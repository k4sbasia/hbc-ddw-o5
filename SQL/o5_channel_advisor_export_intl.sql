set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
select
 'Product_Id'
       || '|'
       || 'Qty_On_Hand'
       || '|'
       || 'AUD_Sale_Price'
       || '|'
       || 'GBP_Sale_Price'
       || '|'
       || 'CHF_Sale_price'
       || '|'
       || 'CAD_Sale_Price'
       || '|'
       || 'AU_Publish'
       || '|'
       || 'UK_Publish'
       || '|'
       || 'CH_Publish'
       || '|'
       || 'CA_Publish'
from dual;

SELECT
  UPC
  || '|'
  || QTY_ON_HAND
  || '|'
  ||  AUD
  || '|'
  ||  GBP
  || '|'
  ||  CHF
  || '|'
  ||  CAD
  || '|'
  || AU_PUBLISH
  || '|'
  || UK_PUBLISH
  || '|'
  || CH_PUBLISH
  || '|'
  || CA_PUBLISH
FROM &1.CHANNEL_ADVISOR_EXTRACT_NEW;
EXIT;
