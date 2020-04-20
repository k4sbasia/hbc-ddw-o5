REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_product_feed_bm.sql
REM  DESCRIPTION:  This script loads required data for shoprunner product feed
REM						from BLUE MARTINI
REM
REM
REM
REM  CODE HISTORY: Name                     Date            Description
REM                -----------------        ----------      ---------------
REM                Kallaar         			06/05/2017   	CREATED
REM
REM#############################################################################
SET ECHO ON
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET TIMING ON
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

-- Only the other sql will execute : Remove after SFCC went live
