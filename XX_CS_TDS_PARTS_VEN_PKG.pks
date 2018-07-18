create or replace
PACKAGE XX_CS_TDS_PARTS_VEN_PKG AS

PROCEDURE PART_OUTBOUND (p_incident_number   	IN VARCHAR2, 
                         p_incident_id		IN NUMBER,
                         p_doc_type          	IN VARCHAR2,
                         p_doc_number        	IN VARCHAR2,
                         x_return_status     	IN OUT NOCOPY VARCHAR2,
                         x_return_msg        	IN OUT NOCOPY VARCHAR2);

FUNCTION PART_TASK (P_subscription_guid  IN RAW,
                  P_event              IN OUT NOCOPY WF_EVENT_T) RETURN VARCHAR2 ;
                  

PROCEDURE DM_PROC (P_REQUEST_NUMBER    IN VARCHAR2,
                      P_REQUEST_ID        IN NUMBER,
                      X_DOC_NUMBER        IN OUT VARCHAR2,
                      X_RETURN_STATUS     IN OUT NOCOPY VARCHAR2,
                      X_RETURN_MSG        IN OUT NOCOPY VARCHAR2);
                      
END XX_CS_TDS_PARTS_VEN_PKG ;

/

