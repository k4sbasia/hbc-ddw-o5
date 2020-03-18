set echo off
set feedback on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set timing on
set serverout on
MERGE INTO O5.bi_netsale hst
   USING (SELECT a.*
            FROM (SELECT TRUNC (i.transdate) transdate, i.STORE, i.REGISTER,
                         i.transnum, i.department, i.sku, i.upc, i.slordernum,
                         i.ROWID rowpoint
                    FROM O5.bi_netsale i
                   WHERE i.skupc_ind NOT IN ('S', 'U', 'R')) a,
                 (SELECT DISTINCT sku sku
                             FROM O5.bi_product) b
           WHERE a.sku = b.sku) trn
   ON (    trn.transdate = hst.transdate
       AND trn.STORE = hst.STORE
       AND trn.REGISTER = hst.REGISTER
       AND trn.transnum = hst.transnum
       AND trn.department = hst.department
       AND trn.sku = hst.sku
       AND hst.ROWID = trn.rowpoint)
   WHEN MATCHED THEN
      UPDATE
         SET hst.skupc_ind = 'S'
   WHEN NOT MATCHED THEN
      INSERT (add_dt, skupc_ind)
      VALUES (SYSDATE, 'I');
COMMIT ;
---changelevel 2009:10:1  chanbe the routine to validate current day's sku and set skupc ind to S vs U --
MERGE INTO O5.bi_netsale hst
   USING (SELECT TRUNC (a.transdate) transdate, a.STORE, a.REGISTER,
                 a.transnum, a.department, b.sku, a.upc, a.slordernum,
                 a.ROWID rowpoint
            FROM O5.bi_netsale a, O5.bi_product b
           WHERE a.upc = b.upc
             AND (   a.skupc_ind NOT IN ('S', 'U', 'R')
                  OR (a.add_dt > SYSDATE - 1 AND a.sku <> b.sku)
                 )) trn
   ON (    trn.transdate = hst.transdate
       AND trn.STORE = hst.STORE
       AND trn.REGISTER = hst.REGISTER
       AND trn.transnum = hst.transnum
       AND trn.department = hst.department
       AND trn.upc = hst.upc
       AND hst.ROWID = trn.rowpoint)
   WHEN MATCHED THEN
      UPDATE
         SET hst.skupc_ind = 'S', hst.sku = trn.sku, hst.modify_dt = SYSDATE
   WHEN NOT MATCHED THEN
      INSERT (add_dt, skupc_ind)
      VALUES (SYSDATE, 'X');
COMMIT ;

--Drop index before refreshing materilaized views
DECLARE
BEGIN
  FOR R1 IN
  (SELECT INDEX_NAME,OWNER,TABLE_NAME
  FROM ALL_INDEXES
  WHERE TABLE_NAME = 'MV_O5_BI_NETSALE'
  )
  LOOP
    BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX '||R1.OWNER||'.' || R1.INDEX_NAME ;
    
    EXCEPTION WHEN OTHERS THEN
    EXECUTE IMMEDIATE 'alter table' ||R1.OWNER||'.' || R1.TABLE_NAME ||' disable primary key';
    END;
  END LOOP;
END;
/
--Refresh SDDW.MV_O5_BI_NETSALE Materialized view for BI

EXEC DBMS_MVIEW.REFRESH ('SDDW.MV_O5_BI_NETSALE', 'C');

--Creating index on MV_O5_BI_NETSALE

CREATE INDEX "SDDW"."IX_O5_NETSALE_BMORDER_MV" ON "SDDW"."MV_O5_BI_NETSALE"
  (
    "BM_ORDERNUM"
  );
  
CREATE INDEX "SDDW"."IX_O5_NETSALE_SKU_MV" ON "SDDW"."MV_O5_BI_NETSALE"
  (
    "SKU"
  );
  
CREATE INDEX "SDDW"."IX_O5_NETSALE_TRANSDATE_MV" ON "SDDW"."MV_O5_BI_NETSALE"
  (
    "TRANSDATE"
  );

UPDATE o5.bi_netsale a
   SET modify_dt = SYSDATE
 WHERE a.modify_dt IS NULL;
 commit;
show errors
exit;
 
