set timing on
set echo on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set timing on

WHENEVER SQLERROR EXIT SQL.SQLCODE;
insert into O5.O5_PARTNERS_EXTRACT_WRK
(merchant_id,
   department_name,
   group_name,
   class_name,
   sku,
   sku_color,
   sku_size1_desc,
   sku_size2_desc,
   upc,
   sku_desc,
   dutiable_price,
   group_id,
   department_id,
   class_id,
   item,
   styl_seq_num,
   brand_name,
   sku_list_price,
   sku_sale_price,
   sku_parent_id,
   web_book_dt,
   wh_sellable_qty,
   prd_parent_id,
   bm_desc,
   productcopy,
   fabric1,
   fabric1pct,
   fabric2,
   fabric2pct,
   fabric3,
   fabric3pct,
   fabric_cont,
   coo,
   modify_dt,
   item_cst_amt,
   net_weight,
   unit_weight,
   vendor_id,
   off_price_ind,
   gwp_flag,
   is_egc,
   morecolors,
   preorder,
   product_url,
   image_url,
 clearance_type,
   division_id,
   division_name,
   Path,
   category,
   ven_styl_num,
   is_readyforprod,
   is_reviewable,
   is_shopthelook,
   country_restriction,
   item_gender,
   pip_text,
   pick_up_allowed_ind,
   store_id,
   back_orderable,
   create_timestamp,
   update_timestamp
)
SELECT 0,
rfs.department_name AS department_name,
rfs.group_name AS group_name,
           prd.class_name AS class_name,
     TO_NUMBER(prd.sku) AS sku,
     sku_attr.sku_color AS sku_color,
           sku_attr.sku_size_desc AS sku_size1_desc,
           sku_attr.size2_description AS sku_size2_desc,
     prd.upc AS upc,
     prd.sku_desc,
     NULL AS dutiable_price,
     NVL(rfs.group_id,prd.group_id) as group_id,
           NVL(rfs.department_id,prd.department_id) as department_id,
           prd.class_id AS class_id,
     prd.item AS item,
           bm.product_id AS styl_seq_num,
           prd_attr.brand_name AS brand_name,
     NULL AS sku_list_price,
           NULL AS sku_sale_price,
           bm.product_id AS sku_parent_id,
     NULL AS web_book_dt,
     0 AS wh_sellable_qty,
           bm.product_id AS prd_parent_id,
     prd_attr.bm_desc AS bm_desc,
     prd_attr.productcopy AS productcopy,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     NULL,
     SYSDATE,
         prd.item_cst_amt AS item_cst_amt,
           NULL AS net_weight,
           NULL AS unit_weight,
     prd.vendor_id AS vendor_id,
       NULL as off_price_ind,
           prd_attr.gwp_flag AS gwp_flag,
           prd_attr.isegc AS is_egc,
           NULL AS morecolors,
           NULL AS preorder,
     url.eng_url AS  product_url,
           case when 'o5' ='o5' then 'https://image.s5a.com/is/image/saksoff5th/'|| bm.product_id
            else 'https://image.s5a.com/is/image/saks/'||bm.product_id
            end upc_url,
           NULL AS clearance_type,
           NVL(rfs.division_id,prd.division_id) as division_id,
           rfs.division_name AS division_name,
           asst.folder_path AS assortment,
           asst.primary_category AS label,
           prd.ven_styl_num AS ven_styl_num,
           'T' AS is_readyforprod,
           prd_attr.is_reviewable AS is_reviewable,
           prd_attr.is_shopthelook AS is_shopthelook,
           NULL AS country_restriction,
           prd_attr.item_gender AS item_gender,
          NULL AS pip_text,
           CASE WHEN rfs.is_pickup_allowed = 'Y' THEN 'TRUE' ELSE 'FALSE' END AS pick_up_allowed_ind,
           NULL AS store_id,
           prd_attr.back_orderable AS back_orderable,
           sysdate AS create_timestamp,
           NULL AS update_timestamp
       FROM
          O5.v_active_product_O5 bm
           LEFT JOIN (
               SELECT DISTINCT
                      prd.product_code,
                   prd.upc,
                   prd.class_id,
                   NULL AS class_name,
                   prd.department_id as department_id,
                   prd.group_id as group_id,
         nvl(prd.sku_description,prd.item_description) sku_desc,
                   prd.division_id as division_id,
                   prd.vendor_id,
                   prd.ven_styl_num,
                   MAX(prd.item_cst_amt) OVER (PARTITION BY PRD.product_code ORDER BY PRD.product_code) AS item_cst_amt,
                   prd.sku,
                   prd.item
--                    prd.modify_dt
               FROM
                  O5.bi_product prd
                    --AND ltrim(prd.group_id,'0') = ltrim(hi.group_id,'0')
        WHERE prd.deactive_ind = 'N'
           ) prd ON bm.product_id = prd.product_code							       --Table is used to filter Active and readyforProd Products
           INNER JOIN O5.all_active_pim_prd_attr_O5 prd_attr ON prd_attr.product_id = bm.product_id               --PIM Product Attributes
           INNER JOIN O5.all_active_pim_sku_attr_O5 sku_attr ON sku_attr.upc = lpad(prd.upc,13,'0') and  sku_status='Yes'                 --PIM SKU Attributes
           LEFT JOIN
           (select  product_id,
           case when primary_parent_category ='ShoesBags' then 'Shoes'||' & '|| 'Handbags'
    when primary_parent_category ='Women' then 'Womens Apparel'
    when primary_parent_category ='Men' then 'Mens'
    when primary_parent_category ='JewelryAccessories' then 'Jewelry'||' & '||'Accessories'
    else primary_parent_category
    end primary_category,folder_path,primary_parent_category
              from O5.all_actv_pim_assortment_O5 ) asst ON bm.product_id = asst.product_id                       --PIM Product Assortments
           LEFT JOIN (SELECT DISTINCT skn_no, is_pickup_allowed , lpad(r.department_id,3,0) department_id,r.dept_name department_name,
           substr(r.group_id,-2) group_id ,substr(r.division_name,1,24) group_name, substr(r.division_id,1,1) division_id , substr(r.department_name,1,24)
           division_name  FROM O5.OMS_RFS_O5_STG r) rfs ON rfs.skn_no = LTRIM(prd.sku,'0')
         LEFT JOIN (SELECT  product_code,
       seo_url eng_url
               FROM O5.PRODUCT_SEO_URL_MAPPING ) url on bm.product_id = url.product_code;
                   commit;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' End Inserting O5.bi_partners_extract_wrk :'||' '||NVL((SQL%ROWCOUNT),0)||' rows affected.');
COMMIT;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||to_char(sysdate,'MM-DD-YYYY HH:Mi:SS')||' Start Gathering all sizes and color in order to concatenate and load product aggregate table');
INSERT INTO O5.bi_product_aggregate
SELECT
     agg.product_code,
     agg.prod_sizes,
     agg.prod_colors,
     '' prod_alt_img_urls,
     sysdate AS create_timestamp,
     sysdate AS update_timestamp
 FROM
 (
      SELECT
             styl_seq_num product_code,
             LISTAGG(sku_color,',') WITHIN GROUP(ORDER BY styl_seq_num) AS prod_colors,
             LISTAGG(sku_size1_desc,',') WITHIN GROUP(ORDER BY styl_seq_num) AS prod_sizes
         FROM O5.O5_PARTNERS_EXTRACT_WRK
         GROUP BY styl_seq_num
     ) agg;
-- LEFT JOIN O5.image_alt_o5 img ON img.product_code = agg.product_code;

DBMS_STATS.GATHER_TABLE_STATS('O5','BI_PARTNERS_EXTRACT',FORCE => TRUE);
-- Start Merging Prices for All SKU's into Partners
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  ' || 'Merge prices for All SKUs Start : ' ||to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
MERGE INTO O5.O5_PARTNERS_EXTRACT_WRK tg
USING (
    SELECT skn_no,
           offer_price,
           original_ticket,
           current_ticket,
           MSRP,
           sd_pip_text,
           CASE WHEN price_flag IN ('M','C','F','P') THEN 'C' ELSE NULL END price_fg,
           compare_at
      FROM O5.V_SD_PRICE_O5
--     WHERE skn_no = '1013931'
    ) src
ON (src.skn_no = tg.sku)
WHEN MATCHED THEN UPDATE
SET
    tg.sku_sale_price = src.offer_price,
    tg.dutiable_price = src.offer_price,
    tg.sku_list_price = src.msrp,
    tg.pip_text = src.sd_pip_text,
    tg.clearance_type = src.price_fg,
    tg.compare_price = src.compare_at
;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  ' || 'Merge prices for All SKUs Complete : ' ||to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || SQL%rowcount);
COMMIT;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  ' || 'Merge Inventory for All SKUs Start : ' ||to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
MERGE INTO O5.&3 tg
USING
    ( SELECT skn_no skn, in_stock_sellable_qty qty
	FROM O5.inventory src) sr ON (tg.sku = sr.skn)
WHEN MATCHED THEN
    UPDATE SET tg.wh_sellable_qty = sr.qty;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  ' || 'Merge Inventory for All SKUs Complete : ' ||to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || SQL%rowcount);
COMMIT;
EXCEPTION
WHEN OTHERS
THEN
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||to_char(sysdate,'MM-DD-YYYY HH:MI:SS')||' Main PLSQL Block Failed!!');
    DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||sqlerrm);
    RAISE;
END;
/
EXIT;
