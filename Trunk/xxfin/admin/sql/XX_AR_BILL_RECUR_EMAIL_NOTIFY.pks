CREATE OR REPLACE PACKAGE XX_AR_BILL_RECUR_EMAIL_NOTIFY
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_BILL_RECUR_HIST_NOTIFY                                                       |
  -- |                                                                                            |
  -- |  Description:  This package is for billing email notification                              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author              Remarks                                       |
  -- | =========   ===========  =============       ============================================  |
  -- | 1.0         28-FEB-2018  Sahithi Kunuru      Initial version                               |
  -- +============================================================================================+
	PROCEDURE email_notify(errbuff OUT VARCHAR2
	                      ,retcode OUT VARCHAR2);
END XX_AR_BILL_RECUR_EMAIL_NOTIFY;
/