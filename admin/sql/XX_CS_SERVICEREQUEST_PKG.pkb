create or replace
PACKAGE BODY "XX_CS_SERVICEREQUEST_PKG" AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_SERVICEREQUEST_PKG                                 |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-Apr-07   Raj Jagarlamudi  Initial draft version       |
-- |1.1       30-JAN-08   Raj Jagarlamudi  Global Ticket Functionality |
---|1.2       30-APR-08   Raj Jagarlamudi  Added zz flag and ship to   |
---|1.3       17-May-08   Raj Jagarlamudi  Added new queues routing    |
---|1.4       28-Oct-08   Raj Jagarlamudi  Added Contact Phone         |
-- |1.5       13-Mar-09   Raj Jagarlamudi  Vendor Info. Populate to    |
-- |                                       External Attributes         |
-- |1.6       30-Mar-09   Raj Jagarlamudi  VW attributes added         |
-- +===================================================================+

G_PKG_NAME      CONSTANT VARCHAR2(30):= 'XX_CS_SERVICEREQUEST_PKG';
v_obj_ver       NUMBER;
g_user_id       number;

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_SR_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL);

END Initialize_Line_Object;

/*******************************************************************************
    Create Global Ticket (incident_link) for new SR
 ******************************************************************************/
 PROCEDURE CREATE_GLOBAL_TICKET (
   P_REQUEST_ID               IN     NUMBER,
   P_USER_ID		      IN     NUMBER,
   P_APPL_ID                  IN     NUMBER,
   P_RESP_ID                  IN     NUMBER,
   P_TO_INCIDENT_ID	      IN     NUMBER,
   P_TO_INCIDENT_NUMBER	      IN     VARCHAR2,
   X_RETURN_STATUS	      OUT NOCOPY   VARCHAR2,
   X_MSG_COUNT		      OUT NOCOPY   NUMBER,
   X_MSG_DATA		      OUT NOCOPY   VARCHAR2,
   X_LINK_ID		      OUT NOCOPY   NUMBER )

IS
      l_api_name               	CONSTANT VARCHAR2(30) := 'CREATE_GLOBAL_TICKET';
      l_api_name_full          	CONSTANT VARCHAR2(61) := G_PKG_NAME||'.'||l_api_name;
      l_link_rec_pub           	APPS.CS_INCIDENTLINKS_PUB.CS_INCIDENT_LINK_REC_TYPE;
      l_object_version_number    number;
      l_reciprocal_link_id       number;

   BEGIN

      l_link_rec_pub.subject_id               := p_request_id;
      l_link_rec_pub.subject_type             := 'SR';
      l_link_rec_pub.object_id                := p_to_incident_id;
      l_link_rec_pub.object_number            := p_to_incident_number;
      l_link_rec_pub.object_type              := 'SR';
      l_link_rec_pub.link_type_id             := 1;
      l_link_rec_pub.link_type                := 'Root Cause of';
      l_link_rec_pub.request_id               := p_request_id;
      l_link_rec_pub.program_application_id   := p_appl_id;
      l_link_rec_pub.program_id               := null;
      l_link_rec_pub.program_update_date      := null;
      l_link_rec_pub.link_segment1            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment2            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment3            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment4            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment5            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment6            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment7            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment8            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment9            := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment10           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment11           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment12           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment13           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment14           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_segment15           := FND_API.G_MISS_CHAR;
      l_link_rec_pub.link_context             := FND_API.G_MISS_CHAR;

      APPS.CS_INCIDENTLINKS_PUB.CREATE_INCIDENTLINK (
         	P_API_VERSION			=> 2.0,
         	P_INIT_MSG_LIST         	=> FND_API.G_TRUE,
         	P_COMMIT     			=> FND_API.G_FALSE,
         	P_RESP_APPL_ID			=> p_appl_id,
         	P_RESP_ID			=> p_resp_id,
         	P_USER_ID			=> p_user_id,
         	P_LOGIN_ID			=> NULL,
         	--P_ORG_ID			=> 204,
         	P_LINK_REC              	=> l_link_rec_pub,
         	X_RETURN_STATUS	        	=> x_return_status,
        	X_MSG_COUNT			=> x_msg_count,
         	X_MSG_DATA			=> x_msg_data,
         	X_OBJECT_VERSION_NUMBER 	=> l_object_version_number,
         	X_RECIPROCAL_LINK_ID    	=> l_reciprocal_link_id,
         	X_LINK_ID			=> x_link_id );

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         FND_MESSAGE.SET_NAME ('XX_CS', 'CS_API_SR_UNKNOWN_ERROR');
         FND_MESSAGE.SET_TOKEN ('P_TEXT',l_api_name_full||'-'||SQLERRM);
         FND_MSG_PUB.ADD;
         FND_MSG_PUB.Count_And_Get(
   	 p_count => x_msg_count,
   	 p_data  => x_msg_data);

END CREATE_GLOBAL_TICKET;
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
lc_group_name                 varchar2(250);
lc_sku_numbers                varchar2(250);
lc_sku_descr                  varchar2(1000);
ln_quantity                  varchar2(50);
lc_vendor                    varchar2(250);
lc_route                     varchar2(50);
lc_dc_flag                   varchar2(1) := 'N';
lc_mail_flag                 varchar2(1) := 'N';
lc_sr_flag                   varchar2(1) := 'N';
---
lc_sender                 VARCHAR2(250);
lc_recipient              VARCHAR2(250);
lc_subject                VARCHAR2(250);
lc_smtp_server            VARCHAR2(250);
ln_return_code            number;
ln_client_timeid          number := fnd_profile.value('CLIENT_TIMEZONE_ID' );
ln_server_timeid          number := fnd_profile.value('SERVER_TIMEZONE_ID' );
ln_time_id                number := 1;
ln_res_time               number := 0;


BEGIN
/*****************************************************************************
  -- Check  Enter global ticket is valid or not
*******************************************************************************/
IF p_sr_req_rec.global_ticket_number is not null then

     begin
        select incident_id
        into  ln_incident_id
        from  cs_incidents_all_b
        where to_number(incident_number) = p_sr_req_rec.global_ticket_number
        and   problem_code = p_sr_req_rec.problem_code
        and   status_flag  = 'O';
     exception
        when others then
          ln_incident_id  := null;
          x_return_status := 'F';
          x_msg_data      := 'Entered Global Ticket is not valid';
     end;
end if;

/*******************************************************************************/
--Apps Initialization
/*******************************************************************************/
begin
   select user_id
   into g_user_id
   from fnd_user
   where user_name = 'CS_ADMIN';
exception
when others then
      x_return_status := 'F';
      x_msg_data := ' Error while selecting userid '||sqlerrm;
end;

apps.fnd_global.apps_initialize(g_user_id,ln_resp_id,ln_resp_appl_id);

 begin
     select user_id
     into ln_user_id
     from fnd_user
     where user_name = upper(p_sr_req_rec.user_id);
  exception
  when no_data_found then
      ln_user_id := g_user_id;
  when others then
      x_return_status := 'F';
      x_msg_data := 'Error while selecting userid '||sqlerrm;
  end;

/****************************************************************************
  -- Verify whether SR is exists or not
*****************************************************************************/
  BEGIN
    select 'Y'
    into  lc_sr_flag
    from  apps.cs_incidents_all_b
    where incident_type_id = p_sr_req_rec.type_id
    and   problem_code = p_sr_req_rec.problem_code
    and   incident_status_id <> 2
    and   incident_attribute_1 = p_sr_req_rec.order_number
    and   rownum < 2;
  EXCEPTION
    WHEN OTHERS THEN
      LC_SR_FLAG := 'N';
  END;

  IF LC_SR_FLAG = 'Y' THEN
     x_return_status := 'F';
     x_msg_data := 'A duplicate SR exists for '||p_sr_req_rec.problem_code || ' for this Order. Please add comments to existing SR';
  END IF;
  
IF (nvl(x_return_status,'S') = 'S') then

    If p_sr_req_rec.customer_id is not null then
     /*******************************************************************************
      -- for only release 1 mapping with orig_system_reference, now GMill will pass
         the AOPS customer id and the following code will reterive the EBS customer id.
         The following code will change after orders book into EBIZ
      *******************************************************************************/
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
        and  hzc.orig_system_reference = lpad(to_char(p_sr_req_rec.customer_id),8,0)||'-'||'00001-A0';

        lr_service_request_rec.customer_id                := ln_party_id;
        lr_service_request_rec.incident_location_type     := 'HZ_PARTY_SITE';
      exception
       when no_data_found then
          x_return_status := 'F';
          x_msg_data := 'Customer not exists in EBS '||sqlerrm;
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecing cust_account_id '||sqlerrm;
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
             x_msg_data := 'Bill to site information not exists';
      END;

       /*********************************************************************
         Ship to Site information
      **********************************************************************/
      lr_service_request_rec.ship_to_party_id           := ln_party_id;
      lr_service_request_rec.ship_to_account_id         := ln_cust_acct_number;
       BEGIN
         select s1.party_site_id,
                s2.party_site_use_id
          into  lr_service_request_rec.ship_to_site_id,
                lr_service_request_rec.ship_to_site_use_id
          from hz_party_sites s1,
               hz_party_site_uses s2
          where s1.party_site_id = s2.party_site_id
          and   s1.party_id = ln_party_id
          and   s1.orig_system_reference = lpad(to_char(p_sr_req_rec.customer_id),8,0)||'-'||p_sr_req_rec.ship_to||'-A0'
          and   s2.status = 'A'
          and   s2.site_use_type = 'SHIP_TO';
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
              select s1.party_site_id,
                     s2.party_site_use_id
              into  lr_service_request_rec.ship_to_site_id,
                    lr_service_request_rec.ship_to_site_use_id
              from  apps.hz_party_sites s1,
                    apps.hz_party_site_uses s2,
                    apps.hz_orig_sys_references hzo
              where s1.party_id = hzo.party_id
              and   s1.party_site_id = s2.party_site_id
              and   hzo.orig_system_reference = lpad(to_char(p_sr_req_rec.customer_id),8,0)||'-'||p_sr_req_rec.ship_to||'-A0'
              and   hzo.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
              and   s2.site_use_type = 'SHIP_TO'
              and   s1.identifying_address_flag = 'Y';
            EXCEPTION
              WHEN OTHERS THEN
                x_msg_data := 'Ship to site information not exists';
            END;
          WHEN OTHERS THEN
             x_msg_data := 'Ship to site information not exists';
      END;
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
    else
      lr_service_request_rec.caller_type := 'PERSON';
       begin
        select person_party_id
        into ln_party_id
        from fnd_user
        where user_name = upper(p_sr_req_rec.user_id);
      exception
        when no_data_found then
          -- For testing only until OID migration process
          ln_party_id := 297042;
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecing party_id '||sqlerrm;
      end;

      -- now ad-test not defined the party id
      lr_service_request_rec.customer_id := ln_party_id;
      lc_contact_point_type := 'EMAIL';
      lc_primary_flag       := 'Y';
      lc_contact_type       := 'PARTY_RELATIONSHIP';
    end if;

-- checking party id exists or not
 IF (nvl(x_return_status,'S') = 'S') then
 /******************************************************************************
-- Response time, Resolution Time reterive from cs_incident_types_b.attribute1
*******************************************************************************/
begin
  select to_number(attribute1),
         to_number(attribute2),
         attribute6,
         attribute7,
         'RS_GROUP',
         attribute9,
         name
  into ln_obligation_time,
         ln_resolution_time,
         lc_item_catagory,
         lc_type_link,
         lr_service_request_rec.group_type,
         lr_service_request_rec.request_context,
         lc_request_type
  from cs_incident_types_vl
  where incident_type_id = p_sr_req_rec.type_id;
exception
  when others then
    ln_obligation_time := 3;
    ln_resolution_time := 4;
    lc_type_link       := null;
    lc_item_catagory   := null;
    lr_service_request_rec.group_type := 'RS_GROUP';
    lr_service_request_rec.request_context := 'ORDER';
end;
/***********************************
-- Severity_id
************************************/
IF lc_request_type in ('Stocked Products','Stock - Non Order')  then
    begin
         select incident_severity_id
         into lr_service_request_rec.severity_id
         from cs_incident_severities_vl
         where name = 'Critical'
         and incident_subtype = 'INC';
      exception
         when others then
            x_return_status := 'F';
            x_msg_data := 'Error while selecing severity id '||sqlerrm;
      end;
     begin
         select nvl(tag,0) 
          into ln_res_time
          from apps.cs_lookups
          where LOOKUP_TYPE = 'REQUEST_PROBLEM_CODE'
          AND   ENABLED_FLAG = 'Y'
          AND   END_DATE_ACTIVE IS NULL
          AND   LOOKUP_CODE = p_sr_req_rec.problem_code;
          
     exception
         when others then
            ln_res_time := 0;
     end;
     
     if ln_res_time <> 0 then
        ln_obligation_time := ln_res_time;
        ln_resolution_time := ln_obligation_time;
     end if;
else
  begin
     select incident_severity_id
     into lr_service_request_rec.severity_id
     from cs_incident_severities_vl
     where name = 'Medium'
     and incident_subtype = 'INC';
  exception
     when others then
        x_return_status := 'F';
        x_msg_data := 'Error while selecing severity id '||sqlerrm;
  end;
end if;
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
      x_msg_data := 'Error while selecing urgency id '||sqlerrm;
end;

/*****************************************************************************
-- Populate the SR Record type
******************************************************************************/
lr_service_request_rec.request_date             := sysdate;
lr_service_request_rec.incident_occurred_date   := sysdate;
lr_service_request_rec.type_id                  := p_sr_req_rec.type_id;
ln_request_type_id                              := p_sr_req_rec.type_id;
/**************************************************************************
-- Stocked Products
***************************************************************************/
IF lc_request_type = 'Stocked Products' then
 
    begin
      select mtls.category_set_id, mtlb.category_id
      into lr_service_request_rec.category_set_id,
           lr_service_request_rec.category_id
      from apps.mtl_category_sets_vl mtls,
           apps.mtl_categories_b mtlb
      where mtlb.structure_id = mtls.structure_id
      and   mtls.category_set_name = 'CS Warehouses'
      and   mtlb.segment1 like to_char(p_sr_req_rec.warehouse_id)||'%';
    exception
      when others then
        lr_service_request_rec.category_set_id := null;
        lr_service_request_rec.category_id := null;
    end;
    -- For Print On Demand store deliveries 2/1/10
    IF lr_service_request_rec.category_id is null 
        AND p_sr_req_rec.problem_code = 'PRINT ON DEMAND' then
             begin
                select mtls.category_set_id, mtlb.category_id
                into lr_service_request_rec.category_set_id,
                     lr_service_request_rec.category_id
                from apps.mtl_category_sets_vl mtls,
                     apps.mtl_categories_b mtlb
                where mtlb.structure_id = mtls.structure_id
                and   mtls.category_set_name = 'CS Warehouses'
                and   mtlb.segment1 like p_sr_req_rec.csc_location||'%';
              exception
                when others then
                  lr_service_request_rec.category_set_id := null;
                  lr_service_request_rec.category_id := null;
            end;
    END IF;
    
    IF p_sr_req_rec.problem_code in ('BIN CHECK','EMERGENCY ORDER/WILL CALL','MSDS REQUEST') then
      begin
         select TAG, 'Y'
          into ln_obligation_time,
                lc_mail_flag
          from cs_lookups
          where lookup_type = 'XX_CS_WH_EMAIL'
          and enabled_flag = 'Y'
          and lookup_code = p_sr_req_rec.problem_code;
          
          ln_resolution_time := ln_obligation_time;
        exception
          when others then
            lc_mail_flag := 'N';
       end;
    elsif p_sr_req_rec.problem_code = 'POSSIBLE FRAUD' then
        begin
          select incident_type_id 
          into ln_request_type_id 
          from cs_incident_types_tl
          where name = 'Loss Prevention';
          
          lr_service_request_rec.type_id := ln_request_type_id;
        end;
        
     elsif p_sr_req_rec.problem_code in ('OBTAIN NEW OD CREDIT CARD NO','HOLD FOR CREDIT') then   
         begin
          select incident_type_id 
          into ln_request_type_id 
          from cs_incident_types_tl
          where name = 'Credit Card Auth';
          
          lr_service_request_rec.type_id := ln_request_type_id;
        end;
        
    end if;
    
end if; -- Stocked Products
/******************************************************************************/
/* Retrive the Time Zone Id and calendar using warehouse id
/* For order related use warehouse time zone id.
/* Call center time zone for non-order related.
/******************************************************************************/
begin
  select organization_id
  into ln_ebs_warehouse_id
  from hr_all_organization_units
  where to_number(attribute1) = p_sr_req_rec.warehouse_id;
exception
  when others then
      ln_ebs_warehouse_id := null;
      lr_service_request_rec.time_zone_id := 1;
end;

IF ln_ebs_warehouse_id is not null then  -- Warehouse Id
 
  begin
    select fn.upgrade_tz_id
    into   lr_service_request_rec.time_zone_id
    from   hr_locations_v hrv,
          fnd_timezones_b fn
    where  fn.timezone_code = hrv.timezone_code
    and    hrv.inventory_organization_id = ln_ebs_warehouse_id;
  exception
    when others then
        lr_service_request_rec.time_zone_id := 1;
  end;
end if; -- Warehouse Id

ln_time_id := to_number(lr_service_request_rec.time_zone_id);
/****************************************************************************
 -- Getting response and resolution times
******************************************************************************/
         begin
              ld_obligation_Date := xx_cs_sr_utils_pkg.res_rev_time_cal
                                          (p_date => SYSDATE,
                                          p_hours => ln_obligation_time,
                                          p_cal_id => 'OD ST CAL',
                                          p_time_id => ln_time_id);
            exception
              when others then
                  ld_obligation_Date  := (sysdate + ln_obligation_time/24);
            end;
          
 --dbms_output.put_line('obligation date '||ld_obligation_Date);
             begin
                ld_resolution_date := xx_cs_sr_utils_pkg.res_rev_time_cal
                                          (p_date => sysdate,
                                          p_hours => ln_resolution_time,
                                          p_cal_id => 'OD ST CAL',
                                          p_time_id => ln_time_id);
             exception
               when others then
                    ld_resolution_date := (sysdate + ln_resolution_time/24 );
             end;
             
--dbms_output.put_line('Time id '||lr_service_request_rec.time_zone_id||' date '||ld_resolution_date);
/****************************************************************************
-- Material Saftey Data Sheet requests are creating as one call requests
*****************************************************************************/
IF p_sr_req_rec.problem_code like 'MSDS REQUEST' then
  lr_service_request_rec.status_id                := 2; -- close status
ELSE
  lr_service_request_rec.status_id                := 1; -- open status
END IF;

IF lr_service_request_rec.request_context   = 'EC Tech Addl.' THEN
    lr_service_request_rec.request_attribute_1      := p_sr_req_rec.order_number;
    lr_service_request_rec.request_attribute_4      := p_sr_req_rec.sales_rep_contact;
    lr_service_request_rec.request_attribute_5      := p_sr_req_rec.contact_name;
    lr_service_request_rec.request_attribute_7      := p_sr_req_rec.preferred_contact;
    lr_service_request_rec.request_attribute_8      := p_sr_req_rec.contact_email;
    lr_service_request_rec.request_attribute_9      := lpad(p_sr_req_rec.customer_id,8,0);
    lr_service_request_rec.request_attribute_11     := p_sr_req_rec.warehouse_id;
    lr_service_request_rec.request_attribute_14     := p_sr_req_rec.contact_phone;
    lr_service_request_rec.request_attribute_13     := p_sr_req_rec.contact_fax;
    lr_service_request_rec.request_attribute_15     := p_sr_req_rec.sales_rep_contact_name;
ELSE
    lr_service_request_rec.request_attribute_1      := p_sr_req_rec.order_number;
    lr_service_request_rec.request_attribute_2      := to_char(p_sr_req_rec.ship_date, 'mm/dd/yyyy');
    lr_service_request_rec.request_attribute_3      := p_sr_req_rec.account_mgr_email;
    lr_service_request_rec.request_attribute_4      := p_sr_req_rec.sales_rep_contact;
    lr_service_request_rec.request_attribute_5      := p_sr_req_rec.contact_name;
    lr_service_request_rec.request_attribute_7      := p_sr_req_rec.preferred_contact;
    lr_service_request_rec.request_attribute_14     := p_sr_req_rec.contact_phone||' '||p_sr_req_rec.contact_fax;
    lr_service_request_rec.request_attribute_9      := lpad(p_sr_req_rec.customer_id,8,0);
    lr_service_request_rec.request_attribute_11     := p_sr_req_rec.warehouse_id;
    lr_service_request_rec.request_attribute_8      := p_sr_req_rec.contact_email;
    lr_service_request_rec.request_attribute_15     := p_sr_req_rec.sales_rep_contact_name;
    lr_service_request_rec.tier                     := p_sr_req_rec.zz_flag;
    lr_service_request_rec.tier_version             := p_sr_req_rec.customer_sku_id; -- Item Type
    lr_service_request_rec.operating_system         := p_sr_req_rec.ship_to;
END IF;
    lr_service_request_rec.creation_program_code    := 'GMILL';
    lr_service_request_rec.last_update_program_code := 'GMILL';
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

  IF p_sr_req_rec.order_number is not null then
       /**************************************************************************
            -- Populate order details to external attributes
        *************************************************************************/
        i := p_order_tbl.first;
        IF I IS NOT NULL THEN
        loop
           IF I = 1 then
              lc_sku_numbers := p_order_tbl(i).sku_id;
              lc_sku_descr   := p_order_tbl(i).sku_description;
              ln_quantity    := p_order_tbl(i).quantity;
              IF lc_request_type like 'VW%' THEN
                lr_service_request_rec.request_attribute_13 := p_order_tbl(i).order_sub;
              END IF;
           else
            lc_sku_numbers := lc_sku_numbers ||' ; '||p_order_tbl(i).sku_id;
          --  lc_sku_descr   := lc_sku_descr ||' ; '||p_order_tbl(i).sku_description;
            ln_quantity    := ln_quantity ||' ; '||p_order_tbl(i).quantity;
           end if;
            lc_vendor      := p_order_tbl(i).attribute1; -- Vendor Id
            lc_route       := p_order_tbl(i).attribute2; -- Route Id

        EXIT WHEN I = p_order_tbl.last;
          I := p_order_tbl.NEXT(I);
         end loop;
            lr_service_request_rec.External_Context     := 'SKU Details';
            lr_service_request_rec.external_attribute_1 := lc_sku_numbers;
            lr_service_request_rec.external_attribute_2 := lc_sku_descr;
           -- lr_service_request_rec.external_attribute_3 := p_order_tbl(i).Manufacturer_info;
            lr_service_request_rec.external_attribute_4 := lc_vendor;
            lr_service_request_rec.external_attribute_5 := ln_quantity;
            lr_service_request_rec.external_attribute_6 := lc_route;
       end if;
  END IF;

/********************************************************************************
  -- Get Child Request Type ids
*********************************************************************************/
  IF p_sr_req_rec.customer_sku_id IN ('STA','SUP','TEC') then
    lc_item_type := 'MISC';
  elsif p_sr_req_rec.customer_sku_id = 'FUR' then
      lc_item_type := 'FUR';
  elsif p_sr_req_rec.customer_sku_id = 'PRO' THEN
    lc_item_type := 'PRO';
  elsif p_sr_req_rec.customer_sku_id = 'PRI' THEN
    lc_item_type := 'PRI';
  else
    lc_item_type := p_sr_req_rec.customer_sku_id;
  end if;

 IF lc_type_link is not null and lc_item_catagory = 'CATEGORY' THEN
  begin
   select incident_type_id
   into   ln_request_type_id
   from   cs_incident_types_b
   where  incident_subtype = 'INC'
   and    end_date_active is null
   and    attribute7 = lc_type_link
   and    attribute6 = lc_item_type
   and    end_date_active is null;
exception
  when others then
    ln_request_type_id := p_sr_req_rec.type_id;
end;
--dbms_output.put_line(' Item Type '||ln_request_type_id||' '||p_sr_req_rec.type_id||' '||lc_type_link||' '||lc_item_type);
END IF;
/*******************************************************************************/
-- Adhoc contact information
/*******************************************************************************/
--lr_service_request_rec.incident_address  := p_sr_req_rec.contact_name;
--lr_service_request_rec.incident_city     := p_sr_req_rec.preferred_contact;
lr_service_request_rec.incident_address2 := p_sr_req_rec.contact_phone;
lr_service_request_rec.incident_address3 := p_sr_req_rec.contact_email;
lr_service_request_rec.incident_address4 := p_sr_req_rec.contact_fax;
/*******************************************************************************
-- Populating Contacts table
********************************************************************************/
/*
lt_contacts_tab(1).party_id := ln_party_id;
lt_contacts_tab(1).contact_point_id := ln_contact_point_id;
lt_contacts_tab(1).CONTACT_POINT_TYPE := lc_contact_point_type;
lt_contacts_tab(1).PRIMARY_FLAG := lc_primary_flag;
lt_contacts_tab(1).CONTACT_TYPE := lc_contact_type ; */

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
          lr_TerrServReq_Rec.service_request_id   := lx_request_id;
          lr_TerrServReq_Rec.party_id             := ln_party_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_request_type_id;
          lr_TerrServReq_Rec.incident_severity_id := lr_service_request_rec.severity_id;
          lr_TerrServReq_Rec.problem_code         := p_sr_req_rec.problem_code;
          lr_TerrServReq_Rec.incident_status_id   := lr_service_request_rec.status_id;
          lr_TerrServReq_Rec.sr_creation_channel  := p_sr_req_rec.channel;
          lr_TerrServReq_Rec.sr_cat_id            := lr_service_request_rec.category_id;
          --lr_TerrServReq_Rec.attribute1           := lc_terr_name;
          --lr_TerrServReq_Rec.warehouse_id         := ln_ebs_warehouse_id;
          --lr_TerrServReq_Rec.ord_line_type      := lc_item_type;
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
          x_msg_data := lx_msg_data;
        END IF;

        /****************************************************************************/
         IF lt_TerrResource_tbl.count > 0 THEN
        -- dbms_output.put_line('owner_group_id '||lt_TerrResource_tbl(1).resource_id);

            lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
            lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
        end if;
        
        IF lc_mail_flag = 'Y' then
            lr_service_request_rec.owner_group_id := null;
            lr_service_request_rec.group_type     := null;
        end if;

      /*******************************************************************************
          Creating Service Request
      *******************************************************************************/
        IF (nvl(x_return_status,'S') = 'S') then
              apps.cs_servicerequest_pub.Create_ServiceRequest (
                                  p_api_version => 2.0,
                                  p_init_msg_list => FND_API.G_TRUE,
                                  p_commit => FND_API.G_FALSE,
                                  x_return_status => lx_return_status,
                                  x_msg_count => lx_msg_count,
                                  x_msg_data => lx_msg_data,
                                  p_resp_appl_id => ln_resp_appl_id,
                                  p_resp_id => ln_resp_id,
                                  p_user_id => g_user_id,
                                  p_login_id => ln_user_id,
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
            x_msg_data := lx_msg_data;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => lx_msg_data,
                              p_msg_index_out => lx_msg_index_out);
                x_msg_data := lx_msg_data;
          END IF;
      END IF;


      IF (lx_return_status = 'S') then

       IF p_sr_req_rec.order_number is not null then
       /**************************************************************************
            -- Populate order details to related objects
        *************************************************************************/
        --p_order_tbl   := XX_CS_SR_ORDER_TBL();
        i := p_order_tbl.first;
        IF I IS NOT NULL THEN
        loop
           -- Populate order details
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
     /************************************************************************
        -- Send mail for WH and Print On Demand Primary issues
      ************************************************************************/
      IF lc_mail_flag = 'Y' then

        xx_cs_sr_utils_pkg.Send_mail(p_request_number => lx_request_number,
                     p_return_status => lx_return_status,
                     p_return_msg => x_msg_data);
                     
      end if;
      ------------------------------------------------------------------------
      end if;
          x_return_status             := lx_return_status;
          p_request_id                := lx_request_id;
          p_request_num               := lx_request_number;
          p_sr_req_rec.request_id     := lx_request_id;
          p_sr_req_rec.request_number := lx_request_number;
      /*************************************************************
          Create Global Tickect with validate entered ticket number
      ***************************************************************/
      IF p_sr_req_rec.global_ticket_number is not null then
            if ln_incident_id is not null then
                CREATE_GLOBAL_TICKET (
                    P_REQUEST_ID      => ln_incident_id,
                    P_USER_ID		=> g_user_id,
                    P_APPL_ID           => ln_resp_appl_id,
                    P_RESP_ID            => ln_resp_id,
                    P_TO_INCIDENT_ID	  =>lx_request_id,
                    P_TO_INCIDENT_NUMBER  => lx_request_number,
                    X_RETURN_STATUS	   => lx_return_status,
                    X_MSG_COUNT		   => lx_msg_count,
                    X_MSG_DATA		   => x_msg_data,
                    X_LINK_ID		   => ln_link_id);
            end if;
        end if;
end if;
       /**************************************************************/
end if; -- Party id check
exception
      when others then
        x_return_status             := 'F';
        x_msg_data                  :=  x_msg_data||' '||sqlerrm;
END Create_ServiceRequest;

/********************************************************************************
   Verify global ticket
********************************************************************************/

FUNCTION GLOBAL_TICKET_NUMBER (P_INCIDENT_ID IN NUMBER,
                               P_GLOBAL_TICKET IN NUMBER,
                               P_GLOBAL_TICKET_FLAG IN VARCHAR2)
RETURN NUMBER IS
ln_incident_id    number;
begin
   IF P_GLOBAL_TICKET_FLAG = 'Y'
      AND P_GLOBAL_TICKET IS NULL THEN

      begin
        select from_incident_id
        into ln_incident_id
        from cs_incident_links
        where object_type = 'SR'
        and   subject_id = p_incident_id
        and   link_type = 'PARENT'
        and   to_number(from_incident_number) = nvl(p_global_ticket, to_number(from_incident_number))
        and   end_date_active is null
        and   rownum < 2;
      exception
        when others then
          ln_incident_id := null;
      end;
  ELSE
    IF P_GLOBAL_TICKET IS NOT NULL THEN
     begin
      select to_incident_id
      into ln_incident_id
      from cs_incident_links
      where object_type = 'SR'
      and   object_id = p_incident_id
      and   link_type = 'PARENT'
      and   to_number(from_incident_number) = nvl(p_global_ticket, to_number(from_incident_number))
      and   end_date_active is null;
    exception
      when others then
        ln_incident_id := null;
    end;

    else
       ln_incident_id := p_incident_id;
    end if;
  end if;

  return ln_incident_id;
END;
/*****************************************************************************
  Get Global Ticket Number if exists
*******************************************************************************/
FUNCTION GET_GLOBAL_TICKET (P_INCIDENT_ID IN NUMBER)
RETURN NUMBER IS
ln_from_incident_number    number;
begin
   begin
    select from_incident_number
    into ln_from_incident_number
    from cs_incident_links
    where object_type = 'SR'
    and   object_id = p_incident_id
    and   link_type = 'PARENT'
    and   end_date_active is null;
  exception
    when others then
      ln_from_incident_number := null;
  end;

  return ln_from_incident_number;
END;

/*********************************************************************************
   Search Service Request details
********************************************************************************/

PROCEDURE Search_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                                 p_sr_req_tbl       in out nocopy XX_CS_SR_TBL_TYPE,
                                 p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                                 p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                                 x_return_status    in out nocopy varchar2,
                                 x_msg_data         in out nocopy varchar2)
IS
CURSOR C1 IS
select alb.incident_id,
       alb.incident_number,
       alb.creation_date,
       decode(f.user_name, 'CS_ADMIN', alb.error_code,f.user_name)  created_by,
       alb.incident_attribute_9 customer_id,
       tlb.name,
       cs.description,
       st.name status,
       alb.incident_attribute_1 order_number
from cs_incidents_all_b alb,
     cs_incident_types_tl tlb,
     cs_lookups cs,
     cs_incident_statuses st,
     fnd_user f
where st.incident_status_id = alb.incident_status_id
and   cs.lookup_code = alb.problem_code
and   alb.incident_type_id = tlb.incident_type_id
and   nvl(alb.incident_attribute_9,'x') = nvl(lpad(to_char(p_sr_req_rec.customer_id),8,0),nvl(alb.incident_attribute_9,'x'))
and   tlb.incident_type_id = nvl(p_sr_req_rec.type_id,tlb.incident_type_id)
--and   tlb.name = nvl(p_sr_req_rec.type_name, tlb.name)
and   alb.incident_status_id = nvl(to_number(p_sr_req_rec.status_name),alb.incident_status_id)
and   nvl(alb.problem_code,'x') = decode(p_sr_req_rec.problem_code,null,nvl(alb.problem_code,'x'),p_sr_req_rec.problem_code)
and   alb.creation_date = nvl(p_sr_req_rec.request_date,alb.creation_date)
and   alb.incident_number = nvl(to_char(p_sr_req_rec.request_number), alb.incident_number)
and   alb.incident_id = nvl(p_sr_req_rec.request_id, alb.incident_id)
and   alb.incident_id  = decode(nvl(p_sr_req_rec.global_ticket_flag,'N'), 'Y',
                XX_CS_SERVICEREQUEST_PKG.GLOBAL_TICKET_NUMBER(alb.incident_id,p_sr_req_rec.global_ticket_number, p_sr_req_rec.global_ticket_flag),
                XX_CS_SERVICEREQUEST_PKG.GLOBAL_TICKET_NUMBER(alb.incident_id,p_sr_req_rec.global_ticket_number, p_sr_req_rec.global_ticket_flag))
and   nvl(alb.incident_attribute_1,'x') = nvl(p_sr_req_rec.order_number,nvl(alb.incident_attribute_1,'x'))
and   f.user_id = alb.created_by
and   cs.lookup_type = 'REQUEST_PROBLEM_CODE'
and   cs.enabled_flag = 'Y'
and   st.incident_subtype = 'INC'
and   rownum < 501
order by alb.incident_id desc;

CURSOR C3 IS
select alb.incident_id,
       alb.incident_number,
       alb.creation_date,
       decode(f.user_name, 'CS_ADMIN', alb.error_code,f.user_name)  created_by,
       alb.incident_attribute_9 customer_id,
       tlb.name,
       cs.description,
       st.name status,
       alb.incident_attribute_1 order_number
from cs_incidents_all_b alb,
     cs_incident_types_tl tlb,
     cs_lookups cs,
     cs_incident_statuses st,
     fnd_user f
where st.incident_status_id = alb.incident_status_id
and   cs.lookup_code        = alb.problem_code
and   alb.incident_type_id  = tlb.incident_type_id
and   nvl(alb.incident_attribute_9,'x') = nvl(lpad(to_char(p_sr_req_rec.customer_id),8,0),nvl(alb.incident_attribute_9,'x'))
and   tlb.incident_type_id = nvl(p_sr_req_rec.type_id,tlb.incident_type_id)
and   alb.incident_status_id = nvl(to_number(p_sr_req_rec.status_name),alb.incident_status_id)
and   nvl(alb.problem_code,'x') = decode(p_sr_req_rec.problem_code,null,nvl(alb.problem_code,'x'),p_sr_req_rec.problem_code)
and   alb.creation_date = nvl(p_sr_req_rec.request_date,alb.creation_date)
and   alb.incident_number = nvl(to_char(p_sr_req_rec.request_number), alb.incident_number)
and   alb.incident_id = nvl(p_sr_req_rec.request_id, alb.incident_id)
and   nvl(alb.incident_attribute_1,'x') = nvl(p_sr_req_rec.order_number,nvl(alb.incident_attribute_1,'x'))
and   f.user_id = alb.created_by
and   cs.lookup_type = 'REQUEST_PROBLEM_CODE'
and   cs.enabled_flag = 'Y'
and   st.incident_subtype = 'INC'
and   rownum < 501
order by alb.incident_id desc;
/************************************************************************************
 Release 2 code change in above query
 --and  a.customer_id = nvl(p_sr_req_rec.customer_id, a.customer_id) -- for release2
*************************************************************************************/
c1_rec                c1%rowtype;
c3_rec                c3%rowtype;
I                     NUMBER := 0;
j                     NUMBER := 0;
BEGIN
      x_msg_data := null;
      I                      := 1;
      P_SR_REQ_TBL           := XX_CS_SR_TBL_TYPE();
      j                      := 1;
      P_ORDER_TBL            := XX_CS_SR_ORDER_TBL();

    IF p_sr_req_rec.request_id is not null or
      p_sr_req_rec.request_number is not null then
        Search_Single_SR (p_sr_req_rec    => p_sr_req_rec,
                          p_sr_req_tbl    => p_sr_req_tbl,
                          p_order_tbl     => p_order_tbl,
                          p_ecom_site_key => p_ecom_site_key,
                          x_return_status => x_return_status,
                          x_msg_data      => x_msg_data);
    ELSE
      IF p_sr_req_rec.global_ticket_flag = 'Y' then
        OPEN C1;
        LOOP
        FETCH C1 INTO C1_REC;
        EXIT WHEN C1%NOTFOUND;

          p_sr_req_tbl.extend;
          Initialize_Line_Object(p_sr_req_tbl(i));

        BEGIN
             p_sr_req_tbl(i).request_date             := c1_rec.creation_date;
             p_sr_req_tbl(i).request_id	              := c1_rec.incident_id;
             p_sr_req_tbl(i).request_number           := c1_rec.incident_number;
             p_sr_req_tbl(i).type_name                := c1_rec.name;
             p_sr_req_tbl(i).status_name              := c1_rec.status;
             p_sr_req_tbl(i).customer_id              := c1_rec.customer_id;
             p_sr_req_tbl(i).problem_code             := c1_rec.description;
             p_sr_req_tbl(i).order_number             := c1_rec.order_number;
             p_sr_req_tbl(i).user_id                  := c1_rec.created_by;
        exception
           when others then
             x_return_status := 'F';
             x_msg_data := SQLERRM;
        END;
         I := I + 1;
        END LOOP;
        CLOSE C1;
      ELSE
          OPEN C3;
          LOOP
          FETCH C3 INTO C3_REC;
          EXIT WHEN C3%NOTFOUND;

            p_sr_req_tbl.extend;
            Initialize_Line_Object(p_sr_req_tbl(i));

          BEGIN
               p_sr_req_tbl(i).request_date             := c3_rec.creation_date;
               p_sr_req_tbl(i).request_id	        := c3_rec.incident_id;
               p_sr_req_tbl(i).request_number           := c3_rec.incident_number;
               p_sr_req_tbl(i).type_name                := c3_rec.name;
               p_sr_req_tbl(i).status_name              := c3_rec.status;
               p_sr_req_tbl(i).customer_id              := c3_rec.customer_id;
               p_sr_req_tbl(i).problem_code             := c3_rec.description;
               p_sr_req_tbl(i).order_number             := c3_rec.order_number;
               p_sr_req_tbl(i).user_id                  := c3_rec.created_by;

          exception
             when others then
               x_return_status := 'F';
               x_msg_data := SQLERRM;
          END;
           I := I + 1;
          END LOOP;
          CLOSE C3;
       END IF;
    END IF;
         x_return_status := 'S';
    EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'F';
         x_msg_data := SQLERRM;
END Search_ServiceRequest;

/*********************************************************************************
   Search Single Service Request details
********************************************************************************/

PROCEDURE Search_Single_SR (p_sr_req_rec       in out nocopy XX_CS_SR_REC_TYPE,
                            p_sr_req_tbl       in out nocopy XX_CS_SR_TBL_TYPE,
                            p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                            p_ecom_site_key    in out nocopy XX_GLB_SITEKEY_REC_TYPE,
                            x_return_status    in out nocopy varchar2,
                            x_msg_data         in out nocopy varchar2)
is

-- New Variables
lc_user_name        varchar2(50);
ln_incident_number  number;


CURSOR C1 IS
select alb.incident_id,
       alb.incident_number,
       alb.creation_date,
       alb.created_by, 
       alb.error_code,
       tlc.summary,
       alb.incident_attribute_9 customer_id,
       tlb.name,
       cs.description,
       st.name status,
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
       alb.incident_attribute_15 sales_rep_contact_name,
       alb.incident_attribute_6 sales_rep_contract_email,
       alb.incident_attribute_7 preferred_contact,
       alb.incident_attribute_5 contact_name,
       alb.incident_attribute_8 contact_email,
       alb.incident_attribute_14  contact_phone,
       alb.tier_version item_type,
       alb.tier zz_flag,
       alb.operating_system ship_to,
       null global_ticket_number
       --XX_CS_SERVICEREQUEST_PKG.GET_GLOBAL_TICKET(alb.incident_id) global_ticket_number
from cs_incidents_all_b alb,
     cs_incident_types_tl tlb,
     cs_incidents_all_tl tlc,
     cs_lookups cs,
     cs_incident_statuses st 
where st.incident_status_id = alb.incident_status_id
and   cs.lookup_code = alb.problem_code
and   tlc.incident_id = alb.incident_id
and   alb.incident_type_id = tlb.incident_type_id
and   alb.incident_number = to_char(ln_incident_number)
--and   alb.incident_id = nvl(p_sr_req_rec.request_id, alb.incident_id)
and   cs.lookup_type = 'REQUEST_PROBLEM_CODE'
and   cs.enabled_flag = 'Y'
and   st.incident_subtype = 'INC'
and   st.language = userenv('LANG')
and   tlb.language = userenv('LANG');
--order by alb.incident_id desc;

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
where service_request_id = c1_rec.incident_id
and  quantity is not null;

c2_rec                c2%rowtype;
j                     NUMBER := 0;

BEGIN
      x_msg_data := null;
      I                      := 1;
      P_SR_REQ_TBL           := XX_CS_SR_TBL_TYPE();
      j                      := 1;
      P_ORDER_TBL            := XX_CS_SR_ORDER_TBL();
      
      IF p_sr_req_rec.request_number is null then
        begin
           select incident_number 
           into ln_incident_number
           from cs_incidents_all_b
           where incident_id = p_sr_req_rec.request_id;
        exception
            when others then 
               null;
        end;
      else
          ln_incident_number := p_sr_req_rec.request_number;
      end if;
      
    
      OPEN C1;
      LOOP
      FETCH C1 INTO C1_REC;
      EXIT WHEN C1%NOTFOUND;
      
      begin 
        select user_name 
        into lc_user_name
        from fnd_user
        where user_id = c1_rec.created_by;
      exception
        when others then
          lc_user_name := 'CS_ADMIN';
      END;

        p_sr_req_tbl.extend;
        Initialize_Line_Object(p_sr_req_tbl(i));

      BEGIN

           p_sr_req_tbl(i).request_date             := c1_rec.creation_date;
           p_sr_req_tbl(i).request_id	            := c1_rec.incident_id;
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
           --p_sr_req_tbl(i).ship_date                := c1_rec.ship_date;
           p_sr_req_tbl(i).global_ticket_flag       := c1_rec.customer_ticket_number;
           p_sr_req_tbl(i).account_mgr_email        := c1_rec.account_mgr_email;
           p_sr_req_tbl(i).sales_rep_contact        := c1_rec.sales_rep_contact;
           p_sr_req_tbl(i).customer_sku_id          := c1_rec.item_type;
           p_sr_req_tbl(i).sales_rep_contact_email  := c1_rec.sales_rep_contract_email;
           p_sr_req_tbl(i).sales_rep_contact_name   := c1_rec.sales_rep_contact_name;
           p_sr_req_tbl(i).preferred_contact        := c1_rec.preferred_contact;
           p_sr_req_tbl(i).contact_name             := c1_rec.contact_name;
           p_sr_req_tbl(i).contact_phone            := c1_rec.contact_phone;
           p_sr_req_tbl(i).contact_email            := c1_rec.contact_email;
           If lc_user_name = 'CS_ADMIN' then
              p_sr_req_tbl(i).user_id                  := c1_rec.error_code;
           else
              p_sr_req_tbl(i).user_id                  := lc_user_name;
           end if;
           p_sr_req_tbl(i).global_ticket_number     := c1_rec.global_ticket_number;
           p_sr_req_tbl(i).zz_flag                  := c1_rec.zz_flag;
           p_sr_req_tbl(i).ship_to                  := c1_rec.ship_to;
     
         begin
            select note
            into p_sr_req_tbl(i).comments
            from cs_sr_notes_v
            where incident_id = c1_rec.incident_id
            and   note_status = 'E'
            and rownum < 2;
          exception
            when others then
              p_sr_req_tbl(i).comments := null;
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
END Search_Single_SR;

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
select csv.note_type_meaning,
       csv.note,
       csv.creation_date,
       decode(csv.user_name,'CS_ADMIN', decode(jtf.entered_by, jtf.created_by,
           nvl(cs.error_code,csv.user_name),to_char(jtf.entered_by)), csv.user_name) user_name
from cs_sr_notes_v csv,
     jtf_notes_b jtf,
     cs_incidents cs
where cs.incident_id = csv.incident_id
and   jtf.jtf_note_id = csv.id
and   csv.incident_id =  p_request_id
and   csv.note_status = 'E'
order by csv.creation_date desc;

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
end Search_notes;

/********************************************************************************
  UPDATE Service Request by Status or Add note
*********************************************************************************/
Procedure Update_ServiceRequest(p_sr_request_id    in number,
                                p_sr_status_id     in VARCHAR2,
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
      into g_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
        x_msg_data := 'Error while selecting userid '||sqlerrm;
    end;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    apps.fnd_global.apps_initialize(g_user_id,ln_resp_id,ln_resp_appl_id);

   /************************************************************************
    -- Get Object version
    *********************************************************************/
     SELECT object_version_number
     INTO ln_obj_ver
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_sr_request_id;
    /*********************************************************************
      -- Get Status
    **********************************************************************/
    BEGIN
      SELECT NAME, INCIDENT_STATUS_ID
      INTO LC_SR_STATUS, LN_STATUS_ID
      FROM CS_INCIDENT_STATUSES_VL
      WHERE INCIDENT_SUBTYPE = 'INC'
      AND NAME  = P_SR_STATUS_ID;
    EXCEPTION
      WHEN OTHERS THEN
        LC_SR_STATUS := NULL;
    END;
    /***********************************************************************
     -- Update SR
     ***********************************************************************/
    -- DBMS_OUTPUT.PUT_LINE('Status '||ln_status_id||' '||lc_sr_status);
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

   /**********************************************************************
    -- update notes.
    **********************************************************************/
    IF p_sr_notes.notes is not null
      and nvl(x_return_status,'S') = 'S' then
      XX_CS_SERVICEREQUEST_PKG.CREATE_NOTE (p_request_id   => p_sr_request_id,
                                          p_sr_notes_rec => p_sr_notes,
                                          p_return_status => x_return_status,
                                          p_msg_data => x_msg_data);
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

                  --DBMS_OUTPUT.PUT_LINE(x_msg_data);
            END LOOP;
          ELSE
                      --Only one error
                  FND_MSG_PUB.Get(
                              p_msg_index => 1,
                              p_encoded => 'F',
                              p_data => x_msg_data,
                              p_msg_index_out => ln_msg_index_out);
          END IF;
          x_msg_data := x_msg_data;
      END IF;

    COMMIT;

END Update_ServiceRequest;

/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_request_id           in number,
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
ln_ext_user             number;

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
ln_source_object_id		:= p_request_id;
lc_source_object_code		:= 'SR';
lc_note_status			:= 'E';  -- (P-Private, E-Publish, I-Public)
lc_note_type			:= 'GENERAL';
lc_notes			:= p_sr_notes_rec.notes;
lc_notes_detail			:= p_sr_notes_rec.note_details;

begin
  ln_ext_user := translate(upper(p_sr_notes_rec.created_by),'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-', '0123456789');
exception
  when others then
    ln_ext_user := null;
end;

IF ln_ext_user is not null then
    ln_entered_by	:= ln_ext_user;
else
    ln_entered_by	:= FND_GLOBAL.user_id;
end if;
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
/*******************************************************************************
*******************************************************************************/
END XX_CS_SERVICEREQUEST_PKG;
/
show errors;
exit;