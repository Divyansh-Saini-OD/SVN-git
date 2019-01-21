SET linesize 10000;
--spool c:\oracle\ora92\bin\pospay;

DECLARE
   CURSOR c_bank_cur
   IS
      SELECT DISTINCT aba.bank_account_num, aba.currency_code
FROM ap_bank_accounts_all aba, ap_bank_branches abb
WHERE 1 = 1
AND aba.bank_branch_id = abb.bank_branch_id
AND abb.bank_name LIKE 'The Bank of Nova Scotia%';
        

   CURSOR c_pospay (p_bank_account_num VARCHAR2)
   IS
      SELECT RPAD (abb.bank_num, 9) bank_num, aba.bank_account_num,
             ac.check_number, ac.amount, ac.address_line1, ac.address_line2,
             ac.address_line3, ac.city, ac.country, ac.zip, ac.state,
             TO_CHAR (TRUNC (ac.check_date), 'rrrrmmdd') check_date,
             RPAD (ac.vendor_name, 50) vendor_name,
             po.segment1 vendor_number,
             DECODE (ac.status_lookup_code,
                     'NEGOTIABLE', 'ISSUED',
                     ac.status_lookup_code
                    ) status_lookup_code,
             ac.currency_code
        FROM ap_checks_all ac,
             ap_check_stocks_all acs,
             ap_bank_accounts_all aba,
             ap_bank_branches abb,
             po_vendors po
       WHERE 1 = 1
         AND ac.payment_method_lookup_code = 'CHECK'
         AND ac.check_stock_id = acs.check_stock_id
         AND acs.bank_account_id = aba.bank_account_id
         AND aba.bank_branch_id = abb.bank_branch_id
         AND ac.vendor_id = po.vendor_id
         AND ac.positive_pay_status_code = 'UNSENT'
         AND aba.bank_account_num = p_bank_account_num;

   v_date               VARCHAR2 (10) := TO_CHAR (TRUNC (SYSDATE), 'rrrrmmdd');
   v_issued             NUMBER         := 0;
   v_void               NUMBER         := 0;
   v_void_amount        NUMBER         := 0;
   v_bank_account_num   VARCHAR2 (25);
   v_currency_code      VARCHAR2 (3);
   v_issued_amount      NUMBER         := 0;
   v_bank_num           VARCHAR2 (50);
   v_check_date         VARCHAR2 (12);
   v_vendor_name        VARCHAR2 (50);
   v_address_line1      VARCHAR2 (100);
   v_address_line2      VARCHAR2 (100);
   v_city               VARCHAR2 (20);
   v_state              VARCHAR2 (20);
   v_country            VARCHAR2 (20);
   v_zip                VARCHAR2 (20);
   v_path               VARCHAR2 (100)	  := 'XXFIN_OUTBOUND';
   v_filename           VARCHAR2(200)     := 'pospay_scotia.rtf';
   v_output_file  	utl_file.file_type;
   v_line               VARCHAR2(5000);
   v_customer_number    VARCHAR2(20):= '8000255770';
   v_transit_number     VARCHAR2(10):= '80002';

  BEGIN
        DBMS_OUTPUT.ENABLE (1000000);
        v_output_file := utl_file.fopen (v_path,v_filename, 'W');
   FOR v_bank_cur IN c_bank_cur
   LOOP
      v_bank_account_num := v_bank_cur.bank_account_num;
      --dbms_output.put_line('The Bank Account Num being passed is :'||'  '||v_bank_account_num);
      v_currency_code := v_bank_cur.currency_code;
      

  --exception
  --  when others then null;

      v_line  :=    'A'     || v_customer_number
                            || v_transit_number 
                            || '0002'
                            || '       '
                            || LPAD(v_bank_account_num,7,'0')
                            || v_currency_code
                            || 'CA'
                            || '000000000000000000000000000000'
                            || v_date
                            || 'ISSUED'
                            || '00000000'
                            || '       BNS'
                            || ' ' 
			;
                          
        

    	utl_file.put_line (v_output_file, v_line);
    	
    

      FOR v_pospay IN c_pospay (v_bank_account_num)
      LOOP
         v_bank_num := v_pospay.bank_num;
         v_check_date := v_pospay.check_date;
         v_vendor_name := v_pospay.vendor_name;
         v_address_line1 := v_pospay.address_line1;
         v_address_line2 := v_pospay.address_line2;
         v_city := v_pospay.city;
         v_state := v_pospay.state;
         v_country := v_pospay.country;
         v_zip := v_pospay.zip;
         --dbms_output.put_line('The Bank Account Num being passed is :'||'  '||v_bank_account_num);
         v_line  := 
               'J'
             || v_transit_number
             || '0002'
             || '       '
             || LPAD(v_bank_account_num,7,'0')
             || LPAD (v_bank_num, 14, '0')
             || LPAD (v_pospay.amount, 10, '0')
             || RPAD (v_pospay.status_lookup_code, 12, '')
             || v_check_date
             || '                              '
             || '                              '
             || '                                 '
             || RPAD (v_vendor_name, 60, '')
             || '                                                            '
             || '                                                            '
             || RPAD (v_address_line1, 60, '')
             || RPAD (v_address_line2, 60, '')
             || '                                                            '
             || RPAD (v_city, 60, '')
             || RPAD (v_state, 60, '')
             || RPAD (v_country, 60, '')
             || RPAD (v_zip, 60, '')
            ;
         utl_file.put_line (v_output_file, v_line);

         IF v_pospay.status_lookup_code IN
               ('NEGOTIABLE',
                'CLEARED',
                'ISSUED',
                'CLEARED BUT UNACCOUNTED',
                'RECONCILED',
                'RECONCILED UNACCOUNTED'
               )
         THEN
            v_issued := v_issued + 1;
            v_issued_amount := v_issued_amount + v_pospay.amount;
         END IF;

         IF v_pospay.status_lookup_code IN
                                    ('VOID', 'SPOILED', 'SET UP', 'OVERFLOW')
         THEN
            v_void := v_void + 1;
            v_void_amount := v_void_amount + v_pospay.amount;
         END IF;
      END LOOP;

      UPDATE ap_checks_all
         SET positive_pay_status_code =
                DECODE (status_lookup_code,
                        'NEGOTIABLE', 'SENT AS NEGOTIABLE',
                        'ISSUED', 'SENT AS NEGOTIABLE',
                        'CLEARED', 'SENT AS NEGOTIABLE',
                        'CLEARED BUT UNACCOUNTED', 'SENT AS NEGOTIABLE',
                        'RECONCILED', 'SENT AS NEGOTIABLE',
                        'RECONCILED UNACCOUNTED', 'SENT AS NEGOTIABLE',
                        'VOIDED', 'SENT AS VOIDED',
                        'SPOILED', 'SENT AS VOIDED',
                        'SET UP', 'SENT AS VOIDED',
                        'OVERFLOW', 'SENT AS VOIDED'
                       )
       WHERE check_id IN (
                SELECT ac1.check_id
                  FROM ap_checks_all ac1,
                       ap_check_stocks_all acs,
                       ap_bank_accounts_all aba,
                       ap_bank_branches abb
                 WHERE 1 = 1
                   AND ac1.check_stock_id = acs.check_stock_id
                   AND acs.bank_account_id = aba.bank_account_id
                   AND aba.bank_branch_id = abb.bank_branch_id
                   AND ac1.payment_method_lookup_code = 'CHECK');

      v_line  :=    'Z'     || '                      '
                            || LPAD (v_issued, 8, '0')
                            || NVL (LPAD (v_issued_amount, 14, '0'),
                                    '00000000000000'
                                   )
                            || NVL (LPAD (v_void, 8, '0'), '00000000')
                            || NVL (LPAD (v_void_amount, 14, '0'),
                                    '00000000000000'
                                   )
                            || '0000000000000000000000'
                            || '  '
                           ;
      utl_file.put_line (v_output_file, v_line);
   END LOOP;
   utl_file.fclose(v_output_file);
END;