REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM 
REM  SCRIPT NAME:  o5_bi_promo_update.sql 
REM  DESCRIPTION:  It Updates the bi_promo_sale table
REM                
REM                
REM                
REM                
REM              
REM
REM  CODE HISTORY: Name	               		Date 	       	Description
REM                -----------------	  	----------  	--------------------------
REM                Unknown     		      	Unknown     	Created
REM                Rajesh Mathew		08/05/2010		Modified
REM                Divya Kafle			11/06/2013		Modified
REM ############################################################################
set timing on
delete from O5.bi_promo_sale_wrk A
where not exists (select ordernum from O5.bi_sale b where a.ordernum = b.ordernum)
;
commit;
merge into O5.BI_PROMO_SALE bb 
using 
( SELECT distinct ordernum, promo_id
  FROM (SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_02))>=10
    THEN SUBSTR(trim(promo_id_02), 1, 4)
    ELSE trim(promo_id_02)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_02 IS NOT NULL
        UNION
        SELECT ordernum,
 CASE
    WHEN LENGTH(trim(promo_id_03))>=10
    THEN SUBSTR(trim(promo_id_03), 1, 4)
    ELSE trim(promo_id_03)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_03 IS NOT NULL
             UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_01))>=10
    THEN SUBSTR(trim(promo_id_01), 1, 4)
    ELSE trim(promo_id_01)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_01 IS NOT NULL  
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_04))>=10
    THEN SUBSTR(trim(promo_id_04), 1, 4)
    ELSE trim(promo_id_04)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_04 IS NOT NULL         
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_05))>=10
    THEN SUBSTR(trim(promo_id_05), 1, 4)
    ELSE trim(promo_id_05)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_05 IS NOT NULL   
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_06))>=10
    THEN SUBSTR(trim(promo_id_06), 1, 4)
    ELSE trim(promo_id_06)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_06 IS NOT NULL   
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_07))>=10
    THEN SUBSTR(trim(promo_id_07), 1, 4)
    ELSE trim(promo_id_07)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_07 IS NOT NULL   
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_08))>=10
    THEN SUBSTR(trim(promo_id_08), 1, 4)
    ELSE trim(promo_id_08)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_08 IS NOT NULL   
                 UNION
        SELECT ordernum, 
CASE
    WHEN LENGTH(trim(promo_id_09))>=10
    THEN SUBSTR(trim(promo_id_09), 1, 4)
    ELSE trim(promo_id_09)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_09 IS NOT NULL  
                 UNION
        SELECT ordernum,
CASE
    WHEN LENGTH(trim(promo_id_10))>=10
    THEN SUBSTR(trim(promo_id_10), 1, 4)
    ELSE trim(promo_id_10)
  END promo_id
          FROM O5.bi_promo_sale_wrk
         WHERE promo_id_10 IS NOT NULL    
         )
) aa
ON (aa.ordernum=bb.ordernum
and aa.promo_id=bb.promo_id
 )
when matched then 
update set bb.modify_dt = trunc(sysdate)  
when not matched then insert 
(ordernum,promo_id,modify_dt) 
values(aa.ordernum,aa.promo_id,trunc(sysdate) );
commit ;
 
merge into O5.BI_PROMO_SALE bb
using
(SELECT  distinct ordernum,  a.promo_id, a.PROMO_TYPE ,   a.PROMO_TYPE_PRIORITY
          FROM O5.BI_PROMO_TYPE_DCD a , O5.BI_PROMO_SALE c
         WHERE upper(trim(a.promo_id)) = upper(trim(c.promo_id))
         and c.PROMO_TYPE is null
) aa
ON (aa.ordernum=bb.ordernum
and upper(trim(aa.promo_id))=upper(trim(bb.promo_id))
 )
when matched then
update set bb.modify_dt = trunc(sysdate)
           ,bb.PROMO_TYPE  = aa.PROMO_TYPE
           ,bb.PROMO_TYPE_PRIORITY = aa.PROMO_TYPE_PRIORITY
when not matched then insert
(ordernum,promo_id,modify_dt, PROMO_TYPE ,   PROMO_TYPE_PRIORITY)
values(aa.ordernum,aa.promo_id,trunc(sysdate), null, null );
COMMIT;

--Refresh Materialized views

EXEC DBMS_MVIEW.REFRESH ('SDDW.MV_O5_BI_PROMO_SALE','C');
exit;

