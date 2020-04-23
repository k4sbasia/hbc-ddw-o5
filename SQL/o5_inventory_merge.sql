set echo off
set linesize 10000
set pagesize 0
set sqlprompt ''
set timing on
set heading off
set trimspool on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

exec dbms_stats.gather_table_stats('O5','INVENTORY_V1');

exec dbms_stats.gather_table_stats('O5','INVENTORY');

UPDATE O5.inventory_v1 set PROCESSED='P' WHERE PROCESSED='F';

COMMIT;

declare 
  
  
   I           INTEGER := 0;
   l_error_count  NUMBER;
  l_error_msg varchar2(2000);
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  LASTPROCESEDDATE DATE := SYSDATE;
  v_err_cnt NUMBER;
  batch_err_cnt   EXCEPTION;
  CURSOR C1 IS
select i.*, to_date('19700101', 'YYYYMMDD') + ( 1 / 24 / 60 / 60 / 1000) * i.ALLOCATIONTIMESTAMP alloc_tstmp,i.rowid rid from O5.inventory_v1 i 
where i.PROCESSED='P'
order by to_date('19700101', 'YYYYMMDD') + ( 1 / 24 / 60 / 60 / 1000) * i.ALLOCATIONTIMESTAMP
--and rownum<10

;
  TYPE INV_REC_TYPE IS
        TABLE OF C1%rowtype;
         v_coll_INV_REC_TYPE   INV_REC_TYPE;
 v_prcs_batch NUMBER;
 
 BEGIN
  
  v_prcs_batch:=o5.INV_BATCH_SEQ.NEXTVAL;
    OPEN c1;                              
    LOOP
    FETCH c1  BULK COLLECT INTO v_coll_INV_REC_TYPE limit 50000;  
    BEGIN
     FORALL indx IN 1..v_coll_INV_REC_TYPE.COUNT SAVE EXCEPTIONS
    
  MERGE INTO O5.INVENTORY UA
  USING (
     SELECT v_coll_INV_REC_TYPE(indx).itemid itemid,
     v_coll_INV_REC_TYPE(indx).onhand onhand,
     v_coll_INV_REC_TYPE(indx).alloc_tstmp alloc_tstmp,
     (to_date('19700101', 'YYYYMMDD') + ( 1 / 24 / 60 / 60 / 1000) *  v_coll_INV_REC_TYPE(indx).instockdate) instockdate,
     v_coll_INV_REC_TYPE(indx).batch_id batch_id
  FROM DUAL
    ) CP
  ON (UA.SKN_NO = CP.ITEMID )
  WHEN MATCHED THEN
    UPDATE SET IN_STOCK_SELLABLE_QTY = CP.ONHAND,
    IN_STOCK_UPDATE_DATE=cp.instockdate,
    BATCH_ID=cp.batch_id,
    MERGE_BATCH_ID=v_prcs_batch
  WHEN NOT MATCHED THEN
    INSERT (SKN_NO,IN_STOCK_SELLABLE_QTY,IN_STOCK_UPDATE_DATE,ADD_DT,BATCH_ID,MERGE_BATCH_ID
            )
    VALUES (CP.ITEMID,CP.ONHAND,CP.instockdate,SYSDATE,cp.batch_id,v_prcs_batch
       );
       COMMIT;
    
EXCEPTION
    WHEN ex_dml_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
      l_error_msg := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
      dbms_output.put_line('Error #' || i || ' at '|| 'iteration
      #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Error message is ' ||
      SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      INSERT INTO  O5.TECH_EXCPTN
                     (
                     PROCESS_NM,KEY_ID ,ERR_MSG, EXCPT_DT,BATCH_ID
                     )
              VALUES (
              'INV_MERGE',
              v_coll_INV_REC_TYPE(i).ITEMID,
              --SELECTION(i).CUSTOMER_ID,
             l_error_msg,SYSDATE,v_prcs_batch
                     );
                     COMMIT;

   END LOOP;        
  
END; 
     
     BEGIN 
      FORALL indx IN 1..v_coll_INV_REC_TYPE.COUNT SAVE EXCEPTIONS
      UPDATE O5.inventory_v1 set PROCESSED='C' WHERE rowid=v_coll_INV_REC_TYPE(indx).rid
     -- and not exists (select 'X' from TECH_EXCPTN WHERE BATCH_ID=v_prcs_batch and KEY_ID=to_char(v_coll_INV_REC_TYPE(indx).itemid))
     ;
      
      COMMIT;
--      
--      FORALL indx IN 1..v_coll_INV_REC_TYPE.COUNT SAVE EXCEPTIONS
--      UPDATE O5.inventory_v1 set PROCESSED='F' WHERE ITEMID=to_char(v_coll_INV_REC_TYPE(indx).itemid)
--      and exists (select 'X' from TECH_EXCPTN WHERE BATCH_ID=v_prcs_batch and KEY_ID=to_char(v_coll_INV_REC_TYPE(indx).itemid))
--      ;
      
--      COMMIT;

EXCEPTION
    WHEN ex_dml_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
      l_error_msg := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
      dbms_output.put_line('Error #' || i || ' at '|| 'iteration
      #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Error message is ' ||
      SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      INSERT INTO  O5.TECH_EXCPTN
                     (
                     PROCESS_NM,KEY_ID ,ERR_MSG, EXCPT_DT,BATCH_ID
                     )
              VALUES (
              'INV_UPD_PRCSD',
              v_coll_INV_REC_TYPE(i).ITEMID,
              --SELECTION(i).CUSTOMER_ID,
              l_error_msg,SYSDATE,v_prcs_batch
                     );
                     COMMIT;

   END LOOP;        
 
END;




 EXIT WHEN C1%NOTFOUND;
       
         END LOOP;
COMMIT;
    



CLOSE c1;  


FOR l_tech in (select key_ID from O5.TECH_EXCPTN where BATCH_ID=v_prcs_batch and PROCESS_NM in ('INV_UPD_PRCSD','INV_MERGE'))
LOOP
UPDATE O5.inventory_v1 set PROCESSED='F' WHERE ITEMID=to_char(l_tech.key_ID);

END LOOP;

select count(*) INTO v_err_cnt from O5.TECH_EXCPTN where BATCH_ID=v_prcs_batch;

IF v_err_cnt > 0
THEN
raise batch_err_cnt;
END IF;

EXCEPTION
WHEN batch_err_cnt
THEN
dbms_output.put_line('Error found in TECH_EXCPTN for batch: '||v_prcs_batch);
RAISE;
WHEN OTHERS
THEN
RAISE;
END ;
/

EXIT;