whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
select    
    'EMAIL_ID' || chr(9) || 
    'EMAIL_ADDRESS' || chr(9) || 
    'GENDER' || chr(9) || 
    'OPT_IN'  || chr(9) || 
    'ADD_BY_SOURCE_ID' || chr(9) || 
    'ADD_DT' || chr(9) || 
    'CUSTOMER_ID' || chr(9) || 
    'INTERNATIONAL_IND' || chr(9) ||
    'MORE_NUMBER'  || chr(9) || 
    'WELCOME_PROMO' || chr(9) || 
    'WELCOME_BACK_PROMO'  || chr(9) || 
    'BARCODE'  || chr(9) || 
    'MORE_OPT_IN'   || chr(9) || 
    'SAKS_FIRST'   || chr(9) || 
    'LOCAL_STORE'   || chr(9) || 
    'LOCAL_STORE_BY_ZIP'
FROM dual; 

SELECT    
    EMAIL_ID || chr(9) || 
    REPLACE(
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(EMAIL_ADDRESS, chr(9), '')
				,UNISTR('\2190'),''),
			UNISTR('\2191'),''),
		UNISTR('\2192'),''),
	UNISTR('\2190'),'') || chr(9) || 
    GENDER || chr(9) || 
    OPT_IN  || chr(9) || 
    ADD_BY_SOURCE_ID || chr(9) || 
    ADD_DT || chr(9) || 
    CUSTOMER_ID || chr(9) || 
    INTERNATIONAL_IND || chr(9) || 
    MORE_NUMBER  || chr(9) || 
    WELCOME_PROMO || chr(9) || 
    WELCOME_BACK_PROMO  || chr(9) || 
    BARCODE  || chr(9) || 
    MORE_OPT_IN   || chr(9) || 
    SAKS_FIRST   || chr(9) || 
    LOCAL_STORE   || chr(9) || 
    LOCAL_STORE_BY_ZIP
FROM sdmrk.o5_email_address
; 
exit
