SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT 'Creating XX_CRM_HRCRM_SYNC_PKG package body'
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_CRM_HRCRM_SYNC_PKG
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                        |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XXCRM_HRCRM_SYNC_PKG                                           |
  -- | Description      :  This custom package is needed to maintain Oracle CRM resources |
  -- |                     synchronized with changes made to employees in Oracle HRMS     |
  -- |                                                                                    |
  -- |                                                                                    |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  07-Jun-07   Prem Kumar       Initial draft version                        |
  -- |     5.3  14-Jun-07   Ankur Tandon     Version to be moved to UATTOPS               |
  -- +====================================================================================+

IS
   ----------------------------
   --Declaring Global Constants
   ----------------------------
   G_OD_SALES_ADMIN_GRP       CONSTANT VARCHAR2(30)            := 'OD_SALES_ADMIN_GRP';
   G_OD_PAYMENT_ANALYST_GRP   CONSTANT VARCHAR2(30)            := 'OD_PAYMENT_ANALYST_GRP';
   G_OD_SUPPORT_GRP           CONSTANT VARCHAR2(30)            := 'OD_SUPPORT_GRP';
   -- ---------------------------
   -- Global Variable Declaration
   -- ---------------------------

   gn_person_id               NUMBER                                                      ;
   gd_as_of_date              DATE                                                        ;
   gc_debug_flag              VARCHAR2(1) := FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG')     ;
   gc_errbuf                  VARCHAR2(2000)                                              ;
   gn_biz_grp_id              NUMBER      := FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID')   ;
   gc_employee_number         per_all_people_f.employee_number%TYPE := NULL               ;
   gc_full_name               per_all_people_f.full_name%TYPE       := NULL               ;
   gc_email_address           per_all_people_f.email_address%TYPE   := NULL               ;
   gn_resource_id             jtf_rs_resource_extns_vl.resource_id%TYPE                   ;
   gc_resource_number         jtf_rs_resource_extns_vl.resource_number%TYPE               ;
   gn_job_id                  per_all_assignments_f.job_id%TYPE                           ;

   gc_return_status           VARCHAR2(10)                                                ;
   -- This shall have the values a. SUCCESS,
   --                            b. ERROR,
   --                            c. WARNING

   gc_conc_prg_id              NUMBER                    DEFAULT   -1                     ;

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

      x_error_message VARCHAR2(2000);

   BEGIN

      fnd_file.put_line(fnd_file.log,p_message);

   EXCEPTION

      WHEN OTHERS THEN
      x_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,x_error_message);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_program_type            =>'CONCURRENT PROGRAM'
                                  ,p_program_name            =>'XXCRMHRCRMCONV'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                                  ,p_error_location          =>'WRITE_LOG'
                                  ,p_error_message_code      => SQLCODE
                                  ,p_error_message           => SQLERRM
                                  ,p_error_message_severity  =>'FATAL'
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

      x_error_message  varchar2(2000);

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

   EXCEPTION

      WHEN OTHERS THEN
      x_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,x_error_message);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_program_type            =>'CONCURRENT PROGRAM'
                                  ,p_program_name            =>'XXCRMHRCRMCONV'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                                  ,p_error_location          =>'WRITE_OUT'
                                  ,p_error_message_code      => SQLCODE
                                  ,p_error_message           => SQLERRM
                                  ,p_error_message_severity  =>'FATAL'
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

      x_error_message VARCHAR2(2000);

   BEGIN

      IF gc_debug_flag ='Y' THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0042_DEBUG_MSG');
         FND_MESSAGE.SET_TOKEN('DEBUG_MESG', p_message );
         FND_MSG_PUB.add;

      END IF;

   EXCEPTION

      WHEN OTHERS THEN
      x_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,x_error_message);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_program_type            =>'CONCURRENT PROGRAM'
                                  ,p_program_name            =>'XXCRMHRCRMCONV'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                                  ,p_error_location          =>'DEBUG_LOG'
                                  ,p_error_message_code      => SQLCODE
                                  ,p_error_message           => SQLERRM
                                  ,p_error_message_severity  =>'FATAL'
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
                  --, p_attribute15        IN  jtf_rs_resource_extns.attribute15%TYPE
                  , x_return_status      OUT NOCOPY  VARCHAR2
                  , x_msg_count          OUT NOCOPY  NUMBER
                  , x_msg_data           OUT NOCOPY  VARCHAR2
                  , x_resource_id        OUT NOCOPY  jtf_rs_resource_extns.resource_id%TYPE
                  , x_resource_number    OUT NOCOPY  jtf_rs_resource_extns.resource_number%TYPE
                  )
   IS

   BEGIN

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
--                    , p_attribute15         => p_attribute15
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    , x_resource_id         => x_resource_id
                    , x_resource_number     => x_resource_number
                    );

   END CREATE_RESOURCE;

   -- +===================================================================+
   -- | Name  : CREATE_SALES_REP                                          |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    sales reps creation in all the OU's.           |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE CREATE_SALES_REP
                  (
                    p_api_version            IN  NUMBER
                  , p_commit                 IN  VARCHAR2   DEFAULT  FND_API.G_FALSE
                  , p_resource_id            IN  jtf_rs_salesreps.resource_id%TYPE
                  , p_sales_credit_type_id   IN  jtf_rs_salesreps.sales_credit_type_id%TYPE
                  , p_salesrep_number        IN  jtf_rs_salesreps.salesrep_number%TYPE   DEFAULT NULL
                  , p_start_date_active      IN  jtf_rs_salesreps.start_date_active%TYPE DEFAULT NULL
                  , p_email_address          IN  jtf_rs_salesreps.email_address%TYPE     DEFAULT NULL
                  , x_return_status          OUT NOCOPY  VARCHAR2
                  , x_msg_count              OUT NOCOPY  NUMBER
                  , x_msg_data               OUT NOCOPY  VARCHAR2
                  , x_salesrep_id            OUT NOCOPY  jtf_rs_resource_extns.resource_id%TYPE
                  )
   IS

      ln_default_org_id   NUMBER;
      lc_return_status    VARCHAR2(1);

      -- -------------------------------------
      -- Cursor to get org_id
      -- -------------------------------------
      CURSOR   get_org_id
      IS
      SELECT   HOU.organization_id  org_id
      FROM     hr_operating_units HOU
              ,fnd_lookup_values FLV
      WHERE    FLV.lookup_type = 'OD_OPERATING_UNIT'
      AND      HOU.name        = FLV.lookup_code
      AND      HOU.organization_id NOT IN  (
                                             SELECT  org_id
                                             FROM    jtf_rs_salesreps
                                             WHERE   gd_as_of_date
                                                     BETWEEN  start_date_active
                                                     AND      NVL(end_date_active,gd_as_of_date)
                                             AND     resource_id = p_resource_id
                                           );

      CURSOR  check_salesrep(ln_org_id  NUMBER)
      IS
      SELECT 'Y' salesrep_flag
             ,salesrep_id
             ,sales_credit_type_id
             ,object_version_number
      FROM    jtf_rs_salesreps
      WHERE   resource_id = gn_resource_id
      AND     org_id      = ln_org_id;

      salesrep_rec                  check_salesrep%ROWTYPE;


   BEGIN

     ln_default_org_id  := fnd_profile.value('ORG_ID');

     FOR get_org_rec IN get_org_id
     LOOP

         dbms_application_info.set_client_info(get_org_rec.org_id);

         salesrep_rec  := NULL;

         IF check_salesrep%ISOPEN THEN
            CLOSE check_salesrep;
         END IF;

         OPEN  check_salesrep(get_org_rec.org_id);
         FETCH check_salesrep INTO salesrep_rec;
         CLOSE check_salesrep;

         IF (NVL(salesrep_rec.salesrep_flag,'N') <> 'Y') THEN

            JTF_RS_SALESREPS_PUB.create_salesrep
                       (
                         p_api_version          => p_api_version
                       , p_commit               => p_commit
                       , p_resource_id          => p_resource_id
                       , p_sales_credit_type_id => p_sales_credit_type_id
                       , p_salesrep_number      => p_salesrep_number
                       , p_start_date_active    => p_start_date_active
                       , p_end_date_active      => NULL
                       , p_email_address        => p_email_address
                       , x_return_status        => lc_return_status
                       , x_msg_count            => x_msg_count
                       , x_msg_data             => x_msg_data
                       , x_salesrep_id          => x_salesrep_id
                       );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               x_return_status := lc_return_status;

            END IF;

         ELSE

            JTF_RS_SALESREPS_PUB.update_salesrep
                             ( P_API_VERSION           => 1.0,
                               P_SALESREP_ID           => salesrep_rec.salesrep_id,
                               P_END_DATE_ACTIVE       => NULL,
                               P_ORG_ID                => get_org_rec.org_id,
                               P_SALES_CREDIT_TYPE_ID  => salesrep_rec.sales_credit_type_id,
                               P_OBJECT_VERSION_NUMBER => salesrep_rec.object_version_number,
                               X_RETURN_STATUS         => lc_return_status,
                               X_MSG_COUNT             => x_msg_count,
                               X_MSG_DATA              => x_msg_data
                             );

            x_salesrep_id :=  salesrep_rec.salesrep_id;

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               x_return_status := lc_return_status;

            END IF;

         END IF;

     END LOOP;

     dbms_application_info.set_client_info(ln_default_org_id);

     IF x_return_status <> FND_API.G_RET_STS_ERROR OR x_return_status <> FND_API.G_RET_STS_UNEXP_ERROR THEN

        x_return_status := FND_API.G_RET_STS_SUCCESS;

     END IF;

   END CREATE_SALES_REP;

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
      l_salesrep_exist_flag   VARCHAR2(1) := 'N';
      lc_return_status        VARCHAR2(1) ;

      CURSOR  get_salesreps
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

      FOR get_salesrep_rec IN get_salesreps
      LOOP

           l_salesrep_exist_flag := 'Y';
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

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  x_return_status := lc_return_status;

               END IF;

            END IF;

      END LOOP;

      IF l_salesrep_exist_flag = 'N' THEN

         DEBUG_LOG('No Salesreps attached to Resource ID: '||P_RESOURCE_ID ||' on date: '|| p_end_date_active);
      ELSE

         DEBUG_LOG('Salesreps End dated.');
      END IF;

     IF x_return_status <> FND_API.G_RET_STS_ERROR OR x_return_status <> FND_API.G_RET_STS_UNEXP_ERROR THEN

        x_return_status := FND_API.G_RET_STS_SUCCESS;
     END IF;


   END ENDDATE_SALESREP;

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
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 , x_role_relate_id     OUT NOCOPY  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
                 )
   IS

   BEGIN

      -- ---------------------
      -- CRM Standard API call
      -- ---------------------

      JTF_RS_ROLE_RELATE_PUB.Create_Resource_Role_Relate
                    (
                      p_api_version               => p_api_version
                    , p_commit                    => p_commit
                    , p_role_resource_type        => p_role_resource_type
                    , p_role_resource_id          => p_role_resource_id
                    , p_role_id                   => p_role_id
                    , p_role_code                 => p_role_code
                    , p_start_date_active         => p_start_date_active
                    , x_return_status             => x_return_status
                    , x_msg_count                 => x_msg_count
                    , x_msg_data                  => x_msg_data
                    , x_role_relate_id            => x_role_relate_id
                    );

   END ASSIGN_ROLE_TO_RESOURCE;

   -- +===================================================================+
   -- | Name  : CREATE_GROUP                                              |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    group creation.                                |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE CREATE_GROUP
                 (
                   p_api_version        IN  NUMBER
                 , p_commit             IN  VARCHAR2
                 , p_group_name         IN  jtf_rs_groups_vl.group_name%TYPE
                 , p_group_desc         IN  jtf_rs_groups_vl.group_desc%TYPE       DEFAULT  NULL
                 , p_exclusive_flag     IN  jtf_rs_groups_vl.exclusive_flag%TYPE   DEFAULT  'N'
                 , p_email_address      IN  jtf_rs_groups_vl.email_address%TYPE    DEFAULT  NULL
                 , p_start_date_active  IN  jtf_rs_groups_vl.start_date_active%TYPE
                 , p_end_date_active    IN  jtf_rs_groups_vl.end_date_active%TYPE  DEFAULT  NULL
                 , p_accounting_code    IN  jtf_rs_groups_vl.accounting_code%TYPE  DEFAULT  NULL
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 , x_group_id           OUT NOCOPY  jtf_rs_groups_vl.group_id%TYPE
                 , x_group_number       OUT NOCOPY  jtf_rs_groups_vl.group_number%TYPE
                 )
   IS

   BEGIN

       -- ---------------------
       -- CRM Standard API call
       -- ---------------------

       JTF_RS_GROUPS_PUB.create_resource_group
                     (
                       p_api_version       => p_api_version
                     , p_commit            => p_commit
                     , p_group_name        => p_group_name
                     , p_group_desc        => p_group_desc
                     , p_exclusive_flag    => p_exclusive_flag
                     , p_email_address     => p_email_address
                     , p_start_date_active => p_start_date_active
                     , p_end_date_active   => p_end_date_active
                     , p_accounting_code   => p_accounting_code
                     , x_return_status     => x_return_status
                     , x_msg_count         => x_msg_count
                     , x_msg_data          => x_msg_data
                     , x_group_id          => x_group_id
                     , x_group_number      => x_group_number
                     );

   END CREATE_GROUP;

   -- +===================================================================+
   -- | Name  : ASSIGN_RES_TO_GRP                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    assigning the resource to the group.           |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE ASSIGN_RES_TO_GRP
                       (
                         p_api_version        IN  NUMBER
                       , p_commit             IN  VARCHAR2
                       , p_group_id           IN  jtf_rs_group_members.group_id%TYPE
                       , p_group_number       IN  jtf_rs_groups_vl.group_number%TYPE
                       , p_resource_id        IN  jtf_rs_group_members.resource_id%TYPE
                       , p_resource_number    IN  jtf_rs_resource_extns.resource_number%TYPE
                       , x_return_status      OUT NOCOPY  VARCHAR2
                       , x_msg_count          OUT NOCOPY  NUMBER
                       , x_msg_data           OUT NOCOPY  VARCHAR2
                       , x_group_member_id    OUT NOCOPY  jtf_rs_group_members.group_member_id%TYPE
                       )
   IS

   BEGIN

       -- ---------------------
       -- CRM Standard API call
       -- ---------------------

       JTF_RS_GROUP_MEMBERS_PUB.create_resource_group_members
                     (
                       p_api_version               => p_api_version
                     , p_commit                    => p_commit
                     , p_group_id                  => p_group_id
                     , p_group_number              => p_group_number
                     , p_resource_id               => p_resource_id
                     , p_resource_number           => p_resource_number
                     , x_return_status             => x_return_status
                     , x_msg_count                 => x_msg_count
                     , x_msg_data                  => x_msg_data
                     , x_group_member_id           => x_group_member_id
                     );

   END ASSIGN_RES_TO_GRP;

   -- +===================================================================+
   -- | Name  : ASSIGN_ROLE_TO_GROUP                                      |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    assigning the roles to the group.              |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE ASSIGN_ROLE_TO_GROUP(
                        p_role_resource_id IN  jtf_rs_role_relations.role_resource_id%TYPE
                       ,p_role_id          IN  jtf_rs_role_relations.role_id%TYPE
                       ,p_start_date       IN  jtf_rs_role_relations.start_date_active%TYPE
                       ,x_return_status    OUT NOCOPY VARCHAR2
                       ,x_msg_count        OUT NOCOPY NUMBER
                       ,x_msg_data         OUT NOCOPY VARCHAR2
                       )
   AS

      lc_role_code            JTF_RS_ROLES_VL.role_code% TYPE;
      lc_role_resource_type   JTF_RS_ROLE_RELATIONS.role_resource_type%TYPE := 'RS_GROUP';
      lc_error_message        VARCHAR2(1000);
      ln_role_relate_id       JTF_RS_ROLE_RELATIONS.role_relate_id%TYPE;

      CURSOR get_role_code
      IS
      SELECT JRV.role_code
      FROM   jtf_rs_roles_vl JRV,
             fnd_lookups     LOOKUP
      WHERE  JRV.role_type_code  = LOOKUP.lookup_code
      AND    JRV.role_id         = p_role_id
      AND    LOOKUP.lookup_type  ='JTF_RS_ROLE_TYPE'
      AND    LOOKUP.enabled_flag ='Y';

   BEGIN

      jtf_rs_role_relate_pub.create_resource_role_relate
        (p_api_version          =>  1.0,
         p_init_msg_list        =>  FND_API.G_FALSE,
         p_commit               =>  FND_API.G_FALSE,
         p_role_resource_type   =>  lc_role_resource_type,
         p_role_resource_id     =>  p_role_resource_id,
         p_role_id              =>  p_role_id,
         p_role_code            =>  lc_role_code,
         p_start_date_active    =>  p_start_date,
--         p_end_date_active      =>  ln_end_date_active,
         x_return_status        =>  x_return_status ,
         x_msg_count            =>  x_msg_count     ,
         x_msg_data             =>  x_msg_data      ,
         x_role_relate_id       =>  ln_role_relate_id
        );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          DEBUG_LOG('In Procedure:ASSIGN_ROLE_TO_GROUP: Proc: jtf_rs_role_relate_pub.create_resource_role_relate Fails for role id: '||p_role_id);

        ELSE

          DEBUG_LOG('In Procedure:ASSIGN_ROLE_TO_GROUP: Proc: jtf_rs_role_relate_pub.create_resource_role_relate Success for role id: '||p_role_id);

        END IF;

        FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                   p_data  => x_msg_data);

  EXCEPTION

     WHEN OTHERS THEN

       gc_return_status  := 'ERROR';
       x_return_status   := FND_API.G_RET_STS_ERROR;

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_error_message     :=  'In Procedure:ASSIGN_ROLE_TO_GROUP: Unexpected Error: ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       --lc_error_message     := FND_MESSAGE.GET;
       FND_MSG_PUB.add;
       FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                  p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'ASSIGN_ROLE_TO_GROUP'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END ASSIGN_ROLE_TO_GROUP;

   -- +===================================================================+
   -- | Name  : ASSIGN_RES_TO_GROUP_ROLE                                  |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    assigning the roles to the members of the      |
   -- |                    group.                                         |
   -- +===================================================================+

   PROCEDURE ASSIGN_RES_TO_GROUP_ROLE
                 (
                   p_api_version        IN  NUMBER
                 , p_commit             IN  VARCHAR2
                 , p_resource_id        IN  NUMBER
                 , p_group_id           IN  NUMBER
                 , p_role_id            IN  NUMBER
                 , p_start_date         IN  DATE
                 , p_end_date           IN  DATE    DEFAULT NULL
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 )
   IS

   BEGIN

      -- ---------------------
      -- CRM Standard API call
      -- ---------------------

      JTF_RS_GRP_MEMBERSHIP_PUB.create_group_membership
               (
                 p_api_version       => p_api_version
               , p_commit            => p_commit
               , p_resource_id       => p_resource_id
               , p_group_id          => p_group_id
               , p_role_id           => p_role_id
               , p_start_date        => p_start_date
               , p_end_date          => p_end_date
               , x_return_status     => x_return_status
               , x_msg_count         => x_msg_count
               , x_msg_data          => x_msg_data
               );

   END ASSIGN_RES_TO_GROUP_ROLE;

   -- +===================================================================+
   -- | Name  : ASSIGN_TO_PARENT_GROUP                                    |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    creating the Parent-Child hierarchy between the|
   -- |                    groups.                                        |
   -- +===================================================================+


   PROCEDURE ASSIGN_TO_PARENT_GROUP
                 (
                   p_api_version         IN  NUMBER
                 , p_commit              IN  VARCHAR2 DEFAULT FND_API.G_FALSE
                 , p_group_id            IN  jtf_rs_groups_b.group_id%TYPE
                 , p_group_number        IN  jtf_rs_groups_b.GROUP_NUMBER%TYPE
                 , p_related_group_id    IN  jtf_rs_grp_relations.related_group_id%TYPE
                 , p_related_group_number IN jtf_rs_groups_b.GROUP_NUMBER%TYPE
                 , p_relation_type       IN  jtf_rs_grp_relations.relation_type%TYPE
                 , p_start_date_active   IN  jtf_rs_grp_relations.start_date_active%TYPE
                 , p_end_date_active     IN  jtf_rs_grp_relations.end_date_active%TYPE   DEFAULT  NULL
                 , x_return_status       OUT NOCOPY  VARCHAR2
                 , x_msg_count           OUT NOCOPY  NUMBER
                 , x_msg_data            OUT NOCOPY  VARCHAR2
                 , x_group_relate_id     OUT jtf_rs_grp_relations.group_relate_id%TYPE
                 )
   IS

   BEGIN

       -- ---------------------
       -- CRM Standard API call
       -- ---------------------

       JTF_RS_GROUP_RELATE_PUB.create_resource_group_relate
                    (
                      p_api_version         => p_api_version
                    , p_commit              => p_commit
                    , p_group_id            => p_group_id
                    , p_group_number        => p_group_number
                    , p_related_group_id    => p_related_group_id
                    , p_related_group_number=> p_related_group_number
                    , p_relation_type       => p_relation_type
                    , p_start_date_active   => p_start_date_active
                    , p_end_date_active     => p_end_date_active
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    , x_group_relate_id     => x_group_relate_id
                    );

   END ASSIGN_TO_PARENT_GROUP;

   -- +===================================================================+
   -- | Name  : CREATE_GROUP_USAGE                                        |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    creating the group usages in sales, sales comp |
   -- |                    SF planning and collections.                   |
   -- +===================================================================+


   PROCEDURE CREATE_GROUP_USAGE
                     ( p_group_id           jtf_rs_groups_vl.group_id%TYPE
                     , p_group_number       jtf_rs_groups_vl.group_number%TYPE
                     , x_return_status      OUT NOCOPY VARCHAR2
                     , x_msg_count          OUT NOCOPY NUMBER
                     , x_msg_data           OUT NOCOPY VARCHAR2
                     )
   IS

      ln_group_usage_id  NUMBER;
      lc_return_status   VARCHAR2(1);
      lc_error_message   VARCHAR2(1000);

      CURSOR get_group_usages
      IS
      SELECT lookup_code
      FROM   fnd_lookups
      WHERE  lookup_type = 'JTF_RS_USAGE'
      AND    lookup_code in ('SALES','SALES_COMP','SF_PLANNING','IEX_COLLECTIONS')
      AND    TRUNC(NVL(end_date_active, gd_as_of_date)) >= TRUNC(gd_as_of_date)
      AND    enabled_flag = 'Y'
      AND    lookup_code NOT IN
             ( SELECT  lookup_code
               FROM    jtf_rs_group_usages
               WHERE   group_id  = p_group_id);

   BEGIN

      FOR  group_usage_rec IN get_group_usages
      LOOP

        jtf_rs_group_usages_pub.create_group_usage
              (P_API_VERSION          => 1.0,
               P_INIT_MSG_LIST        => FND_API.G_FALSE,
               P_COMMIT               => FND_API.G_TRUE,
               P_GROUP_ID             => p_group_id,
               P_GROUP_NUMBER         => p_group_number,
               P_USAGE                => group_usage_rec.lookup_code,
               x_return_status        => lc_return_status,
               x_msg_count            => x_msg_count,
               x_msg_data             => x_msg_data,
               X_GROUP_USAGE_ID       => ln_group_usage_id
              ) ;



         IF  lc_return_status  <> FND_API.G_RET_STS_SUCCESS THEN

            DEBUG_LOG('In Procedure:CREATE_GROUP_USAGE: Proc: JTF_RS_GROUP_USAGES_PUB.create_group_usage Fails');

            IF gc_return_status <> 'ERROR'  THEN

               gc_return_status   := 'WARNING';

            END IF;

         END IF;

      END LOOP;

      x_return_status := FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
     WHEN OTHERS THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:CREATE_GROUP_USAGE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'CREATE_GROUP_USAGE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END CREATE_GROUP_USAGE;

   -- +===================================================================+
   -- | Name  : ENDDATE_OFF_PARENT_GROUP                                  |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    enddating theParent-Child hierarchy between the|
   -- |                    groups.                                        |
   -- +===================================================================+


   PROCEDURE ENDDATE_OFF_PARENT_GROUP
                 (
                   p_group_relate_id      IN   jtf_rs_grp_relations.group_relate_id%TYPE
                 , p_end_date_active      IN   jtf_rs_grp_relations.end_date_active%TYPE
                 , p_object_version_num   IN   jtf_rs_grp_relations.object_version_number%TYPE
                 , x_return_status        OUT NOCOPY  VARCHAR2
                 , x_msg_count            OUT NOCOPY  NUMBER
                 , x_msg_data             OUT NOCOPY  VARCHAR2
                 )
   IS

      l_object_version_num   NUMBER;

   BEGIN

      l_object_version_num  :=  p_object_version_num;

      JTF_RS_GROUP_RELATE_PUB.update_resource_group_relate
                    (
                      p_api_version          => 1.0
                    , p_commit               => 'T'
                    , p_group_relate_id      => p_group_relate_id
                    , p_end_date_active      => p_end_date_active
                    , p_object_version_num   => l_object_version_num
                    , x_return_status        => x_return_status
                    , x_msg_count            => x_msg_count
                    , x_msg_data             => x_msg_data
                    );

   END ENDDATE_OFF_PARENT_GROUP;

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

      l_object_version            NUMBER;

   BEGIN

      l_object_version :=  p_object_version;

      JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_END_DATE_ACTIVE     => P_END_DATE_ACTIVE,
         P_OBJECT_VERSION_NUM  => l_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
        );

   END ENDDATE_RES_GRP_ROLE;

   -- +===================================================================+
   -- | Name  : ENDDATE_GROUP                                             |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    enddate the group.                             |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE  ENDDATE_GROUP
                  (
                  p_group_id           IN  JTF_RS_GROUPS_VL.group_id%TYPE,
                  p_group_number       IN  JTF_RS_GROUPS_VL.group_number%TYPE,
                  p_end_date           IN  JTF_RS_GROUPS_VL.end_date_active%TYPE,
                  p_object_version_num IN  NUMBER,
                  x_return_status      OUT NOCOPY  VARCHAR2,
                  x_msg_count          OUT NOCOPY  NUMBER,
                  x_msg_data           OUT NOCOPY  VARCHAR2
                  )
   IS

      l_object_version        NUMBER;
   BEGIN

      l_object_version  :=  p_object_version_num;

       JTF_RS_GROUPS_PUB.update_resource_group
                       (P_API_VERSION          => 1.0,
                        P_GROUP_ID             => p_group_id,
                        P_GROUP_NUMBER         => p_group_number,
                        P_END_DATE_ACTIVE      => p_end_date,
                        P_OBJECT_VERSION_NUM   => l_object_version,
                        X_RETURN_STATUS        => x_return_status,
                        X_MSG_COUNT            => x_msg_count,
                        X_MSG_DATA             => x_msg_data
                       );

   END ENDDATE_GROUP;

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
      l_object_version            NUMBER;
   BEGIN

      l_object_version :=  p_object_version;

      JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_END_DATE_ACTIVE     => P_END_DATE_ACTIVE,
         P_OBJECT_VERSION_NUM  => l_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
        );

   END;

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

   BEGIN

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

   END ENDDATE_RESOURCE;



   ------------------------------------------------------------------------
   -------------------------End of API Calls-------------------------------
   ------------------------------------------------------------------------

   ------------------------------------------------------------------------
   -------------------------Internal Procs---------------------------------
   ------------------------------------------------------------------------

   -- +===================================================================+
   -- | Name  : END_GRP_AND_RESGRPROLE                                    |
   -- |                                                                   |
   -- | Description:       This Procedure shall enddate the previous group|
   -- |                    memberships and shall also enddate the group   |
   -- |                    if the resource is the last in the group.      |
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

      ln_group_cnt               NUMBER;
      lc_mbrship_exists_flag     VARCHAR2(1);
      ln_old_group_id            NUMBER;
      lc_lastin_grp_flag         VARCHAR2(1);
      lc_error_message           VARCHAR2(1000);
      lc_return_status           VARCHAR2(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(1000);




      TYPE group_table IS TABLE OF jtf_rs_groups_vl.group_id%type INDEX BY BINARY_INTEGER;
      group_tbl  group_table;

      CURSOR  check_old_group_mbrship
      IS
      SELECT  'Y' GRP_MBRSHIP
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_group_mbr_role_vl
      WHERE   resource_id = gn_resource_id
      AND     group_id   <> p_group_id
      AND     end_date_active is NULL);

      CURSOR  get_old_group_mbrship
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

      CURSOR  check_lastin_grp (p_grp_id NUMBER)
      IS
      SELECT  'N' lastin_grp_flag
      FROM    jtf_rs_group_mbr_role_VL
      WHERE   resource_id <> gn_resource_id
      AND     group_id    =  p_grp_id
      AND     NVL(end_date_active,p_end_date+1) > p_end_date;

      CURSOR  get_group_det(p_grp_id NUMBER)
      IS
      SELECT  group_id
             ,group_number
             ,object_version_number
      FROM    jtf_rs_groups_vl
      WHERE   group_id = p_grp_id;

      CURSOR  get_group_role(p_grp_id NUMBER)
      IS
      SELECT  role_relate_id
             ,object_version_number
      FROM    jtf_rs_role_relations
      WHERE   delete_flag = 'N'
      AND     role_resource_type = 'RS_GROUP'
      AND     role_resource_id = p_grp_id;

      CURSOR  get_old_relation(p_grp_id NUMBER)
      IS
      SELECT  related_group_id
             ,group_relate_id
             ,object_version_number
      FROM    jtf_rs_grp_relations_vl
      WHERE   group_id = p_grp_id
      AND     delete_flag   = 'N'
      AND     relation_type = 'PARENT_GROUP'
      AND     p_end_date
              BETWEEN start_date_active
              AND     NVL(end_date_active,p_end_date);

      group_det_rec              get_group_det%ROWTYPE;

   BEGIN

      ln_group_cnt := 1;
      group_tbl.delete;

      FOR  old_grp_mbrship_rec  IN  check_old_group_mbrship
      LOOP

         lc_mbrship_exists_flag := old_grp_mbrship_rec.grp_mbrship;
         EXIT;

      END LOOP;

--write_log('*old membership flag'||lc_mbrship_exists_flag);

      DEBUG_LOG('Old membership exists (Y/N) : '||NVL(lc_mbrship_exists_flag,'N'));

      IF ( lc_mbrship_exists_flag = 'Y' ) THEN

         FOR  group_mbrship_rec IN get_old_group_mbrship
         LOOP

            ENDDATE_RES_GRP_ROLE
               (p_role_relate_id   => group_mbrship_rec.role_relate_id
               ,p_end_date_active  => p_end_date
               ,p_object_version   => group_mbrship_rec.object_version_number
               ,x_return_status    => lc_return_status
               ,x_msg_count        => ln_msg_count
               ,x_msg_data         => lc_msg_data
               );

            IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
            THEN

               --In Fnd Message: P_MESSAGE
               lc_error_message    := 'END_GRP_AND_RESGRPROLE';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0013_ENDDTRSGRPROLE_F');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

               IF gc_return_status <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

            ELSE

               -- Note the group id if its not sales/admin/payment analyst group
               IF (ln_old_group_id IS NULL
               OR ln_old_group_id <> group_mbrship_rec.group_id) THEN

                  IF group_mbrship_rec.group_name NOT IN --('OD_SALES_ADMIN_GRP','OD_PAYMENT_ANALYST_GRP','OD_SUPPORT_GRP')
                    (G_OD_SALES_ADMIN_GRP,G_OD_PAYMENT_ANALYST_GRP,G_OD_SUPPORT_GRP) THEN

                     group_tbl(ln_group_cnt) := group_mbrship_rec.group_id;
                     ln_old_group_id := group_mbrship_rec.group_id;
                     ln_group_cnt    := ln_group_cnt + 1;

                  END IF;

               END IF;  -- END IF, ln_old_group_id <> group_mbrship_rec.group_id

            END IF;    -- lc_return_status <> fnd_api.G_RET_STS_SUCCESS

         END LOOP;  --  END LOOP, get_old_group_mbrship

      END IF;  -- End if, lc_mbrship_exists_flag = 'Y'

--write_log('*count '||group_tbl.count);

      IF ( group_tbl.count > 0 ) THEN
         FOR  i IN group_tbl.FIRST..group_tbl.LAST
         LOOP

             FOR  check_lastin_grp_rec IN check_lastin_grp(group_tbl(i))
             LOOP

                lc_lastin_grp_flag :=  check_lastin_grp_rec.lastin_grp_flag;
                EXIT;

             END LOOP;

             IF  NVL(lc_lastin_grp_flag,'Y') = 'Y' THEN

                DEBUG_LOG('Processing for Group ID: '||group_tbl(i));

                group_det_rec := NULL;

--                FOR  group_det_rec IN get_group_det(group_tbl(i))
--                LOOP

                IF get_group_det%ISOPEN THEN

                   CLOSE get_group_det;

                END IF;

                OPEN  get_group_det (group_tbl(i));
                FETCH get_group_det INTO group_det_rec;
                CLOSE get_group_det;


                FOR  group_role_rec IN get_group_role(group_det_rec.group_id)
                LOOP
--WRITE_LOG('* END DATE IS : '||p_end_date);

                  ENDDATE_RES_GRP_ROLE
                     (p_role_relate_id   => group_role_rec.role_relate_id
                     ,p_end_date_active  => p_end_date
                     ,p_object_version   => group_role_rec.object_version_number
                     ,x_return_status    => lc_return_status
                     ,x_msg_count        => ln_msg_count
                     ,x_msg_data         => lc_msg_data
                     );

                  IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
                  THEN

                     --In Fnd Message: P_MESSAGE
                     lc_error_message    := 'END_GRP_AND_RESGRPROLE';
                     FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0013_ENDDTRSGRPROLE_F');
                     FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
                     -- lc_error_message    := FND_MESSAGE.GET;
                     FND_MSG_PUB.add;

                     IF gc_return_status <> 'ERROR' THEN

                        gc_return_status := 'WARNING';

                     END IF;

                  ELSE

                     DEBUG_LOG('In Procedure:END_GRP_AND_RESGRPROLE: Proc: ENDDATE_RES_GRP_ROLE Success');

                  END IF;

                END LOOP;  -- END LOOP, get_group_role(group_det_rec.group_id)

                FOR  old_relation_rec IN get_old_relation(group_det_rec.group_id)
                LOOP

--WRITE_LOG('* End relation between group '||group_det_rec.group_id||' Group relate id '||old_relation_rec.group_relate_id);

                   ENDDATE_OFF_PARENT_GROUP
                                    ( p_group_relate_id      => old_relation_rec.group_relate_id
                                    , p_end_date_active      => p_end_date
                                    , p_object_version_num   => old_relation_rec.object_version_number
                                    , x_return_status        => lc_return_status
                                    , x_msg_count            => ln_msg_count
                                    , x_msg_data             => lc_msg_data
                                    );
--WRITE_LOG('* After end date old parent hierarchy');
                   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                     --In Fnd Message: P_MESSAGE
                     lc_error_message    := 'PROCESS_MANAGER_ASSIGNMENTS';
                     FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0044_ENDPRNTGRP_F');
                     FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
                     -- lc_error_message    := FND_MESSAGE.GET;
                     FND_MSG_PUB.add;

                     IF gc_return_status <> 'ERROR' THEN

                        gc_return_status := 'WARNING';

                     END IF;

                   ELSE
                     --In Fnd Message: P_MESSAGE
                     DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ENDDATE_OFF_PARENT_GROUP Success');
--                        FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0042_ASGNPRNTGRP_S');
--                        FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--                        -- lc_error_message    := FND_MESSAGE.GET;
--                        FND_MSG_PUB.add;

                   END IF;

                END LOOP;  -- END LOOP, get_old_relation

                ENDDATE_GROUP
                         (
                         p_group_id           => group_det_rec.group_id ,
                         p_group_number       => group_det_rec.group_number,
                         p_end_date           => p_end_date ,
                         p_object_version_num => group_det_rec.object_version_number,
                         x_return_status      => lc_return_status,
                         x_msg_count          => ln_msg_count,
                         x_msg_data           => lc_msg_data
                         );

                IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
                THEN

                  --In Fnd Message: P_MESSAGE
                  FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0043_ENDGRP_F');
                  -- lc_error_message    := FND_MESSAGE.GET;
                  FND_MSG_PUB.add;

                  IF gc_return_status <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                  END IF;

                ELSE

                   DEBUG_LOG('In Procedure:END_GRP_AND_RESGRPROLE: Proc: ENDDATE_GROUP Success');

                END IF;

--            END LOOP;   -- END LOOP, get_group_det(group_tbl(i))

            END IF;   -- END IF, NVL(lc_lastin_grp_flag,'Y') = 'Y'

            lc_lastin_grp_flag := NULL;

         END LOOP;   --  END LOOP, group_tbl.FIRST

      END IF;   -- End if, group_tbl.count> 0

      x_return_status  :=  FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:END_GRP_AND_RESGRPROLE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      gc_return_status := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'END_GRP_AND_RESGRPROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );


   END END_GRP_AND_RESGRPROLE;

   -- +===================================================================+
   -- | Name  : ASSIGN_ROLE                                               |
   -- |                                                                   |
   -- | Description:       This Procedure shall assign roles to the       |
   -- |                    resource. For resource having Manager role     |
   -- |                    the roles with sales support attribute shall   |
   -- |                    not be assigned.                               |
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


      EX_TERMINATE_ROLE_ASGN             EXCEPTION;

      CURSOR  get_job
      IS
      SELECT  job_id
      FROM    per_all_assignments_f
      WHERE   person_id         = gn_person_id
      AND     business_group_id = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      CURSOR CHECK_MGR
      IS
      SELECT 'Y' MANAGER_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1  -- Check for the current role assignment
      FROM    jtf_rs_role_relations JRRR
            , jtf_rs_roles_vl       JRRV
      where   JRRR.role_id           = JRRV.role_id
      AND     JRRR.role_resource_id  = gn_resource_id
      AND     JRRR.role_resource_type  ='RS_INDIVIDUAL'
      AND     JRRV.manager_flag = 'Y'
      AND     gd_as_of_date
      BETWEEN JRRR.start_date_active
      AND     NVL(JRRR.end_date_active,gd_as_of_date)
      UNION
      SELECT  1  -- Check for the new job assignment
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id      = JRJR.role_id
      AND     JRRV.manager_flag = 'Y'
      AND     JRRV.role_type_code IN ('SALES','SALES_COMP')
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRRV.manager_flag = 'Y'
      AND     JRJR.job_id       = gn_job_id
      );

      CURSOR  get_roles
      IS
      SELECT  JRRV.role_id
             ,JRRV.role_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
             ,JRRV.manager_flag
             ,JRRV.attribute14
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id = JRJR.role_id
      AND     JRJR.job_id  = gn_job_id
      AND     JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
      AND     NVL(JRRV.active_flag,'N')    = 'Y'
      AND     JRRV.role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_role_relations
              WHERE   role_resource_id    = gn_resource_id
              AND     role_resource_type  ='RS_INDIVIDUAL'
              AND     gd_as_of_date
                      BETWEEN start_date_active
                      AND     NVL(end_date_active,gd_as_of_date));


   BEGIN

      IF gn_job_id IS NULL THEN

         IF get_job%ISOPEN THEN
            CLOSE get_job;
         END IF;

         OPEN  get_job;
         FETCH get_job INTO gn_job_id;
         CLOSE get_job;

      END IF; -- END IF, gn_job_id IS NULL

      FOR  check_mgr_rec IN check_mgr
      LOOP
         lc_mgr_flag := check_mgr_rec.manager_flag;
         EXIT;
      END LOOP;

--WRITE_LOG('* mgr flag '||lc_mgr_flag);
--WRITE_LOG('* gd_as_of_date '||gd_as_of_date||' job id '||gn_job_id||' resource id '||gn_resource_id);

      FOR  roles_rec IN get_roles
      LOOP

         IF  roles_rec.attribute14 = 'SALES_SUPPORT'
         AND NVL(lc_mgr_flag, 'N') = 'Y' THEN

            --In Fnd Message: P_MESSAGE
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0037_SLSSUPPORT_F');
            FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', roles_rec.role_code );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
               gc_return_status  := 'WARNING';
            END IF;

         ELSE

            ASSIGN_ROLE_TO_RESOURCE
                 (p_api_version          => 1.0
                 ,p_commit               =>'T'
                 ,p_role_resource_type   =>'RS_INDIVIDUAL'
                 ,p_role_resource_id     => gn_resource_id
                 ,p_role_id              => roles_rec.role_id
                 ,p_role_code            => roles_rec.role_code
                 ,p_start_date_active    => gd_as_of_date
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 ,x_role_relate_id       => ln_role_relate_id
                 );

--WRITE_LOG('* role id '||roles_rec.role_id||' ,ln_role_relate_id '||ln_role_relate_id);

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

              FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0030_ASGNROLE_F');
              -- lc_error_message    := FND_MESSAGE.GET;
              FND_MSG_PUB.add;

              IF gc_return_status  <> 'ERROR' THEN
                 gc_return_status  := 'WARNING';
              END IF;

--              RAISE EX_TERMINATE_ROLE_ASGN;

            END IF;

         END IF;

      END LOOP;

      x_return_status := FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION

    WHEN EX_TERMINATE_ROLE_ASGN THEN

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0036_RLASGN_TERMINATE');
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);
    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:ASSIGN_ROLE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'ASSIGN_ROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END ASSIGN_ROLE;

   -- +===================================================================+
   -- | Name  : ASSGN_GRP_ROLE                                            |
   -- |                                                                   |
   -- | Description:       This Procedure shall assign resource to the    |
   -- |                    group and shall create group membership in the |
   -- |                    group.                                         |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE  ASSGN_GRP_ROLE
                     ( p_group_id        IN        NUMBER
                     , p_group_number    IN        VARCHAR2
                     , x_return_status  OUT NOCOPY VARCHAR2
                     , x_msg_count      OUT NOCOPY NUMBER
                     , x_msg_data       OUT NOCOPY VARCHAR2
                     )
   IS

      lc_grp_mbr_exists_flag              VARCHAR2(1);
      ln_group_mem_id                     JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      lc_error_message                    VARCHAR2(1000);
      lc_return_status                    VARCHAR2(1);
      ln_msg_count                        NUMBER;
      lc_msg_data                         VARCHAR2(1000);


      EX_TERMINATE_GRP_ROL_ASGN           EXCEPTION;

      CURSOR  check_grp_mbr_exists
      IS
      SELECT 'Y' grp_mbr
      FROM    jtf_rs_group_members_vl
      WHERE   resource_id  =  gn_resource_id
      AND     group_id     =  p_group_id
      AND     delete_flag  = 'N';

      -- Fetch only those roles that are currently not assigned to the group

      CURSOR  get_resource_roles
      IS
      SELECT  role_id
      FROM    jtf_rs_role_relations_vl
      WHERE   role_resource_id = gn_resource_id
      AND     gd_as_of_date
              BETWEEN start_date_active
              AND     NVL(end_date_active,gd_as_of_date)
      AND     role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_group_mbr_role_vl
              WHERE   resource_id = gn_resource_id
              AND     group_id    = p_group_id
              AND     gd_as_of_date
                      BETWEEN start_date_active
                      AND     NVL(end_date_active,gd_as_of_date));

   BEGIN

      FOR  grp_mbr_exists_rec IN check_grp_mbr_exists
      LOOP
         lc_grp_mbr_exists_flag  :=  grp_mbr_exists_rec.grp_mbr;
         EXIT;
      END LOOP;

      IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN

         DEBUG_LOG('Assigning Resource to the Group Number: '||p_group_number);

         ASSIGN_RES_TO_GRP
               (
                p_api_version          => 1.0
               ,p_commit               => 'T'
               ,p_group_id             => p_group_id
               ,p_group_number         => p_group_number
               ,p_resource_id          => gn_resource_id
               ,p_resource_number      => gc_resource_number
               ,x_return_status        => x_return_status
               ,x_msg_count            => x_msg_count
               ,x_msg_data             => x_msg_data
               ,x_group_member_id      => ln_group_mem_id
               );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
           DEBUG_LOG('In Procedure:ASSGN_GRP_ROLE: Proc: ASSIGN_RES_TO_GRP Fails');

           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0035_ASGNRSGRP_F');
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

           gc_return_status      := 'ERROR';

           RAISE EX_TERMINATE_GRP_ROL_ASGN;

         END IF;

      END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'


      FOR  resource_roles_rec IN get_resource_roles
      LOOP

         ASSIGN_ROLE_TO_GROUP
                  (
                   p_role_resource_id => p_group_id
                  ,p_role_id          => resource_roles_rec.role_id
                  ,p_start_date       => gd_as_of_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
            lc_error_message    := 'ASSGN_GRP_ROLE';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0034_ASGNRSGRPRL_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID', resource_roles_rec.role_id);
--           -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

         END IF;


--WRITE_LOG('* membership Role creation');

         ASSIGN_RES_TO_GROUP_ROLE
                 (p_api_version          => 1.0
                 ,p_commit               => 'T'
                 ,p_resource_id          => gn_resource_id
                 ,p_group_id             => p_group_id
                 ,p_role_id              => resource_roles_rec.role_id
                 ,p_start_date           => gd_as_of_date
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            lc_error_message    := 'ASSGN_GRP_ROLE';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0020_CREAGRPMEM_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID',resource_roles_rec.role_id);

            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

         END IF;

      END LOOP;    -- End loop, get_resource_roles

      x_return_status := FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);
   EXCEPTION

    WHEN EX_TERMINATE_GRP_ROL_ASGN THEN

      gc_return_status  := 'ERROR';

     --In Fnd Message: P_MGR_ASGN_TERMINATED
      lc_error_message := 'In Procedure:ASSGN_GRP_ROLE: Program Terminated.';
      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0033_GRPRLASGN_TERMIN');
      FND_MESSAGE.SET_TOKEN('P_GRPRLASGN_TERMINATED', lc_error_message );
      lc_error_message    := NULL;
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      x_return_status     := FND_API.G_RET_STS_ERROR;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);
    WHEN OTHERS THEN

      gc_return_status  := 'ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:ASSGN_GRP_ROLE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'ASSGN_GRP_ROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END ASSGN_GRP_ROLE;

   -- +===================================================================+
   -- | Name  : PROCESS_GENERIC_RES_DETAILS                               |
   -- |                                                                   |
   -- | Description:       This Procedure shall end date any salesreps    |
   -- |                    that exists for the resource and shall assign  |
   -- |                    roles, group and group membership with         |
   -- |                    OD_SALES_ADMIN_GRP/OD_PAYMENT_ANALYST_GRP.     |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_GENERIC_RES_DETAILS
                                 (p_group_name     IN         VARCHAR2
                                 ,x_return_status  OUT NOCOPY VARCHAR2
                                 ,x_msg_count      OUT NOCOPY NUMBER
                                 ,x_msg_data       OUT NOCOPY VARCHAR2
                                 )
   IS

      lc_sales_rep_flag             VARCHAR2(1);
      lc_error_message              VARCHAR2(1000);

      lc_return_status              VARCHAR2(1);
      ln_msg_count                  NUMBER;
      lc_msg_data                   VARCHAR2(1000);

      CURSOR   check_salesrep
      IS
      SELECT  'Y' sales_rep_flag
      FROM     jtf_rs_salesreps
      WHERE    resource_id = gn_resource_id
      AND      gd_as_of_date
               BETWEEN  start_date_active
               AND      end_date_active;

      CURSOR  get_group_details
      IS
      SELECT  group_id
             ,group_number
      FROM    jtf_rs_groups_vl
      WHERE   group_name = p_group_name;

-- Sep 11

    CURSOR  get_mbr_roles(p_grp_id NUMBER)
      IS
      SELECT  JRGMR.role_id
      FROM    jtf_rs_group_mbr_role_vl JRGMR
      WHERE   JRGMR.group_id    = p_grp_id
      AND     JRGMR.resource_id = gn_resource_id
      AND     JRGMR.member_flag ='Y'
      AND     gd_as_of_date
      BETWEEN JRGMR.start_date_active
      AND     NVL(JRGMR.end_date_active,gd_as_of_date)
      AND     JRGMR.role_id NOT IN (SELECT  role_id
                              FROM    jtf_rs_role_relations
                              WHERE   role_resource_type = 'RS_GROUP'
                              AND     role_resource_id   = p_grp_id
                              AND     gd_as_of_date
                              BETWEEN start_date_active
                              AND     NVL(end_date_active,gd_as_of_date)
                             )
      GROUP BY role_id;


-- Sep 11


      group_details_rec             get_group_details%ROWTYPE;

      EX_TERMINATE_ASGN             EXCEPTION;

   BEGIN

--WRITE_LOG('* Start of Generic details ');
      IF check_salesrep%ISOPEN THEN
         CLOSE check_salesrep;
      END IF;

      OPEN  check_salesrep;
      FETCH check_salesrep INTO lc_sales_rep_flag;
      CLOSE check_salesrep;

--WRITE_LOG('* sales rep flag'||NVL(lc_sales_rep_flag,'N'));

      DEBUG_LOG('Sales rep exists (Y/N): '||NVL(lc_sales_rep_flag,'N'));

      IF (NVL(lc_sales_rep_flag,'N') = 'Y') THEN

        ENDDATE_SALESREP
                       (p_resource_id      => gn_resource_id
                       ,p_end_date_active  => gd_as_of_date - 1
                       ,x_return_status    => x_return_status
                       ,x_msg_count        => x_msg_count
                       ,x_msg_data         => x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            lc_error_message    := 'PROCESS_GENERIC_RES_DETAILS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0015_ENDDTSLSREP_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            gc_return_status     := 'WARNING';

         END IF;

      END IF; -- End if, NVL(lc_sales_rep_flag,'N') = 'Y'

--WRITE_LOG('* Assign role');

      ASSIGN_ROLE
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

--      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
--         --In Fnd Message: P_MESSAGE
--         lc_error_message    := 'In Procedure:PROCESS_GENERIC_RES_DETAILS: Proc: ASSIGN_ROLE Fails';
--         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0030_ASGNROLE_F');
--         FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--         -- lc_error_message    := FND_MESSAGE.GET;
--         FND_MSG_PUB.add;
--
--         RAISE EX_TERMINATE_ASGN;

--      END IF;

--WRITE_LOG('* Group name: '||p_group_name);

      IF  get_group_details%ISOPEN THEN
         CLOSE get_group_details;
      END IF;

      OPEN  get_group_details;
      FETCH get_group_details INTO group_details_rec;
      CLOSE get_group_details;

      ASSGN_GRP_ROLE
               ( p_group_id         => group_details_rec.group_id
               , p_group_number     => group_details_rec.group_number
               , x_return_status    => x_return_status
               , x_msg_count        => x_msg_count
               , x_msg_data         => x_msg_data
               );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            --In Fnd Message: P_MESSAGE
            lc_error_message    := 'PROCESS_GENERIC_RES_DETAILS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0023_ASGNGRPROLE_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
               gc_return_status  := 'WARNING';
            END IF;

            RAISE EX_TERMINATE_ASGN;

         END IF;

-- Sep 11

      FOR  mbr_role_rec IN get_mbr_roles(group_details_rec.group_id)
      LOOP

         ASSIGN_ROLE_TO_GROUP
                  (p_role_resource_id => group_details_rec.group_id
                  ,p_role_id          => mbr_role_rec.role_id
                  ,p_start_date       => gd_as_of_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE

            lc_error_message    := 'PROCESS_GENERIC_RES_DETAILS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0034_ASGNRSGRPRL_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID', mbr_role_rec.role_id);

--           -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
               gc_return_status  := 'WARNING';
            END IF;

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_GENERIC_RES_DETAILS: Proc: ASSIGN_ROLE_TO_GROUP Success, for Group-role, for role id: '||mbr_role_rec.role_id);

         END IF;

      END LOOP;
-- Sep 11
      x_return_status   :=    FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);
   EXCEPTION

    WHEN EX_TERMINATE_ASGN THEN

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0040_TERMINATE_PRG');
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);
    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_GENERIC_RES_DETAILS: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_GENERIC_RES_DETAILS'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_GENERIC_RES_DETAILS;


   -- +===================================================================+
   -- | Name  : PROCESS_SALES_ADMIN                                       |
   -- |                                                                   |
   -- | Description:       This Procedure shall invoke the procedure      |
   -- |                    PROCESS_GENERIC_RES_DETAILS to assign roles and|
   -- |                    group and group membership with                |
   -- |                    OD_SALES_ADMIN_GRP.                            |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_SALES_ADMIN(x_return_status   OUT NOCOPY VARCHAR2
                                ,x_msg_count       OUT NOCOPY NUMBER
                                ,x_msg_data        OUT NOCOPY VARCHAR2 )
   IS
      lc_error_message           VARCHAR2(1000);
   BEGIN

--WRITE_LOG('* Call generic details');

      PROCESS_GENERIC_RES_DETAILS
                     (p_group_name      => G_OD_SALES_ADMIN_GRP
                     ,x_return_status   => x_return_status
                     ,x_msg_count       => x_msg_count
                     ,x_msg_data        => x_msg_data
                     );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

           --In Fnd Message: P_MESSAGE
           lc_error_message    := 'PROCESS_SALES_ADMIN';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0032_PRCGENRSDTL_F');
           FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

--           RAISE EX_TERMINATE_PRGM;

      END IF;
   EXCEPTION

     WHEN OTHERS THEN

       x_return_status      := FND_API.G_RET_STS_ERROR;
       gc_return_status     := 'ERROR';

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_error_message     :=  'In Procedure:PROCESS_SALES_ADMIN: Unexpected Error: ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       --lc_error_message     := FND_MESSAGE.GET;
       FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_SALES_ADMIN'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_SALES_ADMIN;


   -- +===================================================================+
   -- | Name  : PROCESS_SALES_COMP_ANALYST                                |
   -- |                                                                   |
   -- | Description:       This Procedure shall invoke the procedure      |
   -- |                    PROCESS_GENERIC_RES_DETAILS to assign roles and|
   -- |                    group and group membership with                |
   -- |                    OD_PAYMENT_ANALYST_GRP.                        |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_SALES_COMP_ANALYST
                                (x_return_status   OUT NOCOPY VARCHAR2
                                ,x_msg_count       OUT NOCOPY NUMBER
                                ,x_msg_data        OUT NOCOPY VARCHAR2 )
   IS
      lc_error_message           VARCHAR2(1000);
   BEGIN

      PROCESS_GENERIC_RES_DETAILS
                     (p_group_name      => G_OD_PAYMENT_ANALYST_GRP
                     ,x_return_status   => x_return_status
                     ,x_msg_count       => x_msg_count
                     ,x_msg_data        => x_msg_data
                     );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

           --In Fnd Message: P_MESSAGE
           lc_error_message    := 'PROCESS_SALES_COMP_ANALYST';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0032_PRCGENRSDTL_F');
           FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

      END IF;

   EXCEPTION

     WHEN OTHERS THEN

       x_return_status      := FND_API.G_RET_STS_ERROR;
       gc_return_status     :='ERROR';

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_error_message     :=  'In Procedure:PROCESS_SALES_COMP_ANALYST: Unexpected Error: ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       -- lc_error_message     := FND_MESSAGE.GET;
       FND_MSG_PUB.add;

       FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_SALES_COMP_ANALYST'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_SALES_COMP_ANALYST;


   -- +===================================================================+
   -- | Name  : PROCESS_NONMANAGER_ASSIGNMENTS                            |
   -- |                                                                   |
   -- | Description:       This Procedure shall enddate any previous group|
   -- |                    memberships. Shall assign the resource to the  |
   -- |                    manager group, shall create group memberships  |
   -- |                    in manager's group and Sales Support group     |
   -- |                    (optional)                                     |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE  PROCESS_NONMANAGER_ASSIGNMENTS
                       (x_return_status  OUT NOCOPY VARCHAR2
                       ,x_msg_count      OUT NOCOPY NUMBER
                       ,x_msg_data       OUT NOCOPY VARCHAR2
                       )
   IS

      ln_source_mgr_id           PER_ALL_ASSIGNMENTS_F.supervisor_id%   TYPE;
      ln_crm_mgr_id              JTF_RS_RESOURCE_EXTNS_VL.source_id%   TYPE;
      lc_mgr_matches_flag        VARCHAR2(1);
      lc_error_message           VARCHAR2(1000);
      ln_group_id                NUMBER;
      lc_group_number            VARCHAR2(100);
      ln_group_mem_id            JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_spt_grp_id              NUMBER;
      lc_spt_grp_number          VARCHAR2(100);
      lc_grp_mbr_exists_flag     VARCHAR2(1);
      lc_spt_role_flag           VARCHAR2(1);
      lc_return_status           VARCHAR2(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(1000);


      EX_TERMINATE_MGR_ASGN      EXCEPTION;


      CURSOR  get_source_mgr_id
      IS
      SELECT  supervisor_id
      FROM    per_all_assignments_f
      WHERE   primary_flag = 'Y'
      AND     person_id    = gn_person_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      CURSOR  get_mgr_id
      IS
      SELECT  JRRE.source_id
      FROM    jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_resource_extns_vl JRRE
      WHERE   JRGMR.manager_flag = 'Y'
      AND     gd_as_of_date
              BETWEEN  JRGMR.start_date_active
              AND      NVL(JRGMR.end_date_active,gd_as_of_date)
      AND     JRGMR.group_id IN (
                                 SELECT group_id
                                 FROM   jtf_rs_group_mbr_role_vl JRGM
                                 WHERE  JRGM.resource_id = gn_resource_id
                                 AND    gd_as_of_date - 1
                                        BETWEEN  JRGM.start_date_active
                                            AND  NVL(JRGM.end_date_active,gd_as_of_date - 1)
                                 AND    group_id NOT IN
                                        (SELECT  group_id
                                         FROM    jtf_rs_groups_vl
                                         WHERE   group_name IN
                                                 ('OD_SALES_ADMIN_GRP'
                                                 ,'OD_PAYMENT_ANALYST_GRP'
                                                 ,'OD_SUPPORT_GRP'
                                                 )
                                        )
                             )
      AND     JRGMR.resource_id = JRRE.resource_id;

      CURSOR  get_mgr_grp
      IS
      SELECT  JRGM.group_id
             ,JRGV.group_number
      FROM    per_all_assignments_f PAAF
             ,jtf_rs_resource_extns_vl JRRE
             ,jtf_rs_group_members_vl  JRGM
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_groups_vl         JRGV
      WHERE   PAAF.person_id              = gn_person_id
      AND     PAAF.business_group_id      = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN PAAF.effective_start_date
              AND     NVL(PAAF.effective_end_date,gd_as_of_date)
      AND     JRRE.source_id              = PAAF.supervisor_id
      AND     JRGM.resource_id            = JRRE.resource_id
      AND     JRGM.resource_id            = JRGMR.resource_id
      AND     JRGV.group_id               = JRGM.group_id
      AND     JRGM.delete_flag            ='N'
      AND     NVL(JRGMR.manager_flag,'N') ='Y'
      AND     gd_as_of_date
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN JRGMR.start_date_active
              AND     NVL(JRGMR.end_date_active,gd_as_of_date);

      CURSOR  check_support_role
      IS
      SELECT 'Y' SUPPORT_EXISTS
      FROM    DUAL
      WHERE   EXISTS
             (SELECT  1
              FROM    jtf_rs_role_relations_vl JRRR
                     ,jtf_rs_roles_vl  JRRV
              WHERE   JRRR.role_resource_id = gn_resource_id
              AND     JRRR.role_id     = JRRV.role_id
              AND     JRRV.attribute14 = 'SALES_SUPPORT'
              AND     gd_as_of_date
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,gd_as_of_date)
             );

      CURSOR  check_grp_mbr_exists(p_group_id NUMBER)
      IS
      SELECT 'Y' grp_mbr
      FROM    JTF_RS_GROUP_MEMBERS_VL
      WHERE   resource_id = gn_resource_id
      AND     group_id    = p_group_id
      AND     delete_flag = 'N';

      CURSOR  get_suprt_grp_details
      IS
      SELECT  group_id
             ,group_number
      FROM    jtf_rs_groups_vl
      WHERE   group_name = G_OD_SUPPORT_GRP
      AND     gd_as_of_date
              BETWEEN start_date_active
              AND     NVL(END_DATE_ACTIVE,gd_as_of_date);

      CURSOR  get_sales_roles(p_grp_id    NUMBER)
      IS
      SELECT  JRRR.role_id
      FROM    jtf_rs_role_relations_vl  JRRR
             ,jtf_rs_roles_vl JRRV
      WHERE   JRRR.role_resource_id = gn_resource_id
      AND     JRRV.role_id = JRRR.role_id
      AND     JRRV.role_type_code = 'SALES'
      AND     gd_as_of_date
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,gd_as_of_date)
      AND     JRRR.role_id NOT IN ( SELECT  role_id
                                    FROM    jtf_rs_group_mbr_role_vl
                                    WHERE   resource_id = gn_resource_id
                                    AND     group_id    = p_grp_id
                                    AND     gd_as_of_date
                                            BETWEEN start_date_active
                                            AND     NVL(end_date_active,gd_as_of_date)
                                  );

      CURSOR  get_sales_comp_roles(p_grp_id    NUMBER)
      IS
      SELECT  JRRR.role_id
      FROM    jtf_rs_role_relations_vl  JRRR
             ,jtf_rs_roles_vl JRRV
      WHERE   JRRR.role_resource_id = gn_resource_id
      AND     JRRV.role_id = JRRR.role_id
      AND     JRRV.role_type_code = 'SALES_COMP'
      AND     gd_as_of_date
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,gd_as_of_date)
      AND     JRRR.role_id NOT IN ( SELECT  role_id
                                    FROM    jtf_rs_group_mbr_role_vl
                                    WHERE   resource_id = gn_resource_id
                                    AND     group_id    = p_grp_id
                                    AND     gd_as_of_date
                                            BETWEEN start_date_active
                                            AND     NVL(end_date_active,gd_as_of_date)
                                  );


      CURSOR  get_mbr_roles(p_grp_id NUMBER)
      IS
      SELECT  role_id
      FROM    jtf_rs_group_mbr_role_vl
      WHERE   group_id    = p_grp_id
      AND     resource_id = gn_resource_id
      AND     member_flag ='Y'
      AND     gd_as_of_date
      BETWEEN start_date_active
      AND     NVL(end_date_active,gd_as_of_date)
      AND     role_id NOT IN (SELECT  role_id
                              FROM    jtf_rs_role_relations
                              WHERE   role_resource_type = 'RS_GROUP'
                              AND     role_resource_id   = p_grp_id
                              AND     gd_as_of_date
                              BETWEEN start_date_active
                              AND     NVL(end_date_active,gd_as_of_date)
                             )
      GROUP BY role_id;

-- Sep 11

      CURSOR  get_mbr_sc_roles(p_grp_id NUMBER)
      IS
      SELECT  JRGMR.role_id
      FROM    jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_roles_vl  JRRV
      WHERE   JRGMR.group_id    = p_grp_id
      AND     JRRV.role_id      = JRGMR.role_id
      AND     JRRV.role_type_code = 'SALES_COMP'
      AND     JRGMR.resource_id = gn_resource_id
      AND     JRGMR.member_flag ='Y'
      AND     gd_as_of_date
      BETWEEN JRGMR.start_date_active
      AND     NVL(JRGMR.end_date_active,gd_as_of_date)
      AND     JRGMR.role_id NOT IN (SELECT  role_id
                                    FROM    jtf_rs_role_relations
                                    WHERE   role_resource_type = 'RS_GROUP'
                                    AND     role_resource_id   = p_grp_id
                                    AND     gd_as_of_date
                                    BETWEEN start_date_active
                                    AND     NVL(end_date_active,gd_as_of_date)
                                   )
      GROUP BY JRGMR.role_id;


-- Sep 11

--      CURSOR  debug_get_group_roles(p_grp_id number)
--      IS
--      SELECT  role_id
--      FROM    jtf_rs_role_relations
--      WHERE   role_resource_type = 'RS_GROUP'
--      AND     role_resource_id   = p_grp_id
--      AND     gd_as_of_date
--      BETWEEN start_date_active
--      AND     NVL(end_date_active,gd_as_of_date);
--
--      CURSOR  debug_get_mbr_roles(p_grp_id NUMBER)
--      IS
--      SELECT  role_id
--      FROM    jtf_rs_group_mbr_role_vl
--      WHERE   group_id = p_grp_id
--      AND     member_flag = 'Y'
--      AND     gd_as_of_date
--      BETWEEN start_date_active
--      AND     NVL(end_date_active,gd_as_of_date);


      mgr_grp_rec                   get_mgr_grp%ROWTYPE;
      suprt_grp_rec                 get_suprt_grp_details%ROWTYPE;

   BEGIN

--WRITE_LOG('* Start Non Mgr process');
--WRITE_LOG('* Resource id '|| gn_resource_id||' gd_as_of_date '||gd_as_of_date);

      IF get_source_mgr_id%ISOPEN THEN
         CLOSE get_source_mgr_id;
      END IF;

      OPEN  get_source_mgr_id;
      FETCH get_source_mgr_id INTO ln_source_mgr_id;
      CLOSE get_source_mgr_id;

--WRITE_LOG('* Source mgr id '|| ln_source_mgr_id);

      DEBUG_LOG('Source Manager ID: '||ln_source_mgr_id);

      IF get_mgr_id%ISOPEN THEN
         CLOSE get_mgr_id;
      END IF;

      OPEN  get_mgr_id;
      FETCH get_mgr_id INTO ln_crm_mgr_id;
      CLOSE get_mgr_id;

--WRITE_LOG('* crm mgr id '||ln_crm_mgr_id);

      DEBUG_LOG('CRM Manager ID: '||ln_crm_mgr_id);

      IF NVL(ln_crm_mgr_id,ln_source_mgr_id) <> ln_source_mgr_id THEN

         lc_mgr_matches_flag := 'N';

      END IF;


      IF NVL(lc_mgr_matches_flag,'Y') = 'N' THEN

         ln_group_id := -1;   -- Prem, Check if u have to pass group_id or not..

--WRITE_LOG('* End grp and res role');

         DEBUG_LOG('Manager Changes Exists.');

         END_GRP_AND_RESGRPROLE  --END_GRP_ROLE
                     (p_group_id        => ln_group_id,
                      p_end_date        => gd_as_of_date -1,
                      x_return_status   => x_return_status,
                      x_msg_count       => x_msg_count,
                      x_msg_data        => x_msg_data
                     );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
           lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0016_ENDGRPRSGRPROLE_F');
           FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

         ELSE
           DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Success');
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0024_ENDGRPRSGRPROLE_S');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         END IF;

      END IF;   -- END IF, NVL(lc_mgr_matches_flag,'N') = 'Y'

      IF get_mgr_grp%ISOPEN THEN
         CLOSE get_mgr_grp;
      END IF;

      OPEN  get_mgr_grp;
      FETCH get_mgr_grp INTO mgr_grp_rec;
      CLOSE get_mgr_grp;

      ln_group_id      :=  mgr_grp_rec.group_id;
      lc_group_number  :=  mgr_grp_rec.group_number;
--WRITE_LOG('* mgr group id '||ln_group_id);


      IF ln_group_id IS NULL OR lc_group_number IS NULL THEN

          FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0049_NO_MANAGER_GRP');
          FND_MESSAGE.SET_TOKEN('P_DATE',gd_as_of_date);
          FND_MSG_PUB.add;

          RAISE EX_TERMINATE_MGR_ASGN;

      END IF;  -- END IF, ln_group_id IS NULL OR ln_group_number IS NULL


      IF check_support_role%ISOPEN THEN
        CLOSE check_support_role;
      END IF;

      OPEN  check_support_role;
      FETCH check_support_role INTO lc_spt_role_flag;
      CLOSE check_support_role;

--WRITE_LOG('* support role flag '||lc_spt_role_flag);

      IF check_grp_mbr_exists%ISOPEN THEN

         CLOSE check_grp_mbr_exists;
      END IF;

      OPEN  check_grp_mbr_exists(ln_group_id);
      FETCH check_grp_mbr_exists INTO lc_grp_mbr_exists_flag;
      CLOSE check_grp_mbr_exists;

--WRITE_LOG('* Mgr group assinged? '||lc_grp_mbr_exists_flag);

      IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN

        DEBUG_LOG('Assign Resource to Group Number: '||lc_group_number);

        ASSIGN_RES_TO_GRP
            (
             p_api_version          => 1.0
            ,p_commit               => 'T'
            ,p_group_id             => ln_group_id
            ,p_group_number         => lc_group_number
            ,p_resource_id          => gn_resource_id
            ,p_resource_number      => gc_resource_number
            ,x_return_status        => x_return_status
            ,x_msg_count            => x_msg_count
            ,x_msg_data             => x_msg_data
            ,x_group_member_id      => ln_group_mem_id
            );
--WRITE_LOG('* After group assignment');
         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            --In Fnd Message: P_MESSAGE
            lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0019_ASGNRSGRP_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            RAISE EX_TERMINATE_MGR_ASGN;

         ELSE
           --In Fnd Message: P_MESSAGE
           DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Success');
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0030_ASGNRSGRP_S');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         END IF;


      END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'

      --- Sales support group assignment

      IF  ( NVL (lc_spt_role_flag,'N')  = 'Y' ) THEN

         IF get_suprt_grp_details%ISOPEN THEN
            CLOSE get_suprt_grp_details;
         END IF;

         OPEN  get_suprt_grp_details;
         FETCH get_suprt_grp_details INTO suprt_grp_rec;
         CLOSE get_suprt_grp_details;

         ln_spt_grp_id        := suprt_grp_rec.group_id;
         lc_spt_grp_number    := suprt_grp_rec.group_number;

         lc_grp_mbr_exists_flag   := NULL;

         IF check_grp_mbr_exists%ISOPEN THEN
            CLOSE check_grp_mbr_exists;
         END IF;

         OPEN  check_grp_mbr_exists(ln_spt_grp_id);
         FETCH check_grp_mbr_exists INTO lc_grp_mbr_exists_flag;
         CLOSE check_grp_mbr_exists;

         IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN

            ASSIGN_RES_TO_GRP
               (
                p_api_version          => 1.0
               ,p_commit               => 'T'
               ,p_group_id             => ln_spt_grp_id
               ,p_group_number         => lc_spt_grp_number
               ,p_resource_id          => gn_resource_id
               ,p_resource_number      => gc_resource_number
               ,x_return_status        => x_return_status
               ,x_msg_count            => x_msg_count
               ,x_msg_data             => x_msg_data
               ,x_group_member_id      => ln_group_mem_id
               );
--WRITE_LOG('* After sales support grp assignment');

             IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               --In Fnd Message: P_MESSAGE
               lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0019_ASGNRSGRP_F');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

               RAISE EX_TERMINATE_MGR_ASGN;

             ELSE
              --In Fnd Message: P_MESSAGE
              DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Success while validating lc_spt_role_flag = Y');
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0030_ASGNRSGRP_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;

         END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'

     END IF;  -- END IF, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

     --- Sales support group assignment

     FOR  resource_roles_rec IN get_sales_roles(ln_group_id)
     LOOP

         ASSIGN_RES_TO_GROUP_ROLE --CREATE_GROUP_MEMBERSHIP
              (p_api_version          => 1.0
              ,p_commit               => 'T'
              ,p_resource_id          => gn_resource_id
              ,p_group_id             => ln_group_id
              ,p_role_id              => resource_roles_rec.role_id
              ,p_start_date           => gd_as_of_date
              ,x_return_status        => lc_return_status
              ,x_msg_count            => ln_msg_count
              ,x_msg_data             => lc_msg_data
              );
--WRITE_LOG('*After Mgr group membership- Sales kind');
         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0020_CREAGRPMEM_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID',resource_roles_rec.role_id);
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status <> 'ERROR' THEN

               gc_return_status := 'WARNING';

            END IF;

         ELSE
           --In Fnd Message: P_MESSAGE
            DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to MGR group for role id: '||resource_roles_rec.role_id);
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0032_CREAGRPMEM_S');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         END IF;

     END LOOP;    -- End loop, get_sales_roles

     IF  ( NVL (lc_spt_role_flag,'N')  = 'Y' ) THEN

        FOR  resource_roles_rec IN get_sales_comp_roles(ln_spt_grp_id)
        LOOP

            ASSIGN_RES_TO_GROUP_ROLE --CREATE_GROUP_MEMBERSHIP
                 (p_api_version          => 1.0
                 ,p_commit               => 'T'
                 ,p_resource_id          => gn_resource_id
                 ,p_group_id             => ln_spt_grp_id
                 ,p_role_id              => resource_roles_rec.role_id
                 ,p_start_date           => gd_as_of_date
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 );

--WRITE_LOG('* After Support grp membership - Sales Comp Kind');
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0020_CREAGRPMEM_F');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
               FND_MESSAGE.SET_TOKEN('P_ROLE_ID',resource_roles_rec.role_id);
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

               IF gc_return_status <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

               --RAISE EX_TERMINATE_MGR_ASGN;

            ELSE
              --In Fnd Message: P_MESSAGE
              DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to Sales Support group assignment for Role id: '||resource_roles_rec.role_id);

--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0032_CREAGRPMEM_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;

        END LOOP;    -- End loop, get_sales_roles

     ELSE   -- ELSE, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

        FOR  sales_comp_roles_rec IN get_sales_comp_roles(ln_group_id)
        LOOP

            ASSIGN_RES_TO_GROUP_ROLE --CREATE_GROUP_MEMBERSHIP
                 (p_api_version          => 1.0
                 ,p_commit               => 'T'
                 ,p_resource_id          => gn_resource_id
                 ,p_group_id             => ln_group_id
                 ,p_role_id              => sales_comp_roles_rec.role_id
                 ,p_start_date           => gd_as_of_date
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 );
--WRITE_LOG('* After Mgr grp membership - sales comp kind');
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0020_CREAGRPMEM_F');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
               FND_MESSAGE.SET_TOKEN('P_ROLE_ID',sales_comp_roles_rec.role_id);

               FND_MSG_PUB.add;

               IF gc_return_status <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

               --RAISE EX_TERMINATE_MGR_ASGN;

            ELSE
              --In Fnd Message: P_MESSAGE
              DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to MGR group for role id: '||sales_comp_roles_rec.role_id);
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0032_CREAGRPMEM_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;

         END LOOP;    -- End loop, get_sales_roles

      END IF;   -- END IF, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

      FOR  mbr_role_rec IN get_mbr_roles(ln_group_id)
      LOOP

         ASSIGN_ROLE_TO_GROUP
                  (p_role_resource_id => ln_group_id
                  ,p_role_id          => mbr_role_rec.role_id
                  ,p_start_date       => gd_as_of_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
            lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0034_ASGNRSGRPRL_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID', mbr_role_rec.role_id);

           -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Success, for Group-role, for role id: '||mbr_role_rec.role_id);

         END IF;

      END LOOP;

-- Sep 11
      FOR  mbr_role_sc_rec IN get_mbr_sc_roles(ln_spt_grp_id)
      LOOP

         ASSIGN_ROLE_TO_GROUP
                  (p_role_resource_id => ln_spt_grp_id
                  ,p_role_id          => mbr_role_sc_rec.role_id
                  ,p_start_date       => gd_as_of_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
            lc_error_message    := 'PROCESS_NONMANAGER_ASSIGNMENTS';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0034_ASGNRSGRPRL_F');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            FND_MESSAGE.SET_TOKEN('P_ROLE_ID', mbr_role_sc_rec.role_id);
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            IF gc_return_status  <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Support Grp Success, for Group-role, for role id: '||mbr_role_sc_rec.role_id);

         END IF;


      END LOOP;

-- Sep 11

--   for debug_grp_rec IN debug_get_group_roles(ln_group_id)
--   LOOP
--
--   WRITE_LOG('* GROUP ROLES: '||debug_grp_rec.role_id);
--   END LOOP;
--
--   for debug_mbr_rec IN debug_get_mbr_roles(ln_group_id)
--   LOOP
--
--   WRITE_LOG('* MBR ROLES: '||debug_mbr_rec.role_id);
--   END LOOP;
--
      x_return_status := FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION

      WHEN EX_TERMINATE_MGR_ASGN THEN

     --In Fnd Message: P_MGR_ASGN_TERMINATED
      --lc_error_message := 'Manager Group does not exists for the resource.';
      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0045_MGR_ASGN_TERMINATE');
      --FND_MESSAGE.SET_TOKEN('P_MGR_ASGN_TERMINATED', lc_error_message );
      --lc_error_message    := NULL;
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_NONMANAGER_ASSIGNMENTS'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );


   END PROCESS_NONMANAGER_ASSIGNMENTS;

   -- +===================================================================+
   -- | Name  : PROCESS_MANAGER_ASSIGNMENTS                               |
   -- |                                                                   |
   -- | Description:       This Procedure shall create the group, group   |
   -- |                    usages,     . Shall invoke                     |
   -- |                    PROCESS_MANAGER_ASSIGNMENTS for Manager Sales- |
   -- |                    reps and PROCESS_NONMANAGER_ASSIGNMENTS for    |
   -- |                    Non Manager Salesreps.                         |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE  PROCESS_MANAGER_ASSIGNMENTS
                       (x_return_status  OUT NOCOPY VARCHAR2
                       ,x_msg_count      OUT NOCOPY NUMBER
                       ,x_msg_data       OUT NOCOPY VARCHAR2
                       )
   IS

      lc_grp_exist_flag           VARCHAR2(1);
      ln_group_id                 jtf_rs_groups_vl.group_id%TYPE;
      lc_group_number             jtf_rs_groups_vl.group_number%TYPE;
      lc_error_message            VARCHAR2(1000);
      lc_vp_flag                  VARCHAR2(1);
      ln_mgr_grp_id               jtf_rs_groups_vl.group_id%TYPE;
      lc_mgr_group_number         jtf_rs_groups_vl.group_number%TYPE;
      lc_reln_exist_flag          VARCHAR2(1);
      ln_group_relate_id          JTF_RS_GRP_RELATIONS.group_relate_id%TYPE;
      lc_return_status            VARCHAR2(1);
      ln_msg_count                NUMBER;
      lc_msg_data                 VARCHAR2(1000);



      EX_TERMINATE_MGR_ASGN       EXCEPTION;


      CURSOR  check_group_exists(p_emp_number VARCHAR2)
      IS
      SELECT 'Y' group_exists
             ,group_id
             ,group_number
      FROM    jtf_rs_groups_vl
      WHERE   group_name = 'OD_GRP_'||p_emp_number
      AND     gd_as_of_date
             BETWEEN  start_date_active
             AND      NVL(end_date_active,gd_as_of_date);

      CURSOR  check_is_vp
      IS
      SELECT 'Y' VP_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_role_relations_vl JRLV
             ,jtf_rs_roles_b           JRRB
             ,jtf_rs_roles_b_dfv       JRRBD
      WHERE   JRLV.manager_flag     ='Y'
      AND    (JRLV.role_type_code   ='SALES'
       OR     JRLV.role_type_code   ='SALES_COMP')
      AND     JRLV.role_id          = JRRB.role_id
      AND     JRRBD.row_id          = JRRB.rowid
      AND     JRRBD.od_role_code    ='VP'
      AND     JRLV.role_resource_id = gn_resource_id
      AND     NVL(JRRB.active_flag,'N') = 'Y');

      CURSOR  get_mgr_grp
      IS
      SELECT  JRGM.group_id
             ,JRGV.group_number
      FROM    per_all_assignments_f PAAF
             ,jtf_rs_resource_extns_vl JRRE
             ,jtf_rs_group_members_vl  JRGM
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_groups_vl         JRGV
      WHERE   PAAF.person_id              = gn_person_id
      AND     PAAF.business_group_id      = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN PAAF.effective_start_date
              AND     NVL(PAAF.effective_end_date,gd_as_of_date)
      AND     JRRE.source_id              = PAAF.supervisor_id
      AND     JRGM.resource_id            = JRRE.resource_id
      AND     JRGM.resource_id            = JRGMR.resource_id
      AND     JRGV.group_id               = JRGM.group_id
      AND     JRGM.delete_flag            ='N'
      AND     NVL(JRGMR.manager_flag,'N') ='Y'
      AND     gd_as_of_date
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN JRGMR.start_date_active
              AND     NVL(JRGMR.end_date_active,gd_as_of_date);

      CURSOR  check_relation(p_group_id    NUMBER
                            ,p_mgr_grp_id  NUMBER
                            )
      IS
      SELECT  'Y' RELN_EXISTS
      FROM    jtf_rs_grp_relations
      WHERE   group_id         = p_group_id
      AND     related_group_id = p_mgr_grp_id
      AND     relation_type = 'PARENT_GROUP'
      AND     delete_flag   = 'N'
      AND     gd_as_of_date
              BETWEEN start_date_active
              AND     NVL(end_date_active,gd_as_of_date);

      CURSOR  get_old_relation(p_group_id       NUMBER
                              ,p_prnt_group_id  NUMBER
                              )
      IS
      SELECT  related_group_id
             ,group_relate_id
             ,object_version_number
      FROM    jtf_rs_grp_relations_vl
      WHERE   group_id = p_group_id
      AND     related_group_id <> p_prnt_group_id
      AND     delete_flag   = 'N'
      AND     relation_type = 'PARENT_GROUP'
      AND     gd_as_of_date -1                                -- Prem, should -1 be removed
              BETWEEN start_date_active
              AND     NVL(end_date_active,gd_as_of_date - 1);

   BEGIN
--WRITE_LOG('* Manager Processing');
      FOR  check_group_exists_rec IN check_group_exists(gc_employee_number)
      LOOP

        lc_grp_exist_flag := check_group_exists_rec.group_exists;
        ln_group_id       := check_group_exists_rec.group_id;
        lc_group_number   := check_group_exists_rec.group_number;

        EXIT;

      END LOOP;

--WRITE_LOG('* Group exists '||lc_grp_exist_flag);

      IF ( NVL(lc_grp_exist_flag, 'N') <> 'Y' ) THEN

         CREATE_GROUP
            (p_api_version         => 1.0
            ,p_commit              => 'T'
            ,p_group_name          => 'OD_GRP_'||gc_employee_number
            ,p_group_desc          => 'OD_GRP_'||gc_employee_number
            ,p_exclusive_flag      => 'N'
            ,p_email_address       => NULL
            ,p_start_date_active   => gd_as_of_date
            ,p_end_date_active     => NULL
            ,p_accounting_code     => NULL
            ,x_return_status       => x_return_status
            ,x_msg_count           => x_msg_count
            ,x_msg_data            => x_msg_data
            ,x_group_id            => ln_group_id
            ,x_group_number        => lc_group_number
            );

--WRITE_LOG('* Group id '||ln_group_id);

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0021_CREAGRP_F');
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

           gc_return_status  := 'ERROR';

           RAISE EX_TERMINATE_MGR_ASGN;

         ELSE
           --In Fnd Message: P_MESSAGE
           DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP Success, GROUP NUMBER: '||lc_group_number);
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0034_CREAGRP_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

         END IF;

      END IF;  -- END IF; ( NVL(lc_grp_exist_flag, 'N') <> 'Y' )

      -- ----------------------------------------------------------------------
      -- Assign the Resource Role to this Group by calling the standard CRM API
      -- ----------------------------------------------------------------------

      CREATE_GROUP_USAGE
                  ( p_group_id           => ln_group_id
                  , p_group_number       => lc_group_number
                  , x_return_status      => x_return_status
                  , x_msg_count          => x_msg_count
                  , x_msg_data           => x_msg_data
                  );

--WRITE_LOG('* After grp usage');
      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0022_CREAGRPUSG_F');
        FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
        -- lc_error_message    := FND_MESSAGE.GET;
        FND_MSG_PUB.add;

        IF gc_return_status <> 'ERROR' THEN

           gc_return_status := 'WARNING';

        END IF;

      ELSE
        --In Fnd Message: P_MESSAGE
        DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_USAGE Success');
--        FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0036_CREAGRPUSG_S');
--        FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--        -- lc_error_message    := FND_MESSAGE.GET;
--        FND_MSG_PUB.add;

      END IF;

      ASSGN_GRP_ROLE
                  ( p_group_id         => ln_group_id
                  , p_group_number     => lc_group_number
                  , x_return_status    => x_return_status
                  , x_msg_count        => x_msg_count
                  , x_msg_data         => x_msg_data
                  );
--WRITE_LOG('* After grp membership');
       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         --In Fnd Message: P_MESSAGE
         lc_error_message    := 'PROCESS_MANAGER_ASSIGNMENTS';
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0023_ASGNGRPROLE_F');
         FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

       ELSE
         --In Fnd Message: P_MESSAGE
         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSGN_GRP_ROLE Success');
--         FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0038_ASGNGRPROLE_S');
--         FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--         -- lc_error_message    := FND_MESSAGE.GET;
--         FND_MSG_PUB.add;

       END IF;

         -----------------------------------------------
         -- Unassign previous assignments to group roles
         -----------------------------------------------

           --write_log('*before end group role');

         END_GRP_AND_RESGRPROLE
                     ( p_group_id         => ln_group_id
                     , p_end_date         => gd_as_of_date -1
                     , x_return_status    => x_return_status
                     , x_msg_count        => x_msg_count
                     , x_msg_data         => x_msg_data
                     );

--WRITE_LOG('* after End date old grp membership');

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           --In Fnd Message: P_MESSAGE
           lc_error_message    := 'PROCESS_MANAGER_ASSIGNMENTS';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0016_ENDGRPRSGRPROLE_F');
           FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

         ELSE
           --In Fnd Message: P_MESSAGE
           DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Success');
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0024_ENDGRPRSGRPROLE_S');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         END IF;


         FOR  mgr_grp_rec IN get_mgr_grp
         LOOP

            ln_mgr_grp_id        := mgr_grp_rec.group_id;
            lc_mgr_group_number  := mgr_grp_rec.group_number;

            EXIT;

         END LOOP;

         IF  ln_mgr_grp_id IS NULL THEN

            ln_mgr_grp_id := - 1;

--WRITE_LOG('*Mgr grp id is null');

         END IF;

         -- Prem, call the end child group relation for previous groups.
         -- Call end parent child relation for both VP and mgr record

         FOR  old_relation_rec IN get_old_relation(ln_group_id
                                                  ,ln_mgr_grp_id
                                                  )
         LOOP

--WRITE_LOG('* End relation between group '||ln_group_id||' mgr grp '||ln_mgr_grp_id);

            DEBUG_LOG('End date Old Hierarchy with related ID: '||old_relation_rec.group_relate_id);

            ENDDATE_OFF_PARENT_GROUP
                             ( p_group_relate_id      => old_relation_rec.group_relate_id
                             , p_end_date_active      => gd_as_of_date -1
                             , p_object_version_num   => old_relation_rec.object_version_number
                             , x_return_status        => lc_return_status
                             , x_msg_count            => ln_msg_count
                             , x_msg_data             => lc_msg_data
                             );
--WRITE_LOG('* After end date old parent hierarchy');
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

              --In Fnd Message: P_MESSAGE
              lc_error_message    := 'PROCESS_MANAGER_ASSIGNMENTS';
              FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0044_ENDPRNTGRP_F');
              FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
              -- lc_error_message    := FND_MESSAGE.GET;
              FND_MSG_PUB.add;

              IF gc_return_status <> 'ERROR' THEN

                 gc_return_status := 'WARNING';

              END IF;

--            ELSE
--              --In Fnd Message: P_MESSAGE
--              lc_error_message    := 'In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ENDDATE_OFF_PARENT_GROUP Success';
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0042_ASGNPRNTGRP_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;


         END LOOP;  -- END LOOP, get_old_relation

         -------------------------------------
         -- Check VP or NOT
         -------------------------------------

         IF  check_is_vp%ISOPEN THEN

            CLOSE check_is_vp;

         END IF;

         OPEN  check_is_vp;
         FETCH check_is_vp INTO lc_vp_flag;
         CLOSE check_is_vp;

--Write_log('*VP value: '||lc_vp_flag);

         DEBUG_LOG('Is Resource a VP (Y/N): '||NVL(lc_vp_flag,'N'));
         ---------------------------------------------------------------
         -- Non VP Processing
         -- For VP no processing required for assigning to Parent Group.
         ---------------------------------------------------------------
         IF ( NVL(lc_vp_flag,'N') <> 'Y' ) THEN

--WRITE_LOG('* Supervisor mgr grp id '||ln_mgr_grp_id);

            IF ln_mgr_grp_id IS NOT NULL THEN

               FOR  check_relation_rec IN check_relation(ln_group_id
                                                        ,ln_mgr_grp_id)
               LOOP

                  lc_reln_exist_flag := check_relation_rec.reln_exists;
                  EXIT;

               END LOOP;

               IF ( NVL(lc_reln_exist_flag, 'N') <> 'Y' ) THEN

                  ASSIGN_TO_PARENT_GROUP
                        (p_api_version         => 1.0
                        ,p_commit              => 'T'
                        ,p_group_id            => ln_group_id
                        ,p_group_number        => lc_group_number
                        ,p_related_group_id    => ln_mgr_grp_id
                        ,p_related_group_number=> lc_mgr_group_number
                        ,p_relation_type       => 'PARENT_GROUP'
                        ,p_start_date_active   => gd_as_of_date
                        ,p_end_date_active     => NULL
                        ,x_return_status       => x_return_status
                        ,x_msg_count           => x_msg_count
                        ,x_msg_data            => x_msg_data
                        ,x_group_relate_id     => ln_group_relate_id
                        );
--WRITE_LOG('* After parent hierarchy, relate id '||ln_group_relate_id);
                  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                     FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0024_ASGNPRNTGRP_F');
--                    -- lc_error_message    := FND_MESSAGE.GET;
                     FND_MSG_PUB.add;

                     RAISE EX_TERMINATE_MGR_ASGN;

                  ELSE
                    --In Fnd Message: P_MESSAGE
                     DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSIGN_TO_PARENT_GROUP Success');
--                    FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0040_ASGNPRNTGRP_S');
--                    FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
                    -- lc_error_message    := FND_MESSAGE.GET;
--                    FND_MSG_PUB.add;
                     gc_return_status := 'ERROR';

                  END IF;

               END IF;  -- END IF, NVL(lc_reln_exist_flag, 'N') <> 'Y'

            ELSE

               --DEBUG_LOG('Manager group does not exists for the resource.');

               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0049_NO_MANAGER_GRP');
               FND_MESSAGE.SET_TOKEN('P_DATE',gd_as_of_date);
               FND_MSG_PUB.add;

               RAISE EX_TERMINATE_MGR_ASGN;

            END IF;  -- END IF, ln_mgr_grp_id IS NOT NULL

         END IF; -- END IF, NVL(lc_vp_flag,'N') <> 'Y'

      x_return_status  := FND_API.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION

    WHEN EX_TERMINATE_MGR_ASGN THEN

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0018_TERMINATE_PRG');
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_MANAGER_ASSIGNMENTS'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_MANAGER_ASSIGNMENTS;

   -- +===================================================================+
   -- | Name  : PROCESS_SALES_REP_GRP_ASGN                                |
   -- |                                                                   |
   -- | Description:       This Procedure shall check if the resource     |
   -- |                    is a manager. Shall invoke                     |
   -- |                    PROCESS_MANAGER_ASSIGNMENTS for Manager Sales- |
   -- |                    reps and PROCESS_NONMANAGER_ASSIGNMENTS for    |
   -- |                    Non Manager Salesreps.                         |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_SALES_REP_GRP_ASGN
                       (x_return_status  OUT NOCOPY VARCHAR2
                       ,x_msg_count      OUT NOCOPY NUMBER
                       ,x_msg_data       OUT NOCOPY VARCHAR2
                       )
   IS

      lc_mgr_flag          VARCHAR2(1);
      lc_error_message     VARCHAR2(1000);


      CURSOR  check_is_mgr
      IS
      SELECT  'Y' MGR_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_role_relations_vl JRLV
             ,jtf_rs_roles_b           JRRB
      WHERE   JRLV.manager_flag     = 'Y'
      AND     (JRLV.role_type_code  = 'SALES'
       OR      JRLV.role_type_code  = 'SALES_COMP')
      AND     JRLV.role_id          =  JRRB.role_id
      AND     JRLV.role_resource_id =  gn_resource_id
      AND     NVL(JRRB.active_flag,'N') = 'Y');

   BEGIN

      IF check_is_mgr%ISOPEN THEN
         CLOSE check_is_mgr;
      END IF;

      OPEN  check_is_mgr;
      FETCH check_is_mgr INTO  lc_mgr_flag;
      CLOSE check_is_mgr;

--WRITE_LOG('* Mngr flag '||lc_mgr_flag);

      DEBUG_LOG('Is Resource a Manager (Y/N): '||NVL(lc_mgr_flag,'N'));

      IF ( NVL(lc_mgr_flag,'N') <> 'Y' )  THEN
         --------------------------------------
         -- Processing as Non Manager Sales Rep
         --------------------------------------
         -- Prem, call the salesrep assignment prog
         ---***
         Process_NonManager_Assignments
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );
      ELSE
         --------------------------------------
         -- Processing as Manager Sales Rep
         --------------------------------------

         Process_Manager_Assignments
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );


      END IF;  -- END IF, NVL(lc_mgr_flag,'N') <> 'Y'

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_SALES_REP_GRP_ASGN: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_SALES_REP_GRP_ASGN'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_SALES_REP_GRP_ASGN;

   -- +===================================================================+
   -- | Name  : PROCESS_SALES_REP                                         |
   -- |                                                                   |
   -- | Description:       This Procedure shall create salesreps and      |
   -- |                    invokes ASSIGN_ROLE to assign roles and        |
   -- |                    PROCESS_SALES_REP_GRP_ASGN for group           |
   -- |                    and group membership assignments.              |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_SALES_REP
                             (x_return_status   OUT NOCOPY VARCHAR2
                             ,x_msg_count       OUT NOCOPY NUMBER
                             ,x_msg_data        OUT NOCOPY VARCHAR2 )
   IS

      ln_sales_credit_type_id       OE_SALES_CREDIT_TYPES.sales_credit_type_id%TYPE;
      ln_salesrep_id                JTF_RS_SALESREPS.salesrep_id%TYPE;
      lc_error_message              VARCHAR2(1000);

      EX_TERMINATE_PRGM             EXCEPTION;


      CURSOR   get_sales_credit
      IS
      SELECT   sales_credit_type_id
      FROM     oe_sales_credit_types
      WHERE    name = 'Quota Sales Credit' ;

   BEGIN


      IF get_sales_credit%ISOPEN THEN
         CLOSE get_sales_credit;
      END IF;

      OPEN  get_sales_credit;
      FETCH get_sales_credit INTO ln_sales_credit_type_id;
      CLOSE get_sales_credit;

      IF ln_sales_credit_type_id IS NULL THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0041_CRDTTYP_NDFN');
         -- lc_error_message     := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         RAISE EX_TERMINATE_PRGM;

      END IF;

      DEBUG_LOG('Create Sales Rep for the Resource');

      CREATE_SALES_REP
            (p_api_version         => 1.0
            ,p_commit              =>'T'
            ,p_resource_id         => gn_resource_id
            ,p_sales_credit_type_id=> ln_sales_credit_type_id
            ,p_salesrep_number     => gc_employee_number
            ,p_start_date_active   => gd_as_of_date   --lc_effective_start_date
            ,p_email_address       => gc_email_address
            ,x_return_status       => x_return_status
            ,x_msg_count           => x_msg_count
            ,x_msg_data            => x_msg_data
            ,x_salesrep_id         => ln_salesrep_id
            );

--WRITE_LOG('* salesrep id '||ln_salesrep_id);

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN


         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0031_CREASLSRP_F');
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         gc_return_status      :=  'ERROR';

         RAISE EX_TERMINATE_PRGM;

      END IF;

      ASSIGN_ROLE
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

--      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
--      THEN

           --In Fnd Message: P_MESSAGE
--           lc_error_message    := 'In Procedure:PROCESS_SALES_REP: Proc: ASSIGN_ROLE Fails';
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0030_ASGNROLE_F');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

--           RAISE EX_TERMINATE_PRGM;

--      END IF;
--WRITE_LOG('* sales rep and group asgn');

      PROCESS_SALES_REP_GRP_ASGN
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

           --In Fnd Message: P_MESSAGE
           lc_error_message    := 'In Procedure:PROCESS_SALES_REP: Proc: PROCESS_SALES_REP_GRP_ASGN Fails';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0039_PRCSLSRPGRPASGN_F');
           FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

           RAISE EX_TERMINATE_PRGM;

      END IF;

      x_return_status := fnd_api.G_RET_STS_SUCCESS;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION

    WHEN EX_TERMINATE_PRGM THEN

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0038_TERMINATE_PRG');
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_SALES_REP: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_SALES_REP'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_SALES_REP;

   -- +===================================================================+
   -- | Name  : Process_Resource_Details                                  |
   -- |                                                                   |
   -- | Description:       This Procedure is used to create or updates    |
   -- |                    details of a resource.                         |
   -- |                    It will process a resource on the following    |
   -- |                    three options:                                 |
   -- |                    1.  Process as Sales Administrator             |
   -- |                    2.  Process as Sales Comp Analayst             |
   -- |                    3.  Process as Sales Rep                       |
   -- |                    3.a Process as Manager, if applicable          |
   -- |                       (Manager processing is extension of         |
   -- |                        Sales Rep processing.)                     |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_RESOURCE_DETAILS
                (x_return_status   OUT NOCOPY VARCHAR2
                ,x_msg_count       OUT NOCOPY NUMBER
                ,x_msg_data        OUT NOCOPY VARCHAR2
                )
   IS

      lc_role_type_code                JTF_RS_ROLES_VL.role_type_code%TYPE;
      lc_admin_flag                    JTF_RS_ROLES_VL.admin_flag%TYPE;
      lc_member_flag                   JTF_RS_ROLES_VL.member_flag%TYPE;
      lc_sales_rep_flag                VARCHAR2(1);
      lc_error_message                 VARCHAR2(1000);


      CURSOR  check_roles
      IS
      SELECT  JRRV.role_type_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
      FROM    jtf_rs_roles_vl     JRRV
             ,jtf_rs_job_roles_vl JRJRV
      WHERE   JRJRV.role_id       = JRRV.role_id
      AND     JRRV.member_flag    = 'Y'
      AND     JRRV.role_type_code = 'SALES_COMP_PAYMENT_ANALIST'
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRJRV.job_id        = gn_job_id
      UNION ALL
      SELECT  JRRV.role_type_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
      FROM    jtf_rs_roles_vl     JRRV
             ,jtf_rs_job_roles_vl JRJRV
      WHERE   JRJRV.role_id       = JRRV.role_id
      AND     JRRV.admin_flag     = 'Y'
      AND     JRRV.role_type_code = 'SALES'
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRJRV.job_id        = gn_job_id;

      CURSOR   check_salesrep
      IS
      SELECT  'Y' sales_rep_flag
      FROM     jtf_rs_salesreps
      WHERE    resource_id = gn_resource_id
      AND      gd_as_of_date
               BETWEEN  start_date_active
               AND      NVL(end_date_active,gd_as_of_date);


      l_check_roles_rec    check_roles%ROWTYPE;


   BEGIN

      IF check_roles%ISOPEN THEN

         CLOSE check_roles;

      END IF;

      OPEN  check_roles;
      FETCH check_roles INTO l_check_roles_rec;
      CLOSE check_roles;

      lc_role_type_code   :=  l_check_roles_rec.role_type_code;
      lc_admin_flag       :=  l_check_roles_rec.admin_flag;
      lc_member_flag      :=  l_check_roles_rec.member_flag;

--WRITE_LOG('*lc_role_type_code '||lc_role_type_code);
--WRITE_LOG('*lc_admin_flag '||lc_admin_flag);
--WRITE_LOG('*lc_member_flag '||lc_member_flag);

      IF check_salesrep%ISOPEN THEN
         CLOSE check_salesrep;
      END IF;

      OPEN  check_salesrep;
      FETCH check_salesrep INTO lc_sales_rep_flag;
      CLOSE check_salesrep;

--WRITE_LOG('* Sales rep flag '||lc_sales_rep_flag);

      IF  lc_role_type_code  = 'SALES'
      AND lc_admin_flag      = 'Y' THEN
      -------------------------------------
      -- 1. Process as Sales Administrator
      -------------------------------------
--WRITE_LOG('* Call Sales admin ');

         DEBUG_LOG('Resource is of type Sales Admin');

         PROCESS_SALES_ADMIN (x_return_status   => x_return_status
                             ,x_msg_count       => x_msg_count
                             ,x_msg_data        => x_msg_data
                             );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0025_PRCSLSADMN_F');
            FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

         END IF;

      ELSIF  lc_role_type_code   = 'SALES_COMP_PAYMENT_ANALIST'
      AND    lc_member_flag      = 'Y' THEN
      -------------------------------------
      -- 2. Process as Sales Comp Analayst
      -------------------------------------
--WRITE_LOG('* Sales comp analyst');
         DEBUG_LOG('Resource is of type Sales Comp Payment Analist');

         PROCESS_SALES_COMP_ANALYST (x_return_status   => x_return_status
                                    ,x_msg_count       => x_msg_count
                                    ,x_msg_data        => x_msg_data
                                    );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0026_PRCSLSCMPANLST_F');
            FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

         END IF;

      ELSE  -- else for lc_role_type_code  = 'SALES', not an admin resource
      -------------------------------------
      -- 3. Process as Sales Rep
      -------------------------------------
--WRITE_LOG('* Call sales reps processing');
         DEBUG_LOG('Resource is of type Sales Rep');

         PROCESS_SALES_REP (x_return_status   => x_return_status
                           ,x_msg_count       => x_msg_count
                           ,x_msg_data        => x_msg_data
                           );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0027_PRCSLSRP_F');
            FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

         END IF;

      END IF;  -- lc_role_type_code  = 'SALES', not an admin resource

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_RESOURCE_DETAILS: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_RESOURCE_DETAILS'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_RESOURCE_DETAILS;


   -- +===================================================================+
   -- | Name  : PROCESS_NEW_RESOURCE                                      |
   -- |                                                                   |
   -- | Description:       This Procedure shall check if roles exists for |
   -- |                    the job. This shall create new resources       |
   -- |                    in CRM calling the std API.This shall invoke   |
   -- |                    the procedure Process_Resource_Details to      |
   -- |                    assign the roles and to create salesreps.      |
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

      CURSOR   get_job
      IS
      SELECT   job_id
      FROM     per_all_assignments_f
      WHERE    person_id         = gn_person_id
      AND      business_group_id = gn_biz_grp_id
      AND      gd_as_of_date BETWEEN effective_start_date
                                 AND effective_end_date ;

      CURSOR   check_role
      IS
      SELECT  'Y' role_exists
      FROM     per_jobs PJ
              ,jtf_rs_job_roles   JRJR
              ,jtf_rs_roles_b     JRRV
      WHERE    PJ.job_id                 = JRJR.job_id
      AND      PJ.job_id                 = gn_job_id
      AND      JRJR.role_id              = JRRV.role_id
      AND      JRRV.role_type_code      IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
      AND      NVL(JRRV.active_flag,'N') = 'Y';

      CURSOR   get_fnd_user
      IS
      SELECT   user_name
      FROM     fnd_user
      WHERE    employee_id  =  gn_person_id
      AND      gd_as_of_date BETWEEN start_date
                       AND     end_date;


      EX_TERMINATE_PRGM             EXCEPTION;

   BEGIN

      IF get_job%ISOPEN THEN
         CLOSE get_job;
      END IF;

      IF check_role%ISOPEN THEN
         CLOSE check_role;
      END IF;


      OPEN  get_job;
      FETCH get_job INTO gn_job_id ;
      CLOSE get_job;

--WRITE_LOG('* Job id '||gn_job_id);

      IF gn_job_id IS NULL THEN
         --In fnd Message:  P_JOB_NULL||' Job details does not exists for the employee';
         lc_error_message := 'PROCESS_NEW_RESOURCE';
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0008_JOB_NULL');
         FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         RAISE EX_TERMINATE_PRGM;

      END IF;

      OPEN  check_role;
      FETCH check_role INTO lc_role_exists;
      CLOSE check_role;

--WRITE_LOG('*Role exists'||NVL(lc_role_exists,'N'));

      IF lc_role_exists  = 'Y' THEN

         OPEN  get_fnd_user;
         FETCH get_fnd_user INTO lc_user_name;
         CLOSE get_fnd_user;

         --Standard API to create resource in CRM
         CREATE_RESOURCE
                        (p_api_version         => 1.0
                        ,p_commit              =>'T'
                        ,p_category            =>'EMPLOYEE'
                        ,p_source_id           => gn_person_id
                        ,p_source_number       => gc_employee_number
                        ,p_start_date_active   => gd_as_of_date
                        ,p_resource_name       => gc_full_name
                        ,p_source_name         => gc_full_name
                        ,p_user_name           => lc_user_name
--                        ,p_attribute15         => gn_job_id
                        ,x_return_status       => x_return_status
                        ,x_msg_count           => x_msg_count
                        ,x_msg_data            => x_msg_data
                        ,x_resource_id         => gn_resource_id
                        ,x_resource_number     => gc_resource_number
                        );

--WRITE_LOG('*Resource id'||gn_resource_id);

          IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

            x_resource_id       := gn_resource_id  ;

            DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE: Resource created successfully. ');

          ELSE

            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0009_RES_CREATE_FAILED');
            FND_MSG_PUB.add;

            RAISE EX_TERMINATE_PRGM;

          END IF;

          IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
--WRITE_LOG('*Call Process Details');
             PROCESS_RESOURCE_DETAILS
                    (x_return_status   =>  x_return_status
                    ,x_msg_count       =>  x_msg_count
                    ,x_msg_data        =>  x_msg_data
                    );

             IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN


               DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE: Resource details proccessed successfully. ');
--               In Fnd Msg: P_MESSAGE||' '||P_RESDTL_SUCCESS);
--               FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0011_RESDTL_SUCCESS');
--               FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--               FND_MESSAGE.SET_TOKEN('P_RESDTL_SUCCESS', gn_resource_id );
--               -- lc_error_message    := FND_MESSAGE.GET;
--               FND_MSG_PUB.add;


             ELSE
               --In Fnd Msg: P_MESSAGE||' '||P_RES_RESDTL_FAILED);
               lc_error_message    := 'PROCESS_NEW_RESOURCE';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0010_RESDTL_FAIL');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
               FND_MESSAGE.SET_TOKEN('P_RES_RESDTL_FAILED', gn_resource_id );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

             END IF;

          END IF; --End of If resource created successfully then proccessing resources details

      ELSE    -- else for lc_role_exists  = 'Y',  ROLES DOES NOT EXISTS FOR THE JOB ID

         --In Fnd Msg: 'In Procedure:PROCESS_NEW_RESOURCE: Roles do not exist for the Job specified'
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0011_ROLE_NULL');
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         gc_return_status      := 'ERROR';
         x_return_status       := FND_API.G_RET_STS_ERROR;

      END IF;   -- lc_role_exists  = 'Y'

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
      WHEN EX_TERMINATE_PRGM THEN

      lc_error_message    := NULL;
      gc_return_status    := 'ERROR';
      x_return_status     := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0006_PROG_TERMINATED');
      FND_MESSAGE.SET_TOKEN('P_PROCEDURE', 'PROCESS_NEW_RESOURCE' );
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      WHEN OTHERS THEN

      gc_return_status     := 'ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_NEW_RESOURCE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_NEW_RESOURCE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
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


      CURSOR  get_termination_details
      IS
      SELECT  PPS.actual_termination_date
             ,JRRE.object_version_number
      FROM    per_periods_of_service   PPS
             ,jtf_rs_resource_extns_vl JRRE
      WHERE   PPS.person_id          = gn_person_id
      AND     PPS.business_group_id  = gn_biz_grp_id
      AND     JRRE.source_id         = PPS.person_id;


      CURSOR  get_roles_to_enddate
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
      FROM    jtf_rs_role_relations    JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     gd_as_of_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_as_of_date);

      lrec_termination_details         get_termination_details%ROWTYPE;

   BEGIN
      IF get_termination_details%ISOPEN THEN
         CLOSE get_termination_details;
      END IF;

      OPEN  get_termination_details;
      FETCH get_termination_details INTO lrec_termination_details;
      CLOSE get_termination_details;

      ln_object_version_number := lrec_termination_details.object_version_number;
      ld_termination_date      := lrec_termination_details.actual_termination_date;

      END_GRP_AND_RESGRPROLE
                    (p_group_id        => -1
                    ,p_end_date        => ld_termination_date
                    ,x_return_status   => x_return_status
                    ,x_msg_count       => x_msg_count
                    ,x_msg_data        => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --In Fnd Message: P_MESSAGE
        lc_error_message    := 'PROCESS_RES_TERMINATION';
        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0016_ENDGRPRSGRPROLE_F');
        FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
        -- lc_error_message    := FND_MESSAGE.GET;
        FND_MSG_PUB.add;

      ELSE
        --In Fnd Message: P_MESSAGE
        DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: END_GRP_AND_RESGRPROLE Success');
--        FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0024_ENDGRPRSGRPROLE_S');
--        FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--        -- lc_error_message    := FND_MESSAGE.GET;
--        FND_MSG_PUB.add;
      END IF;

      FOR  roles_to_enddate_rec  IN  get_roles_to_enddate
      LOOP

         ENDDATE_RES_ROLE(
                  p_role_relate_id  => roles_to_enddate_rec.roles_relate_id,
                  p_end_date_active => ld_termination_date,
                  p_object_version  => roles_to_enddate_rec.roles_obj_ver_num,
                  x_return_status   => lc_return_status,
                  x_msg_count       => ln_msg_count,
                  x_msg_data        => lc_msg_data
                  );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            lc_error_message    := 'PROCESS_RES_TERMINATION';
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0012_ENDDTRSROLE_FAIL');
            FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
            -- lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

           IF gc_return_status <> 'ERROR' THEN

              gc_return_status := 'WARNING';

           END IF;

         ELSE
           DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RES_ROLE Success');
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0022_ENDDTRSROLE_S');
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         END IF;

      END LOOP;

      ENDDATE_SALESREP
                 (p_resource_id     => gn_resource_id,
                  p_end_date_active => ld_termination_date,
                  x_return_status   => lc_return_status,
                  x_msg_count       => ln_msg_count,
                  x_msg_data        => lc_msg_data
                 );

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --In Fnd Message: P_MESSAGE
         lc_error_message    := 'PROCESS_RES_TERMINATION';
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0015_ENDDTSLSREP_F');
         FND_MESSAGE.SET_TOKEN('P_PROCEDURE',lc_error_message );
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         IF gc_return_status <> 'ERROR' THEN

            gc_return_status := 'WARNING';

         END IF;

      ELSE
        --In Fnd Message: P_MESSAGE
        DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_SALESREP Success');
--        FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0020_ENDDTSLSREP_S');
--        FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
--        -- lc_error_message    := FND_MESSAGE.GET;
--        FND_MSG_PUB.add;

      END IF;

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

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0014_ENDDTRS_FAIL');
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         gc_return_status    := 'ERROR';

      ELSE
        --In Fnd Message: 'In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RESOURCE Success
         DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_RESOURCE Success');
--        FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0019_ENDDTRS_SUCCESS');
--        -- lc_error_message    := FND_MESSAGE.GET;
--        FND_MSG_PUB.add;

      END IF;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
      WHEN OTHERS THEN

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    := 'ERROR';
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_RES_TERMINATION: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_RES_TERMINATION'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
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


      EX_TERMINATE_PRGM          EXCEPTION;

      CURSOR  get_job
      IS
      SELECT  job_id
      FROM    per_all_assignments_f
      WHERE   person_id         = gn_person_id
      AND     business_group_id = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      CURSOR  get_roles_to_enddate(p_job_id   NUMBER)
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
             ,JRGMR.role_relate_id MBR_RELATE_ID
             ,JRRR2.object_version_number MBR_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     gd_as_of_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN   JRRR2.start_date_active
              AND       NVL(JRRR2.end_date_active,gd_as_of_date)
      AND     JRRR.role_id NOT IN (
                                   SELECT  role_id
                                   FROM    jtf_rs_job_roles_vl
                                   WHERE   job_id  = p_job_id
                                  );

      CURSOR  check_is_mgr
      IS
      SELECT 'Y' MGR_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_role_relations_vl JRLV
             ,jtf_rs_roles_b           JRRB
      WHERE   JRLV.manager_flag     = 'Y'
      AND    (JRLV.role_type_code   = 'SALES'
      OR      JRLV.role_type_code   = 'SALES_COMP')
      AND     JRLV.role_id          =  JRRB.role_id
      AND     JRLV.role_resource_id =  gn_resource_id
      AND     NVL(JRRB.active_flag,'N') = 'Y');

      CURSOR  get_asgn_slsupport_roles
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
             ,JRGMR.role_relate_id MBR_RELATE_ID
             ,JRRR2.object_version_number MBR_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
             ,jtf_rs_roles_vl  JRRV
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     JRRV.role_id            = JRRR.role_id
      AND     JRRV.attribute14        ='SALES_SUPPORT'
      AND     gd_as_of_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_as_of_date)
      AND     gd_as_of_date
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_as_of_date);



   BEGIN

      IF get_job%ISOPEN THEN

         CLOSE get_job;

      END IF;

      OPEN get_job;

      FETCH get_job INTO gn_job_id;

      CLOSE get_job;

      IF gn_job_id IS NOT NULL  THEN

         FOR  roles_to_enddate_rec  IN  get_roles_to_enddate(gn_job_id)
         LOOP

            ENDDATE_RES_GRP_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.mbr_relate_id,
                     P_END_DATE_ACTIVE => gd_as_of_date - 1,
                     P_OBJECT_VERSION  => roles_to_enddate_rec.mbr_obj_ver_num,
                     X_RETURN_STATUS   => lc_return_status,
                     X_MSG_COUNT       => ln_msg_count,
                     X_MSG_DATA        => lc_msg_data
                     );
--WRITE_LOG('* end mbr role relate id :'||roles_to_enddate_rec.mbr_relate_id);
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               --In Fnd Message: P_MESSAGE
               lc_error_message    := 'PROCESS_RES_CHANGES';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0013_ENDDTRSGRPROLE_F');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

               IF gc_return_status <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

            ELSE
              --In Fnd Message: P_MESSAGE
               DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_GRP_ROLE Success ');
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0017_ENDDTRSGRPROLE_S');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;

            ENDDATE_RES_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.roles_relate_id,
                     P_END_DATE_ACTIVE => gd_as_of_date - 1,
                     P_OBJECT_VERSION  => roles_to_enddate_rec.roles_obj_ver_num,
                     X_RETURN_STATUS   => lc_return_status,
                     X_MSG_COUNT       => ln_msg_count,
                     X_MSG_DATA        => lc_msg_data
                     );
--WRITE_LOG('* End resource role relate id:'||roles_to_enddate_rec.roles_relate_id);
            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

              --In Fnd Message: P_MESSAGE
               lc_error_message    := 'PROCESS_RES_CHANGES';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0012_ENDDTRSROLE_FAIL');
               FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;


               IF gc_return_status <> 'ERROR' THEN

                  gc_return_status := 'WARNING';

               END IF;

            ELSE
              --In Fnd Message: P_MESSAGE
              DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE Success');
--              FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0015_ENDDTRSROLE_SUCCES');
--              FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--              -- lc_error_message    := FND_MESSAGE.GET;
--              FND_MSG_PUB.add;

            END IF;

         END LOOP;

         IF check_is_mgr%ISOPEN THEN
            CLOSE check_is_mgr;
         END IF;

         OPEN  check_is_mgr;
         FETCH check_is_mgr INTO lc_manager_flag;
         CLOSE check_is_mgr;
--WRITE_LOG('* Is manager flag '||         lc_manager_flag);
         IF ( NVL(lc_manager_flag,'N') = 'Y' ) THEN

            FOR  slsupport_role_rec IN get_asgn_slsupport_roles
            LOOP

               ENDDATE_RES_GRP_ROLE(
                     p_role_relate_id  => slsupport_role_rec.mbr_relate_id,
                     p_end_date_active => gd_as_of_date - 1,
                     p_object_version  => slsupport_role_rec.mbr_obj_ver_num,
                     x_return_status   => lc_return_status,
                     x_msg_count       => ln_msg_count,
                     x_msg_data        => lc_msg_data
                     );
--WRITE_LOG('* end sales support mbr relate id '||slsupport_role_rec.mbr_relate_id);

                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  --In Fnd Message: P_MESSAGE
                   lc_error_message    := 'PROCESS_RES_CHANGES';
                   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0013_ENDDTRSGRPROLE_F');
                   FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
                   -- lc_error_message    := FND_MESSAGE.GET;
                   FND_MSG_PUB.add;

                   IF gc_return_status <> 'ERROR' THEN

                      gc_return_status := 'WARNING';

                   END IF;

                ELSE
                  --In Fnd Message: P_MESSAGE
                  DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_GRP_ROLE for manager Success');
--                  FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0021_ENDDTRSGRPROLE_S');
--                  FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--                  -- lc_error_message    := FND_MESSAGE.GET;
--                  FND_MSG_PUB.add;

                END IF;


               ENDDATE_RES_ROLE(
                     p_role_relate_id  => slsupport_role_rec.roles_relate_id,
                     p_end_date_active => gd_as_of_date - 1,
                     p_object_version  => slsupport_role_rec.roles_obj_ver_num,
                     x_return_status   => lc_return_status,
                     x_msg_count       => ln_msg_count,
                     x_msg_data        => lc_msg_data
                     );
--WRITE_LOG('* end res role relate id '||slsupport_role_rec.roles_relate_id);

                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  --In Fnd Message: P_MESSAGE
                   lc_error_message    := 'PROCESS_RES_CHANGES';
                   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0012_ENDDTRSROLE_FAIL');
                   FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
                   -- lc_error_message    := FND_MESSAGE.GET;
                   FND_MSG_PUB.add;

                   IF gc_return_status <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                   END IF;

                ELSE
                  --In Fnd Message: P_MESSAGE
                  DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE for manager Success');
--                  FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0015_ENDDTRSROLE_SUCCES');
--                  FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--                  -- lc_error_message    := FND_MESSAGE.GET;
--                  FND_MSG_PUB.add;

                END IF;

            END LOOP;

         END IF;  -- END IF, ( NVL(lc_manager_flag,'N') = 'Y' )

         -- Prem,should i call update email???
--WRITE_LOG('* Call process details ');
         PROCESS_RESOURCE_DETAILS
                 (x_return_status   => x_return_status
                 ,x_msg_count       => x_msg_count
                 ,x_msg_data        => x_msg_data
                 );

         IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

           --In Fnd Msg: P_MESSAGE||' '||P_RESDTL_SUCCESS);
           DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Resource details proccessed successfully');
--           FND_MESSAGE.SET_NAME('XXCRM', 'XX_CRM_0011_RESDTL_SUCCESS');
--           FND_MESSAGE.SET_TOKEN('P_MESSAGE', lc_error_message );
--           FND_MESSAGE.SET_TOKEN('P_RESDTL_SUCCESS', gn_resource_id );
--           -- lc_error_message    := FND_MESSAGE.GET;
--           FND_MSG_PUB.add;

         ELSE
           --In Fnd Msg: P_MESSAGE||' '||P_RES_RESDTL_FAILED);
           lc_error_message    := 'PROCESS_RES_CHANGES';
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0010_RESDTL_FAIL');
           FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
           FND_MESSAGE.SET_TOKEN('P_RES_RESDTL_FAILED', gn_resource_id );
           -- lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;

         END IF;

      ELSE

         --In fnd Message:  P_JOB_NULL||' Job ID is null in HRMS';
         lc_error_message := 'PROCESS_RES_CHANGES';
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0008_JOB_NULL');
         FND_MESSAGE.SET_TOKEN('P_PROCEDURE', lc_error_message );
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         RAISE EX_TERMINATE_PRGM;

      END IF;  -- END IF, gn_job_id IS NOT NULL

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

   EXCEPTION
      WHEN EX_TERMINATE_PRGM THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_RES_CHANGES: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_RES_CHANGES'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
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

      CURSOR  check_termination
      IS
      SELECT  termination_status
      FROM   (SELECT  'Y' termination_status
              FROM    per_all_people_f       PAPF
                     ,per_periods_of_service PPOS
                     ,per_person_types       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   <= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EX_EMP'
              OR      PPT.system_person_type          = 'EX_CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     gd_as_of_date
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
              AND     PPOS.actual_termination_date   >= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EMP'
              OR      PPT.system_person_type          = 'CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.business_group_id          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              AND     gd_as_of_date
                      BETWEEN  PAPF.effective_start_date
                      AND      PAPF.effective_end_date );

   BEGIN

      IF check_termination%ISOPEN THEN

         CLOSE check_termination;

      END IF;

      OPEN  check_termination;

      FETCH check_termination INTO lc_termination_flag;

      CLOSE check_termination;

      DEBUG_LOG('Resource Termination exists (Y/N): '||NVL(lc_termination_flag,'N'));

      IF ( NVL(lc_termination_flag,'N') = 'Y') THEN

         PROCESS_RES_TERMINATION
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      ELSE

         UPDATE_EMAIL
                     (p_resource_id       => gn_resource_id
                     ,x_return_status     => x_return_status
                     ,x_msg_count         => x_msg_count
                     ,x_msg_data          => x_msg_data
                     );

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

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_EXISTING_RESOURCE: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_EXISTING_RESOURCE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END PROCESS_EXISTING_RESOURCE;


   ------------------------------------------------------------------------
   ------------------------End of Internal Procs---------------------------
   ------------------------------------------------------------------------

   ------------------------------------------------------------------------
   --------------------------Exposed Procs---------------------------------
   ------------------------------------------------------------------------

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

   PROCEDURE UPDATE_EMAIL
             (p_resource_id             IN  NUMBER
             ,p_init_msg_list           IN  VARCHAR2   DEFAULT  FND_API.G_FALSE
             ,x_return_status          OUT  VARCHAR2
             ,x_msg_count              OUT  NUMBER
             ,x_msg_data               OUT  VARCHAR2
             )
   IS

      lc_error_message            VARCHAR2(4000);

      CURSOR  get_salesrep_det
      IS
      SELECT  JRS.salesrep_id
            , JRS.sales_credit_type_id
            , JRS.object_version_number
            , PAPF.email_address SOURCE_EMAIL
            , JRS.email_address  CRM_EMAIL
            , JRS.org_id
      FROM    jtf_rs_resource_extns_vl  JRRE
            , jtf_rs_salesreps          JRS
            , per_all_people_f          PAPF
      WHERE   JRRE.source_id   = PAPF.person_id
      AND     JRS.resource_id  = JRRE.resource_id
      AND     JRRE.resource_id = p_resource_id;

   BEGIN

      -- Initialize fnd message pub
      IF fnd_api.to_boolean(p_init_msg_list) THEN

         fnd_msg_pub.initialize;

      END IF;

      FOR  salesrep_rec IN get_salesrep_det
      LOOP

         IF  NVL(salesrep_rec.CRM_EMAIL,'A') <> NVL(salesrep_rec.SOURCE_EMAIL,'A') THEN

            JTF_RS_SALESREPS_PUB.update_salesrep
                (P_API_VERSION             => 1.0,
                 P_SALESREP_ID             => salesrep_rec.salesrep_id  ,
                 P_SALES_CREDIT_TYPE_ID    => salesrep_rec.sales_credit_type_id,
                 P_EMAIL_ADDRESS           => salesrep_rec.source_email,
                 P_ORG_ID                  => salesrep_rec.org_id,
                 P_OBJECT_VERSION_NUMBER   => salesrep_rec.object_version_number,
                 X_RETURN_STATUS           => x_return_status,
                 X_MSG_COUNT               => x_msg_count,
                 X_MSG_DATA                => x_msg_data
                );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               --In Fnd Message: P_MESSAGE
               --lc_error_message    := 'In Procedure:UPDATE_EMAIL: Proc: Update salesrep Fails';
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0017_UPDSLSREP_F');
               --FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
               -- lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

            ELSE
              --In Fnd Message: P_MESSAGE
              --lc_error_message    := 'In Procedure:UPDATE_EMAIL: Proc: Update salesrep Success';
              FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0046_UPDSLSREP_S');
              --FND_MESSAGE.SET_TOKEN('P_MESSAGE',lc_error_message );
              -- lc_error_message    := FND_MESSAGE.GET;
              FND_MSG_PUB.add;

            END IF;

         END IF; -- NVL(salesrep_rec.CRM_EMAIL,'A') <> NVL(salesrep_rec.SOURCE_EMAIL,'A')

      END LOOP;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      RETURN;

   EXCEPTION
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:UPDATE_EMAIL: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'UPDATE_EMAIL'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

   END UPDATE_EMAIL;


   -- +===================================================================+
   -- | Name  : PROCESS_RESOURCES                                         |
   -- |                                                                   |
   -- | Description:       This Procedure shall check if the person is a  |
   -- |                    new Resources in CRM based on source id from   |
   -- |                    HRMS.                                          |
   -- |                    This shall call PROCESS_NEW_RESOURCE in case of|
   -- |                    New Resource to be created and                 |
   -- |                    PROCESS_EXISTING_RESOURCE in case resource     |
   -- |                    exists in CRM.                                 |
   -- +===================================================================+

   PROCEDURE PROCESS_RESOURCES
                     (p_person_id        IN          NUMBER
                     ,p_as_of_date       IN          DATE
                     ,p_init_msg_list    IN          VARCHAR2   DEFAULT  FND_API.G_FALSE
                     ,x_resource_id      OUT NOCOPY  NUMBER
                     ,x_return_status    OUT NOCOPY  VARCHAR2
                     ,x_msg_count        OUT NOCOPY  NUMBER
                     ,x_msg_data         OUT NOCOPY  VARCHAR2
                     )
   IS

      lc_resource_exists         VARCHAR2(1);
      lc_error_message           VARCHAR2(1000);

      CURSOR get_emp_details(p_per_id NUMBER)
      IS
      SELECT   PAPF.employee_number
              ,PAPF.full_name
              ,PAPF.email_address
      FROM     per_all_people_f  PAPF
      WHERE    PAPF.person_id  = p_per_id
      AND      gd_as_of_date
               BETWEEN  PAPF.effective_start_date
               AND      PAPF.effective_end_date;

      CURSOR   check_resource
      IS
      SELECT  'Y' resource_exists
              ,resource_id
              ,resource_number
      FROM     jtf_rs_resource_extns_vl
      WHERE    source_id  = gn_person_id;

      lrec_emp_details           get_emp_details%ROWTYPE;
      lrec_check_resource        check_resource%ROWTYPE;

      EX_TERMINATE_PRGM          EXCEPTION;


   BEGIN

      -- Initialize fnd message pub
      fnd_msg_pub.initialize;

      -- ----------------------------------
      -- Assign 'Y' to the concurrent flag
      -- if profile is set to debug
      -- ----------------------------------
      IF (FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG') = 'Y' ) THEN
       gc_debug_flag := 'Y' ;
      END IF;

      SAVEPOINT PROCESS_RESOURCE_SP;

      gd_as_of_date := trunc(p_as_of_date) ;
      gn_person_id  := p_person_id         ;


      --If global variables are NULL
      IF   gc_employee_number IS NULL AND
           gc_full_name       IS NULL AND
           gc_email_address   IS NULL THEN


         IF get_emp_details%ISOPEN THEN
            CLOSE get_emp_details;
         END IF;

         OPEN  get_emp_details(gn_person_id);
         FETCH get_emp_details INTO lrec_emp_details;
         CLOSE get_emp_details;

         gc_employee_number :=  lrec_emp_details.employee_number;
         gc_full_name       :=  lrec_emp_details.full_name;
         gc_email_address   :=  lrec_emp_details.email_address;

      END IF; --If global variables are NULL

      IF gc_employee_number IS NULL OR gc_full_name IS NULL THEN

      --In Message: 'In Procedure:Process_Resources: Employee number and Full name does not exists for the employee';

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         -- lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         RAISE EX_TERMINATE_PRGM;

      END IF;

      DEBUG_LOG('Processing for the person name: '||gc_full_name);

      IF check_resource%ISOPEN THEN

         CLOSE check_resource;

      END IF;

      OPEN  check_resource;

      FETCH check_resource INTO lrec_check_resource;

      lc_resource_exists := lrec_check_resource.resource_exists;
      gn_resource_id     := lrec_check_resource.resource_id;
      gc_resource_number := lrec_check_resource.resource_number;

      CLOSE check_resource;

      DEBUG_LOG('Is it an existing Resource (Y/N): ' ||NVL(lc_resource_exists,'N'));

      IF ( NVL(lc_resource_exists,'N') = 'N' ) THEN
--WRITE_LOG('*Call Process New resource');

         PROCESS_NEW_RESOURCE
                     (x_resource_id      => x_resource_id
                     ,x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      ELSE   -- lc_resource_exists = 'N'  , WHEN RESOURCE EXISTS

--WRITE_LOG('* Call existing resource');

         PROCESS_EXISTING_RESOURCE
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      END IF;  -- ( NVL(lc_resource_exists,'N') = 'N' )

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);


      EXCEPTION

      WHEN EX_TERMINATE_PRGM THEN

      gc_return_status       := 'ERROR';
      x_return_status        := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0006_PROG_TERMINATED');
      FND_MESSAGE.SET_TOKEN('P_PROCEDURE', 'PROCESS_RESOURCES' );
      -- lc_error_message    := FND_MESSAGE.GET;
      FND_MSG_PUB.add;

      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);


      ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;

      WHEN OTHERS THEN
      gc_return_status     := 'ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:PROCESS_RESOURCES: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data  => x_msg_data);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'PROCESS_RESOURCES'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );


      ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;

   END PROCESS_RESOURCES;


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
                 (x_errbuf       OUT VARCHAR2
                 ,x_retcode      OUT NUMBER
                 ,p_person_id    IN  NUMBER
                 ,p_as_of_date   IN  DATE
                 )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lc_return_status   VARCHAR2(5);
      ln_msg_count       PLS_INTEGER;
      lc_msg_data        VARCHAR2(1000);

      l_resource_id      PLS_INTEGER ;
      l_total_count      PLS_INTEGER ;
      l_success          PLS_INTEGER ;
      l_errored          PLS_INTEGER ;
      l_warning          PLS_INTEGER ;
      lc_error_message   VARCHAR2(4000);
      lc_total_count     VARCHAR2(1000);--PLS_INTEGER;
      lc_total_success   VARCHAR2(1000);--PLS_INTEGER;
      lc_total_failed    VARCHAR2(1000);--PLS_INTEGER;
      -- ----------------------------------------------------------------
      -- Declare cursor to get all the employees reporting to the manager
      -- ----------------------------------------------------------------

      CURSOR  lcu_get_employees
      IS
      SELECT  PAAF.person_id           person_id
            , PAPF.full_name           full_name
            , PAPF.email_address       email_address
            , PAPF.employee_number     employee_number   -- 290807 Added by NG
      FROM    per_all_assignments_f    PAAF
            , per_all_people_f         PAPF
            , per_person_types         PPT
            , per_person_type_usages_f PPTU
      WHERE   PAAF.person_id               = PAPF.person_id
      AND     PAPF.person_id               = PPTU.person_id
      AND     PPT. person_type_id          = PPTU.person_type_id
      AND     UPPER (PPT.user_person_type) = 'EMPLOYEE'
      CONNECT BY PRIOR PAAF.person_id   = PAAF.supervisor_id
        START WITH     PAAF.person_id   = p_person_id
      AND p_as_of_date BETWEEN
                  PAAF.effective_start_date AND PAAF.effective_end_date
      AND p_as_of_date BETWEEN
                  PAPF.effective_start_date AND PAPF.effective_end_date
      AND p_as_of_date BETWEEN
                  PPTU.effective_start_date AND PPTU.effective_end_date
      AND PAAF.business_group_id = gn_biz_grp_id
      AND PAPF.business_group_id = gn_biz_grp_id
      AND PPT .business_group_id = gn_biz_grp_id
      ORDER SIBLINGS BY last_name;


      TYPE employee_details_tbl IS TABLE OF lcu_get_employees%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_employee_details employee_details_tbl;

   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN

       fnd_msg_pub.initialize;
       -- ----------------------------------
       -- Assign 'Y' to the concurrent flag
       -- if profile is set to debug
       -- ----------------------------------

--       IF (FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG') = 'Y' ) THEN
--          gc_debug_flag := 'Y' ;
--       END IF;

       l_total_count  := 0   ;
       l_success      := 0   ;
       l_errored      := 0   ;
       l_warning      := 0   ;

       gc_conc_prg_id := fnd_global.CONC_PROGRAM_ID;

       -- --------------------------------------
       -- DISPLAY PROJECT NAME AND PROGRAM NAME
       -- --------------------------------------

        WRITE_LOG(RPAD('Office Depot',50)||'Date: '||trunc(sysdate));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_LOG(LPAD('Oracle HRMS - CRM Synchronization',52));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_LOG('');
        WRITE_LOG('Input Parameters ');
        WRITE_LOG('Person Id : '||p_person_id);
        WRITE_LOG('As-Of-Date: '||p_as_of_date);

        WRITE_OUT(RPAD('Office Depot',50)||' Date: '||trunc(sysdate));
        WRITE_OUT(RPAD(' ',76,'-'));
        WRITE_OUT(LPAD('Oracle HRMS - CRM Synchronization',52));
        WRITE_OUT(RPAD(' ',76,'-'));
        WRITE_OUT('');

        WRITE_OUT(RPAD('Employee Number ',40)||RPAD('Employee Name ',30)||RPAD('Status ',10));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_OUT(' ');


       -- -------------------------------------------------------
       -- Store the records fetched from cursor to the table type
       -- -------------------------------------------------------
       gd_as_of_date  := p_as_of_date;

       OPEN  lcu_get_employees;
       FETCH lcu_get_employees BULK COLLECT INTO lt_employee_details;
       CLOSE lcu_get_employees;

       l_total_count  := lt_employee_details.count;

       -- -----------------------------------------------------------
       -- Call the procedure for all directs reporting to the manager
       -- -----------------------------------------------------------

       IF lt_employee_details.count > 0 THEN

         FOR i IN lt_employee_details.first..lt_employee_details.last
         LOOP
             x_retcode := NULL;

             -- --------------------------------
             -- Reset the flag for each resource
             -- --------------------------------

             --Assigining the values into global variables
             gn_person_id        := NULL;
             gc_employee_number  := NULL;
             gc_full_name        := NULL;
             gc_email_address    := NULL;
             gn_resource_id      := NULL;
             gc_resource_number  := NULL;
             gn_job_id           := NULL;
             gc_return_status    := NULL;


             gn_person_id        := lt_employee_details(i).person_id;
             gc_employee_number  := lt_employee_details(i).employee_number;
             gc_full_name        := lt_employee_details(i).full_name;
             gc_email_address    := lt_employee_details(i).email_address;


             WRITE_LOG(' ');
             WRITE_LOG(RPAD(' ',76,'-'));
             WRITE_LOG('Processing for the person name: '||gc_full_name);

             PROCESS_RESOURCES
                     (p_person_id        => gn_person_id
                     ,p_as_of_date       => p_as_of_date
                     ,p_init_msg_list    => FND_API.G_TRUE
                     ,x_resource_id      => l_resource_id
                     ,x_return_status    => lc_return_status
                     ,x_msg_count        => ln_msg_count
                     ,x_msg_data         => lc_msg_data
                     );

             --WRITE_OUT('Employee Number: ' || LPAD(gc_employee_number,5)||' ,Employee Name: '||LPAD(gc_full_name,10)||' ,Status: '||LPAD(gc_return_status,4));
             WRITE_OUT(RPAD(gc_employee_number,40)||RPAD(gc_full_name,30)||RPAD(NVL(gc_return_status,'SUCCESS'),10));
             --WRITE_OUT(RPAD(' ',76,'-'));

             WRITE_LOG('Processing Status: '||NVL(gc_return_status,'SUCCESS'));

             -- ----------------------------------------------------------------------------
             -- If any error occured during processing of Resources, Roles, Groups and Group
             -- Membership.
             -- ----------------------------------------------------------------------------

             IF gc_return_status = 'ERROR' THEN

                l_errored := l_errored + 1;

             ELSIF gc_return_status = 'WARNING' THEN

                l_warning := l_warning + 1;

             ELSE

                l_success := l_success + 1;

             END IF;

             --Write all the error logged in error message stack to conc prog log file.
             FOR  i IN 1..ln_msg_count
             LOOP

                lc_error_message := NULL;
                lc_error_message := FND_MSG_PUB.GET(i,FND_API.G_FALSE);

                IF lc_error_message IS NOT NULL THEN
                  WRITE_LOG(lc_error_message);
                END IF;

             END LOOP;

          END LOOP;

       ELSE

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0001_EMPLOYEE_NOT_FOUND');
         FND_MESSAGE.SET_TOKEN('P_EMPLOYEE_ID', p_person_id );
         FND_MESSAGE.SET_TOKEN('P_AS_OF_DATE', p_as_of_date );

         lc_error_message := FND_MESSAGE.GET;
         WRITE_LOG(lc_error_message);

       END IF;

       -- ----------------------------------------------------------------------------
       -- Write to output file, the total number of records processed, number of
       -- success and failure records.
       -- ----------------------------------------------------------------------------
       WRITE_OUT(' ');

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0002_RECORD_FETCHED');
       FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', l_total_count );
       lc_total_count    := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_count);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0003_RECORD_SUCCESS');
       FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS',l_success );
       lc_total_success  := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_success);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0048_RECORD_WARNING');
       FND_MESSAGE.SET_TOKEN('P_RECORD_WARNING',l_warning );
       lc_total_success  := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_success);

       FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0004_RECORD_FAILED');
       FND_MESSAGE.SET_TOKEN('P_RECORD_FAILED', l_errored);
       lc_total_failed   := FND_MESSAGE.GET;
       WRITE_OUT(lc_total_failed);


   EXCEPTION
   WHEN OTHERS THEN
      x_errbuf  := 'Completed with errors,  '||SQLERRM ;
      WRITE_LOG(x_errbuf);
      x_retcode := 2 ;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_program_type            =>'CONCURRENT PROGRAM'
                            ,p_program_name            =>'XXCRMHRCRMCONV'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             =>'E1002_HR_CRM_Synchronization'
                            ,p_error_location          =>'MAIN'
                            ,p_error_message_code      => SQLCODE
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  =>'FATAL'
                            );

      ROLLBACK;
      RETURN;

   END MAIN;

END XX_CRM_HRCRM_SYNC_PKG;
/

SHOW ERRORS

-- EXIT