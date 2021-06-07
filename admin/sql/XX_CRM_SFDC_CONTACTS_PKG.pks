create or replace PACKAGE XX_CRM_SFDC_CONTACTS_PKG AS

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

PROCEDURE insert_contact_email( p_acct_orig_sys_reference in  varchar2,
                                p_bad_email_address       in  varchar2,
                                p_correct_email_address   in  varchar2,
                                p_correct_first_name      in  varchar2,
                                p_correct_last_name       in  varchar2,
                                x_return_status           out nocopy varchar2,
                                x_error_message           out nocopy varchar2);

END XX_CRM_SFDC_CONTACTS_PKG;
/
SHOW ERROR;