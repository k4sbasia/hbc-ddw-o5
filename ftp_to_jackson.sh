#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : ftp to jackson.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Refresh The Data In Marketing Data Mart
#####
#####
#####   CODE HISTORY :                    Name                    Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Ishvpreet Singh	        07/31/2017      created
#############################################################################################################################
################################################################
. $HOME/initvars
export PROCESS='ftp_to_jackson'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME_ORDER=$1
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'

cd ${DATA}
echo "Ftp the file ${FILE_NAME_ORDER} to Jackson SAS server" > ${LOG_FILE}
ftp -nv 10.130.176.210  <<EOF>>${LOG_FILE}
user sasftp sasftp0313S
prompt off
bin
put  ${FILE_NAME_ORDER}
quit
EOF
################################################################
cd ${HOME}

if [ `egrep -c "^ERROR|ORA-|invalid identifier|failed|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit 0
