#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME :o5_mv_bisale_refresh.sh 
#####
#####   DESCRIPTION  : This script refreshes mv_bi_sale materialized view 
#####
#####   CODE HISTORY :	Name				Date		Description
#####					------------		----------	------------
#####                                   Jayanthi Dudala         05/24/2012      Modified
#############################################################################################################################
. $HOME/initvars
################################################################
##Control File Variables
export PROCESS='o5_mv_bisale_refresh'
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
########################################################################
echo -e "Refresh PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
########################################################################
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^9'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Refrsh the MV_BI_SALE MV
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql >> ${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
# Get the COUNT from the table
#################################################################
TARGET_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select nvl(sum(demand_dollars),0) from sddw.mv_bi_sale 
  where orderdate between trunc(sysdate-1) and trunc(sysdate); 
quit; 
EOF`
echo -e "The target count for yesterday's data is : $TARGET_COUNT\n" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
# Check for errors
################################################################
echo -e "PROCESS Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
if [ `egrep -c "^ERROR|ORA-|not found" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
###################################################################
fi
exit 0

