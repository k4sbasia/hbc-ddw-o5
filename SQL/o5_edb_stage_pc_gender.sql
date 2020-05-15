whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on

insert into o5.edb_stage_gender
  ( email_address,
    gender )
select
    a.email_address,
    case
         when l.gender = 'C' then 'H'
         else l.gender
    end
from o5.email_gender_landing l
join o5.email_address a on l.email_id = a.email_id
where l.gender is not null
  and l.gender in ('U', 'M', 'F', 'C')
;

commit;

exit;
