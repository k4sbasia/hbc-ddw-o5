#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_feed_ls_sales_cancel_return.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. THe linkshare sales-cancel/return data is produced
#####                              2. FTP the same to linkshare
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Rajesh Mathew           12/28/2010      Modified
#####                                   Jayanthi             Added Austrialian transactions to Linkshare
#####
#############################################################################################################################
. $HOME/initvars
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_ls_sales_cancel_return'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL1="$SQL/o5_ls_sales_cancel_return_US_Extract.sql"
export SFILE_SIZE=0
export FILE_NAME="$DATA/.lstrans_cancels_US_`date +%Y%m%d`_OFF"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export AUDIT_SQL="$SQL/o5_link_share_return_audit.sql"
########################################################################
echo "PROCESS to produce O5 data file for cancelled/return sales to LS started at `date '+%a %b %e %T'`" >${LOG_FILE}
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
##################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
echo "Started extracting data at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL1} >$DATA/.lstrans_cancels_US_`date +%Y%m%d`_OFF
TARGET_COUNT=`cat ${FILE_NAME} | wc -l`
wait
echo "Finished o5 extracting data at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
##FTP file to ftp.saksdirect.com
echo "Started copying the data to filerepo at `date '+%a %b %e %T'`" >>${LOG_FILE}
#cp $DATA/.lstrans_cancels_US_`date +%Y%m%d`_OFF /home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US/.lstrans_cancels_`date +%Y%m%d`_OFF 
wait
echo "Finished copying the data to filerepo at `date '+%a %b %e %T'`" >>${LOG_FILE}
###############################################################
##invoke the perl script to process the file which is moved to filerepo server
###############################################################
#ssh -l ftservice filerepo.saksdirect.com '/home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US/run_lstrans.pl /home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US/'
wait
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#audit Email
#################################################################
sqlplus -s -l  $CONNECTDW @${AUDIT_SQL} >$LOG/o5_link_share_return_audit.log
#cat $LOG/o5_link_share_return_audit.log | mailx -s  "Off 5th Link Share Return processed on `date +%Y%m%d`" hbcdigtialdatamanagement@hbc.com AffiliateTeamList@s5a.com ls-saks@linkshare.com
#################################################################
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "O5 LS_Cancels_file PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit 0 
