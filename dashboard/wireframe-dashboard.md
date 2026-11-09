# Spesifikasi dan Wireframe Dashboard Kinerja Sales vs Target

**Proses Bisnis:** Pemantauan & Evaluasi Kinerja Penjualan vs Target (*AdventureWorks Data Warehouse*)  
**Kelompok:** 4 (Empat)  
**Referensi Desain:** [`Dashboard Sales.png`](../Dashboard%20Sales.png)  
**Dokumen Terkait:** [Desain Cube Mondrian](../docs/desain_cube.md) | [Source-to-Target Mapping](../docs/mapping.md)

---

## 1. Ikhtisar & Tujuan Desain

Dashboard ini dirancang untuk memberikan visibilitas menyeluruh kepada jajaran eksekutif penjualan (*Sales VP / Sales Managers*) dalam mengevaluasi pencapaian kuota penjualan, memetakan performa wilayah, mendeteksi anomali volume vs nilai penjualan, mengevaluasi efektivitas skema komisi, serta menyediakan *early warning system* bagi staf penjualan yang mengalami tren penurunan performa.

Desain tata letak disusun secara logis dari atas ke bawah (*top-down analytical flow*):
1. **Global Control Layer:** Slicer / filter interaktif untuk membatasi ruang lingkup analisis.
2. **Executive Summary Layer (KPIs):** Indikator agregat makro realisasi, target, selisih, dan jumlah staf yang memenuhi target.
3. **Macro Trend & Regional Comparison:** Evaluasi komparatif realisasi vs target antar-kuartal dan tren grup wilayah.
4. **Performance Ranking & Distribution:** Peringkat surplus/defisit wilayah dan tingkat keberhasilan kuartalan tiap salesperson.
5. **Productivity & Anomaly Detection:** Analisis korelasi volume fisik (unit terjual) terhadap nilai nominal, serta perbandingan disparitas peringkat.
6. **Incentive Evaluation & Risk Monitoring (Watchlist):** Analisis keterkaitan skema komisi serta daftar pantauan salesperson berkinerja menurun.
7. **Special Case & Anomaly Handling:** Pemantauan realisasi penjualan tanpa kuota target (khususnya kasus historis Q2 2014).

---

## 2. Diagram Tata Letak Wireframe (Grid Layout)

Berikut adalah representasi tata letak visual (*wireframe grid*) yang merefleksikan arsitektur antarmuka pada [`Dashboard Sales.png`](../Dashboard%20Sales.png):

```text
+---------------------------------------------------------------------------------------------------------------------------------+
| FILTER GLOBAL                                                                                                                   |
| [ Tahun v ]  [ Kuartal v ]  [ Grup Wilayah v ]  [ Wilayah v ]  [ Salesperson v ]  [ Kategori Kinerja v ]                        |
+---------------------------------------------------------------------------------------------------------------------------------+
| [ KPI 1: Realisasi ]  | [ KPI 2: Target ]   | [ KPI 3: Selisih ]      | [ KPI 4: Capai Target ] | [ KPI 5: Tanpa Target ]       |
| Rp [Nilai]            | Rp [Nilai]          | Rp [Nilai]              | [N] Orang               | [N] Salesperson               |
| +/-% vs Q lalu  (P1)  | +/-% vs Q lalu (P1) | % Capaian          (P1) | % dari Total       (P3) | Rp [Nilai Realisasi]     (P7) |
+---------------------------------------------------------------+-----------------------------------------------------------------+
| COMBO CHART: REALISASI VS TARGET PER KUARTAL                  | LINE CHART: SELISIH PER GRUP WILAYAH                            |
| Batang berpasangan (Realisasi & Target), garis selisih (P1)   | Tren selisih waktu per grup wilayah (North America, Europe, dll)|
| [ Clustered Column + Line ]                                   | [ Multi-line Chart ]                                       (P1) |
+---------------------------------------------------------------+-----------------------------------------------------------------+
| DIVERGING BAR: WILAYAH VS TARGET PER TAHUN                    | STACKED BAR: KUARTAL TERCAPAI PER SALESPERSON                   |
| [< Melampaui (Hijau) | Di Bawah (Merah) >] per Wilayah        | 100% Stacked Bar per Salesperson: Tercapai vs Tidak Tercapai    |
| [Selektor Tahun]                           [Diverging Bar] (P2)| Sorotan garis merah bagi salesperson capaian 0             (P3) |
+---------------------------------------------------------------+-----------------------------------------------------------------+
| SCATTER PLOT: UNIT TERJUAL VS REALISASI                       | TABEL: PERINGKAT UNIT VS PERINGKAT REALISASI                    |
| Korelasi volume barang vs nilai penjualan nominal             | Komparasi disparitas peringkat volume vs nilai rupiah           |
| Outlier di bawah garis tren = volume tinggi tapi nilai rendah | Salesperson | Wilayah | Unit | Rank Unit | Rank Real | Real/Unit|
| [ Scatter + Trendline ]                                   (P4)| [ Tabel dengan Peringkat ]                                 (P4) |
+---------------------------------------------------------------+-----------------------------------------------------------------+
| COLUMN CHART + MARKER: KELOMPOK KOMISI                        | TABEL WATCHLIST DENGAN SPARKLINE: SELISIH MEMBURUK              |
| Batang: Kuartal tercapai per kelompok komisi                  | Salesperson dengan penurunan selisih berturut-turut             |
| Marker (Titik): Rata-rata selisih nominal                     | Salesperson | Wilayah | K-2 | K-1 | K0 | Sparkline Tren | Status |
| [ Column + Dot (Dual Axis) ]                              (P5)| [ Tabel + Sparkline + Penanda Status (Warning) ]           (P6) |
+---------------------------------------------------------------+-----------------------------------------------------------------+
| KARTU: SALESPERSON TANPA TARGET                               | STACKED COLUMN: REALISASI TANPA TARGET PER KUARTAL              |
| [ Big Number Card ]                                           | Nilai realisasi kategori "Tanpa Target" dari kuartal ke kuartal |
| Salesperson tanpa target: [N]                                 | Ditumpuk (stacked) berdasarkan grup wilayah                     |
| Realisasi tidak terukur: [Rp Nilai]                       (P7)| [ Stacked Column Chart ]                                   (P7) |
+---------------------------------------------------------------------------------------------------------------------------------+
| Keterangan: (P1) sampai (P7) merujuk pada nomor Pertanyaan Bisnis yang dijawab oleh masing-masing visual.                       |
+---------------------------------------------------------------------------------------------------------------------------------+
```

---

## 3. Spesifikasi Rinci Komponen Dashboard

### 3.1. Filter Global (Slicer Header)
* **Keterangan:** Berlaku secara global untuk seluruh komponen visual pada dashboard, **kecuali visual P2** yang menggunakan selektor independen berbasis tahun.
* **Komponen Filter:**
  1. `Tahun` (Dropdown single/multi-select dari hierarki `dim_tanggal.tahun`)
  2. `Kuartal` (Dropdown multi-select dari hierarki `dim_tanggal.kuartal`)
  3. `Grup Wilayah` (Dropdown filter dari `dim_wilayah.grup_wilayah`: *North America*, *Europe*, *Pacific*)
  4. `Wilayah` (Dropdown hierarkis dari `dim_wilayah.nama_wilayah`)
  5. `Salesperson` (Dropdown filter dari `dim_sales_person.nama_lengkap`)
  6. `Kategori Kinerja` (Dropdown filter dari `dim_kategori_kinerja.kategori_kinerja`: *Melampaui Target*, *Memenuhi Target*, *Kurang*, *Tanpa Target*)

---

### 3.2. Baris 1: Executive KPI Cards

| Komponen | Judul Visual | Tipe Komponen | Pertanyaan Bisnis | Metrik & Formula yang Ditampilkan | Penjelasan & Format |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **KPI 1** | **Total Realisasi** | *Card KPI* | **P1** | `SUM(realisasi_penjualan)` & `MoM/QoQ Growth (%)` | Nilai mata uang (`Rp [nilai]`) disertai persentase perubahan dibandingkan kuartal sebelumnya (indikator panah hijau jika naik, merah jika turun). |
| **KPI 2** | **Total Target** | *Card KPI* | **P1** | `SUM(target_penjualan)` & `QoQ Change (%)` | Nilai mata uang (`Rp [nilai]`) kuota target teragregasi dan persentase perubahan kuota target dibanding kuartal lalu. |
| **KPI 3** | **Selisih Realisasi dan Target** | *Card KPI* | **P1** | `SUM(selisih_realisasi)` & `% Pencapaian` (`Realisasi / Target * 100`) | Nilai selisih absolut (`Rp [nilai]`) dan rasio pencapaian terhadap target. Warna teks otomatis hijau jika positif (surplus) atau merah jika negatif (defisit). |
| **KPI 4** | **Salesperson Capai Target** | *Card KPI* | **P3** | `COUNT(DISTINCT salesperson_key)` dengan Kategori Tercapai & `% dari Total Bertarget` | Jumlah staf penjualan yang memenuhi atau melampaui kuota pada periode terpilih (`[N] orang`) beserta proporsinya terhadap total staf aktif berkuota. |
| **KPI 5** | **Realisasi Tanpa Target** | *Card KPI* | **P7** | `COUNT(DISTINCT salesperson_key)` & `SUM(realisasi_penjualan)` pada kategori `Tanpa Target` | Menampilkan jumlah staf yang membukukan penjualan tanpa kuota target serta total akumulasi rupiah penjualannya (`[N] orang`, `Rp [nilai]`). |

---

### 3.3. Baris 2: Analisis Tren Makro & Selisih Regional (Menjawab P1)

#### 1. Combo Chart: Realisasi vs Target per Kuartal
* **Judul:** Combo chart: realisasi vs target per kuartal
* **Tipe Visual:** *Clustered Column + Line Chart*
* **Pertanyaan Bisnis Terkait:** **P1** (Perkembangan realisasi vs target dari kuartal ke kuartal)
* **Sumbu X:** Periode Kuartal Berurutan (`dim_tanggal.tahun_kuartal`, misal: `2011-Q3`, `2011-Q4`, ...)
* **Sumbu Y1 (Kiri - Batang Berpasangan):**
  - Batang 1: `Realisasi Penjualan` (Warna Biru Solid)
  - Batang 2: `Target Penjualan` (Warna Biru Bergaris/Aksen Emas)
* **Sumbu Y2 (Kanan - Garis Tren):**
  - Garis: `Selisih Realisasi` (Warna Hijau/Teal dengan marker titik pada tiap titik kuartal)
* **Interaktivitas:** *Hover tooltip* menampilkan rincian nominal realisasi, target, selisih kuartal, serta % pencapaian.

#### 2. Line Chart: Selisih per Grup Wilayah
* **Judul:** Line chart: selisih per grup wilayah
* **Tipe Visual:** *Multi-line Chart*
* **Pertanyaan Bisnis Terkait:** **P1** (Komparasi performa selisih per grup wilayah)
* **Sumbu X:** Kuartal Waktu (`dim_tanggal.kuartal` / `tahun_kuartal`)
* **Sumbu Y:** `Selisih Realisasi` (Nilai nominal rupiah; garis nol di tengah memisahkan area surplus dan defisit)
* **Series / Legend:** `Grup Wilayah` (*North America*, *Europe*, *Pacific*)
* **Interaktivitas:** Klik pada salah satu garis grup wilayah akan menyaring visual tabel dan kartu di bawahnya (*cross-filtering*).

---

### 3.4. Baris 3: Pemeringkatan Wilayah & Keberhasilan Salesperson (Menjawab P2 & P3)

#### 1. Diverging Bar Horizontal: Wilayah vs Target per Tahun
* **Judul:** Diverging bar horizontal: wilayah vs target per tahun
* **Tipe Visual:** *Diverging Bar Chart (Horizontal Ranking)*
* **Pertanyaan Bisnis Terkait:** **P2** (Wilayah paling melampaui dan paling di bawah target per tahun)
* **Kontrol Lokal:** Dropdown khusus `Selektor Tahun` di atas chart (memungkinkan evaluasi komparatif tahunan tanpa terpengaruh filter kuartal global).
* **Sumbu Y:** Daftar `Nama Wilayah` (`dim_wilayah.nama_wilayah`), diurutkan dari selisih tertinggi ke terendah.
* **Sumbu X:** `Selisih Realisasi` dengan baseline tengah di angka 0:
  - **Bar Kanan (Hijau):** Wilayah surplus (*Melampaui Target*)
  - **Bar Kiri (Merah/Salmon):** Wilayah defisit (*Di Bawah Target*)
* **Insight:** Memudahkan manajemen mengidentifikasi secara instan wilayah peringkat teratas (*top performing territory*) dan wilayah yang membutuhkan perhatian (*underperforming territory*).

#### 2. Stacked Bar Horizontal: Kuartal Tercapai per Salesperson
* **Judul:** Stacked bar horizontal: kuartal tercapai per salesperson
* **Tipe Visual:** *100% Stacked Bar Chart*
* **Pertanyaan Bisnis Terkait:** **P3** (Jumlah kuartal tiap salesperson berhasil mencapai target)
* **Sumbu Y:** Nama Salesperson (`dim_sales_person.nama_lengkap`)
* **Sumbu X:** Persentase / Proporsi Kuartal (0% - 100%)
* **Segmen Warna:**
  - **Hijau:** Proporsi kuartal dengan status "Tercapai" (`Kategori Kinerja IN ('Melampaui Target', 'Memenuhi Target')`)
  - **Abu-abu / Biru Gelap:** Proporsi kuartal dengan status "Tidak Tercapai" (`Kategori Kinerja = 'Kurang'`)
* **Fitur Penanda Khusus:** Garis pembatas putus-putus merah di bagian bawah untuk menyorot staf yang **0 kali mencapai target** (*never reached target*).

---

### 3.5. Baris 4: Analisis Produktivitas & Efisiensi Penjualan (Menjawab P4)

#### 1. Scatter Plot: Unit Terjual vs Realisasi
* **Judul:** Scatter plot: unit terjual vs realisasi
* **Tipe Visual:** *Scatter Plot + Trendline*
* **Pertanyaan Bisnis Terkait:** **P4** (Perbandingan unit terjual vs realisasi nilai penjualan)
* **Sumbu X:** `Jumlah Unit Terjual` (Volume fisik produk)
* **Sumbu Y:** `Realisasi Penjualan` (Nilai nominal rupiah)
* **Elemen Visual:**
  - Setiap titik lingkaran merepresentasikan satu orang staf penjualan (`Salesperson`).
  - Dilengkapi garis tren linier (*linear trendline*).
* **Identifikasi Anomali:** Titik merah/oranye yang jatuh jauh di bawah garis tren menunjukkan salesperson dengan volume transaksi tinggi namun nilai rupiah rendah (indikasi dominasi penjualan produk bermargin/berharga murah).

#### 2. Tabel: Peringkat Unit vs Peringkat Realisasi
* **Judul:** Tabel: peringkat unit vs peringkat realisasi
* **Tipe Visual:** *Ranked Data Table*
* **Pertanyaan Bisnis Terkait:** **P4** (Disparitas peringkat volume vs nilai rupiah & rata-rata per unit)
* **Format Kolom Tabel:**
  ```text
  +------------------+---------------+-------------+----------------+---------------------+--------------------+
  | Salesperson      | Wilayah       | Unit Terjual| Peringkat Unit | Peringkat Realisasi | Realisasi per Unit |
  +------------------+---------------+-------------+----------------+---------------------+--------------------+
  | [Nama Lengkap]   | [Nama Wilayah]| [n] unit    | #[Rank Volume] | #[Rank Nilai Rp]    | Rp [Nilai Rata2]   |
  +------------------+---------------+-------------+----------------+---------------------+--------------------+
  ```
* **Kalkulasi Khusus:** Kolom `Realisasi per Unit` dihitung melalui calculated member:  
  $$\text{Realisasi per Unit} = \frac{\text{SUM}(realisasi\_penjualan)}{\text{SUM}(jumlah\_unit\_terjual)}$$

---

### 3.6. Baris 5: Evaluasi Skema Komisi & Early Warning System (Menjawab P5 & P6)

#### 1. Column Chart + Marker: Kelompok Komisi
* **Judul:** Column chart + marker: kelompok komisi
* **Tipe Visual:** *Column + Dot / Marker (Dual Axis)*
* **Pertanyaan Bisnis Terkait:** **P5** (Kelompok komisi paling sering mencapai target & rata-rata selisih terbaik)
* **Sumbu X:** `Kelompok Komisi` (`dim_komisi_sales.kelompok_komisi`, misal: Rendah, Sedang, Tinggi)
* **Sumbu Y1 (Kiri - Bar Kolom Biru):** Jumlah kuartal berstatus tercapai (`Jumlah Kuartal Teramati` dengan Kategori Tercapai)
* **Sumbu Y2 (Kanan - Marker Oranye):** Rata-rata selisih nominal (`Rata-rata Selisih per Kuartal`)
* **Tujuan Manajerial:** Memvalidasi apakah kelompok staf dengan persentase komisi lebih tinggi berkorelasi dengan frekuensi pencapaian target dan surplus penjualan yang lebih besar.

#### 2. Tabel Watchlist dengan Sparkline: Selisih Memburuk
* **Judul:** Tabel watchlist dengan sparkline: selisih memburuk
* **Tipe Visual:** *Interactive Table with Embedded Sparklines & Alert Badges*
* **Pertanyaan Bisnis Terkait:** **P6** (Salesperson dengan tren selisih memburuk dalam 3 kuartal berurutan)
* **Pengurutan (*Sorting*):** Diurutkan menurun (*descending*) berdasarkan besaran penurunan performa terdalam.
* **Format Kolom Tabel:**
  ```text
  +------------------+---------------+-------------+-------------+-------------+-----------------+-------------------+
  | Salesperson      | Wilayah       | Selisih K-2 | Selisih K-1 | Selisih K0  | Tren            | Status            |
  +------------------+---------------+-------------+-------------+-------------+-----------------+-------------------+
  | [Nama Lengkap]   | [Nama Wilayah]| Rp [Nilai]  | Rp [Nilai]  | Rp [Nilai]  | \___ (Sparkline)| [Perlu Penanganan]|
  +------------------+---------------+-------------+-------------+-------------+-----------------+-------------------+
  ```
* **Keterangan Kolom:**
  - `K-2`, `K-1`, `K0`: Nilai selisih realisasi pada 3 kuartal berurutan terakhir ($K_0$ adalah kuartal aktif).
  - `Tren`: Grafik mikro (*sparkline line*) berwarna merah yang menunjukkan kurva kemiringan penurunan.
  - `Status`: Badge peringatan visual (*Warning Chip* warna merah/oranye: "Perlu penanganan") untuk memicu intervensi manajemen/coaching.

---

### 3.7. Baris 6: Analisis Kasus Khusus / Tanpa Target (Menjawab P7)

#### 1. Kartu: Salesperson Tanpa Target
* **Judul:** Kartu: salesperson tanpa target
* **Tipe Visual:** *Big Number KPI Summary Card*
* **Pertanyaan Bisnis Terkait:** **P7** (Pemantauan staf berpenjualan tanpa beban kuota)
* **Konten Tampilan:**
  - Label 1: `Salesperson tanpa target`  
    **Besar Angka:** `[N]` (Jumlah staf aktif)
  - Label 2: `Realisasi tidak terukur`  
    **Besar Angka:** `[Rp nilai]` (Total akumulasi penjualan yang dibukukan)

#### 2. Stacked Column: Realisasi Tanpa Target per Kuartal
* **Judul:** Stacked column: realisasi tanpa target per kuartal
* **Tipe Visual:** *Stacked Column Chart*
* **Pertanyaan Bisnis Terkait:** **P7** (Distribusi kuartalan realisasi tanpa target berdasarkan grup wilayah)
* **Sumbu X:** Periode Kuartal (`dim_tanggal.tahun_kuartal`)
* **Sumbu Y:** Total Realisasi Kategori "Tanpa Target" (Nominal Rupiah)
* **Segmen Tumpukan (Stack):** `Grup Wilayah` (*North America*, *Europe*, *Pacific*)
* **Kontekstualisasi Data:** Lonjakan signifikan pada kuartal 2014-Q2 merefleksikan kondisi bisnis di mana manajemen AdventureWorks tidak menetapkan kuota kuartalan namun aktivitas operasional penjualan tetap berjalan.

---

## 4. Matriks Ketertelusuran Pertanyaan Bisnis (Traceability Matrix)

| No. | Rumusan Pertanyaan Bisnis Revisi Dosen | Komponen Visual Dashboard | Dimensi & Granularitas | Measure / Calculated Member Terlibat |
| :---: | :--- | :--- | :--- | :--- |
| **P1** | Perkembangan total realisasi vs target dari kuartal ke kuartal per grup wilayah | • KPI 1, 2, 3<br>• Combo Chart (Realisasi vs Target)<br>• Line Chart (Selisih per Grup Wilayah) | `dim_tanggal` (Tahun, Kuartal)<br>`dim_wilayah` (Grup Wilayah) | `realisasi_penjualan`<br>`target_penjualan`<br>`selisih_realisasi` |
| **P2** | Wilayah paling melampaui dan paling di bawah target per tahun | • Diverging Bar Horizontal (Wilayah vs Target per Tahun) | `dim_wilayah` (Nama Wilayah)<br>`dim_tanggal` (Tahun) | `selisih_realisasi` |
| **P3** | Jumlah kuartal tiap salesperson berhasil mencapai target | • KPI 4<br>• 100% Stacked Bar Horizontal (Kuartal Tercapai per Salesperson) | `dim_sales_person` (Nama Lengkap)<br>`dim_kategori_kinerja`<br>`dim_tanggal` (Kuartal) | `jumlah_kuartal_teramati`<br>Distinct Count `sales_person_key` |
| **P4** | Perbandingan unit terjual vs realisasi dan rata-rata realisasi per unit | • Scatter Plot (Unit vs Realisasi)<br>• Tabel Peringkat Unit vs Realisasi | `dim_sales_person`<br>`dim_wilayah` | `jumlah_unit_terjual`<br>`realisasi_penjualan`<br>`[Realisasi Rata-rata per Unit]` |
| **P5** | Kelompok komisi paling sering mencapai target dan rata-rata selisih terbaik | • Column Chart + Marker (Kelompok Komisi) | `dim_komisi_sales` (Kelompok Komisi)<br>`dim_kategori_kinerja` | `jumlah_kuartal_teramati`<br>`[Rata-rata Selisih per Kuartal]` |
| **P6** | Salesperson dengan tren selisih memburuk dalam kuartal berurutan | • Tabel Watchlist dengan Sparkline | `dim_sales_person`<br>`dim_wilayah`<br>`dim_tanggal` (Lag K-2, K-1, K0) | `selisih_realisasi` (Lag Analysis) |
| **P7** | Salesperson dengan realisasi tanpa target dan nilai realisasinya | • KPI 5<br>• Kartu Salesperson Tanpa Target<br>• Stacked Column Realisasi Tanpa Target | `dim_kategori_kinerja` ("Tanpa Target")<br>`dim_wilayah` (Grup Wilayah)<br>`dim_tanggal` (Kuartal) | `realisasi_penjualan`<br>Distinct Count `sales_person_key` |

---

## 5. Panduan Desain Visual & Tata Warna (Theme Tokens)

Untuk menghasilkan tampilan eksekutif yang konsisten sesuai rancangan mockup:

* **Tema Latar Belakang (*Dark Modern Theme*):**
  - Background Dashboard: `#0d1726` (Deep Slate / Dark Navy)
  - Card / Panel Container: `#162238` (Elevated Navy Slate dengan outline `#223354`)
* **Palet Warna Indikator Kinerja:**
  - **Surplus / Tercapai / Melampaui:** Hijau Emerald (`#22c55e`)
  - **Defisit / Tidak Tercapai / Peringatan:** Merah Coral / Salmon (`#ef4444`)
  - **Realisasi Penjualan:** Biru Cerah (`#3b82f6`)
  - **Target Penjualan:** Garis Emas / Amber (`#f59e0b`)
  - **Grup Wilayah / Multi-series:** Biru (`#38bdf8`), Oranye (`#fb923c`), Ungu (`#a855f7`)
* **Format Tipografi Angka:**
  - Nominal Mata Uang: Menggunakan pemisah ribuan standar (misal: `Rp 1.250.000.000` atau singkatan ringkas pada grafik: `Rp 1,25M`).
  - Persentase: Ditampilkan dengan 1 desimal (misal: `104,5%`).

