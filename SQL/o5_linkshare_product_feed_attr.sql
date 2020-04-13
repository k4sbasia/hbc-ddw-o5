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
    case when item_gender = '1' then 'Not Applicable'
        when  item_gender = '2' then 'Men'
        when  item_gender = '3' then 'Women'
        when  item_gender = '4' then 'Unisex'
        when  item_gender = '5' then 'Kids'
        when  item_gender = '6' then 'Pets'
        else item_gender
        end
    ||'|'||
     NULL ||'|'||
     null
    from &1.&3  wrk where wh_sellable_qty > 0;

select 'TRL' ||'|'||count(distinct upc) from &1.&3  where wh_sellable_qty > 0;

exit;
