#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : pim_product_extract.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for building the attribute data for Product and sku from PIM
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Jayanthi                 Unknown         Created
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='pim_product_extract'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
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
export BANNER=$1
set -x
########################################################################
##Initialize Email Function
########################################################################
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
fi
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @$HOME/SQL/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "pim_product_extract build Process started at `date '+%a %b %e %T'`" >${LOG_FILE}
#########################################################################
#  Run the sql script that performs the product info extract
#################################################################
sqlplus -s -l  $CONNECTPIM @${SQL}/${PROCESS}.sql "${PIMSCHEMA}" "${BANNER}" "${PIM_PRD_ATTR_TAB}" "${PIM_SKU_ATTR_TAB}" "${PIM_WEB_FOLDER_TAB}" "${PIM_FOLDER_ATTR_DATA}" "${PIM_ASRT_PRD_ASSGM}">> ${LOG_FILE}
##"${PIM_SKU_ATTR_TAB}" "${PIM_ASSRT_TAB}">> ${LOG_FILE}
echo "pim_product_extract PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
################################################################
##Update Runstats Finish
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors:`date '+%a %b %e %T'`" >> ${LOG_FILE}
##Update Runstats Finish
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################################################
fi
