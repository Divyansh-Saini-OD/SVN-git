/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                					                       |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_SETUP_PKG.pkb                       |
-- | Description :  Package for XX_CDH_ACCOUNT_SETUP_REQ_PKG table     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  27-Sep-2007 Yusuf Ali	        Initial draft version      |
-- |1.1       17-Oct-2007 Kathirvel P	  Included the procedures    | 
-- |                                        insert_orig_sys_ref        |
-- |						        get_sfa_aops_det,          |
-- |        					  process_contact_point_osr, |
-- |                                        process_org_contact_osr    |
-- |1.2       07-Nov-2007 Kathirvel P	  Included the procedures    | 
-- |                                        process_org_contact_osr    |
-- |1.3       14-Nov-2007 Kathirvel P	  Included the procedures    | 
-- |                                        process_contacts_osr       |
-- |1.4       28-Nov-2007 Kathirvel P       Changed the procedure      |
-- |                                        process_org_contact_osr    |   
-- |                                        to make contact role as    | 
-- |                                        optional for SFA.          | 
-- |1.5       10-Jan-2008 Kathirvel P       Included procedure         |
-- |                                        get_party_relation_id      |
-- |1.6       31-Mar-2008 Kathirvel P       Included the procedure     |
-- |                                        get_acct_contact_id        |
-- |1.7       28-Apr-2008 Kathirvel P       Initialised the variable   |
-- |                                        lv_return_status to S      |
-- |1.8       29-Apr-2008 Kathirvel P       Included a Procedure       |
-- |                                        get_sfa_request_acct_id    |
-- |1.9       07-May-2008 Kathirvel P       Included a procedure       |
-- |                                        get_person_acct_contact_id |
-- |2.0       18-Jun-2008 Kathirvel P       Included status and Orig_  |
-- |                                        system in all the reference|
-- |                                        of hz_orig_sys_references  |
-- |2.1       26-Jan-2009 Kalyan            Modified cursor in         |
-- |                                        GET_PARTY_RELATION_ID to   |
-- |                                        exclude status of HZ_CUST_ |
-- |                                        ACCOUNTS. Party is always  |
-- |                                        active so the change.      |
-- |                                        Defect 105.                |
-- |2.2       22-Oct-2009 Naga Kalyan       Modified to check if       |
-- |                                        contact_point_id exists    |
-- |                                        along with OSR in          |
-- |                                        process_contacts_osr.      |
-- |2.3       11-Dec-2009 Naga Kalyan       CR#687.New procedure       |
-- |                                        create_acct_ap_contact to  |
-- |                                        create ap contact at       |
-- |                                        bill_to site level.        |
-- |2.4       20-Nov-2013 Avinash B         Modified for R12 Upgrade Retrofit|
-- |2.5       11-Dec-2015 Vasu Raparla      Removed Schema References  |
-- |                                         for R.12.2                |
-- +===================================================================+
*/
CREATE OR REPLACE
PACKAGE BODY XX_CDH_ACCOUNT_SETUP_REQ_PKG
AS
   PROCEDURE get_request_id (
      p_request_id             IN       xx_cdh_account_setup_req.request_id%TYPE,
      x_request_id             OUT      NOCOPY xx_cdh_account_setup_req.request_id%TYPE,
      x_return_status          OUT      NOCOPY VARCHAR2,
      x_error_message	       OUT      NOCOPY VARCHAR2
   )
   IS
   lv_request_id		xx_cdh_account_setup_req.request_id%TYPE;
   BEGIN
      x_return_status := 'S';

      SELECT request_id
        INTO lv_request_id
        FROM xx_cdh_account_setup_req
       WHERE request_id = p_request_id;
	
       x_request_id := lv_request_id;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_return_status := 'E';
	 x_error_message := 'Request ID not found.';
         
      WHEN TOO_MANY_ROWS
      THEN
         x_return_status := 'E';
	 x_error_message := 'Too many records returned.';
      WHEN OTHERS
      THEN
         x_return_status := 'E';
	 x_error_message := 'Unexpected error.';
   END get_request_id;


PROCEDURE get_party_id (
      p_osr                    IN       hz_cust_accounts.orig_system_reference%TYPE,
      x_party_id               OUT      NOCOPY hz_cust_accounts.party_id%TYPE,
      x_account_num            OUT      NOCOPY hz_cust_accounts.account_number%TYPE,
      x_cust_account_id        OUT      NOCOPY hz_cust_accounts.cust_account_id%TYPE,      
      x_return_status          OUT      NOCOPY VARCHAR2,
      x_error_message	       OUT      NOCOPY VARCHAR2
   )
   IS
   lv_party_id                     hz_cust_accounts.party_id%TYPE;
   lv_account_num		   hz_cust_accounts.account_number%TYPE;
   lv_cust_account_id	           hz_cust_accounts.cust_account_id%TYPE;
   BEGIN
      x_return_status := 'S';

      SELECT party_id, account_number, cust_account_id
        INTO lv_party_id, lv_account_num, lv_cust_account_id
        FROM hz_cust_accounts
       WHERE orig_system_reference = p_osr;
	
       x_party_id := lv_party_id;
       x_account_num := lv_account_num;
       x_cust_account_id := lv_cust_account_id;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_return_status := 'E';
	 x_error_message := 'Party ID not found.';
         
      WHEN TOO_MANY_ROWS
      THEN
         x_return_status := 'E';
	 x_error_message := 'Too many records returned.';
      WHEN OTHERS
      THEN
         x_return_status := 'E';
	 x_error_message := 'Unexpected error.';
   END get_party_id;



  PROCEDURE update_acct_setup_req 
  (   p_request_id               IN       xx_cdh_account_setup_req.request_id%TYPE,
      p_account_num              IN       xx_cdh_account_setup_req.account_number%TYPE,
      p_cust_account_id          IN	      xx_cdh_account_setup_req.cust_account_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
  BEGIN
    x_return_status := 'S'; 

    UPDATE xx_cdh_account_setup_req
    SET account_number         = p_account_num,
	cust_account_id        = p_cust_account_id
    WHERE request_id = p_request_id;
    
    IF SQL%ROWCOUNT = 0 THEN
         x_return_status := 'E';
	 x_error_message := 'Request ID not found.  Cannot update with account number.';
    END IF;

    COMMIT;

  EXCEPTION
               
      WHEN OTHERS
      THEN
         x_return_status := 'E';
	 x_error_message := 'Unexpected error.'; 
  END update_acct_setup_req;


/*

The procedure insert_orig_sys_ref is used to create a record in hz_orig_sys_references 
based on the given orig_system,orig_system_references, owner_table_name and owner_table_id.

Since the existing Business Object does not create a record in hz_orig_sys_references, 
we are using a standard granular API HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference.

The API validates the given owner_table_id whether it is existing in the given owner_table_name.
For Example, If you have given  owner_table_id = 12345 and owner_table_name = 'HZ_ORG_CONTACTS', the 
column org_contact_id should have a value of 12345 in the table hz_org_contacts.

*/

  PROCEDURE insert_orig_sys_ref
  (   p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_orig_sys_ref		   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      p_owner_table_name         IN       hz_orig_sys_references.owner_table_name%TYPE,
      p_owner_table_id		   IN		hz_orig_sys_references.owner_table_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
   l_orig_objs             HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
   l_return_status         VARCHAR2(30);
   l_msg_count             NUMBER;
   l_msg_data              VARCHAR2(2000);
   l_error_message         VARCHAR2(2000);

  BEGIN
    	x_return_status := 'S'; 

	l_orig_objs.owner_table_name := p_owner_table_name;
	l_orig_objs.owner_table_id   := p_owner_table_id;
	l_orig_objs.orig_system      := p_orig_system;
	l_orig_objs.orig_system_reference := p_orig_sys_ref;
	l_orig_objs.status           :=  'A';
      l_orig_objs.created_by_module:= 'BO_API';
        

      --Calls the standard granular API to create a record in hz_orig_sys_references

      HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference(
          p_init_msg_list          =>    FND_API.G_FALSE,
          p_orig_sys_reference_rec =>    l_orig_objs,
          x_return_status   	     =>    l_return_status,
          x_msg_count 	           =>    l_msg_count,
          x_msg_data	           =>    l_msg_data 
        );

    COMMIT;

    x_return_status := l_return_status;

    IF(l_msg_count > 1) THEN
        FOR I IN 1..FND_MSG_PUB.Count_Msg LOOP
            l_error_message := l_error_message ||FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE );
        END LOOP;
    ELSE
        l_error_message := l_msg_data;
    END IF;
        x_error_message := l_error_message;
  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
  END insert_orig_sys_ref;

/*

The procedure get_sfa_aops_det is being called by BPEL process 'SaveContactPhones' for SFA update. 
The BPEL process calls this procedure if the input payload field SPREQID is empty. 
Since there is no key field to identify the record whether it has been created by SFA create or AOPS, this procedue is
being called for SFA update and AOPS.

This procedure decides whether the entry originated from SFA or AOPS based on the OSR values between 
hz_orig_sys_references and hz_contact_points. If the record was created by SFA, it gets the additional
information (relation_id and contact_point_id) required to call the BO from BPEL.

*/

  PROCEDURE get_sfa_aops_det
  (   p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_contact_point_osr	   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      p_person_osr               IN       hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_osr                  IN       hz_orig_sys_references.orig_system_reference%TYPE,
      x_trans_type               OUT      NOCOPY VARCHAR2,
      x_relation_id              OUT      NOCOPY hz_parties.party_id%TYPE,
      x_contact_point_id         OUT      NOCOPY hz_org_contacts.org_contact_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS

    ln_contact_point_id     hz_contact_points.contact_point_id%TYPE; 
    ln_relation_id          hz_contact_points.owner_table_id%TYPE; 
    ln_contact_osr          hz_contact_points.orig_system_reference%TYPE; 
    lv_return_status         VARCHAR2(30);
    lv_error_message         VARCHAR2(2000);


    --This cursor gets the values from the tables hz_orig_sys_references , hz_contact_points
    --for the given contact_point_osr

    CURSOR l_contact_point_osr_cur IS
    SELECT hcp.contact_point_id , hcp.orig_system_reference 
    FROM   hz_orig_sys_references osr, hz_contact_points hcp 
    WHERE  osr.orig_system_reference = p_contact_point_osr
    AND    osr.owner_table_name      = 'HZ_CONTACT_POINTS'
    AND    osr.orig_system           = p_orig_system
    AND    osr.owner_table_id        = hcp.contact_point_id 
    AND    osr.status                = 'A';               

  BEGIN

    x_return_status := 'S';

    	OPEN  l_contact_point_osr_cur;
    	FETCH l_contact_point_osr_cur INTO ln_contact_point_id,ln_contact_osr;
    	CLOSE l_contact_point_osr_cur;
    
    /*
    Note: When CDH entries are provided via GUI, system does not maintain OSR entries 
          in hz_orig_sys_references.  The system maintains the owner_table_id in the OSR column of the
          same table/respected table. This functionality is done via the SFA Application. We are deriving OSR for Party and 
          Party site but not deriving for Org contact and phone contact points. 
          We need to maintain OSR explicitly in the OSR table with the actual AOPS values 
          for org contact,contact person, contact role and phone contact points so that 
          we can refer those values for SFA updates.

          The OSR should have been created when SFA create happens thru BPEL Process either SaveContactMaster , 
          SaveContactPhones or CreateAccountProcess.
          The below statement compares the OSR values beween the OSR table and actual base table. 
          If both these values do not match then org contact should have been created by SFA else 
          it should be AOPS only.

          Also,this procedure sends relation_id and contact_point_id as output for BPEL process 
          to set the parent IDs while calling the BO.

    */

    	IF (NVL(p_contact_point_osr,'X') <> NVL(ln_contact_osr,'Y')) 
       	AND ln_contact_point_id IS NOT NULL
    	THEN
      	x_trans_type           := 'SFA';
      	x_contact_point_id     := ln_contact_point_id;
    	ELSE
      	x_trans_type           := 'AOPS';
    	END IF;  

             get_party_relation_id
            (   p_orig_system		   => p_orig_system,
                p_party_osr    	   => p_org_osr ,                 
                p_person_osr           => p_person_osr ,
                x_contact_relation_id  => ln_relation_id ,                                                                        
                x_return_status        => lv_return_status,
                x_error_message	   => lv_error_message
            );   
   
         	x_relation_id   := ln_relation_id; 

       	IF  ln_relation_id IS NULL
       	THEN
          		x_return_status := 'E';
          		x_error_message := lv_error_message;
       	END IF;                                                                       

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_contact_point_osr_cur;

  END get_sfa_aops_det;


  /*
  Note: This procedure process_contact_point_osr is being called by the BPEL process SaveContactPhones.
        It calls the child procedure insert_orig_sys_ref to make the OSR entries for phone contacts.

  */

  PROCEDURE process_contact_point_osr
  (   p_party_id                 IN		hz_parties.party_id%TYPE,
      p_person_id                IN	      hz_parties.party_id%TYPE,
      p_contact_point_id         IN       hz_org_contacts.org_contact_id%TYPE,
      p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_orig_sys_ref		   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      x_person_relation_id       OUT      NOCOPY hz_parties.party_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS

    ln_owner_table_id       NUMBER;
    lv_return_status         VARCHAR2(30) := 'S';
    lv_error_message         VARCHAR2(2000);
    ln_relation_id          NUMBER;

    CURSOR l_relation_cur IS
    SELECT party_id 
    FROM   --hz_party_relationships Commented for R12 Upgrade Retrofit
           hz_relationships
    WHERE  subject_id = p_person_id
    AND    object_id  = p_party_id                 
    AND    relationship_code = 'CONTACT_OF';


    CURSOR l_orig_system_cur IS
    SELECT owner_table_id
    FROM   hz_orig_sys_references
    WHERE  orig_system_reference =  p_orig_sys_ref
    AND    owner_table_name      =  'HZ_CONTACT_POINTS'
    AND    orig_system           =  p_orig_system
    AND    status                =  'A';


  BEGIN

    x_return_status := 'S';

    --In order to check whether phone contact already exists for the required OSR, we can get any value from the 
    --OSR table. If there is no record then a call to the child procedure, insert_orig_sys_ref, to make OSR entries.
    IF p_orig_sys_ref IS NOT NULL AND p_contact_point_id IS NOT NULL THEN
        OPEN  l_orig_system_cur;
        FETCH l_orig_system_cur INTO ln_owner_table_id;
        CLOSE l_orig_system_cur;
        
        IF NVL(ln_owner_table_id,0) = 0
        THEN
             insert_orig_sys_ref
                (   p_orig_system		   => p_orig_system,
                    p_orig_sys_ref	   => p_orig_sys_ref,
                    p_owner_table_name     => 'HZ_CONTACT_POINTS',
                    p_owner_table_id	   =>	p_contact_point_id,         
                    x_return_status        => lv_return_status,
                    x_error_message	   => lv_error_message
                );
        END IF;
    
        --Get and sends relation_id as output for BPEL process to set the parent IDs while calling the BO.
    
        OPEN  l_relation_cur ;
        FETCH l_relation_cur INTO ln_relation_id;
        CLOSE l_relation_cur;
    
        IF ln_relation_id IS NULL
        THEN
          lv_return_status := 'E';
          lv_error_message := lv_error_message || 'No Contact Relation beween the Party ID '|| p_party_id ||' and Person ID '||p_person_id;
        END IF;
    
        x_person_relation_id := ln_relation_id;      
        x_return_status := lv_return_status;
        x_error_message := lv_error_message;
    
        COMMIT;
    
    END IF;
    
  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_orig_system_cur;
      CLOSE l_relation_cur;

  END process_contact_point_osr;

/*

The procedure get_sfa_aops_det is being called by the BPEL process 'SaveContactMaster' for SFA update. 
The BPEL process calls this procedure if the input payload field SPREQID is empty. 
Since there is no key field to identity the record whether it was created by SFA create or AOPS, this procedue is
being called for SFA update and AOPS.

This procedure decides whether the entry has been made by SFA operation or AOPS based on the OSR values between 
hz_orig_sys_references and hz_org_contacts. If the record was created by SFA Operation, it gets the additional
information (person_id,org_id,org_contact_id and org_contact_role_id) required to call the BO from BPEL.

*/


  PROCEDURE get_sfa_aops_det
  (   p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr	         IN       hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_osr                  IN       hz_orig_sys_references.orig_system_reference%TYPE,
      x_trans_type               OUT      NOCOPY VARCHAR2,
      x_person_id                OUT      NOCOPY hz_parties.party_id%TYPE,
      x_org_id                   OUT      NOCOPY hz_parties.party_id%TYPE,
      x_org_contact_id           OUT      NOCOPY hz_org_contacts.org_contact_id%TYPE,
      x_org_contact_role_id      OUT      NOCOPY hz_org_contact_roles.org_contact_role_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )  IS

    ln_contact_point_id     hz_contact_points.contact_point_id%TYPE; 
    ln_org_id               hz_parties.party_id%TYPE; 
    ln_person_id            hz_parties.party_id%TYPE; 
    ln_relation_id          hz_parties.party_id%TYPE; 
    ln_contact_osr          hz_contact_points.orig_system_reference%TYPE;
    ln_contact_id           hz_org_contacts.org_contact_id%TYPE;  
    ln_contact_role_id      hz_org_contact_roles.org_contact_role_id%TYPE; 


    CURSOR l_org_cur IS
    SELECT caa.party_id
    FROM   hz_cust_accounts_all caa 
    WHERE  caa.orig_system_reference = p_org_osr;


    CURSOR l_org_contact_osr_cur IS
    SELECT hcp.org_contact_id , hcp.party_relationship_id, hcp.orig_system_reference 
    FROM   hz_orig_sys_references osr, hz_org_contacts hcp 
    WHERE  osr.orig_system_reference = p_org_contact_osr
    AND    osr.owner_table_name      = 'HZ_ORG_CONTACTS'
    AND    osr.orig_system           = p_orig_system
    AND    osr.owner_table_id        = hcp.org_contact_id 
    AND    osr.status                = 'A';

    CURSOR l_contact_person_cur IS
    SELECT osr.owner_table_id
    FROM   hz_orig_sys_references osr
    WHERE  osr.orig_system_reference = p_org_contact_osr
    AND    osr.owner_table_name      = 'HZ_PARTIES'
    AND    osr.orig_system           = p_orig_system
    AND    osr.status                = 'A';

    CURSOR l_org_contact_role_cur IS
    SELECT hcp.org_contact_role_id 
    FROM   hz_org_contact_roles hcp 
    WHERE  hcp.org_contact_id = ln_contact_id;


    CURSOR l_org_osr_cur IS
    SELECT osr.owner_table_id
    FROM   hz_orig_sys_references osr
    WHERE  osr.orig_system_reference = p_org_osr                  
    AND    osr.owner_table_name      = 'HZ_PARTIES'
    AND    osr.orig_system           = p_orig_system
    AND    osr.status                = 'A';

    CURSOR l_org_id_cur IS
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
    WHERE  hca.orig_system_reference = p_org_osr
    AND    hca.status                ='A';                


  BEGIN

    x_return_status := 'S';

    OPEN  l_org_osr_cur ;
    FETCH l_org_osr_cur INTO ln_org_id;
    CLOSE l_org_osr_cur ;
   
    IF ln_org_id IS NULL 
    THEN

    	OPEN  l_org_id_cur ;
    	FETCH l_org_id_cur INTO ln_org_id;
    	CLOSE l_org_id_cur ;

    	IF ln_org_id IS NOT NULL
    	THEN
            x_org_id               := ln_org_id;
      	x_trans_type           := 'AOPS CREATE';
    	ELSE
          		x_return_status := 'E';
          		x_error_message := 'No Party ID for the OSR '||p_org_osr;
    	END IF;  

    ELSE


    --The below statment compares the OSR values beween the OSR table and actual base table. 
    --If both these values does not match then org contact should have been created by SFA else AOPS only.

    OPEN  l_org_contact_osr_cur;
    FETCH l_org_contact_osr_cur INTO ln_contact_id,ln_relation_id,ln_contact_osr;
    CLOSE l_org_contact_osr_cur;
    
    IF (NVL(p_org_contact_osr,'X') <> NVL(ln_contact_osr,'Y')) 
       AND ln_contact_id IS NOT NULL
    THEN
     
      -- Gets the additional informations (person_id,org_id,org_contact_id and org_contact_role_id) 
      -- those are required to call the BO from BPEL.


      OPEN  l_org_contact_role_cur;
      FETCH l_org_contact_role_cur INTO ln_contact_role_id;
      CLOSE l_org_contact_role_cur;

      OPEN  l_contact_person_cur;
      FETCH l_contact_person_cur INTO ln_person_id;
      CLOSE l_contact_person_cur;

      OPEN  l_org_cur;
      FETCH l_org_cur INTO ln_org_id;
      CLOSE l_org_cur;

      x_trans_type           := 'SFA';
      x_person_id            := ln_person_id;
      x_org_id               := ln_org_id;
      x_org_contact_id       := ln_contact_id;
      x_org_contact_role_id  := ln_contact_role_id;

    ELSE
      x_trans_type           := 'AOPS';
    END IF;        
   END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_org_contact_osr_cur;
      CLOSE l_org_contact_role_cur;
      CLOSE l_contact_person_cur;
      CLOSE l_org_cur;
  END get_sfa_aops_det;


  /*
  Note: This procedure, process_org_contact_osr, is being called by the BPEL process 'SaveContactMaster'
        It calls the child procedure insert_orig_sys_ref to make the OSR entries for org contacts
        (person,org_contacts and contact role).

  */

  PROCEDURE process_org_contact_osr
  (   p_party_id                 IN		hz_parties.party_id%TYPE,
      p_person_id                IN	      hz_parties.party_id%TYPE,
      p_org_contact_id           IN       hz_org_contacts.org_contact_id%TYPE,
      p_org_contact_role_id      IN       hz_org_contact_roles.org_contact_role_id%TYPE,
      p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr		   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      p_org_contact_role_osr	   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS

    ln_owner_table_id       NUMBER;
    lv_return_status        VARCHAR2(30):='S';
    lv_error_message        VARCHAR2(2000);

              
    CURSOR l_contact_person_cur IS
    SELECT owner_table_id
    FROM   hz_orig_sys_references
    WHERE  orig_system_reference =  p_org_contact_osr
    AND    owner_table_name      =  'HZ_PARTIES'
    AND    orig_system           =  p_orig_system
    AND    status                =  'A';

    CURSOR l_org_contact_cur IS
    SELECT owner_table_id
    FROM   hz_orig_sys_references
    WHERE  orig_system_reference =  p_org_contact_osr
    AND    owner_table_name      =  'HZ_ORG_CONTACTS'
    AND    orig_system           =  p_orig_system
    AND    status                =  'A';


    CURSOR l_org_contact_role_cur IS
    SELECT owner_table_id
    FROM   hz_orig_sys_references
    WHERE  orig_system_reference =  p_org_contact_role_osr
    AND    owner_table_name      =  'HZ_ORG_CONTACT_ROLES'
    AND    orig_system           =  p_orig_system
    AND    status                =  'A';

  BEGIN

    x_return_status := 'S';

    OPEN  l_contact_person_cur;
    FETCH l_contact_person_cur INTO ln_owner_table_id;
    CLOSE l_contact_person_cur;
    
    IF NVL(ln_owner_table_id,0) = 0
    THEN
         insert_orig_sys_ref
            (   p_orig_system		   => p_orig_system,
                p_orig_sys_ref	   => p_org_contact_osr,
                p_owner_table_name     => 'HZ_PARTIES',
                p_owner_table_id	   =>	p_person_id ,         
                x_return_status        => lv_return_status,
                x_error_message	   => lv_error_message
            );
    END IF;

    OPEN  l_org_contact_cur;
    FETCH l_org_contact_cur INTO ln_owner_table_id;
    CLOSE l_org_contact_cur;
    
    IF NVL(ln_owner_table_id,0) = 0
    THEN
         insert_orig_sys_ref
            (   p_orig_system		   => p_orig_system,
                p_orig_sys_ref	   => p_org_contact_osr,
                p_owner_table_name     => 'HZ_ORG_CONTACTS',
                p_owner_table_id	   =>	p_org_contact_id ,         
                x_return_status        => lv_return_status,
                x_error_message	   => lv_error_message
            );
    END IF;
    
    -- Org Contact Role may not be provided as it is optional for prospect customer.
    -- If SFA provides Contact Role then the below script make the custom OSR entry else the 
    -- functionality would be treated as like AOPS.

    IF p_org_contact_role_id IS NOT NULL
    THEN
        OPEN  l_org_contact_role_cur;
        FETCH l_org_contact_role_cur INTO ln_owner_table_id;
        CLOSE l_org_contact_role_cur;
    
        IF NVL(ln_owner_table_id,0) = 0
        THEN
         insert_orig_sys_ref
            (   p_orig_system		   => p_orig_system,
                p_orig_sys_ref	   => p_org_contact_role_osr,
                p_owner_table_name     => 'HZ_ORG_CONTACT_ROLES',
                p_owner_table_id	   =>	p_org_contact_role_id,         
                x_return_status        => lv_return_status,
                x_error_message	   => lv_error_message
            );
        END IF;
     END IF;

    x_return_status := lv_return_status;
    x_error_message := lv_error_message;

    COMMIT;
  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_contact_person_cur;
      CLOSE l_org_contact_cur;
      CLOSE l_org_contact_role_cur;

  END process_org_contact_osr;


  /*
  Note: This procedure process_org_contact_osr is being called by BPEL process 'CreateAccountProcess'.
        It calls the child procedure process_org_contact_osr to make the OSR entries for org contacts 
        and phone contact points (person,org_contacts, contact role,phone1 and phone2).

  */


  PROCEDURE process_contacts_osr
  (   p_party_id                 IN		hz_parties.party_id%TYPE,
      p_person_id                IN	      hz_parties.party_id%TYPE,
      p_org_contact_id           IN       hz_org_contacts.org_contact_id%TYPE,
      p_org_contact_role_id      IN       hz_org_contact_roles.org_contact_role_id%TYPE,
      p_contact_point1_id        IN       hz_org_contacts.org_contact_id%TYPE,
      p_contact_point2_id        IN       hz_org_contacts.org_contact_id%TYPE,
      p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr		   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      p_contact_point1_osr	   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      p_contact_point2_osr	   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
    lv_return_status        VARCHAR2(30):='S';
    lv_error_message        VARCHAR2(2000);
    ln_relation_id          NUMBER;

  BEGIN

    x_return_status := 'S';

               process_org_contact_osr
                     (   p_party_id                 => p_party_id ,                 
                         p_person_id                => p_person_id ,
                         p_org_contact_id           => p_org_contact_id ,
                         p_org_contact_role_id      => p_org_contact_role_id ,
                         p_orig_system		    => p_orig_system ,
                         p_org_contact_osr	    => p_org_contact_osr ,
                         p_org_contact_role_osr	    => p_org_contact_osr ,
                         x_return_status            => lv_return_status ,
                         x_error_message	          => lv_error_message
                     );

          IF lv_return_status = 'S' 
          THEN
                IF p_contact_point1_osr IS NOT NULL AND p_contact_point1_id IS NOT NULL
                THEN
                       process_contact_point_osr
                         (   p_party_id                 => p_party_id ,                 
                             p_person_id                => p_person_id ,
                             p_contact_point_id         => p_contact_point1_id ,
                             p_orig_system		  => p_orig_system ,
                             p_orig_sys_ref		  => p_contact_point1_osr ,
                             x_person_relation_id       => ln_relation_id ,
                             x_return_status            => lv_return_status ,
                             x_error_message	        => lv_error_message
                         );

                END IF;

                IF p_contact_point2_osr IS NOT NULL AND p_contact_point2_id IS NOT NULL
                THEN
                       process_contact_point_osr
                         (   p_party_id                 => p_party_id ,                 
                             p_person_id                => p_person_id ,
                             p_contact_point_id         => p_contact_point2_id ,
                             p_orig_system		  => p_orig_system ,
                             p_orig_sys_ref		  => p_contact_point2_osr ,
                             x_person_relation_id       => ln_relation_id ,
                             x_return_status            => lv_return_status ,
                             x_error_message	        => lv_error_message
                         );
                END IF;

                x_return_status   := lv_return_status ;
                x_error_message   := lv_error_message ;
          ELSE
                x_return_status   := lv_return_status ;
                x_error_message   := lv_error_message ;

          END IF;

      COMMIT;

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;

  END process_contacts_osr;

  PROCEDURE get_party_relation_id
  (   p_orig_system              IN		hz_orig_sys_references.orig_system%TYPE,
      p_party_osr                IN	      hz_orig_sys_references.orig_system_reference%TYPE,
      p_person_osr               IN       hz_orig_sys_references.orig_system_reference%TYPE,
      x_contact_relation_id      OUT      NOCOPY hz_parties.party_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS

  ln_party_relation_id      hz_parties.party_id%TYPE;

    CURSOR l_contact_relation_cur IS
    SELECT par.party_id 
    FROM   --hz_party_relationships par
           hz_relationships par
    WHERE  par.subject_id = 
           (SELECT osr.owner_table_id 
            FROM   hz_orig_sys_references osr
            WHERE  osr.orig_system_reference = p_person_osr 
            AND    osr.owner_table_name      = 'HZ_PARTIES'
            AND    osr.orig_system           = p_orig_system
            AND    osr.status                = 'A')
    AND    par.object_id = 
           (SELECT cua.party_id 
            FROM   hz_cust_accounts cua
            WHERE  cua.orig_system_reference = p_party_osr
            -- Defect 105
            --AND    cua.status                = 'A'
            )
    AND    par.relationship_code = 'CONTACT_OF';

  BEGIN

    x_return_status := 'S';

    OPEN  l_contact_relation_cur;
    FETCH l_contact_relation_cur INTO ln_party_relation_id;
    CLOSE l_contact_relation_cur ;

    x_contact_relation_id  :=  ln_party_relation_id;   

    IF ln_party_relation_id IS NULL
    THEN
      x_return_status := 'E';
      x_error_message := 'No Contact Relation between the Org OSR '||p_party_osr||' and Person OSR '||p_person_osr;
    END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_contact_relation_cur;
  END get_party_relation_id;

  PROCEDURE get_profile_id
  (   p_account_osr                          IN VARCHAR2,
	x_acct_profile_id                      OUT NOCOPY NUMBER,
	x_site_profile_id                      OUT NOCOPY NUMBER,
	x_return_status 		               OUT NOCOPY VARCHAR2,
	x_error_message                        OUT NOCOPY VARCHAR2
  )
  IS
   l_cust_account_id 	NUMBER;
   l_cust_profile_id 	NUMBER;
   l_site_profile_id 	NUMBER;

    CURSOR l_acct_profile_cur IS
    SELECT hca.cust_account_id,  
           hcp.cust_account_profile_id
    FROM   hz_cust_accounts hca,
           hz_customer_profiles hcp  
    WHERE  hca.cust_account_id       = hcp.cust_account_id 
    AND    hca.orig_system_reference = p_account_osr
    AND    hca.status                = 'A'                        
    AND    hcp.site_use_id IS NULL;

    CURSOR l_site_profile_cur IS
    SELECT hcp.cust_account_profile_id
    FROM   hz_customer_profiles hcp,
           hz_cust_site_uses_all sua 
    WHERE  hcp.cust_account_id = l_cust_account_id
    AND    hcp.site_use_id     = sua.site_use_id
    AND    sua.site_use_code   = 'BILL_TO'
    AND    hcp.site_use_id IS NOT NULL;

  BEGIN
 
    x_return_status := 'S';

    OPEN  l_acct_profile_cur;
    FETCH l_acct_profile_cur into l_cust_account_id,l_cust_profile_id;
    CLOSE l_acct_profile_cur;

    IF l_cust_account_id IS NOT NULL THEN
    	OPEN  l_site_profile_cur ;
    	FETCH l_site_profile_cur into l_site_profile_id ;
    	CLOSE l_site_profile_cur ;
    END IF;

     x_acct_profile_id    := l_cust_profile_id;
     x_site_profile_id    := l_site_profile_id;

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_acct_profile_cur;
      CLOSE l_site_profile_cur;
  END get_profile_id;

  PROCEDURE get_acct_contact_id
  (   p_cust_acct_osr            IN       hz_orig_sys_references.orig_system_reference%TYPE,
      p_acct_contact_osr         IN       hz_orig_sys_references.orig_system_reference%TYPE,
      x_acct_contact_id          OUT      NOCOPY hz_cust_account_roles.cust_account_role_id%TYPE,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
   l_cust_contact_id 	NUMBER;

    CURSOR l_acct_contact_cur IS
    SELECT hac.cust_account_role_id
    FROM   hz_cust_accounts hca,
           hz_cust_account_roles hac  
    WHERE  hca.cust_account_id = hac.cust_account_id 
    AND    hca.orig_system_reference = p_cust_acct_osr 
    AND    hac.orig_system_reference = p_acct_contact_osr
    AND    hac.status = 'A'
    AND    hca.status = 'A'
    AND    hac.cust_acct_site_id IS NULL;


  BEGIN
 
    x_return_status := 'S';

    OPEN  l_acct_contact_cur ;
    FETCH l_acct_contact_cur into l_cust_contact_id ;
    CLOSE l_acct_contact_cur ;

    IF l_cust_contact_id IS NULL 
    THEN
      x_return_status := 'E';
      x_error_message := 'There is no account contact role for the OSR '||p_acct_contact_osr;
    END IF;
    x_acct_contact_id  := l_cust_contact_id ;

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_acct_contact_cur ;

  END get_acct_contact_id;

  PROCEDURE get_sfa_request_acct_id
  (   p_request_id               IN       NUMBER,
      x_bill_to_site_id          OUT      NOCOPY NUMBER,                                                                                                                                                                                                   
      x_ship_to_site_id          OUT      NOCOPY NUMBER,
      x_party_id                 OUT      NOCOPY NUMBER,                                                                                                                                                                                                   
      x_acct_number              OUT      NOCOPY NUMBER,
      x_cust_acct_id             OUT      NOCOPY NUMBER,
      x_orig_system              OUT      NOCOPY VARCHAR2,
      x_orig_sys_reference       OUT      NOCOPY VARCHAR2,
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
CURSOR l_request_acct_cur IS
SELECT 
  asr.bill_to_site_id,
  asr.ship_to_site_id,
  asr.party_id,
  asr.account_number,
  osr.owner_table_id,
  osr.orig_system,
  osr.orig_system_reference
FROM xx_cdh_account_setup_req asr,
  hz_orig_sys_references osr
WHERE asr.request_id = p_request_id               
 AND osr.owner_table_name = 'HZ_CUST_ACCOUNTS'
 AND osr.orig_system      = 'A0'
 AND asr.cust_account_id  = osr.owner_table_id
 AND osr.status = 'A';

  BEGIN
 
    x_return_status := 'S';

    OPEN  l_request_acct_cur ;
    FETCH l_request_acct_cur into 
      x_bill_to_site_id ,                                                                                                                                                                                                   
      x_ship_to_site_id ,
      x_party_id ,
      x_acct_number ,
      x_cust_acct_id ,
      x_orig_system ,
      x_orig_sys_reference ;
    CLOSE l_request_acct_cur ;

    IF x_cust_acct_id IS NULL 
    THEN
      x_return_status := 'E';
      x_error_message := 'There is no Customer Account for the Request ID '||p_request_id;
    END IF;

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_request_acct_cur ;

  END get_sfa_request_acct_id;

  PROCEDURE get_person_acct_contact_id
  (   p_orig_system		   IN       hz_orig_sys_references.orig_system%TYPE,
      p_org_contact_osr 	   IN		hz_orig_sys_references.orig_system_reference%TYPE,
      x_person_id                OUT      NOCOPY NUMBER,          
      x_acct_contact_id          OUT      NOCOPY NUMBER,                                                                                                                                                                                         
      x_return_status            OUT      NOCOPY VARCHAR2,
      x_error_message	         OUT      NOCOPY VARCHAR2
  )
  IS
   l_person_id 	   NUMBER;
   l_acct_contact_id NUMBER;

    CURSOR l_contact_relation_cur IS
    SELECT hpr.subject_id
    FROM   hz_orig_sys_references osr, hz_org_contacts hcp , 
           --hz_party_relationships hpr --Commented for R12 Upgrade Retrofit
           hz_relationships hpr
    WHERE  hcp.party_relationship_id = hpr.relationship_id
    AND    hpr.directional_flag      = 'F'
    AND    osr.orig_system_reference = p_org_contact_osr 
    AND    osr.owner_table_name      = 'HZ_ORG_CONTACTS'
    AND    osr.orig_system           = p_orig_system
    AND    osr.owner_table_id        = hcp.org_contact_id 
    AND    osr.status                = 'A';

    CURSOR l_acct_contact_cur IS
    SELECT car.cust_account_role_id
    FROM   hz_cust_account_roles car
    WHERE  car.orig_system_reference = p_org_contact_osr 
    AND    car.status = 'A';


  BEGIN
 
    x_return_status := 'S';

    OPEN  l_contact_relation_cur ;
    FETCH l_contact_relation_cur into l_person_id ;
    CLOSE l_contact_relation_cur ;

    OPEN  l_acct_contact_cur ;
    FETCH l_acct_contact_cur into l_acct_contact_id ;
    CLOSE l_acct_contact_cur  ;

    IF l_person_id IS NULL 
    THEN
      x_return_status := 'E';
      x_error_message := 'There is no contact person for the OSR '||p_org_contact_osr;
    END IF;

      x_person_id         := l_person_id;
      x_acct_contact_id   := l_acct_contact_id;                                                                                                                                                                                       

  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_contact_relation_cur ;
      CLOSE l_acct_contact_cur ;
  END get_person_acct_contact_id;

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
  )
  IS

    CURSOR l_party_info_cur IS
    SELECT hps.party_site_id, hps.party_id, 
           hps.location_id, hps.orig_system_reference,
           hps.status, asa.cust_account_id
    FROM   hz_orig_sys_references osr, hz_party_sites hps , hz_cust_acct_sites_all asa
    WHERE  osr.orig_system_reference = p_acct_site_osr
    AND    osr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
    AND    osr.orig_system           = p_orig_system
    AND    osr.owner_table_id        = asa.cust_acct_site_id 
    AND    osr.status                = 'A'
    AND    asa.party_site_id         = hps.party_site_id;


  BEGIN
 
    x_return_status := 'S';

    OPEN  l_party_info_cur ;
    FETCH l_party_info_cur into  x_party_site_id, x_party_id, x_location_id ,x_orig_system_reference,x_status,x_cust_acct_id ;
    CLOSE l_party_info_cur ;


    IF x_party_site_id IS NULL 
    THEN
      x_return_status := 'E';
      x_error_message := 'There is no Account Site or party Site for the OSR '||p_acct_site_osr;
    END IF;


  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_party_info_cur ;
  END get_party_site_details;

  --Overloaded with party_site_id in input parameter
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
  )
  IS

    CURSOR l_party_info_cur IS
    SELECT hps.party_site_id, hps.party_id,
           hps.location_id, hps.orig_system_reference,
           hps.status, asa.cust_account_id
    FROM   hz_orig_sys_references osr, hz_party_sites hps , hz_cust_acct_sites_all asa
    WHERE  osr.orig_system_reference = p_acct_site_osr
    AND    osr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
    AND    osr.orig_system           = p_orig_system
    AND    osr.owner_table_id        = asa.cust_acct_site_id
    AND    osr.status                = 'A'
    AND    asa.party_site_id         = hps.party_site_id;
    
    CURSOR l_party_site_info_cur IS
    SELECT hps.party_site_id, hps.party_id,
           hps.location_id, hps.orig_system_reference,
           hps.status, acct.cust_account_id
    FROM   hz_party_sites hps, hz_cust_accounts acct
    WHERE  hps.party_id  = acct.party_id (+)
    and    hps.party_site_id         =  p_party_site_id;    


  BEGIN

    x_return_status := 'S';
    
    if( p_party_site_id is not null ) then
      OPEN  l_party_site_info_cur ;
      FETCH l_party_site_info_cur into  x_party_site_id, x_party_id, x_location_id ,x_orig_system_reference,x_status,x_cust_acct_id ;
      CLOSE l_party_site_info_cur ; 
      return;
    end if;

    OPEN  l_party_info_cur ;
    FETCH l_party_info_cur into  x_party_site_id, x_party_id, x_location_id ,x_orig_system_reference,x_status,x_cust_acct_id ;
    CLOSE l_party_info_cur ;


    IF x_party_site_id IS NULL
    THEN
      x_return_status := 'E';
      x_error_message := 'There is no Account Site or party Site for the OSR '||p_acct_site_osr;
    END IF;


  EXCEPTION
     WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := SQLERRM;
      CLOSE l_party_info_cur ;
  END get_party_site_details;
  
  PROCEDURE create_acct_ap_contact
  (
      p_cust_account_id         IN     hz_cust_accounts.cust_account_id%TYPE,
      p_request_id              IN     xx_cdh_account_setup_req.request_id%TYPE,
      p_party_id                IN     hz_cust_accounts.party_id%TYPE,
      x_return_status           OUT    NOCOPY  VARCHAR2,
      x_error_message	        OUT    NOCOPY  VARCHAR2
  ) IS
  
  -- local variables
  l_ap_org_contact_id         hz_org_contacts.org_contact_id%TYPE;
  l_MSG_DATA                  VARCHAR2(2000);
  l_MSG_COUNT                 NUMBER;
  l_RET_STATUS                VARCHAR2(1);
  l_CUST_ACCOUNT_ROLE_REC     HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
  l_CUST_ACCOUNT_ROLE_ID      HZ_CUST_ACCOUNT_ROLES.cust_account_role_id%TYPE;
  l_rel_rec                   HZ_RELATIONSHIP_V2PUB.RELATIONSHIP_REC_TYPE;
  l_collect_rel_rec           HZ_RELATIONSHIP_V2PUB.RELATIONSHIP_REC_TYPE;
  l_collect_ORG_CONTACT_REC   HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
  
  l_contact_point_rec         hz_contact_point_v2pub.contact_point_rec_type;
  l_edi_rec                   hz_contact_point_v2pub.edi_rec_type;
  l_email_rec                 hz_contact_point_v2pub.email_rec_type;
  l_phone_rec                 hz_contact_point_v2pub.phone_rec_type;
  l_telex_rec                 hz_contact_point_v2pub.telex_rec_type;
  l_web_rec                   hz_contact_point_v2pub.web_rec_type;
  
  l_collect_ORG_CONTACT_ID    hz_org_contacts.org_contact_id%TYPE;
  l_collect_PARTY_REL_ID      HZ_RELATIONSHIPS.relationship_id%TYPE;
  l_collect_PARTY_ID          hz_parties.party_id%TYPE;
  l_collect_PARTY_NUMBER      hz_parties.party_number%TYPE;
  l_collect_contact_point_id  hz_contact_points.contact_point_id%TYPE;
  
  l_ROLE_RESPONSIBILITY_REC   HZ_CUST_ACCOUNT_ROLE_V2PUB.ROLE_RESPONSIBILITY_REC_TYPE;
  l_RESPONSIBILITY_ID         NUMBER;
  l_party_relationship_id     HZ_ORG_CONTACTS.party_relationship_id%TYPE;
  l_rel_party_id              hz_parties.party_id%TYPE;
  l_roles_cnt                 NUMBER;
  l_org_id                    hz_cust_acct_sites_all.org_id%TYPE;
  
  AP_CONT_EXCEPTION           EXCEPTION;
  
  CURSOR  c_bill_to_sites  IS
  SELECT  cas.cust_acct_site_id , cas.org_id
  FROM    hz_cust_acct_sites_all cas,
          hz_cust_site_uses_all  csu
  WHERE   cas.cust_account_id = p_cust_account_id
  AND     cas.cust_acct_site_id = csu.cust_acct_site_id
  AND     csu.site_use_code = 'BILL_TO'
  AND     cas.status = 'A'
  AND     csu.status = 'A';
  
  CURSOR  c_contact_points(p_owner_tab_id  HZ_PARTIES.party_id%TYPE) IS
  SELECT  contact_point_id, rownum
  from    (
          SELECT  contact_point_id 
          FROM    hz_contact_points
          WHERE   owner_table_name = 'HZ_PARTIES'
          AND     owner_table_id   = p_owner_tab_id
          AND     status = 'A' 
          order by contact_point_type , phone_line_type
          );
  
  BEGIN
  
      x_return_status := 'S';
      l_MSG_DATA      := NULL;
      l_MSG_COUNT     := 0;
      l_RET_STATUS    := NULL;
      
      IF p_request_id IS NOT NULL THEN
          -- BPEL
          select  nvl(attribute13,-786) into l_ap_org_contact_id
          from    xx_cdh_account_setup_req req
          where   request_id = p_request_id;
      
          l_collect_rel_rec.created_by_module         := 'BO_API';
          l_collect_ORG_CONTACT_REC.created_by_module := 'BO_API';
          l_contact_point_rec.created_by_module       := 'BO_API';
          l_CUST_ACCOUNT_ROLE_REC.created_by_module   := 'BO_API';
          l_ROLE_RESPONSIBILITY_REC.created_by_module := 'BO_API';
 
      ELSE
          -- Conversion
          BEGIN
            select  nvl(attribute13,-786) into l_ap_org_contact_id
            from    xx_cdh_account_setup_req req
            where   request_id = (
                    select  max(request_id)
                    from    xx_cdh_account_setup_req casr
                    where   casr.party_id = p_party_id
                    and     status IN ('BPEL Transmission Successful')
            ); 
          EXCEPTION WHEN NO_DATA_FOUND THEN
            RETURN;
          END;
          
          l_collect_rel_rec.created_by_module         := 'XXCONV';
          l_collect_ORG_CONTACT_REC.created_by_module := 'XXCONV';
          l_contact_point_rec.created_by_module       := 'XXCONV';
          l_CUST_ACCOUNT_ROLE_REC.created_by_module   := 'XXCONV';
          l_ROLE_RESPONSIBILITY_REC.created_by_module := 'XXCONV';
      
      END IF;     
      
      IF   l_ap_org_contact_id = -786 THEN
            -- AB_FLAG = N
            RETURN;
      ELSE
            -- Relationship_id
            select  party_relationship_id  INTO l_party_relationship_id
            from    hz_org_contacts
            where   org_contact_id = l_ap_org_contact_id;
            
            select  count(1) into l_roles_cnt
            from    hz_cust_account_roles  roles ,
                    hz_role_responsibility resp
            where   cust_account_id = p_cust_account_id
            and     roles.cust_account_role_id = resp.cust_account_role_id 
            and     roles.cust_acct_site_id is not null
            and     resp.responsibility_type = 'DUN'
            and     roles.role_type = 'CONTACT'
            and     roles.status = 'A'
            and     rownum = 1;
          
            IF l_roles_cnt > 0 THEN
              RETURN;
            END IF;
            
      END IF;

      HZ_RELATIONSHIP_V2PUB.get_relationship_rec(
        p_init_msg_list           =>  'T',
        p_relationship_id         =>  l_party_relationship_id,
        p_directional_flag        =>  'F',
        x_rel_rec                 =>  l_rel_rec,
        x_return_status           =>  l_RET_STATUS,
        x_msg_count               =>  l_MSG_COUNT ,
        x_msg_data                =>  l_MSG_DATA 
      );
      
      IF l_RET_STATUS <>'S' THEN
            RAISE AP_CONT_EXCEPTION;
      END IF;
      
      -- modify the values of relationship rec prior to creating the COLLECTIONS entry.
      l_MSG_DATA      := NULL;
      l_MSG_COUNT     := 0;
      l_RET_STATUS    := NULL;
      
      l_rel_party_id := l_rel_rec.party_rec.party_id;
      
      IF l_rel_rec.subject_type = 'PERSON' THEN
        l_collect_rel_rec.subject_type      := 'PERSON';
        l_collect_rel_rec.object_type       := 'ORGANIZATION';
        l_collect_rel_rec.subject_id        := l_rel_rec.subject_id;
        l_collect_rel_rec.object_id         := l_rel_rec.object_id;
        l_collect_rel_rec.relationship_code := 'COLLECTIONS_OF';      
      ELSE
        l_collect_rel_rec.subject_type      := 'ORGANIZATION';
        l_collect_rel_rec.object_type       := 'PERSON';
        l_collect_rel_rec.relationship_code := 'COLLECTIONS';
        l_collect_rel_rec.subject_id        := l_rel_rec.object_id;
        l_collect_rel_rec.object_id         := l_rel_rec.subject_id;
      END IF;
      
      -- check values of subject_id and object
      
      l_collect_rel_rec.relationship_type := 'COLLECTIONS';
      l_collect_rel_rec.subject_table_name:= 'HZ_PARTIES';
      l_collect_rel_rec.object_table_name := 'HZ_PARTIES';
     
      l_collect_ORG_CONTACT_REC.party_rel_rec   := l_collect_rel_rec;
      l_collect_ORG_CONTACT_REC.job_title       := 'AP';     
      HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT(
        P_INIT_MSG_LIST     => 'T',
        P_ORG_CONTACT_REC   => l_collect_ORG_CONTACT_REC,
        X_ORG_CONTACT_ID    => l_collect_ORG_CONTACT_ID,
        X_PARTY_REL_ID      => l_collect_PARTY_REL_ID,
        X_PARTY_ID          => l_collect_PARTY_ID,
        X_PARTY_NUMBER      => l_collect_PARTY_NUMBER,
        X_RETURN_STATUS     => l_RET_STATUS,
        X_MSG_COUNT         => l_MSG_COUNT,
        X_MSG_DATA          => l_MSG_DATA
      );
      
      IF l_RET_STATUS <>'S' THEN
            RAISE AP_CONT_EXCEPTION;
      END IF;
      
      -- create contact points
      for rec_contact_point IN c_contact_points(l_rel_party_id)  loop
        l_MSG_DATA          := NULL;
        l_MSG_COUNT         := 0;
        l_RET_STATUS        := NULL;
        l_contact_point_rec := NULL;
        l_edi_rec           := NULL;
        l_email_rec         := NULL;
        l_phone_rec         := NULL;
        l_telex_rec         := NULL;
        l_web_rec           := NULL;
        
          hz_contact_point_v2pub.get_contact_point_rec(
            p_init_msg_list             => 'T',
            p_contact_point_id          =>  rec_contact_point.contact_point_id,
            x_contact_point_rec         =>  l_contact_point_rec,
            x_edi_rec                   =>  l_edi_rec,
            x_email_rec                 =>  l_email_rec,
            x_phone_rec                 =>  l_phone_rec,
            x_telex_rec                 =>  l_telex_rec,
            x_web_rec                   =>  l_web_rec,
            x_return_status             =>  l_RET_STATUS,
            x_msg_count                 =>  l_MSG_COUNT,
            x_msg_data                  =>  l_MSG_DATA
            );
            
        IF l_RET_STATUS <>'S' THEN
              RAISE AP_CONT_EXCEPTION;
        END IF;
        
        l_MSG_DATA      := NULL;
        l_MSG_COUNT     := 0;
        l_RET_STATUS    := NULL;
        l_contact_point_rec.contact_point_id  := null;
        l_contact_point_rec.owner_table_id    := l_collect_PARTY_ID;
        l_phone_rec.raw_phone_number          := NULL;
        
        IF rec_contact_point.ROWNUM  = 1 THEN
            l_contact_point_rec.CONTACT_POINT_PURPOSE := 'DUNNING';
            l_contact_point_rec.primary_flag := 'Y';
        ELSE
            l_contact_point_rec.CONTACT_POINT_PURPOSE := 'COLLECTIONS';
            l_contact_point_rec.primary_flag := 'N';
        END IF;
        
        hz_contact_point_v2pub.create_contact_point (
          p_init_msg_list               =>  'T',
          p_contact_point_rec           =>  l_contact_point_rec,
          p_edi_rec                     =>  l_edi_rec,
          p_email_rec                   =>  l_email_rec,
          p_phone_rec                   =>  l_phone_rec,
          p_telex_rec                   =>  l_telex_rec,
          p_web_rec                     =>  l_web_rec,
          x_contact_point_id            =>  l_collect_contact_point_id,
          x_return_status               =>  l_RET_STATUS,
          x_msg_count                   =>  l_MSG_COUNT,
          x_msg_data                    =>  l_MSG_DATA
        );
        
        IF l_RET_STATUS <>'S' THEN
              RAISE AP_CONT_EXCEPTION;
        END IF;
      
      end loop;
      
      l_CUST_ACCOUNT_ROLE_REC.party_id          := l_collect_PARTY_ID;
      l_CUST_ACCOUNT_ROLE_REC.cust_account_id   := p_cust_account_id;
      l_CUST_ACCOUNT_ROLE_REC.role_type         := 'CONTACT';
      --l_CUST_ACCOUNT_ROLE_REC.primary_flag      := 'Y';
          
      l_org_id := fnd_profile.value('ORG_ID');
      
      FOR rec_bill_to_sites IN c_bill_to_sites LOOP
      
          l_MSG_DATA    := NULL;
          l_MSG_COUNT   := 0;
          l_RET_STATUS  := NULL;
          l_CUST_ACCOUNT_ROLE_REC.cust_acct_site_id := rec_bill_to_sites.cust_acct_site_id;
          l_CUST_ACCOUNT_ROLE_ID := NULL;
          
          fnd_client_info.set_org_context(rec_bill_to_sites.org_id);
          HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_CUST_ACCOUNT_ROLE(
            P_INIT_MSG_LIST         => 'T',
            P_CUST_ACCOUNT_ROLE_REC => l_CUST_ACCOUNT_ROLE_REC,
            X_CUST_ACCOUNT_ROLE_ID  => l_CUST_ACCOUNT_ROLE_ID,
            X_RETURN_STATUS         => l_RET_STATUS,
            X_MSG_COUNT             => l_MSG_COUNT,
            X_MSG_DATA              => l_MSG_DATA
          );
      
          IF l_RET_STATUS <>'S' THEN
            fnd_client_info.set_org_context(l_org_id);
            RAISE AP_CONT_EXCEPTION;
          END IF;
          
              -- ROLE/ RESPONSIBILITY
          l_MSG_DATA      := NULL;
          l_MSG_COUNT     := 0;
          l_RET_STATUS    := NULL;
          l_ROLE_RESPONSIBILITY_REC.cust_account_role_id := l_CUST_ACCOUNT_ROLE_ID;
          l_ROLE_RESPONSIBILITY_REC.responsibility_type  := 'DUN';
          l_ROLE_RESPONSIBILITY_REC.primary_flag := 'Y';
          
          HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_ROLE_RESPONSIBILITY(
            P_INIT_MSG_LIST           => 'T',
            P_ROLE_RESPONSIBILITY_REC => l_ROLE_RESPONSIBILITY_REC,
            X_RESPONSIBILITY_ID       => l_RESPONSIBILITY_ID,
            X_RETURN_STATUS           => l_RET_STATUS,
            X_MSG_COUNT               => l_MSG_COUNT,
            X_MSG_DATA                => l_MSG_DATA
          );
          
          IF l_RET_STATUS <>'S' THEN
                fnd_client_info.set_org_context(l_org_id);
                RAISE AP_CONT_EXCEPTION;
          END IF;
      
      END LOOP;
      fnd_client_info.set_org_context(l_org_id);
      COMMIT;
  
  EXCEPTION
      WHEN  AP_CONT_EXCEPTION THEN
        IF l_MSG_COUNT > 1 THEN
                FOR I IN 1..l_MSG_COUNT
                LOOP
                    x_error_message := x_error_message||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                END LOOP;
        ELSE
                x_error_message :=  l_MSG_DATA;
        END IF;
        x_return_status := 'E';
        ROLLBACK;
      WHEN OTHERS THEN
        x_return_status := 'E';
        x_error_message := 'Exception in create_acct_apcontact. Failed with  ' ||SQLERRM;
        ROLLBACK;
  END create_acct_ap_contact;

 END XX_CDH_ACCOUNT_SETUP_REQ_PKG;
/
SHOW ERRORS