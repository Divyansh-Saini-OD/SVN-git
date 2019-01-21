SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CDH_DUNNING_CONTACTS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CDH_DUNNING_CONTACTS_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CDH_DUNNING_CONTACTS_PKG                              |
-- | Description : 1) To import dunning contacts and contact points into    |
-- |                  Oracle.                                               |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      18-JUN-2010  Devi Viswanathan     Initial version              |
-- +========================================================================+

-- +========================================================================+
-- | Name        : XX_CDH_DUNN_CONT_TMPLT                                   |
-- | Description : 1) To import dunning contacts and contact points into    |
-- |                  Oracle.                                               |
-- | Returns     : VARCHAR2                                                 |
-- +========================================================================+

  FUNCTION xx_cdh_dunn_cont_tmplt( p_last_name   VARCHAR2
                                 , p_first_name  VARCHAR2
                                 , p_email_id    VARCHAR2
                                 , p_tele_code   VARCHAR2
                                 , p_telephone   VARCHAR2
                                 , p_fax_code    VARCHAR2
                                 , p_fax         VARCHAR2
                                 , p_leg_acc_num VARCHAR2
                                 , p_addr_seq    VARCHAR2
                                 )
  RETURN VARCHAR2
  IS

    CURSOR add_cur( c_leg_acc_num VARCHAR2
                  , c_addr_seq    VARCHAR2)
        IS
    SELECT HCAS.cust_acct_site_id
         , HCAS.cust_account_id
         , HCA.account_number
         , HCA.party_id
         , HCAS.org_id
      FROM hz_cust_acct_sites_all HCAS
         , hz_cust_accounts HCA
     WHERE HCAS.orig_system_reference = LPAD(c_leg_acc_num,8,'0') || '-' || LPAD(c_addr_seq,5,'0') || '-' || 'A0'
       AND HCAS.cust_account_id = HCA.cust_account_id;
    
    CURSOR check_account_cur(c_cust_account_id hz_cust_accounts.cust_account_id%TYPE) 
        IS
    SELECT 1
      FROM hz_cust_accounts HCA
     WHERE HCA.cust_account_id = c_cust_account_id
       AND HCA.status = 'A';  
       
    CURSOR check_site_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS
    SELECT 1
      FROM hz_cust_acct_sites_all HCAS
     WHERE HCAS.cust_acct_site_id = c_cust_acct_site_id
       AND HCAS.status = 'A';   

    CURSOR site_use_cur(c_cust_acct_site_id hz_cust_site_uses_all.cust_acct_site_id%TYPE)
        IS
    SELECT 1
      FROM hz_cust_site_uses_all HCSU
     WHERE HCSU.site_use_code = 'BILL_TO'
       AND HCSU.cust_acct_site_id = c_cust_acct_site_id;

    CURSOR contact_cur(c_cust_acct_site_id hz_cust_account_roles.cust_acct_site_id%TYPE)
        IS
    SELECT 1
      FROM hz_contact_points HCP
         , hz_cust_account_roles HCAR
         , hz_parties HP
         , hz_parties HP1
         , hz_relationships HR
         , hz_org_contacts HOC
         , hz_cust_accounts HCA
     WHERE HCAR.party_id               = HR.party_id
       AND HCAR.role_type              = 'CONTACT'
       AND HOC.party_relationship_id   = HR.relationship_id
       AND HR.subject_id               = HP.party_id
       AND HP1.party_id                = HR.party_id
       AND HCP.owner_table_id          = HP1.party_id
       AND HCAR.cust_account_id        = HCA.cust_account_id
       AND HCA.party_id                = HR.object_id
       AND HCP.owner_table_name        = 'HZ_PARTIES'
       AND HCP.contact_point_purpose   = 'DUNNING'
       AND HCP.status                  = 'A'
       AND HCAR.current_role_state     = 'A'
       AND HCAR.status                 = 'A'
       AND HCAR.cust_acct_site_id      = c_cust_acct_site_id;

    CURSOR job_cur( c_cust_acct_site_id hz_cust_account_roles.cust_acct_site_id%TYPE)
        IS
    SELECT 1
      FROM hz_cust_account_roles HCAR
         , hz_relationships HR
         , hz_org_contacts HOC
     WHERE HCAR.party_id               = HR.party_id
       AND HCAR.role_type              = 'CONTACT'
       AND HOC.party_relationship_id   = HR.relationship_id
       AND HOC.job_title               = 'AP'
       AND HCAR.status                 = 'A'
       AND HCAR.cust_acct_site_id      = c_cust_acct_site_id;
       
       
    CURSOR chk_direct_cur(c_cust_account_id hz_cust_accounts.cust_account_id%TYPE)
        IS
    SELECT  count(*)
      FROM  hz_cust_site_uses_all  HCSU
         ,  hz_cust_acct_sites_all HCAS
     WHERE  HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
       AND  HCSU.site_use_code     = 'BILL_TO'
       AND  HCAS.cust_account_id   = c_cust_account_id;
       
       
    CURSOR coll_rel_cur(c_cust_account_id hz_cust_accounts.cust_account_id%TYPE)
        IS
    SELECT HR.relationship_id
      FROM hz_relationships HR
         , hz_cust_accounts HCA
     WHERE HCA.party_id           = HR.object_id
       AND HR.relationship_code   = 'COLLECTIONS_OF'
       AND HR.status              = 'A'
       AND HCA.cust_account_id    = c_cust_account_id;        
       
  /*     
    CURSOR coll_rel_cur(c_cust_acct_site_id hz_cust_account_roles.cust_acct_site_id%TYPE)
        IS    
     SELECT HR.relationship_id
      FROM hz_cust_account_roles HCAR
        ,  hz_relationships      HR
        ,  hz_cust_accounts      HCA
     WHERE HCAR.party_id          = HR.party_id
       AND HCAR.role_type         = 'CONTACT'
       AND HCAR.cust_account_id   = HCA.cust_account_id
       AND HCA.party_id           = HR.object_id
       AND HR.status              = 'A' 
       AND HCAR.cust_acct_site_id = c_cust_acct_site_id; 
    */   
       
     
    CURSOR role_resp_cur( c_cust_account_id hz_cust_accounts.cust_account_id%TYPE
                        , c_cust_acct_site_id hz_cust_account_roles.cust_acct_site_id%TYPE) 
        IS       
    SELECT HRR.responsibility_id
      FROM hz_cust_account_roles HCAR
         , hz_role_responsibility HRR 
     WHERE HCAR.cust_account_role_id = HRR.cust_account_role_id
       AND HRR.responsibility_type   = 'DUN'
       AND HRR.primary_flag          = 'Y'
       AND HCAR.cust_account_id      = c_cust_account_id
       AND HCAR.cust_acct_site_id    = c_cust_acct_site_id;      
     

    --Declare all the Local variables to be used in procedure

    ln_cust_acct_site_id_in       hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    ln_party_id_in                hz_cust_accounts.party_id%TYPE;
    ln_cust_account_id_in         hz_cust_accounts.cust_account_id%TYPE;
    lc_account_number_in          hz_cust_accounts.account_number%TYPE;
    lr_rel_rec                    hz_relationship_v2pub.relationship_rec_type;
    lr_rel_rec_in                 hz_relationship_v2pub.relationship_rec_type;
    lr_role_responsibility_rec_in hz_cust_account_role_v2pub.role_responsibility_rec_type;
    ln_resp_object_version_number hz_role_responsibility.object_version_number%TYPE; 

    ln_dun_ex           NUMBER;
    ln_bill_to_ex       NUMBER;
    ln_job_ex           NUMBER;
    ln_account_ex       NUMBER;
    ln_site_ex          NUMBER;
    ln_bill_to_cnt      NUMBER;
    ln_org_id           NUMBER;
    ln_war_flag         NUMBER := 0;

   
    lc_get_role_resp_return_status   VARCHAR2(2000);
    ln_get_role_resp_msg_count       NUMBER;
    lc_get_role_resp_msg_data        VARCHAR2(2000);     

    lc_upd_role_resp_return_status   VARCHAR2(2000);
    ln_upd_role_resp_msg_count       NUMBER;
    lc_upd_role_resp_msg_data        VARCHAR2(2000);


    lc_coll_rel_return_status        VARCHAR2(2000);
    ln_coll_rel_msg_count            NUMBER;
    ln_coll_rel_msg_data             VARCHAR2(2000);

    lc_upd_coll_rel_return_status    VARCHAR2(2000);
    ln_upd_coll_rel_msg_count        NUMBER;
    ln_upd_coll_rel_msg_data         VARCHAR2(2000);

    ln_rel_object_version_number     NUMBER;
    ln_party_object_version_number   NUMBER;


    lc_vpd_profile                   VARCHAR2(2000);

    lc_org_contact_return_status     VARCHAR2(2000);
    ln_org_contact_msg_count         NUMBER;
    lc_org_contact_msg_data          VARCHAR2(2000);

    lc_create_person_return_status   VARCHAR2(2000);
    ln_create_person_msg_count       NUMBER;
    lc_create_person_msg_data        VARCHAR2(2000);

    lc_cust_acct_role_rtrn_status    VARCHAR2(1000);
    ln_cust_acct_role_msg_count      NUMBER;
    lc_cust_acct_role_msg_data       VARCHAR2(1000);

    lc_role_resp_return_status       VARCHAR2(1000);
    ln_role_resp_msg_count           NUMBER;
    lc_role_resp_msg_data            VARCHAR2(1000);

    lc_contact_point_return_status   VARCHAR2(2000);
    ln_contact_point_msg_count       NUMBER;
    lc_contact_point_msg_data        VARCHAR2(2000);

    ln_cust_account_role_id          NUMBER;
    lr_cust_account_role_rec         HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;

    lr_role_responsibility_rec       HZ_CUST_ACCOUNT_ROLE_V2PUB.ROLE_RESPONSIBILITY_REC_TYPE;

    lr_person_rec   hz_party_v2pub.person_rec_type;
    ln_party_id     hz_parties.party_id%type;
    lc_party_number hz_parties.party_number%type;
    ln_profile_id   NUMBER;

    lr_org_contact_rec             HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
    ln_org_contact_id_APcontact    NUMBER;
    ln_party_rel_id                NUMBER;
    ln_party_id_create_org_contact NUMBER;
    lc_party_number_org_contact    VARCHAR2(2000);
    lc_return_message              VARCHAR2(2000);

    lr_contact_point_rec_phone    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
    lr_contact_point_rec_email    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
    lr_contact_point_rec_fax      HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
    lr_edi_rec                    HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
    lr_email_rec                  HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
    lr_email_rec_dummy            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
    lr_phone_rec                  HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
    lr_phone_rec_dummy            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
    lr_fax_rec                    HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
    lr_telex_rec                  HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
    lr_web_rec                    HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
    ln_contact_point_id           NUMBER;
    ln_responsibility_id          NUMBER;

  BEGIN

    SAVEPOINT create_dunning_contact;
    
    
    fnd_file.PUT_LINE(fnd_file.LOG, '***********Begin Function xx_cdh_dunn_cont_tmplt');    

    fnd_file.PUT_LINE(fnd_file.LOG, '***********leg_acct_number: ' || p_leg_acc_num);
    fnd_file.PUT_LINE(fnd_file.LOG, '***********seq_num: ' || p_addr_seq);

    fnd_file.PUT_LINE(fnd_file.LOG, '***********org_id: ' || fnd_global.org_id());

    IF p_last_name IS NULL OR LENGTH(TRIM(p_last_name)) = 0 THEN

      fnd_file.PUT_LINE(fnd_file.LOG, '**********Last Name is null');

      RETURN 'FALSE_' || lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Last Name cannot be null';

    END IF; --  p_last_name IS NULL OR LENGTH(TRIM(p_last_name))

    /* To fetch the cust acct site details
     */
    OPEN add_cur(p_leg_acc_num, p_addr_seq);

    FETCH add_cur INTO ln_cust_acct_site_id_in, ln_cust_account_id_in, lc_account_number_in, ln_party_id_in, ln_org_id;

    CLOSE add_cur;

    IF ln_cust_acct_site_id_in IS NULL THEN

      fnd_file.PUT_LINE(fnd_file.LOG, '**********Cust site id not found');

      RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Invalid (customer account number/seq number)';

    END IF;
    
    /* Setting org_context
     */
    fnd_client_info.set_org_context(ln_org_id);

    /* To return error if the site is not a BILL_TO site
     */
    OPEN site_use_cur(ln_cust_acct_site_id_in);

    FETCH site_use_cur INTO ln_bill_to_ex;

    IF site_use_cur%NOTFOUND THEN

      fnd_file.PUT_LINE(fnd_file.LOG, '**********Not a bill to site');

      CLOSE site_use_cur;

      RETURN 'FALSE_' || lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Dunning contact is created only for BILL TO sites';

    END IF;

    CLOSE site_use_cur;

    /* To check if dunning contact point already exists for the customer site
     */

    OPEN contact_cur(ln_cust_acct_site_id_in);

    FETCH contact_cur INTO ln_dun_ex;

      /*  Create a new contact only if customer does not have a dunning contact already
       *  Else omit the record */

      fnd_file.PUT_LINE(fnd_file.LOG, '**********Inide For');

      IF ( contact_cur%NOTFOUND ) THEN


        lc_return_message := 'TRUE' || lc_account_number_in || '"'|| ',' || '"Warning' || '"'|| ',' ;

        /* To check if a contact already exists with JOB = 'AP'
         * If a contact with JOB = 'AP' already exists return a warning else return success
         */

        OPEN job_cur(ln_cust_acct_site_id_in);

        FETCH job_cur INTO ln_job_ex;        
        
        IF job_cur%FOUND THEN
        
          ln_war_flag := 1;

          lc_return_message := lc_return_message || '" New contact created. Site already has a contact with JOB=AP';

        END IF;
        
        CLOSE job_cur;  

        /* Reset profile value XX_CDH_SEC_BYPASS_SEC_RULES to 'Y' to bypass VPD
         */
        /*
        lc_vpd_profile := fnd_profile.value('XX_CDH_SEC_BYPASS_SEC_RULES');

        fnd_file.PUT_LINE(fnd_file.LOG, '**********XX_CDH_SEC_BYPASS_SEC_RULES Profile Value: ' || lc_vpd_profile);

        fnd_profile.put('XX_CDH_SEC_BYPASS_SEC_RULES','Y');
        */
        

        /* Create the person in HZ_PARTIES table
         */

        fnd_file.put_line(fnd_file.LOG, '**********Create Person');

        lr_person_rec.created_by_module := 'HZ_CPUI';
        lr_person_rec.person_first_name := p_first_name;
        lr_person_rec.person_last_name := p_last_name;

        hz_party_v2pub.create_person ( p_init_msg_list => 'T'
                                     , p_person_rec    => lr_person_rec
                                     , x_party_id      => ln_party_id
                                     , x_party_number  => lc_party_number
                                     , x_profile_id    => ln_profile_id
                                     , x_return_status => lc_create_person_return_status
                                     , x_msg_count     => ln_create_person_msg_count
                                     , x_msg_data      => lc_create_person_msg_data
                                     );


        IF lc_create_person_return_status = FND_API.G_RET_STS_ERROR OR lc_create_person_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

          ROLLBACK TO create_dunning_contact;
          RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Person API failed, API error message:  ' || lc_create_person_msg_data;

        END IF;


        -------------------------------------------------------------------------------------------------------------------
        /*  Check if the customer is direct for indirec
         *  If the customer is direct then inactivate all the relationships for that account                 
         *  
         */
         
         ln_bill_to_cnt := 0;
         
         OPEN chk_direct_cur(ln_cust_account_id_in);
         
         FETCH chk_direct_cur INTO ln_bill_to_cnt;
         
         fnd_file.put_line(fnd_file.LOG,'**********No of BILL TO sites: ' || ln_bill_to_cnt);         
         
         CLOSE chk_direct_cur;
         
         IF ln_bill_to_cnt = 1 THEN        
        
            /* Direct CustomerSet the relationship status of existing COLLECTIONS OF as inactive
             */

            fnd_file.put_line(fnd_file.LOG, '**********Direct Customer. Before FOR coll_rel_rec IN coll_rel_cur(ln_cust_account_id_in:' || ln_cust_account_id_in|| ') LOOP');

            FOR coll_rel_rec IN coll_rel_cur(ln_cust_account_id_in) LOOP

              fnd_file.put_line(fnd_file.LOG,'Relationship id: ' || coll_rel_rec.relationship_id);

              hz_relationship_v2pub.get_relationship_rec ( p_init_msg_list   =>  FND_API.G_TRUE
                                                         , p_relationship_id =>  coll_rel_rec.relationship_id
                                                         , x_rel_rec         =>  lr_rel_rec
                                                         , x_return_status   =>  lc_coll_rel_return_status
                                                         , x_msg_count       =>  ln_coll_rel_msg_count
                                                         , x_msg_data        =>  ln_coll_rel_msg_data);

              IF lc_coll_rel_return_status = FND_API.G_RET_STS_ERROR OR lc_coll_rel_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

                ROLLBACK TO create_dunning_contact;
                RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Get Relationship Record API failed for relationship_id: ' || lr_rel_rec.relationship_id || ', API error message:  ' || lc_org_contact_msg_data;

              END IF;

              fnd_file.put_line(fnd_file.LOG,'**********Updating Relationship id: ' || lr_rel_rec.relationship_id);


              lr_rel_rec_in := lr_rel_rec;

              lr_rel_rec_in.status := 'I';

              SELECT HR.object_version_number
                INTO ln_rel_object_version_number
                FROM HZ_RELATIONSHIPs HR
               WHERE HR.relationship_id  =  lr_rel_rec.relationship_id
                 AND HR.directional_flag = 'F';


              SELECT HP.object_version_number
                INTO ln_party_object_version_number
                FROM HZ_PARTIES HP
               WHERE HP.party_id = lr_rel_rec.party_rec.party_id;


              hz_relationship_v2pub.update_relationship ( p_init_msg_list               => 'T'
                                                        , p_relationship_rec            => lr_rel_rec_in
                                                        , p_object_version_number       => ln_rel_object_version_number
                                                        , p_party_object_version_number => ln_party_object_version_number
                                                        , x_return_status               => lc_upd_coll_rel_return_status
                                                        , x_msg_count                   => ln_upd_coll_rel_msg_count
                                                        , x_msg_data                    => ln_upd_coll_rel_msg_data);


              IF lc_upd_coll_rel_return_status = FND_API.G_RET_STS_ERROR OR lc_upd_coll_rel_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

                ROLLBACK TO create_dunning_contact;
                RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Update Relationship API failed for relationship_id: ' || lr_rel_rec_in.relationship_id || ', API error message:  ' || lc_org_contact_msg_data;

              END IF;


            END LOOP;

            /* Create the person as collections contact in HZ_ORG_CONTACTS AND HZ_RELATIONSHIPS tables for direct customer site*/

            lr_org_contact_rec.created_by_module := 'XXCRM';
            lr_org_contact_rec.party_rel_rec.subject_id := ln_party_id;
            lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
            lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
            lr_org_contact_rec.party_rel_rec.object_id := ln_party_id_in;
            lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
            lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
            lr_org_contact_rec.party_rel_rec.relationship_code := 'COLLECTIONS_OF';
            lr_org_contact_rec.party_rel_rec.relationship_type := 'COLLECTIONS';
            lr_org_contact_rec.party_rel_rec.start_date := SYSDATE;
            lr_org_contact_rec.job_title := 'AP';

            fnd_file.PUT_LINE(fnd_file.LOG, '**********Create relationship for direct customers : Subject id: ' || ln_party_id);

            hz_party_contact_v2pub.create_org_contact( p_init_msg_list   => 'T'
                                                     , p_org_contact_rec => lr_org_contact_rec
                                                     , x_org_contact_id  => ln_org_contact_id_APcontact
                                                     , x_party_rel_id    => ln_party_rel_id
                                                     , x_party_id        => ln_party_id_create_org_contact
                                                     , x_party_number    => lc_party_number_org_contact
                                                     , x_return_status   => lc_org_contact_return_status
                                                     , x_msg_count       => ln_org_contact_msg_count
                                                     , x_msg_data        => lc_org_contact_msg_data);

            IF lc_org_contact_return_status = FND_API.G_RET_STS_ERROR OR lc_org_contact_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

              ROLLBACK TO create_dunning_contact;
              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Org Contact API failed, API error message:  ' || lc_org_contact_msg_data;

            END IF;            
            
         ELSE
         
         
            /* Create the person as contact in HZ_ORG_CONTACTS AND HZ_RELATIONSHIPS tables for indirect customer site*/

            lr_org_contact_rec.created_by_module := 'XXCRM';
            lr_org_contact_rec.party_rel_rec.subject_id := ln_party_id;
            lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
            lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
            lr_org_contact_rec.party_rel_rec.object_id := ln_party_id_in;
            lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
            lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
            lr_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
            lr_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
            lr_org_contact_rec.party_rel_rec.start_date := SYSDATE;
            lr_org_contact_rec.job_title := 'AP';

            fnd_file.PUT_LINE(fnd_file.LOG, '**********Create relationship for indirect customers: Subject id: ' || ln_party_id);

            hz_party_contact_v2pub.create_org_contact( p_init_msg_list   => 'T'
                                                     , p_org_contact_rec => lr_org_contact_rec
                                                     , x_org_contact_id  => ln_org_contact_id_APcontact
                                                     , x_party_rel_id    => ln_party_rel_id
                                                     , x_party_id        => ln_party_id_create_org_contact
                                                     , x_party_number    => lc_party_number_org_contact
                                                     , x_return_status   => lc_org_contact_return_status
                                                     , x_msg_count       => ln_org_contact_msg_count
                                                     , x_msg_data        => lc_org_contact_msg_data);

            IF lc_org_contact_return_status = FND_API.G_RET_STS_ERROR OR lc_org_contact_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

              ROLLBACK TO create_dunning_contact;
              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Org Contact API failed, API error message:  ' || lc_org_contact_msg_data;

            END IF;          
         
            
         END IF; -- IF ln_bill_to_cnt = 1 THEN   



        -------------------------------------------------------------------------------------------------------------------

        /* Create the person as CONTACT for the customer site */

        lr_cust_account_role_rec.party_id          := ln_party_id_create_org_contact;
        lr_cust_account_role_rec.cust_account_id   := ln_cust_account_id_in;
        lr_cust_account_role_rec.cust_acct_site_id := ln_cust_acct_site_id_in;
        lr_cust_account_role_rec.role_type         := 'CONTACT';
        lr_cust_account_role_rec.created_by_module := 'XXCRM';


        fnd_file.put_line(fnd_file.LOG, '**********Create cust account role: ln_cust_account_id_in: ' ||ln_cust_account_id_in);
        fnd_file.put_line(fnd_file.LOG, '**********Create cust account role: ln_cust_acct_site_id_in: ' ||ln_cust_acct_site_id_in);
        fnd_file.put_line(fnd_file.LOG, '**********Create cust account role: ln_party_id_create_org_contact: ' ||ln_party_id_create_org_contact);


        hz_cust_account_role_v2pub.create_cust_account_role( p_init_msg_list         => 'T'
                                                           , p_cust_account_role_rec => lr_cust_account_role_rec
                                                           , x_cust_account_role_id  => ln_cust_account_role_id
                                                           , x_return_status         => lc_cust_acct_role_rtrn_status
                                                           , x_msg_count             => ln_cust_acct_role_msg_count
                                                           , x_msg_data              => lc_cust_acct_role_msg_data);

        IF lc_cust_acct_role_rtrn_status = FND_API.G_RET_STS_ERROR OR lc_cust_acct_role_rtrn_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

          ROLLBACK TO create_dunning_contact;
          RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Cust Account Role API failed, API error message:  ' || lc_cust_acct_role_msg_data;

        END IF;

        -------------------------------------------------------------------------------------------------------------------
        
        
        /* To reset the primary flag to N for the exisiting contacts
         */
        FOR role_resp_rec IN role_resp_cur( ln_cust_account_id_in
                                          , ln_cust_acct_site_id_in)
        LOOP

          hz_cust_account_role_v2pub.get_role_responsibility_rec ( p_init_msg_list            => 'T'
                                                                 , p_responsibility_id        => role_resp_rec.responsibility_id
                                                                 , x_role_responsibility_rec  => lr_role_responsibility_rec_in
                                                                 , x_return_status            => lc_get_role_resp_return_status
                                                                 , x_msg_count                => ln_get_role_resp_msg_count
                                                                 , x_msg_data                 => lc_get_role_resp_msg_data );
                                                                 
          IF lc_get_role_resp_return_status = FND_API.G_RET_STS_ERROR OR lc_get_role_resp_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

            ROLLBACK TO create_dunning_contact;
            RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Get Role Responsiblity Rec API failed for responsibility_id: ' || role_resp_rec.responsibility_id || ' , API error message:  ' || lc_get_role_resp_msg_data;

          END IF;                                                                 


           SELECT HRR.object_version_number 
             INTO ln_resp_object_version_number 
             FROM hz_role_responsibility HRR
            WHERE HRR.responsibility_id = role_resp_rec.responsibility_id;

            fnd_file.put_line(fnd_file.LOG, '**********role_resp_rec.responsibility_id: '  || role_resp_rec.responsibility_id);

            lr_role_responsibility_rec_in.primary_flag :='N';


            hz_cust_account_role_v2pub.update_role_responsibility ( p_init_msg_list           => 'T'
                                                                  , p_role_responsibility_rec => lr_role_responsibility_rec_in
                                                                  , p_object_version_number   => ln_resp_object_version_number
                                                                  , x_return_status           => lc_upd_role_resp_return_status
                                                                  , x_msg_count               => ln_upd_role_resp_msg_count
                                                                  , x_msg_data                => lc_upd_role_resp_msg_data);
                                                                  
          IF lc_upd_role_resp_return_status = FND_API.G_RET_STS_ERROR OR lc_upd_role_resp_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

            ROLLBACK TO create_dunning_contact;
            RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Get Role Responsiblity Rec API failed for responsibility_id: ' || role_resp_rec.responsibility_id || ' , API error message:  ' || lc_upd_role_resp_msg_data;

          END IF;                                                                    

        END LOOP;
        

        /* Set the contact role as Dunning */

        lr_role_responsibility_rec.cust_account_role_id := ln_cust_account_role_id;
        lr_role_responsibility_rec.responsibility_type  := 'DUN';
        lr_role_responsibility_rec.created_by_module := 'XXCRM';
        lr_role_responsibility_rec.primary_flag := 'Y';

        fnd_file.PUT_LINE(fnd_file.LOG, '**********Create responsibiltiy: ln_cust_account_role_id: ' ||ln_cust_account_role_id);

        hz_cust_account_role_v2pub.create_role_responsibility( p_init_msg_list           => 'T'
                                                             , p_role_responsibility_rec => lr_role_responsibility_rec
                                                             , x_responsibility_id       => ln_responsibility_id
                                                             , x_return_status           => lc_role_resp_return_status
                                                             , x_msg_count               => ln_role_resp_msg_count
                                                             , x_msg_data                => lc_role_resp_msg_data);

        IF lc_role_resp_return_status = FND_API.G_RET_STS_ERROR OR lc_role_resp_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

          ROLLBACK TO create_dunning_contact;
          RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Role Responsibility API failed, API error message: ' || lc_role_resp_msg_data;

        END IF;

        -------------------------------------------------------------------------------------------------------------------


        /* Creating contact points for eMail, Fax and Telephone.
         * If email is populated then make email as business purpose Dunning and Fax and phone as collections.
         * If only fax and phone information is populated the make Fax as Business purpose of Dunning and Phone as Collections
         * If only Phone is populated make Phone as business purpose Dunning.
         */
        IF p_email_id IS NOT NULL THEN

          lr_contact_point_rec_email.contact_point_type := 'EMAIL';
          lr_contact_point_rec_email.owner_table_name := 'HZ_PARTIES';
          lr_contact_point_rec_email.owner_table_id := ln_party_id_create_org_contact;
          lr_contact_point_rec_email.primary_flag := 'Y';
          lr_contact_point_rec_email.contact_point_purpose := 'DUNNING';
          lr_contact_point_rec_email.created_by_module := 'XXCRM';

          lr_email_rec.email_format := 'MAILHTML';
          lr_email_rec.email_address := p_email_id;


          hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                     , p_contact_point_rec => lr_contact_point_rec_email
                                                     , p_edi_rec           => lr_edi_rec
                                                     , p_email_rec         => lr_email_rec
                                                     , p_phone_rec         => lr_phone_rec_dummy
                                                     , p_telex_rec         => lr_telex_rec
                                                     , p_web_rec           => lr_web_rec
                                                     , x_contact_point_id  => ln_contact_point_id
                                                     , x_return_status     => lc_contact_point_return_status
                                                     , x_msg_count         => ln_contact_point_msg_count
                                                     , x_msg_data          => lc_contact_point_msg_data);

          IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

            ROLLBACK TO create_dunning_contact;
            RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Email, API error message: ' || lc_contact_point_msg_data;

          END IF;

          IF p_fax_code IS NOT NULL AND p_fax IS NOT NULL THEN

            lr_contact_point_rec_fax.contact_point_type := 'PHONE';
            lr_contact_point_rec_fax.owner_table_name := 'HZ_PARTIES';
            lr_contact_point_rec_fax.owner_table_id := ln_party_id_create_org_contact;
            lr_contact_point_rec_fax.contact_point_purpose := 'COLLECTIONS';
            lr_contact_point_rec_fax.primary_flag := 'N';
            lr_contact_point_rec_fax.created_by_module := 'XXCRM';

            lr_fax_rec.phone_area_code := p_fax_code;
            lr_fax_rec.phone_country_code := '1';
            lr_fax_rec.phone_number := p_fax;
            lr_fax_rec.phone_line_type := 'FAX';

            hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                       , p_contact_point_rec =>  lr_contact_point_rec_fax
                                                       , p_edi_rec           =>  lr_edi_rec
                                                       , p_email_rec         =>  lr_email_rec_dummy
                                                       , p_phone_rec         =>  lr_fax_rec
                                                       , p_telex_rec         =>  lr_telex_rec
                                                       , p_web_rec           =>  lr_web_rec
                                                       , x_contact_point_id  =>  ln_contact_point_id
                                                       , x_return_status     =>  lc_contact_point_return_status
                                                       , x_msg_count         =>  ln_contact_point_msg_count
                                                       , x_msg_data          =>  lc_contact_point_msg_data);

            IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

              ROLLBACK TO create_dunning_contact;
              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Fax, API error message: ' || lc_contact_point_msg_data;

            END IF;

          END IF;  -- p_fax_code IS NOT NULL AND p_fax IS NOT NULL


          IF p_tele_code IS NOT NULL AND p_telephone IS NOT NULL THEN


            lr_contact_point_rec_phone.contact_point_type := 'PHONE';
            lr_contact_point_rec_phone.owner_table_name := 'HZ_PARTIES';
            lr_contact_point_rec_phone.owner_table_id := ln_party_id_create_org_contact;
            lr_contact_point_rec_phone.contact_point_purpose := 'COLLECTIONS';
            lr_contact_point_rec_phone.primary_flag := 'N';
            lr_contact_point_rec_phone.created_by_module := 'XXCRM';

            lr_phone_rec.phone_area_code := p_tele_code;
            lr_phone_rec.phone_country_code := '1';
            lr_phone_rec.phone_number := p_telephone;
            lr_phone_rec.phone_line_type := 'GEN';

            hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                       , p_contact_point_rec =>  lr_contact_point_rec_phone
                                                       , p_edi_rec           =>  lr_edi_rec
                                                       , p_email_rec         =>  lr_email_rec_dummy
                                                       , p_phone_rec         =>  lr_phone_rec
                                                       , p_telex_rec         =>  lr_telex_rec
                                                       , p_web_rec           =>  lr_web_rec
                                                       , x_contact_point_id  =>  ln_contact_point_id
                                                       , x_return_status     =>  lc_contact_point_return_status
                                                       , x_msg_count         =>  ln_contact_point_msg_count
                                                       , x_msg_data          =>  lc_contact_point_msg_data);

            IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

              ROLLBACK TO create_dunning_contact;
              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Phone, API error message: ' || lc_contact_point_msg_data;

            END IF;

          END IF; -- p_tele_code IS NOT NULL AND p_telephone IS NOT NULL

        ELSE -- p_email_id IS NOT NULL

          IF p_fax_code IS NOT NULL AND p_fax IS NOT NULL  THEN

            lr_contact_point_rec_fax.contact_point_type := 'PHONE';
            lr_contact_point_rec_fax.owner_table_name := 'HZ_PARTIES';
            lr_contact_point_rec_fax.owner_table_id := ln_party_id_create_org_contact;
            lr_contact_point_rec_fax.contact_point_purpose := 'DUNNING';
            lr_contact_point_rec_fax.primary_flag := 'Y';
            lr_contact_point_rec_fax.created_by_module := 'XXCRM';

            lr_fax_rec.phone_area_code := p_fax_code;
            lr_fax_rec.phone_country_code := '1';
            lr_fax_rec.phone_number := p_fax;
            lr_fax_rec.phone_line_type := 'FAX';

            hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                       , p_contact_point_rec =>  lr_contact_point_rec_fax
                                                       , p_edi_rec           =>  lr_edi_rec
                                                       , p_email_rec         =>  lr_email_rec_dummy
                                                       , p_phone_rec         =>  lr_fax_rec
                                                       , p_telex_rec         =>  lr_telex_rec
                                                       , p_web_rec           =>  lr_web_rec
                                                       , x_contact_point_id  =>  ln_contact_point_id
                                                       , x_return_status     =>  lc_contact_point_return_status
                                                       , x_msg_count         =>  ln_contact_point_msg_count
                                                       , x_msg_data          =>  lc_contact_point_msg_data);

            IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

              ROLLBACK TO create_dunning_contact;
              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Fax, API error message:  ' || lc_contact_point_msg_data;

            END IF;

            IF  p_tele_code IS NOT NULL AND p_telephone IS NOT NULL  THEN

              lr_contact_point_rec_phone.contact_point_type := 'PHONE';
              lr_contact_point_rec_phone.owner_table_name := 'HZ_PARTIES';
              lr_contact_point_rec_phone.owner_table_id := ln_party_id_create_org_contact;
              lr_contact_point_rec_phone.contact_point_purpose := 'COLLECTIONS';
              lr_contact_point_rec_phone.primary_flag := 'N';
              lr_contact_point_rec_phone.created_by_module := 'XXCRM';

              lr_phone_rec.phone_area_code := p_tele_code;
              lr_phone_rec.phone_country_code := '1';
              lr_phone_rec.phone_number := p_telephone;
              lr_phone_rec.phone_line_type := 'GEN';

              hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                         , p_contact_point_rec =>  lr_contact_point_rec_phone
                                                         , p_edi_rec           =>  lr_edi_rec
                                                         , p_email_rec         =>  lr_email_rec_dummy
                                                         , p_phone_rec         =>  lr_phone_rec
                                                         , p_telex_rec         =>  lr_telex_rec
                                                         , p_web_rec           =>  lr_web_rec
                                                         , x_contact_point_id  =>  ln_contact_point_id
                                                         , x_return_status     =>  lc_contact_point_return_status
                                                         , x_msg_count         =>  ln_contact_point_msg_count
                                                         , x_msg_data          =>  lc_contact_point_msg_data);

              IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

                ROLLBACK TO create_dunning_contact;

                RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Phone, API error message:  ' || lc_contact_point_msg_data;

              END IF;

            END IF;  -- p_tele_code IS NOT NULL AND p_telephone IS NOT NULL

          ELSE -- p_fax_code IS NOT NULL AND p_fax IS NOT NULL

            IF  p_tele_code IS NOT NULL AND p_telephone IS NOT NULL  THEN

              lr_contact_point_rec_phone.contact_point_type := 'PHONE';
              lr_contact_point_rec_phone.owner_table_name := 'HZ_PARTIES';
              lr_contact_point_rec_phone.owner_table_id := ln_party_id_create_org_contact;
              lr_contact_point_rec_phone.contact_point_purpose := 'DUNNING';
              lr_contact_point_rec_phone.primary_flag := 'Y';
              lr_contact_point_rec_phone.created_by_module := 'XXCRM';

              lr_phone_rec.phone_area_code := p_tele_code;
              lr_phone_rec.phone_country_code := '1';
              lr_phone_rec.phone_number := p_telephone;
              lr_phone_rec.phone_line_type := 'GEN';

              hz_contact_point_v2pub.create_contact_point( p_init_msg_list     => 'T'
                                                         , p_contact_point_rec =>  lr_contact_point_rec_phone
                                                         , p_edi_rec           =>  lr_edi_rec
                                                         , p_email_rec         =>  lr_email_rec_dummy
                                                         , p_phone_rec         =>  lr_phone_rec
                                                         , p_telex_rec         =>  lr_telex_rec
                                                         , p_web_rec           =>  lr_web_rec
                                                         , x_contact_point_id  =>  ln_contact_point_id
                                                         , x_return_status     =>  lc_contact_point_return_status
                                                         , x_msg_count         =>  ln_contact_point_msg_count
                                                         , x_msg_data          =>  lc_contact_point_msg_data);

              IF lc_contact_point_return_status = FND_API.G_RET_STS_ERROR OR lc_contact_point_return_status =  FND_API.G_RET_STS_UNEXP_ERROR THEN

                ROLLBACK TO create_dunning_contact;

                RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Create Contact Point API failed for Phone, API error message:  ' || lc_contact_point_msg_data;

              END IF;

            ELSE  -- p_tele_code IS NOT NULL AND p_telephone IS NOT NULL

              ROLLBACK TO create_dunning_contact;

              RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Contact point details(eMail, Fax, Phone) not provided';

            END IF;  -- p_tele_code IS NOT NULL AND p_telephone IS NOT NULL

          END IF; -- p_fax_code IS NOT NULL AND p_fax IS NOT NULL

        END IF; -- p_email_id IS NOT NULL

        --fnd_profile.put('XX_CDH_SEC_BYPASS_SEC_RULES',lc_vpd_profile);


        COMMIT;


        /* If a contact with JOB = 'AP' already exists return a warning else return success
         */
         
        OPEN check_account_cur(ln_cust_account_id_in);
        
        FETCH check_account_cur INTO ln_account_ex;
        
        IF check_account_cur%NOTFOUND THEN
        
          IF ln_war_flag = 1 THEN
          
            lc_return_message := lc_return_message  || '", Account is inactive.';            
          
          ELSE
          
            lc_return_message := lc_return_message  || '"Account is inactive.';        
            
          END IF;        
        
          ln_war_flag := 1;        
          
        
        END IF;
        
        CLOSE check_account_cur;
     
        
        OPEN check_site_cur(ln_cust_acct_site_id_in);
        
        FETCH check_site_cur INTO ln_site_ex;
        
        IF check_site_cur%NOTFOUND THEN
        
          IF ln_war_flag = 1 THEN
          
            lc_return_message := lc_return_message || '", Cust account site is inactive.';          
          
          ELSE
          
            lc_return_message := lc_return_message || '"Cust account site is inactive.';     
            
          END IF;  
          
          ln_war_flag := 1;          

        
        END IF;
        
        CLOSE check_site_cur;
        
        
        IF ln_war_flag = 1 THEN
        
          RETURN lc_return_message;
          
        ELSE 
          
          RETURN 'TRUE' || lc_account_number_in || '"'|| ',' || '"Success';          
        
        END IF;

      ELSE -- contact_cur%NOTFOUND

        fnd_file.put_line(fnd_file.log, '**********Dunning contact point already exists');


        RETURN 'FALSE_' ||  lc_account_number_in  || '"' || ',' || '"Error' || '"' || ',' || '"Dunning contact point already exists';

      END IF; -- contact_cur%NOTFOUND

    CLOSE CONTACT_CUR;

    COMMIT;

    RETURN 'TRUE' || lc_account_number_in || '"' || ',' ||  '"Success';

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 'FALSE_ERROR_Unexpected exception_' || SQLERRM;

  END xx_cdh_dunn_cont_tmplt;

END xx_cdh_dunning_contacts_pkg;
/
SHOW ERR
