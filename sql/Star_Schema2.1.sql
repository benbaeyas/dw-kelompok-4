-- ========================================================
-- SKRIP DDL STAR SCHEMA VERSI 2 (DW_KELOMPOK_4)
-- Basis Data Target: dw_kelompok_4 (MariaDB / MySQL)
-- Proses Bisnis: Kinerja Sales vs Target
-- ========================================================

-- Nonaktifkan pengecekan foreign key sementara agar proses DROP & CREATE berjalan aman
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------
-- 1. HAPUS TABEL JIKA SUDAH ADA (Urutan dependensi terbalik)
-- --------------------------------------------------------
DROP TABLE IF EXISTS `fact_kinerja_sales_v2`;
DROP TABLE IF EXISTS `dim_kategori_kinerja`;
DROP TABLE IF EXISTS `dim_produk`;
DROP TABLE IF EXISTS `dim_sales_person`;
DROP TABLE IF EXISTS `dim_tanggal`;
DROP TABLE IF EXISTS `dim_wilayah`;

-- --------------------------------------------------------
-- 2. PEMBUATAN TABEL DIMENSI
-- --------------------------------------------------------

--
-- Tabel Dimensi: dim_kategori_kinerja (Junk / Banding Dimension)
--
CREATE TABLE `dim_kategori_kinerja` (
  `kategori_kinerja_key` int NOT NULL AUTO_INCREMENT,
  `kode_kategori` varchar(10) NOT NULL,
  `nama_kategori` varchar(50) NOT NULL,
  `keterangan_rentang` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`kategori_kinerja_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Tabel Dimensi: dim_produk (SCD Tipe 1)
--
CREATE TABLE `dim_produk` (
  `produk_key` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `nama_produk` varchar(50) NOT NULL,
  `nomor_produk` varchar(25) NOT NULL,
  `sub_kategori` varchar(50) DEFAULT NULL,
  `kategori` varchar(50) DEFAULT NULL,
  `list_price` decimal(15,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`produk_key`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Tabel Dimensi: dim_sales_person (SCD Tipe 2)
--
CREATE TABLE `dim_sales_person` (
  `sales_person_key` int NOT NULL AUTO_INCREMENT,
  `business_entity_id` int NOT NULL,
  `nama_lengkap` varchar(150) NOT NULL,
  `jabatan` varchar(100) NOT NULL,
  `tanggal_masuk` date NOT NULL,
  `komisi_pct` decimal(5,4) NOT NULL DEFAULT '0.0000',
  `bonus` decimal(15,2) NOT NULL DEFAULT '0.00',
  `row_effective_date` date NOT NULL,
  `row_expiry_date` date NOT NULL DEFAULT '9999-12-31',
  PRIMARY KEY (`sales_person_key`),
  KEY `idx_sp_business_entity` (`business_entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Tabel Dimensi: dim_tanggal (SCD Tipe 0 - Standar Kelas DW)
--
CREATE TABLE `dim_tanggal` (
  `tanggal_key` int NOT NULL,
  `tanggal` date NOT NULL,
  `tahun` int NOT NULL,
  `semester` int NOT NULL,
  `kuartal` int NOT NULL,
  `bulan` int NOT NULL,
  `nama_bulan` varchar(15) NOT NULL,
  `minggu_dalam_tahun` int NOT NULL,
  `tanggal_dalam_bulan` int NOT NULL,
  `hari_dalam_minggu` int NOT NULL,
  `nama_hari` varchar(15) NOT NULL,
  `is_akhir_pekan` tinyint(1) NOT NULL,
  PRIMARY KEY (`tanggal_key`),
  UNIQUE KEY `uq_dim_tanggal` (`tanggal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensi tanggal standar kelas DW, versi 1.0 (Alternative Loop)';

--
-- Tabel Dimensi: dim_wilayah (SCD Tipe 1)
--
CREATE TABLE `dim_wilayah` (
  `wilayah_key` int NOT NULL AUTO_INCREMENT,
  `territory_id` int DEFAULT NULL,
  `nama_wilayah` varchar(50) NOT NULL,
  `kode_negara` varchar(3) NOT NULL,
  `nama_negara` varchar(50) NOT NULL,
  `grup_wilayah` varchar(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`wilayah_key`),
  KEY `idx_territory_id` (`territory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 3. PEMBUATAN TABEL FAKTA
-- --------------------------------------------------------

--
-- Tabel Fakta: fact_kinerja_sales_v2
--
CREATE TABLE `fact_kinerja_sales_v2` (
  `tanggal_kuartal_key` int NOT NULL,
  `sales_person_key` int NOT NULL,
  `wilayah_key` int NOT NULL,
  `produk_key` int NOT NULL,
  `target_penjualan` decimal(15,2) DEFAULT NULL,
  `realisasi_penjualan` decimal(15,2) NOT NULL DEFAULT '0.00',
  `selisih_realisasi_target` decimal(15,2) DEFAULT NULL,
  `jumlah_terjual` int NOT NULL DEFAULT '0',
  `kategori_kinerja_key` int NOT NULL,
  PRIMARY KEY (`tanggal_kuartal_key`, `sales_person_key`, `wilayah_key`, `produk_key`),
  KEY `idx_fk_sales_person` (`sales_person_key`),
  KEY `idx_fk_wilayah` (`wilayah_key`),
  KEY `idx_fk_produk` (`produk_key`),
  KEY `idx_fk_kategori_kinerja` (`kategori_kinerja_key`),
  CONSTRAINT `fk_fact_tanggal` FOREIGN KEY (`tanggal_kuartal_key`) REFERENCES `dim_tanggal` (`tanggal_key`),
  CONSTRAINT `fk_fact_sales_person` FOREIGN KEY (`sales_person_key`) REFERENCES `dim_sales_person` (`sales_person_key`),
  CONSTRAINT `fk_fact_wilayah` FOREIGN KEY (`wilayah_key`) REFERENCES `dim_wilayah` (`wilayah_key`),
  CONSTRAINT `fk_fact_produk` FOREIGN KEY (`produk_key`) REFERENCES `dim_produk` (`produk_key`),
  CONSTRAINT `fk_fact_kategori_kinerja` FOREIGN KEY (`kategori_kinerja_key`) REFERENCES `dim_kategori_kinerja` (`kategori_kinerja_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 4. INSERT DATA AWAL (DEFAULT / DUMMY RECORD)
-- --------------------------------------------------------

-- Baris dummy untuk tanggal tidak diketahui
INSERT INTO `dim_tanggal` (
  `tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`,
  `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`,
  `nama_hari`, `is_akhir_pekan`
) VALUES (
  -1, '1900-01-01', 0, 0, 0, 0,
  'Tidak diketahui', 0, 0, 0,
  'Tidak diketahui', 0
);

-- Aktifkan kembali pengecekan foreign key
SET FOREIGN_KEY_CHECKS = 1;
