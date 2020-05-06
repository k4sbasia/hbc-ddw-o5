LOAD DATA
truncate
INTO TABLE sdmrk.o5_vibes_data_wrk
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
person_id "trim(:person_id)", 
external_person_id "trim(:external_person_id)",
mdn "trim(:mdn)",
company_id "trim(:company_id)", 
carrier_code "trim(:carrier_code)",
subscription_list_id "trim(:subscription_list_id)",
opt_in_date "to_timestamp_tz(trim(:opt_in_date),'YYYY-MM-DD hh24:mi:ss TZH:TZM')",
opt_out_date "to_timestamp_tz(trim(:opt_out_date),'YYYY-MM-DD hh24:mi:ss TZH:TZM')",
subscription_event "trim(:subscription_event)",
opt_out_reason "trim(:opt_out_reason)"
)
