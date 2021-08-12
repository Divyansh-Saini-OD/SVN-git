create or replace PACKAGE XX_AR_DISGRACE_REPORT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_DISGRACE_REPORT_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: Discount Grace Days Report Monthly       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         25-FEB-2021   Abhinav Jaiswal      Initial Version Added                       |
  -- +============================================================================================|
  -- +============================================================================================|
  PROCEDURE XX_AR_DISGRACE_RPT_PRC(
      ERRBUF OUT VARCHAR2,
      RETCODE OUT NUMBER );
END XX_AR_DISGRACE_REPORT_PKG;
/