SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_EFT_CFC_WRAPPER_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                            Providge                               |
  -- +===================================================================+
  -- | Name             :    XX_EFT_CFC_WRAPPER_PKG                      |
  -- | Description      :    Package for Submitting Cash Forecast Report |
  -- |                       with desired Layout                         |
  -- |                                                                   |
  -- |                                                                   | 
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date         Author              Remarks                 |
  -- |=======   ===========  ================    ========================|
  -- |1.0       25-Nov-2008  Ganesan JV          Initial Version         |
  -- |1.1       24-FEB-2010  Sadath O K		 Changes made for        |
  -- |                                           defect #2429 		 |
  -- +===================================================================+
   PROCEDURE EFT_CASH_FORECAST_WRAPPER(p_errbuf IN OUT VARCHAR2
                                       ,p_retcode IN OUT NUMBER
                                       ,p_cycle_date IN VARCHAR2); --added for defect#2429
END XX_EFT_CFC_WRAPPER_PKG;
/
sho err