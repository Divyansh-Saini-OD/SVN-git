SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TASK_WF_PKG                                        |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-Mar-08   Raj Jagarlamudi  Initial draft version       |
-- |1.1       13-Jun-08   Raj Jagarlamudi  EC functionality added for  |
-- | 						all groups             |
---+===================================================================+

CREATE OR REPLACE
PACKAGE BODY XX_CS_TASK_WF_PKG AS

/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_task_id               in number,
                       p_task_notes_rec       in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2)
IS

ln_api_version		number;
lc_init_msg_list	varchar2(1);
ln_validation_level	number;
lc_commit		varchar2(1);
lc_return_status	varchar2(1);
ln_msg_count		number;
lc_msg_data		varchar2(2000);
ln_jtf_note_id		number;
ln_source_object_id	number;
lc_source_object_code	varchar2(8);
lc_note_status          varchar2(8);
lc_note_type		varchar2(80);
lc_notes		varchar2(2000);
lc_notes_detail		varchar2(8000);
ld_last_update_date	Date;
ln_last_updated_by	number;
ld_creation_date	Date;
ln_created_by		number;
ln_entered_by           number;
ld_entered_date         date;
ln_last_update_login    number;
lt_note_contexts	JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
ln_msg_index		number;
ln_msg_index_out	number;

begin
/************************************************************************
--Initialize the Notes parameter to create
**************************************************************************/
ln_api_version			:= 1.0;
lc_init_msg_list		:= FND_API.g_true;
ln_validation_level		:= FND_API.g_valid_level_full;
lc_commit			:= FND_API.g_true;
ln_msg_count			:= 0;
/****************************************************************************
-- If ObjectCode is Party then Object_id is party id
-- If ObjectCode is Service Request then Object_id is Service Request ID
-- If ObjectCode is TASK then Object_id is Task id
****************************************************************************/
ln_source_object_id		:= p_task_id;
lc_source_object_code		:= 'TASK';
lc_note_status			:= 'I';  -- (P-Private, E-Publish, I-Public)
lc_note_type			:= 'GENERAL';
lc_notes			:= p_task_notes_rec.notes;
lc_notes_detail			:= p_task_notes_rec.note_details;
ln_entered_by			:= FND_GLOBAL.user_id;
ld_entered_date			:= SYSDATE;
/****************************************************************************
-- Initialize who columns
*****************************************************************************/
ld_last_update_date		:= SYSDATE;
ln_last_updated_by		:= FND_GLOBAL.USER_ID;
ld_creation_date		:= SYSDATE;
ln_created_by			:= FND_GLOBAL.USER_ID;
ln_last_update_login		:= FND_GLOBAL.LOGIN_ID;
/******************************************************************************
-- Call Create Note API
*******************************************************************************/
JTF_NOTES_PUB.create_note (p_api_version        => ln_api_version,
                 	p_init_msg_list         => lc_init_msg_list,
                   	p_commit                => lc_commit,
                   	p_validation_level      => ln_validation_level,
                  	x_return_status         => lc_return_status,
                  	x_msg_count             => ln_msg_count ,
                  	x_msg_data              => lc_msg_data,
                  	p_jtf_note_id	        => ln_jtf_note_id,
                  	p_entered_by            => ln_entered_by,
                  	p_entered_date          => ld_entered_date,
			p_source_object_id	=> ln_source_object_id,
			p_source_object_code	=> lc_source_object_code,
			p_notes			=> lc_notes,
			p_notes_detail		=> lc_notes_detail,
			p_note_type		=> lc_note_type,
			p_note_status		=> lc_note_status,
			p_jtf_note_contexts_tab => lt_note_contexts,
			x_jtf_note_id		=> ln_jtf_note_id,
			p_last_update_date	=> ld_last_update_date,
			p_last_updated_by	=> ln_last_updated_by,
			p_creation_date		=> ld_creation_date,
			p_created_by		=> ln_created_by,
			p_last_update_login	=> ln_last_update_login );

    -- check for errors
      IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) then
          IF (FND_MSG_PUB.Count_Msg > 1) THEN
          --Display all the error messages
            FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                    FND_MSG_PUB.Get(
                              p_msg_index => j,
                              p_encoded => 'F',
                              p_data => lc_msg_data,
                              p_msg_index_out => ln_msg_index_out);

                  DBMS_OUTPUT.PUT_LINE(lc_msg_data);
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lc_msg_data,
                              p_msg_index_out => ln_msg_index_out);
                  DBMS_OUTPUT.PUT_LINE(lc_msg_data);
                  DBMS_OUTPUT.PUT_LINE(ln_msg_index_out);
          END IF;
      END IF;
      p_msg_data          := lc_msg_data;
      p_return_status     := lc_return_status;

END CREATE_NOTE;
  
/******************************************************************************
  -- Update Task
*******************************************************************************/
PROCEDURE Update_Task ( itemtype      VARCHAR2,
                        itemkey       VARCHAR2,
                        actid         NUMBER,
                        funmode       VARCHAR2,
                        result    OUT NOCOPY VARCHAR2 ) AS

ln_task_id          number;
ln_task_number      number;
lc_success          varchar2(50);
ln_msg_count        number;
lc_msg_data         varchar2(50);
ln_task_status_id   number;
ln_obj_ver          number;
lc_response         varchar2(25);
lr_task_notes       XX_CS_SR_NOTES_REC;
lc_note_message     varchar2(2000);
x_return_status     varchar2(200);
x_msg_data          varchar2(200);
ln_sr_request_id    number;
lc_assignee_name    varchar2(200);
lc_task_type_name    varchar2(200);
ln_status_id        number;
lc_status           varchar2(100);
BEGIN
 IF (funmode = 'RUN') THEN
 
 -- lc_response          := WF_ENGINE.GetItemAttrText( itemtype => itemtype,itemkey => itemkey,aname => 'BLK_RESULT');
  ln_task_number      := WF_ENGINE.GetItemAttrText( itemtype => itemtype,itemkey => itemkey,aname => 'TASK_NUMBER');
  lc_task_type_name := wf_engine.getitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'TASK_TYPE_NAME');
      
  ln_task_status_id   := 11;  --Close Status 
 
  BEGIN 
    SELECT TASK_ID, 
           OBJECT_VERSION_NUMBER,
           SOURCE_OBJECT_ID
    INTO LN_TASK_ID, LN_OBJ_VER, Ln_SR_REQUEST_ID
    FROM JTF_TASKS_VL
    WHERE TO_NUMBER(TASK_NUMBER) = LN_TASK_NUMBER;
  EXCEPTION
    WHEN OTHERS THEN
      LN_TASK_ID := NULL;
  END;
  
  -- Update Task status with 'Accepted' 
  --IF lc_response = 'RECEIVED' then 
   jtf_tasks_pub.update_task 
    ( p_object_version_number => ln_obj_ver 
      ,p_api_version          => 1.0 
      ,p_init_msg_list        => fnd_api.g_true 
      ,p_commit               => fnd_api.g_false 
      ,p_task_id              => ln_task_id
      ,x_return_status        => lc_success
      ,x_msg_count            => ln_msg_count 
      ,x_msg_data             => lc_msg_data 
      ,p_task_status_id       => ln_task_status_id);  
  --END if;
  
    /************************************
       -- Get message
    *************************************/
    begin
     select wnar.attribute_value, wnar.recipient_role_display_name 
     into lc_note_message, lc_assignee_name
      from wf_notifications wn
          , wf_notification_attr_resp_v wnar
      where 1=1
      and wn.message_type = itemtype 
      and wn.item_key = itemkey
      and wn.group_id = wnar.group_id
      and wnar.attribute_name = 'BLK_RESPONSE_NOTE';
    exception
      when others then
          lc_note_message := null;
    end;
    
     If lc_note_message is not null then
      lr_task_notes := XX_CS_SR_NOTES_REC(null,null,null,null);
      lr_task_notes.notes          := ' Response from '||lc_assignee_name;
      lr_task_notes.note_details   := lc_note_message;
      lr_task_notes.created_by     := uid;
      lr_task_notes.creation_date  := sysdate;
     end if;
     
      IF lr_task_notes.notes is not null
          and nvl(x_return_status,'S') = 'S' then
          
         CREATE_NOTE(p_task_id          => ln_task_id,
                    p_task_notes_rec    => lr_task_notes,
                    p_return_status     => x_return_status,
                    p_msg_data          => x_msg_data);
     
      end if;
      
      commit;
      /********************************************************************
      -- Service Request update
      ********************************************************************/
      begin 
        select incident_status_id, name
        into ln_status_id, lc_status
        from CS_INCIDENT_STATUSES_VL 
        where name = 'Respond';
      exception
      when others then
         ln_status_id := null;
      end;
      
        if ln_status_id is not null then
          Update_SR_status(p_sr_request_id    => ln_sr_request_id,
                          p_user_id         => uid,
                          p_status_id       => ln_status_id,
                          p_status          => lc_status,
                          x_return_status   => x_return_status,
                          x_msg_data        => x_msg_data);
        end if;
  
    result := 'COMPLETE';
    
  ELSIF (funmode = 'CANCEL') THEN
    result := 'COMPLETE';
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
    WF_CORE.Context('XX_CS_SR_WF_PKG', 'Update_Task',itemtype, itemkey, actid, funmode);
    RAISE;
  NULL;
END UPDATE_TASK;

/***************************************************************************
  -- Update SR status
*****************************************************************************/
Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status_id         in number,
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
    -- Get Object version
    *********************************************************************/
     SELECT object_version_number
     INTO ln_obj_ver
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_sr_request_id;
     
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
              p_status_id	 	=> p_status_id,
              p_status		        => p_status,
              p_closed_date		=> SYSDATE,
              p_audit_comments	        => NULL,
              p_called_by_workflow	=> NULL,
              p_workflow_process_id	=> NULL,
              p_comments		=> NULL,
              p_public_comment_flag	=> NULL,
              x_interaction_id	        => x_interaction_id );

   -- DBMS_OUTPUT.PUT_LINE('Before update note '||x_return_status);
    -- Check errors

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


    COMMIT;

END Update_SR_Status;

END XX_CS_TASK_WF_PKG;

/
show errors;
exit;
