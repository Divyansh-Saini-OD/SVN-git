create or replace PACKAGE BODY xx_vps_ar_refunds_pkg
AS 
-- =========================================================================================================================
--   NAME:       XX_VPS_AR_REFUNDS_PKG .
--   PURPOSE:    This package contains procedures and functions for the
--                VPS AR Automated Refund process.
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        08/01/2017  Uday Jadhav      1. Created this package. 
--   1.1        01/09/2018  Theja Rajula     2. Add Default CCID to AP Invoices Header
--   1.2        03/01/2018  Sahithi Kunuru	 3. Changed the logic to derive payment method-defect#44371
-- =========================================================================================================================
    TYPE receipt_writeoff_record IS RECORD(
        receipt_number        VARCHAR2(30),
        receipt_date          VARCHAR2(240),
        store_number          VARCHAR2(100),
        refund_amount         NUMBER,
        currency              VARCHAR2(15),
        account_dr            VARCHAR2(240),
        account_cr            VARCHAR2(240),
        description           VARCHAR2(240)                                                     
                                           ,
        account_seg_dr        VARCHAR2(25)                 
                                          ,
        account_seg_cr        VARCHAR2(25)                                         
                                          ,
        location_dr           VARCHAR2(25)                                          
                                          ,
        location_cr           VARCHAR2(25)                                         
                                          ,
        meaning_debit         VARCHAR2(240)                                                  
                                           ,
        meaning_credit        VARCHAR2(240)                                                    
                                           ,
        location_description  VARCHAR2(240)                                                     
    );

    TYPE receipt_writeoff_type IS TABLE OF receipt_writeoff_record
        INDEX BY BINARY_INTEGER;

    gt_receipt_writeoff      receipt_writeoff_type;
    gn_count                 NUMBER                := 1;
    gn_tot_receipt_writeoff  NUMBER                := 0;
    gn_cust_id               NUMBER;
    gn_check                 NUMBER;
 
    PROCEDURE od_message(
        p_msg_type        IN  VARCHAR2,
        p_msg             IN  VARCHAR2,
        p_msg_loc         IN  VARCHAR2 DEFAULT NULL,
        p_addnl_line_len  IN  NUMBER DEFAULT 110);

    PROCEDURE identify_refund_trx(
        errbuf               OUT NOCOPY     VARCHAR2,
        retcode              OUT NOCOPY     VARCHAR2,
        p_trx_date_from      IN             VARCHAR2,
        p_trx_date_to        IN             VARCHAR2,
        p_amount_from        IN             NUMBER DEFAULT 0.000001,
        p_amount_to          IN             NUMBER DEFAULT 9999999999999, 
        p_process_type       IN             VARCHAR2  ,
        p_only_for_user_id   IN             NUMBER DEFAULT NULL,
        p_org_id             IN             VARCHAR2,
        p_limit_size         IN             NUMBER)                            
    IS 
        CURSOR id_refund_trx_ar                                                     
        IS
            SELECT   SOURCE,
                     customer_id,
                     customer_number,
                     party_name,
                     aops_customer_number,
                     cash_receipt_id,
                     customer_trx_id,
                     trx_id,
                     CLASS,
                     trx_number,
                     trx_date,
                     invoice_currency_code,
                     amount_due_remaining,
                     aps_last_update_date,
                     pre_selected_flag,
                     refund_request,
                     refund_status,
                     org_id,
                     location_id,
                     address1,
                     address2,
                     address3,
                     city,
                     state,
                     province,
                     postal_code,
                     country,
                     om_hold_status,
                     om_delete_status,
                     om_store_number,
                     store_customer_name,
                     ref_mailcheck_id
            FROM     xx_ar_refund_itm
            WHERE    (refund_request like 'RP_%' 
            --OR(refund_request IS NULL AND check_cust = 0)
            )
            ORDER BY customer_id;  

        TYPE idtrxtab IS TABLE OF idtrxrec
            INDEX BY BINARY_INTEGER;

        vidtrxtab               idtrxtab;
        lc_trx_type             VARCHAR2(20);
        ln_refund_header_id     NUMBER;
        ln_id_count             NUMBER;
        ln_ins_count            NUMBER;
        lc_selected_flag        VARCHAR2(1)                        := 'N';
        lc_refund_alt_flag      VARCHAR2(1);
        lc_escheat_flag         VARCHAR2(1);
        lc_approved_flag        VARCHAR2(1);
        lc_write_off_only       VARCHAR2(1);
        lc_activity_type        VARCHAR2(60);
        lc_dff1                 VARCHAR2(30);
        lc_dff2                 VARCHAR2(30);
        ln_primary_bill_loc_id  NUMBER;
        lc_address1             VARCHAR2(240);
        lc_address2             VARCHAR2(240);
        lc_address3             VARCHAR2(240);
        lc_city                 VARCHAR2(60);
        lc_state                VARCHAR2(60);
        lc_province             VARCHAR2(60);
        lc_postal_code          VARCHAR2(60);
        lc_country              VARCHAR2(60);
        ld_date_from            DATE;
        ld_date_to              DATE;
        lc_sob_name             gl_sets_of_books.short_name%TYPE;
        exp_invalid_sob         EXCEPTION;
        ln_refund_tot           NUMBER;
        lc_user_name            fnd_user.user_name%TYPE;
        lc_ident_type           VARCHAR2(30);                                                           
        ln_custcheck_db         NUMBER;                                                     
        ln_escheat_inact_days   NUMBER;                                                      
        ln_refund_inact_days    NUMBER;                                                      
        lc_payment_method_name  VARCHAR2(30);
 
        -- This procedure will populate data in XX_AR_REFUND_ITM. This table will be repopulated for each execution
        PROCEDURE insert_refund_itm(
            lp_date_from          IN  DATE,
            lp_date_to            IN  DATE,
            lp_refund_inact_days  IN  NUMBER)
        IS
            ln_check_cust  NUMBER := 1;
        BEGIN
            
	  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxfin.xx_ar_refund_itm'; 

            INSERT INTO xx_ar_refund_itm
                (SELECT SOURCE,
                        customer_id,
                        NULL                                                                           --customer_number
                            ,
                        NULL                                                                                --party_name
                            ,
                        NULL                                                                      --aops_customer_number
                            ,
                        cash_receipt_id,
                        customer_trx_id,
                        trx_id,
                        CLASS,
                        trx_number,
                        trx_date,
                        invoice_currency_code,
                        amount_due_remaining,
                        aps_last_update_date,
                        pre_selected_flag,
                        refund_request,
                        refund_status,
                        org_id,
                        location_id,
                        address1,
                        address2,
                        address3,
                        city,
                        state,
                        province,
                        postal_code,
                        country,
                        om_hold_status,
                        om_delete_status,
                        om_store_number,
                        store_customer_name,
                        0 ref_mailcheck_id,
                        1                                                                                   --check_cust
                 FROM   xx_ar_open_credits_itm
                 WHERE  org_id = p_org_id
                 AND    (refund_status IS NULL OR refund_status = 'Declined')
                 AND    amount_due_remaining BETWEEN NVL(  -1
                                                         * p_amount_to,
                                                         -9999999999999)
                                                 AND NVL(  -1
                                                         * p_amount_from,
                                                         -0.000001)
                 AND    trx_date BETWEEN NVL(lp_date_from,
                                             trx_date) AND NVL(lp_date_to,
                                                               trx_date) 
                 AND    cash_receipt_status IN('UNAPP', 'UNID'));
 
            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception in PROCEDURE insert_refund_itm : '
                                  || SQLERRM);
        END insert_refund_itm; 
		
        PROCEDURE open_cursor(
            lp_date_from  IN  DATE,
            lp_date_to    IN  DATE)
        IS
        BEGIN 
                    insert_refund_itm(lp_date_from,
                                      lp_date_to,
                                      ln_refund_inact_days);

                    OPEN id_refund_trx_ar; 
        END;

        PROCEDURE FETCH_RECORDS
        IS
        BEGIN 
                    FETCH id_refund_trx_ar
                    BULK COLLECT INTO vidtrxtab LIMIT p_limit_size; 
        END;

        PROCEDURE close_cursors
        IS
        BEGIN 
            IF (id_refund_trx_ar%ISOPEN)
            THEN
                CLOSE id_refund_trx_ar;
            END IF;
        END;
    BEGIN 
        lc_ident_type := p_process_type;
		ln_id_count := 0;
        ln_ins_count := 0;
        mo_global.set_policy_context('S',
                                     p_org_id);                                          

        BEGIN
            SELECT gsb.short_name
            INTO   lc_sob_name
            FROM   ar_system_parameters asp,
                   gl_sets_of_books gsb
            WHERE  gsb.set_of_books_id = asp.set_of_books_id AND gsb.short_name ='US_USD_P';
        EXCEPTION
            WHEN OTHERS
            THEN
                od_message('O',
                           'Set of Books not found!');
                od_message('M',
                           'Set of Books not found!');
                RAISE;
        END;

        od_message('O',
                   ' ');
        od_message('O',
                   'Parameters: ');
        od_message('O',
                   '----------- ');
        od_message('O',
                   ' '); 

        IF p_amount_from IS NOT NULL OR p_amount_to IS NOT NULL
        THEN
            od_message('O',
                          '   Transaction Amounts between :'
                       || p_amount_from
                       || ' and '
                       || p_amount_to);
        END IF;

        IF p_trx_date_from IS NOT NULL
        THEN
            ld_date_from := fnd_conc_date.string_to_date(p_trx_date_from);
        END IF;

        IF p_trx_date_to IS NOT NULL
        THEN
            ld_date_to := fnd_conc_date.string_to_date(p_trx_date_to);
            od_message('O',
                          '   Transactions between :'
                       || ld_date_from
                       || ' and '
                       || ld_date_to);
        END IF; 
        od_message('O',
                   ' ');
        od_message('O',
                   g_print_line);
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        -- based on the parameters, open the corresponding cursor
        open_cursor(lp_date_from      => ld_date_from,
                    lp_date_to        => ld_date_to);

        LOOP
            -- fetch next set of records for the related cursor
            fnd_file.put_line(fnd_file.LOG,
                                 'Fetch start'
                              || TO_CHAR(SYSDATE,
                                         'HH24:MI:SS'));
            FETCH_RECORDS();  
            fnd_file.put_line(fnd_file.LOG,
                                 'Fetch end'
                              || TO_CHAR(SYSDATE,
                                         'HH24:MI:SS'));
            EXIT WHEN vidtrxtab.COUNT = 0;
            ln_id_count :=   ln_id_count
                           + vidtrxtab.COUNT;
            od_message('M',
                          'Processing...'
                       || vidtrxtab.COUNT
                       || ' transactions identified...');
            fnd_file.put_line(fnd_file.LOG,
                                 p_process_type
                              || ' '
                             -- || p_no_activity_in
                             -- || ' '
                              || ln_refund_inact_days
                              || ' '
                              || ln_escheat_inact_days);

            IF vidtrxtab.COUNT > 0
            THEN
                FOR i IN vidtrxtab.FIRST .. vidtrxtab.LAST
                LOOP
                    --EXIT WHEN vidtrxtab.COUNT = 0;
                    SELECT xx_refund_header_id_s.NEXTVAL
                    INTO   ln_refund_header_id
                    FROM   DUAL;

                    IF (vidtrxtab(i).customer_id IS NOT NULL)
                    THEN
                        BEGIN
                            SELECT account_number,
                                   party_name,
                                   SUBSTR(hca.orig_system_reference,
                                          1,
                                          8) aops_customer_number                   
                            INTO   vidtrxtab(i).customer_number,
                                   vidtrxtab(i).party_name,
                                   vidtrxtab(i).aops_customer_number                
                            FROM   hz_cust_accounts hca,
                                   hz_parties hp
                            WHERE  hca.party_id = hp.party_id AND hca.cust_account_id = vidtrxtab(i).customer_id;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              'Errors while fetching customer information. '
                                           || SQLERRM);
                        END;
                    ELSE
                        -- if customer is not defined (unidentified), and refunding the customer,
                        --   then through an error message
                        IF (lc_ident_type = 'R')
                        THEN
                            od_message('M',
                                       'Processing a refund for a transaction without a customer.');
                        END IF;
                    END IF;
 
                    IF (vidtrxtab(i).store_customer_name IS NOT NULL)
                    THEN
                        vidtrxtab(i).party_name := vidtrxtab(i).store_customer_name;
                    END IF; 
                    
                            lc_escheat_flag := 'N';
                            lc_selected_flag := 'N';
                            lc_refund_alt_flag := 'N';
                            lc_dff1 := vidtrxtab(i).refund_request;--'Send Refund';  
							
                            -- Get the primary Bill Site for the customer.
                            od_message('M',
                                          'Get primary bill Site for Customer# '
                                       || vidtrxtab(i).customer_number
                                       || ' - '
                                       || vidtrxtab(i).party_name);
                     
                              /*  -- Non-Escheat / Non-OM Refunds. --------    */
                        IF lc_sob_name = 'US_USD_P'
                        THEN
                            IF vidtrxtab(i).CLASS = 'PMT'
                            THEN
                                lc_activity_type := vidtrxtab(i).refund_request; --'VPS_REFUND'; --'US_REC_AUTO MAIL CHK_OD';
                            ELSE
                                lc_activity_type := 'VPS_REFUND'; --'US_CM_AUTO MAIL CHK_OD';
                            END IF; 
                        ELSE
                            RAISE exp_invalid_sob;
                        END IF;                                       

                            IF (vidtrxtab(i).customer_id IS NOT NULL)
                            THEN
                                BEGIN
                                    SELECT hl.location_id,
                                           hl.address1,
                                           hl.address2,
                                           hl.address3,
                                           hl.city,
                                           hl.state,
                                           hl.province,
                                           hl.postal_code,
                                           hl.country
                                    INTO   ln_primary_bill_loc_id,
                                           lc_address1,
                                           lc_address2,
                                           lc_address3,
                                           lc_city,
                                           lc_state,
                                           lc_province,
                                           lc_postal_code,
                                           lc_country
                                    FROM   hz_cust_accounts_all hca,
                                           hz_cust_acct_sites_all hcas,
                                           hz_cust_site_uses_all hcsu,
                                           hz_party_sites hps,
                                           hz_locations hl,
                                           hz_parties party
                                    WHERE  party.party_id = hca.party_id
                                    AND    hca.cust_account_id = hcas.cust_account_id
                                    AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                                    AND    hcas.party_site_id = hps.party_site_id
                                    AND    hl.location_id = hps.location_id
                                    AND    hcas.org_id = vidtrxtab(i).org_id
                                    AND    hcsu.primary_flag = 'Y'
                                    AND    hcsu.site_use_code = 'BILL_TO'
                                    AND    hca.cust_account_id = vidtrxtab(i).customer_id;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            END IF; 
                    BEGIN
                        SELECT arm.NAME
                        INTO   lc_payment_method_name
                        FROM   ar_receipt_methods arm,
                               ar_cash_receipts_all acr
                        WHERE  arm.receipt_method_id = acr.receipt_method_id
                        AND    acr.cash_receipt_id = vidtrxtab(i).trx_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lc_payment_method_name := NULL;
                    END;

                    -- V4.0, end of Payment method derivation
                    BEGIN
                        INSERT INTO xx_ar_refund_trx_tmp
                                    (refund_header_id,
                                     customer_id,
                                     customer_number,
                                     payee_name,
                                     aops_customer_number                          
                                                         ,
                                     trx_id,
                                     trx_type,
                                     trx_number,
                                     trx_currency_code,
                                     refund_amount,
                                     adj_created_flag,
                                     selected_flag,
                                     identification_type,
                                     identification_date,
                                     org_id,
                                     primary_bill_loc_id,
                                     alt_address1,
                                     alt_address2,
                                     alt_address3,
                                     alt_city,
                                     alt_state,
                                     alt_province,
                                     alt_postal_code,
                                     alt_country,
                                     last_update_date,
                                     last_updated_by,
                                     creation_date,
                                     created_by,
                                     last_update_login,
                                     refund_alt_flag,
                                     escheat_flag,
                                     paid_flag,
                                     status,
                                     om_delete_status,
                                     om_hold_status,
                                     om_write_off_only,
                                     om_store_number,
                                     activity_type,
                                     original_activity_type                                     
                                                           ,
                                     account_orig_dr                                            
                                                    ,
                                     account_generic_cr                                        
                                                       ,
                                     payment_method_name                               
                                                        ,
                                     ref_mailcheck_id 
                                                     )
                             VALUES (ln_refund_header_id,
                                     vidtrxtab(i).customer_id,
                                     vidtrxtab(i).customer_number,
                                     vidtrxtab(i).party_name,
                                     vidtrxtab(i).aops_customer_number             
                                                                      ,
                                     vidtrxtab(i).trx_id 
                        ,
                                     DECODE(vidtrxtab(i).CLASS,
                                            'PMT', 'R',
                                            'CM', 'C',
                                            'INV', 'I')                                  
                                                       ,
                                     vidtrxtab(i).trx_number,
                                     vidtrxtab(i).trx_currency_code,
                                       -1
                                     * vidtrxtab(i).refund_amount,
                                     'N',
                                     lc_selected_flag,
                                     lc_ident_type,
                                     SYSDATE,
                                     vidtrxtab(i).org_id,
                                     ln_primary_bill_loc_id,
                                     lc_address1,
                                     lc_address2,
                                     lc_address3,
                                     lc_city,
                                     lc_state,
                                     lc_province,
                                     lc_postal_code,
                                     lc_country,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     fnd_global.login_id,
                                     lc_refund_alt_flag,
                                     lc_escheat_flag,
                                     'N'  ,
                                     'I' ,
                                     vidtrxtab(i).om_delete_status,
                                     vidtrxtab(i).om_hold_status,
                                     NVL(lc_write_off_only,
                                         'N'),
                                     vidtrxtab(i).om_store_number,
                                     lc_activity_type,
                                     NULL,
                                     NULL,
                                     NULL,         
                                      lc_payment_method_name ,
                                     vidtrxtab(i).ref_mailcheck_id                                               
                                                                  );

                        IF vidtrxtab(i).CLASS = 'PMT'
                        THEN
                            UPDATE ar_cash_receipts_all acr
                            SET attribute_category = 'US_VPS', 
                                last_update_date = SYSDATE                                          
                                                          ,
                                last_updated_by = fnd_profile.VALUE('USER_ID')                        
                            WHERE  cash_receipt_id = vidtrxtab(i).cash_receipt_id;
                        ELSE
                            UPDATE ra_customer_trx_all
                            SET attribute_category = 'US_VPS', 
                                last_update_date = SYSDATE                                           
                                                          ,
                                last_updated_by = fnd_profile.VALUE('USER_ID')                        
                            WHERE  customer_trx_id = vidtrxtab(i).customer_trx_id;
                        END IF;

                        ln_ins_count :=   NVL(ln_ins_count,
                                              0)
                                        + 1;
                        ln_refund_tot :=   NVL(ln_refund_tot,
                                               0)
                                         +   vidtrxtab(i).refund_amount
                                           * -1;

                        IF NVL(ln_ins_count,
                               0) = 1
                        THEN
                            od_message('O',
                                       g_print_line); 
                            od_message('O',
                                          'Customer# '
                                       || 'Payee                         '
                                       || 'Trx Type    '
                                       || 'Trx Number     '
                                       || ' Refund Amount '
                                       -- || 'Status '
                                       || 'Escheat '
                                       || 'Refund Alt');
                            od_message('O',
                                       g_print_line);
                            od_message('O',
                                       '');
                        END IF;

                        IF vidtrxtab(i).CLASS = 'PMT'
                        THEN
                            lc_trx_type := 'Receipt';
                        ELSIF vidtrxtab(i).CLASS = 'CM'
                        THEN                                                                           
                            lc_trx_type := 'Credit Memo';
                        ELSE
                            lc_trx_type := 'Invoice';
                        END IF;

                        od_message('O',
                                      RPAD(SUBSTR(vidtrxtab(i).customer_number,
                                                  1,
                                                  10),
                                           10,
                                           ' ')
                                   || RPAD(SUBSTR(vidtrxtab(i).party_name,
                                                  1,
                                                  30),
                                           30,
                                           ' ')
                                   || RPAD(lc_trx_type,
                                           12,
                                           ' ')
                                   || RPAD(SUBSTR(vidtrxtab(i).trx_number,
                                                  1,
                                                  15),
                                           15,
                                           ' ')
                                   || LPAD(TO_CHAR(  vidtrxtab(i).refund_amount
                                                   * -1,
                                                   '99G999G990D00PR'),
                                           15,
                                           ' ')
                                   || '   '
                                   || lc_escheat_flag
                                   || '    '
                                   || '    '
                                   || lc_refund_alt_flag
                                   || '    ');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            od_message('M',
                                          SQLCODE
                                       || ': '
                                       || SQLERRM
                                       || ' When saving Trx '
                                       || vidtrxtab(i).CLASS
                                       || ':'
                                       || vidtrxtab(i).trx_number);
                    END; 
                    <<NEXT_RECORD>>                                                                               
                    od_message('E',
                               'Invalid Combination of Delete_Status and Hold_Status');
                END LOOP;
            END IF;
        END LOOP;

        IF ln_id_count > 0
        THEN
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);

            IF p_process_type = 'R'
            THEN
                od_message('M',
                              'Identified '
                           || ln_id_count
                           || ' transactions to Review Form');
                od_message('M',
                              'Inserted '
                           || ln_ins_count
                           || ' transactions to Review Form');
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || RPAD(' ',
                                   30,
                                   ' ')
                           || LPAD('Total Refunds Identified:',
                                   27,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' ')); 
            ELSE
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || RPAD(' ',
                                   30,
                                   ' ')
                           || LPAD('Total :',
                                   27,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' '));
                od_message('M',
                              'Identified '
                           || ln_id_count
                           || ' transactions.');
                od_message('M',
                              'Inserted '
                           || ln_ins_count
                           || ' transactions.');
            END IF;

            od_message('O',
                       g_print_line);
            od_message('O',
                       ' ');
        ELSE                                                                                   -- No records Identified.
            od_message('M',
                       'No Transactions Identified for Review');
        END IF;

        close_cursors();
        COMMIT;
    EXCEPTION
        WHEN exp_invalid_sob
        THEN
            close_cursors();
            od_message('E',
                       'Error Identifying Refund Transactions.',
                       'Invalid Set of Books');
        WHEN OTHERS
        THEN
            close_cursors();
            od_message('M',
                          'Error Identifying Refund Transactions.'
                       || SQLCODE
                       || ':'
                       || SQLERRM);
            od_message('E',
                       'Error Identifying Refund Transactions.');
    END identify_refund_trx;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
    PROCEDURE create_refund(
        errbuf         OUT NOCOPY     VARCHAR2,
        retcode        OUT NOCOPY     VARCHAR2, 
        p_om_escheats  IN             VARCHAR2,
        p_user_id      IN             NUMBER                                                 
                                            )
    IS
        CURSOR c_refund_hdr(
            p_org_id  IN  NUMBER)
        IS
            SELECT   refund_header_id,
                     trx_type,
                     customer_id,
                     customer_number,
                     trx_currency_code,
                     SUM(refund_amount) refund_amount
            FROM     xx_ar_refund_trx_tmp
            WHERE    adj_created_flag = 'N'
            AND      status = 'W'
            AND      selected_flag = 'Y' 
            AND      org_id = p_org_id
           -- AND      last_updated_by = NVL(p_user_id,
            --                               last_updated_by)                                  
            GROUP BY refund_header_id,
                     trx_type,
                     customer_id,
                     customer_number,
                     trx_currency_code
            ORDER BY customer_number,
                     trx_type;

        CURSOR c_trx(
            p_customer_id       IN  NUMBER,
            p_org_id            IN  NUMBER,
            p_refund_header_id  IN  NUMBER)
        IS 
            SELECT        /*+ INDEX (XX_AR_REFUND_TRX_TMP XX_AR_REFUND_TRX_TMP_U1) */
                          *
            FROM          xx_ar_refund_trx_tmp
            WHERE         customer_id = p_customer_id
            AND           adj_created_flag = 'N'
            AND           status = 'W'                                                         --Approved for Write off.
            AND           selected_flag = 'Y'
            AND           org_id = p_org_id
            AND           refund_header_id = p_refund_header_id
            FOR UPDATE OF adjustment_number, adj_created_flag, adj_creation_date
            ORDER BY      customer_number,
                          trx_number;

        CURSOR c_trx_to_unapply(
            p_cash_receipt_id  IN  NUMBER)
        IS
            SELECT ara.applied_payment_schedule_id,
                   ara.receivable_application_id,
                   ara.amount_applied,
                   aps.trx_number
            FROM   ar_receivable_applications ara,
                   ar_payment_schedules aps
            WHERE  ara.applied_payment_schedule_id = aps.payment_schedule_id 
            AND    aps.trx_number IN('On Account', 'Prepayment') 
            AND    NVL(display,
                       'N') = 'Y'
            AND    application_type = 'CASH'
            AND    ara.cash_receipt_id = p_cash_receipt_id;

        CURSOR get_addr(
            p_org_id  IN  NUMBER)
        IS
            SELECT   COUNT(*),
                     customer_id,
                     org_id,
                     customer_number
            FROM     xx_ar_refund_trx_tmp
            WHERE    escheat_flag = 'N'
            AND      refund_alt_flag = 'N'
            AND      identification_type != 'OM'
            AND      status = 'W'
            AND      org_id = p_org_id
            AND      adj_created_flag = 'N'
            AND      (   primary_bill_loc_id IS NULL
                      OR alt_address1 IS NULL
                      OR alt_city IS NULL
                      OR NVL(alt_state,
                             alt_province) IS NULL)
            AND      identification_type = 'R'
            GROUP BY customer_id,
                     org_id,
                     customer_number;

        ln_customer_id         hz_cust_accounts.cust_account_id%TYPE;
        ln_ps_id               ar_payment_schedules_all.payment_schedule_id%TYPE;
        ln_cash_receipt_id     ar_cash_receipts_all.cash_receipt_id%TYPE;
        ln_cust_trx_id         ra_customer_trx_all.customer_trx_id%TYPE;
        ln_cust_trx_line_id    ra_customer_trx_lines_all.customer_trx_line_id%TYPE;
        ln_amt_rem             ar_payment_schedules_all.amount_due_remaining%TYPE;
        ln_adj_amt_from        ar_approval_user_limits.amount_from%TYPE;
        ln_adj_amt_to          ar_approval_user_limits.amount_to%TYPE;
        ln_wrtoff_amt_from     ar_approval_user_limits.amount_from%TYPE;
        ln_wrtoff_amt_to       ar_approval_user_limits.amount_to%TYPE;
        lc_trx_type            VARCHAR2(20);
        x_return_status        VARCHAR2(2000);
        x_msg_count            NUMBER;
        x_msg_data             VARCHAR2(2000);
        lc_api_err_msg         VARCHAR2(2000);
        lc_err_loc             VARCHAR2(100);
        lc_err_msg             VARCHAR2(100);
        lc_err                 VARCHAR2(1);
        lc_adj_warning         VARCHAR2(1);
        lc_adj_num             VARCHAR2(100);
        ln_org_id              NUMBER;
        ln_onacct_amt          ar_receivable_applications_all.amount_applied%TYPE;
        ln_refund_total        NUMBER;
        lc_sob_name            gl_sets_of_books.short_name%TYPE;
        --lc_cm_adj_name        ar_receivables_trx.NAME%TYPE;
        --lc_rcpt_wo_name       ar_receivables_trx.NAME%TYPE;
        ln_conc_request_id     NUMBER;
        lc_reason_code         VARCHAR2(100);
        lc_comments            VARCHAR2(2000);
        lc_address1            VARCHAR2(240);
        lc_address2            VARCHAR2(240);
        lc_address3            VARCHAR2(240);
        lc_city                VARCHAR2(60);
        lc_state               VARCHAR2(60);
        lc_province            VARCHAR2(60);
        lc_postal_code         VARCHAR2(60);
        lc_country             VARCHAR2(60);
        lc_status              VARCHAR2(20);
        ln_refunds_count       NUMBER                                                := 0;
        ln_refund_amounts_tot  NUMBER                                                := 0;
        ln_errors_count        NUMBER                                                := 0;
        -- V4.0, to store payment method flag for store trx
        ln_mail_check          NUMBER                                                := 0;
    BEGIN
        ln_org_id := fnd_profile.VALUE('ORG_ID');
        ln_conc_request_id := fnd_profile.VALUE('CONC_REQUEST_ID');

        BEGIN
            SELECT gsb.short_name
            INTO   lc_sob_name
            FROM   ar_system_parameters asp,
                   gl_sets_of_books gsb
            WHERE  gsb.set_of_books_id = asp.set_of_books_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                od_message('M',
                           'Set of Books not found!');
                RAISE;
        END;

        od_message('M',
                      'Set of Books: '
                   || lc_sob_name);
        od_message('O',
                   '');
        od_message('O',
                      'Set of Books:'
                   || fnd_profile.VALUE('GL_SET_OF_BKS_NAME')
                   || '                 OD: Refunds - Create Refunds                        Date:'
                   || TRUNC(SYSDATE));
        od_message('O',
                   '');
        od_message('O',
                   '');

        -- Verify Primary Bill-To address has been setup
        -- for all non-escheat transactions.
        BEGIN
            FOR v_get_addr IN get_addr(ln_org_id)
            LOOP
                BEGIN
                    UPDATE xx_ar_refund_trx_tmp
                    SET (primary_bill_loc_id, alt_address1, alt_address2, alt_address3, alt_city, alt_state,
                         alt_province, alt_postal_code, alt_country) =
                            (SELECT hl.location_id,
                                    hl.address1,
                                    hl.address2,
                                    hl.address3,
                                    hl.city,
                                    hl.state,
                                    hl.province,
                                    hl.postal_code,
                                    hl.country
                             FROM   hz_cust_accounts hca,
                                    hz_cust_acct_sites hcas,
                                    hz_cust_site_uses hcsu,
                                    hz_party_sites hps,
                                    hz_locations hl
                             WHERE  hca.cust_account_id = hcas.cust_account_id(+)
                             AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id(+)
                             AND    hcas.party_site_id = hps.party_site_id
                             AND    hl.location_id = hps.location_id
                             AND    hcas.org_id = v_get_addr.org_id
                             AND    NVL(hcsu.primary_flag,
                                        'N') = 'Y'
                             AND    hcsu.site_use_code = 'BILL_TO'
                             AND    hca.cust_account_id = v_get_addr.customer_id
                             AND    ROWNUM = 1),
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  customer_id = v_get_addr.customer_id
                    AND    escheat_flag = 'N'
                    AND    refund_alt_flag = 'N'
                    AND    status = 'W'
                    AND    adj_created_flag = 'N'
                    AND    (   primary_bill_loc_id IS NULL
                            OR alt_address1 IS NULL
                            OR alt_city IS NULL
                            OR NVL(alt_state,
                                   alt_province) IS NULL)
                    AND    identification_type = 'R';

                    od_message('M',
                                  'Updated '
                               || SQL%ROWCOUNT
                               || ' rows.');
                    od_message('M',
                                  'Found Primary Bill_To for Customer#:'
                               || v_get_addr.customer_number
                               || ' in org:'
                               || v_get_addr.org_id);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message('M',
                                      '*** Error getting Primary Bill_To for Customer#:'
                                   || v_get_addr.customer_number
                                   || ' in org:'
                                   || v_get_addr.org_id
                                   || '  Error:'
                                   || SQLCODE
                                   || ':'
                                   || SQLERRM);
                END;
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        -- For each refund header ID in xx_ar_refund_trx_tmp table
        -- with atleast one row in xx_ar_refund_trx_tmp with adj_created_flag = 'N'
        FOR v_refund_hdr IN c_refund_hdr(ln_org_id)
        LOOP
            -- Get all records in xx_ar_refund_trx_tmp for refund header ID and adj_created_flag = 'N'
            ln_adj_amt_from := 0;
            ln_adj_amt_to := 0;
 
            IF lc_trx_type = 'C' OR lc_trx_type = 'I'
            THEN                                                                          
                lc_trx_type := 'Credit Memo';
            ELSE
                lc_trx_type := 'Receipt';
            END IF;

            od_message('M',
                       '----------------------------------------------------------------------');

            FOR v_trx IN c_trx(v_refund_hdr.customer_id,
                               ln_org_id,
                               v_refund_hdr.refund_header_id)
            LOOP
                lc_err := 'N';
                lc_adj_warning := 'N';
                lc_adj_num := NULL;
                ln_ps_id := NULL;
                x_return_status := NULL;
                x_msg_data := NULL;
                x_msg_count := NULL; 
                ln_mail_check := 0;
                od_message('M',
                              'Customer#:'
                           || v_refund_hdr.customer_number
                           || ' Type:'
                           || v_trx.trx_type
                           || '  Trx#:'
                           || v_trx.trx_number
                           || ' Refund Amount:'
                           || v_refund_hdr.trx_currency_code
                           || ' '
                           || v_refund_hdr.refund_amount); 
                BEGIN
                    SELECT payment_schedule_id,
                           DECODE(ps.CLASS,
                                  'PMT', 'Receipt',
                                  'Credit Memo'),
                             -1
                           * amount_due_remaining
                    INTO   ln_ps_id,
                           lc_trx_type,
                           ln_amt_rem
                    FROM   ar_payment_schedules ps
                    WHERE  ps.customer_id = v_refund_hdr.customer_id
                    AND    (   (v_trx.trx_type = 'R' AND ps.cash_receipt_id = v_trx.trx_id) 
                            OR (    v_trx.trx_type IN('C', 'I')                            
                                AND ps.customer_trx_id = v_trx.trx_id));

                    IF v_trx.trx_type = 'R'
                    THEN
                        BEGIN
                            ln_onacct_amt := 0; 
                            SELECT NVL(SUM(NVL(amount_applied,
                                               0)),
                                       0) 
                            INTO   ln_onacct_amt
                            FROM   ar_receivable_applications
                            WHERE  cash_receipt_id = v_trx.trx_id
                            AND    display = 'Y'                                    -- only show the active applications
                            AND    applied_payment_schedule_id = (SELECT payment_schedule_id
                                                                  FROM   ar_payment_schedules_all 
                                                                  WHERE  trx_number = 'On Account'); 
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ln_onacct_amt := 0;
                        END;

                        od_message('M',
                                      'Amt_Remaining:'
                                   || ln_amt_rem
                                   || ' On Acct Amt:'
                                   || ln_onacct_amt);
                        ln_amt_rem :=   NVL(ln_amt_rem,
                                            0)
                                      - NVL(ln_onacct_amt,
                                            0);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lc_err := 'Y';

                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number)
                             VALUES (ln_conc_request_id,
                                     'R0008',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number);
                END;

            -- if the amount due remaining <> refund amount.
            -- This is possible if applications/adjustments/unapplications
            -- occur after creation of refund record 
                IF ln_amt_rem <> v_trx.refund_amount AND NVL(v_trx.ref_mailcheck_id,
                                                             0) = 0
                THEN
                    lc_err := 'Y';
                    od_message('M',
                                  '*** Remaining Amount:'
                               || ln_amt_rem
                               || ' does not match Refund Amount:'
                               || v_trx.refund_amount);

                    IF v_trx.trx_type = 'R' AND ln_onacct_amt <> 0
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number,
                                     attribute1,
                                     attribute2,
                                     attribute3)
                             VALUES (ln_conc_request_id,
                                     'R0009',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number,
                                     TO_CHAR(ABS(ln_onacct_amt)),
                                     v_trx.refund_amount,
                                     ln_amt_rem);
                    ELSE
                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number,
                                     attribute1,
                                     attribute2)
                             VALUES (ln_conc_request_id,
                                     'R0001',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number,
                                     TO_CHAR(v_trx.refund_amount),
                                     TO_CHAR(ABS(ln_amt_rem)));
                    END IF;
                END IF;

                -- If alternate address is indicated, check if it has been entered.
                -- Or check if a primary bill-to is specified.
                IF     NVL(v_trx.escheat_flag,
                           'N') = 'N'
                   AND TRIM(v_trx.alt_address1) IS NULL
                   AND TRIM(v_trx.alt_city) IS NULL
                   AND (TRIM(v_trx.alt_state) IS NULL OR TRIM(v_trx.alt_province) IS NULL)
                THEN
                    IF NVL(v_trx.refund_alt_flag,
                           'N') = 'Y' OR v_trx.primary_bill_loc_id IS NULL
                    THEN 
                        IF NOT(    v_trx.identification_type = 'OM'
                               AND v_trx.om_hold_status != 'P'
                               AND v_trx.om_delete_status != 'N')
                        THEN
                            lc_err := 'Y';

                            UPDATE xx_ar_refund_trx_tmp
                            SET error_flag = 'Y',
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE  refund_header_id = v_trx.refund_header_id;

                            INSERT INTO xx_ar_refund_error_log
                                        (conc_request_id,
                                         err_code,
                                         customer_number,
                                         trx_type,
                                         trx_number,
                                         attribute1)
                                 VALUES (ln_conc_request_id,
                                         'R0011',
                                         v_trx.customer_number,
                                         lc_trx_type,
                                         v_trx.trx_number,
                                         DECODE(v_trx.refund_alt_flag,
                                                'Y', 'Alternate',
                                                'Primary Bill-To'));
                        END IF;
                    END IF;
                END IF;

                IF v_trx.activity_type IS NULL
                THEN
                    lc_err := 'Y';

                    UPDATE xx_ar_refund_trx_tmp
                    SET error_flag = 'Y',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  refund_header_id = v_trx.refund_header_id;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number)
                         VALUES (ln_conc_request_id,
                                 'R0014',
                                 v_trx.customer_number,
                                 lc_trx_type,
                                 v_trx.trx_number);
                END IF;

                IF lc_err = 'N'
                THEN
                    -- If credit memo
                    lc_reason_code := NULL;
                    lc_comments := NULL; 
                    IF v_trx.trx_type = 'C' OR v_trx.trx_type = 'I'
                    THEN      
							BEGIN 
								SELECT rct.attribute7 into lc_reason_code
								FROM
									ra_customer_trx_all rct 
								WHERE rct.customer_trx_id= v_trx.trx_id; 
                                lc_comments := 'VPS Credit Memo Refund';
                                EXCEPTION WHEN OTHERS THEN
                                lc_reason_code:='REFUND';
                            END;  

                        x_return_status := NULL;
                        x_msg_data := NULL;
                        x_msg_count := NULL;
                        create_cm_adjustment(ln_ps_id,
                                             v_trx.trx_id,
                                             v_refund_hdr.customer_number,
                                             v_trx.refund_amount,
                                             ln_org_id,
                                             v_trx.activity_type,
                                             lc_reason_code,
                                             lc_comments,
                                             lc_adj_num,
                                             x_return_status,
                                             x_msg_count,
                                             x_msg_data);
                        od_message('M',
                                      'After Create CM Adjustment for:'
                                   || v_trx.trx_number
                                   || ' for :'
                                   || v_trx.trx_currency_code
                                   || ' '
                                   || v_trx.refund_amount
                                   || ' Status:'
                                   || x_return_status
                                   || ' Message:'
                                   || x_msg_count
                                   || ':'
                                   || x_msg_data);
 
                        IF NVL(x_return_status,
                               fnd_api.g_ret_sts_success) = fnd_api.g_ret_sts_success
                        THEN 
                            od_message('M',
                                          'Adj Api returned Success. Msg Count:'
                                       || x_msg_count);

                            IF NVL(x_msg_count,
                                   0) > 0
                            THEN
                                lc_err := 'N';
                                lc_adj_warning := 'Y';

                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    remarks = x_msg_data,
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0004',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        ELSIF NVL(x_return_status,
                                  fnd_api.g_ret_sts_success) <> fnd_api.g_ret_sts_success
                        THEN
                            lc_err := 'Y';

                            IF NVL(x_msg_data,
                                   'x') IN('R0007')
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             x_msg_data,
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             v_trx.activity_type);
                            ELSE
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0003',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        END IF;

                        IF NVL(lc_err,
                               'N') = 'N'
                        THEN
                            od_message('M',
                                          'Success creating CM Adjustment '
                                       || lc_adj_num);

                            UPDATE xx_ar_refund_trx_tmp
                            SET adjustment_number = lc_adj_num,
                                adj_created_flag = 'Y',
                                adj_creation_date = SYSDATE,
                                error_flag = NVL(lc_adj_warning,
                                                 'N'),
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE CURRENT OF c_trx;

                            -- Update DFF2 to show status.
                            UPDATE ra_customer_trx_all
                            SET attribute3 = 'Refund Adjustment', 
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID')
                            WHERE  customer_trx_id = v_trx.trx_id;
                        ELSE                
                            od_message('M',
                                          '*** Error - Refund could not be created for TRX:'
                                       || v_trx.trx_type
                                       || '/'
                                       || v_trx.trx_number);
                        END IF;
                    ELSE                                                                                     -- Receipt.
                        IF NVL(v_trx.escheat_flag,
                               'N') = 'Y'
                        THEN
                            FOR v_unapp_trx IN c_trx_to_unapply(v_trx.trx_id)
                            LOOP
                                IF v_unapp_trx.trx_number = 'On Account'
                                THEN
                                    od_message('M',
                                                  'Unapply On Account of '
                                               || v_unapp_trx.amount_applied
                                               || ' for receipt:'
                                               || v_trx.trx_number);
                                    x_return_status := NULL;
                                    x_msg_data := NULL;
                                    x_msg_count := NULL;
                                    unapply_on_account(v_unapp_trx.receivable_application_id,
                                                       x_return_status,
                                                       x_msg_count,
                                                       x_msg_data);
                                ELSIF v_unapp_trx.trx_number = 'Prepayment'
                                THEN
                                    od_message('M',
                                                  'Unapply Prepayment of '
                                               || v_unapp_trx.amount_applied
                                               || ' for receipt:'
                                               || v_trx.trx_number
                                               || ' - recv_appl_id = '
                                               || v_unapp_trx.receivable_application_id);
                                    x_return_status := NULL;
                                    x_msg_data := NULL;
                                    x_msg_count := NULL;
                                    unapply_prepayment(v_unapp_trx.receivable_application_id,
                                                       x_return_status,
                                                       x_msg_count,
                                                       x_msg_data);
                                ELSE
                                    od_message('M',
                                                  '*** Warning: Non Prepayment/On-Account application'
                                               || ' found for trx:'
                                               || v_trx.trx_number);
                                END IF;
                            END LOOP;
                        ELSE                                                                            -- Non-Escheats.
                            IF NVL(v_trx.refund_alt_flag,
                                   'N') = 'Y'
                            THEN
                                lc_reason_code := 'REFUND ALT';
                                lc_comments :=
                                       ';'
                                    || v_trx.alt_address1
                                    || ' '
                                    || v_trx.alt_address2
                                    || ' '
                                    || v_trx.alt_address3
                                    || ' '
                                    || v_trx.alt_city
                                    || ' '
                                    || NVL(v_trx.alt_state,
                                           v_trx.alt_province)
                                    || ' '
                                    || v_trx.alt_postal_code
                                    || ' '
                                    || v_trx.alt_country;
                            ELSE
                                lc_reason_code := 'REFUND';
                                lc_comments := NULL;
                            END IF;
                        END IF;
 
                        -- If On-Account/Pre-Pay unapp is successful create Rcpt W/off
                        IF     NVL(x_return_status,
                                   fnd_api.g_ret_sts_success) = fnd_api.g_ret_sts_success 
                        --On-Account/Prepayment
                        THEN
                            x_return_status := NULL;
                            x_msg_data := NULL;
                            x_msg_count := NULL; 
                            
							BEGIN 
								SELECT rct.attribute7 into lc_reason_code
								FROM
									ar_cash_receipts_all rct 
								WHERE rct.cash_receipt_id= v_trx.trx_id;  
                                EXCEPTION WHEN OTHERS THEN
									lc_reason_code:='REFUND';
                            END;
							
                            create_receipt_writeoff(v_refund_hdr.refund_header_id ,
                                                    v_trx.trx_id,
                                                    v_refund_hdr.customer_number,
                                                    v_trx.refund_amount,
                                                    ln_org_id,
                                                    v_trx.activity_type,
                                                    lc_reason_code,
                                                    lc_comments,
                                                    NVL(v_trx.escheat_flag,
                                                        'N'),
                                                    lc_adj_num,
                                                    x_return_status,
                                                    x_msg_count,
                                                    x_msg_data);

                            IF NVL(x_return_status,
                                   fnd_api.g_ret_sts_success) <> fnd_api.g_ret_sts_success
                            --Receipt Write-off  was not successful
                            THEN
                                lc_err := 'Y';

                                IF NVL(x_msg_data,
                                       'x') IN('R0012')
                                THEN
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1)
                                         VALUES (ln_conc_request_id,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        5),
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                 v_trx.activity_type);
                                ELSIF x_msg_data IN('R0013')
                                THEN
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1)
                                         VALUES (ln_conc_request_id,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        100),
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                 'Receipt Write-off');
                                ELSE
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1,
                                                 attribute2)
                                         VALUES (ln_conc_request_id,
                                                 'R0005',
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                    v_trx.trx_currency_code
                                                 || ' '
                                                 || v_trx.refund_amount,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        1000));
                                END IF;

                                od_message('M',
                                              '**Error Creating Receipt Write-Off: '
                                           || x_msg_data);
                            ELSE
                                od_message('M',
                                              'After Create Receipt Write-off for:'
                                           || v_trx.trx_number
                                           || ' for :'
                                           || v_trx.trx_currency_code
                                           || ' '
                                           || v_trx.refund_amount
                                           || ' Status:'
                                           || x_return_status
                                           || ' Message:'
                                           || x_msg_count
                                           || ':'
                                           || x_msg_data);
                                od_message('M',
                                              'Receivable_Application_ID for Receipt write-off:'
                                           || lc_adj_num);
                            END IF;
                        ELSIF ln_mail_check = 0
                        THEN                                      
                            --On-Account/Prepayment application error
                            lc_err := 'Y';

                            IF NVL(x_msg_data,
                                   'x') IN('R0010')
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    5),
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    7,
                                                    1000));
                            ELSE
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1,
                                             attribute2)
                                     VALUES (ln_conc_request_id,
                                             'R0005',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                                v_trx.trx_currency_code
                                             || ' '
                                             || v_trx.refund_amount,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        END IF;
                    END IF;

                    IF lc_err = 'N'
                    THEN
                        IF ln_mail_check = 0
                        THEN                   
                            ln_refunds_count :=   NVL(ln_refunds_count,
                                                      0)
                                                + 1;
                            ln_refund_amounts_tot :=   NVL(ln_refund_amounts_tot,
                                                           0)
                                                     + v_trx.refund_amount;
                        END IF;                                          
                        BEGIN
                            UPDATE xx_ar_refund_trx_tmp
                            SET adjustment_number = lc_adj_num,
                                adj_created_flag = 'Y',
                                status = 'A',
                                adj_creation_date = SYSDATE,
                                error_flag = NVL(lc_adj_warning,
                                                 'N'),
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE CURRENT OF c_trx;

                            IF ln_refunds_count = 1
                            THEN
                                od_message('O',
                                           'Adjustments/Write-off Created for the following Transactions');
                                od_message('O',
                                           ' ');
                                od_message('O',
                                           g_print_line); 
                                od_message('O',
                                              'Customer# '
                                           || 'Payee                    '
                                           || 'Trx Type    '
                                           || 'Trx Number     '
                                           || ' Refund Amount '
                                           || 'Adjustment#         '
                                           || 'Status       '
                                           || 'Escheat');
                                od_message('O',
                                           g_print_line);
                            END IF;

                            od_message('O',
                                          RPAD(SUBSTR(v_refund_hdr.customer_number,
                                                      1,
                                                      10),
                                               10,
                                               ' ')
                                       || RPAD(SUBSTR(v_trx.payee_name,
                                                      1,
                                                      25),
                                               25,
                                               ' ')
                                       || RPAD(lc_trx_type,
                                               12,
                                               ' ')
                                       || RPAD(SUBSTR(v_trx.trx_number,
                                                      1,
                                                      15),
                                               15,
                                               ' ')
                                       || LPAD(TO_CHAR(v_trx.refund_amount,
                                                       '99G999G990D00PR'),
                                               15,
                                               ' ')
                                       || RPAD(SUBSTR(lc_adj_num,
                                                      1,
                                                      20),
                                               20,
                                               ' ')
                                       || '   '
                                       || RPAD(v_trx.status,
                                               11,
                                               ' ')
                                       || '  '
                                       || v_trx.escheat_flag);

                            BEGIN
                                lc_err_loc := 'Update DFF2 value on Receipt';

                                -- Update DFF2 to show status.
                                UPDATE ar_cash_receipts_all acr
                                SET attribute3 = 'Refund Adjustment', 
                                    last_update_date = SYSDATE                                         
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                 
                                WHERE  cash_receipt_id = v_trx.trx_id;

                                lc_err_loc := 'Update process code and OM DFF for Receipt';
 
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    od_message('M',
                                                  'Warning: Could not update DFF on Cash Receipt.'
                                               || SQLCODE
                                               || ':'
                                               || SQLERRM);
                            END;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error updating adjustment created flag and'
                                           || ' status after creating adjustment. Error:'
                                           || SQLCODE
                                           || ':'
                                           || SQLERRM);
                        END;
                    END IF;
                ELSE                                                              -- if pre adjust/write-off error = 'N'
                    od_message('M',
                                  '*** Error (Pre-Loop)- Refund could not be created for TRX:'
                               || v_trx.trx_type
                               || '/'
                               || v_trx.trx_number);
                END IF;                                                                                  -- if err = 'N'

                IF lc_err = 'Y'
                THEN
                    ln_errors_count :=   NVL(ln_errors_count,
                                             0)
                                       + 1;
                END IF;
            END LOOP;
        END LOOP;
		
		IF(p_user_id is null) 
		THEN
			update_dffs;
		END IF;
			
        IF ln_refunds_count > 0
        THEN
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);
            od_message('O',
                          RPAD(' ',
                               10,
                               ' ')
                       || RPAD(' ',
                               25,
                               ' ')
                       || RPAD(' ',
                               10,
                               ' ')
                       || LPAD('    Total:  ',
                               15,
                               ' ')
                       || ' '
                       || LPAD(TO_CHAR(ln_refund_amounts_tot,
                                       '9G999G990D00PR'),
                               16,
                               ' '));
            od_message('O',
                       ' ');
        END IF;
 
        IF (gn_tot_receipt_writeoff > 0)
        THEN
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                                 Refunds to be Reclassified '); 
            od_message('O',
                       g_print_line);                         

            FOR cntr IN 1 ..   gn_count
                             - 1
            LOOP
                      
                fnd_file.put_line(fnd_file.output,
                                     gt_receipt_writeoff(cntr).account_dr     
                                  || '|'
                                  || gt_receipt_writeoff(cntr).refund_amount
                                  || '||'                                     
                                  || gt_receipt_writeoff(cntr).receipt_date
                                  || '|'
                                  || gt_receipt_writeoff(cntr).description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_dr           
                                  || '|'
                                  || gt_receipt_writeoff(cntr).meaning_debit
                                  || '|'
                                  || gt_receipt_writeoff(cntr).account_seg_dr); 
                fnd_file.put_line(fnd_file.output,
                                     gt_receipt_writeoff(cntr).account_cr    
                                  || '||'                                    
                                  || gt_receipt_writeoff(cntr).refund_amount
                                  || '|'
                                  || gt_receipt_writeoff(cntr).receipt_date
                                  || '|'
                                  || gt_receipt_writeoff(cntr).description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_cr   
                                  || '|'
                                  || gt_receipt_writeoff(cntr).meaning_credit
                                  || '|'
                                  || gt_receipt_writeoff(cntr).account_seg_cr);
            END LOOP;
        ELSE
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                                 Refunds to be Reclassified ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '*** No Receipt Write OFF done using Generic Receivable Activity ***');
        END IF; 
		
        IF ln_errors_count > 0
        THEN
            print_errors(ln_conc_request_id);
        END IF;

        od_message('O',
                   '');
        od_message('O',
                   '');
        od_message('O',
                   '');
        od_message('O',
                   g_print_line);
        od_message('O',
                   '                                                 Process Summary ');
        od_message('O',
                   g_print_line);
        od_message('O',
                      'Number of refunds successfully Created          :'
                   || ln_refunds_count);
        od_message('O',
                      'Total Amount of refunds successfully Created    :'
                   || ln_refund_amounts_tot);
        od_message('O',
                      'Number of errors when creating refunds          :'
                   || ln_errors_count);
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_application_error(-20000,
                                       '**** Error:'
                                    || SQLCODE
                                    || ':'
                                    || SQLERRM);
    END;

    PROCEDURE create_cm_adjustment(
        p_payment_schedule_id  IN             NUMBER,
        p_customer_trx_id      IN             NUMBER,
        p_customer_number      IN             VARCHAR2,
        p_amount               IN             NUMBER,
        p_org_id               IN             NUMBER,
        p_adj_name             IN             VARCHAR2,
        p_reason_code          IN             VARCHAR2,
        p_comments             IN             VARCHAR2,
        o_adj_num              OUT NOCOPY     VARCHAR2,
        x_return_status        OUT NOCOPY     VARCHAR2,
        x_msg_count            OUT NOCOPY     NUMBER,
        x_msg_data             OUT NOCOPY     VARCHAR2)
    IS
        lr_adj_rec      ar_adjustments%ROWTYPE;
        lc_adj_num      ar_adjustments.adjustment_number%TYPE;
        ln_adj_id       ar_adjustments.adjustment_id%TYPE;
        ln_activity_id  ar_receivables_trx_all.receivables_trx_id%TYPE;
        ln_line_amt     ra_customer_trx_lines_all.extended_amount%TYPE;
        ln_amt          ra_customer_trx_lines_all.extended_amount%TYPE;
        lc_api_err_msg  VARCHAR2(2000);
        lc_adj_status   ar_adjustments_all.status%TYPE;
    BEGIN
        SELECT receivables_trx_id
        INTO   ln_activity_id
        FROM   ar_receivables_trx r
        WHERE  TRIM(r.NAME) = p_adj_name AND org_id = p_org_id AND status = 'A';

        od_message('M',
                      'CM Adjustment Name: '
                   || p_adj_name);
        o_adj_num := NULL;
        lr_adj_rec.TYPE := 'INVOICE';
        lr_adj_rec.payment_schedule_id := p_payment_schedule_id;
        lr_adj_rec.amount := p_amount;
        lr_adj_rec.customer_trx_id := p_customer_trx_id;
        lr_adj_rec.receivables_trx_id := ln_activity_id;
        lr_adj_rec.apply_date := TRUNC(SYSDATE);
        lr_adj_rec.gl_date := TRUNC(SYSDATE);
        lr_adj_rec.reason_code := p_reason_code;                                                             --'REFUND';
        lr_adj_rec.created_from := 'ADJ-API';
        lr_adj_rec.comments :=  p_comments;
        fnd_file.put_line(fnd_file.LOG,
                             'p_payment_schedule_id: '
                          || p_payment_schedule_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_amount: '
                          || p_amount);
        fnd_file.put_line(fnd_file.LOG,
                             'p_customer_trx_id: '
                          || p_customer_trx_id);
        fnd_file.put_line(fnd_file.LOG,
                             'ln_activity_id: '
                          || ln_activity_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_reason_code: '
                          || p_reason_code);
        fnd_file.put_line(fnd_file.LOG,
                             'p_reason_code || p_comments: '
                          || p_reason_code
                          || p_comments);
        ar_adjust_pub.create_adjustment(p_api_name               => 'AR_ADJUST_PUB',
                                        p_api_version            => 1.0,
                                        p_init_msg_list          => fnd_api.g_true,
                                        p_msg_count              => x_msg_count,
                                        p_msg_data               => x_msg_data,
                                        p_return_status          => x_return_status,
                                        p_adj_rec                => lr_adj_rec,
                                        p_new_adjust_number      => lc_adj_num,
                                        p_new_adjust_id          => ln_adj_id );
        o_adj_num := lc_adj_num;
-------------------
        fnd_file.put_line(fnd_file.LOG,
                             'x_msg_count: '
                          || x_msg_count);
        fnd_file.put_line(fnd_file.LOG,
                             'x_msg_data: '
                          || x_msg_data);
        fnd_file.put_line(fnd_file.LOG,
                             'x_return_status: '
                          || x_return_status);

-------------------
        IF NVL(x_return_status,
               'x') = fnd_api.g_ret_sts_success
        THEN
            od_message('M',
                          'Before Approve:'
                       || x_msg_data);
            od_message('M',
                          'Status: '
                       || x_return_status
                       || ' Count:'
                       || x_msg_count
                       || 'Data:'
                       || x_msg_data);
            x_return_status := NULL;
            x_msg_count := NULL;
            x_msg_data := NULL;

            IF lc_adj_num IS NOT NULL
            THEN
                BEGIN
                    SELECT NVL(status,
                               'X')
                    INTO   lc_adj_status
                    FROM   ar_adjustments_all
                    WHERE  adjustment_number = lc_adj_num;

                    IF lc_adj_status != 'A'
                    THEN
                        ar_adjust_pub.approve_adjustment(p_api_name                 => 'AR_ADJUST_PUB',
                                                         p_api_version              => 1.0,
                                                         p_msg_count                => x_msg_count,
                                                         p_msg_data                 => x_msg_data,
                                                         p_return_status            => x_return_status,
                                                         p_adj_rec                  => NULL,
                                                         p_chk_approval_limits      => fnd_api.g_false,
                                                         p_old_adjust_id            => ln_adj_id);
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        od_message('M',
                                      'Error Getting Status for Adjustment:'
                                   || lc_adj_num);
                END;
            END IF;

            od_message('M',
                          'After Approve:'
                       || x_msg_data);
            od_message('M',
                          'Status: '
                       || x_return_status
                       || ' Count:'
                       || x_msg_count
                       || 'Data:'
                       || x_msg_data);
        END IF;

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_api_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || ' of '
                           || x_msg_count
                           || ': '
                           || NVL(lc_api_err_msg,
                                  x_msg_data));
            END LOOP;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            od_message('M',
                          '*** CM Adjustment: '
                       || p_adj_name
                       || ' not Defined for org_id:'
                       || p_org_id);
            x_return_status := 'E';
            x_msg_data := 'R0007';
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** CM Adjustment: '
                       || p_adj_name
                       || ' for org_id:'
                       || p_org_id
                       || ' Other error-'
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data := 'R0007';
    END;

    PROCEDURE create_receipt_writeoff(
        p_refund_header_id           IN             NUMBER                     
                                                          ,
        p_cash_receipt_id            IN             NUMBER,
        p_customer_number            IN             VARCHAR2,
        p_amount                     IN             NUMBER,
        p_org_id                     IN             NUMBER,
        p_wo_name                    IN             VARCHAR2,
        p_reason_code                IN             VARCHAR2,
        p_comments                   IN             VARCHAR2,
        p_escheat_flag               IN             VARCHAR2,
        o_receivable_application_id  OUT NOCOPY     VARCHAR2,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        ln_activity_id                  ar_receivables_trx_all.receivables_trx_id%TYPE;
        ln_applied_payment_schedule_id  ar_payment_schedules_all.payment_schedule_id%TYPE;
        lc_application_ref_type         ar_receivable_applications.application_ref_type%TYPE;
        ln_application_ref_id           ar_receivable_applications.application_ref_id%TYPE;
        lc_application_ref_num          ar_receivable_applications.application_ref_num%TYPE;
        ln_secondary_appln_ref_id       ar_receivable_applications.secondary_application_ref_id%TYPE;
        ln_receivable_application_id    ar_receivable_applications.receivable_application_id%TYPE;
        lc_api_err_msg                  VARCHAR2(2000);
        ln_account_cr                   VARCHAR2(240)                                                  := NULL;
                                                  
        lc_meaning_credit               VARCHAR2(240);                                       
        lc_meaning_debit                VARCHAR2(240);                                       
        lc_description                  VARCHAR2(240);                                      
        lc_generic_activity_type        VARCHAR2(240);                                      
    BEGIN
        BEGIN
            SELECT payment_schedule_id
            INTO   ln_applied_payment_schedule_id
            FROM   ar_payment_schedules
            WHERE  trx_number = 'Receipt Write-off'; 
			
            SELECT flv.meaning,
                   flv.description
            INTO   gt_receipt_writeoff(gn_count).meaning_credit,
                   gt_receipt_writeoff(gn_count).location_description
            FROM   fnd_lookup_values_vl flv
            WHERE  flv.lookup_type = 'XX_AR_REFUNDS_RECLASSIFICATION'
            AND    flv.enabled_flag = 'Y'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND TRUNC(NVL(flv.end_date_active,
                                                                                       SYSDATE
                                                                                     + 1))
            AND    flv.lookup_code = 'CREDIT';

            SELECT flv.meaning,
                   flv.description
            INTO   gt_receipt_writeoff(gn_count).meaning_debit,
                   gt_receipt_writeoff(gn_count).location_description
            FROM   fnd_lookup_values_vl flv
            WHERE  flv.lookup_type = 'XX_AR_REFUNDS_RECLASSIFICATION'
            AND    flv.enabled_flag = 'Y'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND TRUNC(NVL(flv.end_date_active,
                                                                                       SYSDATE
                                                                                     + 1))
            AND    flv.lookup_code = 'DEBIT';
 
            BEGIN
                SELECT r.receivables_trx_id,
                       r.description                                               
                                    ,
                       glc.segment3                                                
                                   ,
                       glc.segment4                                                
                                   ,
                          glc.segment1
                       || '|'        
                       || glc.segment2
                       || '|'
                       || glc.segment3
                       || '|'
                       || glc.segment4
                       || '|'
                       || glc.segment5
                       || '|'
                       || glc.segment6
                       || '|'
                       || glc.segment7 "CODE_COMBINATION"                                  
                INTO   ln_activity_id,
                       gt_receipt_writeoff(gn_count).description                           
                                                                ,
                       gt_receipt_writeoff(gn_count).account_seg_cr,
                       gt_receipt_writeoff(gn_count).location_cr,
                       gt_receipt_writeoff(gn_count).account_cr 
                FROM   ar_receivables_trx r,
                       gl_code_combinations glc
                WHERE  TYPE = 'WRITEOFF'
                AND    TRIM(r.NAME) = p_wo_name
                AND    org_id = p_org_id
                AND    status = 'A'
                AND    glc.code_combination_id = r.code_combination_id;   

                od_message('M',
                              'Receipt Write-Off Name: '
                           || p_wo_name);
                ar_receipt_api_pub.activity_application
                                                       (p_api_version                       => 1.0,
                                                        p_init_msg_list                     => fnd_api.g_true,
                                                        p_commit                            => fnd_api.g_false,
                                                        p_validation_level                  => fnd_api.g_valid_level_full,
                                                        x_return_status                     => x_return_status,
                                                        x_msg_count                         => x_msg_count,
                                                        x_msg_data                          => x_msg_data,
                                                        p_cash_receipt_id                   => p_cash_receipt_id,
                                                        p_amount_applied                    => p_amount,
                                                        p_applied_payment_schedule_id       => ln_applied_payment_schedule_id,
                                                        p_receivables_trx_id                => ln_activity_id,
                                                        p_comments                          =>    p_reason_code
                                                                                               || p_comments,
                                                        p_apply_date                        => TRUNC(SYSDATE),
                                                        p_application_ref_type              => lc_application_ref_type,
                                                        p_application_ref_id                => ln_application_ref_id,
                                                        p_application_ref_num               => lc_application_ref_num,
                                                        p_secondary_application_ref_id      => ln_secondary_appln_ref_id,
                                                        p_receivable_application_id         => ln_receivable_application_id,
                                                        p_called_from                       => 'OD Refunds Process');
                o_receivable_application_id :=    'Rcv Appl ID:'
                                               || TO_CHAR(ln_receivable_application_id);

                IF NVL(x_msg_count,
                       0) > 0
                THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        lc_api_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);    
                        od_message('M',
                                      '*** '
                                   || i
                                   || ' of '
                                   || x_msg_count
                                   || ': '
                                   || NVL(lc_api_err_msg,
                                          x_msg_data));
                    END LOOP;
 
                    BEGIN
                        SELECT receivables_trx_id,
                               r.description                                                   
                                            ,
                               glc.segment3                                                    
                                           ,
                               glc.segment4                                                    
                                           ,
                                  glc.segment1
                               || '|'                           
                               || glc.segment2
                               || '|'
                               || glc.segment3
                               || '|'
                               || glc.segment4
                               || '|'
                               || glc.segment5
                               || '|'
                               || glc.segment6
                               || '|'
                               || glc.segment7 "CODE_COMBINATION",
                               r.NAME "ACTIVITY_TYPE"
                        INTO   ln_activity_id,
                               gt_receipt_writeoff(gn_count).description ,
                               gt_receipt_writeoff(gn_count).account_seg_dr,
                               gt_receipt_writeoff(gn_count).location_dr,
                               gt_receipt_writeoff(gn_count).account_dr,
                               lc_generic_activity_type
                        FROM   ar_receivables_trx r,
                               gl_code_combinations glc
                        WHERE  TYPE = 'WRITEOFF'
                        AND    org_id = p_org_id
                        AND    status = 'A'
                        AND    glc.code_combination_id = r.code_combination_id
                        AND    TRIM(r.NAME) IN(
                                   SELECT flv.description
                                   FROM   fnd_lookup_values_vl flv
                                   WHERE  flv.lookup_type = 'OD_AR_REF_GENERIC_ACTIVITY'
                                   AND    flv.enabled_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active)
                                                             AND TRUNC(NVL(flv.end_date_active,
                                                                             SYSDATE
                                                                           + 1))
                                   AND    p_wo_name LIKE    flv.meaning
                                                         || '%');               
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ln_activity_id := NULL;
                            od_message
                                   ('M',
                                       '*** Receipt Write-off error @OD_AR_REF_GENERIC_ACTIVTY translation derivation:'
                                    || p_wo_name
                                    || ' -Other Err - '
                                    || SQLERRM);
                    END;

                    IF (ln_activity_id IS NOT NULL)
                    THEN
                        od_message('M',
                                      'Generic Receivable Activity ID: '
                                   || ln_activity_id);
                        ar_receipt_api_pub.activity_application
                                                       (p_api_version                       => 1.0,
                                                        p_init_msg_list                     => fnd_api.g_true,
                                                        p_commit                            => fnd_api.g_false,
                                                        p_validation_level                  => fnd_api.g_valid_level_full,
                                                        x_return_status                     => x_return_status,
                                                        x_msg_count                         => x_msg_count,
                                                        x_msg_data                          => x_msg_data,
                                                        p_cash_receipt_id                   => p_cash_receipt_id,
                                                        p_amount_applied                    => p_amount,
                                                        p_applied_payment_schedule_id       => ln_applied_payment_schedule_id,
                                                        p_receivables_trx_id                => ln_activity_id,
                                                        p_comments                          =>    p_reason_code
                                                                                               || p_comments,
                                                        p_apply_date                        => TRUNC(SYSDATE),
                                                        p_application_ref_type              => lc_application_ref_type,
                                                        p_application_ref_id                => ln_application_ref_id,
                                                        p_application_ref_num               => lc_application_ref_num,
                                                        p_secondary_application_ref_id      => ln_secondary_appln_ref_id,
                                                        p_receivable_application_id         => ln_receivable_application_id,
                                                        p_called_from                       => 'OD Refunds Process');
                        o_receivable_application_id :=    'Rcv Appl ID:'
                                                       || TO_CHAR(ln_receivable_application_id);

----------------------------------------------------------------
--To track the receipts to be Reclassified in the output section
----------------------------------------------------------------
                        BEGIN
                            SELECT receipt_number,
                                   TO_CHAR(receipt_date,
                                           'RRRR-MM-DD'),
                                   NVL(attribute1,
                                       attribute2),
                                   currency_code
                            INTO   gt_receipt_writeoff(gn_count).receipt_number,
                                   gt_receipt_writeoff(gn_count).receipt_date,
                                   gt_receipt_writeoff(gn_count).store_number,
                                   gt_receipt_writeoff(gn_count).currency
                            FROM   ar_cash_receipts
                            WHERE  cash_receipt_id = p_cash_receipt_id; 
							
                            gn_tot_receipt_writeoff :=   gn_tot_receipt_writeoff
                                                       + 1;

----------------------------------------------------------
--Update Orig_activity_type,account_dr,account_cr
----------------------------------------------------------
                            UPDATE xx_ar_refund_trx_tmp
                            SET original_activity_type = p_wo_name,
                                activity_type = lc_generic_activity_type,
                                account_orig_dr =
                                               gt_receipt_writeoff(gn_count).account_dr,
                                account_generic_cr =
                                              gt_receipt_writeoff(gn_count).account_cr,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE  refund_header_id = p_refund_header_id;

                            gn_count :=   gn_count
                                        + 1;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message
                                         ('M',
                                             '*** Receipt Write-off error @Reclassification output derivation section:'
                                          || SQLCODE
                                          || ' -Other Err - '
                                          || SQLERRM);
                        END;                                                      
                    ELSE
                        od_message
                                ('M',
                                    'Generic Receivable Activity does not exist for the Original receivable Activity: '
                                 || p_wo_name);
                    END IF; 
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    od_message('M',
                                  '*** Receipt Write-Off: '
                               || p_wo_name
                               || 'not Defined for org_id:'
                               || p_org_id);
                    x_return_status := 'E';
                    x_msg_data := 'R0012';
                WHEN OTHERS
                THEN
                    od_message('M',
                                  '*** Receipt Write-off:'
                               || p_wo_name
                               || ' -Other Err1 - '
                               || SQLERRM);
                    x_return_status := 'E';
                    x_msg_data := 'R0012';
            END;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                od_message('M',
                           '*** CRW: Receipt Write-Off: Payment Schedule not Defined');
                x_return_status := 'E';
                x_msg_data := 'R0013';
            WHEN OTHERS
            THEN
                od_message('M',
                              '*** CRW: Receipt Write-Off: Payment Schedule - Other Err2 - '
                           || SQLERRM);
                x_return_status := 'E';
                x_msg_data := 'R0013';
        END;
    END;

--------------------------------------------------------------------------------
    PROCEDURE unapply_prepayment(
        p_receivable_application_id  IN             NUMBER,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        lc_err_msg  VARCHAR2(2000);
    BEGIN
        ar_receipt_api_pub.unapply_other_account(p_api_version                    => 1.0,
                                                 p_init_msg_list                  => fnd_api.g_true,
                                                 p_commit                         => fnd_api.g_false,
                                                 p_validation_level               => fnd_api.g_valid_level_full,
                                                 x_return_status                  => x_return_status,
                                                 x_msg_count                      => x_msg_count,
                                                 x_msg_data                       => x_msg_data,
                                                 p_receivable_application_id      => p_receivable_application_id);

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || '.'
                           || SUBSTR(lc_err_msg,
                                     1,
                                     255));

                IF x_msg_data IS NOT NULL
                THEN
                    x_msg_data := SUBSTR(   x_msg_data
                                         || '/'
                                         || i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                ELSE
                    x_msg_data := SUBSTR(   i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                END IF;
            END LOOP;
        END IF;

        IF x_return_status <> 'S'
        THEN
            od_message('M',
                       '*** Error Un-Applying Pre-Payment');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** Error Un-Applying Pre-Payment: '
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data :=    'R0010'
                          || ':'
                          || SQLCODE
                          || ':'
                          || SQLERRM;
    END;

--------------------------------------------------------------------------------
    PROCEDURE unapply_on_account(
        p_receivable_application_id  IN             NUMBER,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        lc_err_msg  VARCHAR2(2000);
    BEGIN
        od_message('M',
                   'Before Calling API for Unapplying On Account.');
        ar_receipt_api_pub.unapply_on_account(p_api_version                    => 1.0,
                                              p_init_msg_list                  => fnd_api.g_true,
                                              p_commit                         => fnd_api.g_false,
                                              p_validation_level               => fnd_api.g_valid_level_full,
                                              x_return_status                  => x_return_status,
                                              x_msg_count                      => x_msg_count,
                                              x_msg_data                       => x_msg_data,
                                              p_receivable_application_id      => p_receivable_application_id);
        od_message('M',
                      'After Calling API for Unapplying On Account-Error Count:'
                   || x_msg_count
                   || ' Error Status:'
                   || x_return_status
                   || '  Msg Data:'
                   || x_msg_data);

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || '.'
                           || SUBSTR(lc_err_msg,
                                     1,
                                     255));

                IF x_msg_data IS NOT NULL
                THEN
                    x_msg_data := SUBSTR(   x_msg_data
                                         || '/'
                                         || i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                ELSE
                    x_msg_data := SUBSTR(   i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                END IF;
            END LOOP;
        END IF;

        IF x_return_status <> 'S'
        THEN
            od_message('M',
                       'Error Un-Applying On Account');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** Error Un-Applying On Account: '
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data :=    'R0010'
                          || ':'
                          || SQLCODE
                          || ':'
                          || SQLERRM;
    END; 
	
    -- Procedure to insert a record into ap_invoices_interface table
    PROCEDURE insert_invoice_interface(
        p_inv_amt         IN             NUMBER,
        p_vendor_name     IN             VARCHAR2 , 
        p_curr            IN             VARCHAR2,
        p_sob_name        IN             VARCHAR2 ,
        p_trx_num         IN             VARCHAR2,
        p_invoice_source  IN             VARCHAR2 ,
        p_description     IN             VARCHAR2,
        p_aops_customer_number     IN             VARCHAR2,
        o_invoice_id      OUT NOCOPY     NUMBER,
        o_invoice_num     OUT NOCOPY     VARCHAR2,
        o_sitecode        OUT NOCOPY     VARCHAR2,
        o_org_id          OUT NOCOPY     NUMBER,
        x_err_mesg        OUT NOCOPY     VARCHAR2)
    IS
        ln_invoice_id   NUMBER;
        lc_invoice_num  ap_invoices_all.invoice_num%TYPE;
                
        v_vendor_site_id NUMBER;
        v_vendor_id      NUMBER;
        v_org_id po_vendor_sites_all.org_id%TYPE;
        v_count            NUMBER;
        v_terms_id         NUMBER;
        v_payment_method   VARCHAR2(25);
        v_pay_group_lookup VARCHAR2(25);
        v_ccid             NUMBER;
        v_vendor_num      VARCHAR2(250);
		v_sup_attr8           VARCHAR2(100); 
		v_consignment_flag    VARCHAR2(10);
    BEGIN
    
      v_vendor_id        := NULL;
      v_vendor_site_id   := NULL;
      v_org_id           := NULL;
      v_terms_id         := NULL;
      v_payment_method   := NULL;
      v_pay_group_lookup := NULL;
      v_ccid             := NULL;
        -- Generate invoice_id from sequence
        SELECT ap_invoices_interface_s.NEXTVAL
        INTO   ln_invoice_id
        FROM   DUAL;

        lc_invoice_num :=    'RPY'
                          || (p_trx_num);
        
        v_vendor_num := substr(p_aops_customer_number,1, (instr(p_aops_customer_number,'-',1))-1);
        
		--defect#44371 -changed the logic to derive payment method 
        /*BEGIN
          SELECT vendor_site_id,
            vendor_id,
            org_id,
            --terms_id,
            payment_method_lookup_code,
            pay_group_lookup_code,
           -- accts_pay_code_combination_id,
            attribute8,
            vendor_site_code
          INTO v_vendor_site_id,
            v_vendor_id,
            v_org_id,
            -- v_terms_id,
            v_payment_method,
            v_pay_group_lookup,
           -- v_ccid,
            v_sup_attr8,
            o_sitecode
		FROM ap_supplier_sites_all 
          WHERE LTRIM(vendor_site_code_alt,'0')=v_vendor_num 
			AND pay_site_flag    ='Y'
			AND  attribute8 like 'TR%'
			AND ( inactive_date IS NULL
			OR inactive_date     > SYSDATE);
        EXCEPTION
        WHEN OTHERS THEN
          x_err_mesg :=  lc_invoice_num||SQLCODE
                          || SQLERRM;
        END;*/
		BEGIN
			SELECT
				ssa.vendor_site_id,
				ssa.vendor_id,
				ssa.org_id, 
				ieppm.payment_method_code,
				ssa.pay_group_lookup_code,
			--  ssa.accts_pay_code_combination_id,
				ssa.attribute8,
				ssa.vendor_site_code
			INTO v_vendor_site_id,
				v_vendor_id,
				v_org_id, 
				v_payment_method,
				v_pay_group_lookup,
			--    v_ccid,
				v_sup_attr8,
				o_sitecode
			FROM   ap_supplier_sites_all ssa
				,iby_external_payees_all iepa
				,iby_ext_party_pmt_mthds ieppm 
			WHERE  LTRIM(ssa.vendor_site_code_alt,'0')=v_vendor_num
			AND  ssa.pay_site_flag='Y'
			AND  ssa.attribute8 like 'TR%'
			AND  (ssa.inactive_date  IS NULL
			OR   ssa.inactive_date     > SYSDATE)
			AND  ssa.vendor_site_id = iepa.supplier_site_id 
			AND  iepa.ext_payee_id = ieppm.ext_pmt_party_id 
			AND ((ieppm.inactive_date IS NULL) OR (ieppm.inactive_date > SYSDATE))
			AND ieppm.primary_flag = 'Y' ;  
		EXCEPTION
			WHEN OTHERS THEN
				x_err_mesg := x_err_mesg||'VENDOR_SITE_CODE-'||o_sitecode||': Error Message: '||SQLERRM;
		END;
		
		BEGIN
          SELECT target_value1 INTO  v_consignment_flag
                 FROM xx_fin_translatedefinition xftd
                    , xx_fin_translatevalues xftv
                WHERE xftv.translate_id = xftd.translate_id
                  AND xftd.translation_name ='OD_VPS_TRANSLATION'
                  AND source_value1='CONSIGNMENT_VALIDATION'
                  AND NVL (xftv.enabled_flag, 'N') = 'Y';
                  
                IF v_consignment_flag='Yes' THEN
                  SELECT code_combination_id
                      INTO v_ccid
                      FROM gl_code_combinations
                     WHERE 1=1
                       AND segment1='1001'
                       AND segment2='00000'
                       AND segment3='20101000'
                       AND segment4='010000'
                       AND segment5='0000'
                       AND segment6='90'
                       AND segment7='000000'; -- Added by Theja Rajula 01/04/2017
                  IF v_sup_attr8 IN ('TR-CON' , 'TR-OMXCON') THEN
                    SELECT count(1) into v_count
                      FROM  
                          iby_external_payees_all iep,
                          iby_pmt_instr_uses_all ipiu 
                    WHERE iep.supplier_site_id=v_vendor_site_id
                      AND payment_flow='DISBURSEMENTS'
                      AND ipiu.ext_pmt_party_id=iep.ext_payee_id
                      AND (ipiu.end_date is null or (sysdate between start_date and end_date)) 
                      AND ipiu.instrument_type = 'BANKACCOUNT';
  
                      IF v_count > 0 then
                          v_payment_method := 'EFT';
                          v_pay_group_lookup := 'US_OD_TRADE_EFT';
                      ELSE
                         v_payment_method := 'CHECK';
                         v_pay_group_lookup := 'US_OD_TRADE_NON_DISCOUNT'; 
                      END IF;
                END IF;
            ELSE
              v_ccid:=NULL;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_consignment_flag :=NULL; 
            x_err_mesg := lc_invoice_num||':v_consignment_flag'||SQLCODE
                          || SQLERRM;
            fnd_file.put_line(fnd_file.log,'Error While Getting Consignment Validation Flag'||SQLERRM);
        END;
  fnd_file.put_line(fnd_file.log,'CCID: '||v_ccid);
        -- Insert a record into ap_invoices_interface table
        INSERT INTO ap_invoices_interface
                    (invoice_id,
                     invoice_num,
                     invoice_date,
                     description, 
                     vendor_id,
                     vendor_site_id, 
                     invoice_amount,
                     invoice_currency_code,
                     terms_name,
                     org_id,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     status,
                     SOURCE,
                     attribute7,
                    payment_method_code,
                     pay_group_lookup_code,
                    goods_received_date,
                    accts_pay_code_combination_id -- Added by Theja Rajula 01/04/2017
                    )
             VALUES (ln_invoice_id,
                     SUBSTR(lc_invoice_num,
                            1,
                            50),
                     SYSDATE  ,
                     p_description,
                     v_vendor_id,--p_vendor_name,
                     v_vendor_site_id,--p_sitecode,
                     ABS(p_inv_amt),
                     p_curr,
                     '00',
                     v_org_id,--fnd_global.org_id,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     NULL,
                     p_invoice_source,
                     p_invoice_source, 
                     v_payment_method,
                     v_pay_group_lookup,
                     SYSDATE,
                     v_ccid -- Added by Theja Rajula 01/04/2017
                    );

        o_invoice_id := ln_invoice_id;
        o_invoice_num := lc_invoice_num;
        o_org_id := v_org_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_invoice_id := 0;
            o_invoice_num := NULL;
            o_org_id := v_org_id;
            x_err_mesg :=    SQLCODE
                          || SQLERRM;
    END;

    PROCEDURE insert_invoice_lines_int(
        p_org_id           IN             NUMBER,
        p_invoice_id       IN             NUMBER,
        p_line_num         IN             NUMBER,
        p_company_num      IN             VARCHAR2,
        p_refund_trx_rec   IN             xx_ar_refund_trx_tmp%ROWTYPE,
        o_invoice_line_id  OUT NOCOPY     NUMBER,
        x_err_mesg         OUT NOCOPY     VARCHAR2,
        p_line             IN             NUMBER)
    IS
        ln_invoice_line_id  NUMBER;
        ln_dist_ccid        gl_code_combinations_kfv.code_combination_id%TYPE;
        lc_dist_cc          gl_code_combinations_kfv.padded_concatenated_segments%TYPE;
        ln_coa_id           gl_sets_of_books.chart_of_accounts_id%TYPE;
        lc_company          gl_code_combinations_kfv.segment1%TYPE;
        lc_cost_center      gl_code_combinations_kfv.segment2%TYPE                       := '00000';
        --'09000';
        lc_account          gl_code_combinations_kfv.segment3%TYPE;
        lc_location         gl_code_combinations_kfv.segment4%TYPE                       := '000000';
        lc_intercompany     gl_code_combinations_kfv.segment5%TYPE                       := '0000';
        lc_lob              gl_code_combinations_kfv.segment6%TYPE                       := '00';
        lc_future           gl_code_combinations_kfv.segment7%TYPE                       := '000000';
        exep_location       EXCEPTION;
        exep_company        EXCEPTION;
        ln_org_id           NUMBER;
        lc_act_type         ar_receivables_trx_all.NAME%TYPE                             := NULL;
    BEGIN
        ln_org_id := p_org_id; --fnd_profile.VALUE('ORG_ID');

        SELECT ap_invoice_lines_interface_s.NEXTVAL
        INTO   ln_invoice_line_id
        FROM   DUAL;

        BEGIN
            SELECT chart_of_accounts_id
            INTO   ln_coa_id
            FROM   gl_sets_of_books sob,
                   ap_system_parameters a
            WHERE  sob.set_of_books_id = a.set_of_books_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_dist_ccid := NULL;
        END; 
    
            BEGIN
			  
              SELECT code_combination_id
              INTO ln_dist_ccid
              FROM ar_receivables_trx_all
              WHERE name =p_refund_trx_rec.activity_type; 
            EXCEPTION WHEN OTHERS THEN
            x_err_mesg :=    SQLCODE
                          || SQLERRM;
            END;
          
        IF ln_dist_ccid = 0 OR ln_dist_ccid = -1
        THEN
            ln_dist_ccid := NULL;
            x_err_mesg :=
                   'Error creating Code Combination ('
                || lc_dist_cc
                || ') for Trx: '
                || p_refund_trx_rec.trx_number
                || '. Error:'
                || fnd_flex_ext.GET_MESSAGE;
        ELSE
            INSERT INTO ap_invoice_lines_interface
                        (invoice_id,
                         invoice_line_id,
                         line_number,
                         line_type_lookup_code,
                         amount,
                         dist_code_combination_id,
                         description,
                         created_by,
                         creation_date,
                         last_updated_by,
                         last_update_date,
                         last_update_login,
                         org_id)
                 VALUES (p_invoice_id,
                         ln_invoice_line_id,
                         p_line_num,
                         'ITEM',
                         p_refund_trx_rec.refund_amount                    
                                                       ,
                         ln_dist_ccid,
                            'Refund for ' 
                         || DECODE(p_refund_trx_rec.trx_type,
                                   'R', 'Receipt',
                                   'Credit Memo')                                  
                         || ': '
                         || (p_refund_trx_rec.trx_number),
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.conc_login_id,
                         ln_org_id);

            o_invoice_line_id := ln_invoice_line_id;
        END IF;
    EXCEPTION
        WHEN exep_location
        THEN
            x_err_mesg := 'Location / Store Number not found.';
            o_invoice_line_id := 0;
        WHEN exep_company
        THEN
            x_err_mesg :=    'Company segment could not be determined for location:'
                          || lc_location;
            o_invoice_line_id := 0;
        WHEN OTHERS
        THEN
            o_invoice_line_id := 0;
            x_err_mesg :=    SQLCODE
                          || SQLERRM;
    END;

    PROCEDURE get_vendor_id(
        p_name       IN      VARCHAR2,
        o_vendor_id  OUT     NUMBER)
    IS
    BEGIN
        SELECT vendor_id
        INTO   o_vendor_id
        FROM   ap_vendors_v                                                                                 --po_vendors
        WHERE  TRIM(UPPER(vendor_name)) = TRIM(UPPER(p_name)) AND ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_vendor_id := NULL;
    END;
  
    PROCEDURE create_ap_invoice(
        errbuf   IN OUT NOCOPY  VARCHAR2,
        errcode  IN OUT NOCOPY  INTEGER)
    IS
        CURSOR c_refund_hdr(
            p_org_id  IN  NUMBER)
        IS
            SELECT *
            FROM   xx_ar_refund_trx_tmp xartt
            WHERE  xartt.inv_created_flag = 'N'
            AND    xartt.adj_created_flag = 'Y'
            AND    xartt.selected_flag = 'Y'
            AND    xartt.status =  'A'  
            AND    org_id = p_org_id;

        CURSOR c_trx(
            p_refund_header_id  IN  NUMBER)
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp
            WHERE         refund_header_id = p_refund_header_id 
            FOR UPDATE OF ap_invoice_number, inv_created_flag, ap_inv_creation_date;

        ln_vendor_id            po_vendors.vendor_id%TYPE;
        ln_vendor_site_id       po_vendor_sites.vendor_site_id%TYPE;
        ln_vendor_interface_id  NUMBER;
        lc_create_vendor        VARCHAR2(1);
        lc_create_site          VARCHAR2(1);
        ln_vendor_cnt           NUMBER;
        ln_site_cnt             NUMBER;
        ln_org_id               NUMBER;
        lc_org_id               NUMBER;
        ln_sob_id               gl_sets_of_books.set_of_books_id%TYPE;
        lc_sitecode             po_vendor_sites.vendor_site_code%TYPE;
        ln_tot_amt              NUMBER;
        ln_invoice_id           NUMBER;
        ln_invoice_line_id      NUMBER;
        lc_invoice_num          ap_invoices_all.invoice_num%TYPE;
        lc_invoice_source       VARCHAR2(30);
        ln_inv_count            NUMBER                                          := 0;
        ln_inv_err_count        NUMBER                                          := 0;
        ln_line_num             NUMBER;
        ln_req_id               NUMBER;
        ln_req_id2              NUMBER;
        lc_phase                VARCHAR2(200);
        lc_status               VARCHAR2(200);
        lc_dev_phase            VARCHAR2(200);
        lc_dev_status           VARCHAR2(200);
        lc_message              VARCHAR2(200);
        lb_wait                 BOOLEAN;
        ln_user_id              NUMBER;
        lc_sob_name             gl_sets_of_books.short_name%TYPE;
        ln_trx_id               NUMBER;
        lc_trx_type             VARCHAR2(15);
        lc_err_mesg             VARCHAR2(1000);
        lc_savepoint            VARCHAR2(100);
        intf_insert_error       EXCEPTION;
        lc_comn_err_loc         VARCHAR2(100);
        ln_proc_count           NUMBER                                          := 0;
        ln_conc_request_id      NUMBER;
        lc_cust_number          hz_cust_accounts.account_number%TYPE; 
        lc_aops_order_number    xx_ar_mail_check_holds.aops_order_number%TYPE;
        lc_description          ap_invoices_interface.description%TYPE;
        ln_invoice_amount       NUMBER;
        lc_payee_name           xx_ar_refund_trx_tmp.payee_name%TYPE;
        lc_sale_return_date     VARCHAR2(30);
        lc_in_invoice_number    VARCHAR2(30);
        xx_lc_description       xx_ar_refund_trx_tmp.description%TYPE;       
	lc_insert_error_sup_site VARCHAR2(2);			

    BEGIN
        ln_vendor_cnt := 0;
        ln_site_cnt := 0;
        ln_inv_count := 0;
        ln_proc_count := 0;
        ln_user_id := fnd_global.user_id;
        ln_org_id := fnd_profile.VALUE('ORG_ID');
        ln_conc_request_id := fnd_profile.VALUE('CONC_REQUEST_ID');
        od_message('M',
                   g_print_line);
        od_message('O',
                   ln_conc_request_id);
        od_message('O',
                      fnd_profile.VALUE('GL_SET_OF_BKS_NAME')
                   || '                 OD: Refunds - Create Invoices for Refunds                    Date:'
                   || TRUNC(SYSDATE));
        od_message('O',
                   '');

        SELECT gsb.short_name
        INTO   lc_sob_name
        FROM   hr_operating_units hru,
               gl_sets_of_books gsb
        WHERE  gsb.set_of_books_id = hru.set_of_books_id AND hru.organization_id = ln_org_id;

        lc_comn_err_loc := 'After SOB name';
 
        FOR v_refund_hdr IN c_refund_hdr(ln_org_id)
        LOOP
            BEGIN
                ln_vendor_site_id := NULL;                                 
                lc_err_mesg := NULL;
                lc_create_vendor := 'N';
                lc_create_site := 'N';
	        lc_insert_error_sup_site:=NULL;
                lc_savepoint :=    'SAVEPOINT-XXARRFNDC'
                                || v_refund_hdr.refund_header_id;
                od_message('M',
                           ' ');
                od_message('M',
                           g_print_line);
                SAVEPOINT lc_savepoint;
                od_message('M',
                              'Set Savepoint:'
                           || lc_savepoint);

                IF v_refund_hdr.trx_type = 'R'
                THEN
                    lc_trx_type := 'Receipt';
                ELSE
                    lc_trx_type := 'Credit Memo';
                END IF;
 
                ln_invoice_amount := v_refund_hdr.refund_amount; 
                lc_comn_err_loc := 'Before Insert invoice intf call';
 
                    lc_invoice_source := 'US_OD_VENDOR_PROGRAM'; --'US_OD_AR_REFUND'; 
 
                    SELECT DISTINCT description
                    INTO            xx_lc_description
                    FROM            xx_ar_refund_trx_tmp
                    WHERE           -- trx_number = v_refund_hdr.trx_number    
                                    trx_id = v_refund_hdr.trx_id              
                      AND			trx_type = v_refund_hdr.trx_type		  
                      AND             adj_created_flag = 'Y';
                                                                                          

                    IF xx_lc_description IS NULL
                    THEN                                                                
                        lc_description :=
                                   'REF CUST#'
                                || v_refund_hdr.customer_number
                                || '/'
                                || v_refund_hdr.aops_customer_number;
                    ELSE                                                                 
                        lc_description := xx_lc_description;                             
                    END IF;                                             
                    lc_in_invoice_number := v_refund_hdr.trx_number; 
                -- Insert a record into ap_invoices_interface
                insert_invoice_interface(ln_invoice_amount ,
                                         lc_payee_name , 
                                         v_refund_hdr.trx_currency_code,
                                         lc_sob_name,
                                         lc_in_invoice_number,
                                         lc_invoice_source,
                                         lc_description,
                                         v_refund_hdr.aops_customer_number,
                                         ln_invoice_id,
                                         lc_invoice_num, 
                                         lc_sitecode,
                                         lc_org_id,
                                         lc_err_mesg);
                lc_comn_err_loc := 'After Insert invoice intf call';

                IF lc_err_mesg IS NOT NULL OR ln_invoice_id = 0
                THEN
                    lc_err_mesg :=    'Invoice Interface Insert Error: '
                                   || lc_err_mesg;
                    lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice - AP INV INTF';
                    RAISE intf_insert_error;
                END IF;

                ln_line_num := 1; 
                FOR v_trx IN c_trx(v_refund_hdr.refund_header_id)
                LOOP
                    -- Insert a record into ap_invoice_lines_interface
                    insert_invoice_lines_int(lc_org_id,
                                             ln_invoice_id,
                                             ln_line_num,
                                             v_refund_hdr.customer_number,
                                             v_trx,
                                             ln_invoice_line_id,
                                             lc_err_mesg,
                                             1);
 
                    IF ln_invoice_amount = 0
                    THEN
                        v_trx.refund_amount :=   -1
                                               * v_trx.refund_amount;
                        ln_line_num := 2;
                        insert_invoice_lines_int(lc_org_id,
                                                 ln_invoice_id,
                                                 ln_line_num,
                                                 v_refund_hdr.customer_number,
                                                 v_trx,
                                                 ln_invoice_line_id,
                                                 lc_err_mesg,
                                                 2);
                    END IF; 
                    IF lc_err_mesg IS NOT NULL OR NVL(ln_invoice_line_id,
                                                      0) = 0
                    THEN
                        od_message('M',
                                   'Error after call to Insert Invoice lines Int');
                        lc_err_mesg :=    'Invoice Line Interface Insert Error: '
                                       || lc_err_mesg;
                        lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice-AP INV LINE INTF';
                        RAISE intf_insert_error;
                    END IF;

                    BEGIN 
                        UPDATE xx_ar_refund_trx_tmp
                        SET status = 'X',
                            ap_invoice_number = lc_invoice_num,
                            ap_vendor_site_code=lc_sitecode,
                            error_flag = 'N',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE CURRENT OF c_trx;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            od_message('M',
                                          '*** Error updating AP invoice creation status for trx:'
                                       || v_trx.trx_number
                                       || ' for Customer'
                                       || v_trx.customer_number);
                    END;

                    ln_line_num :=   NVL(ln_line_num,
                                         0)
                                   + 1;
                END LOOP;

                lc_comn_err_loc := 'Before invoice stat update';

                -- Update Invoice Created Status on Transaction
                IF v_refund_hdr.trx_type = 'R'
                THEN
                    UPDATE ar_cash_receipts_all acr
                    SET attribute3 = 'Sent to AP',
                    --SET attribute10 = 'Sent to AP',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID') 
                    WHERE  cash_receipt_id = v_refund_hdr.trx_id;
                ELSE
                    UPDATE ra_customer_trx_all
                    SET attribute3 = 'Sent to AP',
                    --SET attribute10 = 'Sent to AP',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID')      
                    WHERE  customer_trx_id = v_refund_hdr.trx_id;
                END IF;

                ln_inv_count :=   NVL(ln_inv_count,
                                      0)
                                + 1;
            EXCEPTION
                WHEN intf_insert_error
                THEN 
                    od_message('M',
                                  '***Error at:'
                               || lc_comn_err_loc
                               || '. Rolling back to savepoint:'
                               || lc_savepoint);
                    od_message('M',
                               lc_err_mesg); 

                    ln_inv_err_count :=   NVL(ln_inv_err_count,
                                              0)
                                        + 1;
                    ROLLBACK TO lc_savepoint;

                    UPDATE xx_ar_refund_trx_tmp
                    SET error_flag = 'Y',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  refund_header_id = v_refund_hdr.refund_header_id;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number,
                                 attribute1)
                         VALUES (ln_conc_request_id,
                                 'R0015',
                                 v_refund_hdr.customer_number,
                                 lc_trx_type,
                                 v_refund_hdr.trx_number,
                                 lc_err_mesg);
                WHEN OTHERS
                THEN
                    od_message('E',
                                  'Error creating AP invoice for refund - Trx:'
                               || v_refund_hdr.trx_number
                               || ' for Customer'
                               || v_refund_hdr.customer_number
                               || 'Error:'
                               || SQLCODE
                               || ':'
                               || SQLERRM,
                               lc_comn_err_loc);
                    od_message('M',
                                  '***Error at:'
                               || lc_comn_err_loc
                               || '. Rolling back to savepoint:'
                               || lc_savepoint);
                    ROLLBACK TO lc_savepoint;
                    ln_inv_err_count :=   NVL(ln_inv_err_count,
                                              0)
                                        + 1;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number,
                                 attribute1)
                         VALUES (ln_conc_request_id,
                                 'R0015',
                                 v_refund_hdr.customer_number,
                                 lc_trx_type,
                                 v_refund_hdr.trx_number,
                                 lc_err_mesg);
            END;

            ln_proc_count :=   NVL(ln_proc_count,
                                   0)
                             + 1;
        END LOOP;

        COMMIT;
		--added code for defect 44915
        BEGIN
			SELECT organization_id into lc_org_id
			  FROM HR_OPERATING_UNITS
			 WHERE name='OU_US'; 
		EXCEPTION
		WHEN OTHERS THEN
			lc_org_id := NULL;
		END;
		----ended code for defect 44915
        BEGIN
            lc_comn_err_loc := NULL; 
            IF NVL(ln_inv_count,
                   0) > 0
            THEN
                lc_comn_err_loc := 'Submit "Payables Open Interface Import" program Source:US_OD_AR_REFUND';
                ln_req_id :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXIIMPT'                                                      --program
                                                         ,
                                               'Payables Open Interface Import'                            --description
                                                                               ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               lc_org_id                  									--argument1
                                                   ,
                                               lc_invoice_source,                                           --argument2
                                                                 
                                               CHR(0)                                                        --argument3
                                                     ,
                                                  'REFUND'
                                               || TO_CHAR(SYSDATE,
                                                          'DD-MON-YY')                                       --argument4
                                                                      ,
                                               CHR(0)                                                        --argument5
                                                     ,
                                               CHR(0)                                                        --argument6
                                                     ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               'N'                                                           --argument8
                                                  ,
                                               'N'                                                           --argument9
                                                  );

                IF (ln_req_id = 0)
                THEN
                    od_message('M',
                               '*** Error Submitting "Payables Open Interface Import" Source:US_OD_AR_REFUND');
                    --fnd_message.retrieve;
                    fnd_message.raise_error;
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);
                END IF;                                                                    -- Conc Program submission 1.
 
                FOR inv_recs IN (SELECT *
                                 FROM   ap_invoices_interface
                                 WHERE  request_id =ln_req_id)
                LOOP
                    IF inv_recs.status = 'PROCESSED' 
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET status = 'V',
                            inv_created_flag = 'Y',
                            ap_inv_creation_date = SYSDATE,
                            remarks = 'AP Invoice Created',
                            error_flag = 'N',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  ap_invoice_number = inv_recs.invoice_num;
                      --  AND    ap_vendor_site_code = inv_recs.vendor_site_code
                       -- AND    org_id = inv_recs.org_id 

                        BEGIN
                            SELECT trx_id,
                                   trx_type
                            INTO   ln_trx_id,
                                   lc_trx_type
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  ap_invoice_number = inv_recs.invoice_num
                            --AND    ap_vendor_site_code = inv_recs.vendor_site_code
                            AND    inv_created_flag = 'Y';

                            -- Update Invoice Created Status on Transaction
                            IF lc_trx_type = 'R'
                            THEN
                                UPDATE ar_cash_receipts_all acr
                                SET attribute3 = 'AP Invoice Created', 
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     
                                WHERE  cash_receipt_id = ln_trx_id;
                            ELSE
                                UPDATE ra_customer_trx_all
                                SET attribute3 = 'AP Invoice Created', 
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID') 
                                WHERE  customer_trx_id = ln_trx_id;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error Updating Status after successfully creating'
                                           || ' AP Invoice Number:'
                                           || inv_recs.invoice_num);
                        END;
                    ELSIF inv_recs.status = 'REJECTED'
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET inv_created_flag = 'N',
                            error_flag = 'Y',
                            status = 'X',
                            remarks =    ' Error creating AP Invoice.'
                                      || ' Review Payables Open Invoice Interface Log.',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  ap_invoice_number = inv_recs.invoice_num
                    --    AND    ap_vendor_site_code = inv_recs.vendor_site_code
                        AND    status IN('X', 'S');
                    --    AND    org_id = inv_recs.org_id;

                        BEGIN
                            SELECT trx_id,
                                   DECODE(trx_type,
                                          'R', 'Receipt',
                                          'Credit Memo'),
                                   customer_number
                            INTO   ln_trx_id,
                                   lc_trx_type,
                                   lc_cust_number
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  ap_invoice_number = inv_recs.invoice_num
                           -- AND    ap_vendor_site_code = inv_recs.vendor_site_code
                            AND    inv_created_flag = 'N'
                            AND    error_flag = 'Y';

                            -- Update Invoice Created Status on Transaction
                            IF lc_trx_type = 'R'
                            THEN
                                UPDATE ar_cash_receipts_all acr
                                SET attribute3 = 'Sent to AP', 
                                    last_update_date = SYSDATE ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')
                                WHERE  cash_receipt_id = ln_trx_id;
                            ELSE
                                UPDATE ra_customer_trx_all
                                SET attribute3 = 'Sent to AP', 
                                    last_update_date = SYSDATE  ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')  
                                WHERE  customer_trx_id = ln_trx_id;
                            END IF;

                            od_message('M',
                                          'Checking Intf errs for Inv_id:'
                                       || inv_recs.invoice_id
                                       || ' for conc req id:'
                                       || ln_conc_request_id);

                            FOR err_invs IN (SELECT *
                                             FROM   ap_interface_rejections_v
                                             WHERE  invoice_id = inv_recs.invoice_id)
                            LOOP
                                od_message('M',
                                              '*** Error AP INV INTF ERR: Vendor:'
                                           || lc_cust_number
                                           || ' Inv#'
                                           || err_invs.invoice_num
                                           || ' Msg:'
                                           || err_invs.description);

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0015',
                                             lc_cust_number,
                                             lc_trx_type,
                                             SUBSTR(inv_recs.invoice_num,
                                                    3),
                                                'Invoice Interface Error:'
                                             || err_invs.description);
                            END LOOP;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error Updating Status for invoices rejected '
                                           || 'in Payables Open Interface'
                                           || ' AP Invoice Number:'
                                           || inv_recs.invoice_num);
                        END;
                    ELSE
                        NULL;
                    END IF;
                END LOOP;                                                                                    --Inv Recs.
            --END IF;                                -- Conc Program submission.
            END IF;                                                                                      --Inv_Count > 0

            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                               Process Summary ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '');
            od_message('O',
                          'Number of Transactions Processed             :'
                       || ln_proc_count);
            od_message('O',
                          'Number of New Vendors created                :'
                       || ln_vendor_cnt);
            od_message('O',
                          'Number of New Vendors Sites created          :'
                       || ln_site_cnt);
            od_message('O',
                          'Number of Refund Invoices Created            :'
                       || ln_inv_count);
            od_message('O',
                          'Number of Invoices not created due to errors :'
                       || ln_inv_err_count);
            od_message('O',
                       '');

            IF ln_inv_err_count > 0
            THEN
                print_errors(ln_conc_request_id);
            END IF;

          --  update_dffs;
        EXCEPTION
            WHEN OTHERS
            THEN
                DECLARE
                    l_return_code  VARCHAR2(1) := 'E';
                    l_msg_count    NUMBER      := 1;
                BEGIN
                    xx_com_error_log_pub.log_error(p_program_type                => 'CONCURRENT PROGRAM',
                                                   p_program_name                => 'XXARRFNDI',
                                                   p_program_id                  => fnd_profile.VALUE('CONC_REQUEST_ID'),
                                                   p_module_name                 => 'xxfin',
                                                   p_error_location              => lc_comn_err_loc,
                                                   p_error_message_count         => 1,
                                                   p_error_message_code          => 'E',
                                                   p_error_message               =>    SQLCODE
                                                                                    || ':'
                                                                                    || SQLERRM,
                                                   p_error_message_severity      => 'FATAL',
                                                   p_notify_flag                 => 'N',
                                                   p_object_type                 => 'OD Refunds: AP Supplier/Invoice Interface',
                                                   p_object_id                   => NULL,
                                                   p_return_code                 => l_return_code,
                                                   p_msg_count                   => l_msg_count);
                    COMMIT;
                END;
        END;

        update_dffs;
        send_email_notif;
    END;

    -- This procedure is used to synchronize statuses of the DFFs
    --  on the Transactions and receipts screens.
    PROCEDURE update_dffs
    IS 
        CURSOR declined_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         1 = 1
            AND           identification_type != 'E'
            AND           status = 'D'
            AND 		  org_id=fnd_global.org_id
            AND           last_update_date <   SYSDATE
                                             - 14
            AND           refund_header_id =
                              (SELECT MAX(refund_header_id)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  1 = 1
                               AND    xart2.trx_id = xart.trx_id
                               AND    xart2.trx_type = xart.trx_type
                               AND    xart2.trx_number = xart.trx_number)
            FOR UPDATE OF status;
 
        CURSOR processed_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         identification_type != 'E'
            AND           status IN('P')
          	AND 		  org_id=fnd_global.org_id
            AND           last_update_date <   SYSDATE - 14
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            FOR UPDATE OF status;
 
        CURSOR inv_created_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         escheat_flag = 'N'
            AND           inv_created_flag = 'N'
            AND           status IN('X', 'S')
			AND 		  org_id=fnd_global.org_id
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            AND           EXISTS(
                              SELECT 1
                              FROM   ap_invoices_all api,
                                     po_vendor_sites_all avs
                              WHERE  avs.vendor_site_id = api.vendor_site_id
                              AND    invoice_num = xart.ap_invoice_number
                              AND    avs.vendor_site_code = xart.ap_vendor_site_code)
            FOR UPDATE OF status, paid_flag;

        -- Check if Invoice has been paid.
        CURSOR paid_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         inv_created_flag = 'Y'
            AND           status = 'V'
            AND 		  org_id=fnd_global.org_id
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            AND           EXISTS(
                              SELECT 1
                              FROM   ap_invoices_all api,
                                     po_vendor_sites_all avs
                              WHERE  (  NVL(amount_paid,
                                            0)
                                      + NVL(discount_amount_taken,
                                            0)) = invoice_amount
                              AND    avs.vendor_site_id = api.vendor_site_id
                              AND    api.invoice_num = xart.ap_invoice_number
                             AND    avs.vendor_site_code = xart.ap_vendor_site_code
                              )
            FOR UPDATE OF status, paid_flag;
    BEGIN 
       
        -- Mark paid records as processed.
        FOR processed_recs IN processed_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'Z',
                error_flag = 'N'
            WHERE CURRENT OF processed_cur;
        END LOOP;

        -- Mark DFFs of declined records.
        FOR declined_recs IN declined_cur
        LOOP
            -- Update Paid Status on Transaction.
            IF declined_recs.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute7 = 'Decline', 
                    attribute3 = 'Declined', 
                    last_update_date = SYSDATE,
                    last_updated_by = fnd_profile.VALUE('USER_ID')     
                WHERE  cash_receipt_id = declined_recs.trx_id;
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute7 = 'Decline',
                    attribute3 = 'Declined', 
                    last_update_date = SYSDATE ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')
                WHERE  customer_trx_id = declined_recs.trx_id;
            END IF;
        END LOOP;

        -- Check for Invoice creation Records.
        FOR inv_created_rec IN inv_created_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'V',
                inv_created_flag = 'Y',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF inv_created_cur;

            -- Update Paid Status on Transaction.
            IF inv_created_rec.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute3 = 'AP Invoice Created', 
                    last_update_date = SYSDATE,
                    last_updated_by = fnd_profile.VALUE('USER_ID') 
                WHERE  cash_receipt_id = inv_created_rec.trx_id; 
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute3 = 'AP Invoice Created', 
                    last_update_date = SYSDATE ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')
                WHERE  customer_trx_id = inv_created_rec.trx_id;
            END IF;
        END LOOP;

        -- Check for Paid Records.
        FOR paid_rec IN paid_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'P',
                paid_flag = 'Y',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF paid_cur;

            -- Update Paid Status on Transaction.
            IF paid_rec.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute3 = 'Paid', 
                    last_update_date = SYSDATE,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                    
                WHERE  cash_receipt_id = paid_rec.trx_id; 
                
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute3 = 'Paid' ,
                    last_update_date = SYSDATE, 
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                   
                WHERE  customer_trx_id = paid_rec.trx_id;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          'Error Updating DFFs. '
                       || SQLCODE
                       || ':'
                       || SQLERRM);
    END;
 
    PROCEDURE print_errors(
        p_request_id  IN  NUMBER)
    IS
    BEGIN
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        od_message('O',
                   g_print_line);
        od_message('O',
                   '                                               Error Summary');
        od_message('O',
                   g_print_line);
        od_message('O',
                   ' ');
        -- Customer # (10) Type (12) Transaction Number (18)
        od_message('O',
                      'Customer# '
                   || 'Trx Type    '
                   || 'Trx Number        '
                   || 'Error');
        od_message('O',
                   g_print_line);

        FOR v_err_recs IN (SELECT DISTINCT ec.err_code err_code,
                                           el.customer_number,
                                           el.trx_type,
                                           el.trx_number,
                                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ec.err_msg,
                                                                                   '<A1>',
                                                                                   el.attribute1),
                                                                           '<A2>',
                                                                           el.attribute2),
                                                                   '<A3>',
                                                                   el.attribute3),
                                                           '<A4>',
                                                           el.attribute4),
                                                   '<A5>',
                                                   el.attribute5) err_msg
                           FROM            xx_ar_refund_error_log el,
                                           xx_ar_refund_err_codes ec
                           WHERE           ec.err_code = el.err_code
                           AND             el.conc_request_id = NVL(p_request_id,
                                                                    fnd_profile.VALUE('CONC_REQUEST_ID'))
                           ORDER BY        1)
        LOOP
            od_message('O',
                          RPAD(SUBSTR(v_err_recs.customer_number,
                                      1,
                                      10),
                               10,
                               ' ')
                       || RPAD(SUBSTR(v_err_recs.trx_type,
                                      1,
                                      12),
                               12,
                               ' ')
                       || RPAD(SUBSTR(v_err_recs.trx_number,
                                      1,
                                      18),
                               18,
                               ' ')
                       || v_err_recs.err_code
                       || ':'
                       || v_err_recs.err_msg,
                       NULL,
                       80);
        END LOOP;
    END;

    PROCEDURE od_message(
        p_msg_type        IN  VARCHAR2,
        p_msg             IN  VARCHAR2,
        p_msg_loc         IN  VARCHAR2 DEFAULT NULL,
        p_addnl_line_len  IN  NUMBER DEFAULT 110)
    IS
        ln_char_count  NUMBER := 0;
        ln_line_count  NUMBER := 0;
    BEGIN
        IF p_msg_type = 'M'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              p_msg);
        ELSIF p_msg_type = 'O'
        THEN
            /* If message cannot fit on one line,
            -- break into multiple lines */-- fnd_file.put_line(fnd_file.output, p_msg);
            IF NVL(LENGTH(p_msg),
                   0) > 120
            THEN
                FOR x IN 1 ..(  TRUNC(  (  LENGTH(p_msg)
                                         - 120)
                                      / p_addnl_line_len)
                              + 2)
                LOOP
                    ln_line_count :=   NVL(ln_line_count,
                                           0)
                                     + 1;

                    IF ln_line_count = 1
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                          SUBSTR(p_msg,
                                                 1,
                                                 120));
                        ln_char_count :=   NVL(ln_char_count,
                                               0)
                                         + 120;
                    ELSE
                        fnd_file.put_line(fnd_file.output,
                                             LPAD(' ',
                                                    120
                                                  - p_addnl_line_len,
                                                  ' ')
                                          || SUBSTR(LTRIM(p_msg),
                                                      ln_char_count
                                                    + 1,
                                                    p_addnl_line_len));
                        ln_char_count :=   NVL(ln_char_count,
                                               0)
                                         + p_addnl_line_len;
                    END IF;
                END LOOP;
            ELSE
                fnd_file.put_line(fnd_file.output,
                                  p_msg);
            END IF;
        ELSIF p_msg_type = 'E'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              p_msg);
       
        END IF;
    END od_message;

    FUNCTION get_status_descr(
        p_status_code   IN  VARCHAR2,
        p_escheat_flag  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF p_status_code = 'I'
        THEN
            RETURN('01. Identified for Refund');
        ELSIF p_status_code = 'D'
        THEN
            RETURN('02. Declined');
        ELSIF p_status_code = 'W'
        THEN
            RETURN('03. Approved for Adjustment/Write-off');
        ELSIF p_status_code = 'A'
        THEN
            RETURN('04. Adjustment/Write-off Created');
        ELSIF p_status_code = 'S'
        THEN
            RETURN('05. Vendor Created/Matched');
        ELSIF p_status_code = 'X'
        THEN
            IF p_escheat_flag = 'Y'
            THEN
                RETURN('08. Transferred to Abandoned Property database');
            ELSE
                RETURN('06. Transferred to AP');
            END IF;
        ELSIF p_status_code = 'V'
        THEN
            RETURN('07. Invoice Created');
        ELSIF p_status_code = 'P'
        THEN
            IF p_escheat_flag = 'Y'
            THEN
                RETURN('10. Processed - Ready to Purge');
            ELSE
                RETURN('09. Paid - Ready to Purge');
            END IF; 
        ELSIF p_status_code = 'Z'
        THEN
            RETURN('11. Processed Escheat/Non-Escheat that crossed 14 days');
        ELSE
            RETURN p_status_code;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN p_status_code;
    END;
 
    procedure SEND_EMAIL_NOTIF 
    IS
      CURSOR cur is
      select rpad(decode(trx_type,'C','Credit Memo','R','Receipt',trx_type),20,' ')
            ||rpad(trx_number,25,' ')
						||Lpad(To_Char(refund_amount,'99G999G990D00'),19,' ') 
            ||'   '
            ||inv_created_flag
            ||'          '
            ||rpad(substr(remarks,1,81),'81',' ') log_msg
                        from xx_ar_refund_trx_tmp
                        where org_id=fnd_global.org_id
                        and adj_created_flag='Y'
                        and (inv_created_flag='N'
                        OR error_flag='Y')
                        and adj_creation_date>=
                          (  select b.actual_start_date  
                                          from  (
                                                 select rownum as rn, cp.actual_start_date 
                                                 from (
                                                       select actual_start_date  
                                                       from   fnd_concurrent_requests
                                                       where  concurrent_program_id = (select concurrent_program_id
                                                                                       from   fnd_concurrent_programs_vl
                                                                                       where  user_concurrent_program_name = 'OD: US VPS Refunds - Create Refunds'
                                                                                       )
                                                       order by actual_start_date desc) cp) b
                                          where  rn = 1 
                                );
          CURSOR cur_refund_sum 
          IS 
          select Lpad(To_Char(SUM(refund_amount),'99G999G990D00'),19,' ')sum_refund_amt
                        from xx_ar_refund_trx_tmp
                        where org_id=fnd_global.org_id
                        and adj_created_flag='Y'
                        and inv_created_flag='Y'
                        and error_flag='N'
                        and adj_creation_date>=
                          ( select b.actual_start_date  
                                          from  ( select rownum as rn, cp.actual_start_date 
                                                 from (
                                                       select actual_start_date  
                                                       from   fnd_concurrent_requests
                                                       where  concurrent_program_id = (select concurrent_program_id
                                                                                       from   fnd_concurrent_programs_vl
                                                                                       where  user_concurrent_program_name = 'OD: US VPS Refunds - Create Refunds'
                                                                                       )
                                                       order by actual_start_date desc) cp) b
                                          where  rn = 1 );

             lc_conn                                      UTL_SMTP.connection;
             lc_attach_text                               VARCHAR2 (32767);
             lc_success_data                              varchar2(32767);
             lc_exp_data                                  varchar2(32767);
             lc_err_nums                                  NUMBER := 0;
             lc_request_id                                NUMBER := fnd_global.conc_request_id;
             lc_mail_from                                 VARCHAR2(100);
             lc_mail_to                                   VARCHAR2(100); 
             lc_mail_request_id                           NUMBER;
             lv_row_cnt                                   NUMBER:=0;
             lv_refund_sum                                NUMBER;
   BEGIN  
                BEGIN
                        SELECT target_value1,target_value2 INTO  lc_mail_from,lc_mail_to
                         FROM xx_fin_translatedefinition xftd
                            , xx_fin_translatevalues xftv
                        WHERE xftv.translate_id = xftd.translate_id
                          AND xftd.translation_name ='OD_VPS_TRANSLATION'
                          AND source_value1='REFUNDS'
                          AND NVL (xftv.enabled_flag, 'N') = 'Y';
                 
                 EXCEPTION WHEN OTHERS THEN
                 fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM); 
                 fnd_log.STRING (fnd_log.level_statement,
                                 'xx_vps_ar_refunds_pkg: SEND_EMAIL_NOTIF',
                                 'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM
                                ); 
                 END; 
                 
              lc_success_data :='Following Receipts and Credit Memos Processed in EBS Successfully at '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||CHR(10);
              --lc_success_data :=lc_success_data||'Note: AP Invoices are staged; And will be created when the Import Program runs as part of AP Batch.'||CHR(10);
              lc_success_data :=lc_success_data||'---------------------------------------------------------------------------'
                                               ||CHR(10);
              lc_success_data :=lc_success_data||'Transaction Type    '||'Transaction Number       '||'     Refund Amount'
                                               ||CHR(10);
              LC_SUCCESS_DATA :=LC_SUCCESS_DATA||'---------------------------------------------------------------------------'
                                               ||CHR(10);
              FOR r in (select rpad(decode(trx_type,'C','Credit Memo','R','Receipt',trx_type),20,' ')
                              ||rpad(trx_number,25,' ')
                              ||Lpad(To_Char(refund_amount,'99G999G990D00'),19,' ') log_msg
                        from xx_ar_refund_trx_tmp
                        where org_id=fnd_global.org_id
                        and adj_created_flag='Y'
                        and inv_created_flag='Y'
                        and error_flag='N'
                        and adj_creation_date>=
                          ( select b.actual_start_date  
                                          from  ( select rownum as rn, cp.actual_start_date 
                                                 from (
                                                       select actual_start_date  
                                                       from   fnd_concurrent_requests
                                                       where  concurrent_program_id = (select concurrent_program_id
                                                                                       from   fnd_concurrent_programs_vl
                                                                                       where  user_concurrent_program_name = 'OD: US VPS Refunds - Create Refunds'
                                                                                       )
                                                       order by actual_start_date desc) cp) b
                                          where  rn = 1 
                                )  
                          )
                    LOOP
                    lv_row_cnt := lv_row_cnt + 1;
                    lc_success_data :=lc_success_data||r.log_msg||CHR(10) ; 
                        IF length(lc_success_data)>32500 THEN
                          lc_success_data :=lc_success_data||'Too Many Transactions Processed, Please check Log file of Conc Req ID-'||lc_request_id||CHR(10) ;
                        EXIT;
                        END IF;
                    END LOOP; 
                IF lv_row_cnt >0 THEN
                  LC_SUCCESS_DATA :=LC_SUCCESS_DATA||chr(13)||chr(10);
                  LC_SUCCESS_DATA :=LC_SUCCESS_DATA||rpad('Count : '||lv_row_cnt,17,' ');    
                  OPEN cur_refund_sum ;
                  FETCH cur_refund_sum into lv_refund_sum;
                  CLOSE cur_refund_sum ;
                  LC_SUCCESS_DATA     := lc_success_data||Lpad(To_Char(-1*lv_refund_sum,'99G999G990D00'),17,' ')||chr(13)||chr(10);
               END IF;   
       
              lc_exp_data :=lc_exp_data||'--------------------------------------------------'||CHR(10);
              lc_exp_data :=lc_exp_data||'Following Exceptions Occured during Refund Process'||CHR(10);
              lc_exp_data :=lc_exp_data||'-----------------------------------------------------------------------------------------------------------------------'
                                       ||CHR(10);
              lc_exp_data :=lc_exp_data||'Transaction Type    '||'Transaction Number       '||'     Refund Amount'||'   Status'||'      Remarks                  '
                                       ||CHR(10);
              lc_exp_data :=lc_exp_data||'-----------------------------------------------------------------------------------------------------------------------'
                                       ||CHR(10);
        
        FOR e in cur
              LOOP
                lc_exp_data :=lc_exp_data|| e.log_msg||CHR(10);  
                lc_err_nums := cur%ROWCOUNT;  
                  IF length(lc_exp_data)>31000 THEN
                  lc_exp_data :=lc_exp_data
                                ||'Too Many Errors, Please check Log file of Conc Req ID-'
                                ||lc_request_id
                                ||CHR(10) ;
                  EXIT;
                  END IF;
              END LOOP; 
               
        IF lc_err_nums=0 THEN
              lc_exp_data :=lc_exp_data
                            ||'No Exceptions Found'
                            ||CHR(10);
        END IF;
        
        lc_exp_data :=lc_exp_data||'-------------------------------------------------------------------------------'||CHR(10);
        lc_attach_text:= SUBSTR(lc_success_data
								||chr(10)
								||lc_exp_data,1,32767);
                
         
        lc_conn := xx_pa_pb_mail.begin_mail (sender          =>  lc_mail_from,
                                            recipients      =>  lc_mail_to,
                                            cc_recipients   => NULL,
                                            subject         => 'AR VPS Refund Status Report'
                                            ); 
              
               --Attach text in the mail                                              
       xx_pa_pb_mail.write_text (conn   => lc_conn,
                                 message   => lc_attach_text);
       --End of mail                                    
       xx_pa_pb_mail.end_mail (conn => lc_conn);
      
       fnd_file.put_line(fnd_file.log,'lc_attach_text'||lc_attach_text);  
                
   EXCEPTION           
      WHEN OTHERS
      THEN
           fnd_file.put_line(fnd_file.log,'Unable to send mail '||SQLERRM);
           fnd_file.put_line(fnd_file.log,SQLERRM);
           fnd_log.STRING (fnd_log.level_statement,
                         'xx_vps_ar_refunds_pkg'||'SEND_EMAIL_NOTIF',
                         SQLERRM
                        ); 
   END;  
   
    PROCEDURE insert_into_int_tables(
        errbuf   OUT  VARCHAR2,
        retcode  OUT  NUMBER)
    IS
        ln_open_credits_count  NUMBER := 0;
        ln_open_trans_count    NUMBER := 0;
        ln_total_records       NUMBER := 0;
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_open_trans_itm';

            fnd_file.put_line(fnd_file.LOG,
                                 'Truncate Ends for xx_ar_open_trans_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));  
        END;

        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.xx_ar_open_credits_itm';

            fnd_file.put_line(fnd_file.LOG,
                                 'Truncate Ends for xx_ar_open_credits_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS')); 
            fnd_file.put_line(fnd_file.LOG,
                              '');                                            
        END;

        BEGIN 
            INSERT INTO xx_ar_open_trans_itm
                (SELECT /*+PARALLEL(APS,8) FULL(APS)*/
                        *
                 FROM   ar_payment_schedules_all aps
                 WHERE  aps.status = 'OP'
                 AND aps.org_id=fnd_global.org_id
                 );

            ln_open_trans_count := SQL%ROWCOUNT;
            fnd_file.put_line(fnd_file.LOG,
                                 'Inserted in xx_ar_open_trans_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));   
            fnd_file.put_line(fnd_file.LOG,
                                 'Total number of records inserted in xx_ar_open_trans_itm '
                              || ln_open_trans_count
                              || ' rows');            
            fnd_file.put_line(fnd_file.LOG,
                              '');                        
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Insertion failed in xx_ar_open_trans_itm');     
                fnd_file.put_line(fnd_file.LOG,
                                  '');                                       
        END;

        COMMIT;

        BEGIN 
            INSERT      /*+ PARALLEL(XAOTI2,8) */INTO xx_ar_open_credits_itm xaoti2
                (SELECT /*+ FULL(XAOTI) PARALLEL(XAOTI,8) */
                        'NON-OM' SOURCE,
                        xaoti.customer_id,
                        xaoti.cash_receipt_id,
                        xaoti.customer_trx_id,
                        xaoti.CLASS,
                        acr.cash_receipt_id trx_id,
                        xaoti.trx_number,
                        xaoti.trx_date,
                        xaoti.invoice_currency_code,
                        xaoti.amount_due_remaining,
                        xaoti.last_update_date aps_last_update_date, 
                        'Y' pre_selected_flag,
                        acr.attribute7 refund_request,
                        acr.attribute3 refund_status,
                        --acr.attribute10 refund_status,
                        xaoti.org_id,
                        NULL bill_to_site_use_id,
                        acr.customer_site_use_id,
                        NULL location_id,
                        NULL address1,
                        NULL address2,
                        NULL address3,
                        NULL city,
                        NULL state,
                        NULL province,
                        NULL postal_code,
                        NULL country,
                        acr.status cash_receipt_status,
                        NULL om_hold_status,
                        NULL om_delete_status,
                        NULL om_store_number,
                        NULL store_customer_name,
                        acr.last_updated_by
                 FROM   xx_ar_open_trans_itm xaoti,
                        ar_cash_receipts_all acr
                 WHERE  acr.cash_receipt_id = xaoti.cash_receipt_id
                 AND    acr.attribute7 like 'RP_%'
                 AND    xaoti.CLASS = 'PMT'
                 AND    acr.org_id=fnd_global.org_id
                 AND    acr.receipt_method_id NOT IN(
                            SELECT receipt_method_id
                            FROM   ar_receipt_methods arm
                            WHERE  EXISTS(
                                       SELECT 1
                                       FROM   fnd_lookup_values flv
                                       WHERE  lookup_type = 'XX_OD_AR_REFUND_RECEIPT_METHOD'
                                       AND    SYSDATE BETWEEN flv.start_date_active
                                                          AND NVL(flv.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
                                       AND    flv.enabled_flag = 'Y'
                                       AND    flv.meaning = arm.NAME))
                 AND    NOT EXISTS(
                                SELECT 1
                                FROM   xx_ar_refund_trx_tmp
                                WHERE  trx_id = xaoti.cash_receipt_id AND trx_type = 'R' AND status != 'D'
                                       AND ROWNUM = 1)
                 AND    NOT EXISTS(SELECT /*+INDEX(HCA HZ_CUST_ACCOUNTS_U1)*/
                                          1
                                   FROM   hz_cust_accounts hca
                                   WHERE  hca.cust_account_id = xaoti.customer_id AND customer_type = 'I' AND ROWNUM = 1) 
                 AND    xaoti.amount_due_remaining < 0
                 UNION ALL
                 SELECT /*+ FULL(XAOTI) PARALLEL(XAOTI,8) */
                        'NON-OM' SOURCE,
                        xaoti.customer_id,
                        xaoti.cash_receipt_id,
                        xaoti.customer_trx_id,
                        xaoti.CLASS,
                        rct.customer_trx_id trx_id,
                        xaoti.trx_number,
                        xaoti.trx_date,
                        xaoti.invoice_currency_code,
                        xaoti.amount_due_remaining,
                        xaoti.last_update_date aps_last_update_date, 
                        'Y' pre_selected_flag,
                        rct.attribute7 refund_request,
                        rct.attribute3 refund_status, 
                        xaoti.org_id,
                        rct.bill_to_site_use_id,
                        NULL customer_site_use_id,
                        NULL location_id,
                        NULL address1,
                        NULL address2,
                        NULL address3,
                        NULL city,
                        NULL state,
                        NULL province,
                        NULL postal_code,
                        NULL country,
                        'UNAPP' cash_receipt_status,
                        NULL om_hold_status,
                        NULL om_delete_status,
                        NULL om_store_number,
                        NULL store_customer_name,
                        rct.last_updated_by
                 FROM   xx_ar_open_trans_itm xaoti,
                        ra_customer_trx_all rct
                 WHERE  xaoti.customer_trx_id = rct.customer_trx_id
                 AND rct.org_id=fnd_global.org_id
                 AND rct.attribute7 like 'RP_%'
                 AND    xaoti.CLASS IN('CM', 'INV')
                 AND    NOT EXISTS(
                            SELECT 1
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  trx_id = rct.customer_trx_id AND trx_type IN('C', 'I') AND status != 'D'
                                   AND ROWNUM = 1)
                 AND    NOT EXISTS(SELECT /*+INDEX(HCA HZ_CUST_ACCOUNTS_U1)*/
                                          1
                                   FROM   hz_cust_accounts hca
                                   WHERE  hca.cust_account_id = xaoti.customer_id AND customer_type = 'I' AND ROWNUM = 1) 
                 AND    xaoti.amount_due_remaining < 0);

            ln_open_credits_count := SQL%ROWCOUNT;
            fnd_file.put_line(fnd_file.LOG,
                                 'Inserted in xx_ar_open_credits_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));  
            fnd_file.put_line(fnd_file.LOG,
                                 'Total number of records inserted in xx_ar_open_credits_itm '
                              || ln_open_credits_count
                              || ' rows');                            
            fnd_file.put_line(fnd_file.LOG,
                              '');                
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Insertion failed in xx_ar_open_credits_itm'); 
                fnd_file.put_line(fnd_file.LOG,
                                  '');                     
        END;

        COMMIT;
        ln_total_records :=   ln_open_trans_count
                            + ln_open_credits_count;
        fnd_file.put_line(fnd_file.LOG,
                             'Total number of records for both the tables '
                          || ln_total_records
                          || ' rows');                   
        fnd_file.put_line(fnd_file.LOG,
                          '');                     
    END insert_into_int_tables;  
END xx_vps_ar_refunds_pkg;
/