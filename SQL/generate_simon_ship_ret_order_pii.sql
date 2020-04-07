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
SELECT
        '"'
     || 'RETAILER'
     || '","'
     || 'Order Date'
     || '","'
     || 'Saks OFF 5TH Order number'
     || '","'
     || 'Customer Name'
     || '","'
     || 'Customer Email Address'
     || '","'
     || 'Shipping Address'
     || '","'
     || 'Customer Billing Address'
     || '","'
     || 'Customer Phone Number'
     || '"'
 FROM dual;
SELECT DISTINCT
     '"' ||
     'Saks OFF 5TH'                         || '","' ||
     "Order Date"                           || '","' ||
     "Saks OFF 5TH Order number"            || '","' ||
     t2.first_name || ',' || t2.last_name   || '","' ||
     t2.email_address                       || '","' ||
     t2.shipping_address                    || '","' ||
     t2.billing_address                     || '","' ||
     substr(t2.phone,1,3) || '-' || substr(t2.phone,4,3) || '-' || substr(t2.phone,7) || '"'
 FROM &1.stg_simon_order_data_ship t1
 JOIN &1.oms_o5_order_charge_ship_info t2 ON t1."Saks OFF 5TH Order number" = t2.order_no
WHERE trunc(t1.add_date) >= trunc(SYSDATE)
  AND substr(t2.shipping_address,-13,10) LIKE '%US%'
  AND substr(t2.billing_address,-13,10) LIKE '%US%'
;
EXIT;