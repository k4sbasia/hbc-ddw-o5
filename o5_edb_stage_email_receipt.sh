#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_stage_email_receipt.sh
#####
#####   DESCRIPTION  : This script does the following
#####
#####
#####   CODE HISTORY :                    Name                    Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Divya Kafle	        12/21/2014      created
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_edb_stage_email_receipt'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export today=`date +%Y%m%d -d"1 day ago"`
export FILE_NAME="SKSDIRECT_EMAIL.${today}"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'

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

##FTP File
#################################################################
cd $DATA
ftp -nv filerepo.saksdirect.com <<EOF>$LOG_FILE
user ftservice ftsOCT=2015
cd INCOMING
get $FILE_NAME
quit
EOF
cd $HOME
##Load Data
#################################################################
sqlldr $CONNECTDW CONTROL=${CONTROL_FILE} LOG=${CTL_LOG} BAD=${BAD_FILE} DATA=${DATA}/${FILE_NAME}  ERRORS="99999999" SKIP="0"
#################################################################
cat ${CTL_LOG}>>${LOG_FILE}
##DB SQL
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG_FILE} @${SQL}/${PROCESS}.sql >>${LOG_FILE}
EOF

################################################################

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
