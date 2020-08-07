create or replace
PACKAGE BODY XX_CS_MESG_PKG AS

/* $Header: ODCSMAIL.pls on 01/07/09      */
 /****************************************************************************
  *
  * Program Name : XX_CS_MESG_PKG
  * Language     : PL/SQL
  * Description  : Package to maintain email communications.
  * History      :
  *
  * WHO             WHAT                                    WHEN
  * --------------  --------------------------------------- ---------------
  * Raj Jagarlamudi Initial Version                         1/7/09
  * Raj Jagarlamudi Accept entire message                  12/18/09
  * Raj Jagarlamudi Added SR in Bodya                      12/19/09
  ****************************************************************************/
/*****************************************************************************
-- Log Messages
****************************************************************************/
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Custom Email Messages'
     ,p_program_name            => 'XX_CS_MESG_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'CS'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;
/***************************************************************************
  -- Update SR status
*****************************************************************************/
Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status            in varchar2,
                          x_return_status     in out nocopy varchar2,
                          x_msg_data          in out nocopy varchar2)
IS
      x_msg_count	 NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number;
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739;
      ln_status_id       number;
      lc_status          varchar2(50);
      ln_type_id         number;
      lc_type_name       varchar2(250);
      
BEGIN
     begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
    end;
     /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

     /************************************************************************
    -- Get Object version, TYPE, PROBLEM CODE
    *********************************************************************/
    BEGIN
         SELECT object_version_number,
                incident_type_id
         INTO   ln_obj_ver,
                ln_type_id
         FROM   cs_incidents_all_b
         WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;

    BEGIN
        SELECT name
        INTO   lc_type_name
        FROM  cs_incident_types
        WHERE incident_type_id = ln_type_id;
     EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;

       BEGIN
          SELECT incident_status_id,
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = p_status ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_status_id := null;
        END;
  
   
   IF ln_status_id is not null THEN
      /***********************************************************************
       -- Update SR
       ***********************************************************************/
        CS_SERVICEREQUEST_PUB.Update_Status
            (p_api_version		=> 2.0,
             p_init_msg_list	        => FND_API.G_TRUE,
             p_commit		        => FND_API.G_FALSE,
              x_return_status	        => x_return_status,
              x_msg_count	        => x_msg_count,
              x_msg_data		=> x_msg_data,
              p_resp_appl_id	        => ln_resp_appl_id,
              p_resp_id		        => ln_resp_id,
              p_user_id		        => ln_user_id,
              p_login_id		=> NULL,
              p_request_id		=> p_sr_request_id,
              p_request_number	        => NULL,
              p_object_version_number   => ln_obj_ver,
              p_status_id	 	=> ln_status_id,
              p_status		        => lc_status,
              p_closed_date		=> SYSDATE,
              p_audit_comments	        => NULL,
              p_called_by_workflow	=> NULL,
              p_workflow_process_id	=> NULL,
              p_comments		=> NULL,
              p_public_comment_flag	=> NULL,
              x_interaction_id	        => x_interaction_id );

            COMMIT;
           IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                --Display all the error messages
                  FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                          FND_MSG_PUB.Get(
                                    p_msg_index => j,
                                    p_encoded => 'F',
                                    p_data => x_msg_data,
                                    p_msg_index_out => ln_msg_index_out);
      
                        DBMS_OUTPUT.PUT_LINE(x_msg_data);
                  END LOOP;
                ELSE
                            --Only one error
                        FND_MSG_PUB.Get(
                                    p_msg_index => 1,
                                    p_encoded => 'F',
                                    p_data => x_msg_data,
                                    p_msg_index_out => ln_msg_index_out);
                        DBMS_OUTPUT.PUT_LINE(x_msg_data);
                        DBMS_OUTPUT.PUT_LINE(ln_msg_index_out);
                END IF;
                x_msg_data := x_msg_data;
            END IF;
      
    END IF;
END Update_SR_Status;
-- ------------------------------------------------------------------------
-- Send_Message
--   Call the Workflow Notification API to send the message and insert a
--   new record into CS_MESSAGES.
-- ------------------------------------------------------------------------
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
                x_return_msg     IN OUT NOCOPY  VARCHAR2)
IS

lc_source_object     varchar2(50)      := 'Service Request';
lc_source_obj_type   varchar2(25)      := 'INC';
lc_message           VARCHAR2(3000);
lc_sender            varchar2(250);
lc_sender_role       varchar2(250);
lc_receiver          varchar2(250);
lc_receiver_role     varchar2(250);
lc_log_message       varchar2(1000);

BEGIN

      IF p_from_id is not null then
        BEGIN
          SELECT decode(wf.orig_system_id,
                  NULL, usr.user_name,
                  wf.display_name) user_name,
                 wf.name user_role
            INTO lc_sender, lc_sender_role
            FROM wf_roles wf, fnd_user usr
           WHERE usr.user_id = p_from_id
             AND usr.employee_id = wf.orig_system_id (+)
             AND wf.orig_system(+) = 'PER';
          exception
            when others then
                x_return_status := 'F';
                x_return_msg    := 'Error while selecting Sender role '||sqlerrm;
         END;
       else
          lc_sender := 'Customer Service';
       end if;

        BEGIN
        SELECT decode(wf.orig_system_id,
                      NULL, usr.user_name,
                      wf.display_name) user_name,
               wf.name user_role
          INTO lc_receiver, lc_receiver_role
          FROM wf_roles wf, fnd_user usr
         WHERE usr.user_id = p_to_id
           AND usr.employee_id = wf.orig_system_id (+)
           AND wf.orig_system(+) = 'PER';
        exception
          when others then
              x_return_status := 'F';
              x_return_msg    := 'Error while selecting Receiver role '||sqlerrm;
       END;

       lc_message := p_message;
       lc_log_message := 'Sender :'||lc_sender ||' Receiver : '||lc_receiver || 'Message : '||lc_message;

       Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_NOTIFICATION'
                       ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_log_message);

       IF P_SOURCE = 'OWNER' THEN

          CS_MESSAGES_PKG.Send_Message(
              p_source_object_type	  =>  lc_source_object,
              p_source_obj_type_code	=>  lc_source_obj_type,
              p_source_object_int_id	=>  p_sr_id,
              p_source_object_ext_id	=>  p_sr_number,
              p_sender		            =>  lc_sender,
              p_sender_role		        =>  lc_sender_role,
              p_receiver		          =>  lc_receiver,
              p_receiver_role		      =>  lc_receiver_role,
              p_priority		          =>  'MED',
              p_expand_roles		      =>  'N',
              p_action_type		         =>  NULL,
              p_action_code		         =>  'CONFIRMATION',
              p_confirmation		       =>  'N',
              p_message		             =>  lc_message,
              p_function_name		       =>  NULL,
              p_function_params	        =>  NULL );

        ELSE

            XX_CS_MESG_PKG.Send_Message(
              p_source_object_type	    =>  lc_source_object,
              p_source_obj_type_code	  =>  lc_source_obj_type,
              p_source_object_int_id	  =>  p_sr_id,
              p_source_object_ext_id	  =>  p_sr_number,
              p_sender		              =>  lc_sender,
              p_sender_role		          =>  lc_sender_role,
              p_receiver		            =>  lc_receiver,
              p_receiver_role		        =>  lc_receiver_role,
              p_priority		            =>  'MED',
              p_expand_roles		        =>  'N',
              p_action_type		          =>  NULL,
              p_action_code		          =>  'CONFIRMATION',
              p_confirmation		        =>  'N',
              p_message		              =>  lc_message,
              p_url_hyper_link          =>  p_url_link,
              p_subject                 =>  p_subject,
              p_function_name		        =>  NULL,
              p_function_params	        =>  NULL );

      END IF;

 END send_notification;
 /*****************************************************************************
 ******************************************************************************/
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
		p_function_params	IN	VARCHAR2    DEFAULT NULL ) IS

    l_message_id	NUMBER;
    l_notification_id	NUMBER;
    l_ntf_group_id	NUMBER;
    l_source_obj_ext_id	VARCHAR2(200);
    l_user_id		NUMBER;
    l_login_id		NUMBER;
    l_priority		VARCHAR2(30);
    lc_log_message       varchar2(1000);
    l_priority_number	NUMBER;

    CURSOR l_msgid_csr IS
      SELECT cs_messages_s.NEXTVAL
        FROM dual;

    CURSOR l_ntf_csr IS
      SELECT ntf.notification_id
        FROM wf_notifications ntf
       WHERE ntf.group_id = l_ntf_group_id;

    CURSOR l_priority_csr IS
      SELECT meaning
        FROM cs_lookups
       WHERE lookup_type = 'MESSAGE_PRIORITY'
         AND lookup_code = p_priority;

    -- --------------------------------------------------------------------
    -- SetAttributes
    --   Subprocedure used to set the message attibutes that are common to
    --   all the different types of messages
    -- --------------------------------------------------------------------

    PROCEDURE SetAttributes(	p_nid		IN	NUMBER,
                                p_priority      IN      VARCHAR2,
				p_ext_id	IN	VARCHAR2  DEFAULT NULL ) IS
    BEGIN
      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'OBJECT_ID',
			avalue		=>	p_ext_id );

      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'OBJECT_TYPE',
			avalue		=>	p_source_object_type );

      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'SENDER',
			avalue		=>	p_sender );

      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'MESSAGE_TEXT',
			avalue		=>	p_message );

      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'PRIORITY',
			avalue		=>	p_priority );

      WF_NOTIFICATION.SetAttrText(
			nid		=>	p_nid,
			aname		=>	'OBJECT_FORM',
			avalue		=>	p_function_name||':'||p_function_params );

      WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      '#FROM_ROLE',
                        avalue          =>      p_sender_role);

      IF P_SUBJECT IS NOT NULL THEN
            WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      'DISPUTE_ID',
                        avalue          =>      p_subject);
      END IF;

      IF P_URL_HYPER_LINK IS NOT NULL THEN
            WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      'AME_LINK',
                        avalue          =>      p_url_hyper_link);
      END IF;
      -- Fix for bug 2122488--
      Wf_Notification.Denormalize_Notification(p_nid);

    END SetAttributes;


  BEGIN
    -- --------------------------------------------------------------------
    -- Begin of procedure Send_Message
    -- --------------------------------------------------------------------

    -- Get the message ID from the sequence
    OPEN l_msgid_csr;
    FETCH l_msgid_csr INTO l_message_id;
    CLOSE l_msgid_csr;

    --
    -- Attach a '#' character to the object ID if it's not NULL
    --
    IF (p_source_object_ext_id IS NOT NULL) THEN
      l_source_obj_ext_id := '#'||p_source_object_ext_id;
    ELSE
      l_source_obj_ext_id := NULL;
    END IF;

    -- Get the priority value
    OPEN l_priority_csr;
    FETCH l_priority_csr INTO l_priority;
    CLOSE l_priority_csr;

    -- Set priority Number for message.
    -- High (1-49), Medium (50), Low (51-99).
    -- We set arbitrarily : High=25, Medium=50, and Low=75
    IF (p_priority = 'HIGH') THEN
      l_priority_number := 25;
    ELSIF (p_priority = 'MED') THEN
      l_priority_number := 50;
    ELSE
      l_priority_number := 75;
    END IF;


    --
    -- First check to see if an action is being requested
    --
    IF (p_action_type IS NULL) THEN
      --
      -- No Action requested.  We'll be sending an FYI message
      -- Now check and see if expand roles is requested
      --
      IF (p_expand_roles = 'N') THEN

        -- Do not expand roles, just call the Send API
            l_ntf_group_id := WF_NOTIFICATION.Send(
                            role		=>	p_receiver_role,
                            msg_type	=>	'XXCSMESG',
                            msg_name	=>	'FYI_MESSAGE',
                            due_date	=>	NULL,
                            callback	=>	'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK',
                            context		=>	to_char(l_message_id),
                            send_comment	=>	NULL,
                            priority        =>      l_priority_number );
      ELSE

        -- Expand Roles requested, call the SendGroup API instead
        l_ntf_group_id := WF_NOTIFICATION.SendGroup(
                                      role		=>	p_receiver_role,
                                      msg_type	=>	'XXCSMESG',
                                      msg_name	=>	'EXPANDED_FYI_MSG',
                                      due_date	=>	NULL,
                                      callback	=>	'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK',
                                      context		=>	to_char(l_message_id),
                                      send_comment	=>	NULL,
                                      priority        =>      l_priority_number );

      END IF;

      --
      -- For each notification in the group, set up the message attributes.
      -- Note that if the Send API was called, the notification ID will be
      -- the same as the group ID.
      -- We are using a cursor loop until Workflow team provides an API for
      -- updating the notification attributes for the whole group
      --
      FOR l_ntf_rec IN l_ntf_csr LOOP

        l_notification_id := l_ntf_rec.notification_id;

        -- Call the subprocedure to set the notification attributes
        SetAttributes(l_notification_id, l_priority, l_source_obj_ext_id);

      END LOOP;

      l_notification_id := l_ntf_group_id;

    ELSE

      -- Action requested, send the ACTION_REQUEST_MSG message
      l_notification_id := WF_NOTIFICATION.Send(
                          role		=>	p_receiver_role,
                          msg_type	=>	'XXCSMESG',
                          msg_name	=>	'ACTION_REQUEST_MSG',
                          due_date	=>	NULL,
                          callback	=>	'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK',
                          context		=>	to_char(l_message_id),
                          send_comment	=>	NULL,
                          priority        =>      l_priority_number );

      -- Set the notification attributes
      SetAttributes(l_notification_id, l_priority, l_source_obj_ext_id);
    begin
      WF_NOTIFICATION.SetAttrText(
            nid		=>	l_notification_id,
            aname		=>	'ACTION',
            avalue		=>	p_action_type );
    exception
      when others then
        lc_log_message := 'Error while seting attribute '||sqlerrm;

             Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_MESSAGE'
                       ,p_error_message_code =>   'XX_CS_SR02_ERROR_LOG'
                       ,p_error_msg          =>  lc_log_message);
      END;

    END IF;

    -- Get the user information for WHO columns
    l_user_id	:= to_number(FND_PROFILE.VALUE('USER_ID'));
    l_login_id	:= to_number(FND_PROFILE.VALUE('LOGIN_ID'));

    IF (l_user_id IS NULL) THEN
      l_user_id := -1;
    END IF;

    -- Insert a new record into the CS_MESSAGES table
    BEGIN
              INSERT INTO cs_messages (
                          message_id,
                          notification_id,
                          date_sent,
                          last_update_date,
                          last_updated_by,
                          creation_date,
                          created_by,
                          last_update_login,
                          source_object_type_code,
                          source_object_int_id,
                          source_object_ext_id,
                          sender,
                          sender_role,
                          receiver,
                          priority,
                          expand_roles,
                          action_code,
                          confirmation,
                          message,
                          responder,
                          response_date,
                          response,
                          responder_comment )
                  VALUES (
                          l_message_id,
                          l_notification_id,
                          sysdate,
                          sysdate,
                          l_user_id,
                          sysdate,
                          l_user_id,
                          l_login_id,
                          p_source_obj_type_code,
                          p_source_object_int_id,
                          p_source_object_ext_id,
                          p_sender,
                          p_sender_role,
                          p_receiver,
                          p_priority,
                          p_expand_roles,
                          p_action_code,
                          p_confirmation,
                          p_message,
                          NULL,
                          NULL,
                          NULL,
                          NULL );
      EXCEPTION
        WHEN OTHERS THEN
            lc_log_message := 'Error while inserting into table '||sqlerrm;

             Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_MESSAGE'
                       ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_log_message);
      END;

  END Send_Message;



-- ------------------------------------------------------------------------
-- Notification_Callback
--   Callback function for the Messages module.  This procedure will be
--   called by the Workflow Notification system when the recipient has
--   responded.
--   Note that the context parameter will contain the char representation
--   of the MESSAGE_ID.  Parameter text_value and number_value will contain
--   the values of RESPONSE and NOTIFICATION_ID respectively.  See the
--   WF_NOTIFICATION.Respond API for more detail.
-- ------------------------------------------------------------------------

  PROCEDURE Notification_Callback (
		command 	IN	VARCHAR2,
		context		IN	VARCHAR2,
		attr_name	IN	VARCHAR2    DEFAULT NULL,
		attr_type	IN 	VARCHAR2    DEFAULT NULL,
		text_value	IN OUT	NOCOPY VARCHAR2,
		number_value	IN OUT	NOCOPY NUMBER,
		date_value	IN OUT	NOCOPY DATE ) IS

    l_message_id  NUMBER;
    l_user_id	  NUMBER;
    l_login_id	  NUMBER;
    l_comment	  VARCHAR2(2000);
    l_confirmation_nid	NUMBER;
    l_source_type VARCHAR2(100);
    l_source_id   VARCHAR2(100);
    l_message     VARCHAR2(2000);
    l_response    VARCHAR2(30);

    l_status_id       varchar2(100);
    l_sr_notes        XX_CS_SR_NOTES_REC;
    l_note_message    varchar2(2000);
    x_return_status   varchar2(200);
    x_msg_data        varchar2(200);
    lc_prog_code      varchar2(100);
    lc_status         varchar2(50);

    CURSOR l_ntf_csr IS
      SELECT ntf.end_date,
             wf.display_name responder,
             msg.confirmation,
             msg.notification_id,
             msg.sender_role sender,
             msg.source_object_int_id service_req_id
        FROM wf_notifications ntf, wf_roles wf, cs_messages msg
       WHERE msg.message_id = l_message_id
         AND msg.notification_id = ntf.notification_id
         AND ntf.responder = wf.name(+)
         FOR UPDATE OF msg.message_id;

    CURSOR l_response_csr IS
      SELECT meaning
        FROM cs_lookups
       WHERE lookup_type = 'MESSAGE_RESPONSE'
         AND lookup_code = text_value;

    l_ntf_rec  l_ntf_csr%ROWTYPE;

begin
  --
  -- Get the message_id from the context
  --
  l_message_id := to_number(context);

  --
  -- We should never encounter a GET command because we never
  -- have attributes that are based on item attributes.  It we
  -- somehow get here, just return NULL for everything
  --
  IF (upper(command) = 'GET') THEN
    IF (attr_type = 'NUMBER') THEN
      number_value := to_number(NULL);
    ELSIF (attr_type = 'DATE') THEN
      date_value := to_date(NULL);
    ELSE
      text_value := to_char(NULL);
    END IF;

  ELSIF (upper(command) = 'SET') THEN
    --
    -- Do all the work in the COMPLETE command
    --
    null;

  ELSIF (upper(command) = wf_engine.eng_completed) THEN

    -- Get the user information for WHO columns
    l_user_id	:= to_number(FND_PROFILE.VALUE('USER_ID'));
    l_login_id	:= to_number(FND_PROFILE.VALUE('LOGIN_ID'));

    IF (l_user_id IS NULL) THEN
      l_user_id := -1;
    END IF;

    OPEN l_ntf_csr;
    FETCH l_ntf_csr INTO l_ntf_rec;

    -- Get the comment of the responder
    l_comment := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'COMMENT');

    -- Update the row in the CS_MESSAGES table
    UPDATE cs_messages
       SET last_update_date	= sysdate,
           last_updated_by	= l_user_id,
           last_update_login    = l_login_id,
           responder		= l_ntf_rec.responder,
           response_date	= l_ntf_rec.end_date,
           responder_comment	= l_comment,
           response		= text_value
     WHERE CURRENT OF l_ntf_csr;

     /***********************************************************************
     -- Update notes
     ***********************************************************************/

     If l_comment is not null then
        l_sr_notes := XX_CS_SR_NOTES_REC(null,null,null,null);
        l_sr_notes.notes          := text_value;
        l_sr_notes.note_details   := l_comment;
        l_sr_notes.created_by     := uid;
        l_sr_notes.creation_date  := sysdate;
     end if;

   /*   IF text_value = 'ACCEPT' then
            l_status_id := 'Approved';
      else
            l_status_id := 'Cancelled';
      end if; */
      -- update SR
      
      BEGIN
           Update_SR_status(p_sr_request_id  => l_ntf_rec.service_req_id,
                            p_user_id        => l_user_id,
                            p_status         => l_status_id,
                            x_return_status  => lc_status,
                            x_msg_data       => x_msg_data);
         EXCEPTION
           WHEN OTHERS THEN
             X_MSG_DATA := SQLERRM;
      END;
      
      IF l_sr_notes.notes is not null then

         XX_CS_SERVICEREQUEST_PKG.CREATE_NOTE (p_request_id   => l_ntf_rec.service_req_id,
                                          p_sr_notes_rec => l_sr_notes,
                                          p_return_status => x_return_status,
                                          p_msg_data => x_msg_data);

      end if;

    -- If confirmation was requested, we need to send it now
    IF (l_ntf_rec.confirmation = 'Y') THEN

      -- Get the value for response
      OPEN l_response_csr;
      FETCH l_response_csr INTO l_response;
      CLOSE l_response_csr;

      l_source_type := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'OBJECT_TYPE');
      l_source_id   := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'OBJECT_ID');
      l_message     := WF_NOTIFICATION.GetATTRTEXT(l_ntf_rec.notification_id, 'MESSAGE_TEXT');

      l_confirmation_nid := WF_NOTIFICATION.Send(
                            role		=>	l_ntf_rec.sender,
                            msg_type	=>	'XXCSMESG',
                            msg_name	=>	'CONFIRMATION_MESSAGE',
                            due_date	=>	NULL,
                            callback	=>	'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK',
                            context		=>	to_char(l_message_id),
                            send_comment	=>	NULL );

      -- Set up the message attributes
      WF_NOTIFICATION.SetAttrText(
                        nid		=>	l_confirmation_nid,
                        aname		=>	'OBJECT_TYPE',
                        avalue		=>	l_source_type );

      WF_NOTIFICATION.SetAttrText(
                        nid		=>	l_confirmation_nid,
                        aname		=>	'OBJECT_ID',
                        avalue		=>	l_source_id );

      WF_NOTIFICATION.SetAttrText(
                          nid		=>	l_confirmation_nid,
                          aname		=>	'RESPONDER',
                          avalue		=>	l_ntf_rec.responder );

      WF_NOTIFICATION.SetAttrText(
                        nid		=>	l_confirmation_nid,
                        aname		=>	'RESPONSE',
                        avalue		=>	l_response );

      WF_NOTIFICATION.SetAttrText(
                    nid		=>	l_confirmation_nid,
                    aname		=>	'COMMENT',
                    avalue		=>	l_comment );

      WF_NOTIFICATION.SetAttrText(
                      nid		=>	l_confirmation_nid,
                      aname		=>	'MESSAGE',
                      avalue		=>	l_message );
    -- Fix for bug 2122488
    Wf_Notification.Denormalize_Notification(l_confirmation_nid);

    END IF;

    CLOSE l_ntf_csr;

  END IF;

end Notification_Callback;
/****************************************************************************
-- Build Header
*****************************************************************************/
 PROCEDURE send_header(conn IN OUT NOCOPY utl_smtp.connection,
                      name IN VARCHAR2,
                      header IN VARCHAR2) AS
  BEGIN
   If (name = 'Subject') then
   	  utl_smtp.write_data(conn, name || ': =?iso-8859-1?Q?' || utl_raw.cast_to_varchar2(utl_encode.quoted_printable_encode(utl_raw.cast_to_raw(header))) || '?=' || utl_tcp.crlf);
   else
      utl_smtp.write_data(conn, name || ':' || header || utl_tcp.crlf);
   end if;
  END;
/******************************************************************************
    -- Send regular mail
******************************************************************************/
procedure send_email (sender          IN VARCHAR2,
                      recipient       IN VARCHAR2,
                      cc_recipient    IN VARCHAR2 ,
                      bcc_recipient   IN VARCHAR2 ,
                      subject         IN VARCHAR2,
                      message_body    IN VARCHAR2,
                      p_message_type  IN VARCHAR2,
                      IncidentNum     IN VARCHAR2,
                      return_code     OUT NUMBER -- returns SMTP reply code

)
IS

mail_conn         utl_smtp.connection;
crlf              VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
mesg              LONG ;
v_mail_reply      utl_smtp.reply;
lc_smtp_server    VARCHAR2(250);
l_comments        varchar2(2000);
lc_gen_mesg       varchar2(3000);
lx_return_status   varchar2(1);
lx_msg_data        varchar2(2000);
ln_incident_num    number;
ln_sender_id       number;
ln_creator_id      number;
ln_owner_id        number;
lc_dispute_id      varchar2(25);
lc_type_name       varchar2(50);
ln_incident_id     number;
lc_order_num       varchar2(100);
lc_aops_id         varchar2(100);
ln_user_id         number;
lc_url             varchar2(2000);
lc_subject         varchar2(1000);
LT_SR_NOTES        XX_CS_SR_MAIL_NOTES_REC;
mime_type           varchar2(255) := 'text/html';
lc_dispute_msg    varchar2(2000);
ln_status_id      number;
ln_location       NUMBER   := 0;
my_index          NUMBER := 1;
my_recipients     VARCHAR2(32000);
ln_priority       PLS_INTEGER;
lc_problem_code   varchar2(100);
ln_group_id       number;
lc_sender         varchar2(250) := sender;


cursor mesg_cur is
 select message_number||':-'|| message_text message
 from fnd_new_messages
 where message_name like 'XX_CS_DISPUTE%'
 ORDER BY message_number;
 
 mesg_rec mesg_cur%rowtype;

BEGIN

    lt_sr_notes := XX_CS_SR_MAIL_NOTES_REC(null,null,null,null);
   -- Select incident_id and number
    begin
    select cb.incident_id,
           cb.incident_number,
           cb.incident_status_id,
           substr(ct.attribute9,1,3),
           cb.incident_attribute_12,
           cb.incident_attribute_1,
           cb.incident_attribute_9,
           cb.problem_code,
           cb.owner_group_id
    into   ln_incident_id,
           ln_incident_num,
           ln_status_id,
           lc_type_name,
           lc_dispute_id,
           lc_order_num,
           lc_aops_id,
           lc_problem_code,
           ln_group_id
    from  cs_incident_types ct,
          cs_incidents_all_b cb
    where ct.incident_type_id = cb.incident_type_id
    and   cb.incident_id = to_number(IncidentNum);
  exception
    when others then
      lx_msg_data  := 'Error while selecing incident id '||sqlerrm;
      log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_EMAIL'
                       ,p_error_message_code =>   'XX_CS_SR01_ERROR_LOG'
                       ,p_error_msg          =>  lx_msg_data);
  end;
   /*
   lx_msg_data := 'InidentId : '||ln_incident_id||' Type '||p_message_type;
   log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_EMAIL'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  lx_msg_data);
    */
    begin
      select message_text message
      into lc_gen_mesg
      from fnd_new_messages
      where message_name like 'XX_CS_GEN_MSG%';
    exception
      when others then
        lc_gen_mesg := null;
    end;
    /****************************************************************
      -- Update SR for particular SR
    ****************************************************************/
     IF ln_incident_id is not null then

          IF LN_STATUS_ID <> 2 THEN
          begin
            XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(
            P_SR_REQUEST_ID => LN_INCIDENT_ID,
            P_USER_ID    => ln_user_id,
            P_STATUS_ID =>  NULL,
            P_STATUS    => 'Waiting',
            X_RETURN_STATUS => lx_return_status,
            X_MSG_DATA => lx_msg_data);
          exception
            when others then
               lx_msg_data := 'Error while updating InidentId : '||ln_incident_id||' '|| sqlerrm;
                log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_EMAIL'
                           ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                           ,p_error_msg          =>  lx_msg_data);
          end;
          END IF;

          lt_sr_notes.notes          := 'Message sent to: '||recipient ||' for '||p_message_type;
          --lt_sr_notes.note_details   :=  message_body;

          XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id   => ln_incident_id,
                                          p_sr_notes_rec => LT_SR_NOTES,
                                          p_return_status => lx_return_status,
                                          p_msg_data => lx_msg_data);

          -- Move back to group (unassigned) queue
               IF LC_TYPE_NAME IN ('EC ', 'EC') THEN

                          begin
                            /***********************************************************************
                                   -- Update SR
                            ***********************************************************************/
                              update cs_incidents_all_b
                                  set incident_owner_id = null,
                                      unassigned_indicator = 2
                                  where incident_id = ln_incident_id
                                  and   incident_status_id <> 2;

                                        commit;
                            exception
                              when others then
                                 lx_msg_data := 'Error while updating owner '||sqlerrm;
                                 Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.READ_RESPONSE'
                                                ,p_error_message_code =>   'XX_CS_SR02_ERROR_LOG'
                                                ,p_error_msg          =>  lx_msg_data);
                            END ;
              end if;
     end if;
       begin
          select fnd_profile.value('XX_CS_SMTP_SERVER')
          into lc_smtp_server
          from dual;
        exception
          when others then
             lc_smtp_server := 'chrelay.na.odcorp.net';
        end;
        ---
         begin
          select fnd_profile.value('XX_CS_SVC_ACCOUNT')
          into lc_sender
          from dual;
        exception
          when others then
             lc_sender := sender;
        end;
        
        begin
          select a.meaning
            into lc_sender
            from cs_lookups a,
                 jtf_rs_groups_vl b
            where b.accounting_code = a.lookup_code
            and   a.lookup_type = 'XX_CS_SVC_ALIAS'
            and   b.group_id  = ln_group_id;
        exception
          when others then
             lc_sender := lc_sender;
        end;
        
        IF lc_sender is null then
           lc_sender := sender;
        end if;
        
     BEGIN
        mail_conn := utl_smtp.open_connection(lc_smtp_server, 25);
        utl_smtp.helo(mail_conn, lc_smtp_server);
        utl_smtp.mail(mail_conn, sender);
        IF recipient like 'Eorders%' then
          ln_priority := 1;
        end if;
       
      -- clean up any trailing separation characters
              my_recipients := RTRIM(recipient,',; ');
              IF cc_recipient is not null then
                  my_recipients := my_recipients||'; '||cc_recipient;
              end if;
                
              IF bcc_recipient is not null then
                  my_recipients := my_recipients||'; '||bcc_recipient;
              end if;
              -- initialize loop variables
              my_recipients := RTRIM(my_recipients,',; ');
              my_index := 1;
              -- Parse out each recipient and make a call to
              -- UTL_SMTP.RCPT to add it to the recipient list
              WHILE my_index < LENGTH(my_recipients) LOOP
                -- determine multiple recipients by looking for separation characters
                ln_location := INSTR(my_recipients,',',my_index,1);
                IF ln_location = 0 THEN
                  ln_location := INSTR(my_recipients,';',my_index,1);
                END IF;

                IF ln_location <> 0 THEN
                -- multiple recipients, add this one to the recipients list
                UTL_SMTP.RCPT(mail_conn, TRIM(SUBSTR(my_recipients,my_index,ln_location-my_index)));
                my_index := ln_location + 1;
              ELSE
                -- single recipient or last one in list
                UTL_SMTP.RCPT(mail_conn, TRIM(SUBSTR(my_recipients,my_index,LENGTH(my_recipients))));
                my_index := LENGTH(my_recipients);
              END IF;
            END LOOP;
              
      --utl_smtp.rcpt(mail_conn, recipient);
      UTL_smtp.open_data(mail_conn);
      UTL_smtp.write_data(mail_conn, 'MIME-Version: ' || '1.0' || UTL_tcp.CRLF);
      UTL_smtp.write_data(mail_conn, 'Content-Type: ' || 'text/html; charset=utf-8');
      UTL_smtp.write_data(mail_conn, 'Content-Transfer-Encoding: ' || '"8Bit"' ||
      UTL_tcp.CRLF);
    /* ** Sending the header  Body information */
      lc_subject := subject||' for SR#'||ln_incident_num;
      send_header(mail_conn,'From',''||lc_sender||'');
      send_header(mail_conn,'To',''||recipient||'');
      send_header(mail_conn,'Cc',''||cc_recipient||'');
      send_header(mail_conn,'Bcc',''||bcc_recipient||'');
      send_header(mail_conn,'Date',to_char((sysdate-5/24), 'dd Mon yy hh24:mi:ss'));
      send_header(mail_conn,'Subject',lc_subject);
      IF ln_priority is not null then
         send_header(mail_conn, 'X-Priority', ln_priority);
      END IF;
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      ----------------------------------------
      -- Send the main message text
      ----------------------------------------
      -- mime header
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<HTML>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<BODY>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      send_header(mail_conn,'Service Request',ln_incident_num);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      IF lc_order_num is not null then
        send_header(mail_conn,'Order',lc_order_num);
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      end if;
      IF lc_aops_id is not null then
        send_header(mail_conn,'Customer Id',lc_aops_id);
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      end if;
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      UTL_smtp.write_raw_data(mail_conn,utl_raw.cast_to_raw(UTL_tcp.CRLF||'<FONT FACE="Courier New">'||message_body||'</FONT>'));
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);

      IF lc_dispute_id is not null and lc_type_name like 'DRT%' then
       IF lc_problem_code IN ('BT', 'FRE', 'PRC') then
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          BEGIN
             open mesg_cur;
             loop
             fetch mesg_cur into mesg_rec;
             exit when mesg_cur%notfound;

             lc_dispute_msg := mesg_rec.message;
              send_header(mail_conn,'Note',lc_dispute_msg);
               UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
               UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
             end loop;
             close mesg_cur;
          end;

       --   UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        --  send_header(mail_conn,'Dispute Link ',lc_url);
         -- UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
       end if; -- pronlem code
      end if;  --DRT

      IF lc_gen_mesg is not null then
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          send_header(mail_conn,'Note:-',lc_gen_mesg);
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      end if; --gen mesg
     -- send_header(mail_conn,'Instance',lc_instance);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'</BODY>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'</HTML>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
      -- Close the message
      UTL_smtp.close_data(mail_conn);
      UTL_smtp.quit(mail_conn);

    EXCEPTION
      WHEN OTHERS THEN
        lx_msg_data := 'ERROR WHILE SENDING MAIL. '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_EMAIL'
                       ,p_error_message_code =>   'XX_CS_SR01_ERROR_LOG'
                       ,p_error_msg          =>  lx_msg_data);
    --  dbms_output.put_line('error '||lx_msg_data);
    END;
   commit;
END;

/***************************************************************************
  -- Retrive the messages from CallCenter Mail Account
*****************************************************************************/
PROCEDURE Read_Response
AS

POP3_SERVER     varchar2(50);
POP3_PORT       constant number := 110;
POP3_TIMEOUT    constant number := 5;
POP3_OK         constant varchar2(10) := '+OK';
E_POP3_ERROR    exception;
E_READ_TIMEOUT  exception;
pragma          exception_init( E_READ_TIMEOUT, -29276 );
socket          UTL_TCP.connection;
line            varchar2(4000);
r_line          RAW(32767);
msg_id          number;
msg_from        varchar2(4000) := '';
msg_to          varchar2(4000) := '';
msg_sub         varchar2(4000) := '';
from_msg_stamp  varchar2(1000) := '';
msg_body        clob := NULL;
bytes           integer;
crlf            varchar2(2) := chr(13) || chr(10);
hyphen_checker  number := 0;
subject_read_indicator number := 0;
marked_for_deletion number := 0;
userName        varchar2(4000);
password        varchar2(4000);
msgNum          number := 1;
total_msg       number := 0;
process_flag    varchar2(1) := 'Y';


LC_SR_STATUS_ID        VARCHAR2(25);
LC_PROBLEM_CODE        VARCHAR2(50);
LN_TYPE_ID             NUMBER;
LC_RESPONSE_STATUS     VARCHAR2(25);
LC_REQUEST_ID          VARCHAR2(25);
LN_INCIDENT_ID         NUMBER;
LT_SR_NOTES            XX_CS_SR_MAIL_NOTES_REC;
LC_USER_ID             VARCHAR2(200);
i                      number;
X_RETURN_STATUS        VARCHAR2(25);
X_MSG_DATA             VARCHAR2(1000);
LC_INSTANCE            VARCHAR2(25);
LC_DRT_ID              VARCHAR2(100);
LC_DRT_EMAIL           VARCHAR2(150);
LN_RETURN_CODE         NUMBER;
LN_STATUS_ID           NUMBER;
LC_UNDELIVER_MSG       VARCHAR2(150);
LC_BASE64_FLAG         VARCHAR2(1) := 'N';
LC_DECODE_FLAG         VARCHAR2(1) := 'N';
LC_END_FLAG            VARCHAR2(1) := 'N';

/**************************************************************************/
-- send a POP3 command
-- (we expect each command to respond with a +OK)
/*************************************************************************/
FUNCTION WriteToPop( command varchar2 ) 
return varchar2 is
len     integer;
resp    varchar2(4000);

begin
      len := UTL_TCP.write_line( socket, command );
      UTL_TCP.Flush( socket );
    
      -- using a hack to check the popd response
      len := UTL_TCP.read_line( socket, resp );

    If (SUBSTR(resp,1,3) != POP3_OK) then
      raise E_POP3_ERROR;
    end if;

  return( resp );
end WriteToPop;
/***************************************************************************/
/**************************************************************************/
begin
      
    lt_sr_notes := XX_CS_SR_MAIL_NOTES_REC(null,null,null,null);
    
     begin
        select meaning 
        into POP3_SERVER
        from apps.cs_lookups
        where lookup_type = 'XX_CS_POP3_CODE'
        and lookup_code = 'SERVER';
      exception
        when others then
           POP3_SERVER  := 'USCHMSX03.na.odcorp.net';
      end;
 
      begin
       select meaning 
        into userName
        from apps.cs_lookups
        where lookup_type = 'XX_CS_POP3_CODE'
        and lookup_code = 'USERID';
      exception
        when others then
           userName  := 'SVC-CallCenter@na.odcorp.net';
      end;
  
      begin
        select meaning 
        into PASSWORD
        from apps.cs_lookups
        where lookup_type = 'XX_CS_POP3_CODE'
        and lookup_code = 'PASSWD';
      exception
        when others then
           PASSWORD  := NULL;
      end;
    -- open a socket connection to the POP3 server
      socket := UTL_TCP.open_connection(
              remote_host => POP3_SERVER,
              remote_port => POP3_PORT,
              tx_timeout => POP3_TIMEOUT
              );
      -- read the server banner/response from the pop3 daemon
      line := UTL_TCP.get_line(socket);
      -- Testing whether the connection was made successfully
      If (SUBSTR(line,1,3) != POP3_OK) then
        raise E_POP3_ERROR;
      else
          -- authenticate with the POP3 server using the USER and PASS commands
          line := WriteToPop('USER ' || userName);
          line := WriteToPop('PASS ' || password);
    
          If (SUBSTR(line,1,3) != POP3_OK) then
              x_msg_data := 'Error while authentication with password'||line;
              fnd_file.put_line(fnd_file.log,x_msg_data);
              raise E_POP3_ERROR;
          end if;
          line := WriteToPop('STAT');
          line := substr(line, 5, instr(line, ' ', 5)-5);
          total_msg := to_number(line);
           dbms_output.put_line('total msgs '||total_msg);
          /********************************************************************/
          -- This is where we retrieve the specific email message and start
          -- parsing through the data to determine what to do with the message
          -- (i.e., delete it (if it's a returned undeliverable message), copy
          -- contents (i.e., SUBJECT, FROM, BODY, etc.), etc.), assuming that there
          -- are messages in the queue.
          /********************************************************************/
        If (total_msg > 0) then
          LOOP -- loop through all messages
                line := WriteToPop('RETR ' || msgNum);
                LC_REQUEST_ID := null;
                LC_UNDELIVER_MSG := NULL;
                process_flag := 'Y';
                LC_BASE64_FLAG := 'N';
                LC_DECODE_FLAG := 'N';
          BEGIN
            loop -- loop through all parts of current message
            bytes := UTL_TCP.Available( socket );

            If bytes > 0 then
                bytes := UTL_TCP.read_line( socket, line );
                line := replace(line, CHR (13) || CHR (10), '');
          --      dbms_output.put_line('line:   '||line );
                /***************************************************************/
                  -- If FROM part matches, then we know it was a returned
                  -- undeliverable email, so we ignore it, and move to the
                  -- next message.
                /**************************************************************/
                If (instr(upper(trim(line)), upper(trim('Return-path: '))) > 0) or
                  (instr(upper(trim(line)), upper(trim('From: Mail Delivery'))) > 0) or
                 -- (instr(upper(trim(line)), upper(trim('From: SVC-CallCenter@officedepot.com '))) > 0) or
                  (instr(upper(trim(line)), upper(trim('type="multipart/alternative"'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('Subject: Delivery Status Notification'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('Subject: Delivery Status Notification'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('boundary="'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('Subject: Mail System Error'))) > 0) or
                  (instr(upper(trim(substr(line, 1, 11))), upper(trim('Message-ID:'))) > 0) or
                  (instr(upper(trim(substr(line, 1, 12))), upper(trim('In-Reply-To:'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('X-MS-Has-Attach:'))) > 0) or
                  (instr(upper(trim(line)), upper(trim('X-MS-TNEF-Correlator:'))) > 0) or
                  (instr(upper(trim(substr(line, 1, 13))), upper(trim('Thread-Topic:'))) > 0) or
                  (instr(upper(trim(substr(line, 1, 13))), upper(trim('Thread-Index:'))) > 0) or
                   line like 'Content-Type: application/octet-stream%' or line like 'X-AnalysisOut%' or 
                   line like 'Note:%' or line like 'Dispute Link%' --or (trim(line) like '%_NextPart_%' ) 
                   then
             --     dbms_output.put_line('line:   '||line );
                  
                    subject_read_indicator  := 0;
                    IF line like 'Note:%' then
                      LC_END_FLAG := 'Y';
                      process_flag := 'N';
                    end if;
              else 
               -- extracting the various parts of the email message */
                -----Ignoring the multipart messages
            --    dbms_output.put_line('Line  '||process_flag||'  '||line );
                 IF line like 'Content-Type: text/plain;%' then
                    process_flag := 'Y';
                    if (trim(line) like '%X-Brightmail-Tracker%' ) then
                      LC_DECODE_FLAG := 'Y';
                    end if; 
                 end if;
                 
                  IF line like 'Content-Type: multipart%' 
                     or line like 'Content-Type: message%' then
                      process_flag := 'Y';
                          If (trim(line) like '%charset=%' ) then
                            if SUBSTR(SUBSTR(LINE,INSTR(LINE,'charset=')+1),8,10) <> '"us-ascii"' then
                                LC_DECODE_FLAG := 'Y';
                            elsif SUBSTR(SUBSTR(LINE,INSTR(LINE,'charset=')+1),8,7) <> '"UTF-8"' then
                                LC_DECODE_FLAG := 'Y';
                            end if;
                          end if; 
                    end if;
                    
                     If (trim(line) like '%_NextPart_%' ) then
                          LC_DECODE_FLAG := 'Y';
                     end if;
                                  
                    if (trim(line) like '%X-Brightmail-Tracker%' ) then
                      LC_DECODE_FLAG := 'Y';
                    end if;
                 
                 IF trim(line) like 'Content-Transfer-Encoding%base64%' THEN
                     LC_BASE64_FLAG := 'Y';
                 END IF;
                
                 IF line like 'Content-Type: text/html;%' 
                     or line like 'Content-Type: image/jpeg%' then
                     process_flag := 'N';
                 end if;
                 
                 IF LC_BASE64_FLAG = 'Y' then
                         IF trim(line) like '%This is a multi-part message in MIME format.%' then
                          LC_DECODE_FLAG := 'Y';
                         end if;
                         
                         IF trim(line) like '%Motorola-A-Mail%' then
                              LC_DECODE_FLAG := 'Y';
                         end if;
                        
                         IF trim(line) like '%X-Brightmail-Tracker%' then
                              LC_DECODE_FLAG := 'Y';
                         end if;
                       --  dbms_output.put_line('DECODE FLAG  '||LC_DECODE_FLAG||' BASE64 '||LC_BASE64_FLAG );
                 END IF;
                
                 -----
                 IF line like 'From:%' then
                  IF msg_body is null then
                    msg_body := 'Response '||line;
                    msg_body := msg_body || crlf || crlf;
                  end if;
                 end if;
              
                    if instr(upper(trim(substr(line, 1, 23))), upper(trim('Subject: Undeliverable:'))) > 0 then
                      line := trim(replace(line, 'Subject: Undeliverable:'));
                      msg_sub := line ;
                      LC_UNDELIVER_MSG := 'Undeliverable';
                      LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+1),3,7);
                      subject_read_indicator := 1;  
                    elsif instr(upper(trim(substr(line, 1, 13))), upper(trim('Subject: RE: '))) > 0 then
                      line := trim(replace(line, 'Subject: RE: '));
                      msg_sub := line ;
                       IF Line like '%SR#%' THEN
                        LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+1),3,7);
                       END IF;
                    elsif instr(upper(trim(substr(line, 1, 24))), upper(trim('Subject: Service Request'))) > 0 then
                      line := trim(replace(line, 'Subject: Service Request'));
                      msg_sub := line  ;
                        IF LINE LIKE '%Subject: Service Request%' THEN
                          LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Subject: Service Request')+1),24,7);
                        END IF;
                    elsif instr(upper(trim(substr(line, 1, 16))), upper(trim('Service Request:'))) > 0 then
                      IF LC_REQUEST_ID is null or length(lc_request_id) < 7 then
                        LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+1),16,7);
                      end if; 
                    elsif line like '%Service Request:%' then
                      IF LC_REQUEST_ID is null or length(lc_request_id) < 7 then
                        LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+1),16,7);
                      end if; 
                     -- dbms_output.put_line('line# '||line);
                    --  dbms_output.put_line('SR# '||lc_request_id);
                  end if; -- performing extractions for email message component
                /*  if lc_request_id is not null then
                    marked_for_deletion := 1;
                  end if; */
                subject_read_indicator := 1;
              end if; -- checking if email is returned undeliverable or an actual reply from user

          end if; -- checking if bytes > 0
            /*************************************************************************/
            -- We set this flag inside of the if statement that processes the Subject
            -- line because we know the next line will be the beginning of the Body
            /*************************************************************************/
          
             IF (subject_read_indicator > 0) then
              IF process_flag = 'Y' AND LC_END_FLAG = 'N' then
              -- dbms_output.put_line('Line  '||process_flag||'  '||line );
                           
                If ((upper(trim(line)) != '') or (instr(upper(trim(substr(line, 1, 8))), upper(trim('Content-'))) = 0)) then
                   If ((upper(substr(trim(line), 1, 2)) = '--') and (length(line) > 10)) then
                            hyphen_checker := hyphen_checker + 1;
                      else
                     -- dbms_output.put_line('--   '||line ); 
                        If (trim(line) like 'X-MimeOLE:%') then
                              subject_read_indicator := 0;
                          elsif (trim(line) like 'X-Original%') then
                              subject_read_indicator := 0;
                          elsif (trim(line) like 'MIME-Version:%') 
                             OR (trim(line) like '%MIME%')then
                              subject_read_indicator := 0;
                          elsif (upper(line) like '%US-ASCII%') then
                              line := null;
                          elsif ((line) like 'References:%') then
                              line := null;
                          elsif (trim(line) like 'Note:-%' OR
                                  trim(line) like '%Note:-%') then
                              subject_read_indicator := 0;
                              process_flag := 'N';
                              LC_END_FLAG := 'Y';
                          elsif (trim(line) like 'Received:%' ) then
                              subject_read_indicator := 0;
                              process_flag := 'N';
                          elsif (trim(line) like 'http%' ) then
                              subject_read_indicator := 0;
                          elsif (trim(line) like '<http%' ) then
                              subject_read_indicator := 0;
                          --    process_flag := 'N';
                          elsif (trim(line) like 'boundary=%' ) then
                              subject_read_indicator := 0;
                              process_flag := 'N';
                          elsif (trim(line) like '%_NextPart_%' ) then
                              subject_read_indicator := 0;
                              process_flag := 'N'; 
                          elsif (trim(line) like '%Motorola-A-Mail%' ) then
                              subject_read_indicator := 0;
                              process_flag := 'N'; 
                          elsif (trim(line) like '=09' )  then
                              subject_read_indicator := 0;
                          elsif (trim(line) like '=20' )  then
                              subject_read_indicator := 0;
                              line := null;
                          elsif (trim(line) like '%charset=%' ) then
                              subject_read_indicator := 0;
                              line := null;
                          else
                          --- Conversion ----------------
                        --  dbms_output.put_line('Flag   '||lc_base64_flag ||'.'|| LC_DECODE_FLAG); 
                            IF lc_base64_flag = 'Y' AND LC_DECODE_FLAG = 'Y' then
                                --  DBMS_OUTPUT.PUT_LINE('BASE64 DATA');
                                 line := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(line))); 
                            --    DBMS_OUTPUT.PUT_LINE('line '||line);
                                  
                                  If (trim(line) like '%_NextPart_%' ) then
                                    LC_DECODE_FLAG := 'N';
                                  end if;
                                  
                                  IF trim(line) like '%Motorola-A-Mail%' then
                                        LC_DECODE_FLAG := 'N';
                                   end if;
                                    
                                    begin 
                                      msg_body := msg_body || line;
                                    exception
                                      when others then
                                           marked_for_deletion := 1;
                                           msg_sub := 'Error and deleting message for SR# '||LC_REQUEST_ID;
                                           DBMS_OUTPUT.PUT_LINE('line '||line);
                                           fnd_file.put_line(fnd_file.log,msg_sub);
                                    end;
                              else
                                  --  line := replace(line, CHR (13) || CHR (10), '');
                                     line := replace(line, '=20', ' ');
                                     line := replace(line, '=90', ' ');
                                     
                                    begin
                                      msg_body := msg_body || crlf || line ;
                                    exception
                                      when others then
                                         marked_for_deletion := 1;
                                          msg_sub := 'Error and deleting message for SR# '||LC_REQUEST_ID;
                                          DBMS_OUTPUT.PUT_LINE('line '||line);
                                          fnd_file.put_line(fnd_file.log,msg_sub);
                                      end;
                              end if;
                              --- end Conversion ----------------
                           --   DBMS_OUTPUT.PUT_LINE('line '||line);
                            IF UPPER(LINE) LIKE '%APPROVED%' THEN
                                LC_RESPONSE_STATUS := 'APPROVED';
                            END IF;
                          end if;  -- ASCII
                    --    end if; -- hyphen checker
                    end if; -- checking if line begins with "--"
                end if; -- only if it passes our checks to we add the contents to our msg body var
                end if; -- process flag
              end if; -- Subject read indicator
                  
          exit when bytes = 0;
          end loop; -- loop through all parts of current message
          
        --  dbms_output.Put_line('msg '||msg_body);
         --    dbms_output.put_line('SR  |'||LC_REQUEST_ID ||'|');
             
              lt_sr_notes.notes          := 'Response ';
              lt_sr_notes.note_details   := substr(msg_body,1,32760);
            --  dbms_output.put_line('after note |'||LC_REQUEST_ID||'|');
            ------------------Update SR---------------------------------------------
                       BEGIN
                          SELECT  INCIDENT_ID,
                                  INCIDENT_TYPE_ID,
                                  PROBLEM_CODE,
                                  INCIDENT_ATTRIBUTE_4,
                                  INCIDENT_STATUS_ID
                          INTO    LN_INCIDENT_ID,
                                  LN_TYPE_ID,
                                  LC_PROBLEM_CODE,
                                  LC_DRT_ID,
                                  LN_STATUS_ID
                          FROM    CS_INCIDENTS_ALL_B
                          WHERE   INCIDENT_NUMBER = LC_REQUEST_ID;
                       EXCEPTION
                          WHEN OTHERS THEN
                       --   dbms_output.put_line('exception '||sqlerrm);
                              LN_INCIDENT_ID := NULL;
                      END;
               
                IF LN_INCIDENT_ID IS NOT NULL THEN
                
                           marked_for_deletion := 1;
                        IF LC_PROBLEM_CODE IN ('BT', 'FRE', 'PRC') 
                                    AND LC_UNDELIVER_MSG IS NULL THEN
                          IF LC_RESPONSE_STATUS = 'APPROVED' THEN
                              LC_SR_STATUS_ID := 'Respond';
                              -- AM approved and transfer the request to CS team
                              IF ln_status_id <> 2 then
                               BEGIN
                                    XX_CS_DISPUTE_SR_PKG.UPDATE_SR (P_REQUEST_ID  => ln_incident_id,
                                                                    P_NOTES       => 'Acct. Manager Approved the request',
                                                                    X_RETURN_STATUS  => x_return_status,
                                                                    X_MSG_DATA       => x_msg_data);
                                  EXCEPTION
                                    WHEN OTHERS THEN
                                        x_msg_data  := 'Error while updating Dispute SR ID : '|| ln_incident_id||' '||sqlerrm;
                                         Log_Exception ( p_error_location     =>  'XX_CS_MES_PKG.READ_RESPONSE'
                                                       ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                                       ,p_error_msg          =>  x_msg_data
                                                        );
                                  END;
                               end if;
                          else
                              LC_SR_STATUS_ID := 'Closed';

                               IF LC_DRT_ID IS NOT NULL THEN
                                     BEGIN
                                      SELECT EMAIL_ADDRESS
                                      INTO LC_DRT_EMAIL
                                      FROM FND_USER
                                      WHERE USER_ID = TO_NUMBER(LC_DRT_ID);
                                     EXCEPTION
                                       WHEN OTHERS THEN
                                         LC_DRT_EMAIL := NULL;
                                     END;
                                  IF LC_DRT_EMAIL IS NOT NULL THEN
                                                        begin
                                        XX_CS_MESG_PKG.send_email (sender    => 'SVC-CallCenter@officedepot.com',
                                                              recipient      => lc_drt_email,
                                                              cc_recipient   => null ,
                                                              bcc_recipient  => null ,
                                                              subject        => 'Account Manager Response.',
                                                              message_body   => msg_body,
                                                              p_message_type => 'INFO',
                                                              IncidentNum    => ln_incident_id,
                                                              return_code    => ln_return_code );
                                      exception
                                        when others then
                                          X_MSG_DATA := 'Error while sending mail to DRT '|| ln_return_code;
                                          Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.READ_RESPONSE'
                                                        ,p_error_message_code =>   'XX_CS_0003_SEND_ERR'
                                                         ,p_error_msg          =>  X_MSG_DATA);
                                      END;
                                END IF;
                              END IF;
                              IF ln_status_id <> 2 then
                                XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(
                                      P_SR_REQUEST_ID => LN_INCIDENT_ID,
                                      P_USER_ID    => LC_USER_ID,
                                      P_STATUS_ID =>  NULL,
                                      P_STATUS    => LC_SR_STATUS_ID,
                                      X_RETURN_STATUS => X_RETURN_STATUS,
                                      X_MSG_DATA => X_MSG_DATA
                                    );
                              end if;
                          END IF;
                        else
                           IF LN_TYPE_ID = 11004 THEN
                             BEGIN
                               select 2 status_id
                               into ln_status_id 
                                from apps.cs_incident_statuses_tl
                                where name in (select meaning 
                                              from apps.cs_lookups  
                                              where lookup_type = 'XX_CS_WH_STATUS')
                                and incident_status_id = ln_status_id;
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                    NULL;
                                WHEN OTHERS THEN
                                   x_msg_data := 'Error while CLOSE LOOP Status'||LN_INCIDENT_ID;
                                    fnd_file.put_line(fnd_file.log,x_msg_data);
                              END;
                            END IF;
                                
                            LC_SR_STATUS_ID := 'Respond';
                            IF ln_status_id <> 2 then
                              XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(
                                    P_SR_REQUEST_ID => LN_INCIDENT_ID,
                                    P_USER_ID    => LC_USER_ID,
                                    P_STATUS_ID =>  NULL,
                                    P_STATUS    => LC_SR_STATUS_ID,
                                    X_RETURN_STATUS => X_RETURN_STATUS,
                                    X_MSG_DATA => X_MSG_DATA
                                  );
                             end if;
                        END IF; -- Problem code check
                        
                        BEGIN
                          XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id   => ln_incident_id,
                                                          p_sr_notes_rec => lt_sr_notes,
                                                          p_return_status => x_return_status,
                                                          p_msg_data => x_msg_data);
                          commit;
                        exception
                          when others then
                             x_msg_data := 'Error while reading mail box '||sqlerrm;
                           Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.READ_RESPONSE'
                                       ,p_error_message_code =>   'XX_CS_SR01_ERROR_LOG'
                                       ,p_error_msg          =>  x_msg_data);
                        END ;

                 END IF;
                fnd_file.put_line(fnd_file.log,msg_sub);
               --------------------------------------------------------------------------
                -- Delete the Updated message.
                If (marked_for_deletion = 1) then
                  line := WriteToPop('DELE ' || msgNum);
                end if; -- adding email message to queue if it wasn't marked for deletion
    
                -- Resetting our variables that store the parts of the email
                msg_from := '';
                msg_to := '';
                msg_sub := '';
                msg_body := NULL;
                subject_read_indicator := 0;
                marked_for_deletion := 0;
                hyphen_checker := 0;
    
                if (msgNum >= total_msg) then
                exit;
                end if;
                msgNum := msgNum + 1; -- incrementing message counter var
             EXCEPTION
                WHEN OTHERS THEN
                  msg_sub := 'Error in Message '||sqlerrm;
                  --dbms_output.put_line(msg_sub);
                  fnd_file.put_line(fnd_file.log,msg_sub);
                  msgNum := msgNum + 1;
             END;  
          END LOOP;  -- loop through all messages
       end if; -- checking if (total_msg > 0)
        -- close connection.
        line := WriteToPop('QUIT');
        UTL_TCP.close_connection( socket );
      END IF; -- checking whether connection was made successfully
  EXCEPTION
    WHEN OTHERS THEN
      msg_sub := 'Error '||sqlerrm;
      dbms_output.put_line(msg_sub);
      fnd_file.put_line(fnd_file.log,msg_sub);
      marked_for_deletion := 1;
      line := WriteToPop('DELE ' || msgNum);
      line := WriteToPop('QUIT');
      UTL_TCP.close_connection( socket );
end Read_Response;
/*******************************************************************************/
/*******************************************************************************/
END XX_CS_MESG_PKG;
/
show errors;
exit;