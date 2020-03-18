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
INSERT INTO O5.bi_runstats
   SELECT 'O5_BIITMSELADJ.SH' job_name,
          INITCAP (TO_CHAR (SYSDATE, 'MONDD')) load_dt,
          TO_CHAR (SYSDATE, 'HH24:MI P.M.') load_tm, 0 sfile_size,
          'Update item sell from psa psa wh EOM Update' file_name,
          0 load_count, 0 file_count, 0 tfile_size, SYSDATE add_dt,
          NULL modify_dt, 0 source_count, 0 target_count
     FROM DUAL;
COMMIT ;
--  get dates associated with netsales adjustments    ----------
TRUNCATE TABLE O5.bi_sumdates_is;
INSERT INTO O5.bi_sumdates_is
   SELECT DISTINCT datekey
              FROM O5.bi_psa
             WHERE TRUNC (add_dt) = TRUNC (SYSDATE)
               AND datekey <> TRUNC (SYSDATE);
COMMIT ;
 ---- change level 2009:09:01  - add work tables to make the merge use less resource
  -- extract psa data
TRUNCATE TABLE O5.bi_psa_wrk;
COMMIT ;
INSERT/*+ append */ INTO O5.bi_psa_wrk
(department_id, datekey, product_id,total_demand_dollars, total_demand_qty,sold_demand_dollars,
sold_demand_qty,bord_demand_dollars, bord_demand_qty,cancel_dollars,cancel_qty,
gross_dollars,gross_qty,return_dollars,return_qty,net_dollars, sfs_demand_qty, sfs_demand_dollars,  
sfs_sale_qty,  sfs_sale_dollars, sfs_net_sale_qty, sfs_net_sale_dollars,GIFTORDER_DEMAND_QTY,GIFTORDER_DEMAND_DOLLARS, GIFTORDER_SALE_QTY, GIFTORDER_SALE_DOLLARS, 
            giftorder_net_sale_qty, giftorder_net_sale_dollars
)
   SELECT   department_id, datekey, product_id, SUM (total_demand_dollars),
            SUM (total_demand_qty), SUM (sold_demand_dollars),
            SUM (sold_demand_qty), SUM (bord_demand_dollars),
            SUM (bord_demand_qty), SUM (cancel_dollars), SUM (cancel_qty),
            SUM (gross_dollars), SUM (gross_qty), SUM (return_dollars),
            SUM (return_qty), SUM (net_dollars),SUM (sfs_demand_qty), 
            SUM (sfs_demand_dollars),  SUM (sfs_sale_qty),  SUM (sfs_sale_dollars), 
            SUM (sfs_net_sale_qty), SUM (sfs_net_sale_dollars),SUM (giftorder_demand_qty), 
            SUM (giftorder_demand_dollars),  SUM (giftorder_sale_qty),  SUM (giftorder_sale_dollars), 
            SUM (giftorder_net_sale_qty), SUM (giftorder_net_sale_dollars)
       FROM O5.bi_psa, O5.bi_sumdates_is
      WHERE datekey = dte AND dte <> TRUNC (SYSDATE - 1)
   GROUP BY department_id, datekey, product_id;
COMMIT ;
TRUNCATE TABLE O5.bi_psa_wh_wrk;
COMMIT ;
INSERT/*+ append */ INTO O5.bi_psa_wh_wrk
   SELECT   department_id, datekey, product_id, SUM (total_demand_dollars),
            SUM (total_demand_qty), SUM (sold_demand_dollars),
            SUM (sold_demand_qty), SUM (bord_demand_dollars),
            SUM (bord_demand_qty), SUM (cancel_dollars), SUM (cancel_qty),
            SUM (gross_dollars), SUM (gross_qty), SUM (return_dollars),
            SUM (return_qty), SUM (net_dollars)
       FROM O5.bi_psa_wh, O5.bi_sumdates_is
      WHERE datekey = dte AND dte <> TRUNC (SYSDATE - 1)
   GROUP BY department_id, datekey, product_id;
COMMIT ;
----change level 2010:07:19 -------  update the new item sell table ---
TRUNCATE   TABLE O5.bi_item_sell_wk1_new;
INSERT/*+ append */ INTO O5.bi_item_sell_wk1_new
   SELECT distinct b.datekey, b.upc,
          TRIM (TO_CHAR (b.department_id, '000')) department_no,
          b.sku_list_price, 0 total_demand_qty, 0 total_demand_dollars,
          0 bord_demand_qty, 0 bord_demand_dollars, 0 cancel_dollars,
          0 gross_dollars, 0 gross_qty, 0 return_qty, 0 return_dollars,
          0 net_dollars, 0 gross_w_qty, 0 return_w_qty, 0 return_w_dollars,
          0 net_w_dollars, 0 recv_qty, 0 item_cst_amt, 0 price_status, 0 sfs_demand_qty, 
          0 sfs_demand_dollars, 0 sfs_sale_qty, 0 sfs_sale_dollars, 0 sfs_net_sale_qty, 
          0 sfs_net_sale_dollars,0 giftorder_demand_qty, 
          0 giftorder_demand_dollars, 0 giftorder_sale_qty, 0 giftorder_sale_dollars, 0 giftorder_net_sale_qty, 
          0 giftorder_net_sale_dollars
     FROM O5.bi_item_sell b, O5.bi_sumdates_is d
    WHERE datekey = dte AND dte <> TRUNC (SYSDATE - 1);
COMMIT ;
-- removing and saving duplicates - START
analyze table O5.bi_item_sell_wk1_new compute statistics;
insert into O5.bi_item_sell_wk1_new_duplicate
select * from O5.bi_item_sell_wk1_new a
      WHERE ROWID <
               (SELECT MAX (ROWID)
                  FROM O5.bi_item_sell_wk1_new b
                 WHERE      a.datekey = b.datekey 
                 and  a.upc = b.upc                      
                       AND a.department_no = b.department_no); 
COMMIT;					   
DELETE FROM O5.bi_item_sell_wk1_new a
      WHERE ROWID <
               (SELECT MAX (ROWID)
                  FROM O5.bi_item_sell_wk1_new b
                 WHERE     a.upc = b.upc
                       AND a.datekey = b.datekey
                       AND a.department_no = b.department_no);
-- removing and saving duplicates - END
COMMIT;
--  zero out the information to avoid duplication when control information changes  --
--Change Control 2010:01:29 Added hint for performance
MERGE   /*+ use_hash(hst,trn) */ INTO O5.bi_item_sell hst
   USING (SELECT datekey, upc, department_no, sku_list_price,
                 0 total_demand_qty, 0 total_demand_dollars,
                 0 bord_demand_qty, 0 bord_demand_dollars, 0 cancel_dollars,
                 0 gross_dollars, 0 gross_qty, 0 return_qty, 0 return_dollars,
                 0 net_dollars, 0 gross_w_qty, 0 return_w_qty,
                 0 return_w_dollars, 0 net_w_dollars, 0 recv_qty,
                 0 item_cst_amt, 0 price_status, 0 sfs_demand_qty, 
          	 0 sfs_demand_dollars, 0 sfs_sale_qty, 0 sfs_sale_dollars, 
          	 0 sfs_net_sale_qty, 0 sfs_net_sale_dollars,0 giftorder_demand_qty, 
          	 0 giftorder_demand_dollars, 0 giftorder_sale_qty, 0 giftorder_sale_dollars, 
          	 0 giftorder_net_sale_qty, 0 giftorder_net_sale_dollars
            FROM O5.bi_item_sell_wk1_new) trn
   ON (    trn.datekey = hst.datekey
       AND trn.upc = hst.upc
       AND trn.department_no = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.modify_dt = SYSDATE,
             hst.total_demand_qty = trn.total_demand_qty,
             hst.total_demand_dollars = trn.total_demand_dollars,
             hst.bord_demand_qty = trn.bord_demand_qty,
             hst.bord_demand_dollars = trn.bord_demand_dollars,
             hst.cancel_dollars = trn.cancel_dollars,
             hst.gross_dollars = trn.gross_dollars,
             hst.gross_qty = trn.gross_qty, hst.return_qty = trn.return_qty,
             hst.return_dollars = trn.return_dollars,
             hst.net_dollars = trn.net_dollars,
             hst.gross_w_qty = trn.gross_w_qty,
             hst.return_w_qty = trn.return_w_qty,
             hst.return_w_dollars = trn.return_w_dollars,
             hst.net_w_dollars = trn.net_w_dollars,
             hst.sfs_demand_qty = trn.sfs_demand_qty, 
             hst.sfs_demand_dollars = trn.sfs_demand_dollars,  
             hst.sfs_sale_qty = trn.sfs_sale_qty,  
             hst.sfs_sale_dollars = trn.sfs_sale_dollars, 
             hst.sfs_net_sale_qty = trn.sfs_net_sale_qty, 
             hst.sfs_net_sale_dollars = trn.sfs_net_sale_dollars,
             hst.giftorder_demand_qty = trn.giftorder_demand_qty, 
             hst.giftorder_demand_dollars = trn.giftorder_demand_dollars,  
             hst.giftorder_sale_qty = trn.giftorder_sale_qty,  
             hst.giftorder_sale_dollars = trn.giftorder_sale_dollars, 
             hst.giftorder_net_sale_qty = trn.giftorder_net_sale_qty, 
             hst.giftorder_net_sale_dollars = trn.giftorder_net_sale_dollars;
COMMIT ;

--  update item sell with updated psa data
TRUNCATE   TABLE  O5.bi_item_sell_wk2_new;
INSERT/*+ append */ INTO O5.bi_item_sell_wk2_new
--create table O5.BI_ITEM_SELL_wk2_new as
   SELECT b.datekey, b.product_id upc,
          TRIM (TO_CHAR (b.department_id, '000')) department_no,
          f.sku_list_price, b.total_demand_qty, b.total_demand_dollars,
          b.bord_demand_qty, b.bord_demand_dollars, b.cancel_dollars,
          b.gross_dollars, b.gross_qty, b.return_qty, b.return_dollars,
          b.net_dollars, c.gross_qty gross_w_qty, c.return_qty return_w_qty,
          c.return_dollars return_w_dollars, c.net_dollars net_w_dollars,
          0 recv_qty, f.item_cst_amt, f.price_status, b.sfs_demand_qty, 
          b.sfs_demand_dollars,  b.sfs_sale_qty,  b.sfs_sale_dollars, 
          b.sfs_net_sale_qty, b.sfs_net_sale_dollars, b.giftorder_demand_qty, 
          b.giftorder_demand_dollars,  b.giftorder_sale_qty,  b.giftorder_sale_dollars, 
          b.giftorder_net_sale_qty, b.giftorder_net_sale_dollars
     FROM O5.bi_psa_wrk b, O5.bi_psa_wh_wrk c, O5.bi_product f
    WHERE (b.datekey = c.datekey(+) AND b.product_id = c.product_id(+)
           AND b.department_id = c.department_id(+))
      AND b.product_id = f.upc(+);
COMMIT ;
--Change Control 0210:01:29 Added hint for performance
MERGE /*+ use_hash(hst,trn) */INTO O5.bi_item_sell hst
   USING (SELECT datekey, upc, department_no, sku_list_price,
                 total_demand_qty, total_demand_dollars, bord_demand_qty,
                 bord_demand_dollars, cancel_dollars, gross_dollars,
                 gross_qty, return_qty, return_dollars, net_dollars,
                 gross_w_qty, return_w_qty, return_w_dollars, net_w_dollars,
                 0 recv_qty, item_cst_amt, price_status, sfs_demand_qty, 
                 sfs_demand_dollars,  sfs_sale_qty,  sfs_sale_dollars, 
                 sfs_net_sale_qty, sfs_net_sale_dollars,giftorder_demand_qty, 
                 giftorder_demand_dollars,  giftorder_sale_qty,  giftorder_sale_dollars, 
                 giftorder_net_sale_qty, giftorder_net_sale_dollars
            FROM O5.bi_item_sell_wk2_new) trn
   ON (    trn.datekey = hst.datekey
       AND trn.upc = hst.upc
       AND trn.department_no = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.modify_dt = SYSDATE,
             hst.total_demand_qty = trn.total_demand_qty,
             hst.total_demand_dollars = trn.total_demand_dollars,
             hst.bord_demand_qty = trn.bord_demand_qty,
             hst.bord_demand_dollars = trn.bord_demand_dollars,
             hst.cancel_dollars = trn.cancel_dollars,
             hst.gross_dollars = trn.gross_dollars,
             hst.gross_qty = trn.gross_qty, hst.return_qty = trn.return_qty,
             hst.return_dollars = trn.return_dollars,
             hst.net_dollars = trn.net_dollars,
             hst.gross_w_qty = trn.gross_w_qty,
             hst.return_w_qty = trn.return_w_qty,
             hst.return_w_dollars = trn.return_w_dollars,
             hst.net_w_dollars = trn.net_w_dollars,
             hst.sfs_demand_qty = trn.sfs_demand_qty, 
             hst.sfs_demand_dollars = trn.sfs_demand_dollars,  
             hst.sfs_sale_qty = trn.sfs_sale_qty,  
             hst.sfs_sale_dollars = trn.sfs_sale_dollars, 
             hst.sfs_net_sale_qty = trn.sfs_net_sale_qty, 
             hst.sfs_net_sale_dollars = trn.sfs_net_sale_dollars,
             hst.giftorder_demand_qty = trn.giftorder_demand_qty, 
             hst.giftorder_demand_dollars = trn.giftorder_demand_dollars,  
             hst.giftorder_sale_qty = trn.giftorder_sale_qty,  
             hst.giftorder_sale_dollars = trn.giftorder_sale_dollars, 
             hst.giftorder_net_sale_qty = trn.giftorder_net_sale_qty, 
             hst.giftorder_net_sale_dollars = trn.giftorder_net_sale_dollars
   WHEN NOT MATCHED THEN
      INSERT (hst.datekey, hst.upc, hst.department_id, hst.sku_list_price,
              hst.total_demand_qty, hst.total_demand_dollars,
              hst.bord_demand_qty, hst.bord_demand_dollars,
              hst.cancel_dollars, hst.gross_dollars, hst.gross_qty,
              hst.return_qty, hst.return_dollars, hst.net_dollars,
              hst.gross_w_qty, hst.return_w_qty, hst.return_w_dollars,
              hst.net_w_dollars, hst.recv_qty, hst.item_cst_amt,
              hst.price_status, hst.sfs_demand_qty, hst.sfs_demand_dollars,  
              hst.sfs_sale_qty,  hst.sfs_sale_dollars, hst.sfs_net_sale_qty, 
              hst.sfs_net_sale_dollars,hst.giftorder_demand_qty, hst.giftorder_demand_dollars,  
              hst.giftorder_sale_qty,  hst.giftorder_sale_dollars, hst.giftorder_net_sale_qty, 
              hst.giftorder_net_sale_dollars)
      VALUES (trn.datekey, trn.upc, trn.department_no, trn.sku_list_price,
              trn.total_demand_qty, trn.total_demand_dollars,
              trn.bord_demand_qty, trn.bord_demand_dollars,
              trn.cancel_dollars, trn.gross_dollars, trn.gross_qty,
              trn.return_qty, trn.return_dollars, trn.net_dollars,
              trn.gross_w_qty, trn.return_w_qty, trn.return_w_dollars,
              trn.net_w_dollars, trn.recv_qty, trn.item_cst_amt,
              trn.price_status, trn.sfs_demand_qty, trn.sfs_demand_dollars,  
              trn.sfs_sale_qty,  trn.sfs_sale_dollars, trn.sfs_net_sale_qty, 
              trn.sfs_net_sale_dollars,trn.giftorder_demand_qty, trn.giftorder_demand_dollars,  
              trn.giftorder_sale_qty,  trn.giftorder_sale_dollars, trn.giftorder_net_sale_qty, 
              trn.giftorder_net_sale_dollars);
COMMIT ;

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

show errors
exit;
