CREATE OR REPLACE PACKAGE BODY XX_AP_ESCHEAT_PKG
AS
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |              Office Depot Organization                                                           |
  -- +==================================================================================================+
  -- | Name  : XX_AP_ESCHEAT_PKG                                                                        |
  -- | Description:  E2056: Package to process Escheat and PAR checks                                   |
  -- | Change Record:                                                                                   |
  -- |===============                                                                                   |
  -- |Version   Date           Author           Remarks                                                 |
  -- |=======   ==========    =============    ========================================                 |
  -- |DRAFT 1A  25-MAR-2010 P. Marco           Initial draft version                                    | 
  -- |1.0      31-Jyly-2013   Sravanthi     1. Changed column payment_method_lookup_code                |
  -- |                                         to payment_method_code                                   |
  -- |                                     2.  Changed Parameters in fnd_submit.request for XDOREPPB    | 
  -- |                                         (XML Report Publisher) by adding additional Parameter    |
  -- |                                        Dummy for Data Security as in r12 Con Program Definition  |
  -- |1.1      12-Dec-2013   Avinash          E2056 - Changed the VOID_PAYMENT procedure to populate    |
  -- |                                        the Org Id of the Check instead of Profile Org Id for defect 26612.  |
  -- |1.2      21-Feb-2014   Veronica         E2056 - Changed to include the hints suggested by ERP     |
  -- |                                        Engineering for the defect 28382.                         |
  -- |1.3      26-Jun-2014   Madhan           Code modified based on the defect# 30653                  |
  -- |1.4      27-Oct-2015   Harvinder Rakhra Retrofit R12.2                                            |
  -- |1.5	   26-JUN-2018   Atul Khard       Commented the Hint from query as per suggestion from      |
  -- |                                        Hari Jagannathan from Enggineering Team Defect 44664      |
  -- +===================================================================================================+

  ---------------------
  -- Global Variables
  ---------------------
  gc_current_step       VARCHAR2(500);
  gn_user_id            NUMBER   := FND_PROFILE.VALUE('USER_ID');
  gn_org_id             NUMBER   := FND_PROFILE.VALUE('ORG_ID');
  gn_request_id         NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();


  gc_errbuff            VARCHAR2(500);
  gc_retcode            VARCHAR2(1);


  -----------------------------------------------
  -- Functions to pass return code and error code
  -- Back to Form Personalization
  ----------------------------------------------

  FUNCTION GET_RETURN_CODE  RETURN VARCHAR2
    IS
     BEGIN
             RETURN gc_retcode;

     END GET_RETURN_CODE;



  FUNCTION GET_ERRCODE_CODE RETURN VARCHAR2
   IS
     BEGIN
             RETURN gc_errbuff;

     END  GET_ERRCODE_CODE;



    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |              Office Depot Organization                      |
    -- +===================================================================+
    -- | Name  : XX_VOID_PAYMENT                                           |
    -- | Description : Procedure will be submitted via payment form        |
    -- |               personalization                                     |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks                   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

  PROCEDURE XX_VOID_PAYMENT   (p_check_id  IN  NUMBER DEFAULT NULL
                              ,p_void_type IN VARCHAR2 )
  AS
         -------------------
         -- Define exception
         -------------------
          NO_PAYMENTS_FOUND         EXCEPTION;

          ln_payment_cnt            NUMBER;
          ln_check_id               NUMBER;
          lc_current_step           VARCHAR2(500);
          lc_email_adds             VARCHAR2(250);
          lc_pay_grp_lkup_code      VARCHAR2(50);

          ln_conc_id                NUMBER;
    BEGIN

      lc_email_adds :=  'FC-EFT@officedepot.com';

      ln_check_id := p_check_id;
      -- TESTING ln_check_id := 0;
      ---------------------------------------------------------
      lc_current_step  := ' Step: Confirm payments exist  ';
      ---------------------------------------------------------
        ln_payment_cnt := 0;

         SELECT nvl(count(1),0) into ln_payment_cnt
            FROM  AP_CHECKS_V where check_id  = ln_check_id;

        IF ln_payment_cnt = 0 THEN

                RAISE NO_PAYMENTS_FOUND;

        END IF;

      ---------------------------------------------------------
      lc_current_step  := ' Step: setting pay look up code';
      ---------------------------------------------------------
      IF p_void_type = 'Escheat' THEN
          lc_pay_grp_lkup_code := 'US_OD_ESCHEAT_CLEAR';
      ELSE
          lc_pay_grp_lkup_code := 'US_OD_PAR';
      END IF;


       ------------------------------------------------------------------------
       lc_current_step  :=    ' Step: insert XX_AP_ESCHEAT_PAR_PMT_HIS ';
       ------------------------------------------------------------------------
       -- Defect 5721 if ord_id = CAN and currency = CAD then copy control
       -- amount to the funnctional currency to allow email output to have
       -- correct totals

       INSERT INTO XX_AP_ESCHEAT_PAR_PMT_HIS
          (ORG_DOC_NUM
          ,ORG_CHECK_ID
          ,ORG_PMT_DATE
          ,ORG_PAY_AMT
          ,ORG_FUNC_AMT
          ,SUPPLIER_NUM
          ,SUPPLIER_SITE
          ,SUPPLIER_NAME
          ,VOID_TYPE
          ,ADDRESS1
          ,ADDRESS2
          ,CITY
          ,STATE
          ,COUNTRY
          ,ZIP_CODE
          ,org_id
          ,CLR_PAY_DOC_NUM
          ,CLR_PAY_DATE
          ,PAY_CURRENCY
          ,EXTRACT_FILE_NAME
          ,CREATION_DATE
          ,CREATED_BY
          ,LAST_UPDATE_DATE
          ,LAST_UPDATED_BY
          ,ERROR_MESSAGE
          ,PROCESS_DATE
          ,PROCESS_STATUS
          )
       /*SELECT CHECK_NUMBER
           ,CHECK_ID
           ,CHECK_DATE
           ,CONTROL_AMOUNT
           ,BASE_AMOUNT
           ,VENDOR_NUMBER
           ,VENDOR_SITE_CODE
           ,VENDOR_NAME
           ,ATTRIBUTE10    -- VOID_TYPE
           ,ADDRESS_LINE1
           ,ADDRESS_LINE2
           ,CITY
           ,STATE
           ,decode(COUNTRY,'US','USA','CAN')
           ,ZIP
           --,gn_org_id -- Commented for defect 26612. 12-Dec-13
           ,org_id      -- Changed to have Org Id of the Check instead of Profile Org Id for defect 26612. 12-Dec-13.
           ,NULL         -- CLR_PAY_DOC_NUM NUMBER
           ,NULL         -- CLR_PAY_DATE DATE
           ,CURRENCY_CODE
           ,NULL         -- EXTRACT_FILE_NAME VARCHAR2(35)
           ,sysdate      -- CREATION_DATE
           ,gn_user_id   -- CREATED_BY
           ,NULL         -- LAST_UPDATED_DATE
           ,NULL         -- LAST_UPDATE_BY
           ,NULL         -- ERROR_MESSAGE
           ,sysdate      -- PROCESS_DATE
           ,'SELECTED'   -- PROCESS_STATUS
         FROM AP_CHECKS_V
         WHERE check_id  = ln_check_id;*/ --Commented for Defect# 30653 by Madhan 

           SELECT apc.CHECK_NUMBER
           ,apc.CHECK_ID
           ,apc.CHECK_DATE
           ,apc.CONTROL_AMOUNT
           ,apc.BASE_AMOUNT
           ,apc.VENDOR_NUMBER
          -- ,VENDOR_SITE_CODE
           ,assa.vendor_site_code -- Code modified as part of Defect# 30653
           ,apc.VENDOR_NAME
           ,apc.ATTRIBUTE10    -- VOID_TYPE
           ,apc.ADDRESS_LINE1
           ,apc.ADDRESS_LINE2
           ,apc.CITY
           ,apc.STATE
           ,decode(apc.COUNTRY,'US','USA','CAN')
           ,apc.ZIP
           --,gn_org_id -- Commented for defect 26612. 12-Dec-13
           ,apc.org_id      -- Changed to have Org Id of the Check instead of Profile Org Id for defect 26612. 12-Dec-13.
           ,NULL         -- CLR_PAY_DOC_NUM NUMBER
           ,NULL         -- CLR_PAY_DATE DATE
           ,apc.CURRENCY_CODE
           ,NULL         -- EXTRACT_FILE_NAME VARCHAR2(35)
           ,sysdate      -- CREATION_DATE
           ,gn_user_id   -- CREATED_BY
           ,NULL         -- LAST_UPDATED_DATE
           ,NULL         -- LAST_UPDATE_BY
           ,NULL         -- ERROR_MESSAGE
           ,sysdate      -- PROCESS_DATE
           ,'SELECTED'   -- PROCESS_STATUS
           FROM AP_CHECKS_V apc, ap_supplier_sites_all assa
           WHERE apc.check_id  = ln_check_id
             and apc.vendor_site_id = assa.vendor_site_id;
			 
			 
       COMMIT;
       ------------------------------------------------------------------------
       lc_current_step  :=    ' Step: insert XX_AP_ESCHEAT_PAR_INV_HIS ';
       ------------------------------------------------------------------------
       INSERT INTO XX_AP_ESCHEAT_PAR_INV_HIS
          (ORG_CHECK_ID
          ,ORG_INV_PAY_TERMS
          ,ORG_INV_PAY_GROUP
          ,INVOICE_TYPE
          ,INVOICE_NUM
          ,INVOICE_ID
          ,INVOICE_AMT
          ,INVOICE_DATE
          ,INVOICE_CURRENCY
          ,CREATION_DATE
          ,CREATED_BY
          )
        SELECT DISTINCT
           AIP.check_id
          ,AI.terms_id
          ,AI.pay_group_lookup_code
          ,AI.INVOICE_TYPE_LOOKUP_CODE
          ,AI.INVOICE_NUM
          ,AI.invoice_id
          ,AI.invoice_amount
          ,AI.invoice_date
          ,AI.INVOICE_CURRENCY_CODE
          , sysdate
          ,gn_user_id
         FROM AP_INVOICES AI
             ,AP_INVOICE_PAYMENTS  AIP
        WHERE AIP.check_id = ln_check_id
          AND AI.invoice_id = AIP.invoice_id;

          COMMIT;

      ---------------------------------------------------------
      lc_current_step  := ' Step: update: AP_PAYMENT_SCHEDULES ';
      ---------------------------------------------------------
      UPDATE AP_PAYMENT_SCHEDULES 
      --- SET payment_method_lookup_code = 'CLEARING'  -- Commented By Sravanthi on 31-Jyly-2013
      SET payment_method_code = 'CLEARING'             -- Changed column payment_method_lookup_code to payment_method_code By Sravanthi on 31-July-2013 
      WHERE invoice_id IN (SELECT DISTINCT invoice_id
                            FROM AP_INVOICE_PAYMENTS
                           WHERE check_id = ln_check_id);

      COMMIT;

      ---------------------------------------------------------
      lc_current_step  := ' Step: update: ap_invoices ';
      ---------------------------------------------------------
      UPDATE ap_invoices
         --- SET Payment_method_lookup_code = 'CLEARING'   -- Commented By Sravanthi on 31-July-2013
             SET Payment_method_code = 'CLEARING'          -- Changed column payment_method_lookup_code to payment_method_code By Sravanthi on 31-July-2013 
           ,terms_id = 10000
           ,pay_group_lookup_code = lc_pay_grp_lkup_code --'US_OD_ESCHEAT_CLEAR'
       WHERE invoice_id IN (SELECT DISTINCT invoice_id
                              FROM AP_INVOICE_PAYMENTS
                             WHERE check_id = ln_check_id);
       COMMIT;


      gc_retcode := 0;

     EXCEPTION

          WHEN NO_PAYMENTS_FOUND THEN

              gc_errbuff := 'ERROR: No data found on AP_CHECKS_V view for '||
                            'CHECK_ID: '||ln_check_id || 'Processing may ' ||
                            'have failed '||lc_current_step;

              ln_conc_id := fnd_request.submit_request
                       (
                         application => 'XXFIN'
                        ,program     => 'XXODEMAILER'
                        ,description => NULL
                        ,start_time  => SYSDATE
                        ,sub_request => FALSE
                        ,argument1   => lc_email_adds
                        ,argument2   => 'Error occured in Escheats-PAR Process!'
                        ,argument3   => gc_errbuff
                       );

              -------------------------------------------
              -- UPDATE HISTORY TABLE with error messages
              -------------------------------------------
              INSERT INTO XX_AP_ESCHEAT_PAR_PMT_HIS
                           (PROCESS_STATUS
                           ,PROCESS_DATE
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATED_BY
                           ,ERROR_MESSAGE)
                     VALUES
                           ('ERROR'
                            ,SYSDATE
                            ,SYSDATE
                            ,gn_user_id
                            ,SYSDATE
                            ,gn_user_id
                            ,gc_errbuff);
              COMMIT;

              gc_retcode := 1;

          when NO_DATA_FOUND then

              gc_errbuff := SUBSTR('CHECK_ID='||ln_check_id||':'
                                   ||gc_current_step ||chr(10)
                                        ||SQLERRM () ,1,150);


              ln_conc_id := fnd_request.submit_request(
                                application => 'XXFIN'
                               ,program     => 'XXODEMAILER'
                               ,description => NULL
                               ,start_time  => SYSDATE
                               ,sub_request => FALSE
                               ,argument1   => lc_email_adds
                               ,argument2   => 'Error with Escheats-PAR process'
                               ,argument3   => gc_errbuff
                                                         );

             -------------------------------------------
             -- UPDATE HISTORY TABLE with error messages
             -------------------------------------------
             INSERT INTO XX_AP_ESCHEAT_PAR_PMT_HIS
                           (PROCESS_STATUS
                           ,PROCESS_DATE
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATED_BY
                           ,ERROR_MESSAGE)
                    VALUES
                           ('ERROR'
                            ,SYSDATE
                            ,SYSDATE
                            ,gn_user_id
                            ,SYSDATE
                            ,gn_user_id
                            ,gc_errbuff);
             COMMIT;

             gc_retcode := 1;

          WHEN OTHERS THEN

             gc_errbuff := SUBSTR('Other Err:CHECK_ID='
                                 ||ln_check_id||':'|| SQLERRM () ,1,150);

             ln_conc_id := fnd_request.submit_request(
                                    application => 'XXFIN'
                                   ,program     => 'XXODEMAILER'
                                   ,description => NULL
                                   ,start_time  => SYSDATE
                                   ,sub_request => FALSE
                                   ,argument1   => lc_email_adds
                                   ,argument2   => 'Error with Escheats process'
                                   ,argument3   => gc_errbuff
                                                       );

              -------------------------------------------
              -- UPDATE HISTORY TABLE with error messages
              -------------------------------------------
              INSERT INTO XX_AP_ESCHEAT_PAR_PMT_HIS
                           (PROCESS_STATUS
                           ,PROCESS_DATE
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATED_BY
                           ,ERROR_MESSAGE)
                     VALUES
                           ('ERROR'
                            ,SYSDATE
                            ,SYSDATE
                            ,gn_user_id
                            ,SYSDATE
                            ,gn_user_id
                            ,gc_errbuff);
              COMMIT;

              gc_retcode := 1;

    END XX_VOID_PAYMENT;




    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |              Office Depot Organization                      |
    -- +===================================================================+
    -- | Name  : CREATE_EXTACT_FILE_PROC                                   |
    -- | Description : Procedure will be Generate the extract file required|
    -- |               for the Escheat-Par processes                       |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks                   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE CREATE_EXTACT_FILE_PROC    (errbuff     OUT VARCHAR2
                                         ,retcode     OUT VARCHAR2
                                         ,p_void_type  IN VARCHAR2)
    AS


         -------------------
         -- Define exception
         -------------------
         NO_PAYMENTS_FOUND         EXCEPTION;
         g_FileHandle              UTL_FILE.FILE_TYPE;
         lc_current_step           VARCHAR2(500);
         lc_program_name           VARCHAR2(50);
         lc_output_file            VARCHAR2 (100);
         lc_fileheader             VARCHAR2(5000);
         lc_filerec                VARCHAR2(5000);
         lc_print_line             VARCHAR2(5000);
         lc_FTP_Process            VARCHAR2(200);
         lc_delimiter              VARCHAR2(10);
         lc_pay_group              VARCHAR2(50);
         ln_check_number           NUMBER;
         ln_org_check_id           NUMBER;
         lc_check_date             DATE;
         lc_fed_type               VARCHAR2(50);
         ln_fed_id                 NUMBER;
         lc_VAT_REGISTRATION_NUM   NUMBER;
         lc_ORG_TYPE_LOOKUP_CODE   VARCHAR2(50);
         lc_payment_cnt            NUMBER;
         ln_amount                 NUMBER;
         lc_currency               VARCHAR2(15);
         lc_file_curr              VARCHAR2(3);
         lc_record_cnt             NUMBER;
         ----------------------------------------------
         --Cursor to update clearing info history table
         ----------------------------------------------
         CURSOR UPDATE_CLR_INFO IS
              SELECT DISTINCT AC.check_number, AC.check_date, PH.org_check_id
                     FROM  XX_AP_ESCHEAT_PAR_PMT_HIS PH
                         ,XX_AP_ESCHEAT_PAR_INV_HIS IH
                     ,AP_INVOICES AI
                     ,AP_INVOICE_PAYMENTS IP
                     ,AP_CHECKS_V AC
                    WHERE  PH.VOID_TYPE           = p_void_type
                      AND  PH.process_status        = 'SELECTED'
                         AND  PH.org_id                = gn_org_id
                      AND  PH.org_check_id          = IH.org_check_id
                      AND  AI.invoice_id            = IH.invoice_id
                      AND  AI.invoice_id            = IP.invoice_id
                      AND  AC.check_id              = IP.check_id
                      AND  AI.pay_group_lookup_code = lc_pay_group
                      AND  AC.status_lookup_code    = 'NEGOTIABLE';

         ----------------------------------------------
         --Cursor to select records for extract file
         ----------------------------------------------
         CURSOR SELECT_EXTRACT_REC IS
              SELECT  NVL(STATE,'DE') FIL_STATE --State
                     ,ORG_PMT_DATE    --Ck Date
                     ,ORG_PAY_AMT     --Pay_Amount
                     ,ORG_FUNC_AMT    -- Func_Amout
                     ,SUPPLIER_SITE   --Supplier Site
                     ,ORG_DOC_NUM     --Check #
                     ,SUPPLIER_NAME   --Supplier Name
                     ,ADDRESS1        --Address1
                     ,ADDRESS2        --Address2
                     ,CITY            --City
                     ,STATE           --State Code
                     ,COUNTRY         --Country
                     ,ZIP_CODE        --Postal
                     ,CLR_PAY_DOC_NUM --Clearing Payment #
                     ,CLR_PAY_DATE    --Clearing Date
                     ,SUPPLIER_NUM    --Supplier #
                     ,PAY_CURRENCY    --Payment Currency
                     ,decode(gn_org_id,404,'USTRA','CNTRA') BUS_UNIT
               FROM  XX_AP_ESCHEAT_PAR_PMT_HIS
               WHERE     PROCESS_STATUS = 'CLR_INFO_UPDATED'
                 AND void_type      =  p_void_type
                 AND  org_id        = gn_org_id;

    BEGIN
        lc_program_name  := 'CREATE_EXTACT_FILE_PROC';
        lc_current_step  := 'START';

        FND_FILE.PUT_LINE(FND_FILE.LOG, lc_program_name||':'||lc_current_step);


        ----------------------------------------
        lc_current_step  := 'Setting Variables';
        ----------------------------------------
        lc_delimiter := chr(9);


        IF gn_org_id = '404' THEN
          lc_file_curr := 'USD';

        ELSE
          lc_file_curr := 'CAD';

        END IF;

        IF p_void_type  = 'Escheat'  THEN
             ---------------------------------------------
             --set environment variables for Escheat voids
             ---------------------------------------------
             lc_output_file := 'XXAPESCHEATS_AP_'||lc_file_curr||'_'
                             || to_char(sysdate,'MMDDYYYYHH24MISS')||'.txt';
             lc_pay_group := 'US_OD_ESCHEAT_CLEAR';

        ELSE
             -----------------------------------------
             --set environment variables for PAR voids
             -----------------------------------------
             lc_output_file := 'XXAPPAR_AP_'||lc_file_curr||'_'
                             || to_char(sysdate,'MMDDYYYYHH24MISS')||'.txt';
             lc_pay_group := 'US_OD_PAR';

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'p_void_type     = '||p_void_type);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_pay_group    = '||lc_pay_group);

        ------------------------------------------------------
        lc_current_step  := 'Confirming Payment exist for '
                             ||p_void_type||' Process';
        ------------------------------------------------------
        SELECT  nvl(count(1),0)
           INTO  lc_payment_cnt
              FROM  XX_AP_ESCHEAT_PAR_PMT_HIS PH
                ,XX_AP_ESCHEAT_PAR_INV_HIS IH
                ,AP_INVOICES AI
                ,AP_INVOICE_PAYMENTS IP
                ,AP_CHECKS_V AC
            WHERE  PH.VOID_TYPE             =  p_void_type
               AND  PH.process_status        =  'SELECTED'
              AND  PH.org_id                = gn_org_id
               AND  PH.org_check_id          = IH.org_check_id
               AND  AI.invoice_id            = IH.invoice_id
               AND  AI.invoice_id            = IP.invoice_id
               AND  AC.check_id              = IP.check_id
               AND  AI.pay_group_lookup_code = lc_pay_group
               AND  AC.status_lookup_code    = 'NEGOTIABLE';

        --------------------------------------
        --Raise Exception if no payments found
        --------------------------------------
        IF   lc_payment_cnt = 0 THEN

             RAISE NO_PAYMENTS_FOUND;

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_output_file  = '||lc_output_file);


        -------------------------------------------------
        lc_current_step  := 'Open UPDATE_CLR_INFO cursor';
        -------------------------------------------------
        OPEN  UPDATE_CLR_INFO;
          LOOP

             FETCH UPDATE_CLR_INFO INTO ln_check_number, lc_check_date, ln_org_check_id ;

          EXIT WHEN UPDATE_CLR_INFO%NOTFOUND;

             -----------------------------------------------------------
             lc_current_step  := 'UPDATE XX_AP_ESCHEAT_PAR_PMT_HIS';
             -----------------------------------------------------------
             UPDATE XX_AP_ESCHEAT_PAR_PMT_HIS
                SET CLR_PAY_DOC_NUM   = ln_check_number
                   ,CLR_PAY_DATE      = lc_check_date
                   ,PROCESS_STATUS    = 'CLR_INFO_UPDATED'
                   ,LAST_UPDATED_BY   = gn_user_id
                   ,LAST_UPDATE_DATE  = SYSDATE
                 WHERE VOID_TYPE       = p_void_type
                AND  org_id           = gn_org_id
                AND org_check_id      = ln_org_check_id
                AND PROCESS_STATUS    = 'SELECTED';

             COMMIT;

          END LOOP;
        CLOSE  update_clr_info;


        g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND',lc_output_file,'w');
        ----------------------------------------------
        lc_current_step  := 'Writing Header records';
        ----------------------------------------------
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_current_step ||':'||p_void_type);

        IF p_void_type  = 'Escheat'  THEN
            lc_fileheader :='State'             || lc_delimiter
                          ||'Ck Date'           || lc_delimiter
                          ||'Amount'            || lc_delimiter
                          ||'Supplier Site'     || lc_delimiter
                          ||'Check #'           || lc_delimiter
                          ||'Blank'             || lc_delimiter
                          ||'Fed Type'          || lc_delimiter
                          ||'Fed ID'            || lc_delimiter
                          ||'Supplier Name'     || lc_delimiter
                          ||'Blank'             || lc_delimiter
                          ||'Blank'             || lc_delimiter
                          ||'Address1'          || lc_delimiter
                          ||'Address2'          || lc_delimiter
                          ||'City'              || lc_delimiter
                          ||'State Code'        || lc_delimiter
                          ||'Country'           || lc_delimiter
                          ||'Postal'            || lc_delimiter
                          ||'Blank'             || lc_delimiter
                          ||'Blank'             || lc_delimiter
                          ||'Clearing Payment #'|| lc_delimiter
                          ||'Clearing Date'     || lc_delimiter
                          ||'Supplier #'        || lc_delimiter
                          ||'Payment Currency';


                lc_print_line := lc_fileheader;

         ELSE
            lc_fileheader :='ClaimNumber'           || lc_delimiter
                          ||'AuditYear'             || lc_delimiter
                          ||'Currency'              || lc_delimiter
                          ||'Auditor'               || lc_delimiter
                          ||'BusUnit'               || lc_delimiter
                          ||'GlobalNo'              || lc_delimiter
                          ||'SupplierSiteNo'        || lc_delimiter
                          ||'PSVendor'              || lc_delimiter
                          ||'SupplierName'          || lc_delimiter
                          ||'DateEntered'           || lc_delimiter
                          ||'Claim_Code'            || lc_delimiter
                          ||'Claim_Status'          || lc_delimiter
                          ||'Claim_Amt'             || lc_delimiter
                          ||'GL_ACCT'               || lc_delimiter
                          ||'Original Document #'   || lc_delimiter
                          ||'Original Document Date'|| lc_delimiter ;

                lc_print_line := lc_fileheader;

         END IF;

         lc_record_cnt := 0;


         UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
         ----------------------------------------------------
         lc_current_step  := 'Writing Extract Records';
         ----------------------------------------------------
          FOR R_EX IN SELECT_EXTRACT_REC LOOP

             lc_record_cnt := lc_record_cnt + 1;

             FND_FILE.PUT_LINE(FND_FILE.LOG,lc_current_step ||
                                               ':'||p_void_type);

             ----------------------------------------------
             lc_current_step  := 'Getting Display Amount';
             ----------------------------------------------
             -- per defect 5721  removed code below

             --  IF gn_org_id = '404' THEN
             --    ln_amount    := R_EX.ORG_PAY_AMT;
             --    lc_currency  := R_EX.PAY_CURRENCY;

             --   ELSE
             --      IF R_EX.PAY_CURRENCY = 'CAD' THEN
             --          ln_amount    := R_EX.ORG_PAY_AMT;
             --          lc_currency  := R_EX.PAY_CURRENCY;
             --        ELSE
             --          ln_amount    := R_EX.ORG_FUNC_AMT;
             --          lc_currency  :=  R_EX.PAY_CURRENCY;

             --      END IF;
             --   END IF;

             -- per defect 5721  added code below
             ln_amount    := R_EX.ORG_PAY_AMT;
             lc_currency  := R_EX.PAY_CURRENCY;


             IF p_void_type  = 'Escheat'  THEN

                 ----------------------------------------------
                 lc_current_step  := 'Getting Fed type INFO/ID';
                 ----------------------------------------------

                 SELECT NVL(num_1099,0)
                       ,NVL(ORGANIZATION_TYPE_LOOKUP_CODE,'NO-CODE')
                   INTO lc_VAT_REGISTRATION_NUM
                       ,lc_ORG_TYPE_LOOKUP_CODE
                   FROM AP_VENDORS_V
                  WHERE vendor_number = R_EX.SUPPLIER_NUM;



                 IF lc_VAT_REGISTRATION_NUM <> 0
                       AND UPPER(lc_ORG_TYPE_LOOKUP_CODE) = 'CORPORATION' THEN

                        lc_fed_type := 'N';
                        ln_fed_id   :=  lc_VAT_REGISTRATION_NUM;

                 ELSIF lc_VAT_REGISTRATION_NUM <> 0
                        AND UPPER(lc_ORG_TYPE_LOOKUP_CODE) = 'INDIVIDUAL' THEN

                        lc_fed_type := 'Y';
                        ln_fed_id   :=  lc_VAT_REGISTRATION_NUM;
                 ELSE
                        lc_fed_type := NULL;
                        ln_fed_id   := NULL;
                 END IF;

                 lc_filerec := R_EX.FIL_STATE        || lc_delimiter
                             ||to_char(R_EX.ORG_PMT_DATE,'MM/DD/YYYY')
                                                    || lc_delimiter
                             ||to_char(ln_amount,999999999999.99)
                                                    || lc_delimiter
                             ||R_EX.SUPPLIER_SITE   || lc_delimiter
                             ||R_EX.ORG_DOC_NUM     || lc_delimiter
                             ||NULL                 || lc_delimiter
                             ||lc_fed_type          || lc_delimiter
                             ||ln_fed_id            || lc_delimiter
                             ||R_EX.SUPPLIER_NAME   || lc_delimiter
                             ||NULL                 || lc_delimiter
                             ||NULL                 || lc_delimiter
                             ||R_EX.ADDRESS1        || lc_delimiter
                             ||R_EX.ADDRESS2        || lc_delimiter
                             ||R_EX.CITY            || lc_delimiter
                             ||R_EX.STATE           || lc_delimiter
                             ||R_EX.COUNTRY         || lc_delimiter
                             ||R_EX.ZIP_CODE        || lc_delimiter
                             ||NULL                 || lc_delimiter
                             ||NULL                 || lc_delimiter
                             ||R_EX.CLR_PAY_DOC_NUM || lc_delimiter
                             ||to_char(R_EX.CLR_PAY_DATE,'MM/DD/YYYY')
                                                    || lc_delimiter
                             ||R_EX.SUPPLIER_NUM    || lc_delimiter
                             ||lc_currency          || lc_delimiter;
              ELSE

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_current_step ||
                                          ':'||p_void_type);

                lc_filerec := R_EX.CLR_PAY_DOC_NUM   || lc_delimiter
                          ||to_char(sysdate,'YYYY')  || lc_delimiter
                          ||lc_currency              || lc_delimiter
                          ||'OD'                     || lc_delimiter
                          ||R_EX.BUS_UNIT|| lc_delimiter
                          ||R_EX.SUPPLIER_NUM        || lc_delimiter
                          ||R_EX.SUPPLIER_SITE       || lc_delimiter
                          ||NULL                     || lc_delimiter
                          ||R_EX.SUPPLIER_NAME       || lc_delimiter
                          ||to_char(R_EX.CLR_PAY_DATE,'MM/DD/YYYY')
                                                     || lc_delimiter
                          ||'VCK'                    || lc_delimiter
                          ||'Open'                   || lc_delimiter
                          ||to_char(ln_amount,999999999999.99)
                                                     || lc_delimiter
                          ||'20104000'               || lc_delimiter
                          ||R_EX.ORG_DOC_NUM         || lc_delimiter
                          ||to_char(R_EX.ORG_PMT_DATE,'MM/DD/YYYY')
                                                     || lc_delimiter ;
              END IF;

              lc_print_line := lc_filerec;
              UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
        END LOOP;

        UTL_FILE.FFLUSH(g_FileHandle);
        UTL_FILE.FCLOSE(g_FileHandle);

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record count  = '|| lc_record_cnt);

        ---------------------------------------------------------
        lc_current_step  := 'UPDATE HISTORY STATUS To EXTRACTED';
        ---------------------------------------------------------
        UPDATE XX_AP_ESCHEAT_PAR_PMT_HIS
           SET process_status =  'EXTRACTED'
             ,EXTRACT_FILE_NAME = lc_output_file
             ,LAST_UPDATED_BY   = gn_user_id
             ,LAST_UPDATE_DATE  = SYSDATE
         WHERE  VOID_TYPE     =  p_void_type
           AND  org_id        = gn_org_id
           AND process_status =  'CLR_INFO_UPDATED';

        COMMIT;


   EXCEPTION
        WHEN NO_PAYMENTS_FOUND  THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Payments exist!');
            retcode := 0;

        WHEN utl_file.invalid_mode THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Mode Parameter');
            retcode := 1;

         WHEN utl_file.invalid_path THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid File Location');
            retcode := 1;

         WHEN utl_file.invalid_filehandle THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Filehandle');
            retcode := 1;

         WHEN utl_file.invalid_operation THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Operation');
            retcode := 1;

         WHEN utl_file.read_error THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Read Error');
            retcode := 1;

         WHEN utl_file.internal_error THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Internal Error');
            retcode := 1;

         WHEN utl_file.charsetmismatch THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,
                                   'utl_file.Opened With FOPEN_NCHAR ');
            retcode := 1;

         WHEN utl_file.file_open THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.File Already Opened');
            retcode := 1;

         WHEN utl_file.invalid_maxlinesize THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Line Size Exceeds 32K');
            retcode := 1;

         WHEN utl_file.invalid_filename THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid File Name');
            retcode := 1;

         WHEN utl_file.access_denied THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.File Access Denied By');
            retcode := 1;

         WHEN utl_file.invalid_offset THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,
                                           'utl_file.FSEEK Param Less Than 0');



         WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             IF SELECT_EXTRACT_REC%isopen THEN
                  CLOSE SELECT_EXTRACT_REC;
             END IF;

             retcode := 1;
             errbuff := lc_current_step;

    END CREATE_EXTACT_FILE_PROC;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |              Office Depot Organization                      |
    -- +===================================================================+
    -- | Name  : WRITE_EMAIL_OUTPUT                                        |
    -- | Description : Procedure will generate EMAIL output  Called from   |
    -- | FTP_FILE_PROC                                                     |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks                   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE WRITE_EMAIL_OUTPUT     (errbuff     OUT VARCHAR2
                                     ,retcode     OUT VARCHAR2
                                     ,p_void_type IN  VARCHAR2
                                     ,p_file_name IN  VARCHAR2
                                     )

    AS
        lc_current_step   VARCHAR2(500);
        lc_program_name   VARCHAR2(50);
        lc_email_Subj     VARCHAR2(250);
        lc_file_name      VARCHAR2(100);
        lc_ftp_dir        VARCHAR(200);
        lc_total_pay_amt  VARCHAR2(30);
        lc_total_func_amt VARCHAR2(30);
        lc_total_amt      VARCHAR2(30);
        ln_rec_count      NUMBER;
        lc_currency       VARCHAR(50);
        lc_source_value1  VARCHAR(30);

    BEGIN

        lc_program_name  := 'WRITE_EMAIL_OUTPUT';
        lc_current_step  := 'START';


        IF p_void_type = 'Escheat' THEN

             lc_source_value1 := 'OD_AP_ESCHEAT';

        ELSE
             lc_source_value1 := 'OD_AP_PAR';

        END IF;

        SELECT  nvl(b.TARGET_VALUE5,' No Directory Setup! ')
          INTO  lc_ftp_dir
          FROM XX_FIN_TRANSLATEDEFINITION a
              ,XX_FIN_TRANSLATEVALUES b
         WHERE translation_name = 'OD_FTP_PROCESSES'
           AND a.translate_id = b.translate_id
           AND b.source_value1 = lc_source_value1;


        FND_FILE.PUT_LINE(FND_FILE.LOG, lc_program_name||':'||lc_current_step);

        lc_file_name := p_file_name;

        SELECT ltrim(to_char(SUM(ORG_PAY_AMT),'$999,999,999.99'))
              ,ltrim(to_char(SUM(ORG_FUNC_AMT),'$999,999,999.99'))
          INTO lc_total_pay_amt
                 ,lc_total_func_amt
          FROM XX_AP_ESCHEAT_PAR_PMT_HIS
         WHERE PROCESS_STATUS     = 'EXTRACTED'
           AND   void_type        = p_void_type
           AND   org_id           = gn_org_id
           AND EXTRACT_FILE_NAME  = lc_file_name;


        SELECT  COUNT(1)
          INTO ln_rec_count
          FROM XX_AP_ESCHEAT_PAR_PMT_HIS
         WHERE PROCESS_STATUS     = 'EXTRACTED'
           AND   void_type        = p_void_type
           AND   org_id           = gn_org_id
           AND EXTRACT_FILE_NAME  = lc_file_name;

       --------------------------------------
       -- per defect 5721 removed code below
       -------------------------------------

       -- IF  gn_org_id = 404 THEN
       --        lc_currency  := 'USD';
       --        lc_total_amt := lc_total_pay_amt;
       -- ELSE
       --        lc_currency := 'CAD';
       --        lc_total_amt := lc_total_func_amt;
       -- END IF;

        lc_total_amt := lc_total_pay_amt;    -- per defect 5721 added code below

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_void_type|| ' file: '
                            || lc_file_name ||' has been successfully'||
                            ' created and FTP''d to ODSC02 '|| 'Location: '
                            || lc_ftp_dir);

       --------------------------------------
       -- per defect 5721 removed code below
       -------------------------------------

        -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'A total of '||lc_total_amt ||
        -- ' in functional Payment currency of '|| lc_currency || ' with '||
        -- ln_rec_count ||' number of records is in this file.');

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'A total of '||lc_total_amt ||
         ' is the payment amount. '||ln_rec_count ||' records are on the file.');

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Thank you.');

           retcode := 0;
  EXCEPTION
       WHEN NO_DATA_FOUND THEN

              errbuff := SUBSTR(gc_current_step ||chr(10)
                                        ||SQLERRM () ,1,99);
              retcode := 1;

       WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());
             retcode := 1;
             errbuff := lc_current_step ||' '|| SQLERRM ();

    END WRITE_EMAIL_OUTPUT ;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |              Office Depot Organization                      |
    -- +===================================================================+
    -- | Name  : FTP_EMAIL_PROC                                            |
    -- | Description : Procedure will FTP the extract files to the users   |
    -- |               server and generate output for the email notifi-    |
    -- |               cation                                              |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks                   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE FTP_FILE_PROC     (errbuff       OUT VARCHAR2
                                ,retcode       OUT VARCHAR2
                                ,p_void_type   IN VARCHAR2
                                ,p_extact_file IN VARCHAR2 DEFAULT NULL
                                )
    AS

        NO_FILE_FOUND             EXCEPTION;
        MULTI_REC_FOUND           EXCEPTION;
        FTP_ERROR                 EXCEPTION;
        EMAIL_OUTPUT_ERR          EXCEPTION;
        lc_current_step           VARCHAR2(500);
        lc_program_name           VARCHAR2(50);
        ln_req_id                 NUMBER;
        lc_ftp_process            VARCHAR2(50);
        lc_output_file            VARCHAR2(50);
        lc_extract_file           VARCHAR2(50);
        lc_submit_method          VARCHAR2(20);
        ln_record_cnt             NUMBER;
        lc_status_code            VARCHAR2(25);
        lc_warning_flg            VARCHAR2(1) := 'N';
        lc_error_flg              VARCHAR2(1) := 'N';
        ls_req_data               VARCHAR2(240);
        ln_request_id              NUMBER;
        request_status            BOOLEAN;
        p_errbuff                 VARCHAR2(1000);
        p_retcode                 NUMBER;

    BEGIN

      lc_program_name  := 'FTP_FILE_PROC';
      lc_current_step  := 'START';
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_program_name||':'||lc_current_step);


      ls_req_data := fnd_conc_global.request_data;
      ln_request_id := fnd_global.conc_request_id;

      lc_extract_file := p_extact_file;

       ---------------------------------------------------------
       lc_current_step := 'Checking only one extract file exist';
       ---------------------------------------------------------
          SELECT nvl(Count(DISTINCT EXTRACT_FILE_NAME),0)
            INTO ln_record_cnt
            FROM XX_AP_ESCHEAT_PAR_PMT_HIS
           WHERE PROCESS_STATUS     = 'EXTRACTED'
             AND void_type          = p_void_type
             AND org_id             = gn_org_id
             AND EXTRACT_FILE_NAME  = NVL(p_extact_file ,EXTRACT_FILE_NAME);

          IF  ln_record_cnt = 0 THEN
                 RAISE NO_FILE_FOUND;
          END IF;

          IF  ln_record_cnt > 1 THEN
                 RAISE MULTI_REC_FOUND;
          END IF;

          -------------------------------------------------
          lc_current_step := 'Getting extract files name';
          -------------------------------------------------
          SELECT distinct EXTRACT_FILE_NAME
            INTO lc_extract_file
            FROM XX_AP_ESCHEAT_PAR_PMT_HIS
           WHERE PROCESS_STATUS     = 'EXTRACTED'
             AND   void_type        = p_void_type
             AND   org_id           = gn_org_id
             AND EXTRACT_FILE_NAME  = NVL(p_extact_file ,EXTRACT_FILE_NAME);


      --------------------------------------------
      lc_current_step := 'Checking child status';
      --------------------------------------------
      -------------------------------------------------------
      -- If Statement to check the return status of FTP child
      -- ls_req_data is null before the parent program is
      -- place in pending status
      -------------------------------------------------------

      IF ls_req_data IS NOT NULL THEN


          SELECT status_code
            INTO lc_status_code
            FROM fnd_concurrent_requests
           WHERE parent_request_id = gn_request_id;

          IF ( lc_status_code = 'G' OR lc_status_code = 'X'
             OR lc_status_code ='D' OR lc_status_code ='T'  ) THEN

               lc_warning_flg := 'Y';

          ELSIF ( lc_status_code = 'E' ) THEN

               lc_error_flg := 'Y';

          END IF;

          IF lc_error_flg = 'Y' THEN

              FND_FILE.PUT_LINE(FND_FILE.LOG,
                          'Setting completion status to ERROR.');
              request_status :=
                       fnd_concurrent.set_completion_status('ERROR', '');
                       retcode := 2;
          ELSIF lc_warning_flg = 'Y' THEN

              FND_FILE.PUT_LINE(FND_FILE.LOG,
                           'Setting completion status to WARNING.');
              request_status :=
                       fnd_concurrent.set_completion_status('WARNING', '');
                       retcode := 1;
          ELSE

             WRITE_EMAIL_OUTPUT (p_errbuff
                                ,p_retcode
                                ,p_void_type
                                ,lc_extract_file);


              IF p_retcode <> 0 THEN

                   RAISE EMAIL_OUTPUT_ERR;

              END IF;

             ---------------------------------------
             -- Update History table to FTP COMPLETE
             ---------------------------------------
             UPDATE XX_AP_ESCHEAT_PAR_PMT_HIS
                SET PROCESS_STATUS = 'FTP COMPLETE'
                   ,LAST_UPDATED_BY   = gn_user_id
                   ,LAST_UPDATE_DATE  = SYSDATE
              WHERE PROCESS_STATUS    = 'EXTRACTED'
               AND   void_type        = p_void_type
               AND   org_id           = gn_org_id
               AND EXTRACT_FILE_NAME  = lc_extract_file;

              COMMIT;



              FND_FILE.PUT_LINE(FND_FILE.LOG,
                          'Setting completion status to NORMAL.');
              request_status :=
                       fnd_concurrent.set_completion_status('NORMAL', '');

          END IF;

          RETURN;

      END IF;

        -----------------------------------------------
        lc_current_step := 'Declaring Variables step:';
        -----------------------------------------------
        IF p_void_type  = 'Escheat'  THEN
             --set environment variables for Escheat voids
             lc_FTP_Process := 'OD_AP_ESCHEAT';
        ELSE
             --set environment variables for PAR voids
             lc_FTP_Process := 'OD_AP_PAR';

        END IF;



          -----------------------------------------------------------
          lc_current_step := 'Submit XXCOMFTP for: '||lc_extract_file;
          -----------------------------------------------------------
          ln_req_id := fnd_request.submit_request('XXFIN','XXCOMFTP',
                    '','01-OCT-04 00:00:00',TRUE, lc_FTP_process,
                       lc_extract_file , lc_extract_file,'Y' );

          COMMIT;

       -----------------------------------------------------------
       lc_current_step := 'Checking That XXCOMFTP is running ';
       -----------------------------------------------------------
       IF ln_req_id  > 0  THEN

            FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED',
                                 request_data => to_char(gn_request_id));
       ELSE
           RAISE  FTP_ERROR;
       END IF;

    EXCEPTION
        WHEN NO_FILE_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Extract file exists');
            retcode :=1;

        WHEN MULTI_REC_FOUND THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Too many records exist on the '
                              || 'XX_AP_ESCHEAT_PAR_PMT_HIS table for '
                              ||'processing.' );

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Please the review the '
                              || 'XX_AP_ESCHEAT_PAR_PMT_HIS table.'
                              || ' for the following conditions.' );

            FND_FILE.PUT_LINE(FND_FILE.LOG, ' PROCESS_STATUS = EXTRACTED');
            FND_FILE.PUT_LINE(FND_FILE.LOG, ' void_type      = '|| p_void_type);
            FND_FILE.PUT_LINE(FND_FILE.LOG, ' org_id         = '|| gn_org_id);
            retcode :=1;

       WHEN FTP_ERROR THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in process file');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'FTP program never was submitted!');
            retcode :=2;

       WHEN EMAIL_OUTPUT_ERR THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in Writing Email Output');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Output may not be created!');
            retcode :=1;

       WHEN OTHERS THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_current_step);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             retcode := 1;
             errbuff := lc_current_step;


    END FTP_FILE_PROC;

-- +===================================================================+
-- | Name  :SEND_EMAIL_OUTPUT                                          |
-- | Description      :  This local procedure will submit concurrent   |
-- |                     program XXODROEMAILER to email output file    |
-- |                                                                   |
-- | Parameters : p_request_id, p_void_type, p_email_addr_esc          |
-- |              p_email_addr_par                                     |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE SEND_EMAIL_OUTPUT (p_request_id       IN  NUMBER
                               ,p_void_type        IN VARCHAR2
                               ,p_email_addr_esc   IN VARCHAR2
                               ,p_email_addr_par   IN VARCHAR2
                               )
   IS
         SUBMIT_ERRORS     EXCEPTION;
         --------------------------
         -- Declare local variables
         --------------------------
         ln_conc_id               NUMBER;
         lb_bool                  BOOLEAN;
         lc_old_status            VARCHAR2(30);
         lc_phase                 VARCHAR2(100);
         lc_status                VARCHAR2(100);
         lc_dev_phase             VARCHAR2(100);
         lc_dev_status            VARCHAR2(100);
         lc_message               VARCHAR2(100);
         lc_temp_email            VARCHAR2(2000);
         lc_debug_msg             VARCHAR2(1000);
         lc_email_subject         VARCHAR2(500);


   BEGIN

      -------------------------------------
      lc_debug_msg :=  'Setting variables';
      -------------------------------------
      IF p_void_type = 'Escheat'  THEN

                 lc_email_subject := 'Alert_for_Abandoned_Property_Escheats_File'||
                                '_created_DO_NOT_REPLY_TO_THIS_MESSAGE';

            lc_temp_email    := p_email_addr_esc;

      ELSE
                lc_email_subject := 'Alert_for_PAR_File_created_DO_NOT_REPLY_TO_'||
                                'THIS_MESSAGE';

            lc_temp_email    := p_email_addr_par;

      END IF;

      ----------------------------------------------------------
      lc_debug_msg := 'Waiting for XX_AP_ESCH_PAR_FTP '
                         || 'void_type: '||p_void_type;
      ----------------------------------------------------------

      lb_bool := fnd_concurrent.wait_for_request(p_request_id
                                                  ,5
                                                  ,5000
                                                  ,lc_phase
                                                  ,lc_status
                                                  ,lc_dev_phase
                                                  ,lc_dev_status
                                                  ,lc_message
                                                   );


       IF ((lc_dev_phase = 'COMPLETE')
                AND (lc_dev_status = 'NORMAL')) THEN

                ---------------------------------------------------
                lc_debug_msg := 'Submitting XXODROEMAILER '
                                  || 'void_type: '||p_void_type;
                ---------------------------------------------------
                ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXODROEMAILER'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => TRUE
                                                ,argument1   => NULL
                                                ,argument2   => lc_temp_email
                                                ,argument3   => lc_email_subject
                                                ,argument4   => NULL
                                                ,argument5   => 'N'
                                                ,argument6   => p_request_id
                                                         );
               IF ln_conc_id > 0  THEN

                  UPDATE fnd_concurrent_requests
                     SET  phase_code = 'P',
                         status_code = 'I'
                   WHERE request_id = ln_conc_id;

                   COMMIT;

               ELSE

                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'SEND_EMAIL_OUTPUT procedure'
                                            ||' did not submit Emailer program:'
                                            ||' XXODROEMAILER successfully ' );

                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Please confirm that '||
                                                   'concurrent request '||
                                                    p_request_id ||
                                             ' generated output file correcly');

                   RAISE SUBMIT_ERRORS;

               END IF;

         ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG,
                           'Please confirm that concurrent request '||
                             p_request_id || ' generated a output file '||
                           'correctly Program ended with a status of '
                           || lc_dev_status);
               RAISE SUBMIT_ERRORS;

         END IF;


         ----------------------------------------------------------
         lc_debug_msg := 'Waiting for XXODROEMAILER '
                         || 'void_type: '||p_void_type;
         ----------------------------------------------------------

         lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                       ,5
                                                       ,5000
                                                       ,lc_phase
                                                       ,lc_status
                                                       ,lc_dev_phase
                                                       ,lc_dev_status
                                                       ,lc_message
                                                   );


         IF ((lc_dev_phase = 'COMPLETE')
                AND (lc_dev_status = 'NORMAL')) THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG, 'XXODROEMAILER completed'
                                                 || ' successfully ' );

         ELSE

                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request:'||ln_conc_id
                                               ||'XXODROEMAILER error '
                                                  || lc_message);

         END IF;

         EXCEPTION
           WHEN  SUBMIT_ERRORS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error: '|| lc_debug_msg );

           WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error: '|| lc_debug_msg );


   END SEND_EMAIL_OUTPUT;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |              Office Depot Organization                      |
    -- +===================================================================+
    -- | Name  : MASTER_EXTRACT_PROC                                       |
    -- | Description : Procedure is the master program for submitting the  |
    -- |               all extract programs                                |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks                       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE MASTER_EXTRACT_PROC (errbuff           OUT VARCHAR2
                                   ,retcode          OUT VARCHAR2
                                   ,p_email_addr_esc IN VARCHAR2
                                   ,p_email_addr_par IN VARCHAR2)
    AS

      SUBMIT_ERRORS     EXCEPTION;
      EXTRACT_ERRORS    EXCEPTION;

      lc_current_step    VARCHAR2(500);
      lc_program_name    VARCHAR2(50);
      ln_conc_id1        NUMBER;
      ln_conc_id2        NUMBER;

      ln_thread_count     NUMBER;
      ln_conc_request_id  NUMBER := NULL;
      ls_req_data         VARCHAR2(240);
      ln_request_id       NUMBER;        -- parent request id
      cnt_warnings        INTEGER := 0;
      cnt_errors          INTEGER := 0;
      request_status      BOOLEAN;

      call_status         BOOLEAN;
      rphase              VARCHAR2(80);
      rstatus             VARCHAR2(80);
      dphase              VARCHAR2(30);
      dstatus             VARCHAR2(30);
      message             VARCHAR2(240);

      lb_bool1            boolean;
      lc_phase1           VARCHAR2(80);
      lc_status1          VARCHAR2(80);
      lc_dev_phase1       VARCHAR2(30);
      lc_dev_status1      VARCHAR2(30);
      lc_message1         VARCHAR2(240);

      lb_bool2             BOOLEAN;
      lc_phase2            VARCHAR2(80);
      lc_status2           VARCHAR2(80);
      lc_dev_phase2        VARCHAR2(30);
      lc_dev_status2       VARCHAR2(30);
      lc_message2          VARCHAR2(240);

      lc_records_found     VARCHAR2(1);

      ln_application_id    NUMBER;
      ln_pub_request_id    NUMBER;

      lb_prt_result        BOOLEAN;
    BEGIN

      lc_program_name  := 'MASTER_EXTRACT_PROC';
      lc_current_step  := 'START';
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_program_name||':'||lc_current_step);

      ls_req_data := fnd_conc_global.request_data;
      ln_request_id := fnd_global.conc_request_id;

       SELECT APP.application_id
         INTO   ln_application_id
         FROM   fnd_application_vl APP
               ,fnd_concurrent_programs FCP
               ,fnd_concurrent_requests R
         WHERE  FCP.concurrent_program_id = R.concurrent_program_id
         AND    R.request_id = ln_request_id
         AND    APP.application_id = FCP.application_id;

    lc_records_found :='N';

    ------------------------------------------------------------
    lc_current_step  := 'Checking For Payments ';
    ------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Application Id'||':'||ln_application_id);  -- Added by Sravanthi on July 10-2013 for Testing
    FND_FILE.PUT_LINE(FND_FILE.LOG, lc_records_found||':'||lc_current_step);    -- Added by Sravanthi on July 10-2013 for Testing

    FOR void_type IN (SELECT --/*+ leading(ai) index(ai AP_INVOICES_N3) */ --Commented as per Defect 44664
								DISTINCT PH.VOID_TYPE -- Changes for defect 28382 21-Feb-14
                      FROM XX_AP_ESCHEAT_PAR_PMT_HIS PH
                          ,XX_AP_ESCHEAT_PAR_INV_HIS IH
                          ,AP_INVOICES AI
                          ,AP_INVOICE_PAYMENTS IP
                          ,AP_CHECKS_V AC
                     WHERE  PH.process_status          = 'SELECTED'
                       AND  PH.org_id                  =  gn_org_id
                        AND  PH.org_check_id            = IH.org_check_id
                       AND  AI.invoice_id              = IH.invoice_id
                       AND  AI.pay_group_lookup_code  IN ('US_OD_PAR'
                                                         ,'US_OD_ESCHEAT_CLEAR')
                        AND  AI.invoice_id              = IP.invoice_id
                      AND  IP.check_id                = AC.check_id
                       AND  AC.status_lookup_code      = 'NEGOTIABLE')


    LOOP


       lc_records_found :='Y';

       ------------------------------------------------------------
       lc_current_step  := 'Submitting XX_AP_ESCH_PAR_EXTRACT '
                             || 'void_type: '||void_type.VOID_TYPE;
       ------------------------------------------------------------
       ln_conc_id1 :=fnd_request.submit_request
                 ('XXFIN','XX_AP_ESCH_PAR_EXTRACT',
                 '','01-OCT-04 00:00:00',TRUE, void_type.VOID_TYPE);

       IF ln_conc_id1 > 0  THEN

           UPDATE fnd_concurrent_requests
              SET  phase_code = 'P', status_code = 'I'
            WHERE request_id = ln_conc_id1;

           COMMIT;
           -------------------------------------------------------
           lc_current_step  := 'Waiting for XX_AP_ESCH_PAR_EXTRACT '
                                || 'void_type: '||void_type.VOID_TYPE;
           --------------------------------------------------------
           lb_bool1 := fnd_concurrent.wait_for_request
                                       (ln_conc_id1
                                       ,5
                                       ,5000
                                       ,lc_phase1
                                       ,lc_status1
                                       ,lc_dev_phase1
                                       ,lc_dev_status1
                                       ,lc_message1
                                        );

          ----------------------------------------------------------------
          lc_current_step  := 'Checking status of XX_AP_ESCH_PAR_EXTRACT ';
          ----------------------------------------------------------------
          IF ((lc_dev_phase1 = 'COMPLETE')
                AND (lc_dev_status1 = 'NORMAL')) THEN

               -------------------------------------------------------
               lc_current_step  := 'Submitting XX_AP_ESCH_PAR_FTP ';
               --------------------------------------------------------
               ln_conc_id1 :=fnd_request.submit_request
                      ('XXFIN','XX_AP_ESCH_PAR_FTP',
                      '','01-OCT-04 00:00:00',TRUE, void_type.VOID_TYPE,NULL );

               IF ln_conc_id1 > 0  THEN

                  UPDATE fnd_concurrent_requests
                     SET  phase_code = 'P',
                         status_code = 'I'
                   WHERE request_id = ln_conc_id1;

                   COMMIT;

                  -------------------------------------------------------
                  lc_current_step  := 'Calling SEND_EMAIL_OUTPUT ';
                  --------------------------------------------------------


                  SEND_EMAIL_OUTPUT (ln_conc_id1
                                    ,void_type.VOID_TYPE
                                    ,p_email_addr_esc
                                    ,p_email_addr_par
                                    ) ;

                  -------------------------------------------------------
                  lc_current_step  := 'Submitting XXAPACTESC Report ';
                  --------------------------------------------------------
                  ln_conc_id2 :=fnd_request.submit_request
                       ('XXFIN','XXAPACTESC',
                       '','01-OCT-04 00:00:00',TRUE, void_type.VOID_TYPE
                        ,NULL,NULL,'BATCH' );

                  IF ln_conc_id2 > 0  THEN

                      UPDATE fnd_concurrent_requests
                         SET  phase_code = 'P',
                              status_code = 'I'
                       WHERE request_id = ln_conc_id2;

                      COMMIT;
                      -------------------------------------------------------
                      lc_current_step  := 'Waiting for XXAPACTESC Report '
                                       || 'void_type: '||void_type.VOID_TYPE;
                      --------------------------------------------------------
                      lb_bool2 := fnd_concurrent.wait_for_request
                                              (ln_conc_id2
                                               ,5
                                               ,5000
                                               ,lc_phase2
                                               ,lc_status2
                                               ,lc_dev_phase2
                                               ,lc_dev_status2
                                               ,lc_message2
                                               );




                      lb_prt_result := FND_REQUEST.SET_PRINT_OPTIONS
                                              ('XPTR'         --printer name
                                               ,'LANDSCAPE'   --style
                                               ,1
                                               ,TRUE
                                               ,'N');


             ---- Commented By Sravanthi on 8/7/2013 as part of R12 Retrofit             -----------
                     /* -------------------------------------------------------
                      lc_current_step  := 'Submitting XML Publisher Program ';
                      --------------------------------------------------------
                      ln_pub_request_id := fnd_request.submit_request
                                           ('XDO'                      --- application sort name
                                           ,'XDOREPPB'                 --- program short name
                                           ,NULL                       --- description
                                           ,NULL                       --- start_time
                                           ,TRUE                       --- sub_request
                                           ,ln_conc_id2                ---  Request_Id of Previous Program
                                           ,ln_application_id          ---  Application_id=20043
                                           ,'XXAPACTESC'  --template_code,   --- Template Code
                                           ,'en-US'  --language,             --- Language
                                           ,'N'                              --- Dummy for Data Security
                                           ,'RTF'--template_type,            --- Template Type
                                           ,'PDF'--output type               --- Output Type
                                           ,chr(0)
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'',''
                                          );    */                                                   
                    -----                     Comment Ends ----------                                      

            ----------          Added By Sravanthi on 8/7/2013 as part of r12 Upgrade as per Concurrent program Definition for XML Report Publisher in R12  ---------------------
                       -------------------------------------------------------
                      lc_current_step  := 'Submitting XML Publisher Program ';
                      --------------------------------------------------------
                      ln_pub_request_id := fnd_request.submit_request
                                           ('XDO'                      --- application sort name
                                           ,'XDOREPPB'                 --- program short name
                                           ,NULL                       --- description
                                           ,NULL                       --- start_time
                                           ,TRUE                       --- sub_request
                                           ,'N'                        --- Dummy for Data Security
                                           ,ln_conc_id2                ---  Request_Id of Previous Program
                                           ,ln_application_id          ---  Template Application_id=20043
                                           ,'XXAPACTESC'               --- Template Code
                                           ,'en-US'                    ---  Template Locale
                                           , 'N'                       ---  Debug Flag
                                           ,'RTF'--template_type,      --- Template Type
                                           ,'PDF'--output type         --- Output Type
                                           ,chr(0)
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                           ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,'','','','','','','','','',''
                                          ,''
                                          );


                      IF ln_pub_request_id > 0  THEN

                          UPDATE fnd_concurrent_requests
                             SET phase_code = 'P',
                                 status_code = 'I'
                           WHERE request_id = ln_pub_request_id;

                           COMMIT;
                          ------------------------------------------------------
                          lc_current_step := 'Wating for XML Publisher Program';
                          ------------------------------------------------------
                          lb_bool2 := fnd_concurrent.wait_for_request
                                          (ln_pub_request_id
                                           ,5
                                           ,5000
                                          ,lc_phase2
                                          ,lc_status2
                                          ,lc_dev_phase2
                                          ,lc_dev_status2
                                          ,lc_message2
                                          );

                          ------------------------------------------------------
                          lc_current_step  := 'Updating status to processed ';
                          ------------------------------------------------------
                          IF ((lc_dev_phase2 = 'COMPLETE')
                                   AND (lc_dev_status2 = 'NORMAL')) THEN

                             UPDATE XX_AP_ESCHEAT_PAR_PMT_HIS
                                SET process_status    = 'PROCESSED'
                                   ,LAST_UPDATED_BY   = gn_user_id
                                   ,LAST_UPDATE_DATE  = SYSDATE
                              WHERE void_type = void_type.VOID_TYPE
                                AND Process_status = 'FTP COMPLETE'
                                AND  ORG_ID =  gn_org_id;

                             COMMIT;
                           END IF;

                      ELSE

                            FND_FILE.PUT_LINE(FND_FILE.LOG,
                                   'XML Publisher Program failed to submit');
                            RAISE SUBMIT_ERRORS;
                      END IF;

                  ELSE
                      FND_FILE.PUT_LINE(FND_FILE.LOG,
                            'XXAPACTESC Report failed to submit');
                      RAISE SUBMIT_ERRORS;
                  END IF;


               ELSE

                    FND_FILE.PUT_LINE(FND_FILE.LOG,
                       'XX_AP_ESCH_PAR_FTP program failed to submit');
                    RAISE SUBMIT_ERRORS;

               END IF;

          ELSE

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AP_ESCH_PAR_EXTRACT '
                             ||'Complete with Status = ' ||lc_dev_status1
                             ||'Request_ID = '||ln_conc_id1 );
          END IF;

       ELSE

            FND_FILE.PUT_LINE(FND_FILE.LOG,
                  'XX_AP_ESCH_PAR_EXTRACT program failed to submit');
            RAISE SUBMIT_ERRORS;

       END IF;

  END LOOP;

  -------------------------------------------------------
  -- Check all child requests to see how they finished...
  -------------------------------------------------------
  FOR child_request_rec IN (SELECT request_id, status_code
                              FROM fnd_concurrent_requests
                             WHERE parent_request_id = ln_request_id)
     LOOP

        call_status := FND_CONCURRENT.get_request_status(
                           child_request_rec.request_id,
                           '','', rphase, rstatus, dphase,
                            dstatus, message);

               IF ((dphase = 'COMPLETE') AND (dstatus = 'NORMAL')) THEN

                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'child request id: '
                             || child_request_rec.request_id
                             || ' completed successfully');
               ELSE

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error A2:'||lc_current_step);
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'child request id: '
                             || child_request_rec.request_id
                             || ' did not complete successfully');
               END IF;

               IF ( child_request_rec.status_code = 'G'
                   OR child_request_rec.status_code = 'X'
                   OR child_request_rec.status_code ='D'
                   OR child_request_rec.status_code ='T'  ) THEN

                      cnt_warnings := cnt_warnings + 1;

               ELSIF ( child_request_rec.status_code = 'E' ) THEN

                      cnt_errors := cnt_errors + 1;

               END IF;

             END LOOP; -- FOR child_request_rec

             IF cnt_errors > 0 THEN
                      request_status :=
                        fnd_concurrent.set_completion_status('ERROR', '');

              ELSIF cnt_warnings > 0 THEN
                      request_status :=
                       fnd_concurrent.set_completion_status('WARNING', '');
              ELSE
                      request_status :=
                       fnd_concurrent.set_completion_status('NORMAL', '');

              END IF;



    IF lc_records_found = 'N' THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Records Found for processing!');

    END IF;


    EXCEPTION

      WHEN EXTRACT_ERRORS THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT Submission Error'
                      || SQLERRM ());
           retcode := 2;
           errbuff := lc_current_step;


      WHEN  SUBMIT_ERRORS THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT Submission Error'
                      || SQLERRM ());
           retcode := 2;
           errbuff := lc_current_step;

       WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

             retcode := 1;
             errbuff := lc_current_step;

    END MASTER_EXTRACT_PROC;

END XX_AP_ESCHEAT_PKG;
/
