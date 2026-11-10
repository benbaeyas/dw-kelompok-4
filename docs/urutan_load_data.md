# Urutan Load Data (Staging sampai Tabel Fakta)

## 1. Alur

```
[PostgreSQL adventureworks]            [MySQL adn_kl4]
        |  (Table Input -> Table Output)
        v
  stg_wilayah, stg_produk, stg_sales_person,
  stg_periode, stg_target, stg_realisasi
        |
        v
  0. Prasyarat: baris default + unique key
  1. dim_tanggal             (dibangkitkan)
  2. dim_kategori_kinerja    (referensi)
  3. dim_wilayah             (Tipe 1)
  4. dim_produk              (Tipe 1)
  5. dim_sales_person        (Tipe 2)
  6. stg_kinerja             (hitung attainment dan kategori)
  7. fact_kinerja_sales_v2   (baris produk, lalu baris "Semua Produk")
  8. Validasi dan rekonsiliasi
```

Dimensi dimuat sebelum fakta karena fakta memerlukan surrogate key dimensi. `stg_kinerja` dihitung sebelum fakta karena kategori kinerja disalin ke semua baris salesperson-periode.

## 2. Tabel ringkas

| Langkah | Target | Sumber | Dependensi | Strategi |
|---|---|---|---|---|
| E1-E6 | tabel `stg_*` | AdventureWorks (read-only) | - | Kosongkan lalu isi ulang tiap run |
| 1 | dim_tanggal | dibangkitkan | - | Isi sekali |
| 2 | dim_kategori_kinerja | manual | - | Isi sekali |
| 3 | dim_wilayah | stg_wilayah | E1 | Tipe 1 (upsert) |
| 4 | dim_produk | stg_produk | E2 | Tipe 1 (upsert) |
| 5 | dim_sales_person | stg_sales_person | E3 | Tipe 2 |
| 6 | stg_kinerja | stg_target, stg_realisasi | E4-E6 | Kosongkan lalu isi ulang |
| 7 | fact_kinerja_sales_v2 | stg_realisasi, stg_target, stg_kinerja + semua dimensi | 1-6 | Kosongkan lalu isi ulang (full reload) |
| 8 | laporan validasi | fakta dan staging | 7 | - |

## 3. Prasyarat (jalankan sekali di `adn_kl4`)

### 3a. Tabel staging

```sql
CREATE TABLE stg_wilayah (
  territory_id int PRIMARY KEY, nama_wilayah varchar(50), kode_negara varchar(3),
  nama_negara varchar(50), grup_wilayah varchar(50));
CREATE TABLE stg_produk (
  product_id int PRIMARY KEY, nama_produk varchar(50), nomor_produk varchar(25),
  sub_kategori varchar(50), kategori varchar(50), list_price decimal(15,2));
CREATE TABLE stg_sales_person (
  business_entity_id int PRIMARY KEY, nama_lengkap varchar(150), jabatan varchar(100),
  tanggal_masuk date, komisi_pct decimal(5,4), bonus decimal(15,2), territory_id int NULL);
CREATE TABLE stg_periode (period_start date PRIMARY KEY, period_end date);
CREATE TABLE stg_target (
  business_entity_id int, period_start date, sales_quota decimal(15,2),
  PRIMARY KEY (business_entity_id, period_start));
CREATE TABLE stg_realisasi (
  business_entity_id int, period_start date, product_id int,
  realisasi decimal(15,2), qty int,
  PRIMARY KEY (business_entity_id, period_start, product_id));
CREATE TABLE stg_kinerja (
  business_entity_id int, period_start date, total_realisasi decimal(15,2),
  sales_quota decimal(15,2) NULL, attainment decimal(10,4) NULL, kategori_kinerja_key int,
  PRIMARY KEY (business_entity_id, period_start));
```

### 3b. Unique key business key

```sql
ALTER TABLE dim_produk  ADD UNIQUE KEY uk_product_id (product_id);
ALTER TABLE dim_wilayah ADD UNIQUE KEY uk_territory_id (territory_id);
ALTER TABLE dim_sales_person ADD INDEX idx_sp_bk (business_entity_id, row_effective_date);
```

### 3c. Baris default

```sql
INSERT INTO dim_produk VALUES
 (-1,-1,'Tidak diketahui','N/A','Tidak diketahui','Tidak diketahui',0),
 (-2,-2,'Semua Produk','N/A','Semua Produk','Semua Produk',0);
INSERT INTO dim_wilayah VALUES (-1,NULL,'Tidak diketahui','N/A','Tidak diketahui','Tidak diketahui',1);
INSERT INTO dim_sales_person
 (sales_person_key,business_entity_id,nama_lengkap,jabatan,tanggal_masuk,komisi_pct,bonus,row_effective_date,row_expiry_date)
 VALUES (-1,-1,'Tidak diketahui','Tidak diketahui','1900-01-01',0,0,'1900-01-01','9999-12-31');
INSERT INTO dim_kategori_kinerja VALUES
 (-1,'UNK','Tidak diketahui','-'),
 (1,'TNT','Tanpa target','Tidak punya kuota pada periode itu'),
 (2,'BWH','Di bawah target','Attainment < 80%'),
 (3,'MDK','Mendekati target','Attainment 80% sampai < 100%'),
 (4,'CPI','Tercapai','Attainment >= 100%');
```

## 4. Ekstraksi ke staging (PostgreSQL, step Table Input)

```sql
-- E1 stg_wilayah
SELECT t.territoryid, t.name, t.countryregioncode, cr.name AS nama_negara, t."group"
FROM sales.salesterritory t
JOIN person.countryregion cr ON cr.countryregioncode = t.countryregioncode;

-- E2 stg_produk
SELECT p.productid, p.name, p.productnumber,
       COALESCE(ps.name, 'Tidak diketahui'), COALESCE(pc.name, 'Tidak diketahui'), p.listprice
FROM production.product p
LEFT JOIN production.productsubcategory ps ON ps.productsubcategoryid = p.productsubcategoryid
LEFT JOIN production.productcategory pc   ON pc.productcategoryid = ps.productcategoryid;

-- E3 stg_sales_person
SELECT sp.businessentityid,
       TRIM(CONCAT_WS(' ', pe.firstname, pe.middlename, pe.lastname)),
       e.jobtitle, e.hiredate::date, sp.commissionpct, sp.bonus, sp.territoryid
FROM sales.salesperson sp
JOIN person.person pe          ON pe.businessentityid = sp.businessentityid
JOIN humanresources.employee e ON e.businessentityid  = sp.businessentityid;

-- E4 stg_periode
SELECT q.quotadate::date AS period_start,
       COALESCE(LEAD(q.quotadate::date) OVER (ORDER BY q.quotadate) - 1, DATE '9999-12-31') AS period_end
FROM (SELECT DISTINCT quotadate FROM sales.salespersonquotahistory) q;

-- E5 stg_target
SELECT businessentityid, quotadate::date, salesquota
FROM sales.salespersonquotahistory;

-- E6 stg_realisasi (butuh stg_periode: ekstrak E4 dulu dan jalankan query ini
--     dengan rentang periode yang sama, atau gunakan CTE periode di dalam query)
WITH periode AS (
  SELECT q.quotadate::date AS period_start,
         COALESCE(LEAD(q.quotadate::date) OVER (ORDER BY q.quotadate) - 1, DATE '9999-12-31') AS period_end
  FROM (SELECT DISTINCT quotadate FROM sales.salespersonquotahistory) q)
SELECT h.salespersonid, p.period_start, d.productid,
       SUM(d.linetotal) AS realisasi, SUM(d.orderqty) AS qty
FROM sales.salesorderheader h
JOIN sales.salesorderdetail d USING (salesorderid)
JOIN periode p ON h.orderdate::date BETWEEN p.period_start AND p.period_end
WHERE h.salespersonid IS NOT NULL
GROUP BY h.salespersonid, p.period_start, d.productid;
```

## 5. dim_tanggal (dibangkitkan, MySQL)

Sesuaikan rentang tanggal dengan hasil `MIN/MAX` orderdate dan quotadate dari profiling.

```sql
SET SESSION cte_max_recursion_depth = 5000;
INSERT INTO dim_tanggal
WITH RECURSIVE d AS (
  SELECT DATE('2011-01-01') AS t
  UNION ALL SELECT t + INTERVAL 1 DAY FROM d WHERE t < '2014-12-31')
SELECT CAST(DATE_FORMAT(t,'%Y%m%d') AS UNSIGNED), t, YEAR(t), IF(MONTH(t)<=6,1,2), QUARTER(t), MONTH(t),
       ELT(MONTH(t),'Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'),
       WEEK(t,3), DAY(t), DAYOFWEEK(t),
       ELT(DAYOFWEEK(t),'Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'),
       IF(DAYOFWEEK(t) IN (1,7),1,0)
FROM d;
```

## 6. dim_wilayah dan dim_produk (Tipe 1, upsert)

```sql
INSERT INTO dim_wilayah (territory_id,nama_wilayah,kode_negara,nama_negara,grup_wilayah,is_active)
SELECT s.territory_id,s.nama_wilayah,s.kode_negara,s.nama_negara,s.grup_wilayah,
       IF(EXISTS (SELECT 1 FROM stg_sales_person p WHERE p.territory_id = s.territory_id),1,0)
FROM stg_wilayah s
ON DUPLICATE KEY UPDATE nama_wilayah=VALUES(nama_wilayah), kode_negara=VALUES(kode_negara),
  nama_negara=VALUES(nama_negara), grup_wilayah=VALUES(grup_wilayah), is_active=VALUES(is_active);

INSERT INTO dim_produk (product_id,nama_produk,nomor_produk,sub_kategori,kategori,list_price)
SELECT product_id,nama_produk,nomor_produk,sub_kategori,kategori,list_price FROM stg_produk
ON DUPLICATE KEY UPDATE nama_produk=VALUES(nama_produk), nomor_produk=VALUES(nomor_produk),
  sub_kategori=VALUES(sub_kategori), kategori=VALUES(kategori), list_price=VALUES(list_price);
```

## 7. dim_sales_person (Tipe 2)

Gunakan tiga langkah di dokumen strategi SCD (`03_strategi_scd.md`, bagian 3).

## 8. stg_kinerja (attainment dan kategori)

```sql
TRUNCATE stg_kinerja;
INSERT INTO stg_kinerja
SELECT k.business_entity_id, k.period_start,
       COALESCE(r.total_realisasi,0), t.sales_quota,
       CASE WHEN t.sales_quota IS NULL OR t.sales_quota = 0 THEN NULL
            ELSE COALESCE(r.total_realisasi,0) / t.sales_quota END,
       CASE WHEN t.sales_quota IS NULL OR t.sales_quota = 0 THEN 1
            WHEN COALESCE(r.total_realisasi,0) / t.sales_quota >= 1   THEN 4
            WHEN COALESCE(r.total_realisasi,0) / t.sales_quota >= 0.8 THEN 3
            ELSE 2 END
FROM (SELECT business_entity_id, period_start FROM stg_realisasi
      UNION
      SELECT business_entity_id, period_start FROM stg_target) k
LEFT JOIN (SELECT business_entity_id, period_start, SUM(realisasi) AS total_realisasi
           FROM stg_realisasi GROUP BY business_entity_id, period_start) r
       ON r.business_entity_id = k.business_entity_id AND r.period_start = k.period_start
LEFT JOIN stg_target t
       ON t.business_entity_id = k.business_entity_id AND t.period_start = k.period_start;
```

## 9. fact_kinerja_sales_v2

```sql
DELETE FROM fact_kinerja_sales_v2;

-- 9a. Baris produk (realisasi)
INSERT INTO fact_kinerja_sales_v2
(tanggal_kuartal_key,sales_person_key,wilayah_key,produk_key,
 target_penjualan,realisasi_penjualan,selisih_realisasi_target,jumlah_terjual,kategori_kinerja_key)
SELECT COALESCE(dt.tanggal_key,-1), COALESCE(dsp.sales_person_key,-1),
       COALESCE(dw.wilayah_key,-1), COALESCE(dp.produk_key,-1),
       NULL, r.realisasi, NULL, r.qty, COALESCE(k.kategori_kinerja_key,-1)
FROM stg_realisasi r
LEFT JOIN stg_kinerja k  ON k.business_entity_id = r.business_entity_id AND k.period_start = r.period_start
LEFT JOIN stg_sales_person ssp ON ssp.business_entity_id = r.business_entity_id
LEFT JOIN dim_tanggal dt ON dt.tanggal = r.period_start
LEFT JOIN dim_sales_person dsp ON dsp.business_entity_id = r.business_entity_id
      AND r.period_start BETWEEN dsp.row_effective_date AND dsp.row_expiry_date
LEFT JOIN dim_wilayah dw ON dw.territory_id = ssp.territory_id
LEFT JOIN dim_produk dp  ON dp.product_id = r.product_id;

-- 9b. Baris "Semua Produk" (target)
INSERT INTO fact_kinerja_sales_v2
(tanggal_kuartal_key,sales_person_key,wilayah_key,produk_key,
 target_penjualan,realisasi_penjualan,selisih_realisasi_target,jumlah_terjual,kategori_kinerja_key)
SELECT COALESCE(dt.tanggal_key,-1), COALESCE(dsp.sales_person_key,-1),
       COALESCE(dw.wilayah_key,-1), -2,
       t.sales_quota, 0, k.total_realisasi - t.sales_quota, 0, k.kategori_kinerja_key
FROM stg_target t
JOIN stg_kinerja k ON k.business_entity_id = t.business_entity_id AND k.period_start = t.period_start
LEFT JOIN stg_sales_person ssp ON ssp.business_entity_id = t.business_entity_id
LEFT JOIN dim_tanggal dt ON dt.tanggal = t.period_start
LEFT JOIN dim_sales_person dsp ON dsp.business_entity_id = t.business_entity_id
      AND t.period_start BETWEEN dsp.row_effective_date AND dsp.row_expiry_date
LEFT JOIN dim_wilayah dw ON dw.territory_id = ssp.territory_id;
```

Bila insert gagal karena primary key ganda, penyebabnya hampir selalu lookup ke key -1 untuk lebih dari satu produk atau salesperson. Perbaiki data dimensinya, jangan menghapus primary key.

## 10. Validasi

```sql
SELECT 'target' AS cek, (SELECT SUM(target_penjualan) FROM fact_kinerja_sales_v2) AS fakta,
       (SELECT SUM(sales_quota) FROM stg_target) AS staging
UNION ALL
SELECT 'realisasi', (SELECT SUM(realisasi_penjualan) FROM fact_kinerja_sales_v2),
       (SELECT SUM(realisasi) FROM stg_realisasi)
UNION ALL
SELECT 'baris Semua Produk', (SELECT COUNT(*) FROM fact_kinerja_sales_v2 WHERE produk_key = -2),
       (SELECT COUNT(*) FROM stg_target);

-- Kualitas data: fakta dengan key tidak dikenal
SELECT SUM(sales_person_key=-1) AS sp_unknown, SUM(wilayah_key=-1) AS wil_unknown,
       SUM(produk_key=-1) AS prod_unknown, SUM(tanggal_kuartal_key=-1) AS tgl_unknown
FROM fact_kinerja_sales_v2;
```

## 11. Struktur job Pentaho (PDI)

```
job_load_dw
 START
  -> tr_extract_staging        (E1-E6: Table Input -> Table Output, truncate sebelum insert)
  -> tr_dim_wilayah_produk     (langkah 3-4)
  -> tr_dim_sales_person       (langkah 5, step Dimension lookup/update)
  -> tr_hitung_kinerja         (langkah 6: Execute SQL script)
  -> tr_load_fakta             (langkah 7: Execute SQL script, 9a lalu 9b)
  -> tr_validasi               (langkah 8: Table Input, hasil ke log)
 SUCCESS / ABORT (bila validasi gagal)
```

Aturan operasional: bila satu langkah gagal, job berhenti (hop "On error" ke Abort), dan fakta tidak dimuat sampai dimensi selesai. Dimuat ulang penuh setiap run karena volume data kecil.
