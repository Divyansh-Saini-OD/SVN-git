CREATE OR REPLACE
PACKAGE BODY XX_CS_RES_SYNC_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_RES_SYNC_PKG                                       |
-- |                                                                   |
-- | Description: Wrapper package for create/update Support Resource.  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-July-08   Raj Jagarlamudi  Initial draft version      |
-- +===================================================================+
--Global Variables
GC_APPN_NAME          CONSTANT VARCHAR2(30):= 'XXCRM';
GC_PROGRAM_TYPE       CONSTANT VARCHAR2(40):= 'Resource_Sychronize';
GC_MODULE_NAME        CONSTANT VARCHAR2(30):= 'CS';
GC_ERROR_STATUS       CONSTANT VARCHAR2(30):= 'ACTIVE';
GC_NOTIFY_FLAG        CONSTANT VARCHAR2(1) :=  'Y';
gc_debug_flag         VARCHAR2(1) := FND_PROFILE.VALUE('XX_HRCRM_SYNC_DEBUG');
gc_write_debug_to_log CHAR(1);
gn_person_id          NUMBER ;
gc_conc_prg_id        NUMBER  DEFAULT   -1;
gc_employee_number    per_all_people_f.employee_number%TYPE := NULL;
gc_full_name          per_all_people_f.full_name%TYPE       := NULL;
gn_resource_id        jtf_rs_resource_extns_vl.resource_id%TYPE;
gc_resource_number    jtf_rs_resource_extns_vl.resource_number%TYPE;
gn_job_id             per_all_assignments_f.job_id%TYPE;
gd_job_asgn_date      DATE;
gc_errbuf             VARCHAR2(2000); 
gc_err_msg            CLOB;
gn_msg_cnt            NUMBER;  
gn_msg_cnt_get        NUMBER;
gc_msg_data           CLOB;
gc_return_status      VARCHAR2(10) ;
/********************************************************************************
  -- Write Log file
********************************************************************************/
PROCEDURE WRITE_LOG (p_message IN VARCHAR2)
IS
      lc_error_message VARCHAR2(2000);
   BEGIN
      fnd_file.put_line(fnd_file.log,p_message);
   EXCEPTION
      WHEN OTHERS THEN
      lc_error_message := 'Unexpected error during log ' || SQLERRM;
      fnd_file.put_line(fnd_file.log,lc_error_message);

      FND_MESSAGE.SET_NAME('XXCRM','XX_CS_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CS_RES_SYNC_PKG.WRITE_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CS_RES_SYNC_PKG.WRITE_LOG'
                                  ,p_error_message_code      => 'XX_CS_UNEXPECTED_ERR'
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

      FND_MESSAGE.SET_NAME('XXCRM','XX_CS_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CS_RES_SYNC_PKG.WRITE_OUT'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CS_RES_SYNC_PKG.WRITE_OUT'
                                  ,p_error_message_code      => 'XX_CS_UNEXPECTED_ERR'
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

      FND_MESSAGE.SET_NAME('XXCRM','XX_CS_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;

      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf; 
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                   p_application_name        => GC_APPN_NAME
                                  ,p_program_type            => GC_PROGRAM_TYPE
                                  ,p_program_name            =>'XX_CS_RES_SYNC_PKG.DEBUG_LOG'
                                  ,p_program_id              => gc_conc_prg_id
                                  ,p_module_name             => GC_MODULE_NAME
                                  ,p_error_location          =>'XX_CS_RES_SYNC_PKG.DEBUG_LOG'
                                  ,p_error_message_code      => 'XX_CS_UNEXPECTED_ERR'
                                  ,p_error_message           => lc_error_message
                                  ,p_error_status            => GC_ERROR_STATUS
                                  ,p_notify_flag             => GC_NOTIFY_FLAG
                                  ,p_error_message_severity  =>'MAJOR'
                                  );
   END;
   
/*************************************************************************************************
**************************************************************************************************/
  PROCEDURE MAIN_PROC ( X_ERRBUF      OUT VARCHAR2,
                        X_RETCODE     OUT NUMBER,
                        P_GET_NEW_EMP IN  VARCHAR2) AS
 
     
      lc_return_status      VARCHAR2(5);
      ln_msg_count          PLS_INTEGER;
      lc_msg_data           VARCHAR2(1000);
      lc_user_name          VARCHAR2(100);
      l_api_version         number := 1.0;
      lc_category           jtf_rs_resource_extns.category%type := 'EMPLOYEE';
      x_resource_id         jtf_rs_resource_extns.resource_id%type; 
      x_resource_number     jtf_rs_resource_extns.resource_number%type;
      x_role_relate_id	    JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE;
      x_group_relate_id	    JTF_RS_GRP_RELATIONS.GROUP_RELATE_ID%TYPE; 
      X_group_member_id     JTF_RS_GROUP_MEMBERS.GROUP_MEMBER_ID%TYPE; 
      l_start_date_active   jtf_rs_resource_extns.start_date_active%type; 
      l_end_date_active     jtf_rs_resource_extns.end_date_active%type;
      x_return_status       varchar2(1); 
      x_msg_count           number; 
      x_msg_data            varchar2(2000); 
      ln_object_version_num  NUMBER ;
      ln_total_records       NUMBER := 0;
      ln_success_records     NUMBER := 0;

      CURSOR get_term_employees
      IS 
       select v2.role_relate_id,
              v1.resource_id, 
              v1.object_version_number,
              ja.ass_attribute9 end_date 
        from jtf_rs_resource_extns v1,
             jtf_rs_defresroles_vl v2,
              per_all_assignments_f ja
        where ja.person_id = v1.source_id
        and   v2.role_resource_id = v1.resource_id
        and   v1.category = 'EMPLOYEE'
        and   v2.role_type_code = 'CALLCENTER' 
        and   ja.ass_attribute2 = 'CSD' 
        and   v2.res_rl_end_date is null
        and   not exists (select 'x'
                          from  per_jobs jp,
                                jtf_rs_job_roles jb,
                                jtf_rs_roles_b jr,
                                per_all_assignments_f ja,
                                per_all_people_f jf
                        where jf.person_id = ja.person_id
                        and   ja.job_id = jp.job_id
                        and   jp.job_id = jb.job_id
                        and   jb.role_id = jr.role_id
                        and   jr.role_type_code = 'CALLCENTER'
                        and   nvl(jr.active_flag,'N') = 'Y'
                        and   jf.person_id = v1.source_id );
                        
     CURSOR get_employees
      IS
      select emp.employee_number,
             emp.full_name, 
             asg.person_id, 
             job.job_id,
             trunc(to_date(asg.ass_attribute10,'DD-MON-RR')) job_assign_date   
      FROM   hr_all_organization_units org
            , per_all_assignments_f    asg
            , per_jobs                 job
           , hr_locations              loc
           , per_all_people_f          emp
           , per_person_types          ppt
    WHERE    ppt.person_type_id = emp.person_type_id
    and    emp.business_group_id = org.organization_id
    and    emp.person_id   = asg.person_id
    and    trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
    and    asg.primary_flag = 'Y'
    and    ppt.system_person_type       = 'EMP'
    and    (asg.assignment_type = 'E' OR asg.assignment_type = 'C')
    and    trunc(sysdate) between asg.effective_start_date and asg.effective_end_date
    and    asg.job_id   = job.job_id
    and    asg.location_id  = loc.location_id
    and    not exists (select 'x'
                      from jtf_rs_resource_extns rsc
                       where category = 'EMPLOYEE'
                       and  emp.person_id = rsc.source_id)
    and   exists (select 'x'
                    from  jtf_rs_job_roles jb,
                          jtf_rs_roles_b jr
                    where jr.role_id = jb.role_id
                    and   nvl(jr.active_flag,'N') = 'Y'
                    and   jr.role_type_code = 'CALLCENTER'
                    and   jb.job_id = job.job_id);

      TYPE employee_details_tbl_type IS TABLE OF get_employees%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_employee_details employee_details_tbl_type;

      TYPE ter_emp_det_tbl_type IS TABLE OF get_term_employees%ROWTYPE
      INDEX BY BINARY_INTEGER;
      lt_ter_emp_details ter_emp_det_tbl_type;
   -- ---------------------------
   -- Begin of the MAIN procedure
   -- ---------------------------

   BEGIN
      
       fnd_msg_pub.initialize;
       gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;
        
         WRITE_OUT(RPAD('Resource/Employee Number',25)||CHR(9)
                ||RPAD('Resource/Source Id',25)||CHR(9)
                ||RPAD('Employee Name',55)||CHR(9)
                ||RPAD('STATUS',20)||CHR(9)
                ||'ERROR DESCRIPTION');
       -- -------------------------------------------------------
       -- Update end_date if resource job change or terminate
       -- -------------------------------------------------------
      -- l_end_date_active := sysdate;
       
      IF get_term_employees%ISOPEN THEN
          CLOSE get_term_employees;
       END IF;
      BEGIN  
       OPEN  get_term_employees;
       LOOP
          FETCH get_term_employees BULK COLLECT INTO lt_ter_emp_details LIMIT 10000;

          IF lt_ter_emp_details.count > 0 THEN

              -- -----------------------------------------------------------
              -- Call the procedure to create new resources
              -- -----------------------------------------------------------
                FOR i IN lt_ter_emp_details.first..lt_ter_emp_details.last
                LOOP
                   ln_total_records  := ln_total_records + 1;
      
                    x_retcode := NULL;
                    x_resource_id         := lt_ter_emp_details(i).resource_id;
                    x_role_relate_id      := lt_ter_emp_details(i).role_relate_id;
                    ln_object_version_num := lt_ter_emp_details(i).object_version_number;
                    l_end_date_active     := lt_ter_emp_details(i).end_date;
                    
                    DEBUG_LOG('Update Resource Id:'||x_resource_id);
                    
                       UPDATE_RESOURCE
                          ( p_resource_id          => x_resource_id 
                            , p_role_relate_id     => x_role_relate_id
                            , p_end_date_active    => l_end_date_active
                            , p_object_version_num => ln_object_version_num
                            , x_return_status      => x_return_status
                            , x_msg_count          => x_msg_count
                            , x_msg_data           => x_msg_data);
                            
                    IF nvl(x_return_status,'S') = 'E' then
                          gc_return_status := 'ERROR';
                          --dbms_output.put_line('Resource '||x_resource_id||' '||x_msg_data);
                    ELSE
                          gc_return_status   := 'SUCCESS';
                          ln_success_records := ln_success_records + 1;
                    END IF;
                    WRITE_OUT(RPAD(NVL(x_resource_number,0),25)||CHR(9)
                             ||RPAD(NVL(x_resource_id,0),25)||CHR(9)
                             ||RPAD(NVL(gc_full_name,'--'),55)||CHR(9)
                             ||RPAD(NVL(gc_return_status,'SUCCESS'),20)||CHR(9)
                             ||NVL(x_msg_data,'')); 
                    
             END LOOP; 
            END IF;
          EXIT WHEN get_term_employees%NOTFOUND;
       END LOOP;
       CLOSE get_term_employees;
       
       WRITE_OUT(' ');
       WRITE_OUT('Total Records passed to Update :'||ln_total_records);
       
       WRITE_OUT(' ');
       WRITE_OUT('Update Completed Records :'||ln_success_records);
       
     END; -- END OF UPDATE
     
     IF (P_GET_NEW_EMP = 'Y') THEN
       IF get_employees%ISOPEN THEN
          CLOSE get_employees;
       END IF;

      BEGIN
        ln_total_records    := 0;
        ln_success_records  := 0;
        
       OPEN  get_employees;
       LOOP
          FETCH get_employees BULK COLLECT INTO lt_employee_details LIMIT 10000;

          IF lt_employee_details.count > 0 THEN

              -- -----------------------------------------------------------
              -- Call the procedure to create new resources
              -- -----------------------------------------------------------
                FOR i IN lt_employee_details.first..lt_employee_details.last
                LOOP
                    x_retcode := NULL;
                    ln_total_records    := ln_total_records + 1;
                    gn_person_id        := lt_employee_details(i).person_id;
                    gc_employee_number  := lt_employee_details(i).employee_number;
                    gd_job_asgn_date    := lt_employee_details(i).job_assign_date;
                    gc_full_name        := lt_employee_details(i).full_name;
                    gn_job_id           := lt_employee_details(i).job_id;
                    
                    BEGIN
                      SELECT   user_name
                      INTO     lc_user_name
                      FROM     fnd_user
                      WHERE    employee_id  =  gn_person_id;
                   EXCEPTION 
                      WHEN OTHERS THEN
                          x_errbuf  := 'Error while getting FND user, '||SQLERRM ;
                          x_retcode := 2 ;
                  END;
                                     
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
                        ,x_return_status       => x_return_status
                        ,x_msg_count           => x_msg_count
                        ,x_msg_data            => x_msg_data
                        ,x_resource_id         => gn_resource_id
                        ,x_resource_number     => gc_resource_number);
                    
                   --  dbms_output.put_line('Status '||gc_employee_number||' '||x_return_status||' '||x_msg_data);         
                    IF nvl(x_return_status,'S') = 'E' then
                          gc_return_status := 'ERROR';
                          gc_err_msg := x_msg_data;
                    ELSE
                          gc_return_status   := 'SUCCESS';
                          gc_err_msg         := x_msg_data;
                          ln_success_records := ln_success_records + 1;
                    END IF;
                      
                     WRITE_OUT(RPAD(NVL(gc_employee_number,0),25)||CHR(9)
                             ||RPAD(NVL(gn_person_id,0),25)||CHR(9)
                             ||RPAD(NVL(gc_full_name,'--'),55)||CHR(9)
                             ||RPAD(NVL(gc_return_status,'SUCCESS'),20)||CHR(9)
                             ||NVL(gc_err_msg,'--')); 

                END LOOP; 
            END IF;
          EXIT WHEN get_employees%NOTFOUND;
       END LOOP;
       CLOSE get_employees;
      END;
       WRITE_OUT(' ');
       WRITE_OUT('Total Records passed to Create :'||ln_total_records);
       
       WRITE_OUT(' ');
       WRITE_OUT('Imported Records :'||ln_success_records);
       
      END IF;
      
   EXCEPTION
    WHEN OTHERS THEN
      x_errbuf  := 'Completed with errors,  '||SQLERRM ;
      x_retcode := 2 ;

      FND_MESSAGE.SET_NAME('XXCRM','XX_CS_RES_UNEXPECTED_ERR');
      gc_errbuf := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      
      IF gc_err_msg IS NOT NULL THEN
         gc_err_msg := gc_err_msg|| ' * ' ||gc_errbuf;
      ELSE
         gc_err_msg := gc_errbuf;
      END IF;
      
      WRITE_LOG(gc_err_msg);

      XX_COM_ERROR_LOG_PUB.log_error_crm(
                             p_application_name        => GC_APPN_NAME
                            ,p_program_type            => GC_PROGRAM_TYPE
                            ,p_program_name            =>'XX_CS_RES_SYNC_PKG.MAIN'
                            ,p_program_id              => gc_conc_prg_id
                            ,p_module_name             => GC_MODULE_NAME
                            ,p_error_location          =>'XX_CS_RES_SYNC_PKG.MAIN'
                            ,p_error_message_code      => 'XX_CS_RES_UNEXPECTED_ERR'
                            ,p_error_message           => x_errbuf
                            ,p_error_status            => GC_ERROR_STATUS
                            ,p_notify_flag             => GC_NOTIFY_FLAG
                            ,p_error_message_severity  =>'MAJOR'
                            );

      ROLLBACK;
      RETURN;

   END MAIN_PROC;

/*******************************************************************************
-- Import Callcenter Employee and assign Call Center Roles
*******************************************************************************/

  PROCEDURE CREATE_RESOURCE
                  (
                    p_api_version        IN  NUMBER
                  , p_commit             IN  VARCHAR2
                  , p_category           IN  jtf_rs_resource_extns.category%TYPE
                  , p_source_id          IN  jtf_rs_resource_extns.source_id%TYPE  DEFAULT  NULL
                  , p_start_date_active  IN  jtf_rs_resource_extns.start_date_active%TYPE
                  , p_resource_name      IN  jtf_rs_resource_extns_tl.resource_name%TYPE DEFAULT NULL
                  , p_source_number      IN  jtf_rs_resource_extns.source_number%TYPE DEFAULT NULL
                  , p_source_name        IN  jtf_rs_resource_extns.source_name%TYPE
                  , p_user_name          IN  VARCHAR2
                  , x_return_status      OUT NOCOPY  VARCHAR2
                  , x_msg_count          OUT NOCOPY  NUMBER
                  , x_msg_data           OUT NOCOPY  VARCHAR2
                  , x_resource_id        OUT NOCOPY  jtf_rs_resource_extns.resource_id%TYPE
                  , x_resource_number    OUT NOCOPY  jtf_rs_resource_extns.resource_number%TYPE
                  ) AS
 
      -- --------------------------
      -- Local Variable Declaration
      -- --------------------------
      ln_cnt                NUMBER ;
      lc_return_mesg        VARCHAR2(5000);
      v_data                VARCHAR2(5000);
      l_role_relate_id	    JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE;
      l_role_id             jtf_rs_roles_vl.role_id%TYPE;
      l_role_name           jtf_rs_roles_vl.role_name%TYPE;
      l_role_type_code      jtf_rs_roles_b.role_type_code%TYPE;
      l_role_code           jtf_rs_roles_b.role_code%TYPE;
      l_asg_start_date      date;
      
   CURSOR c_job_roles (l_job_id jtf_rs_job_roles.job_id%TYPE) IS
     SELECT jb.role_id, 
            jr.role_type_code,
            jr.role_code
      FROM  jtf_rs_job_roles jb,
            jtf_rs_roles_b jr
      WHERE jr.role_id = jb.role_id
      AND   jr.active_flag = 'Y'
      AND   jb.job_id = l_job_id;

   CURSOR c_role_name (l_role_id jtf_rs_roles_vl.role_id%TYPE) IS
     SELECT role_name
     FROM jtf_rs_roles_vl
     WHERE role_id = l_role_id;
  
   BEGIN
   
      DEBUG_LOG('Inside Proc: CREATE_RESOURCE - '||p_resource_name);

      FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                 p_data  => gc_msg_data
                                 );

      IF gn_msg_cnt_get = 0 THEN
         gn_msg_cnt := 1;
      END IF;
      ------------
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
                    , p_source_name         => p_user_name
                    , p_user_name           => p_user_name
                    , p_attribute14         => null
                    , p_attribute15         => null
                    , x_return_status       => x_return_status
                    , x_msg_count           => x_msg_count
                    , x_msg_data            => x_msg_data
                    , x_resource_id         => x_resource_id
                    , x_resource_number     => x_resource_number
                    );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        DEBUG_LOG('In Procedure:Create Resource: Proc: JTF_RS_RESOURCE_PUB.create_resource Fails for Employee Number: '||p_source_number);
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
         WRITE_LOG(gc_err_msg);
      ELSE
          l_role_id := NULL;
          l_role_type_code := NULL;
          l_asg_start_date  := p_start_date_active;
       IF (gn_job_id IS NOT NULL) THEN
          OPEN c_job_roles (gn_job_id);
          LOOP
          FETCH c_job_roles into l_role_id,l_role_type_code ,l_role_code;
          EXIT WHEN c_job_roles%notfound;
            
          -- Check for CallCenter Roles
          -- Will create the SALES_COMP roles only if the resource is a salesperson.
          if (l_role_type_code = 'CALLCENTER') then

             JTF_RS_ROLE_RELATE_PUB.CREATE_RESOURCE_ROLE_RELATE(
                    p_api_version         => 1.0,
                    p_init_msg_list       =>  FND_API.G_FALSE,
                    p_commit              =>  FND_API.G_FALSE,
                    p_role_resource_type  => 'RS_INDIVIDUAL',
                    p_role_resource_id    => x_resource_id,
                    p_role_id             => l_role_id,
                    p_role_code           => l_role_code,
                    p_start_date_active   => l_asg_start_date,
                    p_end_date_active     => null,
                    x_return_status       => x_return_status,
                    x_msg_count           => x_msg_count,
                    x_msg_data            => x_msg_data,
                    x_role_relate_id      => l_role_relate_id);

             IF ( x_return_status <> fnd_api.g_ret_sts_success) THEN
               l_role_name := NULL;
               OPEN c_role_name (l_role_id);
               FETCH c_role_name INTO l_role_name;
               CLOSE c_role_name;
               fnd_message.set_name('CS', 'XX_CS_RES_SYNC_PKG');
               fnd_message.set_token('P_EMPLOYEE_NAME', p_source_number);
               fnd_message.set_token('P_ROLE_NAME',l_role_name);
               fnd_file.put_line(fnd_file.log, fnd_message.get);
               debug_log('Error while creating role relate resource: '||fnd_message.get||' for '||p_source_number);
             END IF;
          end if; -- End of Check for Callcenter Roles
         END LOOP;
         CLOSE c_job_roles;
         END IF; --End of gn_job_id

      END IF;

   END CREATE_RESOURCE;
   
/************************************************************************************
***********************************************************************************/

PROCEDURE UPDATE_RESOURCE
                 ( p_resource_id        IN  jtf_rs_resource_extns_vl.resource_id%TYPE
                 , p_role_relate_id     IN  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
                 , p_end_date_active    IN  jtf_rs_resource_extns.end_date_active%type
                 , p_object_version_num IN  jtf_rs_resource_extns_vl.object_version_number%TYPE
                 , x_return_status      OUT NOCOPY  VARCHAR2
                 , x_msg_count          OUT NOCOPY  NUMBER
                 , x_msg_data           OUT NOCOPY  VARCHAR2
                 )
   IS
       -- --------------------------
       -- Local Variable Declaration
       -- --------------------------
       ln_cnt                        NUMBER ;
       lc_return_mesg                VARCHAR2(5000);
       v_data                        VARCHAR2(5000);
       ln_obj_version_num            NUMBER := p_object_version_num ;
       l_asg_end_date                date;

   BEGIN

       DEBUG_LOG('Inside Proc: UPDATE_RESOURCE');

       FND_MSG_PUB.count_and_get (p_count => gn_msg_cnt_get,
                                  p_data  => gc_msg_data
                                  );

       IF gn_msg_cnt_get = 0 THEN
          gn_msg_cnt := 1;
       END IF;
       
       l_asg_end_date := p_end_date_active;
       -- ----------------------------------------------------
       -- CRM Standard API call for end date the resource role
       -- -----------------------------------------------------
        JTF_RS_ROLE_RELATE_PUB.update_resource_role_relate
                     (P_API_VERSION         => 1.0,
                      P_ROLE_RELATE_ID      => p_role_relate_id,
                      P_END_DATE_ACTIVE     => l_asg_end_date,
                      P_OBJECT_VERSION_NUM  => ln_obj_version_num,
                      X_RETURN_STATUS       => x_return_status,
                      X_MSG_COUNT           => x_msg_count,
                      X_MSG_DATA            => x_msg_data);

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       
          DEBUG_LOG('In Procedure:Update Resource: Proc: JTF_RS_ROLE_RELATE_PUB.update_resource Fails for Resource id: '||p_resource_id);

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
          
          WRITE_LOG(gc_err_msg);
       END IF;

END UPDATE_RESOURCE;
/*********************************************************************************
**********************************************************************************/
  
END XX_CS_RES_SYNC_PKG;

/
show errors;
exit;