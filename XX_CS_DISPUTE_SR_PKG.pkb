create or replace
PACKAGE BODY "XX_CS_DISPUTE_SR_PKG" AS
 /****************************************************************************
  *
  * Program Name : XX_CS_DISPUTE_SR_PKG
  * Language     : PL/SQL
  * Description  : Package to maintain dispute Requests.
  * History      :
  *
  * WHO             WHAT                                    WHEN
  * --------------  --------------------------------------- ---------------
  * Raj Jagarlamudi Initial Version                         1/7/09
  * Manikant Kasu   Made code changes as per GSCC R12.2.2   1/25/16
  *                 Compliance 
  * Havish Kasina   Defect 39255 for 12.2 retrofit          9/8/16
  ****************************************************************************/
GC_RETURN_STATUS  VARCHAR2(1)     := 'S';
GC_RETURN_MSG     VARCHAR2(3000)  := null;
GN_REQUEST_ID     NUMBER          := null;
GN_REQUEST_NUM    NUMBER          := null;
GC_ACCT_TYPE      VARCHAR2(50)    := null;
GC_AOPS_ID        VARCHAR2(25)    := null;
GN_USER_ID        NUMBER          := null;
GC_DRT_ID         VARCHAR2(50)    := null;
gn_resp_appl_id   number := 514;
gn_resp_id        number := 21739;

/*****************************************************************************/
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
     ,p_program_name            => 'XX_CS_DISPUTE_SR_PKG'
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
-- Get Resources
/***************************************************************************/
PROCEDURE GET_RESOURCE (P_REQ_TYPE_ID     IN NUMBER,
                        P_PROBLEM_CODE    IN VARCHAR2,
                        P_REQUEST_ID      IN NUMBER,
                        P_CHANNEL         IN VARCHAR2,
                        X_GROUP_ID        IN OUT NUMBER,
                        X_GROUP_TYPE      IN OUT  NOCOPY VARCHAR2,
                        X_RETURN_STATUS   IN OUT  NOCOPY VARCHAR2,
                        X_RETURN_MESG     IN OUT  NOCOPY VARCHAR2)
IS
lr_TerrServReq_Rec      XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
lt_TerrResource_tbl     JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
lx_msg_count            NUMBER;
lx_msg_data             VARCHAR2(2000);
lx_msg_index_out        NUMBER;
lx_return_status        VARCHAR2(1);
BEGIN
         /************************************************************************
                -- Get Resources
           *************************************************************************/
              lr_TerrServReq_Rec.service_request_id   := p_request_id;
              lr_TerrServReq_Rec.incident_type_id     := p_req_type_id;
              lr_TerrServReq_Rec.problem_code         := p_problem_code;
              lr_TerrServReq_Rec.sr_creation_channel  := p_channel;
          /*************************************************************************************************************/
                     XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
                                     p_init_msg_list      => FND_API.G_TRUE,
                                     p_TerrServReq_Rec    => lr_TerrServReq_Rec,
                                     p_Resource_Type      => NULL,
                                     p_Role               => null,
                                     x_return_status      => x_return_status,
                                     x_msg_count          => lx_msg_count,
                                     x_msg_data           => lx_msg_data,
                                     x_TerrResource_tbl   => lt_TerrResource_tbl);


                       -- Check errors
                    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                      IF (FND_MSG_PUB.Count_Msg > 1) THEN
                      --Display all the error messages
                        FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                FND_MSG_PUB.Get(
                                          p_msg_index => j,
                                          p_encoded => 'F',
                                          p_data => lx_msg_data,
                                          p_msg_index_out => lx_msg_index_out);
                        END LOOP;
                      ELSE
                                  --Only one error
                              FND_MSG_PUB.Get(
                                          p_msg_index => 1,
                                          p_encoded => 'F',
                                          p_data => lx_msg_data,
                                          p_msg_index_out => lx_msg_index_out);
                      END IF;
                      X_RETURN_MESG := lx_msg_data;
                    END IF;

                    /****************************************************************************/
                     IF lt_TerrResource_tbl.count > 0 THEN
                        x_group_id       := lt_TerrResource_tbl(1).resource_id;
                        x_group_type     := lt_TerrResource_tbl(1).resource_type;

                      end if;

END;
/**************************************************************************/
  -- CREATE_SR
/**************************************************************************/
PROCEDURE CREATE_SR ( P_DISPUTE_ID     IN NUMBER,
                      P_TRX_ID         IN NUMBER,
                      P_TRX_NUMBER     IN VARCHAR2,
                      P_PROBLEM_CODE   IN VARCHAR2,
                      P_DESCRIPTION    IN VARCHAR2,
                      P_NOTES          IN VARCHAR2,
                      P_USER_ID        IN NUMBER,
                      P_SALES_REP_ID   IN NUMBER,
                      P_ORDER_NUM      IN VARCHAR2,
                      P_WAREHOUSE_NUM  IN VARCHAR2,
                      P_CUSTOMER_ID    IN NUMBER,
                      X_REQUEST_NUM    IN OUT NOCOPY VARCHAR2,
                      X_REQUEST_ID     IN OUT NOCOPY VARCHAR2,
                      X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                      X_MSG_DATA       IN OUT NOCOPY VARCHAR2)
IS
lx_msg_count            NUMBER;
lx_msg_data             VARCHAR2(2000);
lx_request_id           NUMBER;
lx_request_number       VARCHAR2(50);
lx_interaction_id       NUMBER;
lx_workflow_process_id  NUMBER;
lx_msg_index_out        NUMBER;
lx_return_status        VARCHAR2(1);
lr_service_request_rec  CS_ServiceRequest_PUB.service_request_rec_type;
lt_notes_table          CS_SERVICEREQUEST_PUB.notes_table;
lt_contacts_tab         CS_SERVICEREQUEST_PUB.contacts_table;
ln_req_type_id          NUMBER;
lc_user_name            VARCHAR2(150);
lc_sales_email          VARCHAR2(150);
ln_sales_rs_id           number;
lc_sales_type           varchar2(100);
lc_subject              varchar2(250);
lc_descr                varchar2(3000);
ln_return_code          number;
lc_notes                varchar2(3000);
BEGIN

         GC_RETURN_MSG := 'Befor Create Distpute SR : '|| P_DISPUTE_ID;
         Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                        ,p_error_message_code =>   'XX_CS_0001_CREATE_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG);

     cs_servicerequest_pub.initialize_rec(lr_service_request_rec);

      BEGIN
        SELECT INCIDENT_TYPE_ID,
		       business_process_id
        INTO LN_REQ_TYPE_ID,
		     lr_service_request_rec.business_process_id
        FROM CS_INCIDENT_TYPES_VL
        WHERE NAME = DECODE(GC_ACCT_TYPE, 'NATIONAL','NA Credit Dispute','BSD Credit Dispute')
        AND NAME IN ('NA Credit Dispute','BSD Credit Dispute');
      EXCEPTION
       WHEN OTHERS THEN
	       lr_service_request_rec.business_process_id := null;
           X_RETURN_STATUS := 'F';
           X_MSG_DATA  := 'Request Type is not valid';
      END;

      IF P_SALES_REP_ID IS NOT NULL THEN
          BEGIN
            select resource_id, email_address 
            into ln_sales_rs_id, lc_sales_email
            from jtf_rs_salesreps
            where salesrep_id = p_sales_rep_id
            and end_date_active is null;
          exception
            when others then
               lc_sales_email := null;
          END;
          
          IF LC_SALES_EMAIL IS NOT NULL THEN
            BEGIN
               SELECT rr.role_name
               INTO  lc_sales_type
               FROM  jtf_rs_defresroles_vl rr
               WHERE rr.role_resource_id = ln_sales_rs_id
               and   rr.delete_flag = 'N'
               and   rr.res_rl_end_date is null
               and   rr.role_name like 'TAM%'
               and   rownum < 2;
            EXCEPTION
             WHEN OTHERS THEN
                 lc_sales_type := NULL;
            END;
          END IF;
          
          lr_service_request_rec.sr_creation_channel  := 'WEB';
          
          IF (P_PROBLEM_CODE IN ('BT', 'FRE', 'PRC') )THEN
            IF LC_SALES_TYPE LIKE 'TAM%' THEN
               lr_service_request_rec.sr_creation_channel  := 'PHONE';
               LC_SALES_TYPE := 'TAM';
            ELSIF LC_SALES_EMAIL IS NULL THEN
                lr_service_request_rec.sr_creation_channel  := 'EMAIL';
               LC_SALES_TYPE := 'TAM';
            END IF;
          END IF;
      END IF;

    IF NVL(X_RETURN_STATUS,'S') = 'S' THEN   -- Sales rep email id check

   /*     GC_RETURN_MSG := 'Additional Info  : '|| p_order_num|| ' '||p_sales_rep_id||' '||lc_sales_email;
         Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                        ,p_error_message_code =>   'XX_CS_0002_DFF_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG); */

        BEGIN
          -- Populate the SR Record type
          lr_service_request_rec.request_date         := sysdate;
          lr_service_request_rec.type_id              := ln_req_type_id;
          lr_service_request_rec.status_id            := 1;
          lr_service_request_rec.severity_id          := 2;
          lr_service_request_rec.problem_code         := p_problem_code;
          lr_service_request_rec.summary              := substr(p_description,1,239);
          lr_service_request_rec.caller_type          := 'ORGANIZATION';
          lr_service_request_rec.customer_id          := p_customer_id;
          lr_service_request_rec.verify_cp_flag       := 'N';
          lr_service_request_rec.creation_program_code := 'IRECEIVABLES';
          lr_service_request_rec.error_code           := GC_DRT_ID;
          lr_service_request_rec.request_context      := 'DRT Addl';
          lr_service_request_rec.request_attribute_1  := substr(p_order_num,1,9);
          lr_service_request_rec.request_attribute_2  := substr(p_order_num,10,3);
          lr_service_request_rec.request_attribute_12 := p_dispute_id;
          lr_service_request_rec.request_attribute_4  := p_user_id;
          lr_service_request_rec.request_attribute_5  := p_sales_rep_id;
          lr_service_request_rec.request_attribute_3  := lc_sales_email;
          lr_service_request_rec.request_attribute_10 := 'OD ST CAL';
          lr_service_request_rec.request_attribute_9  := gc_aops_id;
        EXCEPTION
          WHEN OTHERS THEN
            X_RETURN_STATUS := 'F';
            X_MSG_DATA := 'Error while populating addl.Info';
        END;

           /*******************************************************************************
            -- Notes table
            *******************************************************************************/
            lc_notes := 'Requester Comments: '||p_notes||' Approver Comments: '||p_description;
         BEGIN
            IF length(lc_notes) > 2000 then
              lt_notes_table(1).note        := substr(lc_notes,1,1500);
              lt_notes_table(1).note_detail := lc_notes;
            else
              lt_notes_table(1).note        := lc_notes;
            end if;
              lt_notes_table(1).note_type   := 'GENERAL';
          EXCEPTION
            WHEN OTHERS THEN
              X_RETURN_STATUS := 'F';
              X_MSG_DATA := 'Error while populating notes table';
          END;

          BEGIN
              GET_RESOURCE(lr_service_request_rec.type_id,
                            lr_service_request_rec.problem_code,
                            lx_request_id,
                            lr_service_request_rec.sr_creation_channel,
                            lr_service_request_rec.owner_group_id,
                            lr_service_request_rec.group_type,
                            lx_return_status,
                            lx_msg_data);

                       X_RETURN_STATUS := lx_return_status;
                       X_MSG_DATA      := lx_msg_data;
           EXCEPTION
              WHEN OTHERS THEN
                X_RETURN_STATUS := 'F';
                X_MSG_DATA := 'Error while getting resource '|| lx_msg_data;
                Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                        ,p_error_message_code =>   'XX_CS_0003_RESOURCE_ERR'
                        ,p_error_msg          =>  X_MSG_DATA);
            END;

       /*   GC_RETURN_MSG := 'Resource Group  : '|| lr_service_request_rec.owner_group_id;
            Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                        ,p_error_message_code =>   'XX_CS_0003_Resource_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG);   */

           IF NVL(X_RETURN_STATUS,'S') = 'S' THEN  -- Create SR

              cs_servicerequest_pub.Create_ServiceRequest (
                        p_api_version => 2.0,
                        p_init_msg_list => FND_API.G_TRUE,
                        p_commit => FND_API.G_FALSE,
                        x_return_status => lx_return_status,
                        x_msg_count => lx_msg_count,
                        x_msg_data => lx_msg_data,
                        p_resp_appl_id => gn_resp_id,
                        p_resp_id => gn_resp_appl_id,
                        p_user_id => gn_user_id,
                        p_login_id => NULL,
                        p_request_id => NULL,
                        p_request_number => NULL,
                        p_service_request_rec => lr_service_request_rec,
                        p_notes => lt_notes_table,
                        p_contacts => lt_contacts_tab,
                        x_request_id => lx_request_id,
                        x_request_number => lx_request_number,
                        x_interaction_id => lx_interaction_id,
                        x_workflow_process_id => lx_workflow_process_id );

                IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                    IF (FND_MSG_PUB.Count_Msg > 1) THEN
                    --Display all the error messages
                            FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                            FND_MSG_PUB.Get(
                            p_msg_index => j,
                            p_encoded => 'F',
                            p_data => lx_msg_data,
                            p_msg_index_out => lx_msg_index_out);

                            DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                            END LOOP;
                    ELSE
                          --Only one error
                          FND_MSG_PUB.Get(
                          p_msg_index => 1,
                          p_encoded => 'F',
                          p_data => lx_msg_data,
                          p_msg_index_out => lx_msg_index_out);
                          DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                          DBMS_OUTPUT.PUT_LINE(lx_msg_index_out);
                    END IF;
                END IF;
              
                IF LC_SALES_TYPE <> 'TAM' then 
                -- Send mail to Account Manager
                 IF (P_PROBLEM_CODE IN ('BT', 'FRE', 'PRC')
                      AND LX_REQUEST_NUMBER IS NOT NULL ) THEN

                      lc_subject := 'Approval for Dispute : '||p_dispute_id;
                      lc_descr   := p_description||' for Customer: '||gc_aops_id ||' Order : '||p_order_num;

                  /*    gc_return_msg := 'Before calling email '||lc_subject;

                       Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                        ,p_error_message_code =>   'XX_CS_0003_SENDMAIL_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG);   */

                  begin
                      XX_CS_MESG_PKG.send_email (sender    => 'SVC-CallCenter@officedepot.com',
                                            recipient      => lc_sales_email,
                                            cc_recipient   => null ,
                                            bcc_recipient  => null ,
                                            subject        => lc_subject,
                                            message_body   => lc_descr,
                                            p_message_type => 'INFO',
                                            IncidentNum    => lx_request_id,
                                            return_code    => ln_return_code );
                    exception
                      when others then
                        X_MSG_DATA := 'Error while sending mail '|| ln_return_code;
                        Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.CREATE_SR'
                                      ,p_error_message_code =>   'XX_CS_0003_SEND_ERR'
                                       ,p_error_msg          =>  X_MSG_DATA);
                    END;

                  END IF;

                END IF; --TAM type check.
                
                x_return_status := lx_return_status;
                x_msg_data      := lx_msg_data;
                x_request_num   := lx_request_number;
    END IF;   -- Create SR
   END IF;  -- Sales rep email id check
  exception
  when others then
    X_RETURN_STATUS := 'F';
    X_MSG_DATA      := 'Error while creating SR'||sqlerrm;
END CREATE_SR;
/**************************************************************************/
  -- UPDATE_SR
/**************************************************************************/

PROCEDURE UPDATE_SR (P_REQUEST_ID     IN NUMBER,
                     P_NOTES          IN VARCHAR2,
                     X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                     X_MSG_DATA       IN OUT NOCOPY VARCHAR2)
IS

   lx_msg_count                NUMBER;
   lx_msg_data                 VARCHAR2(2000);
   lx_request_id               NUMBER;
   lx_request_number           VARCHAR2(50);
   lx_interaction_id           NUMBER;
   lx_workflow_process_id      NUMBER;
   lx_msg_index_out            NUMBER;
   lx_return_status            VARCHAR2(1);
   ln_obj_ver                  NUMBER ;
   ln_type_id                  NUMBER;
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;

begin
        GC_RETURN_MSG := 'Befor Update SR : '|| GN_REQUEST_ID;
         Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.UPDATE_SR'
                        ,p_error_message_code =>   'XX_CS_0001_UPDATE_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG);

     cs_servicerequest_pub.initialize_rec(lr_service_request_rec);
      BEGIN
        SELECT INCIDENT_TYPE_ID
        INTO LN_TYPE_ID
        FROM CS_INCIDENT_TYPES_TL
        WHERE NAME = 'BSD Credit Dispute';
      EXCEPTION
       WHEN OTHERS THEN
           X_RETURN_STATUS := 'F';
           X_MSG_DATA  := 'Error while selecting type';
           GC_RETURN_MSG := 'In Update Proc '||x_return_status ||' '||x_msg_data;
           Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.UPDATE_SR'
                        ,p_error_message_code =>   'XX_CS_0002_UPDATE_ERR'
                        ,p_error_msg          =>  GC_RETURN_MSG);
      END;
    IF  NVL(X_RETURN_STATUS,'S') = 'S' THEN
          
          lr_service_request_rec.type_id         := ln_type_id;
          lr_service_request_rec.problem_code    := null;
          lr_service_request_rec.status_id       := 1;
          lr_service_request_rec.owner_id        := null;
          lr_service_request_rec.owner_group_id  := null;
          --lr_service_request_rec.summary         := 'Credit Memo Request';

          GET_RESOURCE(lr_service_request_rec.type_id,
                       lr_service_request_rec.problem_code,
                       p_request_id,
                       lr_service_request_rec.sr_creation_channel,
                       lr_service_request_rec.owner_group_id,
                       lr_service_request_rec.group_type,
                       x_return_status,
                       x_msg_data);

        /************************************************************************
          -- Get Object version
          *********************************************************************/
           BEGIN
           SELECT object_version_number
           INTO ln_obj_ver
           FROM   cs_incidents_all_b
           WHERE  incident_id = p_request_id;
          EXCEPTION
            WHEN OTHERS THEN
              ln_obj_ver := 2;
           END;
         /*************************************************************************
             -- Add notes
          ************************************************************************/
                  IF length(p_notes) > 2000 then
                    lt_notes_table(1).note        := substr(p_notes,1,1500);
                    lt_notes_table(1).note_detail := p_notes;
                  else
                    lt_notes_table(1).note        := p_notes;
                  end if;
                    lt_notes_table(1).note_type   := 'GENERAL';

         /**************************************************************************
             -- Update SR
          *************************************************************************/

         cs_servicerequest_pub.Update_ServiceRequest (
            p_api_version            => 2.0,
            p_init_msg_list          => FND_API.G_TRUE,
            p_commit                 => FND_API.G_FALSE,
            x_return_status          => lx_return_status,
            x_msg_count              => lx_msg_count,
            x_msg_data               => lx_msg_data,
            p_request_id             => p_request_id,
            p_request_number         => NULL,
            p_audit_comments         => NULL,
            p_object_version_number  => ln_obj_ver,
            p_resp_appl_id           => gn_resp_appl_id,
            p_resp_id                => gn_resp_appl_id,
            p_last_updated_by        => gn_user_id,
            p_last_update_login      => NULL,
            p_last_update_date       => sysdate,
            p_service_request_rec    => lr_service_request_rec,
            p_notes                  => lt_notes_table,
            p_contacts               => lt_contacts_tab,
            p_called_by_workflow     => FND_API.G_FALSE,
            p_workflow_process_id    => NULL,
            x_workflow_process_id    => lx_workflow_process_id,
            x_interaction_id         => lx_interaction_id   );

            commit;

        /*    GC_RETURN_MSG := 'After UPDATE SR '||lx_return_status ||' '|| lx_msg_data;
             Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.UPDATE_SR'
                      ,p_error_message_code =>   'XX_CS_0003_UPDATE_SR_LOG'
                      ,p_error_msg          =>  GC_RETURN_MSG);  */

             IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                   --Display all the error messages
                   FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
                      FND_MSG_PUB.Get(p_msg_index     => j,
                                      p_encoded       => 'F',
                                      p_data          => lx_msg_data,
                                      p_msg_index_out => lx_msg_index_out);
                   END LOOP;
                ELSE      --Only one error
                   FND_MSG_PUB.Get(
                      p_msg_index     => 1,
                      p_encoded       => 'F',
                      p_data          => lx_msg_data,
                      p_msg_index_out => lx_msg_index_out);

                END IF;
             END IF;
    END IF;
   x_return_status := lx_return_status;
   x_msg_data      := lx_msg_data;

exception
   when others then
      X_RETURN_STATUS := 'F';
      X_MSG_DATA      := 'Error while updating SR'||sqlerrm;
END UPDATE_SR;
/**************************************************************************/
  -- Main_proc
/**************************************************************************/
PROCEDURE MAIN_PROC(P_DISPUTE_ID    IN NUMBER,
                    P_TRX_ID        IN NUMBER,
                    P_TRX_NUMBER    IN VARCHAR2,
                    P_PROBLEM_CODE  IN VARCHAR2,
                    P_DESCRIPTION   IN VARCHAR2,
                    P_NOTES         IN VARCHAR2,
                    P_USER_NAME     IN VARCHAR2,
                    P_CUSTOMER_ID   IN NUMBER,
                    X_REQUEST_NUM   IN OUT NOCOPY NUMBER,
                    X_RETURN_MSG    IN OUT NOCOPY VARCHAR2)
IS
ln_sales_rep_id     number;
lc_order_num        varchar2(50);
lc_warehouse_num    varchar2(50);
ln_party_id         number;
lc_problem_code     varchar2(25);
lc_problem_descr    varchar2(1000);
lc_drt_user_id      number;

BEGIN
      GN_REQUEST_ID     := null;
      GN_REQUEST_NUM    := null;
      GC_ACCT_TYPE      := null;
      GC_AOPS_ID        := null;
      GN_USER_ID        := null;
      GC_DRT_ID         := null;
      GC_RETURN_STATUS  := 'S';

      GC_RETURN_MSG   := 'Started the process for Dispute : '||p_dispute_id;
      Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.MAIN_PROC'
                      ,p_error_message_code =>   'XX_CS_0001_START_LOG'
                      ,p_error_msg          =>  GC_RETURN_MSG);
      /*******************************************************************************/
      -- Verify the reason code
      /******************************************************************************/
       begin
          select lookup_code, description
          into lc_problem_code, lc_problem_descr
          from fnd_lookup_values
          where lookup_type = 'REQUEST_PROBLEM_CODE'
          and lookup_code = p_problem_code;
       exception
          when others then
                gc_return_status  := 'F';
                GC_RETURN_MSG     := ' Reason Code not exists '||p_problem_code;
      end;

      /********************************************************************/
      -- Check the FND DRT user Name
      /*******************************************************************/
      BEGIN
        SELECT USER_ID
        INTO   LC_DRT_USER_ID
        FROM   FND_USER
        WHERE  USER_NAME = P_USER_NAME;
        GC_DRT_ID := P_USER_NAME;
      EXCEPTION
        WHEN OTHERS THEN
           gc_return_status := 'F';
           GC_RETURN_MSG  := 'User Id in not valid. '||P_USER_NAME;
      END;

  IF  NVL(GC_RETURN_STATUS,'S') = 'S' THEN
      /*******************************************************************************/
      --Customer Support Initialization USER
      /*******************************************************************************/
      begin
         select user_id
         into gn_user_id
         from fnd_user
         where user_name = 'CS_ADMIN';
      exception
      when others then
            gc_return_status := 'F';
            GC_RETURN_MSG    := ' Error while selecting userid '||sqlerrm;
      end;
       fnd_global.apps_initialize(gn_user_id,gn_resp_id,gn_resp_appl_id);
       -- Verify the request created
       begin
        select incident_id,
               incident_number
          into gn_request_id,
               gn_request_num
        from cs_incidents_all_b
        where creation_program_code in ( 'IRECEIVABLES' , 'CSZSRC')
        and   incident_attribute_12 = to_char(p_dispute_id)
        and   problem_code in ('BT', 'FRE', 'PRC');
       exception
        when others then
          gn_request_id   := null;
          gn_request_num  := null;
       end;

      IF gn_request_id is null then
         -- Verify the account type
         begin
            select party_id,
                   sales_channel_code,
                   substr(orig_system_reference,1,8)
            into  ln_party_id,
                  gc_acct_type,
                  gc_aops_id
            from hz_cust_accounts
            where cust_account_id = p_customer_id;
         exception
           when others then
                gc_return_status := 'F';
                gc_return_msg   := 'error while selecting party id '||sqlerrm;
         end;

            lc_order_num := P_TRX_NUMBER;
        -- Getting sales rep id, order number, warehouse id
        IF P_PROBLEM_CODE IN ('BT', 'FRE', 'PRC') THEN
          begin
            select decode(primary_salesrep_id,-3,null,primary_salesrep_id)
            into   ln_sales_rep_id
            from   ra_customer_trx_all
            where  customer_trx_id = p_trx_id;
          exception
            when others then
                  ln_sales_rep_id := null;
          end;

          IF LN_SALES_REP_ID IS NULL THEN
              GC_RETURN_STATUS := 'F';
              GC_RETURN_MSG := 'Request can not send to Account Manager due to Sales Rep Id not exists';
          END IF;

          END IF;

          IF  NVL(GC_RETURN_STATUS,'S') = 'S' THEN
            -- Create SR
            CREATE_SR ( P_DISPUTE_ID     => P_DISPUTE_ID,
                        P_TRX_ID         => P_TRX_ID,
                        P_TRX_NUMBER     => P_TRX_NUMBER,
                        P_PROBLEM_CODE   => LC_PROBLEM_CODE,
                        P_DESCRIPTION    => nvl(p_description,lc_problem_descr),
                        P_NOTES          => P_NOTES,
                        P_USER_ID        => LC_DRT_USER_ID,
                        P_SALES_REP_ID   => LN_SALES_REP_ID,
                        P_ORDER_NUM      => LC_ORDER_NUM,
                        P_WAREHOUSE_NUM  => LC_WAREHOUSE_NUM,
                        P_CUSTOMER_ID    => LN_PARTY_ID,
                        X_REQUEST_NUM    => GN_REQUEST_NUM,
                        X_REQUEST_ID     => GN_REQUEST_ID,
                        X_RETURN_STATUS  => GC_RETURN_STATUS,
                        X_MSG_DATA       => GC_RETURN_MSG);

           END IF; -- Create SR
      else
            -- Update SR
            UPDATE_SR (P_REQUEST_ID     => GN_REQUEST_ID,
                       P_NOTES          => P_NOTES,
                       X_RETURN_STATUS  => GC_RETURN_STATUS,
                       X_MSG_DATA       => GC_RETURN_MSG);
      end if; -- Request Id
  END IF; -- Problem Code
      IF NVL(GC_RETURN_STATUS,'S') <> 'S' THEN
          X_RETURN_MSG := GC_RETURN_MSG;
          Log_Exception ( p_error_location     =>  'XX_CS_DISPUTE_SR_PKG.MAIN_PROC'
                        ,p_error_message_code =>   'XX_CS_0002_FAILED_LOG'
                        ,p_error_msg          =>  GC_RETURN_MSG);
      ELSE
          X_REQUEST_NUM := GN_REQUEST_NUM;
          X_RETURN_MSG  := 'Request is in progress';
      END IF;

END MAIN_PROC;
/**************************************************************************/

END XX_CS_DISPUTE_SR_PKG;
/
show errors;
exit;