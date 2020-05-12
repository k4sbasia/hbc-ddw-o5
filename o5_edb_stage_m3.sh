#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_stage_m3.sh
#####
#####   DESCRIPTION  : This script does the following
#####	             1.Stage M3 Data (Point of Sale)
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Divya Kafle			06/04/2013      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS='o5_edb_stage_m3'
export CONTROL_FILE="${CTL}/${PROCESS}.ctl"
export CONTROL_LOG="${LOG}/${PROCESS}.log"
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_FILE="${DATA}/${PROCESS}.bad"
export today=${today:-$(date +%Y%m%d)}
export FILE_NAME="daily_m3_${today}.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export CONTROL_FILE2="${CTL}/${PROCESS}_update.ctl"

########################################################################
echo "${PROCESS} PROCESS started " >${LOG_FILE}
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
#################################################################
##Update Runstats Start
echo "${PROCESS} PROCESS started" > ${LOG_FILE}
#################################################################
echo "Getting the m3 file" >> ${LOG_FILE}
cp /home/ftservice/INCOMING/$FILE_NAME /home/cognos/DATA

cd $DATA
FILE_COUNT=`head -2 ${FILE_NAME} | tail -1| cut -c4-`
FILE_COUNT=$(expr ${FILE_COUNT} - 2)
echo "Trailer count in the m3 file we received : ${FILE_COUNT}" >> ${LOG_FILE}

sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
##Load Data
#################################################################
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=${DATA}/${FILE_NAME}  ERRORS=999999 SKIP=2 <<EOT>> $CONTROL_LOG
EOT
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE2 LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=${DATA}/${FILE_NAME}  ERRORS=999999 SKIP=2 <<EOT>> $CONTROL_LOG
EOT
mv ${DATA}/${FILE_NAME} ${DATA}/ARCHIVE/${FILE_NAME}
#################################################################
##Load counts
TARGET_COUNT=`sqlplus -s -l  $CONNECTDW <<EOF
set heading off
select count(*)
from o5.EDB_STAGE_SUB where trunc(staged)=trunc(sysdate) and SOURCE_ID = 9165 ;
quit;
EOF`
echo "The Total record Loaded are : $TARGET_COUNT" >> ${LOG_FILE}

echo -e "Load Count check for the M3 data : $TARGET_COUNT ">> ${LOG_FILE}
                              if [ $FILE_COUNT = $TARGET_COUNT ]
                                then
                                echo -e "The counts matches with the m3 file counts \n">>${LOG_FILE}
                              else
                                echo -e "The trailer counts DOES NOT MATCH\n" >>${LOG_FILE}
                                #exit 99
                              fi

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo "${PROCESS} PROCESS ended " >> ${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ] || [ `egrep -c "^ERROR|ORA-|SP2-0|^553"  ${CONTROL_LOG}` -ne 0 ]
then
if [ `egrep -c "ORA-12899" ${CONTROL_LOG}` -ne 0 ]
then
echo "${PROCESS} completed.There were some bad data" >> ${LOG_FILE}
send_email
else
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
fi
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit $?
