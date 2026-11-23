# Panduan ETL Pentaho: Kelompok 4, Kinerja Sales vs Target

Job `etl/job_utama.kjb` mengisi seluruh DW (`adn_kl4-v2`) dari AdventureWorks (`dump-adventureworks`) sekali jalan dan mendukung **SCD Tipe 2** pada `dim_sales_person` (serta aman dijalankan ulang tanpa data ganda).

## 1. Isi paket

| Berkas | Fungsi |
|---|---|
| `etl/job_utama.kjb` | Job: buat staging → t01 → kosongkan fakta & dimensi Tipe 1 → t02–t05 → t10 → Success |
| `etl/t01_ekstrak.ktr` | 12 pasang Table input → Table output (sumber → `stg_*`, Truncate table) |
| `etl/t02_dim_wilayah.ktr`, `t03_dim_produk.ktr` | Staging → dimensi SCD Tipe 1 (Table input dengan aturan mapping, Table output tanpa surrogate key) |
| `etl/t04_dim_sales_person.ktr` | Staging → `dim_sales_person` dengan **SCD Tipe 2** (`jabatan`, `komisi_pct`, `bonus`) dan **SCD Tipe 1** (`nama_lengkap`, `tanggal_masuk`) |
| `etl/t05_dim_kategori_kinerja.ktr` | Tabel referensi lewat Insert/Update (aman diulang) |
| `etl/t10_fact_kinerja_sales.ktr` | Query berbentuk grain → 4 Database lookup (default -1, `dim_sales_person` pakai rentang tanggal efektif) → `fact_kinerja_sales_v2` |
| `sql/staging_ddl.sql`, `sql/kosongkan_dw.sql` | Dipasang juga di dalam job sebagai entri SQL (`kosongkan_dw.sql` mempertahankan riwayat `dim_sales_person`) |
| `sql/query_t01…t10_*.sql` | Salinan query tiap Table input, untuk dilampirkan di dokumen mapping |
| `sql/cek_sumber_vs_staging.sql` | Jumlah baris sumber dibanding staging (jalankan A di sumber, B di DW) |
| `sql/rekonsiliasi.sql` | Bukti angka cocok dan bukti versi SCD Tipe 2, jalankan setelah job selesai |
| `sql/uji_pertanyaan_bisnis.sql` | SQL pembanding untuk 5 pertanyaan bisnis (bahan MDX vs SQL pekan 13) |

## 2. Cara menjalankan

1. Di database `adn_kl4-v2`: pastikan DDL v2 dan `dim_tanggal` (2192 baris) sudah terpasang.
2. Taruh `mysql-connector-j.jar` di folder `lib` Pentaho, buka ulang Spoon.
3. Ekstrak folder `dw-kelompok-4/` ke repo, buka `etl/job_utama.kjb`. Setiap berkas membawa dua koneksi bernama `dump-adventureworks_kel4` (db `dump-adventureworks`) dan `adn_kl4-v2` (db `adn_kl4-v2`), server `localhost:3306`, user `root`, password kosong. Ubah di Spoon bila berbeda (klik kanan koneksi → Share agar sekali ubah untuk semua).
4. Jalankan job (Run). Atau dari terminal: `Kitchen.bat /file:C:\path\repo\etl\job_utama.kjb /level:Basic`.
5. Jalankan `sql/rekonsiliasi.sql` di `adn_kl4-v2`, simpan tangkapan layar (termasuk bagian F untuk bukti SCD Tipe 2).
6. Uji dua kali: jalankan job lagi, jalankan rekonsiliasi lagi. Jumlah baris fakta dan baris aktif dimensi harus sama tanpa error duplicate key.

## 3. Keputusan desain (supaya bisa dijelaskan ke sponsor)

| Topik | Keputusan | Alasan |
|---|---|---|
| Tanggal | Di t01 (sumber → staging) kolom tanggal dibaca sebagai teks `YYYY-MM-DD` (`DATE_FORMAT`). Di t10, `tanggal_kuartal` dikirim sebagai tipe DATE asli | Teks di t01 menghindari pergeseran zona waktu JDBC. Di t10, Database lookup mencocokkan ke kolom DATE `dim_sales_person` dan menolak string (error `couldn't convert string [2011-04-01] to a date`), jadi nilainya harus bertipe tanggal |
| Realisasi | `OrderQty × UnitPrice × (1 − UnitPriceDiscount)` untuk pesanan `OnlineOrderFlag = 0` dengan `SalesPersonID` terisi | Sama dengan `LineTotal`, tetapi tidak bergantung pada ada-tidaknya kolom itu di versi MySQL dari sumber. Tanpa pajak dan ongkos kirim |
| Kuartal kuota | Kuartal dari `QuotaDate`, kuota per salesperson per kuartal dijumlah | Tanggal kuota tidak selalu tanggal 1 kuartal (mis. 31 Mei). `SUM` aman bila ada dua kuota dalam satu kuartal; rekonsiliasi akan menangkapnya |
| Wilayah | Riwayat penugasan (`sales_salesterritoryhistory`) yang beririsan dengan kuartal, ambil yang mulai paling akhir; bila tidak ada pakai `TerritoryID` salesperson; bila tetap kosong → -1 | Sesuai kamus: "wilayah penugasan salesperson pada kuartal itu" |
| CR-01 | Target dan selisih hanya di baris produk -2 (satu baris per salesperson per kuartal bertarget). Baris produk membawa realisasi dan unit, target NULL | Mencegah target terhitung berulang per produk |
| Kategori | 4 kategori sesuai DDL v2: TERCAPAI, BELUM_TERCAPAI, TANPA_TARGET, TARGET_SAJA. Dihitung per salesperson-kuartal (total realisasi vs kuota) dan dipasang di semua baris salesperson-kuartal itu | Cocok dengan `dim_kategori_kinerja` yang sudah dibuat |
| `dim_sales_person` (SCD Tipe 2) | Pemuatan awal memakai `row_effective_date = 1900-01-01` dan `row_expiry_date = 9999-12-31`. Jika atribut historis (`jabatan`, `komisi_pct`, `bonus`) berubah pada run berikutnya, baris lama ditutup (`CURDATE() - 1 hari`) dan baris baru disisipkan (`CURDATE()` s.d. `9999-12-31`). Jika hanya `nama_lengkap` atau `tanggal_masuk` yang berubah, diperbarui langsung (SCD Tipe 1) | Mempertahankan riwayat kinerja salesperson saat terjadi mutasi jabatan, komisi, atau bonus tanpa menghapus versi historis |
| Muat ulang | Fakta dan dimensi Tipe 1 (`dim_produk`, `dim_wilayah`) dikosongkan tiap run, sedangkan `dim_sales_person` dipertahankan untuk histori SCD Tipe 2, dan baris -1/-2, `dim_tanggal`, serta `dim_kategori_kinerja` tetap utuh | Menjaga konsistensi fakta sekaligus riwayat versi SCD Tipe 2 |

## 4. Hal yang perlu diputuskan atau diketahui tim

- **Rumus pencapaian % untuk cube (Christian):** `(SUM(target) + SUM(selisih)) / SUM(target)`. Target dan selisih hanya ada di baris -2, jadi rumus ini benar di agregasi apa pun dan hanya menghitung salesperson-kuartal bertarget. `SUM(realisasi)` tetap memuat Q2 2014 yang tanpa target.
- **Menghitung kuartal tercapai:** hitung baris `produk_key = -2`, atau `COUNT(DISTINCT tanggal_kuartal_key, sales_person_key)`. Menghitung semua baris akan berlipat sebanyak jumlah produk.
- **Salesperson tanpa wilayah dan tanpa penjualan** (3 dari 17) muncul sebagai baris target saja di wilayah "Tidak diketahui" dengan kategori TARGET_SAJA dan pencapaian 0%. Ini menurunkan persentase total dan wilayah "Tidak diketahui". Putuskan dengan sponsor apakah mereka dihitung.
- **Catatan pengujian SCD Tipe 2:** Karena `UNIQUE KEY (business_entity_id, row_effective_date)` aktif di `dim_sales_person`, perubahan atribut Tipe 2 pada `business_entity_id` yang sama akan menghasilkan versi baru pada tanggal kalender (`CURDATE()`) yang berbeda dari `row_effective_date` baris aktif sebelumnya.

---

## 5. Bukti Pengujian Eksekusi ETL (Spoon & Idempotensi)

Pengujian eksekusi *pipeline* data warehouse dilakukan menggunakan Pentaho Data Integration (Spoon) dengan menjalankan `etl/job_utama.kjb` sebanyak dua kali berturut-turut untuk menguji kelancaran aliran data dan integritas idempotensi skema.

### 5.1. Bukti Eksekusi ETL Pertama (Run 1)
Pada eksekusi awal, job menjalankan pembuatan staging, ekstraksi data sumber mentah, pembersihan tabel target, pengisian seluruh dimensi (`dim_wilayah`, `dim_produk`, `dim_sales_person` SCD Tipe 2, `dim_kategori_kinerja`), dan pemuatan fakta `fact_kinerja_sales_v2`.

* **Alur Eksekusi:** `START` → `SQL buat staging (jika belum ada)` → `t01 ekstrak sumber ke staging` → `SQL kosongkan fakta dan dimensi` → `t02 dim_wilayah` → `t03 dim_produk` → `t04 dim_sales_person` → `t05 dim_kategori_kinerja` → `t10 fakta kinerja sales` → `Success`.
* **Metrik Proses:**
  * Pembacaan data fakta staging: 16.888 baris (`I=16888, R=16888, W=16888`).
  * Lookup dimensi: `dim_sales_person` (16.888 baris), `dim_wilayah` (10 baris), `dim_produk` (251 baris), `dim_kategori_kinerja` (4 baris).
  * Output tabel fakta `fact_kinerja_sales_v2`: 16.888 baris dimuat dengan sempurna (`E=0`).
  * Status Akhir: `job_utama - Job execution finished` (Errors: 0, Result: True).

![Bukti Uji Eksekusi ETL Pentaho (Run 1)](<Bukti Gamber/uji_ETL 1.jpeg>)

*Gambar 5.1: Tangkapan layar status sukses eksekusi job_utama.kjb pada Spoon (Run 1).*

---

### 5.2. Bukti Uji Idempotensi / Eksekusi Ulang (Run 2)
Uji idempotensi dilakukan dengan mengeksekusi ulang `job_utama.kjb` secara langsung tanpa intervensi manual. Uji ini membuktikan bahwa strategi `SQL kosongkan fakta dan dimensi` serta penanganan SCD Tipe 2 bekerja dengan benar, sehingga proses reload tidak menimbulkan error *duplicate primary key* atau kegagalan constraint database.

* **Hasil Pengujian Ulang:**
  * Seluruh job entry kembali berstatus sukses bertanda centang hijau.
  * Log eksekusi menunjukkan pemrosesan kembali 16.888 baris fakta (`I=16888, W=16888, E=0`) secara konsisten.
  * Status Akhir: `job_utama - Finished job entry [Success] (result=[true])`, `Spoon - Job has ended` tanpa ada pesan error.

![Bukti Uji Idempotensi ETL Pentaho (Run 2)](<Bukti Gamber/Uji_ETL 2.jpeg>)

*Gambar 5.2: Tangkapan layar bukti uji idempotensi eksekusi kedua job_utama.kjb pada Spoon (Run 2).*

