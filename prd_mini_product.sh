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
. $HOME/params.conf $1
export BANNER=$1
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='prd_mini_product'
export LOG_FILE="$LOG/${BANNER}_${PROCESS}_log.txt"
export JOB_NAME='PRD_LOAD'
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${BANNER}_${PROCESS}.sql'
export FILE_NAME='bi_mini_product table'
export SFILE_SIZE=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export LOAD_COUNT=0

set -x
########################################################################
##Initialize Email Function
########################################################################
if [ "${BANNER}" == "s5a" ];
then
export SCHEMA="mrep."
export mini_prd_table="MV_BI_MINI_PRODUCT"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
export mini_prd_table="MV_O5_BI_MINI_PRODUCT"
fi

########Run the stats####################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
########################################################################################
echo "Running the script started at `date '+%a %b %e %T'`" >${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL} "${SCHEMA}" "${BANNER}" "${mini_prd_table}">>${LOG_FILE}
echo "running the ${BANNER}_${PROCESS} statments completed  at `date '+%a %b %e %T'`" >>${LOG_FILE}
########################################################################################
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${BANNER}_${PROCESS} failed. Please investigate"
echo "${BANNER}_${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
else
echo "${BANNER}_${PROCESS} completed without errors."
##Update Runstats Finish
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
echo "${BANNER}_${PROCESS} completed without errors." >> ${LOG_FILE}
exit 0
###################################################################################################
fi
