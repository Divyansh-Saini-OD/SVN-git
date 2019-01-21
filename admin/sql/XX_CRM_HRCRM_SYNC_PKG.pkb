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
  -- | Name             :  XX_CRM_HRCRM_SYNC_PKG                                          |
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
  -- |Draft 1b  13-Nov-07   Gowri Nagarajan  Incorporated Error Logging changes           |
  -- |Draft 1c  04-Dec-07   Gowri Nagarajan  Modified the date format to 'DD-MON-RR'      |
  -- |                                       for the HRMS and CRM effectivity dates       |
  -- |Draft 1d  06-Dec-07   Gowri Nagarajan  Modified the main query connect by location  |
  -- |Draft 1e  07-Dec-07   Gowri Nagarajan  Modified the main query for duplicates       |
  -- |                                       elimination                                  |
  -- |Draft 1f  08-Dec-07   Gowri Nagarajan  Added end_date_active null to the            |
  -- |                                       CREATE_SALES_REP to eliminate end dated OU   |
  -- |                                       lookup codes.                                |
  -- |Draft 1g  11-Dec-07   Gowri Nagarajan  Added                                        |
  -- |                                        a)Error logging for missed out Fnd messages |
  -- |                                        b)Added date_to condition while getting OU, |
  -- |                                          lookup_codes existing condition           |
  -- |                                        c)Added the Write_log call in the DEBUG_LOG |
  -- |                                          procedure                                 |
  -- |                                        d)Added delete_flag = 'N' for all queries   |
  -- |                                          wherever JTF_RS_ROLE_RELATIONS table used |
  -- |                                        e)Modified logic for Concurrent Prgm        |
  -- |                                          Error Status                              |
  -- |                                        f)Modified gd_job_asgn_date to              |
  -- |                                          greatest(gd_job_asgn_date                 |
  -- |                                          ,gd_mgr_asgn_date) in PROCESS_NONMANAGER_ |
  -- |                                           ASSIGNMENTS procedure                    |
  -- |                                        g)Added VALIDATE_SETUPS procedure for       |
  -- |                                          validating mandatory setups               |
  -- |Draft 1h  17-Dec-07   Gowri Nagarajan  For CR of Bonus Eligibility,                 |
  -- |                                         a) Added GET_BONUS_DATE procedure          |
  -- |                                         b) Implemented above procedure in          |
  -- |                                            ASSIGN_ROLE and BACK_DATE_CURR_ROLES    |
  -- |Draft 1i  28-Dec-07   Gowri Nagarajan  Changed Attribute14 to Attribute15 for       |
  -- |                                       Bonus Eligibility Date and implemented in    |
  -- |                                       ASSIGN_ROLE and BACK_DATE_CURR_ROLES Proc    |
  -- |Draft 1j  03-Jan-08   Gowri Nagarajan  Changed the code for Bonus Eligibility Date  |
  -- |                                       setting of second or more sales comp roles   |
  -- |Draft 1k  08-Jan-08   Gowri Nagarajan  Changed the code for Bonus Eligibility date  |
  -- |                                       calculation for                              |
  -- |                                       a)Attribute15 to Attribute14 change          |
  -- |                                       b)Sales roles Inclusion                      |
  -- |                                       Added Error message to the log Output file   |
  -- |Draft 1l  17-Jan-08   Gowri Nagarajan  Changed the code for concurrent program      |
  -- |                                       log and Output file rationalization          |
  -- |Draft 1m  23-Jan-08   Gowri Nagarajan  Added Job Id to the mandatory checks in the  |
  -- |                                       MAIN and PROCESS_RESOURCES procedure         |
  -- |Draft 1n  25-Feb-08   Gowri Nagarajan  Changed the code for Bonus Eligibility date  |
  -- |                                       setting at the Group membership role level   |
  -- |Draft 1o  10-Mar-08   Gowri Nagarajan  Changed the code for the deletion of         |
  -- |                                       Parent-Child hierarchy between sales groups  |
  -- |                                       and seeded group with Group Id = -1.         |
  -- |Draft 1p  13-Mar-08   Gowri Nagarajan  Changed the code for Name mismatch problem   |
  -- |                                       with the Employee name and Group Name        |
  -- |                                       (Finding Supervisor Group based on           |
  -- |                                        Attrribute15 of Groups table instead        |
  -- |                                        of Group Name)                              |
  -- |Draft 1q  18-Mar-08   Gowri Nagarajan  Changed the code for handling date mismatch  |
  -- |                                       on the HR                                    |
  -- |Draft 1r  24-Apr-08   Gowri Nagarajan  a)Added EX_EMP in the CONNECT BY Query of    |
  -- |                                        MAIN proc				            |
  -- |                                       b)Removed EX_EMP from the                    |
  -- |                                         lcu_check_termination cursor               |
  -- |Draft 1s  24-Apr-08   Gowri Nagarajan  a)Changed CONNECT BY Query to support        |
  -- |                                         backdated and future dated termination     |
  -- |                                       b)Changed the cursor lcu_get_roles_to_enddate|
  -- |                                         of PROCESS_RES_TERMINATION proc            |
  -- |                                         for proper role end dation                 |
  -- |Draft 1t  11-Jun-08   Gowri Nagarajan  a)Commented the code only at the BED         |
  -- |                                         population(attribute14) level of           |
  -- |                                         a)ASSIGN_RES_TO_GROUP_ROLE and 		|
  -- |                                         b)BACKDATE_RES_GRP_ROLE			      |
  -- |                                         procedure calls.				      |
  -- |Draft 1u  12-Jun-08   Gowri Nagarajan  a)Changed the code to pickup resources with  |
  -- |                                         null CRM job date and CRM Supervisor date  |
  -- |                                         in PROCESS_RES_CHANGES proc 		      |
  -- |          25-Jun-08   Gowri Nagarajan  b)Added new fnd message			      |
  -- |                                          XX_TM_0266_NO_RES_ROLE                    |
  -- |          27-Jun-08   Gowri Nagarajan  c)Added check in the ASSIGN_ROLE_TO_GROUP	|
  -- |                                         to find whether the role already exists 	|
  -- |                                         in the group/not				      |
  -- |                                       d)Added Job name to the fnd message 	      |
  -- |                                          XX_TM_0011_ROLE_NULL.			      | 
  -- |          02-Jul-08   Gowri Nagarajan  e)Added Resource Exists,Resource Type in the |
  -- |                                          out file			                  |
  -- |          03-Jul-08   Gowri Nagarajan  f)Added Manager Name in the out file         |
  -- |                                       g)Changed the gc_err_msg(error message)      |
  -- |                                         logging calculation 			      |
  -- |          04-Jul-08   Gowri Nagarajan  h)Added Job_id to the message  		      |
  -- |                                         XX_TM_0011_ROLE_NULL			      |
  -- |Draft 1v  08-Jul-08   Gowri Nagarajan    Changed the code to have the error message |
  -- |                                         in the out file in a single line           | 
  -- |Draft 1w  25-Jul-08   Gowri Nagarajan  a)Added the parameter p_hierarchy_type to    |
  -- |                                          Main and Process_Resource Proc.           | 
  -- |                                       b)Added PROCESS_COLLECTION_RESOURCES for     |
  -- |                                          processing collections hierarchy records  |
  -- |                                       c)Added Collections role type in all the 	|
  -- |                                         possible scenarios			            |
  -- |Draft 1x  24-Dec-08   Kishore Jena     a)Added extra log to track resource changes. |
  -- |Draft 1y  08-Jan-09   Kishore Jena     a)Changed Code to set group start date for   |
  -- |                                         all new groups to 01-JAN-1980.             |
  -- |                                       b)Changed code to ignore proxy roles in      |
  -- |                                         job-role mapping for all error checks.     |
  -- |                                       c)Added logic to retroactively fix resource/ |
  -- |                                         role/group hierarchy as of a past date.    |
  -- |                                       d)Bug fix to avoid half transaction commits. |
  -- |                                       e)Changed code to report "Terminated Employee|
  -- |                                         will not be created as a Resource." as     |
  -- |                                         WARNING instead of ERROR.                  |
  -- |Draft 1z  10-Jun-09   Kishore Jena     a)Changed Code to fix defects raised by      |
  -- |                                         Collections hierarchy (team).              |
  -- | Defect 15151                          a) Changed query to ignore resources         |
  -- |                                          who are already terminated in RM.         |
  -- | Defetc 11701         Deepak V [AMS]   a)Code Changed to consider cases where grp   |
  -- |                                         relation exists and the group start date is|
  -- |                                         less than mgr_assign_date (redone as this  |
  -- |										   was overwritten by 15151.                  |
  -- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|  
  -- +====================================================================================+
IS
   ----------------------------
   --Declaring Global Constants
   ----------------------------
   GC_OD_SALES_ADMIN_GRP       CONSTANT VARCHAR2(30) := 'OD_SALES_ADMIN_GRP'    ;
   GC_OD_PAYMENT_ANALYST_GRP   CONSTANT VARCHAR2(30) := 'OD_PAYMENT_ANALYST_GRP';
   GC_OD_SUPPORT_GRP           CONSTANT VARCHAR2(30) := 'OD_SUPPORT_GRP'        ;
   GC_APPN_NAME                CONSTANT VARCHAR2(30) := 'XXCRM';
   GC_PROGRAM_TYPE             CONSTANT VARCHAR2(40) := 'E1002_HR_CRM_Synchronization';
   GC_MODULE_NAME              CONSTANT VARCHAR2(30) := 'TM';
   GC_ERROR_STATUS             CONSTANT VARCHAR2(30) := 'ACTIVE';
   GC_NOTIFY_FLAG              CONSTANT VARCHAR2(1)  := 'Y';
   GD_DEFAULT_GROUP_START_DATE CONSTANT DATE         := TO_DATE('01-JAN-1980'); 
   GC_PROXY_ROLE               CONSTANT VARCHAR2(10) := 'PRXY';

   -- ---------------------------
   -- Global Variable Declaration
   -- ---------------------------

   gn_person_id                NUMBER                                                      ;
   gd_as_of_date               DATE                                                        ;
   gc_debug_flag               VARCHAR2(1) := FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG')     ;
   gc_write_debug_to_log       CHAR(1);
   gc_errbuf                   VARCHAR2(2000)                                              ;
   gn_biz_grp_id               NUMBER      := FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID')   ;
   gc_employee_number          per_all_people_f.employee_number%TYPE := NULL               ;
   gc_full_name                per_all_people_f.full_name%TYPE       := NULL               ;
   gc_email_address            per_all_people_f.email_address%TYPE   := NULL               ;
   gn_resource_id              jtf_rs_resource_extns_vl.resource_id%TYPE                   ;
   gc_resource_number          jtf_rs_resource_extns_vl.resource_number%TYPE               ;
   gd_resource_start_date      jtf_rs_resource_extns_vl.start_date_active%TYPE             ;
   gd_resource_end_date        jtf_rs_resource_extns_vl.end_date_active%TYPE               ;
   gn_res_obj_ver_number       jtf_rs_resource_extns_vl.object_version_number%TYPE         ;
   gn_job_id                   per_all_assignments_f.job_id%TYPE                           ;
   gd_job_asgn_date            DATE                                                        ;
   gd_mgr_asgn_date            DATE                                                        ;
   gd_crm_job_asgn_date        DATE                                                        ;
   gd_crm_mgr_asgn_date        DATE                                                        ;
   gn_sales_credit_type_id     OE_SALES_CREDIT_TYPES.sales_credit_type_id%TYPE;
   gd_golive_date              DATE     := FND_PROFILE.VALUE('XX_CRM_GO_LIVE_DATE_R1') ;  -- Added on 17/12/07
   gc_sales_rep_res            VARCHAR2(1) := 'N';-- 20/12/07
   gc_mgr_matches_flag         VARCHAR2(1) ;-- 22/12/07
   --gc_resource_exists          VARCHAR2(1) ;-- 22/12/07 -- Commented on 25/06/08
   gc_resource_exists          VARCHAR2(1) ;-- Added on 25/06/08
   gd_minimal_date             DATE := TO_DATE('01-01-4712 BC','DD-MM-RRRR BC');
   gc_job_chng_exists          VARCHAR2(1);-- 28/02/08
   gc_back_date_exists         VARCHAR2(1) := 'N';-- 29/02/08
   gc_future_date_exists       VARCHAR2(1) := 'N';-- 29/02/08
   gc_return_status            VARCHAR2(10)                                                ;
   -- This shall have the values a. SUCCESS,
   --                            b. ERROR,
   --                            c. WARNING


   gc_conc_prg_id              NUMBER                    DEFAULT   -1                      ;
   --gn_role_id                  JTF_RS_ROLE_RELATIONS.role_id%TYPE                          ;-- 03/01/08
   gc_err_msg                  CLOB;--08/01/08

   -- 18/01/08
   gn_msg_cnt_get               NUMBER;
   gn_msg_cnt                   NUMBER;
   gc_msg_data                  CLOB;
   
   gc_resource_type             VARCHAR2(20);-- 02/07/08   
   gc_supervisor_name           VARCHAR2(250);-- 03/07/08
   gn_supervisor_id             PLS_INTEGER ; -- 03/07/08
   gc_hierarchy_type            VARCHAR2(20);-- 24/07/08 
   gn_sales_admin_grp_id        NUMBER;  


   /*-- ---------------------------
   -- Global Cursor Declaration
   -- ---------------------------
   -- Moved from ASSIGN_ROLE procedure on 3-Dec-07
   -- Added on 20/12/07
   -- ----------------------------------------------------------------------
   -- Cursor to check whether the resource is getting fresh sales comp role
   -- ----------------------------------------------------------------------

   CURSOR lcu_chk_role
   IS
   SELECT role_id
   FROM   jtf_rs_role_relations_vl JRRRV
   WHERE  role_resource_id      = gn_resource_id
   AND    JRRRV.role_type_code  = 'SALES_COMP'
   /*AND     gd_job_asgn_date  -- gd_as_of_date
           BETWEEN start_date_active
           AND     NVL(end_date_active,gd_job_asgn_date);
   AND    end_date_active  IS NOT NULL ; -- 03/01/08

   -- Added on 20/12/07
   */

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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.WRITE_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.WRITE_LOG'
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.WRITE_OUT'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.WRITE_OUT'
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
                WRITE_LOG('DEBUG_MESG_WRITE:'||p_message);-- 11/Dec/07
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.DEBUG_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.DEBUG_LOG'
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
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ; -- 08/07/08
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;


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
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      ln_default_org_id   NUMBER;
      --lc_return_status    VARCHAR2(1);
      lc_return_status    VARCHAR2(10);
      ln_salesrep_id      jtf_rs_resource_extns.resource_id%TYPE;
      ln_cnt              NUMBER ;
      lc_return_mesg      VARCHAR2(5000);
      v_data              VARCHAR2(5000);

     /* -- -------------------------------------
      -- Cursor to get org_id
      -- -------------------------------------
      CURSOR   lcu_get_org_id
      IS
      SELECT   HOU.organization_id  org_id
      FROM     hr_operating_units HOU
              ,fnd_lookup_values FLV
      WHERE    HOU.date_to IS NULL      -- 11/Dec/07
      AND      FLV.lookup_type = 'OD_OPERATING_UNIT'
      AND      FLV.end_date_active IS NULL -- 08/Dec/07
      AND      HOU.name        = FLV.lookup_code
      AND      HOU.organization_id NOT IN  (
                                             SELECT  org_id
                                             FROM    jtf_rs_salesreps
                                             WHERE   resource_id = p_resource_id
                                           );
    */
      -- -------------------------------------
      -- Cursor to get org_id -- 11/Dec/07
      -- -------------------------------------

      CURSOR   lcu_get_org_id
      IS
      SELECT    HOU.organization_id  org_id
      FROM      hr_operating_units HOU
               ,(SELECT   *
                 FROM    fnd_lookup_values F
                 WHERE   F.lookup_type = 'OD_OPERATING_UNIT'
                 AND     F.end_date_active IS NULL -- 08/Dec/07
                 AND EXISTS (select name from hr_operating_units)) FLV
      WHERE      HOU.date_to IS NULL      -- 11/Dec/07
      AND        HOU.name        = FLV.lookup_code
      AND        HOU.organization_id NOT IN  (
                                              SELECT  org_id
                                              FROM    jtf_rs_salesreps
                                              WHERE   resource_id = p_resource_id
                                              );

      CURSOR  lcu_check_salesrep(ln_org_id  NUMBER)
      IS
      SELECT 'Y' salesrep_flag
             ,salesrep_id
             ,sales_credit_type_id
             ,object_version_number
      FROM    jtf_rs_salesreps
      WHERE   resource_id = gn_resource_id
      AND     org_id      = ln_org_id;

      lr_salesrep                  lcu_check_salesrep%ROWTYPE;


   BEGIN

     DEBUG_LOG('Inside Proc: CREATE_SALES_REP');

     ln_default_org_id  := fnd_profile.value('ORG_ID');

     FOR get_org_rec IN lcu_get_org_id
     LOOP

         dbms_application_info.set_client_info(get_org_rec.org_id);

         lr_salesrep  := NULL;

         IF lcu_check_salesrep%ISOPEN THEN
            CLOSE lcu_check_salesrep;
         END IF;

         OPEN  lcu_check_salesrep(get_org_rec.org_id);
         FETCH lcu_check_salesrep INTO lr_salesrep;
         CLOSE lcu_check_salesrep;

         IF (NVL(lr_salesrep.salesrep_flag,'N') <> 'Y') THEN

            -- 18/01/08
            FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                       p_data  => gc_msg_data
                                       );

            IF gn_msg_cnt_get = 0 THEN
               gn_msg_cnt := 1;
            END IF;
            -- 18/01/08

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
                       , x_salesrep_id          => ln_salesrep_id
                       );


            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

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

            END IF;

         ELSE
            -- 18/01/08
            FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                       p_data  => gc_msg_data
                                       );

            IF gn_msg_cnt_get = 0 THEN
               gn_msg_cnt := 1;
            END IF;
            -- 18/01/08

            JTF_RS_SALESREPS_PUB.update_salesrep
                             ( P_API_VERSION           => 1.0,
                               P_SALESREP_ID           => lr_salesrep.salesrep_id,
                               P_END_DATE_ACTIVE       => NULL,
                               P_ORG_ID                => get_org_rec.org_id,
                               P_SALES_CREDIT_TYPE_ID  => lr_salesrep.sales_credit_type_id,
                               P_OBJECT_VERSION_NUMBER => lr_salesrep.object_version_number,
                               X_RETURN_STATUS         => lc_return_status,
                               X_MSG_COUNT             => x_msg_count,
                               X_MSG_DATA              => x_msg_data
                             );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               -- 18/01/08
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
               -- 18/01/08

            END IF;

         END IF;
         x_return_status := lc_return_status;

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

   -- +===================================================================+
   -- | Name  : REINSTATE_SALESREP                                        |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    reinstate of sales reps in all OU's.           |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE REINSTATE_SALESREP
                    ( P_RESOURCE_ID          IN  JTF_RS_RESOURCE_EXTNS_VL.resource_id%TYPE,
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
      AND     gd_job_asgn_date
              BETWEEN   start_date_active
              AND       NVL(end_date_active,gd_job_asgn_date+1);

   BEGIN

      DEBUG_LOG('Inside Proc: REINSTATE_SALESREP');

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
                               P_END_DATE_ACTIVE       => NULL,
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

         DEBUG_LOG('No Salesreps attached to Resource ID: '||P_RESOURCE_ID ||' on date: '|| gd_job_asgn_date);
      ELSE

         DEBUG_LOG('Salesreps Reinstated.');
      END IF;

     IF x_return_status <> FND_API.G_RET_STS_ERROR OR x_return_status <> FND_API.G_RET_STS_UNEXP_ERROR THEN

        x_return_status := FND_API.G_RET_STS_SUCCESS;
     END IF;

   END REINSTATE_SALESREP;


   -- +===================================================================+
   -- | Name  : BACKDATE_SALESREP                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    backdate of sales reps in all OU's.            |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE BACKDATE_SALESREP
                    ( P_RESOURCE_ID           IN JTF_RS_RESOURCE_EXTNS_VL.resource_id%TYPE,
                      P_START_DATE_ACTIVE     IN JTF_RS_SALESREPS.start_date_active%TYPE,
                      X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
                      X_MSG_COUNT            OUT NOCOPY  NUMBER,
                      X_MSG_DATA             OUT NOCOPY  VARCHAR2
                    )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lc_salesrep_exist_flag  VARCHAR2(1) := 'N';
      lc_return_status        VARCHAR2(1) ;
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


      CURSOR  lcu_get_salesreps
      IS
      SELECT  salesrep_id
             ,sales_credit_type_id
             ,object_version_number
             ,org_id
             ,end_date_active
      FROM    jtf_rs_salesreps
      WHERE   resource_id = p_resource_id
      AND     TRUNC(start_date_active)  > TRUNC(p_start_date_active);



   BEGIN

      DEBUG_LOG('Inside Proc: BACKDATE_SALESREP');

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
                               P_START_DATE_ACTIVE     => p_start_date_active,
                               P_END_DATE_ACTIVE       => NULL,
                               P_ORG_ID                => get_salesrep_rec.org_id,
                               P_SALES_CREDIT_TYPE_ID  => get_salesrep_rec.sales_credit_type_id,
                               P_OBJECT_VERSION_NUMBER => get_salesrep_rec.object_version_number,
                               X_RETURN_STATUS         => lc_return_status,
                               X_MSG_COUNT             => x_msg_count,
                               X_MSG_DATA              => x_msg_data
                             );

            IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
            THEN

               gc_return_status    := 'ERROR';

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

                  x_return_status  := lc_return_status;

               END IF;

            END IF;

      END LOOP;

      IF lc_salesrep_exist_flag = 'Y' THEN

         DEBUG_LOG('Salesreps Back dated.');

      END IF;

     IF x_return_status <> FND_API.G_RET_STS_ERROR OR x_return_status <> FND_API.G_RET_STS_UNEXP_ERROR THEN

        x_return_status := FND_API.G_RET_STS_SUCCESS;

     END IF;

   END BACKDATE_SALESREP;

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
                 , p_attribute14        IN  jtf_rs_role_relations.attribute14%TYPE-- Added 16/12/07          -- 08/01/08
                 --, p_attribute15        IN  jtf_rs_role_relations.attribute15%TYPE-- Added 28/12/07        -- 08/01/08
                 --, p_attribute_category IN  jtf_rs_role_relations.attribute_category%type-- Added 21/12/07 -- 08/01/08
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 , x_role_relate_id     OUT NOCOPY  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
                 )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      lr_role_relate_rec JTF_RS_ROLE_RELATIONS%ROWTYPE;
      ln_cnt             NUMBER ;
      lc_return_mesg     VARCHAR2(5000);
      v_data             VARCHAR2(5000);

      CURSOR lcu_chk_grp_rol_exists IS 
      SELECT *
      FROM   jtf_rs_role_relations
      WHERE  role_resource_type  = p_role_resource_type
      AND    role_resource_id    = p_role_resource_id
      AND    role_id             = p_role_id
      AND    delete_flag         = 'N'
      AND    NVL(end_date_active, p_start_date_active+1) >= p_start_date_active
      ORDER BY start_date_active;

   BEGIN

      DEBUG_LOG('Inside Proc: ASSIGN_ROLE_TO_RESOURCE');

      OPEN   lcu_chk_grp_rol_exists;
      FETCH  lcu_chk_grp_rol_exists INTO lr_role_relate_rec;
      CLOSE  lcu_chk_grp_rol_exists;


      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      IF lr_role_relate_rec.role_relate_id IS NOT NULL THEN
        DEBUG_LOG('Before Update Resource Role Relate ID: ' || lr_role_relate_rec.role_relate_id);
        XX_JTF_RS_ROLE_RELATE_PUB.Update_Resource_Role_Relate 
                    (
                      p_api_version               => p_api_version
                    , p_commit                    => p_commit
                    , p_role_relate_id            => lr_role_relate_rec.role_relate_id
                    , p_start_date_active         => LEAST(p_start_date_active, lr_role_relate_rec.start_date_active)
                    , p_object_version_num        => lr_role_relate_rec.object_version_number
                    , p_attribute14               => p_attribute14   
                    , x_return_status             => x_return_status
                    , x_msg_count                 => x_msg_count
                    , x_msg_data                  => x_msg_data
                    );

      ELSE
        DEBUG_LOG('Before Create Resource Role Relate Record');
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
      END IF;

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
            gc_err_msg := gc_err_msg|| ' * ' ||lc_return_mesg ; -- 08/07/08
         ELSE
            gc_err_msg := lc_return_mesg ;
         END IF;

         gn_msg_cnt := x_msg_count + 1;

      END IF;


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
                   p_api_version         IN  NUMBER
                 , p_commit              IN  VARCHAR2
                 , p_group_name          IN  jtf_rs_groups_vl.group_name%TYPE
                 , p_group_desc          IN  jtf_rs_groups_vl.group_desc%TYPE       DEFAULT  NULL
                 , p_exclusive_flag      IN  jtf_rs_groups_vl.exclusive_flag%TYPE   DEFAULT  'N'
                 , p_email_address       IN  jtf_rs_groups_vl.email_address%TYPE    DEFAULT  NULL
                 , p_start_date_active   IN  jtf_rs_groups_vl.start_date_active%TYPE
                 , p_end_date_active     IN  jtf_rs_groups_vl.end_date_active%TYPE  DEFAULT  NULL
                 , p_accounting_code     IN  jtf_rs_groups_vl.accounting_code%TYPE  DEFAULT  NULL
                 --Added on 13/03/08(Name mismatch problem)
                 , p_attribute1         IN  jtf_rs_groups_vl.attribute1%TYPE DEFAULT  NULL
                 , p_attribute2         IN  jtf_rs_groups_vl.attribute2%TYPE DEFAULT  NULL
                 , p_attribute3         IN  jtf_rs_groups_vl.attribute3%TYPE DEFAULT  NULL
                 , p_attribute4         IN  jtf_rs_groups_vl.attribute4%TYPE DEFAULT  NULL
                 , p_attribute5         IN  jtf_rs_groups_vl.attribute5%TYPE DEFAULT  NULL
                 , p_attribute6         IN  jtf_rs_groups_vl.attribute6%TYPE DEFAULT  NULL
                 , p_attribute7         IN  jtf_rs_groups_vl.attribute7%TYPE DEFAULT  NULL
                 , p_attribute8         IN  jtf_rs_groups_vl.attribute8%TYPE DEFAULT  NULL
                 , p_attribute9         IN  jtf_rs_groups_vl.attribute9%TYPE DEFAULT  NULL
                 , p_attribute10        IN  jtf_rs_groups_vl.attribute10%TYPE DEFAULT  NULL
                 , p_attribute11        IN  jtf_rs_groups_vl.attribute11%TYPE DEFAULT  NULL
                 , p_attribute12        IN  jtf_rs_groups_vl.attribute12%TYPE DEFAULT  NULL
                 , p_attribute13        IN  jtf_rs_groups_vl.attribute13%TYPE DEFAULT  NULL
                 , p_attribute14        IN  jtf_rs_groups_vl.attribute14%TYPE DEFAULT  NULL
                 , p_attribute15        IN  jtf_rs_groups_vl.attribute15%TYPE DEFAULT  NULL
                 , p_attribute_category IN  jtf_rs_groups_vl.attribute_category%TYPE DEFAULT  NULL
                 --Added on 13/03/08(Name mismatch problem)
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 , x_group_id           OUT NOCOPY  jtf_rs_groups_vl.group_id%TYPE
                 , x_group_number       OUT NOCOPY  jtf_rs_groups_vl.group_number%TYPE
                 )
   IS
     -- --------------------------
     -- Local Variable Declaration
     -- --------------------------

     ln_cnt           NUMBER ;
     lc_return_mesg   VARCHAR2(5000);
     v_data           VARCHAR2(5000);

   BEGIN

       DEBUG_LOG('Inside Proc: CREATE_GROUP');
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
       /*Commented on 13/03/08(Name mismatch problem)
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
      */
       XX_JTF_RS_GROUPS_PUB.create_resource_group
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
                     --Added on 13/03/08(Name mismatch problem)
                     , p_attribute15       => p_attribute15
                     --Added on 13/03/08(Name mismatch problem)
                     , x_return_status     => x_return_status
                     , x_msg_count         => x_msg_count
                     , x_msg_data          => x_msg_data
                     , x_group_id          => x_group_id
                     , x_group_number      => x_group_number
                     );
       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08
       END IF;

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
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

   BEGIN

       DEBUG_LOG('Inside Proc: ASSIGN_RES_TO_GRP');
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

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

       END IF;

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
      lr_role_relate_rec      JTF_RS_ROLE_RELATIONS%ROWTYPE;
      lc_grp_role_exst_flag   VARCHAR2(1); -- 27/06/08
      
      /*
      -- Commented on 27/06/08
      CURSOR lcu_get_role_code
      IS
      SELECT JRV.role_code
      FROM   jtf_rs_roles_vl JRV,
             fnd_lookups     LOOKUP
      WHERE  JRV.role_type_code  = LOOKUP.lookup_code
      AND    JRV.role_id         = p_role_id
      AND    LOOKUP.lookup_type  ='JTF_RS_ROLE_TYPE'
      AND    LOOKUP.enabled_flag ='Y';
      */
      
      -- Added on 27/06/08
      CURSOR lcu_chk_grp_rol_exists
      IS      
      SELECT *
      FROM   jtf_rs_role_relations
      WHERE  role_resource_type  ='RS_GROUP'
      AND    role_resource_id    = p_role_resource_id
      AND    role_id             = p_role_id
      AND    delete_flag         = 'N'
      AND    NVL(end_date_active, p_start_date+1) >= p_start_date
      ORDER BY start_date_active;
   -- AND    p_start_date BETWEEN start_date_active AND NVL(end_date_active, p_start_date+1);     
      
      -- Added on 27/06/08

   BEGIN
      DEBUG_LOG('Inside Proc: ASSIGN_ROLE_TO_GROUP');

      -- Added on 27/06/08
      OPEN   lcu_chk_grp_rol_exists;
      FETCH  lcu_chk_grp_rol_exists INTO lr_role_relate_rec;
      CLOSE  lcu_chk_grp_rol_exists;

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                );

      IF gn_msg_cnt_get = 0 THEN
        gn_msg_cnt := 1;
      END IF;
                  
      IF lr_role_relate_rec.role_relate_id IS NOT NULL THEN       
         DEBUG_LOG('Before Update Role Relate ID : ' || lr_role_relate_rec.role_relate_id);
         JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
           (p_api_version          =>  1.0,
            p_init_msg_list        =>  FND_API.G_FALSE,
            p_commit               =>  FND_API.G_FALSE,
            p_role_relate_id       =>  lr_role_relate_rec.role_relate_id,
            p_start_date_active    =>  LEAST(lr_role_relate_rec.start_date_active, p_start_date),
            p_object_version_num   =>  lr_role_relate_rec.object_version_number,
            x_return_status        =>  x_return_status ,
            x_msg_count            =>  x_msg_count     ,
            x_msg_data             =>  x_msg_data      
           );
      ELSE
         DEBUG_LOG('Before Create Resource Role Relation');
         JTF_RS_ROLE_RELATE_PUB.create_resource_role_relate
           (p_api_version          =>  1.0,
            p_init_msg_list        =>  FND_API.G_FALSE,
            p_commit               =>  FND_API.G_FALSE,
            p_role_resource_type   =>  lc_role_resource_type,
            p_role_resource_id     =>  p_role_resource_id,
            p_role_id              =>  p_role_id,
            p_role_code            =>  lc_role_code,
            p_start_date_active    =>  p_start_date,
          --p_end_date_active      =>  ln_end_date_active,
            x_return_status        =>  x_return_status ,
            x_msg_count            =>  x_msg_count     ,
            x_msg_data             =>  x_msg_data      ,
            x_role_relate_id       =>  ln_role_relate_id
            );
      END IF;  

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        DEBUG_LOG('In Procedure:ASSIGN_ROLE_TO_GROUP: Proc: JTF_RS_ROLE_RELATE_PUB.create_resource_role_relate Fails for role id: '||p_role_id);

        -- 18/01/08
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
        -- 18/01/08

      ELSE
        DEBUG_LOG('In Procedure:ASSIGN_ROLE_TO_GROUP: Proc: JTF_RS_ROLE_RELATE_PUB.create_resource_role_relate Success for role id: '||p_role_id);
      END IF;      

  EXCEPTION

     WHEN OTHERS THEN

       gc_return_status  := 'ERROR';
       x_return_status   := FND_API.G_RET_STS_ERROR;

       x_msg_data := SQLERRM;

       WRITE_LOG(x_msg_data);

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
       gc_errbuf := FND_MESSAGE.GET;

       IF gc_err_msg IS NOT NULL THEN
          gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
       ELSE
          gc_err_msg := gc_errbuf;
       END IF;

       XX_COM_ERROR_LOG_PUB.log_error_crm(
                              p_return_code             => x_return_status
                             ,p_msg_count               => 1
                             ,p_application_name        => GC_APPN_NAME
                             ,p_program_type            => GC_PROGRAM_TYPE
                             ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE_TO_GROUP'
                             ,p_program_id              => gc_conc_prg_id
                             ,p_module_name             => GC_MODULE_NAME
                             ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE_TO_GROUP'
                             ,p_error_message_count     => 1
                             ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                             ,p_error_message           => x_msg_data
                             ,p_error_status            => GC_ERROR_STATUS
                             ,p_notify_flag             => GC_NOTIFY_FLAG
                             ,p_error_message_severity  =>'MAJOR'
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
                 -- Added on 25/02/08
                 , p_attribute14        IN  JTF_RS_ROLE_RELATIONS.ATTRIBUTE14%TYPE   DEFAULT  NULL
                 -- Added on 25/02/08
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

      -- Check for Overlapping group member roles
      CURSOR lcu_chk_grp_rol_exists IS      
      SELECT JRRR.*
      FROM   jtf_rs_group_mbr_role_vl JGMR,
             jtf_rs_role_relations    JRRR
      WHERE  JGMR.resource_id    = p_resource_id
      AND    JGMR.role_id        = p_role_id
      AND    JGMR.group_id       = p_group_id
      AND    NVL(JGMR.end_date_active, p_start_date+1) >= p_start_date
      AND    JRRR.role_relate_id = JGMR.role_relate_id
      ORDER BY JGMR.start_date_active;

      lr_group_mbr_role lcu_chk_grp_rol_exists%ROWTYPE;

   BEGIN

      DEBUG_LOG('Inside Proc: ASSIGN_RES_TO_GROUP_ROLE');

      OPEN   lcu_chk_grp_rol_exists;
      FETCH  lcu_chk_grp_rol_exists INTO lr_group_mbr_role;
      CLOSE  lcu_chk_grp_rol_exists;

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      -- If there is record then update it else insert a new record
      IF lr_group_mbr_role.role_relate_id IS NOT NULL THEN
        DEBUG_LOG('Before Update Create Group Member Role with role relate id = ' || lr_group_mbr_role.role_relate_id);
        XX_JTF_RS_GRP_MEMBERSHIP_PUB.update_group_membership
               (
                 p_api_version        => p_api_version
               , p_commit             => p_commit
               , p_resource_id        => p_resource_id
               , p_role_id            => p_role_id
               , p_role_relate_id     => lr_group_mbr_role.role_relate_id
               , p_start_date         => LEAST(lr_group_mbr_role.start_date_active, p_start_date)
               , p_end_date           => GREATEST(lr_group_mbr_role.end_date_active, p_end_date)
               , p_object_version_num => lr_group_mbr_role.object_version_number
               , x_return_status      => x_return_status
               , x_msg_count          => x_msg_count
               , x_msg_data           => x_msg_data
               );
      ELSE
        DEBUG_LOG('Before Create Group Member Role');
        XX_JTF_RS_GRP_MEMBERSHIP_PUB.create_group_membership
               (
                 p_api_version        => p_api_version
               , p_commit             => p_commit
               , p_resource_id        => p_resource_id
               , p_group_id           => p_group_id
               , p_role_id            => p_role_id
               , p_start_date         => p_start_date
               , p_end_date           => p_end_date
               -- Added on 25/02/08
               , p_attribute14        => p_attribute14
               -- Added on 25/02/08
               , x_return_status      => x_return_status
               , x_msg_count          => x_msg_count
               , x_msg_data           => x_msg_data
               );

      END IF;
      
      
      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08

      END IF;

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
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_cnt           NUMBER ;
      lc_return_mesg   VARCHAR2(5000);
      v_data           VARCHAR2(5000);

   BEGIN

       DEBUG_LOG('Inside Proc: ASSIGN_TO_PARENT_GROUP');

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

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08
       END IF;

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
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------

      ln_group_usage_id  NUMBER;
      lc_return_status   VARCHAR2(1);
      lc_error_message   VARCHAR2(1000);
      ln_cnt             NUMBER ;
      lc_return_mesg     VARCHAR2(5000);
      v_data             VARCHAR2(5000);


      CURSOR lcu_get_group_usages
      IS
      SELECT lookup_code
      FROM   fnd_lookups
      WHERE  lookup_type = 'JTF_RS_USAGE'
      AND    lookup_code in ('SALES','SALES_COMP','SF_PLANNING','IEX_COLLECTIONS')
      AND    TRUNC(NVL(end_date_active,gd_job_asgn_date)) -- gd_as_of_date))
       >=    TRUNC(gd_job_asgn_date) -- gd_as_of_date)
      AND    enabled_flag = 'Y'
      AND    lookup_code NOT IN
                               (SELECT  lookup_code
                                FROM    jtf_rs_group_usages
                                WHERE   group_id  = p_group_id
                               );

   BEGIN
      DEBUG_LOG('Inside Proc: CREATE_GROUP_USAGE');

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      FOR  group_usage_rec IN lcu_get_group_usages
      LOOP

        jtf_rs_group_usages_pub.create_group_usage
              (P_API_VERSION          => 1.0,
               P_INIT_MSG_LIST        => FND_API.G_FALSE,
               P_COMMIT               => FND_API.G_FALSE, -- Changed on 01/14/2008 for avoiding half-commits from 'T',
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

            -- 18/01/08
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
            -- 18/01/08

            IF NVL(gc_return_status,'A') <> 'ERROR'  THEN

               gc_return_status   := 'WARNING';

            END IF;

         END IF;

      END LOOP;

      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION
     WHEN OTHERS THEN
      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.CREATE_GROUP_USAGE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.CREATE_GROUP_USAGE'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );
   END CREATE_GROUP_USAGE;

   -- +===================================================================+
   -- | Name  : BACKDATE_PARENT_GROUP                                     |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    backdate the Parent-Child hierarchy between the|
   -- |                    groups.                                        |
   -- +===================================================================+


   PROCEDURE BACKDATE_PARENT_GROUP
                 ( p_group_relate_id      IN   jtf_rs_grp_relations.group_relate_id%TYPE
                 , p_start_date_active    IN   jtf_rs_grp_relations.end_date_active%TYPE
                 , p_object_version_num   IN   jtf_rs_grp_relations.object_version_number%TYPE
                 , x_return_status        OUT NOCOPY  VARCHAR2
                 , x_msg_count            OUT NOCOPY  NUMBER
                 , x_msg_data             OUT NOCOPY  VARCHAR2
                 )
   IS
     -- --------------------------
     -- Local Variable Declaration
     -- --------------------------

      lc_object_version_num   NUMBER;
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


   BEGIN
      DEBUG_LOG('Inside Proc: BACKDATE_PARENT_GROUP');
      lc_object_version_num  :=  p_object_version_num;

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      JTF_RS_GROUP_RELATE_PUB.update_resource_group_relate
                    (
                      p_api_version          => 1.0
                    , p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_group_relate_id      => p_group_relate_id
                    , p_start_date_active    => p_start_date_active
                    , p_end_date_active      => NULL
                    , p_object_version_num   => lc_object_version_num
                    , x_return_status        => x_return_status
                    , x_msg_count            => x_msg_count
                    , x_msg_data             => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08
      END IF;

   END BACKDATE_PARENT_GROUP;


   -- +===================================================================+
   -- | Name  : DELETE_OFF_PARENT_GROUP                                   |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    deleting the Parent-Child hierarchy between a  |
   -- |                    sales groups and seeded group with GID = -1.   |
   -- +===================================================================+


   PROCEDURE DELETE_OFF_PARENT_GROUP
                 (
                   p_group_relate_id      IN   jtf_rs_grp_relations.group_relate_id%TYPE
                 , p_object_version_num   IN   jtf_rs_grp_relations.object_version_number%TYPE
                 , x_return_status        OUT NOCOPY  VARCHAR2
                 , x_msg_count            OUT NOCOPY  NUMBER
                 , x_msg_data             OUT NOCOPY  VARCHAR2
                 )
   IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version_num   NUMBER;
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


   BEGIN

      DEBUG_LOG('Inside Proc: DELETE_OFF_PARENT_GROUP');
      lc_object_version_num  :=  p_object_version_num;

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      JTF_RS_GROUP_RELATE_PUB.delete_resource_group_relate
                    (
                      p_api_version          => 1.0
                    , p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_group_relate_id      => p_group_relate_id
                    , p_object_version_num   => lc_object_version_num
                    , x_return_status        => x_return_status
                    , x_msg_count            => x_msg_count
                    , x_msg_data             => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08
      END IF;

   END DELETE_OFF_PARENT_GROUP;


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

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version_num   NUMBER;
      ln_cnt                  NUMBER ;
      lc_return_mesg          VARCHAR2(5000);
      v_data                  VARCHAR2(5000);


   BEGIN

      DEBUG_LOG('Inside Proc: ENDDATE_OFF_PARENT_GROUP');
      lc_object_version_num  :=  p_object_version_num;

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      JTF_RS_GROUP_RELATE_PUB.update_resource_group_relate
                    (
                      p_api_version          => 1.0
                    , p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_group_relate_id      => p_group_relate_id
                    , p_end_date_active      => p_end_date_active
                    , p_object_version_num   => lc_object_version_num
                    , x_return_status        => x_return_status
                    , x_msg_count            => x_msg_count
                    , x_msg_data             => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08
      END IF;

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

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

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

         -- 18/01/08
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
         -- 18/01/08

      END IF;

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
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version        NUMBER;
      ln_cnt                   NUMBER ;
      lc_return_mesg           VARCHAR2(5000);
      v_data                   VARCHAR2(5000);


   BEGIN
       DEBUG_LOG('Inside Proc: ENDDATE_GROUP');
       lc_object_version  :=  p_object_version_num;

       -- 18/01/08
       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;
       -- 18/01/08

       JTF_RS_GROUPS_PUB.update_resource_group
                       (P_API_VERSION          => 1.0,
                        P_GROUP_ID             => p_group_id,
                        P_GROUP_NUMBER         => p_group_number,
                        P_END_DATE_ACTIVE      => p_end_date,
                        P_OBJECT_VERSION_NUM   => lc_object_version,
                        X_RETURN_STATUS        => x_return_status,
                        X_MSG_COUNT            => x_msg_count,
                        X_MSG_DATA             => x_msg_data
                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08
       END IF;

   END ENDDATE_GROUP;


   -- +===================================================================+
   -- | Name  : GROUP_BACK_DATE                                           |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    change the group start date to job asgn date   |
   -- |                    and end date to NULL.                          |
   -- +===================================================================+


   PROCEDURE  GROUP_BACK_DATE
                  (p_group_id           IN  JTF_RS_GROUPS_VL.group_id%TYPE,
                   p_group_number       IN  JTF_RS_GROUPS_VL.group_number%TYPE,
                   p_start_date         IN  JTF_RS_GROUPS_VL.end_date_active%TYPE,
                   p_object_version_num IN  NUMBER,
                   x_return_status      OUT NOCOPY  VARCHAR2,
                   x_msg_count          OUT NOCOPY  NUMBER,
                   x_msg_data           OUT NOCOPY  VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version        NUMBER;
      ln_cnt                   NUMBER ;
      lc_return_mesg           VARCHAR2(5000);
      v_data                   VARCHAR2(5000);


   BEGIN

       DEBUG_LOG('Inside Proc: GROUP_BACK_DATE');
       lc_object_version  :=  p_object_version_num;

       -- 18/01/08
       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;
       -- 18/01/08

       JTF_RS_GROUPS_PUB.update_resource_group
                       (P_API_VERSION          => 1.0,
                        P_GROUP_ID             => p_group_id,
                        P_GROUP_NUMBER         => p_group_number,
                        P_START_DATE_ACTIVE    => p_start_date,
                        P_END_DATE_ACTIVE      => NULL,
                        P_OBJECT_VERSION_NUM   => lc_object_version,
                        X_RETURN_STATUS        => x_return_status,
                        X_MSG_COUNT            => x_msg_count,
                        X_MSG_DATA             => x_msg_data
                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

       END IF;


   END GROUP_BACK_DATE;

   -- +===================================================================+
   -- | Name  : UPDATE_GROUP_NAME                                         |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    change the group name if the group owner's     |
   -- |                    name changes because of marriage, divorce etc. |
   -- +===================================================================+


   PROCEDURE  UPDATE_GROUP_NAME
                  (p_group_id           IN  JTF_RS_GROUPS_VL.group_id%TYPE,
                   p_group_number       IN  JTF_RS_GROUPS_VL.group_number%TYPE,
                   p_group_name         IN  JTF_RS_GROUPS_VL.group_name%TYPE,
                   p_group_desc         IN  JTF_RS_GROUPS_VL.group_desc%TYPE,
                   p_object_version_num IN  NUMBER,
                   x_return_status      OUT NOCOPY  VARCHAR2,
                   x_msg_count          OUT NOCOPY  NUMBER,
                   x_msg_data           OUT NOCOPY  VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      lc_object_version        NUMBER;
      ln_cnt                   NUMBER ;
      lc_return_mesg           VARCHAR2(5000);
      v_data                   VARCHAR2(5000);


   BEGIN

       DEBUG_LOG('Inside Proc: UPDATE_GROUP_NAME');
       lc_object_version  :=  p_object_version_num;

       -- 18/01/08
       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;
       -- 18/01/08

       JTF_RS_GROUPS_PUB.update_resource_group
                       (P_API_VERSION          => 1.0,
                        P_GROUP_ID             => p_group_id,
                        P_GROUP_NUMBER         => p_group_number,
                        P_GROUP_NAME           => p_group_name,
                        P_GROUP_DESC           => p_group_desc,
                        P_OBJECT_VERSION_NUM   => lc_object_version,
                        X_RETURN_STATUS        => x_return_status,
                        X_MSG_COUNT            => x_msg_count,
                        X_MSG_DATA             => x_msg_data
                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

       END IF;


   END UPDATE_GROUP_NAME;

   -- +===================================================================+
   -- | Name  : DELETE_ROLE_RELATE                                        |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    delete role relationship.                      |
   -- +===================================================================+

   PROCEDURE DELETE_ROLE_RELATE(
                  P_ROLE_RELATE_ID  IN  NUMBER,
                  P_OBJECT_VERSION  IN  NUMBER,
                  X_RETURN_STATUS   OUT VARCHAR2,
                  X_MSG_COUNT       OUT NUMBER,
                  X_MSG_DATA        OUT VARCHAR2
                  )
   IS
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      ln_cnt                       NUMBER ;
      lc_return_mesg               VARCHAR2(5000);
      v_data                       VARCHAR2(5000);

   BEGIN

      DEBUG_LOG('Inside Proc: DELETE_ROLE_RELATE');

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;

      JTF_RS_ROLE_RELATE_PUB.delete_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_OBJECT_VERSION_NUM  => p_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
        );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08

      END IF;

   END DELETE_ROLE_RELATE;


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

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

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

         -- 18/01/08
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
         -- 18/01/08

      END IF;

   END ENDDATE_RES_ROLE;

   -- +===================================================================+
   -- | Name  : BACKDATE_RES_GRP_ROLE                                     |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API for|
   -- |                    backdate the role assigned to the group member |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE BACKDATE_RES_GRP_ROLE(
                  P_ROLE_RELATE_ID    IN  NUMBER,
                  P_START_DATE_ACTIVE IN  DATE,
                  P_OBJECT_VERSION    IN  NUMBER,
                  P_ATTRIBUTE14       IN  jtf_rs_role_relations.attribute14%TYPE,-- Added on 18/12/07 -- 08/01/08
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

      DEBUG_LOG('Inside Proc: BACKDATE_RES_GRP_ROLE');
      lc_object_version :=  p_object_version;

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      /*25/02/08
      JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_START_DATE_ACTIVE   => p_start_date_active,
         P_OBJECT_VERSION_NUM  => lc_object_version,
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
        );
       25/02/08
      */
      --Added 25/02/08
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
      --Added 25/02/08

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08

      END IF;

   END BACKDATE_RES_GRP_ROLE;


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
                  P_ATTRIBUTE14       IN  jtf_rs_role_relations.attribute14%TYPE,-- Added on 18/12/07 -- 08/01/08
                  --P_ATTRIBUTE15       IN  jtf_rs_role_relations.attribute15%TYPE,-- Added on 28/12/07 -- 08/01/08
                  --P_ATTRIBUTE_CATEGORY IN  jtf_rs_role_relations.attribute_category%type,-- Added 24/12/07 -- 08/01/08
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

      -- 18/01/08
      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      -- 18/01/08

      --JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate -- Added 16/12/07
      XX_JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate -- Added 16/12/07
        (P_API_VERSION         => 1.0,
         P_ROLE_RELATE_ID      => p_role_relate_id,
         P_START_DATE_ACTIVE   => p_start_date_active,
         P_OBJECT_VERSION_NUM  => lc_object_version,
         P_ATTRIBUTE14         => p_attribute14,-- Added on 18/12/07             -- 08/01/08
         --P_ATTRIBUTE15         => p_attribute15,-- Added on 28/12/07           -- 08/01/08
         --P_ATTRIBUTE_CATEGORY  => p_attribute_category, -- Added on 24/12/07   -- 08/01/08
         X_RETURN_STATUS       => x_return_status,
         X_MSG_COUNT           => x_msg_count,
         X_MSG_DATA            => x_msg_data
        );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         -- 18/01/08
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
         -- 18/01/08

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

       JTF_RS_RESOURCE_PUB.update_resource
                    (
                      p_api_version         => 1.0
                    , p_commit              => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_init_msg_list       => fnd_api.G_FALSE
                    , p_resource_id         => p_resource_id
                    , p_resource_number     => p_resource_number
                    , p_source_name         => p_source_name
                    , p_start_date_active   => p_start_date_active
                    , p_object_version_num  => ln_object_version_num
                    --, p_attribute14         => TO_CHAR(p_start_date_active,'MM/DD/RRRR') --04/Dec/07
                    , p_attribute14         => TO_CHAR(p_start_date_active,'DD-MON-RR')
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

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

       JTF_RS_RESOURCE_PUB.update_resource
                    (
                      p_api_version         => 1.0
                    , p_commit              => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
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

          -- 18/01/08
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
          -- 18/01/08

       END IF;

   END UPDT_DATES_RESOURCE;

   -- +===================================================================+
   -- | Name  : UPDATE_RESOURCE_NAME                                      |
   -- |                                                                   |
   -- | Description:       This Procedure is a wrapper for the CRM API to |
   -- |                    update resource name.                          |
   -- |                                                                   |
   -- +===================================================================+


   PROCEDURE UPDATE_RESOURCE_NAME
                 ( p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_resource_number    IN  jtf_rs_resource_extns_vl.resource_number%TYPE
                 , p_resource_name      IN  jtf_rs_resource_extns_vl.resource_name%TYPE
                 , p_source_name        IN  jtf_rs_resource_extns_vl.source_name%TYPE
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

       DEBUG_LOG('Inside Proc: UPDATE_RESOURCE_NAME');

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

       JTF_RS_RESOURCE_PUB.update_resource
                    (
                      p_api_version         => 1.0
                    , p_commit              => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_init_msg_list       => fnd_api.G_FALSE
                    , p_resource_id         => p_resource_id
                    , p_resource_number     => p_resource_number
                    , p_resource_name       => p_resource_name
                    , p_source_name         => p_source_name
                    , p_object_version_num  => ln_object_version_num
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

       END IF;

   END UPDATE_RESOURCE_NAME;



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

       JTF_RS_RESOURCE_PUB.update_resource
                    (
                      p_api_version         => 1.0
                    , p_commit              => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                    , p_resource_id         => p_resource_id
                    , p_resource_number     => p_resource_number
                    , p_end_date_active     => p_end_date_active
                    , p_object_version_num  => ln_object_version_num
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          -- 18/01/08
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
          -- 18/01/08

       END IF;

   END ENDDATE_RESOURCE;


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
   -- |                    3. Mandatory Admin/Support Groups              |
   -- |                    4. Sales Credit type(Quota Sales Credit)       |
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
       ln_sales_credit_type_id           OE_SALES_CREDIT_TYPES.sales_credit_type_id%TYPE;
       ln_grp_id                         JTF_RS_GROUPS_VL.group_id%TYPE;
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

       -- -----------------------------
       -- Check for the group existance
       -- -----------------------------
       CURSOR lcu_check_grp_existance(p_group_name IN VARCHAR2)
       IS
       SELECT group_id
       FROM   jtf_rs_groups_vl
       WHERE  group_name = p_group_name;
       --AND    end_date_active IS NULL;-- 31/12/07

       -- ---------------------------------------
       -- Check for the salescredittype existance
       -- ---------------------------------------

       CURSOR   lcu_get_sales_credit
       IS
       SELECT   sales_credit_type_id
       FROM     oe_sales_credit_types
       WHERE    name = 'Quota Sales Credit'
       AND      enabled_flag = 'Y';


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

      -- ----------------------
      -- Group Existance check
      -- ----------------------
      IF lcu_check_grp_existance%ISOPEN THEN
         CLOSE lcu_check_grp_existance;
      END IF;

      OPEN  lcu_check_grp_existance(GC_OD_SALES_ADMIN_GRP);
      FETCH lcu_check_grp_existance INTO ln_grp_id;
         IF    lcu_check_grp_existance%NOTFOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0188_NULL_ADMIN_GRP');
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
            gn_sales_admin_grp_id := ln_grp_id;

         END IF;

      CLOSE lcu_check_grp_existance;

      OPEN  lcu_check_grp_existance(GC_OD_PAYMENT_ANALYST_GRP);
      FETCH lcu_check_grp_existance INTO ln_grp_id;
         IF    lcu_check_grp_existance%NOTFOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0189_NULL_ANALYST_GRP');
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

      CLOSE lcu_check_grp_existance;

      OPEN  lcu_check_grp_existance(GC_OD_SUPPORT_GRP);
      FETCH lcu_check_grp_existance INTO ln_grp_id;

         IF   lcu_check_grp_existance%NOTFOUND THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0190_NULL_SUPPORT_GRP');
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

      CLOSE lcu_check_grp_existance;

      IF lcu_get_sales_credit%ISOPEN THEN
         CLOSE lcu_get_sales_credit;
      END IF;

      OPEN  lcu_get_sales_credit;
      FETCH lcu_get_sales_credit INTO ln_sales_credit_type_id;
      CLOSE lcu_get_sales_credit;

      IF ln_sales_credit_type_id IS NULL THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0191_NULL_SAL_CRED_TYPE');
         lc_error_msg := FND_MESSAGE.GET;

         IF lc_concat_msg IS NOT NULL THEN
            lc_concat_msg := lc_concat_msg||CHR(10)||CHR(9)||RPAD(' ',224)||lc_error_msg;
         ELSE
            lc_concat_msg := lc_error_msg;
         END IF;

         WRITE_LOG(lc_error_msg);
         lc_term_prgm := 'N';

      ELSE
        gn_sales_credit_type_id:= ln_sales_credit_type_id;
        x_cnt := x_cnt +1;

      END IF;
      -- 04/Jan/08
      IF gd_golive_date IS NULL THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0195_GOLIVE_DATE_NULL');
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
      -- 04/Jan/08
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
                                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.VALIDATE_SETUPS'
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
           gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
        ELSE
           gc_err_msg := gc_errbuf;
        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.VALIDATE_SETUPS'
                                    ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                    ,p_error_message           => SQLERRM
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );
   END VALIDATE_SETUPS;
   -- Added on 17/12/07

    -- +===================================================================+
    -- | Name        :  GET_BONUS_DATE                                     |
    -- |                                                                   |
    -- | Description :  This procedure is used to get the Bonus Eligible   |
    -- |                date for a sales rep                               |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters  :  p_date  IN   Date                                  |
    -- |                x_date  OUT Holds the calculated Bonus date        |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE GET_BONUS_DATE (
                              p_date           IN  DATE
                             ,x_date           OUT DATE
                             )
    IS

      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
       ln_date         NUMBER;
       lc_error_msg    VARCHAR2(2000);

    BEGIN
       DEBUG_LOG('Inside Proc: GET_BONUS_DATE');

       ln_date:= TO_NUMBER(TO_CHAR(p_date,'DD'))-1;
       DEBUG_LOG(p_date);
       x_date := p_date - ln_date;
       DEBUG_LOG(x_date);
       x_date := ADD_MONTHS(x_date,3);
       DEBUG_LOG(x_date);

    EXCEPTION
       WHEN OTHERS THEN
          x_date := gd_minimal_date;

          WRITE_LOG(gd_minimal_date);

          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
          gc_errbuf := FND_MESSAGE.GET;

          WRITE_LOG(SQLERRM);

          IF gc_err_msg IS NOT NULL THEN
             gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
          ELSE
             gc_err_msg := gc_errbuf;
          END IF;

          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                       p_application_name        => GC_APPN_NAME
                                      ,p_program_type            => GC_PROGRAM_TYPE
                                      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.GET_BONUS_DATE'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.GET_BONUS_DATE'
                                      ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                      ,p_error_message           => SQLERRM
                                      ,p_error_status            => GC_ERROR_STATUS
                                      ,p_notify_flag             => GC_NOTIFY_FLAG
                                      ,p_error_message_severity  =>'MAJOR'
                                      );

    END GET_BONUS_DATE;
  -- Added on 17/12/07

   -- +===================================================================+
   -- | Name        :  SET_BONUS_DATE                                     |
   -- |                                                                   |
   -- | Description :  This procedure is used to set the Bonus Eligible   |
   -- |                date for a sales rep                               |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters  :  p_role_type_code     IN  Holds the role type code  |
   -- |                x_attribute_category OUT Holds the Attribute Cat   |
   -- |                x_bonus_date         OUT Holds Bonus Date          |
   -- +===================================================================+

   PROCEDURE SET_BONUS_DATE( p_role_type_code     IN  JTF_RS_ROLE_RELATIONS_VL.role_type_code%TYPE
                            ,p_bonus_date         IN  DATE
                            -- Added on 25/02/08(CR BED Grp Mbr Role level)
                            ,p_grp_mbr_id         IN  JTF_RS_GROUP_MEMBERS.group_member_id%TYPE
                            ,p_rol_res_id         IN  NUMBER
                            ,p_grp_mbr_role_date  IN  DATE
                            -- Added on 25/02/08(CR BED Grp Mbr Role level)
                          -- ,p_attribute_cat      IN  JTF_RS_ROLE_RELATIONS.attribute_category%TYPE
                          --  ,x_attribute_category OUT JTF_RS_ROLE_RELATIONS.attribute_category%TYPE
                            ,x_bonus_date         OUT DATE
                            ,x_err_flag           OUT VARCHAR2
                           )
   IS
      EX_SET_BONUS_DATE           EXCEPTION;
      ln_role_id                  JTF_RS_ROLE_RELATIONS.role_id%TYPE;
      ln_curr_role_id             JTF_RS_ROLE_RELATIONS.role_id%TYPE;-- 29/02/08
      ln_grp_mem_id               JTF_RS_GROUP_MEMBERS.group_member_id%TYPE; -- 29/02/08
      ld_old_role_bonus_date      DATE;-- Added on 07/01/08
      lc_error_msg                VARCHAR2(2000);

      /*Commented on 25/02/08(CR BED Grp Mbr Role level)
      -- ----------------------------------------------------------------------
      -- Cursor to check whether the resource is getting fresh sales comp role
      -- ----------------------------------------------------------------------

      CURSOR lcu_chk_role
      IS
      SELECT JRRRV.role_id
      FROM   jtf_rs_role_relations_vl JRRRV
      WHERE  JRRRV.role_resource_id      = gn_resource_id
      --AND    JRRRV.role_type_code  = 'SALES_COMP'-- 08/01/08
      AND    JRRRV.role_type_code  IN ('SALES','SALES_COMP')
      AND    JRRRV.end_date_active  IS NOT NULL
      AND    JRRRV.admin_flag = 'N'; -- 03/01/08

      -- -------------------------------------------------
      -- Cursor to get the old role Bonus Eligibility Date
      -- -------------------------------------------------

      CURSOR lcu_get_bonus_date(p_role_id IN jtf_rs_role_relations.role_id%TYPE)
      IS
      --SELECT attribute15 -- 08/01/08
      SELECT JRRR.attribute14
      FROM   jtf_rs_role_relations JRRR
      WHERE  JRRR.role_resource_id = gn_resource_id
      AND    JRRR.role_id          = p_role_id;
      Commented on 25/02/08(CR BED Grp Mbr Role level)
      */
      -- Modified on 25/02/08(CR BED Grp Mbr Role level)
      -- Replaced gn_resource_id with parameterized cursor p_grp_mbr_id
      CURSOR lcu_chk_mgr_chg_exst_bfore
      IS
      SELECT count(1)
      FROM   jtf_rs_group_members JRGM
            ,jtf_rs_groups_vl     JRGV
      WHERE  resource_id = gn_resource_id
      AND    JRGM.group_id = JRGV.group_id
      AND    JRGV.group_name LIKE 'OD_GRP%';

      -- ------------------------------------------------------------------------------------
      -- Cursor to check whether the resource is getting fresh sales comp resource group role
      -- ------------------------------------------------------------------------------------

      CURSOR lcu_chk_role(p_rol_res_id IN NUMBER)
      IS
      SELECT JRRRV.role_id
      FROM   jtf_rs_role_relations_vl JRRRV
      WHERE  JRRRV.role_resource_id      = p_rol_res_id
      AND    JRRRV.role_type_code  IN ('SALES','SALES_COMP')
      AND    JRRRV.end_date_active  IS NOT NULL
      AND    JRRRV.admin_flag = 'N'; -- 03/01/08

      -- ------------------------------------------------------------------
      -- Cursor to get the role details during back dation after Job change
      -- ------------------------------------------------------------------

      CURSOR lcu_get_role(p_rol_res_id IN NUMBER)
      IS
      SELECT JRRRV.role_id
      FROM   jtf_rs_role_relations_vl JRRRV
      WHERE  JRRRV.role_resource_id      = p_rol_res_id
      AND    JRRRV.role_type_code  IN ('SALES','SALES_COMP')
      AND    JRRRV.end_date_active  IS NULL
      AND    JRRRV.admin_flag = 'N'; -- 03/01/08

      -- ----------------------------------------------------------------
      -- Cursor to get the old resource group role Bonus Eligibility Date
      -- ----------------------------------------------------------------

      CURSOR lcu_get_bonus_date(p_role_id    IN  JTF_RS_ROLE_RELATIONS.role_id%TYPE
                               ,p_grp_mbr_id IN  JTF_RS_GROUP_MEMBERS.group_member_id%TYPE)
      IS
      SELECT JRRR.attribute14
      FROM   jtf_rs_role_relations JRRR
      WHERE  JRRR.role_resource_id = p_grp_mbr_id
      AND    JRRR.role_id          = p_role_id;
      --Modified on 25/02/08(CR BED Grp Mbr Role level)


   BEGIN
      x_err_flag := 'N';
      --IF p_role_type_code = 'SALES_COMP' THEN -- 08/01/08
        IF p_role_type_code IN ('SALES','SALES_COMP') THEN
           -- x_attribute_category := 'SALES_COMP';
           --IF gd_job_asgn_date < gd_golive_date THEN --25/02/08(CR BED Grp Mbr Role level)

           IF p_grp_mbr_role_date < gd_golive_date THEN
            DEBUG_LOG('Pre Golive Scenario');

            --x_bonus_date := gd_job_asgn_date;-- 25/02/08(CR BED Grp Mbr Role level)
            x_bonus_date := p_grp_mbr_role_date;

         --ELSIF gd_job_asgn_date > gd_golive_date THEN-- 25/02/08(CR BED Grp Mbr Role level)
           ELSIF p_grp_mbr_role_date > gd_golive_date THEN
            DEBUG_LOG('Post Golive Scenario');
            ln_role_id         := NULL;

            --OPEN  lcu_chk_role;--25/02/08(CR BED Grp Mbr Role level)
            --OPEN  lcu_chk_role(p_grp_mbr_id); -- Check it
            OPEN  lcu_chk_role(p_rol_res_id);
            FETCH lcu_chk_role INTO ln_role_id;
            CLOSE lcu_chk_role;

            IF ln_role_id IS NULL THEN

               OPEN  lcu_chk_mgr_chg_exst_bfore;
               FETCH lcu_chk_mgr_chg_exst_bfore INTO ln_grp_mem_id;
               CLOSE lcu_chk_mgr_chg_exst_bfore;

               DEBUG_LOG('gc_mgr_matches_flag :'||gc_mgr_matches_flag);
               DEBUG_LOG('ln_grp_mem_id :'||ln_grp_mem_id);

               IF ln_grp_mem_id >1 AND NVL(gc_mgr_matches_flag,'Y') = 'Y' THEN

                  DEBUG_LOG('Previous Group Membership Exists');
                  IF  gc_back_date_exists = 'Y' OR gc_future_date_exists = 'Y' THEN

                      ld_old_role_bonus_date := NULL;
                      ln_curr_role_id := NULL;

                      OPEN  lcu_get_role(p_rol_res_id);
                      FETCH lcu_get_role INTO ln_curr_role_id;
                      CLOSE lcu_get_role;

                      DEBUG_LOG('ln_curr_role_id:'||ln_curr_role_id);

                      OPEN  lcu_get_bonus_date(ln_curr_role_id,p_grp_mbr_id);
                      FETCH lcu_get_bonus_date INTO ld_old_role_bonus_date;
                      CLOSE lcu_get_bonus_date;

                  END IF;

                  DEBUG_LOG('ld_old_role_bonus_date:'||ld_old_role_bonus_date);

                  --IF gd_job_asgn_date < ld_old_role_bonus_date THEN--25/02/08(CR BED Grp Mbr Role level)
                    IF p_grp_mbr_role_date < ld_old_role_bonus_date THEN

                     DEBUG_LOG('Not a first sales comp role :Post Golive Scenario');
                     DEBUG_LOG('BED not elapsed :Set the old Bonus Eligibilty Date to be the New Date ');
                     x_bonus_date := ld_old_role_bonus_date;
                    ELSE

                     DEBUG_LOG('Not a first sales comp role :Post Golive Scenario');
                     DEBUG_LOG('BED elapsed :Set the Group Member Role Date as the Bonus Eligibility Date');
                     --x_bonus_date := gd_job_asgn_date;--25/02/08(CR BED Grp Mbr Role level)
                     x_bonus_date := p_grp_mbr_role_date;
                    END IF;

               ELSE

                  DEBUG_LOG('First sales comp Resource Group role :Post Golive Scenario');
                  DEBUG_LOG('Call the procedure GET_BONUS_DATE to calculate the Bonus Elig date.');
                  GET_BONUS_DATE(
                              --p_date =>gd_job_asgn_date--25/02/08(CR BED Grp Mbr Role level)
                              p_date =>p_grp_mbr_role_date
                             ,x_date =>x_bonus_date
                             );
                  IF x_bonus_date = gd_minimal_date THEN
                     RAISE EX_SET_BONUS_DATE;
                  END IF;
               END IF;

            ELSIF ln_role_id IS NOT NULL THEN

               IF  gc_back_date_exists = 'Y' OR gc_future_date_exists = 'Y' THEN

                   --OPEN  lcu_get_role(p_grp_mbr_id);-- Check it
                   OPEN  lcu_get_role(p_rol_res_id);
                   FETCH lcu_get_role INTO ln_curr_role_id;
                   CLOSE lcu_get_role;

                   OPEN  lcu_get_bonus_date(ln_curr_role_id,p_grp_mbr_id);
                   FETCH lcu_get_bonus_date INTO ld_old_role_bonus_date;
                   CLOSE lcu_get_bonus_date;

               ELSE
                   OPEN  lcu_get_bonus_date(ln_role_id,p_grp_mbr_id);
                   FETCH lcu_get_bonus_date INTO ld_old_role_bonus_date;
                   CLOSE lcu_get_bonus_date;

               END IF;

               DEBUG_LOG('ld_old_role_bonus_date:'||ld_old_role_bonus_date);

               --IF gd_job_asgn_date < ld_old_role_bonus_date THEN--25/02/08(CR BED Grp Mbr Role level)
                 IF p_grp_mbr_role_date < ld_old_role_bonus_date THEN

                  DEBUG_LOG('Not a first sales comp role :Post Golive Scenario');
                  DEBUG_LOG('BED not elapsed :Set the old Bonus Eligibilty Date to be the New Date ');
                  x_bonus_date := ld_old_role_bonus_date;
                 ELSE

                  DEBUG_LOG('Not a first sales comp role :Post Golive Scenario');
                  DEBUG_LOG('BED elapsed :Set the Group Member Role Date as the Bonus Eligibility Date');
                  --x_bonus_date := gd_job_asgn_date;--25/02/08(CR BED Grp Mbr Role level)
                  x_bonus_date := p_grp_mbr_role_date;
                 END IF;
            END IF;   -- gd_job_asgn_date < gd_golive_date
         END IF;
      ELSE
            x_bonus_date           := p_bonus_date;
            --x_attribute_category   := p_attribute_cat;
      END IF;


   EXCEPTION
      WHEN EX_SET_BONUS_DATE THEN
         x_err_flag := 'Y';
      WHEN OTHERS THEN
         x_err_flag := 'Y';

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
         gc_errbuf := FND_MESSAGE.GET;

         WRITE_LOG(SQLERRM);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.SET_BONUS_DATE'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.SET_BONUS_DATE'
                                     ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                                     ,p_error_message           => SQLERRM
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MAJOR'
                                     );

   END SET_BONUS_DATE;

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


      TYPE group_tbl_type IS TABLE OF jtf_rs_groups_vl.group_id%type INDEX BY BINARY_INTEGER;
      lt_group  group_tbl_type;

      CURSOR  lcu_check_old_group_mbrship
      IS
      SELECT  'Y' GRP_MBRSHIP
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_group_mbr_role_vl
      WHERE   resource_id = gn_resource_id
      AND     group_id   <> p_group_id
      AND     end_date_active is NULL);

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
             ,jtf_rs_roles_vl           JRRV
      WHERE   JRGMR.group_member_id   = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRGMR.group_id          = JRGV.group_id
      AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER'
      AND     JRRR.delete_flag        = 'N'
      AND     JRGMR.resource_id       = gn_resource_id
      AND     JRGMR.group_id         <> p_group_id
      AND     JRGMR.end_date_active  IS NULL
      AND     JRRV.role_id = JRGMR.role_id
      AND     NVL(JRRV.attribute14, 'X') <> GC_PROXY_ROLE
      ORDER   BY group_id;

      CURSOR  lcu_check_lastin_grp (p_grp_id NUMBER)
      IS
      SELECT  'N' lastin_grp_flag
      FROM    jtf_rs_group_mbr_role_VL
      WHERE   resource_id <> gn_resource_id
      AND     group_id    =  p_grp_id
      AND     NVL(end_date_active,p_end_date+1) > p_end_date;

      CURSOR  lcu_get_group_det(p_grp_id NUMBER)
      IS
      SELECT  group_id
             ,group_number
             ,object_version_number
      FROM    jtf_rs_groups_vl
      WHERE   group_id = p_grp_id;

      CURSOR  lcu_get_group_role(p_grp_id NUMBER)
      IS
      SELECT  role_relate_id
             ,object_version_number
      FROM    jtf_rs_role_relations
      WHERE   delete_flag = 'N'
      AND     end_date_active IS NULL
      AND     role_resource_type = 'RS_GROUP'
      AND     role_resource_id = p_grp_id;

      CURSOR  lcu_get_old_relation(p_grp_id NUMBER)
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

      lr_group_det              lcu_get_group_det%ROWTYPE;

   BEGIN

      DEBUG_LOG('Inside Proc: END_GRP_AND_RESGRPROLE');
      ln_group_cnt := 1;
      lt_group.delete;

      FOR  old_grp_mbrship_rec  IN  lcu_check_old_group_mbrship
      LOOP

         lc_mbrship_exists_flag := old_grp_mbrship_rec.grp_mbrship;
         EXIT;

      END LOOP;

      DEBUG_LOG('Old membership exists (Y/N) : '||NVL(lc_mbrship_exists_flag,'N'));

      IF ( lc_mbrship_exists_flag = 'Y' ) THEN

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
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
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

               -- Note the group id if its not sales/admin/payment analyst group
               IF (ln_old_group_id IS NULL
               OR ln_old_group_id <> group_mbrship_rec.group_id) THEN

                  IF group_mbrship_rec.group_name NOT IN --('OD_SALES_ADMIN_GRP','OD_PAYMENT_ANALYST_GRP','OD_SUPPORT_GRP')
                    (GC_OD_SALES_ADMIN_GRP,GC_OD_PAYMENT_ANALYST_GRP,GC_OD_SUPPORT_GRP) THEN

                     lt_group(ln_group_cnt) := group_mbrship_rec.group_id;
                     ln_old_group_id := group_mbrship_rec.group_id;
                     ln_group_cnt    := ln_group_cnt + 1;

                  END IF;

               END IF;  -- END IF, ln_old_group_id <> group_mbrship_rec.group_id

            END IF;    -- lc_return_status <> fnd_api.G_RET_STS_SUCCESS

         END LOOP;  --  END LOOP, lcu_get_old_group_mbrship

      END IF;  -- End if, lc_mbrship_exists_flag = 'Y'


      IF ( lt_group.count > 0 ) THEN
         FOR  i IN lt_group.FIRST..lt_group.LAST
         LOOP

             FOR  check_lastin_grp_rec IN lcu_check_lastin_grp(lt_group(i))
             LOOP

                lc_lastin_grp_flag :=  check_lastin_grp_rec.lastin_grp_flag;
                EXIT;

             END LOOP;

             IF  NVL(lc_lastin_grp_flag,'Y') = 'Y' THEN

                DEBUG_LOG('Processing for Group ID: '||lt_group(i));

                lr_group_det := NULL;

                IF lcu_get_group_det%ISOPEN THEN

                   CLOSE lcu_get_group_det;

                END IF;

                OPEN  lcu_get_group_det (lt_group(i));
                FETCH lcu_get_group_det INTO lr_group_det;
                CLOSE lcu_get_group_det;


                FOR  group_role_rec IN lcu_get_group_role(lr_group_det.group_id)
                LOOP

                  ENDDATE_RES_GRP_ROLE
                     (p_role_relate_id   => group_role_rec.role_relate_id
                     ,p_end_date_active  => p_end_date
                     ,p_object_version   => group_role_rec.object_version_number
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
                                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                            ,p_program_id              => gc_conc_prg_id
                                            ,p_module_name             => GC_MODULE_NAME
                                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
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

                     DEBUG_LOG('In Procedure:END_GRP_AND_RESGRPROLE: Proc: ENDDATE_RES_GRP_ROLE Success');

                  END IF;

                END LOOP;  -- END LOOP, lcu_get_group_role(lr_group_det.group_id)

                FOR  old_relation_rec IN lcu_get_old_relation(lr_group_det.group_id)
                LOOP

                   ENDDATE_OFF_PARENT_GROUP
                                    ( p_group_relate_id      => old_relation_rec.group_relate_id
                                    , p_end_date_active      => p_end_date
                                    , p_object_version_num   => old_relation_rec.object_version_number
                                    , x_return_status        => lc_return_status
                                    , x_msg_count            => ln_msg_count
                                    , x_msg_data             => lc_msg_data
                                    );
                   x_msg_count := ln_msg_count;

                   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                     WRITE_LOG(lc_msg_data);

                     DEBUG_LOG('In Procedure:END_GRP_AND_RESGRPROLE: Proc: ENDDATE_OFF_PARENT_GROUP Fails. ');

                     IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                        gc_return_status := 'WARNING';

                     END IF;

                     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code             => lc_return_status
                                            ,p_msg_count               => ln_msg_count
                                            ,p_application_name        => GC_APPN_NAME
                                            ,p_program_type            => GC_PROGRAM_TYPE
                                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                            ,p_program_id              => gc_conc_prg_id
                                            ,p_module_name             => GC_MODULE_NAME
                                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                            ,p_error_message_count     => ln_msg_count
                                            ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                            ,p_error_message           => lc_msg_data
                                            ,p_error_status            => GC_ERROR_STATUS
                                            ,p_notify_flag             => GC_NOTIFY_FLAG
                                            ,p_error_message_severity  =>'MINOR'
                                            );

                   ELSE

                     DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ENDDATE_OFF_PARENT_GROUP Success');

                   END IF;

                END LOOP;  -- END LOOP, lcu_get_old_relation

                ENDDATE_GROUP
                         (
                         p_group_id           => lr_group_det.group_id ,
                         p_group_number       => lr_group_det.group_number,
                         p_end_date           => p_end_date ,
                         p_object_version_num => lr_group_det.object_version_number,
                         x_return_status      => lc_return_status,
                         x_msg_count          => ln_msg_count,
                         x_msg_data           => lc_msg_data
                         );
                x_msg_count := ln_msg_count;

                IF lc_return_status <> fnd_api.G_RET_STS_SUCCESS
                THEN

                  WRITE_LOG(lc_msg_data);

                  DEBUG_LOG('In Procedure: END_GRP_AND_RESGRPROLE: Proc: ENDDATE_GROUP Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code             => lc_return_status
                                        ,p_msg_count               => ln_msg_count
                                        ,p_application_name        => GC_APPN_NAME
                                        ,p_program_type            => GC_PROGRAM_TYPE
                                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                                        ,p_error_message_count     => ln_msg_count
                                        ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => lc_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MINOR'
                                        );

                ELSE

                   DEBUG_LOG('In Procedure:END_GRP_AND_RESGRPROLE: Proc: ENDDATE_GROUP Success');

                END IF;

            END IF;   -- END IF, NVL(lc_lastin_grp_flag,'Y') = 'Y'

            lc_lastin_grp_flag := NULL;

         END LOOP;   --  END LOOP, lt_group.FIRST

      END IF;   -- End if, lt_group.count> 0

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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.END_GRP_AND_RESGRPROLE'
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
   -- |                    change. When back dated, both the roles shall  |
   -- |                    be backdated. When future dated(when current   |
   -- |                    gd_crm_job_asgn_date is greater than HRMS      |
   -- |                    gd_job_asgn_date), both the group membership   |
   -- |                    start date and role start date are future dated|
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
      ld_bonus_elig_date            DATE;-- Added on 24/12/07
      --lc_attribute_cat              JTF_RS_ROLE_RELATIONS.attribute_category%TYPE; -- Added on 24/12/07
      lc_err_flag                   VARCHAR2(1);

      EX_TERMIN_PROG                EXCEPTION;


   CURSOR  lcu_get_res_details
   IS
   SELECT  resource_number
          ,object_version_number
          ,source_name
--          ,TO_DATE(attribute14,'MM/DD/RRRR') JOB_ASGN_DATE --04/Dec/07
--          ,TO_DATE(attribute15,'MM/DD/RRRR') MGR_ASGN_DATE --04/Dec/07
          ,TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
          ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
   FROM    jtf_rs_resource_extns_vl
   WHERE   resource_id = gn_resource_id;

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
                                  AND     gd_job_asgn_date  -- Changed from gd_job_asgn_date - 1
                                          BETWEEN start_date_active
                                          AND     end_date_active
                                  /* Check is not needed as end date active not null checked in main query
                                  AND     role_relate_id NOT IN (SELECT  role_relate_id
                                                                 FROM    jtf_rs_role_relations
                                                                 WHERE   role_resource_id   = gn_resource_id
                                                                 AND     role_resource_type = 'RS_INDIVIDUAL'
                                                                 AND     end_date_active IS NULL
                                                                 AND     delete_flag = 'N'
                                                                )
                                  */
                               );
   /* Check is not needed as end date active not null checked in main query
   AND     role_relate_id NOT IN (SELECT  role_relate_id
                                  FROM    jtf_rs_role_relations
                                  WHERE   role_resource_id   = gn_resource_id
                                  AND     role_resource_type = 'RS_INDIVIDUAL'
                                  AND     end_date_active IS NULL
                                  AND     delete_flag = 'N'
                                 ); 
   */


   CURSOR  lcu_get_prev_roles_backdate
   IS
   SELECT  role_relate_id
          ,object_version_number
          ,start_date_active
          ,end_date_active
   FROM    jtf_rs_role_relations
   WHERE   role_resource_id = gn_resource_id
   AND     role_resource_type = 'RS_INDIVIDUAL'
   AND     end_date_active IS NOT NULL
   AND     start_date_active <= gd_job_asgn_date -1
   AND     delete_flag = 'N'
   AND     gd_job_asgn_date
           BETWEEN start_date_active
           AND     nvl(end_date_active, gd_job_asgn_date + 1);


   CURSOR  lcu_get_prev_mbr_backdate
   IS
   SELECT  JRRR.role_relate_id
          ,JRRR.object_version_number
          ,JRRR.start_date_active
          ,JRRR.end_date_active
   FROM    jtf_rs_role_relations JRRR
          ,jtf_rs_group_mbr_role_vl JRGMR
   WHERE   JRRR.role_relate_id     = JRGMR.role_relate_id
   AND     JRGMR.resource_id       = gn_resource_id
   AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER'
   AND     JRGMR.end_date_active IS NOT NULL
   AND     JRGMR.start_date_active <= gd_mgr_asgn_date -1
   AND     JRRR.delete_flag = 'N'
   AND     gd_mgr_asgn_date
           BETWEEN JRGMR.start_date_active
           AND     NVL(JRGMR.end_date_active, gd_mgr_asgn_date + 1);

-- ------------------------------------------------------------------------
-- Cursor to fetch previous resource roles for future date scenario
-- -----------------------------------------------------------------------
   CURSOR  lcu_get_prev_roles_futuredate
   IS
   SELECT  role_relate_id
          ,object_version_number
          ,start_date_active
          ,end_date_active          
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
-- ------------------------------------------------------------------------
-- Cursor to fetch previous resource group roles for future date scenario
-- -----------------------------------------------------------------------

   CURSOR  lcu_get_prev_mbr_futuredate
   IS
   SELECT  JRRR.role_relate_id
          ,JRRR.object_version_number
          ,JRRR.start_date_active
          ,JRRR.end_date_active
   FROM    jtf_rs_role_relations JRRR
          ,jtf_rs_group_mbr_role_vl JRGMR
   WHERE   JRRR.role_relate_id     = JRGMR.role_relate_id
   AND     JRGMR.resource_id       = gn_resource_id
   AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER'
   AND     JRGMR.end_date_active IS NOT NULL
   AND     JRRR.delete_flag = 'N'
   AND     JRGMR.end_date_active = ( SELECT MAX(JRGMR1.end_date_active)
                                     FROM   jtf_rs_group_mbr_role_vl JRGMR1
                                     WHERE  JRGMR1.resource_id   = gn_resource_id
                                     AND    JRGMR1.end_date_active IS NOT NULL
                                     );

   CURSOR  lcu_get_curr_roles
   IS
   SELECT  JRRR.role_relate_id
          ,JRRR.start_date_active
          ,JRRR.object_version_number
          -- Commented on 25/02/08(CR BED Grp Mbr Role level)
          --,JRRR.attribute14-- 24/12/07 -- 08/01/08
          -- Commented on 25/02/08(CR BED Grp Mbr Role level)
          --,JRRR.attribute15-- 28/12/07 -- 08/01/08
          --,JRRR.attribute_category-- 24/12/07 -- 08/01/08
          --,JRRV.role_type_code-- 24/12/07-- Commented on 25/02/08(CR BED Grp Mbr Role level)
   FROM    jtf_rs_role_relations  JRRR
          ,jtf_rs_roles_vl        JRRV
   WHERE   JRRR.role_resource_id   = gn_resource_id
   AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
   AND     JRRR.role_id            = JRRV.role_id
   AND     JRRR.end_date_active IS NULL
   AND     JRRR.delete_flag = 'N'  ;

   CURSOR  lcu_get_curr_grp_mbrship
   IS
   SELECT  JRRR.role_relate_id
          ,JRRR.start_date_active
          ,JRRR.object_version_number
          -- Added on 25/02/08(CR BED Grp Mbr Role level)
          ,JRGMR.group_member_id
          ,JRRV.role_type_code
          ,JRRR.attribute14
          -- Added on 25/02/08(CR BED Grp Mbr Role level)
   FROM    jtf_rs_role_relations JRRR
          ,jtf_rs_group_mbr_role_vl JRGMR
          -- Added on 25/02/08(CR BED Grp Mbr Role level)
          ,jtf_rs_roles_vl          JRRV
          -- Added on 25/02/08(CR BED Grp Mbr Role level)
   WHERE   JRRR.role_relate_id     = JRGMR.role_relate_id
   AND     JRGMR.resource_id       = gn_resource_id
   AND     JRRR.role_resource_type = 'RS_GROUP_MEMBER'
   -- Added on 25/02/08(CR BED Grp Mbr Role level)
   AND     JRRR.role_id            = JRRV.role_id
   -- Added on 25/02/08(CR BED Grp Mbr Role level)
   AND     JRRR.end_date_active  IS NULL
   AND     JRGMR.end_date_active IS NULL
   AND     delete_flag = 'N'  ;

   lr_res_details  lcu_get_res_details%ROWTYPE;



   BEGIN

      DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES');

      /* Code Commented on 01/15/2009 as error check is no more needed with retro logic

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
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                            ,p_msg_count               => 1 --x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_error_message_count     => 1 --x_msg_count
                            ,p_error_message_code      =>'XX_TM_0099_OTHER_ROLES_EXIST'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

         RAISE EX_TERMIN_PROG;

      END IF;

      */

      IF lcu_get_res_details%ISOPEN THEN

         CLOSE lcu_get_res_details;

      END IF;

      OPEN  lcu_get_res_details;
      FETCH lcu_get_res_details INTO lr_res_details;
      CLOSE lcu_get_res_details;


      DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Start of Back/Future dating of Current Res Grp Roles and Res Roles.');

      IF gd_crm_job_asgn_date > gd_job_asgn_date THEN

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: HR Job Date less then CRM job Date. Should be Back Date Scenario.');
         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res roles....');

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Before Fetching Previous Res Grp Roles for correcting EndDate for Back/Future dating');
         FOR  prev_role_rec IN lcu_get_prev_mbr_backdate
         LOOP
              DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating End Date of Res Grp Role Id: '||prev_role_rec.role_relate_id);
              ENDDATE_RES_GRP_ROLE
                             (P_ROLE_RELATE_ID  => prev_role_rec.role_relate_id,
                              P_END_DATE_ACTIVE => gd_mgr_asgn_date -1,
                              P_OBJECT_VERSION  => prev_role_rec.object_version_number,
                              X_RETURN_STATUS   => lc_return_status,
                              X_MSG_COUNT       => x_msg_count,
                              X_MSG_DATA        => x_msg_data
                             );

              IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                 WRITE_LOG(x_msg_data);

                 DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: ENDDATE_RES_GRP_ROLE Fails. ');
 
                 IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                   gc_return_status   := 'WARNING';
                 END IF;

                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code             => lc_return_status
                                       ,p_msg_count               => x_msg_count
                                       ,p_application_name        => GC_APPN_NAME
                                       ,p_program_type            => GC_PROGRAM_TYPE
                                       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                       ,p_program_id              => gc_conc_prg_id
                                       ,p_module_name             => GC_MODULE_NAME
                                       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                       ,p_error_message_count     => x_msg_count
                                       ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                       ,p_error_message           => x_msg_data
                                       ,p_error_status            => GC_ERROR_STATUS
                                       ,p_notify_flag             => GC_NOTIFY_FLAG
                                       ,p_error_message_severity  =>'MINOR'
                                       );

              END IF;
         END LOOP;  --  End loop, lcu_get_prev_mbr_backdate

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

               DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE Fails. ');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                 gc_return_status   := 'WARNING';
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => lc_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            END IF;

         END LOOP;  -- End loop, lcu_get_prev_roles_backdate

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: End of Back/Future dating of Previous Res Grp Roles and Res Roles.');

         FOR  curr_role_rec IN lcu_get_curr_roles
         LOOP
            -- Commented on 25/02/08(CR BED Grp Mbr Role level)
            --ld_bonus_elig_date := NULL;
            -- Commented on 25/02/08(CR BED Grp Mbr Role level)
            --lc_attribute_cat   := NULL;
            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Role Id: '||curr_role_rec.role_relate_id);
            IF curr_role_rec.start_date_active > gd_job_asgn_date THEN

               --lc_update_resource := 'Y';-- 18/Mar/08
               /*Commented on 25/02/08(CR BED Grp Mbr Role level)
               SET_BONUS_DATE(p_role_type_code     =>curr_role_rec.role_type_code
                             ,p_bonus_date         =>curr_role_rec.attribute14
                             --,p_attribute_cat      =>curr_role_rec.attribute_category
                             --,x_attribute_category =>lc_attribute_cat
                             ,x_bonus_date         =>ld_bonus_elig_date
                             ,x_err_flag           =>lc_err_flag
                             );
               Commented on 25/02/08(CR BED Grp Mbr Role level)

               IF lc_err_flag = 'Y' THEN
                  gc_return_status  := 'WARNING';
               END IF;
               */

               BACKDATE_RES_ROLE
                          (P_ROLE_RELATE_ID     => curr_role_rec.role_relate_id,
                           P_START_DATE_ACTIVE  => gd_job_asgn_date,
                           P_OBJECT_VERSION     => curr_role_rec.object_version_number,
                           -- Commented on 25/02/08(CR BED Grp Mbr Role level)
                           --P_ATTRIBUTE14        => ld_bonus_elig_date,-- 24/12/07
                           -- Commented on 25/02/08(CR BED Grp Mbr Role level)
                           P_ATTRIBUTE14        => NULL,-- 25/02/08
                           --P_ATTRIBUTE15        => ld_bonus_elig_date,-- 28/12/07 -- 08/01/08
                           --P_ATTRIBUTE_CATEGORY => lc_attribute_cat,     -- 24/12/07
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
                                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                        ,p_error_message_count     => x_msg_count
                                        ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => x_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MINOR'
                                        );
               ELSE
                  lc_update_resource := 'Y';--18/Mar/08
               END IF;

            END IF;

         END LOOP; -- END LOOP, lcu_get_curr_roles

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res grp roles....');
         FOR  curr_grp_mbrship_rec IN lcu_get_curr_grp_mbrship
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Grp Role Id: '||curr_grp_mbrship_rec.role_relate_id);
          --IF curr_grp_mbrship_rec.start_date_active > gd_job_asgn_date THEN -- 26/02/08
            IF curr_grp_mbrship_rec.start_date_active > greatest(gd_job_asgn_date,gd_mgr_asgn_date) THEN-- 26/02/08

               gc_back_date_exists:= 'Y';

               -- Added on 25/02/08(CR BED Grp Mbr Role level)
               ld_bonus_elig_date := NULL;

               DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');

               SET_BONUS_DATE(p_role_type_code     =>curr_grp_mbrship_rec.role_type_code
                             ,p_bonus_date         =>curr_grp_mbrship_rec.attribute14
                             ,p_grp_mbr_id         =>curr_grp_mbrship_rec.group_member_id
                             ,p_rol_res_id         =>curr_grp_mbrship_rec.group_member_id
                             --,p_grp_mbr_role_date  =>gd_job_asgn_date-- 26/02/08
                             ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date)-- 26/02/08
                             --,p_attribute_cat      =>curr_role_rec.attribute_category
                             --,x_attribute_category =>lc_attribute_cat
                             ,x_bonus_date         =>ld_bonus_elig_date
                             ,x_err_flag           =>lc_err_flag
                             );

               IF lc_err_flag = 'Y' THEN
                  gc_return_status  := 'WARNING';
               END IF;

               -- Added on 25/02/08(CR BED Grp Mbr Role level)

               BACKDATE_RES_GRP_ROLE
                          (P_ROLE_RELATE_ID    => curr_grp_mbrship_rec.role_relate_id,
                           --P_START_DATE_ACTIVE => gd_job_asgn_date,-- 26/02/08
                           P_START_DATE_ACTIVE => greatest(gd_job_asgn_date,gd_mgr_asgn_date),-- 26/02/08
                           P_OBJECT_VERSION    => curr_grp_mbrship_rec.object_version_number,
                           /* Commented on 11/Jun/08 since the BED population is taken out
                           -- Added on 25/02/08(CR BED Grp Mbr Role level)
                           P_ATTRIBUTE14       => ld_bonus_elig_date,
                           -- Added on 25/02/08(CR BED Grp Mbr Role level)
                           Commented on 11/Jun/08 since the BED population is taken out
                           */
                           -- Added on 11/Jun/08
                           P_ATTRIBUTE14          => NULL,
                           -- Added on 11/Jun/08
                           X_RETURN_STATUS     => lc_return_status,
                           X_MSG_COUNT         => x_msg_count,
                           X_MSG_DATA          => x_msg_data
                          );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);
                  DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: BACKDATE_RES_GRP_ROLE Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                    gc_return_status   := 'WARNING';
                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code             => lc_return_status
                                         ,p_msg_count               => x_msg_count
                                         ,p_application_name        => GC_APPN_NAME
                                         ,p_program_type            => GC_PROGRAM_TYPE
                                         ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_error_message_count     => x_msg_count
                                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                         ,p_error_message           => x_msg_data
                                         ,p_error_status            => GC_ERROR_STATUS
                                         ,p_notify_flag             => GC_NOTIFY_FLAG
                                         ,p_error_message_severity  =>'MINOR'
                                         );


               END IF;

            END IF;

         END LOOP; -- END LOOP, curr_grp_mbrship_rec


      ELSIF gd_crm_job_asgn_date <  gd_job_asgn_date
      AND   gd_crm_job_asgn_date <> gd_job_asgn_date
      THEN

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: HR Job Date greater then CRM job Date. Should be Future Date Scenario.');
         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res grp roles....');


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
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            END IF;


         END LOOP;  -- End loop, lcu_get_prev_roles_futuredate

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Before Fetching Previous Res Roles for correcting EndDate for Future dating');
         FOR  prev_role_rec IN lcu_get_prev_mbr_futuredate
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating End Date of Res Grp Role Id 1: '||prev_role_rec.role_relate_id);
            ENDDATE_RES_GRP_ROLE
                             (P_ROLE_RELATE_ID  => prev_role_rec.role_relate_id,
                              P_END_DATE_ACTIVE => gd_mgr_asgn_date -1,
                              P_OBJECT_VERSION  => prev_role_rec.object_version_number,
                              X_RETURN_STATUS   => lc_return_status,
                              X_MSG_COUNT       => x_msg_count,
                              X_MSG_DATA        => x_msg_data
                             );

            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(x_msg_data);
               DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: ENDDATE_RES_GRP_ROLE Fails for Group membership.');

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                 gc_return_status   := 'WARNING';
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => lc_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            END IF;

         END LOOP;  --  End loop, lcu_get_prev_mbr_futuredate


         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: End of Future dating of Previous Res Grp Roles and Res Roles.');


         FOR  curr_grp_mbrship_rec IN lcu_get_curr_grp_mbrship
         LOOP

            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Grp Role Id: '||curr_grp_mbrship_rec.role_relate_id);
            --IF curr_grp_mbrship_rec.start_date_active < gd_job_asgn_date THEN-- 26/02/08
            IF curr_grp_mbrship_rec.start_date_active < greatest(gd_job_asgn_date,gd_mgr_asgn_date) THEN-- 26/02/08
               DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Grp Role Id: '||curr_grp_mbrship_rec.role_relate_id);

               gc_future_date_exists := 'Y';-- 29/02/08
               -- Added on 25/02/08(CR BED Grp Mbr Role level)
               ld_bonus_elig_date := NULL;

               DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');

               SET_BONUS_DATE(p_role_type_code     =>curr_grp_mbrship_rec.role_type_code
                             ,p_bonus_date         =>curr_grp_mbrship_rec.attribute14
                             ,p_grp_mbr_id         =>curr_grp_mbrship_rec.group_member_id
                             ,p_rol_res_id         =>curr_grp_mbrship_rec.group_member_id
                             --,p_grp_mbr_role_date  =>gd_job_asgn_date -- 26/02/08
                             ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date) -- 26/02/08
                             --,p_attribute_cat      =>curr_role_rec.attribute_category
                             --,x_attribute_category =>lc_attribute_cat
                             ,x_bonus_date         =>ld_bonus_elig_date
                             ,x_err_flag           =>lc_err_flag
                             );

               IF lc_err_flag = 'Y' THEN
                  gc_return_status  := 'WARNING';
               END IF;

               -- Added on 25/02/08(CR BED Grp Mbr Role level)

               BACKDATE_RES_GRP_ROLE
                          (P_ROLE_RELATE_ID    => curr_grp_mbrship_rec.role_relate_id,
                           --P_START_DATE_ACTIVE => gd_job_asgn_date,-- 26/02/08
                           P_START_DATE_ACTIVE => greatest(gd_job_asgn_date,gd_mgr_asgn_date),--26/02/08
                           P_OBJECT_VERSION    => curr_grp_mbrship_rec.object_version_number,
                           /* Commented on 11/Jun/08 since the BED population is taken out
                           P_ATTRIBUTE14       => ld_bonus_elig_date,-- Added on 25/02/08
                           Commented on 11/Jun/08 since the BED population is taken out
                           */
                           -- Added on 11/Jun/08
                           P_ATTRIBUTE14          => NULL,
                           -- Added on 11/Jun/08
                           X_RETURN_STATUS     => lc_return_status,
                           X_MSG_COUNT         => x_msg_count,
                           X_MSG_DATA          => x_msg_data
                          );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);

                  DEBUG_LOG('In Procedure: BACK_DATE_CURR_ROLES: Proc: BACKDATE_RES_GRP_ROLE Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                    gc_return_status   := 'WARNING';
                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code             => lc_return_status
                                         ,p_msg_count               => x_msg_count
                                         ,p_application_name        => GC_APPN_NAME
                                         ,p_program_type            => GC_PROGRAM_TYPE
                                         ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_error_message_count     => x_msg_count
                                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                         ,p_error_message           => x_msg_data
                                         ,p_error_status            => GC_ERROR_STATUS
                                         ,p_notify_flag             => GC_NOTIFY_FLAG
                                         ,p_error_message_severity  =>'MINOR'
                                         );

               END IF;

            END IF;

         END LOOP; -- END LOOP, curr_grp_mbrship_rec

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Fetching current res roles....');
         FOR  curr_role_rec IN lcu_get_curr_roles
         LOOP
            -- ld_bonus_elig_date := NULL;-- 27/Feb/08
            --lc_attribute_cat   := NULL;
            DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Processing Res Role Id: '||curr_role_rec.role_relate_id);

            IF curr_role_rec.start_date_active < gd_job_asgn_date THEN

               --lc_update_resource  := 'Y';-- 18/Mar/08
               /*Commented on 25/02/08(CR BED Grp Mbr Role level)
               SET_BONUS_DATE(p_role_type_code     =>curr_role_rec.role_type_code
                             ,p_bonus_date         =>curr_role_rec.attribute14
                             --,p_attribute_cat      =>curr_role_rec.attribute_category
                             --,x_attribute_category =>lc_attribute_cat
                             ,x_bonus_date         =>ld_bonus_elig_date
                             ,x_err_flag           =>lc_err_flag
                             );

               IF lc_err_flag = 'Y' THEN
                  gc_return_status  := 'WARNING';
               END IF;
               Commented on 25/02/08(CR BED Grp Mbr Role level)
               */

               BACKDATE_RES_ROLE
                          (P_ROLE_RELATE_ID     => curr_role_rec.role_relate_id,
                           P_START_DATE_ACTIVE  => gd_job_asgn_date,
                           P_OBJECT_VERSION     => curr_role_rec.object_version_number,
                         -- Commented on 25/02/08(CR BED Grp Mbr Role level)
                         --  P_ATTRIBUTE14        => ld_bonus_elig_date, -- 24/12/07
                         -- Commented on 25/02/08(CR BED Grp Mbr Role level)
                           P_ATTRIBUTE14        => NULL,-- 25/02/08
                           --P_ATTRIBUTE15        => ld_bonus_elig_date,-- 28/12/07 -- 08/01/08
                           --P_ATTRIBUTE_CATEGORY => lc_attribute_cat,      -- 24/12/07 -- 08/01/08
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
                                         ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
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
                  lc_update_resource  := 'Y';-- 18/Mar/08
               END IF;

            END IF;

         END LOOP; -- END LOOP, lcu_get_curr_roles

      END IF; -- END IF, gd_crm_job_asgn_date > gd_job_asgn_date ;
      DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: End of Back/Future dation of Current Res or Res Grp Roles');

      IF (NVL(lc_update_resource,'N') = 'Y') THEN

         DEBUG_LOG('Inside Proc BACK_DATE_CURR_ROLES: Updating Resource Dates using UPDT_DATES_RESOURCE.');
         UPDT_DATES_RESOURCE
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lr_res_details.resource_number
                       , p_source_name        =>  lr_res_details.source_name
--                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR')            --04/Dec/07
--                       , p_attribute15        =>  TO_CHAR(lr_res_details.mgr_asgn_date,'MM/DD/RRRR')--04/Dec/07
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_attribute15        =>  TO_CHAR(lr_res_details.mgr_asgn_date,'DD-MON-RR')
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
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
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
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                               p_return_code             => x_return_status
                              ,p_msg_count               => 1
                              ,p_application_name        => GC_APPN_NAME
                              ,p_program_type            => GC_PROGRAM_TYPE
                              ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
                              ,p_program_id              => gc_conc_prg_id
                              ,p_module_name             => GC_MODULE_NAME
                              ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.BACK_DATE_CURR_ROLES'
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
      lc_role_exists_flag                VARCHAR2(1);
      --ld_bonus_elig_date                 DATE;-- Added on 20/12/07 --Commented on 27/02/08
      --ld_old_role_bonus_date             DATE;-- Added on 07/01/08 --Commented on 27/02/08
      --ln_role_id                         JTF_RS_ROLE_RELATIONS.role_id%TYPE;
      --lc_attribute_cat                   JTF_RS_ROLE_RELATIONS.attribute_category%TYPE;
      --lc_err_flag                        VARCHAR2(1);--Commented on 27/02/08
      lc_supprt_flag                     VARCHAR2(1); -- 24/07/08
      

      EX_TERMINATE_ROLE_ASGN             EXCEPTION;

      CURSOR  lcu_get_job
      IS
      SELECT  job_id
      FROM    per_all_assignments_f
      WHERE   person_id         = gn_person_id
      AND     business_group_id = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      CURSOR  lcu_check_mgr
      IS
      SELECT 'Y' MANAGER_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1  -- Check for the current role assignment
      FROM    jtf_rs_role_relations JRRR
            , jtf_rs_roles_vl       JRRV
      where   JRRR.role_id           = JRRV.role_id
      AND     JRRR.role_resource_id  = gn_resource_id
      AND     JRRR.delete_flag  = 'N'
      AND     JRRR.role_resource_type  ='RS_INDIVIDUAL'
      AND     JRRV.manager_flag = 'Y'
      AND     gd_job_asgn_date
      BETWEEN JRRR.start_date_active
      AND     NVL(JRRR.end_date_active,gd_job_asgn_date)
      UNION
      SELECT  1  -- Check for the new job assignment
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id      = JRJR.role_id
      AND     JRRV.manager_flag = 'Y'
      AND     JRRV.role_type_code = 'SALES'
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRRV.manager_flag = 'Y'
      AND     JRJR.job_id       = gn_job_id
      );

      CURSOR  lcu_get_roles
      IS
      SELECT  JRRV.role_id
             ,JRRV.role_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
             ,JRRV.manager_flag
             ,JRRV.attribute14
             ,JRRV.role_type_code -- Added on 17/12/07
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id = JRJR.role_id
      AND     JRJR.job_id  = gn_job_id
      AND     JRRV.role_type_code = 'SALES'  -- ,'SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
      AND     NVL(JRRV.active_flag,'N')    = 'Y'
      AND     JRRV.role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_role_relations
              WHERE   role_resource_id    = gn_resource_id
              AND     role_resource_type  ='RS_INDIVIDUAL'
              AND     delete_flag         = 'N'
              AND     gd_job_asgn_date  -- gd_as_of_date
                      BETWEEN start_date_active
                      AND     NVL(end_date_active,gd_job_asgn_date));  -- gd_as_of_date));
                      
      -- Added on 24/07/08
      
      CURSOR  lcu_check_sprt_roles
      IS
      SELECT 'Y' SUPPORT_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1  -- Check for the current role assignment
      FROM    jtf_rs_role_relations JRRR
            , jtf_rs_roles_vl       JRRV
      where   JRRR.role_id           = JRRV.role_id
      AND     JRRV.role_type_code = 'SALES'  
      AND     JRRR.role_resource_id  = gn_resource_id
      AND     JRRR.delete_flag  = 'N'
      AND     JRRR.role_resource_type  ='RS_INDIVIDUAL'      
      AND     gd_job_asgn_date
      BETWEEN JRRR.start_date_active
      AND     NVL(JRRR.end_date_active,gd_job_asgn_date)
      UNION
      SELECT  1  -- Check for the new job assignment
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id      = JRJR.role_id      
      AND     JRRV.role_type_code IN ('COLLECTIONS')
      AND     JRRV.role_type_code NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST') -- 28/07/08
      AND     NVL(JRRV.active_flag,'N') = 'Y'      
      AND     JRJR.job_id       = gn_job_id
      );

      CURSOR  lcu_get_collection_roles
      IS
      SELECT  JRRV.role_id
             ,JRRV.role_code            
             ,JRRV.attribute14
             ,JRRV.role_type_code -- Added on 17/12/07
      FROM    jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      WHERE   JRRV.role_id = JRJR.role_id
      AND     JRJR.job_id  = gn_job_id
      AND     JRRV.role_type_code IN ('COLLECTIONS')
      AND     JRRV.role_type_code NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST') -- 28/07/08
      AND     NVL(JRRV.active_flag,'N')    = 'Y'
      AND     JRRV.role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_role_relations
              WHERE   role_resource_id    = gn_resource_id
              AND     role_resource_type  ='RS_INDIVIDUAL'
              AND     delete_flag         = 'N'
              AND     gd_job_asgn_date  -- gd_as_of_date
                      BETWEEN start_date_active
                      AND     NVL(end_date_active,gd_job_asgn_date));  -- gd_as_of_date));
                      
      -- Added on 24/07/08
      
      
      CURSOR  lcu_get_res_details
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;


      lr_res_details    lcu_get_res_details%ROWTYPE;      


   BEGIN

      DEBUG_LOG('Inside Proc: Assign_Role');

      IF gn_job_id IS NULL THEN

         IF lcu_get_job%ISOPEN THEN
            CLOSE lcu_get_job;
         END IF;

         OPEN  lcu_get_job;
         FETCH lcu_get_job INTO gn_job_id;
         CLOSE lcu_get_job;

      END IF; -- END IF, gn_job_id IS NULL

      DEBUG_LOG('Job Id'||gn_job_id);     
      
      IF gc_hierarchy_type = 'SALES' THEN
      
         FOR  check_mgr_rec IN lcu_check_mgr
         LOOP

            lc_mgr_flag := check_mgr_rec.manager_flag;
         EXIT;

         END LOOP;

         DEBUG_LOG('Manager Resource'||NVL(lc_mgr_flag, 'N'));    
      
         DEBUG_LOG('Fetching Roles...');
         FOR  roles_rec IN lcu_get_roles
         LOOP
            --ld_bonus_elig_date := NULL;-- 20/12/07 --Commented on 27/02/08
            --lc_attribute_cat   := NULL;-- 21/12/07
            --ln_role_id         := NULL;-- 03/01/08

            DEBUG_LOG('Processing for Role Code: '||roles_rec.role_code);

            IF  roles_rec.attribute14 = 'SALES_SUPPORT'
            AND NVL(lc_mgr_flag, 'N') = 'Y' THEN
 
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0037_SLSSUPPORT_F');
               FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', roles_rec.role_code );
               gc_errbuf := FND_MESSAGE.GET;
               FND_MSG_PUB.add;
               WRITE_LOG(gc_errbuf);

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                  gc_return_status  := 'WARNING';
               END IF;

               IF gc_err_msg IS NOT NULL THEN
                  gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
               ELSE
                  gc_err_msg := gc_errbuf;
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => NULL
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                     ,p_error_message_count     => NULL
                                     ,p_error_message_code      => 'XX_TM_0037_SLSSUPPORT_F'
                                     ,p_error_message           => gc_errbuf
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            ELSE

               lc_role_exists_flag      := 'Y';
               DEBUG_LOG('roles_rec.role_type_code:'||roles_rec.role_type_code);
               -- Commented on 25/02/08(CR BED Grp Mbr Role level)
               /*
               -- Added on 19/12/07
               IF gc_sales_rep_res = 'Y' THEN

                  SET_BONUS_DATE(p_role_type_code     =>roles_rec.role_type_code
                                ,p_bonus_date         =>NULL
                              --  ,p_attribute_cat      =>NULL
                              --  ,x_attribute_category =>lc_attribute_cat
                                ,x_bonus_date         =>ld_bonus_elig_date
                                ,x_err_flag           =>lc_err_flag
                                );

                  IF lc_err_flag = 'Y' THEN
                     gc_return_status  := 'WARNING';
                  END IF;

               END IF;


               DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date);
               DEBUG_LOG('Bonus Eligibility Date:'||ld_bonus_elig_date);

               -- Added on 19/12/07
               -- Commented on 25/02/08(CR BED Grp Mbr Role level)
              */
              DEBUG_LOG('Assigning role:'||roles_rec.role_id||' to the Resource');

              ASSIGN_ROLE_TO_RESOURCE
                 (p_api_version          => 1.0
                 ,p_commit               =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                 ,p_role_resource_type   =>'RS_INDIVIDUAL'
                 ,p_role_resource_id     => gn_resource_id
                 ,p_role_id              => roles_rec.role_id
                 ,p_role_code            => roles_rec.role_code
                 ,p_start_date_active    => gd_job_asgn_date  -- gd_as_of_date
                -- Commented on 25/02/08
                -- ,p_attribute14          => ld_bonus_elig_date
                -- Commented on 25/02/08
                 ,p_attribute14          => NULL
                 --,p_attribute15          => ld_bonus_elig_date -- 28/12/07 -- 08/01/08
                 --,p_attribute_category   => lc_attribute_cat -- 08/01/08
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
                                       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                                       ,p_program_id              => gc_conc_prg_id
                                       ,p_module_name             => GC_MODULE_NAME
                                       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                                       ,p_error_message_count     => ln_msg_count
                                       ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                       ,p_error_message           => lc_msg_data
                                       ,p_error_status            => GC_ERROR_STATUS
                                       ,p_notify_flag             => GC_NOTIFY_FLAG
                                       ,p_error_message_severity  =>'MINOR'
                                       );
               END IF;

            END IF;

         END LOOP;
     
      ELSIF gc_hierarchy_type = 'COLLECTIONS' THEN
      
         FOR  check_sprt_roles_rec IN lcu_check_sprt_roles
         LOOP

            lc_supprt_flag := check_sprt_roles_rec.support_flag;
         EXIT;

         END LOOP;            
      
         DEBUG_LOG('Fetching Roles...');
         FOR  collection_roles_rec IN lcu_get_collection_roles
         LOOP

            DEBUG_LOG('Processing for Role Code: '||collection_roles_rec.role_code);

            IF  collection_roles_rec.attribute14 = 'SALES_SUPPORT'
            AND NVL(lc_supprt_flag, 'N') = 'Y' THEN
 
               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0037_SLSSUPPORT_F');
               FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', collection_roles_rec.role_code );
               gc_errbuf := FND_MESSAGE.GET;
               FND_MSG_PUB.add;
               WRITE_LOG(gc_errbuf);

               IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                  gc_return_status  := 'WARNING';
               END IF;

               IF gc_err_msg IS NOT NULL THEN
                  gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
               ELSE
                  gc_err_msg := gc_errbuf;
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => NULL
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                     ,p_error_message_count     => NULL
                                     ,p_error_message_code      => 'XX_TM_0037_SLSSUPPORT_F'
                                     ,p_error_message           => gc_errbuf
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MINOR'
                                     );

            ELSE

               lc_role_exists_flag      := 'Y';
               DEBUG_LOG('collection_roles_rec.role_type_code:'||collection_roles_rec.role_type_code);
             
               DEBUG_LOG('Assigning role:'||collection_roles_rec.role_id||' to the Resource');

               ASSIGN_ROLE_TO_RESOURCE
                 (p_api_version          => 1.0
                 ,p_commit               =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                 ,p_role_resource_type   =>'RS_INDIVIDUAL'
                 ,p_role_resource_id     => gn_resource_id
                 ,p_role_id              => collection_roles_rec.role_id
                 ,p_role_code            => collection_roles_rec.role_code
                 ,p_start_date_active    => gd_job_asgn_date  -- gd_as_of_date
                -- Commented on 25/02/08
                -- ,p_attribute14          => ld_bonus_elig_date
                -- Commented on 25/02/08
                 ,p_attribute14          => NULL
                 --,p_attribute15          => ld_bonus_elig_date -- 28/12/07 -- 08/01/08
                 --,p_attribute_category   => lc_attribute_cat -- 08/01/08
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
                                       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                                       ,p_program_id              => gc_conc_prg_id
                                       ,p_module_name             => GC_MODULE_NAME
                                       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                                       ,p_error_message_count     => ln_msg_count
                                       ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                       ,p_error_message           => lc_msg_data
                                       ,p_error_status            => GC_ERROR_STATUS
                                       ,p_notify_flag             => GC_NOTIFY_FLAG
                                       ,p_error_message_severity  =>'MINOR'
                                       );
               END IF;

            END IF;

         END LOOP;     
      END IF; -- 24/07/08 -- gc_hierarchy_type = 'SALES'
      
      DEBUG_LOG('After Role Assign Loop');

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
                       --, p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR') --04/DEC/07
                       --, p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR') --04/DEC/07
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       --, p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_attribute15        =>  TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR')-- 24/12/07
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
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSIGN_ROLE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
                     , p_calculate_bonus IN        VARCHAR2 -- 25/02/08
                     , x_return_status  OUT NOCOPY VARCHAR2
                     , x_msg_count      OUT NOCOPY NUMBER
                     , x_msg_data       OUT NOCOPY VARCHAR2
                     )
   IS

      lc_grp_mbr_exists_flag              VARCHAR2(1);
      ln_group_mem_id                     JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_grp_mem_id                       JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;--25/02/08
      lc_error_message                    VARCHAR2(1000);
      lc_return_status                    VARCHAR2(1);
      ld_bonus_elig_date                  DATE;-- 25/02/08(CR BED Grp Mbr Role level)
      lc_attribute14                      JTF_RS_ROLE_RELATIONS.attribute14%TYPE;--25/02/08(CR BED Grp Mbr Role level)
      ln_rol_res_id                       NUMBER;-- 29/02/08
      ln_role_id                          JTF_RS_GROUP_MBR_ROLE_VL.role_id%TYPE;-- 29/02/08
      ln_msg_count                        NUMBER;
      lc_msg_data                         VARCHAR2(1000);

      lc_role_exists_flag                 VARCHAR2(1);
      lc_err_flag                         VARCHAR2(1);--Added on 25/02/08(CR BED Grp Mbr Role level)


      EX_TERMINATE_GRP_ROL_ASGN           EXCEPTION;

      CURSOR  lcu_check_grp_mbr_exists
      IS
      SELECT 'Y' grp_mbr
             ,group_member_id
      FROM    jtf_rs_group_members_vl
      WHERE   resource_id  =  gn_resource_id
      AND     group_id     =  p_group_id
      AND     delete_flag  = 'N';

      -- Fetch only those roles that are currently not assigned to the group

      CURSOR  lcu_get_resource_roles
      IS
      SELECT  JRRR.role_id
             ,JRRV.role_type_code --25/02/08(CR BED Grp Mbr Role level)
             ,JRRV.attribute14
      FROM    jtf_rs_role_relations JRRR
      -- Added on 25/02/08(CR BED Grp Mbr Role level)
             ,jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles JRJR
      -- Added on 25/02/08(CR BED Grp Mbr Role level)
      WHERE   JRRR.role_resource_id = gn_resource_id
      AND     JRRR.role_resource_type = 'RS_INDIVIDUAL' --18/Mar/08
      AND     JRRR.role_id          = JRRV.role_id --25/02/08(CR BED Grp Mbr Role level)
      AND     gd_job_asgn_date  -- gd_as_of_date
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,gd_job_asgn_date)  -- gd_as_of_date)
      AND     NVL(JRRR.delete_flag, 'N') <> 'Y'
      AND     JRRV.role_type_code = 'SALES'
      AND     JRJR.job_id = gn_job_id
      AND     JRJR.role_id = JRRR.role_id
      AND     JRRR.role_id
      NOT IN (SELECT  role_id
              FROM    jtf_rs_group_mbr_role_vl
              WHERE   resource_id = gn_resource_id
              AND     group_id    = p_group_id
              AND     end_date_active IS NULL
              );

      CURSOR  lcu_get_res_details
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
             ,attribute15 -- 29/02/08
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      -- Added on 25/02/08(CR BED Grp Mbr Role level)

      -- Get the Group member role details
      CURSOR lcu_get_mbr_role_details(p_grp_mbr_id IN jtf_rs_group_members.group_member_id%TYPE)
      IS
      SELECT JRRR.attribute14
      FROM   jtf_rs_role_relations JRRR
      WHERE  JRRR.role_resource_id = p_grp_mbr_id
      AND    JRRR.role_id IN
                           (SELECT  role_id
                            FROM    jtf_rs_group_mbr_role_vl
                            WHERE   resource_id  =  gn_resource_id
                            AND     group_id     =  p_group_id
                            AND     end_date_active IS NOT NULL
                           );


      -- Added on 25/02/08(CR BED Grp Mbr Role level)



      lr_res_details  lcu_get_res_details%ROWTYPE;


   BEGIN

      DEBUG_LOG('Inside Proc: ASSGN_GRP_ROLE');
      FOR  grp_mbr_exists_rec IN lcu_check_grp_mbr_exists
      LOOP

         lc_grp_mbr_exists_flag  :=  grp_mbr_exists_rec.grp_mbr;
         ln_grp_mem_id           :=  grp_mbr_exists_rec.group_member_id;
         EXIT;

      END LOOP;

      DEBUG_LOG('Group Membership Exists:'||NVL(lc_grp_mbr_exists_flag,'N'));

      IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN

         DEBUG_LOG('Assigning Resource to the Group Number: '||p_group_number);

         ASSIGN_RES_TO_GRP
               (
                p_api_version          => 1.0
               ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
               ,p_group_id             => p_group_id
               ,p_group_number         => p_group_number
               ,p_resource_id          => gn_resource_id
               ,p_resource_number      => gc_resource_number
               ,x_return_status        => x_return_status
               ,x_msg_count            => x_msg_count
               ,x_msg_data             => x_msg_data
               ,x_group_member_id      => ln_group_mem_id
               );

         ln_grp_mem_id :=ln_group_mem_id;-- 29/02/08


         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);
            DEBUG_LOG('In Procedure:ASSGN_GRP_ROLE: Proc: ASSIGN_RES_TO_GRP Fails');

            gc_return_status      := 'ERROR';

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_msg_data
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );


           RAISE EX_TERMINATE_GRP_ROL_ASGN;

         END IF;

      END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'


      IF p_calculate_bonus = 'Y' THEN

         lc_attribute14 := NULL;

         OPEN   lcu_get_mbr_role_details(ln_grp_mem_id);
         FETCH  lcu_get_mbr_role_details INTO lc_attribute14;
         CLOSE  lcu_get_mbr_role_details;
      END IF;


      FOR  resource_roles_rec IN lcu_get_resource_roles
      LOOP

         lc_role_exists_flag   := 'Y';

         DEBUG_LOG('Assigning Role:'||resource_roles_rec.role_id||'to the Group');

         ASSIGN_ROLE_TO_GROUP
                  (p_role_resource_id => p_group_id
                  ,p_role_id          => resource_roles_rec.role_id
                  ,p_start_date       => gd_job_asgn_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         x_msg_count := ln_msg_count;

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(lc_msg_data);

            DEBUG_LOG('In Procedure:ASSGN_GRP_ROLE: Proc: ASSIGN_ROLE_TO_GROUP Fails for role id:'||resource_roles_rec.role_id);

            IF NVL(gc_return_status,'A') <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => lc_return_status
                                  ,p_msg_count               => ln_msg_count
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                                  ,p_error_message_count     => ln_msg_count
                                  ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                  ,p_error_message           => lc_msg_data
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MINOR'
                                  );

         END IF;

         -- Added on 25/02/08(CR BED Grp Mbr Role level)
         IF p_calculate_bonus = 'Y' THEN

            DEBUG_LOG('lc_attribute14:'||lc_attribute14);
            DEBUG_LOG('ln_grp_mem_id :'||ln_grp_mem_id);

            ld_bonus_elig_date := NULL;
            ln_rol_res_id      := NULL;

            DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');

            IF    gc_job_chng_exists = 'Y' THEN
               ln_rol_res_id    := gn_resource_id;

            ELSIF gc_job_chng_exists = 'N' THEN
               ln_rol_res_id    := ln_grp_mem_id;

            END IF;

            DEBUG_LOG('ln_rol_res_id :'||ln_rol_res_id);

            SET_BONUS_DATE(p_role_type_code     =>resource_roles_rec.role_type_code
                          ,p_bonus_date         =>lc_attribute14
                          ,p_grp_mbr_id         =>ln_grp_mem_id
                          ,p_rol_res_id         =>ln_rol_res_id
                          ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                        --,p_attribute_cat      =>curr_role_rec.attribute_category
                        --,x_attribute_category =>lc_attribute_cat
                          ,x_bonus_date         =>ld_bonus_elig_date
                          ,x_err_flag           =>lc_err_flag
                          );

            IF lc_err_flag = 'Y' THEN
               gc_return_status  := 'WARNING';
            END IF;

         ELSIF p_calculate_bonus = 'N' THEN
             ld_bonus_elig_date := NULL;
         END IF;
         -- Added on 25/02/08(CR BED Grp Mbr Role level)

         -- No PRXY role assignment should happen from here. It should be manually done when asked by business.
         IF NVL(resource_roles_rec.attribute14, 'X') <> GC_PROXY_ROLE THEN
           DEBUG_LOG('Assigning group Role:'||resource_roles_rec.role_id||'to the Resource');
           ASSIGN_RES_TO_GROUP_ROLE
                 (p_api_version          => 1.0
                 ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                 ,p_resource_id          => gn_resource_id
                 ,p_group_id             => p_group_id
                 ,p_role_id              => resource_roles_rec.role_id
                 ,p_start_date           => greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                 /* Commented on 11/Jun/08 since the BED population is taken out 
                 -- Added on 25/Feb/08
                 , p_attribute14         => ld_bonus_elig_date
                 -- Added on 25/Feb/08
                  Commented on 11/Jun/08 since the BED population is taken out
                  */
                 -- Added on 11/Jun/08
                 ,p_attribute14          => NULL
                 -- Added on 11/Jun/08
                 ,x_return_status        => lc_return_status
                 ,x_msg_count            => ln_msg_count
                 ,x_msg_data             => lc_msg_data
                 );

           x_msg_count := ln_msg_count;

           IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

             WRITE_LOG(lc_msg_data);

             DEBUG_LOG('In Procedure:ASSGN_GRP_ROLE:Proc: ASSIGN_RES_TO_GROUP_ROLE Fails for role id:'||resource_roles_rec.role_id);

             IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                gc_return_status  := 'WARNING';
             END IF;

             XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => lc_return_status
                                  ,p_msg_count               => ln_msg_count
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                                  ,p_error_message_count     => ln_msg_count
                                  ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                  ,p_error_message           => lc_msg_data
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MINOR'
                                  );

           END IF;

         END IF;

      END LOOP;    -- End loop, lcu_get_resource_roles

      DEBUG_LOG('Role Exists for the Resource:'||NVL(lc_role_exists_flag,'N'));

      IF (NVL(lc_role_exists_flag,'N')  = 'Y') THEN

         IF lcu_get_res_details%ISOPEN THEN

            CLOSE lcu_get_res_details;

         END IF;

         OPEN  lcu_get_res_details;

         FETCH lcu_get_res_details INTO lr_res_details;

         CLOSE lcu_get_res_details;

         DEBUG_LOG('Inside Proc :ASSGN_GRP_ROLE,Updating the dates for the Resource:'||lr_res_details.resource_number);

         UPDT_DATES_RESOURCE
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lr_res_details.resource_number
                       , p_source_name        =>  lr_res_details.source_name
                       --, p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR')--04/DEC/07
                       --, p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR')--04/DEC/07
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       --, p_attribute15        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')-- 29/02/08
                       , p_attribute15        =>   lr_res_details.attribute15-- 29/02/08
                       , p_object_version_num =>  lr_res_details.object_version_number
                       , x_return_status      =>  x_return_status
                       , x_msg_count          =>  x_msg_count
                       , x_msg_data           =>  x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           WRITE_LOG(x_msg_data);
           DEBUG_LOG('In Procedure: ASSGN_GRP_ROLE: Proc: UPDT_DATES_RESOURCE Fails. ');

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

            RAISE EX_TERMINATE_GRP_ROL_ASGN;

         END IF;


      END IF;  -- END IF, (NVL(lc_role_exists_flag,'N')  = 'Y')

      x_return_status := FND_API.G_RET_STS_SUCCESS;

   EXCEPTION

    WHEN EX_TERMINATE_GRP_ROL_ASGN THEN

      gc_return_status  := 'ERROR';

      DEBUG_LOG('In Procedure: ASSGN_GRP_ROLE: Program Terminated. ');

      x_return_status   := FND_API.G_RET_STS_ERROR;

    WHEN OTHERS THEN

      gc_return_status  := 'ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.ASSGN_GRP_ROLE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );
   END ASSGN_GRP_ROLE;
   
   -- Added on 25/07/08
   -- +===================================================================+
   -- | Name  : PROCESS_COLLECTION_RESOURCES                              |
   -- |                                                                   |
   -- | Description:       This Procedure shall process all the           | 
   -- |                    collections role type memeber resources        |
   -- +===================================================================+

   PROCEDURE PROCESS_COLLECTION_RESOURCES
                                (p_group_id        IN  NUMBER
                                ,p_group_number    IN  VARCHAR2
                                ,x_return_status   OUT NOCOPY VARCHAR2
                                ,x_msg_count       OUT NOCOPY NUMBER
                                ,x_msg_data        OUT NOCOPY VARCHAR2 )
   IS
        lc_error_message           VARCHAR2(1000);     
        ln_group_member_id         JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
        lc_grp_mbr_exists_flag     VARCHAR2(1);
        lc_return_status           VARCHAR2(1);
        ln_msg_count               NUMBER;
        lc_msg_data                VARCHAR2(1000);
        lc_grp_mbrshp_flag         VARCHAR2(1);
  
        lc_other_grpmbr_flag       VARCHAR2(1);
        lc_attribute15             JTF_RS_RESOURCE_EXTNS.attribute15%TYPE;  


  
        EX_TERMINATE_MGR_ASGN      EXCEPTION;       
       
        CURSOR  lcu_check_grp_mbr_exists(p_group_id NUMBER)
        IS
        SELECT 'Y' grp_mbr
               ,group_member_id 
        FROM    JTF_RS_GROUP_MEMBERS_VL
        WHERE   resource_id = gn_resource_id
        AND     group_id    = p_group_id
        AND     delete_flag = 'N';
  
        CURSOR  lcu_get_collection_roles(p_grp_id    NUMBER)
        IS
        SELECT  JRRR.role_id
               ,JRRR.end_date_active                      
        FROM    jtf_rs_role_relations_vl  JRRR
               ,jtf_rs_roles_vl JRRV
        WHERE   JRRR.role_resource_id = gn_resource_id
        AND     JRRV.role_id = JRRR.role_id
        AND     JRRV.role_type_code = 'COLLECTIONS'
        AND     JRRV.role_type_code NOT IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST') -- 28/07/08
        AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                BETWEEN JRRR.start_date_active
                AND     NVL(JRRR.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
        AND     JRRR.role_id NOT IN ( SELECT  role_id
                                      FROM    jtf_rs_group_mbr_role_vl
                                      WHERE   resource_id = gn_resource_id
                                      AND     group_id    = p_grp_id
                                      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                                              BETWEEN start_date_active
                                              AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
                                    );        
  
        CURSOR  lcu_get_mbr_roles(p_grp_id NUMBER)
        IS
        SELECT  role_id
        FROM    jtf_rs_group_mbr_role_vl
        WHERE   group_id    = p_grp_id
        AND     resource_id = gn_resource_id
        AND     (member_flag ='Y'
        OR       admin_flag  = 'Y')
        AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
        BETWEEN start_date_active
        AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
        AND     role_id NOT IN (SELECT  role_id
                                FROM    jtf_rs_role_relations
                                WHERE   role_resource_type = 'RS_GROUP'
                                AND     role_resource_id   =  p_grp_id
                                AND     end_date_active IS NULL
                                AND     delete_flag = 'N'
                               )
        GROUP BY role_id;   
  
        CURSOR  lcu_get_res_details
        IS
        SELECT  resource_number
               ,object_version_number
               ,source_name
               ,attribute15 
        FROM    jtf_rs_resource_extns_vl
        WHERE   resource_id = gn_resource_id;
  
        CURSOR  lcu_check_other_grpmbr(p_grp_id     NUMBER)
                                      
        IS
        SELECT  'Y' other_grmbr_exists
        FROM    jtf_rs_group_mbr_role_vl
        WHERE   resource_id = gn_resource_id
        AND     group_id   <> p_grp_id   
        -- Ignore Proxy roles 01/15/2009
        AND     role_id NOT IN (SELECT role_id from jtf_rs_roles_vl 
                                WHERE NVL(attribute14, 'X') = GC_PROXY_ROLE
                               )     
        AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                BETWEEN start_date_active
                AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date));
            
  
        lr_res_details                lcu_get_res_details%ROWTYPE;

        BEGIN
        
         DEBUG_LOG('Inside Proc: PROCESS_COLLECTION_RESOURCES');
         
         lc_grp_mbr_exists_flag   := NULL;

         IF lcu_check_grp_mbr_exists%ISOPEN THEN
            CLOSE lcu_check_grp_mbr_exists;
         END IF;

         OPEN  lcu_check_grp_mbr_exists(p_group_id);
         FETCH lcu_check_grp_mbr_exists INTO lc_grp_mbr_exists_flag,ln_group_member_id;
         CLOSE lcu_check_grp_mbr_exists;

         DEBUG_LOG('Group Membership Exists:'||NVL(lc_grp_mbr_exists_flag,'N'));

	 IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN 	          
            
            DEBUG_LOG('Calling ASSIGN_RES_TO_GRP:Start');
            ASSIGN_RES_TO_GRP
               (
                p_api_version          => 1.0
               ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
               ,p_group_id             => p_group_id
               ,p_group_number         => p_group_number
               ,p_resource_id          => gn_resource_id
               ,p_resource_number      => gc_resource_number
               ,x_return_status        => x_return_status
               ,x_msg_count            => x_msg_count
               ,x_msg_data             => x_msg_data
               ,x_group_member_id      => ln_group_member_id
               ); 

           DEBUG_LOG('Calling ASSIGN_RES_TO_GRP:End');

             IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               WRITE_LOG(x_msg_data);

               DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Proc: ASSIGN_RES_TO_GRP Fails');

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => x_return_status
                                  ,p_msg_count               => x_msg_count
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                  ,p_error_message_count     => x_msg_count
                                  ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                  ,p_error_message           => x_msg_data
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );

               RAISE EX_TERMINATE_MGR_ASGN;

             ELSE

              DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Proc: ASSIGN_RES_TO_GRP Success ');

            END IF;
         ELSE
            DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Resource is already and member of Group.');
            
         END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'        
         
         IF lcu_check_other_grpmbr%ISOPEN THEN
  
          CLOSE lcu_check_other_grpmbr;
  
         END IF;
  
         OPEN lcu_check_other_grpmbr(p_grp_id  => p_group_id);
  
         FETCH lcu_check_other_grpmbr INTO lc_other_grpmbr_flag;
  
         CLOSE lcu_check_other_grpmbr;
  
         DEBUG_LOG('Other Group Membership Exists:'||NVL(lc_other_grpmbr_flag,'N'));
         IF (NVL(lc_other_grpmbr_flag,'N') = 'Y') THEN
  
  
           FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0102_GRPMBR_OVERLAP');
           lc_error_message    := FND_MESSAGE.GET;
           FND_MSG_PUB.add;
  
           WRITE_LOG(lc_error_message);
  
           IF gc_err_msg IS NOT NULL THEN
              gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
           ELSE
              gc_err_msg := lc_error_message;
           END IF;
  
           XX_COM_ERROR_LOG_PUB.log_error_crm(
                               p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                              ,p_msg_count               => 1
                              ,p_application_name        => GC_APPN_NAME
                              ,p_program_type            => GC_PROGRAM_TYPE
                              ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                              ,p_program_id              => gc_conc_prg_id
                              ,p_module_name             => GC_MODULE_NAME
                              ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                              ,p_error_message_count     => 1
                              ,p_error_message_code      =>'XX_TM_0102_GRPMBR_OVERLAP'
                              ,p_error_message           => lc_error_message
                              ,p_error_status            => GC_ERROR_STATUS
                              ,p_notify_flag             => GC_NOTIFY_FLAG
                              ,p_error_message_severity  =>'MAJOR'
                              );
  
           RAISE EX_TERMINATE_MGR_ASGN;  
  
     END IF;
     
     FOR  get_collection_roles_rec IN lcu_get_collection_roles(p_group_id)
     LOOP    
        
        DEBUG_LOG('Processing Group Member Role Id: '||get_collection_roles_rec.role_id);

        lc_grp_mbrshp_flag := 'Y';

        ASSIGN_RES_TO_GROUP_ROLE
              (p_api_version       => 1.0
              ,p_commit            => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
              ,p_resource_id       => gn_resource_id
              ,p_group_id          => p_group_id
              ,p_role_id           => get_collection_roles_rec.role_id
              ,p_start_date        => greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              ,p_end_date          => get_collection_roles_rec.end_date_active
              ,p_attribute14       => NULL
              ,x_return_status     => lc_return_status
              ,x_msg_count         => ln_msg_count
              ,x_msg_data          => lc_msg_data
              );

         x_msg_count := ln_msg_count;

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(lc_msg_data);
            DEBUG_LOG('Assigning group Role:'||get_collection_roles_rec.role_id||'to the Resource');

            IF NVL(gc_return_status,'A') <> 'ERROR' THEN

               gc_return_status := 'WARNING';

            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                    p_return_code             => lc_return_status
                                   ,p_msg_count               => ln_msg_count
                                   ,p_application_name        => GC_APPN_NAME
                                   ,p_program_type            => GC_PROGRAM_TYPE
                                   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                   ,p_program_id              => gc_conc_prg_id
                                   ,p_module_name             => GC_MODULE_NAME
                                   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                   ,p_error_message_count     => ln_msg_count
                                   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                   ,p_error_message           => lc_msg_data
                                   ,p_error_status            => GC_ERROR_STATUS
                                   ,p_notify_flag             => GC_NOTIFY_FLAG
                                   ,p_error_message_severity  =>'MINOR'
                                   );

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Proc: CREATE_GROUP_MEMBERSHIP Success to MGR group for role id: '||get_collection_roles_rec.role_id);

         END IF;

     END LOOP;    -- End loop, lcu_get_collection_roles
     
      IF (NVL(lc_grp_mbrshp_flag,'N') = 'Y') THEN

         IF lcu_get_res_details%ISOPEN THEN

            CLOSE lcu_get_res_details;

         END IF;

         OPEN  lcu_get_res_details;
         FETCH lcu_get_res_details INTO lr_res_details;
         CLOSE lcu_get_res_details;

         DEBUG_LOG('In Proc,PROCESS_NONMANAGER_ASSIGNMENTS : Calling Proc to Update Reource Dates.');
    
         IF gc_mgr_matches_flag = 'N' OR gc_resource_exists = 'N' THEN
           lc_attribute15 := TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR');
         ELSE
           lc_attribute15 := lr_res_details.attribute15;
         END IF;
    
         UPDT_DATES_RESOURCE
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lr_res_details.resource_number
                       , p_source_name        =>  lr_res_details.source_name                      
                       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                       , p_attribute15        =>  lc_attribute15 
                       , p_object_version_num =>  lr_res_details.object_version_number
                       , x_return_status      =>  x_return_status
                       , x_msg_count          =>  x_msg_count
                       , x_msg_data           =>  x_msg_data
                       );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);
            DEBUG_LOG('In Procedure: PROCESS_COLLECTION_RESOURCES: Proc: UPDT_DATES_RESOURCE Fails. ');

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

            RAISE EX_TERMINATE_MGR_ASGN;

         END IF;


      END IF; -- END IF, NVL(lc_grp_mbrshp_flag,'N') = 'Y'


      DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Processing Group Role Assignments');

      FOR  mbr_role_rec IN lcu_get_mbr_roles(p_group_id)
      LOOP
 
         DEBUG_LOG('For Sales Roles: Calling Proc ASSIGN_ROLE_TO_GROUP');

         ASSIGN_ROLE_TO_GROUP
                  (p_role_resource_id => p_group_id
                  ,p_role_id          => mbr_role_rec.role_id
                  ,p_start_date       => gd_mgr_asgn_date
                  ,x_return_status    => lc_return_status
                  ,x_msg_count        => ln_msg_count
                  ,x_msg_data         => lc_msg_data
                  );

         x_msg_count := ln_msg_count;

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(lc_msg_data);
            DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Proc: ASSIGN_ROLE_TO_GROUP Fails for role id:'||mbr_role_rec.role_id);

            IF NVL(gc_return_status,'A') <> 'ERROR' THEN
              gc_return_status  := 'WARNING';
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                    p_return_code             => lc_return_status
                                   ,p_msg_count               => ln_msg_count
                                   ,p_application_name        => GC_APPN_NAME
                                   ,p_program_type            => GC_PROGRAM_TYPE
                                   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                   ,p_program_id              => gc_conc_prg_id
                                   ,p_module_name             => GC_MODULE_NAME
                                   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                                   ,p_error_message_count     => ln_msg_count
                                   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                   ,p_error_message           => lc_msg_data
                                   ,p_error_status            => GC_ERROR_STATUS
                                   ,p_notify_flag             => GC_NOTIFY_FLAG
                                   ,p_error_message_severity  =>'MINOR'
                                   );

         ELSE

            DEBUG_LOG('In Procedure:PROCESS_COLLECTION_RESOURCES: Proc: ASSIGN_ROLE_TO_GROUP Success, for Group-role, for role id: '||mbr_role_rec.role_id);

         END IF;

      END LOOP;     
     
     
   EXCEPTION

     WHEN OTHERS THEN

       x_return_status      := FND_API.G_RET_STS_ERROR;
       gc_return_status     :='ERROR';
       x_msg_data := SQLERRM;
       WRITE_LOG(x_msg_data);

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
       gc_errbuf := FND_MESSAGE.GET;

       IF gc_err_msg IS NOT NULL THEN
          gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
       ELSE
          gc_err_msg := gc_errbuf;
       END IF;

       XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_COLLECTION_RESOURCES'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

   END PROCESS_COLLECTION_RESOURCES;      
   -- Added on 25/07/08

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

      CURSOR   lcu_check_salesrep
      IS
      SELECT  'Y' sales_rep_flag
      FROM     jtf_rs_salesreps
      WHERE    resource_id = gn_resource_id;

      CURSOR  lcu_get_group_details
      IS
      SELECT  group_id
             ,group_number
      FROM    jtf_rs_groups_vl
      WHERE   group_name = p_group_name
      -- 31/12/07
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
      BETWEEN start_date_active
      AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date));
      -- 31/12/07;

      group_details_rec             lcu_get_group_details%ROWTYPE;

      EX_TERMINATE_ASGN             EXCEPTION;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_GENERIC_RES_DETAILS');

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
                                 ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_GENERIC_RES_DETAILS'
                                 ,p_program_id              => gc_conc_prg_id
                                 ,p_module_name             => GC_MODULE_NAME
                                 ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_GENERIC_RES_DETAILS'
                                 ,p_error_message_count     => x_msg_count
                                 ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                 ,p_error_message           => x_msg_data
                                 ,p_error_status            => GC_ERROR_STATUS
                                 ,p_notify_flag             => GC_NOTIFY_FLAG
                                 ,p_error_message_severity  =>'MINOR'
                                 );

         END IF;

      END IF; -- End if, NVL(lc_sales_rep_flag,'N') = 'Y'

      DEBUG_LOG('Assign Resource Roles');
      ASSIGN_ROLE
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

      IF  lcu_get_group_details%ISOPEN THEN
         CLOSE lcu_get_group_details;
      END IF;

      OPEN  lcu_get_group_details;
      FETCH lcu_get_group_details INTO group_details_rec;
      CLOSE lcu_get_group_details;

      DEBUG_LOG('Assign Resource Groups Roles');
      ASSGN_GRP_ROLE
               ( p_group_id         => group_details_rec.group_id
               , p_group_number     => group_details_rec.group_number
               , p_calculate_bonus  => 'N'--25/02/08
               , x_return_status    => x_return_status
               , x_msg_count        => x_msg_count
               , x_msg_data         => x_msg_data
               );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            DEBUG_LOG('In Procedure:PROCESS_GENERIC_RES_DETAILS: Proc: ASSGN_GRP_ROLE Fails. ');

            IF NVL(gc_return_status,'A') <> 'ERROR' THEN
               gc_return_status  := 'WARNING';
            END IF;

            RAISE EX_TERMINATE_ASGN;

         END IF;

      x_return_status   :=    FND_API.G_RET_STS_SUCCESS;

   EXCEPTION

    WHEN EX_TERMINATE_ASGN THEN

      DEBUG_LOG('In Procedure:PROCESS_GENERIC_RES_DETAILS: Program Terminated. ');

      x_return_status   := FND_API.G_RET_STS_ERROR;

      gc_return_status    :='ERROR';

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_GENERIC_RES_DETAILS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_GENERIC_RES_DETAILS'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
      DEBUG_LOG('Inside Proc: PROCESS_SALES_ADMIN');
      PROCESS_GENERIC_RES_DETAILS
                     (p_group_name      => GC_OD_SALES_ADMIN_GRP
                     ,x_return_status   => x_return_status
                     ,x_msg_count       => x_msg_count
                     ,x_msg_data        => x_msg_data
                     );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

         DEBUG_LOG('In Procedure:PROCESS_SALES_ADMIN: Proc: Process_Generic_Res_Details Fails. ');
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
          gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
       ELSE
          gc_err_msg := gc_errbuf;
       END IF;

       XX_COM_ERROR_LOG_PUB.log_error_crm(
                           p_return_code             => x_return_status
                          ,p_msg_count               => 1
                          ,p_application_name        => GC_APPN_NAME
                          ,p_program_type            => GC_PROGRAM_TYPE
                          ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_ADMIN'
                          ,p_program_id              => gc_conc_prg_id
                          ,p_module_name             => GC_MODULE_NAME
                          ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_ADMIN'
                          ,p_error_message_count     => 1
                          ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                          ,p_error_message           => x_msg_data
                          ,p_error_status            => GC_ERROR_STATUS
                          ,p_notify_flag             => GC_NOTIFY_FLAG
                          ,p_error_message_severity  =>'MAJOR'
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

      DEBUG_LOG('Inside Proc: PROCESS_SALES_COMP_ANALYST');
      PROCESS_GENERIC_RES_DETAILS
                     (p_group_name      => GC_OD_PAYMENT_ANALYST_GRP
                     ,x_return_status   => x_return_status
                     ,x_msg_count       => x_msg_count
                     ,x_msg_data        => x_msg_data
                     );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

           DEBUG_LOG('In Procedure:PROCESS_SALES_COMP_ANALYST: Proc: Process_Generic_Res_Details Fails. ');

      END IF;

   EXCEPTION

     WHEN OTHERS THEN

       x_return_status      := FND_API.G_RET_STS_ERROR;
       gc_return_status     :='ERROR';
       x_msg_data := SQLERRM;
       WRITE_LOG(x_msg_data);

       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
       gc_errbuf := FND_MESSAGE.GET;

       IF gc_err_msg IS NOT NULL THEN
          gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
       ELSE
          gc_err_msg := gc_errbuf;
       END IF;

       XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_COMP_ANALYST'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_COMP_ANALYST'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_msg_data
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
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
      ln_crm_grp_mem_id          JTF_RS_GROUP_MBR_ROLE_VL.group_member_id%  TYPE;--29/02/08
      ln_spt_grp_id              NUMBER;
      lc_spt_grp_number          VARCHAR2(100);
      lc_grp_mbr_exists_flag     VARCHAR2(1);
      lc_spt_role_flag           VARCHAR2(1);
      lc_return_status           VARCHAR2(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(1000);
      lc_grp_mbrshp_flag         VARCHAR2(1);
      lc_dat_chk_flag1           VARCHAR2(1);-- 18/Mar/08
      lc_dat_chk_flag2           VARCHAR2(1);-- 18/Mar/08

      lc_other_grpmbr_flag       VARCHAR2(1);
      lc_attribute15             JTF_RS_RESOURCE_EXTNS.attribute15%TYPE;

      -- Added on 25/02/08(CR BED Grp Mbr Role level)
      ln_sales_group_mem_id      JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_suprt_group_mem_id      JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_bed_sales_group_mem_id  JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_bed_suprt_group_mem_id  JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;
      ln_group_member_id         JTF_RS_GROUP_MEMBERS_VL.group_member_id%  TYPE;-- 29/02/08
      ln_rol_res_id              NUMBER;
      ld_bonus_elig_date         DATE;
      lc_err_flag                VARCHAR2(1);      
      
      -- Added on 25/02/08(CR BED Grp Mbr Role level)

      EX_TERMINATE_MGR_ASGN      EXCEPTION;


      CURSOR  lcu_get_source_mgr_id
      IS
      SELECT  supervisor_id
      FROM    per_all_assignments_f
      WHERE   primary_flag = 'Y'
      AND     person_id    = gn_person_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      /*
      CURSOR  lcu_get_mgr_id
      IS
      SELECT  JRRE.source_id
      FROM    jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_resource_extns_vl JRRE
      WHERE   JRGMR.manager_flag = 'Y'
      AND     gd_mgr_asgn_date
              BETWEEN  JRGMR.start_date_active
              AND      NVL(JRGMR.end_date_active,gd_mgr_asgn_date)
      AND     JRGMR.group_id IN (
                                 SELECT group_id
                                 FROM   jtf_rs_group_mbr_role_vl JRGM
                                 WHERE  JRGM.resource_id = gn_resource_id
                                 AND    gd_mgr_asgn_date -1
                                        BETWEEN  JRGM.start_date_active
                                            AND  NVL(JRGM.end_date_active,gd_mgr_asgn_date -1 )
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
      */
      -- 13/03/08(Name mismatch problem)
      CURSOR  lcu_get_mgr_id
      IS
      SELECT  PAPF.person_id
      FROM    jtf_rs_groups_vl JRGV
             ,per_all_people_f PAPF
      WHERE   JRGV.attribute15 = PAPF.person_id
      AND     JRGV.group_id IN (
                                 SELECT group_id
                                 FROM   jtf_rs_group_mbr_role_vl JRGM
                                 WHERE  JRGM.resource_id = gn_resource_id
                                 /*AND    gd_mgr_asgn_date -1
                                        BETWEEN  JRGM.start_date_active
                                            AND  NVL(JRGM.end_date_active,gd_mgr_asgn_date -1 )
                                 */
                                   AND    greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                                        BETWEEN  JRGM.start_date_active
                                            AND  NVL(JRGM.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
                                 AND    group_id NOT IN
                                        (SELECT  group_id
                                         FROM    jtf_rs_groups_vl
                                         WHERE   group_name IN
                                                                ('OD_SALES_ADMIN_GRP'
                                                                ,'OD_PAYMENT_ANALYST_GRP'
                                                                ,'OD_SUPPORT_GRP'
                                                                )
                                        )
                                 AND    role_id NOT IN (SELECT role_id from jtf_rs_roles_vl 
                                                        WHERE attribute14 = GC_PROXY_ROLE
                                                       )  
                             );

      -- 13/03/08

      -- 29/02/08
      CURSOR  lcu_get_old_mgr_grp_mem_id
      IS
      SELECT group_member_id
      FROM   jtf_rs_group_mbr_role_vl JRGM
      WHERE  JRGM.resource_id = gn_resource_id
      AND    gd_mgr_asgn_date -1
           BETWEEN  JRGM.start_date_active
            AND  NVL(JRGM.end_date_active,gd_mgr_asgn_date -1 )
      AND    group_id NOT IN
                    (SELECT  group_id
                     FROM    jtf_rs_groups_vl
                     WHERE   group_name IN
                                ('OD_SALES_ADMIN_GRP'
                                ,'OD_PAYMENT_ANALYST_GRP'
                                ,'OD_SUPPORT_GRP'
                                )
        );

      -- 29/02/08


      /*
      CURSOR  lcu_get_mgr_grp
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
      AND     gd_mgr_asgn_date
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,gd_mgr_asgn_date)
      AND     gd_mgr_asgn_date
              BETWEEN JRGMR.start_date_active
              AND     NVL(JRGMR.end_date_active,gd_mgr_asgn_date);
      */
      -- 13/03/08(Name mismatch problem)
      CURSOR  lcu_get_mgr_grp
      IS
      SELECT  JRGV.group_id
             ,JRGV.group_number
      FROM    per_all_assignments_f    PAAF
             ,jtf_rs_groups_vl         JRGV
      WHERE   PAAF.person_id              = gn_person_id
      AND     PAAF.business_group_id      = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN PAAF.effective_start_date
              AND     NVL(PAAF.effective_end_date,gd_as_of_date)
      AND     JRGV.attribute15            = PAAF.supervisor_id
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date));
      -- 13/03/08(Name mismatch problem)

      CURSOR  lcu_check_support_role
      IS
      SELECT 'Y' SUPPORT_EXISTS
      FROM    DUAL
      WHERE   EXISTS
             (SELECT  1
              FROM    jtf_rs_role_relations_vl JRRR
                     ,jtf_rs_roles_vl  JRRV
                     ,jtf_rs_job_roles_vl JRJV
              WHERE   JRRR.role_resource_id = gn_resource_id
              AND     JRRR.role_id     = JRRV.role_id
              AND     JRRV.attribute14 = 'SALES_SUPPORT'
              AND     JRJV.role_id = JRRV.role_id
              AND     JRJV.job_id = gn_job_id
             /*   19/12/07
              AND     gd_mgr_asgn_date
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,gd_mgr_asgn_date)
             );
             */ -- 19/12/07
              AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
              );
      CURSOR  lcu_check_grp_mbr_exists(p_group_id NUMBER)
      IS
      SELECT 'Y' grp_mbr
             ,group_member_id -- 29/02/08
      FROM    JTF_RS_GROUP_MEMBERS_VL
      WHERE   resource_id = gn_resource_id
      AND     group_id    = p_group_id
      AND     delete_flag = 'N';

      CURSOR  lcu_get_suprt_grp_details
      IS
      SELECT  group_id
             ,group_number
      FROM    jtf_rs_groups_vl
      WHERE   group_name = GC_OD_SUPPORT_GRP
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)   --18/12/07
              BETWEEN start_date_active
              AND     NVL(END_DATE_ACTIVE,greatest(gd_job_asgn_date,gd_mgr_asgn_date)); --18/12/07


      CURSOR  lcu_get_sales_roles(p_grp_id    NUMBER)
      IS
      SELECT  JRRR.role_id
             ,JRRR.end_date_active
             -- Added on 25/02/08(CR BED Grp Mbr Role level)
             ,JRRV.role_type_code
             -- Added on 25/02/08(CR BED Grp Mbr Role level)
      FROM    jtf_rs_role_relations  JRRR
             ,jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles_vl JRJV
      WHERE   JRRR.role_resource_id = gn_resource_id
      AND     NVL(JRRR.delete_flag, 'N') <> 'Y'
      AND     JRRV.role_id = JRRR.role_id
      AND     JRRV.role_type_code = 'SALES'
      AND     JRJV.role_id = JRRR.role_id
      AND     NVL(JRRV.attribute14, 'X') <> GC_PROXY_ROLE
      AND     JRJV.job_id = gn_job_id
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
      AND     JRRR.role_id NOT IN ( SELECT  role_id
                                    FROM    jtf_rs_group_mbr_role_vl
                                    WHERE   resource_id = gn_resource_id
                                    AND     group_id    = p_grp_id
                                    AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                                            BETWEEN start_date_active
                                            AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
                                  );

      CURSOR  lcu_get_sales_comp_roles(p_grp_id    NUMBER)
      IS
      SELECT  JRRR.role_id
             ,JRRR.end_date_active
             -- Added on 25/02/08(CR BED Grp Mbr Role level)
             ,JRRV.role_type_code
             -- Added on 25/02/08(CR BED Grp Mbr Role level)
      FROM    jtf_rs_role_relations  JRRR
             ,jtf_rs_roles_vl JRRV
             ,jtf_rs_job_roles_vl JRJV
      WHERE   JRRR.role_resource_id = gn_resource_id
      AND     NVL(JRRR.delete_flag, 'N') <> 'Y'
      AND     JRRV.role_id = JRRR.role_id
      AND     JRRV.role_type_code = 'SALES_COMP'
      AND     JRJV.role_id = JRRR.role_id
      AND     JRJV.job_id = gn_job_id
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN JRRR.start_date_active
              AND     NVL(JRRR.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
      AND     JRRR.role_id NOT IN ( SELECT  role_id
                                    FROM    jtf_rs_group_mbr_role_vl
                                    WHERE   resource_id = gn_resource_id
                                    AND     group_id    = p_grp_id
                                    AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
                                            BETWEEN start_date_active
                                            AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
                                  );


      CURSOR  lcu_get_mbr_roles(p_grp_id NUMBER)
      IS
      SELECT  JRRR.role_id
      FROM    jtf_rs_group_mbr_role_vl JRRR
              ,jtf_rs_job_roles_vl JRJV
      WHERE   JRRR.group_id    = p_grp_id
      AND     JRRR.resource_id = gn_resource_id
      AND     JRRR.member_flag ='Y'
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
      BETWEEN JRRR.start_date_active
      AND     NVL(JRRR.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date))
      AND     JRJV.role_id = JRRR.role_id
      AND     JRJV.job_id = gn_job_id
      AND     JRRR.role_id NOT IN (SELECT  role_id
                                   FROM    jtf_rs_role_relations
                                   WHERE   role_resource_type = 'RS_GROUP'
                                   AND     role_resource_id   =  p_grp_id
                                   AND     end_date_active IS NULL
                                   AND     delete_flag = 'N'
                                  )
      GROUP BY JRRR.role_id;

      CURSOR  lcu_get_mbr_sc_roles(p_grp_id NUMBER)
      IS
      SELECT  JRGMR.role_id
      FROM    jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_roles_vl  JRRV
             ,jtf_rs_job_roles_vl JRJV
      WHERE   JRGMR.group_id    = p_grp_id
      AND     JRRV.role_id      = JRGMR.role_id
      AND     JRRV.role_type_code = 'SALES_COMP'
      AND     JRGMR.resource_id = gn_resource_id
      AND     JRGMR.member_flag ='Y'
      AND     gd_mgr_asgn_date
      BETWEEN JRGMR.start_date_active
      AND     NVL(JRGMR.end_date_active,gd_mgr_asgn_date)
      AND     JRJV.role_id = JRRV.role_id
      AND     JRJV.job_id = gn_job_id
      AND     JRGMR.role_id NOT IN (SELECT  role_id
                                    FROM    jtf_rs_role_relations
                                    WHERE   role_resource_type = 'RS_GROUP'
                                    AND     role_resource_id   =  p_grp_id
                                    AND     end_date_active    IS NULL
                                    AND     delete_flag = 'N'
                                   )
      GROUP BY JRGMR.role_id;


      CURSOR  lcu_get_res_details
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
             ,attribute15 -- 24/12/07
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      CURSOR  lcu_check_other_grpmbr(p_grp_id     NUMBER
                                    ,p_spt_grp_id NUMBER)
      IS
      SELECT  'Y' other_grmbr_exists
      FROM    jtf_rs_group_mbr_role_vl
      WHERE   resource_id = gn_resource_id
      AND     group_id   <> p_grp_id
      AND     group_id   <> NVL(p_spt_grp_id,-1)
      -- Ignore Proxy roles 01/15/2009
      AND     role_id NOT IN (SELECT role_id from jtf_rs_roles_vl 
                              WHERE NVL(attribute14, 'X') = GC_PROXY_ROLE
                             )
      /*AND     gd_mgr_asgn_date
              BETWEEN start_date_active
              AND     NVL(end_date_active,gd_mgr_asgn_date);*/
      -- Added on 21/12/07
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN start_date_active
              AND     NVL(end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date));
      -- Added on 21/12/07      

      lr_res_details                lcu_get_res_details%ROWTYPE;
      lr_mgr_grp                    lcu_get_mgr_grp%ROWTYPE;
      lr_suprt_grp                  lcu_get_suprt_grp_details%ROWTYPE;

   BEGIN

      DEBUG_LOG('Inside Proc: Process_NonManager_Assignments');

      gc_mgr_matches_flag := NULL;
      lc_attribute15      := NULL;

      IF lcu_get_source_mgr_id%ISOPEN THEN
         CLOSE lcu_get_source_mgr_id;
      END IF;

      OPEN  lcu_get_source_mgr_id;
      FETCH lcu_get_source_mgr_id INTO ln_source_mgr_id;
      CLOSE lcu_get_source_mgr_id;

      DEBUG_LOG('Source Manager ID: '||ln_source_mgr_id);

      IF lcu_get_mgr_id%ISOPEN THEN
         CLOSE lcu_get_mgr_id;
      END IF;

      OPEN  lcu_get_mgr_id;
      FETCH lcu_get_mgr_id INTO ln_crm_mgr_id;-- 29/02/08
      CLOSE lcu_get_mgr_id;

      DEBUG_LOG('CRM Manager ID: '||ln_crm_mgr_id);

      OPEN  lcu_get_old_mgr_grp_mem_id;
      FETCH lcu_get_old_mgr_grp_mem_id INTO ln_crm_grp_mem_id;-- 29/02/08
      CLOSE lcu_get_old_mgr_grp_mem_id;

      IF NVL(ln_crm_mgr_id,ln_source_mgr_id) <> ln_source_mgr_id THEN
         lc_mgr_matches_flag := 'N';
      ELSE
         lc_mgr_matches_flag := 'Y';
      END IF;    
      
      -- Added on 18/Mar/08
      IF lc_mgr_matches_flag = 'N' THEN

         IF gd_mgr_asgn_date >= gd_job_asgn_date THEN  -- Changed check from > to >= (as manager can start on the same date)

            lc_dat_chk_flag1  := 'Y';
         ELSE

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0260_INV_MGR_ASGN_DT');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0260_INV_MGR_ASGN_DT'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );
            lc_dat_chk_flag1 := 'N';

          END IF;

          IF gd_mgr_asgn_date >=  greatest(gd_crm_job_asgn_date,gd_crm_mgr_asgn_date) THEN

             lc_dat_chk_flag2 := 'Y';
          ELSE
             /* Code Commented on 01/15/2009 as error check is no longer needed and handled in retro logic
             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0261_INV_MAGR_ASGN_DT');
             lc_error_message    := FND_MESSAGE.GET;
             FND_MSG_PUB.add;
             WRITE_LOG(lc_error_message);

             IF gc_err_msg IS NOT NULL THEN
                gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
             ELSE
                gc_err_msg := lc_error_message;
             END IF;

             XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                                ,p_msg_count               => 1 --x_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                ,p_error_message_count     => 1 --x_msg_count
                                ,p_error_message_code      =>'XX_TM_0261_INV_MAGR_ASGN_DT'
                                ,p_error_message           => lc_error_message
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MAJOR'
                                );
             */
             lc_dat_chk_flag2  := 'Y'; -- Changed from 'N' on 01/15/2009 as this should not be an error with retro logic

           END IF;

           IF lc_dat_chk_flag1 = 'Y' AND lc_dat_chk_flag2 = 'Y' THEN

              lc_mgr_matches_flag := 'N';

           ELSE
              lc_mgr_matches_flag := 'Y';
              RAISE EX_TERMINATE_MGR_ASGN;
           END IF;
      END IF;

      DEBUG_LOG('lc_mgr_matches_flag: '||lc_mgr_matches_flag);

      -- Added on 18/Mar/08
      gc_mgr_matches_flag := NVL(lc_mgr_matches_flag,'Y');-- 29/02/08

      IF NVL(lc_mgr_matches_flag,'Y') = 'N' THEN

         ln_group_id := -1;

         DEBUG_LOG('Manager Changes Exists.');

         END_GRP_AND_RESGRPROLE
                     (p_group_id        => ln_group_id,
                      p_end_date        => gd_mgr_asgn_date -1,
                      x_return_status   => x_return_status,
                      x_msg_count       => x_msg_count,
                      x_msg_data        => x_msg_data
                     );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Fails');

         ELSE
           DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Success');

         END IF;

      ELSIF NVL(lc_mgr_matches_flag,'Y') = 'Y' THEN

         DEBUG_LOG('Manager Changes does not Exists.');

      END IF;

      IF lcu_get_mgr_grp%ISOPEN THEN
         CLOSE lcu_get_mgr_grp;
      END IF;

      OPEN  lcu_get_mgr_grp;
      FETCH lcu_get_mgr_grp INTO lr_mgr_grp;
      CLOSE lcu_get_mgr_grp;

      ln_group_id      :=  lr_mgr_grp.group_id;
      lc_group_number  :=  lr_mgr_grp.group_number;

      DEBUG_LOG('Manager Group id:'||ln_group_id);
      DEBUG_LOG('Manager Group Number:'||lc_group_number);

      IF ln_group_id IS NULL OR lc_group_number IS NULL THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0049_NO_MANAGER_GRP');
         FND_MESSAGE.SET_TOKEN('P_DATE',gd_mgr_asgn_date);
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            => 'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0049_NO_MANAGER_GRP'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

          RAISE EX_TERMINATE_MGR_ASGN;

      END IF;  -- END IF, ln_group_id IS NULL OR ln_group_number IS NULL

      IF gc_hierarchy_type = 'SALES' THEN
	      IF lcu_check_support_role%ISOPEN THEN
		CLOSE lcu_check_support_role;
	      END IF;

	      OPEN  lcu_check_support_role;
	      FETCH lcu_check_support_role INTO lc_spt_role_flag;
	      CLOSE lcu_check_support_role;

	      DEBUG_LOG('Support Role Exists:'||NVL(lc_spt_role_flag,'N'));

	      IF lcu_check_grp_mbr_exists%ISOPEN THEN

		 CLOSE lcu_check_grp_mbr_exists;
	      END IF;

	      ln_group_member_id := NULL;-- 29/02/08

	      OPEN  lcu_check_grp_mbr_exists(ln_group_id);
	      FETCH lcu_check_grp_mbr_exists INTO lc_grp_mbr_exists_flag,ln_group_member_id;
	      CLOSE lcu_check_grp_mbr_exists;
	      DEBUG_LOG('lc_grp_mbr_exists_flag:'||lc_grp_mbr_exists_flag);


	      DEBUG_LOG('Processing for default Sales Group Assignment');
	      IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN      

		DEBUG_LOG('Assign Resource to Group Number: '||lc_group_number);

		ASSIGN_RES_TO_GRP
		    (
		     p_api_version          => 1.0
		    ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
		    ,p_group_id             => ln_group_id
		    ,p_group_number         => lc_group_number
		    ,p_resource_id          => gn_resource_id
		    ,p_resource_number      => gc_resource_number
		    ,x_return_status        => x_return_status
		    ,x_msg_count            => x_msg_count
		    ,x_msg_data             => x_msg_data
		    ,x_group_member_id      => ln_group_mem_id
		    );

		 -- Added on 25/02/08(CR BED Grp Mbr Role level)
		    ln_sales_group_mem_id:= ln_group_mem_id;
		 -- Added on 25/02/08(CR BED Grp Mbr Role level)

		 IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		    WRITE_LOG(x_msg_data);
		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Fails to assign to Sales Support Group');

		    XX_COM_ERROR_LOG_PUB.log_error_crm(
					p_return_code             => x_return_status
				       ,p_msg_count               => x_msg_count
				       ,p_application_name        => GC_APPN_NAME
				       ,p_program_type            => GC_PROGRAM_TYPE
				       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				       ,p_program_id              => gc_conc_prg_id
				       ,p_module_name             => GC_MODULE_NAME
				       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				       ,p_error_message_count     => x_msg_count
				       ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
				       ,p_error_message           => x_msg_data
				       ,p_error_status            => GC_ERROR_STATUS
				       ,p_notify_flag             => GC_NOTIFY_FLAG
				       ,p_error_message_severity  =>'MAJOR'
				       );

		    RAISE EX_TERMINATE_MGR_ASGN;

		 ELSE

		   DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Success');

		 END IF;

	      ELSE
		 DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Resource is already a member of Group.');

		 -- Added on 29/02/08(CR BED Grp Mbr Role level)
		    ln_sales_group_mem_id:= ln_group_member_id;
		 -- Added on 29/02/08(CR BED Grp Mbr Role level)

	      END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'

	      -- Sales support group assignment

	      IF  ( NVL (lc_spt_role_flag,'N')  = 'Y' ) THEN

		 DEBUG_LOG('Processing for Sales support group assignment');

		 IF lcu_get_suprt_grp_details%ISOPEN THEN
		    CLOSE lcu_get_suprt_grp_details;
		 END IF;

		 OPEN  lcu_get_suprt_grp_details;
		 FETCH lcu_get_suprt_grp_details INTO lr_suprt_grp;
		 CLOSE lcu_get_suprt_grp_details;

		 ln_spt_grp_id            := lr_suprt_grp.group_id;
		 lc_spt_grp_number        := lr_suprt_grp.group_number;

		 DEBUG_LOG('Support Group Id:'||ln_spt_grp_id);
		 DEBUG_LOG('Support Group Number:'||lc_spt_grp_number);

		 lc_grp_mbr_exists_flag   := NULL;

		 IF lcu_check_grp_mbr_exists%ISOPEN THEN
		    CLOSE lcu_check_grp_mbr_exists;
		 END IF;

		 OPEN  lcu_check_grp_mbr_exists(ln_spt_grp_id);
		 FETCH lcu_check_grp_mbr_exists INTO lc_grp_mbr_exists_flag,ln_group_member_id;
		 CLOSE lcu_check_grp_mbr_exists;

		 DEBUG_LOG('Group Membership Exists:'||NVL(lc_grp_mbr_exists_flag,'N'));

		 IF NVL(lc_grp_mbr_exists_flag,'N') <> 'Y' THEN -- 24/06/08	          

		    DEBUG_LOG('Calling ASSIGN_RES_TO_GRP:Start');
		    ASSIGN_RES_TO_GRP
		       (
			p_api_version          => 1.0
		       ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
		       ,p_group_id             => ln_spt_grp_id
		       ,p_group_number         => lc_spt_grp_number
		       ,p_resource_id          => gn_resource_id
		       ,p_resource_number      => gc_resource_number
		       ,x_return_status        => x_return_status
		       ,x_msg_count            => x_msg_count
		       ,x_msg_data             => x_msg_data
		       ,x_group_member_id      => ln_group_mem_id
		       );

		   -- Added on 25/02/08(CR BED Grp Mbr Role level)
		      ln_suprt_group_mem_id:= ln_group_mem_id;
		   -- Added on 25/02/08(CR BED Grp Mbr Role level)

		   DEBUG_LOG('Calling ASSIGN_RES_TO_GRP:End');

		     IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		       WRITE_LOG(x_msg_data);

		       DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Fails');

		       XX_COM_ERROR_LOG_PUB.log_error_crm(
					   p_return_code             => x_return_status
					  ,p_msg_count               => x_msg_count
					  ,p_application_name        => GC_APPN_NAME
					  ,p_program_type            => GC_PROGRAM_TYPE
					  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					  ,p_program_id              => gc_conc_prg_id
					  ,p_module_name             => GC_MODULE_NAME
					  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					  ,p_error_message_count     => x_msg_count
					  ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
					  ,p_error_message           => x_msg_data
					  ,p_error_status            => GC_ERROR_STATUS
					  ,p_notify_flag             => GC_NOTIFY_FLAG
					  ,p_error_message_severity  =>'MAJOR'
					  );

		       RAISE EX_TERMINATE_MGR_ASGN;

		     ELSE

		      DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_RES_TO_GRP Success while validating lc_spt_role_flag = Y');

		    END IF;
		 ELSE
		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Resource is already and member of Group.');

		    -- Added on 29/02/08(CR BED Grp Mbr Role level)
		       ln_suprt_group_mem_id:= ln_group_member_id;
		    -- Added on 29/02/08(CR BED Grp Mbr Role level)

		 END IF;  -- END IF, NVL(lc_grp_mbr_exists,'N') <> 'Y'

	     END IF;  -- END IF, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

	     -- Sales support group assignment

	     IF lcu_check_other_grpmbr%ISOPEN THEN

		CLOSE lcu_check_other_grpmbr;

	     END IF;

	     OPEN lcu_check_other_grpmbr(p_grp_id     => ln_group_id
					,p_spt_grp_id => ln_spt_grp_id);

	     FETCH lcu_check_other_grpmbr INTO lc_other_grpmbr_flag;

	     CLOSE lcu_check_other_grpmbr;

	     DEBUG_LOG('Other Group Membership Exists:'||NVL(lc_other_grpmbr_flag,'N'));
	     IF (NVL(lc_other_grpmbr_flag,'N') = 'Y') THEN


		 FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0102_GRPMBR_OVERLAP');
		 lc_error_message    := FND_MESSAGE.GET;
		 FND_MSG_PUB.add;

		 WRITE_LOG(lc_error_message);

		 IF gc_err_msg IS NOT NULL THEN
		    gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
		 ELSE
		    gc_err_msg := lc_error_message;
		 END IF;

		 XX_COM_ERROR_LOG_PUB.log_error_crm(
				     p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
				    ,p_msg_count               => 1
				    ,p_application_name        => GC_APPN_NAME
				    ,p_program_type            => GC_PROGRAM_TYPE
				    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				    ,p_program_id              => gc_conc_prg_id
				    ,p_module_name             => GC_MODULE_NAME
				    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				    ,p_error_message_count     => 1
				    ,p_error_message_code      =>'XX_TM_0102_GRPMBR_OVERLAP'
				    ,p_error_message           => lc_error_message
				    ,p_error_status            => GC_ERROR_STATUS
				    ,p_notify_flag             => GC_NOTIFY_FLAG
				    ,p_error_message_severity  =>'MAJOR'
				    );

		 RAISE EX_TERMINATE_MGR_ASGN;


	     END IF;

	     DEBUG_LOG('End of Group Membership Processing. Start of Group Member Roles Processing');

	     DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Processing Group Member Roles (Default Sales)');

	     FOR  resource_roles_rec IN lcu_get_sales_roles(ln_group_id)
	     LOOP

		DEBUG_LOG('Processing Group Member Role Id: '||resource_roles_rec.role_id);

		lc_grp_mbrshp_flag := 'Y';

		-- Added on 25/02/08(CR BED Grp Mbr Role level)
		ld_bonus_elig_date        := NULL;
		ln_rol_res_id             := NULL;
		ln_bed_sales_group_mem_id := NULL;

		DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');
		DEBUG_LOG('gc_job_chng_exists:1:'||gc_job_chng_exists);

		IF    gc_job_chng_exists = 'Y' THEN
		   ln_rol_res_id             := gn_resource_id;
		   ln_bed_sales_group_mem_id := ln_sales_group_mem_id;

		ELSIF gc_job_chng_exists = 'N' AND gc_mgr_matches_flag = 'N' THEN
		   ln_rol_res_id             := ln_crm_grp_mem_id;
		   ln_bed_sales_group_mem_id := ln_crm_grp_mem_id;

		ELSE
		   ln_rol_res_id             := ln_sales_group_mem_id;
		   ln_bed_sales_group_mem_id := ln_sales_group_mem_id;

		END IF;

		DEBUG_LOG('ln_bed_sales_group_mem_id:1:'||ln_bed_sales_group_mem_id);
		DEBUG_LOG('ln_rol_res_id:1:'||ln_rol_res_id);


		SET_BONUS_DATE(p_role_type_code     =>resource_roles_rec.role_type_code
			      ,p_bonus_date         =>NULL
			      ,p_grp_mbr_id         =>ln_bed_sales_group_mem_id
			      ,p_rol_res_id         =>ln_rol_res_id
			      ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date)
			      --,p_attribute_cat      =>curr_role_rec.attribute_category
			      --,x_attribute_category =>lc_attribute_cat
			      ,x_bonus_date         =>ld_bonus_elig_date
			      ,x_err_flag           =>lc_err_flag
			      );

		IF lc_err_flag = 'Y' THEN
		   gc_return_status  := 'WARNING';
		END IF;
		-- Added on 25/02/08(CR BED Grp Mbr Role level)


		ASSIGN_RES_TO_GROUP_ROLE
		      (p_api_version       => 1.0
		      ,p_commit            => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
		      ,p_resource_id       => gn_resource_id
		      ,p_group_id          => ln_group_id
		      ,p_role_id           => resource_roles_rec.role_id
		      ,p_start_date        => greatest(gd_job_asgn_date,gd_mgr_asgn_date)
		      ,p_end_date          => resource_roles_rec.end_date_active
		      /* Commented on 11/Jun/08 since the BED population is taken out
		      -- Added on 25/Feb/08
		      , p_attribute14      => ld_bonus_elig_date
		      -- Added on 25/Feb/08
		      Commented on 11/Jun/08 since the BED population is taken out
		      */
		      -- Added on 11/Jun/08
		      ,p_attribute14          => NULL
		      -- Added on 11/Jun/08
		      ,x_return_status     => lc_return_status
		      ,x_msg_count         => ln_msg_count
		      ,x_msg_data          => lc_msg_data
		      );

		 x_msg_count := ln_msg_count;

		 IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		    WRITE_LOG(lc_msg_data);
		    DEBUG_LOG('Assigning group Role:'||resource_roles_rec.role_id||'to the Resource');

		    IF NVL(gc_return_status,'A') <> 'ERROR' THEN

		       gc_return_status := 'WARNING';

		    END IF;

		    XX_COM_ERROR_LOG_PUB.log_error_crm(
					    p_return_code             => lc_return_status
					   ,p_msg_count               => ln_msg_count
					   ,p_application_name        => GC_APPN_NAME
					   ,p_program_type            => GC_PROGRAM_TYPE
					   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_program_id              => gc_conc_prg_id
					   ,p_module_name             => GC_MODULE_NAME
					   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_error_message_count     => ln_msg_count
					   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
					   ,p_error_message           => lc_msg_data
					   ,p_error_status            => GC_ERROR_STATUS
					   ,p_notify_flag             => GC_NOTIFY_FLAG
					   ,p_error_message_severity  =>'MINOR'
					   );

		 ELSE

		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to MGR group for role id: '||resource_roles_rec.role_id);

		 END IF;

	     END LOOP;    -- End loop, lcu_get_sales_roles

	     IF  ( NVL (lc_spt_role_flag,'N')  = 'Y' ) THEN

		DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Processing Group Member Roles (Sales Comp-Support)');

		FOR  resource_roles_rec IN lcu_get_sales_comp_roles(ln_spt_grp_id)
		LOOP

		   DEBUG_LOG('Processing Group Member Role Id: '||resource_roles_rec.role_id);

		   lc_grp_mbrshp_flag := 'Y';

		   -- Added on 25/02/08(CR BED Grp Mbr Role level)
		   ld_bonus_elig_date     := NULL;
		   ln_rol_res_id          := NULL;
		   ln_suprt_group_mem_id  := NULL;

		   DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');
		   DEBUG_LOG('gc_job_chng_exists:2:'||gc_job_chng_exists);

		   IF    gc_job_chng_exists = 'Y' THEN
		      ln_rol_res_id             := gn_resource_id;
		      ln_bed_suprt_group_mem_id := ln_suprt_group_mem_id;

		   ELSIF gc_job_chng_exists = 'N' AND gc_mgr_matches_flag = 'N' THEN
		      ln_rol_res_id             := ln_crm_grp_mem_id;
		      ln_bed_suprt_group_mem_id := ln_crm_grp_mem_id;

		   ELSE
		      ln_rol_res_id             := ln_suprt_group_mem_id;
		      ln_bed_suprt_group_mem_id := ln_suprt_group_mem_id;

		   END IF;


		   DEBUG_LOG('ln_bed_suprt_group_mem_id:2:'||ln_bed_suprt_group_mem_id);
		   DEBUG_LOG('ln_rol_res_id:2:'||ln_rol_res_id);


		   SET_BONUS_DATE(p_role_type_code     =>resource_roles_rec.role_type_code
				 ,p_bonus_date         =>NULL
				 ,p_grp_mbr_id         =>ln_bed_suprt_group_mem_id
				 ,p_rol_res_id         =>ln_rol_res_id
				 ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date)
				 --,p_attribute_cat      =>curr_role_rec.attribute_category
				 --,x_attribute_category =>lc_attribute_cat
				 ,x_bonus_date         =>ld_bonus_elig_date
				 ,x_err_flag           =>lc_err_flag
				 );

		   IF lc_err_flag = 'Y' THEN
		      gc_return_status  := 'WARNING';
		   END IF;

		   -- Added on 25/02/08(CR BED Grp Mbr Role level)


		   ASSIGN_RES_TO_GROUP_ROLE --CREATE_GROUP_MEMBERSHIP
			 (p_api_version          => 1.0
			 ,p_commit               => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
			 ,p_resource_id          => gn_resource_id
			 ,p_group_id             => ln_spt_grp_id
			 ,p_role_id              => resource_roles_rec.role_id
			 ,p_start_date           => greatest(gd_job_asgn_date,gd_mgr_asgn_date)
			 ,p_end_date             => resource_roles_rec.end_date_active
			 /* Commented on 11/Jun/08 since the BED population is taken out
			 -- Added on 25/Feb/08
			 , p_attribute14        => ld_bonus_elig_date
			 -- Added on 25/Feb/08
			 Commented on 11/Jun/08 since the BED population is taken out
			 */
			 -- Added on 11/Jun/08
			 ,p_attribute14          => NULL
			 -- Added on 11/Jun/08
			 ,x_return_status        => lc_return_status
			 ,x_msg_count            => ln_msg_count
			 ,x_msg_data             => lc_msg_data
			 );

		    x_msg_count := ln_msg_count;

		    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		       WRITE_LOG(lc_msg_data);
		       DEBUG_LOG('Assigning group Role:'||resource_roles_rec.role_id||'to the Resource');

		       IF NVL(gc_return_status,'A') <> 'ERROR' THEN

			  gc_return_status := 'WARNING';

		       END IF;

		       XX_COM_ERROR_LOG_PUB.log_error_crm(
					       p_return_code             => lc_return_status
					      ,p_msg_count               => ln_msg_count
					      ,p_application_name        => GC_APPN_NAME
					      ,p_program_type            => GC_PROGRAM_TYPE
					      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					      ,p_program_id              => gc_conc_prg_id
					      ,p_module_name             => GC_MODULE_NAME
					      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					      ,p_error_message_count     => ln_msg_count
					      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
					      ,p_error_message           => lc_msg_data
					      ,p_error_status            => GC_ERROR_STATUS
					      ,p_notify_flag             => GC_NOTIFY_FLAG
					      ,p_error_message_severity  =>'MINOR'
					      );

		    ELSE

		      DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to Sales Support group assignment for Role id: '||resource_roles_rec.role_id);

		    END IF;

		END LOOP;    -- End loop, lcu_get_sales_comp_roles

	     ELSE   -- ELSE, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

		DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Processing Group Member Roles (Sales Comp - Non Support)');
		FOR  sales_comp_roles_rec IN lcu_get_sales_comp_roles(ln_group_id)
		LOOP

		   DEBUG_LOG('Processing Group Member Role Id: '||sales_comp_roles_rec.role_id);
		   lc_grp_mbrshp_flag := 'Y';

		   -- Added on 25/02/08(CR BED Grp Mbr Role level)
		   ld_bonus_elig_date        := NULL;
		   ln_rol_res_id             := NULL;
		   ln_bed_sales_group_mem_id := NULL;

		   DEBUG_LOG('Calling Procedure:SET_BONUS_DATE');
		   DEBUG_LOG('gc_job_chng_exists:3:'||gc_job_chng_exists);


		   IF    gc_job_chng_exists = 'Y' THEN
		      ln_rol_res_id             := gn_resource_id;
		      ln_bed_sales_group_mem_id := ln_sales_group_mem_id;

		   ELSIF gc_job_chng_exists = 'N' AND gc_mgr_matches_flag = 'N' THEN
		      ln_rol_res_id             := ln_crm_grp_mem_id;
		      ln_bed_sales_group_mem_id := ln_crm_grp_mem_id;

		   ELSE
		      ln_rol_res_id             := ln_sales_group_mem_id;
		      ln_bed_sales_group_mem_id := ln_sales_group_mem_id;

		   END IF;


		   DEBUG_LOG('ln_bed_sales_group_mem_id:3:'||ln_bed_sales_group_mem_id);
		   DEBUG_LOG('ln_rol_res_id:3:'||ln_rol_res_id);


		   SET_BONUS_DATE(p_role_type_code     =>sales_comp_roles_rec.role_type_code
				 ,p_bonus_date         =>NULL
				 ,p_grp_mbr_id         =>ln_bed_sales_group_mem_id
				 ,p_rol_res_id         =>ln_rol_res_id
				 ,p_grp_mbr_role_date  =>greatest(gd_job_asgn_date,gd_mgr_asgn_date)
				 --,p_attribute_cat      =>curr_role_rec.attribute_category
				 --,x_attribute_category =>lc_attribute_cat
				 ,x_bonus_date         =>ld_bonus_elig_date
				 ,x_err_flag           =>lc_err_flag
				 );

		   IF lc_err_flag = 'Y' THEN
		      gc_return_status  := 'WARNING';
		   END IF;

		   -- Added on 25/02/08(CR BED Grp Mbr Role level)


		   ASSIGN_RES_TO_GROUP_ROLE
			 (p_api_version          => 1.0
			 ,p_commit               =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
			 ,p_resource_id          => gn_resource_id
			 ,p_group_id             => ln_group_id
			 ,p_role_id              => sales_comp_roles_rec.role_id
			 ,p_start_date           => greatest(gd_job_asgn_date,gd_mgr_asgn_date)
			 ,p_end_date             => sales_comp_roles_rec.end_date_active
			 /* Commented on 11/Jun/08 since the BED population is taken out
			 -- Added on 25/Feb/08
			 , p_attribute14        => ld_bonus_elig_date
			 -- Added on 25/Feb/08
			 Commented on 11/Jun/08 since the BED population is taken out
			 */
			 -- Added on 11/Jun/08
			 ,p_attribute14          => NULL
			 -- Added on 11/Jun/08
			 ,x_return_status        => lc_return_status
			 ,x_msg_count            => ln_msg_count
			 ,x_msg_data             => lc_msg_data
			 );

		    x_msg_count := ln_msg_count;

		    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		       WRITE_LOG(lc_msg_data);
		       DEBUG_LOG('Assigning group Role:'||sales_comp_roles_rec.role_id||'to the Resource');

		       IF NVL(gc_return_status,'A') <> 'ERROR' THEN

			  gc_return_status := 'WARNING';

		       END IF;

		       XX_COM_ERROR_LOG_PUB.log_error_crm(
					       p_return_code             => lc_return_status
					      ,p_msg_count               => ln_msg_count
					      ,p_application_name        => GC_APPN_NAME
					      ,p_program_type            => GC_PROGRAM_TYPE
					      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					      ,p_program_id              => gc_conc_prg_id
					      ,p_module_name             => GC_MODULE_NAME
					      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					      ,p_error_message_count     => ln_msg_count
					      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
					      ,p_error_message           => lc_msg_data
					      ,p_error_status            => GC_ERROR_STATUS
					      ,p_notify_flag             => GC_NOTIFY_FLAG
					      ,p_error_message_severity  =>'MINOR'
					      );

		    ELSE

		      DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_MEMBERSHIP Success to MGR group for role id: '||sales_comp_roles_rec.role_id);

		    END IF;

		 END LOOP;    -- End loop, lcu_get_sales_roles

	      END IF;   -- END IF, ( NVL (lc_spt_role_flag,'N')  = 'Y' )

	      IF (NVL(lc_grp_mbrshp_flag,'N') = 'Y') THEN

		 IF lcu_get_res_details%ISOPEN THEN

		    CLOSE lcu_get_res_details;

		 END IF;

		 OPEN  lcu_get_res_details;
		 FETCH lcu_get_res_details INTO lr_res_details;
		 CLOSE lcu_get_res_details;

		 DEBUG_LOG('In Proc,PROCESS_NONMANAGER_ASSIGNMENTS : Calling Proc to Update Reource Dates.');
		 -- Added on 24/12/07
		 IF gc_mgr_matches_flag = 'N' OR gc_resource_exists = 'N' THEN
		   lc_attribute15 := TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR');
		 ELSE
		   lc_attribute15 := lr_res_details.attribute15;
		 END IF;
		 -- Added on 24/12/07

		 UPDT_DATES_RESOURCE
			       ( p_resource_id        =>  gn_resource_id
			       , p_resource_number    =>  lr_res_details.resource_number
			       , p_source_name        =>  lr_res_details.source_name
			       --, p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR') --04/DEC/07
			       --, p_attribute15        =>  TO_CHAR(gd_mgr_asgn_date,'MM/DD/RRRR') --04/DEC/07
			       , p_attribute14        =>  TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
			       --, p_attribute15        =>  TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR')     -- 24/12/07
			       , p_attribute15        =>  lc_attribute15 -- 24/12/07
			       , p_object_version_num =>  lr_res_details.object_version_number
			       , x_return_status      =>  x_return_status
			       , x_msg_count          =>  x_msg_count
			       , x_msg_data           =>  x_msg_data
			       );

		 IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		    WRITE_LOG(x_msg_data);
		    DEBUG_LOG('In Procedure: PROCESS_NONMANAGER_ASSIGNMENTS: Proc: UPDT_DATES_RESOURCE Fails. ');

		    XX_COM_ERROR_LOG_PUB.log_error_crm(
				     p_return_code             => x_return_status
				    ,p_msg_count               => x_msg_count
				    ,p_application_name        => GC_APPN_NAME
				    ,p_program_type            => GC_PROGRAM_TYPE
				    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				    ,p_program_id              => gc_conc_prg_id
				    ,p_module_name             => GC_MODULE_NAME
				    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
				    ,p_error_message_count     => x_msg_count
				    ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
				    ,p_error_message           => x_msg_data
				    ,p_error_status            => GC_ERROR_STATUS
				    ,p_notify_flag             => GC_NOTIFY_FLAG
				    ,p_error_message_severity  =>'MAJOR'
				    );

		    RAISE EX_TERMINATE_MGR_ASGN;

		 END IF;


	      END IF; -- END IF, NVL(lc_grp_mbrshp_flag,'N') = 'Y'


	      DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Processing Group Role Assignments');

	      FOR  mbr_role_rec IN lcu_get_mbr_roles(ln_group_id)
	      LOOP

		 DEBUG_LOG('For Sales Roles: Calling Proc ASSIGN_ROLE_TO_GROUP');

		 ASSIGN_ROLE_TO_GROUP
			  (p_role_resource_id => ln_group_id
			  ,p_role_id          => mbr_role_rec.role_id
			  ,p_start_date       => gd_mgr_asgn_date
			  ,x_return_status    => lc_return_status
			  ,x_msg_count        => ln_msg_count
			  ,x_msg_data         => lc_msg_data
			  );

		 x_msg_count := ln_msg_count;

		 IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		    WRITE_LOG(lc_msg_data);
		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Fails for role id:'||mbr_role_rec.role_id);

		    IF NVL(gc_return_status,'A') <> 'ERROR' THEN
		      gc_return_status  := 'WARNING';
		    END IF;

		    XX_COM_ERROR_LOG_PUB.log_error_crm(
					    p_return_code             => lc_return_status
					   ,p_msg_count               => ln_msg_count
					   ,p_application_name        => GC_APPN_NAME
					   ,p_program_type            => GC_PROGRAM_TYPE
					   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_program_id              => gc_conc_prg_id
					   ,p_module_name             => GC_MODULE_NAME
					   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_error_message_count     => ln_msg_count
					   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
					   ,p_error_message           => lc_msg_data
					   ,p_error_status            => GC_ERROR_STATUS
					   ,p_notify_flag             => GC_NOTIFY_FLAG
					   ,p_error_message_severity  =>'MINOR'
					   );

		 ELSE

		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Success, for Group-role, for role id: '||mbr_role_rec.role_id);

		 END IF;

	      END LOOP;

	      FOR  mbr_role_sc_rec IN lcu_get_mbr_sc_roles(ln_spt_grp_id)
	      LOOP

		 DEBUG_LOG('For Sales Comp Roles: Calling Proc ASSIGN_ROLE_TO_GROUP');
		 ASSIGN_ROLE_TO_GROUP
			  (p_role_resource_id => ln_spt_grp_id
			  ,p_role_id          => mbr_role_sc_rec.role_id
			  ,p_start_date       => gd_mgr_asgn_date
			  ,x_return_status    => lc_return_status
			  ,x_msg_count        => ln_msg_count
			  ,x_msg_data         => lc_msg_data
			  );

		  x_msg_count := ln_msg_count;

		 IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

		    WRITE_LOG(lc_msg_data);
		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Fails for role id:'||mbr_role_sc_rec.role_id);

		    IF NVL(gc_return_status,'A') <> 'ERROR' THEN
		      gc_return_status  := 'WARNING';
		    END IF;

		    XX_COM_ERROR_LOG_PUB.log_error_crm(
					    p_return_code             => lc_return_status
					   ,p_msg_count               => ln_msg_count
					   ,p_application_name        => GC_APPN_NAME
					   ,p_program_type            => GC_PROGRAM_TYPE
					   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_program_id              => gc_conc_prg_id
					   ,p_module_name             => GC_MODULE_NAME
					   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
					   ,p_error_message_count     => ln_msg_count
					   ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
					   ,p_error_message           => lc_msg_data
					   ,p_error_status            => GC_ERROR_STATUS
					   ,p_notify_flag             => GC_NOTIFY_FLAG
					   ,p_error_message_severity  =>'MINOR'
					   );

		 ELSE

		    DEBUG_LOG('In Procedure:PROCESS_NONMANAGER_ASSIGNMENTS: Proc: ASSIGN_ROLE_TO_GROUP Support Grp Success, for Group-role, for role id: '||mbr_role_sc_rec.role_id);

		 END IF;
		 
	      END LOOP;
      ELSIF gc_hierarchy_type = 'COLLECTIONS' THEN	      
         
            PROCESS_COLLECTION_RESOURCES
                                (ln_group_id       
                                ,lc_group_number   
                                ,x_return_status   
                                ,x_msg_count       
                                ,x_msg_data   
                                );            
                                
            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               RAISE EX_TERMINATE_MGR_ASGN;
            END IF;
            
      END IF; -- gc_hierarchy_type = 'SALES'      
 
      x_return_status := FND_API.G_RET_STS_SUCCESS;


   EXCEPTION

      WHEN EX_TERMINATE_MGR_ASGN THEN

      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0045_MGR_ASGN_TERMINATE');
      gc_errbuf := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    :='ERROR';
      WRITE_LOG(gc_errbuf);

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => x_return_status
                            ,p_msg_count               => x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                            ,p_error_message_count     => x_msg_count
                            ,p_error_message_code      => 'XX_TM_0045_MGR_ASGN_TERMINATE'
                            ,p_error_message           => gc_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NONMANAGER_ASSIGNMENTS'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
      lc_group_name               jtf_rs_groups_vl.group_name%TYPE;
      lc_group_desc               jtf_rs_groups_vl.group_desc%TYPE;
      ld_group_start_date         jtf_rs_groups_vl.start_date_active%TYPE;
      ln_obj_ver_num              jtf_rs_groups_vl.object_version_number%TYPE;
      lc_error_message            VARCHAR2(1000);
      lc_vp_flag                  VARCHAR2(1);
      ln_mgr_grp_id               jtf_rs_groups_vl.group_id%TYPE;
      lc_mgr_group_number         jtf_rs_groups_vl.group_number%TYPE;
      ld_mgr_group_start          DATE;
      ld_mgr_group_end            DATE;
      lc_reln_exist_flag          VARCHAR2(1);
      ln_group_relate_id          JTF_RS_GRP_RELATIONS.group_relate_id%TYPE;
      lc_return_status            VARCHAR2(1);
      ln_msg_count                NUMBER;
      lc_msg_data                 VARCHAR2(1000);
      lc_last_name                per_all_people_f.full_name%TYPE;

      EX_TERMINATE_MGR_ASGN       EXCEPTION;


      --CURSOR  lcu_check_group_exists(p_emp_number VARCHAR2)
      CURSOR  lcu_check_group_exists
      IS
      SELECT 'Y' group_exists
             ,group_id
             ,group_number
             ,group_name
             ,group_desc
             ,start_date_active
             ,object_version_number
      FROM    jtf_rs_groups_vl
      --WHERE   group_name = 'OD_GRP_'||p_emp_number;
      WHERE   attribute15  = gn_person_id;--13/03/08(Name mismatch problem)

      CURSOR  lcu_check_is_vp
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
                      OR     JRLV.role_type_code   ='SALES_COMP'
                      OR     JRLV.role_type_code   ='COLLECTIONS') -- 24/07/08
                     AND     JRLV.role_id          = JRRB.role_id
                     AND     JRRBD.row_id          = JRRB.rowid
                     AND     JRRBD.od_role_code    ='VP'
                     AND     JRLV.role_resource_id = gn_resource_id
                     AND     NVL(JRRB.active_flag,'N') = 'Y'
                     AND     gd_job_asgn_date BETWEEN JRLV.start_date_active                     -- Sep 19, Chk VP only for
                                              AND     NVL(JRLV.end_date_active,gd_job_asgn_date) -- current asgn only
                    );
     /*Commented on 13/03/08(Name mismatch problem)
      CURSOR  lcu_get_mgr_grp
      IS
      SELECT  JRGM.group_id
             ,JRGV.group_number
      FROM    per_all_assignments_f    PAAF
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
      AND     gd_job_asgn_date
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,gd_job_asgn_date )
      AND     gd_job_asgn_date
              BETWEEN JRGMR.start_date_active
              AND     NVL(JRGMR.end_date_active,gd_job_asgn_date);
     */
      --Added on 13/03/08(Name mismatch problem)

      CURSOR  lcu_get_mgr_grp
      IS
      SELECT  JRGV.group_id
             ,JRGV.group_number
             ,JRGV.start_date_active
             ,JRGV.end_date_active
      FROM    per_all_assignments_f    PAAF
             ,jtf_rs_groups_vl         JRGV
      WHERE   PAAF.person_id              = gn_person_id
      AND     PAAF.business_group_id      = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN PAAF.effective_start_date
              AND     NVL(PAAF.effective_end_date,gd_as_of_date)
      AND     JRGV.attribute15            = PAAF.supervisor_id
      AND     greatest(gd_job_asgn_date,gd_mgr_asgn_date)
              BETWEEN JRGV.start_date_active
              AND     NVL(JRGV.end_date_active,greatest(gd_job_asgn_date,gd_mgr_asgn_date));

      --Added on 13/03/08(Name mismatch problem)

      CURSOR  lcu_check_relation(p_group_id    NUMBER
                                ,p_mgr_grp_id  NUMBER
                                )
      IS
      SELECT 'Y' RELN_EXISTS
             ,group_relate_id
             ,start_date_active
			 ,end_date_active         --Defect 11701 - added this, to be used in the fix.
             ,object_version_number
      FROM    jtf_rs_grp_relations
      WHERE   group_id         = p_group_id
      AND     related_group_id = p_mgr_grp_id
      AND     relation_type = 'PARENT_GROUP'
      AND     delete_flag   = 'N';
/*
      AND     gd_mgr_asgn_date
              BETWEEN start_date_active
              AND     NVL(end_date_active,gd_mgr_asgn_date);
*/

      CURSOR  lcu_get_old_relation(p_group_id       NUMBER
                                  ,p_prnt_group_id  NUMBER
                                  )
      IS
      SELECT  related_group_id
             ,group_relate_id
             ,object_version_number
             ,start_date_active
             ,end_date_active
      FROM    jtf_rs_grp_relations_vl
      WHERE   group_id          = p_group_id
      AND     related_group_id <> p_prnt_group_id
      AND     delete_flag   = 'N'
      AND     relation_type = 'PARENT_GROUP'
      AND     end_date_active IS NULL;

      CURSOR  lcu_get_res_details
      IS
      SELECT  resource_number
             ,object_version_number
             ,source_name
             --,TO_DATE(attribute14,'MM/DD/RRRR') JOB_ASGN_DATE --04/DEC/07
             --,TO_DATE(attribute15,'MM/DD/RRRR') MGR_ASGN_DATE --04/DEC/07
             ,TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
             ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      lr_check_relation         lcu_check_relation%ROWTYPE;

      lr_res_details            lcu_get_res_details%ROWTYPE;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS');

      lc_last_name := substr(gc_full_name,1,instr(gc_full_name,',') - 1);

      --(Name mismatch problem)13/03/08
      --FOR  check_group_exists_rec IN lcu_check_group_exists(lc_last_name||'_'||gc_employee_number)
      FOR  check_group_exists_rec IN lcu_check_group_exists
      LOOP

        lc_grp_exist_flag := check_group_exists_rec.group_exists;
        ln_group_id       := check_group_exists_rec.group_id;
        lc_group_number   := check_group_exists_rec.group_number;
        lc_group_name     := check_group_exists_rec.group_name;
        lc_group_desc     := check_group_exists_rec.group_desc;
        ld_group_start_date := check_group_exists_rec.start_date_active;
        ln_obj_ver_num    := check_group_exists_rec.object_version_number;

        EXIT;

      END LOOP;

      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. lc_grp_exist_flag = '||lc_grp_exist_flag);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. ln_group_id = '||ln_group_id);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. lc_group_number = '||lc_group_number);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. lc_group_name = '||lc_group_name);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. lc_group_desc = '||lc_group_desc);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. ld_group_start_date = '||ld_group_start_date);
      DEBUG_LOG('Inside Proc: PROCESS_MANAGER_ASSIGNMENTS. ln_obj_ver_num = '||ln_obj_ver_num);


      IF ( NVL(lc_grp_exist_flag, 'N') <> 'Y' ) THEN

         CREATE_GROUP
            (p_api_version         => 1.0
            ,p_commit              => FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
            ,p_group_name          => 'OD_GRP_'||lc_last_name||'_'||gc_employee_number
            ,p_group_desc          => 'OD_GRP_'||lc_last_name||'_'||gc_employee_number
            ,p_exclusive_flag      => 'N'
            ,p_email_address       => NULL
            ,p_start_date_active   => GD_DEFAULT_GROUP_START_DATE --gd_job_asgn_date  -- gd_as_of_date
            ,p_end_date_active     => NULL
            ,p_accounting_code     => NULL
            --Added on 13/03/08(Name mismatch problem)
            ,p_attribute15         => gn_person_id
            --Added on 13/03/08(Name mismatch problem)
            ,x_return_status       => x_return_status
            ,x_msg_count           => x_msg_count
            ,x_msg_data            => x_msg_data
            ,x_group_id            => ln_group_id
            ,x_group_number        => lc_group_number
            );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            WRITE_LOG(x_msg_data);
            DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP Fails');

            gc_return_status  := 'ERROR';

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => x_return_status
                               ,p_msg_count               => x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                               ,p_error_message_count     => x_msg_count
                               ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                               ,p_error_message           => x_msg_data
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );


            RAISE EX_TERMINATE_MGR_ASGN;

         ELSE

           DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP Success, GROUP NUMBER: '||lc_group_number);

         END IF;



      ELSIF (gd_job_asgn_date < ld_group_start_date) THEN  -- ELSE, ( NVL(lc_grp_exist_flag, 'N') <> 'Y' )

         GROUP_BACK_DATE
                     (p_group_id           => ln_group_id
                     ,p_group_number       => lc_group_number
                     ,p_start_date         => gd_job_asgn_date
                     ,p_object_version_num => ln_obj_ver_num
                     ,x_return_status      => x_return_status
                     ,x_msg_count          => x_msg_count
                     ,x_msg_data           => x_msg_data
                     );

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           WRITE_LOG(x_msg_data);
           DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: GROUP_BACK_DATE Fails');

           gc_return_status  := 'WARNING';

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => x_msg_count
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_error_message_count     => x_msg_count
                           ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MINOR'
                           );
       END IF;
      -- If group owner name changed because of marriage, divorce etc.
      ELSIF (NVL(lc_group_name, 'XX') <> 'OD_GRP_'||lc_last_name||'_'||gc_employee_number) OR 
            (NVL(lc_group_desc, 'XX') <> 'OD_GRP_'||lc_last_name||'_'||gc_employee_number) THEN 

         UPDATE_GROUP_NAME
                     (p_group_id           => ln_group_id
                     ,p_group_number       => lc_group_number
                     ,p_group_name         => 'OD_GRP_'||lc_last_name||'_'||gc_employee_number
                     ,p_group_desc         => 'OD_GRP_'||lc_last_name||'_'||gc_employee_number
                     ,p_object_version_num => ln_obj_ver_num
                     ,x_return_status      => x_return_status
                     ,x_msg_count          => x_msg_count
                     ,x_msg_data           => x_msg_data
                     );

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           WRITE_LOG(x_msg_data);
           DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: UPDATE_GROUP_NAME Fails');

           gc_return_status  := 'WARNING';

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => x_msg_count
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_error_message_count     => x_msg_count
                           ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MINOR'
                           );
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

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        WRITE_LOG(x_msg_data);
        DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_USAGE Fails. ');

        IF NVL(gc_return_status,'A') <> 'ERROR' THEN

           gc_return_status := 'WARNING';

        END IF;

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                               p_return_code             => x_return_status
                              ,p_msg_count               => x_msg_count
                              ,p_application_name        => GC_APPN_NAME
                              ,p_program_type            => GC_PROGRAM_TYPE
                              ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                              ,p_program_id              => gc_conc_prg_id
                              ,p_module_name             => GC_MODULE_NAME
                              ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                              ,p_error_message_count     => x_msg_count
                              ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                              ,p_error_message           => x_msg_data
                              ,p_error_status            => GC_ERROR_STATUS
                              ,p_notify_flag             => GC_NOTIFY_FLAG
                              ,p_error_message_severity  =>'MINOR'
                              );



      ELSE

        DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: CREATE_GROUP_USAGE Success');

      END IF;

      ASSGN_GRP_ROLE
                  ( p_group_id         => ln_group_id
                  , p_group_number     => lc_group_number
                  , p_calculate_bonus  => 'Y'--25/02/08
                  , x_return_status    => x_return_status
                  , x_msg_count        => x_msg_count
                  , x_msg_data         => x_msg_data
                  );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSGN_GRP_ROLE Fails. ');

         IF NVL(gc_return_status,'A') <> 'ERROR' THEN
            gc_return_status  := 'WARNING';
         END IF;

       ELSE

         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSGN_GRP_ROLE Success');

       END IF;

         -----------------------------------------------
         -- Unassign previous assignments to group roles
         -----------------------------------------------
         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Unassign previous assignments to group roles.');

         END_GRP_AND_RESGRPROLE
                     ( p_group_id         => ln_group_id
                     , p_end_date         => gd_mgr_asgn_date - 1 -- gd_as_of_date -1
                     , x_return_status    => x_return_status
                     , x_msg_count        => x_msg_count
                     , x_msg_data         => x_msg_data
                     );

         IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

           DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Fails .');

         ELSE

           DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: END_GRP_AND_RESGRPROLE Success');

         END IF;

         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Fetching New Supervisor Group based on HR data.');
         FOR  lr_mgr_grp IN lcu_get_mgr_grp
         LOOP

            ln_mgr_grp_id        := lr_mgr_grp.group_id;
            lc_mgr_group_number  := lr_mgr_grp.group_number;
            ld_mgr_group_start   := lr_mgr_grp.start_date_active;
            ld_mgr_group_end     := lr_mgr_grp.end_date_active;

            EXIT;

         END LOOP;

         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: ln_mgr_grp_id = '||ln_mgr_grp_id);
         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: lc_mgr_group_number = '||lc_mgr_group_number);

         IF  ln_mgr_grp_id IS NULL THEN

            ln_mgr_grp_id := - 1;

         END IF;

         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: ln_mgr_grp_id = '||ln_mgr_grp_id);
         DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: lc_mgr_group_number = '||lc_mgr_group_number);

         --
         -- Call the end child group relation for previous groups.
         -- Call end parent child relation for both VP and mgr record
         --

         FOR  old_relation_rec IN lcu_get_old_relation(ln_group_id
                                                      ,ln_mgr_grp_id
                                                      )
         LOOP

            DEBUG_LOG('End date Old Hierarchy with parent group ID: '||old_relation_rec.related_group_id);
            DEBUG_LOG('End date Old Hierarchy with related ID: '||old_relation_rec.group_relate_id);

            IF (old_relation_rec.related_group_id = -1) OR 
               (old_relation_rec.start_date_active > (gd_mgr_asgn_date - 1)) THEN

                DELETE_OFF_PARENT_GROUP
                                 ( p_group_relate_id      => old_relation_rec.group_relate_id
                                 , p_object_version_num   => old_relation_rec.object_version_number
                                 , x_return_status        => lc_return_status
                                 , x_msg_count            => ln_msg_count
                                 , x_msg_data             => lc_msg_data
                                 );

                x_msg_count := ln_msg_count;

                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(lc_msg_data);
                  DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: DELETE_OFF_PARENT_GROUP Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code             => lc_return_status
                                         ,p_msg_count               => ln_msg_count
                                         ,p_application_name        => GC_APPN_NAME
                                         ,p_program_type            => GC_PROGRAM_TYPE
                                         ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                         ,p_error_message_count     => ln_msg_count
                                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                         ,p_error_message           => lc_msg_data
                                         ,p_error_status            => GC_ERROR_STATUS
                                         ,p_notify_flag             => GC_NOTIFY_FLAG
                                         ,p_error_message_severity  =>'MINOR'
                                         );

                END IF;

            ELSE

                ENDDATE_OFF_PARENT_GROUP
                                 ( p_group_relate_id      => old_relation_rec.group_relate_id
                                 , p_end_date_active      => gd_mgr_asgn_date - 1
                                 , p_object_version_num   => old_relation_rec.object_version_number
                                 , x_return_status        => lc_return_status
                                 , x_msg_count            => ln_msg_count
                                 , x_msg_data             => lc_msg_data
                                 );

                x_msg_count := ln_msg_count;

                IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(lc_msg_data);
                  DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ENDDATE_OFF_PARENT_GROUP Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code             => lc_return_status
                                         ,p_msg_count               => ln_msg_count
                                         ,p_application_name        => GC_APPN_NAME
                                         ,p_program_type            => GC_PROGRAM_TYPE
                                         ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                         ,p_program_id              => gc_conc_prg_id
                                         ,p_module_name             => GC_MODULE_NAME
                                         ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                         ,p_error_message_count     => ln_msg_count
                                         ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                         ,p_error_message           => lc_msg_data
                                         ,p_error_status            => GC_ERROR_STATUS
                                         ,p_notify_flag             => GC_NOTIFY_FLAG
                                         ,p_error_message_severity  =>'MINOR'
                                         );

                END IF;
         END IF;


         END LOOP;  -- END LOOP, lcu_get_old_relation

         -------------------------------------
         -- Check VP or NOT
         -------------------------------------

         IF  lcu_check_is_vp%ISOPEN THEN

            CLOSE lcu_check_is_vp;

         END IF;

         OPEN  lcu_check_is_vp;
         FETCH lcu_check_is_vp INTO lc_vp_flag;
         CLOSE lcu_check_is_vp;

         DEBUG_LOG('Is Resource a VP (Y/N): '||NVL(lc_vp_flag,'N'));
         ---------------------------------------------------------------
         -- Non VP Processing
         -- For VP no processing required for assigning to Parent Group.
         ---------------------------------------------------------------
         IF ( NVL(lc_vp_flag,'N') <> 'Y' ) THEN

            IF ln_mgr_grp_id IS NOT NULL THEN

               IF lcu_check_relation%ISOPEN THEN
                  CLOSE lcu_check_relation;
               END IF;

               lr_check_relation := NULL;

               OPEN  lcu_check_relation(ln_group_id
                                       ,ln_mgr_grp_id);

               FETCH lcu_check_relation INTO lr_check_relation;

               CLOSE lcu_check_relation;
				
			   --17 July 2012 Deepak [AMS] Defect#11701: To consider cases where grp relation existed in past, and the grp relation needs tobe created again
               --IF ( NVL(lr_check_relation.reln_exists, 'N') <> 'Y' ) THEN
			     IF ( (NVL(lr_check_relation.reln_exists, 'N') <> 'Y') OR (NVL(lr_check_relation.reln_exists, 'N') = 'Y' AND lr_check_relation.end_date_active < gd_mgr_asgn_date) ) THEN

                  ASSIGN_TO_PARENT_GROUP
                        (p_api_version         => 1.0
                        ,p_commit              =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                        ,p_group_id            => ln_group_id
                        ,p_group_number        => lc_group_number
                        ,p_related_group_id    => ln_mgr_grp_id
                        ,p_related_group_number=> lc_mgr_group_number
                        ,p_relation_type       =>'PARENT_GROUP'
                        ,p_start_date_active   => gd_mgr_asgn_date  -- gd_as_of_date
                        ,p_end_date_active     => ld_mgr_group_end
                        ,x_return_status       => x_return_status
                        ,x_msg_count           => x_msg_count
                        ,x_msg_data            => x_msg_data
                        ,x_group_relate_id     => ln_group_relate_id
                        );

                  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                     WRITE_LOG(x_msg_data);
                     gc_return_status  := 'ERROR';

                     DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSIGN_TO_PARENT_GROUP Fails. ');

                     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code             => x_return_status
                                        ,p_msg_count               => x_msg_count
                                        ,p_application_name        => GC_APPN_NAME
                                        ,p_program_type            => GC_PROGRAM_TYPE
                                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_error_message_count     => x_msg_count
                                        ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => x_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MAJOR'
                                        );

                     RAISE EX_TERMINATE_MGR_ASGN;

                  ELSE

                     DEBUG_LOG('In Procedure:PROCESS_MANAGER_ASSIGNMENTS: Proc: ASSIGN_TO_PARENT_GROUP Success');

                     IF lcu_get_res_details%ISOPEN THEN

                        CLOSE lcu_get_res_details;

                     END IF;

                     OPEN  lcu_get_res_details;
                     FETCH lcu_get_res_details INTO lr_res_details;
                     CLOSE lcu_get_res_details;

                     DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: UPDT_DATES_RESOURCE. ');

                     UPDT_DATES_RESOURCE
                                   ( p_resource_id        =>  gn_resource_id
                                   , p_resource_number    =>  lr_res_details.resource_number
                                   , p_source_name        =>  lr_res_details.source_name
                                   --, p_attribute14        =>  TO_CHAR(lr_res_details.job_asgn_date,'MM/DD/RRRR') --04/DEC/07
                                   --, p_attribute15        =>  TO_CHAR(gd_mgr_asgn_date,'MM/DD/RRRR') --04/DEC/07
                                   , p_attribute14        =>  TO_CHAR(lr_res_details.job_asgn_date,'DD-MON-RR')
                                   , p_attribute15        =>  TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR')
                                   , p_object_version_num =>  lr_res_details.object_version_number
                                   , x_return_status      =>  x_return_status
                                   , x_msg_count          =>  x_msg_count
                                   , x_msg_data           =>  x_msg_data
                                   );

                     IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                        WRITE_LOG(x_msg_data);
                        DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: UPDT_DATES_RESOURCE Fails. ');

                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code             => x_return_status
                                        ,p_msg_count               => x_msg_count
                                        ,p_application_name        => GC_APPN_NAME
                                        ,p_program_type            => GC_PROGRAM_TYPE
                                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_error_message_count     => x_msg_count
                                        ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => x_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MAJOR'
                                        );

                        RAISE EX_TERMINATE_MGR_ASGN;

                     END IF;

                  END IF;               
               --
               -- Check the hierarcy start date to be less than job asgn date else update it to job asgn date
               --
               ELSIF (lr_check_relation.start_date_active > gd_mgr_asgn_date ) THEN
               
               DEBUG_LOG('lr_check_relation.start_date_active:'||lr_check_relation.start_date_active);

                  BACKDATE_PARENT_GROUP
                                   (p_group_relate_id     => lr_check_relation.group_relate_id
                                   ,p_start_date_active   => gd_mgr_asgn_date
                                   ,p_object_version_num  => lr_check_relation.object_version_number
                                   ,x_return_status       => x_return_status
                                   ,x_msg_count           => x_msg_count
                                   ,x_msg_data            => x_msg_data
                                   );

                  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                     WRITE_LOG(x_msg_data);
                     gc_return_status  := 'WARNING';

                     DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Proc: BACKDATE_PARENT_GROUP Fails. ');

                     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code             => x_return_status
                                        ,p_msg_count               => x_msg_count
                                        ,p_application_name        => GC_APPN_NAME
                                        ,p_program_type            => GC_PROGRAM_TYPE
                                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => GC_MODULE_NAME
                                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                        ,p_error_message_count     => x_msg_count
                                        ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                        ,p_error_message           => x_msg_data
                                        ,p_error_status            => GC_ERROR_STATUS
                                        ,p_notify_flag             => GC_NOTIFY_FLAG
                                        ,p_error_message_severity  =>'MINOR'
                                        );
                  END IF;

               END IF;  -- END IF, NVL(lc_reln_exist_flag, 'N') <> 'Y'

            ELSE  -- ELSE, ln_mgr_grp_id IS NOT NULL

               FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0049_NO_MANAGER_GRP');
               FND_MESSAGE.SET_TOKEN('P_DATE',gd_job_asgn_date);
               lc_error_message    := FND_MESSAGE.GET;
               FND_MSG_PUB.add;

               WRITE_LOG(lc_error_message);

               IF gc_err_msg IS NOT NULL THEN
                  gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
               ELSE
                  gc_err_msg := lc_error_message;
               END IF;

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => FND_API.G_RET_STS_ERROR
                                  ,p_msg_count               => 1
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                                  ,p_error_message_count     => 1
                                  ,p_error_message_code      =>'XX_TM_0049_NO_MANAGER_GRP'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );

               RAISE EX_TERMINATE_MGR_ASGN;

            END IF;  -- END IF, ln_mgr_grp_id IS NOT NULL

         END IF; -- END IF, NVL(lc_vp_flag,'N') <> 'Y'

      x_return_status  := FND_API.G_RET_STS_SUCCESS;


   EXCEPTION

    WHEN EX_TERMINATE_MGR_ASGN THEN

      DEBUG_LOG('In Procedure: PROCESS_MANAGER_ASSIGNMENTS: Program Terminated.');

      x_return_status   := FND_API.G_RET_STS_ERROR;

      gc_return_status    :='ERROR';

    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_MANAGER_ASSIGNMENTS'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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


      CURSOR  lcu_check_is_mgr
      IS
      SELECT  'Y' MGR_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_role_relations_vl JRLV
             ,jtf_rs_roles_b           JRRB
      WHERE   JRLV.manager_flag        = 'Y'
      AND     (JRLV.role_type_code     = 'SALES'
       --OR      JRLV.role_type_code     = 'SALES_COMP')
         -- Added on 24/07/08
         OR   JRLV.role_type_code     = 'SALES_COMP'
         OR   JRLV.role_type_code     = 'COLLECTIONS')
         -- Added on 24/07/08
      AND     JRLV.role_id             =  JRRB.role_id
      AND     JRLV.role_resource_id    =  gn_resource_id
      AND     JRLV.role_resource_type  = 'RS_INDIVIDUAL'
      AND     gd_job_asgn_date BETWEEN JRLV.start_date_active                      -- Check only for
                               AND     NVL(JRLV.end_date_active,gd_job_asgn_date)  -- current asgnment
      AND     NVL(JRRB.active_flag,'N') = 'Y');

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_SALES_REP_GRP_ASGN');

      IF lcu_check_is_mgr%ISOPEN THEN
         CLOSE lcu_check_is_mgr;
      END IF;

      OPEN  lcu_check_is_mgr;
      FETCH lcu_check_is_mgr INTO  lc_mgr_flag;
      CLOSE lcu_check_is_mgr;

      DEBUG_LOG('Is Resource a Manager (Y/N): '||NVL(lc_mgr_flag,'N'));

      IF ( NVL(lc_mgr_flag,'N') <> 'Y' )  THEN         
         
         gc_resource_type := 'Member';-- 02/07/08
         --------------------------------------
         DEBUG_LOG('Processing as Non Manager Sales Rep');
         --------------------------------------
         Process_NonManager_Assignments
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );
      ELSE     
         
         gc_resource_type := 'Manager';-- 02/07/08
         
         --------------------------------------
         DEBUG_LOG('Processing as Manager Sales Rep');
         --------------------------------------

         Process_Manager_Assignments
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );


      END IF;  -- END IF, NVL(lc_mgr_flag,'N') <> 'Y'


   EXCEPTION
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     := 'ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP_GRP_ASGN'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP_GRP_ASGN'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
                             ,x_msg_data        OUT NOCOPY VARCHAR2
                             )
   IS

      lc_error_message              VARCHAR2(1000);

      EX_TERMINATE_PRGM             EXCEPTION;


     /* CURSOR   lcu_get_sales_credit
      IS
      SELECT   sales_credit_type_id
      FROM     oe_sales_credit_types
      WHERE    name = 'Quota Sales Credit' ;*/

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_SALES_REP');

     /* IF lcu_get_sales_credit%ISOPEN THEN
         CLOSE lcu_get_sales_credit;
      END IF;

      OPEN  lcu_get_sales_credit;
      FETCH lcu_get_sales_credit INTO ln_sales_credit_type_id;
      CLOSE lcu_get_sales_credit;

      IF ln_sales_credit_type_id IS NULL THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0041_CRDTTYP_NDFN');
         FND_MSG_PUB.add;

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0041_CRDTTYP_NDFN');
         lc_error_message    := FND_MESSAGE.GET;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                            ,p_msg_count               => 1 --x_msg_count
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                            ,p_error_message_count     => 1 --x_msg_count
                            ,p_error_message_code      =>'XX_TM_0041_CRDTTYP_NDFN'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

         RAISE EX_TERMINATE_PRGM;

      END IF;
      */
      IF gc_hierarchy_type = 'SALES' THEN -- 24/07/08
      
         DEBUG_LOG('Create Sales Rep for the Resource');

         CREATE_SALES_REP
               (p_api_version         => 1.0
               ,p_commit              =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
               ,p_resource_id         => gn_resource_id
               ,p_sales_credit_type_id=> gn_sales_credit_type_id
               ,p_salesrep_number     => gc_employee_number
               ,p_start_date_active   => gd_job_asgn_date
               ,p_email_address       => gc_email_address
               ,x_return_status       => x_return_status
               ,x_msg_count           => x_msg_count
               ,x_msg_data            => x_msg_data
               );

         IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
         THEN

            WRITE_LOG(x_msg_data);
            DEBUG_LOG('In Procedure: PROCESS_SALES_REP: Proc: CREATE_SALES_REP Fails. ');

            gc_return_status :=  'ERROR';

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => x_return_status
                               ,p_msg_count               => x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                               ,p_error_message_count     => x_msg_count
                               ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                               ,p_error_message           => x_msg_data
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         END IF;
         
      END IF; -- 24/07/08      

      DEBUG_LOG('Assign Roles to the Resource. Calling Proc ASSIGN_ROLE');
      ASSIGN_ROLE
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

      DEBUG_LOG('Assign Groups and Group Roles to the Resource. Calling Proc PROCESS_SALES_REP_GRP_ASGN');
      PROCESS_SALES_REP_GRP_ASGN
                (x_return_status  => x_return_status
                ,x_msg_count      => x_msg_count
                ,x_msg_data       => x_msg_data
                );

      IF x_return_status <> fnd_api.G_RET_STS_SUCCESS
      THEN

          DEBUG_LOG('In Procedure: PROCESS_SALES_REP: Proc: PROCESS_SALES_REP_GRP_ASGN Fails. ');

         RAISE EX_TERMINATE_PRGM;

      END IF;

      x_return_status := fnd_api.G_RET_STS_SUCCESS;


   EXCEPTION

    WHEN EX_TERMINATE_PRGM THEN

      DEBUG_LOG('In Procedure:PROCESS_SALES_REP: Program Terminated. ');

      x_return_status   := FND_API.G_RET_STS_ERROR;
      gc_return_status    :='ERROR';


    WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_SALES_REP'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
   -- |                    4.  Process as Manager, if applicable          |
   -- |                       (Manager processing is extension of         |
   -- |                        Sales Rep processing.)                     |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE PROCESS_RESOURCE_DETAILS
                (x_return_status   OUT NOCOPY VARCHAR2
                ,x_msg_count       OUT NOCOPY NUMBER
                ,x_msg_data        OUT NOCOPY VARCHAR2
                ,x_termin_prgm     OUT VARCHAR2
                )
   IS

      EX_TERMIN_PRGM                   EXCEPTION;-- 25/06/08
      
      lc_role_type_code                JTF_RS_ROLES_VL.role_type_code%TYPE;
      lc_admin_flag                    JTF_RS_ROLES_VL.admin_flag%TYPE;
      lc_member_flag                   JTF_RS_ROLES_VL.member_flag%TYPE;
      lc_error_message                 VARCHAR2(1000);      
      lc_job_role_exists_flg	       VARCHAR2(1);-- 25/06/08
      lc_job_name                      PER_JOBS.name%TYPE; -- 27/06/08
      lc_any_role_exists               VARCHAR2(1);
      ln_job_id                        PER_JOBS.job_id%TYPE; -- 04/07/08
      lc_sales_rep_flag                VARCHAR2(1); -- 24/07/08      


      CURSOR  lcu_check_roles
      IS
      SELECT  JRRV.role_type_code
             ,JRRV.member_flag
             ,JRRV.admin_flag
      FROM    jtf_rs_roles_vl     JRRV
             ,jtf_rs_job_roles_vl JRJRV
      WHERE   JRJRV.role_id       = JRRV.role_id
      AND     JRRV.member_flag    = 'Y'
      AND     JRRV.role_type_code = 'SALES_COMP_PAYMENT_ANALIST'
      AND     JRRV.role_type_code != 'COLLECTIONS'-- 28/07/08
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
      AND     JRRV.role_type_code != 'COLLECTIONS'-- 28/07/08
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRJRV.job_id        = gn_job_id;

      lr_check_roles    lcu_check_roles%ROWTYPE;
      
      -- Added on 25/06/08         
                            
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
      
      -- Added on 25/06/08
      
      -- Added on 27/06/08
      CURSOR lcu_get_job_name
      IS
      SELECT name 
            ,job_id -- 04/07/08
      FROM   per_jobs
      WHERE  job_id = gn_job_id;
      
      -- Added on 27/06/08
      
      -- Added on 28/07/08
      
      CURSOR  lcu_check_collection_roles
      IS
      SELECT  JRRV.role_type_code      
             ,JRRV.member_flag -- 28/07/08
             ,JRRV.admin_flag  -- 28/07/08     
      FROM    jtf_rs_roles_vl     JRRV
             ,jtf_rs_job_roles_vl JRJRV
      WHERE   JRJRV.role_id       = JRRV.role_id
      AND     JRRV.role_type_code = 'COLLECTIONS'
      AND     NVL(JRRV.active_flag,'N') = 'Y'
      AND     JRJRV.job_id        = gn_job_id;    
      
      lr_check_collection_roles    lcu_check_collection_roles%ROWTYPE;
      
      CURSOR   lcu_check_salesrep
      IS
      SELECT  'Y' sales_rep_flag
      FROM     jtf_rs_salesreps
      WHERE    resource_id = gn_resource_id;                       
                   
      -- Added on 28/07/08 
      
   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_RESOURCE_DETAILS'); 

      DEBUG_LOG('gc_resource_exists:'||gc_resource_exists);  
  
  
      -- Added on 25/06/08
      IF ( NVL(gc_resource_exists,'N') = 'Y') THEN             	                              	       	    
      	    
      	    IF lcu_chk_job_role_map_exists%ISOPEN THEN                       
      	       CLOSE lcu_chk_job_role_map_exists;
      	    END IF;
      	 
      	    OPEN  lcu_chk_job_role_map_exists;
      	    FETCH lcu_chk_job_role_map_exists INTO lc_job_role_exists_flg;
      	    CLOSE lcu_chk_job_role_map_exists;                            	 
      	 
      	    IF (NVL(lc_job_role_exists_flg,'N') <> 'Y') THEN         	              	                     	               	         
      	         
      	         -- Added on 27/06/08
      	         OPEN  lcu_get_job_name;
      	         --FETCH lcu_get_job_name INTO lc_job_name;
      	         FETCH lcu_get_job_name INTO lc_job_name,ln_job_id; -- 04/07/08
      	         CLOSE lcu_get_job_name;      	         
      	         -- Added on 27/06/08
      	 
      	         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0011_ROLE_NULL');
      	         FND_MESSAGE.SET_TOKEN('P_JOB_ID', ln_job_id ); -- 04/07/08
      	         FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 27/06/08      	         
      	 	 gc_errbuf := FND_MESSAGE.GET;
      	 	 FND_MSG_PUB.add;
      	 
      	 	 WRITE_LOG(gc_errbuf);      
      	 	 
      	 	 gc_return_status      :='WARNING';-- 25/06/08
      	 	 x_return_status       := FND_API.G_RET_STS_ERROR;
      	 
      	 	 IF gc_err_msg IS NOT NULL THEN
      	 	    gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      	 	 ELSE
      	 	    gc_err_msg := gc_errbuf;
      	 	 END IF;
      	 
      	 	 XX_COM_ERROR_LOG_PUB.log_error_crm(
      	 	                         p_return_code             => x_return_status
      	 	                        ,p_msg_count               => 1
      	 	                        ,p_application_name        => GC_APPN_NAME
      	 	                        ,p_program_type            => GC_PROGRAM_TYPE
      	 	                        ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
      	 	                        ,p_program_id              => gc_conc_prg_id
      	 	                        ,p_module_name             => GC_MODULE_NAME
      	 	                        ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
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
      	 
      	              gc_return_status      :='WARNING';-- 25/06/08
      	              x_return_status       := FND_API.G_RET_STS_ERROR;
        
      	              IF gc_err_msg IS NOT NULL THEN
      	                 gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      	              ELSE
      	                 gc_err_msg := gc_errbuf;
      	              END IF;

      	              XX_COM_ERROR_LOG_PUB.log_error_crm(
      	                               p_return_code             => x_return_status
      	                              ,p_msg_count               => 1
      	                              ,p_application_name        => GC_APPN_NAME
      	                              ,p_program_type            => GC_PROGRAM_TYPE
      	                              ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
      	                              ,p_program_id              => gc_conc_prg_id
      	                              ,p_module_name             => GC_MODULE_NAME
      	                              ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
      	                              ,p_error_message_count     => 1
      	                              ,p_error_message_code      => 'XX_TM_0266_NO_RES_ROLE'
      	                              ,p_error_message           => gc_errbuf
      	                              ,p_error_status            => GC_ERROR_STATUS
      	                              ,p_notify_flag             => GC_NOTIFY_FLAG
      	                              ,p_error_message_severity  =>'MINOR'
      	                              );
                  	                           
               END IF;   
         
         RAISE EX_TERMIN_PRGM; 
                                                  
         END IF;
      
      END IF;
      
      -- Added on 25/06/08                   
      IF  gc_hierarchy_type = 'SALES' THEN -- 24/07/08
      
         IF lcu_check_roles%ISOPEN THEN   
      
      	    CLOSE lcu_check_roles;
      
      	 END IF;
      
      	 OPEN  lcu_check_roles;
      	 FETCH lcu_check_roles INTO lr_check_roles;
      	 CLOSE lcu_check_roles;
      
      	 lc_role_type_code   :=  lr_check_roles.role_type_code;
      	 lc_admin_flag       :=  lr_check_roles.admin_flag;
      	 lc_member_flag      :=  lr_check_roles.member_flag;   
      
      	 DEBUG_LOG('ROLE_TYPE_CODE:'||lc_role_type_code);
      	 DEBUG_LOG('ADMIN_FLAG:'||lc_admin_flag);
      	 DEBUG_LOG('MEMBER_FLAG:'||lc_member_flag);                 
                                                                     
         IF  lc_role_type_code  = 'SALES'
         AND lc_admin_flag      = 'Y' THEN
            -------------------------------------
            -- 1. Process as Sales Administrator
            -------------------------------------

            DEBUG_LOG('Resource is of type Sales Admin');         
         
            gc_resource_type := 'Admin'; -- 02/07/08

            PROCESS_SALES_ADMIN (x_return_status   => x_return_status
                                ,x_msg_count       => x_msg_count
                                ,x_msg_data        => x_msg_data
                                );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               DEBUG_LOG('In Procedure: PROCESS_RESOURCE_DETAILS: Proc: PROCESS_SALES_ADMIN Fails. ');
 
            END IF;

         ELSIF  lc_role_type_code   = 'SALES_COMP_PAYMENT_ANALIST'
         AND    lc_member_flag      = 'Y' THEN

            -------------------------------------
            -- 2. Process as Sales Comp Analayst
            -------------------------------------

            DEBUG_LOG('Resource is of type Sales Comp Payment Analist');         
         
            gc_resource_type := 'Analyst';-- 02/07/08

            PROCESS_SALES_COMP_ANALYST (x_return_status   => x_return_status
                                       ,x_msg_count       => x_msg_count
                                       ,x_msg_data        => x_msg_data
                                       );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               DEBUG_LOG('In Procedure: PROCESS_RESOURCE_DETAILS: Proc: PROCESS_SALES_COMP_ANALYST Fails. ');

            END IF;

         ELSE  -- else for lc_role_type_code  = 'SALES', not an admin resource
            -------------------------------------
            -- 3. Process as Sales Rep
            -------------------------------------

            DEBUG_LOG('Resource is of type Sales Rep');

            gc_sales_rep_res := 'Y';       
         
            PROCESS_SALES_REP (x_return_status   => x_return_status
                              ,x_msg_count       => x_msg_count
                              ,x_msg_data        => x_msg_data
                              );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               DEBUG_LOG('In Procedure: PROCESS_RESOURCE_DETAILS: Proc: PROCESS_SALES_REP Fails. ');

            END IF;

         END IF;  -- lc_role_type_code  = 'SALES', not an admin resource

      ELSIF  gc_hierarchy_type = 'COLLECTIONS' THEN -- 24/07/08
          
         -- Added on 28/07/08
         IF lcu_check_collection_roles%ISOPEN THEN   
         
            CLOSE lcu_check_collection_roles;
         
         END IF;
         
         OPEN  lcu_check_collection_roles;
         FETCH lcu_check_collection_roles INTO lr_check_collection_roles;
         CLOSE lcu_check_collection_roles;               
         
      	 lc_role_type_code   :=  lr_check_collection_roles.role_type_code;
      	 lc_admin_flag       :=  lr_check_collection_roles.admin_flag;
      	 lc_member_flag      :=  lr_check_collection_roles.member_flag;   
      
      	 DEBUG_LOG('ROLE_TYPE_CODE:'||lc_role_type_code);
      	 DEBUG_LOG('ADMIN_FLAG:'||lc_admin_flag);
      	 DEBUG_LOG('MEMBER_FLAG:'||lc_member_flag);  
      	 
      	 -- Added on 28/07/08
      	 
      	 IF lc_role_type_code = 'COLLECTIONS' THEN
      	    
            IF NVL(lc_member_flag,'N') = 'Y' AND NVL(lc_admin_flag,'N') = 'N' THEN
               gc_resource_type := 'Member';
               
            ELSIF NVL(lc_member_flag,'N') = 'N' AND NVL(lc_admin_flag,'N') = 'Y' THEN
               gc_resource_type := 'Admin';               
            
            END IF;
            
            DEBUG_LOG('Resource is of type Collections');
            
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
         
                 DEBUG_LOG('In Procedure:PROCESS_RESOURCE_DETAILS: Proc: ENDDATE_SALESREP Fails. ');
         
                  gc_return_status    := 'WARNING';
         
         
                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code             => x_return_status
                                       ,p_msg_count               => x_msg_count
                                       ,p_application_name        => GC_APPN_NAME
                                       ,p_program_type            => GC_PROGRAM_TYPE
                                       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
                                       ,p_program_id              => gc_conc_prg_id
                                       ,p_module_name             => GC_MODULE_NAME
                                       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
                                       ,p_error_message_count     => x_msg_count
                                       ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                       ,p_error_message           => x_msg_data
                                       ,p_error_status            => GC_ERROR_STATUS
                                       ,p_notify_flag             => GC_NOTIFY_FLAG
                                       ,p_error_message_severity  =>'MINOR'
                                       );
         
              END IF;
            
            END IF;
        
            PROCESS_SALES_REP (x_return_status   => x_return_status
                              ,x_msg_count       => x_msg_count
                              ,x_msg_data        => x_msg_data
                              );

            IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               DEBUG_LOG('In Procedure: PROCESS_RESOURCE_DETAILS: Proc: PROCESS_SALES_REP Fails. ');

            END IF;                
         END IF;  -- 28/07/08 
                      
     END IF; -- 24/07/08
     
   EXCEPTION
      -- Added on 25/06/08 
      WHEN EX_TERMIN_PRGM THEN
         x_termin_prgm := 'Y';
      -- Added on 25/06/08   
         
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      gc_return_status     :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCE_DETAILS'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
      lc_termination_flag           VARCHAR2(1);  -- Added on 24/04/08
      lc_termin_prgm                VARCHAR2(1);  -- Added on 25/06/08
      lc_job_name                   PER_JOBS.name%TYPE; -- 27/06/08
      ln_job_id                     PER_JOBS.job_id%TYPE; -- 04/07/08
      lc_hierarchy_type             jtf_rs_roles_vl.role_type_code%TYPE; -- 28/07/08
      lc_role_type_flag             VARCHAR2(1);
      lc_invalid_job_flag           VARCHAR2(1); 
      

      CURSOR   lcu_get_job
      IS
      SELECT   job_id
      FROM     per_all_assignments_f
      WHERE    person_id         = gn_person_id
      AND      business_group_id = gn_biz_grp_id
      AND      gd_as_of_date BETWEEN effective_start_date
                                 AND effective_end_date ;

      CURSOR   lcu_check_role
      IS
      SELECT  'Y' role_exists
             , JRRV.role_type_code -- 28/07/08
      FROM     per_jobs PJ
              ,jtf_rs_job_roles   JRJR
              ,jtf_rs_roles_b     JRRV
      WHERE    PJ.job_id                 = JRJR.job_id
      AND      PJ.job_id                 = gn_job_id
      AND      JRJR.role_id              = JRRV.role_id
      --AND      JRRV.role_type_code      IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
      AND      JRRV.role_type_code      IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST','COLLECTIONS') -- 24/07/08
      AND      NVL(JRRV.active_flag,'N') = 'Y';

      CURSOR   lcu_get_fnd_user
      IS
      SELECT   user_name
      FROM     fnd_user
      WHERE    employee_id  =  gn_person_id
      AND      gd_as_of_date BETWEEN start_date
                             AND     NVL(end_date, gd_as_of_date + 1);
      
      -- Added on 24/04/08
      CURSOR  lcu_check_termination
      IS	  
      SELECT TERMINATION_STATUS 
      FROM   (SELECT  'Y' TERMINATION_STATUS
              FROM    PER_ALL_PEOPLE_F       PAPF
                     ,PER_PERIODS_OF_SERVICE PPOS
                     ,PER_PERSON_TYPES       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   <= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EX_EMP'
              OR      PPT.SYSTEM_PERSON_TYPE          = 'EX_CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              --AND     gd_as_of_date -- Commented on 24/04/08
                AND     TRUNC(gd_as_of_date)
                      BETWEEN  PAPF.effective_start_date
                      AND      PAPF.effective_end_date           
              UNION
              SELECT  'Y' TERMINATION_STATUS
              FROM    PER_ALL_PEOPLE_F       PAPF
                     ,PER_PERIODS_OF_SERVICE PPOS
                     ,PER_PERSON_TYPES       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   >= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EMP'
              --OR      PPT.system_person_type          = 'EX_EMP'-- Commented on 24/04/08              
              OR      PPT.SYSTEM_PERSON_TYPE          = 'CWK')
              AND     PAPF.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPOS.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              --AND     gd_as_of_date -- Commented on 24/04/08
                AND     TRUNC(gd_as_of_date)
                        BETWEEN  PAPF.effective_start_date
                        AND      PAPF.EFFECTIVE_END_DATE        	      
	      ) A, JTF_RS_RESOURCE_EXTNS_VL B
        WHERE B.SOURCE_ID = gn_person_id;
              
              
      -- Added on 27/06/08        
      CURSOR lcu_get_job_name        
      IS        
      SELECT name        
            ,job_id -- 04/07/08
      FROM   per_jobs        
      WHERE  job_id = gn_job_id;    
      -- Added on 27/06/08        
      
      
      -- Added on 29/07/08
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
                  AND    JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
                  )      
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code = 'COLLECTIONS' 
                 );  
                 
      CURSOR  lcu_get_invalid_job
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
                  AND    JRRV.role_type_code = 'COLLECTIONS'
                  AND    JRRV.member_flag = 'Y'
                  )      
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code = 'COLLECTIONS'
                  AND    JRRV.admin_flag = 'Y'
                 );         
                        
     
      EX_TERMINATE_PRGM             EXCEPTION;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_NEW_RESOURCE');
      
      -- Added on 24/04/08
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
      	    gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
      	 ELSE
      	    gc_err_msg := lc_error_message;
      	 END IF;
      
      	 XX_COM_ERROR_LOG_PUB.log_error_crm(
      	                     p_return_code             => FND_API.G_RET_STS_ERROR
      	                    ,p_msg_count               => 1
      	                    ,p_application_name        => GC_APPN_NAME
      	                    ,p_program_type            => GC_PROGRAM_TYPE
      	                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
      	                    ,p_program_id              => gc_conc_prg_id
      	                    ,p_module_name             => GC_MODULE_NAME
      	                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
      	                    ,p_error_message_count     => 1
      	                    ,p_error_message_code      =>'XX_TM_0264_DONT_CREATE_RESOURE'
      	                    ,p_error_message           => lc_error_message
      	                    ,p_error_status            => GC_ERROR_STATUS
      	                    ,p_notify_flag             => GC_NOTIFY_FLAG
      	                    ,p_error_message_severity  =>'MINOR'  --Changed from 'MAJOR' to display as WARNING on 01/14/2009 
      	                    );
      
      	 RAISE EX_TERMINATE_PRGM;
      
     END IF; 
      -- Added on 24/04/08   
      
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
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0008_JOB_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

         RAISE EX_TERMINATE_PRGM;

      END IF;
      
      -- Added on 30/07/08
      OPEN  lcu_get_job_name;        
      FETCH lcu_get_job_name INTO lc_job_name,ln_job_id; -- 04/07/08
      CLOSE lcu_get_job_name;      	      
      -- Added on 30/07/08          
      
      IF lcu_get_role_type%ISOPEN THEN
         CLOSE lcu_get_role_type;
      END IF;

      OPEN  lcu_get_role_type;
      FETCH lcu_get_role_type INTO lc_role_type_flag ;
      CLOSE lcu_get_role_type;      
      
      IF lcu_get_invalid_job%ISOPEN THEN
      
         CLOSE lcu_get_invalid_job;
      
      END IF;
                           
      OPEN  lcu_get_invalid_job;	    
      FETCH lcu_get_invalid_job INTO lc_invalid_job_flag;
      CLOSE lcu_get_invalid_job;  
      
      IF  NVL(lc_role_type_flag,'N')= 'Y' THEN             
               
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0269_INVALID_JOB');   
         FND_MESSAGE.SET_TOKEN('P_JOB_ID', ln_job_id ); -- 04/07/08
         FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 27/06/08
         gc_errbuf := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         WRITE_LOG(gc_errbuf);
         
         gc_return_status  := 'ERROR';
           
         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;             
         
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => 1
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'XX_TM_0269_INVALID_JOB'
                                ,p_error_message           => gc_errbuf
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MAJOR'
                              );
         
         RAISE EX_TERMINATE_PRGM;
         
      END IF;     
      
       IF  NVL(lc_invalid_job_flag,'N')= 'Y' THEN             
               
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0268_INVALID_JOB');   
         FND_MESSAGE.SET_TOKEN('P_JOB_ID', ln_job_id ); -- 04/07/08
         FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 27/06/08
         gc_errbuf := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         WRITE_LOG(gc_errbuf);
         
         gc_return_status  := 'ERROR';
           
         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;             
         
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => 1
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'XX_TM_0268_INVALID_JOB'
                                ,p_error_message           => gc_errbuf
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MAJOR'
                              );
         
         RAISE EX_TERMINATE_PRGM;
         
      END IF;         
 
      -- 29/07/08      
      
      IF lcu_check_role%ISOPEN THEN
         CLOSE lcu_check_role;
      END IF;
      
      OPEN  lcu_check_role;
      --FETCH lcu_check_role INTO lc_role_exists;
      FETCH lcu_check_role INTO lc_role_exists,lc_hierarchy_type; -- 28/07/08
      CLOSE lcu_check_role;

      -- 28/07/08 
      IF gc_hierarchy_type = 'SALES' AND (lc_hierarchy_type != 'SALES' AND 
                                          lc_hierarchy_type != 'SALES_COMP' AND 
                                          lc_hierarchy_type != 'SALES_COMP_PAYMENT_ANALIST')
                                      THEN
                                      
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0267_RES_HIERCHY_TYPE');
         FND_MESSAGE.SET_TOKEN('P_HIERARCHY', gc_hierarchy_type );
         gc_errbuf := FND_MESSAGE.GET;
         FND_MSG_PUB.add;         
         gc_return_status      :='ERROR'; 
         
      	 IF gc_err_msg IS NOT NULL THEN
      	    gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      	 ELSE
      	    gc_err_msg := gc_errbuf;
      	 END IF;         
         
         WRITE_LOG(gc_errbuf); -- 29/07/08
         
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => 1
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'XX_TM_0267_RES_HIERCHY_TYPE'
                                ,p_error_message           => gc_errbuf
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MINOR'
                              );
         
         RAISE EX_TERMINATE_PRGM;
         
         
      ELSIF gc_hierarchy_type = 'COLLECTIONS' AND lc_hierarchy_type != 'COLLECTIONS' THEN
      
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0267_RES_HIERCHY_TYPE');
         FND_MESSAGE.SET_TOKEN('P_HIERARCHY', gc_hierarchy_type );
         gc_errbuf := FND_MESSAGE.GET;
         FND_MSG_PUB.add;            
         gc_return_status      :='ERROR'; 
         
      	 IF gc_err_msg IS NOT NULL THEN
      	    gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      	 ELSE
      	    gc_err_msg := gc_errbuf;
      	 END IF;                 
         
         WRITE_LOG(gc_errbuf); -- 29/07/08
         
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => 1
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_error_message_count     => 1
                                ,p_error_message_code      => 'XX_TM_0267_RES_HIERCHY_TYPE'
                                ,p_error_message           => gc_errbuf
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MINOR'
                              );
         
         RAISE EX_TERMINATE_PRGM;
          
      END IF;          
      -- 28/07/08
      

      --DEBUG_LOG('Role exists for the Job:'||lc_role_exists);

      IF lc_role_exists  = 'Y' THEN

         DEBUG_LOG('Role Exists for the Job');

         OPEN  lcu_get_fnd_user;
         FETCH lcu_get_fnd_user INTO lc_user_name;
         CLOSE lcu_get_fnd_user;

         DEBUG_LOG('Fnd_user_name:'||lc_user_name);

         --Standard API to create resource in CRM
         CREATE_RESOURCE
                        (p_api_version         => 1.0
                        ,p_commit              =>FND_API.G_FALSE -- Changed on 01/14/2008 for avoiding half-commits from 'T'
                        ,p_category            =>'EMPLOYEE'
                        ,p_source_id           => gn_person_id
                        ,p_source_number       => gc_employee_number
                        ,p_start_date_active   => gd_job_asgn_date
                        ,p_resource_name       => gc_full_name
                        ,p_source_name         => gc_full_name
                        ,p_user_name           => lc_user_name
                        --,p_attribute14         => TO_CHAR(gd_job_asgn_date,'MM/DD/RRRR') --04/DEC/07
                        --,p_attribute15         => TO_CHAR(gd_mgr_asgn_date,'MM/DD/RRRR') --04/DEC/07
                        ,p_attribute14         => TO_CHAR(gd_job_asgn_date,'DD-MON-RR')
                        ,p_attribute15         => TO_CHAR(gd_mgr_asgn_date,'DD-MON-RR')
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
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
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

             PROCESS_RESOURCE_DETAILS
                    (x_return_status   =>  x_return_status
                    ,x_msg_count       =>  x_msg_count
                    ,x_msg_data        =>  x_msg_data
                    ,x_termin_prgm     =>  lc_termin_prgm
                    );

             IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN


               DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE: Resource details proccessed successfully. ');

             ELSE

               DEBUG_LOG('In Procedure:PROCESS_NEW_RESOURCE:Failed to process Resource details for :'||gn_resource_id);

             END IF;

          END IF; --End of If resource created successfully then proccessing resources details

      ELSE    -- else for lc_role_exists  = 'Y',  ROLES DOES NOT EXISTS FOR THE JOB ID
         -- DEBUG_LOG('Role does not Exists for the Job');                                       
                     
         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0011_ROLE_NULL');
         FND_MESSAGE.SET_TOKEN('P_JOB_ID', ln_job_id ); -- 04/07/08
         FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 27/06/08
         gc_errbuf := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(gc_errbuf);

         --gc_return_status      :='ERROR'; -- 25/06/08
         gc_return_status      :='WARNING'; -- 25/06/08
         x_return_status       := FND_API.G_RET_STS_ERROR;

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
         ELSE
            gc_err_msg := gc_errbuf;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => 1
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
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

      -- If resource is terminated then display as a WARNING otherwise ERROR ** Changed on 01/14/2009
      IF ( NVL(lc_termination_flag,'N') = 'Y') THEN
        gc_return_status    :='WARNING';
      ELSE
        gc_return_status    :='ERROR';
      END IF;

      WHEN OTHERS THEN

      gc_return_status     :='ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_NEW_RESOURCE'
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


      /*Commented on 25/04/08
      CURSOR  lcu_get_roles_to_enddate
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
      FROM    jtf_rs_role_relations    JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR.end_date_active IS NULL
      AND     JRGMR.end_date_active IS NULL      
      AND     JRRR.delete_flag = 'N'  ;
      */

      -- Added on 25/04/08
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
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
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

      ENDDATE_SALESREP
                 (p_resource_id     => gn_resource_id,
                  p_end_date_active => ld_termination_date,
                  x_return_status   => lc_return_status,
                  x_msg_count       => ln_msg_count,
                  x_msg_data        => lc_msg_data
                 );
      x_msg_count := ln_msg_count;

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_SALESREP Fails. ');

         IF NVL(gc_return_status,'A') <> 'ERROR' THEN

            gc_return_status := 'WARNING';

         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => lc_return_status
                                ,p_msg_count               => ln_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                ,p_error_message_count     => ln_msg_count
                                ,p_error_message_code      => 'XX_TM_0015_ENDDTSLSREP_F'
                                ,p_error_message           => lc_msg_data
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MINOR'
                                );

      ELSE

        DEBUG_LOG('In Procedure:PROCESS_RES_TERMINATION: Proc: ENDDATE_SALESREP Success');

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

         WRITE_LOG(x_msg_data);
         DEBUG_LOG('In Procedure: PROCESS_RES_TERMINATION: Proc: ENDDATE_RESOURCE Fails. ');

         gc_return_status    := 'ERROR';

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => x_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_TERMINATION'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_RES_TERMINATION;

   -- +====================================================================+
   -- | Name  : PROCESS_RES_REINSTATE                                      |
   -- |                                                                    |
   -- | Description:       This Procedure shall invoke the procedure       |
   -- |                    REINSTATE_SALESREP to reinstate the salesreps   |
   -- |                    and ENDDATE_RESOURCE to reinstate the resource. |
   -- |                                                                    |
   -- +====================================================================+


   PROCEDURE PROCESS_RES_REINSTATE
                              (x_return_status    OUT NOCOPY  VARCHAR2
                              ,x_msg_count        OUT NOCOPY  NUMBER
                              ,x_msg_data         OUT NOCOPY  VARCHAR2
                              ) IS

      ln_object_version_number         NUMBER;
      lc_error_message                 VARCHAR2(1000);
      lc_return_status                 VARCHAR2(1);
      ln_msg_count                     NUMBER;
      lc_msg_data                      VARCHAR2(1000);

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_RES_REINSTATE');

      REINSTATE_SALESREP
                 (p_resource_id     => gn_resource_id,
                  x_return_status   => lc_return_status,
                  x_msg_count       => ln_msg_count,
                  x_msg_data        => lc_msg_data
                 );

      x_msg_count := ln_msg_count;

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         DEBUG_LOG('In Procedure:PROCESS_RES_REINSTATE: Proc: REINSTATE_SALESREP Fails. ');

         IF NVL(gc_return_status,'A') <> 'ERROR' THEN

            gc_return_status := 'WARNING';

         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => lc_return_status
                                ,p_msg_count               => ln_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                                ,p_error_message_count     => ln_msg_count
                                ,p_error_message_code      => 'XX_TM_0015_ENDDTSLSREP_F'
                                ,p_error_message           => lc_msg_data
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MINOR'
                                );

      ELSE

        DEBUG_LOG('In Procedure:PROCESS_RES_REINSTATE: Proc: REINSTATE_SALESREP Success');

      END IF;

      ENDDATE_RESOURCE
                    ( p_resource_id        => gn_resource_id
                    , p_resource_number    => gc_resource_number
                    , p_end_date_active    => NULL
                    , p_object_version_num => gn_res_obj_ver_number
                    , x_return_status      => x_return_status
                    , x_msg_count          => x_msg_count
                    , x_msg_data           => x_msg_data
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

         WRITE_LOG(x_msg_data);
         DEBUG_LOG('In Procedure: PROCESS_RES_REINSTATE: Proc: ENDDATE_RESOURCE Fails. ');

         gc_return_status    := 'ERROR';

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                 p_return_code             => x_return_status
                                ,p_msg_count               => x_msg_count
                                ,p_application_name        => GC_APPN_NAME
                                ,p_program_type            => GC_PROGRAM_TYPE
                                ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                                ,p_program_id              => gc_conc_prg_id
                                ,p_module_name             => GC_MODULE_NAME
                                ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                                ,p_error_message_count     => x_msg_count
                                ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                ,p_error_message           => x_msg_data
                                ,p_error_status            => GC_ERROR_STATUS
                                ,p_notify_flag             => GC_NOTIFY_FLAG
                                ,p_error_message_severity  =>'MAJOR'
                                );

      ELSE

         DEBUG_LOG('In Procedure:PROCESS_RES_REINSTATE: Proc: ENDDATE_RESOURCE Success');

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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_REINSTATE'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_RES_REINSTATE;


   -- +===================================================================+
   -- | Name  : PROCESS_RES_CHANGES_RETRO                                 |
   -- |                                                                   |
   -- | Description:       This Procedure shall process job title change  |
   -- |                    as of a date equal to or past current job      |
   -- |                    assignment date for a resource. Also supervisor| 
   -- |                    change as of a date equal to or past current   |
   -- |                    supervisor effective date will be processed.   |
   -- +===================================================================+

   PROCEDURE PROCESS_RES_CHANGES_RETRO
                              (x_return_status    OUT NOCOPY  VARCHAR2
                              ,x_msg_count        OUT NOCOPY  NUMBER
                              ,x_msg_data         OUT NOCOPY  VARCHAR2
                              ) IS
      CURSOR  lcu_job_type IS
      SELECT  NVL(SUM(DECODE(NVL(jrr.admin_flag, 'N'),   'Y', 1, 0)), 0) adm_role_cnt,
              NVL(SUM(DECODE(NVL(jrr.manager_flag, 'N'), 'Y', 1, 0)), 0) mgr_role_cnt,
              NVL(SUM(DECODE(NVL(jrr.member_flag, 'N'),  'Y', 1, 0)), 0) mbr_role_cnt
      FROM    jtf_rs_job_roles_vl jrv,
              jtf_rs_roles_vl     jrr
      WHERE   jrv.job_id  = gn_job_id
        AND   jrr.role_id = jrv.role_id
        AND   jrr.role_type_code in ('SALES', 'COLLECTIONS')
        AND   NVL(jrr.active_flag, 'N') = 'Y'
        AND   NVL(jrr.attribute14, 'X') <> GC_PROXY_ROLE; -- Ignore Proxy admin role

      CURSOR  lcu_get_group(c_person_id NUMBER) IS
      SELECT  group_id
      FROM    jtf_rs_groups_vl
      WHERE   attribute15  = c_person_id
        AND   gd_mgr_asgn_date BETWEEN start_date_active and NVL(end_date_active, gd_mgr_asgn_date+1);

      CURSOR  lcu_rsc_roles_retro IS
      SELECT  DISTINCT 
              JRRR.role_relate_id,         
              JRRR.role_resource_type,     
              JRRR.role_resource_id,       
              JRRR.role_id,   
              JRRV.role_name,             
              JRRR.start_date_active,      
              JRRR.end_date_active, 
              JRRR.object_version_number,
              JRRR.delete_flag            
      FROM    jtf_rs_role_relations JRRR,
              jtf_rs_roles_vl       JRRV
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type = 'RS_INDIVIDUAL'
      AND     ((gd_job_asgn_date BETWEEN JRRR.start_date_active 
                                     AND NVL(JRRR.end_date_active, (gd_job_asgn_date+1))) OR
               (JRRR.start_date_active > gd_job_asgn_date AND 
                NVL(JRRR.end_date_active, JRRR.start_date_active + 1) >= JRRR.start_date_active
               )
              )
      AND     NVL(JRRR.delete_flag, 'N') <> 'Y'            
      AND     JRRV.role_id = JRRR.role_id
      AND     NVL(JRRV.attribute14, 'XX') <> GC_PROXY_ROLE  -- Ignore Proxy Roles
      AND     JRRR.role_id NOT IN (
                                   SELECT  DISTINCT JRRV1.role_id
                                   FROM    jtf_rs_job_roles_vl JRJV1,
                                           jtf_rs_roles_vl     JRRV1 
                                   WHERE   JRJV1.job_id  = gn_job_id
                                     AND   JRRV1.role_id = JRJV1.role_id
                                     AND   JRRV1.role_type_code in ('SALES', 'COLLECTIONS')
                                     AND   NVL(JRRV1.active_flag, 'N') = 'Y'
                                  );               


      CURSOR   lcu_grp_roles_retro(c_grp_id NUMBER) IS
      SELECT   DISTINCT 
               JRRR.role_relate_id,         
               JRRR.role_resource_type,     
               JRRR.role_resource_id,       
               JRRR.role_id,  
               JRRV.role_name,                           
               JRRR.start_date_active,      
               JRRR.end_date_active, 
               JRRR.object_version_number,
               JRRR.delete_flag            
      FROM     jtf_rs_role_relations JRRR,
               jtf_rs_group_members  JRGM,
               jtf_rs_roles_vl       JRRV
      WHERE    JRGM.resource_id = gn_resource_id
      AND      NVL(JRGM.delete_flag, 'N') <> 'Y'
      AND      JRRR.role_resource_id = JRGM.group_member_id
      AND      JRRR.role_resource_type = 'RS_GROUP_MEMBER'
      AND      NVL(JRRR.delete_flag, 'N') <> 'Y'
      AND     ((gd_mgr_asgn_date BETWEEN JRRR.start_date_active 
                                     AND NVL(JRRR.end_date_active, (gd_mgr_asgn_date+1))) OR
               (JRRR.start_date_active > gd_mgr_asgn_date AND 
                NVL(JRRR.end_date_active, JRRR.start_date_active + 1) >= JRRR.start_date_active
               )
              )
      AND      JRRV.role_id = JRRR.role_id
      AND      NVL(JRRV.attribute14, 'XX') <> GC_PROXY_ROLE  -- Ignore Proxy Roles
      AND      (JRGM.group_id <> c_grp_id OR
                (JRRR.role_id NOT IN (
                                      SELECT  DISTINCT JRRV1.role_id
                                      FROM    jtf_rs_job_roles_vl JRJV1,
                                              jtf_rs_roles_vl     JRRV1 
                                      WHERE   JRJV1.job_id  = gn_job_id
                                        AND   JRRV1.role_id = JRJV1.role_id
                                        AND   JRRV1.role_type_code in ('SALES', 'COLLECTIONS')
                                        AND   NVL(JRRV1.active_flag, 'N') = 'Y'
                                     )
                )                
               );

      ln_adm_count     NUMBER := 0;
      ln_mgr_count     NUMBER := 0;
      ln_mbr_count     NUMBER := 0;
      ln_grp_src_id    NUMBER;
      ln_group_id      NUMBER;
      lc_delete        VARCHAR2(1);
      ld_end_date      DATE;
      lc_return_status VARCHAR2(1);
      ln_msg_count     NUMBER;
      lc_msg_data      VARCHAR2(1000);      
   BEGIN
      DEBUG_LOG('Inside Proc: PROCESS_RES_CHANGES_RETRO');

      -- Reset the out parameters
      x_return_status    := NULL;
      x_msg_count        := NULL;
      x_msg_data         := NULL;


      -- End date (and delete if required for junk history) group membership roles if not in the valid group and/or 
      -- with the valid role as of supervisor effective date.
      -- (IF gd_mgr_asgn_date <= gd_crm_mgr_asgn_date THEN) --> Commented as always needed

      OPEN  lcu_job_type;
      FETCH lcu_job_type INTO ln_adm_count, ln_mgr_count, ln_mbr_count;
      CLOSE lcu_job_type;

      -- Decide current group source id based on role type
      IF ln_adm_count > 0 THEN 
        ln_grp_src_id := -1;     
        ln_group_id   := gn_sales_admin_grp_id;  -- Admin group
      ELSIF ln_mgr_count > 0 THEN
        ln_grp_src_id := gn_person_id; -- Manager's own group
        ln_group_id   := NULL;
      ELSE  -- All are member roles
        ln_grp_src_id := gn_supervisor_id; -- Member belongs to supervisor's group
        ln_group_id   := NULL;
      END IF;

      -- Find group id if resource does not have admin role based on group source id(person id or supervisor id)
      IF ln_grp_src_id <> -1 THEN
        OPEN  lcu_get_group(ln_grp_src_id);
        FETCH lcu_get_group INTO ln_group_id;
        CLOSE lcu_get_group;
      END IF;

      WRITE_LOG('Group ID = ' || ln_group_id || ' Grp Source Id = ' || ln_grp_src_id);

      FOR mbr_role_rec IN lcu_grp_roles_retro(ln_group_id) LOOP
        IF (gd_mgr_asgn_date - 1) >= mbr_role_rec.start_date_active THEN
          ld_end_date := (gd_mgr_asgn_date - 1);
          lc_delete   := 'N';
        ELSE
          ld_end_date := mbr_role_rec.start_date_active;
          lc_delete   := 'Y';
        END IF; 

        WRITE_LOG('End Dating Grp MBR Role = ' || mbr_role_rec.role_name);

        ENDDATE_RES_GRP_ROLE
               (p_role_relate_id   => mbr_role_rec.role_relate_id
               ,p_end_date_active  => ld_end_date
               ,p_object_version   => mbr_role_rec.object_version_number
               ,x_return_status    => lc_return_status
               ,x_msg_count        => ln_msg_count
               ,x_msg_data         => lc_msg_data
               );


        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          WRITE_LOG(lc_msg_data);
          WRITE_LOG('Role = ' || mbr_role_rec.role_name || ' Start Date = ' || mbr_role_rec.start_date_active ||
                    ' End Date = ' || mbr_role_rec.start_date_active ||
                    'Proposed End Date = ' || ld_end_date
                   );
          DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: ENDDATE_RES_GRP_ROLE Fails. ');

          IF NVL(gc_return_status,'A') <> 'ERROR' THEN
            gc_return_status := 'WARNING';
          END IF;

          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                       p_return_code             => lc_return_status
                                      ,p_msg_count               => ln_msg_count
                                      ,p_application_name        => GC_APPN_NAME
                                      ,p_program_type            => GC_PROGRAM_TYPE
                                      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                      ,p_error_message_count     => ln_msg_count
                                      ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                      ,p_error_message           => lc_msg_data
                                      ,p_error_status            => GC_ERROR_STATUS
                                      ,p_notify_flag             => GC_NOTIFY_FLAG
                                      ,p_error_message_severity  =>'MAJOR'
                                      );

        ELSE
          DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: ENDDATE_RES_GRP_ROLE Success');

          -- Check if invalid resource-role relationship data needs to be deleted
          IF lc_delete = 'Y' THEN
            WRITE_LOG('Deleting Grp Mbr Role = ' || mbr_role_rec.role_name);
            DELETE_ROLE_RELATE(P_ROLE_RELATE_ID  => mbr_role_rec.role_relate_id,
                               P_OBJECT_VERSION  => mbr_role_rec.object_version_number + 1, -- Add 1 after end dating
                               X_RETURN_STATUS   => lc_return_status,
                               X_MSG_COUNT       => ln_msg_count,
                               X_MSG_DATA        => lc_msg_data
                              ); 


            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              WRITE_LOG(lc_msg_data);
              DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: DELETE_ROLE_RELATE Fails. ');
              DEBUG_LOG('Role Relate ID = ' || mbr_role_rec.role_relate_id);
              DEBUG_LOG('Object Ver = ' || mbr_role_rec.object_version_number);

              IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                gc_return_status := 'WARNING';
              END IF;

              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_return_code             => lc_return_status
                                    ,p_msg_count               => ln_msg_count
                                    ,p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_error_message_count     => ln_msg_count
                                    ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                    ,p_error_message           => lc_msg_data
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );

            ELSE
              DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: DELETE_ROLE_RELATE Success');
            END IF;

          END IF;  --lc_delete = 'Y'

        END IF;
           
      END LOOP;

      -- END IF;  --> Commented as always needed

      -- End date (and delete if required for junk history) resource role relations 
      -- with the invalid role as of job effective date.      
      -- IF gd_job_asgn_date <= gd_crm_job_asgn_date THEN --> Commented as always needed

      FOR rsc_role_rec IN lcu_rsc_roles_retro LOOP
        -- Always compare supervisor assignment date as it might always be a later date for end dating
        IF (gd_mgr_asgn_date - 1) >= rsc_role_rec.start_date_active THEN
          ld_end_date := (gd_mgr_asgn_date - 1);
          lc_delete   := 'N';
        ELSE
          ld_end_date := rsc_role_rec.start_date_active;
          lc_delete   := 'Y';
        END IF; 

        WRITE_LOG('End Dating Resource Role = ' || rsc_role_rec.role_name);

        ENDDATE_RES_ROLE(P_ROLE_RELATE_ID  => rsc_role_rec.role_relate_id,
                         P_END_DATE_ACTIVE => ld_end_date,
                         P_OBJECT_VERSION  => rsc_role_rec.object_version_number,
                         X_RETURN_STATUS   => lc_return_status,
                         X_MSG_COUNT       => ln_msg_count,
                         X_MSG_DATA        => lc_msg_data
                        ); 


        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          WRITE_LOG(lc_msg_data);
          WRITE_LOG('Role = ' || rsc_role_rec.role_name || ' Start Date = ' || rsc_role_rec.start_date_active ||
                    ' End Date = ' || rsc_role_rec.start_date_active ||
                    'Proposed End Date = ' || ld_end_date
                   );
          DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: ENDDATE_RES_ROLE Fails. ');

          IF NVL(gc_return_status,'A') <> 'ERROR' THEN
            gc_return_status := 'WARNING';
          END IF;

          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_return_code             => lc_return_status
                                    ,p_msg_count               => ln_msg_count
                                    ,p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_error_message_count     => ln_msg_count
                                    ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                    ,p_error_message           => lc_msg_data
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );

        ELSE
          DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: ENDDATE_RES_ROLE Success');
          -- Check if invalid resource-role relationship data needs to be deleted
          IF lc_delete = 'Y' THEN
            WRITE_LOG('Deleting Resource Role = ' || rsc_role_rec.role_name);
            DELETE_ROLE_RELATE(P_ROLE_RELATE_ID  => rsc_role_rec.role_relate_id,
                               P_OBJECT_VERSION  => rsc_role_rec.object_version_number + 1, -- Add 1 after end dating
                               X_RETURN_STATUS   => lc_return_status,
                               X_MSG_COUNT       => ln_msg_count,
                               X_MSG_DATA        => lc_msg_data
                              ); 


            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
              WRITE_LOG(lc_msg_data);
              DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: DELETE_ROLE_RELATE Fails. ');

              IF NVL(gc_return_status,'A') <> 'ERROR' THEN
                gc_return_status := 'WARNING';
              END IF;

              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                     p_return_code             => lc_return_status
                                    ,p_msg_count               => ln_msg_count
                                    ,p_application_name        => GC_APPN_NAME
                                    ,p_program_type            => GC_PROGRAM_TYPE
                                    ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_program_id              => gc_conc_prg_id
                                    ,p_module_name             => GC_MODULE_NAME
                                    ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                                    ,p_error_message_count     => ln_msg_count
                                    ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                    ,p_error_message           => lc_msg_data
                                    ,p_error_status            => GC_ERROR_STATUS
                                    ,p_notify_flag             => GC_NOTIFY_FLAG
                                    ,p_error_message_severity  =>'MAJOR'
                                    );

            ELSE
              DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES_RETRO: Proc: DELETE_ROLE_RELATE Success');
            END IF;

          END IF; -- lc_delete = 'Y' 

        END IF; -- end date resource role succeeds
           
      END LOOP;
      -- END IF; -- gd_job_asgn_date <= gd_crm_job_asgn_date  --> Commented as always needed
  
   EXCEPTION
      WHEN OTHERS THEN

      x_return_status     := FND_API.G_RET_STS_ERROR;
      gc_return_status    :='ERROR';
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES_RETRO'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
                           );

   END PROCESS_RES_CHANGES_RETRO;

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
      lc_termin_prgm             VARCHAR2(1) := 'N';
      lc_job_name                PER_JOBS.name%TYPE; -- 30/07/08
      lc_role_type_flag          VARCHAR2(1); 
      lc_invalid_job_flag        VARCHAR2(1); 
      lc_resource_name           jtf_rs_resource_extns_vl.resource_name%TYPE;
      lc_resource_number         jtf_rs_resource_extns_vl.resource_number%TYPE;
      ln_obj_ver_num             jtf_rs_resource_extns_vl.object_version_number%TYPE;


      EX_TERMINATE_PRGM          EXCEPTION;
      SKIP_FURTHER_PROCESS       EXCEPTION;

      CURSOR  lcu_get_job
      IS
      SELECT  job_id
--            , TRUNC(TO_DATE(PAAF.ass_attribute10,'rrrr/mm/dd hh24:mi:ss')) JOB_ASGN_DATE --04/Dec/07
--            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'rrrr/mm/dd hh24:mi:ss')) MGR_ASGN_DATE --04/Dec/07
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
      FROM    per_all_assignments_f PAAF
      WHERE   person_id         = gn_person_id
      AND     business_group_id = gn_biz_grp_id
      AND     gd_as_of_date
              BETWEEN effective_start_date
              AND     NVL(effective_end_date,gd_as_of_date);

      CURSOR  lcu_get_roles_to_enddate(p_job_id   NUMBER)
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
             ,JRGMR.role_relate_id MBR_RELATE_ID
             ,JRRR2.object_version_number MBR_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
             ,jtf_rs_roles_vl JRRV
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.delete_flag        = 'N'
      AND     JRRV.role_id = JRRR.role_id
      AND     NVL(JRRV.attribute14, 'X') <> GC_PROXY_ROLE  --  01/16/2008 Ignore Proxy Roles
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     JRRR2.delete_flag       = 'N'
      AND     gd_job_asgn_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_job_asgn_date)
      AND     gd_mgr_asgn_date  -- Changed from gd_job_asgn_date as group member role eff date is always sup eff date.
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_mgr_asgn_date)
      AND     gd_mgr_asgn_date -- Changed from gd_job_asgn_date as group member role eff date is always sup eff date.
              BETWEEN   JRRR2.start_date_active
              AND       NVL(JRRR2.end_date_active,gd_mgr_asgn_date)
      AND     JRRR.role_id NOT IN (
                                   SELECT  role_id
                                   FROM    jtf_rs_job_roles_vl
                                   WHERE   job_id  = p_job_id
                                  );

      CURSOR  lcu_check_is_mgr
      IS
      SELECT 'Y' MGR_FLAG
      FROM    DUAL
      WHERE   EXISTS(
      SELECT  1
      FROM    jtf_rs_role_relations_vl JRLV
             ,jtf_rs_roles_b           JRRB
      WHERE   JRLV.manager_flag     = 'Y'
      AND    (JRLV.role_type_code   = 'SALES'
      --OR      JRLV.role_type_code   = 'SALES_COMP') -- 25/07/08
      OR      JRLV.role_type_code   = 'SALES_COMP'
      OR      JRLV.role_type_code   = 'COLLECTIONS') -- 25/07/08
      AND     JRLV.role_id          =  JRRB.role_id
      AND     JRLV.role_resource_id =  gn_resource_id
      AND     gd_job_asgn_date
              BETWEEN   JRLV.start_date_active
              AND       NVL(JRLV.end_date_active,gd_job_asgn_date)
      AND     NVL(JRRB.active_flag,'N') = 'Y');

      CURSOR  lcu_get_asgn_slsupport_roles
      IS
      SELECT  JRRR.role_relate_id  ROLES_RELATE_ID
             ,JRRR.object_version_number ROLES_OBJ_VER_NUM
             ,JRRR.start_date_active START_DATE_ACTIVE
             ,JRGMR.role_relate_id MBR_RELATE_ID
             ,JRGMR.start_date_active MBR_START_DATE_ACTIVE
             ,JRRR2.object_version_number MBR_OBJ_VER_NUM
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
             ,jtf_rs_roles_vl  JRRV
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRR.delete_flag        = 'N'
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     JRRR2.delete_flag       = 'N'
      AND     JRRV.role_id            = JRRR.role_id
      AND     JRRV.attribute14        ='SALES_SUPPORT'
      AND     gd_job_asgn_date
              BETWEEN   JRRR.start_date_active
              AND       NVL(JRRR.end_date_active,gd_job_asgn_date)
      AND     gd_mgr_asgn_date  -- Changed from gd_job_asgn_date as group member role eff date is always sup eff date.
              BETWEEN   JRGMR.start_date_active
              AND       NVL(JRGMR.end_date_active,gd_mgr_asgn_date);

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
      --SELECT  TO_DATE(attribute14,'MM/DD/RRRR') JOB_ASGN_DATE --04/DEC/07
      --       ,TO_DATE(attribute15,'MM/DD/RRRR') MGR_ASGN_DATE --04/DEC/07
      SELECT  TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
             ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
             ,resource_name
             ,resource_number
             ,object_version_number
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      CURSOR  lcu_check_job_change(p_job_id   NUMBER)
      IS
      SELECT  'Y' job_change
      FROM    jtf_rs_role_relations JRRR
             ,jtf_rs_group_mbr_role_vl JRGMR
             ,jtf_rs_role_relations JRRR2
             ,jtf_rs_roles_vl JRRV
      WHERE   JRRR.role_resource_id   = gn_resource_id
      AND     JRRR.role_resource_type ='RS_INDIVIDUAL'
      AND     JRRV.role_id = JRRR.role_id
      AND     NVL(JRRV.attribute14, 'X') <> GC_PROXY_ROLE  -- Ignore Proxy Roles
      AND     JRGMR.resource_id       = JRRR.role_resource_id
      AND     JRGMR.role_id           = JRRR.role_id
      AND     JRRR2.role_relate_id    = JRGMR.role_relate_id
      AND     JRRR.end_date_active IS NULL
      AND     JRGMR.end_date_active IS NULL
      AND     JRRR2.end_date_active IS NULL
      AND     JRRR.delete_flag = 'N'-- 11/Dec/07
      AND     JRRR2.delete_flag = 'N'-- 11/Dec/07
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

      CURSOR  lcu_get_mgr_date
      IS
      SELECT  DISTINCT start_date_active
      FROM    jtf_rs_group_mbr_role_vl
      WHERE   end_date_active IS NULL
      AND     resource_id   =  gn_resource_id;

      lr_check_resource              lcu_check_res_st_date%ROWTYPE;
      TYPE      date_tbl_type        IS TABLE OF DATE
      INDEX BY BINARY_INTEGER;
      lt_date   date_tbl_type;
      
      
      -- Added on 29/07/08
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
                  AND    JRRV.role_type_code IN ('SALES','SALES_COMP','SALES_COMP_PAYMENT_ANALIST')
                  )      
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code = 'COLLECTIONS' 
                 );  
       
      CURSOR  lcu_get_invalid_job
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
                  AND    JRRV.role_type_code = 'COLLECTIONS'
                  AND    JRRV.member_flag = 'Y'
                  )      
      AND EXISTS
                 (
                  SELECT 1
                  FROM   jtf_rs_roles_vl JRRV
                        ,jtf_rs_job_roles JRJR
                  WHERE  JRRV.role_id = JRJR.role_id
                  AND    JRJR.job_id  = gn_job_id
                  AND    NVL(JRRV.active_flag,'N')    = 'Y'
                  AND    JRRV.role_type_code = 'COLLECTIONS'
                  AND    JRRV.admin_flag = 'Y'
                 );         
       
      -- Added on 30/07/08
      CURSOR lcu_get_job_name
      IS
      SELECT name             
      FROM   per_jobs
      WHERE  job_id = gn_job_id;
      
      -- Added on 30/07/08

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_RES_CHANGES');

      OPEN  lcu_get_resource_det;

      FETCH lcu_get_resource_det 
      INTO  gd_crm_job_asgn_date,gd_crm_mgr_asgn_date, lc_resource_name,
            lc_resource_number, ln_obj_ver_num;

      CLOSE lcu_get_resource_det;    
                                       
      -- Added on 12/Jun/08
     
      IF lcu_get_job%ISOPEN THEN
     
         CLOSE lcu_get_job;
     
      END IF;
      
      OPEN  lcu_get_job;
      
      FETCH lcu_get_job INTO gn_job_id,gd_job_asgn_date,gd_mgr_asgn_date;
      
      CLOSE lcu_get_job;
      
      DEBUG_LOG('gn_job_id:'||gn_job_id);
      DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date);
      DEBUG_LOG('HRMS_MGR_ASGN_DATE:'||gd_mgr_asgn_date);
      
      -- Added on 12/Jun/08

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
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR
                               ,p_msg_count               => 1
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1
                               ,p_error_message_code      =>'XX_TM_0095_NONUNQ_ROLE_DATE'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         ELSIF lt_date.count = 0 THEN

            /*Commented on 12/Jun/08
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0096_NO_RES_ROLES');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;

            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR
                               ,p_msg_count               => 1
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1
                               ,p_error_message_code      =>'XX_TM_0096_NO_RES_ROLES'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;
            Commented on 12/Jun/08 */
            
            -- Added on 12/Jun/08
            gd_crm_job_asgn_date:=gd_job_asgn_date;
            -- Added on 12/Jun/08

         ELSE

            gd_crm_job_asgn_date :=  lt_date(1);

         END IF;

      END IF;  -- end if, gd_crm_job_asgn_date IS NULL

      IF gd_crm_mgr_asgn_date IS NULL THEN

         IF lt_date.count > 0  THEN

            lt_date.delete;

         END IF;

         OPEN  lcu_get_mgr_date;

         FETCH lcu_get_mgr_date BULK COLLECT INTO lt_date;

         CLOSE lcu_get_mgr_date;

         -- DEBUG_LOG('Supervisor Assignment Date:'||lt_date);

         IF lt_date.count > 1 THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0097_NONUNQ_GRPMBRSHP');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0097_NONUNQ_GRPMBRSHP'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         ELSIF lt_date.count = 0 THEN

            /* Commented on 12/Jun/08
            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0098_NO_RES_GRPMBRSHP');
            gc_errbuf := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(gc_errbuf);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
            ELSE
               gc_err_msg := gc_errbuf;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_return_code             => FND_API.G_RET_STS_ERROR--x_return_status
                                  ,p_msg_count               => 1
                                  ,p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                  ,p_error_message_count     => 1
                                  ,p_error_message_code      => 'XX_TM_0098_NO_RES_GRPMBRSHP'
                                  ,p_error_message           => gc_errbuf
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
            Commented on 12/Jun/08 */     
            
            -- Added on 12/Jun/08
            gd_crm_mgr_asgn_date := gd_mgr_asgn_date;
            -- Added on 12/Jun/08

         ELSE

            gd_crm_mgr_asgn_date :=  lt_date(1);

         END IF;

      END IF;  -- end if, gd_crm_mgr_asgn_date IS NULL

      /* Commented on 12/Jun/08
      IF lcu_get_job%ISOPEN THEN

         CLOSE lcu_get_job;

      END IF;
      
      OPEN  lcu_get_job;

      FETCH lcu_get_job INTO gn_job_id,gd_job_asgn_date,gd_mgr_asgn_date;

      CLOSE lcu_get_job;

      DEBUG_LOG('gn_job_id:'||gn_job_id);
      DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date);
      DEBUG_LOG('HRMS_MGR_ASGN_DATE:'||gd_mgr_asgn_date);
      */
      
      DEBUG_LOG('CRM_JOB_ASGN_DATE:'||gd_crm_job_asgn_date);
      DEBUG_LOG('CRM_MGR_ASGN_DATE:'||gd_crm_mgr_asgn_date);  

      -- If resource name has changed because of marriage, divorce etc. in HR then update
      IF NVL(lc_resource_name, 'XX') <> NVL(gc_full_name, 'XX') THEN
        UPDATE_RESOURCE_NAME
                       ( p_resource_id        =>  gn_resource_id
                       , p_resource_number    =>  lc_resource_number
                       , p_resource_name      =>  gc_full_name
                       , p_source_name        =>  gc_full_name
                       , p_object_version_num =>  ln_obj_ver_num
                       , x_return_status      =>  x_return_status
                       , x_msg_count          =>  x_msg_count
                       , x_msg_data           =>  x_msg_data
                       );

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          WRITE_LOG(x_msg_data);
          DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: UPDATE_RESOURCE_NAME Fails. ');

          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MAJOR'
                                     );

          RAISE EX_TERMINATE_PRGM;

        ELSE

          DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: UPDATE_RESOURCE_NAME Success ');

        END IF;

      END IF;  -- Resource Name Changed Check

      -- Check if retro hierarchy fix is required --> Commented as always needed
      -- IF gd_job_asgn_date <= gd_crm_job_asgn_date OR gd_mgr_asgn_date <= gd_crm_mgr_asgn_date THEN
      PROCESS_RES_CHANGES_RETRO(x_return_status,
                                x_msg_count,
                                x_msg_data
                               );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

        WRITE_LOG(x_msg_data);
        DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: PROCESS_RES_CHANGES_RETRO Fails. ');

        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      =>'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MAJOR'
                                     );

        RAISE EX_TERMINATE_PRGM;

      ELSE

        DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: PROCESS_RES_CHANGES_RETRO Success ');

      END IF;

      --END IF; --> Commented as always needed
    

      /* Commented on 01/15/2008 as error check no more needed (Retro Case)
      IF gd_mgr_asgn_date < gd_crm_mgr_asgn_date THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0101_INV_MGR_ASGN_DT');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0101_INV_MGR_ASGN_DT'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

      END IF;  -- END IF, gd_mgr_asgn_date < gd_crm_mgr_asgn_date
      */



      -- Added on 18/Mar/08
      IF lcu_check_job_change%ISOPEN THEN

         CLOSE lcu_check_job_change;

      END IF;

      OPEN  lcu_check_job_change(gn_job_id);

      FETCH lcu_check_job_change INTO lc_job_change_exists;

      CLOSE lcu_check_job_change;

      gc_job_chng_exists := NVL(lc_job_change_exists,'N');-- 28/02/08     
      

      IF NVL(lc_job_change_exists,'N') = 'Y' THEN
      
         -- 29/07/08                        
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

	 IF lcu_get_invalid_job%ISOPEN THEN
	 
	    CLOSE lcu_get_invalid_job;
	 
         END IF;
                        
	 OPEN  lcu_get_invalid_job;	    
         FETCH lcu_get_invalid_job INTO lc_invalid_job_flag;
	 CLOSE lcu_get_invalid_job;                         

         IF  NVL(lc_role_type_flag,'N') = 'Y' THEN             

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0269_INVALID_JOB'); 
            FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id ); -- 30/07/08
            FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 30/07/08
            gc_errbuf := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(gc_errbuf);
           
            gc_return_status  := 'ERROR';
             
            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
            ELSE
               gc_err_msg := gc_errbuf;
            END IF;           
            
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                    p_return_code             => x_return_status
                                   ,p_msg_count               => 1
                                   ,p_application_name        => GC_APPN_NAME
                                   ,p_program_type            => GC_PROGRAM_TYPE
                                   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_program_id              => gc_conc_prg_id
                                   ,p_module_name             => GC_MODULE_NAME
                                   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_error_message_count     => 1
                                   ,p_error_message_code      => 'XX_TM_0269_INVALID_JOB'
                                   ,p_error_message           => gc_errbuf
                                   ,p_error_status            => GC_ERROR_STATUS
                                   ,p_notify_flag             => GC_NOTIFY_FLAG
                                   ,p_error_message_severity  =>'MAJOR'
                                 );                       
                        
            RAISE EX_TERMINATE_PRGM;
         
         END IF;    
         
        IF  NVL(lc_invalid_job_flag,'N') = 'Y' THEN             

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0268_INVALID_JOB'); 
            FND_MESSAGE.SET_TOKEN('P_JOB_ID', gn_job_id ); -- 30/07/08
            FND_MESSAGE.SET_TOKEN('P_JOB_NAME', lc_job_name ); -- 30/07/08
            gc_errbuf := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(gc_errbuf);
           
            gc_return_status  := 'ERROR';
             
            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
            ELSE
               gc_err_msg := gc_errbuf;
            END IF;           
            
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                    p_return_code             => x_return_status
                                   ,p_msg_count               => 1
                                   ,p_application_name        => GC_APPN_NAME
                                   ,p_program_type            => GC_PROGRAM_TYPE
                                   ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_program_id              => gc_conc_prg_id
                                   ,p_module_name             => GC_MODULE_NAME
                                   ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                   ,p_error_message_count     => 1
                                   ,p_error_message_code      => 'XX_TM_0268_INVALID_JOB'
                                   ,p_error_message           => gc_errbuf
                                   ,p_error_status            => GC_ERROR_STATUS
                                   ,p_notify_flag             => GC_NOTIFY_FLAG
                                   ,p_error_message_severity  =>'MAJOR'
                                 );                       
                        
            RAISE EX_TERMINATE_PRGM;
         
         END IF;           

         -- 29/07/08           
         /* Commented on 01/15/2009 as error check is no more required and handled in retro logic
         IF gd_job_asgn_date < greatest(gd_crm_mgr_asgn_date,gd_crm_job_asgn_date) THEN

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0259_INV_JOB_ASGN_DT');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0259_INV_JOB_ASGN_DT'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;

         END IF;
         */
      END IF;

       -- If Backdate or Future date or Job change Exists -- 18/Mar/08
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
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
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

            IF gc_hierarchy_type = 'SALES' THEN -- 28/07/08
            
               BACKDATE_SALESREP
                        ( p_resource_id        => gn_resource_id
                        , p_start_date_active  => gd_job_asgn_date -- TO_DATE(gd_job_asgn_date,'MM/DD/RRRR')
                        , x_return_status      => x_return_status
                        , x_msg_count          => x_msg_count
                        , x_msg_data           => x_msg_data
                        );

               IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  WRITE_LOG(x_msg_data);
                  DEBUG_LOG('In Procedure: PROCESS_RES_CHANGES: Proc: BACKDATE_SALESREP Fails. ');

                  IF NVL(gc_return_status,'A') <> 'ERROR' THEN

                     gc_return_status := 'WARNING';

                  END IF;

                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code             => x_return_status
                                       ,p_msg_count               => x_msg_count
                                       ,p_application_name        => GC_APPN_NAME
                                       ,p_program_type            => GC_PROGRAM_TYPE
                                       ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                       ,p_program_id              => gc_conc_prg_id
                                       ,p_module_name             => GC_MODULE_NAME
                                       ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                       ,p_error_message_count     => x_msg_count
                                       ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                       ,p_error_message           => x_msg_data
                                       ,p_error_status            => GC_ERROR_STATUS
                                       ,p_notify_flag             => GC_NOTIFY_FLAG
                                       ,p_error_message_severity  =>'MINOR'
                                       );

               END IF;
            END IF; -- 28/07/08  

      END IF;
      -- Added on 18/Mar/08

      DEBUG_LOG('Job Change Exists:'||NVL(lc_job_change_exists,'N'));
      IF (NVL(lc_job_change_exists,'N') = 'Y') THEN
         NULL; -- Null statement added to do nothing on 01/15/2009
         --
         -- If new job asgn date is lesser than old job assignment
         -- date error the process else the process shall continue
         --
         -- Commented on 01/15/2009 as error check is no more required and handled in retro logic
/*
         IF gd_crm_job_asgn_date > gd_job_asgn_date THEN

            DEBUG_LOG('HRMS_JOB_ASGN_DATE:'||gd_job_asgn_date ||' is lesser than '||'CRM_JOB_ASGN_DATE:'||gd_crm_job_asgn_date);

            FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0091_ROLES_OVERLAP');
            lc_error_message    := FND_MESSAGE.GET;
            FND_MSG_PUB.add;
            WRITE_LOG(lc_error_message);

            IF gc_err_msg IS NOT NULL THEN
               gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
            ELSE
               gc_err_msg := lc_error_message;
            END IF;

            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                p_return_code             => FND_API.G_RET_STS_ERROR -- x_return_status
                               ,p_msg_count               => 1 --x_msg_count
                               ,p_application_name        => GC_APPN_NAME
                               ,p_program_type            => GC_PROGRAM_TYPE
                               ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_program_id              => gc_conc_prg_id
                               ,p_module_name             => GC_MODULE_NAME
                               ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                               ,p_error_message_count     => 1 --x_msg_count
                               ,p_error_message_code      =>'XX_TM_0091_ROLES_OVERLAP'
                               ,p_error_message           => lc_error_message
                               ,p_error_status            => GC_ERROR_STATUS
                               ,p_notify_flag             => GC_NOTIFY_FLAG
                               ,p_error_message_severity  =>'MAJOR'
                               );

            RAISE EX_TERMINATE_PRGM;
         END IF; -- END IF, gd_crm_job_asgn_date > gd_job_asgn_date;
*/         

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
         FOR  roles_to_enddate_rec  IN  lcu_get_roles_to_enddate(gn_job_id)
         LOOP
            DEBUG_LOG('End dating Resource Grp Role Relate Id:'||roles_to_enddate_rec.mbr_relate_id);
            ENDDATE_RES_GRP_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.mbr_relate_id,
                     P_END_DATE_ACTIVE => gd_mgr_asgn_date -1,
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
                                      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
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
            DEBUG_LOG('roles_to_enddate_rec.mbr_relate_id:'||roles_to_enddate_rec.roles_relate_id);
            ENDDATE_RES_ROLE(
                     P_ROLE_RELATE_ID  => roles_to_enddate_rec.roles_relate_id,
                     P_END_DATE_ACTIVE => gd_job_asgn_date -1,   -- gd_as_of_date - 1,
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
                                      ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                      ,p_program_id              => gc_conc_prg_id
                                      ,p_module_name             => GC_MODULE_NAME
                                      ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
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

         IF lcu_check_is_mgr%ISOPEN THEN
            CLOSE lcu_check_is_mgr;
         END IF;

         OPEN  lcu_check_is_mgr;
         FETCH lcu_check_is_mgr INTO lc_manager_flag;
         CLOSE lcu_check_is_mgr;

         DEBUG_LOG('Manager Resource:'||NVL(lc_manager_flag,'N'));

         IF ( NVL(lc_manager_flag,'N') = 'Y' ) THEN

            DEBUG_LOG('Start of end dating Sales Support Res Grp Roles and Resource Roles');

            FOR  slsupport_role_rec IN lcu_get_asgn_slsupport_roles
            LOOP
               --Only End Date if start date is prior to or equal to gd_mgr_asgn_date -1
               IF slsupport_role_rec.mbr_start_date_active <= gd_mgr_asgn_date -1 THEN
                 DEBUG_LOG('End dating sales support resource group role:'||slsupport_role_rec.mbr_relate_id);
                 ENDDATE_RES_GRP_ROLE(
                     p_role_relate_id  => slsupport_role_rec.mbr_relate_id,
                     p_end_date_active => gd_mgr_asgn_date -1,
                     p_object_version  => slsupport_role_rec.mbr_obj_ver_num,
                     x_return_status   => lc_return_status,
                     x_msg_count       => ln_msg_count,
                     x_msg_data        => lc_msg_data
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
                                          ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                          ,p_program_id              => gc_conc_prg_id
                                          ,p_module_name             => GC_MODULE_NAME
                                          ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                          ,p_error_message_count     => ln_msg_count
                                          ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                          ,p_error_message           => lc_msg_data
                                          ,p_error_status            => GC_ERROR_STATUS
                                          ,p_notify_flag             => GC_NOTIFY_FLAG
                                          ,p_error_message_severity  =>'MINOR'
                                          );

                 ELSE

                   DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_GRP_ROLE for manager Success');

                 END IF;
               END IF;

               --Only End Date if start date is prior to or equal to gd_job_asgn_date -1
               IF slsupport_role_rec.start_date_active <= gd_job_asgn_date -1 THEN
                 DEBUG_LOG('End dating sales support resource role:'||slsupport_role_rec.roles_relate_id);

                 ENDDATE_RES_ROLE(
                     p_role_relate_id  => slsupport_role_rec.roles_relate_id,
                     p_end_date_active => gd_job_asgn_date - 1, -- gd_as_of_date - 1,
                     p_object_version  => slsupport_role_rec.roles_obj_ver_num,
                     x_return_status   => lc_return_status,
                     x_msg_count       => ln_msg_count,
                     x_msg_data        => lc_msg_data
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
                                          ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                          ,p_program_id              => gc_conc_prg_id
                                          ,p_module_name             => GC_MODULE_NAME
                                          ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                                          ,p_error_message_count     => ln_msg_count
                                          ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                          ,p_error_message           => lc_msg_data
                                          ,p_error_status            => GC_ERROR_STATUS
                                          ,p_notify_flag             => GC_NOTIFY_FLAG
                                          ,p_error_message_severity  =>'MINOR'
                                          );

                 ELSE

                   DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Proc: ENDDATE_RES_ROLE for manager Success');

                 END IF;
               END IF;
            END LOOP;
            DEBUG_LOG('End of end dating Sales Support Res Grp Roles and Resource Roles');

         END IF;  -- END IF, ( NVL(lc_manager_flag,'N') = 'Y' )

         PROCESS_RESOURCE_DETAILS
                 (x_return_status   => x_return_status
                 ,x_msg_count       => x_msg_count
                 ,x_msg_data        => x_msg_data
                 ,x_termin_prgm     => lc_termin_prgm
                 );            
                  
         IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN


           DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES: Resource details proccessed successfully');

         ELSE

           DEBUG_LOG('In Procedure:PROCESS_RES_CHANGES:Failed to process Resource details for :'||gn_resource_id);

         END IF;
         
         -- Added on 25/06/08
         IF lc_termin_prgm = 'N' THEN
            RAISE EX_TERMINATE_PRGM;
         END IF; 
         -- Added on 25/06/08

      ELSE

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0008_JOB_NULL');
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;
         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RES_CHANGES'
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

      lc_termination_status  VARCHAR2(1);
	  lc_termination_dt VARCHAR2(10);
	  lc_end_active_dt VARCHAR2(10);
      lc_error_message       VARCHAR2(1000);

      CURSOR  lcu_check_termination
      IS
      SELECT  
	  --Query changed for defect 15151 to ignore resources already terminated in RM
	  A.TERMINATION_STATUS, 
	  NVL(TO_CHAR(A.ACTUAL_TERMINATION_DATE,'DDMMYYYY'),'01011000') ACTUAL_TERMINATION_DATE, 
	  NVL(TO_CHAR(B.END_DATE_ACTIVE, 'DDMMYYYY'), '01011000') END_DATE_ACTIVE
      FROM   (SELECT  'Y' TERMINATION_STATUS, PPOS.actual_termination_date
              FROM    PER_ALL_PEOPLE_F       PAPF
                     ,PER_PERIODS_OF_SERVICE PPOS
                     ,PER_PERSON_TYPES       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   <= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EX_EMP'
              OR      PPT.SYSTEM_PERSON_TYPE          = 'EX_CWK')
              AND     PAPF.business_group_id          = gn_biz_grp_id
              AND     PPOS.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              --AND     gd_as_of_date -- Commented on 24/04/08
                AND     TRUNC(gd_as_of_date)
                      BETWEEN  PAPF.effective_start_date
                      AND      PAPF.effective_end_date           
              UNION
              SELECT  'Y' TERMINATION_STATUS, PPOS.actual_termination_date
              FROM    PER_ALL_PEOPLE_F       PAPF
                     ,PER_PERIODS_OF_SERVICE PPOS
                     ,PER_PERSON_TYPES       PPT
              WHERE   PAPF.person_id                  = gn_person_id
              AND     PAPF.person_id                  = PPOS.person_id
              AND     PPT.person_type_id              = PAPF.person_type_id
              AND     PPOS.actual_termination_date   >= TRUNC (gd_as_of_date)
              AND    (PPT.system_person_type          = 'EMP'
              --OR      PPT.system_person_type          = 'EX_EMP'-- Commented on 24/04/08              
              OR      PPT.SYSTEM_PERSON_TYPE          = 'CWK')
              AND     PAPF.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPOS.BUSINESS_GROUP_ID          = gn_biz_grp_id
              AND     PPT .business_group_id          = gn_biz_grp_id
              --AND     gd_as_of_date -- Commented on 24/04/08
                AND     TRUNC(gd_as_of_date)
                        BETWEEN  PAPF.effective_start_date
                        AND      PAPF.EFFECTIVE_END_DATE        	      
	      ) A, JTF_RS_RESOURCE_EXTNS_VL B
        WHERE B.SOURCE_ID = gn_person_id;

      -- Added on 12/24/2008
      CURSOR   lcu_rsc_roles is
      SELECT   JRRR.role_id,
               JRRV.role_name,
               JRRR.start_date_active,
               JRRR.end_date_active
      FROM     jtf_rs_role_relations JRRR,
               jtf_rs_roles_vl JRRV
      WHERE    JRRR.role_resource_id   = gn_resource_id
        AND    JRRR.role_resource_type = 'RS_INDIVIDUAL'
        AND    JRRV.role_id            = JRRR.role_id
        AND    JRRR.delete_flag        = 'N'
      ORDER BY JRRR.start_date_active;

      CURSOR   lcu_rsc_grp_roles is
      SELECT   JRGV.group_id,
               JRGV.group_name,
               JRRR.role_id,
               JRRV.role_name,
               JRRR.start_date_active,
               JRRR.end_date_active
      FROM     jtf_rs_role_relations JRRR,
               jtf_rs_group_members  JRGM,
               jtf_rs_roles_vl       JRRV,
               jtf_rs_groups_vl      JRGV
      WHERE    JRGM.resource_id = gn_resource_id
        AND    JRGM.delete_flag = 'N'
        AND    JRRR.role_resource_id = JRGM.group_member_id
        AND    JRRR.role_resource_type = 'RS_GROUP_MEMBER'
        AND    JRRV.role_id = JRRR.role_id
        AND    JRRR.delete_flag = 'N'
        AND    JRGV.group_id = JRGM.group_id
      ORDER BY JRRR.start_date_active;

      TYPE  role_tbl_type IS TABLE OF lcu_rsc_roles%ROWTYPE INDEX BY BINARY_INTEGER;
      TYPE  grprole_tbl_type IS TABLE OF lcu_rsc_grp_roles%ROWTYPE INDEX BY BINARY_INTEGER;
      lt_rsc_roles_bfr role_tbl_type;
      lt_rsc_roles_afr role_tbl_type;
      lt_grp_roles_bfr grprole_tbl_type;
      lt_grp_roles_afr grprole_tbl_type;

      -- Added on 12/24/2008
      CURSOR  lcu_get_resource_det
      IS
      SELECT  TO_DATE(attribute14,'DD-MON-RR') JOB_ASGN_DATE
             ,TO_DATE(attribute15,'DD-MON-RR') MGR_ASGN_DATE
      FROM    jtf_rs_resource_extns_vl
      WHERE   resource_id = gn_resource_id;

      ld_crm_job_asgn_date date;
      ld_crm_mgr_asgn_date date;

   BEGIN

      DEBUG_LOG('Inside Proc: PROCESS_EXISTING_RESOURCE');

      IF lcu_check_termination%ISOPEN THEN

         CLOSE lcu_check_termination;

      END IF;

      OPEN  lcu_check_termination;

      FETCH lcu_check_termination INTO lc_termination_status, lc_termination_dt, lc_end_active_dt;

      CLOSE lcu_check_termination;

      DEBUG_LOG('Resource Termination exists (Y/N): '||NVL(lc_termination_status,'N'));

      IF ( NVL(lc_termination_status,'N') = 'Y') THEN		 
		 IF (lc_termination_dt != lc_end_active_dt) THEN --Added for defect 15151. If the resource is terminated, compare the HRMS and RM end date.
														 --If both do not match, then proceed for resource termination.
			 DEBUG_LOG('Process Resource Termination');
			 PROCESS_RES_TERMINATION
						 (x_return_status    => x_return_status
						 ,x_msg_count        => x_msg_count
						 ,x_msg_data         => x_msg_data
						 );
		 END IF;
      ELSE

         -- Get the before snapshot
         lt_rsc_roles_bfr.DELETE;
         lt_grp_roles_bfr.DELETE;

         OPEN  lcu_rsc_roles;
         FETCH lcu_rsc_roles BULK COLLECT INTO lt_rsc_roles_bfr;
         CLOSE lcu_rsc_roles;

         OPEN  lcu_rsc_grp_roles ;
         FETCH lcu_rsc_grp_roles BULK COLLECT INTO lt_grp_roles_bfr;
         CLOSE lcu_rsc_grp_roles;

         -- If resource was terminated then reinstate
         IF gd_resource_end_date IS NOT NULL THEN
           PROCESS_RES_REINSTATE
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );
         END IF;

         IF NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) <> FND_API.G_RET_STS_ERROR THEN
           UPDATE_EMAIL
                     (p_resource_id       => gn_resource_id
                     ,x_return_status     => x_return_status
                     ,x_msg_count         => x_msg_count
                     ,x_msg_data          => x_msg_data
                     );
         END IF;

         DEBUG_LOG('After Call Procedure:UPDATE_EMAIL: x_return_status = ' || x_return_status);

         -- Code Added on 01/14/2008 --> Process Further if Update Email is Successful 
         IF NVL(x_return_status, FND_API.G_RET_STS_SUCCESS) <> FND_API.G_RET_STS_ERROR THEN
           PROCESS_RES_CHANGES
                       (x_return_status    => x_return_status
                       ,x_msg_count        => x_msg_count
                       ,x_msg_data         => x_msg_data
                       );
         END IF;

         -- Code Added on 12/29/2008 

         -- Added on 24-DEC-2008

         -- Get the after snapshot
         OPEN  lcu_get_resource_det;  
         FETCH lcu_get_resource_det INTO ld_crm_job_asgn_date,ld_crm_mgr_asgn_date;
         CLOSE lcu_get_resource_det;    

         lt_rsc_roles_afr.DELETE;
         lt_grp_roles_afr.DELETE;

         OPEN  lcu_rsc_roles;
         FETCH lcu_rsc_roles BULK COLLECT INTO lt_rsc_roles_afr;
         CLOSE lcu_rsc_roles;

         OPEN  lcu_rsc_grp_roles ;
         FETCH lcu_rsc_grp_roles BULK COLLECT INTO lt_grp_roles_afr;
         CLOSE lcu_rsc_grp_roles;

         DEBUG_LOG('Resource Id:'|| gn_resource_id);
         DEBUG_LOG('Resource Number:'|| gc_resource_number);
         DEBUG_LOG('gn_job_id:'||gn_job_id);

         DEBUG_LOG('*************** CRM Job and Mgr Assignment Dates (Before Change) ***************');      
         DEBUG_LOG('CRM_JOB_ASGN_DATE:'||gd_crm_job_asgn_date);
         DEBUG_LOG('CRM_MGR_ASGN_DATE:'||gd_crm_mgr_asgn_date);      
         DEBUG_LOG('*************** CRM Job and Mgr Assignment Dates (After Change) ***************');      
         DEBUG_LOG('CRM_JOB_ASGN_DATE:'||ld_crm_job_asgn_date);
         DEBUG_LOG('CRM_MGR_ASGN_DATE:'||ld_crm_mgr_asgn_date);

         DEBUG_LOG('*************** Resource Roles (Before Change) ***************');
         DEBUG_LOG('Role ID          Role Name                                        Start Date  End Date ');

         FOR i in 1..lt_rsc_roles_bfr.COUNT loop
           DEBUG_LOG(rpad(lt_rsc_roles_bfr(i).role_id, 17) || rpad(lt_rsc_roles_bfr(i).role_name, 49) || 
                     rpad(to_char(lt_rsc_roles_bfr(i).start_date_active), 12) || 
                     rpad(to_char(lt_rsc_roles_bfr(i).end_date_active), 12)
                    );
         END LOOP;

         DEBUG_LOG('*************** Resource Roles (After Change) ***************');
         FOR i in 1..lt_rsc_roles_afr.COUNT loop
           DEBUG_LOG(rpad(lt_rsc_roles_afr(i).role_id, 17) || rpad(lt_rsc_roles_afr(i).role_name, 49) || 
                     rpad(to_char(lt_rsc_roles_afr(i).start_date_active), 12) || 
                     rpad(to_char(lt_rsc_roles_afr(i).end_date_active), 12)
                    );
         END LOOP;

         DEBUG_LOG('*************** Resource Group Member Roles (Before Change) ***************');
         DEBUG_LOG('Group Name                         Role Name                             Start Date  End Date    ');

         FOR i in 1..lt_grp_roles_bfr.COUNT loop
           DEBUG_LOG(rpad(lt_grp_roles_bfr(i).group_name, 35) || rpad(lt_grp_roles_bfr(i).role_name, 38) || 
                     rpad(to_char(lt_grp_roles_bfr(i).start_date_active), 12) || 
                     rpad(to_char(lt_grp_roles_bfr(i).end_date_active), 12)
                    );
         END LOOP;

         DEBUG_LOG('*************** Resource Group Member Roles (After Change) ***************');
         FOR i in 1..lt_grp_roles_afr.COUNT loop
           DEBUG_LOG(rpad(lt_grp_roles_afr(i).group_name, 35) || rpad(lt_grp_roles_afr(i).role_name, 38) || 
                     rpad(to_char(lt_grp_roles_afr(i).start_date_active), 12) || 
                     rpad(to_char(lt_grp_roles_afr(i).end_date_active), 12)
                    );
         END LOOP;
         -- Added on 24-DEC-2008
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
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_EXISTING_RESOURCE'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_EXISTING_RESOURCE'
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
      ln_cnt                      NUMBER ;
      lc_return_mesg              VARCHAR2(5000);
      v_data                      VARCHAR2(5000);



      CURSOR  lcu_get_salesrep_det
      IS
      SELECT  JRS.salesrep_id
             ,JRS.sales_credit_type_id
             ,JRS.object_version_number
             ,PAPF.email_address SOURCE_EMAIL
             ,JRS.email_address  CRM_EMAIL
             ,JRS.org_id
      FROM    jtf_rs_resource_extns_vl  JRRE
             ,jtf_rs_salesreps          JRS
             ,per_all_people_f          PAPF
      WHERE   JRRE.source_id   = PAPF.person_id
      AND     JRS.resource_id  = JRRE.resource_id
      AND     JRRE.resource_id = p_resource_id;

   BEGIN

      DEBUG_LOG('Inside Proc: UPDATE_EMAIL');
      -- Initialize fnd message pub
      IF fnd_api.to_boolean(p_init_msg_list) THEN

         fnd_msg_pub.initialize;

      END IF;

      FOR  salesrep_rec IN lcu_get_salesrep_det
      LOOP

         IF  NVL(salesrep_rec.CRM_EMAIL,'A') <> NVL(salesrep_rec.SOURCE_EMAIL,'A') THEN

            -- 18/01/08
            FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                       p_data  => gc_msg_data
                                       );

            IF gn_msg_cnt_get = 0 THEN
               gn_msg_cnt := 1;
            END IF;
            -- 18/01/08

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

               DEBUG_LOG('In Procedure:UPDATE_EMAIL: Proc: Update salesrep Fails. ');

               -- 18/01/08
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

               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code             => x_return_status
                                     ,p_msg_count               => x_msg_count
                                     ,p_application_name        => GC_APPN_NAME
                                     ,p_program_type            => GC_PROGRAM_TYPE
                                     ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.UPDATE_EMAIL'
                                     ,p_program_id              => gc_conc_prg_id
                                     ,p_module_name             => GC_MODULE_NAME
                                     ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.UPDATE_EMAIL'
                                     ,p_error_message_count     => x_msg_count
                                     ,p_error_message_code      => 'XX_TM_0220_STD_API_ERROR'
                                     ,p_error_message           => x_msg_data
                                     ,p_error_status            => GC_ERROR_STATUS
                                     ,p_notify_flag             => GC_NOTIFY_FLAG
                                     ,p_error_message_severity  =>'MAJOR'
                                     );
               -- 18/01/08

            ELSE

              DEBUG_LOG('In Procedure:UPDATE_EMAIL: Proc: Update salesrep Success. ');

            END IF;

         END IF; -- NVL(salesrep_rec.CRM_EMAIL,'A') <> NVL(salesrep_rec.SOURCE_EMAIL,'A')

      END LOOP;

      RETURN;

   EXCEPTION
      WHEN OTHERS THEN

      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.UPDATE_EMAIL'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.UPDATE_EMAIL'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
                     (p_person_id               IN          NUMBER
                     ,p_as_of_date              IN          DATE
                     ,p_write_debug_to_log      IN          VARCHAR2   DEFAULT  FND_API.G_FALSE
                     ,p_init_msg_list           IN          VARCHAR2   DEFAULT  FND_API.G_FALSE
                     ,p_hierarchy_type          IN          VARCHAR2 -- 24/07/08
                     ,x_resource_id             OUT NOCOPY  NUMBER
                     ,x_return_status           OUT NOCOPY  VARCHAR2
                     ,x_msg_count               OUT NOCOPY  NUMBER
                     ,x_msg_data                OUT NOCOPY  VARCHAR2
                     )
   IS

      lc_resource_exists         VARCHAR2(1);
      lc_error_message           VARCHAR2(1000);
      ln_cnt                     PLS_INTEGER;
      lc_mandat_chk_flag         VARCHAR2(1):= 'Y'; -- 21/01/08

      CURSOR  lcu_get_emp_details(p_per_id NUMBER)
      IS
      SELECT  PAPF.employee_number     EMPLOYEE_NUMBER
             ,PAPF.full_name           FULL_NAME
             ,PAPF.email_address       EMAIL_ADDRESS
--            , TRUNC(TO_DATE(PAAF.ass_attribute10,'rrrr/mm/dd hh24:mi:ss')) JOB_ASGN_DATE --04/Dec/07
--            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'rrrr/mm/dd hh24:mi:ss')) MGR_ASGN_DATE --04/Dec/07
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
            , PAAF.job_id -- 23/01/08
      FROM    per_all_people_f      PAPF
             ,per_all_assignments_f PAAF
      WHERE   PAPF.person_id  = p_per_id
      AND     PAAF.person_id  = PAPF.person_id
      AND     gd_as_of_date
              BETWEEN  PAAF.effective_start_date
              AND      PAAF.effective_end_date
      AND     gd_as_of_date
              BETWEEN  PAPF.effective_start_date
              AND      PAPF.effective_end_date;

      CURSOR   lcu_check_resource
      IS
      SELECT  'Y' resource_exists
              ,resource_id
              ,resource_number
              ,object_version_number
              ,start_date_active
              ,end_date_active
      FROM     jtf_rs_resource_extns_vl
      WHERE    source_id  = gn_person_id;

      lr_emp_details           lcu_get_emp_details%ROWTYPE;
      lr_check_resource        lcu_check_resource%ROWTYPE;

      EX_TERMINATE_PRGM          EXCEPTION;


   BEGIN

      gc_write_debug_to_log := p_write_debug_to_log;

      DEBUG_LOG('Inside Proc: PROCESS_RESOURCES');
      
      -- Initialize fnd message pub
      fnd_msg_pub.initialize;

      -- ----------------------------------
      -- Assign 'Y' to the concurrent flag
      -- if profile is set to debug
      -- ----------------------------------

      SAVEPOINT PROCESS_RESOURCE_SP;

      gd_as_of_date     := trunc(p_as_of_date) ;
      gn_person_id      := p_person_id         ;
      gc_hierarchy_type := p_hierarchy_type; -- 24/07/08

      -- -------------------------------------------------------
      -- If global variables are NULL, fetch emp details
      -- Global Variables will be null when the  PROCESS_RESOURCES
      -- is called independently for a single resource as an API
      -- from some other calling application.
      -- When this procedure will be called from procedure MAIN
      -- (i.e. the HR CRM Synch Conc Prog), all these details
      -- will be provided and pre-validated.
      -- -------------------------------------------------------
      IF   gc_employee_number IS NULL AND
           gc_full_name       IS NULL AND
           gc_email_address   IS NULL THEN


         -- -------------------------------------------------------
         -- Call Procedure Validate_Setups
         -- -------------------------------------------------------
         VALIDATE_SETUPS(ln_cnt);

         IF ln_cnt <> 7 THEN
           RAISE EX_TERMINATE_PRGM;
         END IF;

         gn_resource_id      := NULL;
         gc_resource_number  := NULL;
         gc_return_status    := NULL;
         gc_err_msg          := NULL;--18/01/08
         gn_msg_cnt_get      := 0;--18/01/08
         gn_msg_cnt          := 0;--18/01/08
         gc_msg_data         := NULL;--18/01/08
         gc_resource_type    := NULL;-- 02/07/08         

         IF lcu_get_emp_details%ISOPEN THEN
           CLOSE lcu_get_emp_details;
         END IF;

         OPEN  lcu_get_emp_details(gn_person_id);
         FETCH lcu_get_emp_details INTO lr_emp_details;
         CLOSE lcu_get_emp_details;

         gc_employee_number :=  lr_emp_details.employee_number;
         gc_full_name       :=  lr_emp_details.full_name;
         gc_email_address   :=  lr_emp_details.email_address;
         gd_job_asgn_date   :=  lr_emp_details.job_asgn_date;
         gd_mgr_asgn_date   :=  lr_emp_details.mgr_asgn_date;
         gn_job_id          :=  lr_emp_details.job_id;   -- 23/01/08

      END IF; --If global variables are NULL

      -- 21/01/08
      /*IF gc_employee_number IS NULL OR gc_full_name     IS NULL
      OR gd_job_asgn_date   IS NULL OR gd_mgr_asgn_date IS NULL
      THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         FND_MSG_PUB.add;

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         lc_error_message    := FND_MESSAGE.GET;
      */
      -- 21/01/08

      -- 21/01/08
      IF gc_employee_number IS NULL THEN

         lc_mandat_chk_flag := 'N';

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         FND_MESSAGE.SET_TOKEN('DETAILS', 'Employee Number' );
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
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
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      END IF;

      --23/01/08
      IF gn_job_id IS NULL THEN

         lc_mandat_chk_flag := 'N';

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         FND_MESSAGE.SET_TOKEN('DETAILS', 'Job' );
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      END IF;
      --23/01/08

      IF gd_job_asgn_date IS NULL THEN

         lc_mandat_chk_flag := 'N';

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         FND_MESSAGE.SET_TOKEN('DETAILS', 'Job Assignment Date' );
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      END IF;

      IF gd_mgr_asgn_date IS NULL THEN

         lc_mandat_chk_flag := 'N';

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0005_EMPNUM_NAME_NULL');
         FND_MESSAGE.SET_TOKEN('DETAILS', 'Manager Assignment Date' );
         lc_error_message    := FND_MESSAGE.GET;
         FND_MSG_PUB.add;

         WRITE_LOG(lc_error_message);

         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_count     => 1
                            ,p_error_message_code      =>'XX_TM_0005_EMPNUM_NAME_NULL'
                            ,p_error_message           => lc_error_message
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      END IF;

      IF lc_mandat_chk_flag = 'N' THEN
         RAISE EX_TERMINATE_PRGM;
      END IF;
      -- 21/01/08

      gn_job_id := NULL;

      DEBUG_LOG('Processing for the person name: '||gc_full_name);

      IF lcu_check_resource%ISOPEN THEN

         CLOSE lcu_check_resource;

      END IF;

      OPEN  lcu_check_resource;

      FETCH lcu_check_resource INTO lr_check_resource;

      lc_resource_exists      := lr_check_resource.resource_exists;
      gn_resource_id          := lr_check_resource.resource_id;
      gc_resource_number      := lr_check_resource.resource_number;
      gn_res_obj_ver_number   := lr_check_resource.object_version_number;
      gd_resource_start_date  := lr_check_resource.start_date_active;
      gd_resource_end_date    := lr_check_resource.end_date_active;

      CLOSE lcu_check_resource;

      DEBUG_LOG('Is it an existing Resource (Y/N): ' ||NVL(lc_resource_exists,'N'));
      --WRITE_LOG('Is it an existing Resource (Y/N): ' ||NVL(lc_resource_exists,'N'));
      
       gc_resource_exists := NVL(lc_resource_exists,'N');
       
      IF ( NVL(lc_resource_exists,'N') = 'N' ) THEN         

         PROCESS_NEW_RESOURCE
                     (x_resource_id      => x_resource_id
                     ,x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      ELSE   -- lc_resource_exists = 'N'  , WHEN RESOURCE EXISTS

         PROCESS_EXISTING_RESOURCE
                     (x_return_status    => x_return_status
                     ,x_msg_count        => x_msg_count
                     ,x_msg_data         => x_msg_data
                     );

      END IF;  -- ( NVL(lc_resource_exists,'N') = 'N' )

      DEBUG_LOG('gc_return_status = ' || gc_return_status);
      DEBUG_LOG('x_return_status  = ' || x_return_status);

      -- Code Added on 01/14/2008 --> Commit if no error occured else rollback 
      IF NVL(gc_return_status, 'SUCCESS')  <> 'ERROR' THEN
        DEBUG_LOG('Before Commit Changes');
        COMMIT;
        DEBUG_LOG('After Commit Changes');
      ELSE
        DEBUG_LOG('Before Rolling Back');
        ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;
        DEBUG_LOG('After Rolling Back');
      END IF;


      EXCEPTION

      WHEN EX_TERMINATE_PRGM THEN

      gc_return_status       := 'ERROR';
      x_return_status        := FND_API.G_RET_STS_ERROR;

      ROLLBACK TO SAVEPOINT PROCESS_RESOURCE_SP;

      WHEN OTHERS THEN
      gc_return_status     :='ERROR';
      x_return_status      := FND_API.G_RET_STS_ERROR;
      x_msg_data := SQLERRM;
      WRITE_LOG(x_msg_data);

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                            p_return_code             => x_return_status
                           ,p_msg_count               => 1
                           ,p_application_name        => GC_APPN_NAME
                           ,p_program_type            => GC_PROGRAM_TYPE
                           ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCES'
                           ,p_program_id              => gc_conc_prg_id
                           ,p_module_name             => GC_MODULE_NAME
                           ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.PROCESS_RESOURCES'
                           ,p_error_message_count     => 1
                           ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                           ,p_error_message           => x_msg_data
                           ,p_error_status            => GC_ERROR_STATUS
                           ,p_notify_flag             => GC_NOTIFY_FLAG
                           ,p_error_message_severity  =>'MAJOR'
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
                 (x_errbuf            OUT VARCHAR2
                 ,x_retcode           OUT NUMBER
                 ,p_person_id         IN  NUMBER
                 ,p_as_of_date        IN  DATE
                 ,p_hierarchy_type    IN  VARCHAR2 -- 24/07/08
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
      lc_total_warning   VARCHAR2(1000); -- 23/01/08
      lc_total_failed    VARCHAR2(1000);
      ln_cnt             PLS_INTEGER ;
      
      
      -- ----------------------------------------------------------------
      -- Declare cursor to get all the employees reporting to the manager
      -- ----------------------------------------------------------------

      -- -----------------------------------------------
      -- Commented this for duplicate records -07/Dec/07
      -- -----------------------------------------------

      /*CURSOR  lcu_get_employees
      IS
      SELECT  PAAF.person_id           PERSON_ID
            , PAPF.full_name           FULL_NAME
            , PAPF.email_address       EMAIL_ADDRESS
            , PAPF.employee_number     EMPLOYEE_NUMBER
--            , TRUNC(TO_DATE(PAAF.ass_attribute10,'rrrr/mm/dd hh24:mi:ss')) JOB_ASGN_DATE --04/Dec/07
--            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'rrrr/mm/dd hh24:mi:ss')) MGR_ASGN_DATE --04/Dec/07
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
      FROM    per_all_assignments_f    PAAF
            , per_all_people_f         PAPF
            , per_person_types         PPT
            , per_person_type_usages_f PPTU
      WHERE   PAAF.person_id               = PAPF.person_id
      AND     PAPF.person_id               = PPTU.person_id
      AND     PPT. person_type_id          = PPTU.person_type_id
      AND     PPT.system_person_type       = 'EMP'
      AND p_as_of_date BETWEEN
                  PAAF.effective_start_date AND PAAF.effective_end_date
      AND p_as_of_date BETWEEN
                  PAPF.effective_start_date AND PAPF.effective_end_date
      AND p_as_of_date BETWEEN
                  PPTU.effective_start_date AND PPTU.effective_end_date
      AND PAAF.business_group_id = gn_biz_grp_id
      AND PAPF.business_group_id = gn_biz_grp_id
      AND PPT .business_group_id = gn_biz_grp_id
      CONNECT BY PRIOR PAAF.person_id      = PAAF.supervisor_id
        START WITH     PAAF.person_id      = p_person_id
      ORDER SIBLINGS BY last_name;
      */

      -- -------------------------------------------------
      -- Added to eliminate duplicate records -- 07/Dec/07
      -- -------------------------------------------------
      CURSOR lcu_get_employees
      IS
      SELECT  PAAF.person_id           PERSON_ID
            , PAAF.supervisor_id       SUPERVISOR_ID -- 03/07/08
            , PAPF.full_name           FULL_NAME
            , PAPF.email_address       EMAIL_ADDRESS
            , PAPF.employee_number     EMPLOYEE_NUMBER
--            , TRUNC(TO_DATE(PAAF.ass_attribute10,'rrrr/mm/dd hh24:mi:ss')) JOB_ASGN_DATE --04/Dec/07
--            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'rrrr/mm/dd hh24:mi:ss')) MGR_ASGN_DATE --04/Dec/07
            , TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
            , TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
            , PAAF.job_id -- 23/01/08
      FROM    (SELECT *
               FROM per_all_assignments_f p1
              -- WHERE  p_as_of_date BETWEEN p.effective_start_date AND p.effective_end_date) PAAF -- Commented on 24/04/08
               -- Added on 24/04/08
               WHERE  trunc(p_as_of_date) BETWEEN p1.effective_start_date 
                 AND  DECODE((SELECT  system_person_type
	                      FROM    per_person_type_usages_f p
	                            , per_person_types         ppt
	                      WHERE   TRUNC(p_as_of_date) BETWEEN p.effective_start_date AND p.effective_end_date
	      		      AND     PPT. person_type_id   =  p.person_type_id
	      	              AND     p.person_id           =  p1.person_id
			      AND     PPT.business_group_id =  gn_biz_grp_id),
			     'EX_EMP',TRUNC(p_as_of_date),'EMP', p1.effective_end_date)
              ) PAAF-- Added on 24/04/08
            , (SELECT *
               FROM per_all_people_f p
               WHERE  p_as_of_date BETWEEN p.effective_start_date AND p.effective_end_date
               ) PAPF
            ,  per_person_types         PPT
            , (SELECT *
               FROM per_person_type_usages_f p
               WHERE p_as_of_date BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
      WHERE    PAAF.person_id               = PAPF.person_id
      AND      PAPF.person_id               = PPTU.person_id
      AND      PPT. person_type_id          = PPTU.person_type_id
      AND     (PPT.system_person_type       = 'EMP'
      OR       PPT.system_person_type       = 'EX_EMP')-- Added on 24/04/08
      AND      PAAF.business_group_id       = gn_biz_grp_id
      AND      PAPF.business_group_id       = gn_biz_grp_id
      AND      PPT .business_group_id       = gn_biz_grp_id
      CONNECT BY PRIOR PAAF.person_id       = PAAF.supervisor_id
        START WITH     PAAF.person_id       = p_person_id
      ORDER SIBLINGS BY last_name;

      TYPE employee_details_tbl_type IS TABLE OF lcu_get_employees%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_employee_details employee_details_tbl_type;
      
      CURSOR lcu_get_sup_name(p_supervisor_id IN per_all_people_f.person_id%TYPE)
      IS
      SELECT full_name
      FROM   per_all_people_f PAPF
      WHERE  person_id = p_supervisor_id;       

   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN
       --DEBUG_LOG('Inside Proc: MAIN');
       --DEBUG_LOG('gd_golive_date:'||gd_golive_date);

       fnd_msg_pub.initialize;

       ln_total_count  := 0   ;
       ln_success      := 0   ;
       ln_errored      := 0   ;
       ln_warning      := 0   ;

       gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;

       -- --------------------------------------
       -- DISPLAY PROJECT NAME AND PROGRAM NAME
       -- --------------------------------------

        WRITE_LOG(RPAD('Office Depot',50)||'Date: '||trunc(SYSDATE));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_LOG(LPAD('Oracle HRMS - CRM Synchronization',52));
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_LOG('');
        WRITE_LOG('Input Parameters ');
        WRITE_LOG('Person Id : '||p_person_id);
        WRITE_LOG('As-Of-Date: '||p_as_of_date);

        /* 27/06/08
        WRITE_OUT(RPAD(' Office Depot',163)||LPAD(' Date: '||trunc(SYSDATE),16));
        WRITE_OUT(RPAD(' ',180,'-'));
        WRITE_OUT(LPAD('Oracle HRMS - CRM Synchronization',107));
        WRITE_OUT(RPAD(' ',180,'-'));
        WRITE_OUT('');
        */

        WRITE_OUT(RPAD('EMPLOYEE NUMBER',35)||CHR(9)
                ||RPAD('EMPLOYEE NAME',55)||CHR(9)
                ||RPAD('MANAGER NAME',55)||CHR(9)
                ||RPAD('RESOURCE EXISTS(Y/N)',26)||CHR(9)
                ||RPAD('RESOURCE TYPE',20)||CHR(9)
                ||RPAD('STATUS',20)||CHR(9)
                ||'ERROR DESCRIPTION');
        /* 27/06/08
        WRITE_LOG(RPAD(' ',76,'-'));
        WRITE_OUT(' ');
        */


       -- -------------------------------------------------------
       -- Store the records fetched from cursor to the table type
       -- -------------------------------------------------------
       gd_as_of_date     := p_as_of_date;
       gc_hierarchy_type := p_hierarchy_type; -- 24/07/08


       -- -------------------------------------------------------
       -- Call Procedure Validate_Setups
       -- -------------------------------------------------------
       VALIDATE_SETUPS(ln_cnt);

       IF ln_cnt <> 7 THEN
          RAISE EX_TERMIN_PRGM;
       END IF;

       IF lcu_get_employees%ISOPEN THEN

          CLOSE lcu_get_employees;

       END IF;

       OPEN  lcu_get_employees;
       LOOP

          FETCH lcu_get_employees BULK COLLECT INTO lt_employee_details LIMIT 10000;

          IF lt_employee_details.count > 0 THEN

              -- -----------------------------------------------------------
              -- Call the procedure for all directs reporting to the manager
              -- -----------------------------------------------------------

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
                    gd_job_asgn_date    := NULL;
                    gd_mgr_asgn_date    := NULL;
                    gc_err_msg          := NULL;--18/01/08
                    gn_msg_cnt_get      := 0;--18/01/08
                    gn_msg_cnt          := 0;--18/01/08
                    gc_msg_data         := NULL;--18/01/08
                    gc_resource_type    := NULL;-- 02/07/08 
                    gn_supervisor_id    := NULL;-- 03/07/08

                    gn_person_id        := lt_employee_details(i).person_id;
                    gc_employee_number  := lt_employee_details(i).employee_number;
                    gc_full_name        := lt_employee_details(i).full_name;
                    gc_email_address    := lt_employee_details(i).email_address;
                    gd_job_asgn_date    := lt_employee_details(i).job_asgn_date;
                    gd_mgr_asgn_date    := lt_employee_details(i).mgr_asgn_date;
                    gn_job_id           := lt_employee_details(i).job_id; -- 23/01/08
                    gn_supervisor_id    := lt_employee_details(i).supervisor_id; -- 03/07/08
                    
                    -- Added on 03/07/08
                    OPEN    lcu_get_sup_name(gn_supervisor_id);
                    FETCH   lcu_get_sup_name INTO gc_supervisor_name;
                    CLOSE   lcu_get_sup_name;
                    
                    -- Added on 03/07/08

                    WRITE_LOG(' ');
                    WRITE_LOG(RPAD(' ',76,'-'));
                    WRITE_LOG('Processing for the person name: '||gc_full_name);

                    PROCESS_RESOURCES
                            (p_person_id           => gn_person_id
                            ,p_as_of_date          => p_as_of_date
                            ,p_write_debug_to_log  => FND_API.G_TRUE
                            ,p_init_msg_list       => FND_API.G_TRUE
                            ,p_hierarchy_type      => p_hierarchy_type
                            ,x_resource_id         => ln_resource_id
                            ,x_return_status       => lc_return_status
                            ,x_msg_count           => ln_msg_count
                            ,x_msg_data            => lc_msg_data
                            );

                    WRITE_OUT(RPAD(NVL(gc_employee_number,'--'),34)||CHR(9)
                             ||RPAD(NVL(gc_full_name,'--'),55)||CHR(9)
                             ||RPAD(NVL(gc_supervisor_name,'--'),55)||CHR(9)
                             ||RPAD(NVL(gc_resource_exists,'--'),26)||CHR(9)
                             ||RPAD(NVL(gc_resource_type,'--'),20)||CHR(9)
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

                    /*--Write all the error logged in error message stack to conc prog log file.
                    FOR  i IN 1..NVL(ln_msg_count,0)
                    LOOP

                       lc_error_message := NULL;
                       lc_error_message := FND_MSG_PUB.GET(i,FND_API.G_FALSE);

                       IF lc_error_message IS NOT NULL THEN
                          WRITE_LOG(lc_error_message);
                       END IF;

                    END LOOP;
                    */

                END LOOP; -- lt_employee_details.first..lt_employee_details.last

            END IF;--lt_employee_details.count > 0

          EXIT WHEN lcu_get_employees%NOTFOUND;

       END LOOP;

       CLOSE lcu_get_employees;


       IF ln_total_count < 1 THEN

         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0001_EMPLOYEE_NOT_FOUND');
         FND_MESSAGE.SET_TOKEN('P_EMPLOYEE_ID', p_person_id );
         FND_MESSAGE.SET_TOKEN('P_AS_OF_DATE',  p_as_of_date );

         lc_error_message := FND_MESSAGE.GET;
         IF gc_err_msg IS NOT NULL THEN
            gc_err_msg := gc_err_msg|| ' * ' ||lc_error_message; -- 08/07/08
         ELSE
            gc_err_msg := lc_error_message;
         END IF;
         WRITE_LOG(lc_error_message);

         XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_return_code             => FND_API.G_RET_STS_ERROR
                            ,p_msg_count               => 1
                            ,p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
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
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

   WHEN OTHERS THEN
      x_errbuf  := 'Completed with errors,  '||SQLERRM ;
      x_retcode := 2 ;

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0221_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; -- 08/07/08
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CRM_HRCRM_SYNC_PKG.MAIN'
                            ,p_error_message_code      => 'XX_TM_0221_UNEXPECTED_ERR'
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      ROLLBACK;
      RETURN;

   END MAIN;

END XX_CRM_HRCRM_SYNC_PKG;
/