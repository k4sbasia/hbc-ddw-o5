REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_shoprunner_order_feed.sql
REM  DESCRIPTION:
REM
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                  Date          Description
REM                -----------------    ----------   --------------------------
REM                Kallaar              06/19/2017      Created
REM
REM ############################################################################
SET TIMING ON
SET FEEDBACK ON
SET SERVEROUTPUT ON

EXEC DBMS_OUTPUT.PUT_LINE ('o5_shoprunner_order_feed.sql started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

TRUNCATE TABLE O5.SR_ORDER_FEED;

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.SR_ORDER_FEED started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

INSERT
INTO O5.SR_ORDER_FEED
  (SELECT DISTINCT ORDERNUMBER,
      ORDERDATE,
      SRAUTHENTICATIONTOKEN,
      SUM(TOTALNUMBEROFITEMS) OVER( PARTITION BY ORDERNUMBER) TOTALNUMBEROFITEMS,
      SUM(TOTALNUMBEROFSHOPRUNNERITEMS) OVER( PARTITION BY ORDERNUMBER) TOTALNUMBEROFSHOPRUNNERITEMS,
      CURRENCYCODE,
      SUM(ORDERTOTAL) OVER( PARTITION BY ORDERNUMBER) ORDERTOTAL,
      SUM(BILLINGSUBTOTAL) OVER( PARTITION BY ORDERNUMBER) BILLINGSUBTOTAL,
      CASE
        WHEN (PAYMENTTENDERTYPE='AMEX')
        THEN 'AX'
        WHEN (PAYMENTTENDERTYPE='PAYPAL')
        THEN 'PP'
        WHEN (PAYMENTTENDERTYPE='SAKS')
        THEN 'PL'
        WHEN (PAYMENTTENDERTYPE='VISA')
        THEN 'VI'
        WHEN (PAYMENTTENDERTYPE='JCB')
        THEN 'JC'
        WHEN (PAYMENTTENDERTYPE='MC')
        THEN 'MC'
        WHEN (PAYMENTTENDERTYPE='DINERS')
        THEN 'DC'
        WHEN (PAYMENTTENDERTYPE='DISC')
        THEN 'DI'
        ELSE 'OT'
      END PAYMENTTENDERTYPE,
      CASE
        WHEN(ADJUSTMENTTYPE IS NOT NULL)
        THEN ADJUSTMENT
      END ADJUSTMENT,
      CASE
        WHEN(ADJUSTMENTTYPE IS NOT NULL)
        THEN ADJUSTMENTDATE
      END "ADJUSTMENTDATE",
      CASE
        WHEN(ADJUSTMENTTYPE IS NOT NULL)
        THEN ADJUSTMENTAMOUNT
      END ADJUSTMENTAMOUNT,
      CASE
        WHEN(ADJUSTMENTTYPE IS NOT NULL)
        THEN BILLINGADJAMT
      END BILLINGADJAMT ,
      ADJUSTMENTTYPE,
      CASE
        WHEN(ADJUSTMENTTYPE IS NOT NULL)
        THEN ADJUSTMENTREASON
      END ADJUSTMENTREASON,
      NULL AdjustmentId,
      sysdate-1
    FROM
      (SELECT PARTNER,
        VERSIONNUMBER,
        ORDERNUMBER,
        ORDERDATE,
        SRAUTHENTICATIONTOKEN,
        (TOTALORDER  -NVL(TOTALRETURNSCANCELS,0))TOTALNUMBEROFITEMS ,
        (TOTALSRITEMS-NVL(TOTALNUMBEROFSHOPRUNNERITEMS,0)) TOTALNUMBEROFSHOPRUNNERITEMS,
        BILLINGADJAMT,
        CURRENCYCODE,
        ROUND(
        CASE
          WHEN(ADJUSTMENTAMOUNT>0)
          THEN (ORDERTOTAL-ADJUSTMENTAMOUNT)
          ELSE ORDERTOTAL
        END,3) ORDERTOTAL,
        ROUND(
        CASE
          WHEN(ADJUSTMENTAMOUNT>0)
          THEN (BILLINGSUBTOTAL-(ADJUSTMENTAMOUNT-TAX))
          ELSE BILLINGSUBTOTAL
        END,3) BILLINGSUBTOTAL,
        PAYMENTTENDERTYPE,
        ADJUSTMENT,
        ADJUSTMENTDATE,
        ADJUSTMENTAMOUNT,
        ADJUSTMENTTYPE,
        ADJUSTMENTREASON
      FROM
        (SELECT 'SAKS' "PARTNER",
          '3.0.1' "VERSIONNUMBER",
          BS.ORDERNUM "ORDERNUMBER",
          BS.ORDERDATE "ORDERDATE",
          nvl(o5.F_GET_ORDER_TOKEN(BS.ORDERNUM),sr_token) "SRAUTHENTICATIONTOKEN",
          SUM(BS.QTYORDERED) "TOTALORDER",
          SUM(
          CASE
            WHEN ( BS.SRIND ='Y')
            THEN 1*NVL(BS.QTYORDERED,1)
            ELSE 0
          END) "TOTALSRITEMS",
          SUM (
          CASE
            WHEN ((BS.ORDLINE_STATUS = 'X')
            OR (BS.ORDLINE_STATUS    = 'R'))
            THEN 1*NVL(BS.QTYORDERED,1)
            ELSE 0
          END )"TOTALRETURNSCANCELS", -- new one
          SUM(
          CASE
            WHEN ((BS.ORDLINE_STATUS = 'X')
            OR (BS.ORDLINE_STATUS    = 'R'))
            THEN bs.extend_price_amt
            ELSE 0
          END ) AS "BILLINGADJAMT",
          SUM(
          CASE
            WHEN ( (BS.SRIND        ='Y')
            AND ((BS.ORDLINE_STATUS = 'X')
            OR (BS.ORDLINE_STATUS   = 'R')))
            THEN 1*NVL(BS.QTYORDERED,1)
            ELSE 0
          END) "TOTALNUMBEROFSHOPRUNNERITEMS",
          'USD' "CURRENCYCODE",
          SUM(NVL(BS.EXTEND_PRICE_AMT,0) +NVL(NVL(BS.TAXRATE_AMT,BS.LINE_TAX),0)+NVL(BS.TAX_ON_SHIPPING,0)+NVL(BS.GIFT_WRAP_FEE,0)) "ORDERTOTAL",
          SUM(NVL(BS.EXTEND_PRICE_AMT,0) ) "BILLINGSUBTOTAL",
          SUM(NVL(NVL(BS.TAXRATE_AMT,BS.LINE_TAX),0)+NVL(BS.TAX_ON_SHIPPING,0)) TAX,
          BS.CCD_BRAND "PAYMENTTENDERTYPE",
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN 'CANCEL'
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN 'RETURN'
          END "ADJUSTMENT",
          BS.ADD_DT "ADJUSTMENTDATE",
          SUM(
          CASE
            WHEN ((BS.ORDLINE_STATUS = 'X')
            OR (BS.ORDLINE_STATUS    = 'R'))
            THEN NVL(BS.EXTEND_PRICE_AMT,0)+NVL(NVL(BS.TAXRATE_AMT,BS.LINE_TAX),0)+NVL(BS.GIFT_WRAP_FEE,0)+NVL(BS.TAX_ON_SHIPPING,0)
            ELSE 0
          END) "ADJUSTMENTAMOUNT",
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN 'CANCEL'
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN 'RETURN'
          END "ADJUSTMENTTYPE",
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN BCRC.CANCEL_CODE_DESCRIPTION
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN --rr.DESCRIPTION
              CASE
                WHEN RETURNREASON = '1'
                THEN 'Problem with sizing'
                WHEN RETURNREASON = '2'
                THEN 'Item not as depicted'
                WHEN RETURNREASON = '3'
                THEN 'Incorrect item sent'
                WHEN RETURNREASON = '4'
                THEN 'Item was damaged/defective'
                WHEN RETURNREASON = '5'
                THEN 'Changed mind'
                WHEN RETURNREASON = '6'
                THEN 'Arrived late'
                WHEN RETURNREASON = '7'
                THEN 'Other pieces not received'
                WHEN RETURNREASON = '8'
                THEN 'Dissatisfied with quality'
                WHEN RETURNREASON = '9'
                THEN 'No reason'
              END
          END "ADJUSTMENTREASON"
        FROM O5.BI_SALE BS,
          O5.BI_PRODUCT BP,
          MREP.CANCEL_REASON_CODE BCRC
        WHERE BS.SKU            =BP.SKU
        AND BP.DEACTIVE_IND = 'N'
        AND BS.PRODUCT_ID       =BP.UPC
        AND BS.CANCELREASON     =BCRC.CANCEL_CODE(+)
        AND BS.ORDERMODIFYDATE >=TRUNC(SYSDATE-1)
        AND BS.ORDERMODIFYDATE  <TRUNC(SYSDATE)
        AND BS.SRIND            ='Y'
        AND BS.ORDHDR_STATUS!   ='N'
        GROUP BY BS.ORDERNUM,
          BS.ORDERDATE,
          nvl(o5.F_GET_ORDER_TOKEN(BS.ORDERNUM),sr_token),
          BS.CCD_BRAND,
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN 'CANCEL'
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN 'RETURN'
          END ,
          BS.ADD_DT ,
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN 'CANCEL'
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN 'RETURN'
          END,
          CASE
            WHEN (BS.ORDLINE_STATUS = 'X')
            THEN bcrc.CANCEL_CODE_DESCRIPTION
            WHEN (BS.ORDLINE_STATUS = 'R')
            THEN --rr.DESCRIPTION
              CASE
                WHEN RETURNREASON = '1'
                THEN 'Problem with sizing'
                WHEN RETURNREASON = '2'
                THEN 'Item not as depicted'
                WHEN RETURNREASON = '3'
                THEN 'Incorrect item sent'
                WHEN RETURNREASON = '4'
                THEN 'Item was damaged/defective'
                WHEN RETURNREASON = '5'
                THEN 'Changed mind'
                WHEN RETURNREASON = '6'
                THEN 'Arrived late'
                WHEN RETURNREASON = '7'
                THEN 'Other pieces not received'
                WHEN RETURNREASON = '8'
                THEN 'Dissatisfied with quality'
                WHEN RETURNREASON = '9'
                THEN 'No reason'
              END
          END,
          BS.ORDLINE_STATUS
        ) X
      )
    WHERE NVL(ADJUSTMENTREASON,'NO REASON')!=' Customer CNXL - 20 Minute Window'
    AND SRAUTHENTICATIONTOKEN              IS NOT NULL
  ) ;

EXEC DBMS_OUTPUT.PUT_LINE ('Preparing O5.SR_ORDER_FEED completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Update ADJUSTMENTID on O5.SR_ORDER_FEED started at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

UPDATE O5.SR_ORDER_FEED
SET ADJUSTMENTID    =o5.o5_SQ_SR_ORDER_FEED.nextval
WHERE ADJUSTMENTID IS NULL
AND ADJUSTMENTTYPE IS NOT NULL;

EXEC DBMS_OUTPUT.PUT_LINE ('Update ADJUSTMENTID on O5.SR_ORDER_FEED completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

COMMIT;

EXEC DBMS_OUTPUT.PUT_LINE ('Generate Daily file starting at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
DECLARE
  XML_ITEM CLOB;
BEGIN
  SELECT '<?xml version="1.0" encoding="UTF-8"?>' ||
  XMLELEMENT( "Orders",
	XMLELEMENT ("Partner", 'OFF5TH'),
	XMLELEMENT ("VersionNumber", '3.1'),
	XMLAGG( XMLELEMENT ("Order",
			XMLFOREST ( ORDERNUMBER AS "OrderNumber",
						TO_CHAR(ORDERDATE,'MM/DD/YYYY HH24:MI:SS') AS "OrderDate",
						TOTALNUMBEROFITEMS AS "TotalNumberOfItems",
						TOTALNUMBEROFSHOPRUNNERITEMS AS "TotalNumberOfShopRunnerItems",
						SRAUTHENTICATIONTOKEN AS "SRAuthenticationToken",
						CURRENCYCODE AS "CurrencyCode",
						ORDERTOTAL AS "OrderTotal",
						BILLINGSUBTOTAL AS "BillingSubTotal",
						PAYMENTTENDERTYPE AS "PaymentTenderType"),
	XMLAGG(
		CASE
		  WHEN ADJUSTMENTTYPE IS NOT NULL
		  THEN XMLELEMENT ("Adjustment",
			XMLFOREST ( AdjustmentId AS "AdjustmentId",
						TO_CHAR(ADJUSTMENTDATE,'MM/DD/YYYY HH24:MI:SS') AS "AdjustmentDate",
						ADJUSTMENTAMOUNT AS "AdjustmentAmount",
						BILLINGADJUSTMENTAMOUNT AS "BillingAdjustmentAmount",
						ADJUSTMENTTYPE AS "AdjustmentType",
						ADJUSTMENTREASON AS "AdjustmentReason" ) )
		END ) ) ) ). EXTRACT ('/*').getclobVal ()
  INTO XML_ITEM
  FROM O5.SR_ORDER_FEED
  WHERE UPDATE_DATE>=TRUNC(SYSDATE-1)
  AND ORDERDATE    >=TO_DATE('07/31/2017','MM/DD/YYYY')
  GROUP BY ORDERNUMBER,
    ORDERDATE,
    TOTALNUMBEROFITEMS,
    TOTALNUMBEROFSHOPRUNNERITEMS,
    SRAUTHENTICATIONTOKEN,
    CURRENCYCODE,
    ORDERTOTAL,
    BILLINGSUBTOTAL,
    PAYMENTTENDERTYPE;
  DBMS_XSLPROCESSOR.CLOB2FILE(XML_ITEM, 'DATASERVICE', 'o5_shoprunner_order_feed.xml');
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE ('Error in file generation '|| SQLCODE || '-' || SQLERRM);
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('Generate Daily file completed at '||to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

SHOW ERRORS;

EXEC DBMS_OUTPUT.PUT_LINE ('o5_shoprunner_order_feed.sql completed at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXIT;
