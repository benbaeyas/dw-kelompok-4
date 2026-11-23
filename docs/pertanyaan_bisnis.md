# PROSES BISNIS & PERTANYAAN BISNIS

## Pemilihan Proses Bisnis
Kelompok 4 secara definitif memilih proses bisnis: **Kinerja Sales vs Target**. Pemilihan ini didasarkan pada urgensi strategis manajemen Adventure Works yang memerlukan visibilitas langsung terhadap efektivitas tim penjualan. Berbeda dari proses penjualan transaksional biasa yang hanya mencatat apa yang terjual, proses ini mengevaluasi gap antara ekspektasi manajemen (kuota) dengan pencapaian aktual di lapangan.

---

## Perumusan Pertanyaan Bisnis
Mengikuti prinsip Kimball Lifecycle, perancangan data warehouse harus didorong oleh kebutuhan analitik bisnis nyata. Tim merumuskan 5 pertanyaan bisnis utama yang terukur secara kuantitatif serta 2 pertanyaan analitik tingkat lanjut:

### Perumusan Pertanyaan Bisnis (BARU)

| No | Rumusan Pertanyaan Bisnis | Fakta Terkait | Dimensi Terkait |
|:--:|:---|:---|:---|
| 1 | Bagaimana perkembangan pencapaian target penjualan dari kuartal ke kuartal, baik secara keseluruhan maupun di setiap wilayah? | Realisasi, target, selisih | Tanggal (tahun, kuartal), Wilayah (grup wilayah) |
| 2 | Wilayah mana yang paling melampaui target dan wilayah mana yang paling tertinggal dari target pada setiap tahun, serta bagaimana kinerja tiap salesperson di dalamnya? | Realisasi, target, selisih | Wilayah (grup wilayah, negara, wilayah), Salesperson, Tanggal (tahun) |
| 3 | Siapa salesperson dengan persentase pencapaian tertinggi, siapa yang berada di bawah target dan seberapa jauh, serta berapa kuartal masing-masing berhasil mencapai target? | Realisasi, target, selisih | Salesperson, Kategori Kinerja, Tanggal |
| 4 | Apakah salesperson dengan unit terjual terbanyak selalu menghasilkan realisasi tertinggi, dan berapa rata-rata realisasi per unit untuk tiap salesperson? | Jumlah terjual, realisasi | Sales Person, Wilayah, Tanggal |
| 5 | Kelompok salesperson dengan tingkat komisi mana yang paling sering mencapai target dan memiliki rata-rata selisih terbaik? | Selisih, kategori kinerja | Salesperson (komisi, bonus), Kategori Kinerja, Tanggal |

### Perumusan Pertanyaan Bisnis (LAMA)

| No | Rumusan Pertanyaan Bisnis | Fakta Terkait | Dimensi Terkait |
|:--:|:---|:---|:---|
| 1 | Bagaimana tren pencapaian target penjualan dari kuartal ke kuartal, secara keseluruhan dan per wilayah? | Realisasi, target | Tanggal, Wilayah |
| 2 | Wilayah mana yang kinerjanya paling baik atau paling tertinggal terhadap target, dan bagaimana kinerja tiap sales person di dalamnya? | Realisasi, target, selisih | Wilayah (grup, negara), Sales Person, Tanggal |
| 3 | Siapa sales person dengan persentase pencapaian tertinggi, siapa yang di bawah target dan seberapa jauh, serta berapa kuartal mereka mencapai target? | Realisasi, target, selisih | Sales Person, Tanggal, Wilayah |
| 4 | Apakah sales person dengan pesanan terbanyak selalu menghasilkan realisasi tertinggi, dan berapa nilai rata-rata per pesanannya? | Jumlah pesanan, realisasi | Sales Person, Wilayah, Tanggal |
| 5 | Apakah semakin tinggi komisi (%) sales person berhubungan dengan target dan realisasinya? | Realisasi, target | Sales Person (atribut komisi), Tanggal |

---

## Spesifikasi Parameter Dashboard & Nilai Awal
Agar dashboard analitik bersifat dinamis dan interaktif bagi para eksekutif, pertanyaan bisnis dilengkapi dengan parameter pengguna dan nilai default awal:

| No | Pertanyaan Terkait | Parameter yang Dapat Diatur Pengguna | Nilai Awal (Default) |
|:--:|:---|:---|:---|
| 1 | Pertanyaan 1 (Tren Pencapaian per Kuartal) | Rentang periode (tahun atau kuartal); tampilan keseluruhan atau per grup wilayah; saring/sembunyikan wilayah “Tidak diketahui”. | Seluruh kuartal bertarget (2011 Q2 s.d. 2014 Q1); tampilan keseluruhan; wilayah “Tidak diketahui” disaring. |
| 2 | Pertanyaan 2 (Wilayah Terbaik dan Tertinggal) | Filter rentang tahun; tingkat rincian (grup wilayah, negara, wilayah, salesperson); saring/sembunyikan wilayah “Tidak diketahui”. | Seluruh tahun; tingkat wilayah; “Tidak diketahui” disaring. |
| 3 | Pertanyaan 3 (Pencapaian Salesperson) | Jumlah peringkat (Top N: 3, 5, 10); ambang batas pencapaian target (%); periode kuartal evaluasi; penanda pencilan (outlier). | 3 teratas; ambang 80%; kuartal terakhir bertarget lengkap (2014 Q1); penanda pencilan aktif. |
| 4 | Pertanyaan 4 (Unit Terjual vs Realisasi) | Jumlah peringkat (Top N); periode waktu; filter wilayah. | 5 teratas; seluruh periode; semua wilayah. |
| 5 | Pertanyaan 5 (Kelompok Komisi) | Rentang periode; kategori kinerja yang dihitung; urutan peringkat (jumlah kuartal tercapai atau rata-rata selisih). | Seluruh kuartal bertarget; kategori “Tercapai”; diurutkan menurut jumlah kuartal tercapai. |

---

## Definisi Operasional Metrik & Aturan Agregasi
Untuk menjamin konsistensi laporan analitik, seluruh metrik didefinisikan dengan formula matematis yang tegas:
* **Realisasi Penjualan:** `SUM(LineTotal)` dari rincian pesanan reseller yang ditangani salesperson (`salespersonid IS NOT NULL`), dikelompokkan per salesperson, produk, dan kuartal berdasarkan tanggal pesanan yang telah dikoreksi zona waktunya (+5 jam 30 menit). Total per pesanan setara dengan `SubTotal`.
* **Target Penjualan:** `SalesQuota` dari tabel `sales_salespersonquotahistory` sesuai kuartal tanggal penetapan. Target disimpan satu kali per salesperson per kuartal (pada baris “Tanpa Produk”), sehingga aman dijumlahkan lintas produk.
* **Selisih Realisasi-Target:** Realisasi Penjualan − Target Penjualan. Bernilai NULL apabila target tidak tersedia.
* **Jumlah Unit Terjual:** `SUM(OrderQty)` pada rincian pesanan reseller ber-salesperson dalam kuartal bersangkutan.
* **Realisasi Rata-rata per Unit:** `SUM(Realisasi Penjualan) ÷ SUM(Jumlah Unit Terjual)`. Bernilai 0 apabila tidak ada unit terjual.
* **Persentase Pencapaian:** `(SUM(Realisasi Penjualan) ÷ SUM(Target Penjualan)) × 100%`. Metrik ini bersifat non-aditif dan dihitung secara *on-the-fly* pada OLAP cube. Pada evaluasi tahunan atau per wilayah, realisasi dan target dijumlahkan terlebih dahulu sebelum dibagi (rasio agregat), bukan merata-ratakan persentase antar-kuartal.
* **Kategori Kinerja:** ditetapkan per salesperson per kuartal, yaitu Tercapai (pencapaian ≥ 100%), Belum Tercapai (< 100%), Tanpa Target (realisasi ada, target tidak ada), dan Target Tanpa Realisasi (target ada, realisasi nol).
* **Jumlah Kuartal Tercapai:** `COUNT(DISTINCT kuartal)` dengan kategori “Tercapai” per salesperson atau per kelompok komisi. Dihitung sebagai kuartal yang berbeda, bukan jumlah baris fakta, karena satu kuartal memiliki banyak baris fakta (satu per produk).
* **Rata-rata Selisih per Kuartal:** `SUM(Selisih Realisasi) ÷ COUNT(DISTINCT kuartal)` pada kelompok komisi yang dianalisis.
* **Pengecualian Kuartal Parsial:** Kuartal tanpa target (2014 Q2) secara otomatis dikecualikan dari perhitungan persentase pencapaian dan selisih agar tidak menimbulkan pembagian dengan nol atau angka bias. Realisasinya tetap ditampilkan sebagai transaksi murni.

---

## Verifikasi & Pengujian Kelayakan Pertanyaan terhadap Data Sumber
Kelompok 4 telah menguji kelima pertanyaan bisnis langsung terhadap data sumber operasional untuk memastikan bahwa model data yang dirancang mampu menjawab seluruh kebutuhan tanpa kekurangan atribut:

| No | Pertanyaan Bisnis | Hasil Uji Kelayakan & Temuan Analitik |
|:--:|:---|:---|
| 1 | Perkembangan pencapaian target per kuartal, keseluruhan dan per wilayah | **DAPAT DIJAWAB.** Tren dapat disajikan berkesinambungan dari 2011 Q2 hingga 2014 Q1 (12 kuartal kalender berturut-turut). Kuartal 2014 Q2 hanya menyajikan tren transaksi murni tanpa target. |
| 2 | Wilayah terbaik dan tertinggal per tahun, serta kinerja salesperson di dalamnya | **DAPAT DIJAWAB.** Wilayah berkinerja rendah dapat dipetakan hingga tingkat salesperson. Baris fakta dengan wilayah “Tidak diketahui” (milik manajer; tercatat 26 baris pada uji awal) wajib disaring agar tidak mendistorsi perbandingan antarwilayah. (Hitung ulang jumlah baris setelah ETL.) |
| 3 | Salesperson dengan persentase pencapaian tertinggi, yang di bawah target, dan jumlah kuartal tercapai | **DAPAT DIJAWAB.** Posisi puncak didominasi manajer berkuota sangat kecil. Contoh: pada 2014 Q1, salesperson 287 mencapai 5.664% (peringkat kedua hanya 92%), dan pada 2013 Q4, salesperson 285 mencapai 521%, sehingga diperlukan penanda pencilan (outlier). Pada kuartal terakhir bertarget lengkap (2014 Q1), 9 dari 17 salesperson berada di bawah ambang 80%: 274, 275, 277, 278, 281, 282, 285, 288, dan 289. |
| 4 | Unit terjual vs realisasi, dan rata-rata realisasi per unit | **DAPAT DIJAWAB.** Kolom `jumlah_terjual` dan `realisasi_penjualan` tersedia pada fakta; rata-rata per unit dihitung di cube. (Isi temuan: apakah salesperson dengan unit terbanyak juga berrealisasi tertinggi, dari hasil uji.) |
| 5 | Kelompok komisi yang paling sering mencapai target dan rata-rata selisih terbaik | **DAPAT DIJAWAB.** Atribut `komisi_pct` dan `bonus` tersedia pada `dim_sales_person`. Nilai komisi di sumber hanya kondisi terkini, sehingga hasil bersifat estimasi. (Isi temuan: kelompok komisi teratas, dari hasil uji.) |
