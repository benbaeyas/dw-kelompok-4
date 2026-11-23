# ENTERPRISE DATA WAREHOUSE BUS MATRIX

## Baris Bus Matrix Tim Kelompok 4
Dalam arsitektur *Enterprise Data Warehouse* Kimball, *Enterprise Bus Matrix* berfungsi sebagai peta jalan arsitektural yang memastikan setiap proses bisnis terintegrasi secara harmonis melalui dimensi-dimensi yang terstandarisasi (*conformed dimensions*).

Berikut adalah posisi proses bisnis **Kinerja Sales vs Target (Kelompok 4)** di dalam matriks enterprise Adventure Works:

| Proses Bisnis | Tgl | Prd | Plg | Wil | Prm | Mata | Kirim | Sales | Kary |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Kinerja Sales vs Target (Kelompok 4)** | ● | | | ● | | | | ● | |
| **Penjualan Reseller (B2B)** | ● | ● | ● | ● | ● | ● | ● | ● | |
| **Penjualan Online (B2C)** | ● | ● | ● | ● | ● | ● | ● | | |
| **Pengadaan / Pembelian** | ● | ● | | | | | ● | | ● |
| **Manufaktur / Produksi** | ● | ● | | | | | | | ● |
| **Manajemen Inventaris** | ● | ● | | ● | | | | | |

> [!NOTE]
> **Keterangan Simbol:**  
> Simbol (●) menunjukkan dimensi yang digunakan secara langsung oleh tabel fakta pada proses bisnis terkait.

### Keterangan Singkatan Kolom Dimensi:
* **Tgl:** Dimensi Tanggal (`dim_tanggal`)
* **Prd:** Dimensi Produk (`dim_produk`)
* **Plg:** Dimensi Pelanggan (`dim_pelanggan` / *Customer*)
* **Wil:** Dimensi Wilayah (`dim_wilayah` / *Territory*)
* **Prm:** Dimensi Promosi (`dim_promosi`)
* **Mata:** Dimensi Mata Uang (`dim_mata_uang` / *Currency*)
* **Kirim:** Dimensi Metode Kirim (`dim_metode_kirim` / *Ship Method*)
* **Sales:** Dimensi Sales Person (`dim_sales_person`)
* **Kary:** Dimensi Karyawan (`dim_karyawan` / *Employee*)

---

## Analisis Dimensi Conformed (*Conformed Dimensions*)
Tabel fakta `fact_kinerja_sales` menggunakan 3 dimensi konformasi utama yang siap diintegrasikan lintas kelompok:

1. **Dimensi Tanggal (`dim_tanggal`):**
   * *Conformed Lintas Seluruh Enterprise.*
   * Digunakan oleh seluruh proses bisnis data warehouse Adventure Works dengan definisi kalender yang seragam (tahun, semester, kuartal, bulan, tanggal).
2. **Dimensi Wilayah (`dim_wilayah`):**
   * *Conformed dengan Penjualan Reseller & Online.*
   * Menggunakan struktur hierarki kawasan geografis yang identik dengan proses penjualan reseller dan penjualan daring (Grup Wilayah > Negara > Wilayah).
3. **Dimensi Sales Person (`dim_sales_person`):**
   * *Conformed dengan Penjualan Reseller.*
   * Menggunakan master profil staf penjualan yang sama persis dengan proses transaksi pesanan grosir B2B (identitas, jabatan, tanggal masuk, skema komisi, dan bonus).

---

## Peran Conformed Dimensions dalam Integrasi DW Masa Depan
Dengan diterapkannya dimensi konformasi ini, manajemen Adventure Works nantinya dapat melakukan kueri lintas proses (*drill-across queries*). Sebagai contoh, manajemen dapat membandingkan pencapaian target penjualan sales person dengan total komplain pelanggan atau efisiensi biaya logistik pada wilayah regional yang bersangkutan tanpa perlu mendesain ulang skema database.
