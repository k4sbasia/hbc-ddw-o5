#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : extract_status_update.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1.Updating the time for last  data pull
#####
#####   CODE HISTORY :  		Name                            Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya           	09/30/2015      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS_NAME=$1
export PROCESS='extract_status_update'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
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
export VALIDATE_COUNT='1'
export UPDATE=''
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
#################################################################
echo -e "Time UPDATE process started for $PROCESS_NAME at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################

UPDATE=`sqlplus -s $CONNECTDW <<EOF
set heading off
update mrep.job_extract_status
set last_extract_time= curr_extract_time,
curr_extract_time =sysdate
where process_name='${PROCESS_NAME}'
;
commit;
select * from mrep.job_extract_status where job_name='${PROCESS_NAME}';
quit;
EOF`

echo -e "Time UPDATE" >> ${LOG_FILE}

#cat $UPDATE >>${LOG_FILE}

#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553|not connected" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit 0
