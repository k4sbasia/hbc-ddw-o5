#!/usr/bin/ksh
#############################################################################################################################
#####     			SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_edb_ftp_cm_daily_down.sh
#####
#####   DESCRIPTION  : This script does the following
#####	             1.Pull Down Unsub and COA from Cheetah
#####
#####
#####   CODE HISTORY :	Name			Date		Description
#####			------------		----------	------------
#####			Divya Kafle			06/04/2013      Created
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
export PROCESS='o5_edb_ftp_cm_daily_down'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CONTROL_LOG="$LOG/${PROCESS}.log"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_FILE="$DATA/${PROCESS}.bad"
export yesterday=`date +%Y%m%d -d"1 day ago"`
export FILE_NAME="0"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0

function edb_decrypt {
  # factor this oft repeated code to ease changes, like removing the
  # passphrase
  typeset in="$1"
  typeset out

  # deduce the output name, if not given
  if [ $# == 2 ]; then
    out="$2"
  else
    if [ "${in%.gpg}" != "${in}" ]; then
      out="${in%.gpg}"
    elif [ "${in%.pgp}" != "${in}" ]; then
      out="${in%.pgp}"
    else
      >&2 printf "*error gpg file name\n";
      false;
    fi
  fi

  # specify --output for tiny security improvement
  gpg --no-tty --batch --passphrase-fd 0 \
      --output ${out} --decrypt ${in} \
      < $HOME/email_pass.file \
      || { >&2 printf "*error gpg $in\n"; false; }
}

#function edb_ftp_get {

   #typeset files="$1"

	#lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>${LOG_FILE}
	#cd fromcheetah
	#get $1 $DATA/$1
	#quit
	#EOF
#}

function edb_ungzip {
  # A minor convince function, mostly to help avoid the temptation of
  # letting gzip choose the name of the output file (a very mild
  # security risk).
  typeset in="$1"
  typeset out

  # deduce the output name, if not given
  if [ $# == 2 ]; then
    out="$2"
  else
    if [ "${in%.gz}" != "${in}" ]; then
      out="${in%.gz}"
    else
      >&2 printf "*error gzip file name\n";
      false;
    fi
  fi

  gzip -cd ${in} > ${out} || { >&2 printf "*error ungzip $in\n"; false; }
}

echo "${PROCESS} PROCESS started" > ${LOG_FILE}

sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

rm -f ${DATA}/o5_unsubs_${yesterday}.dat*
rm -f ${DATA}/o5_coa_${yesterday}.dat*

# process the available files - cheetah skips empty files
cd ${DATA}
lftp -u SDO5feeds,rEfrU8 sftp://tt.cheetahmail.com <<EOF>>${LOG_FILE}
cd fromcheetah
get o5_unsubs_${yesterday}.dat.gz
get o5_coa_${yesterday}.dat.gz
quit
EOF

  #edb_ftp_get o5_unsubs_${yesterday}.dat.gz
  #edb_decrypt ${DATA}/o5_unsubs_${yesterday}.dat.gz.pgp
  edb_ungzip ${DATA}/o5_unsubs_${yesterday}.dat.gz

  #edb_ftp_get o5_coa_${yesterday}.dat.gz
  #edb_decrypt ${DATA}/o5_coa_${yesterday}.dat.gz.pgp
  edb_ungzip ${DATA}/o5_coa_${yesterday}.dat.gz

 FILE_COUNT=`wc -l ${DATA}/o5_unsubs_${yesterday}.dat | awk '{printf("%s\n", $1)}'`
  echo "No. of records in o5_unsubs_${yesterday}.dat: ${FILE_COUNT}" >> ${LOG_FILE}

  FILE_COUNT=`wc -l ${DATA}/o5_coa_${yesterday}.dat | awk '{printf("%s\n", $1)}'`
  echo "No. of records in o5_coa_${yesterday}.dat: ${FILE_COUNT}" >> ${LOG_FILE}

#mv o5_unsubs_${yesterday}.dat DATA/ARCHIVE
#mv o5_coa_${yesterday}.dat DATA/ARCHIVE

#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Bad Records Check
#################################################################
echo "${PROCESS} PROCESS ended " >> ${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit $?
