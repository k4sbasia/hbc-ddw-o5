SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 1000
SET PAGESIZE 0
SET HEADING OFF

-- select * from o5.bi_whqty_wrk;
TRUNCATE TABLE o5.bi_whqty_wrk;

INSERT INTO o5.bi_whqty_wrk (
    add_dt,
    modify_dt,
    po_cancel_date,
    po_detail_status_code,
    po_ship_date,
    po_status_code,
    upc,
    wh_backorder_qty,
    wh_po_date,
    wh_po_number,
    wh_sellable_qty
)
    SELECT
        trunc(sysdate) add_dt,
        trunc(sysdate) modify_dt,
        NULL po_cancel_date,
        NULL po_detail_status_code,
        NULL po_ship_date,
        NULL po_status_code,
        p.upc upc,
        0 wh_backorder_qty,
        i.wh_po_date,
        i.wh_po_number,
        CASE
            WHEN in_stock_sellable_qty >= in_store_qty THEN ( in_stock_sellable_qty - in_store_qty )
            ELSE in_stock_sellable_qty
        END
    FROM o5.inventory    i
    JOIN o5.bi_product   p ON p.sku = i.skn_no
   WHERE ( i.in_stock_sellable_qty > 0 );

COMMIT;

EXIT;