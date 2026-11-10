# Strategi SCD (Slowly Changing Dimension)

## 1. Ringkasan strategi per dimensi

| Dimensi | Atribut | Tipe | Alasan |
|---|---|---|---|
| **dim_sales_person** | jabatan, komisi_pct, bonus | **Tipe 2** | Kinerja harus dibaca dengan jabatan dan skema komisi yang berlaku saat periode itu. Bila hanya ditimpa, riwayat kinerja berubah mengikuti kondisi terbaru |
| dim_sales_person | nama_lengkap, tanggal_masuk | Tipe 1 | Perubahan hanya koreksi data; riwayatnya tidak mempengaruhi analisis |
| dim_produk | semua atribut (termasuk list_price) | Tipe 1 | Analisis fokus pada realisasi vs target, bukan harga historis |
| dim_wilayah | semua atribut (termasuk is_active) | Tipe 1 | Dimensi referensi yang jarang berubah |
| dim_tanggal | semua | Tipe 0 | Tanggal tidak pernah berubah |
| dim_kategori_kinerja | semua | Tipe 0 | Tabel referensi tetap |

## 2. Rancangan Tipe 2 pada dim_sales_person

Kolom pendukung: `row_effective_date` (mulai berlaku) dan `row_expiry_date` (hari terakhir berlaku, inklusif).

| Aturan | Nilai |
|---|---|
| Versi pertama | `row_effective_date = '1900-01-01'` |
| Versi berikutnya | `row_effective_date = tanggal ETL berjalan` |
| Baris aktif | `row_expiry_date = '9999-12-31'` |
| Versi yang ditutup | `row_expiry_date = tanggal ETL berjalan - 1 hari` |
| Pemilihan key di fakta | `row_effective_date <= period_start <= row_expiry_date` |

Tidak ada kolom `is_current`; baris aktif dikenali lewat `row_expiry_date = '9999-12-31'`. Kalau tim ingin kolom itu, tambahkan `ALTER TABLE dim_sales_person ADD COLUMN is_current tinyint(1) NOT NULL DEFAULT 1;` dan sesuaikan langkah ETL.

Atribut pemicu versi baru: `jabatan`, `komisi_pct`, `bonus`.

## 3. Logika ETL (MySQL, dijalankan setelah `stg_sales_person` terisi)

```sql
-- Langkah 1: tutup versi lama yang atributnya berubah
UPDATE dim_sales_person d
JOIN stg_sales_person s ON s.business_entity_id = d.business_entity_id
SET d.row_expiry_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
WHERE d.row_expiry_date = '9999-12-31'
  AND (d.jabatan <> s.jabatan OR d.komisi_pct <> s.komisi_pct OR d.bonus <> s.bonus);

-- Langkah 2: sisipkan versi baru (salesperson baru atau yang baru ditutup)
INSERT INTO dim_sales_person
  (business_entity_id, nama_lengkap, jabatan, tanggal_masuk,
   komisi_pct, bonus, row_effective_date, row_expiry_date)
SELECT s.business_entity_id, s.nama_lengkap, s.jabatan, s.tanggal_masuk,
       s.komisi_pct, s.bonus,
       CASE WHEN EXISTS (SELECT 1 FROM dim_sales_person x
                         WHERE x.business_entity_id = s.business_entity_id)
            THEN CURDATE() ELSE '1900-01-01' END,
       '9999-12-31'
FROM stg_sales_person s
WHERE NOT EXISTS (SELECT 1 FROM dim_sales_person d
                  WHERE d.business_entity_id = s.business_entity_id
                    AND d.row_expiry_date = '9999-12-31');

-- Langkah 3: atribut Tipe 1 ditimpa pada versi aktif
UPDATE dim_sales_person d
JOIN stg_sales_person s ON s.business_entity_id = d.business_entity_id
SET d.nama_lengkap = s.nama_lengkap,
    d.tanggal_masuk = s.tanggal_masuk
WHERE d.row_expiry_date = '9999-12-31';
```

Di Pentaho, langkah ini bisa diganti dengan step **Dimension lookup/update** (tipe update "Punch through" untuk Tipe 1 dan "Insert" untuk Tipe 2), dengan field Tipe 2 = jabatan, komisi_pct, bonus.

## 4. Skenario demo (tanpa mengubah database sumber)

AdventureWorks tidak menyimpan riwayat perubahan jabatan atau komisi, jadi perubahan disimulasikan di **staging**:

1. Jalankan ETL penuh. `dim_sales_person` berisi 1 baris per salesperson dengan `row_expiry_date = '9999-12-31'`.
2. Ubah staging: `UPDATE stg_sales_person SET jabatan = 'Sales Manager', bonus = bonus + 1000 WHERE business_entity_id = <id>;`
3. Jalankan langkah 1-3 di atas.
4. Tampilkan hasil: `SELECT * FROM dim_sales_person WHERE business_entity_id = <id> ORDER BY row_effective_date;`

Hasil yang diharapkan:

| business_entity_id | jabatan | row_effective_date | row_expiry_date |
|---|---|---|---|
| 275 | Sales Representative | 1900-01-01 | (hari ini - 1) |
| 275 | Sales Manager | (hari ini) | 9999-12-31 |

5. Fakta periode lama tetap menunjuk ke versi lama, sehingga riwayat tetap benar.

Catatan: setelah demo, ekstrak ulang dari sumber akan mengembalikan nilai asli di staging dan menghasilkan versi baru lagi. Untuk demo, jangan ekstrak ulang `stg_sales_person` sebelum screenshot diambil.

## 5. Batasan yang perlu dicatat di laporan

- Wilayah salesperson di fakta diambil dari kondisi saat ini; perpindahan wilayah (`salesterritoryhistory`) tidak dilacak di versi ini.
- Tipe 2 hanya diterapkan pada dim_sales_person karena hanya di sana riwayat atribut mempengaruhi interpretasi kinerja.
