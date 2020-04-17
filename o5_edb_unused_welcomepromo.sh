#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_unused_welcomepromo
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This script extracts list of email_addresses that were sent welcomepromo 30 days ago and haven't used it yet
#####                              2. and generates txt file to send to CM
#####
#####
#####
#####   CODE HISTORY :                  Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle	        	07/25/2012      created
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_edb_unused_welcomepromo'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export today=${today:-$(date +%Y%m%d)}
export FILE="o5_used_welcomepromo_${today}.csv"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export BATCH_NO='0'
export CONNBM="O5PROD_MREP"
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo "${PROCESS} started" > ${LOG_FILE}
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${PROCESS}.sql >> ${LOG_FILE}
EOF

echo "starting  spool" >> ${LOG_FILE}
sqlplus -s $CONNECTDW  @${SQL}/${PROCESS}_spool.sql > ${DATA}/${FILE}

echo "Process completed" >> ${LOG_FILE}

#################################################################

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|failed|invalid identifier|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
else
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit $?
