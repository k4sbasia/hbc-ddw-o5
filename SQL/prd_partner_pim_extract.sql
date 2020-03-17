REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  prd_partner_pim_extract.sql
REM  DESCRIPTION:  This script PIM details for O5 products
REM                Runs as Part of Partner Extract and gets all Product and SKU attributes from PIM along with Assortments.
REM
REM  CODE HISTORY: Name                         Date                    Description
REM                -----------------            ----------              -----------
REM                Jayanthi                Feb-25-2020              Created
REM ###############################################################################
SET ECHO OFF
SET TIMING ON
SET LINESIZE 10000
SET PAGESIZE 0
SET HEADING OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
BEGIN

    DBMS_OUTPUT.PUT_LINE('PIM Attribute Fetch Process Start :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
    EXECUTE IMMEDIATE 'truncate table pim_exp_bm.all_active_pim_sku_attr';
    EXECUTE IMMEDIATE 'truncate table pim_exp_bm.all_active_pim_prd_attr';
    EXECUTE IMMEDIATE 'truncate table pim_exp_bm.all_actv_pim_assortment';

    --Get Product Attributes
    INSERT INTO pim_exp_bm.all_active_pim_prd_attr
    WITH all_product_attributes AS
    (
    SELECT
            product_id,
            attribute_name,
            TRIM(REPLACE(REPLACE(REPLACE(TRANSLATE(attribute_val, 'x'||CHR(10)||CHR(13), 'x'),'|',''),'^',''),'�','')) attribute_val
     FROM pim_exp_bm.pim_ab_o5_prd_attr_data
    WHERE attribute_name IN ('status','ProductShortDescription','PRODUCTCOPY','GWP_Flag','isEGC','readyForProd','BrandName','Reviewable',
                             'Is_ShopTheLook','Item_Gender','readyForProdTimer','readyForProdEndTimer','PD_RestrictedCountry_Text')
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
			MAX(CASE WHEN attribute_name = 'PD_RestrictedCountry_Text' THEN attribute_val END) AS PD_RestrictedCountry_Text
    FROM all_product_attributes
    GROUP BY product_id
    ;
    DBMS_OUTPUT.PUT_LINE('PIM Product Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
    --Get SKU Attributes
    INSERT INTO pim_exp_bm.all_active_pim_sku_attr
    WITH all_sku_attributes AS
                (
                SELECT
                        product_id,
                        upc,
                        attribute_name,
                        TRIM(REPLACE(REPLACE(TRANSLATE(attribute_val, 'x'||CHR(10)||CHR(13), 'x'),'|',''),'^','')) attribute_val
                 FROM pim_exp_bm.pim_ab_O5_sku_attr_data
                WHERE attribute_name IN ('Color','Size','status','US_STDSize2','Upc_Image')
                  AND attribute_val IS NOT NULL
                )
        SELECT upc,
                   MAX(CASE WHEN attribute_name = 'status' THEN attribute_val END) AS sku_status,
                   MAX(CASE WHEN attribute_name = 'Color' THEN attribute_val ELSE NULL  END )AS sku_color,
                   MAX(CASE WHEN attribute_name = 'Size' THEN attribute_val ELSE NULL  END) AS sku_size_desc,
                   MAX(CASE WHEN attribute_name = 'status' THEN attribute_val ELSE NULL END) AS prd_active,
                     NULL AS parent_category,
                   MAX(CASE WHEN attribute_name = 'US_STDSize2' THEN attribute_val ELSE NULL END) AS size2_description
        FROM all_sku_attributes sku_attr
        GROUP BY upc
    ;
    DBMS_OUTPUT.PUT_LINE('PIM SKU Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;
    --Get Product Assortments
    INSERT INTO pim_exp_bm.all_actv_pim_assortment
    WITH all_folder_data
      AS (
            SELECT DISTINCT
                fl.folder_id,
                fl.folder_name,
                fl.folder_path,
                CONNECT_BY_ROOT fl.folder_name AS primary_parent_category,
                substr(sys_connect_by_path(fl.LABEL,'~'),2) AS path_label,
                LEVEL
            FROM pim_exp_bm.pim_ab_o5_web_folder_data fl
            START WITH fl.folder_parent_id = 1464881062518
            CONNECT BY PRIOR fl.folder_id = fl.folder_parent_id
            AND fl.folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
--Below Change to get the Missing and Accurate Folder Path for all the products
--            AND status_cd = 'A'
            AND EXISTS (SELECT 1
                          FROM pim_exp_bm.pim_ab_o5_folder_attr_data fla
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
                pim_exp_bm.pim_ab_o5_bm_asrt_prd_assgn asrt
                JOIN all_folder_data fd ON fd.folder_path = asrt.assort_name || asrt.sub_assrt_name
            WHERE TRIM(asrt.assort_name) = '/Assortments/SaksMain/ShopCategory'
                and ACTIVITY_IND<>'Delete'
        ) SELECT
            product_id,
            primary_parent_category,
            path_label,
            folder_path,
            product_asrt
        FROM all_assortments
        WHERE latest_prd_path = 1;
    DBMS_OUTPUT.PUT_LINE('PIM Assortment Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS') || ' - ' || nvl((SQL%rowcount),0));
    COMMIT;

DBMS_OUTPUT.PUT_LINE('PIM Attribute Fetch Process End :  '|| to_char(sysdate,'MM-DD-YYYY HH:MI:SS'));
END;
/
EXIT;
