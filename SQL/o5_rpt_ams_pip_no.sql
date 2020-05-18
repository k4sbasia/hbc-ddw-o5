REM ############################################################################
REM                        Saks Direct
REM ############################################################################
REM
REM  CODE HISTORY:   Name               Date            Description
REM                -----------------    ----------      --------------------------
REM                 David Alexander     10/06/2016      Off 5th AMS report to confirm PIP text..
REM
REM
REM ############################################################################
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set linesize 1000
select 'svs,skn,upc,pip text,effective date,promo_start_date,promo_end_date,department,regular price,sale price,price_status'
from dual;
select distinct product_code ||','||
        skn_no ||','||
         p.upc ||','||
        sd_pip_text ||','||
       trunc(effective_date) ||','||
	   case when
            promo_start_date is not null then to_char(promo_start_date)|| ' 00:00:01'
            else promo_start_date end ||','||
       case when
       	    promo_end_date is not null then to_char(promo_end_date) || ' 23:59:59'
            else promo_end_date end  ||','||
       department_id ||','||
       current_ticket ||','||
       offer_price ||','||
	   price_type_cd
from edata_exchange.o5_sd_price_adv a,
     o5.bi_product p
where   lpad(a.skn_no,13,0) = p.sku
and   trunc(effective_date) between trunc(sysdate) and trunc(sysdate)+10
and p.deactive_ind  = 'N'
AND p.item_active_ind = 'A'
and   a.sd_pip_text is null
;
exit
