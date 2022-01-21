CREATE OR REPLACE PACKAGE APPS.XX_PA_CLARITY_EXTRACT_PKG AS   
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

PROCEDURE EXTRACT_CLARITY_DATA(errbuf       OUT NOCOPY VARCHAR2,
                               retcode      OUT NOCOPY NUMBER,
                               p_org_id     IN  NUMBER,
                               p_proj_name  IN  VARCHAR2,
                               p_from_date  IN  DATE,
                               p_to_date    IN  DATE,
					           p_ftp_flag   IN	VARCHAR2,
                               p_debug_flag IN  VARCHAR2);

END XX_PA_CLARITY_EXTRACT_PKG ;
/