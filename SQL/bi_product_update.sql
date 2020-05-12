SET ECHO ON
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET TIMING ON
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE

EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from RFS started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
TRUNCATE TABLE o5.excptn_logger;
-- Need to add columns given to  for oms_rfs_o5_stg
DECLARE
    CURSOR cur IS
    SELECT
         o.*,
         bp.sku bp_skn
     FROM
          (select * from o5.oms_rfs_o5_stg o  where   o.upc=o.reorder_upc_no  ) o,
          (select * from o5.bi_product where  deactive_ind = 'N')  bp
     WHERE
         lpad(
             o.skn_no,
             13,
             0
         ) = bp.sku (+)
         and o.LAST_MOD_DATE >= (select last_run_on from o5.JOB_STATUS where process_name='BI_PRODUCT_UPDT')
            ;
    TYPE v_typ IS
        TABLE OF cur%rowtype;
    v_coll     v_typ;
    v_svs      VARCHAR2(4000) := '';
    v_count    NUMBER(20) := 0;
    err_code   NUMBER(20);
    err_msg    VARCHAR2(4000);
    v_run_id NUMBER(20);
    v_err_cnt NUMBER;
   bi_product_failure EXCEPTION;
BEGIN
select o5.RUN_ID_SEQ.nextval  INTO v_run_id from dual;
    OPEN cur;
    LOOP
        FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
        BEGIN
            EXIT WHEN v_coll.count = 0;
            FOR indx IN v_coll.first..v_coll.last LOOP
                BEGIN
                    IF
                        v_coll(indx).bp_skn IS NULL AND   v_coll(indx).catalog_ind='Y'
                    THEN
           -- INSERT INTO bi_product VALUES (v_svs,v_count);
                        INSERT INTO o5.bi_product (
                            upc,
                            sku,
                            item,
                            sellable_qty,
                            backorder_qty,
                            on_hand_qty,
                            on_order_qty,
                            protected_qty,
                            reserved_qty,
                            backorder_reserved_qty,
                            sku_list_price,
                            sku_sale_price,
                            sku_description,
                            sku_size,
                            sku_color_code,
                            item_description,
                            class_id,
                            group_id,
                            division_id,
                            department_id,
                            vendor_id,
                            gift_ind,
                            restrict_order_ind,
                            add_dt,
                            sku_color,
                            sku_size2,
                            sku_size1_desc,
                            item_cst_amt,
                            ven_styl_num,
                          corp_item_retl_amt,
                            web_itm_flg,
                            product_code,
                            compare_price,
                            OFFER,
                            STOR_BK_FLG
                        ) VALUES (
                            lpad(
                                v_coll(indx).upc,
                                13,
                                0
                            ),
                            lpad(
                                v_coll(indx).skn_no,
                                13,
                                0
                            ),
                            lpad(
                              v_coll(indx).ssn,
                             13,
                              0
                           ),
                            0--SELLABLE_QTY
                            ,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,--BACKORDER_RESERVED_QTY,
                            0,--SKU_LIST_PRICE
                            0,--SKU_SALE_PRICE
                            coalesce(
                             v_coll(indx).fashion_style_desc,
                              v_coll(indx).short_description
                           ),
                            CASE
                                WHEN instr(
                                    trim(v_coll(indx).sku_size),
                                    ' '
                                ) < 1  THEN substr(
                                    trim(v_coll(indx).sku_size),
                                    1,
                                    4
                                )
                                ELSE substr(
                                    trim(substr(
                                        trim(v_coll(indx).sku_size),
                                        1,
                                        instr(
                                            trim(v_coll(indx).sku_size),
                                            ' '
                                        ) - 1
                                    ) ),
                                    1,
                                    4
                                )
                            END,
                            lpad(
                                v_coll(indx).color_code,
                                3,
                                0
                            ),
                            v_coll(indx).short_description,
                            lpad(v_coll(indx).class_id,3,'0'),
                            substr(v_coll(indx).group_id,-2),-- GROUP_ID
                            substr(v_coll(indx).group_id,1,1),-- DIVISION_ID
                            lpad(v_coll(indx).department_id,3,'0'),--DEPARTMENT_ID
                            v_coll(indx).vendor_id,--VENDOR_ID
                            0,
                            0,
                            SYSDATE,--ADD_DT
                            v_coll(indx).sku_color,
                            trim(substr(
                                CASE
                                    WHEN instr(
                                        trim(v_coll(indx).sku_size),
                                        ' '
                                    ) > 0  THEN substr(
                                        trim(substr(
                                            trim(v_coll(indx).sku_size),
                                            instr(
                                                trim(v_coll(indx).sku_size),
                                                ' '
                                            ) + 1,
                                            length(trim(v_coll(indx).sku_size) ) - instr(
                                                v_coll(indx).sku_size,
                                                ' '
                                            )
                                        ) ),
                                        1,
                                        4
                                    )
                                    ELSE NULL
                                END,
                                1,
                                3
                            ) ),
                            trim(v_coll(indx).sku_size),
                            v_coll(indx).item_cst_amt,
                            v_coll(indx).vendor_style_20ch,
                             v_coll(indx).cur_own_retail_dol,
                            'Y',--WEB_ITM_FLG
                            trim(v_coll(indx).product_code),
                            v_coll(indx).compare_at_amt_dol,
                              case
                                 when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='Y') then 'BTH'
                                 when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='N' ) then 'WWW'
                                 when (v_coll(indx).ECOM_CAT_IND='Y' and v_coll(indx).CATALOG_IND = 'N' ) then 'STB'
                              end,
                            v_coll(indx).ECOM_CAT_IND
     );
                    ELSIF
                       v_coll(indx).bp_skn  IS  NOT NULL and v_coll(indx).catalog_ind='Y'
             THEN
                        UPDATE o5.bi_product
                            SET
                                upc = lpad(
                                    v_coll(indx).upc,
                                    13,
                                    0
                                ),
                               item = lpad(
                                  v_coll(indx).ssn,
                                13,
                                 0
                              ),
                                sellable_qty = 0,--SELLABLE_QTY
                                backorder_qty = 0,--BACKORDER_RESERVED_QTY,
                                on_hand_qty = 0,
                                on_order_qty = 0,
                                protected_qty = 0,
                                reserved_qty = 0,
                                backorder_reserved_qty = 0,
                                sku_list_price = 0,--SKU_LIST_PRICE
                                sku_sale_price = 0,--SKU_SALE_PRICE
                             sku_description = coalesce(
                                  v_coll(indx).fashion_style_desc,
                                 v_coll(indx).short_description
                              ),
                                sku_size =
                                    CASE
                                        WHEN instr(
                                            trim(v_coll(indx).sku_size),
                                            ' '
                                        ) < 1  THEN substr(
                                            trim(v_coll(indx).sku_size),
                                            1,
                                            4
                                        )
                                        ELSE substr(
                                            trim(substr(
                                                trim(v_coll(indx).sku_size),
                                                1,
                                                instr(
                                                    trim(v_coll(indx).sku_size),
                                                    ' '
                                                ) - 1
                                            ) ),
                                            1,
                                            4
                                        )
                                    END,
                                sku_color_code = lpad(
                                    v_coll(indx).color_code,
                                    3,
                                    0
                                ),
                                item_description = v_coll(indx).short_description,
                                class_id = v_coll(indx).class_id,
                                group_id = substr(v_coll(indx).group_id,-2),-- GROUP_ID
                                division_id = substr(v_coll(indx).group_id,1,1),-- DIVISION_ID
                                department_id = v_coll(indx).department_id,--DEPARTMENT_ID
                                vendor_id = v_coll(indx).vendor_id,--VENDOR_ID
                                gift_ind = 0,
                                restrict_order_ind = 0,
                                modify_dt = SYSDATE,--ADD_DT
                                sku_color = v_coll(indx).sku_color,
                                sku_size2 = trim(substr(
                                    CASE
                                        WHEN instr(
                                            trim(v_coll(indx).sku_size),
                                            ' '
                                        ) > 0  THEN substr(
                                            trim(substr(
                                                trim(v_coll(indx).sku_size),
                                                instr(
                                                    trim(v_coll(indx).sku_size),
                                                    ' '
                                                ) + 1,
                                                length(trim(v_coll(indx).sku_size) ) - instr(
                                                    v_coll(indx).sku_size,
                                                    ' '
                                                )
                                            ) ),
                                            1,
                                            4
                                        )
                                        ELSE NULL
                                    END,
                                    1,
                                    3
                                ) ),
                                sku_size1_desc = trim(v_coll(indx).sku_size),
                                ven_styl_num = v_coll(indx).vendor_style_20ch,
                                item_cst_amt = v_coll(indx).item_cst_amt,
                               corp_item_retl_amt = v_coll(indx).cur_own_retail_dol,
                                web_itm_flg = 'Y',--WEB_ITM_FLG
                                product_code = trim(v_coll(indx).product_code),
                                compare_price = v_coll(indx).compare_at_amt_dol,
                                offer = case
                                        when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='Y') then 'BTH'
                                        when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='N' ) then 'WWW'
                                        when (v_coll(indx).ECOM_CAT_IND='Y' and v_coll(indx).CATALOG_IND = 'N' ) then 'STB'
                                        end ,
                                STOR_BK_FLG = v_coll(indx).ECOM_CAT_IND
                        WHERE
                            sku = lpad(
                                v_coll(indx).skn_no,
                                13,
                                0
                            ) and DEACTIVE_IND = 'N';
              ELSE
              update o5.bi_product
                 set  DEACTIVE_IND = 'Y'
                  WHERE
                            sku = lpad(
                                v_coll(indx).skn_no,
                                13,
                                0
                            );
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                         err_code := SQLCODE;
                        err_msg := SUBSTR(SQLERRM, 1 , 4000);
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_UPDT',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).skn_no ,sysdate,v_run_id);
                        COMMIT;
                END;
            END LOOP;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_code := sqlcode;
                err_msg := substr(
                    sqlerrm,
                    1,
                    4000
                );
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_UPDT',err_msg||err_msg,'excptn_logger','','',sysdate,v_run_id );
                COMMIT;
        END;
  END LOOP ;
CLOSE cur;
select count(*) into v_err_cnt from o5.excptn_logger where run_id=v_run_id;
IF v_err_cnt>0
THEN RAISE bi_product_failure;
END IF;
EXCEPTION
   WHEN bi_product_failure THEN
      dbms_output.put_line(v_err_cnt||' records update in BI product failed check excptn_logger with run_id: '||v_run_id);
     RAISE;
  WHEN OTHERS THEN
dbms_output.put_line('Error in Bi product process. Please check.');
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from RFS ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from PRD PIM ATTRIBUTE started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
--- Product prd atrribute update :
DECLARE
    CURSOR cur IS
       SELECT
    product_id product_code,
    selloff,
    brand_name,
    dropship_ind,
    alternate,
    back_orderable,
    colorization_ind,
    gwp_flag,
    is_shopthelook,
    item_gender,
    item_risk,
    pd_restrictedshiptype_text,
    pd_restrictedstate_text,
    pd_restrictedwarning_text,
    sizechartsubtype,
    sizecharttemplate,
    purchase_restriction,
    sl_entity,
    sl_web_ok,
    zoom,
    prd_status,
    prd_readyforprod
FROM
    o5.all_active_pim_prd_attr_o5
    where  (trunc(PIM_ADD_DT) >= trunc(sysdate-7) or  trunc(PIM_MODIFY_DT) >= trunc(sysdate-7) or trunc(PIM_ADD_DT)  >= trunc(sysdate-7)  );
  TYPE v_typ IS
        TABLE OF cur%rowtype;
    v_coll     v_typ;
    v_svs      VARCHAR2(4000) := '';
    v_count    NUMBER(20) := 0;
    err_code   NUMBER(20);
    err_msg    VARCHAR2(4000);
    v_run_id NUMBER(20);
    v_err_cnt NUMBER;
   bi_product_failure EXCEPTION;
BEGIN

select o5.RUN_ID_SEQ.nextval  INTO v_run_id from dual;
    OPEN cur;
    LOOP
        FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
        BEGIN
            EXIT WHEN v_coll.count = 0;
            FOR indx IN v_coll.first..v_coll.last LOOP
                BEGIN

                        UPDATE o5.bi_product
                            SET
                              selloff_ind =  v_coll(indx).SellOff,
                                brand_name = v_coll(indx).brand_name,
                                DROPSHIP_IND = v_coll(indx).Dropship_Ind,
              ALT_IND = v_coll(indx).Alternate,
              BORDABLE_IND = v_coll(indx).BACK_ORDERABLE,
              COLORZ_IND = v_coll(indx).Colorization_Ind,
           --   GWP_ELIG_IND = v_coll(indx).GWP_ELIG_IND,
              GWP_FLAG_IND = v_coll(indx).GWP_FLAG,
              STL_IND = v_coll(indx).IS_SHOPTHELOOK,
              ITM_GENDER = v_coll(indx).ITEM_GENDER,
              ITM_RISK_IND = v_coll(indx).Item_Risk,
              RST_SHIPTYPE = v_coll(indx).PD_RestrictedShipType_Text,
              RST_STATE = v_coll(indx).PD_RestrictedState_Text,
              RST_WARNG = v_coll(indx).PD_RestrictedWarning_Text,
              PURCH_RST = v_coll(indx).Purchase_Restriction,
              SC_SUBTYPE = v_coll(indx).SizeChartSubType,
              SC_TEMPLATE = v_coll(indx).SizeChartTemplate,
             SL_ENTITY = v_coll(indx).SL_entity,
              SL_WEBOK_IND = v_coll(indx).SL_web_ok,
              SL_ZOOM_IND = v_coll(indx).zoom,
              modify_dt = trunc(sysdate),
              item_active_ind = case when v_coll(indx).prd_status = 'Yes' then 'A'
                                else 'I'
                                end,
                readyforprod =  v_coll(indx).PRD_READYFORPROD
          where product_code =  v_coll(indx).product_code;
              commit;
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   NULL;
                    WHEN OTHERS THEN
                         err_code := SQLCODE;
                        err_msg := SUBSTR(SQLERRM, 1 , 4000);
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_PRD_ATTR_UPDT',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).product_code ,sysdate,v_run_id);
                        COMMIT;
                END;
            END LOOP;
        COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_code := sqlcode;
                err_msg := substr(
                    sqlerrm,
                    1,
                    4000
                );
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_PRD_ATTR_UPDT',err_msg||err_msg,'excptn_logger','','' ,sysdate,v_run_id );
                COMMIT;
        END;
    END LOOP ;
   CLOSE cur;
select count(*) into v_err_cnt from o5.excptn_logger where run_id=v_run_id;
IF v_err_cnt>0
THEN RAISE bi_product_failure;
END IF;
EXCEPTION
   WHEN bi_product_failure THEN
      dbms_output.put_line(v_err_cnt||' records update in BI product failed check excptn_logger with run_id: '||v_run_id);
     RAISE;
  WHEN OTHERS THEN
dbms_output.put_line('Error in Bi product process. Please check.');
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from PIM PRD TABLE ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from PIM SKU TABLE started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
exec dbms_stats.gather_table_stats('o5','bi_product',force => true);
---Product Sku attribute UPDATE

DECLARE
    CURSOR cur IS
       select upc,
SKU_STATUS,
SKU_COLOR,
SKU_SIZE_DESC,
PRD_ACTIVE,
PARENT_category,
SIZE2_DESCRIPTION,
primary_parent_color,
pickUpAllowedInd,
to_char(to_date(webEndDate,'MM/DD/YYYY'),'DD-MON-YYYY') webEndDate,
to_char(to_date(webStartDate,'MM/DD/YYYY'),'DD-MON-YYYY') webStartDate,
ComplexSwatch from o5.all_active_pim_sku_attr_o5
where  (trunc(PIM_ADD_DT) >= trunc(sysdate-7) or  trunc(PIM_MODIFY_DT) >= trunc(sysdate-7) or trunc(PIM_ADD_DT)  >= trunc(sysdate-7)  );
TYPE v_typ IS
        TABLE OF cur%rowtype;
    v_coll     v_typ;
    v_svs      VARCHAR2(4000) := '';
    v_count    NUMBER(20) := 0;
    err_code   NUMBER(20);
    err_msg    VARCHAR2(4000);
    v_run_id NUMBER(20);
    v_err_cnt NUMBER;
   bi_product_failure EXCEPTION;
BEGIN

select o5.RUN_ID_SEQ.nextval  INTO v_run_id from dual;
    OPEN cur;
    LOOP
        FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
        BEGIN
            EXIT WHEN v_coll.count = 0;
            FOR indx IN v_coll.first..v_coll.last LOOP
                BEGIN

                        UPDATE o5.bi_product
                            SET
                                ACTIVE_IND =
                                case when v_coll(indx).SKU_STATUS = 'Yes' then 'A'
                                                  else 'I'
                                                  end
                                                  ,
                                pickUpAllowedInd= v_coll(indx).pickUpAllowedInd,
                                web_itm_end_dt = v_coll(indx).webEndDate ,
                                  web_itm_strt_dt = v_coll(indx).webStartDate,
                                 MODIFY_DT = trunc(SYSDATE)
          where upc =  v_coll(indx).upc;
              commit;
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   NULL;
                    WHEN OTHERS THEN
                         err_code := SQLCODE;
                        err_msg := SUBSTR(SQLERRM, 1 , 4000);
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_SKU_ATTR_UPDT',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).upc,sysdate,v_run_id);

                        COMMIT;
                END;
            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_code := sqlcode;
                err_msg := substr(
                    sqlerrm,
                    1,
                    4000
                );
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_SKU_ATTR_UPDT',err_msg||err_msg,'excptn_logger','','' ,sysdate,v_run_id );

                COMMIT;
        END;

    END LOOP ;

    CLOSE cur;
select count(*) into v_err_cnt from o5.excptn_logger where run_id=v_run_id;

IF v_err_cnt>0
THEN RAISE bi_product_failure;
END IF;

EXCEPTION
   WHEN bi_product_failure THEN
      dbms_output.put_line(v_err_cnt||' records update in BI product failed check excptn_logger with run_id: '||v_run_id);
     RAISE;
  WHEN OTHERS THEN
dbms_output.put_line('Error in Bi product process. Please check.');

END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update from PIM SKU TABLE ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for Inventory started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));

DECLARE
    CURSOR cur IS
       select p.sku,i.in_stock_sellable_qty  from o5.bi_product p
       left join o5.inventory i on  lpad(i.skn_no,13,'0') = p.sku
       where  ( nvl(i.in_stock_sellable_qty,'0') <> p.wh_sellable_qty );

    TYPE v_typ IS
        TABLE OF cur%rowtype;
    v_coll     v_typ;
    v_svs      VARCHAR2(4000) := '';
    v_count    NUMBER(20) := 0;
    err_code   NUMBER(20);
    err_msg    VARCHAR2(4000);
    v_run_id NUMBER(20);
    v_err_cnt NUMBER;
   bi_product_failure EXCEPTION;
BEGIN

    OPEN cur;
    LOOP
        FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
        BEGIN
            EXIT WHEN v_coll.count = 0;
            FOR indx IN v_coll.first..v_coll.last LOOP
                BEGIN

                        UPDATE o5.bi_product
                            SET
                                wh_sellable_qty = v_coll(indx).in_stock_sellable_qty
              where sku =  v_coll(indx).sku;
              commit;
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   NULL;
                    WHEN OTHERS THEN
                         err_code := SQLCODE;
                        err_msg := SUBSTR(SQLERRM, 1 , 4000);
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BI_PRODUCT_INV_UPDT',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).sku,sysdate,'');

                        COMMIT;
                END;
            END LOOP;

            COMMIT;

        END;

    END LOOP ;

    CLOSE cur;
 END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for Inventory ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
exec dbms_stats.gather_table_stats('o5','bi_product',force => true);
exec dbms_stats.gather_table_stats('edata_exchange','o5_price',force => true);
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for Price started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
--- price status update
DECLARE
   CURSOR cur IS
   select o.skn_no skn_no,PRICE_FLAG,MSRP ,Offer_price  from
       (select  lpad(o.skn_no,13,'0') skn_no,
      to_number(greatest(nvl(to_number(COMPARE_AT_AMT_DOL),0), nvl(to_number(original_ticket),0) ))  MSRP,
      to_number(Offer_price) Offer_price,
      CASE WHEN trim(AMS_PRICE_TYPE_CD) = '0' THEN 'R'
                    WHEN trim(AMS_PRICE_TYPE_CD) = '1' THEN 'M'
                    WHEN trim(AMS_PRICE_TYPE_CD) = '2' THEN 'C'
                    WHEN trim(AMS_PRICE_TYPE_CD) = '3' THEN 'F'
                    END  as PRICE_FLAG
                       from   edata_exchange.o5_price o ) o,
                       (select sku,to_number(sku_sale_price) sku_sale_price,to_number(sku_list_price) sku_list_price,PRICE_status  from o5.bi_product )p
     where o.skn_no = p.sku
          and (o.Offer_price <> sku_sale_price or o.MSRP <> sku_list_price);
   TYPE v_typ IS
       TABLE OF cur%rowtype;
   v_coll     v_typ;
   v_svs      VARCHAR2(4000) := '';
   v_count    NUMBER(20) := 0;
   err_code   NUMBER(20);
   err_msg    VARCHAR2(4000);
   v_run_id NUMBER(20);
   v_err_cnt NUMBER;
  bi_product_failure EXCEPTION;
BEGIN

   OPEN cur;
   LOOP
       FETCH cur BULK COLLECT INTO v_coll LIMIT 300000;
           EXIT WHEN v_coll.count = 0;
           FOR indx IN v_coll.first..v_coll.last LOOP
               BEGIN

                       UPDATE o5.bi_product
                           SET
                            PRICE_status =v_coll(indx).PRICE_FLAG,
                               sku_list_price = v_coll(indx).MSRP,
                               sku_sale_price= v_coll(indx).Offer_price
             where sku =  v_coll(indx).skn_no;
             commit;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                  NULL;
                   WHEN OTHERS THEN
                        err_code := SQLCODE;
                       err_msg := SUBSTR(SQLERRM, 1 , 4000);
                       INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_IPRICE+_UPDATE',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).skn_no,sysdate,'');

                       COMMIT;
               END;
           END LOOP;
 END LOOP ;

   CLOSE cur;
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for Price ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
--If upc is not present in RFS then make it deactive= 'Y' and default deactive = 'N'
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for deactive_ind started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
declare
begin
for r1 in
(
select a.prd_upc from
(select  to_number(upc) upc,upc prd_upc, product_code from o5.bi_product trg
where trunc(add_dt)<> trunc(sysdate) and deactive_ind= 'N'
) a
left join (select  upc from o5.OMS_RFS_o5_STG
  where upc=reorder_upc_no
  ) b
  on trim(a.upc) = trim(b.upc)
  where b.upc is null )
  loop
  update o5.bi_product set deactive_ind = 'Y' where  upc = r1.prd_upc ;
  commit;
end loop;
end;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for deactive_ind ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for SEO URL started at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
--seo url changes for PDP url
declare
BEGIN
  FOR r1 IN
  (
  with prd_product as
  (select DISTINCT
      product_code,
      product_url from o5.bi_product)
  select  p.product_code,'https://www.saksoff5th.com'||seo_url product_url
  from o5.product_seo_url_mapping p
  ,prd_product prd
  where p.product_code = prd.product_code
  and  trim(nvl(prd.product_url,'x')) <> 'https://www.saksoff5th.com' || trim(p.seo_url)
  )
  LOOP
    UPDATE o5.bi_product
    SET product_url = r1.product_url
    WHERE product_code      = r1.product_code;
    COMMIT;
  END LOOP;
END;
/
EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update for SEO URL ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
--Move to Active Status if a Product is active IN RFS.
UPDATE o5.bi_product t1
   SET deactive_ind = 'N'
 WHERE deactive_ind = 'Y'
   AND EXISTS (SELECT 1
		FROM o5.oms_rfs_o5_stg t2
	       WHERE  lpad(t2.skn_no,13,'0') = t1.sku
           and  lpad(t2.upc,13,'0') = t1.upc
		 AND t2.catalog_ind = 'Y'
		 AND t2.upc = t2.reorder_upc_no);
COMMIT;

UPDATE   o5.JOB_STATUS set last_run_on =LAST_COMPLETED_TIME,  LAST_COMPLETED_TIME= sysdate where process_name='BI_PRODUCT_UPDT';

EXEC DBMS_OUTPUT.PUT_LINE ('BI_PRODUCT Update ended at '|| to_char(sysdate , 'MM/DD/YYYY HH:MI:SS AM'));
show errors;

exit
