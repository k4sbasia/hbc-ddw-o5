set serveroutput on
set feedback on

TRUNCATE TABLE O5.EDB_WAITLIST_EXTRACT_WRK;

INSERT INTO O5.EDB_WAITLIST_EXTRACT_WRK
            (WAITLIST_ID,
               EMAIL,
               SKU_CODE_LOWER,
               SKU_PRICE_WAITLISTED,
               ITEM_URL,
               IMAGE_URL,
				       product_code,
				       QTY,
				       BRAND_NAME,
				       ITEM_DESC,
				       sku_size,
				       sku_COLOR,
                       sku_id,
                       sku_parent_id,
                       compare_price,
                       sku_price
		)
SELECT DISTINCT W.WAITLIST_ID,
  upper(trim(W.EMAIL_address)),
  w.upc,
  w.SKU_PRICE,
  REPLACE(opw.product_url,'https://',''),
  w.SKU_IMAGE_URL,
  lpad(w.product_code,13,'0'),
  w.qty,
  W.BRAND_name,
  w.item_desc,
  opw.sku_size1_desc,
  opw.sku_color,
  w.upc,
  opw.styl_seq_num,
  opw.sku_list_price,
  opw.sku_sale_price
  FROM o5.WAITLIST w,
  o5.inventory b ,
 o5.O5_PARTNERS_EXTRACT_WRK opw
WHERE w.waitlist_STATUS = 'N'
AND LPAD(w.upc,13,0) = opw.upc
AND b.skn_no =opw.sku
AND (B.in_stock_sellable_qty > 0 or B.in_store_qty > 0)
;

COMMIT;



delete  from o5.edb_waitlist_extract_wrk a
 where rowid>
 ( select min(rowid) from o5.edb_waitlist_extract_wrk  b where
 a.email=b.email and a.sku_code_lower=b.sku_code_lower);

 commit;

MERGE INTO O5.EDB_WAITLIST_EXTRACT_WRK W
     USING (SELECT email, ROWNUM - 1 AS request_id
              FROM (SELECT DISTINCT email
                      FROM O5.EDB_WAITLIST_EXTRACT_WRK)) src
      ON (w.email = src.email )
WHEN MATCHED
THEN
   UPDATE SET w.request_id = src.request_id;

COMMIT;



MERGE INTO o5.WAITLIST trg
     USING (SELECT distinct email, sku_code_lower  FROM  O5.EDB_WAITLIST_EXTRACT_WRK) src
        ON (trg.email_address = src.email and trg.upc=src.sku_code_lower)
WHEN MATCHED
THEN
   UPDATE SET waitlist_STATUS = 'S',
   WAITLIST_SENT_DT=sysdate,
   WAITLIST_STATUS_change =sysdate;

COMMIT;

INSERT INTO O5.EDB_WAITLIST_EXTRACT_HIS
(
   WAITLIST_ID,
   EMAIL,
   SKU_ID,
   SKU_CODE_LOWER,
   BRAND_NAME,
   ITEM_DESC,
   SKU_SIZE,
   SKU_COLOR,
   SKU_PRICE,
   ITEM_URL,
   IMAGE_URL,
   SKU_PARENT_ID,
   QTY,
   REQUEST_ID,
   BATCH_ID,
   TIME_SENT)
SELECT  WAITLIST_ID,
   EMAIL,
   SKU_ID,
   SKU_CODE_LOWER,
   BRAND_NAME,
   ITEM_DESC,
   SKU_SIZE,
   SKU_COLOR,
   SKU_PRICE_WAITLISTED,
   ITEM_URL,
   IMAGE_URL,
   SKU_PARENT_ID,
   QTY,
   REQUEST_ID,
   &1,
   SYSDATE
FROM O5.EDB_WAITLIST_EXTRACT_WRK;

COMMIT;

exit
