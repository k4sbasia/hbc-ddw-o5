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
SELECT folder_id || '|' || product_id
  FROM o5.ALL_ACTV_PIM_ASST_FULL_o5
union
SELECT lower(replace(replace(replace( folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>')) || '|' || product_id
  FROM o5.ALL_ACTV_PIM_ASST_FULL_o5;
exit;
