whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on
update O5.edb_stage_unsub
set batch_id = &1
where batch_id is null
or PROCESSED is null;

commit;

update O5.edb_stage_unsub
set email_address = upper(trim(replace(email_address,',','')))
where batch_id = &1;

commit;

-- skip echo unsubs from cheetah
update O5.edb_stage_unsub
set skip = '1'
where batch_id = &1
  and source_id = 9104
  and reason = 'K';

commit;

-- skip all but last of any duplicates (not an error)
update O5.edb_stage_unsub
set skip = '1'
where rowid in (select rid
                from (select
                          rowid rid,
                          row_number() over (partition by email_address
                            order by unsubscribed desc, rowid) rn
                      from O5.edb_stage_unsub
                      where batch_id = &1
                        and skip = '0')
                where rn <> 1);

commit;


-- skip if currently unsubscribed
update O5.edb_stage_unsub
set skip = '1'
where rowid in (select s.rowid
                from O5.edb_stage_unsub s
                join O5.email_address e
                   on e.email_address = s.email_address
                where s.batch_id = &1
                  and s.skip = '0'
                  and e.opt_in = 0);

commit;

-- skip if resubscribed since
update O5.edb_stage_unsub
set skip = '1'
where rowid in (select u.rowid
                from O5.edb_stage_unsub u
                join O5.edb_stage_sub s
                   on s.email_address = u.email_address
                where u.batch_id = &1
                  and u.skip = '0'
                  and u.unsubscribed < s.subscribed
                  and s.source_id = 9099);
commit;

-----------------------------------------------------------------------

-- save to cheetah legacy table
insert into O5.email_cheetah_unsub_history
  ( aid,
    pid,
    reason,
    email_address,
    unsub_dt,
    sub_dt,
    add_dt )
select
    aid,
    pid,
    reason,
    email_address,
    unsubscribed,
    subscribed,
    add_dt
from O5.edb_stage_unsub
where batch_id = &1
  and skip = '0'
  and source_id = 9104
;

commit;

merge into O5.email_address o
using (select
           s.email_address,
           s.source_id
       from O5.edb_stage_unsub s
       where batch_id = &1
         and skip = '0') n 	
 on (o.email_address = n.email_address)
when matched then update
set opt_in = 0,
    reopt_in = 1,
    opt_in_chg_dt = case when o.opt_in <> 0 then sysdate
                         else o.opt_in_chg_dt end,
    opt_in_chg_by_source_id = case when o.opt_in <> 0 then n.source_id
                                   else o.opt_in_chg_by_source_id end,
    modify_dt = sysdate,
    modify_by_source_id = n.source_id
;

commit;

insert into O5.email_reopt_history
  ( email_id,
    email_address,
    opt_ind,
    email_opt_change_source,
    email_opt_chg_dt )
select
    e.email_id,
    e.email_address,
    0,
    s.source_id,
    sysdate
from O5.edb_stage_unsub s
join O5.email_address e
   on e.email_address = s.email_address
  and trunc(e.opt_in_chg_dt) = trunc(sysdate)
where s.batch_id = &1
  and s.skip = '0'
;

commit;

------------------------------------------------------------------------
update O5.edb_stage_unsub
set processed = sysdate
where batch_id = &1;

commit;

exit
