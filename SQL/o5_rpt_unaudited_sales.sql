REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM 
REM  CODE HISTORY: Name	               		Date 	       	Description
REM                -----------------	  	----------  	--------------------------
REM                Jayanthi             06/09/2011                Created
REM ############################################################################
set linesize 1000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
set serverout on

select 'The data contained in this report is Off 5th.com un-audited.' from dual;

Select 'DMD    '||'  :'||'$'||Ltrim(To_Char(Demand_$,'999,999,999,999')) Xxxxxxxxy From O5.Unaudited_Sales;
SELECT 'BO    '||'      :'||'$'||nvl(ltrim(TO_CHAR(BACKORDER_$,'999,999,999,999')), 0)  XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT 'BO%    '||'  :'||nvl(ROUND(BACKORDER_$*100/ DEMAND_$),0) ||'%' XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT 'CXL  '||'     :'||'$'||ltrim(TO_CHAR(CANX_$,'999,999,999,999')) XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT 'CXL% '||'  :'||ROUND(CANX_$*100/ DEMAND_$)||'%' XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT 'GRS     '||'  :'||'$'||ltrim(TO_CHAR(GROSS_$,'999,999,999,999')) XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT 'RET        '||':'||'('||'$'||ltrim(TO_CHAR(ABS(RETURN_$),'999,999,999,999'))||')' XXXXXXXXY FROM O5.UNAUDITED_SALES;
SELECT
  Case When
     Return_$ = 0 Then
    'RET%  '||' :'||'0%'
  else 
    'RET%  '||'  :'||ROUND((ABS(RETURN_$)/GROSS_$)*100)||'%' 
   end case FROM O5.UNAUDITED_SALES;
SELECT 'NET       '||' :'||'$'||ltrim(TO_CHAR(NET_$,'999,999,999,999')) XXXXXXXXY FROM O5.UNAUDITED_SALES;

exit;
