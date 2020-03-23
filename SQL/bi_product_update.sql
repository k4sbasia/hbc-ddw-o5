set timing on
set echo on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set timing on

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Need to add columns given to Ishav for oms_rfs_o5_stg


EXEC dbms_output.put_line ('MERGE 1 BI_PRODUCT Started');


DECLARE
    CURSOR cur IS
        SELECT
            o.*,
            bp.sku bp_skn
        FROM
             (select * from oms_rfs_o5_stg o  where   o.upc=o.reorder_upc_no  ) o,
            o5.tmp_tst bp
        WHERE
            lpad(
                o.skn_no,
                13,
                0
            ) = bp.sku (+)
            and o.LAST_MOD_DATE >= (select last_run_on from JOB_STATUS where process_name='O5_ITEM_SETUP')
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

select RUN_ID_SEQ.nextval  INTO v_run_id from dual;
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
           -- INSERT INTO tmp_tst VALUES (v_svs,v_count);
                        INSERT INTO tmp_tst (
                            upc,
                            sku,
                         --commented   item,
                            sellable_qty,
                            backorder_qty,
                            on_hand_qty,
                            on_order_qty,
                            protected_qty,
                            reserved_qty,
                            backorder_reserved_qty,
                            sku_list_price,
                            sku_sale_price,
                          --  sku_description,
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
                           -- corp_item_retl_amt,
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
                          --  lpad(
                            --    v_coll(indx).ssn,
                              --  13,
                               -- 0
                            --),
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
                         --   coalesce(
                        --        v_coll(indx).fashion_style_desc,
                        --        v_coll(indx).short_description
                         --   ),
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
                          --commted  v_coll(indx).cur_own_retail_dol,
                            'Y',--WEB_ITM_FLG
                            trim(v_coll(indx).product_code),
                            v_coll(indx).compare_at_amt_dol,
                              case
                                 when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='Y') then 'BTH'
                                 when (v_coll(indx).CATALOG_IND = 'Y' and v_coll(indx).ECOM_CAT_IND='N' ) then 'WWW'
                                 when (v_coll(indx).ECOM_CAT_IND='Y' and v_coll(indx).CATALOG_IND = 'N' ) then 'STB'
                              end,
                            v_coll(indx).ECOM_CAT_IND
             OFFER,
                        );

                    ELSIF
                       v_coll(indx).bp_skn  IS  NOT NULL and v_coll(indx).catalog_ind='Y'

					 THEN
                        UPDATE o5.tmp_tst
                            SET
                                upc = lpad(
                                    v_coll(indx).upc,
                                    13,
                                    0
                                ),
                             --   item = lpad(
                              --      v_coll(indx).ssn,
                               --     13,
                               --     0
                              --  ),
                                sellable_qty = 0,--SELLABLE_QTY
                                backorder_qty = 0,--BACKORDER_RESERVED_QTY,
                                on_hand_qty = 0,
                                on_order_qty = 0,
                                protected_qty = 0,
                                reserved_qty = 0,
                                backorder_reserved_qty = 0,
                                sku_list_price = 0,--SKU_LIST_PRICE
                                sku_sale_price = 0,--SKU_SALE_PRICE
                              --  sku_description = coalesce(
                               --     v_coll(indx).fashion_style_desc,
                               --     v_coll(indx).short_descriptionxa
                               -- ),
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
                               -- corp_item_retl_amt = v_coll(indx).cur_own_retail_dol,
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
                            );
              ELSE
              update o5.tmp_tst
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
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BAY_ITEM_SETUP',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).skn_no ,sysdate,v_run_id);

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
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'BAY_ITEM_SETUP',err_msg||err_msg,'excptn_logger','','',sysdate,v_run_id );

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


--- Product prd atrribute update :
DECLARE
    CURSOR cur IS
        select product_id product_code,
                           SellOff,
                           BRAND_NAME,
                           Dropship_Ind,
                           Alternate,
                           BACK_ORDERABLE,
                           Colorization_Ind,
                           GWP_FLAG,
                           IS_SHOPTHELOOK,
                           ITEM_GENDER,
                           Item_Risk,
                           PD_RestrictedShipType_Text,
PD_RestrictedState_Text,
PD_RestrictedWarning_Text,
SizeChartSubType,
SizeChartTemplate,
purchase_restriction,
SL_entity,
SL_web_ok,
zoom,
PRD_STATUS,
PRD_READYFORPROD
from o5.all_active_pim_prd_attr_o5
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

select RUN_ID_SEQ.nextval  INTO v_run_id from dual;
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
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_PRD_ATTR_UPDATE',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).product_code ,sysdate,v_run_id);

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
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_PRD_ATTR_UPDATE',err_msg||err_msg,'excptn_logger','','' ,sysdate,v_run_id );

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
webEndDate,
webStartDate,
ComplexSwatch from o5.all_active_pim_sku_attr_o5
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

select RUN_ID_SEQ.nextval  INTO v_run_id from dual;
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
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_SKU_ATTR_UPDATE',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).upc,sysdate,v_run_id);

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
                INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_SKU_ATTR_UPDATE',err_msg||err_msg,'excptn_logger','','' ,sysdate,v_run_id );

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


EXEC dbms_output.put_line ('inventoy update started');

DECLARE
    CURSOR cur IS
       select p.sku,i.in_stock_sellable_qty  from o5.inventory i, o5.bi_product p
       where lpad(i.skn_no,13,'0') = p.sku
       and (i.in_stock_sellable_qty <> p.wh_sellable_qty);

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
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_INV_UPDATE',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).sku,sysdate,'');

                        COMMIT;
                END;
            END LOOP;

            COMMIT;

        END;

    END LOOP ;

    CLOSE cur;
 END;
/

EXEC dbms_output.put_line ('Bi_Product : inventoy update completed');

EXEC dbms_output.put_line ('Bi_Product : Price Update started');


commit ;

--- price status update
DECLARE
    CURSOR cur IS
       select  lpad(o.skn_no,13,'0') skn_no,PRICE_FLAG,MSRP ,Offer_price  from
      o5.V_SD_PRICE_O5 o, o5.bi_product p
      where lpad(o.skn_no,13,'0') = p.sku and
      (o.msrp <> p.sku_list_price
      or o.offer_price <> p.sku_sale_price );


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
                        INSERT INTO o5.excptn_logger(PROCESS_NM,EXCPTN,TABLE_NM,COLUMN_NM,KEY_ID,add_dt,RUN_ID) VALUES ( 'O5_INV_UPDATE',err_code||err_msg,'BI_PRODUCT','',v_coll(indx).skn_no,sysdate,'');

                        COMMIT;
                END;
            END LOOP;
  END LOOP ;

    CLOSE cur;
 END;
 /
;


--If upc is not present in RFS then make it deactive= 'Y' and default deactive = 'N'
declare
begin
for r1 in
(
select a.prd_upc from
(select  to_number(upc) upc,upc prd_upc, product_code from bay_ds.bi_product trg
where trunc(add_dt)<> trunc(sysdate) and deactive_ind= 'N'
) a
left join (select  upc from bay_ds.OMS_RFS_BAY_STG
  ) b
  on trim(a.upc) = trim(b.upc)
  where b.upc is null )
  loop
  update bay_ds.bi_product set deactive_ind = 'Y' where  upc = r1.prd_upc ;
  commit;
end loop;
end;
/

--Move to Active Status if a Product is active IN RFS.
UPDATE bay_ds.bi_product t1
   SET deactive_ind = 'N'
 WHERE deactive_ind = 'Y'
   AND EXISTS (SELECT 1
		FROM bay_ds.oms_rfs_bay_stg t2
	       WHERE t2.upc = t1.upc
		 AND t2.catalog_ind = 'Y'
		 AND t2.upc = t2.reorder_upc_no);
COMMIT;

UPDATE   JOB_STATUS set last_run_on =LAST_COMPLETED_TIME,  LAST_COMPLETED_TIME= sysdate where process_name='o5a_ITEM_SETUP';


show errors;

exit
