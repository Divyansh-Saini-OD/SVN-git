SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY xxbi_fast_refresh_pkg AS
  -- +=========================================================================================+
  -- |                  Office Depot - Project Simplify                                        |
  -- +=========================================================================================+
  -- | Name        : xxbi_fast_refresh                                                         |
  -- | Description : Custom package for data migration.                                        |
  -- |                                                                                         |
  -- |                                                                                         |
  -- |Change Record:                                                                           |
  -- |===============                                                                          |
  -- |Version     Date           Author               Remarks                                  |
  -- |=======    ==========      ================     =========================================|
  -- |1.0        08-Apr-2009     Prasad Devar               Initial version                    |
  -- |1.1        19-Oct-2010     Kishore Jena         Changes related multiple rsd's for user  |                                                                                         |
  -- |                                                                                         |
  -- |                                                                                         |
  -- +=========================================================================================+
  g_limit NUMBER := 500;
  bulk_errors

   EXCEPTION;
  pragma exception_init(bulk_errors,   -24381);
  type r_cursor IS ref CURSOR;

  -- +====================================================================+
  -- | Name        :  display_log                                         |
  -- | Description :  This procedure is invoked to print in the log file  |
  -- |                                                                    |
  -- | Parameters  :  Log Message                                         |
  -- +====================================================================+

  PROCEDURE display_log(p_message IN VARCHAR2)

   IS

  BEGIN

    fnd_file.PUT_LINE(fnd_file.LOG,   p_message);

  END display_log;

  -- +====================================================================+
  -- | Name        :  display_out                                         |
  -- | Description :  This procedure is invoked to print in the output    |
  -- |                file                                                |
  -- |                                                                    |
  -- | Parameters  :  Log Message                                         |
  -- +====================================================================+

  PROCEDURE display_out(p_message IN VARCHAR2)

   IS

  BEGIN

    fnd_file.PUT_LINE(fnd_file.OUTPUT,   p_message);

  END display_out;

/*
  -- +===================================================================+
  -- | Name             : fast_refresh_contacts                          |
  -- | Description      : This procedure extracts Fast Refresh Contacts  |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                                                                   |
  -- +===================================================================+
PROCEDURE fast_refresh_contacts(x_errbuf OUT nocopy VARCHAR2,   x_retcode OUT nocopy VARCHAR2) IS
ln_succ_update_date DATE;
ln_new_update_date DATE;
l_from_date DATE;
l_to_date DATE;
l_update_prof VARCHAR2(1);
l_error_messege VARCHAR2(2000);
l_update_cnt INTEGER := 0;
ln_party_site_id NUMBER;
CURSOR c_contacts IS
SELECT rel.object_id party_id,
  rel.party_id rel_party_id,
  pc.rowid pc_row_id,
  pc.contact_point_id,
  pc.last_update_date c_last_dt,
  pc.contact_point_type,
  pc.primary_flag,
  pc.email_address,
  pc.raw_phone_number,
  phone_area_code,
  phone_country_code,
  phone_number,
  phone_extension,
  phone_line_type,
  pa.party_name,
  pa.person_first_name,
  pa.person_middle_name,
  pa.person_last_name,
  pa.party_id per_party_id,
  pa.rowid parowid,
  rel.rowid relrid,
  rel.relationship_id,
  psext.rowid psextrowid,
  psext.party_site_id site_party_site_id,
  psext.last_update_date site_last_update_date,
  hc.cust_acct_site_id,
  hc.cust_account_id,
  hc.rowid hc_row_id,
  hc.end_date hc_end_date,
  rel.end_date rel_end_date,
  psext.party_site_id,
  hoc.job_title,
  hoc.org_contact_id,
  hc.cust_account_role_id
FROM apps.hz_contact_points pc,
  apps.hz_parties pa,
  apps.hz_relationships rel,
  apps.hz_party_sites_ext_b psext,
  apps.hz_cust_account_roles hc,
  apps.hz_org_contacts hoc
WHERE rel.party_id = pc.owner_table_id
 AND pc.owner_table_name = 'HZ_PARTIES'
 AND rel.subject_type = 'PERSON'
 AND rel.object_type = 'ORGANIZATION'
 AND rel.subject_id = pa.party_id
 AND rel.relationship_id = hoc.party_relationship_id(+)
 AND psext.attr_group_id(+) = 169
 AND psext.n_ext_attr1(+) = rel.relationship_id
 AND hc.party_id(+) = rel.party_id
 AND pc.status = 'A'
 AND pa.status = 'A'
 AND rel.status = 'A'
 AND hc.status(+) = 'A'
 AND current_role_state(+) = 'A'
 AND pc.contact_point_id IN
  (SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE contact_point_id IN
    (SELECT contact_point_id
     FROM ar.mlog$_hz_contact_points
     WHERE dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  UNION ALL
   SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE relationship_id IN
    (SELECT relationship_id
     FROM ar.mlog$_hz_relationships
     WHERE dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  UNION ALL
   SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE per_party_id IN
    (SELECT party_id
     FROM ar.mlog$_hz_parties
     WHERE dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  UNION ALL
   SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE site_party_site_id IN
    (SELECT party_site_id
     FROM ar.mlog$_hz_party_sites_ext_b
     WHERE attr_group_id = 169
     AND dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  UNION ALL
   SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE cust_account_role_id IN
    (SELECT cust_account_role_id
     FROM ar.mlog$_hz_cust_account_role
     WHERE dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  UNION ALL
   SELECT contact_point_id
   FROM xxcrm.xxbi_contact_mv_tbl
   WHERE org_contact_id IN
    (SELECT org_contact_id
     FROM ar.mlog$_hz_org_contacts
     WHERE dmltype$$ = 'D' OR last_update_date >=
      (SELECT to_date(fpov.profile_option_value,    'DD-MON-YYYY HH24:MI:SS')
       FROM fnd_profile_option_values fpov,
         fnd_profile_options fpo
       WHERE fpo.profile_option_id = fpov.profile_option_id
       AND fpo.application_id = fpov.application_id
       AND fpov.level_id = g_level_id
       AND fpov.level_value = g_level_value
       AND fpov.profile_option_value IS NOT NULL
       AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT')
    )
  )
;

type xx_contacts_tbl IS TABLE OF c_contacts % rowtype INDEX BY binary_integer;
lc_xx_contacts_tbl xx_contacts_tbl;
BEGIN
  BEGIN
    SELECT to_date(fpov.profile_option_value,   'DD-MON-YYYY HH24:MI:SS')
    INTO ln_succ_update_date
    FROM fnd_profile_option_values fpov,
      fnd_profile_options fpo
    WHERE fpo.profile_option_id = fpov.profile_option_id
     AND fpo.application_id = fpov.application_id
     AND fpov.level_id = g_level_id
     AND fpov.level_value = g_level_value
     AND fpov.profile_option_value IS NOT NULL
     AND fpo.profile_option_name = 'XXBI_LAST_CONTACTS_DT';

  EXCEPTION
  WHEN others THEN
    ln_succ_update_date := NULL;
  END;

  BEGIN

    ln_new_update_date := sysdate;

  EXCEPTION
  WHEN others THEN
    ln_new_update_date := NULL;
  END;
  display_log('ln_succ_update_date ' || ln_succ_update_date);
  display_log('ln_new_update_date ' || ln_new_update_date);

  display_log('out side ln_succ_update_date ' || ln_succ_update_date);
  display_log(' out side  ln_new_update_date ' || ln_new_update_date);

  OPEN c_contacts;
  FETCH c_contacts bulk collect
  INTO lc_xx_contacts_tbl;
  CLOSE c_contacts;

  display_log('lc_tsk_report_tbl.count ' || lc_xx_contacts_tbl.COUNT);

  BEGIN

    DELETE FROM xxcrm.xxbi_contact_mv_tbl
    WHERE contact_point_id IN
      (SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE contact_point_id IN
        (SELECT contact_point_id
         FROM ar.mlog$_hz_contact_points
         WHERE dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      UNION ALL
       SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE relationship_id IN
        (SELECT relationship_id
         FROM ar.mlog$_hz_relationships
         WHERE dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      UNION ALL
       SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE per_party_id IN
        (SELECT party_id
         FROM ar.mlog$_hz_parties
         WHERE dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      UNION ALL
       SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE site_party_site_id IN
        (SELECT party_site_id
         FROM ar.mlog$_hz_party_sites_ext_b
         WHERE attr_group_id = 169
         AND dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      UNION ALL
       SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE cust_account_role_id IN
        (SELECT cust_account_role_id
         FROM ar.mlog$_hz_cust_account_role
         WHERE dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      UNION ALL
       SELECT contact_point_id
       FROM xxcrm.xxbi_contact_mv_tbl
       WHERE org_contact_id IN
        (SELECT org_contact_id
         FROM ar.mlog$_hz_org_contacts
         WHERE dmltype$$ = 'D' OR last_update_date >= ln_succ_update_date)
      )
    ;

  END;

  IF lc_xx_contacts_tbl.COUNT > 0 THEN

    FOR i IN lc_xx_contacts_tbl.FIRST .. lc_xx_contacts_tbl.LAST
    LOOP */

      /*  SELECT COUNT(1)
        INTO l_update_cnt
        FROM xxcrm.xxbi_contact_mv_tbl
        WHERE contact_point_id = lc_xx_contacts_tbl(i).contact_point_id
         AND relationship_id = lc_xx_contacts_tbl(i).relationship_id
         AND per_party_id = lc_xx_contacts_tbl(i).per_party_id
         AND rel_party_id = lc_xx_contacts_tbl(i).rel_party_id;

        IF l_update_cnt > 0 THEN

          UPDATE xxcrm.xxbi_contact_mv_tbl
          SET party_id = lc_xx_contacts_tbl(i).party_id,
            rel_party_id = lc_xx_contacts_tbl(i).rel_party_id,
            pc_row_id = lc_xx_contacts_tbl(i).pc_row_id,
            contact_point_id = lc_xx_contacts_tbl(i).contact_point_id,
            c_last_dt = sysdate --lc_xx_contacts_tbl(i).C_LAST_DT
          ,
            contact_point_type = lc_xx_contacts_tbl(i).contact_point_type,
            primary_flag = lc_xx_contacts_tbl(i).primary_flag,
            email_address = lc_xx_contacts_tbl(i).email_address,
            raw_phone_number = lc_xx_contacts_tbl(i).raw_phone_number,
            phone_area_code = lc_xx_contacts_tbl(i).phone_area_code,
            phone_country_code = lc_xx_contacts_tbl(i).phone_country_code,
            phone_number = lc_xx_contacts_tbl(i).phone_number,
            phone_extension = lc_xx_contacts_tbl(i).phone_extension,
            phone_line_type = lc_xx_contacts_tbl(i).phone_line_type,
            party_name = lc_xx_contacts_tbl(i).party_name,
            person_first_name = lc_xx_contacts_tbl(i).person_first_name,
            person_middle_name = lc_xx_contacts_tbl(i).person_middle_name,
            person_last_name = lc_xx_contacts_tbl(i).person_last_name,
            per_party_id = lc_xx_contacts_tbl(i).per_party_id,
            parowid = lc_xx_contacts_tbl(i).parowid,
            relrid = lc_xx_contacts_tbl(i).relrid,
            relationship_id = lc_xx_contacts_tbl(i).relationship_id,
            psextrowid = lc_xx_contacts_tbl(i).psextrowid,
            site_party_site_id = lc_xx_contacts_tbl(i).site_party_site_id,
            site_last_update_date = lc_xx_contacts_tbl(i).site_last_update_date,
            cust_acct_site_id = lc_xx_contacts_tbl(i).cust_acct_site_id,
            cust_account_id = lc_xx_contacts_tbl(i).cust_account_id,
            hc_row_id = lc_xx_contacts_tbl(i).hc_row_id
          WHERE contact_point_id = lc_xx_contacts_tbl(i).contact_point_id
           AND relationship_id = lc_xx_contacts_tbl(i).relationship_id
           AND per_party_id = lc_xx_contacts_tbl(i).per_party_id
           AND rel_party_id = lc_xx_contacts_tbl(i).rel_party_id;
        ELSE
        */ 
       /* ln_party_site_id := lc_xx_contacts_tbl(i).party_site_id;

      IF(ln_party_site_id IS NULL
       AND lc_xx_contacts_tbl(i).cust_acct_site_id IS NOT NULL) THEN
        SELECT party_site_id
        INTO ln_party_site_id
        FROM apps.hz_cust_acct_sites_all
        WHERE cust_acct_site_id = lc_xx_contacts_tbl(i).cust_acct_site_id;
      END IF;

      INSERT
      INTO xxcrm.xxbi_contact_mv_tbl(party_id,   rel_party_id,   pc_row_id,   contact_point_id,   
      c_last_dt,   contact_point_type,   primary_flag,   email_address,   raw_phone_number,   phone_area_code, 
      phone_country_code,   phone_number,   phone_extension,   phone_line_type,   party_name,   person_first_name,  
      person_middle_name,   person_last_name,   per_party_id,   parowid,   relrid,   relationship_id,   psextrowid, 
      site_party_site_id,   site_last_update_date,   cust_acct_site_id,   cust_account_id,   hc_row_id,   party_site_id,  
      job_title,   org_contact_id,   cust_account_role_id)
      VALUES(lc_xx_contacts_tbl(i).party_id,   lc_xx_contacts_tbl(i).rel_party_id,   lc_xx_contacts_tbl(i).pc_row_id, 
      lc_xx_contacts_tbl(i).contact_point_id,   --lc_xx_contacts_tbl(i).C_LAST_DT,
      ln_new_update_date,   lc_xx_contacts_tbl(i).contact_point_type,   lc_xx_contacts_tbl(i).primary_flag,  
      lc_xx_contacts_tbl(i).email_address,   lc_xx_contacts_tbl(i).raw_phone_number,   lc_xx_contacts_tbl(i).phone_area_code, 
      lc_xx_contacts_tbl(i).phone_country_code,   lc_xx_contacts_tbl(i).phone_number,   lc_xx_contacts_tbl(i).phone_extension, 
      lc_xx_contacts_tbl(i).phone_line_type,   lc_xx_contacts_tbl(i).party_name,   lc_xx_contacts_tbl(i).person_first_name,   
      lc_xx_contacts_tbl(i).person_middle_name,   lc_xx_contacts_tbl(i).person_last_name,   lc_xx_contacts_tbl(i).per_party_id,  
      lc_xx_contacts_tbl(i).parowid,   lc_xx_contacts_tbl(i).relrid,   lc_xx_contacts_tbl(i).relationship_id,   lc_xx_contacts_tbl(i).psextrowid,   
      lc_xx_contacts_tbl(i).site_party_site_id,   lc_xx_contacts_tbl(i).site_last_update_date,   lc_xx_contacts_tbl(i).cust_acct_site_id,  
      lc_xx_contacts_tbl(i).cust_account_id,   lc_xx_contacts_tbl(i).hc_row_id,   lc_xx_contacts_tbl(i).party_site_id,   lc_xx_contacts_tbl(i).job_title,  
      lc_xx_contacts_tbl(i).org_contact_id,   lc_xx_contacts_tbl(i).cust_account_role_id);

      --  END IF;

    END LOOP;

    COMMIT;
  END IF;

  display_log('Update the sysdate ' || to_char(ln_new_update_date,   'DD-MON-YYYY HH24:MI:SS'));

  IF nvl(UPPER(l_update_prof),   'N') = 'Y' THEN

    IF fnd_profile.save('XXBI_LAST_CONTACTS_DT',   to_char(ln_new_update_date,   'DD-MON-YYYY HH24:MI:SS'),   'SITE') THEN
      COMMIT;

    END IF;

  END IF;

  --select sysdate from dual;
END fast_refresh_contacts; 
*/


  PROCEDURE xxbi_cmplte_rfrsh_contacts_mv(x_error_code OUT nocopy NUMBER,   x_error_buf OUT nocopy VARCHAR2,   p_refresh_flag IN VARCHAR2,   p_load_flag IN VARCHAR2, p_rebuild_flag IN VARCHAR2,  p_create_log  IN VARCHAR2 ) AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name             :  xxbi_cmplte_rfrsh_contacts_mv                   |
  -- | Description      :  This package is used to refresh    Complete              |
  -- |                      XXBI_CONTACTS_MV                       |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author              Remarks                  |
  -- |=======   ==========  ================    =========================|
  -- |1.0       19-MAR-2008 Prasad Devar        Initial version          |
  -- +===================================================================+
  BEGIN


    IF UPPER(p_refresh_flag) = 'Y' THEN
	     fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>   ' || systimestamp || ' Before calling Refresh XXBI_CONTACTS_MV');
      	dbms_mview.refresh('XXCRM.XXBI_CONTACTS_MV', 'C', atomic_refresh => FALSE );
      	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Complie XXBI_CONTACTS_MV Complete');
    END IF;
-- Rebuild the indexes of the MV Table log 
	IF UPPER(p_rebuild_flag) = 'Y' THEN
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n1 rebuild parallel 8');
      END;
	BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n1 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n2 rebuild parallel 8');
      END;
		BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n2 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n3 rebuild parallel 8');
      END;
	 BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n3 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n4 rebuild parallel 8');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n4 noparallel');
      END;
	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Index Rebuild Complete');
    END IF;
-- Recreate the MV Table log 
    IF UPPER(p_create_log) = 'Y' THEN
	BEGIN
        EXECUTE IMMEDIATE('CREATE MATERIALIZED VIEW LOG ON XXCRM.XXBI_CONTACT_MV_TBL WITH ROWID, SEQUENCE ( CONTACT_POINT_ID, CONTACT_POINT_TYPE, C_LAST_DT, PARTY_SITE_ID, RELATIONSHIP_ID ) INCLUDING NEW VALUES');
	END;
    END IF;

	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Index Rebuild Complete');
    IF UPPER(p_load_flag) = 'Y' THEN
	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  DROP MATERIALIZED VIEW LOG ON XXCRM.XXBI_CONTACT_MV_TBL Start');
	BEGIN
        EXECUTE IMMEDIATE('DROP MATERIALIZED VIEW LOG ON XXCRM.XXBI_CONTACT_MV_TBL');
	END;
	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  DROP MATERIALIZED VIEW LOG ON XXCRM.XXBI_CONTACT_MV_TBL Complete');

	BEGIN
 		execute immediate('TRUNCATE TABLE xxcrm.xxbi_contact_mv_tbl');
      END;
	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  TRUNCATE TABLE xxcrm.xxbi_contact_mv_tbl Complete');

	BEGIN
		execute immediate('alter index xxcrm.xxbi_contact_mv_tbl_n1  unusable');
       END;
    	BEGIN
		execute immediate('alter index xxcrm.xxbi_contact_mv_tbl_n2  unusable');
      END;
    	BEGIN
		execute immediate('alter index xxcrm.xxbi_contact_mv_tbl_n3  unusable');
       END;
    	BEGIN
		execute immediate('alter index xxcrm.xxbi_contact_mv_tbl_n4  unusable');
        END;
       fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Index Unuable Complete');
        INSERT
      INTO xxcrm.xxbi_contact_mv_tbl(party_id,   rel_party_id,   pc_row_id,   contact_point_id,   c_last_dt,   contact_point_type,   primary_flag,   email_address,   raw_phone_number,   phone_area_code,   phone_country_code,   phone_number,   phone_extension,   phone_line_type,   party_name,   person_first_name,   person_middle_name,   person_last_name,   per_party_id,   parowid,   relrid,   relationship_id,   psextrowid,   site_party_site_id,   site_last_update_date,   cust_acct_site_id,   cust_account_id,   hc_row_id,   party_site_id,   job_title,   org_contact_id,   cust_account_role_id)
      SELECT /*+full(cm) parallel(cm,4) full(cs) parallel(cs,4)*/ cm.party_id,
        cm.rel_party_id,
        cm.pc_row_id,
        cm.contact_point_id,
        cm.c_last_dt,
        cm.contact_point_type,
        cm.primary_flag,
        cm.email_address,
        cm.raw_phone_number,
        cm.phone_area_code,
        cm.phone_country_code,
        cm.phone_number,
        cm.phone_extension,
        cm.phone_line_type,
        cm.party_name,
        cm.person_first_name,
        cm.person_middle_name,
        cm.person_last_name,
        cm.per_party_id,
        cm.parowid,
        cm.relrid,
        cm.relationship_id,
        cm.psextrowid,
        cm.site_party_site_id,
        cm.site_last_update_date,
        cm.cust_acct_site_id,
        cm.cust_account_id,
        cm.hc_row_id,
        nvl(cs.party_site_id,   cm.party_site_id) party_site_id,
        cm.job_title,
        cm.org_contact_id,
        cm.cust_account_role_id
      FROM xxcrm.xxbi_contacts_mv cm,
        apps.hz_cust_acct_sites_all cs
      WHERE nvl(cm.hc_end_date,   sysdate + 1) > sysdate
       AND nvl(cm.rel_end_date,   sysdate + 1) > sysdate
       AND cm.cust_acct_site_id = cs.cust_acct_site_id(+)
      AND cs.status(+) = 'A';
      COMMIT;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n1 rebuild parallel 8');
      END;
	BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n1 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n2 rebuild parallel 8');
      END;
		BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n2 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n3 rebuild parallel 8');
      END;
	 BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n3 noparallel');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n4 rebuild parallel 8');
      END;
      BEGIN
        EXECUTE IMMEDIATE('alter INDEX xxcrm.xxbi_contact_mv_tbl_n4 noparallel');
      END;

	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Index Rebuild Complete');

	BEGIN
        EXECUTE IMMEDIATE('CREATE MATERIALIZED VIEW LOG ON XXCRM.XXBI_CONTACT_MV_TBL WITH ROWID, SEQUENCE ( CONTACT_POINT_ID, CONTACT_POINT_TYPE, C_LAST_DT, PARTY_SITE_ID, RELATIONSHIP_ID ) INCLUDING NEW VALUES');
	END;

	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  Index Rebuild Complete');

      dbms_stats.gather_table_stats(ownname => 'XXCRM',   tabname => 'xxbi_contact_mv_tbl',   cascade => TRUE,   degree => dbms_stats.default_degree);

	fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || '  gather Stats Complete');
    END IF;

  END xxbi_cmplte_rfrsh_contacts_mv;

  PROCEDURE xxbi_cmplte_rfrsh_asgnmnts_mv(x_error_code   OUT nocopy NUMBER,   
                                          x_error_buf    OUT nocopy VARCHAR2,   
                                          p_refresh_flag IN  VARCHAR2,   
                                          p_load_flag    IN  VARCHAR2,
							p_rebuild_flag IN  VARCHAR2, 
							p_create_log   IN  VARCHAR2
                                         ) AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- |Name             :  xxbi_cmplte_rfrsh_asgnmnts_mv                  |
  -- |Description      :  This procedure is used to complete refresh     |
  -- |                    xxbi_terent_asgnmnt_fct_mv                     |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author              Remarks                  |
  -- |=======   ==========  ================    =========================|
  -- |1.0       19-APR-2010 Kishore Jena        Initial version          |
  -- +===================================================================+
  BEGIN

    IF UPPER(p_refresh_flag) = 'Y' THEN

      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>   ' || systimestamp || 'Before Complete Refresh xxbi_terent_asgnmnt_fct_mv');
      dbms_mview.refresh('xxcrm.xxbi_terent_asgnmnt_fct_mv',   'C', atomic_refresh => FALSE);
      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || 'Complete Refresh xxbi_terent_asgnmnt_fct_mv Complete');

    END IF;
    
  END xxbi_cmplte_rfrsh_asgnmnts_mv;

  PROCEDURE xxbi_cmplte_rfrsh_sitedata_mv(x_error_code   OUT nocopy NUMBER,   
                                          x_error_buf    OUT nocopy VARCHAR2,   
                                          p_refresh_flag IN  VARCHAR2,   
                                          p_load_flag    IN  VARCHAR2,
							p_rebuild_flag IN  VARCHAR2, 
							p_create_log   IN  VARCHAR2
                                         ) AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- |Name             :  xxbi_cmplte_rfrsh_sitedata_mv                  |
  -- |Description      :  This procedure is used to complete refresh     |
  -- |                    xxbi_party_site_data_fct_mv                    |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author              Remarks                  |
  -- |=======   ==========  ================    =========================|
  -- |1.0       19-APR-2010 Kishore Jena        Initial version          |
  -- +===================================================================+
  BEGIN

    IF UPPER(p_refresh_flag) = 'Y' THEN

      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>   ' || systimestamp || 'Before Complete Refresh xxbi_party_site_data_fct_mv');
      dbms_mview.refresh('xxcrm.xxbi_party_site_data_fct_mv',   'C', atomic_refresh => FALSE);
      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>>  ' || systimestamp || 'Complete Refresh xxbi_party_site_data_fct_mv Complete');

    END IF;

  END xxbi_cmplte_rfrsh_sitedata_mv;


  PROCEDURE alter_xxbi_user_site_dtl(x_error_code   OUT nocopy NUMBER,   
                                     x_error_buf    OUT nocopy VARCHAR2  
                                     ) AS
  -- +====================================================================+
  -- | Name        :  alter_xxbi_user_site_dtl                            |
  -- | Description :  This procedure is used to alter xxbi_user_site_dtl  |
  -- |                table dynamically with single partitions for each   |
  -- |                RSD in resource manager.                            |
  -- |Change Record:                                                      |
  -- |===============                                                     |
  -- |Version   Date        Author              Remarks                   |
  -- |=======   ==========  ================    ========================= |
  -- |1.0       19-APR-2010 Kishore Jena        Initial version           |
  -- +====================================================================+

    CURSOR c_partition_to_drop IS
    SELECT DISTINCT to_number(substr(partition_name, 5)) rsd_user_id
    FROM   dba_tab_partitions 
    WHERE  table_name = 'XXBI_USER_SITE_DTL'
      AND  partition_name NOT IN ('RSD_NULL', 'RSD_UNKNOWN')
    MINUS
    SELECT DISTINCT NVL(rsd_user_id, 9999999999) rsd_user_id
    FROM xxcrm.xxbi_group_mbr_info_mv
    ORDER BY 1;

    CURSOR c_partition_to_add IS
    SELECT DISTINCT NVL(rsd_user_id, 9999999999) rsd_user_id
    FROM xxcrm.xxbi_group_mbr_info_mv
    MINUS
    SELECT DISTINCT to_number(substr(partition_name, 5)) rsd_user_id
    FROM   dba_tab_partitions 
    WHERE  table_name = 'XXBI_USER_SITE_DTL'
      AND  partition_name NOT IN ('RSD_NULL', 'RSD_UNKNOWN')
    ORDER BY 1;
  
  BEGIN    
    -- DROP the default Partition
    execute immediate('ALTER TABLE xxcrm.xxbi_user_site_dtl DROP PARTITION RSD_UNKNOWN' ||
                      ' UPDATE GLOBAL INDEXES'
                     );

    FOR part_rec in c_partition_to_drop LOOP
      execute immediate('ALTER TABLE xxcrm.xxbi_user_site_dtl DROP PARTITION RSD_' || part_rec.rsd_user_id ||
                        ' UPDATE GLOBAL INDEXES'
                       );
    END LOOP;

    FOR part_rec in c_partition_to_add LOOP
      execute immediate('ALTER TABLE xxcrm.xxbi_user_site_dtl ADD PARTITION RSD_' || part_rec.rsd_user_id ||
                        ' VALUES (' || part_rec.rsd_user_id || ')'
                       );
    END LOOP;

    -- Add Default Partition Back
    execute immediate('ALTER TABLE xxcrm.xxbi_user_site_dtl ADD PARTITION RSD_UNKNOWN' || 
                      ' VALUES (DEFAULT)'
                     );

  END alter_xxbi_user_site_dtl;

  PROCEDURE xxbi_populate_rsddata(x_error_code   OUT nocopy NUMBER,   
                                  x_error_buf    OUT nocopy VARCHAR2  
                                 ) AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- |Name             :  xxbi_populate_rsddata                          |
  -- |Description      :  This procedure is used to populate             |
  -- |                    table XXBI_USER_SITE_DTL                       |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author              Remarks                  |
  -- |=======   ==========  ================    =========================|
  -- |1.0       19-APR-2010 Kishore Jena        Initial version          |
  -- +===================================================================+

    l_error_code NUMBER;
    l_error_buf  VARCHAR2(1000);

  BEGIN
    -- Flush the data from table
    execute immediate('TRUNCATE TABLE xxcrm.xxbi_user_site_dtl');
 
    -- Add/Drop Partitions
    alter_xxbi_user_site_dtl(l_error_code, l_error_buf);

    x_error_code := l_error_code;
    x_error_buf  := l_error_buf;

    -- Copy data from MV
    INSERT /*+ APPEND */ 
    INTO xxcrm.xxbi_user_site_dtl(rsd_user_id,
                                  sort_id,
                                  user_id,
                                  m1_user_id,
                                  m2_user_id,
                                  m3_user_id,
                                  org_type,
                                  potential_type_cd,
                                  od_site_full_sic_code,
                                  od_site_sic_code,
                                  od_site_wcw,
                                  od_site_wcw_range,
                                  city,
                                  state_province,
                                  postal_code,
                                  cust_loyalty_code,
                                  party_revenue_band,
                                  site_use_id,
                                  site_use,
                                  org_site_status,
                                  duplicate_view,
                                  comparable_potential_amt,
                                  org_number,
                                  org_name,
                                  org_site_number,
                                  site_name,
                                  site_address,
                                  last_activity_date,
                                  m4_user_id,
                                  m5_user_id,
                                  m6_user_id,
                                  party_site_id,
                                  party_id,
                                  location_id,
                                  site_rank,
                                  potential_type_nm,
                                  resource_name,
                                  m1_resource_id,
                                  m1_resource_name_and_role,
                                  m2_resource_id,
                                  m2_resource_name_and_role,
                                  m3_resource_id,
                                  m3_resource_name_and_role,
                                  m4_resource_id,
                                  m4_resource_name_and_role,
                                  m5_resource_id,
                                  m5_resource_name_and_role,
                                  m6_resource_id,
                                  m6_resource_name_and_role,
                                  cust_account_id,
                                  cust_acct_site_id,
                                  parent_party_id,
                                  parent_party_name,
                                  gparent_party_id,
                                  gparent_party_name,
                                  resource_id,
                                  role_id,
                                  group_id,
                                  start_date_active,
                                  end_date_active,
                                  role_name,
                                  group_name,
                                  access_id,
                                  create_view_lead_oppty,
                                  cust_segment_code,
                                  contact_title,
                                  contact_name,
                                  contact_phone,
                                  potential_id,
                                  org_contact_id,
                                  rel_party_id,
                                  relationship_id,
                                  per_party_id
                                 )
    (SELECT nvl(x.rsd_user_id, -1) rsd_user_id,
        rownum sort_id, 
        nvl(x.user_id, -1) user_id,
        nvl(x.m1_user_id, -1) m1_user_id,
        nvl(x.m2_user_id, -1) m2_user_id,
        nvl(x.m3_user_id, -1) m3_user_id,
        nvl(x.org_type, 'XX') org_type,      
        nvl(x.potential_type_cd, 'NEW') potential_type_cd,
        nvl(x.od_site_full_sic_code, 'XX') od_site_full_sic_code,
        nvl((select sic.sic_group_type from xxcrm.xxbi_od_sic_code_mapping sic
             where sic.sic_code =  x.od_site_sic_code
            ), 'XX'
           ) od_site_sic_code,
        nvl(x.od_site_wcw, -1) od_site_wcw,
        nvl((select id from apps.xxbi_cust_wcw_range_dim_v wcw
             where  x.od_site_wcw between wcw.low_val and wcw.high_val and rownum <2 
            ), 'XX'
           ) od_site_wcw_range,
        nvl(x.city, 'XX') city,
        nvl(x.state_province, 'XX') state_province,
        nvl(x.postal_code, 'XX') postal_code,
        nvl(x.cust_loyalty_code, 'XX') cust_loyalty_code,
        nvl(x.party_revenue_band, 'XX') party_revenue_band,
        nvl(x.site_use, 'XX') site_use_id,
        nvl((select value from apps.XXBI_PARTY_SITE_USES_DIM_V sud
             where sud.id = x.site_use and rownum <2 
            ), 'XX'
           ) site_use,
        nvl(x.org_site_status, 'X') org_site_status,
        x.duplicate_view,
        x.comparable_potential_amt,
        x.org_number,
        x.org_name,
        x.org_site_number,
        x.site_name,
        x.site_address,
        x.last_activity_date,
        nvl(x.m4_user_id, -1) m4_user_id,
        nvl(x.m5_user_id, -1) m5_user_id,
        nvl(x.m6_user_id, -1) m6_user_id,
        x.party_site_id,
        x.party_id,
        x.location_id,
        nvl(x.site_rank, -1) site_rank,
        nvl(x.potential_type_nm, 'No Model') potential_type_nm,
        x.resource_name,
        x.m1_resource_id,
        x.m1_resource_name_and_role,
        x.m2_resource_id,
        x.m2_resource_name_and_role,
        x.m3_resource_id,
        x.m3_resource_name_and_role,
        x.m4_resource_id,
        x.m4_resource_name_and_role,
        x.m5_resource_id,
        x.m5_resource_name_and_role,
        x.m6_resource_id,
        x.m6_resource_name_and_role,
        x.cust_account_id,
        x.cust_acct_site_id,
        x.parent_party_id, 
        x.parent_party_name,
        x.gparent_party_id,
        x.gparent_party_name,
        x.resource_id,
        x.role_id,
        x.group_id,
        x.start_date_active,
        x.end_date_active,
        x.role_name,
        x.group_name,
        x.access_id,
        x.create_view_lead_oppty,
        x.cust_segment_code,
        x.contact_title,
        x.contact_name,
        x.contact_phone,
        x.potential_id,
        x.org_contact_id,
        x.rel_party_id,
        x.relationship_id,
        x.per_party_id
    from (select /*+ full(tas) parallel(tas, 6) full(psd) parallel(psd, 6) 
                     full(csd) parallel(csd, 6) full(xnr) full(gmb)
                 */
                gmb.rsd_user_id,
                gmb.user_id,
                gmb.m1_user_id,
                gmb.m2_user_id,
                gmb.m3_user_id,
                psd.org_type,
                psd.potential_type_cd,
                psd.od_site_sic_code,
                psd.od_site_wcw,
                psd.city,
                nvl(decode(psd.country,'US',psd.state,psd.province),'XX') state_province,
                psd.postal_code,
                psd.cust_loyalty_code,
                psd.party_revenue_band,
                psd.site_use,
                psd.org_site_status,
                psd.comparable_potential_amt,
                psd.org_number,
                psd.party_name org_name,
                psd.org_site_number,
                psd.address_lines_phonetic site_name,
                (CASE NVL(psd.address_style,'-9X9Y9Z') WHEN 'AS_DEFAULT' THEN                
                          psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code                                       
                     WHEN '-9X9Y9Z' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code
                     WHEN 'JP' THEN
                             psd.postal_code
                          || '.'
                          || psd.state
                          || '.'
                          || psd.city
                          || '.'
                          || psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address_lines_phonetic
                     WHEN 'NE' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                          || '.'
                          || psd.city
                     WHEN 'POSTAL_ADDR_DEF' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.city
                          || '.'
                          || psd.county
                          || '.'
                          || psd.state
                          || '.'
                          || psd.province
                          || '.'
                          || psd.postal_code
                     WHEN 'POSTAL_ADDR_US' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.city
                          || '.'
                          || psd.county
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                     WHEN 'SA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.province
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.postal_code
                     WHEN 'SE' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.postal_code
                          || '.'
                          || psd.city
                          || '.'
                          || psd.state
                     WHEN 'UAA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                 WHEN 'AS_DEFAULT_CA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.province
                          || '.'
                          || psd.postal_code
                 ELSE
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code
                     END ) site_address,
                psd.last_activity_date,
                gmb.m4_user_id,
                gmb.m5_user_id,
                gmb.m6_user_id,
                psd.party_site_id,
                psd.party_id,
                psd.location_id,
                NVL(xnr.new_rank, psd.site_rank) site_rank,
                psd.potential_type_nm,
                gmb.resource_name,
                gmb.m1_resource_id,
                gmb.m1_resource_name_and_role,
                gmb.m2_resource_id,
                gmb.m2_resource_name_and_role,
                gmb.m3_resource_id,
                gmb.m3_resource_name_and_role,
                gmb.m4_resource_id,
                gmb.m4_resource_name_and_role,
                gmb.m5_resource_id,
                gmb.m5_resource_name_and_role,
                gmb.m6_resource_id,
                gmb.m6_resource_name_and_role,
                psd.cust_account_id,
                psd.cust_acct_site_id,
                psd.parent_party_id,
                psd.parent_party_name,
                psd.gparent_party_id,
                psd.gparent_party_name,
                gmb.resource_id,
                gmb.role_id,
                gmb.group_id,
                gmb.start_date_active,
                gmb.end_date_active,
                gmb.role_name,
                gmb.group_name,
                tas.access_id,
                psd.create_view_lead_oppty,
                psd.od_site_full_sic_code,
                psd.cust_segment_code,
                csd.job_title contact_title,
                csd.party_name contact_name,
                csd.formated_phone contact_phone,
                psd.potential_id,
                csd.org_contact_id,
                csd.rel_party_id,
                csd.relationship_id,
                csd.per_party_id,
                'N' duplicate_view
         FROM   xxcrm.xxbi_terent_asgnmnt_fct_mv tas,
                xxcrm.xxbi_party_site_data_fct_mv psd,
                xxcrm.xxbi_last_site_contact_mv  csd,
                xxcrm.xxscs_potential_new_rank   xnr,
                xxcrm.xxbi_group_mbr_info_mv     gmb
         WHERE  tas.entity_type      = 'PARTY_SITE'
           AND  psd.party_site_id    = tas.entity_id
           AND  csd.party_site_id(+) = psd.party_site_id
           AND  xnr.party_site_id(+) = psd.party_site_id
           AND  xnr.potential_id(+)  = psd.potential_id
           AND  xnr.potential_type_cd(+) = psd.potential_type_cd
           AND  gmb.resource_id = tas.resource_id
           AND  gmb.role_id     = tas.role_id
           AND  gmb.group_id    = tas.group_id
         -- Union added to duplicate sites for users spanning across multiple RSD's in the current RSD partition
         UNION
         SELECT xxbi_utility_pkg.get_rsd_user_id(gmb.user_id)  rsd_user_id,
                gmb.user_id,
                gmb.m1_user_id,
                gmb.m2_user_id,
                gmb.m3_user_id,
                psd.org_type,
                psd.potential_type_cd,
                psd.od_site_sic_code,
                psd.od_site_wcw,
                psd.city,
                nvl(decode(psd.country,'US',psd.state,psd.province),'XX') state_province,
                psd.postal_code,
                psd.cust_loyalty_code,
                psd.party_revenue_band,
                psd.site_use,
                psd.org_site_status,
                psd.comparable_potential_amt,
                psd.org_number,
                psd.party_name org_name,
                psd.org_site_number,
                psd.address_lines_phonetic site_name,
                (CASE NVL(psd.address_style,'-9X9Y9Z') WHEN 'AS_DEFAULT' THEN                
                          psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code                                       
                     WHEN '-9X9Y9Z' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code
                     WHEN 'JP' THEN
                             psd.postal_code
                          || '.'
                          || psd.state
                          || '.'
                          || psd.city
                          || '.'
                          || psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address_lines_phonetic
                     WHEN 'NE' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                          || '.'
                          || psd.city
                     WHEN 'POSTAL_ADDR_DEF' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.city
                          || '.'
                          || psd.county
                          || '.'
                          || psd.state
                          || '.'
                          || psd.province
                          || '.'
                          || psd.postal_code
                     WHEN 'POSTAL_ADDR_US' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.city
                          || '.'
                          || psd.county
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                     WHEN 'SA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.province
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.postal_code
                     WHEN 'SE' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.postal_code
                          || '.'
                          || psd.city
                          || '.'
                          || psd.state
                     WHEN 'UAA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.state
                          || '.'
                          || psd.postal_code
                 WHEN 'AS_DEFAULT_CA' THEN
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.city
                          || '.'
                          || psd.province
                          || '.'
                          || psd.postal_code
                 ELSE
                             psd.address1
                          || '.'
                          || psd.address2
                          || '.'
                          || psd.address3
                          || '.'
                          || psd.address4
                          || '.'
                          || psd.state
                          || '.'
                          || psd.county
                          || '.'
                          || psd.city
                          || '.'
                          || psd.postal_code
                     END ) site_address,
                psd.last_activity_date,
                gmb.m4_user_id,
                gmb.m5_user_id,
                gmb.m6_user_id,
                psd.party_site_id,
                psd.party_id,
                psd.location_id,
                NVL(xnr.new_rank, psd.site_rank) site_rank,
                psd.potential_type_nm,
                gmb.resource_name,
                gmb.m1_resource_id,
                gmb.m1_resource_name_and_role,
                gmb.m2_resource_id,
                gmb.m2_resource_name_and_role,
                gmb.m3_resource_id,
                gmb.m3_resource_name_and_role,
                gmb.m4_resource_id,
                gmb.m4_resource_name_and_role,
                gmb.m5_resource_id,
                gmb.m5_resource_name_and_role,
                gmb.m6_resource_id,
                gmb.m6_resource_name_and_role,
                psd.cust_account_id,
                psd.cust_acct_site_id,
                psd.parent_party_id,
                psd.parent_party_name,
                psd.gparent_party_id,
                psd.gparent_party_name,
                gmb.resource_id,
                gmb.role_id,
                gmb.group_id,
                gmb.start_date_active,
                gmb.end_date_active,
                gmb.role_name,
                gmb.group_name,
                tas.access_id,
                psd.create_view_lead_oppty,
                psd.od_site_full_sic_code,
                psd.cust_segment_code,
                csd.job_title contact_title,
                csd.party_name contact_name,
                csd.formated_phone contact_phone,
                psd.potential_id,
                csd.org_contact_id,
                csd.rel_party_id,
                csd.relationship_id,
                csd.per_party_id,
                'Y' duplicate_view
         FROM   xxcrm.xxbi_terent_asgnmnt_fct_mv tas,
                xxcrm.xxbi_party_site_data_fct_mv psd,
                xxcrm.xxbi_last_site_contact_mv  csd,
                xxcrm.xxscs_potential_new_rank   xnr,
                (SELECT a.* 
                 FROM   xxcrm.xxbi_group_mbr_info_mv a,
                        (
                         -- Subquery to get users having site assignments spanning multiple rsd's
                         SELECT user_id, count(distinct rsd_user_id)
                         FROM   xxcrm.xxbi_group_mbr_info_mv
                         WHERE  user_id is not null
                           AND  rsd_user_id is not null
                         GROUP BY user_id
                         HAVING COUNT(DISTINCT rsd_user_id) > 1
                        ) b
                 WHERE a.user_id = b.user_id
                   AND a.rsd_user_id <> xxbi_utility_pkg.get_rsd_user_id(a.user_id)
                ) gmb
         WHERE  tas.entity_type      = 'PARTY_SITE'
           AND  psd.party_site_id    = tas.entity_id
           AND  csd.party_site_id(+) = psd.party_site_id
           AND  xnr.party_site_id(+) = psd.party_site_id
           AND  xnr.potential_id(+)  = psd.potential_id
           AND  xnr.potential_type_cd(+) = psd.potential_type_cd
           AND  gmb.resource_id = tas.resource_id
           AND  gmb.role_id     = tas.role_id
           AND  gmb.group_id    = tas.group_id
         --ORDER BY gmb.rsd_user_id, NVL(xnr.new_rank, psd.site_rank) desc, psd.comparable_potential_amt desc
         ORDER BY  1 ASC, 30 DESC, 17 DESC
        ) x
      );
        
    COMMIT;

    -- Gather Stats
    dbms_stats.gather_table_stats(ownname => 'xxcrm',   
                                  tabname => 'xxbi_user_site_dtl',   
                                  degree  => 8
                                 );

  END xxbi_populate_rsddata;

  PROCEDURE xxbi_cmplte_rfrsh_mv(x_error_code   OUT nocopy NUMBER,   
                                 x_error_buf    OUT nocopy VARCHAR2,   
                                 p_mv_name      IN  VARCHAR2,
                                 p_refresh_flag IN  VARCHAR2,   
                                 p_load_flag    IN  VARCHAR2,
      				   p_rebuild_flag IN VARCHAR2, 
					   p_create_log  IN VARCHAR2

                                ) AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- |Name             :  xxbi_cmplte_rfrsh_mv                           |
  -- |Description      :  Wrapper procedure for MV complete refresh      |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author              Remarks                  |
  -- |=======   ==========  ================    =========================|
  -- |1.0       19-APR-2010 Kishore Jena        Initial version          |
  -- +===================================================================+

    l_error_code NUMBER;
    l_error_buf  VARCHAR2(1000);

  BEGIN
    IF p_mv_name = 'CONTACTS' THEN
      xxbi_cmplte_rfrsh_contacts_mv(l_error_code,
                                    l_error_buf,
                                    p_refresh_flag,
                                    p_load_flag,
						p_rebuild_flag, 
						p_create_log  

                                   );
    ELSIF p_mv_name = 'ASGNMNTS' THEN
      xxbi_cmplte_rfrsh_asgnmnts_mv(l_error_code,
                                    l_error_buf,
                                    p_refresh_flag,
                                    p_load_flag,
						p_rebuild_flag, 
						p_create_log 
                                   );
    ELSIF p_mv_name = 'SITEDATA' THEN
      xxbi_cmplte_rfrsh_sitedata_mv(l_error_code,
                                    l_error_buf,
                                    p_refresh_flag,
                                    p_load_flag,
						p_rebuild_flag, 
						p_create_log 
                                   );
    ELSIF p_mv_name = 'RSDDATA' THEN
      xxbi_populate_rsddata(l_error_code,
                            l_error_buf
                           );
    END IF;

    x_error_code := l_error_code;
    x_error_buf  := l_error_buf;

  END xxbi_cmplte_rfrsh_mv;

END xxbi_fast_refresh_pkg;

/
SHOW ERRORS;
