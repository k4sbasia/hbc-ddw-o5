
MERGE INTO saks_custom.prd_hier_price_status hst
   USING (SELECT DISTINCT sku_code, upc_code, price_type, department_id,
                          department_name, class_id, GROUP_ID, group_name,
                          division_id, division_name, vendor_id
                     FROM o5.prd_hier_price_status@mrep) trn
   ON (hst.upc_code = trn.upc_code)
   WHEN MATCHED THEN
      UPDATE
         SET hst.sku_code = trn.sku_code, 
             hst.price_type = trn.price_type,
             hst.department_id = trn.department_id,
             hst.department_name = trn.department_name,
             hst.class_id = trn.class_id, hst.GROUP_ID = trn.GROUP_ID,
             hst.group_name = trn.group_name,
             hst.division_id = trn.division_id,
             hst.division_name = trn.division_name,
             hst.vendor_id = trn.vendor_id
   WHEN NOT MATCHED THEN
      INSERT (sku_code, upc_code, price_type, department_id, department_name,
              class_id, GROUP_ID, group_name, division_id, division_name,
              vendor_id)
      VALUES (trn.sku_code, trn.upc_code, trn.price_type, trn.department_id,
              trn.department_name, trn.class_id, trn.GROUP_ID, trn.group_name,
              trn.division_id, trn.division_name, trn.vendor_id);
COMMIT;


QUIT