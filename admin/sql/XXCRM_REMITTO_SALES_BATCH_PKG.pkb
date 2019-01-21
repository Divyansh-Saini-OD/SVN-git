SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - CR-798							|
-- +============================================================================================+
-- | Name        : xxcrm_remitto_sales_batch_pkg.pks                                            |
-- | Description : This procedure is One time Script to update                                  |
-- |		   Remit to sale channel.                                                       |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/07/11       Devendra Petkar        Initial version                            |
-- +============================================================================================+

CREATE OR REPLACE
PACKAGE BODY xxcrm_remitto_sales_batch_pkg
  -- +====================================================================+
  -- |                  Office Depot -  Ebiz to SFDC Conversion.	|
  -- +====================================================================+
  -- | Name       :  xxcrm_remitto_sales_batch_pkg			|
  -- | Description: This procedure is One time Script to update		|
  -- |    Remit to sale channel.					|
  -- |									|
  -- |									|
  -- |									|
  -- |Change Record:							|
  -- |===============							|
  -- |Version   Date        Author           Remarks			|
  -- |=======   ==========  =============    =============================|
  -- |V 1.0    08/07/11   Devendra Petkar				|
  -- +====================================================================+
AS
  -- +===================================================================+
  -- | Name             : update_remitto_sales                           |
  -- | Description      : This procedure is One time Script to update    |
  -- |   Remit to sale channel.						 |
  -- |                                                                   |
  -- | parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                                                                   |
  -- +===================================================================+
PROCEDURE update_remitto_sales(
    x_errbuf OUT NOCOPY  VARCHAR2,
    x_retcode OUT NOCOPY NUMBER,
    P_COMMIT   IN VARCHAR2 DEFAULT 'N',
    p_start_date IN VARCHAR2 DEFAULT NULL,
    p_end_date   IN VARCHAR2 DEFAULT NULL )

IS

  lc_message  VARCHAR2 (1000);
  l_msg_count NUMBER;
  l_msg_data  VARCHAR2(4000);
  l_msg_text  VARCHAR2(4000);
  l_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;
  l_ovn        NUMBER;
  l_ret_status VARCHAR2(4000);
  l_rsc        VARCHAR2(240);
  lc_rsc_fin   VARCHAR2(240);
  l_rsc_new     VARCHAR2(240);
  lc_token         VARCHAR2 (4000);
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;

BEGIN
  -------------------------------------------------------------------------------------------------------------------

      -- Initialize the out Parameters
      x_errbuf := NULL;
      x_retcode := 0;

	DELETE FROM XXCRM_REMITTO_SALES_BATCH;
	DELETE FROM XXCRM_REMITTO_SALES_FINANCE;

	COMMIT;

	    SELECT user_id,
		   responsibility_id,
		   responsibility_application_id
	    INTO   l_user_id,
		   l_responsibility_id,
		   l_responsibility_appl_id
	      FROM apps.fnd_user_resp_groups
	     WHERE user_id=(SELECT user_id
			      FROM apps.fnd_user
			     WHERE user_name='ODCDH')
	     AND   responsibility_id=(SELECT responsibility_id
					FROM apps.FND_RESPONSIBILITY
				       WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');

    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );



	  INSERT INTO XXCRM_REMITTO_SALES_BATCH
	    (
	      record_id, rowid_hz_cust_site_uses_all, site_use_id, cust_account_profile_id, cust_account_id,
	      cust_acct_site_id, attribute25,site_use_code, bill_to_site_use_id, batch_date, account_number,
	      acct_site_orig_sys_reference, state
	    )
		  SELECT /*+ PARALLEL(A,4) PARALLEL(B,4) PARALLEL(C,4) PARALLEL(D,4) PARALLEL(E,4) PARALLEL(F,4) */
			xxcrm_remitto_seq.nextval, c.rowid, a.site_use_id, a.cust_account_profile_id, a.cust_account_id,
			b.cust_acct_site_id, c.attribute25, c.site_use_code, c.bill_to_site_use_id, sysdate, d.account_number,
			b.orig_system_reference, f.state
		  FROM apps.hz_customer_profiles a, apps.hz_cust_acct_sites_all b,
		       apps.hz_cust_site_uses_all c, apps.hz_cust_accounts  d,
		       apps.hz_party_sites e, apps.hz_locations f
		  WHERE a.attribute3 = 'Y'
		  AND a.site_use_id  IS NULL AND a.cust_account_id = d.cust_account_id
		  AND b.cust_acct_site_id = c.cust_acct_site_id AND site_use_code ='BILL_TO'
		  AND  b.party_site_id  = e.party_site_id
		  AND e.location_id  = f.location_id
		  AND a.status = 'A'   AND b.status  = 'A'   AND c.status  = 'A'
		  AND e.status = 'A' ;


	  COMMIT;



	  INSERT INTO XXCRM_REMITTO_SALES_FINANCE
	    (
		cust_account_id, party_site_id, location_id, state, address_id, attribute1
	    )
		SELECT
		  /*+ PARALLEL(A,4) PARALLEL(B,4) PARALLEL(C,4) PARALLEL(D,4) PARALLEL(E,4) PARALLEL(F,4) */
		  b.cust_account_id, b.party_site_id, c.location_id, d.state,
		  e.address_id,  f.attribute1
		FROM apps.hz_cust_accounts a, apps.hz_cust_acct_sites_all b,
		  apps.hz_party_sites c, apps.hz_locations d,
		  apps.ra_remit_tos_all e,
		  Apps.Ar_Remit_To_Addresses_V  f
		WHERE a.cust_account_id = b.cust_account_id AND b.party_site_id = c.party_site_id
		AND c.location_id   = d.location_id AND d.state = e.state
		AND e.address_id  = f.address_id  AND a.status   = 'A'
		AND b.status    = 'A' AND c.status  = 'A';





	  COMMIT;

  --------------------------------------------------------------------------------------------------------------

	  FOR I IN (SELECT ROWID tmp_rowid,
		    a.attribute25, a.cust_account_id, a.site_use_id, a.rowid_hz_cust_site_uses_all  FROM XXCRM_REMITTO_SALES_BATCH A
			  ORDER BY record_id
		  )
	  LOOP
			l_msg_text:='';
			l_rsc_new :='';
			l_rsc :='';
	    BEGIN
		      IF i.attribute25  IS NULL THEN
			l_rsc:=1;
		      ELSIF i.attribute25 IS NOT NULL THEN

				BEGIN

				SELECT
				  f.attribute1
				  INTO lc_rsc_fin
				FROM apps.hz_cust_accounts a, apps.hz_cust_acct_sites_all b,
				  apps.hz_party_sites c, apps.hz_locations d,
				  apps.ra_remit_tos_all e,
				  Apps.Ar_Remit_To_Addresses_V  f
				WHERE a.cust_account_id = b.cust_account_id AND b.party_site_id = c.party_site_id
				AND c.location_id   = d.location_id AND d.state = e.state
				AND e.address_id  = f.address_id  AND a.status   = 'A'
				AND b.status    = 'A' AND c.status  = 'A'
				AND a.cust_account_id = i.cust_account_id;


				EXCEPTION
				WHEN OTHERS THEN
				 lc_token := SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
				 fnd_message.set_token ('MESSAGE', lc_token);
				 lc_message := fnd_message.get;
				 fnd_file.put_line (fnd_file.LOG, ' ');
				 fnd_file.put_line (fnd_file.LOG,
						    'An error occured. Details : ' || lc_message
						   );
				 fnd_file.put_line (fnd_file.LOG, ' ');

				  UPDATE XXCRM_REMITTO_SALES_BATCH
				  SET error_msg=lc_token
				  WHERE rowid  =i.tmp_rowid;
				  COMMIT;
				  -- Need details shall we proceed or not
				END;

				IF i.attribute25 = NVL(lc_rsc_fin,'9999') THEN
				  l_rsc         :=NULL;
				ELSE
				  l_rsc:=i.attribute25; -- Need to confirm when not to run Update
				  GOTO last_line;
				END IF;

		      END IF;

			IF P_COMMIT='Y' THEN

				      l_site_use_rec.site_use_id := i.site_use_id;
				      l_site_use_rec.attribute25 := l_rsc;
				      HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use ( p_init_msg_list => FND_API.G_TRUE,
										p_cust_site_use_rec => l_site_use_rec,
										p_object_version_number => l_ovn,
										x_return_status => l_ret_status,
										x_msg_count => l_msg_count,
										x_msg_data => l_msg_data );
			ELSE
				l_ret_status :='S';
			END IF;

	      IF l_ret_status  <> 'S' THEN

				IF l_msg_count >= 1 THEN

				  fnd_file.put_line(fnd_file.log,'------------------------------------------------------------');
				  fnd_file.put_line(fnd_file.log, 'Error In Call TO Update Site Use API - Site Use ID,  Object Version Number,   Status  : ' || l_site_use_rec.site_use_id || ',' ||l_ovn|| ',' || l_site_use_rec.status);

				  FOR I IN 1..l_msg_count
					  LOOP

					    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE);
					    fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));

					  END LOOP;
				  fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));

				END IF;

			UPDATE XXCRM_REMITTO_SALES_BATCH
			SET batch_status='Error',
			  error_msg     =l_msg_text
			WHERE rowid     =i.tmp_rowid;

			COMMIT;

	      ELSE

			BEGIN
				SELECT attribute25 INTO l_rsc_new FROM hz_cust_site_uses_all WHERE rowid= i.rowid_hz_cust_site_uses_all;

				IF P_COMMIT='N' THEN
				 l_rsc_new :=l_rsc;
				END IF;

			EXCEPTION
			 WHEN OTHERS THEN
			 l_rsc_new:= NULL;
			END;

			UPDATE XXCRM_REMITTO_SALES_BATCH
			SET batch_status='Processed',
			  error_msg     =l_msg_text,
			  attribute25_new = l_rsc_new
			WHERE rowid     =i.tmp_rowid;

			COMMIT;
		GOTO last_line_update;
	      END IF;

	    EXCEPTION
	    WHEN OTHERS THEN
	      lc_message := SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
	      fnd_file.put_line (fnd_file.LOG, ' ');
	      fnd_file.put_line (fnd_file.LOG, 'An error occured. Details : ' || lc_message );
	      fnd_file.put_line (fnd_file.LOG, ' ');
	    END;

	    << last_line >>
			UPDATE XXCRM_REMITTO_SALES_BATCH
			SET batch_status='Processed without Change',
			  attribute25_new = l_rsc
			WHERE rowid     =i.tmp_rowid;

	    << last_line_update  >> NULL;

	  END LOOP;

  UPDATE XXCRM_REMITTO_SALES_BATCH
  SET batch_status    ='Not Processed'
  WHERE batch_status IS NULL;

  COMMIT;

EXCEPTION
WHEN OTHERS THEN
  lc_message := SQLCODE || ':' || SUBSTR (SQLERRM, 1, 256);
  fnd_file.put_line (fnd_file.LOG, ' ');
  fnd_file.put_line (fnd_file.LOG, 'An error occured. Details : ' || lc_message );
  fnd_file.put_line (fnd_file.LOG, ' ');
END update_remitto_sales;

END xxcrm_remitto_sales_batch_pkg;
/

SHOW ERRORS;

EXIT;
