CREATE OR REPLACE PACKAGE XXCRM_OPPTY_RESOURCE_RPT_PKG
AS

PROCEDURE XXCRM_OPPTY_RESOURCE_RPT_PROC (p_errbuf              OUT NOCOPY VARCHAR2
                                     ,p_retcode             OUT NOCOPY VARCHAR2                                                        ,p_opportunity_number  IN VARCHAR2
                                     ,p_lead_status         IN VARCHAR2
                                 );

END XXCRM_OPPTY_RESOURCE_RPT_PKG;
/
SHOW ERR;