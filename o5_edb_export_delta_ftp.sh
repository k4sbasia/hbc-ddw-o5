#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_export_delta_ftp.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This ftp's the daily email files to CM (included in delta)
#####
#####
#####
#####   CODE HISTORY :                   Name                    Date            Description
#####                                   ------------            ----------      ------------
#####									Sripriya Rao			09/16/2015		Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='o5_edb_export_delta_ftp'
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
export todayhh=${today:-$(date +%Y%m%d%H%M%S)}
export today=${today:-$(date +%Y%m%d)}
FILE=o5_subscriber_new_${today}.csv
sub=o5_subscriber_new_${todayhh}.csv

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
echo "${PROCESS} Starting" > ${LOG_FILE}
cd $DATA
FILESIZE=$(stat -c%s "$FILE")
echo "Size of $FILE = $FILESIZE bytes." >> ${LOG_FILE}
if [ $FILESIZE -gt 1 ]
then
mv $FILE ${sub}
cd $HOME
########FTP piece ##############################################
########encrypt###################################################
echo "Starting encryption" >> ${LOG_FILE}
cd $DATA
echo "Starting FTP" >> ${LOG_FILE}
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>>${LOG_FILE}
cd autoproc
put ${sub}
quit
EOF

echo "FTP complete" >> ${LOG_FILE}
mv ${sub} ${DATA}/ARCHIVE/
echo "${PROCESS} complete" >> ${LOG_FILE}
fi

cd $HOME

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
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit $?
