#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_onera_safety_stock_load.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. check to see if safety stock file exists for Onera
#####                  2. if file exists, download the file and load to onera_safety_stock and saks_custom.store_inventory table
#####                  3. generate report
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####
#####
#####
##################################################################################################################################
. $HOME/params.conf $1
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='medalia_feed_extract'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export DATA_FILE=$DATA/${PROCESS}.html
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export CONTROL_FILE="${CTL}/${PROCESS}.ctl"
export BAD_FILE="${LOG}/${PROCESS}.bad"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export OMS_FILE_NAME="${PROCESS}_OMS_`date +%m%d%Y`.csv"
export FILE_NAME="off5th_data_extract_`date +%m%d%Y`.csv"
set -x
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
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
cd ${DATA}
###### get latest data from OMS
sqlplus -s -l $CONNECTO5OMSREAD @${SQL}/${PROCESS}_oms.sql >${OMS_FILE_NAME}
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CTL_LOG BAD=$BAD_FILE DATA=${OMS_FILE_NAME}  ERRORS=99 SKIP=1 direct=true
sqlplus -s -l $CONNECTDW @${SQL}/${PROCESS}.sql "${1}." >${FILE_NAME}
wait
echo "Starting the ftp process to echosurvey.com at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
lftp -u HBC-CX,'8mjp4lvp' sftp://filemanager.lrwcx.com<<EOF>>$LOG_FILE
cd Invitations_ContactCenter
put ${FILE_NAME};
quit
EOF
cd $HOME
echo "Finished the ftp process to  echosurvey.com at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
echo "process completed at `date '+%a %b %e %T %Z %Y'`" >>${LOG_FILE}
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

#################################################################
