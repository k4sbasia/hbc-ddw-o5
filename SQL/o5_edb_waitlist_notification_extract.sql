set linesize 1000
set pagesize 0
set serverout on
set echo on
set feedback on


TRUNCATE TABLE  o5.edb_waitlist_extract;

INSERT
INTO o5.edb_waitlist_extract
	(
		waitlist_id,
		sku,
		status,
		email,
		waitlist_created,
		waitlist_status_change,
		--batch_id,
		--request_id,
		waitlist_sent,
		sku_price
	)
SELECT DISTINCT 
		w.waitlist_id,
		w.upc,
		w.waitlist_status,
		w.email_address,
		w.waitlist_created_dt,
		w.waitlist_status_change,
		--e.batch_id,
		--e.request_id,
		w.waitlist_status_change time_sent,
		w.sku_price
	FROM 
		o5.waitlist w, 
		o5.edb_waitlist_extract_his e
   WHERE 
		w.upc=e.sku_code_lower(+)
	AND w.email_address=e.email(+);
COMMIT;


MERGE INTO o5.edb_waitlist_extract trg 
USING
( 
SELECT DISTINCT w.sku,
				p.brand_name,
				NVL(p.sku_color, 'No Color') sku_color,
				NVL(p.sku_size, 'No Size') sku_size,
				p.fashionfix_ind,
				p.product_code,
				p.department_id,
				p.item_description,
				p.sku_sale_price
		   FROM 
				o5.edb_waitlist_extract w,
				o5.bi_product p
		  WHERE w.sku = TO_NUMBER(p.upc)
)src 
ON	(trg.sku=src.sku)
WHEN MATCHED THEN
UPDATE
	SET trg.brand_name     = src.brand_name,
		trg.sku_color      =src.sku_color,
		trg.sku_size       =src.sku_size,
		trg.fashionfix_ind =src.fashionfix_ind,
		trg.product_code   =src.product_code,
		trg.department     =src.department_id,
		trg.item_desc      =src.item_description,
		trg.sku_sale_price =src.sku_sale_price;
COMMIT;

TRUNCATE TABLE o5.tmp_edb_waitlist_extract_src1;

INSERT INTO o5.tmp_edb_waitlist_extract_src1 
(
    sku_code_lower,
    email,
	time_sent,
	order_number,
	order_date,
	qty_purchased,
    TOT_AMT,TOT_ITEM_AMT
  )
SELECT DISTINCT
			 --W.SKU_ID,
			 w.sku_code_lower,
			 w.email,
			 w.time_sent,
			  ord.order_no order_number,
			 MAX(ord.order_date) order_date,
			 SUM(ord.original_ordered_qty) qty_purchased,
             sum(ordh.orh_total_amt) tot_amt, sum(ord.line_total) tot_item_amt
		FROM 
			 (select distinct sku_id, sku_code_lower, email, time_sent from  o5.edb_waitlist_extract_his)w,
			 o5.oms_o5_order_info ord,
     (select ordd.ORDER_NO, sum(line_total) orh_total_amt from o5.oms_o5_order_info ordd group by ordd.ORDER_NO) ordh
		WHERE 
		   UPPER(TRIM(w.email))  = TRIM(ord.email_address)
           AND ord.upc=w.sku_code_lower
           AND ord.order_no=ordh.order_no
		  AND w.time_sent       < ord.order_date
		  AND exists (select 1 from mrep.bi_datekey where trunc(ord.order_date)=trunc(datekey) and ord.order_date  between fiscal_yearstartdate and fiscal_yearenddate )
	 GROUP BY
			  w.sku_code_lower,
			  w.email,
			  w.time_sent,
			  ord.order_no;
  
  
merge into o5.EDB_WAITLIST_EXTRACT T1
USING (SELECT TIME_SENT, SKU_CODE_LOWER,EMAIL,SUM(QTY_PURCHASED)QTY_PURCHASED,MIN(ORDER_NUMBER)ORDER_NUMBER,MIN(ORDER_DATE)ORDER_DATE,
   SUM( TOT_AMT) TOT_AMT,SUM(TOT_ITEM_AMT) TOT_ITEM_AMT FROM o5.tmp_edb_waitlist_extract_src1 GROUP BY SKU_CODE_LOWER,EMAIL, TIME_SENT) T2
ON(T2.sku_code_lower=t1.sku AND T1.email=t2.email and t1.STATUS='S' and t1.waitlist_sent=t2.time_sent)
WHEN MATCHED THEN UPDATE
SET t1.PURCHASE_FLAG= 'Y',
t1.QTY_PURCHASED=t2.QTY_PURCHASED,
t1.ORDER_NUMBER=t2.ORDER_NUMBER,
t1.ORDER_DATE=t2.ORDER_DATE,
t1.total_value_of_sales= T2.tot_amt,
    t1.TOTAL_VALUE_OF_SALES_ITEM=T2.TOT_ITEM_AMT ;
COMMIT; 
  

MERGE INTO o5.edb_waitlist_extract trg
USING
(SELECT DISTINCT rfs.upc SKU,
				b.in_stock_sellable_qty web_on_hand,
				b.in_store_qty store_on_hand
			FROM
				o5.inventory b,
                o5.oms_rfs_o5_stg rfs
			WHERE 
				b.skn_no =rfs.skn_no
) SRC
  ON (trg.sku = src.sku)
WHEN MATCHED THEN
  UPDATE
	 SET trg.web_onhand = src.web_on_hand,
		 trg.store_onhand=src.store_on_hand;
COMMIT;
                

commit;

EXEC DBMS_MVIEW.refresh('sddw.mv_o5_edb_waitlist','c');
show errors;

exit;


