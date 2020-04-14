whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on

merge into o5.edb_stage_sub trg
using (
select  9195,
        email,
        fname,
        lname,
        zip,
	    zz_language_id,
        staged,
        sysdate
from o5.edb_can_email_signup_wrk
where pid = '2098090846' and zz_mbrand_optin = 'Y') src
on (trg.email_address = src.email and trunc(trg.staged) = trunc(sysdate))
when not matched then
insert (source_id,
        email_address,
        first_name,
        last_name,
        zip_full,
	    language_id,
        canada_flag,
        subscribed,
        staged
        )
values (9195,
        src.email,
        src.fname,
        src.lname,
        src.zip,
	src.zz_language_id,
        'Y',
        src.staged,
        sysdate);
        
merge into mrep.edb_stage_sub trg
using (
select  9195,
        email,
        fname,
        lname,
        zip,
	    zz_language_id,
        staged,
        sysdate
from o5.edb_can_email_signup_wrk
where pid = '2098090846' and zz_sbrand_optin = 'Y') src
on (trg.email_address = src.email and trunc(trg.staged) = trunc(sysdate))
when not matched then
insert (source_id,
        email_address,
        first_name,
        last_name,
        zip_full,
	    language_id,
        canada_flag,
        subscribed,
        staged
        )
values (9195,
        src.email,
        src.fname,
        src.lname,
        src.zip,
	    src.zz_language_id,
        'Y',
        src.staged,
        sysdate);

commit;

merge into o5.edb_stage_sub trg
using (
select  9204,
        email,
        fname,
        lname,
        zip,
            zz_language_id,
        staged,
        sysdate
from o5.edb_can_email_signup_wrk
where pid = '2104770124') src
on (trg.email_address = src.email and trunc(trg.staged) = trunc(sysdate))
when not matched then
insert (source_id,
        email_address,
        first_name,
        last_name,
        zip_full,
        language_id,
        subscribed,
        staged
        )
values (9204,
        src.email,
        src.fname,
        src.lname,
        src.zip,
        src.zz_language_id,
        src.staged,
        sysdate);

commit;

exit	 	

