REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  link_share_sales
REM  DESCRIPTION:  Extract Tab delimited LS Transaction
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                David Alexander              10/04/2010        Created
REM                David Alexander             10/18/2010      Added tracking_code substr
REM                Rajesh Mathew			   05/23/2011      Modified
REM                Jayanthi Dudala	       		07/05/2011   		Modified  Added new field site_id field
REM				   Sripriya Rao				 06/17/2016		Modified to exclude the link to o5.order_report table
REM															pointing to demandware orders
REM ############################################################################
set linesize 1000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
select orderid ||chr(9)||
       siteid ||chr(9)||
       date_time_entered ||chr(9)||
       date_time_completed ||chr(9)||
       sku ||chr(9)||
       quantity ||chr(9)||
       amount ||chr(9)||
       currency ||chr(9)||
       ''||CHR(9)||
       ''||CHR(9)||
       ''||CHR(9)||
       product_name
from (
SELECT DISTINCT
       l.order_line orderid,
       case 
       when site_id is null 
       then       
       trim(o5.f_tracking_code(l.tracking_code))
       else
       trim(o5.f_tracking_code(l.tracking_code))||'-'|| l.site_id 
       end  siteid,
    TO_CHAR(nvl(l.db_orderdate,l.orderdate),'YYYY-MM-DD/hh24:mi:ss') date_time_entered,
    TO_CHAR(nvl(l.db_orderdate,l.orderdate),'YYYY-MM-DD/hh24:mi:ss') date_time_completed,
       l.upc sku,
       l.qtyordered quantity,
       l.extend_price_amt * 100 amount,
       'USD' currency,
       p.group_id ||'-'||m.group_name||' : '|| replace(replace(replace(mp.item_web_description,'<b>',''),'</b>',''),'<br>','') product_name
    from O5.LINK_SHARE_SALES_LANDING_STG L,
    O5.BI_PRODUCT P,
    O5.bi_mini_product mp,
    mrep.bi_merch_hier m
    where  L.UPC = P.PRODUCT_CODE(+)
      and p.product_code= mp.item(+)
      and p.group_id = m.group_id   
     -- and mid = '38801' 
	  AND substr(MID,1,5) = '38801'
	   AND L.OL_STATUS='D'
      and nvl(l.upc,'0')  NOT IN ('0499932227409','0499947955373','0499928820294')
      AND (   (l.tracking_code NOT LIKE '%360iGsaksfifthavenue.com%')
           OR (l.tracking_code NOT LIKE '%360iGwww.saks.com%')
           OR (l.tracking_code NOT LIKE '%AOL.comSearchNatural%')
           OR (l.tracking_code NOT LIKE '%mail.aol.com%')
           OR (l.tracking_code NOT LIKE '%mail.comcast.net%')
           OR (l.tracking_code NOT LIKE '%mail.google.com%')
           OR (l.tracking_code NOT LIKE '%mail.live.com%')
           OR (l.tracking_code NOT LIKE '%mail.yahoo.com%')
           OR (l.tracking_code NOT LIKE '%mail2.daum.net%')
           OR (l.tracking_code NOT LIKE '%mponlinemall.com%')
           OR (l.tracking_code NOT LIKE '%netmail.verizon.net%')
           OR (l.tracking_code NOT LIKE '%webmail.aol.com%')
           OR (l.tracking_code NOT LIKE '%webmail.earthlink.net%')
           OR (l.tracking_code NOT LIKE '%webmailb.netzero.net%')
           OR (l.tracking_code NOT LIKE '%websearch.verizon.net%')
           OR (l.tracking_code NOT LIKE '%www.bing.com%')
           OR (l.tracking_code NOT LIKE '%www.google.com%'))
)
;
INSERT /*+ append */  INTO O5.link_share_sales_hist(ORDERDATE,ORDER_LINE,TRACKING_CODE,SITE_ID,UPC,UNITS,REVENUE,ADD_DT,MID,EXTEND_PRICE_AMT,QTYORDERED,OL_STATUS,DB_ORDERDATE)
   SELECT ORDERDATE,ORDER_LINE,TRACKING_CODE,SITE_ID,UPC,UNITS,REVENUE,ADD_DT,to_number(substr(MID,1,5)),EXTEND_PRICE_AMT,QTYORDERED,OL_STATUS,DB_ORDERDATE
     FROM O5.LINK_SHARE_SALES_LANDING_STG S where substr(MID,1,5) = '38801' and upper(ORDER_LINE) not like 'DW%'
	 AND NOT EXISTS ( SELECT 'X' 
                   FROM O5.link_share_sales_hist A
                   WHERE A.ORDER_LINE = S.ORDER_LINE
				    AND  A.UPC = S.UPC
					AND  TRUNC(A.ORDERDATE) = TRUNC(S.ORDERDATE)
					AND A.MID =38801 );
COMMIT ;

quit;
