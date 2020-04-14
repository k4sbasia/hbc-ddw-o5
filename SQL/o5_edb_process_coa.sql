whenever sqlerror exit failure
set heading off
set verify off
set pagesize 0
set tab off
set serveroutput on
set timing on
-- create batch
update O5.edb_stage_coa
set batch_id = &1
where batch_id is null
or PROCESSED is null;

commit;

------------------------------------------------------------------------
-- clean and sanity check changes

update O5.edb_stage_coa
set new_email_address = upper(trim(replace(new_email_address,',',''))),
    old_email_address = upper(trim(replace(old_email_address,',','')))
where batch_id = &1;

commit;

update O5.edb_stage_coa s
set skip = '1'
where batch_id = &1
  and (old_email_address = new_email_address
    or instr(old_email_address, '@') = 0 or instr(old_email_address, '.') = 0
    or instr(new_email_address, '@') = 0 or instr(new_email_address, '.') = 0);

commit;

------------------------------------------------------------------------
-- update - if old address exists and new does not

exec dbms_output.put_line('update');

declare
  loop_id O5.edb_stage_coa.old_email_address%TYPE;

  cursor c is
  select id
  from O5.edb_stage_coa
  where batch_id = &1
    and skip = '0'
  order by changed;
begin
  open c;
  loop
    fetch c into loop_id;
    exit when c%NOTFOUND;

    merge into O5.email_address t
    using (select
               o.email_id,
               s.source_id,
               s.new_email_address
           from O5.edb_stage_coa s
           join O5.email_address o on o.email_address = s.old_email_address
           where s.id = loop_id
             and not exists (select 1
                             from O5.email_address n
                             where n.email_address = s.new_email_address)) u
      on (t.email_id = u.email_id)
    when matched then
    update
    set email_address = u.new_email_address,
        email_change_source = u.source_id,
        modify_dt = sysdate,
        opt_in = 1,
        orig_opt_dt = case when t.orig_opt_dt is null then sysdate
                             else t.orig_opt_dt end,
        opt_in_chg_dt = case when t.opt_in <> 1 then sysdate
                             else t.opt_in_chg_dt end,
        opt_in_chg_by_source_id = case when t.opt_in <> 1 then u.source_id
                                       else t.opt_in_chg_by_source_id end
    ;

  end loop;
  close c;
end;
/

commit;
------------------------------------------------------------------------
-- opt-out lingering, opted-in old

exec dbms_output.put_line('opt-out old');

insert into O5.edb_stage_unsub
  ( source_id,
    email_address,
    unsubscribed,
    reason )
select
    source_id,
    old_email_address,
    changed,
    'c'
from O5.edb_stage_coa
where rowid in (select rid
                from (select
                          rowid rid,
                          row_number() over (partition by old_email_address
                                             order by changed) rn
                      from O5.edb_stage_coa
                      where batch_id = &1
                        and skip = '0'
                        and exists (select 1
                                    from O5.email_address
                                    where email_address = old_email_address
                                      and opt_in = 1))
                where rn = 1)
;
commit;
------------------------------------------------------------------------

------------------------------------------------------------------------
-- opt-in non-existant or opted-out new

exec dbms_output.put_line('opt-in new');

insert into O5.edb_stage_sub
  ( source_id,
    email_address,
    subscribed )
select
    source_id,
    new_email_address,
    changed
from O5.edb_stage_coa
where rowid in (select rid
                from (select
                          rowid rid,
                          row_number() over (partition by new_email_address
                                             order by changed) rn
                      from O5.edb_stage_coa
                      where batch_id = &1
                        and skip = '0'
                        and not exists (select 1
                                        from O5.email_address
                                        where email_address = new_email_address
                                          and opt_in = 1))
                where rn = 1)
;
commit;
------------------------------------------------------------------------
exec dbms_output.put_line('email_change_history');

insert into O5.email_change_history
  ( email_id,
    old_email_address,
    new_email_address,
    email_change_source,
    email_chg_dt,
    saks_first )
select
    e.email_id,
    s.old_email_address,
    s.new_email_address,
    s.source_id email_change_source,
    sysdate email_chg_dt,
    e.saks_first
from O5.edb_stage_coa s
join O5.email_address e  on e.email_address = s.new_email_address
where s.batch_id = &1
  and s.skip = '0'
;

commit;
------------------------------------------------------------------------
update O5.edb_stage_coa
set processed = sysdate
where batch_id = &1;

commit;

exit
