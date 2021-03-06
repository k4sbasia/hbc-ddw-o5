REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_shoprunner_shipment_feed.sql
REM  DESCRIPTION:  This script prepares the XML data for SHOPRUNNER by fetching
REM                shipment related data
REM
REM
REM
REM  CODE HISTORY:           Name                  Date            Description
REM                          -----------------    ----------      --------------------------
REM                          Kallaar              06/20/2017       Created
REM
REM ############################################################################
SET serveroutput ON
SET feedback ON

EXEC DBMS_OUTPUT.PUT_LINE ('o5_shoprunner_shipment_feed starting at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

DECLARE
  xml_item CLOB;
BEGIN
  DBMS_OUTPUT.PUT_LINE ('Generate Daily file starting at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

  SELECT '<?xml version="1.0" encoding="UTF-8"?>'
    || '<!DOCTYPE ShippedList>'
    || XMLELEMENT( "Shipments", XMLELEMENT ("Partner", 'OFF5TH'),
	xmlagg( XMLELEMENT ("Shipment",
		XMLFOREST (
			RetailerOrderNumber AS "RetailerOrderNumber",
			CarrierCode AS "CarrierCode",
			TrackingNumber AS "TrackingNumber",
			NumberOfItems AS "NumberOfItems",
			NumberOfSRItems AS "NumberOfSRItems")))).EXTRACT ('/*').getclobVal ()
  INTO xml_item
  FROM
    (SELECT DISTINCT bs.ordernum RetailerOrderNumber,
      tsm.shm_carrier  CarrierCode,
      bs.TRACKING_NUMBER TRACKINGNUMBER,
      SUM(bs.qtyordered) over( partition BY bs.ordernum) qtyordered,
      SUM(bs.qtyordered) over( partition BY bs.ordernum,bs.TRACKING_NUMBER) NumberOfItems,
      SUM( (
      CASE
        WHEN (bs.SRIND='Y')
        THEN 1
        ELSE 0
      END)*bs.qtyordered) over( partition BY bs.ordernum,bs.TRACKING_NUMBER) NumberOfSRItems,
       nvl(o5.F_GET_ORDER_TOKEN(bs.ORDERNUM),sr_token) "SRAUTHENTICATIONTOKEN"
      FROM o5.BI_SALE bs
join o5.T_SHIPMENT_METHOD tsm on bs.shipmethod = shm_id
  WHERE bs.shipdate    >=TRUNC(sysdate-1)
  AND bs.shipdate       <TRUNC(sysdate)
    )
  WHERE SRAUTHENTICATIONTOKEN IS NOT NULL;
  DBMS_XSLPROCESSOR.clob2file(xml_item, 'DATASERVICE', 'o5_shoprunner_shipment_feed.xml');
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('Generate Daily file completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

SHOW ERRORS;

EXEC DBMS_OUTPUT.PUT_LINE ('o5_shoprunner_shipment_feed completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXIT;
