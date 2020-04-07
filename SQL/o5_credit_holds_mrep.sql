REM ######################################################################################
REM                         SAKS Direct
REM ######################################################################################
REM
REM  SCRIPT NAME:  o5_credit_card_holds.sql
REM  DESCRIPTION:  Extract credit card customer transactions for Cognos reporting.
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name                         Date            Description
REM                -----------------            ----------      --------------------------
REM                David Alexander              06/07/2012      Created
REM
REM #####################################################################################
REM #####################################################
REM ## Insert new records into reporting table from clone
REM #####################################################

INSERT
INTO &1.credit_card_holds
  (
    associate,
    dte,
    created_on,
    order_number,
    referral_code,
    Full_Auth_Amt,
    description,
    orv_id,
    NOTES,
    FIRST_NAME,
    LAST_NAME
  )
SELECT associate,
  dte,
  created_on,
  order_number,
  referral_code,
  Full_Auth_Amt,
  description,
  orv_id,
  NOTES,
  FIRST_NAME,
  LAST_NAME
from &1.CREDIT_HOLDS
  WHERE dte > trunc(sysdate)-1;
COMMIT;
quit

