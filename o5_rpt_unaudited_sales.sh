#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_rpt_unaudited_sales.sh
#####
#####   DESCRIPTION  : This script does the following
#####                             
#####
#####
#####
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
#####                                   Rajesh Mathew           05/18/2011      Created
#####
#####
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_rpt_unaudited_sales'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export DATA_FILE=$DATA/o5_rpt_unaudited_sales.html
export DATA1_FILE=$DATA/o5_rpt_unaudited_sales_ff.html
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
export SUBJECT="Off 5th.com Un-audited Sales for `TZ=GMT+24 date +"%Y-%m-%d"`"
########################################################################
##Initialize Email Function
########################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "O5 BI_UNAUDITED_SALES Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
#  Run the sql script that performs the data load
#################################################################
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}_load.sql >> ${LOG_FILE} 
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql > ${DATA_FILE} 
wait
##sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}_ff.sql > ${DATA1_FILE}
#################################################################
# Check for the data load
#################################################################
echo -e "rpt_unaudited_sales Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
cat $DATA/o5_rpt_unaudited_sales.html | mailx -s  "${SUBJECT}" SaksDirectBI@saksinc.com hbcdigtialdatamanagement@hbc.com jonathan.greller@hbc.com Pamela_Han@hbc.com Kristen_Sosa@s5a.com John_Quinn@s5a.com Sofia_Moon@s5a.com Kelly_Alfree@s5a.com Nancy_Wong@s5a.com Melissa_Handy@s5a.com Nikki_VanEngel@s5a.com Tony_Gaspari@s5a.com Sarah_Sheppard@s5a.com Jeff_England@s5a.com Jill_Hickerson@s5a.com teri_gakos@S5A.com Cheryl_Hickey@s5a.com Stephanie_Mak@s5a.com Sara_Griffin2@s5a.com Aaron_Shockey@s5a.com William_Norris@s5a.com Josanne_Theodore@s5a.com Laura_Wheeler@s5a.com
##cat $DATA/o5_rpt_unaudited_sales_ff.html | mailx -s  "Off 5th.com Un-audited Sales Fashion Fix Report for `TZ=GMT+24 date +"%Y-%m-%d"`" SaksDirectBI@saksinc.com hbcdigtialdatamanagement@hbc.com
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
###################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#send_email
fi
exit 0
