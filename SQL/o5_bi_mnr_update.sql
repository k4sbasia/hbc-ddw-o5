WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
--Order info update from sddw
--Modified by Rajesh on 3/15/2011 to add employee_ind,cancelreason,international
--Modified by Jayanthi on 09/06 to add fashion_fix_item field in the bi_mnr_orders table
MERGE INTO &1.bi_mnr_orders hst
   USING (SELECT DISTINCT s.orderhdr order_header, s.orderdet linenum,
                          s.ordernum order_number,
                          c.firstname || ' ' || c.lastname customer_name,
                          s.customernumber customer_number,
                          s.orderdate created_on,
                          s.ordline_modifydate modified_on,
                          c.addr1 billing_address1, c.addr2 billing_address2,
                          c.city billing_city, c.state billing_state,
                          c.zipcode billing_zip, c.home_ph phone,
                          c.internetaddress email_address,
                          s.orderdet order_line_number, p.item product_code,
                          p.item_description description,
                          s.ordline_status status, s.qtyordered qty,
                          s.orig_price_amt price,
                          s.extend_price_amt extended_price,
                         (CASE
                              WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) =
                                                            '7037973929394180'
                                 THEN 3
                              WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) =
                                                            '7037973929394178'
                                 THEN 1
                              WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) =
                                                            '7037973929394182'
                                 THEN 6
                              WHEN LTRIM (RTRIM (TO_CHAR (shipmethod))) =
                                                            '7037973929394179'
                                 THEN 2
                              ELSE 0
                           END
                          ) shipping_method,
                          TRUNC (SYSDATE) shipped_dateline,
                          s.ship_addr1 shipping_address1,
                          s.ship_addr2 shipping_address2, s.ship_city,
                          s.ship_state, s.ship_zipcode,
                          s.promo_id promotion_code,
                          s.sl_return_dte return_date,
                         ( case when s.ordline_status = 'R' then
                          to_char(s.sl_return_dte,'YYYYMMDD') ||'-0'||s.STORENUM
                          else null
                          end
                          )return_dateline,
                          s.employee_ind,
                          s.cancelreason,
                          international_ind,
                          p.fashionfix_ind,
                          c.addr3 company_name,
                          s.fullfilllocation,
                          s.tax_on_shipping,
                          s.GIFT_WRAP_FEE,
                          s.tracking_number,
                          s.SAKSFIRST_IND,
                          s.PROMO_ID,
                          s.LINEPROMO_AMT,
                          s.LINE_TAX
                     FROM &1.bi_sale s,
                          &1.bi_customer c,
                          &1.bi_product p
                    WHERE s.createfor = c.customer_id
                      AND s.bm_skuid(+) = p.bm_skuid
                      AND (   (s.orderdate BETWEEN TRUNC (SYSDATE) - 1
                                               AND TRUNC (SYSDATE)
                              )
                           OR (s.ordline_modifydate BETWEEN TRUNC (SYSDATE)
                                                            - 1
                                                        AND TRUNC (SYSDATE)
                              )
                          )) trn
   ON (trn.linenum = hst.linenum)
   WHEN MATCHED THEN
      UPDATE
         SET hst.order_header = trn.order_header,
             hst.customer_name = trn.customer_name,
             hst.customer_number = trn.customer_number,
             hst.created_on = trn.created_on,
             hst.modified_on = trn.modified_on,
             hst.billing_address1 = trn.billing_address1,
             hst.billing_address2 = trn.billing_address2,
             hst.billing_city = trn.billing_city,
             hst.billing_state = trn.billing_state,
             hst.billing_zip = trn.billing_zip, hst.phone = trn.phone,
             hst.email_address = trn.email_address,
             hst.order_line_number = trn.order_line_number,
             hst.product_code = trn.product_code,
             hst.description = trn.description, hst.status = trn.status,
             hst.qty = trn.qty, hst.price = trn.price,
             hst.extended_price = trn.extended_price,
             hst.shipping_method = trn.shipping_method,
             hst.shipped_dateline = trn.shipped_dateline,
             hst.shipping_address1 = trn.shipping_address1,
             hst.shipping_address2 = trn.shipping_address2,
             hst.ship_city = trn.ship_city, hst.ship_state = trn.ship_state,
             hst.ship_zipcode = trn.ship_zipcode,
             hst.promotion_code = trn.promotion_code,
             hst.return_date = trn.return_date,
             hst.return_dateline = trn.return_dateline,
             HST.INTERNATIONAL=trn.international_ind,
             HST.EMPLOYEE=trn.employee_ind,
             hst.cancelreason=trn.cancelreason,
             hst.fashion_fix_item=trn.fashionfix_ind,
             hst.company_name=trn.company_name,
             hst.fullfilllocation = trn.fullfilllocation,
             hst.tax_on_shipping=trn.tax_on_shipping,
             hst.GIFT_WRAP_FEE = trn.GIFT_WRAP_FEE,
             hst.tracking_number = trn.tracking_number,
             hst.saks_first_customer = trn.SAKSFIRST_IND,
             hst.promotion_code = trn.PROMO_ID,
             hst.savings=trn.LINEPROMO_AMT,
             hst.line_tax=trn.line_tax
   WHEN NOT MATCHED THEN
      INSERT (order_header, linenum, order_number, customer_name,
              customer_number, created_on, modified_on, billing_address1,
              billing_address2, billing_city, billing_state, billing_zip,
              phone, email_address, order_line_number, product_code,
              description, status, qty, price, extended_price,
              shipping_method, shipped_dateline, shipping_address1,
              shipping_address2, ship_city, ship_state, ship_zipcode,
              promotion_code, return_date,return_dateline,international,
              employee,cancelreason,fashion_fix_item,company_name,fullfilllocation
              ,tax_on_shipping,GIFT_WRAP_FEE ,tracking_number,saks_first_customer,promotion_code,savings,line_tax)
      VALUES (trn.order_header, trn.linenum, trn.order_number,
              trn.customer_name, trn.customer_number, trn.created_on,
              trn.modified_on, trn.billing_address1, trn.billing_address2,
              trn.billing_city, trn.billing_state, trn.billing_zip, trn.phone,
              trn.email_address, trn.order_line_number, trn.product_code,
              trn.description, trn.status, trn.qty, trn.price,
              trn.extended_price, trn.shipping_method, trn.shipped_dateline,
              trn.shipping_address1, trn.shipping_address2, trn.ship_city,
              trn.ship_state, trn.ship_zipcode, trn.promotion_code, trn.return_date,trn.return_dateline,
              trn.international_ind,trn.employee_ind,trn.cancelreason,trn.fashionfix_ind,trn.company_name, trn.fullfilllocation
              ,trn.tax_on_shipping,trn.GIFT_WRAP_FEE,trn.tracking_number ,trn.tracking_number,trn.SAKSFIRST_IND,trn.LINEPROMO_AMT,trn.line_tax );
COMMIT ;
--Call Center merge

MERGE INTO &1.bi_mnr_orders hst
   USING (
SELECT DISTINCT cc.ordernum order_number, cc.case_id case_number,
                cc.subject case_description, cc.status case_status,
                cc.modify_date last_modified,
                cc.modified_by_user_id modified_by, cc.issue
           FROM &1.call_center_case cc,
                (SELECT   MAX (case_id) case_id, ordernum
                     FROM &1.call_center_case
                 GROUP BY ordernum) sub
          WHERE sub.case_id = cc.case_id
          AND ((cc.create_date BETWEEN TRUNC (SYSDATE) - 1
                                 AND TRUNC (SYSDATE))
            OR (cc.modify_date BETWEEN TRUNC (SYSDATE) - 1
                                 AND TRUNC (SYSDATE)))
                          ) trn
   ON (hst.order_number = trn.order_number)
   WHEN MATCHED THEN
      UPDATE
         SET hst.case_number = trn.case_number,
             hst.case_description = trn.case_description,
             hst.case_status = trn.case_status,
             hst.last_modified = trn.last_modified,
             hst.modified_by = trn.modified_by,
             hst.issue = trn.issue
   WHEN NOT MATCHED THEN
      INSERT (case_number, case_description, case_status, last_modified,
              modified_by,issue)
      VALUES (trn.case_number, trn.case_description, trn.case_status,
              trn.last_modified, trn.modified_by, trn.issue);
COMMIT ;

MERGE INTO &1.bi_mnr_orders hst
   USING (SELECT DISTINCT os.orderdet linenum,
                         max(sku_size_desc) sizez,
                         max(sku_color) color
          FROM   &1.bi_sale os,
           &1.all_active_pim_sku_attr_&2 s
          WHERE  OS.PRODUCT_ID = s.upc
         AND    ((os.orderdate BETWEEN TRUNC (SYSDATE) - 1 AND TRUNC (SYSDATE))
      OR     (os.ordline_modifydate BETWEEN TRUNC (SYSDATE) - 1 AND TRUNC (SYSDATE)))
          GROUP BY os.orderdet
          ) trn
   ON (hst.linenum = trn.linenum)
   WHEN MATCHED THEN UPDATE
         SET hst.color = trn.color,
             hst.sizez = trn.sizez;
COMMIT ;

exec sddw.p_drop_INDEX_ON_MV('MV_O5_BI_MNR_ORDERS');

--Refresh MV
EXEC DBMS_MVIEW.REFRESH ('SDDW.MV_O5_BI_MNR_ORDERS','F');

--Create Indexes on MV
CREATE INDEX "SDDW"."MV_O5_MNR_LINENUM_IDX" ON "SDDW"."MV_O5_BI_MNR_ORDERS"
  (
    "LINENUM"
  );

CREATE INDEX "SDDW"."MV_O5_MNR_ORDERDATE_IDX" ON "SDDW"."MV_O5_BI_MNR_ORDERS"
  (
    "CREATED_ON"
  );

CREATE INDEX "SDDW"."MV_O5_MNR_ORDER_NUMBER_IDX" ON "SDDW"."MV_O5_BI_MNR_ORDERS"
  (
    "ORDER_NUMBER"
  );

CREATE INDEX "SDDW"."MV_O5_IDX_PRODUCT_CODE" ON "SDDW"."MV_O5_BI_MNR_ORDERS"
  (
    "PRODUCT_CODE"
  );

CREATE INDEX "SDDW"."MV_O5_IDX_RETURN_DT_LINE" ON "SDDW"."MV_O5_BI_MNR_ORDERS"
  (
    "RETURN_DATELINE"
  );

exit;

exit;
