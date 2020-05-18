#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_ppe_cheetah_16days_extract.sh
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_ppe_cheetah_16days_extract'
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
SQL1='o5_ppe_cheetah_xml_extract_16days'
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
#################################################################
#################################################################
##Update Runstats Start
#################################################################
sqlplus -sl $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "o5_ppe_cheetah_16days_extract Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
echo -e "Starting the off5th ppe xml data extract fpr 16 days `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
################################################################
sqlplus -s -l $CONNECTDWXML @${SQL}/${SQL1}.sql>> ${LOG_FILE}
#################################################################
sqlplus -s -l $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#Pull the data from 145 box
#################################################################
echo -e "copying the o5 ppe data from 145 to 101 at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
scp cognos@$ORACLESRV:/oracle/EXPORTS/dataservices/Off5th_ppe_`date +%Y%m%d`.xml $DATA
wait
echo -e "Finished copying the data from oracle server at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
echo -e "o5_ppe_cheetah_16days_extract Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
cp "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
else
export SUBJECT="SUCCESS:Off5th PPE DAILY DATA IS PRODUCED AND copied 145-101-30 and READY FOR FURTHER PROCESS"
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
exit 0
fi
