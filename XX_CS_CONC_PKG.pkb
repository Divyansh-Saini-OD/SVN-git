CREATE OR REPLACE
PACKAGE BODY "XX_CS_CONC_PKG" AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_CONC_PKG.pkb                                                            |
-- |                                                                                         |
-- | Description      : Package Body containing procedures CS Concurrent Programs            |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       28-Apr-09        Raj Jagarlamudi        Initial draft version                  |
-- |2.0       28-Aug-12        Raj Jagarlamudi        Added TDS SMB subscriptions            |   
-- |3.0       19-Jun-13        Arun Gannarapu         Made changes to pass p_auto_assign = Y |
-- |                                                  for updat SR API                       |
-- |3.0       22-Jan-16        Vasu raparla           Removed Schema References for R.12.2   |
-- |4.0 	  23-Feb-2016	   Anoop Salim		      Changes for Defect# 37051			     |
-- |5.0		  20-FEB-2017	   Mohammed Arif	      Modified the Package Body to get the 	 |
-- |												  program complete in warning status,    |
-- |												  Defect # 38994.		                 |
-- +=========================================================================================+

gc_conc_prg_id                      NUMBER   := fnd_global.conc_request_id;
lc_error_message                    VARCHAR2(4000);
ln_msg_count                        PLS_INTEGER;
lc_msg_data                         VARCHAR2(4000);
lc_return_status                    VARCHAR2(1);


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
     ,p_application_name        => 'XX_CS'
     ,p_program_type            => 'CS Conc Prog'
     ,p_program_name            => 'XX_CS_CONC_PKG'
     ,p_program_id              => gc_conc_prg_id
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

/***************************************************************************
**************************************************************************/
PROCEDURE UPDATE_SR (P_REQUEST_ID     IN NUMBER,
                     P_GROUP_OWNER_ID IN NUMBER,
                     P_WAREHOUSE_ID   IN VARCHAR2,
                     X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2)
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
   lc_problem_code             varchar2(100);
   lr_TerrServReq_Rec          XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
   lt_TerrResource_tbl         JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
   lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
   lx_sr_update_rec_type       CS_ServiceRequest_PUB.sr_update_out_rec_type;
   lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);
   lc_auto_assign              VARCHAR2(1) := NULL;

begin

    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

    begin
      select mtls.category_set_id, mtlb.category_id
      into lr_service_request_rec.category_set_id,
           lr_service_request_rec.category_id
      from mtl_category_sets_vl mtls,
           mtl_categories_b mtlb
      where mtlb.structure_id = mtls.structure_id
      and   mtls.category_set_name = 'CS Warehouses'
      and   mtlb.segment1 = p_warehouse_id
      and   mtlb.segment1 in (select attribute1 
                              from hr_all_organization_units
                              where  substr(type,1,2) = 'WH');
    exception
      when others then
        lr_service_request_rec.category_set_id := null;
        lr_service_request_rec.category_id := null;
    end;

  /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number,
            incident_type_id,
            problem_code
     INTO ln_obj_ver,
           ln_type_id,
           lc_problem_code
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_obj_ver := 2;
        ln_type_id := null;
    END;
    /*****************************************************************
     -- Get Status Id
     *****************************************************************/
     BEGIN
          SELECT incident_status_id
          INTO  lr_service_request_rec.status_id
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = 'Resolved Missed Promise';
        EXCEPTION
          WHEN OTHERS THEN
            lr_service_request_rec.status_id := 1;
        END;

      lr_service_request_rec.owner_id        := null;

     -- Comment starts AG

     IF ln_type_id is not null 
     THEN
       lr_service_request_rec.owner_group_id  := NULL;
       lc_auto_assign := 'Y';
     ELSE 
       lc_auto_assign := 'N';
     END IF;

        --*************************************************************************
          -- Get Resources
       --*************************************************************************
      /*    lr_TerrServReq_Rec.service_request_id   := p_request_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_type_id;
          lr_TerrServReq_Rec.problem_code         := lc_problem_code;
          lr_TerrServReq_Rec.incident_status_id   := lr_service_request_rec.status_id;
          lr_TerrServReq_Rec.sr_cat_id            := lr_service_request_rec.category_id;
        --*************************************************************************************************************
         XX_CS_RESOURCES_PKG.Get_Resources(p_api_version_number => 2.0,
                         p_init_msg_list      => FND_API.G_TRUE,
                         p_TerrServReq_Rec    => lr_TerrServReq_Rec,
                         p_Resource_Type      => NULL,
                         p_Role               => null,
                         x_return_status      => lx_return_status,
                         x_msg_count          => lx_msg_count,
                         x_msg_data           => lx_msg_data,
                         x_TerrResource_tbl   => lt_TerrResource_tbl);

        ***************************************************************************
         IF lt_TerrResource_tbl.count > 0 THEN
            lr_service_request_rec.owner_group_id := lt_TerrResource_tbl(1).resource_id;
            lr_service_request_rec.group_type     := lt_TerrResource_tbl(1).resource_type;
        end if;
    end if; */ -- commented by ag

   /*************************************************************************
     -- Add notes
    ************************************************************************

      lt_notes_table(1).note        := 'Close Loop - Delivery not completed' ;
      lt_notes_table(1).note_detail := 'Delivery message not received';
      lt_notes_table(1).note_type   := 'GENERAL';

   /**************************************************************************
       -- Update SR
    *************************************************************************/

    lc_message := 'Before UPDATE SR '||lr_service_request_rec.status_id;
    fnd_file.put_line(fnd_file.log, lc_message);

   cs_servicerequest_pub.Update_ServiceRequest (
      p_api_version            => 4.0,
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
      p_auto_assign            => lc_auto_assign,
      p_workflow_process_id    => NULL,
      x_sr_update_out_rec      => lx_sr_update_rec_type
     -- x_workflow_process_id    => lx_workflow_process_id,
     -- x_interaction_id         => lx_interaction_id 
     );

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
      lc_message := 'FND  '||lx_return_status ||' '||lx_msg_data;
       fnd_file.put_line(fnd_file.log, lc_message);
   END IF;
   lc_message := 'Update Status '||lx_return_status ||' '||lx_msg_data;
   fnd_file.put_line(fnd_file.log, lc_message);
   
   x_return_status := lx_return_status;
 --  dbms_output.put_line('status '||lc_message);
   
exception
   when others then
      x_return_status := 'F';
      Log_Exception ( p_error_location     =>  'XX_CS_CONC_PKG.UPDATE_SR'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
END UPDATE_SR;
/***************************************************************************
**************************************************************************/
PROCEDURE UPDATE_CL_SR (P_REQUEST_ID     IN NUMBER,
                        P_STATUS         IN VARCHAR2,
                        P_WAREHOUSE_ID   IN VARCHAR2,
                        X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2)
IS

   lx_msg_count                NUMBER;
   lx_msg_data                 VARCHAR2(2000);
   lx_request_id               NUMBER;
   lx_request_number           VARCHAR2(50);
   lx_interaction_id           NUMBER;
   lx_workflow_process_id      NUMBER;
   lx_msg_index_out            NUMBER;
   lx_return_status            VARCHAR2(1);
   ln_status_id                NUMBER;
   ln_obj_ver                  NUMBER ;
   ln_type_id                  NUMBER;
   lc_problem_code             varchar2(100);
   lr_TerrServReq_Rec           XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type;
   lt_TerrResource_tbl          JTF_TERRITORY_PUB.WinningTerrMember_tbl_type;
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lx_sr_update_rec_type        CS_ServiceRequest_PUB.sr_update_out_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);
   ln_user_id                  number; -- := 1955;
   ln_resp_appl_id             number :=  514;
   ln_resp_id                  number := 21739;  -- Customer Support
   lc_auto_assign              VARCHAR2(1) := NULL;

BEGIN

    begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        lc_message := 'Error while selecting user id for CS_ADMIN '||sqlerrm;
        fnd_file.put_line(fnd_file.log, lc_message);
    end;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

    begin
      select mtls.category_set_id, mtlb.category_id
      into lr_service_request_rec.category_set_id,
           lr_service_request_rec.category_id
      from mtl_category_sets_vl mtls,
           mtl_categories_b mtlb
      where mtlb.structure_id = mtls.structure_id
      and   mtls.category_set_name = 'CS Warehouses'
      and   mtlb.segment1 = p_warehouse_id
      and   mtlb.segment1 in (select attribute1 
                              from hr_all_organization_units
                              where  substr(type,1,2) = 'WH');
    exception
      when others then
        lr_service_request_rec.category_set_id := null;
        lr_service_request_rec.category_id := null;
    end;
    
  /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number,
            incident_type_id,
            problem_code
       INTO ln_obj_ver,
             ln_type_id,
             lc_problem_code
     FROM   cs_incidents_all_b
     WHERE  incident_id = p_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_obj_ver := 2;
        ln_type_id := null;
    END;
    /*****************************************************************
     -- Get Status Id
     *****************************************************************/
     BEGIN
          SELECT incident_status_id
          INTO  lr_service_request_rec.status_id
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = P_STATUS;
        EXCEPTION
          WHEN OTHERS THEN
            lr_service_request_rec.status_id := 1;
        END;

    IF P_STATUS <> 'Closed' 
    AND lr_service_request_rec.category_id is not null 
    THEN

      lr_service_request_rec.owner_id        := null;

      IF ln_type_id is not null 
      THEN
        lc_auto_assign := 'Y';
        lr_service_request_rec.owner_group_id  := NULL;
      ELSE 
        lc_auto_assign := 'N';
      END IF;


      -- ************************************************************************
      -- Get Resources
      -- *************************************************************************
       /* -- Comment start AG

          lr_TerrServReq_Rec.service_request_id   := p_request_id;
          lr_TerrServReq_Rec.incident_type_id     := ln_type_id;
          lr_TerrServReq_Rec.problem_code         := lc_problem_code;
          lr_TerrServReq_Rec.incident_status_id   := lr_service_request_rec.status_id;
          lr_TerrServReq_Rec.sr_cat_id            := lr_service_request_rec.category_id;
      --************************************************************************************
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
        end if;
       end if; */  -- comment end AG

       /**************************************************************************
           -- Update SR
        *************************************************************************/
        lc_message := 'Before UPDATE SR '||lr_service_request_rec.status_id;
        fnd_file.put_line(fnd_file.log, lc_message);
    
       cs_servicerequest_pub.Update_ServiceRequest (
          p_api_version            => 4.0,
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
          p_auto_assign            => lc_auto_assign,
          p_workflow_process_id    => NULL,
          x_sr_update_out_rec      => lx_sr_update_rec_type
        );
        
    ELSE
      ln_status_id := 2;
      
      CS_SERVICEREQUEST_PUB.Update_Status
                (p_api_version		    => 2.0,
                p_init_msg_list	        => FND_API.G_TRUE,
                p_commit		        => FND_API.G_FALSE,
                x_return_status	        => lx_return_status,
                x_msg_count	            => lx_msg_count,
                x_msg_data              => lx_msg_data,
                p_resp_appl_id	        => ln_resp_appl_id,
                p_resp_id		        => ln_resp_id,
                p_user_id		        => ln_user_id,
                p_login_id		        => NULL,
                p_request_id		    => p_request_id,
                p_request_number	    => NULL,
                p_object_version_number => ln_obj_ver,
                p_status_id             => ln_status_id,
                p_status                => NULL,
                p_closed_date           => SYSDATE,
                p_audit_comments	    => NULL,
                p_called_by_workflow	=> NULL,
                p_workflow_process_id	=> NULL,
                p_comments              => NULL,
                p_public_comment_flag	=> NULL,
                x_interaction_id	    => lx_interaction_id);
   END IF;
    
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
      lc_message := 'FND  '||lx_return_status ||' '||lx_msg_data;
       fnd_file.put_line(fnd_file.log, lc_message);
   END IF;
   lc_message := 'Update Status '||lx_return_status ||' '||lx_msg_data;
   fnd_file.put_line(fnd_file.log, lc_message);
   
   x_return_status := lx_return_status;
 --  dbms_output.put_line('status '||lc_message);
   
exception
   when others then
      x_return_status := 'F';
      Log_Exception ( p_error_location     =>  'XX_CS_CONC_PKG.UPDATE_CL_SR'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
END UPDATE_CL_SR;
/******************************************************************************
*******************************************************************************/
PROCEDURE ROUTE_CL_SR
IS

CURSOR CL_CUR IS
SELECT CB.INCIDENT_ID REQUEST_ID,
       CB.INCIDENT_ATTRIBUTE_2 PROMISE_DATE,
       replace(CB.INCIDENT_ATTRIBUTE_6,'00:00:00','') new_Promise_date,
       CB.INCIDENT_ATTRIBUTE_11 WAREHOUSE_ID,
       CB.PROBLEM_CODE,
       NVL(CB.RESOLUTION_CODE,'X') RESOLUTION_CODE
FROM   CS_INCIDENTS_ALL_B CB,
       CS_INCIDENT_STATUSES_VL CL
WHERE  CL.INCIDENT_STATUS_ID = CB.INCIDENT_STATUS_ID
AND    CL.INCIDENT_SUBTYPE = 'INC'
AND    CL.NAME = 'Close Loop' --IN ('Resolved Future Promise', 'Close Loop')
AND    DECODE(CB.INCIDENT_ATTRIBUTE_12, NULL, CB.INCIDENT_ATTRIBUTE_1, CB.INCIDENT_ATTRIBUTE_12) IS NOT NULL
AND    EXISTS ( SELECT 'x'
           FROM CS_INCIDENT_TYPES_TL
           WHERE NAME = 'Stocked Products'
           AND INCIDENT_TYPE_ID  = CB.INCIDENT_TYPE_ID);
           
CL_REC                CL_CUR%ROWTYPE;

LC_STATUS             VARCHAR2(100);
LC_RES_FLAG           VARCHAR2(1) := 'N';
ld_promise_date       date;
LC_RETURN_STATUS      VARCHAR2(50);
LC_MESSAGE            VARCHAR2(2000);

BEGIN
   OPEN CL_CUR;
   LOOP
   FETCH CL_CUR INTO CL_REC;
   EXIT WHEN CL_CUR%NOTFOUND;
   
    IF CL_REC.PROBLEM_CODE IN ('LATE DELIVERY', 'RETURN NOT PICKED UP') THEN
    
       IF cl_rec.new_promise_date is null then
         ld_promise_date     := to_date(cl_rec.promise_date,'mm/dd/yy');
       else
         ld_promise_date := to_date(cl_rec.new_promise_date, 'YYYY/MM/DD');
       end if;
     
        BEGIN
         select 'Y'
         into lc_res_flag 
         from cs_lookups
         where lookup_type = 'XX_CS_CL_RESV_TYPES'
         and enabled_flag = 'Y'
         and end_date_active is null
         and lookup_code = nvl(cl_rec.resolution_code,'x');
        EXCEPTION
         WHEN OTHERS THEN
           lc_res_flag := 'N';
        END;
        
        IF LC_RES_FLAG = 'N' AND LD_PROMISE_DATE > (SYSDATE - 1) THEN
           LC_STATUS := 'Resolved Future Promise';
        ELSE 
           LC_STATUS := 'Closed';
        END IF;
        
    ELSE
       LC_STATUS := 'Closed';
    END IF;
    
    BEGIN
      UPDATE_CL_SR (P_REQUEST_ID        => CL_REC.REQUEST_ID,
                        P_STATUS        => LC_STATUS,
                        P_WAREHOUSE_ID  => CL_REC.WAREHOUSE_ID,
                        X_RETURN_STATUS => LC_RETURN_STATUS);
    EXCEPTION
      WHEN OTHERS THEN
        LC_MESSAGE := 'Error while updating SR#'||cl_rec.request_id||' '||sqlerrm;
        Log_Exception ( p_error_location     =>  'XX_CS_CONC_PKG.ROUTE_CL_SR'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
   
    END;
     
   end loop;
   close CL_CUR;
  
END ROUTE_CL_SR;
/*******************************************************************************
*******************************************************************************/

PROCEDURE GET_AQ_MSG (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER )
AS

lc_return_msg   varchar2(2000);
ln_return_code  number;

BEGIN

    lc_return_msg := 'Before Calling get Messages';
    fnd_file.put_line(fnd_file.log, lc_return_msg);

    BEGIN

      XX_CS_CLOSE_LOOP_PKG.GET_AQ_MESSAGE(P_RETURN_CODE => LN_RETURN_CODE,
                                          P_ERROR_MSG  => LC_RETURN_MSG);

      X_RETCODE := LN_RETURN_CODE;
      X_ERRBUF  := LC_RETURN_MSG;

     commit;

    EXCEPTION
     WHEN OTHERS THEN
      x_retcode := 2;
      lc_return_msg := 'Error while calling GET_AQ. '|| lc_return_msg;
      x_errbuf   := lc_return_msg;
      Log_Exception ( p_error_location     =>  'GET_AQ_MSG'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_return_msg
                    );
    END;

END GET_AQ_MSG;

/*****************************************************************
-- Route to DC if delivery not completed as per scheduled
******************************************************************/

PROCEDURE ROUTE_DC_QUEUE (x_errbuf     OUT  NOCOPY  VARCHAR2
                        , x_retcode  OUT  NOCOPY  NUMBER )
AS
CURSOR CS_CUR IS
SELECT CB.INCIDENT_ID REQUEST_ID,
       CB.INCIDENT_ATTRIBUTE_2 PROMISE_DATE,
       replace(CB.INCIDENT_ATTRIBUTE_6,'00:00:00','') new_Promise_date,
       CB.INCIDENT_ATTRIBUTE_11 WAREHOUSE_ID
FROM   CS_INCIDENTS_ALL_B CB,
       CS_INCIDENT_STATUSES_VL CL
WHERE  CL.INCIDENT_STATUS_ID = CB.INCIDENT_STATUS_ID
AND    CL.INCIDENT_SUBTYPE = 'INC'
AND    CL.NAME IN ('Resolved Future Promise', 'Close Loop')
AND    CB.PROBLEM_CODE IN ('LATE DELIVERY', 'RETURN NOT PICKED UP')
AND    DECODE(CB.INCIDENT_ATTRIBUTE_12, NULL, CB.INCIDENT_ATTRIBUTE_1, CB.INCIDENT_ATTRIBUTE_12) IS NOT NULL
AND    EXISTS ( SELECT 'x'
           FROM CS_INCIDENT_TYPES_TL
           WHERE NAME = 'Stocked Products'
           AND INCIDENT_TYPE_ID  = CB.INCIDENT_TYPE_ID)
AND    NOT EXISTS ( select 'x' from cs_lookups
                 where lookup_type = 'XX_CS_CL_RESV_TYPES'
                 and enabled_flag = 'Y'
                 and end_date_active is null
                 and lookup_code = cb.resolution_code)
AND    EXISTS (select 'x'
                from hr_all_organization_units
                where  substr(type,1,2) = 'WH'
                and   attribute1  = cb.incident_attribute_11);

CS_REC                CS_CUR%ROWTYPE;
ln_group_id           number;
lx_return_status      varchar2(1);
lc_message            VARCHAR2(4000);
ld_promise_date       date;
ld_new_promise_date   date;
ld_act_promise_date   date;

BEGIN
  
  BEGIN
   OPEN CS_CUR;
   LOOP
   FETCH CS_CUR INTO CS_REC;
   EXIT WHEN CS_CUR%NOTFOUND;
   
    lc_message := 'Before update and Warehouse Id: '||cs_rec.warehouse_id ||' Promise Date '||ld_act_promise_date;
    fnd_file.put_line(fnd_file.log, lc_message);
    
    ld_promise_date     := to_date(cs_rec.promise_date,'mm/dd/yy');
    
    lc_message := 'Promise Date '||ld_promise_date;
    fnd_file.put_line(fnd_file.log, lc_message);
    
    ld_new_promise_date := to_date(cs_rec.new_promise_date, 'YYYY/MM/DD');
    
    lc_message := 'New Promise Date '||ld_new_promise_date;
    fnd_file.put_line(fnd_file.log, lc_message);
    
    IF ld_new_promise_date is null then
        ld_act_promise_date := ld_promise_date;
    else
        ld_act_promise_date := ld_new_promise_date;
    end if;
    
    lc_message := 'Actual Promise Date '||ld_act_promise_date;
    fnd_file.put_line(fnd_file.log, lc_message);
    
    IF ld_act_promise_date < (sysdate - 1) then
    
       begin
          UPDATE_SR (P_REQUEST_ID    => CS_REC.REQUEST_ID,
                     P_GROUP_OWNER_ID => LN_GROUP_ID,
                     P_WAREHOUSE_ID   => CS_REC.WAREHOUSE_ID,
                     X_RETURN_STATUS  => LX_RETURN_STATUS);
        exception
         when others then
           lx_return_status := 'F';
        end;
       
        lc_message := ' After update SR. Status '||lx_return_status;
        fnd_file.put_line(fnd_file.log, lc_message);
        
        -- DBMS_OUTPUT.PUT_LINE(lc_message);
     end if;

    IF (nvl(lx_return_status,'S') = 'F') then
       x_retcode := 2;
    END IF;

   END LOOP;
   CLOSE CS_CUR;
   
   commit;
  
   -- calling for other than missed requests.
     begin
       ROUTE_CL_SR;
     exception
      when others then
         x_retcode := 2;
         lx_return_status := 'F';
        lc_message := 'Error while calling Route_cl_sr '||sqlerrm;
        Log_Exception ( p_error_location     =>  'ROUTE_DC_QUEUE'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
      end;
      
      lc_message := ' AFTER ROUTE_CL_SR '||lx_return_status;
      fnd_file.put_line(fnd_file.log, lc_message); 
      
    /* 
      -- 
      begin
         delete from xx_com_error_log
         where module_name in ('CS','CSF','MPS','IES')
         and creation_date < sysdate - 10;
         
         commit;
      exception
        when others then
           null;
      end;
      */
  EXCEPTION
   WHEN OTHERS THEN
     x_retcode := 2;
      lc_message := 'Error while calling ROUTE_DC_QUEUE '|| sqlerrm;
      x_errbuf   := lc_message;
      Log_Exception ( p_error_location     =>  'ROUTE_DC_QUEUE'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
    END;

END ROUTE_DC_QUEUE;

/**************************************************
***************************************************/
PROCEDURE GET_EMAIL_RES (x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode  OUT  NOCOPY  NUMBER )
IS
lc_message    VARCHAR2(4000);
-- Start of changes for defect# 37051	
lc_result		NUMBER;
lc_message_out	VARCHAR2(4000);
lc_exception	EXCEPTION;
-- End of changes for defect# 37051

BEGIN
    BEGIN
	 -- Start of changes for defect# 37051	
      --XX_CS_MESG_PKG.READ_RESPONSE;
		XX_CS_MESG_PKG.READ_RESPONSE(lc_result, lc_message_out);
		--
		IF lc_result = 2
		THEN
			RAISE lc_exception;
		ELSIF lc_result = 1								--Added For Defect# 38994
		THEN											--Added For Defect# 38994
		  x_retcode:= 1;								--Added For Defect# 38994
		  x_errbuf := lc_message_out;					--Added For Defect# 38994
		END IF;	
	 -- End of changes for defect# 37051	
    EXCEPTION
	-- Start of changes for defect# 37051	
	WHEN lc_exception THEN
		x_retcode :=2;
		x_errbuf  := 'Unexpected error in XX_CS_MESG_PKG.READ_RESPONSE. '||lc_message_out;
	-- End of changes for defect# 37051	
     WHEN OTHERS THEN
      x_retcode := 2;
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XX_CS','XX_CS_0001_UNEXPECTED_ERR');
      lc_error_message :=  'In Procedure:XX_CS_CONC_PKG.GET_EMAIL_RES: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'GET_EMAIL_RES'
                     ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message
                    );
    END;
END GET_EMAIL_RES;

/************************************************************************
*************************************************************************/
PROCEDURE GET_CANCEL_ORD( x_errbuf     OUT  NOCOPY  VARCHAR2
                        , x_retcode    OUT  NOCOPY  NUMBER ) IS
/* Variable Declaration */
 TYPE ORDCurTyp          IS REF CURSOR;
  ord_cur                 ORDCurTyp;
  TYPE NTSCURTYP          IS REF CURSOR;
  nts_cur                 NTSCURTYP;
  stmt_str_ord            VARCHAR2(2000);
  stmt_str_nts            VARCHAR2(2000);
  ln_order_number          NUMBER;
  ln_sub_number            NUMBER;
  ln_incident_number       NUMBER;
  ln_incident_id           NUMBER;
  ln_object_version_number NUMBER;
  lc_AS400_notes           VARCHAR2(2000);
  lx_return_status         VARCHAR2(1);
  LX_INTERACTION_ID        NUMBER;
  LX_MSG_DATA              VARCHAR2(2000);
  lx_msg_index_out         NUMBER;
  lx_msg_count             NUMBER;
  lc_order_table           VARCHAR2(200);
  lc_notes_table           VARCHAR2(200);
  lv_db_link               VARCHAR2(100) := fnd_profile.value('XX_CS_AOPS_DBLINK_NAME');
 -- x_retcode                NUMBER;
  
  /*initialize Variables */ 
  ln_resp_appl_id          NUMBER :=  514;
  ln_resp_id               NUMBER := 21739;
  ln_user_id               NUMBER;
  
  /* initialize objects */
  lc_notes		             XX_CS_SR_NOTES_REC := XX_CS_SR_NOTES_REC(NULL,NULL,NULL,NULL);
  lc_ecom_site_key         XX_GLB_SITEKEY_REC_TYPE := XX_GLB_SITEKEY_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL);
 
BEGIN
  dbms_output.put_line('Beginning of API ');
  fnd_file.put_line (fnd_file.log, 'Beginning of API ' );
  IF lv_db_link IS NULL THEN
        fnd_file.put_line (fnd_file.log, 'Profile Option OD: CS AOPS DB Link Name is not SET.');
          x_retcode := 2;
          lx_return_status := 'F';
  END IF;
  
  BEGIN
    SELECT user_id INTO ln_user_id FROM fnd_user
     WHERE user_name = 'CS_ADMIN';
  EXCEPTION
    WHEN OTHERS THEN
      lx_return_status := 'F';
      x_retcode := 2;
      lx_msg_data      := 'Error while selecting userid '||sqlerrm;
      fnd_file.put_line (fnd_file.log, lx_msg_data );
   END;
  
  fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
  
  lc_order_table := 'racoondta.FCO100P@'||lv_db_link||' a';
  lc_notes_table := 'racoondta.FCO105P@'||lv_db_link;
  /* This query will extract all cancel orders from AS400 where incident is open in EBS */
  stmt_str_ord := 'SELECT a.fco100p_order_nbr order_number
                        , a.fco100p_order_sub sub_number 
                        , b.incident_number
                        , b.incident_id
                        , b.object_version_number
                    FROM  '|| lc_order_table ||
                       ' , cs_incidents_all_b b, cs_incident_statuses_vl c '||
                   ' WHERE  a.fco100p_order_status = '||''''||'T'||''''||
                   '   AND a.fco100p_order_nbr = to_number(nvl(substr(b.incident_attribute_1,1,9),-1)) '||
                   ' AND b.incident_status_id = c.incident_status_id '||
                   ' AND UPPER(c.name) = '||''''||'OPEN'||''''||
                   ' AND ROWNUM < 5 ';
                   
  dbms_output.put_line(stmt_str_ord); 
  fnd_file.put_line (fnd_file.log, stmt_str_ord );
  
  /* This query will extract cancel reason message on a given orders from AS400 and will pass it to SR notes field */
  stmt_str_nts := 'SELECT fco105p_order_comment1 || '||''''||' '||''''|| ' || fco105p_order_comment2|| '||''''||' '||''''|| ' || fco105p_order_comment3 notes '||
                   '  FROM '|| lc_notes_table ||
                   ' WHERE fco105p_order_nbr = :p_aops_order AND fco105p_order_sub = :p_aops_sub';
                   
   dbms_output.put_line(stmt_str_nts); 
   fnd_file.put_line (fnd_file.log, stmt_str_nts );
  
  /* Start of Order and SR extract cursor */ 
  OPEN ord_cur FOR stmt_str_ord; 
    LOOP
      FETCH ord_cur INTO ln_order_number, ln_sub_number,ln_incident_number,ln_incident_id,ln_object_version_number; 
        EXIT WHEN ord_cur%NOTFOUND; 
          dbms_output.put_line('Order_number : '||ln_order_number);
          dbms_output.put_line('sub_number : '||ln_sub_number);
          dbms_output.put_line('incident_number : '||ln_incident_number);
          dbms_output.put_line('incident_id : '||ln_incident_id);
          dbms_output.put_line('object_version_number : '||ln_object_version_number);
          fnd_file.put_line (fnd_file.log, 'Incident Number : '||ln_incident_number );
  
      /* Start of message extract from AS400 cursor */ 
      OPEN nts_cur FOR stmt_str_nts USING ln_order_number,ln_sub_number ;
        LOOP 
          FETCH nts_cur INTO lc_AS400_notes;
            EXIT WHEN nts_cur%NOTFOUND;
              --dbms_output.put_line('notes : '||lc_AS400_notes);
              lc_notes.NOTES			    := SUBSTR(lc_AS400_notes,1,2000);
              lc_notes.NOTE_DETAILS  := lc_AS400_notes;
              lc_notes.CREATION_DATE := SYSDATE;
              -- lc_notes.CREATED_BY    := FND_GLOBAL.USER_ID;
              lc_notes.CREATED_BY    := 29497;
              dbms_output.put_line('notes : '||lc_notes.NOTES);
              fnd_file.put_line (fnd_file.log, 'Reasion for Cancelation : '||lc_notes.NOTES );
              
              /* Calling XX_CS_SERVICEREQUEST_PKG to UPDATE SR */
              /* BEGIN
                   XX_CS_SERVICEREQUEST_PKG.Update_ServiceRequest
                                          ( p_sr_request_id    => ln_incident_id
                                          , p_sr_status_id     => 'Cancelled'
                                          , p_sr_notes         => lc_notes
                                          , p_ecom_site_key    => lc_ecom_site_key
                                          , p_user_id          => ln_user_id
                                          , x_return_status    => lx_return_status
                                          , x_msg_data         => lx_msg_data
                                          );
    
                  dbms_output.put_line('lx_return_status :'||lx_return_status);
            EXCEPTION
              WHEN OTHERS THEN
                lx_return_status := 'F';
                x_retcode := 2;
                lx_msg_data      := 'Error calling XX_CS_SERVICEREQUEST_PKG.Update_ServiceRequest '||sqlerrm;
                fnd_file.put_line (fnd_file.log, lx_msg_data );
                
            END;
            */
              dbms_output.put_line('Return Status : ' || lx_return_status);
              dbms_output.put_line('Interaction ID : ' || lx_interaction_id );
              fnd_file.put_line (fnd_file.log, 'Return Status : '||lx_return_status );

              IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                  --Display all the error messages
                  FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                    FND_MSG_PUB.Get
                               ( p_msg_index     => j
                               , p_encoded       => 'F'
                               , p_data          => lx_msg_data
                               , p_msg_index_out => lx_msg_index_out
                               );

                    DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                    fnd_file.put_line (fnd_file.log, lx_msg_data );
                  END LOOP;
                ELSE
                  --Only one error
                  FND_MSG_PUB.Get
                             ( p_msg_index     => 1
                             , p_encoded       => 'F'
                             , p_data          => lx_msg_data
                             , p_msg_index_out => lx_msg_index_out
                             );
                  DBMS_OUTPUT.PUT_LINE(lx_msg_data);
                  DBMS_OUTPUT.PUT_LINE(lx_msg_index_out);
                  fnd_file.put_line (fnd_file.log, lx_msg_data );
                END IF;
              END IF; 
        
        END LOOP;
      CLOSE nts_cur; -- Close message cursor
      
    END LOOP; 
  CLOSE ord_cur; -- Close order and SR cursor
  
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('NO DATA FOUND '||SQLERRM);
    lx_msg_data := 'No Data Found to update :' || SQLERRM; 
    fnd_file.put_line (fnd_file.log, lx_msg_data );

  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED :: '||SQLERRM);
    lx_msg_data := 'WHEN OTHERS RAISED :' || SQLERRM; 
    x_retcode := 2;
    fnd_file.put_line (fnd_file.log, lx_msg_data );
      
END GET_CANCEL_ORD;
/********************************************************************
*********************************************************************/
PROCEDURE TDS_PARTS_ITEMS( X_ERRBUF     OUT NOCOPY VARCHAR2
                          , X_RETCODE   OUT NOCOPY NUMBER
                          , P_SR_NUMBER IN VARCHAR2)
AS

BEGIN
          xx_cs_tds_parts_pkg.main_proc (
                                p_sr_number => p_sr_number
                              , x_return_status => lc_return_status
                              , x_return_message => lc_msg_data) ; 
                                           
      X_RETCODE := 0;
      X_ERRBUF  := lc_msg_data;
 
 EXCEPTION 
  WHEN OTHERS THEN
    lc_msg_data := 'WHEN OTHERS RAISED :' || SQLERRM; 
    x_retcode := 2;
    fnd_file.put_line (fnd_file.log, lc_msg_data );
                                
                                
END;    
/*********************************************************************
**********************************************************************/
PROCEDURE TDS_PARTS_OUTBOUND (X_ERRBUF  OUT NOCOPY VARCHAR2
                            , X_RETCODE OUT NOCOPY NUMBER
                            , P_SR_NUMBER IN VARCHAR2
                            , P_DOC_TYPE IN VARCHAR2)
AS

ln_incident_id    number;
BEGIN
     
    BEGIN
      select incident_id 
      into ln_incident_id
      from cs_incidents_all_b
      where incident_number = p_sr_number;
    EXCEPTION
      WHEN OTHERS THEN
          lc_msg_data := 'Error while selecing incident_id :' || SQLERRM; 
          fnd_file.put_line (fnd_file.log, lc_msg_data );
          
     END;
     
     IF ln_incident_id is not null then
      XX_CS_TDS_PARTS_VEN_PKG.PART_OUTBOUND (p_incident_number   => p_sr_number, 
                                          p_incident_id		    => ln_incident_id,
                                          p_doc_type          => p_doc_type,
                                          p_doc_number        => p_sr_number,
                                          x_return_status     => lc_return_status,
                                          x_return_msg        => lc_msg_data);
                                          
        X_RETCODE := 0;
        X_ERRBUF  := lc_msg_data;
     end if;
 EXCEPTION 
  WHEN OTHERS THEN
    lc_msg_data := 'WHEN OTHERS RAISED :' || SQLERRM; 
    x_retcode := 2;
    fnd_file.put_line (fnd_file.log, lc_msg_data );
            
END; 
/*************************************************************************/

PROCEDURE SUBSCRIPTION_REQ ( x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode    OUT  NOCOPY  NUMBER ) 
AS

CURSOR C1 IS
select a.incident_id, a.object_version_number
from cs_incidents_all_b a,
     cs_incident_types_vl b
where b.incident_type_id = a.incident_type_id
and   b.name in ('TDS-Subscription', 'TDS-SMB Subscription')
and   a.problem_code = 'TDS-SERVICES'
and   a.incident_status_id not in (2, 9100)
and   b.source_lang = 'US'
and   b.incident_subtype = 'INC'
and   a.external_attribute_14 is not null
and   b.attribute7 = 'Support.com';

c1_rec  c1%rowtype;

lc_status             varchar2(100);
ln_status_id          number;
ln_user_id            number := 26176;
ln_resp_appl_id       number := 514;
ln_resp_id            number := 21739;
x_return_status       varchar2(25);
lc_message            varchar2(250);
lx_interaction_id     NUMBER;
ln_obj_ver            number;
lx_msg_count          NUMBER;
lx_msg_data           VARCHAR2(2000);

BEGIN

   select user_id
   into ln_user_id
   from fnd_user
   where user_name = 'CS_ADMIN';
   
   fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
   
   open c1;
   loop
   fetch c1 into c1_rec;
   exit when c1%notfound;
   
      ln_status_id := 2;
        
  -- update SR status
          Begin
              -- DBMS_OUTPUT.PUT_LINE('Status '||ln_status_id||' '||lc_sr_status);
                 CS_SERVICEREQUEST_PUB.Update_Status
                  (p_api_version	=> 2.0,
                  p_init_msg_list	=> FND_API.G_TRUE,
                  p_commit		=> FND_API.G_FALSE,
                  x_return_status	=> x_return_status,
                  x_msg_count	        => lx_msg_count,
                  x_msg_data		=> lx_msg_data,
                  p_resp_appl_id	=> ln_resp_appl_id,
                  p_resp_id		=> ln_resp_id,
                  p_user_id		=> ln_user_id,
                  p_login_id		=> NULL,
                  p_request_id		=> c1_rec.incident_id,
                  p_request_number	=> null,
                  p_object_version_number => c1_rec.object_version_number,
                  p_status_id	 	=> ln_status_id,
                  p_status		=> null,
                  p_closed_date		=> SYSDATE,
                  p_audit_comments	=> NULL,
                  p_called_by_workflow	=> NULL,
                  p_workflow_process_id	=> NULL,
                  p_comments		=> NULL,
                  p_public_comment_flag	=> NULL,
                  x_interaction_id	=> lx_interaction_id);
                  
               
        commit;
      END;
      
      end loop;
      close c1;
      
      X_RETCODE := 0;
      
    exception
      when others then
          lc_msg_data := 'WHEN OTHERS RAISED :' || SQLERRM; 
          x_retcode := 2;
          fnd_file.put_line (fnd_file.log, lc_msg_data );

END SUBSCRIPTION_REQ;
/******************************************************************************/
PROCEDURE SMB_UPDATE ( x_errbuf     OUT  NOCOPY  VARCHAR2
                      , x_retcode    OUT  NOCOPY  NUMBER 
                      , p_request_number IN varchar2
                      , p_cust_name IN VARCHAR2
                      , p_action    IN VARCHAR2
                      , p_skus      IN VARCHAR2
                      , p_units     IN number) 
AS

BEGIN

   XX_CS_MESG_PKG.UPDATE_SMB_QTY (P_REQUEST_NUMBER => P_REQUEST_NUMBER,
                          P_CUST_NAME      => P_CUST_NAME,
                          P_ACTION         => P_ACTION,
                          P_SKUs           => P_SKUs,
                          P_UNITS          => P_UNITS);
                          
END;
/*****************************************************************************/

END XX_CS_CONC_PKG;
/