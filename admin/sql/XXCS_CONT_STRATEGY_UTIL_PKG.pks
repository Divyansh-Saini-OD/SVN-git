CREATE OR REPLACE
PACKAGE XXSCS_CONT_STRATEGY_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXSCS_CONT_STRATEGY_PKG                                               |
-- | Description : Utilities for Contact Strategy procedures                                 |
-- | RICE ID     : I2094_Contact_Strategy_II
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        21-Mar-2008       Sreekanth Rao       Initial Version                         |
-- +=========================================================================================+
AS
 -- Global Variables
 G_ERRBUF               VARCHAR2(4000);
 G_REQUEST_ID           PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
 G_global_start_date    DATE;
 gc_error_message       VARCHAR2(4000);
 PROCEDURE Log_Exception (p_error_location          IN  VARCHAR2
                         ,p_error_message_code      IN  VARCHAR2
                         ,p_error_msg               IN  VARCHAR2
                         ,p_error_message_severity  IN  VARCHAR2
                         ,p_application_name        IN  VARCHAR2
                         ,p_module_name             IN  VARCHAR2
                         ,p_program_type            IN  VARCHAR2
                         ,p_program_name            IN  VARCHAR2
                         );
 PROCEDURE P_Route_Lead_Opp(
                             P_Potential_ID         IN  NUMBER,
                             P_Party_Site_ID        IN  NUMBER,
                             P_Potential_Type_Code  IN  VARCHAR2,
                             X_Entity_Type          OUT NOCOPY VARCHAR2,
                             X_Entity_ID            OUT NOCOPY NUMBER,
                             X_Ret_Code             OUT NOCOPY VARCHAR2,
                             X_Error_Msg            OUT NOCOPY VARCHAR2
                            );
 PROCEDURE P_Create_Cont_Strategy_Lead(
                             P_Potential_ID  IN  NUMBER,
                             P_Party_Site_ID IN  NUMBER,
                             P_Potential_Type_Code  IN  VARCHAR2,                             
                             X_Lead_ID       OUT NOCOPY NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,                             
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            );
 PROCEDURE P_Updt_Cont_Strategy_Lead(
                             P_Feedback_ID   IN  NUMBER,
                             P_Status_Code   IN  VARCHAR2,
                             P_Source_Name   IN  VARCHAR2,
                             P_Channel_Code  IN  VARCHAR2,
                             P_Currency      IN  VARCHAR2,
                             P_Close_reason  IN  VARCHAR2,
                             P_lead_Rank     IN  VARCHAR2,
                             P_Total_Amount  IN  VARCHAR2,
                             X_Lead_ID       OUT NOCOPY NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,                             
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            );
 PROCEDURE P_Create_Task
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Task_Name           IN  VARCHAR2,
                          P_Task_Desc           IN  VARCHAR2,
                          P_Task_Type           IN  VARCHAR2,
                          P_Task_Status         IN  VARCHAR2,
                          P_Task_Priority       IN  VARCHAR2,
                          P_Start_Date          IN  DATE,
                          P_End_Date            IN  DATE,
                          X_Task_ID             OUT NOCOPY NUMBER,
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2);
 PROCEDURE P_Create_Note
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Notes               IN  VARCHAR2,
                          X_Note_ID             OUT NOCOPY NUMBER,
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2);
 PROCEDURE P_Create_Appointment
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Task_Name           IN  VARCHAR2,
                          P_Task_Desc           IN  VARCHAR2,
                          P_Task_Type           IN  VARCHAR2,
                          P_Task_Priority       IN  VARCHAR2,
                          P_Start_Date          IN  DATE,
                          P_End_Date            IN  DATE,
                          P_Timezone_ID         IN  NUMBER DEFAULT fnd_profile.VALUE('CLIENT_TIMEZONE_ID'),
                          X_Task_ID             OUT NOCOPY NUMBER,                          
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2);
END XXSCS_CONT_STRATEGY_PKG;
/