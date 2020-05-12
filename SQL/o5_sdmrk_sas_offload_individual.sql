whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
SELECT    'Individual_ID' || ',' || 
          'LAST_ORDER_DATE' || ',' || 
          'FIRST_ORDER_DATE' || ',' || 
          'SAKS_FIRST_TIER' || ',' || 
          'CARD_ACCT_TYPE' || ',' || 
          'STORE_OF_RESIDENCE' || ',' || 
          'PRIME_STATE' || ',' || 
          'PRIME_ZIPCODE' || ',' || 
          'REPEAT_CUSTOMER_MONTH' || ',' || 
          'REPEAT_CUSTOMER_QUARTER' || ',' || 
          'REPEAT_CUSTOMER_SEASON' || ',' || 
          'REPEAT_CUSTOMER_YEAR' || ',' || 
          'NEW_CUSTOMER_MONTH' || ',' || 
          'NEW_CUSTOMER_QUARTER' || ',' || 
          'NEW_CUSTOMER_SEASON' || ',' || 
          'NEW_CUSTOMER_YEAR' || ',' || 
          'MONETARY_MONTH' || ',' || 
          'MONETARY_QUARTER' || ',' || 
          'MONETARY_SEASON' || ',' || 
          'MONETARY_YEAR' || ',' || 
          'FREQUENCY_MONTH' || ',' || 
          'FREQUENCY_QUARTER' || ',' || 
          'FREQUENCY_SEASON' || ',' || 
          'FREQUENCY_YEAR' || ',' || 
          'RECENCY' || ',' || 
          'WEB_CUSTOMER' || ',' || 
          'STORE_ASSOCIATE_CUSTOMER' || ',' || 
          'CALL_CENTER_CUSTOMER'
from dual
;
SELECT    Individual_ID || ',' || 
          LAST_ORDER_DATE || ',' || 
          FIRST_ORDER_DATE || ',' || 
          SAKS_FIRST_TIER || ',' || 
          CARD_ACCT_TYPE || ',' || 
          STORE_OF_RESIDENCE || ',' || 
          PRIME_STATE || ',' || 
          PRIME_ZIPCODE || ',' || 
          REPEAT_CUSTOMER_MONTH || ',' || 
          REPEAT_CUSTOMER_QUARTER || ',' || 
          REPEAT_CUSTOMER_SEASON || ',' || 
          REPEAT_CUSTOMER_YEAR || ',' || 
          NEW_CUSTOMER_MONTH || ',' || 
          NEW_CUSTOMER_QUARTER || ',' || 
          NEW_CUSTOMER_SEASON || ',' || 
          NEW_CUSTOMER_YEAR || ',' || 
          MONETARY_MONTH || ',' || 
          MONETARY_QUARTER || ',' || 
          MONETARY_SEASON || ',' || 
          MONETARY_YEAR || ',' || 
          FREQUENCY_MONTH || ',' || 
          FREQUENCY_QUARTER || ',' || 
          FREQUENCY_SEASON || ',' || 
          FREQUENCY_YEAR || ',' || 
          RECENCY || ',' || 
          WEB_CUSTOMER || ',' || 
          STORE_ASSOCIATE_CUSTOMER || ',' || 
          CALL_CENTER_CUSTOMER
from sdmrk.o5_individual
; 
exit
