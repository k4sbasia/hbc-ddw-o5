#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_data_extract.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. It extracts the mrep data and compress it
#####
#####
#####
#####
#####   CODE HISTORY :  Name                  Date            Description
#####                  ------------            ----------      ------------
#####                   Divya Kafle           06/09/2013      Created
#####                   Vishal Kumar          03/07/2017	  Modified: Added logic to capture and report errors &
#####                                                                   to notify user/Data team of Delay/Failure.
#####
#####
#############################################################################################################################
#############################################################################################################################
. $HOME/params.conf o5
#set -xu
export PROCESS='o5_data_extract'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
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
export SQL1='o5_bi_customer_extract'
export SQL6='o5_email_gender_data'
DATA_FILE1='o5_bi_customer_extract.txt'
DATA_FILE6='o5_email_gender_data.txt'
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
function send_delay_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 export SUBJECT=${BAD_SUBJECT}
 BSUBJECT="O5 DATA EXTRACT DELAYED"
 BBODY="O5 data extract is delayed and we are looking into it. Thanks!"
 BADDRESS='hbcdigtialdatamanagement@hbc.com'
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" ${BADDRESS}
 send_email
}
#################################################################
#################################################################
echo -e "mrep_data_extract Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
export JOB_NAME="${SQL1}"
export SCRIPT_NAME="${SQL1}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the bi_customer_extract.sql script
#################################################################
echo -e "bi_customer_extract Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL1}.sql > ${DATA}/${DATA_FILE1}
ORACLE_RET_CODE=$?
if [ ${ORACLE_RET_CODE} -ne 0 ]
then
       echo "Aborting: Error executing $SQL1 at `date '+%a %b %e %T'`" >>${LOG_FILE}
		send_delay_email
		exit 99
fi
#################################################################
echo -e "bi_customer_extract Load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT=`wc -l ${DATA}/${DATA_FILE1}`
TARGET_COUNT=`echo -e $TARGET_COUNT | tr ' ' '|' | cut -f1 -d '|'`
if [ ${TARGET_COUNT} -gt 1000000 ]
then
echo -e "Total Count from bi_cusotmer_extract for today is: $TARGET_COUNT \n" >>${LOG_FILE}
else
echo -e "Not enough records in $DATA_FILE1 \n" >>${LOG_FILE}
		send_delay_email
		exit 99
fi
#################################################################
# Update the runstats
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
export JOB_NAME="${SQL6}"
export SCRIPT_NAME="${SQL6}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the bi_sale_extract.sql script
#################################################################
echo -e "email_gender_extract Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL6}.sql > ${DATA}/${DATA_FILE6}
ORACLE_RET_CODE=$?
if [ ${ORACLE_RET_CODE} -ne 0 ]
then
        echo "Aborting: Error executing $SQL6 at `date '+%a %b %e %T'`" >>${LOG_FILE}
	send_delay_email
    exit 99
fi
#################################################################
echo -e "email_gender_extract Load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT=`wc -l ${DATA}/${DATA_FILE6}`
TARGET_COUNT=`echo -e $TARGET_COUNT | tr ' ' '|' | cut -f1 -d '|'`
if [ ${TARGET_COUNT} -gt 1000000 ]
then
     echo -e "Total Count from email_gender_extract for today is: $TARGET_COUNT \n" >>${LOG_FILE}
else
     echo -e "Not enough records in $DATA_FILE6 \n" >>${LOG_FILE}
	send_delay_email
 exit 99
fi
#################################################################
#################################################################
# Update the runstats
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
#tar and zip output files
cd ${DATA}
echo -e "Compressing the data at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
tar -cf - ${DATA_FILE1} ${DATA_FILE6} >`date +%Y%m%d`.o5.tar
wait
bzip2 -c `date +%Y%m%d`.o5.tar >`date +%Y%m%d`.o5.tar.bz2
wait
cd $HOME
echo -e "Compressing the data Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
###check the tar file
ZFILE=$DATA/`date +%Y%m%d`.o5.tar.bz2
ZFILE_COUNT=`wc -l ${ZFILE}`
ZFILE_COUNT=`echo -e $ZFILE_COUNT | tr ' ' '|' | cut -f1 -d '|'`
echo -e "Line Count from ZIP FILE  for today is: $ZFILE_COUNT \n" >>${LOG_FILE}
################################################################
echo -e "mrep_data_extract Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi

cd ${DATA}
rm `date +%Y%m%d`.o5.tar
