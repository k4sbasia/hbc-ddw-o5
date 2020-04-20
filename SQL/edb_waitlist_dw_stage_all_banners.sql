merge INTO &1.WAITLIST TRG USING
(SELECT distinct
waitlist_id,
upper(trim( EMAIL_address))  EMAIL_address,
       upc,
       SKU_PRICE,
       PRODUCT_DETAIL_URL,
       product_code,
       qty,
       BRAND_name,
       item_desc,
       sku_size,
       SKU_COLOR,
       WAITLIST_CREATED_DT,
       WAITLIST_STATUS_CHANGE,
           REGEXP_REPLACE(PHONE_NUMBER,'[^0-9]+', '') PHONE_NUMBER
FROM &1.edb_stage_dw_waitlist_wrk
) SRC ON (UPPER(TRIM(SRC.EMAIL_ADDRESS))=UPPER(TRIM(TRG.EMAIL_ADDRESS)) AND SRC.UPC=TRG.UPC AND trunc(src.WAITLIST_CREATED_DT)= trunc(trg.WAITLIST_CREATED_DT))
WHEN NOT matched THEN
  INSERT
    (
      waitlist_id,
      EMAIL_address,
      upc,
      SKU_PRICE,
      product_detail_url,
      SKU_IMAGE_URL,
      product_code,
      qty,
      BRAND_name,
      item_desc,
 sku_size,
      SKU_COLOR,
      waitlist_status,
      WAITLIST_CREATED_DT,
      WAITLIST_STATUS_CHANGE,
      PHONE_NUMBER
    )
    VALUES
    (
      src.waitlist_id,
      upper(trim(src.EMAIL_address)),
      src.upc,
      src.SKU_PRICE,
      SRC.PRODUCT_DETAIL_URL,
      '&2'|| lpad(src.PRODUCT_CODE,13,'0')||'_222x296.jpg',
      src.product_code,
      src.qty,
      src.BRAND_name,
      src.item_desc,
      src.sku_size,
      src.SKU_COLOR,
      'N',
      SRC.WAITLIST_CREATED_DT,
      SRC.WAITLIST_STATUS_CHANGE,
          SRC.PHONE_NUMBER
    );
commit;
exit

