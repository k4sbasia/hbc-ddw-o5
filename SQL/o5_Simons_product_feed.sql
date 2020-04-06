WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET TRIMSPOOL ON
SET ARRAYSIZE 5000
SET TERMOUT OFF;

--Update inventory from product for upc where varionace_name = 'C'
declare
begin
for r1 in
(
  with inv as
   (
  select  to_char(skn_no) upc,
          in_stock_sellable_qty   wh_sellable_qty
    from &2.inventory),
   feed as
   ( select c.upc ,c.qty_on_hand 
        from &2.CHANNEL_ADVISOR_EXTRACT_NEW c 
        where c.variation_name = 'C'
   )
   select p.wh_sellable_qty ,p.upc from
   inv p, feed f
   where f.upc = p.upc
   and  p.wh_sellable_qty <> f.qty_on_hand  )

   loop
    update &2.CHANNEL_ADVISOR_EXTRACT_NEW set
    qty_on_hand = r1.wh_sellable_qty where upc = r1.upc;
    commit;
end loop;
end;
/

--Update parent varaibtion_name = 'P' sale_price,retail_price and qty for the onhand item only
declare
begin
for r1 in

   (
   with qty_old as
   (
   select sum(qty_on_hand) qty_on_hand,manufacturer_part# from 
   &2.CHANNEL_ADVISOR_EXTRACT_NEW c
   where  variation_name = 'C' and qty_on_hand > 0
   group by manufacturer_part# ),
   feed as
   ( select c.manufacturer_part# ,c.qty_on_hand from
   &2.CHANNEL_ADVISOR_EXTRACT_NEW c where c.variation_name = 'P'
   )
   select p.qty_on_hand ,p.manufacturer_part# from
   qty_old  p, feed f
   where f.manufacturer_part# = p.manufacturer_part#
   and  p.qty_on_hand <> f.qty_on_hand
   )

loop
    update &2.CHANNEL_ADVISOR_EXTRACT_NEW set 
    qty_on_hand = r1.qty_on_hand where manufacturer_part# = r1.manufacturer_part# and variation_name= 'P';
    commit;
end loop;
end;
/

SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET TRIMSPOOL ON
SET ARRAYSIZE 5000
SET TERMOUT OFF;

SPOOL &1;

WITH final_sale AS
  (SELECT c.UPC
  FROM
    (SELECT upc_code,
      product_code
    FROM &2.prd_hier_price_status s,
      &2.bi_product p
    WHERE price_type = 'F'
    AND s.sku_code   = p.sku
    ) f,
    (SELECT REPLACE(upc,'P','0') upc
    FROM &2.CHANNEL_ADVISOR_EXTRACT_NEW
    WHERE clearance_type = 'C'
    AND VARIATION_NAME   = 'C'
    ) c
  WHERE c.upc = f.upc_code
  UNION
  SELECT c.upc
  FROM
    (SELECT DISTINCT product_code
    FROM &2.prd_hier_price_status s,
      &2.bi_product p
    WHERE price_type = 'F'
    AND s.sku_code   = p.sku
    ) f,
    (SELECT REPLACE(upc,'P','0') parent_value,
      upc
    FROM &2.CHANNEL_ADVISOR_EXTRACT_NEW
    WHERE clearance_type = 'C'
    AND VARIATION_NAME   = 'P'
    ) c
  WHERE c.parent_value = f.PRODUCT_CODE
  )
SELECT MANUFACTURER_PART#
  || '|'
  || N.UPC
  || '|'
  || PRODUCT_NAME
  || '|'
  || VARIATION_NAME
  || '|'
  || SKU_NUMBER
  || '|'
  || PRIMARY_CATEGORY
  || '|'
  || SECONDARY_CATEGORY
  || '|'
  || PRODUCT_URL
  || '|'
  || replace(replace(PRODUCT_IMAGE_URL,'https://image.s5a.com','https://s7d2.scene7.com'),'_300x400.jpg','?$960x1280$')
  || '|'
  || SHORT_PRODUCT_DESC
  || '|'
  || LONG_PRODUCT_DESC
  || '|'
  || DISCOUNT
  || '|'
  || DISCOUNT_TYPE
  || '|'
  || SALE_PRICE
  || '|'
  || RETAIL_PRICE
  || '|'
  || BEGIN_DATE
  || '|'
  || END_DATE
  || '|'
  || BRAND
  || '|'
  || SHIPPING
  || '|'
  || IS_DELETE_FLAG
  || '|'
  || KEYWORDS
  || '|'
  || IS_ALL_FLAG
  || '|'
  || MANUFACTURER_NAME
  || '|'
  || SHIPPING_INFORMATION
  || '|'
  || AVAILABLITY
  || '|'
  || UNIVERSAL_PRICING_CODE
  || '|'
  || CLASS_ID
  || '|'
  || IS_PRODUCT_LINK_FLAG
  || '|'
  || IS_STOREFRONT_FLAG
  || '|'
  || IS_MERCHANDISER_FLAG
  || '|'
  || CURRENCY
  || '|'
  || PATH
  || '|'
  || GROUP_ID
  || '|'
  || CATEGORYS
  || '|'
  || REPLACE(SIZES,CHR(10),'')
  || '|'
  || REPLACE(COLOR,CHR(10),'')
  || '|'
  || LARGER_IMAGES
  || '|'
  || QTY_ON_HAND
  || '|'
  || AUD
  || '|'
  || GBP
  || '|'
  || CHF
  || '|'
  || CAD
  || '|'
  || AU_PUBLISH
  || '|'
  || UK_PUBLISH
  || '|'
  || CH_PUBLISH
  || '|'
  || CA_PUBLISH
  || '|'
  || ITEM_FLAG
  || '|'
  || BM_CODE
  || '|'
  || ''
  || '|'
  ||
  CASE
    WHEN VARIATION_NAME = 'P'
    THEN
      CASE
        WHEN PATH IS NULL
        THEN UPPER(CATEGORYS)
        ELSE UPPER(PATH)
      END
    ELSE NULL
  END
  || '|'
  ||replace(ALT_IMAGE_URL,'300x400','960x1280')
  || '|'
  ||DEPARTMENT_ID
  || '|'
  ||
  CASE
    WHEN CLEARANCE_TYPE = 'C'
    THEN 'Y'
    ELSE 'N'
  END
  || '|'
  || DECODE(ITM_GENDER, '1','Not Applicable', '2','Men', '3','Women', '4','Unisex','5','Kids','6','Pets', NULL)
  || '|'
  ||
  CASE
    WHEN f.upc IS NULL
    THEN 'N'
    ELSE 'Y'
  END
FROM &2.CHANNEL_ADVISOR_EXTRACT_NEW n
LEFT JOIN final_sale f ON n.upc          = f.upc
WHERE qty_on_hand > 0 AND upper(trim(brand)) NOT IN ('PRADA','TOMMY BAHAMA');

SPOOL OFF;

EXIT;


