set linesize 30000
set heading off
set echo off
set feedback off
set pagesize 0
set trimspool on
--SET TERMOUT OFF
set serverout on
--set verify off
set timing on

TRUNCATE TABLE PIM_EXP_BM.SFCC_ACTV_PIM_ASSORTMENT_O5;

INSERT INTO PIM_EXP_BM.SFCC_ACTV_PIM_ASSORTMENT_O5
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
            FROM PIM_EXP_BM.pim_ab_o5_web_folder_data fl
            START WITH fl.folder_parent_id = 1408474395181059
            CONNECT BY PRIOR fl.folder_id = fl.folder_parent_id
            AND fl.folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
--Below Change to get the Missing and Accurate Folder Path for all the products
--            AND status_cd = 'A'
            AND EXISTS (SELECT 1
                          FROM PIM_EXP_BM.pim_ab_o5_folder_attr_data fla
                         WHERE fla.folder_path = fl.folder_path
                           AND (CASE WHEN lower(fla.attribute_name) = 'readyforprodfolder' AND fla.attribute_val = 'Yes' THEN 1
                                     WHEN lower(fla.attribute_name) = 'folderactive'   AND fla.attribute_val = 'Yes' THEN 1
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
                PIM_EXP_BM.pim_ab_o5_bm_asrt_prd_assgn asrt
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
        FROM all_assortments;
		
COMMIT;

DELETE FROM O5.SFCC_ACTV_PIM_ASSORTMENT_O5@SDW_MREP;
COMMIT;

INSERT INTO O5.SFCC_ACTV_PIM_ASSORTMENT_O5@SDW_MREP SELECT * FROM PIM_EXP_BM.SFCC_ACTV_PIM_ASSORTMENT_O5;

COMMIT;

exit