create or replace PACKAGE  XX_CRM_PROSPECT_LEAD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XX_CRM_PROSPECT_LEAD_PKG                     |
-- | Description      :  This package contains functions which are     |
-- |                     called by                                     |
-- |                     XXTPS_FILE_UPLOADS_PKG.XXTPS_FILE_UPLOAD      |
-- |                     depending on the template code. These         |
-- |                     functions validate the data and insert it     |
-- |                     into appropriate tables.                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      11-JUN-2010 Mangalasundari K    Created the package body  |
-- |                     Wipro Technologies                            |
-- |1.1      31-MAY-2016 Shubhashree R       Removed the procedure     |
-- |                                         XX_CRM_CUST_LEADS_TMPLT   |
-- |                                         for TOPS Retirement       |
-- +===================================================================+
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
      (   p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE
          ,p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE
          ,p_ext_attribs_row IN OUT SITE_CONTACTS_REC
          ,x_return_msg      OUT    VARCHAR2
      );

END XX_CRM_PROSPECT_LEAD_PKG;
/
SHOW ERR;

