# Laporan Progres Pekan 12

Kelompok : 4 Empat  
Proses bisnis : Kinerja Sales vs Target  
Status : Hijau  

---

## 1. Target dan capaian

| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
| :--- | :---: | :--- |
| Pasang `dim_tanggal` standar v1.0 (2192 baris, 20130315 = Jumat) | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/dim_tanggal_mysql.sql |
| `sql/ddl.sql` dapat dijalankan dua kali tanpa error | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/ddl_kelompok-4.sql |
| Uji constraint (FK, CHECK, PK) | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/uji_constraint.sql https://github.com/benbaeyas/dw-kelompok-4/issues/2#issue-6435877741 |
| Kamus data semua tabel | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/kamus-data.md |
| ERD hasil reverse engineering dan perbandingan dengan v2 | [Selesai] | https://github.com/benbaeyas/dw-kelompok-4/blob/main/sql/erd_star_schema.html |
| Daftar tabel staging di dokumen pemetaan | Selesai | https://github.com/benbaeyas/dw-kelompok-4/blob/main/docs/dokumen%20mapping.md |
    
## 2. Kendala pengerjaan

- Target kuota hanya per salesperson per kuartal, sedangkan grain fakta memuat produk: target akan terhitung berulang. Diusulkan CR-01.
- Dokumen tim belum seragam (key tidak diketahui 0 vs -1, himpunan kategori kinerja, daftar tabel sumber di piagam). Dirapikan di lampiran pemetaan.

## 3. Kendala tim

Pembagian kinerja antar peran antar tim belum optimal. Disarankan untuk segera merapatkan pembagian kinerja agar tidak ada tumpang tindih pekerjaan. Namun untuk koordinasi antar anggota sudah cukup bagus.

## 4. Keputusan dan permintaan persetujuan sponsor

| Item | Keputusan yang diminta |
|---|---|
| CR-01 (target hanya pada baris produk -2) | [Disetujui / Ditolak / Ditunda] |
| Pemakaian key -1 sebagai satu-satunya key "tidak diketahui" | [isi] |
| Perubahan fisik (DECIMAL(14,4), constraint, `kode_kategori` VARCHAR(20)) | Diinformasikan, tanpa CR |

## 5. Rencana pekan depan (Pekan 13)

| Target | Penanggung jawab |
| :--- | :--- |
| Mengoordinasikan milestone implementasi OLAP, memantau pengujian MDX vs SQL, serta menyusun draf laporan progres Pekan 14 (termasuk inventarisasi pertanyaan bisnis yang belum bisa dijawab cube) | Benaya (Project Manager) |
| Membangun file `olap/schema.xml` sesuai tabel desain cube pekan 10 dan memastikan validasi skema bersih (tidak ada elemen merah) di Schema Workbench | Christian (OLAP Developer) |
| Mengonfigurasi Dimensi Waktu sebagai shared dimension di tingkat `<Schema>`, lalu memanggilnya ke dalam cube via `<DimensionUsage>` | Christian (OLAP Developer) |
| Mendefinisikan minimal satu calculated member pada cube (misal: persentase pencapaian kuota / *attainment percentage* atau rata-rata penjualan) | Christian (OLAP Developer) |
| Menyusun minimal 5 query MDX di `olap/query.mdx` yang masing-masing diberi nomor pertanyaan bisnis yang dijawabnya | Christian (OLAP Developer) |
| Menyusun query SQL pembanding untuk ke-5 query MDX serta mengumpulkan bukti tangkapan layar verifikasi (hasil MDX sama dengan SQL) | Nalendra (Data Modeler) |
| Menjaga performa query dan memastikan integritas data fakta serta dimensi di database DW saat dieksekusi oleh engine Mondrian | Jaya (ETL Developer) |
| Menyelaraskan hasil agregasi query MDX dengan kebutuhan data visualisasi pada rancangan antarmuka dashboard | Andhika (Dashboard Developer) |

## 6. Kontribusi anggota

| Anggota | Peran | Kontribusi |
|---|---|---|
| Andreas Benaya | Project Manager | [`141b068`] (https://github.com/benbaeyas/dw-kelompok-4/commit/ac6c1f14550d8dc461474b577ef9bcd2aaa965d1) |
| Nalendra Fadilah Saskara | Data Modeler | [isi: kamus data, ERD] (https://github.com/benbaeyas/dw-kelompok-4/commit/8be110f8947f849007ed7c617204e5d74bb32162) |
| Muhammad Alvian Jaya | ETL Developer | [isi: daftar staging] (https://github.com/benbaeyas/dw-kelompok-4/commit/32e5070fa55a6ecb40c97d67d692edd5653a68ee) |
| Christian Starly | OLAP Developer | [isi] (https://github.com/benbaeyas/dw-kelompok-4/commit/77adffd78b0acee639824bc9eaf93b177cb9af78) |
| Wahyu Pratama Andhika M. | Dashboard Developer | [isi] (https://github.com/benbaeyas/dw-kelompok-4/commit/668c40ae9ac5fce3e19b7529da8be50145b7bf21) |