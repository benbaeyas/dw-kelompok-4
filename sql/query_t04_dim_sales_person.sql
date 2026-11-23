-- t04_dim_sales_person (SCD Tipe 2: jabatan, komisi_pct, bonus | SCD Tipe 1: nama_lengkap, tanggal_masuk)
-- Query yang sama persis dengan yang ada di langkah in_bandingkan_staging_dim (koneksi: adn_kl4-v2).

WITH sumber AS (
  SELECT sp.businessentityid                                                                  AS business_entity_id,
         COALESCE(NULLIF(TRIM(CONCAT_WS(' ', p.firstname, p.middlename, p.lastname)), ''),
                  'Tidak diketahui')                                                          AS nama_lengkap,
         COALESCE(NULLIF(TRIM(e.jobtitle), ''), 'Tidak diketahui')                            AS jabatan,
         COALESCE(e.hiredate, DATE('1900-01-01'))                                             AS tanggal_masuk,
         CAST(COALESCE(sp.commissionpct, 0) AS DECIMAL(5,4))                                  AS komisi_pct,
         CAST(COALESCE(sp.bonus, 0) AS DECIMAL(14,4))                                         AS bonus
  FROM stg_salesperson sp
  LEFT JOIN stg_person   p ON p.businessentityid = sp.businessentityid
  LEFT JOIN stg_employee e ON e.businessentityid = sp.businessentityid
)
SELECT s.business_entity_id,
       s.nama_lengkap,
       s.jabatan,
       s.tanggal_masuk,
       s.komisi_pct,
       s.bonus,
       d.sales_person_key                                                                     AS old_sales_person_key,
       CASE
         WHEN d.sales_person_key IS NULL THEN 'BARU'
         WHEN d.jabatan <> s.jabatan
           OR d.komisi_pct <> s.komisi_pct
           OR d.bonus <> s.bonus THEN 'UBAH_TIPE2'
         WHEN d.nama_lengkap <> s.nama_lengkap
           OR d.tanggal_masuk <> s.tanggal_masuk THEN 'UBAH_TIPE1'
         ELSE 'SAMA'
       END                                                                                    AS status_scd,
       CASE
         WHEN d.sales_person_key IS NULL THEN DATE('1900-01-01')
         ELSE CURDATE()
       END                                                                                    AS new_effective_date,
       DATE('9999-12-31')                                                                     AS new_expiry_date,
       GREATEST(COALESCE(d.row_effective_date, DATE('1900-01-01')),
                DATE_SUB(CURDATE(), INTERVAL 1 DAY))                                          AS closed_expiry_date
FROM sumber s
LEFT JOIN dim_sales_person d
  ON d.business_entity_id = s.business_entity_id
 AND d.row_expiry_date = '9999-12-31'
ORDER BY s.business_entity_id;
