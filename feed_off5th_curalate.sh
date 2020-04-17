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
#####                                         07/19/2016      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
export PROCESS='feed_off5th_curalate'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export DATA_FILE=$DATA/saksoff5th_`date +"%Y%m%d"`.csv
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export ROW_COUNT=0
########################################################################
echo -e "Off 5th Curalate Feed started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
#  Run the sql script that generates the Product File
#################################################################
sqlplus -l -s  $CONNECTDW @${SQL}/${PROCESS}.sql >> ${DATA_FILE}
wait
export ROW_COUNT=`cat ${DATA_FILE} | wc -l`
################################################################a
# SFTP File to Curalate Server
################################################################
lftp -u client_10729,'j@C?Vn3M&+yNYJjA' sftp://sftp.curalate.com <<EOF>> ${LOG_FILE}
put ${DATA_FILE} ${DATA_FILE}
quit
EOF
################################################################
echo -e "Off 5th Curalate Feed ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
exit 99
else
echo "The Saks Off 5th Curalate Product Feed has been Posted. File Name: saksoff5th_20170830.csv  - ${ROW_COUNT} Rows" | mailx  -s "Off 5th Curalate Product Feed Was Posted." -r hbcdigtialdatamanagement@hbc.com hbcdigtialdatamanagement@hbc.com donovan_adams@s5a.com timothy_dufresne@s5a.com Rose_Moda@s5a.com ricky@curalate.com
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
exit 0
fi
