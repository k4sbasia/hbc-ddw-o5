set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on

truncate table  MREP.BI_CATEGORY_WRK;
INSERT /*+ append */
INTO MREP.BI_CATEGORY_WRK
  ( CATEGORY_ID, CATEGORY_NAME
  )
SELECT distinct R.GMM_NO
  || LPAD(R.DMM_NO,2,0),
  SUBSTR(r.dmm_name,1,15)
FROM RFS.MV_RF_MERCHANT_ORG@SAKSRFS_PRD R
;
commit;


truncate table MREP.BI_DEPTDIV_WRK;
INSERT
  /*+append */
INTO MREP.BI_DEPTDIV_WRK
  (
    DEPARTMENT_ID ,
    DEPARTMENT_NAME ,
    DIVISION_ID ,
    DIVISION_NAME ,
    CLASS_ID ,
    CLASS_NAME ,
    BUYER_ID ,
    BUYER_NAME
  )
SELECT distinct lpad(R.DEPT_NO,3,0),
  R.DEPT_NAME,
  R.GMM_NO,
  R.GMM_ABBR,
  LPAD(C.CLASS_NO,2,0),
  SUBSTR(C.CLASS_DESC,1,15),
  lpad(R.BYR_NO,5,0),
  SUBSTR(R.BYR_NAME,1,15)
FROM RFS.MV_RF_MERCHANT_ORG@SAKSRFS_PRD R,
  RFS.RF_DEPT_CLASS@SAKSRFS_PRD C
WHERE C.DEPT_NO=R.DEPT_NO
;
commit;

MERGE INTO MREP.BI_GROUPS HST
     USING (SELECT DISTINCT
                   SUBSTR (category_id, 1, 1) DIVISION_ID,
                   SUBSTR (category_id, 2) GROUP_ID,
                   category_name GROUP_NAME
              FROM MREP.BI_CATEGORY_WRK) TRN
        ON (TRN.GROUP_ID = HST.GROUP_ID AND TRN.DIVISION_ID = HST.DIVISION_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.GROUP_NAME = TRN.GROUP_NAME, HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (DIVISION_ID,
               GROUP_ID,
               GROUP_NAME,
               ADD_DT)
       VALUES (TRN.DIVISION_ID,
               TRN.GROUP_ID,
               TRN.GROUP_NAME,
               SYSDATE);

COMMIT;
--------------------------------------------------------

MERGE INTO MREP.BI_DIVISIONS HST
     USING (SELECT DISTINCT
                   Division_id Division_id,
                   'Division ' || division_id Division_Name
              FROM MREP.BI_GROUPS) TRN
        ON (TRN.DIVISION_ID = HST.DIVISION_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (DIVISION_ID, DIVISION_NAME, ADD_DT)
       VALUES (TRN.DIVISION_ID, TRN.DIVISION_NAME, SYSDATE);

COMMIT;
-------------------------------------------------------------


-- Commented out the department_name updates only insert new departments
 MERGE INTO MREP.BI_DEPARTMENTS HST
     USING ( SELECT DISTINCT
                   DEPARTMENT_ID DEPARTMENT_ID,
                   DEPARTMENT_NAME DEPARTMENT_NAME,
                   BM_PATH BM_PATH
              FROM MREP.BI_DEPTDIV_WRK ) TRN
        ON (TRN.DEPARTMENT_ID = HST.DEPARTMENT_ID)
WHEN NOT MATCHED
THEN
   INSERT     (DEPARTMENT_ID,
               DEPARTMENT_NAME,
               BM_PATH,
               ADD_DT)
       VALUES (TRN.DEPARTMENT_ID,
               TRN.DEPARTMENT_NAME,
               TRN.BM_PATH,
               SYSDATE);

COMMIT;
-- Added new truncate and insert after AMS went live

truncate table mrep.bi_merch_hier_wrk;

INSERT
INTO mrep.bi_merch_hier_wrk
  (
    DPT_CDE ,
    DPT_DCD,
    BUYR_NUM,
    BUYR_L_NAME,
    DIV_CDE,
    div_dcd,
    GMM_CDE,
    gmm_dcd
  )
SELECT DISTINCT lpad(R.DEPT_NO,3,0),
  r.dept_name,
  lpad(r.byr_no,5,0),
  SUBSTR(r.byr_name,1,15),
  lpad(dmm_no,2,0),
  SUBSTR(dmm_name,1,15),
  r.gmm_no,
  SUBSTR(gmm_name,1,15)
FROM RFS.MV_RF_MERCHANT_ORG@SAKSRFS_PRD R,
  rfs.rf_dept_class@saksrfs_prd c
where c.dept_no=r.dept_no;
commit;

MERGE INTO mrep.bi_merch_hier hst
   USING (SELECT dpt_cde, dpt_dcd, buyr_num, buyr_f_init, buyr_l_name,
                 mast_buyr_num, mast_buyr_id_cde, mast_buyr_name, div_cde,
                 div_dcd, div_name, gmm_cde, gmm_dcd, gmm_name, sd_buyr_num,
                 sd_buyr_id_cde, sd_buyr_name, sd_dmm, sd_dmm_name, sd_gmm,
                 sd_gmm_name
            FROM mrep.bi_merch_hier_wrk) trn
   ON (trn.dpt_cde = hst.department_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.department_name = trn.dpt_dcd, hst.buyr_num = trn.buyr_num,
             hst.buyr_f_init = trn.buyr_f_init,
             hst.buyr_l_name = trn.buyr_l_name,
             hst.mast_buyr_num = trn.mast_buyr_num,
             hst.mast_buyr_id_cde = trn.mast_buyr_id_cde,
             hst.mast_buyr_name = trn.mast_buyr_name,
             hst.GROUP_ID = trn.div_cde, hst.group_name = trn.div_dcd,
             hst.dmm_name = trn.div_name, hst.division_id = trn.gmm_cde,
             hst.division_name = trn.gmm_dcd, hst.gmm_name = trn.gmm_name,
             hst.sd_buyr_num = trn.sd_buyr_num,
             hst.sd_buyr_id_cde = trn.sd_buyr_id_cde,
             hst.sd_buyr_name = trn.sd_buyr_name, hst.sd_dmm = trn.sd_dmm,
             hst.sd_dmm_name = trn.sd_dmm_name, hst.sd_gmm = trn.sd_gmm,
             hst.sd_gmm_name = trn.sd_gmm_name
   WHEN NOT MATCHED THEN
      INSERT (hst.department_id, hst.department_name, hst.buyr_num,
              hst.buyr_f_init, hst.buyr_l_name, hst.mast_buyr_num,
              hst.mast_buyr_id_cde, hst.mast_buyr_name, hst.GROUP_ID,
              hst.group_name, hst.dmm_name, hst.division_id,
              hst.division_name, hst.gmm_name, hst.sd_buyr_num,
              hst.sd_buyr_id_cde, hst.sd_buyr_name, hst.sd_dmm,
              hst.sd_dmm_name, hst.sd_gmm, hst.sd_gmm_name)
      VALUES (trn.dpt_cde, trn.dpt_dcd, trn.buyr_num, trn.buyr_f_init,
              trn.buyr_l_name, trn.mast_buyr_num, trn.mast_buyr_id_cde,
              trn.mast_buyr_name, trn.div_cde, trn.div_dcd, trn.div_name,
              trn.gmm_cde, trn.gmm_dcd, trn.gmm_name, trn.sd_buyr_num,
              trn.sd_buyr_id_cde, trn.sd_buyr_name, trn.sd_dmm,
              trn.sd_dmm_name, trn.sd_gmm, trn.sd_gmm_name);
COMMIT ;


MERGE INTO MREP.BI_DEPARTMENTS HST
     USING (SELECT DISTINCT
                   DPT_CDE DEPARTMENT_ID,
                   DPT_DCD DEPARTMENT_NAME,
                   null BM_PATH
              FROM MREP.BI_MERCH_HIER_WRK) TRN
        ON (TRN.DEPARTMENT_ID = HST.DEPARTMENT_ID)
WHEN MATCHED
THEN
   UPDATE SET
      hst.department_name = trn.department_name,
      hst.bm_path = trn.bm_path,
      HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (DEPARTMENT_ID,
               DEPARTMENT_NAME,
               BM_PATH,
               ADD_DT)
       VALUES (TRN.DEPARTMENT_ID,
               TRN.DEPARTMENT_NAME,
               TRN.BM_PATH,
               SYSDATE);

COMMIT;
----------------------------------------------------------------

MERGE INTO MREP.BI_BUYERS HST
     USING (  SELECT buyer_id, MAX (buyer_name) buyer_name
                FROM MREP.BI_DEPTDIV_WRK
            GROUP BY buyer_id) TRN
        ON (TRN.BUYER_ID = HST.BUYER_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (BUYER_ID, BUYER_NAME, ADD_DT)
       VALUES (TRN.BUYER_ID, TRN.BUYER_NAME, SYSDATE);

COMMIT;
------------------------------------------------------------------

truncate table MREP.BI_VENDOR_WRK;
INSERT /*+ append */
into MREP.BI_VENDOR_WRK
  (VENDOR_ID ,VENDOR_NAME)
SELECT DISTINCT lpad(mdsc_vendor_no,5,0) vendor_id, vendor_site_code_alt  FROM RFS.RF_DEPT_MFG@saksrfs_prd m, hbtc.mv_ERP_po_vendor_sites_all@saksrfs_prd h
Where H.Vendor_No=M.Vendor_No
And trim(Vendor_Site_Code_Alt)<>'DUMMY VENDOR'
and mdsc_vendor_no is not null
;
commit;

MERGE INTO MREP.BI_VENDORS HST
     USING (  SELECT VENDOR_ID VENDOR_ID, MAX (VENDOR_NAME) VENDOR_NAME
                FROM MREP.BI_VENDOR_WRK
            GROUP BY VENDOR_ID) TRN
        ON (TRN.VENDOR_ID = HST.VENDOR_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE,
   hst.vendor_name = trn.VENDOR_NAME
WHEN NOT MATCHED
THEN
   INSERT     (VENDOR_ID, VENDOR_NAME, ADD_DT)
       VALUES (TRN.VENDOR_ID, TRN.VENDOR_NAME, SYSDATE);

COMMIT;
------------------------------------------------------------

truncate table MREP.BI_CLASS_WRK;
INSERT
  /*+ append */
INTO  MREP.BI_CLASS_WRK
  (
    CLASS_ID ,
    DEPARTMENT_ID ,
    CLASS_NAME
  )
SELECT distinct lpad(class_no,3,'0'),
  lpad(dept_no,3,'0'),
  class_desc
from RFS.RF_DEPT_CLASS@SAKSRFS_PRD R
;
commit;

MERGE INTO MREP.BI_CLASS HST
     USING (  SELECT CLASS_ID CLASS_ID,
                     DEPARTMENT_ID DEPARTMENT_ID,
                     MAX (CLASS_NAME) CLASS_NAME
                FROM MREP.BI_CLASS_WRK
            GROUP BY CLASS_ID, DEPARTMENT_ID) TRN
        ON (TRN.CLASS_ID = HST.CLASS_ID
            AND TRN.DEPARTMENT_ID = HST.DEPARTMENT_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE,
   HST.CLASS_NAME = trn.CLASS_NAME
WHEN NOT MATCHED
THEN
   INSERT     (CLASS_ID,
               DEPARTMENT_ID,
               CLASS_NAME,
               ADD_DT)
       VALUES (TRN.CLASS_ID,
               TRN.DEPARTMENT_ID,
               TRN.CLASS_NAME,
               SYSDATE);

COMMIT;
----------------------------------------------------------------

MERGE INTO MREP.BI_VENDOR_HIER HST
     USING (  SELECT SUBSTR (category_id, 1, 1) DIVISION_ID,
                     SUBSTR (category_id, 2) GROUP_ID,
                     department_id DEPARTMENT_ID,
                     vendor_id Vendor_id
                FROM MREP.BI_ITEM_WRK
                where vendor_id is null
            GROUP BY SUBSTR (category_id, 1, 1),
                     SUBSTR (category_id, 2),
                     department_id,
                     vendor_id ) TRN
        ON (    TRN.DIVISION_ID = HST.DIVISION_ID
            AND TRN.DEPARTMENT_ID = HST.DEPARTMENT_ID
            AND TRN.GROUP_ID = HST.GROUP_ID
            AND TRN.VENDOR_ID = HST.VENDOR_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (DIVISION_ID,
               GROUP_ID,
               DEPARTMENT_ID,
               VENDOR_ID,
               ADD_DT)
       VALUES (TRN.DIVISION_ID,
               TRN.GROUP_ID,
               TRN.DEPARTMENT_ID,
               TRN.VENDOR_ID,
               SYSDATE);

COMMIT;
----------------------------------------------------------------------

-- BI_VENDOR_HIER 99997
MERGE INTO MREP.BI_VENDOR_HIER HST
     USING (  SELECT division_id DIVISION_ID,
                     GROUP_ID GROUP_ID,
                     department_id DEPARTMENT_ID,
                     '99997' VENDOR_ID
                FROM MREP.BI_VENDOR_HIER
            GROUP BY division_id, GROUP_ID, department_id) TRN
        ON (    TRN.DIVISION_ID = HST.DIVISION_ID
            AND TRN.DEPARTMENT_ID = HST.DEPARTMENT_ID
            AND TRN.GROUP_ID = HST.GROUP_ID
            AND TRN.VENDOR_ID = HST.VENDOR_ID)
WHEN MATCHED
THEN
   UPDATE SET HST.MODIFY_DT = SYSDATE
WHEN NOT MATCHED
THEN
   INSERT     (DIVISION_ID,
               GROUP_ID,
               DEPARTMENT_ID,
               VENDOR_ID,
               ADD_DT)
       VALUES (TRN.DIVISION_ID,
               TRN.GROUP_ID,
               TRN.DEPARTMENT_ID,
               TRN.VENDOR_ID,
               SYSDATE);

COMMIT;
----------------------------------------------------------------------------

--Refreshing Materilaized views:

exec dbms_mview.refresh ('SDDW.MV_BI_VENDORS','C');

exec dbms_mview.refresh ('SDDW.MV_BI_CLASS','C');


exit
