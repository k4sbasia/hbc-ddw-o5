SET ECHO OFF
SET TIMING ON
SET LINESIZE 10000
SET PAGESIZE 0
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION ENABLE PARALLEL DML;

declare
Begin
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '|| TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS') || ' START of Partners Extract Insert');

EXECUTE IMMEDIATE 'TRUNCATE TABLE &2.&3';
EXECUTE IMMEDIATE 'TRUNCATE TABLE &2.image_alt_&1';
EXECUTE IMMEDIATE 'TRUNCATE TABLE &2.bi_product_aggregate';
INSERT INTO &2.&3 (
        merchant_id,
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
        path,
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
        SELECT
            0,
            rfs.department_name          AS department_name,
            rfs.group_name               AS group_name,
            prd.class_name               AS class_name,
            to_number(prd.sku) AS sku,
            sku_attr.sku_color           AS sku_color,
            sku_attr.sku_size_desc       AS sku_size1_desc,
            sku_attr.size2_description   AS sku_size2_desc,
            prd.upc                      AS upc,
            prd.sku_desc,
            NULL AS dutiable_price,
            nvl(rfs.group_id, prd.group_id) AS group_id,
            nvl(rfs.department_id, prd.department_id) AS department_id,
            prd.class_id                 AS class_id,
            prd.item                     AS item,
            bm.product_id                AS styl_seq_num,
            prd_attr.brand_name          AS brand_name,
            NULL AS sku_list_price,
            NULL AS sku_sale_price,
            bm.product_id                AS sku_parent_id,
            NULL AS web_book_dt,
            0 AS wh_sellable_qty,
            bm.product_id                AS prd_parent_id,
            prd_attr.bm_desc             AS bm_desc,
            prd_attr.productcopy         AS productcopy,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            sysdate,
            prd.item_cst_amt             AS item_cst_amt,
            NULL AS net_weight,
            NULL AS unit_weight,
            prd.vendor_id                AS vendor_id,
            NULL AS off_price_ind,
            prd_attr.gwp_flag            AS gwp_flag,
            prd_attr.isegc               AS is_egc,
            NULL AS morecolors,
            NULL AS preorder,
            url.eng_url                  AS product_url,
            CASE
                WHEN '&1' = 'o5' THEN
                    'https://image.s5a.com/is/image/saksoff5th/' || bm.product_id||'_300x400.jpg'
                ELSE
                    'https://image.s5a.com/is/image/saks/' || bm.product_id||'_300x400.jpg'
            END upc_url,
            NULL AS clearance_type,
            nvl(rfs.division_id, prd.division_id) AS division_id,
            rfs.division_name            AS division_name,
            asst.folder_path             AS assortment,
            asst.primary_category        AS label,
            prd.ven_styl_num             AS ven_styl_num,
            'T' AS is_readyforprod,
            prd_attr.is_reviewable       AS is_reviewable,
            prd_attr.is_shopthelook      AS is_shopthelook,
            prd_attr.pd_restrictedcountry_text AS country_restriction,
            prd_attr.item_gender         AS item_gender,
            NULL AS pip_text,
            CASE
                WHEN rfs.is_pickup_allowed = 'Y' THEN
                    'TRUE'
                ELSE
                    'FALSE'
            END AS pick_up_allowed_ind,
            NULL AS store_id,
            prd_attr.back_orderable      AS back_orderable,
            sysdate                      AS create_timestamp,
            NULL AS update_timestamp
        FROM
            &2.v_active_product_&1          bm
            LEFT JOIN (
                SELECT DISTINCT
                    prd.product_code,
                    prd.upc,
                    prd.class_id,
                    NULL AS class_name,
                    prd.department_id   AS department_id,
                    prd.group_id        AS group_id,
                    nvl(prd.sku_description, prd.item_description) sku_desc,
                    prd.division_id     AS division_id,
                    prd.vendor_id,
                    prd.ven_styl_num,
                    MAX(prd.item_cst_amt) OVER(
                        PARTITION BY prd.product_code
                        ORDER BY
                            prd.product_code
                    ) AS item_cst_amt,
                    prd.sku,
                    prd.item
--                    prd.modify_dt
                FROM
                    &2.bi_product prd
                    --AND ltrim(prd.group_id,'0') = ltrim(hi.group_id,'0')
                WHERE
                    prd.deactive_ind = 'N'
            ) prd ON bm.product_id = prd.product_code							       --Table is used to filter Active and readyforProd Products
            INNER JOIN &2.all_active_pim_prd_attr_&1   prd_attr ON prd_attr.product_id = bm.product_id              --PIM Product Attributes
            INNER JOIN &2.all_active_pim_sku_attr_&1   sku_attr ON sku_attr.upc = lpad(prd.upc, 13, '0')
                                                                 AND sku_status = 'Yes'                 --PIM SKU Attributes
            LEFT JOIN (
                SELECT
                    product_id,
                    CASE
                        WHEN primary_parent_category = 'ShoesBags'           THEN
                            'Shoes'
                            || ' & '
                               || 'Handbags'
                        WHEN primary_parent_category = 'Women'               THEN
                            'Womens Apparel'
                        WHEN primary_parent_category = 'Men'                 THEN
                            'Mens'
                        WHEN primary_parent_category = 'JewelryAccessories'  THEN
                            'Jewelry'
                            || ' & '
                               || 'Accessories'
                        ELSE
                            primary_parent_category
                    END primary_category,
                    folder_path,
                    primary_parent_category
                FROM
                    &2.all_actv_pim_assortment_&1
            ) asst ON bm.product_id = asst.product_id                       --PIM Product Assortments
            LEFT JOIN (
                SELECT DISTINCT
                    skn_no,
                    is_pickup_allowed,
                    lpad(r.department_id, 3, 0) department_id,
                    r.dept_name department_name,
                    substr(r.group_id, - 2) group_id,
                    substr(r.division_name, 1, 24) group_name,
                    substr(r.division_id, 1, 1) division_id,
                    substr(r.department_name, 1, 24) division_name
                FROM
                    &2.&4 r
            ) rfs ON rfs.skn_no = ltrim(prd.sku, '0')
            LEFT JOIN (
                SELECT
                    product_code,
                    'https://www.saksoff5th.com'||seo_url  eng_url
                FROM
                    &2.product_seo_url_mapping
            ) url ON bm.product_id = url.product_code;
COMMIT;
dbms_output.put_line('SQL OUTPUT :  '
                         || to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS')
                         || ' End Inserting &2.&3 :'
                         || ' '
                         || nvl((SQL%rowcount), 0)
                         || ' rows affected.');
COMMIT;
dbms_output.put_line('SQL OUTPUT :  '
                         || to_char(sysdate, 'MM-DD-YYYY HH:Mi:SS')
                         || ' Start Gathering all sizes and color in order to concatenate and load product aggregate table');
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' Loaded IMAGE_BAY_&2 table. '||' '||NVL((SQL%ROWCOUNT),0)||' rows affected.');
INSERT INTO &2.image_alt_&1
SELECT
             REGEXP_REPLACE(a.PRODUCT_CODE,'[^[:digit:]]','') product_code,
                                LISTAGG(
                                case when '&1' = 'o5'
                                then 'https://image.s5a.com/is/image/saksoff5th/'
                                else
                                'https://image.s5a.com/is/image/saks/'
                                end
                                || img.asset_id ||'_300x400.jpg',',') WITHIN GROUP(ORDER BY product_code) AS alt_image_url,
                                SYSDATE
                            FROM
                                &2.&4 a
                                JOIN &2.media_manifest img ON regexp_replace(substr(asset_id,0,instr(asset_id,'_') - 1),'[^0-9]+','') = a.upc
                            WHERE (img.asset_id LIKE '%_A1'  or img.asset_id LIKE '%_A2' or img.asset_id LIKE '%_A3' or img.asset_id LIKE '%_A4' or  img.asset_id LIKE '%_ASTL%' )
                              AND a.catalog_ind = 'Y'
                              AND a.upc = a.reorder_upc_no
                          GROUP BY a.product_code;
COMMIT;
DBMS_OUTPUT.PUT_LINE('SQL OUTPUT :  '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS')||' Loaded IMAGE_BAY_ALT table. '||' '||NVL((SQL%ROWCOUNT),0)||' rows affected.');
INSERT INTO &2.bi_product_aggregate
SELECT
agg.product_code,
agg.prod_sizes,
agg.prod_colors,
alt_image_url prod_alt_img_urls,
sysdate   AS create_timestamp,
sysdate   AS update_timestamp
FROM
(
with colr as
  (SELECT
      styl_seq_num product_code,
   LISTAGG(sku_color, ',') WITHIN GROUP(
     ORDER BY
          styl_seq_num
      ) AS prod_colors
      from (select distinct sku_color sku_color,styl_seq_num from &2.&3 ) a
         GROUP BY
      a.styl_seq_num) ,
      siz as  (SELECT
      styl_seq_num product_code,
   LISTAGG(sku_size1_desc, ',') WITHIN GROUP(
     ORDER BY
          styl_seq_num
      ) AS prod_sizes
      from (select distinct sku_size1_desc ,styl_seq_num from &2.&3 ) a
         GROUP BY
      a.styl_seq_num)

      select nvl(c.product_code,z.product_code) product_code, prod_colors,prod_sizes from colr c
      join siz z
      on c.product_code = z.product_code
      ) agg
      LEFT JOIN &2.image_alt_&1 img ON img.product_id = agg.product_code;
dbms_stats.gather_table_stats('&1', '&3', force => true);
-- Start Merging Prices for All SKU's into Partners
dbms_output.put_line('SQL OUTPUT :  '
                         || 'Merge prices for All SKUs Start : '
                         || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS'));
COMMIT;
MERGE INTO &2.&3 tg
    USING (
              SELECT
                  skn_no,
                  offer_price,
                  original_ticket,
                  current_ticket,
                  msrp,
                  sd_pip_text,
                  CASE
                      WHEN price_flag IN (
                          'M',
                          'C',
                          'F',
                          'P'
                      ) THEN
                          'C'
                      ELSE
                          NULL
                  END price_fg,
                  compare_at
              FROM
                  &2.v_sd_price_&1
--     WHERE skn_no = '1013931'
          )
    src ON ( src.skn_no = tg.sku )
    WHEN MATCHED THEN UPDATE
    SET tg.sku_sale_price = src.offer_price,
        tg.dutiable_price = src.offer_price,
        tg.sku_list_price = src.msrp,
        tg.pip_text = src.sd_pip_text,
        tg.clearance_type = src.price_fg,
        tg.compare_price = src.compare_at;
dbms_output.put_line('SQL OUTPUT :  '
                         || 'Merge prices for All SKUs Complete : '
                         || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS')
                         || SQL%rowcount);
COMMIT;
dbms_output.put_line('SQL OUTPUT :  '
                         || 'Merge Inventory for All SKUs Start : '
                         || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS'));
MERGE INTO &2.&3 tg
    USING (
              SELECT
                  skn_no                  skn,
                  in_stock_sellable_qty   qty
              FROM
                  &2.inventory src
          )
    sr ON ( tg.sku = sr.skn )
    WHEN MATCHED THEN UPDATE
    SET tg.wh_sellable_qty = sr.qty;
dbms_output.put_line('SQL OUTPUT :  '
                         || 'Merge Inventory for All SKUs Complete : '
                         || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS')
                         || SQL%rowcount);
COMMIT;
exception WHEN OTHERS THEN
        dbms_output.put_line('SQL OUTPUT :  '
                             || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS')
                             || ' Main PLSQL Block Failed!!');
        dbms_output.put_line('SQL OUTPUT :  ' || sqlerrm);
        RAISE;
END;
/
EXIT;
