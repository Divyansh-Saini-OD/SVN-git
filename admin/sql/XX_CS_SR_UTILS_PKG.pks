create or replace
PACKAGE "XX_CS_SR_UTILS_PKG" AS

PROCEDURE CREATE_NON_GMILL_SR (P_SOURCE         IN VARCHAR2,
                               P_REQ_TYPE       IN VARCHAR2,
                               P_PROBLEM_CODE   IN VARCHAR2,
                               P_DESCRIPTION    IN VARCHAR2,
                               P_USER_ID        IN VARCHAR2,
                               P_CUSTOMER_ID    IN NUMBER,
                               X_REQUEST_NUM    IN OUT NOCOPY VARCHAR2,
                               X_REQUEST_ID     IN OUT NOCOPY VARCHAR2,
                               X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                               X_MSG_DATA       IN OUT NOCOPY VARCHAR2) ;
                            
PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER,
                    P_COMMENTS      IN VARCHAR2,
                    P_USER_ID       IN NUMBER,
                    X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                    X_MSG_DATA      IN OUT NOCOPY VARCHAR2);
                    
Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status_id         in number,
                          p_status            in varchar2,
                          x_return_status     in out nocopy varchar2,
                          x_msg_data          in out nocopy varchar2);
                          
PROCEDURE CREATE_NOTE(p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2);
                       
Procedure Update_SR_Owner(p_sr_request_id    in number,
                          p_user_id          in varchar2,
                          p_owner            in varchar2,
                          x_return_status    in out nocopy varchar2,
                          x_msg_data         in out nocopy varchar2);
                       
FUNCTION RES_REV_TIME_CAL (P_DATE IN DATE,
                           P_HOURS IN NUMBER,
                           P_CAL_ID IN VARCHAR2) 
RETURN DATE   ;
                    
END;

/
show errors;
exit;