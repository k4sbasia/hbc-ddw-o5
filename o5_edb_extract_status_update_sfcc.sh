#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_bm_extract_status_update.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1.Updating the time for last Mongo/BM data pull
#####
#####   CODE HISTORY :  				Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Sripriya Rao           	09/16/2015      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='o5_edb_extract_status_update_sfcc'
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
##Update Runstats Start
#################################################################
echo -e "O5 EDB Mongo/BM time UPDATE process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################

UPDATE=`sqlplus -s $CONNECTDW <<EOF
set heading off
update o5.edb_sub_status
set last_extract_time = curr_extract_time,
curr_extract_time = sysdate
;
commit;
select * from o5.edb_sub_status;
quit;
EOF`

echo -e "O5 EDB Mongo/BM time UPDATE" >> ${LOG_FILE}

#cat $UPDATE >>${LOG_FILE}

echo -e "O5 EDB BM UPDATE process completed at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
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
exit 99
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
