set echo off        
set feedback on    
set linesize 10000    
set pagesize 0      
set sqlprompt ''    
set heading off
set trimspool on 
set serverout on
set timing on

UPDATE o5.bi_individual
SET ford_dt                   = NULL,
    lord_dt                   = NULL,
    saks_first_tier           = ' ',
    prim_addr_cust            = NULL,
    store_of_res              = NULL,
    prime_state               = NULL,
    prime_zipcode             = NULL,
    repeat_customer_month     = NULL,
    repeat_customer_quarter   = NULL,
    repeat_customer_season    = NULL,
    repeat_customer_year      = NULL,
    new_customer_month        = NULL,
    new_customer_quarter      = NULL,
    new_customer_season       = NULL,
    new_customer_year         = NULL,
    monetary_month            = NULL,
    monetary_quarter          = NULL,
    monetary_season           = NULL,
    monetary_year             = NULL,
    frequency_month           = NULL,
    frequency_quarter         = NULL,
    frequency_season          = NULL,
    frequency_year            = NULL,
    recency                   = NULL;
    commit;
exec dbms_output.put_line ('BI_Individual Attribute fields truncated');
-- Update BI_Individual FORD 
 
MERGE INTO o5.bi_individual hst
   USING ( select individual_id, min(ford_dt) FORD_DT
                     FROM o5.bi_customer c
		     WHERE c.individual_id is not NULL -- Temperory fix to address the new accounts for which individual_id is not yet assigned by Prime.
                     GROUP BY INDIVIDUAL_ID
                      ) trn
   ON ( hst.individual_id = trn.individual_id)
   WHEN MATCHED THEN
   UPDATE
         SET hst.ford_dt = trn.ford_dt
   WHEN NOT MATCHED THEN
      INSERT (individual_id, ford_dt)
      VALUES (trn.individual_id, trn.ford_dt);
	  
	  COMMIT ;
exec dbms_output.put_line ('BI_Individual FORD Update completed');
-- Update BI_Individual LORD 
MERGE INTO o5.BI_INDIVIDUAL HST 
using 
 (
  SELECT 
  b.INDIVIDUAL_ID            ,
  Max(trunc(b.orderdate))  MXLORD_DT        
       FROM o5.BI_SALE b
       where b.individual_id<>0 and b.individual_id is not null
	group by b.individual_id
) TRN
ON (TRN.INDIVIDUAL_ID=HST.INDIVIDUAL_ID)
when matched then 
update
set  
   HST.LORD_DT  = TRN.MXLORD_DT    
when not matched then insert 
(  
   HST.INDIVIDUAL_ID      
  ,HST.LORD_DT        
 )
values(
   TRN.INDIVIDUAL_ID      
  ,TRN.MXLORD_DT      
 );
  commit;
exec dbms_output.put_line ('BI_Individual LORD Update completed');
-- New Customer Flag
MERGE INTO o5.bi_individual hst
   USING (SELECT individual_id,
                 (CASE
                     WHEN TRUNC (ford_dt) BETWEEN fiscal_monthstartdate
                                              AND TRUNC (SYSDATE - 1)
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) new_customer_month,
                 (CASE
                     WHEN TRUNC (ford_dt) BETWEEN fiscal_quartstartdate
                                              AND TRUNC (SYSDATE - 1)
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) new_customer_quarter,
                 (CASE
                     WHEN TRUNC (ford_dt) BETWEEN fiscal_seasonstartdate
                                              AND TRUNC (SYSDATE - 1)
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) new_customer_season,
                 (CASE
                     WHEN TRUNC (ford_dt) BETWEEN fiscal_yearstartdate
                                              AND TRUNC (SYSDATE - 1)
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) new_customer_year
            FROM o5.bi_individual i, 
	   o5.bi_datekey d
           WHERE i.individual_id <> 0
             AND datekey = TRUNC (SYSDATE - 1)
             AND ford_dt IS NOT NULL
             AND lord_dt IS NOT NULL) trn
   ON (hst.individual_id = trn.individual_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.new_customer_month = trn.new_customer_month,
             hst.new_customer_quarter = trn.new_customer_quarter,
             hst.new_customer_season = trn.new_customer_season,
             hst.new_customer_year = trn.new_customer_year
   WHEN NOT MATCHED THEN
      INSERT (new_customer_month, new_customer_quarter, new_customer_season,
              new_customer_year)
      VALUES (trn.new_customer_month, trn.new_customer_quarter,
              trn.new_customer_season, trn.new_customer_year);
COMMIT ;
exec dbms_output.put_line ('BI_Individual New Customer Flag Completed'); 
-- Repeat Customer Flag
MERGE INTO o5.bi_individual hst
   USING (SELECT individual_id,
                 (CASE
                     WHEN TRUNC (lord_dt) BETWEEN fiscal_monthstartdate
                                              AND TRUNC (SYSDATE - 1)
                     AND ford_dt < fiscal_monthstartdate
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) repeat_customer_month,
                 (CASE
                     WHEN TRUNC (lord_dt) BETWEEN fiscal_quartstartdate
                                              AND TRUNC (SYSDATE - 1)
                     AND ford_dt < fiscal_quartstartdate
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) repeat_customer_quarter,
                 (CASE
                     WHEN TRUNC (lord_dt) BETWEEN fiscal_seasonstartdate
                                              AND TRUNC (SYSDATE - 1)
                     AND ford_dt < fiscal_seasonstartdate
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) repeat_customer_season,
                 (CASE
                     WHEN TRUNC (lord_dt) BETWEEN fiscal_yearstartdate
                                              AND TRUNC (SYSDATE - 1)
                     AND ford_dt < fiscal_yearstartdate
                        THEN 'Y'
                     ELSE 'N'
                  END
                 ) repeat_customer_year
            FROM o5.bi_individual i, o5.bi_datekey d
           WHERE i.individual_id <> 0 AND datekey = TRUNC (SYSDATE - 1)
           AND FORD_DT IS NOT NULL
           AND LORD_DT IS NOT NULL) trn
   ON (hst.individual_id = trn.individual_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.repeat_customer_month = trn.repeat_customer_month,
             hst.repeat_customer_quarter = trn.repeat_customer_quarter,
             hst.repeat_customer_season = trn.repeat_customer_season,
             hst.repeat_customer_year = trn.repeat_customer_year
   WHEN NOT MATCHED THEN
      INSERT (repeat_customer_month, repeat_customer_quarter,
              repeat_customer_season, repeat_customer_year)
      VALUES (trn.repeat_customer_month, trn.repeat_customer_quarter,
              trn.repeat_customer_season, trn.repeat_customer_year);
COMMIT ;
exec dbms_output.put_line ('BI_Individual Repeat Customer Flag Completed');
-- Frequency Flag


MERGE INTO o5.bi_individual hst
   USING (SELECT   individual_id,
                   ROUND (SUM (frequency_month)) frequency_month,
                   ROUND (SUM (frequency_quarter)) frequency_quarter,
                   ROUND (SUM (frequency_season)) frequency_season,
                   ROUND (SUM (frequency_year)) frequency_year
              FROM (SELECT  s.individual_id,
                             (CASE
                                 WHEN TRUNC (orderdate)
                                        BETWEEN fiscal_monthstartdate
                                            AND TRUNC (SYSDATE - 1)
                                    THEN COUNT (DISTINCT ordernum)
                                 ELSE 0
                              END
                             ) frequency_month,
                             (CASE
                                 WHEN TRUNC (orderdate)
                                        BETWEEN fiscal_quartstartdate
                                            AND TRUNC (SYSDATE - 1)
                                    THEN COUNT (DISTINCT ordernum)
                                 ELSE 0
                              END
                             ) frequency_quarter,
                             (CASE
                                 WHEN TRUNC (orderdate)
                                        BETWEEN fiscal_seasonstartdate
                                            AND TRUNC (SYSDATE - 1)
                                    THEN COUNT (DISTINCT ordernum)
                                 ELSE 0
                              END
                             ) frequency_season,
                             (CASE
                                 WHEN TRUNC (orderdate)
                                        BETWEEN fiscal_yearstartdate
                                            AND TRUNC (SYSDATE - 1)
                                    THEN COUNT (DISTINCT ordernum)
                                 ELSE 0
                              END
                             ) frequency_year
                        FROM 
			    --o5.bi_individual i,
                             --o5.bi_sale s,
			(SELECT individual_id,
      				orderdate,
      				ordernum
    				FROM o5.bi_sale
    			WHERE orderdate >=
      				(SELECT fiscal_yearstartdate
      				FROM o5.bi_datekey
      				WHERE datekey = TRUNC (SYSDATE) - 1
      				)
    			) s ,   
			o5.bi_datekey d
                       WHERE 
			 --s.individual_id = i.individual_id AND
                         d.datekey = TRUNC (SYSDATE - 1)
			and s.individual_id is not null 
			AND orderdate >= fiscal_yearstartdate
                                            GROUP BY s.individual_id,
                             orderdate,
                             fiscal_yearstartdate,
                             fiscal_seasonstartdate,
                             fiscal_quartstartdate,
                             fiscal_monthstartdate)
          GROUP BY individual_id) trn
   ON (trn.individual_id = hst.individual_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.frequency_month = trn.frequency_month,
             hst.frequency_quarter = trn.frequency_quarter,
             hst.frequency_season = trn.frequency_season,
             hst.frequency_year = trn.frequency_year
   WHEN NOT MATCHED THEN
      INSERT (frequency_month, frequency_quarter, frequency_season,
              frequency_year)
      VALUES (trn.frequency_month, trn.frequency_quarter,
              trn.frequency_season, trn.frequency_year);
COMMIT ; 
exec dbms_output.put_line ('BI_Individual Frequency Flag Completed'); 
-- BI_Individual Recency Count
MERGE INTO o5.BI_INDIVIDUAL HST
USING
(
select INDIVIDUAL_ID, ROUND(MONTHS_BETWEEN(TRUNC(SYSDATE),LORD_DT)) RECENCY
from o5.bi_INDIVIDUAL
) TRN
ON
(TRN.INDIVIDUAL_ID=HST.INDIVIDUAL_ID)
WHEN MATCHED THEN UPDATE
SET
HST.RECENCY=TRN.RECENCY
WHEN NOT MATCHED THEN INSERT
(INDIVIDUAL_ID,RECENCY) 
VALUES
(TRN.INDIVIDUAL_ID, TRN.RECENCY)
;
COMMIT;
exec dbms_output.put_line ('BI_Individual Recency Count Completed');
-- BI_Individual Monetary Aggregation
merge into o5.bi_individual hst
using
(
select individual_id,
       round(sum(monetary_month)) MONETARY_MONTH,
       round(sum(monetary_quarter)) MONETARY_QUARTER,
       round(sum(monetary_season)) MONETARY_SEASON,
       round(sum(monetary_year)) MONETARY_YEAR
FROM
(
SELECT  s.individual_id,
 (CASE
             WHEN TRUNC (orderdate) BETWEEN fiscal_monthstartdate
                                        AND TRUNC (SYSDATE - 1)
                THEN SUM(extend_price_amt)
                ELSE 0
          END
         ) monetary_month,
         (CASE
             WHEN TRUNC (orderdate) BETWEEN fiscal_quartstartdate
                                        AND TRUNC (SYSDATE - 1)
                THEN SUM(extend_price_amt)
                ELSE 0
          END
         ) monetary_quarter,
         (CASE
             WHEN TRUNC (orderdate) BETWEEN fiscal_seasonstartdate
                                        AND TRUNC (SYSDATE - 1)
                THEN SUM(extend_price_amt)
                ELSE 0
          END
         ) monetary_season,
         (CASE
             WHEN TRUNC (orderdate) BETWEEN fiscal_yearstartdate
                                        AND TRUNC (SYSDATE - 1)
                THEN SUM(extend_price_amt)
                ELSE 0
          END
         ) monetary_year
    FROM 
    --o5.bi_individual i, 
   --o5.bi_sale s, 
   (SELECT individual_id,
      orderdate,
      ordernum,
	extend_price_amt
    FROM o5.bi_sale
    WHERE orderdate >=
      (SELECT fiscal_yearstartdate
      FROM o5.bi_datekey
      WHERE datekey = TRUNC (SYSDATE) - 1
      )
    ) s ,
    o5.bi_datekey d
   WHERE 
     --s.individual_id = i.individual_id AND
     d.datekey = TRUNC (SYSDATE - 1)
     and orderdate>=fiscal_yearstartdate
     and s.individual_id is not null
GROUP BY 
	--i.individual_id,
	s.individual_id,
         orderdate,
         fiscal_yearstartdate,
         fiscal_seasonstartdate,
         fiscal_quartstartdate,
         fiscal_monthstartdate
)
group by individual_id
) trn
on
(trn.individual_id = hst.individual_id)
when matched then update
set
hst.monetary_month = trn.monetary_month,
hst.monetary_quarter = trn.monetary_quarter,
hst.monetary_season = trn.monetary_season,
hst.monetary_year = trn.monetary_year
when not matched then insert
(
 monetary_month,
 monetary_quarter,
 monetary_season,
 monetary_year
 )
values
(
 trn.monetary_month,
 trn.monetary_quarter,
 trn.monetary_season,
 trn.monetary_year
 )
;
commit; 
exec dbms_output.put_line ('BI_Individual Monetary Aggregation Completed');

--BI_Individual Call Center Customer Flag
MERGE INTO o5.BI_INDIVIDUAL HST
   USING ( 
SELECT  distinct INDIVIDUAL_ID,
   (CASE WHEN ORDERTYPE = 'T'
   THEN 'Y'
   WHEN ORDERTYPE <> 'T'
   THEN 'N'
   ELSE NULL
   END) CALL_CENTER_CUSTOMER
FROM o5.BI_SALE  
where individual_id <> 0
and ordertype = 'T'
)TRN
ON (HST.INDIVIDUAL_ID = TRN.INDIVIDUAL_ID)
   WHEN MATCHED THEN UPDATE
      SET HST.CALL_CENTER_CUSTOMER=TRN.CALL_CENTER_CUSTOMER
   WHEN NOT MATCHED THEN
      INSERT (INDIVIDUAL_ID, CALL_CENTER_CUSTOMER)
      VALUES (TRN.INDIVIDUAL_ID, TRN.CALL_CENTER_CUSTOMER);
COMMIT ;
exec dbms_output.put_line ('BI_Individual Call Center Customer Flag Completed');
-- BI_Individual Web Customer Flag
MERGE INTO o5.BI_INDIVIDUAL HST
   USING ( 
SELECT  distinct INDIVIDUAL_ID,
   (CASE WHEN ORDERTYPE = 'W'
   THEN 'Y'
   WHEN ORDERTYPE <> 'W'
   THEN 'N'
   ELSE NULL
   END) WEB_CUSTOMER
FROM o5.BI_SALE  
where individual_id <> 0
and ordertype = 'W'
)TRN
ON (HST.INDIVIDUAL_ID = TRN.INDIVIDUAL_ID)
   WHEN MATCHED THEN UPDATE
      SET HST.WEB_CUSTOMER=TRN.WEB_CUSTOMER
   WHEN NOT MATCHED THEN
      INSERT (INDIVIDUAL_ID, WEB_CUSTOMER)
      VALUES (TRN.INDIVIDUAL_ID, TRN.WEB_CUSTOMER);
COMMIT ;
exec dbms_output.put_line ('BI_Individual Web Customer Flag Completed');
-- BI_Individual Store Associate Commission Flag
MERGE INTO o5.BI_INDIVIDUAL HST
   USING ( 
SELECT  distinct INDIVIDUAL_ID,
   (CASE WHEN ORDERTYPE = 'STR'
   THEN 'Y'
   WHEN ORDERTYPE <> 'STR'
   THEN 'N'
   ELSE NULL
   END) STORE_ASSOCIATE_CUSTOMER
FROM o5.BI_SALE  
where individual_id <> 0
and ordertype = 'STR'
)TRN
ON (HST.INDIVIDUAL_ID = TRN.INDIVIDUAL_ID)
   WHEN MATCHED THEN UPDATE
      SET HST.STORE_ASSOCIATE_CUSTOMER=TRN.STORE_ASSOCIATE_CUSTOMER
   WHEN NOT MATCHED THEN
      INSERT (INDIVIDUAL_ID, STORE_ASSOCIATE_CUSTOMER)
      VALUES (TRN.INDIVIDUAL_ID, TRN.STORE_ASSOCIATE_CUSTOMER);
COMMIT ;
exec dbms_output.put_line ('BI_Individual Store Associate Commission Flag Completed'); 
exec dbms_output.put_line ('BI_Individual Product Category Started');
--Update Product Category
TRUNCATE TABLE o5.bi_individual_product;
COMMIT ;
MERGE INTO o5.bi_individual_product hst
   USING (
   SELECT INDIVIDUAL_ID,
SUM(MENS_ADVANCED_SPORTSWEAR) MENS_ADVANCED_SPORTSWEAR,
SUM(MENS_CONTEMPORARY) MENS_CONTEMPORARY,
SUM(MENS_CLOTHING) MENS_CLOTHING,
SUM(MENS_SHOES) MENS_SHOES,
SUM(MENS_SPORTSWEAR) MENS_SPORTSWEAR,
SUM(MENS_ACCESSORIES) MENS_ACCESSORIES,
SUM(BRIDGE) BRIDGE,
SUM(CONTEMPORARY) CONTEMPORARY,
SUM(COSMETICS) COSMETICS,
SUM(DESIGNER) DESIGNER,
SUM(EVENING) EVENING,
SUM(FRAGRANCE) FRAGRANCE,
SUM(GIFTS_AND_HOME) GIFTS_AND_HOME,
SUM(HANDBAG) HANDBAG,
SUM(JEWELRY) JEWELRY,
SUM(KIDS) KIDS,
SUM(OUTERWEAR) OUTERWEAR,
SUM(SALON_Z) SALON_Z,
SUM(SHOE) SHOE,
SUM(SOFT_ACCESSORIES) SOFT_ACCESSORIES,
SUM(SWIM) SWIM
FROM
(   
   SELECT   
   individual_id, 
   sum((CASE
       WHEN GROUP_ID = 62
      THEN qtyordered
       ELSE 0
    END
   )) mens_advanced_sportswear,
   sum((CASE
       WHEN GROUP_ID = 33
      THEN qtyordered
       ELSE 0
    END
   )) mens_clothing,
   sum((CASE
       WHEN GROUP_ID = 66
      THEN qtyordered
       ELSE 0
    END
   )) mens_contemporary,
   sum((CASE
       WHEN GROUP_ID = 34
      THEN qtyordered
       ELSE 0
    END
   )) mens_furnishings,
   sum((CASE
       WHEN GROUP_ID = 63
      THEN qtyordered
       ELSE 0
    END
   )) mens_shoes,
   sum((CASE
       WHEN GROUP_ID = 31
      THEN qtyordered
       ELSE 0
    END
   )) mens_sportswear,
   sum((CASE
       WHEN GROUP_ID = 30
      THEN qtyordered
       ELSE 0
    END
   )) mens_accessories,
   sum((CASE
       WHEN GROUP_ID IN (15, 21)
      THEN qtyordered
       ELSE 0
    END
   )) bridge,
   sum((CASE
       WHEN GROUP_ID = 25
      THEN qtyordered
       ELSE 0
    END
   )) contemporary,
   sum((CASE
       WHEN GROUP_ID = 29
      THEN qtyordered
       ELSE 0
    END
   )) cosmetics,
   sum((CASE
       WHEN GROUP_ID IN (9, 10, 16, 20, 22, 23, 24)
      THEN qtyordered
       ELSE 0
    END
   )) designer,
   sum((CASE
       WHEN GROUP_ID = 14
      THEN qtyordered
       ELSE 0
    END)) evening,
   sum((CASE
       WHEN GROUP_ID = 28
      THEN qtyordered
       ELSE 0
    END
   )) fragrance,
   sum((CASE
       WHEN division_id = 7
      THEN qtyordered
       ELSE 0
    END
   )) gifts_and_home,
   sum((CASE
       WHEN GROUP_ID = 39
      THEN qtyordered
       ELSE 0
    END)) handbag,
   sum((CASE
       WHEN GROUP_ID IN (13, 18)
      THEN qtyordered
       ELSE 0
    END
   )) jewelry,
   sum((CASE
       WHEN GROUP_ID = 35
      THEN qtyordered
       ELSE 0
    END)) kids,
   sum((CASE
       WHEN department_id IN
      (57,
       438,
       155,
       174,
       182,
       437,
       495,
       688,
       104,
       499,
       750
      )
      THEN qtyordered
       ELSE 0
    END
   )) outerwear,
   sum((CASE
       WHEN GROUP_ID = 8
      THEN qtyordered
       ELSE 0
    END)) salon_z,
   sum((CASE
       WHEN GROUP_ID = 36
       THEN qtyordered   
       ELSE 0
    END)) shoe,
   sum((CASE
       WHEN GROUP_ID = 19
       THEN qtyordered 
       ELSE 0
    END
   )) soft_accessories,
   sum((CASE
       WHEN department_id IN (42, 742, 319, 342)
       THEN qtyordered 
       ELSE 0
    END)
   ) swim
  FROM o5.bi_sale
     WHERE individual_id <> 0
   AND (   department_id IN
      (57,
       438,
       155,
       174,
       182,
       437,
       495,
       688,
       104,
       499,
       750,
       42,
       742,
       319,
       342
      )
    OR GROUP_ID IN
      (62,
       33,
       66,
       34,
       63,
       31,
       30,
       15,
       21,
       25,
       29,
       9,
       10,
       16,
       20,
       22,
       23,
       24,
       14,
       28,
       39,
       13,
       18,
       35,
       8,
       36,
       19
      )
    OR division_id = 7
   )
  GROUP BY individual_id , group_id, department_id, division_id)
  GROUP BY INDIVIDUAL_ID
   ) trn
   ON (hst.individual_id = trn.individual_id)
   WHEN MATCHED THEN
  UPDATE
 SET hst.mens_advanced_sportswear = trn.mens_advanced_sportswear,
     hst.mens_contemporary = trn.mens_contemporary,
     hst.mens_clothing = trn.mens_clothing,
     hst.mens_shoes = trn.mens_shoes,
     hst.mens_sportswear = trn.mens_sportswear,
     hst.mens_accessories = trn.mens_accessories,
     hst.bridge = trn.bridge, 
     hst.contemporary = trn.contemporary,
     hst.cosmetics = trn.cosmetics, 
     hst.designer = trn.designer,
     hst.evening = trn.evening, 
     hst.fragrance = trn.fragrance,
     hst.gifts_and_home = trn.gifts_and_home,
     hst.handbag = trn.handbag, 
     hst.jewelry = trn.jewelry,
     hst.kids = trn.kids, 
     hst.outerwear = trn.outerwear,
     hst.salon_z = trn.salon_z, 
     hst.shoe = trn.shoe,
     hst.soft_accessories = trn.soft_accessories, 
     hst.swim = trn.swim,
     hst.maint_dt = SYSDATE
   WHEN NOT MATCHED THEN
  INSERT (individual_id, mens_advanced_sportswear, mens_contemporary,
  mens_clothing, mens_shoes, mens_sportswear, mens_accessories,
  bridge, contemporary, cosmetics, designer, evening, 
  fragrance, gifts_and_home, handbag, jewelry, kids, 
  outerwear, salon_z, shoe, soft_accessories, 
  swim, maint_dt)
  VALUES (trn.individual_id, trn.mens_advanced_sportswear,
  trn.mens_contemporary, trn.mens_clothing, trn.mens_shoes,
  trn.mens_sportswear, trn.mens_accessories, trn.bridge,
  trn.contemporary, trn.cosmetics, trn.designer, trn.evening,
  trn.fragrance, trn.gifts_and_home, trn.handbag, trn.jewelry,
  trn.kids, trn.outerwear, trn.salon_z, trn.shoe,
  trn.soft_accessories, trn.swim, SYSDATE);
COMMIT ;
-- BI_Individual Product Category Update Complete
exec dbms_output.put_line ('BI_Individual Product Category Completed');
-- BI_Individual Attribute Update Compete
exec dbms_output.put_line ('BI_Individual Attribute Update Completed');

commit;
exit
