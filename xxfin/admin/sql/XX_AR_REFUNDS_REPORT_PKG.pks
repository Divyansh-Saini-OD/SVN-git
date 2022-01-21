create or replace PACKAGE XX_AR_REFUNDS_REPORT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_REFUNDS_REPORT_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: Discount Grace Days Report Monthly       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         02-Aug-2021   Ankit Handa      Initial Version Added                           |
  -- +============================================================================================|
  -- +============================================================================================|
  PROCEDURE XX_AR_REFUND_RPT_PRC(
      ERRBUF OUT VARCHAR2,
      RETCODE OUT NUMBER );
END XX_AR_REFUNDS_REPORT_PKG;
/