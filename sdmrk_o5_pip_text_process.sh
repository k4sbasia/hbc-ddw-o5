#!/bin/bash
#############################################################################################################################
#####PROGRAM NAME : SDMRK - O5 PIP Text For Analytics
#####
#####   This Script Fetches CRM Feed on Every Monday, Truncates & Loads into STG_CRM_FEED_WEEKLY
#####   Source Location : Marketing DWAUTO
#####   Target Location : AUTOPROC - to Send it to Cheetah
#####   Picks up PIP Text data from O5 price Table, Stages it and Loads into SDMRK Table
#####
#####
#####
#####   CODE HISTORY :  Name                    Date            Description
#####                   Kanhu C Patro           11/15/2017      Initial Version
#####
#####
#############################################################################################################################
. $HOME/params.conf o5
#set -x
export process_name=sdmrk_o5_pip_text_process
export log_dir=$HOME/LOG
export data_dir=$HOME/DATA
export ctl_dir=$HOME/CTL
export sql_dir=$HOME/SQL

echo "Process ${process_name} Begins at `date +"%m/%d/%Y_%H:%M:%S"`" > $log_dir/${process_name}.log

function send_email
{
        if [ $1 -eq 0 ];
        then
			cat $log_dir/${process_name}.log | mailx -s "SDMRK O5th PIP Text Process Completed Successfully for `date +%Y%m%d`- Attached Log" hbcdigitaldatamanagement@saksinc.com off5themailmarketingdirect@saksinc.com customeranalytics@s5a.com
			exit 0
        elif [ $1 -eq 99 ];
        then
			cat $log_dir/${process_name}.log | mailx -s "SDMRK O5th PIP Text Process Failed for `date +%Y%m%d` - Attached Log" hbcdigitaldatamanagement@saksinc.com off5themailmarketingdirect@saksinc.com customeranalytics@s5a.com
			exit 99
        fi
}

echo "--------------------------------------------------------------------------" >> $log_dir/${process_name}.log
echo "Starting O5th SDMRK PIP Text Process at `date`" >> $log_dir/${process_name}.log

##Stage the PIP Text data in O5 Schema
sqlplus -L $CONNECTDW <<eof >>$log_dir/${process_name}.log
whenever sqlerror exit 99;
set serveroutput on;
set echo on;
set feedback off;
begin
execute immediate 'truncate table o5.stg_o5_ams_price_pip_text';
insert into o5.stg_o5_ams_price_pip_text
select
    ams.item_id as product_code,
    prd.upc,
    ams.skn_no as sku,
    ams.sd_pip_text as pip_text,
--    ams.promo_start_date,
--    ams.promo_end_date,
    to_date(trim(substr(ams.promo_start_date, 0, instr(promo_start_date, ' '))), 'mm/dd/yyyy') promo_start_date,
    to_date(trim(substr(ams.promo_end_date, 0, instr(promo_start_date, ' '))), 'mm/dd/yyyy') promo_end_date,
    prd.department_id as department,
--    price_type_cd AS price_status
    case when trim(ams.ams_price_type_cd) = '0' then 'R'
         when trim(ams.ams_price_type_cd) = '1' then 'M'
         when trim(ams.ams_price_type_cd) = '2' then 'C'
         when trim(ams.ams_price_type_cd) = '3' then 'F'
     end price_type
FROM edata_exchange.o5_sd_price ams
--from o5.o5_sd_price_today ams
join o5.bi_product prd on lpad(ams.skn_no, 8, '0') = substr(prd.sku, 6)
where ams.sd_pip_text is not null
;
dbms_output.put_line('Successfully Loaded Data Into o5.stg_o5_ams_price_pip_text with '|| SQL%rowcount);
commit;
end;
/
exit;
eof

###Insert Data to SDMRK Table
sqlplus -L $CONNECTMREPSTATS12C <<eod >>$log_dir/${process_name}.log
whenever sqlerror exit 99;
set serveroutput on;
set echo on;
set feedback off;
begin
--execute immediate 'truncate table mrep.stg_o5_ams_price_pip_text';
insert into mrep.stg_o5_ams_price_pip_text (product_code,upc,sku,pip_text,promo_start_date,promo_end_date,department,price_type)
select product_code, upc, sku, pip_text, promo_start_date, promo_end_date, department,price_type from o5.stg_o5_ams_price_pip_text@dmuser_11gprodsdw;
dbms_output.put_line('Successfully Loaded Data Into mrep.stg_o5_ams_price_pip_text with '|| SQL%rowcount);
commit;
delete mrep.stg_o5_ams_price_pip_text where effective_date < add_months(trunc(sysdate), -1);
dbms_output.put_line('History Data Removed : '|| SQL%rowcount);
commit;
end;
/
exit;
eod

error_count=`egrep -c "^ERROR|ORA-|not found|SP2-0|^553" $log_dir/${process_name}.log`

if [ $error_count -eq 0 ]
then
	echo "Ending PIP Text Process Now" >> $log_dir/${process_name}.log
	echo "--------------------------------------------------------------------------" >> $log_dir/${process_name}.log
	echo "Process ${process_name} Completes at `date +"%m/%d/%Y_%H:%M:%S"`" >>$log_dir/${process_name}.log
	send_email 0
else
	echo "Ending PIP Text Process Now" >> $log_dir/${process_name}.log
	echo "--------------------------------------------------------------------------" >> $log_dir/${process_name}.log
	echo "O5th DMRK PIP Text Process Failed, Please investigate" >>$log_dir/${process_name}.log
	send_email 99
fi
#set +x
