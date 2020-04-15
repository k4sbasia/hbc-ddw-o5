whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on

insert into O5.edb_stage_gender
  ( email_address,
    gender,
    self_select )
select
    internetaddress,
    gender,
    'Y'
from O5.bi_customer
where internetaddress is not null
  and gender is not null
  and gender in ('U', 'M', 'F')
  and internetaddress  LIKE '%@%.%'
;
commit;

exit;
