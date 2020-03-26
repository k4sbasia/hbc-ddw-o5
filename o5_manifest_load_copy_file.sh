#!/bin/bash
#############################################################################################################################
#####                           Saks Direct
##############################################################################################################################
#####
#####   PROGRAM NAME : manifest_load
#####
#####   DESCRIPTION  : This script does the following
#####                              1. download saks.txt file from scene 7
#####				   2. scp the file to production
#####				   3. this is a tempoary alternative until scene7 url is whitelisted
#####
#####   CODE HISTORY :                     Name                   Date          Description
#####                                   ------------            ----------      ------------
#####                                   David Alexander          07/12/2013     Created
#####
#####
##############################################################################################################################
. $HOME/initvars
export PROCESS='o5_manifest_load_copy_file'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME="${DATA}/saksFile.txt"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SLEEP_TIME=300
export SLEEP_CYCLES=20
export RUN_SUBJECT="${PROCESS} has started."
export SLEEP_SUBJECT="${PROCESS} is sleeping."
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CTL_LOG="$LOG/${PROCESS}_ctl.log"
export BAD_FILE="$LOG/${PROCESS}_bad.bad"
export FAILURE="F"
export LOOP="REPEAT"
export COUNTER=0
export DATE=$(date +"%a")
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^6'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
echo -e "manifest load started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTMANIFESTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##FTP Manifest Delta File
cd ${DATA}
if [ -f saksoff5th.txt ]
then
cp saksoff5th.txt saksoff5th_yday.txt
fi

while [ "$LOOP" = "REPEAT" ]
do
  COUNTER=`expr $COUNTER + 1`
#wget -r -nH ftp://adobesaks:Ad0b3D1r3ct@saks.download.akamai.com/saks.txt
#wget -r -nH ftp://adobesaks:Ad0b3D1r3ct@saks.download.akamai.com/saks.txt -a ${LOG_FILE}
curl -O ftp://adobeo5a:Ad0b3D1r3ct@saks.download.akamai.com/saksoff5th.txt > ${LOG_FILE} 2>&1
#rsync -arv -e "ssh -2 -i netstorage_key" sshacs@saks.upload.akamai.com:/8756/adobe/saks.txt /home/cognos/DATA/
wait

wc -l saksoff5th.txt > o5_manifest_row_count.txt

diff o5_manifest_row_count.txt o5_manifest_row_count_old.txt > o5_manifest_diff.txt

wc -l o5_manifest_diff.txt > o5_manifest_linecnt.txt
COUNT=(`cat o5_manifest_linecnt.txt | awk '{print $1}'`)

 if [ $COUNT -eq 0 ]
 then

  if [ $COUNTER -eq 1 ]
  then
     FDATE=(`ls -l o5_manifest_row_count_old.txt | awk '{print $7}'`)
     LDATE=(`ls -l o5_manifest_row_count.txt | awk '{print $7}'`)

     if [ "$FDATE" != "$LDATE" ]
     then
        if [ $COUNTER -eq 10 ]
        then
          FAILURE="T"
          LOOP="NO_REPEAT"
        else
          FAILURE="T"
          LOOP="REPEAT"
          sleep 10m
        fi
     fi

   else
     if [ $COUNTER -eq 10 ]
     then
       FAILURE="T"
       LOOP="NO_REPEAT"
     else
       FAILURE="T"
       LOOP="REPEAT"
       sleep 10m
     fi
   fi
else
    LOOP="NO_REPEAT"
    FAILURE="F"
fi

mv o5_manifest_row_count.txt o5_manifest_row_count_old.txt
done


if [ $FAILURE = "T" ] && ([ "${DATE}" != "Sun" ] && [ "${DATE}" != "Mon" ]);
then
    echo "scene 7 manifest file for Off 5th.com is not updated"|mailx -s "Scene 7 manifest file for Off 5th.com is not updated" hbcdigtialdatamanagement@hbc.com
else
    echo "scene 7 manifest file for Off 5th.com is updated or no changes on Saturday/Sunday" >> ${LOG_FILE}
fi


sftp sd1pdw01vl.saksdirect.com  <<end-of-session
put saksoff5th.txt
bye
end-of-session

###################################################################

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTMANIFESTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "manifest load Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553|Login incorrect|RETR response: 550|refused" ${LOG_FILE}` -ne 0 ]
then
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
else
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit 0
