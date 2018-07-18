create or replace
PACKAGE XX_CS_TDS_VEN_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  FUNCTION SR_TASK
                (P_subscription_guid  IN RAW,
                 P_event              IN OUT NOCOPY WF_EVENT_T) RETURN VARCHAR2;
                 
  
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
                           
  PROCEDURE VEN_OUTBOUND (p_incident_id   IN NUMBER, 
                        p_sr_type       IN VARCHAR2,
                        p_user_id       IN NUMBER,
                        p_status_id     IN NUMBER,
                        x_return_status IN OUT NOCOPY VARCHAR2,
                        x_return_msg    IN OUT NOCOPY VARCHAR2);
                        
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

END XX_CS_TDS_VEN_PKG;
/
