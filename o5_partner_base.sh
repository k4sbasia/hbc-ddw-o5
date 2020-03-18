#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_partner_base.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for building the BI partner base
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Unknown                 Unknown         Created
#####                   Kanhu C Patro           06/25/2018      SQL Modification for Performance
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_partner_base'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export SFILE_SIZE='0'
export FILE_NAME='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
########################################################################
##Initialize Email Function
########################################################################
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
export PART_TABLE="BI_PARTNERS_EXTRACT_WRK"
export OMS_RFS_STG_TAB="OMS_RFS_SAKS_STG"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
export PART_TABLE="O5_PARTNERS_EXTRACT_WRK"
export OMS_RFS_STG_TAB="OMS_RFS_O5_STG"
fi
#############################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @$HOME/SQL/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "bi_partner_base build Process started at `date '+%a %b %e %T'`" >${LOG_FILE}
#########################################################################
#  Run the sql script that performs the product info extract
#################################################################
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL} "${BANNER}" "${SCHEMA}" "${PART_TABLE}" "${OMS_RFS_STG_TAB} >>${LOG_FILE}
echo "o5_partner_base PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
# Get the COUNT from the table
#################################################################
TARGET_COUNT=`sqlplus -s -l  $CONNECTDW "${SCHEMA}" "${PART_TABLE}"<<EOF
set heading off
select count(*)
from &1.&2
WHERE   wh_sellable_qty > 0;
quit;
EOF`
echo "The Target record count is : $TARGET_COUNT" >> ${LOG_FILE}
if [ "$TARGET_COUNT" = 0 ]
then
echo "Partner Base Load Failure `date`" >> ${LOG_FILE}
echo "Partner Base Load Failure `date`" | mailx -s "Partner Base Table load failed.  Please investigate." hbcdigtialdatamanagement@hbc.com
fi
################################################################
##Update Runstats Finish
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
##Update Runstats Finish
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################################################
fi
exit 0
