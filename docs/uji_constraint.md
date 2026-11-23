# Laporan Pengujian Constraint Integritas Data Warehouse

**Kelompok:** 4 (Empat)  
**Proses Bisnis:** Kinerja Sales vs Target  
**Basis Data Target:** `adn_kl4`  
**Tabel Pengujian:** `fact_kinerja_sales_v2`  
**Referensi Skrip:** [`sql/uji_constraint.sql`](../sql/uji_constraint.sql) & [`sql/ddl_kelompok-4.sql`](../sql/ddl_kelompok-4.sql)  

---

## 1. Pendahuluan dan Tujuan Pengujian

Pengujian constraint (*constraint testing*) bertujuan untuk memvalidasi bahwa skema fisik Data Warehouse yang telah diimplementasikan mampu menjaga integritas data secara otomatis pada level basis data. Pengujian ini memastikan:
1. **Integritas Referensial (*Foreign Key*):** Mencegah masuknya baris fakta yang mereferensikan *surrogate key* dimensi yang tidak valid / tidak terdaftar.
2. **Integritas Domain & Logika Bisnis (*CHECK Constraint*):** Menolak data anomali yang melanggar aturan bisnis (seperti nilai kuantitas penjualan negatif).
3. **Integritas Entitas (*Primary Key*):** Mencegah duplikasi data fakta pada *grain* yang sama saat proses ETL dijalankan berulang kali tanpa pengosongan tabel (*idempotency protection*).

Semua pengujian menggunakan data dummy dengan partisi tanggal uji `tanggal_kuartal_key = 20100101` (periode di luar rentang transaksi riil AdventureWorks 2011–2014) sehingga aman dijalankan tanpa merusak atau mengontaminasi data operasional DW.

---

## 2. Ringkasan Hasil Pengujian

| No | Jenis Constraint | Nama Constraint / Kolom | Deskripsi Skenario Uji | Hasil yang Diharapkan | Hasil Aktual (Error DB) | Status |
|:--:|:---|:---|:---|:---|:---|:--:|
| **1** | **FOREIGN KEY** | `fk_fkjs_produk`<br>(`produk_key`) | Menyisipkan data fakta dengan `produk_key = 99999` yang tidak ada di `dim_produk`. | **Ditolak (GAGAL)**<br>Error 1452 | Ditolak: `SQL Error (1452)` Foreign key constraint fails | **VALID** |
| **2** | **CHECK** | `ck_fkjs_jumlah`<br>(`jumlah_terjual`) | Menyisipkan data fakta dengan kuantitas penjualan negatif (`jumlah_terjual = -5`). | **Ditolak (GAGAL)**<br>Error 3819 | Ditolak: `SQL Error (3819)` Check constraint violated | **VALID** |
| **3** | **PRIMARY KEY** | `PRIMARY`<br>(Composite PK Fakta) | Menjalankan *insert* baris yang sama sebanyak 2 kali (duplikasi kombinasi dimensi kunci). | **Eksekusi 1: Berhasil**<br>**Eksekusi 2: Gagal** (Error 1062) | Ditolak pada eksekusi ke-2: `SQL Error (1062)` Duplicate entry | **VALID** |

---

## 3. Rincian Pengujian dan Bukti Tangkapan Layar

### 3.1. Uji 1: Pengujian Foreign Key Constraint (`fk_fkjs_produk`)

* **Tujuan:** Memastikan data fakta hanya dapat dikaitkan dengan dimensi produk yang valid dan terdaftar di `dim_produk`.
* **Skenario:** Percobaan *insert* baris fakta dengan `produk_key = 99999` (kunci tidak terdaftar).
* **Kode SQL Pengujian:**

```sql
-- Uji 1: FOREIGN KEY. produk_key 99999 tidak ada di dim_produk.
-- Harapan: GAGAL, ERROR 1452 (foreign key fk_fkjs_produk).
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, 99999, NULL, 100.0000, NULL, 1, -1);
```

* **Pesan Error Basis Data:**
  ```text
  SQL Error (1452): Cannot add or update a child row: a foreign key constraint fails
  (`adn_kl4`.`fact_kinerja_sales_v2`, CONSTRAINT `fk_fkjs_produk` FOREIGN KEY (`produk_key`) REFERENCES `dim_produk` (`produk_key`))
  ```

* **Bukti Tangkapan Layar:**

![Bukti Uji 1 - Foreign Key Constraint](<Bukti Gamber/uji_constraint 1.jpeg>)

* **Analisis:** Sistem basis data menolak transaksi dan mengeluarkan pesan error 1452. Hal ini membuktikan relasi integritas referensial antara tabel fakta `fact_kinerja_sales_v2` dan tabel dimensi `dim_produk` aktif dan berfungsi secara konsisten.

---

### 3.2. Uji 2: Pengujian CHECK Constraint (`ck_fkjs_jumlah`)

* **Tujuan:** Menjamin kevalidan domain nilai bisnis bahwa barang terjual (*unit quantity*) tidak boleh bernilai negatif (`jumlah_terjual >= 0`). Nilai nol tetap diperbolehkan khusus untuk baris target kuota tanpa transaksi penjualan riil.
* **Skenario:** Percobaan *insert* baris fakta dengan `jumlah_terjual = -5`.
* **Kode SQL Pengujian:**

```sql
-- Uji 2: CHECK. Jumlah terjual negatif tidak masuk akal.
-- (Nol diperbolehkan karena baris target tanpa penjualan memang bernilai 0.)
-- Harapan: GAGAL, ERROR 3819 (check constraint ck_fkjs_jumlah).
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, -1, NULL, 100.0000, NULL, -5, -1);
```

* **Pesan Error Basis Data:**
  ```text
  SQL Error (3819): Check constraint 'ck_fkjs_jumlah' is violated.
  ```

* **Bukti Tangkapan Layar:**

![Bukti Uji 2 - CHECK Constraint](<Bukti Gamber/uji_constraint 2.jpeg>)

* **Analisis:** MySQL menolak operasi penambahan baris karena melanggar constraint `CONSTRAINT ck_fkjs_jumlah CHECK (jumlah_terjual >= 0)`. Hal ini membuktikan bahwa validasi *business rule* di lapisan basis data berjalan efektif mencegah polusi data (*dirty data*) masuk ke dalam Data Warehouse.

---

### 3.3. Uji 3: Pengujian Primary Key Constraint (`PRIMARY`)

* **Tujuan:** Menguji keunikan *composite primary key* (`tanggal_kuartal_key`, `sales_person_key`, `wilayah_key`, `produk_key`) untuk mencegah duplikasi baris pada *grain* analisis yang sama.
* **Skenario:** Mengeksekusi query *insert* yang sama sebanyak dua kali berturut-turut pada data fakta tanpa pembersihan tabel.
* **Kode SQL Pengujian:**

```sql
-- Uji 3: PRIMARY KEY. Jalankan perintah ini DUA KALI.
-- Harapan: pertama BERHASIL, kedua GAGAL, ERROR 1062 (Duplicate entry).
-- Ini yang terjadi bila ETL dijalankan dua kali tanpa mengosongkan fakta.
INSERT INTO fact_kinerja_sales_v2
    (tanggal_kuartal_key, sales_person_key, wilayah_key, produk_key,
     target_penjualan, realisasi_penjualan, selisih_realisasi_target,
     jumlah_terjual, kategori_kinerja_key)
VALUES
    (20100101, -1, -1, -1, NULL, 100.0000, NULL, 1, -1);
```

* **Pesan Error Basis Data (Pada Eksekusi Kedua):**
  ```text
  SQL Error (1062): Duplicate entry '20100101--1--1--1' for key 'fact_kinerja_sales_v2.PRIMARY'
  ```

* **Bukti Tangkapan Layar:**

![Bukti Uji 3 - Primary Key Duplicate](<Bukti Gamber/uji_constraint 3.jpeg>)

* **Analisis:** Eksekusi pertama berhasil menambahkan data. Pada eksekusi kedua, basis data membangkitkan `SQL Error (1062)` karena terdapat duplikasi *entry* pada *composite primary key* `'20100101--1--1--1'`. Pengujian ini membuktikan bahwa *grain* fakta terlindungi dari penggandaan data yang tidak disengaja.

---

## 4. Pembersihan Data Uji (*Post-Test Cleanup*)

Setelah seluruh skenario pengujian selesai dijalankan, dilakukan pembersihan data dummy uji agar tabel fakta tetap bersih sebelum pemuatan data dari pipeline ETL.

```sql
-- ---------------------------------------------------------------------
-- Bersihkan setelah selesai (hanya menghapus baris uji)
-- ---------------------------------------------------------------------
DELETE FROM fact_kinerja_sales_v2 WHERE tanggal_kuartal_key = 20100101;
```

---

## 5. Kesimpulan

Berdasarkan pengujian yang telah dilakukan dengan skrip `sql/uji_constraint.sql`:
1. Seluruh mekanisme constraint (**FOREIGN KEY**, **CHECK**, dan **PRIMARY KEY**) pada tabel fakta `fact_kinerja_sales_v2` terbukti **aktif dan berfungsi sempurna**.
2. Setiap percobaan pemasukan data anomali berhasil ditolak oleh RDBMS dengan kode error yang tepat (`1452`, `3819`, dan `1062`).
3. Skema Data Warehouse telah memiliki proteksi level basis data yang kokoh untuk menjamin keakuratan dan konsistensi data sebelum proses transformasi dan pemuatan (ETL) dijalankan.
