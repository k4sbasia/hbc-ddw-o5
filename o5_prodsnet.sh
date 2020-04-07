#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_prodsnet.sh
#####
#####   DESCRIPTION  : This script does the following
#####				   1. Calls the sql script that deletes the cancelled products from bi_sale table
#####
#####
#####
#####
#####   CODE HISTORY :	Name				Date		Description
#####					------------		----------	------------
#####					Unknown				Unknown		Created
#####					Rajesh Mathew		05/16/2010	Modified
#####
#####
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='o5_prodsnet'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export TODAY=`date -d '-1 day' '+%Y%m%d'`
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export BAD_SUBJECT="${PROCESS} failed"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export FILE_NAME="${DATA}/OFF5THCTL.dat"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
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
 cat $HOME/email_distribution_list.txt|grep '^9'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
echo -e "Prodsnet Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#  Move the data file
#################################################################
cp /home/ftservice/INCOMING/OFF5THCTL."$TODAY" $DATA/OFF5THCTL.dat
#################################################################
##Load the Net Sales Data
#################################################################
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$LOG_FILE BAD=$BAD_FILE DATA=$FILE_NAME  ERRORS=9999 SKIP=0 <<EOT>> $LOG_FILE
EOT
#################################################################
## Get stats and Update Runstats Finish
#################################################################
TFILE_SIZE="`ls -ll $DATA/OFF5THCTL.dat |tr -s ' ' '|' |cut -f5 -d'|'`"
TARGET_COUNT="`wc -l $DATA/OFF5THCTL.dat|tr -s ' ' '|' |cut -f1 -d'|'`"
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#  Update the BI_NETSALE table
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql >> ${LOG_FILE}
#################################################################
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
#send_email
fi
