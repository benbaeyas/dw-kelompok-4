-- Uji: apakah isi DW bisa menjawab 5 pertanyaan bisnis BARU? (SQL pembanding untuk MDX pekan 13)
-- Pencapaian % = (SUM(target) + SUM(selisih)) / SUM(target).
-- Target dan selisih hanya ada di baris produk -2 (CR-01), jadi rumus ini benar di tingkat agregasi apa pun.
-- Hitungan kuartal selalu memakai: produk_key = -2 AND target_penjualan IS NOT NULL (tanpa baris TANPA_TARGET).

USE `adn_kl4-v2`;

-- =====================================================================
-- Q1. Perkembangan pencapaian target dari kuartal ke kuartal:
--     (a) keseluruhan, (b) per grup wilayah
--     Fakta: realisasi, target, selisih | Dimensi: tahun, kuartal, grup wilayah
-- =====================================================================
SELECT t.tahun, t.kuartal,
       '(SEMUA WILAYAH)' AS grup_wilayah,
       SUM(f.realisasi_penjualan)                        AS realisasi_total,
       SUM(f.target_penjualan)                           AS target,
       SUM(f.selisih_realisasi_target)                   AS selisih,
       ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
             / NULLIF(SUM(f.target_penjualan), 0), 2)    AS pencapaian_pct
FROM fact_kinerja_sales_v2 f
JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_kuartal_key
GROUP BY t.tahun, t.kuartal

UNION ALL

SELECT t.tahun, t.kuartal,
       w.grup_wilayah,
       SUM(f.realisasi_penjualan),
       SUM(f.target_penjualan),
       SUM(f.selisih_realisasi_target),
       ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
             / NULLIF(SUM(f.target_penjualan), 0), 2)
FROM fact_kinerja_sales_v2 f
JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_kuartal_key
JOIN dim_wilayah w ON w.wilayah_key = f.wilayah_key
GROUP BY t.tahun, t.kuartal, w.grup_wilayah
ORDER BY tahun, kuartal, grup_wilayah;

USE `adn_kl4-v2`;

-- =====================================================================
-- Q2. Wilayah paling melampaui / paling tertinggal per tahun + kinerja tiap salesperson di dalamnya
--     Fakta: realisasi, target, selisih | Dimensi: tahun, grup wilayah, negara, wilayah, salesperson
--     Kolom berawalan wil_ = angka tingkat wilayah (sama untuk semua salesperson di wilayah itu).
--     wil_rank_terbaik = 1 -> paling melampaui target; wil_rank_terburuk = 1 -> paling tertinggal.
-- =====================================================================
WITH sp AS (   -- tingkat salesperson per wilayah per tahun
    SELECT t.tahun, w.grup_wilayah, w.nama_negara, w.nama_wilayah,
           s.business_entity_id, MAX(s.nama_lengkap) AS nama_lengkap,
           SUM(f.realisasi_penjualan)                AS realisasi_total,
           SUM(f.target_penjualan)                   AS target,
           SUM(f.selisih_realisasi_target)           AS selisih
    FROM fact_kinerja_sales_v2 f
    JOIN dim_tanggal t      ON t.tanggal_key      = f.tanggal_kuartal_key
    JOIN dim_wilayah w      ON w.wilayah_key      = f.wilayah_key
    JOIN dim_sales_person s ON s.sales_person_key = f.sales_person_key
    WHERE f.sales_person_key <> -1
    GROUP BY t.tahun, w.grup_wilayah, w.nama_negara, w.nama_wilayah, s.business_entity_id
    HAVING SUM(f.target_penjualan) IS NOT NULL
),
wil AS (       -- tambahkan total tingkat wilayah lewat window function
    SELECT sp.*,
           SUM(realisasi_total) OVER (PARTITION BY tahun, nama_wilayah) AS wil_realisasi,
           SUM(target)          OVER (PARTITION BY tahun, nama_wilayah) AS wil_target,
           SUM(selisih)         OVER (PARTITION BY tahun, nama_wilayah) AS wil_selisih
    FROM sp
),
hit AS (
    SELECT wil.*,
           ROUND(100 * (wil_target + wil_selisih) / NULLIF(wil_target, 0), 2) AS wil_pencapaian_pct,
           ROUND(100 * (target + selisih)         / NULLIF(target, 0), 2)     AS sp_pencapaian_pct
    FROM wil
)
SELECT tahun, grup_wilayah, nama_negara, nama_wilayah,
       wil_realisasi, wil_target, wil_selisih, wil_pencapaian_pct,
       DENSE_RANK() OVER (PARTITION BY tahun ORDER BY wil_pencapaian_pct DESC) AS wil_rank_terbaik,
       DENSE_RANK() OVER (PARTITION BY tahun ORDER BY wil_pencapaian_pct ASC)  AS wil_rank_terburuk,
       nama_lengkap,
       realisasi_total AS sp_realisasi, target AS sp_target, selisih AS sp_selisih,
       sp_pencapaian_pct
FROM hit
ORDER BY tahun, wil_rank_terbaik, nama_wilayah, sp_pencapaian_pct DESC;

-- =====================================================================
-- Q3. Salesperson: pencapaian % tertinggi, yang di bawah target dan seberapa jauh,
--     serta berapa kuartal berhasil mencapai target
--     Fakta: realisasi, target, selisih | Dimensi: salesperson, kategori kinerja, tanggal
--     selisih < 0 = di bawah target sebesar nilai selisih tersebut
-- =====================================================================
SELECT s.business_entity_id, MAX(s.nama_lengkap)           AS nama_lengkap,
       SUM(f.realisasi_penjualan)                          AS realisasi_total,
       SUM(f.target_penjualan)                             AS target,
       SUM(f.selisih_realisasi_target)                     AS selisih,
       ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
             / NULLIF(SUM(f.target_penjualan), 0), 2)      AS pencapaian_pct,
       CASE WHEN SUM(f.selisih_realisasi_target) >= 0 THEN 'DI ATAS/SESUAI TARGET'
            ELSE 'DI BAWAH TARGET' END                     AS status_total,
       COUNT(DISTINCT CASE WHEN f.produk_key = -2 AND f.target_penjualan IS NOT NULL
                           THEN f.tanggal_kuartal_key END) AS kuartal_bertarget,
       COUNT(DISTINCT CASE WHEN f.produk_key = -2 AND k.kode_kategori = 'TERCAPAI'
                           THEN f.tanggal_kuartal_key END) AS kuartal_tercapai
FROM fact_kinerja_sales_v2 f
JOIN dim_sales_person s      ON s.sales_person_key         = f.sales_person_key
JOIN dim_kategori_kinerja k  ON k.kategori_kinerja_key     = f.kategori_kinerja_key
WHERE f.sales_person_key <> -1
GROUP BY s.business_entity_id
HAVING SUM(f.target_penjualan) IS NOT NULL
ORDER BY pencapaian_pct DESC;

-- =====================================================================
-- Q4. Apakah salesperson dengan unit terjual terbanyak selalu menghasilkan realisasi tertinggi?
--     Rata-rata realisasi per unit tiap salesperson.
--     Fakta: jumlah terjual, realisasi | Dimensi: salesperson, wilayah, tanggal (tahun)
--     Periode = satu kombinasi tahun + wilayah.
--     Satu baris = satu salesperson.
-- =====================================================================
WITH base AS (
    SELECT t.tahun, w.nama_wilayah,
           s.business_entity_id, MAX(s.nama_lengkap) AS nama_lengkap,
           SUM(f.jumlah_terjual)                     AS unit_terjual,
           SUM(f.realisasi_penjualan)                AS realisasi
    FROM fact_kinerja_sales_v2 f
    JOIN dim_tanggal t      ON t.tanggal_key      = f.tanggal_kuartal_key
    JOIN dim_wilayah w      ON w.wilayah_key      = f.wilayah_key
    JOIN dim_sales_person s ON s.sales_person_key = f.sales_person_key
    WHERE f.sales_person_key <> -1
    GROUP BY t.tahun, w.nama_wilayah, s.business_entity_id
),
urut AS (
    SELECT base.*,
           ROW_NUMBER() OVER (PARTITION BY tahun, nama_wilayah ORDER BY unit_terjual DESC) AS n_unit,
           ROW_NUMBER() OVER (PARTITION BY tahun, nama_wilayah ORDER BY realisasi DESC)    AS n_real
    FROM base
)
SELECT nama_lengkap,
       SUM(unit_terjual)                                                    AS unit_terjual,
       SUM(realisasi)                                                       AS realisasi,
       ROUND(SUM(realisasi) / NULLIF(SUM(unit_terjual), 0), 2)              AS realisasi_per_unit,
       COUNT(*)                                                             AS jumlah_periode,
       SUM(n_unit = 1)                                                      AS periode_unit_terbanyak,
       SUM(n_real = 1)                                                      AS periode_realisasi_tertinggi,
       SUM(n_unit = 1 AND n_real = 1)                                       AS periode_keduanya,
       CASE WHEN SUM(n_unit = 1) = 0 THEN '-'
            WHEN SUM(n_unit = 1 AND n_real = 1) = SUM(n_unit = 1) THEN 'SELALU SAMA'
            ELSE 'TIDAK SELALU' END                                         AS unit_terbanyak_juga_realisasi_tertinggi
FROM urut
GROUP BY business_entity_id, nama_lengkap
ORDER BY unit_terjual DESC;

-- =====================================================================
-- Q5. Kelompok salesperson dengan tingkat komisi mana yang paling sering
--     mencapai target dan memiliki rata-rata selisih terbaik?
--     Fakta   : selisih_realisasi_target, kategori_kinerja_key
--     Dimensi : dim_sales_person (komisi, bonus), dim_kategori_kinerja, dim_tanggal
-- =====================================================================

WITH dasar_kuartal AS (
    -- Tahap 1: Ambil data rekap kuartalan bertarget & tandai status tercapai (1/0)
    SELECT s.business_entity_id,
           s.komisi_pct,
           s.bonus,
           t.tahun,
           f.selisih_realisasi_target,
           CASE WHEN k.kode_kategori = 'TERCAPAI' THEN 1 ELSE 0 END AS is_tercapai
    FROM fact_kinerja_sales_v2 f
    JOIN dim_sales_person s     ON s.sales_person_key     = f.sales_person_key
    JOIN dim_kategori_kinerja k ON k.kategori_kinerja_key = f.kategori_kinerja_key
    JOIN dim_tanggal t          ON t.tanggal_key          = f.tanggal_kuartal_key
    WHERE f.produk_key = -2                -- Baris agregasi kuartalan per salesperson
      AND f.target_penjualan IS NOT NULL   -- Hanya kuartal yang memiliki target
      AND f.sales_person_key <> -1
),
rekap_komisi AS (
    -- Tahap 2: Hitung metrik kinerja per kelompok tingkat komisi
    SELECT komisi_pct,
           COUNT(DISTINCT business_entity_id)            AS jml_salesperson,
           CONCAT(MIN(tahun), ' - ', MAX(tahun))         AS periode_tahun,
           COUNT(*)                                      AS jml_kuartal_bertarget,
           SUM(is_tercapai)                              AS jml_kuartal_tercapai,
           COUNT(*) - SUM(is_tercapai)                   AS jml_kuartal_belum_tercapai,
           ROUND(100.0 * SUM(is_tercapai) / COUNT(*), 2) AS persen_tercapai,
           ROUND(AVG(selisih_realisasi_target), 2)       AS rata_rata_selisih,
           ROUND(AVG(bonus), 2)                          AS rata_rata_bonus
    FROM dasar_kuartal
    GROUP BY komisi_pct
)
-- Tahap 3: Tampilkan hasil akhir diurutkan dari yang tertinggi
SELECT CONCAT(ROUND(komisi_pct * 100, 2), '%') AS `Tingkat Komisi`,
       jml_salesperson                         AS `Jumlah Salesperson`,
       periode_tahun                           AS `Periode Tahun`,
       jml_kuartal_bertarget                   AS `Total Kuartal Bertarget`,
       jml_kuartal_tercapai                    AS `Kuartal Tercapai`,
       jml_kuartal_belum_tercapai              AS `Kuartal Belum Tercapai`,
       persen_tercapai                         AS `% Kuartal Tercapai`,
       rata_rata_selisih                       AS `Rata-rata Selisih per Kuartal`,
       rata_rata_bonus                         AS `Rata-rata Bonus`
FROM rekap_komisi
ORDER BY persen_tercapai DESC, rata_rata_selisih DESC;