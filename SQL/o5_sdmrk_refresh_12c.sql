whenever sqlerror exit failure
set serveroutput on
set pagesize 0
set tab off
SET LINESIZE 10000
set timing on
--  WEEKLY RE_FRESH SDMRK.O5_ORDERS
TRUNCATE TABLE SDMRK.O5_ORDERS;
COMMIT;
---
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
csr_id)
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
csr_id
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
csr_id
  FROM &1.Bi_Sale@&3
  where ORDERDATE>='01-jan-2004'
  )
  where LINENUM is not null
    AND order_header_status not in ('N')
;

COMMIT;

--merge into SDMRK.O5_ORDERS TRG using
--(select distinct BM_ORDER_NUMBER, DEMANDWARE_ORDER_NUMBER from O5.ORDER_REPORT where BM_ORDER_NUMBER is not null and lower(BM_ORDER_NUMBER)<>'null'
--) SRC ON (to_number(SRC.BM_ORDER_NUMBER)=TRG.ORDER_NUMBER)
--WHEN matched THEN
 -- update
  --set TRG.DW_ORDER_NUMBER=SRC.DEMANDWARE_ORDER_NUMBER
 -- where DW_ORDER_NUMBER is null ;

--COMMIT;

--MERGE INTO SDMRK.O5_ORDERS HST USING
--(SELECT DISTINCT order_number,
--  sku,
--  qs.evt_id,
--  ff.evt_name
--FROM SDMRK.O5_ORDERS O
--INNER JOIN MREP.BI_QUICK_STATS_OFFPRICE QS
--ON TRUNC(O.ORDERDATE) = TRUNC(QS.QS_DT_KEY)
--AND O.SKU             = QS.QS_SKU
--AND O.ITEM_NUMBER     = QS.QS_ITEM
--INNER JOIN SAKS_CUSTOM.FASHION_FIX_EVENTS@O5PROD_SAKS_CUSTOM FF
--ON QS.EVT_ID = FF.EVT_ID
--AND TRUNC(o.orderdate) BETWEEN TRUNC(evt_vip_start_dt) AND TRUNC(evt_end_dt)
--WHERE NVL(QS.EVT_ID,'99999') <> '99999'
---AND o.flash_ind               = 'T'
--AND o.evt_id                 IS NULL
--) TRN ON (trn.order_number    = hst.order_number AND hst.sku = trn.sku)
--WHEN MATCHED THEN
--  UPDATE SET HST.EVT_ID = TRN.EVT_ID, hst.evt_name = trn.evt_name;
--  COMMIT;
--
ANALYZE TABLE SDMRK.O5_ORDERS ESTIMATE STATISTICS;
--  Re Fresh Product

TRUNCATE TABLE SDMRK.O5_PRODUCT;
COMMIT;

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
          DEACTIVE_IND
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
          s.in_store_qty as "STORE_INVENTORY",
          p.product_code PRD_ID,
          a.DEACTIVE_IND
     FROM &1.bi_product a,
     &1.inventory s ,
     &1.all_active_product_sku_&2 p
     WHERE a.UPC = lpad(s.SKN_NO(+),13,0)
     and a.PRODUCT_CODE = p.upc;

commit;

merge into sdmrk.o5_product trg
using (select web_book_dt,final_item_num from &1.bi_pubdate@&3) src
on (NVL(trg.PRODUCT_CODE,trg.ITEM) = src.FINAL_ITEM_NUM)
when matched then
update set trg.web_book_dt = src.web_book_dt;

commit;

merge into sdmrk.o5_product trg
using (select initcap(bm_desc) bm_desc, item_id from &1.bi_product_id@&3) src
on (NVL(trg.PRODUCT_CODE,trg.ITEM) = src.ITEM_ID)
when matched then
update set trg.bm_desc = src.bm_desc;

commit;

merge into sdmrk.o5_product trg
using (   select
        PRODUCT_ID product_code,
        PRD_READYFORPROD readyforprod_flag
 from &1.all_active_pim_prd_attr_&2
  ) src
on (trg.product_code = src.product_code)
when matched then
update set trg.readyforprod_flag = src.readyforprod_flag;

commit;

merge into sdmrk.o5_product trg
using (  select
        PRODUCT_ID product_code,
        READYFORPROD_TIMER readyforprod_timer
 from &1.all_active_pim_prd_attr_&2
  ) src
on (trg.product_code = src.product_code)
when matched then
update set trg.readyforprod_timer = src.readyforprod_timer;

commit;

UPDATE SDMRK.O5_PRODUCT
SET SKU_COLOR = 'BEAT MEN'
WHERE SKU_COLOR like 'BEAT MEN%' ;

commit;

ANALYZE TABLE SDMRK.O5_PRODUCT ESTIMATE STATISTICS;
COMMIT;

TRUNCATE TABLE SDMRK.O5_INDIVIDUAL;
commit;

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
     FROM &1.BI_INDIVIDUAL@&3
    WHERE INDIVIDUAL_ID NOT IN (102264328, 102289121);

COMMIT;

---CONSOLIDATING INTERNATIONAL UNKNOWN CUSTOMER TO ONE INDIVIDUAL ID OF 999999999



ANALYZE TABLE SDMRK.O5_INDIVIDUAL ESTIMATE STATISTICS;
COMMIT;
TRUNCATE TABLE SDMRK.O5_customer;
COMMIT;


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
ANALYZE TABLE SDMRK.O5_CUSTOMER ESTIMATE STATISTICS;
COMMIT;

merge into sdmrk.O5_Demandware_users trg
using (SELECT distinct email_address, demandware_userid
       from  &1.O5_Demandware_users@&3) hst
on (upper(trim(trg.email_address))=upper(trim(hst.email_address)))
when not matched then insert (email_address, demandware_userid) values
(hst.email_address, hst.demandware_userid);
COMMIT;
ANALYZE TABLE SDMRK.O5_Demandware_users ESTIMATE STATISTICS;
COMMIT;

--PROMO_ORDERS

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
              FROM &1.bi_promo_sale_wrk@&3) trn
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

ANALYZE TABLE SDMRK.O5_promo_orders ESTIMATE STATISTICS;
COMMIT;
----email_addres

TRUNCATE TABLE SDMRK.O5_EMAIL_ADDRESS; 

INSERT
  /*+ append */
INTO SDMRK.O5_email_address
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
FROM &1.EMAIL_ADDRESS@&3
WHERE VALID_IND=1;

commit;

-----email events

TRUNCATE TABLE SDMRK.O5_email_events;

INSERT                                                           /*+ append */
      INTO                SDMRK.O5_email_events (EVENTTYPE,
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
     FROM &1.email_events@&3;

COMMIT;

ANALYZE TABLE SDMRK.O5_email_events ESTIMATE STATISTICS;


TRUNCATE TABLE SDMRK.O5_EMAIL_MAILING_METADATA;

INSERT                                                           /*+ append */
      INTO                SDMRK.O5_EMAIL_MAILING_METADATA (ISSUEID,
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
     FROM &1.EMAIL_MAILING_METADATA@&3;

COMMIT;

ANALYZE TABLE SDMRK.O5_EMAIL_MAILING_METADATA ESTIMATE STATISTICS;

---OPT IN/OUT DATA

TRUNCATE TABLE SDMRK.O5_EMAIL_OPT_INOUT;

INSERT                                                           /*+ append */
      INTO                SDMRK.O5_EMAIL_OPT_INOUT (ADD_BY_SOURCE_ID,
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
     FROM &1.EMAIL_OPT_INOUT@&3
    ;

COMMIT;

ANALYZE TABLE SDMRK.O5_EMAIL_OPT_INOUT ESTIMATE STATISTICS;

truncate table SDMRK.O5_EMAIL_CHANGE_HISTORY;

INSERT /*+ append */
INTO SDMRK.O5_EMAIL_CHANGE_HISTORY
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
FROM &1.Email_Change_History@&3;

commit;

ANALYZE TABLE SDMRK.O5_EMAIL_CHANGE_HISTORY ESTIMATE STATISTICS;

TRUNCATE TABLE  SDMRK.O5_EMAIL_CHEETAH_SEGMENTS;

INSERT  /*+ append */ INTO SDMRK.O5_EMAIL_CHEETAH_SEGMENTS
SELECT * FROM  &1.EMAIL_CHEETAH_SEGMENTS@&3;

COMMIT;

ANALYZE TABLE SDMRK.O5_EMAIL_CHEETAH_SEGMENTS  ESTIMATE STATISTICS;

--Netsale information
truncate table SDMRK.O5_netsale;

insert /*+ append */ into SDMRK.O5_NETSALE
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
select 
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
from &1.BI_NETSALE@&3
where transdate >='01-jan-2008';

commit;

truncate table sdmrk.o5_new_arrival;

insert into sdmrk.o5_new_arrival(product_code,new_arrival_date) 
select item_id product_code,tstamp displayablearrivaldate from &1.t_new_arrival_date_update_rfp;

commit;

exec DBMS_MVIEW.refresh('SDMRK.mv_o5_web_folderid_lkup', 'C', ATOMIC_REFRESH => false);

exit
