create or replace PACKAGE BODY      xx_ar_pos_receipt_pkg
AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +=====================================================================================================+
-- |  Name:  XX_AR_POS_RECEIPT_PKG                                                                       |
-- |                                                                                                     |
-- |  Description:  This package creates and applies cash receipts for POS Receipts                      |
-- |                                                                                                     |
-- |    Create_Summary_Receipt       Extracts, summarizes, and creates POS Receipts                      |
-- |    Apply_Summary_Receipt        Matches, applies POS summary Receipts to Invoices / Credit Memos    |
-- |    Sync_manual_write_offs       updates custom xx_ar_pos_receipts status to match manual entries    |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         18-Mar-2011  R.Strauss            Initial version                                       |
-- | 1.1         25-Jul-2012  Adithya              Defect#19247                                          |
-- | 1.2         15-Jul-2013  Arun Pandian         Retrofitted with R12.                                 |
-- | 1.3         02-Oct-2013  Edson Morales        Re-retrofit for R12.                                  |
-- | 1.4         17-Sep-2013  R. Aldridge          Performance Defect# 27192                             |
-- | 1.5         20-feb-2013  Deepak V             Performance defect# 27868. Threading of apply_recepit |
-- |                                               Have renamed Apply_Summary_Receipt to                 |
-- |                                               Apply_Summary_Receipt_child. New prococedure          |
-- |                                               apply_summary_recepit has been added.                 |
-- | 2.0         16-Mar-2014  Edson Morales        Changes for Defect 27868                              |
-- | 3.0         04-Jul-2014  Kirubha Samuel       IF Logic added for the defect #30045 				 |
-- |												(Zero Receipt Write-Off)           				     |
-- | 4.0         15-Jul-2014  Veronica M           OMX gift card consolidation                           |
-- | 5.0         29-Aug-2014  Kirubha Samuel       IF Logic added for the defect #30045                  |
-- |												(Refund Receipt Write-Off')        				     |
-- | 5.1         21-SEP-2015  John Wilson          Modified the code as per the defect 35802             |
-- | 5.2         11-NOV-2015  Vasu Raparla          Removed Schema References for R12.2                  |
-- |5.9          30-Apr-2020  Pramod Kumar        NAIT-11880 Rev Rec Code changes
-- |5.10         24-Jul-2020  Pramod Kumar        NAIT-11880 Rev Rec Code changes on top of PROD version-Reverting to old version
-- +=====================================================================================================+
    PROCEDURE create_summary_receipt(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_pay_type    IN             VARCHAR2,
        p_debug_flag  IN             VARCHAR2)
    IS
        p_receipt_method       xx_ar_pos_receipts.receipt_method%TYPE;
        p_receipt_method_id    ar_receipt_methods.receipt_method_id%TYPE;
        x_error_message        VARCHAR2(2000)                              DEFAULT NULL;
        x_return_status        VARCHAR2(20)                                DEFAULT NULL;
        x_msg_count            NUMBER                                      DEFAULT NULL;
        x_msg_data             VARCHAR2(4000)                              DEFAULT NULL;
        x_return_flag          VARCHAR2(1)                                 DEFAULT NULL;
        lc_comments            VARCHAR2(4000)                              DEFAULT NULL;
        lc_preauthorized_flag  VARCHAR2(1)                                 DEFAULT NULL;
        lc_amount              NUMBER                                      DEFAULT NULL;
        x_seq_num              NUMBER                                      DEFAULT NULL;
        lc_rows_updt           NUMBER                                      DEFAULT NULL;
        lc_store_num           xx_ar_order_receipt_dtl.store_number%TYPE;
        x_attributes           ar_receipt_api_pub.attribute_rec_type;
        x_bank_account_id      ce_bank_accounts.bank_account_id%TYPE;
        p_start_date           DATE                                        DEFAULT NULL;
        p_end_date             DATE                                        DEFAULT NULL;
        p_cash_receipt_id      NUMBER                                      DEFAULT NULL;
        p_receipt_number       NUMBER                                      := 33;
        tot_receipt_cnt        NUMBER                                      := 0;
        tot_receipt_amt        NUMBER                                      := 0;
        tot_ar_amt             NUMBER                                      := 0;
        gc_error_loc           VARCHAR2(80)                                DEFAULT NULL;

-- ==========================================================================
-- primary cursor - Summarize POS receipts
-- ==========================================================================
        CURSOR pos_summary_cur
        IS
            SELECT   r.customer_id,
                     r.store_number,
                     TRUNC(r.receipt_date) AS receipt_date,
                     TO_DATE(   TRUNC(r.receipt_date)
                             || ' 00:00:00',
                             'DD-MON-YY HH24:MI:SS') AS rcpt_date_start,
                     TO_DATE(   TRUNC(r.receipt_date)
                             || ' 23:59:59',
                             'DD-MON-YY HH24:MI:SS') AS rcpt_date_end,
                     r.payment_type_code,
                     r.credit_card_code,
                     u.site_use_id,
                     SUBSTR(h.NAME,
                            4,
                            2) AS NAME,
                     r.currency_code,
                     COUNT(*) AS receipt_cnt,
                     SUM(r.payment_amount) AS payment_amount
            FROM     xx_ar_order_receipt_dtl r,
                     xx_ar_intstorecust_otc c,
                     hr_operating_units h,
                     hz_cust_acct_sites_all s,
                     hz_cust_site_uses_all u
            WHERE    c.cust_account_id = r.customer_id
            AND      r.org_id = h.organization_id
            AND      s.cust_account_id = c.cust_account_id
            AND      s.cust_acct_site_id = u.cust_acct_site_id
            AND      r.org_id = p_org_id
--   AND    C.CUSTOMER_TYPE          = 'I'
--   AND    C.CUSTOMER_CLASS_CODE    = 'TRADE - SH'
            AND      r.cash_receipt_id = -3
            AND      r.order_source = 'POE'
            AND      u.site_use_code = 'BILL_TO'
            AND      u.primary_flag = 'Y'
            AND      r.store_number = NVL(p_store_num,
                                          r.store_number)
            AND      r.receipt_date >= NVL(p_start_date,
                                           r.receipt_date)
            AND      r.receipt_date <= NVL(p_end_date,
                                           r.receipt_date)
            AND      r.payment_type_code = NVL(p_pay_type,
                                               r.payment_type_code)
			AND     not  exists (select 1 from oe_order_headers_all ooha, oe_order_lines_all oola 
									where ooha.ORIG_SYS_DOCUMENT_REF=r.ORIG_SYS_DOCUMENT_REF
									and  oola.header_id=ooha.header_id
									and oola.inventory_item_id in (select inventory_item_id from xx_ar_subscription_items where is_rev_rec_eligible='Y'))						
            GROUP BY r.customer_id,
                     r.store_number,
                     TRUNC(r.receipt_date),
                     r.payment_type_code,
                     r.credit_card_code,
                     u.site_use_id,
                     SUBSTR(h.NAME,
                            4,
                            2),
                     r.currency_code
            ORDER BY 1, 2, 3, 4, 5, 6, 7;
-- ==========================================================================
-- Main create summary process
-- ==========================================================================
    BEGIN
        gc_error_loc := '1000- Main Process';

        IF p_rcpt_date IS NULL
        THEN
            p_start_date := NULL;
            p_end_date := NULL;
        ELSE
            p_start_date := TO_DATE(   p_rcpt_date
                                    || ' 00:00:00',
                                    'DD-MON-YY HH24:MI:SS');
            p_end_date := TO_DATE(   p_rcpt_date
                                  || ' 23:59:59',
                                  'DD-MON-YY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                          'XX_AR_POS_RECEIPT.CREATE_SUMMARY_RECEIPT START - parameters:      ');
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 ORG_ID        = '
                          || p_org_id);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 STORE_NUMBER  = '
                          || p_store_num);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 START DATE    = '
                          || p_start_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 END DATE      = '
                          || p_end_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 PAYMENT_TYPE  = '
                          || p_pay_type);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 DEBUG_FLAG    = '
                          || p_debug_flag);
        fnd_file.put_line(fnd_file.LOG,
                          ' ');
        fnd_file.put_line(fnd_file.output,
                             '                   '
                          || 'STORE_NUMBER     '
                          || '   '
                          || 'RECEIPT_DATE     '
                          || '   '
                          || 'RECEIPT_NUMBER   '
                          || '   '
                          || 'CASH_RECEIPT_ID  '
                          || '   '
                          || 'AMOUNT'
                          || '     '
                          || 'RECEIPT_METHOD');
        gc_error_loc := '2000- Create Summary Process';

        FOR summary_rec IN pos_summary_cur
        LOOP
            IF p_debug_flag = 'Y'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'DEBUG: Processing store = '
                                  || summary_rec.store_number
                                  || ' date = '
                                  || summary_rec.receipt_date
                                  || ' payment_type = '
                                  || summary_rec.payment_type_code
                                  || ' and credit_card = '
                                  || summary_rec.credit_card_code);
            END IF;

            x_return_flag := ' ';
            p_receipt_number :=   p_receipt_number
                                + 1;

            BEGIN
                IF    summary_rec.payment_type_code = 'CASH'
                   OR summary_rec.credit_card_code = 'TELECHECK PAPER'
                THEN
                    IF summary_rec.credit_card_code = 'PAYPAL'
                    THEN
                        lc_store_num := '';
                    ELSE
                        lc_store_num := summary_rec.store_number;
                    END IF;
                ELSE
                    lc_store_num := '';
                END IF;

                SELECT r.receipt_method_id,
                       r.NAME
                INTO   p_receipt_method_id,
                       p_receipt_method
                FROM   xx_fin_translatedefinition d, xx_fin_translatevalues v, ar_receipt_methods r
                WHERE  d.translate_id = v.translate_id
                AND    d.translation_name = 'AR_POS_RECEIPT_METHODS'
                AND    r.NAME =    summary_rec.NAME
                                || v.target_value1
                                || lc_store_num
                AND    v.source_value1 = summary_rec.payment_type_code
                AND    v.source_value2 = summary_rec.credit_card_code
                AND    v.enabled_flag = 'Y'
                AND    d.enabled_flag = 'Y'
                AND    SYSDATE BETWEEN v.start_date_active AND NVL(v.end_date_active,
                                                                   SYSDATE)
                AND    SYSDATE BETWEEN r.start_date AND NVL(r.end_date,
                                                            SYSDATE);
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    x_return_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - translation not found for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' payment_type = '
                                      || summary_rec.payment_type_code
                                      || ' and credit_card = '
                                      || summary_rec.credit_card_code
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
                WHEN OTHERS
                THEN
                    x_return_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - translation unknown error for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' payment_type = '
                                      || summary_rec.payment_type_code
                                      || ' and credit_card = '
                                      || summary_rec.credit_card_code
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
            END;

            IF p_debug_flag = 'Y'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'DEBUG: RECEIPT_METHOD = '
                                  || p_receipt_method
                                  || ' RECIPT_METHOD_ID = '
                                  || p_receipt_method_id);
            END IF;

            IF x_return_flag != 'Y'
            THEN
-- ==========================================================================
-- INSERT_AR(summary_rec)
-- ==========================================================================
                gc_error_loc := '3000- Insert Summary Process';
                x_attributes.attribute7 := 'POS Summary Receipt';

                IF summary_rec.payment_amount > 0
                THEN
                    lc_comments := 'POS Summary Receipt';
                    x_attributes.attribute7 := 'POS Summary Receipt';
                    lc_amount := summary_rec.payment_amount;
                ELSE
                    IF summary_rec.payment_amount < 0
                    THEN
                        lc_comments := 'POS Summary Receipt for Refund';
                        x_attributes.attribute7 := 'POS Summary Receipt for Refund';
                        lc_amount := 0;
                    ELSE
                        lc_comments := 'POS Net Zero Summary Receipt';
                        x_attributes.attribute7 := 'POS Net Zero Summary Receipt';
                        lc_amount := 0;
                    END IF;
                END IF;

				 x_attributes.attribute14:=null; -- added by john for defect 35802
                IF (summary_rec.payment_type_code = 'CREDIT_CARD')
                THEN
                    lc_preauthorized_flag := 'Y';
                    x_attributes.attribute14 := summary_rec.credit_card_code;
                ELSE
                    lc_preauthorized_flag := 'N';
					x_attributes.attribute14 := summary_rec.credit_card_code; -- added by john for defect 35802
                END IF;

                ar_receipt_api_pub.create_cash(p_api_version =>                     1.0,
                                               p_init_msg_list =>                   fnd_api.g_true,
                                               p_commit =>                          fnd_api.g_false,
                                               p_validation_level =>                fnd_api.g_valid_level_full,
                                               x_return_status =>                   x_return_status,
                                               x_msg_count =>                       x_msg_count,
                                               x_msg_data =>                        x_msg_data,
                                               p_currency_code =>                   summary_rec.currency_code,
                                               p_amount =>                          lc_amount,
                                               p_receipt_date =>                    summary_rec.receipt_date,
                                               p_receipt_method_id =>               p_receipt_method_id,
                                               p_customer_id =>                     summary_rec.customer_id,
                                               p_customer_site_use_id =>            summary_rec.site_use_id,
                                               p_customer_receipt_reference =>      p_receipt_number,
                                               p_customer_bank_account_id =>        x_bank_account_id,
                                               p_cr_id =>                           p_cash_receipt_id,
                                               p_receipt_number =>                  p_receipt_number,
                                               p_comments =>                        lc_comments,
                                               p_called_from =>                     'E2074',
                                               -- p_preauthorized_flag           => lc_preauthorized_flag,
                                               p_attribute_rec =>                   x_attributes);

                IF p_debug_flag = 'Y'
                THEN
                    x_error_message := x_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                         'DEBUG: AR_RECEIPT_API return_status = '
                                      || x_return_status
                                      || ' msg_count = '
                                      || x_msg_count
                                      || ' msg_data = '
                                      || x_error_message);
                END IF;

                IF (x_return_status != 'S')
                THEN
                    x_return_flag := 'Y';
                    x_error_message := x_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - POS receipt AR_RECEIPT_API_PUB failed for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' receipt_method = '
                                      || p_receipt_method
                                      || ' error = '
                                      || x_return_status
                                      || ' msg = '
                                      || x_error_message);

                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_msg_data :=(   i
                                      || '. '
                                      || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                1,
                                                255) );
                        fnd_file.put_line(fnd_file.LOG,
                                             '                  '
                                          || x_msg_data);
                    END LOOP;
                ELSE
                    tot_receipt_cnt :=   tot_receipt_cnt
                                       + 1;
                    tot_receipt_amt :=   tot_receipt_amt
                                       + summary_rec.payment_amount;
                    tot_ar_amt :=   tot_ar_amt
                                  + lc_amount;
-- ==========================================================================
-- INSERT_SUMMARY(summary_rec)
-- ==========================================================================
                    gc_error_loc := '4000- Create Summary Process';

                    SELECT xx_ar_pos_receipts_s.NEXTVAL
                    INTO   x_seq_num
                    FROM   DUAL;

                    IF p_debug_flag = 'Y'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'DEBUG: Get POS seq = '
                                          || x_seq_num
                                          || ' SQLCODE = '
                                          || SQLCODE
                                          || ' SQLERRM = '
                                          || SQLERRM);
                    END IF;

                    INSERT INTO xx_ar_pos_receipts
                                (summary_pos_receipt_id,
                                 customer_id,
                                 store_number,
                                 receipt_date,
                                 receipt_method,
                                 payment_type_code,
                                 credit_card_code,
                                 receipt_type,
                                 cash_receipt_id,
                                 receipt_number,
                                 org_id,
                                 summary_count,
                                 summary_amount,
                                 unapplied_amount,
                                 status,
                                 last_update_date,
                                 last_updated_by,
                                 creation_date,
                                 created_by,
                                 last_update_login)
                    VALUES      (x_seq_num,
                                 summary_rec.customer_id,
                                 summary_rec.store_number,
                                 summary_rec.receipt_date,
                                 p_receipt_method,
                                 summary_rec.payment_type_code,
                                 summary_rec.credit_card_code,
                                 ' ',
                                 p_cash_receipt_id,
                                 TO_CHAR(p_receipt_number),
                                 p_org_id,
                                 summary_rec.receipt_cnt,
                                 summary_rec.payment_amount,
                                 summary_rec.payment_amount,
                                 'OP',
                                 SYSDATE,
                                 fnd_global.user_id,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 fnd_global.login_id);

                    IF p_debug_flag = 'Y'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'DEBUG: Insert POS SQLCODE = '
                                          || SQLCODE
                                          || ' SQLERRM = '
                                          || SQLERRM);
                    END IF;

                    IF SQLCODE != 0
                    THEN
                        x_return_flag := 'Y';
                        x_error_message := SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error - Insert summary receipt failed for store = '
                                          || summary_rec.store_number
                                          || ' date = '
                                          || summary_rec.receipt_date
                                          || ' receipt_method = '
                                          || p_receipt_method
                                          || ' SQLCODE = '
                                          || SQLCODE
                                          || ' error = '
                                          || x_error_message);
                    ELSE
-- ==========================================================================
-- UPDATE_DTLS(p_cash_receipt_id)
-- ==========================================================================
                        gc_error_loc := '5000- Update Details Process';

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: '
                                              || summary_rec.rcpt_date_start
                                              || ' '
                                              || summary_rec.rcpt_date_end);
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: DTL updt conditions, customer_id = '
                                              || summary_rec.customer_id
                                              || ' store_number = '
                                              || summary_rec.store_number
                                              || ' receipt_date = '
                                              || summary_rec.receipt_date
                                              || ' payment_type = '
                                              || summary_rec.payment_type_code
                                              || ' credit_card = '
                                              || summary_rec.payment_type_code
                                              || ' org_id = '
                                              || p_org_id);
                        END IF;

                        UPDATE xx_ar_order_receipt_dtl
                        SET cash_receipt_id = p_cash_receipt_id,
                            receipt_number = TO_CHAR(p_receipt_number),
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_global.user_id
                        WHERE  customer_id = summary_rec.customer_id
                        AND    store_number = summary_rec.store_number
                        AND    receipt_date >= summary_rec.rcpt_date_start
                        AND    receipt_date <= summary_rec.rcpt_date_end
                        AND    payment_type_code = summary_rec.payment_type_code
                        AND    credit_card_code = summary_rec.credit_card_code
                        AND    cash_receipt_id = -3
                        AND    order_source = 'POE'
                        AND    org_id = p_org_id;

                        COMMIT;

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: Update DTL SQLCODE = '
                                              || SQLCODE
                                              || ' SQLERRM = '
                                              || SQLERRM);
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: CUSTOMER_ID = '
                                              || summary_rec.customer_id
                                              || ' store_number = '
                                              || summary_rec.store_number
                                              || ' receipt_date = '
                                              || summary_rec.receipt_date
                                              || ' payment_type_code = '
                                              || summary_rec.payment_type_code
                                              || ' credit_card_code = '
                                              || summary_rec.credit_card_code
                                              || ' cash_receipt_id = '
                                              || p_cash_receipt_id);
                        END IF;

                        IF SQLCODE != 0
                        THEN
                            x_return_flag := 'Y';
                            x_error_message := SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - Update cash_receipt_id for DTLS failed for store = '
                                              || summary_rec.store_number
                                              || ' date = '
                                              || summary_rec.receipt_date
                                              || ' receipt_method = '
                                              || p_receipt_method
                                              || ' SQLCODE = '
                                              || SQLCODE
                                              || ' error = '
                                              || x_error_message);
                        ELSE
-- ==========================================================================
-- Report receipt created
-- ==========================================================================
                            fnd_file.put_line(fnd_file.LOG,
                                                 'CREATED RECEIPT =>     '
                                              || summary_rec.store_number
                                              || '          '
                                              || summary_rec.receipt_date
                                              || '           '
                                              || p_receipt_number
                                              || '           '
                                              || p_cash_receipt_id
                                              || '    '
                                              || TO_CHAR(summary_rec.payment_amount,
                                                         '999,999,999.99')
                                              || '       '
                                              || p_receipt_method);
                            fnd_file.put_line(fnd_file.output,
                                                 '                   '
                                              || summary_rec.store_number
                                              || '              '
                                              || summary_rec.receipt_date
                                              || '     '
                                              || TO_CHAR(p_receipt_number,
                                                         '999999')
                                              || '                  '
                                              || p_cash_receipt_id
                                              || '     '
                                              || TO_CHAR(summary_rec.payment_amount,
                                                         '999,999,999.99')
                                              || '   '
                                              || p_receipt_method);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        gc_error_loc := '6000- Report Totals Process';
        fnd_file.put_line(fnd_file.LOG,
                          ' ');
        fnd_file.put_line(fnd_file.LOG,
                          '     TOTALS  :');
        fnd_file.put_line(fnd_file.LOG,
                             '     RECEIPTS CREATED = '
                          || TO_CHAR(tot_receipt_cnt,
                                     '999,999,999') );
        fnd_file.put_line(fnd_file.LOG,
                             '     POS TOTAL AMOUNT = '
                          || TO_CHAR(tot_receipt_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,
                             '     AR  TOTAL AMOUNT = '
                          || TO_CHAR(tot_ar_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,
                             '     ZERO $ RECEIPTS  = '
                          || TO_CHAR(  tot_ar_amt
                                     - tot_receipt_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.output,
                          ' ');
        fnd_file.put_line(fnd_file.output,
                          '     TOTALS  :');
        fnd_file.put_line(fnd_file.output,
                             '     RECEIPTS CREATED = '
                          || TO_CHAR(tot_receipt_cnt,
                                     '999,999,999') );
        fnd_file.put_line(fnd_file.output,
                             '     POS TOTAL AMOUNT = '
                          || TO_CHAR(tot_receipt_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.output,
                             '     AR  TOTAL AMOUNT = '
                          || TO_CHAR(tot_ar_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.output,
                             '     ZERO $ RECEIPTS  = '
                          || TO_CHAR(  tot_ar_amt
                                     - tot_receipt_amt,
                                     '999,999,999.99') );
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error - Create_Summary_Receipt - Exception - Others '
                              || gc_error_loc);
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'CREATE_SUMMARY_RECEIPT',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error at OTHERS',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               'OTHERS',
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 'POS Create Receipts');
            ROLLBACK;
    END create_summary_receipt;
	
		-- +=====================================================================================================+
-- |                                                                                                     |
-- |  PROCEDURE: CREATE_APPLY_SUBSC_REVREC_RECEIPT                                                                   |
-- |                                                                                                     |
-- |  PROCESSING ORDER:                |
-- |  1. Process Credit Memo(s) to 0$ Receipts            |
-- |  2. Process remaining Credit Memo(s) to any Receipt(s)          |
-- |   only positive receipts              |
-- |  3. Process Invoice(s)               |
-- |   only positive receipts              |
-- |  4. Write Off any remaining zero sum Receipts(s)           |
-- |  5. Apply any remaining matching (netting) transactions         |
-- |                    |
-- +=====================================================================================================+

	 PROCEDURE CREATE_APPLY_SUBSC_REVREC_RCPT(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_pay_type    IN             VARCHAR2,
        p_debug_flag  IN             VARCHAR2)
    IS
        p_receipt_method       xx_ar_pos_receipts.receipt_method%TYPE;
        p_receipt_method_id    ar_receipt_methods.receipt_method_id%TYPE;
        x_error_message        VARCHAR2(2000)                              DEFAULT NULL;
        x_return_status        VARCHAR2(20)                                DEFAULT NULL;
        x_msg_count            NUMBER                                      DEFAULT NULL;
        x_msg_data             VARCHAR2(4000)                              DEFAULT NULL;
        x_return_flag          VARCHAR2(1)                                 DEFAULT NULL;
        lc_comments            VARCHAR2(4000)                              DEFAULT NULL;
        lc_preauthorized_flag  VARCHAR2(1)                                 DEFAULT NULL;
        lc_amount              NUMBER                                      DEFAULT NULL;
        x_seq_num              NUMBER                                      DEFAULT NULL;
        lc_rows_updt           NUMBER                                      DEFAULT NULL;
        lc_store_num           xx_ar_order_receipt_dtl.store_number%TYPE;
        x_attributes           ar_receipt_api_pub.attribute_rec_type;
        x_bank_account_id      ce_bank_accounts.bank_account_id%TYPE;
        p_start_date           DATE                                        DEFAULT NULL;
        p_end_date             DATE                                        DEFAULT NULL;
        p_cash_receipt_id      NUMBER                                      DEFAULT NULL;
        p_receipt_number       NUMBER                                      := 53;
        tot_receipt_cnt        NUMBER                                      := 0;
        tot_receipt_amt        NUMBER                                      := 0;
        tot_ar_amt             NUMBER                                      := 0;
        gc_error_loc           VARCHAR2(80)                                DEFAULT NULL;
        --QC36905
        p_source_value3        VARCHAR2(1);
        p_target_value1        VARCHAR2(20);
		l_trx_number             ra_customer_trx_all.trx_number%TYPE;
		l_customer_trx_id        ra_customer_trx_all.customer_trx_id%TYPE;
		l_amount_due_remaining    NUMBER;
		l_inv_status             ar_payment_schedules_all.status%TYPE;

-- ==========================================================================
-- primary cursor - Summarize POS receipts
-- ==========================================================================
        CURSOR pos_subsc_summary_cur
        IS
           
			 SELECT    r.orig_sys_document_ref,
			 r.customer_id,
                  r.store_number,
                  TRUNC(r.receipt_date) AS receipt_date,
                  TO_DATE(   TRUNC(r.receipt_date)
                          || ' 00:00:00',
                          'DD-MON-YY HH24:MI:SS') AS rcpt_date_start,
                  TO_DATE(   TRUNC(r.receipt_date)
                          || ' 23:59:59',
                          'DD-MON-YY HH24:MI:SS') AS rcpt_date_end,
                  r.payment_type_code,
                  r.credit_card_code,
                  u.site_use_id,
                  SUBSTR(h.NAME,
                         4,
                         2) AS NAME,
                  r.currency_code,
                  COUNT(*) AS receipt_cnt,
                  SUM(r.payment_amount) AS payment_amount
            FROM     xx_ar_order_receipt_dtl r,
                     xx_ar_intstorecust_otc c,
                     hr_operating_units h,
                     hz_cust_acct_sites_all s,
                     hz_cust_site_uses_all u
            WHERE    c.cust_account_id = r.customer_id
            AND      r.org_id = h.organization_id
            AND      s.cust_account_id = c.cust_account_id
            AND      s.cust_acct_site_id = u.cust_acct_site_id
            AND      r.org_id = p_org_id
--   AND    C.CUSTOMER_TYPE          = 'I'
--   AND    C.CUSTOMER_CLASS_CODE    = 'TRADE - SH'
            AND      r.cash_receipt_id = -3
            AND      r.order_source = 'POE'
            AND      u.site_use_code = 'BILL_TO'
            AND      u.primary_flag = 'Y'
            AND      r.store_number = NVL(p_store_num,
                                          r.store_number)
            AND      r.receipt_date >= NVL(p_start_date,
                                           r.receipt_date)
            AND      r.receipt_date <= NVL(p_end_date,
                                           r.receipt_date)
            AND      r.payment_type_code = NVL(p_pay_type,
                                               r.payment_type_code)
			and  exists (select 1 from oe_order_headers_all ooha, oe_order_lines_all oola 
									where ooha.ORIG_SYS_DOCUMENT_REF=r.ORIG_SYS_DOCUMENT_REF
									and  oola.header_id=ooha.header_id
									and oola.inventory_item_id in (select inventory_item_id from xx_ar_subscription_items where is_rev_rec_eligible='Y'))
            GROUP BY r.customer_id,
                     r.store_number,
                     TRUNC(r.receipt_date),
                     r.payment_type_code,
                     r.credit_card_code,
                     u.site_use_id,
                     SUBSTR(h.NAME,
                            4,
                            2),
                     r.currency_code,
					 r.orig_sys_document_ref
            ORDER BY 1, 2, 3, 4, 5, 6, 7;
-- ==========================================================================
-- Main create summary process
-- ==========================================================================
    BEGIN
        gc_error_loc := '1000- Main Process';

        IF p_rcpt_date IS NULL
        THEN
            p_start_date := NULL;
            p_end_date := NULL;
        ELSE
            p_start_date := TO_DATE(   p_rcpt_date
                                    || ' 00:00:00',
                                    'DD-MON-YY HH24:MI:SS');
            p_end_date := TO_DATE(   p_rcpt_date
                                  || ' 23:59:59',
                                  'DD-MON-YY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG,'XX_AR_POS_RECEIPT.CREATE_SUMMARY_RECEIPT START - parameters:      ');
        fnd_file.put_line(fnd_file.LOG,'                                                 ORG_ID        = '|| p_org_id);
        fnd_file.put_line(fnd_file.LOG,'                                                 STORE_NUMBER  = '|| p_store_num);
        fnd_file.put_line(fnd_file.LOG,'                                                 START DATE    = '|| p_start_date);
        fnd_file.put_line(fnd_file.LOG,'                                                 END DATE      = '|| p_end_date);
        fnd_file.put_line(fnd_file.LOG,'                                                 PAYMENT_TYPE  = '|| p_pay_type);
        fnd_file.put_line(fnd_file.LOG,'                                                 DEBUG_FLAG    = '|| p_debug_flag);
        fnd_file.put_line(fnd_file.LOG,' ');
        fnd_file.put_line(fnd_file.output,
                             '                   '
                          || 'STORE_NUMBER     '
                          || '   '
                          || 'RECEIPT_DATE     '
                          || '   '
                          || 'RECEIPT_NUMBER   '
                          || '   '
                          || 'CASH_RECEIPT_ID  '
                          || '   '
                          || 'AMOUNT'
                          || '     '
                          || 'RECEIPT_METHOD');
        gc_error_loc := '2000- Create Summary Process';

        FOR summary_rec IN pos_subsc_summary_cur
        LOOP
            IF p_debug_flag = 'Y'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'DEBUG: Processing store = '
                                  || summary_rec.store_number
                                  || ' date = '
                                  || summary_rec.receipt_date
                                  || ' payment_type = '
                                  || summary_rec.payment_type_code
                                  || ' and credit_card = '
                                  || summary_rec.credit_card_code);
            END IF;

            x_return_flag := ' ';
            p_receipt_number :=   p_receipt_number
                                + 1;
                                
           --QC36905
           BEGIN
              --Get the source_value3 value 
              SELECT  v.source_Value3, v.target_value1
                INTO  p_source_value3, p_target_value1
                FROM  xx_fin_translatedefinition d, xx_fin_translatevalues v
              WHERE  d.translate_id = v.translate_id
                 AND  d.translation_name = 'AR_POS_RECEIPT_METHODS'
                 AND  v.source_value1 = summary_rec.payment_type_code
                 AND  v.source_value2 = summary_rec.credit_card_code
                 AND  v.enabled_flag = 'Y'
                 AND  d.enabled_flag = 'Y'
                 AND  SYSDATE BETWEEN v.start_date_active AND NVL(v.end_date_active, SYSDATE);
              --
              IF p_debug_flag = 'Y' THEN
                 fnd_file.put_line(fnd_file.LOG,'DEBUG: AR_POS_RECEIPT_METHODS.Source Value3 : '||p_source_value3 || '  Target_value1' ||p_target_value1);
              END IF;
              IF p_source_value3 = 'Y' THEN
                  p_receipt_method := summary_rec.NAME || p_target_value1 || summary_rec.store_number;
                  IF p_debug_flag = 'Y' THEN
                     fnd_file.put_line(fnd_file.LOG,'DEBUG: p_receipt_method : '||p_receipt_method);   
                  END IF;
              ELSE
                 p_receipt_method := summary_rec.NAME || p_target_value1 ;
                 IF p_debug_flag = 'Y' THEN
                     fnd_file.put_line(fnd_file.LOG,'DEBUG: In else part p_receipt_method : '||p_receipt_method);
                 END IF;
              END IF;
           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                  x_return_flag := 'Y';
                  x_error_message := SQLERRM;
                  fnd_file.put_line(fnd_file.LOG,
                                       'Error - Unable to derive store number flag from translations for store = '
                                    || summary_rec.store_number
                                    || ' date = '
                                    || summary_rec.receipt_date
                                    || ' payment_type = '
                                    || summary_rec.payment_type_code
                                    || ' and credit_card = '
                                    || summary_rec.credit_card_code
                                    || ' SQLCODE = '
                                    || SQLCODE
                                    || ' error = '
                                    || x_error_message);
              WHEN OTHERS
              THEN
                  x_return_flag := 'Y';
                  x_error_message := SQLERRM;
                  fnd_file.put_line(fnd_file.LOG,
                                       'Error - Unable to derive store number flag from translations for store = '
                                    || summary_rec.store_number
                                    || ' date = '
                                    || summary_rec.receipt_date
                                    || ' payment_type = '
                                    || summary_rec.payment_type_code
                                    || ' and credit_card = '
                                    || summary_rec.credit_card_code
                                    || ' SQLCODE = '
                                    || SQLCODE
                                    || ' error = '
                                    || x_error_message);
          END;

            BEGIN

                SELECT r.receipt_method_id
                INTO   p_receipt_method_id
                FROM   ar_receipt_methods r
                WHERE  r.NAME =    p_receipt_method
                AND    SYSDATE BETWEEN r.start_date AND NVL(r.end_date,
                                                            SYSDATE);
                IF p_debug_flag = 'Y' THEN
                   fnd_file.put_line(fnd_file.LOG,'DEBUG: Getting p_receipt_method_id : '||p_receipt_method_id); 
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    x_return_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - Receipt Method not found for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' payment_type = '
                                      || summary_rec.payment_type_code
                                      || ' and credit_card = '
                                      || summary_rec.credit_card_code
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
                WHEN OTHERS
                THEN
                    x_return_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - Receipt Method Not found-unknown error for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' payment_type = '
                                      || summary_rec.payment_type_code
                                      || ' and credit_card = '
                                      || summary_rec.credit_card_code
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
            END;

            IF p_debug_flag = 'Y'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'DEBUG: RECEIPT_METHOD = '
                                  || p_receipt_method
                                  || ' RECIPT_METHOD_ID = '
                                  || p_receipt_method_id);
            END IF;

            IF x_return_flag != 'Y'
            THEN
-- ==========================================================================
-- INSERT_AR(summary_rec)
-- ==========================================================================
                gc_error_loc := '3000- Insert Summary Process';
                x_attributes.attribute7 := 'POS Summary Receipt';

                IF summary_rec.payment_amount > 0
                THEN
                    lc_comments := 'POS Summary Receipt';
                    x_attributes.attribute7 := 'POS Summary Receipt';
                    lc_amount := summary_rec.payment_amount;
                ELSE
                    IF summary_rec.payment_amount < 0
                    THEN
                        lc_comments := 'POS Summary Receipt for Refund';
                        x_attributes.attribute7 := 'POS Summary Receipt for Refund';
                        lc_amount := 0;
                    ELSE
                        lc_comments := 'POS Net Zero Summary Receipt';
                        x_attributes.attribute7 := 'POS Net Zero Summary Receipt';
                        lc_amount := 0;
                    END IF;
                END IF;

				 x_attributes.attribute14:=null; -- added by john for defect 35802
                IF (summary_rec.payment_type_code = 'CREDIT_CARD')
                THEN
                    lc_preauthorized_flag := 'Y';
                    x_attributes.attribute14 := summary_rec.credit_card_code;
                ELSE
                    lc_preauthorized_flag := 'N';
					x_attributes.attribute14 := summary_rec.credit_card_code; -- added by john for defect 35802
                END IF;

                ar_receipt_api_pub.create_cash(p_api_version =>                     1.0,
                                               p_init_msg_list =>                   fnd_api.g_true,
                                               p_commit =>                          fnd_api.g_false,
                                               p_validation_level =>                fnd_api.g_valid_level_full,
                                               x_return_status =>                   x_return_status,
                                               x_msg_count =>                       x_msg_count,
                                               x_msg_data =>                        x_msg_data,
                                               p_currency_code =>                   summary_rec.currency_code,
                                               p_amount =>                          lc_amount,
                                               p_receipt_date =>                    summary_rec.receipt_date,
                                               p_receipt_method_id =>               p_receipt_method_id,
                                               p_customer_id =>                     summary_rec.customer_id,
                                               p_customer_site_use_id =>            summary_rec.site_use_id,
                                               p_customer_receipt_reference =>      'RCT'||summary_rec.orig_sys_document_ref,--p_receipt_number, 
                                               p_customer_bank_account_id =>        x_bank_account_id,
                                               p_cr_id =>                           p_cash_receipt_id,
                                               p_receipt_number =>                  'RCT'||summary_rec.orig_sys_document_ref, --p_receipt_number,
                                               p_comments =>                        lc_comments,
                                               p_called_from =>                     'E2074',
                                               -- p_preauthorized_flag           => lc_preauthorized_flag,
                                               p_attribute_rec =>                   x_attributes);

                IF p_debug_flag = 'Y'
                THEN
                    x_error_message := x_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                         'DEBUG: AR_RECEIPT_API return_status = '
                                      || x_return_status
                                      || ' msg_count = '
                                      || x_msg_count
                                      || ' msg_data = '
                                      || x_error_message);
                END IF;

                IF (x_return_status != 'S')
                THEN
                    x_return_flag := 'Y';
                    x_error_message := x_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - POS receipt AR_RECEIPT_API_PUB failed for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' receipt_method = '
                                      || p_receipt_method
                                      || ' error = '
                                      || x_return_status
                                      || ' msg = '
                                      || x_error_message);

                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_msg_data :=(   i
                                      || '. '
                                      || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                1,
                                                255) );
                        fnd_file.put_line(fnd_file.LOG,
                                             '                  '
                                          || x_msg_data);
                    END LOOP;
                ELSE
                    tot_receipt_cnt :=   tot_receipt_cnt
                                       + 1;
                    tot_receipt_amt :=   tot_receipt_amt
                                       + summary_rec.payment_amount;
                    tot_ar_amt :=   tot_ar_amt
                                  + lc_amount;
-- ==========================================================================
-- Apply receipt created to AR Invoice
-- ==========================================================================								  
		 BEGIN
		 

		 l_amount_due_remaining := NULL;
		 l_trx_number          := NULL;
		 l_customer_trx_id     := NULL;
		 
		 		 
            SELECT rct.trx_number,rct.customer_trx_id,arp.amount_due_remaining,arp.status
              INTO l_trx_number,l_customer_trx_id,l_amount_due_remaining,l_inv_status
              FROM ra_customer_trx_all rct,
                  ar_payment_schedules_all arp
            WHERE 1=1
			  AND rct.org_id=p_org_id
              AND rct.trx_number=summary_rec.orig_sys_document_ref
              AND rct.customer_trx_id=arp.customer_trx_id
			  AND arp.status='OP'
			 -- AND rct.trx_date >= p_start_date
              --AND rct.trx_date <= p_start_date
              AND rct.attribute_category = 'POS'
              --AND rct.interface_header_attribute3 = 'SUMMARY'
			  ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN 
                l_trx_number:=NULL;
                l_customer_trx_id:=NULL;
              WHEN OTHERS THEN 
                l_trx_number:=NULL;
                l_customer_trx_id:=NULL;
         END;
        FND_FILE.PUT_LINE(FND_FILE.log,'Transaction Number:'||l_trx_number);
        FND_FILE.PUT_LINE(FND_FILE.log,'Transaction Status:'||l_inv_status);	


							AR_RECEIPT_API_PUB.APPLY
                            (p_api_version                      => 1.0,
                             p_init_msg_list                    => fnd_api.g_true,
                             p_commit                           => fnd_api.g_false,
                             p_validation_level                 => fnd_api.g_valid_level_full,
                             x_return_status                    => x_return_status,
                             x_msg_count                        => x_msg_count,
                             x_msg_data                         => x_msg_data,
                             p_cash_receipt_id                  => p_cash_receipt_id,
                             p_customer_trx_id                  => l_customer_trx_id,
                           --  p_installment                      => i_record.terms_sequence_number,
                           --  p_applied_payment_schedule_id      => i_record.payment_schedule_id,
                             p_show_closed_invoices              => 'Y',
                             p_amount_applied                   => l_amount_due_remaining,
                             p_discount                         => NULL,
                             p_apply_date                       => sysdate
                           );
                  
              IF x_return_status = 'S' THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt Applied to transaction successfully: '||l_customer_trx_id); 
                          
               ELSE
                          IF (x_return_status != 'S')
                THEN
                    x_return_flag := 'Y';
                    x_error_message := x_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - POS receipt AR_RECEIPT_API_PUB failed for store = '
                                      || summary_rec.store_number
                                      || ' date = '
                                      || summary_rec.receipt_date
                                      || ' receipt_method = '
                                      || p_receipt_method
                                      || ' error = '
                                      || x_return_status
                                      || ' msg = '
                                      || x_error_message);

                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_msg_data :=(   i
                                      || '. '
                                      || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                1,
                                                255) );
                        fnd_file.put_line(fnd_file.LOG,
                                             '                  '
                                          || x_msg_data);
                    END LOOP;
                        
                        END IF;                   
              END IF; --end if for S Receipt Trx Apply		
								  
								  
								  
-- ==========================================================================
-- INSERT_SUMMARY(summary_rec)
-- ==========================================================================
                    gc_error_loc := '4000- Create Summary Process';

                    SELECT xx_ar_pos_receipts_s.NEXTVAL
                    INTO   x_seq_num
                    FROM   DUAL;

                    IF p_debug_flag = 'Y'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'DEBUG: Get POS seq = '
                                          || x_seq_num
                                          || ' SQLCODE = '
                                          || SQLCODE
                                          || ' SQLERRM = '
                                          || SQLERRM);
                    END IF;
				

                    INSERT INTO xx_ar_pos_receipts
                                (summary_pos_receipt_id,
                                 customer_id,
                                 store_number,
                                 receipt_date,
                                 receipt_method,
                                 payment_type_code,
                                 credit_card_code,
                                 receipt_type,
                                 cash_receipt_id,
                                 receipt_number,
                                 org_id,
                                 summary_count,
                                 summary_amount,
                                 unapplied_amount,
                                 status,
                                 last_update_date,
                                 last_updated_by,
                                 creation_date,
                                 created_by,
                                 last_update_login)
                    VALUES      (x_seq_num,
                                 summary_rec.customer_id,
                                 summary_rec.store_number,
                                 summary_rec.receipt_date,
                                 p_receipt_method,
                                 summary_rec.payment_type_code,
                                 summary_rec.credit_card_code,
                                 ' ',
                                 p_cash_receipt_id,
                                 'RCT'||summary_rec.orig_sys_document_ref,
                                 p_org_id,
                                 summary_rec.receipt_cnt,
                                 summary_rec.payment_amount,
                                 summary_rec.payment_amount,
                                 'CL',
                                 SYSDATE,
                                 fnd_global.user_id,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 fnd_global.login_id);

                    IF p_debug_flag = 'Y'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'DEBUG: Insert POS SQLCODE = '
                                          || SQLCODE
                                          || ' SQLERRM = '
                                          || SQLERRM);
                    END IF;

                    IF SQLCODE != 0
                    THEN
                        x_return_flag := 'Y';
                        x_error_message := SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error - Insert summary receipt failed for store = '
                                          || summary_rec.store_number
                                          || ' date = '
                                          || summary_rec.receipt_date
                                          || ' receipt_method = '
                                          || p_receipt_method
                                          || ' SQLCODE = '
                                          || SQLCODE
                                          || ' error = '
                                          || x_error_message);
                    ELSE
-- ==========================================================================
-- UPDATE_DTLS(p_cash_receipt_id)
-- ==========================================================================
                        gc_error_loc := '5000- Update Details Process';

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: '
                                              || summary_rec.rcpt_date_start
                                              || ' '
                                              || summary_rec.rcpt_date_end);
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: DTL updt conditions, customer_id = '
                                              || summary_rec.customer_id
                                              || ' store_number = '
                                              || summary_rec.store_number
                                              || ' receipt_date = '
                                              || summary_rec.receipt_date
                                              || ' payment_type = '
                                              || summary_rec.payment_type_code
                                              || ' credit_card = '
                                              || summary_rec.payment_type_code
                                              || ' org_id = '
                                              || p_org_id);
                        END IF;

                        UPDATE xx_ar_order_receipt_dtl
                        SET cash_receipt_id = p_cash_receipt_id,
                            receipt_number = 'RCT'||summary_rec.orig_sys_document_ref,
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_global.user_id
                        WHERE  orig_sys_document_ref=summary_rec.orig_sys_document_ref
						and    customer_id = summary_rec.customer_id
                        AND    store_number = summary_rec.store_number
                        AND    receipt_date >= summary_rec.rcpt_date_start
                        AND    receipt_date <= summary_rec.rcpt_date_end
                        AND    payment_type_code = summary_rec.payment_type_code
                        AND    credit_card_code = summary_rec.credit_card_code
                        AND    cash_receipt_id = -3
                        AND    order_source = 'POE'
                        AND    org_id = p_org_id;

                        COMMIT;

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: Update DTL SQLCODE = '
                                              || SQLCODE
                                              || ' SQLERRM = '
                                              || SQLERRM);
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: CUSTOMER_ID = '
                                              || summary_rec.customer_id
                                              || ' store_number = '
                                              || summary_rec.store_number
                                              || ' receipt_date = '
                                              || summary_rec.receipt_date
                                              || ' payment_type_code = '
                                              || summary_rec.payment_type_code
                                              || ' credit_card_code = '
                                              || summary_rec.credit_card_code
                                              || ' cash_receipt_id = '
                                              || p_cash_receipt_id);
                        END IF;

                        IF SQLCODE != 0
                        THEN
                            x_return_flag := 'Y';
                            x_error_message := SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - Update cash_receipt_id for DTLS failed for store = '
                                              || summary_rec.store_number
                                              || ' date = '
                                              || summary_rec.receipt_date
                                              || ' receipt_method = '
                                              || p_receipt_method
                                              || ' SQLCODE = '
                                              || SQLCODE
                                              || ' error = '
                                              || x_error_message);
                        ELSE
-- ==========================================================================
-- Report receipt created
-- ==========================================================================
                            fnd_file.put_line(fnd_file.LOG,
                                                 'CREATED RECEIPT =>     '
                                              || summary_rec.store_number
                                              || '          '
                                              || summary_rec.receipt_date
                                              || '           '
                                              || p_receipt_number
                                              || '           '
                                              || p_cash_receipt_id
                                              || '    '
                                              || TO_CHAR(summary_rec.payment_amount,
                                                         '999,999,999.99')
                                              || '       '
                                              || p_receipt_method);
                            fnd_file.put_line(fnd_file.output,
                                                 '                   '
                                              || summary_rec.store_number
                                              || '              '
                                              || summary_rec.receipt_date
                                              || '     '
                                              || TO_CHAR(p_receipt_number,
                                                         '999999')
                                              || '                  '
                                              || p_cash_receipt_id
                                              || '     '
                                              || TO_CHAR(summary_rec.payment_amount,
                                                         '999,999,999.99')
                                              || '   '
                                              || p_receipt_method);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        gc_error_loc := '6000- Report Totals Process';
        fnd_file.put_line(fnd_file.LOG,' ');
        fnd_file.put_line(fnd_file.LOG,'     TOTALS  :');
        fnd_file.put_line(fnd_file.LOG,'     RECEIPTS CREATED = '|| TO_CHAR(tot_receipt_cnt,'999,999,999') );
        fnd_file.put_line(fnd_file.LOG,'     POS TOTAL AMOUNT = '|| TO_CHAR(tot_receipt_amt,'999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,'     AR  TOTAL AMOUNT = '|| TO_CHAR(tot_ar_amt,'999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,'     ZERO $ RECEIPTS  = '|| TO_CHAR(  tot_ar_amt - tot_receipt_amt,'999,999,999.99') );
        fnd_file.put_line(fnd_file.output,' ');
        fnd_file.put_line(fnd_file.output,'     TOTALS  :');
        fnd_file.put_line(fnd_file.output,'     RECEIPTS CREATED = '|| TO_CHAR(tot_receipt_cnt,'999,999,999') );
        fnd_file.put_line(fnd_file.output,'     POS TOTAL AMOUNT = '|| TO_CHAR(tot_receipt_amt,'999,999,999.99') );
        fnd_file.put_line(fnd_file.output,'     AR  TOTAL AMOUNT = '|| TO_CHAR(tot_ar_amt,'999,999,999.99') );
        fnd_file.put_line(fnd_file.output, '     ZERO $ RECEIPTS  = '|| TO_CHAR(  tot_ar_amt - tot_receipt_amt,'999,999,999.99') );
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,'Error - Create_Summary_Receipt - Exception - Others '|| gc_error_loc);
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'CREATE_SUMMARY_RECEIPT',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error at OTHERS',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               'OTHERS',
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 'POS Create Receipts');
            ROLLBACK;
    END CREATE_APPLY_SUBSC_REVREC_RCPT;

-- +=====================================================================================================+
-- |                                                                                                     |
-- |  PROCEDURE: APPLY_SUMMARY_RECEIPT                                                                   |
-- |                                                                                                     |
-- |  PROCESSING ORDER:                |
-- |  1. Process Credit Memo(s) to 0$ Receipts            |
-- |  2. Process remaining Credit Memo(s) to any Receipt(s)          |
-- |   only positive receipts              |
-- |  3. Process Invoice(s)               |
-- |   only positive receipts              |
-- |  4. Write Off any remaining zero sum Receipts(s)           |
-- |  5. Apply any remaining matching (netting) transactions         |
-- |                    |
-- +=====================================================================================================+
    PROCEDURE apply_summary_receipt_child(
        errbuf              OUT NOCOPY     VARCHAR2,
        retcode             OUT NOCOPY     NUMBER,
        p_org_id            IN             NUMBER,
        p_rcpt_date         IN             VARCHAR2,
        p_tolerance         IN             NUMBER,
        p_debug_flag        IN             VARCHAR2,
        p_min_store_number  IN             VARCHAR2,
        p_max_store_number  IN             VARCHAR2)
    IS
        x_error_message                 VARCHAR2(2000)                                                 DEFAULT NULL;
        x_return_status                 VARCHAR2(20)                                                   DEFAULT NULL;
        x_msg_count                     NUMBER                                                         DEFAULT NULL;
        x_msg_data                      VARCHAR2(4000)                                                 DEFAULT NULL;
        x_email_flag                    VARCHAR2(1)                                                    := 'N';
        x_error_flag                    VARCHAR2(1)                                                    := 'N';
        x_return_flag                   VARCHAR2(1)                                                    DEFAULT NULL;
        lc_status                       VARCHAR2(5)                                                    DEFAULT NULL;
        lc_apply_flag                   VARCHAR2(1)                                                    DEFAULT NULL;
        lc_compl_stat                   BOOLEAN;
        x_rcpt_date                     DATE                                                           DEFAULT NULL;
        lc_customer_id                  NUMBER                                                         DEFAULT NULL;
        lc_rcpt_date_start              DATE                                                           DEFAULT NULL;
        lc_rcpt_date_end                DATE                                                           DEFAULT NULL;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE             DEFAULT NULL;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE            DEFAULT NULL;
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE           DEFAULT NULL;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE   DEFAULT NULL;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        p_start_date                    DATE                                                           DEFAULT NULL;
        p_end_date                      DATE                                                           DEFAULT NULL;
        x_receivables_trx_id            NUMBER                                                         DEFAULT NULL;
        x_payment_set_id                NUMBER                                                         DEFAULT NULL;
        lc_rcpt_trx_name                VARCHAR2(50)                                                   DEFAULT NULL;
        lc_country                      VARCHAR2(2)                                                    DEFAULT NULL;
        lc_app_attributes               ar_receipt_api_pub.attribute_rec_type;
        lr_cm_app_rec                   ar_cm_api_pub.cm_app_rec_type;
        ln_amount_applied_from          ar_receivable_applications.acctd_amount_applied_from%TYPE;
        ln_amount_applied_to            ar_receivable_applications.acctd_amount_applied_to%TYPE;
        ln_out_rec_appl_id              NUMBER                                                         := 0;
        lc_store_inv_amount             NUMBER                                                         := 0;
        lc_store_applied_amt            NUMBER                                                         := 0;
        lc_zero_dollar_amt              NUMBER                                                         := 0;
        lc_apply_amt                    NUMBER                                                         := 0;
        lc_tolerance                    NUMBER                                                         := 0;
        lc_inv_amount_remain            NUMBER                                                         := 0;
        lc_rcpt_amount_remain           NUMBER                                                         := 0;
        ln_req_id                       NUMBER                                                         DEFAULT NULL;
        lc_email_destination            VARCHAR2(200)                                                  DEFAULT NULL;
        tot_store_amt_diff              NUMBER                                                         := 0;
        tot_rcpt_applied_cnt            NUMBER                                                         := 0;
        tot_rcpt_applied_amt            NUMBER                                                         := 0;
        lc_total_unapplied_cnt          NUMBER                                                         := 0;
        lc_total_unapplied_amt          NUMBER                                                         := 0;
        gc_error_loc                    VARCHAR2(80)                                                   DEFAULT NULL;
        ln_print_option                 BOOLEAN;
        ln_instance_name                VARCHAR2(9)                                                    DEFAULT NULL;
        lc_day_of_week                  VARCHAR2(10)                                                   DEFAULT NULL;

-- ==========================================================================
-- cursor - Summarize POS receipts by Store / Date
-- ==========================================================================
        CURSOR pos_sum_rcpt_cur
        IS
            SELECT   r.customer_id,
                     r.store_number,
                     TRUNC(r.receipt_date) AS receipt_date,
                     TO_DATE(   TRUNC(r.receipt_date)
                             || ' 00:00:00',
                             'DD-MON-YY HH24:MI:SS') AS rcpt_date_start,
                     TO_DATE(   TRUNC(r.receipt_date)
                             || ' 23:59:59',
                             'DD-MON-YY HH24:MI:SS') AS rcpt_date_end,
                     SUM(r.unapplied_amount) AS unapplied_amount
            FROM     xx_ar_pos_receipts r
            WHERE    r.status = 'OP'
            AND      r.org_id = p_org_id
            AND      r.receipt_date >= NVL(p_start_date,
                                           r.receipt_date)
            AND      r.receipt_date <= NVL(p_end_date,
                                           r.receipt_date)
            AND      r.store_number BETWEEN p_min_store_number AND p_max_store_number
            GROUP BY r.customer_id, r.store_number, TRUNC(r.receipt_date);

-- ==========================================================================
-- 1. cursor - Retrieve individual POS Receipt summaries to be applied
-- ==========================================================================
        CURSOR ind_pos_sum_rcpt_cur
        IS
            SELECT   r.cash_receipt_id,
                     r.receipt_method,
                     r.receipt_number,
                     r.summary_amount,
                     r.unapplied_amount
            FROM     xx_ar_pos_receipts r
            WHERE    r.status = 'OP'
            AND      r.org_id = p_org_id
            AND      r.customer_id = lc_customer_id
            AND      r.receipt_date >= lc_rcpt_date_start
            AND      r.receipt_date <= lc_rcpt_date_end
            AND      r.unapplied_amount > 0
            ORDER BY r.unapplied_amount DESC;

        lc_receipt_row                  ind_pos_sum_rcpt_cur%ROWTYPE;

-- ==========================================================================
-- 2. cursor - Retrieve individual POS 0$ Receipt summaries to be applied
-- ==========================================================================
        CURSOR ind_pos_sum_o$_rcpt_cur
        IS
            SELECT   r.cash_receipt_id,
                     r.receipt_number,
                     r.payment_type_code,
                     r.credit_card_code,
                     r.receipt_method,
                     r.summary_amount,
                     r.unapplied_amount
            FROM     xx_ar_pos_receipts r
            WHERE    r.status = 'OP'
            AND      r.org_id = p_org_id
            AND      r.customer_id = lc_customer_id
            AND      r.receipt_date >= lc_rcpt_date_start
            AND      r.receipt_date <= lc_rcpt_date_end
            AND      r.unapplied_amount < 0
            ORDER BY r.unapplied_amount DESC;

-- ==========================================================================
-- 3. cursor - Retrieve individual POS INV summaries to be applied
-- ==========================================================================
        CURSOR ind_pos_sum_inv_cur
        IS
            SELECT   p.customer_trx_id,
                     t.customer_reference,
                     p.amount_due_remaining
            FROM     ra_customer_trx_all t, ar_payment_schedules_all p, ra_cust_trx_types_all tt
            WHERE    t.customer_trx_id = p.customer_trx_id
            AND      p.customer_id = lc_customer_id
            AND      p.trx_date >= lc_rcpt_date_start
            AND      p.trx_date <= lc_rcpt_date_end
            AND      t.cust_trx_type_id = tt.cust_trx_type_id
            AND      t.org_id = p_org_id
            AND      t.attribute_category = 'POS'
            AND      t.interface_header_attribute3 = 'SUMMARY'
            AND      p.status = 'OP'
            AND      tt.TYPE = 'INV'
            ORDER BY p.amount_due_remaining DESC;

        lc_invoice_row                  ind_pos_sum_inv_cur%ROWTYPE;

-- ==========================================================================
-- 4. cursor - Retrieve individual POS CM summaries to be applied
-- ==========================================================================
        CURSOR ind_pos_sum_cm_cur
        IS
            SELECT   p.customer_trx_id,
                     t.customer_reference,
                     p.amount_due_remaining
            FROM     ra_customer_trx_all t, ar_payment_schedules_all p, ra_cust_trx_types_all tt
            WHERE    t.customer_trx_id = p.customer_trx_id
            AND      p.customer_id = lc_customer_id
            AND      p.trx_date >= lc_rcpt_date_start
            AND      p.trx_date <= lc_rcpt_date_end
            AND      t.cust_trx_type_id = tt.cust_trx_type_id
            AND      t.org_id = p_org_id
            AND      t.attribute_category = 'POS'
            AND      t.interface_header_attribute3 = 'SUMMARY'
            AND      p.status = 'OP'
            AND      tt.TYPE = 'CM'
            ORDER BY p.amount_due_remaining ASC;

-- ==========================================================================
-- 5. cursor - Retrieve POS net 0$ Receipt summaries to be written off
-- ==========================================================================
        CURSOR ind_pos_net_zero_sum_rcpt_cur
        IS
            SELECT   r.cash_receipt_id,
                     r.receipt_number,
                     r.payment_type_code,
                     r.credit_card_code,
                     r.receipt_method,
                     r.summary_amount,
                     r.unapplied_amount
            FROM     xx_ar_pos_receipts r
            WHERE    r.status = 'OP'
            AND      r.org_id = p_org_id
            AND      r.customer_id = lc_customer_id
            AND      r.receipt_date >= lc_rcpt_date_start
            AND      r.receipt_date <= lc_rcpt_date_end
            AND      r.summary_amount = 0
            AND      r.status = 'OP'
            ORDER BY r.unapplied_amount DESC;

-- ==========================================================================
-- 6. cursor - Retrieve remaining matching POS transactions to be applied
-- ==========================================================================
        CURSOR ind_pos_match_trans_cur
        IS
            SELECT   p1.customer_trx_id AS cm_customer_trx_id,
                     p2.customer_trx_id AS inv_customer_trx_id,
                     p1.amount_due_remaining AS cm_amount_due_remaining,
                     p2.amount_due_remaining AS inv_amount_due_remaining
            FROM     ra_customer_trx_all t1,
                     ra_customer_trx_all t2,
                     ar_payment_schedules_all p1,
                     ar_payment_schedules_all p2,
                     ra_cust_trx_types_all tt1,
                     ra_cust_trx_types_all tt2
            WHERE    NOT EXISTS(
                         SELECT '1'
                         FROM   xx_ar_pos_receipts r
                         WHERE  r.org_id = p_org_id
                         AND    r.customer_id = lc_customer_id
                         AND    r.receipt_date >= lc_rcpt_date_start
                         AND    r.receipt_date <= lc_rcpt_date_end
                         AND    r.status = 'OP')
            AND      t1.customer_trx_id = p1.customer_trx_id
            AND      t2.customer_trx_id = p2.customer_trx_id
            AND      p1.customer_id = lc_customer_id
            AND      p2.customer_id = lc_customer_id
            AND      t1.cust_trx_type_id = tt1.cust_trx_type_id
            AND      t2.cust_trx_type_id = tt2.cust_trx_type_id
            AND      p1.trx_date >= lc_rcpt_date_start
            AND      p1.trx_date <= lc_rcpt_date_end
            AND      p2.trx_date >= lc_rcpt_date_start
            AND      p2.trx_date <= lc_rcpt_date_end
            AND      t1.org_id = p_org_id
            AND      t2.org_id = p_org_id
            AND      TRUNC(p1.trx_date) = TRUNC(p2.trx_date)
            AND      t1.attribute_category = 'POS'
            AND      t2.attribute_category = 'POS'
            AND      t1.interface_header_attribute3 = 'SUMMARY'
            AND      t2.interface_header_attribute3 = 'SUMMARY'
            AND      p1.status = 'OP'
            AND      p2.status = 'OP'
            AND      tt1.TYPE = 'CM'
            AND      tt2.TYPE = 'INV'
            AND      p1.amount_due_remaining =(  -1
                                               * p2.amount_due_remaining)
            ORDER BY p1.amount_due_remaining DESC;

-- ==========================================================================
-- 7. cursor - Retrieve stand-alone matching POS transactions to be applied
-- ==========================================================================
        CURSOR ind_pos_stand_alone_cur
        IS
            SELECT   rcpt.store_number,
                     rcpt.receipt_date,
                     cm.CLASS AS cm_class,
                     cm.amount_due_remaining AS cm_amount_due_remaining,
                     cm.customer_trx_id AS cm_customer_trx_id,
                     cm.payment_schedule_id AS cm_payment_schedule_id,
                     inv.CLASS AS inv_class,
                     inv.amount_due_remaining AS inv_amount_due_remaining,
                     inv.customer_trx_id AS inv_customer_trx_id,
                     inv.payment_schedule_id AS inv_payment_schedule_id
            FROM     (SELECT   SUBSTR(c.account_name,
                                      1,
                                      6) AS store_number,
                               TRUNC(t.trx_date) AS trx_date,
                               p.payment_schedule_id,
                               p.CLASS,
                               p.status,
                               t.customer_trx_id,
                               p.amount_due_original,
                               p.amount_due_remaining
                      FROM     ra_customer_trx_all t,
                               ar_payment_schedules_all p,
                               xx_ar_intstorecust_otc s,
                               hz_cust_accounts_all c
                      WHERE    t.customer_trx_id = p.customer_trx_id
                      AND      t.sold_to_customer_id = s.cust_account_id
                      AND      s.account_number = c.account_number
                      AND      t.attribute_category = 'POS'
                      AND      t.interface_header_attribute3 = 'SUMMARY'
                      AND      p.CLASS = 'CM'
                      AND      p.status = 'OP'
                      AND      TRUNC(t.trx_date) >   SYSDATE
                                                   - 45
                      AND      p.amount_due_remaining <> 0
                      ORDER BY c.account_name, t.trx_date) cm,

--*
                     (SELECT   SUBSTR(c.account_name,
                                      1,
                                      6) AS store_number,
                               TRUNC(t.trx_date) AS trx_date,
                               p.payment_schedule_id,
                               p.CLASS,
                               p.status,
                               t.customer_trx_id,
                               p.amount_due_original,
                               p.amount_due_remaining
                      FROM     ra_customer_trx_all t,
                               ar_payment_schedules_all p,
                               xx_ar_intstorecust_otc s,
                               hz_cust_accounts_all c
                      WHERE    t.customer_trx_id = p.customer_trx_id
                      AND      t.sold_to_customer_id = s.cust_account_id
                      AND      s.account_number = c.account_number
                      AND      t.attribute_category = 'POS'
                      AND      t.interface_header_attribute3 = 'SUMMARY'
                      AND      p.CLASS = 'INV'
                      AND      p.status = 'OP'
                      AND      TRUNC(t.trx_date) >   SYSDATE
                                                   - 45
                      AND      p.amount_due_remaining <> 0
                      ORDER BY c.account_name, t.trx_date) inv,

--*
                     (SELECT   r.store_number,
                               TRUNC(r.receipt_date) AS receipt_date,
                               SUM(r.unapplied_amount)
                      FROM     xx_ar_pos_receipts r
                      WHERE    TRUNC(r.receipt_date) >   SYSDATE
                                                       - 45
                      GROUP BY r.store_number, TRUNC(r.receipt_date)
                      HAVING   SUM(r.unapplied_amount) = 0
                      ORDER BY r.store_number, TRUNC(r.receipt_date) ) rcpt
--*
            WHERE    cm.store_number = inv.store_number
            AND      inv.store_number = rcpt.store_number
            AND      TRUNC(cm.trx_date) = TRUNC(inv.trx_date)
            AND      TRUNC(inv.trx_date) = TRUNC(rcpt.receipt_date)
            AND        cm.amount_due_remaining
                     + inv.amount_due_remaining = 0
            ORDER BY rcpt.store_number, rcpt.receipt_date;
-- ==========================================================================
-- Main Apply Summary process
-- ==========================================================================
    BEGIN
        gc_error_loc := '1000- Main Process';

        IF p_rcpt_date IS NULL
        THEN
            p_start_date := NULL;
            p_end_date := NULL;
        ELSE
            p_start_date := TO_DATE(   p_rcpt_date
                                    || ' 00:00:00',
                                    'DD-MON-YY HH24:MI:SS');
            p_end_date := TO_DATE(   p_rcpt_date
                                  || ' 23:59:59',
                                  'DD-MON-YY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                          'XX_AR_POS_RECEIPT.APPLY_SUMMARY_RECEIPT START - parameters:      ');
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 ORG_ID        = '
                          || p_org_id);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 START DATE    = '
                          || p_start_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 END DATE      = '
                          || p_end_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 DEBUG_FLAG    = '
                          || p_debug_flag);
        fnd_file.put_line(fnd_file.LOG,
                             '                                             MIN STORE_NUMBER  = '
                          || p_min_store_number);
        fnd_file.put_line(fnd_file.LOG,
                             '                                             MAX STORE_NUMBER  = '
                          || p_max_store_number);

        BEGIN
            SELECT SUBSTR(NAME,
                          4,
                          2)
            INTO   lc_country
            FROM   hr_operating_units
            WHERE  organization_id = p_org_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Warning - no Country code found in HZ_OPERATING_UNITS for '
                                  || p_org_id);
        END;

        fnd_file.put_line(fnd_file.output,
                             'Operating Unit: '
                          || lc_country
                          || '                POS Apply Summary Receipts                '
                          || '                DATE: '
                          || TO_CHAR(SYSDATE,
                                     'DD-MON-YY HH24:MM') );
        fnd_file.put_line(fnd_file.output,
                          ' ');
        fnd_file.put_line(fnd_file.output,
                             '        '
                          || 'STORE_NUMBER   '
                          || 'RECEIPT_DATE        '
                          || 'RECEIPT_NUMBER        '
                          || 'AMOUNT              '
                          || 'DESCRIPTION');
        fnd_file.put_line(fnd_file.output,
                          '        ');
        fnd_file.put_line(fnd_file.LOG,
                             '                                                 COUNTRY       = '
                          || lc_country);
        fnd_file.put_line(fnd_file.LOG,
                          ' ');

        BEGIN
            SELECT NAME
            INTO   ln_instance_name
            FROM   v$database;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Warning - instance name not found in v$database ');
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '                                                 INSTANCE      = '
                          || ln_instance_name);
        fnd_file.put_line(fnd_file.LOG,
                          ' ');

        BEGIN
            SELECT v.target_value1
            INTO   lc_tolerance
            FROM   xx_fin_translatedefinition d, xx_fin_translatevalues v
            WHERE  d.translate_id = v.translate_id
            AND    d.translation_name = 'APPLY RECEIPTS TOLERANCE'
            AND    v.enabled_flag = 'Y'
            AND    d.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN v.start_date_active AND NVL(v.end_date_active,
                                                               SYSDATE);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lc_tolerance := 0;
                fnd_file.put_line(fnd_file.LOG,
                                  'Warning - no Tolerance found in translations tables');
        END;

        IF p_tolerance > 0
        THEN
            lc_tolerance := p_tolerance;
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                             'Receipt / Transaction Tolerance = '
                          || lc_tolerance);
-- ==========================================================================
-- Main Loop - by Store / Date
-- ==========================================================================
        gc_error_loc := '2000- Main Store / Date process';

        FOR store_rec IN pos_sum_rcpt_cur
        LOOP
            fnd_file.put_line(fnd_file.LOG,
                                 'Processing store = '
                              || store_rec.store_number
                              || ' date = '
                              || store_rec.receipt_date);

            BEGIN
                lc_customer_id := store_rec.customer_id;
                lc_rcpt_date_start := store_rec.rcpt_date_start;
                lc_rcpt_date_end := store_rec.rcpt_date_end;
                lc_store_inv_amount := 0;
                x_error_flag := 'N';

                -- 1.4 - Modified query to start from payment schedules
                SELECT NVL(SUM(p.amount_due_remaining),
                           0)
                INTO   lc_store_inv_amount
                FROM   ra_customer_trx_all t, ar_payment_schedules_all p
                WHERE  p.customer_id = store_rec.customer_id
                AND    p.status = 'OP'
                AND    t.customer_trx_id = p.customer_trx_id
                AND    t.trx_date >= store_rec.rcpt_date_start
                AND    t.trx_date <= store_rec.rcpt_date_end
                AND    t.attribute_category = 'POS'
                AND    t.interface_header_attribute3 = 'SUMMARY';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    x_error_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - no store invoice data found for store = '
                                      || store_rec.store_number
                                      || ' date = '
                                      || store_rec.receipt_date
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
                WHEN OTHERS
                THEN
                    x_error_flag := 'Y';
                    x_error_message := SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error - retrieving store invoice data for store = '
                                      || store_rec.store_number
                                      || ' date = '
                                      || store_rec.receipt_date
                                      || ' SQLCODE = '
                                      || SQLCODE
                                      || ' error = '
                                      || x_error_message);
            END;

            IF p_debug_flag = 'Y'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'DEBUG: Store Receipts = '
                                  || store_rec.unapplied_amount
                                  || ' Store INV /CM = '
                                  || lc_store_inv_amount);
            END IF;

-- ==========================================================================
-- Are Store's receipts and invoices within tolerances ?
-- ==========================================================================
            IF lc_store_inv_amount > store_rec.unapplied_amount
            THEN
                tot_store_amt_diff := ABS(  lc_store_inv_amount
                                          - store_rec.unapplied_amount);
            ELSE
                tot_store_amt_diff := ABS(  store_rec.unapplied_amount
                                          - lc_store_inv_amount);
            END IF;

            IF lc_tolerance > tot_store_amt_diff
            THEN
                IF p_debug_flag = 'Y'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'DEBUG: Amounts are within tolerances for store = '
                                      || store_rec.store_number
                                      || ' date = '
                                      || store_rec.receipt_date
                                      || ' receipt amount = '
                                      || store_rec.unapplied_amount
                                      || ' INV / CM amount = '
                                      || lc_store_inv_amount);
                END IF;

                lc_store_applied_amt := 0;
-- ==========================================================================
-- First  - process Credit Memo(s) to 0$ Receipts
-- ==========================================================================
                gc_error_loc := '3000- Zero Dollar Receipts';

                FOR invoice_rec IN ind_pos_sum_cm_cur
                LOOP
                    lc_inv_amount_remain := invoice_rec.amount_due_remaining;

                    FOR receipt_rec IN ind_pos_sum_o$_rcpt_cur
                    LOOP
                        BEGIN
                            IF lc_inv_amount_remain > receipt_rec.unapplied_amount
                            THEN
                                lc_apply_amt := lc_inv_amount_remain;
                            ELSE
                                lc_apply_amt := receipt_rec.unapplied_amount;
                            END IF;

                            IF p_debug_flag = 'Y'
                            THEN
                                fnd_file.put_line
                                                 (fnd_file.LOG,
                                                     'DEBUG: 1. Applying Credit Memo to 0$ Receipt, Receipt_method =  '
                                                  || receipt_rec.receipt_method
                                                  || ' unapplied_amount = '
                                                  || receipt_rec.unapplied_amount
                                                  || ' CM customer_trx_id = '
                                                  || invoice_rec.customer_trx_id
                                                  || ' amount_due_remaining = '
                                                  || invoice_rec.amount_due_remaining
                                                  || ' apply_amt = '
                                                  || lc_apply_amt);
                            END IF;

                            ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                                     p_init_msg_list =>         fnd_api.g_true,
                                                     p_commit =>                fnd_api.g_false,
                                                     p_validation_level =>      fnd_api.g_valid_level_full,
                                                     x_return_status =>         x_return_status,
                                                     x_msg_count =>             x_msg_count,
                                                     x_msg_data =>              x_msg_data,
                                                     p_cash_receipt_id =>       receipt_rec.cash_receipt_id,
                                                     p_customer_trx_id =>       invoice_rec.customer_trx_id,
                                                     p_amount_applied =>        lc_apply_amt,
                                                     p_comments =>              'E2074 (Apply POS Credit Memo)');

                            IF (x_return_status != 'S')
                            THEN
                                x_return_flag := 'Y';
                                x_error_message := x_msg_data;
                                fnd_file.put_line
                                              (fnd_file.LOG,
                                                  'Error - POS zero dollar receipt AR_RECEIPT_API_PUB.APPLY failed for'
                                               || ' store = '
                                               || store_rec.store_number
                                               || ' date = '
                                               || store_rec.receipt_date
                                               || ' cash_receipt_id '
                                               || receipt_rec.cash_receipt_id
                                               || ' customer_trx_id '
                                               || invoice_rec.customer_trx_id
                                               || ' amount_applied = '
                                               || lc_apply_amt
                                               || ' error = '
                                               || x_return_status
                                               || ' msg = '
                                               || x_error_message);

                                FOR i IN 1 .. x_msg_count
                                LOOP
                                    x_msg_data :=
                                          (   i
                                           || '. '
                                           || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                     1,
                                                     255) );
                                    fnd_file.put_line(fnd_file.LOG,
                                                         '                  '
                                                      || x_msg_data);
                                END LOOP;
                            ELSE
                                gc_error_loc := '3000- Receivable_Applications table';

                                SELECT application_ref_id,
                                       application_ref_num,
                                       application_ref_type,
                                       secondary_application_ref_id,
                                       receivable_application_id,
                                       payment_set_id
                                INTO   x_application_ref_id,
                                       x_application_ref_num,
                                       x_application_ref_type,
                                       x_secondary_application_ref_id,
                                       x_receivable_application_id,
                                       x_payment_set_id
                                FROM   ar_receivable_applications_all
                                WHERE  cash_receipt_id = receipt_rec.cash_receipt_id
                                AND    status <> 'APP'
                                AND    org_id = p_org_id
                                AND    ROWNUM = 1;

                                CASE
                                    WHEN receipt_rec.payment_type_code = 'CASH'
                                    THEN
							            IF receipt_rec.credit_card_code = 'PAYPAL' -- IF Logic added for the defect #30045
										THEN
										lc_rcpt_trx_name :=    lc_country
                                                    || '_REFUND_PAYPAL';
										ELSE
										lc_rcpt_trx_name :=    lc_country
                                                    || '_REFUND_CASH_'
                                                    || store_rec.store_number;
										END IF;
                            WHEN receipt_rec.payment_type_code = 'CREDIT_CARD'
                                    THEN
                                        IF receipt_rec.credit_card_code = 'DEBIT CARD'
                                        THEN
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_REFUND_DEBIT_CARD_OD';
                                        ELSE
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_REFUND_CC_WO_OD';
                                        END IF;
                                    WHEN receipt_rec.payment_type_code = 'CHECK'
                                    THEN
                                        IF (receipt_rec.credit_card_code = 'OD MONEY CARD2')
                                        THEN
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_REFUND_GIFT_CARD_OD';
									    ELSIF (receipt_rec.credit_card_code  = 'OD MONEY CARD3')   --V4.0 Added for OMX gift card consolidation
										THEN
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_REFUND_GIFT_CARD_OMX';
                                        --Start modification by Adithya for defect#19247
                                        ELSIF(    receipt_rec.credit_card_code LIKE '%TELECHECK%'
                                              AND receipt_rec.receipt_method =    lc_country
                                                                               || '_POS_TELECHECK_OD')
                                        THEN
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_TEL_POS_RVRSL_OD';
                                        --End modification by Adithya for defect#19247
                                        ELSE
                                            lc_rcpt_trx_name :=    lc_country
                                                                || '_MAILCK_CLR_OD';
                                        END IF;
                                    ELSE
                                        lc_rcpt_trx_name := NULL;
                                END CASE;

                                gc_error_loc := '3000- Receivable_trx table';

                                SELECT receivables_trx_id
                                INTO   x_receivables_trx_id
                                FROM   ar_receivables_trx_all
                                WHERE  NAME = lc_rcpt_trx_name
                                AND    org_id = p_org_id
                                AND    status = 'A';

                                ar_receipt_api_pub.activity_application
                                                      (p_api_version =>                       1.0,
                                                       p_init_msg_list =>                     fnd_api.g_true,
                                                       p_commit =>                            fnd_api.g_false,
                                                       p_validation_level =>                  fnd_api.g_valid_level_full,
                                                       x_return_status =>                     x_return_status,
                                                       x_msg_count =>                         x_msg_count,
                                                       x_msg_data =>                          x_msg_data,
                                                       p_cash_receipt_id =>                   receipt_rec.cash_receipt_id,
                                                       p_amount_applied =>                    (  -1
                                                                                               * lc_apply_amt),
                                                       p_apply_date =>                        SYSDATE,
                                                       p_applied_payment_schedule_id =>       -3   --Receipt Write-off
                                                                                                ,
                                                       p_link_to_customer_trx_id =>           NULL,
                                                       p_receivables_trx_id =>                x_receivables_trx_id,
                                                       p_comments =>                          'DEPOSIT : E2074 Refund Receipt Write-Off',
                                                       p_application_ref_type =>              x_application_ref_type,
                                                       p_application_ref_id =>                x_application_ref_id,
                                                       p_application_ref_num =>               x_application_ref_num,
                                                       p_secondary_application_ref_id =>      x_secondary_application_ref_id,
                                                       p_receivable_application_id =>         x_receivable_application_id,
                                                       p_payment_set_id =>                    x_payment_set_id,
                                                       p_attribute_rec =>                     lc_app_attributes,
                                                       p_customer_reference =>                invoice_rec.customer_reference,
                                                       p_val_writeoff_limits_flag =>          'Y',
                                                       p_called_from =>                       'E2074');

                                IF (x_return_status != 'S')
                                THEN
                                    x_return_flag := 'Y';
                                    x_error_message := x_msg_data;
                                    fnd_file.put_line
                                        (fnd_file.LOG,
                                            'Error - POS zero dollar receipt AR_RECEIPT_API_PUB.ACTIVITY_APPLICATION failed for'
                                         || ' store = '
                                         || store_rec.store_number
                                         || ' date = '
                                         || store_rec.receipt_date
                                         || ' cash_receipt_id '
                                         || receipt_rec.cash_receipt_id
                                         || ' customer_trx_id '
                                         || invoice_rec.customer_trx_id
                                         || ' error = '
                                         || x_return_status
                                         || ' msg = '
                                         || x_error_message);

                                    FOR i IN 1 .. x_msg_count
                                    LOOP
                                        x_msg_data :=
                                            (   i
                                             || '. '
                                             || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                       1,
                                                       255) );
                                        fnd_file.put_line(fnd_file.LOG,
                                                             '                  '
                                                          || x_msg_data);
                                    END LOOP;
                                ELSE
                                    lc_store_applied_amt :=   lc_store_applied_amt
                                                            + lc_apply_amt;
                                    tot_rcpt_applied_cnt :=   tot_rcpt_applied_cnt
                                                            + 1;
                                    tot_rcpt_applied_amt :=   tot_rcpt_applied_amt
                                                            + lc_apply_amt;
                                    lc_inv_amount_remain :=   lc_inv_amount_remain
                                                            - lc_apply_amt;
                                    gc_error_loc := '3000- Update POS_RECEIPTS table';

                                    IF   receipt_rec.unapplied_amount
                                       - lc_apply_amt = 0
                                    THEN
                                        lc_status := 'CL';
                                    ELSE
                                        lc_status := 'OP';
                                    END IF;

                                    UPDATE xx_ar_pos_receipts
                                    SET status = lc_status,
                                        unapplied_amount =   unapplied_amount
                                                           - lc_apply_amt,
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_global.user_id
                                    WHERE  cash_receipt_id = receipt_rec.cash_receipt_id
                                    AND    receipt_date >= store_rec.rcpt_date_start
                                    AND    receipt_date <= store_rec.rcpt_date_end
                                    AND    org_id = p_org_id
                                    AND    status = 'OP';

                                    fnd_file.put_line(fnd_file.output,
                                                         '        '
                                                      || store_rec.store_number
                                                      || '          '
                                                      || store_rec.receipt_date
                                                      || '          '
                                                      || receipt_rec.receipt_number
                                                      || '        '
                                                      || TO_CHAR(receipt_rec.unapplied_amount,
                                                                 '999,999,999.99')
                                                      || '      '
                                                      || SUBSTR(receipt_rec.receipt_method,
                                                                1,
                                                                20)
                                                      || ' - '
                                                      || 'zero dollar applied, and write-off');
                                END IF;
                            END IF;

                            COMMIT;
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                fnd_file.put_line(fnd_file.LOG,
                                                     'Error - Zero Dollar receipt - Exception - no data found '
                                                  || ' store = '
                                                  || store_rec.store_number
                                                  || ' date = '
                                                  || store_rec.receipt_date
                                                  || ' cash_receipt_id '
                                                  || receipt_rec.cash_receipt_id
                                                  || ' customer_trx_id '
                                                  || invoice_rec.customer_trx_id
                                                  || ' error = '
                                                  || x_return_status);
                                lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                           '');
                                ROLLBACK;
                            WHEN OTHERS
                            THEN
                                fnd_file.put_line(fnd_file.LOG,
                                                     'Error - Zero Dollar receipt - Exception - Others '
                                                  || ' store = '
                                                  || store_rec.store_number
                                                  || ' date = '
                                                  || store_rec.receipt_date
                                                  || ' cash_receipt_id '
                                                  || receipt_rec.cash_receipt_id
                                                  || ' customer_trx_id '
                                                  || invoice_rec.customer_trx_id
                                                  || ' error = '
                                                  || x_return_status);
                                lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                           '');
                                ROLLBACK;
                        END;
                    END LOOP;
                END LOOP;

-- ==========================================================================
-- Second - process remaining Credit Memo(s) to any Receipt(s)
-- ==========================================================================
                gc_error_loc := '4000- Credit Memo Process';

                BEGIN
                    OPEN ind_pos_sum_rcpt_cur;

                    FETCH ind_pos_sum_rcpt_cur
                    INTO  lc_receipt_row;

                    gc_error_loc := '4000- Credit Memo Process Loop';

                    FOR invoice_rec IN ind_pos_sum_cm_cur
                    LOOP
                        IF invoice_rec.amount_due_remaining > lc_receipt_row.unapplied_amount
                        THEN
                            lc_apply_amt := lc_receipt_row.unapplied_amount;
                        ELSE
                            lc_apply_amt := invoice_rec.amount_due_remaining;
                        END IF;

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line
                                         (fnd_file.LOG,
                                             'DEBUG: 2. Applying Credit Memo to remaining Receipts, Receipt_method =  '
                                          || lc_receipt_row.receipt_method
                                          || ' unapplied_amount = '
                                          || lc_receipt_row.unapplied_amount
                                          || ' CM customer_trx_id = '
                                          || invoice_rec.customer_trx_id
                                          || ' amount_due_remaining = '
                                          || invoice_rec.amount_due_remaining
                                          || ' Amount applied = '
                                          || lc_apply_amt);
                        END IF;

                        ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                                 p_init_msg_list =>         fnd_api.g_true,
                                                 p_commit =>                fnd_api.g_false,
                                                 p_validation_level =>      fnd_api.g_valid_level_full,
                                                 x_return_status =>         x_return_status,
                                                 x_msg_count =>             x_msg_count,
                                                 x_msg_data =>              x_msg_data,
                                                 p_cash_receipt_id =>       lc_receipt_row.cash_receipt_id,
                                                 p_customer_trx_id =>       invoice_rec.customer_trx_id,
                                                 p_amount_applied =>        lc_apply_amt,
                                                 p_comments =>              'E2074 (Apply POS Credit Memo)');

                        IF (x_return_status != 'S')
                        THEN
                            x_return_flag := 'Y';
                            x_error_message := x_msg_data;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - POS CM apply receipt AR_RECEIPT_API_PUB.APPLY failed for'
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cash_receipt_id '
                                              || lc_receipt_row.cash_receipt_id
                                              || ' customer_trx_id '
                                              || invoice_rec.customer_trx_id
                                              || ' error = '
                                              || x_return_status
                                              || ' msg = '
                                              || x_error_message);

                            FOR i IN 1 .. x_msg_count
                            LOOP
                                x_msg_data :=
                                          (   i
                                           || '. '
                                           || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                     1,
                                                     255) );
                                fnd_file.put_line(fnd_file.LOG,
                                                     '                  '
                                                  || x_msg_data);
                            END LOOP;
                        ELSE
                            lc_store_applied_amt :=   lc_store_applied_amt
                                                    + lc_apply_amt;
                            tot_rcpt_applied_cnt :=   tot_rcpt_applied_cnt
                                                    + 1;
                            tot_rcpt_applied_amt :=   tot_rcpt_applied_amt
                                                    + lc_apply_amt;

                            IF   lc_receipt_row.unapplied_amount
                               - lc_apply_amt = 0
                            THEN
                                lc_status := 'CL';
                            ELSE
                                lc_status := 'OP';
                            END IF;

                            gc_error_loc := '4000- Update POS_RECEIPTS table';

                            UPDATE xx_ar_pos_receipts
                            SET status = lc_status,
                                unapplied_amount =   unapplied_amount
                                                   - lc_apply_amt,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_global.user_id
                            WHERE  cash_receipt_id = lc_receipt_row.cash_receipt_id
                            AND    receipt_date >= store_rec.rcpt_date_start
                            AND    receipt_date <= store_rec.rcpt_date_end
                            AND    org_id = p_org_id
                            AND    status = 'OP';

                            fnd_file.put_line(fnd_file.output,
                                                 '        '
                                              || store_rec.store_number
                                              || '          '
                                              || store_rec.receipt_date
                                              || '          '
                                              || lc_receipt_row.receipt_number
                                              || '        '
                                              || TO_CHAR(lc_apply_amt,
                                                         '999,999,999.99')
                                              || '      '
                                              || SUBSTR(lc_receipt_row.receipt_method,
                                                        1,
                                                        20)
                                              || ' - '
                                              || 'Credit Memo remainder applied');
                        END IF;

                        COMMIT;
                    END LOOP;

                    CLOSE ind_pos_sum_rcpt_cur;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        CLOSE ind_pos_sum_rcpt_cur;
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error - remaining Credit Memos to Receipts - Exception - Others '
                                          || ' store = '
                                          || store_rec.store_number
                                          || ' date = '
                                          || store_rec.receipt_date
                                          || ' cash_receipt_id '
                                          || lc_receipt_row.cash_receipt_id
                                          || ' error_location '
                                          || gc_error_loc
                                          || ' error = '
                                          || x_return_status);
                        lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                   '');

                        CLOSE ind_pos_sum_rcpt_cur;
                END;

-- ==========================================================================
-- Third - process Invoice(s)
-- ==========================================================================
                gc_error_loc := '5000- Invoice process';

                BEGIN
                    OPEN ind_pos_sum_inv_cur;

                    FETCH ind_pos_sum_inv_cur
                    INTO  lc_invoice_row;

                    lc_inv_amount_remain := lc_invoice_row.amount_due_remaining;

                    FOR receipt_rec IN ind_pos_sum_rcpt_cur
                    LOOP
                        lc_rcpt_amount_remain := receipt_rec.unapplied_amount;

                        <<apply_next_inv>>
                        IF lc_rcpt_amount_remain > lc_inv_amount_remain
                        THEN
                            lc_apply_amt := lc_inv_amount_remain;
                            lc_inv_amount_remain :=   lc_inv_amount_remain
                                                    - lc_apply_amt;
                            lc_rcpt_amount_remain :=   lc_rcpt_amount_remain
                                                     - lc_apply_amt;
                            lc_apply_flag := 'R';
                        ELSE
                            lc_apply_amt := lc_rcpt_amount_remain;
                            lc_inv_amount_remain :=   lc_inv_amount_remain
                                                    - lc_apply_amt;
                            lc_rcpt_amount_remain :=   lc_rcpt_amount_remain
                                                     - lc_apply_amt;
                            lc_apply_flag := 'I';
                        END IF;

                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: 3. Applying Invoices and Receipts, Receipt_method =  '
                                              || receipt_rec.receipt_method
                                              || ' Customer trx_id = '
                                              || lc_invoice_row.customer_trx_id
                                              || ' Receipt amount remaining = '
                                              || lc_rcpt_amount_remain
                                              || ' Invoice amount remaining = '
                                              || lc_inv_amount_remain
                                              || ' Amount applied = '
                                              || lc_apply_amt);
                        END IF;

                        ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                                 p_init_msg_list =>         fnd_api.g_true,
                                                 p_commit =>                fnd_api.g_false,
                                                 p_validation_level =>      fnd_api.g_valid_level_full,
                                                 x_return_status =>         x_return_status,
                                                 x_msg_count =>             x_msg_count,
                                                 x_msg_data =>              x_msg_data,
                                                 p_cash_receipt_id =>       receipt_rec.cash_receipt_id,
                                                 p_customer_trx_id =>       lc_invoice_row.customer_trx_id,
                                                 p_amount_applied =>        lc_apply_amt,
                                                 p_comments =>              'E2074 (Apply POS Receipt)');

                        IF (x_return_status != 'S')
                        THEN
                            x_return_flag := 'Y';
                            x_error_message := x_msg_data;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - POS apply INV / receipt AR_RECEIPT_API_PUB.APPLY failed for'
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cash_receipt_id '
                                              || receipt_rec.cash_receipt_id
                                              || ' customer_trx_id '
                                              || lc_invoice_row.customer_trx_id
                                              || ' error = '
                                              || x_return_status
                                              || ' msg = '
                                              || x_error_message);

                            FOR i IN 1 .. x_msg_count
                            LOOP
                                x_msg_data :=
                                          (   i
                                           || '. '
                                           || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                     1,
                                                     255) );
                                fnd_file.put_line(fnd_file.LOG,
                                                     '                  '
                                                  || x_msg_data);
                            END LOOP;
                        ELSE
                            lc_store_applied_amt :=   lc_store_applied_amt
                                                    + lc_apply_amt;
                            tot_rcpt_applied_cnt :=   tot_rcpt_applied_cnt
                                                    + 1;
                            tot_rcpt_applied_amt :=   tot_rcpt_applied_amt
                                                    + lc_apply_amt;

                            IF lc_rcpt_amount_remain = 0
                            THEN
                                lc_status := 'CL';
                            ELSE
                                lc_status := 'OP';
                            END IF;

                            gc_error_loc := '5000- Update POS_RECEIPTS table';

                            UPDATE xx_ar_pos_receipts
                            SET status = lc_status,
                                unapplied_amount =   unapplied_amount
                                                   - lc_apply_amt,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_global.user_id
                            WHERE  cash_receipt_id = receipt_rec.cash_receipt_id
                            AND    receipt_date >= store_rec.rcpt_date_start
                            AND    receipt_date <= store_rec.rcpt_date_end
                            AND    org_id = p_org_id
                            AND    status = 'OP';

                            fnd_file.put_line(fnd_file.output,
                                                 '        '
                                              || store_rec.store_number
                                              || '          '
                                              || store_rec.receipt_date
                                              || '          '
                                              || receipt_rec.receipt_number
                                              || '        '
                                              || TO_CHAR(lc_apply_amt,
                                                         '999,999,999.99')
                                              || '      '
                                              || SUBSTR(receipt_rec.receipt_method,
                                                        1,
                                                        20)
                                              || ' - '
                                              || 'POS receipt applied');
                        END IF;

                        IF lc_apply_flag = 'R'
                        THEN
                            FETCH ind_pos_sum_inv_cur
                            INTO  lc_invoice_row;

                            lc_inv_amount_remain := lc_invoice_row.amount_due_remaining;
                            lc_apply_flag := ' ';
                            GOTO apply_next_inv;
                        END IF;

                        COMMIT;
                    END LOOP;

                    CLOSE ind_pos_sum_inv_cur;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        CLOSE ind_pos_sum_inv_cur;
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error - POS apply INV - Exception - Others '
                                          || ' store = '
                                          || store_rec.store_number
                                          || ' date = '
                                          || store_rec.receipt_date
                                          || ' cash_receipt_id '
                                          || lc_receipt_row.cash_receipt_id
                                          || ' error_location '
                                          || gc_error_loc
                                          || ' error = '
                                          || x_return_status
                                          || ' SQLCODE = '
                                          || SQLCODE
                                          || ' SQLERRM = '
                                          || SQLERRM);
                        lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                   '');

                        CLOSE ind_pos_sum_inv_cur;
                END;

-- ==========================================================================
-- Fourth - Write Off any remaining zero sum Receipts(s)
-- ==========================================================================
                gc_error_loc := '6000- Zero Sum process';

                FOR receipt_rec IN ind_pos_net_zero_sum_rcpt_cur
                LOOP
                    BEGIN
                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: 4. Writting Off Zero Sum Receipts, Receipt_method =  '
                                              || receipt_rec.receipt_method
                                              || ' Customer trx_id = '
                                              || lc_invoice_row.customer_trx_id
                                              || ' Receipt amount remaining = '
                                              || lc_rcpt_amount_remain
                                              || ' Invoice amount remaining = '
                                              || lc_inv_amount_remain
                                              || ' Amount applied = '
                                              || lc_apply_amt);
                        END IF;

                        SELECT application_ref_id,
                               application_ref_num,
                               application_ref_type,
                               secondary_application_ref_id,
                               receivable_application_id,
                               payment_set_id
                        INTO   x_application_ref_id,
                               x_application_ref_num,
                               x_application_ref_type,
                               x_secondary_application_ref_id,
                               x_receivable_application_id,
                               x_payment_set_id
                        FROM   ar_receivable_applications_all
                        WHERE  cash_receipt_id = receipt_rec.cash_receipt_id
                        AND    status <> 'APP'
                        AND    org_id = p_org_id
                        AND    ROWNUM = 1;

                        CASE
                            WHEN receipt_rec.payment_type_code = 'CASH'
                            THEN
							    IF receipt_rec.credit_card_code = 'PAYPAL' -- IF Logic added for the defect #30045
								THEN
									lc_rcpt_trx_name :=    lc_country
                                                    || '_REFUND_PAYPAL';
								ELSE
                                    lc_rcpt_trx_name :=    lc_country
                                                    || '_REFUND_CASH_'
                                                    || store_rec.store_number;
								END IF;
                            WHEN receipt_rec.payment_type_code = 'CREDIT_CARD'
                            THEN
                                lc_rcpt_trx_name :=    lc_country
                                                    || '_REFUND_CC_WO_OD';
                            --Start modification by Adithya for defect#19247
                        WHEN receipt_rec.payment_type_code = 'CHECK'
                            THEN
                                IF (    receipt_rec.credit_card_code LIKE '%TELECHECK%'
                                    AND receipt_rec.receipt_method =    lc_country
                                                                     || '_POS_TELECHECK_OD')
                                THEN
                                    lc_rcpt_trx_name :=    lc_country
                                                        || '_TEL_POS_RVRSL_OD';
                                ELSE
                                    lc_rcpt_trx_name :=    lc_country
                                                        || '_MAILCK_CLR_OD';
                                END IF;
                            ELSE
                                lc_rcpt_trx_name :=    lc_country
                                                    || '_MAILCK_CLR_OD';
                        --End modification by Adithya for defect#19247
                        END CASE;

                        gc_error_loc := '6000- RECEIVABLES_TRX table';

                        SELECT receivables_trx_id
                        INTO   x_receivables_trx_id
                        FROM   ar_receivables_trx_all
                        WHERE  NAME = lc_rcpt_trx_name
                        AND    org_id = p_org_id
                        AND    status = 'A';

                        ar_receipt_api_pub.activity_application
                                                      (p_api_version =>                       1.0,
                                                       p_init_msg_list =>                     fnd_api.g_true,
                                                       p_commit =>                            fnd_api.g_false,
                                                       p_validation_level =>                  fnd_api.g_valid_level_full,
                                                       x_return_status =>                     x_return_status,
                                                       x_msg_count =>                         x_msg_count,
                                                       x_msg_data =>                          x_msg_data,
                                                       p_cash_receipt_id =>                   receipt_rec.cash_receipt_id,
                                                       p_amount_applied =>                    0,
                                                       p_apply_date =>                        SYSDATE,
                                                       p_applied_payment_schedule_id =>       -3   --Receipt Write-off
                                                                                                ,
                                                       p_link_to_customer_trx_id =>           NULL,
                                                       p_receivables_trx_id =>                x_receivables_trx_id,
                                                       p_comments =>                          'DEPOSIT : E2074 Net Zero Receipt Write-Off',
                                                       p_application_ref_type =>              x_application_ref_type,
                                                       p_application_ref_id =>                x_application_ref_id,
                                                       p_application_ref_num =>               x_application_ref_num,
                                                       p_secondary_application_ref_id =>      x_secondary_application_ref_id,
                                                       p_receivable_application_id =>         x_receivable_application_id,
                                                       p_payment_set_id =>                    x_payment_set_id,
                                                       p_attribute_rec =>                     lc_app_attributes,
                                                       p_customer_reference =>                NULL,
                                                       p_val_writeoff_limits_flag =>          'Y',
                                                       p_called_from =>                       'E2074');

                        IF (x_return_status != 'S')
                        THEN
                            x_return_flag := 'Y';
                            x_error_message := x_msg_data;
                            fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Error - POS zero sum receipt AR_RECEIPT_API_PUB.ACTIVITY_APPLICATION failed for'
                                   || ' store = '
                                   || store_rec.store_number
                                   || ' date = '
                                   || store_rec.receipt_date
                                   || ' cash_receipt_id '
                                   || receipt_rec.cash_receipt_id
                                   || ' error = '
                                   || x_return_status
                                   || ' msg = '
                                   || x_error_message);

                            FOR i IN 1 .. x_msg_count
                            LOOP
                                x_msg_data :=
                                          (   i
                                           || '. '
                                           || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                     1,
                                                     255) );
                                fnd_file.put_line(fnd_file.LOG,
                                                     '                  '
                                                  || x_msg_data);
                            END LOOP;
                        ELSE
                            lc_store_applied_amt :=   lc_store_applied_amt
                                                    + receipt_rec.unapplied_amount;
                            tot_rcpt_applied_cnt :=   tot_rcpt_applied_cnt
                                                    + 1;
                            tot_rcpt_applied_amt :=   tot_rcpt_applied_amt
                                                    + receipt_rec.unapplied_amount;
                            gc_error_loc := '6000- Update POS_RECEIPTS table';

                            UPDATE xx_ar_pos_receipts
                            SET status = 'CL',
                                unapplied_amount =   unapplied_amount
                                                   - receipt_rec.unapplied_amount,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_global.user_id
                            WHERE  cash_receipt_id = receipt_rec.cash_receipt_id
                            AND    receipt_date >= store_rec.rcpt_date_start
                            AND    receipt_date <= store_rec.rcpt_date_end
                            AND    org_id = p_org_id
                            AND    status = 'OP';

                            fnd_file.put_line(fnd_file.output,
                                                 '        '
                                              || store_rec.store_number
                                              || '          '
                                              || store_rec.receipt_date
                                              || '          '
                                              || receipt_rec.receipt_number
                                              || '        '
                                              || TO_CHAR(receipt_rec.unapplied_amount,
                                                         '999,999,999.99')
                                              || '      '
                                              || SUBSTR(receipt_rec.receipt_method,
                                                        1,
                                                        20)
                                              || ' - '
                                              || 'zero sum receipt write-off');
                        END IF;

                        COMMIT;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - Zero sum receipt - Exception - no data found '
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cash_receipt_id '
                                              || receipt_rec.cash_receipt_id
                                              || ' error = '
                                              || x_return_status);
                            lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                       '');
                            ROLLBACK;
                        WHEN OTHERS
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - Zero sum receipt - Exception - Others '
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cash_receipt_id '
                                              || receipt_rec.cash_receipt_id
                                              || ' error = '
                                              || x_return_status);
                            lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                       '');
                            ROLLBACK;
                    END;
                END LOOP;

-- ==========================================================================
-- Fifth - Apply any remaining matching (netting) transactions
-- ==========================================================================
                gc_error_loc := '7000- Apply match netting Transactions';

                FOR transaction_rec IN ind_pos_match_trans_cur
                LOOP
                    BEGIN
                        IF p_debug_flag = 'Y'
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'DEBUG: 5. Applying remaining matching netting transactions:  '
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || 'CM Customer trx_id = '
                                              || transaction_rec.cm_customer_trx_id
                                              || 'INV Customer trx_id = '
                                              || transaction_rec.inv_customer_trx_id
                                              || 'amount remaining = '
                                              || transaction_rec.cm_amount_due_remaining);
                        END IF;

                        lr_cm_app_rec.cm_customer_trx_id := transaction_rec.cm_customer_trx_id;
                        lr_cm_app_rec.cm_trx_number := NULL;
                        lr_cm_app_rec.inv_customer_trx_id := transaction_rec.inv_customer_trx_id;
                        lr_cm_app_rec.inv_trx_number := NULL;
                        lr_cm_app_rec.installment := NULL;
                        lr_cm_app_rec.amount_applied := transaction_rec.inv_amount_due_remaining;
                        lr_cm_app_rec.applied_payment_schedule_id := -1;   --On Account
                        lr_cm_app_rec.apply_date := SYSDATE;
                        lr_cm_app_rec.gl_date := SYSDATE;
                        lr_cm_app_rec.inv_customer_trx_line_id := NULL;
                        lr_cm_app_rec.inv_line_number := NULL;
                        lr_cm_app_rec.show_closed_invoices := NULL;
                        lr_cm_app_rec.ussgl_transaction_code := NULL;
                        lr_cm_app_rec.attribute_category := NULL;
                        lr_cm_app_rec.attribute1 := NULL;
                        lr_cm_app_rec.attribute2 := NULL;
                        lr_cm_app_rec.attribute3 := NULL;
                        lr_cm_app_rec.attribute4 := NULL;
                        lr_cm_app_rec.attribute5 := NULL;
                        lr_cm_app_rec.attribute6 := NULL;
                        lr_cm_app_rec.attribute7 := NULL;
                        lr_cm_app_rec.attribute8 := NULL;
                        lr_cm_app_rec.attribute9 := NULL;
                        lr_cm_app_rec.attribute10 := NULL;
                        lr_cm_app_rec.attribute11 := NULL;
                        lr_cm_app_rec.attribute12 := NULL;
                        lr_cm_app_rec.attribute13 := NULL;
                        lr_cm_app_rec.attribute14 := NULL;
                        lr_cm_app_rec.attribute15 := NULL;
                        lr_cm_app_rec.global_attribute_category := NULL;
                        lr_cm_app_rec.global_attribute1 := NULL;
                        lr_cm_app_rec.global_attribute2 := NULL;
                        lr_cm_app_rec.global_attribute3 := NULL;
                        lr_cm_app_rec.global_attribute4 := NULL;
                        lr_cm_app_rec.global_attribute5 := NULL;
                        lr_cm_app_rec.global_attribute6 := NULL;
                        lr_cm_app_rec.global_attribute7 := NULL;
                        lr_cm_app_rec.global_attribute8 := NULL;
                        lr_cm_app_rec.global_attribute9 := NULL;
                        lr_cm_app_rec.global_attribute10 := NULL;
                        lr_cm_app_rec.global_attribute11 := NULL;
                        lr_cm_app_rec.global_attribute12 := NULL;
                        lr_cm_app_rec.global_attribute12 := NULL;
                        lr_cm_app_rec.global_attribute14 := NULL;
                        lr_cm_app_rec.global_attribute15 := NULL;
                        lr_cm_app_rec.global_attribute16 := NULL;
                        lr_cm_app_rec.global_attribute17 := NULL;
                        lr_cm_app_rec.global_attribute18 := NULL;
                        lr_cm_app_rec.global_attribute19 := NULL;
                        lr_cm_app_rec.global_attribute20 := NULL;
                        lr_cm_app_rec.comments := 'POS Summary CM-INV application';
                        lr_cm_app_rec.called_from := NULL;
                        ar_cm_api_pub.apply_on_account(p_api_version =>                    1,
                                                       p_init_msg_list =>                  fnd_api.g_true,
                                                       p_commit =>                         fnd_api.g_false,
                                                       p_cm_app_rec =>                     lr_cm_app_rec,
                                                       x_return_status =>                  x_return_status,
                                                       x_msg_count =>                      x_msg_count,
                                                       x_msg_data =>                       x_msg_data,
                                                       x_out_rec_application_id =>         ln_out_rec_appl_id,
                                                       x_acctd_amount_applied_from =>      ln_amount_applied_from,
                                                       x_acctd_amount_applied_to =>        ln_amount_applied_to);

                        IF (x_return_status != 'S')
                        THEN
                            x_return_flag := 'Y';
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - POS apply CM /INV AR_CM_API_PUB.APPLY_ON_ACCOUNT failed for'
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cm_customer_trx_id '
                                              || transaction_rec.cm_customer_trx_id
                                              || ' inv_customer_trx_id '
                                              || transaction_rec.inv_customer_trx_id
                                              || ' return_status = '
                                              || x_return_status
                                              || ' message(1) = '
                                              || x_msg_data);

                            FOR i IN 1 .. x_msg_count
                            LOOP
                                x_msg_data :=
                                          (   i
                                           || '. '
                                           || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                     1,
                                                     255) );
                                fnd_file.put_line(fnd_file.LOG,
                                                     '                  '
                                                  || x_msg_data);
                            END LOOP;
                        ELSE
                            fnd_file.put_line(fnd_file.output,
                                                 '        '
                                              || store_rec.store_number
                                              || '          '
                                              || store_rec.receipt_date
                                              || '                            '
                                              || TO_CHAR(transaction_rec.cm_amount_due_remaining,
                                                         '999,999,999.99')
                                              || '      '
                                              || ' - POS CM / INV applied');
                        END IF;

                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Error - CM / INV Zero net application - Others '
                                              || ' store = '
                                              || store_rec.store_number
                                              || ' date = '
                                              || store_rec.receipt_date
                                              || ' cm_customer_trx_id '
                                              || transaction_rec.cm_customer_trx_id
                                              || ' inv_customer_trx_id '
                                              || transaction_rec.inv_customer_trx_id
                                              || ' error = '
                                              || x_return_status);
                            lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                                       '');
                            ROLLBACK;
                    END;
                END LOOP;

-- ==========================================================================
-- Report store's total applied amount
-- ==========================================================================
                gc_error_loc := '6000- Store Total Process';
                fnd_file.put_line(fnd_file.output,
                                  ' ');
                fnd_file.put_line(fnd_file.output,
                                     ' TOTAL  '
                                  || store_rec.store_number
                                  || '          '
                                  || store_rec.receipt_date
                                  || '                     '
                                  || TO_CHAR(store_rec.unapplied_amount,
                                             '999,999,999.99')
                                  || TO_CHAR(lc_store_applied_amt,
                                             '999,999,999.99')
                                  || '      '
                                  || 'TOTAL POS receipts applied (Original unapplied vs. Actual applied');
                fnd_file.put_line(fnd_file.output,
                                  ' ');
-- ==========================================================================
-- Otherwise Store's receipts and invoices are out of tolerances
-- ==========================================================================
            ELSE
                x_email_flag := 'Y';
                fnd_file.put_line(fnd_file.output,
                                  ' ');
                fnd_file.put_line(fnd_file.output,
                                     ' TOTAL  '
                                  || store_rec.store_number
                                  || '          '
                                  || store_rec.receipt_date
                                  || '                     '
                                  || TO_CHAR(store_rec.unapplied_amount,
                                             '999,999,999.99')
                                  || TO_CHAR(lc_store_inv_amount,
                                             '999,999,999.99')
                                  || ' - '
                                  || 'Not Applied - Amounts are out of tolerance');
                fnd_file.put_line(fnd_file.output,
                                  ' ');
                fnd_file.put_line(fnd_file.LOG,
                                     ' TOTAL  '
                                  || store_rec.store_number
                                  || '          '
                                  || store_rec.receipt_date
                                  || '                     '
                                  || TO_CHAR(store_rec.unapplied_amount,
                                             '999,999,999.99')
                                  || TO_CHAR(lc_store_inv_amount,
                                             '999,999,999.99')
                                  || ' - '
                                  || 'Not Applied - Amounts are out of tolerance');

                IF p_debug_flag = 'Y'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'DEBUG: Amounts are outside tolerances for store = '
                                      || store_rec.store_number
                                      || ' date = '
                                      || store_rec.receipt_date
                                      || ' receipt amount = '
                                      || store_rec.unapplied_amount
                                      || ' INV / CM amount = '
                                      || lc_store_inv_amount);
                END IF;
            END IF;
        END LOOP;

-- ==========================================================================
-- Sixth - Apply any stand-alone matching (netting) transactions
-- ==========================================================================
        gc_error_loc := '8000- Apply stand-alone match netting Transactions';

        BEGIN
            SELECT TRIM(TO_CHAR(SYSDATE,
                                'DAY') )
            INTO   lc_day_of_week
            FROM   DUAL;

            fnd_file.put_line(fnd_file.LOG,
                                 ' Today is ---'
                              || lc_day_of_week
                              || '---');

            IF lc_day_of_week = 'SUNDAY'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  ' Processing Stand-Alone matching netting transactions');

                FOR transaction_rec IN ind_pos_stand_alone_cur
                LOOP
                    lr_cm_app_rec.cm_customer_trx_id := transaction_rec.cm_customer_trx_id;
                    lr_cm_app_rec.cm_trx_number := NULL;
                    lr_cm_app_rec.inv_customer_trx_id := transaction_rec.inv_customer_trx_id;
                    lr_cm_app_rec.inv_trx_number := NULL;
                    lr_cm_app_rec.installment := NULL;
                    lr_cm_app_rec.amount_applied := transaction_rec.inv_amount_due_remaining;
                    lr_cm_app_rec.applied_payment_schedule_id := transaction_rec.inv_payment_schedule_id;
                    lr_cm_app_rec.apply_date := SYSDATE;
                    lr_cm_app_rec.gl_date := SYSDATE;
                    lr_cm_app_rec.inv_customer_trx_line_id := NULL;
                    lr_cm_app_rec.inv_line_number := NULL;
                    lr_cm_app_rec.show_closed_invoices := NULL;
                    lr_cm_app_rec.ussgl_transaction_code := NULL;
                    lr_cm_app_rec.attribute_category := NULL;
                    lr_cm_app_rec.attribute1 := NULL;
                    lr_cm_app_rec.attribute2 := NULL;
                    lr_cm_app_rec.attribute3 := NULL;
                    lr_cm_app_rec.attribute4 := NULL;
                    lr_cm_app_rec.attribute5 := NULL;
                    lr_cm_app_rec.attribute6 := NULL;
                    lr_cm_app_rec.attribute7 := NULL;
                    lr_cm_app_rec.attribute8 := NULL;
                    lr_cm_app_rec.attribute9 := NULL;
                    lr_cm_app_rec.attribute10 := NULL;
                    lr_cm_app_rec.attribute11 := NULL;
                    lr_cm_app_rec.attribute12 := NULL;
                    lr_cm_app_rec.attribute13 := NULL;
                    lr_cm_app_rec.attribute14 := NULL;
                    lr_cm_app_rec.attribute15 := NULL;
                    lr_cm_app_rec.global_attribute_category := NULL;
                    lr_cm_app_rec.global_attribute1 := NULL;
                    lr_cm_app_rec.global_attribute2 := NULL;
                    lr_cm_app_rec.global_attribute3 := NULL;
                    lr_cm_app_rec.global_attribute4 := NULL;
                    lr_cm_app_rec.global_attribute5 := NULL;
                    lr_cm_app_rec.global_attribute6 := NULL;
                    lr_cm_app_rec.global_attribute7 := NULL;
                    lr_cm_app_rec.global_attribute8 := NULL;
                    lr_cm_app_rec.global_attribute9 := NULL;
                    lr_cm_app_rec.global_attribute10 := NULL;
                    lr_cm_app_rec.global_attribute11 := NULL;
                    lr_cm_app_rec.global_attribute12 := NULL;
                    lr_cm_app_rec.global_attribute12 := NULL;
                    lr_cm_app_rec.global_attribute14 := NULL;
                    lr_cm_app_rec.global_attribute15 := NULL;
                    lr_cm_app_rec.global_attribute16 := NULL;
                    lr_cm_app_rec.global_attribute17 := NULL;
                    lr_cm_app_rec.global_attribute18 := NULL;
                    lr_cm_app_rec.global_attribute19 := NULL;
                    lr_cm_app_rec.global_attribute20 := NULL;
                    lr_cm_app_rec.comments := 'POS Summary CM-INV application';
                    lr_cm_app_rec.called_from := NULL;

                    IF p_debug_flag = 'Y'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'DEBUG: 6. Apply stand-alone transactions store = '
                                          || transaction_rec.store_number
                                          || ' date = '
                                          || transaction_rec.receipt_date
                                          || ' CM txn = '
                                          || lr_cm_app_rec.cm_customer_trx_id
                                          || ' INV txn = '
                                          || lr_cm_app_rec.inv_customer_trx_id
                                          || ' CM amount = '
                                          || transaction_rec.cm_amount_due_remaining
                                          || ' INV amount = '
                                          || transaction_rec.inv_amount_due_remaining);
                    END IF;

                    ar_cm_api_pub.apply_on_account(p_api_version =>                    1,
                                                   p_init_msg_list =>                  fnd_api.g_true,
                                                   p_commit =>                         fnd_api.g_false,
                                                   p_cm_app_rec =>                     lr_cm_app_rec,
                                                   x_return_status =>                  x_return_status,
                                                   x_msg_count =>                      x_msg_count,
                                                   x_msg_data =>                       x_msg_data,
                                                   x_out_rec_application_id =>         ln_out_rec_appl_id,
                                                   x_acctd_amount_applied_from =>      ln_amount_applied_from,
                                                   x_acctd_amount_applied_to =>        ln_amount_applied_to);

                    IF (x_return_status != 'S')
                    THEN
                        x_return_flag := 'Y';
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error - POS apply CM /INV AR_CM_API_PUB.APPLY_ON_ACCOUNT failed for'
                                          || ' store = '
                                          || transaction_rec.store_number
                                          || ' date = '
                                          || transaction_rec.receipt_date
                                          || ' cm_customer_trx_id '
                                          || lr_cm_app_rec.cm_customer_trx_id
                                          || ' inv_customer_trx_id '
                                          || lr_cm_app_rec.inv_customer_trx_id
                                          || ' return_status = '
                                          || x_return_status
                                          || ' message(1) = '
                                          || x_msg_data);

                        FOR i IN 1 .. x_msg_count
                        LOOP
                            x_msg_data :=(   i
                                          || '. '
                                          || SUBSTR(fnd_msg_pub.get(p_encoded =>      fnd_api.g_false),
                                                    1,
                                                    255) );
                            fnd_file.put_line(fnd_file.LOG,
                                                 '                  '
                                              || x_msg_data);
                        END LOOP;
                    ELSE
                        fnd_file.put_line(fnd_file.output,
                                             '        '
                                          || transaction_rec.store_number
                                          || '          '
                                          || transaction_rec.receipt_date
                                          || '                            '
                                          || TO_CHAR(transaction_rec.cm_amount_due_remaining,
                                                     '999,999,999.99')
                                          || '      '
                                          || ' - POS Stand-Alone CM / INV applied');
                    END IF;

                    COMMIT;
                END LOOP;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Error - Apply stand-alone matching transactions - Others '
                                  || ' error = '
                                  || x_return_status);
                lc_compl_stat := fnd_concurrent.set_completion_status('WARNING',
                                                                           '');
                ROLLBACK;
        END;

-- ==========================================================================
-- Report this run's total applied amount
-- ==========================================================================
        gc_error_loc := '1000- Run Total Process';
        fnd_file.put_line(fnd_file.output,
                          ' ');
        fnd_file.put_line(fnd_file.output,
                             ' RUN TOTAL:  '
                          || '                   receipts_applied = '
                          || TO_CHAR(tot_rcpt_applied_cnt,
                                     '999,999,999')
                          || '                     amount_applied = '
                          || TO_CHAR(tot_rcpt_applied_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,
                          ' ');
        fnd_file.put_line(fnd_file.LOG,
                             ' RUN TOTAL:  '
                          || '                   receipts_applied = '
                          || TO_CHAR(tot_rcpt_applied_cnt,
                                     '999,999,999')
                          || '                     amount_applied = '
                          || TO_CHAR(tot_rcpt_applied_amt,
                                     '999,999,999.99') );

        BEGIN
            SELECT COUNT(*),
                   SUM(unapplied_amount)
            INTO   lc_total_unapplied_cnt,
                   lc_total_unapplied_amt
            FROM   xx_ar_pos_receipts
            WHERE  TRUNC(receipt_date) = p_rcpt_date;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lc_total_unapplied_cnt := 0;
                lc_total_unapplied_amt := 0;
        END;

        fnd_file.put_line(fnd_file.output,
                          ' ');
        fnd_file.put_line(fnd_file.output,
                             ' RUN TOTAL:  '
                          || '                 receipts_unapplied = '
                          || TO_CHAR(lc_total_unapplied_cnt,
                                     '999,999,999')
                          || '                   amount_unapplied = '
                          || TO_CHAR(lc_total_unapplied_amt,
                                     '999,999,999.99') );
        fnd_file.put_line(fnd_file.LOG,
                          ' ');
        fnd_file.put_line(fnd_file.LOG,
                             ' RUN TOTAL:  '
                          || '                 receipts_unapplied = '
                          || TO_CHAR(lc_total_unapplied_cnt,
                                     '999,999,999')
                          || '                   amount_unapplied = '
                          || TO_CHAR(lc_total_unapplied_amt,
                                     '999,999,999.99') );
-- ==========================================================================
-- Email notification if any receipts out of tolerance
-- ==========================================================================
        gc_error_loc := '1000- Email Notification Process';

        IF x_email_flag = 'Y'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'preparing to send email alert ');

            SELECT v.target_value1
            INTO   lc_email_destination
            FROM   xx_fin_translatedefinition d, xx_fin_translatevalues v
            WHERE  d.translate_id = v.translate_id
            AND    d.translation_name = 'OD_MAIL_GROUPS'
            AND    v.source_value1 = 'E2074 - POS RECEIPTS EMAIL DISTRIBUTION';

            ln_print_option := fnd_request.set_print_options(printer =>      'XPTR',
                                                             copies =>       0);
            ln_req_id :=
                fnd_request.submit_request('xxfin',
                                           'XXODROEMAILER',
                                           '',
                                           '',
                                           FALSE,
                                              ln_instance_name
                                           || '_'
                                           || lc_country
                                           || 'OD: AR POS Apply Receipt Summary',
                                           lc_email_destination,
                                              ln_instance_name
                                           || '_'
                                           || lc_country
                                           || 'OD: AR POS Apply Receipt Summary out of tolerance',
                                              ln_instance_name
                                           || '_'
                                           || lc_country
                                           || 'OD: AR POS Apply Receipt Summary out of tolerance',
                                           'Y',
                                           fnd_global.conc_request_id);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error - Apply_Summary_Receipt - Exception - Others '
                              || gc_error_loc);
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                'APPLY_SUMMARY_RECEIPT',
                                           p_program_id =>                  fnd_global.conc_program_id,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error at OTHERS',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>               'OTHERS',
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 'POS Apply Receipts');
            ROLLBACK;
    END apply_summary_receipt_child;

-- +=====================================================================================================+
-- |                                                                                                     |
-- |  PROCEDURE: SYNC_MANUAL_WRITE_OFFS                                                                  |
-- |                                                                                                     |
-- +=====================================================================================================+
    PROCEDURE sync_manual_write_offs(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_debug_flag  IN             VARCHAR2)
    IS
        x_error_message  VARCHAR2(2000) DEFAULT NULL;
        x_return_status  VARCHAR2(20)   DEFAULT NULL;
        x_msg_count      NUMBER         DEFAULT NULL;
        x_msg_data       VARCHAR2(4000) DEFAULT NULL;
        p_start_date     DATE           DEFAULT NULL;
        p_end_date       DATE           DEFAULT NULL;

-- ==========================================================================
-- cursor - Summarize POS receipts by Store / Date
-- ==========================================================================
        CURSOR write_off_cur
        IS
            SELECT   r.summary_pos_receipt_id,
                     r.store_number,
                     TRUNC(r.receipt_date) AS receipt_date,
                     r.receipt_number,
                     r.cash_receipt_id
            FROM     xx_ar_pos_receipts r, ar_payment_schedules_all p
            WHERE    p.cash_receipt_id = r.cash_receipt_id
            AND      r.status = 'OP'
            AND      p.status = 'CL'
            ORDER BY r.store_number, TRUNC(r.receipt_date);
    BEGIN
        IF p_rcpt_date IS NULL
        THEN
            p_start_date := NULL;
            p_end_date := NULL;
        ELSE
            p_start_date := TO_DATE(   p_rcpt_date
                                    || ' 00:00:00',
                                    'DD-MON-YY HH24:MI:SS');
            p_end_date := TO_DATE(   p_rcpt_date
                                  || ' 23:59:59',
                                  'DD-MON-YY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                          'XX_AR_POS_RECEIPT.SYNC_MANUAL_WRITE_OFFS - parameters:      ');
        fnd_file.put_line(fnd_file.LOG,
                             '                                           ORG_ID        = '
                          || p_org_id);
        fnd_file.put_line(fnd_file.LOG,
                             '                                           STORE_NUMBER  = '
                          || p_store_num);
        fnd_file.put_line(fnd_file.LOG,
                             '                                           START DATE    = '
                          || p_start_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                           END DATE      = '
                          || p_end_date);
        fnd_file.put_line(fnd_file.LOG,
                             '                                           DEBUG_FLAG    = '
                          || p_debug_flag);
        fnd_file.put_line(fnd_file.LOG,
                          ' ');
        fnd_file.put_line(fnd_file.LOG,
                             '        '
                          || 'STORE_NUMBER   '
                          || 'RECEIPT_DATE        '
                          || 'RECEIPT_NUMBER        ');
        fnd_file.put_line(fnd_file.output,
                          '        ');

        FOR receipt_rec IN write_off_cur
        LOOP
            UPDATE xx_ar_pos_receipts
            SET status = 'CL',
                last_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id
            WHERE  summary_pos_receipt_id = receipt_rec.summary_pos_receipt_id;

            fnd_file.put_line(fnd_file.LOG,
                                 '        '
                              || receipt_rec.store_number
                              || '          '
                              || receipt_rec.receipt_date
                              || '          '
                              || receipt_rec.receipt_number);
        END LOOP;

        COMMIT;
    END sync_manual_write_offs;

-- +===================================================================+
-- | Name : APPLY_SUMMARY_RECEIPT                                      |
-- | Description : This Program will submit 10 child requests          |
-- |               to process receipts. The number of child program    |
-- |               to be defined as a parameter in the prgroam defn.   |
-- |                                                                   |
-- | Program "OD: AR POS Apply Receipts Summary"                       |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE apply_summary_receipt(
        errbuf                   OUT NOCOPY     VARCHAR2,
        retcode                  OUT NOCOPY     NUMBER,
        p_org_id                 IN             NUMBER,
        p_store_number           IN             VARCHAR2,
        p_receipt_date           IN             VARCHAR2,
        p_tolerance              IN             NUMBER,
        p_debug_flag             IN             VARCHAR2,
        p_max_number_of_threads  IN             NUMBER)
    AS
        ld_receipt_start_date  DATE;
        ld_receipt_end_date    DATE;
        ln_number_of_threads   NUMBER;
        ln_number_of_stores    NUMBER;
        lc_request_data        VARCHAR2(4000) := NULL;
        ln_child_request_id    NUMBER;
        lv_phase               VARCHAR2(20);
        lv_status              VARCHAR2(20);
        ln_error_count         NUMBER         := 0;
        ln_warning_count       NUMBER         := 0;
        ln_normal_count        NUMBER         := 0;

        CURSOR cur_thread_info(
            p_number_of_threads   IN  NUMBER,
            p_store_number        IN  xx_ar_pos_receipts.store_number%TYPE,
            p_receipt_start_date  IN  xx_ar_pos_receipts.receipt_date%TYPE,
            p_receipt_end_date    IN  xx_ar_pos_receipts.receipt_date%TYPE)
        IS
            SELECT   MIN(store_number) min_store_number,
                     MAX(store_number) max_store_number,
                     COUNT(1) store_count,
                     thread_number
            FROM     (SELECT store_number,
                             NTILE(p_number_of_threads) OVER(ORDER BY store_number) thread_number
                      FROM   (SELECT   store_number
                              FROM     xx_ar_pos_receipts r
                              WHERE    r.status = 'OP'
                              AND      r.org_id = p_org_id
                              AND      r.store_number = NVL(p_store_number,
                                                            r.store_number)
                              AND      r.receipt_date >= NVL(p_receipt_start_date,
                                                             r.receipt_date)
                              AND      r.receipt_date <= NVL(p_receipt_end_date,
                                                             r.receipt_date)
                              GROUP BY store_number) stores)
            GROUP BY thread_number
            ORDER BY thread_number;
    BEGIN
        IF p_receipt_date IS NULL
        THEN
            ld_receipt_start_date := NULL;
            ld_receipt_end_date := NULL;
        ELSE
            ld_receipt_start_date := TO_DATE(   p_receipt_date
                                             || ' 00:00:00',
                                             'DD-MON-YY HH24:MI:SS');
            ld_receipt_end_date := TO_DATE(   p_receipt_date
                                           || ' 23:59:59',
                                           'DD-MON-YY HH24:MI:SS');
        END IF;

        lc_request_data := fnd_conc_global.request_data();
        fnd_file.put_line(fnd_file.LOG,
                          '---------------------------------------------------');
        fnd_file.put_line(fnd_file.LOG,
                          'Parameters');
        fnd_file.put_line(fnd_file.LOG,
                             'p_org_id      = '
                          || p_org_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_store_number   = '
                          || p_store_number);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_date   = '
                          || p_receipt_date);
        fnd_file.put_line(fnd_file.LOG,
                             'p_tolerance   = '
                          || p_tolerance);
        fnd_file.put_line(fnd_file.LOG,
                             'p_debug_flag  = '
                          || p_debug_flag);
        fnd_file.put_line(fnd_file.LOG,
                             'p_max_number_of_threads    = '
                          || p_max_number_of_threads);
        fnd_file.put_line(fnd_file.LOG,
                          '---------------------------------------------------');

        IF (lc_request_data IS NULL)
        THEN
            BEGIN
                SELECT COUNT(DISTINCT store_number)
                INTO   ln_number_of_stores
                FROM   xx_ar_pos_receipts r
                WHERE  r.status = 'OP'
                AND    r.org_id = p_org_id
                AND    r.store_number = NVL(p_store_number,
                                            r.store_number)
                AND    r.receipt_date >= NVL(ld_receipt_start_date,
                                             r.receipt_date)
                AND    r.receipt_date <= NVL(ld_receipt_end_date,
                                             r.receipt_date);

                fnd_file.put_line(fnd_file.LOG,
                                     ' . Number of stores to be processed  ='
                                  || ln_number_of_stores);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                      'Error while getting the number of stores to be processed.');
                    fnd_file.put_line(fnd_file.LOG,
                                         'Error Message  - '
                                      || SQLERRM);
                    retcode := 2;
                    RETURN;
            END;

            IF ln_number_of_stores = 0
            THEN
                retcode := 0;
                errbuf := 'No stores to process. Exiting.';
                RETURN;   -- If no records to proces sthen the program should compelte without submitting child request.
            ELSIF ln_number_of_stores < p_max_number_of_threads
            THEN
                ln_number_of_threads := ln_number_of_stores;
            ELSE
                ln_number_of_threads := p_max_number_of_threads;
            END IF;

            IF NVL(ln_number_of_threads,
                   0) = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Number of threads have not been passed in the concurrent program.');
                retcode := 2;
                errbuf := 'Number of threads have not been paased in the concurrent program.';
                RETURN;
            END IF;

            fnd_file.put_line(fnd_file.LOG,
                                 'Number of threads to be submitted '
                              || ln_number_of_threads);

            FOR thread_info_rec IN cur_thread_info(p_number_of_threads =>       ln_number_of_threads,
                                                   p_store_number =>            p_store_number,
                                                   p_receipt_start_date =>      ld_receipt_start_date,
                                                   p_receipt_end_date =>        ld_receipt_end_date)
            LOOP
                BEGIN
                    ln_child_request_id :=
                        fnd_request.submit_request(application =>      'XXFIN',
                                                   program =>          'XXARPOSRCPTAPPLYCHILD',
                                                   description =>      '',
                                                   start_time =>       SYSDATE,
                                                   sub_request =>      TRUE,
                                                   argument1 =>        p_org_id,
                                                   argument2 =>        p_receipt_date,
                                                   argument3 =>        p_tolerance,
                                                   argument4 =>        p_debug_flag,
                                                   argument5 =>        thread_info_rec.min_store_number,
                                                   argument6 =>        thread_info_rec.max_store_number);
                    COMMIT;

                    IF ln_child_request_id = 0
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Could not submit the child request number '
                                          || thread_info_rec.thread_number
                                          || ' Min store number '
                                          || thread_info_rec.min_store_number
                                          || ' Max store number '
                                          || thread_info_rec.max_store_number
                                          || ' Store Count '
                                          || thread_info_rec.store_count);
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error Message '
                                          || SQLERRM);
                        retcode := 2;
                        RETURN;
                    END IF;

                    fnd_file.put_line(fnd_file.LOG,
                                         'Thread Number '
                                      || thread_info_rec.thread_number
                                      || ' Min store number '
                                      || thread_info_rec.min_store_number
                                      || ' Max store number '
                                      || thread_info_rec.max_store_number
                                      || ' Store Count '
                                      || thread_info_rec.store_count
                                      || '. Request ID = '
                                      || ln_child_request_id);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error while submitting child request '
                                          || SQLERRM);
                END;
            END LOOP;

            IF (ln_number_of_threads > 0)
            THEN
                fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                request_data =>      'child_processing_over');
                RETURN;
            END IF;
        ELSE
--************
            fnd_file.put_line(fnd_file.LOG,
                              '     ');
            fnd_file.put_line(fnd_file.LOG,
                              'Master Restarts: ');
            fnd_file.put_line(fnd_file.LOG,
                                 'Current system time is '
                              || TO_CHAR(SYSDATE,
                                         'DD-MON-YYYY HH24:MI:SS') );
            fnd_file.put_line(fnd_file.LOG,
                              '     ');

            SELECT SUM(CASE
                           WHEN status_code = 'E'
                               THEN 1
                           ELSE 0
                       END),
                   SUM(CASE
                           WHEN status_code = 'G'
                               THEN 1
                           ELSE 0
                       END),
                   SUM(CASE
                           WHEN status_code = 'C'
                               THEN 1
                           ELSE 0
                       END)
            INTO   ln_error_count,
                   ln_warning_count,
                   ln_normal_count
            FROM   fnd_concurrent_requests
            WHERE  parent_request_id = fnd_global.conc_request_id;

            IF (    ln_error_count > 0
                AND ln_warning_count > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'One or more OD: AR POS Apply Receipts Summary-Child ended in Error/Warning');
                retcode := 2;
            ELSIF(    ln_warning_count > 0
                  AND ln_error_count = 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'One or more OD: AR POS Apply Receipts Summary-Child ended in Warning');
                retcode := 1;
            ELSIF(    ln_error_count > 0
                  AND ln_warning_count = 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'One or more OD: AR POS Apply Receipts Summary-Child ended in Error');
                retcode := 2;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unhandled Exception: '
                              || 'SQLCODE: '
                              || SQLCODE
                              || ' SQLERMM: '
                              || SQLERRM);
            errbuf := SUBSTR(   'Unhandled Exception: ERROR: '
                             || SQLERRM,
                             1,
                             250);
            retcode := 2;
    END apply_summary_receipt;
END xx_ar_pos_receipt_pkg;
/
show errors;
exit;