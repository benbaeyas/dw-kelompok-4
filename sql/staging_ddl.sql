-- Tabel staging: salinan apa adanya dari sumber, tanpa PK/constraint (aturan staging pekan 12).
-- Aman dijalankan berulang: tabel staging dibuang lalu dibuat ulang (isinya diisi ulang oleh t01).
-- Lebar kolom teks mengikuti sumber (varchar(100)).
-- Kolom tanggal bertipe DATE; t01 membacanya sebagai teks 'YYYY-MM-DD' agar tidak bergeser zona waktu.
DROP TABLE IF EXISTS stg_salesperson;
CREATE TABLE stg_salesperson (
    businessentityid INT NOT NULL, territoryid INT NULL,
    salesquota DECIMAL(19,4) NULL, bonus DECIMAL(19,4) NULL, commissionpct DECIMAL(10,4) NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_salespersonquotahistory;
CREATE TABLE stg_salespersonquotahistory (
    businessentityid INT NOT NULL, quotadate DATE NOT NULL, salesquota DECIMAL(19,4) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_salesterritory;
CREATE TABLE stg_salesterritory (
    territoryid INT NOT NULL, name VARCHAR(100) NOT NULL, countryregioncode VARCHAR(3) NULL, grup VARCHAR(50) NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_salesterritoryhistory;
CREATE TABLE stg_salesterritoryhistory (
    businessentityid INT NOT NULL, territoryid INT NOT NULL, startdate DATE NOT NULL, enddate DATE NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_countryregion;
CREATE TABLE stg_countryregion (
    countryregioncode VARCHAR(3) NOT NULL, name VARCHAR(100) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_person;
CREATE TABLE stg_person (
    businessentityid INT NOT NULL, firstname VARCHAR(100) NULL, middlename VARCHAR(100) NULL, lastname VARCHAR(100) NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_employee;
CREATE TABLE stg_employee (
    businessentityid INT NOT NULL, jobtitle VARCHAR(50) NULL, hiredate DATE NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_product;
CREATE TABLE stg_product (
    productid INT NOT NULL, name VARCHAR(100) NOT NULL, productnumber VARCHAR(25) NOT NULL,
    listprice DECIMAL(19,4) NULL, productsubcategoryid INT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_productsubcategory;
CREATE TABLE stg_productsubcategory (
    productsubcategoryid INT NOT NULL, productcategoryid INT NOT NULL, name VARCHAR(100) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_productcategory;
CREATE TABLE stg_productcategory (
    productcategoryid INT NOT NULL, name VARCHAR(100) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_salesorderheader;
CREATE TABLE stg_salesorderheader (
    salesorderid INT NOT NULL, orderdate DATE NOT NULL, salespersonid INT NULL, territoryid INT NULL,
    onlineorderflag TINYINT NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
DROP TABLE IF EXISTS stg_salesorderdetail;
CREATE TABLE stg_salesorderdetail (
    salesorderid INT NOT NULL, salesorderdetailid INT NOT NULL, productid INT NOT NULL,
    orderqty INT NOT NULL, unitprice DECIMAL(19,4) NOT NULL, unitpricediscount DECIMAL(10,4) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
