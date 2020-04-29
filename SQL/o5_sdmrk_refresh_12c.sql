whenever sqlerror exit failure
set serveroutput on
set pagesize 0
set tab off
SET LINESIZE 10000
set timing on

SELECT 'Alter table for nologging - SDMRK.O5_ORDERS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
ALTER TABLE SDMRK.O5_ORDERS NOLOGGING;


SELECT 'Truncate table SDMRK.O5_ORDERS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_ORDERS REUSE STORAGE;

--Disable indexes for O5_Orders
DECLARE
BEGIN
  FOR R1 IN
  (SELECT INDEX_NAME,OWNER,TABLE_NAME
  FROM ALL_INDEXES
  WHERE TABLE_NAME = 'O5_ORDERS' and OWNER = 'SDMRK'
  )
  Loop
    begin
    EXECUTE IMMEDIATE 'ALTER INDEX '|| R1.Index_Name|| 'ON SDMRK.O5_ORDERS DISABLE';
    Exception When Others Then
    null;
   end;
    END LOOP;
END;
/
---
SELECT 'Insert into SDMRK.O5_ORDERS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_ORDERS
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
MORE_NUMBER,
csr_id,
SRIND)
   SELECT ORDERNUM Order_Number,
          LINENUM Order_Line_Number,
     --     TRUNC (ORDERDATE) Orderdate,
	        ORDERDATE Orderdate,
          ORDERSTATUS Order_Line_Status,
          ORDER_HEADER_STATUS Order_Header_Status,
          (CASE
              WHEN lower(ORDER_SOURCE) IN ('off5th_mobile') THEN 'off5th_tel'
              ELSE ORDER_SOURCE
           END) ORDER_SOURCE,
          CUSTOMERNUM Customer_Number,
          FREIGHT Freight_Charges,
          SHIPVIA Ship_Via,
          CANCEL_DOLLARS Cancellation_Dollars,
          RETURN_DOLLARS Return_Dollars,
          TAX Tax,
          TRUNC (CANCELDATE) Cancel_Date,
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
          TRUNC (SHIPDATE) Ship_Date,
          CC_TYPE_ID Credit_Card_Type,
          CC_TYPE_DESC Credit_Card_Description,
          BILL_TO_ADDRESS_ID Bill_to_Address_ID,
          SHIP_TO_ADDRESS_ID Ship_to_Address_ID,
          STORENUM Store_Number,
          TRUNC (RETURNDATE) Return_Date,
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
MORE_NUMBER,
csr_id,
SRIND
FROM
(
  SELECT ordernum ordernum,
    orderhdr,
    orderdet linenum,
    orderseq orderdetailseq,
 --   TRUNC (orderdate) orderdate,
    orderdate orderdate,
    orderdate orderdate_time,
    TRUNC (orderdate) entrydate,
    ordline_status orderstatus,
    ordhdr_status order_header_status,
    ORDER_SOURCE,
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
    (CASE
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394177'
                 THEN
                    9
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394178'
                 THEN
                    1
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394179'
                 THEN
                    2
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394180'
                 THEN
                    5
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394181'
                 THEN
                    3
                 WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) = '7037973929394182'
                 THEN
                    6
                 ELSE
                    0
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
      THEN TRUNC (ordline_modifydate)
    END) datereserved,
    TO_CHAR (orderdate, 'HH24MMSS') entrytime,
    (
    CASE
      WHEN ordline_status = 'X'
      THEN TRUNC (ordline_modifydate)
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
      THEN TRUNC (ordline_modifydate)
      ELSE NULL
    END) returndate,
    TRUNC (ordline_modifydate) lastchangedate,
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
MORE_NUMBER,
csr_id,
SRIND
  FROM o5.Bi_Sale@reportdb
  where ORDERDATE>='01-jan-2004'
  )
  where LINENUM is not null
    AND order_header_status not in ('N')
;
COMMIT;

---- Rebuild indexes for ORDERS
DECLARE
BEGIN
  FOR R1 IN
  (SELECT INDEX_NAME,OWNER,TABLE_NAME
  FROM ALL_INDEXES
  WHERE TABLE_NAME = 'O5_ORDERS' and OWNER = 'SDMRK'
  )
  Loop
    begin
    EXECUTE IMMEDIATE 'ALTER INDEX '|| R1.Index_Name|| 'ON SDMRK.O5_ORDERS REBUILD';
    Exception When Others Then
    null;
   end;
    END LOOP;
END;
/

SELECT 'Alter table for nologging for SDMRK.O5_PRODUCT:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
ALTER TABLE SDMRK.O5_PRODUCT NOLOGGING;

--  Re Fresh Product
SELECT 'Truncate table SDMRK.O5_PRODUCT: ' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_PRODUCT REUSE STORAGE;
COMMIT;

--Disable indexes for Product
DECLARE
BEGIN
  FOR R1 IN
  (SELECT INDEX_NAME,OWNER,TABLE_NAME
  FROM ALL_INDEXES
  WHERE TABLE_NAME = 'O5_PRODUCT' and OWNER = 'SDMRK'
  )
  Loop
    begin
    EXECUTE IMMEDIATE 'ALTER INDEX '|| R1.Index_Name|| 'ON SDMRK.O5_PRODUCT DISABLE';
    Exception When Others Then
    null;
   end;
    END LOOP;
END;
/

SELECT 'Insert into SDMRK.O5_PRODUCT:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;

INSERT INTO SDMRK.O5_PRODUCT
          (UPC ,
          SKU ,
          SKU_DESCRIPTION ,
          ITEM ,
          ITEM_DESCRIPTION ,
          Vendor_Style_Number,
          Department_ID,
          SKU_List_Price,
          SKU_Sale_Price,
          Item_list_Price,
          Item_Cost,
          SKU_Size,
          SKU_Color_Code,
          SKU_Color,
          First_Receipt_Date,
          Last_Receipt_Date,
          Analysis_Code_1,
          Warehouse_Sellable_Units,
          Warehouse_Backorder_Units,
          Active_Indicator,
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
          STORE_INVENTORY,
          PRD_ID,
          DEACTIVE_IND,
          COMPARE_PRICE,
          readyforprod_flag
)
   SELECT a.UPC UPC,
          SKU SKU,
          SKU_DESCRIPTION SKU_Description,
          ITEM Item,
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
          WH_SELLABLE_QTY Warehouse_Sellable_Units,
          WH_BACKORDER_QTY Warehouse_Backorder_Units,
          ACTIVE_IND Active_Indicator,
          SELLOFF_IND Sell_Off_Indicator,
          DROPSHIP_IND Dropship_Indicator,
          GWP_ELIG_IND GWP_Eligibility_Indicator,
          REPLENISH_IND Replenish_Indicator,
          GWP_FLAG_IND GWP_Flag,
          WEB_ITM_FLG Web_Item_Flag,
          GROUP_ID GROUP_ID,
          DIVISION_ID Division_ID,
          VENDOR_ID Vendor_ID,
          PRICE_STATUS price_status,
          BRAND_NAME brand_name,
          NVL(a.PRODUCT_CODE,a.ITEM) PRODUCT_CODE,
          s.in_store_qty as STORE_INVENTORY,
          a.product_code PRD_ID,
          a.DEACTIVE_IND,
          DECODE(NVL(a.COMPARE_PRICE,0),0,NVL(a.ITEM_LIST_PRICE,0),NVL(a.COMPARE_PRICE,0)) COMPARE_PRICE,
          case when READYFORPROD = 'Yes' then 'T'
          else 'F'
          end
     FROM &1.bi_product@reportdb a,
     &1.inventory@reportdb s
     WHERE a.sku = lpad(s.SKN_NO,13,'0');

commit;

DECLARE
BEGIN
  FOR R1 IN
  (SELECT INDEX_NAME,OWNER,TABLE_NAME
  FROM ALL_INDEXES
  WHERE TABLE_NAME = 'O5_PRODUCT' and OWNER = 'SDMRK'
  )
  Loop
    begin
    EXECUTE IMMEDIATE 'ALTER INDEX '|| R1.Index_Name|| 'ON SDMRK.O5_PRODUCT REBUILD';
    Exception When Others Then
    null;
   end;
    END LOOP;
END;
/


/*
merge into sdmrk.o5_product trg
using (select web_book_dt,final_item_num from &1.bi_pubdate@&3) src
on (NVL(trg.PRODUCT_CODE,trg.ITEM) = src.FINAL_ITEM_NUM)
when matched then
update set trg.web_book_dt = src.web_book_dt;

commit;
*/

merge into sdmrk.o5_product trg
using (select f_rev_char_conversion(replace(replace(initcap(bm_desc),'Amp;',''),'''S','''s'))  bm_desc,
to_date(READYFORPROD_TIMER,'MM/DD/YYYY HH:MI AM') readyforprod_timer, product_id item_id
from o5.ALL_ACTIVE_PIM_PRD_ATTR_O5@reportdb
) src
on (trg.PRODUCT_CODE = src.ITEM_ID)
when matched then
update set trg.bm_desc = src.bm_desc,
           trg.readyforprod_timer = src.readyforprod_timer;
commit;

 --- Fixing the ampersand chars in the product description
 --- Suppress French/Accented characters in BM_DESC as this is being used to trigger email campaigns to Cheetah and Cheetah is unable to translate them
 SELECT 'Update SDMRK.O5_PRODUCT for fixing the ampersand chars and suppress accent characters in the product description: ' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
 DECLARE
 CURSOR REC_CUR IS
 SELECT ROWID FROM SDMRK.O5_PRODUCT;
 TYPE ROWID_T IS TABLE OF VARCHAR2(50);
 ROWID_TAB ROWID_T;
 BEGIN
 OPEN REC_CUR;
 LOOP
 FETCH REC_CUR BULK COLLECT INTO ROWID_TAB LIMIT 5000;
 EXIT WHEN ROWID_TAB.COUNT() = 0;
 FORALL I IN ROWID_TAB.FIRST .. ROWID_TAB.LAST
 UPDATE SDMRK.O5_PRODUCT NOLOGGING
 SET bm_desc = replace(initcap(utl_raw.cast_to_varchar2((nlssort(f_rev_char_conversion(replace(replace(bm_desc,'Amp;',''),'amp;','')),'nls_sort=binary_ai')))),'''S','''s')
 WHERE ROWID = ROWID_TAB(I);
 COMMIT;
 END LOOP;
 CLOSE REC_CUR;
 END;
 /

UPDATE SDMRK.O5_PRODUCT
SET SKU_COLOR = 'BEAT MEN'
WHERE SKU_COLOR like 'BEAT MEN%' ;

commit;

SELECT 'Truncate table SDMRK.O5_INDIVIDUAL:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_INDIVIDUAL;
COMMIT;
SELECT 'Insert into SDMRK.O5_INDIVIDUAL:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_INDIVIDUAL
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
     FROM O5.BI_INDIVIDUAL@reportdb
    WHERE INDIVIDUAL_ID NOT IN (102264328, 102289121);

COMMIT;

---CONSOLIDATING INTERNATIONAL UNKNOWN CUSTOMER TO ONE INDIVIDUAL ID OF 999999999
SELECT 'Truncate table SDMRK.O5_CUSTOMER:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_customer;
COMMIT;

SELECT 'SDMRK.O5_CUSTOMER:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_customer
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
	  ADD_DT
         , REGISTERED_CUSTOMER REGISTERED_CUSTOMER,
	MORE_NUMBER,
	user_id,
	SDMRK.STRING_TO_MD5_HASH(INTERNETADDRESS)
     FROM o5.bi_customer@reportdb
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
SELECT 'Merge into SDMRK.O5_promo_orders:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
MERGE INTO SDMRK.O5_promo_orders hst
     USING (SELECT ordernum,
                   promo_id_01,
                   trim(promo_id_02) promo_id_02 ,
                   promo_id_03,
                   promo_id_04,
                   promo_id_05,
                   promo_id_06,
                   promo_id_07,
                   promo_id_08,
                   promo_id_09,
                   promo_id_10
              FROM o5.bi_promo_sale_wrk@reportdb) trn
        ON (trn.ordernum = hst.ordernum)
WHEN MATCHED
THEN
   UPDATE SET hst.promo_id_01 = trn.promo_id_01,
              hst.promo_id_02 = trn.promo_id_02,
              hst.promo_id_03 = trn.promo_id_03,
              hst.promo_id_04 = trn.promo_id_04,
              hst.promo_id_05 = trn.promo_id_05,
              hst.promo_id_06 = trn.promo_id_06,
              hst.promo_id_07 = trn.promo_id_07,
              hst.promo_id_08 = trn.promo_id_08,
              hst.promo_id_09 = trn.promo_id_09,
              hst.promo_id_10 = trn.promo_id_10
WHEN NOT MATCHED
THEN
   INSERT     (ordernum,
               promo_id_01,
               promo_id_02,
               promo_id_03,
               promo_id_04,
               promo_id_05,
               promo_id_06,
               promo_id_07,
               promo_id_08,
               promo_id_09,
               promo_id_10)
       VALUES (trn.ordernum,
               trn.promo_id_01,
               trn.promo_id_02,
               trn.promo_id_03,
               trn.promo_id_04,
               trn.promo_id_05,
               trn.promo_id_06,
               trn.promo_id_07,
               trn.promo_id_08,
               trn.promo_id_09,
               trn.promo_id_10);

COMMIT;

----email_address
SELECT 'Truncate table SDMRK.O5_EMAIL_ADDRESS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_EMAIL_ADDRESS;

SELECT 'Insert into SDMRK.O5_EMAIL_ADDRESS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_email_address
 (
    EMAIL_ID,
    EMAIL_ADDRESS,
    GENDER,
    OPT_IN ,
    ADD_BY_SOURCE_ID,
    ADD_DT,
    CUSTOMER_ID,
    INTERNATIONAL_IND,
	MORE_NUMBER,
   welcome_promo,
welcome_back_promo,
barcode,
more_opt_in,
SAKS_FIRST,
LOCAL_STORE,
LOCAL_STORE_BY_ZIP,
CANADA_FLAG,
EMAIL_ADDRESS_MD5
 )
SELECT EMAIL_ID,
  EMAIL_ADDRESS,
  GENDER,
  OPT_IN ,
  ADD_BY_SOURCE_ID,
  ADD_DT,
  CUSTOMER_ID,
  INTERNATIONAL_IND,
MORE_NUMBER,
 welcome_promo,
welcome_back_promo,
barcode,
more_opt_in,
SAKS_FIRST,
LOCAL_STORE,
LOCAL_STORE_BY_ZIP,
CANADA_FLAG,
SDMRK.STRING_TO_MD5_HASH(EMAIL_ADDRESS)
FROM O5.EMAIL_ADDRESS@reportdb
WHERE VALID_IND=1;

COMMIT;

SELECT 'Truncate table SDMRK.O5_EMAIL_EVENTS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_email_events;

SELECT 'Insert into table SDMRK.O5_EMAIL_EVENTS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_email_events (EVENTTYPE,
                                   EVENTTIME,
                                   ISSUEID,
                                   RESULTCODE,
                                   MIMETYPE,
                                   SENDTIME,
                                   EID,
                                   BUYER_TYPE,
                                   EMAIL_CNT,
                                   LOAD_DT)
SELECT EVENTTYPE,
          EVENTTIME,
          ISSUEID,
          RESULTCODE,
          MIMETYPE,
          SENDTIME,
          EID,
          BUYER_TYPE,
          EMAIL_CNT,
          SYSDATE
FROM o5.email_events@reportdb;

COMMIT;

SELECT 'Truncate table SDMRK.O5_EMAIL_MAILING_METADATA:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_EMAIL_MAILING_METADATA;

SELECT 'Insert into SDMRK.O5_EMAIL_MAILING_METADATA:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_EMAIL_MAILING_METADATA (ISSUEID,
                                             ISSUENAME,
                                             TIMESENT,
                                             MAILING_ID,
                                             SUBJECT,
                                             MAILING_NAME,
                                             LOAD_DT)
SELECT ISSUEID,
          ISSUENAME,
          TIMESENT,
          MAILING_ID,
          SUBJECT,
          MAILING_NAME,
          SYSDATE
FROM O5.EMAIL_MAILING_METADATA@reportdb;

COMMIT;


---OPT IN/OUT DATA
SELECT 'Truncate table SDMRK.O5_EMAIL_OPT_INOUT:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_EMAIL_OPT_INOUT;

SELECT 'Insert into SDMRK.O5_EMAIL_OPT_INOUT:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_EMAIL_OPT_INOUT (ADD_BY_SOURCE_ID,
                                      CHG_BY_SOURCE_ID,
                                      EMAIL_ADDRESS,
                                      EMAIL_ID,
                                      OPT_DT,
                                      OPT_IN,
                                      OPT_TIME,
                                      LOAD_DT,
                                      REASON)
SELECT ADD_BY_SOURCE_ID,
          CHG_BY_SOURCE_ID,
          EMAIL_ADDRESS,
          EMAIL_ID,
          OPT_DT,
          OPT_IN,
          OPT_TIME,
          SYSDATE,
          REASON
FROM O5.EMAIL_OPT_INOUT@reportdb
;

COMMIT;

SELECT 'Insert into SDMRK.O5_EMAIL_CHANGE_HISTORY:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_EMAIL_CHANGE_HISTORY
  (
    EMAIL_ID,
    OLD_EMAIL_ADDRESS,
    NEW_EMAIL_ADDRESS,
    EMAIL_CHG_DT
  )
SELECT EMAIL_ID,
  OLD_EMAIL_ADDRESS,
  NEW_EMAIL_ADDRESS,
  EMAIL_CHG_DT
FROM o5.Email_Change_History@reportdb;

COMMIT;

SELECT 'Truncate table SDMRK.O5_EMAIL_CHEETAH_SEGMENTS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE  SDMRK.O5_EMAIL_CHEETAH_SEGMENTS;

SELECT 'Insert into SDMRK.O5_EMAIL_CHEETAH_SEGMENTS:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT INTO SDMRK.O5_EMAIL_CHEETAH_SEGMENTS
SELECT * FROM  O5.EMAIL_CHEETAH_SEGMENTS@reportdb;

COMMIT;

SELECT 'truncate into SDMRK.O5_NETSALE:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
TRUNCATE TABLE SDMRK.O5_NETSALE;

SELECT 'Insert into SDMRK.O5_NETSALE:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT into SDMRK.O5_NETSALE
(
  RECTYPE ,
  DIVISION,
  STORE,
  TRANSDATE,
  REGISTER,
  TRANSNUM,
  DEPARTMENT,
  GROSSSALE,
  GROSSRETURN,
  SALEDISCOUNT ,
  RETURNDISCOUNT,
  SALEMARKDOWN,
  RETURNMARKDOWN,
  SALEQTY,
  RETURNQTY,
  ADJUSTMENT ,
  SPECIALSERVICE,
  CLASS ,
  SKU ,
  UPC,
  SLORDERNUM,
  VENDORNUM,
  SKUPC_IND,
  ADD_DT,
  MODIFY_DT,
  BM_ORDERNUM
  )
SELECT
  RECTYPE ,
  DIVISION,
  STORE,
  TRANSDATE,
  REGISTER,
  TRANSNUM,
  DEPARTMENT,
  GROSSSALE,
  GROSSRETURN,
  SALEDISCOUNT ,
  RETURNDISCOUNT,
  SALEMARKDOWN,
  RETURNMARKDOWN,
  SALEQTY,
  RETURNQTY,
  ADJUSTMENT ,
  SPECIALSERVICE,
  CLASS ,
  SKU ,
  UPC,
  SLORDERNUM,
  VENDORNUM,
  SKUPC_IND,
  sysdate,
  MODIFY_DT,
  BM_ORDERNUM
from O5.BI_NETSALE@reportdb
where transdate >='01-jan-2008';

COMMIT;
SELECT 'Truncate table SDMRK.O5_NEW_ARRIVAL:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
truncate table sdmrk.o5_new_arrival;

SELECT 'Insert into SDMRK.O5_NEW_ARRIVAL:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
INSERT into sdmrk.o5_new_arrival(product_code,new_arrival_date)
select prduct_code,to_date(publish_dt,'MM/DD/YYYY HH:MI AM') publish_dt
from o5.SFCC_PROD_PRODUCT_DATA@reportdb r;

COMMIT;

SELECT 'MV Refreh - mv_o5_web_folderid_lkup:' || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss') FROM DUAL;
exec DBMS_MVIEW.refresh('SDMRK.mv_o5_web_folderid_lkup', 'C', ATOMIC_REFRESH => false);

exit
