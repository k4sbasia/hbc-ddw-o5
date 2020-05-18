EXEC dbms_output.put_line ('BI_PRODUCT - MINI Started');

MERGE INTO &1.bi_mini_product hst
     USING (SELECT upc,
                   sku,
                   item,
                   sku_list_price,
                   sku_sale_price,
                   sku_size,
                   item_list_price,
                   item_description,
                   department_id,
                   vendor_id,
                   active_ind,
                   sku_color,
                   first_recv_dt,
                   last_recv_dt,
                   ven_styl_num,
                   item_cst_amt,
                   analysis_cde_1,
                   analysis_cde_4,
                   price_status,
                   --pub_date,
                   class_id,
                   SEASON_CODE,
                   brand_name,
                   CORP_ANALYSIS_CDE,
                   ANALYSIS_CDE_3,
                   compare_price,
                   ORIG_OWN_RTL_DOL,
                  CORP_ITEM_RETL_AMT
              FROM &1.bi_product where deactive_ind='N' and active_ind is not null ) trn
        ON (trn.upc = hst.upc)
WHEN MATCHED
THEN
   UPDATE SET hst.sku = trn.sku,
              hst.item = trn.item,
              hst.sku_list_price = trn.sku_list_price,
              hst.sku_sale_price = trn.sku_sale_price,
              hst.sku_size = trn.sku_size,
              hst.item_list_price = trn.item_list_price,
              hst.item_description = trn.item_description,
              hst.department_id = trn.department_id,
              hst.vendor_id = trn.vendor_id,
              hst.active_ind = trn.active_ind,
              hst.sku_color = trn.sku_color,
              hst.first_recv_dt = trn.first_recv_dt,
              hst.last_recv_dt = trn.last_recv_dt,
              hst.ven_styl_num = trn.ven_styl_num,
              hst.item_cst_amt = trn.item_cst_amt,
              hst.analysis_cde_1 = trn.analysis_cde_1,
              hst.analysis_cde_4 = trn.analysis_cde_4,
              hst.price_status = trn.price_status,
              --hst.pub_date = trn.pub_date,
              hst.class_id = trn.class_id,
              hst.season_code = trn.season_code,
              hst.vendor_description = trn.brand_name,
              hst.CORP_ANALYSIS_CDE = trn.CORP_ANALYSIS_CDE,
              hst.ANALYSIS_CDE_3 = trn.ANALYSIS_CDE_3,
              hst.compare_price  = trn.compare_price,
              hst.ORIG_OWN_RTL_DOL = trn.ORIG_OWN_RTL_DOL,
              hst.CORP_ITEM_RETL_AMT = trn.CORP_ITEM_RETL_AMT
WHEN NOT MATCHED
THEN
   INSERT     (upc,
               sku,
               item,
               sku_list_price,
               sku_sale_price,
               sku_size,
               item_list_price,
               item_description,
               department_id,
               vendor_id,
               active_ind,
               sku_color,
               first_recv_dt,
               last_recv_dt,
               ven_styl_num,
               item_cst_amt,
               analysis_cde_1,
               analysis_cde_4,
               price_status,
               --pub_date,
               class_id,
               season_code,
               vendor_description,
               CORP_ANALYSIS_CDE,
               ANALYSIS_CDE_3,
               compare_price,
               ORIG_OWN_RTL_DOL,
              CORP_ITEM_RETL_AMT)
       VALUES (trn.upc,
               trn.sku,
               trn.item,
               trn.sku_list_price,
               trn.sku_sale_price,
               trn.sku_size,
               trn.item_list_price,
               trn.item_description,
               trn.department_id,
               trn.vendor_id,
               trn.active_ind,
               trn.sku_color,
               trn.first_recv_dt,
               trn.last_recv_dt,
               trn.ven_styl_num,
               trn.item_cst_amt,
               trn.analysis_cde_1,
               trn.analysis_cde_4,
               trn.price_status,
              -- trn.pub_date,
               trn.class_id,
               trn.season_code,
               trn.brand_name,
               trn.CORP_ANALYSIS_CDE,
               trn.ANALYSIS_CDE_3,
               trn.compare_price,
               trn.ORIG_OWN_RTL_DOL,
               trn.CORP_ITEM_RETL_AMT);

COMMIT;

--delete records from mini_product where its inactive in RFS.

DELETE
FROM &1.bi_mini_product p
WHERE p.upc IN
  (SELECT mp.upc
  FROM &1.bi_mini_product mp,
    &1.bi_product p
  WHERE mp.upc       = p.upc
  AND ( p.deactive_ind = 'Y' or p.active_ind is null )
  );
COMMIT;

MERGE INTO &1.bi_mini_product hst
     USING (SELECT bp.upc,bp.product_code from
                   &1.bi_product bp, &1.bi_mini_product bm
                   where bp.upc = bm.upc and deactive_ind = 'N'
                   and nvl(bm.product_code,'0')<>bp.product_code
                            ) trn
        ON (trn.upc = hst.upc)
WHEN MATCHED
THEN
   UPDATE SET hst.product_code = trn.product_Code;
COMMIT;


MERGE INTO &1.bi_mini_product hst
     USING (
 SELECT DISTINCT
           oa.PRODUCT_ID AS product_id,
           oa.BM_DESC AS short_description,
           oa.RETURNABLE AS returnable,
           oa.PERSONALIZABLE AS personalizable,
           oa.SELLOFF AS  selloff,
           case when oa.PRD_READYFORPROD = 'Yes' then 'T'
           else 'F'
           end readyforprod
 FROM &1.all_active_pim_prd_attr_&2  oa
 ) trn
        ON (trn.product_id = hst.product_code)
 WHEN MATCHED
THEN
   UPDATE SET
                          hst.item_web_description =  substr(trn.short_description, 1, 200),
                          hst.returnable = trn.returnable,
                          hst.personalizable = trn.personalizable,
                          hst.selloff_flag = trn.selloff,
                         hst.readyforprod = trn.readyforprod;

COMMIT;

MERGE INTO &1.bi_mini_product hst
     USING (
 SELECT oa.upc,primary_parent_color color_family
 FROM &1.all_active_pim_sku_attr_&2  oa, &1.bi_mini_product op
 where oa.upc= op.upc
 and primary_parent_color is not null
 and oa.primary_parent_color <> op.COLOR_FAMILY
 ) trn
        ON (trn.upc = hst.upc)
 WHEN MATCHED
THEN
   UPDATE SET hst.COLOR_FAMILY = trn.color_family;

COMMIT;



--First update the pubdate with readyforprod set date
MERGE INTO &1.bi_mini_product hst
     USING (
   select distinct
   a.product_id,a.readyforprod_set_dt from
  ( select product_id,max(readyforprod_set_dt) readyforprod_set_dt from &1.READYFORPROD_SORT s
  --,o5.bi_mini_product bp
 -- where s.product_id = bp.product_code
   group by product_id ) a, &1.bi_mini_product p
   where a.product_id = p.product_code
   and nvl(readyforprod_set_dt,'01-JAN-1999') <> nvl(pub_date,'01-JAN-1999') ) trn
        ON (trn.product_id = hst.product_code)
WHEN MATCHED
THEN
   UPDATE SET
                                hst.pub_date=trn.readyforprod_set_dt;

commit;

EXEC dbms_output.put_line ('BI_PRODUCT - update procedure started');

--Procedure to check the latest row and other rows for a product and if any fields doesn't match update all the fields with the latest row value.

DECLARE
   CURSOR c1
   IS
      SELECT DISTINCT bp.item,
                      item_list_price,
                      item_description,
                      department_id,
                      vendor_id,
                      ven_styl_num,
                      analysis_cde_1,
                      analysis_cde_4,
                      pub_date,
                      brand_name
        FROM &1.bi_product bp,
             (SELECT DISTINCT b.id item
                FROM (  SELECT item id,
                               SUM (
                                  ORA_HASH (
                                        item_description
                                     || '|'
                                     || pub_date
                                     || '|'
                                     || item_list_price
                                     || '|'
                                     || department_id
                                     || '|'
                                     || vendor_id
                                     || '|'
                                     || ven_styl_num
                                     || '|'
                                     || NVL (analysis_cde_1, 'a')
                                     || '|'
                                     || NVL (analysis_cde_4, 'a')
                                     || '|'
                                     || brand_name,
                                     POWER (2, 16) - 1))
                                  val
                          FROM &1.bi_product
                      GROUP BY item,
                               item_description,
                               pub_date,
                               item_list_price,
                               department_id,
                               vendor_id,
                               ven_styl_num,
                               analysis_cde_1,
                               analysis_cde_4,
                               brand_name) a,
                     (  SELECT item id,
                               SUM (
                                  ORA_HASH (
                                        item_description
                                     || '|'
                                     || pub_date
                                     || '|'
                                     || item_list_price
                                     || '|'
                                     || department_id
                                     || '|'
                                     || vendor_id
                                     || '|'
                                     || ven_styl_num
                                     || '|'
                                     || NVL (analysis_cde_1, 'a')
                                     || '|'
                                     || NVL (analysis_cde_4, 'a')
                                     || '|'
                                     || brand_name,
                                     POWER (2, 16) - 1))
                                  val
                          FROM &1.bi_product
                      GROUP BY Item,
                               item_description,
                               pub_date,
                               item_list_price,
                               department_id,
                               vendor_id,
                               ven_styl_num,
                               analysis_cde_1,
                               analysis_cde_4,
                               brand_name) B
               WHERE a.id = b.id AND a.val != b.val) t
       WHERE bp.item = t.item AND TRUNC (bp.modify_dt) = TRUNC (SYSDATE);

   TYPE c1_type IS TABLE OF c1%ROWTYPE
                      INDEX BY PLS_INTEGER;

   rec1           c1_type;
   v_para_value   NUMBER (38) := 2000;
BEGIN
   OPEN c1;

   LOOP
      FETCH c1
      BULK COLLECT INTO rec1
      LIMIT v_para_value;

      FOR r1 IN 1 .. rec1.COUNT
      LOOP
         UPDATE &1.bi_mini_product
            SET item_list_price = rec1 (r1).item_list_price,
                item_description = rec1 (r1).item_description,
                department_id = rec1 (r1).department_id,
                vendor_id = rec1 (r1).vendor_id,
                ven_styl_num = rec1 (r1).ven_styl_num,
                analysis_cde_1 = rec1 (r1).analysis_cde_1,
                analysis_cde_4 = rec1 (r1).analysis_cde_4,
                pub_date = rec1 (r1).pub_date,
                vendor_description = rec1 (r1).brand_name
          WHERE item = rec1 (r1).item;
      END LOOP;

      COMMIT;
      EXIT WHEN c1%NOTFOUND;
   END LOOP;

   COMMIT;
END;
/

EXEC dbms_output.put_line ('BI_PRODUCT - update procedure completed');

exec  dbms_stats.gather_table_stats('&2','bi_mini_product',estimate_percent=> 100);

--Dropping the indexes for MV
exec sddw.p_drop_index_on_mv('MV_O5_BI_MINI_PRODUCT');

--Refreshing the MV
exec DBMS_MVIEW.REFRESH('sddw.mv_o5_bi_mini_product','c');

--Recreating the indexes
CREATE INDEX "SDDW"."IDX_O5_ITEM_IDX_MV" ON "SDDW"."MV_O5_BI_MINI_PRODUCT"
  (
    "ITEM"
  );


commit;
exit
