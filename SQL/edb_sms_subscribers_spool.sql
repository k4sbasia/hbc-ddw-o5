set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
SET   VERIFY  OFF
set heading off

--SELECT distinct 'Content-Type: TEXT' from dual;
--SELECT distinct 'Company-Id: 1' from dual;
--SELECT distinct 'Fields: mdn,pdp_url1,pdp_url2' from dual;
--SELECT distinct 'Delimiter: COMMA' from dual;
select 'mdn' from dual;
SELECT distinct phone_number
FROM &1.waitlist W
WHERE w.phone_number is not null
and WAITLIST_CREATED_DT >=(select max(last_extract_time) from  mrep.job_extract_status where process_name='WAITLIST_SMS_SUBS')
;

exit;