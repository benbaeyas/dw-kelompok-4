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

Seluruh pertanyaan bisnis utama dieksekusi menggunakan kueri SQL pembanding pada skema `fact_kinerja_sales_v2` (mengacu langsung pada file implementasi `sql/uji_pertanyaan_bisnis.sql`) untuk memvalidasi kesiapan data sebelum diimplementasikan pada skema OLAP Mondrian (`olap/schema.xml`) dan kueri analitik MDX pada Pekan 13–14.

> [!NOTE]
> Sesuai arsitektur Change Request CR-01, metrik kuota target (`target_penjualan`) dan selisih (`selisih_realisasi_target`) disimpan secara eksklusif pada baris fakta sintetis produk `produk_key = -2` (baris agregasi kuartalan salesperson). Dengan demikian:
> * **Formula Persentase Pencapaian Kuota:**  
>   $$\text{Pencapaian (\%)} = \frac{\sum(\text{target}) + \sum(\text{selisih})}{\sum(\text{target})} \times 100\%$$  
>   Formula ini menjamin kebenaran kalkulasi pada tingkat agregasi apa pun tanpa memicu penggandaan kuota (*fan-out target*).
> * **Kuartal Bertarget:** Dihitung dengan kriteria `produk_key = -2 AND target_penjualan IS NOT NULL` (mengecualikan kuartal `TANPA_TARGET` pada 2014 Q2).

---

### 2.1. Pertanyaan Bisnis 1: Tren Pencapaian Target Kuartalan Keseluruhan dan per Grup Wilayah

* **Rumusan Masalah:** *"Bagaimana perkembangan pencapaian target penjualan dari kuartal ke kuartal, baik secara keseluruhan maupun di setiap wilayah?"*
* **Kueri SQL:**
  ```sql
  SELECT t.tahun, t.kuartal,
         '(SEMUA WILAYAH)' AS grup_wilayah,
         SUM(f.realisasi_penjualan)                        AS realisasi_total,
         SUM(f.target_penjualan)                           AS target,
         SUM(f.selisih_realisasi_target)                   AS selisih,
         ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
               / NULLIF(SUM(f.target_penjualan), 0), 2)    AS pencapaian_pct
  FROM fact_kinerja_sales_v2 f
  JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_kuartal_key
  GROUP BY t.tahun, t.kuartal

  UNION ALL

  SELECT t.tahun, t.kuartal,
         w.grup_wilayah,
         SUM(f.realisasi_penjualan),
         SUM(f.target_penjualan),
         SUM(f.selisih_realisasi_target),
         ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
               / NULLIF(SUM(f.target_penjualan), 0), 2)
  FROM fact_kinerja_sales_v2 f
  JOIN dim_tanggal t ON t.tanggal_key = f.tanggal_kuartal_key
  JOIN dim_wilayah w ON w.wilayah_key = f.wilayah_key
  GROUP BY t.tahun, t.kuartal, w.grup_wilayah
  ORDER BY tahun, kuartal, grup_wilayah;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 1](<Bukti Gamber/uji_pertanyaan_bisnis 1.png>)

*Gambar 2.1: Hasil eksekusi kueri SQL tren pencapaian kuartalan secara agregat keseluruhan dan per grup wilayah (53 baris × 7 kolom).*

* **Temuan Analitik:**
  * **Tingkat Korporat Keseluruhan `(SEMUA WILAYAH)`:**
    * Perkembangan bisnis menunjukkan pemulihan performa penjualan yang sangat signifikan. Pada kuartal awal (**2011 Q2**), persentase pencapaian hanya tercatat sebesar **12,59%** (Realisasi Rp 489.328,58 vs Target Rp 3.886.000,0; Defisit -Rp 3.396.671,42).
    * Capaian meningkat tajam di **2011 Q3** (63,07%) dan hampir memenuhi kuota target secara penuh pada **2011 Q4** (99,79%).
    * Puncak performa tertinggi sepanjang masa dicapai pada **2012 Q1**, di mana realisasi berhasil melampaui kuota dengan pencapaian **128,42%** (Surplus +Rp 1.440.085,99).
  * **Tren Wilayah *North America*:** Menjadi penggerak utama volume penjualan perusahaan, pulih dari 12,68% (2011 Q2) ke 62,75% (2011 Q3), 101,61% (2011 Q4), dan menembus titik tertinggi 129,77% (2012 Q1).
  * **Tren Wilayah *Europe*:** Mulai dibukukan sejak **2012 Q2** dengan performa awal 61,31%, melonjak ke 93,90% (2012 Q3), dan sukses melampaui target di **2012 Q4** sebesar **110,89%** (+Rp 55.015,35 surplus).
  * **Grup *Tidak diketahui* (Manajer Korporat):** Menampung transaksi pesanan korporat dari 3 staf manajer tanpa teritori spesifik. Karena kuota target kuartalan mereka relatif kecil (Rp 7.000 s.d. Rp 169.000), fluktuasi persentase tampak ekstrem (misalnya 322,64% pada 2011 Q3 dan 147,82% pada 2012 Q4).

---

### 2.2. Pertanyaan Bisnis 2: Wilayah Terbaik dan Tertinggal per Tahun serta Kinerja Salesperson di Dalamnya

* **Rumusan Masalah:** *"Wilayah mana yang paling melampaui target dan wilayah mana yang paling tertinggal dari target pada setiap tahun, serta bagaimana kinerja tiap salesperson di dalamnya?"*
* **Kueri SQL:**
  ```sql
  WITH sp AS (   -- tingkat salesperson per wilayah per tahun
      SELECT t.tahun, w.grup_wilayah, w.nama_negara, w.nama_wilayah,
             s.business_entity_id, MAX(s.nama_lengkap) AS nama_lengkap,
             SUM(f.realisasi_penjualan)                AS realisasi_total,
             SUM(f.target_penjualan)                   AS target,
             SUM(f.selisih_realisasi_target)           AS selisih
      FROM fact_kinerja_sales_v2 f
      JOIN dim_tanggal t      ON t.tanggal_key      = f.tanggal_kuartal_key
      JOIN dim_wilayah w      ON w.wilayah_key      = f.wilayah_key
      JOIN dim_sales_person s ON s.sales_person_key = f.sales_person_key
      WHERE f.sales_person_key <> -1
      GROUP BY t.tahun, w.grup_wilayah, w.nama_negara, w.nama_wilayah, s.business_entity_id
      HAVING SUM(f.target_penjualan) IS NOT NULL
  ),
  wil AS (       -- tambahkan total tingkat wilayah lewat window function
      SELECT sp.*,
             SUM(realisasi_total) OVER (PARTITION BY tahun, nama_wilayah) AS wil_realisasi,
             SUM(target)          OVER (PARTITION BY tahun, nama_wilayah) AS wil_target,
             SUM(selisih)         OVER (PARTITION BY tahun, nama_wilayah) AS wil_selisih
      FROM sp
  ),
  hit AS (
      SELECT wil.*,
             ROUND(100 * (wil_target + wil_selisih) / NULLIF(wil_target, 0), 2) AS wil_pencapaian_pct,
             ROUND(100 * (target + selisih)         / NULLIF(target, 0), 2)     AS sp_pencapaian_pct
      FROM wil
  )
  SELECT tahun, grup_wilayah, nama_negara, nama_wilayah,
         wil_realisasi, wil_target, wil_selisih, wil_pencapaian_pct,
         DENSE_RANK() OVER (PARTITION BY tahun ORDER BY wil_pencapaian_pct DESC) AS wil_rank_terbaik,
         DENSE_RANK() OVER (PARTITION BY tahun ORDER BY wil_pencapaian_pct ASC)  AS wil_rank_terburuk,
         nama_lengkap,
         realisasi_total AS sp_realisasi, target AS sp_target, selisih AS sp_selisih,
         sp_pencapaian_pct
  FROM hit
  ORDER BY tahun, wil_rank_terbaik, nama_wilayah, sp_pencapaian_pct DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 2 - Bagian Wilayah](<Bukti Gamber/uji_pertanyaan_bisnis 2.1.png>)

*Gambar 2.2a: Hasil kueri SQL peringkat wilayah terbaik dan tertinggal (kolom dimensi wilayah, agregasi wilayah, dan ranking).*

![Bukti Uji Pertanyaan Bisnis 2 - Bagian Salesperson](<Bukti Gamber/uji_pertanyaan_bisnis 2.2.png>)

*Gambar 2.2b: Hasil kueri SQL rincian kinerja staf penjualan di masing-masing wilayah (kolom realisasi, target, selisih, dan persentase pencapaian salesperson).*

* **Temuan Analitik:**
  * Kueri memanfaatkan Common Table Expressions (CTE) dan Window Function `DENSE_RANK()` untuk mengelompokkan kinerja wilayah (`wil_rank_terbaik = 1` untuk yang paling melampaui dan `wil_rank_terburuk = 1` untuk yang paling tertinggal), sekaligus membedah kontribusi individual salesperson (`sp_pencapaian_pct`) dalam tabel berukuran **61 baris × 15 kolom**.
  * **Tahun 2011:**
    * **Wilayah Terbaik:** **Northwest** (`wil_rank_terbaik = 1`, capaian 71,06%). Didukung oleh performa seimbang antara Pamela O Ansman-Wolfe (72,21%) dan David R Campbell (69,85%).
    * **Wilayah Paling Tertinggal:** Grup *Tidak diketahui* korporat menempati ranking terbawah (`wil_rank_terburuk = 1`, 22,96% - Stephen Y Jiang). Di antara wilayah operasional resmi, wilayah paling tertinggal adalah **Central** (`wil_rank_terburuk = 2`, 57,45% - Jillian Carson 57,45%) dan **Southwest** (`wil_rank_terburuk = 3`, 59,39% - Linda C Mitchell 55,20% dan Shu K Ito 65,29%).
  * **Tahun 2012:**
    * **Wilayah Terbaik:** **Northwest** kembali memimpin dan sukses melampaui kuota tahunan (`wil_rank_terbaik = 1`, capaian **106,03%**, surplus +Rp 166.972,70). Hal ini ditopang oleh capaian luar biasa Pamela O Ansman-Wolfe (**130,34%**) dan David R Campbell (**103,71%**) yang mengompensasi kinerja Tete A Mensa-Annan (73,36%).
    * **Peringkat 2 & 3:** **Southeast** menempati ranking 2 (97,11% - Tsvi Michael Reiter), disusul grup *Tidak diketahui* korporat pada ranking 3 (93,06% - Stephen Y Jiang 96,29% dan Amy E Alberts 82,29%).
    * **Peringkat 4 & 5:** **Southwest** mencapai ranking 4 (91,85% - Linda C Mitchell 99,27% dan Shu K Ito 81,64%), diikuti **Northeast** pada ranking 5 (88,36% - Jillian Carson 110,76%).

---

### 2.3. Pertanyaan Bisnis 3: Evaluasi Kinerja Staf Penjualan (Peringkat, Gap, & Konsistensi)

* **Rumusan Masalah:** *"Siapa salesperson dengan persentase pencapaian tertinggi, siapa yang berada di bawah target dan seberapa jauh, serta berapa kuartal masing-masing berhasil mencapai target?"*
* **Kueri SQL:**
  ```sql
  SELECT s.business_entity_id, MAX(s.nama_lengkap)           AS nama_lengkap,
         SUM(f.realisasi_penjualan)                          AS realisasi_total,
         SUM(f.target_penjualan)                             AS target,
         SUM(f.selisih_realisasi_target)                     AS selisih,
         ROUND(100 * (SUM(f.target_penjualan) + SUM(f.selisih_realisasi_target))
               / NULLIF(SUM(f.target_penjualan), 0), 2)      AS pencapaian_pct,
         CASE WHEN SUM(f.selisih_realisasi_target) >= 0 THEN 'DI ATAS/SESUAI TARGET'
              ELSE 'DI BAWAH TARGET' END                     AS status_total,
         COUNT(DISTINCT CASE WHEN f.produk_key = -2 AND f.target_penjualan IS NOT NULL
                             THEN f.tanggal_kuartal_key END) AS kuartal_bertarget,
         COUNT(DISTINCT CASE WHEN f.produk_key = -2 AND k.kode_kategori = 'TERCAPAI'
                             THEN f.tanggal_kuartal_key END) AS kuartal_tercapai
  FROM fact_kinerja_sales_v2 f
  JOIN dim_sales_person s      ON s.sales_person_key         = f.sales_person_key
  JOIN dim_kategori_kinerja k  ON k.kategori_kinerja_key     = f.kategori_kinerja_key
  WHERE f.sales_person_key <> -1
  GROUP BY s.business_entity_id
  HAVING SUM(f.target_penjualan) IS NOT NULL
  ORDER BY pencapaian_pct DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 3](<Bukti Gamber/uji_pertanyaan_bisnis 3.png>)

*Gambar 2.3: Peringkat kinerja staf penjualan berdasarkan persentase pencapaian, status total kumulatif, dan frekuensi kuartal tercapai (17 baris × 9 kolom).*

* **Temuan Analitik:**
  * **Status Kumulatif Total:** Seluruh 17 salesperson tercatat berstatus kumulatif `'DI BAWAH TARGET'` secara agregat historis 2011–2014, disebabkan oleh rendahnya realisasi di kuartal awal (2011 Q2). Kendati demikian, performa kuartalan individual menunjukkan dinamika pencapaian target yang kuat.
  * **Top 3 Salesperson (Persentase Tertinggi):**
    1. **Pamela O Ansman-Wolfe (ID 280):** Capaian **89,38%** (Realisasi Rp 3.325.102,59; Target Rp 3.551.000,0; Defisit -Rp 377.011,28; sukses mencapai target di 3 dari 12 kuartal bertarget).
    2. **David R Campbell (ID 283):** Capaian **89,14%** (Realisasi Rp 3.729.945,35; Target Rp 4.025.000,0; Defisit -Rp 437.006,62; sukses mencapai target di 5 dari 12 kuartal bertarget).
    3. **Linda C Mitchell (ID 276):** Capaian **85,56%** (Memegang beban kuota target terbesar di perusahaan yaitu Rp 11.786.000,0; Realisasi Rp 10.367.007,43; Defisit -Rp 1.701.703,62; sukses mencapai target di 5 dari 12 kuartal bertarget).
    4. **Amy E Alberts (ID 287):** Capaian **83,65%** (Realisasi Rp 732.759,18; Target Rp 876.000,0; 2 dari 8 kuartal tercapai).
    5. **Syed E Abbas (ID 285):** Capaian **82,11%** (Realisasi Rp 172.524,45; Target Rp 205.000,0; 2 dari 4 kuartal tercapai).
  * **Tingkat Konsistensi Tertinggi:** **David R Campbell** dan **Linda C Mitchell** menjadi salesperson paling konsisten di perusahaan dengan rekor **5 kuartal berstatus TERCAPAI**, disusul oleh **Stephen Y Jiang** (4 kuartal tercapai).
  * **Kinerja Tertinggal:** Peringkat terbawah diisi oleh **Rachel B Valdez (73,90%)** dan **Lynn N Tsoflias (70,80%)** dengan 0 kuartal tercapai, yang merefleksikan periode masa kerja yang baru dimulai pada 4 kuartal terakhir.

---

### 2.4. Pertanyaan Bisnis 4: Volume Unit Terjual vs Realisasi Finansial

* **Rumusan Masalah:** *"Apakah salesperson dengan unit terjual terbanyak selalu menghasilkan realisasi tertinggi, dan berapa rata-rata realisasi per unit untuk tiap salesperson?"*
* **Kueri SQL:**
  ```sql
  WITH base AS (
      SELECT t.tahun, w.nama_wilayah,
             s.business_entity_id, MAX(s.nama_lengkap) AS nama_lengkap,
             SUM(f.jumlah_terjual)                     AS unit_terjual,
             SUM(f.realisasi_penjualan)                AS realisasi
      FROM fact_kinerja_sales_v2 f
      JOIN dim_tanggal t      ON t.tanggal_key      = f.tanggal_kuartal_key
      JOIN dim_wilayah w      ON w.wilayah_key      = f.wilayah_key
      JOIN dim_sales_person s ON s.sales_person_key = f.sales_person_key
      WHERE f.sales_person_key <> -1
      GROUP BY t.tahun, w.nama_wilayah, s.business_entity_id
  ),
  urut AS (
      SELECT base.*,
             ROW_NUMBER() OVER (PARTITION BY tahun, nama_wilayah ORDER BY unit_terjual DESC) AS n_unit,
             ROW_NUMBER() OVER (PARTITION BY tahun, nama_wilayah ORDER BY realisasi DESC)    AS n_real
  )
  SELECT nama_lengkap,
         SUM(unit_terjual)                                                    AS unit_terjual,
         SUM(realisasi)                                                       AS realisasi,
         ROUND(SUM(realisasi) / NULLIF(SUM(unit_terjual), 0), 2)              AS realisasi_per_unit,
         COUNT(*)                                                             AS jumlah_periode,
         SUM(n_unit = 1)                                                      AS periode_unit_terbanyak,
         SUM(n_real = 1)                                                      AS periode_realisasi_tertinggi,
         SUM(n_unit = 1 AND n_real = 1)                                       AS periode_keduanya,
         CASE WHEN SUM(n_unit = 1) = 0 THEN '-'
              WHEN SUM(n_unit = 1 AND n_real = 1) = SUM(n_unit = 1) THEN 'SELALU SAMA'
              ELSE 'TIDAK SELALU' END                                         AS unit_terbanyak_juga_realisasi_tertinggi
  FROM urut
  GROUP BY business_entity_id, nama_lengkap
  ORDER BY unit_terjual DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 4](<Bukti Gamber/uji_pertanyaan_bisnis 4.png>)

*Gambar 2.4: Hasil pengujian empiris hubungan unit terjual terbanyak vs realisasi finansial tertinggi per periode tahun-wilayah (17 baris × 9 kolom).*

* **Temuan Analitik:**
  * **Jawaban atas Hipotesis:** Apakah salesperson dengan unit terjual terbanyak selalu menghasilkan realisasi omzet tertinggi? Jawabannya adalah **TIDAK SELALU**, sebagaimana dibuktikan oleh kolom indikator `unit_terbanyak_juga_realisasi_tertinggi`:
    * Sebanyak 13 dari 17 salesperson berstatus `'SELALU SAMA'` (ketika berhasil memimpin volume unit pada suatu periode tahun-wilayah, mereka juga otomatis memimpin omzet finansial, seperti Linda C Mitchell pada 3 periode dan Jillian Carson pada 4 periode).
    * Namun terbukti ada **2 salesperson** dengan status anomali **'TIDAK SELALU'**:
      1. **Shu K Ito:** Memimpin unit terjual terbanyak pada 1 periode (`n_unit = 1`), namun tidak pernah menjadi yang tertinggi pada realisasi omzet (`n_real = 0`), sehingga statusnya `TIDAK SELALU` (omzetnya dikalahkan oleh rekan se-wilayahnya yang menjual produk bernilai lebih tinggi).
      2. **Pamela O Ansman-Wolfe:** Memimpin unit terbanyak pada 2 periode, namun hanya 1 periode yang sekaligus menghasilkan omzet tertinggi (`periode_keduanya = 1`), menghasilkan status `TIDAK SELALU`.
    * Dua staf penjualan (Garrett R Vargas dan Syed E Abbas) bertanda `'-'` karena tidak pernah menjadi peringkat 1 volume unit di wilayah penugasannya.
  * **Rata-rata Realisasi per Unit (`realisasi_per_unit`):**
    * Staf dengan rata-rata omzet per unit tertinggi adalah **David R Campbell (Rp 456,43/unit)**, **Pamela O Ansman-Wolfe (Rp 451,78/unit)**, dan **Tsvi Michael Reiter (Rp 436,43/unit)**. Angka ini membuktikan bahwa portofolio penjualan mereka terkonsentrasi pada lini produk bernilai tinggi (*high-margin / premium products*).
    * Sebaliknya, **Linda C Mitchell** (Rp 380,73/unit) dan **Jillian Carson** (Rp 372,10/unit) mendominasi dari sisi volume kuantitas (27.229 dan 27.051 unit terjual).
    * Rata-rata per unit terendah dicatat oleh **Syed E Abbas (Rp 209,12/unit)** dan **Rachel B Valdez (Rp 259,78/unit)**.

---

### 2.5. Pertanyaan Bisnis 5: Hubungan Kelompok Komisi dengan Pencapaian Target

* **Rumusan Masalah:** *"Kelompok salesperson dengan tingkat komisi mana yang paling sering mencapai target dan memiliki rata-rata selisih terbaik?"*
* **Kueri SQL:**
  ```sql
  WITH dasar_kuartal AS (
      -- Tahap 1: Ambil data rekap kuartalan bertarget & tandai status tercapai (1/0)
      SELECT s.business_entity_id,
             s.komisi_pct,
             s.bonus,
             t.tahun,
             f.selisih_realisasi_target,
             CASE WHEN k.kode_kategori = 'TERCAPAI' THEN 1 ELSE 0 END AS is_tercapai
      FROM fact_kinerja_sales_v2 f
      JOIN dim_sales_person s     ON s.sales_person_key     = f.sales_person_key
      JOIN dim_kategori_kinerja k ON k.kategori_kinerja_key = f.kategori_kinerja_key
      JOIN dim_tanggal t          ON t.tanggal_key          = f.tanggal_kuartal_key
      WHERE f.produk_key = -2                -- Baris agregasi kuartalan per salesperson
        AND f.target_penjualan IS NOT NULL   -- Hanya kuartal yang memiliki target
        AND f.sales_person_key <> -1
  ),
  rekap_komisi AS (
      -- Tahap 2: Hitung metrik kinerja per kelompok tingkat komisi
      SELECT komisi_pct,
             COUNT(DISTINCT business_entity_id)            AS jml_salesperson,
             CONCAT(MIN(tahun), ' - ', MAX(tahun))         AS periode_tahun,
             COUNT(*)                                      AS jml_kuartal_bertarget,
             SUM(is_tercapai)                              AS jml_kuartal_tercapai,
             COUNT(*) - SUM(is_tercapai)                   AS jml_kuartal_belum_tercapai,
             ROUND(100.0 * SUM(is_tercapai) / COUNT(*), 2) AS persen_tercapai,
             ROUND(AVG(selisih_realisasi_target), 2)       AS rata_rata_selisih,
             ROUND(AVG(bonus), 2)                          AS rata_rata_bonus
      FROM dasar_kuartal
      GROUP BY komisi_pct
  )
  -- Tahap 3: Tampilkan hasil akhir diurutkan dari yang tertinggi
  SELECT CONCAT(ROUND(komisi_pct * 100, 2), '%') AS `Tingkat Komisi`,
         jml_salesperson                         AS `Jumlah Salesperson`,
         periode_tahun                           AS `Periode Tahun`,
         jml_kuartal_bertarget                   AS `Total Kuartal Bertarget`,
         jml_kuartal_tercapai                    AS `Kuartal Tercapai`,
         jml_kuartal_belum_tercapai              AS `Kuartal Belum Tercapai`,
         persen_tercapai                         AS `% Kuartal Tercapai`,
         rata_rata_selisih                       AS `Rata-rata Selisih per Kuartal`,
         rata_rata_bonus                         AS `Rata-rata Bonus`
  FROM rekap_komisi
  ORDER BY persen_tercapai DESC, rata_rata_selisih DESC;
  ```
* **Bukti Eksekusi:**

![Bukti Uji Pertanyaan Bisnis 5](<Bukti Gamber/uji_pertanyaan_bisnis 5.png>)

*Gambar 2.5: Distribusi frekuensi pencapaian target, rata-rata selisih, dan rata-rata bonus berdasarkan kelompok tingkat komisi (8 baris × 9 kolom).*

* **Temuan Analitik:**
  * **Kelompok Komisi 0.00% (3 Manajer Penjualan Korporat):** Menempati peringkat tertinggi dengan rasio keberhasilan pencapaian kuartalan **33,33%** (8 dari 24 kuartal tercapai) dan rata-rata defisit selisih paling minimal (-Rp 17.935,11 per kuartal), dengan rata-rata bonus Rp 0,0 karena mereka berstatus manajer non-komisi.
  * **Kinerja Kelompok Staf Penjualan Lapangan:**
    * **Komisi 1.50% (3 salesperson):** Memegang efektivitas tertinggi di antara staf lapangan dengan **27,78%** kuartal tercapai (10 dari 36 kuartal), rata-rata selisih -Rp 160.262,42, dan rata-rata bonus Rp 3.166,67.
    * **Komisi 1.20% (2 salesperson):** Menempati peringkat kedua dengan **25,00%** kuartal tercapai (6 dari 24 kuartal), rata-rata selisih -Rp 111.462,94, dan rata-rata bonus Rp 3.800,00.
    * **Komisi 1.00% (4 salesperson):** Menghasilkan tingkat ketercapaian **20,83%** (10 dari 48 kuartal), rata-rata selisih -Rp 93.291,16, dan rata-rata bonus Rp 3.937,50.
    * **Kelompok Komisi Tinggi (≥ 1.60%):** Staf dengan tingkat komisi 1.60% s.d. 2.00% justru menunjukkan performa kuartalan yang rendah:
      * Komisi 1.90%: 14,29% (1 dari 7 kuartal), rata-rata selisih -Rp 83.405,33.
      * Komisi 1.60%: 12,50% (1 dari 8 kuartal), rata-rata selisih -Rp 145.793,42.
      * Komisi 2.00%: 12,50% (1 dari 8 kuartal), rata-rata defisit selisih paling dalam (-Rp 306.305,68 per kuartal) meskipun menerima bonus tertinggi (Rp 5.150,00).
      * Komisi 1.80%: 0,00% (0 dari 8 kuartal tercapai), rata-rata selisih -Rp 136.181,70.
  * **Kesimpulan Bisnis:** Persentase komisi yang lebih besar tidak berkorelasi linier positif dengan frekuensi pencapaian target kuota; kelompok salesperson dengan komisi moderat (1,0%–1,5%) justru membuktikan pencapaian target yang jauh lebih konsisten dibanding kelompok komisi tinggi.

---

## 3. Kesimpulan & Rekomendasi

1. **Keberhasilan Rekonsiliasi:**
   * Pipeline ETL membuktikan integritas 100% pada total target kuota (Rp 95.714.000,00) dan volume unit terjual (214.516 unit).
   * Total realisasi penjualan Rp 80.487.704,19 cocok dengan data sumber operasional (selisih pembulatan hanya Rp 0,012).
   * Sebanyak 1.225 baris transaksi manajer tanpa wilayah penugasan berhasil dipetakan secara aman ke surrogate key `-1` tanpa menghilangkan data fakta.
2. **Kesiapan Menuju OLAP & Dashboard:**
   * Kueri SQL untuk ke-5 pertanyaan bisnis menghasilkan data agregat yang konsisten, bersih, dan menjawab seluruh dimensi yang disyaratkan secara presisi.
   * Logika rasio non-aditif persentase pencapaian kuota berdasarkan arsitektur CR-01 (`produk_key = -2`), pemeringkatan wilayah via window function, serta pengujian komparatif volume unit vs omzet telah tervalidasi secara empiris.
   * Data ini menjadi baseline resmi (*ground truth*) untuk perbandingan hasil eksekusi skema OLAP Mondrian XML (`olap/schema.xml`) dan kueri MDX (`olap/query.mdx`) pada Pekan 13–14.
