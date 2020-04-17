set echo on
set feedback on
set linesize 10000
set pagesize 0
set heading on

MERGE INTO o5.EMAIL_ADDRESS  trg
USING
(
SELECT DISTINCT bs.promo_id welcome_promo
FROM    O5.BI_SALE bs
where
bs.promo_id IN ( SELECT unique_offer_id
                         FROM MREP.unique_offer_id
                         WHERE offer_code IN ( SELECT promo
                                               FROM o5.o5_welcome_promos_ctl_tab
                                               WHERE (TRUNC(sysdate) BETWEEN start_date AND end_date)
                                             )
                        )
AND 
bs.promo_id IS NOT NULL
AND TRUNC(orderdate) >= TRUNC(sysdate)-2
AND TRUNC(orderdate) < TRUNC(sysdate)-1
) src
ON (trg.welcome_promo=src.welcome_promo)
WHEN MATCHED THEN
UPDATE SET wp_used = 'Y',
           wp_used_dt = TRUNC(sysdate)-1
WHERE wp_used IS NULL
;
COMMIT;
exit;
