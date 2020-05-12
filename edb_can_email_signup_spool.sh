#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : edb_can_email_signup_spool.sh
#####
#####   DESCRIPTION  : This script does the following
#####
#####
#####   CODE HISTORY :
#####                   Name                     Date            Description
#####                  ------------            ----------      ------------
#####
#####                  Sripriya Rao              08/04/2015      Created
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
export PROCESS="edb_can_email_signup_spool"
export CONTROL_FILE="${PROCESS}.ctl"
export CONTROL_LOG="$LOG/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export EXTRACT_SQL="$SQL/${PROCESS}.sql"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
export TARGET_COUNT=0
today=${today:-$(date +%Y%m%d)}
export YDAY=`date +%Y%m%d -d"1 day ago"`
export FILE_NAME="canada_email_signup_${today}.csv"
export YDAY_FILE="canada_email_signup_${YDAY}.csv"
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

echo "Starting the process ${PROCESS} `date '+%a %b %e %T %Z %Y'` " > ${LOG_FILE}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

##### Delete the previous day subscriber spool file ######
if [ -f $DATA/$YDAY_FILE ]
then
	rm $DATA/$YDAY_FILE
fi

#################################################################################################
## Extract subscriber file for Saks/O5 Canada
#################################################################################################
echo " Spooling the Canada Suscribers details at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @$EXTRACT_SQL > $DATA/${FILE_NAME}

#################################################################################################
## Copy subscriber spool file for Saks/O5 Canada to I:Drive
#################################################################################################
smbclient //T49-VOL4.INTRANET.SAKSROOT.SAKSINC.COM/ecommerce --authentication-file  /home/cognos/auth_tmp.txt --command 'cd "2015 Marketing\Marketing Analytics\Cross Banner\Splash Page Optins";prompt;lcd /home/cognos/DATA; mput canada_email_signup*.csv;quit;'

#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
exit $?
