SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE

PROMPT CREATING PACKAGE XX_CDH_EBILL_CONVERSION_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

CREATE OR REPLACE
PACKAGE BODY XX_CDH_EBL_DEL_DUP_CONTACTS

As

 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                       WIPRO Technologies                                 |
 -- +==========================================================================+
 -- | Name        : XX_CDH_EBL_DEL_DUP_CONTACTS                                |
 -- |                                                                          |
 -- | Description :This package will delete the duplicate contacts that get    |
 -- |              inserted into the oracle contact table due to the           |
 -- |              conversion program.                                         |
 -- |                                                                          |
 -- |Change Record:                                                            |
 -- |===============                                                           |
 -- |Version   Date            Author         Remarks                          |
 -- |=======   ==========    =============    =================================|
 -- |1.0       25-AUG-10     Param            Initial version for defect # 7666|
 -- |2.0       22-OCT-15     Manikant Kasu    Removed schema alias as part     |
 -- |                                         of GSCC R12.2.2 Retrofit         |
 -- +==========================================================================+

   PROCEDURE XX_EBL_DEL_DUP_CONTACTS(x_error_buff    OUT      VARCHAR2
                                    ,x_ret_code      OUT      NUMBER
                                    ,p_summary_id    IN       NUMBER
                                    ,p_commit        IN       VARCHAR2
                                     )
   IS

 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                       WIPRO Technologies                                 |
 -- +==========================================================================+
 -- | Name        : XX_EBL_DEL_DUP_CONTACTS                                    |
 -- |                                                                          |
 -- | Description :This package will delete the duplicate contacts that get    |
 -- |              inserted into the oracle contact table due to the           |
 -- |              conversion program. This will map the ebill doc id of the   |
 -- |              duplicate contacts to the already excisting contact.        |
 -- |                                                                          |
 -- |                                                                          |
 -- |Change Record:                                                            |
 -- |===============                                                           |
 -- |Version   Date            Author         Remarks                          |
 -- |=======   ==========    =============    =================================|
 -- |1.0       25-AUG-10     Param            Initial version for defect # 7666|
 -- +==========================================================================+

      lc_prv_email                    VARCHAR2(1000);
      lc_curr_email                   VARCHAR2(1000);
      lc_error_message                VARCHAR2(4000);
      lc_return_status                VARCHAR2(4000);
      lc_msg_data                     VARCHAR2(1000);
      ln_msg_count                    NUMBER;
      ln_rel_object_version_number    NUMBER;
      ln_party_object_version_number  NUMBER;
      ln_cust_object_version_number   NUMBER;
      ln_valid_contact                NUMBER;
      ln_count                        NUMBER;
      ln_count1                       NUMBER;
      ln_valid_org_cont_id            NUMBER;
      ln_obj_ver_number               NUMBER;
      lc_invalid_contact              NUMBER; -- Defect# 7666
      lr_rel_rec                      hz_relationship_v2pub.relationship_rec_type;
      lr_contact_point_rec            hz_contact_point_v2pub.contact_point_rec_type;
      lr_cust_account_role_rec        hz_cust_account_role_v2pub.cust_account_role_rec_type;
      lr_edi_rec                      hz_contact_point_v2pub.edi_rec_type;
      lr_email_rec                    hz_contact_point_v2pub.email_rec_type;
      lr_phone_rec                    hz_contact_point_v2pub.phone_rec_type;
      lr_telex_rec                    hz_contact_point_v2pub.telex_rec_type;
      lr_web_rec                      hz_contact_point_v2pub.web_rec_type;

      --Cursor to get Account for the given Summary ID.
      CURSOR lcu_get_acc_id(p_summary_id IN NUMBER)
      IS
      SELECT XOHS.eft_printing_program_id cust_account_id
           , XOHS.email_address           email_address
           , XOHS.party_id                org_contact_id -- Defect# 7666
        FROM xxod_hz_summary XOHS
       WHERE XOHS.summary_id              = p_summary_id
         AND XOHS.insert_update_flag      = 2
       GROUP BY XOHS.eft_printing_program_id
               ,XOHS.email_address
               ,XOHS.party_id
      HAVING count(1) > 1;

      --Cursor to get all the email_address for the Cust Account ID that is passed.
      CURSOR lcu_get_mail_address(p_cust_acct_id IN NUMBER,p_email_address IN VARCHAR2)
      IS
       SELECT HCP.email_address         email_address
             , HCP.contact_point_id      contact_point_id
             , HR.relationship_id        relationship_id
             , HOC.org_contact_id        org_contact_id
             , HOC.contact_number        contact_number
             , HCA.account_number        account_number
             , HCAR.cust_account_role_id cust_account_role_id
          FROM hz_parties HP
             , hz_cust_account_roles HCAR
             , hz_cust_accounts HCA
             , HZ_RELATIONSHIPS HR
             , hz_contact_points HCP
             , hz_org_contacts HOC
         where
               HCAR.cust_account_id            = HCA.cust_account_id
           AND HR.object_id                = HCA.party_id
           AND HR.relationship_code        = 'CONTACT_OF'
           and  hr.relationship_type       = 'CONTACT'
           and hr.directional_flag         = 'F'
           and HCAR.PARTY_ID               = HR.PARTY_ID
	         AND HR.subject_id               = HP.party_id
           AND HCP.owner_table_name        = 'HZ_PARTIES'
           AND HCP.owner_table_id          = HR.party_id
           AND HOC.party_relationship_id   = HR.relationship_id
           AND HOC.status                  = 'A' -- Defect# 7666
           AND HCAR.status                 = 'A' -- Defect# 7666
           AND HP.status                   = 'A'
           AND HR.status                   = 'A'
           AND HCP.orig_system_reference   LIKE 'EEBL_CONV%'
           AND HCA.cust_account_id         = p_cust_acct_id
           AND HCP.email_address           = p_email_address;

   BEGIN

      lc_error_message := ' Account Number '||'|'||' E-mail ID '||'|'||' Contact Number '||'|'||' Relationship ID '||'|'||' Org Contact ID '||'|'||' Contact Point ID '||'|'||' Status ';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_message);

      lc_error_message :=' Opening Loop for Fetching Cust Acc ID.';

      --Loop through each cust_account imported wrongly.
      FOR lrec_get_acc_id IN lcu_get_acc_id(p_summary_id)
      LOOP

         FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------------------------------------------------');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer Account ID : '||lrec_get_acc_id.cust_account_id);

         lc_prv_email := '-1-1';
         ln_valid_org_cont_id := Null;
         lc_error_message :='Opening Loop for Fetching E-Mail address for cust acc ID.';

         -- Loop to pass through all email for the cust document id.
         FOR lcr_get_mail_address IN lcu_get_mail_address(
                                        lrec_get_acc_id.cust_account_id
                                       ,lrec_get_acc_id.email_address)
         LOOP

            lc_curr_email := lcr_get_mail_address.email_address;
            IF (lc_prv_email = lc_curr_email) THEN -- Checks whether the previous and the current mail ID are the same.

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_get_mail_address.account_number||'|'||lcr_get_mail_address.email_address||'|'||lcr_get_mail_address.contact_number||'|'||lcr_get_mail_address.relationship_id||'|'||lcr_get_mail_address.org_contact_id||'|'||lcr_get_mail_address.contact_point_id||'|'||' Will be inactivated');
               FND_FILE.PUT_LINE(FND_FILE.LOG,' Both previous and current mail ID are same for Cust Account ID : ' || lrec_get_acc_id.cust_account_id || ' Relationship ID :' || lcr_get_mail_address.relationship_id );

               lc_error_message := 'Calling Get Relationship API.';

               -- API call to get the relationship record type for the relationship ID that is passed.
               hz_relationship_v2pub.get_relationship_rec ( p_init_msg_list   =>  FND_API.G_TRUE
                                                          , p_relationship_id =>  lcr_get_mail_address.relationship_id
                                                          , x_rel_rec         =>  lr_rel_rec
                                                          , x_return_status   =>  lc_return_status
                                                          , x_msg_count       =>  ln_msg_count
                                                          , x_msg_data        =>  lc_msg_data);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Status of the Relationship ID before update is '||lr_rel_rec.status);
               -- FND_FILE.PUT_LINE (FND_FILE.LOG,'API Return Status:  '||lc_return_status||' No of messages:  '||ln_msg_count||' Error Descriptions :  '||lc_msg_data);

               IF (lc_return_status != 'S') THEN
                  FOR k IN 1 .. ln_msg_count
                  LOOP
                     lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                  END LOOP;
               END IF;

               -- API call to get the Contact Point record type for the Contact Point ID that is passed.
               hz_contact_point_v2pub.get_contact_point_rec ( p_init_msg_list     =>  FND_API.G_TRUE
                                                            , p_contact_point_id  =>  lcr_get_mail_address.contact_point_id
                                                            , x_contact_point_rec =>  lr_contact_point_rec
                                                            , x_edi_rec           =>  lr_edi_rec
                                                            , x_email_rec         =>  lr_email_rec
                                                            , x_phone_rec         =>  lr_phone_rec
                                                            , x_telex_rec         =>  lr_telex_rec
                                                            , x_web_rec           =>  lr_web_rec
                                                            , x_return_status     =>  lc_return_status
                                                            , x_msg_count         =>  ln_msg_count
                                                            , x_msg_data          =>  lc_msg_data );

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Status of the Contact point ID before update is '||lr_contact_point_rec.status||' With Primary Flag as :'||lr_contact_point_rec.primary_flag);
               -- FND_FILE.PUT_LINE (FND_FILE.LOG,'API Return Status:  '||lc_return_status||' No of messages:  '||ln_msg_count||' Error Descriptions :  '||lc_msg_data);

               IF (lc_return_status != 'S') THEN
                  FOR k IN 1 .. ln_msg_count
                  LOOP
                     lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                  END LOOP;
               END IF;

               lr_rel_rec.status := 'I';                          -- Assigning the status to inactivate the relationship.
               lr_rel_rec.end_date := lr_rel_rec.end_date -1;     -- Added for avoiding Overlapping dates.
               lr_contact_point_rec.status := 'I';                -- Assigning the status to inactivate the contact point.

               IF (p_commit = 'Y') THEN --Inactivates the relation only when the commit parameter is 'Y'.
                  -- Gets the object version number for the realtionship ID that is passed.
                  SELECT HR.object_version_number
                     INTO ln_rel_object_version_number
                     FROM hz_relationships HR
                     WHERE HR.relationship_id  =  lr_rel_rec.relationship_id
                     AND HR.directional_flag = 'F';

                  -- Gets the object version number for the party ID that is passed.
                  SELECT HP.object_version_number
                     INTO ln_party_object_version_number
                     FROM hz_parties HP
                     WHERE HP.party_id = lr_rel_rec.party_rec.party_id;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Inactivating the contact for the Relationship ID '||lr_rel_rec.relationship_id ||' of the Cust Account ID: '|| lrec_get_acc_id.cust_account_id);

                  lc_error_message := 'Calling Update Relationship API.';

                  -- API call to inactivate the relationship ID.
                  hz_relationship_v2pub.update_relationship ( p_init_msg_list               => 'T'
                                                            , p_relationship_rec            => lr_rel_rec
                                                            , p_object_version_number       => ln_rel_object_version_number
                                                            , p_party_object_version_number => ln_party_object_version_number
                                                            , x_return_status               => lc_return_status
                                                            , x_msg_count                   => ln_msg_count
                                                            , x_msg_data                    => lc_msg_data);

                  IF (lc_return_status != 'S') THEN
                  FOR k IN 1 .. ln_msg_count
                  LOOP
                     lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                  END LOOP;
               END IF;

                  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Details for update_relationship API');
                  FND_FILE.PUT_LINE (FND_FILE.LOG,' API Return Status is '||lc_return_status||' for the Relationship ID '||lr_rel_rec.relationship_id ||' of Org Contact ID :' ||lcr_get_mail_address.org_contact_id||' and Cust Acct ID: '||lrec_get_acc_id.cust_account_id|| CHR(13)
                                                ||' No of messages:  '||ln_msg_count||' Error Descriptions : '||lc_msg_data);

                  -- Gets the object version number for the Contact Point ID that is passed
                  SELECT  object_version_number
                     INTO    ln_obj_ver_number
                     FROM    hz_contact_points
                     WHERE   contact_point_id = lcr_get_mail_address.contact_point_id;

                  --API call To Update Contact point
                  hz_contact_point_v2pub.update_contact_point (p_init_msg_list                => FND_API.G_FALSE
                                                             , p_contact_point_rec            => lr_contact_point_rec
                                                             , p_object_version_number        => ln_obj_ver_number
                                                             , x_return_status                => lc_return_status
                                                             , x_msg_count                    => ln_msg_count
                                                             , x_msg_data                     => lc_msg_data
                                                             );

               IF (lc_return_status != 'S') THEN
                  FOR k IN 1 .. ln_msg_count
                  LOOP
                     lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                  END LOOP;
               END IF;

                  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Details for update_contact_point API');
                  FND_FILE.PUT_LINE (FND_FILE.LOG,' API Return Status is '||lc_return_status||' for the Contact Point ID '||lcr_get_mail_address.contact_point_id||' of Org Contact ID :' ||lcr_get_mail_address.org_contact_id||' and Cust Acct ID: '||lrec_get_acc_id.cust_account_id|| CHR(13)
                                                ||' No of messages:  '||ln_msg_count||' Error Descriptions : '||lc_msg_data);

                  --API call To Get cust account role
                  hz_cust_account_role_v2pub.get_cust_account_role_rec (p_init_msg_list          => FND_API.G_FALSE
                                                                      , p_cust_account_role_id   => lcr_get_mail_address.cust_account_role_id
                                                                      , x_cust_account_role_rec  => lr_cust_account_role_rec
                                                                      , x_return_status          => lc_return_status
                                                                      , x_msg_count              => ln_msg_count
                                                                      , x_msg_data               => lc_msg_data
                                                                      );

                  IF (lc_return_status != 'S') THEN
                  FOR k IN 1 .. ln_msg_count
                  LOOP
                     lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                  END LOOP;
               END IF;

                  -- Gets the object version number for the Org Contact ID that is passed
                  SELECT object_version_number
                     INTO ln_cust_object_version_number
                     FROM hz_cust_account_roles
                     WHERE cust_account_role_id = lcr_get_mail_address.cust_account_role_id;

                  lr_cust_account_role_rec.status :='I'; -- Assigning the status to inactivate the Org contact

                  --API call To Update cust account role
                  hz_cust_account_role_v2pub.update_cust_account_role  (p_init_msg_list          => FND_API.G_FALSE
                                                                      , p_cust_account_role_rec  => lr_cust_account_role_rec
                                                                      , p_object_version_number  => ln_cust_object_version_number
                                                                      , x_return_status          => lc_return_status
                                                                      , x_msg_count              => ln_msg_count
                                                                      , x_msg_data               => lc_msg_data
                                                                      );

                  IF( lc_return_status != 'S') THEN
                     FOR k IN 1 .. ln_msg_count
                     LOOP
                        lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                        FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||lc_msg_data);
                     END LOOP;
                  END IF;

               END IF;       --(p_commit = 'Y')


               -- Below block added for Defect# 7666
               BEGIN

                  FND_FILE.PUT_LINE (FND_FILE.LOG,
                                    ' Updating xx_cdh_ebl_contacts table for org contact id: '
                                    ||lcr_get_mail_address.org_contact_id||
                                    ' for the Cust Account id :'||lrec_get_acc_id.cust_account_id);

                  -- If already not exist then update
                  lc_error_message := '1st EBL_CONTACT update statement. AccountId and Org_Contact_Id :'
                                      || lrec_get_acc_id.cust_account_id || '-'
                                      || lcr_get_mail_address.org_contact_id;

                  UPDATE xx_cdh_ebl_contacts
                     SET org_contact_id = ln_valid_org_cont_id
                   WHERE org_contact_id = lcr_get_mail_address.org_contact_id
                     AND attribute1     = to_char(lrec_get_acc_id.cust_account_id);

                  IF (p_commit = 'Y') THEN
                     COMMIT;
                  ELSE
                     ROLLBACK;
                  END IF;

               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error - Unique Constraint error due to the presence of duplicate row in xx_cdh_ebl_contacts table for the following details '
                               || lc_error_message);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                 lcr_get_mail_address.account_number||'|'||lcr_get_mail_address.email_address||'|'
                               ||lcr_get_mail_address.contact_number||'|'||lcr_get_mail_address.relationship_id||'|'
                               ||lcr_get_mail_address.org_contact_id||'|'||lcr_get_mail_address.contact_point_id||'|'
                               ||'Failed');

                  WHEN OTHERS THEN
                     lc_error_message := 'Error - Unhandled exception : '||lc_error_message
                                          ||'  SQLCODE - '||SQLCODE||' SQLERRM - '||SQLERRM;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                  lcr_get_mail_address.account_number||'|'||lcr_get_mail_address.email_address||'|'
                                ||lcr_get_mail_address.contact_number||'|'||lcr_get_mail_address.relationship_id||'|'
                                ||lcr_get_mail_address.org_contact_id||'|'||lcr_get_mail_address.contact_point_id||'|'
                                ||'Failed');

               END;

            ELSE                -- (lc_prv_email = lc_curr_email)
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lcr_get_mail_address.account_number||'|'||lcr_get_mail_address.email_address||'|'||lcr_get_mail_address.contact_number||'|'||lcr_get_mail_address.relationship_id||'|'||lcr_get_mail_address.org_contact_id||'|'||lcr_get_mail_address.contact_point_id||'|'||' Will be active');
               ln_valid_org_cont_id := lcr_get_mail_address.org_contact_id;          -- Assigns a valid org contact id.

            END IF;             --(lc_prv_email = lc_curr_email)
            lc_prv_email := lcr_get_mail_address.email_address;

         END LOOP;              -- lcr_get_mail_address

         -- Below block added for Defect# 7666
         BEGIN

            IF lrec_get_acc_id.org_contact_id <> ln_valid_org_cont_id THEN

               SELECT count(1)
               INTO   lc_invalid_contact
               FROM   xx_cdh_ebl_contacts
               WHERE  org_contact_id = lrec_get_acc_id.org_contact_id
               AND    attribute1 = to_char(lrec_get_acc_id.cust_account_id);

               IF lc_invalid_contact > 0 THEN

                  lc_error_message := '2st EBL_CONTACT update statement. AccountId and Org_Contact_Id :'
                                      || lrec_get_acc_id.cust_account_id || '-' || lrec_get_acc_id.org_contact_id;

                  UPDATE xx_cdh_ebl_contacts
                  SET    org_contact_id = ln_valid_org_cont_id
                  WHERE  org_contact_id = lrec_get_acc_id.org_contact_id
                  AND    attribute1 = to_char(lrec_get_acc_id.cust_account_id);

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Wrong Org_Contact - Account and Contact: '
                                   ||lrec_get_acc_id.cust_account_id || ' - ' || lrec_get_acc_id.org_contact_id);
               END IF;

            END IF;

            IF (p_commit = 'Y') THEN -- Updates only when the commit parameter is 'Y'
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;

         EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
               FND_FILE.PUT_LINE(FND_FILE.log,
                            'Error - Unique Constraint error due to the presence of duplicate row in xx_cdh_ebl_contacts table for the following details '
                         || lc_error_message);

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            'Null'||'|'||lrec_get_acc_id.email_address||'|'||'Null'||'|'||'Null'||'|'||'Null'||'|'
                          ||'Null'||'|'||'Failed');

            WHEN OTHERS THEN
               lc_error_message := 'Error - Unhandled exception : '||lc_error_message
                                   ||'  SQLCODE - '||SQLCODE||' SQLERRM - '||SQLERRM;
               FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            'Null'||'|'||lrec_get_acc_id.email_address||'|'||'Null'||'|'||'Null'||'|'||'Null'||'|'
                          ||'Null'||'|'||'Failed');

         END; -- BEGIN

      END LOOP;                 -- lrec_get_acc_id

   EXCEPTION
      WHEN OTHERS THEN
         lc_error_message := 'Error - Unhandled exception : '||lc_error_message
                           ||'  SQLCODE - '||SQLCODE||' SQLERRM - '||SQLERRM;
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);

   END XX_EBL_DEL_DUP_CONTACTS;

END XX_CDH_EBL_DEL_DUP_CONTACTS;
/
SHOW ERRORS;