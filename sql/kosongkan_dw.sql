-- Dijalankan job SETELAH ekstrak dan SEBELUM dimensi dimuat.
-- Urutan: fakta dulu (merujuk dimensi), lalu dimensi SCD Tipe 1.
-- dim_sales_person (SCD Tipe 2) TIDAK dihapus agar riwayat versi perubahan tetap terjaga.
-- dim_tanggal (standar dosen) dan dim_kategori_kinerja (referensi manual) TIDAK disentuh.
DELETE FROM fact_kinerja_sales_v2;
DELETE FROM dim_produk WHERE produk_key NOT IN (-1, -2);
DELETE FROM dim_wilayah WHERE wilayah_key <> -1;
-- Nomor surrogate key dimensi Tipe 1 dimulai lagi dari 1.
ALTER TABLE dim_produk AUTO_INCREMENT = 1;
ALTER TABLE dim_wilayah AUTO_INCREMENT = 1;
