#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_bi_unaudited_sales.sh
#####
#####   DESCRIPTION  : This script does the following
#####                             
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####                                   Rajesh Mathew           05/18/2011      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_bi_unaudited_sales'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export DATA_FILE=$DATA/o5_unaudited_sales.txt
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
echo -e "O5 BI_UNAUDITED_SALES Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
#  Run the sql script that performs the data load
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql > ${DATA_FILE}
wait
#################################################################
# Check for the data load
#################################################################
echo -e "o5 bi_unaudited_sales Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
export SUBJECT="SUCCESS: o5 un-audited sales process completed"
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
###################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#send_email
fi
exit 0
