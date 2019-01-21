SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_HRCRM_CM_SYNC_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CRM_HRCRM_CM_SYNC_PKG                                       |
  -- | Description      :  This custom package is needed to maintain Oracle CRM resources |
  -- |                     synchronized with changes made to employees in Oracle HRMS     |
  -- |                                                                                    |
  -- |                                                                                    |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  05-Sep-08   Gowri Nagarajan  Initial Draft Version                        |
  -- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
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

   gn_person_id                NUMBER                                                      ;
   gc_debug_flag               VARCHAR2(1) := FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG')     ;
   gc_write_debug_to_log       CHAR(1);
   gc_errbuf                   VARCHAR2(2000)                                              ;
   gn_biz_grp_id               NUMBER      := FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID')   ;
   gc_employee_number          per_all_people_f.employee_number%TYPE := NULL               ;
   gc_full_name                per_all_people_f.full_name%TYPE       := NULL               ;
   gn_resource_id              jtf_rs_resource_extns_vl.resource_id%TYPE                   ;
   gc_resource_number          jtf_rs_resource_extns_vl.resource_number%TYPE               ;
   gn_job_id                   per_all_assignments_f.job_id%TYPE                           ;
   gd_job_asgn_date            DATE                                                        ;
   gd_mgr_asgn_date            DATE                                                        ;
   gd_crm_job_asgn_date        DATE                                                        ;
   gd_crm_mgr_asgn_date        DATE                                                        ;
   gc_sales_rep_res            VARCHAR2(1) := 'N';
   gc_resource_exists          VARCHAR2(1) ;
   gc_back_date_exists         VARCHAR2(1) := 'N';
   gc_future_date_exists       VARCHAR2(1) := 'N';
   gc_return_status            VARCHAR2(10)                                                ;
   -- This shall have the values a. SUCCESS,
   --                            b. ERROR,
   --                            c. WARNING


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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.WRITE_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.WRITE_LOG'
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.WRITE_OUT'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.WRITE_OUT'
                                  ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
   END;

   -- +===================================================================+
   -- | Name  : DEBUG_LOG                                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall write to the concurrent   |
   -- |                    program output if the debug flag is Y.         |
   -- |                                                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE DEBUG_LOG (p_message IN VARCHAR2)

   IS

      lc_error_message VARCHAR2(2000);

   BEGIN

      IF gc_debug_flag ='Y' THEN
            IF gc_write_debug_to_log = FND_API.G_TRUE AND gc_conc_prg_id <> -1 THEN
                WRITE_LOG('DEBUG_MESG_WRITE:'||p_message);
            ELSE
                WRITE_LOG('DEBUG_MESG:'||p_message);
            END IF;
      END IF;

   EXCEPTION

      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.DEBUG_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.DEBUG_LOG'
                                  ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
   END;
   ------------------------------------------------------------------------
   ----------------------------API Calls ----------------------------------
   ------------------------------------------------------------------------

   -- +===================================================================+
   -- | Name  : CREATE_RESOURCE                                           |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    resource creation.                             |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE CREATE_RESOURCE
                  (
                    p_api_version        IN  NUMBER
                  , p_commit             IN  VARCHAR2
                  , p_category           IN  jtf_rs_resource_extns.category%TYPE
                  , p_source_id          IN  jtf_rs_resource_extns.source_id%TYPE         DEFAULT  NULL
                  , p_start_date_active  IN  jtf_rs_resource_extns.start_date_active%TYPE
                  , p_resource_name      IN  jtf_rs_resource_extns_tl.resource_name%TYPE  DEFAULT NULL
                  , p_source_number      IN  jtf_rs_resource_extns.source_number%TYPE     DEFAULT NULL
                  , p_source_name        IN  jtf_rs_resource_extns.source_name%TYPE
                  , p_user_name          IN  VARCHAR2
                  , p_attribute14        IN  jtf_rs_resource_extns.attribute14%TYPE
                  , p_attribute15        IN  jtf_rs_resource_extns.attribute15%TYPE
                  , x_return_status      OUT NOCOPY  VARCHAR2
                  , x_msg_count          OUT NOCOPY  NUMBER
                  , x_msg_data           OUT NOCOPY  VARCHAR2
                  , x_resource_id        OUT NOCOPY  jtf_rs_resource_extns.resource_id%TYPE
                  , x_resource_number    OUT NOCOPY  jtf_rs_resource_extns.resource_number%TYPE
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);


   BEGIN
      DEBUG_LOG('Inside Proc: CREATE_RESOURCE');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;


      -- ---------------------
      -- CRM Standard API call
      -- ---------------------

      JTF_RS_RESOURCE_PUB.create_resource
                    (
                      p_api_version         => p_api_version
                    , p_commit              => p_commit
                    , p_init_msg_list       => fnd_api.G_FALSE
                    , p_category            => p_category
                    , p_source_id           => p_source_id
                    , p_start_date_active   => p_start_date_active
                    , p_resource_name       => p_resource_name
                    , p_source_number       => p_source_number
                    , p_source_name         => p_source_name
                    , p_user_name           => p_user_name
                    , p_attribute14         => p_attribute14
                    , p_attribute15         => p_attribute15
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    , x_resource_id         => x_resource_id
                    , x_resource_number     => x_resource_number
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
               lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;


   END CREATE_RESOURCE;

   -- +===================================================================+
   -- | Name  : ASSIGN_ROLE_TO_RESOURCE                                   |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    assignment of role to the resource.            |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE ASSIGN_ROLE_TO_RESOURCE
                 (
                   p_api_version        IN  NUMBER
                 , p_commit             IN  VARCHAR2
                 , p_role_resource_type IN  jtf_rs_role_relations.role_resource_type%TYPE
                 , p_role_resource_id   IN  jtf_rs_role_relations.role_resource_id%TYPE
                 , p_role_id            IN  jtf_rs_role_relations.role_id%TYPE
                 , p_role_code          IN  jtf_rs_roles_b.role_code%TYPE
                 , p_start_date_active  IN  jtf_rs_role_relations.start_date_active%TYPE
                 , p_attribute14        IN  jtf_rs_role_relations.attribute14%TYPE
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 , x_role_relate_id     OUT NOCOPY  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
                 )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

   BEGIN


      DEBUG_LOG('Inside Proc: ASSIGN_ROLE_TO_RESOURCE');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      -- ---------------------
      -- CRM Standard API call
      -- ---------------------

      XX_JTF_RS_ROLE_RELATE_PUB.Create_Resource_Role_Relate
                    (
                      p_api_version               => p_api_version
                    , p_commit                    => p_commit
                    , p_role_resource_type        => p_role_resource_type
                    , p_role_resource_id          => p_role_resource_id
                    , p_role_id                   => p_role_id
                    , p_role_code                 => p_role_code
                    , p_start_date_active         => p_start_date_active
                    , p_attribute14               => p_attribute14
                    , x_return_status             => x_return_status
                    , x_msg_count                 => x_msg_count
                    , x_msg_data                  => x_msg_data
                    , x_role_relate_id            => x_role_relate_id
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
               lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;


   END ASSIGN_ROLE_TO_RESOURCE;

   -- +===================================================================+
   -- | Name  : ENDDATE_RES_GRP_ROLE                                      |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    enddating the role assigned to the group member|
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE ENDDATE_RES_GRP_ROLE(
                  P_ROLE_RELATE_ID  IN  NUMBER,
                  P_END_DATE_ACTIVE IN  DATE,
                  P_OBJECT_VERSION  IN  NUMBER,
                  X_RETURN_STATUS   OUT VARCHAR2,
                  X_MSG_COUNT       OUT NUMBER,
                  X_MSG_DATA        OUT VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version    NUMBER;
      ln_cnt               NUMBER ;
      lc_return_mesg       VARCHAR2(5000);
      v_data               VARCHAR2(5000);


   BEGIN
      DEBUG_LOG('Inside Proc: ENDDATE_RES_GRP_ROLE');
      lc_object_version :=  p_object_version;

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_END_DATE_ACTIVE     => P_END_DATE_ACTIVE,
         P_OBJECT_VERSION_NUM  => lc_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
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
               lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;

   END ENDDATE_RES_GRP_ROLE;

   -- +===================================================================+
   -- | Name  : ENDDATE_RES_ROLE                                          |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    enddate the role assigned to the resource.     |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE ENDDATE_RES_ROLE(
                  P_ROLE_RELATE_ID  IN  NUMBER,
                  P_END_DATE_ACTIVE IN  DATE,
                  P_OBJECT_VERSION  IN  NUMBER,
                  X_RETURN_STATUS   OUT VARCHAR2,
                  X_MSG_COUNT       OUT NUMBER,
                  X_MSG_DATA        OUT VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version            NUMBER;
      ln_cnt                       NUMBER ;
      lc_return_mesg               VARCHAR2(5000);
      v_data                       VARCHAR2(5000);

   BEGIN

      DEBUG_LOG('Inside Proc: ENDDATE_RES_ROLE');
      lc_object_version :=  p_object_version;

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_END_DATE_ACTIVE     => P_END_DATE_ACTIVE,
         P_OBJECT_VERSION_NUM  => lc_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
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
               lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;

   END ENDDATE_RES_ROLE;

   -- +===================================================================+
   -- | Name  : BACKDATE_RES_ROLE                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    backdate the role assigned to the resource.    |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE BACKDATE_RES_ROLE(
                  P_ROLE_RELATE_ID    IN  NUMBER,
                  P_START_DATE_ACTIVE IN  DATE,
                  P_OBJECT_VERSION    IN  NUMBER,
                  P_ATTRIBUTE14       IN  jtf_rs_role_relations.attribute14%TYPE,
                  X_RETURN_STATUS     OUT VARCHAR2,
                  X_MSG_COUNT         OUT NUMBER,
                  X_MSG_DATA          OUT VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lc_object_version            NUMBER;
      ln_cnt                       NUMBER ;
      lc_return_mesg               VARCHAR2(5000);

      v_data                       VARCHAR2(5000);

   BEGIN

      DEBUG_LOG('Inside Proc: BACKDATE_RES_ROLE');
      lc_object_version :=  p_object_version;

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      XX_JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_START_DATE_ACTIVE   => p_start_date_active,
         P_OBJECT_VERSION_NUM  => lc_object_version,
         P_ATTRIBUTE14         => p_attribute14,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
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
               lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;

            END IF;

         END LOOP;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;

   END BACKDATE_RES_ROLE;

   -- +===================================================================+
   -- | Name  : BACKDATE_RESOURCE                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    backdate the resource.                         |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE BACKDATE_RESOURCE
                 ( p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_resource_number    IN  jtf_rs_resource_extns_vl.resource_number%TYPE
                 , p_source_name        IN  jtf_rs_resource_extns_vl.source_name%TYPE
                 , p_start_date_active  IN  jtf_rs_resource_extns_vl.start_date_active%TYPE
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
       DEBUG_LOG('Inside Proc: BACKDATE_RESOURCE');

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
                    , p_start_date_active   => p_start_date_active
                    , p_object_version_num  => ln_object_version_num
                    , p_attribute14         => TO_CHAR(p_start_date_active,'DD-MON-RR')
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
                lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

       END IF;

   END BACKDATE_RESOURCE;


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

       DEBUG_LOG('Inside Proc: UPDT_DATES_RESOURCE');

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
                lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

       END IF;

   END UPDT_DATES_RESOURCE;

   -- +===================================================================+
   -- | Name  : ENDDATE_RESOURCE                                          |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    enddate the resource.                          |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE ENDDATE_RESOURCE
                 (
                   p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_resource_number    IN  jtf_rs_resource_extns_vl.resource_number%TYPE
                 , p_end_date_active    IN  jtf_rs_resource_extns_vl.end_date_active%TYPE
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

       DEBUG_LOG('Inside Proc: ENDDATE_RESOURCE');

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
                    , p_resource_id         => p_resource_id
                    , p_resource_number     => p_resource_number
                    , p_end_date_active     => p_end_date_active
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
                lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
             END IF;

          END LOOP;

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ;
          ELSE
             gc_err_msg := lc_return_mesg ;
          END IF;

          gn_msg_cnt := x_msg_count + 1;

       END IF;

   END ENDDATE_RESOURCE;

   -- +===================================================================+
   -- | Name  : ENDDATE_SALESREP                                          |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    endate of sales reps in all OU's.              |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE ENDDATE_SALESREP
                    ( P_RESOURCE_ID           IN JTF_RS_RESOURCE_EXTNS_VL.resource_id%TYPE,
                      P_END_DATE_ACTIVE       IN JTF_RS_SALESREPS.end_date_active%TYPE,
                      X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
                      X_MSG_COUNT            OUT NOCOPY  NUMBER,
                      X_MSG_DATA             OUT NOCOPY  VARCHAR2
                    )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_salesrep_exist_flag   VARCHAR2(1) := 'N';
      lc_return_status         VARCHAR2(1) ;
      ln_cnt                   NUMBER ;
      lc_return_mesg           VARCHAR2(5000);
      v_data                   VARCHAR2(5000);


      CURSOR  lcu_get_salesreps
      IS
      SELECT  salesrep_id
             ,sales_credit_type_id
             ,object_version_number
             ,org_id
      FROM    jtf_rs_salesreps
      WHERE   resource_id = p_resource_id
      AND     p_end_date_active
              BETWEEN   start_date_active
              AND       NVL(end_date_active,p_end_date_active);


   BEGIN

      DEBUG_LOG('Inside Proc: ENDDATE_SALESREP');

      FOR get_salesrep_rec IN lcu_get_salesreps
      LOOP

           lc_salesrep_exist_flag := 'Y';

           -- 18/01/08
           FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                      p_data  => gc_msg_data
                                      );

           IF gn_msg_cnt_get = 0 THEN
              gn_msg_cnt := 1;
           END IF;
           -- 18/01/08

            -- ---------------------
            -- CRM Standard API call
            -- ---------------------

            JTF_RS_SALESREPS_PUB.update_salesrep
                             ( P_API_VERSION           => 1.0,
                               P_SALESREP_ID           => get_salesrep_rec.salesrep_id,
                               P_END_DATE_ACTIVE       => p_end_date_active,
                               P_ORG_ID                => get_salesrep_rec.org_id,
                               P_SALES_CREDIT_TYPE_ID  => get_salesrep_rec.sales_credit_type_id,
                               P_OBJECT_VERSION_NUMBER => get_salesrep_rec.object_version_number,
                               X_RETURN_STATUS         => lc_return_status,
                               X_MSG_COUNT             => x_msg_count,
                               X_MSG_DATA              => x_msg_data
                             );

            IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
            THEN

               gc_return_status       := 'ERROR';

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
                     lc_return_mesg := lc_return_mesg|| ' * ' ||v_data;
                  END IF;

               END LOOP;

               IF gc_err_msg IS NOT NULL THEN
                  gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ; -- 08/07/08
               ELSE
                  gc_err_msg := lc_return_mesg ;
               END IF;

               gn_msg_cnt := x_msg_count + 1;

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  x_return_status := lc_return_status;

               END IF;

            END IF;

      END LOOP;

      IF lc_salesrep_exist_flag = 'N' THEN

         DEBUG_LOG('No Salesreps attached to Resource ID: '||P_RESOURCE_ID ||' on date: '|| p_end_date_active);
      ELSE

         DEBUG_LOG('Salesreps End dated.');
      END IF;

     IF x_return_status <> FND_API.G_RET_STS_ERROR OR x_return_status <> FND_API.G_RET_STS_UNEXP_ERROR THEN

        x_return_status := FND_API.G_RET_STS_SUCCESS;
     END IF;

   END ENDDATE_SALESREP;

   ------------------------------------------------------------------------
   -------------------------End of API Calls-------------------------------
   ------------------------------------------------------------------------

   ------------------------------------------------------------------------
   -------------------------Internal Procs---------------------------------
   ------------------------------------------------------------------------

   -- +===================================================================+
   -- | Name  : VALIDATE_SETUPS                                           |
   -- |                                                                   |
   -- | Description:       This Procedure will check the following setups:|
   -- |                    1. Lookup Type (for OUs)                       |
   -- |                    2. Lookup values                               |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE VALIDATE_SETUPS( x_cnt  OUT NUMBER)

   IS
       -- ---------------------
       -- Exception declaration
       -- ---------------------
       EX_TERMINATE_PRGM EXCEPTION;
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------
       lc_lookuptype_existance           VARCHAR2(1);
       lc_lookupvalue_existance          VARCHAR2(1);
       lc_error_msg                      VARCHAR2(1000);
       lc_concat_msg                     VARCHAR2(5000);
       lc_term_prgm                      VARCHAR2(1):= 'Y';
       -- ----------------------
       -- Lookup type existance
       -- ----------------------
       CURSOR lcu_lookuptype_existance
       IS
       SELECT 'Y'
       FROM   fnd_lookup_types  FLT
       WHERE  FLT.lookup_type = 'OD_OPERATING_UNIT';

       -- --------------------------------
       -- Lookup type and values existance
       -- --------------------------------
       CURSOR lcu_lookupvalue_existance
       IS
       SELECT 'Y'
       FROM   fnd_lookup_values FLV
       WHERE  FLV.lookup_type = 'OD_OPERATING_UNIT'
       AND    FLV.end_date_active IS NULL
       AND    FLV.lookup_code IN (SELECT name
                                  FROM  hr_operating_units HOU
                                  WHERE HOU.date_to IS NULL
                                  );

   BEGIN

      x_cnt         := 0;
      lc_error_msg  := NULL;
      lc_concat_msg := NULL;

      IF lcu_lookuptype_existance%ISOPEN THEN
         CLOSE lcu_lookuptype_existance;
      END IF;

      OPEN  lcu_lookuptype_existance;
      FETCH lcu_lookuptype_existance INTO lc_lookuptype_existance;
      CLOSE lcu_lookuptype_existance;

      IF (NVL(lc_lookuptype_existance,'N') <> 'Y') THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0186_NULL_LOOKUP_TYPE');
         lc_error_msg  := FND_MESSAGE.GET;
         lc_concat_msg := lc_error_msg;
         WRITE_LOG(lc_error_msg);
         lc_term_prgm := 'N';

      ELSE

         x_cnt := x_cnt +1;

      END IF;

      IF lcu_lookupvalue_existance%ISOPEN THEN
         CLOSE lcu_lookupvalue_existance;
      END IF;

      OPEN  lcu_lookupvalue_existance;
      FETCH lcu_lookupvalue_existance INTO lc_lookupvalue_existance;
      CLOSE lcu_lookupvalue_existance;

      IF (NVL(lc_lookupvalue_existance,'N') <> 'Y') THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0187_NULL_LOOKUP_VALUE');
         lc_error_msg := FND_MESSAGE.GET;

         IF lc_concat_msg IS NOT NULL THEN
            lc_concat_msg := lc_concat_msg||CHR(10)||CHR(9)||RPAD(' ',224)||lc_error_msg;
         ELSE
            lc_concat_msg := lc_error_msg;
         END IF;

         WRITE_LOG(lc_error_msg);
         lc_term_prgm := 'N';

      ELSE
         x_cnt := x_cnt +1;

      END IF;

      IF lc_term_prgm = 'N' THEN
        RAISE EX_TERMINATE_PRGM;
      END IF;

   EXCEPTION
      WHEN EX_TERMINATE_PRGM THEN
        x_cnt := -1;
        DEBUG_LOG('In Exception EX_TERMINATE_PRGM of VALIDATE_SETUPS');
        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_error_message_code      => NULL
                                    ,p_error_message           => lc_concat_msg
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );

      WHEN OTHERS THEN
        x_cnt := -1;
        DEBUG_LOG('In WHEN OTHERS Exception of VALIDATE_SETUPS');

        WRITE_LOG(SQLERRM);

        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
        gc_errbuf := FND_MESSAGE.GET;

        IF gc_err_msg IS NOT NULL THEN
           gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
        ELSE
           gc_err_msg := gc_errbuf;
        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                    ,p_error_message           => SQLERRM
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );
   END VALIDATE_SETUPS;

   -- +===================================================================+
   -- | Name  : END_GRP_AND_RESGRPROLE                                    |
   -- |                                                                   |
   -- | Description:       This Procedure shall enddate the previous group|
   -- |                    memberships.                                   |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE END_GRP_AND_RESGRPROLE
                     ( p_group_id           jtf_rs_groups_vl.group_id%TYPE
                     , p_end_date           DATE
                     , x_return_status      OUT NOCOPY VARCHAR2
                     , x_msg_count          OUT NOCOPY NUMBER
                     , x_msg_data           OUT NOCOPY VARCHAR2
                     )
   IS

      lc_mbrship_exists_flag     VARCHAR2(1);
      ln_old_group_id            NUMBER;
      lc_error_message           VARCHAR2(1000);
      lc_return_status           VARCHAR2(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(1000);

      CURSOR  lcu_get_old_group_mbrship
      IS
      SELECT  JRRR.role_relate_id
             ,JRRR.object_version_number
             ,JRGMR.group_member_id
             ,JRGMR.group_id
             ,JRGV.group_name
             ,JRGMR.role_id
      FROM    jtf_rs_group_mbr_role_vl  JRGMR
             ,jtf_rs_role_relations     JRRR
             ,jtf_rs_groups_vl          JRGV
      WHERE   JRGMR.group_member_id   = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRGMR.group_id          = JRGV.group_id
      AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER'
      AND     JRRR.delete_flag        = 'N'
      AND     JRGMR.resource_id       = gn_resource_id
      AND     JRGMR.group_id         <> p_group_id
      AND     JRGMR.end_date_active  IS NULL
      ORDER   BY group_id;

   BEGIN

      DEBUG_LOG('Inside Proc: END_GRP_AND_RESGRPROLE');

      FOR  group_mbrship_rec IN lcu_get_old_group_mbrship
      LOOP

         ENDDATE_RES_GRP_ROLE
            (p_role_relate_id   => group_mbrship_rec.role_relate_id
            ,p_end_date_active  => p_end_date
            ,p_object_version   => group_mbrship_rec.object_version_number
            ,x_return_status    => lc_return_status
            ,x_msg_count        => ln_msg_count
            ,x_msg_data         => lc_msg_data
            );

         x_msg_count := ln_msg_count;


         IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
         THEN

            WRITE_LOG(lc_msg_data);
            DEBUG_LOG('In Procedure: END_GRP_AND_RESGRPROLE: Proc: ENDDATE_RES_GRP_ROLE Fails for Group membership.');

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => lc_return_status
                                  ,p_msg_count               => ln_msg_count
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                  ,p_error_message_count     => ln_msg_count
                                  ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                  ,p_error_message           => lc_msg_data
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MINOR'
                                   );

            IF NVL(gc_return_status,'A') <> 'ERROR' THEN

               gc_return_status := 'WARNING';

            END IF;

         END IF;
      END LOOP;

      x_return_status  :=  FND_API.G_RET_STS_SUCCESS;


   EXCEPTION

    WHEN OTHERS THEN

      gc_return_status := 'ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;

      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END END_GRP_AND_RESGRPROLE;

   -- +===================================================================+
   -- | Name  : BACK_DATE_CURR_ROLES                                      |
   -- |                                                                   |
   -- | Description:       This Procedure shall backdate the current      |
   -- |                    roles of the resource when there is no job     |
   -- |                    change.                                        |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE  BACK_DATE_CURR_ROLES
                    (x_return_status   OUT   VARCHAR2
                    ,x_msg_count       OUT   NUMBER
                    ,x_msg_data        OUT   VARCHAR2
                    )
   IS

      lc_return_status              VARCHAR2(1);
      lc_error_message              VARCHAR2(1000);
      lc_check_roles                VARCHAR2(1);
      lc_update_resource            VARCHAR2(1);
      ld_bonus_elig_date            DATE;
      lc_err_flag                   VARCHAR2(1);

      EX_TERMIN_PROG                EXCEPTION;


   CURSOR  lcu_get_res_details
   IS
   SELECT  resource_number
          ,object_version_number
          ,source_name
          ,TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
          ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
   FROM    jtf_rs_resource_extns_vl
   WHERE   resource_id = gn_resource_id;

   lr_res_details  lcu_get_res_details%ROWTYPE;

   CURSOR  lcu_check_roles
   IS
   SELECT 'Y' ROLES_EXISTS
   FROM    jtf_rs_role_relations
   WHERE   role_resource_id   = gn_resource_id
   AND     role_resource_type ='RS_INDIVIDUAL'
   AND     delete_flag = 'N'
   AND     end_date_active IS NOT NULL
   AND     start_date_active >  gd_job_asgn_date - 1
   AND     role_relate_id NOT IN (SELECT  role_relate_id
                                  FROM    jtf_rs_role_relations
                                  WHERE   role_resource_id   = gn_resource_id
                                  AND     role_resource_type = 'RS_INDIVIDUAL'
                                  AND     end_date_active IS NOT NULL
                                  AND     delete_flag = 'N'
                                  AND     gd_job_asgn_date - 1
                                          BETWEEN start_date_active
                                          AND     end_date_active
                                  AND     role_relate_id NOT IN (SELECT  role_relate_id
                                                                 FROM    jtf_rs_role_relations
                                                                 WHERE   role_resource_id   = gn_resource_id
                                                                 AND     role_resource_type = 'RS_INDIVIDUAL'
                                                                 AND     end_date_active IS NULL
                                                                 AND     delete_flag = 'N'
                                                                )
                               )
   AND     role_relate_id NOT IN (SELECT  role_relate_id
                                  FROM    jtf_rs_role_relations
                                  WHERE   role_resource_id   = gn_resource_id
                                  AND     role_resource_type = 'RS_INDIVIDUAL'
                                  AND     end_date_active IS NULL
                                  AND     delete_flag = 'N'
                                 );


   CURSOR  lcu_get_prev_roles_backdate
   IS
   SELECT  role_relate_id
          ,object_version_number
   FROM    jtf_rs_role_relations
   WHERE   role_resource_id = gn_resource_id
   AND     role_resource_type = 'RS_INDIVIDUAL'
   AND     end_date_active IS NOT NULL
   AND     delete_flag = 'N'
   AND     gd_job_asgn_date - 1
           BETWEEN start_date_active
           AND     end_date_active
   AND     role_relate_id NOT IN ( SELECT  role_relate_id
                                   FROM    jtf_rs_role_relations
                                   WHERE   role_resource_id = gn_resource_id
                                   AND     role_resource_type = 'RS_INDIVIDUAL'
                                   AND     end_date_active IS NULL
                                   AND     delete_flag = 'N'
                                 );

-- ------------------------------------------------------------------------
-- Cursor to fetch previous resource roles for future date scenario
-- -----------------------------------------------------------------------
   CURSOR  lcu_get_prev_roles_futuredate
   IS
   SELECT  role_relate_id
          ,object_version_number
   FROM    jtf_rs_role_relations JRRR
   WHERE   JRRR.role_resource_id   = gn_resource_id
   AND     JRRR.role_resource_type = 'RS_INDIVIDUAL'
   AND     JRRR.end_date_active IS NOT NULL
   AND     JRRR.delete_flag     = 'N'
   AND     JRRR.end_date_active = ( SELECT MAX(JRRR1.end_date_active)
                                    FROM   jtf_rs_role_relations JRRR1
                                    WHERE  JRRR1.role_resource_id   = gn_resource_id
                                    AND    JRRR1.role_resource_type = 'RS_INDIVIDUAL'
                                    AND    JRRR1.end_date_active IS NOT NULL
                                    AND    JRRR1.delete_flag = 'N'
                                   );


   CURSOR  lcu_get_curr_roles
   IS
   SELECT  JRRR.role_relate_id
          ,JRRR.start_date_active
          ,JRRR.object_version_number
   FROM    jtf_rs_role_relations  JRRR
          ,jtf_rs_roles_vl        JRRV
   WHERE   JRRR.role_resource_id   = gn_resource_id
   AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
   AND     JRRR.role_id            = JRRV.role_id
   AND     JRRR.end_date_active IS NULL
   AND     JRRR.delete_flag = 'N'  ;


   BEGIN

      DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES');

      IF lcu_check_roles%ISOPEN THEN

         CLOSE lcu_check_roles;

      END IF;

      OPEN  lcu_check_roles;
      FETCH lcu_check_roles INTO lc_check_roles;
      CLOSE lcu_check_roles;

      DEBUG_LOG('Other Roles Exists: '||NVL(lc_check_roles,'N'));

      IF  ( NVL(lc_check_roles,'N') = 'Y' ) THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0099_OTHER_ROLES_EXIST');
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                            ,p_msg_count               => 1 --x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_error_message_count     => 1 --x_msg_count
                            ,p_error_message_code      =>'XX_TM_0099_OTHER_ROLES_EXIST'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

         RAISE EX_TERMIN_PROG;

      END IF;


      IF lcu_get_res_details%ISOPEN THEN

         CLOSE lcu_get_res_details;

      END IF;

      OPEN  lcu_get_res_details;
      FETCH lcu_get_res_details INTO lr_res_details;
      CLOSE lcu_get_res_details;

      IF gd_crm_job_asgn_date > gd_job_asgn_date THEN


         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: HR Job Date less then CRM job Date. Should be Back Date Scenario.');

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Before Fetching Previous Res Roles for correcting EndDate for Back/Future dating');

         FOR  prev_role_rec IN lcu_get_prev_roles_backdate
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating End Date of Res Role Id: '||prev_role_rec.role_relate_id);
            ENDDATE_RES_ROLE
                           (P_ROLE_RELATE_ID  => prev_role_rec.role_relate_id,
                            P_END_DATE_ACTIVE => gd_job_asgn_date -1,
                            P_OBJECT_VERSION  => prev_role_rec.object_version_number,
                            X_RETURN_STATUS   => lc_return_status,
                            X_MSG_COUNT       => x_msg_count,
                            X_MSG_DATA        => x_msg_data
                           );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(x_msg_data);

               DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: ENDDATE_RES_ROLE Fails. ');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                 gc_return_status   := 'WARNING';
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => lc_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            END IF;


         END LOOP;  -- End loop, lcu_get_prev_roles_backdate

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res roles....');

         FOR  curr_role_rec IN lcu_get_curr_roles
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Role Id: '||curr_role_rec.role_relate_id);
            IF curr_role_rec.start_date_active > gd_job_asgn_date THEN

               BACKDATE_RES_ROLE
                          (P_ROLE_RELATE_ID     => curr_role_rec.role_relate_id,
                           P_START_DATE_ACTIVE  => gd_job_asgn_date,
                           P_OBJECT_VERSION     => curr_role_rec.object_version_number,
                           P_ATTRIBUTE14        => NULL,
                           X_RETURN_STATUS      => lc_return_status,
                           X_MSG_COUNT          => x_msg_count,
                           X_MSG_DATA           => x_msg_data
                          );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);

                  DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: BACKDATE_RES_ROLE Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                    gc_return_status   := 'WARNING';
                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code             => lc_return_status
                                        ,p_msg_count               => x_msg_count
                                        ,p_application_name        => GC_APPN_NAME
                                        ,p_program_type            => GC_PROGRAM_TYPE
                                        ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                        ,p_error_message_count     => x_msg_count
                                        ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => x_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MINOR'
                                        );
               ELSE
                  lc_update_resource := 'Y';
               END IF;

            END IF;

         END LOOP; -- END LOOP, lcu_get_curr_roles

      ELSIF gd_crm_job_asgn_date <  gd_job_asgn_date
      AND   gd_crm_job_asgn_date <> gd_job_asgn_date
      THEN

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: HR Job Date greater then CRM job Date. Should be Future Date Scenario.');


         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Before Fetching Previous Res Roles for correcting EndDate for Back/Future dating');
         FOR  prev_role_rec IN lcu_get_prev_roles_futuredate
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating End Date of Res Role Id 1: '||prev_role_rec.role_relate_id);
            ENDDATE_RES_ROLE
                           (P_ROLE_RELATE_ID  => prev_role_rec.role_relate_id,
                            P_END_DATE_ACTIVE => gd_job_asgn_date -1,
                            P_OBJECT_VERSION  => prev_role_rec.object_version_number,
                            X_RETURN_STATUS   => lc_return_status,
                            X_MSG_COUNT       => x_msg_count,
                            X_MSG_DATA        => x_msg_data
                           );


            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(x_msg_data);

               DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: ENDDATE_RES_ROLE Fails. ');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                 gc_return_status   := 'WARNING';
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => lc_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            END IF;


         END LOOP;  -- End loop, lcu_get_prev_roles_futuredate

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res roles....');
         FOR  curr_role_rec IN lcu_get_curr_roles
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Role Id: '||curr_role_rec.role_relate_id);

            IF curr_role_rec.start_date_active < gd_job_asgn_date THEN

               BACKDATE_RES_ROLE
                          (P_ROLE_RELATE_ID     => curr_role_rec.role_relate_id,
                           P_START_DATE_ACTIVE  => gd_job_asgn_date,
                           P_OBJECT_VERSION     => curr_role_rec.object_version_number,
                           P_ATTRIBUTE14        => NULL,
                           X_RETURN_STATUS      => lc_return_status,
                           X_MSG_COUNT          => x_msg_count,
                           X_MSG_DATA           => x_msg_data
                          );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);

                  DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: BACKDATE_RES_ROLE Fails. ');

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code             => lc_return_status
                                         ,p_msg_count               => x_msg_count
                                         ,p_application_name        => GC_APPN_NAME
                                         ,p_program_type            => GC_PROGRAM_TYPE
                                         ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_error_message_count     => x_msg_count
                                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                         ,p_error_message           => x_msg_data
                                         ,p_error_status            => GC_ERROR_STATUS
                                         ,p_notify_flag             => GC_NOTIFY_FLAG
                                         ,p_error_message_severity  =>'MINOR'
                                         );

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                    gc_return_status   := 'WARNING';

                  END IF;
               ELSE
                  lc_update_resource  := 'Y';
               END IF;

            END IF;

         END LOOP; -- END LOOP, lcu_get_curr_roles

      END IF; -- END IF, gd_crm_job_asgn_date > gd_job_asgn_date ;
      DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: End of Back/Future dation of Current Res Roles');

      IF (NVL(lc_update_resource,'N') = 'Y') THEN

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating Resource Dates using UPDT_DATES_RESOURCE.');
         UPDT_DATES_RESOURCE
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lr_res_details.resource_number
                       , p_source_name        =>  lr_res_details.source_name
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_object_version_num =>  lr_res_details.object_version_number
                       , x_return_status      =>  x_return_status
                       , x_msg_count          =>  x_msg_count
                       , x_msg_data           =>  x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);
            DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: UPDT_DATES_RESOURCE Fails. ');

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

            RAISE EX_TERMIN_PROG;

         END IF;

      END IF;  -- END IF, (NVL(lc_update_resource,'N') = 'Y')

      x_return_status := FND_API.G_RET_STS_SUCCESS;


      DEBUG_LOG('End Of Proc BACK_DATE_CURR_ROLES');


   EXCEPTION
      WHEN EX_TERMIN_PROG THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';

       WHEN OTHERS THEN

         x_return_status      := FND_API.G_RET_STS_ERROR;
         gc_return_status     := 'ERROR';
         x_msg_data := SQLERRM;
         WRITE_LOG(x_msg_data);

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
         gc_errbuf := FND_MESSAGE.GET;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                               p_return_code             => x_return_status
                              ,p_msg_count               => 1
                              ,p_application_name        => GC_APPN_NAME
                              ,p_program_type            => GC_PROGRAM_TYPE
                              ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                              ,p_program_id              => gc_conc_prg_id
                              ,p_module_name             => GC_MODULE_NAME
                              ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                              ,p_error_message_count     => 1
                              ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                              ,p_error_message           => x_msg_data
                              ,p_error_status            => GC_ERROR_STATUS
                              ,p_notify_flag             => GC_NOTIFY_FLAG
                              ,p_error_message_severity  =>'MAJOR'
                              );
   END  BACK_DATE_CURR_ROLES;

   -- +===================================================================+
   -- | Name  : ASSIGN_ROLE                                               |
   -- |                                                                   |
   -- | Description:       This Procedure shall assign roles to the       |
   -- |                    resource.                                      |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE ASSIGN_ROLE
                       (x_return_status  OUT NOCOPY VARCHAR2
                       ,x_msg_count      OUT NOCOPY NUMBER
                       ,x_msg_data       OUT NOCOPY VARCHAR2
                       )
   IS

      lc_mgr_flag                        VARCHAR2(1);
      ln_role_relate_id                  JTF_RS_ROLE_RELATIONS.role_relate_id%TYPE;
      lc_error_message                   VARCHAR2(1000);
      lc_return_status                   VARCHAR2(1);
      ln_msg_count                       NUMBER;
      lc_msg_data                        VARCHAR2(1000);
      lc_role_exists_flag                VARCHAR2(1);
      lc_supprt_flag                     VARCHAR2(1);

      lc_role_type_code                  JTF_RS_ROLES_VL.role_type_code%TYPE;
      lc_admin_flag                      JTF_RS_ROLES_VL.admin_flag%TYPE;
      lc_member_flag                     JTF_RS_ROLES_VL.member_flag%TYPE;
      lc_error_message                   VARCHAR2(1000);
      lc_job_role_exists_flg	         VARCHAR2(1);
      lc_job_name                        PER_JOBS.name%TYPE;
      lc_any_role_exists                 VARCHAR2(1);

      EX_TERMINATE_ROLE_ASGN             EXCEPTION;

      CURSOR  lcu_get_roles
      IS
      SELECT  JRRV.role_id
             ,JRRV.role_code
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id = JRJR.role_id
      AND     JRJR.job_id  = gn_job_id
      AND     JRRV.role_type_code ='CALLCENTER'
      AND     JRRV.role_type_code NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')
      AND     NVL(JRRV.active_flag,'N')    = 'Y'
      AND     JRRV.role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_role_relations
              WHERE   role_resource_id    = gn_resource_id
              AND     role_resource_type  ='RS_INDIVIDUAL'
              AND     delete_flag         = 'N'
              AND     gd_job_asgn_date
                      BETWEEN start_date_active
                      AND     NVL(end_date_active,gd_job_asgn_date));

      CURSOR  lcu_get_res_details
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;


      lr_res_details    lcu_get_res_details%ROWTYPE;

      CURSOR  lcu_check_roles
      IS
      SELECT  JRRV.role_type_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
      FROM    jtf_rs_roles_vl     JRRV
             ,jtf_rs_job_roles_vl JRJRV
      WHERE   JRJRV.role_id       = JRRV.role_id
      AND     JRRV.member_flag    = 'Y'
      AND     JRRV.role_type_code = 'CALLCENTER'
      AND     JRRV.role_type_code NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRJRV.job_id        = gn_job_id;

      lr_check_roles    lcu_check_roles%ROWTYPE;

      CURSOR lcu_chk_any_role_exists
      IS
      SELECT 'Y'
      FROM   jtf_rs_role_relations
      WHERE  role_resource_id    = gn_resource_id
      AND    role_resource_type  ='RS_INDIVIDUAL'
      AND    delete_flag         = 'N';


      CURSOR   lcu_chk_job_role_map_exists
      IS
      SELECT  'Y' role_exists
      FROM     per_jobs PJ
              ,jtf_rs_job_roles   JRJR
              ,jtf_rs_roles_b     JRRV
      WHERE    PJ.job_id                 = JRJR.job_id
      AND      PJ.job_id                 = gn_job_id
      AND      JRJR.role_id              = JRRV.role_id
      AND      NVL(JRRV.active_flag,'N') = 'Y';

      CURSOR lcu_get_job_name
      IS
      SELECT name
      FROM   per_jobs
      WHERE  job_id = gn_job_id;


   BEGIN

      DEBUG_LOG('Inside Proc: Assign_Role');

      DEBUG_LOG('Job Id: '||gn_job_id);

      IF ( NVL(gc_resource_exists,'N') = 'Y') THEN

      	    IF lcu_chk_job_role_map_exists%ISOPEN THEN
      	       CLOSE lcu_chk_job_role_map_exists;
      	    END IF;

      	    OPEN  lcu_chk_job_role_map_exists;
      	    FETCH lcu_chk_job_role_map_exists INTO lc_job_role_exists_flg;
      	    CLOSE lcu_chk_job_role_map_exists;

      	    IF (NVL(lc_job_role_exists_flg,'N') <> 'Y') THEN

      	         OPEN  lcu_get_job_name;
      	         FETCH lcu_get_job_name INTO lc_job_name;
      	         CLOSE lcu_get_job_name;

      	       	 FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0011_ROLE_NULL');
      	         FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id );
      	         FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name );
      	 	 gc_errbuf := FND_MESSAGE.GET;
      	 	 FND_MSG_PUB.add;

      	 	 WRITE_LOG(gc_errbuf);

      	 	 gc_return_status      :='WARNING';
      	 	 x_return_status       := FND_API.G_RET_STS_ERROR;

      	 	 IF gc_err_msg IS NOT NULL THEN
      	 	    gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      	 	 ELSE
      	 	    gc_err_msg := gc_errbuf;
      	 	 END IF;

      	 	 XX_COM_ERROR_LOG_PUB.log_error_crm(
      	 	                         p_return_code             => x_return_status
      	 	                        ,p_msg_count               => 1
      	 	                        ,p_application_name        => GC_APPN_NAME
      	 	                        ,p_program_type            => GC_PROGRAM_TYPE
      	 	                        ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
      	 	                        ,p_program_id              => gc_conc_prg_id
      	 	                        ,p_module_name             => GC_MODULE_NAME
      	 	                        ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
      	 	                        ,p_error_message_count     => 1
      	 	                        ,p_error_message_code      => 'XX_TM_0011_ROLE_NULL'
      	 	                        ,p_error_message           => gc_errbuf
      	 	                        ,p_error_status            => GC_ERROR_STATUS
      	 	                        ,p_notify_flag             => GC_NOTIFY_FLAG
      	 	                        ,p_error_message_severity  =>'MINOR'
      	 	                        );


      	 	IF lcu_chk_any_role_exists%ISOPEN THEN
      		   CLOSE lcu_chk_any_role_exists;
                END IF;

                OPEN  lcu_chk_any_role_exists;
                FETCH lcu_chk_any_role_exists INTO lc_any_role_exists;
                CLOSE lcu_chk_any_role_exists;

                IF (NVL(lc_any_role_exists,'N') = 'N') THEN

                      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0266_NO_RES_ROLE');
      	              gc_errbuf := FND_MESSAGE.GET;
      	              FND_MSG_PUB.add;

      	              WRITE_LOG(gc_errbuf);

      	              gc_return_status      :='WARNING';
      	              x_return_status       := FND_API.G_RET_STS_ERROR;

      	              IF gc_err_msg IS NOT NULL THEN
      	                 gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      	              ELSE
      	                 gc_err_msg := gc_errbuf;
      	              END IF;

      	              XX_COM_ERROR_LOG_PUB.log_error_crm(
      	                               p_return_code             => x_return_status
      	                              ,p_msg_count               => 1
      	                              ,p_application_name        => GC_APPN_NAME
      	                              ,p_program_type            => GC_PROGRAM_TYPE
      	                              ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
      	                              ,p_program_id              => gc_conc_prg_id
      	                              ,p_module_name             => GC_MODULE_NAME
      	                              ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
      	                              ,p_error_message_count     => 1
      	                              ,p_error_message_code      => 'XX_TM_0266_NO_RES_ROLE'
      	                              ,p_error_message           => gc_errbuf
      	                              ,p_error_status            => GC_ERROR_STATUS
      	                              ,p_notify_flag             => GC_NOTIFY_FLAG
      	                              ,p_error_message_severity  =>'MINOR'
      	                              );

               END IF;

         RAISE EX_TERMINATE_ROLE_ASGN;

         END IF;

      END IF;

      FOR  roles_rec IN lcu_get_roles
      LOOP

         lc_role_exists_flag := 'Y';

         DEBUG_LOG('Assigning role:'||roles_rec.role_id||': '||roles_rec.role_code||' to the resource');

         ASSIGN_ROLE_TO_RESOURCE
                 (p_api_version          => 1.0
                 ,p_commit               =>'T'
                 ,p_role_resource_type   =>'RS_INDIVIDUAL'
                 ,p_role_resource_id     => gn_resource_id
                 ,p_role_id              => roles_rec.role_id
                 ,p_role_code            => roles_rec.role_code
                 ,p_start_date_active    => gd_job_asgn_date
                 ,p_attribute14          => NULL
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 ,x_role_relate_id       => ln_role_relate_id
                 );

         x_msg_count := ln_msg_count;

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           WRITE_LOG(lc_msg_data);

           DEBUG_LOG('In Procedure:ASSIGN_ROLE: Proc: ASSIGN_ROLE_TO_RESOURCE Fails. ');

           IF NVL(gc_return_status,'A') <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
           END IF;

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                  p_return_code             => lc_return_status
                                 ,p_msg_count               => ln_msg_count
                                 ,p_application_name        => GC_APPN_NAME
                                 ,p_program_type            => GC_PROGRAM_TYPE
                                 ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                                 ,p_program_id              => gc_conc_prg_id
                                 ,p_module_name             => GC_MODULE_NAME
                                 ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                                 ,p_error_message_count     => ln_msg_count
                                 ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                 ,p_error_message           => lc_msg_data
                                 ,p_error_status            => GC_ERROR_STATUS
                                 ,p_notify_flag             => GC_NOTIFY_FLAG
                                 ,p_error_message_severity  =>'MINOR'
                                 );
         END IF;

      END LOOP;

      IF (NVL(lc_role_exists_flag,'N')  = 'Y') THEN

         IF lcu_get_res_details%ISOPEN THEN

            CLOSE lcu_get_res_details;

         END IF;

         OPEN  lcu_get_res_details;

         FETCH lcu_get_res_details INTO lr_res_details;

         CLOSE lcu_get_res_details;

         DEBUG_LOG('Inside Procedure:ASSIGN_ROLE ,Calling Proc Update Resource Dates');

         UPDT_DATES_RESOURCE
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lr_res_details.resource_number
                       , p_source_name        =>  lr_res_details.source_name
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_object_version_num =>  lr_res_details.object_version_number
                       , x_return_status      =>  x_return_status
                       , x_msg_count          =>  x_msg_count
                       , x_msg_data           =>  x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);

            DEBUG_LOG('In Procedure: ASSIGN_ROLE: Proc: UPDT_DATES_RESOURCE Fails. ');

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

            RAISE EX_TERMINATE_ROLE_ASGN;

         END IF;

      END IF;  -- END IF, (NVL(lc_role_exists_flag,'N')  = 'Y')


      x_return_status := FND_API.G_RET_STS_SUCCESS;


   EXCEPTION

    WHEN EX_TERMINATE_ROLE_ASGN THEN

      DEBUG_LOG('In Procedure: ASSIGN_ROLE: Program Terminated. ');

      x_return_status   := FND_API.G_RET_STS_ERROR;

      gc_return_status    := 'ERROR';

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.ASSIGN_ROLE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );
   END ASSIGN_ROLE;


   -- +===================================================================+
   -- | Name  : PROCESS_NEW_RESOURCE                                      |
   -- |                                                                   |
   -- | Description:       This Procedure shall check if roles exists for |
   -- |                    the job. This shall create new resources       |
   -- |                    in CRM calling the std API.This shall invoke   |
   -- |                    the procedure Assign_Role to assign the roles  |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_NEW_RESOURCE(x_resource_id      OUT NOCOPY  NUMBER
                                 ,x_return_status    OUT NOCOPY  VARCHAR2
                                 ,x_msg_count        OUT NOCOPY  NUMBER
                                 ,x_msg_data         OUT NOCOPY  VARCHAR2
                                 )

   IS

      lc_role_exists                VARCHAR2(1);
      lc_user_name                  FND_USER.user_name%TYPE;
      lc_error_message              VARCHAR2(1000);
      lc_termination_flag           VARCHAR2(1);
      lc_job_name                   PER_JOBS.name%TYPE;
      lc_role_type_flag             VARCHAR2(1);


      CURSOR   lcu_get_job
      IS
      SELECT   job_id
      FROM     per_all_assignments_f
      WHERE    person_id         = gn_person_id
      AND      business_group_id = gn_biz_grp_id
      AND      SYSDATE BETWEEN effective_start_date
                                 AND effective_end_date ;

      CURSOR   lcu_check_role
      IS
      SELECT  'Y' role_exists
      FROM     per_jobs PJ
              ,jtf_rs_job_roles   JRJR
              ,jtf_rs_roles_b     JRRV
      WHERE    PJ.job_id                 = JRJR.job_id
      AND      PJ.job_id                 = gn_job_id
      AND      JRJR.role_id              = JRRV.role_id
      AND      JRRV.role_type_code       = 'CALLCENTER'
      AND      JRRV.role_type_code      NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')
      AND      NVL(JRRV.active_flag,'N') = 'Y';

      CURSOR   lcu_get_fnd_user
      IS
      SELECT   user_name
      FROM     fnd_user
      WHERE    employee_id  =  gn_person_id
      AND      SYSDATE BETWEEN start_date
                             AND     end_date;


      CURSOR  lcu_check_termination
      IS
      SELECT  termination_status
      FROM   (SELECT  'Y' termination_status
              FROM    per_all_people_f       PAPF
                     ,per_periods_of_service PPOS
                     ,per_person_types       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   <= TRUNC (SYSDATE)
              AND    (PPT.system_person_type          = 'EX_EMP'
              OR      PPT.system_person_type          = 'EX_CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     TRUNC(SYSDATE)
                    BETWEEN  PAPF.effective_start_date
                    AND      PAPF.effective_end_date
              UNION
              SELECT  'Y' termination_status
              FROM    per_all_people_f       PAPF
                     ,per_periods_of_service PPOS
                     ,per_person_types       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   >= TRUNC (SYSDATE)
              AND    (PPT.system_person_type          = 'EMP'
              OR      PPT.system_person_type          = 'CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     TRUNC(SYSDATE)
                    BETWEEN  PAPF.effective_start_date
                    AND      PAPF.effective_end_date
              );

      CURSOR lcu_get_job_name
      IS
      SELECT name
      FROM   per_jobs
      WHERE  job_id = gn_job_id;

      CURSOR  lcu_get_role_type
      IS
      SELECT 'Y' FLAG
      FROM DUAL
      WHERE EXISTS
                 (SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')
                  )
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code = 'CALLCENTER'
                 );

      EX_TERMINATE_PRGM             EXCEPTION;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_NEW_RESOURCE');

      IF lcu_check_termination%ISOPEN THEN
         CLOSE lcu_check_termination;
      END IF;

      OPEN  lcu_check_termination;
      FETCH lcu_check_termination INTO lc_termination_flag;
      CLOSE lcu_check_termination;

      DEBUG_LOG('Resource Termination exists (Y/N): '||NVL(lc_termination_flag,'N'));

      IF ( NVL(lc_termination_flag,'N') = 'Y') THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0264_DONT_CREATE_RESOURE');
      	 lc_error_message  := FND_MESSAGE.GET;
      	 FND_MSG_PUB.add;

      	 WRITE_LOG(lc_error_message);

      	 IF gc_err_msg IS NOT NULL THEN
      	    gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
      	 ELSE
      	    gc_err_msg := lc_error_message;
      	 END IF;

      	 XX_COM_ERROR_LOG_PUB.log_error_crm(
      	                     p_return_code             => FND_API.G_RET_STS_ERROR
      	                    ,p_msg_count               => 1
      	                    ,p_application_name        => GC_APPN_NAME
      	                    ,p_program_type            => GC_PROGRAM_TYPE
      	                    ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
      	                    ,p_program_id              => gc_conc_prg_id
      	                    ,p_module_name             => GC_MODULE_NAME
      	                    ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
      	                    ,p_error_message_count     => 1
      	                    ,p_error_message_code      =>'XX_TM_0264_DONT_CREATE_RESOURE'
      	                    ,p_error_message           => lc_error_message
      	                    ,p_error_status            => GC_ERROR_STATUS
      	                    ,p_notify_flag             => GC_NOTIFY_FLAG
      	                    ,p_error_message_severity  =>'MAJOR'
      	                    );

      	 RAISE EX_TERMINATE_PRGM;

     END IF;

     IF lcu_get_job%ISOPEN THEN
        CLOSE lcu_get_job;
     END IF;

     OPEN  lcu_get_job;
     FETCH lcu_get_job INTO gn_job_id ;
     CLOSE lcu_get_job;

     DEBUG_LOG('Job_id:'||gn_job_id);

     IF gn_job_id IS NULL THEN

        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0008_JOB_NULL');
        lc_error_message  := FND_MESSAGE.GET;
        FND_MSG_PUB.add;

        WRITE_LOG(lc_error_message);

        IF gc_err_msg IS NOT NULL THEN
           gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
        ELSE
           gc_err_msg := lc_error_message;
        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => FND_API.G_RET_STS_ERROR
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      =>'XX_TM_0008_JOB_NULL'
                           ,p_error_message           => lc_error_message
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

        RAISE EX_TERMINATE_PRGM;

     END IF;

     OPEN  lcu_get_job_name;
     FETCH lcu_get_job_name INTO lc_job_name;
     CLOSE lcu_get_job_name;

     IF lcu_get_role_type%ISOPEN THEN
        CLOSE lcu_get_role_type;
     END IF;

     OPEN  lcu_get_role_type;
     FETCH lcu_get_role_type INTO lc_role_type_flag ;
     CLOSE lcu_get_role_type;

     IF  NVL(lc_role_type_flag,'N')= 'Y' THEN

        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0272_INVAL_JOB');
        FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id );
        FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name );
        gc_errbuf := FND_MESSAGE.GET;
        FND_MSG_PUB.add;
        WRITE_LOG(gc_errbuf);

        gc_return_status  := 'ERROR';

        IF gc_err_msg IS NOT NULL THEN
           gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
        ELSE
           gc_err_msg := gc_errbuf;
        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => x_return_status
                               ,p_msg_count               => 1
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                               ,p_error_message_count     => 1
                               ,p_error_message_code      => 'XX_TM_0272_INVAL_JOB'
                               ,p_error_message           => gc_errbuf
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                             );

        RAISE EX_TERMINATE_PRGM;

     END IF;

     IF lcu_check_role%ISOPEN THEN
        CLOSE lcu_check_role;
     END IF;

     OPEN  lcu_check_role;
     FETCH lcu_check_role INTO lc_role_exists;
     CLOSE lcu_check_role;

     IF lc_role_exists  = 'Y' THEN

        DEBUG_LOG('Role Exists for the Job');

        OPEN  lcu_get_fnd_user;
        FETCH lcu_get_fnd_user INTO lc_user_name;
        CLOSE lcu_get_fnd_user;

        DEBUG_LOG('Fnd_user_name:'||lc_user_name);

        --Standard API to create resource in CRM
        CREATE_RESOURCE
                       (p_api_version         => 1.0
                       ,p_commit              =>'T'
                       ,p_category            =>'EMPLOYEE'
                       ,p_source_id           => gn_person_id
                       ,p_source_number       => gc_employee_number
                       ,p_start_date_active   => gd_job_asgn_date
                       ,p_resource_name       => gc_full_name
                       ,p_source_name         => gc_full_name
                       ,p_user_name           => lc_user_name
                       ,p_attribute14         => TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       ,p_attribute15         => TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       ,x_return_status       => x_return_status
                       ,x_msg_count           => x_msg_count
                       ,x_msg_data            => x_msg_data
                       ,x_resource_id         => gn_resource_id
                       ,x_resource_number     => gc_resource_number
                       );

        IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

           x_resource_id       := gn_resource_id  ;

           DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE: Resource created successfully. ');

        ELSE

           WRITE_LOG(x_msg_data);

           DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE: Failed to create Resource');

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                               p_return_code             => x_return_status
                              ,p_msg_count               => x_msg_count
                              ,p_application_name        => GC_APPN_NAME
                              ,p_program_type            => GC_PROGRAM_TYPE
                              ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                              ,p_program_id              => gc_conc_prg_id
                              ,p_module_name             => GC_MODULE_NAME
                              ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                              ,p_error_message_count     => x_msg_count
                              ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                              ,p_error_message           => x_msg_data
                              ,p_error_status            => GC_ERROR_STATUS
                              ,p_notify_flag             => GC_NOTIFY_FLAG
                              ,p_error_message_severity  =>'MAJOR'
                              );

           RAISE EX_TERMINATE_PRGM;

         END IF;

         IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

            DEBUG_LOG('Assign Roles to the Resource. Calling Proc ASSIGN_ROLE');

            ASSIGN_ROLE
                      (x_return_status  => x_return_status
                      ,x_msg_count      => x_msg_count
                      ,x_msg_data       => x_msg_data
                      );

         END IF; --End of If resource created successfully then proccessing resources details

     ELSE    -- else for lc_role_exists  = 'Y',  ROLES DOES NOT EXISTS FOR THE JOB ID
        -- DEBUG_LOG('Role does not Exists for the Job');

        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0011_ROLE_NULL');
        FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id );
        FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name );
        gc_errbuf := FND_MESSAGE.GET;
        FND_MSG_PUB.add;

        WRITE_LOG(gc_errbuf);

        gc_return_status      :='WARNING';
        x_return_status       := FND_API.G_RET_STS_ERROR;

        IF gc_err_msg IS NOT NULL THEN
           gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
        ELSE
           gc_err_msg := gc_errbuf;
        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => x_return_status
                               ,p_msg_count               => 1
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                               ,p_error_message_count     => 1
                               ,p_error_message_code      => 'XX_TM_0011_ROLE_NULL'
                               ,p_error_message           => gc_errbuf
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MINOR'
                               );

     END IF;   -- lc_role_exists  = 'Y'


   EXCEPTION
      WHEN EX_TERMINATE_PRGM THEN

      DEBUG_LOG('Procedure PROCESS_NEW_RESOURCE Terminated.');

      x_return_status   := FND_API.G_RET_STS_ERROR;
      gc_return_status    :='ERROR';

      WHEN OTHERS THEN

      gc_return_status     :='ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_NEW_RESOURCE;

   -- +===================================================================+
   -- | Name  : PROCESS_RES_TERMINATION                                   |
   -- |                                                                   |
   -- | Description:       This Procedure shall invoke the procedure      |
   -- |                    ENDDATE_RES_ROLE to enddate the groupmembership|
   -- |                    This calls ENDDATE_RES_ROLE to enddate the role|
   -- |                    ,ENDDATE_SALESREP to enddate the salesreps     |
   -- |                    and ENDDATE_RESOURCE to enddate the resource.  |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE PROCESS_RES_TERMINATION
                              (x_return_status    OUT NOCOPY  VARCHAR2
                              ,x_msg_count        OUT NOCOPY  NUMBER
                              ,x_msg_data         OUT NOCOPY  VARCHAR2
                              )
   IS

      ln_object_version_number         NUMBER;
      ld_termination_date              PER_PERIODS_OF_SERVICE.actual_termination_date%TYPE;
      lc_error_message                 VARCHAR2(1000);
      lc_return_status                 VARCHAR2(1);
      ln_msg_count                     NUMBER;
      lc_msg_data                      VARCHAR2(1000);


      CURSOR  lcu_get_termination_details
      IS
      SELECT  PPS.actual_termination_date
             ,JRRE.object_version_number
      FROM    per_periods_of_service   PPS
             ,jtf_rs_resource_extns_vl JRRE
      WHERE   PPS.person_id          = gn_person_id
      AND     PPS.business_group_id  = gn_biz_grp_id
      AND     JRRE.source_id         = PPS.person_id;


      CURSOR  lcu_get_roles_to_enddate
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
      FROM    jtf_rs_role_relations    JRRR
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.end_date_active IS NULL
      AND     JRRR.delete_flag = 'N'  ;

      lr_termination_details         lcu_get_termination_details%ROWTYPE;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_RES_TERMINATION');

      IF lcu_get_termination_details%ISOPEN THEN
         CLOSE lcu_get_termination_details;
      END IF;

      OPEN  lcu_get_termination_details;
      FETCH lcu_get_termination_details INTO lr_termination_details;
      CLOSE lcu_get_termination_details;

      ln_object_version_number := lr_termination_details.object_version_number;
      ld_termination_date      := lr_termination_details.actual_termination_date;

      DEBUG_LOG('ln_object_version_number:'||ln_object_version_number);
      DEBUG_LOG('ld_termination_date:'||ld_termination_date);

      END_GRP_AND_RESGRPROLE
                    (p_group_id        => -1
                    ,p_end_date        => ld_termination_date
                    ,x_return_status   => x_return_status
                    ,x_msg_count       => x_msg_count
                    ,x_msg_data        => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: END_GRP_AND_RESGRPROLE Fails. ');

      ELSE

        DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: END_GRP_AND_RESGRPROLE Success');

      END IF;

      FOR  roles_to_enddate_rec  IN  lcu_get_roles_to_enddate
      LOOP

         DEBUG_LOG('End dating resource role:'||roles_to_enddate_rec.roles_relate_id);

         ENDDATE_RES_ROLE(
                       p_role_relate_id  => roles_to_enddate_rec.roles_relate_id,
                       p_end_date_active => ld_termination_date,
                       p_object_version  => roles_to_enddate_rec.roles_obj_ver_num,
                       x_return_status   => lc_return_status,
                       x_msg_count       => ln_msg_count,
                       x_msg_data        => lc_msg_data
                         );

         x_msg_count := ln_msg_count;

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(lc_msg_data);
            DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RES_ROLE Fails. ');

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => lc_return_status
                                  ,p_msg_count               => ln_msg_count
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                  ,p_error_message_count     => ln_msg_count
                                  ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                  ,p_error_message           => lc_msg_data
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MINOR'
                                  );

           IF NVL(gc_return_status,'A') <> 'ERROR' THEN

              gc_return_status := 'WARNING';

           END IF;

         ELSE

           DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RES_ROLE Success');

         END IF;

      END LOOP;

      ENDDATE_RESOURCE
                    ( p_resource_id        => gn_resource_id
                    , p_resource_number    => gc_resource_number
                    , p_end_date_active    => ld_termination_date
                    , p_object_version_num => ln_object_version_number
                    , x_return_status      => x_return_status
                    , x_msg_count          => x_msg_count
                    , x_msg_data           => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         WRITE_LOG(x_msg_data);
         DEBUG_LOG('In Procedure: PROCESS_RES_TERMINATION: Proc: ENDDATE_RESOURCE Fails. ');

         gc_return_status    := 'ERROR';

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => x_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                ,p_error_message_count     => x_msg_count
                                ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                ,p_error_message           => x_msg_data
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MAJOR'
                                );

      ELSE

         DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RESOURCE Success');

      END IF;


   EXCEPTION
      WHEN OTHERS THEN

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_TERMINATION'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_RES_TERMINATION;


   -- +===================================================================+
   -- | Name  : PROCESS_RES_CHANGES                                       |
   -- |                                                                   |
   -- | Description:       This Procedure shall fetch the job id from     |
   -- |                    HRMS and shall enddate the groupmembership     |
   -- |                    Shall check for the manager flag and shall     |
   -- |                    enddate Sales support roles. Shall invoke      |
   -- |                    PROCESS_RESOURCE_DETAILS for further processing|
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_RES_CHANGES
                              (x_return_status    OUT NOCOPY  VARCHAR2
                              ,x_msg_count        OUT NOCOPY  NUMBER
                              ,x_msg_data         OUT NOCOPY  VARCHAR2
                              )
   IS

      ln_job_id                  PER_ALL_ASSIGNMENTS_F.job_id%TYPE;
      lc_manager_flag            VARCHAR2(1);
      lc_error_message           VARCHAR2(1000);
      lc_return_status           VARCHAR2(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(1000);
      lc_back_date_salesrep      VARCHAR2(1);
      lc_job_change_exists       VARCHAR2(1) := 'N';
      lc_job_name                PER_JOBS.name%TYPE; -- 30/07/08
      lc_role_type_flag          VARCHAR2(1);
      lc_invalid_job_flag        VARCHAR2(1);
      ld_grp_mbr_start_date      DATE;
      lc_sales_rep_flag          VARCHAR2(1);

      EX_TERMINATE_PRGM          EXCEPTION;
      SKIP_FURTHER_PROCESS       EXCEPTION;

      CURSOR  lcu_get_job
      IS
      SELECT  job_id
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
      FROM    per_all_assignments_f PAAF
      WHERE   person_id         = gn_person_id
      AND     business_group_id = gn_biz_grp_id
      AND     SYSDATE
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,SYSDATE);

      CURSOR  lcu_get_roles_to_enddate(p_job_id   NUMBER)
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.delete_flag        = 'N'
      AND     gd_job_asgn_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_job_asgn_date)
      AND     JRRR.role_id NOT IN (
                                   SELECT  role_id
                                   FROM    jtf_rs_job_roles_vl
                                   WHERE   job_id  = p_job_id
                                  );

      CURSOR  lcu_get_mbr_rl_enddate(p_job_id   NUMBER)
      IS
      SELECT  JRGMR.role_relate_id MBR_RELATE_ID
             ,JRRR2.object_version_number MBR_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.delete_flag        = 'N'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     JRRR2.delete_flag       = 'N'
      AND     gd_job_asgn_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_job_asgn_date)
      AND     gd_job_asgn_date
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_job_asgn_date)
      AND     gd_job_asgn_date
              BETWEEN   JRRR2.start_date_active
              AND       NVL(JRRR2.end_date_active,gd_job_asgn_date)
      AND     JRRR.role_id NOT IN (
                                   SELECT  role_id
                                   FROM    jtf_rs_job_roles_vl
                                   WHERE   job_id  = p_job_id
                                  );

      CURSOR  lcu_check_res_st_date
      IS
      SELECT 'Y' BACK_DATE_EXISTS
             ,object_version_number
             ,source_name
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id  = gn_resource_id
      AND     start_date_active > gd_job_asgn_date;

      CURSOR  lcu_get_resource_det
      IS
      SELECT  TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
             ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      CURSOR  lcu_check_job_change(p_job_id   NUMBER)
      IS
      SELECT  'Y' job_change
      FROM    jtf_rs_role_relations JRRR
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.end_date_active IS NULL
      AND     JRRR.delete_flag = 'N'
      AND     JRRR.role_id NOT IN (
                                   SELECT  role_id
                                   FROM    jtf_rs_job_roles_vl
                                   WHERE   job_id  = p_job_id
                                  );
      CURSOR  lcu_get_job_date
      IS
      SELECT  DISTINCT start_date_active
      FROM    jtf_rs_role_relations
      WHERE   role_resource_type = 'RS_INDIVIDUAL'
      AND     end_date_active IS NULL
      AND     delete_flag = 'N'
      AND     role_resource_id   =  gn_resource_id;

      lr_check_resource              lcu_check_res_st_date%ROWTYPE;
      TYPE      date_tbl_type        IS TABLE OF DATE
      INDEX BY BINARY_INTEGER;
      lt_date   date_tbl_type;

      CURSOR  lcu_get_role_type
      IS
      SELECT 'Y' FLAG
      FROM DUAL
      WHERE EXISTS
                 (SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS')
                  )
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code ='CALLCENTER'
                 );

      CURSOR lcu_get_job_name
      IS
      SELECT name
      FROM   per_jobs
      WHERE  job_id = gn_job_id;

      CURSOR lcu_get_grp_mbr_date
      IS
      SELECT max(start_date_active)
      FROM   jtf_rs_group_mbr_role_vl
      WHERE  resource_id = gn_resource_id
      AND    end_date_active IS NULL;

      CURSOR   lcu_check_salesrep
      IS
      SELECT  'Y' sales_rep_flag
      FROM     jtf_rs_salesreps jrs
      WHERE    jrs.resource_id = gn_resource_id
        AND    NOT EXISTS (SELECT 1
                           FROM   jtf_rs_group_mbr_role_vl a,
                                  jtf_rs_roles_vl b
                           WHERE  a.resource_id = jrs.resource_id
                             AND  SYSDATE BETWEEN a.start_date_active AND NVL(a.end_date_active, SYSDATE+1)
                             AND  b.role_id     = a.role_id
                             AND  b.role_type_code = 'SALES'
                          );


   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_RES_CHANGES');

      IF lcu_check_salesrep%ISOPEN THEN
         CLOSE lcu_check_salesrep;
      END IF;

      OPEN  lcu_check_salesrep;
      FETCH lcu_check_salesrep INTO lc_sales_rep_flag;
      CLOSE lcu_check_salesrep;

      DEBUG_LOG('Sales rep exists (Y/N): '||NVL(lc_sales_rep_flag,'N'));

      IF (NVL(lc_sales_rep_flag,'N') = 'Y') THEN

        ENDDATE_SALESREP
                       (p_resource_id      => gn_resource_id
                       ,p_end_date_active  => gd_job_asgn_date - 1
                       ,x_return_status    => x_return_status
                       ,x_msg_count        => x_msg_count
                       ,x_msg_data         => x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);

            DEBUG_LOG('In Procedure:PROCESS_GENERIC_RES_DETAILS: Proc: ENDDATE_SALESREP Fails. ');

            gc_return_status    := 'WARNING';


           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                  p_return_code             => x_return_status
                                 ,p_msg_count               => x_msg_count
                                 ,p_application_name        => GC_APPN_NAME
                                 ,p_program_type            => GC_PROGRAM_TYPE
                                 ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                 ,p_program_id              => gc_conc_prg_id
                                 ,p_module_name             => GC_MODULE_NAME
                                 ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                 ,p_error_message_count     => x_msg_count
                                 ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                 ,p_error_message           => x_msg_data
                                 ,p_error_status            => GC_ERROR_STATUS
                                 ,p_notify_flag             => GC_NOTIFY_FLAG
                                 ,p_error_message_severity  =>'MINOR'
                                 );

         END IF;

      END IF; -- End if, NVL(lc_sales_rep_flag,'N') = 'Y'

      OPEN  lcu_get_resource_det;

      FETCH lcu_get_resource_det INTO gd_crm_job_asgn_date,gd_crm_mgr_asgn_date;

      CLOSE lcu_get_resource_det;

      IF lcu_get_job%ISOPEN THEN

         CLOSE lcu_get_job;

      END IF;

      OPEN  lcu_get_job;

      FETCH lcu_get_job INTO gn_job_id,gd_job_asgn_date,gd_mgr_asgn_date;

      CLOSE lcu_get_job;

      DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date);
      DEBUG_LOG('HRMS_MGR_ASGN_DATE:'||gd_mgr_asgn_date);

      IF gd_crm_job_asgn_date IS NULL THEN

         OPEN  lcu_get_job_date;

         FETCH lcu_get_job_date BULK COLLECT INTO lt_date;

         CLOSE lcu_get_job_date;

         --DEBUG_LOG('Job Assignment Date:'||lt_date);

         IF lt_date.count > 1 THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0095_NONUNQ_ROLE_DATE');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR
                               ,p_msg_count               => 1
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1
                               ,p_error_message_code      =>'XX_TM_0095_NONUNQ_ROLE_DATE'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         ELSIF lt_date.count = 0 THEN

            gd_crm_job_asgn_date:=gd_job_asgn_date;

         ELSE

            gd_crm_job_asgn_date :=  lt_date(1);

         END IF;

      END IF;  -- end if, gd_crm_job_asgn_date IS NULL

      IF gd_crm_mgr_asgn_date IS NULL THEN

         OPEN  lcu_get_job_date;

         FETCH lcu_get_job_date BULK COLLECT INTO lt_date;

         CLOSE lcu_get_job_date;

         IF lt_date.count = 0 THEN

            gd_crm_mgr_asgn_date:=gd_job_asgn_date;

         ELSE

            gd_crm_mgr_asgn_date :=  lt_date(1);

         END IF;

      END IF;  -- end if, gd_crm_mgr_asgn_date IS NULL

      DEBUG_LOG('CRM_JOB_ASGN_DATE:'||gd_crm_job_asgn_date);
      DEBUG_LOG('CRM_MGR_ASGN_DATE:'||gd_crm_mgr_asgn_date);

      IF lcu_check_job_change%ISOPEN THEN

         CLOSE lcu_check_job_change;

      END IF;

      OPEN  lcu_check_job_change(gn_job_id);

      FETCH lcu_check_job_change INTO lc_job_change_exists;

      CLOSE lcu_check_job_change;

      IF NVL(lc_job_change_exists,'N') = 'Y' THEN

	 IF lcu_get_job_name%ISOPEN THEN

	    CLOSE lcu_get_job_name;

         END IF;

	 OPEN  lcu_get_job_name;
         FETCH lcu_get_job_name INTO lc_job_name;
	 CLOSE lcu_get_job_name;

         IF lcu_get_role_type%ISOPEN THEN

            CLOSE lcu_get_role_type;

         END IF;

         OPEN  lcu_get_role_type;
         FETCH lcu_get_role_type INTO lc_role_type_flag;
         CLOSE lcu_get_role_type;

         IF  NVL(lc_role_type_flag,'N') = 'Y' THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0272_INVAL_JOB');
            FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id );
            FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name );
            gc_errbuf := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(gc_errbuf);

            gc_return_status  := 'ERROR';

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
            ELSE
               gc_err_msg := gc_errbuf;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                    p_return_code             => x_return_status
                                   ,p_msg_count               => 1
                                   ,p_application_name        => GC_APPN_NAME
                                   ,p_program_type            => GC_PROGRAM_TYPE
                                   ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_program_id              => gc_conc_prg_id
                                   ,p_module_name             => GC_MODULE_NAME
                                   ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_error_message_count     => 1
                                   ,p_error_message_code      => 'XX_TM_0272_INVAL_JOB'
                                   ,p_error_message           => gc_errbuf
                                   ,p_error_status            => GC_ERROR_STATUS
                                   ,p_notify_flag             => GC_NOTIFY_FLAG
                                   ,p_error_message_severity  =>'MAJOR'
                                 );

            RAISE EX_TERMINATE_PRGM;

         END IF;

         IF lcu_get_grp_mbr_date%ISOPEN THEN

            CLOSE lcu_get_grp_mbr_date;

         END IF;

         OPEN  lcu_get_grp_mbr_date;

         FETCH lcu_get_grp_mbr_date INTO ld_grp_mbr_start_date;

         CLOSE lcu_get_grp_mbr_date;

         IF gd_job_asgn_date < ld_grp_mbr_start_date THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0259_INV_JOB_ASGN_DT');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0259_INV_JOB_ASGN_DT'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         END IF;
      END IF;

       -- If Backdate or Future date or Job change Exists

       IF gd_crm_job_asgn_date > gd_job_asgn_date OR
          (gd_crm_job_asgn_date <  gd_job_asgn_date
            AND   gd_crm_job_asgn_date <> gd_job_asgn_date) OR
            NVL(lc_job_change_exists,'N') = 'Y' THEN


            IF lcu_check_res_st_date%ISOPEN THEN

               CLOSE lcu_check_res_st_date;

            END IF;

            OPEN  lcu_check_res_st_date;

            FETCH lcu_check_res_st_date INTO lr_check_resource;

            CLOSE lcu_check_res_st_date;

            DEBUG_LOG('lr_check_resource.back_date_exists:'||NVL(lr_check_resource.back_date_exists,'N'));

            IF (NVL(lr_check_resource.back_date_exists,'N') = 'Y') THEN

               BACKDATE_RESOURCE
                       ( p_resource_id        => gn_resource_id
                       , p_resource_number    => gc_resource_number
                       , p_source_name        => lr_check_resource.source_name
                       , p_start_date_active  => gd_job_asgn_date
                       , p_object_version_num => lr_check_resource.object_version_number
                       , x_return_status      => x_return_status
                       , x_msg_count          => x_msg_count
                       , x_msg_data           => x_msg_data
                       );

               IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);
                  DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: BACKDATE_RESOURCE Fails. ');

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MAJOR'
                                     );

                  RAISE EX_TERMINATE_PRGM;

               ELSE

                  DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: BACKDATE_RESOURCE Success ');

               END IF;

            END IF;  -- (NVL(lr_check_resource.back_date_exists,'N') = 'Y')

      END IF;

      DEBUG_LOG('Job Change Exists:'||NVL(lc_job_change_exists,'N'));

      IF (NVL(lc_job_change_exists,'N') = 'Y') THEN

         --
         -- If new job asgn date is lesser than old job assignment
         -- date error the process else the process shall continue
         --

         IF gd_crm_job_asgn_date > gd_job_asgn_date THEN

            DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date ||' is lesser than '||'CRM_JOB_ASGN_DATE:'||gd_crm_job_asgn_date);

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0091_ROLES_OVERLAP');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0091_ROLES_OVERLAP'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;
         END IF; -- END IF, gd_crm_job_asgn_date > gd_job_asgn_date;

      ELSE  -- NVL(lc_job_change_exists,'N') = 'Y'

         DEBUG_LOG('No Job change');

         BACK_DATE_CURR_ROLES
                        (x_return_status   => x_return_status
                        ,x_msg_count       => x_msg_count
                        ,x_msg_data        => x_msg_data
                        );

         IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

            DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: BACK_DATE_CURR_ROLES Success ');

            x_return_status := FND_API.G_RET_STS_SUCCESS;

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: BACK_DATE_CURR_ROLES Failed. ');

            RAISE EX_TERMINATE_PRGM;

         END IF;  -- END IF, x_return_status = FND_API.G_RET_STS_SUCCESS

      END IF; -- END IF, NVL(lc_job_change_exists,'N') = 'Y'


      IF gn_job_id IS NOT NULL  THEN

         DEBUG_LOG('Job id is not null');
         FOR  roles_to_enddate_rec  IN  lcu_get_mbr_rl_enddate(gn_job_id)
         LOOP
            DEBUG_LOG('End dating Resource Grp Role Relate Id:'||roles_to_enddate_rec.mbr_relate_id);
            ENDDATE_RES_GRP_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.mbr_relate_id,
                     P_END_DATE_ACTIVE => gd_job_asgn_date -1,
                     P_OBJECT_VERSION  => roles_to_enddate_rec.mbr_obj_ver_num,
                     X_RETURN_STATUS   => lc_return_status,
                     X_MSG_COUNT       => ln_msg_count,
                     X_MSG_DATA        => lc_msg_data
                     );

            x_msg_count := ln_msg_count;

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(lc_msg_data);
               DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: ENDDATE_RES_GRP_ROLE Fails for Group membership.');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                       p_return_code             => lc_return_status
                                      ,p_msg_count               => ln_msg_count
                                      ,p_application_name        => GC_APPN_NAME
                                      ,p_program_type            => GC_PROGRAM_TYPE
                                      ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_error_message_count     => ln_msg_count
                                      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                      ,p_error_message           => lc_msg_data
                                      ,p_error_status            => GC_ERROR_STATUS
                                      ,p_notify_flag             => GC_NOTIFY_FLAG
                                      ,p_error_message_severity  =>'MINOR'
                                      );


            ELSE

               DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_GRP_ROLE Success ');

            END IF;

         END LOOP;

         FOR  roles_to_enddate_rec  IN  lcu_get_roles_to_enddate(gn_job_id)
         LOOP
            DEBUG_LOG('roles_to_enddate_rec.roles_relate_id:'||roles_to_enddate_rec.roles_relate_id);

            ENDDATE_RES_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.roles_relate_id,
                     P_END_DATE_ACTIVE => gd_job_asgn_date -1,   -- SYSDATE - 1,
                     P_OBJECT_VERSION  => roles_to_enddate_rec.roles_obj_ver_num,
                     X_RETURN_STATUS   => lc_return_status,
                     X_MSG_COUNT       => ln_msg_count,
                     X_MSG_DATA        => lc_msg_data
                     );

            x_msg_count := ln_msg_count;

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(lc_msg_data);
               DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE Fails. ');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                       p_return_code             => lc_return_status
                                      ,p_msg_count               => ln_msg_count
                                      ,p_application_name        => GC_APPN_NAME
                                      ,p_program_type            => GC_PROGRAM_TYPE
                                      ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_error_message_count     => ln_msg_count
                                      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                      ,p_error_message           => lc_msg_data
                                      ,p_error_status            => GC_ERROR_STATUS
                                      ,p_notify_flag             => GC_NOTIFY_FLAG
                                      ,p_error_message_severity  =>'MINOR'
                                      );

            ELSE

               DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE Success');

            END IF;

         END LOOP;

         DEBUG_LOG('Assign Roles to the Resource. Calling Proc ASSIGN_ROLE');

         ASSIGN_ROLE
                   (x_return_status  => x_return_status
                   ,x_msg_count      => x_msg_count
                   ,x_msg_data       => x_msg_data
                   );

         IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN


           DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Resource details proccessed successfully');

         ELSE

           DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES:Failed to process Resource details for :'||gn_resource_id);

         END IF;

      ELSE

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0008_JOB_NULL');
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'PROCESS_RES_CHANGES'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0008_JOB_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

         RAISE EX_TERMINATE_PRGM;

      END IF;  -- END IF, gn_job_id IS NOT NULL


   EXCEPTION
      WHEN EX_TERMINATE_PRGM THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';


      WHEN SKIP_FURTHER_PROCESS THEN

      x_return_status      := FND_API.G_RET_STS_SUCCESS;
      gc_return_status     :='SUCCESS';



      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_RES_CHANGES'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_RES_CHANGES;

   -- +===================================================================+
   -- | Name  : PROCESS_EXISTING_RESOURCE                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall check for termination, if |
   -- |                    found PROCESS_RES_TERMINATION shall be invoked |
   -- |                    else  PROCESS_RES_CHANGES shall be called.     |
   -- |                                                                   |
   -- +===================================================================+



   PROCEDURE PROCESS_EXISTING_RESOURCE
                              (x_return_status    OUT NOCOPY  VARCHAR2
                              ,x_msg_count        OUT NOCOPY  NUMBER
                              ,x_msg_data         OUT NOCOPY  VARCHAR2
                              )
   IS

      lc_termination_flag    VARCHAR2(1);
      lc_error_message       VARCHAR2(1000);

      CURSOR  lcu_check_termination
      IS
      SELECT  termination_status
      FROM   (SELECT  'Y' termination_status
              FROM    per_all_people_f       PAPF
                     ,per_periods_of_service PPOS
                     ,per_person_types       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   <= TRUNC (SYSDATE)
              AND    (PPT.system_person_type          = 'EX_EMP'
              OR      PPT.system_person_type          = 'EX_CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     TRUNC(SYSDATE)
                      BETWEEN  PAPF.effective_start_date
                      AND      PAPF.effective_end_date
              UNION
              SELECT  'Y' termination_status
              FROM    per_all_people_f       PAPF
                     ,per_periods_of_service PPOS
                     ,per_person_types       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   >= TRUNC (SYSDATE)
              AND    (PPT.system_person_type          = 'EMP'
              OR      PPT.system_person_type          = 'CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     TRUNC(SYSDATE)
                        BETWEEN  PAPF.effective_start_date
                        AND      PAPF.effective_end_date
	      );
   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_EXISTING_RESOURCE');

      IF lcu_check_termination%ISOPEN THEN

         CLOSE lcu_check_termination;

      END IF;

      OPEN  lcu_check_termination;

      FETCH lcu_check_termination INTO lc_termination_flag;

      CLOSE lcu_check_termination;

      DEBUG_LOG('Resource Termination exists (Y/N): '||NVL(lc_termination_flag,'N'));

      IF ( NVL(lc_termination_flag,'N') = 'Y') THEN

         PROCESS_RES_TERMINATION
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      ELSE

         PROCESS_RES_CHANGES
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_EXISTING_RESOURCE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.PROCESS_EXISTING_RESOURCE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_EXISTING_RESOURCE;


   ------------------------------------------------------------------------
   ------------------------End of Internal Procs---------------------------
   ------------------------------------------------------------------------

   ------------------------------------------------------------------------
   --------------------------Exposed Proc---------------------------------
   ------------------------------------------------------------------------

   -- +===================================================================+
   -- | Name  : MAIN                                                      |
   -- |                                                                   |
   -- | Description:       This is the public procedure.The concurrent    |
   -- |                    program OD: CRM HR CM Synchronization Program  |
   -- |                    will call this public procedure                |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE MAIN
                 (x_errbuf            OUT VARCHAR2
                 ,x_retcode           OUT NUMBER
                 )
   IS
      EX_TERMIN_PRGM EXCEPTION;
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lc_return_status   VARCHAR2(5);
      ln_msg_count       PLS_INTEGER;
      lc_msg_data        VARCHAR2(1000);

      ln_resource_id     PLS_INTEGER ;
      ln_total_count     PLS_INTEGER ;
      ln_success         PLS_INTEGER ;
      ln_errored         PLS_INTEGER ;
      ln_warning         PLS_INTEGER ;
      lc_error_message   VARCHAR2(4000);
      lc_total_count     VARCHAR2(1000);
      lc_total_success   VARCHAR2(1000);
      lc_total_warning   VARCHAR2(1000);
      lc_total_failed    VARCHAR2(1000);
      ln_cnt             PLS_INTEGER ;
      lc_mandat_chk_flag VARCHAR2(1):= 'Y';
      lc_resource_exists VARCHAR2(1);


      -- -------------------------------------------------------
      -- Declare cursor to get all the Case Management employees
      -- -------------------------------------------------------

      CURSOR lcu_get_employees
      IS
      SELECT  PAAF.person_id           PERSON_ID
            , PAPF.full_name           FULL_NAME
            , PAPF.employee_number     EMPLOYEE_NUMBER
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , PAAF.job_id
      FROM    (SELECT *
               FROM per_all_assignments_f p1
               WHERE  trunc(SYSDATE) BETWEEN p1.effective_start_date
                 AND  DECODE((SELECT  system_person_type
	                      FROM    per_person_type_usages_f p
	                            , per_person_types         ppt
	                      WHERE   TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date
	      		      AND     PPT. person_type_id   =  p.person_type_id
	      	              AND     p.person_id           =  p1.person_id
			      AND     PPT.business_group_id =  gn_biz_grp_id),
			     'EX_EMP',TRUNC(SYSDATE),'EMP', p1.effective_end_date)) PAAF
            , (SELECT *
               FROM per_all_people_f p
               WHERE  trunc(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date
               ) PAPF
            ,  per_person_types         PPT
            , (SELECT *
               FROM per_person_type_usages_f p
               WHERE trunc(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
      WHERE    PAAF.person_id               = PAPF.person_id
      AND      PAPF.person_id               = PPTU.person_id
      AND      PPT. person_type_id          = PPTU.person_type_id
      -- AND      PAAF.ass_attribute2          = 'CSD'  -- Commented for bringing in resources with all CM roles (QC Defect# 15241)
      AND     (PPT.system_person_type       = 'EMP'
      OR       PPT.system_person_type       = 'EX_EMP')
      AND      PAAF.business_group_id       = gn_biz_grp_id
      AND      PAPF.business_group_id       = gn_biz_grp_id
      AND      PPT .business_group_id       = gn_biz_grp_id
      AND      PAPF.full_name IS NOT NULL
      AND      PAPF.employee_number IS NOT NULL
      AND      PAAF.ass_attribute10 IS NOT NULL
      AND      PAAF.job_id IS NOT NULL
      ORDER  BY last_name;

      TYPE employee_details_tbl_type IS TABLE OF lcu_get_employees%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_employee_details employee_details_tbl_type;

      -- -------------------------------------
      -- Check whether the resource exists/not
      -- -------------------------------------

      CURSOR   lcu_check_resource(p_person_id jtf_rs_resource_extns_vl.source_id%TYPE)
      IS
      SELECT  'Y' resource_exists
              ,resource_id
              ,resource_number
      FROM     jtf_rs_resource_extns_vl
      WHERE    source_id  = p_person_id;


   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN

       fnd_msg_pub.initialize;

       ln_total_count  := 0   ;
       ln_success      := 0   ;
       ln_errored      := 0   ;
       ln_warning      := 0   ;

       gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;

       gc_write_debug_to_log := FND_API.G_TRUE;

       SAVEPOINT PROCESS_RESOURCE_SP;
       -- --------------------------------------
       -- DISPLAY PROJECT NAME AND PROGRAM NAME
       -- --------------------------------------

        WRITE_LOG(RPAD('Office Depot',50)||'Date: '||trunc(SYSDATE));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_LOG(LPAD('Oracle HRMS - CRM Synchronization',52));

        WRITE_OUT(RPAD('EMPLOYEE NUMBER',35)||CHR(9)
                ||RPAD('EMPLOYEE NAME',55)||CHR(9)
                ||RPAD('MANAGER NAME',55)||CHR(9)
                ||RPAD('RESOURCE EXISTS(Y/N)',26)||CHR(9)
                ||RPAD('RESOURCE TYPE',20)||CHR(9)
                ||RPAD('STATUS',20)||CHR(9)
                ||'ERROR DESCRIPTION');

       -- -------------------------------------------------------
       -- Call Procedure Validate_Setups
       -- -------------------------------------------------------
       VALIDATE_SETUPS(ln_cnt);

       IF ln_cnt <> 2 THEN
          RAISE EX_TERMIN_PRGM;
       END IF;

       IF lcu_get_employees%ISOPEN THEN

          CLOSE lcu_get_employees;

       END IF;

       OPEN  lcu_get_employees;
       LOOP

          FETCH lcu_get_employees BULK COLLECT INTO lt_employee_details LIMIT 10000;

          IF lt_employee_details.count > 0 THEN

                FOR i IN lt_employee_details.first..lt_employee_details.last
                LOOP
                    x_retcode := NULL;
                    fnd_msg_pub.initialize;
                    -- --------------------------------
                    -- Reset the flag for each resource
                    -- --------------------------------

                    --Assigining the values into global variables
                    gn_person_id        := NULL;
                    gc_employee_number  := NULL;
                    gc_full_name        := NULL;
                    gn_resource_id      := NULL;
                    gc_resource_number  := NULL;
                    gn_job_id           := NULL;
                    gc_return_status    := NULL;
                    gd_job_asgn_date    := NULL;
                    gd_mgr_asgn_date    := NULL;
                    gc_err_msg          := NULL;
                    gn_msg_cnt_get      := 0;
                    gn_msg_cnt          := 0;
                    gc_msg_data         := NULL;

                    gn_person_id        := lt_employee_details(i).person_id;
                    gc_employee_number  := lt_employee_details(i).employee_number;
                    gc_full_name        := lt_employee_details(i).full_name;
                    gd_job_asgn_date    := lt_employee_details(i).job_asgn_date;
                    gn_job_id           := lt_employee_details(i).job_id;

                    WRITE_LOG(' ');
                    WRITE_LOG(RPAD(' ',76,'-'));
                    WRITE_LOG('Person Id : '||gn_person_id);
                    WRITE_LOG('Processing for the person name: '||gc_full_name);

                    IF gc_employee_number IS NULL THEN

		       lc_mandat_chk_flag := 'N';

		       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
		       FND_MESSAGE.SET_TOKEN('DETAILS', 'Employee Number' );
		       lc_error_message    := FND_MESSAGE.GET;
		       FND_MSG_PUB.add;

		       WRITE_LOG(lc_error_message);

		       IF gc_err_msg IS NOT NULL THEN
		          gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
		       ELSE
		          gc_err_msg := lc_error_message;
		       END IF;

		       XX_COM_ERROR_LOG_PUB.log_error_crm(
		                           p_return_code             => FND_API.G_RET_STS_ERROR
		                          ,p_msg_count               => 1
		                          ,p_application_name        => GC_APPN_NAME
		                          ,p_program_type            => GC_PROGRAM_TYPE
		                          ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                          ,p_program_id              => gc_conc_prg_id
		                          ,p_module_name             => GC_MODULE_NAME
		                          ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                          ,p_error_message_count     => 1
		                          ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
		                          ,p_error_message           => lc_error_message
		                          ,p_error_status            => GC_ERROR_STATUS
		                          ,p_notify_flag             => GC_NOTIFY_FLAG
		                          ,p_error_message_severity  =>'MAJOR'
		                          );

		     END IF;

		     IF gc_full_name IS NULL THEN

		        lc_mandat_chk_flag := 'N';

		        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
		        FND_MESSAGE.SET_TOKEN('DETAILS', 'Employee Name' );
		        lc_error_message    := FND_MESSAGE.GET;
		        FND_MSG_PUB.add;

		        WRITE_LOG(lc_error_message);

		        IF gc_err_msg IS NOT NULL THEN
		           gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
		        ELSE
		           gc_err_msg := lc_error_message;
		        END IF;

		        XX_COM_ERROR_LOG_PUB.log_error_crm(
		                            p_return_code             => FND_API.G_RET_STS_ERROR
		                           ,p_msg_count               => 1
		                           ,p_application_name        => GC_APPN_NAME
		                           ,p_program_type            => GC_PROGRAM_TYPE
		                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_program_id              => gc_conc_prg_id
		                           ,p_module_name             => GC_MODULE_NAME
		                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_error_message_count     => 1
		                           ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
		                           ,p_error_message           => lc_error_message
		                           ,p_error_status            => GC_ERROR_STATUS
		                           ,p_notify_flag             => GC_NOTIFY_FLAG
		                           ,p_error_message_severity  =>'MAJOR'
		                           );

		     END IF;

		     IF gn_job_id IS NULL THEN

		        lc_mandat_chk_flag := 'N';

		        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
		        FND_MESSAGE.SET_TOKEN('DETAILS', 'Job' );
		        lc_error_message    := FND_MESSAGE.GET;
		        FND_MSG_PUB.add;

		        WRITE_LOG(lc_error_message);

		        IF gc_err_msg IS NOT NULL THEN
		           gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
		        ELSE
		           gc_err_msg := lc_error_message;
		        END IF;

		        XX_COM_ERROR_LOG_PUB.log_error_crm(
		                            p_return_code             => FND_API.G_RET_STS_ERROR
		                           ,p_msg_count               => 1
		                           ,p_application_name        => GC_APPN_NAME
		                           ,p_program_type            => GC_PROGRAM_TYPE
		                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_program_id              => gc_conc_prg_id
		                           ,p_module_name             => GC_MODULE_NAME
		                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_error_message_count     => 1
		                           ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
		                           ,p_error_message           => lc_error_message
		                           ,p_error_status            => GC_ERROR_STATUS
		                           ,p_notify_flag             => GC_NOTIFY_FLAG
		                           ,p_error_message_severity  =>'MAJOR'
		                           );

		     END IF;

		     IF gd_job_asgn_date IS NULL THEN

		        lc_mandat_chk_flag := 'N';

		        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
		        FND_MESSAGE.SET_TOKEN('DETAILS', 'Job Assignment Date' );
		        lc_error_message    := FND_MESSAGE.GET;
		        FND_MSG_PUB.add;

		        WRITE_LOG(lc_error_message);

		        IF gc_err_msg IS NOT NULL THEN
		           gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
		        ELSE
		           gc_err_msg := lc_error_message;
		        END IF;

		        XX_COM_ERROR_LOG_PUB.log_error_crm(
		                            p_return_code             => FND_API.G_RET_STS_ERROR
		                           ,p_msg_count               => 1
		                           ,p_application_name        => GC_APPN_NAME
		                           ,p_program_type            => GC_PROGRAM_TYPE
		                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_program_id              => gc_conc_prg_id
		                           ,p_module_name             => GC_MODULE_NAME
		                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
		                           ,p_error_message_count     => 1
		                           ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
		                           ,p_error_message           => lc_error_message
		                           ,p_error_status            => GC_ERROR_STATUS
		                           ,p_notify_flag             => GC_NOTIFY_FLAG
		                           ,p_error_message_severity  =>'MAJOR'
		                           );

		     END IF;

		     IF lc_mandat_chk_flag = 'N' THEN
		        RAISE EX_TERMIN_PRGM;
		     END IF;

		     gn_job_id := NULL;

		     IF lcu_check_resource%ISOPEN THEN

		        CLOSE lcu_check_resource;

		     END IF;

		     lc_resource_exists := NULL;

		     OPEN  lcu_check_resource(lt_employee_details(i).person_id);

		     FETCH lcu_check_resource INTO lc_resource_exists,gn_resource_id,gc_resource_number;

		     CLOSE lcu_check_resource;

		     DEBUG_LOG('Is it an existing Resource (Y/N): ' ||NVL(lc_resource_exists,'N'));

		      gc_resource_exists := NVL(lc_resource_exists,'N');

		     IF ( NVL(lc_resource_exists,'N') = 'N' ) THEN

		        PROCESS_NEW_RESOURCE
		                    (x_resource_id      => ln_resource_id
		                    ,x_return_status    => lc_return_status
		                    ,x_msg_count        => ln_msg_count
		                    ,x_msg_data         => lc_msg_data
		                    );

		     ELSE   -- lc_resource_exists = 'N'  , WHEN RESOURCE EXISTS

		        WRITE_LOG('Resource Id:'||gn_resource_id);

		        PROCESS_EXISTING_RESOURCE
		                    (x_return_status    => lc_return_status
		                    ,x_msg_count        => ln_msg_count
		                    ,x_msg_data         => lc_msg_data
		                    );


		     END IF;  -- ( NVL(lc_resource_exists,'N') = 'N' )


                     WRITE_OUT(RPAD(NVL(gc_employee_number,'--'),34)||CHR(9)
                              ||RPAD(NVL(gc_full_name,'--'),55)||CHR(9)
                              ||RPAD(NVL(' ','--'),55)||CHR(9)
                              ||RPAD(NVL(gc_resource_exists,'--'),26)||CHR(9)
                              ||RPAD(NVL(' ','--'),20)||CHR(9)
                              ||RPAD(NVL(gc_return_status,'SUCCESS'),20)||CHR(9)
                              ||NVL(gc_err_msg,'--'));

                     WRITE_LOG('Processing Status: '||NVL(gc_return_status,'SUCCESS'));

                    -- ----------------------------------------------------------------------------
                    -- If any error occured during processing of Resources, Roles, Groups and Group
                    -- Membership.
                    -- ----------------------------------------------------------------------------

                    ln_total_count := ln_total_count + 1;

                    IF gc_return_status    = 'ERROR' THEN

                       ln_errored := ln_errored + 1;

                    ELSIF gc_return_status = 'WARNING' THEN

                       ln_warning := ln_warning + 1;

                    ELSE

                       ln_success := ln_success + 1;

                    END IF;

                END LOOP; -- lt_employee_details.first..lt_employee_details.last

            END IF;--lt_employee_details.count > 0

          EXIT WHEN lcu_get_employees%NOTFOUND;

       END LOOP;

       CLOSE lcu_get_employees;


       IF ln_total_count < 1 THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0001_EMPLOYEE_NOT_FOUND');
         FND_MESSAGE.SET_TOKEN('P_EMPLOYEE_ID', gn_person_id );
         FND_MESSAGE.SET_TOKEN('SYSDATE',  SYSDATE );

         lc_error_message := FND_MESSAGE.GET;
         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message;
         ELSE
            gc_err_msg := lc_error_message;
         END IF;
         WRITE_LOG(lc_error_message);

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0001_EMPLOYEE_NOT_FOUND'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );
       END IF;

       -- ----------------------------------------------------------------------------
       -- Write to output file, the total number of records processed, number of
       -- success and failure records.
       -- ----------------------------------------------------------------------------
       WRITE_OUT(' ');

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0002_RECORD_FETCHED');
       FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', ln_total_count );
       lc_total_count    := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_count);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0003_RECORD_SUCCESS');
       FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS',ln_success );
       lc_total_success  := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_success);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0048_RECORD_WARNING');
       FND_MESSAGE.SET_TOKEN('P_RECORD_WARNING',ln_warning );
       lc_total_warning  := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_warning);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0004_RECORD_FAILED');
       FND_MESSAGE.SET_TOKEN('P_RECORD_FAILED', ln_errored);
       lc_total_failed   := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_failed);

       -- Changed on 21/01/08
       IF ln_success = 0 AND ln_warning = 0 AND ln_errored = 0 THEN
          -- No Records
          x_retcode := 0; -- Green
       ELSIF ln_success > 0 AND ln_warning = 0 AND ln_errored = 0 THEN
          -- All Success
          x_retcode := 0 ; -- Green
       ELSIF ln_success = 0 AND ln_warning > 0 AND ln_errored = 0 THEN
          -- All Warning
          x_retcode := 1 ; -- Yellow
       ELSIF ln_success = 0 AND ln_warning = 0 AND ln_errored > 0 THEN
          -- All Error
          x_retcode := 2 ; -- Red
       ELSIF ln_success > 0 AND (ln_warning > 0 OR ln_errored > 0) THEN
          -- Some Success, Some Failure (Warning or Error)
          x_retcode := 1 ; -- Yellow
       ELSIF ln_success = 0 AND ln_warning > 0 AND ln_errored > 0 THEN
          -- No Success, Some Warning, Some Error
          x_retcode := 1 ; -- Yellow
       END IF;
       -- Changed on 21/01/08

   EXCEPTION
   WHEN EX_TERMIN_PRGM THEN
      x_errbuf  := 'Completed with errors because of missing setup ,  '||SQLERRM ;
      x_retcode := 2 ;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );
       ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;

      WHEN OTHERS THEN
      gc_return_status     :='ERROR';
      lc_return_status      := FND_API.G_RET_STS_ERROR;
      lc_msg_data := SQLERRM;
      WRITE_LOG(lc_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => lc_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_CM_SYNC_PKG.MAIN'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => lc_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

      ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;

   END MAIN;

END XX_CRM_HRCRM_CM_SYNC_PKG;
/

SHOW ERRORS
