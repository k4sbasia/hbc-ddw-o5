#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : sdmrk_refresh_prd_assortment.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. refresh_prd_assorment table sdmrk
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####
#####
#####
##################################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='sdmrk_refresh_prd_assortment'
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
	export TABLENM="SDMRK.O5_PRD_ASSORTMENT"
	export DDW_DB_LINK="REPORTDB"
elif [ "${BANNER}" == "saks" ]
then
	export TABLENM="SDMRK.PRD_ASSORTMENT"
	export PRODSTO_DB_LINK="PRODSTO_SAKS_CUSTOM"
fi

#################################################################
sqlplus -s -l $CONNECTSDMRK12C @${SQL}/${PROCESS}_12c.sql "$TABLENM" "$SCHEMA" "$DDW_DB_LINK"  >>${LOG_FILE}

################################################################
echo "Finished refresh assorment data at `date '+%a %b %e %T'`" >>${LOG_FILE}
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
send_email
exit 99
fi
