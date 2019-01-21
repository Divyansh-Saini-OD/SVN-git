CREATE OR REPLACE PACKAGE BODY APPS.XX_ar_mass_apply
AS
-- +=========================================================================+
-- |                           Oracle - GSD                                  |
-- |                             Bangalore                                   |
-- +=========================================================================+
-- | Name  : XX_ar_mass_apply                                               |
-- | Rice ID: E3116                                                         |
-- | Description      : This Program will extract all the RCC transactions   |
-- |                    into an XML file for RACE                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     30-JUN-2014 Arun G          Initial draft version                |
-- |2.0     15-JUL-2014 Arun G          Added debug messages/exceptions      |
-- +=========================================================================+

  g_debug_flag      BOOLEAN;
  gc_success        VARCHAR2(100)   := 'SUCCESS';
  gc_failure        VARCHAR2(100)   := 'FAILURE';

  PROCEDURE log_exception ( p_error_location     IN  VARCHAR2
                           ,p_error_msg          IN  VARCHAR2 )
  IS
  -- +===================================================================+
  -- | Name  : log_exception                                             |
  -- | Description     : The log_exception procedure logs all exceptions |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_error_location     IN -> Error location       |
  -- |                   p_error_msg          IN -> Error message        |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
  ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;
  ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;

  BEGIN

    XX_COM_ERROR_LOG_PUB.log_error(  p_return_code             => FND_API.G_RET_STS_ERROR
                                    ,p_msg_count               => 1
                                    ,p_application_name        => 'XXFIN'
                                    ,p_program_type            => 'Custom Messages'
                                    ,p_program_name            => 'XX_RCC_AB_TRX_EXTRACT'
                                    ,p_attribute15             => 'XX_RCC_AB_TRX_EXTRACT'
                                    ,p_program_id              => null
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => p_error_location
                                    ,p_error_message_code      => null
                                    ,p_error_message           => p_error_msg
                                    ,p_error_message_severity  => 'MAJOR'
                                    ,p_error_status            => 'ACTIVE'
                                    ,p_created_by              => ln_user_id
                                    ,p_last_updated_by         => ln_user_id
                                    ,p_last_update_login       => ln_login
                                    );

  EXCEPTION
    WHEN OTHERS
    THEN
      fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
  END log_exception;


  PROCEDURE log_msg(
                    p_string IN VARCHAR2
                   )
  IS
  -- +===================================================================+
  -- | Name  : log_msg                                                   |
  -- | Description     : The log_msg procedure displays the log messages |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_string             IN -> Log Message          |
  -- +===================================================================+

  BEGIN

    IF (g_debug_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG,p_string);
    END IF;
  END log_msg;

-- +===================================================================+
-- | Name  : get_data
-- | Description     : The get_data procedure reads the data from      |
-- |                   webadi excel template file and loads the data   |
-- |                   into stg table for further processing           |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+

  PROCEDURE get_data(p_receipt_number         VARCHAR2,
                     p_customer_number        VARCHAR2,
                     p_orginal_receipt_amount VARCHAR2,        
                     p_invoice_number         VARCHAR2,
                     p_invoice_amount         VARCHAR2,        
                     p_receipt_date           DATE ,  
                     p_created_by             VARCHAR2)

  AS 

  lc_error_message varchar2(4000);

  BEGIN 

    INSERT INTO XX_AR_MASS_APPLY_RECEIPTS
    (BATCH_ID,
     RECORD_ID,
     RECEIPT_NUMBER,
     CUSTOMER_NUMBER,
     ORIGINAL_RECEIPT_AMOUNT,
     INVOICE_NUMBER,
     INVOICE_AMOUNT,
     RECEIPT_DATE,
     STATUS ,
     CREATION_DATE,
     CREATED_BY,
     LAST_UPDATE_DATE,
     LAST_UPDATED_BY)
   VALUES
     (fnd_global.session_id,
      XX_AR_MASS_APPLY_RECEIPTS_S.nextval,
      p_receipt_number,
      p_customer_number,
      p_orginal_receipt_amount,
      p_invoice_number,
      p_invoice_amount,
      p_receipt_date,
      'N',
      SYSDATE,
      p_created_by,
      SYSDATE,
      p_created_by);

    COMMIT;
          
  EXCEPTION 
    WHEN OTHERS 
    THEN
      fnd_message.set_name('BNE', 'Error while inserting the data ..'||SQLERRM);

      lc_error_message := SQLERRM;
 
      insert into ag_error(error1) values(lc_error_message);

      commit;
  END get_data;


-- +===================================================================+
-- | Name  : get_receipt_details 
-- | Description     : The get_receipt_details gets the receipt inform |
-- |                   ation for given input values                    |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE get_receipt_details(p_receipt_number   IN  ar_cash_receipts.receipt_number%TYPE,
                                p_customer_number  IN  ar_cash_receipts.pay_from_customer%TYPE,
                                p_receipt_amount   IN  ar_cash_receipts.amount%TYPE,
                                p_receipt_date     IN  ar_cash_receipts.receipt_date%TYPE,
                                p_org_id           IN  ar_cash_receipts.org_id%TYPE,
                                x_receipt_rec      OUT ar_cash_receipts_all%ROWTYPE,
                                x_return_status    OUT VARCHAR2,
                                x_error_msg        OUT VARCHAR2)
  AS 

  BEGIN 

    x_receipt_rec   := NULL;
    x_return_status := NULL;
    x_error_msg     := NULL;

    SELECT acr.*
    INTO x_receipt_rec
    FROM ar_cash_receipts_all acr,
         hz_cust_accounts_all hca
    WHERE acr.receipt_number   = p_receipt_number
    AND acr.pay_from_customer  = hca.cust_account_id
    AND hca.account_number     = p_customer_number
    AND acr.amount             = p_receipt_amount
    AND acr.org_id             = p_org_id
    AND acr.receipt_date       = p_receipt_date;

    x_return_status := gc_success;

   
  EXCEPTION 
    WHEN NO_DATA_FOUND
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Receipt not found.';
    WHEN TOO_MANY_ROWS
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Too many Receipts found.';

    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Error while getting the receipt info '||SQLERRM;
  END get_receipt_details;



-- +===================================================================+
-- | Name  : validate_receipt_balance 
-- | Description     : This process validates the balances             |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE validate_receipt_balance(p_receipt_id     IN  ar_cash_receipts.cash_receipt_id%TYPE,
                                     p_batch_id       IN  xx_ar_mass_apply_receipts.batch_id%TYPE,
                                     p_upload_amount  OUT xx_ar_mass_apply_receipts.invoice_amount%TYPE,
                                     x_return_status  OUT VARCHAR2,
                                     x_error_msg      OUT VARCHAR2)
  AS 

  ln_amt_due_remaining ar_payment_schedules_all.amount_due_remaining%TYPE := 0;
  ln_invoice_amount    xx_ar_mass_apply_receipts.invoice_amount%TYPE      := 0;

  e_process_exception  EXCEPTION;
  BEGIN 
    x_return_status := NULL;
    x_error_msg     := NULL;
    p_upload_amount := NULL;

    SELECT ABS(SUM(REPLACE(invoice_amount,',','')))
    INTO ln_invoice_amount
    FROM xx_ar_mass_apply_receipts
    WHERE batch_id = p_batch_id;

    log_msg(' Total Invoice_amount :'|| ln_invoice_amount);

    p_upload_amount := ln_invoice_amount;

    SELECT ABS(SUM(REPLACE(amount_due_remaining,',','')))
    INTO ln_amt_due_remaining
    FROM ar_payment_schedules_all
    WHERE cash_receipt_id  = p_receipt_id;

    log_msg(' Total Amount Due Remaining :'||ln_amt_due_remaining);


    IF ln_invoice_amount > ln_amt_due_remaining
    THEN
      x_error_msg     := 'Total Upload amount :'|| ln_invoice_amount ||' is greater than Unapplied Receipt Amount :'|| ln_amt_due_remaining ;
      
      RAISE e_process_exception;

    END IF;

    x_return_status := gc_success;

   
  EXCEPTION 
    WHEN NO_DATA_FOUND
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Receipt not found.';
    WHEN TOO_MANY_ROWS
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Too many Receipts found.';

    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      IF x_error_msg IS NULL
      THEN 
        x_error_msg     := 'Error while getting validating the receipt balance '||SQLERRM;
      END IF;
  END validate_receipt_balance;


-- +===================================================================+
-- | Name  : get_invoice_details 
-- | Description     : The get_invoice_details gets the invoice inform |
-- |                   ation for given input values                    |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE get_invoice_details(p_invoice_number   IN  ra_customer_trx_all.trx_number%TYPE,
                                p_customer_number  IN  ar_cash_receipts.pay_from_customer%TYPE,
                                p_org_id           IN  ar_cash_receipts.org_id%TYPE,
                                x_invoice_rec      OUT ra_customer_trx_all%ROWTYPE,
                                x_return_status    OUT VARCHAR2,
                                x_error_msg        OUT VARCHAR2)
  AS 

  BEGIN 

    x_invoice_rec   := NULL;
    x_return_status := NULL;
    x_error_msg     := NULL;

    SELECT rct.*
    INTO x_invoice_rec
    FROM ra_customer_trx_all rct
--         hz_cust_accounts_all hca
    WHERE trx_number         = p_invoice_number
--    AND hca.cust_account_id  = rct.bill_to_customer_id
--    AND account_number       = p_customer_number
    AND rct.org_id           = p_org_id;

    x_return_status := gc_success;

   
  EXCEPTION 
    WHEN NO_DATA_FOUND
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Invoice not found.';
    WHEN TOO_MANY_ROWS
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Too many Invoices found.';

    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      x_error_msg     := 'Error while getting the Invoice info '||SQLERRM;
  END get_invoice_details;

-- +===================================================================+
-- | Name  : update stg table 
-- | Description     : The update stg table sets the record status     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE update_stg_table(p_record_id      IN     xx_ar_mass_apply_receipts.record_id%TYPE,
                             p_receipt_number IN     xx_ar_mass_apply_receipts.receipt_number%TYPE,
                             p_status         IN     xx_ar_mass_apply_receipts.status%TYPE,
                             p_batch_id       IN     xx_ar_mass_apply_receipts.batch_id%TYPE,
                             p_error_msg      IN OUT xx_ar_mass_apply_receipts.error_message%TYPE,
                             x_return_status  OUT    VARCHAR2)

  AS 
  BEGIN 

    x_return_status := NULL;

    IF p_record_id IS NULL
    THEN 
      UPDATE xx_ar_mass_apply_receipts
      SET status        = p_status,
          error_message = p_error_msg
      WHERE receipt_number = p_receipt_number
      AND batch_id         = p_batch_id;

    ELSE

      UPDATE xx_ar_mass_apply_receipts
      SET status        = p_status,
          error_message = p_error_msg
      WHERE record_id      =  p_record_id 
      AND   receipt_number = p_receipt_number
      AND   batch_id       =  p_batch_id;

    END IF;

    log_msg( SQL%ROWCOUNT ||' Row updated for record id :'|| p_record_id);

    x_return_status := gc_success;

   
  EXCEPTION 
    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      p_error_msg     := 'Error while updating the staging table '||SQLERRM;
  END update_stg_table;


-- +===================================================================+
-- | Name  : apply_receipt 
-- | Description     : The apply_receipts calls the seeded API and     |
-- |                   apply the invoice to receipt.
-- |                   ation for given input values                    |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE apply_receipt(p_invoice_id       IN  ra_customer_trx_all.customer_trx_id%TYPE,
                          p_invoice_amt      IN  xx_ar_mass_apply_receipts.invoice_amount%TYPE,
                          p_cash_receipt_id  IN  ar_cash_receipts_all.cash_receipt_id%TYPE,                           
                          p_org_id           IN  NUMBER, --ar_cash_receipts_all.org_id%TYPE,
                          p_comments         IN  ar_cash_receipts_all.comments%TYPE,
                          x_return_status    OUT VARCHAR2,
                          x_error_msg        OUT VARCHAR2)
  AS 

  x_msg_count      NUMBER;
  x_msg_data       VARCHAR2(32000);

  e_process_exception ExCEPTION;

  BEGIN 
    x_error_msg     := NULL;
    x_return_status := NULL;
    x_msg_count     := NULL;
    x_msg_data      := NULL;

    log_msg(' ORG id          :'|| p_org_id);

    mo_global.init('AR');
    mo_global.set_policy_context('S',p_org_id);

--   fnd_global.apps_initialize(2986907, 20678, 222,0);

   log_msg(' p cash receipt id :'|| p_cash_receipt_id);
   log_msg(' p invoice id      :'|| p_invoice_id);
   log_msg(' p_invoice amt     :'|| p_invoice_amt);
   log_msg(' p_comments       :'||  p_comments);
  
    ar_receipt_api_pub.apply(p_api_version        =>   1.0,
                             p_init_msg_list      =>   fnd_api.g_true,
                             p_commit             =>   fnd_api.g_false,
                             p_validation_level   =>   fnd_api.g_valid_level_full,
                             x_return_status      =>   x_return_status,
                             x_msg_count          =>   x_msg_count,
                             x_msg_data           =>   x_msg_data,
                             p_cash_receipt_id    =>   p_cash_receipt_id,
                             p_customer_trx_id    =>   p_invoice_id,
                             p_amount_applied     =>   p_invoice_amt,
                             p_comments           =>   p_comments,
                             p_apply_date         =>   TRUNC(SYSDATE),
                             p_apply_gl_date      =>   TRUNC(SYSDATE)
                             );

    log_msg(' API return status inside :'|| x_return_status);
    log_msg(' API return msg inside    :'|| x_msg_data);


    IF (x_return_status != 'S')
    THEN
      FOR i IN 1 .. fnd_msg_pub.count_msg
      LOOP
        fnd_msg_pub.get (p_msg_index       => i,
                         p_encoded         => fnd_api.g_false,
                         p_data            => x_msg_data,
                         p_msg_index_out   => x_msg_count);

        x_error_msg := x_error_msg || ('Msg'||TO_CHAR(i)||':'||x_msg_data);
      END LOOP;

      fnd_file.put_line(fnd_file.LOG,'Error - unable to apply the receipt for'
                        || ' cash_receipt_id  '|| p_cash_receipt_id
                        || ' customer_trx_id  '|| p_invoice_id
                        || ' amount_applied = '|| p_invoice_amt
                        || ' error          = '|| x_return_status
                        || ' msg            = '|| x_error_msg);

       RAISE e_process_exception;
    END IF;

    x_return_status := gc_success;
   
  EXCEPTION 
    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      IF x_error_msg IS NULL
      THEN 
        x_error_msg     := 'Error while applying the Invoice.. '||SQLERRM;
      END IF;
  END apply_receipt;

-- +===================================================================+
-- | Name  : generate_report 
-- | Description     : This process generates the report output        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE generate_report(p_batch_id       IN     xx_ar_mass_apply_receipts.batch_id%TYPE,
                            p_upload_amount  IN     xx_ar_mass_apply_receipts.invoice_amount%TYPE,
                            p_receipt_id     IN     ar_cash_receipts_all.cash_receipt_id%TYPE,
                            p_error_msg      OUT    xx_ar_mass_apply_receipts.error_message%TYPE,
                            x_return_status  OUT    VARCHAR2)

  AS 

  CURSOR cur_rep(p_batch_id xx_ar_mass_apply_receipts.batch_id%TYPE, p_status In xx_ar_mass_apply_receipts.status%TYPE)
  IS 
  SELECT xamp.receipt_number,
         xamp.original_receipt_amount,
         xamp.invoice_number,
         xamp.invoice_amount,
         xamp.record_id,
         xamp.error_message
  FROM xx_ar_mass_apply_receipts xamp
  WHERE batch_id    = p_batch_id
  AND xamp.status   = p_status;


  ln_unapplied_amount    VARCHAR2(100) := 0;
  ln_header_rec          NUMBER := 1;
  lc_line                VARCHAR2(4000) := NULL;
  lc_header              VARCHAR2(4000) := NULL;
  lc_head_line           VARCHAR2(4000) := NULL;
  ln_balance_due         ar_payment_schedules_all.amount_due_remaining%TYPE := NULL;
  ln_amount_due_original ar_payment_schedules_all.amount_due_original%TYPE := NULL;
  
   
  BEGIN 

    x_return_status := NULL;

    log_msg('Batch id : '|| p_batch_id);

    FOR cur_rep_rec IN cur_rep(p_batch_id => p_batch_id , p_status => 'C')
    LOOP
      BEGIN

      lc_line := NULL;

      IF ln_header_rec = 1
      THEN 
        log_msg('Processing successful records ..');
        fnd_file.put_line(fnd_file.output, '*****************************REPORT FOR SUCCESSFUL RECORDS **********************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        -- Get the unapplied amount 

       ln_unapplied_amount := 0;

       BEGIN
         SELECT ABS(SUM(amount_due_remaining))
         INTO ln_unapplied_amount
         FROM ar_payment_schedules_all aps
         WHERE 1=1 
         AND   aps.cash_receipt_id  = p_receipt_id;
       EXCEPTION 
         WHEN OTHERS 
         THEN 
           ln_unapplied_amount := NULL;
       END;

        fnd_file.put_line(fnd_file.output, 'Receipt Number          :'||chr(9) || cur_rep_rec.receipt_number );
        fnd_file.put_line(fnd_file.output, 'Original Receipt Amount :'||chr(9) || to_char(cur_rep_rec.original_receipt_amount,'9,999,999.00') );
        fnd_file.put_line(fnd_file.output, 'Upload Amount           :'||chr(9) || to_char(p_upload_amount,'9,999,999.00'));
        fnd_file.put_line(fnd_file.output, 'UnApplied Amount        :'||chr(9) || to_char(ln_unapplied_amount,'9,999,999.00') );

        fnd_file.put_line(fnd_file.output, chr(10));
       
        ln_header_rec := 2;

        lc_header := LPAD('Invoice Number',  14, ' ')||chr(9)||
                     LPAD('Invoice Amount Submitted',  29, ' ')||chr(9)||chr(9)||
                     LPAD('Original Amount', 18, ' ')||CHR(9)|| 
                     LPAD('Balance Due',16, ' ')||CHR(9) ;

        fnd_file.put_line(fnd_file.output , lc_header);


        lc_head_line := LPAD('----------------',  14, ' ')||chr(9)||
                        LPAD('--------------------------',  29, ' ')||chr(9)||chr(9)||
                        LPAD('-----------------', 18, ' ')||CHR(9)|| 
                        LPAD('-------------',16, ' ')||CHR(9) ;

        fnd_file.put_line(fnd_file.output , lc_head_line);

      END IF;

      -- get the balance due 

      ln_balance_due         := 0;
      ln_amount_due_original  := 0;

       BEGIN
         SELECT SUM(amount_due_remaining),
                SUM(amount_due_original)
         INTO ln_balance_due,
              ln_amount_due_original
         FROM ar_payment_schedules_all aps,
              ra_customer_trx_all rct
         WHERE aps.customer_trx_id = rct.customer_trx_id
         AND   rct.trx_number      = cur_rep_rec.invoice_number;
       EXCEPTION 
         WHEN OTHERS 
         THEN 
           ln_balance_due   := 0;
           ln_amount_due_original := 0;
       END;

      lc_line := LPAD(cur_rep_rec.invoice_number,14, ' ')||chr(9)||
                 LPAD(cur_rep_rec.invoice_amount,22, ' ')||chr(9)||chr(9)||
                 LPAD(To_char(ln_amount_due_original,'9,999,999.00'), 25, ' ')||CHR(9)|| 
                 LPAD(TO_CHAR(ln_balance_due,'9,999,999.00') ,19, ' ') ;

       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN 
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_rep_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    ln_header_rec := 1;

    FOR cur_err_rec IN cur_rep(p_batch_id => p_batch_id , p_status => 'E')
    LOOP
      BEGIN

      lc_line := NULL;

      IF ln_header_rec = 1
      THEN 
        log_msg('Processing Failed records ..');
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, '********************************REPORT FOR FAILED RECORDS *******************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        -- Get the unapplied amount 
 
        ln_unapplied_amount := 0;
 
        BEGIN
          SELECT ABS(SUM(amount_due_remaining))
          INTO ln_unapplied_amount
          FROM ar_payment_schedules_all aps
          WHERE 1=1 
          AND   aps.cash_receipt_id  = p_receipt_id; -- cur_err_rec.cash_receipt_id;
        EXCEPTION 
          WHEN OTHERS 
          THEN 
            ln_unapplied_amount := NULL;
        END;

        fnd_file.put_line(fnd_file.output, 'Receipt Number          :'||chr(9) || cur_err_rec.receipt_number );
        fnd_file.put_line(fnd_file.output, 'Original Receipt Amount :'||chr(9) || to_char(cur_err_rec.original_receipt_amount,'9,999,999.00') );
        fnd_file.put_line(fnd_file.output, 'Upload Amount           :'||chr(9) || to_char(p_upload_amount,'9,999,999.00'));
        fnd_file.put_line(fnd_file.output, 'UnApplied Amount        :'||chr(9) || to_char(ln_unapplied_amount,'9,999,999.00') );


        fnd_file.put_line(fnd_file.output, chr(10));

--        fnd_file.put_line(fnd_file.output, 'Invoice Number :'||chr(9)||'Invoice Amount:'||chr(9)||chr(9)||'Original Amount :'||CHR(9) || 'Balance Due :'||CHR(9) );
--        fnd_file.put_line(fnd_file.output, '----------------'||chr(9)||'---------------'||chr(9)||chr(9)||'-----------------'||CHR(9) || '-------------'||CHR(9) );

        lc_header := LPAD('Invoice Number',  14, ' ')||chr(9)||
                     LPAD('Invoice Amount Submitted',  29, ' ')||chr(9)||chr(9)||
                     LPAD('Original Amount', 18, ' ')||CHR(9)|| 
                     LPAD('Balance Due',16, ' ')||CHR(9)||
                     RPAD('Error Message','15',' ')||CHR(9);

        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := LPAD('----------------',  14, ' ')||chr(9)||
                        LPAD('--------------------------',  29, ' ')||chr(9)||chr(9)||
                        LPAD('-----------------', 18, ' ')||CHR(9)|| 
                        LPAD('---------------',16, ' ')||CHR(9)||
                        RPAD('----------------------------------------',15, ' ')||CHR(9);

        fnd_file.put_line(fnd_file.output , lc_head_line);

        
        ln_header_rec := 2;

        fnd_file.put_line(fnd_file.output , chr(10));

      END IF;

      -- get the balance due 

      ln_balance_due         := 0;
      ln_amount_due_original  := 0;

       BEGIN
         SELECT NVL(SUM(amount_due_remaining),0),
                NVL(SUM(amount_due_original),0)
         INTO ln_balance_due,
              ln_amount_due_original
         FROM ar_payment_schedules_all aps,
              ra_customer_trx_all rct
         WHERE aps.customer_trx_id = rct.customer_trx_id
         AND   rct.trx_number      = cur_err_rec.invoice_number;
       EXCEPTION 
         WHEN OTHERS 
         THEN 
           ln_balance_due   := 0;
           ln_amount_due_original := 0;
           
       END;

       log_msg('ln_balance_due'|| ln_balance_due || 'ln_amount_due_original'||ln_amount_due_original);


      lc_line := LPAD(cur_err_rec.invoice_number,14, ' ')||chr(9)||
                 LPAD(cur_err_rec.invoice_amount,22, ' ')||chr(9)||chr(9)||
                 LPAD(To_char(ln_amount_due_original,'9,999,999.00'), 25, ' ')||CHR(9)|| 
                 LPAD(TO_CHAR(ln_balance_due,'9,999,999.00') ,17, ' ')||CHR(9)||
                 --LPAD(cur_err_rec.error_message,50, ' ')||CHR(9)
                 cur_err_rec.error_message||CHR(9)
                 ;

       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN 
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_err_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    x_return_status := gc_success;
   
  EXCEPTION 
    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      p_error_msg     := 'Error while updating the staging table '||SQLERRM;
      log_msg(p_error_msg);
  END generate_report;


  PROCEDURE extract(x_retcode         OUT NOCOPY     NUMBER,
                    x_errbuf          OUT NOCOPY     VARCHAR2)
  IS
  -- +===================================================================+
  -- | Name  : extract
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records and process them via Oracle API         |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+

 
  CURSOR lcu_payments(p_batch_id       IN XX_AR_MASS_APPLY_RECEIPTS.batch_id%TYPE, 
                      p_status         IN XX_AR_MASS_APPLY_RECEIPTS.status%TYPE)                    
  IS 
  SELECT *
  FROM xx_ar_mass_apply_receipts
  WHERE batch_id     = p_batch_id
  AND status         = NVL(p_status, status)
  Order BY receipt_number , invoice_amount;

  TYPE t_pay_tab IS TABLE OF lcu_payments%ROWTYPE INDEX BY PLS_INTEGER;
  l_pay_tab               t_pay_tab;
  ln_batch_id             Number;
  ln_user_id              fnd_user.user_id%TYPE;
  lc_user_name            fnd_user.user_name%TYPE;
  lc_debug_flag           VARCHAR2(1) := NULL;
  ln_receipt_rec          ar_cash_receipts_all%ROWTYPE := NULL;
  lc_return_status        VARCHAR2(10);
  lc_error_msg            VARCHAR2(4000);
  ln_invoice_rec          ra_customer_trx_all%ROWTYPE := NULL;
  lc_receipt_comments     ar_cash_receipts_all.comments%TYPE := NULL;
  lc_prev_receipt_number  ar_cash_receipts_all.receipt_number%TYPE := NULL;
  ln_org_id               NUMBER := NULL;
  lc_receipt_exists       VARCHAR2(1);
  ln_receipt_id           ar_cash_receipts_all.cash_receipt_id%TYPE := NULL;
  ln_upload_amount        xx_ar_mass_apply_receipts.invoice_amount%TYPE := NULL;
  ln_receipt_count        NUMBER := 0;

  ln_successful_records   NUMBER := 0;
  ln_failed_records       NUMBER := 0;

  e_process_exception     EXCEPTION;
  e_receipt_exception     EXCEPTION;
  
  BEGIN

    -- Get the Debug flag

    BEGIN
     SELECT xftv.source_value1
     INTO lc_debug_flag
     FROM xx_fin_translatedefinition xft,
          xx_fin_translatevalues xftv
     WHERE xft.translate_id    = xftv.translate_id
     AND xft.enabled_flag      = 'Y'
     AND xftv.enabled_flag     = 'Y'
     AND xft.translation_name  = 'XXOD_AR_MASS_APPLY_CASH';

    EXCEPTION 
      WHEN OTHERS
      THEN 
        lc_debug_flag := 'N';
    END;

    IF(lc_debug_flag = 'Y')
    THEN
      g_debug_flag := TRUE;
    ELSE
      g_debug_flag := FALSE;
    END IF; 

    ln_user_id := fnd_global.user_id;
    ln_org_id  := fnd_global.org_id;


    log_msg('Getting the user name ..');

    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log ,'Purge all the successfull records from staging table for USER :'||lc_user_name);


    DELETE FROM xx_ar_mass_apply_receipts
    WHERE STATUS = 'C'
    AND Created_by = ln_user_id;

    fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Records deleted from staging table');

    COMMIT;

    fnd_file.put_line(fnd_file.log, 'Remove Duplicate records within the receipt number ..');

    DELETE FROM xx_ar_mass_apply_receipts a
    WHERE EXISTS ( SELECT 1
                   FROM xx_ar_mass_apply_receipts b
                   WHERE invoice_number = A.invoice_number
                   AND invoice_amount = a.invoice_amount
                   AND status = a.status
                   AND ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0 
    THEN 
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Duplicate Records deleted from staging table');
    END IF;


    log_msg('Gettting the next batch id .............');

    SELECT XX_AR_MASS_APPLY_batch_S.NEXTVAL
    INTO ln_batch_id
    FROM DUAL;

    fnd_file.put_line(fnd_file.log, 'Batch id      :'|| ln_batch_id);
    fnd_file.put_line(fnd_file.log, 'session_id    :'||  fnd_global.session_id);
    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);
    fnd_file.put_line(fnd_file.log, 'org id        :'||  ln_org_id);

    fnd_file.put_line(fnd_file.log, 'Update the batch id in stg table for Used id :'|| ln_user_id);


    UPDATE xx_ar_mass_apply_receipts
    SET batch_id = ln_batch_id
    WHERE created_by = ln_user_id
    AND   status = 'N';

    fnd_file.put_line(fnd_file.log ,'Number of records Updated for user : '|| ln_user_id || ' with batch id :'|| ln_batch_id ||' :'||SQL%ROWCOUNT);

    COMMIT;

 

    OPEN lcu_payments(p_batch_id => ln_batch_id,
                      p_status   => 'N');
    LOOP
     FETCH lcu_payments 
     BULK COLLECT INTO l_pay_tab;

      fnd_file.put_line(fnd_file.log, 'Total number of payment records :'||l_pay_tab.COUNT);
     
      IF (l_pay_tab.COUNT > 0)
      THEN

        FOR i_index IN l_pay_tab.FIRST .. l_pay_tab.LAST
        LOOP
          BEGIN
            ln_receipt_rec        := NULL;
            lc_return_status      := NULL;
            lc_error_msg          := NULL;
            ln_invoice_rec        := NULL;
            lc_receipt_comments   := NULL;

              
            IF ( (l_pay_tab(i_index).receipt_number != lc_prev_receipt_number) OR lc_prev_receipt_number IS NULL)
            THEN
              log_msg('Processing Receipt  Number : '||l_pay_tab(i_index).receipt_number);
              log_msg('   Customer Number            : '||l_pay_tab(i_index).customer_number);
              log_msg('   Receipt Original Amount    : '||l_pay_tab(i_index).original_receipt_amount);
              log_msg('   Receipt date               : '||l_pay_tab(i_index).receipt_date);

              ln_receipt_id    := NULL;
              ln_receipt_count := ln_receipt_count + 1;
              ln_upload_amount := NULL;

              get_receipt_details(p_receipt_number   => l_pay_tab(i_index).receipt_number,
                                  p_customer_number  => l_pay_tab(i_index).customer_number,
                                  p_receipt_amount   => l_pay_tab(i_index).original_receipt_amount,
                                  p_receipt_date     => l_pay_tab(i_index).receipt_date,
                                  p_org_id           => ln_org_id,
                                  x_receipt_rec      => ln_receipt_rec,
                                  x_return_status    => lc_return_status,
                                  x_error_msg        => lc_error_msg);

              lc_prev_receipt_number := l_pay_tab(i_index).receipt_number;

              log_msg('Receipt Id : '||ln_receipt_rec.cash_receipt_id);
              
              ln_receipt_id  := ln_receipt_rec.cash_receipt_id;

              lc_receipt_exists   := 'Y';

              IF lc_return_status != gc_success
              THEN 
                lc_receipt_exists := 'N';
                RAISE e_receipt_exception;
              END IF;

              log_msg('Calling validate receipt balance..');

              validate_receipt_balance(p_receipt_id     => ln_receipt_id,
                                       p_batch_id       => ln_batch_id,
                                       p_upload_amount  => ln_upload_amount,
                                       x_return_status  => lc_return_status,
                                       x_error_msg      => lc_error_msg);

              IF lc_return_status != gc_success
              THEN 
                lc_receipt_exists := 'N';
                RAISE e_receipt_exception;
              END IF;

              IF ln_receipt_rec.comments IS NOT NULL 
              THEN 
                lc_receipt_comments := ln_receipt_rec.comments ||' Applied Using the WebADI Mass Load by User Name :' || lc_user_name || 'And on '|| TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS');
              ELSE
                lc_receipt_comments := 'Applied Using the WebADI Mass Load by User Name :' || lc_user_name || 'on '|| TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') ;
              END IF;
                

              log_msg('Updating the comments ..');

              UPDATE ar_cash_receipts_all
              set comments = lc_receipt_comments 
              WHERE cash_receipt_id = ln_receipt_id;

              log_msg('Row updated .. '|| SQL%ROWCOUNT);


              IF ln_receipt_count > 1 
              THEN 
                log_msg('Calling generate report for batch id :'|| ln_batch_id ||' And Receipt id :'|| ln_receipt_id);

                 generate_report(p_batch_id       => ln_batch_id,
                                 p_upload_amount  => ln_upload_amount,
                                 p_receipt_id     => ln_receipt_id,
                                 p_error_msg      => lc_error_msg,
                                 x_return_status  => lc_return_status);
              END IF;                
                                       
            END IF; -- receipt number

            log_msg('Receipt Exists :' || lc_receipt_exists);

            IF lc_receipt_exists = 'Y' 
            THEN
              log_msg ('Processing Invoice Number :'|| l_pay_tab(i_index).invoice_number ||' Invoice Amount :'|| l_pay_tab(i_index).invoice_Amount);

              IF l_pay_tab(i_index).invoice_number IS NOT NULL 
              THEN 
                log_msg('Getting invoice details ....');

                get_invoice_details(p_customer_number  => l_pay_tab(i_index).customer_number,
                                    p_invoice_number   => l_pay_tab(i_index).invoice_number,
                                    p_org_id           => ln_org_id,
                                    x_invoice_rec      => ln_invoice_rec,
                                    x_return_status    => lc_return_status,
                                    x_error_msg        => lc_error_msg);

                log_msg(' Customer Trx id :'|| ln_invoice_rec.customer_trx_id);

              ELSE 
                lc_error_msg := 'Invoice Number is NULL or Invalid ..';
                RAISE e_process_exception;
              END IF;

              IF lc_return_status != gc_success
              THEN 
                RAISE e_process_exception;
              END IF;
                        
              IF (ln_invoice_rec.customer_trx_id IS NOT NULL AND l_pay_tab(i_index).invoice_amount IS NOT NULL )
              THEN
                apply_receipt(p_invoice_id       => ln_invoice_rec.customer_trx_id,
                              p_invoice_amt      => REPLACE(l_pay_tab(i_index).invoice_amount,',','') ,
                              p_cash_receipt_id  => ln_receipt_id,
                              p_org_id           => ln_org_id,
                              p_comments         => lc_receipt_comments,
                              x_return_status    => lc_return_status,
                              x_error_msg        => lc_error_msg);

                log_msg(' API return status :'|| lc_return_status);
                log_msg(' API return msg    :'|| lc_error_msg);

                IF lc_return_status != gc_success
                THEN 
                  RAISE e_process_exception;
                END IF;
  
                update_stg_table(p_record_id      => l_pay_tab(i_index).record_id,
                                 p_receipt_number => l_pay_tab(i_index).receipt_number,
                                 p_status         => 'C',
                                 p_batch_id       => ln_batch_id,
                                 p_error_msg      => lc_error_msg,
                                 x_return_status  => lc_return_status);
 
                ln_successful_records :=  ln_successful_records +1 ;
              END IF;

              log_msg('Commiting the record ...');

              COMMIT;

            END IF; -- record exists 
            
          EXCEPTION 
            WHEN e_receipt_exception
            THEN 
              IF lc_error_msg IS NULL
              THEN
                lc_error_msg := 'Unable to process ..'||SQLERRM;
              END IF;
              fnd_file.put_line(fnd_file.log,lc_error_msg);

              ln_failed_records := ln_failed_records + 1;

              log_exception( p_error_location     =>  'XX_AR_MASS_APPLY_PKG.EXTRACT'
                          ,p_error_msg         =>  lc_error_msg);
              x_retcode := 2;
              ROLLBACK; 

              update_stg_table(p_record_id      => NULL,
                               p_receipt_number => l_pay_tab(i_index).receipt_number,
                               p_batch_id       => ln_batch_id,
                               p_status         => 'E',
                               p_error_msg      => lc_error_msg,
                               x_return_status  => lc_return_status);


            WHEN others 
            THEN 
              IF lc_error_msg IS NULL
              THEN
                lc_error_msg := 'Unable to process ..'||SQLERRM;
              END IF;
              fnd_file.put_line(fnd_file.log,lc_error_msg);

              ln_failed_records := ln_failed_records + 1;

              log_exception( p_error_location     =>  'XX_AR_MASS_APPLY_PKG.EXTRACT'
                          ,p_error_msg         =>  lc_error_msg);
              x_retcode := 2;
              ROLLBACK; 

              update_stg_table(p_record_id      => l_pay_tab(i_index).record_id,
                               p_receipt_number => l_pay_tab(i_index).receipt_number,
                               p_batch_id       => ln_batch_id,
                               p_status         => 'E',
                               p_error_msg      => lc_error_msg,
                               x_return_status  => lc_return_status);

          END;
          COMMIT ;
        END LOOP;
      END IF;
    EXIT WHEN l_pay_tab.COUNT = 0;
   END LOOP;

   CLOSE lcu_payments;
  
   COMMIT;

   fnd_file.put_line(fnd_file.log , 'Total Successfull records ..'|| ln_successful_records );
   fnd_file.put_line(fnd_file.log , 'Total failed records ..'|| ln_failed_records );

   log_msg('Calling generate report for batch id :'|| ln_batch_id ||' And Receipt id :'|| ln_receipt_id);

   generate_report(p_batch_id       => ln_batch_id,
                   p_upload_amount  => ln_upload_amount,
                   p_receipt_id     => ln_receipt_id,
                   p_error_msg      => lc_error_msg,
                   x_return_status  => lc_return_status);

  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      IF lc_error_msg IS NULL
      THEN
        lc_error_msg := 'Unable to process the records'||SQLERRM;
      END IF;
    
      fnd_file.put_line(fnd_file.log,lc_error_msg);
      log_exception ( p_error_location     =>  'XX_AR_MASS_APPLY_PKG.EXTRACT'
                     ,p_error_msg         =>  lc_error_msg);
      x_retcode := 2;  
      COMMIT;
  END extract;
END XX_ar_mass_apply ;

/

Sho err


