CREATE OR REPLACE PACKAGE BODY XX_ASL_ACC_CRT_UTIL_PKG IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name             : XX_ASL_ACC_CRT_UTIL_PKG                        |
-- | Description      : Package Body containing procedure to           |
-- |                    create parties,sites, contacts and phone       |
-- |                    used for offline account creation              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-SEP-2006   Sreekanth-Rao    Initial draft version    |
-- |1          24-NOV-2006   Sreekanth-Rao    Changes after online acct|
-- |                                          redesign sessions        |
-- |2.0        18-Dec-2007   Rajeev Kamath    Added support for ext.   |
-- |3.0        24-Dec-2007   Sreekanth Rao    WCW fix for ext attr,    |
-- |                                          redesign sessions        |
-- |4.0        11-Mar-2008   Sathya Prabha    Removed "Country"        |
-- |                                          hardcoding from address. |
-- |5.0        21-Mar-2008   Sathya Prabha    Integrating Autonamed.   |
-- +===================================================================+


--This Function will be used by the JSP to call the party, sites, contact and phone entities
PROCEDURE P_Create_Entities(
    p_org_name                   IN     HZ_PARTIES.party_name%type,
    p_bt_country                 IN     HZ_PARTIES.country%type,
    p_person_title               IN     HZ_PARTIES.person_pre_name_adjunct%type,
    p_person_first_name          IN     HZ_PARTIES.person_first_name%type,
    p_person_middle_name         IN     HZ_PARTIES.person_middle_name%type,
    p_person_last_name           IN     HZ_PARTIES.person_last_name%type,
    p_bt_address1                IN     HZ_LOCATIONS.address1%type,
    p_bt_address2                IN     HZ_LOCATIONS.address2%type,
    p_bt_address3                IN     HZ_LOCATIONS.address3%type,
    p_bt_address4                IN     HZ_LOCATIONS.address4%type,
    p_bt_city                    IN     HZ_LOCATIONS.city%type,
    p_bt_county                  IN     HZ_LOCATIONS.county%type,
    p_bt_state                   IN     HZ_LOCATIONS.state%type,
    p_bt_postal_code             IN     HZ_LOCATIONS.postal_code%type,
    p_bt_address_style           IN     HZ_LOCATIONS.address_style%type,
    p_bt_address_lines_phonetic  IN     HZ_LOCATIONS.address_lines_phonetic%type,
    p_bt_addressee               IN     HZ_PARTY_SITES.addressee%type,
    p_bt_od_wcw                  IN     NUMBER,
    p_st_address1                IN     HZ_LOCATIONS.address1%type,
    p_st_address2                IN     HZ_LOCATIONS.address2%type,
    p_st_address3                IN     HZ_LOCATIONS.address3%type,
    p_st_address4                IN     HZ_LOCATIONS.address4%type,
    p_st_city                    IN     HZ_LOCATIONS.city%type,
    p_st_county                  IN     HZ_LOCATIONS.county%type,
    p_st_state                   IN     HZ_LOCATIONS.state%type,
    p_st_postal_code             IN     HZ_LOCATIONS.postal_code%type,
    p_st_country                 IN     HZ_PARTIES.country%type,
    p_st_address_style           IN     HZ_LOCATIONS.address_style%type,
    p_st_addressee               IN     HZ_PARTY_SITES.addressee%type,
    p_st_address_lines_phonetic  IN     HZ_LOCATIONS.address_lines_phonetic%type,
    p_st_od_wcw                  IN     NUMBER,
    p_phone_ccode                IN     HZ_CONTACT_POINTS.phone_country_code%type,
    p_phone_acode                IN     HZ_CONTACT_POINTS.phone_area_code%type,
    p_phone_number               IN     HZ_CONTACT_POINTS.phone_number%type,
    p_phone_ext                  IN     HZ_CONTACT_POINTS.phone_extension%type,
    x_org_party_id               OUT    NOCOPY  NUMBER,
    x_org_contact_id             OUT    NOCOPY  NUMBER,
    x_org_contact_party_id       OUT    NOCOPY  NUMBER,
    x_billto_site_id             OUT    NOCOPY  NUMBER,
    x_shipto_site_id             OUT    NOCOPY  NUMBER,
    x_return_status              OUT    NOCOPY VARCHAR2,
    x_error_message              OUT    NOCOPY VARCHAR2) IS

   lc_error_desc               VARCHAR2(4000);
   lr_organization_rec         hz_party_v2pub.organization_rec_type;
   lr_person_rec               hz_party_v2pub.person_rec_type;
   lr_contact_rec              HZ_PARTY_CONTACT_V2PUB.org_contact_rec_type;
   lr_contact_point_rec        hz_contact_point_v2pub.contact_point_rec_type;
   lr_phone_rec                hz_contact_point_v2pub.phone_rec_type;
   l_bt_site_demo_rec          SITE_DEMOGRAPHICS_REC;
   l_st_site_demo_rec          SITE_DEMOGRAPHICS_REC;

   ln_org_party_id             HZ_PARTIES.party_id%type;
   ln_org_party_number         HZ_PARTIES.party_number%type;
   ln_org_profile_id           NUMBER;
   ln_pers_party_id            NUMBER;
   lc_pers_party_number        HZ_PARTIES.party_number%type;
   ln_pers_profile_id          NUMBER;
   ln_org_contact_id           HZ_PARTIES.party_id%type;
   ln_party_reln_id            NUMBER;
   ln_cntct_party_id           NUMBER;
   lc_cntct_party_number       HZ_PARTIES.party_id%type;
   ln_bt_location_id           NUMBER;
   ln_bt_party_site_id         NUMBER;
   ln_bt_party_site_number     NUMBER;
   ln_bt_party_site_use_id     NUMBER;
   ln_bt_party_site_use_no     NUMBER;
   ln_st_location_id           NUMBER;
   ln_st_party_site_id         NUMBER;
   ln_st_party_site_number     NUMBER;
   ln_st_party_site_use_id     NUMBER;
   ln_st_party_site_use_no     NUMBER;
   ln_contact_point_id         NUMBER;
   ln_msg_count                NUMBER;
   lc_msg_data                 VARCHAR2(4000);

BEGIN

--Create Organization

  lr_organization_rec.organization_name  := p_org_name;
  lr_organization_rec.created_by_module  :='ASL';
  lr_organization_rec.party_rec.attribute_category  :=p_bt_country;
  lr_organization_rec.party_rec.attribute13  :='PROSPECT';

 hz_party_v2pub.create_organization
(
             p_init_msg_list      => FND_API.g_true,
             p_organization_rec   => lr_organization_rec,
             x_return_status      => x_return_status,
             x_msg_count          => ln_msg_count,
             x_msg_data           => lc_msg_data,
             x_party_id           => ln_org_party_id,
             x_party_number       => ln_org_party_number,
             x_profile_id         => ln_org_profile_id);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        END IF;


IF p_person_first_name IS NOT NULL OR p_person_last_name IS NOT NULL THEN
--Create Person
  lr_person_rec.person_pre_name_adjunct := p_person_title;
  lr_person_rec.person_first_name       := p_person_first_name;
  lr_person_rec.person_middle_name      := p_person_middle_name;
  lr_person_rec.person_last_name        := p_person_last_name;
  lr_person_rec.created_by_module       := 'ASL';

  hz_party_v2pub.create_person (
             p_init_msg_list      => FND_API.g_true,
             p_person_rec         => lr_person_rec,
             x_party_id           => ln_pers_party_id,
             x_party_number       => lc_pers_party_number,
             x_profile_id         => ln_pers_profile_id,
             x_return_status      => x_return_status,
             x_msg_count          => ln_msg_count,
             x_msg_data           => lc_msg_data);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        END IF;

--Create Organization Contact
  lr_contact_rec.created_by_module                := 'ASL';
  lr_contact_rec.party_rel_rec.SUBJECT_ID         := ln_org_party_id;
  lr_contact_rec.party_rel_rec.SUBJECT_TYPE       := 'ORGANIZATION';
  lr_contact_rec.party_rel_rec.SUBJECT_TABLE_NAME := 'HZ_PARTIES';
  lr_contact_rec.party_rel_rec.OBJECT_ID          := ln_pers_party_id;
  lr_contact_rec.party_rel_rec.OBJECT_TYPE        := 'PERSON';
  lr_contact_rec.party_rel_rec.OBJECT_TABLE_NAME  := 'HZ_PARTIES';
  lr_contact_rec.party_rel_rec.RELATIONSHIP_CODE  := 'CONTACT';
  lr_contact_rec.party_rel_rec.RELATIONSHIP_TYPE  := 'CONTACT';
  lr_contact_rec.party_rel_rec.START_DATE         := sysdate;
  lr_contact_rec.party_rel_rec.STATUS             := 'A';
  lr_contact_rec.party_rel_rec.created_by_module  := 'ASL';

    HZ_PARTY_CONTACT_V2PUB.create_org_contact(
              p_init_msg_list      => FND_API.g_true,
              p_org_contact_rec    => lr_contact_rec,
              x_org_contact_id     => ln_org_contact_id,
              x_party_rel_id       => ln_party_reln_id,
              x_party_id           => ln_cntct_party_id,
              x_party_number       => lc_cntct_party_number,
              x_return_status      => x_return_status,
              x_msg_count          => ln_msg_count,
              x_msg_data           => lc_msg_data);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        END IF;

END IF; --p_person_first_name IS NOT NULL OR p_person_last_name IS NOT NULL THEN

--Create Bill to Site
    P_Create_Address (
                      p_party_id                 => ln_org_party_id,
                      p_site_use_type            => 'BILL_TO',
                      p_address1                 => p_bt_address1,
                      p_address2                 => p_bt_address2,
                      p_address3                 => p_bt_address3,
                      p_address4                 => p_bt_address4,
                      p_city                     => p_bt_city,
                      p_county                   => p_bt_county,
                      p_state                    => p_bt_state,
                      p_postal_code              => p_bt_postal_code,
                      p_country                  => p_bt_country,
                      p_address_style            => p_bt_address_style,
                      p_address_lines_phonetic   => p_bt_address_lines_phonetic,
                      p_addressee                => p_bt_addressee,
                      x_party_site_id            => ln_bt_party_site_id,
                      x_return_status            => x_return_status,
                      x_error_message            => x_error_message);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        ELSE

          l_bt_site_demo_rec.RECORD_ID   := 10;
          l_bt_site_demo_rec.N_EXT_ATTR8 := p_bt_od_wcw;

          process_site_demographics
                  ( p_party_site_id   => ln_bt_party_site_id,
                    p_site_demo_rec   => l_bt_site_demo_rec,
                    x_return_msg      => lc_msg_data
                  );

            x_error_message := x_error_message|| lc_msg_data;
            
          -- Call to Autonamed
    
          XX_JTF_SALES_REP_PTY_SITE_CRTN.create_party_site(p_party_site_id => ln_bt_party_site_id);
        
        END IF;

IF p_st_address1 IS NOT NULL THEN
--Create Ship to Site
    P_Create_Address (
                      p_party_id                 => ln_org_party_id,
                      p_site_use_type            => 'SHIP_TO',
                      p_address1                 => p_st_address1,
                      p_address2                 => p_st_address2,
                      p_address3                 => p_st_address3,
                      p_address4                 => p_st_address4,
                      p_city                     => p_st_city,
                      p_county                   => p_st_county,
                      p_state                    => p_st_state,
                      p_postal_code              => p_st_postal_code,
                      p_country                  => p_st_country,
                      p_address_style            => p_st_address_style,
                      p_address_lines_phonetic   => p_st_address_lines_phonetic,
                      p_addressee                => p_st_addressee,
                      x_party_site_id            => ln_st_party_site_id,
                      x_return_status            => x_return_status,
                      x_error_message            => x_error_message);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;
            x_error_message := x_error_message|| lc_msg_data;

        ELSE
          l_st_site_demo_rec.RECORD_ID   := 20;
          l_st_site_demo_rec.N_EXT_ATTR8 := p_st_od_wcw;

          process_site_demographics
                  ( p_party_site_id   => ln_st_party_site_id,
                    p_site_demo_rec   => l_st_site_demo_rec,
                    x_return_msg      => lc_msg_data
                  );
            x_error_message := x_error_message|| lc_msg_data;
            
            -- Call to Autonamed
        
            XX_JTF_SALES_REP_PTY_SITE_CRTN.create_party_site(p_party_site_id => ln_st_party_site_id);
        
        END IF;

END IF; --p_st_address1 IS NOT NULL THEN

--Create Contact Point
    lr_contact_point_rec.created_by_module      := 'ASL';
    lr_contact_point_rec.contact_point_type     := 'PHONE';
    lr_contact_point_rec.status                 := 'A';
    lr_contact_point_rec.owner_table_name       := 'HZ_PARTIES';
    lr_contact_point_rec.owner_table_id         := ln_cntct_party_id;
    lr_contact_point_rec.primary_flag           := 'Y';
    lr_contact_point_rec.contact_point_purpose  := 'BUSINESS';
    lr_contact_point_rec.primary_by_purpose     := 'Y';
    lr_contact_point_rec.actual_content_source  := 'USER_ENTERED';

    lr_phone_rec.phone_country_code           := p_phone_ccode;
    lr_phone_rec.phone_area_code              := p_phone_acode;
    lr_phone_rec.phone_number                 := p_phone_number;
    lr_phone_rec.phone_extension              := p_phone_ext;
    lr_phone_rec.phone_line_type              :='GEN';

IF p_phone_number IS NOT NULL THEN

hz_contact_point_v2pub.create_phone_contact_point (
              p_init_msg_list      => fnd_api.g_true,
              p_contact_point_rec  => lr_contact_point_rec,
              p_phone_rec          => lr_phone_rec,
              x_contact_point_id   => ln_contact_point_id,
              x_return_status      => x_return_status,
              x_msg_count          => ln_msg_count,
              x_msg_data           => lc_msg_data);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        END IF;

END IF;-- p_phone_number IS NOT NULL OR THEN

X_ORG_PARTY_ID         := ln_org_party_id;
X_ORG_CONTACT_PARTY_ID := ln_cntct_party_id;
X_BILLTO_SITE_ID       := ln_bt_party_site_id;
X_SHIPTO_SITE_ID       := ln_st_party_site_id;
--x_person_party_id      := ln_pers_party_id;
x_org_contact_id      := ln_org_contact_id;

--COMMIT;

EXCEPTION WHEN OTHERS THEN
x_return_status := 'E';
x_error_message  := 'Exception while creating entities: '||sqlcode||' '||sqlerrm;
END P_Create_Entities;

PROCEDURE P_Create_Address (
    p_party_id                 IN     NUMBER,
    p_site_use_type            IN     HZ_PARTY_SITE_USES.site_use_type%type,
    p_address1                 IN     HZ_LOCATIONS.address1%type,
    p_address2                 IN     HZ_LOCATIONS.address2%type,
    p_address3                 IN     HZ_LOCATIONS.address3%type,
    p_address4                 IN     HZ_LOCATIONS.address4%type,
    p_city                     IN     HZ_LOCATIONS.city%type,
    p_county                   IN     HZ_LOCATIONS.county%type,
    p_state                    IN     HZ_LOCATIONS.state%type,
    p_postal_code              IN     HZ_LOCATIONS.postal_code%type,
    p_country                  IN     HZ_PARTIES.country%type,
    p_address_style            IN     HZ_LOCATIONS.address_style%type,
    p_address_lines_phonetic   IN     HZ_LOCATIONS.address_lines_phonetic%type,
    p_addressee                IN     HZ_PARTY_SITES.addressee%type,
    x_party_site_id            OUT    NOCOPY NUMBER,
    x_return_status            OUT    NOCOPY VARCHAR2,
    x_error_message            OUT    NOCOPY VARCHAR2)    IS

 lr_location_rec           hz_location_v2pub.location_rec_type;
 lr_party_site_rec         hz_party_site_v2pub.party_site_rec_type;
 lr_party_site_use_rec     hz_party_site_v2pub.party_site_use_rec_type;
 ln_location_id            NUMBER;
 ln_party_site_id          NUMBER;
 lc_party_site_number      HZ_PARTY_SITES.party_site_number%type;
 ln_msg_count              NUMBER;
 lc_msg_data               VARCHAR2(4000);
 ln_party_site_use_id      NUMBER;


BEGIN

SAVEPOINT CREATE_ADDRESS;

--Create Location
      lr_location_rec.created_by_module := 'ASL';
     -- lr_location_rec.country           := 'US';
      lr_location_rec.country           := p_country;
      lr_location_rec.address1          := p_address1;
      lr_location_rec.address2          := p_address2;
      lr_location_rec.address3          := p_address3;
      lr_location_rec.address4          := p_address4;
      lr_location_rec.city              := p_city;
      lr_location_rec.postal_code       := p_postal_code;
     -- lr_location_rec.state             := p_state;
      lr_location_rec.county            := p_county;


      IF p_country = 'US' THEN
        lr_location_rec.state          := p_state;
      ELSIF p_country = 'CA' THEN
        lr_location_rec.province       := p_state;
      END IF;

--    address_style               :=
--    address_lines_phonetic      :=
--    postal_plus4_code           :=
--    address_effective_date      :=
--    language                    :=
      lr_location_rec.address_lines_phonetic := p_address_lines_phonetic ;--alternate name

    HZ_LOCATION_V2PUB.create_location (
             p_init_msg_list         => FND_API.g_true,
             p_location_rec          => lr_location_rec,
             x_location_id           => ln_location_id,
             x_return_status         => x_return_status,
             x_msg_count             => ln_msg_count,
             x_msg_data              => lc_msg_data);

        IF x_return_status <> 'S' then

          FOR i IN 1..ln_msg_count
          LOOP
              lc_msg_data:=lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
          END LOOP;

            x_error_message := x_error_message|| lc_msg_data;
        END IF;

--Create Bill to Party Site

 lr_party_site_rec.PARTY_ID                 := p_party_id;
 lr_party_site_rec.LOCATION_ID              := ln_location_id;
 lr_party_site_rec.STATUS                   := 'A';
 lr_party_site_rec.ADDRESSEE                := p_addressee;
 lr_party_site_rec.CREATED_BY_MODULE        := 'ASL';

Hz_Party_Site_V2pub.Create_Party_Site(
             p_init_msg_list         => FND_API.g_true,
             p_party_site_rec        => lr_party_site_rec,
             x_party_site_id         => ln_party_site_id,
             x_party_site_number     => lc_party_site_number,
             x_return_status         => x_return_status,
             x_msg_count             => ln_msg_count,
             x_msg_data              => lc_msg_data);

        IF x_return_status <> 'S' then
           FOR i IN 1..ln_msg_count
           LOOP
             lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
           END LOOP;
           SELECT
              nvl(decode(x_error_message,NULL,'',x_error_message||chr(10))||'Error creating Party Site '||lc_msg_data,'')
           INTO
              x_error_message
           FROM
              dual;
           ROLLBACK TO CREATE_ADDRESS;
        END IF;

--Create Bill to Party Site Use
 lr_party_site_use_rec.SITE_USE_TYPE      := p_site_use_type;
 lr_party_site_use_rec.PARTY_SITE_ID      := ln_party_site_id;
 lr_party_site_use_rec.PRIMARY_PER_TYPE   := 'Y';
 lr_party_site_use_rec.STATUS             := 'A';
 lr_party_site_use_rec.CREATED_BY_MODULE  := 'ASL';

Hz_Party_Site_V2pub.Create_Party_Site_Use(
             p_init_msg_list         => FND_API.g_true,
             p_party_site_use_rec    => lr_party_site_use_rec,
             x_party_site_use_id     => ln_party_site_use_id,
             x_return_status         => x_return_status,
             x_msg_count             => ln_msg_count,
             x_msg_data              => lc_msg_data);

        IF x_return_status <> 'S' then
           FOR i IN 1..ln_msg_count
           LOOP
             lc_msg_data := lc_msg_data||Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
           END LOOP;
           SELECT
              nvl(decode(x_error_message,NULL,'',x_error_message||chr(10))||'Error creating Party Site '||lc_msg_data,'')
           INTO
              x_error_message
           FROM
              dual;
           ROLLBACK TO CREATE_ADDRESS;
        END IF;
        x_party_site_id := ln_party_site_id;

EXCEPTION WHEN OTHERS THEN
x_return_status   := 'E';
x_error_message   := 'Exception in P_Create_Address'||sqlcode||' '||sqlerrm;
END P_Create_Address;

-- +===================================================================+
-- | Name        :  PROCESS_SITE_DEMOGRAPHICS                          |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_SITE_DEMOGRAPHICS
   (   p_party_site_id   IN   NUMBER,
       p_site_demo_rec   IN   SITE_DEMOGRAPHICS_REC,
       x_return_msg     OUT   VARCHAR2
   )
IS
   le_exception                  EXCEPTION;
   ln_party_site_id              NUMBER;
   lc_user_table                 EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_temp_user_table            EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
   lc_row_temp_obj               EGO_USER_ATTR_ROW_OBJ    := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);
   lc_data_table                 EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_temp_data_table            EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
   lc_data_temp_obj              EGO_USER_ATTR_DATA_OBJ   := EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
   ln_retcode                    NUMBER;
   ln_errbuf                     VARCHAR2(2000);
   lc_rowid                      VARCHAR2(100);
   l_failed_row_id_list          VARCHAR2(1000);
   l_return_status               VARCHAR2(1000);
   l_errorcode                   NUMBER;
   l_msg_count                   NUMBER;
   l_msg_data                    VARCHAR2(1000);
   lv_return_msg                 VARCHAR2(1000);
   l_errors_tbl                  ERROR_HANDLER.Error_Tbl_Type;
   ln_msg_text                   VARCHAR2(32000);
   l_site_demo_rec               SITE_DEMOGRAPHICS_REC;

BEGIN

   ln_party_site_id := p_party_site_id;

   IF ln_party_site_id IS NULL THEN
      x_return_msg := 'Party Site Id is not Provided';
      RAISE le_exception;
   END IF;

   l_site_demo_rec := p_site_demo_rec;

   build_extensible_table
      (  p_user_row_table        => lc_user_table,
         p_user_data_table       => lc_data_table,
         p_ext_attribs_row       => l_site_demo_rec,
         x_return_msg            => lv_return_msg
      );

   IF lv_return_msg IS NOT NULL THEN
      x_return_msg := lv_return_msg;
      RAISE le_exception;
   END IF;

   HZ_EXTENSIBILITY_PUB.process_partysite_record
      (  p_api_version           => xx_cdh_cust_exten_attri_pkg.g_api_version,
         p_party_site_id         => ln_party_site_id,
         p_attributes_row_table  => lc_user_table,
         p_attributes_data_table => lc_data_table,
         x_failed_row_id_list    => l_failed_row_id_list,
         x_return_status         => l_return_status,
         x_errorcode             => l_errorcode,
         x_msg_count             => l_msg_count,
         x_msg_data              => l_msg_data
      );

   IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
      x_return_msg := NULL;
      COMMIT;
   ELSE
      IF l_msg_count > 0 THEN
         ERROR_HANDLER.Get_Message_List(l_errors_tbl);
         FOR i IN 1..l_errors_tbl.COUNT
         LOOP
            ln_msg_text := ln_msg_text||' '||l_errors_tbl(i).message_text;
         END LOOP;
         x_return_msg := ln_msg_text;
       END IF;
    END IF;

EXCEPTION
   WHEN le_exception THEN
      NULL;
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error - '||SQLERRM;
END PROCESS_SITE_DEMOGRAPHICS;

-- +===================================================================+
-- | Name        :  Build_extensible_table                             |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_user_row_table is table structure contains the     |
-- |              Attribute group information                          |
-- |              p_user_data_table is table structure contains the    |
-- |              attribute columns informations                       |
-- |              p_ext_attribs_row is staging table row information   |
-- |              which needs to be create/updated to extensible attrs |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Build_extensible_table
      (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
          p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
          p_ext_attribs_row IN OUT SITE_DEMOGRAPHICS_REC,
          x_return_msg         OUT VARCHAR2
      )
IS

--Retrieve Attribute Group id based on the Attribute Group code and
-- Flexfleid Name
CURSOR c_ego_attr_grp_id ( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
IS
SELECT attr_group_id
FROM   ego_fnd_dsc_flx_ctx_ext
WHERE  descriptive_flexfield_name    = p_flexfleid_name
AND    descriptive_flex_context_code = p_context_code;


--
CURSOR c_ext_attr_name( p_flexfleid_name VARCHAR2, p_context_code VARCHAR2)
IS
SELECT *
FROM   fnd_descr_flex_column_usages
WHERE  descriptive_flexfield_name    = p_flexfleid_name
AND    descriptive_flex_context_code = p_context_code
AND    enabled_flag                  = 'Y';

TYPE l_xxod_ext_attribs_stg IS TABLE OF c_ext_attr_name%ROWTYPE INDEX BY BINARY_INTEGER;
lx_od_ext_attrib_stg        l_xxod_ext_attribs_stg;

lc_row_temp_obj             EGO_USER_ATTR_ROW_OBJ := EGO_USER_ATTR_ROW_OBJ(null,null,null,null,null,null,null,null,null);

lc_data_temp_obj            EGO_USER_ATTR_DATA_OBJ:= EGO_USER_ATTR_DATA_OBJ(null,null,null,null,null,null,null,null);
lc_count                    NUMBER:=1;
l_flexfleid_name            VARCHAR2(50);
l_attr_group_id             NUMBER;
lc_exception                EXCEPTION;


BEGIN

l_flexfleid_name := 'HZ_PARTY_SITES_GROUP';


OPEN  c_ego_attr_grp_id ( l_flexfleid_name,'SITE_DEMOGRAPHICS' );
FETCH c_ego_attr_grp_id INTO l_attr_group_id;
CLOSE c_ego_attr_grp_id;

IF l_attr_group_id IS NULL THEN
   x_return_msg := 'Attribute Group ''Site Demographics'' is not found';
   RAISE lc_exception;
END IF;

OPEN  c_ext_attr_name ( l_flexfleid_name,'SITE_DEMOGRAPHICS');
FETCH c_ext_attr_name BULK COLLECT INTO lx_od_ext_attrib_stg;
CLOSE c_ext_attr_name;

p_user_row_table.extend;
p_user_row_table(1)                  := lc_row_temp_obj;
p_user_row_table(1).Row_identifier   := P_ext_attribs_row.record_id;
p_user_row_table(1).Attr_group_id    := l_attr_group_id;
p_user_row_table(1).transaction_type := EGO_USER_ATTRS_DATA_PVT.G_SYNC_MODE;

FOR i IN 1 .. lx_od_ext_attrib_stg.COUNT
LOOP

   p_user_data_table.extend;
   p_user_data_table(i)                := lc_data_temp_obj;
   p_user_data_table(i).ROW_IDENTIFIER := P_EXT_ATTRIBS_ROW.record_id;
   p_user_data_table(i).ATTR_NAME      := lx_od_ext_attrib_stg(i).END_USER_COLUMN_NAME;

   IF lx_od_ext_attrib_stg(i).application_column_name ='C_EXT_ATTR1' THEN
      p_user_data_table(i).attr_value_str := p_ext_attribs_row.c_ext_attr1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR10;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR11' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR11;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR12' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR12;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR13' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR13;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR14' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR14;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR15' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR15;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR16' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR16;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR17' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR17;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR18' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR18;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR19' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR19;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='C_EXT_ATTR20' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_STR:=P_EXT_ATTRIBS_ROW.C_EXT_ATTR20;

   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR1' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR10;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR11' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR11;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR12' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR12;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR13' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR13;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR14' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR14;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR15' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR15;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR16' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR16;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR17' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR17;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR18' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR18;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR19' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR19;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='N_EXT_ATTR20' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_NUM:=P_EXT_ATTRIBS_ROW.N_EXT_ATTR20;

   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR1' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR1;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR2' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR2;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR3' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR3;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR4' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR4;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR5' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR5;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR6' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR6;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR7' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR7;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR8' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR8;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR9' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR9;
   ELSIF lx_od_ext_attrib_stg(i).APPLICATION_COLUMN_NAME ='D_EXT_ATTR10' THEN
       P_USER_DATA_TABLE(i).ATTR_VALUE_DATE:=P_EXT_ATTRIBS_ROW.D_EXT_ATTR10;
   END IF;
END LOOP;
EXCEPTION
   WHEN lc_exception THEN
      NULL;
   WHEN OTHERS THEN
      x_return_msg := 'Unexpected Error in Build Extensible Table'||SQLERRM;
END Build_extensible_table;

END XX_ASL_ACC_CRT_UTIL_PKG;
/
