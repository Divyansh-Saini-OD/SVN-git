SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PA_PROJ_TASK_PROG_UPD_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PROJ_TASK_PROG_UPD_PKG.pks                                     |
-- | Description      : Package spec for CR816 PLM Projects Task Progress Update             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        13-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_project_number IN  VARCHAR2 
                           );
                           
 END XX_PA_PROJ_TASK_PROG_UPD_PKG ;
/
SHOW ERRORS;
EXIT ;                           