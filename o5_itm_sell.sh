#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME :o5_itm_sell.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1.MERGE THE  
#####
#####   CODE HISTORY :                   Name                     Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Jayanthi Dudala              10/20/2011      Created
#####
#############################################################################################################################
. $HOME/params.conf o5
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='o5_itm_sell'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
#################################################################################################################################
########Run the stats############
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "Calling the o5_itm_sell.sql script to merge the fact and o5.item_sell tables" >${LOG_FILE}
sqlplus -s $CONNECTDW @${EXTRACT_SQL} >>${LOG_FILE}
echo "Extract File Completed at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
################################################################
##Bad Records Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
