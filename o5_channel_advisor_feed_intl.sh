#!/usr/bin/ksh

#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_channel_advisor_feed_intl.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Tuned o5_feed_channel_advisor.sh and recreated this script.
#####
#####
#####   CODE HISTORY :  Name                Date            Description
#####                   ------------        ----------      ------------
#####                   KALLAAR                         03/30/2017      Created
#####                   KALLAAR                         04/07/2017      Removed FTP to ShopAmex
#####                   Sripriya Rao                    07/31/2017      sftp to FLIPP added
#####
#############################################################################################################################

. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_channel_advisor_feed_intl'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export PROCESS_SQL1='o5_channel_advisor_extract.sql'
export PROCESS_SQL2='o5_channel_advisor_export_intl.sql'
export SFILE_SIZE=0
export FILE_NAME="$DATA/CA_o5_feed_intl_`date +"%Y%m%d"`.txt"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export BBODY=""
export BADDRESS='hbcdigtialdatamanagement@hbc.com' #to be found
export BSUBJECT=""
export SUBJECT="${PROCESS} Failed. Please investigate"
export FILE_NAME_FLIPP="$DATA/o5_product_feed_to_flipp_`date +"%Y%m%d%H%M%S"`.txt"
#################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
function send_delay_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" -c 'hbcdigtialdatamanagement@hbc.com' ${BADDRESS}
 send_email
}
function send_success_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo "O5 CHANNEL ADVISOR FEED COMPLETED"|mailx -s "${CURRENT_TIME} FileName ${FILE_NAME} File size is: ${TFILE_SIZE} Line count is: ${FILE_COUNT}" $address
 done
}
########################################################################
##update Runstats Start
##################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
echo "Started preparing data at `date '+%a %b %e %T'`" >${LOG_FILE}
#sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS_SQL1} ${SCHEMA} ${PIM_DBLINK}>>${LOG_FILE}
#################################################################
echo "Started exporting data at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS_SQL2} ${SCHEMA} >${FILE_NAME}
SQL_RET_CODE=$?
echo "Finished exporting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
cd $DATA
################################################################
##SQL ERROR VALIDATION
#################################################################
if [ ${SQL_RET_CODE} -eq 0  ]
then
        echo "Finished extracting data successfully at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
        BBODY="O5 Versa feed is delayed and we are looking into it. Thanks"
        BADDRESS='David.Mataranglo@360i.com Sofia_Azzolina@s5a.com Hannah_Tevolini@s5a.com'
        BSUBJECT="O5 VERSA FEED DELAYED"
        send_delay_email
        echo "Aborting: Error in ${PROCESS_SQL2} at `date '+%a %b %e %T'`" >>${LOG_FILE}
        exit 99
fi
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${FILE_NAME} ]
then
        TFILE_SIZE="`ls -ll $FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
        FILE_COUNT="`wc -l $FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
fi
echo "File size is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
##FILE COUNT VALIDATION
#################################################################
if [ ${FILE_COUNT} -gt 100000 ]
then
        echo "Enough records on the file " >> ${LOG_FILE}
        echo "Starting FTP process " >> ${LOG_FILE}
else
        echo "Aborting: Error loading ${FILE_NAME}  at `date '+%a %b %e %T'`" >>${LOG_FILE}
        echo "${PROCESS} Failed. Minimum amount of data was not present." >>${LOG_FILE}
        BBODY="O5 Versa feed is delayed and we are looking into it. Thanks"
        BADDRESS='David.Mataranglo@360i.com Sofia_Azzolina@s5a.com Hannah_Tevolini@s5a.com'
        BSUBJECT="O5 VERSA FEED DELAYED"
        send_delay_email
        exit 99
fi
################################################################
#SCP the file to Versafeed
#################################################################
scp -P 22 -i /home/ddwo5/.ssh/cognos_id_rsa /home/ddwo5/DATA/CA_o5_feed_intl_`date +"%Y%m%d"`.txt a_2954@ftp.versafeed.com:/CA_o5_feed_intl_`date +"%Y%m%d"`.txt
SCP_RET_CODE=$?
#################################################################
##SCP VALIDATION need to find out how
#################################################################
if [ ${SCP_RET_CODE} -eq 0  ]
then
  echo "Finished SCP data successfully to VERSAFEED.COM at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
  echo "Aborting: SCP failed  at `date '+%a %b %e %T'`" >>${LOG_FILE}
  BBODY="O5 Versa feed is delayed and we are looking into it. Thanks"
  BADDRESS='David.Mataranglo@360i.com Sofia_Azzolina@s5a.com Hannah_Tevolini@s5a.com'
  BSUBJECT="O5 VERSA FEED DELAYED"
  send_delay_email
  exit 99
fi
echo "Starting the sftp process to Flipp for ${BANNER} at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
#################################################################
cd $HOME
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_SIZE" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|not connected" ${LOG_FILE}` -ne 0 ]
then
        echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
        export SUBJECT=${BAD_SUBJECT}
        BBODY="O5 Versa feed is delayed and we are looking into it. Thanks"
        BADDRESS='David.Mataranglo@360i.com Sofia_Azzolina@s5a.com Hannah_Tevolini@s5a.com'
        BSUBJECT="O5 VERSA FEED DELAYED"
        send_delay_email
        exit 99
else
        BADDRESS='hbcdigtialdatamanagement@hbc.com'
        echo "Off5th Product feed posted to Versafeed successfully"|mailx -s "File posted to Versafeed successfully" ${BADDRESS}
        send_success_email
        echo "${PROCESS} completed without errors." >> ${LOG_FILE}
        echo "Channeladvisor_feed PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
fi
