-- t03_dim_produk
-- Query yang sama persis dengan yang ada di Table input transformasi terkait (koneksi: adn_kl4-v2).

SELECT p.productid                              AS product_id,
       p.name                                   AS nama_produk,
       p.productnumber                          AS nomor_produk,
       COALESCE(ps.name, 'Tanpa Sub Kategori')  AS sub_kategori,
       COALESCE(pc.name, 'Tanpa Kategori')      AS kategori,
       COALESCE(p.listprice, 0)                 AS list_price
FROM stg_product p
LEFT JOIN stg_productsubcategory ps ON ps.productsubcategoryid = p.productsubcategoryid
LEFT JOIN stg_productcategory    pc ON pc.productcategoryid    = ps.productcategoryid
ORDER BY p.productid;
