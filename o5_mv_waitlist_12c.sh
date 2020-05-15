#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_mv_waitlist.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Refresh The Data In Marketing Data Mart
#####
#####
#####   CODE HISTORY :                    Name                    Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                  Aparna Hashmi	        10/13/2015      created
#############################################################################################################################
################################################################
. $HOME/params.conf o5
#set -xu
export PROCESS='o5_mv_waitlist'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export TARGET_COUNT1='0'
export FILE_NAME='o5_mv_waitlist_extract.csv'

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
sqlplus -s -l $CONNECTRUNSTATS12C <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo "${PROCESS} Started" > ${LOG_FILE}

sqlplus -s -l $CONNECTSDMRK12C @${SQL}/${PROCESS}_refresh.sql >> ${LOG_FILE}
wait

sqlplus -s -l $CONNECTSDMRK12C @${SQL}/${PROCESS}.sql   >  $DATA/$FILE_NAME
wait
cd ${DATA}
################################################################
##Commented as ft taking longer from hd1box
echo "Ftp the file ${FILE_NAME_ORDER} to Jackson SAS server" > ${LOG_FILE}
ftp -nv 10.130.176.210  <<EOF>>${LOG_FILE}
user sasftp sasftp0313S
prompt off
bin
put  ${FILE_NAME_ORDER}
quit
EOF
################################################################
cd ${HOME}
##Update Runstats Finish
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
echo "${PROCESS} completed" >> ${LOG_FILE}
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|invalid identifier|failed|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "SDMRK.O5_MV_WAITLIST refreshed successfully `date +"%m/%d/%Y-%H:%M:%S"`"|mailx -s "SDMRK.O5_MV_WAITLIST refreshed successfully" saksdirectdatamanagement@saksinc.com ali_amin@s5a.com nivedhitha_swaminathan@s5a.com fanli_zhou@s5a.com faye_shi@s5a.com jenny_colgan@s5a.com
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
