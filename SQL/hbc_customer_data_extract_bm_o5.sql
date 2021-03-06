whenever sqlerror exit failure
SET echo OFF
SET feedback OFF
SET linesize 10000
SET pagesize 0
SET sqlprompt ''
SET heading OFF

SELECT 'CUSTOMER_ID|CUSTOMERNUM|EMPLOYEENBR|RECENCY_DATE_TIME|FIRSTNAME|MIDDLENAME|LASTNAME|ADDR1|ADDR2|ADDR3|CITY|STATE|ZIPCODE|ZIP4|COUNTRY|INTERNETADDRESS|OPTOUT_IND|GENDER|RECEIVEEMAIL|RECEIVESMS|EMAIL_PREFERENCES|PREFERRED_LANGUAGE|SAKSFIRSTMEMBER|SAKSFIRSTNUMBER|CUSTTITLE|BIRTHDATE|ADD_DT|MODIFY_DT|REGISTERED_CUSTOMER|SAKS_FIRST_TIER|LOYALTY_NUMBER|BANNER_NBR|ADDRESS_TYPE|ADDRESSACTIVEIND|ADDR_FIRSTNAME|ADDR_LASTNAME|ADDR_MIDDLEINITIAL|ADDR_SUFFIX|ADDR_PREFIX|ADDRESSNICKNAME|ADDR_PHONE|ADDR_PHONE_COUNTRY_CODE_NO|ADDR_PHONE_NO_TYPE_CD|POSTAL_CODE|PHONE_NO|CANADIAN_CUST' FROM DUAL;

SELECT
CUSTOMER_ID || '|' ||
CUSTOMERNUM  || '|' ||
EMPLOYEENBR || '|' ||
RECENCY_DATE_TIME || '|' ||
FIRSTNAME || '|' ||
MIDDLENAME || '|' ||
LASTNAME || '|' ||
ADDR1 || '|' ||
ADDR2 || '|' ||
ADDR3 || '|' ||
CITY || '|' ||
STATE || '|' ||
ZIPCODE || '|' ||
ZIP4 || '|' ||
COUNTRY || '|' ||
INTERNETADDRESS || '|' ||
OPTOUT_IND || '|' ||
GENDER || '|' ||
RECEIVEEMAIL || '|' ||
RECEIVESMS || '|' ||
EMAIL_PREFERENCES || '|' ||
PREFERRED_LANGUAGE || '|' ||
SAKSFIRSTMEMBER || '|' ||
SAKSFIRSTNUMBER || '|' ||
CUSTTITLE || '|' ||
BIRTHDATE || '|' ||
ADD_DT || '|' ||
MODIFY_DT || '|' ||
REGISTERED_CUSTOMER || '|' ||
SAKS_FIRST_TIER || '|' ||
LOYALTY_NUMBER || '|' ||
BANNER_NBR || '|' ||
ADDRESS_TYPE || '|' ||
ADDRESSACTIVEIND || '|' ||
ADDR_FIRSTNAME || '|' ||
ADDR_LASTNAME || '|' ||
ADDR_MIDDLEINITIAL || '|' ||
ADDR_SUFFIX || '|' ||
ADDR_PREFIX || '|' ||
ADDRESSNICKNAME || '|' ||
ADDR_PHONE || '|' ||
ADDR_PHONE_COUNTRY_CODE_NO || '|' ||
ADDR_PHONE_NO_TYPE_CD || '|' ||
POSTAL_CODE || '|' ||
PHONE_NO || '|' ||
CANADIAN_CUST
FROM
(
SELECT DISTINCT u.USA_ID AS CUSTOMER_ID,
        NULL AS CUSTOMERNUM,
        u.USA_EMPLOYEENBR AS EMPLOYEENBR,
        TO_CHAR(u.UCID_MODIFY_DT ,'MM/DD/YYYY hh:mm:ss') AS RECENCY_DATE_TIME,
        REPLACE(TRIM(u.USA_FIRST_NM),'|','') AS FIRSTNAME,
        REPLACE(TRIM(u.USA_MIDDLE_NM),'|','') AS MIDDLENAME,
        REPLACE(TRIM(u.USA_LAST_NM),'|','') AS LASTNAME,
        REPLACE(REPLACE(REPLACE(REPLACE(TRIM(u.USA_PRFRD_ADDR1),CHR(9),' '),CHR(10),' '),CHR(13),' '),'|','') AS ADDR1,
        REPLACE(REPLACE(REPLACE(REPLACE(TRIM(u.USA_PRFRD_ADDR2),CHR(9),' '),CHR(10),' '),CHR(13),' '),'|','') AS ADDR2,
        REPLACE(REPLACE(REPLACE(REPLACE(TRIM(u.USA_PRFRD_ADDR3),CHR(9),' '),CHR(10),' '),CHR(13),' '),'|','') AS ADDR3,
        REPLACE(TRIM(u.USA_PRFRD_CITY),'|','') AS CITY,
        TRIM(u.USA_PRFRD_STATE) AS STATE,
        REPLACE(TRIM(u.USA_PRFRD_ZIPCODE),'|','') AS ZIPCODE,
        NULL AS ZIP4,
        REPLACE(TRIM(u.USA_PRFRD_COUNTRY),'|','') AS COUNTRY,
        REPLACE(TRIM(u.USA_EMAIL),'|','')  AS INTERNETADDRESS,
        DECODE(NVL(m.THE_BAY_OPT_STATUS,'0'),'1','N','0','Y') OPTOUT_IND,
        NVL(USA_GENDER,'') AS GENDER,
        DECODE(NVL(m.THE_BAY_OPT_STATUS,'0'),'1','TRUE','0','FALSE') RECEIVEEMAIL,
        NULL AS RECEIVESMS,
        NULL AS EMAIL_PREFERENCES,
        DECODE(m.LANGUAGE_ID,'en-CA','ENG','en-US','ENG','fr-CA','FRN', NULL) AS PREFERRED_LANGUAGE,
        NULL AS SAKSFIRSTMEMBER,
        NULL AS SAKSFIRSTNUMBER,
        NULL AS CUSTTITLE,
        to_char(USA_DOB,'MM/DD/YYYY') AS BIRTHDATE,
        TO_CHAR(u.UCID_CREATE_DT,'MM/DD/YYYY') AS ADD_DT,
        TO_CHAR(u.UCID_MODIFY_DT,'MM/DD/YYYY') AS MODIFY_DT,
        NVL(u.REGISTERED_CUSTOMER,'N') AS REGISTERED_CUSTOMER,
        NULL AS SAKS_FIRST_TIER,
        MORE_NUMBER AS LOYALTY_NUMBER,
        '7' AS BANNER_NBR,
        USA_PRFRD_ADDR_DEFAULT_TYPE ADDRESS_TYPE,
        USA_PRFRD_ADDR_ACTIVEIND ADDRESSACTIVEIND,
USA_PRFRD_ADDR_FIRST_NAME ADDR_FIRSTNAME,
USA_PRFRD_ADDR_LAST_NAME ADDR_LASTNAME,
USA_PRFRD_ADDR_MIDDLE_NAME ADDR_MIDDLEINITIAL,
USA_PRFRD_ADDR_SUFFIX ADDR_SUFFIX,
USA_PRFRD_ADDR_PREFIX ADDR_PREFIX,
NULL ADDRESSNICKNAME,
USA_PRFRD_ADDR_PHONE_NO ADDR_PHONE,
ADDR_PHONE_COUNTRY_CODE_NO ADDR_PHONE_COUNTRY_CODE_NO,
USA_PRFRD_PHONE_TYPE_CD ADDR_PHONE_NO_TYPE_CD,
USA_PRFRD_ZIPCODE POSTAL_CODE,
REPLACE(TRIM(u.USA_PHONE_NUMBER),'|','') PHONE_NO,
CANADIAN_CUST CANADIAN_CUST
FROM O5.USER_ACCOUNT u
INNER JOIN (SELECT DISTINCT ADD_BY_SOURCE_ID,
                  EMAIL_ADDRESS,
                  TRIM(OPT_IN) THE_BAY_OPT_STATUS,
               LANGUAGE_ID LANGUAGE_ID
          FROM O5.EMAIL_ADDRESS
           WHERE ADD_BY_SOURCE_ID <> '9104'
           AND OPT_IN IS NOT NULL
          ) m
ON ( u.USA_EMAIL = UPPER(TRIM(m.EMAIL_ADDRESS)))
WHERE
 (u.ddw_crt_ts > trunc(sysdate-1) OR u.ddw_mod_ts > trunc(sysdate-1))
 );


SELECT
CUSTOMER_ID || '|' ||
CUSTOMERNUM  || '|' ||
EMPLOYEENBR || '|' ||
RECENCY_DATE_TIME || '|' ||
FIRSTNAME || '|' ||
MIDDLENAME || '|' ||
LASTNAME || '|' ||
ADDR1 || '|' ||
ADDR2 || '|' ||
ADDR3 || '|' ||
CITY || '|' ||
STATE || '|' ||
ZIPCODE || '|' ||
ZIP4 || '|' ||
COUNTRY || '|' ||
INTERNETADDRESS || '|' ||
OPTOUT_IND || '|' ||
GENDER || '|' ||
RECEIVEEMAIL || '|' ||
RECEIVESMS || '|' ||
EMAIL_PREFERENCES || '|' ||
PREFERRED_LANGUAGE || '|' ||
SAKSFIRSTMEMBER || '|' ||
SAKSFIRSTNUMBER || '|' ||
CUSTTITLE || '|' ||
BIRTHDATE || '|' ||
ADD_DT || '|' ||
MODIFY_DT || '|' ||
REGISTERED_CUSTOMER || '|' ||
SAKS_FIRST_TIER || '|' ||
LOYALTY_NUMBER || '|' ||
BANNER_NBR|| '|' ||
ADDRESS_TYPE || '|' ||
ADDRESSACTIVEIND || '|' ||
ADDR_FIRSTNAME || '|' ||
ADDR_LASTNAME || '|' ||
ADDR_MIDDLEINITIAL || '|' ||
ADDR_SUFFIX || '|' ||
ADDR_PREFIX || '|' ||
ADDRESSNICKNAME || '|' ||
ADDR_PHONE || '|' ||
ADDR_PHONE_COUNTRY_CODE_NO || '|' ||
ADDR_PHONE_NO_TYPE_CD || '|' ||
POSTAL_CODE || '|' ||
PHONE_NO || '|' ||
CANADIAN_CUST
FROM
(SELECT DISTINCT '99999999' AS CUSTOMER_ID,
        NULL AS CUSTOMERNUM,
        NULL AS EMPLOYEENBR,
        NULL AS RECENCY_DATE_TIME,
        FIRST_NAME AS FIRSTNAME,
        NULL AS MIDDLENAME,
        LAST_NAME AS LASTNAME,
        NULL AS HOME_PH,
        NULL AS BUS_PH,
        NULL AS FAX_PH,
        NULL AS ADDR1,
        NULL AS ADDR2,
        NULL AS ADDR3,
        NULL AS CITY,
        NULL AS STATE,
        NULL AS ZIPCODE,
        NULL AS ZIP4,
        NULL AS COUNTRY,
        EMAIL_ADDRESS AS INTERNETADDRESS,
        'N' AS OPTOUT_IND,
        NULL AS GENDER,
        'TRUE' AS RECEIVEEMAIL,
        NULL AS RECEIVESMS,
        NULL AS EMAIL_PREFERENCES,
        DECODE(LANGUAGE_ID,'en-CA','ENG','en-US','ENG','fr-CA','FRN', NULL) PREFERRED_LANGUAGE,
        NULL AS SAKSFIRSTMEMBER,
        NULL AS SAKSFIRSTNUMBER,
        NULL AS CUSTTITLE,
        NULL AS BIRTHDATE,
       TO_char(ADD_DT,'MM/DD/YYYY') AS ADD_DT,
        NULL AS MODIFY_DT,
        'N' AS REGISTERED_CUSTOMER,
        NULL AS SAKS_FIRST_TIER,
        NULL AS LOYALTY_NUMBER,
        '7' AS BANNER_NBR,
		 NULL AS ADDRESS_TYPE,
         NULL AS ADDRESSACTIVEIND,
         NULL AS ADDR_FIRSTNAME,
         NULL AS ADDR_LASTNAME,
         NULL AS ADDR_MIDDLEINITIAL,
         NULL AS ADDR_SUFFIX,
         NULL AS ADDR_PREFIX,
         NULL AS ADDRESSNICKNAME,
         NULL AS ADDR_PHONE,
         NULL AS ADDR_PHONE_COUNTRY_CODE_NO,
         NULL AS ADDR_PHONE_NO_TYPE_CD,
         NULL AS POSTAL_CODE,
         NULL AS PHONE_NO,
         NULL AS CANADIAN_CUST
FROM O5.EMAIL_ADDRESS
WHERE ADD_BY_SOURCE_ID = 9184 AND ADD_DT > sysdate-1
);

exit
