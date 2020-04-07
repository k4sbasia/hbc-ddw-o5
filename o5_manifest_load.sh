#!/usr/bin/ksh
#############################################################################################################################
#####                           Saks Direct
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_manifest_load
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Extracts and loads manifest media file from Scene 7 into saks_custom table
#####
#####
#####
#####   CODE HISTORY :                     Name                   Date          Description
#####                                   ------------            ----------      ------------
#####                                   David Alexander          07/17/2012     Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
export PROCESS='o5_manifest_load'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME="${DATA}/o5_saksFile.txt"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SLEEP_TIME=300
export SLEEP_CYCLES=20
export RUN_SUBJECT="${PROCESS} has started."
export SLEEP_SUBJECT="${PROCESS} is sleeping."
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CTL_LOG="$LOG/${PROCESS}_ctl.log"
export BAD_FILE="$LOG/${PROCESS}_bad.bad"
export BANNER=$1
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^6'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
echo -e "manifest load started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
fi
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
fi
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##FTP Manifest Delta File
###### Temporarily comment out the curl download part until akamai.com is whitelisted
#wget -r -nH ftp://adobesaks:Ad0b3D1r3ct@saks.download.akamai.com/saks.txt
#wget -r -nH ftp://adobesaks:Ad0b3D1r3ct@saks.download.akamai.com/saks.txt -a ${LOG_FILE}
#curl -O ftp://adobesaks:Ad0b3D1r3ct@saks.download.akamai.com/saks.txt > ${LOG_FILE} 2>&1
#wait
mv /home/ftservice/OUTGOING/SCENE7_HPM_MEDIA_O5.txt ${DATA}/o5_saksFile.txt
dos2unix ${DATA}/o5_saksFile.txt
###################################################################
## SQLLOADER
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CTL_LOG BAD=$BAD_FILE DATA=$FILE_NAME ERRORS=999999999 SKIP=1
#cat $CTL_LOG >>${LOG_FILE}
#################################################################
##DB Insert SQL
#################################################################
echo -e "Starting o5_manifest_load execution ">>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql "${SCHEMA}" "${BANNER}" >> ${LOG_FILE}
echo -e "Ended execution of manifestload ">>${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
rm ${DATA}/o5_saksFile.txt
#################################################################
echo -e "manifest load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553|Login incorrect|RETR response: 550|refused" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
