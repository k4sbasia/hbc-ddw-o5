whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
select 
    'EMAIL_ID' || ',' || 
    'OLD_EMAIL_ADDRESS' || ',' || 
    'NEW_EMAIL_ADDRESS' || ',' || 
    'EMAIL_CHG_DT'
FROM dual 
;
SELECT EMAIL_ID || ',' || 
    replace(OLD_EMAIL_ADDRESS, ',', '') || ',' || 
    replace(NEW_EMAIL_ADDRESS, ',', '') || ',' || 
    EMAIL_CHG_DT
FROM SDMRK.O5_EMAIL_CHANGE_HISTORY
; 
exit
