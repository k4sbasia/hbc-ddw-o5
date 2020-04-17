set echo off
set feedback off 
set linesize 10000 
set pagesize 0 
set sqlprompt '' 
set heading off
set trimspool on 
set serverout on 
select count(*)  remaining_welcome_barcodes
from o5.store_barcode
where use_status is null;
EXIT
EOF