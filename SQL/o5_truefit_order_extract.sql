SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
select '"orderdate"|"orderid"|"CUSTOMERID"|"PRODUCTID"|"PRODUCTTITLE"|"HIERARCHY"|"BRANDNAME"|"BRANDPRODUCTID"|"SKU"|"color"|"ORDER_STATUS"|"SHP_QUANTITY"|"RETURN_QUANTITY"|"RETURN_DATE"|"UNIT_PRICE"|"CURRENCY"|"SIZE"|"SIZE_SCALE"|"UILOCALE"|"GENDER"'
from dual;

WITH
tmp_all_agg_pim_asrrt
AS
(select product_id, LISTAGG(PATH_LABEL,',') WITHIn GROUP (ORDER BY PATH_LABEL) agg_path_label from O5.ALL_ACTV_PIM_ASSORTMENT_O5 group by product_id)
select '"'||to_char(ord.order_Date,'DD-MON-YYYY HH24:MI:SS')||'"|"'||ord.order_no||'"|"'||NVL(usa.usa_id,trim(ord.bill_to_customer_Uid))||'"|"'|| prt.product_code ||'"|"'||
prd_atr.BM_DESC ||'"|"'|| tp.agg_path_label ||'"|"'||
prd_atr.brand_name ||'"|"'|| prt.VENDOR_STYLE ||'"|"'|| ord.upc ||'"|"'|| sku_atr.SKU_COLOR  ||'"|"'||
DECODE(ord.status,'3700.02','Returned','Shipped') ||'"|"'|| ord.SHIPPED_QUANTITY ||'"|"'|| CASE WHEN ord.status ='3700.02' THEN NVL(ord.status_quantity,0) ELSE NULL END ||'"|"'|| CASE WHEN ord.status ='3700.02' THEN to_char(ord.status_date,'DD-MON-YYYY HH24:MI:SS')  ELSE NULL END ||'"|"'||
round(ord.line_total/  DECODE(ord.SHIPPED_QUANTITY,0,ord.status_quantity,ord.SHIPPED_QUANTITY) ,2) ||'"|"'||'USD' ||'"|"'|| sku_atr.SKU_SIZE_DESC ||'"|"'|| ' ' ||'"|"'|| 'en_US' ||'"|"'|| DECODE(prd_atr.ITEM_GENDER, 1,'Not Applicable', 2,'Men', 3,'Women', 4,'Unisex', 5,'Kids' ,6,'Pets', NULL) ||'"'
     from (select ord.order_Date,ord.order_no ,ord.upc ,ord.email_address, sum(ord.SHIPPED_QUANTITY) SHIPPED_QUANTITY,SUM(ord.line_total) line_total,SUM(status_quantity) status_quantity,ord.status, ord.status_date,ord.bill_to_customer_Uid from o5.oms_o5_order_info ord where --ord.ORDER_DATE > sysdate-90 and
      (ord.status >= '3700' and ord.status <>'9000') group by ord.order_Date,ord.order_no,ord.status,ord.upc ,ord.email_address, ord.status_date,bill_to_customer_Uid) ord, O5.user_account usa, o5.oms_rfs_o5_stg prt,
     o5.all_active_pim_prd_attr_o5 prd_atr, tmp_all_agg_pim_asrrt tp,o5.all_active_pim_sku_attr_o5 sku_atr --,tmp_bayorder_lng tl
     where
      upper(ord.email_address) = usa.usa_EMAIL(+)
     and ord.upc=prt.upc
     and prt.product_code=prd_atr.product_id(+)
     and tp.PRODUCT_ID(+)=prt.PRODUCT_CODE
     and lpad(prt.upc,13,0)=sku_atr.upc(+)
    -- and ord.order_no=tl.order_no
    and trunc(ord.status_date) >= trunc(sysdate-8);
EXIT;
