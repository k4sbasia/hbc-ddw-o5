#!/bin/ksh
#-----------------------------------------------------------------------
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Runs email segments and ftps the extract to CheetahMail
#####
#####
#####
#####   CODE HISTORY :                     Name                    Date            Description
#####                                   ------------            ----------      ------------
#####					Unknown			Unknown			Created
#####                                   Divya Kafle		12/16/2011     		Modified
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export PROCESS='o5_edb_cheetah_segments'
export DATA=$HOME/DATA
export LOG=$HOME/LOG
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='o5_cheetah_segments_file.csv'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SQL="$HOME/SQL"
export SQL1='${PROCESS}_myacct_to_checkout'
export SQL2="${PROCESS}_load"
export SQL3="${PROCESS}2_load"
export SQL4="${PROCESS}_file"

################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^9'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#################################################################
echo "edb cheetah segments started at `date '+%a %b %e %T'`\n" > ${LOG_FILE}
#################################################################
rm -f ${DATA}/${FILE_NAME}*
#rm ${DATA}/${FILE_NAME}
#  Run the sql script that performs update
#################################################################
##echo "running my accounts to checkout at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
##sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${SQL1}.sql >> ${LOG_FILE}
##EOF

echo "running cheetah segment at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${SQL2}.sql >> ${LOG_FILE}
EOF

echo "running cheetah segment2 at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${SQL3}.sql >> ${LOG_FILE}
EOF

#echo "cheetah segment spool started at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
#sqlplus -s $CONNECTDW  @${SQL}/${SQL4}.sql > ${DATA}/${FILE_NAME}
#################################################################
#echo "zipping the segment file at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
#gzip ${DATA}/${FILE_NAME}
#wait
#################################################################
echo "edb Cheetahmail Segmentation complete and ended at `date '+%a %b %e %T'`\n" >> ${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_end.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
