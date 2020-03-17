set echo off
set feedback on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set serverout on
set timing on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
--sql from psastore.sh
DELETE FROM O5.bi_psa_stores
      WHERE datekey IN (SELECT dte
                          FROM O5.bi_sumdates);
commit;
INSERT INTO O5.bi_psa_stores
            (fiscal_year, fiscalmonth, division_id, GROUP_ID, department_id,
             datekey, product_id, total_demand_dollars, total_demand_qty,
             sold_demand_dollars, sold_demand_qty, bord_demand_dollars,
             bord_demand_qty, cancel_dollars, cancel_qty, gross_dollars,
             gross_qty, return_dollars, return_qty, net_dollars)
   SELECT   fiscal_year, fiscalmonth, division_id, GROUP_ID, department_id,
            datekey, product_id,
            SUM (total_demand_dollars) total_demand_dollars,
            SUM (total_demand_qty) total_demand_qty,
            SUM (sold_demand_dollars) sold_demand_dollars,
            SUM (sold_demand_qty) sold_demand_qty,
            SUM (bord_demand_dollars) bord_demand_dollars,
            SUM (bord_demand_qty) bord_demand_qty,
            SUM (cancel_dollars) cancel_dollars, SUM (cancel_qty) cancel_qty,
            SUM (gross_dollars) gross_dollars, SUM (gross_qty) gross_qty,
            SUM (return_dollars) return_dollars, SUM (return_qty) return_qty,
            SUM (net_dollars) net_dollars
       FROM (SELECT   c.fiscal_year, c.fiscalmonth,
                      TO_NUMBER (b.division_id) division_id,
                      TO_NUMBER (b.GROUP_ID) GROUP_ID,
                      TO_NUMBER (b.department_id) department_id,
                      TRUNC (a.orderdate) datekey,
                      COALESCE (b.product_id, '0') product_id,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE a.extend_price_amt
                           END
                          )
                         ) total_demand_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE a.qtyordered
                           END
                          )
                         ) total_demand_qty,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN a.backorder_ind IS NULL
                                        OR UPPER
                                              (TRIM (BOTH FROM a.backorder_ind)
                                              ) = 'F'
                                          THEN a.extend_price_amt
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) sold_demand_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN a.backorder_ind IS NULL
                                        OR UPPER
                                              (TRIM (BOTH FROM a.backorder_ind)
                                              ) = 'F'
                                          THEN a.qtyordered
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) sold_demand_qty,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN UPPER
                                              (TRIM (BOTH FROM a.backorder_ind)
                                              ) = 'T'
                                          THEN a.extend_price_amt
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) bord_demand_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN UPPER
                                              (TRIM (BOTH FROM a.backorder_ind)
                                              ) = 'T'
                                          THEN a.qtyordered
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) bord_demand_qty,
                      0 cancel_dollars, 0 cancel_qty, 0 gross_dollars,
                      0 gross_qty, 0 return_dollars, 0 return_qty,
                      0 net_dollars
                 FROM O5.bi_sale a
                      INNER JOIN
                      (SELECT fiscal_year fiscal_year,
                              fiscalmonth fiscalmonth, datekey datekey
                         FROM O5.bi_datekey
                        WHERE datekey IN (SELECT dte
                                            FROM O5.bi_sumdates)) c
                      ON TRUNC (a.orderdate) = c.datekey
                      LEFT JOIN
                      (SELECT   bm_skuid bm_skuid, MAX (item) item,
                                MAX (upc) product_id,
                                TO_NUMBER (MAX (division_id)) division_id,
                                TO_NUMBER (MAX (department_id)) department_id,
                                TO_NUMBER (MAX (GROUP_ID)) GROUP_ID
                           FROM O5.bi_product
                       GROUP BY bm_skuid) b ON a.bm_skuid = b.bm_skuid
                WHERE TRIM (a.fill_loc) <> 'T'
             GROUP BY TRUNC (a.orderdate),
                      c.fiscal_year,
                      c.fiscalmonth,
                      TO_NUMBER (b.division_id),
                      TO_NUMBER (b.GROUP_ID),
                      TO_NUMBER (b.department_id),
                      b.product_id
             UNION
             SELECT   c.fiscal_year, c.fiscalmonth,
                      TO_NUMBER (b.division_id) division_id,
                      TO_NUMBER (b.GROUP_ID) GROUP_ID,
                      TO_NUMBER (b.department_id) department_id,
                      TRUNC (a.ordline_modifydate) datekey,
                      COALESCE (b.product_id, '0') product_id, 0, 0, 0, 0, 0,
                      0,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                                   ('T', 'M')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN UPPER
                                              (TRIM
                                                   (BOTH FROM a.ordline_status)
                                              ) = 'X'
                                          THEN a.extend_price_amt
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) cancel_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (a.ordline_status)) IN
                                                                   ('T', 'M')
                                 THEN 0
                              WHEN a.ordhdr_status = 'N'
                                 THEN 0
                              ELSE (CASE
                                       WHEN UPPER
                                              (TRIM
                                                   (BOTH FROM a.ordline_status)
                                              ) = 'X'
                                          THEN a.qtyordered
                                       ELSE 0
                                    END
                                   )
                           END
                          )
                         ) cancel_qty,
                      0 gross_dollars, 0 gross_qty, 0 return_dollars,
                      0 return_qty, 0 net_dollars
                 FROM O5.bi_sale a
                      INNER JOIN
                      (SELECT fiscal_year fiscal_year,
                              fiscalmonth fiscalmonth, datekey datekey
                         FROM O5.bi_datekey
                        WHERE datekey IN (SELECT dte
                                            FROM O5.bi_sumdates)) c
                      ON TRUNC (a.ordline_modifydate) = c.datekey
                      LEFT JOIN
                      (SELECT   bm_skuid bm_skuid, MAX (item) item,
                                MAX (upc) product_id,
                                TO_NUMBER (MAX (division_id)) division_id,
                                TO_NUMBER (MAX (department_id)) department_id,
                                TO_NUMBER (MAX (GROUP_ID)) GROUP_ID
                           FROM O5.bi_product
                       GROUP BY bm_skuid) b ON a.bm_skuid = b.bm_skuid
                WHERE a.ordline_status = 'X' AND TRIM (a.fill_loc) <> 'T'
             GROUP BY TRUNC (a.ordline_modifydate),
                      c.fiscal_year,
                      c.fiscalmonth,
                      TO_NUMBER (b.division_id),
                      TO_NUMBER (b.GROUP_ID),
                      TO_NUMBER (b.department_id),
                      b.product_id
             UNION
             (SELECT   c.fiscal_year, c.fiscalmonth,
                       TO_NUMBER (b.division_id) division_id,
                       TO_NUMBER (b.GROUP_ID) GROUP_ID,
                       TO_NUMBER (b.department_id) department_id,
                       TRUNC (a.transdate) datekey, b.product_id product_id,
                       0, 0, 0, 0, 0, 0, 0, 0,
                       NVL (SUM (a.grosssale + a.salediscount + a.salemarkdown),
                            0
                           ) gross_dollars,
                       NVL (SUM (a.saleqty), 0) gross_qty,
                       NVL (SUM (  a.grossreturn
                                 + a.returndiscount
                                 + a.returnmarkdown
                                ),
                            0
                           ) return_dollars,
                       NVL (SUM (a.returnqty), 0) return_qty,
                       NVL (SUM (  a.grosssale
                                 + a.grossreturn
                                 + a.salediscount
                                 + a.returndiscount
                                 + a.salemarkdown
                                 + a.returnmarkdown
                                ),
                            0
                           ) net_dollars
                  FROM O5.bi_netsale a
                       INNER JOIN
                       (SELECT fiscal_year fiscal_year,
                               fiscalmonth fiscalmonth, datekey datekey
                          FROM O5.bi_datekey
                         WHERE datekey IN (SELECT dte
                                             FROM O5.bi_sumdates)) c
                       ON TRUNC (a.transdate) = c.datekey
                       LEFT JOIN
                       (SELECT   sku sku, MAX (item) item,
                                 MAX (upc) product_id,
                                 TO_NUMBER (MAX (division_id)) division_id,
                                 TO_NUMBER (MAX (department_id))
                                                                department_id,
                                 TO_NUMBER (MAX (GROUP_ID)) GROUP_ID
                            FROM O5.bi_product
                        GROUP BY sku) b ON a.sku = b.sku
                 WHERE a.skupc_ind IN ('S') AND TO_NUMBER (a.STORE) <> 789
              GROUP BY c.fiscal_year,
                       c.fiscalmonth,
                       TO_NUMBER (b.division_id),
                       TO_NUMBER (b.GROUP_ID),
                       TO_NUMBER (b.department_id),
                       TRUNC (a.transdate),
                       b.product_id
              UNION
              SELECT   c.fiscal_year, c.fiscalmonth,
                       TO_NUMBER (u.division_id) division_id,
                       TO_NUMBER (u.GROUP_ID) GROUP_ID,
                       TO_NUMBER (u.department_id) department_id,
                       TRUNC (a.transdate) datekey, u.product_id product_id,
                       0, 0, 0, 0, 0, 0, 0, 0,
                       NVL (SUM (a.grosssale + a.salediscount + a.salemarkdown),
                            0
                           ) gross_dollars,
                       NVL (SUM (a.saleqty), 0) gross_qty,
                       NVL (SUM (  a.grossreturn
                                 + a.returndiscount
                                 + a.returnmarkdown
                                ),
                            0
                           ) return_dollars,
                       NVL (SUM (a.returnqty), 0) return_qty,
                       NVL (SUM (  a.grosssale
                                 + a.grossreturn
                                 + a.salediscount
                                 + a.returndiscount
                                 + a.salemarkdown
                                 + a.returnmarkdown
                                ),
                            0
                           ) net_dollars
                  FROM O5.bi_netsale a
                       INNER JOIN
                       (SELECT fiscal_year fiscal_year,
                               fiscalmonth fiscalmonth, datekey datekey
                          FROM O5.bi_datekey
                         WHERE datekey IN (SELECT dte
                                             FROM O5.bi_sumdates)) c
                       ON TRUNC (a.transdate) = c.datekey
                       LEFT JOIN
                       (SELECT sku sku, item item, upc product_id,
                               TO_NUMBER (division_id) division_id,
                               TO_NUMBER (department_id) department_id,
                               TO_NUMBER (GROUP_ID) GROUP_ID
                          FROM O5.bi_product) u ON a.upc = u.product_id
                 WHERE a.skupc_ind IN ('U') AND TO_NUMBER (a.STORE) <> 789
              GROUP BY c.fiscal_year,
                       c.fiscalmonth,
                       TO_NUMBER (u.division_id),
                       TO_NUMBER (u.GROUP_ID),
                       TO_NUMBER (u.department_id),
                       TRUNC (a.transdate),
                       u.product_id)
             UNION
             SELECT   c.fiscal_year, c.fiscalmonth,
                      TO_NUMBER (b.division_id) division_id,
                      TO_NUMBER (b.GROUP_ID) GROUP_ID,
                      TO_NUMBER (b.department_id) department_id,
                      TRUNC (a.transdate) datekey, a.upc product_id, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      NVL (SUM (a.grosssale + a.salediscount + a.salemarkdown),
                           0
                          ) gross_dollars,
                      NVL (SUM (a.saleqty), 0) gross_qty,
                      NVL (SUM (  a.grossreturn
                                + a.returndiscount
                                + a.returnmarkdown
                               ),
                           0
                          ) return_dollars,
                      NVL (SUM (a.returnqty), 0) return_qty,
                      NVL (SUM (  a.grosssale
                                + a.grossreturn
                                + a.salediscount
                                + a.returndiscount
                                + a.salemarkdown
                                + a.returnmarkdown
                               ),
                           0
                          ) net_dollars
                 FROM O5.bi_netsale a
                      INNER JOIN
                      (SELECT fiscal_year fiscal_year,
                              fiscalmonth fiscalmonth, datekey datekey
                         FROM O5.bi_datekey
                        WHERE datekey IN (SELECT dte
                                            FROM O5.bi_sumdates)) c
                      ON TRUNC (a.transdate) = c.datekey
                      LEFT JOIN
                      (SELECT   department_id department_id,
                                SUBSTR
                                   ((MAX (   TRIM (TO_CHAR (modify_dt,
                                                            'YYYY-MM-DD'
                                                           )
                                                  )
                                          || TRIM (TO_CHAR (division_id, '0'))
                                          || TRIM (TO_CHAR (GROUP_ID, '000'))
                                          || TRIM (TO_CHAR (department_id,
                                                            '000'
                                                           )
                                                  )
                                         )
                                    ),
                                    11,
                                    1
                                   ) division_id,
                                SUBSTR
                                   ((MAX (   TRIM (TO_CHAR (modify_dt,
                                                            'YYYY-MM-DD'
                                                           )
                                                  )
                                          || TRIM (TO_CHAR (division_id, '0'))
                                          || TRIM (TO_CHAR (GROUP_ID, '000'))
                                          || TRIM (TO_CHAR (department_id,
                                                            '000'
                                                           )
                                                  )
                                         )
                                    ),
                                    12,
                                    3
                                   ) GROUP_ID
                           FROM mrep.bi_merch_hier
                       GROUP BY department_id) b
                      ON TO_NUMBER (a.department) =
                                                   TO_NUMBER (b.department_id)
                WHERE a.skupc_ind NOT IN ('S', 'U')
                  AND TO_NUMBER (a.department) > 0
                  AND TO_NUMBER (a.STORE) <> 789
             GROUP BY c.fiscal_year,
                      c.fiscalmonth,
                      TO_NUMBER (b.division_id),
                      TO_NUMBER (b.GROUP_ID),
                      TO_NUMBER (b.department_id),
                      TRUNC (a.transdate),
                      a.upc)
   GROUP BY fiscal_year,
            fiscalmonth,
            division_id,
            GROUP_ID,
            department_id,
            datekey,
            product_id;
commit;
exit;
