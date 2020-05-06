whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
select 'ORDER_NUMBER' || ',' ||'ORDER_LINE_NUMBER' || ',' ||'ORDERDATE' || ',' ||'ORDER_LINE_STATUS' || ',' ||'ORDER_HEADER_STATUS' || ',' ||'ORDER_TYPE' || ',' ||'CUSTOMER_NUMBER' || ',' ||'FREIGHT_CHARGES' || ',' || 'SHIP_VIA' || ',' ||'CANCELLATION_DOLLARS' || ',' ||   'RETURN_DOLLARS' || ',' || 'TAX' || ',' ||  'CANCEL_DATE' || ',' ||        'PROMO_ID' || ',' ||'REFER_ID' || ',' ||'DEMAND_DOLLARS' || ',' ||  'DEMAND_UNITS' || ',' ||     'CANCEL_REASON_CODE' || ',' ||  'CANCEL_REASON_DESCRIPTION' || ',' ||'RETURN_REASON_CODE' || ',' ||'RETURN_REASON_DESCRIPTION' || ',' ||'BACKORDER_INDICATOR' || ',' || 'SAKS_FIRST_INDICATOR' || ',' ||'EMPLOYEE_INDICATOR' || ',' ||'SAKS_FIRST_FREE_SHIP_INDICATOR' || ',' || 'FILL_LOCATION' || ',' || 'CUSTOMER_ID' || ',' ||'INDIVIDUAL_ID' || ',' ||   'HOUSEHOLD_ID' || ',' ||'SHIP_DATE' || ',' ||'CREDIT_CARD_TYPE' || ',' ||'CREDIT_CARD_DESCRIPTION' || ',' ||'BILL_TO_ADDRESS_ID' || ',' ||'SHIP_TO_ADDRESS_ID' || ',' ||'STORE_NUMBER' || ',' ||'RETURN_DATE' || ',' ||'ITEM_NUMBER' || ',' ||'SKU' || ',' ||'VENDOR_ID' || ',' ||'DEPARTMENT_ID' || ',' || 'GROUP_ID' || ',' ||'DIVISION_ID' || ',' ||'GIFT_WRAP_INDICATOR' || ',' ||'GIFTWRAP_TYPE' || ',' || 'FIRST_PO_DATE' || ',' ||     'RETURN_UNITS' || ',' || 'CANCELLATION_UNITS' || ',' ||    'EMC_NUMBER' || ',' ||  'AFFILIATE_ID' || ',' ||'INTERNATIONAL_IND' || ',' ||'SHIP_ADDR1' || ',' ||'SHIP_ADDR2' || ',' ||  'SHIP_ADDR3' || ',' ||'SHIP_CITY' || ',' ||'SHIP_STATE' || ',' ||'SHIP_ZIPCODE' || ',' || 'SHIP_COUNTRY' || ',' ||'ANYTIME_IND' || ',' || 'FLASH_IND' || ',' ||  'FULLFILLLOCATION' || ',' || 'EVT_ID' || ',' ||  'EVT_NAME' || ',' || 'MORE_NUMBER' || 'DW_ORDER_NUMBER' from dual;

select 
ORDER_NUMBER || ',' || 
ORDER_LINE_NUMBER || ',' ||
ORDERDATE || ',' || 
ORDER_LINE_STATUS || ',' || 
ORDER_HEADER_STATUS || ',' || 
ORDER_TYPE || ',' || 
CUSTOMER_NUMBER || ',' || 
FREIGHT_CHARGES  || ',' || 
SHIP_VIA || ',' || 
CANCELLATION_DOLLARS || ',' || 
RETURN_DOLLARS || ',' || 
TAX || ',' || 
CANCEL_DATE || ',' ||      
replace(PROMO_ID, ',','|') || ',' || 
replace(REFER_ID,',','|') || ',' || 
DEMAND_DOLLARS || ',' || 
DEMAND_UNITS || ',' || 
replace(CANCEL_REASON_CODE,',','|') || ',' || 
replace(CANCEL_REASON_DESCRIPTION,',') || ',' || 
replace(RETURN_REASON_CODE, ',','|') || ',' || 
replace(RETURN_REASON_DESCRIPTION, ',', ' ') || ',' || 
BACKORDER_INDICATOR || ',' ||
SAKS_FIRST_INDICATOR || ',' || 
EMPLOYEE_INDICATOR || ',' || 
SAKS_FIRST_FREE_SHIP_INDICATOR || ',' || 
FILL_LOCATION || ',' || 
CUSTOMER_ID || ',' || 
INDIVIDUAL_ID || ',' || 
HOUSEHOLD_ID || ',' || 
SHIP_DATE || ',' || 
CREDIT_CARD_TYPE || ',' || 
CREDIT_CARD_DESCRIPTION || ',' || 
BILL_TO_ADDRESS_ID || ',' || 
SHIP_TO_ADDRESS_ID || ',' ||  
STORE_NUMBER  || ',' || 
RETURN_DATE  || ',' || 
ITEM_NUMBER || ',' || 
SKU  || ',' || 
VENDOR_ID || ',' || 
DEPARTMENT_ID || ',' ||
GROUP_ID || ',' || 
DIVISION_ID || ',' || 
GIFT_WRAP_INDICATOR || ',' || 
GIFTWRAP_TYPE || ',' || 
FIRST_PO_DATE || ',' ||  
RETURN_UNITS || ',' || 
CANCELLATION_UNITS || ',' ||
EMC_NUMBER || ',' || 
replace(AFFILIATE_ID, ',','|') || ',' || 
INTERNATIONAL_IND || ',' || 
replace(replace(replace (SHIP_ADDR1,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
replace(replace(replace (SHIP_ADDR2,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
replace(replace(replace (SHIP_ADDR3,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
replace(replace(replace (SHIP_CITY,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
replace(replace(replace (SHIP_STATE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
replace(replace(replace (SHIP_ZIPCODE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
SHIP_COUNTRY || ',' || 
ANYTIME_IND || ',' || 
FLASH_IND || ',' || 
FULLFILLLOCATION || ',' || 
EVT_ID || ',' || 
EVT_NAME || ',' ||
MORE_NUMBER || ',' ||
DW_ORDER_NUMBER
from SDMRK.O5_ORDERS
--where ORDERDATE between '29-feb-2012' and '02-jan-2013'
;

exit