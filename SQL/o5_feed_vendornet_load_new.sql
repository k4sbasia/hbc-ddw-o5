REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_feed_vendornet_load_new.sql
REM  DESCRIPTION:  This code does the following.
REM                1. Extract the data for Dropship items for vendornet
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Hars Desai                 03/18/2019              Created
REM ############################################################################
SET echo OFF
SET feedback ON
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF
SET trimspool ON
SET serverout ON

INSERT
INTO o5.bi_vendornet_prod_new
  (
    product_id,
    ordertype,
    sku,
    sku_description,
    vendorcode,
    vendorsku,
    vendordesc,
    upc
  )
SELECT product_code,
  'DS',
  sku,
  item_description AS sku_description,
  vendor_id,
  VEN_STYL_NUM,
  vendordesc,
  upc
FROM
  (SELECT product_code,
    'DS',
    sku,
    item_description,
    NVL(rfs_vendor_no,VENDOR_ID) vendor_id,
    ven_styl_num,
    item_description AS vendordesc,
    upc
  FROM o5.bi_product p
  WHERE to_number(p.sku) in (select skn_no from o5.oms_rfs_o5_stg where upc=reorder_upc_no and vds_ind='Y'and catalog_ind = 'Y')
  );
COMMIT;

DELETE
FROM o5.bi_vendornet_prod_new
WHERE ADD_DT < SYSDATE-30;
COMMIT;


MERGE INTO o5.bi_vendornet_prod_new tg USING
(SELECT
  product_id prd_code_lower,
  dropship_leaddays leaddays
FROM o5.all_active_pim_prd_attr_o5
) src ON (tg.product_id = src.prd_code_lower AND add_dt=TRUNC(sysdate))
WHEN MATCHED THEN
  UPDATE
  SET tg.leaddays = src.leaddays;
  COMMIT;

  /*unit weight updated*/
  MERGE INTO o5.bi_vendornet_prod_new tg USING
  (SELECT
    /*+driving_site(B)*/
    DISTINCT A.PRODUCT_ID,
    A.SKU SKN_NO,
    TO_CHAR((B.ITEM_UNIT_WT_KG*2.2046),'fm9999999.90') pounds
  FROM o5.bi_vendornet_prod_new A,
    o5.oms_rfs_O5_stg B
  WHERE A.PRODUCT_ID=B.product_code
  AND to_number(A.SKU)         =B.SKN_NO
  AND A.add_dt                 =TRUNC(sysdate)
  ) src ON (tg.product_id      = src.PRODUCT_ID AND to_number(tg.SKU)=to_number(src.SKN_NO) AND add_dt=TRUNC(sysdate))
WHEN MATCHED THEN
  UPDATE
  SET tg.unit_wt_lbs = src.pounds;
  COMMIT;


  MERGE INTO o5.bi_vendornet_prod_new trg USING
  (SELECT product_id prd_code_lower,
    case when PRD_READYFORPROD= 'Yes' then 'T' else 'F' end READYFORPROD ,
   REPLACE (REPLACE(REPLACE(REPLACE( bm_desc, '^', '\^'), '\', '\\'),'amp;',''),'<br>','')
  FROM
    o5.all_active_pim_prd_attr_o5
    ) hst ON (trg.product_id = hst.prd_code_lower AND add_dt=TRUNC(sysdate))
WHEN MATCHED THEN
  UPDATE
  SET trg.readyforprod = hst.READYFORPROD,
    trg.sku_description =  bm_desc
  ;
  COMMIT;


   /*UPDATE COLOR & SIZE*/
   MERGE INTO o5.bi_vendornet_prod_new trg USING
 (SELECT UPC sku_code_lower,
   SKU_COLOR color,
   sku_size_desc sizes
 FROM o5.all_active_pim_sku_attr_o5
 ) hst ON trg.upc = hst.sku_code_lower AND add_dt=TRUNC(sysdate))
WHEN MATCHED THEN
 UPDATE
 SET trg.sku_description=trg.sku_description
   || ' / '
   ||hst.color
   ||' / '
   ||hst.sizes;
 COMMIT;

  /*UPDATE VENDORCODE WITH 7 digit number*/
  merge INTO o5.bi_vendornet_prod_new t USING
  (SELECT DISTINCT MIN(a.vendor_no) vendor_num ,
    b.ssn
  FROM rfs.rf_dept_mfg@SAKSRFS_PRD a,
    rfs.rf_item@SAKSRFS_PRD b
  WHERE a.dept_no      = b.dept_no
  AND a.mfg_no         = b.mfg_no
  AND fashion_style_no<>'999999'
  GROUP BY b.ssn
  ) s ON ( ltrim(t.product_id,'0') = s.ssn AND add_dt=TRUNC(sysdate))
WHEN matched THEN
  UPDATE SET vendorcode = s.vendor_num;
  COMMIT;


EXIT;
