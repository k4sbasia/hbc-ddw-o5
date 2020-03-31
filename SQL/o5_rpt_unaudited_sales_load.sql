set timing on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
--Update the O5.unaudited_sales table
Truncate Table O5.Unaudited_Sales;
commit;

INSERT INTO O5.unaudited_sales
SELECT ROUND(SUM(SL.DEMAND_DOLLARS)) demand_$,
  ROUND(SUM(
  CASE
    WHEN SL.BACKORDER_IND=1
    THEN SL.DEMAND_DOLLARS
  END)) backorder_$,
  0 canx_$,
  0 gross_$,
  0 return_$,
  0 net_$
FROM SDDW.mv_O5_BI_SALE SL
WHERE orderdate             =TRUNC(sysdate-1)
AND sl.DIVISION_ID         IS NOT NULL
--AND sl.DIVISION_ID NOT     IN('4','5','9')
AND sl.DIVISION_ID NOT     IN('5','9')
AND sl.ORDER_HEADER_STATUS <> 'N'
--AND sl.group_id            <>68
;
Commit;

UPDATE O5.unaudited_sales
SET canx_$=
  (SELECT ROUND(SUM(SL.DEMAND_DOLLARS)) canx_$
  FROM SDDW.mv_O5_BI_SALE SL
  WHERE CANCELDATE            =TRUNC(sysdate-1)
  AND sl.DIVISION_ID         IS NOT NULL
--  AND sl.DIVISION_ID NOT     IN('4','5','9')
  AND sl.DIVISION_ID NOT     IN('5','9')
  AND sl.ORDER_HEADER_STATUS <> 'N'
--  AND sl.group_id            <>68
  AND ORDERSTATUS             ='X'
  );
Commit;

UPDATE O5.unaudited_sales
SET
  (
    gross_$,
    return_$,
    net_$
  )
  =
  (SELECT ROUND(NVL(SUM(NS.GROSSSALE),0) + NVL(SUM(NS.SALEDISCOUNT),0) + NVL(SUM(NS.SALEMARKDOWN),0)) grosssale_amt,
    ROUND(NVL(SUM(NS.GROSSRETURN)        + SUM(NS.RETURNDISCOUNT) + SUM(NS.RETURNMARKDOWN),0)) GROSSRETURN,
    ROUND(NVL(SUM(NS.GROSSSALE),0)       + NVL(SUM(NS.SALEDISCOUNT),0) + NVL(SUM(NS.SALEMARKDOWN),0))+ROUND(NVL(SUM(NS.GROSSRETURN) + SUM(NS.RETURNDISCOUNT) + SUM(NS.RETURNMARKDOWN),0)) net_$
  FROM sddw.mv_O5_bi_netsale ns
  WHERE NS.TRANSDATE = TRUNC(sysdate-1)
/*  AND NOT EXISTS
    (SELECT *
    FROM SDDW.mv_BI_MERCH_HIER mh
    WHERE to_number(NS.DEPARTMENT_ID)=to_number(MH.DEPARTMENT_ID)
    AND ( MH.DIVISION_ID            IN ('4','5','9')
  --  OR to_number(mh.group_id)        =68 
  )
    )*/
  );
  
COMMIT;

--Update the fashion fix unaudited sales table. comment out for off 5th


Truncate Table O5.Unaudited_Sales_Ff;

INSERT INTO O5.unaudited_sales_ff
SELECT ROUND(SUM(SL.DEMAND_DOLLARS)) demand_$,
  ROUND(SUM(
  CASE
    WHEN SL.BACKORDER_IND=1
    THEN SL.DEMAND_DOLLARS
  END)) backorder_$,
  0 canx_$,
  0 gross_$,
  0 return_$,
  0 net_$
FROM SDDW.mv_O5_BI_SALE SL
WHERE orderdate             =TRUNC(sysdate-1)
AND sl.DIVISION_ID         IS NOT NULL
AND sl.ORDER_HEADER_STATUS <> 'N'
AND sl.group_id             =68;
Commit;

UPDATE O5.unaudited_sales_ff
SET canx_$=
  (SELECT ROUND(SUM(SL.DEMAND_DOLLARS)) canx_$
  FROM SDDW.mv_O5_BI_SALE SL
  WHERE CANCELDATE            =TRUNC(sysdate-1)
  AND sl.DIVISION_ID         IS NOT NULL
  AND sl.ORDER_HEADER_STATUS <> 'N'
--  AND sl.group_id             =68
  AND ORDERSTATUS             ='X'
  );
  
Commit;

UPDATE O5.unaudited_sales_ff
SET
  (
    gross_$,
    return_$,
    net_$
  )
  =
  (SELECT ROUND(NVL(SUM(NS.GROSSSALE),0) + NVL(SUM(NS.SALEDISCOUNT),0) + NVL(SUM(NS.SALEMARKDOWN),0)) grosssale_amt,
    ROUND(NVL(SUM(NS.GROSSRETURN)        + SUM(NS.RETURNDISCOUNT) + SUM(NS.RETURNMARKDOWN),0)) GROSSRETURN,
    ROUND(NVL(SUM(NS.GROSSSALE),0)       + NVL(SUM(NS.SALEDISCOUNT),0) + NVL(SUM(NS.SALEMARKDOWN),0))+ROUND(NVL(SUM(NS.GROSSRETURN) + SUM(NS.RETURNDISCOUNT) + SUM(NS.RETURNMARKDOWN),0)) net_$
  FROM sddw.mv_O5_bi_netsale ns
  WHERE NS.TRANSDATE = TRUNC(sysdate-1)
  AND EXISTS
    (SELECT *
    FROM SDDW.mv_BI_MERCH_HIER mh
    WHERE to_number(NS.DEPARTMENT_ID)=to_number(MH.DEPARTMENT_ID)
  --  AND to_number(mh.group_id)       =68
    )
  );
COMMIT;

exit;
