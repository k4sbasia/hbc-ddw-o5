#!/usr/bin/ksh
#############################################################################################################################
####                           SAKS INC.
#############################################################################################################################
#####
#####   PROGRAM NAME : link_share_sales.sh
#####
#####   DESCRIPTION  : This script does the following
#####                              1. Fetches data from OMS for Yesterday
#####                              2. Processes and Merges data from Source tables to BI_SALE for further processing
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   ------------            ----------      ------------
#####                   Kanhu C Patro           05/01/2020      Created New To Populate BI SALE for O5 Using OMS Data
#############################################################################################################################
#Variable Declaration
BANNER=$1 #SAKS and OFF5 should be the banner data
if [ $# -ne 1 ]
then

        echo ""
        echo ""
        echo "         USAGE : This Script Needs to Have a Parameter Banner Value SAKS and OFF5 should be the banner data "
        echo "         USAGE : This Script Needs to Have a Parameter The Vendor Name <UOP_POP_ORDER_FETCH.sh> <BANNER> "
        echo "         Example : . ./UOP_POP_ORDER_FETCH.sh SAKS/OFF5 "
        echo ""
        echo ""

        exit 99
elif [ "$1" != "SAKS" ] && [ "$1" != "OFF5" ]
then      
        echo ""
        echo ""
        echo "         USAGE : This Script Needs should have a VALID parameter. SAKS or OFF5"
        echo "         Example : . ./UOP_POP_ORDER_FETCH.sh SAKS/OFF5 "
        echo ""
        echo ""
        
        exit 99
elif [ "$1" = "SAKS" ] || [ "$1" = "OFF5" ] 
then
        #Variable Declaration  
        PROCESS="UOP_ORDER_FETCH_POP" 
        SQL=$HOME/SQL
        SQL_FILE=${PROCESS}.sql
        LOG=$HOME/LOG
        LOG_FILE=${PROCESS}_${BANNER}_`date +"%Y%m%d_%H%M%S"`.log
        if [ "$1" = "SAKS" ]
        then
            SCHEMA="MREP."
            # CONNECTION="mrep/qsdw_2015@QASDW" # For QA
            # CONNECTION="mrep/qsdw_2015@QASDW"   # For PROD 
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

#Run SQL Script to Merge Data into BI_SALE
sqlplus -L $CONNECTION @${SQL}/${SQL_FILE} ${SCHEMA} >> ${LOG}/${LOG_FILE}

v_dmd_dollars=`
sqlplus -s -l $CONNECTION <<EOF
    set heading off
    whenever sqlerror exit 9
    set echo on
    DECLARE
        v_dmd_dollars NUMBER;
    BEGIN
        -- v_dmd_dollars := 0;
        SELECT to_char(nvl(SUM (extend_price_amt),0))
          --INTO v_dmd_dollars
          FROM O5.BI_SALE
         WHERE orderdate >= TRUNC (SYSDATE) - 1
    END;
    /
    EXIT;
EOF`

if [ $v_dmd_dollars -lt 1000 ]
then
    echo "Not Enough Demand for O5, Process Abort for Manual Validation." >> ${LOG}/${LOG_FILE}
    exit 9
fi

if [ `egrep -c "^ERROR|ORA-|not found|closed connection|SP2-0|^553" ${LOG}/${LOG_FILE}` -ne 0 ]
then
        echo "${PROCESS} for ${BANNER} failed. Please investigate" >> ${LOG}/${LOG_FILE}
        exit 9
else
        echo "${PROCESS} for ${BANNER} completed without errors."
fi

