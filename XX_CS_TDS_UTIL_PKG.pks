create or replace
PACKAGE XX_CS_TDS_UTIL_PKG AS

  PROCEDURE WARRANTY_UPDATE(x_errbuf     OUT  NOCOPY  VARCHAR2
                        , x_retcode  OUT  NOCOPY  NUMBER );   
  
  PROCEDURE email_send( p_incident  IN  VARCHAR2,
    p_order_num IN VARCHAR2,
    p_email IN  VARCHAR2,
    x_status_flag in out nocopy varchar2,
    x_return_msg  in out nocopy varchar2);
    
  PROCEDURE EMAIL_SEND_PICKUP  (
    p_incident  IN  VARCHAR2,
    p_order_num IN VARCHAR2,
    p_email IN  VARCHAR2,
    x_status_flag in out nocopy varchar2,
    x_return_msg  in out nocopy varchar2);

END XX_CS_TDS_UTIL_PKG;
/
EXIT;