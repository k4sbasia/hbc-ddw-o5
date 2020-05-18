#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : feed_google_product.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for google feed for saks and off5th. This is full product feed
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Nilima Mehta           01/26/2017
#####                                   Ishavpreet Singh           05/12/2017
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='feed_google_product'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export BANNER=$BANNER
export BANNER_PARAM=$1
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export BAD_SUBJECT="FAILURE:${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME=""
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export REC_COUNT='1'
export SCHEMA=""
export SUFFIX=""
export CHAIN=""
export SAKS_FILE_NAME1="google_product_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export O5_FILE_NAME1="google_product_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export SAKS_FILE_NAME2="saksfifthavenue_en-us_products_003"
export O5_FILE_NAME2="saksofffifthavenue_en-us_products_test"
export LT_FILE_NAME1="google_product_feed_${BANNER}_`date +"%Y_%m_%d"`.txt"
export LT_FILE_NAME2="lordandtaylor_en-us_products_test"
########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
function send_delay_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 export SUBJECT=${BAD_SUBJECT}
 BBODY="Google: product feed is delayed and we are looking into it. Thanks"
 BADDRESS="nilima_mehta@5a.com hbcdigitaldatamanagement@saksinc.com"
 BSUBJECT="GOOGLE SAKS PRODUCT FEED DELAYED"
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" ${BADDRESS}
 send_email
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

################################################################
if [ "${BANNER_PARAM}" == "o5" ] || [ "${BANNER_PARAM}" == "lat" ] ;
then
  export BANNER=$BANNER_PARAM
fi
#####################################################################
echo -e " feed started at `date '+%a %b %e %T'`" >${LOG_FILE}
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
if [ "${BANNER}" == "saks" ]
then
export CHAIN="8"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
#######################populate staging table for bay on rfs#########################################
sqlplus -s -l  $CONNECTDW @${SQL}/feed_google_product_load_saks.sql     > $DATA/${SAKS_FILE_NAME1}
wait
cd $DATA
SOURCE_COUNT=`cat $DATA/${SAKS_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file before sending to google. If count is less than 50000 then process will fail" >> ${LOG_FILE}
if [ ${SOURCE_COUNT} -gt 50000 ]
then
echo " ${SOURCE_COUNT} records found in ${SAKS_FILE_NAME1} file " >> ${LOG_FILE}
## DO FTP here
cd $DATA
cp ${SAKS_FILE_NAME1} ${SAKS_FILE_NAME2} >>${LOG_FILE}
echo -e "FTP for product started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
lftp -u mc-sftp-9439371,'^4>M$,!O7a' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
put ${SAKS_FILE_NAME2}
wait
Bye
EOF
#################################################################
##FTP TRANSFER VALIDATION
#################################################################
##if [ $?  -ne  0 ]
##then
##echo "FTP process failed at at `date '+%a %b %e %T'`. Please investigate" >> ${LOG_FILE}
##send_delay_email
##exit 99
##fi
################################################################
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${SAKS_FILE_NAME1} file which is less than 50000. Please check  ${SAKS_FILE_NAME1}  file" >> ${LOG_FILE}
send_delay_email
exit 99
fi
fi
##############################################################################################
if [ "${BANNER}" == "o5" ]
then
export CHAIN="7"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
##################################################################  Run the sql script that write file
sqlplus -s -l  $CONNECTDW @${SQL}/feed_google_product_load_o5.sql    "$SCHEMA" "$BANNER" "$PART_TABLE"  "$PIM_DBLINK"  > $DATA/${O5_FILE_NAME1}
wait
cd $DATA
SOURCE_COUNT=`cat $DATA/${O5_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file for O5 before sending to google. If count is less than 50000 then process will fail" >> ${LOG_FILE}
##Uncomment below code after instore validation
#if [ ${SOURCE_COUNT} -gt 10000 ]
#then
echo " ${SOURCE_COUNT} records found in ${O5_FILE_NAME1} file " >> ${LOG_FILE}
cd $DATA
cp ${O5_FILE_NAME1}  ${O5_FILE_NAME2} >>${LOG_FILE}
## DO FTP here
################################################################
echo -e "FTP for O5 product started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
###removed google reference to Versa for product feed
#lftp -u mc-sftp-17287421,'q!c!_6m{Oa' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
lftp -u a_3068,'B8N2nhvbkqELA' sftp://ftp.versafeed.com <<EOF>>${LOG_FILE}
put ${O5_FILE_NAME2}
wait
Bye
EOF
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#else
#echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${O5_FILE_NAME1} file which is less than 50000. Please check error in  ${O5_FILE_NAME1}  file" >> ${LOG_FILE}
#send_delay_email
#exit 99
#fi
fi
##############################################################################################
if [ "${BANNER}" == "lat" ]
then
export CHAIN="21"
echo "  BANNER = ${BANNER} and CHAIN = ${CHAIN}  " >> ${LOG_FILE}
##################################################################  Run the sql script that write file
sqlplus -s -l  $CONNECTDSGDW @${SQL}/feed_google_product_load_lt.sql      > $DATA/${LT_FILE_NAME1}
wait
cd $DATA
SOURCE_COUNT=`cat $DATA/${LT_FILE_NAME1} | wc -l`
#############################################################
echo "Check for no of rows in data file for LAT before sending to google. If count is less than 50000 then process will fail" >> ${LOG_FILE}
if [ ${SOURCE_COUNT} -gt 10000 ]
then
echo " ${SOURCE_COUNT} records found in ${LT_FILE_NAME1} file " >> ${LOG_FILE}
cd $DATA
cp ${LT_FILE_NAME1}  ${LT_FILE_NAME2} >>${LOG_FILE}
## DO FTP here
################################################################
echo -e "FTP for LAT product started to google at `date '+%a %b %e %T'`" >>${LOG_FILE}
lftp -u mc-sftp-6649174,'T:y7#Htw<K' sftp://partnerupload.google.com:19321 <<EOF>>${LOG_FILE}
put ${LT_FILE_NAME2}
wait
Bye
EOF
echo "Finished Extracting data  at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
echo "${PROCESS} failed. Please investigate. Only ${SOURCE_COUNT} records found in $DATA/${LT_FILE_NAME2} file which is less than 50000. Please check error in  ${O5_FILE_NAME1}  file" >> ${LOG_FILE}
send_delay_email
exit 99
fi
fi

####################################################################
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

####################################################################
#################################################################
echo -e " feed Process Ended at `date '+%a %b %e %T'` " >>${LOG_FILE}
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate " >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
else
export SUBJECT="SUCCESS: quick hits Completed"
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors." >> ${LOG_FILE}
exit 0
#send_email
fi
