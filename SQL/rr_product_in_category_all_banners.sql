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
  FROM &2.all_actv_pim_assortment_&3 prd
  JOIN pim_exp_bm.pim_ab_o5_web_folder_data@&4 fld ON fld.folder_path = prd.folder_path
 WHERE EXISTS(SELECT 1 FROM &2.o5_partners_extract_wrk prt WHERE wh_sellable_qty > 0 AND prt.styl_seq_num = prd.product_id AND sku_list_price IS NOT NULL)
;
exit;
