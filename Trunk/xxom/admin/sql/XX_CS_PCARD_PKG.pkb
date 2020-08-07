CREATE OR REPLACE
PACKAGE BODY "XX_CS_PCARD_PKG" AS
-- +===================================================================================+
-- |                        Office Depot - Project Simplify                            |
-- +===================================================================================+
-- | Name    : XX_CS_PCARD_PKG                                                         |
-- |                                                                                   |
-- | Description      : PCARD encryption and decryption functions                      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version    Date              Author              Remarks                           |
-- |=======    ==========        =============       ========================          |
-- |1.0       20-Aug-08        Raj Jagarlamudi        Initial draft version            |
-- |2.0       09-Jul-13        Arun Gannarapu         Made changes to fnd_documents    |
-- |                                                                                   |
-- +===================================================================================+
/*******************************************************************************
The objects that can be reviewed if considering a customization are as follows:
  . Procedure fnd_attached_documents_pkg.insert_row
  . Table FND_LOBS
  . Table FND_DOCUMENTS (and FND_DOCUMENTS_TL)
  . Table FND_ATTACHED_DOCUMENTS
     - Field ENTITY_NAME = 'CS_INCIDENTS'
     - Field PK1_VALUE to hold the INCIDENT_ID.
*******************************************************************************/
gc_err_msg                varchar2(2000);
gc_err_status             varchar2(25);
gn_msg_cnt                number;
gc_key_lable              varchar2(100);
gc_file_key_lable         varchar2(100);
gc_module                 varchar2(100) := 'PCARD';
g_user_id                 number;
gc_encrypted_val          varchar2(200);
gc_decrypted_val          varchar2(200);

/*************************************************************************/
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
     ,p_program_type            => 'Customer Support PCard Events'
     ,p_program_name            => 'XX_CS_PCARD_PKG'
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

/****************************************************************************/
FUNCTION ENC_PCARD_RULE_Func(p_subscription_guid in raw,
                            p_event in out nocopy WF_EVENT_T) RETURN varchar2 AS
  --  PRAGMA Autonomous_Transaction;
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
    lc_error_msg              VARCHAR2(1000);
    
    CURSOR sel_incident_csr IS
      SELECT inc.incident_type_id type_id,
             inc.incident_id,
             inc.incident_attribute_6  pcard_no,
             inc.incident_attribute_14 inc_label,
             translate(inc.incident_attribute_6,
             '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', '0123456789') tran_pcard_no 
      FROM   cs_incidents inc,
             cs_incident_types cit
      WHERE  inc.incident_number = l_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    cit.end_date_active is null
      and    cit.name like 'EC Pcard Program';

    l_incident_rec   sel_incident_csr%ROWTYPE;
    
  begin
  
    -- Obtain values initialized from the parameter list.
    l_request_number := p_event.GetValueForParameter('REQUEST_NUMBER');
    l_user_id := p_event.GetValueForParameter('USER_ID');
    ln_resp_appl_id := p_event.GetValueForParameter('RESP_APPL_ID'); 
    ln_resp_id := p_event.GetValueForParameter('RESP_ID');
    l_event_key := p_event.getEventKey();
    lc_initiator_role := p_event.GetValueForParameter('INITIATOR_ROLE');
        
    OPEN sel_incident_csr;
    FETCH sel_incident_csr INTO l_incident_rec;
    IF (sel_incident_csr%FOUND AND l_incident_rec.type_id IS NOT NULL) THEN
    
        IF(l_event_name = 'oracle.apps.cs.sr.ServiceRequest.updated') THEN
         
              fnd_global.apps_initialize(
					user_id => l_user_id,
					resp_id => ln_resp_id,
    					resp_appl_id => ln_resp_appl_id
				);
              
              gc_decrypted_val := l_incident_rec.pcard_no;
              
              IF nvl(gc_decrypted_val,'x') = l_incident_rec.tran_pcard_no  
                 AND L_INCIDENT_REC.INC_LABEL IS NULL THEN
                  APPS.XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL(
                            x_encrypted_val  => gc_encrypted_val,
                            x_error_message  => gc_err_msg,
                            x_key_label      => gc_key_lable,
                            p_module         => gc_module,
                            p_key_label      => gc_key_lable,
                            p_algorithm      => 'AES',
                            p_decrypted_val  => gc_decrypted_val,
                            p_format         => 'BASE64');
                            
                 IF gc_key_lable is not null then               
                    begin 
                      update cs_incidents_all_b
                      set incident_attribute_6 = gc_encrypted_val,
                          incident_attribute_14 = gc_key_lable,
                          incident_context = 'EC Addl.'
                      where incident_id = l_incident_rec.incident_id;
                      commit;
                      gc_err_status := 'SUCCESS';
                  exception
                    when others then
                        gc_err_msg    :=  sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.ENC_PCARD_RULE_Func'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
                        gc_err_status := 'FAILED';
                  end;
                else
                    Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.ENC_PCARD_RULE_Func'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
                    gc_err_status := 'FAILED';
                end if; /** gc_key_lable **/
                
              END IF;  /** If ( gc_decrypted_val) **/
              begin
              -- Calling encrypt file attachement if exists
                 XX_CS_PCARD_PKG.encrypt_attachment(l_incident_rec.incident_id);
              exception
                when others then
                  gc_err_msg := sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.Encrypt_attachment'
                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                         ,p_error_msg          =>  gc_err_msg
                          );
                    gc_err_status := 'FAILED';
              end;
      END IF; /** If (Event) **/

    END IF;	/** IF (sel_incident_csr%FOUND AND ... **/
    CLOSE  sel_incident_csr;
    RETURN gc_err_status;
  EXCEPTION
    WHEN others THEN
      IF sel_incident_csr%ISOPEN THEN
	CLOSE sel_incident_csr;
      END IF;
      WF_CORE.CONTEXT('XX_CS_PCARD_PKG', 'ENC_PCARD_RULE_Func',
                      l_event_name , p_subscription_guid);
      WF_EVENT.setErrorInfo(p_event, gc_err_msg);
      return 'FAILED';

  END ENC_PCARD_RULE_Func;

/***********************************************************************
 -- File encryption
************************************************************************/
PROCEDURE encrypt_attachment (p_incident_id in number)
IS

CURSOR sel_file_csr IS
    select lb.file_data , lb.file_id
    from   fnd_attached_documents dc,
           fnd_documents dt,
           fnd_lobs lb
    where lb.file_id = dt.media_id
    and   dt.document_id = dc.document_id
    and   dc.entity_name = 'CS_INCIDENTS'
    and   lb.program_tag is null
    and   dc.pk1_value = to_char(p_incident_id);
    
    l_file_rec    sel_file_csr%ROWTYPE;
    l_file_val    BLOB;
    
BEGIN
    OPEN sel_file_csr;
    LOOP
    FETCH sel_file_csr INTO l_file_rec;
    EXIT when sel_file_csr%NOTFOUND;
                            
    APPS.XX_OD_SECURITY_KEY_PKG.ENCRYPT_BLOB(
               x_out_val        => l_file_val,
               x_error_message  => gc_err_msg,
               x_key_label      => gc_file_key_lable,
               p_module         => gc_module,
               p_key_label      => gc_file_key_lable,
               p_in_val         => l_file_rec.file_data
              );
                            
    IF gc_file_key_lable is not null then
      -- update file data and label.
       BEGIN
        UPDATE FND_LOBS
        SET FILE_DATA   = L_FILE_VAL,
            PROGRAM_TAG = gc_file_key_lable
        WHERE FILE_ID = L_FILE_REC.FILE_ID;
        
       EXCEPTION
        WHEN OTHERS THEN
          gc_err_msg    := 'error '||sqlerrm;
           Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.Encrypt_attachment'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
          gc_err_status := 'FAILED';
       END;
         
        IF nvl(gc_err_status,'X') <> 'FAILED' then
         begin 
            update cs_incidents_all_b
            set incident_attribute_6 = 'File Attached',
                incident_attribute_14 = gc_file_key_lable,
                incident_context = 'EC Addl.'
            where incident_id = p_incident_id;
        exception
            when others then
              gc_err_msg    := 'error while updating file label. '||sqlerrm;
               Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.Encrypt_attachment'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
              gc_err_status := 'FAILED';
        end;
        end if;   
    else
        gc_err_status := 'FAILED';
        Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.Encrypt_attachment'
                        ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                         ,p_error_msg          =>  gc_err_msg
                          );
    end if;  /** gc_file_key_lable **/
     
    END LOOP;
    commit;
    CLOSE sel_file_csr;
END encrypt_attachment;

/*******************************************************************************/
FUNCTION PCARD_DECRYPT (P_SR_NUMBER IN VARCHAR2)
RETURN VARCHAR2 IS

BEGIN
  
  begin
   select incident_attribute_6,
          incident_attribute_14
     into gc_encrypted_val,
          gc_key_lable
   from cs_incidents
   where incident_number = p_sr_number;
  exception
    when others then
       gc_key_lable := null;
  end;
  
  IF gc_key_lable is not null then
    
        APPS.XX_OD_SECURITY_KEY_PKG.DECRYPT(
            p_module         => gc_module,
            p_key_label      => gc_key_lable,
            p_algorithm      => 'AES',
            p_encrypted_val  => gc_encrypted_val,
            x_decrypted_val  => gc_decrypted_val,
            x_error_message  => gc_err_msg,
            P_FORMAT         => 'BASE64'
            );            
  END IF;
    RETURN gc_decrypted_val;
END;


/*******************************************************************************/
PROCEDURE PCARD_DECRYPT_FILE (P_REQUEST_ID IN VARCHAR2)
IS 

l_file_decrypt_val    BLOB;
 

   CURSOR sel_file_csr IS
    select lb.file_data , lb.file_id,
           lb.program_tag
    from   fnd_attached_documents dc,
           fnd_documents dt,
           fnd_lobs lb
    where lb.file_id = dt.media_id
    and   dt.document_id = dc.document_id
    and   dc.entity_name = 'CS_INCIDENTS'
    and   lb.program_tag is not null 
    and   dc.pk1_value = p_request_id;
    
    l_file_rec    sel_file_csr%ROWTYPE;
    
BEGIN
  /* 
  begin
   select incident_attribute_14
     into gc_file_key_lable
   from cs_incidents
   where incident_id = to_number(p_request_id);
  exception
    when others then
       gc_file_key_lable := null;
  end;  */
  
   BEGIN
      OPEN sel_file_csr;
      LOOP
      FETCH sel_file_csr INTO l_file_rec;
      EXIT when sel_file_csr%NOTFOUND;
      
      gc_file_key_lable := l_file_rec.program_tag;
      
          APPS.XX_OD_SECURITY_KEY_PKG.DECRYPT_BLOB(
                 x_out_val         => l_file_decrypt_val,
                 x_error_message   => gc_err_msg,
                 p_module          => gc_module,
                 p_key_label       => gc_file_key_lable,
                 p_in_val          => l_file_rec.file_data
                  );
          IF l_file_decrypt_val IS NOT NULL THEN
             BEGIN
                UPDATE FND_LOBS
                SET FILE_DATA   = l_file_decrypt_val,
                    PROGRAM_TAG = NULL
                WHERE FILE_ID = L_FILE_REC.FILE_ID;
             EXCEPTION
                WHEN OTHERS THEN
                  gc_err_msg    := 'error '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_PCARD_PKG.PCARD_DECRYPT_FILE'
                            ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                            ,p_error_msg          =>  gc_err_msg
                            );
                  gc_err_status := 'FAILED';
              END;
         
          END IF; /** l_file_decrypt_val **/  
       
      END LOOP;
      CLOSE sel_file_csr;
      commit;
    END;
    
END PCARD_DECRYPT_FILE;

/**************************************************************
***************************************************************/
END;

/
show errors;
exit;