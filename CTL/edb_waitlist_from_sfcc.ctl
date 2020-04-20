load data
truncate
into table o5.edb_stage_sfcc_wl_wrk
fields terminated by ',' OPTIONALLY ENCLOSED BY '"'
trailing nullcols
(
 email_address
,product_skus
,phone_number char "REGEXP_REPLACE(:phone_number,'[^0-9]+', '')"
,add_date
)
