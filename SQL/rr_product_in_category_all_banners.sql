REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  product_in_category_sitename.sql
REM  DESCRIPTION:  It creates a data file with product heirarchy details
REM
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Unknown                      Unknown         Created
REM                Rajesh Mathew                        07/14/2010              Modified
REM ############################################################################
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set serverout on
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
set verify off
select 'category_id'||'|'||'product_id' from dual;

WITH atr_id AS
 (SELECT DECODE(atr_nm_lower,'folderactive',atr_id) fldr_atr_id,
               DECODE(atr_nm_lower,'readyforprodfolder',atr_id) rfp_atr_id
      FROM
               martini_main.attribute@&1
      WHERE atr_nm_lower IN ('folderactive' ,'readyforprodfolder')
          AND version = 1
          AND atr_status_cd = 'A'),
 oa_fld AS
   (SELECT oa.oba_obj_id
        FROM martini_main.object_attribute@&1 oa,
                  martini_main.object_attribute@&1  oa2,
                  atr_id
        WHERE oa.oba_atr_id =atr_id.fldr_atr_id
          AND oa.version = 1
         AND NVL(oa.oba_boo_val,'T')='T'
         AND  oa2.oba_atr_id = atr_id.rfp_atr_id
          AND oa.version = 1
         AND NVL(oa.oba_boo_val,'T')='T'
        AND oa.oba_obj_id = oa2.oba_obj_id
       UNION
        SELECT m.sba_id
          FROM martini_main.v_sub_assortment@&1 m,
          atr_id
        WHERE NOT EXISTS (SELECT 1 FROM martini_main.object_attribute@&1 WHERE oba_obj_id = m.sba_id AND oba_boo_val ='F' AND oba_atr_id = atr_id.fldr_atr_id)
             AND NOT EXISTS (SELECT 1 FROM martini_main.object_attribute@&1 WHERE oba_obj_id = m.sba_id AND oba_boo_val ='F' AND oba_atr_id = atr_id.rfp_atr_id)
             AND m.sba_status_cd ='A'
        ) ,
oa_st_dt AS
    (SELECT oa.oba_obj_id,oa.oba_dt_val rfp_st_dt
        FROM martini_main.object_attribute@&1 oa
       WHERE oa.oba_atr_id = (SELECT a.atr_id FROM martini_main.attribute@&1 a WHERE a.atr_nm_lower='readyforprodstarttime' AND  a.version = 1 AND a.atr_status_cd ='A')
         AND oa.version = 1
         AND oa.oba_dt_val IS NOT NULL),
oa_en_dt AS
    (SELECT oa.oba_obj_id,oa.oba_dt_val rfp_end_dt
        FROM martini_main.object_attribute@&1 oa
       WHERE oa.oba_atr_id = (SELECT a.atr_id FROM martini_main.attribute@&1 a WHERE a.atr_nm_lower='readyforprodendtime' AND  a.version = 1 AND a.atr_status_cd ='A')
         AND oa.version = 1
         AND oa.oba_dt_val IS NOT NULL),
oa_all AS
(SELECT
        oa_fld.oba_obj_id
   FROM oa_fld,oa_st_dt,oa_en_dt
  WHERE oa_fld.oba_obj_id = oa_st_dt.oba_obj_id(+)
   AND oa_fld.oba_obj_id = oa_en_dt.oba_obj_id(+)
       AND (NVL2(oa_st_dt.oba_obj_id,rfp_st_dt,SYSDATE) <= TRUNC(SYSDATE)
               OR NVL2(oa_en_dt.oba_obj_id,rfp_end_dt,SYSDATE) >= TRUNC(SYSDATE)))
SELECT category_id || '|' || product_id
FROM (
SELECT category_id , product_id
from (
select distinct to_char(rel_parent_id) category_id,
       rel_nm product_id
from martini_main.relationship@&1 r,
        martini_main.v_sub_assortment@&1 s,
        oa_all o
where r.rel_parent_id = s.sba_id
    and s.sba_id = o.oba_obj_id
and s.sba_status_cd <> 'D'
and ( (s.sba_path like '/Assortments/SaksMain/ShopCategory%')
or (s.sba_path like '/Assortments/SaksMain/Custom%'))
union
select distinct regexp_replace(replace(substr(s.sba_path_lower,regexp_instr(s.sba_path_lower,'/',1,4 )+1),'/','>'),'.$') category_id,
       rel_nm product_id
from martini_main.relationship@&1 r,
        martini_main.v_sub_assortment@&1 s,
        oa_all o
where  r.rel_parent_id = s.sba_id
    and s.sba_id = o.oba_obj_id
   and s.sba_status_cd <> 'D'
and ( (s.sba_path like '/Assortments/SaksMain/ShopCategory%')
or (s.sba_path like '/Assortments/SaksMain/Custom%'))
)
where  product_id is not null
);

exit;
