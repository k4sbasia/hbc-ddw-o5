SET echo off
SET feedback off
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading off
SET trimspool on
SET serverout on
--- changelevel 2010:04:01 -- use psa add date to identify adjustment and andd a get class routine using upc
INSERT INTO O5.bi_runstats
   SELECT 'o5_bi_demand_fi_ext.sh' job_name,
          INITCAP (TO_CHAR (SYSDATE, 'MONDD')) load_dt,
          TO_CHAR (SYSDATE, 'HH24:MI P.M.') load_tm, 0 sfile_size,
          'Demand FTP Extract for financial' file_name, 0 load_count,
          0 file_count, 0 tfile_size, SYSDATE add_dt, NULL modify_dt,
          0 source_count, 0 target_count
     FROM DUAL;
COMMIT ;
TRUNCATE TABLE O5.bi_psa_demand_ext;
INSERT INTO O5.bi_psa_demand_ext
   SELECT   a.datekey, a.department_id, product_id sku, '000' class_id,
            SUM (total_demand_qty) demand_qty,
            SUM (total_demand_dollars) demand_dollars,
            SUM (cancel_qty) cancel_qty, SUM (cancel_dollars) cancel_dollars,
            SUM (bord_demand_qty) backorder_qty,
            SUM (bord_demand_dollars) backorder_dollars
       FROM O5.bi_psa a
      WHERE --a.division_id NOT IN ('4','9') AND
      	    a.division_id NOT IN ('9') AND
            add_dt > SYSDATE - 1
   GROUP BY a.datekey, a.department_id, product_id               -- c.class_id
                                                  ;
COMMIT ;
MERGE INTO O5.bi_psa_demand_ext hst
   USING (SELECT   datekey, a.sku, a.department_id, MAX (b.class_id) class_id
              FROM O5.bi_psa_demand_ext a, O5.bi_product b
             WHERE a.sku = b.sku AND a.department_id = b.department_id
          GROUP BY datekey, a.sku, a.department_id) trn
   ON (    hst.sku = trn.sku
       AND hst.department_id = trn.department_id
       AND hst.datekey = trn.datekey)
   WHEN MATCHED THEN
      UPDATE
         SET hst.class_id = trn.class_id
   WHEN NOT MATCHED THEN
      INSERT (hst.datekey, hst.sku, hst.class_id, hst.department_id)
      VALUES (trn.datekey, trn.sku, trn.class_id, trn.department_id);
COMMIT ;
MERGE INTO O5.bi_psa_demand_ext hst
   USING (SELECT   datekey, a.sku, a.department_id, MAX (b.class_id) class_id
              FROM O5.bi_psa_demand_ext a, O5.bi_product b
             WHERE a.sku = b.upc
               AND a.department_id = b.department_id
               AND a.class_id = '000'
          GROUP BY datekey, a.sku, a.department_id) trn
   ON (    hst.sku = trn.sku
       AND hst.department_id = trn.department_id
       AND hst.datekey = trn.datekey)
   WHEN MATCHED THEN
      UPDATE
         SET hst.class_id = trn.class_id
   WHEN NOT MATCHED THEN
      INSERT (hst.datekey, hst.sku, hst.class_id, hst.department_id)
      VALUES (trn.datekey, trn.sku, trn.class_id, trn.department_id);
COMMIT ;
SELECT    TO_CHAR (datekey, 'yyyy-mm-dd')
       || ','
       || department_id
       || ','
       || class_id
       || ','
       || demand_qty
       || ','
       || demand_dollars
       || ','
       || cancel_qty
       || ','
       || cancel_dollars
       || ','
       || backorder_qty
       || ','
       || backorder_dollars
  FROM (SELECT   datekey, department_id, class_id, SUM (demand_qty)
                                                                   demand_qty,
                 SUM (demand_dollars) demand_dollars,
                 SUM (cancel_qty) cancel_qty,
                 SUM (cancel_dollars) cancel_dollars,
                 SUM (backorder_qty) backorder_qty,
                 SUM (backorder_dollars) backorder_dollars
            FROM O5.bi_psa_demand_ext
        GROUP BY datekey, department_id, class_id
        ORDER BY datekey, department_id, class_id DESC);
UPDATE O5.bi_runstats
   SET target_count = (SELECT COUNT (DISTINCT ordernum)
                         FROM O5.bi_sale_ftp_wrk
                        WHERE TRUNC (datekey) = TRUNC (SYSDATE - 1)),
       modify_dt = SYSDATE
 WHERE TRUNC (add_dt) = TRUNC (SYSDATE)
   AND job_name = 'o5_bi_demand_fi_ext.sh'
   AND modify_dt IS NULL;
commit;
exit;
