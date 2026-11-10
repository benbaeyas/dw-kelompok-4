# Project Charter (Piagam Proyek)

## Informasi Proyek

| Atribut | Keterangan |
| :--- | :--- |
| **Tanggal** | - |
| **No. Proyek** | - |
| **Nama Proyek** | Perancangan Data Warehouse Evaluasi Kinerja Penjualan dan Pencapaian Target Adventure Works |
| **Pimpinan Proyek** | Project Manager (Andreas Benaya) |
| **Klien** | Project Sponsor (Mohamad Irwan Afandi, ST, M.Sc.) |

---

## Pendahuluan

Manajemen penjualan Adventure Works menetapkan target penjualan tiap sales person per kuartal, tetapi target dan realisasinya tersimpan di tabel yang terpisah dan ternormalisasi (target di `salespersonquotahistory`, realisasi di `salesorderheader`). Untuk mengetahui siapa dan wilayah mana yang mencapai target, analis harus menggabungkan banyak tabel secara manual, dan kueri analisis yang berat dapat memperlambat sistem transaksi. Proyek ini memindahkan data ke data warehouse terpisah agar pencapaian dapat dipantau dan dibandingkan antarwaktu, antarwilayah, dan antarsales person.

---

## Tahapan yang Diliputi

* **Pekan 9:** Perencanaan dan desain data warehouse
* **Pekan 10:** Desain ETL, cube, dan dashboard
* **Pekan 11:** Implementasi data warehouse di RDBMS
* **Pekan 12:** ETL dengan Pentaho
* **Pekan 13:** OLAP cube Mondrian
* **Pekan 14:** Dashboard web
* **Pekan 15:** Presentasi proyek
* **Pekan 16:** EAS

---

## Tujuan Proyek

Membangun solusi Data Warehouse terintegrasi untuk mengukur dan menganalisis kinerja pencapaian target penjualan (sales quota) oleh sales person secara berkala (kuartalan), guna mendukung pengambilan keputusan manajemen Adventure Works terkait evaluasi performa, pemberian insentif, dan alokasi strategi wilayah penjualan.

Secara spesifik, proyek ini bertujuan untuk:
* Membangun data warehouse Adventure Works khusus untuk proses bisnis Kinerja Sales vs Target
* Membandingkan realisasi penjualan dengan target secara cepat dan akurat
* Menemukan wilayah dan sales person yang tertinggal dari target
* Mengetahui estimasi beban komisi yang menyertai penjualan
* Memisahkan beban komputasi analisis dari database operasional agar sistem transaksi harian tidak terganggu

---

## Deskripsi Produk / Proyek

* **Sumber dan target data warehouse:** Mengintegrasikan database OLTP MariaDB `adventureworks2` di mana format nama tabel berbentuk `schema_tabel`, menuju target data warehouse berarsitektur star schema `dw_kelompok_X` di MariaDB/MySQL.
* **Tabel sumber OLTP:** Mengekstrak data dari delapan tabel meliputi:
  * `sales_salespersonquotahistory`
  * `sales_salesorderheader`
  * `sales_salesperson`
  * `sales_salesterritory`
  * `sales_salesterritoryhistory`
  * `person_person`
  * `humanresources_employee`
  * `person_countryregion`
* **Struktur data warehouse:** Memuat satu tabel fakta `fact_kinerja_sales` yang dikelilingi oleh tiga dimensi yaitu `dim_tanggal`, `dim_sales_person`, dan `dim_wilayah`.
* **Proses ETL dan granularitas:** Menggunakan Pentaho Data Integration (PDI) untuk ekstraksi, transformasi, dan agregasi data dengan granularitas satu baris per sales person per kuartal, mencakup tahap koreksi geseran waktu pada tanggal pesanan, penentuan wilayah dari riwayat penugasan, perhitungan selisih, dan estimasi komisi.
* **Penyajian dan visualisasi data analitik:** Disalurkan melalui skema Mondrian OLAP dengan query MDX serta dashboard web berbasis chart library untuk menjawab pertanyaan bisnis.

---

## Sasaran Proyek dan Batasan

### Sasaran Proyek
* Menghasilkan rancangan Star Schema versi final yang disetujui dan dikunci oleh Project Sponsor serta diimplementasikan ke dalam skrip DDL yang dapat dijalankan ulang dari database kosong tanpa error.
* Mengembangkan transformasi dan job utama Pentaho yang memuat minimal satu dimensi dengan Slowly Changing Dimension Tipe 2 di mana eksekusi berulang tidak menghasilkan data ganda dan mencapai selisih nol pada query rekonsiliasi.
* Menyusun file schema Mondrian yang dilengkapi dengan calculated member serta memastikan angka hasil dari minimal lima query MDX bernilai sama persis dengan hasil query SQL pembanding.
* Membangun dashboard web sesuai wireframe yang mampu menjawab minimal lima pertanyaan bisnis dan mendemonstrasikan aliran data secara utuh dari database sumber hingga visualisasi akhir pada saat presentasi proyek.

### Batasan

#### Lingkup Proses
* Hanya pesanan yang punya sales person (3.806 pesanan reseller)
* Grain sales person per kuartal
* Di luar lingkup: pesanan online, analisis produk dan pelanggan, pajak, ongkos kirim, dan peramalan

#### Data
* Rentang data 31 Mei 2011 sampai 30 Juni 2014
* Target hanya sampai 2014 Q1, sehingga 2014 Q2 punya realisasi tanpa target
* Kolom TIMESTAMP di sumber bergeser -5 jam 30 menit dan harus dikoreksi saat ETL
* Komisi di sumber hanya nilai terkini, sehingga komisi di dashboard berupa estimasi

#### Analisis
* Hasil bersifat deskriptif dan tidak membuktikan sebab-akibat

#### Teknis dan Waktu
* Database sumber tidak boleh diubah
* Alat yang dipakai: MariaDB/MySQL, Pentaho, dan Mondrian
* Perubahan desain setelah pekan 11 harus disetujui sponsor

---

## Tanggung Jawab dan Peran pada Proyek

| Peran & Personel | Tanggung Jawab |
| :--- | :--- |
| **Project Sponsor**<br>(Mohamad Irwan Afandi, ST, M.Sc.) | Menyampaikan pertanyaan bisnis yang harus dijawab. Memimpin Steering Review tiap pekan. Menyetujui atau menolak keputusan desain. Membantu jika status tim merah. |
| **Project Manager**<br>(Andreas Benaya) | Menjaga target mingguan. Menyusun dan menyampaikan laporan progres. Mencatat kendala dan keputusan. Mengatur pembagian tugas. |
| **Data Modeler**<br>(Nalendra Fadilah Saskara) | Menerjemahkan kebutuhan bisnis menjadi star schema. Menjaga kamus data. |
| **ETL Developer**<br>(Muhammad Alvian Jaya) | Membuat transformasi dan job di Pentaho. Menjaga kualitas dan rekonsiliasi data. |
| **OLAP Developer**<br>(Christian Starly) | Menyusun schema Mondrian dan query MDX yang menjawab pertanyaan bisnis. |
| **Dashboard Developer**<br>(Wahyu Pratama Andhika M.) | Merancang wireframe dan membangun dashboard web dengan chart library. |
