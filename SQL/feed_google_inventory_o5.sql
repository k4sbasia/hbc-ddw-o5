whenever sqlerror exit failure
set linesize 32767
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on
set verify off



select 'retailstoreid' ||chr(9) ||
 'itemid' ||chr(9) ||
 'price' ||chr(9) ||
 'sale price' ||chr(9) ||
 'quantity'
 from  Dual;


 select distinct substr(ship_node,2,4) ||chr(9) ||
 Lpad(a.UPC,13,'0') ||chr(9) ||
 to_char(a.CUR_TKT_PRICE_DOL,'FM999999.00') ||chr(9) ||
 null ||chr(9) ||
 b.ONHAND_AVAILABLE_QUANTITY
from
( select s.CUR_TKT_PRICE_DOL,o.UPC, o.skn_no from O5.OMS_RFS_O5_STG s, O5.STG_GOOGLE_FEED_O5 o
Where o.upc = s.UPC ) a,
(select item_id,SHIPNODE_KEY ship_node ,ATP -PICKUP_SS  ONHAND_AVAILABLE_QUANTITY  from  O5.O5_OMS_COMMON_INV
  where trim(ORGANIZATION_CODE) = 'OFF5' and trim(SHIPNODE_KEY) not in ('DC-LVG-789','DC-789-593')
--and trim(SHIPNODE_KEY) in ('7843','7842')
and ATP - PICKUP_SS >=2) b
Where a.skn_no = trim(b.item_id);

Exit;
