-- Rekonsiliasi staging vs DW. Jalankan di database DW SETIAP KALI job selesai, simpan hasilnya di laporan.
-- Toleransi 0.01 karena fakta menyimpan 4 desimal.

USE `adn_kl4-v2`;

-- A. Angka staging = angka fakta?
SELECT ukuran, staging, fakta, staging - fakta AS selisih,
       CASE WHEN ABS(staging - fakta) < 0.01 THEN 'COCOK' ELSE 'TIDAK COCOK' END AS status
FROM (
  SELECT 'Total realisasi (LineTotal reseller ber-salesperson)' AS ukuran,
         (SELECT SUM(d.orderqty * d.unitprice * (1 - d.unitpricediscount))
            FROM stg_salesorderdetail d JOIN stg_salesorderheader h ON h.salesorderid = d.salesorderid
           WHERE h.onlineorderflag = 0 AND h.salespersonid IS NOT NULL) AS staging,
         (SELECT SUM(realisasi_penjualan) FROM fact_kinerja_sales_v2) AS fakta
  UNION ALL
  SELECT 'Total unit terjual',
         (SELECT SUM(d.orderqty)
            FROM stg_salesorderdetail d JOIN stg_salesorderheader h ON h.salesorderid = d.salesorderid
           WHERE h.onlineorderflag = 0 AND h.salespersonid IS NOT NULL),
         (SELECT SUM(jumlah_terjual) FROM fact_kinerja_sales_v2)
  UNION ALL
  SELECT 'Total target (kuota)',
         (SELECT SUM(salesquota) FROM stg_salespersonquotahistory),
         (SELECT SUM(target_penjualan) FROM fact_kinerja_sales_v2)
  UNION ALL
  SELECT 'Jumlah salesperson-kuartal bertarget (baris produk -2)',
         (SELECT COUNT(*) FROM (SELECT DISTINCT businessentityid, YEAR(quotadate) * 10000 + ((QUARTER(quotadate) - 1) * 3 + 1) * 100 + 1 AS q FROM stg_salespersonquotahistory) x),
         (SELECT COUNT(*) FROM fact_kinerja_sales_v2 WHERE produk_key = -2)
  UNION ALL
  SELECT 'Total selisih = realisasi (pada salesperson-kuartal bertarget) - target',
         (SELECT SUM(f2.realisasi_penjualan) FROM fact_kinerja_sales_v2 f2
           WHERE EXISTS (SELECT 1 FROM fact_kinerja_sales_v2 t
                          WHERE t.tanggal_kuartal_key = f2.tanggal_kuartal_key
                            AND t.sales_person_key = f2.sales_person_key
                            AND t.produk_key = -2))
         - (SELECT SUM(target_penjualan) FROM fact_kinerja_sales_v2),
         (SELECT SUM(selisih_realisasi_target) FROM fact_kinerja_sales_v2)
) r;

-- B. Jumlah baris dimensi (dim_sales_person menghitung baris aktif SCD Tipe 2)
SELECT tabel, jumlah_baris, harapan,
       CASE WHEN jumlah_baris = harapan THEN 'COCOK' ELSE 'TIDAK COCOK' END AS status
FROM (
  SELECT 'dim_tanggal' AS tabel, (SELECT COUNT(*) FROM dim_tanggal) AS jumlah_baris, 2192 AS harapan
  UNION ALL SELECT 'dim_wilayah',          (SELECT COUNT(*) FROM dim_wilayah),          (SELECT COUNT(*) FROM stg_salesterritory) + 1
  UNION ALL SELECT 'dim_produk',           (SELECT COUNT(*) FROM dim_produk),           (SELECT COUNT(*) FROM stg_product) + 2
  UNION ALL SELECT 'dim_sales_person (baris aktif)',
                   (SELECT COUNT(*) FROM dim_sales_person WHERE row_expiry_date = '9999-12-31'),
                   (SELECT COUNT(*) FROM stg_salesperson) + 1
  UNION ALL SELECT 'dim_kategori_kinerja', (SELECT COUNT(*) FROM dim_kategori_kinerja), 5
) b;

-- C. Berapa baris fakta jatuh ke "Tidak diketahui"? (harapan: kecil dan bisa dijelaskan)
SELECT SUM(CASE WHEN sales_person_key = -1 THEN 1 ELSE 0 END)      AS salesperson_tidak_diketahui,
       SUM(CASE WHEN wilayah_key = -1 THEN 1 ELSE 0 END)           AS wilayah_tidak_diketahui,
       SUM(CASE WHEN produk_key = -1 THEN 1 ELSE 0 END)            AS produk_tidak_diketahui,
       SUM(CASE WHEN kategori_kinerja_key = -1 THEN 1 ELSE 0 END)  AS kategori_tidak_diketahui,
       COUNT(*)                                                    AS total_baris
FROM fact_kinerja_sales_v2;

-- D. Sebaran kategori kinerja per salesperson-kuartal (hanya baris target -2 dan baris tanpa target)
SELECT k.kode_kategori, COUNT(*) AS jumlah_salesperson_kuartal
FROM (SELECT DISTINCT tanggal_kuartal_key, sales_person_key, kategori_kinerja_key FROM fact_kinerja_sales_v2) f
JOIN dim_kategori_kinerja k ON k.kategori_kinerja_key = f.kategori_kinerja_key
GROUP BY k.kode_kategori
ORDER BY k.kode_kategori;

-- E. Kuartal tanpa kuota (Q2 2014): seharusnya semuanya TANPA_TARGET, target NULL
SELECT f.tanggal_kuartal_key, k.kode_kategori, COUNT(*) AS jumlah_baris,
       SUM(CASE WHEN f.target_penjualan IS NULL THEN 1 ELSE 0 END) AS baris_target_null
FROM fact_kinerja_sales_v2 f
JOIN dim_kategori_kinerja k ON k.kategori_kinerja_key = f.kategori_kinerja_key
WHERE f.tanggal_kuartal_key >= 20140401
GROUP BY f.tanggal_kuartal_key, k.kode_kategori;

-- F. Bukti SCD Tipe 2 pada dim_sales_person (menampilkan salesperson dengan > 1 versi)
SELECT d.sales_person_key,
       d.business_entity_id,
       d.nama_lengkap,
       d.jabatan,
       d.komisi_pct,
       d.bonus,
       d.row_effective_date,
       d.row_expiry_date,
       CASE WHEN d.row_expiry_date = '9999-12-31' THEN 'AKTIF' ELSE 'HISTORIS (DITUTUP)' END AS status_versi
FROM dim_sales_person d
WHERE d.business_entity_id IN (
    SELECT business_entity_id
    FROM dim_sales_person
    WHERE sales_person_key <> -1
    GROUP BY business_entity_id
    HAVING COUNT(*) > 1
)
ORDER BY d.business_entity_id, d.sales_person_key;
