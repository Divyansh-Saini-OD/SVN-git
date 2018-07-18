CREATE OR REPLACE PACKAGE BODY XX_CS_SR_TASK AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_SR_TASK                                            |
-- |                                                                   |
-- | Description: Wrapper package for create/update service requests.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       21-Apr-10   Raj Jagarlamudi  Initial draft version       |
-- |2.0       09-Sep-2015 Arun G           Changes for Digital Locker SKUs|
-- |3.0       22-JAN-16   Vasu Raparla     Removed Schema References for  |
-- |                                       for R.12.2                  |
-- |3.0 	  31-May-2016 Anoop Salim	   Changes for QC# 37986       |
-- +===================================================================+
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
     ,p_program_name            => 'XX_CS_SR_TASK'
     ,p_program_id              => null
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
PROCEDURE CREATE_PROCEDURE(P_INCIDENT_ID IN NUMBER,
                           X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                           X_MSG_DATA IN OUT NOCOPY VARCHAR2)
IS

Ln_STATUS_ID        number;
LC_STATUS           varchar2(150);
LN_OBJ_VER          NUMBER;
LC_NOTES            varchar2(2000);
LC_TYPE_NAME        varchar2(250);
LN_OWNER_ID         number;
LN_GROUP_ID         number;
ln_task_id          number;
lc_error_id         varchar2(25);
ln_task_status_id   number;
ln_task_priority    number;
LC_MESSAGE          varchar2(2000);
lc_sku_category     varchar2(250);
lc_skus             varchar2(250);
l_user_id           number := 26176;
I                   number := 1;
ln_script_id        number;
lc_process_flag     varchar2(1) := 'N';
lc_exc_vendor_flag  varchar2(1) := 'N';
lc_task_type_name   varchar2(150);
ln_task_type_id     number;
lc_task_context     varchar2(150);
lc_quote_number     varchar2(50);
lc_quote_flag       varchar2(1) := 'N';
lc_quote_url        varchar2(150);
lc_quote_param      varchar2(150);
lc_auth_key         varchar2(100);
lc_store            varchar2(25);
lc_manuf            varchar2(200);
lc_model            varchar2(100);
lc_serial           varchar2(100);
lc_associate        varchar2(200);
lc_prob_descr       varchar2(250);
lc_request_number   varchar2(25);
l_resource_id       number;
l_conc_request_id   NUMBER;
lc_part_order_link  VARCHAR2(1000) := FND_PROFILE.VALUE('XX_CS_TDS_PARTS_LINK');
--Raj added for direct quotation
  x_msg_count           NUMBER;
  x_return_msg       VARCHAR2(1000);
  x_interaction_id   NUMBER;
  x_workflow_process_id NUMBER;
  ln_msg_index       number;
  ln_msg_index_out   number;
  lr_service_request_rec   CS_ServiceRequest_PUB.service_request_rec_type;
  lt_notes_table           CS_SERVICEREQUEST_PUB.notes_table;
  LT_CONTACTS_TAB          CS_SERVICEREQUEST_PUB.CONTACTS_TABLE;
  LC_ESD_SKU_COUNT  NUMBER;  -- Digital Locker
  L_ESD_FLAG varchar2(1) := 'Y';


cursor tds_task_cur (p_incident_id in number) is
select xt.item_number,
       xt.item_description,
       xt.quantity,
       ct.attribute7,
       tt.name,
       tt.task_type_id,
       ct.attribute6 ,
       ct.attribute12,
       ct.attribute13,
       xt.attribute4
from cs_incident_types_vl ct,
     jtf_task_types_vl tt,
     xx_cs_sr_items_link xt
where substr(xt.attribute5,1,1) = ct.attribute6
and   xt.service_request_id = p_incident_id
and  ct.name like 'TDS%'
and  ct.attribute8 = tt.name
and  xt.attribute4 like decode(ct.attribute6, 'A',xt.attribute4, 'S',xt.attribute4,'C',xt.attribute4, '%'||upper(ct.attribute7)||'%')
ORDER BY ct.attribute11;

BEGIN
    lc_message := 'in Task Procedure '||P_INCIDENT_Id;

    Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                             ,p_error_message_code =>   'XX_CS_SR01a_SUCCESS_LOG'
                             ,p_error_msg          =>  lc_message);
   BEGIN
      SELECT CB.INCIDENT_NUMBER,
            CL.NAME,CB.OWNER_GROUP_ID,
             CB.EXTERNAL_ATTRIBUTE_3,
             CB.EXTERNAL_ATTRIBUTE_1,
             CB.TIER,
             lpad(cb.incident_attribute_11, 5,0) store_no,
             cb.incident_attribute_12 manuf,
             cb.incident_attribute_6 model_no,
             cb.incident_attribute_10 serial,
             cb.external_attribute_10 prob_descr,
             nvl(cb.external_attribute_11,cb.incident_attribute_11) ass_name
        INTO  LC_REQUEST_NUMBER,
              LC_TYPE_NAME, LN_GROUP_ID,
              LC_SKU_CATEGORY, LC_SKUS,
              LN_SCRIPT_ID,
              lc_store,
              lc_manuf,
              lc_model,
              lc_serial,
              lc_prob_descr,
              lc_associate
      FROM  CS_INCIDENTS_ALL_B CB,
            CS_INCIDENT_TYPES_TL CL
      WHERE CL.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID
      AND   CB.INCIDENT_ID      = P_INCIDENT_ID;
   EXCEPTION
      WHEN OTHERS THEN
          X_RETURN_STATUS := 'F';
          X_MSG_DATA := SQLERRM;
   END;

   lc_message := 'Type  '||lc_type_name||' - '||lc_request_number;

    Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                             ,p_error_message_code =>   'XX_CS_SR01b_SUCCESS_LOG'
                             ,p_error_msg          =>  lc_message);

  IF lc_type_name like 'TDS%' then
     --DBMS_OUTPUT.PUT_LINE('CAT '|| lc_sku_category);
     IF lc_sku_category is null then
        lc_sku_category := 'M';
     end if;
     
     -- Check if the SR belongs to ESD or not ..

     BEGIN  
       SELECT COUNT(xftv.source_value1)
       INTO lc_esd_sku_count
       FROM xx_fin_translatedefinition xftd ,
            xx_fin_translatevalues xftv,
            xx_cs_sr_items_link xt
       WHERE xftd.translate_id   = xftv.translate_id
       AND xftd.translation_name = 'ESD_SKU_DETAILS'
       AND xftv.source_value1    = xt.item_number
       AND xt.service_request_id = p_incident_id
       AND SYSDATE BETWEEN xftv.start_date_active AND  NVL(xftv.end_date_active,SYSDATE+1)
       AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
       AND xftv.enabled_flag = 'Y'
       AND xftd.enabled_flag = 'Y';
     EXCEPTION
       WHEN OTHERS
       THEN
         x_msg_data := 'Error while checking if the SKU in the task is ESD SKU or not. '||x_msg_data;
         Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                        ,P_ERROR_MESSAGE_CODE =>   'XX_CS_SR011_ERR_LOG'
                        ,P_ERROR_MSG          =>  X_RETURN_STATUS||' '||X_MSG_DATA);
     END;
        
        /* Digital Locker Change */


     FOR tds_task_rec IN tds_task_cur(p_incident_id)
     LOOP
         lc_task_type_name := tds_task_rec.name;
         ln_task_type_id := tds_task_rec.task_type_id;
         lc_task_context  := 'Tech Depot Services';

         lc_message := 'Category   '||tds_task_rec.attribute6||' - '||lc_request_number;

        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                             ,p_error_message_code =>   'XX_CS_SR01b_SUCCESS_LOG'
                             ,p_error_msg          =>  lc_message);
     
         IF tds_task_rec.attribute6 in ('R','S','O','V') Then
             begin
                select 'Y'
                into  lc_exc_vendor_flag
                from  fnd_lookup_values
                where lookup_type = 'XX_TDS_EXC_VENDORS'
                and   tds_task_rec.attribute4 like '%'||meaning||'%';
             exception
                when others then
                   lc_exc_vendor_flag := 'N';
             end;
          else
              lc_exc_vendor_flag := 'N';
              IF tds_task_rec.attribute6 = 'A' AND nvl(lc_quote_flag,'N') = 'N' THEN -- -- Raj on 3/15

                BEGIN
                 select 'Y'
                  into lc_quote_flag
                  from cs_lookups
                  where lookup_type = 'XX_TDS_PARTS_ITEM'
                  and lookup_code = tds_task_rec.item_number;
                EXCEPTION
                  WHEN OTHERS THEN
                    lc_quote_flag := 'N';
                END;


              END IF;  -- In Store Install
          end if;  -- Category

        IF I = 1 THEN
          IF lc_exc_vendor_flag = 'Y' then
            LN_TASK_STATUS_ID := 11;
            LN_TASK_PRIORITY := 3;
            I := 0;
          else
           IF tds_task_rec.attribute6 = 'A' THEN
             LN_TASK_STATUS_ID := 15; -- In Progress
           ELSE
             LN_TASK_STATUS_ID := 14; -- Assigned
           END IF;
           LN_TASK_PRIORITY  :=  2;
           LC_PROCESS_FLAG   := 'Y';
          end if;
        ELSE
          -- Clsoe MCAFEE task
          IF lc_exc_vendor_flag = 'Y' then
             LN_TASK_STATUS_ID := 11;
          ELSE
             LN_TASK_STATUS_ID := 12;  -- Not Started
          END IF;
            LN_TASK_PRIORITY := 3;
        END IF;

        LOG_EXCEPTION ( P_ERROR_LOCATION     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,P_ERROR_MSG          =>  'ESD SKU COUNT : ' ||LC_ESD_SKU_COUNT); 
   /* Digital Locker Change */                    
        IF lc_esd_sku_count > 0 
        THEN 
          IF tds_task_rec.attribute6 = 'C'
          THEN
            LN_TASK_STATUS_ID := 12; -- Not started , 11001 is New
          ELSIF tds_task_rec.attribute6 = 'R' AND l_esd_flag = 'Y'
          THEN
            ln_task_status_id := 14; -- Assigned status for support.com task
            l_esd_flag:='N';
         END IF;
       END IF;  -- END SKU count if
         
       LC_NOTES    := 'Service created for '||' '||tds_task_rec.attribute7 ||' for '||tds_task_rec.item_description;
       LC_MESSAGE  := LC_NOTES;

       Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_message);
       BEGIN
            CREATE_NEW_TASK
                  ( p_task_name          => tds_task_rec.item_description||'-'||tds_task_rec.item_number
                  , p_task_type_id       => ln_task_type_id
                  , p_status_id          => ln_task_status_id
                  , p_priority_id        => ln_task_priority
                  , p_Planned_Start_date => sysdate
                  , p_planned_effort     => null
                  , p_planned_effort_uom => null
                  , p_notes              => lc_notes
                  , p_source_object_id   => p_incident_id
                  , x_error_id           => lc_error_id
                  , x_error              => x_return_msg
                  , x_new_task_id        => ln_task_id
                  , p_note_type          => null
                  , p_note_status        => null
                  , p_Planned_End_date   => null
                  , p_owner_id           => ln_group_id
                  , p_attribute_1           => tds_task_rec.attribute7
                  , p_attribute_2           => lc_process_flag
                  , p_attribute_3           => null
                  , p_attribute_4           => null
                  , p_attribute_5           => tds_task_rec.attribute6
                  , p_attribute_6           => tds_task_rec.item_number
                  , p_attribute_7            => tds_task_rec.item_description
                  , p_attribute_8            => tds_task_rec.quantity
                  , p_attribute_9            => null
                  , p_attribute_10          => null
                  , p_attribute_11          => null
                  , p_attribute_12          => null
                  , p_attribute_13          => null
                  , p_attribute_14          => null
                  , p_attribute_15          => null
                  , p_context                  => lc_task_context
                  , p_assignee_id         => l_user_id
                  , p_template_id         => NULL
                );

                I := I + 1;
          EXCEPTION
            WHEN OTHERS THEN
              lc_message := 'Error while calling new task '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  lc_message);
          END;
     END LOOP;
  END IF;

       IF lc_type_name like 'TDS-Central Repair' then
            lc_status := 'Waiting for Box';
       elsif lc_type_name like 'TDS-In Home' then
            lc_status := 'Pending Apt.Setup';
       elsif lc_type_name like 'TDS-In Home/Office' then
            lc_status := 'Pending Apt.Setup';
       elsif lc_type_name like 'TDS-On Site Service' then
            lc_status := 'Service Not Started';
        elsif lc_type_name like 'TDS-Remote Service' then
            lc_status := 'Awaiting Service';
       end if;

       BEGIN
          SELECT incident_status_id,
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = lc_status;
        EXCEPTION
            WHEN OTHERS THEN
              LC_STATUS := 'Awaiting Service';
        END;

  -- update SR status
    BEGIN
        XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => p_incident_id,
                                  p_user_id        => fnd_global.user_id,
                                  p_status_id      => ln_status_id,
                                  p_status         => lc_status,
                                  x_return_status  => x_return_status,
                                  x_msg_data      => lc_message);

      EXCEPTION
            WHEN OTHERS THEN
              lc_message := 'Error while updating SR status '||sqlerrm;
              Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  lc_message);
      END;

    IF nvl(lc_quote_flag, 'N') = 'Y' then
      --verify the store
    -- Raj added on 2/15 for direct quotation
      begin
          select quote_number
          into lc_quote_number
          from xx_cs_tds_parts
          where request_number = lc_request_number
          and rownum < 2;
      exception
         when others then
            lc_quote_number := null;
      end;

      BEGIN
        SELECT OBJECT_VERSION_NUMBER
        INTO LN_OBJ_VER
        FROM CS_INCIDENTS_ALL_B
        WHERE INCIDENT_ID = P_INCIDENT_ID;
      EXCEPTION
         WHEN OTHERS THEN
           NULL;
      END;

      IF LC_QUOTE_NUMBER IS NOT NULL THEN

      -- Enable Parts button.
    /*   BEGIN
          UPDATE CS_INCIDENTS_ALL_B
          SET EXTERNAL_ATTRIBUTE_6 = lc_part_order_link||lc_request_number
          WHERE INCIDENT_NUMBER = LC_REQUEST_NUMBER;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
             lc_message   := 'eRROR while updating request with link ' || lc_request_number;
               Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                            ,p_error_message_code =>   'XX_CS_SR01a_ERR_LOG'
                            ,p_error_msg          =>  lc_message);
         END; */

        BEGIN
          SELECT incident_status_id
          INTO  ln_status_id
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = 'Approved' ;
        EXCEPTION
          WHEN OTHERS THEN
            null;
        END;

        cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
        lr_service_request_rec.external_attribute_6 := lc_part_order_link||lc_request_number;
        lr_service_request_rec.summary := 'Purchase Order Processed....';
        lr_service_request_rec.status_id   := ln_status_id;

        /*************************************************************************
           -- Add notes
          ************************************************************************/
            lt_notes_table(1).note        := 'Purchase Order Processed....' ;
            lt_notes_table(1).note_detail := 'Purchase Order Processed....';
            lt_notes_table(1).note_type   := 'GENERAL';

      -- Create PO and sends to vendor
      /*   l_conc_request_id :=   fnd_request.submit_request ('CS',
                                            'XX_TDS_PARTS_ITEMS',
                                            'OD CS TDS Parts Items',
                                            NULL,
                                            FALSE,
                                            lc_request_number
                                            );

         IF l_conc_request_id <= 0  THEN
                   lc_message := ' Error while submit the Conc Request for PO'||LC_REQUEST_NUMBER;
                   Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_0002a_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                );
          ELSE
              BEGIN
                update cs_incidents
                set summary = 'Purchase Order Processed..'
                where incident_id = p_incident_id;
              EXCEPTION
                    WHEN OTHERS THEN
                      lc_message := 'Error while updating summary '||sqlerrm;
                      Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                         ,p_error_message_code =>   'XX_CS_SR02c_ERR_LOG'
                                         ,p_error_msg          =>  lc_message);
            END;

          END IF;  */

      ELSE
        begin
          select FND_PROFILE.VALUE('XX_CS_TDS_PARTS_QUOTE_LINK')
          into lc_quote_url
          from dual;
        exception
          when others then
            lc_message := 'Error while updating quotation link '||sqlerrm;
            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                            ,p_error_message_code =>   'XX_CS_SR02a_ERR_LOG'
                            ,p_error_msg          =>  lc_message);
        end;

        begin
          select FND_PROFILE.VALUE('XX_CS_TDS_AUTH_ID')
          into lc_auth_key
          from dual;
        exception
          when others then
            lc_message := 'Error while updating auth key '||sqlerrm;
            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                            ,p_error_message_code =>   'XX_CS_SR02b_ERR_LOG'
                            ,p_error_msg          =>  lc_message);
        end;

        -- enabled quote flag
        lc_quote_url := lc_quote_url||'SRNUMBER='||lc_request_number||'&STORENUMBER='||lc_store||'&ASSOCIATE='||lc_associate;
        lc_quote_param := '&AUTHKEY='||lc_auth_key||'&ODMANUFACTURER='||lc_manuf||'&ODMODEL='||lc_model||'&ODSERIAL='||lc_serial;

        cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
        lr_service_request_rec.external_attribute_13 := lc_quote_url;
        lr_service_request_rec.external_attribute_2 := lc_quote_param;
        lr_service_request_rec.summary := 'Place Parts';

         /*************************************************************************
           -- Add notes
          ************************************************************************/
            lt_notes_table(1).note        := 'Purchase Order Processed....' ;
            lt_notes_table(1).note_detail := 'Purchase Order Processed....';
            lt_notes_table(1).note_type   := 'GENERAL';
      /*
        BEGIN
            update cs_incidents_all_b
            set external_attribute_13 = lc_quote_url,
                external_attribute_2 = lc_quote_param
            where incident_id = p_incident_id;
          EXCEPTION
                WHEN OTHERS THEN
                  lc_message := 'Error while updating quotation link '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR02c_ERR_LOG'
                                     ,p_error_msg          =>  lc_message);
        END;

        BEGIN
            update cs_incidents
            set summary = 'Place Parts'
            where incident_id = p_incident_id;
          EXCEPTION
                WHEN OTHERS THEN
                  lc_message := 'Error while updating summary '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR02b_ERR_LOG'
                                     ,p_error_msg          =>  lc_message);
        END; */

     END IF; -- QUOTE_NUMBER

     /*******************************************************************************************
       -- Update Parts order
    *********************************************************************************************/

         cs_servicerequest_pub.Update_ServiceRequest (
            p_api_version            => 2.0,
            p_init_msg_list          => FND_API.G_TRUE,
            p_commit                 => FND_API.G_FALSE,
            x_return_status          => x_return_status,
            x_msg_count              => x_msg_count,
            x_msg_data               => x_return_msg,
            p_request_id             => p_incident_id,
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

            lc_message := 'Update SR#'||lc_request_number||' - '||x_return_msg;
            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR03_LOG'
                                     ,p_error_msg          =>  lc_message);
        END IF;

    END IF;  -- PARTS FLAG

END;

/************************************************************************************/
  PROCEDURE CREATE_NEW_TASK
  ( p_task_name          IN  VARCHAR2
  , p_task_type_id       IN  NUMBER
  , p_status_id          IN  NUMBER
  , p_priority_id        IN  NUMBER
  , p_Planned_Start_date IN  DATE
  , p_planned_effort     IN  NUMBER
  , p_planned_effort_uom IN VARCHAR2
  , p_notes              IN VARCHAR2
  , p_source_object_id   IN NUMBER
  , x_error_id           OUT NOCOPY NUMBER
  , x_error              OUT NOCOPY VARCHAR2
  , x_new_task_id        OUT NOCOPY NUMBER
  , p_note_type          IN  VARCHAR2
  , p_note_status        IN VARCHAR2
  , p_Planned_End_date   IN  DATE
  , p_owner_id           IN NUMBER
  , p_attribute_1     IN VARCHAR2
  , p_attribute_2     IN VARCHAR2
  , p_attribute_3     IN VARCHAR2
  , p_attribute_4     IN VARCHAR2
  , p_attribute_5     IN VARCHAR2
  , p_attribute_6     IN VARCHAR2
  , p_attribute_7     IN VARCHAR2
  , p_attribute_8     IN VARCHAR2
  , p_attribute_9     IN VARCHAR2
  , p_attribute_10     IN VARCHAR2
  , p_attribute_11     IN VARCHAR2
  , p_attribute_12     IN VARCHAR2
  , p_attribute_13     IN VARCHAR2
  , p_attribute_14     IN VARCHAR2
  , p_attribute_15     IN VARCHAR2
  , p_context         IN VARCHAR2
  , p_assignee_id        IN NUMBER
  , p_template_id        IN NUMBER
) IS

l_task_type_name      varchar2(250);
l_return_status       varchar2(1);
l_msg_count           number;
l_msg_data            varchar2(2000);

l_data                varchar2(200);
l_task_notes_rec      jtf_tasks_pub.task_notes_rec;
l_task_notes_tbl      jtf_tasks_pub.task_notes_tbl;
l_msg_index_out       number;

l_resource_id         number;
l_resource_type       varchar2(30);
l_assign_by_id        number;
l_scheduled_start_date DATE;
l_scheduled_end_date   DATE;
l_incident_number     VARCHAR2(64);
l_organization_id     NUMBER;
l_note_type           varchar2(30);
l_note_status         varchar2(1);
l_user_id             number;
ln_resp_appl_id       number := 514;
ln_resp_id            number := 21739;
l_task_descr          varchar2(250);
ln_script_id          number;
I                     number;

CURSOR c_task_type (v_task_type_id NUMBER)
IS
Select name
  from jtf_task_types_vl
 where TASK_TYPE_ID = v_task_type_id;

CURSOR c_resource_type (p_owner_id NUMBER)
IS
select resource_type
  from jtf_rs_resources_vl
 where resource_id = p_owner_id
 and end_date_active is null;

CURSOR c_incident_number (v_incident_id NUMBER)
IS
Select incident_number,tier,
       INSTALL_SITE_ID
  from cs_incidents_all
 where incident_id = v_incident_id ;

 r_incident_record c_incident_number%ROWTYPE;

CURSOR QA_CUR (v_script_id NUMBER)
IS
select qp.question_label qus,
       qd.freeform_string ans
from   ies_question_data qd,
       ies_questions qp,
       ies_panels ip
where  ip.panel_id = qp.panel_id
and    qp.question_id = qd.question_id
and    ip.panel_label = p_attribute_6
and    qd.transaction_id = v_script_id;

QA_REC  QA_CUR%ROWTYPE;

BEGIN

-- get the task type name
open c_task_type(p_task_type_id);
fetch c_task_type into l_task_type_name;
close c_task_type;

    begin
      select user_id
      into l_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    end;

-- SR number
open c_incident_number (p_source_object_id);
fetch c_incident_number into r_incident_record;
close c_incident_number;
l_incident_number := r_incident_record.incident_number;
ln_script_id      := r_incident_record.tier;

--notes
    If p_notes <> '$$#@'
    then
        If p_note_type is null then
           l_note_type := 'GENERAL';
        else
           l_note_type := p_note_type;
        end if;

        If p_note_status is null then
           l_note_status := 'I';
        else
           l_note_status := p_note_status;
        end if;

      l_task_notes_rec.notes          := p_notes;
      l_task_notes_rec.note_status      := l_note_status;
      l_task_notes_rec.entered_by      := FND_GLOBAL.user_id;
      l_task_notes_rec.entered_date      := sysdate;
      l_task_notes_rec.note_type          := l_note_type;
      I                                   := 1;
      l_task_notes_tbl (I)                := l_task_notes_rec;
      l_task_descr                        := substr(p_notes,1,250);

      -- add QA
      BEGIN
        OPEN QA_CUR (ln_script_id);
        LOOP
        fetch qa_cur into qa_rec;
        exit when qa_cur%notfound;
        I := I + 1;

          l_task_notes_rec.notes      := qa_rec.qus||': '||qa_rec.ans;
          l_task_notes_rec.note_status      := l_note_status;
          l_task_notes_rec.entered_by      := FND_GLOBAL.user_id;
          l_task_notes_rec.entered_date      := sysdate;
          l_task_notes_rec.note_type      := l_note_type;
          l_task_notes_tbl (I)            := l_task_notes_rec;

        end loop;
        close qa_cur;
      exception
        when others then
            l_msg_data := 'error while generating notes '||sqlerrm;
            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_msg_data);
      END;
      -- add Questions
    else
      l_task_notes_tbl := jtf_tasks_pub.g_miss_task_notes_tbl;
    end if;

    l_assign_by_id := p_assignee_id;

-- resource type
open c_resource_type (p_owner_id);
fetch c_resource_type into l_resource_type;
close c_resource_type;


      FND_GLOBAL.APPS_INITIALIZE(L_USER_ID,ln_resp_id,ln_resp_appl_id);

        -- Lets call the API
      jtf_tasks_pub.create_task (
          p_api_version             => 1.0,
          p_commit                  => fnd_api.g_true,
          p_task_name               => p_task_name,
          p_task_type_name          => l_task_type_name,
          p_task_type_id            => p_task_type_id,
          p_description             => l_task_descr,
          p_task_status_name        => null,
          p_task_status_id          => p_status_id,
          p_task_priority_name      => null,
          p_task_priority_id        => p_priority_id,
          p_owner_type_name         => Null,
          p_owner_type_code         => l_resource_type,
          p_owner_id                => p_owner_id,
          p_owner_territory_id      => null,
          p_assigned_by_name        => NULL,
          p_assigned_by_id          => l_assign_by_id,
          p_customer_number         => null,
          p_customer_id             => null,
          p_cust_account_number     => null,
          p_cust_account_id         => null,
          p_address_id              => r_incident_record.INSTALL_SITE_ID,
          p_planned_start_date      => p_Planned_Start_date,
          p_planned_end_date        => p_Planned_End_date,
          p_scheduled_start_date    => l_scheduled_start_date,
          p_scheduled_end_date      => l_scheduled_end_date,
          p_actual_start_date       => NULL,
          p_actual_end_date         => NULL,
          p_timezone_id             => NULL,
          p_timezone_name           => NULL,
          p_source_object_type_code => 'SR',
          p_source_object_id        => p_source_object_id,
          p_source_object_name      => l_incident_number,
          p_duration                => null,
          p_duration_uom            => null,
          p_planned_effort          => p_planned_effort,
          p_planned_effort_uom      => p_planned_effort_uom,
          p_actual_effort           => NULL,
          p_actual_effort_uom       => NULL,
          p_percentage_complete     => null,
          p_reason_code             => null,
          p_private_flag            => null,
          p_publish_flag            => null,
          p_restrict_closure_flag   => NULL,
          p_multi_booked_flag       => NULL,
          p_milestone_flag          => NULL,
          p_holiday_flag            => NULL,
          p_billable_flag           => NULL,
          p_bound_mode_code         => null,
          p_soft_bound_flag         => null,
          p_workflow_process_id     => NULL,
          p_notification_flag       => NULL,
          p_notification_period     => NULL,
          p_notification_period_uom => NULL,
          p_parent_task_number      => null,
          p_parent_task_id          => NULL,
          p_alarm_start             => NULL,
          p_alarm_start_uom         => NULL,
          p_alarm_on                => NULL,
          p_alarm_count             => NULL,
          p_alarm_interval          => NULL,
          p_alarm_interval_uom      => NULL,
          p_palm_flag               => NULL,
          p_wince_flag              => NULL,
          p_laptop_flag             => NULL,
          p_device1_flag            => NULL,
          p_device2_flag            => NULL,
          p_device3_flag            => NULL,
          p_costs                   => NULL,
          p_currency_code           => NULL,
          p_escalation_level        => NULL,
          p_task_notes_tbl          => l_task_notes_tbl,
          x_return_status           => l_return_status,
          x_msg_count               => l_msg_count,
          x_msg_data                => l_msg_data,
          x_task_id                 => x_new_task_id,
          p_attribute1              => p_attribute_1,
          p_attribute2              => p_attribute_2,
          p_attribute3              => p_attribute_3,
          p_attribute4              => p_attribute_4,
          p_attribute5              => p_attribute_5,
          p_attribute6              => p_attribute_6,
          p_attribute7              => p_attribute_7,
          p_attribute8              => p_attribute_8,
          p_attribute9              => p_attribute_9,
          p_attribute10             => p_attribute_10,
          p_attribute11             => p_attribute_11,
          p_attribute12             => p_attribute_12,
          p_attribute13             => p_attribute_13,
          p_attribute14             => p_attribute_14,
          p_attribute15             => p_attribute_15,
          p_attribute_category      => p_context,
          p_date_selected           => NULL,
          p_category_id             => null,
          p_show_on_calendar        => null,
          p_owner_status_id         => null,
          p_template_id             => p_template_id,
          p_template_group_id       => null);

      commit;

IF l_return_status = FND_API.G_RET_STS_SUCCESS
THEN
    /* API-call was successfull */
    x_error_id := 0;
    x_error := FND_API.G_RET_STS_SUCCESS;
ELSE
    FOR l_counter IN 1 .. l_msg_count
    LOOP
          fnd_msg_pub.get
        ( p_msg_index     => l_counter
        , p_encoded       => FND_API.G_FALSE
        , p_data          => l_msg_data
        , p_msg_index_out => l_msg_index_out
        );
         -- dbms_output.put_line( 'Message: '||l_data );
    END LOOP ;
    x_error_id := 2;
    x_error := l_msg_data;
    x_new_task_id := 0; -- no tasks

        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_msg_data);
END IF;
      l_data := 'Task created '||x_new_task_id;
              Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_data);

EXCEPTION
  WHEN OTHERS
  THEN
    x_error_id := 1;
    x_error := SQLERRM;

            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.CREATE_NEW_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  X_ERROR);
END Create_New_Task;
/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_task_id               in number,
                       p_task_notes_rec       in jtf_tasks_pub.task_notes_rec,
                       p_notes_status         in varchar2,
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
lc_notes        varchar2(4000);
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
ln_source_object_id          := p_task_id;
lc_source_object_code        := 'TASK';
lc_note_status                := p_notes_status;  -- (P-Private, E-Publish, I-Public)
lc_note_type                  := 'GENERAL';
lc_notes                      := p_task_notes_rec.notes;
lc_notes_detail                := p_task_notes_rec.notes_detail;
ln_entered_by                  := FND_GLOBAL.user_id;
ld_entered_date                := SYSDATE;
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
  -- Update TDS Task
*******************************************************************************/
PROCEDURE Update_TDS_Task ( P_REQUEST_ID    IN  NUMBER,
                            P_TASK_ID       IN  NUMBER,
                            P_STATUS        IN  NUMBER,
                            P_VENDOR        IN  VARCHAR2,
                            P_NOTES_TBL     IN  jtf_tasks_pub.task_notes_tbl,
                            X_RETURN_STATUS OUT NOCOPY VARCHAR2,
                            X_MSG_DATA      OUT NOCOPY VARCHAR2) AS

ln_task_id          number;
ln_task_number      number;
lc_success          varchar2(50);
ln_msg_count        number;
lc_msg_data         varchar2(50);
ln_task_status_id   number;
ln_obj_ver          number;
lc_response         varchar2(25);
lr_task_notes       jtf_tasks_pub.task_notes_rec; --XX_CS_SR_NOTES_REC;
lc_note_status      varchar2(1);
i                   number;
lc_att_category     varchar2(250);
lc_link             varchar2(250);
lc_url              varchar2(500);
lc_sr_status        varchar2(200);
ln_status_id        number;
lc_reject_flag      varchar2(1) := 'N';
lc_task_proc_flag   varchar2(1) := 'N';
lc_incomplete_flag  varchar2(1) := 'N';

CURSOR VEN_CUR_C IS
SELECT TASK_ID,
      OBJECT_VERSION_NUMBER,
      TASK_STATUS_ID,
      ATTRIBUTE5
FROM  JTF_TASKS_VL
WHERE SOURCE_OBJECT_ID = P_REQUEST_ID
AND   SOURCE_OBJECT_TYPE_CODE = 'SR'
--AND   TASK_STATUS_ID = 8 -- Complete
AND   ATTRIBUTE1 = P_VENDOR;

VEN_REC_C VEN_CUR_C%ROWTYPE;

BEGIN

    IF P_VENDOR IS NULL THEN

        IF P_TASK_ID IS NOT NULL THEN

         BEGIN
          SELECT OBJECT_VERSION_NUMBER
              INTO  LN_OBJ_VER
              FROM JTF_TASKS_VL
              WHERE TASK_ID = P_TASK_ID;
          END;

          IF P_STATUS = 4 THEN
            LC_REJECT_FLAG := 'Y';
          END IF;

          begin
           jtf_tasks_pub.update_task
            ( p_object_version_number => ln_obj_ver
              ,p_api_version          => 1.0
              ,p_init_msg_list        => fnd_api.g_true
              ,p_commit               => fnd_api.g_false
              ,p_task_id              => p_task_id
              ,x_return_status        => x_return_status
              ,x_msg_count            => ln_msg_count
              ,x_msg_data             => x_msg_data
              ,p_task_status_id       => p_status
              ,p_attribute2           => 'N'
              ,p_attribute3           => lc_reject_flag
              );

            commit;
          exception
           when others then
             x_msg_data := 'Error while sending Updatable task '||x_msg_data;
             Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                             ,p_error_message_code =>   'XX_CS_SR011_ERR_LOG'
                             ,p_error_msg          =>  x_return_status||' '||x_msg_data);
          end;

         /******************************************************************
                -- UPDATE TASK NOTES
            *******************************************************************/
            IF nvl(x_return_status,'S') = 'S' then
             I := p_notes_tbl.first;
             IF I IS NOT NULL THEN
               loop
                     --lr_task_notes := jtf_tasks_pub.task_notes_rec();
                     lr_task_notes.notes          := p_notes_tbl(i).notes;
                     lr_task_notes.notes_detail   := p_notes_tbl(i).notes_detail;
                     lc_note_status               := p_notes_tbl(i).note_status;
                     lr_task_notes.entered_by     := uid;
                     lr_task_notes.entered_date  := sysdate;

                     IF lr_task_notes.notes is not null then

                         CREATE_NOTE(p_task_id          => p_task_id,
                                    p_task_notes_rec    => lr_task_notes,
                                    p_notes_status      => lc_note_status,
                                    p_return_status     => x_return_status,
                                    p_msg_data          => x_msg_data);
                    end if;
                EXIT WHEN I = p_notes_tbl.last;
                I := p_notes_tbl.NEXT(I);

               end loop;
             end if;
             commit;
            end IF;
            -- end if update notes
         END IF; --task

    ELSE  -- Vendor tasks
            /**************************************************************
             Verify vendor remaining tasks
            ***************************************************************/
            BEGIN
              OPEN VEN_CUR_C;
              LOOP
              FETCH VEN_CUR_C INTO VEN_REC_C;
              EXIT WHEN VEN_CUR_C%NOTFOUND;

              LN_TASK_ID        := VEN_REC_C.TASK_ID;
              LN_OBJ_VER        := VEN_REC_C.OBJECT_VERSION_NUMBER;
              LC_ATT_CATEGORY   := VEN_REC_C.ATTRIBUTE5;

              IF VEN_REC_C.TASK_STATUS_ID IN (8,4) THEN

                IF VEN_REC_C.TASK_STATUS_ID = 8 THEN
                  LN_TASK_STATUS_ID := 11; -- CLOSED
                  lc_task_proc_flag := 'Y';
                ELSE
                  LN_TASK_STATUS_ID := 7; -- CANCELLED
                  lc_incomplete_flag := 'Y';
                END IF;

                 begin
                   jtf_tasks_pub.update_task
                    ( p_object_version_number => ln_obj_ver
                      ,p_api_version          => 1.0
                      ,p_init_msg_list        => fnd_api.g_true
                      ,p_commit               => fnd_api.g_false
                      ,p_task_id              => ln_task_id
                      ,x_return_status        => x_return_status
                      ,x_msg_count            => ln_msg_count
                      ,x_msg_data             => x_msg_data
                      ,p_task_status_id       => ln_task_status_id
                      ,p_attribute2           => 'N'
                      );

                    commit;
                  exception
                   when others then
                     Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                     ,p_error_msg          =>  x_return_status||' '||x_msg_data);
                  end;

                END IF; -- Task status id

              END LOOP;
              CLOSE VEN_CUR_C;
            END;
            /**************************************************************
             Release pending tasks
            ***************************************************************/
			--
			-- Start of changes for QC# 37986
			--
            BEGIN
				SELECT 	TASK_ID, 
						TASK_STATUS_ID,
						OBJECT_VERSION_NUMBER,
						ATTRIBUTE5
				INTO 	LN_TASK_ID, 
						LN_TASK_STATUS_ID,
						LN_OBJ_VER ,
						LC_ATT_CATEGORY
				FROM 	JTF_TASKS_VL
				WHERE 	SOURCE_OBJECT_ID 		= P_REQUEST_ID
				AND   	SOURCE_OBJECT_TYPE_CODE = 'SR'
				AND   	TASK_STATUS_ID 			= 12 -- not started
				AND   	UPPER(ATTRIBUTE1) 		= 'IMAGE MICRO'
				AND 	TASK_ID = (	SELECT 	MIN(TASK_ID)
									FROM 	JTF_TASKS_VL A
									WHERE 	SOURCE_OBJECT_ID 	= P_REQUEST_ID
									AND 	UPPER(ATTRIBUTE1) 	= 'IMAGE MICRO');
            EXCEPTION
            WHEN OTHERS THEN
                LN_TASK_ID := NULL;
            END;
			--
			IF LN_TASK_ID IS NOT NULL 
			THEN
				--
				LN_TASK_STATUS_ID := 14; -- Assigned
				--
                BEGIN
					jtf_tasks_pub.update_task
						( 
						 p_object_version_number => ln_obj_ver
						,p_api_version          => 1.0
						,p_init_msg_list        => fnd_api.g_true
						,p_commit               => fnd_api.g_false
						,p_task_id              => ln_task_id
						,x_return_status        => x_return_status
						,x_msg_count            => ln_msg_count
						,x_msg_data             => x_msg_data
						,p_task_status_id       => ln_task_status_id
						,p_attribute2           => 'Y'
						);
					--
                    COMMIT;
                EXCEPTION
                WHEN OTHERS THEN
                     Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                     ,p_error_msg          =>  x_return_status||' Image Micro task status update failed: '||x_msg_data);
                END;

				-- Update SR status
				IF LC_ATT_CATEGORY = 'A' THEN
					LC_SR_STATUS := 'Pending In Store';
				ELSE
					LC_SR_STATUS := 'Awaiting Service';
				END IF;
			ELSE	
			--End of changes for QC# 37986			
            BEGIN
              SELECT TASK_ID, TASK_STATUS_ID,
                     OBJECT_VERSION_NUMBER,
                     ATTRIBUTE5
              INTO LN_TASK_ID, LN_TASK_STATUS_ID,
                   LN_OBJ_VER ,LC_ATT_CATEGORY
              FROM JTF_TASKS_VL
              WHERE SOURCE_OBJECT_ID = P_REQUEST_ID
              AND   SOURCE_OBJECT_TYPE_CODE = 'SR'
              AND   TASK_STATUS_ID = 12 -- not started
					  -- Start of changes for QC# 37986
					  --AND   ATTRIBUTE1 <> P_VENDOR
					AND   UPPER(ATTRIBUTE1) NOT IN( UPPER(P_VENDOR),'IMAGE MICRO')
					  -- End of changes for QC# 37986
              AND   ROWNUM < 2
              ORDER BY TASK_ID;
            EXCEPTION
              WHEN OTHERS THEN
                LN_TASK_ID := NULL;
            END;

           IF LN_TASK_ID IS NOT NULL THEN
              LN_TASK_STATUS_ID := 14; -- Assigned
                 begin
                   jtf_tasks_pub.update_task
                    ( p_object_version_number => ln_obj_ver
                      ,p_api_version          => 1.0
                      ,p_init_msg_list        => fnd_api.g_true
                      ,p_commit               => fnd_api.g_false
                      ,p_task_id              => ln_task_id
                      ,x_return_status        => x_return_status
                      ,x_msg_count            => ln_msg_count
                      ,x_msg_data             => x_msg_data
                      ,p_task_status_id       => ln_task_status_id
                      ,p_attribute2           => 'Y'
                      );

                    commit;
                  exception
                   when others then
                     Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                     ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                     ,p_error_msg          =>  x_return_status||' '||x_msg_data);
                  end;

               -- Update SR status
              IF LC_ATT_CATEGORY = 'A' THEN
                 LC_SR_STATUS := 'Pending In Store';
              ELSE
                 LC_SR_STATUS := 'Awaiting Service';
              END IF;
            /**************************************************************
              -- No more pending services, update SR to Call Customer
            ***************************************************************/
           ELSE -- No more pending tasks
              -- Get SR status id
              BEGIN
                SELECT ATTRIBUTE5
                INTO  LC_ATT_CATEGORY
                FROM JTF_TASKS_VL
                WHERE SOURCE_OBJECT_ID = P_REQUEST_ID
                AND   SOURCE_OBJECT_TYPE_CODE = 'SR'
                AND   ATTRIBUTE1 = P_VENDOR
                AND   ROWNUM < 2
                ORDER BY LAST_UPDATE_DATE DESC;
              EXCEPTION
                WHEN OTHERS THEN
                  LC_ATT_CATEGORY := NULL;
              END;

             IF LC_ATT_CATEGORY in ('O','H') THEN
               IF LN_TASK_STATUS_ID = 7 THEN
                LC_SR_STATUS := 'Cancelled';
               ELSE
                LC_SR_STATUS := 'Closed';
               END IF;
              ELSE
                  LC_SR_STATUS  := 'Call Customer';
              END IF;
            END IF; --task id is not null
			--
			-- Start of changes for QC# 37986
			END IF; -- Ending the check for tasks for vendor Image Micro(task id is not null)
			-- End of changes for QC# 37986
                BEGIN
                    SELECT NAME, INCIDENT_STATUS_ID
                    INTO LC_SR_STATUS, LN_STATUS_ID
                    FROM CS_INCIDENT_STATUSES_VL
                    WHERE INCIDENT_SUBTYPE = 'INC'
                    AND NAME  = LC_SR_STATUS;
                  EXCEPTION
                    WHEN OTHERS THEN
                         LN_STATUS_ID := NULL;
                         X_MSG_DATA := 'error while SELECTING status id for '||LC_SR_STATUS;
                            Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                            ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                             ,p_error_msg          =>  x_msg_data);
                  END;

             IF LN_STATUS_ID IS NOT NULL THEN
                BEGIN
                    XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => p_request_id,
                                            p_user_id        => fnd_global.user_id,
                                            p_status_id      => ln_status_id,
                                            p_status         => lc_sr_status,
                                            x_return_status  => x_return_status,
                                            x_msg_data      => x_msg_data);

                          commit;
                 EXCEPTION
                      WHEN OTHERS THEN
                        x_msg_data := 'Error while updating SR status '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                        ,p_error_message_code =>   'XX_CS_SR04_ERR_LOG'
                                        ,p_error_msg          =>  x_msg_data);
                 END;

                IF lc_incomplete_flag = 'Y' THEN
                  BEGIN
                    XX_CS_TDS_SR_PKG.ENQUEUE_MESSAGE (P_REQUEST_ID  => p_request_id,
                                                  P_RETURN_CODE  => x_return_status,
                                                  P_RETURN_MSG     => x_msg_data);
                  EXCEPTION
                      WHEN OTHERS THEN
                          x_msg_data  := 'Error while ENQUEUE message to AOPS : '|| x_msg_data;
                           Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                                         ,p_error_message_code =>   'XX_CS_00011_UNEXPECTED_ERR'
                                         ,p_error_msg          =>  x_msg_data
                                          );
                   END;
                END IF;
              END IF;  -- SR Status check

    END IF; -- VENDOR CHECK
 EXCEPTION
 WHEN OTHERS THEN
       x_msg_data := sqlerrm;
       Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TDS_TASK'
                       ,p_error_message_code =>   'XX_CS_SR05_ERR_LOG'
                       ,p_error_msg          => x_msg_data);
END UPDATE_TDS_TASK;
/******************************************************************************
  -- Update Task
*******************************************************************************/
PROCEDURE Update_Task ( P_REQUEST_ID    IN  NUMBER,
                        P_VENDOR        IN  VARCHAR2,
                        P_SERVICE_LINK  IN  VARCHAR2,
                        P_STATUS        IN  NUMBER,
                        P_NOTES_TBL     IN  jtf_tasks_pub.task_notes_tbl,
                        X_RETURN_STATUS OUT NOCOPY VARCHAR2,
                        X_MSG_DATA      OUT NOCOPY VARCHAR2) AS

ln_task_id          number;
ln_task_number      number;
lc_success          varchar2(50);
ln_msg_count        number;
lc_msg_data         varchar2(50);
ln_task_status_id   number;
ln_obj_ver          number;
lc_response         varchar2(25);
lr_task_notes       jtf_tasks_pub.task_notes_rec;--XX_CS_SR_NOTES_REC;
lc_note_status      varchar2(1);
i                   number;
lc_att_category     varchar2(250);
lc_link             varchar2(250);
lc_url              varchar2(500);
lc_sr_status        varchar2(200);
ln_status_id        number;
lc_process_flag     varchar2(1) := 'N';

CURSOR TDS_TASK_CUR IS
SELECT TASK_ID,TASK_STATUS_ID,
        OBJECT_VERSION_NUMBER
        FROM JTF_TASKS_VL
        WHERE SOURCE_OBJECT_ID = P_REQUEST_ID
        AND   SOURCE_OBJECT_TYPE_CODE = 'SR'
        AND   ATTRIBUTE1 = P_VENDOR
        AND   TASK_STATUS_ID NOT IN (8,11);  -- Close status

tds_task_rec  tds_task_cur%rowtype;

BEGIN

  IF P_VENDOR IS NOT NULL THEN

     BEGIN
      OPEN TDS_TASK_CUR;
      LOOP
      FETCH TDS_TASK_CUR INTO TDS_TASK_REC;
      EXIT WHEN TDS_TASK_CUR%NOTFOUND;

       IF P_STATUS IS NOT NULL THEN
          ln_task_status_id   := P_STATUS;
       ELSE
          ln_task_status_id := tds_task_rec.task_status_id;
       END IF;
       /**********************************************************************
        -- Update task
       ********************************************************************/
          begin
           jtf_tasks_pub.update_task
            ( p_object_version_number => tds_task_rec.object_version_number
              ,p_api_version          => 1.0
              ,p_init_msg_list        => fnd_api.g_true
              ,p_commit               => fnd_api.g_false
              ,p_task_id              => tds_task_rec.task_id
              ,x_return_status        => x_return_status
              ,x_msg_count            => ln_msg_count
              ,x_msg_data             => x_msg_data
              ,p_task_status_id       => ln_task_status_id);

              commit;
           exception
           when others then
             Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.update_task'
                             ,p_error_message_code =>  'XX_CS_SR01_ERR_LOG'
                             ,p_error_msg          =>  x_return_status||' '||x_msg_data);
            end;
            /******************************************************************
                -- UPDATE TASK NOTES
            *******************************************************************/
            IF nvl(x_return_status,'S') = 'S' then
             I := p_notes_tbl.first;
             IF I IS NOT NULL THEN
               loop
                    -- lr_task_notes := XX_CS_SR_NOTES_REC(null,null,null,null);
                     lr_task_notes.notes          := p_notes_tbl(i).notes;
                     lr_task_notes.notes_detail   := p_notes_tbl(i).notes_detail;
                     lc_note_status               := p_notes_tbl(i).note_status;
                     lr_task_notes.entered_by     := uid;
                     lr_task_notes.entered_date  := sysdate;

                     IF lr_task_notes.notes is not null then
                         CREATE_NOTE(p_task_id          => ln_task_id,
                                    p_task_notes_rec    => lr_task_notes,
                                    p_notes_status      => lc_note_status,
                                    p_return_status     => x_return_status,
                                    p_msg_data          => x_msg_data);
                    end if;
                EXIT WHEN I = p_notes_tbl.last;
                I := p_notes_tbl.NEXT(I);

               end loop;
             end if;
             commit;
            end IF;
            -- end if update notes
      END LOOP;
      CLOSE TDS_TASK_CUR;
    END;

  ELSE
       BEGIN
          SELECT TASK_ID, TASK_STATUS_ID,
                 OBJECT_VERSION_NUMBER
          INTO LN_TASK_ID, LN_TASK_STATUS_ID,
               LN_OBJ_VER
          FROM JTF_TASKS_VL
          WHERE SOURCE_OBJECT_ID = P_REQUEST_ID
          AND   SOURCE_OBJECT_TYPE_CODE = 'SR'
          AND   TASK_STATUS_ID NOT IN (8,11) -- Completed/close
          AND   ROWNUM < 2;
        EXCEPTION
          WHEN OTHERS THEN
            LN_TASK_ID := NULL;
        END;

       IF P_STATUS IS NOT NULL THEN
          ln_task_status_id   := P_STATUS;
       END IF;
       --
       IF LN_TASK_ID IS NOT NULL THEN
         /*****************************************************************
            -- Update task with assigned status
          *****************************************************************/
          begin
           jtf_tasks_pub.update_task
            ( p_object_version_number => ln_obj_ver
              ,p_api_version          => 1.0
              ,p_init_msg_list        => fnd_api.g_true
              ,p_commit               => fnd_api.g_false
              ,p_task_id              => ln_task_id
              ,x_return_status        => x_return_status
              ,x_msg_count            => ln_msg_count
              ,x_msg_data             => x_msg_data
              ,p_task_status_id       => ln_task_status_id
              );

            commit;
          exception
           when others then
             Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.update_task'
                             ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                             ,p_error_msg          =>  x_return_status||' '||x_msg_data);
          end;

         /******************************************************************
                -- UPDATE TASK NOTES
            *******************************************************************/
            IF nvl(x_return_status,'S') = 'S' then
             I := p_notes_tbl.first;
             IF I IS NOT NULL THEN
               loop
                    -- lr_task_notes := XX_CS_SR_NOTES_REC(null,null,null,null);
                     lr_task_notes.notes          := p_notes_tbl(i).notes;
                     lr_task_notes.notes_detail   := p_notes_tbl(i).notes_detail;
                     lc_note_status               := p_notes_tbl(i).note_status;
                     lr_task_notes.entered_by     := uid;
                     lr_task_notes.entered_date  := sysdate;

                     IF lr_task_notes.notes is not null then
                         CREATE_NOTE(p_task_id          => ln_task_id,
                                    p_task_notes_rec    => lr_task_notes,
                                    p_notes_status      => lc_note_status,
                                    p_return_status     => x_return_status,
                                    p_msg_data          => x_msg_data);
                    end if;
                EXIT WHEN I = p_notes_tbl.last;
                I := p_notes_tbl.NEXT(I);

               end loop;
             end if;
             commit;
            end IF;
            -- end if update notes
            /*
             BEGIN
                SELECT NAME, INCIDENT_STATUS_ID
                INTO LC_SR_STATUS, LN_STATUS_ID
                FROM CS_INCIDENT_STATUSES_VL
                WHERE INCIDENT_SUBTYPE = 'INC'
                AND NAME  = 'Work In Progress';
              EXCEPTION
                WHEN OTHERS THEN
                     X_MSG_DATA := 'error while SELECTING status id for Work In Progresss ';
                        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TASK'
                                        ,p_error_message_code =>   'XX_CS_SR06_ERR_LOG'
                                         ,p_error_msg          =>  x_msg_data);
              END;
             IF LN_STATUS_ID IS NOT NULL THEN
                BEGIN
                    XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => p_request_id,
                                            p_user_id        => fnd_global.user_id,
                                            p_status_id      => ln_status_id,
                                            p_status         => lc_sr_status,
                                            x_return_status  => x_return_status,
                                            x_msg_data      => x_msg_data);

                EXCEPTION
                      WHEN OTHERS THEN
                        x_msg_data := 'Error while updating SR status '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TASK'
                                           ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                           ,p_error_msg          =>  x_msg_data);
                END;
             END IF;
            */
       ELSE
          /**************************************************************
            -- No more pending services, update SR to Call Customer
          ***************************************************************/
              -- Get Status
              BEGIN
                SELECT NAME, INCIDENT_STATUS_ID
                INTO LC_SR_STATUS, LN_STATUS_ID
                FROM CS_INCIDENT_STATUSES_VL
                WHERE INCIDENT_SUBTYPE = 'INC'
                AND NAME  = 'Call Customer';
              EXCEPTION
                WHEN OTHERS THEN
                     X_MSG_DATA := 'error while SELECTING status id for Call Customer ';
                        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TASK'
                                        ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                         ,p_error_msg          =>  x_msg_data);
              END;
             IF LN_STATUS_ID IS NOT NULL THEN
                BEGIN
                    XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => p_request_id,
                                            p_user_id        => fnd_global.user_id,
                                            p_status_id      => ln_status_id,
                                            p_status         => lc_sr_status,
                                            x_return_status  => x_return_status,
                                            x_msg_data      => x_msg_data);

                EXCEPTION
                      WHEN OTHERS THEN
                        x_msg_data := 'Error while updating SR status '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.UPDATE_TASK'
                                        ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                                        ,p_error_msg          =>  x_msg_data);
                END;
             END IF;
       END IF; -- Task check
  END IF;  -- end if vendor check

 EXCEPTION
 WHEN OTHERS THEN
       Log_Exception ( p_error_location     =>  'XX_CS_SR_TASK.update_task'
                       ,p_error_message_code =>   'XX_CS_SR05_ERR_LOG'
                       ,p_error_msg          => x_msg_data);
END UPDATE_TASK;
/*******************************************************************************
********************************************************************************/

END XX_CS_SR_TASK;
/