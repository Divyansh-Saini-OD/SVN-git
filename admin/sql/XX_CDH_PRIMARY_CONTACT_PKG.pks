CREATE OR REPLACE
PACKAGE XX_CDH_PRIMARY_CONTACT_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_PRIMARY_CONTACT_PKG.pks                           |
-- | Description :  This package is used to find the the primary contact for |
-- |                an account and chnges to non primary.                    |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   12-Mar-2008 Kathirvel          Initial draft version           |
-- +=========================================================================+
AS


-- +========================================================================+
-- | Name        :  Process_Account_Contact                                 |
-- | Description :  Find the primary account contact and updates on the     |
-- |                table HZ_CUST_ACCOUNT_ROLES.                            |
-- +========================================================================+
PROCEDURE Process_Account_Contact(
p_contact_osr                          IN VARCHAR2,
p_account_osr                          IN VARCHAR2,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

END XX_CDH_PRIMARY_CONTACT_PKG;
/