SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=====================================================================+
-- |                  Office Depot - CR-798				 |
-- +=====================================================================+
-- | Name        : XXCRM_REMITTO_ONETIME_SCRIPT.pks                      |
-- | Description : This procedure is One time Script to update           |
-- |		   Remit to sale channel.                                |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version     Date           Author               Remarks              |
-- |=======    ==========      ================     =====================|
-- |1.0        08/07/11       Devendra Petkar        Initial version     |
-- +=====================================================================+

CREATE OR REPLACE PACKAGE BODY xxcrm_remitto_onetime_script
IS
   PROCEDURE main (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      NUMBER,
      p_commit            IN              VARCHAR2 DEFAULT 'N',
      p_processing_flag   IN              VARCHAR2 DEFAULT ''
   )
   IS
-- Processing flag is null then process all
-- Processing flag is PROCESS_NULL. It will process only attribute25 null.
-- Processing flag is PROCESS_SAME. It will check attribute25 and attribute1 same and process them.
      l_user_id                  NUMBER;
      l_responsibility_id        NUMBER;
      l_responsibility_appl_id   NUMBER;
      lc_message                 VARCHAR2 (4000);
      l_site_use_rec             hz_cust_account_site_v2pub.cust_site_use_rec_type;
      l_customer_profile_rec     hz_customer_profile_v2pub.customer_profile_rec_type;
      l_return_status            VARCHAR2 (1);
      l_msg_count                NUMBER;
      l_msg_data                 VARCHAR2 (2000);
      l_object_version_number    NUMBER;
      --Get the log enabled profile option
      -- Creating new profile
      g_fnd_debug                VARCHAR2 (1)
                      := NVL (fnd_profile.VALUE ('REMITTO_LOG_ENABLED'), 'Y');
      l_process_null             VARCHAR2 (1);
      l_process_same             VARCHAR2 (1);

      l_processed_count		NUMBER :=0;
      l_success_count		NUMBER :=0;
      l_success_null_count	NUMBER :=0;
      l_success_same_count	NUMBER :=0;
      l_unsuccess_count		NUMBER :=0;
      l_unsuccess_null_count	NUMBER :=0;
      l_unsuccess_same_count	NUMBER :=0;
      l_nochange_count		NUMBER :=0;
      l_nochange_null_count	NUMBER :=0;
      l_nochange_same_count	NUMBER :=0;
      l_nochange_null_ca_count	NUMBER :=0;
      l_total_count		NUMBER :=0;

      CURSOR c1
      IS
         SELECT /*+ PARALLEL (prof,4) PARALLEL (asite,4) PARALLEL (uses,4) PARALLEL (acct,4) PARALLEL (psite,4) PARALLEL (loc,4) PARALLEL (rmit,4) */
                uses.site_use_id,
                SUBSTR (acct.account_number, 1, 15) account_number,
                SUBSTR (asite.orig_system_reference, 1, 20) site_osr,
                SUBSTR (loc.state, 1, 5) state,
                SUBSTR (uses.attribute25, 1, 2) old_rsc,
                SUBSTR (raddr.attribute1, 1, 2) derived_rsc,
                CAST (DECODE (TRIM (uses.attribute25),
                              NULL, 1,
                              TRIM (raddr.attribute1), NULL
                             ) AS VARCHAR2 (6)
                     ) new_rsc,
		loc.country,
		asite.org_id
           FROM apps.hz_customer_profiles prof,
                apps.hz_cust_acct_sites_all asite,
                apps.hz_cust_site_uses_all uses,
                apps.hz_cust_accounts acct,
                apps.hz_party_sites psite,
                apps.hz_locations loc,
                apps.ra_remit_tos_all rmit,
                (SELECT /*+ PARALLEL (TERR,4) PARALLEL (ADDR,4) PARALLEL (PARTY_SITE,4) PARALLEL (LOC,4) */
                        addr.cust_acct_site_id address_id,
                        addr.attribute1 attribute1
                   FROM apps.fnd_territories_vl terr,
                        apps.hz_cust_acct_sites_all addr,
                        apps.hz_party_sites party_site,
                        apps.hz_locations loc
                  WHERE addr.cust_account_id = -1
                    AND addr.party_site_id = party_site.party_site_id
                    AND loc.location_id = party_site.location_id
                    AND loc.country = terr.territory_code(+)) raddr
          WHERE prof.cust_account_id = acct.cust_account_id
            AND prof.attribute3 = 'Y'
            AND prof.site_use_id IS NULL
            AND acct.cust_account_id = asite.cust_account_id
            AND asite.cust_acct_site_id = uses.cust_acct_site_id
            AND uses.site_use_code = 'BILL_TO'
            AND asite.party_site_id = psite.party_site_id
            AND psite.location_id = loc.location_id
            AND acct.status = 'A'
            AND asite.status = 'A'
            AND uses.status = 'A'
            AND psite.status = 'A'
            AND loc.state = rmit.state(+)
            AND rmit.address_id = raddr.address_id;
   BEGIN
      SELECT user_id, responsibility_id, responsibility_application_id
        INTO l_user_id, l_responsibility_id, l_responsibility_appl_id
        FROM apps.fnd_user_resp_groups
       WHERE user_id = (SELECT user_id
                          FROM apps.fnd_user
                         WHERE user_name = 'ODCDH')
         AND responsibility_id =
                      (SELECT responsibility_id
                         FROM apps.fnd_responsibility
                        WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');

      fnd_global.apps_initialize (l_user_id,
                                  l_responsibility_id,
                                  l_responsibility_appl_id
                                 );

      --Start of procedure log
      IF (g_fnd_debug = 'Y')
      THEN
     --Check if the log level is less than procedure level
--     IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
       --Log the message
--       FND_LOG.string(FND_LOG.LEVEL_PROCEDURE, 'CDH_REMIT_UPDATE', 'Onetime Script Started');
         lc_message := 'Onetime Script Started';
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message :=
               RPAD (NVL ('site_use_id', ' '), 30, ' ')
            || RPAD (NVL ('account_number', ' '), 30, ' ')
            || RPAD (NVL ('site_osr', ' '), 30, ' ')
            || RPAD (NVL ('state', ' '), 30, ' ')
            || RPAD (NVL ('country', ' '), 30, ' ')
            || RPAD (NVL ('old_rsc', ' '), 30, ' ')
            || RPAD (NVL ('derived_rsc', ' '), 30, ' ')
            || RPAD (NVL ('new_rsc', ' '), 30, ' ')
            || RPAD (NVL ('api_error_status', ' '), 30, ' ')
            || RPAD (NVL ('Processed/No Change', ' '), 30, ' ');
         fnd_file.put_line (fnd_file.LOG, lc_message);
--     END IF;
      END IF;

      l_process_null := '';
      l_process_same := '';

      IF p_processing_flag IS NULL
      THEN
         l_process_null := 'Y';
         l_process_same := 'Y';
      ELSIF p_processing_flag = 'PROCESS_NULL'
      THEN
         l_process_null := 'Y';
         l_process_same := 'N';
      ELSIF p_processing_flag = 'PROCESS_SAME'
      THEN
         l_process_null := 'N';
         l_process_same := 'Y';
      END IF;

      FOR i IN c1
      LOOP
	 l_total_count:= l_total_count+1;
         l_site_use_rec := NULL;
	 l_return_status := NULL;

         IF (   (i.old_rsc IS NULL AND l_process_null = 'Y' AND i.org_id <> '403')
				OR (    i.old_rsc = NVL (i.derived_rsc, '9999')  AND l_process_same = 'Y' )
            )
         THEN

	    l_processed_count:= l_processed_count+1;

	    hz_cust_account_site_v2pub.get_cust_site_use_rec
                           (fnd_api.g_false,
                            p_site_use_id               => i.site_use_id,
                            x_cust_site_use_rec         => l_site_use_rec,
                            x_customer_profile_rec      => l_customer_profile_rec,
                            x_return_status             => l_return_status,
                            x_msg_count                 => l_msg_count,
                            x_msg_data                  => l_msg_data
                           );
            l_site_use_rec.attribute25 := i.new_rsc;

            SELECT MAX (object_version_number)
              INTO l_object_version_number
              FROM hz_cust_site_uses_all
             WHERE site_use_id = i.site_use_id;

            hz_cust_account_site_v2pub.update_cust_site_use
                          (fnd_api.g_false,
                           p_cust_site_use_rec          => l_site_use_rec,
                           p_object_version_number      => l_object_version_number,
                           x_return_status              => l_return_status,
                           x_msg_count                  => l_msg_count,
                           x_msg_data                   => l_msg_data
                          );

            --Check if the log is enabled
            IF (g_fnd_debug = 'Y')
            THEN
     --Check if the log level is less than procedure level
--     IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
       --Log the message
       -- account number - site_osr - state - current rsc - derived rsc - new rsc
               lc_message :=
                     RPAD (i.site_use_id, 30, ' ')
                  || RPAD (NVL (i.account_number, ' '), 30, ' ')
                  || RPAD (NVL (i.site_osr, ' '), 30, ' ')
                  || RPAD (NVL (i.state, ' '), 30, ' ')
		  || RPAD (NVL (i.country, ' '), 30, ' ')
                  || RPAD (NVL (i.old_rsc, ' '), 30, ' ')
                  || RPAD (NVL (i.derived_rsc, ' '), 30, ' ')
                  || RPAD (NVL (i.new_rsc, ' '), 30, ' ')
		  || RPAD (NVL (l_return_status, ' '), 30, ' ')
                  || RPAD (NVL ('Processed', ' '), 30, ' ');
               fnd_file.put_line (fnd_file.LOG, lc_message);

	       IF l_return_status <> 'S' THEN
			l_unsuccess_count := l_unsuccess_count+1;

			IF i.old_rsc IS NULL THEN
				l_unsuccess_null_count := l_unsuccess_null_count+1;
			ELSE
				l_unsuccess_same_count := l_unsuccess_same_count+1;
			END IF;

	       ELSE
			l_success_count := l_success_count+1;

			IF i.old_rsc IS NULL THEN
				l_success_null_count := l_success_null_count+1;
			ELSE
				l_success_same_count := l_success_same_count+1;
			END IF;

	       END IF;

--       FND_LOG.string(FND_LOG.LEVEL_STATEMENT, 'CDH_REMIT_UPDATE', 'Site Use ID: ' || i.site_use_id || ', ' || i.old_rsc || ', ' || i.new_rsc || ', ' || l_return_status);
--     END IF;
            END IF;

            IF (p_commit = 'Y')
            THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;
         ELSE
	 l_nochange_count := l_nochange_count+1;

		IF i.old_rsc IS NULL AND i.org_id <> '403' THEN
			l_nochange_null_count := l_nochange_null_count +1;
		ELSIF i.old_rsc IS NULL AND i.org_id = '403' THEN
			l_nochange_null_ca_count := l_nochange_null_ca_count + 1;
		ELSIF i.old_rsc = NVL (i.derived_rsc, '9999') THEN
			l_nochange_same_count := l_nochange_same_count + 1;
		END IF;

	    --do not process. i.e., keep it as it is
             --Check if the log is enabled
            IF (g_fnd_debug = 'Y')
            THEN
     --Check if the log level is less than procedure level
--     IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
       --Log the message
--       FND_LOG.string(FND_LOG.LEVEL_UNEXPECTED, 'CDH_REMIT_UPDATE', 'Site Use ID: ' || i.site_use_id || ', ' || i.old_rsc || ', ' || i.new_rsc || ', ' || 'No Change');
               lc_message :=
                     RPAD (i.site_use_id, 30, ' ')
                  || RPAD (NVL (i.account_number, ' '), 30, ' ')
                  || RPAD (NVL (i.site_osr, ' '), 30, ' ')
                  || RPAD (NVL (i.state, ' '), 30, ' ')
		  || RPAD (NVL (i.country, ' '), 30, ' ')
                  || RPAD (NVL (i.old_rsc, ' '), 30, ' ')
                  || RPAD (NVL (i.derived_rsc, ' '), 30, ' ')
                  || RPAD (NVL (i.new_rsc, ' '), 30, ' ')
		  || RPAD (NVL (l_return_status, ' '), 30, ' ')
                  || RPAD (NVL ('No Change', ' '), 30, ' ');
               fnd_file.put_line (fnd_file.LOG, lc_message);
--     END IF;
            END IF;
         END IF;
      END LOOP;

      --End of procedure log
      IF (g_fnd_debug = 'Y')
      THEN
     --Check if the log level is less than procedure level
--     IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
       --Log the message
       --FND_LOG.string(FND_LOG.LEVEL_UNEXPECTED, 'CDH_REMIT_UPDATE', 'Onetime Script Ended');

	 fnd_file.put_line (fnd_file.LOG, '------------------------- Report ------------------------------' );


	 lc_message := 'Process record Count :: '||l_processed_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '	Success record Count :: '||l_success_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '		Success remit to sale channel NULL record Count :: '||l_success_null_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '		Success remit to sale channel same record Count :: '||l_success_same_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '	Unsuccess record Count :: '||l_unsuccess_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '		Unsuccess remit to sale channel NULL record Count :: '||l_unsuccess_null_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '		Unsuccess remit to sale channel same record Count :: '||l_unsuccess_same_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := 'No Change record Count :: '||l_nochange_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '	No Change remit to sale channel NULL record Count :: '||l_nochange_null_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '	No Change remit to sale channel NULL and Country CA record Count :: '||l_nochange_null_ca_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := '	No Change remit to sale channel same record Count :: '||l_nochange_same_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);
         lc_message := 'Total record Count :: '||l_total_count;
         fnd_file.put_line (fnd_file.LOG, lc_message);



	 fnd_file.put_line (fnd_file.LOG, '------------------------ Report End ----------------------------' );

         lc_message := 'Onetime Script Ended';
         fnd_file.put_line (fnd_file.LOG, lc_message);
--     END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Check if the log is enabled
         IF (g_fnd_debug = 'Y')
         THEN
     --Check if the log level is less than procedure level
--     IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_UNEXPECTED) THEN
       --Log the message
--       FND_LOG.string(FND_LOG.LEVEL_UNEXPECTED, 'CDH_REMIT_UPDATE', 'Exception: ' || SQLERRM);-- You can have key values printed here for debugging; like cust_account_id etc.
            lc_message :=
                  'Exception: ' || SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
            fnd_file.put_line (fnd_file.LOG, lc_message);
--     END IF;
         END IF;
   END main;
END xxcrm_remitto_onetime_script;
/
SHOW ERRORS;

EXIT;
