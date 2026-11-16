# Laporan Progres Pekan 12

**Kelompok:** 4 | **Proyek:** Perancangan Data Warehouse Evaluasi Kinerja Penjualan dan Pencapaian Target Adventure Works
**Proses bisnis:** Kinerja Sales vs Target | **Tahap:** Implementasi data warehouse di RDBMS (tugas pekan 11, dilaporkan di Steering Review pekan 12)

## 1. Target dan capaian

| Target pekan ini | Status | Bukti |
|---|---|---|
| Pasang `dim_tanggal` standar v1.0 (2192 baris, 20130315 = Jumat) | [Selesai / Belum] | `sql/cek_dim_tanggal.sql`, tangkapan layar |
| `sql/ddl.sql` dapat dijalankan dua kali tanpa error | [Selesai / Belum] | tangkapan layar dua kali jalan |
| Uji constraint (FK, CHECK, PK) | [Selesai / Belum] | `sql/uji_constraint.sql`, tangkapan layar error |
| Kamus data semua tabel | Selesai (draf) | `docs/kamus-data.md` |
| ERD hasil reverse engineering dan perbandingan dengan v2 | [Selesai / Belum] | `docs/erd-v2.md`, `docs/erd-v2.png` |
| Daftar tabel staging di dokumen pemetaan | Selesai (draf) | `docs/mapping_tambahan_pekan11.md` |

## 2. Kendala

- Target kuota hanya per salesperson per kuartal, sedangkan grain fakta memuat produk: target akan terhitung berulang. Diusulkan CR-01.
- Dokumen tim belum seragam (key tidak diketahui 0 vs -1, himpunan kategori kinerja, daftar tabel sumber di piagam). Dirapikan di lampiran pemetaan.
- [kendala teknis lain saat menjalankan skrip, bila ada]

## 3. Keputusan dan permintaan persetujuan sponsor

| Item | Keputusan yang diminta |
|---|---|
| CR-01 (target hanya pada baris produk -2) | [Disetujui / Ditolak / Ditunda] |
| Pemakaian key -1 sebagai satu-satunya key "tidak diketahui" | [isi] |
| Perubahan fisik (DECIMAL(14,4), constraint, `kode_kategori` VARCHAR(20)) | Diinformasikan, tanpa CR |

## 4. Rencana pekan depan

ETL dengan Pentaho: muat staging, `dim_wilayah`, `dim_produk`, `dim_sales_person` (SCD tipe 2), `dim_kategori_kinerja`, lalu fakta; uji dua kali jalan tanpa data ganda dan query rekonsiliasi selisih nol.

## 5. Kontribusi anggota

| Anggota | Peran | Kontribusi |
|---|---|---|
| Andreas Benaya | Project Manager | [isi] |
| Nalendra Fadilah Saskara | Data Modeler | [isi: kamus data, ERD] |
| Muhammad Alvian Jaya | ETL Developer | [isi: daftar staging] |
| Christian Starly | OLAP Developer | [isi] |
| Wahyu Pratama Andhika M. | Dashboard Developer | [isi] |
