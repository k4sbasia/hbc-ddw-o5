#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_bi_demand_dly_data.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. It  produces data for jackson
#####
#####
#####
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Rajesh Mathew           05/17/2011      Created
#####                   Jayanthi Dudala                         Added the check before sending file to Jackson 
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_bi_demand_dly_data'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export CTL=$HOME/CTL
export DATA=$HOME/DATA
export DATA_FILE=$DATA/PK.NF.O5DFLASH.txt
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export SUBJECT="Alert!!!!!!! The Jackson O5 Demand File Mismatch, address this immediately"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME='0'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export CHECK_COUNT='0'
export CONTROL_FILE="$CTL/${PROCESS}.ctl"
export CTL_LOG="$LOG/${PROCESS}_ctl.log"
export BAD_FILE="$LOG/${PROCESS}_bad.bad"
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
#################################################################
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l  $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo -e "O5_BI_DEMAND_DLY_DATA Process started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
echo -e "Starting O5 data extract at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${SQL}/${PROCESS}.sql > ${DATA_FILE}
wait
TARGET_COUNT="`wc -l $DATA_FILE|tr -s ' ' '|' |cut -f1 -d'|'`"
wc -l $DATA_FILE> $DATA/PK.NF.O5DFLASH.COUNTS.txt
#################################################################
###File check before we send to Jackson
###Load the file back to the work table
#################################################################
echo " Loading back the file into the work table  at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlldr $CONNECTDW CONTROL=$CONTROL_FILE LOG=$CTL_LOG BAD=$BAD_FILE DATA=${DATA_FILE} ERRORS=999999999
cat $CTL_LOG >>${LOG_FILE}
#################################################################
##Check dollar amounts and counts
CHECK_COUNT=`sqlplus -s $CONNECTDW <<EOF
set heading off
select count(*) from 
(
SELECT   A.DATEKEY,
            SUM (total_demand_qty) demand_qty,
            SUM (total_demand_dollars) demand_dollars,
            SUM (CANCEL_QTY) CANCEL_QTY, 
            SUM (cancel_dollars) cancel_dollars,
            SUM (bord_demand_qty) backorder_qty,
            SUM (bord_demand_dollars) backorder_dollars
       FROM o5.bi_psa a
      WHERE A.DIVISION_ID NOT IN ('9') AND ADD_DT > SYSDATE - 1
   GROUP BY A.DATEKEY
MINUS   
SELECT   DATEKEY, 
                 SUM (DEMAND_QTY) demand_qty,
                 SUM (demand_dollars) demand_dollars,
                 SUM (cancel_qty) cancel_qty,
                 SUM (cancel_dollars) cancel_dollars,
                 SUM (backorder_qty) backorder_qty,
                 SUM (backorder_dollars) backorder_dollars
            FROM o5.BI_PSA_DEMAND_EXT
        GROUP BY DATEKEY
);
quit;
EOF`
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF > ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
#Ftp the file to Jackson 
#################################################################
echo -e "Starting the O5 ftp process to jackson at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
cd $DATA

if [ ${CHECK_COUNT} = 0 ]
then
ftp -n SAKSPROD.SAKSINC.COM   << EOF>>${LOG_FILE}
user ftpnflh nf8636lh
quote PASV
quote site lrecl=80
put PK.NF.O5DFLASH.txt 'PK.NF.O5DFLASH'
put PK.NF.O5DFLASH.COUNTS.txt 'PK.NF.O5DFLASH.COUNTS'
quit
EOF
    cd $HOME
    echo "CHECK_COUNT:= ${CHECK_COUNT}" >> $LOG_FILE
    echo -e "Finished the O5 ftp process to Jackson at `date '+%a %b %e %T %Z %Y'`\n " >>${LOG_FILE}
    echo -e "o5_bi_demand_dly_data Process Ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
    else
    echo "CHECK_COUNT:= ${CHECK_COUNT}" >> $LOG_FILE
    echo "${PROCESS} was not sent.The file didn't pass the check. Please check the counts in the file matches the PSA counts " >> $LOG_FILE
    send_email
    exit 99
fi

################################################################
# Perform removal of some old files
################################################################
find /home/cognos -name '*_sd_demand_finencial.txt' -atime +7 -exec rm {} \;
find /home/cognos -name '*_sd_demand_item.txt' -atime +7 -exec rm {} \;
find /home/cognos -name '*_sd_item_ext_cnt.txt' -atime +7 -exec rm {} \;
find /home/cognos -name '*_sd_demand_finencial_cnt.txt' -atime +7 -exec rm {} \;
find /home/cognos -name '*_sd_sku_item.txt' -atime +7 -exec rm {} \;
find /home/cognos -name '*_sd_item_demand_ext_cnt.txt' -atime +7 -exec rm {} \;
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
    echo -e "${PROCESS} failed. Please investigate." >> ${LOG_FILE}
    export SUBJECT=${BAD_SUBJECT}
#send_email
else
    export SUBJECT="SUCCESS: O5_BI_DEMAND_DLY_DATA extract process completed"
    echo -e "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
