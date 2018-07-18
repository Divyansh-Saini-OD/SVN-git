create or replace
PACKAGE XX_CS_MPS_UTILITIES_PKG AS

FUNCTION http_post ( url VARCHAR2, req_body varchar2)
RETURN VARCHAR2;

PROCEDURE CREATE_SR (P_PARTY_ID       IN NUMBER,
                       P_SALES_NUMBER   IN VARCHAR2,
                       P_REQUEST_TYPE   IN VARCHAR2,
                       P_COMMENTS       IN VARCHAR2,
                       p_sr_req_rec     in out nocopy XX_CS_SR_REC_TYPE,
                       x_return_status  IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MSG     IN OUT NOCOPY VARCHAR2);

 procedure update_sr  (P_REQUEST_ID     IN NUMBER,
                       P_COMMENTS       IN VARCHAR2,
                       P_REQ_TYPE       IN VARCHAR2,
                       P_SR_REQ_REC     IN OUT NOCOPY XX_CS_SR_REC_TYPE,
                       X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MSG     IN OUT NOCOPY VARCHAR2);

  PROCEDURE CONC_PROC (X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                       X_RETCODE         OUT  NOCOPY  NUMBER,
                       P_REQUEST_NUMBER IN VARCHAR2,
                       P_PARTY_ID       IN NUMBER,
                       P_REQ_TYPE       IN VARCHAR2);
                       
  PROCEDURE CREATE_NOTE(p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2);
                       
                  
  PROCEDURE UPDATE_SR_STATUS (P_REQUEST_ID      IN NUMBER,
                            P_REQUEST_NUMBER  IN VARCHAR2,
                            P_STATUS_ID       IN NUMBER,
                            P_STATUS          IN VARCHAR2,
                            X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MSG      IN OUT NOCOPY VARCHAR2);


END XX_CS_MPS_UTILITIES_PKG;
/