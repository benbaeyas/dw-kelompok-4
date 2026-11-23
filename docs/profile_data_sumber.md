# PROFILING DATA SUMBER & ANALISIS KUALITAS DATA

## Gambaran Umum Database Sumber (`adventureworks2`)
Database sumber yang digunakan adalah porting resmi Adventure Works untuk MariaDB/MySQL dengan nama database `adventureworks2`. Struktur database memisahkan skema dan nama tabel menggunakan garis bawah (misal: `sales_salesorderheader`). Seluruh tabel operasional diperlakukan secara ketat sebagai **Read-Only**; tidak ada modifikasi apa pun yang dilakukan terhadap database sumber.

---

## Profil Ringkasan Tabel Sumber
Pemeriksaan awal dilakukan terhadap seluruh tabel yang beririsan langsung dengan proses bisnis **Kinerja Sales vs Target**:

| Nama Tabel Sumber | Jumlah Baris | Fungsi dalam Model Data Warehouse |
|:---|:---:|:---|
| `sales_salesorderheader` | 31.465 | Faktur pesanan penjualan (header), sumber realisasi penjualan. |
| `sales_salesorderdetail` | 121.317 | Baris detail barang pesanan (verifikasi integritas pesanan). |
| `sales_salespersonquotahistory` | 163 | Riwayat kuota target penjualan per kuartal per sales person. |
| `sales_salesperson` | 17 | Profil staf penjualan, komisi (`CommissionPct`), dan wilayah saat ini. |
| `sales_salesterritory` | 10 | Master wilayah pemasaran dan grup teritori kawasan penjualan. |
| `sales_salesterritoryhistory` | 17 | Riwayat penugasan wilayah kerja staf penjualan antar-waktu. |
| `person_person` | 19.972 | Master data identitas manusia (nama lengkap staf penjualan). |

---

## Hasil Eksekusi Kueri Data Profiling (Q1 s.d. Q12)
Kelompok 4 menyusun dan mengeksekusi 12 kueri profiling data terstruktur pada database `adventureworks2` untuk menggali karakteristik data secara menyeluruh:

### Q1. Penghitungan Jumlah Baris Seluruh Tabel Terkait
```sql
SELECT 'sales_salesorderheader' AS tabel, COUNT(*) AS jumlah_baris FROM sales_salesorderheader
UNION ALL SELECT 'sales_salesorderdetail',        COUNT(*) FROM sales_salesorderdetail
UNION ALL SELECT 'sales_salespersonquotahistory', COUNT(*) FROM sales_salespersonquotahistory
UNION ALL SELECT 'sales_salesperson',             COUNT(*) FROM sales_salesperson
UNION ALL SELECT 'sales_salesterritory',          COUNT(*) FROM sales_salesterritory
UNION ALL SELECT 'sales_salesterritoryhistory',   COUNT(*) FROM sales_salesterritoryhistory
UNION ALL SELECT 'person_person',                 COUNT(*) FROM person_person;
```
* **Analisis Hasil:** Kueri berhasil mengonfirmasi volume total data sumber yang utuh, di mana tabel target memiliki 163 baris dan tabel pesanan memiliki 31.465 baris.

---

### Q2. Segmentasi Pesanan Reseller vs Online dan Rentang Tanggal
```sql
SELECT onlineorderflag, COUNT(*) AS jumlah_pesanan,
       MIN(DATE(DATE_ADD(orderdate, INTERVAL 330 MINUTE))) AS awal,
       MAX(DATE(DATE_ADD(orderdate, INTERVAL 330 MINUTE))) AS akhir
FROM sales_salesorderheader
GROUP BY onlineorderflag;
```
* **Analisis Hasil:** Ditemukan segregasi tegas pada sistem transaksi Adventure Works:
  * **Online (B2C):** Pesanan Online B2C (`onlineorderflag = 1`): 27.659 pesanan, rentang 31 Mei 2011 s/d 30 Juni 2014.
  * **Reseller (B2B):** Pesanan Reseller B2B (`onlineorderflag = 0`): 3.806 pesanan, rentang 31 Mei 2011 s/d 01 Mei 2014.
  * *Hanya pesanan Reseller yang memiliki sales person penanggung jawab dan masuk ke dalam lingkup analisis.*

---

### Q3. Pesanan Tanpa Sales Person (Pengecekan Nilai NULL)
```sql
SELECT onlineorderflag, COUNT(*) AS tanpa_salesperson
FROM sales_salesorderheader
WHERE salespersonid IS NULL
GROUP BY onlineorderflag;
```
* **Analisis Hasil:** Sebanyak 27.659 pesanan online bernilai NULL pada `salespersonid`. Pada pesanan reseller (flag 0), jumlah `salespersonid` yang NULL tepat bernilai 0 (nol). Seluruh 3.806 pesanan reseller dapat dipetakan secara sempurna ke staf penjualan.

---

### Q4. Distribusi Baris Detail Nota Pesanan
```sql
SELECT COUNT(*) AS detail_total,
       SUM(h.salespersonid IS NOT NULL) AS detail_ber_salesperson
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.salesorderid = d.salesorderid;
```
* **Analisis Hasil:** Dari 121.317 baris detail penjualan, sebanyak 60.398 baris berasal dari transaksi pesanan reseller yang ditangani oleh staf penjualan.

---

### Q5. Profil Karakteristik Tabel Target Penjualan (`sales_salespersonquotahistory`)
```sql
SELECT COUNT(*) AS jumlah_baris,
       COUNT(DISTINCT businessentityid) AS jumlah_salesperson,
       MIN(quotadate) AS awal, MAX(quotadate) AS akhir,
       SUM(salesquota IS NULL) AS quota_null,
       MIN(salesquota) AS quota_min, MAX(salesquota) AS quota_max,
       SUM(salesquota) AS total_target
FROM sales_salespersonquotahistory;
```
* **Analisis Hasil:**
  * **Volume:** Jumlah baris target: 163 baris untuk 17 sales person berbeda.
  * **Rentang:** Rentang tanggal penetapan target: 31 Mei 2011 s/d 01 Maret 2014.
  * **Kelengkapan:** Nilai NULL pada kolom `SalesQuota`: 0 (seluruh baris memiliki nilai target valid).
  * **Distribusi:** Rentang nilai kuota: Minimum 1.000,00 hingga Maksimum 1.860.000,00.
  * **Total Kontrol:** Total akumulasi target perusahaan: Rp 95.714.000,0000.

---

### Q6 & Q7. Verifikasi Keunikan Grain Kuota Target per Kuartal
```sql
-- Q7. Pengecekan Duplikat pada Grain Kuota (Wajib Kosong / 0 Baris)
SELECT businessentityid, YEAR(quotadate) AS tahun, QUARTER(quotadate) AS kuartal, COUNT(*) AS n
FROM sales_salespersonquotahistory
GROUP BY 1, 2, 3 HAVING COUNT(*) > 1;
```
* **Analisis Hasil:** Kueri Q7 menghasilkan **TEPAT 0 BARIS (himpunan kosong)**. Hal ini membuktikan secara matematis bahwa tidak ada duplikasi target; satu staf penjualan hanya memiliki tepat satu target kuota per kuartal kalender.

---

### Q8 & Q9. Total Kontrol Rekonsiliasi Realisasi Penjualan
```sql
SELECT COUNT(*) AS jumlah_pesanan, SUM(subtotal) AS total_realisasi
FROM sales_salesorderheader WHERE salespersonid IS NOT NULL;
```
* **Analisis Hasil:** Angka kontrol realisasi penjualan adalah **Rp 80.487.704,1832** dari tepat **3.806 pesanan reseller**.

---

### Q10. Diskrepansi Target Tanpa Realisasi dan Realisasi Tanpa Target
```sql
-- Kueri Rekonsiliasi Komposisi Baris Fakta (Full Outer Join)
SELECT COALESCE(t.sp, r.sp) AS salesperson, COALESCE(t.thn, r.thn) AS tahun,
       COALESCE(t.kw, r.kw) AS kuartal, t.target, r.realisasi,
       'target tanpa realisasi' AS masalah
FROM (SELECT businessentityid AS sp, YEAR(quotadate) AS thn, QUARTER(quotadate) AS kw,
             SUM(salesquota) AS target
      FROM sales_salespersonquotahistory GROUP BY 1,2,3) t
LEFT JOIN (SELECT salespersonid AS sp,
                  YEAR(DATE_ADD(orderdate, INTERVAL 330 MINUTE))    AS thn,
                  QUARTER(DATE_ADD(orderdate, INTERVAL 330 MINUTE)) AS kw,
                  SUM(subtotal) AS realisasi
           FROM sales_salesorderheader WHERE salespersonid IS NOT NULL GROUP BY 1,2,3) r
       ON r.sp = t.sp AND r.thn = t.thn AND r.kw = t.kw
WHERE r.sp IS NULL
UNION ALL
SELECT r.sp, r.thn, r.kw, NULL, r.realisasi, 'realisasi tanpa target'
FROM (SELECT salespersonid AS sp,
             YEAR(DATE_ADD(orderdate, INTERVAL 330 MINUTE))    AS thn,
             QUARTER(DATE_ADD(orderdate, INTERVAL 330 MINUTE)) AS kw,
             SUM(subtotal) AS realisasi
      FROM sales_salesorderheader WHERE salespersonid IS NOT NULL GROUP BY 1,2,3) r
LEFT JOIN (SELECT businessentityid AS sp, YEAR(quotadate) AS thn, QUARTER(quotadate) AS kw
           FROM sales_salespersonquotahistory GROUP BY 1,2,3) t
       ON r.sp = t.sp AND r.thn = t.thn AND r.kw = t.kw
WHERE t.sp IS NULL
ORDER BY tahun, kuartal, salesperson;
```
* **Analisis Hasil:** Ditemukan tepat **18 baris diskrepansi asimetris**:
  * **Target Tanpa Realisasi (2 baris):** Staf 274 pada 2011 Q2 dan Staf 285 pada 2013 Q2 (memiliki kuota tetapi tidak menghasilkan transaksi).
  * **Realisasi Tanpa Target (16 baris):** Seluruh 16 sales person aktif pada 2014 Q2 (menghasilkan transaksi tetapi perusahaan tidak menetapkan kuota target).

---

### Q11 & Q12. Analisis Nilai NULL Dimensi Sales Person & Wilayah
```sql
SELECT sp.businessentityid, p.firstname, p.lastname, e.jobtitle
FROM sales_salesperson sp
JOIN person_person p ON p.businessentityid = sp.businessentityid
JOIN humanresources_employee e ON e.businessentityid = sp.businessentityid
WHERE sp.businessentityid NOT IN (SELECT businessentityid FROM sales_salesterritoryhistory);
```
* **Analisis Hasil:** Dari 17 sales person, sebanyak 3 orang tidak memiliki catatan wilayah penugasan di `sales_salesterritoryhistory`:
  * **ID 274:** Stephen Jiang (Jabatan: *North American Sales Manager*)
  * **ID 285:** Syed Abbas (Jabatan: *Pacific Sales Manager*)
  * **ID 287:** Amy Alberts (Jabatan: *European Sales Manager*)
  * *Ketiga individu ini merupakan manajer tingkat tinggi yang menangani pesanan korporat lintas teritori tanpa terikat pada satu wilayah spesifik.*

---

## Rekonsiliasi Data Sumber & Angka Kontrol (*Control Numbers*)
Dari hasil kueri profiling, Kelompok 4 menyusun tabel rekonsiliasi yang menjadi baseline validitas ETL data warehouse:

### Tabel Ukuran Kontrol Rekonsiliasi
| Ukuran Kontrol Rekonsiliasi | Nilai Kontrol Sumber | Target Integritas DW |
|:---|:---:|:---:|
| **Total Pesanan Reseller Ber-Sales Person** | 3.806 pesanan | 100% Cocok (0 Selisih) |
| **Total Akumulasi Realisasi Penjualan** | Rp 80.487.704,1832 | 100% Cocok (0 Selisih) |
| **Total Akumulasi Kuota Target Penjualan** | Rp 95.714.000,0000 | 100% Cocok (0 Selisih) |
| **Total Baris Fakta yang Diharapkan** | 179 baris fakta | 100% Cocok (0 Selisih) |
| **Komposisi Baris Fakta (Target + Realisasi)** | 161 (Keduanya) + 2 (Target saja) + 16 (Realisasi saja) | 179 Total Baris |

### Tabel Evaluasi Kinerja Historis
Rekapitulasi Kinerja Agregat Berdasarkan 161 Baris yang Memiliki Target dan Realisasi:

| Tahun Kalender | Target Penjualan (Rp) | Realisasi Penjualan (Rp) | Pencapaian (%) |
|:---|:---:|:---:|:---:|
| **2011 (Q2–Q4)** | 14.235.000,00 | 8.778.552,00 | 61,7% |
| **2012 (Q1–Q4)** | 30.172.000,00 | 27.133.701,38 | 89,9% |
| **2013 (Q1–Q4)** | 40.788.000,00 | 32.890.351,72 | 80,6% |
| **2014 (Q1)** | 10.359.000,00 | 8.268.335,22 | 79,8% |
| **TOTAL HISTORIS** | **95.554.000,00** | **77.070.940,32** | **80,7%** |
