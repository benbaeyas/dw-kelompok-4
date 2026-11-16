# Dokumen Pemetaan Staging (Pekan 11 & 12)
**Kelompok:** 4 (Empat)  
**Proses Bisnis:** Kinerja Sales vs Target  
**Database DW:** `adn_kl4` / `dw_kelompok_4`  
**Database Sumber:** `adventureworks2` (MariaDB/MySQL)

---

## 1. Peran dan Ketentuan Tabel Staging

Sesuai arahan teknis perancangan Data Warehouse, tabel staging memiliki karakteristik dan ketentuan sebagai berikut:

1. **Salinan Mentah (*Raw Copy*)**
   - Kolom dan tipe data sama persis dengan tabel sumber di OLTP (`adventureworks2`).
   - **Tanpa constraint:** Tidak ada `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, maupun `CHECK` constraint di staging.
   - Semua kolom mengizinkan nilai `NULL` agar proses ekstraksi data berlangsung cepat, andal, dan tidak terhenti akibat error integritas relasional pada sistem sumber.
   - **Dikosongkan setiap ETL jalan:** Tabel staging dikosongkan menggunakan `TRUNCATE TABLE` sebelum proses ekstraksi data baru dimulai.

2. **Satu Database (*Single Database Architecture*)**
   - Tabel staging berada di dalam database Data Warehouse yang sama (`adn_kl4` / `dw_kelompok_4`) dengan skema prefix `stg_`.
   - Karena data mentah sudah berada di database yang sama dengan DW, transformasi pembentukan dimensi dan fakta dapat dieksekusi secara efisien menggunakan join SQL biasa (*in-database transformation* / pendekatan ELT).

3. **Rekonsiliasi Mudah**
   - Keutuhan data hasil muat (*load*) dapat diverifikasi secara instan. Total metrik di staging (seperti `LineTotal` dan `SalesQuota`) dapat dibandingkan langsung dengan total ukuran di tabel fakta (`realisasi_penjualan` dan `target_penjualan`) hanya dengan **satu query SQL rekonsiliasi**.

---

## 2. Daftar Tabel Staging (Sesuai Standar Penugasan)

### 2.1. Tabel Ringkas Staging (Pengelompokan Sumber ke Objek DW)

| Tabel staging | Sumber | Dipakai untuk |
|---|---|---|
| `stg_salesorderheader`, `stg_salesorderdetail` | `sales.salesorderheader`, `sales.salesorderdetail` | **Fakta** (`fact_kinerja_sales_v2`) |
| `stg_salespersonquotahistory` | `sales.salespersonquotahistory` | **Fakta** (`fact_kinerja_sales_v2`) |
| `stg_salesperson`, `stg_person`, `stg_employee` | `sales.salesperson`, `person.person`, `humanresources.employee` | **dim_sales_person (SCD tipe 2)** |
| `stg_salesterritory`, `stg_countryregion` | `sales.salesterritory`, `person.countryregion` | **dim_wilayah** |
| `stg_salesterritoryhistory` | `sales.salesterritoryhistory` | **Fakta** & **dim_wilayah** |
| `stg_product`, `stg_productsubcategory`, `stg_productcategory` | `production.*` | **dim_produk** |

---

### 2.2. Rincian Pemetaan Kolom per Tabel Staging (12 Tabel)

| No | Tabel Staging | Sumber (`adventureworks2`) | Dipakai Untuk (Fakta / Dimensi) | Kolom yang Disalin | Keterangan & Peran di DW |
|:--:|---|---|---|---|---|
| 1 | `stg_salesorderheader` | `sales.salesorderheader` | **Fakta** (`fact_kinerja_sales_v2`) | `SalesOrderID`, `OrderDate`, `SalesPersonID`, `TerritoryID`, `OnlineOrderFlag`, `SubTotal`, `TotalDue` | Filter pesanan reseller (`OnlineOrderFlag = 0`), penentuan kuartal kalender (`OrderDate` + 330 menit), relasi salesperson & wilayah pada baris fakta. |
| 2 | `stg_salesorderdetail` | `sales.salesorderdetail` | **Fakta** (`fact_kinerja_sales_v2`) | `SalesOrderID`, `SalesOrderDetailID`, `ProductID`, `OrderQty`, `UnitPrice`, `UnitPriceDiscount`, `LineTotal` | Perhitungan ukuran metrik fakta: `realisasi_penjualan` (`LineTotal`), `jumlah_terjual` (`OrderQty`), dan relasi produk (`ProductID`). |
| 3 | `stg_salespersonquotahistory` | `sales.salespersonquotahistory` | **Fakta** (`fact_kinerja_sales_v2`) | `BusinessEntityID`, `QuotaDate`, `SalesQuota` | Sumber ukuran kuota kuartalan (`target_penjualan`) pada baris fakta. |
| 4 | `stg_salesperson` | `sales.salesperson` | **dim_sales_person (SCD tipe 2)** | `BusinessEntityID`, `TerritoryID`, `SalesQuota`, `Bonus`, `CommissionPct`, `SalesYTD` | Atribut salesperson yang dipantau perubahannya secara historis (`komisi_pct`, `bonus`). |
| 5 | `stg_salesterritory` | `sales.salesterritory` | **dim_wilayah** (Dimensi) | `TerritoryID`, `Name`, `CountryRegionCode`, `Group` | Atribut master wilayah penjualan (`nama_wilayah`, `grup_wilayah`). |
| 6 | `stg_salesterritoryhistory` | `sales.salesterritoryhistory` | **Fakta** & **dim_wilayah** | `BusinessEntityID`, `TerritoryID`, `StartDate`, `EndDate` | Penentuan riwayat penugasan wilayah salesperson per kuartal untuk lookup `wilayah_key` di fakta. |
| 7 | `stg_person` | `person.person` | **dim_sales_person** (Dimensi) | `BusinessEntityID`, `FirstName`, `MiddleName`, `LastName` | Pembentukan atribut nama lengkap salesperson (`CONCAT_WS`). |
| 8 | `stg_employee` | `humanresources.employee` | **dim_sales_person** (Dimensi) | `BusinessEntityID`, `JobTitle`, `HireDate` | Atribut kepegawaian salesperson (`jabatan` dan `tanggal_masuk`). |
| 9 | `stg_countryregion` | `person.countryregion` | **dim_wilayah** (Dimensi) | `CountryRegionCode`, `Name` | Lookup nama lengkap negara (`nama_negara`) berdasarkan kode negara. |
| 10 | `stg_product` | `production.product` | **dim_produk** (Dimensi) | `ProductID`, `Name`, `ProductNumber`, `ListPrice`, `ProductSubcategoryID` | Master produk (`nama_produk`, `nomor_produk`, `list_price`). |
| 11 | `stg_productsubcategory` | `production.productsubcategory` | **dim_produk** (Dimensi) | `ProductSubcategoryID`, `ProductCategoryID`, `Name` | Lookup nama sub-kategori produk (`sub_kategori`). |
| 12 | `stg_productcategory` | `production.productcategory` | **dim_produk** (Dimensi) | `ProductCategoryID`, `Name` | Lookup nama kategori produk (`kategori`). |

---

## 3. Implementasi: Jalur Pentaho (ETL) vs Jalur n8n / DDL (ELT)

* **Jalur Pentaho Data Integration (Pekan 12):**
  - Pada langkah *Table Output*, Pentaho menyediakan tombol **SQL** yang otomatis menghasilkan query DDL pembuatan tabel staging sesuai field yang dialirkan dari *Table Input*.
  - Menghilangkan beban penulisan DDL manual, namun tetap disiapkan DDL eksplisit agar tim memiliki visibilitas penuh terhadap tipe data.

* **Jalur ELT / n8n / Eksekusi Skrip DDL:**
  - Disediakan file DDL mandiri: `sql/00_staging_ddl.sql`.
  - Berisi struktur tabel mentah tanpa constraint yang dapat dieksekusi langsung di database target `dw_kelompok_4` sebelum ETL dijalankan.

---

## 4. Query Rekonsiliasi Satu Query (Staging vs Fakta)

Sesuai ketentuan, kebenaran ETL diuji dengan membandingkan angka agregat staging terhadap tabel fakta dengan satu query:

### 4.1. Rekonsiliasi Realisasi Penjualan (LineTotal vs realisasi_penjualan)

```sql
SELECT 
    (SELECT ROUND(SUM(d.LineTotal), 2)
     FROM stg_salesorderheader h
     JOIN stg_salesorderdetail d ON h.SalesOrderID = d.SalesOrderID
     WHERE h.OnlineOrderFlag = 0 
       AND h.SalesPersonID IS NOT NULL
    ) AS total_staging_realisasi,
    
    (SELECT ROUND(SUM(realisasi_penjualan), 2) 
     FROM fact_kinerja_sales_v2
    ) AS total_fakta_realisasi,
    
    (SELECT ROUND(SUM(d.LineTotal), 2)
     FROM stg_salesorderheader h
     JOIN stg_salesorderdetail d ON h.SalesOrderID = d.SalesOrderID
     WHERE h.OnlineOrderFlag = 0 
       AND h.SalesPersonID IS NOT NULL
    ) - 
    (SELECT ROUND(SUM(realisasi_penjualan), 2) 
     FROM fact_kinerja_sales_v2
    ) AS selisih_rekonsiliasi;
-- Target hasil selisih_rekonsiliasi: 0.00
```

### 4.2. Rekonsiliasi Target Kuota Penjualan (SalesQuota vs target_penjualan)

```sql
SELECT 
    (SELECT ROUND(SUM(SalesQuota), 2) 
     FROM stg_salespersonquotahistory
    ) AS total_staging_quota,
    
    (SELECT ROUND(SUM(target_penjualan), 2) 
     FROM fact_kinerja_sales_v2 
     WHERE target_penjualan IS NOT NULL
    ) AS total_fakta_target,
    
    (SELECT ROUND(SUM(SalesQuota), 2) 
     FROM stg_salespersonquotahistory
    ) - 
    (SELECT ROUND(SUM(target_penjualan), 2) 
     FROM fact_kinerja_sales_v2 
     WHERE target_penjualan IS NOT NULL
    ) AS selisih_quota;
-- Target hasil selisih_quota: 0.00
```

---

## 5. Penyelarasan Dokumen Proyek

| # | Temuan | Tindakan Penyelarasan |
|---|---|---|
| 1 | Piagam proyek lama hanya mencatat 8 tabel sumber. Star schema v2 membutuhkan dimensi produk (`dim_produk`) sehingga memerlukan 4 tabel tambahan. | Ditambahkan tabel `stg_salesorderdetail`, `stg_product`, `stg_productsubcategory`, dan `stg_productcategory` (total menjadi 12 tabel). |
| 2 | Standardisasi Surrogate Key "Tidak Diketahui" | Seluruh dimensi konsisten menggunakan key `-1` (bukan 0) sesuai aturan dosen dan `ddl.sql`. |
| 3 | Konsistensi Grain Fakta & Target (CR-01) | Target kuota kuartalan ditangani secara konsisten agar tidak terhitung ganda pada grain produk. |
| 4 | Kategori Kinerja | Menggunakan 5 entri standar di `dim_kategori_kinerja`: `UNKNOWN`, `TERCAPAI`, `BELUM_TERCAPAI`, `TANPA_TARGET`, dan `TARGET_SAJA`. |
