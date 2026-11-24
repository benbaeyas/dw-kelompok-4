# Laporan Progres Pekan 13

Kelompok : 4 Empat  
Proses bisnis : Kinerja Sales vs Target  
Status : Hijau  

---

## 1. Target dan capaian

| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
| :--- | :---: | :--- |
| **`etl/t01_ekstrak.ktr`**<br>Salin semua tabel sumber yang dibutuhkan ke staging. Jumlah baris sumber dan staging sama persis. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/etl/t01_ekstrak.ktr |
| **Transformasi tiap dimensi**<br>Satu file `.ktr` per dimensi (`dim_wilayah.ktr`, `dim_sales_person.ktr`, `dim_produk.ktr`, `dim_kategori_kinerja.ktr`). Aturan penanganan NULL sesuai dokumen mapping. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/tree/main/etl/ |
| **Minimal satu dimensi SCD tipe 2**<br>Implementasi SCD Tipe 2 pada `dim_sales_person` untuk melacak perubahan historis jabatan, komisi, dan bonus dengan atribut masa berlaku (`row_effective_date` & `row_expiry_date`). Tunjukkan pembuktian entitas dengan multi-versi. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/strategi_scd.md |
| **Transformasi fakta**<br>Transformasi `t_fact_kinerja_sales.ktr` dengan Database Lookup ke setiap dimensi, penetapan default -1 (Unassigned/Unknown), dan -2 untuk baris target tanpa produk. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/etl/t_fact_kinerja_sales.ktr |
| **`etl/job_utama.kjb`**<br>Orkestrasi alur ETL lengkap: ekstraksi sumber, pengosongan staging (truncate), pemuatan dimensi berurutan, dan pemuatan fakta. Dapat dijalankan via CLI Kitchen dari terminal. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/etl/job_utama.kjb |
| **Rekonsiliasi**<br>Hasil query rekonsiliasi satu query (Staging vs Fakta) setelah job dijalankan dua kali berturut-turut menunjukkan selisih 0 (idempoten dan bebas duplikasi). | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/rekonsiliasi.sql https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/rekonsiliasi_%26_uji_pertanyaan_bisnis.md |
| **Laporan Pekan 13**<br>Menyusun dokumentasi lengkap laporan progres pekan 13 beserta lampiran log eksekusi Kitchen dan hasil verifikasi rekonsiliasi. | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/laporan/Pekan-13.md |

---

## 2. Kendala pengerjaan

- **Tidak ada**

---

## 3. Kendala tim

- **Tidak ada**

---

## 4. Keputusan yang butuh persetujuan sponsor

| Item | Keputusan yang diminta |
|:---|:---|
| **Tidak ada** | **Tidak ada** |

---

## 5. Rencana pekan depan (Pekan 14)

| Target | Penanggung jawab |
| :--- | :--- |
| Mengoordinasikan milestone pengujian OLAP dan integrasi Dashboard, serta menyusun draf Laporan Progres Pekan 14 | Andreas Benaya (Project Manager) |
| Membangun dan memvalidasi file skema Mondrian (`olap/schema.xml`) dengan konfigurasi *shared dimensions* dan *calculated members* | Christian Starly (OLAP Developer) |
| Menyusun minimal 5 kueri analitik MDX pada `olap/query.mdx` yang memetakan langsung ke 5 pertanyaan bisnis | Christian Starly (OLAP Developer) |
| Menyiapkan kueri SQL pembanding untuk ke-5 kueri MDX dan mengumpulkan bukti verifikasi kesamaan angka hasil | Nalendra Fadilah Saskara (Data Modeler) |
| Memantau efisiensi indeks basis data DW dan memastikan performa respons kueri OLAP berjalan optimal | Muhammad Alvian Jaya (ETL Developer) |
| Mengintegrasikan hasil agregasi kueri analitik ke dalam visualisasi antarmuka web dashboard interaktif | Wahyu Pratama Andhika M. (Dashboard Developer) |

---

## 6. Kontribusi anggota

| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
| :--- | :--- | :--- | :---: |
| **Andreas Benaya** | Project Manager | Mengawal sprint implementasi ETL, menyusun dokumen Laporan Progres Pekan 13, serta mendokumentasikan hasil pengujian eksekusi Kitchen. | [`e98deac`](https://github.com/benbaeyas/dw-kelompok-4/commit/e98deac6d2c66a534de9993916d0348e168bc600) |
| **Nalendra Fadilah Saskara** | Data Modeler | Menguji validitas integritas data hasil load dimensi dan fakta, memverifikasi kueri rekonsiliasi satu query, serta memeriksa kepatuhan aturan NULL. | [`e9a8fac`](https://github.com/benbaeyas/dw-kelompok-4/commit/e9a8fac54df5906ef39b2742c3fb60bc3010072e) |
| **Muhammad Alvian Jaya** | ETL Developer | Membangun job orkestrasi `job_utama.kjb`, transformasi ekstraksi `t01_ekstrak.ktr`, transformasi dimensi SCD Tipe 2, dan transformasi fakta. | [`b08fb70`](https://github.com/benbaeyas/dw-kelompok-4/commit/b08fb702deb68925fc7add35391a77f068dddb11) |
| **Christian Starly** | OLAP Developer | Menyiapkan pemetaan field fakta dan dimensi untuk koneksi engine Mondrian serta memverifikasi kesiapan grain tabel fakta hasil ETL. | [`99224df`](https://github.com/benbaeyas/dw-kelompok-4/commit/99224df45d0753c8c76982701008fdc251bf10fe) |
| **Wahyu Pratama Andhika M.** | Dashboard Developer | Menyelaraskan output data hasil pemuatan fakta dengan format kebutuhan chart library dashboard web dan parameter filter kuartal dan rekonsiliasi. | [`0e0fcdc`](https://github.com/benbaeyas/dw-kelompok-4/commit/0e0fcdcd070066f6ed3170054abeac868d002eaf) |