REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  cheetah_xml_data.sql
REM  DESCRIPTION:  This script prepares the XML data for CHEETA by fetching data
REM                BV_CHEETAH_EXTRACT table
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                Rajesh Mathew                08/23/2010              Created
REM                Divya KAfle                  05/16/2013              Modified
REM
REM ############################################################################
set serveroutput on
set feedback on
DECLARE
xml_item   CLOB;
BEGIN
SELECT '<?xml version="1.0" encoding="iso-8859-1"  standalone="yes"?>'||xmlelement("document",xmlattributes (TO_CHAR (SYSTIMESTAMP, 'YYYYMMDDHH24MISS') AS "created",'1.0' AS "version"),XMLELEMENT ("service", 'ebmtrigger1'),
XMLELEMENT ("report_email_notify", 'hbcdigtialdatamanagement@hbc.com'),
xmlagg(
            XMLCONCAT (
               XMLELEMENT (
                  "request",
                  xmlattributes (request_id AS "request_id"),
                  XMLCONCAT (
                     XMLELEMENT ("eid", 237886),
                     XMLELEMENT ("aid", 682906452),
					 XMLELEMENT ("EMAIL_ID", ''),
                     XMLELEMENT ("CUSTOMER_ID", customer_id),
                     XMLELEMENT ("DATE_SENT", to_char(sysdate, 'YYYY-MM-DD')),
                     XMLELEMENT ("email", email),
                     XMLELEMENT ("NAME", customer_first_name),
                     XMLELEMENT ("b", 1),
                     XMLELEMENT ("cb", 2),
                     XMLAGG (
                        XMLELEMENT (
                           "ITEM",
                           XMLFOREST (
                              image_url AS "PROD_IMG_URL",
                              PRODUCT_ID AS "PRODUCTID",
                              XMLCDATA(brand) AS "BRAND",
                              XMLCDATA(o5.ENCD_TO_CHAR_CONVERSION(SHRT_PROD_DESC)) AS "SHRT_PROD_DESC",
                                                          XMLCDATA (o5.ENCD_TO_CHAR_CONVERSION(PRODUCTCOPY)) AS "LONG_PROD_DESC",
                              DATE_SHIPPED AS "DATE_SHP",
                              BM_PRD_ID AS "BM_PRODUCT_ID",
                              mrep.convert_string_to_md5 (email) AS "USERID",
                                replace(replace(o5.turn_to_convert_base64(turntoord),chr(13),''),chr(10),'') AS "TURNTOORD"
                              )))))))).
          EXTRACT ('/*').getclobVal () into xml_item
    FROM  o5.TURN_TO_CHEETAH_EXTRACT a where item_exclude='F' and email is not null and product_id is not null
        and a.brand is not null and a.SHRT_PROD_DESC is not null and a.PRODUCTCOPY is not null AND turntoord IS NOT NULL AND request_id IS NOT NULL
        and email NOT LIKE 'E4X%'--and a.BM_PRD_ID is not null 
and add_dt = TRUNC (SYSDATE)
GROUP BY customer_id, email,customer_first_name,request_id order by request_id;
DBMS_XSLPROCESSOR.clob2file(xml_item, 'DATASERVICE', 'Off5th_ppe_'||to_char(sysdate,'YYYYMMDD')||'.xml');
END;
/
exit;
