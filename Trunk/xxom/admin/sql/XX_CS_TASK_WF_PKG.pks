CREATE OR REPLACE
PACKAGE XX_CS_TASK_WF_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  
  PROCEDURE CREATE_NOTE(p_task_id               in number,
                       p_task_notes_rec       in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2);
                                   
  PROCEDURE Update_Task ( itemtype      VARCHAR2,
                               	   itemkey       VARCHAR2,
                                   actid         NUMBER,
                                   funmode       VARCHAR2,
                                   result    OUT NOCOPY VARCHAR2 ); 
                                   
  Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status_id         in number,
                          p_status            in varchar2,
                          x_return_status     in out nocopy varchar2,
                          x_msg_data          in out nocopy varchar2);

END XX_CS_TASK_WF_PKG;

/

show errors;
exit;

