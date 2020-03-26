SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
SET TIMING ON


UPDATE &1.media_manifest  a
  SET a.is_comp_swatch = 'Y'
WHERE  EXISTS (select 1 from &1.all_active_pim_sku_attr_&2 s
where sku_status = 'Yes' and  a.asset_id = s.upc);
commit;

quit
commit;

quit
