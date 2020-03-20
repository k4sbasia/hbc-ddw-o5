#!/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : rr_product_full_all_banners.sh
#####
#####   DESCRIPTION  : This script does the following
#####             1. The script calls the product full , category full and product category sqls to generate files for feed
#####
#####
#####   CODE HISTORY :   Name             Date        Description
#####                   ------------    ----------  ------------
#####
#####                   Aparna          05/24/2016  Created
#####                                   Kallaar                 03/04/2017      Added additional error handling and logging
#####
#############################################################################################################################

. $HOME/params.conf o5

################################################################

#####################################################################################
##This shell script is called by UC4 Job RR_PRODUCT_FULL_ALL_BANNERS
#####################################################################################
##Varibles
export PROCESS='rr_product_full_all_banners'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export BAD_SUBJECT="${PROCESS} failed"
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export EXTRACT_SQL2='$SQL/rry_category_full_all_banners.sql'
export EXTRACT_SQL3='$SQL/rr_product_in_category_all_banners.sql'
export EXTRACT_SQL4='$SQL/rr_product_attribute_o5.sql'
export BANNER='&1'
#######################################################################################
##Initialize Email Function
################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 echo ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
function send_delay_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 export SUBJECT=${BAD_SUBJECT}
 BSUBJECT="RICH RELEVANCE PRODUCT FULL DELAYED"
 BBODY="Rich Relevance: product full feed is delayed and we are looking into it. Thanks"
 BADDRESS='HBCDigitalSaksDirectSiteOperations@hbc.com'
 echo ${BBODY} ${CURRENT_TIME}|mailx -s "${BSUBJECT}" ${BADDRESS}
 send_email
}
#################################################################
if [ "${BANNER}" == "" ];
then
    BANNER=$1
fi

#################################################################
##Update SCHEMA for specific BANNER
#################################################################
###########################################################
#####      SAKS BANNER     ###########################
if [ "${BANNER}" == "saks" ];
then
export DBCONNECTPRIM="PRIMSTO_MREP"
export CONNECTDW="mrep/mrepprd@newprdsdw"
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="mrep."
export PART_TABLE="BI_PARTNERS_EXTRACT_WRK"
export REVW_TABLE="TURN_TO_PRODUCT_REVIEW"
export BMCONNECTION="PRODSTO_MREP"
export CLNECONNECTION="CLONESTO_MREP"
export FTP_FILE="product_full_$BANNER_`date +%Y%m%d`.txt"
export FTP_FILE1="category_full_$BANNER_`date +%Y%m%d`.txt"
export FTP_FILE2="products_in_category_$BANNER_`date +%Y%m%d`.txt"
fi
#############################################################
########    OFF5TH BANNER    ###############################
############################################################
if [ "${BANNER}" == "o5" ];
then
export DBCONNECTPRIM="PRVO5_SAKSCUSTOM"
export CONNECTDW="O5/o5prd@newprdsdw"
export LOG_FILE="$LOG/${PROCESS}_${BANNER}_log.txt"
export SCHEMA="o5."
export PART_TABLE="O5_PARTNERS_EXTRACT_WRK"
export REVW_TABLE="BV_PRODUCT_REVIEW"
export BMCONNECTION="PRDO5_SAKSCUSTOM"
export CLNECONNECTION="PRDO5_SAKSCUSTOM"
export EXTRACT_SQL='$SQL/rr_product_full_o5_banner.sql'
export FTP_FILE="product_full_off5th_`date +%Y_%m_%d`.txt"
export FTP_FILE1="category_full_off5th_`date +%Y_%m_%d`.txt"
export FTP_FILE2="products_in_category_off5th_`date +%Y_%m_%d`.txt"
fi
#############################################################
########    BAY BANNER    ###############################
############################################################
if [ "${BANNER}" == "bay" ];
then
export DBCONNECTPRIM="PRIMSTO_MREP"
fi
#############################################################
########    LT BANNER    ###############################
############################################################
if [ "${BANNER}" == "lt" ];
then
export DBCONNECTPRIM="PRIMSTO_MREP"
fi
#################################
###########################
cd DATA
echo "RR Full catalog feed process started for $BANNER" >${LOG_FILE}
echo "Creation of the log file started at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL} "${SCHEMA}" "$BMCONNECTION" "$PART_TABLE" "$DBCONNECTPRIM" "$REVW_TABLE" "${BANNER}" >product_full_${BANNER}.txt
SQL_RET_CODE=$?
echo "Creation of the product data file ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
wait
#################################################################
##SQL ERROR VALIDATION
#################################################################
if [ ${SQL_RET_CODE} -eq 0 ]
then
        echo "${EXTRACT_SQL} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
        echo "Aborting: Error ${EXTRACT_SQL} at `date '+%a %b %e %T'`" >>${LOG_FILE}
        send_delay_email
        exit 99
fi
#################################################################
##Rename File
mv product_full_${BANNER}.txt product_full_off5th_`date +%Y_%m_%d`.txt
wait
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${DATA}/product_full_off5th_`date +%Y_%m_%d`.txt  ]
then
        FILE_NAME=product_full_off5th_`date +%Y_%m_%d`.txt
        TFILE_SIZE="`ls -ll ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
        FILE_COUNT="`wc -l ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
fi
echo "File size is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
##FILE COUNT VALIDATION
#################################################################
if [ ${FILE_COUNT} -gt 6000 ]
then
 echo "Enough records on the file " >> ${LOG_FILE}
 echo "Starting FTP process " >> ${LOG_FILE}
else
 echo "Aborting: Error loading product_full_off5th_`date +%Y_%m_%d`.txt  at `date '+%a %b %e %T'`" >>${LOG_FILE}
 echo "${PROCESS} was not sent. Minimum amount of data was not present." >> $LOG_FILE
 send_delay_email
 exit 99
fi
#################################################################
## second file
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL2} "$CLNECONNECTION" "$BMCONNECTION">category_full_${BANNER}.txt
SQL_RET_CODE=$?
echo "Creation of the category data file ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
wait
#################################################################
##SQL ERROR VALIDATION
#################################################################
if [ ${SQL_RET_CODE} -eq 0 ]
then
        echo "${EXTRACT_SQL2} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
        echo "Aborting: Error ${EXTRACT_SQL2} at `date '+%a %b %e %T'`" >>${LOG_FILE}
        send_delay_email
        exit 99
fi
#################################################################
##Rename File
mv category_full_${BANNER}.txt category_full_off5th_`date +%Y_%m_%d`.txt
wait
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${DATA}/category_full_off5th_`date +%Y_%m_%d`.txt  ]
then
        FILE_NAME=category_full_off5th_`date +%Y_%m_%d`.txt
        TFILE_SIZE="`ls -ll ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
        FILE_COUNT="`wc -l ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
fi
echo "File size is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
##FILE COUNT VALIDATION
#################################################################
if [ ${FILE_COUNT} -gt 100 ]
then
 echo "Enough records on the file " >> ${LOG_FILE}
 echo "Starting FTP process " >> ${LOG_FILE}
else
 echo "Aborting: Error loading category_full_off5th_`date +%Y_%m_%d`.txt  at `date '+%a %b %e %T'`" >>${LOG_FILE}
 echo "${PROCESS} was not sent. Minimum amount of data was not present." >> $LOG_FILE
 send_delay_email
 exit 99
fi
#################################################################
## third file
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL3} "$CLNECONNECTION" "${SCHEMA}" "${BANNER}" "$BMCONNECTION">products_in_category_${BANNER}.txt
SQL_RET_CODE=$?
echo "Creation of the category product data file ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
wait
#################################################################
##SQL ERROR VALIDATION
#################################################################
if [ ${SQL_RET_CODE} -eq 0 ]
then
        echo "${EXTRACT_SQL3} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
        echo "Aborting: Error ${EXTRACT_SQL3} at `date '+%a %b %e %T'`" >>${LOG_FILE}
        send_delay_email
        exit 99
fi
#################################################################
##Rename File
mv products_in_category_${BANNER}.txt products_in_category_off5th_`date +%Y_%m_%d`.txt
wait
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${DATA}/products_in_category_off5th_`date +%Y_%m_%d`.txt  ]
then
FILE_NAME=products_in_category_off5th_`date +%Y_%m_%d`.txt
TFILE_SIZE="`ls -ll ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
FILE_COUNT="`wc -l ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
fi
echo "File size is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
##FILE COUNT VALIDATION
#################################################################
if [ ${FILE_COUNT} -gt 6000 ]
then
 echo "Enough records on the file " >> ${LOG_FILE}
 echo "Starting FTP process " >> ${LOG_FILE}
else
 echo "Aborting: Error loading products_in_category_off5th_`date +%Y_%m_%d`.txt  at `date '+%a %b %e %T'`" >>${LOG_FILE}
 echo "${PROCESS} was not sent. Minimum amount of data was not present." >> $LOG_FILE
 send_delay_email
 exit 99
fi
if [ -e ${DATA}/product_attribute_off5th_`date +%Y_%m_%d`.txt  ]
then
 echo "product_attribute_off5th_`date +%Y_%m_%d`.txt already exists so not executing ${EXTRACT_SQL4} again" >>${LOG_FILE}
else
#################################################################
## fourth file
sqlplus -s -l  $CONNECTDW @${EXTRACT_SQL4}  "${SCHEMA}" "${BANNER}" "$BMCONNECTION">product_attribute_${BANNER}.txt
SQL_RET_CODE=$?
echo "Creation of the product attribute data file ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
wait
#################################################################
##SQL ERROR VALIDATION
#################################################################
if [ ${SQL_RET_CODE} -eq 0 ]
then
        echo "${EXTRACT_SQL4} completed at `date '+%a %b %e %T'`" >>${LOG_FILE}
else
        echo "Aborting: Error ${EXTRACT_SQL4} at `date '+%a %b %e %T'`" >>${LOG_FILE}
        send_delay_email
        exit 99
fi
#################################################################
##Rename File
mv product_attribute_${BANNER}.txt product_attribute_off5th_`date +%Y_%m_%d`.txt
wait
#################################################################
# GET FILE LINE COUNT
#################################################################
if [ -e ${DATA}/product_attribute_off5th_`date +%Y_%m_%d`.txt  ]
then
        FILE_NAME=product_attribute_off5th_`date +%Y_%m_%d`.txt
        TFILE_SIZE="`ls -ll ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
        FILE_COUNT="`wc -l ${DATA}/$FILE_NAME |tr -s ' ' '|' |cut -f1 -d'|'`" # linecount of the file
fi
echo "File size is: ${TFILE_SIZE}" >> ${LOG_FILE}
echo "Line count is: ${FILE_COUNT}" >> ${LOG_FILE}
#################################################################
##FILE COUNT VALIDATION
#################################################################
if [ ${FILE_COUNT} -gt 10000 ]
then
 echo "Enough records on the file " >> ${LOG_FILE}
 echo "Starting FTP process " >> ${LOG_FILE}
else
 echo "Aborting: Error loading product_attribute_off5th_`date +%Y_%m_%d`.txt at `date '+%a %b %e %T'`" >>${LOG_FILE}
 echo "${PROCESS} was not sent. Minimum amount of data was not present." >> $LOG_FILE
 send_delay_email
 exit 99
fi
fi
#################################################################

echo  > product_full_${BANNER}_`date +%Y%m%d`.txt.fin
echo  > category_full_${BANNER}_`date +%Y%m%d`.txt.fin
echo  > products_in_category_${BANNER}_`date +%Y%m%d`.txt.fin
echo  > products_in_category_${BANNER}_`date +%Y%m%d`.txt.fin

if [ "${BANNER}" == "saks" ];
then
tar -cvzf catalog_full_${BANNER}_`date +%Y%m%d`.tar.gz product_full_${BANNER}_`date +%Y%m%d`.txt category_full_${BANNER}_`date +%Y%m%d`.txt products_in_category_${BANNER}__`date +%Y%m%d`.txt
wait
#ftp -nv ftp.richrelevance.com<<EOF>> $LOG_FILE
#user saksftp ko11o1k0l
#bin
#put catalog_full_${BANNER}_`date +%Y%m%d`.tar.gz
#quit
#EOF
#################################################################
##FTP TRANSFER VALIDATION
#################################################################
if [ `egrep -c "226 Transfer complete" ${LOG_FILE}` -eq 0 ]
then
echo "FTP process failed. Please investigate" >> ${LOG_FILE}
send_delay_email
exit 99
fi
echo "Finished FTP process " >> ${LOG_FILE}
#################################################################
elif [ "${BANNER}" == "o5" ];
then
cp product_full_off5th_`date +%Y_%m_%d`.txt RR_Off5th
wait
cp category_full_off5th_`date +%Y_%m_%d`.txt RR_Off5th
wait
cp products_in_category_off5th_`date +%Y_%m_%d`.txt RR_Off5th
wait
cp product_attribute_off5th_`date +%Y_%m_%d`.txt RR_Off5th
wait
cd RR_Off5th
zip -r catalog_full_off5th_`date +%Y_%m_%d`.zip  *`date +%Y_%m_%d`.txt
wait
#################################################################
##ZIP FILE SIZE VALIDATION
#################################################################
echo "File zip completed. noW validating zip file " >> ${LOG_FILE}
if [ -e ${DATA}/RR_Off5th/catalog_full_off5th_`date +%Y_%m_%d`.zip ]
then
 GFILE_NAME=catalog_full_off5th_`date +%Y_%m_%d`.zip
 GFILE_SIZE="`ls -ll ${DATA}/RR_Off5th/$GFILE_NAME |tr -s ' ' '|' |cut -f5 -d'|'`" # size of the file
fi
if [ ${GFILE_SIZE} -gt 0 ]
then
 echo "File zip is valid. so start FTP " >> ${LOG_FILE}
else
 echo "Aborting: Error in ZIP file ${GFILE_NAME} at `date '+%a %b %e %T'`" >>${LOG_FILE}
 send_delay_email
exit 99
fi
#################################################################
#ftp -nv ftp.richrelevance.com<<EOF>> $LOG_FILE
#user saksoff5th ae0ahL3me1Ibu
#bin
#put catalog_full_off5th_`date +%Y_%m_%d`.zip
#quit
#EOF
#################################################################
##FTP TRANSFER VALIDATION
#################################################################
if [ `egrep -c "226 Transfer complete" ${LOG_FILE}` -eq 0 ]
then
echo "FTP process failed. Please investigate" >> ${LOG_FILE}
send_delay_email
exit 99
fi
echo "Finished FTP process " >> ${LOG_FILE}
#################################################################
fi

rm $HOME/DATA/RR_Off5th/*
#################################################################
##Update Runstats Finish
#################################################################
sqlplus -s -l  $CONNECTDW<<EOF>${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_SIZE" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
send_delay_email
exit 99
else
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
fi
exit 0
