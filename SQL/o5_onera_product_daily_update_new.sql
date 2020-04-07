REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  onera_product_daily.sql
REM  DESCRIPTION:  Extract product data for onera
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------          ----------      --------------------------
REM                Harsh Desai               09/05/2018        Created
REM ############################################################################
set serverout on
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT  '"UPC' ||'","'||
        'VENDOR_ID' ||'","'||
        'DIVISION_ID' ||'","'||
        'GROUP_ID' ||'","'||
        'DEPARTMENT_ID' ||'","'||
        'CLASS_ID' ||'","'||
        'PRODUCT_CODE' ||'","'||
        'SKU_COLOR' ||'","'||
        'ITEM_COST_AMOUNT' ||'","'||
		'MARGIN'||'","'||
		'LABEL_NAME'  ||'","'||
        'ITEM_DESCRIPTION' ||'","'||
        'SKN' ||'","'||
        'SKN_SIZE' ||'","'||
        'SALE_PRICE' ||'","'||
        'PRICE_STATUS' ||'","'||
        'JEWELRY_FLAG' ||'","'||
        'BOPUS_ELIGIBILITY' ||'","'||
		'DROPSHIP_IND'||'","'||
        'ACTIVE_FLAG"'
 FROM dual;
SELECT distinct '"'|| CASE  WHEN (LENGTH(TO_CHAR(P.UPC))<12)  THEN LPAD(TO_CHAR(P.UPC), 12,0)  WHEN (LENGTH(TO_CHAR(P.UPC))=13)   THEN REGEXP_REPLACE(TO_CHAR(P.UPC),'^0')
    ELSE TO_CHAR(P.UPC)  END
            ||'","'||
            TRIM(P.VENDOR_ID) ||'","'||
            TRIM(P.DIVISION_ID)  ||'","'||
            TRIM(P.GROUP_ID)  ||'","'||
            TRIM(P.DEPARTMENT_ID)  ||'","'||
            TRIM(P.CLASS_ID)  ||'","'||
            TRIM(NVL(P.PRODUCT_CODE, p.ITEM))  ||'","'||
            TRIM(REGEXP_REPLACE(replace(replace(replace(P.SKU_COLOR, CHR (10), ' '), CHR (13), ' '), chr(9), ' '), ' +', ' '))  ||'","'||
            TRIM(to_char(P.ITEM_CST_AMT))  ||'","'||
            TRIM(to_char(P.SKU_SALE_PRICE-P.ITEM_CST_AMT)) ||'","'||
            TRIM(REGEXP_REPLACE(replace(replace(replace(P.BRAND_NAME, CHR (10), ' '), CHR (13), ' '), chr(9), ' '), ' +', ' '))  ||'","'||
            TRIM(REGEXP_REPLACE(replace(replace(replace(P.ITEM_DESCRIPTION, CHR (10), ' '), CHR (13), ' '), chr(9), ' '), ' +', ' '))  ||'","'||
           to_number(p.SKU) ||'","'||
                   TRIM(REGEXP_REPLACE(replace(replace(replace(P.SKU_SIZE, CHR (10), ' '), CHR (13), ' '), chr(9), ' '), ' +', ' ')) ||'","'||
            TRIM(to_char(P.SKU_SALE_PRICE))  ||'","'||
            TRIM(to_char(P.PRICE_STATUS))   ||'","'||
                        ''||'","'||
                        ''||'","'||
           nvl(dropship_ind,'F')||'","'||
           case when s.SKU_STATUS ='Yes' THEN 'Y' ELSE 'N' END||'"'
FROM    &1.bi_product p,&1.oms_rfs_o5_stg o, &1.all_active_pim_sku_attr_&2 s
             where p.product_code = o.product_code
             and to_number(p.sku) = o.skn_no
             and to_number(p.upc) = o.upc
             and o.upc = s.upc
			 and o.upc = o.reorder_upc_no
;

quit;
