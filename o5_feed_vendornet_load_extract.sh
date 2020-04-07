#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   NAME : o5_feed_vendornet_load_extract.sh
#####   DESCRIPTION  : This script does the following
#####                              1. It populates the BI_VENDORNET table and ftp the daily data
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####                                   Rajib Banik           09/29/2016      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
#export PROCESS='o5_feed_vendornet_load'
export PROCESS='o5_feed_vendornet_load_new'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export DATA_FILE=$DATA/dropship_extract_o5.txt
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
#export EXTR_SQL='o5_feed_vendornet_extract'
export EXTR_SQL='o5_feed_vendornet_extract_new'
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
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "BI_Vendornet_extract_load Process started at `date '+%a %b %e %T'`" >${LOG_FILE}
#################################################################
#  Run the sql script that performs the data load
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql >> ${LOG_FILE}
wait
#################################################################
# Check for the data load
#################################################################
if [ $? -ne 0 ] || [ `egrep -c "^ERR|ORA-|not found|SP2-0" ${LOG_FILE}` -ne 0 ]
 then
echo "FAILURE - bi_vendornet_data_load  `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "SUCCESS - bi_vendornet_data_load  `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
fi
#################################################################
echo "Starting  data extract `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${EXTR_SQL}.sql  > ${DATA_FILE}
wait
TARGET_COUNT="`wc -l $DATA_FILE|tr -s ' ' '|' |cut -f1 -d'|'`"
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#Ftp the file to Vednornet
#################################################################
echo "Starting the ftp process to vendornet at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
cd $DATA
sftp SaksFifthAve@prd-transfer.vendornet.com <<EOF>>${LOG_FILE}
cd  Live/DS/Products
put dropship_extract_o5.txt
quit
EOF

cd $HOME
echo "Finished the ftp process to vendornet at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
echo "bi_vendornet_data_extract_load Process Ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
echo "Dropping the O5 Vendornet file at shared location in I: Drive `date '+%a %b %e %T'`" >>${LOG_FILE}
smbclient "\\\\t49-vol4.INTRANET.SAKSROOT.SAKSINC.com\\ECommerce\\" --authentication-file ./auth.txt --command 'cd "\Merch Ops\Vendor Drop Ship\FTP\Product\O5\";prompt;lcd /home/cognos/DATA/;mput 'dropship_extract_o5.txt';quit'
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 1
else
export SUBJECT="SUCCESS: VENDORNET data extract process completed"
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
exit 0
fi
