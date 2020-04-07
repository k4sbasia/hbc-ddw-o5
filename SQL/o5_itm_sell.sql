REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:O5_ITEM_SELL.SQL
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                JAYANTHI DUDALA             10/20/2011       CREATED
REM ############################################################################
set timing on
--Appended this merge from biwhfact.sh script
---change level 2010:07:19 --  update the new partitioned date itm fact table
MERGE INTO o5.bi_date_itm_fact hst
   USING (SELECT   TRUNC (w.add_dt - 1) added, w.upc, p.department_id,
                   SUM (w.wh_backorder_qty) backorder_qty,
                   SUM (w.wh_sellable_qty) sell_qty
              FROM o5.bi_whqty_wrk w, o5.bi_product p
             WHERE w.upc = p.upc
--  and   P.upc = '0058665142122'
          GROUP BY TRUNC (w.add_dt - 1), w.upc, p.department_id) trn
   ON (    hst.actv_dt = trn.added
       AND hst.itm_upc_num = trn.upc
       AND hst.department_id = trn.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.wh_backorder_qty = trn.backorder_qty,
             hst.wh_sellable_qty = trn.sell_qty
   WHEN NOT MATCHED THEN
      INSERT (actv_dt, itm_upc_num, department_id, recv_qty, wh_backorder_qty,
              wh_sellable_qty)
      VALUES (trn.added, trn.upc, trn.department_id, 0, trn.backorder_qty,
              trn.sell_qty);
commit;

TRUNCATE TABLE o5.bi_bkorder_dmd_wrk;
INSERT/*+ append */ INTO o5.bi_bkorder_dmd_wrk
   SELECT   tmp.actv_dt, tmp.upc, tmp.department_id, tmp.vendor_id, tmp.item,
            SUM (tmp.backorder_dmd), SUM (tmp.backorder_qty)
       FROM (SELECT TRUNC (SYSDATE - 1) actv_dt,h.upc, h.department_id,
                    h.vendor_id, h.item,
                    (CASE
                        WHEN LTRIM (RTRIM (g.ordline_status)) NOT IN
                                                              ('K', 'N', 'V')
                           THEN 0
                        WHEN g.ordhdr_status = 'N'
                           THEN 0
                        ELSE g.extend_price_amt
                     END
                    ) backorder_dmd,
                    (CASE
                        WHEN LTRIM (RTRIM (g.ordline_status)) NOT IN
                                                              ('K', 'N', 'V')
                           THEN 0
                        WHEN g.ordhdr_status = 'N'
                           THEN 0
                        ELSE g.qtyordered
                     END
                    ) backorder_qty
               FROM o5.bi_sale g, o5.bi_product h
              WHERE TRUNC (orderdate) > '15-SEP-13'
                    AND g.bm_skuid = h.bm_skuid) tmp
   GROUP BY tmp.actv_dt, tmp.upc, tmp.department_id, tmp.vendor_id, tmp.item;
COMMIT ;
TRUNCATE TABLE o5.bi_psa_wrk;

-- add stores fullfilled 6 columns to bi_psa_wrk table 5/6/2013
INSERT/*+ append */ INTO o5.bi_psa_wrk
   SELECT   department_id, datekey, product_id, SUM (total_demand_dollars),
            SUM (total_demand_qty), SUM (sold_demand_dollars),
            SUM (sold_demand_qty), SUM (bord_demand_dollars),
            SUM (bord_demand_qty), SUM (cancel_dollars), SUM (cancel_qty),
            SUM (gross_dollars), SUM (gross_qty), SUM (return_dollars),
            SUM (return_qty), SUM (net_dollars), SUM(sfs_demand_qty),
            SUM(sfs_demand_dollars), SUM(sfs_sale_qty), SUM(sfs_sale_dollars),
            SUM(sfs_net_sale_qty), SUM(sfs_net_sale_dollars),
            SUM(giftorder_demand_qty),
            SUM(giftorder_demand_dollars), SUM(giftorder_sale_qty), SUM(giftorder_sale_dollars),
            SUM(giftorder_net_sale_qty), SUM(giftorder_net_sale_dollars)
       FROM o5.bi_psa
      WHERE datekey = TRUNC (SYSDATE - 1)
   GROUP BY department_id, datekey, product_id;
COMMIT ;
TRUNCATE TABLE o5.bi_psa_wh_wrk;
INSERT/*+ append */ INTO o5.bi_psa_wh_wrk
   SELECT   department_id, datekey, product_id, SUM (total_demand_dollars),
            SUM (total_demand_qty), SUM (sold_demand_dollars),
            SUM (sold_demand_qty), SUM (bord_demand_dollars),
            SUM (bord_demand_qty), SUM (cancel_dollars), SUM (cancel_qty),
            SUM (gross_dollars), SUM (gross_qty),
            SUM (NVL (return_dollars, 0)), SUM (NVL (return_qty, 0)),
            SUM (net_dollars)
       FROM o5.bi_psa_wh
      WHERE datekey = TRUNC (SYSDATE - 1)
   GROUP BY department_id, datekey, product_id;
COMMIT ;
----change level 2010:07:19 --- update new item sell table
-- add stores fullfilled 6 columns to bi_item_sell table 5/6/2013
MERGE INTO o5.bi_item_sell hst
   USING (SELECT b.datekey, TRIM (TO_CHAR (b.product_id, '0000000000000'))
                                                                          upc,
                 TRIM (TO_CHAR (b.department_id, '000')) department_no,
                 f.sku_list_price, b.total_demand_qty, b.total_demand_dollars,
                 b.bord_demand_qty, b.bord_demand_dollars, b.cancel_dollars,
                 b.gross_dollars, b.gross_qty, b.return_qty, b.return_dollars,
                 b.net_dollars, c.gross_qty gross_w_qty,
                 c.return_qty return_w_qty, c.return_dollars return_w_dollars,
                 c.net_dollars net_w_dollars, 0 recv_qty, f.item_cst_amt,
                 f.price_status, b.sfs_demand_qty, b.sfs_demand_dollars, b.sfs_sale_qty,
                 b.sfs_sale_dollars, b.sfs_net_sale_qty, b.sfs_net_sale_dollars,
                 b.giftorder_demand_qty, b.giftorder_demand_dollars, b.giftorder_sale_qty,
                 b.giftorder_sale_dollars, b.giftorder_net_sale_qty, b.giftorder_net_sale_dollars
            FROM o5.bi_psa_wrk b, o5.bi_psa_wh_wrk c, o5.bi_product f
           WHERE (    b.datekey = TRUNC (SYSDATE - 1)
                  AND (    b.datekey = c.datekey(+)
                       AND b.product_id = c.product_id(+)
                       AND b.department_id = c.department_id(+)
                      )
                  AND b.product_id = f.upc(+)                           -- and
                 )
                ) trn
   ON (trn.datekey = hst.datekey AND trn.upc = hst.upc AND trn.department_no = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.modify_dt = SYSDATE
   WHEN NOT MATCHED THEN
      INSERT (hst.datekey, hst.upc, hst.department_id, hst.sku_list_price,
              hst.total_demand_qty, hst.total_demand_dollars,
              hst.bord_demand_qty, hst.bord_demand_dollars,
              hst.cancel_dollars, hst.gross_dollars, hst.gross_qty,
              hst.return_qty, hst.return_dollars, hst.net_dollars,
              hst.gross_w_qty, hst.return_w_qty, hst.return_w_dollars,
              hst.net_w_dollars, hst.recv_qty, hst.item_cst_amt,
              hst.price_status, hst.modify_dt, hst.sfs_demand_qty, hst.sfs_demand_dollars,
              hst.sfs_sale_qty, hst.sfs_sale_dollars, hst.sfs_net_sale_qty,
              hst.sfs_net_sale_dollars,hst.giftorder_demand_qty, hst.giftorder_demand_dollars,
              hst.giftorder_sale_qty, hst.giftorder_sale_dollars, hst.giftorder_net_sale_qty,
              hst.giftorder_net_sale_dollars)
      VALUES (trn.datekey, trn.upc, trn.department_no, trn.sku_list_price,
              trn.total_demand_qty, trn.total_demand_dollars,
              trn.bord_demand_qty, trn.bord_demand_dollars,
              trn.cancel_dollars, trn.gross_dollars, trn.gross_qty,
              trn.return_qty, trn.return_dollars, trn.net_dollars,
              trn.gross_w_qty, trn.return_w_qty, trn.return_w_dollars,
              trn.net_w_dollars, trn.recv_qty, trn.item_cst_amt,
              trn.price_status,sysdate, trn.sfs_demand_qty, trn.sfs_demand_dollars,
              trn.sfs_sale_qty, trn.sfs_sale_dollars, trn.sfs_net_sale_qty,
              trn.sfs_net_sale_dollars,trn.giftorder_demand_qty, trn.giftorder_demand_dollars,
              trn.giftorder_sale_qty, trn.giftorder_sale_dollars, trn.giftorder_net_sale_qty,
              trn.giftorder_net_sale_dollars);
COMMIT ;
MERGE INTO o5.bi_date_itm_fact hst
   USING (SELECT   k.actv_dt datekey,
                   TRIM (TO_CHAR (k.upc, '0000000000000')) upc,
                   TRIM (TO_CHAR (k.department_id, '000')) department_id,
                   k.backorder_dmd, k.backorder_qty,
                   MIN (c.web_price) sku_sale_price
              FROM o5.bi_bkorder_dmd_wrk k, o5.o5_webprice_wrk c
             WHERE k.upc = c.upc                                        -- and
               AND (k.backorder_dmd > 0 OR k.backorder_qty > 0)
          --   and K.upc = '0058665142122'
          GROUP BY k.actv_dt,
                   TRIM (TO_CHAR (k.upc, '0000000000000')),
                   TRIM (TO_CHAR (k.department_id, '000')),
                   k.backorder_dmd,
                   k.backorder_qty) trn
   ON (    trn.datekey = hst.actv_dt
       AND trn.upc = hst.itm_upc_num
       AND trn.department_id = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.backorder_dmd = trn.backorder_dmd,
             hst.backorder_qty = trn.backorder_qty,
             hst.sku_sale_price = trn.sku_sale_price
   WHEN NOT MATCHED THEN
      INSERT (actv_dt, itm_upc_num, department_id, backorder_dmd,
              backorder_qty, sku_sale_price)
      VALUES (trn.datekey, trn.upc, trn.department_id, trn.backorder_dmd,
              trn.backorder_qty, trn.sku_sale_price);
COMMIT ;
MERGE INTO o5.bi_date_itm_fact hst
   USING (SELECT   k.actv_dt datekey, k.itm_upc_num, k.department_id,rownum,
                   MIN (c.sku_sale_price) sku_sale_price
              FROM o5.bi_date_itm_fact k, o5.bi_product c
             WHERE k.itm_upc_num = c.upc AND k.actv_dt = TRUNC (SYSDATE - 1)
          GROUP BY k.actv_dt, k.itm_upc_num, k.department_id,rownum) trn
   ON (    trn.datekey = hst.actv_dt
       AND trn.itm_upc_num = hst.itm_upc_num
       AND trn.department_id = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.sku_sale_price = trn.sku_sale_price
      ;
COMMIT ;
MERGE INTO o5.bi_date_itm_fact hst
   USING (SELECT   k.actv_dt datekey, k.itm_upc_num, k.department_id,rownum,
                   MIN (c.sku_sale_price) sku_sale_price
              FROM o5.bi_date_itm_fact k, o5.bi_product c
             WHERE k.itm_upc_num = c.upc
               AND k.actv_dt = TRUNC (SYSDATE - 1)
               AND k.sku_sale_price IS NULL
          GROUP BY k.actv_dt, k.itm_upc_num, k.department_id,rownum) trn
   ON (    trn.datekey = hst.actv_dt
       AND trn.itm_upc_num = hst.itm_upc_num
       AND trn.department_id = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.sku_sale_price = trn.sku_sale_price
      ;
COMMIT ;

merge into O5.BI_DATE_ITM_FACT HST
   using (select   K.ACTV_DT DATEKEY, K.ITM_UPC_NUM,
                 min (
                 case when C.UPC is not null
                  then C.OWN_RETL_AMT 
                  else K.SKU_SALE_PRICE
                  end )
              OWN_RETL_AMT
              from O5.BI_DATE_ITM_FACT K, O5.O5_WEBPRICE_WRK C
             where K.ITM_UPC_NUM = C.UPC(+)
               and K.ACTV_DT = TRUNC (sysdate - 1)
               and K.WH_SELLABLE_QTY > 0
          GROUP BY k.actv_dt, k.itm_upc_num) trn
   ON (    trn.datekey = hst.actv_dt
       AND trn.itm_upc_num = hst.itm_upc_num
       )
   WHEN MATCHED THEN
      update
         set HST.OWN_RETL_AMT = TRN.OWN_RETL_AMT;
COMMIT ;         
         
---change level 2011:06:02  add back missed routine from last update
MERGE INTO o5.bi_item_sell hst
   USING (SELECT i.actv_dt datekey,
                 TRIM (TO_CHAR (i.itm_upc_num, '0000000000000')) upc,
                 f.department_id, f.sku_list_price, 0 total_demand_qty,
                 0 total_demand_dollars, 0 bord_demand_qty,
                 0 bord_demand_dollars, 0 cancel_dollars, 0 gross_dollars,
                 0 gross_qty, 0 return_qty, 0 return_dollars, 0 net_dollars,
                 0 gross_w_qty, 0 return_w_qty, 0 return_w_dollars,
                 0 net_w_dollars, i.recv_qty, f.item_cst_amt, f.price_status
            FROM o5.bi_product f, o5.bi_date_itm_fact i
           WHERE i.actv_dt = TRUNC (SYSDATE - 1) and recv_qty>0 AND i.itm_upc_num = f.upc(+)) trn
   ON (    trn.datekey = hst.datekey
       AND trn.department_id = hst.department_id
       AND trn.upc = hst.upc)
   WHEN MATCHED THEN
      UPDATE
         SET hst.recv_qty = trn.recv_qty, hst.modify_dt = SYSDATE
   WHEN NOT MATCHED THEN
      INSERT (hst.datekey, hst.upc, hst.department_id, hst.sku_list_price,
              hst.total_demand_qty, hst.total_demand_dollars,
              hst.bord_demand_qty, hst.bord_demand_dollars,
              hst.cancel_dollars, hst.gross_dollars, hst.gross_qty,
              hst.return_qty, hst.return_dollars, hst.net_dollars,
              hst.gross_w_qty, hst.return_w_qty, hst.return_w_dollars,
              hst.net_w_dollars, hst.recv_qty, hst.item_cst_amt,
              hst.price_status)
      VALUES (trn.datekey, trn.upc, trn.department_id, trn.sku_list_price,
              trn.total_demand_qty, trn.total_demand_dollars,
              trn.bord_demand_qty, trn.bord_demand_dollars,
              trn.cancel_dollars, trn.gross_dollars, trn.gross_qty,
              trn.return_qty, trn.return_dollars, trn.net_dollars,
              trn.gross_w_qty, trn.return_w_qty, trn.return_w_dollars,
              trn.net_w_dollars, trn.recv_qty, trn.item_cst_amt,
              trn.price_status);
COMMIT ;

UPDATE sddw.bi_runstats
   SET target_count = (SELECT COUNT (*)
                         FROM o5.bi_item_sell
                        WHERE datekey = TRUNC (SYSDATE - 1)),
       modify_dt = SYSDATE
 WHERE TRUNC (add_dt) = TRUNC (SYSDATE)
   AND job_name = 'itm_sell'
   ;
COMMIT;

--Drop indexes on MV's MV_BI_ITEM_SELL
exec sddw.p_drop_INDEX_ON_MV('MV_O5_BI_ITEM_SELL');

--Refresh MV
exec dbms_mview.refresh ('SDDW.MV_O5_BI_ITEM_SELL','F');

--Create Indexes on MV
CREATE INDEX "SDDW"."MV_O5_PRT_DEPARTMENT_ID_IDX" ON "SDDW"."MV_O5_BI_ITEM_SELL"
  (
    "DEPARTMENT_ID"
  )
  PARALLEL (DEGREE 4);

Alter Index "SDDW"."MV_O5_PRT_DEPARTMENT_ID_IDX" PARALLEL 1;


CREATE INDEX "SDDW"."MV_O5_PRT_UPC_IDX" ON "SDDW"."MV_O5_BI_ITEM_SELL"
  (
    "UPC"
  )
    PARALLEL (DEGREE 4);

Alter Index "SDDW"."MV_O5_PRT_UPC_IDX"  PARALLEL 1;

CREATE INDEX "SDDW"."MV_O5_PRT_DATEKEY_IDX" ON "SDDW"."MV_O5_BI_ITEM_SELL"
  (
    "DATEKEY"
  )
    PARALLEL (DEGREE 4);

Alter Index "SDDW"."MV_O5_PRT_DATEKEY_IDX"  PARALLEL 1;

--Drop indexes on MV_O5_BI_DATE_ITM_FACT  MV's
exec sddw.p_drop_INDEX_ON_MV('MV_O5_BI_DATE_ITM_FACT');

--Refresh MV
exec dbms_mview.refresh ('SDDW.MV_O5_BI_DATE_ITM_FACT','F');

--Create Indexes on MV

CREATE INDEX "SDDW"."MV_O5_DATE_ITM_FACT_NEW_ITUPC" ON "SDDW"."MV_O5_BI_DATE_ITM_FACT"
  (
    "ITM_UPC_NUM"
  )
  PARALLEL (DEGREE 4);

Alter Index SDDW.MV_O5_DATE_ITM_FACT_NEW_ITUPC PARALLEL 1;

CREATE INDEX "SDDW"."MV_O5_DATE_ITM_FACT_NEW_DEPTID" ON "SDDW"."MV_O5_BI_DATE_ITM_FACT"
  (
    "DEPARTMENT_ID"
  )
  PARALLEL (DEGREE 4);

Alter Index SDDW.MV_O5_DATE_ITM_FACT_NEW_DEPTID PARALLEL 1;

show errors;
quit;
