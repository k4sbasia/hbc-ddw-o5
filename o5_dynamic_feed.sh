#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_dynamic_feed.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Produces the image xml for O5
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####                   Adrian Tiu         01/01/2020
#####
#####
##################################################################################################################################
set -x
. $HOME/params.conf bay
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_dynamic_feed'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export DATE=`date +%Y%m%d%H%M`
export FLAGS_FILE_NAME="dynamic_flags_o5_${DATE}.xml"
export FLAGS_FILE_ZIP="dynamic_flags_o5_${DATE}.zip"
export CAT_FILE_NAME="dynamic_categories_feed_o5_${DATE}.xml"
export CAT_FILE_ZIP="dynamic_categories_feed_o5_${DATE}.zip"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export ENV=$1
export load_type=$2
export SLEEP_TIME=120
echo "Started Job :: ${PROCESS} " >${LOG_FILE}
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
function PRICE_FILE_CHECK {
DONE_PROCESS_CHECK="`sqlplus -S <<EOF
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
select ${DW_USER}price_load.fileCheck${load_type} from dual;
quit;
EOF`"
}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF >${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
 echo "Going to do price file check in $CONNECTDW" > ${LOG_FILE}
####################################################################################
while true ;
do
PRICE_FILE_CHECK
echo "$DONE_PROCESS_CHECK for check" >>${LOG_FILE}
echo -e "***********process completion Check Started  `date +%m/%d/%Y-%H:%M:%S`\n">>${LOG_FILE}
if [ $DONE_PROCESS_CHECK -gt 0 ]
then
    #echo -e "AMS prices published and process is starting `date +%m/%d/%Y-%H:%M:%S`\n">>${LOG_FILE}
sqlplus -s -l $CONNECTDW @SQL/${PROCESS}_load.sql >> ${LOG_FILE}
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in product data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Product data loaded for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
sqlplus -s -l $CONNECTDWXML @SQL/${PROCESS}_flag.sql ${DATE} >> ${LOG_FILE}
#sqlplus -s -l $CONNECTPRODSDWXML @SQL/${PROCESS}_flag_parent.sql ${DATE} >> ${LOG_FILE} #commented as change to process at variant level inplace
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in flag data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "flag data created for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi

sqlplus -s -l $CONNECTPDWOPXML @SQL/${PROCESS}_cat.sql ${DATE} >> ${LOG_FILE}
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in category data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "category data created for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
scp cognos@hd1prc15na.digital.hbc.com:/oracle/EXPORTS/dataservices/${FLAGS_FILE_NAME} DATA/
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "Error in copying flags file for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Flags File copied for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
scp cognos@hd1prc15na.digital.hbc.com:/oracle/EXPORTS/dataservices/${CAT_FILE_NAME} DATA/
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "Error in Category copying file for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Category File copied for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
FILE_COUNT=`grep -o '<product' ${DATA}/${FLAGS_FILE_NAME} | wc -l`
FILE_COUNT_CAT=`grep -o '<category-assignment' ${DATA}/${CAT_FILE_NAME} | wc -l`
if  [ $FILE_COUNT -gt 100 ] && [ $FILE_COUNT_CAT -gt 1000 ]
then
echo -e  "Number of Products to update flags :$FILE_COUNT assignments: $FILE_COUNT_CAT `date '+%a %b %e %T'`\n">>${LOG_FILE}
cd ${DATA}
zip -9 ${FLAGS_FILE_ZIP} ${FLAGS_FILE_NAME}
zip -9 ${CAT_FILE_ZIP} ${CAT_FILE_NAME}
sftp -o "IdentityFile=~/.ssh/${SFCC_NON_KEY}" ${SFCC_NON_USER}@sftp.integration.awshbc.io <<< "put ${DATA}/${FLAGS_FILE_ZIP} sfcc-inbound/catalog/products"
sftp -o "IdentityFile=~/.ssh/${SFCC_NON_KEY}" ${SFCC_NON_USER}@sftp.integration.awshbc.io <<< "put ${DATA}/${CAT_FILE_ZIP} sfcc-inbound/catalog/assignments"
sqlplus -S $CONNECTDW<<EOF
UPDATE   JOB_STATUS set last_run_on =LAST_COMPLETED_TIME,  LAST_COMPLETED_TIME= sysdate where process_name='O5_DYNAMIC';
UPDATE   JOB_STATUS set last_run_on =LAST_COMPLETED_TIME,  LAST_COMPLETED_TIME= sysdate where process_name='O5_DYNAMIC_ASSGN';
COMMIT;
quit;
EOF
##
echo "${PROCESS} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo -e  "Too less products job will end Flags: $FILE_COUNT Assignments : $FILE_COUNT_CAT, check if valid `date '+%a %b %e %T'`\n">>${LOG_FILE}
exit 99
fi
 break
else
        echo "The AMS Web Price Data (${load_type}) is not available.  Load Process is sleeping for 2 minutes. - `date +%m/%d/%Y-%H:%M:%S`" >>${LOG_FILE}
fi
sleep ${SLEEP_TIME}
done
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF >${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate." >> ${LOG_FILE}
exit 1
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors." >> ${LOG_FILE}
