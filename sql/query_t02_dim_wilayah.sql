-- t02_dim_wilayah
-- Query yang sama persis dengan yang ada di Table input transformasi terkait (koneksi: adn_kl4-v2).

SELECT t.territoryid                          AS territory_id,
       t.name                                 AS nama_wilayah,
       COALESCE(t.countryregioncode, 'N/A')   AS kode_negara,
       COALESCE(c.name, 'Tidak diketahui')    AS nama_negara,
       COALESCE(t.grup, 'Tidak diketahui')    AS grup_wilayah,
       CASE WHEN EXISTS (SELECT 1 FROM stg_salesperson sp
                         WHERE sp.territoryid = t.territoryid)
              OR EXISTS (SELECT 1 FROM stg_salesterritoryhistory h
                         WHERE h.territoryid = t.territoryid AND h.enddate IS NULL)
            THEN 1 ELSE 0 END                 AS is_active
FROM stg_salesterritory t
LEFT JOIN stg_countryregion c ON c.countryregioncode = t.countryregioncode
ORDER BY t.territoryid;
