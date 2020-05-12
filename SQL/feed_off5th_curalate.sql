REM ############################################################################
REM                        Saks Direct
REM ############################################################################
REM
REM  CODE HISTORY:   Name               Date            Description
REM                -----------------    ----------      --------------------------
REM                 David Alexander     08/28/2017      SQL Script for Curalate Product Feed.
REM
REM
REM ############################################################################
set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE

SELECT 'product_id,product_title,product_url,image_url,grouping_id'
FROM dual
;
SELECT DISTINCT manufacturer_part#
  ||','
  || replace(product_name,',', ' ')
  ||','
  || product_url
  ||','||
  product_image_url
  ||','
  || (
    case when itm_gender = 1 then 'N/A'
       when itm_gender  = 2 then 'Men'
      when itm_gender  = 3 then 'Women'
       when itm_gender  = 4 then 'Unisex'
       when itm_gender  = 5 then 'Kids'
        when  itm_gender  = 6 then 'Pets'
      else 'N/A'
      end)
  ||' > '
 ||  RegExp_substr(path,'[^/]+',1,+regexp_count(path,'[^/]+'))
  ||','
  || manufacturer_part#
FROM o5.channel_advisor_extract_new t1
where  qty_on_hand > 0
;
exit
