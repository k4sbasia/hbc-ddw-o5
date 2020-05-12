set echo on
set feedback on
set linesize 10000
set pagesize 0
set trimspool on
set serverout on
set timing on
----------------------------------------------
-- Refreshing the sddw.mv_bi_sale materiliaze view
---------------------------------------------
EXEC dbms_output.put_line (to_char(sysdate,'HH:MM:SS AM'));

/*
UPDATE sddw.o5_thunder_upc
SET return_flag = 'Y'
WHERE
    upc IN (
        SELECT DISTINCT
            f1.upc
        FROM
            o5.bi_date_itm_fact f
            INNER JOIN (
                SELECT
                    MIN(n.transdate) transdate,
                    n.upc,
                    a.sku
                FROM
                    o5.bi_netsale n
                    INNER JOIN (
                        SELECT
                            MAX(orderdate) orderdate,
                            p.sku,
                            p.upc
                        FROM
                            sddw.o5_thunder_upc   u
                            INNER JOIN o5.bi_product         p ON u.upc = p.upc
                            INNER JOIN o5.bi_sale            s ON p.bm_skuid = s.bm_skuid
                               AND ordline_status = 'R' AND return_flag IS NULL AND flag = 'R' AND fullfilllocation = 'STORES'
                        GROUP BY p.sku, p.upc
                    ) a
                    ON n.upc = a.upc
                       AND n.transdate > a.orderdate
                       AND grossreturn <> 0
                GROUP BY n.upc, a.sku
            ) f1 ON f.itm_upc_num = f1.upc AND recv_qty > 0 AND f.actv_dt >= f1.transdate
    );

COMMIT;
*/
-- Refresh BI_SALE MV
EXEC dbms_mview.refresh('SDDW.MV_O5_BI_SALE', 'C', atomic_refresh => false);
-- Refresh BI_SALE MV
EXEC dbms_mview.refresh('SDDW.MV_O5_BI_PAYMENT', 'C', atomic_refresh => false);

EXEC dbms_output.put_line(to_char(sysdate, 'HH:MM:SS AM'));

EXIT;