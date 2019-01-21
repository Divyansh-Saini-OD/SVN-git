create or replace
package XX_CDH_UPDATE_RELATIONSHIP_PKG
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- +======================================================================+
-- | Name        :  XX_CDH_UPDATE_RELATIONSHIP_PKG.pks                    |
-- | Description :  Perform lookup to see if an existing relationship     |
-- |                exist.  If so update existing relationship with       |
-- |                inactive status and end date.                         |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date        Author             Remarks                      |
-- |========  =========== ================== =============================|
-- |DRAFT 1a  11/17/2008  Y.Ali              Initial draft version        |
-- +======================================================================+
as


-- +========================================================================+
-- | Name        :  Process_Profile_Main                                   |
-- | Description :  Process the inputs to create Profile at Account and    |
-- |                Account Site Use level                                 |
-- +========================================================================+

PROCEDURE Inactive_Relationship (
p_orig_system                          IN VARCHAR2,
p_parent_account_OSR                   IN VARCHAR2,
p_child_account_OSR                    IN VARCHAR2,
x_parent_account_ID 		       OUT NOCOPY NUMBER,
x_child_account_ID 		       OUT NOCOPY NUMBER,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

PROCEDURE GetPartyIDs (
p_parent_account_OSR                   IN VARCHAR2,
p_child_account_OSR                    IN VARCHAR2,
x_parent_account_ID 		       OUT NOCOPY NUMBER,
x_child_account_ID 		       OUT NOCOPY NUMBER,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

end XX_CDH_UPDATE_RELATIONSHIP_PKG;
/