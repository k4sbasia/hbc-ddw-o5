set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE

DECLARE
BEGIN
    FOR r1 IN (
        WITH inv AS (
            SELECT
                TO_CHAR(rfs.UPC ) upc,
                i.in_stock_sellable_qty   wh_sellable_qty
            FROM
                &1.inventory i
            INNER JOIN &1.oms_rfs_o5_stg rfs ON i.SKN_NO = rfs.SKN_NO
        ),feed AS (
            SELECT
                c.upc,
                c.qty_on_hand
            FROM &1.channel_advisor_extract_new c
            WHERE c.variation_name = 'C'
        )
        SELECT
            p.wh_sellable_qty,
            p.upc
        FROM inv p,
            feed f
        WHERE f.upc = p.upc AND p.wh_sellable_qty <> f.qty_on_hand
    ) LOOP
        UPDATE &1.channel_advisor_extract_new
        SET qty_on_hand = r1.wh_sellable_qty
        WHERE upc = r1.upc;

        COMMIT;
    END LOOP;
END;
/

SELECT
    'id'
    || '~'
    || 'item_group_id'
    || '~'
    || 'availability'
    || '~'
    || 'condition'
    || '~'
    || 'description'
    || '~'
    || 'image_link'
    || '~'
    || 'link'
    || '~'
    || 'title'
    || '~'
    || 'price'
    || '~'
    || 'sale_price'
    || '~'
    || 'brand'
    || '~'
    || 'google_product_category'
    || '~'
    || 'gender'
    || '~'
    || 'margin'
	|| '~'
	|| 'pip_text'
FROM dual;

SELECT
    to_number(sku_number)
    || '~'
    || manufacturer_part#
    || '~'
    || CASE WHEN ( qty_on_hand > 0 AND qty_on_hand <> 3000 ) THEN 'in stock' WHEN qty_on_hand = 3000 THEN 'preorder' ELSE 'out of stock' END
    || '~'
    || 'new'
    || '~'
    || nvl(mrep.encd_to_char_conversion(substr(mrep.str_html(TRIM(regexp_replace(replace(replace(replace(mrep.char_conversion_new (short_product_desc),CHR(10),''),CHR(13),''),'',''),'~','') ) ),1,5000) ),'Saks OFF 5TH')
    || '~'
    || replace(replace(product_image_url,'https://image.s5a.com','https://s7d2.scene7.com'),'_300x400.jpg','?$960x1280$')
    || '~'
    || product_url
    || '~'
    || nvl(mrep.encd_to_char_conversion(substr(replace(product_name,'~',''),1,100) ),'Saks OFF 5TH')
    || '~'
    || retail_price
    || ' USD'
    || '~'
    || sale_price
    || ' USD'
    || '~'
    || mrep.encd_to_char_conversion(manufacturer_name)
    || '~'
    ||nvl(replace(replace(t5.folder_path,'/assortments/saksmain/shopcategory/',''),'/','>'),'Saks OFF 5TH')
    || '~'
    || CASE
        WHEN t1.itm_gender = '1' THEN 'unisex'
        WHEN t1.itm_gender = '2' THEN 'male'
        WHEN t1.itm_gender = '3' THEN 'female'
        WHEN t1.itm_gender = '4' THEN 'unisex'
        WHEN t1.itm_gender = '5' THEN 'unisex '
        WHEN t1.itm_gender = '6' THEN 'unisex'
        ELSE 'unisex'
    END
    || '~'
    || CASE WHEN nvl(t1.sale_price,0) = 0 OR nvl(t2.item_cst_amt,0) = 0 THEN 0 ELSE ROUND(((t1.sale_price - t2.item_cst_amt)/t1.sale_price),2) END
	|| '~'
	||offer_tag
FROM &1.channel_advisor_extract_new t1
JOIN (SELECT DISTINCT product_code, skn_no, upc, MAX(item_cst_amt) AS item_cst_amt
        FROM &1.oms_rfs_o5_stg t2
       GROUP BY product_code, skn_no, upc) t2 ON t1.manufacturer_part# = t2.product_code AND to_number(t1.sku_number) = t2.upc
LEFT JOIN (SELECT max(SD_PIP_TEXT) offer_tag,ITEM_ID as product_code from &1.v_sd_price_o5
where SD_PIP_TEXT is not null
group by ITEM_ID) t4 on t2.product_code = t4.product_code
LEFT JOIN (select product_id AS PRODUCT_CODE, max(lower(folder_path)) AS folder_path from &1.all_actv_pim_assortment_o5
            WHERE folderactive= 'T' and readyforprodfolder= 'T'
                and folder_path like ('/Assortments/SaksMain/ShopCategory%')
            GROUP BY product_id
            ) t5 ON t2.product_code = t5.product_code
WHERE EXISTS (SELECT 1 FROM &1.channel_advisor_extract_new t3 WHERE t3.qty_on_hand > 0 AND t3.variation_name = 'P' AND t1.manufacturer_part# = t3.manufacturer_part#)
AND t1.variation_name = 'C'
;

SHOW ERRORS

EXIT;
