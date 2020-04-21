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
EXECUTE IMMEDIATE 'truncate table &1.ALL_PRODUCT_ATTR_RR_FEED_&2';
    --Get Product Attributes
    DBMS_OUTPUT.PUT_LINE('PIM Product ATTRIBUTE Fetch Process Start :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
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
   CountryOfOrigin,
   DROPSHIP_LEADDAYS,
    PIM_ACTV_DT,
     PIM_ADD_DT,
     PIM_MODIFY_DT
     )
        WITH all_product_attributes AS
       (
       SELECT
               product_id,
               attribute_name,
               PIM_ACTV_DT,
               ADD_DT,
               MODIFY_DT,
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
   'CountryOfOrigin',
   'DropShip_LeadDays'
    )
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
                MAX(CASE WHEN attribute_name = 'CountryOfOrigin' THEN attribute_val END) AS CountryOfOrigin,
                MAX(CASE WHEN attribute_name = 'DropShip_LeadDays' THEN attribute_val END) AS DropShip_LeadDays,
                max(PIM_ACTV_DT) As PIM_ACTV_DT,
                MAX(ADD_DT) AS ADD_DT,
                MAX(MODIFY_DT) AS MODIFY_DT
   FROM all_product_attributes
       GROUP BY product_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('PIM Product Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('PIM SKU Attribute Fetch Process Start :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
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
  SKUHEXVALUE,
  PIM_ACTV_DT,
  PIM_ADD_DT,
  PIM_MODIFY_DT)
    WITH all_sku_attributes AS
                (
                SELECT
                        product_id,
                        upc,
                        attribute_name,
                        PIM_ACTV_DT,
                        ADD_DT,
                        MODIFY_DT,
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
         MAX(CASE WHEN attribute_name = 'SkuHexValue' THEN attribute_val ELSE NULL END) AS SkuHexValue,
         max(PIM_ACTV_DT) As PIM_ACTV_DT,
         MAX(ADD_DT) AS ADD_DT,
        MAX(MODIFY_DT) AS MODIFY_DT
        FROM all_sku_attributes sku_attr
        GROUP BY upc
    ;
    DBMS_OUTPUT.PUT_LINE('PIM SKU Attribute Fetch Process ENDED  :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
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
            START WITH fl.folder_parent_id = 1408474395181059
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
DBMS_OUTPUT.PUT_LINE('Rich Relavance all product attribite Fetch Process Started  :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
insert into ALL_PRODUCT_ATTR_RR_FEED_&2
WITH all_product_attributes AS
       (SELECT
               product_id,
               attribute_name,
               TRIM(REPLACE(REPLACE(REPLACE(TRANSLATE(attribute_val, 'x'||CHR(10)||CHR(13), 'x'),'|',''),'^',''),'�','')) attribute_val
        FROM &3
       WHERE
       lower(attribute_name) IN  ('backorderable',
                                'brandname',
                                'dropship_ind',
                                'featuredtype',
                                'gwp_flag',
                                'item_gender',
                                'pd_restrictedcountry_text',
                                'pd_restrictedstate_text',
                                'personalizable',
                                'productshortdescription',
                                'returnable',
                                'totalreviewcount',
                                'isdesigneritem',
                                'isegc',
                                'isvirtual',
                                'lifestylecontemporary',
                                'lifestylemodern',
                                'lifestylepremier',
                                'refinementproducttype1',
                                'refinementproducttype2',
                                'refinementproducttype3',
                                'refinementstyle1',
                                'refinementstyle2',
                                'refinementstyle3',
                                'refage',
                                'refcollection',
                                'refconcern1',
                                'refconcern2',
                                'refconcern3',
                                'refcoverage',
                                'refcuff',
                                'reffinefashion',
                                'reffinish',
                                'refgender',
                                'reflength',
                                'refmaterial1',
                                'refmaterial2',
                                'refmaterial3',
                                'refoccasion1',
                                'refoccasion2',
                                'refpatternprint',
                                'refrise',
                                'refspf',
                                'refscent1',
                                'refscent2',
                                'refscent3',
                                'refsilhouette1',
                                'refsilhouette2',
                                'refsilhouette3',
                                'refskintype',
                                'refsleevelength',
                                'refwash',
                                'refinementfit1',
                                'refinementfit2',
                                'refinementheelheight'
                              )
             -- and product_id = '0400093605703'
     AND attribute_val IS NOT NULL
     )
      SELECT
               product_id,
              MAX(CASE WHEN lower(attribute_name) = 	'brandname'	THEN attribute_val END)  as  brandname,
MAX(CASE WHEN lower(attribute_name) = 	'dropship_ind'	THEN attribute_val END)  as  dropship_ind,
MAX(CASE WHEN lower(attribute_name) = 	'featuredtype'	THEN attribute_val END)  as  featuredtype,
MAX(CASE WHEN lower(attribute_name) = 	'gwp_flag'	THEN attribute_val END)  as  gwp_flag,
MAX(CASE WHEN lower(attribute_name) = 	'isdesigneritem'	THEN attribute_val END)  as  isdesigneritem,
MAX(CASE WHEN lower(attribute_name) = 	'isegc'	THEN attribute_val END)  as  isegc,
MAX(CASE WHEN lower(attribute_name) = 	'isvirtual'	THEN attribute_val END)  as  isvirtual,
MAX(CASE WHEN lower(attribute_name) = 	'item_gender'	THEN attribute_val END)  as  item_gender,
MAX(CASE WHEN lower(attribute_name) = 	'lifestylecontemporary'	THEN attribute_val END)  as  lifestylecontemporary,
MAX(CASE WHEN lower(attribute_name) = 	'lifestylemodern'	THEN attribute_val END)  as  lifestylemodern,
MAX(CASE WHEN lower(attribute_name) = 	'lifestylepremier'	THEN attribute_val END)  as  lifestylepremier,
MAX(CASE WHEN lower(attribute_name) = 	'pd_restrictedcountry_text'	THEN attribute_val END)  as  pd_restrictedcountry_text,
MAX(CASE WHEN lower(attribute_name) = 	'pd_restrictedstate_text'	THEN attribute_val END)  as  pd_restrictedstate_text,
MAX(CASE WHEN lower(attribute_name) = 	'personalizable'	THEN attribute_val END)  as  personalizable,
MAX(CASE WHEN lower(attribute_name) = 	'productshortdescription'	THEN attribute_val END)  as  productshortdescription,
MAX(CASE WHEN lower(attribute_name) = 	'refage'	THEN attribute_val END)  as  refage,
MAX(CASE WHEN lower(attribute_name) = 	'refcollection'	THEN attribute_val END)  as  refcollection,
MAX(CASE WHEN lower(attribute_name) = 	'refconcern1'	THEN attribute_val END)  as  refconcern1,
MAX(CASE WHEN lower(attribute_name) = 	'refconcern2'	THEN attribute_val END)  as  refconcern2,
MAX(CASE WHEN lower(attribute_name) = 	'refconcern3'	THEN attribute_val END)  as  refconcern3,
MAX(CASE WHEN lower(attribute_name) = 	'refcoverage'	THEN attribute_val END)  as  refcoverage,
MAX(CASE WHEN lower(attribute_name) = 	'refcuff'	THEN attribute_val END)  as  refcuff,
MAX(CASE WHEN lower(attribute_name) = 	'reffinefashion'	THEN attribute_val END)  as  reffinefashion,
MAX(CASE WHEN lower(attribute_name) = 	'reffinish'	THEN attribute_val END)  as  reffinish,
MAX(CASE WHEN lower(attribute_name) = 	'refgender'	THEN attribute_val END)  as  refgender,
MAX(CASE WHEN lower(attribute_name) = 	'refinementfit1'	THEN attribute_val END)  as  refinementfit1,
MAX(CASE WHEN lower(attribute_name) = 	'refinementfit2'	THEN attribute_val END)  as  refinementfit2,
MAX(CASE WHEN lower(attribute_name) = 	'refinementheelheight'	THEN attribute_val END)  as  refinementheelheight,
MAX(CASE WHEN lower(attribute_name) = 	'refinementproducttype1'	THEN attribute_val END)  as  refinementproducttype1,
MAX(CASE WHEN lower(attribute_name) = 	'refinementproducttype2'	THEN attribute_val END)  as  refinementproducttype2,
MAX(CASE WHEN lower(attribute_name) = 	'refinementproducttype3'	THEN attribute_val END)  as  refinementproducttype3,
MAX(CASE WHEN lower(attribute_name) = 	'refinementstyle1'	THEN attribute_val END)  as  refinementstyle1,
MAX(CASE WHEN lower(attribute_name) = 	'refinementstyle2'	THEN attribute_val END)  as  refinementstyle2,
MAX(CASE WHEN lower(attribute_name) = 	'refinementstyle3'	THEN attribute_val END)  as  refinementstyle3,
MAX(CASE WHEN lower(attribute_name) = 	'reflength'	THEN attribute_val END)  as  reflength,
MAX(CASE WHEN lower(attribute_name) = 	'refmaterial1'	THEN attribute_val END)  as  refmaterial1,
MAX(CASE WHEN lower(attribute_name) = 	'refmaterial2'	THEN attribute_val END)  as  refmaterial2,
MAX(CASE WHEN lower(attribute_name) = 	'refmaterial3'	THEN attribute_val END)  as  refmaterial3,
MAX(CASE WHEN lower(attribute_name) = 	'refoccasion1'	THEN attribute_val END)  as  refoccasion1,
MAX(CASE WHEN lower(attribute_name) = 	'refoccasion2'	THEN attribute_val END)  as  refoccasion2,
MAX(CASE WHEN lower(attribute_name) = 	'refpatternprint'	THEN attribute_val END)  as  refpatternprint,
MAX(CASE WHEN lower(attribute_name) = 	'refrise'	THEN attribute_val END)  as  refrise,
MAX(CASE WHEN lower(attribute_name) = 	'refscent1'	THEN attribute_val END)  as  refscent1,
MAX(CASE WHEN lower(attribute_name) = 	'refscent2'	THEN attribute_val END)  as  refscent2,
MAX(CASE WHEN lower(attribute_name) = 	'refscent3'	THEN attribute_val END)  as  refscent3,
MAX(CASE WHEN lower(attribute_name) = 	'refsilhouette1'	THEN attribute_val END)  as  refsilhouette1,
MAX(CASE WHEN lower(attribute_name) = 	'refsilhouette2'	THEN attribute_val END)  as  refsilhouette2,
MAX(CASE WHEN lower(attribute_name) = 	'refsilhouette3'	THEN attribute_val END)  as  refsilhouette3,
MAX(CASE WHEN lower(attribute_name) = 	'refskintype'	THEN attribute_val END)  as  refskintype,
MAX(CASE WHEN lower(attribute_name) = 	'refsleevelength'	THEN attribute_val END)  as  refsleevelength,
MAX(CASE WHEN lower(attribute_name) = 	'refspf'	THEN attribute_val END)  as  refspf,
MAX(CASE WHEN lower(attribute_name) = 	'refwash'	THEN attribute_val END)  as  refwash,
MAX(CASE WHEN lower(attribute_name) = 	'returnable'	THEN attribute_val END)  as  returnable,
MAX(CASE WHEN lower(attribute_name) = 	'totalreviewcount'	THEN attribute_val END)  as  totalreviewcount,
MAX(CASE WHEN lower(attribute_name) = 	'backorderable'	THEN attribute_val END)  as  backorderable
   FROM all_product_attributes
       GROUP BY product_id
    ;
    DBMS_OUTPUT.PUT_LINE('PIM SKU Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
END;
/
quit
