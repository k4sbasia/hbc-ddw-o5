#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_cheetah_demo.sh
#####
#####   DESCRIPTION  : This script does the following
#####		     1. Calls the O5.P_email_optdown for Starting insert from staging table to O5.email_optdwon
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Divya Kafle          06/04/2013      Created
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_edb_cheetah_demo'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_log.txt"
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
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE} ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
function send_email2 {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat "${LOG_FILE}"|mailx -s "${SUBJECT}" $address
 done
}
#################################################################

LOAD_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*)
from O5.email_optdown_wrk wrk
where wrk.frequency_cap IS NOT NULL
AND wrk.frequency_cap <> '0';
quit;
EOF`

echo "The load record count is : $LOAD_COUNT" >${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
echo "${PROCESS} Process started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#########################################################################
#  Run the sql script that performs the product info extract
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF
exec O5.P_email_optdown;
exit;
EOF
#################################################################
# Get the COUNT from the table
#################################################################
TARGET_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*)
from O5.email_optdown
where load_dt >= trunc(sysdate);
quit;
EOF`
echo "The Source record count is : $LOAD_COUNT" >> ${LOG_FILE}
echo "The Target record count is : $TARGET_COUNT" >> ${LOG_FILE}
echo "Starting the mv refresh `date '+%a %b %e %T'`" >> ${LOG_FILE}
sqlplus -s -l  $CONNECTDW <<EOF
exec DBMS_MVIEW.REFRESH('sddw.mv_o5_email_optdown','c', ATOMIC_REFRESH => false);
show errors;
exit;
EOF
echo "End of mv refresh `date '+%a %b %e %T'`" >> ${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "${PROCESS} Process ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#########################################################################
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
export SUBJECT="${PROCESS} completed without errors."
#send_email2
fi
exit $?
