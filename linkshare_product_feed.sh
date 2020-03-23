#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME :o5_linkshare_product_feed.sh
#####
#####   DESCRIPTION  : This script does the following
#####   CODE HISTORY :                   Name                     Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Jayanthi Dudala              10/17/2011      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf $1
export BANNER=$1
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='linkshare_product_feed'
export LOG_FILE="$LOG/${BANNER}_${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${BANNER}_${PROCESS}.sql'
export EXTRACT_SQL2='$SQL/${BANNER}_${PROCESS}_attr.sql'
export FILE_NAME="$DATA/38801_nmerchandis`TZ=GMT+24 date +"%Y%m%d"`.txt"
export FILE_NAME2="$DATA/38801_nattributes`TZ=GMT+24 date +"%Y%m%d"`.txt"
export SFILE_SIZE=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export LOAD_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
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
if [ "${BANNER}" == "s5a" ];
then
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
export PIM_PRD_ATTR_TAB="saks_all_active_pim_prd_attr"
export PIM_SKU_ATTR_TAB="saks_all_active_pim_sku_attr"
export PIM_ASSRT_TAB="saks_all_actv_pim_assortment"
export PART_TABLE="BI_PARTNERS_EXTRACT_WRK"
export BMCONNECTION="PRODSTO_MREP"
export HEADER="SAKS"
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
export HEADER="SAKSOFF5TH"
fi
#################################################################
##Update Runstats Start
#################################################################

########Run the stats####################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
########################################################################################
echo "Running the script to extract data started at `date '+%a %b %e %T'`" >${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL}  "$SCHEMA" "$BANNER" "$PART_TABLE" "$PIM_DBLINK" "$HEADER">$FILE_NAME
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL2} "$SCHEMA" "$BANNER" "$PART_TABLE" "$PIM_DBLINK" "$HEADER">$FILE_NAME2
wait
echo "Completed the  product extract  at `date '+%a %b %e %T'`" >>${LOG_FILE}
########################################################################################
TFILE_SIZE="`ls -ll $FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`"
TARGET_COUNT="`wc -l $FILE_NAME |tr -s ' ' '|'|cut -f1 -d'|'`"
echo " Updating the item count started at  `date '+%a %b %e %T'`" >>${LOG_FILE}
LOAD_COUNT=`sqlplus -s -l  $CONNECTDW<<EOF
set heading off
  select trim(count(distinct (styl_seq_num))) from ${SCHEMA}.${PART_TABLE} where wh_sellable_qty > 0;
quit;
EOF`
##########################################################################################
#### FTP the file to Linkshare
cd $DATA
if [ "${BANNER}" == "o5" ];
then
ftp -nv Mftp.linksynergy.com  << EOF>>${LOG_FILE}
user offSAK PNYUV47c
put 38801_nmerchandis`TZ=GMT+24 date +"%Y%m%d"`.txt
put 38801_nattributes`TZ=GMT+24 date +"%Y%m%d"`.txt 
bye
EOF
fi
if [ "${BANNER}" == "s5a" ];
then
echo "Saks FTP detail" >>${LOG_FILE}
fi
##########################################################################################
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|closed connection|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${BANNER}_${PROCESS} failed. Please investigate"
echo "${BANNER}_${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${BANNER}_${PROCESS} completed without errors."
##Update Runstats Finish
echo "FILE SIZE : $TFILE_SIZE" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
if  [ $TARGET_COUNT -ne 0 ]
then
(echo "${BANNER} Linshare product feed  Counts:
UPC level count : $TARGET_COUNT
ITEM count : $LOAD_COUNT"
) |  mailx -s "${BANNER} Linkshare product count"  AffiliateTeamList@s5a.com hbcdigtialdatamanagement@hbc.com ls-saks@linkshare.com
exit 99
fi
echo "${BANNER}_${PROCESS} completed without errors." >> ${LOG_FILE}
exit 0
###################################################################################################
fi

