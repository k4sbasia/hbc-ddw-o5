#!/usr/bin/ksh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This script ftps the unused welcome promo code  to cheetah
#####
#####
#####
#####   CODE HISTORY :                   Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle	         03/04/2014      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='o5_edb_unused_welcomepromo_ftp'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export today=${today:-$(date +%Y%m%d)}
export FILE_NAME="o5_used_welcomepromo_${today}.csv"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
################################################################
################################################################

echo "${PROCESS} started" > ${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
####FTP File
#################################################################
cd $DATA
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>${LOG_FILE} 
cd autoproc
put "${FILE_NAME}"
quit
EOF

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
exit $?
