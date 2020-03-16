#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_prd_hier_status_refresh.sh
#####
#####   DESCRIPTION  : This script populate o5.prd_hier_price_status table
#####
#####
#####
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####                   Liya Aizenberg      05/20/2016          Created
#####                   
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='o5_prd_hier_status_refresh'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export ENV_TYPE=$1
export PDW_SQL='$SQL/${PROCESS}_pdw.sql'
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export BANNER=$1

################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^9'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
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

#################################################################################################################################
########Run the stats############
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#####################################################################
##Update Environments 
####################################################################
LOG_FILE="$LOG/${PROCESS}_${ENV_TYPE}_log.txt"
####################################################################
echo "Start Main " >  ${LOG_FILE}
if [ "$ENV_TYPE" = "o5_preview" ]; then
echo "Started PDW Update in o5.prd_hier_price_status tables" >> ${LOG_FILE}
sqlplus -s $CONNECTDW @${PDW_SQL} "$SCHEMA" >>${LOG_FILE}
wait
echo "Finished PDW Update in o5.prd_hier_price_status tables" >> ${LOG_FILE}
export DB_CONNECT=$PDP_DBCONNECT_O5_PREVIEW
fi
if [ "$ENV_TYPE" = "o5_stqa" ]; then
export DB_CONNECT=$PDP_DBCONNECT_O5_STQA
fi 
if [ "$ENV_TYPE" = "o5_prod" ]; then
export DB_CONNECT=$PDP_DBCONNECT_O5_PROD
fi

echo "Calling the  sql in $DB_CONNECT script to insert data into o5.prd_hier_price_status tables" >>${LOG_FILE}
#sqlplus -s $DB_CONNECT @${EXTRACT_SQL}  >>${LOG_FILE}
echo "Extract $ENV_TYPE File Completed in $DB_CONNECT at `date +%Y%m-%d:%M:%S`" >>${LOG_FILE}
#################################################################
# Update the runstats 
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${JOB_NAME}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
################################################################
##Bad Records Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit 0
