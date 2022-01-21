CREATE OR REPLACE PACKAGE BODY XX_AR_CUST_REBATE_PAY_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name     :  Customer Rebate pay adjustment API                            |
-- | Rice id  :  EXXXX                                                         |
-- | Description : TO identify the valid Short Paid Invoices and creating      |
-- |               an adjustment for the percentage discount customer is       |
-- |               eligible.                                                   |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date              Author              Remarks                    |
-- |======   ==========     =============        ============================= |
-- |1.0      03-MAY-2012    Bapuji Nanapaneni    Initial version for Defect    |
-- |                                             17760                         |
-- |1.1      23-MAY2012     Bapuji Nanapaneni    using cursor instead of       |
-- |                                             VALIDATE_DIS_CUST             |
-- |1.2      05-JUL-2012    Bapuji Nanapaneni    Changes for Defect#19328      |
-- |1.3      09-AUG-2012    Bapuji Nanapaneni    Changes for Defect#19374      |
-- |1.4      27-AUG-2013    Jagadeesh S          Modified for retrofit R12     |
-- |1.5      26-SEP-2013    Jagadeesh S          Removed ar_sytem_parameters.attribut7|
-- |                                             from cursor c_short_paid_invoices|
-- +===========================================================================+
-- +==========================================================================+
-- | Name : NOTIFY                                                            |
-- | Description :   TO Identify the valid Short Paid Invoices and create     |
-- |                 adjustment  for the qualified  percentage discount       |
-- |                                                                          |
-- | Parameters :   p_receipt_date_from p_receipt_date_to                     |
-- |                                                                          |
-- | Returns    :    x_error_buff,x_ret_code                                  |
-- +==========================================================================+
   PROCEDURE NOTIFY( x_error_buff          OUT  VARCHAR2
                   , x_ret_code            OUT  NUMBER
                   , p_receipt_date_from   IN   VARCHAR2
                   , p_receipt_date_to     IN   VARCHAR2
                   ) AS
      ld_request_date               fnd_concurrent_requests.request_date%TYPE;
      lc_concurrent_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      lc_error_loc                  VARCHAR2(2000);
      lc_error_debug                VARCHAR2(2000);
      lc_loc_err_msg                VARCHAR2(2000);
      lcu_short_paid_invoices       VARCHAR2(2000);
      lc_return_status              VARCHAR2(2000);
      lc_message_data               VARCHAR2(2000);
      lc_drt_found                  VARCHAR2(1):= 'Y';
      ln_message_count              NUMBER;
      lc_msg_data                   VARCHAR2(2000);
      lc_activity_name              ar_receivables_trx_all.name%TYPE;
      ln_percentage                 NUMBER := 0;
      ln_remaining_due_amt          NUMBER := 0;
      ln_discount_amount            NUMBER := 0;
      ln_rec_trx_id                 NUMBER := 0;
      ln_adj_amount                 NUMBER := 0;
      ln_applied_amount             NUMBER := 0;
      ln_invoice_amount             NUMBER := 0;
      ln_amt_due_remaining          NUMBER := 0;
      ln_set_of_books_id            NUMBER;
      lr_inp_adj_rec                ar_adjustments%ROWTYPE;
      ln_adj_number                 VARCHAR2(30);
      ln_adj_id                     NUMBER;
      ln_adj_count                  NUMBER;
      ln_total_records              NUMBER := 0;
      ln_success_records            NUMBER := 0;
      ln_failed_records             NUMBER := 0;
       ld_receipt_date_from          DATE;
      ln_adj_amt                    NUMBER := 0;
      lc_adj_comments               ar_adjustments_all.comments%TYPE;
      ln_act_count                  NUMBER := 0;

      CURSOR c_short_paid_invoices ( p_receipt_date_from   DATE
                                   )IS
      /*SELECT /*+ LEADING(ASP ARA RCT ACR) ACR.receipt_date
           , ACR.receipt_number
           , ARA.amount_applied
           , RCT.trx_number
           , RCT.invoice_currency_code
           , ACR.currency_code
           , HCA.account_number
           , HCA.cust_account_id
           , SUM(RCTL.extended_amount) INVOICEAMOUNT
           , RCT.bill_to_site_use_id
           , HP.party_name
           , HP.party_id
           , APS.acctd_amount_due_remaining
           , RTT.type class
           , APS.payment_schedule_id
           , RCT.customer_trx_id
           , TO_NUMBER(ASP.attribute7) flat_amount_val
         FROM ar_cash_receipts ACR
           , ar_payment_schedules APS
           , ar_receivable_applications ARA
           , ra_customer_trx RCT
           , ra_customer_trx_lines RCTL
           , hz_cust_accounts HCA
           , ar_system_parameters ASP
           , hz_customer_profiles HCP
           , hz_parties  HP
           , ra_cust_trx_types_all RTT      -- Added for the Defect ID : 17760
       WHERE ARA.creation_date BETWEEN NVL(p_receipt_date_from,ld_request_date) AND
             NVL(TO_DATE(p_receipt_date_to,'YYYY/MM/DD HH24:MI:SS'),SYSDATE)
            -- TO_DATE(TO_CHAR(TO_DATE(p_receipt_date_to,'DD-MON-RRRR HH24:MI:SS'),'DD-MON-RRRR') || '23:59:59','DD-MON-RRRR HH24:MI:SS')
         AND ARA.status                     = 'APP'
         AND HCP.site_use_id IS  NULL
         AND ARA.cash_receipt_id            = ACR.cash_receipt_id
         AND ARA.applied_customer_trx_id    = RCT.customer_trx_id
         AND RCT.cust_trx_type_id           = RTT.cust_trx_type_id
         AND RCT.customer_trx_id            = RCTL.customer_trx_id
         AND APS.customer_id                = HCA.cust_account_id
         AND APS.customer_trx_id            = RCT.customer_trx_id
       --  AND APS.acctd_amount_due_remaining > TO_NUMBER(ASP.attribute7) --defect 17760
         AND ((APS.acctd_amount_due_remaining > 0 and APS.class = 'INV') OR ( APS.acctd_amount_due_remaining < 0 and APS.class = 'CM')) -- defect 17760
         AND HCA.cust_account_id            = HCP.cust_account_id
         AND HP.party_id                    = HCA.party_id
         AND ARA.display                    = 'Y'
     GROUP BY ACR.receipt_date
            ,ACR.receipt_number
            ,ARA.amount_applied
            ,RCT.bill_to_site_use_id
            ,RCT.trx_number
            ,HCA.account_number
            ,HCA.cust_account_id
            ,HP.party_name
            ,HP.party_id
            ,APS.acctd_amount_due_remaining
            ,RCT.invoice_currency_code
            ,ACR.currency_code
            ,RTT.type
            ,APS.payment_schedule_id
            ,RCT.customer_trx_id
            ,TO_NUMBER(ASP.attribute7);  */  -- Cursor Commented for Retrofit to R12

      -- Modified cursor query for Retrofit to R12                                              
      SELECT /*+ LEADING(ASP ARA RCT ACR) */ACR.receipt_date  
           , ACR.receipt_number
           , ARA.amount_applied
           , RCT.trx_number
           , RCT.invoice_currency_code
           , ACR.currency_code
           , HCA.account_number
           , HCA.cust_account_id
           , (SELECT SUM(RCTL.extended_amount)  -- Modified to remove group by for retrofit to R12
              FROM  ra_customer_trx_lines RCTL
              WHERE RCT.customer_trx_id = RCTL.customer_trx_id) INVOICEAMOUNT
           , RCT.bill_to_site_use_id
           , HP.party_name
           , HP.party_id
           , APS.acctd_amount_due_remaining
           , RTT.type class
           , APS.payment_schedule_id
           , RCT.customer_trx_id  
         FROM ar_cash_receipts ACR
           , ar_payment_schedules APS
           , ar_receivable_applications ARA
           , ra_customer_trx RCT           
           , hz_cust_accounts HCA           
           , hz_customer_profiles HCP
           , hz_parties  HP
           , ra_cust_trx_types_all RTT      -- Added for the Defect ID : 17760
       WHERE ARA.creation_date BETWEEN NVL(p_receipt_date_from,ld_request_date) AND
             NVL(TO_DATE(p_receipt_date_to,'YYYY/MM/DD HH24:MI:SS'),SYSDATE)
            -- TO_DATE(TO_CHAR(TO_DATE(p_receipt_date_to,'DD-MON-RRRR HH24:MI:SS'),'DD-MON-RRRR') || '23:59:59','DD-MON-RRRR HH24:MI:SS')
         AND ARA.status                     = 'APP'
         AND HCP.site_use_id IS  NULL
         AND ARA.cash_receipt_id            = ACR.cash_receipt_id
         AND ARA.applied_customer_trx_id    = RCT.customer_trx_id
         AND RCT.cust_trx_type_id           = RTT.cust_trx_type_id         
         AND APS.customer_id                = HCA.cust_account_id
         AND APS.customer_trx_id            = RCT.customer_trx_id       
         AND ((APS.acctd_amount_due_remaining > 0 and APS.class = 'INV') OR ( APS.acctd_amount_due_remaining < 0 and APS.class = 'CM')) -- defect 17760
         AND HCA.cust_account_id            = HCP.cust_account_id
         AND HP.party_id                    = HCA.party_id
         AND ARA.display                    = 'Y';

      CURSOR C_ACT_NAME ( p_customer_number IN VARCHAR2 ) IS
      SELECT xftv.target_value1 percentage
           , xftv.target_value2 activate_name
           , xftv.target_value3 sequence
        FROM xx_fin_translatedefinition xftd
           , xx_fin_translatevalues xftv
       WHERE xftd.translate_id              = xftv.translate_id
         AND xftd.translation_name          = 'FLAT_DISCOUNTS'
         AND xftv.source_value1             = p_customer_number
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.ENABLED_FLAG              = 'Y'
         AND xftd.enabled_flag              = 'Y'
      ORDER BY TO_NUMBER(xftv.target_value3) ASC; -- Defect#19374

   BEGIN

      --Printing the Parameters
      lc_error_loc   := 'Printing the Parameters of the program';
      lc_error_debug := '';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date From  : ' ||p_receipt_date_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Date To    : ' ||p_receipt_date_to);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');


      --To Get the  Concurrent Program Name
      lc_error_loc   := 'Get the Concurrent Program Name:';
      lc_error_debug := 'Concurrent Program id: '||FND_GLOBAL.CONC_PROGRAM_ID;
      SELECT user_concurrent_program_name
        INTO lc_concurrent_program_name
        FROM fnd_concurrent_programs_tl
       WHERE concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
         AND language              = USERENV('LANG');

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program name: '||lc_concurrent_program_name);
       --To Get the  Last Successfull Run Date of OD: AR Identify Short Pay
      BEGIN
          lc_error_loc   := 'Get the Last Successfull Run Date of the OD: AR Identify Short Pay';
          lc_error_debug := 'Phase code: C -- Status Code: C ';
         SELECT MAX(actual_start_date)   -- Added for the Defect ID : 17760
           INTO ld_request_date
           FROM fnd_concurrent_requests
          WHERE concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
            AND status_code           = 'C'
            AND phase_code            = 'C';
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
             SELECT SYSDATE INTO ld_request_date FROM DUAL;
             --FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0002_CONC_PROGRAM_ERROR');
             --lc_loc_err_msg :=  FND_MESSAGE.GET;
             --FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'This is the first execution of this program');
          WHEN OTHERS THEN
             FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
             FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
             FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
             FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
             lc_loc_err_msg :=  FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
             XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type            => 'CONCURRENT PROGRAM'
                                            , p_program_name            => lc_concurrent_program_name
                                            , p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            , p_module_name             => 'AR'
                                            , p_error_location          => 'Error at ' || lc_error_loc
                                            , p_error_message_count     => 1
                                            , p_error_message_code      => 'E'
                                            , p_error_message           => lc_loc_err_msg
                                            , p_error_message_severity  => 'Major'
                                            , p_notify_flag             => 'N'
                                            , p_object_type             => 'Short Pay'
                                            );
      END;
      SELECT TO_DATE(p_receipt_date_from,'YYYY/MM/DD HH24:MI:SS') INTO ld_receipt_date_from FROM DUAL;
      FOR lcu_short_paid_invoices IN c_short_paid_invoices (ld_receipt_date_from)
      LOOP
           ln_total_records := ln_total_records + 1;
          ln_act_count     := 0;
          ln_adj_amt       := 0;
          /**************************************DEFECT 17760 BEGIN************************************************/
           -- Need to check for CM
          /* Added Logic to create Adjustments for flat discount customers --NB */
          IF lcu_short_paid_invoices.class = 'CM' THEN
              ln_applied_amount    := (-1*lcu_short_paid_invoices.amount_applied);
              ln_invoice_amount    := (-1*lcu_short_paid_invoices.invoiceamount);
              ln_amt_due_remaining := (-1*lcu_short_paid_invoices.acctd_amount_due_remaining);
          ELSE
              ln_applied_amount    := lcu_short_paid_invoices.amount_applied;
              ln_invoice_amount    := lcu_short_paid_invoices.invoiceamount;
              ln_amt_due_remaining := lcu_short_paid_invoices.acctd_amount_due_remaining;
          END IF;
                  IF ln_applied_amount < ln_invoice_amount THEN
         
              FOR R_ACT_NAME IN C_ACT_NAME (lcu_short_paid_invoices.account_number) LOOP
                  --Commented out as we get more then one adjustment per customer
                  /* validate_dis_cust( p_customer_number => lcu_short_paid_invoices.account_number
                                      , x_activity_name   => lc_activity_name
                                      , x_dis_percentage  => ln_percentage
                                      );
                  */
                  ln_act_count := ln_act_count +1;
                  lc_activity_name := R_ACT_NAME.activate_name;
                  ln_percentage    := R_ACT_NAME.percentage;
                  IF ln_percentage > 0 THEN
                      ln_discount_amount := ROUND(((ln_invoice_amount * ln_percentage)/100),2);
                                  -- IF ln_act_count = 1 THEN
                       --   ln_adj_amt := ln_amt_due_remaining - ln_discount_amount;
                     -- END IF;
                      IF ln_act_count >= 2 THEN
                          ln_amt_due_remaining := ln_adj_amt;
                                                 -- Added below condition for DEFECT 19328
                          IF ln_remaining_due_amt = 0 THEN
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_amt_due_remaining IS 0 So skip adjustment');
                              GOTO END_OF_LOOP;
                          END IF;
                      END IF;

                     -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_amt_due_remaining 1 : '||ln_amt_due_remaining);

                      IF ln_amt_due_remaining <= ln_discount_amount THEN
                          ln_adj_amount        := ln_amt_due_remaining;
                          ln_remaining_due_amt := 0;
                      ELSE
                          ln_adj_amount        := ln_discount_amount;
                          ln_remaining_due_amt := (ln_amt_due_remaining - ln_discount_amount);
                      END IF;
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_remaining_due_amt : '||ln_remaining_due_amt);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_adj_amount        : '|| ln_adj_amount);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_amt_due_remaining : '||ln_amt_due_remaining);
                      --Create Auto Adjustment
                      /* Activity Name */
                      SELECT receivables_trx_id
                        INTO ln_rec_trx_id
                        FROM ar_receivables_trx_all
                       WHERE UPPER(NAME) = UPPER(lc_activity_name);

                      SELECT COUNT(*)
                        INTO ln_adj_count
                        FROM ar_adjustments_all
                       WHERE customer_trx_id    = lcu_short_paid_invoices.customer_trx_id
                         AND receivables_trx_id = ln_rec_trx_id;
                      IF ln_adj_count = 0 THEN
                          ln_adj_amt := ln_amt_due_remaining - ln_discount_amount;
                          /* Set of Books id */
                          ln_set_of_books_id := fnd_profile.value('GL_SET_OF_BKS_ID');
                          IF lcu_short_paid_invoices.class = 'INV' THEN
                              lr_inp_adj_rec.acctd_amount         := (-1 * ln_adj_amount);
                              lr_inp_adj_rec.amount               := (-1 * ln_adj_amount);
                          ELSE
                              lr_inp_adj_rec.acctd_amount         := ln_adj_amount;
                              lr_inp_adj_rec.amount               := ln_adj_amount;
                          END IF;
                          lr_inp_adj_rec.adjustment_id        := NULL;
                          lr_inp_adj_rec.adjustment_number    := NULL;
                          lr_inp_adj_rec.adjustment_type      := 'M';
                          lr_inp_adj_rec.created_by           := FND_GLOBAL.USER_ID;
                          lr_inp_adj_rec.created_from         := 'XX_AR_CUST_REBATE_PAY_PKG';
                          lr_inp_adj_rec.creation_date        := SYSDATE;
                          lr_inp_adj_rec.gl_date              := SYSDATE;
                          lr_inp_adj_rec.last_update_date     := SYSDATE;
                          lr_inp_adj_rec.last_updated_by      := FND_GLOBAL.USER_ID;
                          lr_inp_adj_rec.posting_control_id   := -3;         /* -1,-2,-4 for posted in previous rel and -3 for not posted */
                          lr_inp_adj_rec.set_of_books_id      := ln_set_of_books_id;
                          lr_inp_adj_rec.status               := 'A';
                          lr_inp_adj_rec.type                 := 'LINE';     /* ADJ TYPE CHARGES,FREIGHT,INVOICE,LINE,TAX */
                          lr_inp_adj_rec.payment_schedule_id  := lcu_short_paid_invoices.payment_schedule_id;
                          lr_inp_adj_rec.apply_date           := SYSDATE;
                          lr_inp_adj_rec.receivables_trx_id   := ln_rec_trx_id;
                          lr_inp_adj_rec.customer_trx_id      := lcu_short_paid_invoices.customer_trx_id;
                          lr_inp_adj_rec.comments             := 'FLAT DISCOUNT';
                          lr_inp_adj_rec.reason_code          := 'DISCOUNT';

                          ar_adjust_pub.create_adjustment ( p_api_name             => 'XX_AR_CUST_REBATE_PAY_PKG'
                                                          , p_api_version          => 1.0
                                                          , p_init_msg_list        => FND_API.G_TRUE
                                                          , p_commit_flag          => FND_API.G_TRUE
                                                          , p_validation_level     => FND_API.G_VALID_LEVEL_FULL
                                                          , p_msg_count            => ln_message_count
                                                          , p_msg_data             => lc_message_data
                                                          , p_return_status        => lc_return_status
                                                          , p_adj_rec              => lr_inp_adj_rec
                                                          , p_chk_approval_limits  => NULL
                                                          , p_check_amount         => NULL
                                                          , p_move_deferred_tax    => 'Y'
                                                          , p_new_adjust_number    => ln_adj_number
                                                          , p_new_adjust_id        => ln_adj_id
                                                          , p_called_from          => NULL
                                                          , p_old_adjust_id        => NULL
                                                          );
                          IF lc_return_status = 'S' THEN
                              ln_success_records := ln_success_records + 1;
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Customer Number ',30,' ')||' '||RPAD('Customer Name ',80,' ')||' ' ||RPAD('Invoice Number ',20,' ')||' '||RPAD('Adjustment Number ',20,' ')||' '||'Adjusted Amount ');
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_short_paid_invoices.account_number,30,' ')||' '||RPAD(lcu_short_paid_invoices.party_name,80,' ')||' '||RPAD(lcu_short_paid_invoices.trx_number,20,' ')||' '||RPAD(ln_adj_number,20,' ')||' '|| lr_inp_adj_rec.amount);
                              --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Auto Adjustment is created aganist AdjustmentID : '|| ln_adj_id);
                              --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Number    : '||lcu_short_paid_invoices.trx_number);
                              --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Adjustment Number : '||ln_adj_number);
                              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------');
                          ELSE
                              IF ln_message_count >= 1 THEN
                                  FOR I IN 1..ln_message_count LOOP
                                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_message_data : '|| lc_message_data);
                                      FND_FILE.PUT_LINE(FND_FILE.LOG,(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)));
                                      IF i = 1 THEN
                                          lc_message_data := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                                      END IF;
                                  END LOOP;
                              END IF;
                          END IF;

                      ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Discount Already Applied Before For Invoice No  : ' ||lcu_short_paid_invoices.trx_number);
                      END IF;
                  ELSE
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer IS not qualifed for a Flat Discount :'||lcu_short_paid_invoices.party_name);
                  END IF;

              END LOOP; -- R_ACT_NAME
              IF lc_activity_name IS NULL THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer is not qualified for a flat rate discount or might not be set up : '||lcu_short_paid_invoices.party_name);
                  END IF;
          END IF;
           -- Added below condition for DEFECT 19328
          <<END_OF_LOOP>>
          /**************************************DEFECT 17760 END************************************************/
          COMMIT;
      END LOOP;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------------');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Invoices extracted            : '||ln_total_records );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Invoices got Adjusted         : '||ln_success_records );
        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Invoices did not get Adjusted : '||(ln_total_records-ln_success_records) );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------------------------------------');
   EXCEPTION
       WHEN  OTHERS THEN
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
           FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
           FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
           FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
           lc_loc_err_msg :=  FND_MESSAGE.GET;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'==============================================');
           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
           FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'============================================== ');
           x_ret_code:= 2 ;
           XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type            => 'CONCURRENT PROGRAM'
                                          , p_program_name            => lc_concurrent_program_name
                                          , p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          , p_module_name             => 'AR'
                                          , p_error_location          => 'Error at ' || lc_error_loc
                                          , p_error_message_count     => 1
                                          , p_error_message_code      => 'E'
                                          , p_error_message           => lc_loc_err_msg
                                          , p_error_message_severity  => 'Major'
                                          , p_notify_flag             => 'N'
                                          , p_object_type             => 'Short Pay'
                                          );
   END NOTIFY;

PROCEDURE VALIDATE_DIS_CUST( p_customer_number  IN  VARCHAR2
                           , x_activity_name    OUT VARCHAR2
                           , x_dis_percentage   OUT NUMBER
                           ) IS

lc_activity_name     ar_receivables_trx_all.name%TYPE;
ln_percentage        NUMBER;
lc_error_loc         VARCHAR2(2000);
lc_error_debug       VARCHAR2(2000);
lc_loc_err_msg       xx_com_error_log.error_message%TYPE;
lc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

BEGIN
    lc_error_loc   := 'To Get Customer Flat Discount Percentage ';
    lc_error_debug := ' CUSTOMER NUMBER :'||p_customer_number;

    SELECT user_concurrent_program_name
      INTO lc_concurrent_program_name
      FROM fnd_concurrent_programs_tl
     WHERE concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
       AND language = USERENV('LANG');

    SELECT xftv.target_value1 percentage
         , xftv.target_value2 activate_name
      INTO ln_percentage
         , lc_activity_name
      FROM xx_fin_translatedefinition xftd
         , xx_fin_translatevalues xftv
     WHERE xftd.translate_id              = xftv.translate_id
       AND xftd.translation_name          = 'FLAT_DISCOUNTS'
       AND xftv.source_value1             = p_customer_number
       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
       AND XFTV.ENABLED_FLAG              = 'Y'
       AND xftd.enabled_flag              = 'Y';

       x_activity_name  := lc_activity_name;
       x_dis_percentage := ln_percentage;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Flat Discount Customer Is : '|| p_customer_number);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Activite Name Is          : '|| lc_activity_name);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Discount Percentage       : '|| ln_percentage);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Not a Flat Discount Customer : '|| p_customer_number);
        x_dis_percentage    := 0;
        x_activity_name     := NULL;
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised deriving flat discount : '||SQLERRM);
        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0001_ERROR ');
        FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
        FND_MESSAGE.SET_TOKEN('ERR_DEBUG',lc_error_debug);
        FND_MESSAGE.SET_TOKEN('ERR_ORA',SQLERRM);
        lc_loc_err_msg :=  FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_loc_err_msg);
        XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type            => 'CONCURRENT PROGRAM'
                                       , p_program_name            => lc_concurrent_program_name
                                       , p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                       , p_module_name             => 'AR'
                                       , p_error_location          => 'Error at ' || lc_error_loc
                                       , p_error_message_count     => 1
                                       , p_error_message_code      => 'E'
                                       , p_error_message           => lc_loc_err_msg
                                       , p_error_message_severity  => 'Major'
                                       , p_notify_flag             => 'N'
                                       , p_object_type             => 'Short Pay'
                                       );
        x_dis_percentage := 0;
        x_activity_name  := NULL;
END VALIDATE_DIS_CUST;
END XX_AR_CUST_REBATE_PAY_PKG;
/
