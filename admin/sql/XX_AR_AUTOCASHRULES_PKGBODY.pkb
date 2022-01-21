/* Formatted on 2007/07/22 17:30 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY xx_lockbox_autocashrules_pkg
AS
/******************************************************************************
   NAME:       XX_LOCKBOX_AUTOCASHRULES_PKG
   PURPOSE:

   REVISIONS:
   Ver        Date          Author                                Description
   ---------  ----------   -----------------        ------------------------------------
   1.0        5/4/2007      Shankar Murthy             1. Created this package body.
******************************************************************************/
   PROCEDURE xx_ar_autocashrules_proc
   IS
      CURSOR c_payment_interface
      IS
         SELECT a.*
           FROM xx_ar_paymentsinterface a
          WHERE NOT EXISTS (
                   SELECT trx_number
                     FROM ar_payment_schedules_all b
                    WHERE b.cust_trx_type_id IN (
                                    SELECT r.cust_trx_type_id
                                      FROM ra_cust_trx_types_all r
                                     WHERE r.TYPE IN
                                                   ('INV', 'DM', 'CM', 'CB'))
                      AND (    b.trx_number = a.invoice1
                           AND b.trx_number = a.invoice2
                           AND b.trx_number = a.invoice3
                          ))
            AND a.record_type IN (4, 6);

      v_customer_number          VARCHAR2 (100);
      v_invoice_number1          VARCHAR2 (12);
      v_invoice_number2          VARCHAR2 (12);
      v_invoice_number3          VARCHAR2 (12);
      --p_invoice_number         varchar2(12);

      --v_transmission_record_id number;
      --v_success_counter        number;
      v_invoice_amount1          NUMBER;
      v_invoice_amount2          NUMBER;
      v_invoice_amount3          NUMBER;
      v_deposit_date             DATE;
      v_cust_account_id          NUMBER;
      v_attribute12              xx_ar_paymentsinterface.attribute12%TYPE;
      --v_cons_inv_id            varchar2(25);
      v_consolidated_billing     VARCHAR2 (25);
      inv_bool1                  VARCHAR2 (10);
      inv_bool2                  VARCHAR2 (10);
      inv_bool3                  VARCHAR2 (10);
      v_success1                 VARCHAR2 (10);
      v_success2                 VARCHAR2 (10);
      v_success3                 VARCHAR2 (10);
      v_micr_number              VARCHAR2 (50);
      v_discount_percent         VARCHAR2 (2);
      v_amount_due_original      NUMBER;
      v_customer_trx_id          NUMBER;
      v_count1                   NUMBER;
      v_count2                   NUMBER;
      v_count3                   NUMBER;
      v_max_date                 DATE;
      v_min_date                 DATE;
      v_date                     DATE;
      v_due_date                 DATE                 := TRUNC (SYSDATE, 'MM');
      v_due_date1                DATE                 := TRUNC (SYSDATE, 'mm');
      v_last_day                 DATE;
      date_diff                  NUMBER                                  := 16;
      v_date_diff                NUMBER;
      v_month                    VARCHAR2 (5);
      v_year                     VARCHAR2 (5);
      v_count_due_date           NUMBER                                   := 0;
      p_num                      NUMBER                                   := 0;
      n                          NUMBER                                   := 0;
      p                          NUMBER                                   := 0;
      k                          NUMBER                                   := 0;
      v_trx                      NUMBER                                   := 0;
      v_amount_due_original1     NUMBER                                   := 0;
      v_amount_due_original2     NUMBER                                   := 0;
      v_amount_due_original3     NUMBER                                   := 0;
      v_amount_due_original4     NUMBER                                   := 0;
      v_amount_due_original5     NUMBER                                   := 0;
      l_return_code              VARCHAR2 (1)                           := 'E';
      l_msg_count                NUMBER                                   := 0;
      l_msg_status               VARCHAR2 (4000);
      v_overflow_sequence        xx_ar_paymentsinterface.overflow_sequence%TYPE
                                                                          := 0;

      TYPE numbers IS TABLE OF VARCHAR2 (25)
         INDEX BY BINARY_INTEGER;

      v_number                   numbers;
      -- trxnumber                VARCHAR2 (20);
      v_trx_number1              ar_payment_schedules_all.trx_number%TYPE;
      v_trx_number2              ar_payment_schedules_all.trx_number%TYPE;
      v_trx_number3              ar_payment_schedules_all.trx_number%TYPE;
      v_trx_number4              ar_payment_schedules_all.trx_number%TYPE;
      v_trx_number5              ar_payment_schedules_all.trx_number%TYPE;
      --v_overflow_sequence      NUMBER                                     := 0;
      v_insert_trx_number1       ar_payment_schedules_all.trx_number%TYPE;
      v_insert_trx_number2       ar_payment_schedules_all.trx_number%TYPE;
      v_insert_trx_number3       ar_payment_schedules_all.trx_number%TYPE;
      v_record_type              xx_ar_paymentsinterface.record_type%TYPE;
      v_transmission_record_id   xx_ar_paymentsinterface.transmission_record_id%TYPE;
      sql_stmt                   VARCHAR2 (200);
   BEGIN
      -- This is to facilitate insert records into the custom interface table
      SELECT MAX (overflow_sequence)
        INTO v_overflow_sequence
        FROM xx_ar_paymentsinterface;

      FOR v_payment_interface IN c_payment_interface
      LOOP
         ---looping through each record.
         --get the following values ;
         v_customer_number := v_payment_interface.customer_number;
         v_invoice_number1 := v_payment_interface.invoice1;
         v_invoice_number2 := v_payment_interface.invoice2;
         v_invoice_number3 := v_payment_interface.invoice3;
         v_invoice_amount1 := v_payment_interface.amount_applied1;
         v_invoice_amount2 := v_payment_interface.amount_applied2;
         v_invoice_amount3 := v_payment_interface.amount_applied3;
         v_deposit_date := v_payment_interface.deposit_date;
         v_transmission_record_id :=
                                   v_payment_interface.transmission_record_id;
         --v_transmission_record_id := v_payment_interface.transmission_record_id;
         v_micr_number :=
               v_payment_interface.transit_routing_number
            || v_payment_interface.ACCOUNT;

         IF v_payment_interface.record_type = 6
         THEN
            BEGIN
               -- get the customer id
               SELECT cust_account_id
                 INTO v_cust_account_id
                 FROM hz_cust_accounts
                WHERE account_number = v_customer_number;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT c.customer_id
                       INTO v_cust_account_id
                       FROM ap_bank_branches b,
                            ap_bank_accounts_all a,
                            ap_bank_account_uses_all c
                      WHERE b.bank_branch_id = a.bank_branch_id
                        AND a.bank_account_id = c.external_bank_account_id
                        AND b.bank_num || a.bank_account_num = v_micr_number;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        fnd_file.put_line
                                 (fnd_file.LOG,
                                  'No Customer Id -- Process cannot continue'
                                 );
                  END;
            END;
         END IF;

         BEGIN
            -- For a customer get the profile to find out whether he is
            -- set up to receive a consolidated bill or individual invoice.
            -- if the customer number is null then retrieve the MICR number.
            SELECT 'CONSOLIDATED BILLING'
              INTO v_consolidated_billing
              FROM ar_customer_profiles_v
             WHERE customer_id = v_cust_account_id
               AND lockbox_matching_option_name =
                                                 'Consolidated Billing Number';

            IF v_consolidated_billing IS NOT NULL
            THEN
               SELECT cons_inv_id
                 INTO v_trx_number1
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND cons_inv_id = v_invoice_number1
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number1 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Consolidated
                            Number'
                      || '  '
                      || v_trx_number1
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool1 := 'FALSE';
               ELSE
                  inv_bool1 := 'TRUE';
               END IF;
                  
               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number1);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );

               SELECT cons_inv_id
                 INTO v_trx_number2
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND cons_inv_id = v_invoice_number2
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number2 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Consolidated
                            Number'
                      || '  '
                      || v_trx_number2
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool2 := 'FALSE';
               ELSE
                  inv_bool2 := 'TRUE';
               END IF;

               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number2);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );

               SELECT cons_inv_id
                 INTO v_trx_number3
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND cons_inv_id = v_invoice_number3
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number3 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Consolidated
                            Number'
                      || '  '
                      || v_trx_number3
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool3 := 'FALSE';
               ELSE
                  inv_bool3 := 'TRUE';
               END IF;

               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number3);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );
            ELSE
               SELECT trx_number
                 INTO v_trx_number1
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND trx_number = v_invoice_number1
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number1 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Transaction
                            Number'
                      || '  '
                      || v_trx_number1
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool1 := 'FALSE';
               ELSE
                  inv_bool1 := 'TRUE';
               END IF;

               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number1);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );

               SELECT trx_number
                 INTO v_trx_number2
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND trx_number = v_invoice_number2
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number2 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Transaction
                            Number'
                      || '  '
                      || v_trx_number2
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool2 := 'FALSE';
               ELSE
                  inv_bool2 := 'TRUE';
               END IF;

               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number2);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );

               SELECT trx_number
                 INTO v_trx_number3
                 FROM ar_payment_schedules_all
                WHERE customer_id = v_cust_account_id
                  AND trx_number = v_invoice_number3
                  AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

               IF v_trx_number3 IS NOT NULL
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                         'This Transaction
                            Number'
                      || '  '
                      || v_trx_number3
                      || '  '
                      || 'exists in Oracle'
                     );
                  inv_bool3 := 'FALSE';
               ELSE
                  inv_bool3 := 'TRUE';
               END IF;

               fnd_message.CLEAR;
               fnd_message.set_name ('XXFIN', 'XX_AR_TRXNOEXISTS');
               fnd_message.set_token ('TRXNUMBER', v_trx_number3);
               l_msg_count := l_msg_count + 1;
               l_msg_status := fnd_message.get ();
               xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'XXFINSENDINV',
                   p_program_id                  => 12345,
                   p_module_name                 => 'GET_INVOICE',
                   p_error_location              => 'Fetch Invoice Number',
                   p_error_message_count         => 1,
                   p_error_message_code          => 'E',
                   p_error_message               => l_msg_status,
                   p_error_message_severity      => 'NORMAL',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'Invoice',
                   p_object_id                   => TO_CHAR
                                                       (v_payment_interface.transmission_record_id
                                                       ),
                   p_attribute1                  => 'FIN',
                   p_attribute2                  => 'AR',
                   p_return_code                 => l_return_code,
                   p_msg_count                   => l_msg_count
                  );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               inv_bool1 := 'TRUE';
               inv_bool2 := 'TRUE';
               inv_bool3 := 'TRUE';
         END;

         -- Gross up the Invoice amount
         BEGIN
            SELECT tld.discount_percent
              INTO v_discount_percent
              FROM apps.ar_payment_schedules_all aps,
                   apps.ra_terms_tl tl,
                   apps.ra_terms_lines_discounts tld
             WHERE aps.term_id = tl.term_id
               AND tl.term_id = tld.term_id
               AND aps.customer_id = v_cust_account_id
               AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
               AND TRUNC (aps.due_date) >= v_deposit_date;

            v_invoice_amount1 :=
                          v_invoice_amount1
                          * (100 / 100 - v_discount_percent);
            v_invoice_amount2 :=
                          v_invoice_amount2
                          * (100 / 100 - v_discount_percent);
            v_invoice_amount3 :=
                          v_invoice_amount3
                          * (100 / 100 - v_discount_percent);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            v_success1 := 'FALSE';
            v_success2 := 'FALSE';
            v_success3 := 'FALSE';
                fnd_file.put_line
                     (fnd_file.LOG,
                         'inv_bool1'
                      || '  '
                      || inv_bool1
                      || '  '
                      || ''
                     );
                     
                     fnd_file.put_line
                     (fnd_file.LOG,
                         'inv_bool2'
                      || '  '
                      || inv_bool1
                      || '  '
                      || ''
                     );
                     
                     fnd_file.put_line
                     (fnd_file.LOG,
                         'inv_bool3'
                      || '  '
                      || inv_bool3
                      || '  '
                      || ''
                     );
            -- Begin processing when the invoice number does not match
            IF (inv_bool1 = 'TRUE' OR inv_bool2 = 'TRUE' OR inv_bool3 = 'TRUE'
               )
            THEN
               -- invoice number is not equal to 999999999999
               IF (   v_invoice_number1 <> '999999999999'
                   OR v_invoice_number2 <> '999999999999'
                   OR v_invoice_number3 <> '999999999999'
                  )
               THEN
                  DECLARE
                     CURSOR v_comparetrxnumber
                     IS
                        SELECT   trx_number
                            FROM apps.ar_payment_schedules_all aps
                           WHERE aps.customer_id = v_cust_account_id
                             AND cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
                        GROUP BY trx_number;
                  BEGIN
                     FOR p_comparetrxnumber IN v_comparetrxnumber
                     LOOP
                        FOR i IN 1 .. 12
                        LOOP
                           IF v_success1 = 'TRUE'
                           THEN
                              NULL;
                           ELSE
                              IF SUBSTR (p_comparetrxnumber.trx_number, i, 1) =
                                             SUBSTR (v_invoice_number1, i, 1)
                              THEN
                                 v_count1 := v_count1 + 1;

                                 IF v_count1 >= 6
                                 THEN
                                    v_success1 := 'TRUE';
                                    v_insert_trx_number1 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i - 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number1, i, 1)
                              THEN
                                 v_count1 := v_count1 + 1;

                                 IF v_count1 >= 6
                                 THEN
                                    v_success1 := 'TRUE';
                                    v_insert_trx_number1 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i + 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number1, i, 1)
                              THEN
                                 v_count1 := v_count1 + 1;

                                 IF v_count1 >= 6
                                 THEN
                                    v_success1 := 'TRUE';
                                    v_insert_trx_number1 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              END IF;
                           END IF;

                           IF v_success2 = 'TRUE'
                           THEN
                              NULL;
                           ELSE
                              IF SUBSTR (p_comparetrxnumber.trx_number, i, 1) =
                                             SUBSTR (v_invoice_number2, i, 1)
                              THEN
                                 v_count2 := v_count2 + 1;

                                 IF v_count2 >= 6
                                 THEN
                                    v_success2 := 'TRUE';
                                    v_insert_trx_number2 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i - 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number2, i, 1)
                              THEN
                                 v_count2 := v_count2 + 1;

                                 IF v_count2 >= 6
                                 THEN
                                    v_success2 := 'TRUE';
                                    v_insert_trx_number2 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i + 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number2, i, 1)
                              THEN
                                 v_count2 := v_count2 + 1;

                                 IF v_count2 >= 6
                                 THEN
                                    v_success2 := 'TRUE';
                                    v_insert_trx_number2 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              END IF;
                           END IF;

                           IF v_success3 = 'TRUE'
                           THEN
                              NULL;
                           ELSE
                              IF SUBSTR (p_comparetrxnumber.trx_number, i, 1) =
                                             SUBSTR (v_invoice_number3, i, 1)
                              THEN
                                 v_count3 := v_count3 + 1;

                                 IF v_count3 >= 6
                                 THEN
                                    v_success3 := 'TRUE';
                                    v_insert_trx_number3 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i - 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number3, i, 1)
                              THEN
                                 v_count3 := v_count3 + 1;

                                 IF v_count3 >= 6
                                 THEN
                                    v_success3 := 'TRUE';
                                    v_insert_trx_number3 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              ELSIF SUBSTR (p_comparetrxnumber.trx_number,
                                            i + 1,
                                            1
                                           ) =
                                              SUBSTR (v_invoice_number3, i, 1)
                              THEN
                                 v_count3 := v_count3 + 1;

                                 IF v_count3 >= 6
                                 THEN
                                    v_success3 := 'TRUE';
                                    v_insert_trx_number3 :=
                                                p_comparetrxnumber.trx_number;
                                    v_attribute12 :=
                                       'Partial Invoice Number Match SUCCEEDED';
                                    EXIT;
                                 END IF;
                              END IF;
                           END IF;
                        END LOOP;

                        IF     v_success1 = 'TRUE'
                           AND v_success2 = 'TRUE'
                           AND v_success3 = 'TRUE'
                        THEN
                           EXIT;
                        END IF;
                     END LOOP;
                  END;
               ELSE
                  DECLARE
                     CURSOR v_compareamounts
                     IS
                        SELECT   trx_number,
                                 SUM (amount_due_original) gross_amount
                            FROM apps.ar_payment_schedules_all aps
                           WHERE aps.customer_id = v_cust_account_id
                             AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
                        GROUP BY trx_number;
                  BEGIN
                     FOR p_compareamounts IN v_compareamounts
                     LOOP
                        IF p_compareamounts.gross_amount = v_invoice_amount1
                        THEN
                           v_success1 := 'TRUE';
                           v_attribute12 := 'Amount Lookup Match SUCCEEDED';
                           v_insert_trx_number1 :=
                                                  p_compareamounts.trx_number;
                           EXIT;
                        ELSIF p_compareamounts.gross_amount =
                                                             v_invoice_amount2
                        THEN
                           v_success2 := 'TRUE';
                           v_attribute12 := 'Amount Lookup Match SUCCEEDED';
                           v_insert_trx_number2 :=
                                                  p_compareamounts.trx_number;
                           EXIT;
                        ELSIF p_compareamounts.gross_amount =
                                                             v_invoice_amount3
                        THEN
                           v_success3 := 'TRUE';
                           v_attribute12 := 'Amount Lookup Match SUCCEEDED';
                           v_insert_trx_number3 :=
                                                  p_compareamounts.trx_number;
                           EXIT;
                        ELSE
                           v_success1 := 'FALSE';
                           v_success2 := 'FALSE';
                           v_success3 := 'FALSE';
                        END IF;
                     END LOOP;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_success1 := 'FALSE';
                        v_success2 := 'FALSE';
                        v_success3 := 'FALSE';
                  END;
               END IF;
            END IF;

            --Compare the receipt amount with any of the invoice amounts – - if the amount matches substitute the invoice --number in the table with that of the oracle.

            -- Set the Boolean variable(v_success) to ‘TRUE’ . end if;
            --The below mentioned code is for applying custom autocash rules and -- is not --  specific to this document.Ithas --been included for the sake of giving
            --- complete picture of the functionality.
            -- AUTOCASH RULES
            IF (   v_success1 = 'FALSE'
                OR v_success2 = 'FALSE'
                OR v_success3 = 'FALSE'
               )
            THEN
               -- To get the earliest date till which there is an open transaction .
               BEGIN
                  SELECT MIN (due_date)
                    INTO v_min_date
                    FROM (SELECT   aps.due_date
                              FROM ar_payment_schedules_all aps
                             WHERE aps.customer_id = v_cust_account_id
                               AND aps.amount_due_original > 0
                               AND aps.amount_due_remaining > 0
                          GROUP BY aps.due_date
                          ORDER BY aps.due_date DESC);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
               END;

               --bring up transactions for all months in which there is at least one open invoice / debit memo for a customer;
               BEGIN
                  WHILE v_due_date > v_min_date
                  LOOP
                     v_due_date :=
                                  ROUND (TRUNC (v_due_date, 'mm'))
                                  - date_diff;
                     v_month := TO_CHAR (v_due_date, 'MM');
                     v_year := TO_CHAR (v_due_date, 'YYYY');
                     v_due_date1 :=
                          TO_DATE (v_month || '-01-' || v_year, 'MM-DD-YYYY');
                     v_last_day := LAST_DAY (v_due_date);

                     -- DATE RANGE AUTOCASH RULE I.
                     SELECT SUM (amount_due_original) amount_due_original
                       INTO v_amount_due_original
                       FROM apps.ar_payment_schedules_all aps
                      WHERE aps.customer_id = v_cust_account_id
                        AND aps.amount_due_original > 0
                        AND aps.amount_due_remaining > 0
                        AND TRUNC (aps.due_date) BETWEEN v_due_date1
                                                     AND v_due_date
                        AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

                     --group by aps.due_date;
                     IF v_success1 = 'FALSE'
                     THEN
                        IF v_amount_due_original = v_invoice_amount1
                        THEN
                           v_success1 := 'TRUE';
                           v_attribute12 :=
                                       'DATE RANGE AUTOCASH RULE I SUCCEEDED';

                           DECLARE
                              CURSOR c_select_trxnumbers
                              IS
                                 SELECT trx_number, amount_due_original
                                   FROM apps.ar_payment_schedules_all aps
                                  WHERE aps.customer_id = v_cust_account_id
                                    AND aps.amount_due_original > 0
                                    AND aps.amount_due_remaining > 0
                                    AND TRUNC (aps.due_date) BETWEEN v_due_date1
                                                                 AND v_due_date
                                    AND aps.cust_trx_type_id IN (
                                           SELECT r.cust_trx_type_id
                                             FROM ra_cust_trx_types_all r
                                            WHERE r.TYPE IN
                                                     ('INV', 'DM', 'CM', 'CB'));
                           BEGIN
                              FOR v_select_trxnumbers IN c_select_trxnumbers
                              LOOP
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence,
                                              invoice1,
                                              invoice2, invoice3,
                                              amount_applied1,
                                              amount_applied2,
                                              amount_applied3, attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence,
                                              v_select_trxnumbers.trx_number,
                                              NULL, NULL,
                                              v_select_trxnumbers.amount_due_original,
                                              NULL,
                                              NULL, v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        END IF;
                     END IF;

                     IF v_success2 = 'FALSE'
                     THEN
                        IF v_amount_due_original = v_invoice_amount2
                        THEN
                           v_success2 := 'TRUE';
                           v_attribute12 :=
                                       'DATE RANGE AUTOCASH RULE I SUCCEEDED';

                           DECLARE
                              CURSOR c_select_trxnumbers
                              IS
                                 SELECT trx_number, amount_due_original
                                   FROM apps.ar_payment_schedules_all aps
                                  WHERE aps.customer_id = v_cust_account_id
                                    AND aps.amount_due_original > 0
                                    AND aps.amount_due_remaining > 0
                                    AND TRUNC (aps.due_date) BETWEEN v_due_date1
                                                                 AND v_due_date
                                    AND aps.cust_trx_type_id IN (
                                           SELECT r.cust_trx_type_id
                                             FROM ra_cust_trx_types_all r
                                            WHERE r.TYPE IN
                                                     ('INV', 'DM', 'CM', 'CB'));
                           BEGIN
                              FOR v_select_trxnumbers IN c_select_trxnumbers
                              LOOP
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence, invoice1,
                                              invoice2,
                                              invoice3, amount_applied1,
                                              amount_applied2,
                                              amount_applied3, attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence, NULL,
                                              v_select_trxnumbers.trx_number,
                                              NULL, NULL,
                                              v_select_trxnumbers.amount_due_original,
                                              NULL, v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        END IF;
                     END IF;

                     IF v_success3 = 'FALSE'
                     THEN
                        IF v_amount_due_original = v_invoice_amount3
                        THEN
                           v_success3 := 'TRUE';
                           v_attribute12 :=
                                       'DATE RANGE AUTOCASH RULE I SUCCEEDED';

                           DECLARE
                              CURSOR c_select_trxnumbers
                              IS
                                 SELECT trx_number, amount_due_original
                                   FROM apps.ar_payment_schedules_all aps
                                  WHERE aps.customer_id = v_cust_account_id
                                    AND aps.amount_due_original > 0
                                    AND aps.amount_due_remaining > 0
                                    AND TRUNC (aps.due_date) BETWEEN v_due_date1
                                                                 AND v_due_date
                                    AND aps.cust_trx_type_id IN (
                                           SELECT r.cust_trx_type_id
                                             FROM ra_cust_trx_types_all r
                                            WHERE r.TYPE IN
                                                     ('INV', 'DM', 'CM', 'CB'));
                           BEGIN
                              FOR v_select_trxnumbers IN c_select_trxnumbers
                              LOOP
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence, invoice1,
                                              invoice2,
                                              invoice3,
                                              amount_applied1,
                                              amount_applied2,
                                              amount_applied3,
                                              attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence, NULL,
                                              NULL,
                                              v_select_trxnumbers.trx_number,
                                              NULL,
                                              NULL,
                                              v_select_trxnumbers.amount_due_original,
                                              v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        END IF;
                     END IF;

                     BEGIN
                        IF (   v_success1 = 'FALSE'
                            OR v_success2 = 'FALSE'
                            OR v_success3 = 'FALSE'
                           )
                        THEN
                           -- DATE RANGE AUTOCASH RULE II.
                           SELECT SUM (amount_due_original)
                                                          amount_due_original
                             INTO v_amount_due_original
                             FROM apps.ar_payment_schedules_all aps
                            WHERE aps.customer_id = v_cust_account_id
                              AND aps.amount_due_original > 0
                              AND aps.amount_due_remaining > 0
                              AND TRUNC (aps.due_date) BETWEEN v_due_date
                                                           AND v_last_day
                              AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r          --
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'));

                           IF v_amount_due_original = v_invoice_amount1
                           THEN
                              v_success1 := 'TRUE';
                              v_attribute12 :=
                                      'DATE RANGE AUTOCASH RULE II SUCCEEDED';

                              DECLARE
                                 CURSOR c_select_trxnumbers
                                 IS
                                    SELECT trx_number, amount_due_original
                                      FROM apps.ar_payment_schedules_all aps
                                     WHERE aps.customer_id =
                                                            v_cust_account_id
                                       AND aps.amount_due_original > 0
                                       AND aps.amount_due_remaining > 0
                                       AND TRUNC (aps.due_date)
                                              BETWEEN v_due_date
                                                  AND v_last_day
                                       AND aps.cust_trx_type_id IN (
                                              SELECT r.cust_trx_type_id
                                                FROM ra_cust_trx_types_all r
                                               WHERE r.TYPE IN
                                                        ('INV', 'DM', 'CM',
                                                         'CB'));
                              BEGIN
                                 FOR v_select_trxnumbers IN
                                    c_select_trxnumbers
                                 LOOP
                                    v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                    INSERT INTO xx_ar_paymentsinterface
                                                (record_type, creation_date,
                                                 batch_name,
                                                 item_number,
                                                 currency_code,
                                                 overflow_indicator,
                                                 overflow_sequence,
                                                 invoice1,
                                                 invoice2, invoice3,
                                                 amount_applied1,
                                                 amount_applied2,
                                                 amount_applied3, attribute12
                                                )
                                         VALUES (4, SYSDATE,
                                                 v_payment_interface.batch_name,
                                                 v_payment_interface.item_number,
                                                 v_payment_interface.currency_code,
                                                 v_payment_interface.overflow_indicator,
                                                 v_overflow_sequence,
                                                 v_select_trxnumbers.trx_number,
                                                 NULL, NULL,
                                                 v_select_trxnumbers.amount_due_original,
                                                 NULL,
                                                 NULL, v_attribute12
                                                );
                                 END LOOP;
                              END;

                              EXIT;
                           ELSIF v_amount_due_original = v_invoice_amount2
                           THEN
                              v_success2 := 'TRUE';
                              v_attribute12 :=
                                      'DATE RANGE AUTOCASH RULE II SUCCEEDED';

                              DECLARE
                                 CURSOR c_select_trxnumbers
                                 IS
                                    SELECT trx_number, amount_due_original
                                      FROM apps.ar_payment_schedules_all aps
                                     WHERE aps.customer_id =
                                                            v_cust_account_id
                                       AND aps.amount_due_original > 0
                                       AND aps.amount_due_remaining > 0
                                       AND TRUNC (aps.due_date)
                                              BETWEEN v_due_date
                                                  AND v_last_day
                                       AND aps.cust_trx_type_id IN (
                                              SELECT r.cust_trx_type_id
                                                FROM ra_cust_trx_types_all r
                                               WHERE r.TYPE IN
                                                        ('INV', 'DM', 'CM',
                                                         'CB'));
                              BEGIN
                                 FOR v_select_trxnumbers IN
                                    c_select_trxnumbers
                                 LOOP
                                    v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                    INSERT INTO xx_ar_paymentsinterface
                                                (record_type, creation_date,
                                                 batch_name,
                                                 item_number,
                                                 currency_code,
                                                 overflow_indicator,
                                                 overflow_sequence,
                                                 invoice1,
                                                 invoice2,
                                                 invoice3, amount_applied1,
                                                 amount_applied2,
                                                 amount_applied3, attribute12
                                                )
                                         VALUES (4, SYSDATE,
                                                 v_payment_interface.batch_name,
                                                 v_payment_interface.item_number,
                                                 v_payment_interface.currency_code,
                                                 v_payment_interface.overflow_indicator,
                                                 v_overflow_sequence,
                                                 NULL,
                                                 v_select_trxnumbers.trx_number,
                                                 NULL, NULL,
                                                 v_select_trxnumbers.amount_due_original,
                                                 NULL, v_attribute12
                                                );
                                 END LOOP;
                              END;

                              EXIT;
                           ELSIF v_amount_due_original = v_invoice_amount3
                           THEN
                              v_success3 := 'TRUE';
                              v_attribute12 :=
                                      'DATE RANGE AUTOCASH RULE II SUCCEEDED';

                              DECLARE
                                 CURSOR c_select_trxnumbers
                                 IS
                                    SELECT trx_number, amount_due_original
                                      FROM apps.ar_payment_schedules_all aps
                                     WHERE aps.customer_id =
                                                            v_cust_account_id
                                       AND aps.amount_due_original > 0
                                       AND aps.amount_due_remaining > 0
                                       AND TRUNC (aps.due_date)
                                              BETWEEN v_due_date
                                                  AND v_last_day
                                       AND aps.cust_trx_type_id IN (
                                              SELECT r.cust_trx_type_id
                                                FROM ra_cust_trx_types_all r
                                               WHERE r.TYPE IN
                                                        ('INV', 'DM', 'CM',
                                                         'CB'));
                              BEGIN
                                 FOR v_select_trxnumbers IN
                                    c_select_trxnumbers
                                 LOOP
                                    v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                    INSERT INTO xx_ar_paymentsinterface
                                                (record_type, creation_date,
                                                 batch_name,
                                                 item_number,
                                                 currency_code,
                                                 overflow_indicator,
                                                 overflow_sequence,
                                                 invoice1, invoice2,
                                                 invoice3,
                                                 amount_applied1,
                                                 amount_applied2,
                                                 amount_applied3,
                                                 attribute12
                                                )
                                         VALUES (4, SYSDATE,
                                                 v_payment_interface.batch_name,
                                                 v_payment_interface.item_number,
                                                 v_payment_interface.currency_code,
                                                 v_payment_interface.overflow_indicator,
                                                 v_overflow_sequence,
                                                 NULL, NULL,
                                                 v_select_trxnumbers.trx_number,
                                                 NULL,
                                                 NULL,
                                                 v_select_trxnumbers.amount_due_original,
                                                 v_attribute12
                                                );
                                 END LOOP;
                              END;

                              EXIT;
                           ELSE
                              -- DATE RANGE AUTOCASH RULE III.
                              BEGIN
                                 IF (   v_success1 = 'FALSE'
                                     OR v_success2 = 'FALSE'
                                     OR v_success3 = 'FALSE'
                                    )
                                 THEN
                                    SELECT SUM (amount_due_original)
                                                          amount_due_original
                                      INTO v_amount_due_original
                                      FROM apps.ar_payment_schedules_all aps
                                     WHERE aps.customer_id = v_cust_account_id
                                       AND aps.amount_due_original > 0
                                       AND aps.amount_due_remaining > 0
                                       AND TRUNC (aps.due_date)
                                              BETWEEN v_due_date1
                                                  AND v_last_day
                                       AND aps.cust_trx_type_id IN (
                                              SELECT r.cust_trx_type_id
                                                FROM ra_cust_trx_types_all r
                                               WHERE r.TYPE IN
                                                        ('INV', 'DM', 'CM',
                                                         'CB'));

                                    IF v_amount_due_original =
                                                             v_invoice_amount1
                                    THEN
                                       v_success1 := 'TRUE';
                                       v_attribute12 :=
                                          'DATE RANGE AUTOCASH RULE III SUCCEEDED';

                                       DECLARE
                                          CURSOR c_select_trxnumbers
                                          IS
                                             SELECT trx_number,
                                                    amount_due_original
                                               FROM apps.ar_payment_schedules_all aps
                                              WHERE aps.customer_id =
                                                             v_cust_account_id
                                                AND aps.amount_due_original >
                                                                             0
                                                AND aps.amount_due_remaining >
                                                                             0
                                                AND TRUNC (aps.due_date)
                                                       BETWEEN v_due_date1
                                                           AND v_last_day
                                                AND aps.cust_trx_type_id IN (
                                                       SELECT r.cust_trx_type_id
                                                         FROM ra_cust_trx_types_all r
                                                        WHERE r.TYPE IN
                                                                 ('INV', 'DM',
                                                                  'CM', 'CB'));
                                       BEGIN
                                          FOR v_select_trxnumbers IN
                                             c_select_trxnumbers
                                          LOOP
                                             v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                             INSERT INTO xx_ar_paymentsinterface
                                                         (record_type,
                                                          creation_date,
                                                          batch_name,
                                                          item_number,
                                                          currency_code,
                                                          overflow_indicator,
                                                          overflow_sequence,
                                                          invoice1,
                                                          invoice2,
                                                          invoice3,
                                                          amount_applied1,
                                                          amount_applied2,
                                                          amount_applied3,
                                                          attribute12
                                                         )
                                                  VALUES (4,
                                                          SYSDATE,
                                                          v_payment_interface.batch_name,
                                                          v_payment_interface.item_number,
                                                          v_payment_interface.currency_code,
                                                          v_payment_interface.overflow_indicator,
                                                          v_overflow_sequence,
                                                          v_select_trxnumbers.trx_number,
                                                          NULL,
                                                          NULL,
                                                          v_select_trxnumbers.amount_due_original,
                                                          NULL,
                                                          NULL,
                                                          v_attribute12
                                                         );
                                          END LOOP;
                                       END;

                                       EXIT;
                                    ELSIF v_amount_due_original =
                                                             v_invoice_amount2
                                    THEN
                                       v_success2 := 'TRUE';
                                       v_attribute12 :=
                                          'DATE RANGE AUTOCASH RULE III SUCCEEDED';

                                       DECLARE
                                          CURSOR c_select_trxnumbers
                                          IS
                                             SELECT trx_number,
                                                    amount_due_original
                                               FROM apps.ar_payment_schedules_all aps
                                              WHERE aps.customer_id =
                                                             v_cust_account_id
                                                AND aps.amount_due_original >
                                                                             0
                                                AND aps.amount_due_remaining >
                                                                             0
                                                AND TRUNC (aps.due_date)
                                                       BETWEEN v_due_date1
                                                           AND v_last_day
                                                AND aps.cust_trx_type_id IN (
                                                       SELECT r.cust_trx_type_id
                                                         FROM ra_cust_trx_types_all r
                                                        WHERE r.TYPE IN
                                                                 ('INV', 'DM',
                                                                  'CM', 'CB'));
                                       BEGIN
                                          FOR v_select_trxnumbers IN
                                             c_select_trxnumbers
                                          LOOP
                                             v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                             INSERT INTO xx_ar_paymentsinterface
                                                         (record_type,
                                                          creation_date,
                                                          batch_name,
                                                          item_number,
                                                          currency_code,
                                                          overflow_indicator,
                                                          overflow_sequence,
                                                          invoice1,
                                                          invoice2,
                                                          invoice3,
                                                          amount_applied1,
                                                          amount_applied2,
                                                          amount_applied3,
                                                          attribute12
                                                         )
                                                  VALUES (4,
                                                          SYSDATE,
                                                          v_payment_interface.batch_name,
                                                          v_payment_interface.item_number,
                                                          v_payment_interface.currency_code,
                                                          v_payment_interface.overflow_indicator,
                                                          v_overflow_sequence,
                                                          NULL,
                                                          v_select_trxnumbers.trx_number,
                                                          NULL,
                                                          NULL,
                                                          v_select_trxnumbers.amount_due_original,
                                                          NULL,
                                                          v_attribute12
                                                         );
                                          END LOOP;
                                       END;

                                       EXIT;
                                    ELSIF v_amount_due_original =
                                                             v_invoice_amount3
                                    THEN
                                       v_success3 := 'TRUE';
                                       v_attribute12 :=
                                          'DATE RANGE AUTOCASH RULE III SUCCEEDED';

                                       DECLARE
                                          CURSOR c_select_trxnumbers
                                          IS
                                             SELECT trx_number,
                                                    amount_due_original
                                               FROM apps.ar_payment_schedules_all aps
                                              WHERE aps.customer_id =
                                                             v_cust_account_id
                                                AND aps.amount_due_original >
                                                                             0
                                                AND aps.amount_due_remaining >
                                                                             0
                                                AND TRUNC (aps.due_date)
                                                       BETWEEN v_due_date1
                                                           AND v_last_day
                                                AND aps.cust_trx_type_id IN (
                                                       SELECT r.cust_trx_type_id
                                                         FROM ra_cust_trx_types_all r
                                                        WHERE r.TYPE IN
                                                                 ('INV', 'DM',
                                                                  'CM', 'CB'));
                                       BEGIN
                                          FOR v_select_trxnumbers IN
                                             c_select_trxnumbers
                                          LOOP
                                             v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                             INSERT INTO xx_ar_paymentsinterface
                                                         (record_type,
                                                          creation_date,
                                                          batch_name,
                                                          item_number,
                                                          currency_code,
                                                          overflow_indicator,
                                                          overflow_sequence,
                                                          invoice1,
                                                          invoice2,
                                                          invoice3,
                                                          amount_applied1,
                                                          amount_applied2,
                                                          amount_applied3,
                                                          attribute12
                                                         )
                                                  VALUES (4,
                                                          SYSDATE,
                                                          v_payment_interface.batch_name,
                                                          v_payment_interface.item_number,
                                                          v_payment_interface.currency_code,
                                                          v_payment_interface.overflow_indicator,
                                                          v_overflow_sequence,
                                                          NULL,
                                                          NULL,
                                                          v_select_trxnumbers.trx_number,
                                                          NULL,
                                                          NULL,
                                                          v_select_trxnumbers.amount_due_original,
                                                          v_attribute12
                                                         );
                                          END LOOP;
                                       END;

                                       EXIT;
                                    ELSE
                                       v_success1 := 'FALSE';
                                       v_success2 := 'FALSE';
                                       v_success3 := 'FALSE';
                                    END IF;
                                 END IF;
                              EXCEPTION
                                 WHEN NO_DATA_FOUND
                                 THEN
                                    v_success1 := 'FALSE';
                                    v_success2 := 'FALSE';
                                    v_success3 := 'FALSE';
                              END;
                           END IF;
                        END IF;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_success1 := 'FALSE';
                           v_success2 := 'FALSE';
                           v_success3 := 'FALSE';
                     END;
                    --  END IF;
                  -- END IF;
                  END LOOP;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_success1 := 'FALSE';
                     v_success2 := 'FALSE';
                     v_success3 := 'FALSE';
               END;
            END IF;

            -- PULSE PAY AUTOCASH RULE – FOR UNIQUE DATES FROM LAST ONE MONTHS.
            IF (   v_success1 = 'FALSE'
                OR v_success2 = 'FALSE'
                OR v_success3 = 'FALSE'
               )
            THEN
               -- To get the earliest date till which there is an open transaction .
               BEGIN
                  SELECT COUNT (DISTINCT (aps.due_date))
                    INTO v_count_due_date
                    FROM ar_payment_schedules_all aps
                   WHERE aps.customer_id = v_cust_account_id
                     AND aps.amount_due_original > 0
                     AND aps.amount_due_remaining > 0
                     AND TRUNC (aps.due_date) >= SYSDATE - 90;

                  IF v_count_due_date > 50
                  THEN
                     SELECT MIN (due_date)
                       INTO v_min_date
                       FROM (SELECT   aps.due_date
                                 FROM ar_payment_schedules_all aps
                                WHERE aps.customer_id = v_cust_account_id
                                  AND aps.amount_due_original > 0
                                  AND aps.amount_due_remaining > 0
                                  AND TRUNC (aps.due_date) >= SYSDATE - 90
                             GROUP BY aps.due_date);
                  ELSE
                     SELECT MIN (due_date)
                       INTO v_min_date
                       FROM (SELECT   aps.due_date
                                 FROM ar_payment_schedules_all aps
                                WHERE aps.customer_id = v_cust_account_id
                                  AND aps.amount_due_original > 0
                                  AND aps.amount_due_remaining > 0
                                  AND ROWNUM <= 50
                             GROUP BY aps.due_date);
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
               END;

               v_due_date := TRUNC (SYSDATE, 'MM');

               WHILE v_due_date > v_min_date
               LOOP
                  v_last_day := LAST_DAY (v_due_date);

                  DECLARE
                     CURSOR c_pulsepay
                     IS
                        SELECT   trx_number,
                                 SUM (amount_due_original)
                                                         amount_due_original
                            FROM apps.ar_payment_schedules_all aps
                           WHERE aps.customer_id = v_cust_account_id
                             AND aps.amount_due_original > 0
                             AND aps.amount_due_remaining > 0
                             AND TRUNC (aps.due_date) BETWEEN v_due_date
                                                          AND v_last_day
                             AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
                        GROUP BY due_date, trx_number;
                  BEGIN
                     FOR v_pulsepay IN c_pulsepay
                     LOOP
                        v_amount_due_original :=
                                               v_pulsepay.amount_due_original;

                        IF v_amount_due_original = v_invoice_amount1
                        THEN
                           v_success1 := 'TRUE';
                           v_attribute12 :=
                                         'PULSE PAY AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           INSERT INTO xx_ar_paymentsinterface
                                       (record_type, creation_date,
                                        batch_name,
                                        item_number,
                                        currency_code,
                                        overflow_indicator,
                                        overflow_sequence,
                                        invoice1, invoice2, invoice3,
                                        amount_applied1, amount_applied2,
                                        amount_applied3, attribute12
                                       )
                                VALUES (4, SYSDATE,
                                        v_payment_interface.batch_name,
                                        v_payment_interface.item_number,
                                        v_payment_interface.currency_code,
                                        v_payment_interface.overflow_indicator,
                                        v_overflow_sequence,
                                        v_pulsepay.trx_number, NULL, NULL,
                                        v_amount_due_original, NULL,
                                        NULL, v_attribute12
                                       );

                           EXIT;
                        ELSIF v_amount_due_original = v_invoice_amount2
                        THEN
                           v_success2 := 'TRUE';
                           v_attribute12 :=
                                         'PULSE PAY AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           INSERT INTO xx_ar_paymentsinterface
                                       (record_type, creation_date,
                                        batch_name,
                                        item_number,
                                        currency_code,
                                        overflow_indicator,
                                        overflow_sequence, invoice1,
                                        invoice2, invoice3, amount_applied1,
                                        amount_applied2, amount_applied3,
                                        attribute12
                                       )
                                VALUES (4, SYSDATE,
                                        v_payment_interface.batch_name,
                                        v_payment_interface.item_number,
                                        v_payment_interface.currency_code,
                                        v_payment_interface.overflow_indicator,
                                        v_overflow_sequence, NULL,
                                        v_pulsepay.trx_number, NULL, NULL,
                                        v_amount_due_original, NULL,
                                        v_attribute12
                                       );

                           EXIT;
                        ELSIF v_amount_due_original = v_invoice_amount3
                        THEN
                           v_success3 := 'TRUE';
                           v_attribute12 :=
                                         'PULSE PAY AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           INSERT INTO xx_ar_paymentsinterface
                                       (record_type, creation_date,
                                        batch_name,
                                        item_number,
                                        currency_code,
                                        overflow_indicator,
                                        overflow_sequence, invoice1,
                                        invoice2, invoice3, amount_applied1,
                                        amount_applied2, amount_applied3,
                                        attribute12
                                       )
                                VALUES (4, SYSDATE,
                                        v_payment_interface.batch_name,
                                        v_payment_interface.item_number,
                                        v_payment_interface.currency_code,
                                        v_payment_interface.overflow_indicator,
                                        v_overflow_sequence, NULL,
                                        NULL, v_pulsepay.trx_number, NULL,
                                        NULL, v_amount_due_original,
                                        v_attribute12
                                       );

                           EXIT;
                        ELSE
                           v_success1 := 'FALSE';
                           v_success2 := 'FALSE';
                           v_success3 := 'FALSE';
                        END IF;
                     END LOOP;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_success1 := 'FALSE';
                        v_success2 := 'FALSE';
                        v_success3 := 'FALSE';
                  END;

                  v_due_date := ADD_MONTHS (TRUNC (v_due_date, 'MONTH'), -1);
               END LOOP;
            END IF;

            IF (   v_success1 = 'FALSE'
                OR v_success2 = 'FALSE'
                OR v_success3 = 'FALSE'
               )
            THEN
               --• Any Combination Rule
               v_due_date := TRUNC (SYSDATE, 'MM');

               WHILE v_due_date > v_min_date
               LOOP
                  v_last_day := LAST_DAY (v_due_date);

                  DECLARE
                     CURSOR c_any_combination
                     IS
                        SELECT   trx_number
                            FROM apps.ar_payment_schedules_all aps
                           WHERE aps.customer_id = v_cust_account_id
                             AND aps.amount_due_original > 0
                             AND aps.amount_due_remaining > 0
                             AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
                             AND TRUNC (aps.due_date) BETWEEN v_due_date
                                                          AND v_last_day
                        GROUP BY trx_number, due_date
                        ORDER BY trx_number;
                  BEGIN
                     FOR v_any_combination IN c_any_combination
                     LOOP
                        p_num := p_num + 1;
                        v_trx_number4 := v_any_combination.trx_number;
                        v_number (p_num) := v_trx_number4;
                     END LOOP;

                     SELECT COUNT (trx_number)
                       INTO v_trx
                       FROM apps.ar_payment_schedules_all aps
                      WHERE aps.customer_id = v_cust_account_id
                        AND aps.amount_due_original > 0
                        AND aps.amount_due_remaining > 0
                        AND aps.cust_trx_type_id IN (
                                     SELECT r.cust_trx_type_id
                                       FROM ra_cust_trx_types_all r
                                      WHERE r.TYPE IN
                                                    ('INV', 'DM', 'CM', 'CB'))
                        AND TRUNC (aps.due_date) BETWEEN v_due_date AND v_last_day;

                     FOR i IN 1 .. v_trx
                     LOOP
                        -- DBMS_OUTPUT.put_line ('The Trx Number is :'||'  '||v_number(i));
                        -- DBMS_OUTPUT.put_line ('The Trx Count is :'||'  '||v_trx);
                        SELECT   aps.trx_number,
                                 SUM (aps.amount_due_original)
                            INTO v_trx_number5,
                                 v_amount_due_original1
                            FROM apps.ar_payment_schedules_all aps
                           WHERE trx_number = v_number (i)
                        GROUP BY aps.trx_number;

                        -- trx number added to the original design
                        sql_stmt :=
                           'insert into    xx_ar_autocash_glb_tmp(trx_number,amount_due_original)
                                         values(v_trx_number5,v_amount_due_original1)';

                        EXECUTE IMMEDIATE sql_stmt;

                        -- DBMS_OUTPUT.put_line ('The Trx Number is :'||'  '||v_number(k));
                        v_amount_due_original2 :=
                               v_amount_due_original2 + v_amount_due_original1;

                        IF v_amount_due_original2 = v_invoice_amount1
                        THEN
                           v_success1 := 'TRUE';
                           v_attribute12 :=
                                   'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           DECLARE
                              CURSOR c_insert_interface
                              IS
                                 SELECT trx_number, amount_due_original
                                   INTO v_trx_number5, v_amount_due_original5
                                   FROM xx_ar_autocash_glb_tmp;
                           BEGIN
                              FOR v_insert_interface IN c_insert_interface
                              LOOP
                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence,
                                              invoice1,
                                              invoice2, invoice3,
                                              amount_applied1,
                                              amount_applied2,
                                              amount_applied3, attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence,
                                              v_insert_interface.trx_number,
                                              NULL, NULL,
                                              v_insert_interface.amount_due_original,
                                              NULL,
                                              NULL, v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        ELSIF v_amount_due_original2 = v_invoice_amount2
                        THEN
                           v_success2 := 'TRUE';
                           v_attribute12 :=
                                   'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           DECLARE
                              CURSOR c_insert_interface
                              IS
                                 SELECT trx_number, amount_due_original
                                   INTO v_trx_number5, v_amount_due_original5
                                   FROM xx_ar_autocash_glb_tmp;
                           BEGIN
                              FOR v_insert_interface IN c_insert_interface
                              LOOP
                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence, invoice1,
                                              invoice2,
                                              invoice3, amount_applied1,
                                              amount_applied2,
                                              amount_applied3, attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence, NULL,
                                              v_insert_interface.trx_number,
                                              NULL, NULL,
                                              v_insert_interface.amount_due_original,
                                              NULL, v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        ELSIF v_amount_due_original2 = v_invoice_amount3
                        THEN
                           v_success3 := 'TRUE';
                           v_attribute12 :=
                                   'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                           v_overflow_sequence := v_overflow_sequence + 1;

                           DECLARE
                              CURSOR c_insert_interface
                              IS
                                 SELECT trx_number, amount_due_original
                                   INTO v_trx_number5, v_amount_due_original5
                                   FROM xx_ar_autocash_glb_tmp;
                           BEGIN
                              FOR v_insert_interface IN c_insert_interface
                              LOOP
                                 INSERT INTO xx_ar_paymentsinterface
                                             (record_type, creation_date,
                                              batch_name,
                                              item_number,
                                              currency_code,
                                              overflow_indicator,
                                              overflow_sequence, invoice1,
                                              invoice2,
                                              invoice3,
                                              amount_applied1,
                                              amount_applied2,
                                              amount_applied3,
                                              attribute12
                                             )
                                      VALUES (4, SYSDATE,
                                              v_payment_interface.batch_name,
                                              v_payment_interface.item_number,
                                              v_payment_interface.currency_code,
                                              v_payment_interface.overflow_indicator,
                                              v_overflow_sequence, NULL,
                                              NULL,
                                              v_insert_interface.trx_number,
                                              NULL,
                                              NULL,
                                              v_insert_interface.amount_due_original,
                                              v_attribute12
                                             );
                              END LOOP;
                           END;

                           EXIT;
                        ELSE
                           v_success1 := 'FALSE';
                           v_success2 := 'FALSE';
                           v_success3 := 'FALSE';
                        END IF;

                        FOR j IN i + 1 .. v_trx
                        LOOP
                           EXIT WHEN i + 1 = v_trx;
                           p := j;

                           IF p > 1
                           THEN
                              SELECT   trx_number, SUM (amount_due_original)
                                  INTO v_trx_number5, v_amount_due_original3
                                  FROM apps.ar_payment_schedules_all aps
                                 WHERE trx_number = v_number (p)
                              GROUP BY trx_number;

                              sql_stmt :=
                                 'insert into    xx_ar_autocash2_glb_tmp(trx_number,amount_due_original)
                                         values(v_trx_number5,v_amount_due_original3)';

                              EXECUTE IMMEDIATE sql_stmt;

                              v_amount_due_original4 :=
                                   v_amount_due_original4
                                 + v_amount_due_original3;

                              IF v_amount_due_original4 = v_invoice_amount1
                              THEN
                                 v_success1 := 'TRUE';
                                 v_attribute12 :=
                                    'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 DECLARE
                                    CURSOR c_insert_interface
                                    IS
                                       SELECT trx_number,
                                              amount_due_original
                                         INTO v_trx_number5,
                                              v_amount_due_original5
                                         FROM xx_ar_autocash2_glb_tmp;
                                 BEGIN
                                    FOR v_insert_interface IN
                                       c_insert_interface
                                    LOOP
                                       INSERT INTO xx_ar_paymentsinterface
                                                   (record_type,
                                                    creation_date,
                                                    batch_name,
                                                    item_number,
                                                    currency_code,
                                                    overflow_indicator,
                                                    overflow_sequence,
                                                    invoice1,
                                                    invoice2, invoice3,
                                                    amount_applied1,
                                                    amount_applied2,
                                                    amount_applied3,
                                                    attribute12
                                                   )
                                            VALUES (4,
                                                    SYSDATE,
                                                    v_payment_interface.batch_name,
                                                    v_payment_interface.item_number,
                                                    v_payment_interface.currency_code,
                                                    v_payment_interface.overflow_indicator,
                                                    v_overflow_sequence,
                                                    v_insert_interface.trx_number,
                                                    NULL, NULL,
                                                    v_insert_interface.amount_due_original,
                                                    NULL,
                                                    NULL,
                                                    v_attribute12
                                                   );
                                    END LOOP;
                                 END;

                                 EXIT;
                              ELSIF v_amount_due_original4 = v_invoice_amount2
                              THEN
                                 v_success2 := 'TRUE';
                                 v_attribute12 :=
                                    'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 DECLARE
                                    CURSOR c_insert_interface
                                    IS
                                       SELECT trx_number,
                                              amount_due_original
                                         INTO v_trx_number5,
                                              v_amount_due_original5
                                         FROM xx_ar_autocash2_glb_tmp;
                                 BEGIN
                                    FOR v_insert_interface IN
                                       c_insert_interface
                                    LOOP
                                       INSERT INTO xx_ar_paymentsinterface
                                                   (record_type,
                                                    creation_date,
                                                    batch_name,
                                                    item_number,
                                                    currency_code,
                                                    overflow_indicator,
                                                    overflow_sequence,
                                                    invoice1,
                                                    invoice2,
                                                    invoice3,
                                                    amount_applied1,
                                                    amount_applied2,
                                                    amount_applied3,
                                                    attribute12
                                                   )
                                            VALUES (4,
                                                    SYSDATE,
                                                    v_payment_interface.batch_name,
                                                    v_payment_interface.item_number,
                                                    v_payment_interface.currency_code,
                                                    v_payment_interface.overflow_indicator,
                                                    v_overflow_sequence,
                                                    NULL,
                                                    v_insert_interface.trx_number,
                                                    NULL,
                                                    NULL,
                                                    v_insert_interface.amount_due_original,
                                                    NULL,
                                                    v_attribute12
                                                   );
                                    END LOOP;
                                 END;

                                 EXIT;
                              ELSIF v_amount_due_original4 = v_invoice_amount3
                              THEN
                                 v_success3 := 'TRUE';
                                 v_attribute12 :=
                                    'ANY COMBINATION AUTOCASH RULE  SUCCEEDED';
                                 v_overflow_sequence :=
                                                      v_overflow_sequence + 1;

                                 DECLARE
                                    CURSOR c_insert_interface
                                    IS
                                       SELECT trx_number,
                                              amount_due_original
                                         INTO v_trx_number5,
                                              v_amount_due_original5
                                         FROM xx_ar_autocash2_glb_tmp;
                                 BEGIN
                                    FOR v_insert_interface IN
                                       c_insert_interface
                                    LOOP
                                       INSERT INTO xx_ar_paymentsinterface
                                                   (record_type,
                                                    creation_date,
                                                    batch_name,
                                                    item_number,
                                                    currency_code,
                                                    overflow_indicator,
                                                    overflow_sequence,
                                                    invoice1, invoice2,
                                                    invoice3,
                                                    amount_applied1,
                                                    amount_applied2,
                                                    amount_applied3,
                                                    attribute12
                                                   )
                                            VALUES (4,
                                                    SYSDATE,
                                                    v_payment_interface.batch_name,
                                                    v_payment_interface.item_number,
                                                    v_payment_interface.currency_code,
                                                    v_payment_interface.overflow_indicator,
                                                    v_overflow_sequence,
                                                    NULL, NULL,
                                                    v_insert_interface.trx_number,
                                                    NULL,
                                                    NULL,
                                                    v_insert_interface.amount_due_original,
                                                    v_attribute12
                                                   );
                                    END LOOP;
                                 END;

                                 EXIT;
                              ELSE
                                 v_success1 := 'FALSE';
                                 v_success2 := 'FALSE';
                                 v_success3 := 'FALSE';
                              END IF;
                           END IF;
                        END LOOP;

                        v_amount_due_original4 := 0;
                        p := 0;
                     END LOOP;
                  END;

                  v_due_date := ADD_MONTHS (TRUNC (v_due_date, 'MONTH'), -1);
               END LOOP;
            END IF;
         --else
         --null;
         -- insert records from custom interface table into the standard interface table ;
         -- run the standard lockbox interface program .
         --end if;
         --end if;
         --end if;
         END;

         IF (v_success1 = 'TRUE' OR v_success2 = 'TRUE' OR v_success3 = 'TRUE'
            )
         THEN
            UPDATE xx_ar_paymentsinterface
               SET invoice1 = v_insert_trx_number1,
                   invoice2 = v_insert_trx_number2,
                   invoice3 = v_insert_trx_number3,
                   attribute12 = v_attribute12
             WHERE transmission_record_id = v_transmission_record_id;
         --substitute the invoice number in the interface table with the corresponding invoice number from oracle. end if;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         --NULL;
         fnd_file.put_line (fnd_file.LOG, 'No Invoices to Process');
   END;
END xx_lockbox_autocashrules_pkg;
/