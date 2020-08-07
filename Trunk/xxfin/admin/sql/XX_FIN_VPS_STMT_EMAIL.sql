create or replace Function XX_FIN_VPS_STMT_EMAIL ( p_party_id IN NUMBER )
   RETURN VARCHAR2
IS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_CUST_CONV_VPSUPLOAD_PKG                                                     |
  -- |                                                                                            |
  -- |  Description:  This function to email VPS Customers.                      				  |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
   lv_cc_email_address    VARCHAR2(4000);

BEGIN

SELECT listagg(hcp.email_address,', ')
            within group (order by hca.party_id) as list 
  INTO lv_cc_email_address
  FROM hz_relationships hr ,
    hz_cust_accounts_all hca ,
    hz_parties obj ,
    hz_relationships rel ,
    hz_org_contacts hoc ,
    hz_contact_points hcp ,
    hz_parties sub
  WHERE 1                   =1
	  AND hr.subject_id         =p_party_id
	  AND hr.relationship_code  ='PAYER_GROUP_PARENT_OF'
	  AND hr.subject_table_name ='HZ_PARTIES'
	  AND hr.subject_type       ='ORGANIZATION'
	  AND hr.object_id          =hca.party_id
	  AND hca.party_id          = rel.object_id
	  AND hca.party_id          = obj.party_id
	  AND rel.subject_id        = sub.party_id
	  AND rel.relationship_type = 'CONTACT'
	  AND rel.directional_flag  = 'F'
	  AND rel.relationship_id   =hoc.party_relationship_id
	  AND hoc.job_title         <>'Core/ Non- Core Backup - Billing'
	  AND rel.party_id          = hcp.owner_table_id
	  AND hcp.owner_table_name  = 'HZ_PARTIES';
RETURN lv_cc_email_address;
EXCEPTION 
	WHEN NO_DATA_FOUND THEN 
		lv_cc_email_address:=NULL;
		RETURN lv_cc_email_address;
	WHEN OTHERS THEN
		lv_cc_email_address:=NULL;
		RETURN lv_cc_email_address;	
END;
/
