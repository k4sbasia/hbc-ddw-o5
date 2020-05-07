SET SERVEROUTPUT ON

DECLARE
    v_process VARCHAR2(50);
    v_banner    VARCHAR2(10);
    v_process_st_time VARCHAR2(50);
    v_process_end_time VARCHAR2(50);

BEGIN
    v_process := 'ORDER PROCESSING - POPULATE PROMOTION' ;
    v_banner  := CASE WHEN '&1' = 'O5.' THEN '''O5''' WHEN '&1' = 'MREP.' THEN '''MREP''' END;
    v_process_st_time := to_char(sysdate,'DD-MON-RRRR HH.MI.SS AM');
    dbms_output.put_line('Process : ' || v_process || ' Begins at ' || v_process_st_time);

    MERGE INTO &1.bi_promo_sale t1
    USING 
        (
        WITH all_promo_data AS 
            (
            SELECT DISTINCT 
                    ordernum,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 1)  AS promo_id_01,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 2)  AS promo_id_02,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 3)  AS promo_id_03,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 4)  AS promo_id_04,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 5)  AS promo_id_05,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 6)  AS promo_id_06,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 7)  AS promo_id_07,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 8)  AS promo_id_08,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 9)  AS promo_id_09,
                    regexp_substr(ord.promo_id, '[^,]+', 1, 10) AS promo_id_10
               FROM &1.bi_sale ord 
              WHERE orderdate > sysdate - 14 
                AND promo_id IS NOT NULL
    --        AND ordernum = '10086245'
            )
            , order_specific_promo AS
            (
                SELECT ordernum, CASE WHEN promo_id_01 IS NOT NULL THEN promo_id_01 ELSE NULL END AS promo_id FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_02 IS NOT NULL THEN promo_id_02 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_03 IS NOT NULL THEN promo_id_03 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_04 IS NOT NULL THEN promo_id_04 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_05 IS NOT NULL THEN promo_id_05 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_06 IS NOT NULL THEN promo_id_06 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_07 IS NOT NULL THEN promo_id_07 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_08 IS NOT NULL THEN promo_id_08 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_09 IS NOT NULL THEN promo_id_09 ELSE NULL END FROM all_promo_data
                UNION
                SELECT ordernum, CASE WHEN promo_id_10 IS NOT NULL THEN promo_id_10 ELSE NULL END FROM all_promo_data
            )
            SELECT * FROM order_specific_promo WHERE promo_id IS NOT NULL
        ) t2 ON ( t2.ordernum = t1.ordernum AND t2.promo_id = t1.promo_id )
    WHEN MATCHED THEN UPDATE SET t1.modify_dt = TRUNC(sysdate)
    WHEN NOT MATCHED THEN
    INSERT ( ordernum, promo_id, modify_dt )
    VALUES ( t2.ordernum, t2.promo_id, TRUNC(sysdate) )
    ;
dbms_output.put_line('Total Rows Processed : ' || SQL%ROWCOUNT);
COMMIT;

v_process_end_time := to_char(sysdate,'DD-MON-RRRR HH.MI.SS AM');
dbms_output.put_line('Process : ' || v_process || ' Completed at ' || v_process_end_time);

EXCEPTION
    WHEN others
        THEN raise;
END;
/
EXIT;