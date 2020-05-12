#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_can_email_signup.sh
#####
#####   DESCRIPTION  : This script does the following
#####                   1. Load records with pid: 2098090846 from the
#####                      O5 Canada subscription file into staging
#####                   2. Insert the data from staging to o5. edb_stage_sub if
#####                      ZZ_MBRAND_OPTIN is 'Y'
#####
#####
#####   CODE HISTORY :
#####                   Name                     Date            Description
#####                  ------------            ----------      ------------
#####
#####                  Sripriya Rao              08/03/2015      Created
#####                  Sripriya Rao              12/15/2015      Enhanced to dynamically generate the CTL file based
#####                                                            on the header row in the export file
#####				   Sripriya Rao				 01/23/2017		Modified with regards to the new field, "ZZ_LANGUAGE_ID" in the Cheetah Sub File
#####
#############################################################################################################################
. $HOME/params.conf o5
################################################################
##Control File Variables
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export PROCESS="o5_edb_can_email_signup"
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CONTROL_LOG="$LOG/o5_${PROCESS}.log"
export BAD_FILE="$DATA/${PROCESS}.bad"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export EXTRACT_SQL="$SQL/o5_${PROCESS}.sql"
export SUB_GZIP_FILE="o5_subscriber_`TZ=GMT+24 date +"%Y%m%d"`.dat.gz"
export SUB_DAT_FILE="o5_subscriber_`TZ=GMT+24 date +"%Y%m%d"`.dat"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export BAD_SUBJECT="${PROCESS} failed"
export TARGET_COUNT=0
export GEN_CONTROL_FILE="$CTL/${PROCESS}_gen.ctl"
export O5_CAN_PID="2098090846"
export O5_GILT_COREG_PID="2104770124"

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

########################################################################
## Generate the CTL file based on the header of the export file
########################################################################
function gen_ctl_file {
head -1 $DATA/$SUB_DAT_FILE | sed -e 's/\"//g' | sed -e 's/\,/|/g' > $DATA/o5_header_ca.txt
NUM=`awk -F '|' '{print NF}' < $DATA/o5_header_ca.txt`
echo -e "LOAD DATA" > ${GEN_CONTROL_FILE}
echo -e "${1}" >> ${GEN_CONTROL_FILE}
echo -e "INTO TABLE      O5.EDB_CAN_EMAIL_SIGNUP_WRK" >> ${GEN_CONTROL_FILE}
echo -e "WHEN pid = \"${2}\"" >> ${GEN_CONTROL_FILE}
echo -e "FIELDS TERMINATED BY '|'" >> ${GEN_CONTROL_FILE}
echo -e "OPTIONALLY ENCLOSED BY '\"'" >> ${GEN_CONTROL_FILE}
echo -e "TRAILING NULLCOLS" >> ${GEN_CONTROL_FILE}
echo -e "(" >> ${GEN_CONTROL_FILE}
for i in `eval echo {1..${NUM}}`
do
COLNAME=`awk -F '|' -v pos=$i '{print $pos}' < $DATA/o5_header_ca.txt`
if [ $COLNAME == "pid" ] || [ $COLNAME == "email" ] || [ $COLNAME == "FNAME" ] || [ $COLNAME == "LNAME" ] || [ $COLNAME == "ZIP" ] || [ $COLNAME == "ZZ_MBRAND_OPTIN" ] || [ $COLNAME == "ZZ_SBRAND_OPTIN" ] || [ $COLNAME == "ZZ_LANGUAGE_ID" ]
then
        COLTYPE="char"
else
        COLTYPE="FILLER"
fi
echo -e "$COLNAME`echo "\t"`$COLTYPE," >> ${GEN_CONTROL_FILE}
done
echo -e "staged\tSYSDATE" >> ${GEN_CONTROL_FILE}
echo -e ")" >> ${GEN_CONTROL_FILE}
sed -i 's/SHA256_ORDERER/SHA256/g' ${GEN_CONTROL_FILE}

awk '{ gsub(/\xef\xbb\xbf/,""); print }' ${GEN_CONTROL_FILE} > ${GEN_CONTROL_FILE}.tmp
mv ${GEN_CONTROL_FILE}.tmp ${GEN_CONTROL_FILE}

awk '!seen[$0]++' ${GEN_CONTROL_FILE} > ${GEN_CONTROL_FILE}.tmp
mv ${GEN_CONTROL_FILE}.tmp ${GEN_CONTROL_FILE}
}

echo "Starting the process ${PROCESS} `date '+%a %b %e %T %Z %Y'` " > ${LOG_FILE}
########################################################################
##update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

########################################################################
## Get the O5 Canada Subscriprions gzip file from the ftp site
#################################################################
echo "Starting the ftp process to ftp.bizrate.com at `date '+%a %b %e %T %Z %Y'` " >>${LOG_FILE}
cd $DATA
lftp -u SDO5feeds,'rEfrU8' sftp://tt.cheetahmail.com <<EOF>${LOG_FILE}
cd fromcheetah
get "$SUB_GZIP_FILE"
quit
EOF

#######################################################################
# check if O5 Canada subscription file exists
################################################################
if [ -f $DATA/$SUB_GZIP_FILE ]
then
        echo "$SUB_GZIP_FILE" >>${LOG_FILE}
        echo "O5 Canada subscription file $SAKS_SUB_GZIP_FILE is available `date '+%a %b %e %T'`">>${LOG_FILE}
	echo "Unzipping $SUB_GZIP_FILE" >>${LOG_FILE}
        gunzip $DATA/$SUB_GZIP_FILE
else
        echo "O5 Canada subscription file $SAKS_SUB_GZIP_FILE is not available `date '+%a %b %e %T'`">>${LOG_FILE}
	echo "Aborting..." >> ${LOG_FILE}
        exit 99
fi

###################################################################################
## Dynamically generating the control file based on the header row in the export file
###################################################################################
echo "Dynamically generating the control file based on the header row in the export file" >> ${LOG_FILE}
gen_ctl_file "TRUNCATE" $O5_CAN_PID

#################################################################################################
## Load the O5 Canada subscription file data to the staging table MREP.EDB_CAN_EMAIL_SIGNUP_WRK
#################################################################################################
echo " Loading the $SUB_DAT_FILE into the staging table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
echo "sqlldr $CONNECTDW CONTROL=$GEN_CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$SUB_DAT_FILE ERRORS=99999999 SKIP=1"
sqlldr $CONNECTDW CONTROL=$GEN_CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$SUB_DAT_FILE ERRORS=99999999 SKIP=1
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
                echo "ERROR in loading O5 Canada subscription file in to the staging table"
		echo "Aborting..." >> ${LOG_FILE}
        	exit 99
        else
                echo "O5 Canada subscription file successfully loaded in to the staging table..see ${LOG_FILE} for warnings"
        fi
else
        echo "O5 Canada subscription file successfully loaded in to the staging table"
fi

###################################################################################
## Dynamically generating the control file based on the header row in the export file
###################################################################################
#echo "Dynamically generating the control file based on the header row in the export file" >> ${LOG_FILE}
#gen_ctl_file "APPEND" $O5_GILT_COREG_PID
#
##################################################################################################
### Append the O5 Gilt Co-Reg subscription data to the staging table MREP.EDB_CAN_EMAIL_SIGNUP_WRK
##################################################################################################
#echo " Loading the $SUB_DAT_FILE into the staging table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
#echo "sqlldr $CONNECTDW CONTROL=$GEN_CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$SUB_DAT_FILE ERRORS=99999999 SKIP=1"
#sqlldr $CONNECTDW CONTROL=$GEN_CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$DATA/$SUB_DAT_FILE ERRORS=99999999 SKIP=1
#retcode=`echo $?`
#case "$retcode" in
#        0) echo "SQL*Loader execution successful" >> ${LOG_FILE};;
#        1) echo "SQL*Loader execution exited with EX_FAIL, see logfile" >> ${LOG_FILE};;
#        2) echo "SQL*Loader execution exited with EX_WARN, see logfile" >> ${LOG_FILE};;
#        3) echo "SQL*Loader execution encountered a fatal error" >> ${LOG_FILE};;
#        *) echo "unknown return code" >> ${LOG_FILE};;
#esac
#if [ $retcode -ne 0 ]
#then
#        if [ $retcode -ne 2 ]
#        then
#                echo "ERROR in loading O5 Gilt Co-reg subscription data in to the staging table"
#                echo "Aborting..." >> ${LOG_FILE}
#                exit 99
#        else
#                echo "O5 Gilt subscription data successfully loaded in to the staging table..see ${LOG_FILE} for warnings"
#        fi
#else
#        echo "O5 Gilt subscription data successfully loaded in to the staging table"
#fi

#################################################################################################
## Insert the data from O5.EDB_CAN_EMAIL_SIGNUP_WRK into O5.EDB_STAGE_SUB
################################################################################################
echo " Inserting into O5.EDB_STAGE_SUB  at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql >> ${LOG_FILE}

#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

#################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
exit $?
