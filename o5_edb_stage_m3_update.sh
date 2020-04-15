#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_stage_m3_update.sh
#####
#####   DESCRIPTION  : This script does the following
#####	             1.Updates email_address based om m3 data
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Divya Kafle			11/23/2013      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_edb_stage_m3_update'
export CONTROL_FILE="${CTL}/${PROCESS}.ctl"
export CONTROL_LOG="${LOG}/${PROCESS}.log"
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_FILE="${DATA}/${PROCESS}.bad"
export today=${today:-$(date +%Y%m%d)}
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0

########################################################################
echo "${PROCESS} PROCESS started " >${LOG_FILE}
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
echo "${PROCESS} PROCESS started" > ${LOG_FILE}

sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
sqlplus -s $CONNECTDW  @${SQL}/${PROCESS}.sql >>${LOG_FILE}
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo "${PROCESS} PROCESS ended " >> ${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
#send_email
exit 99
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit $?
