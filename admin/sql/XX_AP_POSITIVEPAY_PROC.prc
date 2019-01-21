create or replace
PROCEDURE XX_AP_POSITIVEPAY_PROC( errbuf OUT VARCHAR2
                                                   ,retcode OUT NUMBER
                                                   ,p_bank_name VARCHAR2
                                                   ,p_days      NUMBER
                                                   ,p_path      VARCHAR2
                                                   ,p_scot_filename  VARCHAR2
                                                   ,p_wach_filename  VARCHAR2
                                                   ,p_customer_number NUMBER
                                                   ,p_transit_number  NUMBER -- Parameter not used per defect 15580
                                                  ) 
IS                                 
-- +============================================================================+
-- |                   Office Depot Project Simplify                            |
-- |                                                                            |
-- +============================================================================+
-- |Name        : AP Positive Pay Program                                       |
-- |Rice Id     : I0228                                                         |  
-- |Change record                                                               |
-- |================                                                            |
-- |version       Date            Author                Remarks                 |
-- |========      ======         ==========             =======                 |
-- | Draft        15-FEB-2007    Shankar Murthy         Initial Version         |
-- |                                                                            | 
-- | 1.0          19-OCT-2007    Mohan                  Fix defect 2459         |
-- |                             Wipro Technologies                             |
-- |                                                                            |
-- | 1.1          19-OCT-2007    Raji                                           |
-- |                             Wipro Technologies                             |
-- | 1.2          18-FEB-2008    Sandeep Pandhare       Defect 4741             |
-- | 1.3          25-FEB-2008    Sandeep Pandhare       Defect 4972             |         
-- | 1.4          18-JUN-2008    Sandeep Pandhare       Defect 8204             |
-- | 1.5          10-JUL-2008    Sandeep Pandhare       Defect 8892             |
-- | 1.6          29-MAY-2009    Peter Marco            Defect 15580            |
-- |                                                    Removed transit number  |
-- |                                                    from parameter and mod- |
-- |                                                    ified account number    |
-- | 1.7          07-JUL-2009    Peter Marco            defect Prd 576          |
-- +============================================================================+
-- +============================================================================+
-- | Parameters:  x_err_buf, x_ret_code,p_bank_name,p_days                      | 
-- |              ,p_path,p_scot_filename,p_wach_filename,                      |
-- |               p_customer_number,p_transit_number                           |
-- |                                                                            |
-- | Returns   : Error Message,Error Code                                       |
-- +============================================================================+

 ln_req_id NUMBER;
 lf_utl_file_handle     UTL_FILE.file_type;
 

BEGIN

 IF UPPER(P_BANK_NAME) LIKE '%SCOTIA%'  THEN
   
DECLARE
---Cursor to fetch the bank details
CURSOR c_bank_cur
 IS
        SELECT DISTINCT ABA.bank_account_id
              ,ABB.bank_num
              ,substr(ABA.bank_account_num,5,5) transit_num         -- Added per defect 15580
            --,ABA.bank_account_num                                    removed per defect 15580
              ,substr(ABA.bank_account_num,15,7) bank_account_num   -- Modified substr function per defect 15580
              ,ABA.currency_code
   FROM        ap_bank_accounts_all ABA
              ,ap_bank_branches ABB
   WHERE 1 = 1
   AND ABA.bank_branch_id = ABB.bank_branch_id
--   AND ABB.bank_name = p_bank_name;
  AND upper(ABB.bank_name) like  '%SCOTIA%';
   
-- DEFECT 4972 Removed the check date parameters so future dated checks are also processed.
   CURSOR c_pospay (p_bank_account_num VARCHAR2)
   IS
      SELECT RPAD(ABB.bank_num, 9) bank_num
            --,ABA.bank_account_num                               removed per defect 15580
            ,substr(ABA.bank_account_num,15,7) bank_acct_num  -- Added per defect 15580
            ,AC.check_number
            ,AC.amount
            ,AC.address_line1
            ,AC.address_line2
            ,AC.address_line3
            ,AC.city, DECODE(ac.country,'CA','CANADA','US','UNITED STATES', AC.country) country -- Added for Defect 2459
            ,AC.zip
            ,AC.state
            ,TO_CHAR (TRUNC (AC.check_date), 'RRRRMMDD') check_date
            ,RPAD (AC.vendor_name, 50) vendor_name
            ,PO.segment1 vendor_number
            ,DECODE (AC.status_lookup_code,'NEGOTIABLE'
                     ,'ISSUED','VOIDED','VOID',AC.status_lookup_code
                    ) status_lookup_code                                      -- Added for Defect 2459
            ,AC.currency_code
        FROM ap_checks_all AC,
             ap_check_stocks_all ACS,
             ap_bank_accounts_all ABA,
             ap_bank_branches ABB,
             po_vendors PO
        WHERE 1 = 1
        AND AC.payment_method_lookup_code = 'CHECK'
        AND AC.check_stock_id = ACS.check_stock_id
        AND ACS.bank_account_id = ABA.bank_account_id
        AND ABA.bank_branch_id = ABB.bank_branch_id
        AND AC.vendor_id = PO.vendor_id
-- defect 4972    AND AC.check_date BETWEEN (SYSDATE-p_days) AND (SYSDATE) -- Added for Defect 2459 , by mohan 10/19/2007
         -- AND ac.positive_pay_status_code = 'UNSENT'
         -- Added for Defect 2459 , by mohan 10/19/2007
        AND( ( AC.positive_pay_status_code = 'UNSENT' )
               OR
              (AC.status_lookup_code = 'VOIDED' ) AND  ( AC.positive_pay_status_code ='SENT AS NEGOTIABLE')
            )
        AND   AC.status_lookup_code   <> 'RECONCILED'               -- added per defect Prd 576
        AND   AC.status_lookup_code   <> 'RECONCILED UNACCOUNTED'   -- added per defect Prd 576
        -- AND ABA.bank_account_num = p_bank_account_num            Removed per defect 15580
        AND substr(ABA.bank_account_num,15,7) = p_bank_account_num;  -- Added per defect 15580

   ld_date               VARCHAR2 (10)  := TO_CHAR (TRUNC (SYSDATE), 'RRRRMMDD');
   ln_issued             NUMBER         := 0;
   ln_void               NUMBER         := 0;
   ln_void_amount        NUMBER         := 0;
   lc_bank_account_num   VARCHAR2 (25);
   lc_currency_code      VARCHAR2 (3);
   ln_issued_amount      NUMBER         := 0;
   lc_bank_num           VARCHAR2 (50);
   lc_check_date         VARCHAR2 (12)  := '';
   lc_vendor_name        ap_checks_all.vendor_name%TYPE;  -- Defect 8204
   lc_address_line1      ap_checks_all.address_line1%TYPE; -- Defect 8204
   lc_address_line2      ap_checks_all.address_line2%TYPE; -- Defect 8204
   lc_city               ap_checks_all.city%TYPE; -- Defect 8204
   lc_state              ap_checks_all.state%TYPE; -- Defect 8204
   lc_country            ap_checks_all.country%TYPE; -- Defect 8204
   lc_zip                ap_checks_all.zip%TYPE;  -- Defect 8204
   -- v_path               VARCHAR2 (100) := 'XXFIN_OUTBOUND';
   lc_filename           VARCHAR2(200); -- := 'pospay_scotia_'||FND_GLOBAL.CONC_REQUEST_ID||'.txt';
   ln_conc_req_id        NUMBER           := FND_GLOBAL.CONC_REQUEST_ID;   
   lc_line               VARCHAR2(5000);
   -- v_customer_number    VARCHAR2(20)   := '8000255770';
   --v_transit_number     VARCHAR2(10)   := '80002';
   lc_check_number       VARCHAR2(50);
   lc_void_status        VARCHAR2(1)    := ' ';
   lc_prev_bnk_acc       ap_bank_accounts_all.bank_account_num%type := '00';
   lc_file_created       CHAR(1)        := 'N';
   
  BEGIN
    DBMS_OUTPUT.ENABLE (1000000);        
    FOR lcu_bank_cur IN c_bank_cur
    LOOP
    
    lc_filename := p_scot_filename||ln_conc_req_id||'.txt';
    
      lc_bank_account_num := lcu_bank_cur.bank_account_num;
      lc_currency_code := lcu_bank_cur.currency_code;
--      FND_FILE.PUT_LINE (fnd_file.log, 'Scotia Loop:' || ' ' || lc_bank_account_num 
--      || ' ' || lcu_bank_cur.currency_code);
      
    FOR lcu_pospay IN c_pospay (lc_bank_account_num)
    LOOP      
 
--       FND_FILE.PUT_LINE (fnd_file.log, 'S PosPay Loop: Name ' || lcu_pospay.vendor_name
--       || ' ' || lcu_pospay.check_number || ' ' || lcu_pospay.check_date );
    
      EXIT WHEN c_pospay%NOTFOUND; 

      IF lc_file_created = 'N' THEN
        lf_utl_file_handle := utl_file.fopen (p_path,lc_filename, 'W');
        lc_file_created := 'Y';
      END IF;

      IF lc_prev_bnk_acc <> lc_bank_account_num THEN
      
        lc_line  :=    'A'    || p_customer_number
                           --   || p_transit_number               removed for defect 15580
                              || lcu_bank_cur.transit_num       --Added Defect 15580
                              || '0002'
                              || '       '
                              || LPAD(lc_bank_account_num,7,'0')   
                              || lc_currency_code
                              || 'CA'
                              || '000000000000000000000000000000'
                              || ld_date
                              || 'ISSUED  '
                              || '        '
                              || 'BNS       '
                              || ' ';

          UTL_FILE.PUT_LINE (lf_utl_file_handle, lc_line);
          FND_FILE.PUT_LINE (fnd_file.output, lc_line);
          lc_prev_bnk_acc := lc_bank_account_num;
          
      END IF ;

      lc_bank_num := lcu_pospay.bank_num;
      lc_check_number := lcu_pospay.check_number;
      lc_check_date := lcu_pospay.check_date;
      lc_vendor_name := lcu_pospay.vendor_name;
      lc_address_line1 := lcu_pospay.address_line1;
      lc_address_line2 := lcu_pospay.address_line2;
      lc_city := lcu_pospay.city;
      lc_state := lcu_pospay.state;
      lc_country := lcu_pospay.country;
      lc_zip := lcu_pospay.zip;
 
   --dbms_output.put_line('The Bank Account Num being passed is :'||'  '||lc_bank_account_num);
      lc_line  :=
               'J'
            -- || p_transit_number                          removed for defect 15580
             || lcu_bank_cur.transit_num                  --Added Defect 15580
             || '0002'
             || '       '
             || LPAD(lc_bank_account_num,7,'0')   
             || LPAD (lc_check_number, 14, '0')
             || LPAD (lcu_pospay.amount*100, 10, '0')
             || RPAD (lcu_pospay.status_lookup_code, 12,' ')
             || RPAD(lc_check_date,8,' ')
             || '                              '
             || '                              '
             || '                              '
             || lc_currency_code
             || RPAD (lc_vendor_name, 60, ' ')
             || '                                                            '
             || '                                                            '
             || RPAD (lc_address_line1, 60, ' ')
             || RPAD (lc_address_line2, 60, ' ')
             || '                                                            '
             || RPAD (lc_city, 60, ' ')
             || RPAD (lc_state, 60, ' ')
             || RPAD (lc_country, 60, ' ')
             || RPAD (lc_zip, 60, ' ')
            ;
    UTL_FILE.PUT_LINE (lf_utl_file_handle, lc_line);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lc_line);

     IF lcu_pospay.status_lookup_code IN
               ('NEGOTIABLE',
                'CLEARED',
                'ISSUED',
                'CLEARED BUT UNACCOUNTED',
                'RECONCILED',
                'RECONCILED UNACCOUNTED'
               )
     THEN
            ln_issued := ln_issued + 1;
            ln_issued_amount := ln_issued_amount + lcu_pospay.amount;
     END IF;

     IF lcu_pospay.status_lookup_code IN
                                    ('VOID'
                                    ,'SPOILED'
                                    ,'SET UP'
                                    ,'OVERFLOW')
     THEN
         ln_void := ln_void + 1;
         ln_void_amount := ln_void_amount + lcu_pospay.amount;
     END IF;
  END LOOP;

   -- The following update statement is as per the delivered code for this functionality.
   -- It is assumed here that immediately before this is happening during the execution of the custom
   -- positive payee match process, the tables are locked and are not subjected to any dml operations on them.

  BEGIN

--FND_FILE.PUT_LINE (fnd_file.log,' Updates to positive_pay_status_code field in AP_CHECKS_ALL started ....');  

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
                SELECT ACL.check_id
                  FROM ap_checks_all ACL,
                       ap_check_stocks_all ACS,
                       ap_bank_accounts_all ABA,
                       ap_bank_branches ABB
                 WHERE 1 = 1
                 AND ACL.check_stock_id = ACS.check_stock_id
                 AND ACS.bank_account_id = ABA.bank_account_id
                 AND ABA.bank_branch_id = ABB.bank_branch_id
                 AND ACL.payment_method_lookup_code = 'CHECK'
-- defect 4972   AND ACL.check_date BETWEEN (SYSDATE-p_days) AND (SYSDATE) -- Added for Defect 2459 , by mohan 10/19/2007
                   -- AND ac.positive_pay_status_code = 'UNSENT'
      -- Added for Defect 2459 , by mohan 10/19/2007
                 AND( ( ACL.positive_pay_status_code = 'UNSENT' ) OR
                      (ACL.status_lookup_code = 'VOIDED' ) AND  ( ACL.positive_pay_status_code ='SENT AS NEGOTIABLE'))
                -- AND ABA.bank_account_num = lc_bank_account_num);    Removed per Prod Defec 576
                 AND substr(ABA.bank_account_num,15,7) = lc_bank_account_num);  --added per Prod defect 576
   EXCEPTION
   WHEN OTHERS THEN
   ROLLBACK;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, SQLERRM||'Error while Updating Scotia Bank positive_pay_status_code for Account Number  '||lc_bank_account_num );
      
   END;

       IF lc_check_number > 0 
       THEN
          lc_line  :=    'Z'     || '                      '
                            || LPAD (ln_issued, 8, '0')
                            || NVL (LPAD (ln_issued_amount*100, 14, '0'),
                                    '00000000000000'
                                   )
                            || NVL (LPAD (ln_void, 8, '0'), '00000000')
                            || NVL (LPAD (ln_void_amount*100, 14, '0'),
                                    '00000000000000'
                                   )
                            || '0000000000000000000000'
                            || '  '
                           ;
         UTL_FILE.PUT_LINE (lf_utl_file_handle, lc_line);
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lc_line);
      
      END IF;
     lc_check_number  := 0 ;
     ln_issued        := 0 ;
     ln_issued_amount := 0 ;
     ln_void          := 0 ;
     ln_void_amount   := 0 ;
 END LOOP;
 
 IF lc_file_created = 'Y' THEN
   UTL_FILE.FCLOSE(lf_utl_file_handle);
   ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                          ,'XXCOMFILCOPY'
                                          ,''
                                          ,''
                                          ,FALSE
                                          ,'$XXFIN_DATA/outbound/'|| lc_filename
                                          ,'$XXFIN_DATA/ftp/out/positivepay/' || lc_filename  
                                          ,'','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         FND_FILE.PUT_LINE
                         (fnd_file.LOG,
                          'Error submitting request for Positive Pay'
                         );
      END IF;
 END IF;  
     --FND_FILE.PUT_LINE(fnd_file.log,'The Total number of checks issued is:'||ln_issued);
 END ;
 ELSIF UPPER(p_bank_name) LIKE '%WACHOVIA%'
 THEN

DECLARE
---Cursor to fetch the bank details
CURSOR c_bank_cur
 IS
        SELECT DISTINCT ABA.bank_account_id
              ,ABB.bank_num
              ,ABA.bank_account_num                                 
              ,ABA.currency_code
   FROM        ap_bank_accounts_all ABA
              ,ap_bank_branches ABB
   WHERE 1 = 1
   AND ABA.bank_branch_id = ABB.bank_branch_id
--   AND ABB.bank_name = p_bank_name;
  AND upper(ABB.bank_name) like  '%WACHOVIA%';

--     DECLARE
           CURSOR c_pospay (p_bank_account_num VARCHAR2)
           IS
           SELECT RPAD(ABB.bank_num, 9) bank_num
              -- ,ABA.bank_account_num                                 Removed per defect 15580
                 ,substr(ABA.bank_account_num,15,7) bank_account_num   -- Added substr function per defect 15580
                 ,AC.check_number
                 ,AC.amount
                 ,AC.address_line1
                 ,AC.address_line2
                 ,AC.address_line3
                 ,AC.city
                 ,DECODE(AC.country,'CA','CANADA','US','UNITED STATES',AC.country) country -- Added for Defect 2459
                 ,AC.zip
                 ,AC.state
                 ,TO_CHAR (TRUNC (AC.check_date), 'RRRRMMDD') check_date
                 ,RPAD (AC.vendor_name, 50) vendor_name
                 ,PO.segment1 vendor_number
                 ,DECODE (AC.status_lookup_code,'NEGOTIABLE','ISSUED'
                        ,'VOIDED', 'VOID',AC.status_lookup_code) status_lookup_code         -- Added for Defect 2459
                 ,AC.currency_code
          FROM   ap_checks_all AC
                ,ap_check_stocks_all ACS
                ,ap_bank_accounts_all ABA
                ,ap_bank_branches ABB
                ,po_vendors PO
          WHERE 1 = 1
          AND   AC.payment_method_lookup_code = 'CHECK'
          AND   AC.check_stock_id = ACS.check_stock_id
          AND   ACS.bank_account_id = ABA.bank_account_id
          AND   ABA.bank_branch_id = ABB.bank_branch_id
          AND   AC.vendor_id = PO.vendor_id
-- defect 4972   AND   AC.check_date BETWEEN (SYSDATE-p_days) AND (SYSDATE) -- Added for Defect 2459 , by mohan 10/19/2007
         -- Added for Defect 2459 , by mohan 10/19/2007
          AND  (( AC.positive_pay_status_code = 'UNSENT' ) OR
               (AC.status_lookup_code = 'VOIDED' ) AND  ( AC.positive_pay_status_code ='SENT AS NEGOTIABLE'))
          AND   AC.status_lookup_code   <> 'RECONCILED'               -- added per defect Prd 576
          AND   AC.status_lookup_code   <> 'RECONCILED UNACCOUNTED'   -- added per defect Prd 576
          AND ABA.bank_account_num = p_bank_account_num; 

   ld_date               VARCHAR2 (10) := TO_CHAR (TRUNC (SYSDATE), 'RRRRMMDD');
   ln_issued             NUMBER        := 0;
   ln_void               NUMBER        := 0;
   ln_void_amount        NUMBER        := 0;
   lc_bank_account_num   VARCHAR2 (25);
   lc_currency_code      VARCHAR2 (3);
   ln_issued_amount      NUMBER        := 0;
   lc_bank_num           VARCHAR2 (50);
   lc_check_date         VARCHAR2 (12);
/*   lc_vendor_name        VARCHAR2 (50);
   lc_address_line1      VARCHAR2 (100);
   lc_address_line2      VARCHAR2 (100);
   lc_city               VARCHAR2 (20);
   lc_state              VARCHAR2 (20);
   lc_country            VARCHAR2 (20);
   lc_zip                VARCHAR2 (20);  */
   lc_vendor_name        ap_checks_all.vendor_name%TYPE;  -- Defect 8204
   lc_address_line1      ap_checks_all.address_line1%TYPE;  -- Defect 8204
   lc_address_line2      ap_checks_all.address_line2%TYPE;  -- Defect 8204
   lc_city               ap_checks_all.city%TYPE;  -- Defect 8204
   lc_state              ap_checks_all.state%TYPE;  -- Defect 8204
   lc_country            ap_checks_all.country%TYPE;  -- Defect 8204
   lc_zip                ap_checks_all.zip%TYPE;   -- Defect 8204   
   
   --v_path               VARCHAR2 (100)    := 'XXFIN_OUTBOUND';
   lc_filename           VARCHAR2(200);  --   := 'pospay_wachovia_'||FND_GLOBAL.CONC_REQUEST_ID||'.txt';
   ln_conc_req_id        NUMBER  :=FND_GLOBAL.CONC_REQUEST_ID;
   lf_utl_file_handle     utl_file.file_type;
   lc_line               VARCHAR2(5000);
   ln_count              NUMBER  := 0 ;
   ln_amount             NUMBER  := 0;
   lc_check_num          VARCHAR2(50) ;
   lc_void_status        VARCHAR2(1) ;
   lc_file_created       CHAR(1) := 'N';
   lc_prev_bnk_acc       ap_bank_accounts_all.bank_account_num%type := '00';
   
BEGIN

   DBMS_OUTPUT.ENABLE (1000000);
    
 FOR lcu_bank_cur IN c_bank_cur
 
   LOOP
             
      lc_filename := p_wach_filename||ln_conc_req_id||'.txt';        
      lc_bank_account_num := lcu_bank_cur.bank_account_num;
      
      lc_currency_code := lcu_bank_cur.currency_code;
      
        
       BEGIN
--          SELECT COUNT(1),SUBSTR(SUM(AC.amount),1,INSTR(SUM(AC.amount),'.',1,1)-1)||SUBSTR(SUM(AC.amount),INSTR(SUM(AC.amount),'.',1,1)+1)
          Select COUNT(1),SUM(AC.amount)  -- defect 8892
          INTO    ln_count
                 ,ln_amount
          FROM   ap_checks_all AC
          WHERE  AC.bank_account_id = lcu_bank_cur.bank_account_id
-- defect 4972   AND    AC.check_date BETWEEN (SYSDATE-p_days) AND (SYSDATE) -- Added for Defect 2459 , by mohan 10/19/2007
        -- Added for Defect 2459 , by mohan 10/19/2007
          AND( (AC.positive_pay_status_code = 'UNSENT' ) OR
             (AC.status_lookup_code = 'VOIDED' ) AND ( AC.positive_pay_status_code ='SENT AS NEGOTIABLE' ))
          AND AC.payment_method_lookup_code = 'CHECK';
        
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(fnd_file.log,'No Data Found Exception while fetching the total amount and count' );
       END;
  
        
--      FND_FILE.PUT_LINE (fnd_file.log, 'Wachovia Loop:' ||  lc_bank_account_num 
--      || ' ' || lcu_bank_cur.currency_code);        
      
 FOR lcu_pospay IN c_pospay (lc_bank_account_num)
 LOOP

--       FND_FILE.PUT_LINE (fnd_file.log, 'W PosPay Loop: Name ' || lcu_pospay.vendor_name
--       || ' ' || lcu_pospay.check_number || ' ' || lcu_pospay.check_date );
        
    IF lc_file_created = 'N' THEN
      lf_utl_file_handle := utl_file.fopen (p_path,lc_filename, 'W');
      lc_file_created := 'Y';
    END IF;
 
     IF  lc_prev_bnk_acc <> lc_bank_account_num
     THEN
        lc_line  :=    'RECONCILIATIONHEADER'     || '0003'
                            || lpad(lc_bank_account_num,13,'0')
                            || lpad(ln_amount*100 ,12,'0')
                            || lpad(ln_count,5,'0')
                            || '000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

        UTL_FILE.PUT_LINE (lf_utl_file_handle, lc_line);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lc_line);
        lc_prev_bnk_acc := lc_bank_account_num;     
     END IF ;
         --lc_bank_num := lcu_pospay.bank_num;
         lc_check_num  := lcu_pospay.check_number;
         lc_check_date := lcu_pospay.check_date;
         lc_vendor_name := lcu_pospay.vendor_name;
         lc_address_line1 := lcu_pospay.address_line1;
         lc_address_line2 := lcu_pospay.address_line2;
         lc_city := lcu_pospay.city;
         lc_state := lcu_pospay.state;
         lc_country := lcu_pospay.country;
         lc_zip := lcu_pospay.zip;
         
   IF lcu_pospay.status_lookup_code IN 
                                    ('VOID'
                                    ,'SPOILED'
                                    ,'SET UP'
                                    ,'OVERFLOW')
        THEN
           ln_void := ln_void + 1;
      lc_void_status := 'V' ;
           ln_void_amount := ln_void_amount + lcu_pospay.amount;
   ELSE
      lc_void_status := ' ' ;
   END IF;
        
         --dbms_output.put_line('The Bank Account Num being passed is :'||'  '||lc_bank_account_num);
         
         lc_line  :=
                LPAD (lc_bank_account_num, 13, '0')
             || LPAD (lc_check_num, 10, '0')
             || LPAD (lcu_pospay.amount*100, 10, '0')
        || lc_check_date
             ||NVL(lc_void_status,' ')
             || '000000000000000000000000000000'
             || '00000000'
             || lpad(lc_vendor_name,50,'0')
             || '00000000000000000000'
             ;
     UTL_FILE.PUT_LINE (lf_utl_file_handle, lc_line);
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lc_line);

     IF lcu_pospay.status_lookup_code IN
               ('NEGOTIABLE',
                'CLEARED',
                'ISSUED',
                'CLEARED BUT UNACCOUNTED',
                'RECONCILED',
                'RECONCILED UNACCOUNTED'
               )
      THEN
         ln_issued := ln_issued + 1;
         ln_issued_amount := ln_issued_amount + lcu_pospay.amount;
      END IF;
      
  END LOOP;
   
 -- The following update statement is as per the delivered code for this functionality.
 -- It is assumed here that immediately before this is happening during the execution of the custom
 -- positive payee match process, the tables are locked and are not subjected to any dml operations on them.

--FND_FILE.PUT_LINE (fnd_file.log,' Updates to positive_pay_status_code field in AP_CHECKS_ALL started ....');
 
    BEGIN
      UPDATE ap_checks_all
      SET positive_pay_status_code = DECODE (status_lookup_code,
                                     'NEGOTIABLE', 'SENT AS NEGOTIABLE',
                                     'ISSUED', 'SENT AS NEGOTIABLE',
                                     'CLEARED', 'SENT AS NEGOTIABLE',
                                     'CLEARED BUT UNACCOUNTED', 'SENT AS NEGOTIABLE',
                                     'RECONCILED', 'SENT AS NEGOTIABLE',
                                     'RECONCILED UNACCOUNTED', 'SENT AS NEGOTIABLE',
                                     'VOIDED', 'SENT AS VOIDED',
                                     'SPOILED', 'SENT AS VOIDED',
                                     'SET UP', 'SENT AS VOIDED',
                                     'OVERFLOW', 'SENT AS VOIDED')
       WHERE check_id IN (
                          SELECT ACL.check_id
                          FROM ap_checks_all ACL
                              ,ap_check_stocks_all ACS
                              ,ap_bank_accounts_all ABA
                              ,ap_bank_branches ABB
                          WHERE 1 = 1
                          AND ACL.check_stock_id = ACS.check_stock_id
                          AND ACS.bank_account_id = ABA.bank_account_id
                          AND ABA.bank_branch_id = ABB.bank_branch_id
                          AND ACL.payment_method_lookup_code = 'CHECK'
-- defect 4972            AND ACL.check_date BETWEEN (SYSDATE-p_days) AND (SYSDATE) -- Added for Defect 2459 , by mohan 10/19/2007
                   -- Added for Defect 2459 , by mohan 10/19/2007
                          AND( (ACL.positive_pay_status_code = 'UNSENT' ) OR
                               (ACL.status_lookup_code = 'VOIDED' ) AND ( ACL.positive_pay_status_code ='SENT AS NEGOTIABLE'))
                          AND ABA.bank_account_num = lc_bank_account_num);    
                          
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT, SQLERRM||'Error while Updating Wachovia Bank positive_pay_status_code for Account Number  '||lc_bank_account_num );
    END;
    
 END LOOP;
 
   -- COMMENTED FOR DEFECT 2459
  -- FND_FILE.PUT_LINE(fnd_file.log,'The Total number of checks issued is:'||ln_count);
 UTL_FILE.FCLOSE(lf_utl_file_handle);
   
 IF lc_file_created = 'Y' THEN
   ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                                         ,'XXCOMFILCOPY'
                                         ,''
                                         ,''
                                         ,FALSE
                                         ,'$XXFIN_DATA/outbound/'|| lc_filename
                                         ,'$XXFIN_DATA/ftp/out/positivepay/' || lc_filename
                                         ,'','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','',''
                                         ,'','','','','','','','','','');

      IF ln_req_id = 0
      THEN
         FND_FILE.PUT_LINE
                         (FND_FILE.LOG,
                          'Error submitting request for Positive Pay'
                         );
      END IF;
  END IF;
END;
END IF;
EXCEPTION
   WHEN UTL_FILE.INVALID_PATH THEN
      UTL_FILE.FCLOSE(lf_utl_file_handle);
      FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid File Path ');
   WHEN UTL_FILE.INVALID_MODE THEN
      UTL_FILE.FCLOSE(lf_utl_file_handle); 
      FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid Mode ');
   WHEN UTL_FILE.INVALID_OPERATION THEN
      UTL_FILE.FCLOSE(lf_utl_file_handle);
      FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid Operation ');
   WHEN UTL_FILE.WRITE_ERROR THEN
      UTL_FILE.FCLOSE(lf_utl_file_handle);
      FND_FILE.PUT_LINE (FND_FILE.LOG ,'Write While calling Utl Package');
   WHEN OTHERS THEN
      UTL_FILE.FCLOSE(lf_utl_file_handle);
      FND_FILE.PUT_LINE (FND_FILE.LOG ,SQLERRM||'UNKNOWN ERROR Occured while executing the Positive pay Program' );
END XX_AP_POSITIVEPAY_PROC;


/
