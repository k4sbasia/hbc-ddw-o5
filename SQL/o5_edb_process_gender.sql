whenever sqlerror exit failure
set heading off
set verify off
set pagesize 0
set serveroutput on
set timing on
update O5.edb_stage_gender
set batch_id = &1
where batch_id is null
or processed is null;

commit;

update O5.edb_stage_gender
set email_address = upper(trim(replace(email_address,',',''))),
    gender        = nvl(gender, 'U'),
    self_select   = nvl(self_select, 'N')
where batch_id = &1;

commit;

-- defer addresses that aren't in O5.email_address
update O5.edb_stage_gender o
set batch_id = null
where batch_id = &1
  and not exists (select 1
                  from O5.email_address i
                  where o.email_address = i.email_address);

commit;
------------------------------------------------------------------------
-- can eliminate some quickly, to improve performance

-- only need unique staged rows - only eight possibilities per address
update O5.edb_stage_gender
set skip = '1'
where rowid in (select rid
                from (select
                          rowid rid,
                          row_number() over (partition by email_address, gender, self_select
                            order by rowid) rn
                      from O5.edb_stage_gender
                      where batch_id = &1
                        and skip = '0')
                where rn <> 1);

commit;

-- ignore if current priority beats staged priority
update O5.edb_stage_gender
set skip = '1'
where rowid in (select s.rowid
                from O5.edb_stage_gender s
                join O5.email_address e on s.email_address = upper(trim(e.email_address))
                where s.batch_id = &1
                  and s.skip = '0'
                  and e.gender is not null
                  and s.self_select = 'N'
                  and e.self_select_gender_ind = 'Y');

commit;

-- ignore if priorities are equal, and it's one of the easy no-change cases:
-- genders equal, or stage is unknown, or current is already household
update O5.edb_stage_gender
set skip = '1'
where rowid in (select s.rowid
                from O5.edb_stage_gender s
                join O5.email_address e on s.email_address = upper(trim(e.email_address))
                where s.batch_id = &1
                  and s.skip = '0'
                  and e.gender is not null
                  and s.self_select = e.self_select_gender_ind
                  and (e.gender = s.gender or s.gender = 'U' or e.gender = 'H'));

commit;

------------------------------------------------------------------------
-- Merge requires a unique match - each target row can be affected at most
-- once.  There certainly could be multiple staged rows for a single address.
-- Apply a sequence per email_address to stage, and then repeat the update
-- until all staged rows have been processed.  This layer column could be
-- added to the stage table, but I thought a temp table was cleaner.

insert into O5.edb_stage_gender_wrk (id, layer)
select
    id,
    row_number() over (partition by email_address order by rowid)
from O5.edb_stage_gender
where batch_id = &1
  and skip = '0';

commit;

declare
  i integer := 1;
begin
  loop
    merge into O5.email_address o
    using (select
               email_address,
               gender,
               self_select
           from O5.edb_stage_gender s
           join O5.edb_stage_gender_wrk w  on w.id = s.id
           where layer = i) n
     on (o.email_address = n.email_address)
    when matched then update
    set
self_select_gender_ind = case
when (nvl(o.self_select_gender_ind,'N') = 'Y' or n.self_select = 'Y') then 'Y'
else 'N'
end,
gender = case
when nvl(o.self_select_gender_ind,'N') = 'Y' and n.self_select = 'N' then nvl(o.gender,'U')
when nvl(o.self_select_gender_ind,'N') = 'N' and n.self_select = 'Y' then     n.gender
when nvl(o.gender,'U') = n.gender then     n.gender
when nvl(o.gender,'U') = 'U'      then     n.gender
when     n.gender      = 'U'      then nvl(o.gender, 'U')
else 'H'
end ;

    exit when sql%rowcount = 0;
    i := i + 1;
  end loop;
end;
/

commit;
------------------------------------------------------------------------
update O5.edb_stage_gender
set processed = sysdate
where batch_id = &1;

commit;

exit;
