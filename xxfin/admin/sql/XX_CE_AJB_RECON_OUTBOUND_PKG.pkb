CREATE OR REPLACE PACKAGE BODY xx_ce_ajb_recon_outbound_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Providge  Consulting                        |
-- +===================================================================+
-- | Name             :   XX_CE_AJB_RECON_OUTBOUND_PKG                 |
-- | Description      :                                                |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0       19-Mar-2008  Sarat Uppalapati    Initial version         |
-- |1.0       26-Mar-2008  Sarat Uppalapati    Changed O/p filenames   |
-- | 1.1      22-Apr-2008  Deepak Gowda        Get about 1/3rd of 996  |
-- |                                           transactions. Remove    |
-- |                                           CHR(13) at end of line  |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- |         Name : XX_CE_RTD_998                                      |
-- | Description :  This procedure is creating data file for           |
-- |     Reconciliation Transaction Detail Records for 998             |
-- |                                                                   |
-- |                                                                   |
-- | Program:                                                          |
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date,p_bank_rec_id    |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE xx_ce_rtd_998 (
      p_errbuf       VARCHAR2
    , p_retcode      VARCHAR2
    , p_trans_date   VARCHAR2
    , p_bank_rec_id  VARCHAR2
   )
   IS
      CURSOR lcu_recon_998
      IS
         (SELECT CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN 'DEBIT'
                    WHEN 'ECA'
                       THEN 'CHECK'
                    ELSE 'CREDIT'
                 END tender_type
               , NVL (acr.attribute1, acr.attribute2) store_num, acr.amount
               , CASE acr.org_id
                    WHEN 404
                       THEN 840
                    WHEN 403
                       THEN 124
                 END country_code
               , CASE acr.currency_code
                    WHEN 'USD'
                       THEN '840'
                    WHEN 'CAD'
                       THEN '124'
                 END currency_code
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN acr.customer_receipt_reference
                    WHEN 'ECA'
                       THEN acr.customer_receipt_reference
                    ELSE acr.receipt_number
                 END receipt_number
               , acr.receipt_number receipt_number_org
               , acr.payment_server_order_num || acr.approval_code auth_num
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN NULL
                    WHEN 'ECA'
                       THEN NULL
                    ELSE acr.payment_server_order_num
                 END ipay_batch_num
               , acr.receipt_date, hdr.provider_code processor_id
            FROM apps.ar_cash_receipts_all acr
               , apps.fnd_lookup_values lv
               , xxfin.xx_ce_recon_glact_hdr hdr
           WHERE acr.attribute14 IS NOT NULL
             AND acr.receipt_method_id NOT IN (
                    SELECT receipt_method_id
                      FROM ar.ar_receipt_methods
                     WHERE NAME IN
                              ('US_CC IRECEIVABLES_OD'
                             , 'CA_CC IRECEIVABLES_OD'))
             AND lv.lookup_type = 'OD_PAYMENT_TYPES'
             AND acr.attribute14 = lv.meaning
             AND lv.lookup_code = hdr.om_card_type
             AND acr.org_id = hdr.org_id
             AND acr.receipt_date =
                                   fnd_conc_date.string_to_date (p_trans_date)
             AND (NOT EXISTS (SELECT 'x'
                                FROM xx_ce_ajb998 ajb998
                               WHERE ajb998.receipt_num = acr.receipt_number)
                 )
             AND acr.receipt_date BETWEEN hdr.effective_from_date
                                      AND NVL (hdr.effective_to_date
                                             , acr.receipt_date + 1
                                              ))
         UNION ALL
         (SELECT CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN 'DEBIT'
                    WHEN 'ECA'
                       THEN 'CHECK'
                    ELSE 'CREDIT'
                 END tender_type
               , ib.KEY store_num, acr.amount
               , CASE acr.org_id
                    WHEN 404
                       THEN 840
                    WHEN 403
                       THEN 124
                 END country_code
               , CASE acr.currency_code
                    WHEN 'USD'
                       THEN '840'
                    WHEN 'CAD'
                       THEN '124'
                 END currency_code
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN acr.customer_receipt_reference
                    WHEN 'ECA'
                       THEN acr.customer_receipt_reference
                    ELSE acr.receipt_number
                 END receipt_number
               , acr.receipt_number receipt_number_org
               , acr.payment_server_order_num || acr.approval_code auth_num
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN NULL
                    WHEN 'ECA'
                       THEN NULL
                    ELSE acr.payment_server_order_num
                 END ipay_batch_num
               , acr.receipt_date, hdr.provider_code processor_id
            FROM apps.iby_trxn_summaries_all its
               , apps.ar_cash_receipts_all acr
               , xx_ce_recon_glact_hdr hdr
               , apps.iby_trxn_core itc
               , apps.fnd_lookup_values lv
               , apps.fnd_lookup_values lv2
               , apps.ar_receipt_methods arm
               , apps.xx_fin_translatevalues val
               , apps.xx_fin_translatedefinition def
               , apps.iby_bepkeys ib
           WHERE its.tangibleid = acr.payment_server_order_num
             AND acr.receipt_method_id IN (
                    SELECT receipt_method_id
                      FROM apps.ar_receipt_methods
                     WHERE NAME IN
                              ('US_CC IRECEIVABLES_OD'
                             , 'CA_CC IRECEIVABLES_OD'))
             AND itc.trxnmid = its.trxnmid
             AND lv.lookup_code = UPPER (itc.instrname)
             AND lv.lookup_type = 'OD_CE_AJB_AUTH_TO_OM_CARD_TYPE'
             AND lv2.lookup_type = 'OD_PAYMENT_TYPES'
             AND lv2.meaning = lv.tag
             AND itc.instrname IS NOT NULL
             AND lv2.lookup_code = hdr.om_card_type
             AND acr.org_id = hdr.org_id
             AND arm.receipt_method_id = acr.receipt_method_id
             AND val.source_value1 = arm.merchant_ref
             AND def.translate_id = val.translate_id
             AND def.translation_name = 'XX_AR_PROMO_KEY'
             AND acr.receipt_date =
                                   fnd_conc_date.string_to_date (p_trans_date)
             AND ib.ownerid = arm.merchant_ref
             AND ib.bepid IN (SELECT ibo.bepid
                                FROM apps.iby_bepinfo ibo
                               WHERE ibo.NAME = val.target_value1)
             AND (NOT EXISTS (SELECT 'x'
                                FROM xx_ce_ajb998 ajb998
                               WHERE ajb998.receipt_num = acr.receipt_number)
                 )
             AND arm.receipt_class_id IN (SELECT receipt_class_id
                                            FROM apps.ar_receipt_classes
                                           WHERE NAME LIKE '%CC%IRECEIVABLES%')
             AND acr.receipt_date BETWEEN hdr.effective_from_date
                                      AND NVL (hdr.effective_to_date
                                             , acr.receipt_date + 1
                                              ));

      l_fhandle         UTL_FILE.file_type;
      lc_recordstr      VARCHAR2 (4000);
      lc_errbuf         VARCHAR2 (200)          := NULL;
      lc_retcode        VARCHAR2 (25)           := NULL;
      lc_dirpath        VARCHAR2 (2000)         := 'XXFIN_OUTBOUND';
      lc_filename       VARCHAR2 (200)  := 'AJB998' || p_bank_rec_id || '.txt';
      lc_fieldseprator  VARCHAR2 (2000)         := ',';
      lr_recon_998      lcu_recon_998%ROWTYPE;
      lc_status         VARCHAR2 (10);
      ln_req_id         NUMBER;
      lc_error_message  VARCHAR2 (2000);
      lc_err_msg        VARCHAR2 (2000);
      lc_vsetfile       VARCHAR2 (30);
      lc_sdate          VARCHAR2 (20);
      lc_trx_type       VARCHAR2 (10);
   BEGIN
      fnd_file.put_line (fnd_file.LOG
                       , 'Processing Reconcilliation for 998:    '
                        );
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_recon_998 IN lcu_recon_998
      LOOP
         lc_vsetfile :=
            CASE rcu_recon_998.tender_type
               WHEN 'CREDIT'
                  THEN    TO_CHAR (rcu_recon_998.receipt_date, 'YYYYMMDD')
                       || '-'
                       || '001'
                       || '.vset'
               ELSE NULL
            END;
         lc_sdate :=
            CASE rcu_recon_998.tender_type
               WHEN 'CREDIT'
                  THEN TO_CHAR (SYSDATE, 'YYYYMMDD')
               ELSE NULL
            END;

         IF (rcu_recon_998.amount < 0)
         THEN
            lc_trx_type := 'REFUND';
         ELSE
            lc_trx_type := 'SALE';
         END IF;

         SELECT    '998'
                || lc_fieldseprator             -- FIPay Reconciliation Record
                || lc_vsetfile
                || lc_fieldseprator                               -- Vset File
                || lc_sdate
                || lc_fieldseprator              -- Settlement Processing Date
                || '0'
                || lc_fieldseprator                             -- Action Code
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_998.tender_type
                || lc_fieldseprator                             -- Tender Type
                || ''
                || lc_fieldseprator                                -- Reserved
                || LPAD (rcu_recon_998.store_num, 6, '0')
                || lc_fieldseprator                            -- Store Number
                || ''
                || lc_fieldseprator                         -- terminal Number
                || lc_trx_type
                || lc_fieldseprator                        -- Transaction Type
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || '123456******9999'
                || lc_fieldseprator                   -- Masked Account Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || LPAD (ABS (rcu_recon_998.amount * 100), 11, '0')
                || lc_fieldseprator                                  -- Amount
                || ''
                || lc_fieldseprator                          -- Invoice Number
                || rcu_recon_998.country_code
                || lc_fieldseprator                            -- Country Code
                || rcu_recon_998.currency_code
                || lc_fieldseprator                           -- Currency Code
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_998.receipt_number
                || '#'
                || lc_fieldseprator                          -- Receipt Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_998.auth_num
                || lc_fieldseprator                    -- Authorization Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || p_bank_rec_id
                || lc_fieldseprator       -- Bank Reconciliation Processing ID
                || rcu_recon_998.ipay_batch_num
                || lc_fieldseprator                   -- iPayment Batch Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || TO_CHAR (rcu_recon_998.receipt_date, 'MMDDYYYY')
                || lc_fieldseprator                        -- Transaction Date
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_998.processor_id
                || lc_fieldseprator                            -- Processor ID
                || ''
                || lc_fieldseprator                             -- Network Fee
                || ''
                || lc_fieldseprator                          -- Adjustment Fee
                || ''
                || lc_fieldseprator                  -- Adjustment/Return Date
                || ''
                || lc_fieldseprator                  -- Adjustment Reason Code
                || ''
                || lc_fieldseprator           -- Adjustment Reason Description
                || ''
                || lc_fieldseprator                      -- Reject Reason Code
                || ''
                || lc_fieldseprator               -- Reject Reason Description
                || ''
                || lc_fieldseprator                             -- Other Fee 1
                || ''
                || lc_fieldseprator                             -- Other Fee 2
                || ''
                || lc_fieldseprator
                              -- Paper Check Fundig % (Merchant Reimbursement)
                || ''
                || lc_fieldseprator                        -- Reference Number
                || ''
                || lc_fieldseprator                         -- Discount Amount
                || ''
                || lc_fieldseprator                           -- Discount Rate
                || ''
                || lc_fieldseprator                            -- Service Rate
                || ''
                || lc_fieldseprator                            -- Other Rate 1
                || ''                                          -- Other Rate 2
           -- || chr(13)
         INTO   lc_recordstr
           FROM DUAL;

--      fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
      ln_req_id :=
         fnd_request.submit_request ('XXFIN'
                                   , 'XXCOMFILCOPY'
                                   , ''
                                   , ''
                                   , FALSE
                                   ,    '$CUSTOM_DATA/xxfin/outbound/'
                                     || lc_filename
                                   ,    '$CUSTOM_DATA/xxfin/ftp/out/'
                                     || lc_filename
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                    );

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG
                        , 'Error submitting request for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                      (p_program_type                => 'CONCURRENT PROGRAM'
                     , p_program_name                => 'XXCERCON998'
                     , p_program_id                  => fnd_global.conc_program_id
                     , p_module_name                 => 'CE'
                     , p_error_location              => 'Error at Submitting XXCOMFILCOPY'
                     , p_error_message_count         => 1
                     , p_error_message_code          => 'E'
                     , p_error_message               => lc_err_msg
                     , p_error_message_severity      => 'Major'
                     , p_notify_flag                 => 'N'
                     , p_object_type                 => 'XX_CE_RTD_996'
                      );
      ELSE
         fnd_file.put_line (fnd_file.output
                          ,    'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM'
                                , p_program_name                => 'XXCERTD998'
                                , p_program_id                  => fnd_global.conc_program_id
                                , p_module_name                 => 'CE'
                                , p_error_location              => 'Error '
                                , p_error_message_count         => 1
                                , p_error_message_code          => 'E'
                                , p_error_message               => lc_err_msg
                                , p_error_message_severity      => 'Major'
                                , p_notify_flag                 => 'N'
                                , p_object_type                 => 'XX_CE_RTD_998'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END xx_ce_rtd_998;

-- +===================================================================+
-- |         Name : XX_CE_RTD_996                                      |
-- | Description :  This procedure is creating data file for           |
-- |     Reconciliation Transaction Detail Records for 996             |
-- |                                                                   |
-- |                                                                   |
-- | Program:                                                          |
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date ,p_bank_rec_id   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE xx_ce_rtd_996 (
      p_errbuf       VARCHAR2
    , p_retcode      VARCHAR2
    , p_trans_date   VARCHAR2
    , p_bank_rec_id  VARCHAR2
   )
   IS
      CURSOR lcu_recon_996
      IS
         (SELECT CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN 'DEBIT'
                    WHEN 'ECA'
                       THEN 'CHECK'
                    ELSE 'CREDIT'
                 END tender_type
               , NVL (acr.attribute1, acr.attribute2) store_num, acr.amount
               , CASE acr.org_id
                    WHEN 404
                       THEN 840
                    WHEN 403
                       THEN 124
                 END country_code
               , CASE acr.currency_code
                    WHEN 'USD'
                       THEN '840'
                    WHEN 'CAD'
                       THEN '124'
                 END currency_code
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN acr.customer_receipt_reference
                    WHEN 'ECA'
                       THEN acr.customer_receipt_reference
                    ELSE acr.receipt_number
                 END receipt_number
               , acr.receipt_number receipt_number_org
               , acr.payment_server_order_num || acr.approval_code auth_num
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN NULL
                    WHEN 'ECA'
                       THEN NULL
                    ELSE acr.payment_server_order_num
                 END ipay_batch_num
               , acr.receipt_date, hdr.provider_code processor_id
            FROM apps.ar_cash_receipts_all acr
               , apps.fnd_lookup_values lv
               , xxfin.xx_ce_recon_glact_hdr hdr
           WHERE acr.attribute14 IS NOT NULL
             AND acr.receipt_method_id NOT IN (
                    SELECT receipt_method_id
                      FROM ar.ar_receipt_methods
                     WHERE NAME IN
                              ('US_CC IRECEIVABLES_OD'
                             , 'CA_CC IRECEIVABLES_OD'))
             AND lv.lookup_type = 'OD_PAYMENT_TYPES'
             AND acr.attribute14 = lv.meaning
             AND lv.lookup_code = hdr.om_card_type
             AND acr.org_id = hdr.org_id
             AND acr.receipt_date =
                                   fnd_conc_date.string_to_date (p_trans_date)
--       AND (NOT EXISTS (
--                SELECT 'x'
--                  FROM xx_ce_ajb998 ajb998
--                 WHERE ajb998.receipt_num = acr.receipt_number )
--            )
             AND MOD (acr.cash_receipt_id, 5) = 1
             AND acr.receipt_date BETWEEN hdr.effective_from_date
                                      AND NVL (hdr.effective_to_date
                                             , acr.receipt_date + 1
                                              ))
         UNION ALL
         (SELECT CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN 'DEBIT'
                    WHEN 'ECA'
                       THEN 'CHECK'
                    ELSE 'CREDIT'
                 END tender_type
               , ib.KEY store_num, acr.amount
               , CASE acr.org_id
                    WHEN 404
                       THEN 840
                    WHEN 403
                       THEN 124
                 END country_code
               , CASE acr.currency_code
                    WHEN 'USD'
                       THEN '840'
                    WHEN 'CAD'
                       THEN '124'
                 END currency_code
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN acr.customer_receipt_reference
                    WHEN 'ECA'
                       THEN acr.customer_receipt_reference
                    ELSE acr.receipt_number
                 END receipt_number
               , acr.receipt_number receipt_number_org
               , acr.payment_server_order_num || acr.approval_code auth_num
               , CASE hdr.ajb_card_type
                    WHEN 'DEBIT'
                       THEN NULL
                    WHEN 'ECA'
                       THEN NULL
                    ELSE acr.payment_server_order_num
                 END ipay_batch_num
               , acr.receipt_date, hdr.provider_code processor_id
            FROM apps.iby_trxn_summaries_all its
               , apps.ar_cash_receipts_all acr
               , xx_ce_recon_glact_hdr hdr
               , apps.iby_trxn_core itc
               , apps.fnd_lookup_values lv
               , apps.fnd_lookup_values lv2
               , apps.ar_receipt_methods arm
               , apps.xx_fin_translatevalues val
               , apps.xx_fin_translatedefinition def
               , apps.iby_bepkeys ib
           WHERE its.tangibleid = acr.payment_server_order_num
             AND acr.receipt_method_id IN (
                    SELECT receipt_method_id
                      FROM apps.ar_receipt_methods
                     WHERE NAME IN
                              ('US_CC IRECEIVABLES_OD'
                             , 'CA_CC IRECEIVABLES_OD'))
             AND itc.trxnmid = its.trxnmid
             AND lv.lookup_code = UPPER (itc.instrname)
             AND lv.lookup_type = 'OD_CE_AJB_AUTH_TO_OM_CARD_TYPE'
             AND lv2.lookup_type = 'OD_PAYMENT_TYPES'
             AND lv2.meaning = lv.tag
             AND itc.instrname IS NOT NULL
             AND lv2.lookup_code = hdr.om_card_type
             AND acr.org_id = hdr.org_id
             AND arm.receipt_method_id = acr.receipt_method_id
             AND val.source_value1 = arm.merchant_ref
             AND def.translate_id = val.translate_id
             AND def.translation_name = 'XX_AR_PROMO_KEY'
             AND acr.receipt_date =
                                   fnd_conc_date.string_to_date (p_trans_date)
             AND ib.ownerid = arm.merchant_ref
             AND ib.bepid IN (SELECT ibo.bepid
                                FROM apps.iby_bepinfo ibo
                               WHERE ibo.NAME = val.target_value1)
--       AND (NOT EXISTS (
--                SELECT 'x'
--                  FROM xx_ce_ajb998 ajb998
--                 WHERE ajb998.receipt_num = acr.receipt_number )
--            )
             AND MOD (acr.cash_receipt_id, 5) = 1
             AND arm.receipt_class_id IN (SELECT receipt_class_id
                                            FROM apps.ar_receipt_classes
                                           WHERE NAME LIKE '%CC%IRECEIVABLES%')
             AND acr.receipt_date BETWEEN hdr.effective_from_date
                                      AND NVL (hdr.effective_to_date
                                             , acr.receipt_date + 1
                                              ));

      l_fhandle         UTL_FILE.file_type;
      lc_recordstr      VARCHAR2 (4000);
      lc_errbuf         VARCHAR2 (200)          := NULL;
      lc_retcode        VARCHAR2 (25)           := NULL;
      lc_dirpath        VARCHAR2 (2000)         := 'XXFIN_OUTBOUND';
      lc_filename       VARCHAR2 (200)  := 'AJB996' || p_bank_rec_id || '.txt';
      lc_fieldseprator  VARCHAR2 (2000)         := ',';
      lr_recon_996      lcu_recon_996%ROWTYPE;
      lc_status         VARCHAR2 (10);
      ln_req_id         NUMBER;
      lc_error_message  VARCHAR2 (2000);
      lc_err_msg        VARCHAR2 (2000);
      lc_vsetfile       VARCHAR2 (30);
      lc_sdate          VARCHAR2 (20);
      lc_trx_type       VARCHAR2 (10);
      lc_cb_code        VARCHAR2 (30);
      lc_cb_acode       VARCHAR2 (30);
      lc_cb_ncode       NUMBER;
   BEGIN
      fnd_file.put_line (fnd_file.LOG
                       , 'Processing Reconcilliation for 996:    '
                        );
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_recon_996 IN lcu_recon_996
      LOOP
         lc_vsetfile :=
            CASE rcu_recon_996.tender_type
               WHEN 'CREDIT'
                  THEN    TO_CHAR (rcu_recon_996.receipt_date, 'YYYYMMDD')
                       || '-'
                       || '001'
                       || '.vset'
               ELSE NULL
            END;
         lc_sdate :=
            CASE rcu_recon_996.tender_type
               WHEN 'CREDIT'
                  THEN TO_CHAR (SYSDATE, 'YYYYMMDD')
               ELSE NULL
            END;

         IF (rcu_recon_996.amount < 0)
         THEN
            lc_trx_type := 'REFUND';
         ELSE
            lc_trx_type := 'SALE';
         END IF;

         lc_cb_code :=
                CASE rcu_recon_996.processor_id
                   WHEN 'MPSCRD'
                      THEN 'CACP'
                   ELSE NULL
                END;
         lc_cb_acode :=
                  CASE rcu_recon_996.processor_id
                     WHEN 'CCSCRD'
                        THEN 'HG'
                     ELSE NULL
                  END;
         lc_cb_ncode :=
                   CASE rcu_recon_996.processor_id
                      WHEN 'CCSCRD'
                         THEN 255
                      ELSE NULL
                   END;

         SELECT    '996'
                || lc_fieldseprator             -- FIPay Reconciliation Record
                || lc_vsetfile
                || lc_fieldseprator                               -- Vset File
                || lc_sdate
                || lc_fieldseprator              -- Settlement Processing Date
                || '0'
                || lc_fieldseprator                             -- Action Code
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_996.tender_type
                || lc_fieldseprator                             -- Tender Type
                || ''
                || lc_fieldseprator                                -- Reserved
                || LPAD (rcu_recon_996.store_num, 6, '0')
                || lc_fieldseprator                            -- Store Number
                || ''
                || lc_fieldseprator                         -- terminal Number
                || lc_trx_type
                || lc_fieldseprator                        -- Transaction Type
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || '123456******9999'
                || lc_fieldseprator                   -- Masked Account Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || LPAD (ABS (rcu_recon_996.amount * 100), 11, '0')
                || lc_fieldseprator                                  -- Amount
                || ''
                || lc_fieldseprator                          -- Invoice Number
                || rcu_recon_996.country_code
                || lc_fieldseprator                            -- Country Code
                || rcu_recon_996.currency_code
                || lc_fieldseprator                           -- Currency Code
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_996.receipt_number
                || '#'
                || lc_fieldseprator                          -- Receipt Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_996.auth_num
                || lc_fieldseprator                    -- Authorization Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || p_bank_rec_id
                || lc_fieldseprator       -- Bank Reconciliation Processing ID
                || rcu_recon_996.ipay_batch_num
                || lc_fieldseprator                   -- iPayment Batch Number
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || TO_CHAR (rcu_recon_996.receipt_date, 'MMDDYYYY')
                || lc_fieldseprator                        -- Transaction Date
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || ''
                || lc_fieldseprator                                -- Reserved
                || rcu_recon_996.processor_id
                || lc_fieldseprator                            -- Processor ID
                || ''
                || lc_fieldseprator                  -- Mastercard no auth fee
                || ''
                || lc_fieldseprator                         -- Chargeback Rate
                || LPAD (ABS (rcu_recon_996.amount * 100), 11, '0')
                || lc_fieldseprator                       -- Chargeback Amount
                || lc_cb_code
                || lc_fieldseprator                  -- Chargeback Action Code
                || ''
                || lc_fieldseprator             -- Chargeback Action Code Date
                || ''
                || lc_fieldseprator             -- Chargeback Reference Number
                || ''
                || lc_fieldseprator              -- Retrieval Reference Number
                || ''
                || lc_fieldseprator                            -- Other Rate 1
                || ''
                || lc_fieldseprator                            -- Other Rate 2
                || lc_cb_acode
                || lc_fieldseprator  -- Chargeback Alpha Code (for Citi Only )
                || lc_cb_ncode     -- Chargeback numeric Code (for Citi Only )
           --  || chr(13)
         INTO   lc_recordstr
           FROM DUAL;

--      fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
      ln_req_id :=
         fnd_request.submit_request ('XXFIN'
                                   , 'XXCOMFILCOPY'
                                   , ''
                                   , ''
                                   , FALSE
                                   ,    '$CUSTOM_DATA/xxfin/outbound/'
                                     || lc_filename
                                   ,    '$CUSTOM_DATA/xxfin/ftp/out/'
                                     || lc_filename
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                    );

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG
                        , 'Error submitting request for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                      (p_program_type                => 'CONCURRENT PROGRAM'
                     , p_program_name                => 'XXCERTD996'
                     , p_program_id                  => fnd_global.conc_program_id
                     , p_module_name                 => 'CE'
                     , p_error_location              => 'Error at Submitting XXCOMFILCOPY'
                     , p_error_message_count         => 1
                     , p_error_message_code          => 'E'
                     , p_error_message               => lc_err_msg
                     , p_error_message_severity      => 'Major'
                     , p_notify_flag                 => 'N'
                     , p_object_type                 => 'XX_CE_RTD_996'
                      );
      ELSE
         fnd_file.put_line (fnd_file.output
                          ,    'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM'
                                , p_program_name                => 'XXCERTD996'
                                , p_program_id                  => fnd_global.conc_program_id
                                , p_module_name                 => 'CE'
                                , p_error_location              => 'Error '
                                , p_error_message_count         => 1
                                , p_error_message_code          => 'E'
                                , p_error_message               => lc_err_msg
                                , p_error_message_severity      => 'Major'
                                , p_notify_flag                 => 'N'
                                , p_object_type                 => 'XX_CE_RTD_996'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END xx_ce_rtd_996;

-- +===================================================================+
-- |         Name : XX_CE_RTD_999                                      |
-- | Description :  This procedure is creating data file for           |
-- |     Reconciliation Store Fee Records for 999                      |
-- |                                                                   |
-- |                                                                   |
-- | Program:                                                          |
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date, p_bank_rec_id   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE xx_ce_rtd_999 (
      p_errbuf       VARCHAR2
    , p_retcode      VARCHAR2
    --,p_trans_date VARCHAR2
   ,  p_bank_rec_id  VARCHAR2
   )
   IS
      CURSOR lcu_recon_999
      IS
         SELECT   SUM (amount) sales_amt, SUM (chbk_amt) chbk_amt, org_id
                , currency_code, bank_rec_id, provider_type tender_type
                , processor_id, store_num, recon_ajb_card_type card_type
             FROM (SELECT   SUM (trx_amount) amount, 0 chbk_amt, org_id
                          , currency_code, bank_rec_id, provider_type
                          , processor_id, store_num, recon_ajb_card_type
                       FROM apps.xx_ce_ajb998_ar_v ajb998
                      WHERE ajb998.bank_rec_id = p_bank_rec_id
                   GROUP BY org_id
                          , currency_code
                          , bank_rec_id
                          , provider_type
                          , processor_id
                          , store_num
                          , recon_ajb_card_type
                   UNION
                   SELECT   0 amount, SUM (chbk_amt) * -1 chbk_amt, org_id
                          , currency_code, bank_rec_id, provider_type
                          , processor_id, store_num, recon_ajb_card_type
                       FROM apps.xx_ce_ajb996_ar_v ajb996
                      WHERE ajb996.bank_rec_id = p_bank_rec_id
                   GROUP BY org_id
                          , currency_code
                          , bank_rec_id
                          , provider_type
                          , processor_id
                          , store_num
                          , recon_ajb_card_type)
         GROUP BY org_id
                , currency_code
                , bank_rec_id
                , provider_type
                , processor_id
                , store_num
                , recon_ajb_card_type
         ORDER BY bank_rec_id
                , processor_id
                , provider_type
                , recon_ajb_card_type
                , store_num;

      l_fhandle          UTL_FILE.file_type;
      lc_recordstr       VARCHAR2 (4000);
      lc_errbuf          VARCHAR2 (200)          := NULL;
      lc_retcode         VARCHAR2 (25)           := NULL;
      lc_dirpath         VARCHAR2 (2000)         := 'XXFIN_OUTBOUND';
      lc_filename        VARCHAR2 (200) := 'AJB999' || p_bank_rec_id || '.txt';
      lc_fieldseprator   VARCHAR2 (2000)         := ',';
      lr_recon_999       lcu_recon_999%ROWTYPE;
      lc_status          VARCHAR2 (10);
      ln_req_id          NUMBER;
      lc_error_message   VARCHAR2 (2000);
      lc_err_msg         VARCHAR2 (2000);
      lc_vsetfile        VARCHAR2 (30);
      lc_sdate           VARCHAR2 (20);
      lc_trx_type        VARCHAR2 (10);
      ln_org_id          NUMBER;
      lc_currency_code   VARCHAR2 (10);
      ln_costs_fund_amt  NUMBER                  := 1 / 100;
      ln_discount_amt    NUMBER                  := 0;
      ln_mon_ass_fee     NUMBER                  := 0;
      ln_reserved_amt    NUMBER                  := 0;
      ln_mon_dis_amt     NUMBER                  := 0;
      ln_amt             NUMBER                  := 0;
      lc_sign            VARCHAR2 (1)            := '+';
   BEGIN
      fnd_file.put_line (fnd_file.LOG
                       , 'Processing Reconcilliation for 999:    '
                        );
      l_fhandle := UTL_FILE.fopen (lc_dirpath, lc_filename, 'w');

      FOR rcu_recon_999 IN lcu_recon_999
      LOOP
         -- ln_discount_amt     := 0;
         -- ln_mon_ass_fee      := 0;
         -- ln_reserved_amt     := 0;
         -- ln_mon_dis_amt      := 0;
         ln_org_id :=
                CASE rcu_recon_999.org_id
                   WHEN 404
                      THEN 840
                   WHEN 403
                      THEN 124
                END;
         lc_currency_code :=
            CASE rcu_recon_999.currency_code
               WHEN 'USD'
                  THEN '840'
               WHEN 'CAD'
                  THEN '124'
            END;

         BEGIN
            SELECT   charge_percentage
                INTO ln_reserved_amt
                FROM xxfin.xx_ce_recon_glact_hdr hdr
                   , xxfin.xx_ce_recon_glact_dtl dtl
                   , xxfin.xx_ce_accrual_glact_dtl acc_dtl
               WHERE dtl.header_id = hdr.header_id
                 AND acc_dtl.header_id = hdr.header_id
                 AND UPPER (TRIM (acc_dtl.charge_description)) =
                                         UPPER (TRIM (dtl.charge_description))
                 AND TRIM (hdr.provider_code) =
                                             TRIM (rcu_recon_999.processor_id)
                 AND TRIM (hdr.ajb_card_type) = TRIM (rcu_recon_999.card_type)
                 AND acc_dtl.charge_code = 'RESERVED_AMOUNT'
                 AND ROWNUM = 1
            GROUP BY charge_percentage;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_reserved_amt := 0;
         END;

         BEGIN
            SELECT   charge_percentage
                INTO ln_mon_dis_amt
                FROM xxfin.xx_ce_recon_glact_hdr hdr
                   , xxfin.xx_ce_recon_glact_dtl dtl
                   , xxfin.xx_ce_accrual_glact_dtl acc_dtl
               WHERE dtl.header_id = hdr.header_id
                 AND acc_dtl.header_id = hdr.header_id
                 AND UPPER (TRIM (acc_dtl.charge_description)) =
                                         UPPER (TRIM (dtl.charge_description))
                 AND TRIM (hdr.provider_code) =
                                             TRIM (rcu_recon_999.processor_id)
                 AND TRIM (hdr.ajb_card_type) = TRIM (rcu_recon_999.card_type)
                 AND acc_dtl.charge_code = 'MONTHLY_DISCOUNT'
                 AND ROWNUM = 1
            GROUP BY charge_percentage;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_mon_dis_amt := 0;
         END;

         BEGIN
            SELECT   charge_percentage
                INTO ln_discount_amt
                FROM xxfin.xx_ce_recon_glact_hdr hdr
                   , xxfin.xx_ce_recon_glact_dtl dtl
                   , xxfin.xx_ce_accrual_glact_dtl acc_dtl
               WHERE dtl.header_id = hdr.header_id
                 AND acc_dtl.header_id = hdr.header_id
                 AND UPPER (TRIM (acc_dtl.charge_description)) =
                                         UPPER (TRIM (dtl.charge_description))
                 AND TRIM (hdr.provider_code) =
                                             TRIM (rcu_recon_999.processor_id)
                 AND TRIM (hdr.ajb_card_type) = TRIM (rcu_recon_999.card_type)
                 AND acc_dtl.charge_code = 'DAILY_DISCOUNT'
                 AND ROWNUM = 1
            GROUP BY charge_percentage;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_discount_amt := 0;
         END;

         BEGIN
            SELECT   charge_percentage
                INTO ln_mon_ass_fee
                FROM xxfin.xx_ce_recon_glact_hdr hdr
                   , xxfin.xx_ce_recon_glact_dtl dtl
                   , xxfin.xx_ce_accrual_glact_dtl acc_dtl
               WHERE dtl.header_id = hdr.header_id
                 AND acc_dtl.header_id = hdr.header_id
                 AND UPPER (TRIM (acc_dtl.charge_description)) =
                                         UPPER (TRIM (dtl.charge_description))
                 AND TRIM (hdr.provider_code) =
                                             TRIM (rcu_recon_999.processor_id)
                 AND TRIM (hdr.ajb_card_type) = TRIM (rcu_recon_999.card_type)
                 AND acc_dtl.charge_code = 'ASSESSMENT_FEE'
                 AND ROWNUM = 1
            GROUP BY charge_percentage;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_mon_ass_fee := 0;
         END;

         ln_amt := (rcu_recon_999.sales_amt + rcu_recon_999.chbk_amt);

         IF (ln_amt < 0)
         THEN
            lc_sign := '-';
         ELSE
            lc_sign := '+';
         END IF;

         SELECT    '999'
                || lc_fieldseprator             -- FIPay Reconciliation Record
                || LPAD (rcu_recon_999.store_num, 6, '0')
                || lc_fieldseprator                            -- Store Number
                || rcu_recon_999.tender_type
                || lc_fieldseprator                             -- Tender Type
                || TO_CHAR (SYSDATE, 'MMDDYYYY')
                || lc_fieldseprator                         -- Processing Date
                || ln_org_id
                || lc_fieldseprator                            -- Country Code
                || rcu_recon_999.currency_code
                || lc_fieldseprator                           -- Currency Code
                || rcu_recon_999.processor_id
                || lc_fieldseprator                            -- Processor ID
                || rcu_recon_999.bank_rec_id
                || lc_fieldseprator       -- Bank Reconciliation Processing ID
                || rcu_recon_999.card_type
                || lc_fieldseprator                               -- Card Type
                || lc_sign
                || ABS (ln_amt) * 100
                || lc_fieldseprator                        -- Net Sales Amount
                || ''
                || lc_fieldseprator                       -- Net Reject Amount
                || (rcu_recon_999.chbk_amt * 100)
                || lc_fieldseprator          -- Chargeback / Adjustment Amount
                || lc_sign
                || ABS (ln_amt * ln_discount_amt / 100) * 100
                || lc_fieldseprator                         -- Discount Amount
                || ''
                || lc_fieldseprator                      -- Net Deposit Amount
                || lc_sign
                || ABS (ln_amt * ln_mon_dis_amt / 100) * 100
                || lc_fieldseprator                    -- Monthly Discount Fee
                || lc_sign
                || ABS (ln_amt * ln_mon_ass_fee / 100) * 100
                || lc_fieldseprator                  -- Monthly Assessment Fee
                || ''
                || lc_fieldseprator                     -- Deposit Hold Amount
                || ''
                || lc_fieldseprator                  -- Deposit Release Amount
                || ''
                || lc_fieldseprator                             -- Service Fee
                || ''
                || lc_fieldseprator                          -- Adjustment Fee
                || lc_sign
                || ABS (ln_amt * ln_costs_fund_amt) * 100
                || lc_fieldseprator                    -- Cost of Funds Amount
                || ''
                || lc_fieldseprator
                                  -- Cost of Funds Alpha Code (for Citi Only )
                || ''
                || lc_fieldseprator
                                -- Cost of Funds numeric Code (for Citi Only )
                || lc_sign
                || ABS (ln_amt * ln_reserved_amt / 100) * 100
                || lc_fieldseprator                         -- Reserved Amount
                || ''
                || lc_fieldseprator
                                -- Reserved Amount Alpha Code (for Citi Only )
                || ''         -- Reserved Amount numeric Code (for Citi Only )
           -- || chr(13)
         INTO   lc_recordstr
           FROM DUAL;

--      fnd_file.put_line (fnd_file.LOG, 'Data:    ' || lc_recordstr);
         UTL_FILE.put_line (l_fhandle, lc_recordstr);
      END LOOP;

      UTL_FILE.fclose (l_fhandle);
      ln_req_id :=
         fnd_request.submit_request ('XXFIN'
                                   , 'XXCOMFILCOPY'
                                   , ''
                                   , ''
                                   , FALSE
                                   ,    '$CUSTOM_DATA/xxfin/outbound/'
                                     || lc_filename
                                   ,    '$CUSTOM_DATA/xxfin/ftp/out/'
                                     || lc_filename
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                   , ''
                                    );

      IF ln_req_id = 0
      THEN
         fnd_file.put_line
                         (fnd_file.LOG
                        , 'Error submitting request for ''Output Redirect''.'
                         );
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                      (p_program_type                => 'CONCURRENT PROGRAM'
                     , p_program_name                => 'XXCERTD999'
                     , p_program_id                  => fnd_global.conc_program_id
                     , p_module_name                 => 'CE'
                     , p_error_location              => 'Error at Submitting XXCOMFILCOPY'
                     , p_error_message_count         => 1
                     , p_error_message_code          => 'E'
                     , p_error_message               => lc_err_msg
                     , p_error_message_severity      => 'Major'
                     , p_notify_flag                 => 'N'
                     , p_object_type                 => 'XX_CE_RTD_999'
                      );
      ELSE
         fnd_file.put_line (fnd_file.output
                          ,    'Started ''Redirecting Output File'' at '
                            || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           );
         fnd_file.put_line (fnd_file.output, ' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_0001_ERR');
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_err_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' ' || SQLERRM);
         xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM'
                                , p_program_name                => 'XXCERTD999'
                                , p_program_id                  => fnd_global.conc_program_id
                                , p_module_name                 => 'CE'
                                , p_error_location              => 'Error '
                                , p_error_message_count         => 1
                                , p_error_message_code          => 'E'
                                , p_error_message               => lc_err_msg
                                , p_error_message_severity      => 'Major'
                                , p_notify_flag                 => 'N'
                                , p_object_type                 => 'XX_CE_RTD_999'
                                 );
         UTL_FILE.fclose (l_fhandle);
   END xx_ce_rtd_999;
END xx_ce_ajb_recon_outbound_pkg;
/