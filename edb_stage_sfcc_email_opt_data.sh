#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : edb_stage_sfcc_email_opt_data.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Fetch the Email Opt-In delta file from SFCC sftp
#####
#####   CODE HISTORY :  		Name                    Date            Description
#####                                   ------------            ----------      ------------
#####                                   Sripriya Rao           	11/06/2019      Created
#####
#####
#############################################################################################################################
################################################################
set -x
. $HOME/params.conf $1
echo $HOME
export BANNER=$1
export PROCESS='edb_stage_sfcc_email_opt_data'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="$LOG/${BANNER}_${PROCESS}_log.txt"
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
export VALIDATE_COUNT='1'
export DELTA_FILE_NAME="emailSubscriptionFeed"
#export CONNECTDW="bay_ds/hbc#1234@QASDW" --needs to be commented if running for QA
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

########################################################################################
########Run the stats####################################################################
sqlplus -s -l $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
echo -e "${PROCESS} process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
cd $DATA
sftp -o "IdentityFile=~/.ssh/${SFCC_PII_KEY}" ${SFCC_PII_USER}@sftp.integration.awshbc.io <<< "get ${SFCC_subscriptions_dir}/${DELTA_FILE_NAME}*.csv"

#### Fetch Email Opt data delta feed from SFCC sftp #####
####

#### add sftp details

####
cd ${HOME}
for f in $(find ${DATA} -maxdepth 1 -iname ${DELTA_FILE_NAME}*.csv -printf "%f\n" | sort -n) ; do
echo $f >> ${LOG_FILE}
PRCSD=`sqlplus -s $CONNECTDW <<EOF
set heading off
select PRRCSD from O5.FILE_PROCESS_STATUS WHERE PROCESS_NAME='INV_LOAD' and FILE_NAME='${f}';
quit;
EOF`
if [ $PRCSD -eq 'C' ]
then
  sqlplus -s -l $CONNECTDW<<EOF>>${LOG_FILE}
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT
    set echo off
    set heading off
    set feedback off
    set verify off
    insert into O5.FILE_PROCESS_STATUS(PROCESS_NAME ,FILE_NAME) VALUES ('INV_LOAD','${f}');
    quit;
    EOF
echo sqlldr $CONNECTDW CONTROL=$CTL/${PROCESS}.ctl LOG=$LOG/${PROCESS}.log BAD=$DATA/${PROCESS}.bad DATA=${DATA}/${f} ERRORS=999999 SKIP=1
sqlldr $CONNECTDW CONTROL=$CTL/${PROCESS}.ctl LOG=$LOG/${PROCESS}.log BAD=$DATA/${PROCESS}.bad DATA=${DATA}/${f} ERRORS=999999 SKIP=1
retcode=`echo $?`
  case "$retcode" in
              0) echo "SQL*Loader execution successful" >> ${LOG_FILE};;
              1) echo "ERROR: SQL*Loader execution exited with EX_FAIL, see logfile" >> ${LOG_FILE};;
              2) echo "ERROR: SQL*Loader execution exited with EX_WARN, see logfile" >> ${LOG_FILE};;
              3) echo "ERROR: SQL*Loader execution encountered a fatal error" >> ${LOG_FILE};;
              *) echo "unknown return code" >> ${LOG_FILE};;
  esac
      if [ $retcode -ne 0 ]
      then
      	echo "ERROR: SQL*Loader execution encountered an error for file ${f} " >> ${LOG_FILE}
					                 exit 99
      else
              echo "${DELTA_FILE_NAME} staging is successfull" >> ${LOG_FILE}
              #sftp -o "IdentityFile=~/.ssh/${SFCC_PII_KEY}" ${SFCC_PII_USER}@sftp.integration.awshbc.io <<< "rename ${SFCC_subscriptions_dir}/${f} ${SFCC_subscriptions_dir}/processed_${f}"
              mv $DATA/${f} $DATA/ARCHIVE
      fi
#################################################################
sqlplus -s -l $CONNECTDW <<EOF>> ${LOG_FILE} @$SQL/${PROCESS}.sql "bay_ds." >> ${LOG_FILE}
EOF
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in processing ${DELTA_FILE_NAME}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Email Opt In data from ${DELTA_FILE_NAME} processed successfully" >> ${LOG_FILE}
fi
sqlplus -s -l $CONNECTDW<<EOF>>${LOG_FILE}
  WHENEVER SQLERROR EXIT SQL.SQLCODE
  WHENEVER OSERROR EXIT
  set echo off
  set heading off
  set feedback off
  set verify off
  UPDATE O5.FILE_PROCESS_STATUS SET PRRCSD='C' WHERE PROCESS_NAME='INV_LOAD' AND FILE_NAME ='${f}');
  quit;
  EOF
fi
done
#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553|not connected" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi


exit $?
