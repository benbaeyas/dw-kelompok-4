-- sql/uji_constraint.sql
-- Bukti bahwa constraint benar-benar bekerja. Jalankan SATU PERINTAH SEKALI di database DW
-- kelompok (setelah dim_tanggal standar dan ddl.sql). Setiap perintah bertanda GAGAL
-- harus ditolak database. Simpan tangkapan layar pesan error tiap uji.
--
-- Aman dijalankan sebelum atau sesudah ETL: semua baris uji memakai
-- tanggal_kuartal_key 20100101, tanggal yang tidak dipakai data AdventureWorks
-- (data 2011-2014), sehingga pembersihan di bagian akhir tidak menyentuh data asli.
--
-- Nomor error MySQL 8: FK 1452, CHECK 3819, PRIMARY KEY/UNIQUE 1062, NOT NULL 1048.
-- (MariaDB memberi nomor lain untuk CHECK: 4025.)

-- ---------------------------------------------------------------------
-- Uji 1: FOREIGN KEY. produk_key 99999 tidak ada di dim_produk.
-- Harapan: GAGAL, ERROR 1452 (foreign key fk_fkjs_produk).
-- ---------------------------------------------------------------------
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, 99999, NULL, 100.0000, NULL, 1, -1);

-- ---------------------------------------------------------------------
-- Uji 2: CHECK. Jumlah terjual negatif tidak masuk akal.
-- (Nol diperbolehkan karena baris target tanpa penjualan memang bernilai 0.)
-- Harapan: GAGAL, ERROR 3819 (check constraint ck_fkjs_jumlah).
-- ---------------------------------------------------------------------
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, -1, NULL, 100.0000, NULL, -5, -1);

-- ---------------------------------------------------------------------
-- Uji 3: PRIMARY KEY. Jalankan perintah ini DUA KALI.
-- Harapan: pertama BERHASIL, kedua GAGAL, ERROR 1062 (Duplicate entry).
-- Ini yang terjadi bila ETL dijalankan dua kali tanpa mengosongkan fakta.
-- ---------------------------------------------------------------------
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, -1, NULL, 100.0000, NULL, 1, -1);

-- ---------------------------------------------------------------------
-- Uji tambahan A: NOT NULL. kategori_kinerja_key tidak boleh kosong (pakai -1, bukan NULL).
-- Harapan: GAGAL, ERROR 1048 (Column 'kategori_kinerja_key' cannot be null).
-- ---------------------------------------------------------------------
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, -2, NULL, 100.0000, NULL, 1, NULL);

-- ---------------------------------------------------------------------
-- Uji tambahan B: UNIQUE natural key. product_id -1 sudah dipakai baris "Tidak diketahui".
-- Harapan: GAGAL, ERROR 1062 (uq_dim_produk_product).
-- ---------------------------------------------------------------------
INSERT INTO dim_produk
    (product_id, nama_produk, nomor_produk, sub_kategori, kategori, list_price)
VALUES
    (-1, 'Produk ganda', 'X-1', 'Uji', 'Uji', 1);

-- ---------------------------------------------------------------------
-- Uji tambahan C: CHECK SCD tipe 2. Tanggal berlaku tidak boleh melewati tanggal berakhir.
-- Harapan: GAGAL, ERROR 3819 (ck_dim_sales_person_berlaku).
-- ---------------------------------------------------------------------
INSERT INTO dim_sales_person
    (business_entity_id, nama_lengkap, jabatan, tanggal_masuk, komisi_pct, bonus,
     row_effective_date, row_expiry_date)
VALUES
    (-99, 'Uji SCD', 'Uji', '2013-01-01', 0.01, 0, '2013-06-01', '2013-01-01');

-- ---------------------------------------------------------------------
-- Bersihkan setelah selesai (hanya menghapus baris uji)
-- ---------------------------------------------------------------------
DELETE FROM fact_kinerja_sales_v2 WHERE tanggal_kuartal_key = 20100101;
