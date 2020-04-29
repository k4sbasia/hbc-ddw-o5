#############################################################################################################################
#####                           OFF5TH INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_sdmrk_refresh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Refresh The Data In Marketing Data Mart
#####
#####
#####   CODE HISTORY :                    Name                    Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Divya Kafle	        09/08/2013      Modified
#####									Sripriya Rao		10/03/2016		Modified(Logic added to include SDMRK job status table)
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_sdmrk_refresh'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export GOOD_SUBJECT="${PROCESS} completed successfully"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^15'|while read group address
 do
 echo "The ${PROCESS} completed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}

echo "${PROCESS} started: `date`" > ${LOG_FILE}

#################################################################
### Insert a row in job_status table to show job_status as STARTED
#################################################################
sqlplus -s -l $CONNECTSDMRK12C<<EOF>>${LOG_FILE}
set echo off
set heading off
set feedback off
set verify off
insert into SDMRK.JOB_STATUS(job_name, job_description, run_date, job_start_time, job_status,banner) values (upper('${PROCESS}'),'Complete Daily Off5th SDMRK Refresh',sysdate,systimestamp,'STARTED','OFF5TH');
commit;
quit;
EOF
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in inserting a row in the SDMRK job_status table for the process ${PROCESS}...Please check" >> ${LOG_FILE}
else
        echo "Insert of a row in SDMRK job_status table for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi

#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#####################################################################
#### Set job start time
#####################################################################
JOB_START_TIME=`sqlplus -s -l $CONNECTSDMRK12C<<EOF
set heading off
select JOB_START_TIME from SDMRK.JOB_STATUS where job_name = upper('${PROCESS}') and job_status = 'STARTED' and trunc(run_date) = trunc(sysdate);
quit;
EOF`

#################################################################
### Update the row in job_status table to show job_status as IN PROGRESS
#################################################################
sqlplus -s -l $CONNECTSDMRK12C<<EOF>>${LOG_FILE}
set echo off
set heading off
set feedback off
set verify off
update SDMRK.JOB_STATUS
set job_status = 'IN PROGRESS'
where job_start_time = '${JOB_START_TIME}' and job_name = upper('${PROCESS}') and job_status = 'STARTED';
commit;
quit;
EOF
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in updating a row in the SDMRK job_status table for the process ${PROCESS}...Please check" >> ${LOG_FILE}
else
        echo "Update of a row in SDMRK job_status table for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi

#################################################################
##DB SQL
#################################################################
sqlplus -s -l $CONNECTSDMRK12C <<EOF> ${LOG_FILE} @${SQL}/${PROCESS}_12c.sql >> ${LOG_FILE}
EOF

################################################################

##Update Runstats Finish
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

echo "SDMRK Re-Fresh of ORDERS, PRODUCT, HIERARCHY and INDIVIDUAL Completed at `date`"

#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|invalid identifier|failed|not found|SP2-0" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
#################################################################
### Update the row in job_status table to show job_status as FAILED
#################################################################
sqlplus -s -l $CONNECTSDMRK12C<<EOF>>${LOG_FILE}
set echo off
set heading off
set feedback off
set verify off
update SDMRK.JOB_STATUS
set job_status = 'FAILED', job_end_time = systimestamp
where job_start_time = '${JOB_START_TIME}' and job_name = upper('${PROCESS}') and job_status = 'IN PROGRESS';
commit;
quit;
EOF
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in updating a row in the SDMRK job_status table for the process ${PROCESS}...Please check" >> ${LOG_FILE}
else
        echo "Update of a row in SDMRK job_status table for the process ${PROCESS} is complete" >> ${LOG_FILE}
fi
export SUBJECT=${BAD_SUBJECT}
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
#################################################################
### Update the row in job_status table to show job_status as COMPLETED
#################################################################
sqlplus -s -l $CONNECTSDMRK12C<<EOF>>${LOG_FILE}
set echo off
set heading off
set feedback off
set verify off
update SDMRK.JOB_STATUS
set job_status = 'COMPLETED', job_end_time = systimestamp
where job_start_time = '${JOB_START_TIME}' and job_name = upper('${PROCESS}') and job_status = 'IN PROGRESS';
commit;
quit;
EOF
retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in updating a row in the SDMRK job_status table for the process ${PROCESS}...Please check" >> ${LOG_FILE}
        exit 99
else
        echo "Update of a row in SDMRK job_status table for the process ${PROCESS} is complete" >> ${LOG_FILE}
        exit 0
fi
export SUBJECT="${GOOD_SUBJECT}"
send_email
fi
