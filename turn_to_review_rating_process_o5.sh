#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : turn_to_review_rating_process
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Fetches the xml file from Turn to
#####                              2. Loads the data into the table
#####                  3. Updates the ratings
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Jayanthi           08/15/2015      Created
#############################################################################################################################
. $HOME/initvars
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='turn_to_review_rating_process_o5'
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SQL1="turn_to_review_rating_process_o5"
export SQL2="turn_to_product_review_refresh"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export SLEEP_TIME=600
export COUNT=5
export CTR=0
export SLEEP_SUBJECT="${PROCESS1} is sleeping."
export RUN_SUBJECT="${PROCESS1} has started."
### remove the existing jsp page ############
export BANNER=$1
########################################################################
rm ProductReviewCacheRefresh.jsp
########################################################################
echo -e "PRODUCT_REVIEW_RATING PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
address="hbcdigtialdatamanagement@hbc.com saksdirectinfra@saksinc.com"
tail -83 ${LOG_FILE}|mailx -s "${SUBJECT}" $address
}
#################################################################
##Update SCHEMA for specific BANNER
#################################################################
###########################################################
#####      SAKS BANNER     ###########################
if [ "${BANNER}" == "saks" ]
then
export SCHEMA="mrep."
export XML_FILE_SAKS="turnto-skuaveragerating.xml"
export XML_FILE=${XML_FILE_SAKS}
export FILE_NAME="${DATA}/${XML_FILE_SAKS}"
export PRODSTO_DB_LINK="PRODSTO_MREP"
export PRIMSTO_DB_LINK="PRIMSTO_MREP"
export CLONE_RUN_FILE='/clonedb_stat/FLAGS/CLONE_REFRESH_RUNNING'
export JSP_FILE='ProductReviewCacheRefresh.jsp'
export SITE_KEY='qVAfLY4rGL8BLeysite'
export AUTH_KEY='DPsx7kA8PmdZC1mauth'
export DATA_FILE="$DATA/product_review.bmi"
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ]
then
export SCHEMA="o5."
export XML_FILE="turnto-skuaveragerating.xml"
export FILE_NAME="${DATA}/${XML_FILE}_${BANNER}"
export PRODSTO_DB_LINK="O5PROD_MREP"
export PRIMSTO_DB_LINK="O5PRIM_MREP"
export JSP_FILE='ProductReviewCacheRefresh.jsp'
### this is for off5th test: export SITE_KEY='BBhFQqvKrFEA7M4site'
### this is for off5th test: export AUTH_KEY='W3SXC52a2ikZxiqauth'
export SITE_KEY='j52xFUl6PGgLo3Ksite'
export AUTH_KEY='48BKMPhyo2v8tMvauth'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
fi
############################################################
# GET THE DATA FILE from BV'S SFTP SERVER
##########################################################################
echo -e "Started the exporting the file from turn to `date '+%a %b %e %T %Z %Y'`\n " >${LOG_FILE}
mv ${FILE_NAME} ${FILE_NAME}_old
echo -e "FTP PRODUCT_REVIEW_RATING  FILE from turn_to started at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
while true ;
do
cd $DATA
curl --cacert /home/cognos/vendorssh/cacert.pem --proxy proxy.saksdirect.com:80 http://static.www.turnto.com/static/export/${SITE_KEY}/${AUTH_KEY}/${XML_FILE} > ${FILE_NAME}
echo -e "Finished the exporting the file from turn to `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
FILE_COUNT=`wc -l $FILE_NAME | awk '{printf("%s\n", $1)}'`
echo "File count: $FILE_COUNT">> $LOG_FILE
wait
if [ ${FILE_COUNT} -gt 3000 ]
then
echo "File present for ${BANNER} . Starting the process" >> $LOG_FILE
else
echo "${PROCESS} was not sent. Minimum amount of data was not present for ${BANNER}" >> $LOG_FILE
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
fi
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Copying the xml file to oracle server
scp ${FILE_NAME} cognos@$ORACLESRV:/oracle/EXPORTS/dataservices
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "Started loading the main table at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
sqlplus -s -l  $CONNECTDWXML @${SQL}/${SQL1}.sql "${SCHEMA}" >> ${LOG_FILE}
#################################################################
echo -e "Finished Loading the main table  at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
echo -e "Started extracting data from the main table at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
REC_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*)
from ${SCHEMA}turn_to_product_review  where trunc(date_modified)>trunc(sysdate-7);
quit;
EOF`
#################################################################
if  [ $REC_COUNT -ne 0 ]
then
echo -e  " New Product Review update file is available at `date '+%a %b %e %T'`\n">>${LOG_FILE}
break;
else
echo -e  "Product Review update file is NOT available at `date '+%a %b %e %T'`\n">>${LOG_FILE}
echo -e  "Process is Sleeping at `date '+%a %b %e %T'`\n">>${LOG_FILE}
fi
CTR=$(expr ${CTR} + 1)
if [ ${CTR} -ge ${COUNT} ]
then
echo -e  "No new updates in the current file `date '+%a %b %e %T'`\n">>${LOG_FILE}
echo -e  "Exiting the process at `date '+%a %b %e %T'`\n">>${LOG_FILE}
(echo -e "Product Review refresh failed ";) | mailx -s " FAILURE:PRODUCT REVIEW TABLE LOAD -No File Received with updates" hbcdigtialdatamanagement@hbc.com
exit 99
fi
sleep ${SLEEP_TIME}
done
#################################################################
echo -e "Refreshing the saks_custom.reviews table in production at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
#sqlplus -s -l  $CONNECTDWXML @${SQL}/${SQL2}.sql "${PRODSTO_DB_LINK}" "${PRIMSTO_DB_LINK}" "${SCHEMA}" >> ${LOG_FILE}
#################################################################
echo -e "Finished Refreshing the saks_custom.reviews table in production at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
###Refresh the jsp page for saks ##
#################################################################
cd $HOME
echo -e "Started Refreshing the JSP  at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
##wget http://hd1pxx21lx.digital.hbc.com:7010/main/productreview/ProductReviewCacheRefresh.jsp>> ${LOG_FILE}
wait
#########################################################################
## Do the MVIEW refresh and endeca review partial
########################################################################
echo -e "Starting the MVIEW refresh at `date '+%a %b %e %T'`\n">>${LOG_FILE}
BEFORE_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*) from saks_custom.reviews@${PRODSTO_DB_LINK};
quit;
EOF`
echo -e "Starting Endeca review partial at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
ssh -n endadmin@hd1putl22lx.digital.hbc.com '/home/endadmin/endeca/apps/saks/control/partial_update_reviews.sh'
wait
echo -e "Finished the endeca review partial at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
########################################################################
#################################################################
echo -e "PRODUCT_REVIEW_RATING LOAD PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ] || [ `egrep -c "false|rejected|Rejected" ${JSP_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
(echo -e "Product Review/JSP refresh failed ";) | mailx -s " FAILURE:PRODUCT REVIEW TABLE LOAD/JSP REFRESH" hbcdigtialdatamanagement@hbc.com saksdirectdevelopment@s5a.com
else
export SUBJECT="SUCCESS: PRODUCT_REVIEW_LOAD"
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
#send_email
fi
