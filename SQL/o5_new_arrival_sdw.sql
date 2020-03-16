TRUNCATE TABLE &2.t_new_arrival_date_update_rfp;
DROP  INDEX &2.IDX_NEW_ARRIVAL_ITEM_RFP;

MERGE INTO &2.t_new_arrival_date_update_rfp a USING
 (SELECT DISTINCT p.PRODUCT_ID item_id,
				 NVL(READYFORPROD_TIMER,TRUNC(r.readyforprod_set_dt)) readyforprod_date,
                 SYSDATE tstamp,
                 MIN(NVL(DECODE(BACK_ORDERABLE,'F','N','Y'),'Y')) pre_order_flag
           FROM
                 &2.all_active_pim_prd_attr_&3 p ,
    		 (SELECT product_id,
                        MIN(readyforprod_set_dt) readyforprod_set_dt
                   FROM &2.readyforprod_sort a
                  WHERE readyforprod = 'Yes'
               GROUP BY product_id) r
           WHERE
                 r.product_id  = p.product_id
             AND p.PRD_STATUS ='A'
        GROUP BY p.PRODUCT_ID ,READYFORPROD_TIMER,r.readyforprod_set_dt   ) b
  ON (a.item_id = b.item_id)
  WHEN NOT MATCHED THEN
  INSERT (item_id,readyforprod_date,tstamp, pre_order_flag) VALUES
  ( b.item_id,b.readyforprod_date,SYSDATE,b.pre_order_flag);
 

COMMIT;

CREATE INDEX &2.IDX_NEW_ARRIVAL_ITEM_RFP ON &2.t_new_arrival_date_update_rfp (item_id);
quit

