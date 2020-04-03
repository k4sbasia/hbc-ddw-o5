  set echo off
set linesize 10000
set pagesize 0
set sqlprompt ''
set timing on
set heading off
set trimspool on
WHENEVER OSERROR  EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
         DECLARE
    CURSOR cur IS
        select pd.PRODUCT_ID,pd.UPC,Decode(pd.attribute_name,'Size','Siz',pd.attribute_name) attribute_name,pd.ATTRIBUTE_VAL,ps.UPC upc_sf 
        from pim_exp_bm.PIM_AB_O5_SKU_ATTR_DATA@pim_read  pd,o5.SFCC_PROD_SKU_DYN_FLAGS ps
        where
        attribute_name in ('status',
'Color',
'Size')
        and  pd.PRODUCT_ID in (select PRODUCT_ID from  pim_exp_bm.PIM_AB_O5_SKU_ATTR_DATA@pim_read WHERE (ADD_DT >= (select last_run_on from JOB_STATUS where process_name='SFCC_LOAD') OR MODIFY_DT >= (select last_run_on from JOB_STATUS where process_name='SFCC_LOAD')  )
-- where skn_no in (select skn from BAY_DS.bi_sku_inventory i where i.skn=sa.SKN_NO and i.qty >0) --98103
)
        and pd.UPC=ps.UPC(+)
        --and ps.PRDUCT_CODE is null
        --and pd.product_id in ('0400093552329','0400093571631','0400091183658')
        order by UPC
              ;

    TYPE v_typ IS
        TABLE OF cur%rowtype;
    v_coll     v_typ;
    v_svs      VARCHAR2(4000) := '';
    v_count    NUMBER(20) := 0;
    err_code   NUMBER(20);
    err_msg    VARCHAR2(4000);
    v_run_id NUMBER(20);
    v_err_cnt NUMBER;
   bi_product_failure EXCEPTION;
   v_curr_atr VARCHAR2(100) :=' ';
   v_atr_chg VARCHAR2(1):='F';
   v_col_nm VARCHAR2(30);
   TYPE v_nm_val_typ IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(30);
   v_coll_nm_val_typ v_nm_val_typ;
   l_idx VARCHAR2(30);
   V_COL_LIST CLOB;
   V_VAL_LIST CLOB;
   v_alt_sql VARCHAR2(4000);
   v_ins_sql CLOB;
   v_curr_upc VARCHAR2(20):=' ';
   v_curr_prd VARCHAR2(20):=' ';
v_curr_upc_sf VARCHAR2(20):=' ';
   v_prd_CHG VARCHAR2(1):='F';
   v_upc_sf  VARCHAR2(20);
   v_col_name VARCHAR2(30);
   v_upd_set_lst CLOB;
   v_col_val CLOB;
      v_upd_sql CLOB;
BEGIN
    OPEN cur;
    LOOP
        FETCH cur BULK COLLECT INTO v_coll LIMIT 50000;
        BEGIN
            IF v_coll.count = 0
            THEN
                V_COL_LIST:=' ';
                 V_VAL_LIST:=' ';
                 v_upd_set_lst:=' ';
              IF v_coll_nm_val_typ.count>0
                 THEN
                    l_idx := v_coll_nm_val_typ.FIRST;
                    LOOP
                      EXIT WHEN l_idx IS NULL;
                     -- dbms_output.put_line (V_COL_LIST);
                     v_col_name:=regexp_replace(l_idx, '[[:space:]]{1,}','_');
                      v_col_val:=replace(v_coll_nm_val_typ(l_idx),'''','''''');
                      V_COL_LIST:=V_COL_LIST||','||v_col_name ;
                      V_VAL_LIST:=trim(V_VAL_LIST)||''','''||v_col_val;
                      v_upd_set_lst:= v_upd_set_lst|| v_col_name||' = '''||v_col_val||''',';
                     -- dbms_output.put_line (v_coll_nm_val_typ(l_idx));
                      l_idx := v_coll_nm_val_typ.NEXT(l_idx);
                    END LOOP;

                    V_VAL_LIST:='('''||v_curr_upc||''','''||v_curr_prd||V_VAL_LIST||''',SYSDATE)';
                    V_COL_LIST:='( UPC '||', PRODUCT_ID '||V_COL_LIST||',PIM_CHG_DT)';
                    v_upd_set_lst:=SUBSTR(v_upd_set_lst,1,length(v_upd_set_lst)-1);
                    IF v_curr_upc_sf IS NULL
                    THEN
                        v_ins_sql:= 'INSERT INTO O5.SFCC_PROD_SKU_DYN_FLAGS '||V_COL_LIST||' VALUES '|| V_VAL_LIST;
                       -- dbms_output.put_line (v_ins_sql);
                        execute immediate v_ins_sql;
                        --COMMIT;
                     ELSE
                        v_upd_sql:= 'UPDATE  O5.SFCC_PROD_SKU_DYN_FLAGS SET '||v_upd_set_lst||' ,PIM_CHG_DT=SYSDATE , PRODUCT_ID='||v_curr_prd||' WHERE  UPC ='''|| v_curr_upc||'''';
                       -- dbms_output.put_line (v_upd_sql);
                        execute immediate v_upd_sql;
                        --COMMIT;
                    END IF;
                END IF;
                COMMIT;
            EXIT WHEN v_coll.count = 0;
            END IF;
            FOR indx IN v_coll.first..v_coll.last
            LOOP
	      BEGIN
              v_upc_sf:=v_coll(indx).upc_sf;
             if v_curr_atr=v_coll(indx).attribute_name
             THEN
                v_atr_chg:='F';

             ELSE
                v_atr_chg:='T';
                v_curr_atr:=v_coll(indx).attribute_name;
                v_col_name:=regexp_replace(v_coll(indx).attribute_name, '[[:space:]]{1,}','_');
                  BEGIN
                 -- dbms_output.put_line (v_col_name);
        --         select column_name into v_col_nm FROM all_tab_cols where table_name='PIM_ATR_SFCC' and column_name=upper( v_col_name);
          --       EXCEPTION
            --     WHEN NO_DATA_FOUND THEN
              --    v_alt_sql:= 'ALTER TABLE PIM_ATR_SFCC ADD '||v_col_name||' VARCHAR2(4000) ';
                  dbms_output.put_line (v_alt_sql);
                --   execute immediate v_alt_sql;
                  --dbms_output.put_line (v_alt_sql);
                 END;




             END IF;
             

              IF v_curr_upc=v_coll(indx).UPC
              THEN
                 v_prd_CHG:='F';

                 v_coll_nm_val_typ(v_coll(indx).attribute_name):= v_coll(indx).ATTRIBUTE_VAL;
              ELSE
                 v_prd_CHG:='T';
                    V_COL_LIST:=' ';
                 V_VAL_LIST:=' ';
                 v_upd_set_lst:=' ';
                  IF v_coll_nm_val_typ.count>0
                 THEN
                    l_idx := v_coll_nm_val_typ.FIRST;
                    LOOP
                      EXIT WHEN l_idx IS NULL;
                      --dbms_output.put_line (v_ins_sql);
                      v_col_name:=regexp_replace(l_idx, '[[:space:]]{1,}','_');
                      v_col_val:=replace(v_coll_nm_val_typ(l_idx),'''','''''');
                      V_COL_LIST:=V_COL_LIST||','||v_col_name;
                      V_VAL_LIST:=trim(V_VAL_LIST)||''','''||v_col_val;
                      v_upd_set_lst:= v_upd_set_lst|| v_col_name||' = '''||v_col_val||''',';
                      --dbms_output.put_line (v_coll_nm_val_typ(l_idx));
                      l_idx := v_coll_nm_val_typ.NEXT(l_idx);
                    END LOOP;

                    V_VAL_LIST:='('''||v_curr_upc||''','''||v_curr_prd||V_VAL_LIST||''',SYSDATE)';
                    V_COL_LIST:='( UPC '||', PRODUCT_ID '||V_COL_LIST||',PIM_CHG_DT)';
                    v_upd_set_lst:=SUBSTR(v_upd_set_lst,1,length(v_upd_set_lst)-1);
                    IF v_curr_upc_sf IS NULL
                    THEN
                        v_ins_sql:= 'INSERT INTO O5.SFCC_PROD_SKU_DYN_FLAGS '||V_COL_LIST||' VALUES '|| V_VAL_LIST;
                       --  dbms_output.put_line (v_ins_sql||';');
                        execute immediate v_ins_sql;
                            COMMIT;
                       ELSE
                        v_upd_sql:= 'UPDATE  O5.SFCC_PROD_SKU_DYN_FLAGS SET '||v_upd_set_lst||' ,PIM_CHG_DT=SYSDATE , PRODUCT_ID='||v_curr_prd||' WHERE  UPC ='''|| v_curr_upc||'''';
                       --  dbms_output.put_line (v_upd_sql);
                        execute immediate v_upd_sql;
                            COMMIT;
                    END IF;
                END IF;
                v_coll_nm_val_typ.delete();
              v_coll_nm_val_typ(v_coll(indx).attribute_name):= v_coll(indx).ATTRIBUTE_VAL;
               v_curr_upc:=v_coll(indx).UPC;
               v_curr_prd:=v_coll(indx).PRODUCT_ID;
                v_curr_upc_sf:=v_coll(indx).upc_sf;
              END IF;

             EXCEPTION
            WHEN OTHERS THEN

            dbms_output.put_line ('exception occured for '||v_coll(indx).PRODUCT_ID);
	    RAISE;
            END;

            END LOOP;
                  COMMIT;

         END;
      END LOOP;
END;
/



exec dbms_stats.gather_table_stats('O5','SFCC_PROD_SKU_DYN_FLAGS');
    exit;
