set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set serverout on
SELECT    'GROSSSALE'
       || ' '
       || 'GROSSRETURN'
       || ' '
       || 'SALEDISCOUNT'
       || ' '
       || 'RETURNDISCOUNT'
       || ' '
       || 'SALEMARKDOWN'
       || ' '
       || 'RETURNMARKDOWN'
       || ' '
       || 'SALEQTY'
       || ' '
       || 'RETURNQTY'||CHR(10)
  FROM DUAL;
select '      ' from dual;
SELECT 'NETSALE :-'||to_char(SUM (grosssale))
       || ' '
       || to_char(SUM (grossreturn))
       || ' '
       || to_char(SUM (salediscount))
       || ' '
       || to_char(SUM (returndiscount))
       || ' '
       || to_char(SUM (salemarkdown))
       || ' '
       || to_char(SUM (returnmarkdown))
       || ' '
       || to_char(SUM (saleqty))
       || ' '
       || to_char(SUM (returnqty))||CHR(10)
  FROM O5.bi_netsale
 WHERE TRUNC (add_dt) = TRUNC (SYSDATE) AND skupc_ind != 'R';
select '      ' from dual;
 SELECT  'SUMMARY :-'||  to_char(grosssale)
       || ' '
       || to_char(grossreturn)
       || ' '
       || to_char(salediscount)
       || ' '
       || to_char(returndiscount)
       || ' '
       || to_char(salemarkdown)
       || ' '
       || to_char(returnmarkdown)
       || ' '
       || to_char(saleqty)
       || ' '
       || to_char(returnqty)||CHR(10)
  FROM O5.bi_netsale_sum where TRUNC(add_dt)=Trunc(sysdate); 
 exit;

