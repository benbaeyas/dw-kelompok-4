# Kamus Data: Data Warehouse Kinerja Sales vs Target

**Kelompok:** 4 | **Database DW:** `dw_kelompok_4` (MySQL) | **Skrip:** `sql/ddl.sql`
**Versi `dim_tanggal`:** skrip standar kelas dari sponsor (`dim_tanggal_mysql.sql`), versi 1.0, 2192 baris (2010-01-01 sampai 2015-12-31, ditambah baris -1)
**Star schema:** v2 | **Grain fakta:** satu baris per salesperson per kuartal per wilayah per produk

Cara membaca: kolom **Key** berisi PK (primary key), FK (foreign key), UK (unique key), atau NK (natural key dari sumber). Setiap dimensi punya baris **-1 "Tidak diketahui"** agar key yang tidak ditemukan tidak membuat ETL gagal dan tidak menghilangkan baris fakta.

---

## 1. dim_tanggal (SCD tipe 0, dipasang dari skrip standar, tidak dibuat tim)

Dimensi tanggal harian. Tabel ini tidak boleh diubah. Atribut tambahan (misalnya hari libur) dibuat di tabel terpisah yang menunjuk ke `tanggal_key`.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| tanggal_key | INT | PK | Kunci tanggal berformat YYYYMMDD | 20130315 | Format ini dipilih karena bisa dihitung langsung dari tanggal transaksi tanpa join, terbaca oleh manusia, dan urutan angkanya sama dengan urutan waktu. Angka urut 1, 2, 3 tidak punya kelebihan itu dan nilainya bergantung pada kapan tabel diisi. Baris -1 = tidak diketahui |
| tanggal | DATE | UK | Tanggal kalender | 2013-03-15 | Baris -1 memakai 1900-01-01: kolom ini NOT NULL sehingga butuh tanggal sungguhan, dan tahun 1900 jelas palsu serta jauh di luar data AdventureWorks (2011-2014) |
| tahun | INT |  | Tahun kalender | 2013 | Bernilai 0 pada baris -1. Untuk analisis tahunan pakai kolom ini, bukan `minggu_dalam_tahun` |
| semester | INT |  | 1 untuk Januari sampai Juni, 2 untuk Juli sampai Desember | 1 | 0 pada baris -1 |
| kuartal | INT |  | Kuartal kalender 1 sampai 4 (Januari-Maret = 1) | 1 | Bukan kuartal fiskal. Fakta kita menunjuk ke tanggal pertama tiap kuartal |
| bulan | INT |  | Nomor bulan 1 sampai 12 | 3 | |
| nama_bulan | VARCHAR(15) |  | Nama bulan | Maret | Bahasa Indonesia (Januari sampai Desember), diisi dengan `ELT()` di skrip standar |
| minggu_dalam_tahun | INT |  | Nomor minggu menurut standar ISO 8601 | 11 | 1 Januari bisa masuk minggu 52 atau 53 tahun sebelumnya. Untuk analisis tahunan pakai kolom `tahun` |
| tanggal_dalam_bulan | INT |  | Tanggal 1 sampai 31 | 15 | |
| hari_dalam_minggu | INT |  | Nomor hari dalam minggu, Senin = 1 sampai Minggu = 7 | 5 | Senin dipilih sebagai hari pertama karena itu aturan ISO 8601, sama dengan `minggu_dalam_tahun`. Fungsi `DAYOFWEEK()` bawaan MySQL memulai dari Minggu, jangan dipakai untuk mengisi atau membandingkan kolom ini. Verifikasi: tanggal 20130315 harus Jumat |
| nama_hari | VARCHAR(15) |  | Nama hari, Senin sampai Minggu | Jumat | Bahasa Indonesia, diisi dengan `ELT(WEEKDAY(d)+1, ...)` |
| is_akhir_pekan | TINYINT(1) |  | 1 bila Sabtu atau Minggu, selain itu 0 | 0 | |

---

## 2. dim_wilayah (SCD tipe 1)

Wilayah penjualan AdventureWorks beserta negara dan grupnya.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| wilayah_key | INT | PK | Surrogate key buatan DW (AUTO_INCREMENT) | 4 | -1 untuk "Tidak diketahui". Dipakai untuk 3 dari 17 salesperson yang tidak punya `TerritoryID` |
| territory_id | INT | NK, UK | ID wilayah di sumber (`sales_salesterritory.TerritoryID`) | 4 | NULL hanya pada baris -1. MySQL mengizinkan banyak NULL pada kolom UNIQUE |
| nama_wilayah | VARCHAR(50) |  | Nama wilayah | Southwest | |
| kode_negara | VARCHAR(3) |  | Kode negara ISO | US | Baris -1 memakai `N/A` |
| nama_negara | VARCHAR(50) |  | Nama negara | United States | Diambil dari `person_countryregion` |
| grup_wilayah | VARCHAR(50) |  | Kelompok besar wilayah | North America | Nilai: North America, Europe, Pacific |
| is_active | TINYINT(1) |  | 1 bila wilayah masih dipakai | 1 | Sumber tidak punya kolom ini. Aturan: 1 bila ada salesperson yang bertugas di wilayah itu. Tim perlu menyepakati aturan ini. Tipe 1: ditimpa saat berubah |

---

## 3. dim_produk (SCD tipe 1, struktur standar)

Katalog produk beserta kategorinya. Dipakai sebagai dimensi tambahan di fakta.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| produk_key | INT | PK | Surrogate key buatan DW | 12 | -1 = tidak diketahui. **-2 = "Tanpa Produk (baris target)"**, dipakai bila target ditaruh di baris sendiri (lihat CR-01) |
| product_id | INT | NK, UK | ID produk di sumber (`production_product.ProductID`) | 749 | Karena Tipe 1, satu produk satu baris, sehingga aman diberi UNIQUE |
| nama_produk | VARCHAR(50) |  | Nama produk | Road-150 Red, 62 | Tipe khusus `Name` di sumber diganti VARCHAR dengan panjang yang sama |
| nomor_produk | VARCHAR(25) |  | Kode produk | BK-R93R-62 | |
| sub_kategori | VARCHAR(50) |  | Subkategori produk | Road Bikes | NOT NULL. Produk tanpa subkategori diisi `Tanpa Sub Kategori` oleh ETL |
| kategori | VARCHAR(50) |  | Kategori produk | Bikes | NOT NULL. Produk tanpa kategori diisi `Tanpa Kategori` oleh ETL |
| list_price | DECIMAL(14,4) |  | Harga jual standar | 3578.2700 | DECIMAL, bukan FLOAT, agar penjumlahan tidak menghasilkan selisih pecahan biner dan rekonsiliasi cocok |

---

## 4. dim_sales_person (SCD tipe 2)

Salesperson AdventureWorks. Perubahan `jabatan`, `komisi_pct`, atau `bonus` membuat baris versi baru supaya kinerja masa lalu dibaca dengan kondisi saat itu.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| sales_person_key | INT | PK | Surrogate key, unik per versi | 7 | Satu salesperson bisa punya beberapa key (satu per versi). Itu sebabnya `business_entity_id` tidak bisa menjadi primary key. -1 = tidak diketahui |
| business_entity_id | INT | NK, UK bersama row_effective_date | ID salesperson di sumber (`sales_salesperson.BusinessEntityID`) | 275 | Tidak unik sendiri karena ada versi |
| nama_lengkap | VARCHAR(150) |  | Nama depan, tengah, dan belakang digabung | Michael G Blythe | Berasal dari `person_person`, bukan dari tabel salesperson. Tipe 1 (ditimpa bila dikoreksi) |
| jabatan | VARCHAR(100) |  | Jabatan | Sales Representative | Tipe 2: pemicu versi baru |
| tanggal_masuk | DATE |  | Tanggal mulai bekerja | 2011-05-31 | Tidak berubah |
| komisi_pct | DECIMAL(5,4) |  | Persentase komisi sebagai pecahan | 0.0150 | 0.0150 berarti 1,5%. Tipe 2: pemicu versi baru. Di sumber hanya ada nilai terkini, sehingga komisi di dashboard berupa estimasi |
| bonus | DECIMAL(14,4) |  | Bonus tahunan | 4100.0000 | Tipe 2: pemicu versi baru |
| row_effective_date | DATE |  | Tanggal versi ini mulai berlaku | 1900-01-01 | Versi pertama memakai 1900-01-01 agar fakta tahun 2011 menemukan barisnya. Bila memakai tanggal ETL, fakta lama jatuh ke baris -1 |
| row_expiry_date | DATE |  | Tanggal terakhir versi ini berlaku (inklusif) | 9999-12-31 | 9999-12-31 berarti versi aktif. Versi lama ditutup dengan tanggal versi baru dikurangi satu hari. Ada CHECK: tidak boleh lebih kecil dari `row_effective_date` |

---

## 5. dim_kategori_kinerja (SCD tipe 1, tabel referensi diisi manual)

Klasifikasi hasil salesperson terhadap targetnya pada satu kuartal.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| kategori_kinerja_key | INT | PK | Surrogate key | 1 | -1 = tidak diketahui. Nilai 1 sampai 4 diisi manual |
| kode_kategori | VARCHAR(20) | UK | Kode singkat untuk lookup di ETL | TERCAPAI | Dibuat VARCHAR(20) karena `BELUM_TERCAPAI` (14 huruf) dan `TANPA_TARGET` (12 huruf) tidak muat di VARCHAR(10) |
| nama_kategori | VARCHAR(50) |  | Label untuk cube dan dashboard | Tercapai | |
| keterangan_rentang | VARCHAR(100) |  | Aturan penentuan kategori | Realisasi >= Target (>= 100%) | |

Isi tabel:

| Key | Kode | Nama | Aturan |
|---|---|---|---|
| -1 | UNKNOWN | Tidak diketahui | Tidak dapat ditentukan |
| 1 | TERCAPAI | Tercapai | Realisasi >= Target |
| 2 | BELUM_TERCAPAI | Belum Tercapai | Realisasi < Target |
| 3 | TANPA_TARGET | Tanpa Target | Realisasi ada, target tidak ada (Q2 2014) |
| 4 | TARGET_SAJA | Target Tanpa Realisasi | Target ada, realisasi 0 |

---

## 6. fact_kinerja_sales_v2

**Grain:** satu baris per salesperson per kuartal per wilayah per produk. Primary key gabungan dari empat key di bawah melindungi dari ETL yang dijalankan dua kali.

| Kolom | Tipe | Key | Arti | Contoh | Catatan |
|---|---|---|---|---|---|
| tanggal_kuartal_key | INT | PK, FK ke dim_tanggal | Tanggal pertama kuartal kalender, format YYYYMMDD | 20130401 | Bukan tanggal pesanan. Pesanan dikelompokkan ke kuartalnya setelah koreksi geseran jam sumber |
| sales_person_key | INT | PK, FK ke dim_sales_person | Versi salesperson yang berlaku pada kuartal itu | 7 | Dicari lewat `row_effective_date <= tanggal kuartal <= row_expiry_date` |
| wilayah_key | INT | PK, FK ke dim_wilayah | Wilayah penugasan salesperson pada kuartal itu | 4 | -1 bila salesperson tidak punya wilayah |
| produk_key | INT | PK, FK ke dim_produk | Produk yang terjual | 12 | -1 produk tidak ditemukan, -2 baris yang membawa target tanpa produk |
| target_penjualan | DECIMAL(14,4) |  | Kuota penjualan kuartalan | 250000.0000 | **NULL** bila tidak ada kuota (2014 Q2). NULL berarti tidak ada target, berbeda dengan target 0. Ukuran aditif, tetapi lihat CR-01 agar tidak terhitung berulang di baris produk |
| realisasi_penjualan | DECIMAL(14,4) |  | Jumlah `LineTotal` pesanan reseller ber-salesperson | 183500.5000 | 0 bila hanya ada target tanpa penjualan. Aditif penuh. Tanpa pajak dan ongkos kirim |
| selisih_realisasi_target | DECIMAL(14,4) |  | Realisasi dikurangi target | -66499.5000 | NULL bila target NULL. Negatif berarti di bawah target. Ada CHECK: tidak boleh terisi bila target NULL |
| jumlah_terjual | INT |  | Jumlah unit (`OrderQty`) | 42 | 0 pada baris yang hanya membawa target. Ada CHECK: tidak boleh negatif |
| kategori_kinerja_key | INT | FK ke dim_kategori_kinerja | Hasil klasifikasi kinerja | 2 | NOT NULL. Pakai -1 bila tidak dapat ditentukan |

**Constraint di fakta:** PRIMARY KEY (4 key), 5 FOREIGN KEY, 4 CHECK (`jumlah_terjual >= 0`, `realisasi_penjualan >= 0`, `target_penjualan` NULL atau >= 0, `selisih` NULL bila target NULL). **Index:** satu index di tiap foreign key selain `tanggal_kuartal_key` (sudah ditutup oleh primary key yang diawali kolom itu). Ukuran tidak diberi index karena tidak dipakai untuk join atau pencarian.

---

## 7. Hal yang sengaja tidak dibawa dari sumber

| Kolom sumber | Alasan |
|---|---|
| `modifieddate` di semua tabel | Dipakai untuk ETL inkremental. ETL proyek ini berjalan penuh, jadi cukup ada di staging |
| `person.demographics` | Nilai tambah, bukan kebutuhan pertanyaan bisnis |
| Jam pada `orderdate` | Grain harian. Jam hanya dipakai untuk koreksi geseran waktu di ETL |
| `onlineorderflag` | Di luar lingkup: hanya pesanan reseller yang punya salesperson |
