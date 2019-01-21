CREATE OR REPLACE PACKAGE XX_ASL_ACC_CRT_UTIL_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name             : XX_ASL_ACC_CRT_UTIL_PKG                        |
-- | Description      : Package Specification containing procedure to  |
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
-- |                                          hardcoding from address  |
-- +===================================================================+

--This Function will be used by the JSP to call the party, sites, contact and phone entities

TYPE SITE_DEMOGRAPHICS_REC IS RECORD
   (
       RECORD_ID        NUMBER DEFAULT 10,
       C_EXT_ATTR1      VARCHAR2(150),
       C_EXT_ATTR2      VARCHAR2(150),
       C_EXT_ATTR3      VARCHAR2(150),
       C_EXT_ATTR4      VARCHAR2(150),
       C_EXT_ATTR5      VARCHAR2(150),
       C_EXT_ATTR6      VARCHAR2(150),
       C_EXT_ATTR7      VARCHAR2(150),
       C_EXT_ATTR8      VARCHAR2(150),
       C_EXT_ATTR9      VARCHAR2(150),
       C_EXT_ATTR10     VARCHAR2(150),
       C_EXT_ATTR11     VARCHAR2(150),
       C_EXT_ATTR12     VARCHAR2(150),
       C_EXT_ATTR13     VARCHAR2(150),
       C_EXT_ATTR14     VARCHAR2(150),
       C_EXT_ATTR15     VARCHAR2(150),
       C_EXT_ATTR16     VARCHAR2(150),
       C_EXT_ATTR17     VARCHAR2(150),
       C_EXT_ATTR18     VARCHAR2(150),
       C_EXT_ATTR19     VARCHAR2(150),
       C_EXT_ATTR20     VARCHAR2(150),
       N_EXT_ATTR1      NUMBER,
       N_EXT_ATTR2      NUMBER,
       N_EXT_ATTR3      NUMBER,
       N_EXT_ATTR4      NUMBER,
       N_EXT_ATTR5      NUMBER,
       N_EXT_ATTR6      NUMBER,
       N_EXT_ATTR7      NUMBER,
       N_EXT_ATTR8      NUMBER,
       N_EXT_ATTR9      NUMBER,
       N_EXT_ATTR10     NUMBER,
       N_EXT_ATTR11     NUMBER,
       N_EXT_ATTR12     NUMBER,
       N_EXT_ATTR13     NUMBER,
       N_EXT_ATTR14     NUMBER,
       N_EXT_ATTR15     NUMBER,
       N_EXT_ATTR16     NUMBER,
       N_EXT_ATTR17     NUMBER,
       N_EXT_ATTR18     NUMBER,
       N_EXT_ATTR19     NUMBER,
       N_EXT_ATTR20     NUMBER,
       D_EXT_ATTR1      DATE  ,
       D_EXT_ATTR2      DATE  ,
       D_EXT_ATTR3      DATE  ,
       D_EXT_ATTR4      DATE  ,
       D_EXT_ATTR5      DATE  ,
       D_EXT_ATTR6      DATE  ,
       D_EXT_ATTR7      DATE  ,
       D_EXT_ATTR8      DATE  ,
       D_EXT_ATTR9      DATE  ,
       D_EXT_ATTR10     DATE
   );

PROCEDURE process_site_demographics
   (   p_party_site_id   IN   NUMBER,
       p_site_demo_rec   IN   SITE_DEMOGRAPHICS_REC,
       x_return_msg     OUT   VARCHAR2
   );

PROCEDURE Build_extensible_table
  (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
      p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
      p_ext_attribs_row IN OUT SITE_DEMOGRAPHICS_REC,
      x_return_msg         OUT VARCHAR2
  );


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
    x_error_message              OUT    NOCOPY VARCHAR2);

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
    x_error_message            OUT    NOCOPY VARCHAR2);

END XX_ASL_ACC_CRT_UTIL_PKG;
/
