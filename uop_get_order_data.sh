#!/usr/bin/ksh
#############################################################################################################################
####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : link_share_sales.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Fetches data from OMS for Yesterday
#####				   2. Processes and Merges data from Source tables to BI_SALE for further processing
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Kanhu C Patro           05/01/2020      Created a new version from Original as part of JSON Conversion
#############################################################################################################################
#Variable Declaration
BANNER=$1 #SAKS and OFF5 should be the banner data

if [ $# -ne 1 ]
then

        echo ""
        echo ""
        echo "         USAGE : This Script Needs to Have a Parameter Banner Value SAKS and OFF5 should be the banner data "
        echo "         USAGE : This Script Needs to Have a Parameter The Vendor Name <UOP_ORDER_FETCH.sh> <BANNER> "
        echo "         Example : . ./UOP_ORDER_FETCH.sh SAKS/OFF5 "
        echo ""
        echo ""

        exit 99
elif [ "$1" != "SAKS" ] && [ "$1" != "OFF5" ]
then
        echo ""
        echo ""
        echo "         USAGE : This Script Needs should have a VALID parameter. SAKS or OFF5"
        echo "         Example : . ./UOP_ORDER_FETCH.sh SAKS/OFF5 "
        echo ""
        echo ""
	
	exit 99
elif [ "$1" = "SAKS" ] || [ "$1" = "OFF5" ]
then
	#Variable Declaration
	PROCESS="UOP_ORDER_FETCH_GET"
	SQL=$HOME/TESTING
	SQL_FILE=${PROCESS}.sql
	LOG=$HOME/LOG
	LOG_FILE=${PROCESS}_${BANNER}_`date +"%Y%m%d_%H%M%S"`.log
	if [ "$1" = "SAKS" ]
	then
		SCHEMA="MREP."
		CONNECTION="mrep/qsdw_2015@QASDW"
	elif [ "$1" = "OFF5" ]
	then
		SCHEMA="O5."
		CONNECTION="o5/qsdw_2015@QASDW"
	fi
	echo "Process Initiating for ${BANNER} at `date`" > ${LOG}/${LOG_FILE}
	echo "PROCESS NAME : ${PROCESS}" >> ${LOG}/${LOG_FILE}
	echo "SCHEMA NAME : ${SCHEMA}" >> ${LOG}/${LOG_FILE}
	echo "DB CONNECTION : ${CONNECTION}" >> ${LOG}/${LOG_FILE}
	echo "SQL FILE : ${SQL_FILE}" >> ${LOG}/${LOG_FILE}
	echo "LOG FILE : ${LOG_FILE}" >> ${LOG}/${LOG_FILE}
fi

#Run the ODI Process to Fetch The Data
#./odi_wrapper.sh "P_UOP_GET_ALL_ORDER_DATA" "001" "SAKS" > /home/cognos/TESTING/saks_uop_order_data_fetch_20191107.log &
#./odi_wrapper.sh "P_UOP_GET_ALL_ORDER_DATA" "001" "OFF5" > /home/cognos/TESTING/o5th_uop_order_data_fetch_20191107.log &


echo "Start ODI Process for ${BANNER} at `date`" >> ${LOG}/${LOG_FILE}
cd ${HOME}
./odi_wrapper.sh "P_UOP_SAKS_O5_ORDER_DATA" "001" "$BANNER" >> ${LOG}/${LOG_FILE}
ODI_STATUS=$?

#Check ODI Logs for Errors
echo "ODI Status : ${ODI_STATUS}" >> ${LOG}/${LOG_FILE}

if [ ${ODI_STATUS} -eq 0 ]
then
        echo "${BANNER} ODI Fetch Complete at `date`" >> ${LOG}/${LOG_FILE}
else
        echo "${BANNER} ODI Fetch Failed at `date`" >> ${LOG}/${LOG_FILE}
        exit 9
fi

if [ `egrep -c "^ERROR|ORA-|not found|closed connection|SP2-0|^553" ${LOG}/${LOG_FILE}` -ne 0 ]
then
        echo "${PROCESS} for ${BANNER} failed. Please investigate" >> ${LOG}/${LOG_FILE}
        exit 9
else
        echo "${PROCESS} for ${BANNER} completed without errors."
fi
