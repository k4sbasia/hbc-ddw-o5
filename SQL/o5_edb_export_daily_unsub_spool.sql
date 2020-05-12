set feedback off
set heading off
set linesize 10000
set pagesize 0
set space 0
set tab off
set trimout on
SELECT email_address
  FROM O5.email_address
 WHERE trunc(opt_in_chg_dt) = trunc(SYSDATE)
       AND opt_in_chg_dt < trunc(SYSDATE)+1
       AND opt_in = 0
       AND orig_opt_dt is not null
       AND valid_ind = 1
       AND opt_in_chg_by_source_id <> 9104
;
exit


