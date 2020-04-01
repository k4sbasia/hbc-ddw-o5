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
   			CASE WHEN pr.CURRENT_TICKET = pr.OFFER_PRICE THEN 'false'
   				WHEN pr.PRICE_TYPE_CD IN ('M', 'C', 'F') OR SD_PIP_TEXT IS NOT NULL THEN 'true' 
   				WHEN (pr.PRICE_TYPE_CD NOT IN ('M', 'C', 'F')) THEN 'false' 
   			ELSE 'false' END AS ACTUAL_ISCLEARANCE,
   			CASE WHEN pr.PRICE_TYPE_CD IN ('C', 'F') THEN 'true' 
   			ELSE 'false' END AS ACTUAL_IsFinalSale
   		FROM EDATA_EXCHANGE.O5_SD_PRICE pr
   		INNER JOIN O5.SFCC_PROD_SKU_DYN_FLAGS sku ON pr.SKN_NO = sku.SKN 
   		;
  		
   	TYPE exist_type IS TABLE OF existing%rowtype;
   	v_exist			exist_type;
   
   
   CURSOR not_existing IS
   		SELECT pr.ITEM_ID AS PRODUCT_ID, pr.SKN_NO as SKN, skunx.ISCLEARANCE AS EXISTING_ISCLEARANCE, skunx.IsFinalSale AS EXISTING_IsFinalSale,
   			CASE WHEN pr.CURRENT_TICKET = pr.OFFER_PRICE THEN 'false'
   				WHEN pr.PRICE_TYPE_CD IN ('M', 'C', 'F') OR SD_PIP_TEXT IS NOT NULL THEN 'true' 
   				WHEN (pr.PRICE_TYPE_CD NOT IN ('M', 'C', 'F')) THEN 'false' 
   			ELSE 'false' END AS ACTUAL_ISCLEARANCE,
   			CASE WHEN pr.PRICE_TYPE_CD IN ('C', 'F') THEN 'true' 
   			ELSE 'false' END AS ACTUAL_IsFinalSale
   		FROM EDATA_EXCHANGE.O5_SD_PRICE pr
   		LEFT JOIN O5.SFCC_PROD_SKU_DYN_FLAGS skunx ON pr.SKN_NO = skunx.SKN
   		WHERE skunx.SKN IS NULL 
   		;
   
   	TYPE not_exist_type IS TABLE OF not_existing%rowtype;
   	v_not_exist			not_exist_type;
   	
   
   BEGIN 
	   
	    SELECT cast(sysdate AS date) INTO v_FLAG_CHG_DT FROM dual;
		SELECT max(PIM_CHG_DT) INTO v_LAST_CHG_DT FROM O5.SFCC_PROD_SKU_DYN_FLAGS;
	   
	   	OPEN existing;
		LOOP 
			FETCH existing BULK COLLECT INTO v_exist LIMIT 500000;
			EXIT WHEN v_exist.count = 0;
		
			FORALL indx IN v_exist.FIRST..v_exist.LAST 
			
			update O5.SFCC_PROD_SKU_DYN_FLAGS
			set ISCLEARANCE = v_exist(indx).ACTUAL_ISCLEARANCE,
				IsFinalSale = v_exist(indx).ACTUAL_IsFinalSale,
				DYN_FLAG_CHG_DT = v_FLAG_CHG_DT
			WHERE SKN = v_exist(indx).SKN 
			AND (nvl(ISCLEARANCE, 'NLL') <> v_exist(indx).ACTUAL_ISCLEARANCE OR nvl(IsFinalSale, 'NLL') <> v_exist(indx).ACTUAL_IsFinalSale)
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
			VALUES(v_not_exist(indx).PRODUCT_ID, v_not_exist(indx).SKN, NULL, v_not_exist(indx).ACTUAL_ISCLEARANCE, v_FLAG_CHG_DT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_not_exist(indx).ACTUAL_IsFinalSale)
			;
			COMMIT;
		END LOOP;
		CLOSE not_existing;
   END;
   /


EXIT;
   	
   	