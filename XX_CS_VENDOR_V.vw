-- +================================================================================+
-- |                        Office Depot - Project Simplify                         |
-- |                                                                                |
-- +================================================================================+
-- | Name         : XX_CS_VENDOR_V.vw                                               |
-- | Rice Id      :                                                                 |
-- | Description  :                                                                 |
-- | Purpose      : Create custom view to get vendor info for all CS's LOOKUP VALUE |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version Date        Author            Remarks                                   | 
-- |======= =========== ================= ==========================================+
-- |1.0     19-AUG-2010 Bapuji Nanapaneni     Initial Version                       |
-- |2.0     04-Jun-2013 Arun Gannarapu        Modified for R12                      |
-- +================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating Custom Views ......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating View Name XX_CS_VENDOR_V .....
PROMPT

CREATE OR REPLACE VIEW 
    XX_CS_VENDOR_V AS (
        SELECT pv.vendor_id 
	     , pv.vendor_name 
	     , ppf.person_id employee_id
	     , ppf.full_name employee_name
	     , aaf.effective_start_date
	     , aaf.effective_end_date
	     , pj.name job_name
	  FROM po_vendors pv        
	     , po_vendor_sites_all pvs
	     , per_all_assignments_f aaf
	     , per_jobs pj
	     , per_all_people_f ppf
	 WHERE pv.vendor_id                = pvs.vendor_id
	   AND lpad(ass_attribute8,10,'0') = pvs.vendor_site_code_alt
	  -- AND aaf.effective_end_date     >= SYSDATE
	   AND aaf.job_id                  = pj.job_id
	 --  AND pj.name LIKE '%CUSTOMER SERVICE%'
           AND aaf.person_id = ppf.person_id);
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

--EXIT;  