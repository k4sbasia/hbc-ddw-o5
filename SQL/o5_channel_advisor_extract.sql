WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF

TRUNCATE TABLE &1.STYLE_SEQ_NUMS;

INSERT INTO &1.STYLE_SEQ_NUMS
SELECT DISTINCT STYL_SEQ_NUM FROM &1.O5_PARTNERS_EXTRACT_WRK WRK;

COMMIT;

TRUNCATE TABLE &1.CHANNEL_ADVISOR_CORE_DATA;

INSERT INTO &1.CHANNEL_ADVISOR_CORE_DATA
SELECT W.UPC,
  W.STYL_SEQ_NUM STYL_SEQ_NUM,
  W.BM_DESC BM_DESC,
  W.GROUP_NAME GROUP_NAME,
  W.DEPARTMENT_NAME DEPARTMENT_NAME,
  W.SKU_PARENT_ID SKU_PARENT_ID,
  W.PRODUCTCOPY PRODUCTCOPY,
  W.SKU_SALE_PRICE SKU_SALE_PRICE,
  W.SKU_LIST_PRICE SKU_LIST_PRICE,
  W.COMPARE_PRICE COMPARE_PRICE,
  W.STYL_SEQ_NUM ITEM,
  W.BRAND_NAME BRAND_NAME,
  W.GROUP_ID GROUP_ID,
  W.CLASS_ID CLASS_ID,
  PATH PATH,
  W.SKU_SIZE1_DESC SKU_SIZE1_DESC,
  W.SKU_COLOR SKU_COLOR,
  W.WH_SELLABLE_QTY WH_SELLABLE_QTY,
  TO_CHAR (W.ITEM_CST_AMT) ITEM_CST_AMT,
  W.PREORDER PREORDER,
  W.SKU_PARENT_ID BM_CODE,
  W.IMAGE_URL IMAGE_URL,
  W.PRODUCT_URL,
  W.DEPARTMENT_ID,
  W.CLEARANCE_TYPE,
  P.ITM_GENDER ITM_GENDER,
  CASE
    WHEN ( UPPER(TRIM(W.COUNTRY_RESTRICTION)) LIKE '%AU%'
    OR UPPER(TRIM(W.COUNTRY_RESTRICTION)) LIKE '%ALL%')
    THEN 'N'
    ELSE 'Y'
  END AS AU_PUBLISH,
  CASE
    WHEN ( Upper(trim(w.country_restriction)) LIKE '%UK%'
    OR Upper(trim(w.country_restriction)) LIKE '%ALL%')
    THEN 'N'
    ELSE 'Y'
  END AS UK_PUBLISH,
  CASE
    WHEN ( Upper(trim(w.country_restriction)) LIKE '%CH%'
    OR Upper(trim(w.country_restriction)) LIKE '%ALL%')     
    THEN 'N'
    ELSE 'Y'
  END AS CH_PUBLISH,
  CASE
    WHEN ( Upper(trim(w.country_restriction)) LIKE '%CA%'
    OR Upper(trim(w.country_restriction)) LIKE '%ALL%')
    THEN 'N'
    ELSE 'Y'
  END CA_PUBLISH,
  W.COUNTRY_RESTRICTION,
  CASE
    WHEN NVL(w.COUNTRY_RESTRICTION, 'No Restriction') IN ('No Restriction')
    THEN 'YES'
    ELSE NULL
  END AS COUNTRY_RESTRICTION_FLAG
FROM &1.O5_PARTNERS_EXTRACT_WRK W,
  &1.BI_PRODUCT P,
  &1.STYLE_SEQ_NUMS R1
WHERE W.UPC                  = P.UPC
AND W.PRODUCTCOPY           IS NOT NULL
AND W.BRAND_NAME            IS NOT NULL
AND UPPER(W.BRAND_NAME) NOT IN ('CHANEL','MONCLER','BOSE','DANCING DEER','POMELLATO')
AND W.STYL_SEQ_NUM           = R1.STYL_SEQ_NUM;

COMMIT;

TRUNCATE TABLE &1.CHANNEL_ADVISOR_EXTRACT_WRK;

INSERT INTO &1.CHANNEL_ADVISOR_EXTRACT_WRK
WITH CURRENCY_CALC AS
  (SELECT *
  FROM
    ( SELECT TARGET_CURRENCY, EXCHANGE_RATE 
      FROM &1.FX_RATES 
      WHERE TARGET_CURRENCY IN ('AUD', 'CAD', 'CHF', 'GBP')
      ORDER BY TARGET_CURRENCY
    ) PIVOT ( MAX(EXCHANGE_RATE) FOR TARGET_CURRENCY IN ('AUD' AS AUD, 'CAD' AS CAD , 'CHF' AS CHF, 'GBP' AS GBP) )
  )
SELECT A.UPC,
  A.PRODUCT_NAME,
  A.SKU_NUMBER,
  A.PRIMARY_CATEGORY,
  A.SECONDARY_CATEGORY,
  A.PRODUCT_URL,
  A.PRODUCT_IMAGE_URL,
  A.SHORT_PRODUCT_DESC,
  A.LONG_PRODUCT_DESC,
  A.DISCOUNT,
  A.DISCOUNT_TYPE,
  A.SALE_PRICE,
  A.RETAIL_PRICE,
  A.BEGIN_DATE,
  A.END_DATE,
  A.BRAND,
  A.SHIPPING,
  A.IS_DELETE_FLAG,
  A.KEYWORDS,
  A.IS_ALL_FLAG,
  A.MANUFACTURER_PART,
  A.MANUFACTURER_NAME,
  A.SHIPPING_INFORMATION,
  A.AVAILABLITY,
  A.UNIVERSAL_PRICING_CODE,
  A.CLASS_ID,
  A.IS_PRODUCT_LINK_FLAG,
  A.IS_STOREFRONT_FLAG,
  A.IS_MERCHANDISER_FLAG,
  A.CURRENCY,
  A.PATH,
  A.GROUP_ID,
  A.CATEGORYS,
  A.SIZES,
  A.COLOR,
  A.VARIATION_NAME,
  A.LARGER_IMAGES,
  A.QTY_ON_HAND,
  A.AUD_SALE_PRICE,
  A.GBP_SALE_PRICE,
  A.CHF_SALE_PRICE,
  A.AU_PUBLISH,
  A.UK_PUBLISH,
  A.CH_PUBLISH,
  A.CA_PUBLISH, 
  A.ITEM_FLAG,
  A.BM_CODE,
  A.MATERIAL,
  A.DEPARTMENT_ID,
  A.CLEARANCE_TYPE,
  A.ITM_GENDER ,
  B.ALT_IMAGE_URL,
  A.AUD,
  A.CAD,
  A.CHF,
  A.GBP
FROM
  (SELECT 'P'
    ||SUBSTR(PRD.ITEM,2,LENGTH(PRD.ITEM))                                                   AS UPC,
    REPLACE(REPLACE (REPLACE (PRD.BM_DESC, CHR (10), ' '), CHR (13), ' '),'|','{PIPE}')     AS PRODUCT_NAME,
    TRIM (TO_CHAR (PRD.UPC, '0000000000000'))                                               AS SKU_NUMBER,
    PRD.GROUP_NAME                                                                          AS PRIMARY_CATEGORY,
    REPLACE(PRD.DEPARTMENT_NAME,'|','{pipe}')                                               AS SECONDARY_CATEGORY,
    PRD.PRODUCT_URL                                                                         AS PRODUCT_URL,
    PRD.IMAGE_URL                                                                           AS PRODUCT_IMAGE_URL,
    REPLACE(REPLACE (REPLACE (PRD.PRODUCTCOPY, CHR (10), ' '), CHR (13), ' '),'|','{pipe}') AS SHORT_PRODUCT_DESC,
    NULL                                                                                    AS LONG_PRODUCT_DESC,
    NULL                                                                                    AS DISCOUNT,
    NULL                                                                                    AS DISCOUNT_TYPE,
    TO_CHAR (PRD.SKU_SALE_PRICE)                                                            AS SALE_PRICE,
    CASE
      WHEN to_number(DECODE(NVL(PRD.COMPARE_PRICE,0),0,NVL(PRD.SKU_LIST_PRICE,0), NVL(PRD.COMPARE_PRICE,0))) < PRD.SKU_SALE_PRICE
      THEN PRD.SKU_SALE_PRICE
      ELSE DECODE(NVL(PRD.COMPARE_PRICE,0),0,NVL(PRD.SKU_LIST_PRICE,0),NVL(PRD.COMPARE_PRICE,0))
    END                                                                                    AS RETAIL_PRICE,
    TRUNC(SYSDATE)                                                                         AS BEGIN_DATE,
    TRUNC(SYSDATE)                                                                         AS END_DATE,
    REPLACE(REPLACE (REPLACE (PRD.BRAND_NAME, CHR (10), ' '), CHR (13), ' '),'|','{pipe}') AS BRAND,
    NULL                                                                                   AS SHIPPING,
    'N'                                                                                    AS IS_DELETE_FLAG,
    NULL                                                                                   AS KEYWORDS,
    'Y'                                                                                    AS IS_ALL_FLAG,
    PRD.STYL_SEQ_NUM                                                                       AS MANUFACTURER_PART,
    REPLACE(REPLACE (REPLACE (PRD.BRAND_NAME, CHR (10), ' '), CHR (13), ' '),'|','{pipe}') AS MANUFACTURER_NAME,
    NULL                                                                                   AS SHIPPING_INFORMATION,
    NULL                                                                                   AS AVAILABLITY,
    PRD.UPC                                                                                AS UNIVERSAL_PRICING_CODE,
    PRD.CLASS_ID                                                                           AS CLASS_ID,
    'Y'                                                                                    AS IS_PRODUCT_LINK_FLAG,
    'Y'                                                                                    AS IS_STOREFRONT_FLAG,
    'Y'                                                                                    AS IS_MERCHANDISER_FLAG,
    NULL                                                                                   AS CURRENCY,
    PRD.PATH ,
    PRD.GROUP_ID,
    REPLACE(PRD.GROUP_NAME,'|', '{pipe}') AS CATEGORYS,
    CASE
      WHEN O5.F_O5_GET_CHILD_ATTR_DATA (PRD.STYL_SEQ_NUM,'sku_size1_desc') = '.'
      THEN NULL
      ELSE O5.F_O5_GET_CHILD_ATTR_DATA (PRD.STYL_SEQ_NUM,'sku_size1_desc')
    END                                                        AS SIZES,
    O5.F_O5_GET_CHILD_ATTR_DATA (PRD.STYL_SEQ_NUM,'sku_color') AS COLOR,
    'P'                                                        AS VARIATION_NAME ,
    NULL                                                       AS LARGER_IMAGES,
    CASE
      WHEN PRD.PREORDER = 'T'
      THEN 3000
      ELSE
        (SELECT SUM(WRK.WH_SELLABLE_QTY)
        FROM O5.O5_PARTNERS_EXTRACT_WRK WRK
        WHERE STYL_SEQ_NUM = PRD.STYL_SEQ_NUM
        )
    END  AS QTY_ON_HAND ,
    NULL AS AUD_SALE_PRICE,
    NULL AS GBP_SALE_PRICE,
    NULL AS CHF_SALE_PRICE,
    PRD.AU_PUBLISH,
    PRD.UK_PUBLISH,
    PRD.CH_PUBLISH,
    PRD.CA_PUBLISH,
    CASE
      WHEN PRD.PREORDER = 'T'
      THEN 'P'
      ELSE NULL
    END         AS ITEM_FLAG,
    PRD.BM_CODE AS BM_CODE,
    NULL        AS MATERIAL,
    PRD.DEPARTMENT_ID,
    PRD.CLEARANCE_TYPE,
    PRD.ITM_GENDER,
    ROUND(PRD.SKU_SALE_PRICE * C.AUD, 2)                                        AS AUD,
    ROUND(PRD.SKU_SALE_PRICE * C.CAD, 2)                                        AS CAD,
    ROUND(PRD.SKU_SALE_PRICE * C.CHF, 2)                                        AS CHF,
    ROUND(PRD.SKU_SALE_PRICE * C.GBP, 2)                                        AS GBP,
    ROW_NUMBER() OVER (PARTITION BY PRD.STYL_SEQ_NUM ORDER BY PRD.STYL_SEQ_NUM) AS R
  FROM &1.CHANNEL_ADVISOR_CORE_DATA PRD,
    CURRENCY_CALC C
  ) A
LEFT OUTER JOIN
  (SELECT STYL_SEQ_NUM,
    LISTAGG( 'https://image.s5a.com/is/image/saksoff5th/'
    || ASSET_ID
    || '_300x400.jpg', ',') WITHIN GROUP (
  ORDER BY ASSET_ID) AS ALT_IMAGE_URL
  FROM
    ( SELECT DISTINCT Q.STYL_SEQ_NUM,
      M.ASSET_ID
    FROM &1.MEDIA_MANIFEST M,
      &1.STYLE_SEQ_NUMS Q
    WHERE M.ASSET_ID IN (Q.STYL_SEQ_NUM
      ||'_A1', Q.STYL_SEQ_NUM
      ||'_A2', Q.STYL_SEQ_NUM
      ||'_ASTL')
    AND UPPER(M.ASSETTYPE) = 'IMAGE'
    )
  GROUP BY STYL_SEQ_NUM
  ) B
ON (A.MANUFACTURER_PART = B.STYL_SEQ_NUM)
WHERE A.R               = 1
UNION ALL
SELECT TO_CHAR(TO_NUMBER (PRD.UPC)),
  REPLACE(REPLACE (REPLACE (PRD.BM_DESC, CHR (10), ' '), CHR (13), ' '),'|','{pipe}'),
  TRIM (TO_CHAR (PRD.UPC, '0000000000000')) ,
  PRD.GROUP_NAME ,
  REPLACE(PRD.DEPARTMENT_NAME,'|','{pipe}') ,
  PRD.PRODUCT_URL,
  PRD.IMAGE_URL,
  REPLACE(REPLACE (REPLACE (PRODUCTCOPY, CHR (10), ' '), CHR (13), ' '),'|','{pipe}'),
  NULL ,
  NULL ,
  NULL ,
  TO_CHAR (PRD.SKU_SALE_PRICE) ,
  CASE
    WHEN to_number(DECODE(NVL(PRD.COMPARE_PRICE,0),0,NVL(PRD.SKU_LIST_PRICE,0), NVL(PRD.COMPARE_PRICE,0))) < to_number(PRD.SKU_SALE_PRICE)
    THEN PRD.SKU_SALE_PRICE
    ELSE DECODE(NVL(PRD.COMPARE_PRICE,0),0,NVL(PRD.SKU_LIST_PRICE,0),NVL(PRD.COMPARE_PRICE,0))
  END ,
  TRUNC(SYSDATE) ,
  TRUNC(SYSDATE) ,
  REPLACE(REPLACE (REPLACE (PRD.BRAND_NAME, CHR (10), ' '), CHR (13), ' '),'|','{pipe}'),
  NULL ,
  'N' ,
  NULL ,
  'Y' ,
  PRD.STYL_SEQ_NUM ,
  REPLACE(REPLACE (REPLACE (PRD.BRAND_NAME, CHR (10), ' '), CHR (13), ' '),'|','{pipe}'),
  NULL ,
  NULL ,
  PRD.UPC ,
  PRD.CLASS_ID,
  'Y' ,
  'Y' ,
  'Y' ,
  NULL ,
  PRD.PATH ,
  PRD.GROUP_ID ,
  REPLACE(PRD.GROUP_NAME,'|','{pipe}'),
  CASE
    WHEN PRD.SKU_SIZE1_DESC = '.'
    THEN NULL
    ELSE PRD.SKU_SIZE1_DESC
  END ,
  PRD.SKU_COLOR ,
  'C' ,
  NULL ,
  CASE
    WHEN PRD.PREORDER = 'T'
    THEN 3000
    ELSE PRD.WH_SELLABLE_QTY
  END WH_SELLABLE_QTY,
  NULL ,
  NULL ,
  NULL ,
  PRD.AU_PUBLISH,
  PRD.UK_PUBLISH,
  PRD.CH_PUBLISH,
  PRD.CA_PUBLISH,
  CASE
    WHEN PRD.PREORDER = 'T'
    THEN 'P'
    ELSE NULL
  END ,
  PRD.BM_CODE,
  NULL,
  PRD.DEPARTMENT_ID,
  PRD.CLEARANCE_TYPE,
  PRD.ITM_GENDER,
  NULL,
  ROUND(PRD.SKU_SALE_PRICE * C.AUD, 2) AS AUD ,
  ROUND(PRD.SKU_SALE_PRICE * C.CAD, 2) AS CAD,
  ROUND(PRD.SKU_SALE_PRICE * C.CHF, 2) AS CHF,
  ROUND(PRD.SKU_SALE_PRICE * C.GBP, 2) AS GBP
FROM &1.CHANNEL_ADVISOR_CORE_DATA PRD,
  CURRENCY_CALC C;
  
COMMIT;

TRUNCATE TABLE &1.CHANNEL_ADVISOR_EXTRACT_NEW;

INSERT INTO &1.CHANNEL_ADVISOR_EXTRACT_NEW
SELECT /*+ APPEND */  *
FROM
  (SELECT DENSE_RANK() OVER (ORDER BY MANUFACTURER_PART#) ITEM_SEQ,
    UPC,
    PRODUCT_NAME,
    SKU_NUMBER,
    PRIMARY_CATEGORY,
    SECONDARY_CATEGORY,
    PRODUCT_URL,
    PRODUCT_IMAGE_URL,
    SHORT_PRODUCT_DESC,
    LONG_PRODUCT_DESC,
    DISCOUNT,
    DISCOUNT_TYPE,
    SALE_PRICE,
    RETAIL_PRICE,
    BEGIN_DATE,
    END_DATE,
    BRAND,
    SHIPPING,
    IS_DELETE_FLAG,
    KEYWORDS,
    IS_ALL_FLAG,
    MANUFACTURER_PART#,
    MANUFACTURER_NAME,
    SHIPPING_INFORMATION,
    AVAILABLITY,
    UNIVERSAL_PRICING_CODE,
    CLASS_ID,
    IS_PRODUCT_LINK_FLAG,
    IS_STOREFRONT_FLAG,
    IS_MERCHANDISER_FLAG,
    CURRENCY,
    PATH,
    GROUP_ID,
    CATEGORYS,
    SIZES,
    COLOR,
    VARIATION_NAME,
    LARGER_IMAGES,
    QTY_ON_HAND,
    AUD_SALE_PRICE,
    GBP_SALE_PRICE,
    AU_PUBLISH,
    UK_PUBLISH,
    CH_PUBLISH,
    CA_PUBLISH,
    ITEM_FLAG,
    MATERIAL,
    BM_CODE,
    CHF_SALE_PRICE,   
    CLEARANCE_TYPE,
    DEPARTMENT_ID,
    ITM_GENDER,
    ALT_IMAGE_URL,
    AUD,
    CAD,
    CHF,
    GBP
  FROM &1.CHANNEL_ADVISOR_EXTRACT_WRK
  )
ORDER BY ITEM_SEQ ASC,
  UPC DESC;
  
COMMIT;

EXIT;

