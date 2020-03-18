#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME :o5_prd_mini_product.sh
#####
#####   DESCRIPTION  : This script does the following
#####   CODE HISTORY :                   Name                     Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Jayanthi Dudala              10/17/2011      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='o5_prd_mini_product'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME='PRD_LOAD'
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export FILE_NAME='bi_mini_product table'
export SFILE_SIZE=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export LOAD_COUNT=0
export BANNER=$1
set -x
########################################################################
##Initialize Email Function
########################################################################
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
fi

########Run the stats####################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
########################################################################################
echo "Running the script started at `date '+%a %b %e %T'`" >${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL} "${SCHEMA}" "${BANNER}" >>${LOG_FILE}
echo "running the o5_prd_mini_product statments completed  at `date '+%a %b %e %T'`" >>${LOG_FILE}
########################################################################################
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
##Update Runstats Finish
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
###################################################################################################
fi
