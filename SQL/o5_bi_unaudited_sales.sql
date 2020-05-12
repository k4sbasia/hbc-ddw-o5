set linesize 30
set heading off
column eol newline
--column DMD format $999,999,999
--column BO format a12
--column CNX format  a12
--column GROSS format a12
--column RET format a12
--column NET format  a12
--column BO% format a4
--column CXL% format a4
--column RET% format a4
ttitle center 'O5 Un-Audited Sales Report'
SELECT
    'DMD'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."TOTAL_DEMAND_DOLLARS"), '999,999,999')) dmd,
    'BO'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."BORD_DEMAND_DOLLARS"), '999,999,999')) bo,
    'CNX'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."CANCEL_DOLLARS"), '999,999,999')) cnx,
    'GROSS'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."GROSS_DOLLARS"), '999,999,999')) gross,
    'RET'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."RETURN_DOLLARS"), '999,999,999')) ret,
    'NET'
    || ' '
    || '$'
    || TRIM(to_char(SUM("BI_PSA"."NET_DOLLARS"), '999,999,999')) net,
    'BO%'
    || ' '
    || round(SUM("BI_PSA"."BORD_DEMAND_DOLLARS") / nullif(SUM("BI_PSA"."TOTAL_DEMAND_DOLLARS"), 0) * 100)
    || '%' "BO%",
    'CXL%'
    || ' '
    || round(SUM("BI_PSA"."CANCEL_DOLLARS") / nullif(SUM("BI_PSA"."TOTAL_DEMAND_DOLLARS"), 0) * 100)
    || '%' "CXL%",
    'RET%'
    || ' '
    || round(SUM("BI_PSA"."RETURN_DOLLARS") / nullif(SUM("BI_PSA"."GROSS_DOLLARS"), 0) * 100)
    || '%' "RET%"
FROM "O5"."BI_PSA"                "BI_PSA",
     "O5"."BI_VDATEKEY_CURRENT"   "BI_DATEKEY_CURRENT"
WHERE "BI_PSA"."DIVISION_ID" IN (1, 2, 3, 4, 6, 7, 8)
  AND "BI_PSA"."DIVISION_ID" NOT IN (5, 9)
  AND "BI_DATEKEY_CURRENT"."DATEKEY" = "BI_PSA"."DATEKEY"
GROUP BY to_char("BI_DATEKEY_CURRENT"."DATEKEY", 'Mon DD, YYYY'), "BI_PSA"."DATEKEY"
;
EXIT;
