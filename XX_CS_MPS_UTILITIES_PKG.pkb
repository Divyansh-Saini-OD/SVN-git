create or replace
PACKAGE BODY XX_CS_MPS_UTILITIES_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_MPS_UTILITIES_PKG                                  |
-- |                                                                   |
-- | Description: Wrapper package for UTILITY PROCS.                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       08-08-12   Raj Jagarlamudi  Initial draft version        |
-- |1.2       01-24-13   Raj Jagarlamudi  Commented the ship-to info   |
-- |1.3       06-24-13   Arun Gannarapu   Made changes to pass         |
-- |                                      p_auto_assign to SR API      |
-- |1.4       09-SEP-16  Havish Kasina    Defect39255 for 12.2 retrofit|
-- +===================================================================+
/*****************************************************************************
-- Log Messages
****************************************************************************/
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2
                         ,p_object_id          IN  VARCHAR2)
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
     ,p_program_name            => 'XX_CS_TDS_VEN_PKG'
     ,p_object_id               => null
     ,p_module_name             => 'MPS'
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
/*************************************************************************
-- Soap Request
**************************************************************************/
FUNCTION http_post ( url VARCHAR2, req_body varchar2)
RETURN VARCHAR2  AS

    soap_request      VARCHAR2(30000);
    soap_respond      VARCHAR2(30000);
    req               utl_http.req;
    resp              utl_http.resp;
    v_response_text   VARCHAR2(32767);
    x_resp            XMLTYPE;
    i                 integer;
    l_msg_data        varchar2(30000);
    lc_return_status  varchar2(100) := 'false';
    lc_conn_link      varchar2(3000);
    lc_message        varchar2(3000);


begin

     soap_request := '<?xml version = "1.0" encoding = "UTF-8"?>'||
                      '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '<soapenv:Header xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '</soapenv:Header>'||
                      '<soapenv:Body>'||req_body||
                      '</soapenv:Body>'||'</soapenv:Envelope>';

    --  dbms_output.put_line(url||soap_request);

      req := utl_http.begin_request(url,'POST','HTTP/1.1');
      utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
      utl_http.set_header(req,'Content-Length', length(soap_request));
      utl_http.set_header(req  , 'SOAPAction'  , 'process');
      utl_http.write_text(req, soap_request);

        resp := utl_http.get_response(req);
        utl_http.read_text(resp, soap_respond);

        lc_message := 'Response Received '||resp.status_code;

      utl_http.end_response(resp);

      x_resp := XMLType.createXML(soap_respond);

      l_msg_data := 'Req '||soap_request;

        x_resp := x_resp.extract('/soap:Envelop/soap:Body/child::node()'
                               ,'xmlns:soap="http://TargetNamespace.com/XMLSchema-instance"');

          l_msg_data := 'Res '||soap_respond;

         v_response_text := l_msg_data;

    return v_response_text;
end;
/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_NOTES_REC,
                       p_return_status        in out nocopy varchar2,
                       p_msg_data             in out nocopy varchar2)
IS

ln_api_version        number;
lc_init_msg_list    varchar2(1);
ln_validation_level    number;
lc_commit        varchar2(1);
lc_return_status    varchar2(1);
ln_msg_count        number;
lc_msg_data        varchar2(2000);
ln_jtf_note_id        number;
ln_source_object_id    number;
lc_source_object_code    varchar2(8);
lc_note_status          varchar2(8);
lc_note_type        varchar2(80);
lc_notes        varchar2(2000);
lc_notes_detail        varchar2(8000);
ld_last_update_date    Date;
ln_last_updated_by    number;
ld_creation_date    Date;
ln_created_by        number;
ln_entered_by           number;
ld_entered_date         date;
ln_last_update_login    number;
lt_note_contexts    JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
ln_msg_index        number;
ln_msg_index_out    number;
ln_ext_user             number;

begin
/************************************************************************
--Initialize the Notes parameter to create
**************************************************************************/
ln_api_version            := 1.0;
lc_init_msg_list        := FND_API.g_true;
ln_validation_level        := FND_API.g_valid_level_full;
lc_commit            := FND_API.g_true;
ln_msg_count            := 0;
/****************************************************************************
-- If ObjectCode is Party then Object_id is party id
-- If ObjectCode is Service Request then Object_id is Service Request ID
-- If ObjectCode is TASK then Object_id is Task id
****************************************************************************/
ln_source_object_id        := p_request_id;
lc_source_object_code        := 'SR';
lc_note_status            := 'E';  -- (P-Private, E-Publish, I-Public)
lc_note_type            := 'GENERAL';
lc_notes            := p_sr_notes_rec.notes;
lc_notes_detail            := p_sr_notes_rec.note_details;

begin
  ln_ext_user := translate(upper(p_sr_notes_rec.created_by),'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-', '0123456789');
exception
  when others then
    ln_ext_user := null;
end;

IF ln_ext_user is not null then
    ln_entered_by    := ln_ext_user;
else
    ln_entered_by    := FND_GLOBAL.user_id;
end if;
ld_entered_date            := SYSDATE;
/****************************************************************************
-- Initialize who columns
*****************************************************************************/
ld_last_update_date        := SYSDATE;
ln_last_updated_by        := FND_GLOBAL.USER_ID;
ld_creation_date        := SYSDATE;
ln_created_by            := FND_GLOBAL.USER_ID;
ln_last_update_login        := FND_GLOBAL.LOGIN_ID;
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
                      p_jtf_note_id            => ln_jtf_note_id,
                      p_entered_by            => ln_entered_by,
                      p_entered_date          => ld_entered_date,
                    p_source_object_id    => ln_source_object_id,
                    p_source_object_code    => lc_source_object_code,
                    p_notes            => lc_notes,
                    p_notes_detail        => lc_notes_detail,
                    p_note_type        => lc_note_type,
                    p_note_status        => lc_note_status,
                    p_jtf_note_contexts_tab => lt_note_contexts,
                    x_jtf_note_id        => ln_jtf_note_id,
                    p_last_update_date    => ld_last_update_date,
                    p_last_updated_by    => ln_last_updated_by,
                    p_creation_date        => ld_creation_date,
                    p_created_by        => ln_created_by,
                    p_last_update_login    => ln_last_update_login );

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
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lc_msg_data,
                              p_msg_index_out => ln_msg_index_out);
          END IF;
      END IF;
      p_msg_data          := lc_msg_data;
      p_return_status     := lc_return_status;

END CREATE_NOTE;
/********************************************************************************************/
 /***************************************************************************/
  PROCEDURE CREATE_SR (P_PARTY_ID       IN NUMBER,
                       P_SALES_NUMBER   IN VARCHAR2,
                       P_REQUEST_TYPE   IN VARCHAR2,
                       P_COMMENTS       IN VARCHAR2,
                       p_sr_req_rec     in out nocopy XX_CS_SR_REC_TYPE,
                       x_return_status  IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MSG     IN OUT NOCOPY VARCHAR2)
  AS

lx_msg_count                NUMBER;
lx_msg_data                 VARCHAR2(2000);
lx_request_id               NUMBER;
lx_request_number           VARCHAR2(50);
lx_interaction_id           NUMBER;
lx_workflow_process_id      NUMBER;
lx_msg_index_out            NUMBER;
lx_return_status            VARCHAR2(1);
lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
lx_sr_create_out_rec         cs_servicerequest_pub.sr_create_out_rec_type;
lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
ln_user_id                   number;
ln_resp_appl_id              number := 514;
ln_resp_id                   number := 21739;
ln_party_id                  number;
ln_cust_acct_number          number;
ln_contact_party_id          number;
ln_contact_point_id          number;
lc_contact_point_type        varchar2(100);
lc_primary_flag              varchar2(1);
lc_contact_type              varchar2(100);
lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
loop_counter                 number := 0;
ln_owner_id                  number;
i                            number;
ln_obligation_time           number;
ln_resolution_time           number;
ld_obligation_date           date;
ld_resolution_date           date;
ln_time_zone                 number;
ln_link_id                   number;
ln_incident_id               number;
ln_ebs_warehouse_id          number;
lc_item_catagory             varchar2(50);
lc_item_type                 varchar2(25);
lc_request_type              varchar2(100);
ln_request_type_id           number;
lc_type_link                 varchar2(100);
lc_group_name                varchar2(250);
lc_sku_numbers               varchar2(250);
lc_sku_descr                 varchar2(1000);
ln_quantity                  varchar2(50);
lc_vendor                    varchar2(250);
lc_route                     varchar2(50);
lc_dc_flag                   varchar2(1) := 'N';
lc_mail_flag                 varchar2(1) := 'N';
lc_sr_flag                   varchar2(1) := 'N';
lc_auto_assign               VARCHAR2(1) := 'N';
---
lc_sender                 VARCHAR2(250);
lc_recipient              VARCHAR2(250);
lc_subject                VARCHAR2(250);
lc_smtp_server            VARCHAR2(250);
ln_return_code            number;
ln_client_timeid          number := fnd_profile.value('CLIENT_TIMEZONE_ID');
ln_server_timeid          number := fnd_profile.value('SERVER_TIMEZONE_ID');
ln_time_id                number := 1;
ln_res_time               number := 0;
ld_delivery_date          date;
ln_delivery_time          number := 0;


BEGIN

/*******************************************************************************/
--Apps Initialization
/*******************************************************************************/
begin
   select user_id
   INTO LN_USER_ID
   from fnd_user
   WHERE USER_NAME = 'CS_ADMIN';
   x_return_status := 'S';
exception
when others then
      x_return_status := 'F';
      x_return_msg := ' Error while selecting userid '||sqlerrm;
END;

apps.fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);


IF (nvl(x_return_status,'S') = 'S') then -- (1)

    IF p_request_type = 'MPS Contract Request' then
      begin
        select hzp.party_type,
             null,
              hzp.party_id,
              hzp.party_number,
              null
        into lr_service_request_rec.caller_type,
             lr_service_request_rec.account_id,
             ln_party_id,
             lr_service_request_rec.customer_number,
             ln_cust_acct_number
        from hz_parties hzp
        where hzp.party_id = p_party_id;

        lr_service_request_rec.customer_id                := ln_party_id;
        lr_service_request_rec.incident_location_type     := 'HZ_PARTY_SITE';
      exception
       when no_data_found then
          x_return_status := 'F';
          x_return_msg := 'Customer not exists in EBS ';
        when others then
          x_return_status := 'F';
          x_return_msg := 'Error while selecing cust_account_id '||sqlerrm;
      END;

      LR_SERVICE_REQUEST_REC.BILL_TO_PARTY_ID           := LN_PARTY_ID;

    else
      begin
        select hzp.party_type,
              hzc.cust_account_id,
              hzp.party_id,
              hzp.party_number,
              hzc.cust_account_id
        into lr_service_request_rec.caller_type,
             lr_service_request_rec.account_id,
             ln_party_id,
             lr_service_request_rec.customer_number,
             ln_cust_acct_number
        from hz_parties hzp,
            hz_cust_accounts hzc
        where hzc.party_id = hzp.party_id
        and  hzp.party_id = p_party_id;

        lr_service_request_rec.customer_id                := ln_party_id;
        lr_service_request_rec.incident_location_type     := 'HZ_PARTY_SITE';
      exception
       when no_data_found then
          x_return_status := 'F';
          x_return_msg := 'Customer not exists in EBS ';
        when others then
          x_return_status := 'F';
          x_return_msg := 'Error while selecing cust_account_id '||sqlerrm;
      end;


      /*********************************************************************
         Bill to Site information
      **********************************************************************/
      lr_service_request_rec.bill_to_party_id           := ln_party_id;
      lr_service_request_rec.bill_to_account_id         := ln_cust_acct_number;
    IF ln_party_id is not null then -- (1) Customer check
       BEGIN
         select s1.party_site_id,
                s2.party_site_use_id,
                s1.party_site_id
          into  lr_service_request_rec.bill_to_site_id,
                lr_service_request_rec.bill_to_site_use_id,
                lr_service_request_rec.install_site_use_id
          from hz_party_sites s1,
               hz_party_site_uses s2
          where s1.party_site_id = s2.party_site_id
          and   s1.party_id = ln_party_id
          and   s2.primary_per_type = 'Y'
          and   s2.site_use_type = 'BILL_TO';
       EXCEPTION
          WHEN OTHERS THEN
             x_return_msg := 'Bill to site information not exists';
      END;
    end if;
       /*********************************************************************
         Ship to Site information
      **********************************************************************/
      lr_service_request_rec.ship_to_party_id           := ln_party_id;
      lr_service_request_rec.ship_to_account_id         := ln_cust_acct_number;
     /*
       BEGIN
          SELECT distinct hcs.site_use_id, hcs.cust_acct_site_id
          into  lr_service_request_rec.ship_to_site_id,
                lr_service_request_rec.ship_to_site_use_id
          FROM APPS.HZ_CUST_ACCOUNTS HCA
               , APPS.HZ_CUST_SITE_USES_ALL HCS
               , APPS.HZ_CUST_ACCT_SITES_ALL HCSA
           WHERE HCA.PARTY_ID                  = ln_party_id
             AND HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
             AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
             AND HCS.STATUS                    = 'A'
             AND HCS.SITE_USE_CODE             = 'SHIP_TO'
             AND HCS.SITE_USE_ID  =to_number(p_sr_req_rec.ship_to);
       EXCEPTION
         WHEN OTHERS THEN
           NULL;
      END; */
      /********************************************************************
         Selecting Contact Points.
      *********************************************************************/
       begin
          select  hzt.contact_point_id,
                  hzt.contact_point_id,
                  hzt.contact_point_type,
                  hzt.primary_flag,
                  hzt.contact_point_purpose
           INTO  ln_contact_party_id,
                ln_contact_point_id,
                lc_contact_point_type,
                lc_primary_flag,
                lc_contact_type
          from  hz_contact_points hzt
          where hzt.contact_point_id =  ln_party_id
          and   hzt.primary_flag = 'Y';

        exception
        when others then
          ln_contact_party_id := null;
      end;
     end if; -- (1) Customer check


-- checking party id exists or not
 IF (nvl(x_return_status,'S') = 'S') then
 /********************************************
  -- Request type attribute
  ********************************************/

  begin
    select attribute9,
	       business_process_id
    into lr_service_request_rec.request_context,
	     lr_service_request_rec.business_process_id
    from cs_incident_types_vl
    where incident_type_id = p_sr_req_rec.type_id;
  exception
    when others then
	  lr_service_request_rec.business_process_id := null;
	  lr_service_request_rec.request_context := null;
end;

/***********************************
-- Severity_id
************************************/
  begin
     select incident_severity_id
     into lr_service_request_rec.severity_id
     from cs_incident_severities_vl
     where name = 'Medium'
     and incident_subtype = 'INC';
  exception
     when others then
        x_return_status := 'F';
        x_return_msg := 'Error while selecing severity id '||sqlerrm;
  end;

  /*******************************************************************
  -- Urgency Id
  ******************************************************************/
   begin
      select incident_urgency_id
      into lr_service_request_rec.urgency_id
      from cs_incident_urgencies_vl
      where name = 'Major';
    exception
    when others then
          x_return_status := 'F';
          x_return_msg := 'Error while selecing urgency id '||sqlerrm;
    end;

     IF p_sr_req_rec.status_name is not null then
      begin
        select incident_status_id
        into lr_service_request_rec.status_id
        from cs_incident_statuses_tl
        where name = p_sr_req_rec.status_name;
      exception
        when others then
          -- x_return_msg := 'Error while selecting status id and status not updated';
          lr_service_request_rec.status_id  := 1; -- open status
      end;
   end if;

  /*****************************************************************************
  -- Populate the SR Record type
  ******************************************************************************/
  lr_service_request_rec.request_date             := sysdate;
  lr_service_request_rec.incident_occurred_date   := sysdate;
  lr_service_request_rec.type_id                  := p_sr_req_rec.type_id;
  ln_request_type_id                              := p_sr_req_rec.type_id;

--dbms_output.put_line('Time id '||lr_service_request_rec.time_zone_id||' date '||ld_resolution_date);
   -- lr_service_request_rec.status_id                := 1; -- open status
    lr_service_request_rec.creation_program_code    := 'SFDC-MPS';
    lr_service_request_rec.last_update_program_code := 'SFDC-MPS';
    lr_service_request_rec.verify_cp_flag           := 'N';
    lr_service_request_rec.sr_creation_channel      := upper(p_sr_req_rec.channel);
    lr_service_request_rec.last_update_channel      := upper(p_sr_req_rec.channel);
    lr_service_request_rec.problem_code             := p_sr_req_rec.problem_code;
    lr_service_request_rec.summary                  := substr(replace(p_sr_req_rec.comments,'//',''),1,79);
    lr_service_request_rec.language                 := 'US'; -- assign from ecomsite key.
    lr_service_request_rec.resource_type            := 'RS_EMPLOYEE';
    lr_service_request_rec.error_code               := p_sr_req_rec.user_id;
    lr_service_request_rec.obligation_Date          := ld_obligation_Date;
    lr_service_request_rec.exp_resolution_date      := ld_resolution_date;
    lr_service_request_rec.group_type               := 'RS_GROUP';

 IF p_request_type <> 'MPS Contract Request' then

    IF lr_service_request_rec.request_context is not null then

      lr_service_request_rec.request_attribute_3 := p_sr_req_rec.sales_rep_contact_ext; -- Serial No
      lr_service_request_rec.request_attribute_12 := p_sr_req_rec.csc_location; -- Device location
      lr_service_request_rec.request_attribute_4 := p_sr_req_rec.preferred_contact; -- Cost Center
      lr_service_request_rec.request_attribute_5 := p_sr_req_rec.contact_email; -- Model no
      lr_service_request_rec.request_attribute_6 := p_sr_req_rec.contact_fax; -- IP Address
      lr_service_request_rec.request_attribute_7 := p_sr_req_rec.contact_name; -- Device contact
      lr_service_request_rec.request_attribute_8 := p_sr_req_rec.contact_phone; -- Device contact phone
      lr_service_request_rec.request_attribute_13 := p_sr_req_rec.customer_sku_id; -- program
      lr_service_request_rec.request_attribute_10 := p_sr_req_rec.zz_flag; -- JIT

    end if;

  end if;
/*******************************************************************************/
-- Adhoc contact information
/*******************************************************************************/
lr_service_request_rec.employee_id := p_sr_req_rec.sales_rep_contact; -- sales rep id
lr_service_request_rec.incident_address2 := p_sr_req_rec.contact_phone;
lr_service_request_rec.incident_address3 := p_sr_req_rec.contact_email;
lr_service_request_rec.incident_address4 := p_sr_req_rec.contact_fax;

/*******************************************************************************
-- Notes table
*******************************************************************************/
IF length(p_sr_req_rec.comments) > 2000 then
  lt_notes_table(1).note        := substr(p_sr_req_rec.comments,1,1500);
  lt_notes_table(1).note_detail := p_sr_req_rec.comments;
else
  lt_notes_table(1).note        := p_sr_req_rec.comments;
end if;

 lt_notes_table(1).note_type   := 'GENERAL';

     --dbms_output.put_line('Org Type Id : '||p_sr_req_rec.type_id||' Fur Type Id '||ln_request_type_id);
     /************************************************************************
          -- Get Resources
     *************************************************************************/
       -- Commented by AG 
          /* lr_TerrServReq_Rec.service_request_id   := lx_request_id;
          lr_TerrServReq_Rec.party_id             := ln_party_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_request_type_id; */

          /*************************************************************************************************************/
        
       /* XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
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
          x_return_msg := lx_msg_data;
        END IF;

        --****************************************************************************
         IF lt_TerrResource_tbl.count > 0 THEN
        -- dbms_output.put_line('owner_group_id '||lt_TerrResource_tbl(1).resource_id);

            lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
            lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
        end if; */ -- Comment ended AG 

        IF lc_mail_flag = 'Y' then
            lr_service_request_rec.owner_group_id := null;
            lr_service_request_rec.group_type     := null;
            lc_auto_assign                        := 'N';
        ELSE
            lc_auto_assign                        := 'Y';
        end if;

      /*******************************************************************************
          Creating Service Request
      *******************************************************************************/
        IF (nvl(x_return_status,'S') = 'S') then
        
              apps.cs_servicerequest_pub.Create_ServiceRequest (
                                  p_api_version => 4.0,
                                  p_init_msg_list => FND_API.G_TRUE,
                                  p_commit => FND_API.G_FALSE,
                                  x_return_status => lx_return_status,
                                  x_msg_count => lx_msg_count,
                                  x_msg_data => lx_msg_data,
                                  p_resp_appl_id => ln_resp_appl_id,
                                  p_resp_id => ln_resp_id,
                                  p_user_id => ln_user_id,
                                  p_login_id => ln_user_id,
                                  --p_org_id => 204,
                                  p_request_id => NULL,
                                  p_request_number => NULL,
                                  p_service_request_rec => lr_service_request_rec,
                                  p_notes => lt_notes_table,
                                  p_contacts => lt_contacts_tab,
                                  p_auto_assign  => lc_auto_assign,
                                  p_auto_generate_tasks => 'N',
                                  x_sr_create_out_rec   => lx_sr_create_out_rec
                                  --p_default_contract_sla_ind => 'N',
                                --  x_request_id => lx_request_id,
                                --  x_request_number => lx_request_number,
                                --  x_interaction_id => lx_interaction_id,
                                --  x_workflow_process_id => lx_workflow_process_id 
                                );
                                
             lx_request_id     := lx_sr_create_out_rec.request_id;
             lx_request_number := lx_sr_create_out_rec.request_number;
          END IF;

    -- Check errors
    IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
          IF (FND_MSG_PUB.Count_Msg > 1) THEN
          --Display all the error messages
            FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                    FND_MSG_PUB.Get(
                              p_msg_index => j,
                              p_encoded => 'F',
                              p_data => lx_msg_data,
                              p_msg_index_out => lx_msg_index_out);
            END LOOP;
            x_return_msg := lx_msg_data;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lx_msg_data,
                              p_msg_index_out => lx_msg_index_out);
                x_return_msg := lx_msg_data;
          END IF;
      END IF;
          x_return_status             := lx_return_status;
          p_sr_req_rec.request_id     := lx_request_id;
          p_sr_req_rec.request_number := lx_request_number;

       /**************************************************************/
end if; -- Party id check

end if; -- status check (1)

exception
      when others then
        x_return_status   := 'F';
        x_return_msg      :=  x_return_msg;
END Create_SR;
 /****************************************************************************/

 procedure update_sr (P_REQUEST_ID     IN NUMBER,
                       P_COMMENTS       IN VARCHAR2,
                       P_REQ_TYPE       IN VARCHAR2,
                       P_SR_REQ_REC     IN OUT NOCOPY XX_CS_SR_REC_TYPE,
                       X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MSG     IN OUT NOCOPY VARCHAR2)

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
   ln_status_id                number;
   ln_category_id              number;
   lc_context                  varchar2(100);
   lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
   lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);


begin

    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

  /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT cb.object_version_number,
            cb.incident_type_id,
            ct.attribute9
     INTO ln_obj_ver,
           ln_type_id,
           lc_context
     FROM   cs_incidents_all_b cb,
            cs_incident_types_vl ct
     WHERE  ct.incident_type_id = cb.incident_type_id
     AND    cb.incident_id = p_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_obj_ver := 2;
        ln_type_id := null;
    END;

    lr_service_request_rec.type_id          := ln_type_id;
    lr_service_request_rec.cust_ticket_number := p_sr_req_rec.global_ticket_number; -- MPS APRIMO Contract number
    lr_service_request_rec.summary        := nvl(p_sr_req_rec.description, substr(p_comments,1,150));

    IF lc_context is not null then
      lr_service_request_rec.request_context      := lc_context;
      lr_service_request_rec.request_attribute_1  := p_sr_req_rec.order_number;
      lr_service_request_rec.request_attribute_11 := p_sr_req_rec.warehouse_id;
      lr_service_request_rec.cust_ticket_number   := p_sr_req_rec.order_number;
      lr_service_request_rec.tier_version := p_sr_req_rec.zz_flag;
      IF p_sr_req_rec.csc_location is not null then
         lr_service_request_rec.cust_ticket_number   := p_sr_req_rec.order_number||','||p_sr_req_rec.csc_location;
      END IF;
      lr_service_request_rec.request_attribute_2  := p_sr_req_rec.ship_date;
    END IF;

    -- get status
    IF p_sr_req_rec.status_name is not null then
      begin
        select incident_status_id
        into lr_service_request_rec.status_id
        from cs_incident_statuses_tl
        where name = p_sr_req_rec.status_name;
      exception
        when others then
           x_return_msg := 'Error while selecting status id and status not updated';
      end;
   end if;

   /*************************************************************************
     -- Add notes
    ************************************************************************/

      lt_notes_table(1).note        := p_comments ;
      lt_notes_table(1).note_detail := p_comments;
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
      x_workflow_process_id    => lx_workflow_process_id,
      x_interaction_id         => lx_interaction_id   );

      commit;

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

   x_return_status := lx_return_status;
   x_return_msg    := lx_msg_data;
  EXCEPTION
   WHEN OTHERS THEN
       X_RETURN_STATUS := 'F';
       X_RETURN_MSG  := 'Error while updating SR '||SQLERRM;
END UPDATE_SR;
/******************************************************************************/
 PROCEDURE CONC_PROC (X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                       X_RETCODE         OUT  NOCOPY  NUMBER,
                       P_REQUEST_NUMBER IN VARCHAR2,
                       P_PARTY_ID       IN NUMBER,
                       P_REQ_TYPE       IN VARCHAR2)
AS
lc_return_status  varchar2(25);
lc_return_msg     varchar2(1000);
BEGIN

   IF P_REQ_TYPE = 'APRIMO' THEN

       XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC( p_party_id  => P_PARTY_ID
                     , p_sales_rep     => null
                     , p_contract_type => null
                     , x_return_status => lc_return_status
                     , x_return_msg    => lc_return_msg
                     );

      x_errbuf := lc_return_msg;
      IF lc_return_status = 'S' then
            x_retcode := 0;
      else
            x_retcode := -1;
      end if;

   end if;

END CONC_PROC;

/********************************************************************************/
PROCEDURE UPDATE_SR_STATUS (P_REQUEST_ID      IN NUMBER,
                            P_REQUEST_NUMBER  IN VARCHAR2,
                            P_STATUS_ID       IN NUMBER,
                            P_STATUS          IN VARCHAR2,
                            X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MSG      IN OUT NOCOPY VARCHAR2)
IS 

x_msg_count          NUMBER;
ln_obj_ver           NUMBER;
lx_interaction_id    NUMBER;
ln_resp_appl_id      NUMBER := 514;
ln_resp_id           NUMBER := 21739;
ln_user_id           NUMBER;
BEGIN

     begin
         select user_id
         INTO LN_USER_ID
         from fnd_user
         WHERE USER_NAME = 'CS_ADMIN';
         x_return_status := 'S';
      exception
        when others then
              x_return_status := 'F';
              x_return_msg := ' Error while selecting userid '||sqlerrm;
        END;

      begin
        SELECT object_version_number
         INTO ln_obj_ver
         FROM   cs_incidents_all_b
         WHERE  incident_id = p_request_id;
      exception
        when others then
              x_return_status := 'F';
              x_return_msg := ' Error while selecting version '||sqlerrm;
      end;
      
     Begin
              
                 CS_SERVICEREQUEST_PUB.Update_Status
                  (p_api_version          => 2.0,
                  p_init_msg_list          => FND_API.G_TRUE,
                  p_commit                  => FND_API.G_FALSE,
                  x_return_status          => x_return_status,
                  x_msg_count              => x_msg_count,
                  x_msg_data                => x_return_msg,
                  p_resp_appl_id          => ln_resp_appl_id,
                  p_resp_id                  => ln_resp_id,
                  p_user_id                  => ln_user_id,
                  p_login_id                => NULL,
                  p_request_id              => p_request_id,
                  p_request_number        => p_request_number,
                  p_object_version_number => ln_obj_ver,
                  p_status_id                   => p_status_id,
                  p_status                    => p_status,
                  p_closed_date                => SYSDATE,
                  p_audit_comments          => NULL,
                  p_called_by_workflow      => NULL,
                  p_workflow_process_id      => NULL,
                  p_comments                  => NULL,
                  p_public_comment_flag      => NULL,
                  x_interaction_id          => lx_interaction_id);

                  commit;
              exception
                when others then
                  
                   x_return_msg := 'Error while updating SR# '||p_request_number||' '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_MPS_UTILITIES_PKG.UPDATE_SR_STATUS'
                                     ,p_error_message_code =>   'XX_CS_S01_ERR_LOG'
                                     ,p_error_msg          =>  x_return_msg
                                     ,p_object_id         => p_request_number);
            end;
    

END;
/*****************************************************************************/
END XX_CS_MPS_UTILITIES_PKG;
/
show errors;
exit;