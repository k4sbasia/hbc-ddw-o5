--Run this process after 1st of every mmonth to fetch Previous months order Data
SET LINESIZE 32767
SET HEADING OFF
SET ECHO OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET TRIMSPOOL ON
SET SERVEROUT ON
SET VERIFY OFF

DECLARE
    v_first_day_of_mnth            DATE;
    v_month_for_billing            DATE;
    v_first_day_of_billing_cycle   DATE;
    v_last_day_of_billing_cycle    DATE;
    
CURSOR C_SHIPPED_DATA IS
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
     || '"' as order_s_data
FROM &1.stg_simon_order_data_ship
WHERE trunc(add_date) BETWEEN v_first_day_of_billing_cycle AND V_last_day_of_billing_cycle
order by add_date
;
CURSOR C_RETURN_DATA
IS
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
    || '"' as order_r_data
FROM &1.stg_simon_order_data_return
WHERE trunc(add_date) BETWEEN v_first_day_of_billing_cycle AND V_last_day_of_billing_cycle
;


l_r_data C_RETURN_DATA%ROWTYPE;
l_s_data C_SHIPPED_DATA%ROWTYPE;

BEGIN
    v_first_day_of_mnth := trunc(SYSDATE, 'MONTH');
    v_month_for_billing := add_months(v_first_day_of_mnth, - 2);
    SELECT
        v_month_for_billing +25 AS first_day_of_billing_cycle,
        add_months(v_month_for_billing + 24, 1)
    INTO
        v_first_day_of_billing_cycle,
        v_last_day_of_billing_cycle
    FROM dual;

--dbms_output.put_line('v_first_day_of_billing_cycle : ' || v_first_day_of_billing_cycle);
--dbms_output.put_line('V_last_day_of_billing_cycle : ' || V_last_day_of_billing_cycle);

--Generate the Header for Monthly File
    dbms_output.put_line(
               '"RETAILER"'
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
     || ',' || '"Product Category"');

--Gather all the Shipped and Return Transactions

    OPEN c_shipped_data;

    LOOP
        FETCH c_shipped_data INTO l_s_data;
        EXIT WHEN c_shipped_data%notfound;
        dbms_output.put_line(l_s_data.order_s_data);
        EXIT WHEN c_shipped_data%notfound;
    END LOOP;
    
    CLOSE c_shipped_data;
    
    OPEN c_return_data;

    LOOP
        FETCH c_return_data INTO l_r_data;
        EXIT WHEN c_return_data%notfound;
        dbms_output.put_line(l_r_data.order_r_data);
        
        EXIT WHEN c_return_data%notfound;
    END LOOP;
    
    CLOSE C_RETURN_DATA;

END;
/
EXIT;