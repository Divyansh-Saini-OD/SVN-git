create or replace package XX_FIN_VPS_BACKUP_DATA
as
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Create index ON XX_FIN_VPS_BACKUP_DATA.pks                   |
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
                           ,P_PROGRAM_ID          IN   NUMBER
                           ,P_VENDOR_NUMBER       IN   VARCHAR2
                           ,P_BACKUP_TYPE         IN   VARCHAR2
                          );
END XX_FIN_VPS_BACKUP_DATA;
/
                         