set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
SELECT ema.email_id||'|'||
      replace(ema.email_address,'|')||'|'||
       CASE
          WHEN (title IS NOT NULL AND title IN (0,1,2,3,4,5)
               )
             THEN (CASE
                      WHEN title = 0
                         THEN 'Miss'
                      WHEN title = 1
                         THEN 'MS.'
                      WHEN title = 2
                         THEN 'MRS.'
                      WHEN title = 3
                         THEN 'MR.'
                      WHEN title = 4
                         THEN 'DR.'
                      ELSE NULL
                   END
                  )
       ELSE ' ' END ||'|'||
       ema.first_name||'|'||
       ema.middle_name||'|'||
       ema.last_name||'|'||
       ema.address||'|'||
       ema.address_two||'|'||
       ema.city||'|'||
       ema.state||'|'||
       ema.zip
  FROM O5.email_address ema --, sddw.email_detail_trans dts
 WHERE ema.valid_ind = 1
     and add_dt > '16-SEP-2013'
         AND NOT EXISTS (SELECT internetaddress
                           FROM O5.bi_customer c
                          WHERE c.internetaddress = ema.email_address)
         AND (ema.self_select_gender_ind is null or
              ema.self_select_gender_ind = 'N')
         AND ema.first_name IS NOT NULL;
-- removed the entry_dt and modify_dt check where it included only one week's data,going forward we need to include everything - changed by Divya Kafle on 05/02/2011
--         AND ((entry_dt between trunc(sysdate)-8 and trunc(sysdate)-1)
--          or  (MODIFY_DT between trunc(sysdate)-8 and trunc(sysdate)-1));
---------------------------------------------------------
--Merge sent email into O5.email_gender_history table
--Added self_select_gender_ind check on 9/21/2009
-- Where clause last changed by Liya Aizenberg on 04/22/2011
--------------------------------------------------------
--MERGE INTO O5.email_gender_history hst
--USING (SELECT ema.email_id, ema.gender, SYSDATE sent_date
--       FROM O5.email_address ema
--      WHERE ema.valid_ind = 1
--         and add_dt > '16-SEP-2013'
--         AND NOT EXISTS (SELECT internetaddress
--                           FROM O5.bi_customer c
--                          WHERE c.internetaddress = ema.email_address)
--         AND (ema.self_select_gender_ind is null or
--              ema.self_select_gender_ind = 'N')
--         AND ema.first_name IS NOT NULL
---- removed the entry_dt and modify_dt check where it included only one week's data, going forward we need to include everything - changed by Divya Kafle on 05/02/2011
----         AND ((entry_dt between trunc(sysdate)-8 and trunc(sysdate)-1)
----          or  (MODIFY_DT between trunc(sysdate)-8 and trunc(sysdate)-1))
--) trn
--ON (trn.email_id = hst.email_id)
--WHEN MATCHED
--THEN
--   UPDATE SET hst.gender = trn.gender, hst.sent_date = trn.sent_date
--WHEN NOT MATCHED
--THEN
--   INSERT (email_id, gender, sent_date)
--   VALUES (trn.email_id, trn.gender, trn.sent_date);
--COMMIT;
quit
