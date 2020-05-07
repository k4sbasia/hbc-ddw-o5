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
#####   CODE HISTORY :	Name				Date		Description
#####					------------		----------	------------
#####					Unknown				Unknown		Created
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
export SQL_FILE='promo_process'
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
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
sqlplus -s -l  $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo -e "Run SQL To Populate Promo Tables at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL_FILE}.sql "${SCHEMA}" >>${LOG_FILE}
echo -e "Populate Promo Tables Completed at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
sqlplus -s -l  $CONNECTDW<<EOF > ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
echo -e "BI_PROMO_PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
    echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
    export SUBJECT=${BAD_SUBJECT}
    exit 99
else
    echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
