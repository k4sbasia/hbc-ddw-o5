whenever sqlerror exit failure
set linesize 32767
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
set verify off
SET TERMOUT OFF
SPOOL &2

SELECT
    'Parent_SKU'
    || '|'
    || 'Product_Id'
    || '|'
    || 'Product_Name'
    || '|'
    || 'Variation_Name'
    || '|'
    || 'SKU_Number'
    || '|'
    || 'Primary_Category'
    || '|'
    || 'Secondary_Category'
    || '|'
    || 'Product_URL'
    || '|'
    || 'Product_Image_URL'
    || '|'
    || 'Short_Product_Desc'
    || '|'
    || 'Long_Product_Desc'
    || '|'
    || 'Discount'
    || '|'
    || 'Discount_Type'
    || '|'
    || 'Sale_Price'
    || '|'
    || 'Retail_Price'
    || '|'
    || 'Begin_Date'
    || '|'
    || 'End_Date'
    || '|'
    || 'Brand'
    || '|'
    || 'Shipping'
    || '|'
    || 'Is_Delete_Flag'
    || '|'
    || 'Keywords'
    || '|'
    || 'Is_All_Flag'
    || '|'
    || 'Manufacturer_Name'
    || '|'
    || 'Shipping_Information'
    || '|'
    || 'Availablity'
    || '|'
    || 'Universal_Pricing_Code'
    || '|'
    || 'Class_ID'
    || '|'
    || 'Is_Product_Link_Flag'
    || '|'
    || 'Is_Storefront_Flag'
    || '|'
    || 'Is_Merchandiser_Flag'
    || '|'
    || 'Currency'
    || '|'
    || 'Path'
    || '|'
    || 'Group'
    || '|'
    || 'Category'
    || '|'
    || 'Size'
    || '|'
    || 'Color'
    || '|'
    || 'Larger_Images'
    || '|'
    || 'Qty_On_Hand'
    || '|'
    || 'AUD_Sale_Price'
    || '|'
    || 'GBP_Sale_Price'
    || '|'
    || 'CHF_Sale_price'
    || '|'
    || 'CAD_Sale_Price'
    || '|'
    || 'AU_Publish'
    || '|'
    || 'UK_Publish'
    || '|'
    || 'CH_Publish'
    || '|'
    || 'CA_Publish'
    || '|'
    || 'Order_Flag'
    || '|'
    || 'BM_Code'
    || '|'
    || 'Material'
    || '|'
    || 'Full_Category_Path'
    || '|'
    || 'Prd_Alt_Image_urls'
    || '|'
    || 'Department_id'
    || '|'
    || 'Clearance'
    || '|'
    || 'Gender'
    || '|'
    || 'Margin'
FROM dual;

SELECT fcae.manufacturer_part#
    || '|'
    || fcae.upc
    || '|'
    || product_name
    || '|'
    || variation_name
    || '|'
    || sku_number
    || '|'
    || primary_category
    || '|'
    || secondary_category
    || '|'
    || product_url
    || '|'
    || product_image_url
    || '|'
    || short_product_desc
    || '|'
    || long_product_desc
    || '|'
    || discount
    || '|'
    || discount_type
    || '|'
    || fcae.sale_price
    || '|'
    || fcae.retail_price
    || '|'
    || begin_date
    || '|'
    || end_date
    || '|'
    || brand
    || '|'
    || shipping
    || '|'
    || is_delete_flag
    || '|'
    || keywords
    || '|'
    || is_all_flag
    || '|'
    || manufacturer_name
    || '|'
    || shipping_information
    || '|'
    || availablity
    || '|'
    || universal_pricing_code
    || '|'
    || class_id
    || '|'
    || is_product_link_flag
    || '|'
    || is_storefront_flag
    || '|'
    || is_merchandiser_flag
    || '|'
    || currency
    || '|'
    || path
    || '|'
    || group_id
    || '|'
    || categorys
    || '|'
    || replace(sizes,CHR(10),'')
    || '|'
    || replace(color,CHR(10),'')
    || '|'
    || larger_images
    || '|'
    || qty_on_hand
    || '|'
    || aud
    || '|'
    || gbp
    || '|'
    || chf
    || '|'
    || cad
    || '|'
    || au_publish
    || '|'
    || uk_publish
    || '|'
    || ch_publish
    || '|'
    || ca_publish
    || '|'
    || item_flag
    || '|'
    || bm_code
    || '|'
    || ''
    || '|'
    || CASE WHEN variation_name = 'P' THEN CASE WHEN path IS NULL THEN upper(categorys) ELSE upper(path) END ELSE NULL END
    || '|'
    || alt_image_url
    || '|'
    || department_id
    || '|'
    || CASE WHEN clearance_type = 'C' THEN 'Y' ELSE 'N' END
    || '|'
    || case when itm_gender = 1 then 'Not Applicable'
        when  itm_gender = 2 then 'Men'
        when  itm_gender = 3 then 'Women'
        when  itm_gender = 4 then 'Unisex'
        when  itm_gender = 5 then 'Kids'
        when  itm_gender = 6 then 'Pets'
        else itm_gender
        end
    || '|'
    || CASE WHEN nvl(fcae.sale_price,0) = 0 OR t2.item_cst_amt IS NULL THEN 0
            WHEN round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2) < 0 THEN 0.01
            ELSE round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2)
        END
FROM
    o5.channel_advisor_extract_new fcae
    JOIN (SELECT DISTINCT t2.product_code, t2.skn_no, t2.upc, MAX(t2.item_cst_amt) AS item_cst_amt
            FROM o5.oms_rfs_o5_stg t2
           GROUP BY t2.product_code, t2.skn_no, t2.upc) t2 ON fcae.manufacturer_part# = t2.product_code AND to_number(fcae.sku_number) = t2.upc;

SPOOL OFF;

EXIT;
