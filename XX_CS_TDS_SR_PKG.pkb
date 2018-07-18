create or replace
PACKAGE BODY XX_CS_TDS_SR_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_SR_PKG                                         |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-Apr-10   Raj Jagarlamudi  Initial draft version       |
-- |1.1                   Raj Jagarlamudi  Add outbound queue          |
-- |1.2       17-OCT-10   Raj Jagarlamudi  Contat info                 |
-- |1.3       15-AUG-12   Raj Jagarlamudi  SMB subscription changes    |
-- |1.4       21-OCT-13   Raj Jagarlamudi  MPS Returns added to AOPS   |
-- |1.5       24-Jun-13   Arun Gannarapu   Made changes to pass        |
-- |                                       auto_assign to "Y"          |
-- |1.6       31-JAN-14   Arun Gannarapu   Made changes to             |
--                                         reset the variable          |
-- |1.7       01-APR-14   Arun Gannarapu   Made changes to 
--                                         re-initialize the           |
--                                         x_return_status and x_msg_data
-- |1.8       28-JAN-2016 Vasu Raparla     Removed Schema References   |
-- |                                       for R12.2                   |
-- |1.9       09-SEP-16   arun Gannarapu   Defect 39255 for 12.2 retrofit
-- +===================================================================+

G_PKG_NAME      CONSTANT VARCHAR2(30):= 'XX_CS_TDS_SR_PKG';
v_obj_ver       NUMBER;
g_user_id       number;
G_SR_NUM        NUMBER;

PROCEDURE Initialize_td_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_TDS_SR_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_TDS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL);

END Initialize_td_Line_Object;
----
PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_SR_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL);

END Initialize_Line_Object;
/************************************************************************************/
/*****************************************************************************
-- Log Messages
****************************************************************************/
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
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_TDS_SR_PKG'
     ,p_program_id              => G_SR_NUM
     ,p_module_name             => 'CSF'
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
/**************************************************************************/
/*-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------*/
PROCEDURE Create_ServiceRequest (p_sr_req_rec       in out nocopy XX_CS_TDS_SR_REC_TYPE,
                                 x_request_id       out nocopy number,
                                 x_request_num      out nocopy varchar2,
                                 x_order_num        out nocopy varchar2,
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
lc_sku_categories            varchar2(250);
lc_skus                      varchar2(250);
lc_sku_descr                 varchar2(1000);
ln_quantity                  varchar2(50);
lc_vendor                    varchar2(250);
lc_sku_category              varchar2(250);
lc_old_category              varchar2(250);
lc_type_category             varchar2(250);
lc_message                   varchar2(2000);
lc_address                   varchar2(500);
---
ln_time_id                   number := 1;
ln_res_time                  number := 0;
ld_order_date                date;

-- New---
ln_type_id                  number;
ln_status_id                number;
lc_status                   varchar2(250);
ln_obj_ver                  number;
lc_request_number           varchar2(25) := NULL;

cursor dev_cur is
select qp.node_name,
       qd.freeform_string node_value 
from   ies_question_data qd,
       ies_questions qp,
       ies_panels ip
where  ip.panel_id = qp.panel_id
and    qp.question_id = qd.question_id
and    ip.panel_name = 'Device'
and    qd.transaction_id = p_sr_req_rec.dev_ques_ans_id;

dev_rec  dev_cur%rowtype;

BEGIN
     
     lc_message := 'Received MQ message for Order '||p_sr_req_rec.order_number|| ' Customer Id '||p_sr_req_rec.customer_id;
     Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST'
                       ,p_error_message_code =>   'XX_CS_AOPS_MESSAGE_LOG'
                       ,p_error_msg          =>  lc_message);

lc_request_number := NULL;
x_return_status   := NULL;
x_msg_data        := NULL;

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

fnd_global.apps_initialize(g_user_id,ln_resp_id,ln_resp_appl_id);

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
                       
IF (nvl(x_return_status,'S') = 'S') then

    If p_sr_req_rec.customer_id is not null then
     /*******************************************************************************
      -- for only release 1 mapping with orig_system_reference, now GMill will pass
         the AOPS customer id and the following code will reterive the EBS customer id.
         The following code will change after orders book into EBIZ
      *******************************************************************************/
      begin
        select hzp.address1||' '||hzp.address2||', '||hzp.city||','||hzp.state||'-'||hzp.postal_code||','||hzp.country address,
              hzp.party_type,
              hzc.cust_account_id,
              hzp.party_id,
              hzp.party_number,
              hzc.cust_account_id
        into lc_address,
             lr_service_request_rec.caller_type,
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
          x_msg_data := 'CUSTID: '||p_sr_req_rec.customer_id||' Customer not exists in EBS '||sqlerrm;
          x_order_num := p_sr_req_rec.order_number;
        when others then
          x_return_status := 'F';
          x_msg_data := 'CUSTID: '||p_sr_req_rec.customer_id||'Order no '||p_sr_req_rec.order_number||' Error while selecing cust_account_id '||sqlerrm;
          x_order_num := p_sr_req_rec.order_number;
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
             x_msg_data := 'Order no '||p_sr_req_rec.order_number||' Bill to site information not exists';
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
              from  hz_party_sites s1,
                    hz_party_site_uses s2,
                    hz_orig_sys_references hzo
              where s1.party_id = hzo.party_id
              and   s1.party_site_id = s2.party_site_id
              and   hzo.orig_system_reference = lpad(to_char(p_sr_req_rec.customer_id),8,0)||'-'||p_sr_req_rec.ship_to||'-A0'
              and   hzo.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
              and   s2.site_use_type = 'SHIP_TO'
              and   s1.identifying_address_flag = 'Y';
            EXCEPTION
              WHEN OTHERS THEN
                x_msg_data := 'Order no '||p_sr_req_rec.order_number||' Ship to site information not exists';
            END;
          WHEN OTHERS THEN
             x_msg_data := 'Ship to site information not exists';
      END;
      /********************************************************************
         Selecting Contact Points.
      *********************************************************************/
       begin
          select  --hr.object_id,
                  hr.party_id,
                  hzt.contact_point_id,
                  hzt.contact_point_type,
                  hzt.primary_flag,
                --  hzt.contact_point_purpose
                'PARTY_RELATIONSHIP'
           INTO  ln_contact_party_id,
                ln_contact_point_id,
                lc_contact_point_type,
                lc_primary_flag,
                lc_contact_type
          from  hz_contact_points hzt,
                hz_relationships hr,
                hz_org_contacts hcon
          where hr.party_id = hzt.owner_table_id
          and   hcon.orig_system_reference = p_sr_req_rec.contact_id
          and   hcon.party_relationship_id = hr.relationship_id
          and   hr.subject_type = 'ORGANIZATION'
          and   hzt.status = 'A'
          and   hzt.primary_flag = 'Y';
         -- and   rownum=1;
        exception
        when others then
          ln_contact_party_id := null;
          ln_contact_point_id := null;
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
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecing party_id '||sqlerrm;
          x_order_num := p_sr_req_rec.order_number;
      end;

      lr_service_request_rec.customer_id := ln_party_id;
      lc_contact_point_type := 'EMAIL';
      lc_primary_flag       := 'Y';
      lc_contact_type       := 'PARTY_RELATIONSHIP';
    end if;

-- checking party id exists or not
 IF (nvl(x_return_status,'S') = 'S') then
    
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
            x_msg_data := 'Error while selecing severity id '||sqlerrm;
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
          x_msg_data := 'Error while selecing urgency id '||sqlerrm;
    end;
    
    /******************************************************************************/
    /* Retrive the Time Zone Id and calendar using warehouse id
    /* For order related use warehouse time zone id.
    /* Call center time zone for non-order related.
    /******************************************************************************/
    begin
      select organization_id
      into ln_ebs_warehouse_id
      from hr_all_organization_units
      where to_number(attribute1) = p_sr_req_rec.location_id;
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
      /**************************************************************************
      -- --
      ***************************************************************************/
     
          begin
            select mtls.category_set_id, mtlb.category_id
            into lr_service_request_rec.category_set_id,
                 lr_service_request_rec.category_id
            from mtl_category_sets_vl mtls,
                 mtl_categories_b mtlb
            where mtlb.structure_id = mtls.structure_id
            and   mtls.category_set_name = 'CS Warehouses'
            and   mtlb.segment1 like p_sr_req_rec.location_id;
          exception
            when others then
              lr_service_request_rec.category_set_id := null;
              lr_service_request_rec.category_id := null;
          end;
      
  IF p_sr_req_rec.order_number is not null then
       /**************************************************************************
            -- Populate order details to external attributes
        *************************************************************************/
        i := p_order_tbl.first;
        IF I IS NOT NULL THEN
        loop
           IF I = 1 then
              lc_sku_category     := substr(p_order_tbl(i).attribute2,1,1);
              lc_old_category     := substr(p_order_tbl(i).attribute2,1,1);
              lc_type_category    := lc_sku_category;
              lc_sku_categories   := lc_sku_category;
              lc_skus             := p_order_tbl(i).sku_id;
           else
              lc_sku_category   :=  substr(p_order_tbl(i).attribute2,1,1);
              lc_sku_categories := lc_sku_categories ||','||lc_sku_category;
              IF length(lc_skus) > 150 then
                lc_skus           := substr(lc_skus,1,150);
              else
                lc_skus           := lc_skus||','||p_order_tbl(i).sku_id;
              end if;
              IF lc_sku_category <> lc_old_category then 
                lc_type_category  := 'M';
              end if;
           end if;
         EXIT WHEN I = p_order_tbl.last;
          I := p_order_tbl.NEXT(I);
         end loop;
            lr_service_request_rec.External_Context     := 'TDS SKU Details';
            lr_service_request_rec.external_attribute_1 := lc_skus ;
            lr_service_request_rec.external_attribute_3 := lc_sku_categories ;
       end if;
  END IF;
  -- device detail population
  begin
    open dev_cur;
    loop
    fetch dev_cur into dev_rec;
    exit when dev_cur%notfound;
          
          IF dev_rec.node_name = 'Manufacturer' then
              lr_service_request_rec.request_attribute_12 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Brand' then
              lr_service_request_rec.request_attribute_4 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Model' then
              lr_service_request_rec.request_attribute_6 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Type' then
              lr_service_request_rec.request_attribute_3 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'OS' then
              lr_service_request_rec.request_attribute_7 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Serial' then
              lr_service_request_rec.request_attribute_10 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Condition' then
              lr_service_request_rec.external_attribute_7 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Description' then
              lr_service_request_rec.external_attribute_10 := substr(dev_rec.node_value,1,150);
          ELSIF dev_rec.node_name = 'System Login' then
              lr_service_request_rec.external_attribute_8 := dev_rec.node_value;
          ELSIF dev_rec.node_name = 'Password' then
              lr_service_request_rec.external_attribute_9 := dev_rec.node_value;
          END IF;
          
    end loop;
    close dev_cur;
  end;

/*****************************************************************
-- Request Type Id
*******************************************************************/

    begin
      select ct.incident_type_id,
	         business_process_id
      into  ln_type_id,
	        lr_service_request_rec.business_process_id
      from cs_incident_types_tl ct,
          cs_incident_types_b cb
      where cb.incident_type_id = ct.incident_type_id
      and ct.name like 'TDS%'
      and cb.attribute6 = lc_type_category
      and cb.end_date_active is null; 
    exception
     when others then
        BEGIN
            select ct.incident_type_id,
			       business_process_id
            into  ln_type_id,
			      lr_service_request_rec.business_process_id
            from  cs_incident_types_tl ct,
                  cs_incident_types_b cb
            where cb.incident_type_id = ct.incident_type_id
            and ct.name = 'TDS-Multi Service'
            and cb.end_date_active is null; 
          EXCEPTION
          when others then
              x_return_status := 'F';
              x_msg_data := ' Error while selecting type '||sqlerrm;
              x_order_num := p_sr_req_rec.order_number;
        END;
    end;
  
    IF (nvl(x_return_status,'S') = 'S') then
         /******************************************************************************
        -- Response time, Resolution Time reterive from cs_incident_types_b.attribute1
        *******************************************************************************/
        begin
          select to_number(attribute1),
                 to_number(attribute2),
                 'RS_GROUP',
                 attribute9,
                 name
          into ln_obligation_time,
                 ln_resolution_time,
                 lr_service_request_rec.group_type,
                 lr_service_request_rec.request_context,
                 lc_request_type
          from cs_incident_types_vl
          where incident_type_id = ln_type_id;
        exception
          when others then
            ln_obligation_time := 3;
            ln_resolution_time := 4;
            lr_service_request_rec.group_type := 'RS_GROUP';
            lr_service_request_rec.request_context := 'ORDER';
        end;
        
        /**********************************************************************
          -- Determine Request Number
        **********************************************************************/
        begin
          select distinct request_number
          into lc_request_number
          from xx_cs_ies_sku_relations
          where service_id = p_sr_req_rec.dev_ques_ans_id
          and rownum < 2;
        exception
         when others then
            lc_message := 'Error while selecting SR number from IES for request# '||p_sr_req_rec.dev_ques_ans_id||'-'||SQLERRM;
            Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST'
                            ,p_error_message_code => 'XX_CS_AOPS_ERR5_LOG'
                            ,p_error_msg          =>  lc_message);
        end;
        
        IF lc_request_number is null then 
           select XX_CS_TDS_REQ_NO_S.NEXTVAL INTO lc_request_number from dual; 
           lc_request_number := lpad(p_sr_req_rec.location_id,5,0)||lc_request_number;
        end if;
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
        /*****************************************************************************
        -- Populate the SR Record type
        ******************************************************************************/
            lr_service_request_rec.request_date             := sysdate;
            lr_service_request_rec.incident_occurred_date   := sysdate;
            lr_service_request_rec.type_id                  := ln_type_id;
            ln_request_type_id                              := ln_type_id;
            lr_service_request_rec.problem_code             := 'TDS-SERVICES';
            lr_service_request_rec.status_id                := 1; 
            lr_service_request_rec.cust_ticket_number       := substr(p_sr_req_rec.order_number,1,9);
            lr_service_request_rec.request_attribute_1      := substr(p_sr_req_rec.order_number,1,9);
            lr_service_request_rec.request_attribute_13      := substr(p_sr_req_rec.order_number,10,12);
            lr_service_request_rec.request_attribute_2      := substr(lc_address,1,150);
            lr_service_request_rec.request_attribute_5      := p_sr_req_rec.contact_name;
            lr_service_request_rec.request_attribute_14     := p_sr_req_rec.contact_phone;
            lr_service_request_rec.request_attribute_9      := lpad(p_sr_req_rec.customer_id,8,0);
            lr_service_request_rec.request_attribute_11     := p_sr_req_rec.location_id;
            lr_service_request_rec.request_attribute_8      := p_sr_req_rec.contact_email;
            lr_service_request_rec.tier                     := p_sr_req_rec.dev_ques_ans_id;
            lr_service_request_rec.tier_version             := p_sr_req_rec.contact_id;
            lr_service_request_rec.operating_system         := p_sr_req_rec.ship_to;
            lr_service_request_rec.creation_program_code    := 'AOPS';
            lr_service_request_rec.last_update_program_code := 'AOPS';
            lr_service_request_rec.verify_cp_flag           := 'N';
            lr_service_request_rec.sr_creation_channel      := 'Email';
            lr_service_request_rec.last_update_channel      := 'Email';
            lr_service_request_rec.summary                  := 'Items : '||lc_skus;
            lr_service_request_rec.language                 := 'US';
            lr_service_request_rec.resource_type            := 'RS_EMPLOYEE';
            lr_service_request_rec.error_code               := p_sr_req_rec.user_id;
            lr_service_request_rec.obligation_Date          := ld_obligation_Date;
            lr_service_request_rec.exp_resolution_date      := ld_resolution_date;
            
        /*******************************************************************************/
        -- Adhoc contact information
        /*******************************************************************************/
        lr_service_request_rec.incident_address  := p_sr_req_rec.contact_name;
        --lr_service_request_rec.incident_city     := p_sr_req_rec.preferred_contact;
        lr_service_request_rec.incident_address2 := p_sr_req_rec.contact_phone;
        lr_service_request_rec.incident_address3 := p_sr_req_rec.contact_email;
        lr_service_request_rec.incident_address4 := p_sr_req_rec.contact_fax;
        /*******************************************************************************
        -- Populating Contacts table
        ********************************************************************************/
        IF ln_contact_point_id is not null then
          lt_contacts_tab(1).party_id := ln_contact_party_id;
          lt_contacts_tab(1).contact_point_id := ln_contact_point_id;
          lt_contacts_tab(1).CONTACT_POINT_TYPE := lc_contact_point_type;
          lt_contacts_tab(1).PRIMARY_FLAG := lc_primary_flag;
          lt_contacts_tab(1).CONTACT_TYPE := lc_contact_type ;  
        end if;
        /*******************************************************************************
        -- Notes table
        *******************************************************************************/
        IF length(p_sr_req_rec.comments) > 2000 then
          lt_notes_table(1).note        := ' Items : '||lc_skus;
          lt_notes_table(1).note_detail := p_sr_req_rec.comments;
        else
          lt_notes_table(1).note        := p_sr_req_rec.comments||' Items :'||lc_skus;
          lt_notes_table(1).note_detail := 'Service Request created for Service Items '||lc_skus;
        end if;
        lt_notes_table(1).note_type   := 'GENERAL';
        
             --dbms_output.put_line('Org Type Id : '||p_sr_req_rec.type_id||' Fur Type Id '||ln_request_type_id);
             /************************************************************************
                  -- Get Resources
             *************************************************************************/
             -- Commented by AG 
             
             /*     lr_TerrServReq_Rec.service_request_id   := lx_request_id;
                  lr_TerrServReq_Rec.party_id             := ln_party_id;
                  lr_TerrServReq_Rec.incident_type_id     := ln_request_type_id;
                  lr_TerrServReq_Rec.sr_cat_id            := lr_service_request_rec.category_id;
               --*************************************************************************************************************
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
        
                --****************************************************************************
                 IF lt_TerrResource_tbl.count > 0 THEN
                -- dbms_output.put_line('owner_group_id '||lt_TerrResource_tbl(1).resource_id);
        
                    lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
                    lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
                end if;
                     */ -- Comment end AG 
    END IF;
      /*******************************************************************************
          Creating Service Request
      *******************************************************************************/
        IF (nvl(x_return_status,'S') = 'S') then
              cs_servicerequest_pub.Create_ServiceRequest (
                                  p_api_version => 4.0,
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
                                  p_request_number => lc_request_number,
                                  p_service_request_rec => lr_service_request_rec,
                                  p_notes => lt_notes_table,
                                  p_contacts => lt_contacts_tab,
                                  p_auto_assign => 'Y',
                                  p_auto_generate_tasks => 'N',
                                  x_sr_create_out_rec  => lx_sr_create_out_rec
                                 -- p_auto_assign  => 'N',
                                  --p_default_contract_sla_ind => 'N',
                                --  x_request_id => lx_request_id,
                                --  x_request_number => lx_request_number,
                                --  x_interaction_id => lx_interaction_id,
                                --  x_workflow_process_id => lx_workflow_process_id 
                                );
               lx_request_id := lx_sr_create_out_rec.request_id;
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
            -- SELECT ITEM DESCRIPTION
                BEGIN
                  SELECT DESCRIPTION 
                  INTO LC_SKU_DESCR
                  FROM MTL_SYSTEM_ITEMS
                  WHERE SEGMENT1 = p_order_tbl(i).sku_id
                  AND ORGANIZATION_ID = 441;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
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
                 attribute4,
                 attribute5)
                values(lx_request_id,
                      p_order_tbl(i).sku_id,
                      lc_sku_descr,
                      p_order_tbl(i).quantity,
                      p_order_tbl(i).order_link,  -- parent sku
                      sysdate,
                      user,
                      sysdate,
                      user,
                      p_order_tbl(i).attribute4, -- Subscription start date
                      p_order_tbl(i).order_sub, -- subscription_id
                      nvl(p_order_tbl(i).Manufacturer_info, p_order_tbl(i).order_number), -- Parent Category/order number
                      p_order_tbl(i).attribute1, -- Vendor Id
                      p_order_tbl(i).attribute2 -- Category Id 
                      ); 
            exception
              when others then
               x_return_status := 'F';
               x_msg_data := 'Error while populating items '||sqlerrm;
            end;
            --update sku relationship table.
            BEGIN
              update xx_cs_ies_sku_relations
              set quantity = p_order_tbl(i).quantity,
                  description = lc_sku_descr,
                  request_id = lx_request_id
              where service_id = p_sr_req_rec.dev_ques_ans_id
              and   sku = nvl(p_order_tbl(i).order_link,p_order_tbl(i).sku_id);
              
              commit;
            exception
              when others then
                 lc_message := 'Error while updating ies_sku table '||lx_request_number||' '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST'
                                     ,p_error_message_code =>   'XX_CS_AOPS_ERR_LOG'
                                     ,p_error_msg          =>  lc_message);
            END;
          EXIT WHEN I = p_order_tbl.last;
          I := p_order_tbl.NEXT(I);
         end loop;
         commit;
        END IF;
       end if;
      ------------------------------------------------------------------------
      -- Update the request
      ------------------------------------------------------------------------
         begin
            select object_version_number
            into ln_obj_ver
            from cs_incidents_all_b
            where incident_id = lx_request_id;
        exception 
           when others then
              ln_obj_ver := 1;
        end;
        
        -- update Service Request for change the status.
        /***********************************
          -- Status
          ************************************/
            begin
              select incident_status_id , name
               into ln_status_id, lc_status
               from cs_incident_statuses_vl
               where name = 'Service Not Started'
               and incident_subtype = 'INC'
               and end_date_active is null;
            exception
               when others then
                  lr_service_request_rec.status_id := 1;
            end;
            
            Begin
              -- DBMS_OUTPUT.PUT_LINE('Status '||ln_status_id||' '||lc_sr_status);
                 CS_SERVICEREQUEST_PUB.Update_Status
                  (p_api_version    => 2.0,
                  p_init_msg_list    => FND_API.G_TRUE,
                  p_commit        => FND_API.G_FALSE,
                  x_return_status    => lx_return_status,
                  x_msg_count            => lx_msg_count,
                  x_msg_data        => lx_msg_data,
                  p_resp_appl_id    => ln_resp_appl_id,
                  p_resp_id        => ln_resp_id,
                  p_user_id        => ln_user_id,
                  p_login_id        => NULL,
                  p_request_id        => lx_request_id,
                  p_request_number    => lx_request_number,
                  p_object_version_number => ln_obj_ver,
                  p_status_id         => ln_status_id,
                  p_status        => lc_status,
                  p_closed_date        => SYSDATE,
                  p_audit_comments    => NULL,
                  p_called_by_workflow    => NULL,
                  p_workflow_process_id    => NULL,
                  p_comments        => NULL,
                  p_public_comment_flag    => NULL,
                  x_interaction_id    => lx_interaction_id);
                  
                  commit;
              exception
                when others then
                   x_msg_data := 'Error while updating SR ';
                   lc_message := 'Error while updating SR# '||lx_request_number||' '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST'
                                     ,p_error_message_code =>   'XX_CS_AOPS_ERR_LOG'
                                     ,p_error_msg          =>  lc_message);
            end;
        -- CHECK ERRORS    
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
          x_msg_data := 'Error while updating SR '||x_msg_data;
        END IF;
        -----
        
      end if;
      
          x_return_status             := lx_return_status;
          x_request_id                := lx_request_id;
          x_request_num               := lx_request_number;
          x_order_num                 := p_sr_req_rec.order_number;
          p_sr_req_rec.request_id     := lx_request_id;
          p_sr_req_rec.request_number := lx_request_number;
     
end if;
       /**************************************************************/
end if; -- Party id check
exception
      when others then
        x_return_status             := 'F';
        x_msg_data                  := x_msg_data||' '||sqlerrm;
        x_order_num                 := p_sr_req_rec.order_number;
        
         lc_message := 'Error while in Create SR for Order '||p_sr_req_rec.order_number||' '||x_msg_data;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.CREATE_SERVICEREQUEST'
                                     ,p_error_message_code =>   'XX_CS_AOPS_ERR2_LOG'
                                     ,p_error_msg          =>  lc_message);
END Create_ServiceRequest;

/********************************************************************************
  UPDATE Service Request by Status and update SKU, quantity.
*********************************************************************************/
Procedure Update_ServiceRequest(p_sr_number        in varchar2,
                                p_sr_status_id     in VARCHAR2,
                                p_cancel_log       in VARCHAR2,
                                p_order_tbl        in out nocopy XX_CS_SR_ORDER_TBL,
                                x_return_status    in out nocopy varchar2,
                                x_msg_data         in out nocopy varchar2)
IS
      x_msg_count              NUMBER;
      x_interaction_id            NUMBER;
      x_workflow_process_id       NUMBER;
      x_msg_index_out             NUMBER;
      ln_obj_ver                  NUMBER;
      lc_sr_status                VARCHAR2(25);
      ln_status_id                number;
      ln_incident_id              number;
      ln_msg_index                number;
      ln_msg_index_out            number;
      ln_user_id                  number; 
      ln_resp_appl_id             number :=  514;
      ln_resp_id                  number := 21739;  -- Customer Support
      i                           number;
      lc_full_cancel              varchar2(1) := 'N';
      lc_cancel_log               varchar2(1000);
      lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
      lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
      lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
      lc_message                  VARCHAR2(2000);
      lc_mps_sr_number            VARCHAR2(25);
      lc_toner_order              VARCHAR2(25);
      lc_serial_no                VARCHAR2(25);
      lc_mps_flag                 VARCHAR2(1) := 'N';
      ln_return_code              NUMBER;
      lc_email_add                VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_SHIPTO_ADDR');
      
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
    fnd_global.apps_initialize(g_user_id,ln_resp_id,ln_resp_appl_id);

   /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
       SELECT object_version_number, incident_id
       INTO ln_obj_ver, ln_incident_id
       FROM   cs_incidents_all_b
       WHERE  incident_number = p_sr_number;
    EXCEPTION
      WHEN OTHERS THEN
         LN_INCIDENT_ID := NULL;
         lc_message := 'No SR found for  '||p_sr_number;
         Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                       ,p_error_message_code =>   'XX_CS_AOPS1_CANCEL_LOG'
                       ,p_error_msg          =>  lc_message);
    END;
    
    IF ln_incident_id is null then
          lc_message := 'MPS order  '||p_sr_number||' '||P_SR_STATUS_ID;
          Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                                 ,p_error_message_code =>   'XX_CS_AOPS5_LOG'
                                 ,p_error_msg          =>  lc_message);
                                 
      IF length(p_sr_number) = 12 then
        LC_TONER_ORDER := SUBSTR(P_SR_NUMBER,1,9);
         begin
           select request_number, serial_no 
           into lc_mps_sr_number, lc_serial_no
           from xx_cs_mps_device_details
           where toner_order_number = lc_toner_order
           and rownum < 2;
           
           lc_mps_flag := 'Y';
           lc_full_cancel := 'Y';
         exception 
            when others then
               lc_mps_sr_number := null;
               lc_message := 'No MPS SR found for  '||p_sr_number;
               Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                             ,p_error_message_code =>   'XX_CS_AOPS2_CANCEL_LOG'
                             ,p_error_msg          =>  lc_message);
          END;
           
      end if;
      
    END IF;
         
        -- MPS Order updates
    IF LC_MPS_SR_NUMBER IS NOT NULL THEN
           begin
              select incident_id , object_version_number
              into ln_incident_id , ln_obj_ver
              from cs_incidents_all_b
              where incident_number = lc_mps_sr_number;
           exception
             when others then
                ln_incident_id := null;
            end;
          IF P_SR_STATUS_ID = 'Cancelled' THEN
            begin  
                  update xx_cs_mps_device_details
                  set toner_order_number = null, 
                      toner_order_date = null,
                      request_number = null,
                      usage_billed = null,
                      toner_stock = toner_stock - 1
                  where serial_no = lc_serial_no
                  and  toner_order_number = lc_toner_order;
                  
                  commit;
            exception
                when others then
                  lc_message := 'Error while updating MPS order  '||p_sr_number;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                                 ,p_error_message_code =>   'XX_CS_AOPS3_CANCEL_LOG'
                                 ,p_error_msg          =>  lc_message);
            end;
          ELSE
              begin  
                  update xx_cs_mps_device_details
                  set usage_billed = null,
                      toner_stock = toner_stock - 1
                  where serial_no = lc_serial_no
                  and  toner_order_number = lc_toner_order;
                  
                  commit;
            exception
                when others then
                  lc_message := 'Error while updating MPS order  '||p_sr_number;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                                 ,p_error_message_code =>   'XX_CS_AOPS3_CANCEL_LOG'
                                 ,p_error_msg          =>  lc_message);
            end;
            
            IF lc_email_add is not null then
            
            XX_CS_MESG_PKG.send_email (sender    => 'SVC-CallCenter@officedepot.com',
                                        recipient      => lc_email_add,
                                        cc_recipient   => null ,
                                        bcc_recipient  => null ,
                                        subject        => 'Return Order for '||lc_serial_no,
                                        message_body   => 'Order# '||p_sr_number||' Returned '||p_cancel_log,
                                        p_message_type => 'CONFIRMATION',
                                        IncidentNum    => ln_incident_id,
                                        return_code    => ln_return_code );
                                        
            end if; -- email address
          end if;
    END IF;    
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
    
     lc_message := 'Received cancel Order for '||p_sr_number|| ' Status '||p_sr_status_id;
     Log_Exception ( p_error_location     =>  'XX_CS_TDS_SR_PKG.UPDATE_SERVICEREQUEST'
                       ,p_error_message_code =>   'XX_CS_AOPS2_CANCEL_LOG'
                       ,p_error_msg          =>  lc_message);
                       
    IF ln_incident_id is not null then
    /**********************************************************************
       --Verify Quantity
    ************************************************************************/ 
    IF NVL(LC_MPS_FLAG,'N') = 'N' THEN
        I := p_order_tbl.first;
        IF I IS NOT NULL THEN
        loop
          
          IF lc_sr_status = 'Cancelled' then 
           -- UPDATE cancelled quanitity for each SKU
             begin  
                  update xx_cs_sr_items_link
                  set quantity = quantity - p_order_tbl(i).quantity, 
                      last_update_date = sysdate,
                      last_updated_by = user
                  where service_request_id = ln_incident_id
                  and   item_number = p_order_tbl(i).sku_id;
            exception
                when others then
                  x_return_status := 'F';
                  x_msg_data := 'Error while updating quantity '||sqlerrm;
            end;
          else
            -- UPDATE quantity
             begin  
                  update xx_cs_sr_items_link
                  set quantity = p_order_tbl(i).quantity, 
                      last_update_date = sysdate,
                      last_updated_by = user
                  where service_request_id = ln_incident_id
                  and   item_number = p_order_tbl(i).sku_id;
            exception
                when others then
                  x_return_status := 'F';
                  x_msg_data := 'Error while updating quantity '||sqlerrm;
            end;
          end if;
          
          EXIT WHEN I = p_order_tbl.last;
          I := p_order_tbl.NEXT(I);
         end loop;
         commit;
         end if;
         
         begin 
          select 'N'
          into lc_full_cancel
          from xx_cs_sr_items_link
          where service_request_id = ln_incident_id
          and   item_number = p_order_tbl(i).sku_id
          and   quantity > 0;
        exception
          when others then
             lc_full_cancel := 'Y';
        end;
    END IF;
    
        IF lc_full_cancel = 'Y' and ln_status_id is not null THEN
              lc_cancel_log := 'Order cancelled by AOPS';
              /***********************************************************************
               -- Update SR
               ***********************************************************************/
              -- DBMS_OUTPUT.PUT_LINE('Status '||ln_status_id||' '||lc_sr_status);
                 CS_SERVICEREQUEST_PUB.Update_Status
                  (p_api_version    => 2.0,
                  p_init_msg_list    => FND_API.G_TRUE,
                  p_commit        => FND_API.G_FALSE,
                  x_return_status    => x_return_status,
                  x_msg_count            => x_msg_count,
                  x_msg_data        => x_msg_data,
                  p_resp_appl_id    => ln_resp_appl_id,
                  p_resp_id        => ln_resp_id,
                  p_user_id        => ln_user_id,
                  p_login_id        => NULL,
                  p_request_id        => ln_incident_id,
                  p_request_number    => p_sr_number,
                  p_object_version_number => ln_obj_ver,
                  p_status_id         => ln_status_id,
                  p_status        => lc_sr_status,
                  p_closed_date        => SYSDATE,
                  p_audit_comments    => NULL,
                  p_called_by_workflow    => NULL,
                  p_workflow_process_id    => NULL,
                  p_comments        => lc_cancel_log,
                  p_public_comment_flag    => NULL,
                  x_interaction_id    => x_interaction_id);
                  
                  commit;
       ELSE -- Update partial request
           
            cs_servicerequest_pub.initialize_rec( lr_service_request_rec );    
             /*************************************************************************
               -- Add notes
              ************************************************************************/
          
                lt_notes_table(1).note        := 'Order updated from gMill' ;
                lt_notes_table(1).note_detail := p_cancel_log;
                lt_notes_table(1).note_type   := 'GENERAL';
            
            cs_servicerequest_pub.Update_ServiceRequest (
                      p_api_version            => 2.0,
                      p_init_msg_list          => FND_API.G_TRUE,
                      p_commit                 => FND_API.G_FALSE,
                      x_return_status          => x_return_status,
                      x_msg_count              => x_msg_count,
                      x_msg_data               => x_msg_data,
                      p_request_id             => ln_incident_id,
                      p_request_number         => p_sr_number,
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
      
    END IF; -- ln_incident_id
    
END Update_ServiceRequest;

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
ln_api_version              := 1.0;
lc_init_msg_list          := FND_API.g_true;
ln_validation_level          := FND_API.g_valid_level_full;
lc_commit              := FND_API.g_true;
ln_msg_count              := 0;
/****************************************************************************
-- If ObjectCode is Party then Object_id is party id
-- If ObjectCode is Service Request then Object_id is Service Request ID
-- If ObjectCode is TASK then Object_id is Task id
****************************************************************************/
ln_source_object_id          := p_request_id;
lc_source_object_code        := 'SR';
lc_note_status                := 'E';  -- (P-Private, E-Publish, I-Public)
lc_note_type                  := 'GENERAL';
lc_notes                      := p_sr_notes_rec.notes;
lc_notes_detail                := p_sr_notes_rec.note_details;

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
    ln_created_by        := FND_GLOBAL.USER_ID;
    ln_last_update_login    := FND_GLOBAL.LOGIN_ID;
  /******************************************************************************
  -- Call Create Note API
  *******************************************************************************/
  JTF_NOTES_PUB.create_note (p_api_version        => ln_api_version,
                    p_init_msg_list               => lc_init_msg_list,
                      p_commit                    => lc_commit,
                      p_validation_level          => ln_validation_level,
                      x_return_status             => lc_return_status,
                      x_msg_count                 => ln_msg_count ,
                      x_msg_data                  => lc_msg_data,
                      p_jtf_note_id              => ln_jtf_note_id,
                      p_entered_by                => ln_entered_by,
                      p_entered_date              => ld_entered_date,
                      p_source_object_id      => ln_source_object_id,
                      p_source_object_code      => lc_source_object_code,
                      p_notes              => lc_notes,
                      p_notes_detail          => lc_notes_detail,
                      p_note_type          => lc_note_type,
                      p_note_status          => lc_note_status,
                      p_jtf_note_contexts_tab     => lt_note_contexts,
                      x_jtf_note_id          => ln_jtf_note_id,
                      p_last_update_date      => ld_last_update_date,
                      p_last_updated_by              => ln_last_updated_by,
                      p_creation_date          => ld_creation_date,
                      p_created_by          => ln_created_by,
                      p_last_update_login      => ln_last_update_login );
  
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
/*------------------------------------------------------------------------
  Procedure Name : Make_Param_Str
  Description    : concatenates parameters for XML message
--------------------------------------------------------------------------*/

 FUNCTION Make_Param_Str(p_param_name IN VARCHAR2, 
                         p_param_value IN VARCHAR2) 
 RETURN VARCHAR2
 IS
 BEGIN
       RETURN '<'||p_param_name||
              '>'||p_param_value||'</'||p_param_name||'>';

 END Make_Param_Str;

/*******************************************************************************
*******************************************************************************/

PROCEDURE ENQUEUE_MESSAGE(P_REQUEST_ID  IN NUMBER,
                          P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                          P_RETURN_MSG  IN OUT NOCOPY VARCHAR2) AS


  enqueue_options     dbms_aq.enqueue_options_t;
  myParser            dbms_xmlparser.Parser;
  message_properties  dbms_aq.message_properties_t;
  message_handle      RAW(16);
 
  message             sys.XMLTYPE; 
  v_document          dbms_xmldom.DOMDocument;
  
  l_initStr           VARCHAR2(30000);
  l_sku_initStr       VARCHAR2(30000);
  lc_incident_number  VARCHAR2(25);
  lc_order_number     varchar2(100);
  ln_status_id        number;
  lc_status           varchar2(250);
  
  CURSOR get_sku_details (P_REQUEST_ID IN NUMBER) IS
  select item_number,
              quantity,
              attribute2 subscription_id
  from xx_cs_sr_items_link
  where service_request_id = p_request_id;

BEGIN
    
    BEGIN
       SELECT incident_number    ,incident_status_id,
              incident_attribute_1||incident_attribute_13 order_number
        INTO lc_incident_number, ln_status_id, lc_order_number
          FROM cs_incidents_all_b
            WHERE incident_id  = p_request_id;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    
    BEGIN
       select name
        into lc_status
        from cs_incident_statuses_tl
        where incident_status_id = ln_status_id;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    

    BEGIN
       l_initStr   := '<?xml version="1.0"  encoding="UTF-8" ?> <Root-Element xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://TargetNamespace.com/dequeueSrupdate2Aops">
                                     <ODTechService>';
       l_initStr  := l_initStr||Make_Param_Str
                                    ('request_number',lc_incident_number);
       l_initStr  := l_initStr||Make_Param_Str
                                  ('order_number',lc_order_number);
                                  
         l_initStr  := l_initStr||Make_Param_Str
                                  ('request_status',lc_status);
    
            
          FOR get_sku_details_rec IN get_sku_details (p_request_id)
          LOOP
            l_sku_initStr := l_sku_initStr||'<skus>';
             
              l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('sku',get_sku_details_rec.item_number);
              l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('sku_quantity',get_sku_details_rec.quantity); 
                                    
               l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('Sku_SubID',get_sku_details_rec.subscription_id); 
                                    
             l_sku_initStr := l_sku_initStr||'</skus>';
          END LOOP;
              
          l_initStr := l_initStr||l_sku_initStr;
              
          l_initStr := l_initStr||'</ODTechService></Root-Element>';
          
        --  dbms_output.put_line('str '||l_initStr);
          
          myParser := dbms_xmlparser.newParser; 
          dbms_xmlparser.parseBuffer(myParser, l_initStr); 
          v_document := dbms_xmlparser.getDocument(myParser); 
          message := DBMS_XMLDOM.GETXMLTYPE(v_document); 
         
            BEGIN
             dbms_aq.enqueue(queue_name => 'XX_CS_AOPS_QUEUE',
                        enqueue_options => enqueue_options,
                        message_properties => message_properties,
                        payload => message,
                        msgid => message_handle);
                        
                       
              P_RETURN_CODE := 'Y';
              P_RETURN_MSG  := 'SUCCESS - Message Created in AQ';
            EXCEPTION
              WHEN OTHERS THEN
                P_RETURN_CODE := 'E';
                P_RETURN_MSG  := 'Error while enqueue message. '||sqlerrm;

            END; 
        
      commit;
    END;
  END ENQUEUE_MESSAGE;
  
  /*******************************************************************************
*******************************************************************************/

PROCEDURE SUB_UPDATES(P_REQUEST_ID  IN NUMBER,
                      P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                      P_RETURN_MSG  IN OUT NOCOPY VARCHAR2) AS


  enqueue_options     dbms_aq.enqueue_options_t;
  myParser            dbms_xmlparser.Parser;
  message_properties  dbms_aq.message_properties_t;
  message_handle      RAW(16);
 
  message             sys.XMLTYPE; 
  v_document          dbms_xmldom.DOMDocument;
  
  l_initStr           VARCHAR2(30000);
  l_sku_initStr       VARCHAR2(30000);
  lc_incident_number  VARCHAR2(25);
  lc_order_number     varchar2(100);
  ln_status_id        number;
  lc_status           varchar2(250);
  
  CURSOR get_sku_details (P_REQUEST_ID IN NUMBER) IS
  select item_number,
              quantity,
              attribute2 subscription_id
  from xx_cs_sr_items_link
  where service_request_id = p_request_id;

BEGIN
    
    BEGIN
       SELECT incident_number    ,incident_status_id,
              incident_attribute_1||incident_attribute_13 order_number
        INTO lc_incident_number, ln_status_id, lc_order_number
          FROM cs_incidents_all_b
            WHERE incident_id  = p_request_id;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    
    /*BEGIN
       select name
        into lc_status
        from cs_incident_statuses_tl
        where incident_status_id = ln_status_id;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END; */
    
    LC_STATUS := 'Update';

    BEGIN
       l_initStr   := '<?xml version="1.0"  encoding="UTF-8" ?> <Root-Element xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://TargetNamespace.com/dequeueSrupdate2Aops">
                                     <ODTechService>';
       l_initStr  := l_initStr||Make_Param_Str
                                    ('request_number',lc_incident_number);
       l_initStr  := l_initStr||Make_Param_Str
                                  ('order_number',lc_order_number);
                                  
         l_initStr  := l_initStr||Make_Param_Str
                                  ('request_status',lc_status);
    
            
          FOR get_sku_details_rec IN get_sku_details (p_request_id)
          LOOP
            l_sku_initStr := l_sku_initStr||'<skus>';
             
              l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('sku',get_sku_details_rec.item_number);
              l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('sku_quantity',get_sku_details_rec.quantity); 
                                    
               l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('Sku_SubID',get_sku_details_rec.subscription_id); 
                                    
             l_sku_initStr := l_sku_initStr||'</skus>';
          END LOOP;
              
          l_initStr := l_initStr||l_sku_initStr;
              
          l_initStr := l_initStr||'</ODTechService></Root-Element>';
          
        --  dbms_output.put_line('str '||l_initStr);
          
          myParser := dbms_xmlparser.newParser; 
          dbms_xmlparser.parseBuffer(myParser, l_initStr); 
          v_document := dbms_xmlparser.getDocument(myParser); 
          message := DBMS_XMLDOM.GETXMLTYPE(v_document); 
         
            BEGIN
             dbms_aq.enqueue(queue_name => 'XX_CS_AOPS_QUEUE',
                        enqueue_options => enqueue_options,
                        message_properties => message_properties,
                        payload => message,
                        msgid => message_handle);
                        
                       
              P_RETURN_CODE := 'Y';
              P_RETURN_MSG  := 'SUCCESS - Message Created in AQ';
            EXCEPTION
              WHEN OTHERS THEN
                P_RETURN_CODE := 'E';
                P_RETURN_MSG  := 'Error while enqueue message. '||sqlerrm;

            END; 
        
      commit;
    END;
  END SUB_UPDATES;
/******************************************************************************************/
END XX_CS_TDS_SR_PKG;
/
show errors;
exit;