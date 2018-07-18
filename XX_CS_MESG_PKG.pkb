CREATE OR REPLACE
PACKAGE BODY XX_CS_MESG_PKG
AS
  /* $Header: ODCSMAIL.pls on 01/07/09      */
  /****************************************************************************
  *
  * Program Name : XX_CS_MESG_PKG
  * Language     : PL/SQL
  * Description  : Package to maintain email te.
  * History      :
  *
  * WHO             WHAT                                    WHEN
  * --------------  --------------------------------------- ---------------
  * Raj Jagarlamudi Initial Version                          1/7/09
  * Raj Jagarlamudi Accept entire message                  12/18/09
  * Raj Jagarlamudi Added SR in Body                       12/19/09
  * Raj Jagarlamudi Added AMAZON enhancement               07/01/13
  * Arun Gannarapu  Made changes to read_response process  07/10/2015
  *                 to work with Google POP server
  * Vasu Raparla    Removed Schema References for R.12.2   01/22/2016
  * Anoop Salim        Changes for Defect# 37051               02/23/2016
  * Poonam Gupta    Changes to read SR Numbers in all digi 02/15/2017
  *                 -its for Defect#40980
  * Mohammed Arif      Added code to handle User Defined       02/20/2017
  *                    Exception in WriteToPop Function,
  *                    so as to restrict the program from
  *                    getting into Error And to get the
  *                    program Complete in Warning Status
  *                    whenever the Message is not updated in
  *                    SR, and also it sends an email along
  *                    with the message. -- Defect# 38994
  * Suresh Naragam     Changes to update SR Notes with outlook mail data (Defect#42000) 06/19/2017
  ****************************************************************************/
  /*****************************************************************************
  -- Log Messages
  ****************************************************************************/
PROCEDURE Log_Exception(
    p_error_location     IN VARCHAR2 ,
    p_error_message_code IN VARCHAR2 ,
    p_error_msg          IN VARCHAR2 )
IS
  ln_login PLS_INTEGER   := FND_GLOBAL.Login_Id;
  ln_user_id PLS_INTEGER := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error ( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XX_CRM' ,p_program_type => 'Custom Email Messages' ,p_program_name => 'XX_CS_MESG_PKG' ,p_program_id => NULL ,p_module_name => 'CS' ,p_error_location => p_error_location ,p_error_message_code => p_error_message_code ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
END Log_Exception;
/***************************************************************************
-- Update SR status
*****************************************************************************/
PROCEDURE Update_SR_status(
    p_sr_request_id IN NUMBER,
    p_user_id       IN VARCHAR2,
    p_status        IN VARCHAR2,
    x_return_status IN OUT nocopy VARCHAR2,
    x_msg_data      IN OUT nocopy VARCHAR2)
IS
  x_msg_count      NUMBER;
  x_interaction_id NUMBER;
  ln_obj_ver       NUMBER;
  ln_msg_index     NUMBER;
  ln_msg_index_out NUMBER;
  ln_user_id       NUMBER;
  ln_resp_appl_id  NUMBER := 514;
  ln_resp_id       NUMBER := 21739;
  ln_status_id     NUMBER;
  lc_status        VARCHAR2(50);
  ln_type_id       NUMBER;
  lc_type_name     VARCHAR2(250);
BEGIN
  BEGIN
    SELECT user_id INTO ln_user_id FROM fnd_user WHERE user_name = 'CS_ADMIN';
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'F';
  END;
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
    INTO ln_obj_ver,
      ln_type_id
    FROM cs_incidents_all_b
    WHERE incident_id = p_sr_request_id;
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'F';
  END;
  BEGIN
    SELECT name
    INTO lc_type_name
    FROM cs_incident_types
    WHERE incident_type_id = ln_type_id;
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'F';
  END;
  BEGIN
    SELECT incident_status_id,
      name
    INTO ln_status_id,
      lc_status
    FROM cs_incident_statuses
    WHERE incident_subtype = 'INC'
    AND name               = p_status ;
  EXCEPTION
  WHEN OTHERS THEN
    ln_status_id := NULL;
  END;
  IF ln_status_id IS NOT NULL THEN
    /***********************************************************************
    -- Update SR
    ***********************************************************************/
    CS_SERVICEREQUEST_PUB.Update_Status (p_api_version => 2.0, p_init_msg_list => FND_API.G_TRUE, p_commit => FND_API.G_FALSE, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data, p_resp_appl_id => ln_resp_appl_id, p_resp_id => ln_resp_id, p_user_id => ln_user_id, p_login_id => NULL, p_request_id => p_sr_request_id, p_request_number => NULL, p_object_version_number => ln_obj_ver, p_status_id => ln_status_id, p_status => lc_status, p_closed_date => SYSDATE, p_audit_comments => NULL, p_called_by_workflow => NULL, p_workflow_process_id => NULL, p_comments => NULL, p_public_comment_flag => NULL, x_interaction_id => x_interaction_id );
    COMMIT;
    IF (x_return_status        <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (FND_MSG_PUB.Count_Msg > 1) THEN
        --Display all the error messages
        FOR j IN 1..FND_MSG_PUB.Count_Msg
        LOOP
          FND_MSG_PUB.Get( p_msg_index => j, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => ln_msg_index_out);
          DBMS_OUTPUT.PUT_LINE(x_msg_data);
        END LOOP;
      ELSE
        --Only one error
        FND_MSG_PUB.Get( p_msg_index => 1, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => ln_msg_index_out);
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
PROCEDURE send_notification(
    p_sr_number     IN NUMBER,
    p_sr_id         IN VARCHAR2,
    p_from_id       IN NUMBER,
    p_to_id         IN NUMBER,
    p_user_id       IN VARCHAR2,
    p_message       IN VARCHAR2 DEFAULT NULL,
    p_url_link      IN VARCHAR2,
    p_subject       IN VARCHAR2,
    p_source        IN VARCHAR2,
    x_return_status IN OUT NOCOPY VARCHAR2,
    x_return_msg    IN OUT NOCOPY VARCHAR2)
IS
  lc_source_object   VARCHAR2(50) := 'Service Request';
  lc_source_obj_type VARCHAR2(25) := 'INC';
  lc_message         VARCHAR2(3000);
  lc_sender          VARCHAR2(250);
  lc_sender_role     VARCHAR2(250);
  lc_receiver        VARCHAR2(250);
  lc_receiver_role   VARCHAR2(250);
  lc_log_message     VARCHAR2(1000);
BEGIN
  IF p_from_id IS NOT NULL THEN
    BEGIN
      SELECT DECODE(wf.orig_system_id, NULL, usr.user_name, wf.display_name) user_name,
        wf.name user_role
      INTO lc_sender,
        lc_sender_role
      FROM wf_roles wf,
        fnd_user usr
      WHERE usr.user_id     = p_from_id
      AND usr.employee_id   = wf.orig_system_id (+)
      AND wf.orig_system(+) = 'PER';
    EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'F';
      x_return_msg    := 'Error while selecting Sender role '||sqlerrm;
    END;
  ELSE
    lc_sender := 'Customer Service';
  END IF;
  BEGIN
    SELECT DECODE(wf.orig_system_id, NULL, usr.user_name, wf.display_name) user_name,
      wf.name user_role
    INTO lc_receiver,
      lc_receiver_role
    FROM wf_roles wf,
      fnd_user usr
    WHERE usr.user_id     = p_to_id
    AND usr.employee_id   = wf.orig_system_id (+)
    AND wf.orig_system(+) = 'PER';
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'F';
    x_return_msg    := 'Error while selecting Receiver role '||sqlerrm;
  END;
  lc_message     := p_message;
  lc_log_message := 'Sender :'||lc_sender ||' Receiver : '||lc_receiver || 'Message : '||lc_message;
  Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_NOTIFICATION' ,p_error_message_code => 'XX_CS_SR02_SUCCESS_LOG' ,p_error_msg => lc_log_message);
  IF P_SOURCE = 'OWNER' THEN
    CS_MESSAGES_PKG.Send_Message( p_source_object_type => lc_source_object, p_source_obj_type_code => lc_source_obj_type, p_source_object_int_id => p_sr_id, p_source_object_ext_id => p_sr_number, p_sender => lc_sender, p_sender_role => lc_sender_role, p_receiver => lc_receiver, p_receiver_role => lc_receiver_role, p_priority => 'MED', p_expand_roles => 'N', p_action_type => NULL, p_action_code => 'CONFIRMATION', p_confirmation => 'N', p_message => lc_message, p_function_name => NULL, p_function_params => NULL );
  ELSE
    XX_CS_MESG_PKG.Send_Message( p_source_object_type => lc_source_object, p_source_obj_type_code => lc_source_obj_type, p_source_object_int_id => p_sr_id, p_source_object_ext_id => p_sr_number, p_sender => lc_sender, p_sender_role => lc_sender_role, p_receiver => lc_receiver, p_receiver_role => lc_receiver_role, p_priority => 'MED', p_expand_roles => 'N', p_action_type => NULL, p_action_code => 'CONFIRMATION', p_confirmation => 'N', p_message => lc_message, p_url_hyper_link => p_url_link, p_subject => p_subject, p_function_name => NULL, p_function_params => NULL );
  END IF;
END send_notification;
/*****************************************************************************
******************************************************************************/
PROCEDURE Send_Message(
    p_source_object_type   IN VARCHAR2,
    p_source_obj_type_code IN VARCHAR2,
    p_source_object_int_id IN NUMBER,
    p_source_object_ext_id IN VARCHAR2,
    p_sender               IN VARCHAR2,
    p_sender_role          IN VARCHAR2 DEFAULT NULL,
    p_receiver             IN VARCHAR2,
    p_receiver_role        IN VARCHAR2,
    p_priority             IN VARCHAR2,
    p_expand_roles         IN VARCHAR2,
    p_action_type          IN VARCHAR2 DEFAULT NULL,
    p_action_code          IN VARCHAR2 DEFAULT NULL,
    p_confirmation         IN VARCHAR2,
    p_message              IN VARCHAR2 DEFAULT NULL,
    p_url_hyper_link       IN VARCHAR2 DEFAULT NULL,
    p_subject              IN VARCHAR2 DEFAULT NULL,
    p_function_name        IN VARCHAR2 DEFAULT NULL,
    p_function_params      IN VARCHAR2 DEFAULT NULL )
IS
  l_message_id        NUMBER;
  l_notification_id   NUMBER;
  l_ntf_group_id      NUMBER;
  l_source_obj_ext_id VARCHAR2(200);
  l_user_id           NUMBER;
  l_login_id          NUMBER;
  l_priority          VARCHAR2(30);
  lc_log_message      VARCHAR2(1000);
  l_priority_number   NUMBER;
  CURSOR l_msgid_csr
  IS
    SELECT cs_messages_s.NEXTVAL FROM dual;
  CURSOR l_ntf_csr
  IS
    SELECT ntf.notification_id
    FROM wf_notifications ntf
    WHERE ntf.group_id = l_ntf_group_id;
  CURSOR l_priority_csr
  IS
    SELECT meaning
    FROM cs_lookups
    WHERE lookup_type = 'MESSAGE_PRIORITY'
    AND lookup_code   = p_priority;
  -- --------------------------------------------------------------------
  -- SetAttributes
  --   Subprocedure used to set the message attibutes that are common to
  --   all the different types of messages
  -- --------------------------------------------------------------------
PROCEDURE SetAttributes(
    p_nid      IN NUMBER,
    p_priority IN VARCHAR2,
    p_ext_id   IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'OBJECT_ID', avalue => p_ext_id );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'OBJECT_TYPE', avalue => p_source_object_type );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'SENDER', avalue => p_sender );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'MESSAGE_TEXT', avalue => p_message );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'PRIORITY', avalue => p_priority );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'OBJECT_FORM', avalue => p_function_name||':'||p_function_params );
  WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => '#FROM_ROLE', avalue => p_sender_role);
  IF P_SUBJECT IS NOT NULL THEN
    WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'DISPUTE_ID', avalue => p_subject);
  END IF;
  IF P_URL_HYPER_LINK IS NOT NULL THEN
    WF_NOTIFICATION.SetAttrText( nid => p_nid, aname => 'AME_LINK', avalue => p_url_hyper_link);
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
    l_source_obj_ext_id      := '#'||p_source_object_ext_id;
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
  IF (p_priority       = 'HIGH') THEN
    l_priority_number := 25;
  ELSIF (p_priority    = 'MED') THEN
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
      l_ntf_group_id := WF_NOTIFICATION.Send( role => p_receiver_role, msg_type => 'XXCSMESG', msg_name => 'FYI_MESSAGE', due_date => NULL, callback => 'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK', context => TO_CHAR(l_message_id), send_comment => NULL, priority => l_priority_number );
    ELSE
      -- Expand Roles requested, call the SendGroup API instead
      l_ntf_group_id := WF_NOTIFICATION.SendGroup( role => p_receiver_role, msg_type => 'XXCSMESG', msg_name => 'EXPANDED_FYI_MSG', due_date => NULL, callback => 'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK', context => TO_CHAR(l_message_id), send_comment => NULL, priority => l_priority_number );
    END IF;
    --
    -- For each notification in the group, set up the message attributes.
    -- Note that if the Send API was called, the notification ID will be
    -- the same as the group ID.
    -- We are using a cursor loop until Workflow team provides an API for
    -- updating the notification attributes for the whole group
    --
    FOR l_ntf_rec IN l_ntf_csr
    LOOP
      l_notification_id := l_ntf_rec.notification_id;
      -- Call the subprocedure to set the notification attributes
      SetAttributes(l_notification_id, l_priority, l_source_obj_ext_id);
    END LOOP;
    l_notification_id := l_ntf_group_id;
  ELSE
    -- Action requested, send the ACTION_REQUEST_MSG message
    l_notification_id := WF_NOTIFICATION.Send( role => p_receiver_role, msg_type => 'XXCSMESG', msg_name => 'ACTION_REQUEST_MSG', due_date => NULL, callback => 'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK', context => TO_CHAR(l_message_id), send_comment => NULL, priority => l_priority_number );
    -- Set the notification attributes
    SetAttributes(l_notification_id, l_priority, l_source_obj_ext_id);
    BEGIN
      WF_NOTIFICATION.SetAttrText( nid => l_notification_id, aname => 'ACTION', avalue => p_action_type );
    EXCEPTION
    WHEN OTHERS THEN
      lc_log_message := 'Error while seting attribute '||sqlerrm;
      Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_MESSAGE' ,p_error_message_code => 'XX_CS_SR02_ERROR_LOG' ,p_error_msg => lc_log_message);
    END;
  END IF;
  -- Get the user information for WHO columns
  l_user_id     := to_number(FND_PROFILE.VALUE('USER_ID'));
  l_login_id    := to_number(FND_PROFILE.VALUE('LOGIN_ID'));
  IF (l_user_id IS NULL) THEN
    l_user_id   := -1;
  END IF;
  -- Insert a new record into the CS_MESSAGES table
  BEGIN
    INSERT
    INTO cs_messages
      (
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
        MESSAGE,
        responder,
        response_date,
        response,
        responder_comment
      )
      VALUES
      (
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
        NULL
      );
  EXCEPTION
  WHEN OTHERS THEN
    lc_log_message := 'Error while inserting into table '||sqlerrm;
    Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_MESSAGE' ,p_error_message_code => 'XX_CS_SR02_SUCCESS_LOG' ,p_error_msg => lc_log_message);
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
PROCEDURE Notification_Callback
  (
    command      IN VARCHAR2,
    context      IN VARCHAR2,
    attr_name    IN VARCHAR2 DEFAULT NULL,
    attr_type    IN VARCHAR2 DEFAULT NULL,
    text_value   IN OUT NOCOPY VARCHAR2,
    number_value IN OUT NOCOPY NUMBER,
    date_value   IN OUT NOCOPY DATE
  )
IS
  l_message_id       NUMBER;
  l_user_id          NUMBER;
  l_login_id         NUMBER;
  l_comment          VARCHAR2(2000);
  l_confirmation_nid NUMBER;
  l_source_type      VARCHAR2(100);
  l_source_id        VARCHAR2(100);
  l_message          VARCHAR2(2000);
  l_response         VARCHAR2(30);
  l_status_id        VARCHAR2(100);
  l_sr_notes XX_CS_SR_NOTES_REC;
  l_note_message  VARCHAR2(2000);
  x_return_status VARCHAR2(200);
  x_msg_data      VARCHAR2(200);
  lc_prog_code    VARCHAR2(100);
  lc_status       VARCHAR2(50);
  CURSOR l_ntf_csr
  IS
    SELECT ntf.end_date,
      wf.display_name responder,
      msg.confirmation,
      msg.notification_id,
      msg.sender_role sender,
      msg.source_object_int_id service_req_id
    FROM wf_notifications ntf,
      wf_roles wf,
      cs_messages msg
    WHERE msg.message_id    = l_message_id
    AND msg.notification_id = ntf.notification_id
    AND ntf.responder       = wf.name(+) FOR UPDATE OF msg.message_id;
  CURSOR l_response_csr
  IS
    SELECT meaning
    FROM cs_lookups
    WHERE lookup_type = 'MESSAGE_RESPONSE'
    AND lookup_code   = text_value;
  l_ntf_rec l_ntf_csr%ROWTYPE;
BEGIN
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
    IF (attr_type    = 'NUMBER') THEN
      number_value  := to_number(NULL);
    ELSIF (attr_type = 'DATE') THEN
      date_value    := to_date(NULL);
    ELSE
      text_value := TO_CHAR(NULL);
    END IF;
  ELSIF (upper(command) = 'SET') THEN
    --
    -- Do all the work in the COMPLETE command
    --
    NULL;
  ELSIF (upper(command) = wf_engine.eng_completed) THEN
    -- Get the user information for WHO columns
    l_user_id     := to_number(FND_PROFILE.VALUE('USER_ID'));
    l_login_id    := to_number(FND_PROFILE.VALUE('LOGIN_ID'));
    IF (l_user_id IS NULL) THEN
      l_user_id   := -1;
    END IF;
    OPEN l_ntf_csr;
    FETCH l_ntf_csr INTO l_ntf_rec;
    -- Get the comment of the responder
    l_comment := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'COMMENT');
    -- Update the row in the CS_MESSAGES table
    UPDATE cs_messages
    SET last_update_date = sysdate,
      last_updated_by    = l_user_id,
      last_update_login  = l_login_id,
      responder          = l_ntf_rec.responder,
      response_date      = l_ntf_rec.end_date,
      responder_comment  = l_comment,
      response           = text_value
    WHERE CURRENT OF l_ntf_csr;
    /***********************************************************************
    -- Update notes
    ***********************************************************************/
    IF l_comment               IS NOT NULL THEN
      l_sr_notes               := XX_CS_SR_NOTES_REC(NULL,NULL,NULL,NULL);
      l_sr_notes.notes         := text_value;
      l_sr_notes.note_details  := l_comment;
      l_sr_notes.created_by    := uid;
      l_sr_notes.creation_date := sysdate;
    END IF;
    -- update SR
    BEGIN
      Update_SR_status(p_sr_request_id => l_ntf_rec.service_req_id, p_user_id => l_user_id, p_status => l_status_id, x_return_status => lc_status, x_msg_data => x_msg_data);
    EXCEPTION
    WHEN OTHERS THEN
      X_MSG_DATA := SQLERRM;
    END;
    IF l_sr_notes.notes IS NOT NULL THEN
      XX_CS_SERVICEREQUEST_PKG.CREATE_NOTE (p_request_id => l_ntf_rec.service_req_id, p_sr_notes_rec => l_sr_notes, p_return_status => x_return_status, p_msg_data => x_msg_data);
    END IF;
    -- If confirmation was requested, we need to send it now
    IF (l_ntf_rec.confirmation = 'Y') THEN
      -- Get the value for response
      OPEN l_response_csr;
      FETCH l_response_csr INTO l_response;
      CLOSE l_response_csr;
      l_source_type      := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'OBJECT_TYPE');
      l_source_id        := WF_NOTIFICATION.GetAttrText(l_ntf_rec.notification_id, 'OBJECT_ID');
      l_message          := WF_NOTIFICATION.GetATTRTEXT(l_ntf_rec.notification_id, 'MESSAGE_TEXT');
      l_confirmation_nid := WF_NOTIFICATION.Send( role => l_ntf_rec.sender, msg_type => 'XXCSMESG', msg_name => 'CONFIRMATION_MESSAGE', due_date => NULL, callback => 'XX_CS_MESG_PKG.NOTIFICATION_CALLBACK', context => TO_CHAR(l_message_id), send_comment => NULL );
      -- Set up the message attributes
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'OBJECT_TYPE', avalue => l_source_type );
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'OBJECT_ID', avalue => l_source_id );
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'RESPONDER', avalue => l_ntf_rec.responder );
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'RESPONSE', avalue => l_response );
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'COMMENT', avalue => l_comment );
      WF_NOTIFICATION.SetAttrText( nid => l_confirmation_nid, aname => 'MESSAGE', avalue => l_message );
      -- Fix for bug 2122488
      Wf_Notification.Denormalize_Notification(l_confirmation_nid);
    END IF;
    CLOSE l_ntf_csr;
  END IF;
END Notification_Callback;
/****************************************************************************
-- Build Header
*****************************************************************************/
PROCEDURE send_header(
    conn   IN OUT NOCOPY utl_smtp.connection,
    name   IN VARCHAR2,
    header IN VARCHAR2)
AS
BEGIN
  IF (name = 'Subject') THEN
    utl_smtp.write_data(conn, name || ': =?iso-8859-1?Q?' || utl_raw.cast_to_varchar2(utl_encode.quoted_printable_encode(utl_raw.cast_to_raw(header))) || '?=' || utl_tcp.crlf);
  ELSE
    utl_smtp.write_data(conn, name || ':' || header || utl_tcp.crlf);
  END IF;
END;
/******************************************************************************
-- Send regular mail
******************************************************************************/
PROCEDURE send_email(
    sender         IN VARCHAR2,
    recipient      IN VARCHAR2,
    cc_recipient   IN VARCHAR2 ,
    bcc_recipient  IN VARCHAR2 ,
    subject        IN VARCHAR2,
    message_body   IN VARCHAR2,
    p_message_type IN VARCHAR2,
    IncidentNum    IN VARCHAR2,
    return_code OUT NUMBER -- returns SMTP reply code
  )
IS
  mail_conn utl_smtp.connection;
  crlf VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
  mesg CLOB ;
  v_mesg CLOB;
  v_mail_reply utl_smtp.reply;
  lc_smtp_server   VARCHAR2(250);
  l_comments       VARCHAR2(2000);
  lc_gen_mesg      VARCHAR2(3000);
  lx_return_status VARCHAR2(1);
  lx_msg_data      VARCHAR2(2000);
  ln_incident_num  NUMBER;
  ln_sender_id     NUMBER;
  ln_creator_id    NUMBER;
  ln_owner_id      NUMBER;
  lc_dispute_id    VARCHAR2(25);
  lc_type_name     VARCHAR2(50);
  ln_incident_id   NUMBER;
  lc_order_num     VARCHAR2(100);
  lc_aops_id       VARCHAR2(100);
  ln_user_id       NUMBER;
  lc_url           VARCHAR2(2000);
  lc_subject       VARCHAR2(1000);
  LT_SR_NOTES XX_CS_SR_MAIL_NOTES_REC;
  mime_type      VARCHAR2(255) := 'text/html';
  lc_dispute_msg VARCHAR2(2000);
  ln_status_id   NUMBER;
  ln_location    NUMBER := 0;
  my_index       NUMBER := 1;
  my_recipients  VARCHAR2(32000);
  ln_priority PLS_INTEGER;
  lc_problem_code  VARCHAR2(100);
  ln_group_id      NUMBER;
  lc_sender        VARCHAR2(250) := sender;
  lc_request_type  VARCHAR2(250);
  lc_contact_name  VARCHAR2(250);
  lc_contact_email VARCHAR2(250);
  lc_route         VARCHAR2(250);
  lc_contact_phone VARCHAR2(250);
  lc_tier          VARCHAR2(50);
  CURSOR mesg_cur
  IS
    SELECT message_number
      ||':-'
      || message_text MESSAGE
    FROM fnd_new_messages
    WHERE message_name LIKE 'XX_CS_DISPUTE%'
    ORDER BY message_number;
  mesg_rec mesg_cur%rowtype;
BEGIN
  lt_sr_notes := XX_CS_SR_MAIL_NOTES_REC(NULL,NULL,NULL,NULL);
  -- Select incident_id and number
  BEGIN
    SELECT cb.incident_id,
      cb.incident_number,
      cb.incident_status_id,
      SUBSTR(ct.attribute9,1,3),
      cb.incident_attribute_12,
      cb.incident_attribute_1,
      cb.incident_attribute_9,
      cb.problem_code,
      cb.owner_group_id,
      ct.name,
      cb.incident_attribute_5 contact_name,
      cb.incident_attribute_8 contact_email,
      cb.incident_attribute_14 contact_phone,
      cb.external_attribute_6 route,
      cb.tier
    INTO ln_incident_id,
      ln_incident_num,
      ln_status_id,
      lc_type_name,
      lc_dispute_id,
      lc_order_num,
      lc_aops_id,
      lc_problem_code,
      ln_group_id,
      lc_request_type,
      lc_contact_name,
      lc_contact_email,
      lc_contact_phone,
      lc_route,
      lc_tier
    FROM cs_incident_types ct,
      cs_incidents_all_b cb
    WHERE ct.incident_type_id = cb.incident_type_id
    AND cb.incident_id        = to_number(IncidentNum);
  EXCEPTION
  WHEN OTHERS THEN
    lx_msg_data := 'Error while selecing incident id '||sqlerrm;
    log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_EMAIL' ,p_error_message_code => 'XX_CS_SR01_ERROR_LOG' ,p_error_msg => lx_msg_data);
  END;
  /*
  lx_msg_data := 'InidentId : '||ln_incident_id||' Type '||p_message_type;
  log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.SEND_EMAIL'
  ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
  ,p_error_msg          =>  lx_msg_data);
  */
  BEGIN
    SELECT message_text MESSAGE
    INTO lc_gen_mesg
    FROM fnd_new_messages
    WHERE message_name LIKE 'XX_CS_GEN_MSG%';
  EXCEPTION
  WHEN OTHERS THEN
    lc_gen_mesg := NULL;
  END;
  /****************************************************************
  -- Update SR for particular SR
  ****************************************************************/
  IF ln_incident_id IS NOT NULL THEN
    IF LN_STATUS_ID <> 2 THEN
      BEGIN
        XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS( P_SR_REQUEST_ID => LN_INCIDENT_ID, P_USER_ID => ln_user_id, P_STATUS_ID => NULL, P_STATUS => 'Waiting', X_RETURN_STATUS => lx_return_status, X_MSG_DATA => lx_msg_data);
      EXCEPTION
      WHEN OTHERS THEN
        lx_msg_data := 'Error while updating InidentId : '||ln_incident_id||' '|| sqlerrm;
        log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_EMAIL' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => lx_msg_data);
      END;
    END IF;
    lt_sr_notes.notes := 'Message sent to: '||recipient ||', CC '||cc_recipient;
    --lt_sr_notes.note_details   :=  message_body;
    XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id => ln_incident_id, p_sr_notes_rec => LT_SR_NOTES, p_return_status => lx_return_status, p_msg_data => lx_msg_data);
    -- Move back to group (unassigned) queue
    IF LC_TYPE_NAME IN ('EC ', 'EC') THEN
      BEGIN
        /***********************************************************************
        -- Update SR
        ***********************************************************************/
        UPDATE cs_incidents_all_b
        SET incident_owner_id   = NULL,
          unassigned_indicator  = 2
        WHERE incident_id       = ln_incident_id
        AND incident_status_id <> 2;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        lx_msg_data := 'Error while updating owner '||sqlerrm;
        Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.READ_RESPONSE' ,p_error_message_code => 'XX_CS_SR02_ERROR_LOG' ,p_error_msg => lx_msg_data);
      END ;
    END IF;
  END IF;
  BEGIN
    SELECT fnd_profile.value('XX_CS_SMTP_SERVER') INTO lc_smtp_server FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    lc_smtp_server := 'chrelay.na.odcorp.net';
  END;
  ---
  BEGIN
    SELECT fnd_profile.value('XX_CS_SVC_ACCOUNT') INTO lc_sender FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    lc_sender := sender;
  END;
  BEGIN
    SELECT a.meaning
    INTO lc_sender
    FROM cs_lookups a,
      jtf_rs_groups_vl b
    WHERE b.accounting_code = a.lookup_code
    AND a.lookup_type       = 'XX_CS_SVC_ALIAS'
    AND b.group_id          = ln_group_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_sender := lc_sender;
  END;
  IF lc_sender IS NULL THEN
    lc_sender  := sender;
  END IF;
  BEGIN
    mail_conn := utl_smtp.open_connection(lc_smtp_server, 25);
    utl_smtp.helo(mail_conn, lc_smtp_server);
    utl_smtp.mail(mail_conn, sender);
    IF recipient LIKE 'Eorders%' THEN
      ln_priority := 1;
    END IF;
    -- clean up any trailing separation characters
    my_recipients   := RTRIM(recipient,',; ');
    IF cc_recipient IS NOT NULL THEN
      my_recipients := my_recipients||'; '||cc_recipient;
    END IF;
    IF bcc_recipient IS NOT NULL THEN
      my_recipients  := my_recipients||'; '||bcc_recipient;
    END IF;
    -- initialize loop variables
    my_recipients := RTRIM(my_recipients,',; ');
    my_index      := 1;
    -- Parse out each recipient and make a call to
    -- UTL_SMTP.RCPT to add it to the recipient list
    WHILE my_index < LENGTH(my_recipients)
    LOOP
      -- determine multiple recipients by looking for separation characters
      ln_location   := INSTR(my_recipients,',',my_index,1);
      IF ln_location = 0 THEN
        ln_location := INSTR(my_recipients,';',my_index,1);
      END IF;
      IF ln_location <> 0 THEN
        -- multiple recipients, add this one to the recipients list
        UTL_SMTP.RCPT(mail_conn, TRIM(SUBSTR(my_recipients,my_index,ln_location-my_index)));
        my_index := ln_location                                                + 1;
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
    UTL_smtp.write_data(mail_conn, 'Content-Transfer-Encoding: ' || '"8Bit"' || UTL_tcp.CRLF);
    /* ** Sending the header  Body information */
    lc_subject        := subject||' for SR#'||ln_incident_num;
    IF lc_request_type = 'Marketplace' THEN
      lc_subject      := subject||' for AMAZON Order #'||lc_tier;
    END IF;
    send_header(mail_conn,'From',''||lc_sender||'');
    send_header(mail_conn,'To',''||recipient||'');
    send_header(mail_conn,'Cc',''||cc_recipient||'');
    send_header(mail_conn,'Bcc',''||bcc_recipient||'');
    send_header(mail_conn,'Date',TO_CHAR(sysdate, 'dd Mon yy hh24:mi:ss'));
    send_header(mail_conn,'Subject',lc_subject);
    IF ln_priority IS NOT NULL THEN
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
    IF lc_order_num IS NOT NULL THEN
      send_header(mail_conn,'Order',lc_order_num);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
    END IF;
    -- Amazon order routing
    IF lc_request_type = 'Marketplace' THEN
      send_header(mail_conn,'Amazon Order ',lc_tier);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Contact Name',lc_contact_name);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Contact email',lc_contact_email);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Contact Phone',lc_contact_phone);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
    ELSE
      IF lc_aops_id IS NOT NULL THEN
        send_header(mail_conn,'Customer Id',lc_aops_id);
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      END IF;
    END IF;
    IF lc_request_type = 'Stocked Products' THEN
      send_header(mail_conn,'Contact Name',lc_contact_name);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Contact email',lc_contact_email);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Contact Phone',lc_contact_phone);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Route',lc_route);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
    END IF;
    UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
    UTL_smtp.write_raw_data(mail_conn,utl_raw.cast_to_raw(UTL_tcp.CRLF||'<FONT FACE="Courier New">'||message_body||'</FONT>'));
    --UTL_smtp.write_data(mail_conn,message_body);
    UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
    UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF);
    IF lc_dispute_id     IS NOT NULL AND lc_type_name LIKE 'DRT%' THEN
      IF lc_problem_code IN ('BT', 'FRE', 'PRC') THEN
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        BEGIN
          OPEN mesg_cur;
          LOOP
            FETCH mesg_cur INTO mesg_rec;
            EXIT
          WHEN mesg_cur%notfound;
            lc_dispute_msg := mesg_rec.message;
            send_header(mail_conn,'Note',lc_dispute_msg);
            UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
            UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
          END LOOP;
          CLOSE mesg_cur;
        END;
        --   UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
        --  send_header(mail_conn,'Dispute Link ',lc_url);
        -- UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      END IF; -- pronlem code
    END IF;   --DRT
    IF lc_gen_mesg IS NOT NULL THEN
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      send_header(mail_conn,'Note:-',lc_gen_mesg);
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
      UTL_smtp.write_data(mail_conn,UTL_tcp.CRLF||'<br>');
    END IF; --gen mesg
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
    Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.SEND_EMAIL' ,p_error_message_code => 'XX_CS_SR01_ERROR_LOG' ,p_error_msg => lx_msg_data);
    RETURN_CODE := 1;
    --  dbms_output.put_line('error '||lx_msg_data);
  END;
  COMMIT;
END;
-- +===================================================================+
-- | Name  : get_translation_info                                       |
-- | Description     : This function returns the transaltion info       |
-- |                                                                    |
-- |                                                                    |
-- | Parameters      :                                                  |
-- +===================================================================+
FUNCTION get_translation_info(
    p_translation_name IN xx_fin_translatedefinition.translation_name%TYPE,
    p_translation_info OUT xx_fin_translatevalues%ROWTYPE,
    p_error_msg OUT VARCHAR2)
  RETURN VARCHAR2
IS
BEGIN
  p_error_msg        := NULL;
  p_translation_info := NULL;
  SELECT xftv.*
  INTO p_translation_info
  FROM xx_fin_translatedefinition xft,
    xx_fin_translatevalues xftv
  WHERE xft.translate_id   = xftv.translate_id
  AND xft.enabled_flag     = 'Y'
  AND xftv.enabled_flag    = 'Y'
  AND xft.translation_name = p_translation_name;
  RETURN 'Success';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  p_error_msg := 'No Translation info found for '||p_translation_name;
  fnd_file.put_line(fnd_file.log,p_error_msg);
  RETURN 'Failure';
WHEN OTHERS THEN
  p_error_msg := 'Error while getting the trans info '|| SQLERRM;
  fnd_file.put_line(fnd_file.log,p_error_msg);
  RETURN 'Failure';
END get_translation_info;
/***************************************************************************
-- Retrive the messages from CallCenter Mail Account
*****************************************************************************/
-- Start of changes for defect# 37051
--PROCEDURE Read_Response
PROCEDURE Read_Response(
    p_result OUT NUMBER,
    p_message OUT VARCHAR2)
  -- End of changes for defect# 37051
AS
  --POP3_SERVER     varchar2(50);
  --POP3_PORT       constant number := 110;
  --POP3_TIMEOUT    constant number := 5;
  POP3_OK             CONSTANT VARCHAR2(10) := '+OK';
  E_POP3_ERROR        EXCEPTION;
  E_READ_TIMEOUT      EXCEPTION;
  e_process_exception EXCEPTION;
  pragma exception_init( E_READ_TIMEOUT, -29276 );
  socket UTL_TCP.connection;
  line VARCHAR2(4000);
  r_line RAW(32767);
  msg_id         NUMBER;
  msg_from       VARCHAR2(4000) := '';
  msg_to         VARCHAR2(4000) := '';
  msg_sub        VARCHAR2(4000) := '';
  from_msg_stamp VARCHAR2(1000) := '';
  msg_body CLOB                 := NULL;
  v_msg_body CLOB               := NULL;
  bytes                  INTEGER;
  crlf                   VARCHAR2(2) := chr(13) || chr(10);
  hyphen_checker         NUMBER      := 0;
  subject_read_indicator NUMBER      := 0;
  marked_for_deletion    NUMBER      := 0;
  userName               VARCHAR2(4000);
  password               VARCHAR2(4000);
  msgNum                 NUMBER      := 1;
  total_msg              NUMBER      := 0;
  process_flag           VARCHAR2(1) := 'Y';
  LC_SR_STATUS_ID        VARCHAR2(25);
  LC_PROBLEM_CODE        VARCHAR2(50);
  LN_TYPE_ID             NUMBER;
  LC_RESPONSE_STATUS     VARCHAR2(25);
  LC_REQUEST_ID          VARCHAR2(25);
  LN_INCIDENT_ID         NUMBER;
  LT_SR_NOTES XX_CS_SR_MAIL_NOTES_REC;
  LC_USER_ID       VARCHAR2(200);
  i                NUMBER;
  X_RETURN_STATUS  VARCHAR2(25);
  X_MSG_DATA       VARCHAR2(1000);
  LC_INSTANCE      VARCHAR2(25);
  LC_DRT_ID        VARCHAR2(100);
  LC_DRT_EMAIL     VARCHAR2(150);
  LN_RETURN_CODE   NUMBER;
  LN_STATUS_ID     NUMBER;
  LC_UNDELIVER_MSG VARCHAR2(150);
  LC_BASE64_FLAG   VARCHAR2(1) := 'N';
  LC_DECODE_FLAG   VARCHAR2(1) := 'N';
  LC_END_FLAG      VARCHAR2(1) := 'N';
  -- TDS SMB subscription changes
  LC_WO_NUMBER     VARCHAR2(25);
  LC_CUST_NAME     VARCHAR2(250);
  LC_CHANGE_ACTION VARCHAR2(50);
  LC_SKUS          VARCHAR2(50);
  LN_UNITS         NUMBER;
  lc_translation_info xx_fin_translatevalues%ROWTYPE;
  lc_trans_name xx_fin_translatedefinition.translation_name%TYPE := 'XXCS_EMAIL_CONFIG';
  lc_error_message VARCHAR2(2000)                                := NULL;
  lc_return_status VARCHAR2(2000)                                := NULL;
  l_warning_cnt    NUMBER                                        :=0; -- For Defect# 38994 to count No of Mails Not Updated
  lv_return_status VARCHAR2(25);                                      -- For Defect# 38994
  lc_mail_sender   VARCHAR2(255) := NULL;                             -- For Defect# 38994
  lc_recipients    VARCHAR2(255) := NULL;                             -- For Defect# 38994
  lc_html_data_flag  VARCHAR2(1) := 'N';
  lc_html_data       CLOB := NULL;
  lc_debug_flag      VARCHAR2(1);
  /**************************************************************************/
  -- send a POP3 command
  -- (we expect each command to respond with a +OK)
  /*************************************************************************/
FUNCTION WriteToPop(
    command VARCHAR2 )
  RETURN VARCHAR2
IS
  LEN  INTEGER;
  resp VARCHAR2(4000);
BEGIN
  fnd_file.put_line(fnd_file.log , 'Command ' ||Command);
  LEN := UTL_TCP.write_line( socket, command );
  UTL_TCP.Flush( socket );
  fnd_file.put_line(fnd_file.log , 'len :' ||LEN);
  -- using a hack to check the popd response
  LEN := UTL_TCP.read_line( socket, resp );
  fnd_file.put_line(fnd_file.log, 'len1 ' ||LEN);
  fnd_file.put_line(fnd_file.log, 'Substr(resp,1,3)' || SUBSTR(resp,1,3));
  IF (SUBSTR(resp,1,3) != POP3_OK) THEN
    x_msg_data         := 'Error Resp,1,3 '||line;
    fnd_file.put_line(fnd_file.log,x_msg_data);
    --marked_for_deletion := 1;
    --raise E_POP3_ERROR;                            -- Commented For Defect# 38994
    fnd_file.put_line(fnd_file.log, 'Func -  Substr(resp,1,3)' || ''||SUBSTR(resp,1,3)||''||'is not equal to +OK'); -- Added For Defect# 38994
    RETURN( resp );                                                                                                 -- Added For Defect# 38994
  END IF;
  RETURN( resp );
  -- Start of changes for defect# 37051
EXCEPTION
WHEN OTHERS THEN
  --RAISE E_POP3_ERROR;                            --Commented For Defect# 38994
  fnd_file.put_line(fnd_file.log, 'Func - WriteToPop- Function Exception Block'||SUBSTR(resp,1,3)||sqlerrm); -- Added For Defect# 38994
  RETURN( resp );                                                                                            -- Added For Defect# 38994
  -- End of changes for defect# 37051
END WriteToPop;
/***************************************************************************/
/**************************************************************************/
BEGIN
  lt_sr_notes := XX_CS_SR_MAIL_NOTES_REC(NULL,NULL,NULL,NULL);
  /* begin
  select meaning
  into POP3_SERVER
  from cs_lookups
  where lookup_type = 'XX_CS_POP3_CODE'
  and lookup_code = 'SERVER';
  exception
  when others then
  POP3_SERVER  := 'USCHMSX03.na.odcorp.net';
  end;
  begin
  select meaning
  into userName
  from cs_lookups
  where lookup_type = 'XX_CS_POP3_CODE'
  and lookup_code = 'USERID';
  exception
  when others then
  userName  := 'SVC-CallCenter@na.odcorp.net';
  end;
  begin
  select meaning
  into PASSWORD
  from cs_lookups
  where lookup_type = 'XX_CS_POP3_CODE'
  and lookup_code = 'PASSWD';
  exception
  when others then
  PASSWORD  := NULL;
  end;*/
  fnd_file.put_line(fnd_file.log, 'Getting the Translation information ..');
  lc_error_message    := NULL;
  lc_return_status    := NULL;
  lc_return_status    := get_translation_info( p_translation_name => lc_trans_name, p_translation_info => lc_translation_info, p_error_msg => lc_error_message);
  IF lc_error_message IS NOT NULL THEN
    RAISE e_process_exception ;
  END IF;
  fnd_file.put_line(fnd_file.log, 'Server Name :' || lc_translation_info.target_value1 );
  fnd_file.put_line(fnd_file.log, 'Port Number :' || lc_translation_info.target_value2 );
  fnd_file.put_line(fnd_file.log, 'POP timeout :' || lc_translation_info.target_value3 );
  fnd_file.put_line(fnd_file.log, 'Wallet path :' || lc_translation_info.target_value4 );
  fnd_file.put_line(fnd_file.log, 'Wallet pwd  :' || lc_translation_info.target_value5 );
  fnd_file.put_line(fnd_file.log, 'User Name   :' || lc_translation_info.target_value6 );
  --   fnd_file.put_line(fnd_file.log, 'Pwd         :' || lc_translation_info.target_value7 );
  fnd_file.put_line(fnd_file.log, 'Debug Value      :' || lc_translation_info.target_value8 );
  fnd_file.put_line(fnd_file.log, 'Sender Mail Id   :' || lc_translation_info.target_value9 );
  fnd_file.put_line(fnd_file.log, 'Recipients Mail  :' || lc_translation_info.target_value10 );
  lc_debug_flag := NVL(lc_translation_info.target_value8,'N');
  fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
  IF ( lc_translation_info.target_value1 IS NULL OR lc_translation_info.target_value2 IS NULL OR lc_translation_info.target_value3 IS NULL OR lc_translation_info.target_value4 IS NULL OR lc_translation_info.target_value5 IS NULL OR lc_translation_info.target_value6 IS NULL OR lc_translation_info.target_value7 IS NULL ) THEN
    fnd_file.put_line(fnd_file.log, ' Required values are missing in the Translation .. please make sure to update the translation with all the values and re-submit the process..');
    RAISE e_process_exception ;
  END IF;
  fnd_file.put_line(fnd_file.log, 'Opening the connection ...');
  -- open a socket connection to the POP3 server
  socket := UTL_TCP.open_connection( remote_host => lc_translation_info.target_value1, --lc_pop3_server, POP3_SERVER,
  remote_port => lc_translation_info.target_value2,                                    -- POP3_PORT,
  tx_timeout => lc_translation_info.target_value3,                                     --POP3_TIMEOUT
  wallet_path => lc_translation_info.target_value4,                                    --lc_wallet_path, --'file:/oracle/product/database/11.2.0/gsidev02/owm/wallets/oracle',
  wallet_password => lc_translation_info.target_value5,                                --lc_wallet_pwd,  --'oradev02',
  charset => 'US7ASCII' );
  /*      socket := UTL_TCP.open_connection(
  remote_host => 'pop.gmail.com', -- POP3_SERVER,
  remote_port => 995, --pop3_port, --25, --143, --25, --443, --25, --POP3_PORT,
  tx_timeout  => 20, --POP3_TIMEOUT,
  wallet_path => 'file:/oracle/product/database/11.2.0/gsidev02/owm/wallets/oracle',
  wallet_password => 'oradev02',
  charset     => 'US7ASCII'
  ); */
  fnd_file.put_line(fnd_file.log,'Connected :');
  utl_tcp.secure_connection(socket);
  -- read the server banner/response from the pop3 daemon
  line := UTL_TCP.get_line(socket);
  -- Testing whether the connection was made successfully
  fnd_file.put_line(fnd_file.log,'Connection status '|| SUBSTR(line,1,3));
  IF (SUBSTR(line,1,3) != POP3_OK) -- POP3_OK =  +OK
    THEN
    raise E_POP3_ERROR;
  ELSE
    fnd_file.put_line(fnd_file.log, 'Authenticating the user name ..');
    -- authenticate with the POP3 server using the USER and PASS commands
    line := WriteToPop('USER ' || lc_translation_info.target_value6); --userName);
    fnd_file.put_line(fnd_file.log, 'Authenticating the password ..');
    line := WriteToPop('PASS ' || lc_translation_info.target_value7);            --password);  writetopop(PASStrans) +OK
    fnd_file.put_line(fnd_file.log,'Authentication status '|| SUBSTR(line,1,3)); -- +OK
    IF (SUBSTR(line,1,3) != POP3_OK) THEN                                        -- POP3_OK =  +OK
      x_msg_data         := 'Error while authentication with password'||line;
      fnd_file.put_line(fnd_file.log,x_msg_data);
      raise E_POP3_ERROR;
    END IF;
    fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
    line      := WriteToPop('STAT');
    line      := SUBSTR(line, 5, instr(line, ' ', 5)-5);
    total_msg := to_number(line);
    fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
    dbms_output.put_line('total msgs '||total_msg);
    fnd_file.put_line(fnd_file.log, 'total msgs '||total_msg);
    fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
    /********************************************************************/
    -- This is where we retrieve the specific email message and start
    -- parsing through the data to determine what to do with the message
    -- (i.e., delete it (if it's a returned undeliverable message), copy
    -- contents (i.e., SUBJECT, FROM, BODY, etc.), etc.), assuming that there
    -- are messages in the queue.
    /********************************************************************/
    IF (total_msg > 0) THEN
      LOOP -- loop through all messages
        line             := WriteToPop('RETR ' || msgNum);
        LC_REQUEST_ID    := NULL;
        LC_UNDELIVER_MSG := NULL;
        process_flag     := 'Y';
        LC_BASE64_FLAG   := 'N';
        LC_DECODE_FLAG   := 'N';
        LC_END_FLAG      := 'N';
        BEGIN
          LOOP -- loop through all parts of current message
            bytes := UTL_TCP.Available( socket );
            --fnd_file.put_line(fnd_file.log, 'bytes :'|| bytes);
            IF bytes > 0 THEN
              bytes := UTL_TCP.read_line( socket, line );
			  line  := REPLACE(line, CHR (13) || CHR (10), '');
			  IF lc_debug_flag = 'Y' THEN
                fnd_file.put_line(fnd_file.log,'Line Data :'||line);
		      END IF;
			  IF line LIKE 'From:%' THEN
                IF lc_html_data IS NULL THEN
                  lc_html_data := 'Response '||line;
                  lc_html_data := lc_html_data || crlf || crlf;
                END IF;
              END IF;
              IF trim(line) like '<body%' THEN
                lc_html_data_flag := 'Y';
              END IF;
              IF lc_html_data_flag = 'Y' THEN
                 lc_html_data := lc_html_data||CHR(10)||line;
                 IF trim(line) = '</body>' THEN
                   lc_html_data_flag := 'N';
                 END IF;
              END IF;
              --       bbms_output.put_line('line:   '||line );
              /***************************************************************/
              -- If FROM part matches, then we know it was a returned
              -- undeliverable email, so we ignore it, and move to the
              -- next message.
              /**************************************************************/
              IF (instr(upper(trim(line)), upper(trim('Return-path: '))) > 0) OR (instr(upper(trim(line)), upper(trim('From: Mail Delivery'))) > 0) OR
                -- (instr(upper(trim(line)), upper(trim('From: SVC-CallCenter@officedepot.com '))) > 0) or
                (instr(upper(trim(line)), upper(trim('type="multipart/alternative"'))) > 0) OR (instr(upper(trim(line)), upper(trim('Subject: Delivery Status Notification'))) > 0) OR (instr(upper(trim(line)), upper(trim('Subject: Delivery Status Notification'))) > 0) OR (instr(upper(trim(line)), upper(trim('boundary="'))) > 0) OR (instr(upper(trim(line)), upper(trim('Subject: Mail System Error'))) > 0) OR (instr(upper(trim(SUBSTR(line, 1, 11))), upper(trim('Message-ID:'))) > 0) OR (instr(upper(trim(SUBSTR(line, 1, 12))), upper(trim('In-Reply-To:'))) > 0) OR (instr(upper(trim(line)), upper(trim('X-MS-Has-Attach:'))) > 0) OR (instr(upper(trim(line)), upper(trim('X-MS-TNEF-Correlator:'))) > 0) OR (instr(upper(trim(SUBSTR(line, 1, 13))), upper(trim('Thread-Topic:'))) > 0) OR (instr(upper(trim(SUBSTR(line, 1, 13))), upper(trim('Thread-Index:'))) > 0) OR line LIKE 'Content-Type: application/octet-stream%' OR line LIKE 'X-AnalysisOut%' OR line LIKE 'Note:%' OR line LIKE 'Dispute Link%' --or
                -- (trim(line) like '%_NextPart_%' )
                THEN
                --dbms_output.put_line('line:   '||line );
                subject_read_indicator := 0;
                IF line LIKE 'Note:%' THEN
                  LC_END_FLAG  := 'Y';
                  process_flag := 'N';
                END IF;
                marked_for_deletion := 1;
              ELSE
                -- extracting the various parts of the email message */
                -----Ignoring the multipart messages
                IF line LIKE 'Content-Type: text/plain;%' 
                  THEN
                  process_flag := 'Y';
                  IF (trim(line) LIKE '%X-Brightmail-Tracker%' ) THEN
                    LC_DECODE_FLAG := 'Y';
                  END IF;
                END IF;
                IF line LIKE 'Content-Type: multipart%' OR line LIKE 'Content-Type: message%' THEN
                  process_flag := 'Y';
                  IF (trim(line) LIKE '%charset=%' ) THEN
                    IF SUBSTR(SUBSTR(LINE,INSTR(LINE,'charset=')+1),8,10)   <> '"us-ascii"' THEN
                      LC_DECODE_FLAG                                        := 'Y';
                    elsif SUBSTR(SUBSTR(LINE,INSTR(LINE,'charset=')+1),8,7) <> '"UTF-8"' THEN
                      LC_DECODE_FLAG                                        := 'Y';
                    END IF;
                  END IF;
                END IF;
                IF (trim(line) LIKE '%_NextPart_%' ) THEN
                  LC_DECODE_FLAG := 'Y';
                END IF;
                IF (trim(line) LIKE '%X-Brightmail-Tracker%' ) THEN
                  LC_DECODE_FLAG := 'Y';
                END IF;
                IF trim(line) LIKE 'Content-Transfer-Encoding%base64%' THEN
                  LC_BASE64_FLAG := 'Y';
                END IF;
                IF line LIKE 'Content-Type: text/html;%' OR line LIKE 'Content-Type: image/jpeg%' THEN
                  process_flag := 'N';
                END IF;
                IF LC_BASE64_FLAG = 'Y' THEN
                  IF trim(line) LIKE '%This is a multi-part message in MIME format.%' THEN
                    LC_DECODE_FLAG := 'Y';
                  END IF;
                  IF trim(line) LIKE '%Motorola-A-Mail%' THEN
                    LC_DECODE_FLAG := 'Y';
                  END IF;
                  IF trim(line) LIKE '%X-Brightmail-Tracker%' THEN
                    LC_DECODE_FLAG := 'Y';
                  END IF;
                END IF;
                -----
                IF line LIKE 'From:%' THEN
                  IF msg_body IS NULL THEN
                    msg_body := 'Response '||line;
                    msg_body := msg_body || crlf || crlf;
                  END IF;
                END IF;
                IF instr(upper(trim(SUBSTR(line, 1, 23))), upper(trim('Subject: Undeliverable:'))) > 0 THEN
                  line                                                                            := trim(REPLACE(line, 'Subject: Undeliverable:'));
                  msg_sub                                                                         := line ;
                  LC_UNDELIVER_MSG                                                                := 'Undeliverable';
                  -- LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+1),3,7);       -- Commented for Defect#40980
                  LC_REQUEST_ID                                                           := REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+3, LENGTH(LINE)),'[$0-9]+'); ---(1) Added for Defect#40980
                  subject_read_indicator                                                  := 1;
                elsif instr(upper(trim(SUBSTR(line, 1, 13))), upper(trim('Subject: WO#'))) > 0 THEN
                  -- TDS SMB subscriptions accept.
                  line    := trim(REPLACE(line, 'Subject: '));
                  msg_sub := line ;
                  --DBMS_OUTPUT.PUT_LINE('LINE##### '||LINE);
                  IF Line LIKE 'WO#%' THEN
                    LC_WO_NUMBER  := SUBSTR(SUBSTR(trim(LINE),INSTR(trim(LINE),'WO#')+1),3,14);
                    lc_wo_number  := trim(lc_wo_number);
                    lc_request_id := lc_wo_number;
                  END IF;
                elsif instr(upper(trim(SUBSTR(line, 1, 13))), upper(trim('Subject: RE: '))) > 0 THEN
                  line                                                                     := trim(REPLACE(line, 'Subject: RE: '));
                  msg_sub                                                                  := line ;
                  IF Line LIKE '%SR#%' THEN
                    -- LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+1),3,7);      -- Commented for Defect#40980
                    LC_REQUEST_ID:= REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+3, LENGTH(LINE)),'[$0-9]+'); ---(2) Added for Defect#40980
                  END IF;
                elsif instr(upper(trim(SUBSTR(line, 1, 8))), upper(trim('Subject:'))) > 0 THEN
                  line                                                               := trim(REPLACE(line, 'Subject:'));
                  msg_sub                                                            := line ;
                  IF Line LIKE '%SR#%' THEN
                    -- LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+1),3,7);      -- Commented for Defect#40980
                    LC_REQUEST_ID:= REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'SR#')+3, LENGTH(LINE)),'[$0-9]+'); ---(3) Added for Defect#40980
                  END IF;
                elsif instr(upper(trim(SUBSTR(line, 1, 24))), upper(trim('Subject: Service Request'))) > 0 THEN
                  line                                                                                := trim(REPLACE(line, 'Subject: Service Request'));
                  msg_sub                                                                             := line ;
                  IF LINE LIKE '%Subject: Service Request%' THEN
                    --LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Subject: Service Request')+1),24,7);     -- Commented for Defect#40980
                    LC_REQUEST_ID:= REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'Subject: Service Request')+24, LENGTH(LINE)),'[$0-9]+'); ---(4) Added for Defect#40980
                  END IF;
                elsif instr(upper(trim(SUBSTR(line, 1, 16))), upper(trim('Service Request:'))) > 0 THEN
                  IF LC_REQUEST_ID                                                            IS NULL OR LENGTH(lc_request_id) < 7 THEN
                    --    LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+1),16,7);     -- Commented for Defect#40980
                    LC_REQUEST_ID:= REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+16, LENGTH(LINE)),'[$0-9]+'); ---(5) Added for Defect#40980
                  END IF;
                elsif line LIKE '%Service Request:%' THEN
                  IF LC_REQUEST_ID IS NULL OR LENGTH(lc_request_id) < 7 THEN
                    --LC_REQUEST_ID := SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+1),16,7); -- Commented for Defect#40980
                    LC_REQUEST_ID:= REGEXP_SUBSTR(SUBSTR(LINE,INSTR(LINE,'Service Request:')+16, LENGTH(LINE)),'[$0-9]+'); ---(6) Added for Defect#40980
                  END IF;
                  -- dbms_output.put_line('line# '||line);
                  --  dbms_output.put_line('SR# '||lc_request_id);
                END IF; -- performing extractions for email message component
                IF lc_request_id      IS NOT NULL THEN
                  marked_for_deletion := 1;
                END IF;
                subject_read_indicator := 1;
              END IF; -- checking if email is returned undeliverable or an actual reply from user
            END IF;   -- checking if bytes > 0
            /*************************************************************************/
            -- We set this flag inside of the if statement that processes the Subject
            -- line because we know the next line will be the beginning of the Body
            /*************************************************************************/
            IF (subject_read_indicator > 0) THEN
              IF process_flag          = 'Y' AND LC_END_FLAG = 'N' THEN
                -- dbms_output.put_line('Line  '||process_flag||'  '||line );
                IF ((upper(trim(line))                != '') OR (instr(upper(trim(SUBSTR(line, 1, 8))), upper(trim('Content-'))) = 0)) THEN
                  IF ((upper(SUBSTR(trim(line), 1, 2)) = '--') AND (LENGTH(line) > 10)) THEN
                    hyphen_checker                    := hyphen_checker + 1;
                  ELSE
                    -- dbms_output.put_line('--   '||line );
                    IF (trim(line) LIKE 'X-MimeOLE:%') THEN
                      subject_read_indicator := 0;
                    elsif (trim(line) LIKE 'X-Original%') THEN
                      subject_read_indicator := 0;
                    elsif (trim(line) LIKE 'MIME-Version:%') OR (trim(line) LIKE '%MIME%')THEN
                      subject_read_indicator := 0;
                    elsif (upper(line) LIKE '%US-ASCII%') THEN
                      line := NULL;
                    elsif ((line) LIKE 'References:%') THEN
                      line := NULL;
                    elsif (trim(line) LIKE 'Note:-%' OR trim(line) LIKE '%Note:-%') THEN
                      subject_read_indicator := 0;
                      process_flag           := 'N';
                      LC_END_FLAG            := 'Y';
                    elsif (trim(line) LIKE 'Received:%' ) THEN
                      subject_read_indicator := 0;
                      process_flag           := 'N';
                    elsif (trim(line) LIKE 'http%' ) THEN
                      subject_read_indicator := 0;
                    elsif (trim(line) LIKE '<http%' ) THEN
                      subject_read_indicator := 0;
                      --    process_flag := 'N';
                    elsif (trim(line) LIKE 'boundary=%' ) THEN
                      subject_read_indicator := 0;
                      process_flag           := 'N';
                    elsif (trim(line) LIKE '%_NextPart_%' ) THEN
                      subject_read_indicator := 0;
                      process_flag           := 'N';
                    elsif (trim(line) LIKE '%Motorola-A-Mail%' ) THEN
                      subject_read_indicator := 0;
                      process_flag           := 'N';
                    elsif (trim(line) LIKE '=09' ) THEN
                      subject_read_indicator := 0;
                    elsif (trim(line) LIKE '=20' ) THEN
                      subject_read_indicator := 0;
                      line                   := NULL;
                    elsif (trim(line) LIKE '%charset=%' ) THEN
                      subject_read_indicator := 0;
                      line                   := NULL;
                    ELSE
                      --- Conversion ----------------
                      IF lc_base64_flag = 'Y' AND LC_DECODE_FLAG = 'Y' THEN
                        --  DBMS_OUTPUT.PUT_LINE('BASE64 DATA');
                        line := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(line)));
                        --    DBMS_OUTPUT.PUT_LINE('line '||line);
                        IF (trim(line) LIKE '%_NextPart_%' ) THEN
                          LC_DECODE_FLAG := 'N';
                        END IF;
                        IF trim(line) LIKE '%Motorola-A-Mail%' THEN
                          LC_DECODE_FLAG := 'N';
                        END IF;
                        BEGIN
                          msg_body := msg_body || line;
                        EXCEPTION
                        WHEN OTHERS THEN
                          marked_for_deletion := 1;
                          msg_sub             := 'Error and deleting message for SR# '||LC_REQUEST_ID;
                          --  DBMS_OUTPUT.PUT_LINE('line '||line);
                          fnd_file.put_line(fnd_file.log,msg_sub);
                        END;
                      ELSE
                        line := REPLACE(line, '=20', ' ');
                        line := REPLACE(line, '=90', ' ');
                        BEGIN
                          msg_body := msg_body || crlf || line ;
                        EXCEPTION
                        WHEN OTHERS THEN
                          marked_for_deletion := 1;
                          msg_sub             := 'Error while assinging msg_body# '||LC_REQUEST_ID;
                          --  DBMS_OUTPUT.PUT_LINE('line '||line);
                          fnd_file.put_line(fnd_file.log,msg_sub);
                        END;
                      END IF;
                      --- end Conversion ----------------
                      --   DBMS_OUTPUT.PUT_LINE('line '||line);
                      IF UPPER(LINE) LIKE '%APPROVED%' THEN
                        LC_RESPONSE_STATUS := 'APPROVED';
                      END IF;
                      -- TDS variables
                      IF lc_wo_number IS NOT NULL THEN
                        IF UPPER(LINE) LIKE '%CUSTOMER NAME%' THEN
                          LC_CUST_NAME := (SUBSTR(LINE,INSTR(LINE,':')+1));
                        END IF;
                        -- Change Action
                        IF UPPER(LINE) LIKE '%CHANGEACTION%' THEN
                          LC_CHANGE_ACTION := (SUBSTR(LINE,INSTR(LINE,':')+1));
                          LC_CHANGE_ACTION := trim(LC_CHANGE_ACTION);
                        END IF;
                        --SKUS
                        IF UPPER(LINE) LIKE '%SKU%' THEN
                          LC_SKUS := (SUBSTR(LINE,INSTR(LINE,':')+1));
                          LC_SKUS := trim(LC_SKUS);
                        END IF;
                        --UNITS
                        IF UPPER(LINE) LIKE '%UNITS%' THEN
                          LN_UNITS := (SUBSTR(LINE,INSTR(LINE,':')+1));
                          LN_UNITS := TRIM(LN_UNITS);
                        END IF;
                      END IF; -- wo number
                    END IF;   -- ASCII
                    --    end if; -- hyphen checker
                  END IF; -- checking if line begins with "--"
                END IF;   -- only if it passes our checks to we add the contents to our msg body var
              END IF;     -- process flag
            END IF; -- Subject read indicator
            EXIT
          WHEN bytes = 0;
          END LOOP; -- loop through all parts of current message
          --  dbms_output.Put_line('msg '||msg_body);
          --    dbms_output.put_line('SR  |'||LC_REQUEST_ID ||'|');
		  IF lc_debug_flag = 'Y' THEN
            fnd_file.put_line(fnd_file.log,'Message Body End Loop : '||CHR(10)||msg_body);
		  END IF;
                    
          IF lc_wo_number IS NOT NULL THEN
            lt_sr_notes.notes        := 'SMB SKUs are updated ';
            lt_sr_notes.note_details := SUBSTR(msg_body,1,32760);
          ELSE
            lt_sr_notes.notes        := 'Response ';
            lt_sr_notes.note_details := SUBSTR(msg_body,1,32760);
          END IF;
            IF lc_debug_flag = 'Y' THEN
              fnd_file.put_line(fnd_file.log,'HTML Rich Text Data : ' ||CHR(10)||lc_html_data);
			END IF;
			IF trim(lc_html_data) IS NOT NULL THEN
              lc_html_data := '<html'||CHR(10)||lc_html_data||CHR(10)||'</html>';
			END IF;
			IF lc_debug_flag = 'Y' THEN
              fnd_file.put_line(fnd_file.log,'Converting html to text data ');
			END IF;
            --lc_html_data := SUBSTR(JTF_NOTES_PUB.get_rich_note_varchar(SUBSTR(lc_html_data,1,32760),'Y'),1,32760);
			lc_html_data := JTF_NOTES_PUB.get_rich_note_clob(lc_html_data,'Y');
			IF lc_debug_flag = 'Y' THEN
			  fnd_file.put_line(fnd_file.log,'Converted text data ' ||lc_html_data);
              fnd_file.put_line(fnd_file.log,'Assigning to note details ');
			END IF;
            --lt_sr_notes.note_details := SUBSTR(lt_sr_notes.note_details||' '||lc_html_data,1,32760);
			lt_sr_notes.note_details := SUBSTR(lc_html_data,1,32760);
          ------------------Update SR---------------------------------------------
          BEGIN
            SELECT INCIDENT_ID,
              INCIDENT_TYPE_ID,
              PROBLEM_CODE,
              INCIDENT_ATTRIBUTE_4,
              INCIDENT_STATUS_ID
            INTO LN_INCIDENT_ID,
              LN_TYPE_ID,
              LC_PROBLEM_CODE,
              LC_DRT_ID,
              LN_STATUS_ID
            FROM CS_INCIDENTS_ALL_B
            WHERE INCIDENT_NUMBER = LC_REQUEST_ID;
          EXCEPTION
          WHEN OTHERS THEN
            --   dbms_output.put_line('exception '||sqlerrm);
            LN_INCIDENT_ID := NULL;
          END;
          fnd_file.put_line(fnd_file.log,'Incident Id :'||LN_INCIDENT_ID);
          IF LN_INCIDENT_ID IS NOT NULL THEN
            -- marked_for_deletion := 1;
            IF LC_PROBLEM_CODE     IN ('BT', 'FRE', 'PRC') AND LC_UNDELIVER_MSG IS NULL THEN
              IF LC_RESPONSE_STATUS = 'APPROVED' THEN
                LC_SR_STATUS_ID    := 'Respond';
                -- AM approved and transfer the request to CS team
                IF ln_status_id <> 2 THEN
                  BEGIN
                    XX_CS_DISPUTE_SR_PKG.UPDATE_SR (P_REQUEST_ID => ln_incident_id, P_NOTES => 'Acct. Manager Approved the request', X_RETURN_STATUS => x_return_status, X_MSG_DATA => x_msg_data);
                  EXCEPTION
                  WHEN OTHERS THEN
                    x_msg_data := 'Error while updating Dispute SR ID : '|| ln_incident_id||' '||sqlerrm;
                    Log_Exception ( p_error_location => 'XX_CS_MES_PKG.READ_RESPONSE' ,p_error_message_code => 'XX_CS_0001_UNEXPECTED_ERR' ,p_error_msg => x_msg_data );
                  END;
                END IF;
              ELSE
                LC_SR_STATUS_ID := 'Closed';
                IF LC_DRT_ID    IS NOT NULL THEN
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
                    BEGIN
                      XX_CS_MESG_PKG.send_email (sender => 'SVC-CallCenter@officedepot.com', recipient => lc_drt_email, cc_recipient => NULL , bcc_recipient => NULL , subject => 'Account Manager Response.', message_body => msg_body, p_message_type => 'INFO', IncidentNum => ln_incident_id, return_code => ln_return_code );
                    EXCEPTION
                    WHEN OTHERS THEN
                      X_MSG_DATA := 'Error while sending mail to DRT '|| ln_return_code;
                      Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.READ_RESPONSE' ,p_error_message_code => 'XX_CS_0003_SEND_ERR' ,p_error_msg => X_MSG_DATA);
                    END;
                  END IF;
                END IF;
                IF ln_status_id <> 2 THEN
                  XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS( P_SR_REQUEST_ID => LN_INCIDENT_ID, P_USER_ID => LC_USER_ID, P_STATUS_ID => NULL, P_STATUS => LC_SR_STATUS_ID, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => X_MSG_DATA );
                END IF;
              END IF;
            ELSE
              IF LN_TYPE_ID = 11004 THEN
                BEGIN
                  SELECT 2 status_id
                  INTO ln_status_id
                  FROM cs_incident_statuses_tl
                  WHERE name IN
                    (SELECT meaning FROM cs_lookups WHERE lookup_type = 'XX_CS_WH_STATUS'
                    )
                  AND incident_status_id = ln_status_id;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
                WHEN OTHERS THEN
                  x_msg_data := 'Error while CLOSE LOOP Status'||LN_INCIDENT_ID;
                  fnd_file.put_line(fnd_file.log,x_msg_data);
                END;
              END IF;
              IF LC_WO_NUMBER   IS NULL THEN
                LC_SR_STATUS_ID := 'Respond';
                IF ln_status_id <> 2 THEN
                  XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS( P_SR_REQUEST_ID => LN_INCIDENT_ID, P_USER_ID => LC_USER_ID, P_STATUS_ID => NULL, P_STATUS => LC_SR_STATUS_ID, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => X_MSG_DATA );
                END IF;
              END IF; -- work order
            END IF;   -- Problem code check
			IF lc_debug_flag = 'Y' THEN
              fnd_file.put_line(fnd_file.log,'Calling CREATE_NOTE Procedure to update SR Notes. ');
			END IF;
            BEGIN
              XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id => ln_incident_id, p_sr_notes_rec => lt_sr_notes, p_return_status => x_return_status, p_msg_data => x_msg_data);
              COMMIT;
              lv_return_status := x_return_status; -- Added For Defect# 38994
			  fnd_file.put_line(fnd_file.log,'SR#'||lc_request_id||' is being updated with the Message'); -- Added for Defect#
              fnd_file.put_line(fnd_file.log,'Message Subject: '||msg_sub);                               -- Modified for Defect#40980
            EXCEPTION
            WHEN OTHERS THEN
              lv_return_status :='N';                                  -- Added For Defect# 38994
              fnd_file.put_line(fnd_file.log,'Unable to Create Note'); -- Added For Defect# 38994
              x_msg_data := 'Error while reading mail box '||sqlerrm;
              Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.READ_RESPONSE' ,p_error_message_code => 'XX_CS_SR01_ERROR_LOG' ,p_error_msg => x_msg_data);
            END ;
		  ELSE
		    line                 := WriteToPop('DELE ' || msgNum);
          END IF;
		  IF lc_debug_flag = 'Y' THEN
		    fnd_file.put_line(fnd_file.log,'Creates Notes return Status : '||lv_return_status);
		    fnd_file.put_line(fnd_file.log,'Msg Marked for deletetion value : '||marked_for_deletion);
		  END IF;
          --------------------------------------------------------------------------
          IF lv_return_status = 'S' -- Added For Defect# 38994 - to check the Mail got Updated in SR
            THEN                    -- Added For Defect# 38994
            -- Delete the Updated message.
            IF (marked_for_deletion = 1) THEN
              line                 := WriteToPop('DELE ' || msgNum);
            END IF; -- adding email message to queue if it wasn't marked for deletion
          ELSE
            -- Code Added For Defect# 38994 - To Print the Messages Not Updated in SR  --  Starts Here
            l_warning_cnt := l_warning_cnt + 1;
            /* Code Added to get the translation values from Translation table for Defect# 38994 Starts Here*/
            /*BEGIN
              SELECT target_value1,
                target_value2
              INTO lc_mail_sender,
                lc_recipients
              FROM xx_fin_translatevalues
              WHERE source_value1 = 'XX_CS_EMAIL_ALERTS';
			  lc_mail_sender := lc_translation_info.target_value9;
			  lc_recipients := lc_translation_info.target_value10;
              fnd_file.put_line(fnd_file.Output,'Messages Not Updated is '||'  --  '||' msgNum is '||msgNum);
              fnd_file.put_line(fnd_file.Output,'msg_sub is '||msg_sub);
              fnd_file.put_line(fnd_file.Output,'msg_body is '||msg_body);
              XX_CS_MESG_PKG.send_email (sender => lc_mail_sender, recipient => lc_recipients, cc_recipient => NULL , bcc_recipient => NULL , subject => msg_sub, message_body => msg_body, p_message_type => 'INFO', IncidentNum => ln_incident_id, return_code => ln_return_code );
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lc_mail_sender := NULL;
              lc_recipients  := NULL;
              fnd_file.put_line(fnd_file.log,'Alert email is not configured');
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Error while sending Message through email '|| ln_return_code);
            END;*/
            -- Code Added For Defect# 38994 - To Print the Messages Not Updated in SR  --  Ends Here
			IF lc_translation_info.target_value9 IS NOT NULL 
			  AND lc_translation_info.target_value10 IS NOT NULL THEN
			    lc_mail_sender := lc_translation_info.target_value9;
			    lc_recipients := lc_translation_info.target_value10;
                fnd_file.put_line(fnd_file.Output,'Messages Not Updated is '||'  --  '||' msgNum is '||msgNum);
                fnd_file.put_line(fnd_file.Output,'msg_sub is '||msg_sub);
                --fnd_file.put_line(fnd_file.Output,'msg_body is '||msg_body);
				fnd_file.put_line(fnd_file.Output,'msg_body is '||SUBSTR(lc_html_data,1,32760));
                XX_CS_MESG_PKG.send_email (sender => lc_mail_sender, recipient => lc_recipients, cc_recipient => NULL , bcc_recipient => NULL , subject => msg_sub, message_body => lc_html_data, p_message_type => 'INFO', IncidentNum => ln_incident_id, return_code => ln_return_code );
			END IF;
          END IF; -- Added For Defect# 38994.
          -- Resetting our variables that store the parts of the email
          lv_return_status       := NULL; -- Added For Defect# 38994
          msg_from               := '';
          msg_to                 := '';
          msg_sub                := '';
          msg_body               := NULL;
          subject_read_indicator := 0;
          marked_for_deletion    := 0;
          hyphen_checker         := 0;
		  lc_html_data           := NULL;
          IF (msgNum             >= total_msg) THEN
            EXIT;
          END IF;
          msgNum := msgNum + 1; -- incrementing message counter var
          fnd_file.put_line(fnd_file.log,'msgnum :'|| msgnum);
        EXCEPTION
        WHEN OTHERS THEN
          msg_sub := 'Error in Message '||sqlerrm;
          --dbms_output.put_line(msg_sub);
          fnd_file.put_line(fnd_file.log,msg_sub);
          --   marked_for_deletion := 1;
          -- Delete the exception message 11/19/10
          IF (marked_for_deletion = 1) THEN
            line                 := WriteToPop('DELE ' || msgNum);
          END IF;
          -- Resetting our variables that store the parts of the email
          msg_from               := '';
          msg_to                 := '';
          msg_sub                := '';
          msg_body               := NULL;
          subject_read_indicator := 0;
          marked_for_deletion    := 0;
          hyphen_checker         := 0;
		  lc_html_data           := NULL;
          IF (msgNum             >= total_msg) THEN
            EXIT;
          END IF;
          msgNum := msgNum + 1;
          fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
          fnd_file.put_line(fnd_file.log,'msgnum in exception :'|| msgnum);
        END;
      END LOOP; -- loop through all messages
    END IF;     -- checking if (total_msg > 0)
    DBMS_OUTPUT.PUT_LINE('WO '||LC_WO_NUMBER);
    fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
    msg_sub := 'WO#'||LC_WO_NUMBER||'Action:'||LC_CHANGE_ACTION||'SKUs:'||lc_skus||'Units:'||ln_units;
    fnd_file.put_line(fnd_file.log,msg_sub);
    IF LC_WO_NUMBER IS NOT NULL THEN
      UPDATE_SMB_QTY (P_REQUEST_NUMBER => LC_WO_NUMBER, P_CUST_NAME => LC_CUST_NAME, P_ACTION => LC_CHANGE_ACTION, P_SKUs => LC_SKUS, P_UNITS => LN_UNITS);
    END IF;
    -- close connection.
    fnd_file.put_line(fnd_file.log,'*****************************************************'); -- Added for Defect#40980
    line := WriteToPop('QUIT');
    UTL_TCP.close_connection( socket );
  END IF; -- checking whether connection was made successfully
  -- Code Added For Defect# 38994 to Check Count of Messages not Updated in SR, If Greater than ZERO then Completes the Program in Warning Status  --Starts Here
  IF l_warning_cnt > 0 THEN
    fnd_file.put_line(fnd_file.log,'l_warning_cnt :'|| l_warning_cnt);
    p_result  := 1;
    p_message := 'Junk Email Found.';
  END IF;
  -- Code Added For Defect# 38994 to Check Count of Messages not Updated in SR, If Greater than ZERO then Completes the Program in Warning Status  --Ends Here
EXCEPTION
WHEN OTHERS THEN
  msg_sub := 'Error '||sqlerrm;
  dbms_output.put_line(msg_sub);
  fnd_file.put_line(fnd_file.log,msg_sub);
  UTL_TCP.close_connection( socket );
  -- Start of changes for defect# 37051
  p_result  := 2;
  p_message := msg_sub;
  -- End of changes for defect# 37051
END Read_Response;
/*******************************************************************************/
/*******************************************************************************/
PROCEDURE UPDATE_SMB_QTY(
    P_REQUEST_NUMBER IN VARCHAR2,
    P_CUST_NAME      IN VARCHAR2,
    P_ACTION         IN VARCHAR2,
    P_SKUs           IN VARCHAR2,
    P_UNITS          IN NUMBER)
IS
  ln_request_id    NUMBER;
  lc_message       VARCHAR2(250);
  lc_return_status VARCHAR2(1) := 'S';
BEGIN
  -- Select request_id
  BEGIN
    SELECT incident_id
    INTO ln_request_id
    FROM cs_incidents_all_b
    WHERE incident_number = p_request_number;
  EXCEPTION
  WHEN OTHERS THEN
    lc_return_status := 'F';
    lc_message       := 'No Data for Request '||p_request_number;
  END;
  --DBMS_OUTPUT.PUT_LINE('WO '||P_REQUEST_NUMBER||'-'||P_ACTION||'-'||P_SKUS||'- '||P_UNITS);
  IF NVL(LC_RETURN_STATUS, 'S') = 'S' THEN
    IF ln_request_id           IS NOT NULL THEN
      -- update qty
      --DBMS_OUTPUT.PUT_LINE('-'||P_ACTION||'-');
      lc_message := 'update qty '||p_action;
      fnd_file.put_line(fnd_file.log,lc_message);
      lc_message := NULL;
      IF p_action = 'Add' THEN
        BEGIN
          UPDATE xx_cs_sr_items_link
          SET quantity             = quantity + p_units
          WHERE service_request_id = ln_request_id
          AND item_number          = p_skus;
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          lc_return_status := 'F';
          lc_message       := 'error while updating '||sqlerrm;
          Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.UPDATE_SMB_QTY' ,p_error_message_code => 'XX_CS_0001_SEND_ERR' ,p_error_msg => LC_MESSAGE);
        END;
      elsif p_action = 'Delete' THEN
        BEGIN
          UPDATE xx_cs_sr_items_link
          SET quantity             = quantity - p_units
          WHERE service_request_id = ln_request_id
          AND item_number          = p_skus;
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          lc_return_status := 'F';
          lc_message       := 'error while updating '||sqlerrm;
          Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.UPDATE_SMB_QTY' ,p_error_message_code => 'XX_CS_0002_SEND_ERR' ,p_error_msg => LC_MESSAGE);
        END;
      elsif p_action = 'New' THEN
        BEGIN
          -- insert
          INSERT
          INTO xx_cs_sr_items_link
            (
              service_request_id,
              item_number,
              item_description,
              quantity,
              order_link,
              creation_date,
              created_by,
              last_update_date,
              last_updated_by,
              attribute1,
              attribute2,
              attribute3,
              attribute4,
              attribute5
            )
          SELECT SERVICE_REQUEST_ID,
            P_SKUs,
            ITEM_DESCRIPTION,
            P_UNITS,
            ORDER_LINK,
            SYSDATE,
            UID,
            SYSDATE,
            UID,
            TO_CHAR(SYSDATE,'YYYYMMDD') , -- DATE
            ATTRIBUTE2,
            ATTRIBUTE3,
            ATTRIBUTE4,
            ATTRIBUTE5
          FROM XX_CS_SR_ITEMS_LINK
          WHERE SERVICE_REQUEST_ID = LN_REQUEST_ID
          AND ATTRIBUTE2          IS NOT NULL
          AND ROWNUM               < 2;
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          lc_return_status := 'F';
          lc_message       := 'error while inserting '||sqlerrm;
          Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.UPDATE_SMB_QTY' ,p_error_message_code => 'XX_CS_0003_SEND_ERR' ,p_error_msg => LC_MESSAGE);
        END;
      END IF;
      IF NVL(LC_RETURN_STATUS, 'S') = 'S' THEN
        lc_return_status           := NULL;
        lc_message                 := NULL;
        BEGIN
          XX_CS_TDS_SR_PKG.SUB_UPDATES(P_REQUEST_ID => LN_REQUEST_ID, P_RETURN_CODE => LC_RETURN_STATUS, P_RETURN_MSG => LC_MESSAGE);
        EXCEPTION
        WHEN OTHERS THEN
          lc_return_status := 'F';
          lc_message       := 'error while CALLING UPDATE PROCEDURE '||sqlerrm;
          Log_Exception ( p_error_location => 'XX_CS_MESG_PKG.UPDATE_SMB_QTY' ,p_error_message_code => 'XX_CS_0004_SEND_ERR' ,p_error_msg => LC_MESSAGE);
        END;
      END IF;
    END IF; -- Reqest id
  END IF;   -- Return status
END UPDATE_SMB_QTY;
/******************************************************************************/
END XX_CS_MESG_PKG;
/