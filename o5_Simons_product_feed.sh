
#!/bin/ksh
#############################################################################################################################
#####                           SAKS INC.
#############################################################################################################################
#####
###   PROGRAM NAME : prd_partner_base_inv_price_upd.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Calls the sql script for building the BI partner base
#####
#####   CODE HISTORY :  Name                            Date            Description
#####                                   ------------            ----------      ------------
###                                   Unknown                         Unknown         Created
#####                                   Rajesh Mathew           07/12/2010      Modified
#####                                   Kanhu C Patro           10/01/2019      HDD-1272 Change to Exclude Prada
#############################################################################################################################
################################################################
. $HOME/params.conf o5
export PROCESS='o5_Simons_product_feed'
export SQL=$HOME/SQL
export LOG=$HOME/LOG
export DATA=$HOME/DATA
export LOG_FILE="$LOG/${PROCESS}_log.txt"
export BAD_SUBJECT="${PROCESS} failed"
export JOB_NAME="${PROCESS}"
export SCRIPT_NAME="${PROCESS}"
export EXTRACT_SQL='$SQL/${PROCESS}.sql'
export SFILE_SIZE='0'
export FILE_NAME="$DATA/o5_Simons_product_`date +"%Y%m%d"`.txt"
export LOAD_COUNT='0'
export FILE_COUNT='0'
export TFILE_SIZE='0'
export SOURCE_COUNT='0'
export TARGET_COUNT='0'


########################################################################
##Initialize Email Function
########################################################################
function send_email {
 CURRENT_TIME=`date +"%m/%d/%Y-%H:%M:%S"`
 cat $HOME/email_distribution_list.txt|grep '^3'|while read group address
 do
 cat ${LOG_FILE} ${CURRENT_TIME}|mailx -s "${SUBJECT}" $address
 done
}
#################################################################
##Update Runstats Start
#################################################################
sqlplus -s -l $CONNECTDW <<EOF > ${LOG}/${PROCESS}_runstats_start.log @$HOME/SQL/runstats_start.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
#################################################################
echo "bi_partner_base Extract  Process started at `date '+%a %b %e %T'`" >${LOG_FILE}
#########################################################################
#  Run the sql script that performs the product info extract
#################################################################
echo "bi_partner_base Sdw  Process started at `date '+%a %b %e %T'`" >>${LOG_FILE}
sqlplus -s -l $CONNECTDW @${EXTRACT_SQL} ${FILE_NAME} ${SCHEMA}
cd ${DATA}
sed -i '1d' ${FILE_NAME}
sed -i '1i Parent_SKU|Product_Id|Product_Name|Variation_Name|SKU_Number|Primary_Category|Secondary_Category|Product_URL|Product_Image_URL|Short_Product_Desc|Long_Product_Desc|Discount|Discount_Type|Sale_Price|Retail_Price|Begin_Date|End_Date|Brand|Shipping|Is_Delete_Flag|Keywords|Is_All_Flag|Manufacturer_Name|Shipping_Information|Availablity|Universal_Pricing_Code|Class_ID|Is_Product_Link_Flag|Is_Storefront_Flag|Is_Merchandiser_Flag|Currency|Path|Group|Category|Size|Color|Larger_Images|Qty_On_Hand|AUD_Sale_Price|GBP_Sale_Price|CHF_Sale_price|CAD_Sale_Price|AU_Publish|UK_Publish|CH_Publish|CA_Publish|Order_Flag|BM_Code|Material|Full_Category_Path|Prd_Alt_Image_urls|Department_id|Clearance|Gender|Final_sale' ${FILE_NAME}
echo "bi_partner_base Sdw  Process ended at `date '+%a %b %e %T'`" >>${LOG_FILE}
SOURCE_COUNT=`cat ${FILE_NAME} | wc -l`
#if [ ${SOURCE_COUNT} -gt 100000 ]
#then
#echo "ftping the file as file check was succesfull `date '+%a %b %e %T'`" >>${LOG_FILE}
#lftp -u saksoff5,tWIaOiOgZ6j94RM6WfoOfAXVxa6gRrQU sftp://sftp.sspo.com<<eof
#cd product
#put ${FILE_NAME}
#quit
#eof
#echo "End ftping the file `date '+%a %b %e %T'`" >>${LOG_FILE}
#else
#echo "Not enough data in the product file" >>${LOG_FILE}
#echo "Simons : off5Saks.com product feed is delayed and we are looking into it"|mailx -s "Saks Product feed delayed" hbcdigtialdatamanagement@hbc.com
#exit 99
#fi
#################################################################
if [ `egrep -c "^ERROR|ORA-|not found|SP2-0|^553" ${LOG_FILE}` -ne 0 ]
then
#mv "${LOG_FILE}" "${LOG_FILE}.`date +%Y%m%d`"
echo "${PROCESS} failed. Please investigate"
echo "${PROCESS} failed. Please investigate" >> ${LOG_FILE}
export SUBJECT=${BAD_SUBJECT}
send_email
exit 99
else
echo "${PROCESS} completed without errors."
echo "${PROCESS} completed without errors." >> ${LOG_FILE}
##Update Runstats Finish
sqlplus -s -l $CONNECTDW<<EOF > ${LOG}/${PROCESS}_runstats_finish.log @${SQL}/runstats_end.sql "$JOB_NAME" "$SCRIPT_NAME" "$SFILE_SIZE" "$FILE_NAME" "$LOAD_COUNT" "$FILE_COUNT" "$TFILE_SIZE" "$SOURCE_COUNT" "$TARGET_COUNT"
EOF
###################################################################################################
fi
