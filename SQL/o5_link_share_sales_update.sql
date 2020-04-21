set serverout on 
set linesize 30 
set heading off
set timing on
merge INTO O5.LINK_SHARE_SALES_LANDING_STG l USING
(SELECT p.product_code upc,
  ss.ordernum,
  max(ss.orderdate) orderdate,
  min(ss.ORDLINE_STATUS) OL_STAT,
  SUM(ss.extend_price_amt) price,
  SUM(ss.qtyordered) qtyordered
from o5.LINK_SHARE_SALES_LANDING_STG LL
inner join o5.BI_PRODUCT P on LL.UPC = P.PRODUCT_CODE
INNER JOIN o5.bi_sale ss ON ll.order_line = to_char(ss.ordernum) AND p.upc        = ss.product_id
GROUP BY p.product_code,
  ss.ordernum
) s ON ( l.order_line = to_char(s.ordernum) AND l.upc = s.upc )
WHEN matched THEN
  UPDATE
  SET l.extend_price_amt = s.price,
    l.qtyordered         = s.qtyordered,
	l.OL_STATUS          = s.OL_STAT,
	l.db_orderdate       = s.orderdate
  where L.ORDER_LINE     = S.ORDERNUM
  AND l.upc              = s.upc;

commit;


delete from o5.LINK_SHARE_SALES_LANDING_STG where upc in 
( SELECT distinct p.product_code upc
from o5.LINK_SHARE_SALES_LANDING_STG LL
inner join o5.BI_PRODUCT P on LL.UPC = P.PRODUCT_CODE
where (p.product_code = '0499535450471' or p.item_description like '%EGC%' or p.sku_description like '%EGC%' ));
commit;

quit
