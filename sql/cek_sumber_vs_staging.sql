-- Rekonsiliasi sumber vs staging (t01 menyalin tanpa filter, jadi jumlahnya harus sama persis).

-- A. Jalankan di database SUMBER (dump-adventureworks)
USE `dump-adventureworks`;

SELECT 'stg_salesperson' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salesperson
UNION ALL
SELECT 'stg_salespersonquotahistory' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salespersonquotahistory
UNION ALL
SELECT 'stg_salesterritory' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salesterritory
UNION ALL
SELECT 'stg_salesterritoryhistory' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salesterritoryhistory
UNION ALL
SELECT 'stg_countryregion' AS staging, COUNT(*) AS jumlah_sumber FROM person_countryregion
UNION ALL
SELECT 'stg_person' AS staging, COUNT(*) AS jumlah_sumber FROM person_person
UNION ALL
SELECT 'stg_employee' AS staging, COUNT(*) AS jumlah_sumber FROM humanresources_employee
UNION ALL
SELECT 'stg_product' AS staging, COUNT(*) AS jumlah_sumber FROM production_product
UNION ALL
SELECT 'stg_productsubcategory' AS staging, COUNT(*) AS jumlah_sumber FROM production_productsubcategory
UNION ALL
SELECT 'stg_productcategory' AS staging, COUNT(*) AS jumlah_sumber FROM production_productcategory
UNION ALL
SELECT 'stg_salesorderheader' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salesorderheader
UNION ALL
SELECT 'stg_salesorderdetail' AS staging, COUNT(*) AS jumlah_sumber FROM sales_salesorderdetail;


-- B. Jalankan di database DW (adn_kl4-v2)
USE `adn_kl4-v2`;

SELECT 'stg_salesperson' AS staging, COUNT(*) AS jumlah_staging FROM stg_salesperson
UNION ALL
SELECT 'stg_salespersonquotahistory' AS staging, COUNT(*) AS jumlah_staging FROM stg_salespersonquotahistory
UNION ALL
SELECT 'stg_salesterritory' AS staging, COUNT(*) AS jumlah_staging FROM stg_salesterritory
UNION ALL
SELECT 'stg_salesterritoryhistory' AS staging, COUNT(*) AS jumlah_staging FROM stg_salesterritoryhistory
UNION ALL
SELECT 'stg_countryregion' AS staging, COUNT(*) AS jumlah_staging FROM stg_countryregion
UNION ALL
SELECT 'stg_person' AS staging, COUNT(*) AS jumlah_staging FROM stg_person
UNION ALL
SELECT 'stg_employee' AS staging, COUNT(*) AS jumlah_staging FROM stg_employee
UNION ALL
SELECT 'stg_product' AS staging, COUNT(*) AS jumlah_staging FROM stg_product
UNION ALL
SELECT 'stg_productsubcategory' AS staging, COUNT(*) AS jumlah_staging FROM stg_productsubcategory
UNION ALL
SELECT 'stg_productcategory' AS staging, COUNT(*) AS jumlah_staging FROM stg_productcategory
UNION ALL
SELECT 'stg_salesorderheader' AS staging, COUNT(*) AS jumlah_staging FROM stg_salesorderheader
UNION ALL
SELECT 'stg_salesorderdetail' AS staging, COUNT(*) AS jumlah_staging FROM stg_salesorderdetail;