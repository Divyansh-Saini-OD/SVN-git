CREATE OR REPLACE
PACKAGE XX_CDH_WEBCONTACT_DELETE_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_WEBCONTACT_DELETE_PKG.pks                         |
-- | Description :  This package is used to delete the web contact and the   |
-- |                related dependent records.                               |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   10-Sep-2008 Kathirvel          Initial draft version           |
-- +=========================================================================+
AS


-- +========================================================================+
-- | Name        :  Delete_Web_Contacts                                    |
-- | Description :  This Procedure is beeing called from BPEL to inactive  |
-- |                contact related all dependents                         |
-- +========================================================================+
PROCEDURE Delete_Web_Contacts(
p_orig_system                          IN VARCHAR2,
p_account_osr                          IN VARCHAR2,
p_contact_osr                          IN VARCHAR2,
x_message                              OUT NOCOPY  INACT_CP_RESULTS_OBJ_TBL,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

END XX_CDH_WEBCONTACT_DELETE_PKG;
/