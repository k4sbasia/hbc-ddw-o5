SET ECHO ON
SET HEADING ON
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT 9

BEGIN
--need to check if we receive partial returns and cancels the whether all the data comes only for cancelled sku or entire order
MERGE INTO &1.stg_simon_order_data_return t1
USING
    (SELECT *
       FROM &1.stg_simon_order_data_return t2
      WHERE trunc(t2.add_date) = trunc(sysdate)
   ) t2 ON ( t1."Saks OFF 5TH Order number" = t2."Saks OFF 5TH Order number" AND t1.sku = t2.sku AND t1.add_date > t2.add_date)
WHEN MATCHED THEN UPDATE
SET
    t1.quantity = t2.quantity,
    t1."Unit Price" = t1."Unit Price",
    t1."Order Discount" = t1."Order Discount",
    t1."Line Item Total" = t1."Line Item Total"
;
DBMS_OUTPUT.PUT_LINE('Returns Merged for Date :' || SYSDATE || ':' || sql%ROWCOUNT);

--Delete Only Duplicate Order And Sku Records If We Have Partial Return Or Cancel Orders
DELETE &1.stg_simon_order_data_return t1
WHERE
    ROWID IN (
        SELECT rank_row
        FROM
            (
                SELECT
                    t2."Saks OFF 5TH Order number",
                    t2.sku,
                    t2.add_date,
                    RANK() OVER( PARTITION BY t2."Saks OFF 5TH Order number",t2.sku ORDER BY t2.add_date) AS order_add_rk,
                    ROWID AS rank_row
                FROM &1.stg_simon_order_data_return t2
            ) t2
        WHERE t2.order_add_rk = 2
    );
DBMS_OUTPUT.PUT_LINE('Partial Retruns and Cancels Deleted :' || SYSDATE || ':' || sql%ROWCOUNT);

COMMIT;


UPDATE &1.stg_simon_order_data_return ret
   SET ret.order_complete_status = 1
 WHERE ret.order_complete_status = 0
   AND EXISTS (SELECT 1
                 FROM &1.stg_simon_order_data_ship shp
                WHERE TRIM(shp."Saks OFF 5TH Order number") = TRIM(ret."Saks OFF 5TH Order number")
                  AND TRIM(shp.sku) = TRIM(ret.sku)
                  AND ret.quantity = shp.quantity
                  AND TRUNC(shp."Order Date") >= TRUNC(sysdate - 90)
                  AND shp.add_date NOT IN TO_DATE('02-APR-19 09:33:48','DD-MON-YY HH:MI:SS'))
;

DBMS_OUTPUT.PUT_LINE('Returns Marked Complete :' || SYSDATE || ':' || sql%ROWCOUNT);


UPDATE &1.stg_omniture_simon_ord_data t1
   SET sent_status = 'P'
 WHERE sent_status = 'N'
   AND t1.order_id IN
                    (
                    WITH total_shipped_sku_in_order AS (
                         SELECT "Saks OFF 5TH Order number"   AS order_id, COUNT(DISTINCT sku) AS total_shipped_sku
                           FROM &1.stg_simon_order_data_ship t2
                          WHERE trunc(t2.add_date) = trunc(SYSDATE)
                          GROUP BY t2."Saks OFF 5TH Order number"
                     ),total_sku_in_order AS (
                         SELECT t1.order_no, COUNT(DISTINCT t1.upc) AS total_sku_in_order
                           FROM &1.oms_o5_order_info t1
                          WHERE EXISTS (SELECT 1 FROM total_shipped_sku_in_order t2 WHERE t1.order_no = t2.order_id)
                         GROUP BY t1.order_no
                     )
                     SELECT t1.order_id
                       FROM total_shipped_sku_in_order t1
                      WHERE EXISTS ( SELECT 1 FROM total_sku_in_order t2 WHERE t1.order_id = t2.order_no AND t1.total_shipped_sku < t2.total_sku_in_order)
);
DBMS_OUTPUT.PUT_LINE('Partial Order Found :' || SYSDATE || ':' || sql%ROWCOUNT);
COMMIT;

UPDATE &1.stg_omniture_simon_ord_data t1
   SET sent_status = 'Y'
 WHERE sent_status = 'P'
   AND t1.order_id IN
                    (
                    WITH total_shipped_sku_in_order AS (
                         SELECT "Saks OFF 5TH Order number"   AS order_id, COUNT(DISTINCT sku) AS total_shipped_sku
                           FROM &1.stg_simon_order_data_ship t2
                          WHERE t2."Saks OFF 5TH Order number" IN (select t5.order_id from &1.stg_omniture_simon_ord_data t5 where t5.sent_status = 'P')
                          GROUP BY t2."Saks OFF 5TH Order number"
                     ),total_sku_in_order AS (
                         SELECT t1.order_no, COUNT(DISTINCT t1.upc) AS total_sku_in_order
                           FROM &1.oms_o5_order_info t1
                          WHERE EXISTS (SELECT 1 FROM total_shipped_sku_in_order t2 WHERE t1.order_no = t2.order_id)
                         GROUP BY t1.order_no
                     )
                     SELECT t1.order_id
                       FROM total_shipped_sku_in_order t1
                      WHERE EXISTS ( SELECT 1 FROM total_sku_in_order t2 WHERE t1.order_id = t2.order_no AND t1.total_shipped_sku = t2.total_sku_in_order)
);

DBMS_OUTPUT.PUT_LINE('Partial Order Completed :' || SYSDATE || ':' || sql%ROWCOUNT);
COMMIT;


UPDATE &1.stg_omniture_simon_ord_data t1
   SET sent_status = 'Y'
 WHERE sent_status = 'N'
   AND EXISTS (SELECT 1
                 FROM &1.stg_simon_order_data_ship t2
                WHERE t2."Saks OFF 5TH Order number" = t1.order_id);
DBMS_OUTPUT.PUT_LINE('Orders Marked Processed for Date :' || SYSDATE || ':' || sql%ROWCOUNT);
COMMIT;

END;
/
EXIT;