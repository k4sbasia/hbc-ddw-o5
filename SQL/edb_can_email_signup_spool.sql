set feedback off
set heading off
set linesize 10000
set pagesize 0
set space 0
set tab off
set trimout on

select 	'EMAIL' || ',' ||
	'FNAME' || ',' ||
	'LNAME' || ',' ||
	'POSTAL' || ',' ||
	'BANNER' || ',' ||
	'LANGUAGE'
from dual;

select email || ',' ||
        fname || ',' ||
        lname || ',' ||
        postal || ',' ||
        banner || ',' ||
        language
from
(
select  email email,
        fname fname,
        lname lname,
        zip postal,
        'Saks' banner,
        'Y' language
from mrep.edb_can_email_signup_wrk a
where zz_sbrand_optin = 'Y' or email in (select email from o5.edb_can_email_signup_wrk where zz_sbrand_optin = 'Y')
union
select  email email,
        fname fname,
        lname lname,
        zip postal,
        'O5' banner,
        'Y' language
from o5.edb_can_email_signup_wrk a
where (zz_sbrand_optin = 'Y' or email in (select email from mrep.edb_can_email_signup_wrk where zz_sbrand_optin = 'Y'))
and email not in (select email from mrep.edb_can_email_signup_wrk a where zz_sbrand_optin = 'Y' or 
			email in (select email from o5.edb_can_email_signup_wrk b where b.zz_sbrand_optin = 'Y'))
);

exit
