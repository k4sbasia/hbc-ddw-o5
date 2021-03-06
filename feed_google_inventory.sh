#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : feed_google_inventory.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for google  Inventory feed for saks and off5th
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Nilima Mehta           03/20/2017
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='feed_google_inventory'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export BANNER=$BANNER
export BANNER_PARAM=$1
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export BAD_SUBJECT="FAILURE:${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME=""
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export REC_COUNT='1'
export SCHEMA=""
export SUFFIX=""
export CHAIN=""
export SAKS_FILE_NAME1="google_inventory_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export SAKS_FILE_NAME2="saksfifthavenue_en-us_price-quantity_003"
export O5_FILE_NAME1="google_inventory_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export O5_FILE_NAME2="saksofffifthavenue_en-us_price-quantity_test"
export LT_FILE_NAME1="google_inventory_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export LT_FILE_NAME2="lordandtaylor_en-us_price-quantity_test"
export BANNER=&1
########################################################################
##Initialize Email Function
#####################################################################
echo -e " Google inventory feed started at `date '+%a %b %e %T'`" >${LOG_FILE}
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
if [ "${BANNER}" == "saks" ]
then
export CHAIN="8"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
#######################populate staging table for bay on rfs#########################################
sqlplus -s -l  $CONNECTDW @${SQL}/feed_google_inventory_saks.sql "${SCHEMA}" "${BANNER}" "${PART_TABLE}"  "${PIM_DBLINK}"  > $DATA/${SAKS_FILE_NAME1}
######################################################################################################
cd $DATA
SOURCE_COUNT=`cat $DATA/${SAKS_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file before sending to google. If count is less than 60000 then process will fail" >> ${LOG_FILE}
if [ ${SOURCE_COUNT} -gt 60000 ]
then
echo " ${SOURCE_COUNT} records found in ${SAKS_FILE_NAME1} file " >> ${LOG_FILE}
## DO FTP here
cd $DATA
cp ${SAKS_FILE_NAME1} ${SAKS_FILE_NAME2} >>${LOG_FILE}
echo -e "FTP for Inventory started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
lftp -u mc-sftp-9439371,'^4>M$,!O7a' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
put ${SAKS_FILE_NAME2}
wait
Bye
EOF
#################################################################
#################################################################
echo -e "FTP for inventory ended to google at `date '+%a %b %e %T'` " >>${LOG_FILE}
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${SAKS_FILE_NAME1} file which is less than 60000. Please check  ${SAKS_FILE_NAME1}  file" >> ${LOG_FILE}
echo "Google product feed for ${BANNER}. Please check $DATA/${SAKS_FILE_NAME1} file "| mailx -s "Google product feed failed - ${BANNER}" hbcdigitaldatamanagement@saksinc.com
exit 99
fi
fi
##############################################################################################
if [ "${BANNER}" == "o5" ]
then
export CHAIN="7"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
##################################################################  Run the sql script that write file
sqlplus -s -l  $CONNECTDW @${SQL}/feed_google_inventory_o5.sql  "${SCHEMA}" "${BANNER}" "${PART_TABLE}"  "${PIM_DBLINK}"  > $DATA/${O5_FILE_NAME1}
wait
cd $DATA
SOURCE_COUNT=`cat $DATA/${O5_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file before sending to google. If count is less than 60000 then process will fail" >> ${LOG_FILE}
## Unco
echo " ${SOURCE_COUNT} records found in ${O5_FILE_NAME1} file " >> ${LOG_FILE}
cd $DATA
cp ${O5_FILE_NAME1}  ${O5_FILE_NAME2} >>${LOG_FILE}
## DO FTP here
################################################################
echo -e "FTP for O5 Inventory started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
lftp -u mc-sftp-17287421,'q!c!_6m{Oa' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
put ${O5_FILE_NAME2}
wait
Bye
EOF
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#else
#echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${O5_FILE_NAME1} file which is less than 60000. Please check error in  ${O5_FILE_NAME1}  file" >> ${LOG_FILE}
#send_delay_email
#exit 99
#fi
fi
##############################################################################################
if [ "${BANNER}" == "lat" ]
then
export CHAIN="21"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
##################################################################  Run the sql script that write file
sqlplus -s -l  $CONNECTDSGDW @${SQL}/feed_google_inventory_lt.sql  "${SCHEMA}" "${BANNER}" "${PART_TABLE}" "${PIM_DBLINK}"   > $DATA/${LT_FILE_NAME1}
wait
cd $DATA
SOURCE_COUNT=`cat $DATA/${LT_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file before sending to google. If count is less than 60000 then process will fail" >> ${LOG_FILE}
if [ ${SOURCE_COUNT} -gt 10000 ]
then
echo " ${SOURCE_COUNT} records found in ${LT_FILE_NAME1} file " >> ${LOG_FILE}
cd $DATA
cp ${LT_FILE_NAME1}  ${LT_FILE_NAME2} >>${LOG_FILE}
## DO FTP here
################################################################
echo -e "FTP for LT Inventory started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
lftp -u mc-sftp-6649174,'T:y7#Htw<K' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
put ${LT_FILE_NAME2}
wait
Bye
EOF
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${LT_FILE_NAME1} file which is less than 60000. Please check error in  ${LT_FILE_NAME1}  file" >> ${LOG_FILE}
send_delay_email
exit 99
fi
fi
####################################################################
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

####################################################################
#################################################################
echo -e " feed Process Ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate." >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
export SUBJECT="SUCCESS: quick hits Completed"
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors." >> ${LOG_FILE}
#send_email
fi
