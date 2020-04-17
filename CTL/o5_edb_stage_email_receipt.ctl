LOAD DATA
truncate
INTO TABLE o5.edb_email_receipt_wrk
(
 DATEKEY     position (1:8) char "to_date(:DATEKEY,'YYYYMMDD')"
,STORE_num   position (9:12) char "trim(:store_num)"
,email_address   position (24:72) char  "upper(trim(:email_address))"
,zip_code  position (73:82) char "trim(:zip_code)"
,more_number   position (90:103) char "trim(:more_number)"
)
