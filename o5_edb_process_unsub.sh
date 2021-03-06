#!/usr/bin/ksh
#-----------------------------------------------------------------------
#####   DESCRIPTION  : This script does the following
#####                              1. This script Processes Unsubscribe Requests
#####
#####
#####
#####   CODE HISTORY :                     Name          Date            Description
#####                                   ------------    ----------      ------------
#####                                   Divya Kafle		06/04/2013     		Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export PROCESS='o5_edb_process_unsub'
export LOG=$HOME/LOG
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export BATCHFILE="$LOG/o5_edb_batch_nextval.txt"
export BATCH_NO='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SQL="$HOME/SQL"
############change this connection is test################
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
echo "${PROCESS} started at `date '+%a %b %e %T'`\n" > ${LOG_FILE}
#################################################################
## get next batch number

sqlplus -s -l  <<EOF> ${BATCHFILE}
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
select O5.edb_batch_seq.nextval batch from dual;
quit
EOF

BATCH_NO=`cat ${BATCHFILE}`
cat ${BATCHFILE} >> ${LOG_FILE}

echo "Batch_no is: " $BATCH_NO >> ${LOG_FILE}

rm ${BATCHFILE}

#  Run the sql script that performs update
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${PROCESS}.sql "$BATCH_NO" >> ${LOG_FILE}
EOF
#################################################################
#################################################################
echo "${PROCESS} ended" >> ${LOG_FILE}
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
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit $?
