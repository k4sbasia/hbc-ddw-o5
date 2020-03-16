set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
SELECT 'HDR'||'|'||'38801'||'|'||'SAKSOFF5TH'||'|'||TO_DATE(SYSDATE,'YYYY-MM-DD/HH:MI:SS') FROM DUAL;

SELECT
UPC||'|'||
replace(bm_desc,'|','-') ||'|'||
STYL_SEQ_NUM||'|'||
CASE WHEN PATH IS NULL THEN CATEGORY else path end||'|'||
''  ||'|'||
replace(product_url,'?site_refer=','')||'|'||
replace(image_url,'300x400','486x648')||'|'||
''  ||'|'||
replace(bm_desc,'|','') || '|'||
trim(replace(mrep.str_html(productcopy),'|',' ') ) || '|'||
''  ||'|'||
''  ||'|'||
sku_sale_price||'|'||
SKU_LIST_PRICE||'|'||
''  ||'|'||
''  ||'|'||
BRAND_NAME||'|'||
''  ||'|'||
'N' ||'|'||
''  ||'|'||
'Y' ||'|'||
STYL_SEQ_NUM||'|'||
''  ||'|'||
''  ||'|'||
''  ||'|'||
''  ||'|'||
'60' ||'|'||
'Y' ||'|'||
'N' ||'|'||
'Y' ||'|'||
'USD'||'|'||
'' ||'|'||
replace(O5.F_GET_ALT_IMAGE_URL (STYL_SEQ_NUM),'300x400','486x648')
from
&1.O5_PARTNERS_EXTRACT_WRK  where wh_sellable_qty > 0;

select 'TRL' ||'|'||count(distinct upc)
FROM &1.O5_PARTNERS_EXTRACT_WRK  where wh_sellable_qty > 0;

exit;
