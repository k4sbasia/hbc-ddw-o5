set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
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
image_url||'_247x329.jpg'||'|'||
image_url||'_222x296.jpg'||'|'||
'USD'||'|'||
''
from
&1.&3
where wh_sellable_qty >0
;
exit

