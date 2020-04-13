set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT 'HDR'||'|'||'38801'||'|'||'&5'||'|'||TO_DATE(SYSDATE,'YYYY-MM-DD/HH:MI:SS') FROM DUAL;

select UPC||'|'||
    '60'||'|'||
    NULL||'|'||
    CASE WHEN PATH IS NULL THEN CATEGORY else path end  ||'|'||
    SKU_SIZE1_DESC||'|'||
    NULL||'|'||
    SKU_COLOR||'|'||
              case when &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 1 then 'Not Applicable'
                   WHEN &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 2 THEN 'Men'
                   WHEN &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 3 THEN 'Women'
                   WHEN &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 4 THEN 'Unisex'
                   WHEN &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 5 THEN 'Kids'
                   WHEN &1.&2_GETATTRVALBYOBJECT (prd_parent_id,'item_gender',1) = 6 THEN 'Pets'
                else NULL
                end ||'|'||
     NULL ||'|'||
     null
    from &1.&3  wrk where wh_sellable_qty > 0;

select 'TRL' ||'|'||count(distinct upc) from &1.&3  where wh_sellable_qty > 0;

exit;
