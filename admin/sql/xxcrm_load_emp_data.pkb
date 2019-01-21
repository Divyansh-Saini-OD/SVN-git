/******************************************************************************
*
* File Name   : xxcrm_load_emp_data.pkb
* Created By  : Phil Price
* Created Date: 08-SEP-2007
* Description : This file contains the procedures to synchronize Oracle HR data
*               using employee data supplied from an external system.
*
* Comments    :  
*
* Modification History
*
* 08-Sep-2007   Phil Price   Initial version.
* 10-Oct-2007   Phil Price   Ability to create emps without fnd_user record.
*
******************************************************************************/

create or replace package body xxcrm_load_emp_data as

--
-- Debug levels
--
DBG_OFF   constant number := 0;
DBG_LOW   constant number := 1;
DBG_MED   constant number := 2;
DBG_HI    constant number := 3;

--
-- Concurrent Manager completion statuses
--
CONC_STATUS_OK      constant number := '0';
CONC_STATUS_WARNING constant number := '1';
CONC_STATUS_ERROR   constant number := '2';

ANONYMOUS_APPS_USER    constant number := -1; 

WHO_CONC_REQUEST_ID    constant number := 1; 
WHO_PROG_APPL_ID       constant number := 2; 
WHO_CONC_PROGRAM_ID    constant number := 3; 
WHO_USER_ID            constant number := 4; 
WHO_CONC_LOGIN_ID      constant number := 5; 

ORA_EMP_FOUND          constant varchar2(10) := 'FOUND';
ORA_EMP_NOT_FOUND      constant varchar2(10) := 'NOT_FOUND';
ORA_EMP_DUP            constant varchar2(10) := 'DUPLICATE';


--
-- Many HR update API's include the parameter p_datetrack_update_mode.
-- We set it here globally so it is used consistently.
--
-- The possible values are (some values not available in some cases):
--
--   UPDATE               = Keep history of existing information
--   CORRECTION           = Correct existing information
--   UPDATE_OVERRIDE      = Replace all scheduled changes
--   UPDATE_CHANGE_INSERT = Insert this change before next scheduled change
--
DATETRACK_MODE_CORRECTION constant varchar2(50) := 'CORRECTION';
DATETRACK_MODE_UPDATE     constant varchar2(50) := 'UPDATE';


--
-- Many HR API's include the parameter p_validate.
-- When set to TRUE the API only validate the parameterrs.  No changes are made.
-- When set to FALSE the API validates tha parameters and then executes the API.
--
g_hr_api_validate  constant boolean := FALSE;


TYPE WhoArray   IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;   
g_who_values    WhoArray;

SQ                     constant varchar2(1) := chr(39); -- single quote

g_conc_mgr_env     boolean;
g_commit           boolean;
g_warning_ct       number := 0;
g_warning_flag     boolean := FALSE;
g_debug_level      number := DBG_OFF;

  cursor c_ext_hr_info (c_employee_number varchar2 default null) is
    select emp.emp_id,
           emp.first_name,
           emp.last_name,
           emp.middle_initial,
           emp.position_cd,    -- 6 digit value, varchar2
           emp.loc_id,         -- numeric value
           emp.termination_dt,
           emp.job_title,
           emp.phone_nbr, 
           emp.division_name,  -- values like Professional/Contract Sales, Stores, Warehouse, 
           emp.dept_name,
           emp.reports_to_id,
           jr.hr_title      oracle_job_title,
           jr.job_code,                         -- values like AE, AM1, BDM1, DSM, RSD, RVP
           jr.sfa_role      job_code_sfa_role,  -- roles defined in Oracle such as OD_US_SA_AM1_ROL, OD_US_SA_BDM1_ROL
           jr.division      job_code_division,  -- values like BSD, DPS, FURNITURE
           jr.manager_flag  job_code_manager_flag
      from xxtps_cms_employees  emp,
           xxtps_jobs_and_roles jr
     where emp.job_title = jr.hr_title_cms (+)
       and emp.emp_id like nvl(c_employee_number,'%')
--     start with emp_id = '517867' -- Steve Schmidt - Cindy Cambell's replacement '443691';   080985 = Cindy Campbell
--   connect by prior emp_id = reports_to_id
     order by emp_id;


  cursor c_ora_hr_info (c_employee_number       varchar2 default null,
                        c_auto_update_when_null varchar2 default 'N') is
    select ppf.person_id,
           ppf.effective_start_date    ppf_effective_start_dt,
           ppf.employee_number,
           ppf.first_name,
           ppf.middle_names,
           ppf.last_name,
           ppf.full_name,
           ppf.email_address           ppf_email_address,
           ppf.party_id,
           nvl(ppf.attribute1,c_auto_update_when_null) auto_update_flag,
           ppf.attribute2              mgr_emp_num,
           ppf.object_version_number   ppf_obj_ver_num,
           ppf.person_type_id,
           ppt.system_person_type,  -- EMP = currently employeed,  EX_EMP = terminated
           pas.assignment_id,
           pas.effective_start_date    pas_effective_start_dt,
           pas.object_version_number   pas_obj_ver_num,
           pas.job_id,
           job.name                    job_name,
           pps.period_of_service_id,
           pps.object_version_number   pps_obj_ver_num,
           fu.user_id                  fnd_user_id,
           fu.employee_id              fnd_employee_id,
           fu.person_party_id          fnd_person_party_id,
           fu.email_address            fnd_email_address
      from per_all_people_f       ppf,
           per_all_assignments_f  pas,
           per_periods_of_service pps,
           per_jobs               job,
           per_person_types       ppt,
           fnd_user               fu
     where ppf.person_type_id  = ppt.person_type_id 
       and ppf.person_id       = pas.person_id
       and ppf.person_id       = pps.person_id
       and pas.job_id          = job.job_id    (+)
       and ppf.employee_number = fu.user_name  (+)
       and 'Y'                 = pas.primary_flag
       and trunc(sysdate)      between ppf.effective_start_date
                                   and ppf.effective_end_date

       and pas.object_version_number  = (select max(pas2.object_version_number)
                                           from per_all_assignments_f pas2
                                          where ppf.person_id = pas2.person_id
                                            and pas2.primary_flag = 'Y')

       and pps.object_version_number = (select max(pps2.object_version_Number)
                                          from per_periods_of_service pps2
                                         where ppf.person_id = pps2.person_id)

       and ppf.employee_number = c_employee_number;


  cursor c_mgr_assignments (c_employee_number       varchar2 default null,
                            c_auto_update_when_null varchar2 default 'N') is
    select ppf.person_id                emp_person_id,
           ppf.attribute2               new_mgr_emp_num,
           ppf.employee_number          emp_employee_number,
           ppf.full_name                emp_full_name,
           ppf.object_version_number    emp_ppf_obj_ver_num,
           nvl(ppf.attribute1,c_auto_update_when_null) auto_update_flag,
           pas.assignment_id            emp_assignment_id,
           pas.effective_start_date     emp_pas_effective_start_dt,
           pas.supervisor_id            emp_supervisor_id,
           pas.object_version_number    emp_pas_obj_ver_num,
           ppf_new_mgr.person_id        new_mgr_person_id,
           ppf_new_mgr.full_name        new_mgr_full_name
      from per_all_people_f      ppf,
           per_all_people_f      ppf_new_mgr,
           per_all_assignments_f pas
     where ppf.person_id             = pas.person_id
       and nvl(ppf.attribute2,'xxx') = ppf_new_mgr.employee_number (+)
       and nvl(pas.supervisor_id,-11223344556677) != nvl(ppf_new_mgr.person_id,-11223344556677)

       and trunc(sysdate)      between ppf.effective_start_date
                                   and ppf.effective_end_date

       and pas.object_version_number  = (select max(pas2.object_version_number)
                                           from per_all_assignments_f pas2
                                          where ppf.person_id = pas2.person_id
                                            and pas2.primary_flag = 'Y')

       and trunc(sysdate)      between ppf_new_mgr.effective_start_date (+)
                                   and ppf_new_mgr.effective_end_date   (+)
       and ppf.employee_number like nvl(c_employee_number,'%')
     order by ppf.employee_number;


  cursor c_missing_emp (c_employee_number varchar2) is
    select ppf.person_id,
           ppf.employee_number,
           ppf.full_name
      from per_all_people_f ppf,
           per_person_types ppt
     where ppf.person_type_id      = ppt.person_type_id
       and ppt.system_person_type  = 'EMP'  -- EMP = active employee
       and nvl(ppf.attribute1,'N') = 'Y'    -- auto maintained
       and trunc(sysdate)          between ppf.effective_start_date
                                       and ppf.effective_end_date
       and not exists (select 'x'
                         from xxtps_cms_employees ext_emp
                        where ppf.employee_number = ext_emp.emp_id)
       and ppf.employee_number like nvl(c_employee_number,'%')
     order by ppf.employee_number;
-- ============================================================================


-------------------------------------------------------------------------------   
function dti return varchar2 is 
-------------------------------------------------------------------------------   
begin 
    return (to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') || ': '); 
end dti; 
-- ============================================================================ 
 
  
-------------------------------------------------------------------------------  
procedure wrtdbg (p_debug_level in  number,
                  p_buff        in varchar2) is 
-------------------------------------------------------------------------------  
 
  l_start_indx number; 
  l_temp_buff  varchar2(300); 
  l_done       boolean := FALSE; 
 
  l_buff       varchar2(4000);

begin 
  l_buff := dti || p_buff;

  if (g_debug_level >= p_debug_level) then
    if (g_conc_mgr_env = TRUE) then 
 
        -- 
        -- If we are in conc mgr env and we are trying to just print 
        -- a blank line, we don't need a chr(10) in addition to a 
        -- "put_line" command.  This causes two blank lines to be printed. 
        -- 
        if (l_buff = chr(10)) then 
            fnd_file.put_line (FND_FILE.LOG, null); 
        else 
            fnd_file.put_line (FND_FILE.LOG, l_buff); 
        end if; 
    else 
        -- 
        --  Oracle can only handle 250 characters at a time 
        -- 
        if (length(l_buff) < 250) then 
            dbms_output.put_line (l_buff); 
        else 
            l_start_indx := 1; 
 
            while (not l_done) loop 
                l_temp_buff := substr(p_buff,l_start_indx,200);         
                dbms_output.put_line (l_temp_buff); 
                 
                if (length(l_temp_buff) < 200) then 
                    l_done := TRUE; 
                end if; 
 
                l_start_indx := l_start_indx + 200; 
            end loop; 
        end if; 
    end if; 
  end if;
end wrtdbg; 
-- ============================================================================ 


------------------------------------------------------------------------------- 
procedure wrtlog (p_buff in varchar2) is 
------------------------------------------------------------------------------- 
    l_buff varchar2(2000); 
 
begin 
    l_buff := p_buff; 
 
    if (g_conc_mgr_env = TRUE) then 
        fnd_file.put_line (FND_FILE.LOG, l_buff); 
 
    else 
        -- 
        -- dbms_output cannot handle lines > 250 long 
        -- 
        dbms_output.put_line (substr(l_buff,1,250)); 
 
        while (length(l_buff) > 250) loop 
            l_buff := substr(l_buff,251); 
            dbms_output.put_line (substr(l_buff,1,250)); 
        end loop; 
    end if; 
end wrtlog; 
-- ============================================================================ 
 
 
------------------------------------------------------------------------------- 
procedure wrtout (p_buff in varchar2) is 
------------------------------------------------------------------------------- 
begin 
    if (g_conc_mgr_env = TRUE) then 
        fnd_file.put_line (FND_FILE.OUTPUT, p_buff); 
 
    else 
        dbms_output.put_line (p_buff); 
    end if; 
end wrtout; 
-- ============================================================================  


------------------------------------------------------------------------------- 
procedure initialize (p_commit_flag        in  varchar2,
                      p_debug_level        in  number,
                      p_sql_trace          in  varchar2,
                      p_emp_person_type_id out number,
                      p_business_group_id  out number,
                      p_msg                out varchar2) is
------------------------------------------------------------------------------- 

  l_proc       varchar2(80)   := 'INITIALIZE'; 
  l_ctx        varchar2(200)  := null; 

begin
  g_debug_level := p_debug_level; 

  g_warning_ct := 0;
 
  if (p_sql_trace = 'Y') then 
    l_ctx := 'Setting SQL trace ON';
    wrtlog (dti || 'Setting SQL trace ON'); 

    l_ctx := 'alter session max_dump_file_size';
    execute immediate 'ALTER SESSION SET max_dump_file_size = unlimited';

    l_ctx := 'alter session tracefile_identifier';
    execute immediate 'ALTER SESSION SET tracefile_identifier = ' || SQ || G_PACKAGE || SQ;

    l_ctx := 'alter session timed_statistics';
    execute immediate 'ALTER SESSION SET timed_statistics = true';

    l_ctx := 'alter session events 10046';
    execute immediate 'ALTER SESSION SET EVENTS ''10046 trace name context forever, level 12''';
  end if; 

  if (p_commit_flag = 'Y') then
    g_commit := TRUE;
  else
    g_commit := FALSE;
  end if;

  l_ctx := 'get "who" values';
  g_who_values(WHO_USER_ID)         := fnd_global.user_id;

  if (g_who_values(WHO_USER_ID) = ANONYMOUS_APPS_USER) then  
      g_who_values(WHO_CONC_REQUEST_ID) := null; 
      g_who_values(WHO_PROG_APPL_ID)    := null; 
      g_who_values(WHO_CONC_PROGRAM_ID) := null; 
      g_who_values(WHO_CONC_LOGIN_ID)   := null; 
      g_conc_mgr_env := FALSE; 
      dbms_output.enable (1000000); 
      wrtlog (dti || 'NOT executing in concurrent manager environment'); 
  else 
      g_who_values(WHO_CONC_REQUEST_ID) := fnd_global.conc_request_id; 
      g_who_values(WHO_PROG_APPL_ID)    := fnd_global.prog_appl_id; 
      g_who_values(WHO_CONC_PROGRAM_ID) := fnd_global.conc_program_id; 
      g_who_values(WHO_CONC_LOGIN_ID)   := fnd_global.conc_login_id; 
      g_conc_mgr_env := TRUE; 
      wrtlog (dti || 'Executing in concurrent manager environment'); 
  end if; 

  wrtdbg(DBG_LOW, '"who" values: ' ||
                   ' USER_ID=' || g_who_values(WHO_USER_ID) ||
                   ' CONC_REQUEST_ID=' || g_who_values(WHO_CONC_REQUEST_ID) ||
                   ' APPLICATION_ID=' || g_who_values(WHO_PROG_APPL_ID) ||
                   ' CONC_PROGRAM_ID=' || g_who_values(WHO_CONC_PROGRAM_ID) ||
                   ' CONC_LOGIN_ID=' || g_who_values(WHO_CONC_LOGIN_ID));

  l_ctx := 'select from per_person_types - system_person_type = "EMP"';
  select person_type_id
    into p_emp_person_type_id
    from per_person_types
   where system_person_type = 'EMP';

  l_ctx := 'select from hr_all_organization_units - name = "Setup Business Group", type = "BG"';
  select organization_id
    into p_business_group_id
    from hr_all_organization_units
   where name = 'Setup Business Group'
     and type = 'BG';

  wrtlog (dti || 'p_emp_person_type_id = ' || p_emp_person_type_id);
  wrtlog (dti || 'p_business_group_id = ' || p_business_group_id);
exception
  when others then  
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;   
end initialize; 
-- ============================================================================ 


-------------------------------------------------------------------------------   
function get_vc_for_boolean (p_boolean_value  in boolean)
  return varchar2 is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'get_vc_for_boolean';
  l_ctx        varchar2(200)  := null; 

  l_vc_value varchar2(10);

begin
    if (p_boolean_value is null) then
      l_vc_value := null;

    elsif (p_boolean_value = TRUE) then
      l_vc_value := 'TRUE';      

    elsif (p_boolean_value = FALSE) then
      l_vc_value := 'FALSE';

    else
      l_vc_value := 'UNKNOWN';
    end if;

    return (l_vc_value);
end get_vc_for_boolean;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure update_assignment_supervisor
              (p_employee_number      in     varchar2,
               p_emp_full_name        in     varchar2,
               p_assignment_id        in     number,
               p_effective_start_dt   in     date,
               p_pas_obj_ver_num      in out number,
               p_mgr_emp_num          in     varchar2,
               p_mgr_full_name        in     varchar2,
               p_mgr_person_id        in     number,
               p_okay                 out    boolean,
               p_msg                  out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_assignment_supervisor';
  l_ctx        varchar2(200)  := null;

  l_warning_msg    varchar2(250);

  l_object_version_number        number;
  l_concatenated_segments        varchar2(200);  -- not sure what this is so allocate lots of space
  l_soft_coding_keyflex_id       number;
  l_comment_id                   number;
  l_effective_start_date         date;
  l_effective_end_date           date;
  l_no_managers_warning          boolean;
  l_other_manager_warning        boolean;
  l_datetrack_update_mode        varchar2(50);

begin 

  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  --
  -- Determine DateTrack mode
  --
  if (p_effective_start_dt = trunc(sysdate)) then
    l_datetrack_update_mode := DATETRACK_MODE_CORRECTION;
  else
    l_datetrack_update_mode := DATETRACK_MODE_UPDATE;
  end if;

  wrtdbg (DBG_HI, '      p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '        p_emp_full_name = ' || p_emp_full_name);
  wrtdbg (DBG_HI, '        p_assignment_id = ' || p_assignment_id);
  wrtdbg (DBG_HI, '   p_effective_start_dt = ' || to_char(p_effective_start_dt,'DD-MON-YYYY'));
  wrtdbg (DBG_HI, '      p_pas_obj_ver_num = ' || p_pas_obj_ver_num);
  wrtdbg (DBG_HI, '          p_mgr_emp_num = ' || p_mgr_emp_num);
  wrtdbg (DBG_HI, '        p_mgr_full_name = ' || p_mgr_full_name);
  wrtdbg (DBG_HI, '        p_mgr_person_id = ' || p_mgr_person_id);
  wrtdbg (DBG_HI, 'l_datetrack_update_mode = ' || l_datetrack_update_mode);

  p_okay := TRUE;

  --
  -- These are in / out parameters, so they need to be initialized
  --
  l_soft_coding_keyflex_id  := hr_api.g_number;
  l_object_version_number   := p_pas_obj_ver_num;

  begin
    l_ctx := 'hr_assignment_api.update_emp_asg - p_assignment_id=' ||
                  p_assignment_id || ' p_employee_number=' || p_employee_number;

    hr_assignment_api.update_emp_asg (p_validate               => g_hr_api_validate,
                                      p_effective_date         => trunc(sysdate),
                                      p_datetrack_update_mode  => l_datetrack_update_mode,
                                      p_assignment_id          => p_assignment_id,
                                      p_object_version_number  => l_object_version_number,
                                      p_supervisor_id          => p_mgr_person_id,

                                      -- all fields below this point are "out" parameters.
                                      p_concatenated_segments  => l_concatenated_segments,
                                      p_soft_coding_keyflex_id => l_soft_coding_keyflex_id,
                                      p_comment_id             => l_comment_id,
                                      p_effective_start_date   => l_effective_start_date,
                                      p_effective_end_date     => l_effective_end_date,
                                      p_no_managers_warning    => l_no_managers_warning,
                                      p_other_manager_warning  => l_other_manager_warning);
    exception
      when others then
        p_okay := FALSE;
        g_warning_ct := g_warning_ct + 1;
        wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                     ' hr_assignment_api.update_emp_asg had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
    end;

  if (p_okay) then
    wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) ||
                  ' Updated supervisor to ' || p_mgr_emp_num || ' ' ||
                    rpad(p_mgr_full_name,20));

    wrtdbg(DBG_MED, '  After call to hr_assignment_api.update_emp_asg:');
    wrtdbg(DBG_MED,'          l_concatenated_segments = ' || l_concatenated_segments);
    wrtdbg(DBG_MED,'         l_soft_coding_keyflex_id = ' || l_soft_coding_keyflex_id);
    wrtdbg(DBG_MED,'                     l_comment_id = ' || l_comment_id);
    wrtdbg(DBG_MED,'           l_effective_start_date = ' || to_char(l_effective_start_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'             l_effective_end_date = ' || to_char(l_effective_end_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'            l_no_managers_warning = ' || get_vc_for_boolean (l_no_managers_warning));
    wrtdbg(DBG_MED,'          l_other_manager_warning = ' || get_vc_for_boolean (l_other_manager_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if ((l_no_managers_warning = TRUE) or (l_other_manager_warning = TRUE)) then
      l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                       ' Update supervisor warnings:';

      if (l_no_managers_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_no_managers_warning';
      end if;

      if (l_other_manager_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_other_manager_warning';
      end if;

      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    p_pas_obj_ver_num := l_object_version_number;
  end if;  -- if (p_okay)

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' - p_pas_obj_ver_num=' || p_pas_obj_ver_num);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_assignment_supervisor;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure update_assignment_dff (p_employee_number      in     varchar2,
                                 p_emp_full_name        in     varchar2,
                                 p_assignment_id        in     number,
                                 p_effective_start_dt   in     date,
                                 p_pas_obj_ver_num      in out number,
                                 p_okay                 out    boolean,
                                 p_msg                  out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_assignment_dff';
  l_ctx        varchar2(200)  := null;

  l_warning_msg    varchar2(250);
  l_upd_mgr        boolean := FALSE;
  l_mgr_person_id  number  := null;
  l_mgr_full_name  per_all_people_f.full_name %type;

  l_object_version_number        number;
  l_concatenated_segments        varchar2(200);  -- not sure what this is so allocate lots of space
  l_soft_coding_keyflex_id       number;
  l_comment_id                   number;
  l_effective_start_date         date;
  l_effective_end_date           date;
  l_no_managers_warning          boolean;
  l_other_manager_warning        boolean;
  l_datetrack_update_mode        varchar2(50);

begin

  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  --
  -- Determine DateTrack mode
  --
  if (p_effective_start_dt = trunc(sysdate)) then
    l_datetrack_update_mode := DATETRACK_MODE_CORRECTION;
  else
    l_datetrack_update_mode := DATETRACK_MODE_UPDATE;
  end if;

  wrtdbg (DBG_HI, '      p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '        p_emp_full_name = ' || p_emp_full_name);
  wrtdbg (DBG_HI, '        p_assignment_id = ' || p_assignment_id);
  wrtdbg (DBG_HI, '      p_pas_obj_ver_num = ' || p_pas_obj_ver_num);
  wrtdbg (DBG_HI, 'l_datetrack_update_mode = ' || l_datetrack_update_mode);

  p_okay := TRUE;

  --
  -- Attribute1 - 7 are required in per_all_assignments_f in GSIDEV02 and TOPUAT01.
  -- None of the attributes currently have validation so we can assign them to any value.
  -- We must do this, or we will get an error when attempting to assign the job_id to per_all_assignments_f.
  -- This is a temporary solution.  Either these DFF's need to be removed, or we need to populate them properly.
  --

  --
  -- These are in / out parameters, so they need to be initialized
  --
  l_object_version_number   := p_pas_obj_ver_num;
  l_soft_coding_keyflex_id  := hr_api.g_number;  -- special value for HR API's indicating no change requested

  begin
    l_ctx := 'hr_assignment_api.update_emp_asg - p_assignment_id=' ||
                  p_assignment_id || ' p_employee_number=' || p_employee_number;

    hr_assignment_api.update_emp_asg (p_validate               => g_hr_api_validate,
                                      p_effective_date         => trunc(sysdate),
                                      p_datetrack_update_mode  => l_datetrack_update_mode,
                                      p_assignment_id          => p_assignment_id,
                                      p_object_version_number  => l_object_version_number,

                                      -- these parameters for DEV02 instance only - they are required
                                      P_ASS_ATTRIBUTE1 => 'x',
                                      P_ASS_ATTRIBUTE2 => 'x',
                                      P_ASS_ATTRIBUTE3 => 'x',
                                      P_ASS_ATTRIBUTE4 => 'x',
                                      P_ASS_ATTRIBUTE5 => 'x',
                                      P_ASS_ATTRIBUTE6 => 'x',
                                      P_ASS_ATTRIBUTE7 => 'x',

                                      -- all fields below this point are "out" parameters.
                                      p_concatenated_segments  => l_concatenated_segments,
                                      p_soft_coding_keyflex_id => l_soft_coding_keyflex_id,
                                      p_comment_id             => l_comment_id,
                                      p_effective_start_date   => l_effective_start_date,
                                      p_effective_end_date     => l_effective_end_date,
                                      p_no_managers_warning    => l_no_managers_warning,
                                      p_other_manager_warning  => l_other_manager_warning);
  exception
    when others then
      p_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                   ' hr_assignment_api.update_emp_asg had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
  end;

  if (p_okay) then
    wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) ||
                  ' Updated assignment DFFs to dummy values.');

    wrtdbg(DBG_MED, '  After call to hr_assignment_api.update_emp_asg:');
    wrtdbg(DBG_MED,'          l_concatenated_segments = ' || l_concatenated_segments);
    wrtdbg(DBG_MED,'         l_soft_coding_keyflex_id = ' || l_soft_coding_keyflex_id);
    wrtdbg(DBG_MED,'                     l_comment_id = ' || l_comment_id);
    wrtdbg(DBG_MED,'           l_effective_start_date = ' || to_char(l_effective_start_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'             l_effective_end_date = ' || to_char(l_effective_end_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'            l_no_managers_warning = ' || get_vc_for_boolean (l_no_managers_warning));
    wrtdbg(DBG_MED,'          l_other_manager_warning = ' || get_vc_for_boolean (l_other_manager_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if ((l_no_managers_warning = TRUE) or (l_other_manager_warning = TRUE)) then
      l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                       ' Update supervisor warnings:';

      if (l_no_managers_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_no_managers_warning';
      end if;

      if (l_other_manager_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_other_manager_warning';
      end if;

      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    p_pas_obj_ver_num := l_object_version_number;
  end if;  -- if (p_okay)

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' - p_pas_obj_ver_num=' || p_pas_obj_ver_num);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_assignment_dff;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure update_assignment_job
              (p_employee_number      in     varchar2,
               p_emp_full_name        in     varchar2,
               p_assignment_id        in     number,
               p_effective_start_dt   in     date,
               p_pas_obj_ver_num      in out number,
               p_new_job_name         in     varchar2,
               p_okay                 out    boolean,
               p_msg                  out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_assignment_job';
  l_ctx        varchar2(200)  := null;

  l_upd_job      boolean := FALSE;
  l_job_id       number;
  l_warning_msg  varchar2(250);

  l_people_group_id              number;
  l_object_version_number        number;
  l_special_ceiling_step_id      number;
  l_group_name                   varchar2(200);  -- not sure what this is so allocate lots of space
  l_effective_start_date         date;
  l_effective_end_date           date;
  l_org_now_no_manager_warning   boolean;
  l_other_manager_warning        boolean;
  l_spp_delete_warning           boolean;
  l_entries_changed_warning      varchar2(200);  -- not sure what this is so allocate lots of space
  l_tax_district_changed_warning boolean;
  l_datetrack_update_mode        varchar2(50);

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  --
  -- Determine DateTrack mode
  --
  if (p_effective_start_dt = trunc(sysdate)) then
    l_datetrack_update_mode := DATETRACK_MODE_CORRECTION;
  else
    l_datetrack_update_mode := DATETRACK_MODE_UPDATE;
  end if;

  wrtdbg (DBG_HI, '      p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '        p_emp_full_name = ' || p_emp_full_name);
  wrtdbg (DBG_HI, '        p_assignment_id = ' || p_assignment_id);
  wrtdbg (DBG_HI, '      p_pas_obj_ver_num = ' || p_pas_obj_ver_num);
  wrtdbg (DBG_HI, '         p_new_job_name = ' || p_new_job_name);
  wrtdbg (DBG_HI, 'l_datetrack_update_mode = ' || l_datetrack_update_mode);

  p_okay := TRUE;

  --
  -- Get the job id for the job name
  --
  if (p_new_job_name is null) then
    l_upd_job := TRUE;
    l_job_id := null;

  else
    begin
      select job_id
        into l_job_id
        from per_jobs
       where name = p_new_job_name
         and trunc(sysdate) between date_from
                                and nvl(date_to,sysdate+1);

      l_upd_job := TRUE;

    exception
      when no_data_found then
        l_upd_job := FALSE;
        g_warning_ct := g_warning_ct + 1;
        wrtlog ('W: job "' || p_new_job_name || '" not found for emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20));

     when others then
       l_upd_job := FALSE;
       g_warning_ct := g_warning_ct + 1;
       wrtlog ('W: job "' || p_new_job_name || '" not available for emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) || ' error: ' || SQLERRM);
    end;
  end if;

  wrtdbg (DBG_HI,'  After fetch:');
  wrtdbg (DBG_HI,'   l_upd_job = ' || get_vc_for_boolean(l_upd_job));
  wrtdbg (DBG_HI,'    l_job_id = ' || l_job_id);

  --
  -- Now set the job assigned to the employee
  --
  if (l_upd_job = TRUE) then
    --
    -- These are in / out parameters, so they need to be initialized
    --
    l_people_group_id         := hr_api.g_number;  -- special value for HR API's indicating no change requested
    l_special_ceiling_step_id := hr_api.g_number;
    l_object_version_number   := p_pas_obj_ver_num;

    begin
      l_ctx := 'hr_assignment_api.update_emp_asg_criteria - p_assignment_id=' ||
                    p_assignment_id || ' p_employee_number=' || p_employee_number;

      hr_assignment_api.update_emp_asg_criteria (p_effective_date               => trunc(sysdate),
                                                 p_datetrack_update_mode        => l_datetrack_update_mode,
                                                 p_assignment_id                => p_assignment_id,
                                                 p_validate                     => g_hr_api_validate,
                                                 p_job_id                       => l_job_id,

                                                 -- all fields below this point are "out" parameters.
                                                 p_people_group_id              => l_people_group_id,
                                                 p_object_version_number        => l_object_version_number,
                                                 p_special_ceiling_step_id      => l_special_ceiling_step_id,
                                                 p_group_name                   => l_group_name,
                                                 p_effective_start_date         => l_effective_start_date,
                                                 p_effective_end_date           => l_effective_end_date,
                                                 p_org_now_no_manager_warning   => l_org_now_no_manager_warning,
                                                 p_other_manager_warning        => l_other_manager_warning,
                                                 p_spp_delete_warning           => l_spp_delete_warning,
                                                 p_entries_changed_warning      => l_entries_changed_warning,
                                                 p_tax_district_changed_warning => l_tax_district_changed_warning);
    exception
      when others then
        p_okay := FALSE;
        g_warning_ct := g_warning_ct + 1;
        wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                    ' hr_assignment_api.update_emp_asg_criteria had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
    end;

    if (p_okay) then
      wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) ||
                    ' Updated job to "' || p_new_job_name || '" (job_id=' || l_job_id || ')');

      wrtdbg(DBG_MED, '  After call to hr_assignment_api.update_emp_asg_criteria:');
      wrtdbg(DBG_MED,'                l_people_group_id = ' || l_people_group_id);
      wrtdbg(DBG_MED,'          l_object_version_number = ' || l_object_version_number);
      wrtdbg(DBG_MED,'        l_special_ceiling_step_id = ' || l_special_ceiling_step_id);
      wrtdbg(DBG_MED,'                     l_group_name = ' || l_group_name);
      wrtdbg(DBG_MED,'           l_effective_start_date = ' || to_char(l_effective_start_date,'DD-MON-YYYY'));
      wrtdbg(DBG_MED,'             l_effective_end_date = ' || to_char(l_effective_end_date,'DD-MON-YYYY'));
      wrtdbg(DBG_MED,'     l_org_now_no_manager_warning = ' || get_vc_for_boolean (l_org_now_no_manager_warning));
      wrtdbg(DBG_MED,'          l_other_manager_warning = ' || get_vc_for_boolean (l_other_manager_warning));
      wrtdbg(DBG_MED,'             l_spp_delete_warning = ' || get_vc_for_boolean (l_spp_delete_warning));
      wrtdbg(DBG_MED,'        l_entries_changed_warning = ' || l_entries_changed_warning);
      wrtdbg(DBG_MED,'   l_tax_district_changed_warning = ' || get_vc_for_boolean (l_tax_district_changed_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
      l_warning_msg := null;
      if ((l_org_now_no_manager_warning = TRUE) or (l_other_manager_warning = TRUE)   or
          (l_spp_delete_warning = TRUE) or (l_tax_district_changed_warning = TRUE)) then
        l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                         ' Update job name warnings:';

        if (l_org_now_no_manager_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_org_now_no_manager_warning';
        end if;

        if (l_other_manager_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_other_manager_warning';
        end if;

        if (l_spp_delete_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_spp_delete_warning';
        end if;

        if (l_tax_district_changed_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_tax_district_changed_warning';
        end if;

        g_warning_ct := g_warning_ct + 1;
        wrtlog (l_warning_msg);
      end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

      p_pas_obj_ver_num := l_object_version_number;

    end if;  -- if (p_okay)
  end if;  -- if (l_upd_job = TRUE)

  wrtdbg (DBG_MED, 'Exit ' || l_proc || ' - p_pas_obj_ver_num=' || p_pas_obj_ver_num);
exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_assignment_job;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure get_fnd_user_info (p_employee_number in  varchar2,
                             p_full_name       in  varchar2,
                             p_fnd_user_id     out number,
                             p_employee_id     out number,
                             p_person_party_id out number,
                             p_email_address   out varchar2,
                             p_msg             out varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'get_fnd_user_info';
  l_ctx        varchar2(200)  := null; 

  l_employee_id      number;
  l_user_id          number;
  l_person_party_id  number;
  l_email_address    fnd_user.email_address %type;

begin 

  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtdbg (DBG_HI, '  p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '        p_full_name = ' || p_full_name);

  begin
    select user_id,
           employee_id,
           person_party_id,
           email_address
      into l_user_id,
           l_employee_id,
           l_person_party_id,
           l_email_address
      from fnd_user
     where user_name = p_employee_number;

  exception
    when no_data_found then
      l_user_id         := null;
      l_employee_id     := null;
      l_person_party_id := null;
      l_email_address   := null;
  end;

  p_fnd_user_id     := l_user_id;
  p_employee_id     := l_employee_id;
  p_person_party_id := l_person_party_id; 
  p_email_address   := l_email_address;

  wrtdbg (DBG_MED, '  After fetch:');
  wrtdbg (DBG_MED, '      p_fnd_user_id = ' || p_fnd_user_id);
  wrtdbg (DBG_MED, '      p_employee_id = ' || p_employee_id);
  wrtdbg (DBG_MED, '  p_person_party_id = ' || p_person_party_id);
  wrtdbg (DBG_MED, '    p_email_address = ' || p_email_address);

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end get_fnd_user_info;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure update_fnd_user_info (p_employee_number in  varchar2,
                                p_full_name       in  varchar2,
                                p_person_id       in  number,
                                p_okay            out boolean,
                                p_msg             out varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_fnd_user_info';
  l_ctx        varchar2(200)  := null; 

begin 

  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtdbg (DBG_HI, '  p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '        p_full_name = ' || p_full_name);
  wrtdbg (DBG_HI, '        p_person_id = ' || p_person_id);

  p_okay := TRUE;

  begin
    fnd_user_pkg.updateuser (x_user_name   => p_employee_number,
                             x_owner       => 'CUST',  -- CUST means this is not a seeded user
                             x_employee_id => p_person_id);
  exception
    when others then
      p_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_full_name,20) ||
                   ' fnd_user_pkg.updateuser.  Skipping this employee.  SQLERRM=' || SQLERRM);
  end;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_fnd_user_info;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure insert_emp  (p_ext_hr_rec             in  c_ext_hr_info%rowtype,
                       p_emp_person_type_id     in  number,
                       p_business_group_id      in  number,
                       p_allow_missing_fnd_user in  varchar2,
                       p_emp_inserted           out boolean,
                       p_msg                    out varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'insert_emp';
  l_ctx        varchar2(200)  := null; 

  --
  -- This value is set to indicate that this program can perform future updates
  -- to this employee's info in Oracle if it changes in the external system.
  --
  -- We always use "Y" in this program.
  -- If an HR representative does not want auto updates, they can set the value
  -- to "N" for individual employees.
  --
  l_auto_update       constant varchar2(1) := 'Y';

  l_curr_date         constant date        := trunc(sysdate);
  l_hire_date         date    := trunc(sysdate);
  l_sex               per_all_people_f.sex %type;
  l_emp_num           per_all_people_f.employee_number %type;

  l_person_id                 number;
  l_assignment_id             number;
  l_per_obj_ver_num           number;
  l_pas_obj_ver_num           number;
  l_per_effective_start_date  date;
  l_per_effective_end_date    date;
  l_full_name                 per_all_people_f.full_name %type; 
  l_per_comment_id            number;
  l_assignment_sequence       number;
  l_assignment_number         per_all_assignments_f.assignment_number %type;
  l_name_combination_warning  boolean;
  l_assign_payroll_warning    boolean;
  l_orig_hire_warning         boolean;

  l_fnd_user_id               number;
  l_employee_id               number;
  l_person_party_id           number;
  l_fnd_email_address         fnd_user.email_address %type;

  l_okay                      boolean;
  l_warning_msg               varchar2(250);

begin 

  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  l_ctx := 'savepoint XXCRM_SAVEPOINT';
  savepoint XXCRM_SAVEPOINT;

  l_okay := TRUE;
  p_emp_inserted := FALSE;

  get_fnd_user_info (p_employee_number => p_ext_hr_rec.emp_id,
                     p_full_name       => p_ext_hr_rec.last_name || ', ' || p_ext_hr_rec.first_name,
                     p_fnd_user_id     => l_fnd_user_id,
                     p_employee_id     => l_employee_id,
                     p_person_party_id => l_person_party_id,
                     p_email_address   => l_fnd_email_address,
                     p_msg             => p_msg);

  if (p_msg is not null) then
    return;
  end if;

  if (p_allow_missing_fnd_user = 'N') then
    if (l_fnd_user_id is null) then
      l_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_ext_hr_rec.emp_id || ' ' ||
                       rpad(p_ext_hr_rec.last_name || ', ' || p_ext_hr_rec.first_name,20) ||
                     ' does not have a login account (fnd_user).  Skipping this employee.');
    end if;
  end if;


  if (l_okay) then
    -- Oracle requires gender.  Only valid values in API are M or F.
    -- Using HR Foundation responsibility (shared HR) it is possible to enter Gender of Unknown.
    -- Unknown gender is stored as null in per_all_people_f.sex column.  However, the API doesn't support "Unknown".
    -- Gender isn't provided by the external feed, so we will arbitrarily choose a gender and assign it to everyone.
    --
    l_sex := 'M';

    --
    -- employee_number is an in / out parameter to the API because the API allows
    -- automatic generation of the number.  Although we specify the emp num, we
    -- still need to put it in a local var to accommodate the in / out property.
    --
    l_emp_num := p_ext_hr_rec.emp_id;

    begin
      l_ctx := 'hr_employee_api.create_employee - l_emp_num=' || l_emp_num;
      hr_employee_api.create_employee (p_validate                  => g_hr_api_validate,
                                       p_hire_date                 => l_curr_date,
                                       p_business_group_id         => p_business_group_id,
                                       p_sex                       => l_sex,
                                       p_person_type_id            => p_emp_person_type_id,
                                       p_last_name                 => p_ext_hr_rec.last_name,
                                       p_first_name                => p_ext_hr_rec.first_name,
                                       p_middle_names              => p_ext_hr_rec.middle_initial,
                                       p_employee_number           => l_emp_num,
                                       p_party_id                  => l_person_party_id,
                                       p_email_address             => l_fnd_email_address,
                                       p_attribute1                => l_auto_update,
                                       p_attribute2                => p_ext_hr_rec.reports_to_id,

                                       -- all fields below this point are "out" parameters.
                                       p_person_id                 => l_person_id,
                                       p_assignment_id             => l_assignment_id,
                                       p_per_object_version_number => l_per_obj_ver_num,
                                       p_asg_object_version_number => l_pas_obj_ver_num,
                                       p_per_effective_start_date  => l_per_effective_start_date,
                                       p_per_effective_end_date    => l_per_effective_end_date,
                                       p_full_name                 => l_full_name,
                                       p_per_comment_id            => l_per_comment_id,
                                       p_assignment_sequence       => l_assignment_sequence,
                                       p_assignment_number         => l_assignment_number,
                                       p_name_combination_warning  => l_name_combination_warning,
                                       p_assign_payroll_warning    => l_assign_payroll_warning,
                                       p_orig_hire_warning         => l_orig_hire_warning);
    exception
      when others then
        l_okay := FALSE;
        g_warning_ct := g_warning_ct + 1;
        wrtlog (dti || 'W: Emp ' || p_ext_hr_rec.emp_id  || ' ' ||
                       rpad(p_ext_hr_rec.last_name || ', ' || p_ext_hr_rec.first_name,20) ||
                     ' hr_employee_api.create_employee had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
    end;
  end if;  -- if (l_okay)

  if (l_okay) then
    wrtlog(dti || 'I: Emp ' || p_ext_hr_rec.emp_id  || ' ' || rpad(l_full_name,20) ||
                  ' Created employee ' || p_ext_hr_rec.last_name || ', ' || p_ext_hr_rec.first_name);

    wrtdbg(DBG_MED,'  After call to hr_employee_api.create_employee:');
    wrtdbg(DBG_MED,'                     l_person_id = ' || l_person_id);
    wrtdbg(DBG_MED,'                 l_assignment_id = ' || l_assignment_id);
    wrtdbg(DBG_MED,'               l_per_obj_ver_num = ' || l_per_obj_ver_num);
    wrtdbg(DBG_MED,'               l_pas_obj_ver_num = ' || l_pas_obj_ver_num);
    wrtdbg(DBG_MED,'      l_per_effective_start_date = ' || to_char(l_per_effective_start_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'        l_per_effective_end_date = ' || to_char(l_per_effective_end_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'                     l_full_name = ' || l_full_name);
    wrtdbg(DBG_MED,'                l_per_comment_id = ' || l_per_comment_id);
    wrtdbg(DBG_MED,'           l_assignment_sequence = ' || l_assignment_sequence);
    wrtdbg(DBG_MED,'             l_assignment_number = ' || l_assignment_number);
    wrtdbg(DBG_MED,'      l_name_combination_warning = ' || get_vc_for_boolean (l_name_combination_warning));
    wrtdbg(DBG_MED,'        l_assign_payroll_warning = ' || get_vc_for_boolean (l_assign_payroll_warning));
    wrtdbg(DBG_MED,'             l_orig_hire_warning = ' || get_vc_for_boolean (l_orig_hire_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if ((l_name_combination_warning = TRUE) or (l_assign_payroll_warning = TRUE) or (l_orig_hire_warning = TRUE)) then
      l_warning_msg := 'WARNING: Emp ' || p_ext_hr_rec.emp_id  || ' ' || rpad(l_full_name,20) ||
                       ' Create employee warnings:';

      if (l_name_combination_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_name_combination_warning';
      end if;

      if (l_assign_payroll_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_assign_payroll_warning';
      end if;

      if (l_orig_hire_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_orig_hire_warning';
      end if;

      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    -- p_employee_number is an in/out parameter.  Verify it didn't change.
    if ((l_emp_num != p_ext_hr_rec.emp_id) or (l_emp_num is null)) then
      -- This is a fatal error.
      p_msg := 'Emp ' || p_ext_hr_rec.emp_id  || ' ' || rpad(l_full_name,20) || ' employee number was changed to ' ||
                 nvl(l_emp_num,'<null>') || ' by Oracle.  This is not allowed.';
      return;
    end if;

    update_assignment_dff (p_employee_number    => p_ext_hr_rec.emp_id,
                           p_emp_full_name      => l_full_name,
                           p_assignment_id      => l_assignment_id,
                           p_effective_start_dt => l_per_effective_start_date, -- new emp inserted;  new assignment rec also created
                           p_pas_obj_ver_num    => l_pas_obj_ver_num,  -- value is updated upon return
                           p_okay               => l_okay,
                           p_msg                => p_msg);

    if (p_msg is not null) then
      return;
    end if;
  end if;  -- if (l_okay)

  if (l_okay) then
    if (p_ext_hr_rec.oracle_job_title is not null) then
      update_assignment_job (p_employee_number    => p_ext_hr_rec.emp_id,
                             p_emp_full_name      => l_full_name,
                             p_assignment_id      => l_assignment_id,
                             p_effective_start_dt => l_per_effective_start_date, -- new emp inserted;  new assignment rec also created
                             p_pas_obj_ver_num    => l_pas_obj_ver_num,  -- value is updated upon return
                             p_new_job_name       => p_ext_hr_rec.oracle_job_title,
                             p_okay               => l_okay,
                             p_msg                => p_msg);

      if (p_msg is not null) then
        return;
      end if;
    end if;
  end if;

  if (l_okay) then
    if (l_fnd_user_id is not null) then
      update_fnd_user_info (p_employee_number => p_ext_hr_rec.emp_id,
                            p_full_name       => l_full_name,
                            p_person_id       => l_person_id,
                            p_okay            => l_okay,
                            p_msg             => p_msg);
    
      if (p_msg is not null) then
        return;
      end if;
    end if;
  end if;

  if (l_okay = TRUE) then
      p_emp_inserted := TRUE;

  else
    wrtdbg (DBG_MED, 'Rolling back to savepoint XXCRM_SAVEPOINT');
    l_ctx := 'rollback to XXCRM_SAVEPOINT';
    rollback to savepoint XXCRM_SAVEPOINT;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end insert_emp;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure update_emp (p_employee_number    in     varchar2,
                      p_person_id          in     number,
                      p_effective_start_dt in     date,
                      p_orig_emp_full_name in     varchar2,
                      p_ppf_obj_ver_num    in out number,
                      p_new_first_name     in     varchar2,
                      p_new_last_name      in     varchar2,
                      p_new_middle_names   in     varchar2,
                      p_new_email_address  in     varchar2,
                      p_new_party_id       in     number,
                      p_new_mgr_emp_num    in     varchar2,
                      p_okay               out    boolean,
                      p_msg                out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_emp';
  l_ctx        varchar2(200)  := null; 

  l_warning_msg     varchar2(250);
  l_ppf_obj_ver_num number;

  l_employee_number            per_all_people_f.employee_number %type;
  l_effective_start_date       date;
  l_effective_end_date         date;
  l_new_emp_full_name          per_all_people_f.full_name %type;
  l_comment_id                 number;
  l_name_combination_warning   boolean;
  l_assign_payroll_warning     boolean;
  l_orig_hire_warning          boolean;
  l_datetrack_update_mode        varchar2(50);

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  --
  -- Determine DateTrack mode
  --
  if (p_effective_start_dt = trunc(sysdate)) then
    l_datetrack_update_mode := DATETRACK_MODE_CORRECTION;
  else
    l_datetrack_update_mode := DATETRACK_MODE_UPDATE;
  end if;

  wrtdbg (DBG_HI, '      p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '            p_person_id = ' || p_person_id);
  wrtdbg (DBG_HI, '   p_orig_emp_full_name = ' || p_orig_emp_full_name);
  wrtdbg (DBG_HI, '      p_ppf_obj_ver_num = ' || p_ppf_obj_ver_num);
  wrtdbg (DBG_HI, '       p_new_first_name = ' || p_new_first_name);
  wrtdbg (DBG_HI, '        p_new_last_name = ' || p_new_last_name);
  wrtdbg (DBG_HI, '     p_new_middle_names = ' || p_new_middle_names);
  wrtdbg (DBG_HI, '    p_new_email_address = ' || p_new_email_address);
  wrtdbg (DBG_HI, '         p_new_party_id = ' || p_new_party_id);
  wrtdbg (DBG_HI, '      p_new_mgr_emp_num = ' || p_new_mgr_emp_num);
  wrtdbg (DBG_HI, 'l_datetrack_update_mode = ' || l_datetrack_update_mode);

  p_okay := TRUE;

  --
  -- These are in / out parameters, so they need to be initialized
  --
  l_employee_number := hr_api.g_varchar2;  -- special value for HR API's indicating no change requested
  l_ppf_obj_ver_num := p_ppf_obj_ver_num;

  begin
    l_ctx := 'hr_person_api.update_person - p_person_id=' ||
                  p_person_id || ' p_employee_number=' || p_employee_number;

    hr_person_api.update_person (p_validate                 => g_hr_api_validate,
                                 p_effective_date           => trunc(sysdate),
                                 p_datetrack_update_mode    => l_datetrack_update_mode,
                                 p_person_id                => p_person_id,
                                 p_object_version_number    => l_ppf_obj_ver_num,
                                 p_employee_number          => l_employee_number,
                                 p_last_name                => p_new_last_name,
                                 p_first_name               => p_new_first_name,
                                 p_middle_names             => p_new_middle_names,
                                 p_email_address            => p_new_email_address,
                                 p_party_id                 => p_new_party_id,
                                 p_attribute1               => 'Y',  -- could have been null if p_auto_update_when_null = "Y"
                                 p_attribute2               => p_new_mgr_emp_num,

                                 -- all fields below this point are "out" parameters.
                                 p_effective_start_date     => l_effective_start_date,
                                 p_effective_end_date       => l_effective_end_date,
                                 p_full_name                => l_new_emp_full_name,
                                 p_comment_id               => l_comment_id,
                                 p_name_combination_warning => l_name_combination_warning,
                                 p_assign_payroll_warning   => l_assign_payroll_warning,
                                 p_orig_hire_warning        => l_orig_hire_warning);
  exception
    when others then
      p_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_orig_emp_full_name,20) ||
                   ' hr_person_api.update_person had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
  end;

  if (p_okay) then

    -- p_employee_number is an in/out parameter.  Verify it didn't change.
    if ((l_employee_number != p_employee_number) or (l_employee_number is null)) then
      -- This is a fatal error.
      p_msg := 'Emp ' || p_employee_number  || ' ' || rpad(p_orig_emp_full_name,20) || ' employee number was changed to ' ||
                 nvl(l_employee_number,'<null>') || ' by Oracle.  This is not allowed.';
      return;
    end if;

    wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_orig_emp_full_name,20) ||
                  ' Updated employee general information.');

    wrtdbg(DBG_MED, '  After call to hr_person_api.update_person:');
    wrtdbg(DBG_MED,'           l_effective_start_date = ' || to_char(l_effective_start_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'             l_effective_end_date = ' || to_char(l_effective_end_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'              l_new_emp_full_name = ' || l_new_emp_full_name);
    wrtdbg(DBG_MED,'                     l_comment_id = ' || l_comment_id);
    wrtdbg(DBG_MED,'       l_name_combination_warning = ' || get_vc_for_boolean (l_name_combination_warning));
    wrtdbg(DBG_MED,'         l_assign_payroll_warning = ' || get_vc_for_boolean (l_assign_payroll_warning));
    wrtdbg(DBG_MED,'              l_orig_hire_warning = ' || get_vc_for_boolean (l_orig_hire_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if ((l_name_combination_warning = TRUE) or (l_assign_payroll_warning = TRUE) or (l_orig_hire_warning = TRUE)) then
      l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                       ' Update employee warnings:';

      if (l_name_combination_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_name_combination_warning';
      end if;

      if (l_assign_payroll_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_assign_payroll_warning';
      end if;

      if (l_orig_hire_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_orig_hire_warning';
      end if;

      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    p_ppf_obj_ver_num := l_ppf_obj_ver_num;

  end if;  -- if (p_okay)

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_emp;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure re_hire_employee (p_employee_number in     varchar2,
                            p_emp_full_name   in     varchar2,
                            p_person_id       in     number,
                            p_ppf_obj_ver_num in out number,
                            p_pas_obj_ver_num out    number,
                            p_okay            out    boolean,
                            p_msg             out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 're_hire_employee';
  l_ctx        varchar2(200)  := null; 

  l_ppf_obj_ver_num  number;
  l_pas_obj_ver_num  number;
  l_warning_msg      varchar2(200);

  l_rehire_reason            per_all_people_f.rehire_reason %type := null;
  l_assignment_id            number;
  l_per_effective_start_date date;
  l_per_effective_end_date   date;
  l_assignment_sequence      number;
  l_assignment_number        per_all_assignments_f.assignment_number %type;
  l_assign_payroll_warning   boolean;

begin 
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtdbg (DBG_HI, '   p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '     p_emp_full_name = ' || p_emp_full_name);
  wrtdbg (DBG_HI, '         p_person_id = ' || p_person_id);
  wrtdbg (DBG_HI, '   p_ppf_obj_ver_num = ' || p_ppf_obj_ver_num);

  p_okay := TRUE;

  --
  -- These are in / out parameters, so they need to be initialized
  --
  l_ppf_obj_ver_num := p_ppf_obj_ver_num;

  begin
    l_ctx := 'hr_employee_api.re_hire_ex_employee - p_person_id = ' ||
                   p_person_id ||  ' p_employee_number=' || p_employee_number;

    hr_employee_api.re_hire_ex_employee (p_validate                  => g_hr_api_validate,
                                         p_hire_date                 => trunc(sysdate),
                                         p_person_id                 => p_person_id,
                                         p_per_object_version_number => l_ppf_obj_ver_num,
                                         p_rehire_reason             => l_rehire_reason,

                                         -- all fields below this point are "out" parameters.
                                         p_assignment_id             => l_assignment_id,
                                         p_asg_object_version_number => l_pas_obj_ver_num,
                                         p_per_effective_start_date  => l_per_effective_start_date,
                                         p_per_effective_end_date    => l_per_effective_end_date,
                                         p_assignment_sequence       => l_assignment_sequence,
                                         p_assignment_number         => l_assignment_number,
                                         p_assign_payroll_warning    => l_assign_payroll_warning);
  exception
    when others then
      p_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                   ' hr_employee_api.re_hire_ex_employee had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
  end;

  if (p_okay) then
    wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) ||
                  ' Rehired employee.');

    wrtdbg(DBG_MED, '  After call to hr_employee_api.re_hire_ex_employee:');
    wrtdbg(DBG_MED,'           l_ppf_obj_ver_num = ' || l_ppf_obj_ver_num);
    wrtdbg(DBG_MED,'             l_assignment_id = ' || l_assignment_id);
    wrtdbg(DBG_MED,'           l_pas_obj_ver_num = ' || l_pas_obj_ver_num);
    wrtdbg(DBG_MED,'  l_per_effective_start_date = ' || to_char(l_per_effective_start_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'    l_per_effective_end_date = ' || to_char(l_per_effective_end_date,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'       l_assignment_sequence = ' || l_assignment_sequence);
    wrtdbg(DBG_MED,'         l_assignment_number = ' || l_assignment_number);
    wrtdbg(DBG_MED,'    l_assign_payroll_warning = ' || get_vc_for_boolean (l_assign_payroll_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if (l_assign_payroll_warning = TRUE) then
      l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                       ' Re-hire employee warnings:';

      if (l_assign_payroll_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_assign_payroll_warning';
      end if;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    p_ppf_obj_ver_num := l_ppf_obj_ver_num;
    p_pas_obj_ver_num := l_pas_obj_ver_num;
  end if;  -- if (p_okay)

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end re_hire_employee;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure terminate_employee (p_employee_number      in     varchar2,
                              p_emp_full_name        in     varchar2,
                              p_period_of_service_id in     number,
                              p_pps_obj_ver_num      in out number,
                              p_okay                 out    boolean,
                              p_msg                  out    varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'terminate_employee';
  l_ctx        varchar2(200)  := null; 

  l_pps_obj_ver_num  number;
  l_pas_obj_ver_num  number;
  l_warning_msg      varchar2(200);

  l_last_std_process_date_out    date;
  l_supervisor_warning           boolean;
  l_event_warning                boolean;
  l_interview_warning            boolean;
  l_review_warning               boolean;
  l_recruiter_warning            boolean;
  l_asg_future_changes_warning   boolean;
  l_entries_changed_warning      varchar2(200);
  l_pay_proposal_warning         boolean;
  l_dod_warning                  boolean;
  l_final_process_date           date;
  l_org_now_no_manager_warning   boolean;

begin 
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtdbg (DBG_HI, '       p_employee_number = ' || p_employee_number);
  wrtdbg (DBG_HI, '         p_emp_full_name = ' || p_emp_full_name);
  wrtdbg (DBG_HI, '  p_period_of_service_id = ' || p_period_of_service_id);
  wrtdbg (DBG_HI, '       p_pps_obj_ver_num = ' || p_pps_obj_ver_num);

  --
  -- These are in / out parameters, so they need to be initialized
  --
  l_pps_obj_ver_num := p_pps_obj_ver_num;

  p_okay := TRUE;

  begin
    l_ctx := 'hr_ex_employee_api.actual_termination_emp - p_period_of_service_id = ' ||
                   p_period_of_service_id ||  ' p_employee_number=' || p_employee_number;

    hr_ex_employee_api.actual_termination_emp (p_validate                   => g_hr_api_validate,
                                               p_effective_date             => trunc(sysdate),
                                               p_period_of_service_id       => p_period_of_service_id,
                                               p_object_version_number      => l_pps_obj_ver_num,
                                               p_actual_termination_date    => trunc(sysdate),

                                               -- all fields below this point are "out" parameters.
                                               p_last_std_process_date_out  =>  l_last_std_process_date_out,
                                               p_supervisor_warning         =>  l_supervisor_warning,
                                               p_event_warning              =>  l_event_warning,
                                               p_interview_warning          =>  l_interview_warning,
                                               p_review_warning             =>  l_review_warning,
                                               p_recruiter_warning          =>  l_recruiter_warning,
                                               p_asg_future_changes_warning =>  l_asg_future_changes_warning,
                                               p_entries_changed_warning    =>  l_entries_changed_warning,
                                               p_pay_proposal_warning       =>  l_pay_proposal_warning,
                                               p_dod_warning                =>  l_dod_warning);
  exception
    when others then
      p_okay := FALSE;
      g_warning_ct := g_warning_ct + 1;
      wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                   ' hr_ex_employee_api.actual_termination_emp had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
  end;

  if (p_okay) then
    wrtdbg(DBG_MED, '  After call to hr_ex_employee_api.actual_termination_emp:');
    wrtdbg(DBG_MED,'             l_pps_obj_ver_num = ' || l_pps_obj_ver_num);
    wrtdbg(DBG_MED,'   l_last_std_process_date_out = ' || to_char(l_last_std_process_date_out,'DD-MON-YYYY'));
    wrtdbg(DBG_MED,'          l_supervisor_warning = ' || get_vc_for_boolean (l_supervisor_warning));
    wrtdbg(DBG_MED,'               l_event_warning = ' || get_vc_for_boolean (l_event_warning));
    wrtdbg(DBG_MED,'           l_interview_warning = ' || get_vc_for_boolean (l_interview_warning));
    wrtdbg(DBG_MED,'              l_review_warning = ' || get_vc_for_boolean (l_review_warning));
    wrtdbg(DBG_MED,'           l_recruiter_warning = ' || get_vc_for_boolean (l_recruiter_warning));
    wrtdbg(DBG_MED,'  l_asg_future_changes_warning = ' || get_vc_for_boolean (l_asg_future_changes_warning));
    wrtdbg(DBG_MED,'     l_entries_changed_warning = ' || l_entries_changed_warning);
    wrtdbg(DBG_MED,'        l_pay_proposal_warning = ' || get_vc_for_boolean (l_pay_proposal_warning));
    wrtdbg(DBG_MED,'                 l_dod_warning = ' || get_vc_for_boolean (l_dod_warning));

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
    l_warning_msg := null;
    if ((l_supervisor_warning = TRUE)      or (l_event_warning = TRUE)        or (l_interview_warning = TRUE) or
        (l_review_warning = TRUE)          or (l_recruiter_warning = TRUE)    or (l_asg_future_changes_warning = TRUE) or
        (l_entries_changed_warning is not null) or (l_pay_proposal_warning = TRUE) or (l_dod_warning = TRUE)) then

      l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                       ' Terminate(1) employee warnings:';

      if (l_supervisor_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_supervisor_warning';
      end if;

      if (l_event_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_event_warning';
      end if;

      if (l_interview_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_interview_warning';
      end if;

      if (l_review_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_review_warning';
      end if;

      if (l_recruiter_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_recruiter_warning';
      end if;

      if (l_asg_future_changes_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_asg_future_changes_warning';
      end if;

      if (l_pay_proposal_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_pay_proposal_warning';
      end if;

      if (l_dod_warning = TRUE) then
        l_warning_msg := l_warning_msg || '  p_dod_warning';
      end if;

      if (l_entries_changed_warning is not null) then
        l_warning_msg := l_warning_msg || '  p_entries_changed_warning=' || l_entries_changed_warning;
      end if;

      g_warning_ct := g_warning_ct + 1;
      wrtlog (l_warning_msg);
    end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

    begin
      --
      -- These are in / out parameters, so they need to be initialized
      --
      l_final_process_date := hr_api.g_date;  -- special value for HR API's indicating no change requested


      l_ctx := 'hr_ex_employee_api.final_process_emp - p_period_of_service_id = ' ||
                     p_period_of_service_id ||  ' p_employee_number=' || p_employee_number;

      hr_ex_employee_api.final_process_emp (p_validate                   => g_hr_api_validate,
                                            p_period_of_service_id       => p_period_of_service_id,
                                            p_object_version_number      => p_pps_obj_ver_num,
                                            p_final_process_date         => l_final_process_date,

                                            -- all fields below this point are "out" parameters.
                                            p_org_now_no_manager_warning => l_org_now_no_manager_warning,
                                            p_asg_future_changes_warning => l_asg_future_changes_warning,
                                            p_entries_changed_warning    => l_entries_changed_warning);
    exception
      when others then
        p_okay := FALSE;
        g_warning_ct := g_warning_ct + 1;
        wrtlog (dti || 'W: Emp ' || p_employee_number  || ' ' || rpad(p_emp_full_name,20) ||
                     ' hr_employee_api.final_process_emp had error.  Skipping this employee.  SQLERRM=' || SQLERRM);
    end;


    if (p_okay) then
      wrtlog(dti || 'I: Emp ' || p_employee_number || ' ' || rpad(p_emp_full_name,20) ||
                    ' Terminated employee.');

      wrtdbg(DBG_MED, '  After call to hr_ex_employee_api.final_process_emp:');
      wrtdbg(DBG_MED,'             l_pps_obj_ver_num = ' || l_pps_obj_ver_num);
      wrtdbg(DBG_MED,'          l_final_process_date = ' || to_char(l_final_process_date,'DD-MON-YYYY'));
      wrtdbg(DBG_MED,'  l_org_now_no_manager_warning = ' || get_vc_for_boolean (l_org_now_no_manager_warning));
      wrtdbg(DBG_MED,'  l_asg_future_changes_warning = ' || get_vc_for_boolean (l_asg_future_changes_warning));
      wrtdbg(DBG_MED,'     l_entries_changed_warning = ' || l_entries_changed_warning);

/**************************  WE DONT CARE ABOUT THE WARNINGS **************************
      l_warning_msg := null;
      if ((l_org_now_no_manager_warning = TRUE) or (l_asg_future_changes_warning = TRUE) or
          (l_entries_changed_warning is not null)) then

        l_warning_msg := 'WARNING: Emp ' || p_employee_number  || ' ' || rpad(p_employee_number,20) ||
                         ' Terminate(2) employee warnings:';

        if (l_org_now_no_manager_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_org_now_no_manager_warning';
        end if;

        if (l_asg_future_changes_warning = TRUE) then
          l_warning_msg := l_warning_msg || '  p_asg_future_changes_warning';
        end if;

        if (l_entries_changed_warning is not null) then
          l_warning_msg := l_warning_msg || '  p_entries_changed_warning=' || l_entries_changed_warning;
        end if;

        g_warning_ct := g_warning_ct + 1;
        wrtlog (l_warning_msg);
      end if;
**************************  WE DONT CARE ABOUT THE WARNINGS **************************/

      p_pps_obj_ver_num := l_pps_obj_ver_num;

    end if;  -- if (p_okay)
  end if;  -- if (p_okay)

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end terminate_employee;
-- ============================================================================


-------------------------------------------------------------------------------   
procedure update_emp_if_needed  (p_ext_hr_rec  in  c_ext_hr_info%rowtype,
                                 p_ora_hr_rec  in  c_ora_hr_info%rowtype,
                                 p_emp_updated out boolean,
                                 p_emp_rehired out boolean,
                                 p_emp_term    out boolean,
                                 p_msg         out varchar2) is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'update_emp_if_needed';
  l_ctx        varchar2(200)  := null; 

  RANDOM_VC    constant varchar2(20) := '$7%9)1_#!@4+=;';
  RANDOM_NUM   constant number       := -1199228833774466501;

  l_upd_field_ct      number := 0;

  --
  -- HR uses the following values in update API's when there is no change to the value:
  --
  --     Data Type  API Value for no change
  --     ---------  ----------------------
  --     varchar2   hr_api.g_varchar2
  --     number     hr_api.g_number
  --     date       hr_api.g_date
  --
  l_new_first_name    per_all_people_f.first_name %type    := hr_api.g_varchar2;
  l_new_last_name     per_all_people_f.last_name %type     := hr_api.g_varchar2;
  l_new_middle_names  per_all_people_f.middle_names %type  := hr_api.g_varchar2;
  l_new_email_address per_all_people_f.email_address %type := hr_api.g_varchar2;
  l_new_mgr_emp_num   per_all_people_f.attribute2 %type    := hr_api.g_varchar2;
  l_new_party_id      per_all_people_f.party_id %type      := hr_api.g_number;

  l_new_employee_id   fnd_user.employee_id %type;

  l_ppf_obj_ver_num  number := p_ora_hr_rec.ppf_obj_ver_num;  -- updated in each time passed as a param
  l_pas_obj_ver_num  number := p_ora_hr_rec.pas_obj_ver_num;  -- updated in each time passed as a param
  l_pps_obj_ver_num  number := p_ora_hr_rec.pps_obj_ver_num;  -- updated in each time passed as a param

  l_okay       boolean := TRUE;
  l_terminated boolean := FALSE;

begin 
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  l_ctx := 'savepoint XXCRM_SAVEPOINT';
  savepoint XXCRM_SAVEPOINT;

  p_emp_updated := FALSE;
  p_emp_rehired := FALSE;
  p_emp_term    := FALSE;

  --
  -- If employee has been terminated in external system, check if they need to be terminated in Oracle.
  --
  if (nvl(p_ext_hr_rec.termination_dt, sysdate+1) <= trunc(sysdate)) then

    l_terminated := TRUE;

    if (p_ora_hr_rec.system_person_type = 'EMP') then
      wrtdbg (DBG_HI, 'Emp ' || p_ext_hr_rec.emp_id || ' terminating employee.');

      --
      -- Need to terminate this emp.
      --
      terminate_employee (p_employee_number      => p_ora_hr_rec.employee_number,
                          p_emp_full_name        => p_ora_hr_rec.full_name,
                          p_period_of_service_id => p_ora_hr_rec.period_of_service_id,
                          p_pps_obj_ver_num      => l_pps_obj_ver_num,
                          p_okay                 => l_okay,
                          p_msg                  => p_msg);

     if (p_msg is not null) then
       return;
     end if;

      if (l_okay) then
        p_emp_term := TRUE;
      end if;

    else
      wrtdbg (DBG_HI, 'Emp ' || p_ext_hr_rec.emp_id || ' already terminated.  No action taken.');
    end if;

  else
    --
    -- Employee is active in the external system.  check if they need to be rehired in Oracle
    --
    if (p_ora_hr_rec.system_person_type = 'EX_EMP') then

      re_hire_employee (p_employee_number => p_ora_hr_rec.employee_number,
                        p_emp_full_name   => p_ora_hr_rec.full_name,
                        p_person_id       => p_ora_hr_rec.person_id,
                        p_ppf_obj_ver_num => l_ppf_obj_ver_num,  -- value is updated upon return
                        p_pas_obj_ver_num => l_pas_obj_ver_num,  -- value is output upon return
                        p_okay            => l_okay,
                        p_msg             => p_msg);

      if (p_msg is not null) then
        return;
      end if;

      if (l_okay) then
        p_emp_rehired := TRUE;
      end if;
    end if;
  end if;

  if ((l_okay) and (l_terminated = FALSE)) then
    --
    -- Set the value for each field that needs to be updated.
    --
    if nvl(p_ora_hr_rec.first_name, RANDOM_VC) != nvl(p_ext_hr_rec.first_name, RANDOM_VC) then
      l_upd_field_ct   := l_upd_field_ct + 1;
      l_new_first_name := p_ext_hr_rec.first_name;
    end if;

    if nvl(p_ora_hr_rec.last_name, RANDOM_VC) != nvl(p_ext_hr_rec.last_name, RANDOM_VC) then
      l_upd_field_ct  := l_upd_field_ct + 1;
      l_new_last_name := p_ext_hr_rec.last_name;
    end if;

    if nvl(p_ora_hr_rec.middle_names, RANDOM_VC) != nvl(p_ext_hr_rec.middle_initial, RANDOM_VC) then
      l_upd_field_ct     := l_upd_field_ct + 1;
      l_new_middle_names := p_ext_hr_rec.middle_initial;
    end if;

    if nvl(p_ora_hr_rec.mgr_emp_num, RANDOM_VC) != nvl(p_ext_hr_rec.reports_to_id, RANDOM_VC) then
      l_upd_field_ct    := l_upd_field_ct + 1;
      l_new_mgr_emp_num := p_ext_hr_rec.reports_to_id;
    end if;

    if nvl(p_ora_hr_rec.ppf_email_address, RANDOM_VC) != nvl(p_ora_hr_rec.fnd_email_address, RANDOM_VC) then
      l_upd_field_ct    := l_upd_field_ct + 1;
      l_new_email_address := p_ora_hr_rec.fnd_email_address;  -- fnd_user.email_address is the master
    end if;

    if nvl(p_ora_hr_rec.party_id, RANDOM_NUM) != nvl(p_ora_hr_rec.fnd_person_party_id, RANDOM_NUM) then
      l_upd_field_ct    := l_upd_field_ct + 1;
      l_new_party_id := p_ora_hr_rec.fnd_person_party_id;  -- fnd_user.email_address is the master
    end if;

    --
    -- If at least one field needs to be updated, call the procedure.
    --
    if (l_upd_field_ct > 0) then

      update_emp (p_employee_number    => p_ora_hr_rec.employee_number,
                  p_person_id          => p_ora_hr_rec.person_id,
                  p_effective_start_dt => p_ora_hr_rec.ppf_effective_start_dt,
                  p_orig_emp_full_name => p_ora_hr_rec.full_name,
                  p_ppf_obj_ver_num    => l_ppf_obj_ver_num,  -- value is updated upon return
                  p_new_first_name     => l_new_first_name,
                  p_new_last_name      => l_new_last_name,
                  p_new_middle_names   => l_new_middle_names,
                  p_new_email_address  => l_new_email_address,
                  p_new_party_id       => l_new_party_id,
                  p_new_mgr_emp_num    => l_new_mgr_emp_num,
                  p_okay               => l_okay,
                  p_msg                => p_msg);

      if (p_msg is not null) then
        return;
      end if;

      if (l_okay) then
        p_emp_updated := TRUE;
      end if;
    end if;

    --
    -- The employees job assignment is updated using a separate API.
    -- If it changed, update it here.
    --
    if (l_okay) then
      if (nvl(p_ora_hr_rec.job_name, RANDOM_VC) != nvl(p_ext_hr_rec.oracle_job_title, RANDOM_VC)) then

        update_assignment_job (p_employee_number    => p_ora_hr_rec.employee_number,
                               p_emp_full_name      => p_ora_hr_rec.full_name,
                               p_assignment_id      => p_ora_hr_rec.assignment_id,
                               p_effective_start_dt => p_ora_hr_rec.pas_effective_start_dt,
                               p_pas_obj_ver_num    => l_pas_obj_ver_num,  -- value is updated upon return
                               p_new_job_name       => p_ext_hr_rec.oracle_job_title,
                               p_okay               => l_okay,
                               p_msg                => p_msg);

        if (p_msg is not null) then
          return;
        end if;

        if (l_okay) then
          p_emp_updated := TRUE;
        end if;
      end if;
    end if;
  
    if (l_okay) then

      if nvl(p_ora_hr_rec.person_id, RANDOM_NUM) != nvl(p_ora_hr_rec.fnd_employee_id, RANDOM_NUM) then
        l_upd_field_ct    := l_upd_field_ct + 1;
        l_new_employee_id := p_ora_hr_rec.person_id;

        update_fnd_user_info (p_employee_number => p_ora_hr_rec.employee_number,
                              p_full_name       => p_ora_hr_rec.full_name,
                              p_person_id       => l_new_employee_id,
                              p_okay            => l_okay,
                              p_msg             => p_msg);

        if (p_msg is not null) then
          return;
        end if;

        if (l_okay) then
          p_emp_updated := TRUE;
        end if;
      end if;
    end if;
  end if;  -- if ((l_okay) and (l_terminated = FALSE))

  if (l_okay = FALSE) then
    p_emp_updated := FALSE;  -- may have set this to true, then encountered a problem later on
    wrtdbg (DBG_MED, 'Rolling back to savepoint XXCRM_SAVEPOINT');
    l_ctx := 'rollback to XXCRM_SAVEPOINT';
    rollback to savepoint XXCRM_SAVEPOINT;
  end if;

  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
end update_emp_if_needed;
-- ============================================================================


-------------------------------------------------------------------------------   
function get_current_emp_info  (p_employee_number       in  varchar2,
                                p_auto_update_when_null in  varchar2,
                                p_ora_hr_rec            out c_ora_hr_info%rowtype,
                                p_msg                   out varchar2)
  return varchar2 is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'get_current_emp_info';
  l_ctx        varchar2(200)  := null; 

  l_rtn_status   varchar2(10) := NULL;
  tmp_ora_hr_rec c_ora_hr_info%rowtype;

begin 
  wrtdbg (DBG_HI, 'Enter ' || l_proc);

  p_ora_hr_rec := null;

  l_ctx := 'open c_ora_hr_info - p_employee_number=' || nvl(p_employee_number,'<null>') ||
           ' p_auto_update_when_null=' || nvl(p_auto_update_when_null,'<null>');
  open c_ora_hr_info (p_employee_number, p_auto_update_when_null);

  l_ctx := 'fetch(1) c_ora_hr_info - p_employee_number=' || p_employee_number;
  fetch c_ora_hr_info into p_ora_hr_rec;

  if (c_ora_hr_info%NOTFOUND) then
    l_rtn_status := ORA_EMP_NOT_FOUND;
  else
    l_rtn_status := ORA_EMP_FOUND;

    --
    -- A second record should never be available.  Check it here.
    --
    l_ctx := 'fetch(2) c_ora_hr_info - p_employee_number=' || p_employee_number;
    fetch c_ora_hr_info into tmp_ora_hr_rec;

    if (c_ora_hr_info%FOUND) then
      l_rtn_status := ORA_EMP_DUP;  -- override the FOUND status
    end if;
  end if;

  l_ctx := 'close c_ora_hr_info - p_employee_number=' || p_employee_number;
  close c_ora_hr_info;
  
  wrtdbg (DBG_HI, 'Exit ' || l_proc || ' l_rtn_status=' || l_rtn_status);

  return (l_rtn_status);

exception
  when others then
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;
    return ORA_EMP_NOT_FOUND;
end get_current_emp_info;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure dbg_display_ext_hr_rec (p_ext_hr_rec in c_ext_hr_info%rowtype) is
-------------------------------------------------------------------------------   

begin 

  if (g_debug_level < DBG_HI) then
    return;
  end if;

  wrtdbg (DBG_HI,'             emp.emp_id = ' || p_ext_hr_rec.emp_id);
  wrtdbg (DBG_HI,'         emp.first_name = ' || p_ext_hr_rec.first_name);
  wrtdbg (DBG_HI,'          emp.last_name = ' || p_ext_hr_rec.last_name);
  wrtdbg (DBG_HI,'     emp.middle_initial = ' || p_ext_hr_rec.middle_initial);
  wrtdbg (DBG_HI,'        emp.position_cd = ' || p_ext_hr_rec.position_cd);
  wrtdbg (DBG_HI,'             emp.loc_id = ' || p_ext_hr_rec.loc_id);
  wrtdbg (DBG_HI,'     emp.termination_dt = ' || to_char(p_ext_hr_rec.termination_dt,'DD-MON-YYYY'));
  wrtdbg (DBG_HI,'          emp.job_title = ' || p_ext_hr_rec.job_title);
  wrtdbg (DBG_HI,'          emp.phone_nbr = ' || p_ext_hr_rec.phone_nbr);
  wrtdbg (DBG_HI,'      emp.division_name = ' || p_ext_hr_rec.division_name);
  wrtdbg (DBG_HI,'          emp.dept_name = ' || p_ext_hr_rec.dept_name);
  wrtdbg (DBG_HI,'      emp.reports_to_id = ' || p_ext_hr_rec.reports_to_id);
  -- wrtdbg (DBG_HI,'                  LEVEL = ' || p_ext_hr_rec.LEVEL);
  wrtdbg (DBG_HI,'       oracle_job_title = ' || p_ext_hr_rec.oracle_job_title);
  wrtdbg (DBG_HI,'            jr.job_code = ' || p_ext_hr_rec.job_code);
  wrtdbg (DBG_HI,'      job_code_sfa_role = ' || p_ext_hr_rec.job_code_sfa_role);
  wrtdbg (DBG_HI,'      job_code_division = ' || p_ext_hr_rec.job_code_division);
  wrtdbg (DBG_HI,'  job_code_manager_flag = ' || p_ext_hr_rec.job_code_manager_flag);

end dbg_display_ext_hr_rec;
-- ============================================================================ 


-------------------------------------------------------------------------------
procedure dbg_display_ora_hr_rec (p_ora_hr_rec in c_ora_hr_info%rowtype) is
-------------------------------------------------------------------------------

begin

  if (g_debug_level < DBG_HI) then
    return;
  end if;

  wrtdbg (DBG_HI,'                  ppf.person_id = ' || p_ora_hr_rec.person_id);
  wrtdbg (DBG_HI,'            ppf.employee_number = ' || p_ora_hr_rec.employee_number);
  wrtdbg (DBG_HI,'                 ppf.first_name = ' || p_ora_hr_rec.first_name);
  wrtdbg (DBG_HI,'               ppf.middle_names = ' || p_ora_hr_rec.middle_names);
  wrtdbg (DBG_HI,'                  ppf.last_name = ' || p_ora_hr_rec.last_name);
  wrtdbg (DBG_HI,'                  ppf.full_name = ' || p_ora_hr_rec.full_name);
  wrtdbg (DBG_HI,'              ppf_email_address = ' || p_ora_hr_rec.ppf_email_address);
  wrtdbg (DBG_HI,'                   ppf.party_id = ' || p_ora_hr_rec.party_id);
  wrtdbg (DBG_HI,'   (ppf.attr1) auto_update_flag = ' || p_ora_hr_rec.auto_update_flag);
  wrtdbg (DBG_HI,'        (ppf.attr2) mgr_emp_num = ' || p_ora_hr_rec.mgr_emp_num);
  wrtdbg (DBG_HI,'                ppf_obj_ver_num = ' || p_ora_hr_rec.ppf_obj_ver_num);
  wrtdbg (DBG_HI,'             ppf.person_type_id = ' || p_ora_hr_rec.person_type_id);
  wrtdbg (DBG_HI,'         ppt.system_person_type = ' || p_ora_hr_rec.system_person_type);
  wrtdbg (DBG_HI,'              pas.assignment_id = ' || p_ora_hr_rec.assignment_id);
  wrtdbg (DBG_HI,'                pas_obj_ver_num = ' || p_ora_hr_rec.pas_obj_ver_num);
  wrtdbg (DBG_HI,'                     pas.job_id = ' || p_ora_hr_rec.job_id);
  wrtdbg (DBG_HI,'            (job.name) job_name = ' || p_ora_hr_rec.job_name);
  wrtdbg (DBG_HI,'       pps.period_of_service_id = ' || p_ora_hr_rec.period_of_service_id);
  wrtdbg (DBG_HI,'                pps_obj_ver_num = ' || p_ora_hr_rec.pps_obj_ver_num);
  wrtdbg (DBG_HI,'                    fnd_user_id = ' || p_ora_hr_rec.fnd_user_id);
  wrtdbg (DBG_HI,'                fnd_employee_id = ' || p_ora_hr_rec.fnd_employee_id);
  wrtdbg (DBG_HI,'            fnd_person_party_id = ' || p_ora_hr_rec.fnd_person_party_id);
  wrtdbg (DBG_HI,'              fnd_email_address = ' || p_ora_hr_rec.fnd_email_address);
end dbg_display_ora_hr_rec;
-- ============================================================================ 


-------------------------------------------------------------------------------
procedure update_manager_assignments (p_max_warnings          in  number,
                                      p_auto_update_when_null in  varchar2,
                                      p_process_one_emp       in  varchar2,
                                      p_msg                   out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'update_manager_assignments'; 
  l_ctx        varchar2(200)  := null; 

  l_fetch_ct       number := 0;
  l_upd_ct         number := 0;
  l_no_auto_upd_ct number:= 0;

  l_emp_pas_obj_ver_num number;
  l_okay                boolean;

  mgr_asg_rec  c_mgr_assignments %rowtype;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtlog ('.');
  wrtlog (dti || 'Start ' || l_proc || '...');

  if (c_mgr_assignments %isopen) then
    l_ctx := 'close c_mgr_assignments(2)';
    close c_mgr_assignments;
  end if;

  l_ctx := 'open c_mgr_assignments - p_process_one_emp=' || nvl(p_process_one_emp,'<null>') ||
               ' p_auto_update_when_null=' || nvl(p_auto_update_when_null,'<null>');
  open c_mgr_assignments (c_employee_number       => p_process_one_emp,
                          c_auto_update_when_null => p_auto_update_when_null);

  loop
    fetch c_mgr_assignments into mgr_asg_rec;
    exit when c_mgr_assignments %notfound;

    l_fetch_ct := l_fetch_ct + 1;

    if (mgr_asg_rec.auto_update_flag = 'Y') then 

      l_emp_pas_obj_ver_num := mgr_asg_rec.emp_pas_obj_ver_num;

      if (mgr_asg_rec.new_mgr_person_id is null) then
        g_warning_ct := g_warning_ct + 1;
        wrtlog (dti || 'W: Emp ' || mgr_asg_rec.emp_employee_number  || ' ' ||
                        rpad(mgr_asg_rec.emp_full_name,20) ||
                      ' Manager not assigned because mgr employee number ' ||
                        mgr_asg_rec.new_mgr_emp_num || ' not in HR');
      else
        update_assignment_supervisor (p_employee_number    => mgr_asg_rec.emp_employee_number,
                                      p_emp_full_name      => mgr_asg_rec.emp_full_name,
                                      p_assignment_id      => mgr_asg_rec.emp_assignment_id,
                                      p_effective_start_dt => mgr_asg_rec.emp_pas_effective_start_dt,
                                      p_pas_obj_ver_num    => l_emp_pas_obj_ver_num,  -- in/out param
                                      p_mgr_emp_num        => mgr_asg_rec.new_mgr_emp_num,
                                      p_mgr_full_name      => mgr_asg_rec.new_mgr_full_name,
                                      p_mgr_person_id      => mgr_asg_rec.new_mgr_person_id,
                                      p_okay               => l_okay,
                                      p_msg                => p_msg);
        if (p_msg is not null) then
          return;
        end if;

        if (l_okay) then
          l_upd_ct := l_upd_ct + 1;

          if (g_commit) then
            l_ctx := 'commit';
            commit;
          end if;
        end if;
      end if;

    else
      l_no_auto_upd_ct := l_no_auto_upd_ct + 1;
    end if;

    if (g_warning_ct > p_max_warnings) then
      p_msg := 'Program has exceed that maximum warnings allowed.  Terminating(2).';
      return;
    end if;
  end loop;

  wrtlog ('.');
  wrtlog ('.  ' || to_char(l_upd_ct, '999,990') || ' manager assignments were updated');
  wrtlog ('.  ' || to_char(l_no_auto_upd_ct, '999,990') || ' records skipped because auto updates not allowed');
  wrtlog ('.  ' || to_char(g_warning_ct, '999,990') || ' warnings reported');
  wrtlog ('.');

  l_ctx := 'close c_mgr_assignments';
  close c_mgr_assignments;

  wrtlog (dti || 'End ' || l_proc || '...');
  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception 
  when others then  
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;  
end update_manager_assignments;
-- ============================================================================ 


-------------------------------------------------------------------------------
procedure load_hr_data  (p_max_warnings           in  number,
                         p_auto_update_when_null  in  varchar2,
                         p_allow_missing_fnd_user in  varchar2,
                         p_process_one_emp        in  varchar2,
                         p_emp_person_type_id     in  number,
                         p_business_group_id      in  number,
                         p_msg                    out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'load_hr_data'; 
  l_ctx        varchar2(200)  := null; 

  l_fetch_ct         number := 0;
  l_ins_ct           number := 0;
  l_upd_ct           number := 0;
  l_emp_term_ct      number := 0;
  l_emp_rehire_ct    number := 0;
  l_no_auto_upd_ct   number := 0;   -- these emps are maintained manually
  l_mult_emp_ct      number := 0;   -- these emps have more than one active record in Oracle HR for emp num
  l_no_change_ct     number := 0;
  l_rtn_status       varchar2(10);

  l_emp_inserted boolean;
  l_emp_updated  boolean;
  l_emp_rehired  boolean;
  l_emp_term     boolean;

  ext_hr_rec c_ext_hr_info%rowtype;
  ora_hr_rec c_ora_hr_info%rowtype;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);
  wrtlog ('.');
  wrtlog (dti || 'Start ' || l_proc || '...');

  if (c_ext_hr_info%isopen) then
    l_ctx := 'close c_ext_hr_info(2)';
    close c_ext_hr_info;
  end if;

  l_ctx := 'open c_ext_hr_info - p_process_one_emp=' || nvl(p_process_one_emp,'<null>');
  open c_ext_hr_info (p_process_one_emp);

  loop
    l_emp_inserted := FALSE;
    l_emp_updated  := FALSE;
    l_emp_rehired  := FALSE;
    l_emp_term     := FALSE;

    fetch c_ext_hr_info into ext_hr_rec;
    exit when c_ext_hr_info%notfound;

    l_fetch_ct := l_fetch_ct + 1;

    wrtdbg (DBG_HI,' ');
    wrtdbg (DBG_MED,'c_ext_hr_info fetched emp_id=' || ext_hr_rec.emp_id);
    dbg_display_ext_hr_rec (p_ext_hr_rec => ext_hr_rec);

    l_rtn_status := get_current_emp_info (p_employee_number       => ext_hr_rec.emp_id,
                                          p_auto_update_when_null => p_auto_update_when_null,
                                          p_ora_hr_rec            => ora_hr_rec,
                                          p_msg                   => p_msg);

    wrtdbg (DBG_HI,'After get_current_emp_info l_rtn_status=' || l_rtn_status);

    if (p_msg is not null) then
      return;
    end if;

    if (l_rtn_status = ORA_EMP_NOT_FOUND) then
      insert_emp (p_ext_hr_rec             => ext_hr_rec,
                  p_emp_person_type_id     => p_emp_person_type_id,
                  p_business_group_id      => p_business_group_id,
                  p_allow_missing_fnd_user => p_allow_missing_fnd_user,
                  p_emp_inserted           => l_emp_inserted,
                  p_msg                    => p_msg);

      if (p_msg is not null) then
        return;
      end if;

      if (l_emp_inserted) then
        l_ins_ct := l_ins_ct + 1;

        if (g_commit) then
          l_ctx := 'commit';
          commit;
        end if;
      end if;

    elsif (l_rtn_status = ORA_EMP_FOUND) then
      dbg_display_ora_hr_rec (p_ora_hr_rec => ora_hr_rec);

      if (ora_hr_rec.auto_update_flag = 'Y') then
        update_emp_if_needed (p_ext_hr_rec  => ext_hr_rec,
                              p_ora_hr_rec  => ora_hr_rec,
                              p_emp_updated => l_emp_updated,
                              p_emp_rehired => l_emp_rehired,
                              p_emp_term    => l_emp_term,
                              p_msg         => p_msg);

        if (p_msg is not null) then
          return;
        end if;

        if (l_emp_updated) then l_upd_ct        := l_upd_ct + 1;        end if;
        if (l_emp_rehired) then l_emp_rehire_ct := l_emp_rehire_ct + 1; end if;
        if (l_emp_term)    then l_emp_term_ct   := l_emp_term_ct + 1;   end if;

        if (l_emp_updated = FALSE) and (l_emp_rehired = FALSE) and (l_emp_term = FALSE) then
          l_no_change_ct := l_no_change_ct + 1;
        else
          if (g_commit) then
            l_ctx := 'commit';
            commit;
          end if;
        end if;
      else
        l_no_auto_upd_ct := l_no_auto_upd_ct + 1;
      end if;

    elsif (l_rtn_status = ORA_EMP_DUP) then
        l_mult_emp_ct := l_mult_emp_ct + 1;
        g_warning_ct := g_warning_ct + 1;
        wrtlog ('W: Emp ' || ext_hr_rec.emp_id || ' ' ||
                    rpad(ext_hr_rec.last_name || ', ' || ext_hr_rec.first_name,20) ||
                  ' Not processing employee with more than one active record in Oracle HR');
    else
      p_msg := 'invalid l_rtn_status=' || nvl(l_rtn_status,'<null>') || ' for emp num ' || ext_hr_rec.emp_id;
      return;
    end if;

    if (g_warning_ct > p_max_warnings) then
      p_msg := 'Program has exceed that maximum warnings allowed.  Terminating(1).';
      return;
    end if;
  end loop;

  wrtlog ('.');
  wrtlog ('.  ' || to_char(l_fetch_ct,      '999,990') || ' records fetched from CMS HR table');
  wrtlog ('.  ' || to_char(l_ins_ct,        '999,990') || ' employee records inserted');
  wrtlog ('.  ' || to_char(l_upd_ct,        '999,990') || ' employee records updated');
  wrtlog ('.  ' || to_char(l_emp_rehire_ct, '999,990') || ' employees rehired');
  wrtlog ('.  ' || to_char(l_emp_term_ct,   '999,990') || ' employees terminated');
  wrtlog ('.  ' || to_char(l_no_change_ct,  '999,990') || ' employees had no changes');
  wrtlog ('.  ' || to_char(g_warning_ct,    '999,990') || ' warnings reported');
  wrtlog ('.  ' || to_char((l_no_auto_upd_ct + l_mult_emp_ct), '999,990') || ' records skipped');
  wrtlog ('.        ' || to_char(l_no_auto_upd_ct, '999,990') || ' records skipped because auto updates not allowed');

  wrtlog ('.        ' || to_char(l_mult_emp_ct,    '999,990') ||
                    ' records skipped because emp num has multiple active HR records');
  wrtlog ('.');

  l_ctx := 'close c_ext_hr_info';
  close c_ext_hr_info;

  wrtlog (dti || 'End ' || l_proc || '...');
  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception 
  when others then  
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;  
end load_hr_data;
-- ============================================================================ 


-------------------------------------------------------------------------------
procedure check_missing_emps (p_max_warnings       in  number,
                              p_process_one_emp    in  varchar2,
                              p_msg                out varchar2) is
-------------------------------------------------------------------------------

  l_proc       varchar2(80)   := 'check_missing_emps';
  l_ctx        varchar2(200)  := null; 

  l_fetch_ct        number := 0;

  missing_emp_rec  c_missing_emp%rowtype;

begin
  wrtdbg (DBG_MED, 'Enter ' || l_proc);

  wrtlog ('.');
  wrtlog (dti || 'Start ' || l_proc || '...');
  wrtlog (dti || 'Checking for auto-maintaned active employees in Oracle that are not in the external HR system...');

  if (c_missing_emp%isopen) then
    l_ctx := 'close c_missing_emp(2)';
    close c_missing_emp;
  end if;

  l_ctx := 'open c_missing_emp - p_process_one_emp=' || nvl(p_process_one_emp,'<null>');
  open c_missing_emp (p_process_one_emp);

  loop
    fetch c_missing_emp into missing_emp_rec;
    exit when c_missing_emp%notfound;

    l_fetch_ct := l_fetch_ct + 1;

    wrtlog (dti || '  W: Emp ' || missing_emp_rec.employee_number || ' ' || rpad(missing_emp_rec.full_name,20));

    -- we want to see all these warnings - no limit
    -- if (g_warning_ct > p_max_warnings) then
    --   p_msg := 'Program has exceed that maximum warnings allowed.  Terminating(1).';
    --   return;
    -- end if;
  end loop;

  wrtlog ('.');
  wrtlog ('.  ' || to_char(l_fetch_ct, '999,990') ||
               ' auto-maintained active employees in Oracle that are not in the external HR system were found.');
  wrtlog ('.');

  l_ctx := 'close c_missing_emp(1)';
  close c_missing_emp;

  wrtlog (dti || 'End ' || l_proc || '...');
  wrtdbg (DBG_MED, 'Exit ' || l_proc);

exception 
  when others then  
    p_msg := l_proc || ' (' || l_ctx || ') SQLERRM=' || SQLERRM;  
end check_missing_emps;
-- ============================================================================ 


-------------------------------------------------------------------------------   
procedure do_main (errbuf                    out varchar2,
                   retcode                   out number,
                   p_max_warnings            in  number    default 100,
                   p_process_emps            in  varchar2  default 'Y',
                   p_process_mgr_assignments in  varchar2  default 'Y',
                   p_check_missing_emps      in  varchar2  default 'Y',
                   p_auto_update_when_null   in  varchar2  default 'N',  -- pgm updates ppf recs w/ null attr1
                   p_allow_missing_fnd_user  in  varchar2  default 'N',
                   p_process_one_emp         in  varchar2  default null,
                   p_commit_flag             in  varchar2  default 'Y',
                   p_debug_level             in  number    default  0, 
                   p_sql_trace               in  varchar2  default 'N') is
-------------------------------------------------------------------------------   

  l_proc       varchar2(80)   := 'do_main'; 
  l_ctx        varchar2(200)  := null; 
  l_error_msg  varchar2(2000) := null; 

  l_emp_person_type_id number;
  l_business_group_id  number;

  l_msg        varchar2(500); 

  l_fnd_rtn    boolean;

begin
--  dbms_profiler.start_profiler (G_PACKAGE); -- DEBUG ONLY ////////

  wrtlog ('.');
  wrtlog (dti || 'Message types reported in the log:');
  wrtlog (dti || '    I = Informational');
  wrtlog (dti || '    W = Warning');

  wrtlog ('.');
  wrtlog (dti || 'Parameters for package ' || G_PACKAGE || ':');  
  wrtlog (dti || '                 p_max_warnings = ' || p_max_warnings);
  wrtlog (dti || '                 p_process_emps = ' || p_process_emps);
  wrtlog (dti || '      p_process_mgr_assignments = ' || p_process_mgr_assignments);
  wrtlog (dti || '           p_check_missing_emps = ' || p_check_missing_emps);
  wrtlog (dti || '        p_auto_update_when_null = ' || p_auto_update_when_null);
  wrtlog (dti || '       p_allow_missing_fnd_user = ' || p_allow_missing_fnd_user);
  wrtlog (dti || '              p_process_one_emp = ' || p_process_one_emp);
  wrtlog (dti || '                  p_commit_flag = ' || p_commit_flag);  
  wrtlog (dti || '                  p_debug_level = ' || p_debug_level);  
  wrtlog (dti || '                    p_sql_trace = ' || p_sql_trace);  
  wrtlog ('.');

  initialize (p_commit_flag        => p_commit_flag,
              p_debug_level        => p_debug_level,
              p_sql_trace          => p_sql_trace,
              p_emp_person_type_id => l_emp_person_type_id,
              p_business_group_id  => l_business_group_id,
              p_msg                => l_msg);

  wrtdbg (DBG_LOW, dti || 'Enter ' || l_proc);  

  if (p_auto_update_when_null not in ('Y', 'N') or (p_auto_update_when_null is null)) then
    l_msg := 'p_auto_update_when_null must by "Y" or "N" but it is set to "' ||
              nvl(p_auto_update_when_null,'<null>') || '".  Program terminating.';
  end if;

  if (l_msg is null) then
    if (p_process_emps = 'Y') then

      if (g_warning_ct > 0) then
        g_warning_flag := TRUE;
        g_warning_ct := 0;  -- reset the warning count
      end if;

      load_hr_data (p_max_warnings           => p_max_warnings,
                    p_auto_update_when_null  => p_auto_update_when_null,
                    p_allow_missing_fnd_user => p_allow_missing_fnd_user,
                    p_process_one_emp        => p_process_one_emp,
                    p_emp_person_type_id     => l_emp_person_type_id,
                    p_business_group_id      => l_business_group_id,
                    p_msg                    => l_msg);

      if (l_msg is null) then
        if (g_commit) then
          l_ctx := 'commit';
          commit;
        end if;
      end if;
    end if;
  end if;

  if (l_msg is null) then
    if (p_process_mgr_assignments = 'Y') then

      if (g_warning_ct > 0) then
        g_warning_flag := TRUE;
        g_warning_ct := 0;  -- reset the warning count
      end if;

      update_manager_assignments (p_max_warnings          => p_max_warnings,
                                  p_auto_update_when_null => p_auto_update_when_null,
                                  p_process_one_emp       => p_process_one_emp,
                                  p_msg                   => l_msg);
      if (l_msg is null) then
        if (g_commit) then
          l_ctx := 'commit';
          commit;
        end if;
      end if;
    end if;
  end if;

  if (l_msg is null) then
    if (p_check_missing_emps = 'Y') then

      if (g_warning_ct > 0) then
        g_warning_flag := TRUE;
        g_warning_ct := 0;  -- reset the warning count
      end if;

      check_missing_emps (p_max_warnings    => p_max_warnings,
                          p_process_one_emp => p_process_one_emp,
                          p_msg             => l_msg);
    end if;
  end if;

  if (l_msg is not null) then 
      l_error_msg := 'ERROR: ' || l_msg; 
      wrtlog (l_error_msg); 
      retcode := CONC_STATUS_ERROR; 
      errbuf  := 'Check log for Error information.'; 

      if (g_commit) then
        l_ctx := 'rollback';
        rollback;
      end if;
  else 

    if (g_warning_ct > 0) then
      g_warning_flag := TRUE;
    end if;

    --
    -- *** WE DONT WANT CONC PROGRAM EXIT STATUS TO BE "WARNING". ***
    --
    g_warning_flag := FALSE;

    if (g_warning_flag = FALSE) then 
      retcode := CONC_STATUS_OK; 
      errbuf    := null; 

    else 
      retcode := CONC_STATUS_WARNING; 
      errbuf  := 'Check log for Warning information.';
      --
      -- When the completion code is WARNING, Oracle does not populate
      -- the Completion Text in the Concurrent Requests "View Details"
      -- screen unless we call fnd_concurrent.set_completion_status.
      -- This info is accurate as of release 11.5.5.
      --
      l_fnd_rtn := fnd_concurrent.set_completion_status ('WARNING',errbuf);
    end if; 

    if (l_msg is null) and (g_commit) then
      l_ctx := 'commit';
      commit;
    end if;
  end if;

  if (p_sql_trace = 'Y') then 
    l_ctx := 'Setting SQL trace OFF';
    wrtlog (dti || 'Setting SQL trace OFF'); 

    l_ctx := 'alter session - trace off';
    execute immediate 'alter session set events ''10046 trace name context off''';
  end if; 

--  dbms_profiler.stop_profiler;  --  DEBUG ONLY  //////

  wrtdbg (DBG_LOW, dti || 'Exit ' || l_proc || ' - retocde=' || retcode || ' errbuf=' || errbuf);

exception 
  when others then 
    l_error_msg := l_proc || ': ' || l_ctx || ' - SQLERRM=' || SQLERRM; 
    raise_application_error (-20001, l_error_msg); 
end do_main;

-- ============================================================================

end xxcrm_load_emp_data;
/

show errors
