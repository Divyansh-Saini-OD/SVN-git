CREATE OR REPLACE
PACKAGE BODY XX_TM_SETUP_RSC_ASSIGNMENT_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_TM_SETUP_RSC_ASSIGNMENT_PKG                                    |
-- |                                                                                |
-- | Description:  This package provides the statistics on Territory assignment .   |
-- |               for the Setup Resource.                                          |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 14-Jul-2009 Sarah Maria Justina        Initial draft version           |
-- |DRAFT 1A 14-Jul-2009 Sreekanth Rao              Updated the report format       |
-- |                                                to fit in excel                 |
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   EX_TM_START_END_PARAMS_ERR      EXCEPTION;
   EX_INVALID_PROFILE_SET          EXCEPTION;

----------------------------
--Declaring Global Variables
----------------------------
-- +====================================================================+
 -- | Name        :  DISPLAY_LOG
 -- | Description :  This procedure is invoked to print in the log file
 -- | Parameters  :  p_message IN VARCHAR2
 -- +====================================================================+
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   BEGIN
         fnd_file.put_line (fnd_file.LOG, p_message);
   END display_log;
-- +====================================================================+
 -- | Name        :  DISPLAY_OUT
 -- | Description :  This procedure is invoked to print in the out file
 -- | Parameters  :  p_message IN VARCHAR2
 -- +====================================================================+
   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   BEGIN
         fnd_file.put_line (fnd_file.OUTPUT, p_message);
   END display_out;

   FUNCTION  canonical_to_dt(p_datetime IN VARCHAR2)
   RETURN TIMESTAMP
   IS
   lc_canonical_dt_mask varchar2(26) := 'YYYY/MM/DD HH24:MI:SS';
   ld_datetime TIMESTAMP;
   BEGIN
       ld_datetime :=to_timestamp(p_datetime, lc_canonical_dt_mask);
       return ld_datetime;
   END;

-- +===========================================================================================================+
-- | Name        :  MAIN
-- | Description:  This package provides the statistics on Territory assignment .
-- |               for the Setup Resource.
-- | Parameters  :  x_errbuf           OUT   VARCHAR2,
-- |                x_retcode          OUT   NUMBER,
-- |                p_start_datetime         VARCHAR2
-- |                p_end_datetime           VARCHAR2
-- +===========================================================================================================+
   PROCEDURE MAIN (
      x_errbuf           OUT   VARCHAR2,
      x_retcode          OUT   NUMBER,
      p_start_datetime         VARCHAR2,
      p_end_datetime           VARCHAR2
   )
   IS
   lt_setup_tbl_type      xx_setup_asgn_tbl;
   L_LIMIT_SIZE           CONSTANT PLS_INTEGER               := 10000;
   p_start_tstamp             TIMESTAMP;
   p_end_tstamp               TIMESTAMP;
   lc_profile_value           VARCHAR2(80);
   ld_last_run_tstamp         TIMESTAMP;
   lc_message_data            VARCHAR2(2000);
   lc_blank_params            VARCHAR2(1)                    := 'N';



   CURSOR lcu_get_setup_assignments(p_start_dt DATE,p_end_dt DATE) IS
	SELECT
	       hp.attribute13 customer_prospect, hps.party_site_id party_site_id,
	       hps.party_site_number party_site_number,
	       SUBSTR (hps.orig_system_reference, 1, 8) orig_system_reference,
	       hp.party_name party_name,
	       regexp_substr (hps.orig_system_reference, '[[:digit:]]+', 1,
			      2) address, terr.start_date_active,
	       terr.end_date_active, rsc.resource_id, rsc.resource_name,
	       (SELECT jrrr.attribute15
	          FROM jtf_rs_role_relations jrrr,
	               jtf_rs_group_mbr_role_vl jrgmr
	         WHERE ROLE.role_id = jrrr.role_id
	           AND SYSDATE BETWEEN jrrr.start_date_active
		   AND COALESCE (jrrr.end_date_active, SYSDATE)
	           AND jrgmr.group_member_id = jrrr.role_resource_id
	           AND jrgmr.GROUP_ID = terr.GROUP_ID
	           AND jrgmr.role_id = jrrr.role_id
	           AND jrrr.delete_flag = 'N'
	           AND jrrr.role_resource_type = 'RS_GROUP_MEMBER'
	         ) legacy_rep_id
	  FROM hz_parties hp,
	       hz_party_sites hps,
	       hz_locations hl,
	       (SELECT
		       terr.named_acct_terr_id, terr_ent.start_date_active,
		       terr_ent.end_date_active, terr_ent.entity_id,
		       terr_rsc.resource_id, terr_rsc.resource_role_id,
		       terr_rsc.GROUP_ID
		  FROM xx_tm_nam_terr_defn terr,
		       xx_tm_nam_terr_entity_dtls terr_ent,
		       xx_tm_nam_terr_rsc_dtls terr_rsc
		 WHERE terr.named_acct_terr_id = terr_ent.named_acct_terr_id
		   AND terr.named_acct_terr_id = terr_rsc.named_acct_terr_id
		   AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id
		   AND SYSDATE BETWEEN terr.start_date_active
				   AND COALESCE (terr.end_date_active, SYSDATE)
		   AND SYSDATE BETWEEN terr_ent.start_date_active
				   AND COALESCE (terr_ent.end_date_active, SYSDATE)
		   AND SYSDATE BETWEEN terr_rsc.start_date_active
				   AND COALESCE (terr_rsc.end_date_active, SYSDATE)
		   AND to_timestamp(TO_CHAR(terr_ent.creation_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS') BETWEEN p_start_dt AND p_end_dt
		   AND COALESCE (terr.status, 'A') = 'A'
		   AND COALESCE (terr_ent.status, 'A') = 'A'
		   AND COALESCE (terr_rsc.status, 'A') = 'A'
		   AND terr_ent.entity_type = 'PARTY_SITE') terr,
	       jtf_rs_roles_vl ROLE,
	       jtf_rs_resource_extns_vl rsc
	 WHERE hp.party_type = 'ORGANIZATION'
	   AND hps.status = 'A'
	   AND hp.status = 'A'
	   AND hp.party_id = hps.party_id
	   AND hps.location_id = hl.location_id
	   AND hps.party_site_id = terr.entity_id
	   AND (   (COALESCE (hp.attribute13, 'X') = 'PROSPECT')
		OR (COALESCE (hp.attribute13, 'X') = 'CUSTOMER')
	       )
	   AND terr.resource_role_id = ROLE.role_id
	   AND ROLE.active_flag = 'Y'
	   AND rsc.resource_id = terr.resource_id
	   AND ROLE.attribute14 LIKE 'SETUP%';

   BEGIN
--                     display_out        (RPAD (' ', 330, '_'));
                                        
                     display_out
                                        (     
                                              RPAD ('CUSTOMER/PROSPECT NUMBER', 30)
                                           || CHR(9)
                                           || RPAD ('SITE', 30)
                                           || CHR(9)
                                           || RPAD ('LEGACY REP', 30)
                                           || CHR(9)
                                           || RPAD ('PARTY SITE NUMBER', 30)
                                           || CHR(9)
                                           || RPAD ('START DATE ACTIVE', 20)
                                           || CHR(9)
                                           || RPAD ('END DATE ACTIVE', 20)
--                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || RPAD (' CUSTOMER PROSPECT', 30)
--                                           || RPAD (' ', 5)
                                        );

--                     display_out        (RPAD (' ', 330, '_'));

                     display_log        ('p_start_datetime: '||p_start_datetime);
                     display_log        ('p_end_datetime:'||p_end_datetime);


      IF(p_start_datetime IS NOT NULL AND p_end_datetime IS NOT NULL) THEN
      		p_start_tstamp :=  canonical_to_dt(p_start_datetime);
      		p_end_tstamp   :=  canonical_to_dt(p_end_datetime);

      ELSIF(p_start_datetime IS NULL AND p_end_datetime IS NULL) THEN
                BEGIN

                SELECT fnd_profile.value('XX_TM_SETUP_RSC_SITES_LAST_RUN_DT')
		  INTO lc_profile_value
                  FROM DUAL;

                display_log        ('lc_profile_value:'||lc_profile_value);

                IF(lc_profile_value IS NOT NULL) THEN

		         ld_last_run_tstamp := canonical_to_dt(lc_profile_value);

		ELSE
		         RAISE EX_INVALID_PROFILE_SET;
                END IF;
                EXCEPTION
		WHEN OTHERS THEN
		         RAISE EX_INVALID_PROFILE_SET;
                END;
                p_start_tstamp :=  ld_last_run_tstamp;
      		p_end_tstamp   :=  canonical_to_dt(TO_CHAR(sysdate,'YYYY/MM/DD HH24:MI:SS'));
      		lc_blank_params:= 'Y';
      ELSIF(p_start_datetime IS NULL AND p_end_datetime IS NOT NULL) OR
           (p_start_datetime IS NOT NULL AND p_end_datetime IS NULL) THEN
                RAISE EX_TM_START_END_PARAMS_ERR;
      END IF;
      display_log ('p_start_tstamp: '||p_start_tstamp);
      display_log ('p_end_tstamp:'||p_end_tstamp);
      -----------------------------------------------
      --Begin loop for BULK Insert
      -----------------------------------------------
      OPEN lcu_get_setup_assignments(p_start_tstamp,p_end_tstamp);
      LOOP
         -------------------------------------------------
         --Initializing table types and their indexes
         -------------------------------------------------
         lt_setup_tbl_type.DELETE;
         FETCH lcu_get_setup_assignments
         BULK COLLECT INTO lt_setup_tbl_type LIMIT L_LIMIT_SIZE;
         IF(lt_setup_tbl_type.COUNT > 0) THEN
	      FOR i IN lt_setup_tbl_type.FIRST .. lt_setup_tbl_type.LAST
	      LOOP
                                        
                     display_out
                                        (     
                                              RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).ORIG_SYSTEM_REFERENCE),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).ADDRESS),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).LEGACY_REP_ID),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).PARTY_SITE_NUMBER),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).START_DATE_ACTIVE),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_setup_tbl_type(i).END_DATE_ACTIVE),' '), 20)
                                           || CHR(9)
                                           || RPAD (' '||NVL(TO_CHAR(lt_setup_tbl_type(i).CUSTOMER_PROSPECT),' '), 30)
                                        );

	      END LOOP;
	  END IF;
      EXIT WHEN lcu_get_setup_assignments%NOTFOUND;
      END LOOP;
      CLOSE lcu_get_setup_assignments;

      IF(lc_blank_params='Y') THEN

      UPDATE fnd_profile_option_values
         SET profile_option_value = TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
       WHERE profile_option_id =
                  (SELECT profile_option_id
                     FROM fnd_profile_options_vl
              WHERE profile_option_name = 'XX_TM_SETUP_RSC_SITES_LAST_RUN_DT');
      END IF;
EXCEPTION
WHEN EX_INVALID_PROFILE_SET THEN
    ROLLBACK;
    fnd_message.set_name           ('XXCRM', 'XX_TM_0275_INVALID_PROFILE_SET');
    lc_message_data                := fnd_message.get;
    x_retcode                      := 2;
    x_errbuf                       := 'Procedure: MAIN: ' || lc_message_data;
WHEN EX_TM_START_END_PARAMS_ERR THEN
    ROLLBACK;
    fnd_message.set_name           ('XXCRM', 'XX_TM_0277_START_END_PARAMS_ERR');
    lc_message_data                := fnd_message.get;
    x_retcode                      := 2;
    x_errbuf                       := 'Procedure: MAIN: ' || lc_message_data;
WHEN OTHERS THEN
    ROLLBACK;
    fnd_message.set_name           ('XXCRM', 'XX_TM_0276_UNEXPECTED_ERROR');
    lc_message_data                := fnd_message.get;
    x_retcode                      := 2;
    x_errbuf                       := 'Procedure: MAIN: ' || lc_message_data;
END MAIN;

END XX_TM_SETUP_RSC_ASSIGNMENT_PKG;
/