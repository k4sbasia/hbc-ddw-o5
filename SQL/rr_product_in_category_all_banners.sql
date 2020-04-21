REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  product_in_category_sitename.sql
REM  DESCRIPTION:  It creates a data file with product heirarchy details
REM
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Unknown                      Unknown         Created
REM                Rajesh Mathew                        07/14/2010              Modified
REM ############################################################################
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

select 'category_id'||'|'||'product_id' from dual;
SELECT fld.folder_id || '|' || prd.product_id
  FROM o5.SFCC_ACTV_PIM_ASSORTMENT_O5 prd
 inner JOIN pim_exp_bm.pim_ab_o5_web_folder_data@pim_read fld ON trim(fld.folder_path) = trim(prd.folder_path)
union
SELECT lower(replace(replace(replace( prd.folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>')) || '|' || prd.product_id
  FROM o5.SFCC_ACTV_PIM_ASSORTMENT_O5 prd
 inner JOIN pim_exp_bm.pim_ab_o5_web_folder_data@pim_read fld ON trim(fld.folder_path) = trim(prd.folder_path)
;
exit;
