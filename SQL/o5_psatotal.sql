set echo OFF 
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
-- sql from the psatotal.sh
TRUNCATE TABLE O5.bi_sumdates;
INSERT INTO O5.bi_sumdates
   SELECT DISTINCT transdate
              FROM (SELECT   transdate
                        FROM O5.bi_netsale
                       WHERE TRUNC (add_dt) = TRUNC (SYSDATE)
                    GROUP BY transdate
                    UNION
                    SELECT   /*+ index(a) */
                             TRUNC (orderdate) transdate
                        FROM O5.bi_sale a
                       WHERE TRUNC (ordline_modifydate) >= TRUNC (SYSDATE - 1)
                         AND TRUNC (orderdate) <> TRUNC (SYSDATE)
						  And Trunc (Orderdate) > (select nvl(fiscal_yearstartdate_ly,sysdate-300) from mrep.bi_datekey where datekey = trunc(sysdate)) 
                    GROUP BY TRUNC (orderdate));
COMMIT;

DELETE FROM O5.bi_psa a
      WHERE exists (select 1 from o5.bi_sumdates b  where a.datekey =  b.dte);                       
COMMIT;

INSERT INTO O5.bi_psa
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
                WHERE a.ordline_status = 'X'
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
                 WHERE a.skupc_ind IN ('S')
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
                 WHERE a.skupc_ind IN ('U')
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
-- add to update ship-from-store (sfs) columns
-- 05/15/2013
MERGE INTO O5.bi_psa c
USING  (SELECT  datekey, product_id, nvl(sum(sfs_demand_dollars), 0) sfs_demand_dollars, nvl(SUM(sfs_demand_qty), 0) sfs_demand_qty, 
        nvl(SUM(gross_dollars), 0) gross_dollars, nvl(SUM(gross_qty), 0) gross_qty,
        nvl(sum(return_dollars), 0) return_dollars, nvl(sum(return_qty), 0) return_qty, 
        nvl(SUM(gross_wh_dollars), 0) gross_wh_dollars, nvl(SUM(gross_wh_qty), 0) gross_wh_qty,
        nvl(sum(return_wh_dollars), 0) return_wh_dollars, nvl(sum(return_wh_qty), 0) return_wh_qty
FROM  (
SELECT  trunc(S.ORDERDATE) datekey, s.product_id,  
        SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (S.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN S.ordhdr_status = 'N'
                                 THEN 0
                              ELSE nvl(S.extend_price_amt, 0)
                           END
                          )
                         ) sfs_demand_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (S.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN S.ordhdr_status = 'N'
                                 THEN 0
                              ELSE nvl(S.qtyordered, 0)
                           END
                          )
                         ) sfs_demand_qty, 0 GROSS_QTY,  0 GROSS_DOLLARS, 0 RETURN_DOLLARS, 0 RETURN_QTY, 0 gross_wh_dollars, 0 gross_wh_qty, 0 return_wh_dollars, 0 return_wh_qty
FROM   O5.bi_sale s
where  S.FULLFILLLOCATION = 'STORES'
--and    B.PRODUCT_ID = '5045339377695'
and    trunc(S.ORDERDATE) IN (SELECT dte FROM O5.bi_sumdates)
group by  trunc(S.ORDERDATE) ,  s.product_id
UNION
SELECT  trunc(S.ORDERDATE) datekey, s.product_id, 0 sfs_demand_dollars, 0 sfs_demand_qty, 
	NVL (SUM (a.saleqty), 0) gross_qty,
        NVL (SUM (nvl(a.grosssale, 0) + nvl(a.salediscount, 0) + nvl(a.salemarkdown, 0)),
                    0
            ) gross_dollars,         
         NVL (SUM (  nvl(a.grossreturn, 0)
                    + nvl(a.returndiscount, 0)
                    + nvl(a.returnmarkdown, 0)
                   ),
               0
           ) return_dollars,
         NVL (SUM (a.returnqty), 0) return_qty, 0 gross_wh_dollars, 0 gross_wh_qty, 0 return_wh_dollars, 0 return_wh_qty
FROM   O5.bi_netsale a, O5.bi_sale s
where  S.FULLFILLLOCATION = 'STORES'
and    trunc(s.orderdate) IN (SELECT dte FROM O5.bi_sumdates)
and    S.PRODUCT_ID = A.UPC
and    S.ORDERNUM = A.BM_ORDERNUM  
--and    B.PRODUCT_ID = '5045339377695'
group BY trunc(S.ORDERDATE), s.product_id
UNION
SELECT trunc(S.ORDERDATE) datekey, s.product_id, 0 total_demand_qty, 0 total_demand_dollars, 0 GROSS_QTY,0 GROSS_DOLLARS, 0 RETURN_DOLLARS, 0 RETURN_QTY, 
        NVL (SUM (nvl(a.grosssale, 0) + nvl(a.salediscount, 0) + nvl(a.salemarkdown, 0)),
                            0
                           ) gross_wh_dollars,
                       NVL (SUM (a.saleqty), 0) gross_wh_qty,
                       NVL (SUM (  nvl(a.grossreturn, 0)
                                 + nvl(a.returndiscount, 0)
                                 + nvl(a.returnmarkdown, 0)
                                ),
                            0
                           ) return_wh_dollars,
                       NVL (SUM (a.returnqty), 0) return_wh_qty
FROM   O5.bi_sale s,  O5.bi_netsale a
where  S.FULLFILLLOCATION = 'STORES'
and    S.PRODUCT_ID = A.UPC
and    S.ORDERNUM = A.BM_ORDERNUM  
and    to_number(a.STORE) = 789
and    s.fill_loc = 'T'
--and    B.PRODUCT_ID = '5045339377695'
and    trunc(S.ORDERDATE) IN (SELECT dte FROM O5.bi_sumdates)
GROUP BY trunc(S.ORDERDATE), s.product_id)
GROUP BY datekey, product_id) t
ON (t.datekey = c.datekey and t.product_id = c.product_id)
WHEN MATCHED THEN UPDATE SET   
       c.SFS_DEMAND_QTY = t.sfs_demand_qty,
       c.SFS_DEMAND_DOLLARS = t.sfs_demand_dollars,
       c.SFS_SALE_QTY = t.gross_wh_qty - t.return_wh_qty,
       c.SFS_SALE_DOLLARS = t.gross_wh_dollars + t.return_wh_dollars,
       c.SFS_NET_SALE_QTY = t.gross_qty - t.return_qty,
       c.SFS_NET_SALE_DOLLARS = t.gross_dollars + t.return_dollars;

commit;

-- add to New columns for gift_order sales
-- 05/01/2014

MERGE INTO O5.bi_psa c
USING  (SELECT  datekey, product_id, nvl(sum(giftorder_demand_dollars), 0) giftorder_demand_dollars, nvl(SUM(giftorder_demand_qty), 0) giftorder_demand_qty, 
        nvl(SUM(gross_dollars), 0) gross_dollars, nvl(SUM(gross_qty), 0) gross_qty,
        nvl(sum(return_dollars), 0) return_dollars, nvl(sum(return_qty), 0) return_qty, 
        nvl(SUM(gross_wh_dollars), 0) gross_wh_dollars, nvl(SUM(gross_wh_qty), 0) gross_wh_qty,
        nvl(sum(return_wh_dollars), 0) return_wh_dollars, nvl(sum(return_wh_qty), 0) return_wh_qty
FROM  (
SELECT  trunc(S.ORDERDATE) datekey, s.product_id,  
        SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (S.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN S.ordhdr_status = 'N'
                                 THEN 0
                              ELSE nvl(S.extend_price_amt, 0)
                           END
                          )
                         ) giftorder_demand_dollars,
                      SUM
                         ((CASE
                              WHEN LTRIM (RTRIM (S.ordline_status)) IN
                                                              ('T', 'M', 'Q')
                                 THEN 0
                              WHEN S.ordhdr_status = 'N'
                                 THEN 0
                              ELSE nvl(S.qtyordered, 0)
                           END
                          )
                         ) giftorder_demand_qty, 0 GROSS_QTY,  0 GROSS_DOLLARS, 0 RETURN_DOLLARS, 0 RETURN_QTY, 0 gross_wh_dollars, 0 gross_wh_qty, 0 return_wh_dollars, 0 return_wh_qty
FROM   O5.bi_sale s
where  s.giftorder_ind = 1
and    trunc(S.ORDERDATE) IN (SELECT dte FROM O5.bi_sumdates)
group by  trunc(S.ORDERDATE) ,  s.product_id
UNION
SELECT  trunc(S.ORDERDATE) datekey, s.product_id, 0 giftorder_demand_dollars, 0 giftorder_demand_qty, 
	NVL (SUM (a.saleqty), 0) gross_qty,
        NVL (SUM (nvl(a.grosssale, 0) + nvl(a.salediscount, 0) + nvl(a.salemarkdown, 0)),
                    0
            ) gross_dollars,         
         NVL (SUM (  nvl(a.grossreturn, 0)
                    + nvl(a.returndiscount, 0)
                    + nvl(a.returnmarkdown, 0)
                   ),
               0
           ) return_dollars,
         NVL (SUM (a.returnqty), 0) return_qty, 0 gross_wh_dollars, 0 gross_wh_qty, 0 return_wh_dollars, 0 return_wh_qty
FROM   O5.bi_netsale a, O5.bi_sale s
where  s.giftorder_ind = 1
and    trunc(s.orderdate) IN (SELECT dte FROM O5.bi_sumdates)
and    S.PRODUCT_ID = A.UPC
and    S.ORDERNUM = A.BM_ORDERNUM  
group BY trunc(S.ORDERDATE), s.product_id
UNION
SELECT trunc(S.ORDERDATE) datekey, s.product_id, 0 total_demand_qty, 0 total_demand_dollars, 0 GROSS_QTY,0 GROSS_DOLLARS, 0 RETURN_DOLLARS, 0 RETURN_QTY, 
        NVL (SUM (nvl(a.grosssale, 0) + nvl(a.salediscount, 0) + nvl(a.salemarkdown, 0)),
                            0
                           ) gross_wh_dollars,
                       NVL (SUM (a.saleqty), 0) gross_wh_qty,
                       NVL (SUM (  nvl(a.grossreturn, 0)
                                 + nvl(a.returndiscount, 0)
                                 + nvl(a.returnmarkdown, 0)
                                ),
                            0
                           ) return_wh_dollars,
                       NVL (SUM (a.returnqty), 0) return_wh_qty
FROM   O5.bi_sale s,  O5.bi_netsale a
where  s.giftorder_ind = 1
and    S.PRODUCT_ID = A.UPC
and    S.ORDERNUM = A.BM_ORDERNUM  
and    to_number(a.STORE) = 789
and    s.fill_loc = 'T'
and    trunc(S.ORDERDATE) IN (SELECT dte FROM O5.bi_sumdates)
GROUP BY trunc(S.ORDERDATE), s.product_id)
GROUP BY datekey, product_id) t
ON (t.datekey = c.datekey and t.product_id = c.product_id)
WHEN MATCHED THEN UPDATE SET   
       c.giftorder_DEMAND_QTY = t.giftorder_demand_qty,
       c.giftorder_DEMAND_DOLLARS = t.giftorder_demand_dollars,
       c.giftorder_SALE_QTY = t.gross_wh_qty - t.return_wh_qty,
       c.giftorder_SALE_DOLLARS = t.gross_wh_dollars + t.return_wh_dollars,
       c.giftorder_NET_SALE_QTY = t.gross_qty - t.return_qty,
       c.giftorder_NET_SALE_DOLLARS = t.gross_dollars + t.return_dollars;

commit;

exit;
