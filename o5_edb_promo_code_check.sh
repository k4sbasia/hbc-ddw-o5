#!/bin/ksh
#############################################################################################################################
#####                           SAKS Direct
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_promo_code_check.sh
#####
#####   DESCRIPTION  : This job checks the number of unused welcome_promo and alerts if unused promocodes are less than 50000
#####
#####
#####
#####   CODE HISTORY :  Name            Date          Description
#####                   ------------    ----------    ------------
#####         		Divya Kafle     11/05/2013    Created Script
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export PROCESS='o5_edb_promo_code_check'
export SQL=$HOME/SQL
export CTL=$HOME/CTL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SQL_FILE="${PROCESS}"
export SQL_FILE2="o5_edb_barcode_code_check"
export DATA_FILE="${DATA}/${PROCESS}_report.txt"
export DATA_FILE2="${DATA}/${SQL_FILE2}_report.txt"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export TARGET_COUNT1=0
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
echo "${PROCESS} started." > ${LOG_FILE}
#################################################################
##Generate report and email to Saks Direct Data management
#################################################################
sqlplus -s $CONNECTDW  @${SQL}/${SQL_FILE}.sql > ${DATA_FILE}
sqlplus -s $CONNECTDW  @${SQL}/${SQL_FILE2}.sql > ${DATA_FILE2}
################################################################
TARGET_COUNT=`cat ${DATA_FILE}`
TARGET_COUNT1=`cat ${DATA_FILE2}`
echo "TARGET_COUNT:${TARGET_COUNT}"
echo "TARGET_COUNT1:${TARGET_COUNT1}"
#######################################
#########################
if  [$TARGET_COUNT -lt 100000 ] | [$TARGET_COUNT1 -lt 100000 ]
then
(echo "ATTENTION: There are less than 100000 unused welcome promopins/barcodes available!") | mailx -s "Available welcome Promopins/store barcode check" hbcdigtialdatamanagement@hbc.com josh_pratt@s5a.com Nivy_Swaminathan@s5a.com rachel_barret@s5a.com elizabeth_williams@s5a.com erin_melia@s5a.com
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
else
echo "No. of unused welcome_promo: ${TARGET_COUNT}" >> ${LOG_FILE}
echo "No. of unused store barcode: ${TARGET_COUNT1}" >> ${LOG_FILE}
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
exit $?
