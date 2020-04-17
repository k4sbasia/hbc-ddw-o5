INSERT INTO o5.edb_stage_sub
  (    subscribed,
    source_id,
    str_code, 
   email_address,
    zip_full,
    more_number  )
SELECT distinct DATEKEY ,
  '9153',
  STORE_num,
  email_address ,
  zip_code ,  
  more_number FROM o5.edb_email_receipt_wrk w
where not exists
(select 1 from o5.email_address e where e.email_address=w.email_address)
and email_address is not null;
commit;

exit
