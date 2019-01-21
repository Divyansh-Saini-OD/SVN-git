SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ar_subscr_rcpt_upd_pkg
AS
 -- +=============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBSCR_RCPT_UPD_PKG                                                          |
  -- |                                                                                            |
  -- |  Description:  This package is to used to update the Receipt Numbers in the Subscriptions  |
  -- |                table for AB Customers where the receipt_number is NULL                     |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         15-NOV-2018  PUNIT_CG         Initial version  for Defect# NAIT- 72201         |
  -- +============================================================================================+

  gc_package_name        CONSTANT all_objects.object_name%TYPE   := 'xx_ar_subscr_rcpt_upd_pkg';
  gc_max_log_size        CONSTANT NUMBER                         := 2000;
  gc_max_print_size      CONSTANT NUMBER                         := 2000;
  gb_debug               BOOLEAN                                 := FALSE;

/***********************************************
 *  Setter procedure for gb_debug global variable
 *  used for controlling debugging
 ***********************************************/

  PROCEDURE set_debug(p_debug_flag  IN  VARCHAR2)
  IS
  BEGIN
    IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE'))
    THEN
      gb_debug := TRUE;
    END IF;
  END set_debug;
  
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_debug is TRUE.
  * Will prepend timestamps to each message logged.  
  * This is useful for determining elapse times.
  *********************************************************************/

  PROCEDURE logit(p_message  IN  VARCHAR2,
                  p_debug    IN  BOOLEAN DEFAULT FALSE)
  IS
    lc_message  VARCHAR2(2000) := NULL;
  BEGIN
     IF (gb_debug)
     THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF')
                           || ' => ' || p_message, 1, gc_max_log_size);
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
      END IF;
     END IF;
  EXCEPTION
     WHEN OTHERS
     THEN
          NULL;
  END logit;
  
  /*************************************************************************
  * Procedure used to print the output of the program.
  * Will display the Invoices and the corresponding Receipt numbers updated.  
  **************************************************************************/
  
  PROCEDURE printit(p_out_message  IN  VARCHAR2)
  IS
    lc_out_message  VARCHAR2(2000) := NULL;
  BEGIN
      lc_out_message := SUBSTR(p_out_message,1, gc_max_print_size);
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.output, lc_out_message);
      END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
  END printit;
  
  /*********************************************************
  * Helper procedure to log that the main procedure/function
  * has been called. Sets the debug flag and logs the 
  * procedure name and the tasks done by the procedure.
  **********************************************************/
  PROCEDURE txn_receiptnum_update(errbuff       OUT VARCHAR2,
                                  retcode       OUT VARCHAR2,
                                  p_debug_flag  IN  VARCHAR2)
  AS
    CURSOR c_ab_txnnum
    IS
      SELECT DISTINCT XAS.invoice_number,XAS.contract_number,XAS.contract_id,RCTA.customer_trx_id,
                      (SELECT SUM(RCTLA.extended_amount) 
                       FROM   ra_customer_trx_lines_all RCTLA 
                       WHERE  RCTLA.customer_trx_id = RCTA.customer_trx_id)txn_amount
      FROM   xx_ar_subscriptions XAS,
             ra_customer_trx_all RCTA,
             xx_ar_contracts XAC,
             xx_ar_contract_lines XACL
      WHERE  XAC.payment_type            = 'AB'
      AND    XAC.contract_id             = XAS.contract_id
      AND    XAS.invoice_created_flag    = 'Y'
      AND    XAS.invoice_number is not null
      AND    XAS.receipt_created_flag    <> 'Y'
      AND    XAS.billing_sequence_number >= XACL.initial_billing_sequence
      AND    XAS.contract_id             = XACL.contract_id
      AND    XAS.contract_line_number    = XACL.contract_line_number
      AND    XAC.contract_id             = XACL.contract_id
      AND    XAS.invoice_number          =  RCTA.trx_number;
      

    CURSOR c_contract_lines (p_invoice_number IN VARCHAR2,p_contract_id IN NUMBER)
    IS 
      SELECT XAS.subscriptions_id,XAS.contract_line_number
      FROM   xx_ar_subscriptions XAS
      WHERE  XAS.invoice_number          = p_invoice_number
      AND    XAS.contract_id             = p_contract_id;

    CURSOR c_cash_receiptid (p_customer_trx_id IN NUMBER)
    IS 
      SELECT ARAA.cash_receipt_id,ARAA.receivable_application_id 
      FROM   ar_receivable_applications_all ARAA
      WHERE  ARAA.applied_customer_trx_id = p_customer_trx_id
      AND    ARAA.status = 'APP'
      AND    ARAA.receivable_application_id IN (SELECT MAX(ARAA1.receivable_application_id)
                                                FROM ar_receivable_applications_all ARAA1
                                                WHERE ARAA1.applied_customer_trx_id = ARAA.applied_customer_trx_id 
                                                AND   ARAA1.cash_receipt_id = ARAA.cash_receipt_id
                                               )
      ORDER  BY 1;

    lc_procedure_name       CONSTANT VARCHAR2(61)                               := gc_package_name || '.' || 'txn_receiptnum_update';
    ln_cash_receipt_id      ar_receivable_applications_all.cash_receipt_id%TYPE := 0;
    lc_receipt_num          ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    ln_cnt_cash_receipts    NUMBER                                              := 0;
    lc_prev_receipt_num     ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    lc_curr_receipt_num     ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    ln_receipt_num_count    NUMBER                                              := 0;
    ln_tot_receipt_amt      NUMBER                                              := 0;
    lc_receipt_created_flag VARCHAR2(1)                                         := NULL;
    ln_prev_receipt_amt     NUMBER                                              := 0;

    BEGIN
    set_debug(p_debug_flag => p_debug_flag);
    logit(p_message => '---------------------------------------------------',
          p_debug   => TRUE);
    logit(p_message => 'Starting TXN_RECEIPTNUM_UPDATE routine. ',
          p_debug   => TRUE);
    logit(p_message => '---------------------------------------------------',
          p_debug   => TRUE);
    printit(p_out_message => RPAD ('-',180 , '-'));
    printit(p_out_message => 'Details of the Contract, Invoice and the Receipt Numbers updated in the Subscriptions Table for AB Customers');
    printit(p_out_message => RPAD ('-',180 , '-'));
    printit(p_out_message => RPAD ('CONTRACT#', 20, ' ') || ' ' ||RPAD ('INVOICE#', 20, ' ') || ' ' || RPAD ('RECEIPT#', 20, ' '));
    printit(p_out_message => RPAD ('-', 20, '-') || ' ' || RPAD ('-', 20, '-') || ' ' || RPAD ('-', 20, '-'));
    FOR ab_txnnum_rec IN c_ab_txnnum
      LOOP
      /**************************************************************************************
      * LOOP Through the Transaction Number for which the Receipt Numbers have to be updated.
      ***************************************************************************************/
      ln_cash_receipt_id   := 0;
      lc_receipt_num       := NULL;
      ln_cnt_cash_receipts := 0;
      lc_curr_receipt_num  := NULL;
      logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------',
            p_debug   => TRUE);
      logit(p_message => 'START of updating Record of Invoice# : ' || ab_txnnum_rec.invoice_number || ' for Contract #: ' || ab_txnnum_rec.contract_number,
            p_debug   => TRUE);
      logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------',
            p_debug   => TRUE);
      BEGIN
          SELECT COUNT(ARAA.cash_receipt_id)
          INTO   ln_cnt_cash_receipts
          FROM   ar_receivable_applications_all ARAA
          WHERE  ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id;
      EXCEPTION
          WHEN OTHERS 
          THEN
            ln_cnt_cash_receipts := 0;
      END;
         IF ln_cnt_cash_receipts > 0 
         THEN
               
               ln_receipt_num_count    := 0;
               ln_tot_receipt_amt      := 0; 
               lc_receipt_created_flag := NULL;

               FOR cash_receiptid_rec IN c_cash_receiptid (ab_txnnum_rec.customer_trx_id)
                  LOOP
                    lc_prev_receipt_num  := NULL;
                    ln_prev_receipt_amt  := 0;
                    
                    BEGIN
                      SELECT ACRA.receipt_number,ARAA.amount_applied
                      INTO   lc_prev_receipt_num,ln_prev_receipt_amt
                      FROM   ar_cash_receipts_all ACRA,
                             ar_receivable_applications_all ARAA
                      WHERE  ACRA.cash_receipt_id = cash_receiptid_rec.cash_receipt_id
                      AND    ARAA.receivable_application_id = cash_receiptid_rec.receivable_application_id
                      AND    ACRA.cash_receipt_id = ARAA.cash_receipt_id
                      AND    ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id
                      AND    ARAA.status = 'APP';
                    EXCEPTION
                    WHEN OTHERS
                    THEN 
                      lc_prev_receipt_num := NULL;
                      ln_prev_receipt_amt := 0;
                    END;
                    
                    IF  (lc_prev_receipt_num IS NOT NULL)
                    THEN
                      ln_tot_receipt_amt     := ln_tot_receipt_amt + ln_prev_receipt_amt;
                    END IF;
                  END LOOP;

                BEGIN
                     SELECT MAX(ACRA.receipt_number)
                     INTO   lc_curr_receipt_num
                     FROM   ar_cash_receipts_all ACRA,
                            ar_receivable_applications_all ARAA
                     WHERE  ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id
                     AND    ARAA.status = 'APP'
                     AND    ARAA.receivable_application_id IN (SELECT MAX(ARAA1.receivable_application_id)
                                                               FROM   ar_receivable_applications_all ARAA1
                                                               WHERE  ARAA1.applied_customer_trx_id = ARAA.applied_customer_trx_id 
                                                               AND    ARAA1.cash_receipt_id = ARAA.cash_receipt_id
                                                               )
                     AND    ACRA.cash_receipt_id = ARAA.cash_receipt_id;
                EXCEPTION       
                WHEN OTHERS
                     THEN lc_curr_receipt_num := NULL;
                END;
                IF (ln_tot_receipt_amt < ab_txnnum_rec.txn_amount)
                THEN
                   lc_receipt_created_flag := 'P';
                ELSIF(ln_tot_receipt_amt = ab_txnnum_rec.txn_amount)
                THEN
                   lc_receipt_created_flag := 'Y';   
                END IF;
               IF (lc_curr_receipt_num IS NOT NULL) 
               THEN
               FOR contract_lines_rec IN c_contract_lines (ab_txnnum_rec.invoice_number,ab_txnnum_rec.contract_id)
                  LOOP
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_debug   => TRUE);
                    logit(p_message => 'Updation of Record with Contract id # : ' || ab_txnnum_rec.contract_id || ' for  Subscriptions id#: ' || contract_lines_rec.subscriptions_id || ' and  Contract Line#: ' || contract_lines_rec.contract_line_number,
                          p_debug   => TRUE);
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_debug   => TRUE); 
                   
                      UPDATE xx_ar_subscriptions XAS
                      SET    XAS.receipt_number       = lc_curr_receipt_num,
                             XAS.receipt_created_flag = lc_receipt_created_flag,
                             XAS.ordt_staged_flag     = 'Y'
                      WHERE  XAS.contract_line_number = contract_lines_rec.contract_line_number 
                      AND    XAS.subscriptions_id     = contract_lines_rec.subscriptions_id;
                  END LOOP;
                END IF; 
          END IF;
          IF (lc_curr_receipt_num IS NOT NULL) 
          THEN
            logit(p_message => '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                  p_debug   => TRUE);
            logit(p_message => 'End of Updating Record of Invoice# : ' || ab_txnnum_rec.invoice_number || ' with Receipt #: ' || lc_curr_receipt_num || ' having total Receipt Amount: ' || ln_tot_receipt_amt,
                  p_debug   => TRUE);
            logit(p_message => '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                  p_debug   => TRUE);
            printit(p_out_message => RPAD (ab_txnnum_rec.contract_number, 20, ' ') || ' ' || RPAD (ab_txnnum_rec.invoice_number, 20, ' ') || ' ' || RPAD (lc_curr_receipt_num, 20, ' '));
          ELSIF (lc_curr_receipt_num IS NULL)
          THEN
            lc_curr_receipt_num := 'No Receipt exists';
            logit(p_message => '-----------------------------------------------------------------------',
                  p_debug   => TRUE);
            logit(p_message => lc_curr_receipt_num ||' for Invoice# : ' || ab_txnnum_rec.invoice_number,
                  p_debug   => TRUE);
            logit(p_message => '-----------------------------------------------------------------------',
                  p_debug   => TRUE);
            printit(p_out_message => RPAD (ab_txnnum_rec.contract_number, 20, ' ') || ' ' || RPAD (ab_txnnum_rec.invoice_number, 20, ' ') || ' ' || RPAD (lc_curr_receipt_num, 20, ' '));
          END IF;
      END LOOP;
     COMMIT;
    EXCEPTION
    WHEN OTHERS
    THEN
       logit(p_message => '---------------------------------------------------------------------------------------------------------------',
             p_debug   => TRUE);
       logit(p_message => 'Exception while Submitting the Receipt Updation Program ' || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
             p_debug   => TRUE);
       logit(p_message => '---------------------------------------------------------------------------------------------------------------',
             p_debug   => TRUE);
       RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END txn_receiptnum_update;
END xx_ar_subscr_rcpt_upd_pkg;
/
SHOW ERRORS;
EXIT;