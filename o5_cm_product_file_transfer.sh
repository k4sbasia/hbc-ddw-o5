#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_cm_product_file_transfer.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Posts the O5 cm_product file to SAS Server
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------     	  ------------
#####					Sripriya Rao		03/25/2016	  Created
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
export PROCESS="o5_cm_product_file_transfer"
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
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
export today=${today:-$(date +%Y%m%d)}
export FILE_NAME="o5_cm_product_${today}.txt"
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^15'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
echo "${PROCESS} started at `date '+%a %b %e %T'`" > ${LOG_FILE}

###################################################################
#### Check if today's O5 cm_product file exists in the DATA dir
###################################################################
echo "Checking if $FILE_NAME exists in $DATA..." >> ${LOG_FILE}

if [ -f $DATA/$FILE_NAME ]
then
	echo "Transfering $FILE_NAME to SAS Server... at `date '+%a %b %e %T'`" >> ${LOG_FILE}
	smbclient -C "\\\\nyco-ms-psas01.intranet.saksroot.saksinc.com\DWfiles\\" --authentication-file /home/ddwo5/auth.txt --command 'lcd '$DATA';put '$FILE_NAME';quit'
	echo "$FILE_NAME successfully transfered to SAS Server... at `date '+%a %b %e %T'`" >> ${LOG_FILE}
else
	 echo "$DATA/$FILE_NAME does not exist...please check" >> ${LOG_FILE}
	 exit 99
fi

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
echo "$PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
# Check for errors
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
