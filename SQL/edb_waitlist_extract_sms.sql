set serveroutput on
set feedback on

TRUNCATE TABLE &2.EDB_WAITLIST_EXTRACT_SMS_WRK;

INSERT INTO &2.EDB_WAITLIST_EXTRACT_SMS_WRK 
            (
			 SKU_CODE_LOWER,
             SKU_PRICE_WAITLISTED,
             ITEM_URL,
             product_code,
			 phone_number
		)
 SELECT DISTINCT 
  w.upc,
  w.SKU_PRICE,
  w.product_detail_url,
  lpad(w.product_code,13,'0'),
  phone_number
FROM &2.WAITLIST w,
&2.inventory b ,
&2.oms_rfs_o5_stg s
WHERE w.SMS_STATUS = 'N'
and lpad(w.upc,13,0) = lpad(s.upc,13,0)
and s.skn_no= b.skn_no
--AND LPAD(B.SKU_ID,13, 0)=C.UPC_CODE(+)
--AND w.upc=b.sku_id(+)
--AND (B.WH_SELLABLE_QTY > 0 or ( C.SHIP_FROM_STORE_STATUS = 'I' and C.ONHAND_INVENTORY > 0))
and (B.IN_STOCK_SELLABLE_QTY > 0 or B.IN_STORE_QTY > 0)
;

COMMIT;

delete  from &2.EDB_WAITLIST_EXTRACT_SMS_WRK a
 where rowid>
 ( select min(rowid) from &2.EDB_WAITLIST_EXTRACT_SMS_WRK  b where 
 a.phone_number=b.phone_number and a.sku_code_lower=b.sku_code_lower); 
 
 commit;

MERGE INTO &2.WAITLIST trg
     USING (SELECT distinct phone_number, sku_code_lower  FROM  &2.EDB_WAITLIST_EXTRACT_SMS_WRK) src
        ON (trg.phone_number = src.phone_number and trg.upc=src.sku_code_lower)
WHEN MATCHED
THEN
   UPDATE SET SMS_STATUS = 'S',
   SMS_SENT_DATE=sysdate;

COMMIT;

INSERT INTO &2.EDB_WAITLIST_SMS_HIS
(
   SKU_CODE_LOWER,
   SKU_PRICE_WAITLISTED,
   ITEM_URL,
   TIME_SENT,
   PHONE_NUMBER)
SELECT  distinct
   SKU_CODE_LOWER,
   SKU_PRICE_WAITLISTED,
   ITEM_URL,
   SYSDATE,
   PHONE_NUMBER
FROM &2.EDB_WAITLIST_EXTRACT_SMS_WRK where phone_number IS NOT NULL;
   
COMMIT;

exit
