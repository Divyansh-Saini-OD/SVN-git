CREATE OR REPLACE PACKAGE BODY xx_split_lockbox_pkg
IS
-- +===================================================================================+
-- +===================================================================================+
-- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
-- | Description : This Package is used to get split long running lockbox files.       |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
-- |  2.0     11-NOV-2015  Vasu Raparla            Removed Schema References for R12.2 |
-- +===================================================================================+
   PROCEDURE deletestdiface (x_retcode OUT VARCHAR2, p_file_name VARCHAR2)
   IS
    Ar_Payments number(10);
   Ar_Transmissions number(10);
   BEGIN
      DELETE FROM ar_payments_interface_all
            WHERE transmission_request_id =
                     (SELECT transmission_request_id
                        FROM ar_transmissions_all
                       WHERE transmission_name = SUBSTR (p_file_name, 1, 30));
             Ar_Payments := SQL%ROWCOUNT;
      DBMS_OUTPUT.PUT_LINE('Rows deleted from Ar_Payments_Intrace_All'||Ar_Payments);

      DELETE FROM ar_transmissions_all
            WHERE transmission_name = SUBSTR (p_file_name, 1, 30);
            Ar_Transmissions := SQL%ROWCOUNT;
      DBMS_OUTPUT.PUT_LINE('Rows deleted from Ar_Transmissions_All'||Ar_Transmissions);
    

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error Clearing the Standard Table');
         x_retcode := 2;
   END;

-- +===================================================================================+
-- +===================================================================================+
-- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
-- | Description : This Main Procedure used to  split long running lockbox files.      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
-- +===================================================================================+
   PROCEDURE main (
      x_errbuf            OUT   VARCHAR2,
      x_retcode           OUT   VARCHAR2,
      p_file_name               VARCHAR2,
      p_sub_validate            VARCHAR2,
      p_sub_quick_cash          VARCHAR2,
      p_group_threshold         NUMBER DEFAULT 500
   )
   IS
      ln_transmission_request_id   NUMBER;
      l_check_valid_file           NUMBER    := 0;
      l_check_insert               NUMBER    := 0;
      l_gl_date                    VARCHAR2 (30) ;
      l_gl_date1                   VARCHAR2 (30) ;

      CURSOR c_check_valid_file (p_file_name VARCHAR2)
      IS
         SELECT 1
           FROM xx_ar_payments_interface xapi
          WHERE file_name = p_file_name
            AND EXISTS (
                   SELECT 1
                     FROM fnd_concurrent_programs_vl fcp,
                          fnd_concurrent_requests fcr
                    WHERE fcp.user_concurrent_program_name IN
                             ('Process Lockboxes',
                              'OD: Validate Process Lockboxes',
                              'Custom Process Lockboxes'
                             )
                      AND fcp.concurrent_program_id = fcr.concurrent_program_id
                      AND fcr.argument4 = SUBSTR (xapi.file_name, 1, 30)
                      AND argument15 = 'N'           --check for only validate
                      AND fcr.status_code IN ('D', 'X'))
            AND NOT EXISTS (
                   SELECT 1
                     FROM fnd_concurrent_programs_vl fcp,
                          fnd_concurrent_requests fcr
                    WHERE fcp.user_concurrent_program_name IN
                             ('Process Lockboxes',
                              'OD: Validate Process Lockboxes',
                              'Custom Process Lockboxes'
                             )
                      AND fcp.concurrent_program_id = fcr.concurrent_program_id
                      AND fcr.argument4 = xapi.file_name
                      AND fcr.phase_code <> 'C'
                      AND fcr.status_code NOT IN ('D', 'X'));

      CURSOR c_check_insert (p_file_name VARCHAR2)
      IS
         SELECT 1
           FROM xx_ar_payments_interface_split
          WHERE file_name = p_file_name AND ROWNUM = 1;
   BEGIN
      x_retcode := 0;

      SELECT gl_date
        INTO l_gl_date
        FROM xx_ar_lbx_wrapper_temp
       WHERE exact_file_name = p_file_name;

      IF l_gl_date IS NULL
      THEN
         SELECT gl_date
           INTO l_gl_date
           FROM xx_ar_lbx_wrapper_temp_history
          WHERE exact_file_name = p_file_name;
      END IF;

      OPEN c_check_valid_file (p_file_name);

      FETCH c_check_valid_file
       INTO l_check_valid_file;

      CLOSE c_check_valid_file;

      fnd_file.put_line (fnd_file.LOG, 'l_check_valid_file ::' || l_check_valid_file );
      fnd_file.put_line (fnd_file.LOG, 'p_group_threshold ::' || p_group_threshold );
      fnd_file.put_line (fnd_file.LOG, 'l_gl_date ::' || l_gl_date);
      fnd_file.put_line (fnd_file.LOG, 'p_sub_validate ::' || p_sub_validate);
      fnd_file.put_line (fnd_file.LOG, 'p_sub_quick_cash ::' || p_sub_quick_cash );

      IF l_check_valid_file = 1
      THEN
         IF p_group_threshold IS NOT NULL
         THEN
            g_group_threshold := p_group_threshold;
         END IF;

         OPEN c_check_insert (p_file_name);

         FETCH c_check_insert
          INTO l_check_insert;

         CLOSE c_check_insert;

         IF l_check_insert <> 1
         THEN
            SELECT xx_ar_transmissions_s.NEXTVAL,
                   TO_CHAR (TO_DATE (l_gl_date, 'DD-MON-YY'), 'DD-Mon-RRRR')
              INTO ln_transmission_request_id,
                   l_gl_date1
              FROM DUAL;

            fnd_file.put_line (fnd_file.LOG, 'ln_transmission_request_id ::' || ln_transmission_request_id );
            
            insertdata (p_file_name                    => p_file_name,
                        p_transmission_request_id      => ln_transmission_request_id
                       );
         ELSE
            fnd_file.put_line
               (fnd_file.LOG, ' File Already Split, Proceeding with Launching the concurrent program for any residual batch' );
         END IF;

         IF p_sub_validate = 'Y'
         THEN
            fnd_file.put_line (fnd_file.LOG, 'LaunchValidate ');
            fnd_file.put_line (fnd_file.LOG, 'p_lockbox_file_name ::' || p_file_name);
            fnd_file.put_line (fnd_file.LOG, 'p_gl_date1 ::' || TO_CHAR (TO_DATE(l_gl_date, 'DD-MON-YY'), 'YYYY/MM/DD HH24:MI:SS'));
            fnd_file.put_line (fnd_file.LOG, 'p_gl_date2 ::' || l_gl_date1);
            fnd_file.put_line (fnd_file.LOG, 'p_transmission_req_id ::' || ln_transmission_request_id );
            launchvalidate
                         (p_lockbox_file_name        => p_file_name,
                          p_gl_date1                 => TO_CHAR (TO_DATE(l_gl_date, 'DD-MON-YY'), 'YYYY/MM/DD HH24:MI:SS'),
                          p_gl_date2                 => l_gl_date1,
                          p_transmission_req_id      => ln_transmission_request_id
                         );
         END IF;

         IF p_sub_quick_cash = 'Y'
         THEN
            fnd_file.put_line (fnd_file.LOG, 'processLB ');
            processlb (p_file_name => p_file_name);
         END IF;
      ELSE
         x_retcode := 1;
         fnd_file.put_line (fnd_file.LOG,
                               'File ::'
                            || p_file_name
                            || ' is not elligible for Splitting'
                           );
      --fnd_file.put_line(fnd_file.out,'File ::'||P_file_name||' is not elligible for Splitting');
      END IF;

      deletestdiface (x_retcode => x_retcode, p_file_name => p_file_name);
   END;

-- +===================================================================================+
-- +===================================================================================+
-- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
-- | Description : This insertdata Procedure used to inserta data into the table       |  
-- |               xx_ar_payments_interface_split from xx_ar_payments_interface        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
-- +===================================================================================+


   PROCEDURE insertdata (p_file_name VARCHAR2, p_transmission_request_id NUMBER)
   IS
   BEGIN
      INSERT INTO xx_ar_payments_interface_split
                  (status, record_type, destination_account, origination,
                   lockbox_number, deposit_date, deposit_time, batch_name,
                   item_number, remittance_amount, transit_routing_number,
                   ACCOUNT, check_number, customer_number, overflow_sequence,
                   overflow_indicator, invoice1, invoice2, invoice3,
                   amount_applied1, amount_applied2, amount_applied3,
                   batch_record_count, batch_amount, lockbox_record_count,
                   lockbox_amount, transmission_record_count,
                   transmission_amount, attribute1, attribute2, attribute3,
                   attribute4, attribute5, record_status, process_num,
                   file_name, error_mesg, inv_match_status, process_date,
                   error_flag, creation_date, created_by, last_update_date,
                   last_updated_by, auto_cash_status, auto_cash_request,
                   customer_id, trx_date, invoice1_status, invoice2_status,
                   invoice3_status, sending_company_id,
                   transmission_request_id, transmission_id, gl_date,
                   attribute_category, pickup_status, split_file_name)
         SELECT status, record_type, destination_account, origination,
                lockbox_number, deposit_date, deposit_time, batch_name,
                item_number, remittance_amount, transit_routing_number,
                ACCOUNT, check_number, customer_number, overflow_sequence,
                overflow_indicator, invoice1, invoice2, invoice3,
                amount_applied1, amount_applied2, amount_applied3,
                batch_record_count, batch_amount, lockbox_record_count,
                lockbox_amount, transmission_record_count,
                transmission_amount, attribute1, attribute2, attribute3,
                attribute4, attribute5, record_status, process_num,
                file_name, error_mesg, inv_match_status, process_date,
                error_flag, creation_date, created_by, last_update_date,
                last_updated_by, auto_cash_status, auto_cash_request,
                customer_id, trx_date, invoice1_status, invoice2_status,
                invoice3_status, sending_company_id,
                p_transmission_request_id transmission_request_id,
                NULL transmission_id, NULL gl_date, NULL attribute_category,
                NULL pickup_status, NULL split_file_name
           FROM xx_ar_payments_interface
          WHERE file_name = p_file_name;
   END insertdata;


-- +===================================================================================+
-- +===================================================================================+
-- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
-- | Description : This launchvalidate Procedure launches the  concurrent program      |
-- |                   'OD: Validate Process Lockboxes' for the split files .          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
-- +===================================================================================+


   PROCEDURE launchvalidate (
      p_lockbox_file_name     VARCHAR2,
      p_gl_date1              VARCHAR2,
      p_gl_date2              VARCHAR2,
      p_transmission_req_id   NUMBER
   )
   IS
      ln_lck_req_id                  NUMBER;
      l_record_count                 NUMBER         := 0;
      l_remittance_amount            NUMBER         := 0;
      l_lockbox_count                NUMBER         := 0;
      l_transmission_count           NUMBER         := 0;
      ln_transmission_id             NUMBER         := 0;
      ln_tran_req_id                 NUMBER         := 0;
      l_exit                         NUMBER         := 1;
      l_lockbox_file_name            VARCHAR2 (100)
                                       := SUBSTR (p_lockbox_file_name, 1, 20);
      n_lockbox_file_name            VARCHAR2 (100);
      l_counter                      NUMBER         := 1;
      l_user_id                      NUMBER         := 0;
      l_resp_id                      NUMBER         := 0;
      l_resp_appl_id                 NUMBER         := 0;
      l_inserted_4_record            NUMBER         := 0;
      lc_gl_date1                    VARCHAR2 (30)  := p_gl_date1;
      lc_gl_date2                    VARCHAR2 (30)  := p_gl_date2;
      ln_transmission_req_id         NUMBER         := p_transmission_req_id;

      CURSOR c_residual_batch (p_lockbox_file_name VARCHAR2)
      IS
         SELECT DISTINCT batch_name
                    FROM xx_ar_payments_interface_split
                   WHERE transmission_request_id = ln_transmission_req_id
                     AND file_name = p_lockbox_file_name
                     AND pickup_status IS NULL
                     AND record_type IN (4, 5, 6, 7)
                GROUP BY batch_name;

      group_threshold                NUMBER         := g_group_threshold;
      l_lock_submissions_threshold   NUMBER;
      l_lock_counter                 NUMBER         := 0;
   BEGIN
      SELECT fug.user_id, fug.responsibility_id,
             fug.responsibility_application_id
        INTO l_user_id, l_resp_id,
             l_resp_appl_id
        FROM fnd_user_resp_groups fug,
             fnd_responsibility_tl fut,
             fnd_user fu
       WHERE 1 = 1
         AND fu.user_id = fnd_profile.VALUE ('USER_ID')
         AND fut.responsibility_name = 'OD (US) AR Batch Jobs'
         AND fut.LANGUAGE = 'US'
         AND fu.user_id = fug.user_id
         AND fug.responsibility_id = fut.responsibility_id;

      LOOP
         l_exit := 1;

         FOR d_residual_batch IN c_residual_batch (p_lockbox_file_name)
         LOOP
            INSERT INTO ar_payments_interface_all
                        (transmission_record_id, status, record_type,
                         destination_account, origination, lockbox_number,
                         deposit_date, deposit_time, batch_name, item_number,
                         remittance_amount, transit_routing_number, ACCOUNT,
                         check_number, customer_number, overflow_sequence,
                         overflow_indicator, invoice1, invoice2, invoice3,
                         amount_applied1, amount_applied2, amount_applied3,
                         batch_record_count, batch_amount,
                         lockbox_record_count, lockbox_amount,
                         transmission_record_count, transmission_amount,
                         attribute1, attribute2, attribute3, attribute4,
                         attribute5, creation_date, created_by,
                         last_update_date, last_updated_by, customer_id,
                         invoice1_status, invoice2_status, invoice3_status,
                         transmission_request_id, transmission_id, gl_date,
                         attribute_category)
               (SELECT ar_payments_interface_s.NEXTVAL, status, record_type,
                       destination_account, origination, lockbox_number,
                       deposit_date, deposit_time, batch_name, item_number,
                       remittance_amount, transit_routing_number, ACCOUNT,
                       check_number, customer_number, overflow_sequence,
                       overflow_indicator, invoice1, invoice2, invoice3,
                       amount_applied1, amount_applied2, amount_applied3,
                       batch_record_count, batch_amount,
                       lockbox_record_count, lockbox_amount,
                       transmission_record_count, transmission_amount,
                       attribute1, attribute2, attribute3, attribute4,
                       attribute5, creation_date, created_by,
                       last_update_date, last_updated_by, customer_id,
                       invoice1_status, invoice2_status, invoice3_status,
                       transmission_request_id, transmission_id, gl_date,
                       attribute_category
                  FROM xx_ar_payments_interface_split
                 WHERE batch_name = d_residual_batch.batch_name
                   AND file_name = p_lockbox_file_name
                   AND transmission_request_id = ln_transmission_req_id
                   AND pickup_status IS NULL
                   AND record_type IN (4, 5, 6, 7));

            SELECT COUNT (*)
              INTO l_record_count
              FROM ar_payments_interface_all
             WHERE record_type IN (4, 5, 6, 7)
               AND transmission_request_id = ln_transmission_req_id;

            UPDATE xx_ar_payments_interface_split
               SET pickup_status = 'Picked'
             WHERE batch_name = d_residual_batch.batch_name
               AND transmission_request_id = ln_transmission_req_id
               AND file_name = p_lockbox_file_name
               AND pickup_status IS NULL
               AND record_type IN (4, 5, 6, 7);

            INSERT INTO xx_lock_trans_split_history
                        (batch_name, status,
                         transmission_request_id, old_file_name
                        )
                 VALUES (d_residual_batch.batch_name, 'Picked',
                         ln_transmission_req_id, p_lockbox_file_name
                        );

            l_inserted_4_record := 1;
            EXIT WHEN (l_record_count > group_threshold);
         END LOOP;

         IF (l_inserted_4_record = 1)
         THEN
            fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);

            INSERT INTO ar_payments_interface_all
                        (transmission_record_id, status, record_type,
                         destination_account, origination, lockbox_number,
                         deposit_date, deposit_time, batch_name, item_number,
                         remittance_amount, transit_routing_number, ACCOUNT,
                         check_number, customer_number, overflow_sequence,
                         overflow_indicator, invoice1, invoice2, invoice3,
                         amount_applied1, amount_applied2, amount_applied3,
                         batch_record_count, batch_amount,
                         lockbox_record_count, lockbox_amount,
                         transmission_record_count, transmission_amount,
                         attribute1, attribute2, attribute3, attribute4,
                         attribute5, creation_date, created_by,
                         last_update_date, last_updated_by, customer_id,
                         invoice1_status, invoice2_status, invoice3_status,
                         transmission_request_id, transmission_id, gl_date,
                         attribute_category)
               (SELECT ar_payments_interface_s.NEXTVAL, status, record_type,
                       destination_account, origination, lockbox_number,
                       deposit_date, deposit_time, batch_name, item_number,
                       remittance_amount, transit_routing_number, ACCOUNT,
                       check_number, customer_number, overflow_sequence,
                       overflow_indicator, invoice1, invoice2, invoice3,
                       amount_applied1, amount_applied2, amount_applied3,
                       batch_record_count, batch_amount,
                       lockbox_record_count, lockbox_amount,
                       transmission_record_count, transmission_amount,
                       attribute1, attribute2, attribute3, attribute4,
                       attribute5, creation_date, created_by,
                       last_update_date, last_updated_by, customer_id,
                       invoice1_status, invoice2_status, invoice3_status,
                       transmission_request_id, transmission_id, gl_date,
                       attribute_category
                  FROM xx_ar_payments_interface_split
                 WHERE transmission_request_id = ln_transmission_req_id
                   AND record_type IN (1, 8, 9, 2));

            SELECT SUM (remittance_amount)
              INTO l_remittance_amount
              FROM ar_payments_interface_all aa
             WHERE aa.transmission_request_id = ln_transmission_req_id
               AND aa.record_type NOT IN (1, 8, 9, 2);

            SELECT COUNT (DISTINCT batch_name)
              INTO l_lockbox_count
              FROM ar_payments_interface_all aa
             WHERE aa.transmission_request_id = ln_transmission_req_id
               AND aa.record_type NOT IN (1, 8, 9, 2);

            SELECT COUNT (*)
              INTO l_transmission_count
              FROM ar_payments_interface_all aa
             WHERE aa.transmission_request_id = ln_transmission_req_id;

            
            SELECT fnd_concurrent_requests_s.NEXTVAL,
                   ar_transmissions_s.NEXTVAL
              INTO ln_tran_req_id,
                   ln_transmission_id
              FROM DUAL;

            UPDATE ar_payments_interface_all
               SET transmission_record_count = l_transmission_count,
                   transmission_amount = l_remittance_amount,
                   transmission_request_id = ln_tran_req_id,
                   transmission_id = ln_transmission_id
             WHERE transmission_request_id = ln_transmission_req_id
               AND record_type = 9;

            UPDATE ar_payments_interface_all
               SET lockbox_record_count = l_lockbox_count,
                   lockbox_amount = l_remittance_amount,
                   transmission_request_id = ln_tran_req_id,
                   transmission_id = ln_transmission_id
             WHERE transmission_request_id = ln_transmission_req_id
               AND record_type = 8;

            UPDATE ar_payments_interface_all
               SET transmission_request_id = ln_tran_req_id,
                   transmission_id = ln_transmission_id
             WHERE transmission_request_id = ln_transmission_req_id
               AND record_type IN (1, 2, 4, 5, 6, 7);

            UPDATE xx_lock_trans_split_history
               SET new_transmission_request_id = ln_tran_req_id,
                   status = 'Processed'
             WHERE status = 'Picked';

            SELECT l_lockbox_file_name || ' - ' || ln_transmission_id
              INTO n_lockbox_file_name
              FROM DUAL;

            UPDATE xx_lock_trans_split_history
               SET new_transmission_request_id = ln_tran_req_id,
                   status = 'Processed',
                   new_file_name = n_lockbox_file_name
             WHERE status = 'Picked';

            INSERT INTO ar_transmissions_all
                        (transmission_request_id, created_by, creation_date,
                         last_updated_by, last_update_date, trans_date, TIME,
                         validated_count, validated_amount, COUNT, amount,
                         status, origin, destination, attribute1,
                         requested_lockbox_id, requested_trans_format_id,
                         requested_gl_date, transmission_name,
                         transmission_id, latest_request_id)
               SELECT ln_tran_req_id,                          -- :request_id,
                                     l_user_id,                   -- :user_id,
                                               SYSDATE, l_user_id,
                                                                  -- :user_id,
                                                                  SYSDATE,
                      TRUNC (SYSDATE), TO_CHAR (SYSDATE, 'HH24:MI'), 0, 0,
                      l_transmission_count, l_remittance_amount, 'NB',
                                                                      -- 'NB',
                                                                      '', '',
                      p_gl_date1, '',            -- :lockbox_id :i_lockbox_id,
                                     1000,                      -- :format_id,
                                          p_gl_date2,
                                                     -- :gl_date :i_gl_date,
                                                     n_lockbox_file_name,
                                                        -- :transmission_name,
                      ln_transmission_id, ''             -- :latest_request_id
                 FROM DUAL;

            ln_lck_req_id :=
               fnd_request.submit_request
                                      ('AR',
                                       'XX_ARLPLB',
                                       '',
                                       SYSDATE,
                                       FALSE,                          --Check
                                       'N',
                                       ln_transmission_id -- p_transmission_id
                                                         ,
                                       ln_tran_req_id    -- p_trans_request_id
                                                     ,
                                       n_lockbox_file_name    -- lc_trans_name
                                                          ,
                                       'N',
                                       NULL,
                                       NULL,
                                       1000               -- p_trans_format_id
                                           ,
                                       'Y',                --Submit Validation
                                       'N',
                                       NULL,
                                       lc_gl_date1
                                                  -- TO_CHAR(p_gl_date,'YYYY/MM/DD HH24:MI:SS')
               ,
                                       'R',
                                       'N',
                                       'N',           --Submit Post Quick Cash
                                       'N',
                                       'Y',
                                       NULL,
                                       404
                                      );
            
            COMMIT;

            IF (ln_lck_req_id <> 0)
            THEN
               UPDATE xx_lock_trans_split_history
                  SET lockbox_request_id = ln_lck_req_id,
                      status = 'Program Submitted'
                WHERE status = 'Processed'
                  AND transmission_request_id = ln_transmission_req_id;
            ELSE
               UPDATE xx_lock_trans_split_history
                  SET status = 'Program Submission Failure'
                WHERE status = 'Processed'
                  AND transmission_request_id = ln_transmission_req_id;
            END IF;

            l_lock_counter := l_lock_counter + 1;

            UPDATE fnd_concurrent_requests
               SET last_update_date = SYSDATE,
                   last_updated_by = l_user_id,
                   hold_flag = 'N',
                   phase_code = 'P',
                   status_code = 'Q',
                   completion_text = ''
             WHERE request_id = ln_lck_req_id;

            COMMIT;
            l_record_count := 0;
            l_remittance_amount := 0;
            l_lockbox_count := 0;
            l_transmission_count := 0;
            ln_transmission_id := 0;
            l_inserted_4_record := 0;
         END IF;

         SELECT COUNT (*)
           INTO l_exit
           FROM xx_ar_payments_interface_split
          WHERE pickup_status IS NULL
            AND record_type IN (4, 5, 6, 7)
            AND transmission_request_id = ln_transmission_req_id;

         IF (l_lock_counter >= NVL (l_lock_submissions_threshold, 1000))
         THEN
            l_exit := 0;
         END IF;

         EXIT WHEN (l_exit = 0);
      END LOOP;
   END;


-- +===================================================================================+
-- +===================================================================================+
-- | Name        : XX_SPLIT_LOCKBOX_PKG                                                |
-- | Description : This processlb Procedure launches the  concurrent program           |
-- |                   'Process Lockboxes' for the split files .                       |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |  1.0     15-NOV-2012  Rajeshkumar M R         Initial version                     |
-- +===================================================================================+


   PROCEDURE processlb (p_file_name VARCHAR2)
   IS
      l_user_id            NUMBER          := 0;
      l_resp_id            NUMBER          := 0;
      l_resp_appl_id       NUMBER          := 0;
      ln_lck_req_id        NUMBER;
      ln_validate_req_id   NUMBER          := 0;
      ln_req_status        VARCHAR2 (30);
      ln_req_phase         VARCHAR2 (30);
      ln_dev_status        VARCHAR2 (30);
      ln_dev_phase         VARCHAR2 (30);
      ln_message           VARCHAR2 (4000);
      ln_status            BOOLEAN;
      ln_pending_records   NUMBER          := 0;

      CURSOR c_submit_process_lock_box
      IS
         SELECT DISTINCT lockbox_request_id, fcr.argument1, fcr.argument2,
                         fcr.argument3, fcr.argument4, fcr.argument5,
                         fcr.argument6, fcr.argument7, fcr.argument8,
                         fcr.argument9, fcr.argument10, fcr.argument11,
                         fcr.argument12, fcr.argument13, fcr.argument14,
                         fcr.argument15, fcr.argument16, fcr.argument17,
                         fcr.argument18, fcr.argument19
                    FROM xx_lock_trans_split_history xlth,
                         fnd_concurrent_requests fcr
                   WHERE xlth.lockbox_request_id = fcr.request_id
                     AND post_quick_cash_req_id IS NULL
                     AND old_file_name = p_file_name;

      CURSOR c_pending_records
      IS
         SELECT 1
           FROM xx_lock_trans_split_history
          WHERE post_quick_cash_req_id IS NULL
            AND ROWNUM = 1
            AND old_file_name = p_file_name;
   BEGIN
      SELECT fug.user_id, fug.responsibility_id,
             fug.responsibility_application_id
        INTO l_user_id, l_resp_id,
             l_resp_appl_id
        FROM fnd_user_resp_groups fug,
             fnd_responsibility_tl fut,
             fnd_user fu
       WHERE 1 = 1        
         AND fu.user_id = fnd_profile.VALUE ('USER_ID')
         AND fut.responsibility_name = 'OD (US) AR Batch Jobs'
         AND fut.LANGUAGE = 'US'
         AND fu.user_id = fug.user_id
         AND fug.responsibility_id = fut.responsibility_id;

      fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);

      LOOP
         FOR r_submit_process_lock_box IN c_submit_process_lock_box
         LOOP
            ln_validate_req_id := 0;
            ln_req_status := NULL;
            ln_req_phase := NULL;
            ln_dev_status := NULL;
            ln_dev_phase := NULL;
            ln_message := NULL;
            ln_status := FALSE;
            ln_validate_req_id :=
                                 r_submit_process_lock_box.lockbox_request_id;
            ln_status :=
               fnd_concurrent.get_request_status
                                           (request_id      => ln_validate_req_id,
                                            phase           => ln_req_phase,
                                            status          => ln_req_status,
                                            dev_phase       => ln_dev_phase,
                                            dev_status      => ln_req_status,
                                            MESSAGE         => ln_message
                                           );

            IF ln_dev_phase = 'COMPLETE'
            THEN
               ln_lck_req_id :=
                  fnd_request.submit_request
                     ('AR',
                      'ARLPLB',
                      '',
                      SYSDATE,
                      FALSE,                                           --check
                      r_submit_process_lock_box.argument1,
                      r_submit_process_lock_box.argument2 -- p_transmission_id
                                                         ,
                      r_submit_process_lock_box.argument3
                                                         -- p_trans_request_id
                                                         ,
                      r_submit_process_lock_box.argument4     -- lc_trans_name
                                                         ,
                      r_submit_process_lock_box.argument5,
                      r_submit_process_lock_box.argument6,
                      r_submit_process_lock_box.argument7,
                      r_submit_process_lock_box.argument8 -- p_trans_format_id
                                                         ,
                      'N',
                      r_submit_process_lock_box.argument10,
                      r_submit_process_lock_box.argument11,
                      r_submit_process_lock_box.argument12
                                                          -- TO_CHAR(p_gl_date,'YYYY/MM/DD HH24:MI:SS')
                  ,
                      r_submit_process_lock_box.argument13,
                      r_submit_process_lock_box.argument14,
                      'Y',
                      r_submit_process_lock_box.argument16,
                      r_submit_process_lock_box.argument17,
                      r_submit_process_lock_box.argument18,
                      r_submit_process_lock_box.argument19
                     );

               
               UPDATE fnd_concurrent_requests
                  SET last_update_date = SYSDATE,
                      last_updated_by = l_user_id,
                      hold_flag = 'Y',
                      phase_code = 'P',
                      status_code = 'Q',
                      completion_text = ''
                WHERE request_id = ln_lck_req_id;

               UPDATE xx_lock_trans_split_history
                  SET post_quick_cash_req_id = ln_lck_req_id
                WHERE lockbox_request_id =
                                  r_submit_process_lock_box.lockbox_request_id;

               COMMIT;
            END IF;
         END LOOP;

         DBMS_LOCK.sleep (60);                         -- Sleep for 60 seconds
         ln_pending_records := 0;

         OPEN c_pending_records;

         FETCH c_pending_records
          INTO ln_pending_records;

         EXIT WHEN c_pending_records%NOTFOUND;

         CLOSE c_pending_records;
      END LOOP;

      IF c_pending_records%ISOPEN
      THEN
         CLOSE c_pending_records;
      END IF;
   END processlb;
END xx_split_lockbox_pkg;
/
SHOW ERRORS
