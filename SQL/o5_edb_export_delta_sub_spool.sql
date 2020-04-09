set feedback off
set heading off
set linesize 10000
set pagesize 0
set space 0
set tab off
set trimout on
select distinct
    email_address    || ',' ||
    welcome_promo    || ',' ||
    add_by_source_id || ',' ||
    master_source_id || ',' ||
    orig_opt_dt      || ',' ||
    international_customer  || ',' ||
    cm_aid || ',' ||
    case when mod(email_id, 2)=1 then 'Y'
             else 'N' end || ',' ||
    TRIM(more_number) || ',' ||
    trim(barcode)   || ',' ||
    language_id || ',' ||
    email_id || ',' ||
    o5.convert_string_to_md5(lower(email_address)) || ',' ||
    o5.convert_string_to_sha1(lower(email_address)) || ',' ||
    o5.convert_string_to_sha256(lower(email_address)) || ',' ||
    nvl(product_code,'') || ',' ||
    nvl(department_id,'') || ',' ||
    nvl(brand_name,'') welcome_series
from
(
with email_sub_spool as
(select distinct sub.email_address,
             sub.welcome_promo,
             sub.add_by_source_id,
             sub.master_source_id,
             sub.orig_opt_dt,
             case when ( nvl(s.ship_country, 'US') <> 'US' or nvl(c.country, 'US') <> 'US' ) or sub.international_ind = 'Y' then 'Y' ELSE 'N' END  international_customer,
             sub.cm_aid,
             sub.email_id,
             sub.more_number,
             sub.barcode,
             sub.language_id
      FROM o5.bi_customer c,
           o5.bi_sale s,
           (SELECT e.email_address,
                   e.welcome_promo,
                   e.add_by_source_id,
                   s.master_source_id,
                   e.orig_opt_dt,
                   case when nvl(e.canada_flag,'N') = 'Y' then 'Y' else e.international_ind end international_ind,
                   (select cm_aid from mrep.email_master_source m where s.master_source_id=m.master_source_id) cm_aid,
                   e.email_id,
                   more_number,
                   e.barcode barcode,
                   e.language_id
            FROM o5.email_address e, mrep.email_source s
            WHERE
                  e.cheetah_extract_dt_delta > (select curr_extract_time from o5.edb_sub_status)
                  AND e.sys_entry_dt > (select last_extract_time from o5.edb_sub_status)
                  AND e.opt_in = 1
                  AND e.valid_ind = 1
                  AND e.orig_opt_dt is not null
                  AND e.add_by_source_id = s.source_id
                  AND e.add_by_source_id <> '9104'
                  and e.welcome_promo is not null) sub
      WHERE sub.email_address = upper(trim(c.internetaddress(+)))
            AND s.createfor(+) = c.customer_id
)
SELECT  distinct
        e.email_address,
        e.welcome_promo,
        e.add_by_source_id,
        e.master_source_id,
        e.orig_opt_dt,
        e.international_customer,
        e.cm_aid,
        e.email_id,
        e.more_number,
        e.barcode,
        e.language_id,
        null orderdate,
        null createfor,
        null ordernum,
        null product_code,
        null upc,
        null offernprice_amt,
        null department_id,
        null brand_name,
        1 rr
from email_sub_spool e
where not exists (select 1 from o5.bi_customer c, o5.bi_sale s, o5.bi_product pp where
                  trim(e.email_address) = upper(trim(c.internetaddress)) and 
                  s.createfor = c.customer_id and
                  s.item = pp.product_code and
                  s.product_id = pp.upc and
                  pp.active_ind = 'A' and 
                  pp.wh_sellable_qty > 0 and 
                  pp.sku_sale_price > 0 and 
                  trunc(orderdate) >= trunc(e.orig_opt_dt)-14)
union
select * from
(
SELECT  distinct
        e.email_address,
        e.welcome_promo,
        e.add_by_source_id,
        e.master_source_id,
        e.orig_opt_dt,
        e.international_customer,
        e.cm_aid,
        e.email_id,
        e.more_number,
        e.barcode,
        e.language_id,
        s.orderdate,
        s.createfor,
        s.ordernum,
        pp.product_code,
        pp.upc,
        s.offernprice_amt, 
        pp.department_id,
        pp.brand_name,
        DENSE_RANK() over (partition by e.email_address order by s.offernprice_amt desc) rr
from email_sub_spool e
INNER JOIN o5.bi_customer c
ON (trim(e.email_address) = upper(trim(c.internetaddress)))
INNER JOIN o5.bi_sale s
ON (s.createfor = c.customer_id)
INNER JOIN o5.bi_product pp
ON (s.item = pp.product_code and s.product_id = pp.upc)
where pp.active_ind = 'A' and
      pp.wh_sellable_qty > 0 and 
      pp.sku_sale_price > 0 and
      trunc(orderdate) >= trunc(e.orig_opt_dt)-14
) where rr=1
);
exit
