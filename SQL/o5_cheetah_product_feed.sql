set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT
UPC||'|'||
replace(MREP.CHAR_REPLACE_NEW(SKU_DESC), '|', ' ') ||'|'||
STYL_SEQ_NUM||'|'||
replace(MREP.CHAR_REPLACE_NEW(category), '|', ' ') ||'|'||
prd_parent_id ||'|'||
replace(MREP.CHAR_REPLACE_NEW(bm_desc), '|', ' ') ||'|'||
sku_sale_price||'|'||
COMPARE_PRICE ||'|'||
replace(MREP.CHAR_REPLACE_NEW(BRAND_NAME), '|', ' ') ||'|'||
replace(MREP.CHAR_REPLACE_NEW(SKU_COLOR), '|', ' ') ||'|'||
replace(MREP.CHAR_REPLACE_NEW(SKU_SIZE1_DESC), '|', '/') ||'|'||
REPLACE(image_url,'_300x400.jpg','_247x329.jpg')||'|'||
REPLACE(image_url,'_300x400.jpg','_222x296.jpg')||'|'||
'USD'||'|'||
''
from
&1.&3
where wh_sellable_qty >0
;
exit
