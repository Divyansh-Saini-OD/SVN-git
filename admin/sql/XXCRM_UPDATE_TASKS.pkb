SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XXCRM_UPDATE_TASKS package body
PROMPT

CREATE OR REPLACE
PACKAGE BODY XXCRM_UPDATE_TASKS AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXCRM_UPDATE_TASKS                                                        |
-- | Description : One Off Package to Mass Update specific Task Types and Statuses           |
-- |               (QC 2297,1790)                                                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        21-Sep-20009      Sreekanth Rao       Initial Version                         |
-- +=========================================================================================+


 PROCEDURE Log_Exception 
  -- +=============================================================================================+
  -- | Name             : Log_Exception                                                            |
  -- | Description      : This procedure uses error handling framework to log errors               |
  -- |                                                                                             |
  -- +=============================================================================================+
                         (p_error_location          IN  VARCHAR2
                         ,p_error_message_code      IN  VARCHAR2
                         ,p_error_msg               IN  VARCHAR2
                         ,p_error_message_severity  IN  VARCHAR2
                         ,p_application_name        IN  VARCHAR2
                         ,p_module_name             IN  VARCHAR2
                         ,p_program_type            IN  VARCHAR2
                         ,p_program_name            IN  VARCHAR2
                         )  IS 

 --Local Variables
   ln_login        PLS_INTEGER           := FND_GLOBAL.Login_Id;
   ln_user_id      PLS_INTEGER           := FND_GLOBAL.User_Id;
   ln_request_id   PLS_INTEGER           := FND_GLOBAL.Conc_Request_Id;

 BEGIN

   XX_COM_ERROR_LOG_PUB.log_error_crm
      (
       p_return_code             => FND_API.G_RET_STS_ERROR
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => p_program_type
      ,p_program_name            => p_program_name
      ,p_module_name             => 'XXTASKS'
      ,p_error_location          => p_error_location
      ,p_error_message_code      => p_error_message_code
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => p_error_message_severity
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      ,p_program_id              => ln_request_id
      );

 EXCEPTION  WHEN OTHERS THEN
       gc_error_message := 'Unexpected error in  XXCRM_UPDATE_TASKS.Log_Exception - ' ||SQLERRM;
       APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);
 END Log_Exception;


PROCEDURE P_Update_Task
   -- +=============================================================================================+
   -- | Name             : P_Update_Task_Status                                                     |
   -- | Description      : This procedure is used to update task status and Type                    |
   -- +=============================================================================================+
                          (P_Task_ID              IN  NUMBER,
                           P_New_Task_Type_ID     IN  NUMBER,                          
                           P_New_Task_Status_ID   IN  NUMBER,
                           X_Ret_Code             OUT NOCOPY NUMBER,
                           X_Error_Msg            OUT NOCOPY VARCHAR2) IS

 x_return_status             VARCHAR2(10);
 x_msg_count                 NUMBER;
 x_msg_data                  VARCHAR2(4000);
 l_new_task_status_id        NUMBER; 
 l_new_task_type_id          NUMBER;  
 l_task_object_version       NUMBER;

BEGIN

-- Validate Task Status ID

  IF P_New_Task_Status_ID IS NOT NULL
  THEN
    BEGIN
     SELECT
        task_status_id
     INTO
        l_new_task_status_id
     FROM
        apps.jtf_task_statuses_vl
     WHERE
          task_status_id = P_New_Task_Status_ID
      AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);

    EXCEPTION WHEN OTHERS THEN
      l_new_task_status_id := FND_API.g_miss_num;
      X_Ret_Code := 2;
      X_Error_Msg := 'Invalid New Task Status';
    END;
  ELSE  
     l_new_task_status_id := FND_API.g_miss_num;
  END IF;

-- Validate Task Type ID
  IF P_New_Task_Type_ID IS NOT NULL
  THEN
    BEGIN
     SELECT
        task_type_id
     INTO
        l_new_task_type_id
     FROM
        apps.jtf_task_types_vl
     WHERE
          task_type_id = P_New_Task_Type_ID
      AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);

    EXCEPTION WHEN OTHERS THEN
      l_new_task_type_id := FND_API.g_miss_num;
      X_Ret_Code := 2;
      X_Error_Msg := 'Invalid New Task Type';
    END;
  ELSE  
      l_new_task_type_id := FND_API.g_miss_num;
  END IF;

  SELECT 
     object_version_number
  INTO
     l_task_object_version
   FROM 
     apps.jtf_tasks_vl
  WHERE task_id = P_Task_ID;


--Call the Tasks Update API
  JTF_TASKS_PUB.Update_Task
     (
        p_api_version               =>     1.0,
        p_init_msg_list             =>     fnd_api.g_false,
        p_commit                    =>     fnd_api.g_false,
        p_object_version_number     =>     l_task_object_version,
        p_task_id                   =>     P_Task_ID,
        p_task_number               =>     fnd_api.g_miss_char,
        p_task_name                 =>     fnd_api.g_miss_char,
        p_task_type_name            =>     fnd_api.g_miss_char,
        p_task_type_id              =>     nvl(l_new_task_type_id,fnd_api.g_miss_num),
        p_description               =>     fnd_api.g_miss_char,
        p_task_status_name          =>     fnd_api.g_miss_char,
        p_task_status_id            =>     nvl(l_new_task_status_id,fnd_api.g_miss_num),
        p_task_priority_name        =>     fnd_api.g_miss_char,
        p_task_priority_id          =>     fnd_api.g_miss_num,
        p_owner_type_name           =>     fnd_api.g_miss_char,
        p_owner_type_code           =>     fnd_api.g_miss_char,
        p_owner_id                  =>     fnd_api.g_miss_num,
        p_owner_territory_id        =>     fnd_api.g_miss_num,
        p_assigned_by_name          =>     fnd_api.g_miss_char,
        p_assigned_by_id            =>     fnd_api.g_miss_num,
        p_customer_number           =>     fnd_api.g_miss_char,
        p_customer_id               =>     fnd_api.g_miss_num,
        p_cust_account_number       =>     fnd_api.g_miss_char,
        p_cust_account_id           =>     fnd_api.g_miss_num,
        p_address_id                =>     fnd_api.g_miss_num,
        p_address_number            =>     fnd_api.g_miss_char,
        p_planned_start_date        =>     fnd_api.g_miss_date,
        p_planned_end_date          =>     fnd_api.g_miss_date,
        p_scheduled_start_date      =>     fnd_api.g_miss_date,
        p_scheduled_end_date        =>     fnd_api.g_miss_date,
        p_actual_start_date         =>     fnd_api.g_miss_date,
        p_actual_end_date           =>     fnd_api.g_miss_date,
        p_timezone_id               =>     fnd_api.g_miss_num,
        p_timezone_name             =>     fnd_api.g_miss_char,
        p_source_object_type_code   =>     fnd_api.g_miss_char,
        p_source_object_id          =>     fnd_api.g_miss_num,
        p_source_object_name        =>     fnd_api.g_miss_char,
        p_duration                  =>     fnd_api.g_miss_num,
        p_duration_uom              =>     fnd_api.g_miss_char,
        p_planned_effort            =>     fnd_api.g_miss_num,
        p_planned_effort_uom        =>     fnd_api.g_miss_char,
        p_actual_effort             =>     fnd_api.g_miss_num,
        p_actual_effort_uom         =>     fnd_api.g_miss_char,
        p_percentage_complete       =>     fnd_api.g_miss_num,
        p_reason_code               =>     fnd_api.g_miss_char,
        p_private_flag              =>     fnd_api.g_miss_char,
        p_publish_flag              =>     fnd_api.g_miss_char,
        p_restrict_closure_flag     =>     fnd_api.g_miss_char,
        p_multi_booked_flag         =>     fnd_api.g_miss_char,
        p_milestone_flag            =>     fnd_api.g_miss_char,
        p_holiday_flag              =>     fnd_api.g_miss_char,
        p_billable_flag             =>     fnd_api.g_miss_char,
        p_bound_mode_code           =>     fnd_api.g_miss_char,
        p_soft_bound_flag           =>     fnd_api.g_miss_char,
        p_workflow_process_id       =>     fnd_api.g_miss_num,
        p_notification_flag         =>     fnd_api.g_miss_char,
        p_notification_period       =>     fnd_api.g_miss_num,
        p_notification_period_uom   =>     fnd_api.g_miss_char,
        p_alarm_start               =>     fnd_api.g_miss_num,
        p_alarm_start_uom           =>     fnd_api.g_miss_char,
        p_alarm_on                  =>     fnd_api.g_miss_char,
        p_alarm_count               =>     fnd_api.g_miss_num,
        p_alarm_fired_count         =>     fnd_api.g_miss_num,
        p_alarm_interval            =>     fnd_api.g_miss_num,
        p_alarm_interval_uom        =>     fnd_api.g_miss_char,
        p_palm_flag                 =>     fnd_api.g_miss_char,
        p_wince_flag                =>     fnd_api.g_miss_char,
        p_laptop_flag               =>     fnd_api.g_miss_char,
        p_device1_flag              =>     fnd_api.g_miss_char,
        p_device2_flag              =>     fnd_api.g_miss_char,
        p_device3_flag              =>     fnd_api.g_miss_char,
        p_costs                     =>     fnd_api.g_miss_num,
        p_currency_code             =>     fnd_api.g_miss_char,
        p_escalation_level          =>     fnd_api.g_miss_char,
        p_attribute1                =>     jtf_task_utl.g_miss_char,
        p_attribute2                =>     jtf_task_utl.g_miss_char,
        p_attribute3                =>     jtf_task_utl.g_miss_char,
        p_attribute4                =>     jtf_task_utl.g_miss_char,
        p_attribute5                =>     jtf_task_utl.g_miss_char,
        p_attribute6                =>     jtf_task_utl.g_miss_char,
        p_attribute7                =>     jtf_task_utl.g_miss_char,
        p_attribute8                =>     jtf_task_utl.g_miss_char,
        p_attribute9                =>     jtf_task_utl.g_miss_char,
        p_attribute10               =>     jtf_task_utl.g_miss_char,
        p_attribute11               =>     jtf_task_utl.g_miss_char,
        p_attribute12               =>     jtf_task_utl.g_miss_char,
        p_attribute13               =>     jtf_task_utl.g_miss_char,
        p_attribute14               =>     jtf_task_utl.g_miss_char,
        p_attribute15               =>     jtf_task_utl.g_miss_char,
        p_attribute_category        =>     jtf_task_utl.g_miss_char,
        p_date_selected             =>     jtf_task_utl.g_miss_char,
        p_category_id               =>     jtf_task_utl.g_miss_number,
        p_show_on_calendar          =>     jtf_task_utl.g_miss_char,
        p_owner_status_id           =>     jtf_task_utl.g_miss_number,
        p_parent_task_id            =>     jtf_task_utl.g_miss_number,
        p_parent_task_number        =>     jtf_task_utl.g_miss_char,
        p_enable_workflow           =>     NULL,
        p_abort_workflow            =>     NULL,
        p_task_split_flag           =>     NULL,
        p_child_position            =>     jtf_task_utl.g_miss_char,
        p_child_sequence_num        =>     jtf_task_utl.g_miss_number,
        x_return_status             =>     x_return_status,
        x_msg_count                 =>     x_msg_count,
        x_msg_data                  =>     x_msg_data
      );

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
            
              X_Ret_Code  := 2;
              X_Error_Msg := 'Error in XXSCS_CONT_STRATEGY_PKG.P_Update_Task for Task ID :'
                                                                                           ||P_Task_ID
                                                                                           ||'.'
                                                                                           ||x_msg_data;

        ELSE
             X_Ret_Code := 0;
             X_Error_Msg := 'Task Updated';
--             COMMIT;
        END IF;
  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code  := 2;
              X_Error_Msg := 'Error in XXSCS_CONT_STRATEGY_PKG.P_Update_Task for Task ID :'
                                                                                           ||P_Task_ID
                                                                                           ||'.'
                                                                                           ||sqlerrm;

END P_Update_Task;


PROCEDURE P_Mass_Update_Tasks
   -- +=============================================================================================+
   -- | Name             : P_Mass_Update_Tasks                                                      |
   -- | Description      : This procedure is used to mass update task Types or Statuses             |
   -- +=============================================================================================+
                          ( x_errbuf         OUT NOCOPY VARCHAR2,
                            x_retcode        OUT NOCOPY NUMBER,
                            P_Update_column  IN VARCHAR2,                            
                            P_Commit         IN VARCHAR2) IS

 l_error_msg                 VARCHAR2(4000);
 l_ret_code                  NUMBER; 

CURSOR C_TASKS_TO_BE_UPDTD_FOR_TYPES IS
SELECT DISTINCT
    TSK.task_id,
    TSK.task_name,
    TSK.description,    
    TSK.source_object_type_code,
    TSK.task_type_id,
    TSKTYPE.name tasktype,
    NEWTSKTYPE.task_type_id new_task_type_id,
    NEWTSKTYPE.name new_task_type,
    JTFRE.source_name Owner,
    JTFRE.source_job_title owner_job_code,
    TSK.last_update_date
from
  apps.jtf_tasks_vl          TSK,
  apps.jtf_rs_role_relations JRRR, 
  apps.jtf_rs_roles_vl       JRV,
  apps.jtf_rs_resource_extns_vl JTFRE,
  apps.jtf_task_types_vl     TSKTYPE,
  apps.jtf_task_types_vl     NEWTSKTYPE,  
  apps.fnd_user              FNDU
where 
  TSK.owner_id = JTFRE.resource_id and
  JTFRE.resource_id = JRRR.role_resource_id and
  JRRR.role_resource_type = 'RS_INDIVIDUAL' and
  JRRR.role_id = JRV.role_id and
  JRV.role_type_code = 'SALES' and
  TSK.task_type_id = TSKTYPE.task_type_id and
  TSK.created_by = FNDU.user_id and
  TSK.entity = 'TASK' and
  TSK.source_object_type_code IN ('PARTY','OPPORTUNITY','LEAD','OD_PARTY_SITE','TASK') and 
  TSKTYPE.name not in ('Email','Other','Call','In Person Visit','Mail')  and
    decode(TSKTYPE.name,
                'Analyze'                  ,'Call',
                'Appointment'              ,'In Person Visit',
                'Approval'                 ,'Call',
                'Bids'                     ,'Call',
                'Callback'                 ,'Call',                
                'Email Notification'       ,'Email',
                'Business Penetration'     ,'Call',
                'Business Review'          ,'In Person Visit',
                'Cold Call'                ,'In Person Visit',
                'Customer Roll Out'        ,'In Person Visit',
                'Email Follow-up'          ,'Call',
                'Follow up action'         ,'Call',
                'Follow Up Call'           ,'Call',
                'General'                  ,'Call',
                'Joint Sales Call'         ,'In Person Visit',
                'Lunch'                    ,'In Person Visit',
                'Marketing Blitz'          ,'In Person Visit',
                'Meeting'                 ,'In Person Visit',
                'New Business'            ,'Call',
                'OD Acct. Mgr. Follow Up' ,'In Person Visit',
                'OD Follow Up'            ,'In Person Visit',
                'OD Vendor Follow Up'     ,'In Person Visit',
                'Service Resolution'      ,'Call',
                'Telephone'               ,'Call',
                 TSKTYPE.name) = NEWTSKTYPE.name;
                 
CURSOR C_TASKS_TO_BE_UPDTD_FOR_STATUS IS
SELECT DISTINCT 
      a.task_id,
      a.task_name,
      a.source_object_type_code,
      a.source_object_id,
      g.name task_status,
      a.task_status_id,
      NEW_TSK_STATUS.task_status_id new_task_status_id,
      NEW_TSK_STATUS.name new_task_status,
      d.source_name Owner,
      d.source_job_title owner_job_code,
      a.last_update_date
FROM
  apps.jtf_tasks_vl a,
  apps.jtf_rs_role_relations b, 
  apps.jtf_rs_roles_b c,
  apps.jtf_rs_resource_extns_vl d,
  apps.jtf_task_statuses_tl g,
  apps.jtf_task_statuses_tl NEW_TSK_STATUS,  
  apps.fnd_user h
where 
  a.owner_id = d.resource_id and
  d.resource_id = b.role_resource_id and
  b.role_resource_type = 'RS_INDIVIDUAL' and
  b.role_id = c.role_id and
  c.role_type_code = 'SALES' and
  a.task_status_id = g.task_status_id and
  g.name in ('Close','Not Started','Open','New') and
  a.created_by = h.user_id and
  a.entity = 'TASK' and
  a.source_object_type_code IN ('PARTY','OPPORTUNITY','LEAD','OD_PARTY_SITE','TASK') and
  decode(g.name,
                'New'                      ,'In Progress',
                'Open'                     ,'In Progress',
                'Not Started'              ,'In Progress',
                'Close'                    ,'Completed',
                 g.name)= NEW_TSK_STATUS.name;
BEGIN

  IF P_Update_column = 'TASK_TYPE' THEN

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',10,'-')                           
                           ||rpad('-',20,'-')
                           ||rpad('-',10,'-') 
                           ||rpad('-',20,'-')
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                                 rpad('Task ID',10,' ') 
                           ||'|'||rpad('Task Name',50,' ')
                           ||'|'||rpad('Source Object Type',15,' ')
                           ||'|'||rpad('TaskTypeID',10,' ')                           
                           ||'|'||rpad('Task Type',20,' ')
                           ||'|'||rpad('NewTTypeID',10,' ') 
                           ||'|'||rpad('New Task Type',20,' ')
                           ||'|'||rpad('Owner',60,' ')
                           ||'|'||rpad('Owner Job',100,' ')
                           ||'|'||rpad('Last Update Date',15,' ')
                           ||'|'||rpad('Error Message',200,' '));
     
    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,                           
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',10,'-')                           
                           ||rpad('-',20,'-')
                           ||rpad('-',10,'-') 
                           ||rpad('-',20,'-')
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));
      
   FOR i in C_TASKS_TO_BE_UPDTD_FOR_TYPES
   LOOP

         IF P_Commit = 'Y' THEN
             P_Update_Task
                          (P_Task_ID              => i.task_id,
                           P_New_Task_Type_ID     => i.new_task_type_id,
                           P_New_Task_Status_ID   => NULL,
                           X_Ret_Code             => l_ret_code,
                           X_Error_Msg            => l_error_msg);
        END IF;                   

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                                  rpad(substr(nvl(to_char(i.task_id),' '),1,10),10,' ') 
                           ||'|'||rpad(substr(nvl(to_char(i.task_name),' '),1,50),50,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.source_object_type_code),' '),1,15),15,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.task_type_id),' '),1,10),10,' ')                           
                           ||'|'||rpad(substr(nvl(to_char(i.tasktype),' '),1,20),20,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.new_task_type_id),' '),1,10),10,' ') 
                           ||'|'||rpad(substr(nvl(to_char(i.new_task_type),' '),1,20),20,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.Owner),' '),1,60),60,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.owner_job_code),' '),1,100),100,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.last_update_date),' '),1,15),15,' ')
                           ||'|'||rpad(substr(nvl(to_char(l_error_msg),' '),1,200),200,' '));

   END LOOP;

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,                           
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',10,'-')                           
                           ||rpad('-',20,'-')
                           ||rpad('-',10,'-') 
                           ||rpad('-',20,'-')
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));

  ELSIF P_Update_column = 'TASK_STATUS' THEN
     
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')                           
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                                 rpad('Task ID',10,' ') 
                           ||'|'||rpad('Task Name',50,' ')
                           ||'|'||rpad('Source Object Type',15,' ')
                           ||'|'||rpad('TskStatusID',11,' ')
                           ||'|'||rpad('Task Status',15,' ')
                           ||'|'||rpad('NewStatusID',11,' ')
                           ||'|'||rpad('New Task Status',15,' ')                           
                           ||'|'||rpad('Owner',60,' ')
                           ||'|'||rpad('Owner Job',100,' ')
                           ||'|'||rpad('Last Update Date',15,' ')
                           ||'|'||rpad('Error Message',200,' '));
     
    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,                           
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')                           
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));
      
   FOR i in C_TASKS_TO_BE_UPDTD_FOR_STATUS
   LOOP

         IF P_Commit = 'Y' THEN
             P_Update_Task
                          (P_Task_ID              => i.task_id,
                           P_New_Task_Type_ID     => NULL,
                           P_New_Task_Status_ID   => i.new_task_status_id,
                           X_Ret_Code             => l_ret_code,
                           X_Error_Msg            => l_error_msg);
        END IF;                   

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,
                                  rpad(substr(nvl(to_char(i.task_id),' '),1,10),10,' ') 
                           ||'|'||rpad(substr(nvl(to_char(i.task_name),' '),1,50),50,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.source_object_type_code),' '),1,15),15,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.task_status_id),' '),1,11),11,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.task_status),' '),1,15),15,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.new_task_status_id),' '),1,11),11,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.new_task_status),' '),1,15),15,' ')                           
                           ||'|'||rpad(substr(nvl(to_char(i.Owner),' '),1,60),60,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.owner_job_code),' '),1,100),100,' ')
                           ||'|'||rpad(substr(nvl(to_char(i.last_update_date),' '),1,15),15,' ')
                           ||'|'||rpad(substr(nvl(to_char(l_error_msg),' '),1,200),200,' '));

   END LOOP;

    APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT,                           
                             rpad('-',10,'-') 
                           ||rpad('-',50,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',11,'-')
                           ||rpad('-',15,'-')                           
                           ||rpad('-',60,'-')
                           ||rpad('-',100,'-')
                           ||rpad('-',15,'-')
                           ||rpad('-',200,'-'));
     
     END IF;-- P_Update_column = 'TASK_TYPE' THEN;
  EXCEPTION WHEN OTHERS THEN
     x_retcode := 2;
     x_errbuf  := 'Unexpected error in XXCRM_UPDATE_TASKS.P_Mass_Update_Tasks - ' ||SQLERRM;
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,x_errbuf);

     Log_Exception
                            (p_error_location          => 'XXCRM_UPDATE_TASKS'
                            ,p_error_message_code      => 'XXTASKUPDTERR'
                            ,p_error_msg               =>  x_errbuf
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXTASKS'
                            ,p_program_type            => 'QC2297'
                            ,p_program_name            => 'XXCRM_UPDATE_TASKS.P_Mass_Update_Tasks'
                            );

END P_Mass_Update_Tasks;

END XXCRM_UPDATE_TASKS;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
