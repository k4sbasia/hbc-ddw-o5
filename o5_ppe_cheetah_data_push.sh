#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_ppe_cheetah_data_push.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. pushes the file to cheetah
#####
#####
#####   CODE HISTORY : 					 Name                  Date            Description
#####                                   ------------            ----------      ------------
#####                                   Divya Kafle           06/02/2014      Created
#####
#############################################################################################################################
. $HOME/params.conf o5
export PROCESS='o5_ppe_cheetah_data_push'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_log.txt"
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
SLEEP_TIME=100
echo -e "o5_ppe_cheetah_data_push process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
if [ -f "$DATA/Off5th_ppe_`date +%Y%m%d`.xml" ]
then
echo "Off5th PPE File for cheetah is available at `date '+%a %b %e %T'`\n">>${LOG_FILE}
cd $DATA
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>>${LOG_FILE}
cd autoproc
put Off5th_ppe_`date +%Y%m%d`.xml
bye
EOF
cd $HOME
cat ${LOG_FILE} |mailx -s "Off5th PPE Data push successfully completed" hbcdigtialdatamanagement@hbc.com
else
echo "Off5th PPE File for cheetah is NOT available at `date '+%a %b %e %T'`\n">>${LOG_FILE}
exit 99
fi
exit 0
