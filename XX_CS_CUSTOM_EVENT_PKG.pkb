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
-- |          05-JAN-10       Raj Jagarlamudi        Added store portal validations          |
-- |          01-NOV-12       Raj Jagarlamudi        MPS events added                        |
-- |2.0       19-Jun-13       Arun Gannarapu         Made changes to pass p_auto_assign = Y  |
-- |                                                 for updat SR API .Replaced the direct   /
--                                                   table update with Oracle API Call in    /
--                                                    CS_SR_OWNER_Func 
--/           09-Jul-13      Arun Gannarapu          Made changes to fnd_documents_tl qry   /
-- |3.0       28-JAN-2016    Vasu Raparla            Removed Schema References for R.12.2    |
-- +=========================================================================================+

gc_err_msg      varchar2(2000);
gc_err_status   varchar2(25);
gn_msg_cnt      number;
g_user_id       number;
ln_party_id     number;

PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
  lc_log_flag  varchar2(1)           := fnd_profile.value('XX_CS_LOG_FLAG');
BEGIN
  
  IF p_error_message_code like '%LOG' THEN
    IF nvl(lc_log_flag,'N') = 'Y' THEN
       LC_LOG_FLAG := 'Y';
    ELSE
        LC_LOG_FLAG := 'N';
    END IF;
  ELSE 
     LC_LOG_FLAG := 'Y';
  END IF;
  
  IF nvl(lc_log_flag,'N') = 'Y' then
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
  end if;
END Log_Exception;
/*******************************************************************************
   Update expire date for EC PCard attachment file
********************************************************************************/
PROCEDURE UPDATE_ATTACHMENT (P_INCIDENT_ID IN NUMBER)
IS

CURSOR sel_file_csr IS
    select lb.file_data , lb.file_id
    from   fnd_attached_documents dc,
           fnd_documents dt,
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
                          ,p_error_msg          =>  gc_err_msg);
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

    l_event_name                 VARCHAR2(240) := p_event.getEventName( );
    l_request_number            VARCHAR2(64);
    l_user_id                      NUMBER;
    l_event_key                    VARCHAR2(240);
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
    ln_resp_appl_id              NUMBER;
    ln_resp_id                    NUMBER;
    lc_initiator_role         VARCHAR2(150);
    lc_sender_role            varchar2(150);
    lc_error_msg              VARCHAR2(1000);
    lc_aops_id                VARCHAR2(200);
    lc_context_val            VARCHAR2(50);
    lc_return_status          varchar2(25);
    lc_message                varchar2(1000);
    lc_subject                varchar2(250);
    lc_recipient              varchar2(250);
    lc_sender                 varchar2(250);
    ld_res_date               date;
    ld_resv_date              date;
    ln_res_hours              number;
    lc_smtp_server            VARCHAR2(250);
    lc_mail_conn              utl_smtp.connection;
    crlf                      VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
    v_mail_reply              utl_smtp.reply;
    lc_message_body           LONG;
    lc_mesg                   LONG ;
    lc_problem_code           varchar2(250);
    lc_res_check_flag         varchar2(1)       := 'N';
    lc_status_flag            varchar2(1)       := 'S';
    ln_status_id              number ;
    lc_ext_context_val        Varchar2(50);
    lc_project_number         varchar2(50);
      
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
             inc.incident_urgency_id,
             inc.creation_program_code
      FROM   cs_incidents inc,
             cs_incident_types cit
      WHERE  inc.incident_number = l_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    cit.end_date_active is null
      and    inc.creation_program_code <> 'AOPS';

    l_incident_rec   sel_incident_csr%ROWTYPE;

  begin

    -- Obtain values initialized from the parameter list.
    l_request_number  := p_event.GetValueForParameter('REQUEST_NUMBER');
    l_user_id         := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID');
    ln_resp_id        := p_event.GetValueForParameter('RESP_ID');
    l_event_key       := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');
                              
    OPEN sel_incident_csr;
    FETCH sel_incident_csr INTO l_incident_rec;
    
    gc_err_msg := 'NUMBER '||l_request_number;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                           ,p_error_message_code =>   'XX_CS_0001_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                          ); 
                          
    lc_problem_code := l_incident_rec.problem_code;
    
    IF (sel_incident_csr%FOUND AND l_incident_rec.type_id IS NOT NULL ) THEN

     IF(l_event_name = 'oracle.apps.cs.sr.ServiceRequest.created') THEN
         IF l_incident_rec.creation_program_code = 'CSZSRC' then
         
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
                                          p_cal_id => 'OD ST CAL',
                                          p_time_id => 1);
            exception
              when others then
                  ld_res_date := l_incident_rec.creation_date + (ln_res_hours/24);
            end;

             begin
                ld_resv_date := xx_cs_sr_utils_pkg.res_rev_time_cal
                                          (p_date => l_incident_rec.creation_date,
                                          p_hours => l_incident_rec.resolve_time,
                                          p_cal_id => 'OD ST CAL',
                                          p_time_id => 1);
             exception
               when others then
                    ld_resv_date  :=   l_incident_rec.creation_date + (l_incident_rec.resolve_time/24);
             end;
          
                 gc_err_msg := 'type_name '||l_incident_rec.type_name;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                           ,p_error_message_code =>   'XX_CS_0004_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                          ); 
              IF l_incident_rec.type_name = 'Billing Support Issues' then
              
                begin
                    select tag 
                    into lc_ext_context_val
                    from cs_lookups
                    where lookup_type = 'REQUEST_PROBLEM_CODE'
                    and lookup_code = l_incident_rec.problem_code;
                exception
                    when others then
                        null;
                end;
                
                  begin
                      update cs_incidents_all_b
                      set obligation_date = ld_res_date,
                          expected_resolution_date = ld_resv_date,
                          incident_attribute_9 = lc_aops_id,
                          incident_context = lc_context_val,
                          external_context = lc_ext_context_val
                      where incident_id = l_incident_rec.incident_id;
                      return 'SUCCESS';
                  exception
                    when others then
                        gc_err_msg := sqlerrm;
                        Log_Exception ( p_error_location  =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                    ,p_error_message_code =>   'XX_CS_0004_UNEXPECTED_ERR'
                                    ,p_error_msg          =>  gc_err_msg
                                    );
                        return 'FAILED';
                    end;
              
              else
                
                   begin
                      update cs_incidents_all_b
                      set obligation_date = ld_res_date,
                          expected_resolution_date = ld_resv_date,
                          incident_attribute_9 = lc_aops_id,
                          incident_context = lc_context_val,
                          project_number = lc_project_number
                      where incident_id = l_incident_rec.incident_id;
                      return 'SUCCESS';
                  exception
                    when others then
                        gc_err_msg := sqlerrm;
                        Log_Exception ( p_error_location  =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                    ,p_error_message_code =>   'XX_CS_0004_UNEXPECTED_ERR'
                                    ,p_error_msg          =>  gc_err_msg
                                    );
                        return 'FAILED';
                    end;
               end if; -- billing support.
               
         end if; --creation_program_code                
     
    
      /**************************************************************************/   
          -- send create notification to Print queue
      /**************************************************************************/
     IF l_incident_rec.type_name = 'Stocked Products' then
      IF lc_problem_code = 'PRINT ON DEMAND' THEN
          BEGIN
                select jtg.email_address
                into  lc_recipient
                from cs_incidents csi,
                     jtf_rs_groups_vl jtg
                where jtg.group_id = csi.owner_group_id
                and  csi.incident_number =  l_request_number
                and  csi.problem_code = 'PRINT ON DEMAND'
                and  jtg.group_name like '%RPF' ;
           EXCEPTION
              WHEN OTHERS THEN
                lc_recipient := null;
             gc_err_msg := 'ERROR while selecting RPF email'||sqlerrm;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                           ,p_error_message_code =>   'XX_CS_0003_UNEXPECTED_ERR'
                           ,p_error_msg          =>  gc_err_msg
                          );  
             END;
          
             IF lc_recipient is not null then
             
               begin
                  select fnd_profile.value('XX_CS_SMTP_SERVER')
                  into lc_smtp_server
                  from dual;
                exception
                  when others then
                     lc_smtp_server := 'chrelay.na.odcorp.net';
                end;
                        lc_sender   := 'SVC-CallCenter@officedepot.com';
                        lc_subject  := 'Request created for Copy and Print';
                        lc_message_body := 'Service Request# '||l_request_number||' created. Please verify in Queue and do not respond to this mail.';
                        lc_message_body := lc_message_body;
                        
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
      END IF;  -- Print on Demand
      
      END IF; -- Stocked type.
     END IF; -- event
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
    l_event_name                 VARCHAR2(240) := p_event.getEventName( );
    l_request_number            VARCHAR2(64);
    ln_user_id                    NUMBER;
    l_event_key                    VARCHAR2(240);
    ln_resp_appl_id              NUMBER;
    ln_resp_id                    NUMBER;
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
    lc_message                varchar2(2000);
    lc_notes                  long;
    lc_smtp_server            VARCHAR2(250);
    lc_return_code            NUMBER;
    lc_mail_conn              utl_smtp.connection;
    crlf                      VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
    v_mail_reply              utl_smtp.reply;
    lc_url                    varchar2(2000);
    lc_source                 varchar2(25);
    lc_type_email             varchar2(150);
    lc_status                 varchar2(50);
    lc_order_num              varchar2(50);
    -- for AR credit Risk
    lc_contact_email          varchar2(250);
    lc_user_name              varchar2(150);
    lc_resolution_type        varchar2(1000);
    -- Tech depot
    lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
    lt_task_notes               jtf_tasks_pub.task_notes_tbl;
    ln_msg_count                number;
    l_resource_id               number;
    l_request_id                NUMBER;
    lc_po_number                VARCHAR2(25);
    lc_event_status_flag        VARCHAR2(1) := 'N';
    lc_po_flag                  varchar2(1) := fnd_profile.value('XX_MPS_PO_CREATION');

BEGIN
    -- Obtain values initialized from the parameter list.
    l_request_number  := p_event.GetValueForParameter('REQUEST_NUMBER');
    ln_user_id        := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID');
    ln_resp_id        := p_event.GetValueForParameter('RESP_ID');
    l_event_key       := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');
    lc_summary        := p_event.GetValueForParameter('PREV_SUMMARY');


-------------------------
    begin
      select fnd_profile.value('XX_CS_SMTP_SERVER')
      into lc_smtp_server
      from dual;
    exception
      when others then
         lc_smtp_server := 'chrelay.na.odcorp.net';
    end;

    begin
      select inc.incident_status_id,
             fn.user_name,
             inc.created_by,
             inc.incident_owner_id,
             inc.incident_attribute_1||'-001',
             inc.incident_attribute_8,
             inc.incident_attribute_9,
             inc.incident_attribute_12 dispute_id,
             inc.incident_attribute_13 credit_memo,
             cit.name,
             inc.incident_id,
             inc.problem_code,
             inc.resolution_code,
             cit.attribute10,
             inc.purchase_order_num,
             inc.customer_id
      into   ln_status_id,
             lc_user_name,
             ln_creator_id,
             ln_owner_id,
             lc_order_num,
             lc_contact_email,
             lc_aops_id,
             lc_dispute_id,
             lc_credit_memo,
             lc_type_name,
             ln_incident_id,
             lc_problem_code,
             lc_resolution_type,
             lc_type_email,
             lc_po_number,
             ln_party_id
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

/*************************************************************************
   -- Check status id in Event notification rules
**************************************************************************/
BEGIN 
  SELECT 'Y'
  INTO LC_EVENT_STATUS_FLAG 
  FROM CS_SR_ACTION_TRIGGERS 
  WHERE INCIDENT_STATUS_ID = LN_STATUS_ID
  AND EVENT_CODE = 'CHANGE_STATUS_OF_SR'
  AND ROWNUM < 2;
EXCEPTION
  WHEN OTHERS THEN
     LC_EVENT_STATUS_FLAG := 'N';
END;

IF NVL(LC_EVENT_STATUS_FLAG,'N') = 'Y' THEN
    BEGIN
          SELECT name
           INTO  lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   incident_status_id = ln_status_id;
        EXCEPTION
          WHEN OTHERS THEN
            lc_status := 'Open';
    END;
     
      GC_ERR_MSG := 'in Event Status :  '||ln_status_id ||' Type:  '||lc_type_name;
       
       Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0005_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
                            
   If ln_status_id = 2 then
        
        -- IF Type EC Pcard then update expired date for file if exists
        IF lc_type_name = 'EC Pcard Program' THEN
            -- CALL PROECDURE
            update_attachment(ln_incident_id);
        END IF;
        -- Disputes 
         IF lc_type_name IN ('NA Credit Dispute','BSD Credit Dispute') THEN
          lc_subject := ' for Dispute# '||lc_dispute_id;
         else
           lc_subject := 'SR# '||L_REQUEST_NUMBER||' is closed';
         end if;

        -- Select creator mail id
        IF LC_USER_NAME <> 'CS_ADMIN' THEN
            begin
              select source_email
              into lc_recipient
              from jtf_rs_resource_extns
              where user_id = ln_creator_id;
            exception
              when others then
               lc_status_flag := 'E';
               gc_err_msg := 'Error while selecting email id '||sqlerrm;
            end;
        ELSE
            LC_RECIPIENT := NULL;
        END IF;
        
        --AR credit rick receipient
        IF lc_type_name like 'AR%' THEN
            LC_RECIPIENT := LC_CONTACT_eMAIL;
        END IF;
        
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
                        from cs_sr_notes_v csn,
                             jtf_notes_tl jtn
                        where jtn.jtf_note_id = csn.id
                        and   csn.incident_id = ln_incident_id
                        and   csn.note_status <> 'P'
                        and   csn.last_update_date = (select max(last_update_date) from cs_sr_notes_v
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
                                p_from_id     => ln_sender_id,
                                p_to_id      => ln_creator_id,
                                p_user_id      => ln_user_id,
                                p_message     => lc_message_body,
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
             
             IF LC_TYPE_NAME LIKE 'AR%' THEN
                  begin
                        select to_char(decode(csn.is_detail,'Y', jtn.notes_detail, csn.note)) note_details
                        into lc_notes
                        from cs_sr_notes_v csn,
                             jtf_notes_tl jtn
                        where jtn.jtf_note_id = csn.id
                        and   csn.incident_id = ln_incident_id
                        and   csn.note_status <> 'P'
                        and   csn.last_update_date = (select max(last_update_date) 
                                                      from cs_sr_notes_v
                                                      where incident_id = ln_incident_id);

                    exception
                      when others then
                          lc_notes := null;
                    end;
                    
                  begin 
                    select description 
                    into lc_resolution_type
                    from cs_lookups
                      where lookup_type = 'REQUEST_RESOLUTION_CODE'
                      and   lookup_code = lc_resolution_type;
                  exception
                      when others then
                          null;
                  end;
                    
                    lc_resolution_type := 'Resolution Type : '||lc_resolution_type;
                    
              END IF;
            
             
             IF lc_recipient is not null then
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
                        lc_message_body || crlf ||crlf|| lc_resolution_type||crlf||crlf|| lc_notes;
                        utl_smtp.helo(lc_mail_conn, lc_smtp_server);
                        utl_smtp.mail(lc_mail_conn, lc_sender);
                        utl_smtp.rcpt(lc_mail_conn, lc_recipient);
                        utl_smtp.data(lc_mail_conn, lc_mesg);
                        utl_smtp.quit(lc_mail_conn);
                     end;
                     
                    end if;
             end if;
           end if;  -- Type Checking.
            
        else
                  Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                                 ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                 ,p_error_msg          =>  gc_err_msg
                                  );
        end if;
    
    
    /**************************************************************************
     -- TDS request closed requests. 
     *************************************************************************/
    
    
     IF lc_type_name like 'TDS%' then
     
         gc_err_msg := 'Before enqueue message '||ln_incident_id;
     
        Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0001_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
        gc_err_msg := null;
        
        BEGIN
        
          XX_CS_TDS_SR_PKG.ENQUEUE_MESSAGE (P_REQUEST_ID  => ln_incident_id,
                                        P_RETURN_CODE  => lc_status_flag,
                                        P_RETURN_MSG     => gc_err_msg);
                                        
       
           
          Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0002_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
          XX_CS_TDS_UTIL_PKG.EMAIL_SEND(P_INCIDENT => L_REQUEST_NUMBER,
                                        P_ORDER_NUM => LC_ORDER_NUM,
                                        P_EMAIL => LC_CONTACT_EMAIL,
                                        X_STATUS_FLAG => LC_STATUS,
                                        X_RETURN_MSG => LC_MESSAGE);
                                                       
        EXCEPTION
            WHEN OTHERS THEN
                GC_ERR_MSG  := 'Error while ENQUEUE message to AOPS : '|| ln_incident_id||' '||gc_err_msg;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                               ,p_error_message_code =>   'XX_CS_0003_UNEXPECTED_ERR'
                               ,p_error_msg          =>  gc_err_msg
                                );
        END;
    END IF;

ELSE

  /*
  GC_ERR_MSG  := 'Status :'|| LC_STATUS|| ' for SR#'||ln_incident_id;
             Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0003_log'
                           ,p_error_msg          =>  gc_err_msg
                            ); */
                            
   
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
    
     /**************************************************************************
     -- MPS Requests. 
     *************************************************************************/
    
     IF lc_type_name = 'MPS Contract Request' then
     
      IF LC_STATUS IN ('Work Completed') THEN
        
         gc_err_msg := 'Before call receive feed '||ln_incident_id;
     
         Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0001_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
         xx_cs_mps_avf_feed_pkg.receive_feed( p_request_id   => ln_incident_id
                                          , p_party_id      => ln_party_id
                                          , x_return_status  => lc_status
                                          , x_return_mesg    => lc_message);
      END IF;
                                          
    end if;
    
      IF lc_type_name = 'MPS Supplies Request' then
     
      IF LC_STATUS IN ('Work Completed') THEN
        
         gc_err_msg := 'Before call receive feed '||ln_incident_id;
     
         Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0002_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
        /* xx_cs_mps_avf_feed_pkg.load_fleet_feed( p_request_id   => ln_incident_id
                                          , x_return_status  => lc_status
                                          , x_return_msg    => lc_message); */
                                          
       begin 
                                          
        l_request_id :=   fnd_request.submit_request ('CS',
                                            'XX_CS_MPS_FEED',
                                            'OD MPS Fleet Data Upload',
                                            NULL,
                                            FALSE,
                                            'FLEETLOAD',
                                            l_request_number,
                                            null
                                            );
        exception
          when others then
              gc_err_msg := ' Error while submit the MPS feed Conc Request '||L_REQUEST_NUMBER||' Conc Req# '||l_request_id;
                   Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002d_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
        
        end;
                                            
                IF l_request_id < 0  THEN
                   gc_err_msg := ' Error while submit the MPS feed Conc Request '||L_REQUEST_NUMBER||' Conc Req# '||l_request_id;
                   Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002a_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
                ELSE
                    UPDATE CS_INCIDENTS
                    SET SUMMARY = 'File Load In Progress.. Please refresh for latest updates',
                        purchase_order_num = l_request_number
                    WHERE INCIDENT_ID = LN_INCIDENT_ID;
                  
                END IF;
                
      END IF;
      
       IF LC_STATUS IN ('Resolved') THEN
        
         gc_err_msg := 'Before call supplies_req '||ln_incident_id;
     
         Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                           ,p_error_message_code =>   'XX_CS_0003_SUCCESS_LOG'
                           ,p_error_msg          =>  gc_err_msg
                            );
                            
       XX_CS_MPS_VALIDATION_PKG.SUPPLIES_REQ(P_DEVICE_ID   => L_REQUEST_NUMBER,
                                              P_GROUP_ID    => LN_PARTY_ID,
                                              X_RETURN_STATUS  => LC_STATUS,
                                              X_RETURN_MSG    => LC_MESSAGE); 
                                              
      END IF;
                                          
    end if;
    
      -- MPS Installations
      IF lc_type_name = 'MPS Installations' then 
         IF LC_STATUS = 'Approved' THEN
            IF nvl(lc_po_flag,'N') = 'Y' then
               begin
                     XX_CS_MPS_VALIDATION_PKG.SUBMIT_PO( LN_PARTY_ID,
                                 L_REQUEST_NUMBER,
                                 'OTHER',
                                 LC_STATUS,
                                 LC_MESSAGE);
                                 
              end;
          
           end if;
         end if;
      end if;
      
      -- MPS Time and Material
      
       IF lc_type_name = 'MPS TIME-MATERIAL' then 
          IF LC_STATUS = 'Approved' THEN
            IF nvl(lc_po_flag,'N') = 'Y' then
              begin
                     XX_CS_MPS_VALIDATION_PKG.SUBMIT_PO( LN_PARTY_ID,
                                 L_REQUEST_NUMBER,
                                'TMATERIAL',
                                 LC_STATUS,
                                 LC_MESSAGE);
                                 
              end;
           end if;
         end if;
       end if;
       
      -- MPS Service
       IF lc_type_name = 'MPS Device' then 
         IF LC_STATUS = 'Resolved' THEN
          IF lc_problem_code = 'MPS-HARDWARE ISSUE' 
           AND lc_resolution_type = 'MPS-SERVICE' THEN
              -- Call vendor interface
                BEGIN
                    XX_CS_MPS_VEN_PKG.CASE_OUTBOUND_PROC (P_INCIDENT_ID => LN_INCIDENT_ID ,
                                   P_ACTION       => 'Create',
                                   P_TYPE         => NULL,
                                   P_PARTY_ID     => LN_PARTY_ID,
                                   X_RETURN_STATUS => LC_STATUS,
                                   X_RETURN_MSG   => LC_MESSAGE );
                      EXCEPTION
                        WHEN OTHERS THEN
                            GC_ERR_MSG  := 'Error invoking barrister interface: '|| ln_incident_id||' '||sqlerrm;
                             Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                                           ,p_error_message_code =>   'XX_CS_0004_UNEXPECTED_ERR'
                                           ,p_error_msg          =>  gc_err_msg
                                            );
                                   
                END;
           END IF;
         end if;
       end if;
      
      
    IF lc_type_name like 'TDS%' THEN
      -- TDS Cancelled Status 
      IF lc_status = 'Cancelled' then
      
      --IF LC_USER_NAME = 'CS_ADMIN' THEN
  
            XX_CS_TDS_VEN_PKG.VEN_OUTBOUND(p_incident_id => ln_incident_id, 
                                        p_sr_type       => lc_type_name,
                                        p_user_id       => ln_user_id,
                                        p_status_id     => ln_status_id,
                                        x_return_status => lc_status_flag,
                                        x_return_msg    => gc_err_msg);
     -- ELSE
      
        begin
          update xx_cs_sr_items_link
          set quantity = 0
          where service_request_id = ln_incident_id;
          
          commit;
        end;
        
        BEGIN
          XX_CS_TDS_SR_PKG.ENQUEUE_MESSAGE (P_REQUEST_ID   => ln_incident_id,
                                            P_RETURN_CODE  => lc_status_flag,
                                            P_RETURN_MSG   => gc_err_msg);
                             
        EXCEPTION
            WHEN OTHERS THEN
                GC_ERR_MSG  := 'Error while ENQUEUE message to AOPS : '|| ln_incident_id||' '||gc_err_msg;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                               ,p_error_message_code =>   'XX_CS_0004_UNEXPECTED_ERR'
                               ,p_error_msg          =>  gc_err_msg
                                );
        END; 
        
        IF LC_PO_NUMBER IS NOT NULL THEN
         begin
          XX_CS_TDS_PARTS_VEN_PKG.PART_OUTBOUND (p_incident_number   => l_request_number, 
                                                   p_incident_id         => ln_incident_id,
                                                   p_doc_type         => 'CANCEL',
                                                   p_doc_number       => l_request_number,
                                                   x_return_status    => lc_status_flag,
                                                   x_return_msg       => gc_err_msg);
            exception
              WHEN OTHERS THEN
                GC_ERR_MSG  := 'Error while calling part_outboune'|| ln_incident_id||' '||gc_err_msg;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                               ,p_error_message_code =>   'XX_CS_0005_UNEXPECTED_ERR'
                               ,p_error_msg          =>  gc_err_msg
                                );
            END; 
        END IF;
   --   END IF; -- User check. 
      
     ELSIF LC_STATUS = 'Service Not Started' then
         -- Task creation
          BEGIN
              XX_CS_SR_TASK.CREATE_PROCEDURE(LN_INCIDENT_ID,
                                              LC_STATUS_FLAG,
                                              LC_MESSAGE);
            EXCEPTION
              WHEN OTHERS THEN
                gc_err_msg := 'Error while generating tasks for '||l_request_number ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                           ,p_error_message_code =>   'XX_CS_0001_ERR_LOG'
                           ,p_error_msg          =>  gc_err_msg
                          );
           END;
       
       ELSIF LC_STATUS = 'Received Parts' THEN
       
           -- get the resource_id
       /*    begin
             select ja.resource_id
             into l_resource_id
              from jtf_tasks_vl jt,
                    jtf_task_types_tl jv,
                    jtf_task_assignments ja
              where ja.task_id = jt.task_id
              and   jv.task_type_id = jt.task_type_id
              and   jt.source_object_type_code = 'SR'
              and   jt.source_object_id = ln_incident_id
              and   jv.name like 'TDS Diagnosis and Repair';
           exception
             when others then
                l_resource_id := 100001060;
            end; */
            
            begin
               select jtt.resource_id
                into   l_resource_id
                from   jtf_rs_resource_extns jtt,
                       jtf_rs_group_members jtm
                where jtm.resource_id = jtt.resource_id
                and   jtt.category = 'PARTY'
                 and   jtm.delete_flag = 'N'
                and   exists (select 'x' from csp_inv_loc_assignments
                              where resource_id = jtt.resource_id )
                and   jtm.group_id = (SELECT owner_group_id
                                    FROM cs_incidents_all_b
                                    WHERE incident_id = ln_incident_id );
                                    
            exception
             when others then
                gc_err_msg := 'Error while selecting resource_id '||l_request_number ;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002d_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
            end;
       
         begin
            xx_cs_tds_parts_receipts.receive_shipments (
                              p_api_version_number => 1.0,
                              p_init_msg_list      => fnd_api.g_false,
                              p_commit             => fnd_api.g_false,
                              p_validation_level   => null,
                              p_document_number    => l_request_number,
                              p_resource_id        => l_resource_id,
                              x_return_status      => lc_status,
                              x_msg_count          => ln_msg_count,
                              x_msg_data           => lc_message );
          exception
             when others then
                gc_err_msg := 'Error while calling receive shipments '||l_request_number ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002c_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
          end;
                              
       ELSIF LC_STATUS IN ('Work Completed') THEN 
       
           begin
            XX_CS_TDS_EXCESS_PARTS.EXCESS_RETURNS (
                              p_document_number    => l_request_number,
                              p_validation_level   => null,
                              p_resource_id        => l_resource_id,
                              x_return_status      => lc_status,
                              x_msg_count          => ln_msg_count,
                              x_msg_data           => lc_message );
          exception
             when others then
                gc_err_msg := 'Error while calling Excess Parts Process '||l_request_number ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002d_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
          end;
       ELSIF LC_STATUS in ('Approved') then
          -- Send mail to Customer for pick up pc
          BEGIN
              
                 l_request_id :=   fnd_request.submit_request ('CS',
                                            'XX_TDS_PARTS_ITEMS',
                                            'OD CS TDS Parts Items',
                                            NULL,
                                            FALSE,
                                            l_request_number
                                            );
                                            
                IF l_request_id < 0  THEN
                   gc_err_msg := ' Error while submit the Conc Request '||L_REQUEST_NUMBER;
                   Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002a_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
                ELSE
                    UPDATE CS_INCIDENTS
                    SET SUMMARY = 'In Progress.. Please refresh for latest updates',
                        purchase_order_num = l_request_number
                    WHERE INCIDENT_ID = LN_INCIDENT_ID;
                  
                END IF;

   
          EXCEPTION
              WHEN OTHERS THEN
                gc_err_msg := 'Error while calling parts process '||l_request_number ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002a_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
           END;
     ELSIF LC_STATUS in ('Call Customer') then
          -- Send mail to Customer for pick up pc
          BEGIN
              XX_CS_TDS_UTIL_PKG.EMAIL_SEND_PICKUP(P_INCIDENT => L_REQUEST_NUMBER,
                                        P_ORDER_NUM => LC_ORDER_NUM,
                                        P_EMAIL => LC_CONTACT_EMAIL,
                                        X_STATUS_FLAG => LC_STATUS,
                                        X_RETURN_MSG => LC_MESSAGE);
            EXCEPTION
              WHEN OTHERS THEN
                gc_err_msg := 'Error while sending mail '||ln_incident_id ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_Cust_Rule_Func'
                                 ,p_error_message_code =>   'XX_CS_0002_ERR_LOG'
                                 ,p_error_msg          =>  gc_err_msg
                                );
           END;
     ELSE
    -- VEN OUTBOUND MESSAGES
       BEGIN
         gc_err_msg := null;
         
          XX_CS_TDS_VEN_PKG.VEN_OUTBOUND(p_incident_id => ln_incident_id, 
                                        p_sr_type       => lc_type_name,
                                        p_user_id       => ln_user_id,
                                        p_status_id     => ln_status_id,
                                        x_return_status => lc_status_flag,
                                        x_return_msg    => gc_err_msg);
                                    
      exception
        when others then
            GC_ERR_MSG  := 'Error while calling outbound message '|| ln_incident_id||' '||sqlerrm;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_STATUS_Func'
                               ,p_error_message_code =>   'XX_CS_0004_UNEXPECTED_ERR'
                               ,p_error_msg          =>  gc_err_msg
                                );
      end;
     END IF;  -- Cancelled Status
    END IF; -- TDS Type
    
    return 'SUCCESS';
  END IF; -- Close Status
    -----------------------------
END IF;  -- Event Status flag check
    return 'SUCCESS';
END CS_SR_STATUS_Func;
/*********************************************************************************************
 **********************************************************************************************/
-- Change Record:                                                                             |
-- |===============                                                                           |
-- |Version    Date              Author              Remarks                                  |
-- |=======    ==========        =============       ========================                 |
-- |1.0      19-Jun-2013       Arun Gannarapu       Updated to auto assign the Group          |
--                                                                                            |  
-- Purspose :                                                                                 |
-- This function is called from Business events ,                                             |
-- It updates the SR Group and owner when the SR type is changed to ECR type                  |
-- The Group will be derived and assigned to SR based on the SR Type/seeded rules .           | 
-- If the owner is already exists then it will remain same ..
/*********************************************************************************************/

/*******************************************************************************/
 FUNCTION CS_SR_OWNER_Func(p_subscription_guid in raw,
                           p_event             in out nocopy WF_EVENT_T)
 RETURN varchar2
 AS
    L_EVENT_NAME                 varchar2(240);
    L_EVENT_KEY                  varchar2(240);
    l_incident_number            cs_incidents_all_b.incident_number%type;
    l_incident_id                cs_incidents_all_b.incident_id%type;
    lc_responsibility_id         varchar2(80);
    lc_responsibility_appl_id    varchar2(30);
    l_incident_date              date;
    lc_return_status             varchar2(240);
    l_incident_status_id         cs_incidents_all_b.incident_status_id%type;
    l_service_rec                cs_servicerequest_pub.service_request_rec_type;
    ln_sr_user_id                number;
    ln_sr_resp_id                number;
    ln_sr_resp_appl_id           number;
    ln_sr_api_version            number;
    lc_sr_return_status          varchar2(1);
    ln_sr_msg_count              number;
    lc_sr_msg_data               varchar2(2000);
    ln_sr_msg_index_out          number;
    ln_prev_type_id              number;
    ln_prev_owner_id             number;
    ln_prev_status_id            number;
    ln_dispute_id                number;
    lc_subject                   varchar2(250);
    lc_msg                       varchar2(2000);
    ln_owner_id                  number;
    lc_owner_name                varchar2(250);
    ln_group_id                  number;
    lc_created_by                varchar2(100);
    lc_resource_type             varchar2(100);
    ln_sr_type_id                number;
    lc_sr_problem_code           varchar2(250);
    lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
    lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
    lc_maintenance_flag          varchar2(1);
    lc_url                       varchar2(2000);
    lc_exsit_flag                varchar2(1) := 'N';
    lx_msg_count                 NUMBER;
    lx_msg_data                  VARCHAR2(2000);
    lx_msg_index_out             NUMBER;
    lx_return_status             VARCHAR2(1);
    ln_obj_ver                   NUMBER ;
    lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
    lx_sr_update_rec_type        CS_ServiceRequest_PUB.sr_update_out_rec_type;
    lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
    lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
    lc_message                   VARCHAR2(2000);
    lc_auto_assign               VARCHAR2(1) := NULL;
    
 BEGIN
 
    -- get the service request number from the event message
  
    l_incident_number   := wf_event.getValueForParameter('REQUEST_NUMBER',p_event.Parameter_List);
    ln_sr_user_id	    := wf_event.getValueForParameter('USER_ID',p_event.Parameter_List);
    ln_sr_resp_id       := wf_event.getValueForParameter('RESP_ID',p_event.Parameter_List);
    ln_sr_resp_appl_id  := wf_event.getValueForParameter('RESP_APPL_ID',p_event.Parameter_List);
    ln_prev_type_id     := wf_event.getValueForParameter('PREV_TYPE_ID',p_event.Parameter_List);
    ln_prev_status_id   := wf_event.getValueForParameter('PREV_STATUS_ID',p_event.Parameter_List);
    ln_prev_owner_id    := wf_event.getValueForParameter('PREV_OWNER_ID',p_event.Parameter_List);
    
    IF ln_prev_type_id is not null
    THEN
      -- get the service request id and service request type
      
      BEGIN
        SELECT cia.incident_id,
               cia.incident_date,
               cia.incident_type_id,
               cia.problem_code, 
               nvl(cia.incident_owner_id,ln_prev_owner_id),
               cia.object_version_number,
               cia.incident_status_id
        INTO   l_incident_id,
               l_incident_date,
               ln_sr_type_id,
               lc_sr_problem_code,
               ln_owner_id,
               ln_obj_ver,
               lr_service_request_rec.status_id
        FROM   cs_incidents_vl_sec cia,
               cs_incident_types_vl_sec cit
        WHERE  cia.incident_number = l_incident_number
        AND    cia.incident_type_id = cit.incident_type_id
        AND    cit.name like 'ECR%';
      EXCEPTION 
        WHEN OTHERS 
        THEN 
          l_incident_id := null;
          ln_sr_type_id  := null;
      END;
   
      IF l_incident_id is not null
      THEN 
         -- Request Type Change
         IF ln_sr_type_id <> ln_prev_type_id
         THEN
            lc_maintenance_flag := 'Y';
         END IF;
      END IF;

      -- if service request type is maintenance, then proceed  else terminate
      
      IF (nvl(lc_maintenance_flag,'N') = 'Y')
      THEN 
        BEGIN 
        
          cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
          lr_service_request_rec.owner_group_id  := NULL;
          lr_service_request_rec.owner_id       := NULL; --:= ln_owner_id;
          lc_auto_assign := 'Y';
          
          cs_servicerequest_pub.Update_ServiceRequest(p_api_version            => 4.0,
                                                      p_init_msg_list          => FND_API.G_TRUE,
                                                      p_commit                 => FND_API.G_FALSE,
                                                      x_return_status          => lx_return_status,
                                                      x_msg_count              => lx_msg_count,
                                                      x_msg_data               => lx_msg_data,
                                                      p_request_id             => l_incident_id,
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
                                                      p_auto_assign            => lc_auto_assign,
                                                      p_workflow_process_id    => NULL,
                                                      x_sr_update_out_rec      => lx_sr_update_rec_type);
                                                      
         IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS)
          THEN 
            IF (FND_MSG_PUB.Count_Msg > 1)
            THEN
              --Display all the error messages
              FOR j in  1..FND_MSG_PUB.Count_Msg
              LOOP
                FND_MSG_PUB.Get(p_msg_index     => j,
                                p_encoded       => 'F',
                                p_data          => lx_msg_data,
                                p_msg_index_out => lx_msg_index_out);
              END LOOP;
            ELSE      --Only one error
              FND_MSG_PUB.Get(p_msg_index     => 1,
                              p_encoded       => 'F',
                              p_data          => lx_msg_data,
                              p_msg_index_out => lx_msg_index_out);
            END IF;
            
          ELSIF (lx_return_status = FND_API.G_RET_STS_SUCCESS) 
          THEN 
           COMMIT;
           IF ln_owner_id IS NOT NULL
           THEN 
             XX_CS_SR_UTILS_PKG.Update_SR_Owner(p_sr_request_id  => l_incident_id,
                                                p_user_id        => NULL,
                                                p_owner          => ln_owner_id, 
                                                x_return_status  => lx_return_status,
                                                x_msg_data       => lx_msg_data);
           END IF;   
         END IF;
         lc_message := 'FND  '||lx_return_status ||' '||lx_msg_data;
         fnd_file.put_line(fnd_file.log, 'TEST'|| lc_message);

         RETURN 'SUCCESS';
      
        EXCEPTION 
        WHEN OTHERS
        THEN 
          gc_err_msg := sqlerrm;
          Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_SR_OWNER_Func'
                         ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                        ,p_error_msg          =>  gc_err_msg);
       
          wf_core.context('XX_CS_CUSTOM_EVENT_PKG','service_request_updated',
                        p_event.getEventName(),p_subscription_guid);
                      wf_event.setErrorInfo(p_event,'ERROR');
          RETURN 'ERROR';
        END; 

        -- Select new group id
       --************************************************************************
       -- Get Resources
       --*************************************************************************
        -- Comment start AG 
       /* lr_TerrServReq_Rec.service_request_id   := l_incident_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_sr_type_id;
          lr_TerrServReq_Rec.problem_code         := lc_sr_problem_code;

       -- *************************************************************************************************************
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

       --****************************************************************************
          IF lt_TerrResource_tbl.count > 0 THEN
           -- dbms_output.put_line('owner_group_id '||lt_TerrResource_tbl(1).resource_id);

               ln_group_id       := lt_TerrResource_tbl(1).resource_id;
               lc_resource_type     := lt_TerrResource_tbl(1).resource_type;
             end if;

         --***********************************************************************
                -- Update SR
         --***********************************************************************
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
             end; */ -- comment ends --AG 
            
      END IF; -- Maintenance flag 
    END IF; -- ln_prev_type_id 

    -- Send owner update notification to DRT
    IF ln_prev_owner_id is null
    and (ln_prev_status_id is null or ln_prev_status_id = 1)
    Then
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


      If (ln_owner_id is not null and lc_exsit_flag = 'N' )
      Then
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
FUNCTION CS_WH_Func(p_subscription_guid in raw,
                     p_event in out nocopy WF_EVENT_T) RETURN varchar2 AS

    l_event_name           VARCHAR2(240) := p_event.getEventName( );
    l_request_number          VARCHAR2(64);
    l_user_id              NUMBER;
    l_event_key              VARCHAR2(240);
    ln_request_id             number;
    ln_resp_appl_id          NUMBER;
    ln_resp_id              NUMBER;
    lc_initiator_role         VARCHAR2(150);
    lc_sender_role            varchar2(150);
    lc_error_msg              VARCHAR2(1000);
    lc_return_status          varchar2(25);
    lc_message                varchar2(1000);
    lc_subject                varchar2(250);
    ln_return_code            number;

  
  begin

    -- Obtain values initialized from the parameter list.
    l_request_number  := p_event.GetValueForParameter('REQUEST_NUMBER');
    l_user_id         := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID');
    ln_resp_id        := p_event.GetValueForParameter('RESP_ID');
    l_event_key       := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');

    
    return 'SUCCESS';
  EXCEPTION
    WHEN others THEN
      WF_CORE.CONTEXT('XX_CS_CUSTOM_EVENT', 'CS_WH_Func',
                      l_event_name , p_subscription_guid);
      WF_EVENT.setErrorInfo(p_event, 'ERROR');
       gc_err_msg := 'ERROR in custom event';
       Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_WH_Func'
                     ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                     ,p_error_msg          =>  gc_err_msg
                    );
      return 'WARNING';
  END CS_WH_Func;
/***************************************************************************/
FUNCTION CS_WH_ESC_Func(p_subscription_guid in raw,
                     p_event in out nocopy WF_EVENT_T) RETURN varchar2 AS

    l_event_name           VARCHAR2(240) := p_event.getEventName( );
    l_request_number          VARCHAR2(64);
    l_user_id              NUMBER;
    l_event_key              VARCHAR2(240);
    ln_request_id             number;
    ln_resp_appl_id          NUMBER;
    ln_resp_id              NUMBER;
    lc_initiator_role         VARCHAR2(150);
    lc_sender_role            varchar2(150);
    lc_error_msg              VARCHAR2(1000);
    lc_return_status          varchar2(25);
    lc_message                varchar2(1000);
    lc_esc_code               varchar2(15);
    ln_return_code            number;
    LC_SR_STATUS_ID           varchar2(25);
    LT_SR_NOTES               XX_CS_SR_MAIL_NOTES_REC;

    CURSOR sel_incident_csr IS
     SELECT inc.incident_type_id type_id,
             cit.name type_name,
             inc.incident_id,
             inc.creation_date,
             inc.problem_code,
             inc.summary,
             inc.incident_status_id
      FROM   cs_incidents inc,
             cs_incident_types cit,
             cs_lookups csl
      WHERE  csl.lookup_code = inc.problem_code
      and    inc.incident_number = l_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    inc.incident_status_id = 51
      and    cit.end_date_active is null
      and    cit.name = 'Stocked Products'
      and    csl.lookup_type = 'XX_CS_WH_EMAIL'
      and    csl.enabled_flag = 'Y';

    l_incident_rec   sel_incident_csr%ROWTYPE;

  begin

    -- Obtain values initialized from the parameter list.
    l_request_number  := p_event.GetValueForParameter('REQUEST_NUMBER');
    l_user_id         := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id   := p_event.GetValueForParameter('RESP_APPL_ID');
    ln_resp_id        := p_event.GetValueForParameter('RESP_ID');
    l_event_key       := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
    lc_sender_role    := p_event.GetValueForParameter('SENDER_ROLE');

    OPEN sel_incident_csr;
    FETCH sel_incident_csr INTO l_incident_rec;
    IF (sel_incident_csr%FOUND AND l_incident_rec.type_id IS NOT NULL ) THEN

          IF l_incident_rec.incident_id is not null then
            BEGIN
              select reference_code
              into lc_esc_code
              from jtf_task_references_b
              where object_type_code = 'SR'
              and object_id = l_incident_rec.incident_id;
            exception
              when others then
                lc_esc_code := null;
            END;

           IF lc_esc_code = 'ESC' THEN
                 LC_SR_STATUS_ID := 'Closed';
                    IF l_incident_rec.incident_status_id <> 2 then
                       XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(
                              P_SR_REQUEST_ID => l_incident_rec.incident_id,
                              P_USER_ID    => L_USER_ID,
                              P_STATUS_ID =>  NULL,
                              P_STATUS    => LC_SR_STATUS_ID,
                              X_RETURN_STATUS => LC_RETURN_STATUS,
                               X_MSG_DATA => LC_ERROR_MSG
                               );
                    end if;

                    lt_sr_notes.notes          := 'No Response from EOders team and closing SR automatically';

                    BEGIN

                       XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id   => l_incident_rec.incident_id,
                                                       p_sr_notes_rec => lt_sr_notes,
                                                       p_return_status => lc_return_status,
                                                       p_msg_data => lc_error_msg);
                          commit;
                     exception
                       when others then
                          gc_err_msg := 'Error while updating SR and notes '||sqlerrm;
                          Log_Exception ( p_error_location     =>  'XX_CS_MESG_PKG.READ_RESPONSE'
                                       ,p_error_message_code =>   'XX_CS_SR01_ERROR_LOG'
                                       ,p_error_msg          =>  gc_err_msg);
                    END ;
               END IF;  --'ESC'


          END IF; -- incident id
    --   END IF; -- EVENT
    END IF; -- Type id is not null

    CLOSE sel_incident_csr;
    return 'SUCCESS';
  EXCEPTION
    WHEN others THEN
      IF sel_incident_csr%ISOPEN THEN
    CLOSE sel_incident_csr;
      END IF;
      WF_CORE.CONTEXT('XX_CS_CUSTOM_EVENT', 'CS_WH_Func',
                      l_event_name , p_subscription_guid);
      WF_EVENT.setErrorInfo(p_event, 'ERROR');
       gc_err_msg := 'ERROR in custom event';
       Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.CS_WH_Func'
                     ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                     ,p_error_msg          =>  gc_err_msg
                    );
      return 'WARNING';
  END CS_WH_ESC_Func;

/***************************************************************************/
END XX_CS_CUSTOM_EVENT_PKG;
/
show errors;
exit;