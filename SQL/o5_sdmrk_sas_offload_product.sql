whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
SELECT 	  'UPC' || ',' || 
          'SKU' || ',' || 
          'SKU_Description' || ',' || 
          'Item' || ',' || 
          'Item_Description' || ',' || 
          'Vendor_Style_Number' || ',' || 
          'Department_ID' || ',' || 
          'SKU_List_Price' || ',' || 
          'SKU_Sale_Price' || ',' || 
          'Item_list_Price' || ',' || 
          'Item_Cost' || ',' || 
          'SKU_Size' || ',' || 
          'SKU_Color_Code' || ',' || 
          'SKU_Color' || ',' || 
          'First_Receipt_Date' || ',' || 
          'Last_Receipt_Date' || ',' || 
          'Analysis_Code_1' || ',' || 
          'Warehouse_Sellable_Units' || ',' || 
          'Warehouse_Backorder_Units' || ',' || 
          'Active_Indicator' || ',' || 
          'Sell_Off_Indicator' || ',' || 
          'Dropship_Indicator' || ',' || 
          'GWP_Eligibility_Indicator' || ',' || 
          'Replenish_Indicator' || ',' || 
          'GWP_Flag' || ',' || 
          'Web_Item_Flag' || ',' || 
          'GROUP_ID' || ',' || 
          'Division_ID' || ',' || 
          'Vendor_ID' || ',' || 
          'price_status' || ',' || 
		  'brand_name' || ',' || 
	  	  'Prd_ID'||','||
		  'BM_Description'
     FROM dual;

SELECT 	  UPC || ',' || 
          SKU || ',' || 
          regexp_replace(replace(replace(SKU_Description, ',', ''),'?' ,''),'[[:cntrl:]]')  || ',' || 
          ITEM || ',' || 
          regexp_replace(replace(replace(Item_Description, ',', ''),'?' ,''), '[[:cntrl:]]') || ',' || 
          Vendor_Style_Number || ',' || 
          Department_ID || ',' || 
          SKU_List_Price || ',' || 
          SKU_Sale_Price || ',' || 
          Item_list_Price || ',' || 
          Item_Cost || ',' || 
          SKU_Size || ',' || 
          replace(SKU_Color_Code, ',', '' )  || ',' || 
          regexp_replace(replace(replace(replace(replace(replace(SKU_COLOR, ',', ' '),'?' ,''), 'Â', ''),'¿', ''),'',''), '[[:cntrl:]]')  || ',' || 
          First_Receipt_Date || ',' || 
          Last_Receipt_Date || ',' || 
          Analysis_Code_1 || ',' || 
          Warehouse_Sellable_Units || ',' || 
          Warehouse_Backorder_Units || ',' || 
          Active_Indicator || ',' || 
          Sell_Off_Indicator || ',' || 
          Dropship_Indicator || ',' || 
          GWP_Eligibility_Indicator || ',' || 
          Replenish_Indicator || ',' || 
          GWP_Flag || ',' || 
          Web_Item_Flag || ',' || 
          GROUP_ID || ',' || 
          Division_ID || ',' || 
          Vendor_ID || ',' || 
          price_status || ',' || 
		  regexp_replace(replace(replace(replace(replace(replace(brand_name, ',', ' '),'?' ,''), 'Â', ''),'¿', ''),'',''), '[[:cntrl:]]') 
		  prd_id||','||
		  replace(replace(replace(replace(replace(replace(bm_desc, ',', ' '),'?' ,''), 'Â', ''),'¿', ''),'',''),chr(26),'')	  
     FROM sdmrk.o5_product
;

exit
