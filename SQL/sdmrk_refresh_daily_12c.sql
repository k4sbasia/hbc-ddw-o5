whenever sqlerror exit failure
set serveroutput on
set pagesize 0
set tab off
SET LINESIZE 10000
set timing on

ALTER TABLE SDMRK.ORDERS NOLOGGING;

TRUNCATE TABLE SDMRK.ORDERS;
---
INSERT INTO SDMRK.ORDERS
(ORDER_NUMBER ,
ORDER_LINE_NUMBER,
ORDERDATE,
ORDER_LINE_STATUS,
ORDER_HEADER_STATUS,
ORDER_TYPE,
CUSTOMER_NUMBER,
FREIGHT_CHARGES ,
SHIP_VIA,
CANCELLATION_DOLLARS,
RETURN_DOLLARS,
TAX,
CANCEL_DATE,
PROMO_ID ,
REFER_ID,
DEMAND_DOLLARS,
DEMAND_UNITS,
CANCEL_REASON_CODE,
CANCEL_REASON_DESCRIPTION,
RETURN_REASON_CODE,
RETURN_REASON_DESCRIPTION,
BACKORDER_INDICATOR,
SAKS_FIRST_INDICATOR,
EMPLOYEE_INDICATOR,
SAKS_FIRST_FREE_SHIP_INDICATOR,
FILL_LOCATION ,
CUSTOMER_ID,
INDIVIDUAL_ID ,
HOUSEHOLD_ID ,
SHIP_DATE ,
CREDIT_CARD_TYPE,
CREDIT_CARD_DESCRIPTION,
BILL_TO_ADDRESS_ID,
SHIP_TO_ADDRESS_ID ,
STORE_NUMBER,
RETURN_DATE ,
ITEM_NUMBER ,
SKU ,
VENDOR_ID,
DEPARTMENT_ID,
GROUP_ID,
DIVISION_ID,
GIFT_WRAP_INDICATOR,
GIFTWRAP_TYPE ,
FIRST_PO_DATE  ,
RETURN_UNITS ,
CANCELLATION_UNITS ,
EMC_NUMBER ,
AFFILIATE_ID ,
INTERNATIONAL_IND,
SHIP_ADDR1,
SHIP_ADDR2,
SHIP_ADDR3 ,
SHIP_CITY ,
SHIP_STATE,
SHIP_ZIPCODE,
SHIP_COUNTRY,
ANYTIME_IND,
FLASH_IND,
FULLFILLLOCATION,
SRIND)
   SELECT ORDERNUM Order_Number,
          LINENUM Order_Line_Number,
          orderdate_time Orderdate,
          ORDERSTATUS Order_Line_Status,
          ORDER_HEADER_STATUS Order_Header_Status,
          (CASE
              WHEN lower(ORDERTYPE) IN ('iph', 'ipd') THEN lower(ORDERTYPE)
              ELSE ORDERTYPE
           END) ORDER_TYPE ,
          CUSTOMERNUM Customer_Number,
          FREIGHT Freight_Charges,
          SHIPVIA Ship_Via,
          CANCEL_DOLLARS Cancellation_Dollars,
          RETURN_DOLLARS Return_Dollars,
          TAX Tax,
          CANCELDATE Cancel_Date,
          PROMO_ID Promo_ID,
          REFER_ID Refer_ID,
          DEMAND_DOLLARS Demand_Dollars,
          DEMAND_QTY Demand_Units,
          CANCELREASON Cancel_Reason_Code,
          CANCELREASON_DESC Cancel_Reason_Description,
          RETURNREASON Return_Reason_Code,
          RETURNREASON_DESC Return_Reason_Description,
          BACKORDER_IND Backorder_Indicator,
          SAKSFIRST_IND Saks_First_Indicator,
          EMPLOYEE_IND Employee_Indicator,
          SAKSFIRST_FREESHIP_IND Saks_First_Free_Ship_Indicator,
          FILL_LOC Fill_Location,
          CUSTOMER_ID Customer_Id,
          (CASE
              WHEN INDIVIDUAL_ID IN (102264328, 102289121) THEN 999999999
              ELSE INDIVIDUAL_ID
           END)
             Individual_ID,
          HOUSEHOLD_ID Household_ID,
          SHIPDATE Ship_Date,
          CC_TYPE_ID Credit_Card_Type,
          CC_TYPE_DESC Credit_Card_Description,
          BILL_TO_ADDRESS_ID Bill_to_Address_ID,
          SHIP_TO_ADDRESS_ID Ship_to_Address_ID,
          STORENUM Store_Number,
          RETURNDATE Return_Date,
          ITEM Item_Number,
          SKU SKU,
          VENDOR_ID Vendor_ID,
          DEPARTMENT_ID Department_ID,
          GROUP_ID GROUP_ID,
          DIVISION_ID Division_ID,
          GIFTWRAP_IND Gift_Wrap_Indicator,
          (CASE
              WHEN giftwrap_ind = 'A' THEN 'Complementary Gift Wrap'
              WHEN giftwrap_ind = 'B' THEN 'Pewter wrap'
              WHEN giftwrap_ind = 'C' THEN 'White wrap'
              WHEN giftwrap_ind = 'N' THEN 'No Wrap'
              ELSE NULL
           END)
             giftwrap_type,
          FST_PODATE First_PO_Date,
          QTYRETURNED Returned_Units,
          QTYCANCELLED Cancellation_Units,
          EMC_NUMBER emc_number,
          AFFILIATE_ID affiliate_id,
          INTERNATIONAL_IND international_ind,
           SHIP_ADDR1,
           SHIP_ADDR2,
           SHIP_ADDR3,
         SHIP_CITY,
         SHIP_STATE,
         SHIP_ZIPCODE,
         SHIP_COUNTRY,
         RPT_ANYTIME,
        RPT_FLASH,
        FULLFILLLOCATION,
        SRIND
FROM
(
  SELECT ordernum ordernum,
    orderhdr,
    orderdet linenum,
    orderseq orderdetailseq,
    TRUNC (orderdate) orderdate,
    orderdate orderdate_time,
    orderdate entrydate,
    ordline_status orderstatus,
    ordhdr_status order_header_status,
    ordertype,
    customernumber customernum,
    freight_amt freight,
    (
    CASE
      WHEN giftorder_ind IS NOT NULL
      THEN 'Y'
      ELSE 'N'
    END) giftorder,
    (
    CASE
      WHEN ordline_status IN ('D', 'M')
      THEN 'Y'
      ELSE 'N'
    END) shipcomplete,
    ponum ponum,
    (
    CASE
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929808295'
      THEN 9
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973930820217'
      THEN 1
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973930820219'
      THEN 2
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973933441469'
      THEN 5
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973933227467'
      THEN 3
      WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973933758655'
      THEN 6
      ELSE 0
    END) shipvia,
    sourcecodedetail sourcecodedetail,
    orig_price_amt origprice,
    offernprice_amt price,
    offernprice_amt offerprice,
    qtyordered qtyordered,
    (
    CASE
      WHEN ordline_status = 'X'
      THEN qtyordered
      ELSE 0
    END) qtycancelled,
    (
    CASE
      WHEN ordline_status = 'X'
      THEN qtyordered * offernprice_amt
      ELSE 0
    END) cancel_dollars,
    (
    CASE
      WHEN ordline_status IN ('D', 'M')
      THEN qtyordered
      ELSE 0
    END) qtyshipped,
    (
    CASE
      WHEN ordline_status = 'R'
      THEN qtyordered
      ELSE 0
    END) qtyreturned,
    (
    CASE
      WHEN ordline_status = 'R'
      THEN qtyordered * offernprice_amt
      ELSE 0
    END) return_dollars,
    (NVL (taxrate_amt, 0) * NVL (offernprice_amt, 0) / 100) tax,
    discount_amt discount,
    (
    CASE
      WHEN ordline_status = 'B'
      THEN qtyordered
      ELSE 0
    END) qtyreserved,
    (
    CASE
      WHEN ordline_status = 'B'
      THEN ordline_modifydate
    END) datereserved,
    TO_CHAR (orderdate, 'HH24MMSS') entrytime,
    (
    CASE
      WHEN ordline_status = 'X'
      THEN ordline_modifydate
    END) canceldate,
    UPPER (promo_id) promo_id,
    refer_id refer_id,
    (
    CASE
      WHEN LTRIM (RTRIM (ordline_status)) IN ('T', 'M', 'Q')
      THEN 0
      WHEN ordhdr_status = 'N'
      THEN 0
      ELSE extend_price_amt
    END) demand_dollars,
    (
    CASE
      WHEN LTRIM (RTRIM (ordline_status)) IN ('T', 'M', 'Q')
      THEN 0
      WHEN ordhdr_status = 'N'
      THEN 0
      ELSE qtyordered
    END) demand_qty,
    cancelreason cancelreason,
    (
    CASE
      WHEN cancelreason = 'A'
      THEN 'No Inventory System Cancel'
      WHEN cancelreason = 'B'
      THEN 'No Inventory System Cancel-Overnight'
      WHEN cancelreason = 'S1'
      THEN 'System Issues - Inventory Overstated'
      WHEN cancelreason = 'S2'
      THEN 'System Issues - Order Related'
      WHEN cancelreason = 'YC'
      THEN 'CSR Cancel-No Inventory'
      WHEN cancelreason = 'E'
      THEN 'Credit Hold Cancel-2day'
      WHEN cancelreason = 'YV'
      THEN 'CSR Cancel-Item Order Verification'
      WHEN cancelreason = 'C2'
      THEN 'Customer Service Cancel'
      WHEN cancelreason = 'YD'
      THEN 'CSR Cancel-Customer Request'
      WHEN cancelreason = 'YR'
      THEN 'Customer Cancel-20 minute window'
      WHEN cancelreason = 'OO'
      THEN 'Backorder Cancel-PO Quantity Decrease'
      WHEN cancelreason = 'PC'
      THEN 'Backorder Cancel-PO Cancel'
      WHEN cancelreason = 'PD'
      THEN 'Backorder Cancel-PO Expired'
      WHEN cancelreason = 'F1'
      THEN 'Fraud'
      WHEN cancelreason = 'RA'
      THEN 'Risk Above $575'
      WHEN cancelreason = 'RB'
      THEN 'Risk Below $575'
      WHEN cancelreason = 'RD'
      THEN 'Delivery Address Questionable'
      WHEN cancelreason = 'RE'
      THEN 'Attempted EGC Purchase'
      WHEN cancelreason = 'RI'
      THEN 'Income Risk'
      WHEN cancelreason = 'RP'
      THEN 'Population Risk'
      WHEN cancelreason = 'RS'
      THEN 'Score Above Accepted Threshold'
      WHEN cancelreason = 'RU'
      THEN 'UPC Risk'
      WHEN cancelreason = 'D1'
      THEN 'Damaged/Defective Item'
      WHEN cancelreason = 'D2'
      THEN 'Item not Consistent with Picture on Web'
      WHEN cancelreason = 'YE'
      THEN 'CSR Cancel-Shipping Delay'
      WHEN cancelreason = 'YF'
      THEN 'CSR Cancel-SL Reprocess'
      WHEN cancelreason = 'YH'
      THEN 'Credit Hold Cancel- 2nd attempt'
      WHEN cancelreason = 'YK'
      THEN 'CSR Cancel-BM Reprocess'
      WHEN cancelreason = 'CC'
      THEN 'Risk Management Customer Cancel'
      WHEN cancelreason = 'D'
      THEN 'Web Cancel from SL'
      WHEN cancelreason = 'H1'
      THEN 'Credit Hard Decline - Bank or SVC'
      WHEN cancelreason = 'H2'
      THEN 'Fraud System Hard Decline'
      WHEN cancelreason = 'RC'
      THEN 'Risk Management Cancel (Soft Decline)'
      WHEN cancelreason = 'RM'
      THEN 'Risk Management Hard Decline'
      WHEN cancelreason = 'YB'
      THEN 'CSR Cancel - BackOrder Cancel Risk'
      WHEN cancelreason = 'YG'
      THEN 'Swat Cancel bcz no inventory'
      WHEN cancelreason = 'YM'
      THEN 'BO cancel -- customer/system issue'
      WHEN cancelreason = 'SH'
      THEN 'Shell Order Cancel - auto cancel'
      WHEN cancelreason = 'LA'
      THEN 'No Inventory System Cancel - Locator'
      WHEN cancelreason = 'LB'
      THEN 'Inventory Mismatch - Fusion Cancel'
      WHEN cancelreason = 'LC'
      THEN 'Locator Manual Cancel'
    END) cancelreason_desc,
    returnreason returnreason,
    (
    CASE
      WHEN returnreason = '1'
      THEN 'Problem with sizing'
      WHEN returnreason = '2'
      THEN 'Item not as depicted'
      WHEN returnreason = '3'
      THEN 'Incorrect item sent'
      WHEN returnreason = '4'
      THEN 'Item was damaged/defective'
      WHEN returnreason = '5'
      THEN 'Changed mind'
      WHEN returnreason = '6'
      THEN 'Arrived late'
      WHEN returnreason = '7'
      THEN 'Other pieces not received'
      WHEN returnreason = '8'
      THEN 'Dissatisfied with quality'
      WHEN returnreason = '9'
      THEN 'No reason'
    END) returnreason_desc,
    holdreason holdreason,
    DECODE (backorder_ind, 'T', 1, 0) backorder_ind,
    DECODE (saksfirst_ind, 'T', 1, 0) saksfirst_ind,
    DECODE (employee_ind, 'T', 1, 0) employee_ind,
    DECODE (saksifirst_freeship_ind, 'T', 1, 0) saksfirst_freeship_ind,
    DECODE (fill_loc, 'T', 1, 0) fill_loc,
    createfor customer_id,
    shipdate shipdate,
    podate podate,
    bm_skuid bmskuid,
    ccd_id cc_type_id,
    ccd_brand cc_type_desc,
    bill_to_address_id bill_to_address_id,
    ship_to_address_id ship_to_address_id,
    DECODE (slordernum, NULL, 0, slordernum) slordernum,
    DECODE (storenum, NULL, 0, storenum) storenum,
    (
    CASE
      WHEN ordline_status = 'R'
      THEN ordline_modifydate
      ELSE NULL
    END) returndate,
    ordline_modifydate lastchangedate,
    offer offer,
    item item,
    SKU SKU,
    product_id product_id,
    vendor_id vendor_id,
    department_id department_id,
    GROUP_ID GROUP_ID,
    division_id division_id,
    (
    CASE
      WHEN giftwrap_ind = 'A'
      THEN 'Complementary Gift Wrap'
      WHEN giftwrap_ind = 'B'
      THEN 'Pewter wrap'
      WHEN giftwrap_ind = 'C'
      THEN 'White wrap'
      WHEN giftwrap_ind = 'N'
      THEN 'No Wrap'
      ELSE NULL
    END) giftwrap_ind,
    DECODE (markdown_amt, NULL, 0, markdown_amt) markdown_amt,
    DECODE (linepromo_amt, NULL, 0, linepromo_amt) linepromo_amt,
    DECODE (assocdisc_amt, NULL, 0, assocdisc_amt) assocdisc_amt,
    emc_number emc_number,
    fstv_canrsn fstv_canrsn,
    fstv_ldte fstv_ldte,
    fst_podate fst_podate,
    SUBSTR (refer_id, 4, 16) user_id,
    SUBSTR (refer_id, 4, 16) user_id_num,
    commission_assoc1_nm,
    commission_assoc2_nm,
    (
    CASE
      WHEN commission_assoc1_id IS NOT NULL
      THEN SUBSTR (commission_assoc1_id, 5, 10)
      ELSE NULL
    END) commission_assoc1_id,
    (
    CASE
      WHEN commission_assoc2_id IS NOT NULL
      THEN SUBSTR (commission_assoc2_id, 5, 10)
      ELSE NULL
    END) commission_assoc2_id,
    (
    CASE
      WHEN commission_assoc1_id IS NOT NULL
      THEN ABS (SUBSTR (commission_assoc1_id, 1, 4))
      ELSE 0
    END) commission_assoc1_store,
    (
    CASE
      WHEN commission_assoc2_id IS NOT NULL
      THEN ABS (SUBSTR (trim(REGEXP_REPLACE(commission_assoc2_id, '[^[:alnum:] ]', 0)), 1, 4))
      ELSE NULL
    END) commission_assoc2_store,
    ship_first_name,
    ship_middle_name,
    ship_last_name,
    ship_addr1,
    ship_addr2,
    ship_addr3,
    ship_city,
    ship_state,
    ship_zipcode,
    ship_country,
    CASE
      WHEN INSTR (promo_id, ',') > 0
      THEN SUBSTR (promo_id, 1, INSTR (promo_id, ',') - 1)
      ELSE promo_id
    END first_promo,
    CASE
      WHEN INSTR (promo_id, ',') > 0
      THEN SUBSTR (promo_id, INSTR (promo_id, ',') + 1, 50)
      ELSE NULL
    END second_promo,
    international_ind,
    individual_id,
    household_id,
    sub_total,
    line_tax,
    total_shipping,
    gift_wrap_fee,
    affiliate_id,
    TAX_ON_SHIPPING,
    OFF5TH_ITEM,
    OFFPRICE_ITEM,
    OUTLETITEM,
    RPT_FLASH,
    RPT_ANYTIME,
    FULLFILLLOCATION,
        CASE
          WHEN SRIND = 'Y'
          THEN 'Yes'
          WHEN SRIND = 'N'
          THEN 'No'
          WHEN SRIND IS NULL
          THEN 'No'
        END SRIND
  FROM &1.Bi_Sale@&3
  )
  where LINENUM is not null
    AND order_header_status not in ('N')
;

COMMIT;

--MERGE INTO SDMRK.ORDERS HST USING
--(SELECT DISTINCT order_number,
--  sku,
--  qs.evt_id,
--ff.evt_name
--FROM SDMRK.ORDERS O
--INNER JOIN &1.BI_QUICK_STATS_OFFPRICE@&3 QS
--ON TRUNC(O.ORDERDATE) = TRUNC(QS.QS_DT_KEY)
--AND O.SKU             = QS.QS_SKU
--AND O.ITEM_NUMBER     = QS.QS_ITEM
--INNER JOIN SAKS_CUSTOM.FASHION_FIX_EVENTS@PRODSTO_SAKS_CUSTOM FF
--ON QS.EVT_ID = FF.EVT_ID
--AND TRUNC(o.orderdate) BETWEEN TRUNC(evt_vip_start_dt) AND TRUNC(evt_end_dt)
--WHERE NVL(QS.EVT_ID,'99999') <> '99999'
--AND o.flash_ind               = 'T'
--AND o.evt_id                 IS NULL
--) TRN ON (trn.order_number    = hst.order_number AND hst.sku = trn.sku)
--WHEN MATCHED THEN
--  UPDATE SET HST.EVT_ID = TRN.EVT_ID, hst.evt_name = trn.evt_name;

--COMMIT;

ALTER TABLE SDMRK.INDIVIDUAL NOLOGGING;

TRUNCATE TABLE SDMRK.INDIVIDUAL;

INSERT INTO SDMRK.INDIVIDUAL
   SELECT INDIVIDUAL_ID Individual_ID,
          LORD_DT LAST_ORDER_DATE,
          FORD_DT FIRST_ORDER_DATE,
          SAKS_FIRST_TIER,
          CARD_ACCT_TYPE,
          STORE_OF_RES STORE_OF_RESIDENCE,
          PRIME_STATE,
          PRIME_ZIPCODE,
          REPEAT_CUSTOMER_MONTH,
          REPEAT_CUSTOMER_QUARTER,
          REPEAT_CUSTOMER_SEASON,
          REPEAT_CUSTOMER_YEAR,
          NEW_CUSTOMER_MONTH,
          NEW_CUSTOMER_QUARTER,
          NEW_CUSTOMER_SEASON,
          NEW_CUSTOMER_YEAR,
          MONETARY_MONTH,
          MONETARY_QUARTER,
          MONETARY_SEASON,
          MONETARY_YEAR,
          FREQUENCY_MONTH,
          FREQUENCY_QUARTER,
          FREQUENCY_SEASON,
          FREQUENCY_YEAR,
          RECENCY,
          WEB_CUSTOMER,
          STORE_ASSOCIATE_CUSTOMER,
          CALL_CENTER_CUSTOMER
     FROM &1.BI_INDIVIDUAL@&3
    WHERE INDIVIDUAL_ID NOT IN (102264328, 102289121);

COMMIT;

---CONSOLIDATING INTERNATIONAL UNKNOWN CUSTOMER TO ONE INDIVIDUAL ID OF 999999999

INSERT INTO SDMRK.INDIVIDUAL
   SELECT 999999999 Individual_ID,
          LORD_DT LAST_ORDER_DATE,
          FORD_DT FIRST_ORDER_DATE,
          SAKS_FIRST_TIER,
          CARD_ACCT_TYPE,
          STORE_OF_RES STORE_OF_RESIDENCE,
          PRIME_STATE,
          PRIME_ZIPCODE,
          REPEAT_CUSTOMER_MONTH,
          REPEAT_CUSTOMER_QUARTER,
          REPEAT_CUSTOMER_SEASON,
          REPEAT_CUSTOMER_YEAR,
          NEW_CUSTOMER_MONTH,
          NEW_CUSTOMER_QUARTER,
          NEW_CUSTOMER_SEASON,
          NEW_CUSTOMER_YEAR,
          MONETARY_MONTH,
          MONETARY_QUARTER,
          MONETARY_SEASON,
          MONETARY_YEAR,
          FREQUENCY_MONTH,
          FREQUENCY_QUARTER,
          FREQUENCY_SEASON,
          FREQUENCY_YEAR,
          RECENCY,
          WEB_CUSTOMER,
          STORE_ASSOCIATE_CUSTOMER,
          CALL_CENTER_CUSTOMER
     FROM &1.BI_INDIVIDUAL@&3
    WHERE INDIVIDUAL_ID IN (102264328, 102289121) AND ROWNUM = 1;

COMMIT;

ALTER TABLE SDMRK.BI_SAKS_FIRST_DETAIL NOLOGGING;

MERGE INTO SDMRK.BI_SAKS_FIRST_DETAIL trg
USING (SELECT SAKS_FIRST_NUM,
  TITLE,
  FIRST_NAME,
  MIDDLE_NAME,
  LAST_NAME,
  ADDR,
  ADDR2,
  CITY,
  STATE,
  ZIP,
  TIER_INFO,
  ACCOUNT_TYPE,
  INDIVIDUAL_ID,
  HOUSEHOLD_ID,
  ADD_DT
FROM &1.BI_SAKS_FIRST_DETAIL@&3) src
ON (trg.INDIVIDUAL_ID = src.INDIVIDUAL_ID AND trg.SAKS_FIRST_NUM = src.SAKS_FIRST_NUM)
WHEN MATCHED THEN
UPDATE SET
trg.TITLE=src.TITLE,
trg.FIRST_NAME=src.FIRST_NAME,
trg.MIDDLE_NAME=src.MIDDLE_NAME,
trg.LAST_NAME=src.LAST_NAME,
trg.ADDR=src.ADDR,
trg.ADDR2=src.ADDR2,
trg.CITY=src.CITY,
trg.STATE=src.STATE,
trg.ZIP=src.ZIP,
trg.TIER_INFO=src.TIER_INFO,
trg.ACCOUNT_TYPE=src.ACCOUNT_TYPE,
trg.HOUSEHOLD_ID=src.HOUSEHOLD_ID,
trg.ADD_DT=src.ADD_DT
WHEN NOT MATCHED THEN
INSERT(
    SAKS_FIRST_NUM,
    TITLE,
    FIRST_NAME,
    MIDDLE_NAME,
    LAST_NAME,
    ADDR,
    ADDR2,
    CITY,
    STATE,
    ZIP,
    TIER_INFO,
    ACCOUNT_TYPE,
    INDIVIDUAL_ID,
    HOUSEHOLD_ID,
    ADD_DT)
VALUES
(src.SAKS_FIRST_NUM,
src.TITLE,
src.FIRST_NAME,
src.MIDDLE_NAME,
src.LAST_NAME,
src.ADDR,
src.ADDR2,
src.CITY,
src.STATE,
src.ZIP,
src.TIER_INFO,
src.ACCOUNT_TYPE,
src.INDIVIDUAL_ID,
src.HOUSEHOLD_ID,
src.ADD_DT);

COMMIT;

merge INTO SDMRK.BI_SAKS_FIRST_DETAIL HST USING
(SELECT DISTINCT TO_NUMBER(LOYALTY_ID) LOYALTY_ID,
  max(ENROLLMENT_DATE) ENROLLMENT_DATE,
  max(STATUS) STATUS,
  max(ELIGIBLE_BALANCE) ELIGIBLE_BALANCE,
  max(BASE_POINTS) BASE_POINTS,
  max(POINT_BALANCE) POINT_BALANCE
FROM SAKS_CUSTOM.SAKSFIRST_POINTS@PRODSTO_SAKS_CUSTOM group  by TO_NUMBER(LOYALTY_ID)
) SRC ON (HST.SAKS_FIRST_NUM = TO_NUMBER(SRC.LOYALTY_ID))
WHEN MATCHED THEN
  UPDATE
  SET hst.ENROLLMENT_DATE =src.ENROLLMENT_DATE,
    HST.STATUS            =SRC.STATUS,
    HST.ELIGIBLE_BALANCE  =SRC.ELIGIBLE_BALANCE,
    HST.BASE_POINTS       =SRC.BASE_POINTS,
    HST.POINT_BALANCE     =SRC.POINT_BALANCE
        ;
COMMIT;

ALTER TABLE SDMRK.customer NOLOGGING;

TRUNCATE TABLE SDMRK.customer;

INSERT INTO sdmrk.customer(CUSTOMER_ID,
INDIVIDUAL_ID,
HOUSEHOLD_ID,
TITLE,
FIRST_NAME,
MIDDLE_NAME,
LAST_NAME,
HOME_PHONE,
ADDR1,
ADDR2,
ADDR3,
CITY,
STATE,
ZIPCODE,
ZIP4,
POSTAL_CODE,
COUNTRY,
EMAIL_ADDRESS,
ADD_DT,
REGISTERED_CUSTOMER,
SAKSFIRSTNUMBER,
EMAIL_ADDRESS_MD5)
SELECT CUSTOMER_ID CUSTOMER_ID,
          (CASE
              WHEN INDIVIDUAL_ID IN (102264328, 102289121) THEN 999999999
              ELSE INDIVIDUAL_ID
           END)
             Individual_ID,
          HOUSEHOLD_ID HOUSEHOLD_ID,
          CUSTTITLE TITLE,
          FIRSTNAME FIRST_NAME,
          MIDDLENAME MIDDLE_NAME,
          LASTNAME LAST_NAME,
          SUBSTR(TRIM(HOME_PH),1,35) HOME_PHONE,
          ADDR1 ADDR1,
          ADDR2 ADDR2,
          ADDR3 ADDR3,
          CITY CITY,
          STATE STATE,
          ZIPCODE ZIPCODE,
          ZIP4 ZIP4,
          P_CODE POSTAL_CODE,
          COUNTRY COUNTRY,
          UPPER (INTERNETADDRESS) AS EMAIL_ADDRESS,
          ADD_DT,
          REGISTERED_CUSTOMER REGISTERED_CUSTOMER,
      SAKSFIRSTNUMBER,
          SDMRK.STRING_TO_MD5_HASH(INTERNETADDRESS)
     FROM &1.bi_customer@&3
    WHERE INTERNETADDRESS LIKE '%@%' AND INTERNETADDRESS LIKE '%.%'
          AND (   LENGTH (
                     SUBSTR (INTERNETADDRESS,
                             1,
                             INSTR (INTERNETADDRESS, '@') - 1)) > 1
               OR LENGTH (
                     SUBSTR (
                        INTERNETADDRESS,
                        INSTR (INTERNETADDRESS, '@') + 1,
                        (  INSTR (INTERNETADDRESS, '.')
                         - 1
                         - INSTR (INTERNETADDRESS, '@')
                         + 1)
                        - 1)) > 1
               OR LENGTH (
                     SUBSTR (INTERNETADDRESS,
                             INSTR (INTERNETADDRESS, '.') + 1)) > 1);

COMMIT;

ALTER TABLE SDMRK.EMAIL_ADDRESS NOLOGGING;

MERGE INTO sdmrk.email_address trg
USING (SELECT EMAIL_ID,
  EMAIL_ADDRESS,
  GENDER,
  OPT_IN ,
  ADD_BY_SOURCE_ID,
  ADD_DT,
  CUSTOMER_ID,
  INTERNATIONAL_IND,
  CANADA_FLAG,
  SDMRK.STRING_TO_MD5_HASH(EMAIL_ADDRESS) EMAIL_ADDRESS_MD5
FROM &1.EMAIL_ADDRESS@&3
WHERE VALID_IND=1 AND (ADD_DT >= to_char(sysdate-1,'DD-MON-YY') OR MODIFY_DT >= to_char(sysdate-1,'DD-MON-YY'))) src
ON (trg.EMAIL_ID = src.EMAIL_ID)
WHEN MATCHED THEN
UPDATE SET
trg.EMAIL_ADDRESS=src.EMAIL_ADDRESS,
trg.GENDER=src.GENDER,
trg.OPT_IN=src.OPT_IN,
trg.ADD_BY_SOURCE_ID=src.ADD_BY_SOURCE_ID,
trg.ADD_DT=src.ADD_DT,
trg.CUSTOMER_ID=src.CUSTOMER_ID,
trg.INTERNATIONAL_IND=src.INTERNATIONAL_IND,
trg.CANADA_FLAG=src.CANADA_FLAG,
trg.EMAIL_ADDRESS_MD5=src.EMAIL_ADDRESS_MD5
WHEN NOT MATCHED THEN
INSERT(
    EMAIL_ID,
    EMAIL_ADDRESS,
    GENDER,
    OPT_IN ,
    ADD_BY_SOURCE_ID,
    ADD_DT,
    CUSTOMER_ID,
    INTERNATIONAL_IND,
    CANADA_FLAG,
    EMAIL_ADDRESS_MD5
 )
VALUES (src.EMAIL_ID,
    src.EMAIL_ADDRESS,
    src.GENDER,
    src.OPT_IN ,
    src.ADD_BY_SOURCE_ID,
    src.ADD_DT,
    src.CUSTOMER_ID,
    src.INTERNATIONAL_IND,
    src.CANADA_FLAG,
    src.EMAIL_ADDRESS_MD5);

COMMIT;

--  Re Fresh Product

TRUNCATE TABLE SDMRK.PRODUCT;
COMMIT;
INSERT INTO SDMRK.PRODUCT(
UPC,
          SKU,
          SKU_DESCRIPTION,
          Item,
          ITEM_DESCRIPTION,
          Vendor_Style_Number,
          DEPARTMENT_ID,
          SKU_LIST_PRICE,
          SKU_SALE_PRICE,
          Item_list_Price,
          Item_Cost,
          SKU_SIZE,
          SKU_COLOR_CODE,
          SKU_COLOR,
          First_Receipt_Date,
          Last_Receipt_Date,
          Analysis_Code_1,
          Warehouse_Sellable_Units,
          Warehouse_Backorder_Units,
          ACTIVE_INDICATOR,
          Sell_Off_Indicator,
          Dropship_Indicator,
          GWP_Eligibility_Indicator,
          Replenish_Indicator,
          GWP_Flag,
          Web_Item_Flag,
          GROUP_ID,
          Division_ID,
          Vendor_ID,
          price_status,
          brand_name,
          PRODUCT_CODE,
          WEB_BOOK_DT,
          PRD_ID,
          BM_DESC,
          STORE_INVENTORY,
          BACKORDER_INDICATOR,
          DEACTIVE_IND
)
    SELECT a.UPC UPC,
          a.SKU SKU,
          SKU_DESCRIPTION SKU_Description,
          a.ITEM Item,
          ITEM_DESCRIPTION Item_Description,
          VEN_STYL_NUM Vendor_Style_Number,
          DEPARTMENT_ID Department_ID,
          SKU_LIST_PRICE SKU_List_Price,
          SKU_SALE_PRICE SKU_Sale_Price,
          ITEM_LIST_PRICE Item_list_Price,
          ITEM_CST_AMT Item_Cost,
          SKU_SIZE SKU_Size,
          SKU_COLOR_CODE SKU_Color_Code,
          SKU_COLOR SKU_Color,
          FIRST_RECV_DT First_Receipt_Date,
          LAST_RECV_DT Last_Receipt_Date,
          ANALYSIS_CDE_1 Analysis_Code_1,
          a.WH_SELLABLE_QTY Warehouse_Sellable_Units,
          a.WH_BACKORDER_QTY Warehouse_Backorder_Units,
          ACTIVE_IND Active_Indicator,
          SELLOFF_IND Sell_Off_Indicator,
          a.DROPSHIP_IND Dropship_Indicator,
          GWP_ELIG_IND GWP_Eligibility_Indicator,
          REPLENISH_IND Replenish_Indicator,
          GWP_FLAG_IND GWP_Flag,
          WEB_ITM_FLG Web_Item_Flag,
          GROUP_ID GROUP_ID,
          DIVISION_ID Division_ID,
          VENDOR_ID Vendor_ID,
          PRICE_STATUS price_status,
          a.BRAND_NAME brand_name,
          NVL(PRODUCT_CODE,ITEM) PRODUCT_CODE,
          WEB_BOOK_DT WEB_BOOK_DT,
          a.PRD_ID PRD_ID,
          MAX(c.BM_DESC) OVER (PARTITION BY c.item_id ORDER BY c.bm_desc) BM_DESC,
         s.in_store_qty as "STORE_INVENTORY",
          NVL(oa.BACK_ORDERABLE , 'F') as "BACKORDER_INDICATOR",
          a.deactive_ind as DEACTIVE_IND
     FROM &1.bi_product a, &1.bi_pubdate b, &1.bi_product_id c,
    &1.v_sd_price_&2 p,
    &1.inventory s,
    &1.all_active_pim_prd_attr_&2 oa
     WHERE NVL(a.PRODUCT_CODE,a.ITEM) = b.FINAL_ITEM_NUM(+)
           AND NVL(a.PRODUCT_CODE,a.ITEM) = c.ITEM_ID(+)
           AND NVL(a.PRODUCT_CODE,a.ITEM)=p.ITEM_ID
          and  p.SKN_NO = lpad(s.SKN_NO (+),13,0)
           and a.PRODUCT_CODE = oa.PRODUCT_ID
           AND c.BM_DESC is not null;

COMMIT;

merge into sdmrk.product trg
using (
  select
        PRODUCT_ID product_code,
        PRD_READYFORPROD readyforprod_flag
 from &1.all_active_pim_prd_attr_&2
  ) src
on (trg.product_code = src.product_code)
when matched then
update set trg.readyforprod_flag = src.readyforprod_flag;

COMMIT;

merge into sdmrk.product trg
using (
  select
        PRODUCT_ID product_code,
        READYFORPROD_TIMER readyforprod_timer
 from &1.all_active_pim_prd_attr_&2
  ) src
on (trg.product_code = src.product_code)
when matched then
update set trg.readyforprod_timer = src.readyforprod_timer;

COMMIT;

UPDATE SDMRK.PRODUCT
SET SKU_COLOR = 'BEAT MEN'
WHERE SKU_COLOR like 'BEAT MEN%' ;

COMMIT;

ALTER TABLE SDMRK.EXCLUDED_PRODUCTS NOLOGGING;

TRUNCATE TABLE SDMRK.EXCLUDED_PRODUCTS;

INSERT INTO sdmrk.excluded_products(product_code,start_datetime,end_datetime)
select product_id,READYFORPROD_TIMER,readyforprod_end_time
--(to_date(prd.READYFORPROD_TIMER, 'MM/DD/YYYY HH:MI PM')),product_id
from
&1.all_active_pim_prd_attr_&2 prd
 where
  trunc(sysdate) between to_date(prd.READYFORPROD_TIMER, 'MM/DD/YYYY HH:MI PM')  and to_date(prd.readyforprod_end_time, 'MM/DD/YYYY HH:MI PM')

COMMIT;

-- added to update default billing address corresponding from Blue Martini
merge into SDMRK.CUSTOMER trg
using (select       a.address_id address_id,
                    m.customer_id customer_id,
                    trim(a.addr1) addr1,
                    trim(a.addr2) addr2,
                    trim(a.addr3) addr3,
                    trim(a.city) city,
                    trim(a.state) state,
                    trim(a.zip) zip,
                    trim(a.country) country
             from &1.bi_customer@&3 m
             inner join &1.bi_address@&3b a
             on (m.customer_id = a.customer_id and a.address_id = m.BILL_TO_ADDRESS)
             where (m.ADD_DT >= to_char(sysdate-1,'DD-MON-YY') OR m.MODIFY_DT >= to_char(sysdate-1,'DD-MON-YY'))
       ) src
on (trg.customer_id = src.customer_id)
when matched then
update set
trg.addr1_default=src.addr1,
trg.addr2_default=src.addr2,
trg.addr3_default=src.addr3,
trg.city_default=src.city,
trg.state_default=src.state,
trg.zipcode_default=src.zip,
trg.country_default=src.country;

commit;


exec DBMS_MVIEW.refresh('SDMRK.mv_web_folderid_lkup', 'C', ATOMIC_REFRESH => false);

exit;
