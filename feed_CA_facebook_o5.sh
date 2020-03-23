#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : feed_facebook_bloomreach.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. The script calls the feed_CA_facebook_o5.sh which produces a customized CA product feed to Bloomreach.
#####
#####
#####   CODE HISTORY :                   Name                   Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Sripriya Rao            07/19/2016      Created
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
export PROCESS='feed_CA_facebook_o5'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export PROCESS_SQL="${PROCESS}.sql"
export SFILE_SIZE=0
export FILE_NAME="$DATA/off5th_facebook_`date +"%Y%m%d"`.tsv"
export FILE_NAME_FB="o5a/off5th_facebook_feed.tsv"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export HTTPS_PROXY=http://proxy.saksdirect.com:80
export BANNER=$1
set -x
########################################################################
##update Runstats Start
#################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^9'|while read group address
 do
 echo "The ${PROCESS} has mismatch source and target counts ${CURRENT_TIME}"|mailx -s "CA Feed Mismatch Counts" $address
 done
}
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
export PIM_PRD_ATTR_TAB="saks_all_active_pim_prd_attr"
export PIM_SKU_ATTR_TAB="saks_all_active_pim_sku_attr"
export PIM_ASSRT_TAB="saks_all_actv_pim_assortment"
export PART_TABLE="BI_PARTNERS_EXTRACT_WRK"
export BMCONNECTION="PRODSTO_MREP"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export SCHEMA="o5."
export PART_TABLE="O5_PARTNERS_EXTRACT_WRK"
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export PIM_PRD_ATTR_TAB="pim_ab_o5_prd_attr_data"
export PIM_SKU_ATTR_TAB="pim_ab_O5_sku_attr_data"
export PIM_WEB_FOLDER_TAB="pim_ab_o5_web_folder_data"
export PIM_ASRT_PRD_ASSGM="pim_ab_o5_bm_asrt_prd_assgn"
export PIM_FOLDER_ATTR_DATA="pim_ab_o5_folder_attr_data"
export PIM_DBLINK="PIM_READ"
fi
##################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

###################################################################
echo "Started extracting data at `date '+%a %b %e %T'`" >${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS_SQL} "${SCHEMA}" >${FILE_NAME}
sed -i 's/\t/ /g' ${FILE_NAME}
wait
sed -i 's/~/\t/g' ${FILE_NAME}
wait
cd $HOME
SOURCE_COUNT=`cat ${FILE_NAME} | wc -l`
if [ ${SOURCE_COUNT} -gt 10000 ]
then
cp ${FILE_NAME} ${FILE_NAME_FB}
echo "Data check completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo "Data file doesnt have enought data to post please check" >>${LOG_FILE}
exit 99
fi
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
echo "Facebook_feed PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
################################################################
#Ftp the file to CA
#################################################################
echo "Starting the sftp process to Facebook at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
cd $DATA
echo "Checking the validity of the feed file generated..." >> ${LOG_FILE}
if [ `egrep -c "^ERROR|ORA-|not connected|object no longer exists error" ${FILE_NAME}` -ne 0 ]
then
        echo "Incorrect data in the feed file, ${FILE_NAME}. Please investigate"
        echo "Incorrect data in the feed file, ${FILE_NAME}. Please investigate" >> ${LOG_FILE}
        exit 99
else
echo "Posting files to s3 bucket http://s3.amazonaws.com/facebook-hbc " >>${LOG_FILE}
cd $HOME
#export HTTPS_PROXY=http://proxy.saksdirect.com:80
#/home/cognos/upload_file.py --file o5a/off5th_facebook_feed.tsv --bucket_name facebook-hbc  >> ${LOG_FILE}
fi
cd $HOME
echo "Saks Product feed to facebook process completed at `date '+%a %b %e %T %Z %Y'`" >>${LOG_FILE}
#################################################################
# Check for errors
################################################################
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|not connected" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
fi