REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  o5_prodcust.sql
REM  DESCRIPTION:  This script performs customer load process
REM
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name	               		Date 	       	Description
REM                -----------------	  	----------  	--------------------------
REM                Unknown     		      	Unknown     	Created
REM                Rajesh Mathew		07/13/2010	Modified
REM		   Divya Kafle                  05/21/2012      Modified
REM ############################################################################
set echo on
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
set timing on
---change level 2009:07:01   change dblinks for new production hardware
----change level 2010:01:01 change link to use clone db
DELETE FROM O5.bi_customer_wrk;

INSERT INTO O5.bi_customer_wrk
SELECT   aaa.customer_id, aaa.customernum, aaa.employeenbr,
            aaa.customertype, aaa.firstname, aaa.middlename, aaa.lastname,
            aaa.home_ph, aaa.bus_ph, aaa.fax_ph, aaa.addr1, aaa.addr2,
            aaa.addr3, aaa.city, aaa.state, aaa.zipcode, aaa.country,
            aaa.internetaddress, aaa.bill_to_address, aaa.ship_to_address,
            aaa.optout_ind, null gender,null receiveemail, null saksfirstmember, null saksfirstnumber, null title,null birthdate,
            SYSDATE, NULL, aaa.registered_customer
       FROM (SELECT   usa.usa_id customer_id,
                      NULL as CUSTOMERNUM,
                      usa.USA_EMPLOYEENBR employeenbr,
                      'B2C' customertype,
                      usa.usa_first_nm firstname,
                      usa.usa_middle_nm middlename, usa.usa_last_nm lastname,
                      NVL (usa.USA_PRFRD_ADDR_PHONE_NO,  usa.USA_PHONE_NUMBER)  home_ph,
                      NULL as  bus_ph, NULL as  fax_ph,
                      NVL (usa.USA_PRFRD_ADDR1, '')  addr1,
                      NVL (usa.USA_PRFRD_ADDR2, '')  addr2,
                      NVL (usa.USA_PRFRD_ADDR3, '') addr3,
                      NVL (usa.USA_PRFRD_CITY, '')  city,
                      NVL (usa.USA_PRFRD_STATE, '') state,
                      NVL (usa.USA_PRFRD_ZIPCODE, '')  zipcode,
                      NVL (usa.USA_PRFRD_COUNTRY, '') country,
                      usa.usa_email internetaddress,
                      NULL bill_to_address,
                      NULL ship_to_address,
                      usa.EMAIL_OPT_IND optout_ind,
                      'Y' registered_customer
                 FROM o5.user_account usa
                WHERE   DDW_CRT_TS > trunc(sysdate -3) OR DDW_MOD_TS > trunc(sysdate -3)                --  Fix 3/2009
) aaa
;


COMMIT;


MERGE INTO O5.bi_customer hst
   USING (SELECT *
            FROM O5.bi_customer_wrk) trn
   ON (trn.customer_id = hst.customer_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.customernum = trn.customernum,
             hst.employeenbr = trn.employeenbr,
             hst.customertype = trn.customertype,
             hst.firstname = trn.firstname, hst.middlename = trn.middlename,
             hst.lastname = trn.lastname, hst.home_ph = trn.home_ph,
             hst.bus_ph = trn.bus_ph, hst.fax_ph = trn.fax_ph,
             hst.addr1 = trn.addr1, hst.addr2 = trn.addr2,
             hst.addr3 = trn.addr3, hst.city = trn.city,
             hst.state = trn.state, hst.zipcode = trn.zipcode,
             hst.country = trn.country,
             hst.internetaddress = trn.internetaddress,
             hst.bill_to_address = trn.bill_to_address,
             hst.ship_to_address = trn.ship_to_address,
             hst.optout_ind = trn.optout_ind, hst.gender = trn.gender,
             hst.receiveemail = trn.receiveemail,
             hst.saksfirstmember = trn.saksfirstmember,
             hst.saksfirstnumber = trn.saksfirstnumber,
             hst.custtitle = trn.custtitle, hst.birthdate = trn.birthdate,
             hst.modify_dt = SYSDATE,
             hst.registered_customer = trn.registered_customer
   WHEN NOT MATCHED THEN
      INSERT (customer_id, customernum, employeenbr, customertype, firstname,
              middlename, lastname, home_ph, bus_ph, fax_ph, addr1, addr2,
              addr3, city, state, zipcode, country, internetaddress,
              bill_to_address, ship_to_address, optout_ind, gender,
              receiveemail, saksfirstmember, saksfirstnumber, custtitle,
              birthdate, add_dt, registered_customer, p_code)
      VALUES (trn.customer_id, trn.customernum, trn.employeenbr,
              trn.customertype, trn.firstname, trn.middlename, trn.lastname,
              trn.home_ph, trn.bus_ph, trn.fax_ph, trn.addr1, trn.addr2,
              trn.addr3, trn.city, trn.state, trn.zipcode, trn.country,
              trn.internetaddress, trn.bill_to_address, trn.ship_to_address,
              trn.optout_ind, trn.gender, trn.receiveemail,
              trn.saksfirstmember, trn.saksfirstnumber, trn.custtitle,
              trn.birthdate, SYSDATE, trn.registered_customer, NULL);
COMMIT ;


DELETE FROM O5.bi_customer_wrk;

INSERT INTO O5.bi_customer_wrk
SELECT   aaa.customer_id, aaa.customernum, aaa.employeenbr,
            aaa.customertype, aaa.firstname, aaa.middlename, aaa.lastname,
            aaa.home_ph, aaa.bus_ph, aaa.fax_ph, aaa.addr1, aaa.addr2,
            aaa.addr3, aaa.city, aaa.state, aaa.zipcode, aaa.country,
            aaa.internetaddress, aaa.bill_to_address, aaa.ship_to_address,
            aaa.optout_ind, null gender,null receiveemail, null saksfirstmember, null saksfirstnumber, null title,null birthdate,
            SYSDATE, NULL, aaa.registered_customer
       FROM (
select distinct oi.BILL_TO_CUSTOMER_UID CUSTOMER_ID,NULL as CUSTOMERNUM ,NULL as employeenbr,
                      'B2C' customertype,oi.BILL_TO_FIRST_NAME FIRSTNAME,NULL AS middlename,oi.BILL_TO_LAST_NAME LASTNAME, NVL(oi.BILL_TO_CELL,oi.BILL_TO_PHONE) home_ph,      NULL as  bus_ph, NULL as  fax_ph
                      ,substr(oi.BILL_TO_ADDRESS,1,80) addr1, substr(oi.BILL_TO_ADDRESS,81,80) addr2,substr(oi.BILL_TO_ADDRESS,161,80) addr3
                      ,oi.BILL_TO_CITY city, oi.BILL_TO_STATE state, oi.BILL_TO_ZIP_CODE zipcode,oi.BILL_TO_COUNTRY country, oi.EMAIL_ADDRESS internetaddress,NULL bill_to_address,
                      NULL ship_to_address,
                      NULL optout_ind,
                      'N' registered_customer  from o5.oms_o5_order_info oi, o5.user_account ua
where UPPER(oi.EMAIL_ADDRESS)= ua.USA_EMAIL(+)
and ua.usa_email is null
and oi.ORDER_DATE > trunc(sysdate-2)
) aaa;

MERGE INTO O5.bi_customer hst
   USING (SELECT *
            FROM O5.bi_customer_wrk) trn
   ON (trn.customer_id = hst.customer_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.customernum = trn.customernum,
             hst.employeenbr = trn.employeenbr,
             hst.customertype = trn.customertype,
             hst.firstname = trn.firstname, hst.middlename = trn.middlename,
             hst.lastname = trn.lastname, hst.home_ph = trn.home_ph,
             hst.bus_ph = trn.bus_ph, hst.fax_ph = trn.fax_ph,
             hst.addr1 = trn.addr1, hst.addr2 = trn.addr2,
             hst.addr3 = trn.addr3, hst.city = trn.city,
             hst.state = trn.state, hst.zipcode = trn.zipcode,
             hst.country = trn.country,
             hst.internetaddress = trn.internetaddress,
             hst.bill_to_address = trn.bill_to_address,
             hst.ship_to_address = trn.ship_to_address,
             hst.optout_ind = trn.optout_ind, hst.gender = trn.gender,
             hst.receiveemail = trn.receiveemail,
             hst.saksfirstmember = trn.saksfirstmember,
             hst.saksfirstnumber = trn.saksfirstnumber,
             hst.custtitle = trn.custtitle, hst.birthdate = trn.birthdate,
             hst.modify_dt = SYSDATE,
             hst.registered_customer = trn.registered_customer
   WHEN NOT MATCHED THEN
      INSERT (customer_id, customernum, employeenbr, customertype, firstname,
              middlename, lastname, home_ph, bus_ph, fax_ph, addr1, addr2,
              addr3, city, state, zipcode, country, internetaddress,
              bill_to_address, ship_to_address, optout_ind, gender,
              receiveemail, saksfirstmember, saksfirstnumber, custtitle,
              birthdate, add_dt, registered_customer, p_code)
      VALUES (trn.customer_id, trn.customernum, trn.employeenbr,
              trn.customertype, trn.firstname, trn.middlename, trn.lastname,
              trn.home_ph, trn.bus_ph, trn.fax_ph, trn.addr1, trn.addr2,
              trn.addr3, trn.city, trn.state, trn.zipcode, trn.country,
              trn.internetaddress, trn.bill_to_address, trn.ship_to_address,
              trn.optout_ind, trn.gender, trn.receiveemail,
              trn.saksfirstmember, trn.saksfirstnumber, trn.custtitle,
              trn.birthdate, SYSDATE, trn.registered_customer, NULL);
COMMIT ;

MERGE INTO O5.bi_customer hst
   USING (SELECT  b.createfor customer_id, MAX (TRUNC (b.orderdate)) mxlord_dt, MIN (TRUNC (b.orderdate)) miford_dt
                     FROM O5.bi_sale b
                     where TRUNC (orderdate) = TRUNC (SYSDATE - 1)
                     GROUP BY createfor) trn
   ON (trn.customer_id = hst.customer_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.lord_dt = trn.mxlord_dt,
            hst.ford_dt=trn.miford_dt
         ;

commit;


MERGE INTO O5.bi_customer hst
   USING (SELECT a.customer_id, a.individual_id, a.household_id
            FROM O5.bi_cust_xref a, O5.bi_customer b
           WHERE a.customer_id = b.customer_id
             AND (   a.individual_id <> b.individual_id
                  OR a.household_id <> b.household_id
                  OR b.individual_id IS NULL
                  OR b.household_id IS NULL
                 )) trn
   ON (trn.customer_id = hst.customer_id)
   WHEN MATCHED THEN
      UPDATE
         SET hst.individual_id = trn.individual_id,
             hst.household_id = trn.household_id, hst.modify_dt = SYSDATE
   WHEN NOT MATCHED THEN
	INSERT (hst.customer_id, hst.individual_id, hst.household_id)
	VALUES (trn.customer_id, trn.individual_id, trn.household_id);
COMMIT ;

merge INTO o5.bi_customer trg USING
(SELECT  createfor,
  max(more_number) more_number
FROM o5.bi_sale
WHERE TRUNC(add_dt)      =TRUNC(sysdate)
AND more_number         IS NOT NULL group by createfor
) src ON (trg.customer_id=src.createfor)
WHEN matched THEN
  UPDATE SET trg.more_number=src.more_number
  ;
commit;
