#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : feed_echosurvey_extract.sh 
#####
#####   DESCRIPTION  : This script does the following
#####                              1. The script calls the feed_echosurvey_extract.sql which produces the product feed to echosurvey.com.
#####
#####
#####   CODE HISTORY :                   Name                     Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Jayanthi Dudala              08/19/2011      Created
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
export PROCESS='o5_feed_echosurvey_extract'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export FILE_NAME="$DATA/off5th_data_extract_`date +%m%d%Y`.csv"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
export TARGET_COUNT=0
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
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
echo "Started extracting data at `date '+%a %b %e %T'`" >${LOG_FILE}
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql "${SCHEMA}" >${FILE_NAME}
TARGET_COUNT=`cat ${FILE_NAME} | wc -l`
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "echosurvey.com PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
#Ftp the file to LS
#################################################################
echo "Starting the ftp process to echosurvey.com at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
cd $DATA
lftp -u HBC-CX,'8mjp4lvp' sftp://filemanager.lrwcx.com<<EOF>>$LOG_FILE
cd Invitations_ContactCenter
put off5th_data_extract_`date +%m%d%Y`.csv
quit
EOF
cd $HOME
echo "Finished the ftp process to  echosurvey.com at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
echo "feed_echosurvey _product process completed at `date '+%a %b %e %T %Z %Y'`" >>${LOG_FILE}
#################################################################
# Check for errors
################################################################
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi