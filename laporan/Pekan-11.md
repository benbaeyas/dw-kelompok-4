# Laporan Progres Pekan 11

Kelompok : 4 Empat  
Proses bisnis : Kinerja Sales vs Target  
Status : Hijau  

---

## 1. Target dan capaian

| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
| :--- | :---: | :--- |
| **Perbaiki star schema menjadi versi 2**<br>Ikuti catatan sponsor dari Steering Review hari ini. Pakai struktur `dim_tanggal` standar apa adanya. Sesuaikan `dim_produk` dengan struktur standar. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/Star%20Schema.sql |
| **Source-to-target mapping lengkap**<br>Untuk setiap kolom di setiap dimensi dan fakta. Pakai templat mapping lengkap. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/mapping.md |
| **Strategi SCD tiap dimensi**<br>Tulis tipe yang dipakai untuk kolom-kolom penting beserta alasannya. Minimal satu dimensi memakai tipe 2. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/strategi_scd.md |
| **Urutan load**<br>Daftar urutan tabel yang dimuat, dari staging sampai fakta. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/urutan_load_data.md |
| **Desain cube**<br>Tabel desain dimensi, hierarki, measure, dan minimal satu calculated member. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/desain_cube.md |
| **Wireframe dashboard**<br>Setiap visual diberi nomor pertanyaan bisnis yang dijawabnya. Semua pertanyaan bisnis terwakili. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/dashboard/Dashboard%20Sales.png |
| **Uji Pentaho**<br>Pasang Pentaho Data Integration, buka Spoon, buat koneksi ke database sumber, dan jalankan satu Table Input sederhana. Simpan tangkapan layarnya. | Selesai | https://github.com/benbaeyas/dw-kelompok-4/issues/1 https://github.com/benbaeyas/dw-kelompok-4/blob/main/etl/uji_pentaho-Adventureworks.ktr |

---

## 2. Kendala pengerjaan

- **Penyelarasan Tipe Data Tanggal & Timezone:** Perlu penyesuaian offset waktu (-5.5 jam) pada saat ekstraksi data pesanan di Pentaho agar tanggal pesanan tidak bergeser satu hari ke belakang.
- **Konfigurasi Driver JDBC Pentaho:** Memerlukan penempatan file `mysql-connector-j.jar` / `mariadb-java-client.jar` ke dalam direktori `lib/` Spoon agar koneksi database dikenali dengan baik.

---

## 3. Kendala tim

Koordinasi antar anggota tim berjalan dengan baik melalui pertemuan mingguan dan diskusi grup luring maupun daring walaupun kesulitan untuk meyelaraskan ide dan keep up dalam pengerjaan. Namun, hal tersebut tidak menghambat progres penyelesaian deliverable Pekan 11 yang telah disepakati dan dikerjakan sesuai peran spesifik masing-masing.

---

## 4. Keputusan yang butuh persetujuan sponsor

- **Penetapan Nilai Batas Kategori Kinerja:** Konfirmasi rentang persentase untuk `dim_kategori_kinerja` (misal: `>= 100%` untuk Melampaui Target, `80% - 99%` untuk Memenuhi Target, dan `< 80%` untuk Kurang).
- **Penanganan Periode Tanpa Kuota (Q2 2014):** Penegasan kembali bahwa realisasi pada Q2 2014 diklasifikasikan dengan kategori khusus `Tanpa Kuota` (*No Quota*) agar tidak dianggap sebagai defisit performa.

---

## 5. Rencana pekan depan (Pekan 12)

| Target | Penanggung jawab |
| :--- | :--- |
| Mengawal jadwal sprint ETL, memantau milestone integrasi data, serta menyiapkan draf laporan progres Pekan 12 | Benaya (Project Manager)
| Membangun transformasi staging dan pembersihan data di Pentaho Data Integration | Jaya (ETL Developer) |
| Mengimplementasikan *Dimension Lookup/Update* (SCD Tipe 2) untuk `dim_sales_person` | Jaya (ETL Developer) |
| Validasi rekonsiliasi data dan pengujian integrity constraints database data warehouse | Nalendra (Data Modeler) |
| Penyusunan draf skema Mondrian XML dan query MDX awal | Christian (OLAP Developer) |
| Persiapan layout web dashboard berbasis visual library sesuai wireframe | Andhika (Dashboard Developer) |

---

## 6. Kontribusi anggota

| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
| :--- | :--- | :--- | :---: |
| **Andreas Benaya** | Project Manager | Mengoordinasikan pembagian tugas Pekan 11, menyusun dokumen Laporan Progres Pekan 11, dan mengawal keselarasan target sponsor. | [`141b068`](https://github.com/benbaeyas/dw-kelompok-4/commit/141b068a26069700d5e234d67e1f6e0d9e64253c) |
| **Nalendra Fadilah Saskara** | Data Modeler | Memperbaiki skema star schema ke versi 2, menyelaraskan `dim_tanggal` & `dim_produk` standar, serta menyusun Source-to-Target Mapping (STTM). | [`6d00fca`](https://github.com/benbaeyas/dw-kelompok-4/commit/6d00fca4d3de4d407a398322df393787f01fca66) |
| **Muhammad Alvian Jaya** | ETL Developer | Melakukan uji koneksi Pentaho Data Integration (Spoon), mengonfigurasi Table Input sumber, dan merancang alur urutan load tabel. | [`14554cb`](https://github.com/benbaeyas/dw-kelompok-4/commit/14554cb43ab421508c80da5e4b670b1303efd22e) |
| **Christian Starly** | OLAP Developer | Merancang arsitektur Cube Mondrian, memetakan dimensi, hierarki, measure, serta formula calculated member pencapaian target. | [`cf6e150`](https://github.com/benbaeyas/dw-kelompok-4/commit/cf6e150792ad723c3a1f3808057bfd6392e47979) |
| **Wahyu Pratama Andhika M.** | Dashboard Developer | Merancang wireframe dashboard lengkap dan memetakan setiap komponen visual ke 5 pertanyaan bisnis. | [`def8623`](https://github.com/benbaeyas/dw-kelompok-4/commit/def86234cb366534007d625777a5eec519bfa646) |
