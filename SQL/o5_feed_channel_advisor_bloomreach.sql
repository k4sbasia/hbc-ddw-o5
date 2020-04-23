set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off

SELECT  'Parent_SKU'
       || '~'
       || 'Product_Id'
       || '~'
       || 'Product_Name'
       || '~'
       || 'Variation_Name'
       || '~'
       || 'SKU_Number'
       || '~'
       || 'Primary_And_Secondary_Category'
       || '~'
       || 'Product_URL'
       || '~'
       || 'Product_Image_URL'
       || '~'
       || 'Short_Product_Desc'
       || '~'
       || 'Long_Product_Desc'
       || '~'
       || 'Discount'
       || '~'
       || 'Discount_Type'
       || '~'
       || 'Sale_Price'
       || '~'
       || 'Retail_Price'
       || '~'
       || 'Begin_Date'
       || '~'
       || 'End_Date'
       || '~'
       || 'Brand'
       || '~'
       || 'Shipping'
       || '~'
       || 'Is_Delete_Flag'
       || '~'
       || 'Keywords'
       || '~'
       || 'Is_All_Flag'
       || '~'
       || 'Manufacturer_Name'
       || '~'
       || 'Shipping_Information'
       || '~'
       || 'Availablity'
       || '~'
       || 'Universal_Pricing_Code'
       || '~'
       || 'Class_ID'
       || '~'
       || 'Is_Product_Link_Flag'
       || '~'
       || 'Is_Storefront_Flag'
       || '~'
       || 'Is_Merchandiser_Flag'
       || '~'
       || 'Currency'
       || '~'
       || 'Path'
       || '~'
       || 'Group'
       || '~'
       || 'Category'
       || '~'
       || 'Size'
       || '~'
       || 'Color'
       || '~'
       || 'Larger_Images'
       || '~'
--       || 'Shipping'                                                  Removed duplicated header
--       || '~'                                                         Removed concatination
       || 'Qty_On_Hand'
       || '~'
       || 'AUD_Sale_Price'
       || '~'
       || 'GBP_Sale_Price'
       || '~'
       || 'CHF_Sale_price'
       || '~'
       || 'CAD_Sale_Price'
       || '~'
       || 'AU_Publish'
       || '~'
       || 'UK_Publish'
       || '~'
       || 'CH_Publish'
       || '~'
       || 'CA_Publish'
       || '~'
       || 'Order_Flag'
       || '~'
       || 'BM_Code'
       || '~'
       || 'Material'
       || '~'
       || 'All_Category_Path'
       || '~'
       || 'Department_id'
       || '~'
       || 'Clearance'
       || '~'
       || 'ITM_GENDER'
       || '~'
       || 'IN_STOCK'
	   || '~'
	   || 'Margin'
  FROM DUAL;
SELECT Manufacturer_part#
       || '~'
       || fcae.upc
       || '~'
       || Product_Name
       || '~'
       || Variation_Name
       || '~'
       || SKU_Number
       || '~'
       || Primary_Category || '|' || Secondary_Category
       || '~'
       || replace(product_url,'?site_refer=','')
       || '~'
       || Product_Image_URL
       || '~'
       || REPLACE(Short_Product_Desc,'~','')
       || '~'
       || REPLACE(Long_Product_Desc,'~','')
       || '~'
       || Discount
       || '~'
       || Discount_Type
       || '~'
       || to_char(Sale_Price,'fm999999.00')
       || '~'
       || to_char(Retail_Price,'fm999999.00')
       || '~'
       || Begin_Date
       || '~'
       || End_Date
       || '~'
       || Brand
       || '~'
       || Shipping
       || '~'
       || is_Delete_Flag
       || '~'
       || Keywords
       || '~'
       || Is_All_Flag
       || '~'
       || Manufacturer_Name
       || '~'
       || Shipping_Information
       || '~'
       || Availablity
       || '~'
       || Universal_Pricing_Code
       || '~'
       || Class_ID
       || '~'
       || Is_Product_Link_Flag
       || '~'
       || Is_Storefront_Flag
       || '~'
       || Is_Merchandiser_Flag
       || '~'
       || Currency
       || '~'
       || Path
       || '~'
       || Group_id
       || '~'
       || Categorys
       || '~'
       || replace(replace(sizes,chr(10),''),'~','')
       || '~'
       || replace(replace(Color,chr(10),''),'~','')
       || '~'
       || Larger_Images
       || '~'
--       || Shipping                                               Removed duplicated value
--       || '~'                                                    Removed concatination
       || Qty_On_Hand
       || '~'
       || AUD
       || '~'
       || GBP
       || '~'
       || CHF
       || '~'
       || CAD
        || '~'
       ||AU_PUBLISH
       || '~'
       ||UK_PUBLISH
       || '~'
       ||CH_PUBLISH
       || '~'
       ||CA_PUBLISH
       || '~'
       || item_flag
       || '~'
       || BM_code
       || '~'
       ||replace(replace(Material,chr(10)),'~')
       || '~'
       ||o5.f_get_category_path_all_sfcc (Manufacturer_part#)
       || '~'
       ||department_id
       || '~'
       ||CLEARANCE_TYPE
       || '~'
       ||ITM_GENDER
       || '~'
       || case when qty_on_hand = 0 then 'N' else 'Y' end
	   || '~'
	   || CASE WHEN (nvl(fcae.sale_price,0) = 0 OR t2.item_cst_amt IS NULL) THEN 0
          WHEN round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2) < 0 THEN 0.01
          ELSE round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2)
      END
    from O5.CHANNEL_ADVISOR_EXTRACT_NEW fcae
	JOIN (SELECT DISTINCT product_code, skn_no, upc, MAX(item_cst_amt) AS item_cst_amt
        FROM o5.oms_rfs_o5_stg t2
       GROUP BY product_code, skn_no, upc) t2 ON fcae.manufacturer_part# = t2.product_code AND to_number(fcae.sku_number) = t2.upc
and to_number(fcae.Retail_Price) >= to_number(fcae.Sale_Price)
        and fcae.qty_on_hand > 0
   ;

exit
