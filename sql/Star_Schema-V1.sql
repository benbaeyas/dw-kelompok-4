-- MySQL dump 10.13  Distrib 8.0.19, for Win64 (x86_64)
--
-- Host: localhost    Database: adn_kl4-v1
-- ------------------------------------------------------
-- Server version	8.0.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `dim_sales_person`
--

DROP TABLE IF EXISTS `dim_sales_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dim_sales_person` (
  `sk_sales_person` int NOT NULL AUTO_INCREMENT,
  `businessentityid` int NOT NULL,
  `nama_lengkap` varchar(150) NOT NULL,
  `job_title` varchar(100) NOT NULL,
  `commission_pct` decimal(5,4) NOT NULL,
  PRIMARY KEY (`sk_sales_person`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dim_sales_person`
--

LOCK TABLES `dim_sales_person` WRITE;
/*!40000 ALTER TABLE `dim_sales_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `dim_sales_person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dim_tanggal`
--

DROP TABLE IF EXISTS `dim_tanggal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dim_tanggal` (
  `sk_tanggal_kuartal` int NOT NULL AUTO_INCREMENT,
  `tahun` int NOT NULL,
  `kuartal` int NOT NULL,
  `nama_kuartal_tahun` varchar(20) NOT NULL,
  PRIMARY KEY (`sk_tanggal_kuartal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dim_tanggal`
--

LOCK TABLES `dim_tanggal` WRITE;
/*!40000 ALTER TABLE `dim_tanggal` DISABLE KEYS */;
/*!40000 ALTER TABLE `dim_tanggal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dim_wilayah`
--

DROP TABLE IF EXISTS `dim_wilayah`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dim_wilayah` (
  `sk_wilayah` int NOT NULL AUTO_INCREMENT,
  `territoryid` int NOT NULL,
  `nama_wilayah` varchar(50) NOT NULL,
  `kode_negara` varchar(3) NOT NULL,
  `grup_wilayah` varchar(50) NOT NULL,
  PRIMARY KEY (`sk_wilayah`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dim_wilayah`
--

LOCK TABLES `dim_wilayah` WRITE;
/*!40000 ALTER TABLE `dim_wilayah` DISABLE KEYS */;
/*!40000 ALTER TABLE `dim_wilayah` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fact_kinerja_sales`
--

DROP TABLE IF EXISTS `fact_kinerja_sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fact_kinerja_sales` (
  `sk_tanggal_kuartal` int NOT NULL,
  `sk_sales_person` int NOT NULL,
  `sk_wilayah` int NOT NULL,
  `target_penjualan` decimal(14,4) DEFAULT NULL,
  `realisasi_penjualan` decimal(14,4) NOT NULL,
  `selisih_pencapaian` decimal(14,4) DEFAULT NULL,
  `jumlah_pesanan` int NOT NULL,
  `estimasi_komisi` decimal(14,4) NOT NULL,
  PRIMARY KEY (`sk_tanggal_kuartal`,`sk_sales_person`,`sk_wilayah`),
  KEY `fk_fks_sales_person` (`sk_sales_person`),
  KEY `fk_fks_wilayah` (`sk_wilayah`),
  CONSTRAINT `fk_fks_sales_person` FOREIGN KEY (`sk_sales_person`) REFERENCES `dim_sales_person` (`sk_sales_person`),
  CONSTRAINT `fk_fks_tanggal` FOREIGN KEY (`sk_tanggal_kuartal`) REFERENCES `dim_tanggal` (`sk_tanggal_kuartal`),
  CONSTRAINT `fk_fks_wilayah` FOREIGN KEY (`sk_wilayah`) REFERENCES `dim_wilayah` (`sk_wilayah`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fact_kinerja_sales`
--

LOCK TABLES `fact_kinerja_sales` WRITE;
/*!40000 ALTER TABLE `fact_kinerja_sales` DISABLE KEYS */;
/*!40000 ALTER TABLE `fact_kinerja_sales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'adn_kl4-v1'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-17 10:28:46
