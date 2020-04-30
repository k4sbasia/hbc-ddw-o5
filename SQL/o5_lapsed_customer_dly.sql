WHENEVER SQLERROR EXIT 1
SET SERVEROUTPUT ON;
DECLARE
    v_process               VARCHAR2(20) := 'O5 LAPSPED CAMPAING';
    v_table_name            VARCHAR2(50) := 'O5_FINAL_LP_CUSTOMER_DATA_DLY';
    v_process_st_time       VARCHAR2(50);
    v_process_end_time      VARCHAR2(50);
    v_process_time          VARCHAR2(50);
    v_process_run_date      DATE := TRUNC(SYSDATE);
    v_his_del_date          DATE := TRUNC(SYSDATE)-10;
    v_max_order_dt          DATE := TRUNC(TRUNC(SYSDATE,'WW')-1,'WW');          --To Identify last week orders
    v_max_crm_dt            DATE := ADD_MONTHS(TRUNC(SYSDATE,'WW')+7,-6);       --Decides How far we look back to identify customers
    v_code                  VARCHAR2(100);
    v_errm                  VARCHAR2(500);
    v_sql                   VARCHAR2(500);
    v_recs_archived         NUMBER;
    v_rec_count_dly         NUMBER;
    custom_exception        EXCEPTION;

CURSOR c_lapsed_camp_data
IS
    WITH ALL_ELIGIBLE_CUSTOMERS AS
    (
    SELECT T1.*,
           TO_DATE(LAST_ORDER_DATE,'DDMONRRRR') AS FMT_DATE,
           TRUNC(SYSDATE) - TO_DATE(LAST_ORDER_DATE,'DDMONRRRR') AS F_DIFF_IN_DAYS
      FROM STG_O5_LP_WEEKLY_CRM_FEED T1
     WHERE TO_DATE(LAST_ORDER_DATE,'DDMONRRRR') <=  v_max_crm_dt
    )
    ,LAST_7_DAYS_ORDER_CHECK AS
    (
    SELECT EC.EMAIL_ADDRESS,
           EC.EMAIL_ID,
           CST.CUSTOMER_ID AS CUSTOMER_ID,
           EC.F_DIFF_IN_DAYS,
           CASE WHEN EC.f_diff_in_days = 180 THEN 'A1'
                        WHEN EC.f_diff_in_days = 187 THEN 'A2'
                        WHEN EC.f_diff_in_days = 270 THEN 'B1'
                        WHEN EC.f_diff_in_days = 277 THEN 'B2'
                        WHEN EC.f_diff_in_days = 365 THEN 'C1'
                        WHEN EC.f_diff_in_days = 372 THEN 'C2'
                        WHEN EC.f_diff_in_days = 450 THEN 'D1'
                        WHEN EC.f_diff_in_days = 457 THEN 'D2'
                        WHEN EC.f_diff_in_days = 540 THEN 'E1'
                        WHEN EC.f_diff_in_days = 547 THEN 'E2'
                        WHEN EC.f_diff_in_days = 630 THEN 'F1'
                        WHEN EC.f_diff_in_days = 637 THEN 'F2'
                        WHEN EC.f_diff_in_days = 720 THEN 'G1'
                        WHEN EC.f_diff_in_days = 727 THEN 'G2'
                 ELSE 'NA'
           END AS RECIPE,
           ROW_NUMBER() OVER (PARTITION BY CST.EMAIL_ADDRESS ORDER BY ADD_DT DESC) AS F_RANK_CUST,
           CASE WHEN ORD.CUSTOMER_ID IS NOT NULL THEN 1 ELSE 0 END AS F_CUST_ORD_FOUND
      FROM ALL_ELIGIBLE_CUSTOMERS EC
      LEFT JOIN SDMRK.O5_CUSTOMER CST ON CST.EMAIL_ADDRESS = EC.EMAIL_ADDRESS
      LEFT JOIN SDMRK.O5_ORDERS ORD ON ORD.CUSTOMER_ID = CST.CUSTOMER_ID AND ORD.ORDERDATE >= v_max_order_dt
     WHERE F_DIFF_IN_DAYS < 800
    --   AND CST.EMAIL_ADDRESS IN ('0012BOND@GMAIL.COM','007.ARTEM@GMAIL.COM')
    )
    SELECT
        EMAIL_ADDRESS,
        EMAIL_ID,
        CUSTOMER_ID,
        RECIPE,
        NULL PROMOCODE,
        NULL BARCODE,
        NULL GENERICATTRIBUTE1,
        NULL GENERICATTRIBUTE2,
        NULL GENERICATTRIBUTE3,
        NULL GENERICATTRIBUTE4,
        NULL GENERICATTRIBUTE5,
        1 GENERICNUMBER1,
        ROWNUM GENERICNUMBER2,
        NULL GENERICNUMBER3,
        NULL GENERICDATE1,
        NULL GENERICDATE2,
        NULL GENERICDATE3
           --RECIPE, COUNT(1) AS EMAIL_PER_RECIPE
      FROM LAST_7_DAYS_ORDER_CHECK t1
     WHERE F_CUST_ORD_FOUND = 0
       AND F_RANK_CUST = 1
       AND RECIPE <> 'NA'
    --GROUP BY RECIPE
    --ORDER BY 1
;

   TYPE c_lp_data IS TABLE OF c_lapsed_camp_data%rowtype;
    l_data            c_lp_data;

BEGIN
    v_process_st_time := to_char(sysdate,'MM/DD/RRRR HH24:MI:SS');
    v_sql := 'TRUNCATE TABLE SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY';
    dbms_output.put_line('Process : ' || v_process || ' Begins at ' || v_process_st_time);

    --Move the Data to History Table before TRUNCATING daily table
    INSERT INTO SDMRK.O5_FINAL_LP_CUSTOMER_DATA_HIS
    (   EMAIL_ADDRESS,
        EMAIL_ID,
        CUSTOMER_ID,
        RECIPE,
        PROMOCODE,
        BARCODE,
        GENERICATTRIBUTE1,
        GENERICATTRIBUTE2,
        GENERICATTRIBUTE3,
        GENERICATTRIBUTE4,
        GENERICATTRIBUTE5,
        GENERICNUMBER1,
        GENERICNUMBER2,
        GENERICNUMBER3,
        GENERICDATE1,
        GENERICDATE2,
        GENERICDATE3
    )
    SELECT * FROM SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY;
    v_recs_archived := SQL%ROWCOUNT;
    dbms_output.put_line('CUSTOMERS ARCHIVED TO  HISTORY - O5_FINAL_LP_CUSTOMER_DATA_HIS : ' || v_recs_archived);
    COMMIT;

    SELECT COUNT(1) INTO v_rec_count_dly FROM SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY;

    IF (v_recs_archived = v_rec_count_dly)
    THEN
        EXECUTE IMMEDIATE v_sql;
        dbms_output.put_line('Daily Table '|| v_table_name || ' Truncated.');
    ELSE
        RAISE custom_exception;
    END IF;

    OPEN c_lapsed_camp_data;
    LOOP
        FETCH c_lapsed_camp_data BULK COLLECT INTO l_data;
        FORALL idx IN 1..l_data.COUNT
            INSERT INTO SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY
            VALUES l_data (idx);
        EXIT WHEN c_lapsed_camp_data%notfound;
    END LOOP;

    dbms_output.put_line('NO OF CUSTOMERS IDENTIFIED - O5_FINAL_LP_CUSTOMER_DATA_DLY : ' || c_lapsed_camp_data%ROWCOUNT);
    v_process_time := to_char(sysdate,'MM/DD/RRRR HH24:MI:SS');
    CLOSE c_lapsed_camp_data;
    COMMIT;

    --Excluding Opt-Out Customers
    UPDATE SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY dly
       SET GENERICNUMBER1 = 0
     WHERE EXISTS (SELECT 1
                    FROM SDMRK.email_address eml
                   WHERE dly.email_address = eml.email_address
                     AND (opt_in = 0 OR international_ind = 'T'));

    dbms_output.put_line('EMAIL MARKED OPT OUT : ' || SQL%ROWCOUNT);
    COMMIT;
    --SELECT * FROM O5_PRODUCT
    --GET PREVIOUS ORDER SPECIFIC DATA FOR LAPSED CUSTOMERS
    MERGE INTO SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY FL
    USING
    (
        SELECT
            CUSTOMER_ID,
            LISTAGG(PRD.PRD_ID,'::') WITHIN GROUP (ORDER BY CUSTOMER_ID,PRD_ID) AS PRD_ID,
            LISTAGG(PRD.PRODUCT_CODE,'::') WITHIN GROUP (ORDER BY CUSTOMER_ID,PRD_ID) AS SKU_ID,
            LISTAGG(SKU_DESCRIPTION,'::') WITHIN GROUP (ORDER BY CUSTOMER_ID,PRD_ID) AS PRD_DESC,
            LISTAGG(BRAND_NAME,'::') WITHIN GROUP (ORDER BY CUSTOMER_ID,PRD_ID) AS BRAND_NAME
          FROM (SELECT RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDERDATE DESC) AS LATEST_ORDER,
                       ORD.CUSTOMER_ID,
                       ORD.SKU
                  FROM SDMRK.O5_ORDERS ORD
                 WHERE ORDER_LINE_STATUS = 'D'
    --               AND ORD.CUSTOMER_ID IN (2253998837095619, 2253998855529481)
                ) ORD
          JOIN SDMRK.O5_PRODUCT PRD ON PRD.SKU = ORD.SKU --AND PRD.PRODUCT_CODE = ORD.ITEM_NUMBER --AND PRD.SKU = ORD.SKU
          LEFT JOIN (select upc  SKU_CODE_LOWER from o5.all_active_pim_sku_attr_o5@reportdb ) SKU ON PRD.UPC = SKU_CODE_LOWER
         WHERE ORD.LATEST_ORDER = 1
         GROUP BY CUSTOMER_ID
        ) PRD
    ON (PRD.CUSTOMER_ID = FL.CUSTOMER_ID)
    WHEN MATCHED
    THEN UPDATE
            SET GENERICATTRIBUTE1 = PRD_ID,
                GENERICATTRIBUTE2 = SKU_ID,
                GENERICATTRIBUTE3 = PRD_DESC,
                GENERICATTRIBUTE4 = BRAND_NAME
    WHERE GENERICNUMBER1 = 1;
    dbms_output.put_line('NUMBER OF CUSTOMERS UPDATE PRODUCT INFO : ' || SYSDATE || ' ' || SQL%ROWCOUNT || ' SYSDATE ');
    COMMIT;

    --Check For Repeating Customer To Reuse Promocodes
        MERGE INTO SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY dly
        USING (SELECT DISTINCT email_address,
                               first_value(promocode) OVER (PARTITION BY EMAIL_ADDRESS ORDER BY upload_dt DESC) as promocode,
                               first_value(barcode) OVER (PARTITION BY EMAIL_ADDRESS ORDER BY upload_dt DESC) as barcode
                FROM SDMRK.O5_FINAL_LP_CUSTOMER_DATA_HIS) his
           ON (dly.email_address = his.email_address) -- AND his.his_recipe = substr(dly.recipe,1,1) AND his_recipe_1 = 1)
        WHEN MATCHED THEN
      UPDATE SET dly.promocode  = his.promocode,
                 dly.barcode    = his.barcode
       WHERE substr(dly.recipe,2,1) = 2 AND GENERICNUMBER1 = 1;
--
    dbms_output.put_line('PROMO CODES UPDATED FOR REMINDERS AT : ' || SYSDATE || ' ' || SQL%ROWCOUNT);
    COMMIT;

    MERGE INTO SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY dly
    USING
        (SELECT rownum as PK, B.BARCODE
           FROM SDMRK.STG_O5_LP_PROMOCODES B
          WHERE B.STATUS_CHECK = 0) PR
       ON (DLY.GENERICNUMBER2 = PR.PK)
      WHEN MATCHED THEN
    UPDATE
       SET dly.promocode    = PR.BARCODE,
           dly.barcode      = PR.BARCODE
     WHERE dly.promocode    IS NULL
       AND SUBSTR(dly.recipe,2,1) = 1
       AND GENERICNUMBER1 = 1;
--
    dbms_output.put_line('PROMO CODES USED FROM PROMO BANK : ' || SYSDATE || ' ' || SQL%ROWCOUNT);
    COMMIT;

    --INVALIDATE THE PROMOCOE ALREADY UTILZED IN THE BANK
    UPDATE SDMRK.STG_O5_LP_PROMOCODES pr
       SET status_check = 1
     WHERE EXISTS (SELECT 1
                     FROM SDMRK.O5_FINAL_LP_CUSTOMER_DATA_DLY lp
                    WHERE lp.promocode = pr.BARCODE
                      AND substr(lp.recipe,2,1) = 1);

        dbms_output.put_line('PROMO CODES MARKED UNUSED IN STAGE TABLE: ' || SYSDATE || ' ' || SQL%ROWCOUNT);
    COMMIT;

    --Delete from History if its a 10 DAYS Old Data
    DELETE
      FROM SDMRK.O5_FINAL_LP_CUSTOMER_DATA_HIS
     WHERE UPLOAD_DT <= v_his_del_date;

    dbms_output.put_line('HISTORY DELETE FOR : ' || v_his_del_date || ' : '|| SQL%ROWCOUNT);
    COMMIT;

    v_process_end_time := to_char(sysdate,'MM/DD/RRRR HH24:MI:SS');
    dbms_output.put_line('Process : ' || v_process || ' Completed at ' || v_process_end_time);
EXCEPTION
    WHEN custom_exception THEN
        v_process_end_time := to_char(SYSDATE,'MM/DD/RRRR HH24:MI:SS');
        dbms_output.put_line('Archiving Daily Data Failed');
        dbms_output.put_line('-------------------------------------------------------------------');
        dbms_output.put_line('Process ' || v_process || ' Exits : '|| v_process_end_time);
        ROLLBACK;

    WHEN OTHERS THEN
        v_code := SQLCODE;
        v_errm := substr(sqlerrm, 1 , 100);
        dbms_output.put_line('Error in process '|| v_process || '  Please Investigate.');
        dbms_output.put_line('Error Code : '||v_code);
        dbms_output.put_line('Error Message : '||v_errm);
END;
/
EXIT;
