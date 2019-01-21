CREATE OR REPLACE PACKAGE APPS.XX_CDH_OMX_DUNNING_PKG
AS
-- +=========================================================================+
-- |                        Office Depot                                      |
-- +=========================================================================+
-- | Name  : XX_CDH_OMX_DUNNING_PKG                                         |
-- | Rice ID: C0701                                                          |
-- | Description      : This Program will extract all the OMX contacts       |
-- |                    and create .csv file and sent to web collect         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
--|1.0      10-FEB-2015 Abhi K          Initial draft version                |
--|1.1      15-FEB-2015 Abhi K          Code Review version                  |
--|1.2      26-MAR-2015 Abhi k          Updated the logic to get Account Name|
-- +=========================================================================+
PROCEDURE EXTRACT (
      x_retcode      OUT NOCOPY      NUMBER,
      x_errbuf       OUT NOCOPY      VARCHAR2,
      p_status       IN              VARCHAR2,
      p_debug_flag   IN              VARCHAR2
      
   );
END;
/
SHOW ERRORS;