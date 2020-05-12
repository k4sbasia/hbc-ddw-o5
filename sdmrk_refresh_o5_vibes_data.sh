#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : sdmrk_refresh_o5_vibes_data
#####
#####   DESCRIPTION  : This script does the following
#####	             1.Stage CheetahMail Unsubscription
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Sripriya Rao		07/22/2018      Created
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
export PROCESS='sdmrk_refresh_o5_vibes_data'
export CONTROL_FILE="${CTL}/${PROCESS}.ctl"
export PAR_FILE="${CTL}/${PROCESS}.par"
export CONTROL_LOG="${LOG}/${PROCESS}.log"
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_FILE="${DATA}/${PROCESS}.bad"
export YDAY=`date +%Y-%m-%d -d"1 day ago"`
export FILE_NAME="subscriptions_${YDAY}.csv"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
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
sqlplus -sl $CONNECTSDMRK12C <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
cd $DATA
lftp -u off5th5498,'4fe29ea35cee5' sftp://upload.vibes.com<<EOF>>$LOG_FILE
cd "files/Daily Subscription Files"
get ${FILE_NAME}
quit
EOF

if [ ! $DATA/${FILE_NAME} ]
then
   echo "Current week's Saks SMS file not received..Please contact Vibes!!!" >> $LOG_FILE
   exit 99
fi

sed -i 's/\t/\,/g' $DATA/${FILE_NAME}

##Load Data
#################################################################
sqlldr $CONNECTSDMRK12C CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=${DATA}/${FILE_NAME}  ERRORS=999999 SKIP=1 <<EOT>> $CONTROL_LOG
EOT
retcode=`echo $?`
case "$retcode" in
        0) echo "SQL*Loader execution successful" >> ${LOG_FILE};;
        1) echo "SQL*Loader execution exited with EX_FAIL, see logfile" >> ${LOG_FILE};;
        2) echo "SQL*Loader execution exited with EX_WARN, see logfile" >> ${LOG_FILE};;
        3) echo "SQL*Loader execution encountered a fatal error" >> ${LOG_FILE};;
        *) echo "unknown return code" >> ${LOG_FILE};;
esac
if [ $retcode -ne 0 ]
then
        if [ $retcode -ne 2 ]
        then
                echo "ERROR in loading Saks SMS subscription file from Vibes"
                echo "Aborting..." >> ${LOG_FILE}
                exit 99
        else
                echo "Saks SMS subscription file from Vibes successfully loaded..see ${LOG_FILE} for warnings"
        fi
else
        echo "Saks SMS subscription file from Vibes successfully loaded"
fi

## Merge data into history table
#################################################################
sqlplus -s -l $CONNECTSDMRK12C<<EOF>>$LOG_FILE
set echo off
set heading off
set feedback off
set verify off
merge into sdmrk.o5_vibes_data_lookup trg
using (select person_id,
              external_person_id,
              mdn,
              company_id,
              carrier_code,
              subscription_list_id,
              opt_in_date,
              opt_out_date,
              subscription_event,
              opt_out_reason,
              case when subscription_event = 'optIn' then opt_in_date else opt_out_date end event_timestamp
        from sdmrk.o5_vibes_data_wrk) src
on (trim(trg.person_id) = trim(src.person_id) and
    trim(nvl(trg.external_person_id,' ')) = trim(nvl(src.external_person_id,' ')) and
    trim(trg.mdn) = trim(src.mdn) and
    trim(trg.company_id) = trim(src.company_id) and
    trim(trg.carrier_code) = trim(src.carrier_code))
when matched then update
set trg.subscription_list_id = src.subscription_list_id,
    trg.opt_in_date = src.opt_in_date,
    trg.opt_out_date = src.opt_out_date,
    trg.subscription_event = src.subscription_event,
    trg.opt_out_reason = src.opt_out_reason,
    trg.event_timestamp = src.event_timestamp
when not matched then insert(
              person_id,
              external_person_id,
              mdn,
              company_id,
              carrier_code,
              subscription_list_id,
              opt_in_date,
              opt_out_date,
              subscription_event,
              opt_out_reason,
              event_timestamp)
values(       src.person_id,
              src.external_person_id,
              src.mdn,
              src.company_id,
              src.carrier_code,
              src.subscription_list_id,
              src.opt_in_date,
              src.opt_out_date,
              src.subscription_event,
              src.opt_out_reason,
              case when src.subscription_event = 'optIn' then src.opt_in_date else src.opt_out_date end
);
commit;
merge into SDMRK.o5_vibes_data_hst trg
using (select person_id, mdn,subscription_event,event_timestamp
       from SDMRK.o5_vibes_data_lookup
      ) src
on (trg.person_id = src.person_id and
    trg.mobile_phone = src.mdn and
    trg.event_type = src.subscription_event and
    trg.event_timestamp = src.event_timestamp
    )
when not matched then
insert (person_id, mobile_phone,event_type,event_timestamp)
values (src.person_id, src.mdn, src.subscription_event,src.event_timestamp);
commit;
quit;
EOF

retcode=$?
if [ $retcode -ne 0 ]
then
        echo "SQL Error in loading and merging Saks SMS subscription data from Vibe into history table...Please check" >> ${LOG_FILE}
else
        echo "Successfully loaded and merged Saks SMS subscription data from Vibe into history table" >> ${LOG_FILE}
fi

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -sl $CONNECTSDMRK12C <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
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
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
fi
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
exit 0
fi
