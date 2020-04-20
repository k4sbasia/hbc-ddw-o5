#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_ppe_cheetah_data_load_extract.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for building the BI partner base
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            		----------      ------------
#####                                   Divya Kafle   06/02/2014      Created
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_ppe_cheetah_data_load_extract'
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
SQL1='o5_ppe_cheetah_data_load'
SQL2='o5_ppe_cheetah_xml_extract'
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
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "o5_ppe_cheetah_data_extract_load Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
#  Run the sql script that performs the data load
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL1}.sql>> ${LOG_FILE}
##################################################################
# Check for the data load
#################################################################
if [ $? -ne 0 ] || [ `egrep -c "^ERR|ORA-|not found|SP2-0" ${LOG_FILE}` -ne 0 ]
 then
echo -e "FAILURE - o5_ppe_cheetah_data_load  `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo -e "SUCCESS - o5_ppe_cheetah_data_load `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
fi
#################################################################
#  get the target count
#################################################################
TARGET_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*)
from o5.BV_CHEETAH_EXTRACT
WHERE item_exclude='F' and email is not null and product_id is not null
and trunc(add_dt) = TRUNC (SYSDATE);
quit;
EOF`
################################################################
echo -e "The Target record count is : $TARGET_COUNT" >> ${LOG_FILE}
echo -e "Starting the off5th ppe xml data extract `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
################################################################
sqlplus -s -l  $CONNECTDWXML @${SQL}/${SQL2}.sql>> ${LOG_FILE}
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#Pull the data from 145 box
#################################################################
echo -e "copying the o5 ppe data from 145 to 101 at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
scp cognos@$ORACLESRV:/oracle/EXPORTS/dataservices/Off5th_ppe_`date +%Y%m%d`.xml $DATA
wait
echo -e "Finished copying the data from 145 to 101 at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
echo -e "o5_ppe_cheetah_data_extract_load Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
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
