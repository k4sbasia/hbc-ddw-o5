#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : edb_waitlist_extract_sms
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This script extracts waitlisted items that are have intertory available now
#####                              2. and generates xml file to send to CM
#####
#####
#####
#####   CODE HISTORY :                  Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle	        	03/15/2012      created
#####
#############################################################################################################################
################################################################
. $HOME/params.conf $1
export BANNER=$1
export PROCESS='edb_sms_subscribers_spool_all_banners'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE=${LOG}/${BANNER}_${PROCESS}_log.txt
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export today=${today:-$(date +%Y%m%d)}
export SAKS_FILE="sms_subs.persons_${today}_saks.csv"
export O5_FILE="sms_subs.persons_${today}.csv"
export FILE="sms_subs.persons_${today}.csv"
export SAKS_SPOOL_SQL="edb_sms_subscribers_saks_spool.sql"
export O5_SPOOL_SQL="edb_sms_subscribers_spool.sql"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export BATCH_NO='0'
export SCHEMA=""
export BMCONNECTION=""
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
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo "${PROCESS} started for $BANNER" > ${LOG_FILE}

if [ "${BANNER}" == "saks" ]
then
	SCHEMA="mrep."
	FILE=${SAKS_FILE}
	SPOOL_SQL=${SAKS_SPOOL_SQL}
else
	SCHEMA="o5."
	FILE=${O5_FILE}
	SPOOL_SQL=${O5_SPOOL_SQL}
fi

echo "staring spool" >> ${LOG_FILE}
sqlplus -s $CONNECTDW  @${SQL}/${SPOOL_SQL} "$SCHEMA" > ${DATA}/${FILE}

#################################################################
echo "Process completed" >> ${LOG_FILE}
#################################################################

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|failed|invalid identifier|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
else
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit 0
