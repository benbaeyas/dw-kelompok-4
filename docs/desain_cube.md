# Desain OLAP Cube: Kinerja Sales vs Target
**Proyek:** Data Warehouse Evaluasi Kinerja Penjualan dan Pencapaian Target  
**Kelompok:** Kelompok 4  
**Tabel Fakta Sumber:** `fact_kinerja_sales_v2`  
**Basis Data Target:** `dw_kelompok_4` (`adn_kl4`)  
**Referensi Modul:** Pertemuan 10 - Desain Cube (Persiapan Menuju Implementasi Mondrian Pekan 13)  
**Dokumentasi Terkait:** [mapping.md](mapping.md) (Source-to-Target Mapping, Strategi SCD Tiap Dimensi, dan Urutan Load ETL)

---

## 1. Tabel Desain Cube Utama

Sesuai dengan panduan modul dosen pada materi *Desain Cube*, berikut adalah spesifikasi arsitektural lapisan analitik OLAP Cube:

| Elemen | Desain untuk Kinerja Sales vs Target | Asal di DW | Keterangan / Formula |
|---|---|---|---|
| **Nama Cube** | `Kinerja Sales vs Target` | `fact_kinerja_sales_v2` | Cube analitik evaluasi performa penjualan terhadap target kuota |
| **Dimensi Waktu** | Tahun > Semester > Kuartal | `dim_tanggal` lewat `tanggal_kuartal_key` (SCD Tipe 0) | Hierarki kalender standar untuk agregasi antar-periode |
| **Dimensi Wilayah** | Grup Wilayah > Negara > Wilayah | `dim_wilayah` lewat `wilayah_key` (SCD Tipe 1) | Hierarki kawasan regional geografis penjualan |
| **Dimensi Sales Person** | Jabatan > Sales Person | `dim_sales_person` lewat `sales_person_key` (SCD Tipe 2) | Hierarki organisasi staf penjualan (melacak riwayat jabatan & komisi) |
| **Dimensi Kelompok Komisi** | Kelompok Komisi > Sales Person | `dim_sales_person` lewat `sales_person_key` (SCD Tipe 2) | Pengelompokan staf berdasarkan tingkat persentase komisi |
| **Dimensi Kategori Kinerja** | Kategori Kinerja | `dim_kategori_kinerja` lewat `kategori_kinerja_key` (SCD Tipe 1) | Klasifikasi performa (*Tercapai, Belum Tercapai, Tanpa Target, Target Tanpa Realisasi*) |
| **Dimensi Produk** | Kategori > Subkategori > Produk | `dim_produk` lewat `produk_key` (SCD Tipe 1) | Dimensi bersama (*conformed*) untuk analisis penjualan barang |
| **Measure: Realisasi Penjualan** | `Realisasi Penjualan` (aggregator: `sum`) | Kolom fakta `realisasi_penjualan` | Total nilai penjualan bersih (SubTotal pesanan reseller) |
| **Measure: Target Penjualan** | `Target Penjualan` (aggregator: `sum`) | Kolom fakta `target_penjualan` | Total kuota penjualan yang ditetapkan manajemen |
| **Measure: Selisih Realisasi** | `Selisih Realisasi` (aggregator: `sum`) | Kolom fakta `selisih_realisasi_target` | Akumulasi selisih absolut (`Realisasi - Target`) |
| **Measure: Unit Terjual** | `Jumlah Unit Terjual` (aggregator: `sum`) | Kolom fakta `jumlah_terjual` | Total kuantitas barang dagangan yang berhasil terjual |
| **Measure: Hitungan Kuartal** | `Jumlah Kuartal` (aggregator: `count`) | Kolom fakta `tanggal_kuartal_key` | Menghitung frekuensi baris fakta kuartalan |
| **Calculated Member 1** | `Realisasi Rata-rata per Unit` | Dihitung di cube | `[Measures].[Realisasi Penjualan] / [Measures].[Jumlah Unit Terjual]` (Rasio nilai per unit terjual) |
| **Calculated Member 2** | `Persentase Pencapaian Target` | Dihitung di cube | `IIf([Measures].[Target Penjualan] > 0, ([Measures].[Realisasi Penjualan] / [Measures].[Target Penjualan]) * 100, NULL)` |
| **Calculated Member 3** | `Persentase Selisih Target` | Dihitung di cube | `IIf([Measures].[Target Penjualan] > 0, ([Measures].[Selisih Realisasi] / [Measures].[Target Penjualan]) * 100, NULL)` |

---

## 2. Rincian Hierarki dan Level Dimensi

| Nama Dimensi | Tipe SCD | Nama Hierarki | Level-Level (Tingkatan) | Kolom Sumber di Tabel Dimensi | Tipe Level |
|---|---|---|---|---|---|
| **Waktu** | SCD Tipe 0 | `Kalender` | 1. Tahun<br>2. Semester<br>3. Kuartal | `tahun`<br>`semester`<br>`kuartal` | Numeric (TimeYears)<br>Numeric<br>Numeric (TimeQuarters) |
| **Wilayah** | SCD Tipe 1 | `Geografis` | 1. Grup Wilayah<br>2. Negara<br>3. Wilayah | `grup_wilayah`<br>`nama_negara`<br>`nama_wilayah` | String<br>String<br>String |
| **Sales Person** | SCD Tipe 2 | `Organisasi` | 1. Jabatan<br>2. Sales Person | `jabatan`<br>`nama_lengkap` | String<br>String |
| **Komisi Sales** | SCD Tipe 2 | `Kelompok Komisi` | 1. Persentase Komisi<br>2. Sales Person | `komisi_pct`<br>`nama_lengkap` | Numeric<br>String |
| **Kategori Kinerja** | SCD Tipe 1 | `Klasifikasi` | 1. Kategori Kinerja | `nama_kategori` | String |
| **Produk** | SCD Tipe 1 | `Katalog` | 1. Kategori<br>2. Subkategori<br>3. Produk | `kategori`<br>`sub_kategori`<br>`nama_produk` | String<br>String<br>String |

---

## 3. Rincian Measure dan Calculated Member

### A. Base Measures (Tabel Fakta)
1. **`Realisasi Penjualan`**
   - Kolom: `realisasi_penjualan`
   - Fungsi Agregasi: `sum`
   - Format Display: `Rp #,##0.00`
   - Fungsi: Menghitung total nilai omzet penjualan aktual yang dihasilkan staf penjualan.
2. **`Target Penjualan`**
   - Kolom: `target_penjualan`
   - Fungsi Agregasi: `sum`
   - Format Display: `Rp #,##0.00`
   - Fungsi: Menghitung total kuota target yang dibebankan kepada staf penjualan.
3. **`Selisih Realisasi`**
   - Kolom: `selisih_realisasi_target`
   - Fungsi Agregasi: `sum`
   - Format Display: `Rp #,##0.00`
   - Fungsi: Mengetahui nilai surplus (positif) atau defisit (negatif) penjualan.
4. **`Jumlah Unit Terjual`**
   - Kolom: `jumlah_terjual`
   - Fungsi Agregasi: `sum`
   - Format Display: `#,##0`
   - Fungsi: Mengukur volume fisik penjualan barang dagangan.
5. **`Jumlah Kuartal Teramati`**
   - Kolom: `tanggal_kuartal_key`
   - Fungsi Agregasi: `count`
   - Format Display: `#,##0`
   - Fungsi: Menghitung frekuensi kuartal untuk rasio konsistensi pencapaian target.

### B. Calculated Members (Lapisan OLAP)
1. **`Realisasi Rata-rata per Unit` (Wajib untuk Pertanyaan Bisnis 4)**
   - Formula MDX:
     ```mdx
     IIf(
       [Measures].[Jumlah Unit Terjual] > 0,
       [Measures].[Realisasi Penjualan] / [Measures].[Jumlah Unit Terjual],
       0
     )
     ```
   - Format Display: `Rp #,##0.00`
   - Keterangan: Mengukur rata-rata harga/nilai realisasi dari setiap unit barang yang dijual oleh sales person (mengungkap apakah sales person menjual barang bernilai tinggi atau banyak barang bernilai kecil).

2. **`Persentase Pencapaian Target`**
   - Formula MDX:
     ```mdx
     IIf(
       [Measures].[Target Penjualan] > 0,
       ([Measures].[Realisasi Penjualan] / [Measures].[Target Penjualan]) * 100,
       NULL
     )
     ```
   - Format Display: `0.00"%"`
   - Keterangan: Menghitung rasio pencapaian agregat secara aditif (menjumlahkan realisasi terlebih dahulu lalu dibagi dengan total target, bukan merata-ratakan persentase).

3. **`Rata-rata Selisih per Kuartal` (Mendukung Pertanyaan Bisnis 5)**
   - Formula MDX:
     ```mdx
     IIf(
       [Measures].[Jumlah Kuartal Teramati] > 0,
       [Measures].[Selisih Realisasi] / [Measures].[Jumlah Kuartal Teramati],
       NULL
     )
     ```
   - Format Display: `Rp #,##0.00`
   - Keterangan: Menghitung rata-rata surplus/defisit kuartalan per kelompok komisi.

---

## 4. Pemetaan Terhadap 7 Pertanyaan Bisnis Revisi Dosen

Tabel ini membuktikan keselarasan penuh antara desain Cube dengan kebutuhan manajerial:

| No | Rumusan Pertanyaan Bisnis | Dimensi & Level yang Digunakan | Measure & Calculated Member | Operasi OLAP yang Dilakukan |
|---|---|---|---|---|
| **1** | Perkembangan total realisasi vs target dari kuartal ke kuartal per grup wilayah | Waktu (`Tahun > Kuartal`), Wilayah (`Grup Wilayah`) | `Realisasi Penjualan`, `Target Penjualan`, `Selisih Realisasi` | **Drill-down** waktu ke Kuartal, **Slice** per Grup Wilayah |
| **2** | Wilayah paling melampaui dan paling di bawah target per tahun | Wilayah (`Grup Wilayah > Negara > Wilayah`), Waktu (`Tahun`) | `Selisih Realisasi` | **Slice** per Tahun, **Drill-down** wilayah, **Rank/Sort** nilai selisih |
| **3** | Jumlah kuartal tiap salesperson berhasil mencapai target | Sales Person (`Sales Person`), Kategori Kinerja (`Kategori Kinerja`), Waktu (`Tahun > Kuartal`) | `Jumlah Kuartal Teramati` | **Slice** Kategori Kinerja = 'Tercapai', **Count** kuartal |
| **4** | Perbandingan unit terjual vs realisasi dan rata-rata realisasi per unit | Sales Person (`Sales Person`), Wilayah, Waktu | `Jumlah Unit Terjual`, `Realisasi Penjualan`, `Realisasi Rata-rata per Unit` | **Rank** Unit Terjual vs Realisasi, evaluasi **Calculated Member** |
| **5** | Kelompok komisi paling sering mencapai target dan rata-rata selisih terbaik | Komisi Sales (`Kelompok Komisi`), Kategori Kinerja, Waktu | `Jumlah Kuartal Teramati`, `Selisih Realisasi`, `Rata-rata Selisih per Kuartal` | **Dice** Komisi x Kategori 'Tercapai', komparasi rata-rata selisih |
| **6\*** | Salesperson dengan tren selisih memburuk 2 kuartal berurutan | Sales Person (`Sales Person`), Waktu (`Tahun > Kuartal`) | `Selisih Realisasi` | **Trend Analysis** / perbandingan Lag selisih antar-kuartal berurutan |
| **7\*** | Salesperson dengan realisasi tanpa target dan nilai realisasinya | Kategori Kinerja (`Kategori Kinerja`), Wilayah (`Grup Wilayah`), Waktu (`Tahun > Kuartal`) | `Realisasi Penjualan`, Distinct Count Sales Person | **Slice** Kategori Kinerja = 'Tanpa Target' (misal: 2014 Q2), agregasi realisasi |

---

## 5. Gambaran Awal Skema Mondrian XML (Untuk Implementasi Pekan 13)

Sebagai persiapan implementasi teknis di Pekan 13 sesuai arahan modul, berikut adalah cetak biru skema Mondrian XML yang siap digunakan:

```xml
<Schema name="AdventureWorks_DW">
  <Cube name="Kinerja Sales vs Target">
    <Table name="fact_kinerja_sales_v2"/>

    <!-- Dimensi Waktu -->
    <Dimension name="Waktu" foreignKey="tanggal_kuartal_key" type="TimeDimension">
      <Hierarchy hasAll="true" allMemberName="Semua Periode" primaryKey="tanggal_key">
        <Table name="dim_tanggal"/>
        <Level name="Tahun" column="tahun" type="Numeric" levelType="TimeYears"/>
        <Level name="Semester" column="semester" type="Numeric"/>
        <Level name="Kuartal" column="kuartal" type="Numeric" levelType="TimeQuarters"/>
      </Hierarchy>
    </Dimension>

    <!-- Dimensi Wilayah -->
    <Dimension name="Wilayah" foreignKey="wilayah_key">
      <Hierarchy hasAll="true" allMemberName="Semua Wilayah" primaryKey="wilayah_key">
        <Table name="dim_wilayah"/>
        <Level name="Grup Wilayah" column="grup_wilayah" type="String"/>
        <Level name="Negara" column="nama_negara" type="String"/>
        <Level name="Wilayah" column="nama_wilayah" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- Dimensi Sales Person -->
    <Dimension name="Sales Person" foreignKey="sales_person_key">
      <Hierarchy hasAll="true" allMemberName="Semua Sales Person" primaryKey="sales_person_key">
        <Table name="dim_sales_person"/>
        <Level name="Jabatan" column="jabatan" type="String"/>
        <Level name="Sales Person" column="nama_lengkap" type="String"/>
      </Hierarchy>
      <Hierarchy name="Berdasarkan Komisi" hasAll="true" allMemberName="Semua Komisi" primaryKey="sales_person_key">
        <Table name="dim_sales_person"/>
        <Level name="Persentase Komisi" column="komisi_pct" type="Numeric"/>
        <Level name="Sales Person" column="nama_lengkap" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- Dimensi Kategori Kinerja -->
    <Dimension name="Kategori Kinerja" foreignKey="kategori_kinerja_key">
      <Hierarchy hasAll="true" allMemberName="Semua Kategori" primaryKey="kategori_kinerja_key">
        <Table name="dim_kategori_kinerja"/>
        <Level name="Kategori Kinerja" column="nama_kategori" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- Dimensi Produk (Conformed Dimension) -->
    <Dimension name="Produk" foreignKey="produk_key">
      <Hierarchy hasAll="true" allMemberName="Semua Produk" primaryKey="produk_key">
        <Table name="dim_produk"/>
        <Level name="Kategori" column="kategori" type="String"/>
        <Level name="Subkategori" column="sub_kategori" type="String"/>
        <Level name="Produk" column="nama_produk" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- Base Measures -->
    <Measure name="Realisasi Penjualan" column="realisasi_penjualan" aggregator="sum" formatString="Rp #,##0.00"/>
    <Measure name="Target Penjualan" column="target_penjualan" aggregator="sum" formatString="Rp #,##0.00"/>
    <Measure name="Selisih Realisasi" column="selisih_realisasi_target" aggregator="sum" formatString="Rp #,##0.00"/>
    <Measure name="Jumlah Unit Terjual" column="jumlah_terjual" aggregator="sum" formatString="#,##0"/>
    <Measure name="Jumlah Kuartal Teramati" column="tanggal_kuartal_key" aggregator="count" formatString="#,##0"/>

    <!-- Calculated Members -->
    <CalculatedMember name="Realisasi Rata-rata per Unit" dimension="Measures"
      formula="IIf([Measures].[Jumlah Unit Terjual] &gt; 0, [Measures].[Realisasi Penjualan] / [Measures].[Jumlah Unit Terjual], 0)"
      formatString="Rp #,##0.00"/>

    <CalculatedMember name="Persentase Pencapaian Target" dimension="Measures"
      formula="IIf([Measures].[Target Penjualan] &gt; 0, ([Measures].[Realisasi Penjualan] / [Measures].[Target Penjualan]) * 100, NULL)"
      formatString="0.00%"/>
  </Cube>
</Schema>
```
