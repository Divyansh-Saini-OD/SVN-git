CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_OMX_EBILL_CONTACTS_PKG
AS
   -- +==================================================================================+
   -- |                        Office Depot                                              |
   -- +==================================================================================+
   -- | Name  : XX_CDH_OMX_EBILL_CONTACTS_PKG                                            |
   -- | Rice ID: C0700                                                                   |
   -- | Description      : This program will process all the records and creates the     |
   -- |                    ebilling contacts and link to corresponding billing document  |
   -- |                                                                                  |
   -- |Change Record:                                                                    |
   -- |===============                                                                   |
   -- |Version Date        Author            Remarks                                     |
   -- |======= =========== =============== ==============================================|
   -- |1.0     18-FEB-2015 Havish Kasina   Initial draft version                         |
   -- |2.0     12-MAR-2015 Havish Kasina   Code review changes                           |  
   -- |3.0     05-MAY-2015 Havish Kasina   Changes done as per Defect # 1239             | 
   -- |4.0     22-SEP-2015 Havish Kasina   Changes done as per Defect # 1738             | 
   -- +==================================================================================+

   --------------------------------
   -- Global Variable Declaration --
   --------------------------------
   gd_last_update_date    DATE          := SYSDATE;
   gn_last_updated_by     NUMBER        := fnd_global.user_id;
   gd_creation_date       DATE          := SYSDATE;
   gn_created_by          NUMBER        := fnd_global.user_id;
   gn_last_update_login   NUMBER        := fnd_global.login_id;
   gn_request_id          NUMBER        := fnd_global.conc_request_id;
   gd_cycle_date          DATE          := SYSDATE;
   gn_conc_request_id     NUMBER        := fnd_global.conc_request_id;  -- request_id
   gn_conc_prog_appl_id   NUMBER        := fnd_global.prog_appl_id; -- program_application_id
   gn_conc_program_id     NUMBER        := fnd_global.conc_program_id;  -- program_id
   gc_success             VARCHAR2(1)   := 'S';
   gc_failure             VARCHAR2(1)   := 'F';
   
   PROCEDURE log_msg (p_string IN VARCHAR2)
   IS
   -- +===================================================================+
   -- | Name  : log_msg                                                   |
   -- | Description     : The log_msg procedure displays the log messages |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters      : p_string             IN -> Log Message          |
   -- +===================================================================+
   BEGIN
   
      IF (g_debug_flag)
      THEN      
         fnd_file.put_line (fnd_file.LOG, p_string);         
      END IF;
      
   END log_msg;

   PROCEDURE log_exception (p_error_location   IN VARCHAR2,
                            p_error_msg        IN VARCHAR2)
   IS
   -- +===================================================================+
   -- | Name  : log_exception                                             |
   -- | Description     : The log_exception procedure logs all exceptions |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters      : p_error_location     IN -> Error location       |
   -- |                   p_error_msg          IN -> Error message        |
   -- +===================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   ln_login     NUMBER := gn_last_update_login;
   ln_user_id   NUMBER := gn_created_by;
   
   BEGIN   
      XX_COM_ERROR_LOG_PUB.log_error 
      (  p_return_code              => FND_API.G_RET_STS_ERROR,
         p_msg_count                => 1,
         p_application_name         => 'XXCRM',
         p_program_type             => 'Custom Messages',
         p_program_name             => 'XX_CDH_OMX_EBILL_CONTACTS',
         p_attribute15              => 'XX_CDH_OMX_EBILL_CONTACTS',
         p_program_id               => NULL,
         p_module_name              => 'MOD4A',
         p_error_location           => p_error_location,
         p_error_message_code       => NULL,
         p_error_message            => p_error_msg,
         p_error_message_severity   => 'MAJOR',
         p_error_status             => 'ACTIVE',
         p_created_by               => ln_user_id,
         p_last_updated_by          => ln_user_id,
         p_last_update_login        => ln_login
      );      
   EXCEPTION   
      WHEN OTHERS
      THEN
      log_msg('Error while writing to the log exception...' || SQLERRM);      
   END log_exception;

--update the status in staging table

  PROCEDURE update_status(p_record_id           IN        NUMBER,
                          p_status              IN        VARCHAR2,
                          p_error_message       IN OUT    VARCHAR2)
  IS  
  -- +=======================================================================+
  -- | Name  : update_status                                                 |
  -- | Description: This is to update the status in staging table            |
  -- |                                                                       |
  -- | Parameters : p_record_id         IN        -> Record Id               |
  -- |              p_status            IN        -> Status in staging table |
  -- |              p_error_message     IN OUT    -> Error Message           |
  -- +=======================================================================+
   BEGIN

     UPDATE xx_cdh_omx_ebill_contacts_stg
     SET status           = p_status,
         error_message    = p_error_message,
         last_update_date = gd_last_update_date,
         last_updated_by  = gn_last_updated_by
      WHERE record_id     = p_record_id;
    
    p_error_message:= NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF p_error_message IS NULL
      THEN
        p_error_message := 'Error while updating the status  '|| SQLERRM ;
      END IF;
      log_msg (p_error_message);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.UPDATE_STATUS',
                     p_error_msg        => p_error_message);
  END update_status;


   PROCEDURE Check_contact (p_return_status      OUT VARCHAR2,
                            p_return_msg         OUT VARCHAR2,
                            p_contact_rec        IN  xx_cdh_omx_ebill_contacts_stg%ROWTYPE,
                            p_cust_acct_id       IN  NUMBER,
                            p_cust_party_id      IN  NUMBER,
                            p_contact_id         OUT NUMBER,
                            p_org_contact_id     OUT NUMBER)
   IS
   -- +=======================================================================+
   -- | Name  : Check_contact                                                 |
   -- | Description: This is to check contact exists or not                   |
   -- |                                                                       |
   -- | Parameters : p_return_status         OUT    -> Return Status          |
   -- |              p_return_msg            OUT    -> Return Message         |
   -- |              p_contact_rec           IN     -> Contact record         |
   -- |              p_cust_acct_id          IN     -> Customer Account id    |
   -- |              p_cust_party_id         IN     -> Party id               |
   -- |              p_contact_id            OUT    -> Contact Id             |
   -- |              p_org_contact_id        OUT    -> Org Contact Id         |
   -- +=======================================================================+
   lc_email_id          VARCHAR2(200);
   BEGIN
      p_contact_id  := NULL;
      p_org_contact_id := NULL;
      SELECT hcp.contact_point_id,hcp.email_Address,hoc.org_contact_id
        INTO p_contact_id,lc_email_id,p_org_contact_id
        FROM hz_cust_account_roles hcar,
             hz_parties hprel,
             hz_org_contacts hoc,
             hz_relationships hr,
             hz_cust_accounts hca,
             hz_contact_points hcp
       WHERE hcar.cust_account_id = hca.cust_account_id
         AND hca.cust_account_id = p_cust_acct_id
         AND hcar.role_type = 'CONTACT'
         AND hcar.party_id = hr.party_id
         AND hr.party_id = hprel.party_id
         AND hoc.party_relationship_id = hr.relationship_id
         AND hr.directional_flag = 'F'
         AND hr.subject_type = 'PERSON'
         AND hr.subject_table_name = 'HZ_PARTIES'
         AND hcp.owner_table_id = hprel.party_id
         AND hcp.contact_point_purpose = 'BILLING'
         AND hcp.contact_point_Type = 'EMAIL'
         AND UPPER (hcp.email_Address) = TRIM(UPPER (p_contact_rec.email_address));
      
      p_return_status := gc_success;
      p_return_msg    := NULL;
      log_msg('Contact Exists. Contact Id is; '||p_contact_id||' and Email Id is : '||lc_email_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_return_status := gc_failure;         
         p_return_msg    :='No Contact Exists';
         p_contact_id    := NULL;
         p_org_contact_id:= NULL;
         log_msg (p_return_msg);
              
      WHEN TOO_MANY_ROWS
      THEN
         p_return_status := gc_failure;         
         p_return_msg    :='Too many Contacts found ';
         p_contact_id    := NULL;
         p_org_contact_id:= NULL;
         log_msg (p_return_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CHECK_CONTACT',
                        p_error_msg        => p_return_msg);               
      WHEN OTHERS
      THEN         
         IF p_return_msg IS NULL
         THEN
            p_return_msg :='Unable to fetch the contact id'||' '||SQLERRM;
         END IF;
         p_return_status := gc_failure;
         p_contact_id    := NULL;
         p_org_contact_id:= NULL;
         log_msg (p_return_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CHECK_CONTACT',
                        p_error_msg        => p_return_msg);
               
   END Check_contact;

-- Create person
   PROCEDURE create_person ( p_return_status   OUT    VARCHAR2,
                             p_return_msg      OUT    VARCHAR2,
                             p_contact_rec     IN     xx_cdh_omx_ebill_contacts_stg%ROWTYPE,
                             p_person_id       OUT    NUMBER)
   IS
   -- +=======================================================================+
   -- | Name  : create_person                                                 |
   -- | Description: This is to create the person                             |
   -- |                                                                       |
   -- | Parameters : p_return_status         OUT    -> Return Status          |
   -- |              p_return_msg            OUT    -> Return Message         |
   -- |              p_contact_rec           IN     -> Contact record         |
   -- |              p_person_id             OUT     -> Person Id             |
   -- +=======================================================================+  
            
   lr_person_rec        hz_party_v2pub.person_rec_type;
   e_process_exception  EXCEPTION;
   --Out variables for API
   lc_party_num         hz_parties.party_number%TYPE;
   ln_profile_id        hz_person_profiles.person_profile_id%TYPE;
   lc_return_status     VARCHAR2 (1);
   ln_msg_count         NUMBER;
   lc_msg_data          VARCHAR2 (256);
   
   BEGIN
   
      lr_person_rec        := NULL;
      lc_party_num         := NULL;
      ln_profile_id        := NULL;
      lc_return_status     := NULL;
      ln_msg_count         := NULL;
      lc_msg_data          := NULL;
      p_person_id          := NULL;

      lr_person_rec.created_by_module := 'XXOMXCNV'; -- Module name
      lr_person_rec.person_first_name :=NVL (TRIM(p_contact_rec.contact_first_name),SUBSTR (TRIM(p_contact_rec.email_address),1,INSTR (TRIM(p_contact_rec.email_address), '@') - 1));-- First Name
      lr_person_rec.person_last_name :=NVL (TRIM(p_contact_rec.contact_last_name), 'OMX'); -- Last Name
      
      log_msg('Creating Person');
      hz_party_v2pub.create_person (   p_init_msg_list   => fnd_api.g_true
                                     , p_person_rec      => lr_person_rec
                                     , x_party_id        => p_person_id
                                     , x_party_number    => lc_party_num
                                     , x_profile_id      => ln_profile_id
                                     , x_return_status   => lc_return_status
                                     , x_msg_count       => ln_msg_count
                                     , x_msg_data        => lc_msg_data
                                     );
                                     
       log_msg('person party Id is     :'||p_person_id);
       log_msg('person party number is :'||lc_party_num);
       log_msg('person profile id is   :'||ln_profile_id);
       
      --derive error messages from API if Ret status
      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         log_msg('Creation of Person failed');
         FOR i IN 1 .. FND_MSG_PUB.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => fnd_api.g_false,
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            p_return_msg := p_return_msg || ('Msg'||TO_CHAR(i)||':'||lc_msg_data);
         END LOOP;
         
         RAISE e_process_exception;
         
      ELSIF lc_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
         p_return_status := gc_success;
         p_return_msg    := NULL;
         log_msg('Creation of Person is successful');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_return_msg IS NULL
         THEN
            p_return_msg := 'Unable to create the person' ||' '|| SQLERRM;   
         END IF;      
         log_msg (p_return_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_PERSON',
                        p_error_msg        => p_return_msg);
         p_person_id     := NULL;
         p_return_status := gc_failure;  
             
   END create_person;


-- Create org contact
   PROCEDURE create_org_contact ( p_return_status       OUT    VARCHAR2,
                                  p_return_msg          OUT    VARCHAR2,
                                  p_cust_acct_id        IN     NUMBER,
                                  p_person_id           IN     NUMBER,
                                  p_cust_party_id       IN     NUMBER,
                                  p_person_rel_id       OUT    NUMBER,
                                  p_org_contact_id      OUT    NUMBER)
   IS
   -- +=======================================================================+
   -- | Name  : create_org_contact                                            |
   -- | Description: This is to create the org contact                        |
   -- |                                                                       |
   -- | Parameters : p_return_status         OUT    -> Return Status          |
   -- |              p_return_msg            OUT    -> Return Message         |
   -- |              p_cust_acct_id          IN     -> Customer Account Id    |
   -- |              p_person_id             IN     -> Person Id              |
   -- |              p_cust_party_id         IN     -> Party Id               |
   -- |              p_person_rel_id         OUT    -> Relationsip id         |
   -- |              p_org_contact_id        OUT    -> Org Contact Id         |
   -- +=======================================================================+
   lr_org_contact_rec     hz_party_contact_v2pub.org_contact_rec_type;
   e_process_exception    EXCEPTION;
   --API out variables
   ln_party_rel_id        hz_relationships.relationship_id%TYPE;
   lc_party_contact_num   hz_parties.party_number%TYPE;
   lc_return_status       VARCHAR2 (1);
   ln_msg_count           NUMBER;
   lc_msg_data            VARCHAR2 (256);
   BEGIN
      lr_org_contact_rec        := NULL;
      ln_party_rel_id           := NULL;
      lc_party_contact_num      := NULL;
      lc_return_status          := NULL;
      ln_msg_count              := NULL;
      lc_msg_data               := NULL;
      p_org_contact_id          := NULL;
      p_person_rel_id           := NULL;
   
      lr_org_contact_rec.job_title := NULL;
      lr_org_contact_rec.party_rel_rec.subject_id := p_person_id;
      lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
      lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';

      --Customer Party Info
      lr_org_contact_rec.party_rel_rec.object_id := p_cust_party_id;
      lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
      lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
      lr_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
      lr_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
      lr_org_contact_rec.party_rel_rec.status := 'A';
      lr_org_contact_rec.party_rel_rec.attribute20 := NULL;
      lr_org_contact_rec.created_by_module := 'XXOMXCNV';
      lr_org_contact_rec.party_rel_rec.created_by_module := 'XXOMXCNV';

      log_msg('Creating Org contact');
      hz_party_contact_v2pub.create_org_contact ( p_init_msg_list     => fnd_api.g_true,
                                                  p_org_contact_rec   => lr_org_contact_rec,
                                                  x_org_contact_id    => p_org_contact_id,
                                                  x_party_rel_id      => ln_party_rel_id,-- hz_relationships.relationship_id
                                                  x_party_id          => p_person_rel_id,        --ln_party_contact_id,-- relationship record in hz_parties
                                                  x_party_number      => lc_party_contact_num,
                                                  x_return_status     => lc_return_status,
                                                  x_msg_count         => ln_msg_count,
                                                  x_msg_data          => lc_msg_data);
                                                  
      log_msg('Org Contact id        :'||p_org_contact_id);
      log_msg('Party Relationship id :'||ln_party_rel_id);

      --derive error messages from API if Ret status
      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         log_msg('Creation of Org contact failed');
         FOR i IN 1 .. FND_MSG_PUB.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => fnd_api.g_false,
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            p_return_msg := p_return_msg || ('Msg'||TO_CHAR(i)||':'||lc_msg_data);
         END LOOP;

         RAISE e_process_exception;
         
      ELSIF lc_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
         p_return_status := gc_success;
         p_return_msg    := NULL;
         log_msg('Creation of org contact is successful');

      END IF;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_return_msg IS NULL
         THEN
            p_return_msg := 'Unable to create create org contact'||'  '|| SQLERRM;
         END IF;         
         log_msg (p_return_msg);
         log_exception ( p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_ORG_CONTACT',
                         p_error_msg        => p_return_msg);
         p_return_status  := gc_failure;
         p_person_rel_id  := NULL;
         p_org_contact_id := NULL;
                           
   END Create_Org_contact;


-- Create contact role
   PROCEDURE create_contact_role (  p_return_status          OUT VARCHAR2,
                                    p_return_msg             OUT VARCHAR2,
                                    p_cust_acct_id           IN  NUMBER,
                                    p_person_rel_id          IN  NUMBER,
                                    p_cust_acct_role_id      OUT NUMBER)
   IS
   -- +==========================================================================+
   -- | Name  : create_contact_role                                              |
   -- | Description: This is to create the contact role                          |
   -- |                                                                          |
   -- | Parameters : p_return_status         OUT    -> Return Status             |
   -- |              p_return_msg            OUT    -> Return Message            |
   -- |              p_cust_acct_id          IN     -> Customer Account Id       |
   -- |              p_person_rel_id         IN     -> Relationsip id            |
   -- |              p_cust_acct_role_id     OUT    -> Customer account role id  |
   -- +==========================================================================+
   lr_acct_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;

   lc_return_status     VARCHAR2 (1);
   ln_msg_count         NUMBER;
   lc_msg_data          VARCHAR2 (256);
   e_process_exception  EXCEPTION;
   BEGIN
      lr_acct_role_rec      := NULL;
      lc_return_status      := NULL;
      ln_msg_count          := NULL;
      lc_msg_data           := NULL;
      p_cust_acct_role_id   := NULL;
   
      lr_acct_role_rec.created_by_module := 'XXOMXCNV';
      lr_acct_role_rec.cust_account_id := p_cust_acct_id;
      lr_acct_role_rec.party_id := p_person_rel_id;
      lr_acct_role_rec.role_type := 'CONTACT';
      lr_acct_role_rec.status := 'A';
      
      log_msg('Creating Customer account role');
      hz_cust_account_role_v2pub.create_cust_account_role (   p_init_msg_list           => fnd_api.g_true,
                                                              p_cust_account_role_rec   => lr_acct_role_rec,
                                                              x_cust_account_role_id    => p_cust_acct_role_id,
                                                              x_return_status           => lc_return_status,
                                                              x_msg_count               => ln_msg_count,
                                                              x_msg_data                => lc_msg_data);

      log_msg('Customer account role id :'||p_cust_acct_role_id);
      
      --derive error messages from API if Ret status
      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         log_msg('Creation of Customer account role failed');
         FOR i IN 1 .. FND_MSG_PUB.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => fnd_api.g_false,
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            p_return_msg := p_return_msg || ('Msg'||TO_CHAR(i)||':'||lc_msg_data);
         END LOOP;
         
         RAISE e_process_exception;
         
      ELSIF lc_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
         p_return_status := gc_success;
         p_return_msg    := NULL;
         log_msg('Creation of Customer account role is successful');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_return_msg is NULL
         THEN
            p_return_msg := 'Unable to create customer account role'||'  '|| SQLERRM;
         END IF;         
         log_msg (p_return_msg);
         log_exception ( p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_CONTACT_ROLE',
                         p_error_msg        => p_return_msg);
         p_cust_acct_role_id := NULL;
         p_return_status     := gc_failure;
         
   END create_contact_role;

-- Create contact role responsibility
   PROCEDURE create_contact_role_resp (   p_return_status          OUT VARCHAR2,
                                          p_return_msg             OUT VARCHAR2,
                                          p_cust_acct_role_id      IN  NUMBER,
                                          p_role_resp_id           OUT NUMBER)
   IS
   -- +==========================================================================+
   -- | Name  : create_contact_role_resp                                         |
   -- | Description: This is to create the contact role responsibility           |
   -- |                                                                          |
   -- | Parameters : p_return_status         OUT    -> Return Status             |
   -- |              p_return_msg            OUT    -> Return Message            |
   -- |              p_role_resp_id          OUT    -> Role responsibility id    |
   -- |              p_cust_acct_role_id     IN     -> Customer account role id  |
   -- +==========================================================================+
   lr_role_resp_rec   hz_cust_account_role_v2pub.role_responsibility_rec_type;

   lc_return_status     VARCHAR2 (1);
   ln_msg_count         NUMBER;
   lc_msg_data          VARCHAR2 (256);
   e_process_exception  EXCEPTION;
   BEGIN
      lr_role_resp_rec   := NULL;
      lc_return_status   := NULL;
      ln_msg_count       := NULL;
      lc_msg_data        := NULL;
      p_role_resp_id     := NULL;
      
      lr_role_resp_rec.created_by_module := 'XXOMXCNV';      --our_module_name;
      lr_role_resp_rec.cust_account_role_id := p_cust_acct_role_id;
      lr_role_resp_rec.primary_flag := 'Y';
      lr_role_resp_rec.responsibility_type := 'BILLING';
      
      log_msg('Creating Contact role responsibility');
      hz_cust_account_role_v2pub.create_role_responsibility ( p_init_msg_list             => fnd_api.g_true,
                                                              p_role_responsibility_rec   => lr_role_resp_rec,
                                                              x_responsibility_id         => p_role_resp_id,
                                                              x_return_status             => lc_return_status,
                                                              x_msg_count                 => ln_msg_count,
                                                              x_msg_data                  => lc_msg_data);

      log_msg('Contact role responsibility id is :'||p_role_resp_id);
      
      --derive error messages from API if Ret status
      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         log_msg('Creation of contact role responsibility failed');
         FOR i IN 1 .. FND_MSG_PUB.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => fnd_api.g_false,
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            p_return_msg := p_return_msg || ('Msg'||TO_CHAR(i)||':'||lc_msg_data);
         END LOOP;
         
         RAISE e_process_exception;

      ELSIF lc_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
         p_return_status := gc_success;
         p_return_msg    := NULL;
         log_msg('Creation of Contact role responsibility is successful');

      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN         
         IF p_return_msg IS NULL
         THEN
            p_return_msg := 'Uanble to create contact role responsibility'||'  '|| SQLERRM;    
         END IF;     
         log_msg (p_return_msg);
         log_exception ( p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_CONTACT_ROLE_RESP',
                         p_error_msg        => p_return_msg);
         p_return_status := gc_failure;
         p_role_resp_id  := NULL;
         
   END Create_contact_role_resp;

-- Create email  contact id
   PROCEDURE Create_email_Contact ( p_return_status         OUT VARCHAR2,
                                    p_return_msg            OUT VARCHAR2,
                                    p_contact_rec           IN  xx_cdh_omx_ebill_contacts_stg%ROWTYPE,
                                    p_person_rel_id         IN  NUMBER,
                                    p_contact_point_id      OUT NUMBER)
   IS
   -- +==========================================================================+
   -- | Name  : create_contact_role_resp                                         |
   -- | Description: This is to create the contact role responsibility           |
   -- |                                                                          |
   -- | Parameters : p_return_status         OUT    -> Return Status             |
   -- |              p_return_msg            OUT    -> Return Message            |
   -- |              p_contact_rec           IN     -> Contact record            |
   -- |              p_person_rel_id         IN     -> Contact party id          |
   -- |              p_contact_point_id      OUT    -> Contact Point Id          |
   -- +==========================================================================+
   lr_contact_point_rec   hz_contact_point_v2pub.contact_point_rec_type;
   lr_email_rec           hz_contact_point_v2pub.email_rec_type;

   lc_return_status       VARCHAR2 (1);
   ln_msg_count           NUMBER;
   lc_msg_data            VARCHAR2 (256);
   e_process_exception    EXCEPTION;
   BEGIN
      lr_contact_point_rec   := NULL;
      lr_email_rec           := NULL;
      lc_return_status       := NULL;
      ln_msg_count           := NULL;
      lc_msg_data            := NULL;
      p_contact_point_id     := NULL;
      
      lr_contact_point_rec.contact_point_type := 'EMAIL';
      lr_contact_point_rec.owner_table_name := 'HZ_PARTIES';
      lr_contact_point_rec.owner_table_id := p_person_rel_id; --p_contact_party_id; --p_party_id;
      lr_contact_point_rec.created_by_module := 'XXOMXCNV';  --our_module_name;
      lr_contact_point_rec.status := 'A';
      lr_contact_point_rec.contact_point_purpose := 'BILLING';

      lr_email_rec.email_format := 'MAILHTML';
      lr_email_rec.email_address := TRIM(p_contact_rec.email_address);

      log_msg('Creating email contact point');
      hz_contact_point_v2pub.create_email_contact_point (  p_init_msg_list       => fnd_api.g_true,
                                                           p_contact_point_rec   => lr_contact_point_rec,
                                                           p_email_rec           => lr_email_rec,
                                                           x_contact_point_id    => p_contact_point_id,
                                                           x_return_status       => lc_return_status,
                                                           x_msg_count           => ln_msg_count,
                                                           x_msg_data            => lc_msg_data);
                                                           
       log_msg('Contact point id is:'||p_contact_point_id);

      --derive error messages from API if Ret status
      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         log_msg('Creation of email contact point failed');
         FOR i IN 1 .. FND_MSG_PUB.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => fnd_api.g_false,
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            p_return_msg := p_return_msg || ('Msg'||TO_CHAR(i)||':'||lc_msg_data);
         END LOOP;
         RAISE e_process_exception;

      ELSIF lc_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
         p_return_status := gc_success;
         p_return_msg    := NULL;
         log_msg('Creation of email contact point is successful');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_return_msg IS NULL
         THEN
            p_return_msg := 'Uanble to create email contact point'||'  '|| SQLERRM;  
         END IF;       
         log_msg (p_return_msg);
         log_exception ( p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_EMAIL_CONTACT',
                         p_error_msg        => p_return_msg);
         p_contact_point_id := NULL;
         p_return_status := gc_failure;
         
   END Create_email_Contact;


   PROCEDURE create_contact ( p_return_status      OUT    VARCHAR2,
                              p_return_msg         OUT    VARCHAR2,
                              p_contact_rec        IN     xx_cdh_omx_ebill_contacts_stg%ROWTYPE,
                              p_cust_acct_id       IN     NUMBER,
                              p_cust_party_id      IN     NUMBER,
                              p_contact_id         OUT    NUMBER,
                              p_org_contact_id     OUT    NUMBER)
   IS
   -- +==========================================================================+
   -- | Name  : create_contact                                                   |
   -- | Description: This is to create the contact                               |
   -- |                                                                          |
   -- | Parameters : p_return_status         OUT    -> Return Status             |
   -- |              p_return_msg            OUT    -> Return Message            |
   -- |              p_contact_rec           IN     -> Contact record            |
   -- |              p_cust_acct_id          IN     -> Customer account id       |
   -- |              p_cust_party_id         IN     -> Party id                  |
   -- |              p_contact_id            OUT    -> Contact id                |
   -- |              p_org_contact_id        OUT    -> Org Contact id            |
   -- +==========================================================================+
   ln_person_id             NUMBER;
   ln_person_rel_id         NUMBER;
   ln_org_contact_id        NUMBER;
   ln_acct_role_id          NUMBER;
   ln_role_resp_id          NUMBER;
   ln_contact_point_id      NUMBER;
   lc_return_status         VARCHAR2 (1);
   lc_error_msg             VARCHAR2 (4000);
   e_process_exception      EXCEPTION;
   
   BEGIN
   
      ln_person_id         := NULL;
      ln_person_rel_id     := NULL;
      ln_org_contact_id    := NULL;
      ln_acct_role_id      := NULL;
      ln_role_resp_id      := NULL;
      ln_contact_point_id  := NULL;
      lc_return_status     := NULL;
      lc_error_msg         := NULL;
      p_contact_id         := NULL;
      -- Calling create person
      create_person (p_return_status   => lc_return_status,
                     p_return_msg      => lc_error_msg,
                     p_contact_rec     => p_contact_rec,
                     p_person_id       => ln_person_id);

      log_msg('Create person return status  :'||lc_return_status);
      log_msg('Create person return message :'||lc_error_msg);
      log_msg('Person Id is :'||ln_person_id);
      
      IF lc_return_status <> gc_success
      THEN
         RAISE e_process_exception;
      END IF;

      -- Calling create org contact
      create_org_contact (p_return_status    => lc_return_status,
                          p_return_msg       => lc_error_msg,
                          p_cust_acct_id     => p_cust_acct_id,
                          p_person_id        => ln_person_id,
                          p_cust_party_id    => p_cust_party_id,
                          p_person_rel_id    => ln_person_rel_id,
                          p_org_contact_id   => ln_org_contact_id);
        
      log_msg('create org contact return status  :'||lc_return_status);
      log_msg('create org contact return message :'||lc_error_msg);
      log_msg('Org Contact id is :'||ln_org_contact_id);
        
      IF lc_return_status <> gc_success
      THEN
         RAISE e_process_exception;
      END IF;
      
      -- Calling create contact role
      create_contact_role (p_return_status       => lc_return_status,
                           p_return_msg          => lc_error_msg,
                           p_cust_acct_id        => p_cust_acct_id,
                           p_person_rel_id       => ln_person_rel_id, 
                           p_cust_acct_role_id   => ln_acct_role_id);
                                 
      log_msg('create contact role return status  :'||lc_return_status);
      log_msg('create contact role return message :'||lc_error_msg);
      log_msg('Account role id is :'||ln_acct_role_id);
              
      IF lc_return_status <> gc_success
      THEN
         RAISE e_process_exception;
      END IF;

      -- Calling create contact role responsibility
      create_contact_role_resp ( p_return_status       => lc_return_status,
                                 p_return_msg          => lc_error_msg,
                                 p_cust_acct_role_id   => ln_acct_role_id,
                                 p_role_resp_id        => ln_role_resp_id);
                  
      log_msg('create contact role responsibilty return status  :'||lc_return_status);
      log_msg('create contact role responsibilty return message :'||lc_error_msg);
      log_msg('Role responsibility id is :'||ln_role_resp_id);
      
        
      IF lc_return_status <> gc_success
      THEN
         RAISE e_process_exception;
      END IF;

      -- Calling create email contact
      create_email_Contact ( p_return_status      => lc_return_status,
                             p_return_msg         => lc_error_msg,
                             p_contact_rec        => p_contact_rec,
                             p_person_rel_id      => ln_person_rel_id, --ln_person_id,--ln_org_contact_id,
                             p_contact_point_id   => ln_contact_point_id);

      log_msg('create email contact return status  :'||lc_return_status);
      log_msg('create email contact return message :'||lc_error_msg);
      log_msg('Contact point id is :'||ln_contact_point_id);
                  
      IF lc_return_status <> gc_success
      THEN
         RAISE e_process_exception;
      END IF;
      
      p_return_status  := gc_success;
      p_return_msg     := NULL;     
      p_contact_id     := ln_contact_point_id;
      p_org_contact_id := ln_org_contact_id;      

   EXCEPTION
      WHEN OTHERS
      THEN
         IF lc_error_msg is NULL
         THEN
            lc_error_msg := 'Unable to create email contact point'||'  '|| SQLERRM; 
         END IF;  
         p_return_msg      :=  lc_error_msg;
         p_return_status   := lc_return_status;  
         p_contact_id      := NULL; 
         p_org_contact_id  := NULL;
         log_msg (p_return_msg);
         log_exception ( p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.CREATE_CONTACT',
                         p_error_msg        => p_return_msg);
   END create_contact;


   PROCEDURE link_contact_to_ebill_docs (p_return_status        OUT    VARCHAR2,
                                         p_return_msg           OUT    VARCHAR2,
                                         p_cust_acct_id         IN     NUMBER,
                                         p_aops_customer_number IN     VARCHAR2,
                                         p_org_contact_id       IN     NUMBER,
                                         p_consignee_num        IN     VARCHAR2
                                         )
   IS
   -- +==========================================================================+
   -- | Name  : link_contact_to_ebill_docs                                       |
   -- | Description: This is to create the contact                               |
   -- |                                                                          |
   -- | Parameters : p_return_status         OUT    -> Return Status             |
   -- |              p_return_msg            OUT    -> Return Message            |
   -- |              p_cust_acct_id          IN     -> Customer account id       |
   -- |              p_aops_customer_number  IN     -> AOPS Customer Number      |
   -- |              p_org_contact_id        OUT    -> Org Contact id            |
   -- +==========================================================================+
   CURSOR cur_link_contact (p_cust_acct_id   IN NUMBER)
   IS
     SELECT n_ext_attr2,
            c_ext_attr3,
            c_ext_attr7,
            extension_id,
            cust_account_id                        
       FROM xx_cdh_cust_acct_ext_b cae
      WHERE cust_account_id = p_cust_acct_id 
        AND c_ext_attr3 = 'ePDF'
        AND TRUNC (SYSDATE) BETWEEN TRUNC(NVL (d_ext_attr1,SYSDATE - 1)) AND TRUNC(NVL (d_ext_attr2,SYSDATE + 1)) -- start date and end date
        AND attr_group_id =(SELECT attr_group_id
                             FROM ego_attr_groups_v eag
                            WHERE eag.attr_group_type ='XX_CDH_CUST_ACCOUNT'
                              AND eag.attr_group_name = 'BILLDOCS'
                              AND eag.application_id  =(SELECT application_id
                                                          FROM fnd_application
                                                         WHERE application_short_name ='AR'));
        
   CURSOR c_cust_sites (p_cust_acct_id   IN NUMBER,
                        p_consignee_num  IN VARCHAR2)
   IS 
      SELECT hcas.cust_acct_site_id
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_accounts hca,
             hz_parties hp,
             hz_party_sites hps
       WHERE hcas.cust_account_id   =   hca.cust_account_id
         AND hp.party_id            =   hca.party_id
         AND hp.party_id            =   hps.party_id
         AND hcas.party_site_id     =   hps.party_site_id
         AND hcas.status            =   'A'
         AND hca.cust_account_id    =   p_cust_acct_id
        -- AND SUBSTR (hps.orig_system_reference,8,INSTR (SUBSTR (hps.orig_system_reference, 8), '-') - 1) = p_consignee_num; -- Commented as per Defect # 1239
        --AND SUBSTR(hps.orig_system_reference,8,LENGTH(SUBSTR(hps.orig_system_reference,8))-4)= p_consignee_num;  -- Added as per Defect # 1239
		AND SUBSTR(hps.orig_system_reference,8,INSTR(hps.orig_system_reference,'-OMX')-8) = p_consignee_num; --Added as per Defect #1738
        
   CURSOR c_error_message ( p_aops_customer_number IN VARCHAR2)
   IS 
     SELECT error_message
       FROM xx_cdh_omx_bill_docs_stg
      WHERE aops_customer_number = p_aops_customer_number;
        
    

   ln_ebl_doc_contact_id   NUMBER;
   lb_record_exists        BOOLEAN := FALSE;
   lc_site_exists          VARCHAR2(2):= 'N';
   lc_error_msg            VARCHAR2(4000);
   lc_return_status        VARCHAR2(1);
   e_process_exception     EXCEPTION;
   ln_success_records      NUMBER;
   ln_failed_records       NUMBER;
   e_cursor_exception      EXCEPTION;
      
   BEGIN
      
      log_msg('Linking Org contact id :'||p_org_contact_id||' for billing document');
      ln_success_records  := 0;
      ln_failed_records   := 0;
      -- Linking bill contacts to bill documents
      
      FOR cur_link_contact_rec IN cur_link_contact (p_cust_acct_id)
      LOOP            
        lb_record_exists := TRUE;
        BEGIN
            lc_error_msg          := NULL;
            lc_return_status      := NULL;
            ln_ebl_doc_contact_id := NULL;
            log_msg('Processing the customer document id :'||cur_link_contact_rec.n_ext_attr2);
        
            IF (cur_link_contact_rec.c_ext_attr7 = 'Y' OR p_consignee_num IS NULL)-- Check whether the customer is Direct('Y') or Indirect('N')
            THEN                                                                  -- Changes done as per Defect Id 1279
              -- Get the ebl doc contact id
              log_msg('Get the doc contact id');
              SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
                INTO ln_ebl_doc_contact_id
                FROM DUAL;
              log_msg('doc contact id:'||ln_ebl_doc_contact_id);      
              log_msg('Inserting records for Direct Customer');
              INSERT INTO xx_cdh_ebl_contacts (ebl_doc_contact_id,
                                                    cust_doc_id,
                                                    org_contact_id,
                                                    cust_acct_site_id,
                                                    attribute1,
                                                    creation_date,
                                                    created_by,
                                                    last_update_date,
                                                    last_updated_by,
                                                    last_update_login,
                                                    request_id,
                                                    program_application_id,
                                                    program_id,
                                                    program_update_date)
                                             VALUES (ln_ebl_doc_contact_id,           
                                                     cur_link_contact_rec.n_ext_attr2,
                                                     p_org_contact_id,                    
                                                     NULL,                            
                                                     TO_CHAR(cur_link_contact_rec.cust_account_id), -- Customer Account Id        
                                                     gd_creation_date,                
                                                     gn_created_by,                   
                                                     gd_last_update_date,             
                                                     gn_last_updated_by,               
                                                     gn_last_update_login,           
                                                     gn_conc_request_id,                    
                                                     gn_conc_prog_appl_id,      
                                                     gn_conc_program_id,                    
                                                     gd_creation_date                                  
                                                    );
               lc_return_status  := gc_success; 
               lc_error_msg      := NULL;                                                                      

            ELSE
               FOR c_cust_sites_rec IN c_cust_sites (p_cust_acct_id,p_consignee_num)
               LOOP
                  lc_site_exists := 'Y';
                  BEGIN
                     -- Get the ebl doc contact id
                     log_msg('Get the doc contact id');
                     SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
                       INTO ln_ebl_doc_contact_id
                       FROM DUAL;
                       
                     log_msg('doc contact id:'||ln_ebl_doc_contact_id);
                     log_msg('Inserting records for Indirect Customer');
                     INSERT INTO xx_cdh_ebl_contacts (ebl_doc_contact_id,
                                                           cust_doc_id,
                                                           org_contact_id,
                                                           cust_acct_site_id,
                                                           attribute1,
                                                           creation_date,
                                                           created_by,
                                                           last_update_date,
                                                           last_updated_by,
                                                           last_update_login,
                                                           request_id,
                                                           program_application_id,
                                                           program_id,
                                                           program_update_date)
                                                    VALUES (ln_ebl_doc_contact_id,       
                                                            cur_link_contact_rec.n_ext_attr2, 
                                                            p_org_contact_id,                
                                                            c_cust_sites_rec.cust_acct_site_id, 
                                                            TO_CHAR (cur_link_contact_rec.cust_account_id),             
                                                            gd_creation_date,                
                                                            gn_created_by,                      
                                                            gd_last_update_date,          
                                                            gn_last_updated_by,           
                                                            gn_last_update_login,        
                                                            gn_conc_request_id,                
                                                            gn_conc_prog_appl_id,   
                                                            gn_conc_program_id,                
                                                            gd_creation_date                              
                                                           );
                     lc_return_status := gc_success;                                                          
                  EXCEPTION
                    WHEN OTHERS 
                    THEN                        
                       lc_return_status:= gc_failure; 
                       lc_error_msg   := 'Unable to link the Org contact :'|| p_org_contact_id ||' for customer account site id :'|| c_cust_sites_rec.cust_acct_site_id||' '||SQLERRM; 
                       ln_failed_records := ln_failed_records + 1;
                  END;
               END LOOP;
               
               IF lc_site_exists = 'N'
               THEN
                  lc_return_status := gc_failure;
                  lc_error_msg := 'Ebill contact is not linked to paydoc due to AOPS address reference does not exist';
                END IF;            
            END IF;
            
            IF lc_return_status = gc_success
            THEN
               log_msg('Updating the status to COMPLETE');
               FOR c_error_message_rec IN c_error_message (p_aops_customer_number)
               LOOP
                 IF NVL(c_error_message_rec.error_message,'XXXX') NOT LIKE '%Either Default Payterm or MBS DOC or Delivery method used to create the doc%'
                 THEN
            -- Update the status to COMPLETE in xx_cdh_cust_acct_ext_b table
                   UPDATE xx_cdh_cust_acct_ext_b 
                      SET c_ext_attr16 = 'COMPLETE' -- Status updating from 'IN_PROCESS' to 'COMPLETE'
                    WHERE cust_account_id = p_cust_acct_id  
                      AND n_ext_attr2 = cur_link_contact_rec.n_ext_attr2;
                    log_msg('Number of records Updated :'||SQL%ROWCOUNT); 
                   COMMIT;
                 END IF;
              END LOOP;                 
            END IF;
                    
        EXCEPTION
           WHEN OTHERS
           THEN
               IF lc_error_msg IS NULL
               THEN
                  lc_error_msg:='Unable to link the Org contact '||p_org_contact_id||' '||SQLERRM;
               END IF; 
               lc_return_status := gc_failure;
        END;
      END LOOP;
      
      IF NOT (lb_record_exists) 
      THEN    
         lc_error_msg    :='No ePDF document found. Unable to link the contact';      
         RAISE e_process_exception;  
      END IF;
        
      p_return_status := lc_return_status;
      p_return_msg    := lc_error_msg;
   
   EXCEPTION
      WHEN OTHERS
      THEN
          IF lc_error_msg IS NULL
          THEN
             lc_error_msg := 'unable to process'||' '||SQLERRM;
          END IF;
          log_msg(lc_error_msg);
          log_exception(p_error_location => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.LINK_CONTACT_TO_EBILL_DOCS',
                        p_error_msg      => lc_error_msg);
          p_return_status := gc_failure;
          p_return_msg    := lc_error_msg;
   END;


   PROCEDURE EXTRACT (x_retcode                   OUT NOCOPY    NUMBER,
                      x_errbuf                    OUT NOCOPY    VARCHAR2,
                      p_batch_id                  IN            NUMBER,
                      p_debug_flag                IN            VARCHAR2,
                      p_aops_customer_number      IN            VARCHAR2,
                      p_status                    IN            VARCHAR2)
   IS
  -- +======================================================================+
  -- | Name  : extract                                                      |
  -- | Description     : The extract is the main                            |
  -- |                   procedure that will extract all the records        |
  -- |                  from staging table and process one after another    |
  -- |                                                                      |
  -- | Parameters      : x_retcode               OUT                        |
  -- |                   x_errbuf                OUT                        |
  -- |                   p_debug_flag            IN -> Debug Flag           |
  -- |                   p_batch_id              IN -> Batch Number         |
  -- |                   p_aops_customer_number  IN -> aops customer number |
  -- |                   p_status                IN -> status               |
  -- +======================================================================+
  
   CURSOR cur_extract (p_aops_customer_number   IN VARCHAR2,
                       p_batch_id               IN NUMBER,
                       p_status                 IN VARCHAR2)
   IS
    SELECT *
      FROM xx_cdh_omx_ebill_contacts_stg
     WHERE 1 = 1 
       AND status = NVL(p_status,status)
       AND aops_customer_number = NVL(p_aops_customer_number,aops_customer_number)
       AND batch_id = NVL(p_batch_id,batch_id)
     ORDER BY batch_id;
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   lc_error_msg               VARCHAR2 (4000);
   lc_return_status           VARCHAR2 (1);
   ln_cust_acct_id            NUMBER;
   ln_cust_party_id           NUMBER;
   ln_contact_id              NUMBER;
   ln_org_contact_id          NUMBER;
   lc_email_id                VARCHAR2 (200);
   e_process_exception        EXCEPTION;
   ln_success_records         NUMBER;
   ln_failed_records          NUMBER;
   ln_total_records           NUMBER;
   e_cursor_exception         EXCEPTION;
     
   BEGIN
   
      fnd_file.put_line(fnd_file.log,'Input parameters .....:');
      fnd_file.put_line(fnd_file.log,'p_debug_flag: ' || p_debug_flag);
      fnd_file.put_line(fnd_file.log,'p_batch_id:' || p_batch_id);
      fnd_file.put_line(fnd_file.log,'p_aops_customer_number:' || p_aops_customer_number);
      fnd_file.put_line(fnd_file.log,'p_status:' || p_status);

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;
      
      ln_success_records :=0;
      ln_failed_records  :=0;
      ln_total_records   :=0;

      FOR cur_extract_rec IN cur_extract (p_aops_customer_number, p_batch_id,p_status)
      LOOP
         BEGIN
            ln_cust_acct_id          := NULL;
            ln_cust_party_id         := NULL;
            lc_error_msg             := NULL;
            ln_contact_id            := NULL;
            ln_org_contact_id        := NULL;
            lc_email_id              := NULL;
            lc_return_status         := NULL;
            log_msg ('  ');
            log_msg('Processing the record for AOPS Customer Number :'||cur_extract_rec.aops_customer_number);
            
            -- Check email_address exists or not in the staging table            
            IF cur_extract_rec.email_address IS NULL
            THEN
               lc_error_msg := 'No email address exists ';
               RAISE e_cursor_exception;
            END IF;
                        
            -- Derive Customer and Party
            log_msg('Deriving Customer Account Id and Party Id');
            BEGIN
               SELECT hca.cust_account_id, 
                      hca.party_id
                 INTO ln_cust_acct_id, 
                      ln_cust_party_id
                 FROM hz_cust_accounts hca
                WHERE hca.orig_system_reference =LPAD (TO_CHAR (cur_extract_rec.aops_customer_number),8,0)|| '-'|| '00001-A0';

               log_msg('Customer Account ID :' || ln_cust_acct_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_error_msg:= 'Customer Derivation Failed for AOPS Customer Number :'||cur_extract_rec.aops_customer_number;
                  RAISE e_cursor_exception;
            END;

            -- Calling check_contact procedure
            log_msg('Calling check_contact');            
            check_contact (p_return_status   => lc_return_status,
                           p_return_msg      => lc_error_msg,
                           p_contact_rec     => cur_extract_rec,
                           p_cust_acct_id    => ln_cust_acct_id,
                           p_cust_party_id   => ln_cust_party_id,
                           p_contact_id      => ln_contact_id,
                           p_org_contact_id  => ln_org_contact_id);
                           
            log_msg('Check contact return msg    :'||lc_error_msg);

           -- Calling Create Contact if given contact does not exist
            IF lc_return_status <> gc_success
            THEN  
               log_msg('Calling create contact');      
               create_contact (p_return_status   => lc_return_status,
                               p_return_msg      => lc_error_msg,
                               p_contact_rec     => cur_extract_rec,
                               p_cust_acct_id    => ln_cust_acct_id,
                               p_cust_party_id   => ln_cust_party_id,
                               p_contact_id      => ln_contact_id,
                               p_org_contact_id  => ln_org_contact_id);
                               
               log_msg('Create contact return status :'||lc_return_status);
               log_msg('Create contact return msg    :'||lc_error_msg);
            END IF;

            -- Create contact is failed then update the status to E
            IF lc_return_status <> gc_success
               THEN  
                  ROLLBACK;             
                  RAISE e_cursor_exception;  
              
            END IF;
               
            -- if check contact status or create contact status is success then link the contact to ebill doc
            IF lc_return_status = gc_success 
            THEN
               COMMIT;
               log_msg('Calling link contact to ebill documents procedure');
               link_contact_to_ebill_docs (p_return_status        => lc_return_status,
                                           p_return_msg           => lc_error_msg,
                                           p_cust_acct_id         => ln_cust_acct_id,
                                           p_aops_customer_number => cur_extract_rec.aops_customer_number,
                                           p_org_contact_id       => ln_org_contact_id,
                                           p_consignee_num        => cur_extract_rec.bill_to_consignee);
               
               log_msg('Link contact to ebill docs return status :'||lc_return_status);
               log_msg('Link contact to ebill docs return msg    :'||lc_error_msg);
               
            END IF;
                                           
            -- If link contact to ebill docs return status is faliure, then update the status to E in staging table with the appropriate error message
            IF lc_return_status <> gc_success
            THEN
                RAISE e_cursor_exception;
            END IF;
               
            -- Updating the status to C in the staging table
            log_msg('Calling update_status to update the status to C in the staging table');
            update_status( p_record_id     => cur_extract_rec.record_id,
                           p_status        => 'C',
                           p_error_message => lc_error_msg
                          );                                                      
         COMMIT;
               ln_success_records := ln_success_records + 1;
               
         EXCEPTION
            WHEN OTHERS
            THEN             
               IF lc_error_msg IS NULL
               THEN
                lc_error_msg := 'Unable to link the contact '||SQLERRM;
               END IF;
               fnd_file.put_line(fnd_file.log,lc_error_msg);
               log_exception ( p_error_location    =>  'XX_CDH_OMX_EBILL_CONTACTS_PKG.EXTRACT'
                              ,p_error_msg         =>  lc_error_msg);  
                              
               log_msg('Calling update_status to update the status to E in the staging table');
                     update_status( p_record_id     => cur_extract_rec.record_id,
                                    p_status        => 'E',
                                    p_error_message => lc_error_msg
                                  );
                COMMIT;                  
               ln_failed_records := ln_failed_records + 1;             
         END;
            ln_total_records := ln_total_records + 1;
      END LOOP;
      
      log_msg('  ');
      fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
      fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
      fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_total_records);
      
   EXCEPTION
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to process ' || SQLERRM;
         END IF;
         fnd_file.put_line(fnd_file.log,lc_error_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_EBILL_CONTACTS_PKG.EXTRACT',
                        p_error_msg        => lc_error_msg);
         x_retcode := 2;
         ROLLBACK;
   END EXTRACT;
END XX_CDH_OMX_EBILL_CONTACTS_PKG;
/
SHOW ERRORS;
