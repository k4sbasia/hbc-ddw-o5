#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_onera_order_feed.sh
#####
#####   DESCRIPTION  : This script does the following
#####                      1. FTP to onera
#####
#####
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                  ------------            ----------      ------------
#####                  Rajib Banik             09/14/2017      created
#####
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='o5_onera_order_feed'
export CTL=$HOME/CTL
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export SQL=$HOME/SQL
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
cd ${DATA}/ONERA

########################################################################
echo "${PROCESS} to produce order files for Onera started at `date '+%a %b %e %T'`" >${LOG_FILE}
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
##################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF


##########################################################################################
echo "Invoke ODI to PULL OMS ORDER data started at `date '+%a %b %e %T'`" >>${LOG_FILE}
##########################################################################################
#$HOME/run_odi_scenario.sh "O5_ONERA_ORDER_FEED" "001" "OFF5" >> ${LOG_FILE}
$HOME/run_odi_scenario.sh "O5_NEW_ONERA_ORDER_FEED" "001" "OFF5" >> ${LOG_FILE}
##################################################################
if [ $? -gt 0 ]
then
  echo "ODI job failed due to data error please check " | mailx -s "O5 Onera Order feed Failed" hbcdigitaldatamanagement@saksinc.com harsh.desai@hbc.com
fi

echo "ODI to PULL OMS ORDER data completed at `date '+%a %b %e %T'`" >>${LOG_FILE}

export FILE_NAME=`ls -ltr /home/cognos/DATA/ONERA/Off5_orders_hourly_feed_*.csv | awk  '{print $9}' | sed 's/.*\///'`
echo "New File Name ${FILE_NAME}" >>${LOG_FILE}
TARGET_COUNT1=`cat ${FILE_NAME} | wc -l`
if [ $TARGET_COUNT1 -lt 1 ]
then
echo "No data for Onera Order feed"
echo "${PROCESS} was not sent. No data for Onera hourly order feed." >> $LOG_FILE
export SUBJECT="No data for Onera hourly Order feed ${CURRENT_TIME}"
send_email
exit 99
fi
wait



sftp saks@feeds-saks.oneracommerce.com  <<end-of-session
cd /mnt/saksoff5th/data/prod
put ${FILE_NAME}
bye
end-of-session


if [ $? -gt 0 ]
then
  mailx -s "WARNING: ${FILE_NAME} did not ftp'ed to Onera" hbcdigitaldatamanagement@saksinc.com
fi


#echo "sftp to internal server" >> $LOG_FILE
#sftp -oIdentityFile=/home/cognos/.ssh/vendor_keys/id_saks hbc-safety-stock@sftp2.data.hbc.io<<EOF>> ${LOG_FILE}
#cd hbc-safety-stock/O5/ORDER/
#put ${FILE_NAME}
#quit
#EOF


mv ${DATA}/ONERA/${FILE_NAME} ${DATA}

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "Feed Onera hourly order PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
