SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_CRM_HRCRM_CLEANSE_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_CRM_HRCRM_CLEANSE_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CRM_HRCRM_CLEANSE_PKG                                       |
  -- | Description      :  This custom package is needed to delete the Oracle CRM         |
  -- |                     resource roles,group membership,group member roles,group roles |
  -- |                     and parent child relations                                     |
  -- |                                                                                    |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  26-May-08   Gowri Nagarajan  Initial draft version                        |
  -- |Draft 1b  05-Jun-08   Gowri Nagarajan  Changed the code for the savepoint error     |
  -- |Draft 1c  25-Jun-08   Gowri Nagarajan  Changed the code to nullify the CRM DFF dates|
  -- |Draft 1d  31-Jul-08   Gowri Nagarajan  Added Role Type Code and Group Usage for     |
  -- |                                       Collection records				  |
  -- +====================================================================================+
IS
   ----------------------------
   --Declaring Global Constants
   ----------------------------
   GC_APPN_NAME                CONSTANT VARCHAR2(30):= 'XXCRM';
   GC_PROGRAM_TYPE             CONSTANT VARCHAR2(40):= 'E1002_HR_CRM_Synchronization';
   GC_MODULE_NAME              CONSTANT VARCHAR2(30):= 'TM';
   GC_ERROR_STATUS             CONSTANT VARCHAR2(30):= 'ACTIVE';
   GC_NOTIFY_FLAG              CONSTANT VARCHAR2(1) :=  'Y';

   -- ---------------------------
   -- Global Variable Declaration
   -- ---------------------------
   
   gd_as_of_date               DATE                                                        ;
   gc_errbuf                   VARCHAR2(2000)                                              ;
   gn_biz_grp_id               NUMBER      := FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID')   ;

   gc_conc_prg_id              NUMBER                    DEFAULT   -1                      ;
   gc_err_msg                  CLOB;

   gn_msg_cnt_get              NUMBER;
   gn_msg_cnt                  NUMBER;
   gc_msg_data                 CLOB;


   -- +===================================================================+
   -- | Name  : WRITE_LOG                                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall write to the concurrent   |
   -- |                    program log.                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE WRITE_LOG (p_message IN VARCHAR2)

   IS

      lc_error_message VARCHAR2(2000);

   BEGIN

      fnd_file.put_line(fnd_file.log,p_message);      

   EXCEPTION

      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',29)||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_DELETE_ROL_PKG.WRITE_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_DELETE_ROL_PKG.WRITE_LOG'
                                  ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );

   END; 

   -- +===================================================================+
   -- | Name  : WRITE_OUT                                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall write to the concurrent   |
   -- |                    program output.                                |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE WRITE_OUT (p_message IN VARCHAR2)
   IS

      lc_error_message  varchar2(2000);

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);      

   EXCEPTION

      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error when writing output ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',29)||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.WRITE_OUT'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.WRITE_OUT'
                                  ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
   END;

   -- +===================================================================+
   -- | Name  : DELETE_RES_GROUP_ROLE                                     |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    deleting the roles to the members of the       |
   -- |                    group.                                         |
   -- +===================================================================+

   PROCEDURE DELETE_RES_GROUP_ROLE
                 (
                 p_api_version        IN  NUMBER
                ,p_commit             IN  VARCHAR2
                ,p_group_id           IN  jtf_rs_group_mbr_role_vl.group_id%TYPE
                ,p_resource_id        IN  jtf_rs_resource_extns.resource_id%TYPE
                ,p_group_member_id    IN  jtf_rs_group_mbr_role_vl.group_member_id%TYPE
                ,p_role_relate_id     IN  jtf_rs_group_mbr_role_vl.role_relate_id%TYPE
                ,p_object_version_num IN  jtf_rs_role_relations.object_version_number%TYPE
                ,x_return_status      OUT NOCOPY  VARCHAR2
                ,x_msg_count          OUT NOCOPY  NUMBER
                ,x_msg_data           OUT NOCOPY  VARCHAR2
                 )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

   BEGIN

      WRITE_LOG('Inside Proc: DELETE_RES_GROUP_ROLE');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;


      -- ---------------------
      -- CRM Standard API call
      -- ---------------------

      JTF_RS_GRP_MEMBERSHIP_PUB.delete_group_membership
               (
               p_api_version        => p_api_version
              ,p_commit             => p_commit
              ,p_group_id           => p_group_id
              ,p_resource_id        => p_resource_id
              ,p_group_member_id    => p_group_member_id
              ,p_role_relate_id     => p_role_relate_id
              ,p_object_version_num => p_object_version_num
              ,x_return_status      => x_return_status
              ,x_msg_count          => x_msg_count
              ,x_msg_data           => x_msg_data
               );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN


         lc_return_mesg := NULL;
         ln_cnt         := 0;

         FOR i IN gn_msg_cnt..x_msg_count
         LOOP
            ln_cnt := ln_cnt +1;
            v_data :=fnd_msg_pub.get(
                                    p_msg_index => i
                                  , p_encoded   => FND_API.G_FALSE
                                    );
                                    
            v_data := 'Group Membership Role with the Role Relate Id: '||p_role_relate_id||CHR(10)||RPAD(' ',31)||v_data;
            
            IF ln_cnt = 1 THEN
               lc_return_mesg := v_data;
               x_msg_data     := v_data;
            ELSE
               x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
               lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',31)|| v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',31)||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;

   END DELETE_RES_GROUP_ROLE;


   -- +===================================================================+
   -- | Name  : DELETE_GRP_MBRSHIP                                        |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    assigning the resource to the group.           |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE DELETE_GRP_MBRSHIP
                       (
                         p_api_version           IN  NUMBER
                       , p_commit                IN  VARCHAR2
                       , p_group_id              IN  jtf_rs_group_members.group_id%TYPE
                       , p_group_number          IN  jtf_rs_groups_vl.group_number%TYPE
                       , p_resource_id           IN  jtf_rs_group_members.resource_id%TYPE
                       , p_resource_number       IN  jtf_rs_resource_extns.resource_number%TYPE
                       , p_object_version_number IN  jtf_rs_group_members.object_version_number%TYPE
                       , x_return_status         OUT NOCOPY  VARCHAR2
                       , x_msg_count             OUT NOCOPY  NUMBER
                       , x_msg_data              OUT NOCOPY  VARCHAR2
                       )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt              NUMBER ;
      lc_return_mesg      VARCHAR2(5000);
      v_data              VARCHAR2(5000);
      ln_group_member_id  jtf_rs_group_members.group_member_id%TYPE;         
 

       -- -----------------------
       -- Get the Group Member Id
       -- -----------------------
       CURSOR lcu_get_grp_mbr_id
       IS
       SELECT group_member_id       
       FROM   jtf_rs_group_members
       WHERE  resource_id  = p_resource_id
       AND    group_id     = p_group_id;

   BEGIN
       
       WRITE_LOG('Inside Proc: DELETE_GRP_MBRSHIP');

       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;      

       -- ---------------------
       -- CRM Standard API call
       -- ---------------------

       JTF_RS_GROUP_MEMBERS_PUB.delete_resource_group_members
                     (
                    p_api_version       => p_api_version
                   ,p_commit            => p_commit
                   ,p_group_id          => p_group_id
                   ,p_group_number      => p_group_number
                   ,p_resource_id       => p_resource_id
                   ,p_resource_number   => p_resource_number
                   ,p_object_version_num=> p_object_version_number
                   ,x_return_status     => x_return_status
                   ,x_msg_count         => x_msg_count
                   ,x_msg_data          => x_msg_data
                     );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          lc_return_mesg := NULL;
          ln_cnt         := 0;

          FOR i IN gn_msg_cnt..x_msg_count
          LOOP
             ln_cnt := ln_cnt +1;
             v_data :=fnd_msg_pub.get(
                                     p_msg_index => i
                                   , p_encoded   => FND_API.G_FALSE
                                     );
             
             OPEN    lcu_get_grp_mbr_id;
	     FETCH   lcu_get_grp_mbr_id INTO ln_group_member_id;
             CLOSE   lcu_get_grp_mbr_id;         
                                      
             v_data := 'Group Membership with the Group Member Id: '||ln_group_member_id||CHR(10)||RPAD(' ',31)||v_data;
             
             IF ln_cnt = 1 THEN
                lc_return_mesg := v_data;
                x_msg_data     := v_data;
             ELSE
                x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
                lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',31)|| v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',31)||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

       END IF;

   END DELETE_GRP_MBRSHIP;

   -- +===================================================================+
   -- | Name  : DELETE_RESOURCE_ROLE                                      |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    deletion of role to the resource assignment    |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE DELETE_RESOURCE_ROLE
                 (
                  p_api_version         IN  NUMBER
                 ,p_commit              IN  VARCHAR2
                 ,p_role_relate_id      IN  jtf_rs_role_relations.role_relate_id%TYPE
                 ,p_object_version_num  IN  jtf_rs_role_relations.object_version_number%TYPE
                 ,x_return_status       OUT NOCOPY  VARCHAR2
                 ,x_msg_count           OUT NOCOPY  NUMBER
                 ,x_msg_data            OUT NOCOPY  VARCHAR2
                 )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

   BEGIN


      WRITE_LOG('Inside Proc: DELETE_RESOURCE_ROLE');       

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;


      -- ---------------------
      -- CRM Standard API call
      -- ---------------------


      JTF_RS_ROLE_RELATE_PUB.delete_resource_role_relate
                    (
                    p_api_version       => p_api_version
                   ,p_commit            => p_commit
                   ,p_role_relate_id    => p_role_relate_id
                   ,p_object_version_num=> p_object_version_num
                   ,x_return_status     => x_return_status
                   ,x_msg_count         => x_msg_count
                   ,x_msg_data          => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         lc_return_mesg := NULL;
         ln_cnt         := 0;

         FOR i IN gn_msg_cnt..x_msg_count
         LOOP
            ln_cnt := ln_cnt +1;
            v_data :=fnd_msg_pub.get(
                                    p_msg_index => i
                                  , p_encoded   => FND_API.G_FALSE
                                    );
                                    
            v_data := 'Resource Role with the Role Relate Id: '||p_role_relate_id||CHR(10)||RPAD(' ',31)||v_data;                                    
                                    
            IF ln_cnt = 1 THEN
               lc_return_mesg := v_data;
               x_msg_data     := v_data;
            ELSE
               x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
               lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',31)|| v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',31)||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;


   END DELETE_RESOURCE_ROLE;

   -- +===================================================================+
   -- | Name  : DELETE_GROUP_ROLE                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    deleting the roles to the group assignment.    |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE DELETE_GROUP_ROLE(
                        p_api_version        IN  NUMBER
                       ,p_commit             IN	 VARCHAR2
                       ,p_role_relate_id     IN	 jtf_rs_role_relations.role_relate_id%TYPE
                       ,p_object_version_num IN	 jtf_rs_role_relations.object_version_number%TYPE
                       ,x_return_status      OUT NOCOPY  VARCHAR2
                       ,x_msg_count          OUT NOCOPY  NUMBER
                       ,x_msg_data           OUT NOCOPY  VARCHAR2
   			    )
  AS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_role_code            JTF_RS_ROLES_VL.role_code% TYPE;
      lc_role_resource_type   JTF_RS_ROLE_RELATIONS.role_resource_type%TYPE := 'RS_GROUP';
      lc_error_message        VARCHAR2(1000);
      ln_role_relate_id       JTF_RS_ROLE_RELATIONS.role_relate_id%TYPE;
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


   BEGIN

      WRITE_LOG('Inside Proc: DELETE_GROUP_ROLE');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;


     JTF_RS_ROLE_RELATE_PUB.delete_resource_role_relate
                   (
                   p_api_version       => p_api_version
                  ,p_commit            => p_commit
                  ,p_role_relate_id    => p_role_relate_id
                  ,p_object_version_num=> p_object_version_num
                  ,x_return_status     => x_return_status
                  ,x_msg_count         => x_msg_count
                  ,x_msg_data          => x_msg_data
                  );


        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          lc_return_mesg := NULL;
          ln_cnt         := 0;

          FOR i IN gn_msg_cnt..x_msg_count
          LOOP
             ln_cnt := ln_cnt +1;
             v_data :=fnd_msg_pub.get(
                                     p_msg_index => i
                                   , p_encoded   => FND_API.G_FALSE
                                     );
                                     
             v_data := 'Group Role with the Role Relate Id: '||p_role_relate_id||CHR(10)||RPAD(' ',31)||v_data;
                                     
             IF ln_cnt = 1 THEN
                lc_return_mesg := v_data;
                x_msg_data     := v_data;
             ELSE
                x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
                lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',31)|| v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',31)||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

        END IF;

   END DELETE_GROUP_ROLE;
   
   -- +===================================================================+
   -- | Name  : DELETE_GROUP_RELATIONS                                    |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    deleting the roles to the group assignment.    |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE DELETE_GROUP_RELATIONS(
                        p_api_version        IN  NUMBER
                       ,p_commit             IN	 VARCHAR2
                       ,p_group_relate_id    IN	 jtf_rs_grp_relations.group_relate_id%TYPE
                       ,p_object_version_num IN	 jtf_rs_grp_relations.object_version_number%TYPE
                       ,x_return_status      OUT NOCOPY  VARCHAR2
                       ,x_msg_count          OUT NOCOPY  NUMBER
                       ,x_msg_data           OUT NOCOPY  VARCHAR2
   			    )
  AS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
 
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


   BEGIN

      WRITE_LOG('Inside Proc: DELETE_GROUP_RELATIONS');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;


      JTF_RS_GROUP_RELATE_PUB.delete_resource_group_relate
                   (
                   p_api_version       => p_api_version
                  ,p_commit            => p_commit
                  ,p_group_relate_id   => p_group_relate_id
                  ,p_object_version_num=> p_object_version_num
                  ,x_return_status     => x_return_status
                  ,x_msg_count         => x_msg_count
                  ,x_msg_data          => x_msg_data
                  );


        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          lc_return_mesg := NULL;
          ln_cnt         := 0;

          FOR i IN gn_msg_cnt..x_msg_count
          LOOP
             ln_cnt := ln_cnt +1;
             v_data :=fnd_msg_pub.get(
                                     p_msg_index => i
                                   , p_encoded   => FND_API.G_FALSE
                                     );
                                     
             v_data := 'Group Relations with the Group Relate Id: '||p_group_relate_id||CHR(10)||RPAD(' ',31)||v_data;                       
             
             IF ln_cnt = 1 THEN
                lc_return_mesg := v_data;
                x_msg_data     := v_data;
             ELSE
                x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
                lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',31)|| v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',31)||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

        END IF;

   END DELETE_GROUP_RELATIONS;      
   -- Added on 25/06/08
   -- +===================================================================+
   -- | Name  : UPDT_DATES_RESOURCE                                       |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    update the dates on the resource.              |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE UPDT_DATES_RESOURCE
                 ( p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_resource_number    IN  jtf_rs_resource_extns_vl.resource_number%TYPE
                 , p_source_name        IN  jtf_rs_resource_extns_vl.source_name%TYPE
                 , p_attribute14        IN  jtf_rs_resource_extns_vl.attribute14%TYPE
                 , p_attribute15        IN  jtf_rs_resource_extns_vl.attribute15%TYPE
                 , p_object_version_num IN  jtf_rs_resource_extns_vl.object_version_number%TYPE
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 )
   IS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------
       ln_object_version_num         NUMBER := p_object_version_num;
       ln_cnt                        NUMBER ;
       lc_return_mesg                VARCHAR2(5000);
       v_data                        VARCHAR2(5000);


   BEGIN

       WRITE_LOG('Inside Proc: UPDT_DATES_RESOURCE');
       
       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;       

       -- ---------------------
       -- CRM Standard API call
       -- ---------------------

       JTF_RS_RESOURCE_PUB.update_resource
                    (
                      p_api_version         => 1.0
                    , p_commit              => 'T'
                    , p_init_msg_list       => fnd_api.G_FALSE
                    , p_resource_id         => p_resource_id
                    , p_resource_number     => p_resource_number
                    , p_source_name         => p_source_name
                    , p_attribute14         => p_attribute14
                    , p_attribute15         => p_attribute15
                    , p_object_version_num  => ln_object_version_num
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          
          lc_return_mesg := NULL;
          ln_cnt         := 0;

          FOR i IN gn_msg_cnt..x_msg_count
          LOOP
             ln_cnt := ln_cnt +1;
             v_data :=fnd_msg_pub.get(
                                     p_msg_index => i
                                   , p_encoded   => FND_API.G_FALSE
                                     );
             IF ln_cnt = 1 THEN
                lc_return_mesg := v_data;
                x_msg_data     := v_data;
             ELSE
                x_msg_data     := lc_return_mesg||CHR(10)|| v_data;
                lc_return_mesg := lc_return_mesg||CHR(10)||RPAD(' ',58)|| v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',58)||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;          

       END IF;

   END UPDT_DATES_RESOURCE;   
   -- Added on 25/06/08
   
   -- +===================================================================+
   -- | Name  : MAIN                                                      |
   -- |                                                                   |
   -- | Description:       This is the public procedure.The concurrent    |
   -- |                    program OD: CRM HRCRM Cleanse Program          |
   -- |                    will call this public procedure which inturn   |
   -- |                    will call the respective APIS                  |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE MAIN
                 (x_errbuf       OUT VARCHAR2
                 ,x_retcode      OUT NUMBER
                 ,p_person_id    IN  NUMBER                
                 )
   IS
      
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lc_return_status         VARCHAR2(5);
      ln_msg_count             PLS_INTEGER;
      lc_msg_data              VARCHAR2(1000);

      x_return_status          VARCHAR2(5);
      x_msg_count	       NUMBER;
      x_msg_data	       VARCHAR2(32000);

      ln_grp_mbr_role_suc_tot  NUMBER := 0;
      ln_grp_mbr_suc_tot       NUMBER := 0;
      ln_res_rol_suc_tot       NUMBER := 0;
      ln_grp_rol_suc_tot       NUMBER := 0; 
      ln_grp_rel_suc_tot       NUMBER := 0;
      ln_date_del_suc_tot      NUMBER := 0;-- 25/06/08

      ln_grp_mbr_role_suc      NUMBER ;
      ln_grp_mbr_suc           NUMBER ;
      ln_res_rol_suc           NUMBER ;
      ln_grp_rol_suc           NUMBER ;
      ln_grp_rel_suc           NUMBER ; 
      ln_date_del_suc          NUMBER ; -- 25/06/08
      
      ln_grp_mbr_role_err      NUMBER ;
      ln_grp_mbr_err           NUMBER ;
      ln_res_rol_err           NUMBER ;
      ln_grp_rol_err           NUMBER ;  
      ln_grp_rel_err           NUMBER ;
      ln_date_del_err          NUMBER ;-- 25/06/08

      lc_grp_mbr_role_flg      VARCHAR2(1):= 'N';
      lc_grp_mbr_flg           VARCHAR2(1):= 'N';
      lc_res_rol_flg           VARCHAR2(1):= 'N';
      lc_grp_rol_flg           VARCHAR2(1):= 'N';
      lc_grp_rel_flg           VARCHAR2(1):= 'N';-- 25/06/08
      
      lc_grp_mbr_role_commit_flg      VARCHAR2(1) ;
      lc_grp_mbr_commit_flg           VARCHAR2(1) ;
      lc_res_rol_commit_flg           VARCHAR2(1) ;
      lc_grp_rol_commit_flg           VARCHAR2(1) ;
      lc_grp_rel_commit_flg           VARCHAR2(1) ;
      lc_date_del_commit_flg          VARCHAR2(1) ;
      


      -- --------------------------------------------------------------------
      -- Cursor declaration to get all the resources reporting to the manager
      -- --------------------------------------------------------------------

      CURSOR lcu_get_resources
      IS
      SELECT JRRE.resource_id
            ,JRRE.source_id 
      FROM
     	(SELECT   PAAF.person_id      PERSON_ID
                , PAAF.ass_attribute9
     		, PAAF.supervisor_id
     		, PAAF.business_group_id
     	 FROM   ( SELECT *
     		  FROM per_all_assignments_f p1
     		  WHERE  trunc(SYSDATE) BETWEEN p1.effective_start_date
     		  AND  DECODE(
     		             (SELECT  system_person_type
     			      FROM    per_person_type_usages_f p
     			            , per_person_types         ppt
     			      WHERE   TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date
     			      AND     PPT. person_type_id   =  p.person_type_id
     			      AND     p.person_id           =  p1.person_id
     			      AND     PPT.business_group_id =  gn_biz_grp_id),
     			      'EX_EMP',TRUNC(SYSDATE),'EMP', p1.effective_end_date)
     	        ) PAAF
     	      , ( SELECT *
     		  FROM per_all_people_f p
     		  WHERE  SYSDATE BETWEEN p.effective_start_date AND p.effective_end_date
     	        ) PAPF
     	       ,  per_person_types         PPT
     	       , (SELECT *
     	          FROM per_person_type_usages_f p
     	          WHERE SYSDATE BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
         WHERE    PAAF.person_id               = PAPF.person_id
         AND      PAPF.person_id               = PPTU.person_id
         AND      PPT. person_type_id          = PPTU.person_type_id
         AND     (PPT.system_person_type       = 'EMP'
         OR       PPT.system_person_type       = 'EX_EMP')
         AND      PAAF.business_group_id       = gn_biz_grp_id
         AND      PAPF.business_group_id       = gn_biz_grp_id
         AND      PPT .business_group_id       = gn_biz_grp_id
         CONNECT BY PRIOR PAAF.person_id       = PAAF.supervisor_id
         START WITH     PAAF.person_id         = p_person_id
     	 ) t
        , jtf_rs_resource_extns_vl  JRRE
      WHERE t.person_id = JRRE.source_id;

      
      TYPE employee_details_tbl_type IS TABLE OF lcu_get_resources%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_employee_details employee_details_tbl_type;

      
      -- ----------------------------------------------------
      -- Cursor Declaration to get all the group member roles
      -- ----------------------------------------------------
      
      CURSOR lcu_get_grp_mbr_role_dtls(p_resource_id IN jtf_rs_resource_extns.resource_id%TYPE)
      IS
      SELECT JRRR.role_relate_id
            ,JRRR.object_version_number
            ,JRGM.group_member_id
            ,JRGM.group_id
      FROM   jtf_rs_role_relations  JRRR
            ,jtf_rs_group_members   JRGM                           
      WHERE  JRRR.role_resource_id = JRGM.group_member_id                 
      AND    JRRR.role_id IN 
                            (SELECT role_id
                             FROM   jtf_rs_roles_vl JRRV                             
                             WHERE  JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')-- 31/07/08
                             )
      AND    NVL(JRRR.attribute15,'N') <> 'CLEANUP'
      AND    JRGM.group_id IN 
                            (SELECT group_id
                             FROM   jtf_rs_group_usages
                             WHERE  usage IN ('SALES_COMP','COMP_PAYMENT','SALES','IEX_COLLECTIONS')-- 31/07/08
                            )
      AND    JRRR.role_resource_type    = 'RS_GROUP_MEMBER'
      AND    JRRR.delete_flag           = 'N'
      AND    JRGM.delete_flag           = 'N'
      AND    JRGM.resource_id           =  p_resource_id;

      -- ---------------------------------------------------
      -- Cursor Declaration to get all the group memberships
      -- ---------------------------------------------------
      
      CURSOR lcu_get_grp_mbr_dtls(p_resource_id IN jtf_rs_resource_extns.resource_id%TYPE)
      IS
      SELECT JRGM.group_id
            ,JRGV.group_number
            ,JRGM.object_version_number
            ,JRRE.resource_number
      FROM   jtf_rs_resource_extns_vl  JRRE
            ,jtf_rs_groups_vl          JRGV
            ,jtf_rs_group_members      JRGM            
      WHERE  JRRE.resource_id = JRGM.resource_id      
      AND    JRGM.group_id    = JRGV.group_id
      AND    JRGM.delete_flag = 'N'      
      AND    JRGM.group_id IN 
                            (SELECT group_id
                             FROM   jtf_rs_group_usages
                             WHERE  usage IN ('SALES_COMP','COMP_PAYMENT','SALES','IEX_COLLECTIONS')-- 31/07/08
                            )
      AND    JRRE.resource_id = p_resource_id;
      
      -- ------------------------------------------------
      -- Cursor Declaration to get all the resource roles
      -- ------------------------------------------------
      
      CURSOR lcu_get_res_role_dtls(p_resource_id IN jtf_rs_resource_extns.resource_id%TYPE)
      IS
      SELECT JRRR.role_relate_id
            ,JRRR.object_version_number
      FROM   jtf_rs_role_relations     JRRR
            ,jtf_rs_resource_extns_vl  JRRE            
      WHERE  JRRR.role_resource_id      =  JRRE.resource_id      
      AND    JRRR.role_resource_type    = 'RS_INDIVIDUAL'
      AND    NVL(JRRR.attribute15,'N') <> 'CLEANUP'
      AND    JRRR.delete_flag           = 'N'
      AND    JRRR.role_id IN 
                         (SELECT role_id
                          FROM   jtf_rs_roles_vl JRRV                          
                          WHERE  JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')-- 31/07/08
                         )
      AND    JRRE.resource_id      =  p_resource_id;

      
      -- ---------------------------------------------
      -- Cursor Declaration to get all the group roles
      -- ---------------------------------------------
      
      CURSOR lcu_get_grp_role_dtls(p_source_id IN jtf_rs_resource_extns.source_id%TYPE)
      IS
      SELECT JRRR.role_relate_id
            ,JRRR.object_version_number
      FROM   jtf_rs_role_relations  JRRR
            ,jtf_rs_groups_vl       JRGV                    
      WHERE  JRRR.role_resource_id    = JRGV.group_id
      AND    JRRR.role_resource_type  = 'RS_GROUP'
      AND    NVL(JRRR.attribute15,'N') <> 'CLEANUP'
      AND    JRRR.delete_flag         = 'N'       
      AND    JRRR.role_id IN 
                           (SELECT role_id
                            FROM   jtf_rs_roles_vl JRRV                            
                            WHERE  JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')-- 31/07/08
                           )
      AND    JRGV.group_id IN 
                            (SELECT group_id
                             FROM   jtf_rs_group_usages
                             WHERE  usage IN ('SALES_COMP','COMP_PAYMENT','SALES','IEX_COLLECTIONS')-- 31/07/08
                            )
      AND    JRGV.attribute15         = p_source_id; 

      -- -------------------------------------------------------
      -- Cursor Declaration to get all the parent child relation
      -- -------------------------------------------------------
      
      CURSOR lcu_get_parent_child_dtls(p_source_id IN jtf_rs_resource_extns.source_id%TYPE)
      IS
      SELECT  JRGR.group_relate_id
             ,JRGR.object_version_number
      FROM    jtf_rs_grp_relations   JRGR
             ,jtf_rs_groups_vl       JRGV      
      WHERE   JRGR.group_id         = JRGV.group_id
      AND     JRGR.relation_type    = 'PARENT_GROUP'
      AND     JRGR.related_group_id IN (SELECT group_id
                                        FROM   jtf_rs_group_usages
                                        WHERE  usage IN ('SALES_COMP','COMP_PAYMENT','SALES','IEX_COLLECTIONS')-- 31/07/08
                                        )
      AND     JRGR.delete_flag      = 'N'
      AND     JRGV.attribute15      = p_source_id; 
      
      -- Added on 25/06/08
      -- ----------------------------------------------
      -- Cursor Declaration to get the resource details
      -- ----------------------------------------------      
      
      CURSOR  lcu_get_res_details(p_resource_id IN jtf_rs_resource_extns.resource_id%TYPE)
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = p_resource_id
      AND     attribute14 IS NOT NULL
      AND     attribute15 IS NOT NULL ;             
      
      -- Added on 25/06/08
      
   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN

       fnd_msg_pub.initialize;      
       
       gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;

       -- --------------------------------------
       -- DISPLAY PROJECT NAME AND PROGRAM NAME
       -- --------------------------------------

       WRITE_LOG(RPAD('Office Depot',50)||'Date: '||trunc(SYSDATE));
       WRITE_LOG(RPAD(' ',76,'-'));
       WRITE_LOG(LPAD('OD: CRM HRCRM Cleanse Program',52));
       WRITE_LOG(RPAD(' ',76,'-'));
       WRITE_LOG('');
       WRITE_LOG('Input Parameters ');
       WRITE_LOG('Person Id : '||p_person_id);
       WRITE_LOG('As-Of-Date: '||SYSDATE);


       WRITE_OUT(RPAD(' Office Depot',64)||LPAD(' Date: '||trunc(SYSDATE),16));
       WRITE_OUT(RPAD(' ',80,'-'));
       WRITE_OUT(LPAD('OD: CRM HRCRM Cleanse Program',50));
       WRITE_OUT(RPAD(' ',80,'-'));
       WRITE_OUT('');      
              

       IF lcu_get_resources%ISOPEN THEN

          CLOSE lcu_get_resources;

       END IF;

       OPEN  lcu_get_resources;
       LOOP

          FETCH lcu_get_resources BULK COLLECT INTO lt_employee_details LIMIT 75;

          WRITE_LOG('Resource Count: '||lt_employee_details.count);

          IF lt_employee_details.count > 0 THEN

              -- -----------------------------------------------------------
              -- Call the procedure for all directs reporting to the manager
              -- -----------------------------------------------------------

                FOR i IN lt_employee_details.first..lt_employee_details.last
                LOOP
                    
                    SAVEPOINT PROCESS_RESOURCE_SP;
                    
                    gc_err_msg := NULL;
                    
                    ln_grp_mbr_role_err := 0;
		    ln_grp_mbr_err      := 0;
		    ln_res_rol_err      := 0;
		    ln_grp_rol_err      := 0;  
                    ln_grp_rel_err      := 0;
                    ln_date_del_err     := 0; -- 26/06/08
                    ln_grp_mbr_role_suc := 0;
		    ln_grp_mbr_suc      := 0;
		    ln_res_rol_suc      := 0;
		    ln_grp_rol_suc      := 0; 
                    ln_grp_rel_suc      := 0;   
                    ln_date_del_suc     := 0; -- 26/06/08
                                        
                    x_retcode := NULL;

                    WRITE_LOG('Deleting records for the resource_id :'||lt_employee_details(i).resource_id);                  

                    FOR lcu_get_grp_mbr_role_dtls_rec IN lcu_get_grp_mbr_role_dtls(lt_employee_details(i).resource_id)
                    LOOP
		       
		       lc_grp_mbr_role_flg := 'Y';
		       WRITE_LOG('Deleting group member role for the role_relate_id :'||lcu_get_grp_mbr_role_dtls_rec.role_relate_id);

		       DELETE_RES_GROUP_ROLE
		                          (
		                          p_api_version        => 1.0
		                         ,p_commit             => FND_API.G_FALSE
		                         ,p_group_id           => lcu_get_grp_mbr_role_dtls_rec.group_id
		                         ,p_resource_id        => lt_employee_details(i).resource_id
		                         ,p_group_member_id    => lcu_get_grp_mbr_role_dtls_rec.group_member_id
		                         ,p_role_relate_id     => lcu_get_grp_mbr_role_dtls_rec.role_relate_id
		                         ,p_object_version_num => lcu_get_grp_mbr_role_dtls_rec.object_version_number
		                         ,x_return_status      => x_return_status
		                         ,x_msg_count          => x_msg_count
		                         ,x_msg_data           => x_msg_data
		                          );


		       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		          WRITE_LOG('In Procedure:MAIN: Proc: DELETE_RES_GROUP_ROLE Fails. ');
		          
		          ln_grp_mbr_role_err := ln_grp_mbr_role_err +1;

		          XX_COM_ERROR_LOG_PUB.log_error_crm(
		                                 p_return_code             => x_return_status
		                                ,p_msg_count               => x_msg_count
		                                ,p_application_name        => GC_APPN_NAME
		                                ,p_program_type            => GC_PROGRAM_TYPE
		                                ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                                ,p_program_id              => gc_conc_prg_id
		                                ,p_module_name             => GC_MODULE_NAME
		                                ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                                ,p_error_message_count     => x_msg_count
		                                ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
		                                ,p_error_message           => x_msg_data
		                                ,p_error_status            => GC_ERROR_STATUS
		                                ,p_notify_flag             => GC_NOTIFY_FLAG
		                                ,p_error_message_severity  =>'MINOR'
		                                );
		       ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
		          ln_grp_mbr_role_suc := ln_grp_mbr_role_suc +1;

		       END IF;

		    END LOOP;

		    IF (ln_grp_mbr_role_err = 0 AND lc_grp_mbr_role_flg = 'Y') OR lc_grp_mbr_role_flg ='N' THEN

	               FOR lcu_get_grp_mbr_dtls_rec IN lcu_get_grp_mbr_dtls(lt_employee_details(i).resource_id)
		       LOOP

		          lc_grp_mbr_flg := 'Y';
		          WRITE_LOG('Deleting group membership for the group_id :'||lcu_get_grp_mbr_dtls_rec.group_id);

			  DELETE_GRP_MBRSHIP
					    (
					     p_api_version           => 1.0
					   , p_commit                => FND_API.G_FALSE
					   , p_group_id              => lcu_get_grp_mbr_dtls_rec.group_id
					   , p_group_number          => lcu_get_grp_mbr_dtls_rec.group_number
					   , p_resource_id           => lt_employee_details(i).resource_id
					   , p_resource_number       => lcu_get_grp_mbr_dtls_rec.resource_number
					   , p_object_version_number => lcu_get_grp_mbr_dtls_rec.object_version_number
					   , x_return_status         => x_return_status
					   , x_msg_count             => x_msg_count
					   , x_msg_data              => x_msg_data
					    );


			  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

			     ln_grp_mbr_err:= ln_grp_mbr_err + 1;
			     
			     WRITE_LOG('In Procedure:MAIN: Proc: DELETE_GRP_MBRSHIP Fails. ');

			     XX_COM_ERROR_LOG_PUB.log_error_crm(
						    p_return_code             => x_return_status
						   ,p_msg_count               => x_msg_count
						   ,p_application_name        => GC_APPN_NAME
						   ,p_program_type            => GC_PROGRAM_TYPE
						   ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
						   ,p_program_id              => gc_conc_prg_id
						   ,p_module_name             => GC_MODULE_NAME
						   ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
						   ,p_error_message_count     => x_msg_count
						   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
						   ,p_error_message           => x_msg_data
						   ,p_error_status            => GC_ERROR_STATUS
						   ,p_notify_flag             => GC_NOTIFY_FLAG
						   ,p_error_message_severity  =>'MINOR'
						   );

			  ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
			     ln_grp_mbr_suc := ln_grp_mbr_suc + 1;

		          END IF;

		       END LOOP;
		    END IF;

		    IF (ln_grp_mbr_err =0 AND lc_grp_mbr_flg = 'Y') OR lc_grp_mbr_flg = 'N' THEN

		       FOR lcu_get_res_role_dtls_rec IN lcu_get_res_role_dtls(lt_employee_details(i).resource_id)
                       LOOP

                          lc_res_rol_flg :='Y';
                          WRITE_LOG('Deleting resource role for the role_relate_id :'||lcu_get_res_role_dtls_rec.role_relate_id);
                         
                          
                          DELETE_RESOURCE_ROLE
                                             (
                                              p_api_version         => 1.0
                                             ,p_commit              => FND_API.G_FALSE
                                             ,p_role_relate_id      => lcu_get_res_role_dtls_rec.role_relate_id
                                             ,p_object_version_num  => lcu_get_res_role_dtls_rec.object_version_number
                                             ,x_return_status       => x_return_status
                                             ,x_msg_count           => x_msg_count
                                             ,x_msg_data            => x_msg_data
                                              );                                            
                                              
                          
                          IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		             ln_res_rol_err := ln_res_rol_err + 1;
		             
		             WRITE_LOG('In Procedure:MAIN: Proc: DELETE_RESOURCE_ROLE Fails. ');

		             XX_COM_ERROR_LOG_PUB.log_error_crm(
		                                       p_return_code             => x_return_status
		                                      ,p_msg_count               => x_msg_count
		                                      ,p_application_name        => GC_APPN_NAME
		                                      ,p_program_type            => GC_PROGRAM_TYPE
		                                      ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                                      ,p_program_id              => gc_conc_prg_id
		                                      ,p_module_name             => GC_MODULE_NAME
		                                      ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                                      ,p_error_message_count     => x_msg_count
		                                      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
		                                      ,p_error_message           => x_msg_data
		                                      ,p_error_status            => GC_ERROR_STATUS
		                                      ,p_notify_flag             => GC_NOTIFY_FLAG
		                                      ,p_error_message_severity  =>'MINOR'
		                                      );

		          ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
		             ln_res_rol_suc := ln_res_rol_suc +1;

		          END IF;

                       END LOOP;
                       
                    END IF;

                    IF  (ln_res_rol_err= 0 AND lc_res_rol_flg = 'Y') OR lc_res_rol_flg = 'N'THEN                   


		       FOR lcu_get_grp_role_dtls_rec IN lcu_get_grp_role_dtls(lt_employee_details(i).source_id)
		       LOOP
		          
		          lc_grp_rol_flg := 'Y';
		          
		          WRITE_LOG('Deleting group role for the role_relate_id :'||lcu_get_grp_role_dtls_rec.role_relate_id);

		          DELETE_GROUP_ROLE(
		                            p_api_version         => 1.0
		                           ,p_commit              => FND_API.G_FALSE
		                           ,p_role_relate_id      => lcu_get_grp_role_dtls_rec.role_relate_id
		                           ,p_object_version_num  => lcu_get_grp_role_dtls_rec.object_version_number
		                           ,x_return_status       => x_return_status
		                           ,x_msg_count           => x_msg_count
		                           ,x_msg_data            => x_msg_data
			                   );

			  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                             ln_grp_rol_err := ln_grp_rol_err + 1;
                             
                             WRITE_LOG('In Procedure:MAIN: Proc: DELETE_GROUP_ROLE Fails. ');

		             XX_COM_ERROR_LOG_PUB.log_error_crm(
				                          p_return_code             => x_return_status
				                         ,p_msg_count               => x_msg_count
				                         ,p_application_name        => GC_APPN_NAME
				                         ,p_program_type            => GC_PROGRAM_TYPE
				                         ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
				                         ,p_program_id              => gc_conc_prg_id
				                         ,p_module_name             => GC_MODULE_NAME
				                         ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
				                         ,p_error_message_count     => x_msg_count
				                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
				                         ,p_error_message           => x_msg_data
				                         ,p_error_status            => GC_ERROR_STATUS
				                         ,p_notify_flag             => GC_NOTIFY_FLAG
				                         ,p_error_message_severity  =>'MINOR'
				                         );
			  
			  ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
			     ln_grp_rol_suc := ln_grp_rol_suc +1;
			  
			  END IF;
			  
		       END LOOP;
		       
		     END IF;
		     
		     IF (ln_grp_rol_err = 0 AND lc_grp_rol_flg = 'Y') OR lc_grp_rol_flg = 'N' THEN 
		     
		      FOR lcu_get_parent_child_dtls_rec IN lcu_get_parent_child_dtls(lt_employee_details(i).source_id)
		      LOOP	          	         		          
		         		         
		         lc_grp_rel_flg := 'Y';
		         
		         WRITE_LOG('Deleting parent child relation for the group_relate_id :'||lcu_get_parent_child_dtls_rec.group_relate_id);
		     
		         DELETE_GROUP_RELATIONS(
		                     p_api_version         => 1.0
		                    ,p_commit              => FND_API.G_FALSE
		                    ,p_group_relate_id     => lcu_get_parent_child_dtls_rec.group_relate_id
		                    ,p_object_version_num  => lcu_get_parent_child_dtls_rec.object_version_number
		                    ,x_return_status       => x_return_status
		                    ,x_msg_count           => x_msg_count
		                    ,x_msg_data            => x_msg_data
		                    );
		     
		         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
		     
		            ln_grp_rel_err := ln_grp_rel_err + 1;
		      
		            WRITE_LOG('In Procedure:MAIN: Proc: DELETE_GROUP_RELATIONS Fails. ');
		     
		            XX_COM_ERROR_LOG_PUB.log_error_crm(
		                               p_return_code             => x_return_status
		                              ,p_msg_count               => x_msg_count
		                              ,p_application_name        => GC_APPN_NAME
		                              ,p_program_type            => GC_PROGRAM_TYPE
		                              ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                              ,p_program_id              => gc_conc_prg_id
		                              ,p_module_name             => GC_MODULE_NAME
		                              ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                              ,p_error_message_count     => x_msg_count
		                              ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
		                              ,p_error_message           => x_msg_data
		                              ,p_error_status            => GC_ERROR_STATUS
		                              ,p_notify_flag             => GC_NOTIFY_FLAG
		                              ,p_error_message_severity  =>'MINOR'
		                              );
		     
		         ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
		            ln_grp_rel_suc := ln_grp_rel_suc +1;
		     
		         END IF;
		     
		      END LOOP;         		           
		     
		     END IF;               		     
                     
                     -- Added on 25/06/08
		     IF (ln_grp_rel_err = 0 AND lc_grp_rel_flg = 'Y') OR lc_grp_rel_flg = 'N'  THEN 
		     
		      FOR lcu_get_res_details_rec IN lcu_get_res_details(lt_employee_details(i).resource_id)
		      LOOP	          	         		          
		         		         
		         WRITE_LOG('Deleting CRM Job and Supervisor Dates for the resource');
		     
		         UPDT_DATES_RESOURCE
		                       ( p_resource_id        =>  lt_employee_details(i).resource_id
		                       , p_resource_number    =>  lcu_get_res_details_rec.resource_number
		                       , p_source_name        =>  lcu_get_res_details_rec.source_name
		                       , p_attribute14        =>  NULL
		                       , p_attribute15        =>  NULL
		                       , p_object_version_num =>  lcu_get_res_details_rec.object_version_number
		                       , x_return_status      =>  x_return_status
		                       , x_msg_count          =>  x_msg_count
		                       , x_msg_data           =>  x_msg_data
		                       );       
		         	         
		         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
		     
		            ln_date_del_err := ln_date_del_err + 1;      
		            
		            WRITE_LOG('In Procedure:MAIN: Proc: UPDT_DATES_RESOURCE Fails. ');
		             
		            XX_COM_ERROR_LOG_PUB.log_error_crm(
		                               p_return_code             => x_return_status
		                              ,p_msg_count               => x_msg_count
		                              ,p_application_name        => GC_APPN_NAME
		                              ,p_program_type            => GC_PROGRAM_TYPE                                                                                                                                                                                                           
		                              ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                              ,p_program_id              => gc_conc_prg_id
		                              ,p_module_name             => GC_MODULE_NAME
		                              ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
		                              ,p_error_message_count     => x_msg_count
		                              ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
		                              ,p_error_message           => x_msg_data
		                              ,p_error_status            => GC_ERROR_STATUS
		                              ,p_notify_flag             => GC_NOTIFY_FLAG
		                              ,p_error_message_severity  =>'MINOR'
		                              );
		                          
		     
		         ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
		            ln_date_del_suc := ln_date_del_suc +1;
		     
		         END IF;
		     
		      END LOOP;         		           
		     
		     END IF;                                    
                     -- Added on 25/06/08  
                     
	             IF ln_grp_mbr_role_err >0  THEN	       
	          	          
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);	
	                lc_grp_mbr_role_commit_flg := 'N';                
              	        		         	       
	             ELSIF (ln_grp_mbr_role_err = 0 AND ln_grp_mbr_role_suc>0) THEN       
	          	       
	                lc_grp_mbr_role_commit_flg := 'Y';                  
	       	        ln_grp_mbr_role_suc_tot:= ln_grp_mbr_role_suc +ln_grp_mbr_role_suc_tot;
	       	     ELSE
	       	        lc_grp_mbr_role_commit_flg := 'Y';
	       	  
	             END IF;	
	      
	             IF ln_grp_mbr_err>0  THEN
	       
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);	
	                lc_grp_mbr_commit_flg := 'N';
	                
	       
	             ELSIF (ln_grp_mbr_err = 0 AND ln_grp_mbr_suc>0) THEN
	          
	       	        lc_grp_mbr_commit_flg := 'Y';
	       	        ln_grp_mbr_suc_tot := ln_grp_mbr_suc+ln_grp_mbr_suc_tot;
	       	     
	       	     ELSE
	       	        lc_grp_mbr_commit_flg := 'Y';
	       	  
	             END IF;     
	       
	             IF ln_res_rol_err>0  THEN
	       
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);
	                lc_res_rol_commit_flg := 'N';
	                
	       
	             ELSIF (ln_res_rol_err = 0 AND ln_res_rol_suc>0) THEN
	       
	                lc_res_rol_commit_flg := 'Y';
	       	        ln_res_rol_suc_tot := ln_res_rol_suc+ln_res_rol_suc_tot;
	       	     
	       	     ELSE
	       	        lc_res_rol_commit_flg := 'Y';
	       	  
	             END IF;
	      
	             IF ln_grp_rol_err>0  THEN
	       
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);
	                lc_grp_rol_commit_flg := 'N';
	                
	       
	             ELSIF (ln_grp_rol_err = 0 AND ln_grp_rol_suc>0) THEN
	       
	                lc_grp_rol_commit_flg := 'Y';
	       	        ln_grp_rol_suc_tot := ln_grp_rol_suc+ln_grp_rol_suc_tot;
	       	        
                     ELSE
                        lc_grp_rol_commit_flg := 'Y';
	       	  
	             END IF;
	      
	             IF ln_grp_rel_err>0  THEN
	       
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);
	                lc_grp_rel_commit_flg := 'N';
	                
	       
	             ELSIF (ln_grp_rel_err = 0 AND ln_grp_rel_suc>0) THEN
	       
	       	        lc_grp_rel_commit_flg := 'Y';
	       	        ln_grp_rel_suc_tot :=ln_grp_rel_suc+ln_grp_rel_suc_tot;
	       	     ELSE
	       	        lc_grp_rel_commit_flg := 'Y';
	       	  
	             END IF;	    	       

             	     -- Added on 25/06/08
	             IF ln_date_del_err>0  THEN
	       
	                WRITE_OUT((RPAD(' '||'Error Message',27))||' '||' : '||gc_err_msg);	
	                lc_date_del_commit_flg := 'N';
	                
	       
	             ELSIF (ln_date_del_err = 0 AND ln_date_del_suc>0) THEN
	       
	       	        lc_date_del_commit_flg := 'Y';
	       	        ln_date_del_suc_tot :=ln_date_del_suc + ln_date_del_suc_tot;
	       	     ELSE
	       	        lc_date_del_commit_flg := 'Y';
	       	  
	             END IF;	
	             -- Added on 25/06/08      
	             
	             IF lc_grp_mbr_role_commit_flg = 'Y' OR
	             	lc_grp_mbr_commit_flg      = 'Y' OR
	             	lc_res_rol_commit_flg      = 'Y' OR
	             	lc_grp_rol_commit_flg      = 'Y' OR
	             	lc_grp_rel_commit_flg      = 'Y' OR
	             	lc_date_del_commit_flg     = 'Y' THEN
	             	
	             	COMMIT;         	       
	             	WRITE_LOG('Commit Completed');
	             ELSIF lc_grp_mbr_role_commit_flg = 'N' OR
	                   lc_grp_mbr_commit_flg      = 'N' OR
	                   lc_res_rol_commit_flg      = 'N' OR
	             	   lc_grp_rol_commit_flg      = 'N' OR
	             	   lc_grp_rel_commit_flg      = 'N' OR
	             	   lc_date_del_commit_flg     = 'N' THEN
	               	   
	             	 WRITE_LOG('Rolling back to savepoint');
	             	 ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;
	             
	             END IF;	      
	             
	          END LOOP;

	       END IF;      
	       
	      EXIT WHEN lcu_get_resources%NOTFOUND;

	      END LOOP;

	      CLOSE lcu_get_resources;                       	            	
	      
	      WRITE_OUT((RPAD(' '||'Group Member Roles Deleted',27))||' '||' : '||ln_grp_mbr_role_suc_tot);
	      WRITE_OUT((RPAD(' '||'Group Memberships Deleted',27))||' '||' : '||ln_grp_mbr_suc_tot);
	      WRITE_OUT((RPAD(' '||'Resource Roles Deleted',27))||' '||' : '||ln_res_rol_suc_tot);
	      WRITE_OUT((RPAD(' '||'Group Roles Deleted',27))||' '||' : '||ln_grp_rol_suc_tot);
	      WRITE_OUT((RPAD(' '||'Group Relations Deleted',27))||' '||' : '||ln_grp_rel_suc_tot);
	      WRITE_OUT((RPAD(' '||'CRM Dates Deleted',27))||' '||' : '||ln_date_del_suc_tot);
	      
	      
   EXCEPTION  

   WHEN OTHERS THEN
      x_errbuf  := 'Completed with errors,  '||SQLERRM ;
      x_retcode := 2 ;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg||CHR(10)||RPAD(' ',29)||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CLEANSE_PKG.MAIN'
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );
                            
     ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;    
   

   END MAIN;

END XX_CRM_HRCRM_CLEANSE_PKG;
/

SHOW ERRORS

EXIT
