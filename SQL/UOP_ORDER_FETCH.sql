SET SERVEROUTPUT ON
SET ECHO ON
SET FEEDBACK OFF
SET VERIFY OFF

DECLARE
    
    v_process VARCHAR2(500);
    v_process_st_time VARCHAR2(50);
    v_process_end_time VARCHAR2(50);
    v_banner VARCHAR2(10);
    c_new NUMBER DEFAULT 0; c_upd_cancel NUMBER DEFAULT 0; c_upd_exis NUMBER DEFAULT 0; 
    c_loop_m NUMBER DEFAULT 0; 
    no_record_found EXCEPTION;
    deadlock_detected EXCEPTION;
    
CURSOR c_order_data 
IS
WITH all_order_data AS (
    SELECT
        NULL                                    AS orderhdr,           --Changed from BM to OMS
        to_number(ord.orderdet)                 AS orderdet,           --Temporary till SFCC Goes Live
        row_number() OVER (PARTITION BY ord.order_header_key ORDER BY ord.order_line_key) AS orderseq,  -- Changed to Order Line SEQ 
        to_number(nvl(cust.customer_id, cust.bill_to_key))             AS createfor, -- Assuming Registered Customers will Have GENERIC_ATTRIBUTE1 populated, Guest Using BILL_TO_KEY
        NULL                                    AS extponum,
        to_number(ord.order_no)                 AS ordernum,
        ord.h_createts                          AS orderdate,
        ord.h_modifyts                          AS ordermodifydate,
        NULL                                    AS ordhdr_status,                                        -- No Value to be populated --Changed from BM to OMS
        CASE
            WHEN ord.order_line_status_id  IN ('1000','1040','1050','1100') THEN 'L'                                -- New As the Order is Created in OMS.
            WHEN ord.order_line_status_id  IN ('1300','1500','1600','2100','2100.1','3200.2','3200'/*,'3350.1','3350.15','3350.2','3350.25','3350.3','3350.35',' 3350.4' */ ) THEN 'S' -- IN PROGRESS
            WHEN ord.order_line_status_id  IN ('3350.1','3350.10','3350.15','3350.20','3350.25','3350.30','3350.35','3350.40' ) THEN 'P' -- Confirmed Please check if this is Correct with Team
            WHEN ord.order_line_status_id  IN ('3700.01.001','3700.01.002','3700.01.003','3700.01.004','3700.02') THEN 'R'    -- Return
            WHEN ord.order_line_status_id  IN ('3700','3700.7','3700.3') THEN 'D'                                   -- Shipped / Delivered
            WHEN ord.order_line_status_id  IN ('9000') THEN 'X'                                                     -- Cancelled
            WHEN ord.order_line_status_id  IN ('2100.100','2130','2130.01','2140','2141','2160','2160.01') THEN 'U'   -- PO Sent Sent to Vendor for DropShip Items
            WHEN ord.order_line_status_id  IN ('1400') THEN 'UN'   -- Unknown At this Point where to Put this Group
         ELSE ord.order_line_status_id
        END                                                       AS ordline_status,              -- Changed from BM to OMS
        CASE WHEN h_order_entry_type = 'Online' AND h_order_entered_by = 'MAPP' THEN 'MOB'
             WHEN h_order_entry_type = 'Call Center' THEN 'TEL'
             WHEN h_order_entry_type = 'Online' THEN 'WEB'
             WHEN h_order_entry_type = 'POS' THEN 'STR'
          ELSE substr(h_order_entry_type,1,3)
        END                                         AS ordertype,                                   -- Changed from BM to OMS
        substr(TRIM(ord.h_promo_used),1,50)         AS promo_id,                                    -- Changed from BM to OMS OR Change the PROMO Column to 100
        SUM(ord.l_shippingcharge + ord.l_shippingsurcharge) OVER( PARTITION BY ord.order_header_key ) AS freight_amt,
        NULL                                        AS giftorder_ind,                               -- Check the Column is null in Target orl_grg_id in Order Line is never Populated
        ord.l_list_price                                                AS orig_price_amt,          -- Price Per Unit 
        CASE WHEN ord.order_line_status_id  IN ('9000') THEN NULL 
             WHEN ord.l_ordered_qty = 0 THEN ord.l_list_price - ord.l_discount_actual
             ELSE ord.l_list_price - ( ord.l_discount_actual / ord.l_ordered_qty ) 
         END                                                            AS offernprice_amt,         -- Price Per Unit Less Discount
        CASE WHEN ord.order_line_status_id  IN ('9000') THEN NULL 
             WHEN ord.l_ordered_qty = 0 THEN ord.l_list_price - ord.l_discount_actual
             ELSE ( ord.l_list_price - ( ord.l_discount_actual / ord.l_ordered_qty ) ) * ord.l_ordered_qty
         END                                                            AS extend_price_amt,        -- Price Per Unit Less Discount * QTY
        CASE WHEN ord.order_line_status_id  IN ('9000') THEN NULL ELSE ord.l_ordered_qty END    AS qtyordered,
        CASE WHEN ord.order_line_status_id  IN ('9000') THEN NULL 
             WHEN ord.l_ordered_qty = 0 THEN round(ord.l_tax / ( ord.l_list_price - ord.l_discount_actual ),2)
             ELSE round(ord.l_tax / ( ord.l_list_price - ( ord.l_discount_actual / ord.l_ordered_qty )) * 100 ,2) 
         END AS taxrate_amt,
        CASE WHEN ord.order_line_status_id  IN ('9000') THEN NULL ELSE ord.l_discount_actual + ord.l_discount_associate END AS discount_amt,
        NULL                                        AS bm_skuid,                                        -- Changed from BM to OMS, Not Needed Any More
        to_number(ord.bill_to_id)                   AS bill_to_address_id,                              -- Need to Check With Team
        NULL                                        AS sourcecodedetail,
        CASE WHEN v_banner = 'O5' THEN NULL
             WHEN v_banner = 'SAKS' THEN 
                CASE WHEN ord.h_promo_used  LIKE '%SFELITE%'
                    OR ord.h_promo_used  LIKE '%SFDIAMOND%' 
                    OR ord.h_promo_used  LIKE '%SFPREMIER%'
                    OR ord.h_promo_used  LIKE '%SFPLAT%'
                    OR ord.h_promo_used  LIKE '%SFLIMIT%'
                    THEN 'T' 
                 ELSE 'F' 
                END
         END                                                                  AS saksfirst_ind,
        CASE WHEN v_banner = 'O5' THEN NULL
             WHEN v_banner = 'SAKS' THEN 
             	CASE WHEN ord.h_promo_used  LIKE '%SFELITE%'
                	OR ord.h_promo_used  LIKE '%SFDIAMOND%' 
                	OR ord.h_promo_used  LIKE '%SFPREMIER%'
                	OR ord.h_promo_used  LIKE '%SFPLAT%'
                	OR ord.h_promo_used  LIKE '%SFLIMIT%'
                	THEN 'T' 
                	ELSE 'F' 
                END
         END                                                                  AS saksifirst_freeship_ind,
        ord.site_refer                                                        AS refer_id,
        CASE WHEN ord.l_discount_associate <> 0 THEN 'T' ELSE 'F' END         AS employee_ind,
        CASE WHEN ord.l_giftwrapcharge <> 0 THEN 'T' ELSE 'F' END             AS giftwrap_ind,
        CASE WHEN nvl(giftwrap_message,'X') <> 'X' THEN 'T' ELSE 'F' END      AS giftwrap_msg_ind,
        CASE WHEN l_line_type = 'PREORDER' THEN 'T' ELSE 'F' END              AS backorder_ind,
        ord.l_po_date                                                         AS podate,
        NULL                                                                  AS ponum,--Yet to Identify the details
--        case when ord.order_line_status_id  in ('9000') then ord.l_reason_code  else null end   as cancelreason,
        CASE 
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'CSR Cancel-Customer Request' THEN 'YD'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'CSR Cancel-Customer Request' THEN 'YR'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Customer Service Cancel' THEN 'C2'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Fraud' THEN 'F1'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Credit Hard Decline - Bank or SVC' THEN 'H2'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'No Inventory System Cancel-Overnight' THEN 'B'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'System Issues - Inventory Overstated' THEN 'S1'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Customer Cancel-20 minute window' THEN 'YR'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Item not Consistent with Picture on Web' THEN 'D2'
            WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'No Inventory System Cancel' THEN 'A'
            -- WHEN ord.order_line_status_id = '9000' AND ord.l_reason_code = 'Generic Cancel' THEN 'GC'
            WHEN ord.order_line_status_id = '9000' THEN 'GC' -- This includes GenericCancel for which we donot have direct mapping, refer ODI or above filter
        ELSE NULL END   AS cancelreason,    
--        NULL                      AS sl_sale_price,
        round(ord.l_list_price * 100, 0) AS sl_sale_price,
        NULL                      AS slordernum,
        to_number(CASE WHEN cust.shipnode_key LIKE 'DC%' THEN substr(cust.shipnode_key,-3) 
                       WHEN LENGTH(cust.shipnode_key) > 3 THEN substr(cust.shipnode_key,2)
                  ELSE cust.shipnode_key 
                  END)            AS storenum,
        CASE WHEN cust.shipnode_key LIKE 'DC%' THEN 'F' ELSE 'T' END            AS fillloc, -- This Indicates /Attributes/Inventory/Location_Ind
        CASE WHEN ord.order_line_status_id  IN ('3700.01.001','3700.01.002','3700.01.003','3700.01.004','3700.02') THEN ord.l_reason_code  ELSE NULL END   AS returnreason,
        NULL                      AS returntendertype,
        TO_DATE(to_char(to_timestamp(cust.shipping_date),'DD-MON-YY HH24:MI:SS'),'DD-MON-YYYY HH24:MI:SS')        AS shipdate,
--        case when cust.shipping_option = ',' then null else cust.shipping_option end shipping_option,
        -- Change the Case ID Values for O5th
        CASE WHEN v_banner = 'O5' THEN 
            CASE 
                WHEN LOWER(cust.shipping_option) LIKE '%saturday%' THEN 7037973929394182         -- Saturday
                WHEN LOWER(cust.shipping_option) LIKE '%2%day%' OR  LOWER(shipping_option) LIKE '%two%day%' OR LOWER(shipping_option) LIKE '%Express%Saver%' THEN 7037973929394179  -- Rush 2-3 Business days
                WHEN LOWER(cust.shipping_option) LIKE '%usps%standard%' OR  LOWER(shipping_option) LIKE '%upsn%ground%' THEN 7037973929394177    -- USPS Standard
                WHEN LOWER(cust.shipping_option) LIKE '%overnight%' THEN 7037973929394180    -- Next Bus. Day
                WHEN cust.shipping_option LIKE '%AK%HI%' THEN 7037973929394181    -- StandardHawaiiAlaska
             ELSE 7037973929394178 -- Standard (4-6 Bus. Days)
            END
            WHEN v_banner = 'SAKS' THEN 
            CASE 
                WHEN LOWER(cust.shipping_option) LIKE '%saturday%' THEN 7037973933758655         -- Saturday
                WHEN LOWER(cust.shipping_option) LIKE '%2%day%' OR  LOWER(shipping_option) LIKE '%two%day%' OR LOWER(shipping_option) LIKE '%Express%Saver%' THEN 7037973930820219  -- Rush 2-3 Business days
                WHEN LOWER(cust.shipping_option) LIKE '%usps%standard%' OR  LOWER(shipping_option) LIKE '%upsn%ground%' THEN 7037973929808295    -- USPS Standard
                WHEN LOWER(cust.shipping_option) LIKE '%overnight%' THEN 7037973933227467    -- Next Bus. Day
                WHEN cust.shipping_option LIKE '%AK%HI%' THEN 7037973933441469    -- StandardHawaiiAlaska
             ELSE 7037973930820217 -- Standard (4-6 Bus. Days)
            END 
        END                                       AS shipmethod,
        --Specific to Each Banner Change Case ID Values for O5th
        to_number(ord.ship_to_id)                 AS ship_to_address_id,
        ord.customer_contact_id                   AS customernumber,
        NULL                                      AS bmsku_ind,
        NULL                                      AS ccd_id,
        ord.h_payment_card_type                   AS ccd_brand,
        NULL                                      AS holdreason,
        ord.load_date                             AS add_dt,
        ord.last_update_date                      AS modify_dt,
        ord.l_modifyts                            AS ordline_modifydate,
        NULL                                      AS sl_cancel_dte,
        NULL                                      AS sl_return_dte,
        NULL                                      AS markdown_amt,
        nvl(ord.l_discount_actual,0)              AS linepromo_amt,
        nvl(ord.l_discount_associate,0)           AS assocdisc_amt,
        NULL                                      AS emc_number,
        NULL                                      AS fstv_canrsn,
        NULL                                      AS fstv_ldte,
        NULL                                      AS fst_podate,
        NULL                                      AS commission_assoc2_id,
        NULL                                      AS commission_assoc1_id,
        NULL                                      AS commission_assoc2_nm,
        NULL                                      AS commission_assoc1_nm,
        cust.first_name                           AS ship_first_name,
        cust.middle_name                          AS ship_middle_name,
        cust.last_name                            AS ship_last_name,
        regexp_substr(cust.shipping_address, '[^,]+', 1, 1) AS ship_addr1, 
        regexp_substr(cust.shipping_address, '[^,]+', 1, 2) AS ship_addr2,
        regexp_substr(cust.shipping_address, '[^,]+', 1, 3) AS ship_addr3,
--        regexp_substr(cust.shipping_address, '[^,]+', 1, 4) AS ship_addr4,
        cust.s_city	                              AS ship_city,
        cust.s_state	                          AS ship_state,
        cust.s_zipcode                            AS ship_zipcode,
        cust.s_country                            AS ship_country,
        ord.is_e4x_order                          AS international_ind, --e4x_order,                   --Used for Internation_ind
        SUM(ord.l_line_total) OVER( PARTITION BY ord.order_header_key ) AS sub_total,
        ord.l_tax                               AS line_tax,
        ord.l_shippingcharge                    AS total_shipping,
        ord.l_giftwrapcharge                    AS gift_wrap_fee,
        NULL                                    AS affiliate_id,
        NULL                                    AS tax_on_shipping,              --Did not Find it in OMS
        NULL                                    AS off5th_item,                  --NA for Saks
        NULL                                    AS offprice_item,                --NA for Saks
        NULL                                    AS outletitem,                   --Not used any more
        NULL                                    AS rpt_flash,
        NULL                                    AS rpt_anytime,
        NULL                                    AS offer,
        NULL                                    AS household_id,
        NULL                                    AS individual_id,
        NULL                                    AS division_id,
        NULL                                    AS GROUP_ID,
        NULL                                    AS department_id,
        NULL                                    AS vendor_id,
        ord.product_code                        AS product_id,
        ord.skn_no                              AS sku,
        NULL                                    AS item,
        CASE WHEN ord.order_line_status_id IN ('9000') THEN ord.l_ret_can_date  ELSE NULL END  AS canceldate,
        CASE WHEN cust.shipnode_key LIKE 'DC%' THEN 'DC' ELSE 'STORES' END AS fullfilllocation,
        ord.h_order_entry_type                  AS order_source,
        NULL                                    AS more_number,
        NULL                                    AS csr_id,
        NULL                                    AS customer_display_price,
        ord.shoprunner_ind                      AS sr_ind,
        ord.shoprunner_tok                      AS shoprunner_token, 
        cust.tracking_no                        AS tracking_number,
        to_number(ord.order_header_key)         AS order_header_key, 
        to_number(ord.order_line_key)           AS order_line_key,
        CASE WHEN hist.order_line_key IS NOT NULL OR hist.orderdet IS NOT NULL THEN 1 ELSE 0 END AS f_existing_order,
        CASE WHEN ord.orderdet IS NULL THEN to_number(ord.order_line_key) ELSE to_number(ord.orderdet) END AS f_matching_criteria -- To Handle Switch from BM to SFCC
--        CASE WHEN hist.orderdet IS NOT NULL THEN 1 ELSE 0 END AS f_existing_order
--        CASE WHEN hist.order_line_key IS NOT NULL THEN 1 ELSE 0 END AS f_existing_order
-- Extra
        CASE WHEN ord.order_line_status_id IN ('3700.01.001','3700.01.002','3700.01.003','3700.01.004','3700.02') THEN ord.l_ret_can_date  ELSE NULL END  AS returndate,
        ord.giftwrap_message      AS giftwrap_message,
    FROM &1.t_so5_order_line_info      ord
    JOIN &1.t_so5_ord_cust_ship_dtls   cust ON ord.order_line_key = cust.order_line_key
    LEFT JOIN (SELECT order_line_key, orderdet FROM O5.bi_sale_ddw) hist ON ( ord.order_line_key = hist.order_line_key OR to_number(ord.orderdet) = hist.orderdet )
--    LEFT JOIN (SELECT order_line_key FROM bi_sale) hist ON ord.order_line_key = hist.order_line_key
--    LEFT JOIN (SELECT orderdet FROM O5.bi_sale_ddw) hist ON to_number(ord.orderdet) = hist.orderdet
    WHERE  ( (TRUNC(ord.load_date) = TRUNC(sysdate)   OR ord.last_update_date  = TRUNC(sysdate)) 
          OR (TRUNC(cust.load_date) = TRUNC(sysdate)  OR cust.last_update_date = TRUNC(sysdate)) )   
--    WHERE ord.order_line_status_id = orderstatus
) 
SELECT * FROM all_order_data;
--SELECT * FROM all_order_data where rownum < 1500;

--  l_start := DBMS_UTILITY.get_time;
 TYPE l_order IS TABLE OF c_order_data%rowtype;
 ord l_order; 
-- ord_e l_order;      -- Existing Orders
-- ord_ne l_order;     -- Non Existing Orders

-- DEAL WITH ORDERS THAT ARE PRESENT IN BI_SALE

BEGIN
    v_process := 'ORDER PROCESSING - BI_SALE' ;
--    v_banner  := '''O5''';
    v_banner  := CASE WHEN '&1' = 'O5.' THEN '''O5''' WHEN '&1' = 'MREP.' THEN '''MREP''' END;
    v_process_st_time := to_char(sysdate,'DD-MON-RRRR HH.MI.SS AM');
    dbms_output.put_line('Process : ' || v_process || ' Begins at ' || v_process_st_time);
    
-- BEGIN
-- EXAMPLE START
-- Any of the following statements opens the cursor:

--  OPEN c1(emp_name, emp_salary);
--  LOOP
--     FETCH c1 INTO my_record;
--     EXIT WHEN c1%NOTFOUND;
--     -- process data record
--    dbms_output.put_line('Name = ' || my_record.last_name || ', salary = ' || my_record.salary);
--  END LOOP;
-- END;

-- EXAMPLE END

    --Populate Collection with Cursor Data
    OPEN c_order_data;
    LOOP                                                                                                    -- Outer Loop For Cursor
        c_loop_m := c_loop_m + 1;
        FETCH c_order_data BULK COLLECT INTO ord LIMIT 5000;                                                 -- Fetch Limit Records Into Record
--    CLOSE c_order_data;
    --Process Collection Data
        FOR idx IN 1..ord.LAST
        LOOP                                                                                                -- Inner Loop For Record
            IF ord(idx).f_existing_order = 0                                                                -- For Records Not Existing in BI_SALE
            THEN
                c_new := c_new + 1;
                INSERT INTO &1.bi_sale t1
                VALUES (
                    ord(idx).orderhdr,
                    ord(idx).orderdet,
                    ord(idx).orderseq,
                    ord(idx).createfor,
                    ord(idx).extponum,
                    ord(idx).ordernum,
                    ord(idx).orderdate,
                    ord(idx).ordermodifydate,
                    ord(idx).ordhdr_status,
                    ord(idx).ordline_status,
                    ord(idx).ordertype,
                    ord(idx).promo_id,
                    ord(idx).freight_amt,
                    ord(idx).giftorder_ind,
                    ord(idx).orig_price_amt,
                    ord(idx).offernprice_amt,
                    ord(idx).extend_price_amt,
                    ord(idx).qtyordered,
                    ord(idx).taxrate_amt,
                    ord(idx).discount_amt,
                    ord(idx).bm_skuid,
                    ord(idx).bill_to_address_id,
                    ord(idx).sourcecodedetail,
                    ord(idx).saksfirst_ind,
                    ord(idx).saksifirst_freeship_ind,
                    ord(idx).refer_id,
                    ord(idx).employee_ind,
                    ord(idx).giftwrap_ind,
                    ord(idx).giftwrap_msg_ind,
                    ord(idx).backorder_ind,
                    ord(idx).podate,
                    ord(idx).ponum,
                    ord(idx).cancelreason,
                    ord(idx).sl_sale_price,
                    ord(idx).slordernum,
                    ord(idx).storenum,
                    ord(idx).fillloc,
                    ord(idx).returnreason,
                    ord(idx).returntendertype,
                    ord(idx).shipdate,
                    ord(idx).shipmethod,
                    ord(idx).ship_to_address_id,
                    ord(idx).customernumber,
                    ord(idx).bmsku_ind,
                    ord(idx).ccd_id,
                    ord(idx).ccd_brand,
                    ord(idx).holdreason,
                    ord(idx).add_dt,
                    ord(idx).modify_dt,
                    ord(idx).ordline_modifydate,
                    ord(idx).sl_cancel_dte,
                    ord(idx).sl_return_dte,
                    ord(idx).markdown_amt,
                    ord(idx).linepromo_amt,
                    ord(idx).assocdisc_amt,
                    ord(idx).emc_number,
                    ord(idx).fstv_canrsn,
                    ord(idx).fstv_ldte,
                    ord(idx).fst_podate,
                    ord(idx).commission_assoc2_id,
                    ord(idx).commission_assoc1_id,
                    ord(idx).commission_assoc2_nm,
                    ord(idx).commission_assoc1_nm,
                    ord(idx).ship_first_name,
                    ord(idx).ship_middle_name,
                    ord(idx).ship_last_name,
                    ord(idx).ship_addr1,
                    ord(idx).ship_addr2,
                    ord(idx).ship_addr3,
                    ord(idx).ship_city,
                    ord(idx).ship_state,
                    ord(idx).ship_zipcode,
                    ord(idx).ship_country,
                    ord(idx).international_ind,
                    ord(idx).sub_total,
                    ord(idx).line_tax,
                    ord(idx).total_shipping,
                    ord(idx).gift_wrap_fee,
                    ord(idx).affiliate_id,
                    ord(idx).tax_on_shipping,
                    ord(idx).off5th_item,
                    ord(idx).offprice_item,
                    ord(idx).outletitem,
                    ord(idx).rpt_flash,
                    ord(idx).rpt_anytime,
                    ord(idx).offer,
                    ord(idx).household_id,
                    ord(idx).individual_id,
                    ord(idx).division_id,
                    ord(idx).GROUP_ID,
                    ord(idx).department_id,
                    ord(idx).vendor_id,
                    ord(idx).product_id,
                    ord(idx).sku,
                    ord(idx).item,
                    ord(idx).canceldate,
                    ord(idx).fullfilllocation,
                    ord(idx).order_source,
                    ord(idx).more_number,
                    ord(idx).csr_id,
                    ord(idx).customer_display_price,
                    ord(idx).sr_ind,
                    ord(idx).tracking_number,
                    ord(idx).order_header_key,
                    ord(idx).order_line_key,
                    ord(idx).shoprunner_token
                );
            END IF;
            IF ord(idx).f_existing_order = 1 AND ord(idx).ordline_status = 'X'                              -- For Records Existing in BI_SALE and status Cancelled
            THEN
                c_upd_cancel := c_upd_cancel + 1;  
                UPDATE &1.bi_sale t1 
                   SET t1.ordline_status = 'X', 
                       t1.cancelreason  = ord(idx).cancelreason,
                       t1.canceldate    = ord(idx).canceldate
--                 WHERE t1.orderdet = ord(idx).orderdet                                -- To Update Based on ORDERDET
--                   AND  t1.order_header_key = ord(idx).order_header_key               -- May Not be needed
--                 WHERE t1.order_line_key = ord(idx).order_line_key                    -- To Update Based on ORDER_LINE_KEY 
                  WHERE NVL(t1.orderdet,t1.order_line_key) = ord(idx).f_matching_criteria   -- To Update Based on ORDERDET and ORDER_LINE_KEY to handle switch from BM to SFCC
                     ;     
            END IF;
            IF ord(idx).f_existing_order = 1 AND ord(idx).ordline_status <> 'X'                             -- For Records Existing in BI_SALE and status NOT Cancelled 
            THEN
                c_upd_exis := c_upd_exis + 1;
                UPDATE &1.bi_sale t1 
                   SET 
--                        t1.orderhdr = ord(idx).orderhdr,
--                        t1.orderdet = ord(idx).orderdet,
--                        t1.orderseq = ord(idx).orderseq,              -- Not Needed if Existing Order is Update
                        t1.createfor = ord(idx).createfor,
                        t1.extponum = ord(idx).extponum,
--                        t1.ordernum = ord(idx).ordernum,              -- Not Needed if Existing Order is Update
--                        t1.orderdate = ord(idx).orderdate,            -- Not Needed if Existing Order is Update
                        t1.ordermodifydate = ord(idx).ordermodifydate,
--                        t1.ordhdr_status = ord(idx).ordhdr_status,      -- Not Needed if Existing Order is Update
                        t1.ordline_status = ord(idx).ordline_status,
                        t1.ordertype = ord(idx).ordertype,
                        t1.promo_id = ord(idx).promo_id,
                        t1.freight_amt = ord(idx).freight_amt,
                        t1.giftorder_ind = ord(idx).giftorder_ind,
                        t1.orig_price_amt = ord(idx).orig_price_amt,
                        t1.offernprice_amt = ord(idx).offernprice_amt,
                        t1.extend_price_amt = ord(idx).extend_price_amt,
                        t1.qtyordered = ord(idx).qtyordered,
                        t1.taxrate_amt = ord(idx).taxrate_amt,
                        t1.discount_amt = ord(idx).discount_amt,
                        t1.bm_skuid = ord(idx).bm_skuid,
                        t1.bill_to_address_id = ord(idx).bill_to_address_id,
                        t1.sourcecodedetail = ord(idx).sourcecodedetail,
                        t1.saksfirst_ind = ord(idx).saksfirst_ind,
                        t1.saksifirst_freeship_ind = ord(idx).saksifirst_freeship_ind,
                        t1.refer_id = ord(idx).refer_id,
                        t1.employee_ind = ord(idx).employee_ind,
                        t1.giftwrap_ind = ord(idx).giftwrap_ind,
                        t1.giftwrap_msg_ind = ord(idx).giftwrap_msg_ind,
                        t1.backorder_ind = ord(idx).backorder_ind,
                        t1.podate = ord(idx).podate,
                        t1.ponum = ord(idx).ponum,
                        t1.cancelreason = ord(idx).cancelreason,
                        t1.sl_sale_price = ord(idx).sl_sale_price,
                        t1.slordernum = ord(idx).slordernum,
                        t1.storenum = ord(idx).storenum,
                        t1.fill_loc = ord(idx).fillloc,
                        t1.returnreason = ord(idx).returnreason,
                        t1.returntendertype = ord(idx).returntendertype,
                        t1.shipdate = ord(idx).shipdate,
                        t1.shipmethod = ord(idx).shipmethod,
                        t1.ship_to_address_id = ord(idx).ship_to_address_id,
                        t1.customernumber = ord(idx).customernumber,
                        t1.bmsku_ind = ord(idx).bmsku_ind,
                        t1.ccd_id = ord(idx).ccd_id,
                        t1.ccd_brand = ord(idx).ccd_brand,
                        t1.holdreason = ord(idx).holdreason,
                        t1.add_dt = ord(idx).add_dt,
                        t1.modify_dt = ord(idx).modify_dt,
                        t1.ordline_modifydate = ord(idx).ordline_modifydate,
                        t1.sl_cancel_dte = ord(idx).sl_cancel_dte,
                        t1.sl_return_dte = ord(idx).sl_return_dte,
                        t1.markdown_amt = ord(idx).markdown_amt,
                        t1.linepromo_amt = ord(idx).linepromo_amt,
                        t1.assocdisc_amt = ord(idx).assocdisc_amt,
                        t1.emc_number = ord(idx).emc_number,
                        t1.fstv_canrsn = ord(idx).fstv_canrsn,
                        t1.fstv_ldte = ord(idx).fstv_ldte,
                        t1.fst_podate = ord(idx).fst_podate,
                        t1.commission_assoc2_id = ord(idx).commission_assoc2_id,
                        t1.commission_assoc1_id = ord(idx).commission_assoc1_id,
                        t1.commission_assoc2_nm = ord(idx).commission_assoc2_nm,
                        t1.commission_assoc1_nm = ord(idx).commission_assoc1_nm,
                        t1.ship_first_name = ord(idx).ship_first_name,
                        t1.ship_middle_name = ord(idx).ship_middle_name,
                        t1.ship_last_name = ord(idx).ship_last_name,
                        t1.ship_addr1 = ord(idx).ship_addr1,
                        t1.ship_addr2 = ord(idx).ship_addr2,
                        t1.ship_addr3 = ord(idx).ship_addr3,
                        t1.ship_city = ord(idx).ship_city,
                        t1.ship_state = ord(idx).ship_state,
                        t1.ship_zipcode = ord(idx).ship_zipcode,
                        t1.ship_country = ord(idx).ship_country,
                        t1.international_ind = ord(idx).international_ind,
                        t1.sub_total = ord(idx).sub_total,
                        t1.line_tax = ord(idx).line_tax,
                        t1.total_shipping = ord(idx).total_shipping,
                        t1.gift_wrap_fee = ord(idx).gift_wrap_fee,
                        t1.affiliate_id = ord(idx).affiliate_id,
--                        t1.tax_on_shipping = ord(idx).tax_on_shipping,
--                        t1.off5th_item = ord(idx).off5th_item,
--                        t1.offprice_item = ord(idx).offprice_item,
--                        t1.outletitem = ord(idx).outletitem,
--                        t1.rpt_flash = ord(idx).rpt_flash,
--                        t1.rpt_anytime = ord(idx).rpt_anytime,
--                        t1.offer = ord(idx).offer,
--                        t1.household_id = ord(idx).household_id,
--                        t1.individual_id = ord(idx).individual_id,
--                        t1.division_id = ord(idx).division_id,
--                        t1.group_id = ord(idx).group_id,
--                        t1.department_id = ord(idx).department_id,
                        t1.vendor_id = ord(idx).vendor_id,
--                        t1.product_id = ord(idx).product_id,
                        t1.sku = ord(idx).sku,
                        t1.item = ord(idx).item,
                        t1.canceldate = ord(idx).canceldate,
                        t1.fullfilllocation = ord(idx).fullfilllocation,
                        t1.more_number = ord(idx).order_source,
--                        t1.csr_id = ord(idx).more_number,
--                        t1.order_source = ord(idx).csr_id,
--                        t1.customer_display_price = ord(idx).customer_display_price,
                        t1.srind = ord(idx).sr_ind,
                        t1.tracking_number = ord(idx).tracking_number,
    --                    t1.ORDER_HEADER_KEY = ord(idx).ORDER_HEADER_KEY,
    --                    t1.ORDER_LINE_KEY = ord(idx).ORDER_LINE_KEY,
                        t1.sr_token = ord(idx).shoprunner_token
--                 WHERE t1.orderdet = ord(idx).orderdet                                -- To Update Based on ORDERDET
--                   AND  t1.order_header_key = ord(idx).order_header_key               -- May Not be needed
--                 WHERE t1.order_line_key = ord(idx).order_line_key                    -- To Update Based on ORDER_LINE_KEY 
                  WHERE NVL(t1.orderdet,t1.order_line_key) = ord(idx).f_matching_criteria   -- To Update Based on ORDERDET and ORDER_LINE_KEY to handle switch from BM to SFCC
                     ;
            END IF;
        END LOOP;                                                                                           -- Inner Loop For Record
--        DBMS_OUTPUT.PUT_LINE ('No of Existing Orders Modified : ' || ord(idx).ordernum );
--        DBMS_OUTPUT.PUT_LINE ('No of Existing Orders Modified : ' || SQL%BULK_ROWCOUNT(idx) );

        IF c_new > 0 THEN
            dbms_output.put_line ('Loop - ' || c_loop_m || ' : No of New Orders Added : ' || c_new  );
        END IF;
        IF c_upd_cancel > 0 THEN
            dbms_output.put_line ('Loop - ' || c_loop_m || ' : No of Existing Orders Cancelled : ' || c_upd_cancel);
        END IF;
        IF c_upd_exis > 0 THEN
            dbms_output.put_line ('Loop - ' || c_loop_m || ' : No of Existing Orders Modified : ' || c_upd_exis);
        END IF;

        COMMIT;
    EXIT WHEN c_order_data%notfound;                                                                        -- Cursor Exit
    END LOOP;                                                                                               -- Outer Loop Of Cursor
    CLOSE c_order_data;

-- dbms_output.put_line('NO OF NEW ORDERS IDENTIFIED FOR '|| v_banner || ' : ' || c_order_data%rowcount);
v_process_end_time := to_char(sysdate,'DD-MON-RRRR HH.MI.SS AM');
dbms_output.put_line('Process : ' || v_process || ' Completed at ' || v_process_end_time);
COMMIT;

EXCEPTION
    WHEN no_record_found 
        then null;
--        insert into bi_sale_comments values (sysdate, 'No Order Identified', 'RunID : ' || to_char(sysdate,'HH24') );

END;
/
EXIT;