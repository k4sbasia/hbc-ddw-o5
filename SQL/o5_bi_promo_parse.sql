REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_bi_promo_parse.sql
REM  DESCRIPTION:  It creates a data file with promo details
REM
REM  CODE HISTORY: Name	               		Date 	       	Description
REM                -----------------	  	----------  	--------------------------
REM                Unknown     		      	Unknown     	Created
REM                Rajesh Mathew			08/05/2010		Modified
REM ############################################################################
set echo off
set feedback off
set sqlprompt ''
set heading off
set pagesize 0
set serverout off
set linesize 1000

SELECT DISTINCT
    ordernum
    || '|'
    || replace(ltrim(oba_str_val), ',', '|')
    || '||||||||||||'
FROM
    (
        SELECT
            ordernum,
            promo_id oba_str_val
        FROM o5.bi_sale
        WHERE orderdate > sysdate - 14
    );

SPOOL OFF;
EXIT;