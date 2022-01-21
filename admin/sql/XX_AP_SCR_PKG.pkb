CREATE OR REPLACE
PACKAGE BODY xx_ap_scr_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Providge Consulting                        |
-- +===================================================================+
-- | Name             :    XX_AP_SCR_PKG                               |
-- | Description      :    This Package is for 01. Capturing  all      |
-- |                       Eligible Open Invoices for  SCR Process     |
-- |                      02. Transmit Process - Submit the eamil      |
-- |                          bursting Program                         |
-- |                      03. Bundle Process -- Creating Credit Memo to|
-- |                          SCR Vendor and Standard Invoice to       |
-- |                          Financial Bank                           |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |    1.0   18-JUN-2007  Sarat Uppalapati    Initial version         |
-- |    1.0   26-SEP-2007  Sarat Uppalapati    commented               |
-- |                                        lc_v_site_hold_flag = 'N'  |
-- |    1.0   04-OCT-2007  Sarat Uppalapati    Added logic             |
-- |    1.0   30-OCT-2007  Sarat Uppalapti  CR 282 for Receipts Data   |
-- |    1.0   06-NOV-2007  Sarat Uppalapti  Separator changed to '|'   |
-- |    1.0   06-NOV-2007  Sarat Uppalapti  Appeneded vendor num to batch id  |
-- |    1.0   06-NOV-2007  Sarat Uppalapti  Changed Bank File Names    |
-- |    1.0   07-NOV-2007  Sarat Uppalapti  Changed Bank File Names    |
-- |    1.8   28-NOV-2007  Sandeep Pandhare Defect-2832 Update Due date on Payment Schedule |
-- |    1.9   05-DEC-2007  Sandeep Pandhare Defect-2914 Update Payment Method on Payment Schedule |
-- |    1.10  13-DEC-2007  Sandeep Pandhare Defect-2917 Replace US_OD_ACH to US_OD_SCR |
-- |    1.11  23-JAN-2008  Greg Dill        Defect-2914 Minor changes and removed duplicate call to APXIIMPT|
-- |    1.12  19-FEB-2008  Sowmya M S       Defect # 4613  - TOO_MANY_ROWS error in the transmit process |
-- +===================================================================+
AS
   PROCEDURE select_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_bank_name   IN       VARCHAR2
   )
   IS
   ln_cnt   NUMBER;
   ln_batch_id NUMBER;
   BEGIN
--        BEGIN
--        SELECT MAX (batch_id)
--           INTO ln_batch_id
--           FROM xxfin.xx_ap_scr_headers_all
--          WHERE scr_action = 'B';
--        END;

            SELECT COUNT(1)
            INTO ln_cnt
            FROM xx_ap_scr_headers_all;

            IF ln_cnt = 0 THEN
              /* First time run */
              capture_process (p_bank_name);
            ELSE
                /* Unfinished bacthes? */
                SELECT COUNT(1)
                INTO ln_cnt
                FROM xx_ap_scr_headers_all
                WHERE batch_id = (SELECT MAX(batch_id)
                                  FROM xx_ap_scr_headers_all)
                AND   scr_action = 'B';

                IF (ln_cnt = 0) THEN
                  fnd_file.put_line (fnd_file.LOG, '-------------------------------------');
                  fnd_file.put_line (fnd_file.LOG, 'Only one Active Batch at a time');
                  fnd_file.put_line (fnd_file.LOG, '-------------------------------------');
                ELSE
                  capture_process (p_bank_name);
                END IF;
            END IF;
END select_process;

   PROCEDURE capture_process (
      p_bank_name   IN       VARCHAR2
   )
   IS
      CURSOR c_scr_header
      IS
         SELECT   ai.vendor_site_id, ai.vendor_id, ai.org_id,
                  SUM (NVL (ai.invoice_amount, 0)) gross_amount,
                  SUM (NVL (ps.discount_amount_available, 0))
                                                             discount_amount,
                  (  SUM (NVL (ai.invoice_amount, 0))
                   - SUM (NVL (ps.discount_amount_available, 0))
                  ) net_amount,
                  SUM (NVL (ps.amount_remaining, 0)) gross_amount1,
                  SUM (NVL (ps.discount_amount_remaining, 0)) discount1
             FROM apps.ap_invoices ai,
                  apps.po_vendor_sites vs,
                  apps.ap_payment_schedules ps
            WHERE ai.vendor_site_id = vs.vendor_site_id
              AND ps.invoice_id = ai.invoice_id
             -- AND ai.invoice_amount - NVL (ps.discount_amount_available, 0) > 0 -- Commented 04/10/07
              AND vs.pay_group_lookup_code = 'US_OD_SCR'
              AND vs.hold_all_payments_flag = 'N'
              AND ps.payment_status_flag = 'N'
              AND ai.payment_method_lookup_code !='CLEARING'
              AND ai.pay_group_lookup_code != 'US_OD_SCR_CLEARING'
              AND ai.terms_id != (select term_id from ap_terms  where name = '00')
              AND (NOT EXISTS (
                      SELECT 'x'
                        FROM apps.ap_holds h
                       WHERE h.invoice_id = ai.invoice_id
                         AND h.release_lookup_code IS NULL)
                  )
              AND (EXISTS (
                      SELECT 'x'
                        FROM apps.ap_bank_account_uses bau,
                             apps.ap_bank_accounts aba,
                             apps.ap_bank_branches abb
                       WHERE bau.external_bank_account_id =
                                                           aba.bank_account_id
                         AND aba.bank_branch_id = abb.bank_branch_id
                         AND bau.vendor_site_id = ai.vendor_site_id
                         AND abb.bank_name = p_bank_name
                         AND bau.primary_flag = 'Y')
                  )
              AND (NOT EXISTS (
                      SELECT 'x'
                        FROM xxfin.xx_ap_scr_lines_all l
                             ,xxfin.xx_ap_scr_headers_all h
                       WHERE l.header_id = h.header_id
                         AND l.invoice_id = ai.invoice_id
                         AND DECODE(h.scr_action,'X','N','N') = DECODE(h.scr_action,'X','Y',l.reserve_flag)
                         AND h.batch_id = (SELECT MAX(batch_id)
                                             FROM xx_ap_scr_headers_all)
                       )
                  )
         GROUP BY ai.vendor_site_id, ai.vendor_id, ai.org_id
           HAVING (  SUM (NVL (ai.invoice_amount, 0))
                   - SUM (NVL (ps.discount_amount_available, 0))) > 0;

      CURSOR c_scr_line (p_vendor_site_id NUMBER)
      IS
         SELECT   inv.invoice_id, inv.org_id, inv.invoice_num,
                  s.payment_status_flag, inv.invoice_amount,
                  s.discount_amount_available, inv.SOURCE, inv.invoice_date
             FROM apps.ap_invoices inv, apps.ap_payment_schedules s
            WHERE s.invoice_id = inv.invoice_id
              AND inv.vendor_site_id = p_vendor_site_id
             -- AND (inv.invoice_amount - NVL (s.discount_amount_available, 0) ) > 0
              AND s.payment_status_flag = 'N'
              AND inv.payment_method_lookup_code !='CLEARING'
              AND inv.pay_group_lookup_code != 'US_OD_SCR_CLEARING'
              AND inv.terms_id != (select term_id from ap_terms  where name = '00')
              AND (NOT EXISTS (
                      SELECT 'x'
                        FROM apps.ap_holds h
                       WHERE h.invoice_id = inv.invoice_id
                         AND h.release_lookup_code IS NULL)
                  )
         ORDER BY inv.invoice_date ASC;

      lr_ap_scr_headers     xxfin.xx_ap_scr_headers_all%ROWTYPE;
      lr_ap_scr_lines       xxfin.xx_ap_scr_lines_all%ROWTYPE;
      lc_v_site_hold_flag   VARCHAR2 (1);
      ln_scr_cnt            NUMBER;
      ln_inv_hld_cnt        NUMBER;
      ld_date1              DATE                                  := SYSDATE;
      ln_user               NUMBER            := fnd_profile.VALUE ('USER_ID');
      ln_login              NUMBER           := fnd_profile.VALUE ('LOGIN_ID');
      ln_per_amount         NUMBER;
      ld_date               DATE;
      ln_days               NUMBER;
      ln_days_pending       NUMBER;
      ln_w_days             NUMBER;
      ld_w_date             DATE;
      ln_amt                NUMBER;
      ln_bundle_amt         NUMBER;
      ln_res_per            NUMBER;
      lc_error_flag         VARCHAR2 (1)                          := 'N';
      lc_error_loc          VARCHAR2 (2000)                       := NULL;
      lc_err_msg            VARCHAR2 (250);
      lc_shor_name          VARCHAR2 (250)                      := 'XXAPSCRSP';
      ln_req_id             NUMBER;
      ln_req_id1            NUMBER;
      ln_req_id2            NUMBER;
      lc_phase              VARCHAR2 (50);
      lc_reqstatus          VARCHAR2 (50);
      lc_devphase           VARCHAR2 (50);
      lc_devstatus          VARCHAR2 (50);
      lc_message            VARCHAR2 (50);
      lc_req_status         BOOLEAN;
      ln_pay_amount         NUMBER;

   BEGIN
      /* Assigning Batch ID */
      SELECT xxfin.xx_ap_scr_batch_id_s.NEXTVAL
        INTO lr_ap_scr_headers.batch_id
        FROM DUAL;

      /* Processig SCR Header Record */
      FOR lcu_scr_header IN c_scr_header
      LOOP
         --Initialization for each transactions
         lc_error_flag := 'N';

         /* Getting vendor site reserve hold info */
         BEGIN
            lc_error_loc :=
                    'Getting the most recent vendor site reserve hold info. ';

            SELECT COUNT (1)
              INTO ln_scr_cnt
              FROM xxfin.xx_ap_scr_headers_all
             WHERE vendor_site_id = lcu_scr_header.vendor_site_id;

            --AND org_id         = lcu_scr_header.org_id;
            IF (ln_scr_cnt >= 1)
            THEN
               SELECT auto_reserve,
                      reserve_return,
                      reserve_hold_amt
                 INTO lr_ap_scr_headers.auto_reserve,
                      lr_ap_scr_headers.reserve_return,
                      lr_ap_scr_headers.reserve_hold_amt
                 FROM xxfin.xx_ap_scr_headers_all
                WHERE ROWID =
                         (SELECT MAX (ROWID)
                            FROM xxfin.xx_ap_scr_headers_all
                           WHERE vendor_site_id =
                                                 lcu_scr_header.vendor_site_id
                             AND org_id = lcu_scr_header.org_id);
            ELSE
               lr_ap_scr_headers.auto_reserve := 'N';
               lr_ap_scr_headers.reserve_return := 0;
               lr_ap_scr_headers.reserve_hold_amt := 0;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_flag := 'Y';
               fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_err_msg);
               xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SCR SELECT PROCESS'
                                 );
         END;

           /* Getting vendor name and Bank account */
         BEGIN
            lc_error_loc := 'Getting the vendor name and bank account. ';

            SELECT v.vendor_name,
                   aba.bank_account_name,
                   aba.bank_account_num
              INTO lr_ap_scr_headers.vendor_name,
                   lr_ap_scr_headers.bank_account_name,
                   lr_ap_scr_headers.bank_account_num
              FROM apps.ap_bank_account_uses_all bau,
                   apps.ap_bank_accounts_all aba,
                   apps.ap_bank_branches abb,
                   apps.po_vendor_sites_all vs,
                   apps.po_vendors v
             WHERE bau.external_bank_account_id = aba.bank_account_id
               AND aba.bank_branch_id = abb.bank_branch_id
               AND bau.vendor_site_id = vs.vendor_site_id
               AND vs.vendor_id = v.vendor_id
               AND bau.vendor_site_id = lcu_scr_header.vendor_site_id
               AND abb.bank_name = p_bank_name
               AND bau.primary_flag = 'Y'
               AND vs.org_id = lcu_scr_header.org_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_v_site_hold_flag := 'K';
               lc_error_flag := 'Y';
               fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_err_msg);
               xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SCR SELECT PROCESS'
                                 );
         END;

         IF (--lc_v_site_hold_flag = 'N' AND  -- Commented on 09/26/07
               lc_error_flag = 'N')
         THEN
            SELECT xxfin.xx_ap_scr_header_id_s.NEXTVAL
              INTO lr_ap_scr_headers.header_id
              FROM DUAL;

            lr_ap_scr_headers.vendor_site_id := lcu_scr_header.vendor_site_id;
            lr_ap_scr_headers.gross_amount := lcu_scr_header.gross_amount;
            lr_ap_scr_headers.discount_amount :=
                                                lcu_scr_header.discount_amount;
            lr_ap_scr_headers.net_amount := lcu_scr_header.net_amount;
            lr_ap_scr_headers.org_id := lcu_scr_header.org_id;
            lr_ap_scr_headers.scr_action := 'E';
            lr_ap_scr_headers.scr_status := 'A';
            lr_ap_scr_headers.eff_status := 'A';
            lr_ap_scr_headers.last_update_date := ld_date1;
            lr_ap_scr_headers.last_updated_by := ln_user;
            lr_ap_scr_headers.creation_date := ld_date1;
            lr_ap_scr_headers.created_by := ln_user;
            lr_ap_scr_headers.last_update_login := ln_login;

            -- Begin CR 282
            BEGIN
            SELECT SUM(open_reciever_amount)
              INTO lr_ap_scr_headers.receipts
              FROM xxfin.xx_ap_scr_receiver_stg
             WHERE xx_po_global_vendor_pkg.f_translate_inbound(global_vendor_id) =  lcu_scr_header.vendor_site_id
               AND open_reciever_days <= 60;
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
               lr_ap_scr_headers.receipts := 0;
            END;
            -- End CR 282

            BEGIN
               INSERT INTO xxfin.xx_ap_scr_headers_all
                    VALUES lr_ap_scr_headers;

               COMMIT;
            END;

            --Reset for each transactions
            lr_ap_scr_headers.programs := 0;
            lr_ap_scr_headers.returns := 0;
            ln_per_amount := NULL;
            ln_days := NULL;
            ld_date := NULL;
            ln_days_pending := NULL;
            ln_w_days := 0;
            ln_amt := 0;
            ln_bundle_amt := 0;

            FOR lcu_scr_line IN c_scr_line (lcu_scr_header.vendor_site_id)
            LOOP
               --Initialization for each transactions
               lc_error_flag := 'N';

               IF lr_ap_scr_headers.reserve_hold_amt <> 0
               THEN
                  ln_amt := ln_amt + lcu_scr_line.invoice_amount;
                  ln_res_per :=
                       (  (  lr_ap_scr_headers.gross_amount
                           - lr_ap_scr_headers.reserve_hold_amt
                          )
                        * lr_ap_scr_headers.reserve_return
                       )
                     / 100;

                  IF (ln_amt >=
                         (  lr_ap_scr_headers.gross_amount
                          - lr_ap_scr_headers.reserve_hold_amt
                          - ln_res_per
                         )
                     )
                  THEN
                     lr_ap_scr_lines.reserve_flag := 'Y';
                  ELSE
                     lr_ap_scr_lines.reserve_flag := 'N';
                     ln_bundle_amt :=
                          ln_bundle_amt
                        + lcu_scr_line.invoice_amount
                        - NVL (lcu_scr_line.discount_amount_available, 0);
                  END IF;
               ELSE
                  lr_ap_scr_lines.reserve_flag := 'N';
                  ln_bundle_amt :=
                       ln_bundle_amt
                     + lcu_scr_line.invoice_amount
                     - NVL (lcu_scr_line.discount_amount_available, 0);
               END IF;

               BEGIN
                  lc_error_loc := 'Getting the invoice due date. ';

                  SELECT UNIQUE due_date
                           INTO ld_date
                           FROM apps.ap_payment_schedules_all
                          WHERE payment_status_flag = 'N'
                            AND invoice_id = lcu_scr_line.invoice_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                     fnd_message.set_token ('ERR_LOC', lc_error_loc);
                     fnd_message.set_token ('ERR_ORA', SQLERRM);
                     lc_err_msg := fnd_message.get;
                     fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                     xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SCR SELECT PROCESS'
                                 );
               END;

               SELECT xxfin.xx_ap_scr_line_id_s.NEXTVAL
                 INTO lr_ap_scr_lines.line_id
                 FROM DUAL;

               lr_ap_scr_lines.header_id := lr_ap_scr_headers.header_id;
               lr_ap_scr_lines.invoice_id := lcu_scr_line.invoice_id;
               lr_ap_scr_lines.org_id := lcu_scr_line.org_id;
               lr_ap_scr_lines.invoice_num := lcu_scr_line.invoice_num;
               lr_ap_scr_lines.invoice_date := lcu_scr_line.invoice_date;
               lr_ap_scr_lines.invoice_due_date := ld_date;
               lr_ap_scr_lines.invoice_amount := lcu_scr_line.invoice_amount;
               lr_ap_scr_lines.discount_amount := lcu_scr_line.discount_amount_available;
               lr_ap_scr_lines.last_update_date := ld_date1;
               lr_ap_scr_lines.last_updated_by := ln_user;
               lr_ap_scr_lines.creation_date := ld_date1;
               lr_ap_scr_lines.created_by := ln_user;
               lr_ap_scr_lines.last_update_login := ln_login;

               BEGIN
                  INSERT INTO xxfin.xx_ap_scr_lines_all
                       VALUES lr_ap_scr_lines;

                  COMMIT;
               END;

               ln_per_amount :=
                     lcu_scr_line.invoice_amount / lcu_scr_header.gross_amount;



               ln_days := ld_date - SYSDATE;
               ln_days_pending := ROUND (ln_days) * ROUND (ln_per_amount, 2);
               ln_w_days := NVL (ln_days_pending, 0) + NVL (ln_w_days, 0);

               IF lcu_scr_line.SOURCE = 'US_OD_RTV_MERCHANDISING'
               THEN
                  lr_ap_scr_headers.returns :=
                       NVL (lcu_scr_line.invoice_amount, 0)
                     + lr_ap_scr_headers.returns;
               ELSIF lcu_scr_line.SOURCE = 'US_OD_VENDOR_PROGRAM'
               THEN
                  lr_ap_scr_headers.programs :=
                       NVL (lcu_scr_line.invoice_amount, 0)
                     + lr_ap_scr_headers.programs;
               END IF;
            END LOOP;

            SELECT SYSDATE + ROUND (ln_w_days)
              INTO lr_ap_scr_headers.weighted_date
              FROM DUAL;

            BEGIN
               UPDATE xxfin.xx_ap_scr_headers_all
                  SET weighted_date = lr_ap_scr_headers.weighted_date,
                      programs = lr_ap_scr_headers.programs,
                      returns = lr_ap_scr_headers.returns,
                      receipts = 0,
                      bundle_amount = ln_bundle_amt,
                      payable_amount = ( SELECT  NVL(SUM(NVL(invoice_amount,0) - NVL(discount_amount,0)),0)
                                           FROM xxfin.xx_ap_scr_lines_all
                                          WHERE reserve_flag = 'N'
                                            AND header_id    = lr_ap_scr_headers.header_id
                                        )
                WHERE vendor_site_id = lr_ap_scr_headers.vendor_site_id
                  AND org_id = lr_ap_scr_headers.org_id
                  AND batch_id = lr_ap_scr_headers.batch_id;

               COMMIT;
            END;
         END IF;
      END LOOP;

      /* Sumbit request for OD: AP SCR Select Report */
      ln_req_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXAPSCR1',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     'E',
                                     lr_ap_scr_headers.batch_id
                                    );
      /* Start the request */
      COMMIT;

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                       (fnd_file.LOG,
                        'Error submitting request for ''OD: AP SCR Select Report''.'
                       );
         lc_error_loc := 'Error submitting request for OD: AP SCR Select Report';
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                  (p_program_type                => 'CONCURRENT PROGRAM',
                                   p_program_name                => lc_shor_name,
                                   p_program_id                  => fnd_global.conc_program_id,
                                   p_module_name                 => 'AP',
                                   p_error_location              =>    'Error at '
                                                                    || lc_error_loc,
                                   p_error_message_count         => 1,
                                   p_error_message_code          => 'E',
                                   p_error_message               => lc_err_msg,
                                   p_error_message_severity      => 'Major',
                                   p_notify_flag                 => 'N',
                                   p_object_type                 => 'OD: AP SCR Select Report'
                                  );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''OD: AP SCR Select Report'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_loc := 'Unexpected Error';
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SCR SELECT PROCESS'
                                 );
   END capture_process;

   PROCEDURE transmit_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_batch_id    IN OUT   NUMBER
   )
   IS
      ln_req_id       NUMBER;
      ln_req_id1      NUMBER;
      ln_req_id2      NUMBER;
      lc_error_flag   VARCHAR2 (1)    := 'N';
      lc_error_loc    VARCHAR2 (2000) := NULL;
      lc_err_msg      VARCHAR2 (250);
      lc_shor_name    VARCHAR2 (250)  := 'XXAPSCRTP';
      lc_instance_name VARCHAR2(2000);
      lc_web_host_name VARCHAR2(2000);

      lc_phase        VARCHAR2 (50);
      lc_status       VARCHAR2 (50);
      lc_devphase     VARCHAR2 (50);
      lc_devstatus    VARCHAR2 (50);
      lc_message      VARCHAR2 (50);
      lc_req_status   BOOLEAN;

   BEGIN
 -- For Defect-4613
      SELECT name
        INTO lc_instance_name
        FROM v$database;

     /* SELECT host
        INTO lc_web_host_name
        FROM apps.fnd_nodes
        WHERE webhost IS NOT NULL
        AND domain = 'na.odcorp.net'; */

       
         SELECT XFTV.target_value1
         INTO lc_web_host_name
         FROM   xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
         WHERE  XFTV.translate_id    = XFTD.translate_id
         AND    XFTD.translation_name = 'XX_AP_SCR_APPL_SERVER'
         AND    XFTV.source_value1 = lc_instance_name
         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
         AND    XFTV.enabled_flag = 'Y'
         AND    XFTD.enabled_flag = 'Y';
      /* Sumbit request for OD: AP SCR Report */
      ln_req_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXAPSCRD',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     p_batch_id
                                    );
      /* Start the request */
      COMMIT;

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error submitting request for ''OD: AP SCR Invoice Detail Report''.'
            );
         lc_error_loc :=
               'Error submitting request for OD: AP SCR Invoice Detail Report';
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                          (p_program_type                => 'CONCURRENT PROGRAM',
                           p_program_name                => lc_shor_name,
                           p_program_id                  => fnd_global.conc_program_id,
                           p_module_name                 => 'AP',
                           p_error_location              =>    'Error at '
                                                            || lc_error_loc,
                           p_error_message_count         => 1,
                           p_error_message_code          => 'E',
                           p_error_message               => lc_err_msg,
                           p_error_message_severity      => 'Major',
                           p_notify_flag                 => 'N',
                           p_object_type                 => 'OD: AP SCR Invoice Detail Report'
                          );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''OD: AP SCR Detail Report'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
                     /* Wait for the OD: AP SCR Detail Report request to complete */
             lc_req_status := fnd_concurrent.wait_for_request(
                                                        ln_req_id     -- request_id
                                                        ,30           -- interval
                                                        ,360000       -- max_wait
                                                        ,lc_phase     -- phase
                                                        ,lc_status    -- status
                                                        ,lc_devphase  -- dev_phase
                                                        ,lc_devstatus -- dev_status
                                                        ,lc_message   -- message
                                                       );
                /* Submit the OD: AP SCR Invoice Burst Process*/
                ln_req_id1 :=
                fnd_request.submit_request ('XXFIN'
                                            ,'XXAPSCRBUP'
                                            ,NULL
                                            ,NULL
                                            ,FALSE
                                            ,ln_req_id
                                            ,lc_instance_name
                                            ,lc_web_host_name
                                            ,'Y'
                                            ,chr(0)
                                            );
               /* Start the request */
               COMMIT;
               IF (ln_req_id1 = 0) THEN
                  fnd_file.put_line
                  (fnd_file.LOG,
                       'Error submitting request for ''OD: AP SCR Invoice Burst Process''.'
                  );
               ELSE
                  fnd_file.put_line (fnd_file.output,
                          'Started ''OD: AP SCR Invoice Burst Process'' at '
                          || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
                  fnd_file.put_line (fnd_file.output, ' ');
                  UPDATE xxfin.xx_ap_scr_headers_all
                   SET scr_action = 'S'
                 WHERE batch_id = p_batch_id
                   AND scr_action = 'E';
                     /* Wait for the OD: AP SCR Invoice Burst Process request to complete */
                lc_req_status := fnd_concurrent.wait_for_request(
                                                        ln_req_id     -- request_id
                                                        ,30           -- interval
                                                        ,360000       -- max_wait
                                                        ,lc_phase     -- phase
                                                        ,lc_status    -- status
                                                        ,lc_devphase  -- dev_phase
                                                        ,lc_devstatus -- dev_status
                                                        ,lc_message   -- message
                                                       );
                 COMMIT;
                 /* Submit the OD: AP SCR Transmit Report */
                ln_req_id2 :=
                fnd_request.submit_request ('XXFIN'
                                            ,'XXAPSCR2'
                                            ,NULL
                                            ,NULL
                                            ,FALSE
                                            ,'S'
                                            ,p_batch_id
                                            );
                IF (ln_req_id2 = 0) THEN
                  fnd_file.put_line
                  (fnd_file.LOG,
                       'Error submitting request for ''OD: AP SCR Transmit Report''.'
                  );
                  fnd_file.put_line (fnd_file.output, ' ');
                ELSE
                  fnd_file.put_line (fnd_file.output,
                          'Started ''OD: AP SCR Transmit Report'' at '
                          || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
                  fnd_file.put_line (fnd_file.output, ' ');
                END IF;
               END IF;

      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_loc := 'Unexpected Error';
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPSCRD',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'SCR TRANSMIT PROCESS'
                                 );
   END transmit_process;

   PROCEDURE get_id_flex_num (
      p_flex_structure_code   IN       VARCHAR2 DEFAULT 'OD_GLOBAL_COA',
      x_id_flex_num           OUT      NUMBER,
      x_segment_delimiter     OUT      VARCHAR2,
      x_returnmessage         OUT      VARCHAR2
   )
   IS
   -- Retrieve AFF id_flex_num and segment delimiter.
   BEGIN
      SELECT concatenated_segment_delimiter, id_flex_num
        INTO x_segment_delimiter, x_id_flex_num
        FROM fnd_id_flex_structures
       WHERE application_id = 101
         AND id_flex_code = 'GL#'
         AND id_flex_structure_code = p_flex_structure_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_returnmessage := 'AFF structure not defined: ' || 'OD_GLOBAL_COA';
   END get_id_flex_num;

   PROCEDURE bundle_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_batch_id    IN       NUMBER
   )


   IS
      CURSOR c_inv_header
      IS
         SELECT h.ROWID, h.header_id, h.vendor_site_id, h.bundle_amount,
                h.org_id
           FROM xxfin.xx_ap_scr_headers_all h
          WHERE h.batch_id = p_batch_id AND h.scr_action = 'S';

      CURSOR c_inv_lines (p_header_id IN NUMBER)
      IS
         SELECT l.ROWID, l.invoice_id, i.invoice_num, (nvl(l.invoice_amount,0)-nvl(l.discount_amount,0)) invoice_amount
          --i.invoice_amount
           FROM xxfin.xx_ap_scr_lines_all l, apps.ap_invoices_all i
          WHERE l.invoice_id = i.invoice_id
            AND l.header_id = p_header_id
            AND l.reserve_flag = 'N';

      CURSOR c_b_inv_header
      IS
         SELECT   SUM (h.bundle_amount) bundle_amount, h.org_id,h.weighted_date
             FROM xxfin.xx_ap_scr_headers_all h
            WHERE h.batch_id = p_batch_id AND h.scr_action = 'S'
         GROUP BY h.batch_id, h.org_id,h.weighted_date;

      CURSOR c_b_inv_lines (p_weighted_date IN DATE)
      IS
         SELECT h.ROWID, h.header_id, h.vendor_site_id, h.vendor_name,
                h.bank_account_name, h.bank_account_num, h.bundle_amount,
                h.org_id
           FROM xxfin.xx_ap_scr_headers_all h
          WHERE h.batch_id = p_batch_id
            AND h.scr_action = 'S'
            AND TRUNC(h.weighted_date) = TRUNC(p_weighted_date);
      CURSOR c_bundled_inv (p_batch_id IN NUMBER)
      IS
         SELECT l.ROWID, l.invoice_id
           FROM xxfin.xx_ap_scr_headers_all h
                ,xxfin.xx_ap_scr_lines_all l
          WHERE l.header_id = h.header_id
            AND h.batch_id = p_batch_id
            AND h.scr_action = 'B'
            AND l.reserve_flag = 'N';

      lr_ap_invoices_interface        ap_invoices_interface%ROWTYPE;
      lr_ap_invoice_lines_interface   ap_invoice_lines_interface%ROWTYPE;
      ld_date                         DATE                          := SYSDATE;
      ln_user                         NUMBER  := fnd_profile.VALUE ('USER_ID');
      ln_login                        NUMBER := fnd_profile.VALUE ('LOGIN_ID');
      lc_wf_flag                      VARCHAR2 (1)                     := NULL;
      lc_error_flag                   VARCHAR2 (1)                      := 'N';
      lc_error_loc                    VARCHAR2 (2000)                  := NULL;
      lc_err_msg                      VARCHAR2 (250);
      ln_count                        NUMBER                              := 1;
      ln_tot_batch_count              NUMBER                              := 0;
      ln_failed_val_count             NUMBER                              := 0;
      ln_failed_proc_count            NUMBER                              := 0;
      ln_sucess_count                 NUMBER                              := 0;
      ln_line_count                   NUMBER                              := 0;
      ln_line_num                     NUMBER                              := 0;
      ln_b_tot_batch_count            NUMBER                              := 0;
      ln_b_failed_val_count           NUMBER                              := 0;
      ln_b_failed_proc_count          NUMBER                              := 0;
      ln_b_line_count                 NUMBER                              := 0;
      ln_b_line_num                   NUMBER                              := 0;
      ln_req_id                       NUMBER;
      ln_req_id1                      NUMBER;
      ln_req_id2                      NUMBER;
      ln_req_id3                      NUMBER;
      lc_shor_name                    VARCHAR2 (250)             := 'XXAPSCBP';
      lc_phase                        VARCHAR2 (50);
      lc_reqstatus                    VARCHAR2 (50);
      lc_devphase                     VARCHAR2 (50);
      lc_devstatus                    VARCHAR2 (50);
      lc_message                      VARCHAR2 (50);
      lc_req_status                   BOOLEAN;
      l_valid_result                  BOOLEAN;
      l_new_concat_segments           VARCHAR2 (3000);
      l_returnmessage                 VARCHAR2 (4000);
      ln_counter             NUMBER :=0;
      ln_counter1            NUMBER :=0;
      l_new_aff_ccid                  gl_code_combinations.code_combination_id%TYPE;
      l_id_flex_num                   fnd_id_flex_structures.id_flex_num%TYPE;
      l_segment_delimiter             fnd_id_flex_structures.concatenated_segment_delimiter%TYPE;
   BEGIN
      FOR lcu_inv_header IN c_inv_header
      LOOP                                              -- Header Loop Begins
         BEGIN                                                -- Header Begin
            --Initialization for each transactions
            lc_error_flag := 'N';
            ln_tot_batch_count := ln_tot_batch_count + 1;
            ln_counter := ln_counter + 1;

            /* < Selecting vendor information into a local variables from po_vendor_sites_all table > */
            BEGIN
               fnd_file.put_line
                          (fnd_file.LOG,
                           '                                                '
                          );
               fnd_file.put_line (fnd_file.LOG, 'Validating the Vendor');

               SELECT vendor_id,
                      vendor_site_code,
                      payment_method_lookup_code,
                      pay_group_lookup_code,
                      terms_id,
                      invoice_currency_code
                 INTO lr_ap_invoices_interface.vendor_id,
                      lr_ap_invoices_interface.vendor_site_code,
                      lr_ap_invoices_interface.payment_method_lookup_code,
                      lr_ap_invoices_interface.pay_group_lookup_code,
                      lr_ap_invoices_interface.terms_id,
                      lr_ap_invoices_interface.invoice_currency_code
                 FROM apps.po_vendor_sites
                WHERE vendor_site_id = lcu_inv_header.vendor_site_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_flag := 'Y';
                  lc_error_loc := 'Error while populating the Vendor';
                  fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                  xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Credit to Vendor'
                                 );
            END;

            /* < Assigning sequence number to a local variable > */
            SELECT apps.ap_invoices_interface_s.NEXTVAL
              INTO lr_ap_invoices_interface.invoice_id
              FROM DUAL;

            lr_ap_invoices_interface.invoice_type_lookup_code := 'CREDIT';
            lr_ap_invoices_interface.invoice_num              := 'SCR CREDIT: '||p_batch_id||' - '||LPAD(ln_counter,4,'0');
            lr_ap_invoices_interface.invoice_date := ld_date;
            lr_ap_invoices_interface.org_id := lcu_inv_header.org_id;
            lr_ap_invoices_interface.goods_received_date := ld_date;
                                                               -- need a value
            lr_ap_invoices_interface.creation_date := ld_date;
            lr_ap_invoices_interface.created_by := ln_user;
            lr_ap_invoices_interface.last_update_date := ld_date;
            lr_ap_invoices_interface.last_updated_by := ln_user;
            lr_ap_invoices_interface.last_update_login := ln_login;
            lr_ap_invoices_interface.payment_method_lookup_code := 'CLEARING';
            lr_ap_invoices_interface.pay_group_lookup_code := 'US_OD_SCR_CLEARING';
            lr_ap_invoices_interface.terms_name := '00';
            select term_id
              into lr_ap_invoices_interface.terms_id
              from ap_terms
             where name ='00';

            IF (lcu_inv_header.bundle_amount > 0)
            THEN
               lr_ap_invoices_interface.invoice_amount :=
                                          (0 - lcu_inv_header.bundle_amount
                                          );
            ELSE
               lr_ap_invoices_interface.invoice_amount :=
                                                 lcu_inv_header.bundle_amount;
            END IF;

            lr_ap_invoices_interface.gl_date := ld_date;
            lr_ap_invoices_interface.description :=
                            'SCR CREDIT' || TO_CHAR (SYSDATE, 'MM/DD/RR HH24:MI:SS');
            lr_ap_invoices_interface.SOURCE := 'US_OD_SCR';
            lr_ap_invoices_interface.workflow_flag := lc_wf_flag;

             --lr_ap_invoices_interface.attribute8                    := lcu_inv_header.attribute8;
             --lr_ap_invoices_interface.attribute9                      := lcu_inv_header.attribute9;
             --lr_ap_invoices_interface.attribute10                      := lcu_inv_header.attribute10;
             --lr_ap_invoices_interface.attribute13                      := lcu_inv_header.attribute13;
             --lr_ap_invoices_interface.voucher_num                      := lcu_inv_header.voucher_num;
             --lr_ap_invoices_interface.exclusive_payment_flag        := lcu_inv_header.exclusive_payment_flag;
             --lr_ap_invoices_interface.amount_applicable_to_discount    := lcu_inv_header.amount_applicable_to_discount;
             --lr_ap_invoices_interface.terms_date                      := lcu_inv_header.terms_date;
            /*
            IF (lc_error_flag = 'Y')
              THEN
              ln_failed_val_count := ln_failed_val_count + SQL%ROWCOUNT;
                UPDATE xxfin.XX_AP_SCR_HEADERS_ALL
                   SET process_flag = '3'
                 WHERE rowid = lcu_inv_header.ROWID
                   AND process_flag = 2;
                COMMIT;
             ELSE
                UPDATE xxfin.XX_AP_SCR_HEADERS_ALL
                   SET process_flag = '4'
                 WHERE rowid = lcu_inv_header.ROWID
                   AND process_flag = 2;
                COMMIT;
             END IF;
             */
            IF (lc_error_flag = 'N')
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  '                               '
                                 );
               fnd_file.put_line
                                (fnd_file.LOG,
                                 'Inserting into ap_invoices_interface table.'
                                );

               BEGIN
                  INSERT INTO apps.ap_invoices_interface
                       VALUES lr_ap_invoices_interface;

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_flag := 'Y';
                     lc_error_loc := 'unable to insert:';
                     fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                     fnd_message.set_token ('ERR_LOC', lc_error_loc);
                     fnd_message.set_token ('ERR_ORA', SQLERRM);
                     lc_err_msg := fnd_message.get;
                     fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                     xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Credit to Vendor'
                                 );
               END;
            END IF;

            /* < For Loop for the lines > */
            IF (lc_error_flag = 'N')
            THEN
               ln_line_count := 0;
               ln_line_num := 0;

               FOR lcu_inv_lines IN c_inv_lines (lcu_inv_header.header_id)
               LOOP                                       -- Line Loop Begins
                  ln_line_count := ln_line_count + SQL%ROWCOUNT;
                  ln_line_num := ln_line_num + 1;

                  BEGIN                                    -- Begin for lines
                     /* < Generating sequence number for invoice_line_id  > */
                     SELECT apps.ap_invoice_lines_interface_s.NEXTVAL
                       INTO lr_ap_invoice_lines_interface.invoice_line_id
                       FROM DUAL;

                     BEGIN
                        /*
                         SELECT code_combination_id
                           INTO lr_ap_invoice_lines_interface.dist_code_combination_id
                           FROM apps.gl_code_combinations
                          WHERE segment1 = '1001'
                            AND segment2 = '00000'
                            AND segment3 = '20108000'
                            AND segment4 = '000000'
                            AND segment5 = '0000'
                            AND segment6 = '00'
                            AND segment7 = '000000';
                            */
                        get_id_flex_num
                                 (x_id_flex_num            => l_id_flex_num,
                                  x_segment_delimiter      => l_segment_delimiter,
                                  x_returnmessage          => l_returnmessage
                                 );
                        -- Compose new concatenated account combinations.
                        l_new_concat_segments :=
                              '1001'
                           || l_segment_delimiter
                           || '00000'
                           || l_segment_delimiter
                           || '20108000'
                           || l_segment_delimiter
                           || '010000'
                           || l_segment_delimiter
                           || '0000'
                           || l_segment_delimiter
                           || '90'
                           || l_segment_delimiter
                           || '000000';
                        -- Validate account combination exists.
                        l_valid_result :=
                           fnd_flex_keyval.validate_segs
                                     (operation             => 'CREATE_COMBINATION',
                                      appl_short_name       => 'SQLGL',
                                      key_flex_code         => 'GL#',
                                      structure_number      => l_id_flex_num,
                                      concat_segments       => l_new_concat_segments
                                     );

                        IF NOT l_valid_result
                        THEN
                           lc_err_msg := fnd_flex_keyval.error_message;
                        ELSE
                           l_new_aff_ccid := fnd_flex_keyval.combination_id;

                           IF (l_new_aff_ccid = -1)
                           THEN
                              lc_err_msg :=
                                    'Invalid account combination: '
                                 || l_new_concat_segments;
                              lc_error_flag := 'Y';
                           ELSE
                              lc_err_msg := l_new_aff_ccid;
                              lr_ap_invoice_lines_interface.dist_code_combination_id :=
                                                               l_new_aff_ccid;
                           END IF;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           lc_error_flag := 'Y';
                           lc_error_loc := 'GL code combination not defined:';
                           fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                           fnd_message.set_token ('ERR_LOC', lc_error_loc);
                           fnd_message.set_token ('ERR_ORA', SQLERRM);
                           lc_err_msg := fnd_message.get;
                           fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                           xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Credit to Vendor'
                                 );
                     END;

                     lr_ap_invoice_lines_interface.invoice_id :=
                                           lr_ap_invoices_interface.invoice_id;
                     lr_ap_invoice_lines_interface.line_number := ln_line_num;
                     lr_ap_invoice_lines_interface.line_type_lookup_code :=
                                                                        'ITEM';
                     lr_ap_invoice_lines_interface.amount :=
                                           (0 - lcu_inv_lines.invoice_amount
                                           );
                     lr_ap_invoice_lines_interface.accounting_date := ld_date;
                     lr_ap_invoice_lines_interface.description :=
                           lcu_inv_lines.invoice_num
                        || ''
                        || TO_CHAR (SYSDATE, 'MM/DD/RR HH24:MI:SS');
                     lr_ap_invoice_lines_interface.org_id :=
                                               lr_ap_invoices_interface.org_id;
                     lr_ap_invoice_lines_interface.creation_date :=
                                        lr_ap_invoices_interface.creation_date;
                     lr_ap_invoice_lines_interface.created_by :=
                                           lr_ap_invoices_interface.created_by;
                     lr_ap_invoice_lines_interface.last_update_date :=
                                     lr_ap_invoices_interface.last_update_date;
                     lr_ap_invoice_lines_interface.last_updated_by :=
                                      lr_ap_invoices_interface.last_updated_by;
                     lr_ap_invoice_lines_interface.last_update_login :=
                                    lr_ap_invoices_interface.last_update_login;

                     IF (lc_error_flag = 'N')
                     THEN
                        fnd_file.put_line (fnd_file.LOG,
                                           '                               '
                                          );
                        fnd_file.put_line
                           (fnd_file.LOG,
                            'Inserting into ap_invoice_lines_interface table.'
                           );

                        BEGIN
                           INSERT INTO apps.ap_invoice_lines_interface
                                VALUES lr_ap_invoice_lines_interface;

                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lc_error_flag := 'Y';
                              lc_error_loc := 'unable to insert:';
                              fnd_message.set_name ('XXFIN',
                                                    'XX_AP_0001_ERR');
                              fnd_message.set_token ('ERR_LOC', lc_error_loc);
                              fnd_message.set_token ('ERR_ORA', SQLERRM);
                              lc_err_msg := fnd_message.get;
                              fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                              xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Credit to Vendor'
                                 );
                        END;
                     END IF;
                  END;                                        -- End for lines
               END LOOP;                                  -- END for line loop
            END IF;
         END;                                                    -- Header End
      END LOOP;

      FOR lcu_b_inv_header IN c_b_inv_header
      LOOP                         -- Header creating Standard invoice to Bank
         --Initialization for each transactions
         lc_error_flag := 'N';
         ln_b_tot_batch_count := ln_b_tot_batch_count + 1;
         ln_counter1 := ln_counter1 + 1;

         BEGIN
            SELECT vs.vendor_site_id
              INTO lr_ap_invoices_interface.vendor_site_id
              FROM apps.ap_bank_branches abb,
                   apps.ap_bank_accounts aba,
                   apps.po_vendor_sites vs
             WHERE aba.bank_branch_id = abb.bank_branch_id
               AND aba.attribute1 = vs.vendor_id
               AND vs.primary_pay_site_flag = 'Y'
               AND vs.pay_site_flag = 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_flag := 'Y';
               lc_error_loc := 'Error while populating the Bank Vendor ';
               fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_err_msg);
               xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Debit to Bank Vendor'
                                 );
         END;

         BEGIN
            fnd_file.put_line
                          (fnd_file.LOG,
                           '                                                '
                          );
            fnd_file.put_line (fnd_file.LOG, 'Validating the Bank Vendor');

            SELECT vendor_id,
                   vendor_site_code,
                   payment_method_lookup_code,
                   pay_group_lookup_code,
                   terms_id,
                   invoice_currency_code
              INTO lr_ap_invoices_interface.vendor_id,
                   lr_ap_invoices_interface.vendor_site_code,
                   lr_ap_invoices_interface.payment_method_lookup_code,
                   lr_ap_invoices_interface.pay_group_lookup_code,
                   lr_ap_invoices_interface.terms_id,
                   lr_ap_invoices_interface.invoice_currency_code
              FROM apps.po_vendor_sites
             WHERE vendor_site_id = lr_ap_invoices_interface.vendor_site_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_flag := 'Y';
               lc_error_loc := 'Error while populating the Bank Vendor';
               fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_err_msg);
               xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Debit to Bank Vendor'
                                 );
         END;

         /* < Assigning sequence number to a local variable > */
         SELECT apps.ap_invoices_interface_s.NEXTVAL
           INTO lr_ap_invoices_interface.invoice_id
           FROM DUAL;

         lr_ap_invoices_interface.invoice_type_lookup_code := 'STANDARD';
         lr_ap_invoices_interface.invoice_num              := 'SCR STANDARD: '||p_batch_id||' - '||LPAD(ln_counter1,4,'0');
         lr_ap_invoices_interface.invoice_date := ld_date;
         lr_ap_invoices_interface.org_id := lcu_b_inv_header.org_id;
         lr_ap_invoices_interface.goods_received_date := ld_date;
                                                               -- need a value
         lr_ap_invoices_interface.creation_date := ld_date;
         lr_ap_invoices_interface.created_by := ln_user;
         lr_ap_invoices_interface.last_update_date := ld_date;
         lr_ap_invoices_interface.last_updated_by := ln_user;
         lr_ap_invoices_interface.last_update_login := ln_login;
         lr_ap_invoices_interface.workflow_flag := lc_wf_flag;
         lr_ap_invoices_interface.invoice_amount :=
                                                lcu_b_inv_header.bundle_amount;
         lr_ap_invoices_interface.gl_date := ld_date;
         lr_ap_invoices_interface.description :=
                            'SCR ' || TO_CHAR (SYSDATE, 'MM/DD/RR HH24:MI:SS');
         lr_ap_invoices_interface.SOURCE := 'US_OD_SCR';   -- defect 2917
         lr_ap_invoices_interface.terms_date := lcu_b_inv_header.weighted_date;

         IF (lc_error_flag = 'N')
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               '                               '
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Inserting into ap_invoices_interface table.'
                              );

            BEGIN
               INSERT INTO apps.ap_invoices_interface
                    VALUES lr_ap_invoices_interface;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_flag := 'Y';
                  lc_error_loc := 'unable to insert:';
                  fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                  xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Debit to Bank Vendor'
                                 );
            END;
         END IF;

         /* < For Loop for the lines > */
         IF (lc_error_flag = 'N')
         THEN
            ln_b_line_count := 0;
            ln_b_line_num := 0;

            FOR lcu_b_inv_lines IN c_b_inv_lines (lcu_b_inv_header.weighted_date)
            LOOP                                          -- Line Loop Begins
               ln_b_line_count := ln_b_line_count + SQL%ROWCOUNT;
               ln_b_line_num := ln_b_line_num + 1;

               BEGIN                                       -- Begin for lines
                  /* < Generating sequence number for invoice_line_id  > */
                  SELECT apps.ap_invoice_lines_interface_s.NEXTVAL
                    INTO lr_ap_invoice_lines_interface.invoice_line_id
                    FROM DUAL;

                  BEGIN

                     get_id_flex_num
                                 (x_id_flex_num            => l_id_flex_num,
                                  x_segment_delimiter      => l_segment_delimiter,
                                  x_returnmessage          => l_returnmessage
                                 );
                     -- Compose new concatenated account combinations.
                     l_new_concat_segments :=
                           '1001'
                        || l_segment_delimiter
                        || '00000'
                        || l_segment_delimiter
                        || '20108000'
                        || l_segment_delimiter
                        || '010000'
                        || l_segment_delimiter
                        || '0000'
                        || l_segment_delimiter
                        || '90'
                        || l_segment_delimiter
                        || '000000';
                     l_valid_result :=
                        fnd_flex_keyval.validate_segs
                                     (operation             => 'CREATE_COMBINATION',
                                      appl_short_name       => 'SQLGL',
                                      key_flex_code         => 'GL#',
                                      structure_number      => l_id_flex_num,
                                      concat_segments       => l_new_concat_segments
                                     );

                     IF NOT l_valid_result
                     THEN
                        lc_err_msg := fnd_flex_keyval.error_message;
                     ELSE
                        l_new_aff_ccid := fnd_flex_keyval.combination_id;

                        IF (l_new_aff_ccid = -1)
                        THEN
                           lc_err_msg :=
                                 'Invalid account combination: '
                              || l_new_concat_segments;
                           lc_error_flag := 'Y';
                        ELSE
                           lc_err_msg := l_new_aff_ccid;
                           lr_ap_invoice_lines_interface.dist_code_combination_id :=
                                                               l_new_aff_ccid;
                        END IF;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        lc_error_flag := 'Y';
                        lc_error_loc := 'GL code combination not defined:';
                        fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                        fnd_message.set_token ('ERR_LOC', lc_error_loc);
                        fnd_message.set_token ('ERR_ORA', SQLERRM);
                        lc_err_msg := fnd_message.get;
                        fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                        xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Debit to Bank Vendor'
                                 );
                  END;

                  lr_ap_invoice_lines_interface.invoice_id :=
                                           lr_ap_invoices_interface.invoice_id;
                  lr_ap_invoice_lines_interface.line_number := ln_b_line_num;
                  lr_ap_invoice_lines_interface.line_type_lookup_code :=
                                                                        'ITEM';
                  lr_ap_invoice_lines_interface.amount :=
                                                 lcu_b_inv_lines.bundle_amount;
                  lr_ap_invoice_lines_interface.accounting_date := ld_date;
                  lr_ap_invoice_lines_interface.description :=
                                                   lcu_b_inv_lines.vendor_name;
                  lr_ap_invoice_lines_interface.org_id :=
                                               lr_ap_invoices_interface.org_id;
                  lr_ap_invoice_lines_interface.creation_date :=
                                        lr_ap_invoices_interface.creation_date;
                  lr_ap_invoice_lines_interface.created_by :=
                                           lr_ap_invoices_interface.created_by;
                  lr_ap_invoice_lines_interface.last_update_date :=
                                     lr_ap_invoices_interface.last_update_date;
                  lr_ap_invoice_lines_interface.last_updated_by :=
                                      lr_ap_invoices_interface.last_updated_by;
                  lr_ap_invoice_lines_interface.last_update_login :=
                                    lr_ap_invoices_interface.last_update_login;

                  IF (lc_error_flag = 'N')
                  THEN
                     fnd_file.put_line (fnd_file.LOG,
                                        '                               '
                                       );
                     fnd_file.put_line
                           (fnd_file.LOG,
                            'Inserting into ap_invoice_lines_interface table.'
                           );

                     BEGIN
                        INSERT INTO apps.ap_invoice_lines_interface
                             VALUES lr_ap_invoice_lines_interface;

                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           lc_error_flag := 'Y';
                           lc_error_loc := 'unable to insert:';
                           fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
                           fnd_message.set_token ('ERR_LOC', lc_error_loc);
                           fnd_message.set_token ('ERR_ORA', SQLERRM);
                           lc_err_msg := fnd_message.get;
                           fnd_file.put_line (fnd_file.LOG, lc_err_msg);
                           xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => lc_shor_name,
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || lc_error_loc,
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Debit to Bank Vendor'
                                 );
                     END;
                  END IF;
               END;                             -- End for lines Debit to Bank
            END LOOP;                                     -- END for line loop
         END IF;
      END LOOP;                                        -- Header Bank end loop

      IF (lc_error_flag = 'N')
      THEN
         -- Submitting the Payables Open Interface Program.
         fnd_file.put_line (fnd_file.output, 'Starting Imports...');
         /* Submit the 'Payables Open Interface Import' process */  -- defect 2917
         ln_req_id :=
            fnd_request.submit_request ('SQLAP',
                                        'APXIIMPT',
                                        NULL,
                                        NULL,
                                        FALSE,
                                        'US_OD_SCR',
                                        NULL,
                                        'N/A',
                                        NULL,
                                        NULL,
                                        NULL,
                                        'N',
                                        'N',
                                        'N',
                                        'N',
                                        1000,
                                        fnd_global.user_id,
                                        fnd_global.login_id
                                       );
         /* Start the request */
         COMMIT;

         IF ln_req_id = 0
         THEN
            fnd_file.put_line
               (fnd_file.LOG,
                'Error submitting request for ''Payables Open Interface Import for US_OD_SCR''.'
               );
         ELSE
            fnd_file.put_line
                         (fnd_file.output,
                             'Started ''Payables Open Interface Import for US_OD_SCR'' at '
                          || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                         );
            fnd_file.put_line (fnd_file.output, ' ');
            lc_req_status :=
               fnd_concurrent.wait_for_request (ln_req_id       -- request_id
                                                ,30                 -- interval
                                                ,360000             -- max_wait
                                                ,lc_phase              -- phase
                                                ,lc_reqstatus         -- status
                                                ,lc_devphase       -- dev_phase
                                                ,lc_devstatus     -- dev_status
                                                ,lc_message          -- message
                                               );

                  /* Mark the SCR batch as Bundled */
                  UPDATE xxfin.xx_ap_scr_headers_all
                   SET scr_action = 'B'
                 WHERE batch_id = p_batch_id
                   AND scr_action = 'S';

               /* Submit the OD: AP SCR Bundle Report */
               ln_req_id2 :=
               fnd_request.submit_request ('XXFIN',
                                           'XXAPSCR3',
                                           NULL,
                                           NULL,
                                           FALSE,
                                           'B',
                                           p_batch_id
                                          );
             /* Start the request */
             COMMIT;
           IF (ln_req_id2 = 0) THEN
            fnd_file.put_line
                    (fnd_file.LOG, 'Error submitting request for ''OD: AP SCR Bundle Report''.');
            lc_error_loc := 'Error submitting request for OD: AP SCR Bundle Report';
           ELSE
            fnd_file.put_line (fnd_file.output, 'Started ''OD: AP SCR Bundle Report'' at '
                               || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'                                     )
                              );
            fnd_file.put_line (fnd_file.output, ' ');
            lc_req_status :=
            fnd_concurrent.wait_for_request (ln_req_id       -- request_id
                                             ,30                 -- interval
                                             ,360000             -- max_wait
                                             ,lc_phase              -- phase
                                             ,lc_reqstatus         -- status
                                             ,lc_devphase       -- dev_phase
                                             ,lc_devstatus     -- dev_status
                                             ,lc_message          -- message
                                            );
              /* Submitting the Promissory Note Process. */
              fnd_file.put_line (fnd_file.output, 'Starting OD: Ap Suntrust Promissory Notes Process...');
             /* Submit the 'SunTruse Promossory Notes process */
            ln_req_id3 :=
            fnd_request.submit_request ('XXFIN',
                                        'XXAPSTPN',
                                        NULL,
                                        NULL,
                                        FALSE,
                                        p_batch_id
                                       );
             /* Start the request */
             COMMIT;
             IF (ln_req_id3 = 0) then
              fnd_file.put_line
                    (fnd_file.LOG, 'Error submitting request for ''OD: Ap Suntrust Promissory Notes Process''.');
              lc_error_loc := 'Error submitting request for OD: AP SCR Report';
             ELSE
             fnd_file.put_line (fnd_file.output, 'Started ''OD: Ap Suntrust Promissory Notes Process'' at '
                               || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'                                     )
                              );
             fnd_file.put_line (fnd_file.output, ' ');
             END IF;
           END IF;

         END IF;
      END IF;

    FOR lcu_bundled_inv IN c_bundled_inv (p_batch_id) LOOP
    UPDATE apps.ap_invoices_all
      SET  payment_method_lookup_code ='CLEARING'
           ,pay_group_lookup_code = 'US_OD_SCR_CLEARING'
           ,terms_id = (select term_id from ap_terms  where name = '00')
           ,terms_date = sysdate -- Defect 2832
     WHERE invoice_id = lcu_bundled_inv.invoice_id;
     COMMIT;
-- Defect 2832
     UPDATE apps.ap_payment_schedules
      SET due_date = sysdate,
          payment_method_lookup_code ='CLEARING'    -- defect 2914
      WHERE invoice_id = lcu_bundled_inv.invoice_id;
     COMMIT;


    END LOOP;
   END bundle_process;

-- +===================================================================+
-- |         Name : PROMISSORY NOTE for SUNTRUST BANK                  |
-- | Description : To create the Promissory Notes for SunTrust Bank    |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE st_pro_note_h (p_batch_id IN NUMBER)
   IS
      CURSOR lcu_main
      IS
      SELECT pv.segment1  segment1
             ,hdr.vendor_name  vendor_name
             ,hdr.batch_id batch_id
             ,hdr.weighted_date weighted_date
             ,hdr.bundle_amount bundle_amount
       FROM xxfin.xx_ap_scr_headers_all hdr
            ,apps.po_vendor_sites_all vs
            ,apps.po_vendors  pv
      WHERE hdr.vendor_site_id = vs.vendor_site_id
        AND pv.vendor_id = vs.vendor_id
        AND hdr.scr_action = 'B'
        AND hdr.batch_id = p_batch_id;

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_fieldSeprator   VARCHAR2(2000) := '|';
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)                   := 'dra_OD_'||p_batch_id|| '.txt';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
   BEGIN

      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP


         SELECT    'Office Depot'
                || lc_fieldSeprator
                || rcu_main.segment1
                || lc_fieldSeprator
                || rcu_main.vendor_name
                || lc_fieldSeprator
                || rcu_main.batch_id||'-'||rcu_main.segment1
                || lc_fieldSeprator
                || to_char(sysdate,'mm/dd/rrrr')
                || lc_fieldSeprator
                || to_char(rcu_main.weighted_date,'mm/dd/rrrr')
                || lc_fieldSeprator
                || to_char(rcu_main.bundle_amount,'9999999999.99')
                || lc_fieldSeprator
                || to_char(sysdate,'mm/dd/rrrr')
                || CHR(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);

        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                          ,'XXCOMFILCOPY'
                      ,''
                          ,''
                       ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/' || lc_filename
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
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Error submitting request for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPSTPN',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'ST_PRO_NOTE_H'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPSTPN',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'ST_PRO_NOTE_H'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END st_pro_note_h;


   PROCEDURE st_pro_note_d (p_batch_id IN NUMBER)
   IS
      CURSOR lcu_main
      IS
      SELECT  hdr.batch_id  batch_id
              ,pv.segment1   segment1
              ,hdr.vendor_name vendor_name
              ,lines.invoice_num invoice_num
              ,ai.invoice_date  invoice_date
              ,hdr.weighted_date weighted_date
              ,(lines.invoice_amount-nvl(lines.discount_amount,0)) net_amount
from xxfin.xx_ap_scr_headers_all hdr
     ,xxfin.xx_ap_scr_lines_all  lines
     ,apps.po_vendor_sites_all vs
     ,apps.po_vendors  pv
     ,apps.ap_invoices_all ai
where lines.header_id = hdr.header_id
and   hdr.vendor_site_id = vs.vendor_site_id
and   pv.vendor_id = vs.vendor_id
and   lines.invoice_id = ai.invoice_id
and   lines.reserve_flag = 'N'
and   hdr.scr_action = 'B'
and   hdr.batch_id = p_batch_id
order by hdr.header_id;

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (2000);
      lc_errbuf          VARCHAR2 (200)                   := NULL;
      lc_retcode         VARCHAR2 (25)                    := NULL;
      lc_dirpath         VARCHAR2 (2000)                  := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200)              := 'inv_OD_'||p_batch_id|| '.txt';
      lc_fieldSeprator   VARCHAR2(2000) := '|';
      lr_main            lcu_main%ROWTYPE;
      ln_vendor          NUMBER;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lr_target          xx_fin_translatevalues%ROWTYPE;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
   BEGIN

      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_main IN lcu_main
      LOOP


         SELECT    'Office Depot'
                || lc_fieldSeprator
                || rcu_main.batch_id||'-'||rcu_main.segment1
                || lc_fieldSeprator
                || rcu_main.segment1
                || lc_fieldSeprator
                || rcu_main.vendor_name
                || lc_fieldSeprator
                || rcu_main.invoice_num
                || lc_fieldSeprator
                || rcu_main.invoice_date
                || lc_fieldSeprator
                || to_char(rcu_main.weighted_date,'mm/dd/rrrr')
                || lc_fieldSeprator
                || rcu_main.net_amount
                || lc_fieldSeprator
                || to_char(sysdate,'mm/dd/rrrr')
                || CHR(13)
           INTO lc_recordstr
           FROM DUAL;

         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);

        ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                         ('XXFIN'
                          ,'XXCOMFILCOPY'
                      ,''
                          ,''
                       ,FALSE
                                           ,'$CUSTOM_DATA/xxfin/outbound/'|| lc_filename
                                           ,'$CUSTOM_DATA/xxfin/ftp/out/' || lc_filename
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
         fnd_file.put_line
                         (fnd_file.LOG,
                          'Error submitting request for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                       (p_program_type                => 'CONCURRENT PROGRAM',
                        p_program_name                => 'XXAPSTPN',
                        p_program_id                  => fnd_global.conc_program_id,
                        p_module_name                 => 'AP',
                        p_error_location              => 'Error at Submitting XXCOMFILCOPY',
                        p_error_message_count         => 1,
                        p_error_message_code          => 'E',
                        p_error_message               => lc_err_msg,
                        p_error_message_severity      => 'Major',
                        p_notify_flag                 => 'N',
                        p_object_type                 => 'ST_PRO_NOTE_D'
                       );
      ELSE
         fnd_file.put_line (fnd_file.output,
                               'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPSTPN',
                                  p_program_id                  => fnd_global.conc_program_id,
                                  p_module_name                 => 'AP',
                                  p_error_location              => 'Error ',
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'ST_PRO_NOTE_D'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END st_pro_note_d;
 PROCEDURE ST_PROMISSORY_NOTE ( p_errbuf  VARCHAR2
                               ,p_retcode VARCHAR2
                               ,p_batch_id IN NUMBER )
 IS
 BEGIN
       fnd_file.put_line (fnd_file.LOG,
                         'Starting SunTrust Promissory Note Header interface...'
                        );
       st_pro_note_h(p_batch_id);
       fnd_file.put_line (fnd_file.LOG,
                         'Starting SunTrust Promissory Note Details interface...'
                        );
       st_pro_note_d(p_batch_id);
 END ST_PROMISSORY_NOTE;
END xx_ap_scr_pkg;
/