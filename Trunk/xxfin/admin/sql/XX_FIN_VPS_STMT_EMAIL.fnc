create or replace Function XX_FIN_VPS_STMT_EMAIL ( p_party_id IN NUMBER )
   RETURN VARCHAR2
IS
   lv_cc_email_address    VARCHAR2(4000);

BEGIN

SELECT listagg(hcp.email_address,', ')
            within group (order by hca.party_id) as list 
  INTO lv_cc_email_address
  FROM hz_cust_accounts_all hca ,
    hz_parties obj ,
    hz_relationships rel ,
    hz_org_contacts hoc ,
    hz_contact_points hcp ,
    hz_parties sub
  WHERE 1                   =1
	  AND hca.party_id         =p_party_id
	  AND hca.party_id          = rel.object_id
	  AND hca.party_id          = obj.party_id
	  AND rel.subject_id        = sub.party_id
	  AND rel.relationship_type = 'CONTACT'
	  AND rel.directional_flag  = 'F'
	  AND rel.relationship_id   =hoc.party_relationship_id
	  AND UPPER(hoc.job_title) like 'CORE%NON%BACKUP%BILLING%'
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