set pagesize 0
set linesize 200
set echo off
set feedback off
set trimspool on
set serverout on
set heading off
  SELECT    'ORDER_NO'
       || ','
       ||'ENTERPRISE_KEY'
       || ','
       ||'ORDER_DATE'
       ||','
       || 'CUSTOMER_EMAILID'
       || ','
       || 'CSRID'
       || ','
       || 'CSR_USER'
       || ','
       || 'CONTACTDATE'
       || ','
       || 'ORDERTYPE'
       from dual;
SELECT    SAL.ORDERNUM
         || ','
         ||'OFF5TH'
         || ','
         ||trunc(orderdate)
         || ','
         || CUS.INTERNETADDRESS
         || ','
         || CSR.USER_NAME
         || ','
         || CSR.USER_NAME
         || ','
         || TO_CHAR (OE.ORV_CREATE_DT, 'YYYY-MM-DD HH:MI:SS AM')
         || ','
         || SAL.ORDERTYPE
    FROM &1.BI_SALE SAL
         INNER JOIN &1.BI_CUSTOMER CUS
            ON SAL.CREATEFOR = CUS.CUSTOMER_ID
		  inner join  &1.email_address EA
           on  CUS.INTERNETADDRESS = ea.email_address and opt_in=1		
         INNER JOIN &1.BI_ORDER_EVENT OE
            ON SAL.ORDERHDR = OE.ORV_ORH_ID
         LEFT JOIN &1.CSR_LOOKUP CSR
            ON OE.ORV_CREATED_BY = CSR.USER_ID
   WHERE (OE.ORV_CREATE_DT BETWEEN TRUNC (SYSDATE - 1)
                               AND   TRUNC (SYSDATE - 1)
                                   + 23 / 24
                                   + 59 / 1440
                                   + 59 / 24 / 60 / 60
          AND orv_created_by > 0
          AND orv_typ_cd IS NULL)
         AND (SAL.ORDERSEQ = 1 AND SAL.ORDERNUM IS NOT NULL)
GROUP BY SAL.ORDERNUM,
         trunc(orderdate),
         CUS.INTERNETADDRESS,
         TO_CHAR (OE.ORV_CREATED_BY),
         TO_CHAR (OE.ORV_CREATE_DT, 'YYYY-MM-DD HH:MI:SS AM'),
         CSR.USER_NAME,
         SAL.ORDERTYPE
ORDER BY SAL.ORDERNUM,
         CUS.INTERNETADDRESS,
         TO_CHAR (OE.ORV_CREATED_BY),
         TO_CHAR (OE.ORV_CREATE_DT, 'YYYY-MM-DD HH:MI:SS AM'),
         CSR.USER_NAME,
         SAL.ORDERTYPE;
exit;