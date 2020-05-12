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

TRUNCATE TABLE o5.linkshare_tran_product_dtl;
--insert into mrep.linkshare_tran_product_dtl
--select product_code, sku_code, brandname, productshortdescription, listprice, saleprice, color, "size", us_stdsize FROM endeca_saks_custom.endeca_sku_extract@prodsto_mrep;
--COMMIT;

INSERT INTO o5.linkshare_tran_product_dtl (product_code,
										productshortdescription,
                                        brandname
                                        )
SELECT a.upc
           product_code,
       (SELECT attribute_val
          FROM pim_exp_bm.pim_ab_o5_prd_attr_data@PIM_READ
         WHERE     product_id = a.upc
               AND attribute_name IN ('ProductShortDescription'))
           ProductShortDescription,
       (SELECT CONVERT(attribute_val,  'US7ASCII', 'WE8ISO8859P1') as attribute_val
          FROM pim_exp_bm.pim_ab_o5_prd_attr_data@PIM_READ
         WHERE product_id = a.upc AND attribute_name IN ('BrandName'))
           BrandName
  FROM o5.link_share_sales_landing_stg a;
 COMMIT;

MERGE INTO o5.linkshare_tran_product_dtl trg
     USING (  SELECT item_id,
                     MAX (offer_price)         offer_price,
                     MAX (current_ticket)     current_ticket
                FROM edata_exchange.o5_sd_price
            GROUP BY item_id) src
        ON (trg.product_code = src.item_id)
WHEN MATCHED
THEN
    UPDATE SET
        trg.saleprice = src.offer_price, 
        trg.listprice = src.current_ticket;

COMMIT;

quit
