CREATE OR REPLACE PACKAGE BODY apps.xx_ar_manual_pmts_pkg
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_MANUAL_PMTS_PKG                                                              |
-- |  Description:  This package is used to run manual processes on payments.                   |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         04-Jun-2008  Brian J Looman   Initial version                                  |
-- | 1.1         07-JUN-2013  Bapuji Nanapaneni Replaced SYN with TBL for 12i upgrade           |
-- | 1.2         12-SEPT-2013 Edson Morales     Added R12 credit card encryption                |
-- | 2.0         04-Feb-2014  Edson Morales    Changes for Defect 27883                         |
-- +============================================================================================+
    gb_debug         BOOLEAN      DEFAULT TRUE;                                               -- print debug/log output
    gc_access_level  VARCHAR2(50) := fnd_profile.VALUE('XX_AR_I1025_ACCESS_LEVEL');

-- ==========================================================================
-- procedure to turn on/off debug
-- ==========================================================================
    PROCEDURE set_debug(
        p_debug  IN  BOOLEAN DEFAULT TRUE)
    IS
    BEGIN
        gb_debug := p_debug;
    END;

-- ==========================================================================
-- procedure for printing to the output
-- ==========================================================================
    PROCEDURE put_out_line(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        -- if in concurrent program, print to output file
        IF (fnd_global.conc_request_id > 0)
        THEN
            fnd_file.put_line(fnd_file.output,
                              NVL(p_buffer,
                                  ' '));
        -- else print to DBMS_OUTPUT
        ELSE
            DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,
                                            ' '),
                                        1,
                                        255));
        END IF;
    END;

-- ==========================================================================
-- procedure for printing to the log
-- ==========================================================================
    PROCEDURE put_log_line(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        --if debug is on (defaults to true)
        IF (gb_debug)
        THEN
            -- if in concurrent program, print to log file
            IF (fnd_global.conc_request_id > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  NVL(p_buffer,
                                      ' '));
            -- else print to DBMS_OUTPUT
            ELSE
                DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,
                                                ' '),
                                            1,
                                            255));
            END IF;
        END IF;
    END;

-- ==========================================================================
-- procedure to clear the credit card errors on a receipt
-- ==========================================================================
    PROCEDURE clear_receipt_cc_errors(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_receipt_method_id    IN      NUMBER,
        p_receipt_date_from    IN      VARCHAR2,
        p_receipt_date_to      IN      VARCHAR2,
        p_receipt_number_from  IN      VARCHAR2,
        p_receipt_number_to    IN      VARCHAR2,
        p_tangible_prefix      IN      VARCHAR2 DEFAULT NULL,
        p_cc_error_text        IN      VARCHAR2 DEFAULT NULL,
        p_commit_flag          IN      VARCHAR2 DEFAULT 'Y')
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'CLEAR_RECEIPT_CC_ERRORS';
        ld_receipt_date_from  DATE         DEFAULT NULL;
        ld_receipt_date_to    DATE         DEFAULT NULL;
    BEGIN
        put_log_line(   'BEGIN '
                     || lc_sub_name);
        put_log_line();
        SAVEPOINT before_clear_cc_errors;
        ld_receipt_date_from := fnd_conc_date.string_to_date(p_receipt_date_from);
        ld_receipt_date_to := fnd_conc_date.string_to_date(p_receipt_date_to);
        put_log_line('Parameters: ');
        put_log_line(   '  Receipt Method ID   = '
                     || p_receipt_method_id);
        put_log_line(   '  Receipt Date From   = '
                     || ld_receipt_date_from);
        put_log_line(   '  Receipt Date To     = '
                     || ld_receipt_date_to);
        put_log_line(   '  Receipt Number From = '
                     || p_receipt_number_from);
        put_log_line(   '  Receipt Number To   = '
                     || p_receipt_number_to);
        put_log_line(   '  Tangible Prefix     = '
                     || p_tangible_prefix);
        put_log_line(   '  CC Error Text       = '
                     || p_cc_error_text);
        put_log_line(   '  Commit Flag         = '
                     || p_commit_flag);
        put_log_line();
        x_return_code := 0;

-- ==========================================================================
-- validate that the user has administrative access
-- ==========================================================================
        IF (gc_access_level = 'ADMIN')
        THEN
            put_log_line('User has administrative access to I1025 procedures.');
            put_log_line();
        ELSE
            put_log_line('*** User does not have administrative access to the I1025 manual procedures. ***');
            x_return_code := 1;
            x_error_buffer := 'User does not have administrative access to the I1025 manual procedures.';
            RETURN;
        END IF;

-- ==========================================================================
-- update the given receipts to receipt the credit card error flags
-- ==========================================================================
        UPDATE ar_cash_receipts_all acr
        SET acr.cc_error_flag = NULL,
            acr.cc_error_code = NULL,
            acr.cc_error_text = NULL,
            acr.last_updated_by = fnd_global.user_id,
            acr.last_update_date = SYSDATE,
            acr.last_update_login = fnd_global.login_id,
            acr.request_id = fnd_global.conc_request_id,
            acr.program_application_id = fnd_global.prog_appl_id,
            acr.program_id = fnd_global.conc_program_id,
            acr.program_update_date = SYSDATE
        WHERE  acr.org_id = fnd_global.org_id
        AND    acr.receipt_method_id = p_receipt_method_id
        AND    acr.cc_error_flag IS NOT NULL                                             -- if anything in CC error flag
        AND    acr.receipt_date BETWEEN NVL(ld_receipt_date_from,
                                            acr.receipt_date)
                                    AND   NVL(ld_receipt_date_to,
                                              acr.receipt_date)
                                        + 0.99999
        AND    acr.receipt_number BETWEEN NVL(p_receipt_number_from,
                                              acr.receipt_number)
                                      AND NVL(p_receipt_number_to,
                                              acr.receipt_number)
        AND    (   (p_tangible_prefix IS NOT NULL AND acr.payment_server_order_num LIKE    p_tangible_prefix
                                                                                        || '%')
                OR (p_tangible_prefix IS NULL))
        AND    (   (p_cc_error_text IS NOT NULL AND acr.cc_error_text LIKE    p_cc_error_text
                                                                           || '%')
                OR (p_cc_error_text IS NULL))
        AND    (SELECT status
                FROM   ar_cash_receipt_history_all
                WHERE  cash_receipt_id = acr.cash_receipt_id AND current_record_flag = 'Y') = 'CONFIRMED';

        put_log_line(   '# Reset error flags on these receipts.  Records updated: '
                     || SQL%ROWCOUNT);
        put_log_line();

-- ==========================================================================
-- issue commit if requested
-- ==========================================================================
        IF (p_commit_flag = 'Y')
        THEN
            COMMIT;
        END IF;

        put_log_line();
        put_log_line(   'END '
                     || lc_sub_name);
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK TO SAVEPOINT before_clear_cc_errors;
            x_return_code := 2;
            RAISE;
    END;

-- ==========================================================================
-- procedure to correct the receipt methods on the tender tables
-- ==========================================================================
    PROCEDURE correct_receipt_method(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_source_table         IN      VARCHAR2,
        p_receipt_method_from  IN      VARCHAR2,
        p_receipt_method_to    IN      VARCHAR2,
        p_from_date            IN      VARCHAR2,
        p_to_date              IN      VARCHAR2)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'CORRECT_RECEIPT_METHOD';
        ld_from_date          DATE         DEFAULT NULL;
        ld_to_date            DATE         DEFAULT NULL;
        ln_old_rcpt_mthd_id   NUMBER       DEFAULT NULL;
        ln_new_rcpt_mthd_id   NUMBER       DEFAULT NULL;

        CURSOR c_rcpt_mthd_id(
            cp_receipt_method  IN  VARCHAR2)
        IS
            SELECT receipt_method_id
            FROM   ar_receipt_methods
            WHERE  NAME = cp_receipt_method;
    BEGIN
        put_log_line(   'BEGIN '
                     || lc_sub_name);
        put_log_line();
        ld_from_date := fnd_conc_date.string_to_date(p_from_date);
        ld_to_date := fnd_conc_date.string_to_date(p_to_date);
        put_log_line('Parameters: ');
        put_log_line(   '  Source Table          = '
                     || p_source_table);
        put_log_line(   '  Old Receipt Method ID = '
                     || p_receipt_method_from);
        put_log_line(   '  New Receipt Method ID = '
                     || p_receipt_method_to);
        put_log_line(   '  From Date             = '
                     || ld_from_date);
        put_log_line(   '  To Date               = '
                     || ld_to_date);
        put_log_line();
        x_return_code := 0;

-- ==========================================================================
-- validate that the user has administrative access
-- ==========================================================================
        IF (gc_access_level = 'ADMIN')
        THEN
            put_log_line('User has administrative access to the I1025 manual procedures.');
            put_log_line();
        ELSE
            put_log_line('*** User does not have administrative access to the I1025 manual procedures. ***');
            x_return_code := 1;
            x_error_buffer := 'User does not have administrative access to the I1025 manual procedures.';
            RETURN;
        END IF;

        OPEN c_rcpt_mthd_id(cp_receipt_method      => p_receipt_method_from);

        FETCH c_rcpt_mthd_id
        INTO  ln_old_rcpt_mthd_id;

        CLOSE c_rcpt_mthd_id;

        OPEN c_rcpt_mthd_id(cp_receipt_method      => p_receipt_method_to);

        FETCH c_rcpt_mthd_id
        INTO  ln_new_rcpt_mthd_id;

        CLOSE c_rcpt_mthd_id;

        IF (p_source_table IN('Deposit Payments', 'All'))
        THEN
            UPDATE xx_om_legacy_deposits
            SET receipt_method_id = ln_new_rcpt_mthd_id
            WHERE  receipt_method_id = ln_old_rcpt_mthd_id
            AND    creation_date BETWEEN ld_from_date AND   ld_to_date
                                                          + 0.99999
            AND    i1025_status = 'NEW';

            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' records in XX_OM_LEGACY_DEPOSITS.');
            put_log_line();
        END IF;

        IF (p_source_table IN('Refund Tenders', 'All'))
        THEN
            UPDATE xx_om_return_tenders_all
            SET receipt_method_id = ln_new_rcpt_mthd_id
            WHERE  receipt_method_id = ln_old_rcpt_mthd_id
            AND    creation_date BETWEEN ld_from_date AND   ld_to_date
                                                          + 0.99999
            AND    i1025_status = 'NEW';

            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' records in XX_OM_RETURN_TENDERS_ALL.');
            put_log_line();
        END IF;

        IF (p_source_table IN('Order Payments', 'All'))
        THEN
            UPDATE oe_payments p
            SET p.receipt_method_id = ln_new_rcpt_mthd_id
            WHERE  p.receipt_method_id = ln_old_rcpt_mthd_id
            AND    p.creation_date BETWEEN ld_from_date AND   ld_to_date
                                                            + 0.99999
            AND    EXISTS(SELECT 1
                          FROM   oe_order_headers_all
                          WHERE  header_id = p.header_id AND flow_status_code NOT IN('INVOICED', 'CLOSED'));

            put_log_line(   '# Updated '
                         || SQL%ROWCOUNT
                         || ' records in OE_PAYMENTS.');
            put_log_line();
        END IF;

        put_log_line();
        put_log_line(   'END '
                     || lc_sub_name);
    END;

-- ==========================================================================
-- procedure to clear selected remittance batch id from the given receipts
-- ==========================================================================
    PROCEDURE clear_selected_remit_batch(
        x_error_buffer         OUT     VARCHAR2,
        x_return_code          OUT     NUMBER,
        p_receipt_method_id    IN      NUMBER,
        p_remit_batch_id       IN      NUMBER,
        p_receipt_date_from    IN      VARCHAR2,
        p_receipt_date_to      IN      VARCHAR2,
        p_receipt_number_from  IN      VARCHAR2,
        p_receipt_number_to    IN      VARCHAR2,
        p_tangible_prefix      IN      VARCHAR2 DEFAULT NULL,
        p_cc_error_text        IN      VARCHAR2 DEFAULT NULL,
        p_commit_flag          IN      VARCHAR2 DEFAULT 'Y')
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'CLEAR_SELECTED_REMIT_BATCH';
        ld_receipt_date_from  DATE         DEFAULT NULL;
        ld_receipt_date_to    DATE         DEFAULT NULL;
    BEGIN
        put_log_line(   'BEGIN '
                     || lc_sub_name);
        put_log_line();
        SAVEPOINT before_clear_remit_batch;
        ld_receipt_date_from := fnd_conc_date.string_to_date(p_receipt_date_from);
        ld_receipt_date_to := fnd_conc_date.string_to_date(p_receipt_date_to);
        put_log_line('Parameters: ');
        put_log_line(   '  Receipt Method ID   = '
                     || p_receipt_method_id);
        put_log_line(   '  Remittance Batch ID = '
                     || p_remit_batch_id);
        put_log_line(   '  Receipt Date From   = '
                     || ld_receipt_date_from);
        put_log_line(   '  Receipt Date To     = '
                     || ld_receipt_date_to);
        put_log_line(   '  Receipt Number From = '
                     || p_receipt_number_from);
        put_log_line(   '  Receipt Number To   = '
                     || p_receipt_number_to);
        put_log_line(   '  Tangible Prefix     = '
                     || p_tangible_prefix);
        put_log_line(   '  CC Error Text       = '
                     || p_cc_error_text);
        put_log_line(   '  Commit Flag         = '
                     || p_commit_flag);
        put_log_line();
        x_return_code := 0;

-- ==========================================================================
-- validate that the user has administrative access
-- ==========================================================================
        IF (gc_access_level = 'ADMIN')
        THEN
            put_log_line('User has administrative access to I1025 procedures.');
            put_log_line();
        ELSE
            put_log_line('*** User does not have administrative access to the I1025 manual procedures. ***');
            x_return_code := 1;
            x_error_buffer := 'User does not have administrative access to the I1025 manual procedures.';
            RETURN;
        END IF;

-- ==========================================================================
-- update the given receipts to receipt the credit card error flags
-- ==========================================================================
        UPDATE ar_cash_receipts_all acr
        SET acr.selected_remittance_batch_id = NULL,
            acr.last_updated_by = fnd_global.user_id,
            acr.last_update_date = SYSDATE,
            acr.last_update_login = fnd_global.login_id,
            acr.request_id = fnd_global.conc_request_id,
            acr.program_application_id = fnd_global.prog_appl_id,
            acr.program_id = fnd_global.conc_program_id,
            acr.program_update_date = SYSDATE
        WHERE  acr.org_id = fnd_global.org_id
        AND    acr.receipt_method_id = p_receipt_method_id
        AND    acr.receipt_date BETWEEN NVL(ld_receipt_date_from,
                                            acr.receipt_date)
                                    AND   NVL(ld_receipt_date_to,
                                              acr.receipt_date)
                                        + 0.99999
        AND    acr.receipt_number BETWEEN NVL(p_receipt_number_from,
                                              acr.receipt_number)
                                      AND NVL(p_receipt_number_to,
                                              acr.receipt_number)
        AND    (   (p_tangible_prefix IS NOT NULL AND acr.payment_server_order_num LIKE    p_tangible_prefix
                                                                                        || '%')
                OR (p_tangible_prefix IS NULL))
        AND    (   (p_cc_error_text IS NOT NULL AND acr.cc_error_text LIKE    p_cc_error_text
                                                                           || '%')
                OR (p_cc_error_text IS NULL))
        AND    (   (p_remit_batch_id IS NOT NULL AND acr.selected_remittance_batch_id = p_remit_batch_id)
                OR (p_remit_batch_id IS NULL AND acr.selected_remittance_batch_id IS NOT NULL))
        AND    (SELECT status
                FROM   ar_cash_receipt_history_all
                WHERE  cash_receipt_id = acr.cash_receipt_id AND current_record_flag = 'Y') = 'CONFIRMED';

        put_log_line(   '# Cleared remittance batch id on these receipts.  Records updated: '
                     || SQL%ROWCOUNT);
        put_log_line();

-- ==========================================================================
-- issue commit if requested
-- ==========================================================================
        IF (p_commit_flag = 'Y')
        THEN
            COMMIT;
        END IF;

        put_log_line();
        put_log_line(   'END '
                     || lc_sub_name);
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK TO SAVEPOINT before_clear_remit_batch;
            x_return_code := 2;
            RAISE;
    END;
END;
/