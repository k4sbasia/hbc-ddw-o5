set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off

SELECT  'Parent_SKU'
       || chr(9)
       || 'Product_Id'
       || chr(9)
       || 'Product_Name'
       || chr(9)
       || 'Variation_Name'
       || chr(9)
       || 'SKU_Number'
       || chr(9)
       || 'Primary_And_Secondary_Category'
       || chr(9)
       || 'Product_URL'
       || chr(9)
       || 'Product_Image_URL'
       || chr(9)
       || 'Short_Product_Desc'
       || chr(9)
       || 'Long_Product_Desc'
       || chr(9)
       || 'Discount'
       || chr(9)
       || 'Discount_Type'
       || chr(9)
       || 'Sale_Price'
       || chr(9)
       || 'Retail_Price'
       || chr(9)
       || 'Begin_Date'
       || chr(9)
       || 'End_Date'
       || chr(9)
       || 'Brand'
       || chr(9)
       || 'Shipping'
       || chr(9)
       || 'Is_Delete_Flag'
       || chr(9)
       || 'Keywords'
       || chr(9)
       || 'Is_All_Flag'
       || chr(9)
       || 'Manufacturer_Name'
       || chr(9)
       || 'Shipping_Information'
       || chr(9)
       || 'Availablity'
       || chr(9)
       || 'Universal_Pricing_Code'
       || chr(9)
       || 'Class_ID'
       || chr(9)
       || 'Is_Product_Link_Flag'
       || chr(9)
       || 'Is_Storefront_Flag'
       || chr(9)
       || 'Is_Merchandiser_Flag'
       || chr(9)
       || 'Currency'
       || chr(9)
       || 'Path'
       || chr(9)
       || 'Group'
       || chr(9)
       || 'Category'
       || chr(9)
       || 'Size'
       || chr(9)
       || 'Color'
       || chr(9)
       || 'Larger_Images'
       || chr(9)
--       || 'Shipping'                                                  Removed duplicated header
--       || chr(9)                                                         Removed concatination
       || 'Qty_On_Hand'
       || chr(9)
       || 'AUD_Sale_Price'
       || chr(9)
       || 'GBP_Sale_Price'
       || chr(9)
       || 'CHF_Sale_price'
       || chr(9)
       || 'CAD_Sale_Price'
       || chr(9)
       || 'AU_Publish'
       || chr(9)
       || 'UK_Publish'
       || chr(9)
       || 'CH_Publish'
       || chr(9)
       || 'CA_Publish'
       || chr(9)
       || 'Order_Flag'
       || chr(9)
       || 'BM_Code'
       || chr(9)
       || 'Material'
       || chr(9)
       || 'All_Category_Path'
       || chr(9)
       || 'Department_id'
       || chr(9)
       || 'Clearance'
       || chr(9)
       || 'ITM_GENDER'
       || chr(9)
       || 'IN_STOCK'
	   || chr(9)
	   || 'Margin'
  FROM DUAL;

SELECT Manufacturer_part#
       || chr(9)
       || fcae.upc
       || chr(9)
       || Product_Name
       || chr(9)
       || Variation_Name
       || chr(9)
       || SKU_Number
       || chr(9)
       || Primary_Category || '|' || Secondary_Category
       || chr(9)
       || replace(product_url,'?site_refer=','')
       || chr(9)
       || Product_Image_URL
       || chr(9)
       || '"'||REPLACE(Short_Product_Desc,chr(9),'')||'"'
       || chr(9)
       || Long_Product_Desc
       || chr(9)
       || Discount
       || chr(9)
       || Discount_Type
       || chr(9)
       || Sale_Price
       || chr(9)
       || Retail_Price
       || chr(9)
       || Begin_Date
       || chr(9)
       || End_Date
       || chr(9)
       || Brand
       || chr(9)
       || Shipping
       || chr(9)
       || is_Delete_Flag
       || chr(9)
       || Keywords
       || chr(9)
       || Is_All_Flag
       || chr(9)
       || Manufacturer_Name
       || chr(9)
       || Shipping_Information
       || chr(9)
       || Availablity
       || chr(9)
       || Universal_Pricing_Code
       || chr(9)
       || Class_ID
       || chr(9)
       || Is_Product_Link_Flag
       || chr(9)
       || Is_Storefront_Flag
       || chr(9)
       || Is_Merchandiser_Flag
       || chr(9)
       || Currency
       || chr(9)
       || Path
       || chr(9)
       || Group_id
       || chr(9)
       || Categorys
       || chr(9)
       || replace(sizes,chr(10),'')
       || chr(9)
       || replace(Color,chr(10),'')
       || chr(9)
       || Larger_Images
       || chr(9)
--       || Shipping                                               Removed duplicated value
--       || chr(9)                                                    Removed concatination
       || Qty_On_Hand
       || chr(9)
       || ROUND (Sale_Price * MREP.F_CURRENCY_CALC ('AUD'),2)
       || chr(9)
       || ROUND (Sale_Price * MREP.F_CURRENCY_CALC ('GBP'),2)
       || chr(9)
       || ROUND (Sale_Price * MREP.F_CURRENCY_CALC ('CHF'),2)
       || chr(9)
       || ROUND (Sale_Price * MREP.F_CURRENCY_CALC ('CAD'),2)
        || chr(9)
       ||
         CASE WHEN
              MREP.getattrvalbyobject(bm_code,'pd_restrictedcountry_text',1) = 'ALLX' then 'N'
          ELSE
           CASE
             WHEN MREP.f_get_country_restrict_items (Manufacturer_part#,'AU') = 'Y' THEN 'N'
             ELSE 'Y'
           END
         END
       || chr(9)
       ||
        CASE WHEN
              MREP.getattrvalbyobject(bm_code,'pd_restrictedcountry_text',1) = 'ALLX' then 'N'
           ELSE
            CASE
              WHEN MREP.f_get_country_restrict_items (Manufacturer_part#,'UK') = 'Y' THEN 'N'
              ELSE 'Y'
            END
        END
       || chr(9)
       ||
        CASE WHEN
              MREP.getattrvalbyobject(bm_code,'pd_restrictedcountry_text',1) = 'ALLX' then 'N'
           ELSE
           CASE
             WHEN MREP.f_get_country_restrict_items (Manufacturer_part#,'CH') = 'Y' THEN 'N'
             ELSE 'Y'
           END
        END
       || chr(9)
       ||
       CASE WHEN
              MREP.getattrvalbyobject(bm_code,'pd_restrictedcountry_text',1) = 'ALLX' then 'Y'
           ELSE
           CASE
             WHEN MREP.f_get_country_restrict_items (Manufacturer_part#,'CA') = 'Y' THEN 'N'
             ELSE 'Y'
           END
       END
       || chr(9)
       || item_flag
       || chr(9)
       || BM_code
       || chr(9)
       ||replace(Material,chr(10),'')
       || chr(9)
       ||mrep.f_get_category_path_all (Manufacturer_part#)
       || chr(9)
       ||department_id
       || chr(9)
       || case when clearance_type = 'C' then 'Y' else 'N' end
       || chr(9)
       || DECODE(fcae.itm_gender, 1,'Not Applicable', 2,'Men', 3,'Women', 4,'Unisex', 5,'Kids' ,6,'Pets', NULL)
       || chr(9)
       || case when qty_on_hand = 0 then 'N' else 'Y' end
	   || chr(9)
	   ||  CASE WHEN nvl(fcae.sale_price,0) = 0 OR t2.item_cst_amt IS NULL THEN 0
	   	    WHEN round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2) < 0 THEN 0.01
	   	    ELSE round(((fcae.sale_price - t2.item_cst_amt) / fcae.sale_price),2)
	   	END
    from mrep.feed_channel_advisor_extract fcae
	JOIN (SELECT DISTINCT t2.product_code, t2.skn_no, t2.upc, MAX(t2.item_cst_amt) AS item_cst_amt
        FROM mrep.oms_rfs_saks_stg t2
       GROUP BY t2.product_code, t2.skn_no, t2.upc) t2 ON fcae.manufacturer_part# = t2.product_code AND to_number(fcae.sku_number) = t2.upc
    where to_number(fcae.Retail_Price) >= to_number(fcae.Sale_Price)        -- Added on 01/22/2015 Aleks Kaydanov
        AND upper(fcae.brand) not in ('MONCLER')  --Added as part of Salesfloor request 06/07/2017 Harsh Desai
    order by item_seq asc;

exit;
