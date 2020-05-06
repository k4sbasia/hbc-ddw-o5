whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off

select    
    'EMAIL_ADDRESS' || ',' || 
    'SFA_EMPLOYEE' || ',' || 
    'VIP'  || ',' || 
    'SAKSFIRST' || ',' || 
    'SAKS_CARD_HOLDER' || ',' || 
    'BUYER_STATUS' || ',' || 
    'BUYER_TYPE' || ',' || 
    'VGC_SENDER' || ',' || 
    'GIFT_CARD_BUYER'  || ',' || 
    'VGC_RECIPIENT' || ',' || 
    'PHONE_ORDERER' || ',' || 
    'WEB_ONLY_BUYER' || ',' || 
    'SWEEPSTAKE_ENTRANT' || ',' || 
    'PROMO_CODE_USER' || ',' || 
    'HOLIDAY_ONLY_SHOPPER' || ',' || 
    'GIFT_GIVER'  || ',' || 
    'VENDOR' || ',' || 
    'MODIFY_DT' || ',' || 
    'BDATE' || ',' || 
    'FORD_DT' || ',' || 
    'LORD_DT' || ',' || 
    'SALE_SHOPPER' || ',' || 
    'MASTER_SOURCE_ID' || ',' || 
    'MASTER_CHANNEL'  || ',' || 
    'BUYER_STATUS_KEY' || ',' || 
    'REOPT_IN' || ',' || 
    'ADD_DT' || ',' || 
    'FIRST_NAME' || ',' || 
    'LAST_NAME' || ',' || 
    'LOCAL_STORE' || ',' || 
    'LOCAL_STORE_BY_ZIP' || ',' || 
    'STATE' || ',' || 
    'ZIP' || ',' || 
    'INTERNATIONAL_CUSTOMER' || ',' || 
    'GENDER'  || ',' || 
    'WELCOME_PROMO' || ',' || 
    'EMAIL_ID' || ',' || 
    'CM_AID' || ',' || 
    'MORE_NUMBER' 
FROM dual; 


select    
    replace(EMAIL_ADDRESS, ',', '')  || ',' || 
    SFA_EMPLOYEE || ',' || 
    VIP  || ',' || 
    SAKSFIRST || ',' || 
    SAKS_CARD_HOLDER || ',' || 
    BUYER_STATUS || ',' || 
    BUYER_TYPE || ',' || 
    VGC_SENDER || ',' || 
    GIFT_CARD_BUYER  || ',' || 
    VGC_RECIPIENT || ',' || 
    PHONE_ORDERER || ',' || 
    WEB_ONLY_BUYER || ',' || 
    SWEEPSTAKE_ENTRANT || ',' || 
    PROMO_CODE_USER || ',' || 
    HOLIDAY_ONLY_SHOPPER || ',' || 
    GIFT_GIVER  || ',' || 
    VENDOR || ',' || 
    MODIFY_DT || ',' || 
    BDATE || ',' || 
    FORD_DT || ',' || 
    LORD_DT || ',' || 
    SALE_SHOPPER || ',' || 
    MASTER_SOURCE_ID || ',' || 
    MASTER_CHANNEL || ',' || 
    BUYER_STATUS_KEY || ',' || 
    REOPT_IN || ',' || 
    ADD_DT || ',' || 
    replace(replace(first_name,'''', ''), ',', '') || ',' || 
    replace(replace(last_name,'''', ''), ',', '') || ',' || 
    replace(replace(replace (LOCAL_STORE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
    replace(replace(replace (LOCAL_STORE_BY_ZIP,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
    replace(replace(replace (STATE,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
    replace(replace(replace (ZIP,  CHR(10), '') , ',' , ''), CHR(13), '') || ',' || 
    INTERNATIONAL_CUSTOMER || ',' || 
    GENDER  || ',' || 
    WELCOME_PROMO || ',' || 
    EMAIL_ID || ',' || 
    CM_AID || ',' ||
MORE_NUMBER 
FROM SDMRK.O5_EMAIL_CHEETAH_SEGMENTS; 

exit
