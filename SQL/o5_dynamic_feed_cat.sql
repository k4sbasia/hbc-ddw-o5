REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  sfcc_dynamic_feed_cat.sql
REM  DESCRIPTION:  This script prepares the XML data for SFCC dynamic assignments
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name	               		Date 	       	Description
REM
REM ############################################################################
set sqlblanklines ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR  EXIT FAILURE
set echo off
set feedback off
set linesize 32767
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
SET LONG 999999999
COL xml FORMAT A32000
set serveroutput on
set feedback on
DECLARE
xml_item   CLOB;
BEGIN
WITH all_dynamic_assignment
AS
(
SELECT DISTINCT prduct_code product_id,CASE WHEN isclearance = 'true' THEN 1584570370926
                                       ELSE NULL
                                       END AS ICF, 
									   CASE WHEN dfs_flag = 'Y' THEN 1586293950803
                                       ELSE NULL
                                       END AS DFS,dfs_flag,isnew
       FROM O5.sfcc_prod_product_data sp
       where
      ( (exists  (select 'X' from  O5.SFCC_PROD_SKU_DYN_FLAGS si where sp.PRDUCT_CODE=si.product_id and
                              ( si.DYN_FLAG_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC_ASSGN')
                                OR  si.IN_STOCK_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC_ASSGN')
                              )
                              )
       OR
       sp.DYN_FLAG_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC_ASSGN')
     )
       OR ( sp.PIM_CHG_DT >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC_ASSGN')
           ) )
  --   AND
    -- PRDUCT_CODE in( '0600003098431','0600089175641','0600087533652','0600003459849')
),
isnewflags as (select distinct product_id,primary_parent_category  from O5.SFCC_ACTV_PIM_ASSORTMENT_O5 a) 
SELECT '<?xml version="1.0" encoding="UTF-8"?>'||
      XMLSERIALIZE(DOCUMENT (
      XMLELEMENT(
          "catalog",
          XMLATTRIBUTES(
              'storefront-o5a' AS "catalog-id",
              'http://www.demandware.com/xml/impex/catalog/2006-10-31' AS "xmlns"),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584570370926 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450196 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450197 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450198 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450199 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450200 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450201 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(
       XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1584742450202 AS "category-id", a.product_id AS "product-id", 'delete' as "mode"))
                   ),
      XMLAGG(Case when dfs_flag = 'N' THEN 
	   XMLELEMENT ("category-assignment",
                   XMLATTRIBUTES (1586293950803 AS "category-id", a.product_id  AS "product-id", 'delete' as "mode") ) END
                   )
--                   ,
--                  XMLAGG(
--                  XMLELEMENT ("category-assignment",
--                   XMLATTRIBUTES (1580222661860 AS "category-id", product_id AS "product-id", 'delete' as "mode"))
--                   )
--                 ,
--                  XMLAGG(
--                  XMLELEMENT ("category-assignment",
--                   XMLATTRIBUTES (1580222661862 AS "category-id", product_id AS "product-id" , 'delete' as "mode"))
--                   )
                   ,
                  XMLAGG(
                        CASE WHEN ICF IS NOT NULL THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (ICF AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN DFS IS NOT NULL THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (DFS AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Women' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450196 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Shoes'  THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450197 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Shoes' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450196 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Handbags'  THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450198 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Handbags' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450196 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'JewelryAccessories' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450199 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Beauty' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450200 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Home' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450202 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               ),
                  XMLAGG(
                        CASE WHEN isnew='true' AND primary_parent_category = 'Men' THEN
                                   XMLELEMENT ("category-assignment",
                                           XMLATTRIBUTES (1584742450201 AS "category-id", a.product_id AS "product-id"))
                               ELSE NULL            END
                               )
                   )) AS CLOB INDENT SIZE = 5)
                   into xml_item
FROM all_dynamic_assignment a,isnewflags  b where a.product_id = b.product_id(+)
--WHERE category_id IS NOT NULL
 ;
DBMS_XSLPROCESSOR.clob2file(xml_item, 'DATASERVICE', 'dynamic_categories_feed_o5_'||'&1'||'.xml', nls_charset_id('AL32UTF8'));
END;
/

exit;
