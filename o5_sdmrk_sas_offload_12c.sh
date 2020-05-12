#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5_sdmrk_sas_offload.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Refresh The Data In Marketing Data Mart
#####
#####
#####   CODE HISTORY :                    Name                    Date            Description
#####                                   ------------            ----------      ------------
#####
#####                                   Divya Kafle	        09/13/2013      created
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_sdmrk_sas_offload'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export CTL=$HOME/CTL
export LOG_FILE="${LOG}/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export SFILE_SIZE='0'
export FILE_NAME_ORDER='o5_orders.csv'
export FILE_NAME_CUSTOMER='o5_customer.csv'
export FILE_NAME_PROMOORDER='o5_promo_order.csv'
export FILE_NAME_INDIVIDUAL='o5_individual.csv'
export FILE_NAME_EMAIL_ADDRESS='o5_email_address.txt'
export FILE_NAME_PRODUCT='o5_product.csv'
export FILE_NAME_EMAIL_CHANGE='o5_email_change_his.csv'
export FILE_NAME_EMAIL_CM_SEG='o5_cheetah_segments.csv'
export FILE_ZIP='o5_sdmrk_sas_offload.zip'
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'
export SQLORDER="o5_sdmrk_sas_offload_order"
export SQLCUSTOMER="o5_sdmrk_sas_offload_customer"
export SQLPROMOORDER="o5_sdmrk_sas_offload_promo_order"
export SQLINDIVIDUAL="o5_sdmrk_sas_offload_individual"
export SQLEMAIL_ADDRESS="o5_sdmrk_sas_offload_email_address"
export SQLEMAILCHANGEHIS="o5_sdmrk_sas_offload_email_change_his"
export SQLEMAILCMSEGMENT="o5_sdmrk_sas_offload_email_cheetah_seg"
export SQLPRODUCTS="o5_sdmrk_sas_offload_product"
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
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C <<EOF> ${LOG}/${PROCESS}_runstats_start.log @${SQL}/runstats_start_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
##DB SQL
#################################################################
echo "${PROCESS} Started" > ${LOG_FILE}

echo "Starting ${SQLORDER}" >> ${LOG_FILE}



sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLORDER}.sql > ${DATA}/${FILE_NAME_ORDER}
EOF

echo "Starting ${SQLCUSTOMER}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLCUSTOMER}.sql > ${DATA}/${FILE_NAME_CUSTOMER}
EOF

echo "Starting ${SQLPROMOORDER}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLPROMOORDER}.sql > ${DATA}/${FILE_NAME_PROMOORDER}
EOF

echo "Starting ${SQLINDIVIDUAL}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLINDIVIDUAL}.sql > ${DATA}/${FILE_NAME_INDIVIDUAL}
EOF

echo "Starting ${SQLEMAIL_ADDRESS}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLEMAIL_ADDRESS}.sql > ${DATA}/${FILE_NAME_EMAIL_ADDRESS}
EOF

echo "Starting ${SQLEMAILCHANGEHIS}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLEMAILCHANGEHIS}.sql > ${DATA}/${FILE_NAME_EMAIL_CHANGE}
EOF

echo "Starting ${SQLPRODUCTS}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLPRODUCTS}.sql > ${DATA}/${FILE_NAME_PRODUCT}
EOF

echo "Starting ${SQLEMAILCMSEGMENT}" >> ${LOG_FILE}
sqlplus -s -l $CONNECTSDMRK12C <<EOF>> ${LOG_FILE} @${SQL}/${SQLEMAILCMSEGMENT}.sql > ${DATA}/${FILE_NAME_EMAIL_CM_SEG}
EOF

echo "Starting file compression" >> ${LOG_FILE}
cd ${DATA}
rm -f ${FILE_ZIP}
rm -f ${FILE_NAME_ORDER}.gz

zip ${FILE_ZIP} ${FILE_NAME_CUSTOMER} ${FILE_NAME_PROMOORDER} ${FILE_NAME_INDIVIDUAL} ${FILE_NAME_EMAIL_ADDRESS} ${FILE_NAME_EMAIL_CHANGE} ${FILE_NAME_PRODUCT} ${FILE_NAME_EMAIL_CM_SEG}

gzip ${FILE_NAME_ORDER}

echo "Ftp the file to Jackson SAS server" >> ${LOG_FILE}
ftp -nv 10.130.176.210  <<EOF>>${LOG_FILE}
user sasftp sasftp0313S
prompt off
bin
put  "${FILE_ZIP}" "${FILE_ZIP}"
put  "${FILE_NAME_ORDER}.gz" "${FILE_NAME_ORDER}.gz"
quit
EOF
################################################################
cd ${HOME}
##Update Runstats Finish
#################################################################
sqlplus -s -l $CONNECTRUNSTATS12C<<EOF> ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end_12c.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF

echo "${PROCESS} completed" >> ${LOG_FILE}

#################################################################
##Error Log Check
#################################################################
if [ `egrep -c "^ERROR|ORA-|invalid identifier|failed|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate\n" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
exit 99
#send_email
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors.\n" >> ${LOG_FILE}
exit 0
fi
