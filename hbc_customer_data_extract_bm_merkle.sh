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
#####                                   Sripriya Rao            07/19/2016      Created
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
. $HOME/initvars
export LBANNER=`echo $BANNER | tr 'a-z' 'A-Z'`
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='hbc_customer_data_extract_bm'
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export CONTROL_FILE="$CTL/${PROCESS}_${BANNER}.ctl"
export CTL_LOG="$LOG/${PROCESS}_${BANNER}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export today=${today:-$(date +%Y%m%d)}
export FILE_NAME="${LBANNER}_CUST_PROFILE_DLY_${today}.txt"
export SQL_FILE_DLY="${PROCESS}_${BANNER}"
export SFILE_SIZE=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export LOAD_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
export HDR_FILE_DLY="${DATA}/tmp_${BANNER}_customer_data_header.txt"
export DAT_FILE_DLY="${DATA}/tmp_${BANNER}_customer_data.txt"
export TRL_FILE_DLY="${DATA}/tmp_${BANNER}_customer_data_trailer.txt"
export FINAL_FILE_DLY="${DATA}/SFCC_${LBANNER}_CUST_PROFILE_DLY.txt"
export MERKLE_FILE_DLY="${DATA}/SFCC_${LBANNER}_CUST_PROFILE_DLY_${today}.txt"
######################################################################
#Initialize Email Function
######################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE}|mailx -s "${SUBJECT}" $address
 done
}
######Run the stats####################################################################
sqlplus -s -l  $CONNECTDW <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

###### Check the Type for the extract####################################################################
export SQL_FILE=${SQL_FILE_DLY}
export FINAL_FILE=${FINAL_FILE_DLY}
export MERKLE_FILE=${MERKLE_FILE_DLY}
export HDR_FILE=${HDR_FILE_DLY}
export DAT_FILE=${DAT_FILE_DLY}
export TRL_FILE=${TRL_FILE_DLY}
##### Extract Customer data from Blue Martini / Mongo #####
echo "Process started" >${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${SQL_FILE_DLY}.sql > $DAT_FILE
echo "Process creating the data file completed" >>${LOG_FILE}
if [ -f $DAT_FILE ] && [ `egrep -c "^ERROR|^ORA-|not found|SP2-0|^553" ${DAT_FILE}` -eq 0 ]
then
#########Check the file counts and generate the final Customer Data Extract File###########
ROW_COUNT=`wc ${DAT_FILE} | awk '{print $1-1}'`
echo "TRL|${ROW_COUNT}" > ${TRL_FILE}
if [ $ROW_COUNT  != 0 ]
then
echo "HDR: `date +%Y-%m-%d`" > ${HDR_FILE}
cat ${HDR_FILE} ${DAT_FILE} ${TRL_FILE} > ${FINAL_FILE}
############ Encrypt/Post the file to Merkle ############
cp ${FINAL_FILE} ${MERKLE_FILE}
gpg --encrypt --default-recipient 'Merkle HDBC' ${MERKLE_FILE}
#### Posting to Merkle Dev server
if [ $BANNER = "saks" ]
then
###### Posting to Merkle Prod server - added on 10/12/2016
lftp -u HDBCMAIN9482,'jKwl9Dof!wr(' sftp://fm.merkleinc.com<<EOF>>$LOG_FILE
cd Inbox
put ${MERKLE_FILE}.gpg
quit
EOF
elif [ $BANNER = "o5" ]
then
lftp -u HDBCMAIN9482,'jKwl9Dof!wr(' sftp://fm.merkleinc.com<<EOF>>$LOG_FILE
cd Inbox
put ${MERKLE_FILE}.gpg
quit
EOF
fi
rm ${HDR_FILE}
rm ${DAT_FILE}
rm ${TRL_FILE}
else
echo "${BANNER} Customer Data extract file is empty..aborting..please check!!!" >> ${LOG_FILE}
exit 99
fi
else
echo "${BANNER} Customer Data file doesn't exist or Error in generating the customer extract...aborting...please check!!!!" >> ${LOG_FILE}
exit 99
fi

##Update Runstats Finish
sqlplus -s -l  $CONNECTDW<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

##########################################################################################
#### Bad Records Check
##################################################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
#export SUBJECT=${BAD_SUBJECT}
#send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
