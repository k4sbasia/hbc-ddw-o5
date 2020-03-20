WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET echo OFF
SET feedback OFF
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF
SET trimspool ON
SET serverout ON
SET verify OFF
TRUNCATE TABLE &1.FEED_RR_PRICE_RANGE;
INSERT
INTO FEED_RR_PRICE_RANGE
  (
    PRODUCT_ID,
    RECOMMENDABLE,
    SALES_FLAG,
    WAS_PRICE_RANGE,
    NOW_PRICE_RANGE
  )
  (SELECT TMP1.ITEM_ID,
      NVL(TMP2.RECOMMENDABLE,'false') RECOMMENDABLE2,
      NVL(TMP2.SALE_FLAG,'0') SALES_FLAG,
      CASE
        WHEN NVL(TMP2.RECOMMENDABLE,'false')= 'true'
        THEN TMP2.WAS_PRICE
        ELSE TMP1.WAS_PRICE
      END WAS_PRICE_RANGE,
      CASE
        WHEN NVL(TMP2.RECOMMENDABLE,'false')= 'true'
        THEN TMP2.NOW_PRICE
        ELSE TMP1.NOW_PRICE
      END now_price_range
    FROM
      (SELECT PRICE.ITEM_ID,
        CASE
          WHEN PRICE.MAX_CURRENT_PRICE<PRICE.MIN_ORIGINAL_PRICE
          THEN '1'
          ELSE '0'
        END SALE_FLAG,
        CASE
          WHEN (PRICE.MIN_ORIGINAL_PRICE = PRICE.MAX_ORIGINAL_PRICE)
          THEN TRIM(TO_CHAR(PRICE.MAX_ORIGINAL_PRICE, '$9,999,999.00'))
          WHEN (PRICE.MIN_ORIGINAL_PRICE <> PRICE.MAX_ORIGINAL_PRICE)
          THEN TRIM(TO_CHAR(PRICE.MIN_ORIGINAL_PRICE, '$9,999,999.00'))
            ||' - '
            ||TRIM(TO_CHAR(PRICE.MAX_ORIGINAL_PRICE, '$9,999,999.00'))
        END WAS_PRICE ,
        CASE
          WHEN (PRICE.MIN_CURRENT_PRICE = PRICE.MAX_CURRENT_PRICE)
          THEN TRIM(TO_CHAR(PRICE.MAX_CURRENT_PRICE, '$9,999,999.00'))
          WHEN (PRICE.MIN_CURRENT_PRICE <> PRICE.MAX_CURRENT_PRICE)
          THEN TRIM(TO_CHAR(PRICE.MIN_CURRENT_PRICE, '$9,999,999.00'))
            ||' - '
            ||TRIM(TO_CHAR(PRICE.MAX_CURRENT_PRICE, '$9,999,999.00'))
        END NOW_PRICE
      FROM
        (SELECT item_id ITEM_ID,
          MIN(Price_type_cd) PRICE_TYPE,
          MIN(to_number(MSRP)) MIN_ORIGINAL_PRICE,
          MAX(to_number(MSRP)) MAX_ORIGINAL_PRICE,
          MIN(to_number(OFFER_PRICE) ) MIN_CURRENT_PRICE,
          MAX(to_number(OFFER_PRICE) ) MAX_CURRENT_PRICE
        FROM &1.v_sd_price_&2 o, &1.all_active_product_sku_&2 s
        where o.skn_no = s.skn_no
        and
          OFFER_PRICE > 1
        -- and item_id = '0400090078279'
        GROUP BY item_id
        ) PRICE
      ) TMP1,
      (SELECT ITEM_ID,
            CASE
              WHEN (T1.IN_STOCK ) > 0
              THEN 'true'
              ELSE 'false'
            END
          RECOMMENDABLE,
        CASE
          WHEN T1.MAX_CURRENT_PRICE<T1.MIN_ORIGINAL_PRICE
          THEN '1'
          ELSE '0'
        END SALE_FLAG,
        CASE
          WHEN (T1.MIN_ORIGINAL_PRICE = T1.MAX_ORIGINAL_PRICE)
          THEN TRIM(TO_CHAR(T1.MAX_ORIGINAL_PRICE, '$9,999,999.00'))
          WHEN (T1.MIN_ORIGINAL_PRICE <> T1.MAX_ORIGINAL_PRICE)
          THEN TRIM(TO_CHAR(T1.MIN_ORIGINAL_PRICE, '$9,999,999.00'))
            ||' - '
            ||TRIM(TO_CHAR(T1.MAX_ORIGINAL_PRICE, '$9,999,999.00'))
        END WAS_PRICE,
        CASE
          WHEN (T1.MIN_CURRENT_PRICE = T1.MAX_CURRENT_PRICE)
          THEN TRIM(TO_CHAR(T1.MAX_CURRENT_PRICE, '$9,999,999.00'))
          WHEN (T1.MIN_CURRENT_PRICE <> T1.MAX_CURRENT_PRICE)
          THEN TRIM(TO_CHAR(T1.MIN_CURRENT_PRICE, '$9,999,999.00'))
            ||' - '
            ||TRIM(TO_CHAR(T1.MAX_CURRENT_PRICE, '$9,999,999.00'))
        END NOW_PRICE
      FROM
        (SELECT SUM(IN_STOCK) IN_STOCK ,
          SUM(INSTOCK_STORE) IN_STOCK_STORE,
          MIN(CURRENT_PRICE) MIN_CURRENT_PRICE,
          MAX(CURRENT_PRICE) MAX_CURRENT_PRICE,
          MIN(ORIGINAL_PRICE) MIN_ORIGINAL_PRICE,
          MAX(ORIGINAL_PRICE) MAX_ORIGINAL_PRICE,
          MIN(PRICE_TYPE) price_type,
          ITEM_ID
        FROM
          (SELECT
            WI.in_stock_sellable_qty IN_STOCK,
            NVL(WI.in_store_qty,0) INSTOCK_STORE,
            Price_type_cd PRICE_TYPE,
            MSRP ORIGINAL_PRICE,
            OFFER_PRICE CURRENT_PRICE,
            SO.item_id ITEM_ID,
            WI.SKN_NO SKU_ID,
            s.upc
          FROM &1.v_sd_price_&2 SO, &1.all_active_product_sku_&2 s,&1.inventory WI
        where SO.skn_no = s.skn_no
             and s.skn_no = wi.skn_no
          )
        WHERE (IN_STOCK  > 0
        OR INSTOCK_STORE > 0)
        GROUP BY ITEM_ID
        ) T1
      ) TMP2
    WHERE TMP1.ITEM_ID = TMP2.ITEM_ID(+)
  );
COMMIT;

TRUNCATE TABLE &1.FEED_RR_PRODUCT_DAILY;

TRUNCATE TABLE &1.RR_BM_PRODUCT;

COMMIT;


INSERT INTO RR_BM_PRODUCT
SELECT '' PRD_ID,
  P.PRODUCT_ID PRD_CODE_LOWER,
  CASE
    WHEN PRD_READYFORPROD = 'Yes'
    THEN
      CASE
        WHEN P.is_reviewable= 'T'
        THEN 'T'
        ELSE 'F'
      END
    ELSE '0'
  END AS OBA_BOO_VAL,
  IS_SHOPTHELOOK AS SHOPLOOK
FROM all_active_pim_prd_attr_&2 P
WHERE P.PRD_STATUS ='Yes';

COMMIT;

INSERT INTO FEED_RR_PRODUCT_DAILY
WITH BASE AS
  (SELECT
    DISTINCT PRD.STYL_SEQ_NUM,
    PRD.BM_DESC,
    PRD.GROUP_ID,
    PRD.DEPARTMENT_ID,
    'T' AS TOGGLE_FLAG,
    TO_CHAR (PRD.SKU_SALE_PRICE)   AS SKU_SALE_PRICE,
    TO_CHAR (PRD.SKU_LIST_PRICE)   AS SKU_LIST_PRICE,
    TO_CHAR (PRD.ITEM_CST_AMT)     AS ITEM_CST_AMT,
    PR.RECOMMENDABLE,
    REPLACE(BRAND_NAME, '|', ' ') AS BRAND_NAME,
    PRD.MORECOLORS,
    PRD.PREORDER,
    PR.WAS_PRICE_RANGE,
    PR.NOW_PRICE_RANGE,
    PR.SALES_FLAG,
	prd.product_url,is_egc,
    image_url
  FROM &1_PARTNERS_EXTRACT_WRK PRD,
    FEED_RR_PRICE_RANGE PR
  WHERE PRD.STYL_SEQ_NUM = PR.PRODUCT_ID
 AND nvl(PRD.is_egc,'F')        <> 'T'
AND NVL(PRD.GWP_FLAG,'F')      <> 'T'
 AND nvl(PRD.off_price_ind,'N')  <> 'Y'
 AND PRD.BM_DESC       IS NOT NULL
  AND UPPER(PRD.BRAND_NAME) NOT LIKE '%CHANEL%'
  )
SELECT REPLACE(REPLACE (REPLACE (P.BM_DESC, CHR (10), ' '), CHR (13), ' '), '|', ' '),
  P.GROUP_ID,
  P.DEPARTMENT_ID,
  P.product_url,
  p.image_url||'_102x136.jpg',
  TO_CHAR (P.SKU_SALE_PRICE),
  TO_CHAR (P.SKU_LIST_PRICE),
  TO_CHAR (P.ITEM_CST_AMT),
  P.STYL_SEQ_NUM,
  P.RECOMMENDABLE,
  REPLACE(P.BRAND_NAME, '|', ' '),
  P.MORECOLORS,
  P.PREORDER,
  '0',
  NULL,
  '0',
  NVL(S.OBA_BOO_VAL,'0') ,
  P.WAS_PRICE_RANGE,
  P.NOW_PRICE_RANGE,
  P.SALES_FLAG,
  S.PRD_ID,
  S.SHOPLOOK
FROM BASE P
JOIN RR_BM_PRODUCT S
ON (P.STYL_SEQ_NUM = S.PRD_CODE_LOWER);
commit;

 INSERT INTO &1.FEED_RR_PRODUCT_DAILY
 SELECT 'Standard Gift Card' BM_DESC,
  P.GROUP_ID,
  P.DEPARTMENT_ID,
'https://www.saksoff5th.com/main/ProductDetail.jsp?PRODUCT<>prd_id='|| p.prd_id,
'https://image.s5a.com/is/image/saksoff5th/'||TRIM(P.product_code) ||'_102x136.jpg' ,
  TO_CHAR (P.SKU_SALE_PRICE),
  TO_CHAR (P.SKU_LIST_PRICE),
  TO_CHAR (P.ITEM_CST_AMT),
  product_code STYL_SEQ_NUM,
  'true' RECOMMENDABLE,
  REPLACE(P.BRAND_NAME, '|', ' '),
  NULL MORECOLORS,
  NULL PREORDER,
  '0',
  NULL,
  '0',
  'F' ,
 TRIM(TO_CHAR(25, '$9,999,999.00')) || ' - ' || TRIM(TO_CHAR(500, '$9,999,999.00')) WAS_PRICE_RANGE,
  TRIM(TO_CHAR(25, '$9,999,999.00')) || ' - ' || TRIM(TO_CHAR(500, '$9,999,999.00')) NOW_PRICE_RANGE,
  0 SALES_FLAG,
  p.prd_id,
  0
FROM &1.Bi_product P
 where p.product_code = '0499535450471'
 and SKU_SALE_PRICE = 500;

commit;

declare
  begin
for r1 in
(
select
  (rating / 100) rating
  ,
 (
 CASE
 WHEN r.rating IS NOT NULL
THEN r.rating
  || '.gif'
ELSE NULL
END) rating_image_url,
R.TOTALREVIEWCOUNT num_reviews,
 product_id
  from &1.TURN_TO_PRODUCT_REVIEW R ) loop

  update &1.FEED_RR_PRODUCT_DAILY set rating = r1.rating,rating_image_url = r1.rating_image_url,num_reviews= r1.num_reviews where  product_id = r1.product_id;
  commit;
  end loop;
  end;


TRUNCATE TABLE &1.FEED_RR_PRODUCT_DELTA;

COMMIT;

INSERT INTO &1.FEED_RR_PRODUCT_DELTA
  (
    PRODUCT_ID,
    SALES_FLAG,
    RECOMMENDABLE,
    WAS_PRICE_RANGE,
    NOW_PRICE_RANGE
  )
SELECT DISTINCT PRODUCT_ID,
  SALES_FLAG,
  RECOMMENDABLE,
  WAS_PRICE_RANGE,
  NOW_PRICE_RANGE
FROM &1.FEED_RR_PRODUCT_DAILY ;

COMMIT;

SELECT 'name'
  ||'|'
  || 'attribute.Group'
  ||'|'
  || 'attribute.Department'
  ||'|'
  || 'link_url'
  ||'|'
  || 'image_url'
  ||'|'
  || 'sale_price'
  ||'|'
  || 'price'
  ||'|'
  || 'attribute.cost'
  ||'|'
  || 'product_id'
  ||'|'
  || 'recommendable'
  ||'|'
  || 'brand'
  ||'|'
  || 'attribute.morecolors'
  ||'|'
  || 'attribute.preorder'
  ||'|'
  || 'rating'
  ||'|'
  || 'attribute.rating_image_url'
  ||'|'
  || 'num_reviews'
  ||'|'
  || 'attribute.display_review'
  || '|'
  || 'attribute.now_price_range'
  || '|'
  || 'attribute.was_price_range'
  || '|'
  || 'attribute.sale_flag'
  || '|'
  || 'attribute.alt_image_flag'
  || '|'
  || 'attribute.alt_image_1'
  || '|'
  || 'attribute.alt_image_2'
  || '|'
  || 'attribute.mobile_url'
  ||'|'
  || 'attribute.mobile_url_alt'
FROM DUAL ;
SELECT DISTINCT R.ITEM_BM_DESC
  ||'|'
  || R.GROUP_ID
  ||'|'
  || R.DEPARTMENT
  ||'|'
  || R.LINK_URL
  ||'|'
  ||
  CASE
    WHEN R.SHOPLOOK = '1'
    THEN
      CASE
        WHEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'ASTL') IS NOT NULL
        THEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'ASTL')
        ELSE R.IMAGE_URL
      END
    ELSE R.IMAGE_URL
  END
  ||'|'
  || R.SALES_PRICE
  ||'|'
  || R.PRICE
  ||'|'
  || R.COST
  ||'|'
  || R.PRODUCT_ID
  ||'|'
  || R.RECOMMENDABLE
  ||'|'
  || R.BRAND
  ||'|'
  || R.MORECOLORS
  ||'|'
  || R.PREORDER
  ||'|'
  || R.RATING
  ||'|'
  || R.RATING_IMAGE_URL
  ||'|'
  || R.NUM_REVIEWS
  ||'|'
  || R.DISPLAY_REVIEW
  ||'|'
  || R.NOW_PRICE_RANGE
  ||'|'
  || R.WAS_PRICE_RANGE
  ||'|'
  || R.SALES_FLAG
  ||'|'
  ||
  CASE
    WHEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'A1') IS NOT NULL
    THEN 'Y'
    ELSE 'N'
  END
  ||'|'
  ||
  CASE
    WHEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'') IS NOT NULL
    THEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'')
    ELSE NULL
  END
  ||'|'
  ||
  CASE
    WHEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'A1') IS NOT NULL
    THEN &1.F_GET_RR_ALT_IMAGE(PRODUCT_ID,'A1')
    ELSE NULL
  END
  ||'|'
  || DECODE('&1','mrep.','https://m.saks.com/pd.jsp?productCode=','o5.','https://m.saksoff5th.com/pd.jsp?productCode=')
  ||R.PRODUCT_ID
  ||'|'
  || DECODE('&1','mrep.','https://image.s5a.com/is/image/saks/','o5.','https://image.s5a.com/is/image/saksoff5th/')
  ||R.PRODUCT_ID
FROM &1.FEED_RR_PRODUCT_DAILY R;

EXIT
