REM ############################################################################
REM                         SAKS, INC.
REM ############################################################################
REM
REM  SCRIPT NAME:  cheetah_xml_data.sql
REM  DESCRIPTION:  This script prepares the XML data for CHEETA by fetching data
REM                BV_CHEETAH_EXTRACT table
REM
REM
REM
REM
REM
REM  CODE HISTORY: Name	               		Date 	       	Description
REM                -----------------	  	----------  	--------------------------
REM                Rajesh Mathew		08/23/2010	     	Created
REM                Divya KAfle			05/16/2013	     	Modified
REM
REM ############################################################################
set sqlblanklines ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR  EXIT FAILURE
set echo off
set feedback off
set linesize 32767
set pagesize 0
set sqlprompt ''
set heading off
set trimspool on
SET LONG 999999999
COL xml FORMAT A32000
set serveroutput on
set feedback on
DECLARE
xml_item   CLOB;
BEGIN
 select
    '<?xml version="1.0" encoding="UTF-8"?>'
     ||
    XMLSERIALIZE(
     DOCUMENT (
     -- (
       a.data --as xmltype
      --)
     )
AS CLOB INDENT SIZE = 5--.EXTRACT ('/*').getclobVal ()
    ) into xml_item
    from
      ( select
        XMLELEMENT(
            "catalog",
            XMLATTRIBUTES(
                'master-o5a' AS "catalog-id",
                'http://www.demandware.com/xml/impex/catalog/2006-10-31' AS "xmlns"
            ),   xmlagg(
                XMLELEMENT ("product",
                    XMLATTRIBUTES (SP.PRDUCT_CODE as "product-id"),
                    XMLELEMENT ("custom-attributes",
                                XMLELEMENT ("custom-attribute",
                                            XMLATTRIBUTES ('isClearance' as "attribute-id"),NVL(sp.isClearance,'false')),
                                XMLELEMENT ("custom-attribute",
                                            XMLATTRIBUTES ('isNew' as "attribute-id"),NVL(sp.isNew,'false')),
                                XMLELEMENT ("custom-attribute",
                                            XMLATTRIBUTES ('Waitlist' as "attribute-id"),NVL(sp.isWaitlist,'false'))
                                            )
                                            )
                                            ),

             xmlagg(
             (select  xmlagg(XMLELEMENT ("product",
                    XMLATTRIBUTES (skn as "product-id"),
                    XMLELEMENT ("custom-attributes",
                                XMLELEMENT ("custom-attribute",
                                            XMLATTRIBUTES ('isClearance' as "attribute-id"),NVL(si.isClearance,'false')),
                                XMLELEMENT ("custom-attribute",
                                            XMLATTRIBUTES ('finalSale' as "attribute-id"),NVL(si.isFinalSale,'false'))
                                            )
                                            ) )
                            from
                            (select product_id,skn,max(isFinalSale) isFinalSale, max(isClearance) isClearance, max(DYN_FLAG_CHG_DT) DYN_FLAG_CHG_DT
                              from o5.SFCC_PROD_SKU_DYN_FLAGS si where sp.PRDUCT_CODE=si.product_id and si.skn is not null group by product_id, skn) si

                  )
                )
         ) data

from    o5.SFCC_PROD_PRODUCT_DATA sp
where  (exists  (select 'X' from  o5.SFCC_PROD_SKU_DYN_FLAGS si where sp.PRDUCT_CODE=si.product_id and
                              (  si.DYN_FLAG_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC')
                                OR  si.IN_STOCK_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC') 
								OR si.PIM_CHG_DT >=(select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC')  )
                          )
        OR
        sp.DYN_FLAG_CHG_DT  >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC')
      )
        OR ( sp.PIM_CHG_DT >= (select last_run_on from o5.JOB_STATUS where process_name='SFCC_DYNAMIC')
            )
--and sp.PRDUCT_CODE in ('0600084935160' ,'0600090478552','0600090861280')
--group  by sp.PRDUCT_CODE,sp.isNew
) a
;
DBMS_XSLPROCESSOR.clob2file(xml_item, 'DATASERVICE', 'dynamic_flags_o5_'||'&1'||'.xml', nls_charset_id('AL32UTF8'));
END;
/

exit;