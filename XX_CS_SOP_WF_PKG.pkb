CREATE OR REPLACE PACKAGE BODY XX_CS_SOP_WF_PKG AS

g_sys_user_id   number;

 /* $Header: ODCSMAIL.pls on 01/07/09      */
 /****************************************************************************
  *
  * Program Name : XX_CS_SOP_WF_PKG
  * Language     : PL/SQL
  * Description  : Package to maintain email communications.
  * History      :
  *
  * WHO             WHAT                                    WHEN
  * --------------  --------------------------------------- ---------------
  * Raj Jagarlamudi Initial Version                         4/1/10
  * Manikabt Kasu   Made code changes to retrofit as per    1/25/16
  *                 GSCC R12.2.2 Compliance
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
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_SOP_WF_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'IBU'
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
      x_msg_count	      NUMBER;
      x_interaction_id        NUMBER;
      ln_obj_ver              NUMBER;
      ln_msg_index            number;
      ln_msg_index_out        number;
      ln_user_id              number;
      ln_resp_appl_id         number :=  514;
      ln_resp_id              number := 21739;
      ln_status_id            number;
      lc_status               varchar2(50);
      ln_type_id              number;
      lc_type_name            varchar2(250);
      x_workflow_process_id   NUMBER;
      lr_service_request_rec  CS_ServiceRequest_PUB.service_request_rec_type;
      lt_notes_table          CS_SERVICEREQUEST_PUB.notes_table;
      lt_contacts_tab         CS_SERVICEREQUEST_PUB.contacts_table;
      ln_created_by           number;

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
                 name, created_by
          INTO  ln_status_id, lc_status,
                ln_created_by
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = p_status ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_status_id := null;
        END;


   IF ln_status_id is not null THEN
      /***********************************************************************
       -- Update SR Status
       ***********************************************************************/
      IF p_status = 'Approved' then

          cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

             lr_service_request_rec.owner_id               := null;
             lr_service_request_rec.owner_group_id         := null;

                       /*************************************************************************
                         -- Add notes
                        ************************************************************************/
                          lt_notes_table(1).note        := 'Request approved by business' ;
                          lt_notes_table(1).note_detail := 'Request approved by business';
                          lt_notes_table(1).note_type   := 'GENERAL';

                       /**************************************************************************
                           -- Update SR
                        *************************************************************************/

                       cs_servicerequest_pub.Update_ServiceRequest (
                          p_api_version            => 2.0,
                          p_init_msg_list          => FND_API.G_TRUE,
                          p_commit                 => FND_API.G_FALSE,
                          x_return_status          => x_return_status,
                          x_msg_count              => x_msg_count,
                          x_msg_data               => x_msg_data,
                          p_request_id             => p_sr_request_id,
                          p_request_number         => NULL,
                          p_audit_comments         => NULL,
                          p_object_version_number  => ln_obj_ver,
                          p_resp_appl_id           => NULL,
                          p_resp_id                => NULL,
                          p_last_updated_by        => NULL,
                          p_last_update_login      => NULL,
                          p_last_update_date       => sysdate,
                          p_service_request_rec    => lr_service_request_rec,
                          p_notes                  => lt_notes_table,
                          p_contacts               => lt_contacts_tab,
                          p_called_by_workflow     => FND_API.G_FALSE,
                          p_workflow_process_id    => NULL,
                          x_workflow_process_id    => x_workflow_process_id,
                          x_interaction_id         => x_interaction_id   );

                          commit;

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

      else

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
      end if; -- Approved.

       Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.UPDATE_SR_STATUS'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  x_msg_data);
    else
         x_msg_data := p_status ||' Status not setup ';

          Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.UPDATE_SR_STATUS'
                       ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                       ,p_error_msg          =>  x_msg_data);
    END IF;


END Update_SR_Status;

 /*****************************************************************************
 ******************************************************************************/
  PROCEDURE Send_Message (
		p_source_object_type	  IN	VARCHAR2,
		p_source_obj_type_code    IN	VARCHAR2,
		p_source_object_int_id	  IN	NUMBER,
		p_source_object_ext_id	  IN	VARCHAR2,
		p_sender		  IN	VARCHAR2,
		p_sender_role		  IN	VARCHAR2    DEFAULT NULL,
		p_receiver		  IN	VARCHAR2,
		p_receiver_role		  IN	VARCHAR2,
		p_priority		  IN	VARCHAR2,
		p_expand_roles		  IN	VARCHAR2,
		p_action_type		  IN	VARCHAR2    DEFAULT NULL,
		p_action_code		  IN	VARCHAR2    DEFAULT NULL,
		p_confirmation		  IN	VARCHAR2,
		p_message		  IN	VARCHAR2    DEFAULT NULL,
                p_url_hyper_link          IN    VARCHAR2    DEFAULT NULL,
                p_subject                 IN    VARCHAR2    DEFAULT NULL,
		p_function_name		  IN	VARCHAR2    DEFAULT NULL,
		p_function_params	  IN	VARCHAR2    DEFAULT NULL ) IS

    l_message_id	        NUMBER;
    l_notification_id	        NUMBER;
    l_ntf_group_id	        NUMBER;
    l_source_obj_ext_id	        VARCHAR2(200);
    l_user_id		        NUMBER;
    l_login_id		        NUMBER;
    l_priority		        VARCHAR2(30);
    lc_sender_role              varchar2(250);
    lc_log_message              varchar2(1000);
    l_priority_number   	NUMBER;
    lc_sender                   varchar2(100);

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

    PROCEDURE SetAttributes(	  p_nid		    IN	NUMBER,
                                p_priority  IN  VARCHAR2,
                                p_ext_id	  IN	VARCHAR2  DEFAULT NULL ) IS
    BEGIN

       BEGIN
          SELECT decode(wf.orig_system_id,
                  NULL, usr.user_name,
                  wf.display_name) user_name,
                  wf.name user_role
            INTO lc_sender, lc_sender_role
            FROM wf_roles wf, fnd_user usr
           WHERE usr.user_id = to_number(FND_PROFILE.VALUE('USER_ID'))
             AND usr.employee_id = wf.orig_system_id (+)
             AND wf.orig_system(+) = 'PER';
          exception
            when others then
                lc_sender         := 'Store Operations';
                lc_log_message    := 'Error while selecting Sender role '||sqlerrm;
         END;

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
                        avalue		=>	lc_sender );

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
                        avalue		=>	null );

      WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      '#FROM_ROLE',
                        avalue          =>      lc_sender_role);

      IF P_SUBJECT IS NOT NULL THEN
            WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      'SUBJECT',
                        avalue          =>      p_subject);
      END IF;

      IF P_URL_HYPER_LINK IS NOT NULL THEN
            WF_NOTIFICATION.SetAttrText(
                        nid             =>      p_nid,
                        aname           =>      'AME_LINK',
                        avalue          =>      p_url_hyper_link);
      END IF;

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
    IF (p_action_code = 'FYI') THEN
      --
      -- No Action requested.  We'll be sending an FYI message
      -- Now check and see if expand roles is requested
      --
      IF (p_expand_roles = 'N') THEN

        -- Do not expand roles, just call the Send API
            l_ntf_group_id := WF_NOTIFICATION.Send(
                            due_date	=>	NULL,
                            role		=> p_receiver_role,
                            msg_type	=>	'XXCSSOP',
                            msg_name	=>	'FYI_MESSAGE',
                            callback	=>	'XX_CS_SOP_WF_PKG.NOTIFICATION_CALLBACK',
                            context		=>	to_char(l_message_id),
                            send_comment	=>	NULL,
                            priority        =>      l_priority_number );
      ELSE

        -- Expand Roles requested, call the SendGroup API instead
        l_ntf_group_id := WF_NOTIFICATION.SendGroup(
                                      role		    =>	p_receiver_role,
                                      msg_type	  =>	'XXCSSOP',
                                      msg_name	  =>	'EXPANDED_FYI_MSG',
                                      due_date	  =>	NULL,
                                      callback	  =>	'XX_CS_SOP_WF_PKG.NOTIFICATION_CALLBACK',
                                      context		  =>	to_char(l_message_id),
                                      send_comment =>	NULL,
                                      priority     =>      l_priority_number );

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

    ELSIF (p_action_code = 'ACTION') THEN

      -- Action requested, send the ACTION_REQUEST_MSG message
      l_notification_id := WF_NOTIFICATION.Send(
                          role		=>	p_receiver_role,
                          msg_type	=>	'XXCSSOP',
                          msg_name	=>	'ACTION_REQUEST_MSG',
                          due_date	=>	NULL,
                          callback	=>	'XX_CS_SOP_WF_PKG.NOTIFICATION_CALLBACK',
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

             Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.SEND_MESSAGE'
                       ,p_error_message_code =>   'XX_CS_SR02_ERROR_LOG'
                       ,p_error_msg          =>  lc_log_message);
      END;

    ELSIF (p_action_code = 'REMINDER') THEN

      -- Action requested, send the ACTION_REQUEST_MSG message
      l_notification_id := WF_NOTIFICATION.Send(
                          role		=>	p_receiver_role,
                          msg_type	=>	'XXCSSOP',
                          msg_name	=>	'CONFIRMATION_MESSAGE',
                          due_date	=>	NULL,
                          callback	=>	'XX_CS_SOP_WF_PKG.NOTIFICATION_CALLBACK',
                          context		=>	to_char(l_message_id),
                          send_comment	=>	NULL,
                          priority        =>      l_priority_number );

    END IF;

    -- Get the user information for WHO columns
    l_user_id	:= to_number(FND_PROFILE.VALUE('USER_ID'));
    l_login_id	:= to_number(FND_PROFILE.VALUE('LOGIN_ID'));

    IF (l_user_id IS NULL) THEN
      l_user_id := -1;
    END IF;

    IF l_notification_id IS NOT NULL THEN
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
                          p_source_object_ext_id,
                          l_login_id,
                          p_source_obj_type_code,
                          p_source_object_int_id,
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

             Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.SEND_MESSAGE'
                       ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_log_message);
      END;

    END IF;

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
    lc_return_status   varchar2(200);
    lc_msg_data        varchar2(200);
    lc_prog_code      varchar2(100);
    lc_status         varchar2(50);
    -- Reject Mail variables
   lc_message_body           LONG;
   lc_mesg                   LONG ;
   lc_html_msg               LONG;
   lc_subject                varchar2(250);
   lc_source_object          varchar2(50)      := 'Service Request';
   lc_source_obj_type        varchar2(25)      := 'INC';
   lc_sender                 varchar2(250);
   ln_approval               number := 0;
   lc_sub_name               varchar2(150);
   lc_submittor              varchar2(25);
   lc_fun_url                varchar2(250)  := fnd_profile.value('XX_CS_SOP_FUNTION_URL');
   lc_url                    varchar2(2000) := fnd_profile.value('XX_CS_SOP_LINK_URL');
   lc_function_params        varchar2(250);
   lc_err_msg                varchar2(2000);
   ln_incident_num           number;
   lc_email_address          varchar2(250);


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
  lc_fun_url := lc_fun_url||ln_incident_num;
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
        l_sr_notes.notes          := 'Action Response';
        l_sr_notes.note_details   := l_comment;
        l_sr_notes.created_by     := uid;
        l_sr_notes.creation_date  := sysdate;
     end if;

     begin
        select cl.name
        into lc_status
        from cs_incidents_all_b cb,
             cs_incident_statuses_tl cl
        where cl.incident_status_id = cb.incident_status_id
        and  cb.incident_id = l_ntf_rec.service_req_id;
     end;

      IF text_value = 'ACCEPT' then
         if lc_status = 'Pending Approval' then
            l_status_id := 'Awaiting Final Approval';
         else
            l_status_id := 'Pending Approval';
         end if;
      elsif text_value = 'REJECT' then
         if lc_status = 'Pending Approval' then
            l_status_id := 'Cancelled By Ops';
         else
            l_status_id := 'Cancelled By User';
         end if;
      end if;

      BEGIN
           Update_SR_status(p_sr_request_id  => l_ntf_rec.service_req_id,
                            p_user_id        => l_user_id,
                            p_status         => l_status_id,
                            x_return_status  => lc_return_status,
                            x_msg_data       => lc_msg_data);
         EXCEPTION
           WHEN OTHERS THEN
             LC_MSG_DATA := SQLERRM;
      END;

      IF l_sr_notes.notes is not null then

         XX_CS_SERVICEREQUEST_PKG.CREATE_NOTE (p_request_id   => l_ntf_rec.service_req_id,
                                          p_sr_notes_rec => l_sr_notes,
                                          p_return_status => lc_return_status,
                                          p_msg_data => lc_msg_data);

      end if;

      IF text_value = 'ACCEPT' then

        IF l_status_id = 'Pending Approval' then

          Task_creation (p_incident_id  => l_ntf_rec.service_req_id,
                         x_return_status    => lc_status,
                         x_return_msg       => LC_msg_data);
        end if;
      elsif text_value = 'REJECT' then

            begin
                select incident_number,
                       created_by
                into   ln_incident_num,
                       l_user_id
                from cs_incidents_all_b
                where incident_id = l_ntf_rec.service_req_id;
            end;

            lc_sender        := 'Store Operations';
            lc_message_body  := 'Request# '||ln_incident_num ||' is not approved ';
            lc_subject       := 'Request#'||ln_incident_num||'  Rejected';

            begin
                select email_address
                into lc_submittor
                from fnd_user
                where user_id = l_user_id;
               exception
                when others then
                  lc_message_body  := 'Request# '||ln_incident_num ||' is not approved ';
                  lc_message_body := lc_message_body ||' Submittor email id is not found ';
                  lc_submittor  := '491862';
              end;
              lc_url := lc_url||ln_incident_num;


            send_email(email_address_in => lc_email_address,
                    user_id          => l_user_id,
                    subject          => lc_subject,
                    msg_body         => lc_message_body,
                    srID             => l_ntf_rec.service_req_id
                  );

      End if;

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
                            msg_type	=>	'XXCSSOP',
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
/*************************************************************************************
 --- Store Portal Approval notification
**************************************************************************************/
PROCEDURE SOP_PROCEDURE ( P_REQUEST_ID      IN NUMBER,
                          P_REQUEST_NUMBER  IN NUMBER,
                          P_REQUEST_TYPE    IN VARCHAR2,
                          P_USER_ID         IN NUMBER,
                          P_SENDER_ROLE     IN VARCHAR2,
                          P_STATUS          IN OUT NOCOPY VARCHAR2,
                          P_ERR_MSG         IN OUT NOCOPY VARCHAR2)
IS
 lc_message_body           LONG;
 lc_mesg                   LONG ;
 lc_html_msg               LONG;
 lc_source_object          varchar2(50)      := 'Service Request';
 lc_source_obj_type        varchar2(25)      := 'INC';
 lc_sender                 varchar2(250);
 lc_sendor_role            varchar2(50);
 ln_approval               number := 0;
 lc_director               varchar2(50);
 lc_dir_name               varchar2(150);
 lc_submittor              varchar2(150);
 lc_fun_url                varchar2(250) :=  fnd_profile.value('XX_CS_SOP_FUNTION_URL');
 lc_url                    varchar2(2000) := fnd_profile.value('XX_CS_SOP_FUNTION_URL')||p_request_number;
 lc_function_params        varchar2(250);
 lc_err_msg                varchar2(2000);
 lc_dir_msg     long;


BEGIN
       lc_fun_url := lc_fun_url||p_request_number;

        begin
          select j.approval_authority, nvl(f.description,user_name),
                 f.user_name
           into ln_approval, lc_submittor, lc_sendor_role
              from per_all_assignments_f A,
                   per_jobs J,
                   fnd_user f
              where f.employee_id = a.person_id
              and  A.job_id=J.job_id
              and  f.user_id = p_user_id;
         exception
            when others then
                ln_approval := 0;
          end;

          IF ln_approval <> 120 then
            begin
              select a.assignment_number, p.full_name
               into lc_director, lc_dir_name
                from per_all_assignments_f a,
                       per_all_people_f p,
                       per_jobs j
                where j.job_id = a.job_id
                and  p.person_id = a.person_id
                and trunc(sysdate) between p.effective_start_date and p.effective_end_date
                and trunc(sysdate) between a.effective_start_date and a.effective_end_date
                and   j.approval_authority = 120
                and rownum < 2
                connect by prior a.supervisor_id = a.person_id
                start with a.person_id = (select employee_id from fnd_user
                                            where user_id = p_user_id)
                order by a.ass_attribute4;
            exception
              when others then
                lc_director := null;
                lc_dir_name := null;
            end;
          END IF;
           --  lc_function_params := 'request_id='||p_request_id;

        IF LC_DIRECTOR IS NOT NULL THEN
         lc_sender        := p_sender_role;
         lc_message_body  := 'Communication Request# '||p_request_number||' submitted by '||lc_submittor||' for '||p_request_type||'.  Please approve the request.';
      BEGIN
      SELECT MESSAGE_TEXT
      INTO lc_dir_msg
      FROM FND_NEW_MESSAGES
      WHERE MESSAGE_NAME = 'XX_CS_SOP_DIR_CONF';
       EXCEPTION
      WHEN OTHERS THEN
        lc_dir_msg := 'The Request has been due to no response and no further action will be taken. You may re-submit for consideration as a new request';
      END;
         lc_message_body :=   lc_dir_msg;

          begin
            select meaning, description
            into lc_director, lc_dir_name
            from FND_LOOKUP_VALUES_VL
            where lookup_type like 'XX_CS_SOP_DIR_ID'
            and lookup_code = 'DIR_ID';
           exception
            when others then

              lc_dir_name  := 'Jagarlamudi, Rajeswari';
              lc_director  := '491862';
          end;
          BEGIN
               XX_CS_SOP_WF_PKG.Send_Message(
                  p_source_object_type	  =>  lc_source_object,
                  p_source_obj_type_code  =>  lc_source_obj_type,
                  p_source_object_int_id  =>  p_request_id,
                  p_source_object_ext_id  =>  p_request_number,
                  p_sender		  =>  lc_sender,
                  p_sender_role		  =>  lc_sendor_role,
                  p_receiver		  =>  lc_dir_name,
                  p_receiver_role	  =>  lc_director,
                  p_priority		  =>  'HIGH',
                  p_expand_roles	  =>  'N',
                  p_action_type		  =>  'APPROVE',
                  p_action_code		  =>  'ACTION',
                  p_confirmation	  =>  'N',
                  p_message		  =>  lc_message_body,
                  p_url_hyper_link        =>  LC_URL,
                  p_function_name	  =>  lc_fun_url, --'CSXSRISR',
                  p_function_params	  =>  lc_function_params );

          EXCEPTION
           WHEN OTHERS THEN
               lc_err_msg := 'ERROR while SENDING NOTIFICATION'||sqlerrm;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.SOP_PROCEDEURE'
                           ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                           ,p_error_msg          =>  lc_err_msg
                          );
          END;

        END IF;

END SOP_PROCEDURE;
/******************************************************************************
 -- Task Assignment
*******************************************************************************/
PROCEDURE Task_assignment (p_task_id        IN NUMBER,
                           p_resource_id    IN NUMBER,
                           x_return_status  OUT NOCOPY VARCHAR2,
                           x_return_msg     OUT NOCOPY VARCHAR2)
IS

l_user_name           fnd_user.user_name%TYPE := 'CS_ADMIN';
l_task_id             jtf_tasks_b.task_id%TYPE := P_TASK_ID;
l_resource_id         jtf_rs_emp_dtls_vl.resource_id%TYPE := p_resource_id;
l_show_on_cal         jtf_task_all_assignments.show_on_calendar%TYPE := 'N';
l_assignment_status   jtf_task_statuses_vl.name%TYPE := 'Accepted';

cursor c_login_user (b_user_name VARCHAR2) is
select user_id
from fnd_user
where user_name = b_user_name;

cursor c_assignee is
select resource_id
from jtf_rs_emp_dtls_vl r
where r.resource_id = l_resource_id;

cursor c_assignment_status (b_status VARCHAR2) is
select task_status_id
from jtf_task_statuses_vl
where name = b_status
and assignment_status_flag = 'Y';

l_user_id               NUMBER;
l_assignee_id           NUMBER;
l_assignment_status_id  NUMBER;
l_task_assignment_id    NUMBER;
l_return_status         VARCHAR2(1);
l_msg_count             NUMBER;
l_msg_data              VARCHAR2(1000);

BEGIN

      open c_login_user(l_user_name);
      fetch c_login_user into l_user_id;
        if c_login_user%NOTFOUND then
        close c_login_user;
          raise_application_error(-20000, 'User name '||l_user_name||' is not found.');
        end if;
       close c_login_user;
        dbms_output.put_line('User Id : '||l_user_id);
      open c_assignee;
      fetch c_assignee into l_assignee_id;
      if c_assignee%NOTFOUND then
      close c_assignee;
        raise_application_error(-20000,'Employee resource id '||l_resource_id||' is not found.');
      end if;
      close c_assignee;
      open c_assignment_status(l_assignment_status);
      fetch c_assignment_status into l_assignment_status_id;
      if c_assignment_status%NOTFOUND then
      close c_assignment_status;
        raise_application_error(-20000,'Assignment status '||l_assignment_status||' is not found.');
      end if;
      close c_assignment_status;
      fnd_global.apps_initialize(l_user_id, 0, 690);
          jtf_task_assignments_pub.create_task_assignment(
                        p_api_version => 1.0,
                        p_init_msg_list => fnd_api.g_true,
                        p_commit => fnd_api.g_false,
                        p_task_assignment_id => NULL,
                        p_task_id => l_task_id,
                        p_resource_type_code => 'RS_GROUP',
                        p_resource_id => l_assignee_id,
                        p_assignment_status_id => l_assignment_status_id,
                        p_show_on_calendar => l_show_on_cal,
                        x_return_status => l_return_status,
                        x_msg_count => l_msg_count,
                        x_msg_data => l_msg_data,
                        x_task_assignment_id => l_task_assignment_id
                        );
          IF l_return_status <> fnd_api.g_ret_sts_success THEN
                  IF l_msg_count > 0 THEN
                    l_msg_data := NULL;
                    FOR i IN 1..l_msg_count LOOP
                    l_msg_data := l_msg_data ||' '||fnd_msg_pub.get(1,'F');
                    END LOOP;
                    fnd_message.set_encoded(l_msg_data);
                    dbms_output.put_line(l_msg_data);
                  END IF;
                  ROLLBACK;
            ELSE
                  dbms_output.put_line('l_task_assignment_id = '||l_task_assignment_id);
                  dbms_output.put_line('Return Status = '||l_return_status);
                  COMMIT;
            END IF;
end;            
/******************************************************************************
   Task creation
******************************************************************************/
PROCEDURE Task_creation (p_incident_id      in number,
                         x_return_status    out nocopy varchar2,
                         x_return_msg       out nocopy varchar2)
IS

lc_message            varchar2(2000);
ln_task_status_id     number;
ln_task_priority      number;
ln_template_id        number;
ln_assignee_id        number;
LC_NOTES              varchar2(2000);
ln_incident_num       number;
LN_GROUP_ID           number;
ln_task_id            number;
lc_type_name          varchar2(250);
ln_task_group         number;

lc_fun_url            varchar2(250)  := fnd_profile.value('XX_CS_SOP_FUNTION_URL');
lc_url                varchar2(2000) := fnd_profile.value('XX_CS_SOP_FUNTION_URL');
lc_function_params    varchar2(250);
lc_source_object      varchar2(50)   := 'Service Request';
lc_source_obj_type    varchar2(25)   := 'INC';
lc_sender             varchar2(250);
lc_sendor_role        varchar2(250);
ln_approval           number := 0;
lc_director           varchar2(50);
lc_dir_name           varchar2(150);
lc_submittor          varchar2(150);
lc_message_body       LONG;
ln_user_id            number;
lc_email_address      varchar2(250);

cursor sop_task_cur is
select tt.name,tt.task_type_id,
       ct.attribute3
from cs_incident_types_vl ct,
     jtf_task_types_vl tt
where ct.attribute8 = tt.name
and   ct.name in (select distinct SRTYPE
                  from XX_CS_ISUPPORT_SURVEY
                  where srnumber = ln_incident_num);

cursor sop_app_cur is
select ct.name, ct.attribute3
from cs_incident_types_vl ct
where ct.name in (select distinct SRTYPE
                  from XX_CS_ISUPPORT_SURVEY
                  where srnumber = ln_incident_num
                  and srtype <> lc_type_name);

BEGIN
     BEGIN
       SELECT CB.INCIDENT_NUMBER,
              CB.OWNER_GROUP_ID,
              CT.NAME,
              CB.CREATED_BY
       INTO LN_INCIDENT_NUM,
            LN_GROUP_ID,
            LC_TYPE_NAME,
            LN_USER_ID
       FROM CS_INCIDENTS_ALL_B CB,
            CS_INCIDENT_TYPES_TL CT
       WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID
       AND CB.INCIDENT_ID = P_INCIDENT_ID;
    EXCEPTION
      WHEN OTHERS THEN
        LN_INCIDENT_NUM := NULL;
    END;

    lc_url := lc_url||ln_incident_num;
    lc_fun_url := lc_fun_url||ln_incident_num;

     BEGIN
          SELECT TASK_STATUS_ID
          INTO LN_TASK_STATUS_ID
          FROM JTF_TASK_STATUSES_VL
          WHERE NAME = 'Open';
        EXCEPTION
            WHEN OTHERS THEN
              LN_TASK_STATUS_ID := 15;
        END;

        LN_TASK_PRIORITY := 2;

      LC_MESSAGE    := 'Before creating Task '||' '||ln_incident_num;

              Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                             ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                             ,p_error_msg          =>  lc_message);

     FOR sop_task_rec IN sop_task_cur
     LOOP

        ln_task_group := sop_task_rec.attribute3;

        IF ln_task_group is null then
          ln_task_group := ln_group_id;
        end if;

        LC_MESSAGE    := lc_type_name ||'Task created for '||' '||ln_incident_num;

              Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                             ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                             ,p_error_msg          =>  lc_message);


        BEGIN
            SELECT TASK_TEMPLATE_ID
            INTO LN_TEMPLATE_ID
            FROM JTF_TASK_TEMPLATES_VL
            WHERE TASK_TYPE_ID = SOP_TASK_REC.TASK_TYPE_ID;
        EXCEPTION
          WHEN OTHERS THEN
             LN_TEMPLATE_ID := NULL;
        END;

       IF sop_task_rec.task_type_id is not null then
         BEGIN
              XX_CS_SR_TASK.CREATE_NEW_TASK
                    ( p_task_name          => sop_task_rec.name
                    , p_task_type_id       => sop_task_rec.task_type_id
                    , p_status_id          => ln_task_status_id
                    , p_priority_id        => ln_task_priority
                    , p_Planned_Start_date => sysdate
                    , p_planned_effort     => null
                    , p_planned_effort_uom => null
                    , p_notes              => lc_notes
                    , p_source_object_id   => p_incident_id
                    , x_error_id           => x_return_status
                    , x_error              => x_return_msg
                    , x_new_task_id        => ln_task_id
                    , p_note_type          => null
                    , p_note_status        => null
                    , p_Planned_End_date   => null
                    , p_owner_id           => ln_task_group
                    , p_attribute_1	 => null
                    , p_attribute_5	 => null
                    , p_attribute_2	 => null
                    , p_attribute_3	 => null
                    , p_attribute_4	 => null
                    , p_attribute_6	 => null
                    , p_attribute_7	 => null
                    , p_attribute_8	 => null
                    , p_attribute_9	 => null
                    , p_attribute_10	 => null
                    , p_attribute_11	 => null
                    , p_attribute_12	 => null
                    , p_attribute_13	 => null
                    , p_attribute_14	 => null
                    , p_attribute_15	 => null
                    , p_context		 => null
                    , p_assignee_id  => ln_assignee_id
                    , p_template_id  => ln_template_id
                  );
            EXCEPTION
              WHEN OTHERS THEN
                lc_message := 'Error while callin new task '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                   ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                   ,p_error_msg          =>  lc_message);
            END;

      end if;
      end loop;

      -- FYI notification


            lc_sender        := 'Store Operations';
            lc_message_body  := 'Communication Request# '||ln_incident_num;

            begin
                select meaning, description
                into lc_director, lc_dir_name
                from FND_LOOKUP_VALUES_VL
                where lookup_type like 'XX_CS_SOP_DIR_ID'
                and lookup_code = 'BUS_ID';
               exception
                when others then
                  lc_dir_name  := 'Jagarlamudi, Rajeswari';
                  lc_director  := '491862';
              end;

              begin
                select user_name
                into lc_sendor_role
                from fnd_user
                where user_id = ln_user_id;
              exception
                 when others then
                   lc_sendor_role := lc_sender;
              end;

              lc_message_body := lc_message_body || 'Submitted by '||lc_sendor_role||' for Type '||lc_type_name||'. Details are attached';
              lc_message := 'Request#'||ln_incident_num||' created for type '||lc_type_name;



            begin
                select description
                into lc_email_address
                from FND_LOOKUP_VALUES_VL
                where lookup_type like 'XX_CS_SOP_DIR_ID'
                and lookup_code = 'FYI_ID';
               exception
                when others then
                  lc_email_address := 'rjagarlamudi@officedepot.com';
              end;

         send_email(email_address_in => lc_email_address,
                    user_id          => ln_user_id,
                    subject          => lc_message,
                    msg_body         => lc_message_body,
                    srID             => p_incident_id
                  );


      FOR sop_app_rec IN sop_app_cur
      LOOP

         lc_url := lc_url||ln_incident_num;

         BEGIN
               XX_CS_SOP_WF_PKG.Send_Message(
                  p_source_object_type	    =>  lc_source_object,
                  p_source_obj_type_code    =>  lc_source_obj_type,
                  p_source_object_int_id    =>  p_incident_id,
                  p_source_object_ext_id    =>  ln_incident_num,
                  p_sender		    =>  lc_sender,
                  p_sender_role		    =>  lc_sender,
                  p_receiver		    =>  lc_dir_name,
                  p_receiver_role	    =>  lc_director,
                  p_priority		    =>  'HIGH',
                  p_expand_roles	    =>  'N',
                  p_action_type		    =>  'APPROVE',
                  p_action_code		    =>  'ACTION',
                  p_confirmation	    =>  'N',
                  p_message		    =>  lc_message_body,
                  p_url_hyper_link          =>  LC_URL,
                  p_function_name	    =>  lc_fun_url, --'CSXSRISR',
                  p_function_params	    =>  lc_function_params );
          EXCEPTION
           WHEN OTHERS THEN
               lc_message := 'ERROR while SENDING NOTIFICATION'||sqlerrm;
                 Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.TASK_CREATION'
                           ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                           ,p_error_msg          =>  lc_message
                          );
          END;

     END LOOP;

END;
/******************************************************************************
  -- FYI mail
*******************************************************************************/
procedure StartFYIProcess (
   roleName in varchar2,
   srID    in number,
   subject in varchar2,
   content   Wf_Engine.TextTabTyp,
   ProcessOwner in varchar2,
   Workflowprocess in varchar2 ,
   item_type in varchar2 )
IS

ItemType varchar2(30) := 'XXIBUSRD';
ItemKey  varchar2(200) := 'NOTIF_' || roleName;
ItemUserKey varchar2(200) := roleName;
lc_Workflowprocess  varchar2(50) := 'IBU_SENDMAIL';
lc_fun_url          varchar2(250)  := fnd_profile.value('XX_CS_SOP_FUNTION_URL');
i number := 0;
ln_sr_num           number;

cnt number := 0;
l_user varchar2(50);
seq number := 0;
create_seq varchar2(50) := 'create sequence IBU_SR_NOTIFICATION_S';
get_seq varchar2(50) := 'select ' || 'IBU_SR_NOTIFICATION_S' || '.nextval from dual';

begin
   /* Get schema name */
  select user into l_user from dual;

  /* Get sequence for item key to be unique */
  select count(*) into cnt from all_objects
  where object_name like 'IBU_SR_NOTIFICATION_S'
  and object_type = 'SEQUENCE'
  and owner = l_user;

  select incident_number into ln_sr_num from cs_incidents_all_b
  where incident_id = srid;

  lc_fun_url := lc_fun_url||ln_sr_num;

   Log_Exception ( p_error_location  =>  'XX_CS_SOP_WF_PKG.StartFYIProcess'
                   ,p_error_message_code =>   'XX_CS_0001_SUCCESS_LOG'
                   ,p_error_msg          =>  lc_fun_url);

  if cnt = 0 then
     execute immediate create_seq;
   else
     execute immediate get_seq into seq;
  end if;

  ItemKey := roleName||seq;

  wf_engine.CreateProcess(itemtype => ItemType,
                           itemkey => ItemKey,
                           process => lc_WorkflowProcess );

  wf_engine.SetItemUserKey(itemtype => Itemtype,
                            itemkey => Itemkey,
                            userkey => ItemUserKey);

  wf_engine.SetItemAttrText(itemtype => Itemtype,
                             itemkey => Itemkey,
                             aname => 'IBU_ROLE',
                             avalue => roleName);

  wf_engine.SetItemAttrText (itemtype => Itemtype,
                              itemkey => Itemkey,
                              aname => 'IBU_SUBJECT_ITEM',
                              avalue => subject);

   wf_engine.SetItemAttrText (itemtype => Itemtype,
                              itemkey => Itemkey,
                              aname => 'ODIBU_FORM',
                              avalue => lc_fun_url);

  wf_engine.SetItemAttrNumber(itemtype => Itemtype,
                              itemkey => Itemkey,
                              aname => 'IBUSRID',
                              avalue => srID);

  wf_engine.SetItemOwner(itemtype => Itemtype,
                         itemkey => Itemkey,
                         owner => roleName);

  for i in 1..8 loop
    if(i = 1)  then
      wf_engine.SetItemAttrText(itemtype => Itemtype,
                             itemkey => Itemkey,
                             aname => 'IBU_ITEM_CONTENT',
                             avalue => content(i));
    else
      wf_engine.SetItemAttrText(itemtype => Itemtype,
                             itemkey => Itemkey,
                             aname => 'IBUCONTENT'||(i-1),
                             avalue => content(i));
    end if;
   end loop;

  wf_engine.StartProcess (itemtype => Itemtype,
			  itemkey => Itemkey );

  end StartFYIProcess;
/****************************************************************************
*****************************************************************************/

procedure send_email(
            email_address_in in varchar2,
            user_id          in varchar2,
            subject          in varchar2,
            msg_body         in varchar2,
            srID             in number)
as

  user_name               varchar2(100) := null;
  user_display_name       varchar2(100) := null;
  language                varchar2(100) := 'AMERICAN';
  territory               varchar2(100) := 'America';
  description             varchar2(100) := NULL;
  notification_preference varchar2(100) := 'MAILTEXT';
  email_address           varchar2(100) := NULL;
  fax                     varchar2(100) :=NULL;
  status                  varchar2(100) := 'ACTIVE';
  expiration_date         varchar2(100) := NULL;
  role_name               varchar2(100) := NULL;
  role_display_name       varchar2(100) := NULL;
  role_description        varchar2(100) := NULL;
  wf_id                   Number;
  msg_type                varchar2(100) := 'IBU_SUBS';
  msg_name                varchar2(100) := 'IBU_MESG';
  due_date                date := NULL;
  callback                varchar2(100) := NULL;
  context                 varchar2(100) := NULL;
  send_comment            varchar2(100) := NULL;
  priority                number := null;
  email_content           Wf_Engine.TextTabTyp;
  email_content_count_end number := 1;
  temp_email_msg_body     varchar2(32000) := null;
  truncateCharNum         number := 0; -- added by wei ma
  retainCharNum           number := 0;
  i                       number := 1;
  finaltotalCharNum       number := 0;
  originatotalCharNum     number := 0;
  temp_email_content_holder varchar2(16000) := null;

  duplicate_user_or_role  exception;
  PRAGMA  EXCEPTION_INIT (duplicate_user_or_role, -20002);

begin

  role_name := 'IBUSR_'||email_address_in;
  role_display_name := user_id; --actual user fullName
  email_address := email_address_in;

  temp_email_msg_body := substr(msg_body, 0, 32000);

  originatotalCharNum := length(temp_email_msg_body);

  while (i < 9 ) loop
     if(finaltotalCharNum < originatotalCharNum) then
       temp_email_content_holder := substr(temp_email_msg_body, 0,4000);
        IBU_REQ_PKG.check_string_length_bites(
            p_string => temp_email_content_holder, --email_content(i),
            p_targetlen => 4000,
            x_returnLen => retainCharNum,
            x_truncateCharNum => truncateCharNum);
      email_content(i) := substr(temp_email_content_holder, 0, retainCharNum);
      temp_email_msg_body := substr(temp_email_msg_body, 4001-truncateCharNum);
      finaltotalCharNum := finaltotalCharNum + retainCharNum;

    else
      email_content(i) := '';
    end if;
    i := i+1;

  end loop;

  begin
    WF_Directory.CreateAdHocUser(role_name, role_display_name, language,
      territory, role_description, notification_preference,
      email_address, fax, status, expiration_date);
    exception
      when duplicate_user_or_role then
        WF_Directory.SetAdHocUserAttr (role_name, role_display_name,
          notification_preference, language, territory, email_address, fax);
  end;

 -- next is to use the new startProcess procedure
  StartFYIProcess(role_name, srID, subject, email_content,
        role_name, 'IBU_SENDMAIL', 'XXIBUSRD');

end send_email;
/*------------------------------------------------------------------------------
-------------------------------------------------------------------------------*/
PROCEDURE INIT_PROC (P_REQUEST_NUMBER IN NUMBER)
IS

lc_err_msg      varchar2(2000);
lc_status_flag  varchar2(25);
lc_type_name    varchar2(250);
ln_incident_id  number;
ln_user_id      number;
lc_sender       varchar2(250);
lc_status       varchar2(250);

BEGIN

       LC_ERR_MSG := 'In INIT_PROC SR#'||P_REQUEST_NUMBER;
             Log_Exception ( p_error_location  =>  'XX_CS_SOP_WF_PKG.INIT_PROC'
                                      ,p_error_message_code =>   'XX_CS_0001_SUCCESS_ERR'
                                      ,p_error_msg          =>  lc_err_msg
                                      );

        BEGIN
              SELECT cit.name type_name,
                     inc.incident_id,
                     inc.created_by,
                     inc.group_owner
              INTO   lc_type_name,
                     ln_incident_id,
                     ln_user_id,
                     lc_sender
              FROM   cs_incidents inc,
                     cs_incident_types cit
              WHERE  inc.incident_number = to_char(p_request_number)
              and    cit.incident_type_id = inc.incident_type_id
              and    cit.end_date_active is null;
        EXCEPTION
          WHEN OTHERS THEN
             LC_ERR_MSG := 'Error while selecting details '||sqlerrm;
             Log_Exception ( p_error_location  =>  'XX_CS_SOP_WF_PKG.INIT_PROC'
                                      ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                      ,p_error_msg          =>  lc_err_msg
                                      );
        END;

        begin
            select user_name
            into lc_sender
            from fnd_user
            where user_id = ln_user_id;
        exception
           when others then
              lc_sender := 'Store Operations';
        end;

        IF LN_INCIDENT_ID IS NOT NULL THEN

                BEGIN
                    XX_CS_SOP_WF_PKG.SOP_PROCEDURE ( P_REQUEST_ID  => LN_INCIDENT_ID,
                                  P_REQUEST_NUMBER  => P_REQUEST_NUMBER,
                                  P_REQUEST_TYPE    => LC_TYPE_NAME,
                                  P_USER_ID         => LN_USER_ID,
                                  P_SENDER_ROLE     => LC_SENDER,
                                  P_STATUS          => LC_STATUS_FLAG,
                                  P_ERR_MSG         => LC_ERR_MSG);
                  EXCEPTION
                      WHEN OTHERS THEN
                          Log_Exception ( p_error_location  =>  'XX_CS_SOP_WF_PKG.INIT_PROC'
                                      ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                      ,p_error_msg          =>  lc_err_msg
                                      );
                  END;

                lc_status := 'Pending Confirmation';

              BEGIN
                  Update_SR_status(p_sr_request_id  => ln_incident_id,
                                p_user_id        => ln_user_id,
                                p_status         => lc_status,
                                x_return_status  => lc_status_flag,
                                x_msg_data       => lc_err_msg);
               EXCEPTION
                  WHEN OTHERS THEN
                      Log_Exception ( p_error_location  =>  'XX_CS_SOP_WF_PKG.INIT_PROC'
                                          ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                          ,p_error_msg          =>  lc_err_msg
                                          );
              END;
          END IF;

END;
/******************************************************************************************/

FUNCTION TASK_UPDATE (P_subscription_guid  IN RAW,
                      P_event              IN OUT NOCOPY WF_EVENT_T)
RETURN VARCHAR2 AS

 l_event_key              NUMBER ;
 l_event_name 	          VARCHAR2(240) := p_event.getEventName();
 l_entity_activity_code   VARCHAR2(30) ;
 l_updated_entity_code    VARCHAR2(40) ;
 l_updated_entity_id      NUMBER;
 l_entity_update_date     DATE ;
 l_source_object_code     VARCHAR2(240);
 l_source_object_id       NUMBER ;
 l_incident_id            NUMBER ;
 l_user_id                NUMBER := null ;
 l_audit_id		  NUMBER ;
 lc_vendor_id             VARCHAR2(250);
 l_return_status 	  VARCHAR2(30);
 l_msg_count 	 	  NUMBER ;
 l_msg_data   	 	  VARCHAR2(32767) ;
 l_initStr                VARCHAR2(30000);
 l_sku_initStr            VARCHAR2(30000);
 lc_type_name             VARCHAR2(250);

 -- Cursors to get Task Details

    CURSOR get_Task_Dtls (p_task_id IN NUMBER) IS
           SELECT task_id ,
                  task_name,
                  last_update_date,
                  creation_date ,
                  last_updated_by,
                  source_object_type_code ,
                  source_object_id
            FROM jtf_tasks_vl
           WHERE task_id = p_task_id ;

    CURSOR GET_SR_TASK_DTLS (P_INCIDENT_ID IN NUMBER) IS
          SELECT J1.TASK_ID, J1.TASK_NAME, J2.NAME
          FROM JTF_TASKS_VL J1,
               JTF_TASK_STATUSES_VL J2
          WHERE J2.TASK_STATUS_ID = J1.TASK_STATUS_ID
          AND   J1.SOURCE_OBJECT_TYPE_CODE = 'SR'
          AND   J1.SOURCE_OBJECT_ID = P_INCIDENT_ID;

    e_event_updates EXCEPTION ;

    l_object_version_number   number;
    lr_service_request_rec    CS_ServiceRequest_PUB.service_request_rec_type;
    lt_notes                  CS_SERVICEREQUEST_PUB.notes_table;
    lt_contacts               CS_SERVICEREQUEST_PUB.contacts_table;

l_incident_number		NUMBER;
l_store_number  		VARCHAR2(25);
l_order_number  		NUMBER;
lc_phone_number		        VARCHAR2(50);
lc_email_id                     VARCHAR2(250);
l_incident_urgency_id		NUMBER;
l_incident_owner_id		NUMBER;
l_owner_group_id		NUMBER;
l_customer_id			NUMBER;
l_aops_cust_id                  NUMBER;
l_last_updated_by		NUMBER;
l_summary			VARCHAR2(240) ;
l_url                           varchar2(2000);
lc_status                       varchar2(50);
lc_task_close_flag              varchar2(1) := 'N';
lc_task_reject_flag             varchar2(1) := 'N';
lc_task_working_flag            varchar2(1) := 'N';
i                               number;
l_api_version                   number;
l_workflow_process_id           NUMBER;
l_interaction_id                NUMBER;
l_msg_index_out                number;

BEGIN

  /** Detect the event raised and determine necessary parameters depending on the event **/

   IF  l_event_name  = 'oracle.apps.jtf.cac.task.updateTask'  THEN

          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_TYPE_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');

         IF ((l_source_object_code = 'SR') AND (l_source_object_id IS NOT NULL ) ) THEN

             l_event_key  := p_event.GetValueForParameter('TASK_ID');

             FOR get_task_dtls_rec IN get_task_dtls(l_event_key)
             LOOP
                    IF ((get_task_dtls_rec.source_object_type_code = 'SR') AND
                        (get_task_dtls_rec.source_object_id IS NOT NULL ) ) THEN

                       l_updated_entity_id     := l_event_key ;
                       l_updated_entity_code   := 'SR_TASK' ;
                       l_entity_update_date    := get_task_dtls_rec.last_update_date ;
                       l_entity_activity_code  := 'U' ;
                       l_incident_id           := get_task_dtls_rec.source_object_id ;
                       l_user_id               := get_task_dtls_rec.last_updated_by ;
                    END IF ;

              END LOOP ;

            BEGIN
                SELECT incident_number,
                      object_version_number
                INTO l_incident_number,
                     l_object_version_number
                FROM cs_incidents_all_b
                WHERE incident_id  = l_incident_id;
               -- AND   incident_context like 'SOP%' ;
            EXCEPTION
                WHEN OTHERS THEN
                    l_incident_number := NULL;
            END;

            l_msg_data := 'In event Inicdent Num '||l_incident_number ;

            Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.TASK_UPDATE'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  l_msg_data);

            IF l_incident_number IS NOT NULL THEN

               FOR get_sr_task_dtls_rec IN get_sr_task_dtls(l_incident_id)
               LOOP

                     IF get_sr_task_dtls_rec.name = 'Close' then
                        lc_task_close_flag := 'Y';
                     elsif get_sr_task_dtls_rec.name in ('Rejected','Cancelled') then
                        lc_task_reject_flag := 'Y';
                     else
                        lc_task_working_flag := 'Y';
                     end if;

               END LOOP ;

                l_msg_data := 'BEFORE UPDATE SR '||l_incident_number ;

                Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.TASK_UPDATE'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'

                       ,p_error_msg          =>  l_msg_data);

               cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
               /*************************************************************************
                         -- Add notes
                ************************************************************************/
                          lt_notes(1).note        := 'Business Approval Status ' ;
                          lt_notes(1).note_type   := 'GENERAL';

               IF lc_task_reject_flag = 'N' and lc_task_working_flag = 'N' then

                    lt_notes(1).note_detail := 'All Tasks are approved ';

                     LC_STATUS := 'Approved';
                ELSIF lc_task_reject_flag = 'Y' then

                    LC_STATUS := 'Cancelled';
                END IF;

              IF lc_task_working_flag = 'N' then
               /**************************************************************************
                      -- Update SR
               *************************************************************************/
                   BEGIN
                         Update_SR_status(p_sr_request_id  => l_incident_id,
                                          p_user_id        => null,
                                          p_status         => lc_status,
                                          x_return_status  => l_return_status,
                                          x_msg_data       => l_msg_data);
                       EXCEPTION
                         WHEN OTHERS THEN
                           L_MSG_DATA := SQLERRM;
                    END;

                          l_msg_data := 'SR update Status  '||l_return_status ||' '|| l_msg_data;

                          Log_Exception ( p_error_location     =>  'XX_CS_SOP_WF_PKG.TASK_UPDATE'
                                         ,p_error_message_code =>  'XX_CS_SR02_SUCCESS_LOG'
                                         ,p_error_msg          =>  l_msg_data);

              end if;  -- Task In Progress

          END IF; -- INCIDENT NUMBER
      END IF;  -- SR Object

   END IF;
    RETURN 'SUCCESS';
END;
/****************************************************************************************/
PROCEDURE ESC_PROC (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER )
AS
CURSOR C1 IS
SELECT BB.INCIDENT_ID,
       BB.INCIDENT_NUMBER,
       BB.CREATED_BY,
       ST.NAME,
       BB.OBLIGATION_DATE,
       BB.EXPECTED_RESOLUTION_DATE,
       BB.INC_RESPONDED_BY_DATE,
       BB.INCIDENT_RESOLVED_DATE
FROM CS_INCIDENTS_ALL_B BB,
     CS_INCIDENT_STATUSES ST,
     CS_INCIDENT_TYPES_VL CT
WHERE CT.INCIDENT_TYPE_ID = BB.INCIDENT_TYPE_ID
AND   ST.INCIDENT_STATUS_ID = BB.INCIDENT_STATUS_ID
AND   CT.ATTRIBUTE6 = 'SOP'
AND   ST.NAME IN ('Pending Confirmation','Pending Approval')
AND   ST.INCIDENT_SUBTYPE = 'INC'
AND   CT.INCIDENT_SUBTYPE = 'INC';

C1_REC              C1%ROWTYPE;
lc_status           varchar2(150);
l_return_status     varchar2(150);
l_msg_data          varchar2(1000);
lc_sender           varchar2(250);
lc_message          varchar2(3000);
lc_message_body     long;
lc_email_address    varchar2(250);
lc_dir_email        varchar2(250);
lc_dir_cancel_msg   long;
lc_bus_cancel_msg   long;
lc_rem_msg          long;

BEGIN

    -- Director Cancel message
    BEGIN
      SELECT MESSAGE_TEXT
      INTO LC_DIR_CANCEL_MSG
      FROM FND_NEW_MESSAGES
      WHERE MESSAGE_NAME = 'XX_CS_SOP_NO_DIR_RESP';
    EXCEPTION
      WHEN OTHERS THEN
        LC_DIR_CANCEL_MSG := 'The Request has been canceled due to no response and no further action will be taken. You may re-submit for consideration as a new request';
   END;

   -- Business Cancel message
    BEGIN
      SELECT MESSAGE_TEXT
      INTO LC_BUS_CANCEL_MSG
      FROM FND_NEW_MESSAGES
      WHERE MESSAGE_NAME = 'XX_CS_SOP_WHEN_APPROVAL_EMAIL';
    EXCEPTION
      WHEN OTHERS THEN
        LC_BUS_CANCEL_MSG := 'The Request has been not been accepted by one or all of the approving departments, Please verify request.';
   END;

   -- Business Cancel message
    BEGIN
      SELECT MESSAGE_TEXT
      INTO LC_REM_MSG
      FROM FND_NEW_MESSAGES
      WHERE MESSAGE_NAME = 'XX_CS_SOP_DIR_REM_CONF';
    EXCEPTION
      WHEN OTHERS THEN
        LC_BUS_CANCEL_MSG := 'The Request has been not been approved for submission. If your director is out of office then update request with alternate approvals.';
   END;

    BEGIN
      OPEN C1;
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;
        -- Director approval escalation
        IF C1_REC.NAME = 'Pending Confirmation' then
           IF (C1_REC.OBLIGATION_DATE-23/24) > SYSDATE
              AND C1_REC.INC_RESPONDED_BY_DATE IS NULL then
              -- Sent remainder
               begin
                select user_name, email_address
                into lc_sender, lc_email_address
                from fnd_user
                where user_id = c1_rec.created_by;
              exception
                 when others then
                   null;
              end;
          -- director mail -- 099602
             

              begin
                select  email_address
                 into  lc_dir_email
                from fnd_user
                where user_id = '099602';
              exception
                 when others then
                   null;
              end;

              lc_message_body := lc_rem_msg;
              lc_message := 'Request#'||c1_rec.incident_number;


                send_email(email_address_in => lc_email_address,
                              user_id          => c1_rec.created_by,
                              subject          => lc_message,
                              msg_body         => lc_message_body,
                              srID             => c1_rec.incident_id
                            );

                    send_email(email_address_in => lc_dir_email,
                              user_id          => c1_rec.created_by,
                              subject          => lc_message,
                              msg_body         => lc_message_body,
                              srID             => c1_rec.incident_id
                            );

           elsif C1_REC.OBLIGATION_DATE > SYSDATE
              AND C1_REC.INC_RESPONDED_BY_DATE IS NULL then

              lc_message_body := lc_dir_cancel_msg;
              lc_message := 'Request#'||c1_rec.incident_number;

                send_email(email_address_in => lc_email_address,
                              user_id          => c1_rec.created_by,
                              subject          => lc_message,
                              msg_body         => lc_message_body,
                              srID             => c1_rec.incident_id
                            );

             -- Cancelled the request
                     lc_status := 'Cancelled';
                     BEGIN
                         Update_SR_status(p_sr_request_id  => c1_rec.incident_id,
                                          p_user_id        => null,
                                          p_status         => lc_status,
                                          x_return_status  => l_return_status,
                                          x_msg_data       => l_msg_data);
                       EXCEPTION
                         WHEN OTHERS THEN
                           L_MSG_DATA := SQLERRM;
                    END;
           end if;
        elsif C1_REC.NAME = 'Pending Approval' then
            if C1_REC.EXPECTED_RESOLUTION_DATE  > SYSDATE
              AND  C1_REC.INCIDENT_RESOLVED_DATE IS NULL then

              lc_message_body := lc_bus_cancel_msg;
              lc_message := 'Request#'||c1_rec.incident_number;

                send_email(email_address_in => lc_email_address,
                              user_id          => c1_rec.created_by,
                              subject          => lc_message,
                              msg_body         => lc_message_body,
                              srID             => c1_rec.incident_id
                            );
             -- Cancelled the request
                lc_status := 'Cancelled';
                     BEGIN
                         Update_SR_status(p_sr_request_id  => c1_rec.incident_id,
                                          p_user_id        => null,
                                          p_status         => lc_status,
                                          x_return_status  => l_return_status,
                                          x_msg_data       => l_msg_data);
                       EXCEPTION
                         WHEN OTHERS THEN
                           L_MSG_DATA := SQLERRM;
                    END;
           end if;
        end if;
      END LOOP;
      CLOSE C1;
    END;
END;
/****************************************************************************************/
END XX_CS_SOP_WF_PKG;
/

SHOW ERRORS;
EXIT;

