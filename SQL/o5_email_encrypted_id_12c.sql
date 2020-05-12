whenever sqlerror exit failure
set heading off
set verify off
set serveroutput on
set pagesize 0
set tab off
set timing on

---Delete any duplicate rows from the stage table:
---=================================================
delete FROM 
 SDMRK.O5_EDB_CM_EMAIL_SUB_WRK   A
WHERE 
  a.rowid > 
   ANY (
     SELECT 
        B.rowid
     FROM 
       SDMRK.O5_EDB_CM_EMAIL_SUB_WRK B
     WHERE 
        trim(A.email_address) = trim(B.email_address) AND
        trim(A.encrypted_id) = trim(B.encrypted_id)
	);

commit;

---For inserting into SDMRK.O5_EMAIL_ENCRYPTID :
---=============================================
merge into SDMRK.O5_EMAIL_ENCRYPTID trg
using (select a.email_address,a.encrypted_id
       from SDMRK.O5_EDB_CM_EMAIL_SUB_WRK a
       ) src
on (trim(trg.email_address) = trim(src.email_address))
when not matched then
insert (email_address,
        encrypted_id
	)
values (src.email_address,
        src.encrypted_id
	)
when matched then update
set trg.encrypted_id = src.encrypted_id,
    modify_dt = sysdate
;
commit;

---Adding into history table SDMRK.O5_EDB_CM_EMAIL_SUB_HIS:
---==================================================
merge into SDMRK.O5_EDB_CM_EMAIL_SUB_HIS trg
using (select a.email_address,a.encrypted_id
       from SDMRK.O5_EDB_CM_EMAIL_SUB_WRK a
       ) src
on (trim(trg.email_address) = trim(src.email_address)
    AND trim(trg.encrypted_id) = trim(src.encrypted_id)
    AND trunc(load_dt) = trunc(sysdate))
when not matched then
insert (email_address,
        encrypted_id
        )
values (src.email_address,
        src.encrypted_id
        );

commit;

exit