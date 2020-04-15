#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_cheetah_metadata_load.sh
#####
#####   DESCRIPTION  : This script does the following
#####	             1. The scripts loads the o5_email_cheetah_metadata.dat file into staging table using sqlldr
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Divya Kafle			062/04/2012      Created
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
export PROCESS='o5_edb_cheetah_metadata_load'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CONTROL_LOG="$LOG/${PROCESS}.log"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export FILE_NAME="${DATA}/o5_email_cheetah_metadata.dat"
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
echo "${PROCESS} PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
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
echo "${PROCESS} PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}

FILE_COUNT=`wc -l $FILE_NAME | awk '{printf("%s\n", $1)}'`
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Load Data
#################################################################

sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$FILE_NAME  ERRORS=999999 SKIP=1 <<EOT>> $CONTROL_LOG
EOT
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo "${PROCESS} PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ] || [ `egrep -c "^ERROR|ORA-|SP2-0|^553"  ${CONTROL_LOG}` -ne 0 ]
then
if [ `egrep -c "ORA-12899" ${CONTROL_LOG}` -ne 0 ]
then
echo "${PROCESS} completed.There were some bad data\n" >> ${LOG_FILE}
send_email
else
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
fi
else
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
