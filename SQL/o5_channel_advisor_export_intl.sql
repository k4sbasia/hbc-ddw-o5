SET echo OFF
SET feedback OFF
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF
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
