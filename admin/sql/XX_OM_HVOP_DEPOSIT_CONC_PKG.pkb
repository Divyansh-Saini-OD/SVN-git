Create Or Replace  PACKAGE BODY      xx_om_hvop_deposit_conc_pkg
AS
    PROCEDURE into_recpt_tbl_for_postpay(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE check_postpayment(
        p_hdr_idx    IN  NUMBER,
        p_start_idx  IN  NUMBER);

-- +=========================================================================================+
-- |    Office Depot - Project Simplify                                                      |
-- |     Office Depot                                                                        |
-- |                                                                                         |
-- +=========================================================================================+
-- | Name  : XX_OM_HVOP_DEPOSIT_CONC_PKG                                                     |
-- | Rice ID : I1272                                                                         |
-- | Description      : Package Body                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |                                                                                         |
-- |===============                                                                          |
-- |                                                                                         |
-- |Version    Date          Author           Remarks                                        |
-- |=======    ==========    =============    ===============================================+
-- |DRAFT 1A   06-MAY-2007   Visalakshi       Initial draft version                          |
-- |1          06-OCT-2007   Manish Chavan    Changes related to Post Payments               |
-- |1.1        12-OCT-2009   Bapuji N         added single quote for Debit Card              |
-- |                                          validation                                     |
-- |1.2        27-JUN-2013   Bapuji N         Retro Fit for 12i                              |
-- |1.3        06-SEPT-2013  Edson Morales    Modified for R12 encryption                    |
-- |1.4        17-SEPT-2013  Edson Morales    Modified encryption call                       |
-- |1.5        21-SEPT-2013  Edson Morales    Fix for Defect 25560                           |
-- |2.0        04-Feb-2013   Edson Morales    Changes for Defect 27883                       |
-- |2.1        14-Jul-2014   Suresh Ponnambalam OMX Gift Card Consolidation                  |
-- |2.2        15-Apr-2015   Arun Gannarapu   Tokenization/EMV changes                       |
-- |2.3        20-Jul-2015   Arun Gannarapu   Made changes to fix defect 35134               |
-- |2.4        22-Jul-2015   Arun G           Made changes to fix the defect #35134          |
-- |                                          removed the TRIM                               |
-- |2.5        27-Jul-2015   Arun G           Made changes to populate default               |
-- |                                          values for EMV                                 |
-- |2.6        08-Aug-2015   Arun G           Made changes to fix the defect 35383           |
-- |2.7        27-Oct-2016   Rajeshkumar      Performance issue 39886                        |
-- |2.8        25-Aug-2017   Venkata Battu    Made changes to order_source function for biz box| 
-- |2.9        15-Sep-2020   Ray Strauss      Changed code to handle empty files             | 
-- +=========================================================================================+
    PROCEDURE process_deposit(
        x_retcode      OUT NOCOPY     NUMBER,
        x_errbuf       OUT NOCOPY     VARCHAR2,
        p_debug_level  IN             NUMBER,
        p_filename     IN             VARCHAR2)
    IS
        lc_input_file_handle    UTL_FILE.file_type;
        lc_curr_line            VARCHAR2(1000);
        lc_o_unit               VARCHAR2(50);
        lc_return_status        VARCHAR2(100);
        ln_debug_level          NUMBER                                            := oe_debug_pub.g_debug_level;
        lc_errbuf               VARCHAR2(2000);
        ln_retcode              NUMBER;
        ln_request_id           NUMBER;
        lc_file_path            VARCHAR2(100)                                := fnd_profile.VALUE('XX_OM_SAS_FILE_DIR');
        lb_has_records          BOOLEAN;
        i                       BINARY_INTEGER;
        lc_pos_txn_number       oe_headers_iface_all.orig_sys_document_ref%TYPE;
        lc_curr_pos_txn_number  oe_headers_iface_all.orig_sys_document_ref%TYPE;
        lc_record_type          VARCHAR2(10);
        l_order_tbl             order_tbl_type;
        lc_error_flag           VARCHAR2(1)                                       := 'N';
        lc_filename             VARCHAR2(100);
        lc_filedate             VARCHAR2(30);
        lb_at_trailer           BOOLEAN                                           := FALSE;
        lc_arch_path            VARCHAR2(100);
        ln_master_request_id    NUMBER;
        ln_file_run_count       BINARY_INTEGER;
        lc_invoicing_on         VARCHAR2(1)                            := oe_sys_parameters.VALUE('XX_OM_INVOICING_ON');
    BEGIN
        --Initialize the error count
        g_error_count := 0;
        -- Initialize the fnd_message stack
        fnd_msg_pub.initialize;
        oe_bulk_msg_pub.initialize;
        fnd_file.put_line(fnd_file.output,
                             'Debug Level: '
                          || NVL(p_debug_level,
                                 0));

        IF NVL(p_debug_level,
               -1) >= 0
        THEN
            fnd_profile.put('ONT_DEBUG_LEVEL',
                            p_debug_level);
            oe_debug_pub.g_debug_level := p_debug_level;
            lc_filename := oe_debug_pub.set_debug_mode('CONC');
        END IF;

        fnd_file.put_line(fnd_file.output,
                             'Processing The file : '
                          || p_filename);
        ln_debug_level := oe_debug_pub.g_debug_level;
        -- Set the Global
        xx_om_hvop_util_pkg.g_use_test_cc := NVL(fnd_profile.VALUE('XX_OM_USE_TEST_CC'),
                                                 'N');

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Process_Deposit');
        END IF;

        BEGIN
            -- File name will be sent in as IN parameter so no need to generate file name.
            lc_return_status := 'S';
            fnd_profile.get('CONC_REQUEST_ID',
                            g_request_id);
            fnd_file.put_line(fnd_file.LOG,
                              'Start Procedure ');
            fnd_file.put_line(fnd_file.LOG,
                                 'File Path : '
                              || lc_file_path);
            fnd_file.put_line(fnd_file.LOG,
                                 'File Name : '
                              || p_filename);
            fnd_file.put_line(fnd_file.LOG,
                                 'File Name length : '
                              || LENGTH(p_filename));
            lc_input_file_handle := UTL_FILE.fopen(lc_file_path,
                                                   p_filename,
                                                   'R');
            oe_debug_pub.ADD('After the file open');
        EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
                oe_debug_pub.ADD(   'Invalid Path: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid Path: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_mode
            THEN
                oe_debug_pub.ADD(   'Invalid Mode: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid Mode: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_filehandle
            THEN
                oe_debug_pub.ADD(   'Invalid file handle: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid file handle: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_operation
            THEN
                oe_debug_pub.ADD(   'Invalid operation: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid operation222: '
                                  || SQLERRM
                                  || '::::'
                                  || p_filename);
                lc_errbuf :=    'Can not find the DEPOSIT file :'
                             || p_filename
                             || ' in '
                             || lc_file_path;
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.read_error
            THEN
                oe_debug_pub.ADD(   'Read Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Read Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.write_error
            THEN
                oe_debug_pub.ADD(   'Write Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Write Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.internal_error
            THEN
                oe_debug_pub.ADD(   'Internal Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Internal Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN NO_DATA_FOUND
            THEN
                oe_debug_pub.ADD(   'No data found: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'No data found: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN VALUE_ERROR
            THEN
                oe_debug_pub.ADD(   'Value Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Value Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  SQLERRM);
                UTL_FILE.fclose(lc_input_file_handle);
                RAISE fnd_api.g_exc_error;
        END;

        lb_has_records := TRUE;
        g_file_name := p_filename;
        i := 0;

        -- Check if the file has been run before
        SELECT COUNT(file_name)
        INTO   ln_file_run_count
        FROM   xx_om_sacct_file_history
        WHERE  file_name = p_filename;

        BEGIN
            LOOP
                BEGIN
                    lc_curr_line := NULL;
                    /* UTL FILE READ START */
                    UTL_FILE.get_line(lc_input_file_handle,
                                      lc_curr_line);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                          'NO MORE RECORD TO READ');
                        oe_debug_pub.ADD(   'Failure in Get Line :'
                                         || i);
                        lb_has_records := FALSE;

                        IF l_order_tbl.COUNT = 0
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                              'THE FILE IS EMPTY NO RECORDS');
                            lb_at_trailer := TRUE;
                            EXIT;
--                            RAISE fnd_api.g_exc_error;
                        END IF;
                    WHEN OTHERS
                    THEN
                        x_retcode := 2;
                        fnd_file.put_line(fnd_file.output,
                                             'Unexpected error '
                                          || SUBSTR(SQLERRM,
                                                    1,
                                                    200));
                        fnd_file.put_line(fnd_file.output,
                                          '');
                        x_errbuf := 'Please check the log file for error messages';
                        lb_has_records := FALSE;
                        RAISE fnd_api.g_exc_error;
                END;

                -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
                lc_curr_line := SUBSTR(lc_curr_line,
                                       1,
                                       330);
                oe_debug_pub.ADD(   'My Line Is :'
                                 || lc_curr_line);
                lc_pos_txn_number := SUBSTR(lc_curr_line,
                                            1,
                                            20);

                IF lc_curr_pos_txn_number IS NULL
                THEN
                    lc_curr_pos_txn_number := lc_pos_txn_number;
                END IF;

                -- IF Order has changed or we are at the last record of the file
                IF lc_curr_pos_txn_number <> lc_pos_txn_number OR NOT lb_has_records
                THEN
                    oe_debug_pub.ADD('Before Process Current Order :');
                    process_current_deposit(p_order_tbl       => l_order_tbl,
                                            p_at_trailer      => lb_at_trailer);
                    oe_debug_pub.ADD('After Process Current Order :');
                    l_order_tbl.DELETE;
                    i := 0;
                END IF;

                lc_curr_pos_txn_number := lc_pos_txn_number;

                IF NOT lb_has_records
                THEN
                    -- nothing to process
                    EXIT;
                END IF;

                lc_record_type := SUBSTR(lc_curr_line,
                                         21,
                                         2);

                IF lc_record_type = '10'
                THEN
                    i :=   i
                         + 1;
                    l_order_tbl(i).record_type := lc_record_type;
                    l_order_tbl(i).file_line := lc_curr_line;
                ELSIF lc_record_type = '11'
                THEN                                                                           -- Header comments record
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'The comments Rec is '
                                         || SUBSTR(lc_curr_line,
                                                   33,
                                                   298));
                    END IF;

                    l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                || SUBSTR(lc_curr_line,
                                                          33,
                                                          298);
                ELSIF lc_record_type = '12'
                THEN                                                                            -- Header Address record
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'The addr Rec is '
                                         || SUBSTR(lc_curr_line,
                                                   33,
                                                   298));
                    END IF;

                    l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                || SUBSTR(lc_curr_line,
                                                          33,
                                                          298);
                /* R11.2 Single Payment Changes --NB */
                ELSIF lc_record_type = '25'
                THEN
                    i :=   i
                         + 1;
                    l_order_tbl(i).record_type := lc_record_type;
                    l_order_tbl(i).file_line := lc_curr_line;
                    oe_debug_pub.ADD(   'The SP ord det Rec is '
                                     || SUBSTR(lc_curr_line,
                                               33,
                                               298));
                ELSIF lc_record_type = '40'
                THEN
                    i :=   i
                         + 1;
                    l_order_tbl(i).record_type := lc_record_type;
                    l_order_tbl(i).file_line := lc_curr_line;
                ELSIF lc_record_type = '99'
                THEN                                                                                   -- Trailer Record
                    i :=   i
                         + 1;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'The Trailer Rec is '
                                         || lc_curr_line);
                    END IF;

                    l_order_tbl(i).record_type := lc_record_type;
                    l_order_tbl(i).file_line := lc_curr_line;
                    lb_at_trailer := TRUE;
                END IF;
            END LOOP;

            -- After reading the whole file insert into the custom payments table
            IF g_payment_rec.orig_sys_document_ref.COUNT > 0
            THEN
                insert_data;
            END IF;

            -- If trailer record is missing then we need to raise hard error as it can happen as a result of file getting truncated
            -- during transmission
            IF NOT lb_at_trailer
            THEN
                -- Send email notification that trailer record is missing
                xx_om_hvop_util_pkg.send_notification('DEPOSIT Trailer record missing',
                                                         'Trailer record is missing on the file :'
                                                      || p_filename);
                fnd_file.put_line(fnd_file.LOG,
                                     'ERROR: Trailer record is missing on the file :'
                                  || p_filename);
                RAISE fnd_api.g_exc_error;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_flag := 'Y';
                ROLLBACK;
                fnd_file.put_line(fnd_file.LOG,
                                     'Unexpected error in Process Child :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                -- Send email notification
                xx_om_hvop_util_pkg.send_notification('DEPOSIT unexpected Error',
                                                         'Unexpected error while processing the file : '
                                                      || p_filename
                                                      || 'Check the request log for request_id :'
                                                      || g_request_id);
                RAISE fnd_api.g_exc_unexpected_error;
        END;

        -- Save the messages logged so far
        oe_bulk_msg_pub.save_messages(g_request_id);
        COMMIT;

        -- Running the file for first time
        IF ln_file_run_count = 0
        THEN
            -- Get the Master Request ID
            BEGIN
                SELECT parent_request_id
                INTO   ln_master_request_id
                FROM   fnd_run_requests
                WHERE  request_id = g_request_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ln_master_request_id := g_request_id;
            END;

            -- Create log into the File History Table
            INSERT INTO xx_om_sacct_file_history
                        (file_name,
                         file_type,
                         request_id,
                         master_request_id,
                         process_date,
                         error_flag,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         total_orders,
                         legacy_header_count,
                         legacy_header_amount,
                         legacy_payment_count,
                         legacy_payment_amount,
                         org_id,
                         acct_order_total)
                 VALUES (p_filename,
                         'DEPOSIT',
                         g_request_id,
                         ln_master_request_id,
                         g_process_date,
                         lc_error_flag,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         g_header_counter,
                         g_header_count,
                         g_header_tot_amount,
                         g_payment_count,
                         g_payment_tot_amt,
                         g_org_id,
                         g_header_tot_amount);
        ELSE
            -- We are in rerun mode and need to update the record in xx_om_sacct_file_history
            UPDATE xx_om_sacct_file_history
            SET total_orders =   total_orders
                               + g_header_counter
            WHERE  file_name = p_filename;
        END IF;

        COMMIT;

        -- Move the file to archive directory
        BEGIN
            lc_arch_path := fnd_profile.VALUE('XX_OM_SAS_ARCH_FILE_DIR');
            -- UTL_FILE.FRENAME(lc_file_path, p_filename, lc_arch_path, p_filename||'.done');
            UTL_FILE.fcopy(lc_file_path,
                           p_filename,
                           lc_arch_path,
                              p_filename
                           || '.done');
            UTL_FILE.fremove(lc_file_path,
                             p_filename);
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Failed to move file to archieval directory');
        END;

        -- Send email notification if there are deposit records marked for error
        IF g_error_count > 0
        THEN
            xx_om_hvop_util_pkg.send_notification('DEPOSIT Errors',
                                                     'There are '
                                                  || g_error_count
                                                  || ' order deposit records marked for error in file :'
                                                  || p_filename);
        END IF;

        fnd_file.put_line(fnd_file.output,
                             'No of deposit orders processed : '
                          || g_header_rec.orig_sys_document_ref.COUNT);
        fnd_file.put_line(fnd_file.output,
                             'No of deposit orders with errors : '
                          || g_error_count);
        fnd_file.put_line(fnd_file.output,
                             'No of deposit orders with success : '
                          || (  g_header_rec.orig_sys_document_ref.COUNT
                              - g_error_count));
        -- Time to submit the concurrent request to process the receipt for these deposit record
        fnd_file.put_line(fnd_file.output,
                          'Submitting the Receipt creation process');

        -- Check if AR is ON
        IF lc_invoicing_on = 'Y'
        THEN
            ln_request_id :=
                fnd_request.submit_request('XXFIN',
                                           'XX_AR_CREATE_APPLY_RECEIPTS',
                                           'Create Deposit Receipts ::',
                                           NULL,
                                           FALSE,
                                           g_org_id,
                                           TO_CHAR(TRUNC(SYSDATE),
                                                   'YYYY/MM/DD HH24:MI:SS'),
                                           TO_CHAR(TRUNC(SYSDATE),
                                                   'YYYY/MM/DD HH24:MI:SS'),
                                           'Create Deposit Receipts',
                                           g_request_id,
                                           NULL);

            IF ln_request_id = 0
            THEN
                fnd_file.put_line(fnd_file.output,
                                  'Error in submitting CREATE RECEIPT request');
                x_errbuf := fnd_message.get;
                x_retcode := 2;
                RETURN;
            END IF;

            fnd_file.put_line(fnd_file.output,
                              'Receipt Creation is successful');
        END IF;

        x_retcode := 0;
    EXCEPTION
        WHEN fnd_api.g_exc_error
        THEN
            ROLLBACK;
            x_retcode := 2;
            x_errbuf := SUBSTR(SQLERRM,
                               1,
                               80);
            fnd_file.put_line(fnd_file.LOG,
                                 'Error in reading the file :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            xx_om_hvop_util_pkg.send_notification('Deposit File Missing',
                                                  lc_errbuf);
            RAISE fnd_api.g_exc_error;
        WHEN OTHERS
        THEN
            ROLLBACK;
            x_retcode := 2;
            x_errbuf := SUBSTR(SQLERRM,
                               1,
                               80);
            fnd_file.put_line(fnd_file.LOG,
                                 'Unexpected error in Process Deposit :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            xx_om_hvop_util_pkg.send_notification('Error in Processing Deposits ',
                                                     'Unexpected error in Process Deposit :'
                                                  || SUBSTR(SQLERRM,
                                                            1,
                                                            80)
                                                  || ' in File '
                                                  || p_filename);
            RAISE fnd_api.g_exc_error;
    END process_deposit;

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
-- +=====================================================================+
-- | Name  : Process_Current_Deposit                                     |
-- | Description      : This Procedure will read line by line from flat  |
-- |                    file and process each deposit by order till end  |
-- |                    of file                                          |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE process_current_deposit(
        p_order_tbl   IN  order_tbl_type,
        p_at_trailer  IN  BOOLEAN)
    IS
        l_cnt          BINARY_INTEGER;
        i              BINARY_INTEGER;
        l_hdr_idx      BINARY_INTEGER := 0;
        l_start_idx    BINARY_INTEGER := 0;
        l_curr_idx     BINARY_INTEGER := 0;
        l_credit_flag  VARCHAR2(1)    := 'N';
    BEGIN
        oe_debug_pub.ADD('In Process Current Deposit :');
        l_cnt := 1;

        FOR k IN 1 .. p_order_tbl.COUNT
        LOOP
            IF p_order_tbl(k).record_type = '10'
            THEN
                oe_debug_pub.ADD('Calling  Process Header');
                process_header(p_order_tbl(k),
                               l_credit_flag);
            /* R11.2 Single Payment Changes */
            ELSIF p_order_tbl(k).record_type = '25'
            THEN
                oe_debug_pub.ADD('Calling  SP Order Details ');
                process_sp_order_details(p_order_tbl(k));
            ELSIF p_order_tbl(k).record_type = '40'
            THEN
                oe_debug_pub.ADD('Calling  Process Payment');
                process_payment(p_order_tbl(k));
                l_curr_idx := g_payment_rec.transaction_number.COUNT;
                oe_debug_pub.ADD(   'Current index is :'
                                 || l_curr_idx);

                IF l_cnt >= 2
                THEN
                    l_start_idx := l_curr_idx;
                    oe_debug_pub.ADD(   'start index is :'
                                     || l_curr_idx);
                END IF;

                IF l_curr_idx > l_start_idx AND g_payment_rec.error_flag(l_curr_idx) = 'Y'
                THEN
                    oe_debug_pub.ADD(   'Found error at index :'
                                     || l_curr_idx);
                    -- set the error flag on the prior payment records for the same order if any
                    i :=   l_curr_idx
                         - 1;
                    oe_debug_pub.ADD(   'Failing point NBAPUJI :'
                                     || i);

                    BEGIN
                        --WHILE G_Payment_Rec.orig_sys_document_ref(i) = G_Payment_Rec.orig_sys_document_ref(l_start_idx) LOOP
                        WHILE g_payment_rec.transaction_number(i) = g_payment_rec.transaction_number(l_start_idx)
                        LOOP
                            oe_debug_pub.ADD(   'Setting error flag for index :'
                                             || i);
                            g_payment_rec.error_flag(i) := 'Y';
                            i :=   i
                                 - 1;

                            IF i = 0
                            THEN
                                EXIT;
                            END IF;
                        END LOOP;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            EXIT;
                        WHEN OTHERS
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Failed in Process_Current_Deposit :'
                                              || SUBSTR(SQLERRM,
                                                        1,
                                                        80));
                            RAISE fnd_api.g_exc_unexpected_error;
                    END;
                END IF;
            ELSIF p_order_tbl(k).record_type = '99'
            THEN
                oe_debug_pub.ADD('Calling  Process Trailer');
                process_trailer(p_order_tbl(k));
            END IF;

            l_cnt :=   l_cnt
                     + 1;
        END LOOP;

        oe_debug_pub.ADD('At the end of curr order loop ');
        oe_debug_pub.ADD(   'l_start_idx:'
                         || l_start_idx);
        oe_debug_pub.ADD(   'Credit Flag:'
                         || l_credit_flag);

        IF NOT p_at_trailer
        THEN
            l_hdr_idx := g_header_rec.orig_sys_document_ref.COUNT;
            oe_debug_pub.ADD(   'Error Flag:'
                             || g_header_rec.error_flag(l_hdr_idx));

            IF NVL(g_header_rec.error_flag(l_hdr_idx),
                   'N') = 'Y'
            THEN
                g_error_count :=   g_error_count
                                 + 1;
            END IF;

            IF     l_hdr_idx > 0
               AND l_start_idx > 0
               AND l_credit_flag = 'N'
               AND NVL(g_header_rec.error_flag(l_hdr_idx),
                       'N') <> 'Y'
            THEN
                oe_debug_pub.ADD('Calling Check_PostPayment :');
                check_postpayment(p_hdr_idx        => l_hdr_idx,
                                  p_start_idx      => l_start_idx);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in Process_Current_Deposit :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            RAISE fnd_api.g_exc_unexpected_error;
    END process_current_deposit;

    PROCEDURE process_header(
        p_order_rec    IN      order_rec_type,
        p_credit_flag  OUT     VARCHAR2)
    IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Office Depot                               |
-- +===================================================================+
-- | Name  : process_header                                            |
-- | Description      : This Procedure will read the header line       |
-- |                    validate , derive and populate the global      |
-- |                    variables(record types)                        |
-- +===================================================================+
        i                         BINARY_INTEGER;
        lc_order_source           VARCHAR2(20);
        lc_orig_sys_customer_ref  VARCHAR2(50);
        lc_customer_ref           VARCHAR2(50);
        lc_order_category         VARCHAR2(2);
        lc_paid_at_store_id       VARCHAR2(20);
        lc_err_msg                VARCHAR2(240);
        lc_return_status          VARCHAR2(80);
        lb_store_customer         BOOLEAN;
        lc_orig_sys               VARCHAR2(10);
        lc_sas_sale_date          VARCHAR2(10);
        lc_ship_date              VARCHAR2(10);
        ln_debug_level   CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_aops_pos_flag          VARCHAR2(1);
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering  Process Header');
        END IF;

        i :=   g_header_rec.pos_txn_number.COUNT
             + 1;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'G_Header_Rec count is :'
                             || TO_CHAR(  i
                                        - 1));
        END IF;

        g_order_source := NULL;
        g_header_rec.error_flag(i) := 'N';
        lc_paid_at_store_id := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line,
                                                      135,
                                                      4)));
        lc_order_source := LTRIM(SUBSTR(p_order_rec.file_line,
                                        143,
                                        1));
        g_order_source := lc_order_source;
        lc_customer_ref := LTRIM(SUBSTR(p_order_rec.file_line,
                                        218,
                                        8));
        g_header_rec.spc_card_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              196,
                                                              20)));
        lc_order_category := SUBSTR(p_order_rec.file_line,
                                    217,
                                    1);
        g_header_rec.transactional_curr_code(i) := SUBSTR(p_order_rec.file_line,
                                                          43,
                                                          3);
        g_header_rec.inv_loc_no(i) := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line,
                                                             139,
                                                             4)));
        g_header_rec.sold_to_org(i) := NULL;
        g_header_rec.sold_to_org_id(i) := NULL;
        g_header_rec.is_reference_return(i) := NULL;
        lc_sas_sale_date := TRIM(SUBSTR(p_order_rec.file_line,
                                        821,
                                        10));
        lc_ship_date := TRIM(SUBSTR(p_order_rec.file_line,
                                    226,
                                    10));
        lc_aops_pos_flag := LTRIM(SUBSTR(p_order_rec.file_line,
                                         329,
                                         1));
        /* R11.2 SDR Changes Single Payment using exsiting variable for single_pay_ind */
        g_header_rec.is_reference_return(i) := SUBSTR(p_order_rec.file_line,
                                                      917,
                                                      1);
        oe_debug_pub.ADD(   'lc_sas_sale_date = '
                         || lc_sas_sale_date);

        IF lc_sas_sale_date IS NOT NULL
        THEN
            g_header_rec.sas_sale_date(i) := TO_DATE(lc_sas_sale_date,
                                                     'YYYY-MM-DD');
        ELSIF lc_ship_date IS NOT NULL
        THEN                                                              -- For POS the SAS date will come in ship_date
            g_header_rec.sas_sale_date(i) := TO_DATE(lc_ship_date,
                                                     'YYYY-MM-DD');
        ELSE
            g_header_rec.sas_sale_date(i) := SYSDATE;
        END IF;

        -- IF the deposit file is coming from POS
        IF lc_aops_pos_flag = 'P'
        THEN
            g_header_rec.pos_txn_number(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                           1,
                                                           20));
            g_header_rec.orig_sys_document_ref(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                                  308,
                                                                  12));
        ELSE
            g_header_rec.orig_sys_document_ref(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                                  1,
                                                                  12));
            g_header_rec.pos_txn_number(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                           308,
                                                           20));

            IF g_header_rec.pos_txn_number(i) IS NULL
            THEN
                g_header_rec.error_flag(i) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Missing Orig Sys Document Ref for : '
                              || g_header_rec.pos_txn_number(i);
                fnd_message.set_name('XXOM',
                                     'XX_OM_REQ_ATTR_MISSING');
                fnd_message.set_token('ATTRIBUTE',
                                      'Orig Sys Document Ref');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        -- IF the deposit total is negative then it is a deposit refund/credit
        IF SUBSTR(p_order_rec.file_line,
                  268,
                  1) = '-'
        THEN
            p_credit_flag := 'Y';
        ELSE
            p_credit_flag := 'N';
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Original System Refrence = '
                             || g_header_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD(   'POS Transaction Number = '
                             || g_header_rec.pos_txn_number(i));
            oe_debug_pub.ADD(   'Paid at store id = '
                             || lc_paid_at_store_id);
            oe_debug_pub.ADD(   'Order Source = '
                             || lc_order_source);
            oe_debug_pub.ADD(   'Customer Ref = '
                             || lc_customer_ref);
            oe_debug_pub.ADD(   'SPC card number = '
                             || g_header_rec.spc_card_number(i));
            oe_debug_pub.ADD(   'lc_order_category = '
                             || lc_order_category);
        END IF;

        -- to get order source id
        IF lc_order_source IS NOT NULL
        THEN
            g_header_rec.order_source_id(i) := xx_om_sacct_conc_pkg.order_source(lc_order_source,null); -- added for Biz Box 

            IF g_header_rec.order_source_id(i) IS NULL
            THEN
                g_header_rec.error_flag(i) := 'Y';
                --g_header_rec.order_source(i) := lc_order_source;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'ORDER_SOURCE_ID NOT FOUND FOR Order Source : '
                              || lc_order_source;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_ATTR_DERIVATION');
                fnd_message.set_token('ATTRIBUTE',
                                         'ORDER SOURCE - '
                                      || lc_order_source);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.order_source_id(i) := NULL;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Request_id '
                             || g_request_id);
            oe_debug_pub.ADD(   'Order Source is '
                             || g_header_rec.order_source_id(i));
        END IF;

        IF lc_paid_at_store_id IS NOT NULL
        THEN
            g_header_rec.paid_at_store_id(i) := xx_om_sacct_conc_pkg.get_store_id(lc_paid_at_store_id);
            g_header_rec.paid_at_store_no(i) := lc_paid_at_store_id;
            g_header_rec.created_by_store_id(i) := g_header_rec.paid_at_store_id(i);
        ELSE
            g_header_rec.paid_at_store_id(i) := NULL;
            g_header_rec.paid_at_store_no(i) := NULL;
            g_header_rec.created_by_store_id(i) := NULL;
        END IF;

        /* to get customer_id */
        IF lc_customer_ref IS NULL
        THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_org_id(i) := NULL;
            g_header_rec.sold_to_org(i) := lc_customer_ref;
            set_msg_context(p_entity_code      => 'HEADER');
            lc_err_msg :=    'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : '
                          || lc_customer_ref;
            fnd_message.set_name('XXOM',
                                 'XX_OM_MISSING_ATTRIBUTE');
            fnd_message.set_token('ATTRIBUTE',
                                  'Customer Reference');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        ELSE
            lc_orig_sys_customer_ref :=    lc_customer_ref
                                        || '-00001-A0';
            lc_orig_sys := 'A0';
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Customer Ref is '
                             || lc_orig_sys_customer_ref);
        END IF;

        IF lc_orig_sys_customer_ref IS NOT NULL
        THEN
            hz_orig_system_ref_pub.get_owner_table_id(p_orig_system                => lc_orig_sys,
                                                      p_orig_system_reference      => lc_orig_sys_customer_ref,
                                                      p_owner_table_name           => 'HZ_CUST_ACCOUNTS',
                                                      x_owner_table_id             => g_header_rec.sold_to_org_id(i),
                                                      x_return_status              => lc_return_status);

            IF (lc_return_status <> fnd_api.g_ret_sts_success)
            THEN
                g_header_rec.error_flag(i) := 'Y';
                g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : '
                              || lc_orig_sys_customer_ref;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_ATTR_DERIVATION');
                fnd_message.set_token('ATTRIBUTE',
                                         'SOLD_TO_ORG_ID'
                                      || '-'
                                      || lc_orig_sys_customer_ref);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSE
                IF ln_debug_level > 0
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'The Customer Account Found: '
                                      || g_header_rec.sold_to_org_id(i));
                END IF;
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Sold_To_org_Id is : ',
                             g_header_rec.sold_to_org_id(i));
        END IF;

        g_header_counter :=   g_header_counter
                            + 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Header '
                              || g_header_rec.orig_sys_document_ref(i));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            RAISE fnd_api.g_exc_unexpected_error;
    END process_header;

/* 11.2  Added for SDR */
    PROCEDURE process_sp_order_details(
        p_order_rec  IN  order_rec_type)
    IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_payment                                           |
-- | Description      : This Procedure will read the payments line from|
-- |                     file validate , derive and insert into global |
-- |                     record types,which later is used to populate  |
-- |                     custom table                                  |
-- |                                                                   |
-- +===================================================================+
        j                        BINARY_INTEGER;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        ln_hdr_ind               NUMBER;
        lc_err_msg               VARCHAR2(240);
    BEGIN
        oe_debug_pub.ADD('Beginning Of SP Order Dtl Program');
        -- Get the current index of the header record
        ln_hdr_ind := g_header_rec.pos_txn_number.COUNT;
        j :=   g_sp_ord_dtl_rec.transaction_number.COUNT
             + 1;
        g_sp_ord_dtl_rec.transaction_number(j) := g_header_rec.pos_txn_number(ln_hdr_ind);
        g_sp_ord_dtl_rec.order_source_id(j) := g_header_rec.order_source_id(ln_hdr_ind);
        g_sp_ord_dtl_rec.orig_sys_document_ref(j) := TRIM(SUBSTR(p_order_rec.file_line,
                                                                 33,
                                                                 20));
        g_sp_ord_dtl_rec.order_total(j) := TRIM(SUBSTR(p_order_rec.file_line,
                                                       54,
                                                       10));
        g_sp_ord_dtl_rec.single_pay_ind(j) := g_header_rec.is_reference_return(ln_hdr_ind);

        IF g_sp_ord_dtl_rec.orig_sys_document_ref(j) IS NULL
        THEN
            g_header_rec.error_flag(ln_hdr_ind) := 'Y';
            set_msg_context(p_entity_code      => 'HEADER_DTL');
            lc_err_msg :=    'Missing Orig Sys Document Ref for : '
                          || g_header_rec.pos_txn_number(ln_hdr_ind);
            fnd_message.set_name('XXOM',
                                 'XX_OM_REQ_ATTR_MISSING');
            fnd_message.set_token('ATTRIBUTE',
                                  'Orig Sys Document Ref');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'G_sp_ord_dtl_rec.transaction_number(j) : '
                             || g_sp_ord_dtl_rec.transaction_number(j));
            oe_debug_pub.ADD(   'G_sp_ord_dtl_rec.order_source_id(j) : '
                             || g_sp_ord_dtl_rec.order_source_id(j));
            oe_debug_pub.ADD(   'G_sp_ord_dtl_rec.orig_sys_document_ref(j) : '
                             || g_sp_ord_dtl_rec.orig_sys_document_ref(j));
            oe_debug_pub.ADD(   'G_sp_ord_dtl_rec.order_total(j) : '
                             || g_sp_ord_dtl_rec.order_total(j));
        END IF;
    END process_sp_order_details;

    PROCEDURE process_payment(
        p_order_rec  IN  order_rec_type)
    IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_payment                                           |
-- | Description      : This Procedure will read the payments line from|
-- |                     file validate , derive and insert into global |
-- |                     record types,which later is used to populate  |
-- |                     custom table                                  |
-- |                                                                   |
-- +===================================================================+
        i                        BINARY_INTEGER;
        lc_pay_type              VARCHAR2(10);
        ln_sold_to_org_id        NUMBER;
        ln_payment_number        NUMBER         := 0;
        lc_err_msg               VARCHAR2(200);
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        ln_hdr_ind               NUMBER;
        lc_payment_type_code     VARCHAR2(30);
        lc_cc_code               VARCHAR2(80);
        lc_cc_name               VARCHAR2(80);
        ln_receipt_method_id     NUMBER;
        ld_exp_date              DATE;
        ln_pay_amount            NUMBER;
        lc_key_name              VARCHAR2(25);
        lc_cc_number_enc         VARCHAR2(128);
        lc_cc_number_dec         VARCHAR2(50);
        lc_cc_mask               VARCHAR2(20);
        lc_pay_sign              VARCHAR2(1);
        lc_cc_entry              VARCHAR2(30);
        lc_cvv_resp              VARCHAR2(1);
        lc_avs_resp              VARCHAR2(1);
        lc_auth_entry_mode       VARCHAR2(1);
        lc_cc_number_enc_custom  VARCHAR2(128);
        lc_identifier            VARCHAR2(50);
        ln_length                NUMBER         := 16;
        lb_bool                  BOOLEAN        := TRUE;
    BEGIN
        g_transaction_number := NULL;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Process_Payment');
        END IF;

        -- Get the current index of the header record
        ln_hdr_ind := g_header_rec.pos_txn_number.COUNT;
        -- Get the index for G_Payment_Rec
        i :=   g_payment_rec.orig_sys_document_ref.COUNT
             + 1;
        g_payment_rec.error_flag(i) := g_header_rec.error_flag(ln_hdr_ind);
        g_payment_rec.currency_code(i) := g_header_rec.transactional_curr_code(ln_hdr_ind);
        --g_payment_rec.store_location(i) := g_header_rec.paid_at_store_no(ln_hdr_ind);
        g_payment_rec.paid_at_store_id(i) := g_header_rec.paid_at_store_id(ln_hdr_ind);
        g_payment_rec.single_pay_ind(i) := g_header_rec.is_reference_return(ln_hdr_ind);
        -- Read the Payment Type
        lc_pay_type := SUBSTR(p_order_rec.file_line,
                              36,
                              2);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Pay Type '
                             || lc_pay_type);
        END IF;

        -- Read the Payment amount
        ln_pay_amount := SUBSTR(p_order_rec.file_line,
                                39,
                                10);
        lc_pay_sign := SUBSTR(p_order_rec.file_line,
                              38,
                              1);

        IF lc_pay_sign = '-'
        THEN
            ln_pay_amount :=   ln_pay_amount
                             * -1;
        END IF;

        --Added the transaction number.
        IF g_order_source = 'P'
        THEN
            g_transaction_number := g_header_rec.pos_txn_number(ln_hdr_ind);
        ELSE
            g_transaction_number := NULL;
        END IF;

        IF lc_pay_type IS NULL
        THEN
            set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
            g_payment_rec.error_flag(i) := 'Y';
            g_header_rec.error_flag(ln_hdr_ind) := 'Y';
            lc_err_msg :=    'PAYMENT METHOD Missing on : '
                          || g_header_rec.pos_txn_number(ln_hdr_ind);
            fnd_message.set_name('XXOM',
                                 'XX_OM_MISSING_ATTRIBUTE');
            fnd_message.set_token('ATTRIBUTE',
                                  'Tender Type');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        IF lc_pay_type IS NOT NULL
        THEN
            xx_om_sacct_conc_pkg.get_pay_method(p_payment_instrument      => lc_pay_type,
                                                p_payment_type_code       => lc_payment_type_code,
                                                p_credit_card_code        => lc_cc_code);

            IF lc_payment_type_code IS NULL
            THEN
                g_payment_rec.i1025_status(i) := 'AB_ACCOUNT';
                g_payment_rec.payment_type_code(i) := lc_pay_type;
                g_payment_rec.credit_card_code(i) := lc_cc_code;
                lc_payment_type_code := lc_pay_type;
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'After Pay method, payment_type_code '
                             || lc_payment_type_code);
            oe_debug_pub.ADD(   'After Pay method, cc code '
                             || lc_cc_code);
            oe_debug_pub.ADD(   'Transaction number '
                             || g_transaction_number);
        END IF;

        -- Get the receipt method for the tender type
        IF lc_pay_type = 'AB'
        THEN
            ln_receipt_method_id := NULL;
        ELSE
            ln_receipt_method_id :=
                xx_om_sacct_conc_pkg.get_receipt_method(lc_pay_type,
                                                        g_org_id,
                                                        g_header_rec.paid_at_store_no(ln_hdr_ind));
            g_payment_rec.i1025_status(i) := 'NEW';

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Receipt Method Id '
                                 || ln_receipt_method_id);
            END IF;

            IF ln_receipt_method_id IS NULL
            THEN
                set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                lc_err_msg := 'Could not derive Receipt Method for the payment instrument';
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                fnd_message.set_name('XXOM',
                                     'XX_OM_NO_RECEIPT_METHOD');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        -- Read the CC exp date first
        BEGIN
            ld_exp_date := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                69,
                                                4)),
                                   'MMYY');
        EXCEPTION
            WHEN OTHERS
            THEN
                ld_exp_date := NULL;
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Error reading CC Exp Date'
                              || SUBSTR(p_order_rec.file_line,
                                        69,
                                        4);
                fnd_message.set_name('XXOM',
                                     'XX_OM_READ_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      'CC Exp Date');
                fnd_message.set_token('ATTRIBUTE2',
                                      SUBSTR(p_order_rec.file_line,
                                             69,
                                             4));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
        END;

        -- Initialize the CC number first
        g_payment_rec.credit_card_number(i) := NULL;
        -- Read Credit Card Details..
        lc_key_name := TRIM(SUBSTR(p_order_rec.file_line,
                                   174,
                                   24));
        lc_cc_number_enc := TRIM(SUBSTR(p_order_rec.file_line,
                                        199,
                                        48));
        lc_cc_mask := TRIM(SUBSTR(p_order_rec.file_line,
                                  49,
                                  20));

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Key Name'
                             || lc_key_name,
                             1);
            -- oe_debug_pub.add('CC Num read from file' || lc_cc_number_enc, 1);
            oe_debug_pub.ADD(   'CC Mask'
                             || lc_cc_mask,
                             1);
        END IF;

        IF lc_cc_number_enc IS NULL AND lc_cc_mask IS NOT NULL
        THEN
            lc_cc_number_enc := lc_cc_mask;
        END IF;

        oe_debug_pub.ADD(   'lc_cc_number_enc: '
                         || lc_cc_number_enc,
                         1);
        oe_debug_pub.ADD(   'lc_payment_type_code: '
                         || lc_payment_type_code,
                         1);
        oe_debug_pub.ADD(   'xx_om_hvop_util_pkg.g_use_test_cc: '
                         || xx_om_hvop_util_pkg.g_use_test_cc,
                         1);

        IF lc_cc_number_enc IS NOT NULL AND lc_payment_type_code = 'CREDIT_CARD'
        THEN
            IF xx_om_hvop_util_pkg.g_use_test_cc = 'N'
            THEN
                DBMS_SESSION.set_context(namespace      => 'XX_OM_DEP_CONTEXT',
                                         ATTRIBUTE      => 'TYPE',
                                         VALUE          => 'OM');
                -- Use the Credit card read from the file
                xx_od_security_key_pkg.decrypt(p_module             => 'HVOP',
                                               p_key_label          => lc_key_name,
                                               p_encrypted_val      => lc_cc_number_enc,
                                               p_format             => 'EBCDIC',
                                               x_decrypted_val      => lc_cc_number_dec,
                                               x_error_message      => lc_err_msg);
            ELSE
                -- Use the first 6 and last 4 of the CC mask and generate a TEST credit card
                IF lc_pay_type = '26'
                THEN
                    ln_length := 15;
                END IF;

                lc_cc_number_dec :=
                          xx_om_hvop_util_pkg.get_test_cc(SUBSTR(lc_cc_mask,
                                                                 1,
                                                                 6),
                                                          SUBSTR(lc_cc_mask,
                                                                 7,
                                                                 4),
                                                          ln_length);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Test CC number is '
                                     || lc_cc_number_dec);
                END IF;
            END IF;

            IF ln_debug_level > 0
            THEN
                --oe_debug_pub.add('CC Num after decryption' || lc_cc_number_dec, 1);
                oe_debug_pub.ADD(   'CC Num length'
                                 || LENGTH(lc_cc_number_dec),
                                 1);
                oe_debug_pub.ADD(   'Error Message'
                                 || lc_err_msg,
                                 1);
            END IF;

            IF lc_cc_number_dec IS NULL
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                g_payment_rec.credit_card_number(i) :=    lc_key_name
                                                       || ':'
                                                       || lc_cc_number_enc;
                lc_err_msg :=    'Error Decrypting credit card number'
                              || lc_cc_number_enc;
                fnd_message.set_name('XXOM',
                                     'XX_OM_CC_DECRYPT_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_err_msg);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSIF    SUBSTR(lc_cc_number_dec,
                            1,
                            6)
                  || SUBSTR(lc_cc_number_dec,
                            -4,
                            4) <> lc_cc_mask
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                g_payment_rec.credit_card_number(i) :=    lc_key_name
                                                       || ':'
                                                       || lc_cc_number_enc;
                lc_err_msg :=
                       'Decrypted Credit card number :'
                    || SUBSTR(lc_cc_number_dec,
                              1,
                              6)
                    || SUBSTR(lc_cc_number_dec,
                              -4,
                              4)
                    || ' does not match mask value '
                    || lc_cc_mask;
                fnd_message.set_name('XXOM',
                                     'XX_OM_CC_MASK_MISMATCH');
                fnd_message.set_token('ATTRIBUTE1',
                                         SUBSTR(lc_cc_number_dec,
                                                1,
                                                6)
                                      || SUBSTR(lc_cc_number_dec,
                                                -4,
                                                4));
                fnd_message.set_token('ATTRIBUTE2',
                                      lc_cc_mask);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Start reading Payment Record ');
        END IF;

        /*Initialise all varibales to Null */
        g_payment_rec.orig_sys_document_ref(i) := NULL;
        g_payment_rec.order_source_id(i) := NULL;
        g_payment_rec.orig_sys_payment_ref(i) := NULL;
        g_payment_rec.payment_type_code(i) := NULL;
        g_payment_rec.payment_collection_event(i) := NULL;
        g_payment_rec.prepaid_amount(i) := NULL;
        g_payment_rec.credit_card_holder_name(i) := NULL;
        g_payment_rec.credit_card_expiration_date(i) := NULL;
        g_payment_rec.credit_card_code(i) := NULL;
        g_payment_rec.credit_card_approval_code(i) := NULL;
        g_payment_rec.credit_card_approval_date(i) := NULL;
        g_payment_rec.check_number(i) := NULL;
        g_payment_rec.payment_amount(i) := NULL;
        g_payment_rec.operation_code(i) := NULL;
        g_payment_rec.receipt_method_id(i) := NULL;
        g_payment_rec.payment_number(i) := NULL;
        g_payment_rec.attribute6(i) := NULL;
        g_payment_rec.attribute7(i) := NULL;
        g_payment_rec.attribute8(i) := NULL;
        g_payment_rec.attribute9(i) := NULL;
        g_payment_rec.attribute10(i) := NULL;
        g_payment_rec.sold_to_org_id(i) := NULL;
        g_payment_rec.sold_to_org(i) := NULL;
        g_payment_rec.attribute11(i) := NULL;
        g_payment_rec.attribute12(i) := NULL;
        g_payment_rec.attribute13(i) := NULL;
        g_payment_rec.attribute3(i) := NULL;
        g_payment_rec.attribute14(i) := NULL;
        g_payment_rec.IDENTIFIER(i) := NULL;
        g_payment_rec.payment_type_code(i) := lc_payment_type_code;
        g_payment_rec.receipt_method_id(i) := ln_receipt_method_id;
        g_payment_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
        g_payment_rec.sold_to_org_id(i) := g_header_rec.sold_to_org_id(ln_hdr_ind);
        g_payment_rec.sold_to_org(i) := g_header_rec.sold_to_org(ln_hdr_ind);
        g_payment_rec.order_source_id(i) := g_header_rec.order_source_id(ln_hdr_ind);
        g_payment_rec.orig_sys_payment_ref(i) := SUBSTR(p_order_rec.file_line,
                                                        33,
                                                        3);
        g_payment_rec.prepaid_amount(i) := ln_pay_amount;
        g_payment_rec.payment_amount(i) := NULL;
        g_payment_rec.transaction_number(i) := g_header_rec.pos_txn_number(ln_hdr_ind);
        g_payment_rec.attribute11(i) := lc_pay_type;
        g_payment_rec.avail_balance(i) := g_payment_rec.prepaid_amount(i);
        g_payment_rec.receipt_date(i) := g_header_rec.sas_sale_date(ln_hdr_ind);

        IF g_header_rec.sold_to_org_id(ln_hdr_ind) IS NOT NULL AND lc_cc_number_enc IS NOT NULL
        THEN
            lc_cc_name := xx_om_sacct_conc_pkg.credit_card_name(g_header_rec.sold_to_org_id(ln_hdr_ind));
        END IF;

        IF lc_cc_number_dec IS NOT NULL
        THEN
            lc_cc_number_enc_custom := NULL;
            lc_identifier := NULL;
            DBMS_SESSION.set_context(namespace      => 'XX_OM_DEP_CONTEXT',
                                     ATTRIBUTE      => 'TYPE',
                                     VALUE          => 'EBS');
            xx_od_security_key_pkg.encrypt_outlabel(p_module             => 'AJB',
                                                    p_key_label          => NULL,
                                                    p_algorithm          => '3DES',
                                                    p_decrypted_val      => lc_cc_number_dec,
                                                    x_encrypted_val      => lc_cc_number_enc_custom,
                                                    x_error_message      => lc_err_msg,
                                                    x_key_label          => lc_identifier);

            IF (lc_cc_number_enc_custom IS NULL OR lc_identifier IS NULL)
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                g_payment_rec.credit_card_number(i) :=    lc_key_name
                                                       || ':'
                                                       || lc_cc_number_enc;
                lc_err_msg :=    'Error Encrypting credit card number'
                              || lc_cc_number_enc;
                fnd_message.set_name('XXOM',
                                     'XX_OM_CC_DECRYPT_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_err_msg);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSE
                g_payment_rec.credit_card_number(i) := lc_cc_number_enc_custom;
                g_payment_rec.IDENTIFIER(i) := lc_identifier;
            END IF;
        END IF;

        IF lc_cc_number_enc IS NOT NULL
        THEN
            oe_debug_pub.ADD('Credit_card info Entering:::');
            g_payment_rec.credit_card_expiration_date(i) := ld_exp_date;
            g_payment_rec.credit_card_code(i) := lc_cc_code;
            g_payment_rec.credit_card_approval_code(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                             75,
                                                                             6)));

            IF ld_exp_date IS NULL
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg := 'CC EXP DATE IS MISSING';
                fnd_message.set_name('XXOM',
                                     'XX_OM_MISSING_ATTRIBUTE');
                fnd_message.set_token('ATTRIBUTE',
                                      'Credit Card EXP date');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;

            IF g_payment_rec.credit_card_approval_code(i) IS NULL AND lc_pay_type NOT IN('16') AND ln_pay_amount > 0
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg := 'CC approval code is missing';
                fnd_message.set_name('XXOM',
                                     'XX_OM_MISSING_ATTRIBUTE');
                fnd_message.set_token('ATTRIBUTE',
                                      'Credit Card Approval Code');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;

            BEGIN
                g_payment_rec.credit_card_approval_date(i) :=
                                                    TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                                         81,
                                                                         10)),
                                                            'YYYY-MM-DD');
            EXCEPTION
                WHEN OTHERS
                THEN
                    g_payment_rec.credit_card_approval_date(i) := NULL;
                    g_payment_rec.error_flag(i) := 'Y';
                    g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'Error reading CC Approval Date'
                                  || SUBSTR(p_order_rec.file_line,
                                            81,
                                            10);
                    fnd_message.set_name('XXOM',
                                         'XX_OM_READ_ERROR');
                    fnd_message.set_token('ATTRIBUTE1',
                                          'CC Approval Date');
                    fnd_message.set_token('ATTRIBUTE2',
                                          SUBSTR(p_order_rec.file_line,
                                                 81,
                                                 10));
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
            END;

            IF g_payment_rec.credit_card_approval_date(i) IS NULL AND lc_pay_type NOT IN('16') AND ln_pay_amount > 0
            THEN
                g_payment_rec.error_flag(i) := 'Y';
                g_header_rec.error_flag(ln_hdr_ind) := 'Y';
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg := 'CC approval date is missing';
                fnd_message.set_name('XXOM',
                                     'XX_OM_MISSING_ATTRIBUTE');
                fnd_message.set_token('ATTRIBUTE',
                                      'Credit Card Approval Date');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            oe_debug_pub.ADD('Not a Credit Card 2:::');
            g_payment_rec.credit_card_number(i) := NULL;
            g_payment_rec.credit_card_expiration_date(i) := NULL;
            g_payment_rec.credit_card_code(i) := NULL;
            g_payment_rec.credit_card_approval_code(i) := NULL;
            g_payment_rec.credit_card_approval_date(i) := NULL;
            g_payment_rec.check_number(i) := NULL;
            g_payment_rec.attribute6(i) := NULL;
            g_payment_rec.attribute7(i) := NULL;
            g_payment_rec.attribute8(i) := NULL;
            g_payment_rec.attribute9(i) := NULL;
            g_payment_rec.attribute10(i) := NULL;
            g_payment_rec.attribute3(i) := NULL;
            g_payment_rec.attribute14(i) := NULL;
        END IF;

        g_payment_rec.check_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                            91,
                                                            20)));
        g_payment_rec.payment_number(i) := g_payment_rec.orig_sys_payment_ref(i);
        g_payment_rec.attribute6(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                          111,
                                                          1)));
        g_payment_rec.attribute7(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                          112,
                                                          11)));
        g_payment_rec.attribute8(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                          123,
                                                          50)));
        g_payment_rec.attribute9(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                          173,
                                                          1)));
        g_payment_rec.attribute10(i) := lc_cc_mask;
        g_payment_rec.credit_card_holder_name(i) := lc_cc_name;
        g_payment_rec.attribute11(i) := lc_pay_type;
        -- Read the Debit Card Approval reference number
        g_payment_rec.attribute12(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           247,
                                                           30)));
        -- Adding the code to capture CC entry mode (keyed or swiped), CVV response code and AVS response code
        g_payment_rec.cc_entry_mode(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             277,
                                                             1)));
        g_payment_rec.cvv_resp_code(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             278,
                                                             1)));
        g_payment_rec.avs_resp_code(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             279,
                                                             1)));
        g_payment_rec.auth_entry_mode(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                               280,
                                                               1)));
        g_payment_rec.attribute13(i) :=
               g_payment_rec.cc_entry_mode(i)
            || ':'
            || g_payment_rec.cvv_resp_code(i)
            || ':'
            || g_payment_rec.avs_resp_code(i)
            || ':'
            || g_payment_rec.auth_entry_mode(i);

        -- Adding the code to capture the Tokenization and EMV fields for defect -34103

        g_payment_rec.attribute3(i)  :=  LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,283,1)));         -- Token flag
        g_payment_rec.attribute14(i) :=  SUBSTR(p_order_rec.file_line,284,1)||'.'||   -- EMV card
                                         SUBSTR(p_order_rec.file_line,285,2)||'.'||   -- EMV Terminal
                                         SUBSTR(p_order_rec.file_line,287,1)||'.'||   -- EMV Transaction
                                         SUBSTR(p_order_rec.file_line,288,1)||'.'||   -- EMV Offline
                                         SUBSTR(p_order_rec.file_line,289,1)||'.'||   -- EMV Fallback
                                         SUBSTR(p_order_rec.file_line,290,10) ;       -- EMV TVR

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'lc_pay_type = '
                             || lc_pay_type);
            oe_debug_pub.ADD(   'receipt_method = '
                             || g_payment_rec.receipt_method_id(i));
            oe_debug_pub.ADD(   'orig_sys_document_ref = '
                             || g_payment_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD(   'order_source_id = '
                             || g_payment_rec.order_source_id(i));
            oe_debug_pub.ADD(   'orig_sys_payment_ref = '
                             || g_payment_rec.orig_sys_payment_ref(i));
            oe_debug_pub.ADD(   'payment_amount = '
                             || g_payment_rec.payment_amount(i));
            oe_debug_pub.ADD(   'lc_cc_number = '
                             || lc_cc_number_dec);
            oe_debug_pub.ADD(   'credit_card_expiration_date = '
                             || g_payment_rec.credit_card_expiration_date(i));
            oe_debug_pub.ADD(   'credit_card_approval_code = '
                             || g_payment_rec.credit_card_approval_code(i));
            oe_debug_pub.ADD(   'credit_card_approval_date = '
                             || g_payment_rec.credit_card_approval_date(i));
            oe_debug_pub.ADD(   'check_number = '
                             || g_payment_rec.check_number(i));
            oe_debug_pub.ADD(   'Sold To Org Id = '
                             || g_payment_rec.sold_to_org_id(i));
            oe_debug_pub.ADD(   'attribute6 = '
                             || g_payment_rec.attribute6(i));
            oe_debug_pub.ADD(   'attribute7 = '
                             || g_payment_rec.attribute7(i));
            oe_debug_pub.ADD(   'attribute8 = '
                             || g_payment_rec.attribute8(i));
            oe_debug_pub.ADD(   'attribute9 = '
                             || g_payment_rec.attribute9(i));
            oe_debug_pub.ADD(   'attribute10 = '
                             || g_payment_rec.attribute10(i));
            oe_debug_pub.ADD(   'attribute11 = '
                             || g_payment_rec.attribute11(i));
            oe_debug_pub.ADD(   'attribute12 = '
                             || g_payment_rec.attribute12(i));
            oe_debug_pub.ADD(   'attribute13 = '
                             || g_payment_rec.attribute13(i));
            oe_debug_pub.ADD(   'credit_card_holder_name = '
                             || g_payment_rec.credit_card_holder_name(i));
            oe_debug_pub.ADD(   'attribute3 = '
                             || g_payment_rec.attribute3(i));
            oe_debug_pub.ADD(   'attribute14 = '
                             || g_payment_rec.attribute14(i));

            oe_debug_pub.ADD('Exiting process_payment ');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Payment for:'
                              || g_payment_rec.orig_sys_document_ref(i));
            fnd_file.put_line(fnd_file.LOG,
                                 'Payment Ref:'
                              || g_payment_rec.orig_sys_payment_ref(i));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            RAISE fnd_api.g_exc_unexpected_error;
    END process_payment;

    PROCEDURE insert_data
    IS
    BEGIN
        oe_debug_pub.ADD(' Entering insert_data');
        FORALL i_pay IN INDICES OF g_payment_rec.transaction_number
            INSERT INTO xx_om_legacy_deposits
                        (orig_sys_document_ref,
                         order_source_id,
                         orig_sys_payment_ref,
                         org_id,
                         payment_type_code,
                         payment_collection_event,
                         prepaid_amount,
                         credit_card_number,
                         credit_card_holder_name,
                         credit_card_expiration_date,
                         credit_card_code,
                         credit_card_approval_code,
                         credit_card_approval_date,
                         check_number,
                         payment_amount,
                         operation_code,
                         error_flag,
                         receipt_method_id,
                         payment_number,
                         created_by,
                         creation_date,
                         last_update_date,
                         last_updated_by,
                         request_id,
                         cc_auth_manual,
                         merchant_number,
                         cc_auth_ps2000,
                         allied_ind,
                         currency_code,
                         process_code,
                         sold_to_org_id,
                         sold_to_org,
                         transaction_number,
                         cc_mask_number,
                         od_payment_type,
                         avail_balance,
                         paid_at_store_id,
                         debit_card_approval_ref,
                         receipt_date,
                         imp_file_name,
                         cc_entry_mode,
                         cvv_resp_code,
                         avs_resp_code,
                         auth_entry_mode,
                         i1025_status,
                         single_pay_ind,
                         IDENTIFIER,
                         token_flag,
                         emv_card,
                         emv_terminal,
                         emv_transaction,
                         emv_offline,
                         emv_fallback,
                         emv_tvr)
                 VALUES (g_payment_rec.orig_sys_document_ref(i_pay),
                         g_payment_rec.order_source_id(i_pay),
                         g_payment_rec.orig_sys_payment_ref(i_pay),
                         g_org_id,
                         g_payment_rec.payment_type_code(i_pay),
                         g_payment_rec.payment_collection_event(i_pay),
                         g_payment_rec.prepaid_amount(i_pay),
                         g_payment_rec.credit_card_number(i_pay),
                         g_payment_rec.credit_card_holder_name(i_pay),
                         g_payment_rec.credit_card_expiration_date(i_pay),
                         g_payment_rec.credit_card_code(i_pay),
                         g_payment_rec.credit_card_approval_code(i_pay),
                         g_payment_rec.credit_card_approval_date(i_pay),
                         g_payment_rec.check_number(i_pay),
                         g_payment_rec.payment_amount(i_pay),
                         g_payment_rec.operation_code(i_pay),
                         g_payment_rec.error_flag(i_pay),
                         g_payment_rec.receipt_method_id(i_pay),
                         g_payment_rec.payment_number(i_pay),
                         fnd_global.user_id,
                         SYSDATE,
                         SYSDATE,
                         fnd_global.user_id,
                         g_request_id,
                         g_payment_rec.attribute6(i_pay),
                         g_payment_rec.attribute7(i_pay),
                         g_payment_rec.attribute8(i_pay),
                         g_payment_rec.attribute9(i_pay),
                         g_payment_rec.currency_code(i_pay),
                         'P',
                         g_payment_rec.sold_to_org_id(i_pay),
                         g_payment_rec.sold_to_org(i_pay),
                         g_payment_rec.transaction_number(i_pay),
                         g_payment_rec.attribute10(i_pay),
                         g_payment_rec.attribute11(i_pay),
                         g_payment_rec.avail_balance(i_pay),
                         g_payment_rec.paid_at_store_id(i_pay),
                         g_payment_rec.attribute12(i_pay),
                         g_payment_rec.receipt_date(i_pay),
                         g_file_name,
                         g_payment_rec.cc_entry_mode(i_pay),
                         g_payment_rec.cvv_resp_code(i_pay),
                         g_payment_rec.avs_resp_code(i_pay),
                         g_payment_rec.auth_entry_mode(i_pay),
                         g_payment_rec.i1025_status(i_pay),
                         g_payment_rec.single_pay_ind(i_pay),
                         g_payment_rec.IDENTIFIER(i_pay),
                         NVL(LTRIM(RTRIM(g_payment_rec.attribute3(i_pay))),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay), 1,(INSTR(g_payment_rec.attribute14(i_pay),'.',1,1)-1)))),'N'),
                         LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay), 3,(INSTR(g_payment_rec.attribute14(i_pay),'.',1,1))))),
                         NVL(LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay), 6,(INSTR(g_payment_rec.attribute14(i_pay),'.',1,1)-1)))),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay), 8,(INSTR(g_payment_rec.attribute14(i_pay),'.',1,1)-1)))),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay), 10,(INSTR(g_payment_rec.attribute14(i_pay),'.',1,1)-1)))),'N'),
                         LTRIM(RTRIM(SUBSTR(g_payment_rec.attribute14(i_pay),12,10)))
                         );

        oe_debug_pub.ADD(   'Exiting Payment insert_data :'
                         || SQL%ROWCOUNT);

        FORALL i_ord IN INDICES OF g_sp_ord_dtl_rec.transaction_number
            INSERT INTO xx_om_legacy_dep_dtls
                        (transaction_number,
                         order_source_id,
                         orig_sys_document_ref,
                         order_total,
                         single_pay_ind,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by)
                 VALUES (g_sp_ord_dtl_rec.transaction_number(i_ord),
                         g_sp_ord_dtl_rec.order_source_id(i_ord),
                         g_sp_ord_dtl_rec.orig_sys_document_ref(i_ord),
                         g_sp_ord_dtl_rec.order_total(i_ord),
                         g_sp_ord_dtl_rec.single_pay_ind(i_ord),
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id);
        oe_debug_pub.ADD(   'Exiting order dtl insert_data :'
                         || SQL%ROWCOUNT);
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in inserting Deposit records ag:'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            RAISE fnd_api.g_exc_error;
    END insert_data;

    PROCEDURE set_msg_context(
        p_entity_code  IN  VARCHAR2,
        p_line_ref     IN  VARCHAR2 DEFAULT NULL)
    IS
        ln_hdr_ind  BINARY_INTEGER := g_header_rec.pos_txn_number.COUNT;
    BEGIN
        oe_bulk_msg_pub.set_msg_context(p_entity_code                     => p_entity_code,
                                        p_entity_ref                      => NULL,
                                        p_entity_id                       => NULL,
                                        p_header_id                       => NULL,
                                        p_line_id                         => NULL,
                                        p_order_source_id                 => g_header_rec.order_source_id(ln_hdr_ind),
                                        p_orig_sys_document_ref           => g_header_rec.pos_txn_number(ln_hdr_ind),
                                        p_orig_sys_document_line_ref      => NULL,
                                        p_orig_sys_shipment_ref           => NULL,
                                        p_change_sequence                 => NULL,
                                        p_source_document_type_id         => NULL,
                                        p_source_document_id              => NULL,
                                        p_source_document_line_id         => NULL,
                                        p_attribute_code                  => NULL,
                                        p_constraint_id                   => NULL);
    END set_msg_context;

    PROCEDURE process_trailer(
        p_order_rec  IN  order_rec_type)
    IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                   Office Depot                                    |
-- +===================================================================+
-- | Name  : Process_Deposits                                          |
-- | Description      : This Procedure will read the last line where   |
-- |                    total headers, total lines etc send in each    |
-- |                    feed and insert into history tbl               |
-- |                                                                   |
-- +===================================================================+
        ln_debug_level  CONSTANT NUMBER       := oe_debug_pub.g_debug_level;
        lc_process_date          VARCHAR2(14);
        lb_day_deduct            BOOLEAN      := FALSE;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering  Trailer Header');
        END IF;

        g_header_count := SUBSTR(p_order_rec.file_line,
                                 42,
                                 7);
        g_payment_count := SUBSTR(p_order_rec.file_line,
                                  66,
                                  7);
        g_payment_tot_amt := SUBSTR(p_order_rec.file_line,
                                    125,
                                    13);
        g_header_tot_amount := SUBSTR(p_order_rec.file_line,
                                      73,
                                      13);
        -- Read the Process Date from tariler record
        lc_process_date := NVL(TRIM(SUBSTR(p_order_rec.file_line,
                                           193,
                                           14)),
                               TO_CHAR(SYSDATE,
                                       'YYYYMMDDHH24MISS'));

        BEGIN
            IF TO_NUMBER(SUBSTR(lc_process_date,
                                9,
                                2)) < 10
            THEN
                g_process_date :=   TRUNC(TO_DATE(lc_process_date,
                                                  'YYYYMMDDHH24MISS'))
                                  - 1;
            ELSE
                g_process_date := TRUNC(TO_DATE(lc_process_date,
                                                'YYYYMMDDHH24MISS'));
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Error reading Process Date from trailer record :'
                                  || lc_process_date);
                g_process_date := TRUNC(SYSDATE);
        END;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Header Count  :'
                             || g_header_count);
            oe_debug_pub.ADD(   'Payment Count is :'
                             || g_payment_count);
            oe_debug_pub.ADD(   'Payment Total is :'
                             || g_payment_tot_amt);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Failed to process trailer record ');
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
    END process_trailer;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                   Office Depot                                    |
-- +===================================================================+
-- | Name  : Check_PostPayment                                         |
-- | Description      : This Procedure will validate to see if order   |
-- |                    already exist if so it treates as a payment    |
-- |                    and will process wxcept for single payment     |
-- |                    scenarios                                      |
-- +===================================================================+
    PROCEDURE check_postpayment(
        p_hdr_idx    IN  NUMBER,
        p_start_idx  IN  NUMBER)
    IS
        ln_debug_level  CONSTANT NUMBER                                := oe_debug_pub.g_debug_level;
        l_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
        l_hold_release_rec       oe_holds_pvt.hold_release_rec_type;
        l_header_rec             xx_om_sacct_conc_pkg.header_match_rec;
        lc_return_status         VARCHAR2(1);
        l_orig_sys_document_ref  VARCHAR2(50);
        l_ord_total              NUMBER;
        j                        BINARY_INTEGER;
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(2000);
        l_idx                    BINARY_INTEGER;
        l_payment_rec            xx_om_sacct_conc_pkg.payment_rec_type;
        l_del_tbl                xx_om_sacct_conc_pkg.t_bi;
        k                        BINARY_INTEGER;
        d_idx                    BINARY_INTEGER                        := 0;
        lc_transaction_number    VARCHAR2(80);
    BEGIN
        d_idx :=   d_idx
                 + 1;
        oe_debug_pub.ADD(   'Entering Check_PostPayment '
                         || p_hdr_idx);
        -- Need to check if the deposit is a POST PAYMENT where order already exists in EBS
        -- R11.2 Changes for single payment if order come first we should not treat it as payment and process instead
        -- skip the order so deposit will be created as a normal pre payment receipt. add logic in i1025 once receipt is
        -- created as pre payment them pull the order and start appling the amt off the order to prepayment and create a record in oe payments.
        lc_transaction_number := g_header_rec.pos_txn_number(p_hdr_idx);

        IF g_header_rec.orig_sys_document_ref(p_hdr_idx) IS NOT NULL
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'g_header_rec.orig_sys_document_ref(p_hdr_idx) '
                                 || g_header_rec.orig_sys_document_ref(p_hdr_idx));
            END IF;

            l_orig_sys_document_ref := g_header_rec.orig_sys_document_ref(p_hdr_idx);
        ELSIF     g_header_rec.orig_sys_document_ref(p_hdr_idx) IS NULL
              AND NVL(g_header_rec.is_reference_return(p_hdr_idx),
                      'N') != 'Y'
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'g_sp_ord_dtl_rec.orig_sys_document_ref(d_idx) '
                                 || g_sp_ord_dtl_rec.orig_sys_document_ref(d_idx));
            END IF;

            l_orig_sys_document_ref := g_sp_ord_dtl_rec.orig_sys_document_ref(d_idx);
        ELSE
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Skip releasing of order and create prepayment receipt : '
                                 || g_header_rec.is_reference_return(p_hdr_idx));
            END IF;

            GOTO end_of_header;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Orig Sys'
                             || l_orig_sys_document_ref);
        END IF;

        k := 0;

        BEGIN
            SELECT   h.header_id,
                     h.orig_sys_document_ref,
                     h.order_source_id,
                     h.transactional_curr_code,
                     hs.hold_id,
                     hs.hold_source_id,
                     oh.order_hold_id,
                     h.sold_to_org_id,
                     h.invoice_to_org_id,
                     h.order_number,
                     h.ship_from_org_id
            BULK COLLECT INTO l_header_rec.header_id,
                      l_header_rec.orig_sys_document_ref,
                      l_header_rec.order_source_id,
                      l_header_rec.curr_code,
                      l_header_rec.hold_id,
                      l_header_rec.hold_source_id,
                      l_header_rec.order_hold_id,
                      l_header_rec.sold_to_org_id,
                      l_header_rec.invoice_to_org_id,
                      l_header_rec.order_number,
                      l_header_rec.ship_from_org_id
            FROM     oe_order_headers h,
                     oe_order_holds oh,
                     oe_hold_sources hs,
                     oe_hold_definitions hd
            WHERE    orig_sys_document_ref LIKE    SUBSTR(l_orig_sys_document_ref,
                                                          1,
                                                          9)
                                                || '%'
            AND      h.header_id = oh.header_id
            AND      h.booked_flag = 'N'
            AND      oh.hold_release_id IS NULL
            AND      oh.hold_source_id = hs.hold_source_id
            AND      hs.hold_id = hd.hold_id
            AND      hd.NAME = 'OD: SAS Pending deposit hold'
            ORDER BY h.orig_sys_document_ref;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Found the data '
                                 || l_header_rec.header_id.COUNT);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD('No order exists for this deposit record : ',
                                     l_orig_sys_document_ref);
                END IF;

                GOTO end_of_header;
        END;

        FOR i IN 1 .. l_header_rec.header_id.COUNT
        LOOP
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Looping over the header loop '
                                 || i);
            END IF;

            -- Get the order total for each order
            SELECT SUM(  ROUND((  NVL(l.shipped_quantity,
                                      l.ordered_quantity)
                                * l.unit_selling_price),
                               2)
                       + ROUND(NVL(l.tax_value,
                                   0),
                               2))
            INTO   l_ord_total
            FROM   oe_order_lines l
            WHERE  l.header_id = l_header_rec.header_id(i);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Current order total is '
                                 || l_ord_total);
            END IF;

            -- Get the start index of the payment record
            l_idx := p_start_idx;
            j := 1;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'lc_transaction_number '
                                 || lc_transaction_number);
                oe_debug_pub.ADD(   'g_payment_rec.transaction_number(l_idx) '
                                 || g_payment_rec.transaction_number(l_idx));
            END IF;

            WHILE l_ord_total > 0 AND lc_transaction_number = g_payment_rec.transaction_number(l_idx)
            LOOP                                -- Loop over the deposit records for that order to match the order total
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Inside payment record loop '
                                     || l_ord_total);
                    oe_debug_pub.ADD(   ' payment record index is '
                                     || l_idx);
                    oe_debug_pub.ADD(   ' g_payment_rec.attribute11 '
                                     || g_payment_rec.attribute11(l_idx));
                END IF;

                -- Skip the payment record if available balance is zero or order total is zero
                IF g_payment_rec.avail_balance(l_idx) = 0 OR l_ord_total = 0
                THEN
                    oe_debug_pub.ADD(   'Skipping the record '
                                     || g_payment_rec.avail_balance(l_idx));
                    GOTO end_of_rec;
                END IF;

                IF g_payment_rec.attribute11(l_idx) = 'AB'
                THEN
                    GOTO end_of_dep_loop;
                    oe_debug_pub.ADD(   'Skipping the Deposit for pay type '
                                     || g_payment_rec.attribute11(l_idx));
                END IF;

                oe_debug_pub.ADD(   'Available balance is '
                                 || g_payment_rec.avail_balance(l_idx));

                -- Check if the Payment Record matches order total
                IF l_ord_total < g_payment_rec.avail_balance(l_idx)
                THEN
                    oe_debug_pub.ADD('Total less than balance');
                    -- set the new payment rec
                    l_payment_rec.prepaid_amount(j) := l_ord_total;
                    -- Update current deposit rec
                    g_payment_rec.prepaid_amount(l_idx) :=   g_payment_rec.avail_balance(l_idx)
                                                           - l_ord_total;
                    g_payment_rec.avail_balance(l_idx) := g_payment_rec.prepaid_amount(l_idx);
                    -- Order Total is matched by the availbale balance
                    l_ord_total := 0;
                ELSE
                    oe_debug_pub.ADD('Total greater or equal to balance');
                    -- set the new payment rec
                    l_payment_rec.prepaid_amount(j) := g_payment_rec.prepaid_amount(l_idx);
                    -- Order Total is matched by the availbale balance
                    l_ord_total :=   l_ord_total
                                   - g_payment_rec.avail_balance(l_idx);
                    -- Update current deposit rec
                    g_payment_rec.avail_balance(l_idx) := 0;
                    -- g_payment_rec.prepaid_amount(l_idx) := 0;
                    -- marking i1025 status to 'COMPLETE' has we treat this has a payment
                    g_payment_rec.i1025_status(l_idx) := 'COMPLETE';
                    g_payment_rec.i1025_status(j) := g_payment_rec.i1025_status(l_idx);
                    oe_debug_pub.ADD(   'G_payment_rec.i1025_status(j) :'
                                     || g_payment_rec.i1025_status(j));
                    -- Need to mark the current payment record for delete
                    k :=   k
                         + 1;
                    l_del_tbl(k) := l_idx;
                END IF;

                l_payment_rec.payment_set_id(j) := NULL;
                l_payment_rec.payment_type_code(j) := g_payment_rec.payment_type_code(l_idx);
                l_payment_rec.receipt_method_id(j) := g_payment_rec.receipt_method_id(l_idx);
                l_payment_rec.orig_sys_payment_ref(j) := g_payment_rec.orig_sys_payment_ref(l_idx);
                l_payment_rec.credit_card_number(j) := g_payment_rec.credit_card_number(l_idx);
                l_payment_rec.credit_card_expiration_date(j) := g_payment_rec.credit_card_expiration_date(l_idx);
                l_payment_rec.credit_card_code(j) := g_payment_rec.credit_card_code(l_idx);
                l_payment_rec.credit_card_approval_code(j) := g_payment_rec.credit_card_approval_code(l_idx);
                l_payment_rec.credit_card_approval_date(j) := g_payment_rec.credit_card_approval_date(l_idx);
                l_payment_rec.check_number(j) := g_payment_rec.check_number(l_idx);
                l_payment_rec.CONTEXT(j) := 'SALES_ACCT_HVOP';
                l_payment_rec.attribute6(j) := g_payment_rec.attribute6(l_idx);
                l_payment_rec.attribute7(j) := g_payment_rec.attribute7(l_idx);
                l_payment_rec.attribute8(j) := g_payment_rec.attribute8(l_idx);
                l_payment_rec.attribute9(j) := g_payment_rec.attribute9(l_idx);
                l_payment_rec.attribute10(j) := g_payment_rec.attribute10(l_idx);
                l_payment_rec.attribute11(j) := g_payment_rec.attribute11(l_idx);
                l_payment_rec.attribute12(j) := g_payment_rec.attribute12(l_idx);
                l_payment_rec.attribute13(j) := g_payment_rec.attribute13(l_idx);
                l_payment_rec.attribute15(j) := NULL;
                l_payment_rec.credit_card_holder_name(j) := g_payment_rec.credit_card_holder_name(l_idx);
                l_payment_rec.orig_sys_document_ref(j) := l_header_rec.orig_sys_document_ref(i);
                l_payment_rec.sold_to_org_id(j) := l_header_rec.sold_to_org_id(i);
                l_payment_rec.invoice_to_org_id(j) := l_header_rec.invoice_to_org_id(i);
                l_payment_rec.order_source_id(j) := l_header_rec.order_source_id(i);
                l_payment_rec.payment_number(j) := j;
                l_payment_rec.payment_amount(j) := l_payment_rec.prepaid_amount(j);
                l_payment_rec.header_id(j) := l_header_rec.header_id(i);
                l_payment_rec.order_curr_code(j) := l_header_rec.curr_code(i);
                l_payment_rec.order_number(j) := l_header_rec.order_number(i);
                l_payment_rec.receipt_date(j) := g_payment_rec.receipt_date(l_idx);
                l_payment_rec.tangible_id(j) := NULL;
                l_payment_rec.ship_from_org_id(j) := l_header_rec.ship_from_org_id(i);
                l_payment_rec.paid_at_store_id(j) := g_payment_rec.paid_at_store_id(l_idx);

                l_payment_rec.attribute3(j) := g_payment_rec.attribute13(l_idx);
                l_payment_rec.attribute14(j) := g_payment_rec.attribute14(l_idx);
                oe_debug_pub.ADD(   'after setting the l_payment_rec :'
                                 || j);
                j :=   j
                     + 1;

                <<end_of_rec>>
                l_idx :=   l_idx
                         + 1;
            END LOOP;                                                                   -- Loop over the deposit records

            <<end_of_dep_loop>>
            -- If payment records are found then create receipt and insert the records in oe_payments table.
            IF l_payment_rec.header_id.COUNT > 0
            THEN
                oe_debug_pub.ADD('Need to create payment records :');
                xx_om_sales_acct_pkg.create_receipt_payment(p_payment_rec        => l_payment_rec,
                                                            p_request_id         => g_request_id,
                                                            p_run_mode           => 'HVOP',
                                                            x_return_status      => lc_return_status);
                oe_debug_pub.ADD(   'after calling Create_Receipt_payment :'
                                 || lc_return_status);

                IF lc_return_status <> fnd_api.g_ret_sts_success
                THEN
                    set_msg_context(p_entity_code      => 'HEADER');
                    oe_debug_pub.ADD(   'Failed creating receipt and payment records '
                                     || l_header_rec.header_id(i));
                    fnd_message.set_name('XXOM',
                                         'XX_OM_FAILED_TO_CREATE_RECEIPT');
                    fnd_message.set_token('ATTRIBUTE1',
                                          l_header_rec.order_number(i));
                    oe_bulk_msg_pub.ADD;
                    RAISE fnd_api.g_exc_error;
                END IF;
            END IF;

            -- Now Remove the hold on the order
            l_hold_source_rec.hold_source_id := l_header_rec.hold_source_id(i);
            l_hold_source_rec.hold_id := l_header_rec.hold_id(i);
            l_hold_source_rec.header_id := l_header_rec.header_id(i);
            l_hold_release_rec.release_reason_code := 'PREPAYMENT';
            l_hold_release_rec.release_comment := 'XX_OM_HVOP_DEPOSIT_CONC_PKG: Deposit received, removing the hold';
            l_hold_release_rec.hold_source_id := l_header_rec.hold_source_id(i);
            l_hold_release_rec.order_hold_id := l_header_rec.order_hold_id(i);
            oe_debug_pub.ADD(   'before calling Release_Holds :'
                             || lc_return_status);
            oe_holds_pub.release_holds(p_hold_source_rec       => l_hold_source_rec,
                                       p_hold_release_rec      => l_hold_release_rec,
                                       x_return_status         => lc_return_status,
                                       x_msg_count             => ln_msg_count,
                                       x_msg_data              => lc_msg_data);
            oe_debug_pub.ADD(   'after calling Release_Holds :'
                             || lc_return_status);

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                set_msg_context(p_entity_code      => 'HEADER');
                oe_debug_pub.ADD(   'Failed to release hold '
                                 || l_header_rec.header_id(i));
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_TO_RELEASE_HOLD');
                fnd_message.set_token('ATTRIBUTE1',
                                      l_header_rec.order_number(i));
                oe_bulk_msg_pub.ADD;
                GOTO end_of_loop;
            END IF;

            -- Book the order so that it flows through the Invoice Interface
            oe_debug_pub.ADD(   'Before calling Book Order :'
                             || lc_return_status);
            oe_order_book_util.complete_book_eligible(p_api_version_number      => 1.0,
                                                      p_init_msg_list           => fnd_api.g_false,
                                                      p_header_id               => l_header_rec.header_id(i),
                                                      x_return_status           => lc_return_status,
                                                      x_msg_count               => ln_msg_count,
                                                      x_msg_data                => lc_msg_data);
            oe_debug_pub.ADD(   'after calling Book Order :'
                             || lc_return_status);

            IF lc_return_status = fnd_api.g_ret_sts_success
            THEN
                into_recpt_tbl_for_postpay(p_header_id          => l_header_rec.header_id(i),
                                           x_return_status      => lc_return_status);

                IF lc_return_status <> fnd_api.g_ret_sts_success
                THEN
                    oe_debug_pub.ADD(   'Failed to Insert Into XX_AR_ORDER_RECEIPT_DTL TABLE for header_id '
                                     || l_header_rec.header_id(i));
                END IF;
            END IF;

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                set_msg_context(p_entity_code      => 'HEADER');
                oe_debug_pub.ADD(   'Failed to Book the order '
                                 || l_header_rec.header_id(i));
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_TO_BOOK');
                fnd_message.set_token('ATTRIBUTE1',
                                      l_header_rec.order_number(i));
                oe_bulk_msg_pub.ADD;
            END IF;

            <<end_of_loop>>
            oe_debug_pub.ADD(   'End OF Loop:'
                             || lc_return_status);
        END LOOP;                                                                                    -- loop over orders

        <<end_of_header>>
        oe_debug_pub.ADD('Exiting  Check_PostPayment:');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in Check_PostPayment No Data Found'
                              || l_orig_sys_document_ref);
            fnd_file.put_line(fnd_file.LOG,
                                 'NO DATA FOUND : '
                              || SQLERRM);
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in Check_PostPayment '
                              || l_orig_sys_document_ref);
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            RAISE fnd_api.g_exc_error;
    END check_postpayment;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                   Office Depot                                    |
-- +===================================================================+
-- | Name  : apply_payment_to_prepay                                   |
-- | Description      : This Procedure will get all deposits and see   |
-- |                    if it as Pending deposit hold if so it apply   |
-- |                    payments aganist a receipt amount and release  |
-- |                    hold aganist the order                         |
-- +===================================================================+
    PROCEDURE apply_payment_to_prepay(
        p_orig_sys_document_ref  IN      VARCHAR2,
        x_return_status          OUT     VARCHAR2)
    IS
        CURSOR c_deposits(
            p_osd_ref       IN  VARCHAR2,
            p_invoicing_on  IN  VARCHAR2)
        IS
            SELECT     NVL(d.orig_sys_document_ref,
                           dt.orig_sys_document_ref) orig_sys_document_ref,
                       dt.order_source_id,
                       payment_type_code,
                       receipt_method_id,
                       payment_set_id,
                       orig_sys_payment_ref,
                       avail_balance,
                       credit_card_number,
                       credit_card_expiration_date,
                       credit_card_code,
                       credit_card_approval_code,
                       credit_card_approval_date,
                       check_number,
                       cc_auth_manual,
                       merchant_number,
                       cc_auth_ps2000,
                       allied_ind,
                       cc_mask_number,
                       od_payment_type,
                       credit_card_holder_name,
                       cash_receipt_id,
                       debit_card_approval_ref,
                       cc_entry_mode,
                       cvv_resp_code,
                       avs_resp_code,
                       auth_entry_mode,
                       d.single_pay_ind,
                       d.transaction_number,
                       d.token_flag,
                       d.emv_card,
                       d.emv_terminal,
                       d.emv_transaction,
                       d.emv_offline,
                       d.emv_fallback,
                       d.emv_tvr
            FROM       xx_om_legacy_deposits d,
                       xx_om_legacy_dep_dtls dt
            WHERE      --NVL(d.orig_sys_document_ref,dt.orig_sys_document_ref) = p_osd_ref commented for 39886
						(d.orig_sys_document_ref = p_osd_ref OR  (d.orig_sys_document_ref  is NULL AND dt.orig_sys_document_ref = p_osd_ref)) --added for 39886
            AND        d.avail_balance > 0
            AND        d.i1025_status <> 'CANCELLED'
            AND        NVL(error_flag,
                           'N') = 'N'
            AND        cash_receipt_id IS NOT NULL
            --AND (cash_receipt_id is NOT NULL OR 'N' = 'N' OR od_payment_type = 'AB')
            AND        d.transaction_number = dt.transaction_number
            ORDER BY   avail_balance
            FOR UPDATE;

/* Variable Declaration */
        i                         BINARY_INTEGER                            := 0;
        j                         BINARY_INTEGER                            := 0;
        ln_debug_level   CONSTANT NUMBER                                    := oe_debug_pub.g_debug_level;
        lc_orig_sys_ref           VARCHAR2(30);
        ln_dep_count              BINARY_INTEGER;
        ln_deposit_amt            NUMBER;
        ln_payment_amt            NUMBER;
        ln_avail_balance          NUMBER;
        ln_msg_count              NUMBER;
        lc_msg_data               VARCHAR2(4000);
        lc_return_status          VARCHAR2(1);
        lb_put_on_hold            BOOLEAN;
        lc_hold_comments          VARCHAR2(1000);
        ln_payment_set_id         NUMBER;
        lc_invoicing_on           VARCHAR2(1)                      := oe_sys_parameters.VALUE('XX_OM_INVOICING_ON',
                                                                                              404);
        ln_header_id              NUMBER;
        lc_orig_sys_document_ref  VARCHAR2(80);
        ln_order_source_id        NUMBER;
        ln_hold_id                NUMBER;
        ln_hold_source_id         NUMBER;
        ln_order_hold_id          NUMBER;
        ln_sold_to_org_id         NUMBER;
        g_payment_rec             xx_om_sacct_conc_pkg.g_payment_rec%TYPE;
        l_hold_source_rec         oe_holds_pvt.hold_source_rec_type;
        l_hold_release_rec        oe_holds_pvt.hold_release_rec_type;
        l_header_rec              xx_om_sacct_conc_pkg.header_match_rec;
        ln_request_id             NUMBER                                    := -1;
        ln_end_time               NUMBER;
        ln_start_time             NUMBER;
        ln_receipt_count          NUMBER;
    BEGIN
        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        fnd_file.put_line(fnd_file.LOG,
                          'Begnining of reapply deposit prepayment for single payment');
        fnd_profile.get('CONC_REQUEST_ID',
                        ln_request_id);

        IF LENGTH(p_orig_sys_document_ref) > 12
        THEN
            lc_orig_sys_ref := p_orig_sys_document_ref;
        ELSE
            lc_orig_sys_ref :=    SUBSTR(p_orig_sys_document_ref,
                                         1,
                                         9)
                               || '001';
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                             'lc_orig_sys_ref :::'
                          || lc_orig_sys_ref);

        SELECT COUNT(*)
        INTO   ln_receipt_count
        FROM   xx_om_legacy_deposits d,
               xx_om_legacy_dep_dtls dt
        WHERE  --NVL(d.orig_sys_document_ref,  dt.orig_sys_document_ref) = lc_orig_sys_ref  --Rajesh 39886
		
				(     d.orig_sys_document_ref = lc_orig_sys_ref  OR  (d.orig_sys_document_ref IS NULL AND dt.orig_sys_document_ref = lc_orig_sys_ref )) --Added for 39886
        AND    d.transaction_number = dt.transaction_number
        AND    d.cash_receipt_id IS NULL;

        IF ln_receipt_count = 0
        THEN
            SELECT h.header_id,
                   h.orig_sys_document_ref,
                   h.order_source_id,
                   h.sold_to_org_id,
                   hs.hold_id,
                   hs.hold_source_id,
                   oh.order_hold_id
            INTO   ln_header_id,
                   lc_orig_sys_document_ref,
                   ln_order_source_id,
                   ln_sold_to_org_id,
                   ln_hold_id,
                   ln_hold_source_id,
                   ln_order_hold_id
            FROM   oe_order_headers_all h,
                   oe_order_holds oh,
                   oe_hold_sources hs,
                   oe_hold_definitions hd
            WHERE  h.orig_sys_document_ref = p_orig_sys_document_ref
            AND    h.header_id = oh.header_id
            AND    oh.hold_release_id IS NULL
            AND    oh.hold_source_id = hs.hold_source_id
            AND    hs.hold_id = hd.hold_id
            AND    hd.NAME = 'OD: SAS Pending deposit hold';

            SAVEPOINT process_deposit;

            -- Get the order total paid by deposit
            SELECT order_total
            INTO   ln_deposit_amt
            FROM   xx_om_header_attributes_all
            WHERE  header_id = ln_header_id;

            ln_payment_amt := ln_deposit_amt;
            -- Set the counter for Payment Number counter
            j := 0;

            FOR c1 IN c_deposits(lc_orig_sys_ref,
                                 lc_invoicing_on)
            LOOP
                fnd_file.put_line(fnd_file.LOG,
                                     'INSIDE C1 CURSOR LOOP :::'
                                  || i);
                i :=   i
                     + 1;
                j :=   j
                     + 1;
                g_payment_rec.header_id(i) := NULL;
                -- G_payment_rec.request_id(i)                  := NULL;
                g_payment_rec.payment_type_code(i) := NULL;
                g_payment_rec.credit_card_code(i) := NULL;
                g_payment_rec.credit_card_number(i) := NULL;
                g_payment_rec.credit_card_holder_name(i) := NULL;
                g_payment_rec.credit_card_expiration_date(i) := NULL;
                g_payment_rec.prepaid_amount(i) := NULL;
                g_payment_rec.payment_set_id(i) := NULL;
                g_payment_rec.receipt_method_id(i) := NULL;
                g_payment_rec.credit_card_approval_code(i) := NULL;
                g_payment_rec.credit_card_approval_date(i) := NULL;
                g_payment_rec.check_number(i) := NULL;
                g_payment_rec.payment_amount(i) := NULL;
                g_payment_rec.payment_number(i) := NULL;
                g_payment_rec.orig_sys_payment_ref(i) := NULL;
                g_payment_rec.CONTEXT(i) := NULL;
                g_payment_rec.attribute6(i) := NULL;
                g_payment_rec.attribute7(i) := NULL;
                g_payment_rec.attribute8(i) := NULL;
                g_payment_rec.attribute9(i) := NULL;
                g_payment_rec.attribute10(i) := NULL;
                g_payment_rec.attribute11(i) := NULL;
                g_payment_rec.attribute12(i) := NULL;
                g_payment_rec.attribute13(i) := NULL;
                g_payment_rec.attribute15(i) := NULL;
                g_payment_rec.orig_sys_document_ref(i) := NULL;
                g_payment_rec.tangible_id(i) := NULL;

                g_payment_rec.attribute3(i) := NULL;
                g_payment_rec.attribute14(i) := NULL;

                IF ln_deposit_amt <= c1.avail_balance
                THEN
                    g_payment_rec.prepaid_amount(i) := ln_deposit_amt;
                    -- Order Total is matched by the availbale balance
                    ln_avail_balance :=   c1.avail_balance
                                        - ln_deposit_amt;
                    ln_deposit_amt := 0;
                ELSE
                    g_payment_rec.prepaid_amount(i) := c1.avail_balance;
                    -- Set the remaining balance
                    ln_deposit_amt :=   ln_deposit_amt
                                      - c1.avail_balance;
                    ln_avail_balance := 0;
                END IF;

                fnd_file.put_line(fnd_file.LOG,
                                  'Calling XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment ::');
                -- Call this API only if INVOICING is ON
                --IF lc_invoicing_on = 'Y' THEN
                xx_ar_prepayments_pkg.reapply_deposit_prepayment(p_init_msg_list         => fnd_api.g_false,
                                                                 p_commit                => fnd_api.g_false,
                                                                 p_validation_level      => fnd_api.g_valid_level_full,
                                                                 p_cash_receipt_id       => c1.cash_receipt_id,
                                                                 p_header_id             => ln_header_id,
                                                                 p_order_number          => p_orig_sys_document_ref,
                                                                 p_apply_amount          => g_payment_rec.prepaid_amount
                                                                                                                      (i),
                                                                 x_payment_set_id        => ln_payment_set_id,
                                                                 x_return_status         => lc_return_status,
                                                                 x_msg_count             => ln_msg_count,
                                                                 x_msg_data              => lc_msg_data);
                fnd_file.put_line(fnd_file.LOG,
                                     'ln_payment_set_id ::'
                                  || ln_payment_set_id);
                g_payment_rec.header_id(i) := ln_header_id;
                --G_payment_rec.request_id(i)                  := -1; --p_request_id;
                g_payment_rec.payment_type_code(i) := c1.payment_type_code;
                g_payment_rec.credit_card_code(i) := c1.credit_card_code;
                g_payment_rec.credit_card_number(i) := c1.credit_card_number;
                g_payment_rec.credit_card_holder_name(i) := c1.credit_card_holder_name;
                g_payment_rec.credit_card_expiration_date(i) := c1.credit_card_expiration_date;
                g_payment_rec.prepaid_amount(i) := ln_payment_amt;
                g_payment_rec.payment_set_id(i) := ln_payment_set_id;
                g_payment_rec.receipt_method_id(i) := c1.receipt_method_id;
                g_payment_rec.credit_card_approval_code(i) := c1.credit_card_approval_code;
                g_payment_rec.credit_card_approval_date(i) := c1.credit_card_approval_date;
                g_payment_rec.check_number(i) := c1.check_number;
                g_payment_rec.payment_amount(i) := ln_payment_amt;
                g_payment_rec.payment_number(i) := j;
                g_payment_rec.orig_sys_payment_ref(i) := c1.orig_sys_payment_ref;
                g_payment_rec.CONTEXT(i) := 'SALES_ACCT_HVOP';
                g_payment_rec.attribute6(i) := c1.cc_auth_manual;
                g_payment_rec.attribute7(i) := c1.merchant_number;
                g_payment_rec.attribute8(i) := c1.cc_auth_ps2000;
                g_payment_rec.attribute9(i) := c1.allied_ind;
                g_payment_rec.attribute10(i) := c1.cc_mask_number;
                g_payment_rec.attribute11(i) := c1.od_payment_type;
                g_payment_rec.attribute12(i) := c1.debit_card_approval_ref;
                g_payment_rec.attribute13(i) :=
                       c1.cc_entry_mode
                    || ':'
                    || c1.cvv_resp_code
                    || ':'
                    || c1.avs_resp_code
                    || ':'
                    || c1.auth_entry_mode
                    || ':'
                    || c1.single_pay_ind;
                g_payment_rec.attribute15(i) := c1.cash_receipt_id;
                g_payment_rec.orig_sys_document_ref(i) := lc_orig_sys_document_ref;

                g_payment_rec.attribute3(i)  := c1.token_flag;
                g_payment_rec.attribute14(i) := c1.emv_card||'.'||c1.emv_terminal||'.'||c1.emv_transaction||'.'||
                                                c1.emv_offline||'.'||c1.emv_fallback||'.'||c1.emv_tvr;

                IF lc_return_status = fnd_api.g_ret_sts_success OR ln_payment_set_id IS NOT NULL
                THEN
                    -- Now Remove the hold on the order
                    l_hold_source_rec.hold_source_id := ln_hold_source_id;
                    l_hold_source_rec.hold_id := ln_hold_id;
                    l_hold_source_rec.header_id := ln_header_id;
                    l_hold_release_rec.release_reason_code := 'PREPAYMENT';
                    l_hold_release_rec.release_comment := 'Single Payment Hold: Deposit received, removing the hold';
                    l_hold_release_rec.hold_source_id := ln_hold_source_id;
                    l_hold_release_rec.order_hold_id := ln_order_hold_id;
                    oe_holds_pub.release_holds(p_hold_source_rec       => l_hold_source_rec,
                                               p_hold_release_rec      => l_hold_release_rec,
                                               x_return_status         => lc_return_status,
                                               x_msg_count             => ln_msg_count,
                                               x_msg_data              => lc_msg_data);

                    IF lc_return_status <> fnd_api.g_ret_sts_success
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'unable to release hold for header id : '
                                          || l_hold_source_rec.header_id);
                    END IF;

                    UPDATE xx_om_legacy_deposits
                    SET avail_balance = ln_avail_balance,
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_global.user_id
                    WHERE  cash_receipt_id = c1.cash_receipt_id;

                    fnd_file.put_line(fnd_file.LOG,
                                         'ln_avail_balance '
                                      || ln_avail_balance);
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                      'Not able to unapply prepayment receipt ');
                    fnd_file.put_line(fnd_file.LOG,
                                         'lc_return_status :::'
                                      || lc_return_status);
                    fnd_file.put_line(fnd_file.LOG,
                                         'lc_msg_data :::'
                                      || lc_msg_data);
                    fnd_file.put_line(fnd_file.LOG,
                                         'ln_payment_set_id :::'
                                      || g_payment_rec.payment_set_id(i));
                    fnd_file.put_line(fnd_file.LOG,
                                         'orig_sys_document_ref :::'
                                      || g_payment_rec.orig_sys_document_ref(i));
                END IF;

                -- END IF;
                x_return_status := lc_return_status;
            END LOOP;

            BEGIN
                fnd_file.put_line(fnd_file.LOG,
                                     'first :::'
                                  || g_payment_rec.payment_number.FIRST);
                fnd_file.put_line(fnd_file.LOG,
                                     'last :::'
                                  || g_payment_rec.payment_number.LAST);
                FORALL i_pay IN g_payment_rec.payment_number.FIRST .. g_payment_rec.payment_number.LAST
                    INSERT INTO oe_payments
                                (payment_level_code,
                                 header_id,
                                 creation_date,
                                 created_by,
                                 last_update_date,
                                 last_updated_by,
                                 request_id,
                                 payment_type_code,
                                 credit_card_code,
                                 credit_card_number,
                                 credit_card_holder_name,
                                 credit_card_expiration_date,
                                 prepaid_amount,
                                 payment_set_id,
                                 receipt_method_id,
                                 payment_collection_event,
                                 credit_card_approval_code,
                                 credit_card_approval_date,
                                 check_number,
                                 payment_amount,
                                 payment_number,
                                 lock_control,
                                 orig_sys_payment_ref,
                                 CONTEXT,
                                 attribute6,
                                 attribute7,
                                 attribute8,
                                 attribute9,
                                 attribute10,
                                 attribute11,
                                 attribute12,
                                 attribute13,
                                 attribute15,
                                 tangible_id,
                                 attribute3,
                                 attribute14)
                         VALUES ('ORDER',
                                 g_payment_rec.header_id(i_pay),
                                 SYSDATE,
                                 fnd_global.user_id,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 ln_request_id,
                                 g_payment_rec.payment_type_code(i_pay),
                                 g_payment_rec.credit_card_code(i_pay),
                                 g_payment_rec.credit_card_number(i_pay),
                                 g_payment_rec.credit_card_holder_name(i_pay),
                                 g_payment_rec.credit_card_expiration_date(i_pay),
                                 g_payment_rec.payment_amount(i_pay),
                                 g_payment_rec.payment_set_id(i_pay),
                                 g_payment_rec.receipt_method_id(i_pay),
                                 'PREPAY',
                                 g_payment_rec.credit_card_approval_code(i_pay),
                                 g_payment_rec.credit_card_approval_date(i_pay),
                                 g_payment_rec.check_number(i_pay),
                                 g_payment_rec.payment_amount(i_pay),
                                 g_payment_rec.payment_number(i_pay),
                                 1,
                                 g_payment_rec.orig_sys_payment_ref(i_pay),
                                 g_payment_rec.CONTEXT(i_pay),
                                 g_payment_rec.attribute6(i_pay),
                                 g_payment_rec.attribute7(i_pay),
                                 g_payment_rec.attribute8(i_pay),
                                 g_payment_rec.attribute9(i_pay),
                                 g_payment_rec.attribute10(i_pay),
                                 g_payment_rec.attribute11(i_pay),
                                 g_payment_rec.attribute12(i_pay),
                                 g_payment_rec.attribute13(i_pay),
                                 g_payment_rec.attribute15(i_pay),
                                 g_payment_rec.tangible_id(i_pay),
                                 g_payment_rec.attribute3(i_pay),
                                 g_payment_rec.attribute14(i_pay)
                                );




                fnd_file.put_line(fnd_file.LOG,
                                     'Total Number of orders unapplied : '
                                  || TO_CHAR(SQL%ROWCOUNT));

                SELECT hsecs
                INTO   ln_end_time
                FROM   v$timer;

                fnd_file.put_line(fnd_file.LOG,
                                     'Time spent in load_to_settlement is (sec) '
                                  || (  (  ln_end_time
                                         - ln_start_time)
                                      / 100));
                DBMS_OUTPUT.put_line(   'Time spent in load_to_settlement is (sec) '
                                     || (  (  ln_end_time
                                            - ln_start_time)
                                         / 100));
                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'When Others in bulk insert  : '
                                      || SQLERRM);
                    ROLLBACK TO SAVEPOINT process_deposit;
            END;

            -- Book the order so that it flows through the Invoice Interface
            oe_debug_pub.ADD(   'Before calling Book Order :'
                             || lc_return_status);
            oe_order_book_util.complete_book_eligible(p_api_version_number      => 1.0,
                                                      p_init_msg_list           => fnd_api.g_false,
                                                      p_header_id               => ln_header_id,
                                                      x_return_status           => lc_return_status,
                                                      x_msg_count               => ln_msg_count,
                                                      x_msg_data                => lc_msg_data);
            x_return_status := lc_return_status;

            --COMMIT;
            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_TO_BOOK');
                fnd_message.set_token('ATTRIBUTE1',
                                      p_orig_sys_document_ref);
            END IF;
        ELSE
            fnd_file.put_line(fnd_file.LOG,
                              'All Receipts are not processed Yet ');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'NO Data Found');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'When Others in apply_payment_to_prepay : '
                              || SQLERRM);
            ROLLBACK TO SAVEPOINT process_deposit;
    END apply_payment_to_prepay;

    PROCEDURE into_recpt_tbl_for_postpay(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                   Office Depot                                    |
-- +===================================================================+
-- | Name  : Check_PostPayment                                         |
-- | Description      : This Procedure will insert into xx_ar_order_   |
-- |                    receipt_dtl table for all post_payment non     |
-- |                     single payments for each order number         |
-- +===================================================================+
        CURSOR c_order(
            p_header_id  IN  NUMBER)
        IS
            SELECT xxfin.xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   ooh.order_number order_number,
                   ooh.orig_sys_document_ref orig_sys_document_ref,
                   ooh.header_id header_id,
                   ooh.transactional_curr_code currency_code,
                   oos.NAME order_source,
                   ott.NAME order_type,
                   ooh.sold_to_org_id customer_id,
                   LPAD(aou.attribute1,
                        6,
                        '0') store_num,
                   ooh.org_id org_id,
                   ooh.request_id request_id,
                   xoh.imp_file_name imp_file_name,
                   SYSDATE creation_date,
                   ooh.created_by created_by,
                   SYSDATE last_update_date,
                   ooh.created_by last_updated_by,
                   oop.payment_number payment_number,
                   oop.orig_sys_payment_ref orig_sys_payment_ref,
                   oop.payment_type_code payment_type_code,
                   flv.meaning cc_code,
                   oop.credit_card_number cc_number,
                   oop.credit_card_holder_name cc_name,
                   oop.credit_card_expiration_date cc_exp_date,
                   oop.payment_amount payment_amount,
                   oop.receipt_method_id receipt_method_id,
                   oop.check_number check_number,
                   oop.attribute6 cc_auth_manual,
                   oop.attribute7 merchant_nbr,
                   oop.attribute8 cc_auth_ps2000,
                   oop.attribute9 allied_ind,
                   oop.attribute10 cc_mask_number,
                   oop.attribute11 od_payment_type,
                   oop.attribute15 cash_receipt_id,
                   oop.payment_set_id payment_set_id,
                   'HVOP' process_code,
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   (SELECT LPAD(attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units a
                    WHERE  a.organization_id = NVL(xoh.paid_at_store_id,
                                                   ship_from_org_id)) ship_from,
                   oop.credit_card_approval_code credit_card_approval_code,
                   oop.credit_card_approval_date credit_card_approval_date,
                   ooh.invoice_to_org_id customer_site_billto_id,
                   TRUNC(ooh.ordered_date) receipt_date,
                   'SALE' sale_type,
                   oop.attribute13 additional_auth_codes,
                   xfh.process_date process_date,
                   oop.attribute3 token_flag,
                   oop.attribute14 emv_details
            FROM   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   oe_transaction_types_tl ott,
                   xx_om_header_attributes_all xoh,
                   xx_om_sacct_file_history xfh,
                   hr_all_organization_units aou,
                   oe_payments oop,
                   fnd_lookup_values flv
            WHERE  ooh.order_source_id = oos.order_source_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    ott.LANGUAGE = USERENV('LANG')
            AND    ooh.header_id = xoh.header_id
            AND    xoh.imp_file_name = xfh.file_name
            AND    ooh.ship_from_org_id = aou.organization_id
            AND    ooh.header_id = oop.header_id
            AND    oop.attribute11 = flv.lookup_code
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'
            AND    ooh.header_id = p_header_id;

        lc_receipt_number           VARCHAR2(80);
        lc_receipt_status           VARCHAR2(30);
        lc_customer_receipt_number  VARCHAR2(80);
        lc_tender_type              VARCHAR2(80);
        ld_cleared_date             DATE;
        lc_tender_type              VARCHAR2(80);
        ln_debug_level     CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_error_message            VARCHAR2(2000);
        lb_settlement_staged        BOOLEAN        := FALSE;
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;

        FOR r_order IN c_order(p_header_id)
        LOOP
            IF r_order.cash_receipt_id IS NOT NULL
            THEN
                SELECT receipt_number
                INTO   lc_receipt_number
                FROM   ar_cash_receipts_all
                WHERE  cash_receipt_id = r_order.cash_receipt_id;
            ELSE
                lc_receipt_number := NULL;
                r_order.cash_receipt_id := -3;
            END IF;

            IF r_order.cc_code = 'DEBIT CARD'
            THEN
                lc_customer_receipt_number :=
                    xx_om_sales_acct_pkg.format_debit_card(r_order.orig_sys_document_ref,
                                                           r_order.cc_mask_number,
                                                           r_order.payment_amount);
            ELSIF r_order.cc_code = 'TELECHECK ECA'
            THEN
                lc_customer_receipt_number :=
                          SUBSTR(r_order.orig_sys_document_ref,
                                 1,
                                 12)
                       || '00'
                       || SUBSTR(r_order.orig_sys_document_ref,
                                 13);
            ELSE
                lc_customer_receipt_number := r_order.orig_sys_document_ref;
            END IF;

            IF r_order.cc_code IN
                        ('DEBIT CARD', 'TELECHECK ECA', 'CASH', 'TELECHECK PAPER', 'GIFT CERTIFICATE', 'OD MONEY CARD2','OD MONEY CARD3')
            THEN
                r_order.remitted := 'Y';
            ELSE
                r_order.remitted := 'N';
            END IF;

            lc_receipt_status := r_order.receipt_status;

            IF r_order.cc_code IN('CASH', 'TELECHECK PAPER', 'GIFT CERTIFICATE', 'OD MONEY CARD2','OD MONEY CARD3')
            THEN
                r_order.MATCHED := 'Y';
                lc_receipt_status := 'CLEARED';
                ld_cleared_date := SYSDATE;
            ELSE
                r_order.MATCHED := 'N';
                lc_receipt_status := 'OPEN';
                ld_cleared_date := NULL;
            END IF;

            INSERT INTO xx_ar_order_receipt_dtl
                        (order_payment_id,
                         order_number,
                         orig_sys_document_ref,
                         header_id,
                         order_source,
                         order_type,
                         customer_id,
                         store_number,
                         org_id,
                         request_id,
                         imp_file_name,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         payment_number,
                         orig_sys_payment_ref,
                         payment_type_code,
                         credit_card_code,
                         credit_card_number,
                         credit_card_holder_name,
                         credit_card_expiration_date,
                         payment_amount,
                         receipt_method_id,
                         check_number,
                         cc_auth_manual,
                         merchant_number,
                         cc_auth_ps2000,
                         allied_ind,
                         cc_mask_number,
                         od_payment_type,
                         cash_receipt_id,
                         payment_set_id,
                         process_code,
                         remitted,
                         MATCHED,
                         receipt_status,
                         ship_from,
                         customer_receipt_reference,
                         receipt_number,
                         credit_card_approval_code,
                         credit_card_approval_date,
                         customer_site_billto_id,
                         receipt_date,
                         sale_type,
                         additional_auth_codes,
                         process_date,
                         currency_code,
                         single_pay_ind,
                         last_update_login,
                         token_flag,
                         emv_card,
                         emv_terminal,
                         emv_transaction,
                         emv_offline,
                         emv_fallback,
                         emv_tvr
                         )
                 VALUES (r_order.order_payment_id,
                         r_order.order_number,
                         r_order.orig_sys_document_ref,
                         r_order.header_id,
                         r_order.order_source,
                         r_order.order_type,
                         r_order.customer_id,
                         r_order.store_num,
                         r_order.org_id,
                         r_order.request_id,
                         r_order.imp_file_name,
                         r_order.creation_date,
                         r_order.created_by,
                         r_order.last_update_date,
                         r_order.last_updated_by,
                         r_order.payment_number,
                         r_order.orig_sys_payment_ref,
                         r_order.payment_type_code,
                         r_order.cc_code,
                         r_order.cc_number,
                         r_order.cc_name,
                         r_order.cc_exp_date,
                         r_order.payment_amount,
                         r_order.receipt_method_id,
                         r_order.check_number,
                         r_order.cc_auth_manual,
                         r_order.merchant_nbr,
                         r_order.cc_auth_ps2000,
                         r_order.allied_ind,
                         r_order.cc_mask_number,
                         r_order.od_payment_type,
                         r_order.cash_receipt_id,
                         r_order.payment_set_id,
                         r_order.process_code,
                         r_order.remitted,
                         r_order.MATCHED,
                         lc_receipt_status,
                         r_order.ship_from,
                         lc_customer_receipt_number,
                         lc_receipt_number,
                         r_order.credit_card_approval_code,
                         r_order.credit_card_approval_date,
                         r_order.customer_site_billto_id,
                         r_order.receipt_date,
                         r_order.sale_type,
                         r_order.additional_auth_codes,
                         r_order.process_date,
                         r_order.currency_code,
                         NULL,
                         NULL,
                         NVL(LTRIM(RTRIM(r_order.token_flag)),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(r_order.emv_details, 1,(INSTR(r_order.emv_details,'.',1,1)-1)))),'N'),
                         SUBSTR(r_order.emv_details, 3,(INSTR(r_order.emv_details,'.',1,1))),
                         NVL(LTRIM(RTRIM(SUBSTR(r_order.emv_details, 6,(INSTR(r_order.emv_details,'.',1,1)-1)))),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(r_order.emv_details, 8,(INSTR(r_order.emv_details,'.',1,1)-1)))),'N'),
                         NVL(LTRIM(RTRIM(SUBSTR(r_order.emv_details, 10,(INSTR(r_order.emv_details,'.',1,1)-1)))),'N'),
                         LTRIM(RTRIM(SUBSTR(r_order.emv_details,12,10)))
                        );

            x_return_status := fnd_api.g_ret_sts_success;
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'No Data Found Raised in insert_into_recpt_tbl:::');

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('No Data Found Raised in insert_into_recpt_tbl:::');
            END IF;
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            fnd_file.put_line(fnd_file.LOG,
                                 ' Others Raised in insert_into_recpt_tbl:::'
                              || SQLERRM);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Others Raised in insert_into_recpt_tbl:::'
                                 || SUBSTR(SQLERRM,
                                           1,
                                           240));
            END IF;
    END into_recpt_tbl_for_postpay;
END xx_om_hvop_deposit_conc_pkg;
/
