#!/bin/ksh
#-----------------------------------------------------------------------
#####   NAME	     : o5_edb_export_delta.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Daily Export to CheetahMailfor off5th (delta)
#####
#####
#####
#####   CODE HISTORY :                  Name                    Date            Description
#####                                   ------------            ----------      ------------
#####									Sripriya Rao			09/16/2015		Created
#####
#####
#############################################################################################################################
################################################################

. $HOME/params.conf o5
################################################################
##Control File Variables
export PROCESS='o5_edb_export_delta'
export LOG=$HOME/LOG
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SQL="$HOME/SQL"
export SQLSUB="${PROCESS}_sub_spool"

today=${today:-$(date +%Y%m%d)}
sub=o5_subscriber_new_${today}.csv
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^9'|while read group address
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
#################################################################
echo "o5_edb_export_delta started " > ${LOG_FILE}
#################################################################
#  Run the sql script that performs update
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${PROCESS}.sql >>${LOG_FILE}
EOF
echo "sub spool started" >> ${LOG_FILE}
sqlplus -s $CONNECTDW  @${SQL}/${SQLSUB}.sql > ${DATA}/${sub}

echo "o5_edb_export_delta ended" >> ${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_end.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit $?
