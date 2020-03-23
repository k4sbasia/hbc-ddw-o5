#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_prodsumload_psa.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql scripts that populates the PSA tables
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####                                   Unknown                         Unknown         Created
#####                                   Rajesh Mathew           05/18/2010      Modified
#####									Rajesh Mathew           10/21/2011      Modified to add biitemadj here
##### 
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='o5_prodsumload_psa'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export TODAY=`date +%Y%m%d`
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export BAD_SUBJECT="${PROCESS} failed"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export SFILE_SIZE='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SQL1='o5_psatotal'
export SQL2='o5_psawhse'
export SQL3='o5_psastore'
export SQL4='o5_biitmseladj'
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
#################################################################
echo -e "Prodsumload_psa Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
##Update Runstats Start
#################################################################
export JOB_NAME="${SQL1}"
export SCRIPT_NAME="${SQL1}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the psatotal.sql script
#################################################################
echo -e "O5 PSATOTAL Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL1}.sql >> ${LOG_FILE}
#################################################################
echo -e "O5 PSATOTAL Load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT="`sqlplus -s -l  <<EOF
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
select count(*) from O5.BI_PSA a
where trunc(add_dt)=trunc(sysdate);
exit
EOF`"
echo -e "Total Count from O5.BI_PSA for todays Load is: $TARGET_COUNT \n" >>${LOG_FILE}
#################################################################
# Update the runstats for psatotal.sql
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
#################################################################
##Update Runstats Start
#################################################################
export JOB_NAME="${SQL2}"
export SCRIPT_NAME="${SQL2}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the psawhse.sql script
#################################################################
echo -e "PSAWHSE Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL2}.sql >> ${LOG_FILE}
#################################################################
echo -e "PSAWHSE Load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT="`sqlplus -s -l  <<EOF
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
select count(*) from O5.BI_PSA_WH a
where trunc(add_dt)=trunc(sysdate);
exit
EOF`"
echo -e "Total Count from O5.BI_PSA_WH for todays Load is: $TARGET_COUNT \n" >>${LOG_FILE}
#################################################################
# Update the runstats for psawhse.sql
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
#################################################################
##Update Runstats Start
#################################################################
export JOB_NAME="${SQL3}"
export SCRIPT_NAME="${SQL3}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the psastore.sql script
#################################################################
echo -e "PSASTORE Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL3}.sql >> ${LOG_FILE}
#################################################################
echo -e "PSASTORE Load ENDED at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT="`sqlplus -s -l  <<EOF
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
select count(*) from O5.BI_PSA_STORES a
where trunc(add_dt)=trunc(sysdate);
exit
EOF`"
echo -e "Total Count from O5.BI_PSA_STORES for todays Load is: $TARGET_COUNT \n" >>${LOG_FILE}
#################################################################
# Update the runstats for psastore.sql
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
#################################################################
##Update Runstats Start
#################################################################
export JOB_NAME="${SQL4}"
export SCRIPT_NAME="${SQL4}"
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${JOB_NAME}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# call the biitmseladj.sql script
#################################################################
echo -e "O5 BIITMSELADJ Load started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL4}.sql >> ${LOG_FILE}
#################################################################
echo -e "O5 BIITMSELADJ Load ENDED at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##################################################################
TARGET_COUNT="0"
#################################################################
# Update the runstats for biitemseladj.sql
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
echo -e "O5 Prodsumload_psa Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit 0
