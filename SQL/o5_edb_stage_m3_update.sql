set timing on
set feedback on

update O5.edb_stage_m3_update
set email_address = upper(trim(email_address)),
    associate_id  = trim(associate_id),
    account_num   = trim(account_num),
    str_code      = trim(str_code),
    prefix        = trim(prefix),
    full_name     = trim(full_name),
    first_name    = trim(first_name),
    middle_name   = trim(middle_name),
    last_name     = trim(last_name),
    address       = trim(address),
    address_two   = trim(address_two),
    city          = trim(city),
    state         = trim(state),
    zip_full      = trim(zip_full),
    zip_5         = trim(zip_5),
    zip_4         = trim(zip_4),
    phone         = trim(phone),
    country       = trim(country),
    MORE_NUMBER   = TRIM(MORE_NUMBER);
commit;

update O5.edb_stage_m3_update
set zip_full = zip_5
where (country is null or country = 'US')
  and zip_full is null
  and ZIP_5 is not null
  and ZIP_4 is null;
commit;
  
update O5.edb_stage_m3_update
set zip_full = zip_5 || '-' || zip_4
where (country is null or country = 'US')
  and zip_full is null
  and zip_5 is not null
  and zip_4 is not null;

commit;

-- populate zip_5 and zip_4 from zip_full
update O5.edb_stage_m3_update
set zip_5 = regexp_replace(zip_full, '^([0-9]{5})-?([0-9]{4})$', '\1'),
    zip_4 = regexp_replace(zip_full, '^([0-9]{5})-?([0-9]{4})$', '\2')
where (country is null or country = 'US')
  and zip_full is not null
  and zip_5 is null
  and zip_4 is null
  and regexp_like(zip_full, '^([0-9]{5})-?([0-9]{4})$');

commit;

update O5.edb_stage_m3_update
set zip_5 = zip_full
where (country is null or country = 'US')
  and zip_full is not null
  and zip_5 is null
  and zip_4 is null
  and regexp_like(zip_full, '^([0-9]{5})$');

commit;


merge into O5.EMAIL_ADDRESS TRG using
(select distinct EMAIL_ADDRESS, max(MORE_NUMBER) more_number from O5.EDB_STAGE_M3_UPDATE
group by EMAIL_ADDRESS
) SRC 
ON (TRG.EMAIL_ADDRESS=SRC.EMAIL_ADDRESS)
WHEN matched THEN
  UPDATE
  set TRG.MORE_NUMBER=coalesce(SRC.MORE_NUMBER,TRG.MORE_NUMBER),
    trg.modify_dt=sysdate
    /*TRG.FIRST_NAME   =COALESCE(SRC.FIRST_NAME,TRG.FIRST_NAME),
    TRG.LAST_NAME    =COALESCE(SRC.LAST_NAME,TRG.LAST_NAME),
    TRG.ADDRESS      =COALESCE(SRC.ADDRESS,TRG.ADDRESS),
    TRG.ADDRESS_TWO  =COALESCE(SRC.ADDRESS_TWO,TRG.ADDRESS_TWO),
    TRG.CITY         =COALESCE(SRC.CITY,TRG.CITY),
    TRG.STATE        =COALESCE(SRC.STATE,TRG.STATE),
    TRG.ZIP          =coalesce(SRC.ZIP_FULL,TRG.ZIP),
    TRG.PHONE_number        =COALESCE(SRC.PHONE, TRG.PHONE_number),
    trg.init_store   = COALESCE(trg.init_store, to_number(src.str_code))*/
    ;
commit;
-------------------------------

exit
