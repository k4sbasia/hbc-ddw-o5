#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_fromcheetah_pull_demo.sh
#####
#####   DESCRIPTION  : Pulls the demographics file from cheetah
#####
#####
#####
####
#####   		CODE HISTORY :	Name			Date		Description
#####					------------		----------	------------
#####					Divya Kafle				06/04/2013	Created
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export PROCESS='o5_edb_fromcheetah_pull_demo'
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
export YDAY=`date +%Y%m%d -d"1 day ago"`
export XDAY=`date +%Y%m%d -d"14 day ago"`
export Y2DAY=`date +%Y%m%d -d"2 day ago"`
export filename=o5_demo_$YDAY.dat.gz.pgp
export filename2=o5_demo_$YDAY.dat.gz
export filename3=o5_demo_$YDAY.dat
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE} ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
#################################################################
##Update Runstats Start
#################################################################
#################################################################
sqlplus -s -l  ${CONNECTDW} <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#################################################################
echo "Starting FTP pull process for demo file " > ${LOG_FILE}

cd ${DATA}
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>>${LOG_FILE}
cd fromcheetah
get $filename2 $DATA/$filename2
bye
EOF
wait
# Decrypt Cheetah Mail data files
#gpg  --no-tty --batch --passphrase-fd < $HOME/email_pass.file --decrypt $DATA/$filename
wait
gunzip $DATA/$filename2
# FTP decrypted Cheetah Mail data files to SDW

mv $DATA/$filename3  $DATA/o5_email_cheetah_demo.dat

echo "Finished FTP pull process for demo file\n " >> ${LOG_FILE}
#################################################################

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  ${CONNECTDW} <<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
###############################################################
if [ `egrep -c "^ERROR|ORA-|not found|failed|Failure writing network stream|No such file or directory|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
