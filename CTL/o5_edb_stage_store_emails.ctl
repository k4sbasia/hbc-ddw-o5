LOAD DATA
TRUNCATE
INTO TABLE o5.edb_stage_store_emails_wrk
FIELDS TERMINATED BY '!'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
 DATEKEY     position (1:8) char "to_date(:DATEKEY,'YYYYMMDD')"
,STORE_NUM   position (10:13) char "trim(:STORE_NUM)"
,TERM_NUM    position (15:18) char "trim(:TERM_NUM)"
,TRAN_NUM    position (20:23) char "trim(:TRAN_NUM)" 
,OPER_SIGN_ON_O position (25:30) char "trim(:OPER_SIGN_ON_O)"
,STRING_L32  position (32:33) char "trim(:STRING_L32)"
,EMAIL_ADDR_L32 position (35:83) char "trim(:EMAIL_ADDR_L32)"
,STRING_L33  position (85:86) char "trim(:STRING_L33)"
,EMAIL_ADDR_L33 position (88:136) char "trim(:EMAIL_ADDR_L33)"
,STRING_L34  position (138:139) char "trim(:STRING_L34)"
,EMAIL_ADDR_L34 position (141:189) char "trim(:EMAIL_ADDR_L34)"
,EMAIL_RECEIPT_L32 position (191:191) char "trim(:EMAIL_RECEIPT_L32)"
)
