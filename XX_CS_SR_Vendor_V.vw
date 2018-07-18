 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                                                                   |
 -- +===================================================================+
 -- | Name         :XX_CS_VENDOR_V                                      |
 -- | Description  :Agent Vendor View                                   |
 -- |                                                                   |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date        Author              Remarks                  |
 -- |=======   ==========  =============       =========================|
 -- |DRAFT 1A 24-Jun-11  Rajeswari Jagarlamudi   Initial draft version  |
 -- |         13-JUN-13  Raj                     Remove PO schema name  |
 ---|                                              for all PO tables    |
 -- +===================================================================+
 
 SET VERIFY OFF;
 WHENEVER SQLERROR CONTINUE;
 WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE FORCE VIEW "APPS"."XX_CS_VENDOR_V" ("VENDOR_ID", "VENDOR_NAME", "EMPLOYEE_ID", "EMPLOYEE_NAME", "EFFECTIVE_START_DATE", "EFFECTIVE_END_DATE", "JOB_NAME")
AS
  (SELECT pv.vendor_id ,
    pv.vendor_name ,
    ppf.person_id employee_id ,
    ppf.full_name employee_name ,
    aaf.effective_start_date ,
    aaf.effective_end_date ,
    pj.name job_name
  FROM po_vendors pv ,
    po_vendor_sites_all pvs ,
    per_all_assignments_f aaf ,
    per_jobs pj ,
    per_all_people_f ppf
  WHERE pv.vendor_id              = pvs.vendor_id
  AND lpad(ass_attribute8,10,'0') = pvs.vendor_site_code_alt
    -- AND aaf.effective_end_date     >= SYSDATE
  AND aaf.job_id = pj.job_id
    --  AND pj.name LIKE '%CUSTOMER SERVICE%'
  AND aaf.person_id = ppf.person_id
  ) ;

SHOW ERRORS;