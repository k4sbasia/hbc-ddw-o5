set feedback off
set heading off
set linesize 10000
set pagesize 0
set space 0
set tab off
set trimout on
select
OLD_EMAIL_ADDRESS    ||','||
NEW_EMAIL_ADDRESS
from O5.EMAIL_CHANGE_HISTORY
where trunc(EMAIL_CHG_DT) = trunc(sysdate)
and EMAIL_CHANGE_SOURCE <> 9104
;
exit
