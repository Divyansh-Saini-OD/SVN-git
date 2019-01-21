create or replace package XX_FIN_VPS_BACKUP_INVSKU
as
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Package to get backup data  ON XX_FIN_VPS_BACKUP_INVSKU.pks  |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0       09-JUL-17      Sreedhar Mohan            Initial draft version  |
-- +===========================================================================+
  PROCEDURE VPS_BACKUP_GET( ERRBUF                OUT  VARCHAR2
                           ,RETCODE               OUT  NUMBER
                           ,P_STMT_DATE           IN   VARCHAR2
                          );
END XX_FIN_VPS_BACKUP_INVSKU;
/