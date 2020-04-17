-- O5:
-- process existing files first
-- if record has solely a value in the 32 string without an e-receipt indicator, process as 9165
-- if record has solely a value in the 32 string with an e-receipt indicator, process as 9153
-- if record has solely a value in the 33 string without an e-receipt indicator, process as 9165
-- if record has solely a value in the 33 string with an e-receipt indicator, process as 9153
-- if record has values in both 32 AND 33 strings that are not the same, process a COA with the 32 string email as the new value, AND the 33 string email should be opted out.

INSERT INTO o5.edb_stage_sub
  ( subscribed,
    source_id,
    str_code,
    email_address
   )
SELECT distinct
  datekey,
  '9165',
  store_num,
  email_addr_l32
FROM o5.edb_stage_store_emails_wrk 
WHERE email_addr_l32 is not null 
AND email_addr_l33 is null
AND email_addr_l34 is null
AND email_receipt_l32 is null;

COMMIT;

INSERT INTO o5.edb_stage_sub
  ( subscribed,
    source_id,
    str_code,
    email_address
   )
SELECT distinct
  datekey,
  '9153',
  store_num,
  email_addr_l32
FROM o5.edb_stage_store_emails_wrk
WHERE email_addr_l32 is not null
AND email_addr_l33 is null
AND email_addr_l34 is null
AND email_receipt_l32 = 'Y';

COMMIT;

INSERT INTO o5.edb_stage_sub
  ( subscribed,
    source_id,
    str_code,
    email_address
   )
SELECT distinct
  datekey,
  '9165',
  store_num,
  email_addr_l33
FROM o5.edb_stage_store_emails_wrk
WHERE email_addr_l33 is not null
AND email_addr_l32 is null
AND email_addr_l34 is null
AND email_receipt_l32 is null;

COMMIT;

INSERT INTO o5.edb_stage_sub
  ( subscribed,
    source_id,
    str_code,
    email_address
   )
SELECT distinct
  datekey,
  '9153',
  store_num,
  email_addr_l33
FROM o5.edb_stage_store_emails_wrk
WHERE email_addr_l33 is not null
AND email_addr_l32 is null
AND email_addr_l34 is null
AND email_receipt_l32 = 'Y';

COMMIT;

INSERT INTO o5.edb_stage_coa
	( source_id,
	  old_email_address,
	  new_email_address,
	  changed,
          email_id
	)
SELECT '9165',
       trim(upper(email_addr_l32)),
       trim(upper(email_addr_l33)),
       datekey,
       email_id
FROM o5.edb_stage_store_emails_wrk 
INNER JOIN o5.email_address 
ON (email_address = upper(trim(email_addr_l32)))
WHERE email_addr_l33 is not null 
AND email_addr_l32 is not null
AND email_addr_l32 <> email_addr_l33
AND email_receipt_l32 is null;

COMMIT;

INSERT INTO o5.edb_stage_coa
        ( source_id,
          old_email_address,
          new_email_address,
          changed,
          email_id
        )
SELECT '9153',
       trim(upper(email_addr_l32)),
       trim(upper(email_addr_l33)),
       datekey,
       email_id
FROM o5.edb_stage_store_emails_wrk
INNER JOIN o5.email_address
ON (email_address = upper(trim(email_addr_l32)))
WHERE email_addr_l33 is not null
AND email_addr_l32 is not null
AND email_addr_l32 <> email_addr_l33
AND email_receipt_l32 = 'Y';

COMMIT;

INSERT INTO o5.edb_stage_store_emails_hist
(       DATEKEY,
        STORE_NUM,
        TERM_NUM,
        TRAN_NUM,
        OPER_SIGN_ON_O,
        STRING_L32,
        STRING_L33,
        STRING_L34,
        EMAIL_ADDR_L32,
        EMAIL_ADDR_L33,
        EMAIL_ADDR_L34,
        EMAIL_RECEIPT_L32
)
SELECT
        DATEKEY,
        STORE_NUM,
        TERM_NUM,
        TRAN_NUM,
        OPER_SIGN_ON_O,
        STRING_L32,
        STRING_L33,
        STRING_L34,
        EMAIL_ADDR_L32,
        EMAIL_ADDR_L33,
        EMAIL_ADDR_L34,
        EMAIL_RECEIPT_L32
FROM o5.edb_stage_store_emails_wrk;

COMMIT;

exit
