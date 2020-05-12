set timing on
merge into O5.email_address o
using (select
           email_id,
           customer_id
       from (select
                 e.email_id,
                 c.customer_id,
                 row_number() over (partition by upper(trim(internetaddress))
                                    order by c.add_dt) rn
             from O5.email_address e
             join O5.bi_customer c
               on e.email_address = upper(trim(internetaddress))
             where e.customer_id is null)
        where rn = 1) n
  on (o.email_id = n.email_id)
when matched then update
set customer_id = n.customer_id
;

commit;

-- age stage tables
delete from O5.edb_stage_sub
where source_id = 9165
  and staged < trunc(sysdate) - 60;

commit;

delete from O5.edb_stage_sub
where source_id <> 9165
	and staged < trunc(sysdate) - 45;
  --[Divya] -2011.06.13
  --changed to retain for 45 days
  --and staged < trunc(sysdate) - 14

commit;

delete from O5.edb_stage_coa  
where source_id <> 9165
	and staged < trunc(sysdate) - 45;
  --[Divya] -2011.06.13
  --changed to retain for 45 days
  --and staged < trunc(sysdate) - 14

commit;

delete from O5.edb_stage_unsub
where source_id <> 9165
	and staged < trunc(sysdate) - 45;
  --[Divya] -2011.06.13
  --changed to retain for 45 days
  --and staged < trunc(sysdate) - 14

commit;

delete from O5.edb_stage_exception
where source_id <> 9165
	and staged < trunc(sysdate) - 45;
  --[Divya] -2011.06.13
  --changed to retain for 45 days
  --and staged < trunc(sysdate) - 14
commit;


delete from O5.edb_stage_gender
where
staged < trunc(sysdate) - 2
;
commit;
exit;
