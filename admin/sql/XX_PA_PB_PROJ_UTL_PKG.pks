CREATE OR REPLACE PACKAGE APPS.XX_PA_PB_PROJ_UTL_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PB_PROJ_UTL_PKG.pks                                     |
-- | Description      : Package spec for CR853 PLM Enhancement Utility Package               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        28-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

   g_user_name      varchar2(60):= FND_PROFILE.value('USERNAME');
   g_resp_name      varchar2(60):= FND_PROFILE.value('RESP_NAME');
   g_resp_appl_id   number      := FND_PROFILE.value('RESP_APPL_ID');
   g_user_id        number      := FND_PROFILE.value('USER_ID');
   g_resp_id        number      := FND_PROFILE.value('RESP_ID');
   g_profile_org_id number      := FND_PROFILE.value('ORG_ID');

PROCEDURE proj_task_status_update(p_vendor_id varchar2
                      ,p_vendor_name varchar2
                      ,p_factory_id varchar2
                      ,p_factory_name varchar2
                      ,p_task_type varchar2
                           );
                           
PROCEDURE get_vendor_info( projectId IN NUMBER
                          ,x_error_msg  OUT USER_FUNC_ERROR_ARRAY
                           )
                          ;   
                                                      
                           
 END XX_PA_PB_PROJ_UTL_PKG ;
/