#!/usr/bin/ksh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This script ftps the waitlist notification emails to cheetah
#####
#####
#####
#####   CODE HISTORY :                   Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle	         03/15/2012      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf $1
export BANNER=$1
export ENV=$2
export PROCESS='edb_sms_subs_vibe_ftp_all_banners'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE=${LOG}/${BANNER}_${PROCESS}_log.txt
export BAD_SUBJECT="${BANNER} ${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export todayhh=${today:-$(date +%Y%m%d%H%M%S)}
export today=${today:-$(date +%Y%m%d)}
export SAKS_FILE="sms_subs.persons_${today}_saks.csv"
export O5_FILE="sms_subs.persons_${today}.csv"
export FILE="sms_subs.persons_${today}.csv"
export FILENAME="sms_subs.subs_${todayhh}.csv"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
################################################################
################################################################

echo "${PROCESS} started for $BANNER in $ENV" > ${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
####FTP File
#################################################################
cd ${DATA}

if [ "${BANNER}" = "saks" ]
then
        FILE=${SAKS_FILE}
else
        FILE=${O5_FILE}
fi


FILESIZE=$(stat -c%s "$FILE")
echo "Size of $FILENAME = $FILESIZE bytes." >> ${LOG_FILE}
if [ $FILESIZE -gt 2 ]
then
cp ${FILE} ${FILENAME}

if [ "${BANNER}" = "saks" ]
then
	if [ "${ENV}" == "qa" ]
	then
		lftp -u saksfif2153,d5f7d014a2db5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
		cd files/in
		#put ${FILENAME}
		quit
EOF
	else
		lftp -u saksfif2153,d5f7d014a2db5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
		cd files/in
		#put ${FILENAME}
		quit
EOF
	fi
else
	if [ "${ENV}" == "qa" ]
	then
		lftp -u off5th5498,4fe29ea35cee5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
		cd files/in
		put ${FILENAME}
		quit
EOF
	else
		lftp -u off5th5498,4fe29ea35cee5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
		cd files/in
		put ${FILENAME}
		quit
EOF
	fi
fi
else
	echo "No data at this time to send"
fi
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
exit 0
