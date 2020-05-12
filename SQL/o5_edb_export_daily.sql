set timing on

UPDATE O5.welcome_promocodes wpr
   SET use_status = 'U'
 WHERE EXISTS (
          SELECT welcome_promo
            FROM O5.email_address ema
           WHERE ema.welcome_promo = wpr.promo_code
             or  ema.welcome_back_promo = wpr.promo_code )
         and use_status is null ;
commit;

UPDATE O5.store_barcode wpr
   SET use_status = 'U'
 where exists (
          SELECT barcode
            from O5.EMAIL_ADDRESS EMA
           WHERE ema.barcode = wpr.barcode
              )
         and use_status is null ;
commit;

MERGE INTO O5.email_address hst
   USING (SELECT distinct ema.email_id, wpr.promo_code
            FROM O5.email_address ema, O5.V_WELCOME_PROMOCODES_AMS wpr
           WHERE ema.email_id = wpr.email_id
             AND valid_ind = 1
             AND ((opt_in = 1 AND trunc(orig_opt_dt) >= sysdate-180 AND orig_opt_dt is not null))
             AND trunc(add_dt) > '15-SEP-2013'
	     and ema.welcome_promo is null
	     AND NOT EXISTS (SELECT welcome_promo
                               FROM O5.email_address ema1
                              WHERE wpr.promo_code = ema1.welcome_promo)
	     and not exists
		(select 1 from o5.edb_overlay_email_address o where o.email_address=ema.email_address)
		) trn
   ON (hst.email_id = trn.email_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.welcome_promo = trn.promo_code
   WHEN NOT MATCHED THEN
      INSERT (welcome_promo)
      VALUES (NULL);
commit;


UPDATE O5.welcome_promocodes wpr
   SET use_status = 'U'
 WHERE EXISTS (
          SELECT welcome_promo
            FROM O5.email_address ema
           WHERE ema.welcome_promo = wpr.promo_code
             or  ema.welcome_back_promo = wpr.promo_code )
         and use_status is null ;
commit;

UPDATE O5.edb_overlay_offer_codes wpr
   SET use_status = 'U'
 WHERE EXISTS (
          SELECT welcome_promo
            FROM O5.email_address ema
           WHERE ema.welcome_promo = wpr.promo_code  )
         and use_status is null ;
commit;

MERGE INTO O5.email_address hst
   USING (SELECT distinct ema.email_id, wpr.promo_code, wpr.bar_code
            FROM O5.email_address ema, O5.v_edb_overlay_promo_codes wpr 
           WHERE ema.email_id = wpr.email_id
             AND valid_ind = 1
             AND ((opt_in = 1 AND trunc(orig_opt_dt) >= sysdate-180 AND orig_opt_dt is not null))
             AND trunc(add_dt) > '08-FEB-2015'
	     and ema.welcome_promo is null
	     AND NOT EXISTS (SELECT welcome_promo
                               FROM O5.email_address ema1
                              WHERE wpr.promo_code = ema1.welcome_promo)
	     and exists
		(select 1 from o5.edb_overlay_email_address o where o.email_address=ema.email_address)
		) trn
   ON (hst.email_id = trn.email_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.welcome_promo = trn.promo_code,
		  hst.barcode = trn.bar_code  
;
commit;

UPDATE O5.edb_overlay_offer_codes wpr
   SET use_status = 'U'
 WHERE EXISTS (
          SELECT welcome_promo
            FROM O5.email_address ema
           WHERE ema.welcome_promo = wpr.promo_code  )
         and use_status is null ;
commit;

MERGE INTO O5.email_address hst
   USING (SELECT distinct ema.email_id,WPR.BARCODE
            FROM O5.email_address ema,O5.V_STORE_BARCODES WPR
           WHERE ema.email_id = wpr.email_id
             AND valid_ind = 1
             AND ((opt_in = 1 AND trunc(orig_opt_dt) >= sysdate-180 AND orig_opt_dt is not null))
             and TRUNC(SYS_ENTRY_DT) > '15-SEP-2013' and TRUNC(SYS_ENTRY_DT) < TO_DATE('24-JUL-2017','DD-MON-YYYY') ---- added on 7/13/2017 as Marketing requested to pass the barcode same as the welcome_promo from 7/24/2017
             and ema.barcode is null
             AND NOT EXISTS (SELECT barcode
                               from O5.EMAIL_ADDRESS EMA1
                              WHERE wpr.barcode = ema1.barcode)
			 AND not exists
		     (select 1 from o5.edb_overlay_email_address o where o.email_address=ema.email_address)
							  ) trn
   ON (hst.email_id = trn.email_id)
   WHEN MATCHED THEN
      update
         SET hst.barcode = trn.barcode;
commit;

---- added on 7/13/2017 as Marketing requested to pass the barcode same as the welcome_promo from 7/24/2017
UPDATE O5.email_address
SET barcode = welcome_promo
WHERE TRUNC(SYS_ENTRY_DT) >= TO_DATE('24-JUL-2017','DD-MON-YYYY');

commit;


UPDATE O5.store_barcode wpr
   SET use_status = 'U'
 where exists (
          SELECT barcode
            from O5.EMAIL_ADDRESS EMA
           WHERE ema.barcode = wpr.barcode
              )
         and use_status is null ;
commit;

------------------------------------------------------------------------
-- sub - email_cheetah_new_delta.sql

--UPDATE O5.email_address
--   SET cheetah_extract_dt = SYSDATE
-- WHERE TRUNC (sys_entry_dt) = TRUNC (SYSDATE)
--   AND opt_in = 1
--   AND valid_ind = 1
--   AND add_by_source_id <> '9104'
--   AND email_address LIKE '%@%'
--   AND email_address LIKE '%.%'
--   ;
--commit;


--------------------------

MERGE INTO O5.email_address tg
USING (SELECT email_address, decode(intcs, 'T', 'T', NULL) international_ind
         FROM (SELECT ea.email_address
                     ,decode(ea.international_ind, NULL, 'F', 'T') inte
                     ,greatest(MAX(decode(nvl(c.country, 'US'), 'US', 'F',
                                          'T')),
			MAX(decode(nvl(ea.canada_flag,'N'),'N',decode(nvl(s.ship_country, 'US'), 'US', 'F','T'),'T'))) intcs
                 FROM O5.email_address ea
                     ,O5.bi_customer   c
                     ,O5.bi_sale       s
                WHERE ea.email_address = upper(c.internetaddress(+))
                      AND c.customer_id = s.createfor(+)
                GROUP BY ea.email_address
                        ,decode(ea.international_ind, NULL, 'F', 'T'))
        WHERE inte <> intcs) src
ON (tg.email_address = src.email_address)
WHEN MATCHED THEN
  UPDATE SET tg.international_ind = src.international_ind;
commit;

------------------------------------------------------------------------
-- reopt - email_cheetah_reopt.sql

UPDATE O5.email_address
   SET cheetah_extract_dt = SYSDATE
 WHERE (   TRUNC (reopt_in_chg_dt) = TRUNC (SYSDATE)
        OR TRUNC (opt_in_chg_dt) = TRUNC (SYSDATE))
   AND TRUNC (reopt_in_chg_dt) > TRUNC (sys_entry_dt)
   AND TRUNC (opt_in_chg_dt) > TRUNC (sys_entry_dt)
   AND orig_opt_dt is not null
   AND opt_in = 1
   AND valid_ind = 1
   AND opt_in_chg_by_source_id <> '9104'
   AND email_address LIKE '%@%'
   AND email_address LIKE '%.%';
commit;

--exec DBMS_MVIEW.refresh('sddw.mv_o5_email_address', 'C');
--show errors;

exit
