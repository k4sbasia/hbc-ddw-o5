set linesize 32767
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
set verify off

--generate the shippiung file
--spool file for shipping
SELECT '"RETAILER"'
     || ',' || '"Order Date"'
     || ',' || '"Order Modified Date"'
     || ',' || '"Saks OFF 5TH Order number"'
     || ',' || '"SKU"'
     || ',' || '"QUANTITY"'
     || ',' || '"Order Status"'
     || ',' || '"Unit Price"'
     || ',' || '"Order Discount"'
     || ',' || '"Line Item Total"'
     || ',' || '"Order Product Total"'
     || ',' || '"Order Total Shipping"'
     || ',' || '"Order Total Tax"'
     || ',' || '"Order Total"'
     || ',' || '"Currency"'
     || ',' || '"Shipping Option"'
     || ',' || '"Shipping Tracking No."'
     || ',' || '"Product Category"'
 FROM dual;

SELECT
     '"'
     || retailer
     || '","'
     || "Order Date"
     || '","'
     || "Order Modified Date"
     || '","'
     || "Saks OFF 5TH Order number"
     || '","'
     || sku
     || '","'
     || quantity
     || '","'
     || "Order Status"
     || '","'
     || "Unit Price"
     || '","'
     || "Order Discount"
     || '","'
     || "Line Item Total"
     || '","'
     || "Order Product Total"
     || '","'
     || "Order Total Shipping"
     || '","'
     || "Order Total Tax"
     || '","'
     || "Order Total"
     || '","'
     || "Currency"
     || '","'
     || CASE
         WHEN "Order Total Shipping" = '0'     THEN 'Free Shipping'
         WHEN "Order Total Shipping" = '7.99'  THEN 'Standard Delivery'
         WHEN "Order Total Shipping" = '14.99' THEN 'Rush Delivery'
         WHEN "Order Total Shipping" = '24.99' THEN 'Next Business Day Delivery'
         WHEN "Order Total Shipping" = '34.99' THEN 'Saturday Delivery'
         ELSE "Shipping Option"
     END
     || '","'
     || "Shipping Tracking No."
     || '","'
     || "Product Category"
     || '"'
 FROM &1.stg_simon_order_data_ship
WHERE trunc(add_date) = trunc(SYSDATE)
--where add_date in ('02-APR-19 09:33:54','05-APR-19 12:43:28')
 UNION
SELECT
    '"'
    || retailer
    || '","'
    || "Order Date"
    || '","'
    || "Order Modified Date"
    || '","'
    || "Saks OFF 5TH Order number"
    || '","'
    || sku
    || '","'
    || quantity
    || '","'
    || "Order Status"
    || '","'
    || CASE WHEN TO_CHAR("Unit Price") = '0' THEN '0' ELSE '-' || TO_CHAR("Unit Price") END
    || '","'
    || CASE WHEN TO_CHAR("Order Discount") = '0' THEN '0' ELSE '-' || TO_CHAR("Order Discount") END
    || '","'
    || CASE WHEN TO_CHAR("Line Item Total") = '0' THEN '0' ELSE '-' || TO_CHAR("Line Item Total") END
    || '","'
    || "Order Product Total"
    || '","'
    || "Order Total Shipping"
    || '","'
    || "Order Total Tax"
    || '","'
    || "Order Total"
    || '","'
    || "Currency"
    || '","'
    || "Shipping Option"
    || '","'
    || "Shipping Tracking No."
    || '","'
    || "Product Category"
    || '"'
FROM &1.stg_simon_order_data_return
WHERE trunc(add_date) = trunc(SYSDATE);

EXIT;