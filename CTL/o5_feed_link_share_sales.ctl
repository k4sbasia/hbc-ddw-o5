LOAD DATA
APPEND
INTO TABLE O5.LINK_SHARE_SALES_LANDING_STG
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
orderdate  char "to_date(:orderdate,'Month DD YYYY')",
order_line char "trim(:order_line)",
tracking_code  "trim(:tracking_code)",
site_id "trim(:site_id)",
upc   "trim(:upc)",
mid "nvl(:mid,'38801')",
units "trim(:units)",
revenue decimal external
)
