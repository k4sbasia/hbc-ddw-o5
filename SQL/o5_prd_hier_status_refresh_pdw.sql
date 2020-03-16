TRUNCATE TABLE &1.UPC_WITH_STORE_INV;

INSERT INTO &1.UPC_WITH_STORE_INV
SELECT OROS.UPC AS UPC_CODE 
FROM &1.OMS_RFS_O5_STG oros 
	JOIN &1.INVENTORY i ON i.SKN_NO =OROS.SKN_NO  
where in_stock_sellable_qty > 0;

COMMIT;

TRUNCATE TABLE &1.prd_hier_price_status;


INSERT INTO &1.prd_hier_price_status
   SELECT DISTINCT p.sku sku_code, p.upc upc_code, w.price_type,
                     h.department_id, h.department_name, p.class_id, h.GROUP_ID,
                     h.group_name, h.division_id, h.division_name, p.vendor_id
                FROM &1.bi_product p,
                     mrep.bi_merch_hier h,
                 --    mrep.SKU_DTL_WRK_FULL s, -- added
                     &1.UPC_WITH_STORE_INV i, -- take inventory into consideration 11/11/2013
                     (SELECT DISTINCT w.upc, 'P' price_type
                                 FROM &1.O5_WEBPRICE_WRK w,
                                      &1.O5_WEBPRICE_WRK w1
                                WHERE w.upc = w1.upc
                                  AND w.price_type = 'R'
                                  AND w.web_price > w1.web_price
                                  AND w1.price_type IS NULL
                      UNION
                      SELECT DISTINCT upc, price_type
                                 FROM &1.O5_WEBPRICE_WRK w2
                                WHERE price_type IS NOT NULL
                                  AND NOT EXISTS (
                                         SELECT w.upc
                                           FROM &1.O5_WEBPRICE_WRK w,
                                                &1.O5_WEBPRICE_WRK w1
                                          WHERE w1.price_type IS NULL
                                            AND w.upc = w1.upc
                                            AND w.upc = w2.upc
                                            AND w.price_type = 'R')) w
               WHERE h.department_id = p.department_id
                 AND h.GROUP_ID = p.GROUP_ID
                 AND h.division_id = p.division_id
            --     AND P.UPC = S.UPC -- added
            -- AND s.sku_group_code = '030' -- added
                 AND w.upc = p.upc
                 AND p.modify_dt > SYSDATE - 1
               and P.UPC = i.upc_code(+);

COMMIT;

QUIT