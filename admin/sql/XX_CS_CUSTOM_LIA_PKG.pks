CREATE OR REPLACE
PACKAGE XX_CS_CUSTOM_LIA_PKG AS
                 
  PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER);
  
  Procedure Update_SR_status(p_sr_request_id    in number,
                             p_status            in varchar2);
                             
  PROCEDURE TASK_ASSIGN (P_SR_REQUEST_ID IN NUMBER);
  
  PROCEDURE TASK_CLOSED (P_SR_REQUEST_ID IN NUMBER);

END XX_CS_CUSTOM_LIA_PKG;
/
show errors;
exit;

