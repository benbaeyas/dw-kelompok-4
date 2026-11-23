# PERANCANGAN STAR SCHEMA VERSI 2

## 1. Latar Belakang & Alasan Evolusi Skema
Pada iterasi awal (Versi 1), tabel fakta dirancang dengan granularitas agregat kuartalan murni per staf penjualan dan wilayah tanpa memperhitungkan rincian barang dagangan yang dipesan. Berdasarkan evaluasi *Steering Review* bersama Project Sponsor dan kebutuhan analitik bisnis yang lebih mendalam, skema bintang disempurnakan menjadi **Star Schema Versi 2** (`fact_kinerja_sales_v2`) dengan poin pembaruan utama sebagai berikut:
1. **Penambahan Dimensi Produk (`dim_produk`):** Memungkinkan manajemen mengevaluasi kontribusi lini produk dan kategori barang tertentu terhadap pencapaian target penjualan staf.
2. **Penambahan Dimensi Kategori Kinerja (`dim_kategori_kinerja`):** Menggantikan penanda boolean `ada_target` dengan klasifikasi status kinerja yang formal (*Tercapai*, *Belum Tercapai*, *Tanpa Target*, *Target Tanpa Realisasi*, *Tidak Diketahui*).
3. **Penyelarasan Dimensi Tanggal Standar Enterprise (`dim_tanggal` v1.0):** Mengadopsi struktur dimensi kalender standar kelas dengan format surrogate key berbasis integer `YYYYMMDD` (contoh: `20110401`).
4. **Penanganan Multi-Granularitas Target (CR-01):** Target kuota ditetapkan per kuartal tanpa rincian produk, sehingga pada tabel fakta target hanya dicatat satu kali pada baris *surrogate key* khusus produk `produk_key = -2` (*Tanpa Produk / Baris Target*) demi mencegah terjadinya penggandaan nilai target (*overcounting*) saat dilakukan agregasi lintas produk.
5. **Standarisasi Tipe Data & Presisi Keuangan:** Menggunakan tipe data `DECIMAL(14,4)` untuk seluruh ukuran finansial (`target_penjualan`, `realisasi_penjualan`, `selisih_realisasi_target`, `bonus`, dan `list_price`).

---

## 2. Penerapan Metodologi 4 Langkah Kimball (Versi 2)

### Langkah 1: Memilih Proses Bisnis (*Select the Business Process*)
Proses bisnis yang dimodelkan tetap konsisten: **Evaluasi Kinerja Penjualan vs Kuota Target (*Sales Performance vs Quota Evaluation*)**, yang memadukan data penetapan kuota staf penjualan dengan realisasi transaksi pesanan reseller (B2B).

### Langkah 2: Menyatakan Grain (*Declare the Grain*)
Grain diperluas ke tingkat produk agar mampu menjawab pertanyaan bisnis mengenai volume penjualan barang dan rata-rata realisasi per unit:

> [!IMPORTANT]
> **PERNYATAAN GRAIN VERSI 2 (SATU KALIMAT):**  
> *"Satu baris di `fact_kinerja_sales_v2` mewakili target atau realisasi penjualan satu sales person dalam satu kuartal kalender untuk satu wilayah dan satu produk tertentu."*

### Langkah 3: Mengidentifikasi Dimensi (*Identify the Dimensions*)
Model dimensional Versi 2 didukung oleh **5 tabel dimensi** terstandarisasi:
1. **Dimensi Tanggal (`dim_tanggal`):** Konformasi enterprise kalender via `tanggal_kuartal_key`.
2. **Dimensi Sales Person (`dim_sales_person`):** Profil staf penjualan dengan pelacakan riwayat jabatan, komisi, dan bonus (SCD Tipe 2).
3. **Dimensi Wilayah (`dim_wilayah`):** Kawasan regional dan teritori penugasan pemasaran (SCD Tipe 1).
4. **Dimensi Produk (`dim_produk`):** Katalog barang dagangan, kategori, subkategori, dan harga jual (SCD Tipe 1).
5. **Dimensi Kategori Kinerja (`dim_kategori_kinerja`):** Tabel referensi klasifikasi capaian target (SCD Tipe 1/0).

### Langkah 4: Mengidentifikasi Fakta (*Identify the Facts*)
Ukuran metrik numerik pada tabel fakta `fact_kinerja_sales_v2` meliputi:
* **`target_penjualan`** (DECIMAL(14,4)): Kuota target penjualan kuartalan (hanya ada pada baris `produk_key = -2`).
* **`realisasi_penjualan`** (DECIMAL(14,4)): Akumulasi nilai bersih (`LineTotal`) pesanan reseller.
* **`selisih_realisasi_target`** (DECIMAL(14,4)): Nilai selisih (`realisasi_penjualan − target_penjualan`).
* **`jumlah_terjual`** (INT): Total kuantitas barang fisik yang berhasil terjual (`OrderQty`).
* **`kategori_kinerja_key`** (INT): Kunci penunjuk status klasifikasi performa kuartalan.

---

## 3. Diagram Arsitektur Star Schema Versi 2
Struktur arsitektur relasional Star Schema Versi 2 menempatkan tabel fakta `fact_kinerja_sales_v2` di pusat yang terhubung langsung dengan kelima dimensi melalui integritas referensial (*Foreign Key*):

![Diagram Arsitektur Star Schema Versi 2](<Bukti Gamber/starschema_v2.png>)

*Gambar: Diagram Arsitektur Star Schema Versi 2 (`fact_kinerja_sales_v2`)*

---

## 4. Perbandingan Arsitektur: Versi 1 vs Versi 2

| Aspek Rancangan | Star Schema Versi 1 (`fact_kinerja_sales`) | Star Schema Versi 2 (`fact_kinerja_sales_v2`) | Justifikasi Perubahan |
|:---|:---|:---|:---|
| **Grain Fakta** | Salesperson × Kuartal × Wilayah | **Salesperson × Kuartal × Wilayah × Produk** | Mengakomodasi kebutuhan analisis per produk dan rata-rata realisasi per unit barang. |
| **Jumlah Dimensi** | 3 Dimensi (`dim_tanggal`, `dim_sales_person`, `dim_wilayah`) | **5 Dimensi** (`+ dim_produk`, `+ dim_kategori_kinerja`) | Analisis barang dagangan dan kategorisasi status target secara terstandarisasi. |
| **Dimensi Tanggal** | Dimensi kuartalan khusus (`sk_tanggal_kuartal`) | **`dim_tanggal` Enterprise v1.0** (`tanggal_key` = YYYYMMDD) | Standarisasi shared dimension lintas seluruh tim enterprise DW. |
| **Penanganan Target** | Satu target per baris fakta agregat | **CR-01:** Target hanya pada baris `produk_key = -2` | Mencegah target terhitung berlipat ganda (*overcounting*) saat di-SUM lintas produk. |
| **Ukuran Volume Penjualan** | `jumlah_pesanan` (COUNT nota) | **`jumlah_terjual`** (SUM `OrderQty`) | Konsisten dengan grain produk untuk menghitung rata-rata nilai per unit. |
| **Penanda Kinerja** | Flag boolean `ada_target` (0/1) | **FK `kategori_kinerja_key`** ke `dim_kategori_kinerja` | Klasifikasi bisnis lebih kaya: *Tercapai, Belum Tercapai, Tanpa Target, Target Saja*. |
| **Presisi Finansial** | `DECIMAL(15,2)` | **`DECIMAL(14,4)`** | Mencegah rounding error sesuai struktur data sumber Adventure Works. |

---

## 5. Kamus Data Spesifikasi Tabel Data Warehouse Versi 2

### 1. Tabel Fakta: `fact_kinerja_sales_v2`

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan & Sumber Data |
|:---|:---|:---:|:---:|:---|
| `tanggal_kuartal_key` | INT | PK, FK | No | Foreign key ke `dim_tanggal.tanggal_key` (format `YYYYMMDD`). |
| `sales_person_key` | INT | PK, FK | No | Foreign key ke `dim_sales_person.sales_person_key`. |
| `wilayah_key` | INT | PK, FK | No | Foreign key ke `dim_wilayah.wilayah_key`. |
| `produk_key` | INT | PK, FK | No | Foreign key ke `dim_produk.produk_key` (`-2` untuk baris target kuota murni). |
| `target_penjualan` | DECIMAL(14,4) | - | Yes | Kuota penjualan dari `sales_salespersonquotahistory`. Bernilai NULL pada baris produk riil. |
| `realisasi_penjualan` | DECIMAL(14,4) | - | No | Total `LineTotal` pesanan reseller dari `sales_salesorderdetail`. Default 0 pada baris target murni. |
| `selisih_realisasi_target` | DECIMAL(14,4) | - | Yes | `realisasi_penjualan − target_penjualan`. Bernilai NULL bila target NULL. |
| `jumlah_terjual` | INT | - | No | Akumulasi `OrderQty` produk terjual. Bernilai 0 pada baris target kuota murni. |
| `kategori_kinerja_key` | INT | FK | No | Foreign key ke `dim_kategori_kinerja.kategori_kinerja_key` (`-1` s.d. `4`). |

### 2. Tabel Dimensi: `dim_sales_person` (SCD Tipe 2)

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan & Sumber Data |
|:---|:---|:---:|:---:|:---|
| `sales_person_key` | INT AUTO_INC | PK | No | Surrogate key versi profil staf penjualan. |
| `business_entity_id` | INT | - | No | Natural key staf dari `sales_salesperson`. |
| `nama_lengkap` | VARCHAR(150) | - | No | Nama lengkap staf dari `person_person`. |
| `jabatan` | VARCHAR(100) | - | No | Jabatan dari `humanresources_employee` (Atribut SCD Tipe 2). |
| `tanggal_masuk` | DATE | - | No | Tanggal mulai bekerja (`HireDate`). |
| `komisi_pct` | DECIMAL(5,4) | - | No | Persentase komisi staf (Atribut SCD Tipe 2). |
| `bonus` | DECIMAL(14,4) | - | No | Nilai bonus berjalan staf (Atribut SCD Tipe 2). |
| `row_effective_date` | DATE | - | No | Tanggal mulai berlakunya versi dimensi (`1900-01-01` untuk versi awal). |
| `row_expiry_date` | DATE | - | No | Tanggal akhir berlakunya versi dimensi (`9999-12-31` untuk versi aktif). |

### 3. Tabel Dimensi: `dim_wilayah` (SCD Tipe 1)

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan & Sumber Data |
|:---|:---|:---:|:---:|:---|
| `wilayah_key` | INT AUTO_INC | PK | No | Surrogate key wilayah penjualan (`-1` = Tidak diketahui). |
| `territory_id` | INT | - | Yes | Natural key teritori dari `sales_salesterritory` (NULL pada baris `-1`). |
| `nama_wilayah` | VARCHAR(50) | - | No | Nama kawasan operasional (misal: *Northwest*, *Southwest*). |
| `kode_negara` | VARCHAR(3) | - | No | Kode ISO negara (`CountryRegionCode`). |
| `nama_negara` | VARCHAR(50) | - | No | Nama resmi negara dari `person_countryregion`. |
| `grup_wilayah` | VARCHAR(50) | - | No | Wilayah makro (*North America*, *Europe*, *Pacific*). |
| `is_active` | TINYINT(1) | - | No | Status operasional wilayah (Default `1`). |

### 4. Tabel Dimensi: `dim_produk` (SCD Tipe 1)

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan & Sumber Data |
|:---|:---|:---:|:---:|:---|
| `produk_key` | INT AUTO_INC | PK | No | Surrogate key produk (`-1` = Unknown, `-2` = Tanpa Produk / Baris Target). |
| `product_id` | INT | - | No | Natural key produk dari `production_product`. |
| `nama_produk` | VARCHAR(50) | - | No | Nama resmi barang dagangan. |
| `nomor_produk` | VARCHAR(25) | - | No | Kode serial/nomor katalog produk. |
| `sub_kategori` | VARCHAR(50) | - | No | Nama subkategori dari `production_productsubcategory`. |
| `kategori` | VARCHAR(50) | - | No | Nama kategori makro dari `production_productcategory`. |
| `list_price` | DECIMAL(14,4) | - | No | Harga katalog resmi produk. |

### 5. Tabel Dimensi: `dim_kategori_kinerja` (SCD Tipe 0/1)

| Nama Kolom | Tipe Data | PK/FK | Null? | Keterangan & Nilai Domain |
|:---|:---|:---:|:---:|:---|
| `kategori_kinerja_key` | INT AUTO_INC | PK | No | Surrogate key kategori kinerja. |
| `kode_kategori` | VARCHAR(20) | - | No | Kode unik kategori (`TERCAPAI`, `BELUM_TERCAPAI`, `TANPA_TARGET`, `TARGET_SAJA`, `UNKNOWN`). |
| `nama_kategori` | VARCHAR(50) | - | No | Deskripsi nama kategori yang tampil di laporan visual. |
| `keterangan_rentang` | VARCHAR(100) | - | Yes | Keterangan batas formula rasio pencapaian target. |

### 6. Tabel Dimensi: `dim_tanggal` (SCD Tipe 0 - Standar Enterprise v1.0)
Struktur tabel dimensi kalender menggunakan standar kelas berisi 2.192 baris hari kalender (2011 s.d. 2016) dan baris `-1` (Tidak diketahui):
* **Atribut Kunci:** `tanggal_key` (INT PK, format `YYYYMMDD`).
* **Atribut Kalender:** `tanggal` (DATE UNIQUE), `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan`.

---

## 6. Aturan Integritas Basis Data & Constraint

Untuk menjamin kualitas dan konsistensi data sebelum maupun sesudah pemuatan ETL, skema fisik `fact_kinerja_sales_v2` diproteksi secara ketat pada lapisan basis data:

1. **Integritas Entitas & Idempotensi (Composite Primary Key):**
   ```sql
   PRIMARY KEY (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key)
   ```
   Kombinasi keempat surrogate key dimensi ini menjamin tidak ada baris ganda pada grain yang sama.
2. **Integritas Referensial (Foreign Key):**
   Tabel fakta memiliki 5 relasi *Foreign Key* yang merujuk langsung ke *Primary Key* masing-masing dimensi (`fk_fkjs_tanggal`, `fk_fkjs_sales_person`, `fk_fkjs_wilayah`, `fk_fkjs_produk`, `fk_fkjs_kategori`).
3. **Validasi Domain Bisnis (CHECK Constraint):**
   * `CONSTRAINT ck_fkjs_jumlah CHECK (jumlah_terjual >= 0)`
   * `CONSTRAINT ck_fkjs_realisasi CHECK (realisasi_penjualan >= 0)`
   * `CONSTRAINT ck_fkjs_target CHECK (target_penjualan IS NULL OR target_penjualan >= 0)`
   * `CONSTRAINT ck_fkjs_selisih CHECK (target_penjualan IS NOT NULL OR selisih_realisasi_target IS NULL)`
   * `CONSTRAINT ck_dim_sales_person_berlaku CHECK (row_effective_date <= row_expiry_date)`
