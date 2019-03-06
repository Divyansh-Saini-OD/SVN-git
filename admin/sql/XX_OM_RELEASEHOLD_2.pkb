/* Formatted on 2012/10/05 00:51 (Formatter Plus v4.8.8) */
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET server output on;

CREATE OR REPLACE PACKAGE BODY xx_om_releasehold_2
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_RELEASEHOLD (XX_OM_RELEASEHOLD.PKS)                       |
-- | Description      : This Program is designed to release HOLDS,           |
-- |                    OD: SAS Pending deposit hold and                     |
-- |                    OD: Payment Processing Failure as an activity after  |
-- |                    Post production                                      |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks        Description         |
-- |======= =========== =============     ===========   ===============      |
-- |DRAFT1A 20-JUL-12   Oracle AMS Team   Initial draft version              |
-- |                                                                         |
-- | 0.1  04-OCT-12   Oracle AMS Team     Defect # 20464   IF SO Type is POS |
-- |                                                                         |
-- |   and data is there in the ORDT then setting the p_return_status to S . |
-- +=========================================================================+

   -- Master Concurrent Program
   PROCEDURE xx_main_procedure (
      x_retcode             OUT NOCOPY      NUMBER,
      x_errbuf              OUT NOCOPY      VARCHAR2,
      p_order_number_from   IN              NUMBER,
      p_order_number_to     IN              NUMBER,
      p_date_from           IN              VARCHAR2,
      p_date_to             IN              VARCHAR2,
      p_sas_hold_param      IN              VARCHAR2,
      p_ppf_hold_param      IN              VARCHAR2,
      p_debug_flag          IN              VARCHAR2
   )
   AS
-- +=====================================================================+
-- | Name  : XX_MAIN_PROCEDURE                                           |
-- | Description     : The Main procedure to determine which Hold is to  |
-- |                   be released,OD: SAS Pending deposit hold or       |
-- |                   OD: Payment Processing Failure or both            |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_SAS_HOLD_param    IN ->Flag of Y/N              |
-- |                   p_PPF_HOLD_param    IN ->Flag of Y/N              |
-- |                   x_retcode           OUT                           |
-- |                   x_errbuf            OUT                           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
      g_resp_id        NUMBER;
      g_resp_appl_id   NUMBER;
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', 'Start of prgram::: ');
         put_log_line (p_debug_flag,
                       'N',
                       'Calling XX_MAIN_PROCEDURE -- main procedure '
                      );
      END IF;

      IF (p_sas_hold_param = 'Y')
      THEN
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag,
                          'N',
                          'Calling xx_om_sas_depo_release procedure '
                         );
         END IF;

         xx_om_sas_depo_release (p_order_number_from,
                                 p_order_number_to,
                                 p_date_from,
                                 p_date_to,
                                 p_debug_flag
                                );
      ELSE
         NULL;
      END IF;

      IF (p_ppf_hold_param = 'Y')
      THEN
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag,
                          'N',
                          'Calling xx_om_ppf_hold_release procedure '
                         );
         END IF;

         xx_om_ppf_hold_release (p_order_number_from,
                                 p_order_number_to,
                                 p_date_from,
                                 p_date_to,
                                 p_debug_flag
                                );
      ELSE
         NULL;
      END IF;
   END xx_main_procedure;

-- +============================================================================+
-- | Name             :  PUT_LOG_LINE                                           |
-- | Description      :  This procedure will print log messages.                |
-- | Parameters       :  p_debug  IN   -> Debug Flag - Default N.               |
-- |                  :  p_force  IN  -> Default Log - Default N                |
-- |                  :  p_buffer IN  -> Log Message.                           |
-- +============================================================================+
   PROCEDURE put_log_line (
      p_debug_flag   IN   VARCHAR2 DEFAULT 'N',
      p_force        IN   VARCHAR2 DEFAULT 'N',
      p_buffer       IN   VARCHAR2 DEFAULT ' '
   )
   AS
   BEGIN
      IF (p_debug_flag = 'Y' OR p_force = 'Y')
      THEN
         -- IF called from a concurrent program THEN print into log file
         IF (fnd_global.conc_request_id > 0)
         THEN
            fnd_file.put_line (fnd_file.LOG, NVL (p_buffer, ' '));
         -- ELSE print on console
         ELSE
            DBMS_OUTPUT.put_line (SUBSTR (NVL (p_buffer, ' '), 1, 300));
         END IF;
      END IF;
   END put_log_line;

-- +============================================================================+
-- | Name             :  XX_CREATE_PREPAY_RECEIPT                               |
-- |                                                                            |
-- | Description      :  This procedure will create AR Receipt (with Prepayment |
-- |                     Application) based on the data present in oe_payments  |
-- |                     and oe_order_headers_all tables.                       |
-- | Parameters       :  p_header_id        IN ->  Order Header ID for which    |
-- |                     prepayment receipt need to be created.                 |
-- |                  :  p_debug_flag       IN ->     By default it will be Y.  |
-- |                  :  p_return_status    OUT->         S=Success, F=Failure  |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version Date        Author            Remarks             Descripition      |
-- |======= =========== =============     ================  ==============      |
-- | 0.1  04-OCT-12   Oracle AMS Team     Defect # 20464     IF SO Type is POS  |
-- |                                                                            |
-- |   and data is there in the ORDT then setting the p_return_status to S .    |
-- +============================================================================+
   PROCEDURE xx_create_prepay_receipt (
      p_header_id       IN       NUMBER,
      p_debug_flag      IN       VARCHAR2 DEFAULT 'Y',
      p_return_status   OUT      VARCHAR2
   )
   AS
      CURSOR lcu_payments
      IS
         SELECT   h.header_id, i.payment_type_code, i.credit_card_code,
                  i.credit_card_number, i.credit_card_holder_name,
                  i.credit_card_expiration_date, i.credit_card_approval_code,
                  i.credit_card_approval_date, i.check_number,
                  i.prepaid_amount, i.payment_amount, i.orig_sys_payment_ref,
                  i.payment_number, i.receipt_method_id,
                  h.transactional_curr_code, h.sold_to_org_id,
                  h.invoice_to_org_id, i.payment_set_id, h.order_number,
                  i.CONTEXT, i.attribute6, i.attribute7, i.attribute8,
                  i.attribute9, i.attribute10, i.attribute11, i.attribute12,
                  i.attribute13, i.attribute15, h.ship_from_org_id,
                  ha.paid_at_store_id, h.orig_sys_document_ref,
                  i.tangible_id, h.ordered_date receipt_date
             FROM apps.oe_payments i,
                  apps.oe_order_headers_all h,
                  apps.xx_om_header_attributes_all ha
            WHERE h.header_id = i.header_id
              AND ha.header_id = h.header_id
              AND i.attribute15 IS NULL
              AND h.header_id = p_header_id
         ORDER BY h.header_id, i.payment_number;

      TYPE t_pay_tab IS TABLE OF lcu_payments%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_pay_tab                       t_pay_tab;
      lc_so_type                      VARCHAR2 (100)                   := NULL;
                                                   -- Added for Defect # 20464
      ln_so_header_id                 NUMBER                           := NULL;
                                                   -- Added for Defect # 20464
      ln_user                         NUMBER                           := NULL;
      lc_timestamp                    VARCHAR2 (30)                    := NULL;
      lc_print_header                 VARCHAR2 (300)                   := NULL;
      lc_print_line                   VARCHAR2 (300)                   := NULL;
      ln_ps_id                        NUMBER;
      ln_cr_id                        NUMBER;
      ln_trx_id                       NUMBER;
      lc_tan_id                       VARCHAR2 (100);
      l_xx_cr_pay_pgm_name            VARCHAR2 (30)                 := 'XXTBD';
      ln_msg_count                    NUMBER;
      lc_status                       VARCHAR2 (1);
      lc_return_status                VARCHAR2 (1);
      lc_msg_data                     VARCHAR2 (2000);
      ln_rec_appl_id                  NUMBER;
      ln_remittance_bank_account_id   NUMBER;
      ln_payment_server_order_num     NUMBER;
      ln_sec_application_ref_id       NUMBER;
      ln_curr_pay_set_id              NUMBER;
      ln_app_ref_id                   NUMBER;
      lc_pay_response_error_code      VARCHAR2 (80);
      lc_approval_code                VARCHAR2 (120);
      lc_app_ref_num                  VARCHAR2 (80);
      ln_receipt_number               ar_cash_receipts.receipt_number%TYPE;
      ln_cash_receipt_id              ar_cash_receipts.cash_receipt_id%TYPE;
      lc_receipt_comments             ar_cash_receipts.comments%TYPE;
      lc_customer_receipt_reference   ar_cash_receipts.customer_receipt_reference%TYPE;
      lc_app_customer_reference       ar_receivable_applications.customer_reference%TYPE;
      lc_app_comments                 ar_receivable_applications.comments%TYPE;
      lc_order_source                 oe_order_sources.NAME%TYPE;
      l_auth_attr_rec                 xx_ar_cash_receipts_ext%ROWTYPE;
      l_app_attribute_rec             ar_receipt_api_pub.attribute_rec_type;
      l_attribute_rec                 ar_receipt_api_pub.attribute_rec_type;
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
        INTO lc_timestamp
        FROM DUAL;

      -- g_user_id is passed as a global variable
      ln_user := g_user_id;
      put_log_line (p_debug_flag, 'Y', ' ');
      put_log_line (p_debug_flag,
                    'Y',
                    'Begining of XX_CREATE_PREPAY_RECEIPT Procedure'
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'Processing starts at : ' || lc_timestamp
                   );
      put_log_line (p_debug_flag, 'Y', ' ');
      put_log_line (p_debug_flag, 'Y', 'Parameters : ');
      put_log_line (p_debug_flag, 'Y', 'p_header_id     : ' || p_header_id);
      put_log_line (p_debug_flag, 'Y', 'p_debug_flag    : ' || p_debug_flag);

      OPEN lcu_payments;

      FETCH lcu_payments
      BULK COLLECT INTO l_pay_tab;

      CLOSE lcu_payments;

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', ' ');
         put_log_line (p_debug_flag,
                       'N',
                       'Total Number of Records : ' || l_pay_tab.COUNT
                      );
         put_log_line (p_debug_flag, 'N', ' ');
      END IF;

      IF (l_pay_tab.COUNT > 0)
      THEN
         IF p_debug_flag = 'Y'
         THEN
            lc_print_header :=
                  RPAD ('ORDER_NUMBER', 20, ' ')
               || RPAD ('RECEIPT_DATE', 20, ' ')
               || RPAD ('RECEIPT_AMOUNT', 20, ' ')
               || RPAD ('RECEIPT_NUMBER', 20, ' ')
               || RPAD ('CASH_RECEIPT_ID', 20, ' ')
               || RPAD ('PAYMENT_SET_ID', 20, ' ')
               || RPAD ('API STATUS', 15, ' ')
               || RPAD ('RETURN STATUS', 15, ' ')
               || RPAD ('MSG_COUNT', 15, ' ')
               || RPAD ('MSG_DATA', 120, ' ');
         END IF;

         FOR i_index IN l_pay_tab.FIRST .. l_pay_tab.LAST
         LOOP
            -- Resetting variables
            lc_so_type := NULL;                   -- Added for Defect # 20464
            ln_so_header_id := NULL;              -- Added for Defect # 20464
            lc_status := NULL;
            ln_msg_count := NULL;
            lc_msg_data := NULL;
            ln_ps_id := NULL;
            ln_cr_id := NULL;
            ln_trx_id := NULL;
            lc_tan_id := NULL;
            ln_rec_appl_id := NULL;
            ln_remittance_bank_account_id := NULL;
            ln_payment_server_order_num := NULL;
            ln_sec_application_ref_id := NULL;
            ln_curr_pay_set_id := NULL;
            ln_app_ref_id := NULL;
            lc_pay_response_error_code := NULL;
            lc_approval_code := NULL;
            lc_app_ref_num := NULL;
            ln_receipt_number := NULL;
            ln_cash_receipt_id := NULL;
            lc_receipt_comments := NULL;
            lc_customer_receipt_reference := NULL;
            lc_app_customer_reference := NULL;
            lc_app_comments := NULL;
            lc_order_source := NULL;
            l_auth_attr_rec := NULL;
            l_app_attribute_rec := NULL;
            l_attribute_rec := NULL;

            -- Added for Defect # 20464

            --Getting Sales Order type to know whether it is AOPS or POS
            BEGIN
               SELECT ot.NAME
                 INTO lc_so_type
                 FROM apps.oe_order_headers_all h,
                      apps.oe_order_lines_all l,
                      apps.oe_transaction_types_tl ot
                WHERE 1 = 1
                  AND h.header_id = l.header_id
                  AND l.line_type_id = ot.transaction_type_id
                  AND h.header_id = l_pay_tab (i_index).header_id
                  AND ot.NAME IN
                         ('OD CA POS STANDARD - LINE',
                          'OD US POS STANDARD - LINE',
                          'OD CA STANDARD - LINE',
                          'OD US STANDARD - LINE'
                         )
                  AND ROWNUM = 1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lc_so_type := NULL;
            END;

            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag,
                             'N',
                             'Sales Order Type :  ' || lc_so_type
                            );
            END IF;

            -- Chekcing If the Sales Order is AOPS  or not.
            -- IF condition is added for Defect # 20464
            IF (   lc_so_type = 'OD CA STANDARD - LINE'
                OR lc_so_type = 'OD US STANDARD - LINE'
               )
            THEN
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag,
                                'N',
                                'Sales Order Type is AOPS :  ' || lc_so_type
                               );
                  put_log_line
                     (p_debug_flag,
                      'N',
                      'Sales Order Type is AOPS So going to Create Prepayment Receipt'
                     );
               END IF;

               BEGIN
                  -- Setting Receipt Attributes
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Processing Order Number : '
                                   || l_pay_tab (i_index).orig_sys_document_ref
                                  );
                     put_log_line
                        (p_debug_flag,
                         'N',
                         'Calling XX_AR_PREPAYMENTS_PKG.SET_RECEIPT_ATTR_REFERENCES'
                        );
                  END IF;

                  xx_ar_prepayments_pkg.set_receipt_attr_references
                     (p_receipt_context                 => 'SALES_ACCT',
                      p_orig_sys_document_ref           => l_pay_tab (i_index).orig_sys_document_ref,
                      p_receipt_method_id               => l_pay_tab (i_index).receipt_method_id,
                      p_payment_type_code               => l_pay_tab (i_index).payment_type_code,
                      p_check_number                    => l_pay_tab (i_index).check_number,
                      p_paid_at_store_id                => l_pay_tab (i_index).paid_at_store_id,
                      p_ship_from_org_id                => l_pay_tab (i_index).ship_from_org_id,
                      p_cc_auth_manual                  => l_pay_tab (i_index).attribute6,
                      p_cc_auth_ps2000                  => l_pay_tab (i_index).attribute8,
                      p_merchant_number                 => l_pay_tab (i_index).attribute7,
                      p_od_payment_type                 => l_pay_tab (i_index).attribute11,
                      p_debit_card_approval_ref         => l_pay_tab (i_index).attribute12,
                      p_cc_mask_number                  => l_pay_tab (i_index).attribute10,
                      p_payment_amount                  => l_pay_tab (i_index).payment_amount,
                      p_called_from                     => 'HVOP',
                      p_additional_auth_codes           => l_pay_tab (i_index).attribute13,
                      x_receipt_number                  => ln_receipt_number,
                      x_receipt_comments                => lc_receipt_comments,
                      x_customer_receipt_reference      => lc_customer_receipt_reference,
                      x_attribute_rec                   => l_attribute_rec,
                      x_app_customer_reference          => lc_app_customer_reference,
                      x_app_comments                    => lc_app_comments,
                      x_app_attribute_rec               => l_app_attribute_rec,
                      x_receipt_ext_attributes          => l_auth_attr_rec
                     );

                  -- Creating Prepayment Receipt
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line
                           (p_debug_flag,
                            'N',
                            'Calling XX_AR_PREPAYMENTS_PKG.CREATE_PREPAYMENT'
                           );
                  END IF;

                  xx_ar_prepayments_pkg.create_prepayment
                     (p_api_version                       => 1.0,
                      p_init_msg_list                     => fnd_api.g_false,
                      p_commit                            => fnd_api.g_false,
                      p_validation_level                  => fnd_api.g_valid_level_full,
                      x_return_status                     => lc_return_status,
                      x_msg_count                         => ln_msg_count,
                      x_msg_data                          => lc_msg_data,
                      p_receipt_method_id                 => l_pay_tab
                                                                      (i_index).receipt_method_id,
                      p_currency_code                     => l_pay_tab
                                                                      (i_index).transactional_curr_code,
                      p_amount                            => l_pay_tab
                                                                      (i_index).payment_amount,
                      p_customer_id                       => l_pay_tab
                                                                      (i_index).sold_to_org_id,
                      p_customer_site_use_id              => l_pay_tab
                                                                      (i_index).invoice_to_org_id,
                      p_customer_receipt_reference        => lc_customer_receipt_reference,
                      p_attribute_rec                     => l_attribute_rec,
                      p_called_from                       => 'HVOP',
                      p_receipt_comments                  => lc_receipt_comments,
                      p_app_attribute_rec                 => l_app_attribute_rec,
                      p_app_comments                      => lc_app_comments,
                      p_app_customer_reference            => lc_app_customer_reference,
                      p_application_ref_type              => 'OM',
                      p_application_ref_id                => ln_app_ref_id,
                      p_application_ref_num               => lc_app_ref_num,
                      p_secondary_application_ref_id      => ln_sec_application_ref_id,
                      p_credit_card_code                  => l_pay_tab
                                                                      (i_index).credit_card_code,
                      p_credit_card_number                => l_pay_tab
                                                                      (i_index).credit_card_number,
                      p_credit_card_holder_name           => l_pay_tab
                                                                      (i_index).credit_card_holder_name,
                      p_credit_card_expiration_date       => l_pay_tab
                                                                      (i_index).credit_card_expiration_date,
                      p_credit_card_approval_code         => l_pay_tab
                                                                      (i_index).credit_card_approval_code,
                      p_credit_card_approval_date         => l_pay_tab
                                                                      (i_index).credit_card_approval_date,
                      p_sas_sale_date                     => l_pay_tab
                                                                      (i_index).receipt_date,
                      p_receipt_ext_attributes            => l_auth_attr_rec,
                      p_payment_number                    => l_pay_tab
                                                                      (i_index).payment_number,
                      x_payment_set_id                    => ln_ps_id,
                      x_cash_receipt_id                   => ln_cr_id,
                      x_receipt_number                    => ln_receipt_number,
                      x_payment_server_order_num          => lc_tan_id,
                      x_payment_response_error_code       => lc_pay_response_error_code
                     );

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag,
                                   'N',
                                   'API Return Status : ' || lc_return_status
                                  );
                  END IF;

                  -- If API Return Status is S
                  IF lc_return_status = 'S'
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Updating XX_AR_ORDER_RECEIPT_DTL'
                                     );
                     END IF;

                     UPDATE apps.xx_ar_order_receipt_dtl
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            cash_receipt_id = ln_cr_id,
                            receipt_number = ln_receipt_number,
                            payment_set_id = ln_ps_id
                      WHERE header_id = l_pay_tab (i_index).header_id;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Updating OE_PAYMENTS'
                                     );
                     END IF;

                     UPDATE apps.oe_payments
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            attribute15 = ln_cr_id,
                            payment_set_id = ln_ps_id,
                            tangible_id = lc_tan_id
                      WHERE header_id = l_pay_tab (i_index).header_id;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line
                                   (p_debug_flag,
                                    'N',
                                    'Updating AR_RECEIVABLE_APPLICATIONS_ALL'
                                   );
                     END IF;

                     UPDATE /*+ INDEX(ar_receivable_applications_all ar_receivable_applications_n1) */apps.ar_receivable_applications_all
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            payment_set_id = ln_ps_id,
                            application_ref_num =
                                              l_pay_tab (i_index).order_number,
                            application_ref_id = l_pay_tab (i_index).header_id
                      WHERE display = 'Y'
                        AND cash_receipt_id = ln_cr_id
                        AND applied_payment_schedule_id = -7;

                     lc_status := 'S';

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag,
                                      'N',
                                      'After Update Status : ' || lc_status
                                     );
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_status := lc_status;
                     lc_msg_data :=
                           lc_msg_data
                        || ' | API Return Status : '
                        || lc_return_status
                        || ' | After Update Status : '
                        || lc_status
                        || ' | '
                        || SQLERRM;
                     put_log_line (p_debug_flag, 'Y', ' ');
                     put_log_line (p_debug_flag,
                                   'Y',
                                   'EXCEPTION | ' || SQLERRM
                                  );
                     put_log_line (p_debug_flag, 'Y', ' ');
                     xx_com_error_log_pub.log_error
                        (p_program_type                => 'CONCURRENT PROGRAM',
                         p_program_name                => l_xx_cr_pay_pgm_name,
                         p_module_name                 => 'AR',
                         p_error_location              => 'Error while creating receipts - API',
                         p_error_message_count         => 1,
                         p_error_message_code          => 'E',
                         p_error_message               => lc_msg_data,
                         p_error_message_severity      => 'Major',
                         p_notify_flag                 => 'N',
                         p_object_type                 => 'Creating Prepayment Receipts'
                        );
               END;

               IF p_debug_flag = 'Y'
               THEN
                  lc_print_line :=
                        RPAD (l_pay_tab (i_index).order_number, 20, ' ')
                     || RPAD (l_pay_tab (i_index).receipt_date, 20, ' ')
                     || RPAD (l_pay_tab (i_index).payment_amount, 20, ' ')
                     || RPAD (ln_receipt_number, 20, ' ')
                     || RPAD (ln_cr_id, 20, ' ')
                     || RPAD (ln_ps_id, 20, ' ')
                     || RPAD (lc_return_status, 15, ' ')
                     || RPAD (lc_status, 15, ' ')
                     || RPAD (ln_msg_count, 15, ' ')
                     || RPAD (SUBSTR (lc_msg_data, 1, 120), 120, ' ');
               END IF;

               IF lc_status = 'S'
               THEN
                  p_return_status := lc_status;
                  COMMIT;

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', 'Executed COMMIT');
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag, 'N', lc_print_header);
                     put_log_line (p_debug_flag, 'N', lc_print_line);
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  put_log_line (p_debug_flag,
                                'Y',
                                'p_return_status : ' || p_return_status
                               );
                  put_log_line (p_debug_flag, 'Y', ' ');
               ELSE
                  p_return_status := 'F';

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag, 'N', lc_print_header);
                     put_log_line (p_debug_flag, 'N', lc_print_line);
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  put_log_line (p_debug_flag,
                                'Y',
                                'p_return_status : ' || p_return_status
                               );
                  put_log_line (p_debug_flag, 'Y', ' ');
               END IF;
             -- IF Else part for the Defect # 20464
            -- Going to check Sales Order is POS Order or not
            ELSIF (   lc_so_type = 'OD CA POS STANDARD - LINE'
                   OR lc_so_type = 'OD US POS STANDARD - LINE'
                  )
            THEN
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag,
                                'N',
                                'Sales Order Type is POS :  ' || lc_so_type
                               );
                  put_log_line
                     (p_debug_flag,
                      'N',
                      'Sales Order Type is POS So going to Check for this Sales Order, data is exists or not in ORDT table: '
                     );
               END IF;

               BEGIN
                  SELECT ordt.header_id
                    INTO ln_so_header_id
                    FROM apps.xx_ar_order_receipt_dtl ordt
                   WHERE 1 = 1
                     AND ordt.header_id = l_pay_tab (i_index).header_id
                     AND ordt.order_source = 'POE'
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     ln_so_header_id := NULL;
               END;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag,
                                'N',
                                   'The Value of ln_so_header_id :  '
                                || ln_so_header_id
                               );
                  put_log_line
                     (p_debug_flag,
                      'N',
                      'If the value of ln_so_header_id is not null for this Sales Order that means data is exists in ORDT table: '
                     );
               END IF;

               IF ln_so_header_id IS NOT NULL
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line
                            (p_debug_flag,
                             'N',
                                'The Value of ln_so_header_id is not NULL:  '
                             || ln_so_header_id
                            );
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Data is there for this Header ID :  '
                                   || l_pay_tab (i_index).header_id
                                   || ' in the table ORDT: '
                                  );
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Going to set p_return_status= S '
                                  );
                  END IF;

                  p_return_status := 'S';
               ELSE
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line
                               (p_debug_flag,
                                'N',
                                   'The Value of ln_so_header_id is  NULL:  '
                                ||ln_so_header_id
                               );
                     put_log_line
                                (p_debug_flag,
                                 'N',
                                    'Data is not there for this Header ID :  '
                                 || l_pay_tab (i_index).header_id
                                 || ' in the table ORDT: '
                                );
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Going to set p_return_status= F '
                                  );
                  END IF;

                  p_return_status := 'F';
               END IF;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag,
                                'N',
                                   'Finally p_return_status  =   '
                                || p_return_status
                               );
               END IF;
            END IF;                                --- End IF for Defect 20464
         END LOOP;
      END IF;

      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
        INTO lc_timestamp
        FROM DUAL;

      put_log_line (p_debug_flag,
                    'Y',
                    'Processing ends at   : ' || lc_timestamp
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'End of XX_CREATE_PREPAY_RECEIPT Procedure'
                   );
      put_log_line (p_debug_flag, 'Y', ' ');
   EXCEPTION
      WHEN OTHERS
      THEN
         put_log_line (p_debug_flag, 'Y', ' ');
         put_log_line (p_debug_flag, 'Y', 'ERROR | ' || SQLERRM);
         put_log_line (p_debug_flag, 'Y', ' ');
         xx_com_error_log_pub.log_error
                 (p_program_type                => 'CONCURRENT PROGRAM',
                  p_program_name                => l_xx_cr_pay_pgm_name,
                  p_module_name                 => 'AR',
                  p_error_location              => 'Error while creating receipts - Main',
                  p_error_message_count         => 1,
                  p_error_message_code          => 'E',
                  p_error_message               => 'ERROR | ' || SQLERRM,
                  p_error_message_severity      => 'Major',
                  p_notify_flag                 => 'N',
                  p_object_type                 => 'Creating Prepayment Receipts'
                 );
   END xx_create_prepay_receipt;

-- SAS Pending Deposit Hold Records
   PROCEDURE xx_om_sas_depo_release (
      p_order_number_from   IN   NUMBER,
      p_order_number_to     IN   NUMBER,
      p_date_from           IN   VARCHAR2,
      p_date_to             IN   VARCHAR2,
      p_debug_flag          IN   VARCHAR2 DEFAULT 'N'
   )
   AS
-- +=====================================================================+
-- | Name  : XX_OM_SAS_DEPO_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: SAS Pending deposit hold                      |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
      l_hold_source_rec    oe_holds_pvt.hold_source_rec_type;
      l_hold_release_rec   oe_holds_pvt.hold_release_rec_type;
      l_header_rec         xx_om_sacct_conc_pkg.header_match_rec;
      i                    BINARY_INTEGER;
      ln_header_id         oe_order_headers_all.header_id%TYPE;
      lc_return_status     VARCHAR2 (30);
      ln_msg_count         NUMBER;
      ln_sucess_count      NUMBER                                := 0;
      ln_fetch_count       NUMBER                                := 0;
      ln_total_fetch       NUMBER                                := 0;
      ln_failed_count      NUMBER                                := 0;
      lc_msg_data          VARCHAR2 (2000);
      ln_prepaid_amount    NUMBER                                := 0;
      ln_order_total       NUMBER                                := 0;
      ln_avail_balance     NUMBER                                := 0;
      ln_hold_id           NUMBER                                := 0;
      ln_r_msg_count       NUMBER                                := 0;
      ln_payment_set_id    NUMBER;
      ln_amount            NUMBER;
      ln_ord_due_balance   NUMBER;
      ln_sent_amt          NUMBER;
      ln_amount_applied    NUMBER;
      ln_osr_length        NUMBER                                := 0;
      l_date_to            DATE
          := fnd_conc_date.string_to_date (p_date_to) + 1
             - 1 / (24 * 60 * 60);
      l_date_from          DATE := fnd_conc_date.string_to_date (p_date_from);

      -- this cursor pulls up all orders in entered and invoice hold status which has
      -- a deposit with status as "CREATED_DEPOSIT".
      CURSOR c_order_number
      IS
         SELECT DISTINCT h.header_id
                    FROM ont.oe_order_headers_all h,
                         ont.oe_order_holds_all oh,
                         ont.oe_hold_sources_all hs,
                         ont.oe_hold_definitions hd,
                         xxom.xx_om_legacy_deposits d,
                         xxom.xx_om_legacy_dep_dtls dd
                   WHERE h.header_id = oh.header_id
                     AND oh.hold_source_id = hs.hold_source_id
                     AND h.org_id = g_org_id
                     AND hs.hold_id = hd.hold_id
                     AND oh.hold_release_id IS NULL
                     AND hd.NAME = 'OD: SAS Pending deposit hold'
                     AND d.i1025_status IN
                                      ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
                     AND d.cash_receipt_id IS NOT NULL
                     AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                       SUBSTR (dd.orig_sys_document_ref, 1, 9)
                     AND LENGTH (dd.orig_sys_document_ref) = 12
                     AND dd.transaction_number = d.transaction_number
                     AND h.flow_status_code IN ('ENTERED', 'INVOICE_HOLD')
                     AND h.order_number BETWEEN NVL (p_order_number_from,
                                                     h.order_number
                                                    )
                                            AND NVL (p_order_number_to,
                                                     h.order_number
                                                    )
                     AND h.creation_date BETWEEN NVL (l_date_from,
                                                      h.creation_date
                                                     )
                                             AND NVL (l_date_to,
                                                      h.creation_date
                                                     )
         UNION
         SELECT DISTINCT h.header_id
                    FROM ont.oe_order_headers_all h,
                         ont.oe_order_holds_all oh,
                         ont.oe_hold_sources_all hs,
                         ont.oe_hold_definitions hd,
                         xxom.xx_om_legacy_deposits d,
                         xxom.xx_om_legacy_dep_dtls dd
                   WHERE h.header_id = oh.header_id
                     AND oh.hold_source_id = hs.hold_source_id
                     AND hs.hold_id = hd.hold_id
                     AND h.org_id = g_org_id
                     AND oh.hold_release_id IS NULL
                     AND hd.NAME = 'OD: SAS Pending deposit hold'
                     AND d.i1025_status IN
                                      ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
                     AND d.cash_receipt_id IS NOT NULL
                     AND h.orig_sys_document_ref = dd.orig_sys_document_ref
                     AND LENGTH (dd.orig_sys_document_ref) = 20
                     AND dd.transaction_number = d.transaction_number
                     AND h.flow_status_code IN ('ENTERED', 'INVOICE_HOLD')
                     AND h.order_number BETWEEN NVL (p_order_number_from,
                                                     h.order_number
                                                    )
                                            AND NVL (p_order_number_to,
                                                     h.order_number
                                                    )
                     AND h.creation_date BETWEEN NVL (l_date_from,
                                                      h.creation_date
                                                     )
                                             AND NVL (l_date_to,
                                                      h.creation_date
                                                     );

      -- This cursor pulls required info from deposit record to insert into payments table
      CURSOR c_payment (p_header_id IN NUMBER)
      IS
         SELECT DISTINCT h.header_id header_id, h.request_id request_id,
                         d.payment_type_code payment_type_code,
                         d.credit_card_code credit_card_code,
                         d.credit_card_number credit_card_number,
                         d.credit_card_holder_name credit_card_holder_name,
                         d.credit_card_expiration_date
                                                  credit_card_expiration_date,
                         d.payment_set_id payment_set_id,
                         d.receipt_method_id receipt_method_id,
                         d.payment_collection_event payment_collection_event,
                         d.credit_card_approval_code
                                                    credit_card_approval_code,
                         d.credit_card_approval_date
                                                    credit_card_approval_date,
                         d.check_number check_number,
                         d.orig_sys_payment_ref orig_sys_payment_ref,
                         TO_NUMBER (d.orig_sys_payment_ref) payment_number,
                         dd.orig_sys_document_ref orig_sys_document_ref,
                         d.avail_balance avail_balance,
                         d.prepaid_amount prepaid_amount,
                         d.cc_auth_manual attribute6,
                         d.merchant_number attribute7,
                         d.cc_auth_ps2000 attribute8, d.allied_ind attribute9,
                         d.cc_mask_number attribute10,
                         d.od_payment_type attribute11,
                         d.debit_card_approval_ref attribute12,
                            d.cc_entry_mode
                         || ':'
                         || d.cvv_resp_code
                         || ':'
                         || d.avs_resp_code
                         || ':'
                         || d.auth_entry_mode attribute13,
                         d.cash_receipt_id attribute15,
                         d.transaction_number tran_number    /* Added by NB */
                    FROM ont.oe_order_headers_all h,
                         xxom.xx_om_legacy_deposits d,
                         xxom.xx_om_legacy_dep_dtls dd
                   WHERE LENGTH (dd.orig_sys_document_ref) = 12
                     AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                                            SUBSTR (dd.orig_sys_document_ref(+),
                                                                    1, 9)
                     AND NVL (d.error_flag, 'N') = 'N'
                     AND dd.transaction_number = d.transaction_number
                     AND d.avail_balance > 0
                     AND h.header_id = p_header_id
         UNION
         SELECT DISTINCT h.header_id header_id, h.request_id request_id,
                         d.payment_type_code payment_type_code,
                         d.credit_card_code credit_card_code,
                         d.credit_card_number credit_card_number,
                         d.credit_card_holder_name credit_card_holder_name,
                         d.credit_card_expiration_date
                                                  credit_card_expiration_date,
                         d.payment_set_id payment_set_id,
                         d.receipt_method_id receipt_method_id,
                         d.payment_collection_event payment_collection_event,
                         d.credit_card_approval_code
                                                    credit_card_approval_code,
                         d.credit_card_approval_date
                                                    credit_card_approval_date,
                         d.check_number check_number,
                         d.orig_sys_payment_ref orig_sys_payment_ref,
                         TO_NUMBER (d.orig_sys_payment_ref) payment_number,
                         dd.orig_sys_document_ref orig_sys_document_ref,
                         d.avail_balance avail_balance,
                         d.prepaid_amount prepaid_amount,
                         d.cc_auth_manual attribute6,
                         d.merchant_number attribute7,
                         d.cc_auth_ps2000 attribute8, d.allied_ind attribute9,
                         d.cc_mask_number attribute10,
                         d.od_payment_type attribute11,
                         d.debit_card_approval_ref attribute12,
                            d.cc_entry_mode
                         || ':'
                         || d.cvv_resp_code
                         || ':'
                         || d.avs_resp_code
                         || ':'
                         || d.auth_entry_mode attribute13,
                         d.cash_receipt_id attribute15,
                         d.transaction_number tran_number    /* Added by NB */
                    FROM ont.oe_order_headers_all h,
                         xxom.xx_om_legacy_deposits d,
                         xxom.xx_om_legacy_dep_dtls dd
                   WHERE h.orig_sys_document_ref = dd.orig_sys_document_ref
                     AND NVL (d.error_flag, 'N') = 'N'
                     AND LENGTH (dd.orig_sys_document_ref) = 20
                     AND d.avail_balance > 0
                     AND dd.transaction_number = d.transaction_number
                     AND h.header_id = p_header_id;

      TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_order_tab          t_order_tab;

      -- reterives the holds info
      CURSOR c_hold (p_header_id IN NUMBER)
      IS
         SELECT oh.header_id, hs.hold_id, hs.hold_source_id, oh.order_hold_id
           FROM ont.oe_order_holds_all oh, ont.oe_hold_sources_all hs
          WHERE oh.hold_source_id = hs.hold_source_id
            AND oh.hold_release_id IS NULL
            AND oh.header_id = p_header_id;
   BEGIN
      put_log_line (p_debug_flag,
                    'Y',
                    'OD: OM Release Deposit Holds ' || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Concurrent Program Parameters                  :::'
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number From                           :::'
                    || '  '
                    || p_order_number_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number To                             :::'
                    || '  '
                    || p_order_number_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date From                              :::'
                    || '  '
                    || l_date_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date To                                :::'
                    || '  '
                    || l_date_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'Release OD: SAS Pending deposit hold ' || '  '
                    || CHR (10)
                   );
      put_log_line (p_debug_flag, 'Y', ':::BEGIN:::');

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag,
                       'N',
                       'Value of g_org_id is :  ' || g_org_id
                      );
      END IF;

      OPEN c_order_number;

      FETCH c_order_number
      BULK COLLECT INTO l_order_tab;

      CLOSE c_order_number;

      ln_fetch_count := ln_fetch_count + 1;
      ln_total_fetch := l_order_tab.COUNT;
      put_log_line (p_debug_flag,
                    'Y',
                    'Total Fetched Orders::: ' || l_order_tab.COUNT
                   );

      IF (l_order_tab.COUNT > 0)
      THEN
         FOR i IN l_order_tab.FIRST .. l_order_tab.LAST
         LOOP
            ln_header_id := l_order_tab (i).header_id;
            l_header_rec := NULL;

            OPEN c_hold (ln_header_id);

            FETCH c_hold
            BULK COLLECT INTO l_header_rec.header_id, l_header_rec.hold_id,
                   l_header_rec.hold_source_id, l_header_rec.order_hold_id;

            CLOSE c_hold;

            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                                'l_header_rec.header_id:::'
                             || l_header_rec.header_id (1)
                            );
               put_log_line (p_debug_flag,
                             'N',
                             'ln_header_id:::' || ln_header_id
                            );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            IF l_header_rec.header_id (1) IS NOT NULL
            THEN
               -- Now Remove the hold on the order
               l_hold_source_rec.hold_source_id :=
                                              l_header_rec.hold_source_id (1);
               l_hold_source_rec.hold_id := l_header_rec.hold_id (1);
               l_hold_release_rec.release_reason_code :=
                                                 'MANUAL_RELEASE_MARGIN_HOLD';
               l_hold_release_rec.release_comment :=
                                                    'Post Production Cleanup';
               l_hold_release_rec.hold_source_id :=
                                              l_header_rec.hold_source_id (1);
               l_hold_release_rec.order_hold_id :=
                                               l_header_rec.order_hold_id (1);

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                   'HEADER_ID      : '
                                || l_header_rec.header_id (1)
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'HOLD_SOURCE_ID : '
                                || l_header_rec.hold_source_id (1)
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                'HOLD_ID : ' || l_header_rec.hold_id (1)
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               oe_holds_pub.release_holds
                                    (p_hold_source_rec       => l_hold_source_rec,
                                     p_hold_release_rec      => l_hold_release_rec,
                                     x_return_status         => lc_return_status,
                                     x_msg_count             => ln_msg_count,
                                     x_msg_data              => lc_msg_data
                                    );

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'Hold Return Status::' || lc_return_status
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;
            -- COMMIT;  Defect#13407. The commit statement is stopping the ENTERED records from getting inserted into OE_PAYMENTS table.
            ELSE
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag, 'N', 'NO Hold is Applied ');
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;
            END IF;

            IF lc_return_status = 'S'
            THEN
               ln_ord_due_balance := NULL;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag, 'N', 'before r_payment loop ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_header_id ' || ln_header_id
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'l_header_rec.header_id(1)  '
                                || l_header_rec.header_id (1)
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               ln_payment_set_id := NULL;

               FOR r_payment IN c_payment (l_header_rec.header_id (1))
               LOOP
                  IF r_payment.prepaid_amount > 0
                  THEN
                     ln_header_id := r_payment.header_id;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.prepaid_amount :  '
                                      || r_payment.prepaid_amount
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'header_id :  ' || ln_header_id
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.header_id :  '
                                      || r_payment.header_id
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'orig_sys_payment_ref :  '
                                      || r_payment.orig_sys_payment_ref
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'payment_number :  '
                                      || r_payment.payment_number
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     SELECT order_total
                       INTO ln_amount
                       FROM xxom.xx_om_header_attributes_all
                      WHERE header_id = r_payment.header_id;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'ln_amount ' || ln_amount
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'avail_balance  '
                                      || r_payment.avail_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     BEGIN
                        SELECT amount_applied
                          INTO ln_amount_applied
                          FROM apps.ar_receivable_applications_all
                         WHERE cash_receipt_id = r_payment.attribute15
                           AND application_ref_num = r_payment.tran_number
                           AND application_ref_type = 'SA'
                           AND display = 'Y';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ln_amount_applied := 0;
                     END;

                     IF ln_amount <= r_payment.avail_balance
                     THEN
                        IF ln_ord_due_balance IS NULL
                        THEN
                           ln_ord_due_balance :=
                                       (ln_amount - r_payment.avail_balance
                                       );
                           ln_sent_amt := ln_amount;
                        ELSE
                           ln_sent_amt := ln_ord_due_balance;
                        END IF;
                     ELSE
                        IF ln_ord_due_balance IS NULL
                        THEN
                           ln_sent_amt := r_payment.avail_balance;
                           ln_ord_due_balance :=
                              (  NVL (ln_ord_due_balance, ln_amount)
                               - r_payment.avail_balance
                              );
                        ELSE
                           ln_sent_amt := ln_ord_due_balance;
                           ln_ord_due_balance :=
                              (  NVL (ln_ord_due_balance, ln_amount)
                               - r_payment.avail_balance
                              );
                        END IF;
                     END IF;

                     IF ln_amount_applied < ln_sent_amt
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                               (p_debug_flag,
                                'N',
                                'Amount to Apply is less then send amount   '
                               );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        GOTO end_of_loop;
                     END IF;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'ln_sent_amt  ' || ln_sent_amt
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'ln_ord_due_balance  '
                                      || ln_ord_due_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     IF ln_sent_amt <= 0
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                              (p_debug_flag,
                               'N',
                                  'Order total is less then avaliable balance :  '
                               || r_payment.attribute15
                              );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        GOTO end_of_loop;
                     ELSE
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                               (p_debug_flag,
                                'N',
                                   'UNAPPLY APPLY TRANSACTION RECEIPT ID :  '
                                || r_payment.attribute15
                               );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;
                     END IF;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.orig_sys_document_ref  '
                                      || r_payment.orig_sys_document_ref
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'cash receipt id '
                                      || r_payment.attribute15
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     xx_ar_prepayments_pkg.reapply_deposit_prepayment
                           (p_init_msg_list         => fnd_api.g_true,
                            p_commit                => fnd_api.g_false,
                            p_validation_level      => fnd_api.g_valid_level_full,
                            p_cash_receipt_id       => r_payment.attribute15,
                            p_header_id             => r_payment.header_id,
                            p_order_number          => r_payment.orig_sys_document_ref,
                            p_apply_amount          => ln_sent_amt,
                            x_payment_set_id        => ln_payment_set_id,
                            x_return_status         => lc_return_status,
                            x_msg_count             => ln_r_msg_count,
                            x_msg_data              => lc_msg_data
                           );

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line
                           (p_debug_flag,
                            'N',
                            'after calling XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment '
                           );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'lc_return_status ' || lc_return_status
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     IF lc_return_status = 'S'
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line (p_debug_flag,
                                         'N',
                                            'ln_payment_set_id : '
                                         || ln_payment_set_id
                                        );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;
                     ELSE
                        IF ln_r_msg_count >= 1
                        THEN
                           FOR i IN 1 .. ln_msg_count
                           LOOP
                              put_log_line
                                 ('N',
                                  'N',
                                     i
                                  || '. '
                                  || SUBSTR
                                        (fnd_msg_pub.get
                                                 (p_encoded      => fnd_api.g_false),
                                         1,
                                         255
                                        )
                                 );

                              IF p_debug_flag = 'Y'
                              THEN
                                 put_log_line (p_debug_flag, 'N', ' ');
                                 put_log_line
                                    (p_debug_flag,
                                     'N',
                                     'raised error and skipping the payment   '
                                    );
                                 put_log_line (p_debug_flag, 'N', ' ');
                              END IF;

                              GOTO skip_payment;
                           END LOOP;
                        END IF;
                     END IF;

                     BEGIN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line (p_debug_flag,
                                         'N',
                                         'before inserting into oe_payments '
                                        );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        INSERT INTO oe_payments
                                    (payment_level_code, header_id,
                                     creation_date, created_by,
                                     last_update_date, last_updated_by,
                                     request_id,
                                     payment_type_code,
                                     credit_card_code,
                                     credit_card_number,
                                     credit_card_holder_name,
                                     credit_card_expiration_date,
                                     prepaid_amount, payment_set_id,
                                     receipt_method_id,
                                     payment_collection_event,
                                     credit_card_approval_code,
                                     credit_card_approval_date,
                                     check_number, payment_amount,
                                     payment_number, lock_control,
                                     orig_sys_payment_ref,
                                     CONTEXT, attribute6,
                                     attribute7,
                                     attribute8,
                                     attribute9,
                                     attribute10,
                                     attribute11,
                                     attribute12,
                                     attribute13,
                                     tangible_id
                                    )
                             VALUES ('ORDER', ln_header_id,
                                     SYSDATE, fnd_global.user_id,
                                     SYSDATE, fnd_global.user_id,
                                     r_payment.request_id,
                                     r_payment.payment_type_code,
                                     r_payment.credit_card_code,
                                     r_payment.credit_card_number,
                                     r_payment.credit_card_holder_name,
                                     r_payment.credit_card_expiration_date,
                                     ln_sent_amt, ln_payment_set_id,
                                     r_payment.receipt_method_id,
                                     'PREPAY',
                                     r_payment.credit_card_approval_code,
                                     r_payment.credit_card_approval_date,
                                     r_payment.check_number, ln_sent_amt,
                                     r_payment.payment_number, 1,
                                     r_payment.orig_sys_payment_ref,
                                     'SALES_ACCT_HVOP', r_payment.attribute6,
                                     r_payment.attribute7,
                                     r_payment.attribute8,
                                     r_payment.attribute9,
                                     r_payment.attribute10,
                                     r_payment.attribute11,
                                     r_payment.attribute12,
                                     r_payment.attribute13,
                                     r_payment.attribute15
                                    );

                        put_log_line ('N', 'N', 'after insertion ');
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           put_log_line
                                  (p_debug_flag,
                                   'Y',
                                      'Trying to insert Duplicate Payment:::'
                                   || r_payment.orig_sys_document_ref
                                   || SQLERRM
                                  );
                           GOTO skip_payment;
                     END;
                  END IF;

                  <<end_of_loop>>
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag, 'N', 'END OF LOOP ');
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;
               END LOOP;

               <<skip_payment>>
               SELECT SUM (prepaid_amount)
                 INTO ln_prepaid_amount
                 FROM ont.oe_payments
                WHERE header_id = ln_header_id AND prepaid_amount > 0;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_prepaid_amount ' || ln_prepaid_amount
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               SELECT LENGTH (orig_sys_document_ref)
                 INTO ln_osr_length
                 FROM ont.oe_order_headers_all
                WHERE header_id = ln_header_id;

               SELECT ROUND (order_total, 2) order_total
                 INTO ln_order_total
                 FROM xxom.xx_om_header_attributes_all
                WHERE header_id = ln_header_id;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_order_total ' || ln_order_total
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               IF ln_prepaid_amount = ln_order_total
               THEN
                  put_log_line ('N', 'N', 'Avail Balance IS 0 ');

                  IF ln_osr_length = 12
                  THEN
                     UPDATE xxom.xx_om_legacy_deposits d
                        SET avail_balance = 0
                      WHERE prepaid_amount > 0
                        AND EXISTS (
                               SELECT 1
                                 FROM ont.oe_order_headers_all h,
                                      xxom.xx_om_legacy_dep_dtls dd
                                WHERE h.header_id = ln_header_id
                                  AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                         SUBSTR (dd.orig_sys_document_ref,
                                                 1,
                                                 9
                                                )
                                  AND LENGTH (dd.orig_sys_document_ref) = 12
                                  AND dd.transaction_number =
                                                          d.transaction_number);
                  ELSIF ln_osr_length = 20
                  THEN
                     UPDATE xxom.xx_om_legacy_deposits d
                        SET avail_balance = 0
                      WHERE prepaid_amount > 0
                        AND EXISTS (
                               SELECT 1
                                 FROM ont.oe_order_headers_all h,
                                      xxom.xx_om_legacy_dep_dtls dd
                                WHERE h.header_id = ln_header_id
                                  AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                  AND LENGTH (dd.orig_sys_document_ref) = 20
                                  AND dd.transaction_number =
                                                          d.transaction_number);
                  END IF;

                  COMMIT;
                  wf_engine.completeactivityinternalname
                                        (itemtype      => 'OEOH',
                                         itemkey       => l_header_rec.header_id
                                                                           (1),
                                         activity      => 'BOOK_ELIGIBLE',
                                         RESULT        => NULL
                                        );
                  ln_sucess_count := ln_sucess_count + 1;
                  COMMIT;
               ELSE
                  ln_avail_balance := ln_order_total - ln_prepaid_amount;

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   'ln_avail_balance : ' || ln_avail_balance
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  IF ln_avail_balance > 0
                  THEN
                     --
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'ln_avail_balance 2: '
                                      || ln_avail_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     IF ln_osr_length = 12
                     THEN
                        UPDATE xxom.xx_om_legacy_deposits d
                           SET avail_balance = ln_avail_balance
                         WHERE prepaid_amount > 0
                           AND EXISTS (
                                  SELECT 1
                                    FROM ont.oe_order_headers_all h,
                                         xxom.xx_om_legacy_dep_dtls dd
                                   WHERE h.header_id = ln_header_id
                                     AND SUBSTR (h.orig_sys_document_ref, 1,
                                                 9) =
                                            SUBSTR (dd.orig_sys_document_ref,
                                                    1,
                                                    9
                                                   )
                                     AND LENGTH (dd.orig_sys_document_ref) =
                                                                            12
                                     AND dd.transaction_number =
                                                          d.transaction_number);
                     ELSIF ln_osr_length = 20
                     THEN
                        UPDATE xxom.xx_om_legacy_deposits d
                           SET avail_balance = ln_avail_balance
                         WHERE prepaid_amount > 0
                           AND EXISTS (
                                  SELECT 1
                                    FROM ont.oe_order_headers_all h,
                                         xxom.xx_om_legacy_dep_dtls dd
                                   WHERE h.header_id = ln_header_id
                                     AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                     AND LENGTH (dd.orig_sys_document_ref) =
                                                                            20
                                     AND dd.transaction_number =
                                                          d.transaction_number);
                     END IF;

                     SELECT hold_id
                       INTO ln_hold_id
                       FROM ont.oe_hold_definitions
                      WHERE NAME = 'OD: SAS Pending deposit hold';

                     l_hold_source_rec.hold_id := ln_hold_id;
                     l_hold_source_rec.hold_entity_code := 'O';
                     l_hold_source_rec.hold_entity_id := ln_header_id;
                     l_hold_source_rec.hold_comment :=
                                                 SUBSTR (lc_msg_data, 1, 2000);
                     oe_holds_pub.apply_holds
                            (p_api_version           => 1.0,
                             p_validation_level      => fnd_api.g_valid_level_none,
                             p_hold_source_rec       => l_hold_source_rec,
                             x_msg_count             => ln_msg_count,
                             x_msg_data              => lc_msg_data,
                             x_return_status         => lc_return_status
                            );
                  END IF;
               END IF;
            END IF;

            COMMIT;
         END LOOP;
      END IF;

      ln_failed_count := ln_total_fetch - ln_sucess_count;

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', ' ');
         put_log_line (p_debug_flag,
                       'N',
                          'Sucessfully processed order Count:::'
                       || ln_sucess_count
                      );
         put_log_line (p_debug_flag,
                       'N',
                       'Failed to process order Count:::' || ln_failed_count
                      );
         put_log_line (p_debug_flag, 'N', ' ');
      END IF;

      put_log_line ('N', 'N', ':::End of Program:::');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         put_log_line (p_debug_flag, 'Y', 'No Data Found To Process:::');
      WHEN OTHERS
      THEN
         put_log_line (p_debug_flag, 'Y', 'When Others Raised: ' || SQLERRM);
   END;

-- Payment Processing Failure Hold Records
   PROCEDURE xx_om_ppf_hold_release (
      p_order_number_from   IN   NUMBER,
      p_order_number_to     IN   NUMBER,
      p_date_from           IN   VARCHAR2,
      p_date_to             IN   VARCHAR2,
      p_debug_flag          IN   VARCHAR2 DEFAULT 'N'
   )
   AS
-- +=====================================================================+
-- | Name  : XX_OM_PPF_HOLD_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: Payment Processing Failure                    |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
      l_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
      l_hold_release_rec       oe_holds_pvt.hold_release_rec_type;
-----------------
      l_order_number_rec       order_number_rec;
      l_order_number_rec_tab   order_number_rec_tab;
      i                        BINARY_INTEGER;
      j                        NUMBER                                := 0;
      ln_header_id             oe_order_headers_all.header_id%TYPE;
      lc_return_status         VARCHAR2 (30);
      ln_failed_count          NUMBER                                := 0;
      ln_msg_count             NUMBER;
      ln_total_fetch           NUMBER                                := 0;
      ln_sucess_count          NUMBER                                := 0;
      lc_msg_data              VARCHAR2 (2000);
      l_date_to                DATE
          := fnd_conc_date.string_to_date (p_date_to) + 1
             - 1 / (24 * 60 * 60);
      l_date_from              DATE
                                := fnd_conc_date.string_to_date (p_date_from);
      l_xx_pre_return_status   VARCHAR2 (1)                          := '';
      l_p_debug_flag           VARCHAR2 (1);
      --Added to include the logic to release holds on orders with zero dollar amount
      l_ord_total_ppf          NUMBER;

--Main cursor to fetch records stuck in PPF Hold status and the status of the payment,deposit,receipt and if customer is of AB type
      CURSOR c_order_number
      IS
         SELECT   *
             FROM (SELECT imp_file_name,
                                        -- TO_CHAR(H.CREATION_DATE,'dd-mon-yyyy hh24:mi:ss'),
                                        h.creation_date,
                                                        -- TO_CHAR(H.LAST_UPDATE_DATE,'dd-mon-yyyy hh24:mi:ss'),
                                                        h.last_update_date,
                          h.request_id, h.batch_id, oh.order_hold_id,
                          hs.hold_source_id, h.order_number, h.header_id,
                          hd.NAME AS hold_name, h.flow_status_code,
                          DECODE ((SELECT 1
                                     FROM ont.oe_payments o
                                    WHERE o.header_id = h.header_id
                                      AND ROWNUM = 1),
                                  NULL, 'N',
                                  'Y'
                                 ) payment_status,
                          (SELECT DECODE
                                        (b.transaction_number,
                                         NULL, 'N',
                                         'Y'
                                        )
                             FROM apps.xx_om_legacy_deposits a,
                                  ont.oe_order_headers_all c,
                                  apps.xx_om_legacy_dep_dtls b
                            WHERE b.orig_sys_document_ref(+) =
                                                       c.orig_sys_document_ref
                              AND b.transaction_number = a.transaction_number(+)
                              AND c.orig_sys_document_ref =
                                                       h.orig_sys_document_ref
                              AND h.header_id = c.header_id
                              AND ROWNUM = 1) deposit_status,
                          DECODE
                             ((SELECT 1
                                 FROM apps.oe_payments i,
                                      apps.ar_cash_receipts_all acra,
                                      apps.ar_cash_receipt_history_all acrh,
                                      apps.xx_ar_order_receipt_dtl xxar,
                                      apps.ar_payment_schedules_all arps
                                WHERE 1 = 1
                                  AND h.header_id = i.header_id
                                  AND acra.cash_receipt_id = i.attribute15
                                  AND acrh.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND acrh.current_record_flag = 'Y'
                                  AND xxar.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND arps.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND ROWNUM = 1),
                              NULL, 'N',
                              'Y'
                             ) receipt_status,
                          DECODE
                             ((SELECT 1
                                 FROM apps.hz_customer_profiles o
                                WHERE h.sold_to_org_id = o.cust_account_id
                                  AND o.attribute3 = 'Y'
                                  AND ROWNUM = 1),
                              1, 'Y',
                              'N'
                             ) AS ab_customer
                     FROM ont.oe_order_holds_all oh,
                          ont.oe_order_headers_all h,
                          ont.oe_hold_sources_all hs,
                          ont.oe_hold_definitions hd,
                          xxom.xx_om_header_attributes_all x
                    WHERE oh.hold_source_id = hs.hold_source_id
                      AND x.header_id = h.header_id
                      AND hs.hold_id = hd.hold_id
                      AND oh.hold_release_id IS NULL
                      AND h.org_id = g_org_id
                      AND oh.header_id = h.header_id
                      AND h.flow_status_code = 'INVOICE_HOLD'
                      AND hd.NAME = 'OD: Payment Processing Failure'
                      AND h.order_number BETWEEN NVL (p_order_number_from,
                                                      h.order_number
                                                     )
                                             AND NVL (p_order_number_to,
                                                      h.order_number
                                                     )
                      AND h.creation_date BETWEEN NVL (l_date_from,
                                                       h.creation_date
                                                      )
                                              AND NVL (l_date_to,
                                                       h.creation_date
                                                      )) stg
            WHERE 1 = 1
         ORDER BY 2;

      TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_order_tab              t_order_tab;
   BEGIN
      put_log_line (p_debug_flag,
                    'Y',
                    'OD: Payment Processing Failure HOLDS' || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Concurrent Program Parameters                  :::'
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number From                           :::'
                    || '  '
                    || p_order_number_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number To                             :::'
                    || '  '
                    || p_order_number_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date From                              :::'
                    || '  '
                    || l_date_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date To                                :::'
                    || '  '
                    || l_date_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'Release OD: Payment Processing Failure' || '  '
                    || CHR (10)
                   );
      put_log_line (p_debug_flag, 'Y', ':::BEGIN:::');

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag,
                       'N',
                       'Value of g_org_id is :  ' || g_org_id
                      );
      END IF;

      OPEN c_order_number;

      FETCH c_order_number
      BULK COLLECT INTO l_order_tab;

      CLOSE c_order_number;

      ln_total_fetch := l_order_tab.COUNT;
      ln_sucess_count := 0;
      put_log_line (p_debug_flag,
                    'Y',
                    'Total Fetched Orders::: ' || l_order_tab.COUNT
                   );

      IF (l_order_tab.COUNT > 0)
      THEN
         FOR i IN l_order_tab.FIRST .. l_order_tab.LAST
         LOOP
            l_order_number_rec := NULL;
            l_order_number_rec.imp_file_name := l_order_tab (i).imp_file_name;
            l_order_number_rec.creation_date := l_order_tab (i).creation_date;
            l_order_number_rec.last_update_date :=
                                             l_order_tab (i).last_update_date;
            l_order_number_rec.request_id := l_order_tab (i).request_id;
            l_order_number_rec.batch_id := l_order_tab (i).batch_id;
            l_order_number_rec.order_hold_id := l_order_tab (i).order_hold_id;
            l_order_number_rec.hold_source_id :=
                                               l_order_tab (i).hold_source_id;
            l_order_number_rec.order_number := l_order_tab (i).order_number;
            l_order_number_rec.header_id := l_order_tab (i).header_id;
            l_order_number_rec.hold_name := l_order_tab (i).hold_name;
            l_order_number_rec.flow_status_code :=
                                             l_order_tab (i).flow_status_code;
            l_order_number_rec.payment_status :=
                                               l_order_tab (i).payment_status;
            l_order_number_rec.deposit_status :=
                                               l_order_tab (i).deposit_status;
            l_order_number_rec.ab_customer := l_order_tab (i).ab_customer;
            l_order_number_rec.receipt_status :=
                                               l_order_tab (i).receipt_status;
            l_order_number_rec_tab (j) := l_order_number_rec;

            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                                'Sales Order Number is :::'
                             || l_order_tab (i).order_number
                            );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            --part 2
            -- Now Remove the hold on the order
            l_hold_source_rec.hold_source_id := l_order_tab (i).hold_source_id;
            l_hold_source_rec.hold_id := l_order_tab (i).order_hold_id;
            l_hold_release_rec.release_reason_code :=
                                                  'MANUAL_RELEASE_MARGIN_HOLD';
            l_hold_release_rec.release_comment := 'Post Production Cleanup';
            l_hold_release_rec.hold_source_id :=
                                                l_order_tab (i).hold_source_id;
            l_hold_release_rec.order_hold_id := l_order_tab (i).order_hold_id;

            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                             'HEADER_ID      : ' || l_order_tab (i).header_id
                            );
               put_log_line (p_debug_flag,
                             'N',
                                'HOLD_SOURCE_ID : '
                             || l_order_tab (i).hold_source_id
                            );
               put_log_line (p_debug_flag,
                             'N',
                                'HOLD_ID        : '
                             || l_order_tab (i).order_hold_id
                            );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            --Logic to segregate the records which will be called by Create Receipt Procedure
            --before OD: Payment Processing Failure Hold is being released

            --PPF Holds on all AB Customer Orders should be released without further check
            IF (l_order_tab (i).ab_customer = 'Y')
            THEN
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'PPF Holds on  AB Customers Orders'
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                'Calling the Release Hold on the order'
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               GOTO release_hold_api;
            --PPF Holds on non AB Customer Orders should be verified on the basis of the Receipt and Payment Information
            ELSE
               --If both Payment and Receipt Status is Y
               IF (    l_order_tab (i).receipt_status = 'Y'
                   AND l_order_tab (i).payment_status = 'Y'
                  )
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line
                        (p_debug_flag,
                         'N',
                         'PPF Holds on non AB Customers Orders are further checked on the Payment and Receipt Status'
                        );
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Payment Status :  '
                                   || l_order_tab (i).payment_status
                                   || '   and  Receipt Status : '
                                   || l_order_tab (i).receipt_status
                                  );
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Calling the Release Hold on the order'
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  GOTO release_hold_api;
               ELSIF (    l_order_tab (i).receipt_status = 'N'
                      AND l_order_tab (i).payment_status = 'Y'
                     )
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Payment Status :  '
                                   || l_order_tab (i).payment_status
                                   || '   and  Receipt Status : '
                                   || l_order_tab (i).receipt_status
                                  );
                     put_log_line
                        (p_debug_flag,
                         'N',
                         'Receipt needs to be created before releasing Hold on the order'
                        );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  --Debug Messages before calling the procedure
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Passing the HEADER_ID      : '
                                   || l_order_tab (i).header_id
                                  );
                     put_log_line
                        (p_debug_flag,
                         'N',
                            'Calling XX_CREATE_PREPAY_RECEIPT package for the Order :  '
                         || l_order_tab (i).order_number
                        );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  --Calling Create Receipt Procedure
                  l_p_debug_flag := p_debug_flag;
                  xx_create_prepay_receipt
                                    (p_header_id          => l_order_tab (i).header_id,
                                     p_debug_flag         => l_p_debug_flag,
                                     p_return_status      => l_xx_pre_return_status
                                    );

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                      'Return from XX_CREATE_PREPAY_RECEIPT '
                                   || CHR (10)
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  --Check if the return status of the procedure.
                  IF (l_xx_pre_return_status = 'S')
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Calling the Release Hold on the order'
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     GOTO release_hold_api;
                  ELSE
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line
                           (p_debug_flag,
                            'N',
                               'XX_CREATE_PREPAY_RECEIPT has failed to create a receipt   : '
                            || l_order_tab (i).order_number
                           );
                        put_log_line
                                (p_debug_flag,
                                 'N',
                                 'Hold will not be released against the order'
                                );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     GOTO ppf_hold_not_to_be_released;
                  END IF;
------------------------------------------
               ELSIF (    l_order_tab (i).receipt_status = 'N'
                      AND l_order_tab (i).payment_status = 'N'
                     )
               THEN
                  BEGIN
                     SELECT order_total
                       INTO l_ord_total_ppf
                       FROM xxom.xx_om_header_attributes_all
                      WHERE header_id = l_order_tab (i).header_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        fnd_file.put_line (fnd_file.LOG,
                                           ' No Data Found To Process'
                                          );
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                                    (fnd_file.LOG,
                                     ' Exception happened at L_ORD_TOTAL_PPF'
                                    );
                  END;

                  IF (l_ord_total_ppf = 0)
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'L_ORD_TOTAL_PPF is  : '
                                      || l_ord_total_ppf
                                     );
                        put_log_line
                           (p_debug_flag,
                            'N',
                            'This is a zero dollar transaction, so Hold should be released'
                           );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Calling Hold Release Program '
                                     );
                     END IF;

                     GOTO release_hold_api;
                  ELSE
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line
                           (p_debug_flag,
                            'N',
                               'The order is not elligible for PPF Hold release '
                            || l_order_tab (i).order_number
                           );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     GOTO ppf_hold_not_to_be_released;
                  END IF;
-------------------------------------------------------
               ELSE
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                      'If the Payment Staus is '
                                   || l_order_tab (i).payment_status
                                   || '  and Receip Status is  '
                                   || l_order_tab (i).receipt_status
                                   || ' for Non AB 
Customers '
                                  );
                     put_log_line
                        (p_debug_flag,
                         'N',
                            'The order is not elligible for PPF Hold release '
                         || l_order_tab (i).order_number
                        );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  GOTO ppf_hold_not_to_be_released;
               END IF;
            END IF;

            --Type 2
            <<release_hold_api>>
            oe_holds_pub.release_holds
                                    (p_hold_source_rec       => l_hold_source_rec,
                                     p_hold_release_rec      => l_hold_release_rec,
                                     x_return_status         => lc_return_status,
                                     x_msg_count             => ln_msg_count,
                                     x_msg_data              => lc_msg_data
                                    );

                          --End of Type 2
--end of part 12
            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                             'Hold Return Status::' || lc_return_status
                            );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            IF lc_return_status = fnd_api.g_ret_sts_success
            THEN
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag, 'N', 'Holds API Success');
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               COMMIT;
               wf_engine.completeactivityinternalname
                                (itemtype      => 'OEOH',
                                 itemkey       => l_order_tab (i).header_id,
                                 activity      => 'HDR_INVOICE_INTERFACE_ELIGIBLE',
                                 RESULT        => NULL
                                );
               ln_sucess_count := ln_sucess_count + 1;
               COMMIT;
            ELSIF lc_return_status IS NULL
            THEN
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'Status is null from Holds API '
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;
            ELSE
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'Holds API Failed: ' || lc_msg_data
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               FOR i IN 1 .. oe_msg_pub.count_msg
               LOOP
                  lc_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i,
                                          p_encoded        => 'F');

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   i || ') ' || lc_msg_data
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;
               END LOOP;

               ROLLBACK;
            END IF;

            <<ppf_hold_not_to_be_released>>
            j := j + 1;
         END LOOP;

         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag, 'N', ' :::End of Program:::');
            put_log_line (p_debug_flag, 'N', ' ');
         END IF;
      ELSE
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag,
                          'N',
                          ' No record in Payment Processing Failure Hold'
                         );
            put_log_line (p_debug_flag, 'N', ' ');
         END IF;
      END IF;

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', ' ');
         put_log_line (p_debug_flag,
                       'N',
                          ' Sucessfully processed order Count:::'
                       || ln_sucess_count
                      );
         put_log_line (p_debug_flag,
                       'N',
                       ' Failed to process order Count:::' || ln_failed_count
                      );
         put_log_line (p_debug_flag, 'N', ' ');
      END IF;

      ln_failed_count := ln_total_fetch - ln_sucess_count;
      put_log_line ('N', 'N', ' :::End of Program:::');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         put_log_line (p_debug_flag, 'Y', ' No Data Found To Process:::');
      WHEN OTHERS
      THEN
         put_log_line (p_debug_flag, 'Y', ' When Others Raised: ' || SQLERRM);
   END;
END xx_om_releasehold_2;
/

SHOW ERRORS PACKAGE BODY XX_OM_RELEASEHOLD_2;
--EXIT;