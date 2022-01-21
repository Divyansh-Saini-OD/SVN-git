CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_RFND_POS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - SDR project                                                                |
-- |  Oracle GSD Consulting                                                                     |
-- +============================================================================================+
-- |  Name:  XX_AR_RFND_POS_PKG                                                                 |
-- |  Rice Id : I1038                                                                           |
-- |  Description:  This OD Package that contains a procedure to create AR Refund process for   |
-- |                POS                                                                         |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06-APR-2011  Vamshi Katta     Initial version                                  |
-- | 1.1         25-APR-2011  Gaurav           Code Changed to get payment method from          |
-- |                                           ar_receipt_methods and order_recipt_dtl table    |
-- | 1.2         17-MAY-2011  Sreenivasa T     Updated code as per defect id 11543              |
-- | 1.3         20-MAY-2011  Vamshi Katta     Modified code for org specific                   |
-- | 1.4         11-Jul-2013  Rishabh Chhajer  Modified as per R12 Retrofit Upgrade             |
-- +============================================================================================+

   gn_org_id         NUMBER  DEFAULT fnd_global.org_id;
   gd_sysdate        DATE    DEFAULT SYSDATE;
   gn_user_id        NUMBER  DEFAULT fnd_global.user_id;
   gn_login_id       NUMBER  DEFAULT fnd_global.login_id;
   gn_conc_req_id    NUMBER  DEFAULT fnd_global.conc_request_id;
   gn_conc_prog_name VARCHAR2(35) DEFAULT 'OD: Identify Non AB POS Refunds';

-- +============================================================================================+
-- | Procedure - Output and log messages are captured                                           |
-- +============================================================================================+

   PROCEDURE od_message
   (  p_msg_type        IN  VARCHAR2
    , p_msg             IN  VARCHAR2
    , p_msg_loc         IN  VARCHAR2 DEFAULT NULL
    , p_addnl_line_len  IN  NUMBER DEFAULT 110 )
   IS
     ln_char_count  NUMBER := 0;
     ln_line_count  NUMBER := 0;
   BEGIN
      IF p_msg_type = 'M' or p_msg_type = 'E' THEN

         fnd_file.put_line (fnd_file.LOG, p_msg);
      ELSIF p_msg_type = 'O' THEN
         IF NVL (LENGTH (p_msg), 0) > 120 THEN
            FOR x IN 1..(TRUNC ((LENGTH (p_msg) - 120) / p_addnl_line_len) + 2 ) LOOP

               ln_line_count := NVL (ln_line_count, 0) + 1;
               IF ln_line_count = 1 THEN
                  fnd_file.put_line(fnd_file.output, SUBSTR (p_msg, 1, 120));
                  ln_char_count := NVL (ln_char_count, 0) + 120;

               ELSE
                  fnd_file.put_line( fnd_file.output,
                    LPAD(' ', 120 - p_addnl_line_len, ' ')
                      || SUBSTR(LTRIM(p_msg), ln_char_count + 1, p_addnl_line_len ) );
                  ln_char_count := NVL (ln_char_count, 0) + p_addnl_line_len;

               END IF;
            END LOOP;
         ELSE
            fnd_file.put_line (fnd_file.output, p_msg);
         END IF;
      END IF;
   END od_message;

-- +============================================================================================+
-- |  This procedure extracts records from mail check table and insert only pending POS records |
-- |  into refund temp table for further processing via E055.                                   |
-- +============================================================================================+

   PROCEDURE insert_mcheck_pos_rfnd_proc (
      err_buf                    OUT      VARCHAR2
    , retcode                    OUT      NUMBER)
   IS
      --V1.2 Added Outer Joins and NVL conditions to the xx_ar_order_receipt_dtl related columns.
      CURSOR c_mail_check
      IS
         SELECT xamch.ref_mailcheck_id
              , xamch.pos_transaction_number
              , xamch.aops_order_number
              , xamch.check_amount
              , NVL(xaord.customer_id,1380) customer_id
              , xamch.store_customer_name
              , xamch.address_line_1
              , xamch.address_line_2
              , xamch.address_line_3
              , xamch.address_line_4
              , xamch.city
              , CASE
                   WHEN xamch.country = 'US'
                      THEN xamch.state_province
                   ELSE NULL
                END state
              , CASE
                   WHEN xamch.country = 'CA'
                      THEN xamch.state_province
                   ELSE NULL
                END province
              , xamch.postal_code
              , xamch.country
              , xamch.phone_number
              , xamch.phone_extension
              , xamch.hold_status
              , xamch.delete_status
              , xamch.creation_date
              , xamch.created_by
              , xamch.last_update_date
              , xamch.last_update_by
              , xamch.last_update_login
              , xamch.program_application_id
              , xamch.program_id
              , xamch.program_update_date
              , xamch.request_id
              , xamch.process_code
              , xamch.ap_vendor_id
              , xamch.ap_invoice_id
              --, xamch.ar_cash_receipt_id
              , xamch.ar_customer_trx_id
              , NVL(xaord.cash_receipt_id,1380) cash_receipt_id
              , NVL(xaord.currency_code,DECODE(xamch.country,'US','USD','CA','CAD',NULL)) currency_code
              , NVL(xaord.receipt_number,xamch.pos_transaction_number) trx_number
              , NVL(xaord.store_number,'00'||SUBSTR(xamch.pos_transaction_number,1,4)) store_number
              , xaord.receipt_method_id
              , NVL(arm.name,'US_POS_MAILCHECK_OD') name
           FROM xx_ar_mail_check_holds xamch
              , xx_ar_order_receipt_dtl xaord
              , ar_receipt_methods     arm
          WHERE xamch.pos_transaction_number = xaord.orig_sys_document_ref(+)
            AND xamch.aops_order_number IS NULL
        AND xamch.ar_cash_receipt_id IS NULL
            AND xamch.process_code = 'PENDING'
            AND xaord.receipt_method_id= arm.receipt_method_id(+)
            AND NVL(xamch.country,'US')  = (SELECT  DECODE( NAME,'OU_US', 'US', 'OU_CA','CA')		-- Added by Rishabh On 11-Jul-13 as per R12 Retrofit changes.
                                         FROM HR_OPERATING_UNITS 
                                           WHERE ORGANIZATION_ID=FND_PROFILE.VALUE('ORG_ID')); -- 1.3

      l_rec_mail_check       c_mail_check%ROWTYPE;
      lc_proc_name  CONSTANT VARCHAR2(30)                := 'INSERT_MCHECK_POS_RFND_PROC';
      lc_sob_name            gl_sets_of_books.NAME%TYPE;
      lc_om_write_off_only   VARCHAR2(1)                 := NULL;
      lc_escheat_flag        VARCHAR2(1)                 := NULL;
      lc_activity_type       VARCHAR2(30)                := NULL;
      --lc_om_store_number     VARCHAR2(30)                := NULL;
      lc_invalid_rec         VARCHAR2(1)                := NULL;
      lc_payment_method_name VARCHAR2(30)                 := NULL;
      ln_total_records       NUMBER                       := 0;
      ln_success_records     NUMBER                       := 0;
      ln_error_records       NUMBER                       := 0;
      exp_invalid_sob        EXCEPTION;
   BEGIN

      od_message('M', 'BEGIN '|| lc_proc_name);
   begin
mo_global.SET_POLICY_CONTEXT('S',gn_org_id);
end;
      -- Derive Set of Books Name
      BEGIN
         SELECT gsb.short_name
           INTO lc_sob_name
           FROM ar_system_parameters asp
              , gl_sets_of_books gsb
          WHERE gsb.set_of_books_id = asp.set_of_books_id
            AND gsb.short_name IN ('US_USD_P', 'CA_CAD_P');

             od_message('M', 'Set of Books : '|| lc_sob_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            od_message('M','Error Message : Set of Books not found');
            RAISE exp_invalid_sob;
      END;

      FOR l_rec_mail_check IN c_mail_check
      LOOP
         -- Initializing variables
         --lc_om_store_number      := NULL;
         lc_om_write_off_only    := NULL;
         lc_escheat_flag         := NULL;
         lc_activity_type        := NULL;
         lc_invalid_rec          := 'N';
         lc_payment_method_name  := NULL;
         ln_total_records        := ln_total_records+1;

         od_message('M','---------------------------------------------------------------');
         od_message('M','Ref_mailcheck_ID    : '|| l_rec_mail_check.ref_mailcheck_id);
         od_message('M','Cash_receipt ID     : '|| l_rec_mail_check.cash_receipt_id);

         -- Derive Payment method Name
/*  Code commented by Gaurav for v1.1
         BEGIN
            SELECT --NVL (acr.attribute1, acr.attribute2),
                   arm.name
              INTO --lc_om_store_number ,
                   lc_payment_method_name
              FROM ar_cash_receipts_all acr
                 , ar_receipt_methods arm
             WHERE arm.receipt_method_id = acr.receipt_method_id
               AND acr.cash_receipt_id = l_rec_mail_check.cash_receipt_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_payment_method_name := NULL;
               --lc_om_store_number := NULL;
               lc_invalid_rec := 'Y';
               od_message('M','Error Message : Payment Method Name not found');
         END;

Code commented by Gaurav for v1.1  */
         IF lc_invalid_rec = 'N' THEN
            IF ( l_rec_mail_check.hold_status = 'P'
            AND l_rec_mail_check.delete_status = 'N')
            THEN
               lc_om_write_off_only    := 'N';
               lc_escheat_flag         := 'N';

               IF lc_sob_name = 'US_USD_P'
               THEN
                  lc_activity_type    := 'US_MAILCK_CLR_OD';
               ELSIF lc_sob_name = 'CA_CAD_P'
               THEN
                  lc_activity_type    := 'CA_MAILCK_CLR_OD';
               ELSE
                  RAISE exp_invalid_sob;
               END IF;
            -- ignore hold_status values for escheat
            ELSIF (l_rec_mail_check.delete_status IN ('A', 'E') )
            THEN
               lc_escheat_flag         := 'Y';
               lc_om_write_off_only    := 'N';

               IF lc_sob_name = 'US_USD_P'
               THEN
                  lc_activity_type    := 'US_ESCHEAT_REC_WRITEOFF_OD';
               ELSIF lc_sob_name = 'CA_CAD_P'
               THEN
                  lc_activity_type    := 'CA_ESCHEAT_REC_WRITEOFF_OD';
               ELSE
                  RAISE exp_invalid_sob;
               END IF;
            -- process any other mail check records as write-offs
            ELSE
               --writeoff_receipt
               lc_om_write_off_only    := 'Y';
               lc_escheat_flag         := 'N';

               IF lc_sob_name = 'US_USD_P'
               THEN
                  IF (l_rec_mail_check.delete_status = 'S')
                  THEN
                     lc_activity_type    :=    'US_MAILCK_REV_'
                                            || l_rec_mail_check.store_number
                                            || '_OD';
                  ELSIF ((l_rec_mail_check.delete_status = 'O')
                         OR (l_rec_mail_check.delete_status = 'M') )
                  THEN
                     lc_activity_type    :=    'US_MAILCK_O/S_'
                                            || l_rec_mail_check.store_number
                                            || '_OD';
                  ELSE
                     od_message('M','Error Message : Invalid Combination of Hold Status and Delete Status');
                     lc_invalid_rec := 'Y';
                  END IF;
               -- for CANADA SOB
               ELSIF lc_sob_name = 'CA_CAD_P'
               THEN
                  IF (l_rec_mail_check.delete_status = 'S')
                  THEN
                     lc_activity_type    :=    'CA_MAILCK_REV_'
                                            || l_rec_mail_check.store_number
                                            || '_OD';
                  ELSIF (    (l_rec_mail_check.delete_status = 'O')
                         OR (l_rec_mail_check.delete_status = 'M') )
                  THEN
                     lc_activity_type    :=    'CA_MAILCK_O/S_'
                                            || l_rec_mail_check.store_number
                                            || '_OD';
                  ELSE
                     od_message('M','Error Message : Invalid Combination of Hold Status and Delete Status');
                     lc_invalid_rec := 'Y';
                  END IF;
               ELSE
                  RAISE exp_invalid_sob;
               END IF;
            END IF;

            od_message('M','Delete Status       : '|| l_rec_mail_check.delete_status);
            od_message('M','Hold Status         : '|| l_rec_mail_check.hold_status);
            od_message('M','Activity Type       : '|| lc_activity_type);
            od_message('M','Escheat Flag        : '|| lc_escheat_flag);
            od_message('M','Om Write off Flag   : '|| lc_om_write_off_only);
            od_message('M','Payment Method Name : '|| lc_payment_method_name);
            --od_message('M','OM Store Number     : '|| lc_om_store_number);
         END IF;

         IF lc_invalid_rec = 'N'
         THEN
            ln_success_records := ln_success_records +1;
            INSERT INTO xx_ar_refund_trx_tmp
                        (refund_header_id
                       , customer_id
                       , customer_number
                       , payee_name
                       , aops_customer_number
                       , trx_id
                       , trx_type
                       , trx_number
                       , trx_currency_code
                       , refund_amount
                       , identification_type
                       , identification_date
                       , org_id
                       , primary_bill_loc_id
                       , alt_address1
                       , alt_address2
                       , alt_address3
                       , alt_city
                       , alt_state
                       , alt_province
                       , alt_postal_code
                       , alt_country
                       , last_update_date
                       , last_updated_by
                       , creation_date
                       , created_by
                       , last_update_login
                       , om_hold_status
                       , om_delete_status
                       , om_write_off_only
                       , pre_selected_flag
                       , adj_created_flag
                       , selected_flag
                       , refund_alt_flag
                       , escheat_flag
                       , status
                       , inv_created_flag
                       , activity_type
                       , om_store_number
                       , ref_mailcheck_id
                       , payment_method_name)
                 VALUES (xx_refund_header_id_s.NEXTVAL
                       , l_rec_mail_check.customer_id                                                          --(XX_AR_ORDER_RECEIPT_DTL)
                       , NULL                                                                            -- customer_number
                       , l_rec_mail_check.store_customer_name                                                                 --payee_name
                       , NULL                                                                       -- aops_customer_number
                       , l_rec_mail_check.cash_receipt_id                                                                        -- trx_id
                       , 'R'                                                                                    -- trx_type
                       , l_rec_mail_check.trx_number                                                                         -- trx_number
                       , l_rec_mail_check.currency_code                                                       -- currency_code
                       , l_rec_mail_check.check_amount                                                                    -- refund_amount
                       , 'OM'                                                                        -- identification_type
                       , SYSDATE                                                                     -- identificaiton_date
                       , gn_org_id                                                                        -- org_id
                       , NULL                                                                         --primary_bill_loc_id
                       , l_rec_mail_check.address_line_1
                       , l_rec_mail_check.address_line_2
                       , l_rec_mail_check.address_line_3
                       , l_rec_mail_check.city
                       , l_rec_mail_check.state                                                                                --alt_state
                       , l_rec_mail_check.province                                                                          --alt_province
                       , l_rec_mail_check.postal_code
                       , l_rec_mail_check.country
                       , gd_sysdate
                       , gn_user_id
                       , gd_sysdate
                       , gn_user_id
                       , gn_login_id
                       , l_rec_mail_check.hold_status                                                                    -- om_hold_status
                       , l_rec_mail_check.delete_status                                                                -- om_delete_status
                       , lc_om_write_off_only
                       , 'N'                                                                            --pre_selected_flag
                       , 'Y'                                                                             --adj_created_flag
                       , 'Y'                                                                                --selected_flag
                       , 'Y'                                                                              --refund_alt_flag
                       , lc_escheat_flag
                       , 'A'                                                                                       --status
                       , 'N'                                                                             --inv_created_flag
                       , lc_activity_type
                       , l_rec_mail_check.store_number
                       , l_rec_mail_check.ref_mailcheck_id
                       , l_rec_mail_check.name);

            UPDATE xx_ar_mail_check_holds
               SET process_code = 'APPROVED'
                 , ar_cash_receipt_id = l_rec_mail_check.cash_receipt_id
             WHERE process_code = 'PENDING'
               AND ref_mailcheck_id = l_rec_mail_check.ref_mailcheck_id;

               od_message('M','Success Message : Inserted into Temp table and Updated Hold Table');
         ELSE
            ln_error_records := ln_error_records +1;
            od_message('M','Error Message : Error while Inserting into temp table or updating Hold Table');
         END IF; -- lc_invalid_rec
      END LOOP;
         od_message('M','---------------------------------------------------------------');
         od_message('M','END of processing records into refund transactions tmp table ');
         od_message('M','END '|| lc_proc_name);

         od_message('O','-------------------------------------------------');
         od_message('O','Program name     : '||gn_conc_prog_name);
         od_message('O','Request ID       : '||gn_conc_req_id);
         od_message('O','Program Run Date : '|| TO_CHAR(gd_sysdate,'DD-MON-YYYY HH24:MI:SS'));
         od_message('O','-------------------------------------------------');
         od_message('O','Total No of records Fetched               : '|| ln_total_records);
         od_message('O','Total No of records Successfully Inserted : '|| ln_success_records);
         od_message('O','Total No of records Failed Validation     : '|| ln_error_records);

   EXCEPTION
      WHEN exp_invalid_sob
      THEN
         od_message('M','---------------------------------------------------------------');
         od_message('M','Error Message : Invalid Set of Books');
         od_message('M','END '|| lc_proc_name);
      WHEN OTHERS
      THEN
            od_message('M','Error Message : '
                       || SQLCODE
                       || ':'
                       || SQLERRM);
         od_message('M','END '
                       || lc_proc_name);

   END insert_mcheck_pos_rfnd_proc;
END XX_AR_RFND_POS_PKG;
/
