whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on
--  08/16 international flag set for billing address is not US too
--Change Control 200:11:24 Added 'Y','N' to international Customer flag
--Change Control 2009:11:20 Added International Customer Flag
-- Added Birthday Merge on 09/04/2009 
-- Added gender routine to set null gender = 'U'
-- Added email_id to genderal merge on 2009:10:12
---------------------------------------------------------------------------------
----Sweep Stakes Segment Update
----Based on Saks Quick Email Table
---------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Non Buyer Saks First Segment Update based on Matchcode and Saks First File
-------------------------------------------------------------------------------
--Create Email Matchcode Table
-------------------------------------------------------------------------------
drop table dm_user.email_matchcode;

create table dm_user.email_matchcode
as
select email_address
,upper(substr(replace(replace(replace(replace(replace(replace(replace(zip,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5)||
 substr(replace(replace(replace(replace(replace(replace(replace(last_name,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5) ||
 substr(replace(replace(replace(replace(replace(replace(replace(first_name,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,1) ||
 substr(replace(replace(replace(replace(replace(replace(replace(address,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5)) MATCHCODE
 from O5.email_address;

exec dbms_output.put_line ('Email Matchcode Table Created');

show errors;
-------------------------------------------------------------------------------
--Create Saks First Matchcode Table
-------------------------------------------------------------------------------
drop table dm_user.saks_first_matchcode;

CREATE TABLE dm_user.saks_first_matchcode
AS
SELECT
  saks_first_number,
  title,
  first_name,
  middle_name,
  last_name,
  addr,
  addr2,
  city,
  state,
  zip,
  tier_info,
  SYSDATE add_dt,
  account_type,
  UPPER(SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(zip,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5)||
 SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(last_name,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5) ||
 SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(first_name,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,1) ||
 SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(addr,' ','')
 ,',',''),'.',''),'''',''),'"',''),'-',''),'_',''),1,5)) matchcode
FROM mrep.bi_saks_first
;

exec dbms_output.put_line ('Saks First Matchcode Table Created');

show errors;
-------------------------------------------------------------------
--Initialize saks_first to null
--------------------------------------------------------------------
UPDATE O5.email_address
   SET saks_first = NULL;
COMMIT ;
----------------------------------------------------------------------
--Merge non-buyers into Saks First Merge based on Matchcode 
--in O5.email_address table and saks first file.
----------------------------------------------------------------------
MERGE INTO O5.email_address hst
   USING (
   SELECT bb.email_address,
                 (CASE
                     WHEN bb.tier_order = '6'                   -- Un-Enrolled
                        THEN 'UN-ENROLLED'
                     WHEN bb.tier_order = '5'                 -- Entry Premier
                        THEN 'ENTRY_PREMIER'
                     WHEN bb.tier_order = '1'                       -- Diamond
                        THEN 'DIAMOND'
                     WHEN bb.tier_order = '4'                       -- Premier
                        THEN 'PREMIER'
                     WHEN bb.tier_order = '3'                         -- Elite
                        THEN 'ELITE'
                     WHEN bb.tier_order = '2'                      -- Platinum
                        THEN 'PLATINUM'
                  END
                 ) saks_first_level
            FROM (SELECT DISTINCT aa.email_address,
                                  MIN (aa.tier_order) tier_order
                             FROM (SELECT mat.email_address, sfa.tier_info,
                                          (CASE
                                              WHEN sfa.tier_info = 'A'
                                                 -- Un-Enrolled
                                           THEN 6
                                              WHEN sfa.tier_info = 'C'
                                                 -- Entry Premier
                                           THEN 5
                                              WHEN sfa.tier_info = 'D'
                                                 -- Diamond
                                           THEN 1
                                              WHEN sfa.tier_info = 'V'
                                                 -- Premier
                                           THEN 4
                                              WHEN sfa.tier_info = 'W'
                                                 -- Elite
                                           THEN 3
                                              WHEN sfa.tier_info = 'Z'
                                                 -- Platinum
                                           THEN 2
                                           END
                                          ) tier_order
                                     FROM dm_user.email_matchcode mat,
                                          dm_user.saks_first_matchcode sfa
                                    WHERE mat.matchcode = sfa.matchcode
                                    AND   sfa.tier_info in ('A','C','D','V','W','Z')) aa
                         GROUP BY aa.email_address) bb)trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.saks_first = trn.saks_first_level
   WHEN NOT MATCHED THEN
      INSERT (email_address, saks_first)
      VALUES (trn.email_address, trn.saks_first_level);
COMMIT ;
exec dbms_output.put_line ('Non-Buyer Saks First Merge complete');
--------------------------------------------------------------------------------
--Merge buyer saks first tier from bi_customer table
--------------------------------------------------------------------------------
MERGE INTO O5.email_address hst
   USING (SELECT bb.email_address,
                 (CASE
                     WHEN bb.tier_order = '6'                   -- Un-Enrolled
                        THEN 'UN-ENROLLED'
                     WHEN bb.tier_order = '5'                 -- Entry Premier
                        THEN 'ENTRY_PREMIER'
                     WHEN bb.tier_order = '1'                       -- Diamond
                        THEN 'DIAMOND'
                     WHEN bb.tier_order = '4'                       -- Premier
                        THEN 'PREMIER'
                     WHEN bb.tier_order = '3'                         -- Elite
                        THEN 'ELITE'
                     WHEN bb.tier_order = '2'                      -- Platinum
                        THEN 'PLATINUM'
                  END
                 ) saks_first_level
            FROM (SELECT DISTINCT aa.email_address,
                                  MIN (aa.tier_order) tier_order
                             FROM (SELECT cus.internetaddress email_address,
                                          saks_first_tier,
                                          (CASE
                                              WHEN cus.saks_first_tier = 'A'
                                                 -- Un-Enrolled
                                           THEN 6
                                              WHEN cus.saks_first_tier = 'C'
                                                 -- Entry Premier
                                           THEN 5
                                              WHEN cus.saks_first_tier = 'D'
                                                 -- Diamond
                                           THEN 1
                                              WHEN cus.saks_first_tier = 'V'
                                                 -- Premier
                                           THEN 4
                                              WHEN cus.saks_first_tier = 'W'
                                                 -- Elite
                                           THEN 3
                                              WHEN cus.saks_first_tier = 'Z'
                                                 -- Platinum
                                           THEN 2
                                           END
                                          ) tier_order
                                     FROM O5.email_address ema,
                                          O5.bi_customer cus
                                    WHERE ema.email_address =
                                                           cus.internetaddress
                                      AND cus.saks_first_tier IN
                                                    ('C', 'D', 'V', 'W', 'Z')
                                      AND ema.saks_first IS NULL) aa
                         GROUP BY aa.email_address) bb) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.saks_first = trn.saks_first_level
   WHEN NOT MATCHED THEN
      INSERT (email_address, saks_first)
      VALUES (trn.email_address, trn.saks_first_level);
COMMIT ;
exec dbms_output.put_line ('Saks First Buyer Merge complete');
------------------------------------------------------------------------
--Merge saks_first_tier into O5.email_cheetah_segments
----------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT ema.email_address, saks_first
            FROM O5.email_address ema, O5.email_cheetah_segments seg
           WHERE ema.email_address = seg.email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.saksfirst = trn.saks_first
   WHEN NOT MATCHED THEN
      INSERT (email_address, saksfirst)
      VALUES (trn.email_address, trn.saks_first);
COMMIT;
exec dbms_output.put_line ('Update Saks First segment in cheetah_segments complete');          
----------------------------------------------------------------------------------
----Gender Merge from email_address into email_cheetah_segments
----------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT ema.email_address, ema.gender 
            FROM O5.email_address ema, O5.email_cheetah_segments seg
           WHERE ema.email_address = seg.email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.gender = trn.gender
   WHEN NOT MATCHED THEN
      INSERT (email_address, gender)
      VALUES (trn.email_address, trn.gender);
commit;
update O5.email_cheetah_segments 
set gender = 'U'
where (gender not in ('F','M','U')
       or gender is null);
commit;
exec dbms_output.put_line ('Gender Segment Merge complete'); 
-----------------------------------------------------------------------------
----Updates the add_dt, first_name, last_name, reporting_store, local_store, 
---- local_store_by_zip, mster_channel, master_source_id, 
----men, middle_name, modify_dt state, zip, sweep_stake segements and email_id.
------------------------------------------------------------------------------- 
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT ema.email_address, ema.add_dt, ema.first_name, ema.last_name,
                 ema.reporting_store local_store, ema.local_store_by_zip,
                 ms.channel master_channel,
                 ms.master_source_id master_source_id,
                 add_by_source_id source_id,
                 (CASE
                     WHEN ema.modify_dt IS NULL
                        THEN SYSDATE
                     ELSE ema.modify_dt
                  END
                 ) modify_dt,
                 ema.state, ema.zip, ema.welcome_promo, ema.ford_dt,
                 ema.lord_dt, ema.email_id, ms.cm_aid, ema.more_number
            FROM mrep.email_source es,
                 mrep.email_master_source ms,
                 O5.email_cheetah_segments cs,
                 O5.email_address ema
           WHERE ema.email_address = cs.email_address
             AND ema.add_by_source_id = es.source_id
             AND es.master_source_id = ms.master_source_id) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.add_dt = trn.add_dt, hst.first_name = trn.first_name,
             hst.last_name = trn.last_name, hst.local_store = trn.local_store,
             hst.local_store_by_zip = trn.local_store_by_zip,
             hst.master_channel = trn.master_channel,
             hst.master_source_id = trn.master_source_id,
             hst.source_id = trn.source_id, hst.modify_dt = trn.modify_dt,
             hst.state = trn.state, hst.zip = trn.zip,
             hst.welcome_promo = trn.welcome_promo, hst.ford_dt = trn.ford_dt,
             hst.lord_dt = trn.lord_dt, hst.email_id = trn.email_id,
	     hst.cm_aid=trn.cm_aid, hst.more_number =trn.more_number
   WHEN NOT MATCHED THEN
      INSERT (email_address, add_dt, first_name, last_name, local_store,
              local_store_by_zip, master_channel, master_source_id, source_id,
              modify_dt, state, zip, welcome_promo, ford_dt, lord_dt, email_id, cm_aid, more_number)
      VALUES (trn.email_address, trn.add_dt, trn.first_name, trn.last_name,
              trn.local_store, trn.local_store_by_zip, trn.master_channel,
              trn.master_source_id, trn.source_id, trn.modify_dt, trn.state,
              trn.zip, trn.welcome_promo, trn.ford_dt, trn.lord_dt, trn.email_id, trn.cm_aid, trn.more_number
             );
COMMIT ;
exec dbms_output.put_line ('General Segment Merge complete');
------------------------------------------------------------------------------
--Birthday Merge
-----------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT ema.email_address,
                    CASE
                       WHEN LENGTH (bday_month) < 2
                          THEN 0 || bday_month
                       ELSE TO_CHAR (bday_month)
                    END
                 || '/'
                 || CASE
                       WHEN LENGTH (bday_day) < 2
                          THEN 0 || bday_day
                       ELSE TO_CHAR (bday_day)
                    END
                 || '/'
                 || 1900 bdate
            FROM O5.email_address ema, O5.email_cheetah_segments seg
           WHERE valid_ind = 1
             AND opt_in = 1
             AND bday_day BETWEEN 1 AND 31
             AND bday_month BETWEEN 1 AND 12
             AND ema.email_address = seg.email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.bdate = trn.bdate
   WHEN NOT MATCHED THEN
      INSERT (email_address, bdate)
      VALUES (trn.email_address, trn.bdate);
COMMIT ;
exec dbms_output.put_line ('Birthday Segment Merge Complete');
----------------------------------------------------------------
--International Customer Flag
---------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
USING (SELECT DISTINCT e.email_address, 'Y' international_customer
       FROM O5.email_cheetah_segments e, O5.bi_customer c, O5.bi_sale s
       WHERE     e.email_address = c.internetaddress
             AND s.createfor = c.customer_id
             AND email_address NOT LIKE 'E4X%'
             AND (s.international_ind = 'T' or nvl(c.country,'US') <> 'US')) trn
ON (hst.email_address = trn.email_address)
WHEN MATCHED
THEN
   UPDATE SET hst.international_customer   = trn.international_customer
WHEN NOT MATCHED
THEN
   INSERT (email_address, international_customer)
   VALUES (trn.email_address, trn.international_customer);
COMMIT;
exec dbms_output.put_line ('International Customer Merge Complete');
exec dbms_output.put_line ('Cheetah Segment Merge Complete');
exit
