#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : bay_sfcc_image.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Produces the image xml for SFCC
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####                   Ishavpreet Singh         20/02/2019
#####
#####
##################################################################################################################################
set -x
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='sfcc_prod_product_delta'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export FILE_NAME="image_bay_`date +%Y%m%d%H%M`_11.xml"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export ENV=$1
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

########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF >${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
sqlplus -s -l $CONNECTDW @SQL/${PROCESS}.sql > ${LOG_FILE}
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in product data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Product data loaded for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
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
fi

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF >${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
