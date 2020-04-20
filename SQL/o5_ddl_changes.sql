----O5----

CREATE TABLE "O5"."RFS_UDA_DATA"
 (	"SKN_NO" NUMBER(8,0) NOT NULL ENABLE,
"UDA_ID" NUMBER(5,0) NOT NULL ENABLE,
"LAST_MOD_DATE" DATE,
"UDA_VALUE" NUMBER(3,0) NOT NULL ENABLE,
"UDA_VALUE_DESC" VARCHAR2(250 BYTE) NOT NULL ENABLE,
"VALUE_LAST_MOD_DATE" DATE
 );


CREATE SEQUENCE INV_BATCH_SEQ MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1;


  CREATE TABLE "O5"."INVENTORY"
   (	"SKN_NO" NUMBER(20,0) NOT NULL ENABLE,
	"IN_STOCK_SELLABLE_QTY" NUMBER(10,0) NOT NULL ENABLE,
	"IN_STOCK_UPDATE_DATE" DATE,
	"ADD_DT" DATE,
	"IN_STORE_QTY" NUMBER(18,0),
	"WH_PO_DATE" DATE,
	"WH_PO_NUMBER" NUMBER(38,0)
   ) ;

ALTER TABLE INVENTORY ADD (IN_STORE_UPDATE_DATE DATE);

CREATE INDEX "O5"."IDX_INVENTORY_1" ON "O5"."INVENTORY" ("SKN_NO") ;


  CREATE TABLE "O5"."INVENTORY_V1"
   (	"ITEMID" VARCHAR2(20 BYTE),
	"ALLOCATION" VARCHAR2(100 BYTE),
	"ONHAND" NUMBER,
	"ALLOCATIONTIMESTAMP" VARCHAR2(50 BYTE),
	"BACKORDER" VARCHAR2(10 BYTE),
	"DUMMY" VARCHAR2(10 BYTE),
	"INSTOCKDATE" VARCHAR2(50 BYTE),
	"PERPETUAL" VARCHAR2(10 BYTE),
	"PREORDER" VARCHAR2(10 BYTE),
	"PROCESSED" VARCHAR2(1 BYTE) DEFAULT 'N',
	"BATCH_ID" NUMBER(18,0),
	"ADD_DT" DATE DEFAULT SYSDATE
   )
PARTITION BY RANGE ("ADD_DT") INTERVAL (NUMTODSINTERVAL(1, 'DAY'))
 (PARTITION "INV_V1_P0"  VALUES LESS THAN (TO_DATE(' 2018-08-26 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'));



CREATE INDEX "O5"."IDX_INVENTORY_V1" ON "O5"."INVENTORY_V1" ("ITEMID") ;

CREATE INDEX "O5"."IDX_INV_PRCSD" ON "O5"."INVENTORY_V1" (trunc("ADD_DT"),"PROCESSED") LOCAL ;


  CREATE TABLE "O5"."TECH_EXCPTN"
   (	"PROCESS_NM" VARCHAR2(100 BYTE),
	"KEY_ID" VARCHAR2(500 BYTE),
	"ERROR_CD" VARCHAR2(500 BYTE),
	"ERR_MSG" VARCHAR2(4000 BYTE),
	"EXCPT_DT" DATE,
	"BATCH_ID" NUMBER(18,0)
   );


CREATE INDEX "O5"."IDX_T_EXCPT" ON "O5"."TECH_EXCPTN" ("BATCH_ID") ;

  CREATE TABLE "O5"."INVENTORY_STORES"
   (	"SKN_NO" NUMBER(20,0) NOT NULL ENABLE,
     STORE_ID NUMBER(18,0),
	"ADD_DT" DATE,
	"IN_STORE_QTY" NUMBER(18,0),
    "IN_STORE_UPDATE_DATE" DATE,
	"BATCH_ID" NUMBER(18,0),
	"MERGE_BATCH_ID" NUMBER(18,0)
   );


create index idx_inv_store_item on INVENTORY_STORES (STORE_ID,SKN_NO);

create index idx_inv_store_skn on INVENTORY_STORES (SKN_NO);

  CREATE TABLE "O5"."EDB_STAGE_SFCC_EMAIL_OPT_DATA"
     (	"SOURCE_ID" NUMBER,
  	"EMAIL_ADDRESS" VARCHAR2(250 BYTE),
  	"FIRST_NAME" VARCHAR2(250 BYTE),
  	"MIDDLE_NAME" VARCHAR2(250 BYTE),
  	"LAST_NAME" VARCHAR2(250 BYTE),
  	"ADDRESS" VARCHAR2(500 BYTE),
  	"ADDRESS_TWO" VARCHAR2(500 BYTE),
  	"CITY" VARCHAR2(50 BYTE),
  	"STATE" VARCHAR2(20 BYTE),
  	"ZIP_FULL" VARCHAR2(25 BYTE),
  	"COUNTRY" VARCHAR2(25 BYTE),
  	"PHONE" VARCHAR2(25 BYTE),
  	"OFF5TH_OPT_STATUS" CHAR(1 BYTE),
  	"SAKS_OPT_STATUS" CHAR(1 BYTE),
  	"SAKS_CANADA_OPT_STATUS" CHAR(1 BYTE),
  	"OFF5TH_CANADA_OPT_STATUS" CHAR(1 BYTE),
  	"THE_BAY_OPT_STATUS" CHAR(1 BYTE),
  	"LANGUAGE" VARCHAR2(10 BYTE),
  	"BANNER" VARCHAR2(20 BYTE),
  	"CANADA_FLAG" CHAR(1 BYTE),
  	"SAKS_FAMILY_OPT_STATUS" CHAR(1 BYTE),
  	"MORE_NUMBER" VARCHAR2(50 BYTE),
  	"HBC_REWARDS_NUMBER" VARCHAR2(50 BYTE),
  	"BIRTHDAY" VARCHAR2(20 BYTE),
  	"GENDER" VARCHAR2(10 BYTE),
  	"SUB_UNSUB_DATE" DATE
     );


     GRANT ALL ON o5.edb_stage_sfcc_email_opt_data TO DM_USER;

     CREATE TABLE "O5"."FILE_PROCESS_STATUS"
 (	"PROCESS_NAME" VARCHAR2(20 BYTE),
"FILE_NAME" VARCHAR2(4000 BYTE),
"ADD_DT" DATE DEFAULT SYSDATE,
"PRRCSD" VARCHAR2(1 BYTE) DEFAULT 'N'
) ;

CREATE INDEX "O5"."IDX_FILR_PRCS_NM" ON "O5"."FILE_PROCESS_STATUS" ("PROCESS_NAME", "FILE_NAME") ;

GRANT ALL ON o5.FILE_PROCESS_STATUS to DM_USER;  



  CREATE TABLE "O5"."EDB_SFCC_EMAIL_OPT_DATA_HIST" 
   (	"SOURCE_ID" NUMBER, 
	"EMAIL_ADDRESS" VARCHAR2(250 BYTE), 
	"FIRST_NAME" VARCHAR2(250 BYTE), 
	"MIDDLE_NAME" VARCHAR2(250 BYTE), 
	"LAST_NAME" VARCHAR2(250 BYTE), 
	"ADDRESS" VARCHAR2(500 BYTE), 
	"ADDRESS_TWO" VARCHAR2(500 BYTE), 
	"CITY" VARCHAR2(50 BYTE), 
	"STATE" VARCHAR2(20 BYTE), 
	"ZIP_FULL" VARCHAR2(25 BYTE), 
	"COUNTRY" VARCHAR2(25 BYTE), 
	"PHONE" VARCHAR2(25 BYTE), 
	"OFF5TH_OPT_STATUS" CHAR(1 BYTE), 
	"SAKS_OPT_STATUS" CHAR(1 BYTE), 
	"SAKS_CANADA_OPT_STATUS" CHAR(1 BYTE), 
	"OFF5TH_CANADA_OPT_STATUS" CHAR(1 BYTE), 
	"THE_BAY_OPT_STATUS" CHAR(1 BYTE), 
	"LANGUAGE" VARCHAR2(10 BYTE), 
	"BANNER" VARCHAR2(20 BYTE), 
	"CANADA_FLAG" CHAR(1 BYTE), 
	"SAKS_FAMILY_OPT_STATUS" CHAR(1 BYTE), 
	"MORE_NUMBER" VARCHAR2(50 BYTE), 
	"HBC_REWARDS_NUMBER" VARCHAR2(50 BYTE), 
	"BIRTHDAY" VARCHAR2(20 BYTE), 
	"GENDER" VARCHAR2(10 BYTE), 
	"ADD_DT" DATE DEFAULT sysdate, 
	"SUB_UNSUB_DATE" DATE
   );


GRANT ALL ON o5.EDB_SFCC_EMAIL_OPT_DATA_HIST TO DM_USER;


  CREATE TABLE "O5"."T_GDPR_REGION" 
   (	"COUNTRY" VARCHAR2(200 BYTE), 
	"COUNTRY_CODE" VARCHAR2(20 BYTE), 
	"GDPR_REGION" VARCHAR2(200 BYTE), 
	"ADDED_DT" DATE
   );
   
   
SET DEFINE OFF;
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Austria','AT','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Belgium','BE','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Bulgaria','BG','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Croatia','HR','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Cyprus','CY','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Czech Republic','CZ','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Denmark','DK','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Estonia','EE','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Finland','FI','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('France','FR','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Germany','DE','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Greece','GR','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Hungary','HU','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Iceland','IS','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Ireland','IE','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Italy','IT','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Latvia','LV','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Liechtenstein','LI','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Lithuania','LT','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Luxembourg','LU','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Malta','MT','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Netherlands','NL','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Norway','NO','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Poland','PL','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Portugal','PT','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Romania','RO','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Slovakia','SK','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Slovenia','SI','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Spain','ES','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Sweden','SE','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('Switzerland','CH','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));
Insert into T_GDPR_REGION (COUNTRY,COUNTRY_CODE,GDPR_REGION,ADDED_DT) values ('United Kingdom','GB','Y',to_date('07-MAY-2018 14:27:36','DD-MON-YYYY HH24:MI:SS'));

COMMIT;



 CREATE TABLE "O5"."EDB_STAGE_SFCC_WL_WRK" 
   (	"EMAIL_ADDRESS" VARCHAR2(400 BYTE), 
	"ADD_DATE" VARCHAR2(400 BYTE), 
	"PRODUCT_SKUS" VARCHAR2(400 BYTE), 
	"PHONE_NUMBER" VARCHAR2(50 BYTE),
    "CREATE_DT" DATE DEFAULT SYSDATE
   );


GRANT ALL ON o5.EDB_STAGE_SFCC_WL_WRK to DM_USER;  



create or replace PROCEDURE       "P_WAITLIST_DATA_PREP_SFCC"
is 
bm_prd_id number;
bm_sku_id number;
currPrice varchar2(20)   default null;
vPrdCode  varchar2(200) default null;
vSku      number(20);
vSkuCode varchar2(200) default null;

begin
  execute immediate 'truncate table O5.edb_stage_dw_waitlist_wrk';
 -- update O5.edb_stage_mongo_wl_wrk set product_skus =replace(replace(replace(replace(product_skus,']'),'[') ,'"'),' ');
 -- commit;
  
     
     
    dbms_output.put_line('sku '||bm_prd_id||bm_sku_id);

      Insert into o5.edb_stage_dw_waitlist_wrk (WAITLIST_ID
                                              ,EMAIL_ADDRESS
                                              ,UPC
                                              ,BRAND_NAME
                                              ,ITEM_DESC
                                              ,SKU_SIZE
                                              ,SKU_COLOR
                                              ,SKU_PRICE
                                              ,PRODUCT_CODE
                                              ,QTY
                                              ,PRODUCT_DETAIL_URL
                                              ,WAITLIST_CREATED_DT
                                              ,WAITLIST_STATUS_CHANGE
                                              ,WAITLIST_SENT_DT
                                              ,WAITLIST_STATUS
                                              ,PHONE_NUMBER)
                         SELECT o5.WAITLIST_SEQ.nextval
                                              ,upper(sfw.email_address)
                                              ,sfw.product_skus
                                              ,bpw.BRAND_NAME
                                              ,bpw.BM_DESC
                                              ,bpw.SKU_SIZE1_DESC
                                              ,bpw.SKU_COLOR
                                              ,bpw.SKU_SALE_PRICE
                                              ,bpw.STYL_SEQ_NUM
                                              ,bpw.WH_SELLABLE_QTY
                                              ,bpw.PRODUCT_URL
                                              ,to_date(sfw.add_date,'MM/DD/YYYY HH24:MI:SS')
                                              ,null
                                              ,null
                                              ,'N'
                                              ,sfw.PHONE_NUMBER
 FROM o5.O5_PARTNERS_EXTRACT_WRK bpw ,o5.edb_stage_sfcc_wl_wrk sfw
where bpw.upc=lpad(sfw.PRODUCT_SKUS,13,0)   ;
      commit;
     
     
     
  
end p_waitlist_data_prep_SFCC;
/


GRANT EXECUTE on p_waitlist_data_prep_SFCC to DM_USER;


ALTER TABLE o5.tmp_edb_waitlist_extract_src1  ADD (TOT_AMT NUMBER(18,2),TOT_ITEM_AMT NUMBER(18,2));



  CREATE TABLE "O5"."FX_RATES" 
   (	"SOURCE_CURRENCY" VARCHAR2(5 BYTE), 
	"TARGET_CURRENCY" VARCHAR2(5 BYTE), 
	"EXCHANGE_RATE" NUMBER(15,10), 
	"UPDATE_DT" DATE DEFAULT SYSDATE
   );


GRANT SELECT ON O5.FX_RATES TO DM_USER;