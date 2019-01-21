-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_JTF_RESOURCE_INFO.vw                                   |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This database view returns resource and employee info.  It was created   |
-- | for the form XX_JTF_PROXY_ASSIGNMENTS.fmb.                               |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       23-SEP-2009  Phil Price         Initial version                 |
-- +==========================================================================+

create or replace view apps.xx_jtf_resource_info as
select
-- Subversion Info:
--   $HeadURL$
--       $Rev$
--      $Date$
       rsc.rowid row_id,
       rsc.resource_id,
       rsc.category,
       obj.name category_meaning,
       rsc.resource_number,
       rsc.start_date_active,
       rsc.end_date_active,
       emp.emp_start_date,
       decode(emp.emp_end_date,
                to_date('31-DEC-4712','DD-MON-YYYY'), null,
                emp.emp_end_date) emp_end_date,
       rsc.user_id,
       rsc.user_name,
       rsc.source_id,  -- for EMPLOYEE category, this is person_id
       rsc.source_name,
       rsc.source_job_id,
       rsc.source_job_title,
       rsc.source_email,
       rsc.source_phone,
       rsc.source_mgr_id,
       rsc.source_mgr_name,
       rsc.person_party_id,
       rsc.creation_date,
       rsc.created_by,
       rsc.last_update_date,
       rsc.last_updated_by,
       rsc.last_update_login
  from jtf_rs_resource_extns_vl rsc,
       jtf_objects_vl           obj,
       (select ppf.person_id,
               nvl(pps.date_start, ppf.start_date)                      emp_start_date,
               nvl(pps.actual_termination_date, ppf.effective_end_date) emp_end_date
          from per_all_people_f         ppf,
               per_periods_of_service   pps
         where ppf.person_id = pps.person_id (+)
           and trunc(sysdate) between ppf.effective_start_date and ppf.effective_end_date
           and nvl(pps.object_version_number,-1234567890)
                                        = (select nvl(max(object_version_number),-1234567890)
                                              from per_periods_of_service pps2
                                             where pps.person_id = pps2.person_id)) emp
 where rsc.category    = obj.object_code
   and (case when rsc.category = 'EMPLOYEE'
             then rsc.source_id
             else null
        end)                   = emp.person_id (+)
   and trunc(sysdate) between trunc(nvl(rsc.start_date_active, sysdate -1))
                          and trunc(nvl(rsc.end_date_active,   sysdate +1))
/


