#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS Direct 
#############################################################################################################################
#####
#####   PROGRAM NAME : new_arrival_update.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls procedure  "P_PARTIAL_UPDATE_NEW_ARRIVAL" in variuos enviroments (prodsto, stgdb, primsto)
#####                               
#####
#####
#####   CODE HISTORY :  Name                Date            Description
#####                ------------          ----------      ------------
#####
#####               Liya Aizenberg         04/28/2016        Created 
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
#export ENV=$1
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export PROCESS="o5_new_arrival_update_${ENV}"
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
export SQL0="$SQL/o5_new_arrival_sdw.sql"
export SQL01="$SQL/o5_new_arrival_sdw_prev.sql"
export SQL1="$SQL/o5_new_arrival_update.sql"
########################################################################
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
######################################################################
##Runstats for job
#####################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#####################################################################
##Update Environments 
####################################################################
##if [ "$ENV" = "o5_preview" ]; then
##            SCHEMA="endeca_saks_custom_cis."; export SCHEMA
##            DBLINK="PRVO5_MREP"; export DBLINK
##			SCHEMAETL="saks_custom."
##fi
##if [ "$ENV" = "o5_stqa" ]; then
##            SCHEMA="endeca_saks_custom_cis."; export SCHEMA
##            DBLINK="QAO5_MREP"; export DBLINK
##fi
##if [ "$ENV" = "o5_prod" ]; then
##            SCHEMA="endeca_saks_custom."; export SCHEMA
 ##           DBLINK="PRODO5_MREP"; export DBLINK
##			SCHEMAETL="saks_custom."
##fi
##SDW

#if [ "$ENV" = "o5_preview" ]; then
sqlplus -s -l  $CONNECTDW <<EOF>${LOG_FILE} @${SQL01} "$DBLINK" "$SCHEMA" "$BANNER"
EOF
#sqlplus -s -l  $CONNECTDW <<EOF>>${LOG_FILE} @${SQL1} "$DBLINK" "$SCHEMAETL"
#EOF
#fi

if [ "$ENV" = "o5_stqa" ]; then
#sqlplus -s -l  $CONNECTDW <<EOF>${LOG_FILE} @${SQL01} "$DBLINK" "$SCHEMA"
#EOF
echo "commented in STQA this code as it updates the common table used in prod" > ${LOG_FILE}
fi

#if [ "$ENV" = "o5_prod" ]; then
sqlplus -s -l  $CONNECTDW <<EOF>${LOG_FILE} @${SQL0} "$DBLINK" "$SCHEMA""$BANNER"
EOF
#sqlplus -s -l  $CONNECTDW <<EOF>>${LOG_FILE} @${SQL1} "$DBLINK" "$SCHEMAETL"
#EOF
#fi

##per ENV: preview, QA, PROD

#sqlplus -s -l  $CONNECTDW <<EOF>>${LOG_FILE} @${SQL1} "$DBLINK" "$SCHEMA"
#EOF
#wait

#################################################################
##Update Runstats Finish
################################################################# 
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit 0
