-- =====================================================================
--  Kelompok 4
-- =====================================================================
-- USE adn_kl4;

-- Fakta harus dihapus dulu, kalau tidak DROP dim_tanggal gagal (error 3730)
DROP TABLE IF EXISTS fact_kinerja_sales_v2;

-- ===== BAGIAN 1: dim_tanggal standar dosen (tanpa blok pemeriksaan) =====
-- Tabel ini gagal dihapus jika sudah dirujuk tabel fakta. Itu disengaja,
-- supaya tidak terhapus tanpa sengaja.
DROP TABLE IF EXISTS dim_tanggal;

CREATE TABLE dim_tanggal (
    tanggal_key          INT          NOT NULL PRIMARY KEY,  -- format YYYYMMDD, -1 = tidak diketahui
    tanggal              DATE         NOT NULL UNIQUE,
    tahun                INT          NOT NULL,
    semester             INT          NOT NULL,     -- 1 = Jan-Jun, 2 = Jul-Des
    kuartal              INT          NOT NULL,     -- 1 s.d. 4
    bulan                INT          NOT NULL,     -- 1 s.d. 12
    nama_bulan           VARCHAR(15)  NOT NULL,     -- Januari ... Desember
    minggu_dalam_tahun   INT          NOT NULL,     -- minggu ISO 8601, 1 s.d. 53
    tanggal_dalam_bulan  INT          NOT NULL,     -- 1 s.d. 31
    hari_dalam_minggu    INT          NOT NULL,     -- Senin = 1 ... Minggu = 7
    nama_hari            VARCHAR(15)  NOT NULL,     -- Senin ... Minggu
    is_akhir_pekan       BOOLEAN      NOT NULL      -- 1 untuk Sabtu dan Minggu
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
  COMMENT = 'Dimensi tanggal standar kelas DW, versi 1.0';

-- Bawaan MySQL membatasi rekursi 1000 langkah. Rentang ini butuh 2191.
-- SET SESSION cte_max_recursion_depth = 1000;

-- Satu baris per hari
INSERT INTO dim_tanggal
WITH RECURSIVE hari AS (
    SELECT DATE('2010-01-01') AS d
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM hari WHERE d < DATE('2015-12-31')
)
SELECT
    CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED),
    d,
    YEAR(d),
    IF(MONTH(d) <= 6, 1, 2),
    QUARTER(d),
    MONTH(d),
    ELT(MONTH(d), 'Januari','Februari','Maret','April','Mei','Juni','Juli',
                  'Agustus','September','Oktober','November','Desember'),
    WEEK(d, 3),                 -- mode 3 = minggu ISO 8601
    DAY(d),
    WEEKDAY(d) + 1,             -- WEEKDAY: Senin = 0, jadi ditambah 1
    ELT(WEEKDAY(d) + 1, 'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'),
    WEEKDAY(d) >= 5
FROM hari;

-- Baris "Tidak diketahui" untuk fakta yang tanggalnya kosong
INSERT INTO dim_tanggal VALUES
    (-1, '1900-01-01', 0, 0, 0, 0, 'Tidak diketahui', 0, 0, 0, 'Tidak diketahui', FALSE);

-- ===== BAGIAN 2: ddl.sql =====
-- =====================================================================
-- sql/ddl.sql  |  Kelompok 4  |  Proses bisnis: Kinerja Sales vs Target
-- Star schema v2 -> tabel fisik (MySQL 8.0.16 ke atas; CHECK baru

-- CARA PAKAI
--   1. Pilih database DW kelompok (dw_kelompok_4), BUKAN adventureworks.
--   2. Pasang dim_tanggal standar versi 1.0 lebih dulu (skrip dari dosen).
--      Skrip ini TIDAK membuat, mengubah, atau menghapus dim_tanggal,
--      tetapi fakta merujuk ke dim_tanggal, jadi tabel itu harus sudah ada.
--   3. Jalankan skrip ini. Boleh dijalankan berulang kali: semua tabel
--      milik skrip dihapus lalu dibuat ulang (data ikut hilang, isi ulang
--      lewat ETL).
--
-- URUTAN: (1) hapus, fakta dulu  (2) dimensi + baris "Tidak diketahui"
--         (3) fakta dengan foreign key, CHECK, dan index.
--
-- ATURAN KEY
--   * Surrogate key (_key)  : INT AUTO_INCREMENT, dibuat oleh DW.
--   * Natural key (_id)     : INT, disalin dari sumber, bukan primary key.
--   * Key -1                : baris "Tidak diketahui" di setiap dimensi.
--   * produk_key -2         : "Tanpa Produk", dipakai bila target harus
--                             ditaruh di baris sendiri (lihat CR-01).
--   * Foreign key ditulis sebagai CONSTRAINT di bawah tabel. Di MySQL 8,
--     REFERENCES di samping kolom diabaikan tanpa pesan error.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. HAPUS (urutan terbalik: fakta dulu, baru dimensi)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS fact_kinerja_sales_v2;
DROP TABLE IF EXISTS dim_kategori_kinerja;
DROP TABLE IF EXISTS dim_sales_person;
DROP TABLE IF EXISTS dim_produk;
DROP TABLE IF EXISTS dim_wilayah;


-- ---------------------------------------------------------------------
-- 2. DIMENSI
-- ---------------------------------------------------------------------

-- dim_wilayah  (SCD Tipe 1)
CREATE TABLE dim_wilayah (
    wilayah_key   INT           NOT NULL AUTO_INCREMENT,
    territory_id  INT           NULL,
    nama_wilayah  VARCHAR(50)   NOT NULL,
    kode_negara   VARCHAR(3)    NOT NULL,
    nama_negara   VARCHAR(50)   NOT NULL,
    grup_wilayah  VARCHAR(50)   NOT NULL,
    is_active     TINYINT(1)    NOT NULL DEFAULT 1,
    PRIMARY KEY (wilayah_key),
    UNIQUE KEY uq_dim_wilayah_territory (territory_id),
    CONSTRAINT ck_dim_wilayah_active CHECK (is_active IN (0, 1))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Dimensi wilayah penjualan, SCD tipe 1';

INSERT INTO dim_wilayah
    (wilayah_key, territory_id, nama_wilayah, kode_negara, nama_negara, grup_wilayah, is_active)
VALUES
    (-1, NULL, 'Tidak diketahui', 'N/A', 'Tidak diketahui', 'Tidak diketahui', 1);


-- dim_produk  (SCD Tipe 1, struktur standar sesuai arahan sponsor)
CREATE TABLE dim_produk (
    produk_key    INT           NOT NULL AUTO_INCREMENT,
    product_id    INT           NOT NULL,
    nama_produk   VARCHAR(50)   NOT NULL,
    nomor_produk  VARCHAR(25)   NOT NULL,
    sub_kategori  VARCHAR(50)   NOT NULL,
    kategori      VARCHAR(50)   NOT NULL,
    list_price    DECIMAL(14,4) NOT NULL,
    PRIMARY KEY (produk_key),
    UNIQUE KEY uq_dim_produk_product (product_id),
    CONSTRAINT ck_dim_produk_price CHECK (list_price >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Dimensi produk, SCD tipe 1';

INSERT INTO dim_produk
    (produk_key, product_id, nama_produk, nomor_produk, sub_kategori, kategori, list_price)
VALUES
    (-1, -1, 'Tidak diketahui',            'N/A', 'Tidak diketahui', 'Tidak diketahui', 0),
    (-2, -2, 'Tanpa Produk (baris target)', 'N/A', 'Tidak berlaku',   'Tidak berlaku',   0);


-- dim_sales_person  (SCD Tipe 2 pada jabatan, komisi_pct, bonus)
-- Baris aktif: row_expiry_date = '9999-12-31'.
-- Versi pertama tiap salesperson diberi row_effective_date '1900-01-01'
-- supaya fakta kuartal lama tetap menemukan barisnya.
CREATE TABLE dim_sales_person (
    sales_person_key    INT           NOT NULL AUTO_INCREMENT,
    business_entity_id  INT           NOT NULL,
    nama_lengkap        VARCHAR(150)  NOT NULL,
    jabatan             VARCHAR(100)  NOT NULL,
    tanggal_masuk       DATE          NOT NULL,
    komisi_pct          DECIMAL(5,4)  NOT NULL,
    bonus               DECIMAL(14,4) NOT NULL,
    row_effective_date  DATE          NOT NULL,
    row_expiry_date     DATE          NOT NULL DEFAULT '9999-12-31',
    PRIMARY KEY (sales_person_key),
    UNIQUE KEY uq_dim_sales_person_versi (business_entity_id, row_effective_date),
    CONSTRAINT ck_dim_sales_person_berlaku CHECK (row_effective_date <= row_expiry_date),
    CONSTRAINT ck_dim_sales_person_komisi  CHECK (komisi_pct >= 0 AND komisi_pct <= 1),
    CONSTRAINT ck_dim_sales_person_bonus   CHECK (bonus >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Dimensi salesperson, SCD tipe 2';

INSERT INTO dim_sales_person
    (sales_person_key, business_entity_id, nama_lengkap, jabatan, tanggal_masuk,
     komisi_pct, bonus, row_effective_date, row_expiry_date)
VALUES
    (-1, -1, 'Tidak diketahui', 'Tidak diketahui', '1900-01-01',
     0, 0, '1900-01-01', '9999-12-31');


-- dim_kategori_kinerja  (tabel referensi, diisi manual, SCD Tipe 1)
-- kode_kategori dibuat VARCHAR(20): 'BELUM_TERCAPAI' (14 huruf) dan
-- 'TANPA_TARGET' (12 huruf) tidak muat di VARCHAR(10).
CREATE TABLE dim_kategori_kinerja (
    kategori_kinerja_key  INT           NOT NULL AUTO_INCREMENT,
    kode_kategori         VARCHAR(20)   NOT NULL,
    nama_kategori         VARCHAR(50)   NOT NULL,
    keterangan_rentang    VARCHAR(100)  NULL,
    PRIMARY KEY (kategori_kinerja_key),
    UNIQUE KEY uq_dim_kategori_kode (kode_kategori)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Klasifikasi kinerja salesperson terhadap target';

INSERT INTO dim_kategori_kinerja
    (kategori_kinerja_key, kode_kategori, nama_kategori, keterangan_rentang)
VALUES
    (-1, 'UNKNOWN',        'Tidak diketahui',        'Kategori tidak dapat ditentukan'),
    ( 1, 'TERCAPAI',       'Tercapai',               'Realisasi >= Target (>= 100%)'),
    ( 2, 'BELUM_TERCAPAI', 'Belum Tercapai',         'Realisasi < Target (< 100%)'),
    ( 3, 'TANPA_TARGET',   'Tanpa Target',           'Realisasi ada, Target NULL (Q2 2014)'),
    ( 4, 'TARGET_SAJA',    'Target Tanpa Realisasi', 'Target ada, Realisasi 0.00');


-- ---------------------------------------------------------------------
-- 3. FAKTA
-- Grain: satu baris per salesperson per kuartal per wilayah per produk.
-- Tidak ada DEFAULT pada ukuran: ETL wajib mengisinya secara eksplisit,
-- supaya celah di ETL tidak tertutup nilai 0 diam-diam.
-- ---------------------------------------------------------------------
CREATE TABLE fact_kinerja_sales_v2 (
    tanggal_kuartal_key       INT           NOT NULL,
    sales_person_key          INT           NOT NULL,
    wilayah_key               INT           NOT NULL,
    produk_key                INT           NOT NULL,
    target_penjualan          DECIMAL(14,4) NULL,
    realisasi_penjualan       DECIMAL(14,4) NOT NULL,
    selisih_realisasi_target  DECIMAL(14,4) NULL,
    jumlah_terjual            INT           NOT NULL,
    kategori_kinerja_key      INT           NOT NULL,
    PRIMARY KEY (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key),
    KEY ix_fkjs_sales_person (sales_person_key),
    KEY ix_fkjs_wilayah      (wilayah_key),
    KEY ix_fkjs_produk       (produk_key),
    KEY ix_fkjs_kategori     (kategori_kinerja_key),
    CONSTRAINT ck_fkjs_jumlah    CHECK (jumlah_terjual >= 0),
    CONSTRAINT ck_fkjs_realisasi CHECK (realisasi_penjualan >= 0),
    CONSTRAINT ck_fkjs_target    CHECK (target_penjualan IS NULL OR target_penjualan >= 0),
    CONSTRAINT ck_fkjs_selisih   CHECK (target_penjualan IS NOT NULL OR selisih_realisasi_target IS NULL),
    CONSTRAINT fk_fkjs_tanggal   FOREIGN KEY (tanggal_kuartal_key)
        REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fkjs_sales_person FOREIGN KEY (sales_person_key)
        REFERENCES dim_sales_person (sales_person_key),
    CONSTRAINT fk_fkjs_wilayah   FOREIGN KEY (wilayah_key)
        REFERENCES dim_wilayah (wilayah_key),
    CONSTRAINT fk_fkjs_produk    FOREIGN KEY (produk_key)
        REFERENCES dim_produk (produk_key),
    CONSTRAINT fk_fkjs_kategori  FOREIGN KEY (kategori_kinerja_key)
        REFERENCES dim_kategori_kinerja (kategori_kinerja_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Fakta kinerja sales vs target, grain salesperson x kuartal x wilayah x produk';


-- ---------------------------------------------------------------------
-- 4. PEMERIKSAAN (hanya SELECT, aman dijalankan ulang)
-- ---------------------------------------------------------------------
-- 4a. Setiap dimensi harus punya baris -1. Hasil harapan: 1 baris tiap tabel
--     (dim_produk 2 baris: -1 dan -2; dim_kategori_kinerja 5 baris).
SELECT 'dim_wilayah'          AS tabel, COUNT(*) AS baris FROM dim_wilayah
UNION ALL SELECT 'dim_produk',           COUNT(*) FROM dim_produk
UNION ALL SELECT 'dim_sales_person',     COUNT(*) FROM dim_sales_person
UNION ALL SELECT 'dim_kategori_kinerja', COUNT(*) FROM dim_kategori_kinerja;

-- 4b. Foreign key benar-benar terbentuk. Hasil harapan: 5.
SELECT COUNT(*) AS jumlah_foreign_key
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE()
  AND TABLE_NAME = 'fact_kinerja_sales_v2'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

-- 4c. CHECK terbentuk di fakta. Hasil harapan: 4.
SELECT COUNT(*) AS jumlah_check
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE()
  AND TABLE_NAME = 'fact_kinerja_sales_v2'
  AND CONSTRAINT_TYPE = 'CHECK';

-- ===== BAGIAN 3: pemeriksaan dim_tanggal =====
SELECT COUNT(*) AS jumlah_baris_dim_tanggal FROM dim_tanggal;  -- 2192
SELECT tanggal_key, nama_hari, kuartal, minggu_dalam_tahun FROM dim_tanggal WHERE tanggal_key = 20130315;  -- Jumat, 1, 11