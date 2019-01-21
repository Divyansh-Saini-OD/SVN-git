SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XX_CRM_SFDC_CONTACTS_PKG AS

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CRM_SFDC_CONTACTS_PKG.pks                              |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | Table hanfler for xx_crm_sfdc_contacts.                                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       22-AUG-2011  Phil Price         Initial version                 |
-- |                                                                          |
-- +==========================================================================+


PROCEDURE insert_contacts (sfdc_contact_obj  in  xx_crm_sfdc_contact_obj,
                           x_return_status   out nocopy    varchar2,
                           x_error_message   out nocopy    varchar2);

END XX_CRM_SFDC_CONTACTS_PKG;
/

show errors
