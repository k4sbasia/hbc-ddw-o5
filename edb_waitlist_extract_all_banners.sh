#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : edb_waitlist_extract_dev
#####
#####   DESCRIPTION  : This script does the following
#####                              1. This script extracts waitlisted items that are have intertory available now
#####                              2. and generates xml file to send to CM
#####
#####
#####
#####   CODE HISTORY :                  Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Sripriya Rao	        11/19/2015      created
#####
#############################################################################################################################
################################################################
. $HOME/initvars
export BANNER=$1
export ENV=$2
export PROCESS='edb_waitlist_extract_all_banners'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_${BANNER}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export today=`date +%Y%m%d`
export SAKS_FILE="waitlist_notification_${today}.xml"
export O5_FILE="o5_waitlist_notification_${today}.xml"
#export SQLXML='edb_waitlist_cm_extract_xml'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export BATCH_NO='0'
export BATCHFILE="$LOG/waitlist_nextval.txt"
################################################################
##Initialize Email Function
################################################################


function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^3'|while read group address
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
##DB SQL
#################################################################
echo "${PROCESS} started for ${BANNER} in $ENV" > ${LOG_FILE}


if [ "${BANNER}" == "saks" ]
then
        SCHEMA="mrep."
        FILE=${SAKS_FILE}
	export SQL_FILE="edb_waitlist_extract_all_bann"
	export SQLXML='edb_waitlist_cm_extract_xml'


else
        export SCHEMA="o5."
        FILE=${O5_FILE}
	export SQL_FILE="o5_edb_waitlist_extract_all_bann"
        export SQLXML="edb_waitlist_cm_extract_xml_all_bann"

fi


echo  $SCHEMA >>${LOG_FILE}



sqlplus -s -l  <<EOF> ${BATCHFILE}
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
SELECT ${SCHEMA}EDB_WAITLIST_EXTRACT_HIS_SEQ.NEXTVAL FROM DUAL;
quit
EOF

BATCH_NO=`cat ${BATCHFILE}`
cat ${BATCHFILE} >> ${LOG_FILE}

echo "Batch_no is: " $BATCH_NO >> ${LOG_FILE}

rm ${BATCHFILE}

#echo sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql "$BMCONNECTION" "$BATCH_NO" >> ${LOG_FILE}
sqlplus -s -l  $CONNECTDW <<EOF>> ${LOG_FILE} @${SQL}/${SQL_FILE}.sql  "$BATCH_NO" >> ${LOG_FILE}
EOF
echo "staring xml spool" >> ${LOG_FILE}
sqlplus -s $CONNECTDWXML  @${SQL}/${SQLXML}.sql "$SCHEMA"
#################################################################
#Pull the data from 145 box
#################################################################
echo -e "copying the ppe data from 145 to 101 " >>${LOG_FILE}
#scp cognos@192.168.7.145:/oracle/EXPORTS/dataservices/${FILE} $DATA
echo scp cognos@$ORACLESRV:/oracle/EXPORTS/dataservices/${FILE} $DATA
scp cognos@$ORACLESRV:/oracle/EXPORTS/dataservices/${FILE} $DATA
wait
echo -e "Finished copying the data from 145 " >>${LOG_FILE}
echo "Process completed" >> ${LOG_FILE}
#################################################################

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|failed|invalid identifier|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
else
echo "${PROCESS} completed without errors" >> ${LOG_FILE}
fi
