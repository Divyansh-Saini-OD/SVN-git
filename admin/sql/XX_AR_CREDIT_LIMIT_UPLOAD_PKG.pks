CREATE OR REPLACE PACKAGE APPS.XX_AR_CREDIT_LIMIT_UPLOAD_PKG AS   
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       |  
-- +============================================================================================+ 
-- |  Name:  XX_AR_CREDIT_LIMIT_UPLOAD_PKG                                                      | 
-- |                                                                                            | 
-- |  Description:  This package is used by WEB ADI to mass update credit limits.               |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         10-JAN-2017  R.Strauss            Initial version                              |
-- +============================================================================================+

PROCEDURE UPDATE_CREDIT_LIMIT(errbuf       OUT NOCOPY VARCHAR2,
                              retcode      OUT NOCOPY NUMBER);

PROCEDURE INSERT_CREDIT_LIMIT(P_ACCOUNT_NUMBER  IN VARCHAR2,
                              P_CREDIT_LIMIT    IN NUMBER,
                              P_CURRENCY_CODE   IN VARCHAR2);

END XX_AR_CREDIT_LIMIT_UPLOAD_PKG ;
/