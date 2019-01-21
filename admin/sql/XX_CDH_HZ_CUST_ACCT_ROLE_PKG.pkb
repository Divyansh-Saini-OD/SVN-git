SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_HZ_CUST_ACCT_ROLE_PKG 
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_CDH_HZ_CUST_ACCT_ROLE_PKG                                         |
-- | Description: This package body is for linking  Contact, roles , Responsiblities      |
-- |                                                .                                     |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version     Date         Author               Remarks                                 |
-- |=======   ===========  ==================   ==========================================|
-- |DRAFT 1A  08-APR-2010  Mangala                Initial draft version                   |
-- +======================================================================================+
AS
-- +========================================================================================+
-- | Name             : CREATE_CUST_ACCOUNT_ROLE                                            |
-- | Description      : This procedure is for linking the Contact, Roles, Responsibilities  |
-- |                                                                                        |
-- |                                                                                        |
-- +========================================================================================+
procedure CREATE_CUST_ACCOUNT_ROLE(p_rel_party_id             IN  NUMBER,
                                   p_cust_account_id          IN  NUMBER,
                                   x_cust_account_role_id     OUT NUMBER,
                                   x_responsibility_id        OUT NUMBER,
                                   x_return_status            OUT VARCHAR2,
                                   x_msg_count                OUT NUMBER,
                                   x_msg_data                 OUT VARCHAR2
                                   )
IS
      l_role_responsibility_rec   HZ_CUST_ACCOUNT_ROLE_V2PUB.ROLE_RESPONSIBILITY_REC_TYPE;
      l_cust_account_role_rec     HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
      l_contact_point_rec HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
      l_edi_rec            HZ_CONTACT_POINT_V2PUB.edi_rec_type;
      l_email_rec          HZ_CONTACT_POINT_V2PUB.email_rec_type;
      l_phone_rec          HZ_CONTACT_POINT_V2PUB.phone_rec_type;
      l_telex_rec          HZ_CONTACT_POINT_V2PUB.telex_rec_type;
      l_web_rec            HZ_CONTACT_POINT_V2PUB.web_rec_type;
      ln_obj_ver_no        NUMBER := 1.0;

      CURSOR lcu_cont_point IS
      SELECT contact_point_id 
      FROM   hz_contact_points 
      WHERE  owner_table_id=p_rel_party_id 
      AND    owner_table_name='HZ_PARTIES';
BEGIN
      --Intializations of the Local variables

      l_CUST_ACCOUNT_ROLE_REC.party_id          := p_rel_party_id; 
      l_CUST_ACCOUNT_ROLE_REC.cust_account_id   := p_cust_account_id;
      l_CUST_ACCOUNT_ROLE_REC.role_type         := 'CONTACT';
      l_CUST_ACCOUNT_ROLE_REC.created_by_module := 'EBL';

      HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_CUST_ACCOUNT_ROLE(
                                                        p_init_msg_list         => 'T',                   
                                                        p_cust_account_role_rec => l_cust_account_role_rec,
                                                        x_cust_account_role_id  => x_cust_account_role_id,
                                                        x_return_status         => x_return_status,          
                                                        x_msg_count             => x_msg_count,           
                                                        x_msg_data              => x_msg_data); 
          
      IF (x_return_status ='E')
      THEN
            return;
      END IF;

      -- ROLE/ RESPONSIBILITY
      l_role_responsibility_rec.cust_account_role_id := x_CUST_ACCOUNT_ROLE_ID;
      l_role_responsibility_rec.responsibility_type  := 'BILLING';
      l_role_responsibility_rec.created_by_module := 'EBL';
      HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_ROLE_RESPONSIBILITY(
                             p_init_msg_list           => 'T',
                             p_role_responsibility_rec => l_role_responsibility_rec,
                             x_responsibility_id       => x_responsibility_id,
                             x_return_status           => x_return_status,
                             x_msg_count               => x_msg_count,
                             x_msg_data                => x_msg_data); 

      IF (x_return_status ='E')
      THEN
            return;
      END IF;
      
    FOR lcr_cont_point in lcu_cont_point
    LOOP

        l_contact_point_rec.contact_point_id := lcr_cont_point.contact_point_id;
        l_contact_point_rec.contact_point_purpose := 'BILLING';
        HZ_CONTACT_POINT_V2PUB.update_contact_point(
                p_init_msg_list         => 'T',
                p_contact_point_rec    => l_contact_point_rec,
                p_edi_rec               => l_edi_rec,
                p_email_rec             => l_email_rec,
                p_phone_rec             => l_phone_rec,
                p_telex_rec             => l_telex_rec,
                p_web_rec               => l_web_rec,
                p_object_version_number => ln_obj_ver_no,
                x_return_status         => x_return_status,
                x_msg_count             => x_msg_count,
                x_msg_data              => x_msg_data);
    END LOOP;

    COMMIT;

END CREATE_CUST_ACCOUNT_ROLE;



-- +========================================================================================+
-- | Name             : CREATE_CUST_ACCOUNT_ROLE                                            |
-- | Description      : This procedure is for linking the Contact, Roles, Responsibilities  |
-- |                                                                                        |
-- |                                                                                        |
-- +========================================================================================+
PROCEDURE CREATE_CUST_ACCOUNT_ROLE(p_rel_party_id             IN  NUMBER,
                                   p_cust_account_id          IN  NUMBER,
                                   x_return_status            OUT VARCHAR2
                                   )
IS
   l_cust_account_role_id NUMBER;
   l_msg_count            NUMBER;
   l_msg_data             VARCHAR2(1000);
   l_responsibility_id    NUMBER;
BEGIN

   CREATE_CUST_ACCOUNT_ROLE(p_rel_party_id             => p_rel_party_id  
                          , p_cust_account_id         => p_cust_account_id          
                          , x_cust_account_role_id    => l_cust_account_role_id
                          , x_responsibility_id       => l_responsibility_id
                          , x_return_status           => x_return_status
                          , x_msg_count               => l_msg_count
                          , x_msg_data                => l_msg_data
                            );

END CREATE_CUST_ACCOUNT_ROLE;


END XX_CDH_HZ_CUST_ACCT_ROLE_PKG;


/
SHOW ERRORS;
