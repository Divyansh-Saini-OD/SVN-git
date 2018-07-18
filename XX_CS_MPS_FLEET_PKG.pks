create or replace
PACKAGE XX_CS_MPS_FLEET_PKG AS 

  PROCEDURE SUPPLIES_ALERT (P_DEVICE_ID     IN VARCHAR2,
                          P_GROUP_ID        IN VARCHAR2,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2);
                          
  PROCEDURE DEVICE_FEED(P_GROUP_ID        IN VARCHAR2,
                        P_DEVICE_ID       IN VARCHAR2,
                        P_DEVICE_TBL      IN XX_CS_MPS_DEVICE_TBL_TYPE,
                        X_RETURN_STATUS   IN OUT VARCHAR2,
                        X_RETURN_MSG      IN OUT VARCHAR2);
                          
  PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                        X_RETCODE         OUT  NOCOPY  NUMBER,
                        P_TYPE            IN VARCHAR2,
                        P_GROUP_ID        IN VARCHAR2,
                        P_FEED_SYSTEM     IN VARCHAR2);
                        
  PROCEDURE RESET_REQUEST_FLAG (X_RETCODE             OUT NOCOPY    NUMBER,
                                X_ERRBUF              OUT NOCOPY    VARCHAR2,
                                P_SUPPLIES_LABEL      IN            VARCHAR2,
                                P_REQUEST_NUMBER      IN            VARCHAR2,
                                P_SERIAL_NUMBER       IN            VARCHAR2);

END XX_CS_MPS_FLEET_PKG;
/