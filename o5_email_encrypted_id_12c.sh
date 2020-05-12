#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_email_encrypted_id.sh
#####
#####   DESCRIPTION  : This script does the following
#####
#####   CODE HISTORY :
#####                   Name                     Date           Description
#####                  ------------            ----------      ------------
#####		           Sripriya Rao	           12/22/2015	      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
#set -xu
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS="o5_email_encrypted_id"
export CONTROL_FILE="$CTL/${PROCESS}_12c.ctl"
export CONTROL_LOG="$LOG/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export EXTRACT_SQL="$SQL/${PROCESS}.sql"
export today=`date +%Y%m%d`
export yesterday=`date +%Y%m%d -d"1 day ago"`
export DATAPULL_DATE=$today
export EMAIL_HIST_FILE_ZIP="ForSaks_${today}_Off5th_EmailUserProfID_DataPull_${DATAPULL_DATE}.dat.gz"
export EMAIL_HIST_FILE_DAT="ForSaks_${today}_Off5th_EmailUserProfID_DataPull_${DATAPULL_DATE}.dat"
export EMAIL_DAILY_FILE_ZIP="ForSaks_${today}_OmnitureUserIDtoEmail_subs_${yesterday}.dat.gz"
export EMAIL_DAILY_FILE_DAT="ForSaks_${today}_OmnitureUserIDtoEmail_subs_${yesterday}.dat"
#### For Testing
#export EMAIL_HIST_FILE_ZIP="ForSaks_20160107_Off5th_EmailUserProfID_DataPull_20151215.gz"
#export EMAIL_HIST_FILE_DAT="ForSaks_20160107_Off5th_EmailUserProfID_DataPull_20151215"
#export EMAIL_DAILY_FILE_ZIP="ForSaks_20160112_OmnitureUserIDtoEmail_subs_20160111.dat.gz"
#export EMAIL_DAILY_FILE_DAT="ForSaks_20160112_OmnitureUserIDtoEmail_subs_20160111.dat"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
export TARGET_COUNT=0
export HIST_FLAG=$1
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
function send_delay_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 export SUBJECT=${BAD_SUBJECT}
 BSUBJECT="o5_email_encrypted_id in Automic Client 10 Failed"
 BBODY="o5_email_encrypted_id failed, please look into it. Thanks!"
 BADDRESS='SaksDirectDataManagement@saksinc.com'
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" ${BADDRESS}
 send_email
}
echo "Starting the process ${PROCESS} `date '+%a %b %e %T %Z %Y'` " > ${LOG_FILE}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$LOG_FILE" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

########################################################################
### Check the HIST_FLAG to see if we are loading the history/daily file

if [ $HIST_FLAG == 'T' ]
then
	echo "Flag set to load the history file" >> ${LOG_FILE}
	FILE_ZIP=$EMAIL_HIST_FILE_ZIP
	FILE_DAT=$EMAIL_HIST_FILE_DAT
else
	echo "Flag set to load the daily file" >> ${LOG_FILE}
        FILE_ZIP=$EMAIL_DAILY_FILE_ZIP
        FILE_DAT=$EMAIL_DAILY_FILE_DAT
fi

########################################################################
## Fetch the Email sub file with encrypted ids from Cheetah
#################################################################
#echo "Fetch the Email sub file with encrypted ids from Cheetah at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
#cd $DATA
#lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>${LOG_FILE}
#cd fromcheetah
#get "$FILE_ZIP"
#quit
#EOF
#
#cp /home/marketing/o5fromcheetah/$FILE_ZIP $DATA
cd $DATA
ftp -nv filerepo.saksdirect.com << EOF>$LOG_FILE
user marketing MarOCT=2015
cd o5fromcheetah
bin
get $FILE_ZIP $FILE_ZIP
quit
EOF
#########################################################################
### check if Saks Canada subscription file exists
##################################################################
if [ -f $DATA/$FILE_ZIP ]
then
	echo "$FILE_ZIP" >>${LOG_FILE}
	echo "Email Sub file $FILE_ZIP is available `date '+%a %b %e %T'`">>${LOG_FILE}
	echo "Unzipping $FILE_ZIP" >>${LOG_FILE}
	gunzip $DATA/$FILE_ZIP
else
	echo "Email Sub file $FILE_ZIP is not available `date '+%a %b %e %T'`">>${LOG_FILE}
	echo "Aborting..." >> ${LOG_FILE}
	exit 99
fi

#################################################################################################
## Load the Email Sub File from CM to O5.O5_EDB_CM_EMAIL_SUB_WRK
#################################################################################################
echo " Loading the EMAIL_DAILY_FILE_SUB into the staging table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
echo "sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$FILE_DAT ERRORS=99999999 SKIP=1"
sqlldr $CONNECTSDMRK12C CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$FILE_DAT ERRORS=99999999 SKIP=1
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
                echo "ERROR in loading Email encrypt id file from CM in to the staging table"
		echo "Aborting..." >> ${LOG_FILE}
		send_delay_email
        	exit 99
        else
                echo "Email encrypt id file from CM successfully loaded in to the staging table..see ${LOG_FILE} for warnings"
        fi
else
        echo "Email encrypt id file from CM successfully loaded in to the staging table"
fi

#################################################################################################
## Append the Email data to SDMRK.O5_EMAIL_ENCRYPTID
################################################################################################
echo " Inserting into SDMRK.O5_EMAIL_ENCRYPTID and O5.O5_EDB_CM_EMAIL_SUB_HIS at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C @${SQL}/${PROCESS}_12c.sql >> ${LOG_FILE}

#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$LOG_FILE" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_delay_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
