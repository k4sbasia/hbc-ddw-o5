SET echo on
SET feedback on
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF
SET trimspool ON
set timing on
--***********************************************************
--***********************************************************
DECLARE
  I             INTEGER := 0;
  l_error_count NUMBER;
  l_error_msg   VARCHAR2(2000);
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  LASTPROCESEDDATE DATE := SYSDATE;
  CURSOR C1
  IS
    SELECT
    cp.*,a.usa_email
    FROM &2.CUSTOMER_PROFILE_STAGE_O5_S5A CP
    left join &3.user_account a on  upper(CP.EMAIL_ADDRESS) = a.usa_email
    WHERE CP.EMAIL_ADDRESS    IS NOT NULL
  and cp.banner_id = 8
    ;
TYPE CUST_REC_TYPE
IS
  TABLE OF C1%rowtype;
  v_coll_CUST_REC_TYPE CUST_REC_TYPE;
BEGIN
  OPEN c1;
  LOOP
     begin
                FETCH c1 BULK COLLECT
                INTO v_coll_CUST_REC_TYPE limit 10000;
                FORALL indx IN 1..v_coll_CUST_REC_TYPE.COUNT SAVE EXCEPTIONS

                MERGE INTO &3.USER_ACCOUNT UA USING
                (SELECT v_coll_CUST_REC_TYPE(indx).CUSTOMER_ID CUSTOMER_ID,
                  v_coll_CUST_REC_TYPE(indx).SOURCE_CD SOURCE_CD,
                  v_coll_CUST_REC_TYPE(indx).EMPLOYEENBR EMPLOYEENBR,
                  v_coll_CUST_REC_TYPE(indx).CUSTOMERTYPE CUSTOMERTYPE ,
                  v_coll_CUST_REC_TYPE(indx).RECENCY_DATE_TIME RECENCY_DATE_TIME,
                  v_coll_CUST_REC_TYPE(indx).PREFIX PREFIX,
                  v_coll_CUST_REC_TYPE(indx).EMAIL_OPT_IND EMAIL_OPT_IND,
                  v_coll_CUST_REC_TYPE(indx).FIRSTNAME FIRSTNAME,
                  v_coll_CUST_REC_TYPE(indx).MIDDLENAME MIDDLENAME,
                  v_coll_CUST_REC_TYPE(indx).LASTNAME LASTNAME,
                  upper(v_coll_CUST_REC_TYPE(indx).EMAIL_ADDRESS) EMAIL_ADDRESS,
                  v_coll_CUST_REC_TYPE(indx).GENDER GENDER,
                  v_coll_CUST_REC_TYPE(indx).DOB DOB,
                  v_coll_CUST_REC_TYPE(indx).PHONE_NUMBER PHONE_NUMBER,
                  v_coll_CUST_REC_TYPE(indx).PREFERRRED_LANGUAGE PREFERRRED_LANGUAGE,
                  v_coll_CUST_REC_TYPE(indx).REGISTERED_CUSTOMER REGISTERED_CUSTOMER,
                  v_coll_CUST_REC_TYPE(indx).MORE_NUMBER MORE_NUMBER,
                  v_coll_CUST_REC_TYPE(indx).BANNER_ID BANNER_ID ,
                  v_coll_CUST_REC_TYPE(indx).CANADIAN_CUST CANADIAN_CUST,
                  v_coll_CUST_REC_TYPE(indx).CREATE_DT CREATE_DT,
                  v_coll_CUST_REC_TYPE(indx).MODIFY_DT MODIFY_DT
                FROM DUAL where v_coll_CUST_REC_TYPE(indx).USA_EMAIL is NULL
                ) CP ON (upper(UA.USA_EMAIL) = CP.EMAIL_ADDRESS AND UA.USA_ID = CP.CUSTOMER_ID)
				  WHEN NOT MATCHED THEN
                INSERT
                  (
                    USA_ID,
                    USA_SOURCE_CD,
                    USA_EMPLOYEENBR,
                    USA_CUSTOMER_TYPE,
                    RECENCY_DATE_TIME,
                    USA_PREFIX,
                    EMAIL_OPT_IND,
                    USA_FIRST_NM,
                    USA_MIDDLE_NM,
                    USA_LAST_NM,
                    USA_EMAIL,
                    USA_GENDER,
                    USA_DOB,
                    USA_PHONE_NUMBER,
                    PREFERRRED_LANGUAGE,
                    REGISTERED_CUSTOMER,
                    MORE_NUMBER,
                    BANNER_ID,
                    CANADIAN_CUST,
                    UCID_MODIFY_DT,
                    UCID_CREATE_DT,
                    DDW_CRT_TS
                  )
                  VALUES
                  (
                    CP.CUSTOMER_ID,
                    CP.SOURCE_CD,
                    CP.EMPLOYEENBR,
                    CP.CUSTOMERTYPE,
                    CP.RECENCY_DATE_TIME,
                    CP.PREFIX,
                    CP.EMAIL_OPT_IND,
                    CP.FIRSTNAME,
                    CP.MIDDLENAME,
                    CP.LASTNAME,
                    UPPER(CP.EMAIL_ADDRESS),
                    CP.GENDER,
                    CP.DOB,
                    CP.PHONE_NUMBER,
                    CP.PREFERRRED_LANGUAGE,
                    CP.REGISTERED_CUSTOMER,
                    CP.MORE_NUMBER,
                    CP.BANNER_ID,
                    CP.CANADIAN_CUST,
                    CP.MODIFY_DT,
                    CP.CREATE_DT - 6/24,
                    SYSDATE
                  );
                COMMIT;
                 EXCEPTION WHEN ex_dml_errors THEN
                  l_error_count := SQL%BULK_EXCEPTIONS.count;
                  FOR i IN 1 .. l_error_count
                  LOOP
                    l_error_msg := SQLERRM
                    (
                      -SQL%BULK_EXCEPTIONS(i).ERROR_CODE
                    )
                    ;
                    dbms_output.put_line('Error #' || i || ' at '|| 'iteration  #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
                    dbms_output.put_line('Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                    INSERT
                    INTO USER_ACCOUNT_EXCEPTION
                      (
                        USA_EMAIL,
                        --USA_ID
                        ERROR_CNT,
                        error_msg,
                        exception_dt
                      )
                      VALUES
                      (
                        v_coll_CUST_REC_TYPE(i).EMAIL_ADDRESS,
                        --SELECTION(i).CUSTOMER_ID,
                        l_error_count,
                        l_error_msg|| ' into USER_ACCOUNT',
                        LASTPROCESEDDATE
                      );
                    COMMIT;
                       EXIT
                  WHEN C1%NOTFOUND;
                 end loop;
			 raise;
       end;
    FORALL indx IN 1..v_coll_CUST_REC_TYPE.COUNT SAVE EXCEPTIONS MERGE INTO &3.USER_ADDRESS UA USING
    (SELECT upper(v_coll_CUST_REC_TYPE(indx).EMAIL_ADDRESS) EMAIL_ADDRESS,
        v_coll_CUST_REC_TYPE(indx).CUSTOMER_ID CUSTOMER_ID,
        v_coll_CUST_REC_TYPE(indx).ADDR1 ADDR1,
        v_coll_CUST_REC_TYPE(indx).ADDR2 ADDR2,
        v_coll_CUST_REC_TYPE(indx).ADDR3 ADDR3,
        v_coll_CUST_REC_TYPE(indx).CITY CITY,
        v_coll_CUST_REC_TYPE(indx).STATE STATE,
        v_coll_CUST_REC_TYPE(indx).ZIPCODE ZIPCODE,
        v_coll_CUST_REC_TYPE(indx).ZIP4 ZIP4 ,
        v_coll_CUST_REC_TYPE(indx).COUNTRY COUNTRY,
        v_coll_CUST_REC_TYPE(indx).ADDRESS_TYPE ADDRESS_TYPE ,
        v_coll_CUST_REC_TYPE(indx).ADDRESS_PRIORITY_TYPE_CD ADDRESS_PRIORITY_TYPE_CD,
        v_coll_CUST_REC_TYPE(indx).CREATE_DT CREATE_DT,
        v_coll_CUST_REC_TYPE(indx).MODIFY_DT MODIFY_DT,
        v_coll_CUST_REC_TYPE(indx).ADDRESS_OPT_IND ADDRESS_OPT_IND,
        v_coll_CUST_REC_TYPE(indx).ADDR_FIRST_NAME ADDR_FIRST_NAME,
       v_coll_CUST_REC_TYPE(indx).ADDR_LAST_NAME ADDR_LAST_NAME,
       v_coll_CUST_REC_TYPE(indx).ADDR_PREFIX ADDR_PREFIX,
      v_coll_CUST_REC_TYPE(indx).ADDR_DEFAULT_TYPE ADDR_DEFAULT_TYPE,
      v_coll_CUST_REC_TYPE(indx).ADDR_MIDDLE_NAME ADDR_MIDDLE_NAME,
      v_coll_CUST_REC_TYPE(indx).ADDR_SUFFIX ADDR_SUFFIX,
      v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_NO ADDR_PHONE_NO,
      v_coll_CUST_REC_TYPE(indx).ADDR_EXTERNAL_ID ADDR_EXTERNAL_ID,
      v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_COUNTRY_CODE_NO ADDR_PHONE_COUNTRY_CODE_NO,
      v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_NO_TYPE_CD ADDR_PHONE_NO_TYPE_CD
      FROM DUAL
      where (v_coll_CUST_REC_TYPE(indx).ZIPCODE is not null
        or v_coll_CUST_REC_TYPE(indx).ZIP4 is not null)
    )
    CP ON (UA.USA_EMAIL = CP.EMAIL_ADDRESS AND NVL(UA.USA_ZIPCODE,'00000') = NVL(CP.ZIPCODE,'00000') AND NVL(UA.USA_ZIP4,'00000') = NVL(CP.ZIP4,'00000')
    )
  WHEN MATCHED THEN
    UPDATE
    SET USA_ADDR1             =CP.ADDR1,
      USA_ADDR2               =CP.ADDR2,
      USA_ADDR3               =CP.ADDR3,
      USA_CITY                =CP.CITY,
      USA_STATE               =CP.STATE,
      USA_COUNTRY             =CP.COUNTRY,
      ADDRESS_PRIORITY_TYPE_CD=CP.ADDRESS_PRIORITY_TYPE_CD,
      UCID_MODIFY_DT          = CP.MODIFY_DT,
      UCID_CREATE_DT          =CP.CREATE_DT - 6/24,
     ADDRESS_OPT_IND         = CP.ADDRESS_OPT_IND,
      ADDR_FIRST_NAME         = CP.ADDR_FIRST_NAME,
      ADDR_LAST_NAME          =CP.ADDR_LAST_NAME,
      ADDR_PREFIX          =CP.ADDR_PREFIX,
      ADDR_DEFAULT_TYPE          =CP.ADDR_DEFAULT_TYPE,
      USA_ID                   =CP.CUSTOMER_ID,
      ADDR_MIDDLE_NAME          =CP.ADDR_MIDDLE_NAME,
      ADDR_SUFFIX          =CP.ADDR_SUFFIX,
      ADDR_PHONE_NO          =CP.ADDR_PHONE_NO,
      ADDR_EXTERNAL_ID          =CP.ADDR_EXTERNAL_ID,
      ADDR_PHONE_COUNTRY_CODE_NO          =CP.ADDR_PHONE_COUNTRY_CODE_NO,
      ADDR_PHONE_NO_TYPE_CD          =CP.ADDR_PHONE_NO_TYPE_CD,
      DDW_MOD_TS              =SYSDATE
      WHEN NOT MATCHED THEN
    INSERT
      (
        USA_EMAIL,
        USA_ID,
        USA_ADDR1,
        USA_ADDR2,
        USA_ADDR3,
        USA_CITY,
        USA_STATE,
        USA_ZIPCODE,
        USA_COUNTRY,
        USA_ZIP4,
        ADDRESS_TYPE,
        ADDRESS_PRIORITY_TYPE_CD,
        UCID_MODIFY_DT,
        UCID_CREATE_DT,
        ADDRESS_OPT_IND ,
        ADDR_FIRST_NAME,
        ADDR_LAST_NAME,
       ADDR_PREFIX,
      ADDR_DEFAULT_TYPE,
      ADDR_MIDDLE_NAME,
      ADDR_SUFFIX,
      ADDR_PHONE_NO,
      ADDR_EXTERNAL_ID,
      ADDR_PHONE_COUNTRY_CODE_NO,
      ADDR_PHONE_NO_TYPE_CD,
      DDW_CRT_TS
      )
      VALUES
      (
        CP.EMAIL_ADDRESS,
        CP.CUSTOMER_ID,
        CP.ADDR1,
        CP.ADDR2,
        CP.ADDR3,
        CP.CITY,
        CP.STATE,
        CP.ZIPCODE,
        CP.COUNTRY,
        CP.ZIP4,
        CP.ADDRESS_TYPE,
        CP.ADDRESS_PRIORITY_TYPE_CD,
        CP.MODIFY_DT,
        CP.CREATE_DT - 6/24,
        CP.ADDRESS_OPT_IND,
       CP.ADDR_FIRST_NAME,
       CP.ADDR_LAST_NAME,
       CP.ADDR_PREFIX,
       CP.ADDR_DEFAULT_TYPE,
       CP.ADDR_MIDDLE_NAME,
       CP.ADDR_SUFFIX,
       CP.ADDR_PHONE_NO,
       CP.ADDR_EXTERNAL_ID,
       CP.ADDR_PHONE_COUNTRY_CODE_NO,
       CP.ADDR_PHONE_NO_TYPE_CD,
       SYSDATE--,CP.ADDR1,CP.ADDR2,CP.ADDR3,CP.CITY,CP.STATE,CP.ZIPCODE,CP.COUNTRY
      );
COMMIT;
    EXIT
  WHEN C1%NOTFOUND;
  END LOOP;
  COMMIT;
  CLOSE c1;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := SQL%BULK_EXCEPTIONS.count;
  FOR i IN 1 .. l_error_count
  LOOP
    l_error_msg := SQLERRM
    (
      -SQL%BULK_EXCEPTIONS(i).ERROR_CODE
    )
    ;
    dbms_output.put_line('Error #' || i || ' at '|| 'iteration  #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
    dbms_output.put_line('Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    INSERT
    INTO USER_ACCOUNT_EXCEPTION
      (
        USA_EMAIL,
        --USA_ID
        ERROR_CNT,
        error_msg,
        exception_dt
      )
      VALUES
      (
        v_coll_CUST_REC_TYPE(i).EMAIL_ADDRESS,
        --SELECTION(i).CUSTOMER_ID,
        l_error_count,
        l_error_msg || ' into USER_ADDRESS',
        LASTPROCESEDDATE
      );
    COMMIT;
  END LOOP;
  CLOSE c1;
  raise;
end;
/

  declare
   I           INTEGER := 0;
   l_error_count  NUMBER;
  l_error_msg varchar2(2000);
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  LASTPROCESEDDATE DATE := SYSDATE;

  CURSOR C1 IS
SELECT
       *
  FROM &2.CUSTOMER_PROFILE_STAGE_O5_S5A CP
  WHERE CP.EMAIL_ADDRESS IS NOT NULL
  and addr_default_type = 'Y'
  and CP.ADDRESS_OPT_IND = 'A'
  and cp.banner_id = 4;
  TYPE CUST_REC_TYPE IS
        TABLE OF C1%rowtype;
         v_coll_CUST_REC_TYPE   CUST_REC_TYPE;

 BEGIN
    OPEN c1;
    LOOP
    FETCH c1  BULK COLLECT INTO v_coll_CUST_REC_TYPE limit 10000;


       FORALL indx IN 1..v_coll_CUST_REC_TYPE.COUNT SAVE EXCEPTIONS
    UPDATE &3.USER_ACCOUNT  UA
    SET USA_PRFRD_ADDR1=v_coll_CUST_REC_TYPE(indx).ADDR1,
    USA_PRFRD_ADDR2=v_coll_CUST_REC_TYPE(indx).ADDR2,
    USA_PRFRD_ADDR3=v_coll_CUST_REC_TYPE(indx).ADDR3,
    USA_PRFRD_CITY=v_coll_CUST_REC_TYPE(indx).CITY,
    USA_PRFRD_STATE=v_coll_CUST_REC_TYPE(indx).STATE,
    USA_PRFRD_COUNTRY=v_coll_CUST_REC_TYPE(indx).COUNTRY,
    USA_PRFRD_ZIPCODE=v_coll_CUST_REC_TYPE(indx).ZIPCODE,
    USA_PRFRD_ZIP4=v_coll_CUST_REC_TYPE(indx).ZIP4,
    UCID_MODIFY_DT = v_coll_CUST_REC_TYPE(indx).MODIFY_DT,
    UCID_CREATE_DT=v_coll_CUST_REC_TYPE(indx).CREATE_DT,
    USA_PRFRD_ADDR_FIRST_NAME=v_coll_CUST_REC_TYPE(indx).ADDR_FIRST_NAME,
USA_PRFRD_ADDR_LAST_NAME=v_coll_CUST_REC_TYPE(indx).ADDR_LAST_NAME,
USA_PRFRD_ADDR_PREFIX=v_coll_CUST_REC_TYPE(indx).ADDR_PREFIX,
USA_PRFRD_ADDR_DEFAULT_TYPE=v_coll_CUST_REC_TYPE(indx).ADDRESS_TYPE,
USA_PRFRD_ADDR_MIDDLE_NAME=v_coll_CUST_REC_TYPE(indx).ADDR_MIDDLE_NAME,
USA_PRFRD_ADDR_SUFFIX=v_coll_CUST_REC_TYPE(indx).ADDR_SUFFIX,
USA_PRFRD_ADDR_PHONE_NO=v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_NO,
USA_PRFRD_ADDR_EXTERNAL_ID=v_coll_CUST_REC_TYPE(indx).ADDR_EXTERNAL_ID,
ADDR_PHONE_COUNTRY_CODE_NO=v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_COUNTRY_CODE_NO,
USA_PRFRD_PHONE_TYPE_CD=v_coll_CUST_REC_TYPE(indx).ADDR_PHONE_NO_TYPE_CD,
USA_PRFRD_ADDR_ACTIVEIND=v_coll_CUST_REC_TYPE(indx).ADDRESS_OPT_IND,
DDW_MOD_TS=SYSDATE
  WHERE UA.USA_EMAIL = upper(v_coll_CUST_REC_TYPE(indx).EMAIL_ADDRESS);
       COMMIT;
       EXIT WHEN C1%NOTFOUND;

         END LOOP;
COMMIT;
CLOSE c1;
EXCEPTION
    WHEN ex_dml_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      FOR i IN 1 .. l_error_count LOOP
      l_error_msg := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
      dbms_output.put_line('Error #' || i || ' at '|| 'iteration
      #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Error message is ' ||
      SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      INSERT INTO  USER_ACCOUNT_EXCEPTION
                     (
                     USA_EMAIL,
                     --USA_ID
                     ERROR_CNT, error_msg, exception_dt
                     )
              VALUES (
              v_coll_CUST_REC_TYPE(i).EMAIL_ADDRESS,
              --SELECTION(i).CUSTOMER_ID,
              l_error_count,l_error_msg || 'While updating default address',LASTPROCESEDDATE
                     );
                     COMMIT;
   END LOOP;
   CLOSE c1;
END ;
/

exit;
