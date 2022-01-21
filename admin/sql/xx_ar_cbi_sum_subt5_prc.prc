CREATE OR REPLACE PROCEDURE xx_ar_cbi_sum_subt5 
                                                (
                                                  p_sort_list   IN VARCHAR2
                                                 ,p_customer_id IN NUMBER
                                                 ,p_cons_inv_id IN NUMBER
                                                 ,p_report_type IN VARCHAR2                                                 
                                                ) AS
 lv_sql_stmnt1   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt2   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt3   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt4   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt5   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt6   VARCHAR2(10000) :=TO_CHAR(NULL);      
 lv_sql_stmnt7   VARCHAR2(10000) :=TO_CHAR(NULL); 
 lv_sql_stmnt8   VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt9   VARCHAR2(10000) :=TO_CHAR(NULL);  
 lv_sql_stmnt10  VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt11  VARCHAR2(10000) :=TO_CHAR(NULL);  
 lv_sql_stmnt12  VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt13  VARCHAR2(10000) :=TO_CHAR(NULL);
 lv_sql_stmnt14  VARCHAR2(10000) :=TO_CHAR(NULL);   
 lv_sql_stmnt99  VARCHAR2(10000) :=TO_CHAR(NULL); 
 lv_first_field  VARCHAR2(2)     :=TO_CHAR(NULL);
 lv_second_field VARCHAR2(2)     :=TO_CHAR(NULL);
 lv_third_field  VARCHAR2(2)     :=TO_CHAR(NULL);
 lv_fourth_field VARCHAR2(2)     :=TO_CHAR(NULL);   
 lv_enter        VARCHAR2(1) :='
'; 
 lv_col         VARCHAR2(2);  
 
 col1           VARCHAR2(80);
 col2       NUMBER;
 source_cur INTEGER;
 target_cur INTEGER;
 exec_stmnt INTEGER;
 n_col1_seq NUMBER :=1; 
 
FUNCTION get_sort_tags(p_tag IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
 IF p_tag ='B1' THEN
  RETURN 'Customer :';
 ELSIF p_tag ='U1' THEN
  RETURN 'PO :';
 ELSIF p_tag ='D1' THEN
  RETURN 'Cost Center :';
 ELSIF p_tag ='L1' THEN
  RETURN 'Desktop :';
 ELSIF p_tag ='R1' THEN
  RETURN 'Release :';
 ELSIF p_tag ='S1' THEN
  RETURN 'Ship To :';
 ELSE
  RETURN NULL;
 END IF; 
EXCEPTION
 WHEN OTHERS THEN
  RETURN NULL;
END get_sort_tags;
 
begin
 lv_col :=SUBSTR(p_sort_list ,9 ,2);
 lv_first_field :=lv_col;
 lv_sql_stmnt2 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              ||lv_enter
              ||' AND '||lv_col||' IS NOT NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||lv_enter
              ||'ORDER BY '||lv_col;                          
              
 lv_sql_stmnt1 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              ||lv_enter
              ||' AND '||lv_col||' IS NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||lv_enter              
              ||'ORDER BY '||lv_col;               
              
  -- ================   
  -- First Insert for the fifth field in the sort order where the value is blank...
  -- ================  
BEGIN
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt1, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('First insert for two subtotals :'||SQLERRM);
END;                    

  -- ================   
  -- Second Insert for the fifth field in the sort order where the value is not blank...
  -- ================  
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt2, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;
                       
 --dbms_output.put_line('Stmnt1 :'||lv_enter||lv_sql_stmnt1);  
 --dbms_output.put_line('Stmnt2 :'||lv_enter||lv_sql_stmnt2);
 
 lv_sql_stmnt2 :='AND  '
              ||lv_enter
              ||lv_col||' IN '
              ||'('
              ||lv_enter
              ||'SELECT  '||lv_col
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
             -- ||lv_enter
             -- ||' AND '||lv_col||' IS NOT NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||')'; 
              
 --dbms_output.put_line('Stmnt2 -Modified :'||lv_enter||lv_sql_stmnt2);
 
lv_col :=SUBSTR(p_sort_list ,7 ,2);
lv_second_field :=lv_col;
  -- ================   
  -- First Insert for the fourth field in the sort order where the value is blank...
  -- ================  
 lv_sql_stmnt5 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              ||lv_enter
              ||' AND '||lv_col||' IS NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||lv_enter              
              ||'ORDER BY '||lv_col;  
BEGIN
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt5, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('First insert for two subtotals :'||SQLERRM);
END;                    

/* 
   lv_sql_stmnt99 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL AND '||lv_first_field||' IS NULL ' 
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;
                 
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt99, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;                 
*/ 
  -- ================   
  -- Second Insert for the fourth field in the sort order where the value is not blank...
  -- ================  

   lv_sql_stmnt6 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL ' 
                 ||lv_enter
                 ||lv_sql_stmnt2                
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;  
  
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt6, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;  

 lv_sql_stmnt6 :='AND  '
              ||lv_enter
              ||lv_col||' IN '
              ||'('
              ||lv_enter
              ||'SELECT  '||lv_col
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              --||lv_enter
              --||' AND '||lv_col||' IS NOT NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||')'; 
 
lv_col :=SUBSTR(p_sort_list ,5 ,2);
lv_third_field :=lv_col;
  -- ================   
  -- First Insert for the second field in the sort order where the value is blank...
  -- ================  
 lv_sql_stmnt7 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              ||lv_enter
              ||' AND '||lv_col||' IS NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||lv_enter              
              ||'ORDER BY '||lv_col;  
BEGIN
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt7, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('First insert for two subtotals :'||SQLERRM);
END;                    
 /* 
   lv_sql_stmnt99 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL AND '||lv_second_field||' IS NULL ' 
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;

BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt99, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;
 */ 
  -- ================   
  -- Second Insert for the second field in the sort order where the value is not blank...
  -- ================  

   lv_sql_stmnt8 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL ' 
                 ||lv_enter
                 ||lv_sql_stmnt6                
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;  
  
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt8, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;

 lv_sql_stmnt8 :='AND  '
              ||lv_enter
              ||lv_col||' IN '
              ||'('
              ||lv_enter
              ||'SELECT  '||lv_col
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              --||lv_enter
              --||' AND '||lv_col||' IS NOT NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||')';               
              
lv_col :=SUBSTR(p_sort_list ,3 ,2);
lv_fourth_field :=lv_col;
  -- ================   
  -- First Insert for the second field in the sort order where the value is blank...
  -- ================  
 lv_sql_stmnt12 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              ||lv_enter
              ||' AND '||lv_col||' IS NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||lv_enter              
              ||'ORDER BY '||lv_col;  
BEGIN
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt12, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('First insert for two subtotals :'||SQLERRM);
END;                    
/* 
   lv_sql_stmnt99 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL AND '||lv_third_field||' IS NULL ' 
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;

BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt99, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;
 */ 
  -- ================   
  -- Second Insert for the second field in the sort order where the value is not blank...
  -- ================  

   lv_sql_stmnt13 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL ' 
                 ||lv_enter
                 ||lv_sql_stmnt8                
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;  
  
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt8, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;

 lv_sql_stmnt13 :='AND  '
              ||lv_enter
              ||lv_col||' IN '
              ||'('
              ||lv_enter
              ||'SELECT  '||lv_col
              ||lv_enter
              ||'FROM xx_ar_cbi_softheaders_hdr_v '
              ||lv_enter
              ||'WHERE cons_inv_id ='||p_cons_inv_id
              --||lv_enter
              --||' AND '||lv_col||' IS NOT NULL '                 
              ||lv_enter              
              ||'GROUP  BY '||lv_col
              ||')';


 IF SUBSTR(p_sort_list ,1 ,2) !='B1' THEN 
   lv_col :=SUBSTR(p_sort_list ,1 ,2);
   
   lv_sql_stmnt3 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NULL '
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;
                 
  -- ================   
  -- First Insert for the first field in the sort order where the value is blank...
  -- ================  
BEGIN
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt3, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('First insert for two subtotals :'||SQLERRM);
END;    
 /* 
   lv_sql_stmnt99 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL AND '||lv_fourth_field||' IS NULL ' 
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;

BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt99, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;             
 */     
   lv_sql_stmnt4 :='SELECT  '||lv_col||', SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||lv_enter
                 ||'WHERE cons_inv_id ='||p_cons_inv_id
                 ||lv_enter
                 ||' AND '||lv_col||' IS NOT NULL ' 
                 ||lv_enter
                 ||lv_sql_stmnt13                
                 ||lv_enter
                 ||'GROUP  BY '||lv_col
                 ||lv_enter              
                 ||'ORDER BY '||lv_col;

  -- ================   
  -- Second Insert for the first field in the sort order where the value is not blank...
  -- ================  
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt4, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col1 ,80);
  dbms_sql.define_column(source_cur, 2, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col1);
        dbms_sql.column_value(source_cur, 2, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags(lv_col)||col1||'');
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;
                 
 ELSE
   lv_sql_stmnt14 :='SELECT SUM(TOTAL_AMOUNT) TOTAL_AMOUNT'
                 ||lv_enter
                 ||'FROM xx_ar_cbi_softheaders_hdr_v '
                 ||'WHERE cons_inv_id ='||p_cons_inv_id;
                 
BEGIN  
  source_cur := dbms_sql.open_cursor;
  dbms_sql.parse(source_cur, lv_sql_stmnt14, dbms_sql.NATIVE);  
  dbms_sql.define_column(source_cur, 1, col2);
  exec_stmnt := dbms_sql.execute(source_cur);
  target_cur := dbms_sql.open_cursor;
  dbms_sql.parse
   ( target_cur
    ,'INSERT INTO XX_AR_CBI_SORT(RPT_TYPE ,CUSTOMER_ID ,CONS_INV_ID ,TRX_ID ,SUBTOT_DESC ,SUBTOT_AMOUNT) VALUES
    (:c_bind_rpt_type ,:n_bind_cust_id ,:n_cons_inv_id ,:n_bind_trx_id ,:c_bind_subtot_desc ,:n_bind_subtot_amt)'
    ,dbms_sql.NATIVE  
   );
    LOOP
      -- Fetch a row from the source table...
      IF dbms_sql.fetch_rows(source_cur) > 0 THEN
        -- get column values of the row 
        dbms_sql.column_value(source_cur, 1, col2);
        -- bind in the values to be inserted...
        dbms_sql.bind_variable(target_cur, ':c_bind_rpt_type'    ,p_report_type);        
        dbms_sql.bind_variable(target_cur, ':n_bind_cust_id'     ,p_customer_id);
        dbms_sql.bind_variable(target_cur, ':n_cons_inv_id'      ,p_cons_inv_id);        
        dbms_sql.bind_variable(target_cur, ':n_bind_trx_id'      ,n_col1_seq);
        dbms_sql.bind_variable(target_cur, ':c_bind_subtot_desc' ,'Subtotal '||get_sort_tags('B1'));
        dbms_sql.bind_variable(target_cur, ':n_bind_subtot_amt'  ,col2);
        exec_stmnt := dbms_sql.execute(target_cur);
        n_col1_seq :=n_col1_seq+1;
      ELSE
        -- No more rows to insert... 
        EXIT;
      END IF;
    END LOOP;
  COMMIT;
  dbms_sql.close_cursor(source_cur);
  dbms_sql.close_cursor(target_cur);
EXCEPTION
  WHEN OTHERS THEN
    IF dbms_sql.is_open(source_cur) THEN
      dbms_sql.close_cursor(source_cur);
    END IF; 
    IF dbms_sql.is_open(target_cur) THEN
      dbms_sql.close_cursor(target_cur);
    END IF;
   --DBMS_OUTPUT.PUT_LINE('Second insert for two subtotals :'||SQLERRM);
END;                 
 END IF;    
           
 --dbms_output.put_line('Stmnt3 :'||lv_enter||lv_sql_stmnt3);  
 --dbms_output.put_line('Stmnt4 :'||lv_enter||lv_sql_stmnt4); 
 --dbms_output.put_line('Stmnt5 :'||lv_enter||lv_sql_stmnt5); 
 commit work;           
exception
 when others then
  dbms_output.put_line('Outer Block...'||SQLERRM);
end;
/