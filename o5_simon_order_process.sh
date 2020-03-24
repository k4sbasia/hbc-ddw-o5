#!/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_simon_order_process
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Extracts Simon Orders from Ominture
#####                              2. Find Shipped and Return Data from OMS
#####                              3. Generates Order Feed to send it to Simon
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Kanhu C Patro           04/05/2018      Created
#############################################################################################################################
################################################################

. $HOME/params.conf o5
export PROCESS='o5_simon_order_process'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL

export LOG_FILE=$LOG/${PROCESS}.log

export SQL_FILE_1=$SQL/find_simon_ship_ret_order.sql
export SQL_FILE_2=$SQL/generate_simon_ship_ret_order.sql
export SQL_FILE_3=$SQL/merge_simon_ret_can_order.sql
export SQL_FILE_4=$SQL/generate_simon_ship_ret_order_pii.sql
export SQL_FILE_5=$SQL/generate_simon_monthly_ship_ret_order.sql

export OMNITURE_ORDER_FILE="PAR_MED_SHOPPREMIUMOUTLETS$(date --date yesterday "+%Y%m%d").csv"
export FILE_NAME="$DATA/o5_simons_order_`date +"%Y%m%d"`.csv"
export FILE_MONTHLY_NAME="$DATA/o5_simons_monthly_order_report_`date +"%Y%m%d"`.csv"

export CTL_FILE=$CTL/${PROCESS}.ctl
export file_process_mn=`date "+%d"`

export FILE_NAME_1="$DATA/o5_simons_customer_data_`date +"%Y%m%d"`.csv"
export FILE_NAME_GPG="$DATA/o5_simons_customer_data_`date +"%Y%m%d"`.gpg"

export SUBJECT_LINE="O5th Simon Order Feed Posted For `date '+%a %b %e %Y'`."
export SUBJECT_LINE_MON="O5th Simon Monthly Report For `date '+%B_%Y'`."

#set -x
echo "Process $PROCESS started at `date '+%a %b %e %T'`" > ${LOG_FILE}

if [ $file_process_mn -eq "01" ]
then
	echo "Month Begining, Run the Monthly Report for Shipped and return Transactions." >> ${LOG_FILE}
	sqlplus -s $CONNECTO5STATS12C @${SQL_FILE_5} "${SCHEMA}">> ${FILE_MONTHLY_NAME}
    if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${FILE_MONTHLY_NAME}` -ne 0 ]
    then
        echo "${PROCESS} failed while generating Monthly Report. Please investigate" >> ${LOG_FILE}
        exit 99
    else
        echo "Monthly Report Generated Successfully. Ready to Send the Report to Business." >> ${LOG_FILE}
        echo "O5th Simon Order Monthly Shipped & Return Data."|mailx -s "${SUBJECT_LINE_MON}" -a "${FILE_MONTHLY_NAME}" alison.flack@hbc.com hannah.tevolini@hbc.com
    fi
else 
    echo "Not Month Begining, No Need to run Monthly Report." >> ${LOG_FILE}
fi

cd $DATA
#Fetch Order File From Omniture to Local Unix Box
#ftp -nv ftp2.omniture.com<<EOF
#user saksdatafeed PFsfelvb
#binary
#get $OMNITURE_ORDER_FILE
#quit
#EOF

if [ -f $DATA/$OMNITURE_ORDER_FILE ]
then
        echo "Order File $OMNITURE_ORDER_FILE fetch Successfull. ">> ${LOG_FILE}
else
        echo "Order File $OMNITURE_ORDER_FILE Mising, Please check FTP Site for the file. ">> ${LOG_FILE}
        exit 99
fi

echo "Load $OMNITURE_ORDER_FILE File into DB. ">> ${LOG_FILE}

sqlldr $CONNECTO5STATS12C CONTROL=$CTL_FILE DATA=$DATA/$OMNITURE_ORDER_FILE LOG=$LOG/${PROCESS}_loader.log BAD=$DATA/${PROCESS}_loader.bad ERRORS=10
retcode=`echo $?`
case "$retcode" in
        0) echo "SQL*Loader execution successful" >> ${LOG_FILE};;
        1) echo "SQL*Loader execution exited with EX_FAIL, see logfile" >> ${LOG_FILE};;
        2) echo "SQL*Loader execution exited with EX_WARN, see logfile" >> ${LOG_FILE};;
        3) echo "SQL*Loader execution encountered a fatal error" >> ${LOG_FILE};;
        *) echo "unknown return code" >> ${LOG_FILE};;
esac
echo "SQL Loader Returin Code : $retcode ">> ${LOG_FILE}

echo "Started Processing $OMNITURE_ORDER_FILE File. ">> ${LOG_FILE}

#Run SQL to find the Shipped and Returned Order
sqlplus -s $CONNECTO5STATS12C @${SQL_FILE_1} "${SCHEMA}" "${BANNER}">> ${LOG_FILE}

#Generate the Order Shipped, Returned and Cancelled Orders
echo "Generating $FILE_NAME File. ">> ${LOG_FILE}
sqlplus -s -l $CONNECTO5STATS12C @${SQL_FILE_2} "${SCHEMA}" > ${FILE_NAME}
#Create PII Data for Shipped Orders
sqlplus -s $CONNECTO5STATS12C @${SQL_FILE_4} "${SCHEMA}" > ${FILE_NAME_1}

if [ -f $FILE_NAME ] && [ -f $FILE_NAME_1 ]
then
        #Check For Errors in SQL Log OR Data File
        if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ] || [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${FILE_NAME}` -ne 0 ] || [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${FILE_NAME_1}` -ne 0 ]
        then
                echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
                exit 99
        else
                echo "Data File Created Successfully for FTP. " >> ${LOG_FILE}
        fi
else
        echo "$FILE_NAME or $FILE_NAME_1 Missing Please Investigate. " >> ${LOG_FILE}
        exit 99
fi
#exit 99
echo "Post Process Orders. ">> ${LOG_FILE}
sqlplus -s $CONNECTO5STATS12C @${SQL_FILE_3} "${SCHEMA}">> ${LOG_FILE}

if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
        echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
        exit 99
else
        echo "${PROCESS} completed without errors. Ready to Send the Order Data to Simon." >> ${LOG_FILE}
fi

export order_count=`cat $FILE_NAME | wc -l`
if [ $order_count -gt 1 ]
then
        echo "Order Data Identified'." >> ${LOG_FILE}
#Post the file to Simon
        echo "FTPing the file as file check was succesfull `date '+%a %b %e %T'`" >>${LOG_FILE}
#lftp -u saksoff5,tWIaOiOgZ6j94RM6WfoOfAXVxa6gRrQU sftp://sftp.sspo.com <<EOF
#cd Product_Order_Data
#put ${FILE_NAME}
#quit
#EOF

export PII_count=`cat $FILE_NAME_1 | wc -l`
if [ $PII_count -gt 1 ]
then
	echo "PII Data Identified'." >> ${LOG_FILE}
    echo "FTPing Transaction PII data as file check was succesfull `date '+%a %b %e %T'`" >>${LOG_FILE}
	gpg -o ${FILE_NAME_GPG} --encrypt --default-recipient "ExactTarget, LLC. (We mail it.) <info@exacttarget.com>" ${FILE_NAME_1} 
	
#lftp -u saksoff5,tWIaOiOgZ6j94RM6WfoOfAXVxa6gRrQU sftp://sftp.sspo.com <<EOF
#cd Customer_Order_Data
#put ${FILE_NAME_GPG}
#quit
#EOF
fi

#Send Email to Business
        echo "O5th Simon Order Feed Processing Complete. Please refer attachment for detail of records."|mailx -s "${SUBJECT_LINE}" -a "${FILE_NAME}" alison.flack@hbc.com jennifer.carullo@hbc.com stephanie.stevens@hbc.com
        echo "O5th Simon Order Feed Processing Complete. Order and Transactional File Posted to Simon. "|mailx -s "${SUBJECT_LINE}" hbcdigitaldatamanagement@saksinc.com
else
        echo "O5th Simon Order Feed Processing Complete. No Order Identified today for Simon. "|mailx -s "${SUBJECT_LINE}" alison.flack@hbc.com jennifer.carullo@hbc.com stephanie.stevens@hbc.com
        echo "O5th Simon Order Feed Processing Complete.  "|mailx -s "${SUBJECT_LINE}" hbcdigitaldatamanagement@saksinc.com
fi
echo "Process $PROCESS Completed Successfully at `date '+%a %b %e %T'`" >> ${LOG_FILE}
#set +x