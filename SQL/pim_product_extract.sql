REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  pim_product_extract.sql
REM  DESCRIPTION:  This script PIM details for O5 products
REM                Runs as Part of Partner Extract and gets all Product and SKU attributes from PIM along with Assortments.
REM
REM  CODE HISTORY: Name                         Date                    Description
REM                -----------------            ----------              -----------
REM                Jayanthi                Feb-25-2020              Created
REM ###############################################################################
SET echo OFF
SET feedback OFF
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF
SET trimspool ON
SET serverout ON
SET verify OFF
SET TIMING ON
SET LINESIZE 10000
SET PAGESIZE 0
SET HEADING OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE
declare
BEGIN
    DBMS_OUTPUT.PUT_LINE('PIM Attribute Fetch Process Start :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
EXECUTE IMMEDIATE 'truncate table &1.all_active_pim_prd_attr_&2';
EXECUTE IMMEDIATE 'truncate table &1.all_active_pim_sku_attr_&2';
EXECUTE IMMEDIATE 'truncate table &1.all_actv_pim_assortment_&2';
    --Get Product Attributes
    INSERT INTO all_active_pim_prd_attr_&2
    (
     PRODUCT_ID ,
   PRD_STATUS ,
   PRD_READYFORPROD,
   BM_DESC  ,
   PRODUCTCOPY ,
   BRAND_NAME ,
   GWP_FLAG ,
   ISEGC ,
   IS_REVIEWABLE,
   IS_SHOPTHELOOK ,
   ITEM_GENDER ,
   BACK_ORDERABLE,
   READYFORPROD_TIMER ,
   READYFORPROD_END_TIME,
   PD_RESTRICTEDCOUNTRY_TEXT ,
   ALTERNATE,
   COLORIZATION_IND ,
   DROPSHIP_IND,
   ITEM_RISK ,
   PURCHASE_RESTRICTION ,
   WAITLIST ,
   SELLOFF ,
   DROPSHIP_AGENT,
   PERSONALIZABLE ,
   RETURNABLE  ,
   ZOOM   ,
   SL_WEB_OK ,
   SL_ENTITY ,
   SIZECHARTTEMPLATE ,
   SIZECHARTSUBTYPE ,
   PD_RESTRICTEDWARNING_TEXT ,
   PD_RESTRICTEDSTATE_TEXT ,
   PD_RESTRICTEDSHIPTYPE_TEXT,
   CountryOfOrigin
     )
        WITH all_product_attributes AS
       (
       SELECT
               product_id,
               attribute_name,
               TRIM(REPLACE(REPLACE(REPLACE(TRANSLATE(attribute_val, 'x'||CHR(10)||CHR(13), 'x'),'|',''),'^',''),'�','')) attribute_val
        FROM &3
       WHERE
       attribute_name IN  ( 'status',
     'ProductShortDescription',
     'PRODUCTCOPY',
     'GWP_Flag',
     'isEGC',
     'readyForProd',
     'BrandName',
     'Reviewable',
     'Is_ShopTheLook',
     'Item_Gender',
     'readyForProdTimer',
     'readyForProdEndTimer',
     'PD_RestrictedCountry_Text',
    'Alternate' ,
     'Colorization_Ind',
   'CountryOfOrigin',
   'DropShip_Ind',
   'Item_Risk',
   'PD_RestrictedShipType_Text',
   'PD_RestrictedState_Text',
   'PD_RestrictedWarning_Text',
   'PurchaseRestriction',
   'Returnable',
   'selloff',
   'SizeChartSubType',
   'SizeChartTemplate',
   'SL_web_ok',
   'SL_entity',
   'waitlist',
   'Zoom',
   'CountryOfOrigin')
     AND attribute_val IS NOT NULL
       )
       SELECT
               product_id,
               MAX(CASE WHEN attribute_name = 'status' THEN attribute_val END) AS prd_status,
               MAX(CASE WHEN attribute_name = 'readyForProd' THEN attribute_val END) AS prd_readyforprod,
               MAX(CASE WHEN attribute_name = 'ProductShortDescription' THEN attribute_val END) AS bm_desc,
               MAX(CASE WHEN attribute_name = 'PRODUCTCOPY' THEN attribute_val END) AS productcopy,
               MAX(CASE WHEN attribute_name = 'BrandName' THEN attribute_val END) AS brand_name,
               MAX(CASE WHEN attribute_name = 'GWP_Flag' THEN attribute_val END) AS gwp_flag,
               MAX(CASE WHEN attribute_name = 'isEGC' THEN attribute_val END) AS isegc,
               MAX(CASE WHEN attribute_name = 'Reviewable' THEN attribute_val END) AS is_reviewable,
               MAX(CASE WHEN attribute_name = 'Is_ShopTheLook' THEN attribute_val END) is_shopthelook,
               MAX(CASE WHEN attribute_name = 'Item_Gender' THEN attribute_val END) AS item_gender,
               MAX(CASE WHEN attribute_name = 'Backorderable' THEN attribute_val END) AS back_orderable,
               MAX(CASE WHEN attribute_name = 'readyForProdTimer' THEN attribute_val END) AS readyForProdTimer,
               MAX(CASE WHEN attribute_name = 'readyForProdEndTimer' THEN attribute_val END) AS readyForProdEndTimer,
               MAX(CASE WHEN attribute_name = 'PD_RestrictedCountry_Text' THEN attribute_val END) AS PD_RestrictedCountry_Text,
               MAX(CASE WHEN attribute_name = 'Alternate' THEN attribute_val END) Alternate,
               MAX(CASE WHEN attribute_name = 'Colorization_Ind' THEN attribute_val END) AS Colorization_Ind,
               MAX(CASE WHEN attribute_name = 'DropShip_Ind' THEN attribute_val END) AS DropShip_Ind,
               MAX(CASE WHEN attribute_name = 'Item_Risk' THEN attribute_val END) AS Item_Risk,
               MAX(CASE WHEN attribute_name = 'PurchaseRestriction' THEN attribute_val END) AS PurchaseRestriction,
                 MAX(CASE WHEN attribute_name = 'waitlist' THEN attribute_val END) AS waitlist,
                  MAX(CASE WHEN attribute_name = 'selloff' THEN attribute_val END) AS selloff,
               '' dropship_agent,
               '' Personalizable,
               MAX(CASE WHEN attribute_name = 'Returnable' THEN attribute_val END) AS Returnable,
                 MAX(CASE WHEN attribute_name = 'Zoom' THEN attribute_val END) AS Zoom,
                 MAX(CASE WHEN attribute_name = 'SL_web_ok' THEN attribute_val END) AS SL_web_ok,
               MAX(CASE WHEN attribute_name = 'SL_entity' THEN attribute_val END) AS SL_entity,
               MAX(CASE WHEN attribute_name = 'SizeChartTemplate' THEN attribute_val END) SizeChartTemplate,
               MAX(CASE WHEN attribute_name = 'SizeChartSubType' THEN attribute_val END) AS SizeChartSubType,
               MAX(CASE WHEN attribute_name = 'PD_RestrictedWarning_Text' THEN attribute_val END) AS PD_RestrictedWarning_Text,
                MAX(CASE WHEN attribute_name = 'PD_RestrictedState_Text' THEN attribute_val END) PD_RestrictedState_Text,
                MAX(CASE WHEN attribute_name = 'PD_RestrictedShipType_Text' THEN attribute_val END) AS PD_RestrictedShipType_Text,
                MAX(CASE WHEN attribute_name = 'CountryOfOrigin' THEN attribute_val END) AS CountryOfOrigin
   FROM all_product_attributes
       GROUP BY product_id
    ;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('PIM Product Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
--Get SKU Attributes
    INSERT INTO all_active_pim_sku_attr_&2
    (
      UPC  ,
  SKU_STATUS  ,
  SKU_COLOR,
  SKU_SIZE_DESC,
  PARENT_CATEGORY ,
  SIZE2_DESCRIPTION,
  COMPLEXSWATCH,
  WEBSTARTDATE ,
  WEBENDDATE,
  PICKUPALLOWEDIND ,
  PRIMARY_PARENT_COLOR,
  SKUHEXVALUE)
    WITH all_sku_attributes AS
                (
                SELECT
                        product_id,
                        upc,
                        attribute_name,
                        TRIM(REPLACE(REPLACE(TRANSLATE(attribute_val, 'x'||CHR(10)||CHR(13), 'x'),'|',''),'^','')) attribute_val
                 FROM &4
                WHERE attribute_name IN ('Color','Size','status','US_STDSize2','ComplexSwatch',
                    'webStartDate',
                    'webEndDate',
                    'pickUpAllowedInd',
                    'Primary_Parent_Color',
                    'SkuHexValue')
                  AND attribute_val IS NOT NULL
                )
        SELECT upc,
        MAX(CASE WHEN attribute_name = 'status' THEN attribute_val END) AS sku_status,
        MAX(CASE WHEN attribute_name = 'Color' THEN attribute_val ELSE NULL  END )AS sku_color,
        MAX(CASE WHEN attribute_name = 'Size' THEN attribute_val ELSE NULL  END) AS sku_size_desc,
        MAX(CASE WHEN attribute_name = 'status' THEN attribute_val ELSE NULL END) AS prd_active,
        MAX(CASE WHEN attribute_name = 'US_STDSize2' THEN attribute_val ELSE NULL END) AS size2_description,
         MAX(CASE WHEN attribute_name = 'ComplexSwatch' THEN attribute_val ELSE NULL END) AS ComplexSwatch,
         MAX(CASE WHEN attribute_name = 'webStartDate' THEN attribute_val ELSE NULL END) AS webStartDate,
          MAX(CASE WHEN attribute_name = 'webEndDate' THEN attribute_val ELSE NULL END) AS webEndDate,
         MAX(CASE WHEN attribute_name = 'pickUpAllowedInd' THEN attribute_val ELSE NULL END) AS pickUpAllowedInd,
         MAX(CASE WHEN attribute_name = 'Primary_Parent_Color' THEN attribute_val ELSE NULL END) AS Primary_Parent_Color,
         MAX(CASE WHEN attribute_name = 'SkuHexValue' THEN attribute_val ELSE NULL END) AS SkuHexValue
        FROM all_sku_attributes sku_attr
        GROUP BY upc
    ;
--Get Product Assortments
    INSERT INTO all_actv_pim_assortment_&2
    (
      PRODUCT_ID  ,
PRIMARY_PARENT_CATEGORY ,
PATH_LABEL ,
FOLDER_PATH,
PRODUCT_ASRT ,
FOLDERACTIVE,
READYFORPRODFOLDER
    )
    WITH all_folder_data
      AS (
            SELECT DISTINCT
                fl.folder_id,
                fl.folder_name,
                fl.folder_path,

                CONNECT_BY_ROOT fl.folder_name AS primary_parent_category,
                substr(sys_connect_by_path(fl.LABEL,'~'),2) AS path_label,
                LEVEL
            FROM &5 fl
            START WITH fl.folder_parent_id = 1464881062518
            CONNECT BY PRIOR fl.folder_id = fl.folder_parent_id
            AND fl.folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
--Below Change to get the Missing and Accurate Folder Path for all the products
--            AND status_cd = 'A'
            AND EXISTS (SELECT 1
                          FROM &6 fla
                         WHERE fla.folder_path = fl.folder_path
                           AND (CASE WHEN fla.attribute_name = 'readyForProdFolder' AND fla.attribute_val = 'Yes' THEN 1
                                     WHEN fla.attribute_name = 'folderactive'   AND fla.attribute_val = 'Yes' THEN 1
                                     ELSE 0
                                 END) = 1)
            ORDER BY LEVEL, fl.folder_id
        )
        ,all_assortments AS (
            SELECT
                asrt.object_name AS product_id,
                fd.primary_parent_category,
                fd.path_label,
                fd.folder_path,
--                asrt.assort_name ||
                asrt.sub_assrt_name  || '/' || object_name AS product_asrt,
                row_number() OVER(PARTITION BY asrt.object_name ORDER BY greatest(asrt.pim_actv_dt,asrt.modify_dt) DESC) AS latest_prd_path
        FROM
                &7 asrt
                JOIN all_folder_data fd ON fd.folder_path = asrt.assort_name || asrt.sub_assrt_name
            WHERE TRIM(asrt.assort_name) = '/Assortments/SaksMain/ShopCategory'
                and ACTIVITY_IND<>'Delete'
        ) SELECT
            product_id,
            primary_parent_category,
            path_label,
            folder_path,
            product_asrt,
            'T' FOLDERACTIVE,
            'T' READYFORPRODFOLDER
        FROM all_assortments
        WHERE latest_prd_path = 1;
    DBMS_OUTPUT.PUT_LINE('PIM Assortment Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('PIM SKU Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
END;
/
quit
