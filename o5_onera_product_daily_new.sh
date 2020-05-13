#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : onera_product_daily.sh
#####
#####   DESCRIPTION  : This script does the following
#####                      1. extract product data from production
#####                      2. FTP to onera
#####
#####
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                  ------------            ----------      ------------
#####			Liya Aizenberg		11/10/2014	created
#####
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
export PROCESS='o5_onera_product_daily_new'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
#export EXTRACT_SQL1="$SQL/o5_onera_product_daily_new.sql"
export EXTRACT_SQL1="$SQL/o5_onera_product_daily_update_new.sql"
export FILE_NAME="$DATA/saks_off5th_onera_product_daily_feed_`date +%Y%m%d`.txt"
export REMOVE_FILE_NAME="$DATA/saks_off5th_onera_product_daily_feed_`date -d '2 day ago' "+%Y%m%d"`.txt.gz"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
############################################################
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
export BANNER="saks"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
export BANNER="o5"
fi
########################################################################
echo "${PROCESS} to produce data files for Onera started at `date '+%a %b %e %T'`" >${LOG_FILE}
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

###################################################################
echo "Started extract data at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL1} "${SCHEMA}" "${BANNER}" >${FILE_NAME}
###################################################################
echo "End extract data at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################

TARGET_COUNT1=`cat ${FILE_NAME} | wc -l`
if [ $TARGET_COUNT1 -eq 1 ]
then
echo "No data for saksoff5th Onera daily safety stock feed"
echo "${PROCESS} was not sent. No data for Onera daily product feed." >> $LOG_FILE
export SUBJECT="No data for Onera daily product feed"
send_email
exit 99
fi
wait

echo "Finished Onera extracting data at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
##FTP file
cd $DATA

dos2unix ${FILE_NAME}
sftp '-oIdentityFile=/home/ddwo5/.ssh/cognos_id_rsa' saks@feeds-saks.oneracommerce.com  <<end-of-session
cd saksoff5th
put saks_off5th_onera_product_daily_feed_`date +%Y%m%d`.txt onera_product_daily_feed_`date +%Y%m%d`.txt
bye
end-of-session

if [ $? -gt 0 ]
then
  mailx -s "WARNING: ${FILE_NAME} did not ftp'ed to Onera" hbcdigtialdatamanagement@hbc.com
fi

gzip ${FILE_NAME}

echo "sftp to internal server" >>${LOG_FILE}
sftp -oIdentityFile=/home/ddwo5/.ssh/vendor_keys/id_saks hbc-safety-stock@sftp2.data.hbc.io<<EOF>> ${LOG_FILE}
cd hbc-safety-stock/O5/PRODUCT/
put saks_off5th_onera_product_daily_feed_`date +%Y%m%d`.txt.gz
quit
EOF

if [ -f ${REMOVE_FILE_NAME} ]
then
   rm ${REMOVE_FILE_NAME}
fi

#################################################################
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "feed Onera hour orders PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
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
exit 0
