set feedback off
set heading off
set linesize 10000
set pagesize 0
set space 0
set tab off
set trimout on

SELECT 'EMAIL' || ',' || 'WELCOME_PROMO' ||',' || 'WELCOME_BARCODE'
  FROM DUAL;
  
SELECT ea.email_address || ',' || 
       CASE WHEN inout.email_address IS NOT NULL THEN ea.welcome_back_promo ELSE NULL END || ',' || 
	   CASE WHEN inout.email_address IS NOT NULL THEN ea.welcome_back_barcode ELSE NULL END 
  FROM O5.email_address ea, (SELECT email_address, MAX(opt_dt) out_dt
          FROM O5.email_opt_inout io
         WHERE io.opt_in = 0
         GROUP BY email_address) inout
 WHERE TRUNC (ea.cheetah_extract_dt) = TRUNC (SYSDATE)
   AND (TRUNC (ea.reopt_in_chg_dt) > trunc(ea.sys_entry_dt) or
       trunc (ea.opt_in_chg_dt) > trunc(ea.sys_entry_dt))
   AND ea.opt_in = 1
   AND ea.valid_ind = 1
   AND ea.orig_opt_dt is not null
   AND ea.email_address = inout.email_address(+)
   AND inout.out_dt(+) <= trunc(SYSDATE) - 183
;
exit
