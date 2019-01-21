CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_BILL_DOCUMENTS_PKG
AS
-- +================================================================================+
-- |                                                                                |
-- +================================================================================+
-- | Name  : XX_CDH_OMX_BILL_DOCUMENTS_PKG|
-- | Rice ID: C0700                                                                 |
-- | Description      : This Program will extract all the OMX Billing documents     |
-- |                    data received from OMX and creates the documents in oracle  |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version DATE        Author            Remarks                                   |
-- |======= =========== =============== ============================================|
-- |1.0     23-Feb-2015 Arun Gannarapu  Initial draft version                       |
-- |2.0     13-Apr-2015 Arun Gannarapu  made changes for 1082/1083                  |
-- +================================================================================+

  TYPE xx_od_ext_attr_rec IS RECORD
  (Attribute_group_code      VARCHAR2(30),
   record_id                 NUMBER,
   Interface_entity_name     VARCHAR2(100),
   cust_acct_id              NUMBER,
   c_ext_attr1               VARCHAR2(150),   -- Document_type -- consoliDATEd or invoiced
   c_ext_attr2               VARCHAR2(150),   -- Paydoc or Infodoc
   c_ext_attr3               VARCHAR2(150),   -- Delivery Method 
   c_ext_attr4               VARCHAR2(150),   -- Signature Required
   c_ext_attr5               VARCHAR2(150),   -- Cycle
   c_ext_attr6               VARCHAR2(150),   -- Document type -- Direct or Indirect
   c_ext_attr7               VARCHAR2(150),
   c_ext_attr8               VARCHAR2(150),
   c_ext_attr9               VARCHAR2(150),
   c_ext_attr10              VARCHAR2(150),
   c_ext_attr11              VARCHAR2(150),  -- Populate if consoliDATEd is Y else N
   c_ext_attr12              VARCHAR2(150),
   c_ext_attr13              VARCHAR2(150),
   c_ext_attr14              VARCHAR2(150),  -- Payment term
   c_ext_attr15              VARCHAR2(150),
   c_ext_attr16              VARCHAR2(150),  -- Status 'COMPLETE'
   c_ext_attr17              VARCHAR2(150),
   c_ext_attr18              VARCHAR2(150),
   c_ext_attr19              VARCHAR2(150),
   c_ext_attr20              VARCHAR2(150),
   N_Ext_attr1               NUMBER ,         -- MBS DOC ID
   N_Ext_attr2               NUMBER ,         -- CUST DOC ID
   N_Ext_attr3               NUMBER ,         -- NO OF COPIES --1
   N_Ext_attr4               NUMBER ,
   N_Ext_attr5               NUMBER ,
   N_Ext_attr6               NUMBER ,
   N_Ext_attr7               NUMBER ,
   N_Ext_attr8               NUMBER ,
   N_Ext_attr9               NUMBER ,
   N_Ext_attr10              NUMBER ,
   N_Ext_attr11              NUMBER ,
   N_Ext_attr12              NUMBER ,
   N_Ext_attr13              NUMBER ,
   N_Ext_attr14              NUMBER ,
   N_Ext_attr15              NUMBER ,
   N_Ext_attr16              NUMBER ,
   N_Ext_attr17              NUMBER ,
   N_Ext_attr18              NUMBER ,      -- Payment term id
   N_Ext_attr19              NUMBER ,      -- 0 --infodoc and 1 --paydoc
   N_Ext_attr20              NUMBER ,      -- batch id
   D_Ext_attr1               DATE,         -- start DATE
   d_Ext_attr2               DATE,         -- End DATE 
   d_Ext_attr3               DATE,         -- End DATE
   d_Ext_attr4               DATE,         -- End DATE
   d_Ext_attr5               DATE,         
   d_Ext_attr6               DATE,         
   d_Ext_attr7               DATE,         
   d_Ext_attr8               DATE,        
   d_Ext_attr9               DATE,        
   d_Ext_attr10              DATE        
   );

  G_ORGANIZATION              CONSTANT VARCHAR2(100) :='ORGANIZATION';
  G_SITE                      CONSTANT VARCHAR2(100) :='SITE';
  G_PERSON                    CONSTANT VARCHAR2(100) :='PERSON';
  G_ACCOUNT                   CONSTANT VARCHAR2(100) :='ACCOUNT';
  G_ACC_SITE                  CONSTANT VARCHAR2(100) :='ACCOUNT_SITE';
  G_ACC_SITE_USE              CONSTANT VARCHAR2(100) :='ACCOUNT_SITE_USE';
  G_API_VERSION               CONSTANT NUMBER        := 1.0;
  
  -- +========================================================================================+
  -- | Name  : Build Extension table                                                          |
  -- | Description   : This Procedure This process will build the                             |
  -- |                 attribute_data_table and attribute_row_table based                     |
  -- |                 on the values provided . These row tables are needed for API call.     |
  -- |                 EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data to create the document |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE build_extension_table(p_user_row_table  IN OUT EGO_USER_ATTR_ROW_TABLE,
                                  p_user_data_table IN OUT EGO_USER_ATTR_DATA_TABLE,
                                  p_ext_attribs_row IN OUT xx_od_ext_attr_rec,
                                  p_return_Status       OUT VARCHAR2,
                                  p_error_msg           OUT VARCHAR2);

  
  -- +===================================================================+
  -- | Name  : get_payment_term_info                                      |
  -- | Description     : This function returns the payment terminfo       |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_payment_term_info(p_cursor_rec          IN  xx_cdh_omx_bill_docs_stg%ROWTYPE,
                                 p_doc_type            IN  xx_fin_translatevalues.target_value2%TYPE,
                                 p_payment_term_info   OUT ra_terms%ROWTYPE,
                                 p_default_used        OUT VARCHAR2,
                                 p_error_msg           OUT VARCHAR2)
  RETURN VARCHAR2;



  -- +===================================================================+
  -- | Name  : derive_delivery_method                                     |
  -- | Description     : This function returns the delivery method info   |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION derive_delivery_method(p_billing_flag        IN  xx_cdh_omx_bill_docs_Stg.summary_bill_flag%TYPE,
                                  p_delivery_method     OUT VARCHAR2,
                                  p_default_used        OUT VARCHAR2,
                                  p_error_msg           OUT VARCHAR2)
  RETURN VARCHAR2;


  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract is the main                         |
  -- |                   procedure that will extract the records         |
  -- |                   from staging table to create the documents      |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+

  PROCEDURE extract( x_retcode           OUT NOCOPY     NUMBER
                    ,x_errbuf            OUT NOCOPY     VARCHAR2
                    ,p_aops_acct_NUMBER  IN             xx_cdh_omx_bill_docs_stg.aops_customer_number%TYPE
                    ,p_status            IN             xx_cdh_omx_bill_docs_stg.status%TYPE
                    ,p_debug_flag        IN             VARCHAR2
                    ,p_batch_id          IN             xx_cdh_omx_bill_docs_stg.batch_id%TYPE
                    );
  

END XX_CDH_OMX_BILL_DOCUMENTS_PKG;
/

Sho err