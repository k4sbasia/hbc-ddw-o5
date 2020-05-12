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
select 'mdn,pdp_url1,pdp_url2' from dual;
SELECT distinct phone_number || ',' || w.ITEM_URL || ',' ||w.product_code
FROM &1.EDB_WAITLIST_EXTRACT_SMS_WRK w,
     &1.O5_PARTNERS_EXTRACT_WRK bpw
WHERE w.phone_number is not null and w.item_url is not null
  AND w.product_code = bpw.styl_seq_num
and lpad(w.sku_code_lower,13,0)=bpw.upc
  AND length(w.phone_number) >=10
;

exit;
