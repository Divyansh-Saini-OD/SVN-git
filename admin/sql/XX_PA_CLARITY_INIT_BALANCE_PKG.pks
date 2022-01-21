CREATE OR REPLACE PACKAGE APPS.XX_PA_CLARITY_INIT_BALANCE_PKG AS   
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       |  
-- +============================================================================================+ 
-- |  Name:  XX_PA_CLARITY_EXTRACT_PKG                                                          | 
-- |                                                                                            | 
-- |  Description:  This package extracts Project and Budget information for CLARITY            |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         21-SEP-2011  R.Strauss            Initial version                              |
-- +============================================================================================+

PROCEDURE EXTRACT_CLARITY_BALANCE(errbuf       OUT NOCOPY VARCHAR2,
                                  retcode      OUT NOCOPY NUMBER);

END XX_PA_CLARITY_INIT_BALANCE_PKG ;
/