REM ##############################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  ddw_product_load.sql
REM  DESCRIPTION:  This script populates the partner base table for O5 products
REM
REM
REM  CODE HISTORY: Name                           Date                Description
REM                -----------------          ----------      --------------------------
REM                Unknown                       Jun-3-2018                      Created
REM   Added SEO product URL Jayanthi
REM ###############################################################################
SET ECHO OFF
SET TIMING ON
SET LINESIZE 10000
SET PAGESIZE 0
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION ENABLE PARALLEL DML;

--#################
DECLARE
    v_atr_readyforprod NUMBER(38,0);
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE &1.all_active_product_&2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE &1.all_active_pim_prd_attr_&2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE &1.all_active_pim_sku_attr_&2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE &1.all_actv_pim_assortment_&2';



    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' Products Identified from BM : '||' '||NVL((SQL%ROWCOUNT),0)||' rows affected.');

/*
        Get Data from PIM to BAY_DS-- Populate bi_partners_extract_wrk
*/

    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '|| TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS') || ' START PIM Data Move from PIM to Local Schema');
    INSERT INTO &1.all_active_pim_prd_attr_&2
            SELECT * FROM pim_exp_bm.all_active_pim_prd_attr_&2@&3;
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS')||' Product Attribute Rows '|| NVL((SQL%rowcount),0)|| ' copied');
    COMMIT;

    --DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' Start extracting PIM SKU data ');
    INSERT INTO &1.all_active_pim_sku_attr_&2
            SELECT * FROM pim_exp_bm.all_active_pim_sku_attr_&2@&3;
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS')||' SKU Attribute Rows '|| NVL((SQL%rowcount),0)|| ' copied');
    COMMIT;

    INSERT INTO &1.all_actv_pim_assortment_&2
            SELECT * FROM pim_exp_bm.all_actv_pim_assortment_&2@&3;
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS')||' Product Assortment Rows '|| NVL((SQL%rowcount),0)|| ' copied');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '|| TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS') || ' END PIM Data Move from PIM to Local Schema');


    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' Start fetching active products ');

    --Fetch all active poroducts from BlueMartini
    INSERT INTO &1.all_active_product_&2
    SELECT
        null,
        prd.product_id
    FROM &1.V_ACTIVE_PRODUCT_&2  prd;
    COMMIT;

EXCEPTION
WHEN OTHERS
THEN
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||to_char(sysdate,'MM-DD-YYYY HH:MI:SS')||' Main PLSQL Block Failed!!');
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||sqlerrm);
    RAISE;
END;
/
EXIT;
