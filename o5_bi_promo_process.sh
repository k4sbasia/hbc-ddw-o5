#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_bi_promo_process.sh
#####
#####   DESCRIPTION  : This script does the following
#####				   1. Calls the sql script that peforms parsing the promo info
#####				   2. Calls the sql script that updates the promo info
#####
#####
#####
#####   CODE HISTORY :	Name				Date		Description
#####					------------		----------	------------
#####					Unknown				Unknown		Created
#####					Rajesh Mathew		07/13/2010	Modified
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
################################################################
###extract promo, orders from bi sale and build sddw promo sale table
################################################################
##Control File Variables
export PROCESS='o5_bi_promo_process'
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
export SQL1='o5_bi_promo_parse'
export SQL2='o5_bi_promo_update'
export BANNER=$1
########################################################################
echo -e "BI_PROMO_PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^9'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
if [ "${BANNER}" == "saks" ]
then
export SCHEMA="mrep."
fi
if [ "${BANNER}" == "o5" ]
then
export SCHEMA="o5."
fi
#################################################################
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo -e "extract and parse o5 promo id from bi sale"
echo -e "Creation of the data file started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL1}.sql "${SCHEMA}" >$DATA/o5_bi_promo.txt
echo -e "Creation of the data file ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
#################################################################
# Get the file stats
#################################################################
if [ -e ${DATA}/o5_bi_promo.txt ]
then
export FILE_NAME=o5_bi_promo.txt
TFILE_SIZE="`ls -ll ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`"
FILE_COUNT="`wc -l ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`"
fi
#################################################################
echo -e "load parse o5 promo to work file \n" >> ${LOG_FILE}
$HOME/o5_bi_promo_parse_ld.sh> o5_bi_promo_parse_ld.out
wait
echo -e "Finished loading parse o5 promo to work file\n" >> ${LOG_FILE}
cat $LOG/bi_promo_parse_ld.log>>${LOG_FILE}
###############################################################
echo -e "Update promo actvities\n" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL2}.sql >> ${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
echo -e "BI_PROMO_PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
