CREATE OR REPLACE
PACKAGE BODY "XX_CS_SERVICEREQUEST_PKG" AS

 /*=======================================================================+
 | FILENAME : XX_CS_SERVICEREQUEST_PKG
 |
 | DESCRIPTION : Wrapper package for create/update service requests.
 |
 | Created                         Rajeswari Jagarlamudi - 24-Apr-2007
***************************************************************************/

G_PKG_NAME      CONSTANT VARCHAR2(30):= 'XX_CS_SERVICEREQUEST_PKG';
v_obj_ver       NUMBER;
g_user_id       number; -- For initialization

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_SR_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

END Initialize_Line_Object;

/************************************************************************************/

/*-------------------------------------------------------------------------------------
Service Request Rec (xx_cs_sr_rec_type) details
  request_date      -- Service Request create date
  request_id	    -- Service Request ID (unique - primary key)
  request_number    -- Service Request Number (display field to users
  type_id           -- Service Request Type Id (Drop down list of GMill Screen)
  type_name         -- Service Request Type name (ex: Stocked Product)
  status_name       -- Status of Service request (Open, Closed )
  owner_id          -- Service Request Owner Id
  owner_group_id    -- Service Request Group id
  description       -- Description - Summary
  caller_type       -- Caller type (Customer or Agent)
  customer_id       -- Customer Id
  customer_sku_id   -- SKUs
  user_id           -- User id (ex: ad-test)
  language
  problem_code      -- Problem code
  exp_resolution_date   -- Expected Resolution Date (internal )
  act_resolution_date   -- Actual Resolution Date (internal)
  channel
  contact_name
  contact_phone
  contact_email
  contact_fax
  comments
  order_number
  customer_number
------------------------------------------------------------------------------------- */
PROCEDURE Create_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 p_request_id       in out nocopy number,
                                 p_request_num      in out nocopy number,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL)
IS

lx_msg_count                NUMBER;
lx_msg_data                 VARCHAR2(2000);
lx_request_id               NUMBER;
lx_request_number           VARCHAR2(50);
lx_interaction_id           NUMBER;
lx_workflow_process_id      NUMBER;
lx_msg_index_out            NUMBER;
lx_return_status            VARCHAR2(1);
lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
ln_user_id                   number;
ln_resp_appl_id              number := 514; --Test this with 170
ln_resp_id                   number := 21739;  -- Customer Support
ln_party_id                  number;
ln_contact_point_id          number;
lc_contact_point_type        varchar2(100);
lc_primary_flag              varchar2(1);
lc_contact_type              varchar2(100);
lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
loop_counter                 number := 0;
ln_owner_id                  number;
i                            number;
ln_obligation_time           number; -- Responding time
ln_resolution_time           number;
ln_time_zone                 number;

BEGIN
  -- Initialization user id
  begin
     select user_id
     into g_user_id
     from fnd_user
     where user_name = '491862';
  end;
  begin
    select user_id
    into ln_user_id
    from fnd_user
    where user_name = upper(p_sr_req_rec.user_id);
  exception
  when others then
    ln_user_id := ln_user_id;
  end;
/*******************************************************************************/
-- Application id  514 (short name CSS)
-- Responsibility  22851 (customer support)
--Apps Initialization
/*******************************************************************************/
apps.fnd_global.apps_initialize(g_user_id,ln_resp_id,ln_resp_appl_id);

if p_sr_req_rec.customer_id is not null then
  -- for only release 1 mapping with orig_system_reference
  begin
     select hzp.party_type,
            hzc.cust_account_id,
            hzt.contact_point_id,
            hzt.contact_point_type,
            hzt.primary_flag,
            hzt.contact_point_purpose,
            hzp.party_id,
            hzp.party_number
    into lr_service_request_rec.caller_type,
         lr_service_request_rec.account_id,
         ln_contact_point_id,
         lc_contact_point_type,
         lc_primary_flag,
         lc_contact_type,
         ln_party_id,
         lr_service_request_rec.customer_number
    from hz_parties hzp,
        hz_cust_accounts hzc,
        hz_contact_points hzt
    where hzt.contact_point_id = hzp.primary_phone_contact_pt_id
    and  hzc.party_id = hzp.party_id
    and  hzp.orig_system_reference = to_char(p_sr_req_rec.customer_id)||'-00001-A0';

    lr_service_request_rec.customer_id        := ln_party_id;
    lr_service_request_rec.customer_phone_id  := ln_contact_point_id;
  exception
    when others then
      x_return_status := 'F';
      x_msg_data := 'Error while selecing cust_account_id '||sqlerrm;
  end;
else
  lr_service_request_rec.caller_type := 'PERSON';
   begin
    select person_party_id
    into ln_party_id
    from fnd_user
    where user_name = '491862'; --upper(p_sr_req_rec.user_id);
  exception
    when others then
      x_return_status := 'FAILED';
      x_msg_data := 'Error while selecing party_id '||sqlerrm;
  end;
  -- now ad-test not defined the party id
  lr_service_request_rec.customer_id := ln_party_id;
  lc_contact_point_type := 'EMAIL';
  lc_primary_flag       := 'Y';
  lc_contact_type       := 'PARTY_RELATIONSHIP';
end if;
-- Severity_id 
begin
   select incident_severity_id 
   into lr_service_request_rec.severity_id
   from cs_incident_severities_vl
   where name = 'High'
   and incident_subtype = 'INC';
exception
   when others then
      x_return_status := 'FAILED';
      x_msg_data := 'Error while selecing severity id '||sqlerrm;
end;  

-- Urgency Id
begin
  select incident_urgency_id 
  into lr_service_request_rec.urgency_id
  from cs_incident_urgencies_vl  
  where name = 'Minor';
exception
when others then
      x_return_status := 'FAILED';
      x_msg_data := 'Error while selecing urgency id '||sqlerrm;
end;  

-- Populate the SR Record type
lr_service_request_rec.request_date := to_date(p_sr_req_rec.request_date, 'DD-MON-YYYY HH24:MI:SS');
lr_service_request_rec.type_id      := p_sr_req_rec.type_id;
lr_service_request_rec.status_id    := 1; -- always open status
lr_service_request_rec.request_context := 'Order';
lr_service_request_rec.request_attribute_1 := p_sr_req_rec.order_number;
lr_service_request_rec.request_attribute_2 := p_sr_req_rec.ship_date;
lr_service_request_rec.request_attribute_3 := p_sr_req_rec.account_mgr_email;
lr_service_request_rec.request_attribute_4 := p_sr_req_rec.sales_rep_contact;
lr_service_request_rec.request_attribute_5 := p_sr_req_rec.sales_rep_contact_phone;
lr_service_request_rec.request_attribute_6 := p_sr_req_rec.sales_rep_contract_email;
lr_service_request_rec.request_attribute_8 := p_sr_req_rec.amazon_po_number;
lr_service_request_rec.request_attribute_9 := p_sr_req_rec.customer_id;
-- select calendar and time zone id.
lr_service_request_rec.verify_cp_flag := 'N';
lr_service_request_rec.sr_creation_channel := p_sr_req_rec.channel;
lr_service_request_rec.problem_code := p_sr_req_rec.problem_code;
lr_service_request_rec.summary := p_sr_req_rec.problem_code;
--lr_service_request_rec.owner_id  := l_owner_id;
--lr_service_request_rec.owner := p_sr_req_rec.user_id;
lr_service_request_rec.language := 'US'; -- assign from ecomsite key.
lr_service_request_rec.resource_type := 'RS_EMPLOYEE';
lr_service_request_rec.cust_ticket_number := p_sr_req_rec.global_ticket_flag;

/******************************************************************************/
/* Retrive the Time Zone Id and calendar using warehouse id
/* For order related use warehouse time zone id.
/* Call center time zone for non-order related.
/******************************************************************************/
begin
  select calendar_code
  into lr_service_request_rec.request_attribute_10
  from mtl_parameters
  where organization_id = p_sr_req_rec.warehouse_id;
exception
  when others then
     lr_service_request_rec.request_attribute_10 := 'OD WH CAL';
end;

begin
  select fn.upgrade_tz_id
  into   lr_service_request_rec.time_zone_id
  from   hr_locations_v hrv,
         fnd_timezones_b fn
  where  fn.timezone_code = hrv.timezone_code
  and    hrv.inventory_organization_id = p_sr_req_rec.warehouse_id;
exception
  when others then
        lr_service_request_rec.time_zone_id := 1;
end;

-- Response time, reterive from cs_incident_types_b.attribute1
begin
  select attribute1
  into ln_obligation_time
  from cs_incident_types_b
  where incident_type_id = p_sr_req_rec.type_id;
exception
  when others then
    ln_obligation_time := 3.5;
end;
lr_service_request_rec.obligation_Date := (sysdate + ln_obligation_time/24);

-- Resolution Time, reterive from cs_incidents_type.attribute2
begin
  select attribute1
  into ln_resolution_time
  from cs_incident_types_b
  where incident_type_id = p_sr_req_rec.type_id;
exception
  when others then
    ln_resolution_time := 4;
end;
lr_service_request_rec.exp_resolution_date := (sysdate + ln_resolution_time/24 );

/*******************************************************************************/
-- Adhoc contact information
/*******************************************************************************/
lr_service_request_rec.incident_address := p_sr_req_rec.contact_name;
lr_service_request_rec.incident_address2 := p_sr_req_rec.contact_phone;
lr_service_request_rec.incident_address3 := p_sr_req_rec.contact_email;
lr_service_request_rec.incident_address4 := p_sr_req_rec.contact_fax;
/*
-- Contacts table
lt_contacts_tab(1).party_id := ln_party_id;
lt_contacts_tab(1).contact_point_id := ln_contact_point_id;
lt_contacts_tab(1).CONTACT_POINT_TYPE := lc_contact_point_type;
lt_contacts_tab(1).PRIMARY_FLAG := lc_primary_flag;
lt_contacts_tab(1).CONTACT_TYPE := lc_contact_type;
*/
-- Notes table
IF length(p_sr_req_rec.comments) > 2000 then
  lt_notes_table(1).note        := substr(p_sr_req_rec.comments,1,1500);
  lt_notes_table(1).note_detail := p_sr_req_rec.comments;
else
  lt_notes_table(1).note        := p_sr_req_rec.comments;
end if;
lt_notes_table(1).note_type   := 'GENERAL';

    --  dbms_output.put_line('Party Id : '||ln_party_id||' Type Id '||p_sr_req_rec.type_id);
     /************************************************************************
          -- Get Resources
     *************************************************************************/
   /*       --l_TerrServReq_Rec.service_request_id   := lx_request_id;
          lr_TerrServReq_Rec.party_id             := ln_party_id;
          lr_TerrServReq_Rec.incident_type_id     := p_sr_req_rec.type_id;
          lr_TerrServReq_Rec.incident_severity_id := lr_service_request_rec.severity_id;
          lr_TerrServReq_Rec.problem_code         := p_sr_req_rec.problem_code;
          lr_TerrServReq_Rec.incident_status_id   := lr_service_request_rec.status_id;
          lr_TerrServReq_Rec.sr_creation_channel  := p_sr_req_rec.channel;  */
          /*************************************************************************************************************/
      --- Expecting from GMill or Dertermin based on Order Line from oe_order_line_all
         -- first check the non_code_flag, if 'N' then look for 'DIRECT' or 'DROPSHIP' or 'BACK-TO-BACK'
         /**************************************************************************************************************/
       /*   lr_TerrServReq_Rec.ord_line_type      := '3';

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
          x_msg_data := lx_msg_data;
        END IF; */
        /****************************************************************************/
      /*   IF lt_TerrResource_tbl.count > 0 THEN
          dbms_output.put_line('Resource Group and Group Id '||lt_TerrResource_tbl(1).resource_id||' '||lt_TerrResource_tbl(1).resource_type);
            lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
            lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
          end if;  */
          
          -- Resource selection  lr_service_request_rec.summary
          begin
            SELECT C.MEANING, C.ATTRIBUTE15, 'RS_GROUP'
            INTO   lr_service_request_rec.summary,
                   lr_service_request_rec.owner_group_id,
                   lr_service_request_rec.group_type
            FROM   CS_SR_PROB_CODE_MAPPING_DETAIL D,
                   CS_LOOKUPS C
            WHERE  C.LOOKUP_CODE = D.PROBLEM_CODE
            AND    D.INCIDENT_TYPE_ID =  p_sr_req_rec.type_id
            AND    D.PROBLEM_CODE = p_sr_req_rec.problem_code
            AND    C.LOOKUP_TYPE = 'REQUEST_PROBLEM_CODE'
            AND    C.ENABLED_FLAG = 'Y';
          exception
             when others then
                lr_service_request_rec.group_type := 'RS_GROUP';
          end;


              apps.cs_servicerequest_pub.Create_ServiceRequest (
                                  p_api_version => 2.0,
                                  p_init_msg_list => FND_API.G_TRUE,
                                  p_commit => FND_API.G_FALSE,
                                  x_return_status => lx_return_status,
                                  x_msg_count => lx_msg_count,
                                  x_msg_data => lx_msg_data,
                                  p_resp_appl_id => ln_resp_appl_id,
                                  p_resp_id => ln_resp_id,
                                  p_user_id => ln_owner_id, --l_user_id,
                                  p_login_id => NULL,
                                  --p_org_id => 204,
                                  p_request_id => NULL,
                                  p_request_number => NULL,
                                  p_service_request_rec => lr_service_request_rec,
                                  p_notes => lt_notes_table,
                                  p_contacts => lt_contacts_tab,
                                 -- p_auto_assign  => 'N',
                                  --p_default_contract_sla_ind => 'N',
                                  x_request_id => lx_request_id,
                                  x_request_number => lx_request_number,
                                  x_interaction_id => lx_interaction_id,
                                  x_workflow_process_id => lx_workflow_process_id );

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

                --  DBMS_OUTPUT.PUT_LINE(lx_msg_data);
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lx_msg_data,
                              p_msg_index_out => lx_msg_index_out);
                --  DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                --  DBMS_OUTPUT.PUT_LINE(lx_msg_index_out);
          END IF;
          x_msg_data := lx_msg_data;
      END IF;
     --dbms_output.put_line('status ' || lx_return_status);
      IF (lx_return_status = 'S') then
      --dbms_output.put_line('Order number '||p_sr_req_rec.order_number);
       IF p_sr_req_rec.order_number is not null then
       /**************************************************************************
            -- Populate order details to related objects
        *************************************************************************/
        --p_order_tbl   := XX_CS_SR_ORDER_TBL();
        i := p_order_tbl.first;
        IF I IS NOT NULL THEN
         loop
           -- Populate order details
            --dbms_output.put_line('Item details  '||p_order_tbl(i).sku_id||' '||p_order_tbl(i).quantity);
            begin
                insert into xx_cs_sr_items_link
                (service_request_id,
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
                 attribute4)
                values(lx_request_id,
                      p_order_tbl(i).sku_id,
                      p_order_tbl(i).sku_description,
                      p_order_tbl(i).quantity,
                      p_order_tbl(i).order_link,
                      sysdate,
                      user,
                      sysdate,
                      user,
                      p_order_tbl(i).order_number,
                      p_order_tbl(i).order_sub,
                      p_order_tbl(i).Manufacturer_info,
                      p_order_tbl(i).attribute1); -- Vendor Id
            exception
              when others then
               x_return_status := 'F';
               x_msg_data := 'Error while populating items '||sqlerrm;
            end;
          EXIT WHEN I = p_order_tbl.last;
          I := p_order_tbl.NEXT(I);
         end loop;
         commit;
        END IF;
      end if;

        end if;

          x_return_status             := lx_return_status;
          p_request_id                := lx_request_id;
          p_request_num               := lx_request_number;
          p_sr_req_rec.request_id     := lx_request_id;
          p_sr_req_rec.request_number := lx_request_number;
exception
      when others then
        x_return_status             := 'F';
        x_msg_data                  :=  x_msg_data;
END Create_ServiceRequest;
/*********************************************************************************/

PROCEDURE Search_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_sr_req_tbl       in out nocopy XX_CS_SR_TBL_TYPE,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2)
is
CURSOR C1 IS
select alb.incident_id,
       alb.incident_number,
       alb.creation_date,
       alb.created_by,
       tlc.summary,
       --a.customer_id, 
       alb.incident_attribute_9 customer_id,
       tlb.name,
       cs.description,
       decode(alb.incident_status_id,1,'Open',2,'Closed',102,'Cancelled') status,
       alb.incident_attribute_1 order_number,
       alb.resolution_code,
       alb.incident_address,
       alb.incident_address2,
       alb.incident_address3,
       alb.incident_address4,
       alb.customer_ticket_number,
       alb.incident_attribute_2 ship_date,
       alb.incident_attribute_3 account_mgr_email,
       alb.incident_attribute_4 sales_rep_contact,
       alb.incident_attribute_5 sales_rep_contact_phone,
       alb.incident_attribute_6 sales_rep_contract_email,
       alb.incident_attribute_8 amazon_po_number
from cs_incidents_all_b alb,
     cs_incident_types_tl tlb,
     cs_incidents_all_tl tlc,
     cs_lookups cs
where cs.lookup_code = alb.problem_code
and   tlc.incident_id = alb.incident_id
and   alb.incident_type_id = tlb.incident_type_id
and   nvl(alb.incident_attribute_9,'x') = nvl(to_char(p_sr_req_rec.customer_id),nvl(alb.incident_attribute_9,'x'))
and   tlb.incident_type_id = nvl(p_sr_req_rec.type_id,tlb.incident_type_id)
and   tlb.name = nvl(p_sr_req_rec.type_name, tlb.name)
and   alb.incident_status_id = nvl(to_number(p_sr_req_rec.status_name),alb.incident_status_id)
and   nvl(alb.problem_code,'x') = decode(p_sr_req_rec.problem_code,null,nvl(alb.problem_code,'x'))
and   alb.creation_date = nvl(p_sr_req_rec.request_date,alb.creation_date)
and   alb.incident_number = nvl(p_sr_req_rec.request_number, alb.incident_number)
and   alb.incident_id  = nvl(p_sr_req_rec.request_id, alb.incident_id)
and   nvl(alb.incident_attribute_1,'x') = nvl(p_sr_req_rec.order_number,nvl(alb.incident_attribute_1,'x'))
and   cs.lookup_type = 'REQUEST_PROBLEM_CODE'
and   cs.enabled_flag = 'Y'
order by alb.incident_id desc;

/************************************************************************************
 Release 2 code change in above query 
 --and  a.customer_id = nvl(p_sr_req_rec.customer_id, a.customer_id) -- for release2
*************************************************************************************/

c1_rec                c1%rowtype;
I                     NUMBER := 0;

cursor c2 is
select item_number,
       item_description,
       quantity,
       attribute1 order_number,
       order_link,
       attribute2 order_sub,
       attribute3 Manufacturer_info,
       attribute4 vendor_id
from xx_cs_sr_items_link
where service_request_id = c1_rec.incident_id;

c2_rec                c2%rowtype;
j                     NUMBER := 0;

BEGIN
      x_msg_data := null;
      I                      := 1;
      P_SR_REQ_TBL           := XX_CS_SR_TBL_TYPE();
      j                      := 1;
      P_ORDER_TBL            := XX_CS_SR_ORDER_TBL();
            
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;

      p_sr_req_tbl.extend;
      Initialize_Line_Object(p_sr_req_tbl(i));

    BEGIN

         p_sr_req_tbl(i).request_date             := c1_rec.creation_date;
         p_sr_req_tbl(i).request_id	          := c1_rec.incident_id;
         p_sr_req_tbl(i).request_number           := c1_rec.incident_number;
         p_sr_req_tbl(i).type_name                := c1_rec.name;
         p_sr_req_tbl(i).status_name              := c1_rec.status;
         p_sr_req_tbl(i).customer_id              := c1_rec.customer_id;
         p_sr_req_tbl(i).problem_code             := c1_rec.description;
         p_sr_req_tbl(i).description              := c1_rec.summary;
         p_sr_req_tbl(i).order_number             := c1_rec.order_number;
         p_sr_req_tbl(i).resolution_code          := c1_rec.resolution_code;
         p_sr_req_tbl(i).contact_name             := c1_rec.incident_address;
         p_sr_req_tbl(i).contact_phone            := c1_rec.incident_address2;
         p_sr_req_tbl(i).contact_email            := c1_rec.incident_address3;
         p_sr_req_tbl(i).contact_fax              := c1_rec.incident_address4;
         p_sr_req_tbl(i).ship_date                := c1_rec.ship_date;
         p_sr_req_tbl(i).global_ticket_flag       := c1_rec.customer_ticket_number;
         p_sr_req_tbl(i).account_mgr_email        := c1_rec.account_mgr_email;
         p_sr_req_tbl(i).sales_rep_contact        := c1_rec.sales_rep_contact;
         p_sr_req_tbl(i).sales_rep_contact_phone  := c1_rec.sales_rep_contact_phone;
         p_sr_req_tbl(i).sales_rep_contract_email := c1_rec.sales_rep_contract_email;
         p_sr_req_tbl(i).amazon_po_number         := c1_rec.amazon_po_number;
      begin
          select note
          into p_sr_req_tbl(i).comments
          from cs_sr_notes_v
          where incident_id = c1_rec.incident_id
          and rownum < 2;
        exception
          when others then
            p_sr_req_tbl(i).comments := null;
        end;

        begin
          select user_name
          into p_sr_req_tbl(i).user_id
          from fnd_user
          where user_id = c1_rec.created_by;
        exception
          when others then
            p_sr_req_tbl(i).user_id := c1_rec.created_by;
        end;

        -- Assign Items if selected.
        begin
          open c2;
          loop
          fetch c2 into c2_rec;
          exit when c2%notfound;

          p_order_tbl.extend;
          p_order_tbl(j) := xx_cs_sr_order_rec_type(null,null,null,null,null,null,null,null,null,null,null,null);

          begin
              p_order_tbl(j).sku_id             := c2_rec.item_number;
              p_order_tbl(j).sku_description    := c2_rec.item_description;
              p_order_tbl(j).quantity           := c2_rec.quantity;
              p_order_tbl(j).order_number       := c2_rec.order_number;
              p_order_tbl(j).order_link         := c2_rec.order_link;
              p_order_tbl(j).attribute2         := c1_rec.incident_id;  -- Service Request Id
              p_order_tbl(j).order_sub          := c2_rec.order_sub;
              p_order_tbl(j).Manufacturer_info  := c2_rec.Manufacturer_info;
              p_order_tbl(j).attribute1         := c2_rec.vendor_id;
          exception
           when others then
            x_return_status := 'F';
            x_msg_data := 'Error while assigning order details '||sqlerrm;
          end;
              j := j + 1;
         end loop;
         close c2;
         exception
           when others then
              x_return_status := 'F';
              x_msg_data := 'Error cursor 2 '||sqlerrm;
      end;
    exception
       when others then
         x_return_status := 'F';
         x_msg_data := SQLERRM;
         
    END;

     I := I + 1;

    END LOOP;
    CLOSE C1;
         x_return_status := 'S';
    EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'F';
         x_msg_data := SQLERRM;
END ;

/*******************************************************************************
   Search Service Request Note details
********************************************************************************/
PROCEDURE Search_notes (p_request_id    in number,
                        p_sr_notes_tbl  in out nocopy XX_CS_SR_NOTES_TBL,
                        p_ecom_site_key in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                        p_return_status in out nocopy varchar2,
                        p_msg_data      in out nocopy varchar2)
is

cursor c1 is
select a.note_type_meaning,
       a.note,
       a.creation_date,
       b.user_name
from cs_sr_notes_v a,
      fnd_user b
where a.created_by = b.user_id
and   a.incident_id =  p_request_id;

c1_rec  c1%rowtype;
I       NUMBER := 0;
begin
      I                        := 1;
      P_SR_NOTES_TBL           := XX_CS_SR_NOTES_TBL();
    open c1;
    loop
    fetch c1 into c1_rec;
    exit when c1%notfound;
       p_sr_notes_tbl.extend;
       p_sr_notes_tbl(i) := xx_cs_sr_notes_rec(null,null,null,null);

       BEGIN
         p_sr_notes_tbl(i).notes          := c1_rec.note_type_meaning;
         p_sr_notes_tbl(i).note_details   := c1_rec.note;
         p_sr_notes_tbl(i).created_by     := c1_rec.user_name;
         p_sr_notes_tbl(i).creation_date  := c1_rec.creation_date;

         I := I + 1;

      END;

    end loop;
    close c1;
     p_return_status := 'S';
     EXCEPTION
      WHEN OTHERS THEN
         p_return_status := 'F';
         p_msg_data := SQLERRM;
end;

/********************************************************************************
  UPDATE Service Request by Status or Add note
*********************************************************************************/
Procedure Update_ServiceRequest(p_sr_request_id    in number,
                                p_sr_status_id     in number,
                                p_sr_notes         in XX_CS_SR_NOTES_REC,
                                p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                p_user_id          in varchar2,
                                x_return_status    in out nocopy varchar2,
                                x_msg_data         in out nocopy varchar2)
IS
      x_msg_count	NUMBER;
      x_interaction_id  NUMBER;
      ln_obj_ver         NUMBER;
      lc_sr_status       VARCHAR2(25);
      ln_status_id       number;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number; -- := 1955;
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739;  -- Customer Support

BEGIN

    begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = upper(p_user_id);
    exception
    when others then
      x_return_status := 'E';
      x_msg_data      := 'Error while selecting user id '||sqlerrm;
    end;
   -- dbms_output.put_line('user '||p_user_id||' '||ln_user_id);
    --Apps Initialization
    apps.fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    -- Update SR

    SELECT object_version_number
    INTO ln_obj_ver
    FROM   cs_incidents_all_b
    WHERE  incident_id = p_sr_request_id;

     IF P_SR_STATUS_ID = 2 THEN
         LC_SR_STATUS := 'Closed';
         ln_status_id := 2;
      ELSIF P_SR_STATUS_ID = 103 THEN
         LC_SR_STATUS  := 'Cancelled';
         ln_status_id  := 103;
      END IF;

      IF LC_SR_STATUS IS NOT NULL THEN
       CS_SERVICEREQUEST_PUB.Update_Status
        (p_api_version		=> 2.0,
        p_init_msg_list	        => FND_API.G_TRUE,
        p_commit		=> FND_API.G_FALSE,
        x_return_status	        => x_return_status,
        x_msg_count	        => x_msg_count,
        x_msg_data		=> x_msg_data,
        p_resp_appl_id	        => ln_resp_appl_id,
        p_resp_id		=> ln_resp_id,
        p_user_id		=> ln_user_id,
        p_login_id		=> NULL,
        p_request_id		=> p_sr_request_id,
        p_request_number	=> NULL,
        p_object_version_number => ln_obj_ver,
        p_status_id	 	=> ln_status_id,
        p_status		=> lc_sr_status,
        p_closed_date		=> SYSDATE,
        p_audit_comments	=> NULL,
        p_called_by_workflow	=> NULL,
        p_workflow_process_id	=> NULL,
        p_comments		=> NULL,
        p_public_comment_flag	=> NULL,
        x_interaction_id	=> x_interaction_id);

    end if;
   -- DBMS_OUTPUT.PUT_LINE('STATUS '||x_return_status);
    -- update notes.
    IF p_sr_notes.notes is not null
      and nvl(x_return_status,'S') = 'S' then
      XX_CS_SERVICEREQUEST_PKG.CREATE_NOTE (p_request_id   => p_sr_request_id,
                                          p_sr_notes_rec => p_sr_notes,
                                          p_return_status => x_return_status,
                                          p_msg_data => x_msg_data);
     -- dbms_output.put_line('note created ');
    end if;

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

    --DBMS_OUTPUT.PUT_LINE ('X_RETURN_STATUS --- '||x_return_status);
    --DBMS_OUTPUT.PUT_LINE ('X_MSG_COUNT     --- '||TO_CHAR(x_msg_count));
    --DBMS_OUTPUT.PUT_LINE ('X_MSG_DATA      --- '||x_msg_data||' '||SQLERRM);

    COMMIT;

END;

/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE (p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_NOTES_REC,
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

--Initialize the Notes parameter to create

ln_api_version			:= 1.0;
lc_init_msg_list		:= FND_API.g_true;
ln_validation_level		:= FND_API.g_valid_level_full;
lc_commit			:= FND_API.g_true;
ln_msg_count			:= 0;
-- If ObjectCode is Party then Object_id is party id
-- If ObjectCode is Service Request then Object_id is Service Request ID
-- If ObjectCode is TASK then Object_id is Task id
ln_source_object_id		:= p_request_id;
lc_source_object_code		:= 'SR';
lc_note_status			:= 'P';  -- (P-Publish, E-Private, I-Internal)
lc_note_type			:= 'GENERAL';
lc_notes				:= p_sr_notes_rec.notes;
lc_notes_detail			:= p_sr_notes_rec.note_details;
ln_entered_by			:= FND_GLOBAL.user_id;
ld_entered_date			:= SYSDATE;

-- Initialize who columns
ld_last_update_date		:= SYSDATE;
ln_last_updated_by		:= FND_GLOBAL.USER_ID;
ld_creation_date			:= SYSDATE;
ln_created_by			:= FND_GLOBAL.USER_ID;
ln_last_update_login		:= FND_GLOBAL.LOGIN_ID;


-- Call API

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

          --  dbms_output.put_line('Status '||lc_return_status||': '||lc_msg_data);

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

END;

END;
