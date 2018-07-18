create or replace
PACKAGE      XX_CS_MPS_VALIDATION_PKG AS

-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_VALIDATION_PKG.pks                                                         |
-- | Description  : This package contains Monitoring systems feed procedures                      |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        31-AUG-2012   Raj Jagarlamudi    Initial version                                   |
-- |2.0        04-JUN-2014   Arun Gannarapu     Added p_Debug_flag to main procedure              |
-- +==============================================================================================+

   PROCEDURE SUPPLIES_REQ (P_DEVICE_ID       IN VARCHAR2,
                          P_GROUP_ID        IN VARCHAR2,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2);

  PROCEDURE METER_REQ (P_DEVICE_ID         IN VARCHAR2,
                          P_GROUP_ID        IN VARCHAR2,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      in OUT varchar2);

  procedure NO_FEED_DEVICES( X_RETURN_STATUS   in OUT varchar2,
                             X_RETURN_MSG      in OUT varchar2);

  PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                        X_RETCODE         OUT  NOCOPY  NUMBER,
                        P_TYPE            IN VARCHAR2,
                        P_DEVICE_ID        IN VARCHAR2,
                        P_GROUP_ID        IN VARCHAR2,
                        P_DEBUG_FLAG      IN VARCHAR2);

    PROCEDURE SUPPLIES_ORDER(P_PARTY_ID       IN NUMBER,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2);

    PROCEDURE OM_REQ(P_DEVICE_ID       IN VARCHAR2,
                   P_GROUP_ID        IN VARCHAR2,
                   X_RETURN_STATUS   IN OUT VARCHAR2,
                   X_RETURN_MSG      IN OUT VARCHAR2);
                
    PROCEDURE MISC_SUPPLIES(P_PARTY_ID       IN NUMBER,
                          X_RETURN_STATUS   IN OUT VARCHAR2,
                          X_RETURN_MSG      IN OUT VARCHAR2);
                          
    PROCEDURE email_send (x_return_status in out nocopy varchar2 , 
                      x_return_msg in out nocopy varchar2);
                      
    PROCEDURE MANUAL_ORDER(X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                        X_RETCODE         OUT  NOCOPY  NUMBER,
                        P_SERIAL_NO       IN VARCHAR2,
                        P_LABEL           IN VARCHAR2);
                      
    FUNCTION GET_MARGIN (P_SERIAL_NO IN VARCHAR2,
                         P_PARTY_ID IN NUMBER) RETURN NUMBER;
                         
                         
      PROCEDURE SUBMIT_PO (P_PARTY_ID IN NUMBER,
                             P_REQUEST_NUMBER IN VARCHAR2,
                             P_TYPE IN VARCHAR2,
                             X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                         X_RETURN_MSG     IN OUT NOCOPY VARCHAR2);

 PROCEDURE CREATE_TASK
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
  , p_attribute_1	       IN VARCHAR2
  , p_attribute_2	       IN VARCHAR2
  , p_attribute_3	       IN VARCHAR2
  , p_attribute_4	       IN VARCHAR2
  , p_attribute_5	       IN VARCHAR2
  , p_attribute_6	       IN VARCHAR2
  , p_attribute_7	       IN VARCHAR2
  , p_attribute_8	       IN VARCHAR2
  , p_attribute_9	       IN VARCHAR2
  , p_attribute_10	     IN VARCHAR2
  , p_attribute_11	     IN VARCHAR2
  , p_attribute_12	     IN VARCHAR2
  , p_attribute_13	     IN VARCHAR2
  , p_attribute_14	     IN VARCHAR2
  , p_attribute_15	     IN VARCHAR2
  , p_context		         IN VARCHAR2
  , p_assignee_id        IN NUMBER
  , p_template_id        IN NUMBER );
END XX_CS_MPS_VALIDATION_PKG;
/