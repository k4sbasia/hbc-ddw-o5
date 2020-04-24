#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_inventory_merge.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Produces the image xml for O5
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####                   Ishavpreet Singh        01/01/2020
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
export PROCESS='o5_inventory_merge'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export DATE=`date +%Y%m%d%H%M`
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export ENV=$1
export load_type=$2
export SLEEP_TIME=120
export RUN_DATE_EXPR="TO_DATE('`date +"%Y%m%d"`','YYYYMMDD')"
echo "Started Job :: ${PROCESS} " >${LOG_FILE}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF >${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
 echo "Start Merge in $CONNECTDW" >> ${LOG_FILE}
####################################################################################

sqlplus -s -l $CONNECTDW @SQL/${PROCESS}.sql >> ${LOG_FILE}
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in merging inventory data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Inventory data loaded for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi

echo "Start Store Inventory Merge in $CONNECTDW" >> ${LOG_FILE}
sqlplus -s -l $CONNECTDW @SQL/o5_inv_str_merge.sql >> ${LOG_FILE}
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in merging store inventory data for process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Store Inventory data loaded for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
##
echo "${PROCESS} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
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
