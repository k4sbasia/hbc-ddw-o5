#!/usr/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_rpt_ams_pip.sh
#####
#####   DESCRIPTION  : Shell script for Off 5th AMS report to confirm PIP text.  This report is used to validate AMS data.
#####
#####
#####
#####
#####   CODE HISTORY :                     Name               Date            Description
#####                                   ------------         ----------      ------------
#####                                  David Alexander      10/06/2016        Report Created
#####                                  David Alexander      11/18/2016        Script change to FTP file to Server.
#####                                  David Alexander      12/02/2016        Add 2nd SQL script for non-PIP items.
#####                                  David Alexander      12/07/2016        Corrected issue with smbclient command.
#############################################################################################################################
. $HOME/params.conf o5
export PROCESS='o5_rpt_ams_pip'
export SQL=$HOME/SQL
export SQL2=$HOME/SQL/o5_rpt_ams_pip_no
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export DATA_FILE="$DATA/${PROCESS}.csv"
export DATA_FILE1="$DATA/${PROCESS}_no.csv"
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SUBJECT="Off 5th AMS Report `date +"%Y-%m-%d."`"
export TODAY=`date +%Y%m%d`
########################################################################
echo -e "Off 5th AMS Report started at `date '+%a %b %e %T'`\n" >${LOG_FILE}
#################################################################
#  Run the sql script that performs the data load
#################################################################
sqlplus -s -l  $CONNECTDW  @${SQL}/${PROCESS}.sql > ${DATA_FILE}
sqlplus -s -l  $CONNECTDW  @${SQL}/${PROCESS}_no.sql > ${DATA_FILE1}
#################################################################
echo -e "Off 5th AMS Report ended at `date '+%a %b %e %T'`\n" >>${LOG_FILE}
################################################################
# Check for errors
################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo -e "${PROCESS} failed. Please investigate"
echo -e "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
exit 99
else
smbclient -s /dev/null "\\\\t49-vol4.INTRANET.SAKSROOT.SAKSINC.com\\ECommerce\\" --authentication-file /home/cognos/auth_tmp.txt --command 'cd "2018 Marketing\Off5th.com\Promotions\AMS Report Folder";prompt;lcd /home/cognos/DATA/;mput o5_rpt_ams_pip.csv;rename o5_rpt_ams_pip.csv 'o5_rpt_ams_pip_${TODAY}.csv';quit'
wait
smbclient -s /dev/null "\\\\t49-vol4.INTRANET.SAKSROOT.SAKSINC.com\\ECommerce\\" --authentication-file /home/cognos/auth_tmp.txt --command 'cd "2018 Marketing\Off5th.com\Promotions\AMS Report Folder";prompt;lcd /home/cognos/DATA/;mput o5_rpt_ams_pip_no.csv;rename o5_rpt_ams_pip_no.csv 'o5_rpt_ams_pip_no_${TODAY}.csv';quit'
wait
echo "Off 5th AMS Reports." | mailx -s "Off 5th AMS Reports have been posted to the 2018 Marketing\Off5th.com\Promotions\AMS Report Folder" -r hbcdigitaldatamanagement@saksinc.com hbcdigitaldatamanagement@saksinc.com Geraldine_Cole@s5a.com Off5themailmarketingdirect@saksinc.com Off5thcategorymanagers@hbc.com carol_sung@s5a.com manasa.reddy@hbc.com Jason_Chang1@s5a.com
echo -e "${PROCESS} completed without errors."
echo -e "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
exit 0
fi
