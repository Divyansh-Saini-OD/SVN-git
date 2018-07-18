create or replace
PACKAGE XX_CS_MPS_MINI_AVF_UPLD_PKG AS 

   PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                         X_RETCODE         OUT  NOCOPY  NUMBER,
                         P_BATCH_ID        IN NUMBER);

END XX_CS_MPS_MINI_AVF_UPLD_PKG;
/
