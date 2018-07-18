CREATE OR REPLACE PACKAGE BODY APPS.XX_CS_SR_UTILS_PKG AS

-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- +============================================================================================+
-- | Name    : XX_CS_SR_UTILS_PKG.pkb                                                           |
-- |                                                                                            |
-- | Description      : Package Body containing procedures CS Concurrent Programs               |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date         Author              Remarks                                         |
-- |=======    ==========   =============       ========================                        |
-- |1.0         -----         -----             Comment Header not present                      |
-- |                                            in this Package                                 |
-- |2.0       21-Jun-13    Ravi Palasamudram    After Defining BOM Exception Calendar,SR adding |
-- |                                            one extra working day to Resolve and Resolution |
-- |                                            Date, to fix this Modified the Get_date_time procedure|
-- |                                            Defect # 23872 -- SR Scheduled on Exception day |
-- |                                            RICE ID # E1254 - UWQ_Timezones                 |
-- |3.0       24-Sep-13   Arun Gannarapu        Made changes as part of R12 retrofit ..         |
--|4.0        11-jan-18  Arun Gannarapu         Made changes for defect 43540
-- +============================================================================================+
/***************************************************************************/
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
     ,p_program_name            => 'XX_CS_SR_UTILS_PKG'
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
/*****************************************************************************
-- Update Service Request
*****************************************************************************/
PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER,
                    X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                    X_MSG_DATA      IN OUT NOCOPY VARCHAR2)
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
   lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
   lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lx_sr_update_rec_type        CS_ServiceRequest_PUB.sr_update_out_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);
   lc_problem_code             VARCHAR2(250);
   lc_auto_assign              VARCHAR2(1) := NULL;

begin

    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

  /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number,
            incident_type_id,
            incident_status_id,
            category_id,
            problem_code
     INTO ln_obj_ver,
           ln_type_id,
           ln_status_id,
           ln_category_id,
           lc_problem_code
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_obj_ver := 2;
        ln_type_id := null;
    END;

      lr_service_request_rec.owner_id        := null;

      IF ln_type_id is not null
      THEN
        lc_auto_assign := 'Y' ;
      ELSE
        lc_auto_assign := 'N' ;

        --  Commented by AG

       --************************************************************************
          -- Get Resources
       --*************************************************************************/
        /*  lr_TerrServReq_Rec.service_request_id   := p_sr_request_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_type_id;
          lr_TerrServReq_Rec.incident_status_id   := ln_status_id;
          lr_TerrServReq_Rec.sr_cat_id            := ln_category_id;
          lr_TerrServReq_Rec.problem_code         := lc_problem_code;
        -- ************************************************************************************************************
         XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
                         p_init_msg_list      => FND_API.G_TRUE,
                         p_TerrServReq_Rec    => lr_TerrServReq_Rec,
                         p_Resource_Type      => NULL,
                         p_Role               => null,
                         x_return_status      => lx_return_status,
                         x_msg_count          => lx_msg_count,
                         x_msg_data           => lx_msg_data,
                         x_TerrResource_tbl   => lt_TerrResource_tbl);

        --****************************************************************************
         IF lt_TerrResource_tbl.count > 0 THEN
            lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
            lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
        end if; */
    end if;
   /*************************************************************************
     -- Add notes
    ************************************************************************/

      lt_notes_table(1).note        := 'Resolved with Future Delivery Date' ;
      lt_notes_table(1).note_detail := 'Resolved with Future Delivery Date';
      lt_notes_table(1).note_type   := 'GENERAL';

   /**************************************************************************
       -- Update SR
    *************************************************************************/

   cs_servicerequest_pub.Update_ServiceRequest (
      p_api_version            => 4.0,
      p_init_msg_list          => FND_API.G_TRUE,
      p_commit                 => FND_API.G_FALSE,
      x_return_status          => lx_return_status,
      x_msg_count              => lx_msg_count,
      x_msg_data               => lx_msg_data,
      p_request_id             => p_sr_request_id,
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

  EXCEPTION
   WHEN OTHERS THEN
       X_RETURN_STATUS := 'F';
       X_MSG_DATA  := 'Error while updating SR '||SQLERRM;
END UPDATE_SR;

/***************************************************************************
  -- Update owner of SR
*****************************************************************************/
Procedure Update_SR_Owner(p_sr_request_id    in number,
                          p_user_id          in varchar2,
                          p_owner            in varchar2,
                          x_return_status    in out nocopy varchar2,
                          x_msg_data         in out nocopy varchar2)
IS
      x_msg_count     NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      ln_group_owner_id  number;
      ln_resource_type   varchar2(100);
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
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
        x_msg_data := 'Error while selecting userid '||sqlerrm;
    end;

      /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number,
            owner_group_id ,
            group_type
     INTO  ln_obj_ver,
           ln_group_owner_id,
           ln_resource_type
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
       x_return_status := 'F';
        x_msg_data := 'Error while selecting incident info '||sqlerrm;
    END;


   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

    /***********************************************************************
     -- Update SR
     ***********************************************************************/
       CS_SERVICEREQUEST_PUB.Update_owner
        (p_api_version        => 2.0,
        p_init_msg_list            => FND_API.G_TRUE,
        p_commit        => FND_API.G_FALSE,
        p_resp_appl_id            => ln_resp_appl_id,
        p_resp_id        => ln_resp_id,
        p_user_id        => ln_user_id,
        p_login_id        => NULL,
        p_request_id        => p_sr_request_id,
        p_request_number    => NULL,
        p_object_version_number => ln_obj_ver,
        p_owner_id         => p_owner,
        p_owner_group_id    => ln_group_owner_id,
        p_resource_type        => ln_resource_type,
        p_audit_comments    => NULL,
        p_called_by_workflow    => NULL,
        p_workflow_process_id    => NULL,
        p_comments        => NULL,
        p_public_comment_flag    => NULL,
        x_interaction_id    => x_interaction_id,
        x_return_status            => x_return_status,
        x_msg_count            => x_msg_count,
        x_msg_data        => x_msg_data);

 --   DBMS_OUTPUT.PUT_LINE('Before update note '||x_return_status);
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

    COMMIT;

EXCEPTION
  WHEN OTHERS
  THEN
    X_RETURN_STATUS := 'F';
    X_MSG_DATA  := 'Error while updating SR '||SQLERRM;

END Update_SR_Owner;

/***************************************************************************
  -- Update SR status
*****************************************************************************/
Procedure Update_SR_status(p_sr_request_id    in number,
                          p_user_id           in varchar2,
                          p_status_id         in number,
                          p_status            in varchar2,
                          x_return_status     in out nocopy varchar2,
                          x_msg_data          in out nocopy varchar2)
IS
      x_msg_count     NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number;
      ln_resp_appl_id    number   :=  514;
      ln_resp_id         number   := 21739;
      lc_problem_code    varchar2(250);
      lc_bin_check_flag  varchar2(1) := 'N';
      ln_status_id       number;
      ln_prev_status_id  number;
      lc_status          varchar2(50);
      ln_type_id         number;
      lc_type_name       varchar2(250);
      lc_owner           varchar2(25);
      lc_dc_flag         varchar2(1) := 'N';
      -- Update whole SR
      lr_TerrServReq_Rec       XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
      lt_TerrResource_tbl      JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
      lr_service_request_rec   CS_ServiceRequest_PUB.service_request_rec_type;
      lx_sr_update_rec_type    CS_ServiceRequest_PUB.sr_update_out_rec_type;
      lt_notes_table           CS_SERVICEREQUEST_PUB.notes_table;
      lt_contacts_tab          CS_SERVICEREQUEST_PUB.contacts_table;
      lx_interaction_id        NUMBER;
      lx_workflow_process_id   NUMBER;
      ln_category_id           number;
      lc_message               varchar2(2000);
      lc_auto_assign           VARCHAR2(1) := NULL;

BEGIN
     begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
    end;
     /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

     /************************************************************************
    -- Get Object version, TYPE, PROBLEM CODE
    *********************************************************************/
    BEGIN
         SELECT object_version_number,
                problem_code,
                incident_type_id,
                incident_status_id,
                category_id
         INTO   ln_obj_ver,
                lc_problem_code,
                ln_type_id,
                ln_prev_status_id,
                ln_category_id
         FROM   cs_incidents_all_b
         WHERE  incident_id = p_sr_request_id;
    EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;

    BEGIN
        SELECT name
        INTO   lc_type_name
        FROM  cs_incident_types
        WHERE incident_type_id = ln_type_id;
     EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'F';
    END;

       BEGIN
          SELECT incident_status_id,
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = p_status ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_status_id := 51;
            lc_status    := 'Waiting';
        END;

   IF LC_TYPE_NAME = 'Stocked Products' THEN
      BEGIN
          select 'Y'
          into  lc_dc_flag
          from  cs_lookups
          where lookup_type = 'XX_CS_WH_EMAIL'
          and   enabled_flag = 'Y'
          and   lookup_code = lc_problem_code;
      EXCEPTION
        WHEN OTHERS THEN
          LC_DC_FLAG := 'N';
      END;
   END IF;
  -- dbms_output.put_line('DC flag and Status '||LC_DC_FLAG||' '||LN_PREV_STATUS_ID);
 /*   lc_message := 'DC flag and Status '||LC_DC_FLAG||' '||LN_PREV_STATUS_ID;

    Log_Exception ( p_error_location     =>  'XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_message); */

   IF LC_DC_FLAG = 'N' OR
      (LC_DC_FLAG = 'Y' AND LN_PREV_STATUS_ID NOT IN (1,51)) THEN
      /***********************************************************************
       -- Update SR
       ***********************************************************************/
        CS_SERVICEREQUEST_PUB.Update_Status
            (p_api_version        => 2.0,
             p_init_msg_list            => FND_API.G_TRUE,
             p_commit                => FND_API.G_FALSE,
              x_return_status            => x_return_status,
              x_msg_count            => x_msg_count,
              x_msg_data        => x_msg_data,
              p_resp_appl_id            => ln_resp_appl_id,
              p_resp_id                => ln_resp_id,
              p_user_id                => ln_user_id,
              p_login_id        => NULL,
              p_request_id        => p_sr_request_id,
              p_request_number            => NULL,
              p_object_version_number   => ln_obj_ver,
              p_status_id         => ln_status_id,
              p_status                => lc_status,
              p_closed_date        => SYSDATE,
              p_audit_comments            => NULL,
              p_called_by_workflow    => NULL,
              p_workflow_process_id    => NULL,
              p_comments        => NULL,
              p_public_comment_flag    => NULL,
              x_interaction_id            => x_interaction_id );

            COMMIT;
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

      ELSE  -- Update whole SR

        cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
        lr_service_request_rec.owner_id        := null;
        lr_service_request_rec.status_id   := ln_status_id;

        IF ln_type_id is not null
        then
          lc_auto_assign := 'Y' ;
        ELSE
          lc_auto_assign := 'N' ;


         --************************************************************************
            -- Get Resources
         --*************************************************************************

         /* Comment starts -AG
            lr_TerrServReq_Rec.service_request_id   := p_sr_request_id;
            lr_TerrServReq_Rec.incident_type_id     := ln_type_id;
            lr_TerrServReq_Rec.problem_code         := lc_problem_code;
            lr_TerrServReq_Rec.incident_status_id   := ln_status_id;
            lr_TerrServReq_Rec.sr_cat_id            := ln_category_id;
         --   dbms_output.put_line('cat id'||ln_category_id);
           --*************************************************************************************************************
           XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
                           p_init_msg_list      => FND_API.G_TRUE,
                           p_TerrServReq_Rec    => lr_TerrServReq_Rec,
                           p_Resource_Type      => NULL,
                           p_Role               => null,
                           x_return_status      => x_return_status,
                           x_msg_count          => x_msg_count,
                           x_msg_data           => x_msg_data,
                           x_TerrResource_tbl   => lt_TerrResource_tbl);

          --****************************************************************************
           IF lt_TerrResource_tbl.count > 0 THEN
              lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
              lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
          end if; */  -- Comment end AG
      end if;

       --   dbms_output.put_line('group '||lr_service_request_rec.owner_group_id);
           lc_message := 'group '||lr_service_request_rec.owner_group_id;

   /*  Log_Exception ( p_error_location     =>  'XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS'
                       ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_message); */
         /*************************************************************************
           -- Add notes
          ************************************************************************/
          IF ln_status_id <> 51 THEN
            lt_notes_table(1).note        := 'eOrder Team Responded' ;
            lt_notes_table(1).note_detail := 'eOrder Team Responded';
            lt_notes_table(1).note_type   := 'GENERAL';
          END IF;
         /**************************************************************************
             -- Update SR
          *************************************************************************/

         cs_servicerequest_pub.Update_ServiceRequest (
            p_api_version            => 4.0,
            p_init_msg_list          => FND_API.G_TRUE,
            p_commit                 => FND_API.G_FALSE,
            x_return_status          => x_return_status,
            x_msg_count              => x_msg_count,
            x_msg_data               => x_msg_data,
            p_request_id             => p_sr_request_id,
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

            commit;

         IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
            IF (FND_MSG_PUB.Count_Msg > 1) THEN
               --Display all the error messages
               FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
                  FND_MSG_PUB.Get(p_msg_index     => j,
                                  p_encoded       => 'F',
                                  p_data          => x_msg_data,
                                  p_msg_index_out => ln_msg_index_out);
               END LOOP;
            ELSE      --Only one error
               FND_MSG_PUB.Get(
                  p_msg_index     => 1,
                  p_encoded       => 'F',
                  p_data          => x_msg_data,
                  p_msg_index_out => ln_msg_index_out);

            END IF;
        END IF;

         LC_MESSAGE := 'Update Status '||x_return_status||' '||x_msg_data;
         Log_Exception ( p_error_location     =>  'XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS'
                       ,p_error_message_code =>   'XX_CS_SR03_SUCCESS_LOG'
                       ,p_error_msg          =>  lc_message);
    END IF;
END Update_SR_Status;

/***************************************************************************/
/*********************************************************************************
    Create Notes
*********************************************************************************/
PROCEDURE CREATE_NOTE(p_request_id           in number,
                       p_sr_notes_rec         in XX_CS_SR_MAIL_NOTES_REC,
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
lc_note_status            := 'I';  -- (P-Private, E-Publish, I-Public)
lc_note_type            := 'GENERAL';
lc_notes            := p_sr_notes_rec.notes;
lc_notes_detail            := p_sr_notes_rec.note_details;
ln_entered_by            := FND_GLOBAL.user_id;
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
/***************************************************************************/
PROCEDURE GET_DATE_TIMES (P_CAL_ID IN VARCHAR2,
                          P_START_TIME IN OUT NUMBER,
                          P_END_TIME IN OUT NUMBER,
                          P_DATE IN OUT DATE)
IS
ld_local_date   date := NULL;
BEGIN

     /************************ COMMENT START ************************************
                Commented as per QC # 23872 - SR scheduled on exception day
                     RICE ID # E1254 - UWQ_Timezones
      ***************************************************************************/

    --IF ld_local_date is null then

   --  LOOP

   --    begin
   --         select b2.from_time, b2.to_time, b1.next_date
  --          into   p_start_time, p_end_time, p_date
  --          from    bom_calendar_dates b1,
  --                  bom_shift_times b2
  --          where b2.calendar_code = b1.calendar_code
  --          and    b1.calendar_code = P_CAL_ID
  --          and   trunc(b1.calendar_date) = trunc(p_date)
  --          and   b2.shift_num = 1
  --          and   not exists ( select 'x' from bom_calendar_exceptions
  --                        where calendar_code = b1.calendar_code
  --                        and  exception_date = b1.calendar_date
  --                        and  exception_set_id = b1.exception_set_id);

  --            ld_local_date := p_date;
  --        exception
  --          when others then

  --              select b2.from_time, b2.to_time, b1.next_date
  --                into   p_start_time, p_end_time, p_date
  --                from    bom_calendar_dates b1,
  --                        bom_shift_times b2
  --                where b2.calendar_code = b1.calendar_code
  --                and    b1.calendar_code = P_CAL_ID
  --                and   trunc(b1.calendar_date) = trunc(p_date)
  --                and   b2.shift_num = 1;

  --                p_date := p_date + 1;

  --    end;

  --  exit when ld_local_date is not null;
  --  end loop;

    --end if;

  -- ************* END Commented as per QC # 23872 - SR scheduled on exception day*****

    BEGIN

              SELECT b2.from_time, b2.to_time, b1.next_date
               INTO   p_start_time, p_end_time, p_date
               FROM   bom_calendar_dates b1,
                      bom_shift_times b2
               WHERE b2.calendar_code = b1.calendar_code
                AND    b1.calendar_code = P_CAL_ID
                AND   trunc(b1.calendar_date) = trunc(p_date)
                AND   b2.shift_num = 1;

                    ld_local_date := p_date;

     END;


END GET_DATE_TIMES;
/***************************************************************************/
FUNCTION RES_REV_TIME_CAL (P_DATE IN DATE,
                           P_HOURS IN NUMBER,
                           P_CAL_ID IN VARCHAR2,
                           P_TIME_ID IN NUMBER)
RETURN DATE IS

ln_curtime    number;
ln_orgtime    number;
ln_remtime    number;
ln_localtime  number;
i             number := 1;
x_start_time  number;
x_end_time    number;
ln_bal_hours  number;
ln_bal_min    integer;
ld_date       date;
ld_l_date     date;
lc_holiday    varchar2(1) := 'N';
ld_create_date date;
ld_timestamp  timestamp;
ln_days       number;
ln_diff       number;
a             INTERVAL DAY TO SECOND;


BEGIN
 --DBMS_OUTPUT.PUT_LINE('Sys Time '||(TO_CHAR(p_date, 'DD-MON-YYYY HH24:MI:SS')));

   ln_localtime   := (TO_CHAR(p_date,'HH24.MI'))*3600;
   ld_date        := HZ_TIMEZONE_PUB.Convert_DateTime(1,p_time_id,p_date);
   ln_orgtime     := (TO_CHAR(ld_date,'HH24.MI'))*3600;
   ld_create_date := p_date;

  --  DBMS_OUTPUT.PUT_LINE('after conversion '||(TO_CHAR(ld_date, 'DD-MON-YYYY HH24:MI:SS')));

  IF p_hours > 8 then
    ln_days := floor(p_hours/8);
    ld_date := p_date;
    ln_curtime := (TO_CHAR(LD_DATE,'HH24.MI'))*3600;
    for i in 1 .. ln_days loop
      ld_date := ld_date + 1;
           begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
           end;
    end loop;
  else
    ld_date := ld_date + p_hours/24;
    ln_curtime := (TO_CHAR(ld_date,'HH24.MI'))*3600;
     --DBMS_OUTPUT.PUT_LINE('after adding '||(TO_CHAR(ld_date, 'DD-MON-YYYY HH24:MI:SS')));
         begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
          end;
  end if;

  If trunc(ld_date) > trunc(p_date) then
        -- Checking created date working day or not
         begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_create_date);
          end;
         -- dbms_output.put_line(ld_create_date);
    IF ld_create_date > p_date then
       lc_holiday := 'Y';
       DBMS_OUTPUT.PUT_LINE('Holiday');
        ln_bal_hours := (x_start_time/3600 + p_hours);
          -- added on6/28/10
        ld_date := ld_create_date; -- + ln_bal_hours/24;
        ln_curtime := (TO_CHAR(ld_date,'HH24.MI'))*3600;
     END IF;

  end if;
 IF lc_holiday = 'N' then
  --DBMS_OUTPUT.PUT_LINE('BAL HOURS '||ln_bal_hours||' Cur time '||ln_curtime||' end time'||x_end_time||'org '||ln_orgtime);
  IF ln_curtime > x_end_time then
    IF ln_orgtime > x_end_time then
      ln_bal_hours := 8 + p_hours;
    else
      ln_remtime := ln_curtime - x_end_time;
      ln_bal_hours := 8 + (ln_remtime/3600);
      ln_bal_min   := 100*(ln_bal_hours - floor(ln_bal_hours));
    end if;
     ld_date     := ld_date+1;
         begin
             get_date_times (p_cal_id => p_cal_id,
                             p_start_time => x_start_time,
                             p_end_time => x_end_time,
                             p_date => ld_date);
          end;
   --  DBMS_OUTPUT.PUT_LINE('bgbvbBAL HOURS '||ln_bal_hours);
          ln_bal_min   := 100*(ln_bal_hours - floor(ln_bal_hours));
ELSIF ln_curtime < x_start_time then
   IF ln_orgtime > x_end_time or ln_orgtime < x_start_time then
       ln_bal_hours := x_start_time/3600 + p_hours;
   else
        ln_remtime := x_start_time - ln_curtime;
        ln_bal_hours := (ln_remtime/3600);
        ln_bal_min   := 100*(ln_bal_hours - floor(ln_bal_hours));
        --ln_bal_min   := ln_bal_min + 1;
   end if;
      --  ld_date      := ld_date + ln_bal_hours/24;
    --DBMS_OUTPUT.PUT_LINE('BAL HOURS '||ln_bal_hours);
  ELSE
    IF ln_orgtime < x_start_time then
      ln_bal_hours := x_start_time/3600 + p_hours;
    ELSE
      ln_bal_hours := (ln_curtime/3600);
     -- DBMS_OUTPUT.PUT_LINE('BAL HOURS '||ln_bal_hours);

      ln_bal_min   := 100*(ln_bal_hours - floor(ln_bal_hours));
     -- ln_bal_min   := ln_bal_min + 1;
      -- DBMS_OUTPUT.PUT_LINE('MIN '||ln_bal_min);
    END IF;
  END IF;
 END IF;
     ln_bal_hours := floor(ln_bal_hours);
     ld_date := ld_date + ln_bal_hours/24;

     IF ln_bal_min <> 0 THEN
      ld_date := ld_date + ln_bal_min/1440;
      END IF;
     ln_diff := ((ln_localtime-ln_orgtime)/3600);
     --DBMS_OUTPUT.PUT_LINE('BEFORE CONVERSION '||(TO_CHAR(ld_date, 'DD-MON-YYYY HH24:MI:SS')));
     IF ln_diff <> 0 then
      ld_date := HZ_TIMEZONE_PUB.Convert_DateTime(p_time_id,1,ld_date);
     end if;

   DBMS_OUTPUT.PUT_LINE('Fianl '||(TO_CHAR(ld_date, 'DD-MON-YYYY HH24:MI:SS')));
  return ld_date;

END RES_REV_TIME_CAL;
/**************************************************************************/
/******************************************************************************
 -- Send Mail
 ******************************************************************************/
 Procedure Send_mail(p_request_number in number,
                     p_return_status in out nocopy varchar2,
                     p_return_msg in out nocopy varchar2)
 is

    l_request_number          VARCHAR2(64);
    ln_request_id             number;
    lc_message                varchar2(1000);
    lc_subject                varchar2(250);
    ln_return_code            number;
    lc_message_body           LONG;
    lc_mesg                   LONG ;
    lc_smtp_server            VARCHAR2(250);
    lc_return_code            NUMBER;
    lc_mail_conn              utl_smtp.connection;
    crlf                      VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
    v_mail_reply              utl_smtp.reply;
    lc_sender                 VARCHAR2(250);
    lc_recipient              VARCHAR2(250);
    lc_tier                   VARCHAR2(50);
    CURSOR sel_incident_csr IS
     SELECT inc.incident_type_id type_id,
             cit.name type_name,
             inc.incident_id,
             inc.creation_date,
             inc.problem_code,
             inc.summary,
             replace(csl.description,'_WH_', inc.incident_attribute_11) email_id,
             csl.lookup_code,
             inc.incident_attribute_9 aops_id,
             inc.tier
      FROM   cs_incidents inc,
             cs_incident_types cit,
             cs_lookups csl
      WHERE  csl.lookup_code = inc.problem_code
      and    inc.incident_number = p_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    cit.end_date_active is null
      --and    cit.name = 'Stocked Products'
      and    csl.lookup_type = 'XX_CS_WH_EMAIL'
      and    csl.enabled_flag = 'Y'
      and    not exists(select 'X' from cs_lookups cl 
	                    where cl.lookup_type = 'XX_CS_WH_EMAIL' 
						and cl.enabled_flag = 'Y' 
						and cl.lookup_code = inc.incident_attribute_11)
      UNION 
       SELECT inc.incident_type_id type_id,
             cit.name type_name,
             inc.incident_id,
             inc.creation_date,
             inc.problem_code,
             inc.summary,
             replace(csl.meaning,'_WH_', inc.incident_attribute_11) email_id,
             csl.description lookup_code,
             inc.incident_attribute_9 aops_id,
             inc.tier
      FROM   cs_incidents inc,
             cs_incident_types cit,
             cs_lookups csl
      WHERE  csl.description = inc.problem_code
      and    inc.incident_number = p_request_number
      and    cit.incident_type_id = inc.incident_type_id
      and    cit.end_date_active is null
      AND    inc.incident_attribute_11 = csl.lookup_code
      --and    cit.name = 'Stocked Products'
      and    csl.lookup_type = 'XX_CS_WH_EMAIL'
      and    csl.enabled_flag = 'Y';

    l_incident_rec   sel_incident_csr%ROWTYPE;

  begin

    -- Obtain values initialized from the parameter list.
    l_request_number  := p_request_number;

    OPEN sel_incident_csr;
    FETCH sel_incident_csr INTO l_incident_rec;
    IF (sel_incident_csr%FOUND AND l_incident_rec.type_id IS NOT NULL ) THEN

          IF l_incident_rec.incident_id is not null then
            BEGIN
              select note
              into lc_message
              from cs_sr_notes_v
              where incident_id = l_incident_rec.incident_id
              and   note_status = 'E'
              and   rownum < 2;
            exception
              when others then
                lc_message := null;
            END;

          IF l_incident_rec.lookup_code = 'MSDS REQUEST' then

            begin
              select fnd_profile.value('XX_CS_SMTP_SERVER')
              into lc_smtp_server
              from dual;
            exception
              when others then
                 lc_smtp_server := 'USCHMSX83.na.odcorp.net';
            end;
            lc_sender := 'SVC-CallCenter@officedepot.com';
            lc_subject := 'MSDS REQUEST for Customer: '||l_incident_rec.aops_id;
            lc_message_body := lc_message;
                  Begin
                       lc_mail_conn  := utl_smtp.open_connection(lc_smtp_server,25);
                       lc_mesg       := 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf ||
                       'From: <'||lc_sender||'>' || crlf ||
                       'Subject: '||lc_subject || crlf ||
                       'To: '||l_incident_rec.email_id || crlf || crlf ||
                        lc_message_body;
                        utl_smtp.helo(lc_mail_conn, lc_smtp_server);
                        utl_smtp.mail(lc_mail_conn, lc_sender);
                        utl_smtp.rcpt(lc_mail_conn, lc_recipient);
                        utl_smtp.data(lc_mail_conn, lc_mesg);
                        utl_smtp.quit(lc_mail_conn);
                   End;

          else
            lc_subject := l_incident_rec.lookup_code;
            IF lc_message is null then
              lc_message := l_incident_rec.summary;
            END IF;

            IF l_incident_rec.email_id is not null then

              XX_CS_MESG_PKG.send_email (sender    => 'SVC-CallCenter@officedepot.com',
                                        recipient      => l_incident_rec.email_id,
                                        cc_recipient   => null ,
                                        bcc_recipient  => null ,
                                        subject        => lc_subject,
                                        message_body   => lc_message,
                                        p_message_type => 'CONFIRMATION',
                                        IncidentNum    => l_incident_rec.incident_id,
                                        return_code    => ln_return_code );
            ELSE
                 p_return_msg     := 'eMail id is not valid for SR#'||l_request_number ||' and email is not issued.';
                 p_return_status  := 'F';

            END IF; -- EMAIL ID
          END IF; -- REQUEST TYPE
          END IF; -- incident id

    END IF; -- Type id is not null

    CLOSE sel_incident_csr;

  EXCEPTION
    WHEN others THEN
      p_return_msg     := 'Error '||sqlerrm|| ' while sending Mail for SR#'||l_request_number;
      p_return_status  := 'F';
  END Send_mail;
/****************************************************************************
 -- Send Mail
 ****************************************************************************/
END;
/
