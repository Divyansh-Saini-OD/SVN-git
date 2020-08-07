create or replace
PACKAGE BODY XX_CS_CUSTOM_EVENT_PKG AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_CUSTOM_EVENT_PKG                                                        |
-- |                                                                                         |
-- | Description      : Customer Support Custom Event functions                              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       28-Apr08        Raj Jagarlamudi        Initial draft version                   |
-- |          20-Sep-09       Raj Jagarlamudi        Added Severity validation for Merch(MR) |
-- +=========================================================================================+

gc_err_msg      varchar2(2000);
gc_err_status   varchar2(25);
gn_msg_cnt      number;
g_user_id       number;

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
     ,p_program_type            => 'Customer Support Custom Events'
     ,p_program_name            => 'XX_CS_CUSTOM_EVENT_PKG'
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
/*******************************************************************************
   Update expire date for EC PCard attachment file
********************************************************************************/
PROCEDURE UPDATE_ATTACHMENT (P_INCIDENT_ID IN NUMBER)
IS

CURSOR sel_file_csr IS
    select lb.file_data , lb.file_id
    from   fnd_attached_documents dc,
           fnd_documents_tl dt,
           fnd_lobs lb
    where lb.file_id = dt.media_id
    and   dt.document_id = dc.document_id
    and   dc.entity_name = 'CS_INCIDENTS'
    and   dc.pk1_value = to_char(p_incident_id);
    
    l_file_rec    sel_file_csr%ROWTYPE;
    
BEGIN
    OPEN sel_file_csr;
    LOOP
    FETCH sel_file_csr INTO l_file_rec;
    EXIT when sel_file_csr%NOTFOUND;
    
      -- update file data and label.
       BEGIN
        UPDATE FND_LOBS
        SET EXPIRATION_DATE   = SYSDATE
        WHERE FILE_ID = L_FILE_REC.FILE_ID;
        
       EXCEPTION
        WHEN OTHERS THEN
          gc_err_msg    := 'error '||sqlerrm;
           Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.UPDATE_attachment'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
          gc_err_status := 'FAILED';
       END;
        
    END LOOP;
    commit;
    CLOSE sel_file_csr;
 END  UPDATE_ATTACHMENT;
/****************************************************************************************
  CS_Custom_Rule_Func
***************************************************************************************/

  FUNCTION CS_CUST_RULE_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2 AS
  
    l_event_name 	      VARCHAR2(240) := p_event.getEventName( );
    l_request_number	      VARCHAR2(64);
    l_user_id		      NUMBER;
    l_event_key		      VARCHAR2(240);
    lc_encrypted_val          varchar2(200);
    lc_decrypted_val          varchar2(200);
    ln_request_id             number;
    ln_obj_version            number;
    lx_interaction_id         NUMBER;
    lx_workflow_process_id    NUMBER;
    lx_msg_index_out          NUMBER;
    lr_service_request_rec    CS_ServiceRequest_PUB.service_request_rec_type;
    lt_notes_table            CS_SERVICEREQUEST_PUB.notes_table;
    lt_contacts_tab           CS_SERVICEREQUEST_PUB.contacts_table;  
    ln_resp_appl_id	      NUMBER;
    ln_resp_id		      NUMBER;
    lc_initiator_role         VARCHAR2(150);
    lc_sender_role            varchar2(150);
    lc_error_msg              VARCHAR2(1000);
    lc_aops_id                VARCHAR2(200);
    lc_context_val            VARCHAR2(50);
    lc_return_status          varchar2(25);
    lc_message                varchar2(1000);
    lc_subject                varchar2(250);
    ld_res_date               date;
    ld_resv_date              date;
    ln_res_hours              number;
    
    CURSOR sel_incident_csr IS
      SELECT inc.incident_type_id type_id,
             cit.name type_name,
             inc.incident_id,
             inc.creation_date,
             to_number(cit.attribute1) response_time,
             to_number(cit.attribute2) resolve_time,
             inc.customer_id,
             inc.problem_code,
             cit.attribute9,
             inc.creation_program_code prog_code,
             inc.summary,
             inc.incident_urgency_id
      FROM   cs_incidents inc,
             cs_incident_types cit
      WHERE  inc.incident_number = l_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    cit.end_date_active is null
      and    inc.creation_program_code not in ('IRECEIVABLES','GMILL');

    l_incident_rec   sel_incident_csr%ROWTYPE;

  begin
  
    -- Obtain values initialized from the parameter list.
    l_request_number := p_event.GetValueForParameter('REQUEST_NUMBER');
    l_user_id := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id := p_event.GetValueForParameter('RESP_APPL_ID'); 
    ln_resp_id := p_event.GetValueForParameter('RESP_ID');
    l_event_key := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');
    
    OPEN sel_incident_csr;
    FETCH sel_incident_csr INTO l_incident_rec;
    IF (sel_incident_csr%FOUND AND l_incident_rec.type_id IS NOT NULL ) THEN
    
        IF(l_event_name = 'oracle.apps.cs.sr.ServiceRequest.created') THEN
        
               IF l_incident_rec.customer_id is not null then 
                begin
                    select substr(orig_system_reference,1,8)
                    into lc_aops_id
                    from hz_cust_accounts
                    where party_id = l_incident_rec.customer_id;
               exception
                when others then
                    lc_aops_id := null;
                end; 
              end if;
              
            lc_context_val := NVL(l_incident_rec.attribute9,'ORDER');
            
            IF l_incident_rec.type_name like 'MR-%' THEN 
              IF l_incident_rec.incident_urgency_id = 1 then
                ln_res_hours := 4;
              else
                ln_res_hours := l_incident_rec.response_time;
              end if;
            ELSE
              ln_res_hours := l_incident_rec.response_time;
            END IF;
            
            begin
              ld_res_date := xx_cs_sr_utils_pkg.res_rev_time_cal 
                                          (p_date => l_incident_rec.creation_date,
                                          p_hours => ln_res_hours,
                                          p_cal_id => 'OD ST CAL');
            exception
              when others then
                  ld_res_date := l_incident_rec.creation_date + (ln_res_hours/24);
            end;
                 
             begin                             
                ld_resv_date := xx_cs_sr_utils_pkg.res_rev_time_cal 
                                          (p_date => l_incident_rec.creation_date,
                                          p_hours => l_incident_rec.resolve_time,
                                          p_cal_id => 'OD ST CAL');
             exception 
               when others then
                    ld_resv_date  :=   l_incident_rec.creation_date + (l_incident_rec.resolve_time/24);
             end;
            
           begin 
              update cs_incidents_all_b
              set obligation_date = ld_res_date,
                  expected_resolution_date = ld_resv_date,
                  incident_attribute_9 = lc_aops_id,
                  incident_attribute_10 = 'OD ST CAL',
                  incident_context = lc_context_val
              where incident_id = l_incident_rec.incident_id;
              return 'SUCCESS';
          exception
            when others then
                gc_err_msg := sqlerrm;
                Log_Exception ( p_error_location  =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
                return 'FAILED';
            end;
      
        END IF;  -- Event
    
    END IF; -- Type id is not null
    
    CLOSE sel_incident_csr;
    return 'SUCCESS';
  EXCEPTION
    WHEN others THEN
      IF sel_incident_csr%ISOPEN THEN
	CLOSE sel_incident_csr;
      END IF;
      WF_CORE.CONTEXT('XX_CS_CUSTOM_EVENT', 'CS_Cust_Rule_Func',
                      l_event_name , p_subscription_guid);
      WF_EVENT.setErrorInfo(p_event, 'ERROR');
       gc_err_msg := 'ERROR in custom event';
       Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                     ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                     ,p_error_msg          =>  gc_err_msg
                    );
      return 'WARNING';
  END CS_CUST_RULE_Func;
/*****************************************************************************/

FUNCTION CS_SR_STATUS_Func(p_subscription_guid in raw,
                             p_event in out nocopy WF_EVENT_T) RETURN varchar2
IS
    l_event_name 	      VARCHAR2(240) := p_event.getEventName( );
    l_request_number	      VARCHAR2(64);
    ln_user_id		      NUMBER;
    l_event_key		      VARCHAR2(240);
    ln_resp_appl_id	      NUMBER;
    ln_resp_id		      NUMBER;
    lc_initiator_role         VARCHAR2(150);
    lc_sender_role            varchar2(150);
    lc_summary                varchar2(2000);
    lc_status_flag            varchar2(1) := 'S';
    ln_status_id              number := 0;
    ln_incident_id            number ;
    ln_creator_id             number := 0;
    ln_owner_id               number := 0;
    lc_aops_id                varchar2(250);
    lc_type_name              varchar2(250);
    lc_dispute_id             varchar2(25);
    lc_credit_memo            varchar2(25);
    lc_problem_code           varchar2(25);
    -- Mail variables
    lc_sender                 VARCHAR2(250);
    ln_sender_id              NUMBER;
    lc_recipient              VARCHAR2(250); 
    lc_subject                VARCHAR2(250); 
    lc_message_body           LONG; 
    lc_mesg                   LONG ;
    lc_smtp_server            VARCHAR2(250);
    lc_return_code            NUMBER; 
    lc_mail_conn              utl_smtp.connection; 
    crlf                      VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 ); 
    v_mail_reply              utl_smtp.reply; 
    lc_url                    varchar2(2000);
    lc_source                 varchar2(25);
    lc_type_email             varchar2(150);
    
BEGIN
    -- Obtain values initialized from the parameter list.
    l_request_number  := p_event.GetValueForParameter('REQUEST_NUMBER');
    ln_user_id         := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID'); 
    ln_resp_id        := p_event.GetValueForParameter('RESP_ID');
    l_event_key       := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');
    lc_summary        := p_event.GetValueForParameter('PREV_SUMMARY');

    begin
      select fnd_profile.value('XX_CS_SMTP_SERVER') 
      into lc_smtp_server
      from dual;
    exception
      when others then
         lc_smtp_server := 'USCHMSX83.na.odcorp.net';
    end;
    
    begin
      select inc.incident_status_id, 
             decode(fn.user_name,'CS_ADMIN',inc.incident_attribute_4,inc.created_by),
             inc.incident_owner_id,
             inc.incident_attribute_9,
             inc.incident_attribute_12 dispute_id,
             inc.incident_attribute_13 credit_memo,
             cit.name,
             inc.incident_id,
             inc.problem_code,
             cit.attribute10
      into   ln_status_id,
             ln_creator_id,
             ln_owner_id,
             lc_aops_id,
             lc_dispute_id,
             lc_credit_memo,
             lc_type_name,
             ln_incident_id,
             lc_problem_code,
             lc_type_email
      from   cs_incidents inc,
             cs_incident_types cit,
             fnd_user fn
      where  fn.user_id = inc.created_by
      and    inc.incident_type_id = cit.incident_type_id
      and    inc.incident_number = l_request_number;
    exception
      when others then
          ln_status_id   := 0;
          lc_status_flag := 'E';
          gc_err_msg := 'Error while incident '||sqlerrm;
          return 'FAILED';
      end;   
      
   If ln_status_id = 2 then
        -- IF Type EC Pcard then update expired date for file if exists
        IF lc_type_name = 'EC Pcard Program' THEN
            -- CALL PROECDURE
            update_attachment(ln_incident_id);
        END IF;
         IF lc_type_name IN ('NA Credit Dispute','BSD Credit Dispute') THEN
          lc_subject := ' for Dispute# '||lc_dispute_id;
         else
           lc_subject := 'SR# '||L_REQUEST_NUMBER||' is closed';  
         end if;
         
        -- Select creator mail id
        begin
          select source_email 
          into lc_recipient
          from jtf_rs_resource_extns
          where user_id = ln_creator_id;
        exception
          when others then
           lc_status_flag := 'E';
           gc_err_msg := 'Error while selecting email id '||sqlerrm;
           return 'FAILED';
        end;
        --Select owner mail id
        IF ln_owner_id <> 0 THEN
           begin
            select source_email, user_id
            into lc_sender, ln_sender_id
            from jtf_rs_resource_extns
            where resource_id = ln_owner_id;
           exception
             when others then
                lc_sender := null;
            END;
        else
          begin
            select email_address, orig_system_id
            into lc_sender, ln_sender_id
            from wf_roles
            where name = lc_sender_role; --lc_initiator_role;
          exception
            when others then
              lc_sender := null;
           end;
         end if;
         IF lc_sender is null then
            lc_sender := 'Customer Support';
         end if; 
    
   -- Send mail 
   IF lc_status_flag = 'S' then
  
       IF lc_type_name IN ('NA Credit Dispute','BSD Credit Dispute') THEN
         
          begin
           select XX_IREC_CREDIT_MEMO_PKG.CURRENT_NOTIFICATION_URL(lc_dispute_id) 
           into lc_url
           from dual; 
          exception
            when others then
              lc_url := null;
          end;
          
            IF lc_credit_memo is not null then
              lc_message_body := 'AOPS Credit Memo# '||lc_credit_memo || '  is issued for Dispute#'||lc_dispute_id||'.  Please refere the SR# '||L_REQUEST_NUMBER ||' for more details. ';
            else
              -- Get reason from notes
              begin
                    select to_char(decode(csn.is_detail,'Y', jtn.notes_detail, csn.note)) note_details
                    into lc_message_body
                    from apps.cs_sr_notes_v csn,
                         apps.jtf_notes_tl jtn
                    where jtn.jtf_note_id = csn.id
                    and   csn.incident_id = ln_incident_id
                    and   csn.note_status <> 'P'
                    and   csn.last_update_date = (select max(last_update_date) from apps.cs_sr_notes_v
                                    where incident_id = ln_incident_id);

              exception
                when others then
                    lc_message_body := 'AOPS Credit Memo is not issued for Dispute#'||lc_dispute_id||'.  Please refere the SR# '||L_REQUEST_NUMBER ||' for more details. ';
              end;
              
            end if;
           
               lc_source := 'Closed';
              begin
                   xx_cs_mesg_pkg.send_notification ( 
                                p_sr_number      => l_request_number,
                                p_sr_id          => ln_incident_id,
                                p_from_id	 => ln_sender_id,
                                p_to_id 	 => ln_creator_id,
                                p_user_id 	 => ln_user_id,
                                p_message	 => lc_message_body,
                                p_url_link       => lc_url,
                                p_subject        => lc_subject,
                                p_source         => lc_source,
                                x_return_status  => lc_status_flag,
                                x_return_msg     => gc_err_msg );
                                
                    IF NVL(lc_status_flag,'S') <> 'S' THEN
                        Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                        ,p_error_msg          =>  gc_err_msg);
                    END IF;
                  exception
                    when others then
                        Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                        ,p_error_msg          =>  gc_err_msg);
                         return 'ERROR';
                   end;
            else  -- if not Credit dispute.
            
             IF LC_AOPS_ID IS NOT NULL THEN
                lc_message_body := 'SR# '||L_REQUEST_NUMBER ||' closed for Customer#'||lc_aops_id||'. Primary issue is '||lc_summary;
             ELSE
                lc_message_body := 'SR# '||L_REQUEST_NUMBER ||' closed. Primary issue is '||lc_summary;
             END IF;
             
                IF lc_sender <> lc_recipient then
                    if lc_type_email is not null then
                       lc_sender := lc_type_email;
                    end if;
                    
                      begin
                       lc_mail_conn  := utl_smtp.open_connection(lc_smtp_server, 25); 
                       lc_mesg       := 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf || 
                       'From: <'||lc_sender||'>' || crlf || 
                       'Subject: '||lc_subject || crlf || 
                       'To: '||lc_recipient || crlf || crlf || 
                        lc_message_body; 
                        utl_smtp.helo(lc_mail_conn, lc_smtp_server); 
                        utl_smtp.mail(lc_mail_conn, lc_sender); 
                        utl_smtp.rcpt(lc_mail_conn, lc_recipient); 
                        utl_smtp.data(lc_mail_conn, lc_mesg); 
                        utl_smtp.quit(lc_mail_conn); 
                     end;
                    end if;
           end if;  -- Type Checking.
         return 'SUCCESS';
   else
            Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                           ,p_error_msg          =>  gc_err_msg
                            );
            return 'FAILED';  
                 
   end if;
ELSE
   IF lc_problem_code in ('BT', 'FRE', 'PRC') then
     BEGIN
        XX_CS_DISPUTE_SR_PKG.UPDATE_SR (P_REQUEST_ID  => ln_incident_id,
                                        P_NOTES       => 'Acct. Manager Approved the request',
                                        X_RETURN_STATUS  => lc_status_flag,
                                        X_MSG_DATA       => gc_err_msg);
      EXCEPTION
        WHEN OTHERS THEN
            GC_ERR_MSG  := 'Error while updating Dispute SR ID : '|| ln_incident_id||' '||sqlerrm;
             Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                           ,p_error_msg          =>  gc_err_msg
                            );
      END;
      
   END IF;
    return 'SUCCESS';
END IF; -- Close Status
    
END CS_SR_STATUS_Func;
/*******************************************************************************
********************************************************************************/
FUNCTION CS_SR_TASK_WF(p_subscription_guid in raw,
                       p_event in out nocopy WF_EVENT_T) RETURN varchar2 AS
 
   l_incident_id            NUMBER ;
   l_user_id                NUMBER := null ;
   l_audit_id		    NUMBER ;
   l_return_status          varchar2(200);
   l_sr_return_status       varchar2(1);
   l_task_return_status     varchar2(1);
   l_msg_count 	 	    NUMBER ;
   l_msg_data   	    VARCHAR2(2000) ;
   l_msg_index_out          NUMBER;
   ln_resp_appl_id	    NUMBER;
   ln_resp_id		    NUMBER;
   lc_error_msg             VARCHAR2(1000);
   ln_obj_ver               NUMBER;
   lc_comments              varchar2(1000);
   ln_status_id             number;
   lc_status                varchar2(25);
   x_interaction_id         NUMBER; 
   l_owner_id               NUMBER;
   l_owner_type_code        varchar2(150);
   l_assignee_id            NUMBER;
   l_assignee_type_code     varchar2(150);
   l_task_type_id           number;
   l_process	            varchar2(100);
   
   cursor c_task( b_task_id number ) is
    select
      source_object_type_code
    , source_object_id
    , created_by
    , owner_id
    , owner_type_code
    , task_type_id
    from
      jtf_tasks_b
    where task_id = b_task_id
    and  source_object_type_code = 'SR';

  l_send_date               constant date := p_event.send_date;
  l_event_name              constant varchar2(240) := p_event.event_name;
  l_task_id                 constant number := p_event.GetValueForParameter('TASK_ID');
  l_task_assignment_id      constant number := p_event.GetValueForParameter('TASK_ASSIGNMENT_ID');
  l_assignee_role           constant varchar2(30) := p_event.GetValueForParameter('ASSIGNEE_ROLE');

  l_source_object_type_code varchar2(60);
  l_source_object_id        number;

begin
    
   If l_assignee_role = 'ASSIGNEE' then
   
    open c_task( l_task_id );
    fetch c_task into l_source_object_type_code, l_source_object_id, l_user_id,
                      l_owner_id, l_owner_type_code, l_task_type_id;
    if c_task%found then
    
    begin
      select resource_id, resource_type_code 
      into l_assignee_id, l_assignee_type_code
      from jtf_task_assignments
      where task_id = l_task_id
      and   task_assignment_id = l_task_assignment_id;
    exception
     when others then
       l_assignee_id        := null;
       l_assignee_type_code := null;
    end;  
    
  --  insert into xx_cs_process_test
    --values ('task# '||l_task_id||'Assin# '||l_task_assignment_id||' Assignee# '||l_assignee_id);
    
        IF ((l_source_object_type_code = 'SR') AND (l_source_object_id IS NOT NULL ) ) THEN
          
           -- Get Object version

                BEGIN
                 SELECT object_version_number
                 INTO   ln_obj_ver
                 FROM   cs_incidents_all_b
                 WHERE  incident_id = l_source_object_id;
                EXCEPTION
                  WHEN OTHERS THEN
                     ln_obj_ver := NULL;
                END;  
               /*********************************************************************
                 -- Get status id
                *********************************************************************/
                begin 
                  select incident_status_id, name
                  into ln_status_id, lc_status
                  from CS_INCIDENT_STATUSES_VL 
                  where name = 'Waiting';
                exception
                when others then
                   ln_status_id := null;
                end;
       
                /***********************************************************************
                 -- Update SR
                 ***********************************************************************/
                  IF ln_status_id IS NOT NULL then
                    CS_SERVICEREQUEST_PUB.Update_Status
                        ( p_api_version		=> 2.0,
                          p_init_msg_list	=> FND_API.G_TRUE,
                          p_commit		=> FND_API.G_FALSE,
                          x_return_status	=> l_sr_return_status,
                          x_msg_count	        => l_msg_count,
                          x_msg_data		=> l_msg_data,
                          p_resp_appl_id	=> ln_resp_appl_id,
                          p_resp_id		=> ln_resp_id,
                          p_user_id		=> l_user_id,
                          p_login_id		=> NULL,
                          p_request_id		=> l_source_object_id,
                          p_request_number	=> NULL,
                          p_object_version_number   => ln_obj_ver,
                          p_status_id	 	=> ln_status_id,
                          p_status		=> lc_status,
                          p_closed_date		=> SYSDATE,
                          p_audit_comments	=> NULL,
                          p_called_by_workflow	=> NULL,
                          p_workflow_process_id	=> NULL,
                          p_comments		=> NULL,
                          p_public_comment_flag	=> NULL,
                          x_interaction_id	=> x_interaction_id );
                   END IF;  -- Status
                                  
                if (l_sr_return_status <> FND_API.G_RET_STS_SUCCESS) then
                    return 'WARNING';
		end if;

                jtf_task_wf_util.create_notification
                        (
                          p_event 		      	=> 'ADD_ASSIGNEE',
                          p_task_id                  	=> l_task_id,
                          p_old_owner_id             	=> l_owner_id,
                          p_old_owner_code           	=> l_owner_type_code,
                          p_old_assignee_id		=> l_assignee_id,	
                          p_old_assignee_code		=> l_assignee_type_code,		
                          p_new_assignee_id		=> l_assignee_id,
                          p_new_assignee_code		=> l_assignee_type_code,
                          x_return_status              => l_return_status,
                          x_msg_count                  => l_msg_count,
                          x_msg_data                   => l_msg_data
                        ); 

                -- Check WF notification errors
                    gc_err_msg := 'Create Notification for task#'  ||l_task_id||' Status '||l_task_return_status;
                      Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_TASK_WF'
                     ,p_error_message_code =>   'XX_CS_EVENT_SUCCESS_LOG'
                     ,p_error_msg          =>  gc_err_msg
                    ); 
              
                
        END IF;  -- SR object Code and Object Id check
     end if; -- Task cursor
     close c_task;
    end if; -- Assignee
    return 'SUCCESS';
  exception
	when others then
		wf_core.context('XX_CS_CUSTOM_EVENT','CS_SR_TASK_WF',
					p_event.getEventName(),p_subscription_guid);
		wf_event.setErrorInfo(p_event,'WARNING');
	return 'ERROR';
END CS_SR_TASK_WF;
/*******************************************************************************/
 FUNCTION CS_SR_OWNER_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2
AS
        L_EVENT_NAME              varchar2(240);
	L_EVENT_KEY               varchar2(240);
	l_incident_number         cs_incidents_all_b.incident_number%type;
	l_incident_id             cs_incidents_all_b.incident_id%type;
	lc_responsibility_id       varchar2(80);
	lc_responsibility_appl_id  varchar2(30);
	l_incident_date           date;
	lc_return_status           varchar2(240);
	l_incident_status_id      cs_incidents_all_b.incident_status_id%type;
	l_service_rec             cs_servicerequest_pub.service_request_rec_type;
	ln_sr_user_id              number;
	ln_sr_resp_id              number;
	ln_sr_resp_appl_id         number;
	ln_sr_api_version          number;
	lc_sr_return_status        varchar2(1);
	ln_sr_msg_count            number;
	lc_sr_msg_data             varchar2(2000);
        ln_sr_msg_index_out        number;
	ln_prev_type_id            number;
	ln_prev_owner_id           number;
        ln_prev_status_id          number;
        ln_dispute_id              number;
        lc_subject                 varchar2(250);
        lc_msg                     varchar2(2000);
        ln_owner_id                number;
        lc_owner_name              varchar2(250);
        ln_group_id                number;
        lc_created_by              varchar2(100);
        lc_resource_type           varchar2(100);
        ln_sr_type_id              number;
        lc_sr_problem_code         varchar2(250);
        lr_TerrServReq_Rec        XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
        lt_TerrResource_tbl       JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
        lc_maintenance_flag        varchar2(1);
        lc_url                     varchar2(2000);
        lc_exsit_flag              varchar2(1) := 'N';
begin

   	-- get the service request number from the event message
  	l_incident_number := wf_event.getValueForParameter('REQUEST_NUMBER',p_event.Parameter_List);
   	ln_sr_user_id	  := wf_event.getValueForParameter('USER_ID',p_event.Parameter_List);
   	ln_sr_resp_id      := wf_event.getValueForParameter('RESP_ID',p_event.Parameter_List);
	ln_sr_resp_appl_id := wf_event.getValueForParameter('RESP_APPL_ID',p_event.Parameter_List);
   	ln_prev_type_id    := wf_event.getValueForParameter('PREV_TYPE_ID',p_event.Parameter_List);
   	ln_prev_status_id  := wf_event.getValueForParameter('PREV_STATUS_ID',p_event.Parameter_List);
   	ln_prev_owner_id   := wf_event.getValueForParameter('PREV_OWNER_ID',p_event.Parameter_List); 
                    
        IF ln_prev_type_id is not null then
              -- get the service request id and service request type
            begin
              select cia.incident_id,cia.incident_date, cia.incident_type_id,
                    cia.problem_code, nvl(cia.incident_owner_id,ln_prev_owner_id)
              into l_incident_id,l_incident_date, ln_sr_type_id, 
                    lc_sr_problem_code, ln_owner_id
              from cs_incidents_vl_sec cia, cs_incident_types_vl_sec cit
              where cia.incident_number = l_incident_number
              and cia.incident_type_id = cit.incident_type_id
              and cit.name like 'ECR%';
            exception
              when others then
                 l_incident_id := null;
                 ln_sr_type_id  := null;
            end;
            
            IF l_incident_id is not null then
            -- Request Type Change
              IF ln_sr_type_id <> ln_prev_type_id THEN
                lc_maintenance_flag := 'Y';
              end if;
           end if;
          
              -- if service request type is maintenance, then proceed  else terminate
              If (nvl(lc_maintenance_flag,'N') = 'Y') then 
                      -- Select new group id
                  /************************************************************************
                        -- Get Resources
                   *************************************************************************/
                    lr_TerrServReq_Rec.service_request_id   := l_incident_id;
                    lr_TerrServReq_Rec.incident_type_id     := ln_sr_type_id;
                    lr_TerrServReq_Rec.problem_code         := lc_sr_problem_code;
                                
                    /*************************************************************************************************************/
                    XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
                                  p_init_msg_list      => FND_API.G_TRUE,
                                  p_TerrServReq_Rec    => lr_TerrServReq_Rec,
                                  p_Resource_Type      => NULL,
                                  p_Role               => null,
                                  x_return_status      => lc_return_status,
                                  x_msg_count          => ln_sr_msg_count,
                                  x_msg_data           => lc_sr_msg_data,
                                  x_TerrResource_tbl   => lt_TerrResource_tbl);
                      
                                 -- Check errors
                              IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) then
                                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                                --Display all the error messages
                                  FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                          FND_MSG_PUB.Get(
                                                    p_msg_index => j,
                                                    p_encoded => 'F',
                                                    p_data => lc_sr_msg_data,
                                                    p_msg_index_out => ln_sr_msg_index_out);
                                  END LOOP;
                                ELSE
                                            --Only one error
                                        FND_MSG_PUB.Get(
                                                    p_msg_index => 1,
                                                    p_encoded => 'F',
                                                    p_data => lc_sr_msg_data,
                                                    p_msg_index_out => ln_sr_msg_index_out);
                                END IF;
                                   gc_err_msg := lc_sr_msg_data;
                                    Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                                ,p_error_msg          =>  gc_err_msg
                                                );
                              END IF; 
                              
                          /****************************************************************************/
                             IF lt_TerrResource_tbl.count > 0 THEN
                              -- dbms_output.put_line('owner_group_id '||lt_TerrResource_tbl(1).resource_id);
                               
                                  ln_group_id       := lt_TerrResource_tbl(1).resource_id;
                                  lc_resource_type     := lt_TerrResource_tbl(1).resource_type;
                                end if;    
                                
                            /***********************************************************************
                                   -- Update SR
                            ***********************************************************************/
                               begin 
                                  update cs_incidents_all_b
                                  set owner_group_id = ln_group_id,
                                       incident_owner_id = ln_owner_id
                                  where incident_id = l_incident_id;
                                  return 'SUCCESS';
                              exception
                                when others then
                                    gc_err_msg := sqlerrm;
                                    Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                                ,p_error_msg          =>  gc_err_msg
                                                );
                                    return 'ERROR';
                                end;           
			   end if;      
   	end if;  
          
        -- Send owner update notification to DRT 
        IF ln_prev_owner_id is null
           and (ln_prev_status_id is null or ln_prev_status_id = 1) then
            
           begin
              select cia.incident_id, cia.incident_owner_id,
                     cia.incident_attribute_4,
                     cia.incident_attribute_12
              into   l_incident_id,ln_owner_id, lc_created_by, ln_dispute_id
              from cs_incidents_vl_sec cia, cs_incident_types_vl_sec cit
              where cia.incident_number = l_incident_number
              and cia.incident_type_id = cit.incident_type_id
              and cit.name IN ('NA Credit Dispute','BSD Credit Dispute');
            exception
              when others then
                 ln_owner_id     := null;
                 lc_created_by   := null;
            end;
            begin
               select 'Y' 
               into lc_exsit_flag
               from cs_messages
               where source_object_int_id = l_incident_id
               and   rownum < 2;
            exception
              when others then
                lc_exsit_flag := 'N';
            end;
            
            If (ln_owner_id is not null and lc_exsit_flag = 'N' ) then
               begin
                  select source_name, user_id
                  into   lc_owner_name, ln_sr_user_id
                  from jtf_rs_resource_extns
                  where resource_id = ln_owner_id;
               exception
                 when others then
                   ln_sr_user_id := null;
              end;
              lc_msg := 'Owner: '||lc_owner_name ||' assigned to SR# '||l_incident_number||' for Dispute# '||ln_dispute_id;
              lc_subject := ' for Dispute# '||ln_dispute_id;
              
             begin
               select XX_IREC_CREDIT_MEMO_PKG.CURRENT_NOTIFICATION_URL(ln_dispute_id) 
               into lc_url
               from dual;
              exception
                when others then
                  lc_url := null;
              end; 
              
              
                begin
                   xx_cs_mesg_pkg.send_notification ( 
                                p_sr_number      => l_incident_number,
                                p_sr_id          => l_incident_id,
                                p_from_id	 => ln_sr_user_id,
                                p_to_id 	 => to_number(lc_created_by),
                                p_user_id 	 => ln_sr_user_id,
                                p_message	 => lc_msg, 
                                p_url_link       => lc_url,
                                p_subject        => lc_subject,
                                p_source         => 'OWNER',
                                x_return_status  => lc_return_status,
                                x_return_msg     => lc_sr_msg_data );
                                
                    IF NVL(lc_return_status,'S') <> 'S' THEN
                        gc_err_msg := lc_sr_msg_data;
                         Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                        ,p_error_msg          =>  gc_err_msg);
                    END IF;
                  exception
                    when others then
                        gc_err_msg := sqlerrm;
                         Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                        ,p_error_msg          =>  gc_err_msg);
                         return 'ERROR';
                   end;           

               end if;  -- Owner
            end if;   -- Previous Owner
         
        return 'SUCCESS';
    exception
	when others then
		wf_core.context('XX_CS_CUSTOM_EVENT_PKG','service_request_updated',
					p_event.getEventName(),p_subscription_guid);
		wf_event.setErrorInfo(p_event,'ERROR');
	return 'ERROR';
  END;
/********************************************************************************/
END XX_CS_CUSTOM_EVENT_PKG;
/
SHOW ERRORS;
EXIT;