#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_cheetah_demo_load.sh
#####
#####   DESCRIPTION  : This script does the following
#####	             1. The scripts loads the email_cheetah_demo.dat file into staging table using sqlldr
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Alvin Qin			09/07/2010      Created
#####			Divya Kafle			12/15/2011      Modified
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
export PROCESS='o5_edb_cheetah_demo_load'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CONTROL_LOG="$LOG/${PROCESS}.log"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export FILE_NAME="${DATA}/o5_email_cheetah_demo.dat"
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
echo "${PROCESS} PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
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

function edb_dos2unix {
  # simple dos2unix - remove carriage return and eof
  tr -d '\015\032'
}

#################################################################
##Update Runstats Start
#################################################################
echo "${PROCESS} PROCESS started at `date '+%a %b %e %T'`\n" >${LOG_FILE}

FILE_COUNT=`wc -l $FILE_NAME | awk '{printf("%s\n", $1)}'`
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

sed 's/|/\,/g' ${FILE_NAME} > ${FILE_NAME}.tmp
sed 's/\"//g' ${FILE_NAME}.tmp > ${FILE_NAME}

# generate ctlfile
printf "load data
truncate
into table O5.email_optdown_wrk
fields terminated by ','
optionally enclosed by '\"'
trailing nullcols
(" > ${CONTROL_FILE}
# the location of email_id can change, so generate this each time
{
  c=",
";
  for f in $(head -n1 ${FILE_NAME} | edb_dos2unix | tr '[:upper:],' '[:lower:] '); do
    v="filler";                 # default type - change to keep field
    case ${f} in
      (email)        f="email_address";
                     v="char \"trim(upper(:${f}))\"";
                     ;;
      (date_changed) f="date_changed";
                     v="char \"to_date(substr(:${f},1,14),'yyyymmddhh24miss')\"";
                     ;;
      (add_dt)       f="add_dt";
                     v="char \"to_date(substr(:${f},1,11),'DD-MON-YYYY')\"";
                     ;;
      (email_id)     v="char";
                     ;;
    esac
    printf "%s%s %s" "$c" "$f" "$v"; # {line ending}{field name}{type}
  done
  printf ")\n";
} >> ${CONTROL_FILE}

sed -i 's/(,/(/g' ${CONTROL_FILE}

sed -i 's/SHA256_ORDERER/SHA256/g' ${CONTROL_FILE}

awk '{ gsub(/\xef\xbb\xbf/,""); print }' ${CONTROL_FILE} > ${CONTROL_FILE}.tmp
mv ${CONTROL_FILE}.tmp ${CONTROL_FILE}

awk '!seen[$0]++' ${CONTROL_FILE} > ${CONTROL_FILE}.tmp
mv ${CONTROL_FILE}.tmp ${CONTROL_FILE}

#################################################################
##Load Data
#################################################################

sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CONTROL_LOG BAD=$BAD_FILE DATA=$FILE_NAME  ERRORS=999999 SKIP=1 <<EOT>> $CONTROL_LOG
EOT
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo "${PROCESS} PROCESS ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ] || [ `egrep -c "^ERROR|ORA-|SP2-0|^553"  ${CONTROL_LOG}` -ne 0 ]
then
if [ `egrep -c "ORA-12899" ${CONTROL_LOG}` -ne 0 ]
then
echo "${PROCESS} completed.There were some bad data\n" >> ${LOG_FILE}
send_email
else
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
fi
else
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
fi
exit $?
