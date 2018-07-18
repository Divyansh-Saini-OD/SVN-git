create or replace
PACKAGE XX_CS_MPS_VEN_PKG AS 

  PROCEDURE UPDATE_REQUEST (P_REQUEST_NUMBER  IN VARCHAR2,
                          P_STATUS          IN VARCHAR2,
                          P_VENDOR          IN VARCHAR2,
                          P_COMMENTS        IN VARCHAR2,
                          P_SERVICE_LINK    IN VARCHAR2,
                          P_MESSAGE_ID      IN NUMBER,
                          P_SKU_TBL         IN XX_CS_TDS_SKU_TBL,
                          X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                          X_MSG_DATA        OUT NOCOPY VARCHAR2);

  PROCEDURE UPDATE_COMMENTS (P_REQUEST_NUMBER  IN VARCHAR2,
                           P_VENDOR          IN VARCHAR2,
                           P_COMMENTS        IN VARCHAR2,
                           X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                           X_MSG_DATA        OUT NOCOPY VARCHAR2);


  PROCEDURE OUTBOUND_ACK (P_REQUEST_NUMBER  IN VARCHAR2,
                        P_VENDOR          IN VARCHAR2,
                        P_COMMENTS        IN VARCHAR2,
                        P_SERVICE_LINK    IN VARCHAR2,
                        P_MESSAGE_ID      IN NUMBER,
                        X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                        X_MSG_DATA        OUT NOCOPY VARCHAR2);

  PROCEDURE CAN_PROC (P_INCIDENT_NUMBER IN VARCHAR2,
                     P_INCIDENT_ID     IN NUMBER,
                     P_STORE_NUMBER    IN VARCHAR2,
                       P_ACTION          IN VARCHAR2,
                       X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MESSAGE  IN OUT NOCOPY VARCHAR2);
                       
  PROCEDURE  OUTBOUND_PROC (P_INCIDENT_ID IN NUMBER,
                           P_ACTION       IN VARCHAR2,
                           P_TYPE         IN VARCHAR2,
                           P_PARTY_ID     IN NUMBER,
                           P_HDR_REC      IN XX_CS_PO_HDR_REC,
                           P_LINES_TBL    IN XX_CS_ORDER_LINES_TBL,
                           X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MSG   IN OUT NOCOPY VARCHAR2);
                           
PROCEDURE CASE_OUTBOUND_PROC(P_INCIDENT_ID IN NUMBER,
                           P_ACTION       IN VARCHAR2,
                           P_TYPE         IN VARCHAR2,
                           P_PARTY_ID     IN NUMBER,
                           X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MSG   IN OUT NOCOPY VARCHAR2);
                  
                       
END XX_CS_MPS_VEN_PKG;
/
