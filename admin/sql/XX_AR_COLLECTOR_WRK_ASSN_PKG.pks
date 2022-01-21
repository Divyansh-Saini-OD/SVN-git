SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_AR_COLLECTOR_WRK_ASSN_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                      WIPRO Technologies                           |
  -- +===================================================================+
  -- | Name             :    XX_AR_COLLECTOR_WRK_ASSN_PKG                      |
  -- | Description      :    Package for Submitting Collector Work Assignment  |
  -- |                       Report                                            |
  -- |                       with desired Layout                         |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date         Author              Remarks                 |
  -- |=======   ===========  ================    ========================|
  -- |1.0       19-Jan-2009  Ganesan JV          Initial Version         |
  -- +===================================================================+
   PROCEDURE COL_WRK_ASSN_WRAPPER(p_errbuf  OUT NOCOPY VARCHAR2
								  ,p_retcode OUT NOCOPY NUMBER
                                  ,p_collector_name IN VARCHAR2
                                  ,p_collector_group IN VARCHAR2
								  ,p_start_date_low IN VARCHAR2
								  ,p_start_date_high IN VARCHAR2
								  ,p_end_date_low IN VARCHAR2
								  ,p_end_date_high IN VARCHAR2
								  ,p_status IN VARCHAR2
								  ,p_item_aged_gr IN NUMBER
                                  );
END XX_AR_COLLECTOR_WRK_ASSN_PKG;
/
SHO ERR