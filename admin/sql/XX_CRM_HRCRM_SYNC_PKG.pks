SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_CRM_HRCRM_SYNC_PKG package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_CRM_HRCRM_SYNC_PKG
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
  -- +===================================================================================+
  -- |                                                                                   |
  -- | Name             :  XX_CRM_HRCRM_SYNC_PKG                                         |
  -- | Description      :  This custom package is needed to maintain Oracle CRM resources|
  -- |                     synchronized with changes made to employees in Oracle HRMS    |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |                                                                                   |
  -- | This package contains the following sub programs:                                 |
  -- | =================================================                                 |
  -- |Type         Name             Description                                          |
  -- |=========    ===========      =====================================================|
  -- |PROCEDURE    Main             This is the public procedure.The concurrent program  |
  -- |                              OD HR CRM Synchronization Program will call this     |
  -- |                              public procedure which inturn will call another      |
  -- |                              public procedure.                                    |
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date        Author                       Remarks                         |
  -- |=======   ==========  ==========================   ================================|
  -- |Draft 1a  07-Jun-07   Prem Kumar                   Initial draft version           |
  -- |Draft 1b  17-Dec-07   Gowri Nagarajan              Added  p_init_msg_list parameter|
  -- |                                                   in PROCESS_RESOURCES Procedure  |
  -- |Draft 1c  25-Jul-08   Gowri Nagarajan              Added  p_hierarchy_type 	 |
  -- |                                                   parameter to the MAIN and 	 |
  -- |                                                   PROCESS_RESOURCES proc		 |
  -- +===================================================================================+

  AS

      -- +===================================================================+
      -- | Name  : MAIN                                                      |
      -- |                                                                   |
      -- | Description:       This is the public procedure.The concurrent    |
      -- |                    program OD HR CRM Synchronization Program      |
      -- |                    will call this public procedure which inturn   |
      -- |                    will call another public procedure.            |
      -- |                                                                   |
      -- +===================================================================+  

      PROCEDURE MAIN
                   (
                     x_errbuf           OUT   VARCHAR2
                   , x_retcode          OUT   NUMBER
                   , p_person_id        IN    NUMBER
                   , p_as_of_date       IN    DATE
                   , p_hierarchy_type   IN    VARCHAR2 -- 24/07/08
                   );

      -- +===================================================================+
      -- | Name  : PROCESS_RESOURCES                                         |
      -- |                                                                   |
      -- | Description:       This Procedure is responsible to Create/Update |
      -- |                    Resources in Resource Manager based on employee|
      -- |                    data in Oracle HRMS as well as Create /Assigns |
      -- |                    Roles,Groups and Group Memberships to these    |
      -- |                    Resources                                      |
      -- |                                                                   |
      -- +===================================================================+                   

   PROCEDURE PROCESS_RESOURCES
                     (p_person_id               IN          NUMBER
                     ,p_as_of_date              IN          DATE
                     ,p_write_debug_to_log      IN          VARCHAR2   DEFAULT  FND_API.G_FALSE
                     ,p_init_msg_list           IN          VARCHAR2   DEFAULT  FND_API.G_FALSE
                     ,p_hierarchy_type          IN          VARCHAR2 -- 24/07/08
                     ,x_resource_id             OUT NOCOPY  NUMBER
                     ,x_return_status           OUT NOCOPY  VARCHAR2
                     ,x_msg_count               OUT NOCOPY  NUMBER
                     ,x_msg_data                OUT NOCOPY  VARCHAR2
                     );
                   
      -- +===================================================================+
      -- | Name  : UPDATE_EMAIL                                              |
      -- |                                                                   |
      -- | Description:       This is a public procedure, expected to be     |
      -- |                    called as an API and during resource creation  |
      -- |                    and updation. An explicit commit needs to be   |
      -- |                    provided in the calling procedure.  This shall |
      -- |                    check if the parameters are null, if not, it   |      
      -- |                    will call the update API.                      |
      -- |                                                                   |
      -- | Parameters:        Resource Id: Of the resource, for which email  |
      -- |                                 has to be updated.                |      
      -- |                    Resource Number:Of the resource, for which     |
      -- |                                    email has to be updated.       |      
      -- |                    Obj Ver Number:Of the resource, for which      |      
      -- |                                    email has to be updated.       |
      -- |                    Email Address: Of the resource.                |
      -- |                                                                   |
      -- |                                                                   |
      -- +===================================================================+                   
      
--      PROCEDURE UPDATE_EMAIL
--                   (p_salesrep_id             IN  NUMBER
--                   ,p_sales_credit_type_id    IN  NUMBER
--                   ,p_org_id                  IN  NUMBER
--                   ,p_object_version_number   IN  NUMBER
--                   ,p_email_address           IN  VARCHAR2
--                   ,p_init_msg_list           IN  VARCHAR2   DEFAULT  FND_API.G_FALSE                   
--                   ,x_return_status          OUT  VARCHAR2
--                   ,x_msg_count              OUT  NUMBER 
--                   ,x_msg_data               OUT  VARCHAR2 
--                   );


   PROCEDURE UPDATE_EMAIL
             (p_resource_id             IN  NUMBER
             ,p_init_msg_list           IN  VARCHAR2   DEFAULT  FND_API.G_FALSE
             ,x_return_status          OUT  VARCHAR2
             ,x_msg_count              OUT  NUMBER 
             ,x_msg_data               OUT  VARCHAR2 
             );               

  END XX_CRM_HRCRM_SYNC_PKG;     /* Package Specification Ends */
/

SHOW ERRORS;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
