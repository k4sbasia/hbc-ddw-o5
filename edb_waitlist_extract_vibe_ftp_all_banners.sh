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
. $HOME/initvars
export BANNER=$1
export ENV=$2
export PROCESS='edb_waitlist_extract_vibe_ftp_all_banners'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE=${LOG}/${BANNER}_${PROCESS}_log.txt
export BAD_SUBJECT="${BANNER} ${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export todayhh=${today:-$(date +%Y%m%d%H%M%S)}
export today=${today:-$(date +%Y%m%d)}
export SAKS_FILE="waitlist.recipient_list_saks.csv"
export O5_FILE="waitlist.recipient_list.csv"
export FILE="waitlist.recipient_list.csv"
export FILETEST="waitlist_test.recipient_list.csv"
export FILENAME="waitlistprod.recipient_list.csv"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
################################################################
################################################################

echo "${PROCESS} started for ${BANNER} in $ENV" > ${LOG_FILE}
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
	cp ${SAKS_FILE} ${FILE}

else
	cp ${O5_FILE} ${FILE}

fi



FILESIZE=$(stat -c%s "$FILE")
echo "Size of $FILE = $FILESIZE bytes." >> ${LOG_FILE}
if [ $FILESIZE -gt 2 ]
then

if [ "${BANNER}" = "saks" ]
then

	if [ `egrep -c "saksoff5th.com" ${FILE}` -ne 0 ]
    then
		echo "Incorrect file . Unable to send" >> ${LOG_FILE}
	else
		if [ "${ENV}" == "qa" ]
		then
			lftp -u saksfif2153,d5f7d014a2db5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
			cd files/in
			put ${FILE}
			quit
EOF
		else
			lftp -u saksfif2153,d5f7d014a2db5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
			cd files/in
			put ${FILE}
			quit
EOF
		fi
	fi

else
	if [ `egrep -c "saksfifthavenue.com" ${FILE}` -ne 0 ]
    then
		echo "Incorrect file . Unable to send" >> ${LOG_FILE}
	else
	if [ "${ENV}" == "qa" ]
	then
		cp ${FILE} ${FILETEST}
		lftp -u off5th5498,4fe29ea35cee5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
		cd files/in
		put ${FILETEST}
		quit
EOF
	else
	cp $FILE $FILENAME
	lftp -u off5th5498,4fe29ea35cee5 sftp://upload.vibes.com<<EOF>>${LOG_FILE}
	cd files/in
	put ${FILENAME}
	quit

EOF
	fi
	fi
fi


else
	echo "No data at this time to send" >> ${LOG_FILE}
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
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
