#!/usr/bin/ksh
#############################################################################################################################
####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : o5a_refresh_mviews.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Fetches data from OMS for Yesterday
#####                              2. Processes and Merges data from Source tables to BI_SALE for further processing
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Kanhu C Patro           05/01/2020      Script to Refresh MV's in SDDW Schema
#############################################################################################################################
#Variable Declaration
BANNER=$1 #SAKS and OFF5 should be the banner data
if [ $# -ne 1 ]
then

        echo ""
        echo ""
        echo "         USAGE : This Script Needs to Have a Parameter Banner Value SAKS and OFF5 should be the banner data "
        echo "         USAGE : This Script Needs to Have a Parameter The Vendor Name <o5a_refresh_mviews.sh> <BANNER> "
        echo "         Example : . ./o5a_refresh_mviews.sh SAKS/OFF5 "
        echo ""
        echo ""

        exit 99
elif [ "$1" != "SAKS" ] && [ "$1" != "OFF5" ]
then      
        echo ""
        echo ""
        echo "         USAGE : This Script Needs should have a VALID parameter. SAKS or OFF5"
        echo "         Example : . ./o5a_refresh_mviews.sh SAKS/OFF5 "
        echo ""
        echo ""
        
        exit 99
elif [ "$1" = "SAKS" ] || [ "$1" = "OFF5" ] 
then
        #Variable Declaration  
        PROCESS="o5a_refresh_mviews" 
        SQL=$HOME/TESTING
        SQL_FILE=${PROCESS}.sql
        LOG=$HOME/LOG
        LOG_FILE=${PROCESS}_${BANNER}_`date +"%Y%m%d_%H%M%S"`.log
        if [ "$1" = "SAKS" ]
        then
            SCHEMA="MREP."
            # CONNECTION="mrep/qsdw_2015@QASDW" # For QA
            CONNECTION="mrep/qsdw_2015@QASDW"   # For PROD 
        elif [ "$1" = "OFF5" ]
        then
            SCHEMA="O5."
            # CONNECTION="o5/qsdw_2015@QASDW"   # For QA
            CONNECTION="O5/o5prd@newprdsdw"     # For PROD
        fi
        echo "Process Initiating for ${BANNER} at `date`" > ${LOG}/${LOG_FILE}
        echo "PROCESS NAME : ${PROCESS}" >> ${LOG}/${LOG_FILE}
        echo "SCHEMA NAME : ${SCHEMA}" >> ${LOG}/${LOG_FILE}
        echo "DB CONNECTION : ${CONNECTION}" >> ${LOG}/${LOG_FILE}
        echo "SQL FILE : ${SQL_FILE}" >> ${LOG}/${LOG_FILE}
        echo "LOG FILE : ${LOG_FILE}" >> ${LOG}/${LOG_FILE}
fi

#Run SQL To Refresh MV's
sqlplus -L $CONNECTION @${SQL}/${SQL_FILE} ${SCHEMA} >> ${LOG}/${LOG_FILE}


if [ `egrep -c "^ERROR|ORA-|not found|closed connection|SP2-0|^553" ${LOG}/${LOG_FILE}` -ne 0 ]
then
        echo "${PROCESS} for ${BANNER} failed. Please investigate" >> ${LOG}/${LOG_FILE}
        exit 9
else
        echo "${PROCESS} for ${BANNER} completed without errors."
        exit $?
fi

