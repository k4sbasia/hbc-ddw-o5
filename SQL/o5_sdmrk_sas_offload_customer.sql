whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
select 'CUSTOMER_ID' || ',' ||  
  'INDIVIDUAL_ID' || ',' ||  
  'HOUSEHOLD_ID' || ',' ||  
  'TITLE' || ',' ||  
  'FIRST_NAME' || ',' ||  
  'MIDDLE_NAME' || ',' ||  
  'LAST_NAME' || ',' ||  
  'HOME_PHONE' || ',' ||  
  'ADDR1' || ',' ||  
  'ADDR2' || ',' ||  
  'ADDR3' || ',' ||  
  'CITY' || ',' ||  
  'STATE' || ',' ||  
  'ZIPCODE' || ',' ||  
  'ZIP4' || ',' ||  
  'POSTAL_CODE' || ',' ||  
  'COUNTRY' || ',' ||  
  'EMAIL_ADDRESS' || ',' ||  
  'ADD_DT' || ',' ||  
  'REGISTERED_CUSTOMER' || ',' || 
  'MORE_NUMBER'
FROM dual; 

SELECT CUSTOMER_ID || ',' ||  
  INDIVIDUAL_ID || ',' ||  
  HOUSEHOLD_ID || ',' ||  
  TITLE || ',' ||  
  replace(FIRST_NAME, ',', '') || ',' ||  
  replace(MIDDLE_NAME, ',', '') || ',' ||  
  replace(LAST_NAME, ',', '') || ',' ||  
  replace(HOME_PHONE, ',', '') || ',' ||  
  replace(replace(replace (ADDR1,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' ||  
  replace(replace(replace (ADDR2,  CHR(10), '') , ',' , ''), CHR(13), '')  || ',' ||  
  replace(replace(replace (ADDR3,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' ||  
  replace(replace(replace (CITY,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' ||  
  replace(replace(replace (STATE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' ||  
  replace(replace(replace (ZIPCODE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
  replace(ZIP4, ',', '') || ',' ||  
  POSTAL_CODE || ',' ||  
  COUNTRY || ',' ||  
  EMAIL_ADDRESS || ',' ||  
  ADD_DT || ',' ||  
  REGISTERED_CUSTOMER || ',' || 
  MORE_NUMBER
FROM sdmrk.o5_customer
; 
exit
