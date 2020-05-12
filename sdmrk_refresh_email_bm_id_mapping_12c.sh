#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : sdmrk_refresh_email_bm_id_mapping.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. refresh_prd_assorment table sdmrk
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####                   Sripriya Rao            05/02/2018      Created
#####
#####
##################################################################################################################################
. $HOME/params.conf $1
################################################################
##Control File Variables
export BANNER=$1
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='sdmrk_refresh_email_bm_id_mapping'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="${LOG}/${PROCESS}_${BANNER}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################
echo "Started extracting data at `date '+%a %b %e %T'`" >${LOG_FILE}

if [ "${BANNER}" == "o5" ]
then
	export TABLENM="SDMRK.O5_EMAIL_ADDRESS_BM_ID_MAPPING"
  export PRODSDW_DB_LINK="reportdb"
        export FBANNER="off5th"
        export EMAIL_TABLE="SDMRK.O5_EMAIL_ADDRESS"
elif [ "${BANNER}" == "saks" ]
then
	export TABLENM="SDMRK.EMAIL_ADDRESS_BM_ID_MAPPING"
	export PRODSDW_DB_LINK="reportdb"
        export FBANNER="saks"
        export EMAIL_TABLE="SDMRK.EMAIL_ADDRESS"
fi

#################################################################
sqlplus -s -l $CONNECTSDMRK12C @${SQL}/${PROCESS}_12c.sql "$TABLENM" "$EMAIL_TABLE" "$PRODSDW_DB_LINK" "$FBANNER" >>${LOG_FILE}

################################################################
echo "Finished $BANNER Email BM ID Mapping at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "${PROCESS} PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
# Check for errors
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
send_email
fi
