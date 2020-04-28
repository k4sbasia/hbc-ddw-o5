SET ECHO OFF
SET FEEDBACK on
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET TRIMSPOOL ON

insert into &1.edb_stage_sub
(
source_id,
email_address,
subscribed,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language_id
)
select
source_id,
email_address,
case when sub_unsub_date is null then sysdate else sub_unsub_date end,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language
from
&1.edb_stage_sfcc_email_opt_data
where 
(source_id in ('9166','500','9184','9197','9168','9050','9192','9193') and
decode('&1','o5.',trim(OFF5TH_OPT_STATUS),'mrep.',trim(saks_opt_status)) = 'Y')
and email_address is not null;

commit;

insert into mrep.edb_stage_sub
(
source_id,
email_address,
subscribed,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language_id
)
select
decode(source_id,'9168','9173'),
email_address,
case when sub_unsub_date is null then sysdate else sub_unsub_date end,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language
from
&1.edb_stage_sfcc_email_opt_data
where 
 source_id in ('9168') and trim(saks_opt_status) = 'Y'
and email_address is not null;

COMMIT;

--mmost probably for Saks adding O5 optin from saks should be uncommented when same script used for Saks
/*
insert into o5.edb_stage_sub
(
source_id,
email_address,
subscribed,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language_id
)
select
decode(source_id,'9050','9173'),
email_address,
case when sub_unsub_date is null then sysdate else sub_unsub_date end,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
language
from
mrep.edb_stage_sfcc_email_opt_data
where 
 source_id in ('9050') and trim(OFF5TH_OPT_STATUS) = 'T'
and email_address is not null;
*/

COMMIT;

insert into &1.edb_stage_unsub
(source_id,
email_address,
unsubscribed,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
reason,
language_id
)
select source_id,
email_address,
case when sub_unsub_date is null then sysdate else sub_unsub_date end,
first_name,
middle_name,
last_name,
address,
address_two,
city,
state,
zip_full,
country,
phone,
canada_flag,
'M',
language
from &1.edb_stage_sfcc_email_opt_data
where decode('&1','o5.',trim(OFF5TH_OPT_STATUS),'mrep.',trim(saks_opt_status)) = 'N'
and email_address is not null;

commit;

delete from
   &1.edb_stage_sub a
where
   a.rowid >
   any (select b.rowid
   from
      &1.edb_stage_sub  b
   where
        a.email_address = b.email_address
      and trunc(a.subscribed) = trunc(b.subscribed)
      and a.source_id in (9192,9166,9193,9184,9197,9168,9050,9173)
      and a.source_id = b.source_id
   )
  and a.subscribed > (trunc(sysdate-1));

commit;

insert into &1.edb_sfcc_email_opt_data_hist(
SOURCE_ID,
EMAIL_ADDRESS,
FIRST_NAME,
MIDDLE_NAME,
LAST_NAME,
ADDRESS,
ADDRESS_TWO,
CITY,
STATE,
ZIP_FULL,
COUNTRY, 
PHONE, 
OFF5TH_OPT_STATUS,
SAKS_OPT_STATUS,    
SAKS_CANADA_OPT_STATUS,       
OFF5TH_CANADA_OPT_STATUS,      
THE_BAY_OPT_STATUS,     
SUB_UNSUB_DATE, 
LANGUAGE,  
BANNER,
CANADA_FLAG,      
SAKS_FAMILY_OPT_STATUS,     
MORE_NUMBER,
HBC_REWARDS_NUMBER, 
BIRTHDAY,
GENDER
)
select SOURCE_ID,
EMAIL_ADDRESS,
FIRST_NAME,
MIDDLE_NAME,
LAST_NAME,
ADDRESS,
ADDRESS_TWO,
CITY,
STATE,
ZIP_FULL,
COUNTRY, 
PHONE, 
OFF5TH_OPT_STATUS,
SAKS_OPT_STATUS,    
SAKS_CANADA_OPT_STATUS,       
OFF5TH_CANADA_OPT_STATUS,      
THE_BAY_OPT_STATUS,     
SUB_UNSUB_DATE, 
LANGUAGE,  
BANNER,
CANADA_FLAG,      
SAKS_FAMILY_OPT_STATUS,     
MORE_NUMBER,
HBC_REWARDS_NUMBER, 
BIRTHDAY,
GENDER
from &1.edb_stage_sfcc_email_opt_data;

commit;

exit
