WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT 'category_id' || '|' || 'parent_id' || '|' || 'name' FROM DUAL;
select '1408474395181059'|| '|' ||' '||'|' ||'ShopCategory' from dual
union
select '1408474395181057'|| '|' ||' '||'|' ||'Custom' from dual
union
select '2534374302023913'|| '|' ||'1408474395181057'||'|' ||'Email Events' from dual
union
select distinct folder_id|| '|' ||folder_parent_id|| '|' ||label from o5.ALL_ACTV_PIM_ASST_FULL_o5
union
SELECT distinct
lower(replace(replace(replace( folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>'))
    || '|'
    || rtrim(lower(replace(replace(replace(replace( folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>'),folder_name,'')),'>')
    || '|'
    ||folder_name
from
o5.ALL_ACTV_PIM_ASST_FULL_o5
;
EXIT;
