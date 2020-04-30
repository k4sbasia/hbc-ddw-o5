set linesize 1000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
whenever sqlerror exit failure

merge into &1 trg
using (select e.email_address,
             u.customer_id customer_id,
             u.registered_customer  registered,
             u.recency_date_time  last_login_dt
      from &2 e
      inner join O5.BI_CUSTOMER@&3 u
      on (upper(nvl(u.usa_uid, u.usa_email)) = e.email_address)
      ) src
on (trg.email_address = src.email_address and
   trg.customer_id = src.customer_id and
   trg.registered = src.registered and
   trg.last_login_dt = src.last_login_dt)
when not matched then insert
(email_address,
customer_id,
registered,
last_login_dt)
values(src.email_address,
      src.customer_id,
      src.registered,
      src.last_login_dt
      );
commit;


      
--commented since not used and populated 
--  merge into &1 trg
--using (select upper(nvl(u.usa_uid, u.usa_email)) email_address,
--             u.usa_id customer_id,
--             case when usa_uid is null then 'N' else 'Y' end registered,
--             usa_last_login_dt last_login_dt
--      from sdmrk.favorites_service_data f
--      inner join martini_store.user_account@prodsto_saks_custom u
--      on (f.account_id = u.usa_id and banner = '&4')
--      ) src
--on (trg.email_address = src.email_address and
--   trg.customer_id = src.customer_id and
--   trg.registered = src.registered and
--   trg.last_login_dt = src.last_login_dt)
--when not matched then insert
--(email_address,
--customer_id,
--registered,
--last_login_dt)
--values(src.email_address,
--      src.customer_id,
--      src.registered,
--      src.last_login_dt
--      );
--commit;

exit





























