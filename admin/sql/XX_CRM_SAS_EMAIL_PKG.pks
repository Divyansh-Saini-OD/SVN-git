create or replace
PACKAGE XX_CRM_SAS_EMAIL_PKG 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CRM_SAS_EMAIL_PKG                                       |
-- | Description : SAS Behavioral EMAIL Campaign                              |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      09-Mar-2010 Indra Varada           Initial Version               |
-- +==========================================================================+
AS
  PROCEDURE build_order_email (
    p_errbuf               OUT NOCOPY VARCHAR2,
    p_retcode              OUT NOCOPY VARCHAR2,
    p_include_pos_orders   IN  VARCHAR2
  );
  
  PROCEDURE purge_order_email (
    p_errbuf               OUT NOCOPY VARCHAR2,
    p_retcode              OUT NOCOPY VARCHAR2
  );

END XX_CRM_SAS_EMAIL_PKG;
/
