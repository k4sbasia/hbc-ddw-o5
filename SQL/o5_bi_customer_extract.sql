set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
select 
    to_char(bi_customer.CUSTOMER_ID,'9999999999999999')              || '|' ||
    bi_customer.CUSTOMERNUM                                          || '|' ||
    bi_customer.EMPLOYEENBR                                          || '|' || 
    bi_customer.CUSTOMERTYPE                                         || '|' ||
    replace(bi_customer.FIRSTNAME,'|','')                            || '|' ||
    replace(bi_customer.MIDDLENAME,'|','')                           || '|' ||
    replace(bi_customer.LASTNAME,'|','')                             || '|' ||
    replace(bi_customer.HOME_PH,'|','')                              || '|' ||   
    replace(bi_customer.BUS_PH,'|','')                               || '|' ||
    replace(bi_customer.FAX_PH,'|','')                               || '|' ||
    replace(bi_customer.ADDR1,'|','')                                || '|' ||
    replace(bi_customer.ADDR2,'|','')                                || '|' ||
    replace(bi_customer.ADDR3,'|','')                                || '|' ||
    replace(bi_customer.CITY,'|','')                                 || '|' ||
    replace(bi_customer.STATE,'|','')                                || '|' ||
    replace(bi_customer.ZIPCODE,'|','')                              || '|' ||
    bi_customer.COUNTRY                                              || '|' ||
    replace(bi_customer.INTERNETADDRESS,'|','')                      || '|' ||
    to_char(bi_customer.BILL_TO_ADDRESS,'99999999999999999')         || '|' ||
    to_char(bi_customer.SHIP_TO_ADDRESS,'99999999999999999')         || '|' ||
    bi_customer.OPTOUT_IND                                           || '|' ||
    bi_customer.GENDER                                               || '|' ||
    bi_customer.RECEIVEEMAIL                                         || '|' ||
    bi_customer.SAKSFIRSTMEMBER                                      || '|' ||
    bi_customer.SAKSFIRSTNUMBER                                      || '|' ||
    bi_customer.CUSTTITLE                                            || '|' ||
    bi_customer.BIRTHDATE                                            || '|' || 
    bi_customer.ADD_DT                                               || '|' ||
    bi_customer.MODIFY_DT                                            || '|' ||
    bi_customer.FORD_DT                                             
from o5.bi_customer
--where 
--(
--add_dt between trunc(sysdate)-8 
--           and trunc(sysdate)-1 
--)
--or
--(
--modify_dt between trunc(sysdate)-8
--             and trunc(sysdate)-1
--)
;
exit
EOF
