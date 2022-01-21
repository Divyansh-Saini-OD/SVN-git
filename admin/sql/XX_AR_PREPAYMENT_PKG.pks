SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_PREPYAMENT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_AR_PREPYAMENT_PKG.pks                           |
-- | Description : To reprocess the failed Prepayment programs         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- | 1.0       01-JUN-2008   P.Suresh                                  |
-- |                                                                   |
-- | 1.1       21-AUG-2008   Sowmya M S      Defect :10039 - Added two |
-- |                           Wipro         parameters(Wait Internal 
-- |                                        and Max Wait Time)         |
-- +===================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

--- +===================================================================+
-- | Name        :  reprocess_prepayment                                |
-- | Description :Extension is used to reprocess the failed Prepayment  |
-- |              programs by updating the receipts with the correct    |
-- |              customer details and then re-submitting the failed    |
-- |              prepayments                                           |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE reprocess_prepayment(
                       x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode             OUT NOCOPY VARCHAR2
                      ,p_hours               IN         NUMBER
                      ,p_submit_pre          IN         VARCHAR2
                      ,p_interval            IN         NUMBER          -- Added for defect : 10039
                      ,p_max_wait            IN         NUMBER          -- Added for defect : 10039
                     );



END XX_AR_PREPYAMENT_PKG;
/
SHOW ERRORS
EXIT;
