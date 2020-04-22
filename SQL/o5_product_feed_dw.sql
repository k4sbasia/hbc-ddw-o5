REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_product_feed_dw.sql
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
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

EXEC DBMS_OUTPUT.PUT_LINE ('o5_product_feed_bm.sql started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

TRUNCATE TABLE O5.O5_WEB_ASSORTMENTS;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_WEB_ASSORTMENTS started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT INTO O5.O5_WEB_ASSORTMENTS
SELECT
	b.product_id AS PRD_ID
    ,a.folder_id AS SBA_ID
   ,b.folder_path  AS SBA_PATH
   ,b.product_id AS PRODUCT_CODE
FROM
    pim_exp_bm.pim_ab_o5_web_folder_data@PIM_READ a,
    o5.SFCC_ACTV_PIM_ASSORTMENT_O5 b
WHERE
    a.folder_path = b.folder_path
;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_WEB_ASSORTMENTS completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

TRUNCATE TABLE o5.O5_SR_PRODUCTS_BM;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_PRODUCTS_BM started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT INTO o5.O5_SR_PRODUCTS_BM
SELECT distinct SKU.PRODUCT_CODE PRD_ID,
  pa.Product_id PRODUCT_CODE,
  S.skn_no SKN,
  LPAD(sku.upc,13,'0') sku_CODE,
  pa.Colorization_Ind COLOR_IND,
  pa.purchase_restriction AS PURCH_RES,
   ASRT.SBA_PATH,
  NVL(S.in_stock_sellable_qty, 0)  AS WH_SELLABLE_QTY
FROM o5.all_active_product_sku_o5 SKU
JOIN o5.inventory S ON s.SKN_NO =sku.skn_no
JOIN o5.all_active_pim_prd_attr_o5 pa ON pa.PRODUCT_ID =sku.product_code
JOIN O5.O5_WEB_ASSORTMENTS_BKUP ASRT ON (ASRT.PRoduct_code        = SKU.PRODUCT_CODE);
commit ;
;
COMMIT;
EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_PRODUCTS_BM completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
TRUNCATE TABLE O5.BI_PRODUCT_INFO;
COMMIT;
EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.BI_PRODUCT_INFO started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
INSERT INTO O5.BI_PRODUCT_INFO
WITH BASE AS
  (SELECT BPW.STYL_SEQ_NUM AS PRODUCT_CODE,
    BPW.BRAND_NAME         AS BRAND_MANUFACTURER,
    BPW.PRODUCTCOPY        AS PRODUCT_DESCRIPTION,
    TRIM(BPW.GROUP_NAME)   AS DEPARTMENT ,
    BM.SBA_PATH            AS CATEGORY_MAPPING,
    BPW.SKU,
    BPW.UPC,
    BPW.BM_DESC AS PRODUCT_NAME,
    1           AS SHOPRUNNER_ELIGIBLE,
    BPW.PRODUCT_URL
    ||'?'
    ||'site_refer=' AS PRODUCT_URL,
    -- NULL                                     AS PRODUCT_IMAGE_URL_MAIN,
    O5.F_GET_ALT_IMAGE_URL(BPW.STYL_SEQ_NUM) AS PRODUCT_IMAGE_URL_ADDL,
    BPW.SKU_LIST_PRICE                       AS REGULAR_PRICE,
    CASE
      WHEN (BPW.SKU_SALE_PRICE != BPW.SKU_LIST_PRICE)
      THEN BPW.SKU_SALE_PRICE
    END SALE_PRICE,
    BM.WH_SELLABLE_QTY AS QUANTITY, -- to be updated from inventory
    CASE
      WHEN(BPW.SKU_COLOR='.')
      THEN ''
      ELSE BPW.SKU_COLOR
    END PRODUCT_COLOR ,
    TRIM(
    CASE
      WHEN(BPW.SKU_SIZE1_DESC='.')
      THEN ''
      ELSE BPW.SKU_SIZE1_DESC
    END)
    || TRIM(
    CASE
      WHEN(BPW.SKU_SIZE2_DESC='.')
      THEN ''
      ELSE BPW.SKU_SIZE2_DESC
    END) PROD_SIZE,
    BM.COLOR_IND,
	BPW.COUNTRY_RESTRICTION,
	BM.PURCH_RES
  FROM O5.O5_PARTNERS_EXTRACT_WRK BPW
  JOIN O5.O5_SR_PRODUCTS_BM BM
  ON (BPW.STYL_SEQ_NUM = BM.PRODUCT_CODE
  AND BPW.UPC          = BM.UPC_CODE )
  )
SELECT PRODUCT_CODE,
  SKU,
  UPC,
  BRAND_MANUFACTURER,
  PRODUCT_DESCRIPTION,
  DEPARTMENT ,
  CATEGORY_MAPPING,
  PRODUCT_NAME,
  SHOPRUNNER_ELIGIBLE,
  PRODUCT_URL,
  CASE
    WHEN COLOR_IND         = '1'
    AND PRODUCT_COLOR NOT IN ('No Color','NO COLOR')
    THEN (
      CASE
        WHEN LENGTH(NVL(O5.F_CHECK_MANIFEST_COLOR(TRIM( (PRODUCT_CODE)), TRIM( (PRODUCT_COLOR))), '')) > 0
        THEN 'https://image.s5a.com/is/image/saksoff5th/'
          || TRIM(( (PRODUCT_CODE)))
          ||'_'
          || UPPER(REPLACE(TRIM( (PRODUCT_COLOR)),' '))
          ||'_300x400.jpg'
        ELSE 'https://image.s5a.com/is/image/saksoff5th/'
          || TRIM(( (PRODUCT_CODE)))
          ||'_'
          ||'300x400.jpg'
      END )
    ELSE 'https://image.s5a.com/is/image/saksoff5th/'
      ||TRIM( (PRODUCT_CODE))
      ||'_300x400.jpg'
  END PRODUCT_IMAGE_URL_MAIN,
  PRODUCT_IMAGE_URL_ADDL,
  REGULAR_PRICE,
  SALE_PRICE,
  QUANTITY,
  PRODUCT_COLOR ,
  PROD_SIZE,
  COUNTRY_RESTRICTION,
  PURCH_RES
FROM BASE;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.BI_PRODUCT_INFO completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXEC DBMS_OUTPUT.PUT_LINE ('Genetration of file started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

DECLARE
XML_ITEM   CLOB;
BEGIN
SELECT '<?xml version="1.0" encoding="UTF-8"?>' ||
XMLELEMENT( "feed",
                XMLAGG(
                    XMLELEMENT ("product",
                          XMLFOREST ( PRODUCT_CODE AS "parent_sku",
                                      CATEGORY_MAPPING AS "category_mapping",
                                      BRAND_MANUFACTURER AS "brand_manufacturer",
                                      PRODUCT_DESCRIPTION AS "product_description",
                                      DEPARTMENT AS "department"
                                    ),
                          XMLAGG(
                                  XMLELEMENT ("product_variant",
                                          XMLFOREST ( SKU AS "sku",
                                                      PRODUCT_NAME AS "product_name",
                                                      SHOPRUNNER_ELIGIBLE AS "shoprunner_eligible",
                                                      PRODUCT_URL AS "product_url",
                                                      PRODUCT_IMAGE_URL_MAIN AS "product_image_url_main",
                                                      PRODUCT_IMAGE_URL_ADDL AS "Product_Image_URL_Additional",
                                                      REGULAR_PRICE AS "regular_price",
                                                      SALE_PRICE AS "sale_price",
                                                      QUANTITY AS "quantity",
                                                      PRODUCT_COLOR AS "product_color",
                                                      PROD_SIZE AS "size",
                                                      UPC AS "upc"
                                                    )
                                              )
                                 )
                                )
                      )
                ).EXTRACT ('/*').GETCLOBVAL() INTO XML_ITEM
FROM O5.BI_PRODUCT_INFO
WHERE SHOPRUNNER_ELIGIBLE = 1
GROUP BY PRODUCT_CODE,
BRAND_MANUFACTURER,
DEPARTMENT,
PRODUCT_DESCRIPTION,
CATEGORY_MAPPING;

DBMS_XSLPROCESSOR.CLOB2FILE(XML_ITEM, 'DATASERVICE', 'o5_shoprunner_product_feed.xml', NLS_CHARSET_ID('AL32UTF8'));

EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE ('Error in file generation '|| SQLCODE || '-' || SQLERRM);
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('Genetration of file completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

SHOW ERRORS;

EXEC DBMS_OUTPUT.PUT_LINE ('o5_product_feed_dw.sql completed at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXIT;
