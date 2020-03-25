SET ECHO ON
SET HEADING ON
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT 9
--Find Shipped Orders to Send it to Simon
BEGIN

INSERT INTO o5.stg_simon_order_data_ship
    (
        retailer,
        "Order Date",
        "Order Modified Date",
        "Saks OFF 5TH Order number",
        sku,
        quantity,
        "Order Status",
        "Unit Price",
        "Order Discount",
        "Line Item Total",
        "Order Product Total",
        "Order Total Shipping",
        "Order Total Tax",
        "Order Total",
        "Currency",
        "Shipping Option",
        "Shipping Tracking No.",
        "Product Category"
    )
WITH simon_order_data AS
(
SELECT
    'Saks OFF 5TH' AS c1,
    t1.order_date AS c2,
    t1.status_date AS c3,
    to_number(t1.order_no) AS c4,
    t1.upc AS c5,
    t1.status_quantity AS c6,
    CASE WHEN status = '3700' THEN 'Shipped'
         WHEN status = '9000' THEN 'Cancelled'
         WHEN status = '3700.02' THEN 'Returned' END AS c7,
    FIRST_VALUE(t2.unit_price) OVER ( PARTITION BY to_number(t2.order_no), t2.item_id   ORDER BY t2.modifyts DESC) AS c8,
    FIRST_VALUE(case when t2.invoiced_line_total = 0 then t2.LINE_TOTAL else t2.invoiced_line_total end ) OVER ( PARTITION BY to_number(t2.order_no), t2.item_id  ORDER BY t2.modifyts DESC) AS c9,
    FIRST_VALUE(case when t2.invoiced_extended_price = 0 then t2.LIST_PRICE else t2.invoiced_extended_price end ) OVER ( PARTITION BY to_number(t2.order_no), t2.item_id ORDER BY t2.modifyts DESC) AS c10,
    t2.charge_name AS c11,
    MAX(t2.chargeamount) OVER(PARTITION BY to_number(t2.order_no), t2.item_id, t2.charge_name ORDER BY t2.charge_name) AS c12,
    'USD' AS c13,
    t2.shipping_option AS c14,
    t2.tracking_number AS c15,
    RANK() OVER(PARTITION BY to_number(t1.order_no), t1.item_id ORDER BY t1.status_date DESC NULLS LAST, t1.status DESC) as f_order_trank
FROM o5.oms_o5_order_info t1
JOIN o5.oms_o5_order_charge_ship_info t2 ON t1.order_no = t2.order_no AND TRIM(t1.item_id) = TRIM(t2.item_id)
WHERE EXISTS (SELECT 1 FROM O5.stg_omniture_simon_ord_data src WHERE src.order_id = to_number(t1.order_no) AND src.sent_status in ('N','P'))
--AND TRIM(t1.status) = ('3700')
--AND TRIM(t1.status) IN ('3700', '3700.02', '9000')
--AND TRIM(t1.order_no) in ('007323316')
)
--select * from simon_order_data
,all_order_data as
(
select *
from (
    select distinct
         t1.c1
        ,t1.c2
        ,t1.c3
        ,t1.c4
        ,t1.c5
        ,t1.c6
        ,t1.c7
        ,t1.c8
        ,t1.c9
        ,t1.c10
        ,t1.c11
        ,t1.c12
        ,t1.c13
        ,t1.c14
        ,t1.c15
    from simon_order_data t1
   where f_order_trank = 1
    )
    pivot ( max(c12) for c11 in ( 'DISCOUNT' Discount, 'SHIPPINGCHARGE' Shippingcharge ))
)
--select t1.* from all_order_data t1 ORDER BY C4
,all_processed_data as (
select
     t1.c1 as RETAILER
    ,t1.c2 as "Order Date"
    ,t1.c3 as "Order Modified Date"
    ,t1.c4 as "Saks OFF 5TH Order number"
    ,t1.c5 as "SKU"
    ,t1.c6 as "QUANTITY"
    ,t1.c7 as "Order Status"
    ,t1.c8 as "Unit Price"
    ,nvl(t1.DISCOUNT,0) as "Order Discount"
    ,t1.c10 - nvl(t1.discount,0) as "Line Item Total"
    ,sum(t1.c10) over( partition by t1.c4 order by t1.c4) - sum(nvl(t1.discount,0)) over (partition by t1.c4 order by t1.c4) as "Order Product Total"
    ,sum(nvl(t1.shippingcharge,0)) over( partition by t1.c4 order by t1.c4) as "Order Total Shipping"
    ,sum(t1.c9) over( partition by t1.c4 order by t1.c4) - (sum(t1.c10) over( partition by t1.c4 order by t1.c4) - sum(nvl(t1.discount,0)) over (partition by t1.c4 order by t1.c4)) - sum(nvl(t1.shippingcharge,0)) over( partition by t1.c4 order by t1.c4) as "Order Total Tax" --47.03-35.97-7.99
    ,sum(t1.c9) over( partition by t1.c4 order by t1.c4) as "Order Total"
    ,t1.c13 as "Currency"
    ,t1.c14 as "Shipping Option"
    ,t1.c15 as "Shipping Tracking No."
    ,bm.prim_category   as "Product Category"
from all_order_data t1
LEFT JOIN
            (SELECT
                upc,
                to_char(TRIM(replace(regexp_substr(rel_path,'/[^/]+',2,3),'/',' '))) AS prim_category
            FROM
                (
                    SELECT DISTINCT
                        sku.sku_code_lower   AS upc,
                        rel_path AS rel_path
                    FROM
                        (SELECT PRODUCT_ID rel_nm_lower,FOLDER_PATH rel_path
                           FROM o5.all_actv_pim_assortment_o5
                          WHERE FOLDER_PATH LIKE '/Assortments/SaksMain/ShopCategory%' AND FOLDERACTIVE = 'T') rel
                        JOIN ( SELECT upc prd_code_lower,
                        		PRODUCT_CODE prd_id
             					 from o5.all_active_product_sku_o5) prd ON prd.prd_code_lower = rel.rel_nm_lower
                        JOIN (SELECT  PRODUCT_CODE sku_parent_id,
                        				SKN_NO sku_code_lower
                                FROM o5.all_active_product_sku_o5
                               ) sku ON sku_parent_id = prd.prd_id
                )
            ) bm ON bm.upc = to_number(t1.c5)
)
--SELECT * FROM all_processed_data t1 WHERE nvl(t1."Order Status",'X') = 'Shipped'
SELECT *
  FROM all_processed_data t1
 WHERE (nvl(t1."Order Status",'X') = 'Shipped' and exists (select 1
                                                            from o5.stg_omniture_simon_ord_data t2
                                                            where t2.order_id = t1."Saks OFF 5TH Order number"
                                                              and t2.sent_status = 'N')
        ) --To Handle New Orders where THERE IS NO partial Shipment
    OR (nvl(t1."Order Status",'X') = 'Shipped' and exists (select 1 from o5.stg_omniture_simon_ord_data t4 WHERE t4.order_id = t1."Saks OFF 5TH Order number" AND t4.sent_status = 'P')
                                               and not exists
                                                          (select t3."Saks OFF 5TH Order number" as shipped_order_id, t3.sku
                                                             from o5.stg_simon_order_data_ship t3
                                                            where t3."Saks OFF 5TH Order number" = t1."Saks OFF 5TH Order number"
                                                              and t3.sku = t1.sku)
       ) --To Handle New Orders where THERE IS partial Shipment
;

DBMS_OUTPUT.PUT_LINE('Number of Shipped Orders Found for Date :' || SYSDATE || ':' || sql%ROWCOUNT);
COMMIT;


--Process Returns
INSERT INTO o5.stg_simon_order_data_return
(
    retailer,
    "Order Date",
    "Order Modified Date",
    "Saks OFF 5TH Order number",
    sku,
    quantity,
    "Order Status",
    "Unit Price",
    "Order Discount",
    "Line Item Total",
    "Order Product Total",
    "Order Total Shipping",
    "Order Total Tax",
    "Order Total",
    "Currency",
    "Shipping Option",
    "Shipping Tracking No.",
    "Product Category"
)
    WITH all_return_eligible_orders AS (
        select distinct
            shp."Saks OFF 5TH Order number"   as ship_order_id,
            shp.sku                           as upc,
            shp.quantity,
            ret.sku as ret_sku,
            ret.quantity as ret_quantity,
            case when ret.sku is null then 1 else 0 end f_return_eligible --OR shp.quantity > nvl(ret.quantity,0)
        from o5.stg_simon_order_data_ship shp
        left join o5.stg_simon_order_data_return ret ON trim(shp."Saks OFF 5TH Order number") = trim(ret."Saks OFF 5TH Order number") AND trim(shp.sku) = trim(ret.sku) AND ret.order_complete_status = 1
        where trunc(shp."Order Date") >= trunc(sysdate - 90)
          and shp.add_date not in to_date('02-APR-19 09:33:48','DD-MON-YY HH:MI:SS')
    )
--    SELECT *  FROM o5.oms_o5_order_info t1  WHERE t1.order_no IN (SELECT SHIP_ORDER_ID FROM all_return_eligible_orders WHERE f_return_eligible = 1)
    ,simon_order_data AS (
        SELECT
            'Saks OFF 5TH' AS c1,
            t1.order_date        AS c2,
            t1.status_date       AS c3,
            to_number(t1.order_no) AS c4,
            t1.upc               AS c5,
            t1.status_quantity   AS c6,
            CASE
                WHEN status = '3700'    THEN 'Shipped'
                WHEN status = '9000'    THEN 'Cancelled'
                WHEN status = '3700.02' THEN 'Returned'
            END AS c7,
            FIRST_VALUE(t2.unit_price) OVER(PARTITION BY to_number(t2.order_no),t2.item_id ORDER BY t2.modifyts DESC) AS c8,
            FIRST_VALUE(t2.invoiced_line_total) OVER( PARTITION BY to_number(t2.order_no),t2.item_id ORDER BY t2.modifyts DESC) AS c9,
            FIRST_VALUE(t2.invoiced_extended_price) OVER(PARTITION BY to_number(t2.order_no),t2.item_id ORDER BY t2.modifyts DESC) AS c10,
            t2.charge_name       AS c11,
            MAX(t2.chargeamount) OVER(PARTITION BY to_number(t2.order_no),t2.item_id,t2.charge_name ORDER BY t2.charge_name) AS c12,
            'USD' AS c13,
            t2.shipping_option   AS c14,
            t2.tracking_number   AS c15
        FROM o5.oms_o5_order_info t1
        LEFT JOIN o5.oms_o5_order_charge_ship_info t2 ON t1.order_no = t2.order_no AND TRIM(t1.item_id) = TRIM(t2.item_id)
        WHERE EXISTS (SELECT 1 FROM all_return_eligible_orders src WHERE src.ship_order_id = to_number(t1.order_no) and src.f_return_eligible = 1 and src.upc = t1.upc)
          AND TRIM(t1.status) IN ('3700.02','9000')
    )
--select * from simon_order_data
   ,all_order_data AS (
        SELECT * FROM
            (
                SELECT DISTINCT
                    t1.c1,
                    t1.c2,
                    t1.c3,
                    t1.c4,
                    t1.c5,
                    t1.c6,
                    t1.c7,
                    t1.c8,
                    t1.c9,
                    t1.c10,
                    t1.c11,
                    t1.c12,
                    t1.c13,
                    t1.c14,
                    t1.c15
                FROM simon_order_data t1
            ) PIVOT (MAX ( c12 ) FOR c11 IN ( 'DISCOUNT' discount,'SHIPPINGCHARGE' shippingcharge ))
    )
--select t1.* from all_order_data t1 ORDER BY C4
   ,all_processed_data AS (
        SELECT
             t1.c1    AS retailer
            ,t1.c2    AS "Order Date"
            ,t1.c3    AS "Order Modified Date"
            ,t1.c4    AS "Saks OFF 5TH Order number"
            ,t1.c5    AS "SKU"
            ,t1.c6    AS "QUANTITY"
            ,t1.c7    AS "Order Status"
            ,t1.c8    AS "Unit Price"
            ,nvl(t1.discount,0) AS "Order Discount"
            ,t1.c10 - nvl(t1.discount,0) AS "Line Item Total"
            ,SUM(t1.c10) OVER(PARTITION BY t1.c4 ORDER BY t1.c4 ) - SUM(nvl(t1.discount,0)) OVER(PARTITION BY t1.c4 ORDER BY t1.c4) AS "Order Product Total"
            ,SUM(t1.shippingcharge) OVER(PARTITION BY t1.c4 ORDER BY t1.c4) AS "Order Total Shipping"
            ,SUM(t1.c9) OVER( PARTITION BY t1.c4 ORDER BY t1.c4) - ( SUM(t1.c10) OVER(PARTITION BY t1.c4 ORDER BY t1.c4 ) - SUM(nvl(t1.discount,0)) OVER(PARTITION BY t1.c4 ORDER BY t1.c4)) - SUM(t1.shippingcharge) OVER( PARTITION BY t1.c4 ORDER BY t1.c4) AS "Order Total Tax" --47.03-35.97-7.99
            ,SUM(t1.c9) OVER(PARTITION BY t1.c4 ORDER BY t1.c4 ) AS "Order Total"
            ,t1.c13   AS "Currency"
            ,t1.c14   AS "Shipping Option"
            ,t1.c15   AS "Shipping Tracking No.",
             NULL AS "Product Category"
        FROM all_order_data t1
--order by 4
    )
    SELECT
        retailer,
        "Order Date",
        "Order Modified Date",
        "Saks OFF 5TH Order number",
        sku,
        quantity,
        "Order Status",
        "Unit Price",
        "Order Discount",
        "Line Item Total",
        NULL "Order Product Total",
        NULL "Order Total Shipping",
        NULL "Order Total Tax",
        NULL "Order Total",
        "Currency",
        NULL "Shipping Option",
        NULL "Shipping Tracking No.",
        NULL "Product Category"
    FROM all_processed_data t1;

DBMS_OUTPUT.PUT_LINE('Number of Return Orders Found for Date :' || SYSDATE || ':' || sql%ROWCOUNT);
COMMIT;

END;
/
EXIT;