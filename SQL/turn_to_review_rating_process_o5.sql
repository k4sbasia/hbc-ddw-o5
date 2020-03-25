REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:turn_to_review_rating_process.sql
REM  DESCRIPTION: Load the xml data into the tables
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      ----------------
REM                 Jayanthi            08/26/2015        Created
REM ######################################################################
set echo off
set feedback on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set serverout on
set timing on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
DELETE FROM &1.turn_to_product_review_stg ;
COMMIT ;
truncate table &1.turn_to_ratings_xml;
INSERT INTO &1.turn_to_ratings_xml
     VALUES (XMLTYPE (BFILENAME ('DATASERVICE', 'turnto-skuaveragerating.xml_o5'),
                      NLS_CHARSET_ID ('WE8ISO8859P1')
                     ));

COMMIT ;
--insert into staging from the xml extract load
INSERT INTO &1.turn_to_product_review_stg
            (product_id,totalreviewcount,avg_rating)
   SELECT  prd_id,review_count,avg_rating
     FROM (select EXTRACTVALUE (VALUE (ag_id), '/product/@sku') prd_id,EXTRACTVALUE (VALUE (ag_id), '/product/@review_count') review_count,
   value(ag_id).extract('/product/text()').getStringVal() avg_rating
 from &1.turn_to_ratings_xml STG,
TABLE (XMLSEQUENCE (EXTRACT (object_value, '/sku_avg_rating/products/product'))) ag_id);

COMMIT;

--Upate the ratings column
UPDATE &1.turn_to_product_review_stg
   SET rating = (ROUND (avg_rating / 0.5) * 0.5) * 100;

commit;
---- Insert any new product_id from staging to the main table
INSERT INTO &1.turn_to_product_review (PRODUCT_ID,
                               TOTALREVIEWCOUNT,
                               RATING,
                               DATE_MODIFIED,AVG_RATING)
   SELECT PRODUCT_ID,
          TOTALREVIEWCOUNT,
          RATING,
          SYSDATE,AVG_RATING
     FROM &1.turn_to_product_review_stg stg
    WHERE NOT EXISTS
             (SELECT 'A'
                FROM &1.turn_to_product_review p
               WHERE stg.product_id = p.product_id);

COMMIT;

MERGE INTO &1.turn_to_product_review tg
     USING (SELECT a.*
              FROM &1.turn_to_product_review_stg a, &1.turn_to_product_review b
             WHERE a.product_id = b.product_id
                   AND (A.TOTALREVIEWCOUNT != B.TOTALREVIEWCOUNT
                        OR A.RATING != B.RATING)) src
        ON (tg.product_id = src.product_id)
WHEN MATCHED
THEN
   UPDATE SET
      TG.RATING = src.rating,
      TG.TOTALREVIEWCOUNT = src.totalreviewcount,
      TG.DATE_MODIFIED = SYSDATE,
      TG.AVG_RATING = src.avg_rating;
commit;

Delete from &1.turn_to_product_review p1
      where  product_id not in (select product_id from &1.turn_to_product_review_stg p2 where p1.product_id = p2.product_id )
      and rownum < 50;
commit;

show errors
exit;
