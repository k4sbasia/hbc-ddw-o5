whenever sqlerror exit failure
set pagesize 0
set echo off
set feedback on
set sqlprompt ''
set heading off
set trimspool on
set serverout on
set timing on
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------------------
--Set internetaddress = trim(upper(internetaddress)) in bi_customer 
----------------------------------------------------------------------------------
UPDATE O5.bi_customer
set internetaddress = trim(upper(internetaddress))
;
COMMIT;
exec dbms_output.put_line ('Customer internetaddress update complete');
---------------------------------------------------------------------------
--------------------------------------------------------------------------
--Updated Buyer Logic based on the email first order date
--------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Update email_address table with first order date 
--based on customer and sale tables
--------------------------------------------------------------------------------
MERGE INTO O5.EMAIL_ADDRESS HST
   USING (SELECT DISTINCT sub.email_address, sub.ford_dt
            from (select EMA.EMAIL_ADDRESS, min (ORDERDATE) FORD_DT
                    from O5.BI_SALE S, O5.EMAIL_ADDRESS EMA,
                    O5.BI_CUSTOMER C
                    where S.createfor = C.CUSTOMER_ID
                    and C.INTERNETADDRESS=EMA.EMAIL_ADDRESS
		    and ORDHDR_STATUS not  in ('N')
                    and ORDLINE_STATUS in ('X','R','D')
                    GROUP BY  ema.email_address ) sub) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.ford_dt = trn.ford_dt
   WHEN NOT MATCHED THEN
      INSERT (email_address, ford_dt)
      values (TRN.EMAIL_ADDRESS, TRN.FORD_DT);
COMMIT ;

exec dbms_output.put_line ('First Order Date update complete');
----------------------------------------------------------------------------------
----Update email_address table with last order date 
----based on customer and sale tables
----------------------------------------------------------------------------------
MERGE INTO O5.EMAIL_ADDRESS HST
   USING (SELECT DISTINCT sub.email_address, sub.lord_dt
            from (select EMA.EMAIL_ADDRESS, max (ORDERDATE) LORD_DT
                     from O5.BI_SALE S, O5.EMAIL_ADDRESS EMA,
                     O5.BI_CUSTOMER C
                     where S.createfor = C.CUSTOMER_ID
                    and C.INTERNETADDRESS=EMA.EMAIL_ADDRESS
		    and ORDHDR_STATUS not  in ('N')
                    and ORDLINE_STATUS in ('X','R','D')
                  GROUP BY  ema.email_address ) sub ) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.lord_dt = trn.lord_dt
   WHEN NOT MATCHED THEN
      INSERT (email_address, lord_dt)
      values (TRN.EMAIL_ADDRESS, TRN.LORD_DT);
COMMIT;
exec dbms_output.put_line ('Last Order Date update complete');
------------------------------------------------------------------------------
--Truncate O5.email_cheetah_segment table prior to loading
----------------------------------------------------------------------------
truncate table O5.email_cheetah_segments;
exec dbms_output.put_line ('segment table truncation complete');
--------------------------------------------------------------------------
--New Buyer Segment
--Customers who have made a purchase over 6 months ago
--------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT ema.email_address, 'NEWBUYER' buyer_status
                     FROM O5.email_address ema
                    WHERE ema.valid_ind = 1
                      AND ema.opt_in = 1
                      AND lord_dt >= TRUNC (SYSDATE) - 183) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Newbuyer segment update complete');
--------------------------------------------------------------------------
--Latent Buyer
--Customers whose last purchase was 7-12 months ago.
--------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT ema.email_address, 'LATENT' buyer_status
                     FROM O5.email_address ema
                    WHERE ema.valid_ind = 1
                      AND ema.opt_in = 1
                      AND ema.lord_dt BETWEEN TRUNC (SYSDATE) - 365
                                          AND TRUNC (SYSDATE) - 183) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Latent buyer segment update complete');
-----------------------------------------------------------------------
--New Non-Buyer
-- Customers who were added to the system within the last 6 Months
-- and have not made a purchase.
-----------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT email_address, 'NEWNON' buyer_status
           FROM O5.email_address ema
                   WHERE ema.valid_ind = 1
                     AND ema.opt_in = 1
                     AND ema.lord_dt is null ---[2011.05.31][divya]added lord_dt check
                     AND TRUNC (ema.add_dt) >= TRUNC (SYSDATE) - 183 
                     AND NOT EXISTS ( 
                                SELECT 1 FROM O5.bi_sale sal, O5.bi_customer c
                                  WHERE c.customer_id=sal.createfor 
		    		and ORDHDR_STATUS not  in ('N')
                    		and ORDLINE_STATUS in ('X','R','D')
				and c.internetaddress=ema.email_address)) trn                
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Newnon buyer segment update complete');
------------------------------------------------------------------------------
--Lapsed 
--Customers whose last purchase was 13-18 months ago. 
------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT ema.email_address, 'LAPSED' buyer_status
                     FROM O5.email_address ema
                    WHERE ema.valid_ind = 1
                      AND ema.opt_in = 1
                      AND ema.lord_dt BETWEEN TRUNC (SYSDATE) - 548
                                      AND TRUNC (SYSDATE) - 366) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Lapsed buyer segment update complete');
-------------------------------------------------------------------------------
--ATTRITED
--Customers who last purchase was over 18 months ago. 
-------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT ema.email_address, 'ATTRITED' buyer_status
                     FROM O5.email_address ema
                    WHERE ema.valid_ind = 1
                      AND ema.opt_in = 1
                      AND ema.lord_dt <= TRUNC (SYSDATE) - 549) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Attrited buyer segment update complete');
-----------------------------------------------------------------------------
--Non-Buyer
--Customers who have added to the system prior to 6 
--months ago and have not made a purchase.
-----------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT email_address, 'NON' buyer_status
          FROM O5.email_address ema
          WHERE ema.valid_ind = 1
                 AND ema.opt_in = 1
                 AND ema.lord_dt is null ---[2011.05.31][divya]added ford_dt check
                 AND ema.add_dt <= TRUNC (SYSDATE) - 184 
   		 AND NOT EXISTS (
                   SELECT 1 FROM O5.bi_sale sal, O5.bi_customer c
                            WHERE c.customer_id=sal.createfor 
		    	and ORDHDR_STATUS not  in ('N')
                    	and ORDLINE_STATUS in ('X','R','D')
			and c.internetaddress=ema.email_address)) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_status = trn.buyer_status
   WHEN NOT MATCHED THEN
      INSERT (email_address, buyer_status)
      VALUES (trn.email_address, trn.buyer_status);
COMMIT ;
exec dbms_output.put_line ('Non buyer segment update complete');
----------------------------------------------------------------------------------
----VIP1
----Customers who spent between $1000 and $2500 demand dollars within the last 12 months.
/*
---------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT email_address, '1' vip
                     FROM 
                          (SELECT   SUM (ROUND (demand_dollars)) DEMAND,
                                       ema.email_address
                               FROM  O5.email_address ema, sddw.mv_o5_bi_sale sal
                              WHERE ema.customer_id = sal.customer_id
                                AND TRUNC (orderdate) >= TRUNC (SYSDATE) - 365
                                AND ORDERSTATUS NOT IN ('Q', 'T', 'M')
				AND ORDER_HEADER_STATUS not in ('N')
                    		and ORDERSTATUS in ('X','R','D')
                                AND ema.valid_ind = 1
                                AND ema.opt_in = 1
                                GROUP BY ema.email_address ) dmd
                    WHERE 
                      dmd.DEMAND BETWEEN '1000' AND '2499') trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.vip = trn.vip
   WHEN NOT MATCHED THEN
      INSERT (email_address, vip)
      VALUES (trn.email_address, trn.vip);
COMMIT ;
exec dbms_output.put_line ('VIP segment update complete');
----------------------------------------------------------------------------------
----VIP2
----Customers who spent more than $2500 demand dollars within the last 12 months.
----------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT email_address, '2' vip
                     FROM 
                          (SELECT   SUM (ROUND (demand_dollars)) DEMAND,
                                       ema.email_address
                               FROM  O5.email_address ema, sddw.mv_o5_bi_sale sal
                              WHERE ema.customer_id = sal.customer_id
                                AND TRUNC (orderdate) >= TRUNC (SYSDATE) - 365
                                AND orderstatus NOT IN ('Q', 'T', 'M')
				AND ORDER_HEADER_STATUS not in ('N')
                    		and ORDERSTATUS in ('X','R','D')
                                AND ema.valid_ind = 1
                                AND ema.opt_in = 1
                                GROUP BY ema.email_address ) dmd
                    WHERE 
                        dmd.DEMAND > '2500') trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.vip = trn.vip
   WHEN NOT MATCHED THEN
      INSERT (email_address, vip)
      VALUES (trn.email_address, trn.vip);
COMMIT ;
exec dbms_output.put_line ('VIP2 segment update complete');
-------------------------------------------------------------------------------
--Sale Shopper
--Customers that have demand where the price is lower than the offer price.
-------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT DISTINCT ema.email_address, 'T' sale_shopper
                     FROM O5.email_address ema
                    WHERE ema.valid_ind = 1
                      AND ema.opt_in = 1
                      AND EXISTS (
                             SELECT 1
                               FROM sddw.mv_o5_bi_sale sal
                              WHERE ema.customer_id = sal.customer_id
                                AND orderstatus NOT IN ('Q', 'T', 'M')
				AND ORDER_HEADER_STATUS not in ('N')
                    		and ORDERSTATUS in ('X','R','D')
                                AND price < origprice
                                )) trn 
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.sale_shopper = trn.sale_shopper
   WHEN NOT MATCHED THEN
      INSERT (email_address, sale_shopper)
      VALUES (trn.email_address, trn.sale_shopper);
COMMIT ;
exec dbms_output.put_line ('Sale Shopper segment update complete');
-------------------------------------------------------------------------------
--Update Spend type
--Updates buyer_type field with the total demand_dollars spend for the categories below.
-------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT   email_address, SUM (spend_sd_classic) spend_sd_classic,
                   SUM (spend_sd_contemporary) spend_sd_contemporary,
                   SUM (spend_sd_cosmetic) spend_sd_cosmetic,
                   SUM (spend_sd_designer) spend_sd_designer,
                   SUM (spend_sd_evening) spend_sd_evening,
                   SUM (spend_sd_gifts) spend_sd_gifts,
                   SUM (spend_sd_gold_range) spend_sd_gold_range,
                   SUM (spend_sd_home) spend_sd_home,
                   SUM (spend_sd_jewelry) spend_sd_jewelry,
                   SUM (spend_sd_kids) spend_sd_kids,
                   SUM (spend_sd_mens) spend_sd_mens,
                   SUM (spend_sd_modern) spend_sd_modern,
                   SUM (spend_sd_outerwear_swim) spend_sd_outerwear_swim,
                   SUM (spend_sd_salonz) spend_sd_salonz,
                   SUM (spend_sd_shoe_bag) spend_sd_shoe_bag,
                   SUM (spend_sd_soft_acc) spend_sd_soft_acc
              FROM (SELECT   e.email_address,
                             SUM
                                ((CASE
                                     WHEN division_id = 1
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_designer,
                             SUM
                                ((CASE
                                     WHEN division_id = 3
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_mens,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (36, 39)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_shoe_bag,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (13, 18)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_jewelry,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 25 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_contemporary,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (21, 60, 61, 15)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_modern,
                             SUM
                                ((CASE
                                     WHEN division_id = 7
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_home,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (21, 60, 61, 15)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_classic,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 38 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_gifts,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (28, 29)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_cosmetic,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 35 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_kids,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 08 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_salonz,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 22 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_gold_range,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID IN (14, 24)
                                     AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_evening,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 11 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_outerwear_swim,
                             SUM
                                ((CASE
                                     WHEN GROUP_ID = 19 AND demand_dollars > 0
                                        THEN demand_dollars
                                     ELSE 0
                                  END
                                 )
                                ) spend_sd_soft_acc
                        FROM O5.email_address ema,
                             sddw.mv_o5_bi_sale s,
                             O5.email_cheetah_segments e
                       WHERE s.customer_id = ema.customer_id
				AND s.ORDER_HEADER_STATUS not in ('N')
                    		and s.ORDERSTATUS in ('X','R','D')
				 AND e.email_address=ema.email_address
                    GROUP BY e.email_address, demand_dollars)
          GROUP BY email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.spend_sd_classic = trn.spend_sd_classic,
             hst.spend_sd_contemporary = trn.spend_sd_contemporary,
             hst.spend_sd_cosmetic = trn.spend_sd_cosmetic,
             hst.spend_sd_designer = trn.spend_sd_designer,
             hst.spend_sd_evening = trn.spend_sd_evening,
             hst.spend_sd_gifts = trn.spend_sd_gifts,
             hst.spend_sd_gold_range = trn.spend_sd_gold_range,
             hst.spend_sd_home = trn.spend_sd_home,
             hst.spend_sd_jewelry = trn.spend_sd_jewelry,
             hst.spend_sd_kids = trn.spend_sd_kids,
             hst.spend_sd_mens = trn.spend_sd_mens,
             hst.spend_sd_modern = trn.spend_sd_modern,
             hst.spend_sd_outerwear_swim = trn.spend_sd_outerwear_swim,
             hst.spend_sd_salonz = trn.spend_sd_salonz,
             hst.spend_sd_shoe_bag = trn.spend_sd_shoe_bag,
             hst.spend_sd_soft_acc = trn.spend_sd_soft_acc
   WHEN NOT MATCHED THEN
      INSERT (spend_sd_classic, spend_sd_contemporary, spend_sd_cosmetic,
              spend_sd_designer, spend_sd_evening, spend_sd_gifts,
              spend_sd_gold_range, spend_sd_home, spend_sd_jewelry,
              spend_sd_kids, spend_sd_mens, spend_sd_modern,
              spend_sd_outerwear_swim, spend_sd_salonz, spend_sd_shoe_bag,
              spend_sd_soft_acc)
      VALUES (trn.spend_sd_classic, trn.spend_sd_contemporary,
              trn.spend_sd_cosmetic, trn.spend_sd_designer,
              trn.spend_sd_evening, trn.spend_sd_gifts,
              trn.spend_sd_gold_range, trn.spend_sd_home,
              trn.spend_sd_jewelry, trn.spend_sd_kids, trn.spend_sd_mens,
              trn.spend_sd_modern, trn.spend_sd_outerwear_swim,
              trn.spend_sd_salonz, trn.spend_sd_shoe_bag,
              trn.spend_sd_soft_acc);
COMMIT ;
exec dbms_output.put_line ('Spend Category update complete');
--------------------------------------------------------------------------------
--Buyer Type Update
--Update Buyer Status field based on Spend Types
--------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT email_address,
                 (  (CASE
                        WHEN ema.spend_sd_designer > 0
                           THEN POWER (2, 0)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_mens > 0
                           THEN POWER (2, 1)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_shoe_bag > 0
                           THEN POWER (2, 2)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_jewelry > 0
                           THEN POWER (2, 3)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_contemporary > 0
                           THEN POWER (2, 4)
                        ELSE 0
                     END
                    )
                  + (CASE
                        WHEN ema.spend_sd_modern > 0
                           THEN POWER (2, 5)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_classic > 0
                           THEN POWER (2, 6)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_cosmetic > 0
                           THEN POWER (2, 7)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_gifts > 0
                           THEN POWER (2, 8)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_home > 0
                           THEN POWER (2, 9)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_kids > 0
                           THEN POWER (2, 10)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_salonz > 0
                           THEN POWER (2, 11)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_gold_range > 0
                           THEN POWER (2, 12)
                        ELSE 0
                     END
                    )
                  + (CASE
                        WHEN ema.spend_sd_evening > 0
                           THEN POWER (2, 13)
                        ELSE 0
                     END)
                  + (CASE
                        WHEN ema.spend_sd_outerwear_swim > 0
                           THEN POWER (2, 14)
                        ELSE 0
                     END
                    )
                  + (CASE
                        WHEN ema.spend_sd_soft_acc > 0
                           THEN POWER (2, 15)
                        ELSE 0
                     END
                    )
                 ) buyer_type
            FROM O5.email_cheetah_segments ema) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.buyer_type = trn.buyer_type
   WHEN NOT MATCHED THEN
      INSERT (buyer_type)
      VALUES (trn.buyer_type);
COMMIT ;
exec dbms_output.put_line ('buyer_type segment update complete');
--------------------------------------------------------------------------------
--Vendor Update Merge
--Update Buyer Status field based on Spend Types
--------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT   email_address, SUM (vendor) vendor
              FROM (SELECT   e.email_address,
                               ((CASE
                                    WHEN vendor_id = '03970'
                                       THEN POWER (2, 0)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '07768'
                                       THEN POWER (2, 1)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '08582'
                                       THEN POWER (2, 2)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '13641'
                                       THEN POWER (2, 3)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '19539'
                                       THEN POWER (2, 4)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '02124'
                                       THEN POWER (2, 5)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '09100'
                                       THEN POWER (2, 6)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '10283'
                                       THEN POWER (2, 7)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id IN ('04035', '07135')
                                       THEN POWER (2, 8)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '01376'
                                       THEN POWER (2, 9)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '04242'
                                       THEN POWER (2, 10)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id IN ('13779', '07942')
                                       THEN POWER (2, 11)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '59276'
                                       THEN POWER (2, 13)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '17178'
                                       THEN POWER (2, 15)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '10385'
                                       THEN POWER (2, 16)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '06345'
                                       THEN POWER (2, 17)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '15257'
                                       THEN POWER (2, 18)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '01369'
                                       THEN POWER (2, 19)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '14461'
                                       THEN POWER (2, 21)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '11095'
                                       THEN POWER (2, 22)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '52139'
                                       THEN POWER (2, 23)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '45860'
                                       THEN POWER (2, 25)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '17792'
                                       THEN POWER (2, 28)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '19374'
                                       THEN POWER (2, 29)
                                    ELSE 0
                                 END
                                )
                               )
                             + ((CASE
                                    WHEN vendor_id = '18018'
                                       THEN POWER (2, 26)
                                    ELSE 0
                                 END
                                )
                               ) vendor
                        FROM sddw.mv_o5_bi_sale s,
                             O5.email_address e
                       WHERE e.customer_id = s.customer_id
                         AND e.opt_in = 1
                         AND e.valid_ind = 1
                         AND demand_dollars > 0
			AND s.ORDER_HEADER_STATUS not in ('N')
                    	and s.ORDERSTATUS in ('X','R','D')
                    GROUP BY email_address, vendor_id)
          GROUP BY email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.vendor = trn.vendor
   WHEN NOT MATCHED THEN
      INSERT (email_address, vendor)
      VALUES (trn.email_address, trn.vendor);
COMMIT ;
exec dbms_output.put_line ('Vendor Segment update complete');
--------------------------------------------------------------------------------
--Net Dollars by Category
--Demand Dollars less Cancel and Return dollars, group by category
------------------------------------------------------------------------------
MERGE INTO O5.email_cheetah_segments hst
   USING (SELECT   e.email_address,
                   SUM
                      ((CASE
                           WHEN division_id = 1
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_designer,
                   SUM
                      ((CASE
                           WHEN division_id = 3
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_mens,
                   SUM
                      ((CASE
                           WHEN GROUP_ID IN (36, 39)
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_shoe_bag,
                   SUM
                      ((CASE
                           WHEN GROUP_ID IN (13, 18)
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_jewelry,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 25
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_contemporary,
                   SUM
                      ((CASE
                           WHEN division_id = 7
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_home,
                   SUM
                      ((CASE
                           WHEN GROUP_ID IN (21, 60, 61, 15)
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_classic,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 38
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_gifts,
                   SUM
                      ((CASE
                           WHEN GROUP_ID IN (28, 29)
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_cosmetic,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 35
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_kids,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 08
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_salonz,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 22
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_gold_range,
                   SUM
                      ((CASE
                           WHEN GROUP_ID IN (14, 24)
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_evening,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 11
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_outerwear_swim,
                   SUM
                      ((CASE
                           WHEN GROUP_ID = 19
                              THEN (  demand_dollars
                                    - (cancel_dollars + return_dollars)
                                   )
                           ELSE 0
                        END
                       )
                      ) net_dollars_soft_acc
              FROM sddw.mv_o5_bi_sale s,
			 O5.email_address ema,
                   O5.email_cheetah_segments e
             WHERE s.customer_id = ema.customer_id 
		 	AND ema.email_address=e.email_address     
				AND s.ORDER_HEADER_STATUS not in ('N')
                    		and s.ORDERSTATUS in ('X','R','D')     
          GROUP BY e.email_address) trn
   ON (hst.email_address = trn.email_address)
   WHEN MATCHED THEN
      UPDATE
         SET hst.net_dollars_classic = trn.net_dollars_classic,
             hst.net_dollars_contemporary = trn.net_dollars_contemporary,
             hst.net_dollars_cosmetic = trn.net_dollars_cosmetic,
             hst.net_dollars_designer = trn.net_dollars_designer,
             hst.net_dollars_evening = trn.net_dollars_evening,
             hst.net_dollars_gifts = trn.net_dollars_gifts,
             hst.net_dollars_gold_range = trn.net_dollars_gold_range,
             hst.net_dollars_home = trn.net_dollars_home,
             hst.net_dollars_jewelry = trn.net_dollars_jewelry,
             hst.net_dollars_kids = trn.net_dollars_kids,
             hst.net_dollars_mens = trn.net_dollars_mens,
             hst.net_dollars_outerwear_swim = trn.net_dollars_outerwear_swim,
             hst.net_dollars_salonz = trn.net_dollars_salonz,
             hst.net_dollars_shoe_bag = trn.net_dollars_shoe_bag,
             hst.net_dollars_soft_acc = trn.net_dollars_soft_acc
   WHEN NOT MATCHED THEN
      INSERT (email_address, net_dollars_classic, net_dollars_contemporary,
              net_dollars_cosmetic, net_dollars_designer, net_dollars_evening,
              net_dollars_gifts, net_dollars_gold_range, net_dollars_home,
              net_dollars_jewelry, net_dollars_kids, net_dollars_mens,
              net_dollars_outerwear_swim,
              net_dollars_salonz, net_dollars_shoe_bag, net_dollars_soft_acc)
      VALUES (trn.email_address, trn.net_dollars_classic,
              trn.net_dollars_contemporary, trn.net_dollars_cosmetic,
              trn.net_dollars_designer, trn.net_dollars_evening,
              trn.net_dollars_gifts, trn.net_dollars_gold_range,
              trn.net_dollars_home, trn.net_dollars_jewelry,
              trn.net_dollars_kids, trn.net_dollars_mens,
              trn.net_dollars_outerwear_swim,
              trn.net_dollars_salonz, trn.net_dollars_shoe_bag,
              trn.net_dollars_soft_acc);
COMMIT ; 
*/
exec dbms_output.put_line ('Net dollars by category segment update complete');
exec dbms_output.put_line ('Cheetah Segment Update complete');
exit
