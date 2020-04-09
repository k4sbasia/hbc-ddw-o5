whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on
-- create batch

update O5.edb_stage_sub
set batch_id = &1
where batch_id is null
or PROCESSED is null;
commit;

exec dbms_output.put_line('trim');

update O5.edb_stage_sub
set email_address = upper(trim(replace(email_address,',',''))),
    associate_id  = trim(associate_id),
    account_num   = trim(account_num),
    str_code      = trim(str_code),
    prefix        = trim(prefix),
    full_name     = trim(full_name),
    first_name    = trim(first_name),
    middle_name   = trim(middle_name),
    last_name     = trim(last_name),
    address       = trim(address),
    address_two   = trim(address_two),
    city          = trim(city),
    state         = trim(state),
    zip_full      = trim(zip_full),
    zip_5         = trim(zip_5),
    zip_4         = trim(zip_4),
    phone         = trim(phone),
    country       = trim(country),
    saks_first    = trim(saks_first),
    mobile_phone  = trim(mobile_phone),  --[divya][2011.07.15] added mobile
    MORE_NUMBER   = trim(MORE_NUMBER)
where batch_id = &1;

commit;


update O5.edb_stage_sub
set skip = '1'
where batch_id = &1
  and source_id = 203 -- hsbc
  and email_address in (select email_address
                        from O5.email_address);

commit;

update O5.edb_stage_sub
set skip = '1'
where batch_id = &1
and email_address in ('.',',','@')
;
  
commit;


update O5.edb_stage_sub
set skip = '1'
where rowid in (select s.rowid
                from O5.edb_stage_sub s
                join O5.edb_stage_unsub u
                   on u.email_address = s.email_address
                where s.batch_id = &1
                  and (s.source_id = 9165 or s.skip = '0')
                  and (length(u.reason) = 4
                    or (s.subscribed < u.unsubscribed
		    and (u.source_id = 9165 or u.skip = '0'))));

commit;

--------skip if reopt from following master_sources--------------------
--for saks.com
------ master_source_id in (2, 11, 12, 13, 14, 15, 23, 25)
update O5.edb_stage_sub su
set skip = '1'
where batch_id = &1
  and source_id <> 203
  and exists 
  (select 1 from mrep.email_source s, mrep.email_master_source m 
  	where su.source_id=s.source_id and
  	m.master_source_id=s.master_source_id and m.reopt_ind='N')
  and exists 
	(select 1 from O5.email_address a
		where su.email_address=a.email_address and a.opt_in=0
		and orig_opt_dt is not null and opt_in_chg_dt is not null
        );

commit;
       
------------------------------------------------------------------------
exec dbms_output.put_line('email_id');

update O5.edb_stage_sub
set email_id = O5.email_id.nextval
where email_id is null
  and batch_id = &1;

commit;

------------------------------------------------------------------------
-- Could perform additional cleaning here.  Here is an example of cross
-- populating zip_full and zip_5/zip_4.

exec dbms_output.put_line('zipcode');

-- populate zip_full from zip_5 and zip_4
update O5.edb_stage_sub
set zip_full = zip_5
where batch_id = &1
  and skip = '0'
  and (country is null or country = 'US')
  and zip_full is null
  and zip_5 is not null
  and zip_4 is null;

commit;

update O5.edb_stage_sub
set zip_full = zip_5 || '-' || zip_4
where batch_id = &1
  and skip = '0'
  and (country is null or country = 'US')
  and zip_full is null
  and zip_5 is not null
  and zip_4 is not null;

commit;


-- populate zip_5 and zip_4 from zip_full
update O5.edb_stage_sub
set zip_5 = regexp_replace(zip_full, '^([0-9]{5})-?([0-9]{4})$', '\1'),
    zip_4 = regexp_replace(zip_full, '^([0-9]{5})-?([0-9]{4})$', '\2')
where batch_id = &1
  and skip = '0'
  and (country is null or country = 'US')
  and zip_full is not null
  and zip_5 is null
  and zip_4 is null
  and regexp_like(zip_full, '^([0-9]{5})-?([0-9]{4})$');

commit;


update O5.edb_stage_sub
set zip_5 = zip_full
where batch_id = &1
  and skip = '0'
  and (country is null or country = 'US')
  and zip_full is not null
  and zip_5 is null
  and zip_4 is null
  and regexp_like(zip_full, '^([0-9]{5})$');

commit;

--- Set the canada_flag to 'Y' if it's a CCA record through one of the Canada stores
update o5.edb_stage_sub
set canada_flag = 'Y'
where  batch_id = &1
and skip = '0'
and str_code in (select store_no from RFS.RF_STORE@saksrfs_prd
                                where chain = 7 and currency_code = 'CAD'
                                );

commit;

-- While more involved, could similarly cross populate full_name and
-- prefix,first,middle,last_name.

------------------------------------------------------------------------
-- populate local tables

-- populate legacy tables: O5.saks_quick_email? O5.email_sqe_work?

-- FIXME O5.saks_quick_email used (minimally) by segment process needs
-- sqe_email and sqe_gender and that's all...?  Could just populate it directly
-- when staging, just like the original.

exec dbms_output.put_line('email_detail_trans');

insert into O5.email_detail_trans
  ( source,
    email_address,
    associate_id,
    account_num,
    str_code,
    name_full,
    prefix,
    first_name,
    middle_name,
    last_name,
    address,
    address_two,
    city,
    state,
    zip_full,
    zip_5,
    zip_4,
    country,
    phone,
    saks_first_num,
    bd_month,
    bd_day,
    date_modified,
    date_received,
    email_id,
    invalid_email_ind,
    invalid_zip_ind,
    missing_address_ind,
    missing_fname_ind,
    missing_lname_ind,
    mobile_phone,
    MORE_NUMBER )  
select
    source_id,
    email_address,
    associate_id,
    account_num,
    str_code,
    full_name,
    prefix,
    first_name,
    middle_name,
    last_name,
    address,
    address_two,
    city,
    state,
    zip_full,
    zip_5,
    zip_4,
    country,
    phone,
    saks_first,
    bday_month,
    bday_day,
    subscribed,
    trunc(subscribed),
    email_id,
    case when instr(email_address, '@') = 0
           or instr(email_address, '.') = 0 then 1 else 0 end,
    case when length(zip_full) < 5
           or length(zip_full) > 10 then 0 else 1 end,
    case when address is null then 1
         when city is null then 1
         when state is null then 1
         else 0 end,
    case when first_name is null then 1 else 0 end,
    case when last_name is null then 1 else 0 end,
    mobile_phone,
   MORE_NUMBER 			
from O5.edb_stage_sub
where batch_id = &1
and (source_id = 9165 or skip = '0') ; 

commit;

----------------------------------------------------------------------------------
exec dbms_output.put_line('welcome promo codes');

update O5.welcome_promocodes wpr
   set use_status = 'U'
where use_status is null
  and exists (select 1
              from O5.email_address ema
              where ema.welcome_promo = wpr.promo_code
                 or ema.welcome_back_promo = wpr.promo_code);

commit;


MERGE INTO O5.email_address trg
USING (SELECT ema.email_address, prom.promo_code
         FROM (SELECT email_address, ROWNUM rn
                 FROM (SELECT DISTINCT ema.email_address
                         FROM O5.email_address      ema
                             ,O5.email_detail_trans dts
                        WHERE ema.email_address = dts.email_address
                              AND dts.datekey = TRUNC(SYSDATE)
                              AND (ema.opt_in = 0 AND ema.opt_in_chg_dt <= trunc(SYSDATE) - 183 )
                              AND ema.valid_ind = 1
			      AND NOT EXISTS
                       (SELECT NULL
                                 FROM O5.email_opt_inout inout
                                WHERE dts.email_address = inout.email_address
				      AND inout.opt_in = 0
                                      AND inout.reason in ('a', 'b')))) ema
             ,(SELECT ROWNUM rn, pro.promo_code
                 FROM O5.welcome_promocodes pro
                WHERE pro.use_status IS NULL
		AND EXISTS (select 1 from O5.o5_welcome_promos_ctl_tab
                                                              where (trunc(sysdate) between start_date and end_date) and
                                                              promo = pro.promo)
) prom
        WHERE ema.rn = prom.rn) trn
ON (trg.email_address = trn.email_address)
WHEN MATCHED THEN
  UPDATE SET trg.welcome_back_promo = trn.promo_code;

commit;


update O5.welcome_promocodes wpr
   set use_status = 'U'
where use_status is null
  and exists (select 1
              from O5.email_address ema
              where ema.welcome_promo = wpr.promo_code
                 or ema.welcome_back_promo = wpr.promo_code);

commit;

----------Nilima added-----for WELCOME_BACK_BARCODE -------------------------
exec dbms_output.put_line('welcome back barcode');

update O5.STORE_BARCODE wpr
   set use_status = 'U'
where use_status is null
  and exists (select 1
              from O5.email_address ema
              where ema.barcode = wpr.barcode
                 or WELCOME_BACK_BARCODE = wpr.barcode);

commit;


MERGE INTO O5.email_address trg
USING (SELECT ema.email_address, prom.barcode
         FROM (SELECT email_address, ROWNUM rn
                 FROM (SELECT DISTINCT ema.email_address
                         FROM O5.email_address      ema
                             ,O5.email_detail_trans dts
                        WHERE ema.email_address = dts.email_address
                              AND dts.datekey = TRUNC(SYSDATE)
                              AND (ema.opt_in = 0 AND ema.opt_in_chg_dt <= trunc(SYSDATE) - 183 )
                              AND ema.valid_ind = 1
			      AND NOT EXISTS
                       (SELECT NULL
                                 FROM O5.email_opt_inout inout
                                WHERE dts.email_address = inout.email_address
				      AND inout.opt_in = 0
                                      AND inout.reason in ('a', 'b')))) ema
             ,(SELECT ROWNUM rn, pro.barcode barcode
                 FROM O5.STORE_BARCODE pro
                WHERE pro.use_status IS NULL
		AND EXISTS (select 1 from O5.o5_welcome_promos_ctl_tab c
                                                              where (trunc(sysdate) between start_date and end_date) and
                                                              c.barcode = substr(pro.barcode,1,11))
) prom
        WHERE ema.rn = prom.rn) trn
ON (trg.email_address = trn.email_address)
WHEN MATCHED THEN
  UPDATE SET trg.WELCOME_BACK_BARCODE = trn.barcode;

commit;

update O5.STORE_BARCODE wpr
   set use_status = 'U'
where use_status is null
  and exists (select 1
              from O5.email_address ema
              where ema.barcode = wpr.barcode
                 or WELCOME_BACK_BARCODE = wpr.barcode);

 

commit;

------------End of barcode - added by Nilima ----------------------------------------------------------------
------------------------------------------------------------------------
-- update

exec dbms_output.put_line('update email_address');

-- exclude hsbc from update
-- if multiple subs today, just use "last" one
-- only use new address if it is complete
-- only use new name if it is complete

-- FIXME could loop over these, in subscribed order, to percolate info up
-- from multiple subs

-- Debated splitting this into multiple statements, processing logical groups
-- of columns together.  This would be slower, but I suspect much easier to
-- follow.  Decided against, since the insert can not be similarly split.

merge into O5.email_address o
using (select
           s.source_id,
           s.email_address,
           s.subscribed,
           s.associate_id,
           s.account_num,
           s.str_code,
           s.full_name,
           s.prefix,    -- FIXME translate to title?
           s.first_name,
           s.middle_name,
           s.last_name,
           s.address,
           s.address_two,
           s.city,
           s.state,
           s.zip_full,
           s.country,
           s.phone,
           s.saks_first,
           s.bday_month,
           s.bday_day,
           s.email_id,
           (case when s.first_name is null then 0
                 when s.last_name is null then 0
                 else 1 end) name_complete,
           (case when s.address is null then 0
                 when s.city is null then 0
                 when s.state is null then 0
                 when s.zip_full is null then 0
                 else 1 end) address_complete,
           (case when exists (select 1
                              from O5.email_opt_inout io
                              where io.email_address = s.email_address
                                and io.opt_in = 0
                                and io.reason in ('a', 'b')) then 0
                 else 1 end) opt_in,
	   s.canada_flag,
	   s.language_id,
	   s.mobile_phone, --[divya][2011.07.15] added mobile_phone	     
           s.MORE_NUMBER 
       from O5.edb_stage_sub s
       where s.batch_id = &1
         and s.skip = '0'
         and s.id in (select max(s1.id)
                      from O5.edb_stage_sub s1
                      where s1.batch_id = &1
                        and s1.skip = '0'
                      group by email_address)) n
  on (o.email_address = n.email_address)
when matched then update
 set first_name = case when n.name_complete = 1
                       then n.first_name
                       else o.first_name end,
     middle_name = case when n.name_complete = 1
                        then n.middle_name else o.middle_name end,
     last_name = case when n.name_complete = 1
                      then n.last_name
                      else o.last_name end,
     address = case when n.address_complete = 1
                    then n.address
                    else o.address end,
     address_two = case when n.address_complete = 1
                    then n.address_two
                    else o.address_two end,
     city = case when n.address_complete = 1
                    then n.city
                    else o.city end,
     state = case when n.address_complete = 1
                    then n.state
                    else o.state end,
     zip = case when n.address_complete = 1
                    then n.zip_full
                    else o.zip end,
     country = case when n.address_complete = 1
                    then n.country
                    else o.country end,
     phone_number = coalesce(n.phone, o.phone_number),
     mobile_number = coalesce(n.mobile_phone, o.mobile_number), 
     saks_first = coalesce(n.saks_first, o.saks_first),
     bday_month = coalesce(n.bday_month, o.bday_month),
     bday_day = coalesce(n.bday_day, o.bday_day),
     opt_in = n.opt_in,
     opt_in_chg_dt = case when o.opt_in <> n.opt_in then sysdate
                          else o.opt_in_chg_dt end,
     opt_in_chg_by_source_id = case when o.opt_in <> n.opt_in then n.source_id
                                    else o.opt_in_chg_by_source_id end,
     opt_in_chg_referer_id = case when o.opt_in <> n.opt_in then to_char(n.source_id)
                                  else o.opt_in_chg_referer_id end,
     reopt_in = 0,
     -- FIXME should these next two columns reference opt_in or reopt_in?
     reopt_in_chg_dt = case when o.opt_in <> n.opt_in then sysdate
                            else o.reopt_in_chg_dt end,
     reopt_in_chg_by_source_id = case when o.opt_in <> n.opt_in then n.source_id
                                      else o.reopt_in_chg_by_source_id end,
     valid_ind = 1,
     valid_chg_dt = case when o.valid_ind <> 1 then sysdate
                         else o.valid_chg_dt end,
     valid_chg_by_source_id = case when o.valid_ind <> 1 then n.source_id
                                   else o.valid_chg_by_source_id end,
     valid_chg_reason =  case when o.valid_ind <> 1 then NULL
                              else o.valid_chg_reason end,
     modify_dt = sysdate,
     modify_by_source_id = n.source_id,
     email_change_source = case when o.opt_in <> n.opt_in then n.source_id
                                else o.email_change_source end,
     init_store = coalesce(o.init_store, to_number(n.str_code)),
     init_store_collect_dt = case when o.init_store is null and n.str_code is not null
                                  then trunc(n.subscribed)
                                  else o.init_store_collect_dt end,
     init_store_associate_id = case when o.init_store is null and n.str_code is not null
                                    then n.associate_id
                                    else o.init_store_associate_id end,
     orig_opt_dt = case when o.orig_opt_dt is null  then trunc(n.subscribed)
                                else o.orig_opt_dt end,
     sys_entry_dt = case when o.sys_entry_dt is null  then sysdate
                                else o.sys_entry_dt end,
     MORE_NUMBER =coalesce(n.MORE_NUMBER,o.MORE_NUMBER),
     canada_flag = n.canada_flag,
     language_id = n.language_id
;

commit;

------------------------------------------------------------------------
-- insert

exec dbms_output.put_line('insert email_address');

merge into O5.email_address o
using (select
           s.source_id,
           s.email_address,
           s.subscribed,
           s.associate_id,
           s.account_num,
           s.str_code,
           s.full_name,
           s.prefix,    -- FIXME translate to title?
           s.first_name,
           s.middle_name,
           s.last_name,
           s.address,
           s.address_two,
           s.city,
           s.state,
           s.zip_full,
           s.country,
           s.phone,
           s.self_select_gender,
           s.saks_first,
           s.bday_month,
           s.bday_day,
	   s.mobile_phone, --[divya][2011.07.15] added mobile_phone
           s.email_id,
           s.MORE_NUMBER,
	   s.canada_flag,
	   s.language_id
       from O5.edb_stage_sub s
       where s.batch_id = &1
         and s.skip = '0'
         and s.id in (select max(s1.id)
                      from O5.edb_stage_sub s1
                      where s1.batch_id = &1
                        and s1.skip = '0'
                      group by email_address)
         and instr(email_address, '@') <> 0
         and instr(email_address, '.') <> 0) n
  on (o.email_address = n.email_address)
when not matched then
  insert ( email_id,
           email_address,
           title,
           first_name,
           middle_name,
           last_name,
           address,
           address_two,
           city,
           state,
           zip,
           country,
           phone_number,
	   mobile_number, --[divya] [2011.07.15]added mobile
	   bday_month,
           bday_day,
           saks_first,
           opt_in,
           opt_in_chg_dt,
           opt_in_chg_by_source_id,
           opt_in_chg_referer_id,
           valid_ind,
           valid_chg_dt,
           valid_chg_by_source_id,
           add_dt,
           add_by_source_id,
           modify_dt,
           modify_by_source_id,
           modify_count,
           reopt_in,
           reopt_in_chg_dt,
           reopt_in_chg_by_source_id,
           associate_id,
           entry_dt,
           email_change_source,
           age_range_id,
           local_store,
           init_store,
           init_store_collect_dt,
           init_store_associate_id,
           saks_direct_purchase_count,
           saks_web_purchase_count,
           self_select_store_ind,
           self_select_saks_first_ind,
           self_select_bday_ind,
	   orig_opt_dt,
	   sys_entry_dt,
           MORE_NUMBER,
	   canada_flag,
	   delta_flag,
	   language_id
)
  values ( n.email_id,
           n.email_address,
           null,
           n.first_name,
           n.middle_name,
           n.last_name,
           n.address,
           n.address_two,
           n.city,
           n.state,
           n.zip_full,
           n.country,
           n.phone,
	   n.mobile_phone, 
           n.bday_month,
           n.bday_day,
           n.saks_first,
           1, -- opt_in
           sysdate,
           n.source_id,
           to_char(n.source_id),
           1, -- valid_ind
           sysdate,
           n.source_id,
           case when n.subscribed is null then trunc(sysdate) else trunc(n.subscribed) end,
           n.source_id,
           sysdate, -- modify_dt
           n.source_id,
           1,
           0, --reopt_in
           sysdate,
           n.source_id,
           n.associate_id,
           sysdate,
           n.source_id,
           null,
           n.str_code,
           to_number(n.str_code),
           case when n.str_code is not null then case when n.subscribed is null then trunc(sysdate) else trunc(n.subscribed) end else null end,
           n.associate_id,
           null,
           null,
           null,
           null,
           null,
	   case when n.subscribed is null then trunc(sysdate) else trunc(n.subscribed) end,
     	   sysdate,
           n.MORE_NUMBER,
	   n.canada_flag,
	   1,
	   n.language_id);
commit;
------------------------------------------------------------------------
exec dbms_output.put_line('local store by zip');

update O5.email_address
set local_store = null
where reporting_store is null and local_store = 0;

MERGE INTO O5.email_address  hst
USING (
 SELECT c.email_address,  c.email_id, c.opt_in, c.valid_ind, c.add_by_source_id, min( s.storenum) store_num
             FROM MREP.BI_TRADE_AREA s, O5.email_address c, mrep.bi_store_info st
             WHERE   s.zip_code =substr(c.zip,1,5)
             and     st.store_num = s.storenum
             and     (st.close_date = '01-jan-0001' or sysdate < st.close_date)
             and     c.local_store_by_zip is null -- and entry_dt > sysdate-7
             group by c.email_address,  c.email_id, c.opt_in, c.valid_ind, c.add_by_source_id 
                              ) TRN
   ON (hst.email_id = trn.email_id
       and hst.email_address=trn.email_address
     )
   WHEN MATCHED THEN
      UPDATE
         SET hst.local_store_by_zip = trn.store_num
            ,hst.modify_dt=sysdate ;

commit;

------------------------------------------------------------------------
exec dbms_output.put_line('reporting store');

MERGE INTO O5.email_address   hst
USING (select distinct s.email_address, max(s.email_id) email_id ,  max(s.opt_in) opt_in, 
      max(s.valid_ind) valid_ind , max(s.add_by_source_id) add_by_source_id , min(s.reporting_store) reporting_store
 from (
 SELECT c.email_address,  c.email_id, c.opt_in, c.valid_ind, c.add_by_source_id,
      (CASE
       WHEN     c.local_store_by_zip > 0 and c.local_store is null
           then c.local_store_by_zip
           when c.local_store_by_zip > 0 and  c.local_store = 0
           then c.local_store_by_zip
           When c.local_store <> store_gl_num  and   c.local_store <> 0
           THEN c.local_store
           When c.local_store > 0
           THEN c.local_store
           when c.local_store=store_gl_num  and   c.local_store <> 0
           THEN st.store_num
           WHEN c.local_store=store_gl_num  and  c.local_store is not null
           THEN st.store_num
       END)  reporting_store
             FROM  O5.email_address c
             left outer join  mrep.bi_store_info st
             on  c.local_store=st.store_gl_num    and store_business_type in ('B','R') and ST.STORE_GL_NUM <> 0
             WHERE reporting_store is null and (c.local_store_by_zip  is not null or c.local_store is not null)
             ) s, mrep.bi_store_info st2
             where s.reporting_store = st2.store_num
             and (st2.close_date = '01-jan-0001' or st2.close_date > sysdate)
             group by s.email_address
                              ) TRN
   ON (hst.email_id = trn.email_id
       and hst.email_address=trn.email_address
     )
   WHEN MATCHED THEN
      UPDATE
         SET hst.reporting_store = trn.reporting_store
           ,hst.modify_dt=sysdate
;

commit;
------------------------------------------------------------------------
exec dbms_output.put_line('stage gender');

insert into O5.edb_stage_gender
  ( source_id,
    email_address,
    gender,
    self_select )
select
    source_id,
    email_address,
    gender,
    self_select_gender
from O5.edb_stage_sub
where batch_id = &1
  and skip = '0'
  and gender is not null
;
commit;

------------------------------------------------------------------------

--update the source_id for the multiple source we recieved

MERGE INTO O5.email_address  hst
USING (
 SELECT C.EMAIL_ADDRESS,max(trunc(staged)) staged, MAX(SOURCE_ID) source_id
        from    O5.EDB_STAGE_SUB C
      WHERE BATCH_ID = &1
      AND SKIP = '0'
      AND SOURCE_ID IS NOT NULL
      group by c.email_address
                              ) TRN
   ON (
       HST.EMAIL_ADDRESS=TRN.EMAIL_ADDRESS
       and trunc(hst.entry_dt) = trunc(sysdate)
     )
   WHEN MATCHED THEN
      UPDATE
         SET ADD_BY_SOURCE_ID = TRN.SOURCE_ID,
          OPT_IN_CHG_BY_SOURCE_ID = TRN.SOURCE_ID,
          VALID_CHG_BY_SOURCE_ID =  TRN.SOURCE_ID,
          MODIFY_BY_SOURCE_ID = TRN.SOURCE_ID,
          OPT_IN_CHG_REFERER_ID = TRN.SOURCE_ID,
          REOPT_IN_CHG_BY_SOURCE_ID =  TRN.SOURCE_ID,
          EMAIL_CHANGE_SOURCE = TRN.SOURCE_ID;
         

commit;

update O5.edb_stage_sub
set processed = sysdate
where batch_id = &1;

commit;

exit;
