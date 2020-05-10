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
       SELECT    SAL.ORDER_NO
           || ','
           ||'OFF5TH'
           || ','
           ||trunc(SAL.ORDER_DATE)
           || ','
           || SAL.EMAILID
           || ','
           || SAL.USERNAME
           || ','
           || SAL.USERNAME
           || ','
           || SAL.CONTACT_TIME
           || ','
           || SAL.ENTRY_TYPE
      FROM &1.csr_echo_survey_feed_data  SAL
  		  inner join  &1.email_address EA
             on  UPPER(SAL.emailid) = ea.email_address and opt_in=1
  ORDER BY SAL.ORDER_NO,
           SAL.EMAILID,
           SAL.CONTACT_TIME,
           CSR.USER_NAME;
exit;
