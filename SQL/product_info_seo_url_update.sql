SET ECHO OFF
SET TIMING ON
SET LINESIZE 10000
SET PAGESIZE 0
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
BEGIN
 DBMS_OUTPUT.PUT_LINE('Truncating &3 table started:  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));

 EXECUTE IMMEDIATE 'truncate table &1.&3';

 DBMS_OUTPUT.PUT_LINE('Truncating  &3 table Ended :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('SEO URL UPDATE from PIM Attribute Process Started : :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));

INSERT
INTO &1.&3
  (
    PRODUCT_CODE,
    SEO_URL,
    UPDATED_ON
  )
SELECT product_id,
'https://staging-na02-hbc.demandware.net/s/Saksoff5th/product/'
||lower(brand_name)
||'-'
||lower(bm_desc)
||'-'
||product_id
||'.html' en_seo_url,
updated_on
FROM
  ( WITH all_product_attributes AS
  (SELECT product_id,
    &1.SEO_CHAR_CONVERSION(TRIM(bm_desc)) bm_desc,
   &1.SEO_CHAR_CONVERSION(TRIM(brand_name)) brand_name
  FROM &1.all_active_pim_prd_attr_&2
  WHERE bm_desc IS NOT NULL
  )
SELECT product_id,
  MAX(bm_desc)    AS bm_desc,
  MAX(brand_name) AS brand_name,
  trunc(sysdate) updated_on
FROM all_product_attributes
GROUP BY product_id
);
COMMIT;

DBMS_OUTPUT.PUT_LINE('SEO URL UPDATE from PIM Attribute Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
END;
/
exit
