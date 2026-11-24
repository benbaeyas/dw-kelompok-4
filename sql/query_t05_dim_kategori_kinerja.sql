-- t05_dim_kategori_kinerja
-- Tabel referensi diisi manual. Upsert: aman dijalankan berulang, baris -1 dan 1..4 selalu ada.
-- Setara dengan Table input (data hardcoded) -> Insert/Update (key: kategori_kinerja_key) pada koneksi adn_kl4-v2.
-- Catatan: sintaks "AS new" butuh MySQL 8.0.19+. Untuk versi lebih lama, hapus "AS new"
-- dan ganti new.kolom dengan VALUES(kolom).

USE `adn_kl4-v2`;

-- (Opsional) DDL tabel; tipe data diasumsikan, sesuaikan dengan tabel aslimu.
CREATE TABLE IF NOT EXISTS dim_kategori_kinerja (
    kategori_kinerja_key INT          NOT NULL,   -- tanpa AUTO_INCREMENT karena ada key -1
    kode_kategori        VARCHAR(30)  NOT NULL,
    nama_kategori        VARCHAR(50)  NOT NULL,
    keterangan_rentang   VARCHAR(100) NULL,
    PRIMARY KEY (kategori_kinerja_key)
);

INSERT INTO dim_kategori_kinerja
    (kategori_kinerja_key, kode_kategori, nama_kategori, keterangan_rentang)
VALUES
    (-1, 'UNKNOWN',        'Tidak diketahui',        'Kategori tidak dapat ditentukan'),
    ( 1, 'TERCAPAI',       'Tercapai',               'Realisasi >= Target (>= 100%)'),
    ( 2, 'BELUM_TERCAPAI', 'Belum Tercapai',         'Realisasi < Target (< 100%)'),
    ( 3, 'TANPA_TARGET',   'Tanpa Target',           'Realisasi ada, Target NULL (Q2 2014)'),
    ( 4, 'TARGET_SAJA',    'Target Tanpa Realisasi', 'Target ada, Realisasi 0.00')
AS new
ON DUPLICATE KEY UPDATE
    kode_kategori      = new.kode_kategori,
    nama_kategori      = new.nama_kategori,
    keterangan_rentang = new.keterangan_rentang;
