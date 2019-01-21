/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAC Consulting Organization                 |
-- +===================================================================+
-- | Name        :  XX_GET_PARTY_ID.prc                                |
-- | Description :  Procedure for E1328_BSD_iReceivables_interface     |
-- |                conversion                                         |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  03-Oct-2007 Ramesh Raghupathi Initial draft version      |
-- +===================================================================+
*/

CREATE OR REPLACE PROCEDURE xx_get_party_id
 ( p_cust_acct_cnt_os     IN       VARCHAR2
 , p_cust_acct_cnt_osr    IN       VARCHAR2
 , x_party_id             OUT      NUMBER
 , x_retcode              OUT      VARCHAR2
 )
IS
  ln_cust_acct_site_id     hz_cust_acct_sites_all.cust_acct_site_id%TYPE; 
  lv_billto_orig_sys_ref   hz_cust_acct_sites_all.orig_system_reference%TYPE;
  ln_bill_to_site_id       hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
  ln_org_contact_id        number;
  ln_relationship_party_id number;
  
  le_contact_not_found       EXCEPTION;   
  le_relationship_not_found  EXCEPTION;

  CURSOR lc_fetch_rel_party_id_cur ( p_org_contact_id IN NUMBER )
  IS
  SELECT hr.party_id
  FROM   hz_relationships hr,
         hz_org_contacts  hoc
  WHERE  hoc.org_contact_id = p_org_contact_id
  AND    hr.relationship_id = hoc.party_relationship_id
  AND    hr.status = 'A';

BEGIN

   BEGIN
     xx_external_users_pkg.get_site_use_id 
     ( p_cust_acct_cnt_os
     , p_cust_acct_cnt_osr
     , 'HZ_ORG_CONTACTS'
     , ln_org_contact_id
     );

     dbms_output.put_line ('ln_contact_id: '|| ln_org_contact_id );

     IF ln_org_contact_id IS NULL 
     THEN
       raise le_contact_not_found;
     END IF;   

     FOR lc_fetch_rel_party_id_rec IN lc_fetch_rel_party_id_cur (ln_org_contact_id)
     LOOP
       ln_relationship_party_id := lc_fetch_rel_party_id_rec.party_id;
       EXIT;
     END LOOP; 
 
     dbms_output.put_line ('ln_relationship_party_id: '|| ln_relationship_party_id );
         
     IF ln_relationship_party_id IS NULL 
       THEN
         raise le_relationship_not_found;
     END IF;
     x_party_id := ln_relationship_party_id;

   EXCEPTION
     when le_contact_not_found then  
       x_retcode := 1;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'E1328_BSDNET_iReceivables'
       , p_program_type            => 'CONVERSION'
       , p_program_name            => 'XX_GET_PARTY_ID'
       , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0001_CONTACT_NOT_FOUND'
       , p_error_message           => 'ContactOSR: '|| p_cust_acct_cnt_osr||' from AOPS not found in CDH'
       , p_error_message_severity  => 1 
       );
     when le_relationship_not_found then  
       x_retcode := 1;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'E1328_BSDNET_iReceivables'
       , p_program_type            => 'CONVERSION'
       , p_program_name            => 'XX_GET_PARTY_ID'
       , p_module_name             => 'CDH'
       , p_error_message_code      => 'XX_CDH_0003_RELATIONSHIP_NOT_FOUND'
       , p_error_message           => 'Relationship does not exist for contact: '|| p_cust_acct_cnt_osr ||' with ship to org: ' 
       , p_error_message_severity  => 1 
       );
     when others then 
       x_retcode := 1;
       xx_com_error_log_pub.log_error
       ( p_application_name        => 'E1328_BSDNET_iReceivables'
       , p_program_type            => 'CONVERSION'
       , p_program_name            => 'XX_GET_PARTY_ID'
       , p_module_name             => 'CDH'
       , p_error_message_code      => SQLCODE
       , p_error_message           => SQLERRM
       , p_error_message_severity  => 1 
       );
   END;
END xx_get_party_id;  

