REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_edb_stage_bm_checkout_delta.sql
REM  DESCRIPTION:  Delta job to update O5.edb_stage_sub 
REM
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Sripriya Rao                 09/16/2015   	Created 
REM                Ishavpreet Singh             04/10/2020      Updated for SFCC , Customer ID mapping handled for unregistered customer by population Bill_to_key from OMS into Bi_customer
REM
REM ############################################################################

whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on

insert into O5.edb_stage_sub
  ( source_id,
    email_address,
    subscribed,
    prefix,
    first_name,
    middle_name,
    last_name,
    address,
    address_two,
    city,
    state,
    zip_full,
    country,
    saks_first,
    more_number )
select
   distinct   
   9166,
    trim(upper(internetaddress)),
    add_dt,
    custtitle,                
    firstname,
    middlename,
    lastname,
    addr1,
    addr2,
    city,
    state,
    substr(zipcode,1,29), 
    country,
    saksfirstnumber,
    more_number         
from O5.bi_customer c
where exists (select 1
              from O5.bi_sale s
              where c.customer_id = s.createfor)
  and add_dt > (select last_extract_time from o5.edb_sub_status) 
  and internetaddress is not null
  and upper(trim(internetaddress)) not like 'E4X%'
  and trim(c.country) not in (select country_code from O5.T_GDPR_REGION)
;
commit;

exit
