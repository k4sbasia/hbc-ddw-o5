set echo off
set feedback off 
set linesize 10000 
set pagesize 0 
set sqlprompt '' 
set heading off
set trimspool on 
set serverout on 

select count(*)  remaining_welcome_promo_pins
from o5.WELCOME_PROMOCODES
where promo =(select promo from o5.o5_welcome_promos_ctl_tab
where (trunc(sysdate) between start_date and end_date)) and use_status is null;

EXIT
EOF
