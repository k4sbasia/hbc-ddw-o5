whenever sqlerror exit failure
set linesize 32767
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout off
set verify off
set define off


TRUNCATE TABLE O5.STG_GOOGLE_FEED_O5;

INSERT into O5.STG_GOOGLE_FEED_O5(
UPC, DEPARTMENT_NAME, SHORT_DESCRIPTION, WEB_PRICE, BRAND_NAME, IMAGE_URL, SKU_SIZE, SKU_COLOR, PRODUCT_CODE, VENDOR_STYLE_20CH, ADD_DT,SKN_NO
)
select distinct a.UPC,
 a.DEPARTMENT_NAME,
 a.SHORT_DESCRIPTION,
 a.CUR_TKT_PRICE_DOL,
 a.BRAND_NAME,
 a.IMAGE_URL,
 a.SKU_SIZE,
 a.SKU_COLOR,
  a.PRODUCT_CODE PRODUCT_CODE,
 a.VENDOR_STYLE_20CH,
 trunc(SYSDATE) ADD_DT,
 a.SKN_NO
from O5.OMS_RFS_O5_STG a,
    o5.bi_product p
where
 a.upc = A.REORDER_UPC_NO
and lpad(a.upc,13,0)=p.upc
and A.SHORT_DESCRIPTION <> 'DO NOT USE'
and exists (select product_id from o5.v_active_product_o5 b where p.product_code = b.product_id)
--and a.DEPARTMENT_ID in ('932')
--and a.DIVISION_ID like '4%'
--and lower(p.brand_name) in ('pure navy','renvy','saks fifth avenue','ava & aiden','nhp','russel park')
;

commit;


SELECT 'itemid'||chr(9) ||
 'title' ||chr(9) ||
 'description' ||chr(9) ||
 'price' ||chr(9) ||
 'gtin' ||chr(9) ||
 'brand' ||chr(9) ||
 'image_link' ||chr(9) ||
 'size' ||chr(9) ||
 'color' ||chr(9) ||
 'item_group_id' ||chr(9) ||
 'mpn' ||chr(9) ||
 'condition'
from dual;


SELECT distinct regexp_replace(lpad(UPC,13,'0'), '[[:space:]]+', chr(32)) ||chr(9)||
 regexp_replace(DEPARTMENT_NAME , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(SHORT_DESCRIPTION, '[[:space:]]+', chr(32))||chr(9)||
 regexp_replace(to_char(WEB_PRICE,'FM999999.00'), '[[:space:]]+', chr(32)) ||chr(9) ||
 regexp_replace(lpad(UPC,13,'0') , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(BRAND_NAME , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(IMAGE_URL, '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(SKU_SIZE , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(SKU_COLOR , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(PRODUCT_CODE , '[[:space:]]+', chr(32))||chr(9) ||
 regexp_replace(VENDOR_STYLE_20CH, '[[:space:]]+', chr(32)) ||chr(9) ||
 'new'
FROM  O5.STG_GOOGLE_FEED_O5 a ,
(select item_id,SHIPNODE_KEY ship_node ,ATP -PICKUP_SS  ONHAND_AVAILABLE_QUANTITY  from  O5.O5_OMS_COMMON_INV where trim(ORGANIZATION_CODE) = 'OFF5' and trim(SHIPNODE_KEY) not in ('DC-LVG-789','DC-789-593') 
 --and trim(SHIPNODE_KEY) in ('7843','7842')
and (ATP - PICKUP_SS) >1) b
Where a.skn_no = trim(b.item_id);

Exit;
