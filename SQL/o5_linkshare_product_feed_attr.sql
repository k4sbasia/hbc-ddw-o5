set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
SELECT 'HDR'||'|'||'38801'||'|'||'SAKSOFF5TH'||'|'||TO_DATE(SYSDATE,'YYYY-MM-DD/HH:MI:SS') FROM DUAL;

select UPC||'|'||
    '60'||'|'||
    NULL||'|'||
    CASE WHEN PATH IS NULL THEN CATEGORY else path end  ||'|'||
    SKU_SIZE1_DESC||'|'||
    NULL||'|'||
    SKU_COLOR||'|'||
              case when O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 1 then 'Not Applicable'
                   WHEN O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 2 THEN 'Men'
                   WHEN O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 3 THEN 'Women'
                   WHEN O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 4 THEN 'Unisex'
                   WHEN O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 5 THEN 'Kids'
                   WHEN O5.O5_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 6 THEN 'Pets'
                else NULL
                end ||'|'||
     NULL ||'|'||
     null
    from &1.O5_PARTNERS_EXTRACT_WRK  wrk where wh_sellable_qty > 0;

select 'TRL' ||'|'||count(distinct upc) from &1.O5_PARTNERS_EXTRACT_WRK  where wh_sellable_qty > 0;

exit;
