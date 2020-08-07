create or replace
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
-- |                                                                                         |
-- +=========================================================================================+
gc_conc_prg_id                      NUMBER   := apps.fnd_global.conc_request_id;
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
     ,p_program_type            => 'E2007_CRF_CloseLoop_Mobilecast_Deliveries'
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
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);

begin

    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

    lr_service_request_rec.owner_id        := null;
    lr_service_request_rec.owner_group_id  := p_group_owner_id;
    lr_service_request_rec.group_type      := 'RS_GROUP';
    lr_service_request_rec.summary         := 'Close Loop';

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
    /*****************************************************************
     -- Get Status Id
     *****************************************************************/
     BEGIN
          SELECT incident_status_id 
          INTO  lr_service_request_rec.status_id
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = 'Waiting';
        EXCEPTION
          WHEN OTHERS THEN
            lr_service_request_rec.status_id := 1;
        END;
   /*************************************************************************
     -- Add notes 
    ************************************************************************/
    
      lt_notes_table(1).note        := 'Close Loop - Delivery not completed' ;
      lt_notes_table(1).note_detail := 'Delivery message not received';
      lt_notes_table(1).note_type   := 'GENERAL';

   /**************************************************************************
       -- Update SR
    *************************************************************************/
    
    lc_message := 'Before UPDATE SR '||lr_service_request_rec.status_id;
    fnd_file.put_line(fnd_file.log, lc_message);
    
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
      lc_message := 'FND  '||lx_return_status ||' '||lx_msg_data;
       fnd_file.put_line(fnd_file.log, lc_message);
   END IF; 
   x_return_status := lx_return_status;
   
exception
   when others then
      x_return_status := 'F';

END UPDATE_SR;   

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
SELECT INCIDENT_ID REQUEST_ID, 
       DECODE(INCIDENT_ATTRIBUTE_12, NULL, INCIDENT_ATTRIBUTE_2, to_char(INCIDENT_ATTRIBUTE_6, 'MM/DD/YYYY')) Promise_date,
       INCIDENT_ATTRIBUTE_11 WAREHOUSE_ID
FROM CS_INCIDENTS_ALL_B
WHERE INCIDENT_STATUS_ID =  
(SELECT INCIDENT_STATUS_ID
FROM CS_INCIDENT_STATUSES_VL
WHERE INCIDENT_SUBTYPE = 'INC'
AND NAME LIKE 'Resolved')
AND PROBLEM_CODE IN ('LATE DELIVERY', 'RETURN NOT PICKED UP')
AND EXISTS ( SELECT 'x' 
           FROM CS_INCIDENT_TYPES_TL 
           WHERE NAME = 'Stocked Products'
           AND INCIDENT_TYPE_ID  = CS_INCIDENTS_ALL_B.INCIDENT_TYPE_ID)
AND DECODE(INCIDENT_ATTRIBUTE_12, NULL, INCIDENT_ATTRIBUTE_1, INCIDENT_ATTRIBUTE_12) IS NOT NULL;

CS_REC                CS_CUR%ROWTYPE;
ln_group_id           number;
lx_return_status      varchar2(1);
lc_message            VARCHAR2(4000);

BEGIN

  BEGIN
    SELECT GROUP_ID
    INTO LN_GROUP_ID
    FROM JTF_RS_GROUPS_TL  
    WHERE GROUP_NAME = 'Warehouse';
  EXCEPTION
    WHEN OTHERS THEN
      LN_GROUP_ID := NULL;
  END;
  
  BEGIN
   OPEN CS_CUR;
   LOOP
   FETCH CS_CUR INTO CS_REC;
   EXIT WHEN CS_CUR%NOTFOUND;
   
    lc_message := 'Before Calling get child group '||cs_rec.warehouse_id||''||ln_group_id;
    fnd_file.put_line(fnd_file.log, lc_message);
    
    IF TO_DATE(CS_REC.PROMISE_DATE, 'MM/DD/YYYY') < SYSDATE THEN 
      --Transfer SR to warehouse queue
      IF CS_REC.WAREHOUSE_ID IS NOT NULL THEN
        XX_CS_RESOURCES_PKG.get_child_group 
                          (x_group_id => ln_group_id,
                           p_warehouse_id  => cs_rec.warehouse_id,
                           x_return_status => lx_return_status);
      END IF;
    end if;
    
    lc_message := ' child group '||ln_group_id|| ' Status '||lx_return_status;
    fnd_file.put_line(fnd_file.log, lc_message);
                     
    IF (nvl(lx_return_status,'S') = 'S') then
       begin
          UPDATE_SR (P_REQUEST_ID    => CS_REC.REQUEST_ID,
                     P_GROUP_OWNER_ID => LN_GROUP_ID,
                     X_RETURN_STATUS  => LX_RETURN_STATUS);
        exception
         when others then
           lx_return_status := 'F';
        end;
    end if;
      
     lc_message := ' After update SR. Status '||lx_return_status;
     fnd_file.put_line(fnd_file.log, lc_message);  
     
    IF (nvl(lx_return_status,'S') = 'F') then 
       x_retcode := 2;
    END IF;
   
   END LOOP;
   CLOSE CS_CUR;
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

BEGIN
    BEGIN
      XX_CS_MESG_PKG.READ_RESPONSE;
    EXCEPTION
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
END;
/
SHOW ERRORS;
EXIT;