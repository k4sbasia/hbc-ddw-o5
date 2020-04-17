#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_ftp_cm_daily_up
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This ftp's the daily email files to CM
#####
#####
#####
#####   CODE HISTORY :                  Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle			    06/04/2013      Created
#####									Sripriya Rao			05/24/2016		Modified
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_edb_ftp_cm_daily_up'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
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

today=${today:-$(date +%Y%m%d)}
#sub=o5_subscriber_${today}.csv
unsub=o5_unsubscribers_${today}.csv
coa=o5_coa_${today}.csv
reopt=o5_cheetah_reopt_${today}.txt


files="o5_unsubscribers_${today}.csv
       o5_coa_${today}.csv
       o5_cheetah_reopt_${today}.txt"
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /export/home/cognos/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

########FTP piece ##############################################
########encrypt###################################################
echo "${PROCESS} Starting" > ${LOG_FILE}

# send to cheetah
cd ${DATA}
#ftp -nv filerepo.saksdirect.com <<EOF>>$LOG_FILE
#user ftservice fr1secure
#prompt off
#cd INCOMING
echo "Starting FTP" >> ${LOG_FILE}
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>>${LOG_FILE}
cd autoproc
put ${unsub}
put ${coa}
put ${reopt}
quit
EOF

echo "FTP complete" >> ${LOG_FILE}

mv ${files} ${DATA}/ARCHIVE/

echo "${PROCESS} complete" >> ${LOG_FILE}

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|cannot|Invalid|can not|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit $?
