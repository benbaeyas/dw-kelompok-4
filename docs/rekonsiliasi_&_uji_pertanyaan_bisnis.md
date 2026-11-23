# Laporan Rekonsiliasi Data & Pengujian Pertanyaan Bisnis

**Kelompok:** 4 (Empat)  
**Proses Bisnis:** Kinerja Sales vs Target  
**Database Target:** `adn_kl4` / `adn_kl4-v2`  
**Tabel Utama:** `fact_kinerja_sales_v2`  
**Referensi Pipeline:** `etl/job_utama.kjb` & `docs/panduan_etl.md`  

---

## 1. Pendahuluan

Laporan ini menyajikan hasil evaluasi pasca-eksekusi pipeline ETL Pentaho Data Integration (`etl/job_utama.kjb`) yang mencakup dua pilar pengujian utama:
1. **Rekonsiliasi Integritas Data (*Data Reconciliation*):** Membuktikan bahwa pemuatan data dari staging ke Data Warehouse berlangsung utuh, akurat, dan memenuhi seluruh batasan arsitektural.
2. **Pengujian Kueri SQL Pertanyaan Bisnis (*Business Questions Verification*):** Membuktikan bahwa skema Data Warehouse yang telah terisi mampu menjawab 5 pertanyaan bisnis analitik strategis secara presisi dan objektif.

---

## BAGIAN I: REKONSILIASI DATA WAREHOUSE

Rekonsiliasi dijalankan pada database Data Warehouse setelah seluruh alur transformasi ETL dieksekusi secara lengkap.

### 1.1. Rekonsiliasi Ukuran Utama (Staging vs Fakta DW)

Pengujian ini membandingkan agregasi total nilai transaksi reseller dan target kuota antara tabel staging mentah dengan tabel fakta `fact_kinerja_sales_v2`:

| Ukuran Metrik | Nilai Staging | Nilai Fakta DW | Selisih | Status |
|:---|:---:|:---:|:---:|:---:|
| **Total Realisasi Penjualan** | Rp 80.487.704,1792 | Rp 80.487.704,1914 | -0,0122 | **COCOK (99,9999%)** |
| **Total Unit Terjual** | 214.516,0 | 214.516,0 | 0,0 | **COCOK (100%)** |
| **Total Target (Kuota)** | Rp 95.714.000,0 | Rp 95.714.000,0 | 0,0 | **COCOK (100%)** |
| **Jumlah Salesperson-Kuartal Bertarget** | 163,0 | 163,0 | 0,0 | **COCOK (100%)** |
| **Total Selisih (Realisasi − Target)** | -Rp 18.643.059,6714 | -Rp 18.643.059,6833 | 0,0119 | **COCOK (99,9999%)** |

> [!NOTE]
> Selisih nominal sebesar Rp 0,012 pada total realisasi penjualan (kurang dari 2 sen pada perputaran omzet 80,4 miliar rupiah) timbul akibat perbedaan presisi pembulatan desimal (*rounding difference*) antara floating-point perhitungan baris per baris staging dengan `DECIMAL(14,4)` pada tabel fakta. Secara nominal bisnis dan matematis, data terbukti **rekonsiliasi sempurna**.

![Bukti Rekonsiliasi Ukuran Utama](<Bukti Gamber/rekonsiliasi 1.png>)

*Gambar 1.1: Hasil eksekusi kueri rekonsiliasi metrik utama (Staging vs Fakta).*

---

### 1.2. Rekonsiliasi Volume Baris Tabel Dimensi

Verifikasi volume baris pada seluruh tabel dimensi untuk memastikan tidak ada data master yang hilang atau terduplikasi:

| Nama Tabel Dimensi | Jumlah Baris Terbentuk | Target / Harapan | Status |
|:---|:---:|:---:|:---:|
| `dim_tanggal` | 2.192 | 2.192 | **COCOK** |
| `dim_wilayah` | 11 | 11 | **COCOK** |
| `dim_produk` | 506 | 506 | **COCOK** |
| `dim_sales_person` (Baris Aktif) | 18 | 18 | **COCOK** |
| `dim_kategori_kinerja` | 5 | 5 | **COCOK** |

![Bukti Rekonsiliasi Dimensi](<Bukti Gamber/rekonsiliasi 2.png>)

*Gambar 1.2: Hasil kueri verifikasi kecocokan jumlah baris seluruh tabel dimensi.*

---

### 1.3. Audit Kualitas Kunci Asing & Penanganan Nilai Tak Diketahui

Pemeriksaan integritas referensial dan penanganan baris tanpa wilayah (*unassigned territory*) pada tabel fakta `fact_kinerja_sales_v2`:

| Pemeriksaan Kunci Asing | Jumlah Baris Tak Diketahui (`-1`) | Total Baris Fakta | Analisis Temuan |
|:---|:---:|:---:|:---|
| **Salesperson Tidak Diketahui** | **0** | 16.888 | Seluruh baris transaksi terpetakan ke staf penjualan valid. |
| **Wilayah Tidak Diketahui** | **1.225** | 16.888 | Berasal dari transaksi pesanan korporat 3 manajer (ID 274, 285, 287) yang tidak memiliki penugasan teritori tunggal. |
| **Produk Tidak Diketahui** | **0** | 16.888 | Seluruh barang pesanan terpetakan ke master produk valid. |
| **Kategori Tidak Diketahui** | **0** | 16.888 | Seluruh baris fakta terklasifikasi secara sempurna. |

![Bukti Audit Foreign Key dan Wilayah Tak Diketahui](<Bukti Gamber/rekonsiliasi 3.png>)

*Gambar 1.3: Hasil kueri audit keberadaan foreign key default -1 pada tabel fakta.*

---

### 1.4. Rekonsiliasi Distribusi Kategori Kinerja

Distribusi status pencapaian target pada tingkat agregasi staf penjualan per kuartal:

| Kode Kategori Kinerja | Jumlah Salesperson-Kuartal | Keterangan Logika Bisnis |
|:---|:---:|:---|
| `BELUM_TERCAPAI` | 124 | Realisasi penjualan di bawah kuota target (< 100%). |
| `TERCAPAI` | 37 | Realisasi penjualan memenuhi atau melampaui kuota target (≥ 100%). |
| `TANPA_TARGET` | 16 | Realisasi penjualan pada kuartal 2014 Q2 (tidak ada penetapan target kuota). |
| `TARGET_SAJA` | 2 | Penetapan kuota target tanpa adanya transaksi penjualan (Staf 274 pada 2011 Q2 & Staf 285 pada 2013 Q2). |
| **Total Periode Teramati** | **179** | **Cocok 100% dengan total baris analisis pada BAB III Data Profiling.** |

![Bukti Distribusi Kategori Kinerja](<Bukti Gamber/rekonsiliasi 4.png>)

*Gambar 1.4: Hasil kueri rekonsiliasi distribusi kategori kinerja kuartalan.*

---

### 1.5. Audit Khusus Kuartal Tanpa Target (2014 Q2)

Verifikasi penanganan khusus untuk Kuartal 2 Tahun 2014 (`tanggal_kuartal_key = 20140401`):

* **Jumlah Baris Fakta 2014 Q2:** 1.549 baris.
* **Kode Kategori:** `TANPA_TARGET`.
* **Baris dengan Target NULL:** 1.549 baris (100%).
* **Kesimpulan:** Seluruh baris transaksi 2014 Q2 tersimpan sebagai realisasi murni dengan `target_penjualan = NULL` tanpa memicu pembagian nol (*zero division*) pada kalkulasi rasio persentase.

![Bukti Audit Kuartal 2014 Q2](<Bukti Gamber/rekonsiliasi 5.png>)

*Gambar 1.5: Hasil verifikasi integritas baris kuartal 2014 Q2.*

---

### 1.6. Audit Integritas SCD Tipe 2 (`dim_sales_person`)

Pengecekan konsistensi rentang waktu masa berlaku versi (`row_effective_date` dan `row_expiry_date`) pada dimensi staf penjualan:

* Kueri pemeriksaan baris anomali (tumpang tindih tanggal atau versi tanpa penutup aktif) menghasilkan **0 baris (Himpunan Kosong)**.
* Membuktikan bahwa seluruh 18 baris dimensi staf penjualan konsisten dan valid secara temporal.

![Bukti Integritas SCD Tipe 2](<Bukti Gamber/rekonsiliasi 6.png>)

*Gambar 1.6: Hasil kueri audit validitas rentang tanggal SCD Tipe 2.*

---

## BAGIAN II: PENGUJIAN 5 PERTANYAAN BISNIS (SQL VS DW)

Seluruh pertanyaan bisnis utama dieksekusi menggunakan query SQL pembanding pada skema `fact_kinerja_sales_v2` untuk memvalidasi kesiapan data sebelum diimplementasikan pada skema OLAP Mondrian dan visualisasi Dashboard.

---

### 2.1. Pertanyaan Bisnis 1: Tren Pencapaian Target Kuartalan per Wilayah

* **Rumusan Masalah:** *"Bagaimana perkembangan pencapaian target penjualan dari kuartal ke kuartal, baik secara keseluruhan maupun di setiap wilayah?"*
* **Kueri SQL:**
  ```sql
  SELECT 
      d.tahun,
      d.kuartal,
      w.grup_wilayah,
      SUM(f.target_penjualan) AS target,
      SUM(CASE WHEN f.target_penjualan IS NOT NULL THEN f.realisasi_penjualan ELSE 0 END) AS realisasi_bertarget,
      SUM(f.selisih_realisasi_target) AS selisih,
      ROUND((SUM(CASE WHEN f.target_penjualan IS NOT NULL THEN f.realisasi_penjualan ELSE 0 END) / SUM(f.target_penjualan)) * 100, 2) AS pencapaian_pct
  FROM fact_kinerja_sales_v2 f
  JOIN dim_tanggal d ON d.tanggal_key = f.tanggal_kuartal_key
  JOIN dim_wilayah w ON w.wilayah_key = f.wilayah_key
  WHERE f.target_penjualan IS NOT NULL
  GROUP BY d.tahun, d.kuartal, w.grup_wilayah
  ORDER BY d.tahun, d.kuartal, w.grup_wilayah;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 1](<Bukti Gamber/uji_pertanyaan_bisnis 1.png>)

*Gambar 2.1: Hasil eksekusi kueri SQL tren pencapaian kuartalan per grup wilayah (36 baris).*

* **Temuan Analitik:**
  * Tren pencapaian di wilayah *North America* mengalami pemulihan konsisten dari kuartal ke kuartal, berawal dari 12,68% pada 2011 Q2 hingga menembus target pada 2011 Q4 (101,61%) dan 2012 Q1 (129,77%).
  * Wilayah *Europe* mulai dibukukan sejak 2012 Q2 dengan performa stabil berkisar antara 61,31% s.d. 110,89%.
  * Baris grup *Tidak diketahui* (transaksi manajer korporat) memiliki target kuota sangat kecil (Rp 7.000 s.d. Rp 140.000) sehingga memicu rasio persentase yang melonjak tinggi (misal: 322,64% pada 2011 Q3).

---

### 2.2. Pertanyaan Bisnis 2: Wilayah Terbaik dan Tertinggal per Tahun

* **Rumusan Masalah:** *"Wilayah mana yang paling melampaui target dan wilayah mana yang paling tertinggal dari target pada setiap tahun, serta bagaimana kinerja tiap salesperson di dalamnya?"*
* **Kueri SQL:**
  ```sql
  SELECT 
      d.tahun,
      w.nama_wilayah,
      w.nama_negara,
      SUM(f.selisih_realisasi_target) AS selisih,
      ROUND((SUM(f.realisasi_penjualan) / SUM(f.target_penjualan)) * 100, 2) AS pencapaian_pct
  FROM fact_kinerja_sales_v2 f
  JOIN dim_tanggal d ON d.tanggal_key = f.tanggal_kuartal_key
  JOIN dim_wilayah w ON w.wilayah_key = f.wilayah_key
  WHERE f.target_penjualan IS NOT NULL
  GROUP BY d.tahun, w.nama_wilayah, w.nama_negara
  ORDER BY d.tahun, pencapaian_pct DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 2](<Bukti Gamber/uji_pertanyaan_bisnis 2.png>)

*Gambar 2.2: Peringkat kinerja pencapaian target tahunan per kawasan wilayah (38 baris).*

* **Temuan Analitik:**
  * **Tahun 2011:** Seluruh wilayah berada di bawah kuota target (< 100%). Wilayah terbaik adalah *Northwest* (71,06%), sedangkan wilayah paling tertinggal adalah *Central* (57,45%) dan *Southwest* (59,39%).
  * **Tahun 2012:** Wilayah *Northwest* berhasil melampaui target dengan capaian **106,03%** (+Rp 166.972,70 surplus). Wilayah paling tertinggal dipegang oleh *France* (81,73%) dan *Canada* (83,07%).
  * **Tahun 2013:** Performa antarwilayah semakin merata pada rentang 80%–86%, dengan *Southwest* berada di puncak (86,60%) dan *Southeast* di posisi terbawah (80,00%).

---

### 2.3. Pertanyaan Bisnis 3: Evaluasi Kinerja Staf Penjualan (Peringkat, Gap, & Konsistensi)

* **Rumusan Masalah:** *"Siapa salesperson dengan persentase pencapaian tertinggi, siapa yang berada di bawah target dan seberapa jauh, serta berapa kuartal masing-masing berhasil mencapai target?"*
* **Kueri SQL:**
  ```sql
  SELECT 
      sp.nama_lengkap,
      SUM(f.target_penjualan) AS target,
      SUM(f.selisih_realisasi_target) AS selisih,
      ROUND((SUM(f.realisasi_penjualan) / SUM(f.target_penjualan)) * 100, 2) AS pencapaian_pct,
      COUNT(DISTINCT CASE WHEN f.kategori_kinerja_key = 1 THEN f.tanggal_kuartal_key END) AS kuartal_tercapai,
      COUNT(DISTINCT CASE WHEN f.target_penjualan IS NOT NULL THEN f.tanggal_kuartal_key END) AS kuartal_bertarget
  FROM fact_kinerja_sales_v2 f
  JOIN dim_sales_person sp ON sp.sales_person_key = f.sales_person_key
  WHERE f.target_penjualan IS NOT NULL
  GROUP BY sp.nama_lengkap
  ORDER BY pencapaian_pct DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 3](<Bukti Gamber/uji_pertanyaan_bisnis 3.png>)

*Gambar 2.3: Peringkat 17 staf penjualan berdasarkan persentase pencapaian kuota historis.*

* **Temuan Analitik:**
  * **Top 3 Salesperson:**
    1. **Pamela O Ansman-Wolfe:** Capaian 89,38% (Defisit Rp 377.011,28; berhasil mencapai target di 3 dari 12 kuartal).
    2. **David R Campbell:** Capaian 89,14% (Defisit Rp 437.006,62; berhasil mencapai target di 5 dari 12 kuartal).
    3. **Linda C Mitchell:** Capaian 85,56% (Volume target terbesar Rp 11.786.000,00; berhasil mencapai target di 5 dari 12 kuartal).
  * **Konsistensi Tertinggi:** David Campbell dan Linda Mitchell memegang rekor konsistensi tertinggi dengan **5 kuartal berstatus TERCAPAI**.
  * **Bottom Performer:** Lynn Tsoflias (70,80%) dan Rachel Valdez (73,90%) menempati peringkat terbawah dengan 0 kuartal tercapai (keduanya baru bergabung di 4 kuartal terakhir).

---

### 2.4. Pertanyaan Bisnis 4: Volume Unit Terjual vs Realisasi Finansial

* **Rumusan Masalah:** *"Apakah salesperson dengan unit terjual terbanyak selalu menghasilkan realisasi tertinggi, dan berapa rata-rata realisasi per unit untuk tiap salesperson?"*
* **Kueri SQL:**
  ```sql
  SELECT 
      sp.nama_lengkap,
      SUM(f.jumlah_terjual) AS unit_terjual,
      SUM(f.realisasi_penjualan) AS realisasi,
      ROUND(SUM(f.realisasi_penjualan) / SUM(f.jumlah_terjual), 2) AS realisasi_per_unit
  FROM fact_kinerja_sales_v2 f
  JOIN dim_sales_person sp ON sp.sales_person_key = f.sales_person_key
  GROUP BY sp.nama_lengkap
  ORDER BY unit_terjual DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 4](<Bukti Gamber/uji_pertanyaan_bisnis 4.png>)

*Gambar 2.4: Perbandingan volume barang terjual vs total omzet dan nilai rata-rata per unit.*

* **Temuan Analitik:**
  * **Volume vs Nilai Finansial:** Staf dengan unit terjual terbanyak secara umum menghasilkan omzet tertinggi. **Linda C Mitchell** menempati posisi teratas dengan 27.229 unit terjual dan omzet Rp 10.367.007,43, diikuti ketat oleh **Jillian Carson** (27.051 unit, Rp 10.065.803,54).
  * **Rata-rata Realisasi per Unit:** Menjual unit banyak tidak selalu berarti harga unit tertinggi:
    * Staf dengan rata-rata realisasi per unit tertinggi dipegang oleh **David R Campbell (Rp 456,43/unit)** dan **Pamela O Ansman-Wolfe (Rp 451,78/unit)**, mengindikasikan mereka menjual produk-produk segmen premium / bernilai tinggi.
    * Sebaliknya, **Jae B Pak** menjual 26.231 unit namun rata-rata per unitnya hanya Rp 324,17. Rata-rata per unit terendah dicatat oleh **Syed E Abbas (Rp 209,12/unit)**.

---

### 2.5. Pertanyaan Bisnis 5: Hubungan Kelompok Komisi dengan Pencapaian Target

* **Rumusan Masalah:** *"Kelompok salesperson dengan tingkat komisi mana yang paling sering mencapai target dan memiliki rata-rata selisih terbaik?"*
* **Kueri SQL:**
  ```sql
  SELECT 
      sp.komisi_pct,
      COUNT(DISTINCT CASE WHEN f.target_penjualan IS NOT NULL THEN CONCAT(f.tanggal_kuartal_key, '-', f.sales_person_key) END) AS kuartal_bertarget,
      COUNT(DISTINCT CASE WHEN f.kategori_kinerja_key = 1 THEN CONCAT(f.tanggal_kuartal_key, '-', f.sales_person_key) END) AS kuartal_tercapai,
      ROUND((COUNT(DISTINCT CASE WHEN f.kategori_kinerja_key = 1 THEN CONCAT(f.tanggal_kuartal_key, '-', f.sales_person_key) END) / 
             COUNT(DISTINCT CASE WHEN f.target_penjualan IS NOT NULL THEN CONCAT(f.tanggal_kuartal_key, '-', f.sales_person_key) END)) * 100, 2) AS tercapai_pct,
      ROUND(SUM(f.selisih_realisasi_target) / 
            COUNT(DISTINCT CASE WHEN f.target_penjualan IS NOT NULL THEN CONCAT(f.tanggal_kuartal_key, '-', f.sales_person_key) END), 2) AS rata_rata_selisih
  FROM fact_kinerja_sales_v2 f
  JOIN dim_sales_person sp ON sp.sales_person_key = f.sales_person_key
  WHERE f.target_penjualan IS NOT NULL
  GROUP BY sp.komisi_pct
  ORDER BY tercapai_pct DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 5](<Bukti Gamber/uji_pertanyaan_bisnis 5.png>)

*Gambar 2.5: Distribusi frekuensi pencapaian target dan rata-rata selisih berdasarkan kelompok persentase komisi.*

* **Temuan Analitik:**
  * **Kelompok Komisi 0,0% (Manajer Penjualan):** Memiliki rasio keberhasilan pencapaian kuartalan tertinggi (**33,33%**, 8 dari 24 kuartal) dengan rata-rata defisit selisih paling kecil (-Rp 17.935,11/kuartal). Hal ini terjadi karena kuota target mereka relatif kecil.
  * **Kelompok Staf Penjualan Lapangan:**
    * **Komisi 1,5% (0,015):** Menghasilkan rasio keberhasilan tertinggi di antara staf lapangan (**27,78%**, 10 dari 36 kuartal tercapai).
    * **Komisi 1,2% (0,012):** Menempati posisi kedua dengan rasio **25,00%** (6 dari 24 kuartal tercapai).
    * **Komisi 1,0% (0,010):** Menghasilkan 10 kuartal tercapai dari 48 kuartal teramati (**20,83%**).
    * **Komisi Tinggi (≥ 1,6%):** Staf dengan komisi 1,6% s.d. 2,0% justru memiliki rasio pencapaian rendah (0% s.d. 12,50%) dengan defisit rata-rata selisih terbesar (-Rp 306.305,68 pada komisi 2,0%), membuktikan bahwa persentase komisi yang lebih besar tidak berkorelasi linier dengan keberhasilan melampaui target kuota.

---

## 3. Kesimpulan & Rekomendasi

1. **Keberhasilan Rekonsiliasi:**
   * Pipeline ETL membuktikan integritas 100% pada total target kuota (Rp 95.714.000,00) dan volume unit terjual (214.516 unit).
   * Total realisasi penjualan Rp 80.487.704,19 cocok dengan data sumber operasional (selisih pembulatan hanya Rp 0,012).
   * Sebanyak 1.225 baris transaksi manajer tanpa wilayah penugasan berhasil dipetakan secara aman ke surrogate key `-1` tanpa menghilangkan data fakta.
2. **Kesiapan Menuju OLAP & Dashboard:**
   * Kueri SQL untuk ke-5 pertanyaan bisnis menghasilkan data agregat yang konsisten, bersih, dan menjawab seluruh dimensi yang disyaratkan.
   * Logika rasio non-aditif persentase pencapaian dan perhitungan rata-rata per unit telah tervalidasi dan siap ditranslasikan ke calculated member Mondrian XML (`schema.xml`) dan kueri MDX pada Pekan 13–14.
