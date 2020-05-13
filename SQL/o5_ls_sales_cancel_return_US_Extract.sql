set linesize 1000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on

INSERT  --append
      INTO  O5.ls_sales_cancel_return (ORDERNUM,
                                         orderseq,
                                         SITE_ID,
                                         ORDERDATE,
                                         ORDLINE_MODIFYDATE,
                                         SKU,
                                         ITEM_ID,
                                         QUANTITY,
                                         AMOUNT,
                                         CURRENCY,
                                         MID,
										 product_name)
   SELECT /*+ use_hash(bs,bp,ls) parallel(bs,2) leading(bs) */
         ordernum,
          orderseq,
          NULL,
          bs.orderdate,
          ordline_modifydate,
          bp.SKU,
          bp.PRODUCT_CODE,
          qtyordered,
          EXTEND_PRICE_AMT,
          'USD',
          MID,
          (
        SELECT
            MAX(prd.product_name) AS product_name
        FROM o5.feed_channel_advisor_extract prd
        where prd.manufacturer_part# = BP.product_code
    ) product_name
     FROM O5.bi_sale bs,
          O5.BI_PRODUCT BP,
          (SELECT DISTINCT order_line, upc,mid FROM o5.LINK_SHARE_SALES_HIST) ls
    WHERE     bs.bm_skuid = bp.bm_skuid
          and BS.ORDERNUM = LS.ORDER_LINE
          AND bp.product_code = ls.upc
          AND TRUNC (bs.orderdate) >= TRUNC (SYSDATE) - 90
          AND TRUNC (ordline_modifydate) - TRUNC (bs.orderdate) <= 90
          and ORDLINE_STATUS in ('X', 'R')
          and ls.mid = 38801
          AND NOT EXISTS
                     (SELECT 'X'
                        FROM o5.ls_sales_cancel_return ls
                       WHERE bs.ordernum = ls.ordernum
                             and BS.ORDERSEQ = LS.ORDERSEQ);
commit;

SELECT    'ORDERID'
       || CHR (9)
       || 'SITEID'
       || CHR (9)
       || 'TIME_ENTERED'
       || CHR (9)
       || 'TIME_COMPLETED'
       || CHR (9)
       || 'SKU'
       || CHR (9)
       || 'QUANTITY'
       || CHR (9)
       || 'AMOUNT'
       || CHR (9)
       || 'CURRENCY'
FROM DUAL;
SELECT    ordernum
       || CHR (9)
       || NULL
       || CHR (9)
       || TO_CHAR (orderdate, 'YYYY-MM-DD/hh:mm:ss')
       || CHR (9)
       || TO_CHAR (orderdate, 'YYYY-MM-DD/hh:mm:ss')
       || CHR (9)
       || ITEM_ID
       || CHR (9)
       || QUANTITY
       || CHR (9)
       || AMOUNT
       || CHR (9)
       || CURRENCY
  FROM (  SELECT ordernum,
                 MAX (orderdate) orderdate,
                 MAX (ordline_modifydate) ordline_modifydate,
                 ITEM_ID,
                 SUM (quantity) AS quantity,
                 SUM (amount*(-100)) AS amount,
                 currency
            FROM o5.ls_sales_cancel_return
           WHERE TRUNC (add_dt) = TRUNC (SYSDATE)
           and mid = 38801
        GROUP BY ordernum, ITEM_ID, currency);
quit;
