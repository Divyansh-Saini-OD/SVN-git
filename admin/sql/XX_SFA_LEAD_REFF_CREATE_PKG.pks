CREATE OR REPLACE
PACKAGE
XX_SFA_LEAD_REFF_CREATE_PKG
AS

TYPE SITE_CONTACTS_REC IS RECORD
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


-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEAD_REFF_CREATE_PKG                         |
-- | Description      :Create leads referred through Lead Referral Form    |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |  1.0   23-Dec-10       Renupriya                                      |
-- +=======================================================================+

PROCEDURE XX_LEAD_CREATE (
         x_errbuf    OUT NOCOPY VARCHAR2
        ,x_retcode  OUT NOCOPY NUMBER);

-- +===================================================================+
-- | Name        :  PROCESS_SITE_CONTACTS                              |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_SITE_CONTACTS
   (    p_party_site_id      IN   NUMBER
       ,p_site_contact_rec   IN   SITE_CONTACTS_REC
       ,x_return_msg         OUT  VARCHAR2
   );

-- +===================================================================+
-- | Name        :  PROCESS_SITE_DEMOGRAPHICS                              |
-- | Description :  This procedure is used to construct the table      |
-- |                Structure used by the extensiable api's.           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE process_site_demographics
   (   p_party_site_id   IN   NUMBER,
       p_site_demo_rec   IN   SITE_DEMOGRAPHICS_REC,
       x_return_msg     OUT   VARCHAR2
   );
-- +===================================================================+
-- | Name        :  Build_ext_table_site_contact                             |
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
PROCEDURE Build_ext_table_site_contact
      (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE
          ,p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE
          ,p_ext_attribs_row IN OUT SITE_CONTACTS_REC
          ,x_return_msg      OUT    VARCHAR2
      );

-- +===================================================================+
-- | Name        :  Build_ext_table_site_demo                             |
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
PROCEDURE Build_ext_table_site_demo
  (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
      p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
      p_ext_attribs_row IN OUT SITE_DEMOGRAPHICS_REC,
      x_return_msg         OUT VARCHAR2
  );
-- +===================================================================+
-- | Name        :  update_mask_email                                  |
-- | Description :  This procedure is used to send email to the        |
-- |                respective sales person about leads assigned       |
-- |                to them                                            |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_email contains email of sales person               |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_mask_email
      (   x_errbuf OUT VARCHAR2
        , x_retcode OUT VARCHAR2
	, p_req_id IN VARCHAR2
	, p_mask_email IN VARCHAR2
      );

-- +===================================================================+
-- | Name        :  lead_ref_email                                     |
-- | Description :  This procedure is used to send email to the        |
-- |                respective sales person about leads assigned       |
-- |                to them                                            |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |              p_email contains email of sales person               |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lead_ref_email
          ( x_errbuf OUT VARCHAR2
	  , x_retcode OUT VARCHAR2
	  , p_req_id IN VARCHAR2);


-- +===================================================================+
-- | Name        :  lead_ref_process_main                              |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lead_ref_process_main
          ( x_errbuf OUT VARCHAR2
	  , x_retcode OUT VARCHAR2);


END XX_SFA_LEAD_REFF_CREATE_PKG;

/
SHO ERROR