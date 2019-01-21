CREATE OR REPLACE PACKAGE BODY XX_SFA_CONTACT_CREATE_PKG AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_SFA_CONTACT_CREATE_PKG                                                      |
-- | Description      : Package Body containing procedure to create org contact              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date         Author              Remarks                                      |
-- |=======    ==========   =============       ========================                     |
-- |DRAFT 1A   21-DEC-2009  Anirban Chaudhuri   Initial draft version                        |
-- +=========================================================================================+ 

-- | Subversion Info:

-- |

-- |   $HeadURL$

-- |       $Rev$

-- |      $Date$

-- |

-- Declare any global variable(s)

/*PROCEDURE insert_log_mesg (p_mesg IN VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
 insert into anirban_table values (p_mesg);
 commit;
END;*/

-- +===================================================================+
-- | Name  : Create_Org_APContact                                      |
-- | Description:       This Procedure will be used to create a person,|
-- |                    setup this person as a org contact, create     |
-- |                    contact points and lastly create               |
-- |                    an association of this newly contact to the    |
-- |                    party site of the organization passed as param.|
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Create_Org_APContact(
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    x_org_contact_id             OUT NUMBER,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2
)
IS

   --Declare all the Local variables to be used in procedure

   x_return_status_org_contact VARCHAR2(2000);
   x_msg_count_create_org_contact NUMBER;
   x_msg_data_create_org_contact VARCHAR2(2000);

   x_return_status_create_person VARCHAR2(2000);
   x_msg_count_create_person NUMBER;
   x_msg_data_create_person VARCHAR2(2000);

   x_return_status_contact_point VARCHAR2(2000);
   x_msg_count_contact_point NUMBER;
   x_msg_data_contact_point VARCHAR2(2000);

   p_person_rec HZ_PARTY_V2PUB.PERSON_REC_TYPE;
   x_party_id NUMBER;
   x_party_number VARCHAR2(2000);
   x_profile_id NUMBER;

   p_org_contact_rec HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
   x_org_contact_id_APcontact NUMBER;
   x_party_rel_id NUMBER;
   x_party_id_create_org_contact NUMBER;
   x_party_number_org_contact VARCHAR2(2000);

   l_extension_id NUMBER;
   l_attr_group_id NUMBER;
   x_rowid VARCHAR2(2000);

   l_edi_rec_nab    HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   l_phone_rec_nab  HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   l_telex_rec_nab  HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE; 
   l_web_rec_nab    HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   l_return_status_nab VARCHAR2(2000);
   l_msg_count_nab  NUMBER;
   l_msg_data_nab VARCHAR2(2000);

   p_contact_point_rec              HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_email    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_fax      HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_edi_rec              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   p_email_rec            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_email_rec_dummy      HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_phone_rec            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_phone_rec_dummy      HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_fax_rec              HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_telex_rec            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
   p_web_rec              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   x_contact_point_id     NUMBER;


BEGIN

 SAVEPOINT Create_Org_APContact;

 FND_MSG_PUB.initialize;
 x_return_status := 'S';
-------------------------------------------------------------------------------------------------------------------

 p_person_rec.person_pre_name_adjunct := p_person_pre_name_adjunct;
 p_person_rec.created_by_module := 'HZ_CPUI';
 p_person_rec.person_first_name := p_person_first_name;
 p_person_rec.person_middle_name := p_person_middle_name;
 p_person_rec.person_last_name := p_person_last_name;

 hz_party_v2pub.create_person (
 'T',
 p_person_rec,
 x_party_id,
 x_party_number,
 x_profile_id,
 x_return_status_create_person,
 x_msg_count_create_person,
 x_msg_data_create_person
 );

 IF x_return_status_create_person <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_create_person_exp;
 END IF;

-------------------------------------------------------------------------------------------------------------------

 p_org_contact_rec.created_by_module := 'HZ_CPUI';
 p_org_contact_rec.party_rel_rec.subject_id := x_party_id;
 p_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
 p_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
 p_org_contact_rec.party_rel_rec.object_id := p_party_id;
 p_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
 p_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
 p_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
 p_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
 p_org_contact_rec.party_rel_rec.start_date := SYSDATE;

 hz_party_contact_v2pub.create_org_contact(
 'T',
 p_org_contact_rec,
 x_org_contact_id_APcontact,
 x_party_rel_id,
 x_party_id_create_org_contact,
 x_party_number_org_contact,
 x_return_status_org_contact,
 x_msg_count_create_org_contact,
 x_msg_data_create_org_contact);

 IF x_return_status_org_contact <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_create_org_exp;
 END IF;

 x_org_contact_id := x_org_contact_id_APcontact;

-------------------------------------------------------------------------------------------------------------------

 p_contact_point_rec.contact_point_type := 'PHONE';
 p_contact_point_rec.owner_table_name := 'HZ_PARTIES';
 p_contact_point_rec.owner_table_id := x_party_id_create_org_contact;
 p_contact_point_rec.primary_flag := 'Y';
 p_contact_point_rec.contact_point_purpose := 'BUSINESS';
 p_contact_point_rec.created_by_module := 'HZ_CPUI';

 p_phone_rec.phone_area_code := p_phone_area_code;
 p_phone_rec.phone_country_code := p_phone_country_code;
 p_phone_rec.phone_number := p_phone_number;
 p_phone_rec.phone_extension := p_phone_extension;
 p_phone_rec.phone_line_type := 'GEN';

 hz_contact_point_v2pub.create_contact_point(
 'T',
 p_contact_point_rec,
 p_edi_rec,
 p_email_rec,
 p_phone_rec,
 p_telex_rec,
 p_web_rec,
 x_contact_point_id,
 x_return_status_contact_point,
 x_msg_count_contact_point,
 x_msg_data_contact_point);
 
 IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_contact_points_exp;
 END IF;

 x_return_status_contact_point := 'S';

 if (trim(p_email_address) IS NOT NULL) then

  p_contact_point_rec_for_email.contact_point_type := 'EMAIL';
  p_contact_point_rec_for_email.owner_table_name := 'HZ_PARTIES';
  p_contact_point_rec_for_email.owner_table_id := x_party_id_create_org_contact;
  p_contact_point_rec_for_email.primary_flag := 'Y';
  p_contact_point_rec_for_email.contact_point_purpose := 'BUSINESS';
  p_contact_point_rec_for_email.created_by_module := 'HZ_CPUI';

  p_email_rec.email_format := 'MAILHTML';
  p_email_rec.email_address := p_email_address;

  XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

  IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
    FND_MSG_PUB.ADD;
    RAISE invalid_email_add_exp;
  END IF;

  hz_contact_point_v2pub.create_contact_point(
  'T',
  p_contact_point_rec_for_email,
  p_edi_rec,
  p_email_rec,
  p_phone_rec_dummy,
  p_telex_rec,
  p_web_rec,
  x_contact_point_id,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);

  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_contact_points_exp;
  END IF;

 end if;

 x_return_status_contact_point := 'S';

 --insert_log_mesg('Anirban just before entering fax create');

 if ((trim(p_fax_area_code) is not null) and (trim(p_fax_number) is not null)) then

  --insert_log_mesg('Anirban inside fax create');

  p_contact_point_rec_for_fax.contact_point_type := 'PHONE';
  p_contact_point_rec_for_fax.owner_table_name := 'HZ_PARTIES';
  p_contact_point_rec_for_fax.owner_table_id := x_party_id_create_org_contact;
  p_contact_point_rec_for_fax.primary_flag := 'N';
  p_contact_point_rec_for_fax.contact_point_purpose := 'BUSINESS';
  p_contact_point_rec_for_fax.created_by_module := 'HZ_CPUI';

  p_fax_rec.phone_area_code := p_fax_area_code;
  p_fax_rec.phone_country_code := p_fax_country_code;
  p_fax_rec.phone_number := p_fax_number;
  p_fax_rec.phone_line_type := 'FAX';

  hz_contact_point_v2pub.create_contact_point(
  'T',
  p_contact_point_rec_for_fax,
  p_edi_rec,
  p_email_rec_dummy,
  p_fax_rec,
  p_telex_rec,
  p_web_rec,
  x_contact_point_id,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);

  --insert_log_mesg('Anirban inside fax create, value of x_return_status_contact_point is: '||x_return_status_contact_point);

  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_contact_points_exp;
  END IF;

 end if;

-------------------------------------------------------------------------------------------------------------------

 SELECT EGO_EXTFWK_S.NEXTVAL INTO l_extension_id FROM DUAL;

 select attr_group_id INTO l_attr_group_id from ego_attr_groups_v egoag where egoag.attr_group_type = 'HZ_PARTY_SITES_GROUP' AND egoag.attr_group_name = 'SITE_CONTACTS';


 HZ_PARTY_SITES_EXT_PKG.INSERT_ROW(
  X_ROWID => x_rowid,
  X_EXTENSION_ID => l_extension_id,
  X_PARTY_SITE_ID => p_party_site_id,
  X_ATTR_GROUP_ID => l_attr_group_id,
  X_C_EXT_ATTR1 => 'A',
  X_C_EXT_ATTR2 => null,
  X_C_EXT_ATTR3 => null,
  X_C_EXT_ATTR4 => null,
  X_C_EXT_ATTR5 => null,
  X_C_EXT_ATTR6 => null,
  X_C_EXT_ATTR7 => null,
  X_C_EXT_ATTR8 => null,
  X_C_EXT_ATTR9 => null,
  X_C_EXT_ATTR10 => null,
  X_C_EXT_ATTR11 => null,
  X_C_EXT_ATTR12 => null,
  X_C_EXT_ATTR13 => null,
  X_C_EXT_ATTR14 => null,
  X_C_EXT_ATTR15 => null,
  X_C_EXT_ATTR16 => null,
  X_C_EXT_ATTR17 => null,
  X_C_EXT_ATTR18 => null,
  X_C_EXT_ATTR19 => null,
  X_C_EXT_ATTR20 => null,
  X_N_EXT_ATTR1 => x_party_rel_id,
  X_N_EXT_ATTR2 => null,
  X_N_EXT_ATTR3 => null,
  X_N_EXT_ATTR4 => null,
  X_N_EXT_ATTR5 => null,
  X_N_EXT_ATTR6 => null,
  X_N_EXT_ATTR7 => null,
  X_N_EXT_ATTR8 => null,
  X_N_EXT_ATTR9 => null,
  X_N_EXT_ATTR10 => null,
  X_N_EXT_ATTR11 => null,
  X_N_EXT_ATTR12 => null,
  X_N_EXT_ATTR13 => null,
  X_N_EXT_ATTR14 => null,
  X_N_EXT_ATTR15 => null,
  X_N_EXT_ATTR16 => null,
  X_N_EXT_ATTR17 => null,
  X_N_EXT_ATTR18 => null,
  X_N_EXT_ATTR19 => null,
  X_N_EXT_ATTR20 => null,
  X_D_EXT_ATTR1 => sysdate,
  X_D_EXT_ATTR2 => null,
  X_D_EXT_ATTR3 => null,
  X_D_EXT_ATTR4 => null,
  X_D_EXT_ATTR5 => null,
  X_D_EXT_ATTR6 => null,
  X_D_EXT_ATTR7 => null,
  X_D_EXT_ATTR8 => null,
  X_D_EXT_ATTR9 => null,
  X_D_EXT_ATTR10 => null,
  X_TL_EXT_ATTR1 => null,
  X_TL_EXT_ATTR2 => null,
  X_TL_EXT_ATTR3 => null,
  X_TL_EXT_ATTR4 => null,
  X_TL_EXT_ATTR5 => null,
  X_TL_EXT_ATTR6 => null,
  X_TL_EXT_ATTR7 => null,
  X_TL_EXT_ATTR8 => null,
  X_TL_EXT_ATTR9 => null,
  X_TL_EXT_ATTR10 => null,
  X_TL_EXT_ATTR11 => null,
  X_TL_EXT_ATTR12 => null,
  X_TL_EXT_ATTR13 => null,
  X_TL_EXT_ATTR14 => null,
  X_TL_EXT_ATTR15 => null,
  X_TL_EXT_ATTR16 => null,
  X_TL_EXT_ATTR17 => null,
  X_TL_EXT_ATTR18 => null,
  X_TL_EXT_ATTR19 => null,
  X_TL_EXT_ATTR20 => null,
  X_CREATION_DATE => sysdate,
  X_CREATED_BY => FND_GLOBAL.user_id,
  X_LAST_UPDATE_DATE => sysdate,
  X_LAST_UPDATED_BY => FND_GLOBAL.user_id,
  X_LAST_UPDATE_LOGIN => FND_GLOBAL.login_id);

-------------------------------------------------------------------------------------------------------------------

EXCEPTION

----------------- Exceptions for the api: Create_Org_APContact ----------------------------------------------------

 WHEN invalid_create_person_exp THEN
        ROLLBACK TO Create_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	-- (if needed) FND_MESSAGE.SET_NAME('AR', 'HZ_API_DUPLICATE_COLUMN');
        -- (if needed) FND_MESSAGE.SET_TOKEN('COLUMN', 'org_contact_id');
        -- (if needed) FND_MSG_PUB.ADD;
        FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_create_person,
                                  p_data  => x_msg_data_create_person);

 WHEN invalid_create_org_exp THEN
        ROLLBACK TO Create_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_create_org_contact,
                                  p_data  => x_msg_data_create_org_contact);

 WHEN invalid_contact_points_exp THEN
        ROLLBACK TO Create_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_contact_point,
                                  p_data  => x_msg_data_contact_point);

 WHEN invalid_email_add_exp THEN
        ROLLBACK TO Create_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => l_msg_count_nab,
                                  p_data  => l_msg_data_nab);

 WHEN OTHERS THEN
    ROLLBACK TO Create_Org_APContact;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'Error in procedure Create_Org_APContact. The error mesage: '||sqlerrm;

----------------- Exceptions for the api: Create_Org_APContact ----------------------------------------------------

END Create_Org_APContact;


-- +===================================================================+
-- | Name  : Create_Org_SalesContact                                   |
-- | Description:       This Procedure will be used to create a person,|
-- |                    setup this person as a org contact, create     |
-- |                    contact points and lastly create               |
-- |                    an association of this newly contact to the    |
-- |                    party site of the organization passed as param.|
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Create_Org_SalesContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    x_org_contact_id             OUT NUMBER,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2
)
IS

   --Declare all the Local variables to be used in procedure

   x_return_status_org_contact VARCHAR2(2000);
   x_msg_count_create_org_contact NUMBER;
   x_msg_data_create_org_contact VARCHAR2(2000);

   x_return_status_create_person VARCHAR2(2000);
   x_msg_count_create_person NUMBER;
   x_msg_data_create_person VARCHAR2(2000);

   x_return_status_contact_point VARCHAR2(2000);
   x_msg_count_contact_point NUMBER;
   x_msg_data_contact_point VARCHAR2(2000);

   p_person_rec HZ_PARTY_V2PUB.PERSON_REC_TYPE;
   x_party_id NUMBER;
   x_party_number VARCHAR2(2000);
   x_profile_id NUMBER;

   p_org_contact_rec HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
   x_org_contact_id_APcontact NUMBER;
   x_party_rel_id NUMBER;
   x_party_id_create_org_contact NUMBER;
   x_party_number_org_contact VARCHAR2(2000);

   l_extension_id NUMBER;
   l_attr_group_id NUMBER;
   x_rowid VARCHAR2(2000);

   l_edi_rec_nab    HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   l_phone_rec_nab  HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   l_telex_rec_nab  HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE; 
   l_web_rec_nab    HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   l_return_status_nab VARCHAR2(2000);
   l_msg_count_nab  NUMBER;
   l_msg_data_nab VARCHAR2(2000);

   p_contact_point_rec              HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_email    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_fax      HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_edi_rec              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   p_email_rec            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_email_rec_dummy      HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_phone_rec            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_phone_rec_dummy      HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_fax_rec              HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_telex_rec            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
   p_web_rec              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   x_contact_point_id     NUMBER;


BEGIN

 SAVEPOINT Create_Org_SalesContact;

 FND_MSG_PUB.initialize;
 x_return_status := 'S';
-------------------------------------------------------------------------------------------------------------------

 p_person_rec.person_pre_name_adjunct := p_person_pre_name_adjunct;
 p_person_rec.created_by_module := 'HZ_CPUI';
 p_person_rec.person_first_name := p_person_first_name;
 p_person_rec.person_middle_name := p_person_middle_name;
 p_person_rec.person_last_name := p_person_last_name;

 hz_party_v2pub.create_person (
 'T',
 p_person_rec,
 x_party_id,
 x_party_number,
 x_profile_id,
 x_return_status_create_person,
 x_msg_count_create_person,
 x_msg_data_create_person
 );

 IF x_return_status_create_person <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_create_Sales_per_exp;
 END IF;

-------------------------------------------------------------------------------------------------------------------

 p_org_contact_rec.created_by_module := 'HZ_CPUI';
 p_org_contact_rec.party_rel_rec.subject_id := x_party_id;
 p_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
 p_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
 p_org_contact_rec.party_rel_rec.object_id := p_party_id;
 p_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
 p_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
 p_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
 p_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
 p_org_contact_rec.party_rel_rec.start_date := SYSDATE;

 hz_party_contact_v2pub.create_org_contact(
 'T',
 p_org_contact_rec,
 x_org_contact_id_APcontact,
 x_party_rel_id,
 x_party_id_create_org_contact,
 x_party_number_org_contact,
 x_return_status_org_contact,
 x_msg_count_create_org_contact,
 x_msg_data_create_org_contact);

 IF x_return_status_org_contact <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_create_Sales_org_exp;
 END IF;

 x_org_contact_id := x_org_contact_id_APcontact;

-------------------------------------------------------------------------------------------------------------------

 p_contact_point_rec.contact_point_type := 'PHONE';
 p_contact_point_rec.owner_table_name := 'HZ_PARTIES';
 p_contact_point_rec.owner_table_id := x_party_id_create_org_contact;
 p_contact_point_rec.primary_flag := 'Y';
 p_contact_point_rec.contact_point_purpose := 'BUSINESS';
 p_contact_point_rec.created_by_module := 'HZ_CPUI';

 p_phone_rec.phone_area_code := p_phone_area_code;
 p_phone_rec.phone_country_code := p_phone_country_code;
 p_phone_rec.phone_number := p_phone_number;
 p_phone_rec.phone_extension := p_phone_extension;
 p_phone_rec.phone_line_type := 'GEN';

 hz_contact_point_v2pub.create_contact_point(
 'T',
 p_contact_point_rec,
 p_edi_rec,
 p_email_rec,
 p_phone_rec,
 p_telex_rec,
 p_web_rec,
 x_contact_point_id,
 x_return_status_contact_point,
 x_msg_count_contact_point,
 x_msg_data_contact_point);

 IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_Sales_cpoints_exp;
 END IF;

 x_return_status_contact_point := 'S';

 if (trim(p_email_address) IS NOT NULL) then

  p_contact_point_rec_for_email.contact_point_type := 'EMAIL';
  p_contact_point_rec_for_email.owner_table_name := 'HZ_PARTIES';
  p_contact_point_rec_for_email.owner_table_id := x_party_id_create_org_contact;
  p_contact_point_rec_for_email.primary_flag := 'Y';
  p_contact_point_rec_for_email.contact_point_purpose := 'BUSINESS';
  p_contact_point_rec_for_email.created_by_module := 'HZ_CPUI';

  p_email_rec.email_format := 'MAILHTML';
  p_email_rec.email_address := p_email_address;

  XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

  IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
    FND_MSG_PUB.ADD;
    RAISE invalid_email_add_exp;
  END IF;

  hz_contact_point_v2pub.create_contact_point(
  'T',
  p_contact_point_rec_for_email,
  p_edi_rec,
  p_email_rec,
  p_phone_rec_dummy,
  p_telex_rec,
  p_web_rec,
  x_contact_point_id,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);

  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_Sales_cpoints_exp;
  END IF;

 end if;

 x_return_status_contact_point := 'S';

 if ((trim(p_fax_area_code) is not null) and (trim(p_fax_number) is not null)) then

  p_contact_point_rec_for_fax.contact_point_type := 'PHONE';
  p_contact_point_rec_for_fax.owner_table_name := 'HZ_PARTIES';
  p_contact_point_rec_for_fax.owner_table_id := x_party_id_create_org_contact;
  p_contact_point_rec_for_fax.primary_flag := 'N';
  p_contact_point_rec_for_fax.contact_point_purpose := 'BUSINESS';
  p_contact_point_rec_for_fax.created_by_module := 'HZ_CPUI';

  p_fax_rec.phone_area_code := p_fax_area_code;
  p_fax_rec.phone_country_code := p_fax_country_code;
  p_fax_rec.phone_number := p_fax_number;
  p_fax_rec.phone_line_type := 'FAX';

  hz_contact_point_v2pub.create_contact_point(
  'T',
  p_contact_point_rec_for_fax,
  p_edi_rec,
  p_email_rec_dummy,
  p_fax_rec,
  p_telex_rec,
  p_web_rec,
  x_contact_point_id,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);

  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_Sales_cpoints_exp;
  END IF;

 end if;

-------------------------------------------------------------------------------------------------------------------

 SELECT EGO_EXTFWK_S.NEXTVAL INTO l_extension_id FROM DUAL;

 select attr_group_id INTO l_attr_group_id from ego_attr_groups_v egoag where egoag.attr_group_type = 'HZ_PARTY_SITES_GROUP' AND egoag.attr_group_name = 'SITE_CONTACTS';


 HZ_PARTY_SITES_EXT_PKG.INSERT_ROW(
  X_ROWID => x_rowid,
  X_EXTENSION_ID => l_extension_id,
  X_PARTY_SITE_ID => p_party_site_id,
  X_ATTR_GROUP_ID => l_attr_group_id,
  X_C_EXT_ATTR1 => 'A',
  X_C_EXT_ATTR2 => null,
  X_C_EXT_ATTR3 => null,
  X_C_EXT_ATTR4 => null,
  X_C_EXT_ATTR5 => null,
  X_C_EXT_ATTR6 => null,
  X_C_EXT_ATTR7 => null,
  X_C_EXT_ATTR8 => null,
  X_C_EXT_ATTR9 => null,
  X_C_EXT_ATTR10 => null,
  X_C_EXT_ATTR11 => null,
  X_C_EXT_ATTR12 => null,
  X_C_EXT_ATTR13 => null,
  X_C_EXT_ATTR14 => null,
  X_C_EXT_ATTR15 => null,
  X_C_EXT_ATTR16 => null,
  X_C_EXT_ATTR17 => null,
  X_C_EXT_ATTR18 => null,
  X_C_EXT_ATTR19 => null,
  X_C_EXT_ATTR20 => null,
  X_N_EXT_ATTR1 => x_party_rel_id,
  X_N_EXT_ATTR2 => null,
  X_N_EXT_ATTR3 => null,
  X_N_EXT_ATTR4 => null,
  X_N_EXT_ATTR5 => null,
  X_N_EXT_ATTR6 => null,
  X_N_EXT_ATTR7 => null,
  X_N_EXT_ATTR8 => null,
  X_N_EXT_ATTR9 => null,
  X_N_EXT_ATTR10 => null,
  X_N_EXT_ATTR11 => null,
  X_N_EXT_ATTR12 => null,
  X_N_EXT_ATTR13 => null,
  X_N_EXT_ATTR14 => null,
  X_N_EXT_ATTR15 => null,
  X_N_EXT_ATTR16 => null,
  X_N_EXT_ATTR17 => null,
  X_N_EXT_ATTR18 => null,
  X_N_EXT_ATTR19 => null,
  X_N_EXT_ATTR20 => null,
  X_D_EXT_ATTR1 => sysdate,
  X_D_EXT_ATTR2 => null,
  X_D_EXT_ATTR3 => null,
  X_D_EXT_ATTR4 => null,
  X_D_EXT_ATTR5 => null,
  X_D_EXT_ATTR6 => null,
  X_D_EXT_ATTR7 => null,
  X_D_EXT_ATTR8 => null,
  X_D_EXT_ATTR9 => null,
  X_D_EXT_ATTR10 => null,
  X_TL_EXT_ATTR1 => null,
  X_TL_EXT_ATTR2 => null,
  X_TL_EXT_ATTR3 => null,
  X_TL_EXT_ATTR4 => null,
  X_TL_EXT_ATTR5 => null,
  X_TL_EXT_ATTR6 => null,
  X_TL_EXT_ATTR7 => null,
  X_TL_EXT_ATTR8 => null,
  X_TL_EXT_ATTR9 => null,
  X_TL_EXT_ATTR10 => null,
  X_TL_EXT_ATTR11 => null,
  X_TL_EXT_ATTR12 => null,
  X_TL_EXT_ATTR13 => null,
  X_TL_EXT_ATTR14 => null,
  X_TL_EXT_ATTR15 => null,
  X_TL_EXT_ATTR16 => null,
  X_TL_EXT_ATTR17 => null,
  X_TL_EXT_ATTR18 => null,
  X_TL_EXT_ATTR19 => null,
  X_TL_EXT_ATTR20 => null,
  X_CREATION_DATE => sysdate,
  X_CREATED_BY => FND_GLOBAL.user_id,
  X_LAST_UPDATE_DATE => sysdate,
  X_LAST_UPDATED_BY => FND_GLOBAL.user_id,
  X_LAST_UPDATE_LOGIN => FND_GLOBAL.login_id);

-------------------------------------------------------------------------------------------------------------------

EXCEPTION

----------------- Exceptions for the api: Create_Org_SalesContact -------------------------------------------------

 WHEN invalid_create_Sales_per_exp THEN
        ROLLBACK TO Create_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	-- (if needed) FND_MESSAGE.SET_NAME('AR', 'HZ_API_DUPLICATE_COLUMN');
        -- (if needed) FND_MESSAGE.SET_TOKEN('COLUMN', 'org_contact_id');
        -- (if needed) FND_MSG_PUB.ADD;
        FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_create_person,
                                  p_data  => x_msg_data_create_person);

 WHEN invalid_create_Sales_org_exp THEN
        ROLLBACK TO Create_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_create_org_contact,
                                  p_data  => x_msg_data_create_org_contact);

 WHEN invalid_email_add_exp THEN
        ROLLBACK TO Create_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => l_msg_count_nab,
                                  p_data  => l_msg_data_nab);

 WHEN invalid_Sales_cpoints_exp THEN
        ROLLBACK TO Create_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_contact_point,
                                  p_data  => x_msg_data_contact_point);

 WHEN OTHERS THEN
    ROLLBACK TO Create_Org_SalesContact;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'Error in procedure Create_Org_SalesContact. The error mesage: '||sqlerrm;

----------------- Exceptions for the api: Create_Org_SalesContact -------------------------------------------------

END Create_Org_SalesContact;


-- +===================================================================+
-- | Name  : Update_Org_APContact                                      |
-- | Description:       This Procedure will be used to update a person |
-- |                    and update contact points.                     |
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Update_Org_APContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    p_org_contact_id             IN VARCHAR2,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2
)
IS

   --Declare all the Local variables to be used in procedure

   x_return_status_update_person VARCHAR2(2000);
   x_msg_count_update_person NUMBER;
   x_msg_data_update_person VARCHAR2(2000);

   x_return_status_contact_point VARCHAR2(2000);
   x_msg_count_contact_point NUMBER;
   x_msg_data_contact_point VARCHAR2(2000);

   party_id_contact NUMBER;
   contact_point_id_phone NUMBER;
   contact_point_id_fax NUMBER;
   contact_point_id_email NUMBER;

   obj_ver_num_contact NUMBER;
   obj_ver_num_phone NUMBER;
   obj_ver_num_fax NUMBER;
   obj_ver_num_email NUMBER;

   l_edi_rec_nab    HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   l_phone_rec_nab  HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   l_telex_rec_nab  HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE; 
   l_web_rec_nab    HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   l_return_status_nab VARCHAR2(2000);
   l_msg_count_nab  NUMBER;
   l_msg_data_nab VARCHAR2(2000);

   p_person_rec HZ_PARTY_V2PUB.PERSON_REC_TYPE;
   x_party_id NUMBER;
   x_profile_id NUMBER;

   p_party_object_version_number NUMBER;
   p_object_version_number_phone NUMBER;
   p_object_version_number_fax NUMBER;
   p_object_version_number_email NUMBER;

   l_extension_id NUMBER;
   l_attr_group_id NUMBER;

   l_person_pre_name_adjunct     VARCHAR2(200);
   l_person_first_name           VARCHAR2(200);
   l_person_middle_name          VARCHAR2(200);
   l_person_last_name            VARCHAR2(200);
   l_email_address               VARCHAR2(200);
   l_phone_country_code          VARCHAR2(200);
   l_phone_area_code             VARCHAR2(200);
   l_phone_number                VARCHAR2(200);
   l_phone_extension             VARCHAR2(200);
   l_fax_country_code            VARCHAR2(200);
   l_fax_area_code               VARCHAR2(200);
   l_fax_number                  VARCHAR2(200);
   l_owner_table_id              NUMBER(15);
   
   p_contact_point_rec              HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_email    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_fax      HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_edi_rec              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   p_email_rec            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_email_rec_dummy      HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_phone_rec            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_phone_rec_dummy      HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_fax_rec              HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_telex_rec            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
   p_web_rec              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   x_contact_point_id     NUMBER;

   l_doNOTcall_updatePerson VARCHAR2(200);
   l_doNOTcall_updatePerson1 VARCHAR2(200);
   l_doNOTcall_updatePerson2 VARCHAR2(200);
   l_doNOTcall_updatePerson3 VARCHAR2(200);
   l_doNOTcall_updatePerson4 VARCHAR2(200);
   l_doNOTcall_updateCPoint VARCHAR2(200);
   l_doNOTcall_updateCPoint1 VARCHAR2(200);
   l_doNOTcall_updateCPoint2 VARCHAR2(200);
   l_doNOTcall_updateCPoint3 VARCHAR2(200);
   l_doNOTcall_updateCPoint4 VARCHAR2(200);

   --Declare cursors

   CURSOR contact_person IS
    select party_id, object_version_number, person_pre_name_adjunct, person_first_name, person_middle_name, person_last_name
    from hz_parties 
    where party_id = (select subject_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id));

   CURSOR contact_phone IS
    select contact_point_id, object_version_number, phone_country_code, phone_area_code, phone_number, phone_extension, owner_table_id 
    from hz_contact_points 
    where contact_point_type = 'PHONE' 
    and status = 'A' 
    and phone_line_type = 'GEN'
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id))
    ORDER BY primary_flag DESC, CREATION_DATE DESC;

   CURSOR contact_fax IS
    select contact_point_id, object_version_number, phone_country_code, phone_area_code, phone_number
    from hz_contact_points 
    where contact_point_type = 'PHONE' 
    and status = 'A' 
    and phone_line_type = 'FAX'
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id))
    ORDER BY primary_flag DESC, CREATION_DATE DESC;

   CURSOR contact_email IS
    select contact_point_id, object_version_number, email_address
    from hz_contact_points 
    where contact_point_type = 'EMAIL' 
    and status = 'A' 
    and primary_flag = 'Y' 
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id));

BEGIN

 SAVEPOINT Update_Org_APContact;
 
 FND_MSG_PUB.initialize;
 x_return_status := 'S';

 l_doNOTcall_updatePerson  := 'Y';
 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updatePerson1 := 'Y';
 l_doNOTcall_updatePerson2 := 'Y';
 l_doNOTcall_updatePerson3 := 'Y';
 l_doNOTcall_updatePerson4 := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';

 open contact_person;
 fetch contact_person into party_id_contact, obj_ver_num_contact, l_person_pre_name_adjunct, l_person_first_name, l_person_middle_name, l_person_last_name;
 close contact_person;

 open contact_phone;
 fetch contact_phone into contact_point_id_phone, obj_ver_num_phone, l_phone_country_code, l_phone_area_code, l_phone_number, l_phone_extension, l_owner_table_id;
 close contact_phone;

 open contact_fax;
 fetch contact_fax into contact_point_id_fax, obj_ver_num_fax, l_fax_country_code, l_fax_area_code, l_fax_number;
 close contact_fax;

 open contact_email;
 fetch contact_email into contact_point_id_email, obj_ver_num_email, l_email_address;
 close contact_email;

-------------------------------------------------------------------------------------------------------------------

 if ((trim(p_person_pre_name_adjunct) is null) and (l_person_pre_name_adjunct is null)) then
   l_doNOTcall_updatePerson1 := 'Y';
 end if;
 if ((trim(p_person_pre_name_adjunct) is null) and (l_person_pre_name_adjunct is not null)) then
   l_doNOTcall_updatePerson1 := 'N';
 end if;
 if ((trim(p_person_pre_name_adjunct) is not null) and (l_person_pre_name_adjunct is null)) then
   l_doNOTcall_updatePerson1 := 'N';
 end if;
 if ((trim(p_person_pre_name_adjunct) is not null) and (l_person_pre_name_adjunct is not null)) then
 if (p_person_pre_name_adjunct <> l_person_pre_name_adjunct) then
   l_doNOTcall_updatePerson1 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson1 : '||l_doNOTcall_updatePerson1);


 if ((trim(p_person_first_name) is null) and (l_person_first_name is null)) then
   l_doNOTcall_updatePerson2 := 'Y';
 end if;
 if ((trim(p_person_first_name) is null) and (l_person_first_name is not null)) then
   l_doNOTcall_updatePerson2 := 'N';
 end if;
 if ((trim(p_person_first_name) is not null) and (l_person_first_name is null)) then
   l_doNOTcall_updatePerson2 := 'N';
 end if;
 if ((trim(p_person_first_name) is not null) and (l_person_first_name is not null)) then
 if (p_person_first_name <> l_person_first_name) then
   l_doNOTcall_updatePerson2 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson2 : '||l_doNOTcall_updatePerson2);


 if ((trim(p_person_middle_name) is null) and (l_person_middle_name is null)) then
   l_doNOTcall_updatePerson3 := 'Y';
 end if;
 if ((trim(p_person_middle_name) is null) and (l_person_middle_name is not null)) then
   l_doNOTcall_updatePerson3 := 'N';
 end if;
 if ((trim(p_person_middle_name) is not null) and (l_person_middle_name is null)) then
   l_doNOTcall_updatePerson3 := 'N';
 end if;
 if ((trim(p_person_middle_name) is not null) and (l_person_middle_name is not null)) then
 if (p_person_middle_name <> l_person_middle_name) then
   l_doNOTcall_updatePerson3 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson3 : '||l_doNOTcall_updatePerson3);


 if ((trim(p_person_last_name) is null) and (l_person_last_name is null)) then
   l_doNOTcall_updatePerson4 := 'Y';
 end if;
 if ((trim(p_person_last_name) is null) and (l_person_last_name is not null)) then
   l_doNOTcall_updatePerson4 := 'N';
 end if;
 if ((trim(p_person_last_name) is not null) and (l_person_last_name is null)) then
   l_doNOTcall_updatePerson4 := 'N';
 end if;
 if ((trim(p_person_last_name) is not null) and (l_person_last_name is not null)) then
 if (p_person_last_name <> l_person_last_name) then
   l_doNOTcall_updatePerson4 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson4 : '||l_doNOTcall_updatePerson4);


 if ((l_doNOTcall_updatePerson4 = 'N') or (l_doNOTcall_updatePerson3 = 'N') or (l_doNOTcall_updatePerson2 = 'N') or (l_doNOTcall_updatePerson1 = 'N')) then
   l_doNOTcall_updatePerson := 'N';
   --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson : '||l_doNOTcall_updatePerson);
 end if;


 if (l_doNOTcall_updatePerson = 'N') then

  p_person_rec.person_pre_name_adjunct := p_person_pre_name_adjunct;
  p_person_rec.person_first_name := p_person_first_name;
  p_person_rec.person_middle_name := p_person_middle_name;
  p_person_rec.person_last_name := p_person_last_name;
  p_person_rec.party_rec.party_id := party_id_contact;

  p_party_object_version_number := obj_ver_num_contact;

  hz_party_v2pub.update_person (
  'T',
  p_person_rec,
  p_party_object_version_number,
  x_profile_id,
  x_return_status_update_person,
  x_msg_count_update_person,
  x_msg_data_update_person
  );

  IF x_return_status_update_person <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_update_person_exp;
  END IF;

 end if;

-------------------------------------------------------------------------------------------------------------------

 if ((trim(p_phone_area_code) is null) and (l_phone_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'Y';
 end if;
 if ((trim(p_phone_area_code) is null) and (l_phone_area_code is not null)) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if;
 if ((trim(p_phone_area_code) is not null) and (l_phone_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if;
 if ((trim(p_phone_area_code) is not null) and (l_phone_area_code is not null)) then
 if (p_phone_area_code <> l_phone_area_code) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if; end if;



 if ((trim(p_phone_country_code) is null) and (l_phone_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'Y';
 end if;
 if ((trim(p_phone_country_code) is null) and (l_phone_country_code is not null)) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if;
 if ((trim(p_phone_country_code) is not null) and (l_phone_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if;
 if ((trim(p_phone_country_code) is not null) and (l_phone_country_code is not null)) then
 if (p_phone_country_code <> l_phone_country_code) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if; end if;



 if ((trim(p_phone_extension) is null) and (l_phone_extension is null)) then
   l_doNOTcall_updateCPoint3 := 'Y';
 end if;
 if ((trim(p_phone_extension) is null) and (l_phone_extension is not null)) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if;
 if ((trim(p_phone_extension) is not null) and (l_phone_extension is null)) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if;
 if ((trim(p_phone_extension) is not null) and (l_phone_extension is not null)) then
 if (p_phone_extension <> l_phone_extension) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if; end if;



 if ((trim(p_phone_number) is null) and (l_phone_number is null)) then
   l_doNOTcall_updateCPoint4 := 'Y';
 end if;
 if ((trim(p_phone_number) is null) and (l_phone_number is not null)) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if;
 if ((trim(p_phone_number) is not null) and (l_phone_number is null)) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if;
 if ((trim(p_phone_number) is not null) and (l_phone_number is not null)) then
 if (p_phone_number <> l_phone_number) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if; end if;

 if ((l_doNOTcall_updateCPoint4 = 'N') or (l_doNOTcall_updateCPoint3 = 'N') or (l_doNOTcall_updateCPoint2 = 'N') or (l_doNOTcall_updateCPoint1 = 'N')) then
   l_doNOTcall_updateCPoint := 'N';   
 end if;


 if (l_doNOTcall_updateCPoint = 'N') then

  p_contact_point_rec.contact_point_id := contact_point_id_phone;

  p_phone_rec.phone_area_code := p_phone_area_code;
  p_phone_rec.phone_country_code := p_phone_country_code;
  p_phone_rec.phone_number := p_phone_number;
  p_phone_rec.phone_extension := p_phone_extension;

  p_object_version_number_phone := obj_ver_num_phone;

  hz_contact_point_v2pub.update_contact_point(
  'T',
  p_contact_point_rec,
  p_edi_rec,
  p_email_rec,
  p_phone_rec,
  p_telex_rec,
  p_web_rec,
  p_object_version_number_phone,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);


  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_Sales_cpoints_exp;
  END IF;

 end if;

 x_return_status_contact_point := 'S';

 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';


 if (contact_point_id_email is null) then

  -- call create api for email CP

  if (trim(p_email_address) IS NOT NULL) then

   p_contact_point_rec_for_email.contact_point_type := 'EMAIL';
   p_contact_point_rec_for_email.owner_table_name := 'HZ_PARTIES';
   p_contact_point_rec_for_email.owner_table_id := l_owner_table_id;
   p_contact_point_rec_for_email.primary_flag := 'Y';
   p_contact_point_rec_for_email.contact_point_purpose := 'BUSINESS';
   p_contact_point_rec_for_email.created_by_module := 'HZ_CPUI';

   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;

   XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

   IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
    FND_MSG_PUB.ADD;
    RAISE invalid_email_add_exp;
   END IF;

   hz_contact_point_v2pub.create_contact_point(
   'T',
   p_contact_point_rec_for_email,
   p_edi_rec,
   p_email_rec,
   p_phone_rec_dummy,
   p_telex_rec,
   p_web_rec,
   x_contact_point_id,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);

 
   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_update_cpoints_exp;
   END IF;

  end if;

 else -- if (contact_point_id_email is null) then

  if ((trim(p_email_address) is null) and (l_email_address is null)) then
   l_doNOTcall_updateCPoint := 'Y';
  end if;
  if ((trim(p_email_address) is null) and (l_email_address is not null)) then
   l_doNOTcall_updateCPoint := 'N';
  end if;
  if ((trim(p_email_address) is not null) and (l_email_address is null)) then
   l_doNOTcall_updateCPoint := 'N';
  end if;
  if ((trim(p_email_address) is not null) and (l_email_address is not null)) then
  if (p_email_address <> l_email_address) then
   l_doNOTcall_updateCPoint := 'N';
  end if; end if;

  --insert_log_mesg('Anirban line#1296 : '|| l_doNOTcall_updateCPoint);
  
  if (trim(p_email_address) is not null) then

   p_contact_point_rec_for_email.contact_point_id := contact_point_id_email;
   p_contact_point_rec_for_email.contact_point_type :=  'EMAIL';
   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;

   --insert_log_mesg('Anirban line#1299 : '|| trim(p_email_address));
   XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

   --insert_log_mesg('Anirban line#1311 l_return_status_nab : '|| l_return_status_nab);
   IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
    FND_MSG_PUB.ADD;
    RAISE invalid_email_add_exp;
   END IF;  
  end if; 


  if (l_doNOTcall_updateCPoint = 'N') then

   p_contact_point_rec_for_email.contact_point_id := contact_point_id_email;
   p_contact_point_rec_for_email.contact_point_type :=  'EMAIL';
   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;
   p_object_version_number_email := obj_ver_num_email;

   if (trim(p_email_address) is null) then
    p_email_rec.email_address := l_email_address;
    p_contact_point_rec_for_email.status := 'D';
   end if;

   hz_contact_point_v2pub.update_contact_point(
   'T',
   p_contact_point_rec_for_email,
   p_edi_rec,
   p_email_rec,
   p_phone_rec_dummy,
   p_telex_rec,
   p_web_rec,
   p_object_version_number_email,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);


   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_update_cpoints_exp;
   END IF;

   if (trim(p_email_address) is null) then
    update hz_parties set email_address = null where party_id = l_owner_table_id;
   end if;

  end if;
 end if; -- if (contact_point_id_email is null) then

 x_return_status_contact_point := 'S';

 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';

 if (contact_point_id_fax is null) then

  -- call create api for fax CP

  if ((trim(p_fax_area_code) is not null) and (trim(p_fax_number) is not null)) then

   p_contact_point_rec_for_fax.contact_point_type := 'PHONE';
   p_contact_point_rec_for_fax.owner_table_name := 'HZ_PARTIES';
   p_contact_point_rec_for_fax.owner_table_id := l_owner_table_id;
   p_contact_point_rec_for_fax.primary_flag := 'N';
   p_contact_point_rec_for_fax.contact_point_purpose := 'BUSINESS';
   p_contact_point_rec_for_fax.created_by_module := 'HZ_CPUI';

   p_fax_rec.phone_area_code := p_fax_area_code;
   p_fax_rec.phone_country_code := p_fax_country_code;
   p_fax_rec.phone_number := p_fax_number;
   p_fax_rec.phone_line_type := 'FAX';

   hz_contact_point_v2pub.create_contact_point(
   'T',
   p_contact_point_rec_for_fax,
   p_edi_rec,
   p_email_rec_dummy,
   p_fax_rec,
   p_telex_rec,
   p_web_rec,
   x_contact_point_id,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);


   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_update_cpoints_exp;
   END IF;

  end if;

 else -- if (contact_point_id_fax is null) then

  if ((trim(p_fax_area_code) is null) and (l_fax_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'Y';
  end if;
  if ((trim(p_fax_area_code) is null) and (l_fax_area_code is not null)) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if;
  if ((trim(p_fax_area_code) is not null) and (l_fax_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if;
  if ((trim(p_fax_area_code) is not null) and (l_fax_area_code is not null)) then
  if (p_fax_area_code <> l_fax_area_code) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if; end if;


  if ((trim(p_fax_country_code) is null) and (l_fax_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'Y';
  end if;
  if ((trim(p_fax_country_code) is null) and (l_fax_country_code is not null)) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if;
  if ((trim(p_fax_country_code) is not null) and (l_fax_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if;
  if ((trim(p_fax_country_code) is not null) and (l_fax_country_code is not null)) then
  if (p_fax_country_code <> l_fax_country_code) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if; end if;


  if ((trim(p_fax_number) is null) and (l_fax_number is null)) then
   l_doNOTcall_updateCPoint3 := 'Y';
  end if;
  if ((trim(p_fax_number) is null) and (l_fax_number is not null)) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if;
  if ((trim(p_fax_number) is not null) and (l_fax_number is null)) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if;
  if ((trim(p_fax_number) is not null) and (l_fax_number is not null)) then
  if (p_fax_number <> l_fax_number) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if; end if;


  if ((l_doNOTcall_updateCPoint3 = 'N') or (l_doNOTcall_updateCPoint2 = 'N') or (l_doNOTcall_updateCPoint1 = 'N')) then
   l_doNOTcall_updateCPoint := 'N';   
  end if;


  if (l_doNOTcall_updateCPoint = 'N') then

   p_contact_point_rec_for_fax.contact_point_id := contact_point_id_fax;
   p_fax_rec.phone_area_code := p_fax_area_code;
   p_fax_rec.phone_country_code := p_fax_country_code;
   p_fax_rec.phone_number := p_fax_number;

   p_object_version_number_fax := obj_ver_num_fax;

   hz_contact_point_v2pub.update_contact_point(
   'T',
   p_contact_point_rec_for_fax,
   p_edi_rec,
   p_email_rec_dummy,
   p_fax_rec,
   p_telex_rec,
   p_web_rec,
   p_object_version_number_fax,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);

   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_update_cpoints_exp;
   END IF;

  end if;
 end if; -- if (contact_point_id_fax is null) then

-------------------------------------------------------------------------------------------------------------------

EXCEPTION

----------------- Exceptions for the api: Update_Org_APContact ----------------------------------------------------

 WHEN invalid_update_person_exp THEN
        ROLLBACK TO Update_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	-- (if needed) FND_MESSAGE.SET_NAME('AR', 'HZ_API_DUPLICATE_COLUMN');
        -- (if needed) FND_MESSAGE.SET_TOKEN('COLUMN', 'org_contact_id');
        -- (if needed) FND_MSG_PUB.ADD;
        FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_update_person,
                                  p_data  => x_msg_data_update_person);

 WHEN invalid_update_cpoints_exp THEN
        ROLLBACK TO Update_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_contact_point,
                                  p_data  => x_msg_data_contact_point);

 WHEN invalid_email_add_exp THEN
        ROLLBACK TO Update_Org_APContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => l_msg_count_nab,
                                  p_data  => l_msg_data_nab);

 WHEN OTHERS THEN
    ROLLBACK TO Update_Org_APContact;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'Error in procedure Update_Org_APContact. The error mesage: '||sqlerrm;

----------------- Exceptions for the api: Update_Org_APContact ----------------------------------------------------

END Update_Org_APContact;


-- +===================================================================+
-- | Name  : Update_Org_SalesContact                                      |
-- | Description:       This Procedure will be used to update a person |
-- |                    and update contact points.                     |
-- | Parameters:                                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Update_Org_SalesContact (
    p_person_pre_name_adjunct    IN VARCHAR2,
    p_person_first_name          IN VARCHAR2,
    p_person_middle_name         IN VARCHAR2,
    p_person_last_name           IN VARCHAR2,
    p_email_address              IN VARCHAR2,
    p_phone_country_code         IN VARCHAR2,
    p_phone_area_code            IN VARCHAR2,
    p_phone_number               IN VARCHAR2,
    p_phone_extension            IN VARCHAR2,
    p_fax_country_code           IN VARCHAR2,
    p_fax_area_code              IN VARCHAR2,
    p_fax_number                 IN VARCHAR2,
    p_party_id                   IN NUMBER,
    p_party_site_id              IN NUMBER,
    p_org_contact_id             IN VARCHAR2,
    x_return_status              IN OUT NOCOPY   VARCHAR2,
    x_msg_count                  OUT    NOCOPY   NUMBER,
    x_msg_data                   OUT    NOCOPY   VARCHAR2
)
IS

   --Declare all the Local variables to be used in procedure

   x_return_status_update_person VARCHAR2(2000);
   x_msg_count_update_person NUMBER;
   x_msg_data_update_person VARCHAR2(2000);

   x_return_status_contact_point VARCHAR2(2000);
   x_msg_count_contact_point NUMBER;
   x_msg_data_contact_point VARCHAR2(2000);

   party_id_contact NUMBER;
   contact_point_id_phone NUMBER;
   contact_point_id_fax NUMBER;
   contact_point_id_email NUMBER;

   obj_ver_num_contact NUMBER;
   obj_ver_num_phone NUMBER;
   obj_ver_num_fax NUMBER;
   obj_ver_num_email NUMBER;

   l_edi_rec_nab    HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   l_phone_rec_nab  HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   l_telex_rec_nab  HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE; 
   l_web_rec_nab    HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   l_return_status_nab VARCHAR2(2000);
   l_msg_count_nab  NUMBER;
   l_msg_data_nab VARCHAR2(2000);

   p_person_rec HZ_PARTY_V2PUB.PERSON_REC_TYPE;
   x_party_id NUMBER;
   x_profile_id NUMBER;

   p_party_object_version_number NUMBER;
   p_object_version_number_phone NUMBER;
   p_object_version_number_fax NUMBER;
   p_object_version_number_email NUMBER;

   l_extension_id NUMBER;
   l_attr_group_id NUMBER;

   l_person_pre_name_adjunct     VARCHAR2(200);
   l_person_first_name           VARCHAR2(200);
   l_person_middle_name          VARCHAR2(200);
   l_person_last_name            VARCHAR2(200);
   l_email_address               VARCHAR2(200);
   l_phone_country_code          VARCHAR2(200);
   l_phone_area_code             VARCHAR2(200);
   l_phone_number                VARCHAR2(200);
   l_phone_extension             VARCHAR2(200);
   l_fax_country_code            VARCHAR2(200);
   l_fax_area_code               VARCHAR2(200);
   l_fax_number                  VARCHAR2(200);
   l_owner_table_id              NUMBER(15);
   
   p_contact_point_rec              HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_email    HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_contact_point_rec_for_fax      HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
   p_edi_rec              HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE;
   p_email_rec            HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_email_rec_dummy      HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
   p_phone_rec            HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_phone_rec_dummy      HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_fax_rec              HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
   p_telex_rec            HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE;
   p_web_rec              HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE;
   x_contact_point_id     NUMBER;

   l_doNOTcall_updatePerson VARCHAR2(200);
   l_doNOTcall_updatePerson1 VARCHAR2(200);
   l_doNOTcall_updatePerson2 VARCHAR2(200);
   l_doNOTcall_updatePerson3 VARCHAR2(200);
   l_doNOTcall_updatePerson4 VARCHAR2(200);
   l_doNOTcall_updateCPoint VARCHAR2(200);
   l_doNOTcall_updateCPoint1 VARCHAR2(200);
   l_doNOTcall_updateCPoint2 VARCHAR2(200);
   l_doNOTcall_updateCPoint3 VARCHAR2(200);
   l_doNOTcall_updateCPoint4 VARCHAR2(200);

   --Declare cursors

   CURSOR contact_person IS
    select party_id, object_version_number, person_pre_name_adjunct, person_first_name, person_middle_name, person_last_name
    from hz_parties 
    where party_id = (select subject_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id));

   CURSOR contact_phone IS
    select contact_point_id, object_version_number, phone_country_code, phone_area_code, phone_number, phone_extension, owner_table_id 
    from hz_contact_points 
    where contact_point_type = 'PHONE' 
    and status = 'A' 
    and phone_line_type = 'GEN'
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id))
    ORDER BY primary_flag DESC, CREATION_DATE DESC;

   CURSOR contact_fax IS
    select contact_point_id, object_version_number, phone_country_code, phone_area_code, phone_number
    from hz_contact_points 
    where contact_point_type = 'PHONE' 
    and status = 'A' 
    and phone_line_type = 'FAX'
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id))
    ORDER BY primary_flag DESC, CREATION_DATE DESC;

   CURSOR contact_email IS
    select contact_point_id, object_version_number, email_address
    from hz_contact_points 
    where contact_point_type = 'EMAIL' 
    and status = 'A' 
    and primary_flag = 'Y' 
    and owner_table_id = (select party_id from hz_party_relationships where party_relationship_id = (select party_relationship_id from hz_org_contacts where org_contact_id = p_org_contact_id));

BEGIN

 SAVEPOINT Update_Org_SalesContact;
 
 FND_MSG_PUB.initialize;
 x_return_status := 'S';

 l_doNOTcall_updatePerson  := 'Y';
 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updatePerson1 := 'Y';
 l_doNOTcall_updatePerson2 := 'Y';
 l_doNOTcall_updatePerson3 := 'Y';
 l_doNOTcall_updatePerson4 := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';


 open contact_person;
 fetch contact_person into party_id_contact, obj_ver_num_contact, l_person_pre_name_adjunct, l_person_first_name, l_person_middle_name, l_person_last_name;
 close contact_person;

 open contact_phone;
 fetch contact_phone into contact_point_id_phone, obj_ver_num_phone, l_phone_country_code, l_phone_area_code, l_phone_number, l_phone_extension, l_owner_table_id;
 close contact_phone;

 open contact_fax;
 fetch contact_fax into contact_point_id_fax, obj_ver_num_fax, l_fax_country_code, l_fax_area_code, l_fax_number;
 close contact_fax;

 open contact_email;
 fetch contact_email into contact_point_id_email, obj_ver_num_email, l_email_address;
 close contact_email;

-------------------------------------------------------------------------------------------------------------------

 if ((trim(p_person_pre_name_adjunct) is null) and (l_person_pre_name_adjunct is null)) then
   l_doNOTcall_updatePerson1 := 'Y';
 end if;
 if ((trim(p_person_pre_name_adjunct) is null) and (l_person_pre_name_adjunct is not null)) then
   l_doNOTcall_updatePerson1 := 'N';
 end if;
 if ((trim(p_person_pre_name_adjunct) is not null) and (l_person_pre_name_adjunct is null)) then
   l_doNOTcall_updatePerson1 := 'N';
 end if;
 if ((trim(p_person_pre_name_adjunct) is not null) and (l_person_pre_name_adjunct is not null)) then
 if (p_person_pre_name_adjunct <> l_person_pre_name_adjunct) then
   l_doNOTcall_updatePerson1 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson1 : '||l_doNOTcall_updatePerson1);


 if ((trim(p_person_first_name) is null) and (l_person_first_name is null)) then
   l_doNOTcall_updatePerson2 := 'Y';
 end if;
 if ((trim(p_person_first_name) is null) and (l_person_first_name is not null)) then
   l_doNOTcall_updatePerson2 := 'N';
 end if;
 if ((trim(p_person_first_name) is not null) and (l_person_first_name is null)) then
   l_doNOTcall_updatePerson2 := 'N';
 end if;
 if ((trim(p_person_first_name) is not null) and (l_person_first_name is not null)) then
 if (p_person_first_name <> l_person_first_name) then
   l_doNOTcall_updatePerson2 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson2 : '||l_doNOTcall_updatePerson2);


 if ((trim(p_person_middle_name) is null) and (l_person_middle_name is null)) then
   l_doNOTcall_updatePerson3 := 'Y';
 end if;
 if ((trim(p_person_middle_name) is null) and (l_person_middle_name is not null)) then
   l_doNOTcall_updatePerson3 := 'N';
 end if;
 if ((trim(p_person_middle_name) is not null) and (l_person_middle_name is null)) then
   l_doNOTcall_updatePerson3 := 'N';
 end if;
 if ((trim(p_person_middle_name) is not null) and (l_person_middle_name is not null)) then
 if (p_person_middle_name <> l_person_middle_name) then
   l_doNOTcall_updatePerson3 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson3 : '||l_doNOTcall_updatePerson3);


 if ((trim(p_person_last_name) is null) and (l_person_last_name is null)) then
   l_doNOTcall_updatePerson4 := 'Y';
 end if;
 if ((trim(p_person_last_name) is null) and (l_person_last_name is not null)) then
   l_doNOTcall_updatePerson4 := 'N';
 end if;
 if ((trim(p_person_last_name) is not null) and (l_person_last_name is null)) then
   l_doNOTcall_updatePerson4 := 'N';
 end if;
 if ((trim(p_person_last_name) is not null) and (l_person_last_name is not null)) then
 if (p_person_last_name <> l_person_last_name) then
   l_doNOTcall_updatePerson4 := 'N';
 end if; end if;
 --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson4 : '||l_doNOTcall_updatePerson4);


 if ((l_doNOTcall_updatePerson4 = 'N') or (l_doNOTcall_updatePerson3 = 'N') or (l_doNOTcall_updatePerson2 = 'N') or (l_doNOTcall_updatePerson1 = 'N')) then
   l_doNOTcall_updatePerson := 'N';
   --insert_log_mesg('Anirban printing the value of l_doNOTcall_updatePerson : '||l_doNOTcall_updatePerson);
 end if;


 if (l_doNOTcall_updatePerson = 'N') then

  p_person_rec.person_pre_name_adjunct := p_person_pre_name_adjunct;
  p_person_rec.person_first_name := p_person_first_name;
  p_person_rec.person_middle_name := p_person_middle_name;
  p_person_rec.person_last_name := p_person_last_name;
  p_person_rec.party_rec.party_id := party_id_contact;

  p_party_object_version_number := obj_ver_num_contact;

  hz_party_v2pub.update_person (
  'T',
  p_person_rec,
  p_party_object_version_number,
  x_profile_id,
  x_return_status_update_person,
  x_msg_count_update_person,
  x_msg_data_update_person
  );

  IF x_return_status_update_person <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_update_Sales_per_exp;
  END IF;

 end if;
-------------------------------------------------------------------------------------------------------------------

 if ((trim(p_phone_area_code) is null) and (l_phone_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'Y';
 end if;
 if ((trim(p_phone_area_code) is null) and (l_phone_area_code is not null)) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if;
 if ((trim(p_phone_area_code) is not null) and (l_phone_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if;
 if ((trim(p_phone_area_code) is not null) and (l_phone_area_code is not null)) then
 if (p_phone_area_code <> l_phone_area_code) then
   l_doNOTcall_updateCPoint1 := 'N';
 end if; end if;



 if ((trim(p_phone_country_code) is null) and (l_phone_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'Y';
 end if;
 if ((trim(p_phone_country_code) is null) and (l_phone_country_code is not null)) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if;
 if ((trim(p_phone_country_code) is not null) and (l_phone_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if;
 if ((trim(p_phone_country_code) is not null) and (l_phone_country_code is not null)) then
 if (p_phone_country_code <> l_phone_country_code) then
   l_doNOTcall_updateCPoint2 := 'N';
 end if; end if;



 if ((trim(p_phone_extension) is null) and (l_phone_extension is null)) then
   l_doNOTcall_updateCPoint3 := 'Y';
 end if;
 if ((trim(p_phone_extension) is null) and (l_phone_extension is not null)) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if;
 if ((trim(p_phone_extension) is not null) and (l_phone_extension is null)) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if;
 if ((trim(p_phone_extension) is not null) and (l_phone_extension is not null)) then
 if (p_phone_extension <> l_phone_extension) then
   l_doNOTcall_updateCPoint3 := 'N';
 end if; end if;



 if ((trim(p_phone_number) is null) and (l_phone_number is null)) then
   l_doNOTcall_updateCPoint4 := 'Y';
 end if;
 if ((trim(p_phone_number) is null) and (l_phone_number is not null)) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if;
 if ((trim(p_phone_number) is not null) and (l_phone_number is null)) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if;
 if ((trim(p_phone_number) is not null) and (l_phone_number is not null)) then
 if (p_phone_number <> l_phone_number) then
   l_doNOTcall_updateCPoint4 := 'N';
 end if; end if;

 if ((l_doNOTcall_updateCPoint4 = 'N') or (l_doNOTcall_updateCPoint3 = 'N') or (l_doNOTcall_updateCPoint2 = 'N') or (l_doNOTcall_updateCPoint1 = 'N')) then
   l_doNOTcall_updateCPoint := 'N';   
 end if;


 if (l_doNOTcall_updateCPoint = 'N') then

  p_contact_point_rec.contact_point_id := contact_point_id_phone;
  p_phone_rec.phone_area_code := p_phone_area_code;
  p_phone_rec.phone_country_code := p_phone_country_code;
  p_phone_rec.phone_number := p_phone_number;
  p_phone_rec.phone_extension := p_phone_extension;

  p_object_version_number_phone := obj_ver_num_phone;

  hz_contact_point_v2pub.update_contact_point(
  'T',
  p_contact_point_rec,
  p_edi_rec,
  p_email_rec,
  p_phone_rec,
  p_telex_rec,
  p_web_rec,
  p_object_version_number_phone,
  x_return_status_contact_point,
  x_msg_count_contact_point,
  x_msg_data_contact_point);

  IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
   RAISE invalid_upd_Sales_cpoints_exp;
  END IF;

 end if;

 x_return_status_contact_point := 'S';
 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';


 if (contact_point_id_email is null) then

  -- call create api for email CP

  if (trim(p_email_address) IS NOT NULL) then

   p_contact_point_rec_for_email.contact_point_type := 'EMAIL';
   p_contact_point_rec_for_email.owner_table_name := 'HZ_PARTIES';
   p_contact_point_rec_for_email.owner_table_id := l_owner_table_id;
   p_contact_point_rec_for_email.primary_flag := 'Y';
   p_contact_point_rec_for_email.contact_point_purpose := 'BUSINESS';
   p_contact_point_rec_for_email.created_by_module := 'HZ_CPUI';

   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;

   XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

   IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
    FND_MSG_PUB.ADD;
    RAISE invalid_email_add_exp;
   END IF;

   hz_contact_point_v2pub.create_contact_point(
   'T',
   p_contact_point_rec_for_email,
   p_edi_rec,
   p_email_rec,
   p_phone_rec_dummy,
   p_telex_rec,
   p_web_rec,
   x_contact_point_id,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);
  
   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_upd_Sales_cpoints_exp;
   END IF;
    
  end if;

 else -- if (contact_point_id_email is null) then

  if ((trim(p_email_address) is null) and (l_email_address is null)) then
   l_doNOTcall_updateCPoint := 'Y';
  end if;
  if ((trim(p_email_address) is null) and (l_email_address is not null)) then
   l_doNOTcall_updateCPoint := 'N';
  end if;
  if ((trim(p_email_address) is not null) and (l_email_address is null)) then
   l_doNOTcall_updateCPoint := 'N';
  end if;
  if ((trim(p_email_address) is not null) and (l_email_address is not null)) then
  if (p_email_address <> l_email_address) then
   l_doNOTcall_updateCPoint := 'N';
  end if; end if;

  if (trim(p_email_address) is not null) then

   p_contact_point_rec_for_email.contact_point_id := contact_point_id_email;
   p_contact_point_rec_for_email.contact_point_type := 'EMAIL'; 
   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;
     
   XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => p_contact_point_rec_for_email,
               p_edi_rec            => l_edi_rec_nab,
               p_email_rec          => p_email_rec,
               p_phone_rec          => l_phone_rec_nab,
               p_telex_rec          => l_telex_rec_nab,
               p_web_rec            => l_web_rec_nab,
               x_return_status      => l_return_status_nab,
               x_msg_count          => l_msg_count_nab,
               x_msg_data           => l_msg_data_nab);

   IF l_return_status_nab <> FND_API.G_RET_STS_SUCCESS THEN
     FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
     FND_MSG_PUB.ADD;
     RAISE invalid_email_add_exp;
   END IF;
  end if;

  if (l_doNOTcall_updateCPoint = 'N') then

   p_contact_point_rec_for_email.contact_point_id := contact_point_id_email;
   p_contact_point_rec_for_email.contact_point_type := 'EMAIL'; 
   p_email_rec.email_format := 'MAILHTML';
   p_email_rec.email_address := p_email_address;
   p_object_version_number_email := obj_ver_num_email;

   if (trim(p_email_address) is null) then
    p_email_rec.email_address := l_email_address;
    p_contact_point_rec_for_email.status := 'D';
   end if;

   
   hz_contact_point_v2pub.update_contact_point(
   'T',
   p_contact_point_rec_for_email,
   p_edi_rec,
   p_email_rec,
   p_phone_rec_dummy,
   p_telex_rec,
   p_web_rec,
   p_object_version_number_email,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);

   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
      RAISE invalid_upd_Sales_cpoints_exp;
   END IF;
 
   if (trim(p_email_address) is null) then
     update hz_parties set email_address = null where party_id = l_owner_table_id;
   end if;
   
  end if;
 end if; -- if (contact_point_id_email is null) then


 x_return_status_contact_point := 'S';
 l_doNOTcall_updateCPoint  := 'Y';
 l_doNOTcall_updateCPoint1 := 'Y';
 l_doNOTcall_updateCPoint2 := 'Y';
 l_doNOTcall_updateCPoint3 := 'Y';
 l_doNOTcall_updateCPoint4 := 'Y';


 if (contact_point_id_fax is null) then

  -- call create api for fax CP

  if ((trim(p_fax_area_code) is not null) and (trim(p_fax_number) is not null)) then

   p_contact_point_rec_for_fax.contact_point_type := 'PHONE';
   p_contact_point_rec_for_fax.owner_table_name := 'HZ_PARTIES';
   p_contact_point_rec_for_fax.owner_table_id := l_owner_table_id;
   p_contact_point_rec_for_fax.primary_flag := 'N';
   p_contact_point_rec_for_fax.contact_point_purpose := 'BUSINESS';
   p_contact_point_rec_for_fax.created_by_module := 'HZ_CPUI';

   p_fax_rec.phone_area_code := p_fax_area_code;
   p_fax_rec.phone_country_code := p_fax_country_code;
   p_fax_rec.phone_number := p_fax_number;
   p_fax_rec.phone_line_type := 'FAX';

   hz_contact_point_v2pub.create_contact_point(
   'T',
   p_contact_point_rec_for_fax,
   p_edi_rec,
   p_email_rec_dummy,
   p_fax_rec,
   p_telex_rec,
   p_web_rec,
   x_contact_point_id,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);

   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_upd_Sales_cpoints_exp;
   END IF;

  end if;

 else -- if (contact_point_id_fax is null) then

  if ((trim(p_fax_area_code) is null) and (l_fax_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'Y';
  end if;
  if ((trim(p_fax_area_code) is null) and (l_fax_area_code is not null)) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if;
  if ((trim(p_fax_area_code) is not null) and (l_fax_area_code is null)) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if;
  if ((trim(p_fax_area_code) is not null) and (l_fax_area_code is not null)) then
  if (p_fax_area_code <> l_fax_area_code) then
   l_doNOTcall_updateCPoint1 := 'N';
  end if; end if;


  if ((trim(p_fax_country_code) is null) and (l_fax_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'Y';
  end if;
  if ((trim(p_fax_country_code) is null) and (l_fax_country_code is not null)) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if;
  if ((trim(p_fax_country_code) is not null) and (l_fax_country_code is null)) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if;
  if ((trim(p_fax_country_code) is not null) and (l_fax_country_code is not null)) then
  if (p_fax_country_code <> l_fax_country_code) then
   l_doNOTcall_updateCPoint2 := 'N';
  end if; end if;


  if ((trim(p_fax_number) is null) and (l_fax_number is null)) then
   l_doNOTcall_updateCPoint3 := 'Y';
  end if;
  if ((trim(p_fax_number) is null) and (l_fax_number is not null)) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if;
  if ((trim(p_fax_number) is not null) and (l_fax_number is null)) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if;
  if ((trim(p_fax_number) is not null) and (l_fax_number is not null)) then
  if (p_fax_number <> l_fax_number) then
   l_doNOTcall_updateCPoint3 := 'N';
  end if; end if;


  if ((l_doNOTcall_updateCPoint3 = 'N') or (l_doNOTcall_updateCPoint2 = 'N') or (l_doNOTcall_updateCPoint1 = 'N')) then
   l_doNOTcall_updateCPoint := 'N';   
  end if;


  if (l_doNOTcall_updateCPoint = 'N') then

   p_contact_point_rec_for_fax.contact_point_id := contact_point_id_fax;

   p_fax_rec.phone_area_code := p_fax_area_code;
   p_fax_rec.phone_country_code := p_fax_country_code;
   p_fax_rec.phone_number := p_fax_number;

   p_object_version_number_fax := obj_ver_num_fax;

   hz_contact_point_v2pub.update_contact_point(
   'T',
   p_contact_point_rec_for_fax,
   p_edi_rec,
   p_email_rec_dummy,
   p_fax_rec,
   p_telex_rec,
   p_web_rec,
   p_object_version_number_fax,
   x_return_status_contact_point,
   x_msg_count_contact_point,
   x_msg_data_contact_point);

   IF x_return_status_contact_point <> FND_API.G_RET_STS_SUCCESS THEN       
    RAISE invalid_upd_Sales_cpoints_exp;
   END IF;

  end if;
 end if; -- if (contact_point_id_fax is null) then

-------------------------------------------------------------------------------------------------------------------

EXCEPTION

----------------- Exceptions for the api: Update_Org_SalesContact -------------------------------------------------

 WHEN invalid_update_Sales_per_exp THEN
        ROLLBACK TO Update_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	-- (if needed) FND_MESSAGE.SET_NAME('AR', 'HZ_API_DUPLICATE_COLUMN');
        -- (if needed) FND_MESSAGE.SET_TOKEN('COLUMN', 'org_contact_id');
        -- (if needed) FND_MSG_PUB.ADD;
        FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_update_person,
                                  p_data  => x_msg_data_update_person);

 WHEN invalid_upd_Sales_cpoints_exp THEN
        ROLLBACK TO Update_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count_contact_point,
                                  p_data  => x_msg_data_contact_point);

 WHEN invalid_email_add_exp THEN
        ROLLBACK TO Update_Org_SalesContact;
        x_return_status := FND_API.G_RET_STS_ERROR;
	FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => l_msg_count_nab,
                                  p_data  => l_msg_data_nab);

 WHEN OTHERS THEN
    ROLLBACK TO Update_Org_SalesContact;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'Error in procedure Update_Org_SalesContact. The error mesage: '||sqlerrm;

----------------- Exceptions for the api: Update_Org_SalesContact -------------------------------------------------

END Update_Org_SalesContact;

END XX_SFA_CONTACT_CREATE_PKG ;
/
--SHOW ERRORS;