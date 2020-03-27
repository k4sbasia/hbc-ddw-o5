REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_bi_promo_parse.sql
REM  DESCRIPTION:  It creates a data file with promo details
REM
REM
REM
REM
REM
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
SELECT DISTINCT    ordernum
                || '|'
                || REPLACE (LTRIM (oba_str_val), ',', '|')
                || '||||||||||||'
           FROM (
             SELECT orderhdr, ordernum,
                                    promo_id
                               FROM &1.bi_sale
                              WHERE  orderdate > SYSDATE - 14)
;
commit ;
spool off
exit;
