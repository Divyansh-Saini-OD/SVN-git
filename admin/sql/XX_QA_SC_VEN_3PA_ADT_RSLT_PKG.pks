
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_SC_VEN_3PA_ADT_RSLT_PKG AS
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

PROCEDURE VENDOR_AUDIT_RESULT_PUB(p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                                 ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                                 ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                                 ,p_auditor_tbl   IN XX_QA_SC_AUDITORS_TBL_TYPE
                                 ,p_findings_tbl  IN XX_QA_SC_FINDINGS_TBL_TYPE
                                 ,p_violation_tbl IN XX_QA_SC_VIOLATION_TBL_TYPE 
                                 ,x_lc_return_cd     OUT VARCHAR2
                                 ,x_lc_return_msg    OUT VARCHAR2 
                               );   
                               
PROCEDURE vendor_audit_notify( p_header_rec    IN XX_QA_SC_HEADER_MATCH_REC_TYPE
                              ,p_audit_rec     IN XX_QA_SC_AUDIT_REC_TYPE
                              ,p_vendor_tbl    IN XX_QA_SC_VENDOR_TBL_TYPE
                              ,p_match_flag    IN VARCHAR2
                              ,x_errbuf      OUT NOCOPY VARCHAR2
                              ,x_retcode     OUT NOCOPY VARCHAR2
                            );   
                            
PROCEDURE audit_reprocess(  x_errbuf      OUT NOCOPY VARCHAR2
                           ,x_retcode     OUT NOCOPY NUMBER
                           ,p_trans_status    IN VARCHAR2
                           ,p_inspection_no   IN VARCHAR2
                           ,p_vendor_no       IN VARCHAR2
                           ,p_vendor_name     IN VARCHAR2
                           ,p_vendor_addr     IN VARCHAR2
                           ,p_factory_no      IN VARCHAR2
                           ,p_factory_name    IN VARCHAR2
                           ,p_factory_addr    IN VARCHAR2
                           ,p_agent           IN VARCHAR2
                           ,p_region          IN VARCHAR2
                            );                                                           
                               
END XX_QA_SC_VEN_3PA_ADT_RSLT_PKG;
/