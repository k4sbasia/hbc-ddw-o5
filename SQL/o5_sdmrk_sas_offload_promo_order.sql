whenever sqlerror exit failure
set pagesize 0
set tab off
SET LINESIZE 10000
set feedback off
SELECT 'ordernum' || ',' ||
  'promo_id_01' || ',' ||
  'promo_id_02' || ',' ||
  'promo_id_03' || ',' ||
  'promo_id_04' || ',' ||
  'promo_id_05' || ',' ||
  'promo_id_06' || ',' ||
  'promo_id_07' || ',' ||
  'promo_id_08' || ',' ||
  'PROMO_ID_09' || ',' ||
  'promo_id_10'
from DUAL
;

SELECT ordernum || ',' ||
  PROMO_ID_01 || ',' ||
  trim(promo_id_02) || ',' ||
  promo_id_03 || ',' ||
  promo_id_04 || ',' ||
  promo_id_05 || ',' ||
  promo_id_06 || ',' ||
  promo_id_07 || ',' ||
  promo_id_08 || ',' ||
  PROMO_ID_09 || ',' ||
  PROMO_ID_10
from SDMRK.O5_PROMO_ORDERS
;
exit
