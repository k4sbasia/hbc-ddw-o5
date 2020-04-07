REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_feed_vendornet_extract_new.sql
REM  DESCRIPTION:  This code does the following.
REM                1. Extract the data for Dropship items for vendornet
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Hars Desai                 03/18/2019              Created
REM
REM ############################################################################
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on

SELECT    'OrderType'
       || '|'
       || 'SKU'
       || '|'
       || 'Description'
       || '|'
       || 'VendorCode'
       || '|'
       || 'vendorSKU'
       || '|'
       || 'Vendordesc'
       || '|'
       || 'UPCCode'
       || '|'
       || 'LeadDays'
       || '|'
       || 'svs'
       || '|'
       || 'UnitWeight'
       || '|'
       || 'Banner'
  FROM DUAL;
SELECT    ordertype
       || '|'
       || to_number(sku)
       || '|'
       || sku_description
       || '|'
       || vendorcode
       || '|'
       || vendorsku
       || '|'
       || vendordesc
       || '|'
       || upc
       || '|'
       || leaddays
       || '|'
       || PRODUCT_ID
       || '|'
       || unit_wt_lbs
       || '|'
       || 'OFF5'
  FROM o5.bi_vendornet_prod_new where add_dt=trunc(sysdate) and readyforprod='T';

  quit;
