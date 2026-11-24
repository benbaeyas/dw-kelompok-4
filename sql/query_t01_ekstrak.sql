-- t01_ekstrak: satu pasang Table input (koneksi: dump-adventureworks_kel4) -> Table output (koneksi: adn_kl4-v2, Truncate table).

-- ke stg_salesperson
SELECT businessentityid, territoryid, salesquota, bonus, commissionpct
FROM sales_salesperson;

-- ke stg_salespersonquotahistory
SELECT businessentityid,
       DATE_FORMAT(quotadate, '%Y-%m-%d') AS quotadate,
       salesquota
FROM sales_salespersonquotahistory;

-- ke stg_salesterritory
SELECT territoryid, name, countryregioncode, `Group` AS grup
FROM sales_salesterritory;

-- ke stg_salesterritoryhistory
SELECT businessentityid, territoryid,
       DATE_FORMAT(startdate, '%Y-%m-%d') AS startdate,
       DATE_FORMAT(enddate, '%Y-%m-%d') AS enddate
FROM sales_salesterritoryhistory;

-- ke stg_countryregion
SELECT countryregioncode, name
FROM person_countryregion;

-- ke stg_person
SELECT businessentityid, firstname, middlename, lastname
FROM person_person;

-- ke stg_employee
SELECT businessentityid, jobtitle,
       DATE_FORMAT(hiredate, '%Y-%m-%d') AS hiredate
FROM humanresources_employee;

-- ke stg_product
SELECT productid, name, productnumber, listprice, productsubcategoryid
FROM production_product;

-- ke stg_productsubcategory
SELECT productsubcategoryid, productcategoryid, name
FROM production_productsubcategory;

-- ke stg_productcategory
SELECT productcategoryid, name
FROM production_productcategory;

-- ke stg_salesorderheader
SELECT salesorderid,
       DATE_FORMAT(orderdate, '%Y-%m-%d') AS orderdate,
       salespersonid, territoryid,
       CAST(onlineorderflag AS UNSIGNED) AS onlineorderflag
FROM sales_salesorderheader;

-- ke stg_salesorderdetail
SELECT salesorderid, salesorderdetailid, productid, orderqty, unitprice, unitpricediscount
FROM sales_salesorderdetail;

