create or replace
PACKAGE BODY XX_CDH_OU_DEL
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_OU_DEL.pkb                                  |
-- | Description :  Code to remove site use OSR ref for OU Corrections |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  02-Nov-2009 Indra Varada       Initial draft version     |
-- +===================================================================+
PROCEDURE fix_site_use_ou
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_commit            IN  VARCHAR2
   ,p_osr      		IN  VARCHAR2
   ,p_entity_type       IN  VARCHAR2
)
AS
l_owner_id        NUMBER;
l_ps_owner_id     NUMBER;

CURSOR s_use_cur (p_site_id IN NUMBER) IS
SELECT site_use_id FROM hz_cust_site_uses_all
WHERE cust_acct_site_id = p_site_id;

BEGIN

IF p_entity_type = 'HZ_CUST_SITE_USES_ALL' THEN
 
 SELECT owner_table_id INTO l_owner_id
 FROM hz_orig_sys_references
 WHERE orig_system_reference = p_osr
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_CUST_SITE_USES_ALL'
 AND status = 'A';

 fnd_file.put_line (fnd_file.log, 'Site Use ID:' || l_owner_id);
 
 UPDATE hz_orig_sys_references SET status = 'I',last_update_date = SYSDATE
 WHERE orig_system_reference = p_osr
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_CUST_SITE_USES_ALL'
 AND status = 'A';

 fnd_file.put_line (fnd_file.log,'Number Of Rows Inactivated in OSR Table : ' || SQL%ROWCOUNT);
 

 UPDATE hz_cust_site_uses_all set status = 'I', primary_flag = 'N',last_update_date = SYSDATE
 WHERE site_use_id = l_owner_id;

 fnd_file.put_line (fnd_file.log,'Number Of Rows updated in Site Uses Table : ' || SQL%ROWCOUNT);

ELSIF p_entity_type = 'HZ_CUST_ACCT_SITES_ALL' THEN

 SELECT owner_table_id INTO l_owner_id
 FROM hz_orig_sys_references
 WHERE orig_system_reference = p_osr
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
 AND status = 'A';
 
 fnd_file.put_line (fnd_file.log, 'Site ID:' || l_owner_id);
 
 
 SELECT party_site_id INTO l_ps_owner_id
 FROM hz_cust_acct_sites_all
 WHERE cust_acct_site_id = l_owner_id;
 
 fnd_file.put_line (fnd_file.log, 'Party Site ID:' || l_ps_owner_id);
 
 UPDATE hz_orig_sys_references SET status = 'I', last_update_date = SYSDATE
 WHERE owner_table_id = l_ps_owner_id
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_PARTY_SITES'
 AND status = 'A';
 
 UPDATE hz_party_sites set status = 'I'
 WHERE party_site_id = l_ps_owner_id;
 
 UPDATE hz_party_site_uses set status = 'I'
 WHERE party_site_id = l_ps_owner_id;
 
 
 UPDATE hz_orig_sys_references SET status = 'I', last_update_date = SYSDATE
 WHERE orig_system_reference = p_osr
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
 AND status = 'A';

 fnd_file.put_line (fnd_file.log,'Number Of Rows Inactivated In OSR Table : ' || SQL%ROWCOUNT);

 UPDATE hz_cust_acct_sites_all set status = 'I',last_update_date = SYSDATE
 WHERE cust_acct_site_id = l_owner_id;
 
 FOR l_use_cur IN s_use_cur (l_owner_id) LOOP
 
    UPDATE hz_cust_site_uses_all set status = 'I',primary_flag = 'N', last_update_date = SYSDATE
    WHERE site_use_id = l_use_cur.site_use_id;
     
     fnd_file.put_line (fnd_file.log,'Number Of Site Uses Updated (Site UseId - ' || l_use_cur.site_use_id || ')' || SQL%ROWCOUNT);
       
    UPDATE hz_orig_sys_references set status = 'I', last_update_date = SYSDATE
    WHERE owner_table_id = l_use_cur.site_use_id
    AND owner_table_name = 'HZ_CUST_SITE_USES_ALL';
    
      fnd_file.put_line (fnd_file.log,'Number Of Site Use OSRs Updated (Site UseId - ' || l_use_cur.site_use_id || ')' || SQL%ROWCOUNT);
      
    
 END LOOP;

 fnd_file.put_line (fnd_file.log,'Number Of Rows updated in Sites Table : ' || SQL%ROWCOUNT);

ELSIF p_entity_type = 'HZ_PARTY_SITES' THEN

 SELECT owner_table_id INTO l_ps_owner_id
 FROM hz_orig_sys_references
 WHERE orig_system_reference = p_osr
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_PARTY_SITES'
 AND status = 'A';
 
 fnd_file.put_line (fnd_file.log, 'Party Site ID:' || l_ps_owner_id);
 
 UPDATE hz_orig_sys_references SET status = 'I', last_update_date = SYSDATE
 WHERE owner_table_id = l_ps_owner_id
 AND orig_system = 'A0'
 AND owner_table_name = 'HZ_PARTY_SITES'
 AND status = 'A';
 
 UPDATE hz_party_sites set status = 'I'
 WHERE party_site_id = l_ps_owner_id;
 
 UPDATE hz_party_site_uses set status = 'I'
 WHERE party_site_id = l_ps_owner_id;

END IF;

 IF p_commit = 'Y' THEN
     COMMIT;
 ELSE
     ROLLBACK;
 END IF;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    fnd_file.put_line (fnd_file.log,'Exception in fix_invalid_cnt: ' || SQLERRM);
    x_retcode  := 2;
END fix_site_use_ou;
END XX_CDH_OU_DEL;
/
SHOW ERRORS;
EXIT;