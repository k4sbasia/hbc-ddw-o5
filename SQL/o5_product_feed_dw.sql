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

TRUNCATE TABLE O5.O5_SR_PRODUCTS;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.O5_SR_PRODUCTS started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT INTO O5.O5_SR_PRODUCTS
SELECT  DISTINCT bm.PRODUCT_CODE
FROM o5.BI_PRODUCT prd
JOIN o5.BI_PRODUCT_INFO bm
ON (bm.PRODUCT_CODE = prd.item
AND BM.UPC     = PRD.UPC)
WHERE REGEXP_LIKE (prd.ITEM_DESCRIPTION, 'virtual', 'i') -- VIRTUAL PRODUCTS
OR prd.Dropship_ind ='T' -- DROP SHIP ELIGIBLE
OR bm.PURCH_RES     = '2' -- CSR ONLY ITEMS
OR REGEXP_LIKE (prd.SKU_DESCRIPTION, ' egc', 'i') -- ELECTRONIC GIFT CARDS
OR REGEXP_LIKE (prd.SKU_DESCRIPTION, ' vegc', 'i') -- VIRTUAL GIFT CARDS
OR BM.COUNTRY_RESTRICTION NOT IN ('ALL','ALLX') /* INTERNATIONAL SHIPPING ELIGIBLE PRODUCTS */;

COMMIT;
EXEC DBMS_OUTPUT.PUT_LINE ('Update O5.BI_PRODUCT_INFO with shoprunner elligible completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

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
