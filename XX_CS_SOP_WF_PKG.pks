create or replace
PACKAGE XX_CS_SOP_WF_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */

   /* TODO enter package declarations (types, exceptions, methods etc) here */

  PROCEDURE Send_Message (
		p_source_object_type	IN	VARCHAR2,
		p_source_obj_type_code  IN	VARCHAR2,
		p_source_object_int_id	IN	NUMBER,
		p_source_object_ext_id	IN	VARCHAR2,
		p_sender		IN	VARCHAR2,
		p_sender_role		IN	VARCHAR2    DEFAULT NULL,
		p_receiver		IN	VARCHAR2,
		p_receiver_role		IN	VARCHAR2,
		p_priority		IN	VARCHAR2,
		p_expand_roles		IN	VARCHAR2,
		p_action_type		IN	VARCHAR2    DEFAULT NULL,
		p_action_code		IN	VARCHAR2    DEFAULT NULL,
		p_confirmation		IN	VARCHAR2,
		p_message		IN	VARCHAR2    DEFAULT NULL,
                p_url_hyper_link        IN      VARCHAR2    DEFAULT NULL,
                p_subject               IN      VARCHAR2    DEFAULT NULL,
		p_function_name		IN	VARCHAR2    DEFAULT NULL,
		p_function_params	IN	VARCHAR2    DEFAULT NULL );

  PROCEDURE Notification_Callback (
		command 	IN	VARCHAR2,
		context		IN	VARCHAR2,
		attr_name	IN	VARCHAR2    DEFAULT NULL,
		attr_type	IN 	VARCHAR2    DEFAULT NULL,
		text_value	IN OUT NOCOPY VARCHAR2,
		number_value	IN OUT NOCOPY NUMBER,
		date_value	IN OUT NOCOPY 	DATE );
                
  PROCEDURE SOP_PROCEDURE ( P_REQUEST_ID      IN NUMBER,
                          P_REQUEST_NUMBER  IN NUMBER,
                          P_REQUEST_TYPE    IN VARCHAR2,
                          P_USER_ID         IN NUMBER,
                          P_SENDER_ROLE     IN VARCHAR2,
                          P_STATUS          IN OUT NOCOPY VARCHAR2,
                          P_ERR_MSG         IN OUT NOCOPY VARCHAR2);
                          
  PROCEDURE INIT_PROC (P_REQUEST_NUMBER IN NUMBER);
  
  
 PROCEDURE Task_creation (p_incident_id  in number,
                         x_return_status    out nocopy varchar2,
                         x_return_msg       out nocopy varchar2);
                         

 Procedure Send_rem_mail(p_request_number in varchar2,
                         p_email_address  in varchar2,
                         p_subject        in varchar2,
                         p_msg_body       in varchar2,
                         p_return_status in out nocopy varchar2,
                         p_return_msg in out nocopy varchar2);
                         
procedure StartFYIProcess (
   roleName in varchar2,
   srID    in number,
   subject in varchar2,
   content   Wf_Engine.TextTabTyp,
   ProcessOwner in varchar2,
   Workflowprocess in varchar2 ,
   item_type in varchar2 ) ; 
   
procedure send_email(
  email_address_in in varchar2,
  user_id          in varchar2,
  subject          in varchar2,
  msg_body         in varchar2,
  srID             in number
);

FUNCTION TASK_UPDATE (P_subscription_guid  IN RAW,
                      P_event              IN OUT NOCOPY WF_EVENT_T) 
RETURN VARCHAR2;

PROCEDURE ESC_PROC (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER );
                    
PROCEDURE Task_assignment (p_task_id        IN NUMBER,
                           p_resource_id    IN NUMBER,
                           p_resource_type  IN VARCHAR2,
                           x_return_status  OUT NOCOPY VARCHAR2,
                           x_return_msg     OUT NOCOPY VARCHAR2);
                
END XX_CS_SOP_WF_PKG;
/
