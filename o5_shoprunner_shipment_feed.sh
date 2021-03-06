#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_shoprunner_shipment_feed.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. 
#####				      
#####
#####   CODE HISTORY : 	Name                Date            Description
#####                 	------------        ----------      ------------
#####					KALLAAR   			06/05/2017      Created
#####                 
#####				  
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_shoprunner_shipment_feed'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export FILEDATE=`date +"%Y%m%d%H%M"`
export SHIPMENT_FEED='o5_shoprunner_shipment_feed.sql'

export SHIPMENT_FEED_NAME='o5_shoprunner_shipment_feed.xml'
export SHIPMENT_FILE_NAME="OFF5TH_${FILEDATE}_shipment-feed.xml"

export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0

export DMUSER='sroff5th'
export DMPWD='J3hP4mjNWtd'
export TARGET_LOC="Inbox"
export DMHOST='sftp.off5th.shoprunner.net'

export BADDRESS='hbcdigitaldatamanagement@saksinc.com' 
export BSUBJECT="UPSTREAM COMMERCE FEED DELAYED"
export BBODY="Upstream commerce shipment feed is delayed and we are looking into it. Thanks" 
export SUBJECT="${PROCESS} Failed. Please investigate"
#################################################################
#SEND MAIL
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
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" ${BADDRESS}
 send_email
}
########################################################################
##update Runstats Start
##################################################################
sqlplus -s -l $CONNECTDW <<EOF >${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
echo "Started preparing data from DW at `date '+%a %b %e %T'`" >${LOG_FILE}
#sqlplus -s -l $CONNECTO5 @${SQL}/${SHIPMENT_FEED} >>${LOG_FILE}
sqlplus -s -l $CONNECTDWXML @${SQL}/${SHIPMENT_FEED} >>${LOG_FILE}
SQL_RET_CODE=$?
echo "Finished preparing data from DW at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
if [ ${SQL_RET_CODE} -eq 0  ]
then
echo "Finished preparing data from DW successfully at `date '+%a %b %e %T'`" >>${LOG_FILE}
else 	
echo "Aborting: Error in ${ORDER_FEED} at `date '+%a %b %e %T'`" >>${LOG_FILE}
send_delay_email
exit 99
fi
#################################################################
#Pull the data from 145 box -- try to get proper message
#################################################################
echo -e "copying the data from 145 to 101 at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
scp cognos@${ORACLESRV}:/oracle/EXPORTS/dataservices/${SHIPMENT_FEED_NAME} ${DATA}
wait
dos2unix ${DATA}/${SHIPMENT_FEED_NAME}>>${LOG_FILE}
echo -e "Executed the command Dos2Unix to eliminate  " >>${LOG_FILE}
mv ${DATA}/${SHIPMENT_FEED_NAME} ${DATA}/${SHIPMENT_FILE_NAME}
echo -e "Finished copying the data from 145 to sd1pdw01vlat `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
#################################################################
cd ${DATA}
#################################################################
# Check for errors on data file
###############################################################
if [ `egrep -c "^ERROR|ORA-|not found|not connected" ${SHIPMENT_FILE_NAME}` -ne 0 ]
then
	echo "Data file has errors. Please investigate" >> ${LOG_FILE}	
	send_delay_email
	exit 99
else     	
	echo "Data file is clean. ready for transfer" >> ${LOG_FILE}	
fi
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${SHIPMENT_FILE_NAME} ]
then	
	TFILE_SIZE="`ls -ll $SHIPMENT_FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
	#FILE_COUNT="`wc -l $SHIPMENT_FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
	FILE_COUNT=`grep -o "<RetailerOrderNumber>" $SHIPMENT_FILE_NAME |wc -l` # linecount of the file
fi
echo "File size ${ORDER_FILE_NAME} is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count ${ORDER_FILE_NAME} is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
echo "Starting SFTP process " >> ${LOG_FILE}
wait
lftp -u ${DMUSER},${DMPWD} sftp://${DMHOST}<<EOF >>${LOG_FILE}
cd ${TARGET_LOC}
put ${SHIPMENT_FILE_NAME}
quit
EOF
LFTP_RET_CODE=$?
echo "SFTP process completed" >> ${LOG_FILE}
#################################################################
##LFTP ERROR VALIDATION
#################################################################
if [ ${LFTP_RET_CODE} -eq 0 ]
then
	echo "LFTP completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
	echo "Aborting: Error in LFPT at `date '+%a %b %e %T'`" >>${LOG_FILE}
	send_delay_email
	exit 99
fi
#################################################################
cd $HOME
#################################################################
##Added Email Notification
#################################################################
echo -e "Shoprunner O5 Shipment feed Posted on `date '+%a %b %e %T'` \n\nThe File size for today's feed is : ${TFILE_SIZE} bytes\nTotal number of line count in the XML is : ${FILE_COUNT}\n\nPlease make aware of any issue to  HBC Data Management. \nThank You " |mailx -s "O5 Shoprunner Shipment Feed" -r O5_SHOPRUNNER_EMAIL@hbc.com Harsh_Desai@s5a.com hbcdigitaldatamanagement@saksinc.com  nsampey@shoprunner.com
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l $CONNECTDW<<EOF >${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_SIZE" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# Check for errors
###############################################################
if [ `egrep -c "^ERROR|ORA-|not found|not connected" ${LOG_FILE}` -ne 0 ]
then
	echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}	
	send_delay_email
	exit 99
else
	echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
#exit 0