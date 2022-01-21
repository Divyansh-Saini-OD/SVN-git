CREATE OR REPLACE PACKAGE BODY xx_ar_refunds_escheats_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                            Providge                               |
-- +===================================================================+
-- | Name             :    XX_AR_refunds_escheats_pkg                  |
-- | Description      :    Package for Refund Escheats File            |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0       26-JUL-2007  Petritia Sampath     Initial version        |
-- |1.1       12-JUN-2008  Sandeep Pandhare     Added Parameters       |
-- |1.2       16-JUL-2008  Sandeep Pandhare     Defect 7703            |
-- |1.3       21-JUL-2008  Brian J Looman       Defects 9143,9144,9146 |
-- |1.4       17-SEP-2008  Sandeep Pandhare     Defects 11347          |
-- |1.4       16-OCT-2008  Deepak Gowda         Defects 11983          |
-- |1.4       12-Nov-2008  Sandeep Pandhare     Defects 12268          |
-- |2.0       18-APR-2011  Gaurav Agarwal       SDR Chages             |
-- |2.1       22-OCT-2015  Vasu Raparla         Removed Schema 
-- |                                             References for R12.2  |
-- +===================================================================+
   PROCEDURE xx_ar_refunds_escheats_proc (
      x_errbuf       OUT      VARCHAR2
    , x_retcode      OUT      VARCHAR2
    , p_org_id       IN       VARCHAR2
    , p_file_path    IN       VARCHAR2
    , p_ident_type   IN       VARCHAR2 DEFAULT 'N'               -- defect 7703
    , p_days_old     IN       NUMBER DEFAULT 120                 -- defect 9144
    , p_email_addr   IN       VARCHAR2 DEFAULT NULL
   )                                                             -- defect 9146
   IS
      lc_file_handle    UTL_FILE.file_type;
      lc_errormsg       VARCHAR2 (2000);
      lc_file_name      VARCHAR2 (50);
      lc_type           VARCHAR2 (30);
      lc_diff_type      VARCHAR2 (30);
      lc_first_name     VARCHAR2 (30);
      lc_last_name      VARCHAR2 (30);
      lc_party_name     VARCHAR2 (30);
      lc_org_name       VARCHAR2 (30);
      lc_firstname      VARCHAR2 (30);
      lc_lastname       VARCHAR2 (30);
      lc_flag           VARCHAR2 (30);
      lc_code           VARCHAR2 (30);
      lc_fiscal_code    VARCHAR2 (30);
      lc_delimiter      VARCHAR2 (1)       := CHR (9);
      lc_country        VARCHAR2 (3);
      ln_total_amount   NUMBER             := 0;
      ln_total_recs     NUMBER             := 0;
      lc_dir_path       VARCHAR2 (400);
      ln_request_id     NUMBER;
      ln_days_old       NUMBER             := NVL (p_days_old, 120);
      lb_result         BOOLEAN;
      lc_conc_phase     VARCHAR2 (1000);
      lc_conc_status    VARCHAR2 (1000);
      lc_dev_phase      VARCHAR2 (1000);
      lc_dev_status     VARCHAR2 (1000);
      lc_return_msg     VARCHAR2 (1000);

      CURSOR lcu_refund_escheats
      IS
         SELECT        ROWID, customer_id, customer_number
                     , NVL(NVL (alt_state, alt_province), 'DE') filingcode  --defect 12268
                     , TO_CHAR (identification_date, 'MM/DD/YYYY') iden_date
                     , refund_amount, trx_number, payee_name, alt_address1
                     , alt_address2, alt_city
                     , NVL (alt_state, alt_province) alt_state_province
                     , alt_country, alt_postal_code, status, remarks
                     , CASE
                          WHEN trx_type = 'R'
                             THEN (SELECT receipt_date
                                     FROM ar_cash_receipts_all
                                    WHERE org_id = xart.org_id
                                      AND cash_receipt_id = xart.trx_id
                                      AND ROWNUM = 1)
                          ELSE (SELECT trx_date
                                  FROM ra_customer_trx_all
                                 WHERE org_id = xart.org_id
                                   AND customer_trx_id = xart.trx_id
                                   AND ROWNUM = 1)
                       END trx_date
                  FROM xx_ar_refund_trx_tmp xart
                 WHERE org_id = NVL (p_org_id, fnd_profile.VALUE ('ORG_ID'))
                   AND adj_created_flag = 'Y'
                   AND escheat_flag = 'Y'
--v 2.0 added 
                    AND  (( status = 'A' and identification_type != 'OM' ) 
                   or (identification_type = 'OM' and status = 'V'   )) 
--v 2.0 added 
                   AND ((p_ident_type = 'Y'                       -- defect 7703
                         AND identification_type = 'OM'
                         AND identification_date < SYSDATE - ln_days_old
                        )                                         -- defect 9144
                        OR (p_ident_type = 'N'                    -- defect 7703
                            AND identification_type <> 'OM'
                           )
                       )
         FOR UPDATE OF status, remarks;

      TYPE t_escheats_tab IS TABLE OF lcu_refund_escheats%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_escheats_tab    t_escheats_tab;

      CURSOR c_dir
      IS
         SELECT directory_path
           FROM dba_directories
          WHERE directory_name = p_file_path;
   BEGIN
      x_retcode := 0;
      x_errbuf := NULL;

-- =============================================================================
-- construct the escheat file name based on the parameters and current date
-- =============================================================================
      IF (p_ident_type = 'Y')
      THEN
         lc_file_name :=
             'XXARESCHEATS_OM_' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI')
             || '.txt';
      ELSIF (p_ident_type = 'N')
      THEN
         lc_file_name :=
             'XXARESCHEATS_AR_' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI')
             || '.txt';
         ln_days_old := 0;
      -- for AR, ignore the parameter, this should always be zero
      ELSE
         lc_file_name :=
                'XXARESCHEATS_' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI')
                || '.txt';
      END IF;

-- =============================================================================
-- fetch the directory path for the given directory name
-- =============================================================================
      OPEN c_dir;

      FETCH c_dir
       INTO lc_dir_path;

      CLOSE c_dir;

      fnd_file.put_line (fnd_file.LOG, ' Directory: ' || p_file_path);
      fnd_file.put_line (fnd_file.LOG, '   Path: ' || lc_dir_path);

-- =============================================================================
-- fail if the directory did not exist in DBA_DIRECTORIES
-- =============================================================================
      IF (lc_dir_path IS NULL)
      THEN
         raise_application_error (-20001
                                ,    'Directory '
                                  || p_file_path
                                  || ' is not defined in DBA_DIRECTORIES.'
                                  || CHR (10)
                                  || '  Please define a valid Directory name.'
                                 );
      END IF;

-- =============================================================================
-- fetch the escheat records that are eligible for abandoned property
-- =============================================================================
      OPEN lcu_refund_escheats;

      FETCH lcu_refund_escheats
      BULK COLLECT INTO l_escheats_tab;

      CLOSE lcu_refund_escheats;

-- =============================================================================
-- if records are found, process the escheat records
-- =============================================================================
      IF (l_escheats_tab.COUNT > 0)
      THEN
-- =============================================================================
-- open a new file for writing the escheat records to
-- =============================================================================
         lc_file_handle :=
                         UTL_FILE.fopen (p_file_path, lc_file_name, 'w', 32767);

-- =============================================================================
-- loop through each escheat record
-- =============================================================================
         FOR i_index IN l_escheats_tab.FIRST .. l_escheats_tab.LAST
         LOOP
-- =============================================================================
-- clear (reset) all the local variables
-- =============================================================================
            lc_diff_type := NULL;
            lc_firstname := NULL;
            lc_lastname := NULL;
            lc_org_name := NULL;
            lc_flag := NULL;
            lc_fiscal_code := NULL;
            lc_country := NULL;

-- =============================================================================
-- get the customer information for the current escheat record
-- =============================================================================
            BEGIN
               SELECT hp.person_first_name, hp.person_last_name
                    , hp.party_name, hp.party_type
                    , NVL (hp.jgzz_fiscal_code, NULL)
                 INTO lc_first_name, lc_last_name
                    , lc_party_name, lc_type
                    , lc_code
                 FROM hz_parties hp, hz_cust_accounts hca
                WHERE hp.party_id = hca.party_id
                  AND hca.cust_account_id = l_escheats_tab (i_index).customer_id;

-- =============================================================================
-- if party for this customer is an organization
-- =============================================================================
               IF lc_type = 'ORGANIZATION'
               THEN
                  lc_org_name := l_escheats_tab (i_index).payee_name;
                  lc_diff_type := 'B';

                  IF lc_code IS NOT NULL
                  THEN
                     lc_flag := 'N';
                     lc_fiscal_code := lc_code;
                  ELSE
                     lc_flag := NULL;
                  END IF;
-- =============================================================================
-- if party for this customer is a person
-- =============================================================================
               ELSIF lc_type = 'PERSON'
               THEN
                  lc_firstname := lc_first_name;
                  lc_lastname := lc_last_name;
                  lc_diff_type := 'P';

                  IF lc_code IS NOT NULL
                  THEN
                     lc_flag := 'Y';
                     lc_fiscal_code := lc_code;
                  ELSE
                     lc_flag := NULL;
                  END IF;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

-- =============================================================================
-- get the territory code for the country
-- =============================================================================
            BEGIN
               SELECT iso_territory_code
                 INTO lc_country
                 FROM fnd_territories
                WHERE territory_code = l_escheats_tab (i_index).alt_country;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

-- =============================================================================
-- output the escheat record to the new file
-- =============================================================================
            UTL_FILE.put_line (lc_file_handle
                             , l_escheats_tab (i_index).filingcode   -- l_escheats_tab (i_index).alt_state_province Defect 12268
                               || lc_delimiter
                               --|| NVL(l_escheats_tab(i_index).iden_date, TO_CHAR(SYSDATE,'MM/DD/YYYY') )
                               || l_escheats_tab (i_index).trx_date
                               || lc_delimiter
                               || l_escheats_tab (i_index).refund_amount
                               || lc_delimiter
                               || l_escheats_tab (i_index).customer_number
                               || lc_delimiter
                               || l_escheats_tab (i_index).trx_number
                               || lc_delimiter
                               || lc_diff_type
                               || lc_delimiter
                               || lc_flag
                               || lc_delimiter
                               || lc_fiscal_code
                               || lc_delimiter
                               || lc_org_name
                               || lc_delimiter
                               || lc_firstname
                               || lc_delimiter
                               || lc_lastname
                               || lc_delimiter
                               || l_escheats_tab (i_index).alt_address1
                               || lc_delimiter
                               || l_escheats_tab (i_index).alt_address2
                               || lc_delimiter
                               || l_escheats_tab (i_index).alt_city
                               || lc_delimiter
                               || l_escheats_tab (i_index).alt_state_province
                               || lc_delimiter
                               || lc_country
                               || lc_delimiter
                               || l_escheats_tab (i_index).alt_postal_code
                              );
-- =============================================================================
-- calculate the summaries for the escheat records
-- =============================================================================
            ln_total_amount :=
                        ln_total_amount + l_escheats_tab (i_index).refund_amount;
            ln_total_recs := ln_total_recs + 1;

-- =============================================================================
-- update the current record as processed, and note the escheat file name
-- =============================================================================
            UPDATE xx_ar_refund_trx_tmp
               SET status = 'X'
                 , remarks = 'Escheat File: ' || lc_file_name
             WHERE ROWID = l_escheats_tab (i_index).ROWID;
         END LOOP;

-- =============================================================================
-- close the escheat file
-- =============================================================================
         IF (UTL_FILE.is_open (lc_file_handle))
         THEN
            UTL_FILE.fclose (lc_file_handle);
         END IF;

-- =============================================================================
-- output these details to the Concurrent Program Output (will also be emailed)
-- =============================================================================
         fnd_file.put_line
            (fnd_file.output
           ,    'The Escheats file, "'
             || lc_file_name
             || '",'
             || ' has been successfully created in directory "'
             || lc_dir_path
             || '"'
             || ' and is scheduled to be transferred to the Abandoned Property Database.'
            );
         fnd_file.put_line (fnd_file.output, '');
         fnd_file.put_line
            (fnd_file.output
           ,    'A Total of '
             || TRIM (TO_CHAR (ln_total_amount, '$999,999,990.00'))
             || ' in '
             || TRIM (TO_CHAR (ln_total_recs, '999,999,990'))
             || ' abandoned property transactions have been added to this new Escheats File.'
            );
         fnd_file.put_line (fnd_file.output, '');
         fnd_file.put_line
            (fnd_file.output
           ,    'Please create the Journal Entry to debit the Clearing account and'
             || ' credit the Abandoned Property account for this amount.'
            );
-- =============================================================================
-- Submit "Common File Copy" to copy file to /xxfin/ftp/out/escheats/
--   Defect 11347
-- =============================================================================
         ln_request_id :=
            fnd_request.submit_request
               (application => 'XXFIN'
              ,                                        -- application short name
                program => 'XXCOMFILCOPY'
              ,                                       -- concurrent program name
                description => NULL
              ,                                -- additional request description
                start_time => NULL
              ,                                           -- request submit time
                sub_request => FALSE
              ,                                        -- is this a sub-request?
                argument1 => lc_dir_path || '/' || lc_file_name
              ,                                                   -- Source file
                argument2 => '$XXFIN_DATA/ftp/out/escheats/' || lc_file_name
              ,                                              -- Destination file
                argument3 => ''
              ,                                                 -- Source string
                argument4 => ''
               );                                          -- Destination string

-- ===========================================================================
-- check status of "common file copy" request
-- ===========================================================================
         IF (ln_request_id > 0)
         THEN
            COMMIT;

-- ===========================================================================
-- wait on the completion of this copy file request
-- ===========================================================================
            IF NOT fnd_concurrent.wait_for_request
                                   (request_id => ln_request_id
                                  , INTERVAL => 5
                                  ,                        -- check every 5 secs
                                    max_wait => 60 * 60
                                  ,                   -- check for max of 1 hour
                                    phase => lc_conc_phase
                                  , status => lc_conc_status
                                  , dev_phase => lc_dev_phase
                                  , dev_status => lc_dev_status
                                  , MESSAGE => lc_return_msg
                                   )
            THEN
               x_retcode := 1;
               x_errbuf :=
                     'XXCOMFILCOPY - Errors waiting on the "Common File Copy" program. '
                  || lc_return_msg;
            END IF;

-- =============================================================================
-- Set program status in Warning if "Common File Copy" fails
-- =============================================================================
            IF (lc_conc_status = 'Error')
            THEN
               x_retcode := 1;
               x_errbuf :=
                        'XXCOMFILCOPY - "Common File Copy" completed in Error.';
            END IF;
         ELSE
            fnd_message.retrieve (lc_return_msg);
            x_retcode := 1;
            x_errbuf :=
                  'XXCOMFILCOPY - Errors submitting the "Common File Copy" program. '
               || lc_return_msg;
         END IF;

-- =============================================================================
-- If escheat file is created and transferred successfully, then submit the
--  "Common Emailer Program" to send the output to the given recipients
-- =============================================================================
         IF (x_errbuf IS NULL)
         THEN
            ln_request_id :=
               fnd_request.submit_request
                  ('XXFIN'
                 , 'XXODXMLMAILER'
                 , NULL
                 , TO_CHAR (SYSDATE + 10 / (24 * 60 * 60)
                          , 'YYYY/MM/DD HH24:MI:SS'
                           )
                 -- schedule 10 seconds from now
               ,   FALSE
                 , NULL
                 , p_email_addr
                 , 'Alert for Abandoned Property - Escheats File created - DO NOT REPLY TO THIS MESSAGE'
                 , 'Please review the attached program output for details and action items...'
                 , 'N'
                 , fnd_global.conc_request_id
                 , 'XXARRFNDE'
                  );
         END IF;
      ELSE
-- =============================================================================
-- No Data was found
-- =============================================================================
         fnd_file.put_line
            (fnd_file.output
           , 'No records exist in XX_AR_REFUND_TRX_TMP that are eligible for escheat.'
            );
         fnd_file.put_line
            (fnd_file.LOG
           , 'No records exist in XX_AR_REFUND_TRX_TMP that are eligible for escheat.'
            );
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
-- =============================================================================
-- Rollback any changes
-- =============================================================================
         ROLLBACK;

-- =============================================================================
-- close the file, if still open
-- =============================================================================
         IF (UTL_FILE.is_open (lc_file_handle))
         THEN
            UTL_FILE.fclose (lc_file_handle);
         END IF;

-- =============================================================================
-- return the errors
-- =============================================================================
         DBMS_OUTPUT.put_line (SQLERRM);
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         x_retcode := 2;
         x_errbuf := SQLERRM;
-- =============================================================================
-- log these errors in the OD common error log
-- =============================================================================
         xx_com_error_log_pub.log_error
              (p_program_type => 'CONCURRENT PROGRAM'
             , p_program_name => 'XXARRFNDE'
             , p_program_id => fnd_global.conc_program_id
             , p_module_name => 'AR'
             , p_error_location => 'Error in E0055 Create Escheat File Program'
             , p_error_message_count => 1
             , p_error_message_code => 'E'
             , p_error_message => SQLERRM
             , p_error_message_severity => 'Major'
             , p_notify_flag => 'N'
             , p_object_type => 'XX_AR_REFUNDS_ESCHEATS_PROC'
              );
-- =============================================================================
-- re-raise the original error
-- =============================================================================
         RAISE;
   END;
END;

/