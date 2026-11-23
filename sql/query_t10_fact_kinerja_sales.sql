WITH pesanan AS (
  -- baris pesanan reseller yang punya salesperson, sudah diberi kuartalnya
  SELECT h.salespersonid AS sp_id,
         d.productid     AS product_id,
         YEAR(h.orderdate) * 10000 + ((QUARTER(h.orderdate) - 1) * 3 + 1) * 100 + 1 AS q_key,
         DATE_ADD(MAKEDATE(YEAR(h.orderdate), 1), INTERVAL (QUARTER(h.orderdate) - 1) * 3 MONTH) AS q_date,
         d.orderqty      AS qty,
         d.orderqty * d.unitprice * (1 - d.unitpricediscount) AS nilai
  FROM stg_salesorderdetail d
  JOIN stg_salesorderheader h ON h.salesorderid = d.salesorderid
  WHERE h.onlineorderflag = 0
    AND h.salespersonid IS NOT NULL
),
kuota AS (
  -- kuota per salesperson per kuartal (kuartal dari QuotaDate)
  SELECT q.businessentityid AS sp_id,
         YEAR(q.quotadate) * 10000 + ((QUARTER(q.quotadate) - 1) * 3 + 1) * 100 + 1 AS q_key,
         DATE_ADD(MAKEDATE(YEAR(q.quotadate), 1), INTERVAL (QUARTER(q.quotadate) - 1) * 3 MONTH) AS q_date,
         SUM(q.salesquota)  AS target
  FROM stg_salespersonquotahistory q
  GROUP BY q.businessentityid, YEAR(q.quotadate) * 10000 + ((QUARTER(q.quotadate) - 1) * 3 + 1) * 100 + 1, DATE_ADD(MAKEDATE(YEAR(q.quotadate), 1), INTERVAL (QUARTER(q.quotadate) - 1) * 3 MONTH)
),
real_sp AS (
  SELECT sp_id, q_key, q_date, SUM(nilai) AS total_real
  FROM pesanan
  GROUP BY sp_id, q_key, q_date
),
spq AS (
  -- semua pasangan salesperson x kuartal: yang punya penjualan, ditambah yang hanya punya kuota
  SELECT r.sp_id, r.q_key, r.q_date, r.total_real, t.target
  FROM real_sp r
  LEFT JOIN kuota t ON t.sp_id = r.sp_id AND t.q_key = r.q_key
  UNION ALL
  SELECT t.sp_id, t.q_key, t.q_date, 0, t.target
  FROM kuota t
  WHERE NOT EXISTS (SELECT 1 FROM real_sp r WHERE r.sp_id = t.sp_id AND r.q_key = t.q_key)
),
wilayah_sp AS (
  -- wilayah penugasan pada kuartal itu: riwayat yang beririsan dengan kuartal, ambil yang paling baru
  SELECT z.sp_id, z.q_key, z.territoryid
  FROM (
    SELECT s.sp_id, s.q_key, th.territoryid,
           ROW_NUMBER() OVER (PARTITION BY s.sp_id, s.q_key ORDER BY th.startdate DESC) AS rn
    FROM spq s
    JOIN stg_salesterritoryhistory th
      ON th.businessentityid = s.sp_id
     AND th.startdate <= DATE_SUB(DATE_ADD(s.q_date, INTERVAL 3 MONTH), INTERVAL 1 DAY)
     AND (th.enddate IS NULL OR th.enddate >= s.q_date)
  ) z
  WHERE z.rn = 1
),
kat AS (
  SELECT s.sp_id, s.q_key, s.q_date, s.total_real, s.target,
         COALESCE(tr.territoryid, sp.territoryid) AS territory_id,
         CASE WHEN s.target IS NULL          THEN 'TANPA_TARGET'
              WHEN s.total_real = 0          THEN 'TARGET_SAJA'
              WHEN s.total_real >= s.target  THEN 'TERCAPAI'
              ELSE 'BELUM_TERCAPAI' END       AS kode_kategori
  FROM spq s
  LEFT JOIN wilayah_sp tr ON tr.sp_id = s.sp_id AND tr.q_key = s.q_key
  LEFT JOIN stg_salesperson sp ON sp.businessentityid = s.sp_id
)
SELECT k.q_key                          AS tanggal_kuartal_key,
       k.q_date                 AS tanggal_kuartal,
       k.sp_id                          AS business_entity_id,
       k.territory_id                   AS territory_id,
       o.product_id                     AS product_id,
       CAST(NULL AS DECIMAL(14,4))      AS target_penjualan,
       ROUND(SUM(o.nilai), 4)           AS realisasi_penjualan,
       SUM(o.qty)                       AS jumlah_terjual,
       CAST(NULL AS DECIMAL(14,4))      AS selisih_realisasi_target,
       k.kode_kategori                  AS kode_kategori
FROM pesanan o
JOIN kat k ON k.sp_id = o.sp_id AND k.q_key = o.q_key
GROUP BY k.q_key, k.q_date, k.sp_id, k.territory_id, o.product_id, k.kode_kategori
UNION ALL
-- baris target (CR-01): satu baris per salesperson x kuartal bertarget, produk -2
SELECT k.q_key, k.q_date, k.sp_id, k.territory_id,
       -2,
       ROUND(k.target, 4),
       CAST(0 AS DECIMAL(14,4)),
       0,
       ROUND(k.total_real - k.target, 4),
       k.kode_kategori
FROM kat k
WHERE k.target IS NOT NULL