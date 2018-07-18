CREATE OR REPLACE
PACKAGE XX_CS_MESG_PKG AUTHID CURRENT_USER AS

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

PROCEDURE send_notification (
                p_sr_number      IN             NUMBER,
                p_sr_id          IN             VARCHAR2,
                p_from_id	 IN	        NUMBER,
		p_to_id 	 IN	        NUMBER,
		p_user_id 	 IN	        VARCHAR2,
		p_message	 IN	        VARCHAR2    DEFAULT NULL,
                p_url_link       IN             VARCHAR2,
                p_subject        IN             VARCHAR2,
                p_source         IN             VARCHAR2,
                x_return_status  IN OUT NOCOPY  VARCHAR2,
                x_return_msg     IN OUT NOCOPY  VARCHAR2);

  PROCEDURE Notification_Callback (
		command 	IN	VARCHAR2,
		context		IN	VARCHAR2,
		attr_name	IN	VARCHAR2    DEFAULT NULL,
		attr_type	IN 	VARCHAR2    DEFAULT NULL,
		text_value	IN OUT NOCOPY VARCHAR2,
		number_value	IN OUT NOCOPY NUMBER,
		date_value	IN OUT NOCOPY 	DATE );

  procedure send_email (sender          IN VARCHAR2,
                      recipient       IN VARCHAR2,
                      cc_recipient    IN VARCHAR2 ,
                      bcc_recipient   IN VARCHAR2 ,
                      subject         IN VARCHAR2,
                      message_body    IN VARCHAR2,
                    --  p_file          IN BLOB,
                      p_message_type  IN VARCHAR2,
                      IncidentNum     IN VARCHAR2,
                      return_code     OUT NUMBER) ;

-- Start of changes for defect# 37051	
  --PROCEDURE Read_Response ;
    PROCEDURE Read_Response( p_result OUT NUMBER, p_message OUT VARCHAR2);
-- End of changes for defect# 37051		
  
  PROCEDURE UPDATE_SMB_QTY (P_REQUEST_NUMBER IN VARCHAR2,
                          P_CUST_NAME     IN VARCHAR2,
                          P_ACTION        IN VARCHAR2,
                          P_SKUs          IN VARCHAR2,
                          P_UNITS         IN NUMBER);

END XX_CS_MESG_PKG;
/
