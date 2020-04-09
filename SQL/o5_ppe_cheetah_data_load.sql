REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_cheetah_data_load.sql
REM  DESCRIPTION:  It truncates and loads BV Cheetah table with data required for
REM                XML Feed for CHEETAH MAIL
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Jayanthi                 06/02/2014              Created
REM
REM ############################################################################
--bring the product/cutsomer/sale info from three different tables

--delete data older than 7 months.
--delete data older than 7 months.
DELETE FROM O5.TURN_TO_CHEETAH_EXTRACT WHERE ADD_DT < ADD_MONTHS(SYSDATE,-7);
commit;

delete from O5.TURN_TO_CHEETAH_EXTRACT where trunc(add_dt) = trunc(sysdate);

INSERT INTO o5.TURN_TO_CHEETAH_EXTRACT(ordernum,
                                     CUSTOMER_ID,
                                     CUSTOMER_FIRST_NAME,
                                                                         CUSTOMER_LAST_NAME,
                                     EMAIL,
                                     PRODUCT_ID,
                                     INTERNATIONAL,
                                     SHRT_PROD_DESC,
                                     BRAND,
                                     DATE_SHIPPED,
                                     IMAGE_URL,
                                                                         ORDER_DATE,
                                                                         ZIPCODE,
                                                                         ORDERSEQ
                                                                         )
select
max(a.ordernum) as ordernum,
            max(bc.customer_id),
            bc.firstname,
                        bc.lastname,
            bc.internetaddress AS USERID,
            a.product_code AS PRODUCTID,
            a.INTERNATIONAL_IND,
            MAX (a.item_description) AS SHRT_PROD_DESC,
            a.brand_name AS BRAND,
            TRUNC (a.shipdate) AS Date_shipped,
            max(a.PROD_IMG_URL),
                        max(trunc(a.orderdate)),
                        max(bc.zipcode),
      max(a.orderseq)
      from
(
select bs.createfor,e.product_code,bs.ordernum,INTERNATIONAL_IND,e.bm_desc item_description,e.brand_name,bs.shipdate,
                'https://image.s5a.com/is/image/saks/'
                || TRIM (e.product_code)
                || '_180x240.jpg'
          PROD_IMG_URL,bs.orderdate,
                        bs.orderseq
 FROM o5.bi_sale bs, o5.TURNTO_CATALOG_FULL_EXTRACT e
      WHERE
      ( (bs.shipdate = TRUNC (SYSDATE) - 9 AND international_ind = 'F')
             OR (bs.shipdate = TRUNC (SYSDATE) - 14 AND international_ind = 'T') )
        and bs.bm_skuid = e.bm_skuid ) a,
        o5.bi_customer bc
        where a.createfor = bc.customer_id
        and bc.internetaddress NOT LIKE 'E4X%'
           AND NOT EXISTS
                       (SELECT 'A'
                          FROM o5.TURN_TO_CHEETAH_EXTRACT ch
                         WHERE     a.ordernum = CH.ORDERNUM
                               AND a.product_code = ch.product_id
                               AND bc.customer_id = ch.customer_id)
           AND EXISTS
                                                (SELECT 1
                          FROM o5.email_address e
                         WHERE  bc.internetaddress = e.email_address and e.opt_in=1)
group by
            bc.firstname ,
            bc.lastname,
            bc.internetaddress,
            a.product_code,
             a.INTERNATIONAL_IND,
             a.brand_name,
             TRUNC (a.shipdate);
commit;

MERGE INTO
        o5.TURN_TO_CHEETAH_EXTRACT TRG
USING
        (
SELECT
        email,
        MAX(BC.CUSTOMER_ID) CUST_ID
FROM
        o5.TURN_TO_CHEETAH_EXTRACT bc
WHERE
        TRUNC(ADD_DT)=TRUNC(SYSDATE)
GROUP BY
        email) SRC ON
        (
                TRG.email=SRC.email
        )
        WHEN MATCHED THEN
UPDATE
SET
        TRG.CUSTOMER_ID=SRC.CUST_ID ;

commit;

MERGE INTO o5.TURN_TO_CHEETAH_EXTRACT tg
   USING (SELECT   c.ordernum,upper(b.oba_str_val) oba_str_val
              FROM martini_main.ATTRIBUTE@o5prod_mrep a,
                   martini_store.object_attribute@o5prod_mrep b,
                   o5.bi_sale c
             WHERE a.atr_nm IN ('MarketingBillToEmail')
               AND a.VERSION = 1
               AND a.atr_status_cd <> 'D'
               AND a.atr_id = b.oba_atr_id
               AND b.oba_obj_id = c.orderhdr
               AND c.orderhdr IN (
                      SELECT TO_CHAR (orderhdr) AS orderhdr
                        FROM O5.bi_sale
                       WHERE ordernum IN (
                                SELECT ordernum
                                  FROM o5.TURN_TO_CHEETAH_EXTRACT
                                 WHERE  NVL(international_ind,'F')='T'
                                   AND add_dt = TRUNC (SYSDATE)))
          GROUP BY c.ordernum, b.oba_str_val) src
   ON (tg.ordernum = src.ordernum)
   WHEN MATCHED THEN
      UPDATE
         SET tg.email = src.oba_str_val;
commit;

MERGE INTO o5.BV_CHEETAH_EXTRACT tg
     USING (
            SELECT p.prd_code_lower product_code
              FROM martini_main.product@o5prod_mrep p
             WHERE   p.version=1
             AND prd_status_cd<>'A'
            UNION
            SELECT p.prd_code_lower product_code
              FROM martini_main.object_attribute@o5prod_mrep oa,
                   martini_main.product@o5prod_mrep p
             WHERE   p.version=1 and oa.version=1 and  oa.oba_obj_id = p.prd_id
                   AND oba_boo_val = 'T'
                   AND oa.oba_atr_id IN (SELECT a.atr_id
                                           FROM martini_main.
                                                 attribute@o5prod_mrep a
                                          WHERE a.atr_nm_lower = 'isegc')
            UNION
            SELECT p.prd_code_lower product_code
              FROM martini_main.object_attribute@o5prod_mrep oa,
                   martini_main.product@o5prod_mrep p
             WHERE   p.version=1 and oa.version=1 and  oa.oba_obj_id = p.prd_id
                   AND oba_boo_val = 'T'
                   AND oa.oba_atr_id IN (SELECT a.atr_id
                                           FROM martini_main.
                                                 attribute@o5prod_mrep a
                                          WHERE a.atr_nm_lower = 'gwp_flag')) src
        ON (tg.product_id = src.product_code and add_dt=trunc(sysdate))
WHEN MATCHED
THEN
   UPDATE SET tg.item_exclude = 'T';
commit;


--Assign a request_id to each customer
--This is a new number starting with 0 every day.
--If a customer has more than one item in the table, same request_id will be
--assinged to all the records of the customer on the same add_dt.
--When assigning id, exlude the ITEM_EXLUDE items.
MERGE INTO o5.TURN_TO_CHEETAH_EXTRACT tg
     USING (SELECT email, ROWNUM - 1 AS request_id
              FROM (SELECT DISTINCT email
                      FROM o5.TURN_TO_CHEETAH_EXTRACT
                     WHERE trunc(add_dt) = TRUNC (SYSDATE) AND item_exclude = 'F' and email is not null and product_id is not null
                                         and email NOT LIKE 'E4X%')) src
        ON (    tg.email = src.email
            AND tg.add_dt = TRUNC (SYSDATE)
            AND tg.item_exclude = 'F' and tg.email is not null
                        AND tg.product_id is not null
                        AND tg.email NOT LIKE 'E4X%')
WHEN MATCHED
THEN
   UPDATE SET tg.request_id = src.request_id;
   commit;
--get the long description
MERGE INTO o5.TURN_TO_CHEETAH_EXTRACT tg
     USING (SELECT p.prd_code_lower, oa.oba_str_val long_desc
              FROM martini_main.object_attribute@o5prod_mrep oa,
                   martini_main.product@o5prod_mrep p
             -- o5.TURN_TO_CHEETAH_EXTRACT bc
             WHERE oa.oba_obj_id = p.prd_id
                   --and bc.product_id=p.prd_id
                   --AND rownum < 10
                   and p.prd_status_cd <> 'D'
                   AND oa.oba_atr_id IN
                          (SELECT a.atr_id
                             FROM martini_main.
                                   attribute@o5prod_mrep a
                            WHERE a.atr_nm_lower = 'productcopy')) src
         ON (tg.product_id = src.prd_code_lower and tg.add_dt = TRUNC (SYSDATE) AND tg.item_exclude = 'F')
WHEN MATCHED
THEN
   UPDATE SET tg.productcopy = src.long_desc;
commit;
--Update the short_description for any change happened at the attribute level
MERGE INTO o5.TURN_TO_CHEETAH_EXTRACT tg
     USING (SELECT p.prd_code_lower, oa.oba_str_val as short_description
  FROM martini_main.object_attribute@o5prod_mrep oa,
       martini_main.product@o5prod_mrep p
 WHERE oa.oba_obj_id = p.prd_id
        and p.prd_status_cd <> 'D'
        AND oa.oba_atr_id IN
              (SELECT a.atr_id
                 FROM martini_main.attribute@o5prod_mrep a
                WHERE a.atr_nm_lower = 'productshortdescription')) src
         ON (tg.product_id = src.prd_code_lower and tg.add_dt = TRUNC (SYSDATE) AND tg.item_exclude = 'F')
WHEN MATCHED
THEN
   UPDATE SET tg.SHRT_PROD_DESC = src.short_description;
commit;

merge into o5.TURN_TO_CHEETAH_EXTRACT TG
     USING (SELECT p.prd_code_lower, p.prd_id bm_prd_id
              from MARTINI_MAIN.PRODUCT@o5prod_mrep P
             WHERE version=1 and p.prd_status_cd='A' ) src
         ON (tg.product_id = src.prd_code_lower and tg.add_dt = TRUNC (SYSDATE))
WHEN MATCHED
THEN
   update set TG.bm_prd_id = SRC.bm_prd_id;
commit;

--Update turntoord field with Jason formate as per turnto document

DECLARE
BEGIN
  FOR r1 IN
  (SELECT request_id,
    customer_id,
    product_id,
        ordernum,
    o5.f_get_turnto_ord_code(request_id,customer_id,product_id,ordernum) str_val
  FROM o5.TURN_TO_CHEETAH_EXTRACT
  WHERE ordernum          IS NOT NULL
  AND order_Date          IS NOT NULL
  AND customer_first_Name IS NOT NULL
  AND customer_last_Name  IS NOT NULL
  AND email               IS NOT NULL
  AND shrt_prod_desc      IS NOT NULL
  AND image_url           IS NOT NULL
  AND product_id          IS NOT NULL
  and request_id is not null
  and TRUNC(ADD_DT)=TRUNC(SYSDATE)
  )
  LOOP
UPDATE o5.TURN_TO_CHEETAH_EXTRACT t
    SET turntoord      = r1.str_val
    WHERE t.request_id = r1.request_id
    AND t.customer_id  = r1.customer_id
    AND t.product_id   = r1.product_id
        and t.ordernum = r1.ordernum;
    COMMIT;
  END LOOP;
END;
/

exec dbms_stats.gather_table_stats(ownname=>'o5',tabname=>'TURN_TO_CHEETAH_EXTRACT',estimate_percent=>10,degree=>2,cascade=>TRUE);
show errors;
exit;
