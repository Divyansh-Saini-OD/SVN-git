CREATE OR REPLACE package APPS.XX_PA_PROJ_CONV_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PROJ_CONV_PKG.pks                            |
-- | Description :  his objective of this API is to convert projects   |
-- |                 from the PRD01 to PRDGB PA system.                |
-- |               All detail information will be converted.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       13-Mar-2010 Rama Dwibhashyam     Initial version         |
-- +===================================================================+

   -- Global Variables
   g_run_date             DATE   := SYSDATE;
   --g_request_id           NUMBER := Fnd_Global.conc_request_id ;
   g_resp_id              NUMBER := Fnd_Global.resp_id ;
   g_resp_appl_id         NUMBER := FND_PROFILE.value('RESP_APPL_ID');
   g_user_id              NUMBER := Fnd_Global.user_id;
   g_login_id             NUMBER := Fnd_Global.login_id;
   g_org_id               NUMBER := Fnd_Profile.value('ORG_ID');
   g_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
   g_application_id       NUMBER := 275;
   g_user_name            VARCHAR2(100) := FND_PROFILE.value('USERNAME');
   g_resp_name            VARCHAR2(150) := FND_PROFILE.value('RESP_NAME');

procedure CREATE_PROJECT_INFO (
                               x_errbuf            OUT NOCOPY VARCHAR2
                             , x_retcode           OUT NOCOPY VARCHAR2
                             , p_project_number     IN  VARCHAR2
                             , p_template_number    IN  VARCHAR2
                             );
                             

procedure CREATE_ATTR_INFO (
                               x_msg_data          OUT NOCOPY VARCHAR2
                             , x_return_status     OUT NOCOPY VARCHAR2
                             , p_old_project_id     IN  NUMBER
                             , p_new_project_id     IN  NUMBER                             
                             , p_old_attr_group_id  IN  NUMBER
                             , p_new_attr_group_id  IN  NUMBER
                             , p_old_extension_id   IN  NUMBER
                             );                             
                             


END XX_PA_PROJ_CONV_PKG ;
/