set pagesize 0
set linesize 200
set echo off
set feedback off
set trimspool on
set serverout on
set heading off

SELECT H.ORDER_NO || ',' ||
  RTRIM(H.ENTERPRISE_KEY)|| ',' ||
  TRUNC(H.ORDER_DATE)|| ',' ||
  B.EMAILID || ',' ||
  N.CREATEUSERID|| ',' ||
  REPLACE(trim(U1.USERNAME),',','-')|| ',' ||
  TO_CHAR (N.contact_time, 'YYYY-MM-DD HH:MI:SS AM')|| ',' ||
  h.ENTRY_TYPE|| ',' ||
  H.EXTN_COMMUNICATION_LANG
FROM OMSPRD.YFS_ORDER_HEADER H
inner join OMSPRD.YFS_NOTES N on  H.ORDER_HEADER_KEY = N.TABLE_KEY
inner join OMSPRD.YFS_PERSON_INFO B on  H.BILL_TO_KEY = B.PERSON_INFO_KEY
inner join OMSPRD.YFS_USER U1 on  trim(u1.loginid)  = trim(n.modifyuserid)
WHERE
H.DOCUMENT_TYPE = '0001'
AND H.ENTERPRISE_KEY IN ('OFF5')
AND H.DRAFT_ORDER_FLAG = 'N'
AND N.note_text is not null
AND reason_code='CUSTOMER_CARE'
and trunc(N.CREATETS) = trunc(sysdate-1)
UNION
SELECT H.ORDER_NO|| ',' ||
  RTRIM(H.ENTERPRISE_KEY) || ',' ||
  TRUNC(H.ORDER_DATE)|| ',' ||
  B.EMAILID || ',' ||
  H.CREATEUSERID|| ',' ||
  REPLACE(NVL(U1.USERNAME,H.EXtn_ASSOCIATE_NAME),',','-')|| ',' ||
  TO_CHAR (N.contact_time, 'YYYY-MM-DD HH:MI:SS AM')|| ',' ||
  h.ENTRY_TYPE|| ',' ||
  H.EXTN_COMMUNICATION_LANG--, U.USERNAME
FROM
OMSPRD.YFS_ORDER_HEADER H
INNER JOIN OMSPRD.YFS_PERSON_INFO B
ON H.BILL_TO_KEY        = B.PERSON_INFO_KEY
LEFT JOIN OMSPRD.YFS_NOTES N
ON (H.ORDER_HEADER_KEY = N.TABLE_KEY
AND TRUNC(N.CREATETS)  = (TRUNC(sysdate-1))
AND N.REASON_CODE      = 'CUSTOMER_CARE')
LEFT JOIN OMSPRD.YFS_USER U1
ON trim(u1.loginid)      = trim(n.modifyuserid)
WHERE H.DOCUMENT_TYPE    = '0001'
AND H.ENTERPRISE_KEY    IN ('OFF5')
AND H.DRAFT_ORDER_FLAG   = 'N'
AND H.ENTRY_TYPE         ='Call Center'
AND trunc(H.ORDER_DATE)       = (TRUNC(sysdate-1))
;


exit;
