SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_QA_SC_VEN_3PA_ADT_BPEL_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_QA_SC_AUDIT_RESULT_PKG                                       |
-- | Description      : This Program will load Vendor audtit Results         |
-- |                                                                         |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 06-APR-2011 Bala               Initial draft version             |
-- +=========================================================================+
-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------
TYPE collect_plan_rec IS RECORD( data_rec QA_RESULTS_INTERFACE%ROWTYPE) ;
g_collect_plan_rec collect_plan_rec;
TYPE collection_plan_rbl IS TABLE OF collect_plan_rec;
g_collection_plan_tbl collection_plan_rbl;


PROCEDURE VENDOR_AUDIT_RESULT(p_header_rec     IN XX_QA_SC_HEADER_MATCH_REC_TYPE 
                              ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE 
                              ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE 
                              ,p_auditor_tbl   IN XX_QA_SC_AUDITORS_TBL_TYPE 
                              ,p_findings_tbl  IN XX_QA_SC_FINDINGS_TBL_TYPE 
                              ,p_violation_tbl IN XX_QA_SC_VIOLATION_TBL_TYPE  
                              ,x_return_cd     OUT VARCHAR2
                              ,x_return_msg    OUT VARCHAR2 );
                              
                            
                              
END XX_QA_SC_VEN_3PA_ADT_BPEL_PKG;
/
SHOW ERRORS PACKAGE XX_QA_SC_VEN_AUDIT_BPEL_PKG;
EXIT;

