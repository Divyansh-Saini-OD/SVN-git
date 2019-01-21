SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cdh_ebl_conv_contacts_pkg

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_CONV_CONTACTS_PKG                                |
  -- | Description :                                                             |
  -- | This package specification provides table handlers for the table          |
  -- | XX_CDH_EBL_CONV_CONTACTS.                                                 |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author           Remarks                              |
  -- |======== =========== ================ =====================================|
  -- |DRAFT 1A 09-DEC-2010 Devi Viswanathan Initial draft version                |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

AS

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : INSERT_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- | This procedure inserts data into the table  XX_CDH_EBL_CONV_CONTACTS.     |
  -- |                                                                           |
  -- |                                                                           |
  -- | Parameters  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | Returns     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE insert_row( x_status              OUT VARCHAR2
                    , x_error_message       OUT VARCHAR2
                    , p_ebl_conv_contact_id  IN NUMBER
                    , p_ebl_conv_doc_id      IN NUMBER
                    , p_org_contact_id       IN NUMBER
                    , p_org_ref_number       IN VARCHAR2 DEFAULT NULL
                    , p_cust_acct_site_id    IN NUMBER
                    , p_first_name           IN VARCHAR2
                    , p_last_name            IN VARCHAR2
                    , p_email_address        IN VARCHAR2
                    , p_phone_area_code      IN VARCHAR2
                    , p_phone_number         IN VARCHAR2
                    , p_phone_extension      IN VARCHAR2
                    , p_attribute1           IN VARCHAR2 DEFAULT NULL
                    , p_attribute2           IN VARCHAR2 DEFAULT NULL
                    , p_attribute3           IN VARCHAR2 DEFAULT NULL
                    , p_attribute4           IN VARCHAR2 DEFAULT NULL
                    , p_attribute5           IN VARCHAR2 DEFAULT NULL
                    , p_attribute6           IN VARCHAR2 DEFAULT NULL
                    , p_attribute7           IN VARCHAR2 DEFAULT NULL
                    , p_attribute8           IN VARCHAR2 DEFAULT NULL
                    , p_attribute9           IN VARCHAR2 DEFAULT NULL
                    , p_attribute10          IN VARCHAR2 DEFAULT NULL
                    , p_attribute11          IN VARCHAR2 DEFAULT NULL
                    , p_attribute12          IN VARCHAR2 DEFAULT NULL
                    , p_attribute13          IN VARCHAR2 DEFAULT NULL
                    , p_attribute14          IN VARCHAR2 DEFAULT NULL
                    , p_attribute15          IN VARCHAR2 DEFAULT NULL
                    , p_attribute16          IN VARCHAR2 DEFAULT NULL
                    , p_attribute17          IN VARCHAR2 DEFAULT NULL
                    , p_attribute18          IN VARCHAR2 DEFAULT NULL
                    , p_attribute19          IN VARCHAR2 DEFAULT NULL
                    , p_attribute20          IN VARCHAR2 DEFAULT NULL
                    , p_last_update_date     IN DATE DEFAULT SYSDATE
                    , p_last_updated_by      IN NUMBER DEFAULT FND_GLOBAL.USER_ID
                    , p_creation_date        IN DATE DEFAULT SYSDATE
                    , p_created_by           IN NUMBER DEFAULT FND_GLOBAL.USER_ID
                    , p_last_update_login    IN NUMBER DEFAULT FND_GLOBAL.USER_ID);

  -- +===========================================================================+
  -- |                                                                           |
  -- | Name        : UPDATE_ROW                                                  |
  -- |                                                                           |
  -- | Description :                                                             |
  -- |  This procedure shall update data into the table XX_CDH_EBL_CONV_CONTACTS.|
  -- |                                                                           |
  -- |                                                                           |
  -- | Parameters  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | Returns     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

PROCEDURE update_row( x_status              OUT VARCHAR2
                    , x_error_message       OUT VARCHAR2
                    , p_ebl_conv_contact_id  IN NUMBER
                    , p_ebl_conv_doc_id      IN NUMBER
                    , p_org_contact_id       IN NUMBER
                    , p_org_ref_number       IN VARCHAR2 DEFAULT NULL
                    , p_cust_acct_site_id    IN NUMBER                    
                    , p_first_name           IN VARCHAR2
                    , p_last_name            IN VARCHAR2
                    , p_email_address        IN VARCHAR2
                    , p_phone_area_code      IN VARCHAR2
                    , p_phone_number         IN VARCHAR2
                    , p_phone_extension      IN VARCHAR2
                    , p_attribute1           IN VARCHAR2 DEFAULT NULL
                    , p_attribute2           IN VARCHAR2 DEFAULT NULL
                    , p_attribute3           IN VARCHAR2 DEFAULT NULL
                    , p_attribute4           IN VARCHAR2 DEFAULT NULL
                    , p_attribute5           IN VARCHAR2 DEFAULT NULL
                    , p_attribute6           IN VARCHAR2 DEFAULT NULL
                    , p_attribute7           IN VARCHAR2 DEFAULT NULL
                    , p_attribute8           IN VARCHAR2 DEFAULT NULL
                    , p_attribute9           IN VARCHAR2 DEFAULT NULL
                    , p_attribute10          IN VARCHAR2 DEFAULT NULL
                    , p_attribute11          IN VARCHAR2 DEFAULT NULL
                    , p_attribute12          IN VARCHAR2 DEFAULT NULL
                    , p_attribute13          IN VARCHAR2 DEFAULT NULL
                    , p_attribute14          IN VARCHAR2 DEFAULT NULL
                    , p_attribute15          IN VARCHAR2 DEFAULT NULL
                    , p_attribute16          IN VARCHAR2 DEFAULT NULL
                    , p_attribute17          IN VARCHAR2 DEFAULT NULL
                    , p_attribute18          IN VARCHAR2 DEFAULT NULL
                    , p_attribute19          IN VARCHAR2 DEFAULT NULL
                    , p_attribute20          IN VARCHAR2 DEFAULT NULL
                    , p_last_update_date     IN DATE     DEFAULT SYSDATE
                    , p_last_updated_by      IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_creation_date        IN DATE     DEFAULT SYSDATE
                    , p_created_by           IN NUMBER   DEFAULT FND_GLOBAL.USER_ID
                    , p_last_update_login    IN NUMBER   DEFAULT FND_GLOBAL.USER_ID);


END xx_cdh_ebl_conv_contacts_pkg;
/

SHOW ERRORS;