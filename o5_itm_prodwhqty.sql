SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 1000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF

truncate table o5.Bi_Whqty_Wrk;

insert into o5.Bi_Whqty_Wrk ( ADD_DT,
MODIFY_DT,
PO_CANCEL_DATE,
PO_DETAIL_STATUS_CODE,
PO_SHIP_DATE,
PO_STATUS_CODE,
UPC,
WH_BACKORDER_QTY,
WH_PO_DATE,
WH_PO_NUMBER,
WH_SELLABLE_QTY  )
select trunc(sysdate) ADD_DT,
 trunc(sysdate)  MODIFY_DT,
null PO_CANCEL_DATE,
null PO_DETAIL_STATUS_CODE,
null PO_SHIP_DATE,
null PO_STATUS_CODE,
p.upc UPC,
0 WH_BACKORDER_QTY,
i.WH_PO_DATE,
i.WH_PO_NUMBER,
case when in_stock_sellable_qty >= in_store_qty then (in_stock_sellable_qty-in_store_qty)
else in_stock_sellable_qty end
From o5.inventory i,
o5.bi_product p
where
p.sku = i.SKN_NO 
and 
(i.in_stock_sellable_qty  > 0)
;

commit;

EXIT;
