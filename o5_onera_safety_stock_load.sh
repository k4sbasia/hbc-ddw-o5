#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_onera_safety_stock_load.sh
#####
#####   DESCRIPTION  : This script does the following
#####                  1. check to see if safety stock file exists for Onera
#####		       2. if file exists, download the file and load to onera_safety_stock and saks_custom.store_inventory table
#####		       3. generate report
#####
#####   CODE HISTORY :  Name                      Date            Description
#####                   ------------            ----------      ------------
#####
#####
#####
##################################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA/off5th_onera
export CTL=$HOME/CTL
export PROCESS='o5_onera_safety_stock_load'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export CTL_LOG="$DATA/${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export BAD_SUBJECT="${PROCESS} failed"
export DATA_FILE=$DATA/${PROCESS}.html
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export CONTROL_FILE="${CTL}/${PROCESS}.ctl"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export ONERA_DATA_FILE="Off5th_safety_stocks.txt"
export ONERA_FILE_NAME="o5_onera_file_check.txt"
export ONERA_OMS_DATA_FILE="Off5th_oms_safety_stocks.txt"
export ONERA_OMS_FILE_NAME="o5_onera_oms_file_check.txt"
export ONERA_WEEK_FILE="o5_onera_week_file.txt"
################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat /home/cognos/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo "The ${PROCESS} failed. ${CURRENT_TIME}"|mailx -s "${SUBJECT}" $address
 done
}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

# remove older files
if [ -f $DATA/safety_stock* ]
then
   rm $DATA/safety_stock*
fi

###### get latest file from onera server
ssh saks@feeds-saks.oneracommerce.com "ls -ltr /mnt/saks/saksoff5th/onera/safety_stocks*tsv | tail -1 | awk  '{print $9}' | sed 's/.*\///'" > $DATA/$ONERA_FILE_NAME
ONERA_FILENAME=`cat $DATA/$ONERA_FILE_NAME`

ssh saks@feeds-saks.oneracommerce.com "ls -ltr /mnt/saks/saksoff5th/onera/OFF5_node_level_safety_stocks*tsv | tail -1 | awk  '{print $9}' | sed 's/.*\///'" > $DATA/$ONERA_OMS_FILE_NAME
ONERA_OMS_FILENAME=`cat $DATA/$ONERA_OMS_FILE_NAME`

echo "ONERA_OMS_FILENAME :: ${ONERA_OMS_FILENAME} --- ONERA_FILENAME :: ${ONERA_FILENAME}"> ${LOG_FILE}
###### check last loaded file from database
DB_FILENAME=`sqlplus -s $CONNECTDW <<EOF
set heading off
select trim(filename) from o5.onera_loaded_file;
quit;
EOF`
DB_FILENAME=${DB_FILENAME:1}

if [ "$ONERA_FILENAME" == "$DB_FILENAME" ]
then
   echo "No new off 5th safety_stock file from Onera" >> ${LOG_FILE}
   exit 0
else # need to load the file

###################################################################
echo "Getting off 5th safety_stock file from Onera at `date '+%a %b %e %T'`" >> ${LOG_FILE}
cd ${DATA}

sftp saks@feeds-saks.oneracommerce.com  <<end-of-session
cd saksoff5th/onera/
get $ONERA_FILENAME $ONERA_DATA_FILE
get ${ONERA_OMS_FILENAME}
bye
end-of-session

#################################################################
echo "Started transferring Onera node level safety stocks file" >>${LOG_FILE}
#################################################################
sftp scoms@ccetlp01.hbc.com <<EOF>> ${LOG_FILE}
cd /rfs/items/oms
put ${ONERA_OMS_FILENAME}
chmod 777 ${ONERA_OMS_FILENAME}
quit
EOF

#echo "Started transferring Onera node level safety stocks to internal server" >>${LOG_FILE}
#sftp -oIdentityFile=/home/cognos/.ssh/vendor_keys/id_saks hbc-safety-stock@sftp2.data.hbc.io<<EOF>> ${LOG_FILE}
#cd hbc-safety-stock/O5/SAFETY/
#put ${ONERA_OMS_FILENAME}
#quit
#EOF

################################################################
echo "Finished Transferring Onera node level safety stocks file  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################

echo "Started sqlldr safety_stock file to mrep at `date '+%a %b %e %T'`" >>${LOG_FILE}

if [ ! -f $DATA/$ONERA_DATA_FILE ]
then
   echo "${PROCESS} has no file exist" >> ${LOG_FILE}
   exit 0
fi

#################################################################
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CTL_LOG BAD=$BAD_FILE DATA=$DATA/$ONERA_DATA_FILE ERRORS=999999999
cat $CTL_LOG >>${LOG_FILE}
echo "Finished sqlldr safety_stock file at `date '+%a %b %e %T'`" >${LOG_FILE}

STOCK_CNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
SELECT COUNT(*) FROM o5.ONERA_SAFETY_STOCK WHERE sfs_safety_stock > 0 ;
quit;
EOF`

if [ $STOCK_CNT -eq 0 ]
then
   cp $DATA/$ONERA_FILENAME $DATA/$ONERA_FILENAME.bad
   echo "${PROCESS} failed because all ship_from_store safety_stock is zero. Please investigate"
   echo "${PROCESS} failed because all ship_from_store safety_stock is zero. Please investigate" >> ${LOG_FILE}
   export SUBJECT="Off 5th Onera SS Recommendations Load failed because all ship_from_store safety_stock is zero. Please investigate"
   echo "Off 5th Onera SS Recommendations Load failed because all all ship_from_store safety_stock is zero!!!" | mailx -s "${SUBJECT}" grace_yang@saksinc.com
   exit 1
fi

echo "insert data to saks_custom and mrep history table `date '+%a %b %e %T'`" >>${LOG_FILE}
## Liya commented this on 07/06/2016 because safetry srock update comes from OMS
##sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql "$update_environment" >> ${LOG_FILE}
fi

DB_FILENAME=`sqlplus -s $CONNECTDW <<EOF
set heading off
update o5.onera_loaded_file set filename = '${ONERA_FILENAME}';
quit;
EOF`

echo "generate report for `date '+%a %b %e %T'`" >>${LOG_FILE}

LOADED_CNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*) from o5.ONERA_SAFETY_STOCK;
quit;
EOF`

SUBJECT="Off 5th Safety Stock load report `date '+%m/%d/%y %H:%M:%S'`"
FILE_NAME=`cat $DATA/$ONERA_FILE_NAME`
REC_CNT=`cat $DATA/$ONERA_DATA_FILE | wc -l`
REC_CNT=`expr $REC_CNT - 1`
DATE_CNT=`date +%V`
if [ -f $DATA/$ONERA_WEEK_FILE ]
then
WEEK_IND=`cat $DATA/$ONERA_WEEK_FILE`
else
WEEK_IND=`date +%V`
fi

if [ $DATE_CNT -eq $WEEK_IND ]
then
echo -e "=================================================================================\n" >> $DATA/${PROCESS}.txt
else
echo -e "=================================================================================\n" > $DATA/${PROCESS}.txt
fi
echo -e "Off 5th Onera SS Recommendations Load -- `date '+%m/%d/%y %H:%M:%S %A'`" >> $DATA/${PROCESS}.txt
echo -e "File Name: $FILE_NAME" >> $DATA/${PROCESS}.txt
echo -e "$REC_CNT = Number of records in Off 5th onera file for `date '+%m/%d/%y %H:%M:%S'`" >> $DATA/${PROCESS}.txt
echo -e "$LOADED_CNT = Number of records loaded to Off 5th onera_safety_stock table for `date '+%m/%d/%y %H:%M:%S'`" >> $DATA/${PROCESS}.txt
if [ -f ${BAD_FILE} ]
then
    BAD_CNT=`wc -l $BAD_FILE | awk '{split($0,a," "); print a[1]}'`
    echo -e "$BAD_CNT =  Number of records NOT loaded to Off 5th onera_safety_stock table for `date '+%m/%d/%y %H:%M:%S'`\n" >> $DATA/${PROCESS}.txt
else
    echo -e "0 =  Number of records NOT loaded to Off 5th onera_safety_stock table for `date '+%m/%d/%y %H:%M:%S'`\n" >> $DATA/${PROCESS}.txt
fi
echo `date +%V` > $DATA/onera_week_file.txt

#cat $DATA/${PROCESS}.txt | mailx -s "${SUBJECT}" Grace_Yang@saksinc.com
cat $DATA/${PROCESS}.txt | mailx -s "${SUBJECT}" hbcdigitaldatamanagement@saksinc.com _298314@saksinc.com Hepzi_LeonSoon@saksinc.com Bill_Holland@saksinc.com Jayanth_Kalluri@saksinc.com srinath@oneracommerce.com sahil@oneracommerce.com paul@oneracommerce.com Stephanie_Mak@saksinc.com Sashi_Gopalan@saksinc.com Richard_Jap@saksinc.com

# remove any file that are older than 2 hours
find ${DATA} -name safety_stocks* -type f -mmin +720 -delete

##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "Report  PROCESS ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
#################################################################
# Check for errors
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
