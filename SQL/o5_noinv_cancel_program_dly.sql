WHENEVER SQLERROR EXIT 1
SET SERVEROUTPUT ON;
DECLARE
    v_REC_COUNT_DLY     NUMBER(10)      := 0;
    v_REC_COUNT_TEST    NUMBER(10)      := 0;
    v_SQL               VARCHAR2(500);
    c_CONTROL_GROUP     VARCHAR2(10)    := 'C';
    c_TESTING_GROUP     VARCHAR2(10)    := 'T';

    CURSOR c_noinv_customer_info
    IS
    with all_cust_info as
            (SELECT
usa_email AS email_address,
                OL.CREATEFOR AS customer_id,
                P.UPC AS SKU_ID,
                p.PRODUCT_CODE AS prd_id,
                EXTEND_PRICE_AMT as sku_price,
                P.UPC AS SKU_code_lower,
                P.PRODUCT_CODE AS prd_code_lower,
                OL.ORDERNUM AS order_number,
                PRD.BRAND_NAME AS brand_name,
                PRD.BM_DESC AS prd_short_desc,
                sl_cancel_dte AS cancel_dt
from
     o5.bi_sale@reportdb ol
    join o5.user_account@reportdb usr on ol.createfor = usr.usa_id
    join o5.bi_product@reportdb p on ol.product_id = p.upc and deactive_ind = 'N'
    join o5.all_active_pim_prd_attr_o5@reportdb prd ON p.product_code = prd.product_id
       WHERE ordline_status = 'X' and cancelreason = 'B' and trunc(canceldate) = trunc(sysdate)-1
             AND NOT EXISTS (SELECT *
                               FROM sdmrk.raw_weekly_crm_feed_o5_2 crm
                              WHERE margin_flag > .20
                                AND usr.usa_email = UPPER(crm.email_address))
        )
        SELECT
                email_address,
                customer_id,
                'OC' AS program_name,
                sku_id,
                prd_id,
                sku_code_lower,
                prd_code_lower product_code,
                order_number,
                brand_name,
                prd_short_desc,
                cancel_dt ord_cancel_date,
                NULL AS genericattribute1,
                NULL AS genericattribute2,
                NULL AS genericattribute3,
                1 AS genericnumber1,
                ROWNUM AS genericnumber2, --use it for primary sequence to assign promo codes
                sku_price AS genericnumber3,
                NULL AS genericdate1,
                NULL AS genericdate2,
                TRUNC(SYSDATE) AS genericdate3
        FROM all_cust_info
    ;

   TYPE c_noinv_data IS TABLE OF c_noinv_customer_info%ROWTYPE;
   l_data            c_noinv_data;
BEGIN

    --Move the Data to History Table before TRUNCATING daily table
    INSERT INTO sdmrk.stg_noinv_ord_cancel_his
    SELECT * FROM sdmrk.stg_noinv_ord_cancel_dly WHERE GENERICNUMBER1 = 1 and GENERICATTRIBUTE3 = 'T';
    COMMIT;

    v_sql := 'TRUNCATE TABLE sdmrk.stg_noinv_ord_cancel_dly';
    EXECUTE IMMEDIATE v_sql;

    OPEN c_noinv_customer_info;
    LOOP
          FETCH c_noinv_customer_info BULK COLLECT INTO l_data;
          FORALL idx IN 1..l_data.COUNT
          INSERT INTO sdmrk.stg_noinv_ord_cancel_dly
            VALUES l_data(idx);
          EXIT WHEN c_noinv_customer_info%NOTFOUND;
    END LOOP;
    dbms_output.put_line('No of Rows Inserted Into STG_NOINV_ORD_CANCEL_DLY : ' || c_noinv_customer_info%ROWCOUNT);
    CLOSE c_noinv_customer_info;
    COMMIT;

    --Excluding Opt-Out Customers and International Customers
    UPDATE sdmrk.stg_noinv_ord_cancel_dly dly
       SET genericnumber1 = genericnumber1+1
     WHERE EXISTS (SELECT 1
                      FROM sdmrk.o5_email_address eml
                     WHERE trim(upper(dly.email_address)) = upper(eml.email_address)
                       AND (opt_in = 0 OR international_ind = 'T'))
        OR dly.email_address IS NULL;

    dbms_output.put_line('Emails Marked Opt Out or Interantional Customer : ' || SQL%ROWCOUNT);
    COMMIT;

    --Enforce One Promo Code Per Month Specific to Each Email Address
    UPDATE sdmrk.stg_noinv_ord_cancel_dly dly
       SET genericnumber1 = genericnumber1+1
     WHERE EXISTS (SELECT 1
                      FROM sdmrk.stg_noinv_ord_cancel_his his
                     WHERE his.genericdate3 >= TO_DATE('08/08/2018 12:00:00','MM/DD/YYYY HH:MI:SS')
                       AND dly.email_address = his.email_address
                       AND his.genericattribute3 = 'T'
                       AND his.genericnumber1 = 1
                       AND his.genericdate3 >= TRUNC(sysdate-30)
--                       AND his.ord_cancel_date BETWEEN TRUNC(sysdate,'MM') AND add_months(TRUNC(sysdate,'MM'),1)-1)
                       )
        AND genericnumber1 = 1;

    --Enforce Test/Control group
    MERGE INTO sdmrk.stg_noinv_ord_cancel_dly dly
    USING
        (
        SELECT DISTINCT email_address, genericattribute3
          FROM sdmrk.stg_noinv_ord_cancel_his
         WHERE TRUNC(genericdate3) >= TO_DATE('08/08/2018 12:00:00','MM/DD/YYYY HH:MI:SS') -- temporary Fix till cleanup of History table
           AND genericnumber1 = 1
        ) grp ON (grp.email_address = dly.email_address)
    WHEN MATCHED
    THEN UPDATE SET dly.genericattribute3 = grp.genericattribute3;
    COMMIT;

    --IDENTIFY TOTAL EMAIL AND MARK THE TEST_CONTROL_GROUP
    SELECT
        MAX(total_email_cnt) , CEIL(MAX(total_email_cnt) / 2)
        INTO v_REC_COUNT_DLY,v_REC_COUNT_TEST
    FROM
        (
            SELECT DENSE_RANK() OVER(ORDER BY email_address) AS total_email_cnt
            FROM sdmrk.stg_noinv_ord_cancel_dly dly
            WHERE dly.genericnumber1 = 1
        );

    MERGE INTO sdmrk.stg_noinv_ord_cancel_dly dly
    USING
        (
        SELECT email_address,
               DENSE_RANK() OVER (ORDER BY email_address) AS drank_email,
               ROWID AS row_id,
               CASE WHEN DENSE_RANK() OVER (ORDER BY email_address) > v_REC_COUNT_TEST THEN c_TESTING_GROUP ELSE c_CONTROL_GROUP END c_test_control_grp
          FROM sdmrk.stg_noinv_ord_cancel_dly dly
         WHERE dly.genericnumber1 = 1
           AND dly.genericattribute3 is null
        ) tc ON (tc.ROWID = dly.ROWID)
    WHEN MATCHED THEN UPDATE SET dly.genericattribute3 = tc.c_test_control_grp
;

    --UPDATE GENERICATTRUBTE1 FOR EMAIL ID
    MERGE INTO sdmrk.stg_noinv_ord_cancel_dly dly
    USING (SELECT email_id, UPPER(TRIM(email_address)) AS email_add
            FROM sdmrk.o5_email_address) eml
       ON (eml.email_add = UPPER(TRIM(dly.email_address)))
     WHEN MATCHED
     THEN UPDATE SET dly.genericattribute1 = eml.email_id
    WHERE genericnumber1 = 1;

    dbms_output.put_line('Emails update with EMAIL_ID : ' || SQL%ROWCOUNT);
    COMMIT;

/*
    -- Update the promocode from bank to customer table
        MERGE INTO sdmrk.stg_noinv_ord_cancel_dly dly
        USING
        (SELECT ROWNUM AS pk_key, b.*
           FROM sdmrk.stg_o5_noinv_promocodes b
          WHERE status_check = 0
            AND applicable_month = TO_CHAR(TRUNC(SYSDATE,'MONTH'),'MMYY')
        ) promo ON (dly.genericnumber2 = promo.pk_key)
         WHEN MATCHED THEN
       UPDATE
          SET dly.genericattribute2 = promo.promocode
        WHERE dly.genericattribute2 IS NULL
          AND dly.genericnumber1 = 1            -- Only Valid Customers
          AND dly.genericattribute3= 'T';       -- Assign Promo for Testing Group
*/

--Promo Code to Only Distinct Customers
        MERGE INTO sdmrk.stg_noinv_ord_cancel_dly dly
        USING
          (SELECT ROWNUM AS pk_key, b.*
             FROM sdmrk.stg_o5_noinv_promocodes b
            WHERE status_check = 0
              AND applicable_month = to_char(TRUNC(sysdate,'MONTH'),'MMYY')) promo
               ON (dly.genericnumber2 = promo.pk_key
                       AND dly.ROWID IN (
                                WITH all_eligible_cust AS (
                                    SELECT email_address, MIN(ROWID) AS row_id
                                      FROM sdmrk.stg_noinv_ord_cancel_dly dly
                                     WHERE dly.genericattribute2 IS NULL
                                       AND dly.genericnumber1 = 1            -- Only Valid Customers
--                                       AND dly.genericattribute3 = 'T'
                                    GROUP BY email_address)
                                SELECT row_id FROM all_eligible_cust)
                                )
        WHEN MATCHED THEN
        UPDATE SET dly.genericattribute2 = promo.promocode;

    dbms_output.put_line('Promo Codes Used From Promo Bank in STG_NOINV_ORD_CANCEL_DLY : ' || SQL%ROWCOUNT);
    COMMIT;
    --INVALIDATE THE PROMOCOE ALREADY UTILZED IN THE BANK
    UPDATE sdmrk.stg_o5_noinv_promocodes pr
       SET status_check = 1
     WHERE EXISTS (SELECT 1
                     FROM sdmrk.stg_noinv_ord_cancel_dly lp
                    WHERE lp.genericattribute2 = pr.promocode
                      AND applicable_month = TO_CHAR(TRUNC(SYSDATE,'MONTH'),'MMYY'));

        dbms_output.put_line('Promo Codes Marked Unused in STAGE Table: ' || SQL%ROWCOUNT);
    COMMIT;
END;
/
EXIT;
