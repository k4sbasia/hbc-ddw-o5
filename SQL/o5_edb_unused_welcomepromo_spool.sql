set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
  
select 'email_address' from DUAL;
SELECT 
  replace(email_address, ',','')
FROM O5.EMAIL_ADDRESS E
WHERE wp_used='Y'
AND wp_used_dt= trunc(sysdate)-1
;
exit
