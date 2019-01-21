CREATE OR REPLACE
PACKAGE XX_CDH_AOPS_CDH_REP_PKG 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_AOPS_CDH_REP_PKG.pks                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Program to provide DELTA Customer Report                   |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      12-Dec-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  
  PROCEDURE get_cdh_aops_delta_rep
  (
      x_errbuf          OUT NOCOPY  VARCHAR2,
      x_retcode         OUT NOCOPY  VARCHAR2,
      p_entity_type     IN          VARCHAR2,
      p_cust_type       IN          VARCHAR2,
      p_delta_type      IN          VARCHAR2
      
  );

END XX_CDH_AOPS_CDH_REP_PKG;
/
SHOW ERRORS;
