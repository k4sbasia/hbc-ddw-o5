#!/bin/bash
#############################################################################################################################
#####                           SAKS Direct
#############################################################################################################################
#####
#####   DESCRIPTION  :Customer Accounts Updates
#####
#####
#####
#####   CODE HISTORY :  Name            Date            Description
#####               ------------       ----------      ------------
#####           Jayanthi       2020      Customer Accounts Updates
#####
#############################################################################################################################
export BANNER=$BANNER
. $HOME/params.conf o5
if [ "${BANNER}" == "" ];
then
export BANNER=$2
fi
export BANNER="o5"
################################################################
##Control File Variables
################################################################
#export BANNER=$1
################################################################
export PROCESS="user_account_address_updates"
export SQL=$HOME/SQL
export CTL=$HOME/CTL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export BAD_SUBJECT="${PROCESS} in ${BANNER} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="$SQL/${PROCESS}.sql"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export EDATA_EXCHANGE_SCHEMA="EDATA_EXCHANGE."
################################################################
##Staging the customer data from ucid table to history table
#################################################################
echo "START Customer backup data  for $BANNER `date +%Y%m%d` "  > ${LOG_FILE}
sqlplus -S $CONNECTDW<<EOF
delete from ${DW_USER}CUSTOMER_PROFILE_STAGE_HISTORY
where trunc(CREATE_DT) = trunc(sysdate);
commit;
insert into ${DW_USER}CUSTOMER_PROFILE_STAGE_HISTORY select * from ${EDATA_EXCHANGE_SCHEMA}CUSTOMER_PROFILE_STAGE_O5_S5A;
commit;
quit;
EOF
################################################################
################################################################
echo "START Customer updates  for $BANNER `date +%Y%m%d` "  >> ${LOG_FILE}
sqlplus -S $CONNECTUSER @${SCRIPT_NAME} "${BANNER}" "${EDATA_EXCHANGE_SCHEMA}" "${SCHEMA}">>${LOG_FILE}
echo "END Customer updates for $BANNER `date +%Y%m%d` "  >> ${LOG_FILE}
################################################################
##Bad Records Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
else
echo "${PROCESS} completed without errors."
sqlplus -S $CONNECTDW<<EOF
TRUNCATE TABLE ${EDATA_EXCHANGE_SCHEMA}CUSTOMER_PROFILE_STAGE_O5_S5A;
quit;
EOF
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
