#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_bi_promo_parse_id.sh
#####
#####   DESCRIPTION  : This script does the following
#####				   1. The scripts loads the bi_promo.txt file into table using sqlldr
#####
#####
#####
#####
#####   CODE HISTORY :	Name				Date		Description
#####					------------		----------	------------
#####					Unknown				Unknown		Created
#####					Rajesh Mathew		08/10/2010	Modified
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
export PROCESS='o5_bi_promo_parse_ld'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export FILE_NAME="${DATA}/o5_bi_promo.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export BANNER=$1
########################################################################
echo -e "BI_PROMO_PARSE_ID PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^9'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
if [ "${BANNER}" == "saks" ]
then
export SCHEMA="mrep."
fi
if [ "${BANNER}" == "o5" ]
then
export SCHEMA="o5."
fi
#################################################################
##Update Runstats Start
#################################################################
FILE_COUNT=`wc -l $FILE_NAME | awk '{printf("%s\n",$1)}'`
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Load Data
#################################################################
 sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$LOG_FILE BAD=$BAD_FILE DATA=$FILE_NAME  ERRORS=9999 SKIP=0 <<EOT>> $LOG_FILE
EOT
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo -e "BI_PROMO_PARSE_ID PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
