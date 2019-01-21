SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_JTF_RM_SETUP_REPORT_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_JTF_RM_SETUP_REPORT_PKG                                       |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT1A   18-APR-2008 Nabarun Ghosh             Initial draft Version.          |
-- +================================================================================+

   --PRAGMA SERIALLY_REUSABLE;
   ----------------------------
   --Declaring Global Constants
   ----------------------------

   G_LAST_UPDATE_DATE          DATE            := SYSDATE;
   G_LAST_UPDATED_BY           PLS_INTEGER     := FND_GLOBAL.USER_ID;
   G_CREATION_DATE             DATE            := SYSDATE;
   G_CREATED_BY                PLS_INTEGER     := FND_GLOBAL.USER_ID;
   G_LAST_UPDATE_LOGIN         PLS_INTEGER     := FND_GLOBAL.LOGIN_ID;
   G_PROG_APPL_ID              PLS_INTEGER     := FND_GLOBAL.PROG_APPL_ID;
   G_REQUEST_ID                PLS_INTEGER     := FND_GLOBAL.CONC_REQUEST_ID;
   
   G_ENTITY_PARTY              VARCHAR2 (16)   := 'PARTY';
   G_ENTITY_PARTY_SITE         VARCHAR2 (16)   := 'PARTY_SITE';
   G_ENTITY_LEAD               VARCHAR2 (16)   := 'LEAD';
   G_ENTITY_OPPT               VARCHAR2 (16)   := 'OPPORTUNITY';
   G_PARTY_TYPE_ORG            VARCHAR2 (16)   := 'ORGANIZATION';
   
   
   -- +================================================================================+
   -- | Name        :  Log_Exception                                                   |
   -- | Description :  This procedure is used to log any exceptions raised using custom|
   -- |                Error Handling Framework                                        |
   -- +================================================================================+
   PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                            ,p_error_message_code IN  VARCHAR2
                            ,p_error_msg          IN  VARCHAR2 )
   IS
   
     ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
     ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
   
   BEGIN
   
     XX_COM_ERROR_LOG_PUB.log_error_crm
        (
         p_return_code             => FND_API.G_RET_STS_ERROR
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'E1309-B_Autonamed_Account_Creation'
        ,p_program_name            => 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
        ,p_module_name             => 'TM'
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
   
   -- +====================================================================+
   -- | Name        :  display_out                                         |
   -- | Description :  This procedure is invoked to print in the output    |
   -- |                file                                                |
   -- |                                                                    |
   -- | Parameters  :  Log Message                                         |
   -- +====================================================================+
   
   PROCEDURE display_out(
                         p_message IN VARCHAR2
                        )
   
   IS
   
   BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
   END display_out;

   PROCEDURE display_log(
                         p_message IN VARCHAR2
                        )
   
   IS
   
   BEGIN
        NULL;
        --FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
   END display_log;
   
   FUNCTION Check_Member ( 
                           p_resource_id  IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                         )
   RETURN NUMBER
   IS
     
     ln_is_member      PLS_INTEGER;
   
   BEGIN
   
      SELECT COUNT(1)
      INTO   ln_is_member 
      FROM   jtf_rs_resource_extns_vl RES
      WHERE EXISTS
                  (
                   SELECT 1
                   FROM   jtf_rs_group_mbr_role_vl   GMR
                   WHERE  GMR.resource_id = RES.resource_id
                   AND    SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,sysdate+1)
                   AND    GMR.member_flag = 'Y'
                  )
      AND NOT EXISTS
                    (
                     SELECT 1
                     FROM   jtf_rs_group_mbr_role_vl GMR
                     WHERE  GMR.resource_id = RES.resource_id
                     AND    SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,SYSDATE+1)
                     AND    GMR.manager_flag = 'Y'
                    )
      AND NOT EXISTS
                    (
                     SELECt 1
                     FROM   jtf_rs_group_mbr_role_vl GMR
                     WHERE  GMR.resource_id = RES.resource_id
                     AND    SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,SYSDATE+1)
                     AND    GMR.admin_flag = 'Y'	
	        )
      AND  RES.resource_id = p_resource_id;		        

      RETURN ln_is_member;

   END Check_Member;
   
   FUNCTION Check_Admin ( 
                           p_resource_id  IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                         )
   RETURN NUMBER
   IS
   
     ln_is_admin      PLS_INTEGER;
   
   BEGIN
      
      select COUNT(1)
      INTO   ln_is_admin 
      FROM   jtf_rs_resource_extns_vl RES
      WHERE  EXISTS
                   (
                    SELECT 1
                    FROM   jtf_rs_group_mbr_role_vl GMR
                    WHERE  GMR.resource_id = RES.resource_id
                    AND	   SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,SYSDATE+1)
                    AND	   GMR.admin_flag = 'Y'
                   )
      AND NOT EXISTS
                    (
                      SELECT 1
                      FROM   jtf_rs_group_mbr_role_vl GMR
                      WHERE  GMR.resource_id = RES.resource_id
                      AND    SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,SYSDATE+1)
                      AND    GMR.manager_flag = 'Y'
                    )
      AND  RES.resource_id = p_resource_id;
      

      RETURN ln_is_admin;

   END Check_Admin;
   
   FUNCTION Check_Manager ( 
                           p_resource_id  IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                         )
   RETURN NUMBER
   IS
   
     ln_is_manager      PLS_INTEGER;
   
   BEGIN
      
      SELECT COUNT(1)
      INTO   ln_is_manager 
      FROM   jtf_rs_resource_extns_vl RES
      WHERE EXISTS
                  (
                   SELECT 1
                   FROM   jtf_rs_group_mbr_role_vl GMR
                   WHERE  GMR.resource_id = RES.resource_id
                   AND	  SYSDATE BETWEEN GMR.start_date_active AND NVL(GMR.end_date_active,SYSDATE+1)
                   AND	  GMR.manager_flag = 'Y'
                  )
      AND RES.resource_id = p_resource_id;             
      
      RETURN ln_is_manager;

   END Check_Manager;   
   
   PROCEDURE Get_Resource_Mgr_Setup_Dtl  
                                       (        
   	                                 p_resource_name IN jtf_rs_resource_extns_vl.resource_name%TYPE
   	                                ,x_error_code   OUT NOCOPY VARCHAR2
   	                                ,x_error_msg    OUT NOCOPY VARCHAR2
   	                               )
   AS   	                               
      
      ln_is_manager           PLS_INTEGER;
      ln_is_member            PLS_INTEGER;
      ln_is_admin             PLS_INTEGER;
      lc_output_str           VARCHAR2(32000);
      lc_error_message        VARCHAR2(32000); 
      lc_return_status        VARCHAR2(1);
      ln_msg_count            PLS_INTEGER;
      lc_msg_data             VARCHAR2(4000);
      lc_message              VARCHAR2(4000);
      ln_cnt                  PLS_INTEGER;
      ln_proceed              PLS_INTEGER := 0;
      ln_group_count          PLS_INTEGER := 0;
      ln_role_count           PLS_INTEGER := 0;
      ln_is_supv_exists       PLS_INTEGER := 0;
      ln_supv_groups          PLS_INTEGER := 0;
      
      lc_res_str              VARCHAR2(32000);
      lc_res_grp_str          VARCHAR2(32000);
      lc_res_grp_role         VARCHAR2(32000);
      lc_res_grp_supv	      VARCHAR2(32000);
      lc_res_supv_grp	      VARCHAR2(32000);
      lc_res_supv_grp_role    VARCHAR2(32000);
      lc_str                  VARCHAr2(32000);  
      --lc_str1                 VARCHAr2(32000);  
      --lc_str2                 VARCHAr2(32000);  
      --lc_str3                 VARCHAr2(32000);  
      --lc_str4                 VARCHAr2(32000);  
            
   BEGIN
       
       --Obtain the resource details
       OPEN lcu_get_resource_details(p_resource_name);
       FETCH lcu_get_resource_details BULK COLLECT
       INTO  lt_cur_res_dtls_tbl; 
       CLOSE lcu_get_resource_details;
       
       IF lt_cur_res_dtls_tbl.COUNT > 0 THEN
         
         --Resource details loop
         FOR ln_row IN lt_cur_res_dtls_tbl.FIRST..lt_cur_res_dtls_tbl.LAST
         LOOP  
                    
           -- Member Check
           ln_is_member  := Check_Member (lt_cur_res_dtls_tbl(ln_row).resource_id);
             
           -- Admin Check
           ln_is_admin   := Check_Admin (lt_cur_res_dtls_tbl(ln_row).resource_id);
           
           -- Manager Check
           ln_is_manager := Check_Manager (lt_cur_res_dtls_tbl(ln_row).resource_id);
           
           IF ln_is_member > 0 OR 
              ln_is_admin  > 0 OR
              ln_is_manager > 0 THEN
              
              ln_proceed  := 1;
              
           END IF;
           
           IF ln_proceed > 0 THEN
             
             --Obtain the resources group details
             OPEN  lcu_get_res_groups (lt_cur_res_dtls_tbl(ln_row).resource_id);
             FETCH lcu_get_res_groups BULK COLLECT
             INTO  lt_cur_get_res_groups_tbl;
             CLOSE lcu_get_res_groups;
               
             ln_group_count := 0;
             ln_group_count := lt_cur_get_res_groups_tbl.COUNT;       
             
             display_log('ln_group_count:  '||ln_group_count);  
             
             IF lt_cur_get_res_groups_tbl.COUNT > 0 THEN 
              BEGIN   
               
               --Resource group details loop
               FOR ln_res_grp IN lt_cur_get_res_groups_tbl.FIRST..lt_cur_get_res_groups_tbl.LAST
               LOOP
                 
                 display_log('Inside Resource group details loop');
                 display_log('==================================');
                 
                 lt_tm_rm_setup_tbl(ln_row).employee_number  := lt_cur_res_dtls_tbl(ln_row).employee_number;
                 lt_tm_rm_setup_tbl(ln_row).resource_name    := lt_cur_res_dtls_tbl(ln_row).resource_name;
                 lt_tm_rm_setup_tbl(ln_row).user_name	     := lt_cur_res_dtls_tbl(ln_row).user_name;
                 lt_tm_rm_setup_tbl(ln_row).resource_id	     := lt_cur_res_dtls_tbl(ln_row).resource_id;
                 
                 IF ln_is_member > 0 THEN
                    lt_tm_rm_setup_tbl(ln_row).sales_resource_type  := 'Member';
                 END IF;
                 
                 IF ln_is_admin > 0 THEN
                    lt_tm_rm_setup_tbl(ln_row).sales_resource_type  := 'Admin';
                 END IF;
                 
                 IF ln_is_manager > 0 THEN
                      lt_tm_rm_setup_tbl(ln_row).sales_resource_type  := 'Manager';
                 END IF;
                 
                 IF ln_group_count > 1 THEN
                    lt_tm_rm_setup_tbl(ln_row).Multiple_Groups	     := 'Y';
                 ELSE   
                    lt_tm_rm_setup_tbl(ln_row).Multiple_Groups	     := 'N';
                 END IF;
                 
                 lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).resource_id	        := lt_cur_res_dtls_tbl(ln_row).resource_id;
                 lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).resource_group_id   := lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id  ;
                 lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).resource_group_name := lt_cur_get_res_groups_tbl(ln_res_grp).res_group_name;
                 
                 display_log('lt_cur_res_dtls_tbl(ln_row).resource_id:'||lt_cur_res_dtls_tbl(ln_row).resource_id);
                 display_log('lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id :'||lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id );
                 
                 --Obtain resources groups role / div details
                 OPEN lcu_get_res_groups_role (
                                               lt_cur_res_dtls_tbl(ln_row).resource_id
                                              ,lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id    
                                              );
                 FETCH lcu_get_res_groups_role BULK COLLECT
                 INTO  lt_cur_get_res_grp_role_tbl;
                 CLOSE lcu_get_res_groups_role;
                 
                 ln_role_count := 0;
                 ln_role_count := lt_cur_get_res_grp_role_tbl.COUNT;       
                 
                 IF ln_role_count > 1 THEN
                    lt_tm_rm_setup_tbl(ln_row).Multiple_Roles	     := 'Y';
                 ELSE   
                    lt_tm_rm_setup_tbl(ln_row).Multiple_Roles	     := 'N';
                 END IF;
                 
                 IF lt_cur_get_res_grp_role_tbl.COUNT > 0 THEN 
                  BEGIN 
                   --Resource group role / div details loop
                   FOR ln_res_grp_role IN lt_cur_get_res_grp_role_tbl.FIRST..lt_cur_get_res_grp_role_tbl.LAST
                   LOOP
                         
                     lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).resource_group_id	     := lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id;   
                     lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).resource_sales_role_name := lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Name  ; 
                     lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).resource_division        := lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Div;  
                     lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).Resource_Legacy_Id       := lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Lgcy_id;  
                     
                     display_log('Inside Resource group role / div details loop');
                     display_log('==============================================');
                     
                     display_log('ln_is_member:'||ln_is_member);
                     display_log('Resource Group Id:'||lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id);
                     display_log('Res_Grp_Role_Name:'||lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Name);
                     display_log('Res_Grp_Role_Div :'||lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Div);
                     display_log('Resource_Legacy_Id :'||lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Lgcy_id);
                     
                    
                     IF ln_is_member > 0 THEN
                        --Obtain resources groups supervisor details                
                        OPEN lcu_get_grp_supv_rep (
                                                   lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id
                                                  );
                        FETCH lcu_get_grp_supv_rep BULK COLLECT
                        INTO  lt_cur_get_res_grp_supv_tbl;
                        CLOSE lcu_get_grp_supv_rep;                  
                     ELSE    
                        --Obtain managers group supervisor details 
                        OPEN lcu_get_grp_supv_mgr (
                                                   lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id
                                                  );
                        FETCH lcu_get_grp_supv_mgr BULK COLLECT
                        INTO  lt_cur_get_res_grp_supv_tbl;
                        CLOSE lcu_get_grp_supv_mgr; 
                     END IF;
                     
                     ln_is_supv_exists := 0;
                     ln_is_supv_exists := lt_cur_get_res_grp_supv_tbl.COUNT;  
                     
                     display_log('lt_cur_get_res_grp_supv_tbl.COUNT :'||ln_is_supv_exists);                     
                     
                     --IF ln_role_count = 1 THEN   --Commented on 23/04/2008
                     IF ln_is_supv_exists = 1 THEN
                        lt_tm_rm_setup_tbl(ln_row).no_supervisor	      := 'N';
                        lt_tm_rm_setup_tbl(ln_row).multiple_supervisors       := 'N';
                     ELSIF ln_is_supv_exists > 1 THEN
                        lt_tm_rm_setup_tbl(ln_row).no_supervisor	      := 'N';
                        lt_tm_rm_setup_tbl(ln_row).multiple_supervisors       := 'Y';
                     ELSE   
                        lt_tm_rm_setup_tbl(ln_row).no_supervisor	      := 'Y';
                        lt_tm_rm_setup_tbl(ln_row).multiple_supervisors       := 'N';
                     END IF;
                     
                     display_log('no_supervisor	      :'       ||lt_tm_rm_setup_tbl(ln_row).no_supervisor	     );
                     display_log('multiple_supervisors       :'||lt_tm_rm_setup_tbl(ln_row).multiple_supervisors      );
                     display_log('lt_cur_get_res_grp_supv_tbl.COUNT :'||lt_cur_get_res_grp_supv_tbl.COUNT);
                 
                     IF lt_cur_get_res_grp_supv_tbl.COUNT > 0 THEN   
                       
                       display_log('1');
                       
                       BEGIN 
                        --Resource group supervisor details loop
                        FOR ln_res_grp_supv IN lt_cur_get_res_grp_supv_tbl.FIRST..lt_cur_get_res_grp_supv_tbl.LAST
                        LOOP
                           
                       	  display_log('2');
                       	  display_log('ln_row: '||ln_row);
                       	  display_log('ln_res_grp: '||ln_res_grp);
                       	  display_log('ln_res_grp_role: '||ln_res_grp_role);
                       	  display_log('ln_res_grp_supv: '||ln_res_grp_supv);
                       	  
                       	  
                       	  
                       	  --display_log('lt_cur_get_res_groups_tbl(ln_res_grp_role).res_group_id: '||lt_cur_get_res_groups_tbl(ln_res_grp_role).res_group_id);
                       	  display_log('lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id): '||lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id);
                       	  display_log('2.1');
                       	  display_log('lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_name: '||lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_name);
                       	  display_log('2.2');
                       	  display_log('lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id : '||lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id );
                       	  display_log('2.3');
                       	  
                       	                         	  
                          lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).resource_group_id      := lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id;   
                          lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).group_supervisor_name  := lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_name; 
                          lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).group_supervisor_id    := lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id  ;
                          
                          display_log('3');
                          
                          display_log('Inside Resource group supervisor details loop');
                          display_log('==============================================');
                          display_log('Resource Group Id:'||lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id);
                          display_log('lt_cur_get_res_groups_tbl(ln_res_grp_role).res_group_id;    '   ||lt_cur_get_res_groups_tbl(ln_res_grp).res_group_id   );
                          display_log('lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_name;'||lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_name);
                          display_log('lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id  ;'||lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id  );
                          
                          --Obtain the supervisors group details
                          OPEN lcu_get_supv_groups (
                                                   lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id
                                                   );
                          FETCH lcu_get_supv_groups BULK COLLECT
                          INTO  lt_cur_get_supv_grp_tbl;
                          CLOSE lcu_get_supv_groups;
                     
                          ln_supv_groups := 0;
                          ln_supv_groups := lt_cur_get_supv_grp_tbl.COUNT;       
                     
                          IF ln_supv_groups > 1 THEN
                             lt_tm_rm_setup_tbl(ln_row).Multiple_Supervisor_Groups := 'Y';
                          ELSIF ln_supv_groups = 1 THEN 
                             lt_tm_rm_setup_tbl(ln_row).Multiple_Supervisor_Groups := 'N';
                          ELSE
                             lt_tm_rm_setup_tbl(ln_row).Multiple_Supervisor_Groups := 'N';
                          END IF;
                     
                          IF  lt_cur_get_supv_grp_tbl.COUNT > 0 THEN                            
                           BEGIN 
                            FOR ln_supv_grp IN lt_cur_get_supv_grp_tbl.FIRST..lt_cur_get_supv_grp_tbl.LAST
                            LOOP
                              
                              display_log('Inside Supervisors group details loop');
                              display_log('======================================');
                              
                              lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Group_Supervisor_Id   := lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id;
                              lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Supervisor_Group_Id   := lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id;      
                              lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Supervisor_Group_name := lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_Name;	
                              
                              display_log('lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id;  ;'||lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id );
                              display_log('lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id;        ;'||lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id       );
                              display_log('lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_Name;	  ;'||lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_Name	 );
                              
                              --Obtain the supervisor groups role / div
                              OPEN lcu_get_supv_grp_role (
                                                          lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id
                                                         ,lt_cur_get_res_grp_supv_tbl(ln_res_grp_supv).res_grp_supv_id 
                                                         );
                              FETCH lcu_get_supv_grp_role BULK COLLECT 
                              INTO  lt_cur_get_supv_grp_role_tbl;
                              CLOSE lcu_get_supv_grp_role;
                         
                              display_log('Supvervisor groups role / div count:  '||lt_cur_get_supv_grp_role_tbl.COUNT);
                              
                              IF  lt_cur_get_supv_grp_role_tbl.COUNT > 0 THEN
                               BEGIN          
                                FOR ln_supv_grp_role IN lt_cur_get_supv_grp_role_tbl.FIRST..lt_cur_get_supv_grp_role_tbl.LAST
                                LOOP
                                  display_log('Inside supervisor groups role / div details loop');
                                  display_log('================================================');
                                  
                                  lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).Supervisor_Group_Id	   := lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id;
                                  lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).Supervisor_Grp_Role_Name  := NVL(lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role,'--')  ;     
                                  lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).Supervisor_Grp_Division   := NVL(lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role_Div,'--'); 
                                  
                                  display_log('lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id:                '||lt_cur_get_supv_grp_tbl(ln_supv_grp).Supv_Grp_id);
                                  display_log('lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role  ;  '||lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role    );
                                  display_log('lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role_Div;'||lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).Supv_Grp_Role_Div);
                                  
                                  --Derive the cross division
                                  
                                  display_log('--Derive the cross division--');
                                  display_log('Resource Div: lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Div: '||lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Div);
                                  display_log('Sup      Div: lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_div: '||lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_div);
                                  
                                  IF  lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_div 
                                        = lt_cur_get_res_grp_role_tbl(ln_res_grp_role).Res_Grp_Role_Div                 THEN
                                        lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).cross_divisions    := 'N';
                                  ELSE  
                                        lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).cross_divisions    := 'Y';
                                  END IF;                                 
                                  
                                  --End of derivation of cross division

                                  --Derive the Reporting to Non-DSM
                                  
                                  display_log('--Derive the Reporting to Non-DSM--');
                                  display_log('Sup OD Role Code : lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_code: '||lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_code);

                                  IF  lt_cur_get_supv_grp_role_tbl(ln_supv_grp_role).supv_grp_role_code = 'DSM' THEN
                                        lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).Reporting_To_Non_DSM    := 'N';
                                  ELSE  
                                        lt_tm_rm_setup_tbl(ln_row).lt_tm_res_group_tbl(ln_res_grp).lt_tm_res_grp_role_div_tbl(ln_res_grp_role).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role).Reporting_To_Non_DSM    := 'Y';
                                  END IF;  
                                  
                                  -- End of Derivationof Reporting to Non-DSM
                                  
                                  
                                END LOOP; -- End Loop of lt_cur_get_supv_grp_role_tbl                           
                               EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                 NULL;
                               END;
                              END IF;      -- End of If lt_cur_get_supv_grp_role_tbl.COUNT > 0                                  
                              
                            END LOOP; -- End Loop of lt_cur_get_supv_grp_tbl                      
                           EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                             NULL; 
                           END; 

                          END IF;     -- End of If lt_cur_get_supv_grp_tbl.COUNT > 0                                  
                        END LOOP; -- End Loop of lt_cur_get_res_grp_role_tbl
                       EXCEPTION 
                        WHEN OTHERS THEN 
                         display_log('WHEN OTHERS...'||SQLERRM);
                       END; 

                      END IF;     -- End of If lt_cur_get_res_grp_role_tbl.COUNT > 0                   
                   END LOOP; --End Loop of lt_cur_get_res_grp_role_tbl                 
                  EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                    NULL;
                  END;

                 END IF;     --End of If lt_cur_get_res_grp_role_tbl.COUNT > 0                      
               END LOOP; -- End Loop of lt_cur_get_res_groups_tbl                           
              EXCEPTION
               WHEN NO_DATA_FOUND THEN
                NULL; 
              END;                

             END IF;     -- End If of lt_tm_get_res_groups_tbl.COUNT > 0                
           END IF; --ln_proceed > 0           
         END LOOP; -- End Loop of lt_tm_res_dtls_tbl         

       END IF;     -- End If of lt_tm_res_dtls_tbl.COUNT > 0
         
       --+-----------------------------------------------------------------------------------+
       --|Displaying the output                                                              | 
       --|                                                                                   |
       --+-----------------------------------------------------------------------------------+
       
       Display_Out(
                     RPAD('EMPLOYEE_NUMBER'                  ,35)||chr(9)
                   ||RPAD('RESOURCE_NAME'                    ,55)||chr(9)
                   ||RPAD('USER_NAME'                        ,25)||chr(9)
                   ||RPAD('RESOURCE_ID'                      ,25)||chr(9)
                   ||RPAD('SALES_RESOURCE_TYPE'              ,30)||chr(9)                   
                   ||RPAD('MULTIPLE_GROUPS_(Y/N)'            ,30)||chr(9)
                   ||RPAD('MULTIPLE_ROLES_(Y/N)'             ,30)||chr(9)
                   ||RPAD('NO_SUPERVISOR_(Y/N)'              ,30)||chr(9)
                   ||RPAD('MULTIPLE_SUPERVISORS_(Y/N)'       ,30)||chr(9)
                   ||RPAD('MULTIPLE_SUPERVISORS_GROUPS_(Y/N)',40)||chr(9)
                   ||RPAD('RESOURCE_GROUP_NAME'              ,25)||chr(9)                  
                   ||RPAD('SALES_ROLE_NAME'                  ,25)||chr(9)
                   ||RPAD('DIVISION'                         ,15)||chr(9)
                   ||RPAD('LEGACY_ID'                        ,15)||chr(9)                   
                   ||RPAD('SUPERVISOR_NAME'                  ,25)||chr(9)
                   ||RPAD('SUPERVISOR_GROUP_NAME'            ,25)||chr(9)
                   ||RPAD('SUPERVISOR_ROLE_NAME'             ,25)||chr(9)
                   ||RPAD('SUPERVISOR_DIVISION'              ,25)||chr(9)
                   ||RPAD('CROSS_DIVISIONS_(Y/N)'            ,25)||chr(9)
                   ||RPAD('REPORTING_TO_NON-DSM_(Y/N)'       ,35)||chr(9)
                   --||CHR(10)                   
                  );
                  
       /*Display_Out(
                      LPAD(' ',35,'_')
		    ||LPAD(' ',55,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',30,'_')
		    ||LPAD(' ',30,'_')
		    ||LPAD(' ',30,'_')
		    ||LPAD(' ',30,'_')
		    ||LPAD(' ',30,'_')
		    ||LPAD(' ',40,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',15,'_')
		    ||LPAD(' ',15,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
		    ||LPAD(' ',25,'_')
                    ||LPAD(' ',35,'_')
                   --||CHR(10)                   
                  );    */   
       --Display_Out(RPAD(' ',600,'-'));
       
       lc_res_str            := NULL;
       lc_output_str         := NULL;
            
       lc_res_grp_str        := NULL;
       lc_res_grp_role       := NULL;
       lc_res_grp_supv	     := NULL;
       lc_res_supv_grp	     := NULL;
       lc_res_supv_grp_role  := NULL; 
       lc_str                := NULL;       
       
       BEGIN
        --+ Resource Records +--
        IF lt_tm_rm_setup_tbl.COUNT > 0 THEN       
          FOR ln_res_rows IN lt_tm_rm_setup_tbl.FIRST..lt_tm_rm_setup_tbl.LAST
          LOOP
            
            lc_res_str :=   RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Employee_Number,'--')	       ,35)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Resource_Name,'--')	       ,55)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).User_Name,'--')                   ,25)||chr(9)
            		  ||RPAD(lt_tm_rm_setup_tbl(ln_res_rows).Resource_Id                           ,25)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Sales_Resource_Type,'--')         ,30)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Multiple_Groups,'--')             ,30)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Multiple_Roles,'--')              ,30)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).No_Supervisor,'--')               ,30)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Multiple_Supervisors,'--')        ,30)||chr(9)
            		  ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).Multiple_Supervisor_Groups,'N')   ,40)||chr(9)
            		  ;
            
            lc_res_grp_str := NULL;
            
            BEGIN
             --+ Resources Group Records +--
             IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl.COUNT > 0 THEN            
               
               FOR ln_res_grp_rows IN lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl.FIRST..lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl.LAST
               LOOP
                    
                IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).Resource_Id = lt_tm_rm_setup_tbl(ln_res_rows).Resource_Id THEN
                       
                  lc_res_grp_str := lc_res_str||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).Resource_Group_Name,'--'),25)||chr(9);
                    
                  --+ Resource groups role division details +--
                  BEGIN
                  
                    IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl.COUNT > 0 THEN
                    
                       FOR ln_res_grp_role_div IN lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl.FIRST..lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl.LAST
                       LOOP
                         
                         IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).Resource_Group_Id
                           = lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).Resource_Group_Id THEN
                         
                           lc_res_grp_role := lc_res_grp_str||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).Resource_Sales_Role_Name,'--') ,25)||chr(9)
                       	                                    ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).Resource_Division,'--')        ,15)||chr(9)
                       	                                    ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).Resource_Legacy_Id,'--')       ,15)||chr(9);
                         
                           lc_res_grp_supv := NULL;
                           --+ Resource group supervisor details +--
                           BEGIN
                            IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl.COUNT > 0 THEN
                              
                              FOR ln_res_grp_supv IN lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl.FIRST..lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl.LAST
                              LOOP
                                
                                IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).Resource_Group_Id
                                  = lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).Resource_Group_Id THEN
                                  
                                  lc_res_grp_supv := lc_res_grp_role||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).Group_Supervisor_Name,'--') ,25)||chr(9);
                                  
                                  
                                  lc_res_supv_grp := NULL;
                                  --+ Supervisors group details +--
                                  BEGIN                                    
                                    IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl.COUNT > 0 THEN
                                    
                                      FOR  ln_supv_grp IN lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl.FIRST..lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl.LAST
                                      LOOP
                                       
                                       IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Group_Supervisor_Id
                                         = lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).Group_Supervisor_Id THEN
                                       
                                       
                                          lc_res_supv_grp := lc_res_grp_supv||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Supervisor_Group_name,'--'),25)||chr(9);
                                          
                                          lc_res_supv_grp_role := NULL;
                                          --+ Supervisors group role division details +--
                                          BEGIN
                                            
                                            IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl.COUNT > 0 THEN
                                              
                                              FOR ln_supv_grp_role_div IN lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl.FIRST..lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl.LAST
                                              LOOP
                                                 
                                                 IF lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role_div).Supervisor_Group_Id
                                                   = lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).Supervisor_Group_Id THEN 
                                                 
                                                   lc_res_supv_grp_role := lc_res_supv_grp||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role_div).Supervisor_Grp_Role_Name,'--'),25)||chr(9)
                                                                                          ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role_div).Supervisor_Grp_Division,'--'),25)||chr(9)
                                                                                          ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role_div).Cross_Divisions,'--'),25)||chr(9)
                                                                                          ||RPAD(NVL(lt_tm_rm_setup_tbl(ln_res_rows).lt_tm_res_group_tbl(ln_res_grp_rows).lt_tm_res_grp_role_div_tbl(ln_res_grp_role_div).lt_tm_res_grp_supv_tbl(ln_res_grp_supv).lt_tm_supv_group_tbl(ln_supv_grp).lt_tm_supv_grp_role_div_tbl(ln_supv_grp_role_div).reporting_to_non_dsm,'--'),35)||chr(9);
                                                                                      
                                                   Display_Out(lc_res_supv_grp_role);
                                                 END IF;
                                                 
                                              END LOOP;
                                              
                                            ELSE
                                              --If supervisors groups role and div does not exists then print till supervisor group. 
                                              Display_Out(lc_res_supv_grp);
                                            END IF;
                                            
                                          EXCEPTION
                                           WHEN NO_DATA_FOUND THEN
                                             NULL;
                                          END;
                                          
                                       END IF;
                                       
                                      END LOOP;
                                      
                                    ELSE
                                      --If no supervisors group exists then print till the supervisor details 
                                      Display_Out(lc_res_grp_supv);
                                      
                                    END IF;
                                    
                                  EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                     NULL;
                                  END;
                                
                                END IF;
                               
                              END LOOP; -- End Loop of lt_tm_res_grp_supv_tbl
                            ELSE
                              --If no group supervisor exists then print till the group role details                            
                              Display_Out(lc_res_grp_role);
                            
                            END IF; --End of If lt_tm_res_grp_supv_tbl.COUNT > 0 
                           EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                              NULL;
                           END;
                         END IF;
                         
                       END LOOP; --End Loop of lt_tm_res_grp_role_div_tbl    
                    
                    ELSE
                      --If no group roles exists then print only the resource and the group details
                      Display_Out(lc_res_grp_str);
                    END IF; --End of If lt_tm_res_grp_role_div_tbl.COUNT > 0 
                  
                  EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                     NULL;
                  END;
                  
                END IF; 
                    
               END LOOP; --End Loop of lt_tm_res_group_tbl             
            
             ELSE
               
               --If no groups then print only the resource details
               Display_Out(lc_res_str);
               
             END IF;      --End of If lt_tm_res_group_tbl.COUNT > 0 
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
            END;            
            
          END LOOP; --End Loop of lt_tm_rm_setup_tbl 
        END IF;      --End of If lt_tm_rm_setup_tbl.COUNT > 0
       EXCEPTION
         WHEN NO_DATA_FOUND THEN 
           NULL;
       END ;
       
   EXCEPTION
     WHEN OTHERS THEN
       lc_error_message := SQLERRM;
       x_error_code     := 'E';
       x_error_msg      := lc_error_message; 
       
       --Log Exception
       ---------------
       lc_error_message := 'Get_Resource_Mgr_Setup_Dtl';
       lc_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       
       FND_MSG_PUB.add;
       FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                  p_data  => lc_msg_data);
                                
       lc_message := FND_MESSAGE.GET;
       
       Log_Exception ( p_error_location     =>  'Get_Resource_Mgr_Setup_Dtl'
                      ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                      ,p_error_msg          =>  lc_message                 
                  );    
       
   END Get_Resource_Mgr_Setup_Dtl;    
   
   -- +================================================================================+
   -- | Name        :  Resource_Mgr_Setup_Main                                         |
   -- | Description :                                                                  |
   -- |                                                                                |
   -- +================================================================================+   
   PROCEDURE Resource_Mgr_Setup_Main
                                 ( x_errbuf       OUT NOCOPY  VARCHAR2 
          		          ,x_retcode      OUT NOCOPY  NUMBER
          		          ,p_resource_name IN jtf_rs_resource_extns_vl.resource_name%TYPE
          		         ) 
   AS
     
     lc_resource_name      jtf_rs_resource_extns_vl.resource_name%TYPE;   
     lc_error_code         VARCHAR2(1) := 'S';
     lc_error_message      VARCHAR2(32000);
     ln_msg_count          PLS_INTEGER;
     lc_msg_data           VARCHAR2(32000);
     lc_message            VARCHAR2(32000); 
     lc_return_status      VARCHAR2(1);
     
   BEGIN
      
      lc_resource_name := p_resource_name;
      fnd_file.put_line(fnd_file.LOG,'lc_resource_name: '||lc_resource_name);
      Get_Resource_Mgr_Setup_Dtl(
                                 p_resource_name  => lc_resource_name
                                ,x_error_code     => lc_error_code    
                                ,x_error_msg      => lc_error_message
                                ); 
      
      fnd_file.put_line(fnd_file.LOG,'lc_error_message: '||lc_error_message);
      fnd_file.put_line(fnd_file.LOG,'lc_error_code: '||lc_error_code);
      
      
      IF lc_error_code <>  FND_API.G_RET_STS_SUCCESS THEN
         x_retcode := 2;
         x_errbuf  := lc_error_message;
      END IF;
   
   EXCEPTION
     WHEN OTHERS THEN
       x_retcode        := 2;
       lc_error_message := SQLERRM;
       x_errbuf         := lc_error_message;

       --Log Exception
       ---------------
       lc_error_message := 'Resource_Mgr_Setup_Main';
       lc_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);

       FND_MSG_PUB.add;
       FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                  p_data  => lc_msg_data);
                                
       lc_message := FND_MESSAGE.GET;
       
       Log_Exception ( p_error_location     =>  'Resource_Mgr_Setup_Main'
                      ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                      ,p_error_msg          =>  lc_message                      
                  );    
   
   END Resource_Mgr_Setup_Main;

END XX_JTF_RM_SETUP_REPORT_PKG;
/

SHOW ERRORS
--EXIT;