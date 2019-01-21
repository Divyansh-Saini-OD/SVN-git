SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +================================================-===================+
-- | Name       : XX_CDH_DQM_SYNC                                 |
-- | Rice Id    : E0259 Customer Search                                 | 
-- | Description: Real time dqm synchronization
-- | Author: Indra Varada
-- +====================================================================+  
create or replace
PACKAGE XX_CDH_DQM_SYNC AS

FUNCTION realtime_sync  (p_subscription_guid  IN RAW,
          p_event              IN OUT WF_EVENT_T,
          p_operation     IN VARCHAR2)
          RETURN VARCHAR2 ;
          
PROCEDURE DQM_REAL_TIME_SYNC_CREATE (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );
                
PROCEDURE DQM_REAL_TIME_SYNC_UPDATE (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );
                
PROCEDURE SYNC_PARTY_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );
                
PROCEDURE SYNC_SITE_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );
                
PROCEDURE SYNC_CONTACT_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );
                
PROCEDURE SYNC_CONTACT_POINT_INDEX (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );                


END XX_CDH_DQM_SYNC;
/
SHOW ERRORS;
EXIT;