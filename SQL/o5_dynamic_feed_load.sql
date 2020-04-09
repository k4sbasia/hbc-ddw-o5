set echo off
set linesize 10000
set pagesize 0
set sqlprompt ''
set timing on
set heading off
set trimspool on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE


-----------------------------------------------------------------------------SFCC_PROD_SKU_DYN_FLAGS update/insert------------------------------------------------------------------------

	DECLARE

	v_FLAG_CHG_DT DATE;
	v_LAST_CHG_DT DATE;

	CURSOR existing IS
   		SELECT sku.PRODUCT_ID, sku.SKN, sku.ISCLEARANCE AS EXISTING_ISCLEARANCE, sku.IsFinalSale AS EXISTING_IsFinalSale,
   			CASE
   				WHEN pr.PRICE_TYPE_CD IN ('M', 'C', 'F') OR SD_PIP_TEXT IS NOT NULL THEN 'true'
   				WHEN (pr.PRICE_TYPE_CD NOT IN ('M', 'C', 'F')) THEN 'false'
   			ELSE 'false' END AS ACTUAL_ISCLEARANCE,
   			CASE WHEN pr.PRICE_TYPE_CD IN ('C', 'F') THEN 'true'
   			ELSE 'false' END AS ACTUAL_IsFinalSale,
             CASE WHEN NVL(bs.IN_STOCK_SELLABLE_QTY,0)>0   THEN '1' ELSE '0' END  ACTUAL_INSTOCK
   		FROM EDATA_EXCHANGE.O5_SD_PRICE pr
   		INNER JOIN O5.SFCC_PROD_SKU_DYN_FLAGS sku ON pr.SKN_NO = sku.SKN
        LEFT JOIN o5.inventory bs ON  pr.SKN_NO=bs.SKN_NO
   		;

   	TYPE exist_type IS TABLE OF existing%rowtype;
   	v_exist			exist_type;


   CURSOR not_existing IS
   		SELECT pr.ITEM_ID AS PRODUCT_ID, pr.SKN_NO as SKN, skunx.ISCLEARANCE AS EXISTING_ISCLEARANCE, skunx.IsFinalSale AS EXISTING_IsFinalSale,
   			CASE
   				WHEN pr.PRICE_TYPE_CD IN ('M', 'C', 'F') OR SD_PIP_TEXT IS NOT NULL THEN 'true'
   				WHEN (pr.PRICE_TYPE_CD NOT IN ('M', 'C', 'F')) THEN 'false'
   			ELSE 'false' END AS ACTUAL_ISCLEARANCE,
   			CASE WHEN pr.PRICE_TYPE_CD IN ('C', 'F') THEN 'true'
   			ELSE 'false' END AS ACTUAL_IsFinalSale,
             CASE WHEN NVL(bs.IN_STOCK_SELLABLE_QTY,0)>0   THEN '1' ELSE '0' END  ACTUAL_INSTOCK
   		FROM EDATA_EXCHANGE.O5_SD_PRICE pr
   		LEFT JOIN O5.SFCC_PROD_SKU_DYN_FLAGS skunx ON pr.SKN_NO = skunx.SKN
        LEFT JOIN o5.inventory bs ON  pr.SKN_NO=bs.SKN_NO
   		WHERE skunx.SKN IS NULL
   		;

   	TYPE not_exist_type IS TABLE OF not_existing%rowtype;
   	v_not_exist			not_exist_type;


   BEGIN

	    SELECT cast(sysdate AS date) INTO v_FLAG_CHG_DT FROM dual;


	   	OPEN existing;
		LOOP
			FETCH existing BULK COLLECT INTO v_exist LIMIT 500000;
			EXIT WHEN v_exist.count = 0;

			FORALL indx IN v_exist.FIRST..v_exist.LAST

			update O5.SFCC_PROD_SKU_DYN_FLAGS
			set ISCLEARANCE = v_exist(indx).ACTUAL_ISCLEARANCE,
				IsFinalSale = v_exist(indx).ACTUAL_IsFinalSale,
				DYN_FLAG_CHG_DT = CASE WHEN (nvl(ISCLEARANCE, 'NLL') <> v_exist(indx).ACTUAL_ISCLEARANCE OR nvl(IsFinalSale, 'NLL') <> v_exist(indx).ACTUAL_IsFinalSale) THEN v_FLAG_CHG_DT ELSE DYN_FLAG_CHG_DT END,
                IN_STOCK= v_exist(indx).ACTUAL_INSTOCK
                , IN_STOCK_CHG_DT= v_FLAG_CHG_DT
			WHERE SKN = v_exist(indx).SKN
			AND (nvl(ISCLEARANCE, 'NLL') <> v_exist(indx).ACTUAL_ISCLEARANCE OR nvl(IsFinalSale, 'NLL') <> v_exist(indx).ACTUAL_IsFinalSale
               OR  nvl(IN_STOCK,'NLL') <> v_exist(indx).ACTUAL_INSTOCK)

			;
			COMMIT;
		END LOOP;
		CLOSE existing;


		OPEN not_existing;
		LOOP
			FETCH not_existing BULK COLLECT INTO v_not_exist LIMIT 500000;
			EXIT WHEN v_not_exist.count = 0;

			FORALL indx IN v_not_exist.FIRST..v_not_exist.LAST

			INSERT INTO O5.SFCC_PROD_SKU_DYN_FLAGS(PRODUCT_ID, SKN, ISSALE, ISCLEARANCE, DYN_FLAG_CHG_DT, IN_STOCK, IN_STOCK_CHG_DT, STATUS, COLOR, SIZ, UPC, PIM_CHG_DT, IsFinalSale)
			VALUES(v_not_exist(indx).PRODUCT_ID, v_not_exist(indx).SKN, NULL, v_not_exist(indx).ACTUAL_ISCLEARANCE, v_FLAG_CHG_DT, v_not_exist(indx).ACTUAL_INSTOCK, v_FLAG_CHG_DT, NULL, NULL, NULL, NULL, NULL, v_not_exist(indx).ACTUAL_IsFinalSale)
			;
			COMMIT;
		END LOOP;
		CLOSE not_existing;
   END;
   /

exec dbms_stats.gather_table_stats('O5','SFCC_PROD_SKU_DYN_FLAGS');

UPDATE O5.SFCC_PROD_PRODUCT_DATA set isSale='false', isClearance='false'--,isNew=NVL(isNew,'false')
 ;
         COMMIT;

         DECLARE
        CURSOR cur IS
    select PRODUCT_ID , bsp.isSale,bsp.ISCLEARANCE,bsp.IN_STOCK , bsp.STATUS sku_status
             from  O5.SFCC_PROD_SKU_DYN_FLAGS bsp ,O5.SFCC_PROD_PRODUCT_DATA   sp
             where bsp.PRODUCT_ID=sp.PRDUCT_CODE
             order by PRODUCT_ID;
                TYPE v_typ IS
            TABLE OF cur%rowtype;
                v_coll     v_typ;

           TYPE v_itm_prc_typ IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(30);
       v_coll_itm_prc_typ v_itm_prc_typ;
          BEGIN
              OPEN cur;
        LOOP
            FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
             EXIT WHEN v_coll.count = 0;
            FORALL indx IN v_coll.first..v_coll.last
    --        LOOP
    --         v_coll_itm_prc_typ(v_coll(indx).item_id):= v_coll(indx).PRC_typ_cd;
    --        END LOOP;

            UPDATE O5.SFCC_PROD_PRODUCT_DATA set isclearance= CASE WHEN v_coll(indx).ISCLEARANCE='true'  AND v_coll(indx).IN_STOCK ='1' AND v_coll(indx).sku_status='Yes' THEN 'true' else isclearance END
            where PRDUCT_CODE=v_coll(indx).PRODUCT_ID ;

            COMMIT;

            END LOOP;
          END;
      /

			DECLARE
		         CURSOR cur IS
		     select sp.PRDUCT_CODE , sp.ISNEW, CASE WHEN to_date(sp.PUBLISH_DT,'MM/DD/YYYY') >= trunc(sysdate-8) THEN 'true' ELSE 'false' END DERIVED_NEW
		              from O5.SFCC_PROD_PRODUCT_DATA   sp
		              where (sp.ISNEW = 'true' or  to_date(sp.PUBLISH_DT,'MM/DD/YYYY') >= trunc(sysdate-8))
		              ;
		                 TYPE v_typ IS
		             TABLE OF cur%rowtype;
		                 v_coll     v_typ;

		            TYPE v_itm_prc_typ IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(30);
		        v_coll_itm_prc_typ v_itm_prc_typ;
		           BEGIN
		               OPEN cur;
		         LOOP
		             FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
		              EXIT WHEN v_coll.count = 0;
		             FORALL indx IN v_coll.first..v_coll.last
		     --        LOOP
		     --         v_coll_itm_prc_typ(v_coll(indx).item_id):= v_coll(indx).PRC_typ_cd;
		     --        END LOOP;

		             UPDATE O5.SFCC_PROD_PRODUCT_DATA set isNEW=  v_coll(indx).DERIVED_NEW, DYN_FLAG_CHG_DT=SYSDATE
		             where PRDUCT_CODE=v_coll(indx).PRDUCT_CODE ;

		             COMMIT;

		             END LOOP;
		           END;
		       /			

exec dbms_stats.gather_table_stats('O5','SFCC_PROD_PRODUCT_DATA');

EXIT;
