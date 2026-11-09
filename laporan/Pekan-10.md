# Laporan Progres Pekan 10

Kelompok : 4 Empat
Proses bisnis : Kinerja Sales vs Target
Status : Hijau

## 1. Target dan capaian

| Target pekan ini                           | Status  | Bukti (tautan file, commit, tangkapan layar)                                                       |
| ------------------------------------------ | ------- | -------------------------------------------------------------------------------------------------- |
| Repositori dan dosen diundang              | Selesai | [(https://github.com/benbaeyas/dw-kelompok-4)]                                                     |
| Piagam proyek terisi lengkap               | Selesai | [https://docs.google.com/document/d/14GiFn3XX6SwZr9DJC9ZVn6wI6WcP6sHAKJbeu4PZv4c/edit?usp=sharing] |
| 5 pertanyaan bisnis dengan fakta & dimensi | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Pernyataan grain dalam satu kalimat        | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Rancang star schema versi 1                | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Isi baris bus matrix tim                   | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Profil data sumber tersimpan               | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Minimal 3 risiko dan penanganannya         | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |
| Database Adventure Works berjalan          | Selesai | [https://docs.google.com/document/d/1V443pcDMo8ZP1meIALPJdeeeEOEoPS4I5EJz3kemE3Q/edit?usp=sharing] |

## 2. Kendala pengerjaan

- **Perbedaan Penamaan Tabel Database:** Sempat terjadi _error_ karena format pemisah nama skema dan tabel (`sales.salespersonquotahistory` vs `sales_salespersonquotahistory`). Sudah diselesaikan dengan menyesuaikan kueri ke format _underscore_ sesuai dengan sumber database (MariaDB/MySQL port).
- **Data NULL pada Wilayah:** Ditemukan bahwa 3 dari 17 Sales Person tidak memiliki `TerritoryID` di tabel profil utamanya, sehingga berpotensi menyebabkan relasi yang kosong (_null_) saat disambung ke dimensi wilayah. Kami berencana menggunakan `sales_salesterritoryhistory` atau membuat dimensi "Unassigned" saat proses ETL.

## 3. Kendala tim

Semua anggota tim dapat dihubungi dan pembagian kerja berjalan lancar sesuai dengan peran masing-masing. Komunikasi dilakukan rutin melalui [Grup WhatsApp/Discord]. _(Catatan: Silakan disesuaikan jika ada kendala nyata di tim)_

## 4. Keputusan yang butuh persetujuan sponsor

- **Penanganan Data Target (Quota) yang Terbatas:** Target penjualan (`SalesQuota`) dari data sumber hanya tersedia hingga kuartal 1 tahun 2014, sedangkan data realisasi transaksi berlangsung hingga Juni 2014. Kami memohon persetujuan sponsor agar realisasi Q2 2014 dibiarkan tanpa perhitungan selisih target di dashboard akhir agar laporan tidak bias.
- **Tabel Sumber Database:** Sesuai instruksi proyek, instalasi standar menggunakan PostgreSQL, namun sumber data awal kami diekstrak dari format MariaDB. Kami memohon konfirmasi ulang apakah perancangan DDL kami harus menggunakan standar dialek PostgreSQL atau bebas asalkan _star schema_ terbentuk sempurna.

## 5. Rencana pekan depan

| Target                                        | Penanggung jawab              |
| --------------------------------------------- | ----------------------------- |
| Mengawal jadwal sprint ETL, memantau milestone integrasi data, serta menyiapkan draf laporan progres Pekan 12 | Benaya (Project Manager) |
| Persiapan skrip DDL untuk Star Schema final   | Nalendra (Data Modeler)       |
| Merancang awal transformasi dimensi SCD (ETL) | Jaya (ETL Developer)          |
| Menyiapkan kerangka skema Mondrian            | Christian (OLAP Developer)    |
| Menyiapkan aset/library untuk Dashboard       | Andhika (Dashboard Developer) |

## 6. Kontribusi anggota

| Nama      | Peran               | Yang dikerjakan pekan ini                                                                              | Bukti commit    |
| --------- | ------------------- | ------------------------------------------------------------------------------------------------------ | --------------- |
| Benaya    | Project Manager     | Mengatur rapat, menyusun laporan progres Pekan 10, melengkapi Piagam Proyek.                           | [Tautan commit] |
| Nalendra  | Data Modeler        | Menganalisis OLTP, mendefinisikan _grain_, merancang Star Schema versi 1, menyusun Bus Matrix.         | [Tautan commit] |
| Jaya      | ETL Developer       | Memasang database, menjalankan kueri profil data sumber (menghitung baris, rentang tanggal, dan NULL). | [Tautan commit] |
| Christian | OLAP Developer      | Menganalisis kebutuhan fakta (additivity) dan kesiapan dimensi untuk 5 pertanyaan bisnis.              | [Tautan commit] |
| Andhika   | Dashboard Developer | Merancang kerangka awal visualisasi pertanyaan bisnis untuk persiapan _wireframe_.                     | [Tautan commit] |
