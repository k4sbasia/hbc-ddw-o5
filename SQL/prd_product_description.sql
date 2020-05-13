REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  bi_product_description.sql
REM  DESCRIPTION:  This is a weekly update refresh the bi_product_description
REM                table with the bm_description
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Rajesh Mathew              12/06/2010              Created
REM
REM ############################################################################
--Updated bp.item with bp.product_code - Jayanthi as we have product_code in mrep.bi_product
set serveroutput on
MERGE INTO mrep.BI_PRODUCT_DESCRIPTION tg
     USING (SELECT DISTINCT
                   p.prd_code_lower AS product_id,
                   bp.product_code item,
                   oa.oba_str_val AS short_description
              FROM martini_main.object_attribute@CLONESTO_MREP oa,
                   martini_main.product@CLONESTO_MREP p,
                   mrep.bi_product bp
             WHERE     p.version = 1
                   AND oa.version = 1
                   AND oa.oba_obj_id = p.prd_id
                   AND p.prd_code_lower = BP.PRODUCT_CODE
                   AND p.prd_status_cd <> 'D'
                   AND oa.oba_atr_id IN
                          (SELECT a.atr_id
                             FROM martini_main.
                                   attribute@CLONESTO_MREP a
                            WHERE a.atr_nm_lower = 'productshortdescription')
                     ) src
        ON (TG.PRODUCT_ID = src.item)
WHEN MATCHED
THEN
   UPDATE SET tg.short_description = src.short_description
WHEN NOT MATCHED
THEN
   INSERT     (tg.product_id, tg.short_description)
       VALUES (src.item, src.short_description);
commit;

--Refresh sddw materialized view:

exec  dbms_mview.refresh ('SDDW.MV_BI_PRODUCT_DESCRIPTION','F');

--For o5th product description update for not on site report
MERGE INTO o5.O5_PRODUCT_DESCRIPTION tg
     USING (SELECT
                        p.product_id AS item,
                        p.bm_desc AS short_description
                   FROM o5.ALL_ACTIVE_PIM_PRD_ATTR_O5 p
                     ) src
        ON (TG.PRODUCT_ID = src.item)
WHEN MATCHED
THEN
   UPDATE SET tg.short_description = src.short_description
WHEN NOT MATCHED
THEN
   INSERT     (tg.product_id, tg.short_description)
       VALUES (src.item, src.short_description);
commit;

exec  dbms_mview.refresh ('SDDW.MV_O5_BI_PRODUCT_DESCRIPTION','C');

exit;
