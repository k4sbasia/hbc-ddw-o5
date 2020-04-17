WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
set serverout off
SET ECHO OFF
SET FEEDBACK OFF
SET LINESIZE 10000
SET PAGESIZE 0
SET SQLPROMPT ''
SET HEADING OFF
SET VERIFY OFF
SELECT 'category_id' || '|' || 'parent_id' || '|' || 'name' FROM DUAL;
SELECT
    a.folder_id
    || '|'
    || a.folder_parent_id
    || '|'
    || label
FROM
    pim_exp_bm.pim_ab_o5_web_folder_data@&2 a,
    (
        SELECT
            *
        FROM
            (
                SELECT
                    folder_path,
                    MAX(
                        CASE
                            WHEN attribute_name = 'FolderActive' THEN
                                attribute_val
                        END
                    ) AS folderactive,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdStartTime' THEN
                                attribute_val
                        END
                    ) AS readyforprodstarttime,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdEndTime' THEN
                                attribute_val
                        END
                    ) AS readyforprodendtime
                FROM
                    pim_exp_bm.pim_ab_o5_folder_attr_data@&2
                WHERE
                    folder_path IS NOT NULL
                GROUP BY
                    folder_path
            )
        WHERE
            folderactive = 'Yes'
            AND ( nvl(to_date(readyforprodstarttime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) <= trunc(sysdate)
                  AND nvl(to_date(readyforprodendtime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) >= trunc(sysdate) )
            AND ( ( folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
      OR (folder_path LIKE '/Assortments/SaksMain/Custom%'))
             )
    ) b
WHERE
    a.folder_path = b.folder_path
     -- and a.folder_path = '/Assortments/SaksMain/ShopCategory/Women/Apparel/Coats'
    AND status_cd = 'A'
union
SELECT
lower(replace(replace(replace( a.folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>'))
    || '|'
    || rtrim(lower(replace(replace(replace(replace( a.folder_path,'/Assortments/SaksMain/ShopCategory/',''),'/Assortments/SaksMain/Custom/',''),'/','>'),folder_name,'')),'>')
    || '|'
    ||a.folder_name
FROM
    pim_exp_bm.pim_ab_o5_web_folder_data@pim_read a,
    (
        SELECT
            *
        FROM
            (
                SELECT
                    folder_path,
                    MAX(
                        CASE
                            WHEN attribute_name = 'FolderActive' THEN
                                attribute_val
                        END
                    ) AS folderactive,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdStartTime' THEN
                                attribute_val
                        END
                    ) AS readyforprodstarttime,
                    MAX(
                        CASE
                            WHEN attribute_name = 'readyForProdEndTime' THEN
                                attribute_val
                        END
                    ) AS readyforprodendtime
                FROM
                    pim_exp_bm.pim_ab_o5_folder_attr_data@pim_read
                WHERE
                    folder_path IS NOT NULL
                GROUP BY
                    folder_path
            )
        WHERE
            folderactive = 'Yes'
            AND ( nvl(to_date(readyforprodstarttime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) <= trunc(sysdate)
                  AND nvl(to_date(readyforprodendtime, 'MM/DD/YYYY HH:MI PM'), trunc(sysdate)) >= trunc(sysdate) )
            AND ( ( folder_path LIKE '/Assortments/SaksMain/ShopCategory%'
      OR (folder_path LIKE '/Assortments/SaksMain/Custom%'))
             )
    ) b
WHERE
    a.folder_path = b.folder_path
     -- and a.folder_path = '/Assortments/SaksMain/ShopCategory/Women/Apparel/Coats'
    AND status_cd = 'A';    
EXIT;
