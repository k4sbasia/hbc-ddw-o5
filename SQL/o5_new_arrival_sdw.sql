WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF

TRUNCATE TABLE &1.t_new_arrival_date_update_rfp;
DROP  INDEX &1.IDX_NEW_ARRIVAL_ITEM_RFP;

MERGE INTO &1.t_new_arrival_date_update_rfp a USING
 (SELECT DISTINCT p.PRODUCT_ID item_id,
				 NVL(trunc(to_date(READYFORPROD_TIMER, 'MM/DD/YYYY HH:MI PM')),TRUNC(r.readyforprod_set_dt)) readyforprod_date,
                 SYSDATE tstamp,
                 'F' pre_order_flag
           FROM
                 &1.all_active_pim_prd_attr_&2 p ,
    		 (SELECT product_id,
                        MIN(readyforprod_set_dt) readyforprod_set_dt
                   FROM &1.readyforprod_sort a
                  WHERE readyforprod = 'Yes'
               GROUP BY product_id) r
           WHERE
                 r.product_id  = p.product_id
             AND p.PRD_STATUS ='Yes'
        GROUP BY p.PRODUCT_ID ,READYFORPROD_TIMER,r.readyforprod_set_dt   ) b
  ON (a.item_id = b.item_id)
  WHEN NOT MATCHED THEN
  INSERT (item_id,readyforprod_date,tstamp, pre_order_flag) VALUES
  ( b.item_id,b.readyforprod_date,SYSDATE,b.pre_order_flag);


COMMIT;

CREATE INDEX &1.IDX_NEW_ARRIVAL_ITEM_RFP ON &1.t_new_arrival_date_update_rfp (item_id);
quit
