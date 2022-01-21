create or replace
PACKAGE XX_AR_UPDT_DFF_COMM_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_UPDATE_DFF_COMM_PKG                                                    			|
-- |  Description:  Mass Update of DFF and Comments 											|
-- |  Rice ID : E3058		                                   									|                                                       
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         02-Apr-2013   Adithya        Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_UPDATE_DFF_COMM_PKG.XX_MAIN                                           |
-- |  Description: This pkg.procedure will do the validations required and perform the mass update. |
-- =============================================================================================|
  PROCEDURE XX_MAIN
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER
   );
   

END XX_AR_UPDT_DFF_COMM_PKG;
/
