SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_RM_SETUP_REPORT_PKG AUTHID CURRENT_USER
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
-- |DRAFT1A   14-APR-2008 Nabarun Ghosh             Initial draft Version.          |
-- +================================================================================+

  --PRAGMA SERIALLY_REUSABLE;
  
  gc_plsql_tab_limit                CONSTANT PLS_INTEGER := 25;
    
  
  --Supervisors group role division details
  TYPE xx_tm_supv_grp_role_div_t IS RECORD 
     (Supervisor_Group_Id	   jtf_rs_groups_vl.group_id%TYPE               
     ,Supervisor_Grp_Role_Name     jtf_rs_group_mbr_role_vl.role_name%TYPE
     ,Supervisor_Grp_Division      jtf_rs_roles_b.attribute15%TYPE
     ,Cross_Divisions              VARCHAR2(3)        --(Yes/No)
     ,Reporting_To_Non_DSM         VARCHAR2(3)        --(Yes/No)
    ) ;
    
  TYPE xx_tm_supv_grp_role_div_tab_t IS TABLE OF xx_tm_supv_grp_role_div_t INDEX BY PLS_INTEGER;
  lt_tm_supv_grp_role_div_tbl        xx_tm_supv_grp_role_div_tab_t;

  --Supervisors group details
  TYPE xx_tm_supv_group_t IS RECORD 
     (Group_Supervisor_Id          jtf_rs_resource_extns_vl.resource_id%TYPE              
     ,Supervisor_Group_Id	   jtf_rs_groups_vl.group_id%TYPE 
     ,Supervisor_Group_name	   jtf_rs_groups_vl.group_name%TYPE
     ,lt_tm_supv_grp_role_div_tbl  xx_tm_supv_grp_role_div_tab_t
    ) ;
    
  TYPE xx_tm_supv_group_tab_t IS TABLE OF xx_tm_supv_group_t INDEX BY PLS_INTEGER;
  lt_tm_supv_group_tbl        xx_tm_supv_group_tab_t;    
  
  --Resource group supervisor details
  TYPE xx_tm_res_grp_supv_t IS RECORD 
     (Resource_Group_Id	           jtf_rs_groups_vl.group_id%TYPE                
     ,Group_Supervisor_Id          jtf_rs_resource_extns_vl.resource_id%TYPE 
     ,Group_Supervisor_Name        jtf_rs_resource_extns_vl.resource_name%TYPE 
     ,lt_tm_supv_group_tbl         xx_tm_supv_group_tab_t
    ) ;
    
  TYPE xx_tm_res_grp_supv_tab_t IS TABLE OF xx_tm_res_grp_supv_t INDEX BY PLS_INTEGER;
  lt_tm_res_grp_supv_tbl        xx_tm_res_grp_supv_tab_t;   
  
  --Resource groups role division details
  TYPE xx_tm_res_grp_role_div_t IS RECORD 
     (Resource_Group_Id	           jtf_rs_groups_vl.group_id%TYPE                
     ,Resource_Sales_Role_Name     jtf_rs_group_mbr_role_vl.role_name%TYPE
     ,Resource_Division            jtf_rs_roles_b.attribute15%TYPE
     ,Resource_Legacy_Id           jtf_rs_role_relations.attribute15%TYPE
     ,lt_tm_res_grp_supv_tbl       xx_tm_res_grp_supv_tab_t
    ) ;
    
  TYPE xx_tm_res_grp_role_div_tab_t IS TABLE OF xx_tm_res_grp_role_div_t INDEX BY PLS_INTEGER;
  lt_tm_res_grp_role_div_tbl        xx_tm_res_grp_role_div_tab_t;  
  

  --Resource group details
  TYPE xx_tm_res_group_t IS RECORD 
     (Resource_Id	           jtf_rs_resource_extns_vl.resource_id%TYPE                  
     ,Resource_Group_Id            jtf_rs_groups_vl.group_id%TYPE
     ,Resource_Group_Name          jtf_rs_groups_vl.group_name%TYPE
     ,lt_tm_res_grp_role_div_tbl   xx_tm_res_grp_role_div_tab_t
     ) ;
    
  TYPE xx_tm_res_group_tab_t IS TABLE OF xx_tm_res_group_t INDEX BY PLS_INTEGER;
  lt_tm_res_group_tbl        xx_tm_res_group_tab_t;  
  
  --Resource details  
  TYPE xx_tm_rm_setup_t IS RECORD 
     (Employee_Number	           jtf_rs_resource_extns_vl.source_number%TYPE      
     ,Resource_Name	           jtf_rs_resource_extns_vl.resource_name%TYPE    
     ,User_Name	                   fnd_user.user_name%TYPE    
     ,Resource_Id	           jtf_rs_resource_extns_vl.resource_id%TYPE                  
     ,Sales_Resource_Type          VARCHAR2(20)
     ,Multiple_Groups              VARCHAR2(3)        --(Yes/No)
     ,Multiple_Roles               VARCHAR2(3)        --(Within a group) (Yes/No)
     ,No_Supervisor                VARCHAR2(3)        --(Within a group) (Yes/No)
     ,Multiple_Supervisors         VARCHAR2(3)        --(Within a group) (Yes/No)
     ,Multiple_Supervisor_Groups   VARCHAR2(3)        --(Yes/No)     
     ,lt_tm_res_group_tbl          xx_tm_res_group_tab_t
    ) ;
    
  TYPE xx_tm_rm_setup_tab_t IS TABLE OF xx_tm_rm_setup_t INDEX BY PLS_INTEGER;
  lt_tm_rm_setup_tbl        xx_tm_rm_setup_tab_t;
  
  
  -- ----------------------------------------------------------- 
  -- Get the Employee_Number,Resource Name,User Name,Resource Id
  -- ----------------------------------------------------------- 
  CURSOR   lcu_get_resource_details (p_resource_name IN jtf_rs_resource_extns_vl.resource_name%TYPE)
  IS
  SELECT   RES.source_number          employee_number
          ,RES.resource_name          resource_name
          ,USR.user_name              user_name
          ,RES.resource_id            resource_id
  FROM     jtf_rs_resource_extns_vl   RES
          ,fnd_user                   USR
          ,per_all_people_f           PPF
  WHERE    RES.source_id  = PPF.person_id
  AND      PPF.person_id  = USR.employee_id
  AND      RES.resource_name LIKE NVL(p_resource_name,'%')
  AND      SYSDATE BETWEEN PPF.effective_start_date AND NVL(PPF.effective_end_date,SYSDATE)
  AND      SYSDATE BETWEEN RES.start_date_active AND NVL(RES.end_date_active,SYSDATE+1)
  AND      SYSDATE BETWEEN USR.start_date AND NVL(USR.end_date,SYSDATE) 
  AND EXISTS ( SELECT   1
  	       FROM   jtf_rs_groups_vl         GRPNM 	  
  	             ,jtf_rs_group_mbr_role_vl GRP
  		     ,jtf_rs_group_usages      USAGES
  		     ,jtf_rs_roles_b           ROLS
  	       WHERE GRPNM.group_id    = GRP.group_id
  	       AND   SYSDATE BETWEEN NVL(GRP.start_date_active,SYSDATE - 1) AND NVL(GRP.end_date_active,SYSDATE + 1)
  	       --AND   USAGES.usage IN ('SALES','TELESALES')
  	       AND   USAGES.usage        = 'SALES'
  	       AND   GRP.group_id        = USAGES.group_id
  	       AND   ROLS.role_type_code = 'SALES'
  	       AND   GRP.role_id         = ROLS.role_id
  	       AND   GRP.resource_id     = RES.resource_id  
            )
  ORDER BY 2
  ;
  
  --Record to capture the values of cursor lcu_get_resource_details
  TYPE cur_res_dtls_t IS RECORD 
     (Employee_Number	           jtf_rs_resource_extns_vl.source_number%TYPE      
     ,Resource_Name	           jtf_rs_resource_extns_vl.resource_name%TYPE    
     ,User_Name	                   fnd_user.user_name%TYPE    
     ,Resource_Id	           jtf_rs_resource_extns_vl.resource_id%TYPE                  
    ) ;
    
  TYPE cur_res_dtls_tab_t IS TABLE OF cur_res_dtls_t INDEX BY PLS_INTEGER;
  lt_cur_res_dtls_tbl        cur_res_dtls_tab_t;

  
  -- -----------------------
  -- Get the resource groups
  --------------------------
  CURSOR lcu_get_res_groups (p_resource_id IN jtf_rs_resource_extns_vl.resource_id%TYPE)
  IS
  SELECT   GRP.group_id             group_id
   	  ,GRPNM.group_name         group_name
  FROM     jtf_rs_groups_vl         GRPNM 	  
   	  ,jtf_rs_group_mbr_role_vl GRP
  	  ,jtf_rs_group_usages      USAGES
  	  ,jtf_rs_roles_b           ROLS
  WHERE GRPNM.group_id    = GRP.group_id
  AND   SYSDATE BETWEEN NVL(GRP.start_date_active,SYSDATE - 1) AND NVL(GRP.end_date_active,SYSDATE + 1)
  --AND   USAGES.usage IN ('SALES','TELESALES')
  AND   USAGES.usage        = 'SALES'
  AND   GRP.group_id    = USAGES.group_id
  AND   ROLS.role_type_code = 'SALES'
  AND   GRP.role_id         = ROLS.role_id
  AND   GRP.resource_id = p_resource_id
  GROUP BY  GRP.group_id    
  	   ,GRPNM.group_name
  ;
  
  --Record to capture the values of cursor lcu_get_res_groups
  TYPE cur_get_res_groups_t IS RECORD 
     (Res_Group_Id            jtf_rs_groups_vl.group_id%TYPE    
     ,Res_Group_Name          jtf_rs_groups_vl.group_name%TYPE
     ) ;
    
  TYPE cur_get_res_grp_tab_t IS TABLE OF cur_get_res_groups_t INDEX BY PLS_INTEGER;
  lt_cur_get_res_groups_tbl     cur_get_res_grp_tab_t;
  
  -- -----------------------------------------
  -- Get the resource groups roles / divisions
  --------------------------------------------
  CURSOR lcu_get_res_groups_role (
                                   p_resource_id  IN jtf_rs_resource_extns_vl.resource_id%TYPE
                                  ,p_res_group_id IN jtf_rs_groups_vl.group_id%TYPE    
                                 )
  IS
  SELECT   ROLES.role_name          role_name             
   	  ,ROLES.attribute15        attribute15
   	  ,LEGACYID.attribute15     legacy_id
  FROM     jtf_rs_role_relations    LEGACYID
          ,jtf_rs_roles_vl          ROLES
   	  ,jtf_rs_group_usages      USAGES
  	  ,jtf_rs_group_mbr_role_vl GRP  	  
  WHERE GRP.resource_id       	= p_resource_id
  AND   GRP.group_id          	= p_res_group_id 
  AND   SYSDATE BETWEEN NVL(GRP.start_date_active,SYSDATE - 1) AND NVL(GRP.end_date_active,SYSDATE + 1)
  AND   USAGES.group_id         = GRP.group_id
  --AND   USAGES.usage          	IN ('SALES','TELESALES')
  AND   USAGES.usage        = 'SALES'
  AND   ROLES.role_id           = GRP.role_id
  --AND   ROLES.role_type_code 	IN  ('SALES','TELESALES')
  AND   ROLES.role_type_code = 'SALES'
  AND   LEGACYID.role_relate_id = GRP.role_relate_id 
  GROUP BY ROLES.role_name   
  	  ,ROLES.attribute15
  	  ,LEGACYID.attribute15;
  	     	   
  --Record to capture the values of cursor lcu_get_res_groups_role
  TYPE cur_get_res_grp_role_t IS RECORD 
     (	Res_Grp_Role_Name         jtf_rs_roles_vl.role_name%TYPE    
     ,	Res_Grp_Role_Div          jtf_rs_roles_vl.attribute15%TYPE
     ,  Res_Grp_Role_Lgcy_id      jtf_rs_role_relations.attribute15%TYPE
     ) ;
    
  TYPE xx_cur_get_res_grp_role_t IS TABLE OF cur_get_res_grp_role_t INDEX BY PLS_INTEGER;
  lt_cur_get_res_grp_role_tbl    xx_cur_get_res_grp_role_t;  
    
  -- ------------------------------------------
  -- Get the resource groups supervisor details
  ---------------------------------------------
  CURSOR lcu_get_grp_supv_rep (
                                  p_res_group_id IN jtf_rs_groups_vl.group_id%TYPE    
                                 )
  IS
  SELECT  RES.resource_name       supervisor_name
         ,MGR.resource_id         supervisor_id  
  FROM   jtf_rs_groups_vl         GRPNM
	,jtf_rs_resource_extns_vl RES
        ,jtf_rs_roles_vl          RLES
        ,jtf_rs_group_mbr_role_vl MGR
  WHERE  MGR.group_id          	= p_res_group_id
  AND    MGR.manager_flag      	= 'Y' 
  AND    SYSDATE BETWEEN NVL(MGR.start_date_active,SYSDATE - 1) AND NVL(MGR.end_date_active,SYSDATE + 1)
  AND    RLES.role_id          	= MGR.role_id
  --AND    RLES.role_type_code 	IN  ('SALES','TELESALES') 
  AND    RLES.role_type_code 	=  'SALES'
  AND    RES.resource_id       	= MGR.resource_id
  AND    GRPNM.group_id         = MGR.group_id
  AND EXISTS  ( SELECT 1
  		FROM jtf_rs_group_usages  USGS
    	        WHERE MGR.group_id    = USGS.group_id 
                --AND   USGS.USAGE IN ('SALES','TELESALES')
                AND   USGS.USAGE = 'SALES'
              )
  GROUP BY  RES.resource_name
  	   ,MGR.resource_id  
  ;
    
-- ------------------------------------------
  -- Get the managers groups supervisor details
  ---------------------------------------------
  CURSOR lcu_get_grp_supv_mgr (
                               p_res_group_id IN jtf_rs_groups_vl.group_id%TYPE    
                              )
  IS
  SELECT  RES.resource_name       supervisor_name
         ,MGR.resource_id         supervisor_id  
  FROM   jtf_rs_groups_vl         GRPNM
  	,jtf_rs_resource_extns_vl RES
        ,jtf_rs_roles_vl          RLES
  	,jtf_rs_group_mbr_role_vl MGR
        ,jtf_rs_grp_relations_vl  GR
  WHERE  GR.group_id          	= p_res_group_id
  AND    SYSDATE BETWEEN NVL(GR.start_date_active,SYSDATE - 1) AND NVL(GR.end_date_active,SYSDATE + 1)
  AND	 nvl(delete_flag,'N')    = 'N'
  AND	 MGR.group_id 		 = GR.related_group_id
  AND    MGR.manager_flag      	 = 'Y' 
  AND    SYSDATE BETWEEN NVL(MGR.start_date_active,SYSDATE - 1) AND NVL(MGR.end_date_active,SYSDATE + 1)
  AND    RLES.role_id          	= MGR.role_id
  --AND    RLES.role_type_code 	IN  ('SALES','TELESALES')
  AND    RLES.role_type_code 	= 'SALES'
  AND    RES.resource_id       	= MGR.resource_id
  AND    GRPNM.group_id         = MGR.group_id
  AND EXISTS  ( SELECT 1
    		FROM jtf_rs_group_usages  USGS
      	        WHERE MGR.group_id    = USGS.group_id 
                --AND   USGS.USAGE IN ('SALES','TELESALES')
                AND   USGS.USAGE  = 'SALES'
                )
  GROUP BY  RES.resource_name
    	   ,MGR.resource_id  
  ;
  
  
  --Record to capture the values of cursor lcu_get_grp_supv_rep / lcu_get_grp_supv_mgr
  TYPE cur_get_res_grp_supv_t IS RECORD 
       (
        Res_Grp_Supv_Name         jtf_rs_resource_extns_vl.resource_name%TYPE    
       ,Res_Grp_Supv_Id           jtf_rs_resource_extns_vl.resource_name%TYPE
       ) ;
      
  TYPE xx_cur_get_res_grp_supv_t IS TABLE OF cur_get_res_grp_supv_t INDEX BY PLS_INTEGER;
  lt_cur_get_res_grp_supv_tbl    xx_cur_get_res_grp_supv_t; 
  

  -- ---------------------------------
  -- Get the supervisors group details
  ------------------------------------
  CURSOR lcu_get_supv_groups (
                               p_supv_id IN jtf_rs_resource_extns_vl.resource_id%TYPE    
                             )
  IS
  SELECT  MGR.group_id            group_id
         ,GRPNM.group_name        group_name  
  FROM   jtf_rs_group_mbr_role_vl MGR
        ,jtf_rs_roles_vl          RLES
        ,jtf_rs_resource_extns_vl RES
        ,jtf_rs_groups_vl         GRPNM
  WHERE  MGR.role_id           = RLES.role_id
  AND    MGR.manager_flag      = 'Y' 
  AND    MGR.resource_id       = p_supv_id
  AND    MGR.resource_id       = RES.resource_id
  --AND    RLES.role_type_code IN  ('SALES','TELESALES') 
  AND    RLES.role_type_code = 'SALES'
  AND    MGR.group_id          = GRPNM.group_id
  AND    SYSDATE BETWEEN NVL(MGR.start_date_active,SYSDATE - 1) AND NVL(MGR.end_date_active,SYSDATE + 1)
  AND EXISTS  ( SELECT 1
  		FROM jtf_rs_group_usages  USGS
    	        WHERE MGR.group_id    = USGS.group_id 
                --AND   USGS.USAGE IN ('SALES','TELESALES')
                AND   USGS.USAGE = 'SALES'
              )
  GROUP BY  MGR.group_id    
  	   ,GRPNM.group_name
  ;              
    
  --Record to capture the values of cursor lcu_get_supv_groups
  TYPE cur_get_supv_grp_t IS RECORD 
       (
        Supv_Grp_id         jtf_rs_group_mbr_role_vl.group_id%TYPE    
       ,Supv_Grp_Name       jtf_rs_groups_vl.group_name%TYPE    
       ) ;
      
  TYPE xx_cur_get_supv_grp_t IS TABLE OF cur_get_supv_grp_t INDEX BY PLS_INTEGER;
  lt_cur_get_supv_grp_tbl    xx_cur_get_supv_grp_t; 


  -- --------------------------------------------
  -- Get the supervisor groups role and divisions
  -----------------------------------------------
  CURSOR lcu_get_supv_grp_role (
                                 p_supv_group_id IN jtf_rs_group_mbr_role_vl.group_id%TYPE  
                                ,p_supv_id  	 IN jtf_rs_resource_extns_vl.resource_id%TYPE 
                               )
  IS
  SELECT  NVL(RLES.role_name,'--')          role_name
         ,NVL(RLES.attribute15,'--')        attribute15  -- OD Division
         ,NVL(RLES.attribute14,'--')        attribute14  -- OD Role
  FROM   jtf_rs_group_mbr_role_vl MGR
        ,jtf_rs_roles_vl          RLES
        ,jtf_rs_resource_extns_vl RES
        ,jtf_rs_groups_vl         GRPNM
  WHERE  MGR.group_id          = p_supv_group_id
  AND    MGR.resource_id       = p_supv_id
  AND    MGR.manager_flag      = 'Y' 
  AND    SYSDATE BETWEEN NVL(MGR.start_date_active,SYSDATE - 1) AND NVL(MGR.end_date_active,SYSDATE + 1)
  AND	 MGR.role_id           = RLES.role_id
  AND    MGR.resource_id       = RES.resource_id
  --AND    RLES.role_type_code IN  ('SALES','TELESALES')
  AND    RLES.role_type_code = 'SALES'
  AND    MGR.group_id          = GRPNM.group_id
  AND    EXISTS  ( SELECT 1
  		FROM jtf_rs_group_usages  USGS
    	        WHERE MGR.group_id    = USGS.group_id 
                --AND   USGS.USAGE IN ('SALES','TELESALES')
                AND   USGS.USAGE = 'SALES'
              )
  GROUP BY  RLES.role_name  
  	   ,RLES.attribute15
  	   ,RLES.attribute14
  ;              
    
  --Record to capture the values of cursor lcu_get_supv_groups
  TYPE cur_get_supv_grp_role_t IS RECORD 
       (
        Supv_Grp_Role       jtf_rs_roles_vl.role_name%TYPE    
       ,Supv_Grp_Role_Div   jtf_rs_roles_vl.attribute15%TYPE
       ,Supv_Grp_Role_Code  jtf_rs_roles_vl.attribute14%TYPE
       ) ;
      
  TYPE xx_cur_get_supv_grp_role_t IS TABLE OF cur_get_supv_grp_role_t INDEX BY PLS_INTEGER;
  lt_cur_get_supv_grp_role_tbl    xx_cur_get_supv_grp_role_t; 


  -- -----------------------------------------------------------------------------------------
  -- Declaring public procedures
  --------------------------------------------------------------------------------------------
  PROCEDURE Resource_Mgr_Setup_Main
                                 ( x_errbuf       OUT NOCOPY  VARCHAR2 
          		          ,x_retcode      OUT NOCOPY  NUMBER
          		          ,p_resource_name IN jtf_rs_resource_extns_vl.resource_name%TYPE
          		         ) ;
     
END XX_JTF_RM_SETUP_REPORT_PKG;
/

SHOW ERRORS
--EXIT;
