# MANAJEMEN RISIKO AWAL (INITIAL RISK ASSESSMENT)

## Identifikasi dan Mitigasi Risiko Proyek
Untuk menjamin kelancaran pelaksanaan proyek hingga Pekan 16, Kelompok 4 telah menyusun register risiko awal yang mencakup aspek teknis, data, dan operasional tim:

| Identifikasi Risiko | Potensi Dampak Negatif | Prob. | Dampak | Rencana Tindakan Mitigasi |
|:---|:---|:---:|:---:|:---|
| **Pergeseran waktu kolom TIMESTAMP (-5:30)** | 244 pesanan reseller masuk ke kuartal yang keliru, menyebabkan angka realisasi tidak akurat. | **Tinggi** | **Tinggi** | Menerapkan formula `DATE_ADD(orderdate, INTERVAL 330 MINUTE)` pada seluruh kueri ekstraksi ETL Pentaho dan mencatatnya di kamus data. |
| **Realisasi 2014 Q2 tanpa target kuota (16 baris)** | Kalkulasi persentase pencapaian menghasilkan error pembagian nol atau angka yang menyesatkan. | **Tinggi** | **Sedang** | Menyimpan `target_penjualan` bernilai `NULL` (bukan 0), menyediakan penanda `ada_target`, dan menyaring 2014 Q2 pada formula persentase cube. |
| **Data NULL pada wilayah sales person (3 manajer)** | Proses JOIN ke dimensi wilayah gagal dan menghilangkan 26 baris fakta dari data warehouse. | **Tinggi** | **Tinggi** | Membuat baris default *'Tidak Diketahui'* (`wilayah_key = 0` / `-1`) pada `dim_wilayah` dan menyaringnya pada evaluasi kinerja wilayah regional. |
| **Nilai target kuota ekstrem kecil (Outlier)** | Grafik peringkat pencapaian terdistorsi ekstrem oleh manajer bertarget Rp 1.000 (pencapaian ribuan %). | **Sedang** | **Sedang** | Mempertahankan nilai asli pada data warehouse namun menyediakan kontrol filter *'Saring Pencilan'* pada dashboard visualisasi. |
| **Ketidaksesuaian DBMS sumber (MariaDB vs Postgres)** | Skrip materi kelas berbasis PostgreSQL mengalami ketidakcocokan sintaks fungsi SQL. | **Rendah** | **Sedang** | Menyesuaikan seluruh kueri ke dialek MariaDB/MySQL, mendokumentasikan sintaks ekuivalen, dan meminta persetujuan resmi sponsor. |
| **Ketidakseimbangan kontribusi anggota tim** | Beban kerja menumpuk pada individu tertentu dan menghambat jadwal mingguan. | **Rendah** | **Tinggi** | Menetapkan pembagian peran spesifik (RACI), memantau kontribusi melalui riwayat commit Git, dan evaluasi berkala di *Steering Review*. |

---

## Kategorisasi Matriks Risiko Proyek

Berdasarkan analisis tingkat probabilitas dan dampaknya, risiko proyek dikelompokkan ke dalam tiga kategori utama:

### 1. Risiko Kualitas & Integritas Data (Data Quality Risks)
* **Koreksi Zona Waktu:** Adanya offset 5 jam 30 menit pada kolom `TIMESTAMP` sumber operasional berpotensi menggeser agregasi tanggal pesanan ke batas kuartal yang salah. Mitigasi dilakukan di hulu ETL dengan penyesuaian interval 330 menit.
* **Granularitas Target Parsial (2014 Q2):** Ketiadaan target kuota pada kuartal penutup ditangani dengan penetapan nilai `NULL` dan flag penanda agar metrik turunan di lapisan OLAP cube tidak menghasilkan anomali pembagian nol (*divide-by-zero*).
* **Missing Territory:** Ketidakberadaan wilayah pada manajer ditangani menggunakan konsep *Default Unknown Record* agar baris fakta tidak hilang saat proses lookup/join.

### 2. Risiko Analitik & Visualisasi (Analytics & Presentation Risks)
* **Distorsi Pencilan (*Outlier*):** Manajer dengan kuota kecil menghasilkan persentase pencapaian ribuan persen. Integritas data di level storage tetap dijaga dengan mempertahankan nilai asli, sementara kontrol visualisasi disediakan pada dashboard melalui saklar filter *outlier*.

### 3. Risiko Teknis & Manajemen Tim (Technical & Operational Risks)
* **Kompatibilitas Dialek RDBMS:** Standarisasi penuh dialek SQL ke MariaDB/MySQL pada seluruh skrip DDL, transformasi ETL, dan fungsi tanggal.
* **Tata Kelola Tim:** Menerapkan pembagian tugas terstruktur (Project Manager, Data Modeler, ETL Developer, OLAP Developer, Dashboard Developer) dengan pemantauan berbasis commit Git mingguan.
