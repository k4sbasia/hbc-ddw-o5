#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : product_file_transfer_to_datasong.sh  
#####
#####   DESCRIPTION  : This script does the following
#####                  1. Transfer Saks/O5 Product data files to Datasong
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####			Sripriya Rao		09/30/2015	Created	
#####
#####
##################################################################################################################################
. $HOME/initvars

################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS="product_file_transfer_to_datasong"
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export LOG_FILE="$LOG/${BANNER}_${PROCESS}_log.txt"
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
export SAKS_PRODUCT_ZIP_FILE="cm_product.txt.gz"
export SAKS_PRODUCT_UNZIP_FILE="cm_product.txt"
export SAKS_PRODUCT_FILE="cm_product_${today}.txt"
export O5_PRODUCT_FILE="o5_cm_product_${today}.txt"

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

echo "Starting the process: `date +"%m/%d/%Y-%H:%M:%S"`" > ${LOG_FILE}
echo "Looking for $BANNER product file to post to Datasong" >> ${LOG_FILE}

cd $DATA
if [ $BANNER = 'saks' ]
then
	if [ ! -f $SAKS_PRODUCT_ZIP_FILE ]
	then
		echo "Saks Product file not available...Pls check !!!" >> ${LOG_FILE}
		exit 99
	else
		gunzip $SAKS_PRODUCT_ZIP_FILE
		cp $SAKS_PRODUCT_UNZIP_FILE $SAKS_PRODUCT_FILE
		echo "Start transfering the file to Saks s3 bucket for datasone/Neustar  at `date '+%a %b %e %T'`" >> ${LOG_FILE}
		  export HTTPS_PROXY=http://proxy.saksdirect.com:80
          aws --profile datasong s3 cp $SAKS_PRODUCT_FILE s3://hbc-action/Saks/ >> ${LOG_FILE}
		  echo "SAKS transfering completed to s3 bucket for datasone/Neustar  at `date '+%a %b %e %T'`" >> ${LOG_FILE}
		echo "Finished transfer Saks product file to datasong at `date '+%a %b %e %T'`" >> ${LOG_FILE}
		gzip $SAKS_PRODUCT_UNZIP_FILE
		rm ${SAKS_PRODUCT_FILE}
	fi
fi

if [ $BANNER = 'o5' ]
then
	if [ ! -f $O5_PRODUCT_FILE ]
	then
		echo "O5 Product file not available...Pls check !!!" >> ${LOG_FILE}
		exit 99
	else
		echo "Start transfer O5 product file to datasong/Neustar s3 bucket at `date '+%a %b %e %T'`" >> ${LOG_FILE}
		export HTTPS_PROXY=http://proxy.saksdirect.com:80
		aws --profile datasong s3 cp $O5_PRODUCT_FILE s3://hbc-action/Off_5th/ >> ${LOG_FILE}
		echo "off5th transfering completed to s3 bucket for datasone/Neustar  at `date '+%a %b %e %T'`" >> ${LOG_FILE}
	fi
fi
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
echo "$PROCESS ended at `date '+%a %b %e %T'`" >> ${LOG_FILE}

#################################################################
# Check for errors
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi

cd $HOME
exit 0
