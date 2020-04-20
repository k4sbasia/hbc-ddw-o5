SET SERVEROUTPUT ON
SET FEEDBACK ON

DECLARE
   xml_item   CLOB;
BEGIN
     SELECT '<?xml version="1.0" encoding="iso-8859-1"  standalone="yes"?>'
            || XMLELEMENT (
                  "document",
                  xmlattributes (
                     TO_CHAR (SYSTIMESTAMP, 'YYYYMMDDHH24MISS') AS "created",
                     '1.0' AS "version"),
                  XMLELEMENT ("service", 'ebmtrigger1'),
                  XMLELEMENT ("report_email_notify",
                              'hbcdigtialdatamanagement@hbc.com'),
                  XMLAGG (
                     XMLCONCAT (
                        XMLELEMENT (
                           "request",
                           xmlattributes (request_id AS "request_id "),
                           XMLCONCAT (
                              XMLELEMENT ("eid", '228592'),
                              XMLELEMENT ("aid", '682906452'),
                              XMLELEMENT ("email", w.email),
			      XMLELEMENT ("EMAIL_ID", e.email_id),
                              XMLELEMENT ("b", 1),
                                XMLAGG (
                                 XMLELEMENT (
                                    "ITEM",
                                    XMLFOREST (
                                       XMLCDATA (W.BRAND_NAME) AS "BRAND_NAME",
                                       XMLCDATA (W.ITEM_DESC) AS "ITEM_DESCRIPTION",
                                       XMLCDATA (W.SKU_COLOR) AS "SKU_COLOR",
                                       W.SKU_SIZE AS "SKU_SIZE",
                                       TRIM(TO_CHAR(W.SKU_PRICE, '$99,999,999.99')) AS "SKU_PRICE",
                                       XMLCDATA (W.ITEM_URL) AS "PRODUCT_PAGE_URL",
                                       XMLCDATA (W.product_code) AS "PRODUCT_ID",
                                       XMLCDATA (W.IMAGE_URL) AS "IMAGE_URL",
                                       TRIM(TO_CHAR(W.COMPARE_PRICE, '$99,999,999.99')) AS "COMPARE_PRICE",
                                       W.QTY AS "QUANTITY")))))))).EXTRACT (
                  '/*').getclobVal ()
       INTO xml_item
       FROM &1.EDB_WAITLIST_EXTRACT_WRK W,
            &1.EMAIL_ADDRESS E
        where w.item_desc is not null and w.brand_name is not null and TRIM(TO_CHAR(W.COMPARE_PRICE, '$99,999,999.99')) is not null 
        and   W.email = E.email_address(+)
   GROUP BY
        w.request_id,
        w.EMAIL,
        e.EMAIL_ID
   ORDER BY w.request_id asc;

   DBMS_XSLPROCESSOR.clob2file (
      xml_item,
      'DATASERVICE',
      'o5_waitlist_notification_' || TO_CHAR (SYSDATE, 'YYYYMMDD') || '.xml');
END;
/
exit;

