/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                					               |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_SETUP_PKG.pls                       |
-- | Description :  Package for XX_CDH_ACCOUNT_SETUP_REQ_PKG table     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  27-Sep-2007 Yusuf Ali	        Initial draft version      |
-- |1.1       17-Oct-2007 Kathirvel P	  Included the procedures    | 
-- |                                        insert_orig_sys_ref        |
-- |						        get_sfa_aops_det           |
-- |        					  process_contact_point_osr  |
-- |1.2       07-Nov-2007 Kathirvel P	  Included the procedures    | 
-- |                                        process_org_contact_osr    |
-- |1.3       14-Nov-2007 Kathirvel P	  Included the procedures    | 
-- |                                        process_contacts_osr       |
-- |1.4       10-Jan-2008 Kathirvel P       Included procedure         |
-- |                                        get_party_relation_id      |
-- |1.5       21-Mar-2008 Kathirvel P	  Included the procedure     |
-- |                                        get_profile_id             |
-- |1.6       31-Mar-2008 Kathirvel P       Included the procedure     |
-- |                                        get_acct_contact_id        |
-- |1.7       29-Apr-2008 Kathirvel P       Included a Procedure       |
-- |                                        get_sfa_request_acct_id    |
-- |1.8       07-May-2008 Kathirvel P       Included a procedure       |
-- |                                        get_person_acct_contact_id |
-- |1.9       23-Jul-2008 Kathirvel P       Included a procedure       |
-- |                                        get_party_site_details     |
-- |2.3       11-Dec-2009 Naga Kalyan       CR#687.New procedure       |
-- |                                        create_acct_apcontact to   |
-- |                                        create ap contact at       |
-- |                                        bill_to site level.        |
-- +===================================================================+
*/
CREATE OR REPLACE
PACKAGE XX_CDH_ACCOUNT_SETUP_REQ_PKG
AS
  
  PROCEDURE get_request_id
  (   p_request_id               IN       	xx_cdh_account_setup_req.request_id%TYPE,
      x_request_id               OUT NOCOPY     xx_cdh_account_setup_req.request_id%TYPE,
      x_return_status            OUT NOCOPY     VARCHAR2,
      x_error_message	         OUT NOCOPY     VARCHAR2
  );

  PROCEDURE get_party_id (
      p_osr                    IN   hz_cust_accounts.orig_system_reference%TYPE,
      x_party_id               OUT  NOCOPY    hz_cust_accounts.party_id%TYPE,
      x_account_num            OUT  NOCOPY    hz_cust_accounts.account_number%TYPE,
      x_cust_account_id        OUT  NOCOPY    hz_cust_accounts.cust_account_id%TYPE,      
      x_return_status          OUT  NOCOPY    VARCHAR2,
      x_error_message	       OUT  NOCOPY    VARCHAR2
   );

  PROCEDURE update_acct_setup_req
  (   p_request_id               IN     xx_cdh_account_setup_req.request_id%TYPE,
      p_account_num              IN     xx_cdh_account_setup_req.account_number%TYPE,
      p_cust_account_id		   IN	    xx_cdh_account_setup_req.cust_account_id%TYPE,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY VARCHAR2
  );

  PROCEDURE insert_orig_sys_ref
  (   p_orig_system		   IN    hz_orig_sys_references.orig_system%TYPE,
      p_orig_sys_ref		   IN	   hz_orig_sys_references.orig_system_reference%TYPE,
      p_owner_table_name         IN    hz_orig_sys_references.owner_table_name%TYPE,
      p_owner_table_id		   IN	   hz_orig_sys_references.owner_table_id%TYPE,
      x_return_status            OUT   NOCOPY   VARCHAR2,
      x_error_message	         OUT   NOCOPY   VARCHAR2
  );

  PROCEDURE get_sfa_aops_det
  (   p_orig_system		   IN     hz_orig_sys_references.orig_system%TYPE,
      p_contact_point_osr	   IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      p_person_osr               IN     hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_osr                  IN     hz_orig_sys_references.orig_system_reference%TYPE,
      x_trans_type               OUT    NOCOPY  VARCHAR2,
      x_relation_id              OUT    NOCOPY  hz_parties.party_id%TYPE,
      x_contact_point_id         OUT    NOCOPY  hz_org_contacts.org_contact_id%TYPE,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );

  PROCEDURE process_contact_point_osr
  (   p_party_id                 IN	   hz_parties.party_id%TYPE,
      p_person_id                IN	   hz_parties.party_id%TYPE,
      p_contact_point_id         IN    hz_org_contacts.org_contact_id%TYPE,
      p_orig_system		   IN    hz_orig_sys_references.orig_system%TYPE,
      p_orig_sys_ref		   IN	   hz_orig_sys_references.orig_system_reference%TYPE,
      x_person_relation_id       OUT   NOCOPY   hz_parties.party_id%TYPE,
      x_return_status            OUT   NOCOPY   VARCHAR2,
      x_error_message	         OUT   NOCOPY   VARCHAR2
  );

  PROCEDURE get_sfa_aops_det
  (   p_orig_system		   IN    hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr	         IN	   hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_osr                  IN    hz_orig_sys_references.orig_system_reference%TYPE,
      x_trans_type               OUT   NOCOPY   VARCHAR2,
      x_person_id                OUT   NOCOPY   hz_parties.party_id%TYPE,
      x_org_id                   OUT   NOCOPY   hz_parties.party_id%TYPE,
      x_org_contact_id           OUT   NOCOPY   hz_org_contacts.org_contact_id%TYPE,
      x_org_contact_role_id      OUT   NOCOPY   hz_org_contact_roles.org_contact_role_id%TYPE,
      x_return_status            OUT   NOCOPY   VARCHAR2,
      x_error_message	         OUT   NOCOPY   VARCHAR2
  );

  PROCEDURE process_org_contact_osr
  (   p_party_id                 IN	   hz_parties.party_id%TYPE,
      p_person_id                IN	   hz_parties.party_id%TYPE,
      p_org_contact_id           IN    hz_org_contacts.org_contact_id%TYPE,
      p_org_contact_role_id      IN    hz_org_contact_roles.org_contact_role_id%TYPE,
      p_orig_system		   IN    hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr		   IN	   hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_contact_role_osr	   IN	   hz_orig_sys_references.orig_system_reference%TYPE,
      x_return_status            OUT   NOCOPY   VARCHAR2,
      x_error_message	         OUT   NOCOPY   VARCHAR2
  );

  PROCEDURE process_contacts_osr
  (   p_party_id                 IN	    hz_parties.party_id%TYPE,
      p_person_id                IN	    hz_parties.party_id%TYPE,
      p_org_contact_id           IN     hz_org_contacts.org_contact_id%TYPE,
      p_org_contact_role_id      IN     hz_org_contact_roles.org_contact_role_id%TYPE,
      p_contact_point1_id        IN     hz_org_contacts.org_contact_id%TYPE,
      p_contact_point2_id        IN     hz_org_contacts.org_contact_id%TYPE,
      p_orig_system		   IN     hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr		   IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      p_contact_point1_osr	   IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      p_contact_point2_osr	   IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );

  PROCEDURE get_party_relation_id
  (   p_orig_system              IN     hz_orig_sys_references.orig_system%TYPE,
      p_party_osr                IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      p_person_osr               IN     hz_orig_sys_references.orig_system_reference%TYPE,
      x_contact_relation_id      OUT    NOCOPY  hz_parties.party_id%TYPE,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );

  PROCEDURE get_profile_id
  (   p_account_osr                          IN  VARCHAR2,
	x_acct_profile_id                      OUT NOCOPY NUMBER,
	x_site_profile_id                      OUT NOCOPY NUMBER,
	x_return_status 		               OUT NOCOPY VARCHAR2,
	x_error_message                        OUT NOCOPY VARCHAR2
  );

  PROCEDURE get_acct_contact_id
  (   p_cust_acct_osr            IN    hz_orig_sys_references.orig_system_reference%TYPE,
      p_acct_contact_osr         IN    hz_orig_sys_references.orig_system_reference%TYPE,
      x_acct_contact_id          OUT   NOCOPY   hz_cust_account_roles.cust_account_role_id%TYPE,
      x_return_status            OUT   NOCOPY   VARCHAR2,
      x_error_message	         OUT   NOCOPY   VARCHAR2
  );

  PROCEDURE get_sfa_request_acct_id
  (   p_request_id               IN     NUMBER,
      x_bill_to_site_id          OUT    NOCOPY  NUMBER,                                                                                                                                                                                                   
      x_ship_to_site_id          OUT    NOCOPY  NUMBER,
      x_party_id                 OUT    NOCOPY  NUMBER,                                                                                                                                                                                                   
      x_acct_number              OUT    NOCOPY  NUMBER,
      x_cust_acct_id             OUT    NOCOPY  NUMBER,
      x_orig_system              OUT    NOCOPY  VARCHAR2,
      x_orig_sys_reference       OUT    NOCOPY  VARCHAR2,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );

  PROCEDURE get_person_acct_contact_id
  (   p_orig_system		   IN     hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr 	   IN	    hz_orig_sys_references.orig_system_reference%TYPE,
      x_person_id                OUT    NOCOPY  NUMBER,          
      x_acct_contact_id          OUT    NOCOPY  NUMBER,                                                                                                                                                                                         
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );

  PROCEDURE get_party_site_details
  (   p_orig_system		   IN     hz_orig_sys_references.orig_system%TYPE,
      p_acct_site_osr		   IN     hz_orig_sys_references.orig_system_reference%TYPE,
      x_party_site_id            OUT    NOCOPY  NUMBER,
      x_party_id			   OUT    NOCOPY  NUMBER,
      x_location_id              OUT    NOCOPY  NUMBER,
      x_orig_system_reference    OUT    NOCOPY  VARCHAR2,
      x_status                   OUT    NOCOPY  VARCHAR2, 
      x_cust_acct_id             OUT    NOCOPY  NUMBER,                                                                                                                                                                             
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	         OUT    NOCOPY  VARCHAR2
  );
  
  PROCEDURE get_party_site_details
  (   p_orig_system		     IN     hz_orig_sys_references.orig_system%TYPE,
      p_acct_site_osr		   IN     hz_orig_sys_references.orig_system_reference%TYPE,
      p_party_site_id      IN     NUMBER,
      x_party_site_id            OUT    NOCOPY  NUMBER,
      x_party_id			           OUT    NOCOPY  NUMBER,
      x_location_id              OUT    NOCOPY  NUMBER,
      x_orig_system_reference    OUT    NOCOPY  VARCHAR2,
      x_status                   OUT    NOCOPY  VARCHAR2,
      x_cust_acct_id             OUT    NOCOPY  NUMBER,
      x_return_status            OUT    NOCOPY  VARCHAR2,
      x_error_message	           OUT    NOCOPY  VARCHAR2
  ); 
  
  PROCEDURE create_acct_ap_contact
  (
      p_cust_account_id         IN     hz_cust_accounts.cust_account_id%TYPE,
      p_request_id              IN     xx_cdh_account_setup_req.request_id%TYPE,
      p_party_id                IN     hz_cust_accounts.party_id%TYPE,
      x_return_status           OUT    NOCOPY  VARCHAR2,
      x_error_message	        OUT    NOCOPY  VARCHAR2
  );

END XX_CDH_ACCOUNT_SETUP_REQ_PKG;
/
