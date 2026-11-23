# PERANCANGAN STAR SCHEMA VERSI 1

## Penerapan Metodologi 4 Langkah Kimball
Perancangan model dimensional data warehouse mengadopsi secara ketat metodologi 4 langkah (*Four-Step Dimensional Design Process*) yang dikembangkan oleh Ralph Kimball:

### Langkah 1: Memilih Proses Bisnis (*Select the Business Process*)
Proses bisnis yang dipilih adalah **Evaluasi Kinerja Penjualan vs Kuota Target (*Sales Performance vs Quota Evaluation*)**. Proses ini mengintegrasikan data perencanaan target berkala dari manajemen dengan data transaksi operasional penjualan aktual.

### Langkah 2: Menyatakan Grain (*Declare the Grain*)
Penetapan *grain* adalah keputusan arsitektur paling fundamental dalam pemodelan data warehouse. *Grain* mendefinisikan secara pasti apa yang diwakili oleh tepat satu baris fisik di dalam tabel fakta.

> [!IMPORTANT]
> **PERNYATAAN GRAIN (SATU KALIMAT):**  
> *"Satu baris di `fact_kinerja_sales` mewakili target dan realisasi penjualan satu sales person dalam satu kuartal kalender."*

Granularitas kuartalan dipilih secara logis karena kuota target penjualan Adventure Works ditetapkan oleh dewan manajemen pada basis kuartal, sehingga perbandingan *apple-to-apple* hanya dapat terjadi pada tingkat agregasi kuartal.

### Langkah 3: Mengidentifikasi Dimensi (*Identify the Dimensions*)
Dimensi menyediakan konteks bisnis (*"siapa, di mana, kapan"*) yang mengelilingi fakta. Berdasarkan *grain* yang dideklarasikan, diidentifikasi 3 tabel dimensi:
1. **Dimensi Tanggal (`dim_tanggal`):** Menggambarkan dimensi waktu kuartalan kalender (standar konformasi *enterprise*).
2. **Dimensi Sales Person (`dim_sales_person`):** Menggambarkan profil staf penjualan (identitas, jabatan, tanggal masuk, komisi, bonus).
3. **Dimensi Wilayah (`dim_wilayah`):** Menggambarkan wilayah penugasan pemasaran regional dan kawasan geografis negara.

### Langkah 4: Mengidentifikasi Fakta (*Identify the Facts*)
Fakta adalah nilai metrik kuantitatif terukur yang dihasilkan dari proses bisnis. Berdasarkan kebutuhan pelaporan, fakta yang didefinisikan meliputi:
* **`target_penjualan`** (Aditif): Akumulasi kuota penjualan yang ditargetkan dalam kuartal kalender.
* **`realisasi_penjualan`** (Aditif): Akumulasi nilai penjualan bersih aktual (`SubTotal`) dalam kuartal kalender.
* **`selisih_realisasi_target`** (Aditif): Nilai selisih absolut (`Realisasi − Target`).
* **`jumlah_pesanan`** (Aditif): Total transaksi nota pesanan reseller yang berhasil dibukukan.
* **`ada_target`** (Penanda/Flag 0/1): Atribut penanda ketersediaan data target untuk mempermudah filter.

---

## Diagram Arsitektur Star Schema Versi 1
Berdasarkan hasil analisis konseptual, tim merancang diagram *Star Schema* Versi 1. Model ini menempatkan tabel fakta `fact_kinerja_sales` di titik pusat yang dikelilingi oleh tabel-tabel dimensi pendukung:

![Gambar 4.1: Diagram Arsitektur Star Schema Versi 1 (fact_kinerja_sales)](<Bukti Gamber/starschema_v1.png>)

*Gambar 4.1: Diagram Arsitektur Star Schema Versi 1 (`fact_kinerja_sales`)*

---

## Kamus Data Spesifikasi Tabel Data Warehouse
Struktur kolom, tipe data, serta aturan integritas tabel data warehouse didefinisikan sebagai berikut:

### 1. Tabel Fakta: `fact_kinerja_sales`

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan / Sumber Data |
|:---|:---|:---:|:---:|:---|
| `tanggal_kuartal_key` | INT | FK | No | Kunci tanggal awal kuartal kalender (relasi ke `dim_tanggal`). |
| `sales_person_key` | INT | FK | No | Surrogate key staf penjualan (relasi ke `dim_sales_person`). |
| `wilayah_key` | INT | FK | No | Surrogate key wilayah penugasan staf (relasi ke `dim_wilayah`). |
| `target_penjualan` | DECIMAL(15,2) | - | Yes | Nilai kuota target kuartalan. Bernilai NULL jika tidak ada target. |
| `realisasi_penjualan` | DECIMAL(15,2) | - | No | Total `SubTotal` pesanan reseller. Default 0 jika tidak ada pesanan. |
| `selisih_realisasi_target` | DECIMAL(15,2) | - | Yes | Realisasi − Target. Bernilai NULL jika target bernilai NULL. |
| `jumlah_pesanan` | INT | - | No | Jumlah pesanan reseller yang ditangani dalam kuartal terkait. |
| `ada_target` | TINYINT(1) | - | No | Flag penanda ketersediaan target: 1 = Memiliki target, 0 = Realisasi murni. |

### 2. Tabel Dimensi: `dim_sales_person`

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan / Sumber Data |
|:---|:---|:---:|:---:|:---|
| `sales_person_key` | INT AUTO_INC | PK | No | Surrogate key staf penjualan. |
| `business_entity_id` | INT | - | No | Natural key staf dari sistem OLTP operasional. |
| `nama_lengkap` | VARCHAR(150) | - | No | Gabungan `firstname`, `middlename`, dan `lastname` dari `person_person`. |
| `jabatan` | VARCHAR(100) | - | No | Job title staf penjualan dari `humanresources_employee`. |
| `tanggal_masuk` | DATE | - | No | Tanggal mulai bekerja (`HireDate`). |
| `komisi_pct` | DECIMAL(5,4) | - | No | Persentase komisi penjualan dari `sales_salesperson`. |
| `bonus` | DECIMAL(15,2) | - | No | Nilai bonus kumulatif berjalan dari sistem operasional. |
| `row_effective_date` | DATE | - | No | Atribut audit waktu SCD Tipe 2 (tanggal berlaku). |

### 3. Tabel Dimensi: `dim_wilayah`

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan / Sumber Data |
|:---|:---|:---:|:---:|:---|
| `wilayah_key` | INT AUTO_INC | PK | No | Surrogate key wilayah pemasaran (Key 0 = Tidak Diketahui). |
| `territory_id` | INT | - | Yes | Natural key wilayah dari `sales_salesterritory` (NULL pada Unassigned). |
| `nama_wilayah` | VARCHAR(50) | - | No | Nama kawasan wilayah (misal: Northwest, Southwest, France). |
| `kode_negara` | VARCHAR(3) | - | No | Kode ISO negara (`CountryRegionCode`). |
| `nama_negara` | VARCHAR(50) | - | No | Nama resmi negara dari `person_countryregion`. |
| `grup_wilayah` | VARCHAR(50) | - | No | Grup teritori makro (North America, Europe, Pacific, Unassigned). |
| `is_active` | TINYINT(1) | - | No | Penanda status keaktifan wilayah operasional. |

### 4. Tabel Dimensi: `dim_tanggal`
Tabel `dim_tanggal` menggunakan standar dimensi konformasi *enterprise* yang disediakan oleh Project Sponsor. Kunci penghubung yang digunakan adalah tanggal awal kuartal kalender (misal: `2011-04-01` untuk Kuartal 2 2011). Atribut dimensi mencakup: `tanggal_key` (PK), `tanggal_lengkap`, `tahun`, `kuartal`, `bulan`, `nama_bulan`, `kuartal_nama`, dan penanda akhir pekan.

---

## Aturan Penurunan Nilai & Logika Transformasi ETL
Logika penurunan nilai dari sistem operasional ke tabel fakta data warehouse dirumuskan sebagai berikut:
1. **Ekstraksi Realisasi:** Data realisasi penjualan dan jumlah pesanan diekstrak dari `sales_salesorderheader` dengan klausa filter `WHERE salespersonid IS NOT NULL`. Tanggal pesanan disesuaikan menggunakan formula `DATE_ADD(orderdate, INTERVAL 330 MINUTE)` sebelum diagregasi per tahun dan kuartal kalender.
2. **Ekstraksi Target:** Data target kuota diekstrak dari `sales_salespersonquotahistory`, di mana tahun dan kuartal diekstrak langsung dari kolom `quotadate`.
3. **Penggabungan Fakta (*Full Outer Join*):** Tabel fakta dibentuk melalui mekanisme `FULL OUTER JOIN` antara dataset target kuota dan dataset realisasi transaksi berdasarkan kombinasi kunci (`SalesPersonID`, `Tahun`, `Kuartal`).
4. **Resolusi Dimensi Wilayah:** Kunci `wilayah_key` ditentukan berdasarkan wilayah resmi di `sales_salesterritoryhistory` yang berlaku aktif pada hari terakhir kuartal terkait. Apabila tidak ada riwayat, sistem merujuk pada `territoryid` di `sales_salesperson`. Jika masih bernilai NULL, maka dipetakan ke `wilayah_key = 0` (Unassigned).
