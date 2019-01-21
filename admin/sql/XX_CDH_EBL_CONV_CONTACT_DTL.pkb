SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_ebl_conv_contacts_pkg

  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XX_CDH_EBL_CONV_CONTACTS_PKG                                |
  -- | Description :                                                             |
  -- | This package provides table handlers for the table                        |
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
                    , p_last_update_login    IN NUMBER DEFAULT FND_GLOBAL.USER_ID)
IS

BEGIN

  INSERT
  INTO xx_cdh_ebl_conv_contact_dtl(ebl_conv_contact_id 
                               , ebl_conv_doc_id
                               , org_contact_id
                               , org_ref_number
                               , cust_acct_site_id
                               , first_name
                               , last_name
                               , email_address
                               , phone_area_code
                               , phone_number
                               , phone_extension
                               , attribute1
                               , attribute2
                               , attribute3
                               , attribute4
                               , attribute5
                               , attribute6
                               , attribute7
                               , attribute8
                               , attribute9
                               , attribute10
                               , attribute11
                               , attribute12
                               , attribute13
                               , attribute14
                               , attribute15
                               , attribute16
                               , attribute17
                               , attribute18
                               , attribute19
                               , attribute20
                               , last_update_date
                               , last_updated_by
                               , creation_date
                               , created_by
                               , last_update_login)
            VALUES    ( p_ebl_conv_contact_id 
                      , p_ebl_conv_doc_id
                      , p_org_contact_id
                      , p_org_ref_number
                      , p_cust_acct_site_id
                      , p_first_name
                      , p_last_name
                      , p_email_address
                      , p_phone_area_code
                      , p_phone_number
                      , p_phone_extension
                      , p_attribute1
                      , p_attribute2
                      , p_attribute3
                      , p_attribute4
                      , p_attribute5
                      , p_attribute6
                      , p_attribute7
                      , p_attribute8
                      , p_attribute9
                      , p_attribute10
                      , p_attribute11
                      , p_attribute12
                      , p_attribute13
                      , p_attribute14
                      , p_attribute15
                      , p_attribute16
                      , p_attribute17
                      , p_attribute18
                      , p_attribute19
                      , p_attribute20
                      , p_last_update_date
                      , p_last_updated_by
                      , p_creation_date
                      , p_created_by
                      , p_last_update_login);
                      
  x_status := 'S';

EXCEPTION

   WHEN OTHERS THEN
    
    x_status := 'E';
    x_error_message := 'Insert into xx_cdh_ebl_conv_contact_dtl failed.' || ' SQLCODE - ' || SQLCODE || ' SQLERRM - '  || INITCAP(SQLERRM);

END insert_row;

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
                    , p_last_update_login    IN NUMBER   DEFAULT FND_GLOBAL.USER_ID)                    
IS
BEGIN

  UPDATE xx_cdh_ebl_conv_contact_dtl
  SET ebl_conv_contact_id = p_ebl_conv_contact_id
    , org_contact_id      = p_org_contact_id
    , org_ref_number      = p_org_ref_number
    , cust_acct_site_id   = p_cust_acct_site_id
    , first_name          = p_first_name
    , last_name           = p_last_name
    , email_address       = p_email_address
    , phone_area_code     = p_phone_area_code
    , phone_number        = p_phone_number
    , phone_extension     = p_phone_extension
    , attribute1          = p_attribute1
    , attribute2          = p_attribute2
    , attribute3          = p_attribute3
    , attribute4          = p_attribute4
    , attribute5          = p_attribute5
    , attribute6          = p_attribute6
    , attribute7          = p_attribute7
    , attribute8          = p_attribute8
    , attribute9          = p_attribute9
    , attribute10         = p_attribute10
    , attribute11         = p_attribute11
    , attribute12         = p_attribute12
    , attribute13         = p_attribute13
    , attribute14         = p_attribute14
    , attribute15         = p_attribute15
    , attribute16         = p_attribute16
    , attribute17         = p_attribute17
    , attribute18         = p_attribute18
    , attribute19         = p_attribute19
    , attribute20         = p_attribute20
    , last_update_date    = p_last_update_date
    , last_updated_by     = p_last_updated_by
    , creation_date       = p_creation_date
    , created_by          = p_created_by
    , last_update_login   = p_last_update_login
 WHERE ebl_conv_doc_id  = p_ebl_conv_doc_id;
 
  x_status := 'S';

EXCEPTION

   WHEN OTHERS THEN
    
    x_status := 'E';
    x_error_message := 'Update into xx_cdh_ebl_conv_contact_dtl failed.' || ' SQLCODE - ' || SQLCODE || ' SQLERRM - '  || INITCAP(SQLERRM);

END update_row;

END xx_cdh_ebl_conv_contacts_pkg;
/

SHOW ERRORS;