CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_PURGE_PKG 
AS
-- +================================================================================================+
-- |                        Office Depot                                                            |
-- +================================================================================================+
-- | Name  : XX_CDH_OMX_PURGE_PKG                                                                   |
-- | Rice ID: C0700                                                                                 |
-- | Description      : This package is used to purge all the successful records over p_purge_days  |
-- |                    (default--> 30 days) from the staging tables                                |                                                                      
-- |                                                                                                |
-- |Change Record:                                                                                  |
-- |===============                                                                                 |
-- |Version Date        Author            Remarks                                                   |
-- |======= =========== =============== ============================================================|
-- |1.0     04-MAR-2015 Havish Kasina   Initial draft version                                       |
-- |2.0     12-MAR-2015 Havish Kasina   Code Review Changes                                         |
-- +================================================================================================+
   
  PROCEDURE data_purge 
  (
      x_retcode              OUT NOCOPY      NUMBER,
      x_errbuf               OUT NOCOPY      VARCHAR2,
      p_purge_days           IN              NUMBER
  );

END;
/
SHOW ERRORS;