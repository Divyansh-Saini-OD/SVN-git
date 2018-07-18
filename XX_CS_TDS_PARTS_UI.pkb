create or replace
PACKAGE BODY XX_CS_TDS_PARTS_UI AS
/******************************************************************************************/
-- Raj Jagarlamudi -- TDS Parts UI Updates
/*****************************************************************************************/
PROCEDURE log_exception (
      p_object_id IN VARCHAR2
    , p_error_location IN VARCHAR2
    , p_error_message_code IN VARCHAR2
    , p_error_msg IN VARCHAR2
   )
IS
  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_CRM'
                                    , p_program_type                => 'Custom Messages'
                                    , p_program_name                => 'XX_CS_TDS_PARTS_PKG'
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => 'CSF'
                                    , p_error_location              => p_error_location
                                    , p_error_message_code          => p_error_message_code
                                    , p_error_message               => p_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => ln_user_id
                                    , p_last_updated_by             => ln_user_id
                                    , p_last_update_login           => ln_login
                                     );
   END log_exception;
/************************************************************************************************/
  PROCEDURE MAIN_PROC (P_SR_NUMBER IN VARCHAR2,
                     X_RETURN_STATUS IN OUT VARCHAR2,
                     X_RETURN_MSG     IN OUT VARCHAR2) AS
  
  ln_incident_id    number;
  ln_status_id      number;
  lc_receipt_flag   varchar2(1) := 'N';
  lc_sales_flag     varchar2(1) := 'N';
  lc_excess_flag    varchar2(1) := 'N';
  ln_user_id        number;
  ln_resp_appl_id    number   :=  514;
  ln_resp_id         number   := 21739;
  ln_obj_ver        number;
  lc_status         varchar2(25);
  x_msg_count	       NUMBER;
  x_interaction_id   NUMBER;
  x_workflow_process_id NUMBER;
  ln_msg_index       number;
  ln_msg_index_out   number;
  lr_service_request_rec   CS_ServiceRequest_PUB.service_request_rec_type;
  lt_notes_table           CS_SERVICEREQUEST_PUB.notes_table;
  lt_contacts_tab          CS_SERVICEREQUEST_PUB.contacts_table;
  lc_summary         varchar2(1000);
  lc_print_url       varchar2(1000) := FND_PROFILE.VALUE('XX_CS_TDS_PRINT_LINK');
  lc_message         varchar2(2000);
  lc_inv_flag        varchar2(1) := 'N';
  
  BEGIN
    -- received shipments
    BEGIN
      select received_shipment_flag,
             sales_flag 
      into   lc_receipt_flag,
             lc_sales_flag
      from  xx_cs_tds_parts
      where request_number = p_sr_number
      and   rownum < 2;
     EXCEPTION
       WHEN OTHERS THEN
          lc_receipt_flag := 'N';
          lc_sales_flag   := 'N';
     END;
     
     BEGIN
        select incident_id ,
              object_version_number
        into   ln_incident_id,
               ln_obj_ver
        from cs_incidents_all_b
        where incident_number = p_sr_number;
     EXCEPTION
       WHEN OTHERS THEN
         x_return_status := 'F';
         x_return_msg := 'Error while selecting incidentId '||sqlerrm;
     END;
    
    IF NVL(X_RETURN_STATUS, 'S') <> 'F' THEN 
     --USER ID
     
        begin
          select user_id
          into ln_user_id
          from fnd_user
          where user_name = 'CS_ADMIN';
        exception
          when others then
            x_return_status := 'F';
            x_return_msg    := 'Error while selecting userid '||sqlerrm;
        end;
        
    /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
     
     IF nvl(lc_receipt_flag,'N') = 'Y' then
        lc_status := 'Received Parts';
        lc_summary := 'Part Received from Nexicore';
        lr_service_request_rec.summary := lc_summary;
     END IF;
     
     IF nvl(lc_receipt_flag,'N') = 'R' then
      IF nvl(lc_sales_flag,'N') = 'Y' then
      
       BEGIN
        select 'Y' 
        into   lc_excess_flag
        from  xx_cs_tds_parts
        where request_number = p_sr_number
        and   nvl(excess_flag,'N') = 'Y'
        and   excess_quantity > 0
        and   rownum < 2;
       EXCEPTION
         WHEN OTHERS THEN
            lc_excess_flag := 'N';
       END;
       
       IF nvl(lc_excess_flag, 'N') = 'Y' then
       
        -- verify Invoice Process
        Begin
          select  'Y'
          into lc_inv_flag
          from ap_invoices_all apn,
               ap_invoice_distributions_all apd,
               po_distributions_all pod,
               po_headers_all poa
          where poa.po_header_id = pod.po_header_id
          and   pod.po_distribution_id = apd.po_distribution_id
          and   apd.invoice_id = apn.invoice_id  
          and   apn.invoice_type_lookup_code = 'STANDARD'
          and   poa.segment1 = p_sr_number
          and   rownum < 2;
        exception
            when others then
               lc_inv_flag := 'N';
        end; 
        IF lc_inv_flag = 'Y' then
            lc_status := 'Work Completed';
            lc_summary := 'Excess Parts Return Order Created.';
        else
            begin
              update xx_cs_tds_parts
              set attribute2 = 'P'
              where request_number = p_sr_number;
              
              commit;
            end;
            
            lc_status := 'Return Excess Parts';
            lc_summary := 'Invoice not received, waiting for return parts...';
        end if;
       else
         lc_status := 'Call Customer';
         lc_summary := 'Parts Replaced, Call Customer';
       end if;
       
        lr_service_request_rec.external_attribute_4 := lc_print_url||'key='||p_sr_number||'&format=printable';
        lr_service_request_rec.external_attribute_12 := null;
        lr_service_request_rec.summary := lc_summary;
      END IF; -- Sales Flag
     END IF;  -- Receipt flag
     
       BEGIN
          SELECT incident_status_id,
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = lc_status ;
        EXCEPTION
          WHEN OTHERS THEN
            null;
        END;
        
       IF LN_STATUS_ID IS NOT NULL THEN
        lr_service_request_rec.status_id   := ln_status_id;
        /********************************************************************
         -- Update SR
         *********************************************************************/
         
         /*************************************************************************
           -- Add notes
          ************************************************************************/
            lt_notes_table(1).note        := lc_message ;
            lt_notes_table(1).note_detail := lc_message;
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
            x_msg_data               => x_return_msg,
            p_request_id             => ln_incident_id,
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
               FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
                  FND_MSG_PUB.Get(p_msg_index     => j,
                                  p_encoded       => 'F',
                                  p_data          => x_return_msg,
                                  p_msg_index_out => ln_msg_index_out);
               END LOOP;
            ELSE      --Only one error
               FND_MSG_PUB.Get(
                  p_msg_index     => 1,
                  p_encoded       => 'F',
                  p_data          => x_return_msg,
                  p_msg_index_out => ln_msg_index_out);
      
            END IF;
            
            lc_message := 'Update the SR ' || SQLERRM;
                 log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_UI.MAIN_PROC'
                            , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                            , p_error_msg               => lc_message
                             );
        END IF;
                             
     END IF;
        
      /***********************************************************************
       -- Update SR
       ***********************************************************************/
      /*  CS_SERVICEREQUEST_PUB.Update_Status
                (p_api_version		     => 2.0,
                p_init_msg_list	        => FND_API.G_TRUE,
                p_commit		            => FND_API.G_FALSE,
                x_return_status	        => x_return_status,
                x_msg_count	            => x_msg_count,
                x_msg_data		          => x_return_msg,
                p_resp_appl_id	        => ln_resp_appl_id,
                p_resp_id		            => ln_resp_id,
                p_user_id		            => ln_user_id,
                p_login_id		          => NULL,
                p_request_id		        => ln_incident_id,
                p_request_number	        => p_sr_number,
                p_object_version_number   => ln_obj_ver,
                p_status_id	 	          => ln_status_id,
                p_status		            => lc_status,
                p_closed_date		        => SYSDATE,
                p_audit_comments	        => NULL,
                p_called_by_workflow	  => NULL,
                p_workflow_process_id	  => NULL,
                p_comments		          => NULL,
                p_public_comment_flag	  => NULL,
                x_interaction_id	       => x_interaction_id );

            COMMIT;
           IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                --Display all the error messages
                  FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                          FND_MSG_PUB.Get(
                                    p_msg_index => j,
                                    p_encoded => 'F',
                                    p_data => x_return_msg,
                                    p_msg_index_out => ln_msg_index_out);
      
                       -- DBMS_OUTPUT.PUT_LINE(x_msg_data);
                  END LOOP;
                ELSE
                            --Only one error
                        FND_MSG_PUB.Get(
                                    p_msg_index => 1,
                                    p_encoded => 'F',
                                    p_data => x_return_msg,
                                    p_msg_index_out => ln_msg_index_out);
                        --DBMS_OUTPUT.PUT_LINE(x_msg_data);
                        --DBMS_OUTPUT.PUT_LINE(ln_msg_index_out);
                END IF;
                
                x_return_msg := x_return_msg;
            END IF;

           IF lc_summary is not null then 
            begin
              update cs_incidents
              set summary = lc_summary
              where incident_id = ln_incident_id;
              
              commit;
            EXCEPTION
              WHEN OTHERS THEN
                 lc_message := 'Error updating summary ' || SQLERRM;
                 log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_UI.MAIN_PROC'
                           , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                            , p_error_msg               => lc_message
                             );
           end;
          
           end if;
           */
      END IF; -- INCIDENT ID
            
  END MAIN_PROC;

END XX_CS_TDS_PARTS_UI;
/
show errors;
exit;