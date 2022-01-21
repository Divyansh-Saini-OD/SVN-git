/* Formatted on 2007/07/24 10:37 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY apps.xx_ar_lbmain_pkg
AS
/******************************************************************************
   NAME:       xx_ar_lbmain_pkg
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/1/2007      Shankar Murthy       1. Created this package body.
******************************************************************************/
   PROCEDURE xx_ar_lbmain_proc (errbuf       OUT      VARCHAR2,
      retcode      OUT      NUMBER,
      p_filename   IN       VARCHAR2
      
   )
   IS
      v_data_file                 VARCHAR2 (100);
      v_data_file1                VARCHAR2 (100);
      v_start_time                VARCHAR2 (10);
      p_request_id                NUMBER          := 0;
      v_interval                  NUMBER          := 60;
      v_max_wait                  NUMBER          := 1800;
      v_phase                     VARCHAR2 (100);
      v_status_code               VARCHAR2 (100);
      v_dev_phase                 VARCHAR2 (20);
      v_message                   VARCHAR2 (200);
      v_sub_request               VARCHAR2 (20)   := 'FALSE';
      v_call_status               BOOLEAN;
      v_request_id                NUMBER;
      v_transmission_request_id   NUMBER;
      v_transmission_name         VARCHAR2 (50);
      v_err_msg                   VARCHAR2 (20);
      v_dev_status                VARCHAR2 (20);
      v_user_id                   NUMBER;
      l_return_code               VARCHAR2 (1)    := 'E';
      l_msg_count                 NUMBER          := 0;
      l_msg_status                VARCHAR2 (4000);
      v_transmission_format_id    NUMBER;
      v_org_id                    NUMBER;
      v_new_transmission          VARCHAR2 (1)    := 'N';
      v_transmission_id           NUMBER;
      v_submit_import             VARCHAR2 (1)    := 'N';
      v_control_file              VARCHAR2 (25)   := 'xx_od_ardeft';
      v_submit_validation         VARCHAR2 (1)    := 'Y';
      v_pay_unrelated_invoices    VARCHAR2 (1)    := 'N';
      v_lockbox_id                NUMBER;
      v_gl_date                   DATE
                                  := TO_DATE (TO_CHAR (SYSDATE, 'dd-mon-yy'));
      v_gl_date1                  VARCHAR2 (20)
                                            := TO_CHAR (SYSDATE, 'dd-mon-yy HH24:MI:SS');
      v_report_format             VARCHAR2 (1);
      v_complete_batches_only     VARCHAR2 (1)    := 'N';
      v_submit_postbatch          VARCHAR2 (1)    := 'Y';
      v_alternate_name_search     VARCHAR2 (1);
      v_ignore_invalid_txn_num    VARCHAR2 (1)    := 'Y';
      v_ussgl_transaction_code    VARCHAR2 (25);
      v_count                     NUMBER;
      v_request_id1                number ;
   BEGIN
      v_user_id := fnd_profile.VALUE ('USER_ID');
      v_org_id := fnd_profile.VALUE ('ORG_ID');
      v_data_file :=
         SUBSTR (p_filename,
                   INSTR (p_filename,
                          '/',
                          -1,
                          1
                         )
                 + 1
                );                                     --NVL (p_filename, '');

      -- Retrieve Transmission Format Id 
      SELECT transmission_format_id
        INTO v_transmission_format_id
        FROM ar_transmission_formats
       WHERE format_name = 'OD_US BOA LOCKBOX';

      --- Retrieve Transmission Name.
      SELECT transmission_name
        INTO v_transmission_name
        FROM ar_transmissions_all
       WHERE transmission_name = v_data_file;

      -- If transmission already exists raise an error
      IF v_transmission_name IS NOT NULL
      THEN
         fnd_message.CLEAR;
         fnd_message.set_name ('XXFIN', 'XX_AR_TRANSMISSIONEXISTS');
         --  fnd_message.set_token ('TRXNUMBER', v_trx_number1);
         l_msg_count := l_msg_count + 1;
         l_msg_status := fnd_message.get ();
         xx_com_error_log_pub.log_error
                              (p_program_type                => 'SQLSCRIPT',
                               p_program_name                => 'TRANSMISSION_NAME',
                               p_program_id                  => 23456,
                               p_module_name                 => 'AR',
                               p_error_location              => 'CHECK TRANSMISSION NAME',
                               p_error_message_count         => 1,
                               p_error_message_code          => 'E',
                               p_error_message               => l_msg_status,
                               p_error_message_severity      => 'NORMAL',
                               p_notify_flag                 => 'N',
                               p_object_type                 => 'TRANSMISSION NAME',
                               p_object_id                   => 1,
                                                 --TO_CHAR
                                                 --(v_payment_interface.transmission_record_id
                               -- ),
                               p_attribute1                  => 'FIN',
                               p_attribute2                  => 'AR',
                               p_return_code                 => l_return_code,
                               p_msg_count                   => l_msg_count
                              );
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         -- Load data into Custom Interface table .
         v_request_id :=
            apps.fnd_request.submit_request ('xxfin',
                                             'XXARLBLOAD',
                                             'Custom lockbox loader prorgam',
                                             v_gl_date1,
                                             FALSE,
                                             --v_data_file1,
                                             p_filename,
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             '',
                                             ''
                                            );
         COMMIT;
         fnd_file.put_line (fnd_file.LOG,
                            'The request id is :' || '  ' || v_request_id
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_gl_date1 is :' || '  ' || v_gl_date1
                           );                           
         if v_request_id > 0  then
         v_call_status :=
            fnd_concurrent.wait_for_request (v_request_id,
                                             10,
                                             0,
                                             v_phase,
                                             v_status_code,
                                             v_dev_phase,
                                             v_dev_status,
                                             v_message
                                            );
        end if;                                            
         v_request_id1  := v_request_id ;
         fnd_file.put_line (fnd_file.LOG,
                            'The status Code is:' || '  ' || v_status_code
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_phase is:' || '  ' || v_phase);
         fnd_file.put_line (fnd_file.LOG,
                            'The v_dev_phase is:' || '  ' || v_dev_phase
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_dev_status is:' || '  ' || v_dev_status
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_message is:' || '  ' || v_message
                           );

         --DBMS_OUTPUT.put_line ('The status code is :' || '  ' || v_status_code);
         --DBMS_OUTPUT.put_line ('The Dev Phase is :' || '  ' || v_dev_phase);
         --DBMS_OUTPUT.put_line (   'The Dev status code is :'
             --                  || '  '
             --                  || v_dev_status
                           --   );
         --DBMS_OUTPUT.put_line ('The Message is :' || '  ' || v_message);

         -- Insert relevant values into the transmissions table .
        IF trim(v_status_code) in ('Normal','Warning') THEN    

                SELECT count(*)
                INTO    v_count
                FROM    xx_ar_paymentsinterface ;
                
                fnd_file.put_line(fnd_file.log,'Loaded Records: '||v_count);         
           
               
           
        
         
            
            

            SELECT ar_transmissions_s.NEXTVAL
              INTO v_transmission_id
              FROM DUAL;

            SELECT fnd_concurrent_requests_s.NEXTVAL
              INTO v_transmission_request_id
              FROM DUAL;

            INSERT INTO ar_transmissions_all
                        (transmission_request_id, created_by, creation_date,
                         last_updated_by, last_update_date,
                         transmission_name, transmission_id,
                         requested_trans_format_id, org_id,
                         latest_request_id
                        )
                 VALUES (v_transmission_request_id, v_user_id, SYSDATE,
                         v_user_id, SYSDATE,
                         v_data_file , v_transmission_id,
                         v_transmission_format_id, v_org_id,
                         v_transmission_request_id
                        );

            COMMIT;
            
            fnd_file.put_line (fnd_file.LOG,
                            'The v_transmission_request_id is:' || '  ' || v_transmission_request_id
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_transmission_id is:' || '  ' || v_transmission_id);
         fnd_file.put_line (fnd_file.LOG,
                            'The v_transmission_format_id is:' || '  ' || v_transmission_format_id
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_transmission_request_id is:' || '  ' || v_transmission_request_id
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'The v_data_file TRUNC (SYSDATE):' || '  ' || v_data_file || TRUNC (SYSDATE)
                           );
            fnd_file.put_line
                            (fnd_file.LOG,
                             'Inserted record into AR_TRANSMISSIONS_ALL table'
                            );
            -- Execute the custom autocash program
            xx_lockbox_autocashrules_pkg.xx_ar_autocashrules_proc;
            -- Insert records from the custom interface table into the
            --  seeded  interface table .
            v_count := 0;

            INSERT INTO ar_payments_interface_all
                        (ACCOUNT, amount_applied1, amount_applied2,
                         amount_applied3, amount_applied4, amount_applied5,
                         amount_applied6, amount_applied7, amount_applied8,
                         amount_applied_from1, amount_applied_from2,
                         amount_applied_from3, amount_applied_from4,
                         amount_applied_from5, amount_applied_from6,
                         amount_applied_from7, amount_applied_from8,
                         anticipated_clearing_date, application_notes,
                         attribute1, attribute10, attribute11, attribute12,
                         attribute13, attribute14, attribute15, attribute2,
                         attribute3, attribute4, attribute5, attribute6,
                         attribute7, attribute8, attribute9,
                         attribute_category, bank_trx_code, batch_amount,
                         batch_name, batch_record_count, bill_to_location,
                         check_number, comments, cpg_association_flag,
                         cpg_batch_date, cpg_batch_sequence_number,
                         cpg_batch_source, cpg_batch_status,
                         cpg_customer_ref_number,
                         cpg_cust_deduction_reason_code,
                         cpg_negative_trx_indicator, cpg_original_trx_number,
                         cpg_orig_batch_name, cpg_orig_lockbox_number,
                         cpg_orig_remittance_amount, cpg_postmark_date,
                         cpg_process_status, cpg_purchase_order_number,
                         cpg_reassociation_trace_num, cpg_receipt_amount,
                         cpg_receipt_count, cpg_receipt_status,
                         cpg_ship_to_location_number, cpg_transaction_date,
                         cpg_trx_handling_code, created_by, creation_date,
                         currency_code, customer_bank_account_id,
                         customer_bank_branch_name, customer_bank_name,
                         customer_id, customer_name_alt, customer_number,
                         customer_reason1, customer_reason2, customer_reason3,
                         customer_reason4, customer_reason5, customer_reason6,
                         customer_reason7, customer_reason8,
                         customer_reference1, customer_reference2,
                         customer_reference3, customer_reference4,
                         customer_reference5, customer_reference6,
                         customer_reference7, customer_reference8,
                         customer_site_use_id, deposit_date, deposit_time,
                         destination_account, exchange_rate,
                         exchange_rate_type, global_attribute1,
                         global_attribute10, global_attribute11,
                         global_attribute12, global_attribute13,
                         global_attribute14, global_attribute15,
                         global_attribute16, global_attribute17,
                         global_attribute18, global_attribute19,
                         global_attribute2, global_attribute20,
                         global_attribute3, global_attribute4,
                         global_attribute5, global_attribute6,
                         global_attribute7, global_attribute8,
                         global_attribute9, global_attribute_category,
                         gl_date, invoice1, invoice1_installment,
                         invoice1_status, invoice2, invoice2_installment,
                         invoice2_status, invoice3, invoice3_installment,
                         invoice3_status, invoice4, invoice4_installment,
                         invoice4_status, invoice5, invoice5_installment,
                         invoice5_status, invoice6, invoice6_installment,
                         invoice6_status, invoice7, invoice7_installment,
                         invoice7_status, invoice8, invoice8_installment,
                         invoice8_status, invoice_currency_code1,
                         invoice_currency_code2, invoice_currency_code3,
                         invoice_currency_code4, invoice_currency_code5,
                         invoice_currency_code6, invoice_currency_code7,
                         invoice_currency_code8, item_number, last_updated_by,
                         last_update_date, last_update_login, lockbox_amount,
                         lockbox_batch_count, lockbox_number,
                         lockbox_record_count, matching1_date, matching2_date,
                         matching3_date, matching4_date, matching5_date,
                         matching6_date, matching7_date, matching8_date,
                         match_resolved_using, org_id, origination,
                         overflow_indicator, overflow_sequence, receipt_date,
                         receipt_method, receipt_method_id, record_type,
                         remittance_amount, remittance_bank_branch_name,
                         remittance_bank_name, resolved_matching1_date,
                         resolved_matching1_installment,
                         resolved_matching2_date,
                         resolved_matching2_installment,
                         resolved_matching3_date,
                         resolved_matching3_installment,
                         resolved_matching4_date,
                         resolved_matching4_installment,
                         resolved_matching5_date,
                         resolved_matching5_installment,
                         resolved_matching6_date,
                         resolved_matching6_installment,
                         resolved_matching7_date,
                         resolved_matching7_installment,
                         resolved_matching8_date,
                         resolved_matching8_installment,
                         resolved_matching_number1, resolved_matching_number2,
                         resolved_matching_number3, resolved_matching_number4,
                         resolved_matching_number5, resolved_matching_number6,
                         resolved_matching_number7, resolved_matching_number8,
                         special_type, status, tmp_amt_applied1,
                         tmp_amt_applied2, tmp_amt_applied3, tmp_amt_applied4,
                         tmp_amt_applied5, tmp_amt_applied6, tmp_amt_applied7,
                         tmp_amt_applied8, tmp_amt_applied_from1,
                         tmp_amt_applied_from2, tmp_amt_applied_from3,
                         tmp_amt_applied_from4, tmp_amt_applied_from5,
                         tmp_amt_applied_from6, tmp_amt_applied_from7,
                         tmp_amt_applied_from8, tmp_inv_currency_code1,
                         tmp_inv_currency_code2, tmp_inv_currency_code3,
                         tmp_inv_currency_code4, tmp_inv_currency_code5,
                         tmp_inv_currency_code6, tmp_inv_currency_code7,
                         tmp_inv_currency_code8, tmp_trans_to_rcpt_rate1,
                         tmp_trans_to_rcpt_rate2, tmp_trans_to_rcpt_rate3,
                         tmp_trans_to_rcpt_rate4, tmp_trans_to_rcpt_rate5,
                         tmp_trans_to_rcpt_rate6, tmp_trans_to_rcpt_rate7,
                         tmp_trans_to_rcpt_rate8, transferred_receipt_amount,
                         transferred_receipt_count, transit_routing_number,
                         transmission_amount, transmission_id,
                         transmission_record_count, transmission_record_id,
                         transmission_request_id, trans_to_receipt_rate1,
                         trans_to_receipt_rate2, trans_to_receipt_rate3,
                         trans_to_receipt_rate4, trans_to_receipt_rate5,
                         trans_to_receipt_rate6, trans_to_receipt_rate7,
                         trans_to_receipt_rate8, ussgl_transaction_code,
                         ussgl_transaction_code1, ussgl_transaction_code2,
                         ussgl_transaction_code3, ussgl_transaction_code4,
                         ussgl_transaction_code5, ussgl_transaction_code6,
                         ussgl_transaction_code7, ussgl_transaction_code8)
               SELECT ACCOUNT, amount_applied1, amount_applied2,
                      amount_applied3, amount_applied4, amount_applied5,
                      amount_applied6, amount_applied7, amount_applied8,
                      amount_applied_from1, amount_applied_from2,
                      amount_applied_from3, amount_applied_from4,
                      amount_applied_from5, amount_applied_from6,
                      amount_applied_from7, amount_applied_from8,
                      anticipated_clearing_date, application_notes,
                      attribute1, attribute10, attribute11, attribute12,
                      attribute13, attribute14, attribute15, attribute2,
                      attribute3, attribute4, attribute5, attribute6,
                      attribute7, attribute8, attribute9, attribute_category,
                      bank_trx_code, batch_amount, batch_name,
                      batch_record_count, bill_to_location, check_number,
                      comments, cpg_association_flag, cpg_batch_date,
                      cpg_batch_sequence_number, cpg_batch_source,
                      cpg_batch_status, cpg_customer_ref_number,
                      cpg_cust_deduction_reason_code,
                      cpg_negative_trx_indicator, cpg_original_trx_number,
                      cpg_orig_batch_name, cpg_orig_lockbox_number,
                      cpg_orig_remittance_amount, cpg_postmark_date,
                      cpg_process_status, cpg_purchase_order_number,
                      cpg_reassociation_trace_num, cpg_receipt_amount,
                      cpg_receipt_count, cpg_receipt_status,
                      cpg_ship_to_location_number, cpg_transaction_date,
                      cpg_trx_handling_code, created_by, creation_date,
                      currency_code, customer_bank_account_id,
                      customer_bank_branch_name, customer_bank_name,
                      customer_id, customer_name_alt, customer_number,
                      customer_reason1, customer_reason2, customer_reason3,
                      customer_reason4, customer_reason5, customer_reason6,
                      customer_reason7, customer_reason8, customer_reference1,
                      customer_reference2, customer_reference3,
                      customer_reference4, customer_reference5,
                      customer_reference6, customer_reference7,
                      customer_reference8, customer_site_use_id, deposit_date,
                      deposit_time, destination_account, exchange_rate,
                      exchange_rate_type, global_attribute1,
                      global_attribute10, global_attribute11,
                      global_attribute12, global_attribute13,
                      global_attribute14, global_attribute15,
                      global_attribute16, global_attribute17,
                      global_attribute18, global_attribute19,
                      global_attribute2, global_attribute20,
                      global_attribute3, global_attribute4, global_attribute5,
                      global_attribute6, global_attribute7, global_attribute8,
                      global_attribute9, global_attribute_category, gl_date,
                      invoice1, invoice1_installment, invoice1_status,
                      invoice2, invoice2_installment, invoice2_status,
                      invoice3, invoice3_installment, invoice3_status,
                      invoice4, invoice4_installment, invoice4_status,
                      invoice5, invoice5_installment, invoice5_status,
                      invoice6, invoice6_installment, invoice6_status,
                      invoice7, invoice7_installment, invoice7_status,
                      invoice8, invoice8_installment, invoice8_status,
                      invoice_currency_code1, invoice_currency_code2,
                      invoice_currency_code3, invoice_currency_code4,
                      invoice_currency_code5, invoice_currency_code6,
                      invoice_currency_code7, invoice_currency_code8,
                      item_number, last_updated_by, last_update_date,
                      last_update_login, lockbox_amount, lockbox_batch_count,
                      lockbox_number, lockbox_record_count, matching1_date,
                      matching2_date, matching3_date, matching4_date,
                      matching5_date, matching6_date, matching7_date,
                      matching8_date, match_resolved_using, org_id,
                      origination, overflow_indicator, overflow_sequence,
                      receipt_date, receipt_method, receipt_method_id,
                      record_type, remittance_amount,
                      remittance_bank_branch_name, remittance_bank_name,
                      resolved_matching1_date, resolved_matching1_installment,
                      resolved_matching2_date, resolved_matching2_installment,
                      resolved_matching3_date, resolved_matching3_installment,
                      resolved_matching4_date, resolved_matching4_installment,
                      resolved_matching5_date, resolved_matching5_installment,
                      resolved_matching6_date, resolved_matching6_installment,
                      resolved_matching7_date, resolved_matching7_installment,
                      resolved_matching8_date, resolved_matching8_installment,
                      resolved_matching_number1, resolved_matching_number2,
                      resolved_matching_number3, resolved_matching_number4,
                      resolved_matching_number5, resolved_matching_number6,
                      resolved_matching_number7, resolved_matching_number8,
                      special_type, status, tmp_amt_applied1,
                      tmp_amt_applied2, tmp_amt_applied3, tmp_amt_applied4,
                      tmp_amt_applied5, tmp_amt_applied6, tmp_amt_applied7,
                      tmp_amt_applied8, tmp_amt_applied_from1,
                      tmp_amt_applied_from2, tmp_amt_applied_from3,
                      tmp_amt_applied_from4, tmp_amt_applied_from5,
                      tmp_amt_applied_from6, tmp_amt_applied_from7,
                      tmp_amt_applied_from8, tmp_inv_currency_code1,
                      tmp_inv_currency_code2, tmp_inv_currency_code3,
                      tmp_inv_currency_code4, tmp_inv_currency_code5,
                      tmp_inv_currency_code6, tmp_inv_currency_code7,
                      tmp_inv_currency_code8, tmp_trans_to_rcpt_rate1,
                      tmp_trans_to_rcpt_rate2, tmp_trans_to_rcpt_rate3,
                      tmp_trans_to_rcpt_rate4, tmp_trans_to_rcpt_rate5,
                      tmp_trans_to_rcpt_rate6, tmp_trans_to_rcpt_rate7,
                      tmp_trans_to_rcpt_rate8, transferred_receipt_amount,
                      transferred_receipt_count, transit_routing_number,
                      transmission_amount, transmission_id,
                      transmission_record_count, transmission_record_id,
                      transmission_request_id, trans_to_receipt_rate1,
                      trans_to_receipt_rate2, trans_to_receipt_rate3,
                      trans_to_receipt_rate4, trans_to_receipt_rate5,
                      trans_to_receipt_rate6, trans_to_receipt_rate7,
                      trans_to_receipt_rate8, ussgl_transaction_code,
                      ussgl_transaction_code1, ussgl_transaction_code2,
                      ussgl_transaction_code3, ussgl_transaction_code4,
                      ussgl_transaction_code5, ussgl_transaction_code6,
                      ussgl_transaction_code7, ussgl_transaction_code8
                 FROM xxfin.xx_ar_paymentsinterface;

            COMMIT;

            SELECT COUNT (1)
              INTO v_count
              FROM ar_payments_interface_all;

            IF v_count > 0
            THEN
               fnd_file.put_line
                      (fnd_file.LOG,
                       'Inserted record into AR_PAYMENTS_INTERFACE_ALL table'
                      );
            ELSE
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Insert record into AR_PAYMENTS_INTERFACE_ALL table Failed'
                  );
            END IF;

            -- Design based on Multiple Lockboxes .
            -- execute the seeded Lockbox Interface Program for each Lockbox.
            DECLARE
               CURSOR c_lockbox_interface
               IS
                  SELECT DISTINCT lockbox_number lockbox_number
                             FROM ar_payments_interface_all
                            WHERE record_type IN (5)                  -- 7, 8
                                                    ;
            BEGIN
               FOR v_lockbox_interface IN c_lockbox_interface
               LOOP
                  fnd_file.put_line (fnd_file.LOG,
                                        'Lockbox Number is:'
                                     || '  '
                                     || v_lockbox_interface.lockbox_number
                                    );

                  SELECT lockbox_id
                    INTO v_lockbox_id
                    FROM ar_lockboxes_all
                   WHERE TRIM (lockbox_number) =
                                     TRIM (v_lockbox_interface.lockbox_number);

                  --v_request_id := 0;
                  fnd_file.put_line (fnd_file.LOG,
                                        'The new_transmission is'
                                     || '  '
                                     || v_new_transmission
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                        'The transmission_name is'
                                     || '  '
                                     || v_data_file
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                        'The transmission_request_id is'
                                     || '  '
                                     || v_transmission_request_id
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'The data_file1 is' || '  '
                                     || p_filename
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                        'The control_file is'
                                     || '  '
                                     || v_control_file
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'The lockbox_id is' || '  '
                                     || v_lockbox_id
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'The org_id, is' || '  ' || v_org_id
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                        'The transmission_format_id is'
                                     || '  '
                                     || v_transmission_format_id
                                    );
                  v_request_id :=
                     apps.fnd_request.submit_request
                                                   ('AR',
                                                    'ARLPLB',
                                                    null,
                                                    null,--v_gl_date1,--'01-JUN-04 00:00:00',
                                                    FALSE,
                                                    v_new_transmission,
                                                    v_transmission_id,
                                                    v_transmission_request_id,
                                                    v_data_file,
                                                    v_submit_import,
                                                    '',
                                                    '',
                                                    v_transmission_format_id,
                                                    v_submit_validation,
                                                    v_pay_unrelated_invoices,
                                                    v_lockbox_id,
                                                    '',
                                                    'A',
                                                    v_complete_batches_only,  
                                                    v_submit_postbatch,
                                                    'N',
                                                    '',
                                                    '',
                                                    v_org_id,
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    '',
                                                    ''
                                                   );
                                                   
                                                                    
                  COMMIT;
                  
                  
                  fnd_file.put_line (fnd_file.LOG,
                                     'The v_transmission_id is' || '  '
                                     || v_transmission_id
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'The v_transmission_request_id is' || '  '
                                     || v_transmission_request_id
                                    );    
                  fnd_file.put_line (fnd_file.LOG,
                                     'The v_data_file is' || '  '
                                     || v_data_file
                                    );  
                  fnd_file.put_line (fnd_file.LOG,
                                     'The v_lockbox_id is' || '  '
                                     || v_lockbox_id
                                    );                                                                                                                                              
                  fnd_file.put_line (fnd_file.LOG,
                                     'The request id is' || '  '
                                     || v_request_id
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'Standard Lockbox Program executed'
                                    );

                  BEGIN
                     SELECT NVL (status_code, '')
                       INTO v_status_code
                       FROM fnd_concurrent_requests
                      WHERE request_id = v_request_id;

                     IF v_status_code = 'C'                         -- success
                     THEN
                        NULL;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        fnd_message.CLEAR;
                        fnd_message.set_name ('XXFIN', 'XX_AR_ARLPLB_ERROR');
                        --fnd_message.set_token ('TRXNUMBER', v_trx_number1);
                        l_msg_count := l_msg_count + 1;
                        l_msg_status := fnd_message.get ();
                        xx_com_error_log_pub.log_error
                             (p_program_type                => 'CONCURRENT PROGRAM',
                              p_program_name                => 'ARLPLB',
                              p_program_id                  => 23456,
                              p_module_name                 => 'AR',
                              p_error_location              => 'STANDARD LOCKBOX PROCESS',
                              p_error_message_count         => 1,
                              p_error_message_code          => 'E',
                              p_error_message               => l_msg_status,
                              p_error_message_severity      => 'NORMAL',
                              p_notify_flag                 => 'N',
                              p_object_type                 => 'RECEIPT',
                              p_object_id                   => 1,
                                               --TO_CHAR
                                               --(v_payment_interface.transmission_record_id
                              -- ),
                              p_attribute1                  => 'FIN',
                              p_attribute2                  => 'AR',
                              p_return_code                 => l_return_code,
                              p_msg_count                   => l_msg_count
                             );
                  END;
               END LOOP;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  fnd_file.put_line (fnd_file.LOG,
                                     'Lockbox number does not exist'
                                    );
            END;
         ELSE
            fnd_message.CLEAR;
            fnd_message.set_name ('XXFIN', 'XX_AR_XXARLBLOAD_ERROR');
            --fnd_message.set_token ('TRXNUMBER', v_trx_number1);
            l_msg_count := l_msg_count + 1;
            l_msg_status := fnd_message.get ();
            xx_com_error_log_pub.log_error
                                     (p_program_type                => 'CONCURRENT PROGRAM',
                                      p_program_name                => 'XXARLBLOAD',
                                      p_program_id                  => 23456,
                                      p_module_name                 => 'AR',
                                      p_error_location              => 'SQLLOADER',
                                      p_error_message_count         => 1,
                                      p_error_message_code          => 'E',
                                      p_error_message               => l_msg_status,
                                      p_error_message_severity      => 'NORMAL',
                                      p_notify_flag                 => 'N',
                                      p_object_type                 => 'DATAFILE',
                                      p_object_id                   => 1,
                                                       --TO_CHAR
                                                       --(v_payment_interface.transmission_record_id
                                      -- ),
                                      p_attribute1                  => 'FIN',
                                      p_attribute2                  => 'AR',
                                      p_return_code                 => l_return_code,
                                      p_msg_count                   => l_msg_count
                                     );
           
                                               
         END IF;
      WHEN OTHERS
      THEN
         fnd_message.CLEAR;
         fnd_message.set_name ('XXFIN', 'XX_AR_SYSTEM_ERROR');
         --fnd_message.set_token ('TRXNUMBER', v_trx_number1);
         l_msg_count := l_msg_count + 1;
         l_msg_status := fnd_message.get ();
         xx_com_error_log_pub.log_error
                                     (p_program_type                => 'CONCURRENT PROGRAM',
                                      p_program_name                => 'ARLBMAIN',
                                      p_program_id                  => 23456,
                                      p_module_name                 => 'AR',
                                      p_error_location              => 'CUSTOM PROGRAM',
                                      p_error_message_count         => 1,
                                      p_error_message_code          => 'E',
                                      p_error_message               => l_msg_status,
                                      p_error_message_severity      => 'SEVERE',
                                      p_notify_flag                 => 'N',
                                      p_object_type                 => 'RECEIPT',
                                      p_object_id                   => 1,
                                                       --TO_CHAR
                                                       --(v_payment_interface.transmission_record_id
                                      -- ),
                                      p_attribute1                  => 'FIN',
                                      p_attribute2                  => 'AR',
                                      p_return_code                 => l_return_code,
                                      p_msg_count                   => l_msg_count
                                     );
   END;
END xx_ar_lbmain_pkg;
/
