set echo off
set feedback on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set serverout on
set timing on
----------------------------------------------
-- Refreshing the sddw.mv_bi_sale materiliaze view
---------------------------------------------
exec dbms_output.put_line (to_char(sysdate,'HH:MM:SS AM'));

UPDATE SDDW.O5_THUNDER_UPC SET RETURN_FLAG = 'Y' WHERE UPC IN
(SELECT DISTINCT f1.upc
FROM O5.BI_DATE_ITM_FACT F
INNER JOIN
  (SELECT MIN(n.transdate) transdate,
    n.upc,
    a.sku
  FROM O5.BI_NETSALE N
  INNER JOIN
    (SELECT MAX(orderdate) orderdate,
      p.sku,
      p.upc
    FROM SDDW.O5_THUNDER_UPC U
    INNER JOIN O5.BI_PRODUCT P
    ON U.UPC = P.UPC
    INNER JOIN O5.BI_SALE S
    ON P.BM_SKUID        = S.BM_SKUID
    AND ORDLINE_STATUS   = 'R'
    and return_flag is null
    and flag = 'R'  
    AND FULLFILLLOCATION = 'STORES'
    GROUP BY P.SKU,
      P.UPC
    ) A ON N.UPC   = A.UPC
  AND N.TRANSDATE  > A.ORDERDATE
  AND GROSSRETURN <> 0
  GROUP BY N.UPC,
    A.SKU
  ) F1 ON F.ITM_UPC_NUM = F1.UPC
AND RECV_QTY            > 0
AND F.ACTV_DT          >= F1.TRANSDATE);

commit;
 
--DROP INDEX SDDW.IDX1_MVBISALE_O5;
--DROP INDEX SDDW.MV_BI_SALE_ORDDT_BMSKU_IX_05;
--DROP INDEX SDDW.MV_IDX_CANCELDATE1_O5;
-- 
--Refresh MV
EXEC DBMS_MVIEW.REFRESH ('SDDW.MV_O5_BI_SALE','C',ATOMIC_REFRESH => false);


--CREATE INDEX SDDW.IDX1_MVBISALE_O5 ON SDDW.MV_O5_BI_SALE (LASTCHANGEDATE ASC);
--CREATE INDEX SDDW.MV_BI_SALE_ORDDT_BMSKU_IX_05 ON SDDW.MV_O5_BI_SALE (ORDERDATE ASC, BMSKUID ASC);
--CREATE INDEX SDDW.MV_IDX_CANCELDATE1_O5 ON SDDW.MV_O5_BI_SALE (CANCELDATE ASC);

show errors;
exec dbms_output.put_line (to_char(sysdate,'HH:MM:SS AM'));
exit;

