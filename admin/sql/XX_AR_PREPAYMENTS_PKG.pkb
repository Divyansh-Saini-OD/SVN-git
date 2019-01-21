create or replace PACKAGE BODY XX_AR_PREPAYMENTS_PKG 
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_PREPAYMENTS_PKG                                                              |
-- |  Rice ID: I1025                                                                            |
-- |  Description:  This package is an extended version of AR_PREPAYMENTS_PUB.                  |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         02-Oct-2007  B.Looman         Initial version                                  |
-- | 1.1         16-Dec-2008  Anitha.D         Fix for Defect 11482                             |
-- | 1.1         28-JAN-2009  Anitha.D         Fix for Defect 11482                             |
-- | 1.2         29-SEP-2009  Anitha.D         Fix for Defect 2385                              |
-- | 1.3         28-APR-2011  GAURAV Agarwal   Fix for SDR Project                              |
-- | 1.4         15-MAY-2011  GAURAV Agarwal   Fix for SDR Project for defect 11494             |
-- | 1.5         10-Aug-2011  GAURAV Agarwal   Fix for post SDR defect : 13009                  |
-- | 1.6         18-OCT-2012  Bapuji N         Fix for PAYPAL Tender Defect : 20779             |
-- | 1.7         24-JUN-2013  Bapuji N         Fix for AMAZON Tender                            |
-- | 1.8         02-AUG-2013  Bapuji N         RetorFit for 12i                                 |
-- | 1.9         21-AUG-2013  Edson Morales    Added voice auth back                            |
-- | 2.0         28-AUG-2013  Edson Morales    Added R12 encryption                             |
-- | 2.1         17-SEP-2013  Edson Morales    Changed encryption to use AJB                    |
-- | 2.2.        12-DEC-2013  Edson Morales    Defect 27022.  For DEBIT_CARDS                   |
-- | 3.0         04-Feb-2013  Edson M.         Changes for Defect 27883                         |
-- | 4.0         15-Jul-2014  Veronica M       OMX Gift Card Consolidation                      |
-- | 4.0         15-Jul-2014  Suresh P         OMX Gift Card Consolidation                      |
-- | 4.1         30-JUL-2015  Ravi P           For QC Defect#34528								|
-- | 4.2 		 03-MAY-2018  Theja Rajula	   EBAY Changes										|
-- | 5.0         17-MAY-2018  Havish Kasina    Market Place Expansion - AR Changes for adding   |
-- |                                           new translations.To make the code configurable   | 
-- |                                           for future market places(Defect NAIT-42023)      |
-- +============================================================================================+
    gb_debug                BOOLEAN                                     DEFAULT FALSE;        -- print debug/log output
    gd_program_run_date     DATE                                        DEFAULT SYSDATE;
    -- get the current date when first used
    gc_disc_card_type       xx_fin_translatevalues.target_value1%TYPE   := 'DISCOVER';                  -- Defect 11482
-- Profiles:
--  XX_AR_1025_MESSAGE_LOGGING_LEVEL: profile level for recording messages
--   0 for no messages
--   1 for only errors
--   2 for errors and warnings
--   3 for all messages (errors, warnings, and info) - DEFAULTS to ALL messages
--  XX_AR_I1025_REFUND_AMT_TOLERANCE: Refund Amount Tolerance (difference in refund amount
--     and credit memo amount due remaining)
--  XX_AR_I1025_COMMIT_INTERVAL: Commit Interval (how often to commit records

    --GN_COMMIT_INTERVAL         NUMBER          DEFAULT 100;   -- interval for commits (profile)
    gn_i1025_message_level  NUMBER                                      DEFAULT 3;   -- message logging level (profile)
--GN_REFUND_TOLERANCE        NUMBER          DEFAULT 0;     -- refund tolerance (profile)
    gn_cc_bank_time         NUMBER                                      DEFAULT 0;
    -- duration for fetch/create CC bank acct
    gn_prepay_time          NUMBER                                      DEFAULT 0;
    -- duration for create prepayment API
    gn_ipayment_time        NUMBER                                      DEFAULT 0; -- duration for iPayment adapter API
    gn_total_time           NUMBER                                      DEFAULT 0;

    -- duration for total API process time

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
-- procedure for printing to the log
-- ==========================================================================
    PROCEDURE put_log_line(
        p_buffer  IN  VARCHAR2 DEFAULT ' ',
        p_force   IN  BOOLEAN DEFAULT FALSE)
    IS
    BEGIN
        --if debug is on (defaults to true)
        IF (gb_debug OR p_force)
        THEN
            -- if in concurrent program, print to log file
            IF (fnd_global.conc_request_id > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  NVL(   TO_CHAR(SYSTIMESTAMP,
                                                 'HH24:MI:SS.FF: ')
                                      || p_buffer,
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
-- procedure for printing to the log the current datetime
-- ==========================================================================
    PROCEDURE put_current_datetime(
        p_buffer  IN  VARCHAR2 DEFAULT ' ')
    IS
    BEGIN
        NULL;
    --put_log_line('== ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || ' ==');
    END;

-- ==========================================================================
-- function to get the current timestamp (number in seconds)
-- ==========================================================================
    FUNCTION get_timestamp
        RETURN NUMBER
    IS
        l_time  TIMESTAMP := SYSTIMESTAMP;
    BEGIN
        RETURN(  (  (  (  (    EXTRACT(DAY FROM l_time)
                             * 24
                           + EXTRACT(HOUR FROM l_time))
                        * 60)
                     + EXTRACT(MINUTE FROM l_time))
                  * 60)
               + EXTRACT(SECOND FROM l_time));
    END;

-- ==========================================================================
-- procedure for inserting I1025 messages (errors, warnings, and info)
-- ==========================================================================
    PROCEDURE clear_i1025_messages(
        p_i1025_record_type      IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2,
        p_payment_number         IN  NUMBER,
        p_request_id             IN  NUMBER)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'CLEAR_I1025_MESSAGES';

        TYPE t_rowid_tab IS TABLE OF ROWID
            INDEX BY PLS_INTEGER;

        a_rowid_tab           t_rowid_tab;

        CURSOR c_old_run
        IS
            SELECT     ROWID row_id
            FROM       xx_ar_i1025_messages
            WHERE      i1025_record_type = p_i1025_record_type
            AND        orig_sys_document_ref = p_orig_sys_document_ref
            AND        payment_number = p_payment_number
            AND        most_recent_run = 'Y'
            AND        request_id < p_request_id
            FOR UPDATE NOWAIT;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
-- ==========================================================================
-- get the previous runs when most_recent_run at "Y"
-- ==========================================================================
        OPEN c_old_run;

        FETCH c_old_run
        BULK COLLECT INTO a_rowid_tab;

        CLOSE c_old_run;

-- ==========================================================================
-- update previous run to "No" for most_recent_run
-- ==========================================================================
        IF (a_rowid_tab.COUNT > 0)
        THEN
            IF (gb_debug)
            THEN
                put_log_line(   '# Old Run Count = '
                             || a_rowid_tab.COUNT);
            END IF;

            FORALL i_index IN a_rowid_tab.FIRST .. a_rowid_tab.LAST
                UPDATE xx_ar_i1025_messages
                SET most_recent_run = 'N'
                WHERE  ROWID = a_rowid_tab(i_index);
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            put_log_line('* Errors occured when clearing I1025 messages.');
            put_log_line(SQLERRM);
    END;

-- ==========================================================================
-- procedure for inserting I1025 messages (errors, warnings, and info)
-- ==========================================================================
    PROCEDURE insert_i1025_message(
        p_i1025_record_type      IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2,
        p_payment_number         IN  NUMBER,
        p_program_run_date       IN  DATE,
        p_request_id             IN  NUMBER,
        p_message_code           IN  VARCHAR2,
        p_message_text           IN  VARCHAR2,
        p_error_location         IN  VARCHAR2,
        p_message_type           IN  VARCHAR2 DEFAULT gc_i1025_msg_type_error)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'INSERT_I1025_MESSAGE';
        ln_current_seq        NUMBER       DEFAULT 0;
        lc_message_type       VARCHAR2(20) DEFAULT NULL;

        CURSOR c_current_seq
        IS
            SELECT MAX(sequence_number)
            FROM   xx_ar_i1025_messages
            WHERE  i1025_record_type = p_i1025_record_type
            AND    orig_sys_document_ref = p_orig_sys_document_ref
            AND    payment_number = p_payment_number
            AND    request_id = p_request_id;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
-- ==========================================================================
-- check if we should be recording the message
-- ==========================================================================
        IF (p_message_type = gc_i1025_msg_type_info AND gn_i1025_message_level <= 3)
        THEN
            RETURN;
        ELSIF(p_message_type = gc_i1025_msg_type_warning AND gn_i1025_message_level <= 2)
        THEN
            RETURN;
        ELSIF(p_message_type = gc_i1025_msg_type_error AND gn_i1025_message_level <= 1)
        THEN
            RETURN;
        ELSIF(gn_i1025_message_level = 0)
        THEN
            RETURN;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line('Insert I1025 message text for this orig_sys_document_ref/payment_number');
        END IF;

-- ==========================================================================
-- default the message type to Error if not defined
-- ==========================================================================
        IF (p_message_type IS NOT NULL)
        THEN
            lc_message_type := p_message_type;
        ELSE
            lc_message_type := 'E';
        END IF;

-- ==========================================================================
-- get the sequence number used for the previous record
-- ==========================================================================
        OPEN c_current_seq;

        FETCH c_current_seq
        INTO  ln_current_seq;

        CLOSE c_current_seq;

-- ==========================================================================
-- insert the record into the I1025 messages table
-- ==========================================================================
        INSERT INTO xx_ar_i1025_messages
                    (i1025_record_type,
                     orig_sys_document_ref,
                     payment_number,
                     program_run_date,
                     request_id,
                     most_recent_run,
                     sequence_number,
                     MESSAGE_TYPE,
                     MESSAGE_CODE,
                     MESSAGE_TEXT,
                     error_location,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     last_update_login)
             VALUES (p_i1025_record_type,
                     p_orig_sys_document_ref,
                     p_payment_number,
                     p_program_run_date,
                     p_request_id,
                     'Y',
                       NVL(ln_current_seq,
                           0)
                     + 1,
                     lc_message_type,
                     p_message_code,
                     p_message_text,
                     p_error_location,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.login_id);

        IF (gb_debug)
        THEN
            put_log_line(   '# Inserted '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_AR_I1025_MESSAGES');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            put_log_line('* Errors occured when adding the I1025 message.');
            put_log_line(SQLERRM);
    END;

-- ==========================================================================
-- procedure wrapper for adding a message for prepayment errors/warnings/info
-- ==========================================================================
    PROCEDURE add_prepay_message(
        p_orig_sys_document_ref  IN  VARCHAR2,
        p_payment_number         IN  NUMBER,
        p_message_code           IN  VARCHAR2,
        p_message_text           IN  VARCHAR2,
        p_error_location         IN  VARCHAR2,
        p_message_type           IN  VARCHAR2 DEFAULT gc_i1025_msg_type_error)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'ADD_PREPAY_MESSAGE';
    BEGIN
        insert_i1025_message(p_i1025_record_type          => gc_i1025_record_type_order,
                             p_orig_sys_document_ref      => p_orig_sys_document_ref,
                             p_payment_number             => p_payment_number,
                             p_program_run_date           => gd_program_run_date,
                             p_request_id                 => NVL(fnd_global.conc_request_id,
                                                                 -1),
                             p_message_code               => p_message_code,
                             p_message_text               => p_message_text,
                             p_error_location             => p_error_location,
                             p_message_type               => p_message_type);
    END;

-- ===========================================================================
-- generic function that is used to separate a delimited string into an
--   array of string values
-- ===========================================================================
    FUNCTION explode(
        p_string     IN  VARCHAR2,
        p_delimiter  IN  VARCHAR2 DEFAULT ',')
        RETURN stringarray
    IS
        n_index       NUMBER      DEFAULT 0;
        n_pos         NUMBER      DEFAULT 0;
        n_hold_pos    NUMBER      DEFAULT 1;
        a_return_tab  stringarray DEFAULT stringarray();
    BEGIN
        LOOP
            n_pos := INSTR(p_string,
                           p_delimiter,
                           n_hold_pos);

            IF n_pos > 0
            THEN
                a_return_tab.EXTEND;
                n_index :=   n_index
                           + 1;
                a_return_tab(n_index) := LTRIM(SUBSTR(p_string,
                                                      n_hold_pos,
                                                        n_pos
                                                      - n_hold_pos));
            ELSE
                a_return_tab.EXTEND;
                n_index :=   n_index
                           + 1;
                a_return_tab(n_index) := LTRIM(SUBSTR(p_string,
                                                      n_hold_pos));
                EXIT;
            END IF;

            n_hold_pos :=   n_pos
                          + 1;
        END LOOP;

        RETURN a_return_tab;
    END;

-- ==========================================================================
-- raise errors generated by an Oracle API
-- ==========================================================================
    PROCEDURE raise_api_errors(
        p_sub_name   IN  VARCHAR2,
        p_msg_count  IN  NUMBER,
        p_api_name   IN  VARCHAR2)
    IS
        lc_api_errors  VARCHAR2(2000) DEFAULT NULL;
    BEGIN
-- ==========================================================================
-- get API errors from the standard FND_MSG_PUB message stack
-- ==========================================================================
        FOR idx IN 1 .. p_msg_count
        LOOP
            IF (lc_api_errors IS NOT NULL)
            THEN
                lc_api_errors :=    lc_api_errors
                                 || CHR(10);
            END IF;

            lc_api_errors :=    lc_api_errors
                             || '  '
                             || idx
                             || ': '
                             || fnd_msg_pub.get(idx,
                                                'F');
        END LOOP;

-- ==========================================================================
-- if API errors generated, then push errors to message stack
-- ==========================================================================
        fnd_message.set_name('XXFIN',
                             'XX_AR_I1025_20002_API_ERRORS');
        fnd_message.set_token('SUB_NAME',
                              p_sub_name);
        fnd_message.set_token('API_NAME',
                              p_api_name);
        fnd_message.set_token('API_ERRORS',
                              lc_api_errors);
        --FND_MESSAGE.set_token('API_ERRORS',NULL);
        raise_application_error(-20002,
                                fnd_message.get());
    END;

-- ==========================================================================
-- raise errors for missing parameters
-- ==========================================================================
    PROCEDURE raise_missing_param_errors(
        p_sub_name    IN  VARCHAR2,
        p_param_name  IN  VARCHAR2)
    IS
    BEGIN
        fnd_message.set_name('XXFIN',
                             'XX_AR_I1025_20001_MISS_PARAM');
        fnd_message.set_token('SUB_NAME',
                              p_sub_name);
        fnd_message.set_token('PARAMETER',
                              p_param_name);
        raise_application_error(-20001,
                                fnd_message.get());
    END;

-- ==========================================================================
-- function that will get the prepayment recv trx id for the given org_id
-- ==========================================================================
    FUNCTION get_prepayment_recv_trx_id(
        p_org_id  IN  NUMBER)
        RETURN NUMBER
    IS
        lc_sub_name   CONSTANT VARCHAR2(50) := 'GET_PREPAYMENT_RECV_TRX_ID';

        CURSOR c_prepay_recv_trx
        IS
            SELECT receivables_trx_id
            FROM   ar_receivables_trx_all
            WHERE  TYPE = 'PREPAYMENT' AND status = 'A' AND org_id = p_org_id;

        ln_prepay_recv_trx_id  NUMBER       DEFAULT NULL;
    BEGIN
        OPEN c_prepay_recv_trx;

        FETCH c_prepay_recv_trx
        INTO  ln_prepay_recv_trx_id;

        CLOSE c_prepay_recv_trx;

        RETURN ln_prepay_recv_trx_id;
    END;

-- ==========================================================================
-- function that will get the country prefix for the given org_id
-- ==========================================================================
    FUNCTION get_country_prefix(
        p_org_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'GET_COUNTRY_PREFIX';

        CURSOR c_country
        IS
            SELECT default_country
            FROM   ar_system_parameters_all
            WHERE  org_id = p_org_id;

        lc_country_code       VARCHAR2(50) DEFAULT NULL;
    BEGIN
        OPEN c_country;

        FETCH c_country
        INTO  lc_country_code;

        CLOSE c_country;

        RETURN lc_country_code;
    END;

-- ==========================================================================
-- function that will get the receipt method name for the given id
-- ==========================================================================
    FUNCTION get_receipt_method(
        p_receipt_method_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'GET_RECEIPT_METHOD';

        CURSOR c_receipt_method
        IS
            SELECT NAME
            FROM   ar_receipt_methods
            WHERE  receipt_method_id = p_receipt_method_id;

        lc_receipt_method     VARCHAR2(50) DEFAULT NULL;
    BEGIN
        OPEN c_receipt_method;

        FETCH c_receipt_method
        INTO  lc_receipt_method;

        CLOSE c_receipt_method;

        RETURN lc_receipt_method;
    END;

-- ==========================================================================
-- procedure that returns the actual payment type based on the
--   org_id (country), payment_type_code, and receipt_method
-- ==========================================================================
    FUNCTION get_payment_type(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)  := 'GET_PAYMENT_TYPE';
        lc_country_prefix     VARCHAR2(50)  DEFAULT NULL;
        lc_receipt_method     VARCHAR2(50)  DEFAULT NULL;
        lc_payment_type       VARCHAR2(100) DEFAULT NULL;
    BEGIN
-- ==========================================================================
-- get the country code prefix for the given operating unit (org_id)
-- ==========================================================================
        lc_country_prefix := get_country_prefix(p_org_id);
-- ==========================================================================
-- get the receipt method name for the given id
-- ==========================================================================
        lc_receipt_method := get_receipt_method(p_receipt_method_id);

-- ==========================================================================
-- determine the payment type for the given receipt method
--   if no receipt method found, then null will be returned
-- ==========================================================================
        IF (lc_receipt_method LIKE    lc_country_prefix
                                   || '_OM_CASH_%')
        THEN
            IF (p_payment_type = 'CHECK')
            THEN
                -- check and cash both use this receipt mthd
                --   CHECK is: Check, Telecheck Paper, and Foreign Check
                lc_payment_type := 'CHECK';
            ELSE
                lc_payment_type := 'CASH';
            END IF;
	-- Commented as per Version 5.0 by Havish K
	/*
        ELSIF((lc_receipt_method =    lc_country_prefix
                                  || '_GIFT CARD_OD')
               OR
			   (lc_receipt_method =    lc_country_prefix
                                  || '_GIFT CARD_OMX'))   --V4.0 Added for OMX gift card consolidation
        THEN
            lc_payment_type := 'GIFT_CARD';
        ELSIF(   (lc_receipt_method =    lc_country_prefix
                                      || '_TELECHECK_OD')
              OR (lc_receipt_method =    lc_country_prefix
                                      || '_TELECHECK_OD_OLD'))                                                    --v1.4
        THEN
            lc_payment_type := 'TELECHECK';
        ELSIF(lc_receipt_method =    lc_country_prefix
                                  || '_MAILCHECK_OD')
        THEN
            lc_payment_type := 'MAILCHECK';
        ELSIF(   (lc_receipt_method =    lc_country_prefix
                                      || '_DEBIT CARD_OD')
              OR (lc_receipt_method =    lc_country_prefix
                                      || '_DEBIT CARD_OD2')
              OR (lc_receipt_method =    lc_country_prefix
                                      || '_DEBIT CARD_OD_OLD'))                                                   --v1.4
        THEN
            lc_payment_type := 'DEBIT_CARD';
        ELSIF(   (lc_receipt_method =    lc_country_prefix
                                      || '_CC OD ALL_CC')
              OR (lc_receipt_method =    lc_country_prefix
                                      || '_CC OD ALL_CC_OLD')
              OR (lc_receipt_method =    lc_country_prefix
                                      || '_CC OD ALL_CC_BYPASS'))                                                 --v1.4
        THEN
            lc_payment_type := 'CREDIT_CARD';
        ELSIF lc_receipt_method =    lc_country_prefix
                                  || '_PAYPAL_OD'                                                        -- Defect 20779
        THEN
            lc_payment_type := 'CASH';
        ELSIF lc_receipt_method =    lc_country_prefix
                                  || '_AMAZON_OD'
        THEN
            lc_payment_type := 'CASH';
        ELSIF lc_receipt_method =    lc_country_prefix
                                      || '_EBAY_OD'
        THEN
            lc_payment_type := 'CASH';						--EBAY Changes
	*/
	    -- Start of adding changes as per Version 5.0 by Havish K
		ELSE
		    BEGIN
			    SELECT target_value1
                  INTO lc_payment_type
                  FROM xx_fin_translatevalues
                 WHERE translate_id IN (SELECT translate_id 
	                                      FROM xx_fin_translatedefinition 
	                                     WHERE translation_name = 'OD_AR_PYMT_TYPE' 
	                                       AND enabled_flag = 'Y')
	               AND lc_country_prefix||source_value1 = lc_receipt_method;
			EXCEPTION
			WHEN OTHERS
			THEN
			    lc_payment_type := NULL;
			END;	
        -- End of adding changes as per Version 5.0 by Havish K			
        END IF; 

        RETURN lc_payment_type;
    END;

-- ==========================================================================
-- procedure that returns the actual payment type based on the
--   org_id (country), od_payment_type lookup code
-- ==========================================================================
    FUNCTION get_payment_type(
        p_org_id           IN  NUMBER,
        p_od_payment_type  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)  := 'GET_PAYMENT_TYPE';
        lc_payment_type       VARCHAR2(100) DEFAULT NULL;
    BEGIN
-- ==========================================================================
-- determine the payment type for the given od payment type code
-- ==========================================================================
    -- Commented as per Version 5.0 by Havish K
    /*
        lc_payment_type :=
            CASE p_od_payment_type
                WHEN '01'
                    THEN 'CASH'                                                                                 -- CASH
                WHEN '10'
                    THEN 'CHECK'                                                                               -- CHECK
                WHEN '11'
                    THEN 'MAILCHECK'                                                                          -- REFUND
                WHEN '14'
                    THEN NULL                                                                         -- OD MONEY CARD1
                WHEN '16'
                    THEN 'DEBIT_CARD'                                                                     -- DEBIT CARD
                WHEN '17'
                    THEN NULL                                                                                 -- DINERS
                WHEN '18'
                    THEN 'GIFT_CARD'                                                                  -- OD MONEY CARD2
                WHEN '19'
                    THEN 'GIFT_CARD'                                                                  -- OD MONEY CARD3 OMX gift card consolidation
                WHEN '20'
                    THEN NULL                                                                             -- HOUSE ACTT
                WHEN '22'
                    THEN 'CREDIT_CARD'                                                                     -- OD CHARGE
                WHEN '24'
                    THEN 'CREDIT_CARD'                                                                          -- VISA
                WHEN '25'
                    THEN 'CREDIT_CARD'                                                                            -- MC
                WHEN '26'
                    THEN 'CREDIT_CARD'                                                                          -- AMEX
                WHEN '27'
                    THEN 'CREDIT_CARD'                                                                           -- SPS
                WHEN '29'
                    THEN 'CREDIT_CARD'                                                                      -- DISCOVER
                WHEN '30'
                    THEN 'TELECHECK'                                                                   -- TELECHECK ECA
                WHEN '31'
                    THEN 'CHECK'                                                                     -- TELECHECK PAPER
                WHEN '32'
                    THEN 'CASH'                                                                  -- PAYPAL Defect 20779
                WHEN '33'
                    THEN 'CASH'                                                                               -- AMAZON
				WHEN '35'
                    THEN 'CASH'                                                                               -- EBAY
                WHEN '51'
                    THEN 'CASH'                                                                     -- GIFT CERTIFICATE
                WHEN '80'
                    THEN 'CHECK'                                                                       -- FOREIGN_CHECK
                WHEN '81'
                    THEN 'CASH'                                                                         -- FOREIGN CASH
                WHEN 'AB'
                    THEN NULL                                                                        -- Account Billing
            END;
	*/
	    -- Start of adding changes as per Version 5.0 by Havish K
	    BEGIN
		    SELECT target_value1
              INTO lc_payment_type
              FROM xx_fin_translatevalues
             WHERE translate_id IN (SELECT translate_id 
	                                  FROM xx_fin_translatedefinition 
	                                 WHERE translation_name = 'OD_AR_PYMT_TYPES_CODES' 
	                                   AND enabled_flag = 'Y')
	           AND source_value1 = p_od_payment_type;
		EXCEPTION
		WHEN OTHERS
		THEN
		    lc_payment_type := NULL;
		END;
		-- End of adding changes as per Version 5.0 by Havish K
	    RETURN lc_payment_type;
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to the given
--   receipt method is given payment type
-- ==========================================================================
    FUNCTION is_payment_type(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL,
        p_matches_pmt_type   IN  VARCHAR2)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)  := 'IS_PAYMENT_TYPE';
        lc_payment_type       VARCHAR2(100) DEFAULT NULL;
    BEGIN
        lc_payment_type :=
            get_payment_type(p_org_id                 => p_org_id,
                             p_receipt_method_id      => p_receipt_method_id,
                             p_payment_type           => p_payment_type);

        IF (lc_payment_type = UPPER(p_matches_pmt_type))
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is CASH
-- ==========================================================================
    FUNCTION is_cash(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_CASH';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'CASH');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is CHECK
-- ==========================================================================
    FUNCTION is_check(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_CHECK';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'CHECK');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is CREDIT_CARD
-- ==========================================================================
    FUNCTION is_credit_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_CREDIT_CARD';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'CREDIT_CARD');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is DEBIT_CARD
-- ==========================================================================
    FUNCTION is_debit_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_DEBIT_CARD';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'DEBIT_CARD');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is MAILCHECK
-- ==========================================================================
    FUNCTION is_mailcheck(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_MAILCHECK';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'MAILCHECK');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is TELECHECK
-- ==========================================================================
    FUNCTION is_telecheck(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_TELECHECK';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'TELECHECK');
    END;

-- ==========================================================================
-- procedure that returns true/false if payment type associated to  the given
--   receipt method is GIFT_CARD
-- ==========================================================================
    FUNCTION is_gift_card(
        p_org_id             IN  NUMBER,
        p_receipt_method_id  IN  NUMBER,
        p_payment_type       IN  VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'IS_GIFT_CARD';
    BEGIN
        RETURN is_payment_type(p_org_id                 => p_org_id,
                               p_receipt_method_id      => p_receipt_method_id,
                               p_payment_type           => p_payment_type,
                               p_matches_pmt_type       => 'GIFT_CARD');
    END;

-- ==========================================================================
-- function that return the pre-payment application line for the given
--   cash receipt
-- ==========================================================================
    FUNCTION get_prepay_application_record(
        p_cash_receipt_id   IN  NUMBER,
        p_reference_type    IN  VARCHAR2,
        p_reference_number  IN  VARCHAR2)
        RETURN gcu_prepay_appl%ROWTYPE
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)              := 'GET_PREPAY_APPLICATION';
        x_prepay_appl_rec     gcu_prepay_appl%ROWTYPE;
    BEGIN
        OPEN gcu_prepay_appl(cp_cash_receipt_id       => p_cash_receipt_id,
                             cp_reference_type        => p_reference_type,
                             cp_reference_number      => p_reference_number);

        FETCH gcu_prepay_appl
        INTO  x_prepay_appl_rec;

        CLOSE gcu_prepay_appl;

        RETURN x_prepay_appl_rec;
    END;

-- ==========================================================================
-- unapply the prepayment application
-- ==========================================================================
    PROCEDURE unapply_prepayment_application(
        p_prepay_appl_row  IN OUT NOCOPY  gcu_prepay_appl%ROWTYPE)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)   := 'UNAPPLY_PREPAYMENT_APPL';
        x_return_status       VARCHAR2(20)   DEFAULT NULL;
        x_msg_count           NUMBER         DEFAULT NULL;
        x_msg_data            VARCHAR2(4000) DEFAULT NULL;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- unapply the pre-payment application
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Unapply Pre-Payment Receivable Application');
            put_log_line(   '  recv appl id  = '
                         || p_prepay_appl_row.receivable_application_id);
            put_log_line(   '  appl ref type = '
                         || p_prepay_appl_row.application_ref_type);
            put_log_line(   '  appl ref num  = '
                         || p_prepay_appl_row.application_ref_num);
            put_log_line(   '  prepay amount = '
                         || p_prepay_appl_row.amount_applied);
        END IF;

        ar_receipt_api_pub.unapply_other_account
                                            (p_api_version                    => 1.0,
                                             p_init_msg_list                  => fnd_api.g_true,
                                             p_commit                         => fnd_api.g_false,
                                             p_validation_level               => fnd_api.g_valid_level_full,
                                             x_return_status                  => x_return_status,
                                             x_msg_count                      => x_msg_count,
                                             x_msg_data                       => x_msg_data,
                                             p_cash_receipt_id                => p_prepay_appl_row.cash_receipt_id,
                                             p_receivable_application_id      => p_prepay_appl_row.receivable_application_id,
                                             p_called_from                    => 'PREPAYMENT');

        -- 'I1025' );  -- defect 7462
        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully Unapplied the Prepayment.');
                put_log_line(   '  cash_receipt_id = '
                             || p_prepay_appl_row.cash_receipt_id);
                put_log_line(   '  receivable_application_id = '
                             || p_prepay_appl_row.receivable_application_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name       => lc_sub_name,
                             p_msg_count      => x_msg_count,
                             p_api_name       => 'AR_RECEIPT_API_PUB.unapply_other_account');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- procedure that re-applies remainder of the receipt to the prepayment
-- ==========================================================================
    PROCEDURE apply_prepayment_application(
        p_prepay_appl_row  IN OUT NOCOPY  gcu_prepay_appl%ROWTYPE)
    IS
        lc_sub_name         CONSTANT VARCHAR2(50)   := 'apply_prepayment';
        x_return_status              VARCHAR2(1)    DEFAULT NULL;
        x_msg_count                  NUMBER         DEFAULT NULL;
        x_msg_data                   VARCHAR2(4000) DEFAULT NULL;
        ln_receivables_trx_id        NUMBER         DEFAULT NULL;
        x_receivable_application_id  NUMBER         DEFAULT NULL;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
        END IF;

-- ==========================================================================
-- re-apply the pre-payment application for the difference
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Re-Apply Receipt to prepayment with reference to order.');
            put_log_line(   '  Cash Receipt Id  = '
                         || p_prepay_appl_row.cash_receipt_id);
            put_log_line(   '  Payment Set Id   = '
                         || p_prepay_appl_row.payment_set_id);
            put_log_line(   '  Amount to re-apply = '
                         || p_prepay_appl_row.amount_applied);
            put_log_line('Fetching prepayment application activity for this org_id...');
        END IF;

        ln_receivables_trx_id := get_prepayment_recv_trx_id(p_org_id      => p_prepay_appl_row.org_id);

        IF (gb_debug)
        THEN
            put_log_line(   '  Prepayment Trx Id = '
                         || ln_receivables_trx_id);
            put_log_line('Prepay Appl Row: ');
            put_log_line(   '  Cash Receipt Id   = '
                         || p_prepay_appl_row.cash_receipt_id);
            put_log_line(   '  Amt Applied       = '
                         || p_prepay_appl_row.amount_applied);
            put_log_line(   '  Payment Set Id    = '
                         || p_prepay_appl_row.payment_set_id);
            put_log_line(   '  App Ref Type      = '
                         || p_prepay_appl_row.application_ref_type);
            put_log_line(   '  App Ref Id        = '
                         || p_prepay_appl_row.application_ref_id);
            put_log_line(   '  App Ref Num       = '
                         || p_prepay_appl_row.application_ref_num);
            put_log_line(   '  Sec App Ref Id    = '
                         || p_prepay_appl_row.secondary_application_ref_id);
        END IF;

        ar_receipt_api_pub.apply_other_account
                                      (p_api_version                       => 1.0,
                                       p_init_msg_list                     => fnd_api.g_true,
                                       p_commit                            => fnd_api.g_false,
                                       p_validation_level                  => fnd_api.g_valid_level_full,
                                       x_return_status                     => x_return_status,
                                       x_msg_count                         => x_msg_count,
                                       x_msg_data                          => x_msg_data,
                                       p_cash_receipt_id                   => p_prepay_appl_row.cash_receipt_id,
                                       p_amount_applied                    => p_prepay_appl_row.amount_applied,
                                       p_receivables_trx_id                => ln_receivables_trx_id,
                                       p_payment_set_id                    => p_prepay_appl_row.payment_set_id,
                                       p_application_ref_type              => p_prepay_appl_row.application_ref_type,
                                       p_application_ref_id                => p_prepay_appl_row.application_ref_id,
                                       p_application_ref_num               => p_prepay_appl_row.application_ref_num,
                                       p_secondary_application_ref_id      => p_prepay_appl_row.secondary_application_ref_id,
                                       p_applied_payment_schedule_id       => -7,  --ar_payment_schedules pre-payment id
                                       p_receivable_application_id         => x_receivable_application_id,
                                       p_comments                          => 'I1025 (Apply Prepayment)',
                                       p_called_from                       => 'PREPAYMENT');

        -- 'I1025' );  -- defect 7462
        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('- Successfully Re-Applied Receipt to prepayment.');
                put_log_line(   '   cash_receipt_id = '
                             || p_prepay_appl_row.cash_receipt_id);
                put_log_line(   '   receivable_application_id = '
                             || x_receivable_application_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name       => lc_sub_name,
                             p_msg_count      => x_msg_count,
                             p_api_name       => 'AR_RECEIPT_API_PUB.apply_other_account');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- get the store location number (from attribute1) for the given organization
-- ==========================================================================
    FUNCTION get_store_location(
        p_organization_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_store_location  VARCHAR2(30) DEFAULT NULL;

        CURSOR c_org(
            cp_organization_id  IN  NUMBER)
        IS
            SELECT LPAD(haou.attribute1,
                        6,
                        '0')
            FROM   hr_all_organization_units haou
            WHERE  haou.organization_id = cp_organization_id;
    BEGIN
        OPEN c_org(cp_organization_id      => p_organization_id);

        FETCH c_org
        INTO  lc_store_location;

        CLOSE c_org;

        RETURN lc_store_location;
    END;

-- ==========================================================================
-- get the meaning for the given od payment type code
-- ==========================================================================
    FUNCTION get_od_payment_type(
        p_od_payment_type  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_od_payment_type  VARCHAR2(30) DEFAULT NULL;

        CURSOR c_od_payment_type(
            cp_od_payment_type  IN  VARCHAR2)
        IS
            SELECT meaning
            FROM   oe_lookups
            WHERE  lookup_type = 'OD_PAYMENT_TYPES' AND lookup_code = cp_od_payment_type;
    BEGIN
        OPEN c_od_payment_type(cp_od_payment_type      => p_od_payment_type);

        FETCH c_od_payment_type
        INTO  lc_od_payment_type;

        CLOSE c_od_payment_type;

        RETURN lc_od_payment_type;
    END;

-- ==========================================================================
-- procedure to insert the additional information for AR Receipts into
--   the custom table XX_AR_CASH_RECEIPTS_EXT
-- ==========================================================================
    PROCEDURE insert_receipt_ext_info(
        p_receipt_ext_attributes  IN OUT NOCOPY  xx_ar_cash_receipts_ext%ROWTYPE)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50) := 'INSERT_RECEIPT_EXT_INFO';
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line('Inserting the additional information for AR Receipts...');
            put_log_line(   '  Cash Receipt Id  = '
                         || p_receipt_ext_attributes.cash_receipt_id);
            put_log_line(   '  CC Entry Mode    = '
                         || p_receipt_ext_attributes.cc_entry_mode);
            put_log_line(   '  CVV Resp Code    = '
                         || p_receipt_ext_attributes.cvv_resp_code);
            put_log_line(   '  AVS Resp Code    = '
                         || p_receipt_ext_attributes.avs_resp_code);
            put_log_line(   '  Auth Entry Mode  = '
                         || p_receipt_ext_attributes.auth_entry_mode);
            put_log_line(   '  Orig Sys Doc Ref = '
                         || p_receipt_ext_attributes.orig_sys_document_ref);
            put_log_line(   '  Payment Number   = '
                         || p_receipt_ext_attributes.payment_number);
            put_log_line(   '  Import File Name = '
                         || p_receipt_ext_attributes.imp_file_name);
            put_log_line(   '  OM Import Date   = '
                         || p_receipt_ext_attributes.om_import_date);
            put_log_line(   '  I1025 Rec Type   = '
                         || p_receipt_ext_attributes.i1025_record_type);
            put_log_line(   '  I1025 amount     = '
                         || p_receipt_ext_attributes.i1025_amount);
--    put_log_line('  Disc Net info    = ' || p_receipt_ext_attributes.disc_net_info ); -- Defect 11482
--    put_log_line('  Ajb Ref No:      = ' || p_receipt_ext_attributes.ajb_ref_nbr ); -- Defect 11482
        END IF;

-- ==========================================================================
-- insert the credit card refund information into the custom iPayment table
-- ==========================================================================
        INSERT INTO xx_ar_cash_receipts_ext
                    (cash_receipt_id,
                     cc_entry_mode,
                     cvv_resp_code,
                     avs_resp_code,
                     auth_entry_mode,
                     payment_number,
                     orig_sys_document_ref,
                     imp_file_name,
                     om_import_date,
                     i1025_record_type,
                     i1025_amount,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     last_update_login,
                     disc_net_info                                                                       -- Defect 11482
--    ajb_ref_nbr -- Defect 11482
                    )
             VALUES (p_receipt_ext_attributes.cash_receipt_id,
                     p_receipt_ext_attributes.cc_entry_mode,
                     p_receipt_ext_attributes.cvv_resp_code,
                     p_receipt_ext_attributes.avs_resp_code,
                     p_receipt_ext_attributes.auth_entry_mode,
                     p_receipt_ext_attributes.payment_number,
                     p_receipt_ext_attributes.orig_sys_document_ref,
                     p_receipt_ext_attributes.imp_file_name,
                     p_receipt_ext_attributes.om_import_date,
                     p_receipt_ext_attributes.i1025_record_type,
                     p_receipt_ext_attributes.i1025_amount,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.login_id,
                     p_receipt_ext_attributes.disc_net_info                                              -- Defect 11482
--    p_receipt_ext_attributes.ajb_ref_nbr -- Defect 11482
                    );

        IF (gb_debug)
        THEN
            put_log_line(   'Inserted '
                         || SQL%ROWCOUNT
                         || ' row[s] in XX_AR_CASH_RECEIPTS_EXT');
        END IF;
    END;

-- ==========================================================================
-- get the debit card approval reference based on specific payment fields
--   Concatenate the following segments:
--   1. Store/Location Number - 6 digits ? from POS transaction number
--   2. Transaction Date - 8 digits (CCYYMMDD) ? from POS transaction number
--   3. Register Number - 2 digits ? from POS transaction number
--   4. Account Number Mask - 10 digits - First 6 digits and last 4 digits) - from CC mask number
--   5. Payment Amount - 4 digits - rightmost 4 digits of the approved amount
--       (ie. $125.48 would be 2548; $1.25 would be 0125)
-- ==========================================================================
    FUNCTION get_debit_card_approval_ref(
        p_pos_transaction_number  IN  VARCHAR2,
        p_cc_mask_number          IN  VARCHAR2,
        p_payment_amount          IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_segment1                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment2                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment3                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment4                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment5                 VARCHAR2(50)  DEFAULT NULL;
        lc_debit_card_approval_ref  VARCHAR2(250) DEFAULT NULL;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line('Build Debit Card Approval References');
            put_log_line(   '  POS Trans Number: '
                         || p_pos_transaction_number);
            put_log_line(   '  CC Mask Number  : '
                         || p_cc_mask_number);
            put_log_line(   '  Payment Amount  : '
                         || p_payment_amount);
            put_log_line();
        END IF;

        lc_segment1 := LPAD(SUBSTR(p_pos_transaction_number,
                                   1,
                                   4),
                            6,
                            '0');
        lc_segment2 := SUBSTR(p_pos_transaction_number,
                              5,
                              8);
-- ==========================================================================
-- defect 10733 - register (segment3) on the debit card reference needs to
--   be "00" because of limitations on AJB for getting the register number
-- ==========================================================================
        lc_segment3 := '00';
        --lc_segment3 := SUBSTR(p_pos_transaction_number,14,2);
        lc_segment4 := p_cc_mask_number;
-- ==========================================================================
-- format the payment amount as required by segment 5
-- ==========================================================================
        lc_segment5 := REPLACE(TO_CHAR(ABS(p_payment_amount),
                                       'fm999999999999999999999.00'),
                               '.');

        IF (LENGTH(lc_segment5) < 4)
        THEN
            lc_segment5 := LPAD(lc_segment5,
                                4,
                                '0');
        END IF;

        lc_segment5 := SUBSTR(lc_segment5,
                              -4);

        IF (gb_debug)
        THEN
            put_log_line(   '  Segment 1 (Store Num)    = '
                         || lc_segment1);
            put_log_line(   '  Segment 2 (Trans Date)   = '
                         || lc_segment2);
            put_log_line(   '  Segment 3 (Register Num) = '
                         || lc_segment3);
            put_log_line(   '  Segment 4 (CC Mask Num)  = '
                         || lc_segment4);
            put_log_line(   '  Segment 5 (Payment Amt)  = '
                         || lc_segment5);
        END IF;

-- ==========================================================================
-- build the approval reference from each of the segments
-- ==========================================================================
        lc_debit_card_approval_ref :=    lc_segment1
                                      || lc_segment2
                                      || lc_segment3
                                      || lc_segment4
                                      || lc_segment5;

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'Debit Card Approval Ref = '
                         || lc_debit_card_approval_ref);
            put_log_line();
        END IF;

        RETURN lc_debit_card_approval_ref;
    END;

-- ==========================================================================
-- set the receipt DFF attributes and references based on the usage
-- ==========================================================================
    PROCEDURE set_receipt_attr_references(
        p_receipt_context             IN             VARCHAR2,
        p_orig_sys_document_ref       IN             oe_order_headers.orig_sys_document_ref%TYPE,
        p_receipt_method_id           IN             ar_cash_receipts.receipt_method_id%TYPE,
        p_payment_type_code           IN             oe_payments.payment_type_code%TYPE,
        p_check_number                IN             oe_payments.check_number%TYPE DEFAULT NULL,
        p_paid_at_store_id            IN             NUMBER DEFAULT NULL,
        p_ship_from_org_id            IN             oe_order_headers.ship_from_org_id%TYPE DEFAULT NULL,
        p_cc_auth_manual              IN             VARCHAR2 DEFAULT NULL,
        p_cc_auth_ps2000              IN             VARCHAR2 DEFAULT NULL,
        p_merchant_number             IN             VARCHAR2 DEFAULT NULL,
        --p_company_code                 IN  VARCHAR2 DEFAULT NULL,
        p_od_payment_type             IN             VARCHAR2 DEFAULT NULL,
        p_debit_card_approval_ref     IN             VARCHAR2 DEFAULT NULL,
        p_cc_mask_number              IN             VARCHAR2 DEFAULT NULL,
        p_payment_amount              IN             NUMBER DEFAULT NULL,
        p_applied_customer_trx_id     IN             NUMBER DEFAULT NULL,
        p_original_receipt_id         IN             NUMBER DEFAULT NULL,
        p_transaction_number          IN             VARCHAR2 DEFAULT NULL,
        p_additional_auth_codes       IN             VARCHAR2 DEFAULT NULL,
        p_imp_file_name               IN             VARCHAR2 DEFAULT NULL,
        p_om_import_date              IN             DATE DEFAULT NULL,
        p_i1025_record_type           IN             VARCHAR2 DEFAULT gc_i1025_record_type_order,
        p_called_from                 IN             VARCHAR2 DEFAULT NULL,
        p_original_order              IN             VARCHAR2 DEFAULT NULL,
        p_print_debug                 IN             VARCHAR2 DEFAULT fnd_api.g_false,
        x_receipt_number              IN OUT NOCOPY  ar_cash_receipts.receipt_number%TYPE,
        x_receipt_comments            IN OUT NOCOPY  ar_cash_receipts.comments%TYPE,
        x_customer_receipt_reference  IN OUT NOCOPY  ar_cash_receipts.customer_receipt_reference%TYPE,
        x_attribute_rec               IN OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
        x_app_customer_reference      IN OUT NOCOPY  ar_receivable_applications.customer_reference%TYPE,
        x_app_comments                IN OUT NOCOPY  ar_receivable_applications.comments%TYPE,
        x_app_attribute_rec           IN OUT NOCOPY  ar_receipt_api_pub.attribute_rec_type,
        x_receipt_ext_attributes      IN OUT NOCOPY  xx_ar_cash_receipts_ext%ROWTYPE)
    IS
        lc_sub_name   CONSTANT VARCHAR2(50) := 'SET_RECEIPT_ATTR_REFERENCES';
        l_transaction_number   VARCHAR2(50) DEFAULT NULL;
        l_payment_type         VARCHAR2(50) DEFAULT NULL;
        a_addl_auth_codes_tab  stringarray  DEFAULT stringarray();
--  lc_disc_net_info                VARCHAR2(250); -- Defect 11482
--  lc_card_name                    xx_fin_translatevalues.target_value1%TYPE; -- Defect 11482
    BEGIN
-- ==========================================================================
-- check if printing debug info (log)
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_print_debug)
        THEN
            gb_debug := TRUE;
        ELSE
            gb_debug := FALSE;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_current_datetime();
        END IF;

        IF (p_transaction_number IS NOT NULL)
        THEN
            l_transaction_number := p_transaction_number;
        ELSE
            l_transaction_number := p_orig_sys_document_ref;
        END IF;

-- ==========================================================================
-- get the payment type based on the receipt method
--   and validate the receipt method is defined
-- ==========================================================================
        IF (p_receipt_method_id IS NOT NULL)
        THEN
            l_payment_type :=
                get_payment_type(p_org_id                 => fnd_global.org_id,
                                 p_receipt_method_id      => p_receipt_method_id,
                                 p_payment_type           => p_payment_type_code);
        ELSE
            raise_missing_param_errors(p_sub_name        => lc_sub_name,
                                       p_param_name      => 'Receipt Method (RECEIPT_METHOD_ID)');
        END IF;

        IF (p_receipt_context = 'SALES_ACCT')
        THEN
-- ==========================================================================
-- For Receipt Number
--  Check/Telecheck use check number, for everything else leave as is (automatic)
-- ==========================================================================
            IF (x_receipt_number IS NULL AND l_payment_type IN('CHECK', 'TELECHECK'))
            THEN
                x_receipt_number := p_check_number;
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  REF: x_receipt_number = '
                             || x_receipt_number);
            END IF;

-- ==========================================================================
-- For Comments on the AR Receipt
--  build a generic comment if parameter is not given
-- ==========================================================================
            IF (x_receipt_comments IS NULL)
            THEN
                x_receipt_comments :=    'OD Receipt with Prepayment ('
                                      || l_payment_type
                                      || ')';
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  REF: x_receipt_comments = '
                             || x_receipt_comments);
            END IF;

-- ==========================================================================
-- For Comments on the Application
--  build a generic comment if parameter is not given
-- ==========================================================================
            IF (x_app_comments IS NULL)
            THEN
                x_app_comments :=    'OD Prepayment ('
                                  || l_payment_type
                                  || ')';
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  REF: x_app_comments = '
                             || x_app_comments);
            END IF;

-- ==========================================================================
-- For Customer Receipt Reference on the AR Receipt
--  Gift Cards use check number
--  Debit Cards use the approval reference
--  Telechecks use a re-formated legacy order number
--    - prepend 2 more 0's to the register number segment to make it 5 bytes
--  For everything else use legacy order number
-- ==========================================================================
            IF (x_customer_receipt_reference IS NULL)
            THEN
                IF (l_payment_type = 'GIFT_CARD')
                THEN
                    x_customer_receipt_reference := p_check_number;
                ELSIF(l_payment_type = 'DEBIT_CARD')
                THEN
                    x_customer_receipt_reference :=
                        get_debit_card_approval_ref(p_pos_transaction_number      => l_transaction_number,
                                                    p_cc_mask_number              => p_cc_mask_number,
                                                    p_payment_amount              => p_payment_amount);
                ELSIF(l_payment_type = 'TELECHECK')
                THEN
                    x_customer_receipt_reference :=
                                            SUBSTR(l_transaction_number,
                                                   1,
                                                   12)
                                         || '00'
                                         || SUBSTR(l_transaction_number,
                                                   13);
                ELSE
                    x_customer_receipt_reference := l_transaction_number;
                END IF;
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  REF: x_customer_receipt_reference = '
                             || x_customer_receipt_reference);
            END IF;

-- ==========================================================================
-- For Customer Receipt Reference on the Application
--  use the same customer reference as the receipt reference
-- ==========================================================================
            IF (x_app_customer_reference IS NULL)
            THEN
                x_app_customer_reference := x_customer_receipt_reference;
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  REF: x_app_customer_reference = '
                             || x_app_customer_reference);
            END IF;

-- ==========================================================================
-- Set remaining descriptive flexfields on the AR receipt
-- ==========================================================================
            x_attribute_rec.attribute_category := p_receipt_context;

            IF (p_paid_at_store_id IS NOT NULL)
            THEN
                x_attribute_rec.attribute1 := get_store_location(p_organization_id      => p_paid_at_store_id);
            END IF;

            IF (p_ship_from_org_id IS NOT NULL)
            THEN
                x_attribute_rec.attribute2 := get_store_location(p_organization_id      => p_ship_from_org_id);
            END IF;

-- ==========================================================================
-- For Voice Authorization Flexfield (ATTRIBUTE3)
--  if attribute is defined as Y or 1, then DFF value should be 1 (Voice)
--  everything else should be 2 (Automatic)
-- ==========================================================================
            IF (p_cc_auth_manual IN('Y', '1'))
            THEN
                x_attribute_rec.attribute3 := '1';
            ELSE
                x_attribute_rec.attribute3 := '2';
            END IF;

            x_attribute_rec.attribute4 := p_cc_auth_ps2000;
            x_attribute_rec.attribute5 := p_merchant_number;
            x_attribute_rec.attribute7 := p_orig_sys_document_ref;
            x_attribute_rec.attribute12 := p_original_order;

            IF (p_od_payment_type IS NOT NULL)
            THEN
                x_attribute_rec.attribute14 := get_od_payment_type(p_od_payment_type      => p_od_payment_type);
            END IF;

            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   '  DFF: receipt context = '
                             || x_attribute_rec.attribute_category);
                put_log_line(   '  DFF: receipt attribute1 = '
                             || x_attribute_rec.attribute1);
                put_log_line(   '  DFF: receipt attribute2 = '
                             || x_attribute_rec.attribute2);
                put_log_line(   '  DFF: receipt attribute3 = '
                             || x_attribute_rec.attribute3);
                put_log_line(   '  DFF: receipt attribute4 = '
                             || x_attribute_rec.attribute4);
                put_log_line(   '  DFF: receipt attribute5 = '
                             || x_attribute_rec.attribute5);
                put_log_line(   '  DFF: receipt attribute7 = '
                             || x_attribute_rec.attribute7);
                put_log_line(   '  DFF: receipt attribute12 = '
                             || x_attribute_rec.attribute12);
                put_log_line(   '  DFF: receipt attribute14 = '
                             || x_attribute_rec.attribute14);
                put_log_line();
            END IF;

-- ==========================================================================
-- Set remaining descriptive flexfields on the AR receipt applications
-- ==========================================================================
            x_app_attribute_rec.attribute_category := p_receipt_context;
            x_app_attribute_rec.attribute7 := p_orig_sys_document_ref;
            x_app_attribute_rec.attribute12 := p_applied_customer_trx_id;

            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line(   '  DFF: app context = '
                             || x_app_attribute_rec.attribute_category);
                put_log_line(   '  DFF: app attribute7 = '
                             || x_app_attribute_rec.attribute7);
                put_log_line(   '  DFF: app attribute12 = '
                             || x_app_attribute_rec.attribute12);
                put_log_line();
            END IF;
        END IF;

        IF (p_orig_sys_document_ref IS NOT NULL)
        THEN
            x_receipt_ext_attributes.orig_sys_document_ref := p_orig_sys_document_ref;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: orig_sys_document_ref = '
                             || x_receipt_ext_attributes.orig_sys_document_ref);
            END IF;
        END IF;

        IF (p_payment_amount IS NOT NULL)
        THEN
            x_receipt_ext_attributes.i1025_amount := p_payment_amount;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: I1025_amount = '
                             || x_receipt_ext_attributes.i1025_amount);
            END IF;
        END IF;

        IF (p_imp_file_name IS NOT NULL)
        THEN
            x_receipt_ext_attributes.imp_file_name := p_imp_file_name;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: imp_file_name = '
                             || x_receipt_ext_attributes.imp_file_name);
            END IF;
        END IF;

        IF (p_om_import_date IS NOT NULL)
        THEN
            x_receipt_ext_attributes.om_import_date := p_om_import_date;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: om_import_date = '
                             || x_receipt_ext_attributes.om_import_date);
            END IF;
        END IF;

        IF (p_i1025_record_type IS NOT NULL)
        THEN
            x_receipt_ext_attributes.i1025_record_type := p_i1025_record_type;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: I1025_record_type = '
                             || x_receipt_ext_attributes.i1025_record_type);
            END IF;
        END IF;

        IF (p_additional_auth_codes IS NOT NULL)
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line('Separate the additional credit card authorization codes... ');
                put_log_line(   '  p_additional_auth_codes = '
                             || p_additional_auth_codes);
                put_log_line('  delimiter =  : ');
            END IF;

            a_addl_auth_codes_tab :=
                                  xx_ar_prepayments_pkg.explode(p_string         => p_additional_auth_codes,
                                                                p_delimiter      => ':');

            IF (gb_debug)
            THEN
                put_log_line(   '  Array Count = '
                             || a_addl_auth_codes_tab.COUNT);
            END IF;

            IF (a_addl_auth_codes_tab.COUNT >= 4)
            THEN
                x_receipt_ext_attributes.cc_entry_mode := a_addl_auth_codes_tab(1);
                x_receipt_ext_attributes.cvv_resp_code := a_addl_auth_codes_tab(2);
                x_receipt_ext_attributes.avs_resp_code := a_addl_auth_codes_tab(3);
                x_receipt_ext_attributes.auth_entry_mode := a_addl_auth_codes_tab(4);
--      x_receipt_ext_attributes.disc_net_info   := a_addl_auth_codes_tab(5); -- Defect 11482
--      x_receipt_ext_attributes.ajb_ref_nbr     := a_addl_auth_codes_tab(6); -- Defect 11482
            END IF;

            IF (gb_debug)
            THEN
                put_log_line(   '  EXT: cc_entry_mode = '
                             || x_receipt_ext_attributes.cc_entry_mode);
                put_log_line(   '  EXT: cvv_resp_code = '
                             || x_receipt_ext_attributes.cvv_resp_code);
                put_log_line(   '  EXT: avs_resp_code = '
                             || x_receipt_ext_attributes.avs_resp_code);
                put_log_line(   '  EXT: auth_entry_mode = '
                             || x_receipt_ext_attributes.auth_entry_mode);
--      put_log_line('  EXT: disc_net_info = '   || x_receipt_ext_attributes.disc_net_info ); -- Defect 11482
--      put_log_line('  EXT: ajb_ref_nbr = '     || x_receipt_ext_attributes.ajb_ref_nbr ); -- Defect 11482
                put_log_line();
            END IF;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_current_datetime();
            put_log_line();
        END IF;
    END;

-- ==========================================================================
-- create prepayment api call
-- ==========================================================================
    PROCEDURE create_prepayment(
        p_api_version                   IN             NUMBER,
        p_init_msg_list                 IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_commit                        IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_validation_level              IN             NUMBER DEFAULT fnd_api.g_valid_level_full,
        x_return_status                 OUT NOCOPY     VARCHAR2,
        x_msg_count                     OUT NOCOPY     NUMBER,
        x_msg_data                      OUT NOCOPY     VARCHAR2,
        p_print_debug                   IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_receipt_method_id             IN             ar_cash_receipts.receipt_method_id%TYPE,
        p_payment_type_code             IN             oe_payments.payment_type_code%TYPE DEFAULT NULL,
        p_currency_code                 IN             ar_cash_receipts.currency_code%TYPE DEFAULT NULL,
        p_amount                        IN             ar_cash_receipts.amount%TYPE,
        p_payment_number                IN             NUMBER DEFAULT NULL,
        p_sas_sale_date                 IN             DATE DEFAULT NULL,
        p_receipt_date                  IN             ar_cash_receipts.receipt_date%TYPE DEFAULT NULL,
        p_gl_date                       IN             ar_cash_receipt_history.gl_date%TYPE DEFAULT NULL,
        p_customer_id                   IN             ar_cash_receipts.pay_from_customer%TYPE DEFAULT NULL,
        p_customer_site_use_id          IN             hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
        p_customer_bank_account_id      IN             ar_cash_receipts.customer_bank_account_id%TYPE DEFAULT NULL,
        p_customer_receipt_reference    IN             ar_cash_receipts.customer_receipt_reference%TYPE DEFAULT NULL,
        p_remittance_bank_account_id    IN             ar_cash_receipts.remittance_bank_account_id%TYPE DEFAULT NULL,
        p_called_from                   IN             VARCHAR2 DEFAULT NULL,
        p_attribute_rec                 IN             ar_receipt_api_pub.attribute_rec_type
                DEFAULT ar_receipt_api_pub.attribute_rec_const,
        p_receipt_comments              IN             VARCHAR2 DEFAULT NULL,
        p_application_ref_type          IN             ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
        p_application_ref_id            IN             ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
        p_application_ref_num           IN             ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
        p_secondary_application_ref_id  IN             ar_receivable_applications.secondary_application_ref_id%TYPE
                DEFAULT NULL,
        p_apply_date                    IN             ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
        p_apply_gl_date                 IN             ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
        p_amount_applied                IN             ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
        p_app_attribute_rec             IN             ar_receipt_api_pub.attribute_rec_type
                DEFAULT ar_receipt_api_pub.attribute_rec_const,
        p_app_comments                  IN             ar_receivable_applications.comments%TYPE DEFAULT NULL,
        x_payment_set_id                IN OUT NOCOPY  NUMBER,              -- pass payment_set_id for multiple payments
        x_cash_receipt_id               OUT NOCOPY     ar_cash_receipts.cash_receipt_id%TYPE,
        x_receipt_number                IN OUT NOCOPY  ar_cash_receipts.receipt_number%TYPE,
        p_receipt_ext_attributes        IN             xx_ar_cash_receipts_ext%ROWTYPE
                DEFAULT g_default_receipt_ext_attrs)
    IS
        lc_sub_name            CONSTANT VARCHAR2(50)                                             := 'CREATE_PREPAYMENT';
        x_application_ref_type          ar_receivable_applications.application_ref_type%TYPE  := p_application_ref_type;
        x_application_ref_id            ar_receivable_applications.application_ref_id%TYPE      := p_application_ref_id;
        x_application_ref_num           ar_receivable_applications.application_ref_num%TYPE    := p_application_ref_num;
        x_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE
                                                                                      := p_secondary_application_ref_id;
        x_customer_bank_account_id      ar_cash_receipts.customer_bank_account_id%TYPE
                                                                                     DEFAULT p_customer_bank_account_id;
        x_credit_card_approval_code     ar_cash_receipts.approval_code%TYPE;
        l_attributes_rec                ar_receipt_api_pub.attribute_rec_type                        := p_attribute_rec;
        l_app_attributes_rec            ar_receipt_api_pub.attribute_rec_type                    := p_app_attribute_rec;
        l_receipt_ext_attributes        xx_ar_cash_receipts_ext%ROWTYPE                     := p_receipt_ext_attributes;
        x_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE      DEFAULT NULL;
        l_payment_type                  VARCHAR2(50)                                                   DEFAULT NULL;
        x_cash_receipt_rec              ar_cash_receipts%ROWTYPE;
        ln_receipt_count                NUMBER                                                         DEFAULT 0;
        lc_receipt_number               ar_cash_receipts.receipt_number%TYPE                        := x_receipt_number;
        ld_new_receipt_date             DATE                                                           DEFAULT NULL;
        ld_receipt_date                 ar_cash_receipts.receipt_date%TYPE                       DEFAULT p_receipt_date;
        ld_gl_date                      ar_cash_receipt_history.gl_date%TYPE                          DEFAULT p_gl_date;
        ld_apply_date                   ar_receivable_applications.apply_date%TYPE                 DEFAULT p_apply_date;
        ld_apply_gl_date                ar_receivable_applications.gl_date%TYPE                 DEFAULT p_apply_gl_date;
        ln_start_time                   NUMBER                                                         DEFAULT NULL;
        ln_start_api_time               NUMBER                                                         DEFAULT NULL;
        lb_debug_back                   BOOLEAN                                                        DEFAULT NULL;
        lc_card_name                    xx_fin_translatevalues.target_value1%TYPE;                      -- Defect 11482
        lc_return_status                VARCHAR2(1);
        x_payment_server_order_num      ar_cash_receipts.payment_server_order_num%TYPE;
        x_payment_response_error_code   VARCHAR2(200);

        CURSOR lcu_duplicate_receipt(
            cp_receipt_number  IN  VARCHAR2,
            cp_receipt_date    IN  DATE,
            cp_receipt_amount  IN  NUMBER,
            cp_customer_id     IN  NUMBER)
        IS
            SELECT COUNT(1)
            FROM   ar_cash_receipts acr
            WHERE  acr.receipt_number = cp_receipt_number
            AND    acr.receipt_date = cp_receipt_date
            AND    acr.amount = cp_receipt_amount
            AND    acr.pay_from_customer = cp_customer_id
            AND    acr.TYPE = 'CASH'
            AND    acr.status <> 'REV';
    BEGIN
-- Starting Defect 11482
        BEGIN
            SELECT target_value1
            INTO   lc_card_name
            FROM   xx_fin_translatedefinition xftd,
                   xx_fin_translatevalues xftv
            WHERE  translation_name = 'OD_IBY_CREDIT_CARD_TYPE'
            AND    xftv.translate_id = xftd.translate_id
            AND    xftv.source_value1 = l_attributes_rec.attribute14
            AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    xftv.enabled_flag = 'Y'
            AND    xftd.enabled_flag = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_card_name := NULL;
        END;

-- Ending Defect 11482

        -- ==========================================================================
-- check if printing debug info (log)
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_print_debug)
        THEN
            gb_debug := TRUE;
        ELSE
            gb_debug := FALSE;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_current_datetime();
        END IF;

        ln_start_time := get_timestamp();
-- ==========================================================================
-- Clear existing I1025 messages
-- ==========================================================================
        clear_i1025_messages(p_i1025_record_type          => gc_i1025_record_type_order,
                             p_orig_sys_document_ref      => p_attribute_rec.attribute7,
                             p_payment_number             => NVL(p_payment_number,
                                                                 0),
                             p_request_id                 => NVL(fnd_global.conc_request_id,
                                                                 -1));
-- ==========================================================================
-- Set savepoint for reapplying the prepayment
-- ==========================================================================
        SAVEPOINT before_create_xx_prepayment;

-- ==========================================================================
-- Initialize message list if p_init_msg_list is set to TRUE
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_init_msg_list)
        THEN
            fnd_msg_pub.initialize;
        END IF;

-- ==========================================================================
-- Initialize the return status to success
-- ==========================================================================
        x_return_status := fnd_api.g_ret_sts_success;

-- ==========================================================================
-- validate the customer account is defined
-- ==========================================================================
        IF (p_customer_id IS NULL)
        THEN
            raise_missing_param_errors(p_sub_name        => lc_sub_name,
                                       p_param_name      => 'Customer Account (CUSTOMER_ID)');
        END IF;

-- ==========================================================================
-- get the payment type based on the receipt method
--   and validate the receipt method is defined
-- ==========================================================================
        IF (p_receipt_method_id IS NOT NULL)
        THEN
            l_payment_type :=
                get_payment_type(p_org_id                 => fnd_global.org_id,
                                 p_receipt_method_id      => p_receipt_method_id,
                                 p_payment_type           => p_payment_type_code);
        ELSE
            raise_missing_param_errors(p_sub_name        => lc_sub_name,
                                       p_param_name      => 'Receipt Method (RECEIPT_METHOD_ID)');
        END IF;

        IF (gb_debug)
        THEN
            put_log_line(   '  payment_type = '
                         || l_payment_type);
        END IF;

-- ==========================================================================
-- use SAS original payment date to generate the receipt, GL, and apply dates
--   defect #3197
-- ==========================================================================
        IF (p_sas_sale_date IS NOT NULL)
        THEN
            IF (gb_debug)
            THEN
                put_log_line();
                put_log_line('SAS Sale date will be used to calculate the receipt and apply dates.');
                put_log_line(   ' SAS Sale Date = '
                             || p_sas_sale_date);
            END IF;

            ld_new_receipt_date := TRUNC(p_sas_sale_date);
-- ==========================================================================
-- use SAS sale date to get the receipt dates
-- ==========================================================================
            ld_receipt_date := ld_new_receipt_date;
            ld_apply_date := ld_new_receipt_date;
        ELSE
            ld_receipt_date := TRUNC(NVL(p_receipt_date,
                                         SYSDATE));
            ld_apply_date := TRUNC(p_apply_date);
        END IF;

        ld_gl_date := TRUNC(p_gl_date);
        ld_apply_gl_date := TRUNC(p_apply_gl_date);

        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line('Receipt Dates: ');
            put_log_line(   ' Receipt Date = '
                         || ld_receipt_date);
            put_log_line(   ' GL Date = '
                         || ld_gl_date);
            put_log_line(   ' Apply Date = '
                         || ld_apply_date);
            put_log_line(   ' Apply GL Date = '
                         || ld_apply_gl_date);
        END IF;

-- ==========================================================================
-- Validate that this will not create a duplicate receipt (causes error)
--   Unique: receipt number, date, amount, customer
--   If this occurs, use automatic document numbering and update receipt
--   number afterwards.  This is how the AR Receipts form behaves.
--   This has similar logic to AR_RECEIPT_VAL_PVT.val_duplicate_receipt
--     Must use receipt date from logic above - defect #4283
-- ==========================================================================
        OPEN lcu_duplicate_receipt(cp_receipt_number      => x_receipt_number,
                                   cp_receipt_date        => ld_receipt_date,
                                   cp_receipt_amount      => p_amount,
                                   cp_customer_id         => p_customer_id);

        FETCH lcu_duplicate_receipt
        INTO  ln_receipt_count;

        CLOSE lcu_duplicate_receipt;

        IF (ln_receipt_count > 0)
        THEN
            fnd_message.set_name('AR',
                                 'AR_RW_CASH_DUPLICATE_RECEIPT');
            put_log_line(fnd_message.get());
            put_log_line(   ' ...Using automatic document numbering and I1025 will correctly update the '
                         || '    receipt number after creation.  This is how the AR Receipts form behaves. ');
            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20109_DUPL_RECEIPT');
            fnd_message.set_token('RECEIPT_NUMBER',
                                  x_receipt_number);
            fnd_message.set_token('RECEIPT_DATE',
                                  ld_receipt_date);
            fnd_message.set_token('RECEIPT_AMOUNT',
                                  p_amount);
            fnd_message.set_token('CUSTOMER_ID',
                                  p_customer_id);
            add_prepay_message(p_orig_sys_document_ref      => p_attribute_rec.attribute7,
                               p_payment_number             => NVL(p_payment_number,
                                                                   0),
                               p_message_code               => 'DUPLICATE_RECEIPT',
                               p_message_text               => fnd_message.get(),
                               p_error_location             => lc_sub_name,
                               p_message_type               => gc_i1025_msg_type_info);
            lc_receipt_number := NULL;
        ELSE
            lc_receipt_number := x_receipt_number;
        END IF;

        IF (gb_debug)
        THEN
            put_log_line('Create Pre-Payment (AR Receipt with Prepayment Application)');
            put_log_line();
        END IF;

-- ==========================================================================
-- create pre-payment which creates an AR receipt with a prepay application
-- ==========================================================================
        ar_prepayments_pub.create_prepayment(p_api_version                       => 1.0,
                                             p_init_msg_list                     => fnd_api.g_true,
                                             p_commit                            => fnd_api.g_false,
                                             p_validation_level                  => fnd_api.g_valid_level_full,
                                             x_return_status                     => x_return_status,
                                             x_msg_count                         => x_msg_count,
                                             x_msg_data                          => x_msg_data,
                                             p_receipt_method_id                 => p_receipt_method_id,
                                             p_currency_code                     => p_currency_code,
                                             p_amount                            => p_amount,
                                             p_receipt_date                      => ld_receipt_date,
                                             p_gl_date                           => ld_gl_date,
                                             p_customer_id                       => p_customer_id,
                                             p_customer_site_use_id              => p_customer_site_use_id,
                                             p_customer_bank_account_id          => NULL,
                                             p_remittance_bank_account_id        => p_remittance_bank_account_id,
                                             p_applied_payment_schedule_id       => -7,
                                             --ar_payment_schedules pre-payment id
                                             p_called_from                       => 'PREPAYMENT',
                                             -- p_called_from,  -- defect 7462
                                             p_receipt_comments                  => p_receipt_comments,
                                             p_customer_receipt_reference        => p_customer_receipt_reference,
                                             p_amount_applied                    => p_amount_applied,
                                             p_application_ref_type              => x_application_ref_type,
                                             p_application_ref_id                => x_application_ref_id,
                                             p_application_ref_num               => x_application_ref_num,
                                             p_secondary_application_ref_id      => x_secondary_application_ref_id,
                                             p_apply_date                        => ld_apply_date,
                                             p_apply_gl_date                     => ld_apply_gl_date,
                                             p_payment_server_order_num          => x_payment_server_order_num,
                                             p_approval_code                     => x_credit_card_approval_code,
                                             p_payment_response_error_code       => x_payment_response_error_code,
                                             p_receivable_application_id         => x_receivable_application_id,
                                             p_payment_set_id                    => x_payment_set_id,
                                             p_cr_id                             => x_cash_receipt_id,
                                             p_receipt_number                    => lc_receipt_number,
                                             p_attribute_rec                     => l_attributes_rec,
                                             app_attribute_rec                   => l_app_attributes_rec,
                                             app_comments                        => p_app_comments,
                                             p_call_payment_processor            => fnd_api.g_false,
                                             p_org_id                            => mo_global.get_current_org_id);
        gn_prepay_time :=   gn_prepay_time
                          + (  get_timestamp()
                             - ln_start_api_time);

        IF (gb_debug)
        THEN
            put_log_line(   '- Return Status: '
                         || x_return_status
                         || ', Msg Cnt: '
                         || x_msg_count);
        END IF;

        IF (x_return_status = 'S')
        THEN
            IF (gb_debug)
            THEN
                put_log_line('Successfully created the receipt with prepayment.');
                put_log_line(   '  x_cash_receipt_id = '
                             || x_cash_receipt_id);
                put_log_line(   '  x_payment_set_id  = '
                            || x_payment_set_id);
            END IF;
        ELSE
            raise_api_errors(p_sub_name       => lc_sub_name,
                             p_msg_count      => x_msg_count,
                             p_api_name       => 'AR_PREPAYMENTS_PUB.create_prepayment');
        END IF;

-- ==========================================================================
-- fetch the AR receipt just created
-- ==========================================================================
        x_cash_receipt_rec.cash_receipt_id := x_cash_receipt_id;
        arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec      => x_cash_receipt_rec);

        IF (gb_debug)
        THEN
            put_log_line('- Fetched Receipt: ');
            put_log_line(   '  cash receipt id = '
                         || x_cash_receipt_rec.cash_receipt_id);
            put_log_line(   '  receipt number  = '
                         || x_cash_receipt_rec.receipt_number);
        END IF;

-- ==========================================================================
-- set the receipt number if this was a duplicate receipt caught above
-- ==========================================================================
        IF (ln_receipt_count > 0)
        THEN
            x_cash_receipt_rec.receipt_number := x_receipt_number;
-- ==========================================================================
-- update the AR receipts with new manual receipt number
-- ==========================================================================
            arp_cash_receipts_pkg.update_p(p_cr_rec      => x_cash_receipt_rec);

            IF (gb_debug)
            THEN
                put_log_line('- Updated Receipt afterwards with manual Receipt Number. ');
                put_log_line(   '  Receipt Number = '
                             || x_cash_receipt_rec.receipt_number);
            END IF;
        END IF;

        l_receipt_ext_attributes.cash_receipt_id := x_cash_receipt_rec.cash_receipt_id;
        l_receipt_ext_attributes.payment_number := p_payment_number;

        -- Starting Defect 11482
        IF (l_attributes_rec.attribute4 IS NOT NULL)
        THEN
            IF (lc_card_name = gc_disc_card_type)
            THEN
                l_receipt_ext_attributes.disc_net_info := SUBSTR(l_attributes_rec.attribute4,
                                                                 8,
                                                                 15);
            END IF;
        END IF;

-- Ending Defect 11482

        -- ==========================================================================
-- insert extra receipt info into custom XX_AR_CASH_RECEIPTS_EXT table
-- ==========================================================================
        insert_receipt_ext_info(p_receipt_ext_attributes      => l_receipt_ext_attributes);
-- ==========================================================================
-- set output variables (based on fetched cash receipt)
-- ==========================================================================
        x_cash_receipt_id := x_cash_receipt_rec.cash_receipt_id;
        x_receipt_number := x_cash_receipt_rec.receipt_number;
        x_payment_server_order_num := x_cash_receipt_rec.payment_server_order_num;

-- ==========================================================================
-- Standard check of p_commit
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_commit)
        THEN
            COMMIT;
        END IF;

-- ==========================================================================
-- Return message data to output parameters
-- ==========================================================================
        fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                  p_count        => x_msg_count,
                                  p_data         => x_msg_data);
        gn_total_time :=   gn_total_time
                         + (  get_timestamp()
                            - ln_start_time);

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_current_datetime();
            put_log_line();
        END IF;

-- ==========================================================================
-- force to print out the timings for Create Prepayment
-- ==========================================================================
        lb_debug_back := gb_debug;
        gb_debug := TRUE;
        put_log_line(   'PREPAYMENT timings: '
                     || ' Total='
                     || gn_total_time
                     || ', CC Bank='
                     || gn_cc_bank_time
                     || ', Prepayment='
                     || gn_prepay_time
                     || ', iPayment='
                     || gn_ipayment_time);
        gb_debug := lb_debug_back;
    EXCEPTION
        WHEN OTHERS
        THEN
            add_prepay_message(p_orig_sys_document_ref      => p_attribute_rec.attribute7,
                               p_payment_number             => NVL(p_payment_number,
                                                                   0),
                               p_message_code               => 'PREPAYMENT_ERRORS',
                               p_message_text               => SQLERRM,
                               p_error_location             => lc_sub_name,
                               p_message_type               => gc_i1025_msg_type_error);

            IF (SQLCODE BETWEEN -20000 AND -20999)
            THEN
                ROLLBACK TO SAVEPOINT before_create_xx_prepayment;
                x_return_status := fnd_api.g_ret_sts_error;
                fnd_message.set_name('AR',
                                     'GENERIC_MESSAGE');
                fnd_message.set_token('GENERIC_TEXT',
                                         lc_sub_name
                                      || ' : '
                                      || SQLERRM);
                fnd_msg_pub.ADD;
                fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                          p_count        => x_msg_count,
                                          p_data         => x_msg_data);
            ELSE
                ROLLBACK TO SAVEPOINT before_create_xx_prepayment;
                x_return_status := fnd_api.g_ret_sts_unexp_error;
                fnd_message.set_name('AR',
                                     'GENERIC_MESSAGE');
                fnd_message.set_token('GENERIC_TEXT',
                                         lc_sub_name
                                      || ' : '
                                      || SQLERRM);
                fnd_msg_pub.ADD;
                fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                          p_count        => x_msg_count,
                                          p_data         => x_msg_data);
            END IF;

            gn_total_time :=   gn_total_time
                             + (  get_timestamp()
                                - ln_start_time);
-- ==========================================================================
-- force to print out the timings for Create Prepayment
-- ==========================================================================
            lb_debug_back := gb_debug;
            gb_debug := TRUE;
            put_log_line(   'PREPAYMENT timings: '
                         || ' Total='
                         || gn_total_time
                         || ', CC Bank='
                         || gn_cc_bank_time
                         || ', Prepayment='
                         || gn_prepay_time
                         || ', iPayment='
                         || gn_ipayment_time);
            gb_debug := lb_debug_back;
    END;

-- ==========================================================================
-- procedure to unapply the prepayment of an AOPS order, and instead apply
--   it to the actual OM Order (interfaced once the deposit order is closed)
-- ==========================================================================
    PROCEDURE reapply_deposit_prepayment(
        p_init_msg_list     IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_commit            IN             VARCHAR2 DEFAULT fnd_api.g_false,
        p_validation_level  IN             NUMBER DEFAULT fnd_api.g_valid_level_full,
        x_return_status     OUT NOCOPY     VARCHAR2,
        x_msg_count         OUT NOCOPY     NUMBER,
        x_msg_data          OUT NOCOPY     VARCHAR2,
        p_cash_receipt_id   IN             NUMBER,
        p_header_id         IN             NUMBER,
        p_order_number      IN             VARCHAR2,
        p_apply_amount      IN             NUMBER,
        x_payment_set_id    IN OUT NOCOPY  NUMBER)
    IS
        lc_sub_name  CONSTANT VARCHAR2(50)               := 'REAPPLY_DEPOSIT_PREPAYMENT';
        lb_deposit_found      BOOLEAN                    DEFAULT NULL;
        l_cash_receipt_rec    ar_cash_receipts%ROWTYPE;
        l_prepay_appl_rec     gcu_prepay_appl%ROWTYPE;
        l_prepay_new_rec      gcu_prepay_appl%ROWTYPE;
        l_prepay_remain_rec   gcu_prepay_appl%ROWTYPE;

        CURSOR c_deposit_rcpt
        IS
            SELECT acr.cash_receipt_id,
                   acr.receipt_number,
                   ddt.orig_sys_document_ref,
                   xold.transaction_number,
                   xold.payment_number
            FROM   ar_cash_receipts_all acr,
                   xx_om_legacy_deposits xold,
                   xx_om_legacy_dep_dtls ddt
            WHERE  acr.cash_receipt_id = xold.cash_receipt_id
            AND    xold.transaction_number = ddt.transaction_number(+)
--            AND NVL (xold.orig_sys_document_ref, ddt.orig_sys_document_ref) = p_order_number Commented by Gaurav for V1.5
-- Follwoing Line added by Gaurav for v 1.5
            AND    SUBSTR(ddt.orig_sys_document_ref,
                          1,
                          9) = SUBSTR(p_order_number,
                                      1,
                                      9)
            AND    acr.cash_receipt_id = p_cash_receipt_id;

        l_deposit_rcpt        c_deposit_rcpt%ROWTYPE;

        CURSOR c_payment_set_id
        IS
            SELECT ar_receivable_applications_s1.NEXTVAL
            FROM   DUAL;
-- ==========================================================================
-- using autonomous transaction to prevent bank acct record locking in HVOP
--   defect 10692
-- ** revert changes back since Oracle Patch fixes this - defect 7462
-- ==========================================================================
--PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF (gb_debug)
        THEN
            put_log_line();
            put_log_line(   'BEGIN '
                         || lc_sub_name);
            put_current_datetime();
        END IF;

-- ==========================================================================
-- Print parameters as defined
-- ==========================================================================
        IF (gb_debug)
        THEN
            put_log_line('Prepayment new references:');
            put_log_line(   '  p_cash_receipt_id: '
                         || p_cash_receipt_id);
            put_log_line(   '  p_header_id:       '
                         || p_header_id);
            put_log_line(   '  p_order_number:    '
                         || p_order_number);
            put_log_line(   '  p_apply_amount:    '
                         || p_apply_amount);
            put_log_line(   '  x_payment_set_id:  '
                         || x_payment_set_id);
        END IF;

-- ==========================================================================
-- Clear existing I1025 messages
-- ==========================================================================
        clear_i1025_messages(p_i1025_record_type          => gc_i1025_record_type_order,
                             p_orig_sys_document_ref      => l_deposit_rcpt.orig_sys_document_ref,
                             p_payment_number             => l_deposit_rcpt.payment_number,
                             p_request_id                 => NVL(fnd_global.conc_request_id,
                                                                 -1));
-- ==========================================================================
-- Set savepoint for reapplying the deposit prepayment
-- ==========================================================================
        SAVEPOINT reapply_deposit_prepayment;

-- ==========================================================================
-- Initialize message list if p_init_msg_list is set to TRUE
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_init_msg_list)
        THEN
            fnd_msg_pub.initialize;
        END IF;

-- ==========================================================================
-- Initialize the return status to success
-- ==========================================================================
        x_return_status := fnd_api.g_ret_sts_success;

-- ==========================================================================
-- get the deposit receipt
-- ==========================================================================
        OPEN c_deposit_rcpt;

        FETCH c_deposit_rcpt
        INTO  l_deposit_rcpt;

        lb_deposit_found := c_deposit_rcpt%FOUND;

        CLOSE c_deposit_rcpt;

        DBMS_OUTPUT.put_line(   'l_cash_receipt_rec.cash_receipt_id :'
                             || l_cash_receipt_rec.cash_receipt_id);

-- ==========================================================================
-- reset master program return code status (just in case)
-- ==========================================================================
        IF (lb_deposit_found)
        THEN
            l_cash_receipt_rec.cash_receipt_id := p_cash_receipt_id;
-- ==========================================================================
-- fetch and lock (with nowait) the AR receipt
-- ==========================================================================
            arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec      => l_cash_receipt_rec);

            IF (gb_debug)
            THEN
                put_log_line('- Fetched and Locked Receipt: ');
                put_log_line(   '  cash receipt id = '
                             || l_cash_receipt_rec.cash_receipt_id);
                put_log_line(   '  receipt number  = '
                             || l_cash_receipt_rec.receipt_number);
                put_log_line('Fetching Prepayment: ');
            END IF;

-- ==========================================================================
-- fetch the recv application for the prepayment
-- ==========================================================================
            l_prepay_appl_rec :=
                get_prepay_application_record(p_cash_receipt_id       => p_cash_receipt_id,
                                              p_reference_type        => 'SA',
                                              p_reference_number      => l_deposit_rcpt.transaction_number
                                                                                                          -- V1.3 changes made for SDR project
                                             );

-- ==========================================================================
-- if found, print prepayment application info
-- ==========================================================================
            IF (l_prepay_appl_rec.receivable_application_id IS NOT NULL)
            THEN
                IF (gb_debug)
                THEN
                    put_log_line(   '  recv appl id  = '
                                 || l_prepay_appl_rec.receivable_application_id);
                    put_log_line(   '  appl ref type = '
                                 || l_prepay_appl_rec.application_ref_type);
                    put_log_line(   '  appl ref num  = '
                                 || l_prepay_appl_rec.application_ref_num);
                    put_log_line(   '  prepay amount = '
                                 || l_prepay_appl_rec.amount_applied);
                END IF;

-- ==========================================================================
-- unapply the existing prepayment
-- ==========================================================================
                unapply_prepayment_application(p_prepay_appl_row      => l_prepay_appl_rec);

-- ==========================================================================
-- generate and fetch the payment_set_id if not defined
-- ==========================================================================
                IF (x_payment_set_id IS NOT NULL)
                THEN
                    IF (gb_debug)
                    THEN
                        put_log_line(' Parameter x_payment_set_id is defined. ');
                    END IF;
                ELSE
                    IF (gb_debug)
                    THEN
                        put_log_line(' Parameter x_payment_set_id is not defined. ');
                        put_log_line(' Retrieving the next payment_set_id... ');
                    END IF;

                    OPEN c_payment_set_id;

                    FETCH c_payment_set_id
                    INTO  x_payment_set_id;

                    CLOSE c_payment_set_id;

                    IF (gb_debug)
                    THEN
                        put_log_line(   ' x_payment_set_id = '
                                     || x_payment_set_id);
                    END IF;
                END IF;

-- ==========================================================================
-- apply the new OM prepayment order reference
-- ==========================================================================
--l_prepay_new_rec := l_prepay_appl_rec;
                l_prepay_new_rec.org_id := l_prepay_appl_rec.org_id;
                l_prepay_new_rec.cash_receipt_id := p_cash_receipt_id;
                l_prepay_new_rec.payment_set_id := x_payment_set_id;
                l_prepay_new_rec.application_ref_type := 'OM';
                l_prepay_new_rec.application_ref_id := p_header_id;
                l_prepay_new_rec.application_ref_num := p_order_number;
                l_prepay_new_rec.amount_applied := p_apply_amount;
                apply_prepayment_application(p_prepay_appl_row      => l_prepay_new_rec);
-- ==========================================================================
-- reapply the difference back to the old SA reference
-- ==========================================================================
                l_prepay_remain_rec := l_prepay_appl_rec;
                l_prepay_remain_rec.amount_applied :=   l_prepay_appl_rec.amount_applied
                                                      - p_apply_amount;

                IF (l_prepay_remain_rec.amount_applied > 0)
                THEN
                    apply_prepayment_application(p_prepay_appl_row      => l_prepay_remain_rec);
                END IF;

-- ==========================================================================
-- re-fetch the latest AR receipt
-- ==========================================================================
                arp_cash_receipts_pkg.nowaitlock_fetch_p(p_cr_rec      => l_cash_receipt_rec);

                IF (gb_debug)
                THEN
                    put_log_line('- Fetched and Locked Receipt: ');
                    put_log_line(   '  cash receipt id = '
                                 || l_cash_receipt_rec.cash_receipt_id);
                    put_log_line(   '  receipt number  = '
                                 || l_cash_receipt_rec.receipt_number);
                END IF;

-- ==========================================================================
-- set the I1025 process code to "Standard Matching"
-- ==========================================================================
                l_cash_receipt_rec.attribute13 :=    'STD_MATCHING|'
                                                  || TO_CHAR(SYSDATE,
                                                             'YYYY/MM/DD HH24:MI:SS');
-- ==========================================================================
-- update the AR receipts with new process status
-- ==========================================================================
                arp_cash_receipts_pkg.update_p(p_cr_rec      => l_cash_receipt_rec);

                IF (gb_debug)
                THEN
                    put_log_line(   '- Updated Receipt: '
                                 || l_cash_receipt_rec.receipt_number
                                 || ' as "Standard Matching".');
                END IF;

-- ==========================================================================
-- update the Deposit record with the new status
-- ==========================================================================
                UPDATE xx_om_legacy_deposits
                SET i1025_status = 'STD_PREPAY_MATCH',
                    i1025_update_date = SYSDATE
                WHERE  cash_receipt_id = l_cash_receipt_rec.cash_receipt_id
				  AND prepaid_amount > 0 -- Added for defect#34528
				  AND I1025_STATUS <> 'MAILCHECK_HOLD'; -- Added for defect#34528

                IF (gb_debug)
                THEN
                    put_log_line(   '- Updated '
                                 || SQL%ROWCOUNT
                                 || ' Deposit record[s]. ');
                    put_log_line('  I1025 Status = STD_PREPAY_MATCH.');
                END IF;
            ELSE
                IF (gb_debug)
                THEN
                    put_log_line('* ERROR - No Prepayment Application could be found.');
                END IF;

                fnd_message.set_name('XXFIN',
                                     'XX_AR_I1025_20016_NO_PREPAY_AP');
                fnd_message.set_token('SUB_NAME',
                                      lc_sub_name);
                raise_application_error(-20016,
                                        fnd_message.get());
            END IF;
        ELSE
            IF (gb_debug)
            THEN
                put_log_line('* ERROR - Deposit receipt could not be found.');
            END IF;

            fnd_message.set_name('XXFIN',
                                 'XX_AR_I1025_20017_NO_DEPOSIT');
            fnd_message.set_token('SUB_NAME',
                                  lc_sub_name);
            raise_application_error(-20017,
                                    fnd_message.get());
        END IF;

-- ==========================================================================
-- Standard check of p_commit
-- ==========================================================================
        IF fnd_api.to_boolean(p_char      => p_commit)
        THEN
            COMMIT;
        END IF;

-- ==========================================================================
-- Return message data to output parameters
-- ==========================================================================
        fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                  p_count        => x_msg_count,
                                  p_data         => x_msg_data);

        IF (gb_debug)
        THEN
            put_log_line(   'END '
                         || lc_sub_name);
            put_current_datetime();
            put_log_line();
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            add_prepay_message(p_orig_sys_document_ref      => l_deposit_rcpt.orig_sys_document_ref,
                               p_payment_number             => l_deposit_rcpt.payment_number,
                               p_message_code               => 'REAPPLY_DEPOSIT_ERRORS',
                               p_message_text               => SQLERRM,
                               p_error_location             => lc_sub_name,
                               p_message_type               => gc_i1025_msg_type_error);

            IF (SQLCODE BETWEEN -20000 AND -20999)
            THEN
                ROLLBACK TO SAVEPOINT reapply_deposit_prepayment;
                x_return_status := fnd_api.g_ret_sts_error;
                fnd_message.set_name('AR',
                                     'GENERIC_MESSAGE');
                fnd_message.set_token('GENERIC_TEXT',
                                         lc_sub_name
                                      || ' : '
                                      || SQLERRM);
                fnd_msg_pub.ADD;
                fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                          p_count        => x_msg_count,
                                          p_data         => x_msg_data);
            ELSE
                ROLLBACK TO SAVEPOINT reapply_deposit_prepayment;
                x_return_status := fnd_api.g_ret_sts_unexp_error;
                fnd_message.set_name('AR',
                                     'GENERIC_MESSAGE');
                fnd_message.set_token('GENERIC_TEXT',
                                         lc_sub_name
                                      || ' : '
                                      || SQLERRM);
                fnd_msg_pub.ADD;
                fnd_msg_pub.count_and_get(p_encoded      => fnd_api.g_false,
                                          p_count        => x_msg_count,
                                          p_data         => x_msg_data);
            END IF;
    END;
BEGIN
-- ==========================================================================
-- Set global variables that are derived from Profile Option values
-- ==========================================================================
    gn_i1025_message_level := NVL(fnd_profile.VALUE('XX_AR_I1025_MESSAGE_LOGGING_LEVEL'),
                                  3);
--GN_REFUND_TOLERANCE := NVL(FND_PROFILE.value('XX_AR_I1025_REFUND_AMT_TOLERANCE'),0);
--GN_COMMIT_INTERVAL := NVL(FND_PROFILE.value('XX_AR_I1025_COMMIT_INTERVAL'),100);
END;
/