-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 09, 2026 at 08:03 AM
-- Server version: 8.4.3
-- PHP Version: 8.3.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `adn_kl4`
--

-- --------------------------------------------------------

--
-- Table structure for table `dim_kategori_kinerja`
--

CREATE TABLE `dim_kategori_kinerja` (
  `kategori_kinerja_key` int NOT NULL,
  `kode_kategori` varchar(10) NOT NULL,
  `nama_kategori` varchar(50) NOT NULL,
  `keterangan_rentang` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dim_produk`
--

CREATE TABLE `dim_produk` (
  `produk_key` int NOT NULL,
  `product_id` int NOT NULL,
  `nama_produk` varchar(50) NOT NULL,
  `nomor_produk` varchar(25) NOT NULL,
  `sub_kategori` varchar(50) DEFAULT NULL,
  `kategori` varchar(50) DEFAULT NULL,
  `list_price` decimal(15,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dim_sales_person`
--

CREATE TABLE `dim_sales_person` (
  `sales_person_key` int NOT NULL,
  `business_entity_id` int NOT NULL,
  `nama_lengkap` varchar(150) NOT NULL,
  `jabatan` varchar(100) NOT NULL,
  `tanggal_masuk` date NOT NULL,
  `komisi_pct` decimal(5,4) NOT NULL,
  `bonus` decimal(15,2) NOT NULL,
  `row_effective_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dim_tanggal`
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
  `is_akhir_pekan` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensi tanggal standar kelas DW, versi 1.0 (Alternative Loop)';

--
-- Dumping data for table `dim_tanggal`
--

INSERT INTO `dim_tanggal` (`tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan`) VALUES
(-1, '1900-01-01', 0, 0, 0, 0, 'Tidak diketahui', 0, 0, 0, 'Tidak diketahui', 0);

-- --------------------------------------------------------

--
-- Table structure for table `dim_wilayah`
--

CREATE TABLE `dim_wilayah` (
  `wilayah_key` int NOT NULL,
  `territory_id` int DEFAULT NULL,
  `nama_wilayah` varchar(50) NOT NULL,
  `kode_negara` varchar(3) NOT NULL,
  `nama_negara` varchar(50) NOT NULL,
  `grup_wilayah` varchar(50) NOT NULL,
  `is_active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fact_kinerja_sales_v2`
--

CREATE TABLE `fact_kinerja_sales_v2` (
  `tanggal_kuartal_key` int NOT NULL,
  `sales_person_key` int NOT NULL,
  `wilayah_key` int NOT NULL,
  `produk_key` int NOT NULL,
  `target_penjualan` decimal(15,2) DEFAULT NULL,
  `realisasi_penjualan` decimal(15,2) NOT NULL,
  `selisih_realisasi_target` decimal(15,2) DEFAULT NULL,
  `jumlah_terjual` int NOT NULL,
  `kategori_kinerja_key` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `dim_kategori_kinerja`
--
ALTER TABLE `dim_kategori_kinerja`
  ADD PRIMARY KEY (`kategori_kinerja_key`);

--
-- Indexes for table `dim_produk`
--
ALTER TABLE `dim_produk`
  ADD PRIMARY KEY (`produk_key`);

--
-- Indexes for table `dim_sales_person`
--
ALTER TABLE `dim_sales_person`
  ADD PRIMARY KEY (`sales_person_key`);

--
-- Indexes for table `dim_tanggal`
--
ALTER TABLE `dim_tanggal`
  ADD PRIMARY KEY (`tanggal_key`),
  ADD UNIQUE KEY `tanggal` (`tanggal`);

--
-- Indexes for table `dim_wilayah`
--
ALTER TABLE `dim_wilayah`
  ADD PRIMARY KEY (`wilayah_key`);

--
-- Indexes for table `fact_kinerja_sales_v2`
--
ALTER TABLE `fact_kinerja_sales_v2`
  ADD PRIMARY KEY (`tanggal_kuartal_key`,`sales_person_key`,`wilayah_key`,`produk_key`),
  ADD KEY `sales_person_key` (`sales_person_key`),
  ADD KEY `wilayah_key` (`wilayah_key`),
  ADD KEY `produk_key` (`produk_key`),
  ADD KEY `fk_kategori_kinerja` (`kategori_kinerja_key`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `dim_kategori_kinerja`
--
ALTER TABLE `dim_kategori_kinerja`
  MODIFY `kategori_kinerja_key` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dim_produk`
--
ALTER TABLE `dim_produk`
  MODIFY `produk_key` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dim_sales_person`
--
ALTER TABLE `dim_sales_person`
  MODIFY `sales_person_key` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dim_wilayah`
--
ALTER TABLE `dim_wilayah`
  MODIFY `wilayah_key` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `fact_kinerja_sales_v2`
--
ALTER TABLE `fact_kinerja_sales_v2`
  ADD CONSTRAINT `fact_kinerja_sales_v2_ibfk_1` FOREIGN KEY (`tanggal_kuartal_key`) REFERENCES `dim_tanggal` (`tanggal_key`),
  ADD CONSTRAINT `fact_kinerja_sales_v2_ibfk_2` FOREIGN KEY (`sales_person_key`) REFERENCES `dim_sales_person` (`sales_person_key`),
  ADD CONSTRAINT `fact_kinerja_sales_v2_ibfk_3` FOREIGN KEY (`wilayah_key`) REFERENCES `dim_wilayah` (`wilayah_key`),
  ADD CONSTRAINT `fact_kinerja_sales_v2_ibfk_4` FOREIGN KEY (`produk_key`) REFERENCES `dim_produk` (`produk_key`),
  ADD CONSTRAINT `fk_kategori_kinerja` FOREIGN KEY (`kategori_kinerja_key`) REFERENCES `dim_kategori_kinerja` (`kategori_kinerja_key`);

--
-- Perubahan SCD Tipe 2 pada `dim_sales_person`
--

ALTER TABLE dim_sales_person
  ADD COLUMN row_expiry_date date NOT NULL;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;