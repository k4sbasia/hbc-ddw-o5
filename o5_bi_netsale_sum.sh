#!/usr/bin/ksh 
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_bi_netsale_sum.sh
#####
#####   DESCRIPTION  : This script does the following 
#####				   1. This scripts loads the summary netsale into the staging table
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
export PROCESS='o5_bi_netsale_sum'
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
export FILE_NAME="${DATA}/OFF5THLSUM.dat"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}" 
export SFILE_SIZE='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export COMP_DATA="${DATA}/o5_sales_audit_comp.txt"
export SUBJECT2="O5 NETSALES AUDIT SUMMARY COMPARISON"
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
echo -e "BI_NETSALE_SUM Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#  Move the data file
#################################################################
cp /home/ftservice/INCOMING/OFF5THLSUM."$TODAY" $DATA/OFF5THLSUM.dat
#################################################################
##Load the Net Sales Data
#################################################################
 sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$LOG_FILE BAD=$BAD_FILE DATA=$FILE_NAME  ERRORS=9999 SKIP=0 <<EOT>> $LOG_FILE
EOT
#################################################################
## Get stats and Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql >${COMP_DATA}
cat ${COMP_DATA}|mailx -s "${SUBJECT2}" hbcdigtialdatamanagement@hbc.com 
################################################################
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
#send_email
fi
exit 0

