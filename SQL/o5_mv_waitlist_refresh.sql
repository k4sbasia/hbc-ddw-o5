
whenever sqlerror exit failure
set serveroutput on
set pagesize 0
set tab off
SET LINESIZE 10000
set timing on

exec DBMS_MVIEW.refresh('SDMRK.O5_MV_WAITLIST', 'C', ATOMIC_REFRESH => false);

exit;