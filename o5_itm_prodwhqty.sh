#!/bin/bash
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME :o5_itm_prodwhqty.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Gets the file  QOORDERAVAIL.TXT from Filerepo and formats the file.
#####                              2. Loads the data into O5.BI_WHQTY_WRK and O5.BI_WHQTY_HST tables 
#####                              3. Loads the dirorder.dat file into sddw.bi_runstats table
#####                              4. Updates the O5.BI_WHQTY_WRK table modify date  
#####
#####   CODE HISTORY :                   Name                     Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Liya Aizenberg           07/10/2013      Created
#####
#####
#############################################################################################################################
. $HOME/initvars
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export PROCESS='o5_itm_prodwhqty'
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE=0
export FILE_NAME="$DATA/O5_PKORDERAVAIL.TXT"
export LOAD_COUNT=0
export FILE_COUNT=0
export TFILE_SIZE=0
export SOURCE_COUNT=0
export TARGET_COUNT=0
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export SQL_FILE="$SQL/${PROCESS}.sql"
export CTL_LOG="$LOG/${PROCESS}_ctl.log"
export BAD_FILE="$LOG/${PROCESS}_bad.bad"
export CONTROL_FILE1="$CTL/${PROCESS}_hst.ctl"
export CTL_LOG1="$LOG/${PROCESS}_hst_ctl.log"
export BAD_FILE1="$LOG/${PROCESS}_hst_bad.bad"
export JXN_FILE="POORDERAVAIL.TXT"
export CURRENT_TIME=`date +"%m%d%Y-%H%M%S"`

#################################################################
##Update Runstats Start
#################################################################
echo " ${PROCESS} Started." >>${LOG_FILE}
########Run the stats############
sqlplus -s -l  $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###############################################################
## Make a copy of Yesterday File###########################
echo " Save Yesterday's File for comparing `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW<<EOF
truncate table o5.BI_WHQTY_WRK_YESTER;
insert into o5.BI_WHQTY_WRK_YESTER select * from o5.BI_WHQTY_WRK;
commit;
quit;
EOF
#################################################################
##Load Data into staging table
#################################################################
echo "Copying data from production into the staging table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL_FILE} >>${LOG_FILE}
################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF > ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###############################################################
##Remove Done file
###############################################################
SAME_FILE_CHECK="`sqlplus -s -l  <<EOF
$CONNECTDW
set echo off
set feedback off
set linesize 10000
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
SELECT count(*)
FROM  O5.BI_WHQTY_WRK_YESTER  A, O5.BI_WHQTY_WRK  B
WHERE A.UPC = B.UPC
and A.WH_SELLABLE_QTY != b.WH_SELLABLE_QTY;
quit;
EOF`"
echo "Same file Check count is ${SAME_FILE_CHECK}. If Zero, it means files are the same. No difference found" >>${LOG_FILE}
if [ ${SAME_FILE_CHECK} -gt 0 ]
then
    echo -e " Today's and Yesterday's inventory files are different. Inventory has been processed. \n">>${LOG_FILE}
else
    echo -e "Attention: No Difference Found between Today's and Yesterday's inventory Files\n" >>${LOG_FILE}
    echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
    exit 99
fi
###################### ADDED BY Liya: inventory_ready.done ##########################################
touch /home/cognos/atomicflags/inventory_ready.flag
##########################################################################################
## Update the  modify date in the staging table where its null.###########################
echo " Updating the modify date in the staging table started at  `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW<<EOF
 update o5.BI_WHQTY_WRK a set modify_dt=sysdate where a.modify_dt is null;
commit;
quit;
EOF
touch /home/ftservice/INCOMING/o5_pkord.done
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
    echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
    export SUBJECT=${BAD_SUBJECT}
    # send_email
    exit 9
else
    echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi