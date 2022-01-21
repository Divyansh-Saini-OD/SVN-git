create or replace package XX_FIN_VPS_RCPT_INTERIM
as
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Populate receipts data into INTERIM table                    | 
-- |                  XX_FIN_VPS_RCPT_INTERIM                                  |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0       30-NOV-17      Thejaswini Rajula         Initial draft version  |
-- +===========================================================================+
  PROCEDURE GET_OA_RECEIPTS( ERRBUF                OUT  VARCHAR2
                            ,RETCODE               OUT  NUMBER
                            ,FROM_DATE             IN   VARCHAR2 DEFAULT NULL
                            ,TO_DATE               IN   VARCHAR2 DEFAULT NULL
                          );
END XX_FIN_VPS_RCPT_INTERIM;
/