SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XXCRM_UPDATE_TASKS package
PROMPT

CREATE OR REPLACE
PACKAGE XXCRM_UPDATE_TASKS
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
AS

 -- Global Variables
gc_error_message VARCHAR2(4000):= NULL;

 PROCEDURE Log_Exception (p_error_location          IN  VARCHAR2
                         ,p_error_message_code      IN  VARCHAR2
                         ,p_error_msg               IN  VARCHAR2
                         ,p_error_message_severity  IN  VARCHAR2
                         ,p_application_name        IN  VARCHAR2
                         ,p_module_name             IN  VARCHAR2
                         ,p_program_type            IN  VARCHAR2
                         ,p_program_name            IN  VARCHAR2
                         );

PROCEDURE P_Update_Task
                         ( P_Task_ID              IN  NUMBER,
                           P_New_Task_Type_ID     IN  NUMBER,                          
                           P_New_Task_Status_ID   IN  NUMBER,
                           X_Ret_Code             OUT NOCOPY NUMBER,
                           X_Error_Msg            OUT NOCOPY VARCHAR2);


PROCEDURE P_Mass_Update_Tasks
                          ( x_errbuf         OUT NOCOPY VARCHAR2,
                            x_retcode        OUT NOCOPY NUMBER,
                            P_Update_column  IN VARCHAR2,
                            P_Commit         IN VARCHAR2);

END XXCRM_UPDATE_TASKS;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
