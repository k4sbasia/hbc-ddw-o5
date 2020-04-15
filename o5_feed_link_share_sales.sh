#!/usr/bin/ksh
#############################################################################################################################
####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_feed_link_share_sales.sh    
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Ftp the sales file from omniture
#####				   2. Process the file and sent the extract to LS
#####
#####
#####
#####   CODE HISTORY :  		Name                   	Date            Description
#####                                   ------------            ----------      ------------
#####					Unknown			Unknown		Created
#####                                   Rajesh Mathew           05/24/2011      Modified
#####                                   Jayanthi Dudala	        07/05/2011      Modified Added new field "site_id"  
#####                                   Nilima Mehta        01/13/2017      Modified for looking .zip file
#############################################################################################################################
################################################################
#. $HOME/initvars
. $HOME/params.conf o5
export PROCESS='o5_feed_link_share_sales'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export TODAY=`date +%Y%m%d`
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export EXTRACT_FILE='o5_link_share_sales_extract'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$LOG/${PROCESS_ctl}.log"
export BAD_FILE="$HOME/OUTFILE/o5_link_share_sales.bad"
export FILE="AFF_Orders_`TZ=GMT+24 date +"%Y%m%d"`a_OFF.csv"
export FILE_ZIP="AFF_Orders_`TZ=GMT+24 date +"%Y%m%d"`a_OFF.zip"
export YDAY_FILE=`date --date='30 days ago' +AFF_Orders_"%Y%m%d"a_OFF.csv`
export YDAY_FILE2=`date --date='30 days ago' +sakscomlive_"%Y-%m-%d"_OFF.tar.gz`
export FILEB="AFF_Orders_`TZ=GMT+24 date +"%Y%m%d"`b_OFF.csv"
export YDAY_FILEB=`date --date='3 days ago' +AFF_Orders_"%Y%m%d"b_OFF.csv` 
export BAD_SUBJECT="${PROCESS} failed"
export EXTRACT_SQL='$SQL/o5_link_share_sales.sql'
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME=$DATA/$FILE
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export AUDIT_SQL='$SQL/o5_link_share_sales_audit.sql'
export SLEEP_TIME='1200'
export COUNT=9
export CTR=0
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /export/home/cognos/email_distribution_list.txt|grep '^9'|while read group address
 do
 echo "${SUBJECT}. The ${PROCESS} had ${ROW_CNT} bad record(s). ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}

##################################################################
echo "O5 Linkshare Sales started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
echo "FTP the data file from O5 Omniture started at `date '+%a %b %e %T'`" >>${LOG_FILE}
##FTP File
while true ;
do
cd $DATA
## Look for .zip file first on server - added by Nilima on 01/13/2017
ftp -nv ftp2.omniture.com<<EOF>>$LOG_FILE
user saksdatafeed PFsfelvb
binary
get "$FILE_ZIP"
prompt off
quit
EOF
cd $DATA
if [ -a $FILE_ZIP ]
then
echo "Omniture $FILE_ZIP is available  `date '+%a %b %e %T'`">>${LOG_FILE}
unzip $FILE_ZIP
if [ -a $FILE ]
then
FILE_NAME=$DATA/$FILE
echo "Omniture $FILE_NAME is available and process is starting `date '+%a %b %e %T'`">>${LOG_FILE}
break;
fi
fi
############################################
cd $DATA
ftp -nv ftp2.omniture.com<<EOF>>$LOG_FILE
user saksdatafeed PFsfelvb
get "$FILE"
prompt off
delete "$YDAY_FILE"
delete "$YDAY_FILE2"
quit
EOF
#################################################################
##Check if the file A exsists in SERVER A,if not wait for 3 hrs checking every 20mts it the file is not present,fianally look for File B in second server
#################################################################
if [ -a $FILE ]
then
FILE_NAME=$DATA/$FILE
echo "FILE_NAME $FILE_NAME" >>${LOG_FILE}
echo "Omniture $FILE_NAME is available and process is starting `date '+%a %b %e %T'`">>${LOG_FILE}
break;
else
CTR=$(expr ${CTR} + 1)
if [ ${CTR} -ge ${COUNT} ]
then
echo "Getting the omniture file B and starting the process`date '+%a %b %e %T'`">>${LOG_FILE}
ftp -nv ftp.omniture.com<<EOF>>$LOG_FILE
user saks5thave uGXYkeN0
get "$FILEB"
prompt off
quit
EOF
mv $FILEB $FILE
break;
else
echo "Link Share Sales File is not available `date '+%a %b %e %T'`">>${LOG_FILE}
echo "Process is sleeping at `date '+%a%b%e%T'`">>${LOG_FILE}
sleep ${SLEEP_TIME}
fi
fi
done
#################################################################
##delete the yesterdays files in Server 2
#################################################################
ftp -nv ftp.omniture.com<<EOF>>$LOG_FILE
user saks5thave uGXYkeN0
prompt off
delete "$YDAY_FILEB"
echo "deleted yesterday file B from ftp.omniture.com server">>${LOG_FILE}
quit
EOF
#################################################################
##Update Runstats Start
#################################################################
FILE_COUNT=`wc -l $FILE_NAME|awk '{printf("%s\n",$1)}'`
echo " The count is : $FILE_COUNT " >>${LOG_FILE}
########Run the stats############
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Load Link Share Sales Data into Staging 
#################################################################
echo " Loading the file into the staging table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CTL_LOG BAD=$BAD_FILE DATA=$FILE_NAME ERRORS=99999999 SKIP=1 
cat $CTL_LOG >>${LOG_FILE}
################################################################@
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
##Extract LS Trans File
#################################################################
echo "Extract File and copying data to history table Starting at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/o5_link_share_sales_update.sql  >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/o5_link_share_sales_US.sql >$DATA/.lstrans_US_OFF
wait
echo "Extract Files for Off 5th US Completed at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
################################################################
## Checking error in data file before posting to Linkshare
if [ `egrep -c "^ERROR|ORA-|not found" $DATA/.lstrans_US_OFF` -ne 0 ]
then
echo "${PROCESS} failed. Error in /home/cognos/DATA/.lstrans_US_OFF file " >> ${LOG_FILE}
exit 99
else
cp $DATA/.lstrans_US_OFF /home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US/.lstrans
wait
fi
echo "Copied the files to Linkshare respective folders" >>${LOG_FILE}
#added new ftserive server to run the .perl script and copy the lstrans file to filerep
ssh -l ftservice filerepo.saksdirect.com '/home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US/run_lstrans.pl /home/ftservice/OUTGOING/LinkShare_OFF5TH/Linkshare_OFF5TH_US'
wait
cd $DATA
#rm -f $YDAY_FILE
#################################################################
##Audit Email
#################################################################
sqlplus -s -l  $CONNECTDW @${AUDIT_SQL} >$LOG/o5_link_share_sales_audit.log
cat $LOG/o5_link_share_sales_audit.log | mailx -s  "Off 5th Link Share Sales Audit `date +%Y%m%d`" jayanthi_dudala@saksinc.com hbcdigtialdatamanagement@hbc.com AffiliateTeamList@s5a.com ls-saks@linkshare.com
echo "Delete data from staging table Starting at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/o5_link_share_sales_del_stg.sql  >>${LOG_FILE}
echo "Delete data from staging tableEnded at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
#################################################################
##Bad Records Check
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
