set linesize 32767 
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
set verify off


SELECT 'WAITLIST_ID' || ','||
'BATCH_ID' || ','|| 
'REQUEST_ID' || ','|| 
'SKU' || ','|| 
'STATUS' || ','||
'EMAIL' || ','||
'WAITLIST_CREATED' || ','||
'WAITLIST_STATUS_CHANGE' || ','|| 
'WAITLIST_SENT' || ','|| 
'PURCHASE_FLAG' || ','|| 
'QTY_PURCHASED' || ','|| 
'BRAND_NAME' || ','|| 
'ITEM_DESC' || ','|| 
'SKU_SIZE' || ','|| 
'SKU_COLOR' || ','|| 
'SKU_PRICE' || ','|| 
'DEPARTMENT' || ','|| 
'PRODUCT_CODE' || ','|| 
'FASHIONFIX_IND' || ','|| 
'STORE_ONHAND' || ','|| 
'WEB_ONHAND' || ','|| 
'TOTAL_VALUE_OF_SALES' || ','|| 
'TOTAL_VALUE_OF_SALES_ITEM' || ','|| 
'ORDER_NUMBER' || ','|| 
'ORDER_DATE'
FROM DUAL;

   SELECT WAITLIST_ID
 || ','
 || BATCH_ID
 || ','
 || REQUEST_ID
 || ','
 || SKU
 || ','
 || STATUS
 || ','
 || EMAIL
 || ','
 || WAITLIST_CREATED
 || ','
 || WAITLIST_STATUS_CHANGE
 || ','
 || WAITLIST_SENT
 || ','
 || PURCHASE_FLAG
 || ','
 || QTY_PURCHASED
 || ','
 || replace(BRAND_NAME,',',' ')
 || ','
 || replace(ITEM_DESC,',', ' ')
 || ','
 || SKU_SIZE
 || ','
 || SKU_COLOR
 || ','
 || SKU_PRICE
 || ','
 || DEPARTMENT
 || ','
 || PRODUCT_CODE
 || ','
 || FASHIONFIX_IND
 || ','
 || STORE_ONHAND
 || ','
 || WEB_ONHAND
 || ','
 || TOTAL_VALUE_OF_SALES
 || ','
 || TOTAL_VALUE_OF_SALES_ITEM
 || ','
 || ORDER_NUMBER
 || ','
 ||ORDER_DATE
 FROM SDMRK.O5_MV_WAITLIST;
 
 EXIT;
   	   
		   