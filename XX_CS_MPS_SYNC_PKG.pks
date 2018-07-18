create or replace
PACKAGE XX_CS_MPS_SYNC_PKG AS 

  PROCEDURE TONER_REQ_SYNC( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                            X_RETCODE         OUT  NOCOPY  NUMBER,
                            P_TYPE            IN VARCHAR2,
                            P_DAYS            IN NUMBER);
 

END XX_CS_MPS_SYNC_PKG;
/