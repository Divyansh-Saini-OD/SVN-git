create or replace
PACKAGE XX_OD_PA_CPTL_UPLD_PKG 
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_OD_PA_CPTL_UPLD_PKG                                                             |
-- |  Description:  PA Mass Upload Tool to update project asset information                     | 
-- |  Rice ID : E3062                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01-Jul-2013   Archana N.        Initial version                                |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_OD_PA_CPTL_UPLD_PKG.XX_MAIN                                                      |
-- |  Description: This pkg.procedure will invoke the appropriate API and update project asset  |
-- |  details.                                                                                  |
-- =============================================================================================|
PROCEDURE XX_MAIN
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER);

-- +============================================================================================+
-- |  Name: XX_OD_PA_CPTL_UPLD_PKG.PUBLISH_REPORT                                               |
-- |  Description: This pkg.procedure will invoke the publisher program to publish the report in|
-- |               Excel format.                                                                |
-- =============================================================================================|

PROCEDURE PUBLISH_REPORT;
   
END XX_OD_PA_CPTL_UPLD_PKG;
/
