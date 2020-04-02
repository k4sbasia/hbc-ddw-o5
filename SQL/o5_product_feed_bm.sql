REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_product_feed_bm.sql
REM  DESCRIPTION:  This script loads required data for shoprunner product feed 
REM						from BLUE MARTINI
REM
REM
REM
REM  CODE HISTORY: Name                     Date            Description
REM                -----------------        ----------      ---------------
REM                Kallaar         			06/05/2017   	CREATED
REM
REM#############################################################################
SET ECHO ON
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET TIMING ON
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE 

EXEC DBMS_OUTPUT.PUT_LINE ('o5_product_feed_bm.sql started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

TRUNCATE TABLE O5.O5_WEB_ASSORTMENTS;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_WEB_ASSORTMENTS started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT INTO O5.O5_WEB_ASSORTMENTS
SELECT
	c.product_code AS PRD_ID
    ,a.folder_id AS SBA_ID
   ,SUBSTR(REPLACE(a.folder_path,'/','>'),2)  AS SBA_PATH
   ,c.product_id AS PRODUCT_CODE
FROM
    pim_exp_bm.pim_ab_o5_web_folder_data@PIM_READ a,
    (
        SELECT
            *
        FROM
            (
                SELECT
                    folder_path,
                    MAX(
                        CASE
                            WHEN attribute_name = 'FolderActive' THEN
                                attribute_val
                        END
                    ) AS folderactive,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdStartTime' THEN
                                attribute_val
                        END
                    ) AS readyforprodstarttime,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdEndTime' THEN
                                attribute_val
                        END
                      ) AS readyforprodendtime,
                      MAX(
                        CASE
                            WHEN attribute_name = 'readyforprodfolder' THEN
                                attribute_val
                        END
                      ) AS readyforprodfolder  
                FROM
                    pim_exp_bm.pim_ab_o5_folder_attr_data@PIM_READ
                WHERE
                    folder_path IS NOT NULL
                GROUP BY
                    folder_path
            )
        WHERE
            folderactive = 'Yes'
            AND ( nvl(to_date(readyforprodstarttime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) <= trunc(sysdate)
                  AND nvl(to_date(readyforprodendtime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) >= trunc(sysdate) )
            AND ( ( folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
      OR (folder_path LIKE '/Assortments/SaksMain/Custom%'))
             )
    ) b,
    (SELECT pa.PRODUCT_ID PRODUCT_ID,ps.PRODUCT_CODE,pa.FOLDER_PATH FROM o5.all_actv_pim_assortment_o5 pa
    	LEFT JOIN o5.all_active_product_sku_o5 ps ON ps.upc=pa.PRODUCT_ID )c
WHERE
    a.folder_path = b.folder_path
    AND a.folder_path = c.folder_path
     -- and a.folder_path = '/Assortments/SaksMain/ShopCategory/Women/Apparel/Coats'
    AND status_cd = 'A'
	 AND c.product_code IS NOT null;
  
COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_WEB_ASSORTMENTS completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

--TRUNCATE TABLE O5.O5_SR_ASSORTMENTS;

--COMMIT;

--EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_ASSORTMENTS started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

--INSERT INTO O5.O5_SR_ASSORTMENTS
--SELECT ps.PRODUCT_CODE PRD_ID,
--  PRD.Product_id PRODUCT_CODE,
--  prd.Colorization_Ind COLOR_IND,
 -- ASRT.SBA_PATH
--FROM o5.all_active_pim_prd_attr_o5 prd
--JOIN o5.all_active_product_sku_o5 ps ON ps.upc=prd.PRODUCT_ID 
--JOIN o5.all_active_pim_prd_attr_o5 ATR ON  ATR.Product_id = prd.Product_id
--JOIN O5.O5_WEB_ASSORTMENTS ASRT ON (ASRT.PRD_ID        = ps.PRODUCT_CODE)
--WHERE ATR.PRD_READYFORPROD = 'Yes'
--AND PRD.PRD_STATUS  = 'Yes' ;

--COMMIT;

--EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_ASSORTMENTS completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

TRUNCATE TABLE o5.O5_SR_PRODUCTS_BM;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_PRODUCTS_BM started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT INTO o5.O5_SR_PRODUCTS_BM
SELECT SKU.PRODUCT_CODE PRD_ID,
  pa.Product_id PRODUCT_CODE,
  S.skn_no SKN,
  LPAD(sku.upc,13,'0') sku_CODE,
  pa.Colorization_Ind COLOR_IND,
  pa.purchase_restriction AS PURCH_RES,
   ASRT.SBA_PATH,
  NVL(S.in_stock_sellable_qty, 0)  AS WH_SELLABLE_QTY
FROM o5.all_active_product_sku_o5 SKU
JOIN o5.inventory S ON s.SKN_NO =sku.PRODUCT_CODE 
JOIN o5.all_active_pim_prd_attr_o5 pa ON pa.PRODUCT_ID =sku.upc
JOIN O5.O5_WEB_ASSORTMENTS ASRT ON (ASRT.PRD_ID        = SKU.PRODUCT_CODE)
WHERE
NVL(S.in_stock_sellable_qty, 0) > 0 
;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_PRODUCTS_BM completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

SHOW ERRORS;

EXEC DBMS_OUTPUT.PUT_LINE ('o5_product_feed_bm.sql started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXIT;
