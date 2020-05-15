set linesize 1000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
truncate table &1;
INSERT INTO &1 (product_code, folder_id, folder_parent_id, folder_name, parent_folder_name, assortment)
select
product_id product_code,folder_id,folder_parent_id,label folder_name,
case when primary_parent_category = 'EditorialEvents' then 'Editorial Events'
    when primary_parent_category = 'EmailEvents' then 'Email Events'
    else
 (SELECT
   distinct
    label
        from &2.ALL_ACTV_PIM_ASST_FULL_o5@&3  p
        where p.folder_id=a.folder_parent_id)
   end      parent_folder_name,
        primary_parent_category assortment
--rtrim(lower(replace(replace(replace(replace( folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>'),folder_name,'')),'>')
from &2.ALL_ACTV_PIM_ASST_FULL_o5@&3 a;
commit;
exit;
