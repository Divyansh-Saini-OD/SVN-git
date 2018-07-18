create or replace
PACKAGE XX_CS_SR_TASK AS

 PROCEDURE CREATE_PROCEDURE (P_INCIDENT_ID IN NUMBER,
                            X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                            X_MSG_DATA IN OUT NOCOPY VARCHAR2);
                            
 PROCEDURE Update_Task ( P_REQUEST_ID    IN  NUMBER,
                        P_VENDOR        IN  VARCHAR2,
                        P_SERVICE_LINK  IN VARCHAR2,
                        P_STATUS        IN  NUMBER,
                        P_NOTES_TBL     IN  jtf_tasks_pub.task_notes_tbl,
                        X_RETURN_STATUS OUT NOCOPY VARCHAR2,
                        X_MSG_DATA      OUT NOCOPY VARCHAR2);
                        
 PROCEDURE Update_TDS_Task ( P_REQUEST_ID    IN  NUMBER,
                            P_TASK_ID       IN  NUMBER,
                            P_STATUS        IN  NUMBER,
                            P_VENDOR        IN  VARCHAR2,
                            P_NOTES_TBL     IN  jtf_tasks_pub.task_notes_tbl,
                            X_RETURN_STATUS OUT NOCOPY VARCHAR2,
                            X_MSG_DATA      OUT NOCOPY VARCHAR2);

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
  , p_owner_id          IN NUMBER
  , p_attribute_1	IN VARCHAR2
  , p_attribute_2	IN VARCHAR2
  , p_attribute_3	IN VARCHAR2
  , p_attribute_4	IN VARCHAR2
  , p_attribute_5	IN VARCHAR2
  , p_attribute_6	IN VARCHAR2
  , p_attribute_7	IN VARCHAR2
  , p_attribute_8	IN VARCHAR2
  , p_attribute_9	IN VARCHAR2
  , p_attribute_10	IN VARCHAR2
  , p_attribute_11	IN VARCHAR2
  , p_attribute_12	IN VARCHAR2
  , p_attribute_13	IN VARCHAR2
  , p_attribute_14	IN VARCHAR2
  , p_attribute_15	IN VARCHAR2
  , p_context		IN VARCHAR2
  , p_assignee_id        IN NUMBER
  , p_template_id        IN NUMBER);

END XX_CS_SR_TASK;
/