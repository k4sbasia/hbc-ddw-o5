#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : feed_channel_advisor_bloomreach.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. The script calls the feed_channel_advisor.sh which produces a customized CA product feed to Bloomreach.
#####
#####
#####   CODE HISTORY :                   Name                   Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Sripriya Rao            07/19/2016      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
export BANNER=$1
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='feed_channel_advisor_bloomreach'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export PROCESS_SQL="${PROCESS}.sql"
export SFILE_SIZE=0
export FILE_NAME="$DATA/CA_feed_bloomreach_`date +"%Y%m%d"`.txt"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
########################################################################
##update Runstats Start
#################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^9'|while read group address
 do
 echo "The ${PROCESS} has mismatch source and target counts ${CURRENT_TIME}"|mailx -s "CA Feed Mismatch Counts" $address
 done
}
##################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

###################################################################
echo "Started extracting data at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS_SQL} >${FILE_NAME}
SOURCE_COUNT=`cat ${FILE_NAME} | wc -l`
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
echo "Channeladvisor_feed PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
#Ftp the file to CA
#################################################################
echo "Starting the sftp process to Bloomreach at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
cd $DATA
echo "Checking the validity of the feed file generated..." >> ${LOG_FILE}
if [ `egrep -c "^ERROR|ORA-|not connected|object no longer exists error" ${FILE_NAME}` -ne 0 ]
then
        echo "Incorrect data in the feed file, ${FILE_NAME}. Please investigate"
        echo "Incorrect data in the feed file, ${FILE_NAME}. Please investigate" >> ${LOG_FILE}
        exit 99
else
iconv -f ISO-8859-1 -t UTF-8 $FILE_NAME > $DATA/Saks_CA_feed_bloomreach.tsv
sftp -o StrictHostKeyChecking=no  saksfifthavenue@ftp.bloomreach.com <<EOF>>${LOG_FILE}
cd feed
put Saks_CA_feed_bloomreach.tsv
quit
EOF
lftp -u top_e6576e32-7716-4913-a425-8b898c67b5ef,'b4cecb1c-8e8d-4888-923e-dc5a251563e6' sftp://data-sftp.criteo.com<<EOF>>${LOG_FILE}
cd Saks5th
put $FILE_NAME
quit
EOF
fi
cd $HOME
echo "Finished the ftp process to Bloomreach  at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
echo "Saks Product feed to Bloomreach process completed at `date '+%a %b %e %T %Z %Y'`" >>${LOG_FILE}
#################################################################
# Check for errors
################################################################
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|not connected" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
exit 0
#################################################################
fi
