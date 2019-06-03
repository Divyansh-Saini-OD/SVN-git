/* Formatted on 2015/01/24 00:09 (Formatter Plus v4.8.8) */
--SET VERIFY OFF;
--WHENEVER SQLERROR CONTINUE;
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY xx_cdh_hvop_upload_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_HVOP_UPLOAD_PKG.pkb                         |
-- | Description :  HVOP error upload process program                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ========================= |
-- |DRAFT 1a  20-NOV-2014 Sridhar Pamu       Initial draft version     |
-- |1.1       05-Jan-2016 Manikant Kasu      Removed schema alias as   | 
-- |                                         part of GSCC R12.2.2      |
-- |                                         Retrofit                  |
-- | 1.2      03-JUN-2018  Dinesh Nagapuri   Replaced V$INSTANCE with DB_Name for LNS   			 |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        :  UPLOAD_HVOP_ERRORS                                |
-- | Description :  This procedure will be registered as a Concurrent  |
-- |                Program and will be  inserting the customer and site |
-- |                Records into xxod_hz_summary table and submits     |
-- |                 OD: CDH Force Activate Accounts Or Sites Program  |
-- |                and submit AOPS conversion batches.QC 31926        |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE upload_hvop_errors (
      p_errbuf    OUT NOCOPY   VARCHAR2,
      p_retcode   OUT NOCOPY   VARCHAR2
   )
   AS
      CURSOR accounts_cur
      IS
         SELECT DISTINCT '1' customer_site, m.MESSAGE_TEXT,
                         hc.orig_system_reference customer_osr,
                         SUBSTR (hs.orig_system_reference, 1, 17)
                                                                 ship_to_osr,
                         SUBSTR (hs1.orig_system_reference, 1,
                                 17) bill_to_osr,
                         h.org_id, h.ship_to_org_id, h.invoice_to_org_id,
                         h.ship_to_org, h.invoice_to_org
                    FROM oe_headers_iface_all h,
                         oe_processing_msgs_vl m,
                         hz_cust_accounts_all hc,
                         hz_cust_site_uses_all hs,
                         hz_cust_site_uses_all hs1
                   WHERE h.error_flag = 'Y'
                     AND h.orig_sys_document_ref = m.original_sys_document_ref
                     AND h.order_source_id = m.order_source_id
                     AND h.sold_to_org_id = hc.cust_account_id(+)
                     AND h.ship_to_org_id = hs.site_use_id(+)
                     AND h.invoice_to_org_id = hs1.site_use_id(+)
                     AND ((   MESSAGE_TEXT LIKE '%Validation%Ship%'
                           OR MESSAGE_TEXT LIKE '%Bill%'
                          )
                         )
         UNION
         SELECT DISTINCT '2' customer, 'Customer Validation',
                         hc.orig_system_reference customer_osr,
                         NULL ship_to_osr, NULL bill_to_osr, h.org_id, NULL,
                         NULL, NULL, NULL
                    FROM oe_headers_iface_all h,
                         oe_processing_msgs_vl m,
                         hz_cust_accounts_all hc,
                         hz_cust_site_uses_all hs,
                         hz_cust_site_uses_all hs1
                   WHERE h.error_flag = 'Y'
                     AND h.orig_sys_document_ref = m.original_sys_document_ref
                     AND h.order_source_id = m.order_source_id
                     AND h.sold_to_org_id = hc.cust_account_id(+)
                     AND h.ship_to_org_id = hs.site_use_id(+)
                     AND h.invoice_to_org_id = hs1.site_use_id(+)
                     AND (MESSAGE_TEXT LIKE '%Val%Customer%')
                ORDER BY 1;

      l_cust_account_id         NUMBER;
      l_object_version_number   NUMBER;
      l_success_count           NUMBER          := 0;
      l_error_count             NUMBER          := 0;
      l_total_records           NUMBER          := 0;
      l_site_use_error_count    NUMBER          := 0;
      l_site_use_succ_count     NUMBER          := 0;
      l_return_status           VARCHAR2 (1);
      l_status                  VARCHAR2 (1)    := NULL;
      l_sql_query               VARCHAR2 (2000);
      l_sync_back_aops_time     NUMBER;
      lt_conc_request_id        NUMBER          := 0;
      lt_site_conc_request_id   NUMBER          := 0;
      l_user_id                 NUMBER;
      l_resp_id                 NUMBER;
      l_resp_appl_id            NUMBER;
      l_customer_count          NUMBER          := 0;
      l_site_count              NUMBER          := 0;
      l_db_link_name            VARCHAR2 (50);    --:= 'STUBBY.NA.ODCORP.NET';
      l_commit_flag             VARCHAR2 (1)    := 'Y';
      l_cust_batch_id           NUMBER;
      l_site_batch_id           NUMBER;
      l_instance                VARCHAR2 (50);
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Running Procedure Automate HVOP Procedure .......'
                        );

      BEGIN
         SELECT TO_CHAR (SYSDATE, 'DDMMRRHH24MI'),
                TO_CHAR (SYSDATE, 'DDMMRRHH24MI') + 1
           INTO l_cust_batch_id,
                l_site_batch_id
           FROM DUAL;
      END;

      BEGIN
	  /*
         SELECT instance_name
           INTO l_instance
           FROM v$instance;
	*/
	  	SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8) 		-- Changed from V$instance to DB_NAME
		INTO l_instance
		FROM dual;
      END;
	  
	
      IF l_instance IN ('GSIPSTGB', 'GSIUATGB')
      THEN
         l_db_link_name := 'AS400.NA.ODCORP.NET';
      ELSE
         l_db_link_name := 'STUBBY.NA.ODCORP.NET';
      END IF;

      FOR i IN accounts_cur
      LOOP
         EXIT WHEN accounts_cur%NOTFOUND;

         IF i.MESSAGE_TEXT IN ('Customer Validation')
         THEN
            l_customer_count := l_customer_count + 1;

            BEGIN
               INSERT INTO xxod_hz_summary
                           (summary_id, account_orig_system_reference
                           )
                    VALUES (l_cust_batch_id, i.customer_osr
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                                 (fnd_file.LOG,
                                     'Error while inserting Customer Data : '
                                  || SQLERRM
                                 );
            END;

            fnd_file.put_line (fnd_file.LOG,
                               'Customer to be Activated  : '
                               || i.customer_osr
                              );
         ELSIF i.MESSAGE_TEXT IN
                                ('Validation failed for the field - Ship To')
         THEN
            l_site_count := l_site_count + 1;

            BEGIN
               INSERT INTO xxod_hz_summary
                           (summary_id, acct_site_orig_sys_reference
                           )
                    VALUES (l_site_batch_id, i.ship_to_osr
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Error while inserting Ship to Data : '
                                   || SQLERRM
                                  );
            END;

            fnd_file.put_line (fnd_file.LOG,
                                  'Ship To Site to be Activated  : '
                               || i.ship_to_osr
                              );
         ELSIF i.MESSAGE_TEXT IN
                                ('Validation failed for the field - Bill To')
         THEN
            l_site_count := l_site_count + 1;

            BEGIN
               INSERT INTO xxod_hz_summary
                           (summary_id, acct_site_orig_sys_reference
                           )
                    VALUES (l_site_batch_id, i.bill_to_osr
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                                  (fnd_file.LOG,
                                      'Error while inserting Bill To Data : '
                                   || SQLERRM
                                  );
            END;

            fnd_file.put_line (fnd_file.LOG,
                                  'Bill To Site to be Activated  : '
                               || i.bill_to_osr
                              );
         END IF;

         COMMIT;
      END LOOP;

      fnd_file.put_line (fnd_file.output,
                            'Total Records To Process For Customers: '
                         || l_customer_count
                        );
      fnd_file.put_line (fnd_file.output,
                            'Total Records To Process For Sites : '
                         || l_site_count
                        );

      BEGIN
         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE user_name = 'ODCDH';

         SELECT responsibility_id, application_id
           INTO l_resp_id, l_resp_appl_id
           FROM fnd_responsibility_vl
          WHERE responsibility_name = 'OD (US) Customer Conversion';

         fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);

         IF (l_customer_count > 0)
         THEN
            lt_conc_request_id :=
               fnd_request.submit_request
                                (application      => 'XXCNV',
                                 program          => 'XX_CDH_ACTIVATE_SITES_ACCOUNTS',
                                 description      => NULL,
                                 sub_request      => FALSE,
                                 argument1        => 'ACCOUNT',
                                 argument2        => l_cust_batch_id,
                                 argument3        => 'A',
                                 argument4        => l_db_link_name,
                                 argument5        => l_commit_flag
                                );

            IF lt_conc_request_id > 0
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Program To Activate Customer Accounts with Request ID :'
                   || lt_conc_request_id
                   || '  '
                   || 'Started at  : '
                   || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                  );
               fnd_file.put_line (fnd_file.output, '');
               fnd_file.put_line
                    (fnd_file.output,
                        'Program To Activate Customer Accounts Started at  : '
                     || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                    );
            ELSE
               fnd_file.put_line
                    (fnd_file.LOG,
                     'Failed to submit Program To Activate Customer Accounts'
                    );
               p_retcode := 1;
            END IF;
         END IF;

         IF (l_site_count > 0)
         THEN
            lt_site_conc_request_id :=
               fnd_request.submit_request
                                (application      => 'XXCNV',
                                 program          => 'XX_CDH_ACTIVATE_SITES_ACCOUNTS',
                                 --OD: CDH Force Activate Accounts Or Sites
                                 description      => NULL,
                                 sub_request      => FALSE,
                                 argument1        => 'ACCOUNT SITE',
                                 argument2        => l_site_batch_id,
                                 argument3        => 'A',
                                 argument4        => l_db_link_name,
                                 argument5        => l_commit_flag
                                );

            IF lt_site_conc_request_id > 0
            THEN
               fnd_file.put_line
                   (fnd_file.LOG,
                       'Program To Activate Customer Sites with Request ID :'
                    || lt_site_conc_request_id
                    || '  '
                    || 'Started at  : '
                    || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                   );
               fnd_file.put_line (fnd_file.output, '');
               fnd_file.put_line
                     (fnd_file.output,
                         'Program To Activate Customer Sites Started at  : : '
                      || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                     );
            ELSE
               fnd_file.put_line
                       (fnd_file.LOG,
                        'Failed to submit Program To Activate Customer Sites'
                       );
               p_retcode := 1;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
               (fnd_file.LOG,
                   'Failed to submit Program  OD: CDH Force Activate Accounts Or Sites: '
                || SQLERRM
               );
      END;

      fnd_file.put_line (fnd_file.LOG,
                         'Procedure Upload HVOP Errors Completed'
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
                'Unexpected Error in procedure Upload HVOP Errors - Error - '
             || SQLERRM
            );
         p_errbuf :=
              'Unexpected Error in procedure Upload HVOP Errors - ' || SQLERRM;
         p_retcode := 2;
   END upload_hvop_errors;
END xx_cdh_hvop_upload_pkg;
/

SHOW ERRORS;