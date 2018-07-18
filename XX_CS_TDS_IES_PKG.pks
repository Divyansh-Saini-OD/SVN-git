create or replace
PACKAGE XX_CS_TDS_IES_PKG AS

  PROCEDURE GET_QUESTIONS (P_SERVICE_TYPE     IN VARCHAR2,
                           P_SERVICE_ID       IN NUMBER,
                           P_PANEL_CATEGORY   IN VARCHAR2,
                           P_QUE_TBL_TYPE     IN OUT NOCOPY XX_CS_IES_QUE_TBL_TYPE,
                           X_WO_NUMBER        IN OUT NOCOPY VARCHAR2,
                           X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MESG      IN OUT NOCOPY VARCHAR2);
                          
  PROCEDURE SUBMIT_ANSWERS (P_SERVICE_TYPE     IN VARCHAR2, 
                            P_MODIFY_FLAG      IN VARCHAR2,
                            P_PANEL_CATEGORY   IN VARCHAR2,
                            P_ANS_TBL_TYPE     IN XX_CS_IES_ANS_TBL_TYPE,
                            P_SERVICE_ID       IN OUT NOCOPY NUMBER, 
                            X_SKUKEY           IN OUT NOCOPY VARCHAR2,
                            X_RETURN_CODE      IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MESG      IN OUT NOCOPY VARCHAR2);
                            
  PROCEDURE GET_ANSWER_OPTIONS (P_ANS_OPTION      IN VARCHAR2,
                              P_QUE_ID        IN NUMBER,
                              P_ANS_OPTIONS   IN OUT NOCOPY XX_CS_IES_OPT_TBL_TYPE,
                              X_RETURN_CODE   IN OUT NOCOPY VARCHAR2,
                              X_RETURN_MESG   IN OUT NOCOPY VARCHAR2);
                              
  PROCEDURE SUBMIT_SKUS (P_SERVICE_TYPE        IN VARCHAR2, 
                         P_SERVICE_ID          IN NUMBER,
                         P_EMAIL_ID            IN VARCHAR2,
                         P_LOC_ID              IN VARCHAR2,
                         P_SKU_TBL_TYPE        IN XX_CS_TDS_SKU_TBL,
                         X_RETURN_CODE         IN OUT NOCOPY VARCHAR2,
                         X_RETURN_MESG         IN OUT NOCOPY VARCHAR2);
                              
  PROCEDURE GET_SUBMITED_SKUS (P_SERVICE_TYPE      IN VARCHAR2, 
                             P_SERVICE_ID          IN NUMBER,
                             P_SKU_TBL_TYPE        IN OUT NOCOPY XX_CS_TDS_SKU_TBL,
                             X_RETURN_CODE         IN OUT NOCOPY VARCHAR2,
                             X_RETURN_MESG         IN OUT NOCOPY VARCHAR2);

END XX_CS_TDS_IES_PKG;
/
EXIT;