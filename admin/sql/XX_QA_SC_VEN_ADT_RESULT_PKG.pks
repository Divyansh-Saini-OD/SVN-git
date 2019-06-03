
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace
PACKAGE XX_QA_SC_VEN_ADT_RESULT_PKG AS
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
TYPE header_match_rec IS RECORD (
      message_invoke_for          VARCHAR2(150) 
    , vendor_id                   NUMBER 
    , vendor_name                 VARCHAR2(150) 
    , msg_date_time               DATE 
    );
g_header_match_rec header_match_rec;
---------------------------------------------------------------
-- CONTACT PHONE RECORD
-----------------------------------------------------------------
TYPE contact_phone_Rec_Type IS RECORD (
      contact_type       VARCHAR2(1000)
    , contact_no         VARCHAR2(150)
    );
G_contact_phone_Rec  contact_phone_Rec_Type;    
---------------------------------------------------------------
-- VEND CONTACT RECORD
-----------------------------------------------------------------
TYPE vend_contact_Rec_Type IS RECORD (
      contact_name          VARCHAR2(1000)
    , address_1             VARCHAR2(500)
    , address_2             VARCHAR2(500)
    , address_3             VARCHAR2(500)
    , address_4             VARCHAR2(500)
    , address_city          VARCHAR2(250)
    , address_state         VARCHAR2(250)
    , address_country       VARCHAR2(250)
    , contact_phone         contact_phone_Rec_Type
    );    
/* Tender Global Record Declaration */
G_vend_contact_Rec  vend_contact_Rec_Type;
---------------------------------------------------------------
-- CONTACT ADDRESS RECORD
-----------------------------------------------------------------
TYPE contact_add_Rec_Type IS RECORD (
      address_1             VARCHAR2(500)
    , address_2             VARCHAR2(500)
    , address_3             VARCHAR2(500)
    , address_4             VARCHAR2(500)
    , address_city          VARCHAR2(500)
    , address_state         VARCHAR2(500)
    , address_country       VARCHAR2(500)
    );    
G_contact_add_Rec  contact_add_Rec_Type;
-----------------------------------------------------------------
-- VENDOR RECORD
-----------------------------------------------------------------
TYPE vendor_Rec_Type IS RECORD (
      od_vendor_no            VARCHAR2(150) 
    , vendor                  VARCHAR2(1000)
    , vendor_address          contact_add_Rec_Type  -- VARCHAR2(2000) 
    , vendor_contact          vend_contact_Rec_Type -- VARCHAR2(2000) 
    , entity_id               VARCHAR2(150)
    , od_factory_no           VARCHAR2(150)
    , base_address            VARCHAR2(1000)
    , city                    VARCHAR2(150)
    , state                   VARCHAR2(150)
    , country                 VARCHAR2(150)
    , factory_contacts        vend_contact_Rec_Type -- VARCHAR2(2000)  
    , factory_status          VARCHAR2(150)
    , invoice_no              VARCHAR2(150)
    , invoice_date            DATE 
    , invoice_amount          VARCHAR2(150)
    , payment_method          VARCHAR2(150)
    , payment_date            DATE
    , payment_amount          VARCHAR2(150)
    , grade                   VARCHAR2(150)
    , region                  VARCHAR2(150)
    , sub_region              VARCHAR2(150)
    , vendor_attribute1       VARCHAR2(150)
    , vendor_attribute2       VARCHAR2(150)
    , vendor_attribute3       VARCHAR2(150)
    , vendor_attribute4       VARCHAR2(150)
    , vendor_attribute5       VARCHAR2(150)
    );
/* Global Record Declaration for  Line */
G_vendor_Rec vendor_Rec_Type;
TYPE vendor_tbl_Type IS TABLE OF vendor_Rec_Type ;
-----------------------------------------------------------------
-- AUDITORS ADJUSTMENTS RECORD
-----------------------------------------------------------------
TYPE auditors_Rec_Type IS RECORD (
      od_sc_auditor_name      VARCHAR2(1000)
    , od_sc_auditor_level     VARCHAR2(150) 
    , auditor_attribute1         VARCHAR2(150)
    , auditor_attribute2         VARCHAR2(150)
    , auditor_attribute3         VARCHAR2(150)
    , auditor_attribute4         VARCHAR2(150)
    , auditor_attribute5         VARCHAR2(150)
    );
/* Global Record Declaration   Line Adjustments*/
G_auditors_Rec  auditors_Rec_Type;
TYPE auditors_tbl_type     IS TABLE OF auditors_Rec_Type;  
-----------------------------------------------------------------
-- FINDINGS RECORD
-----------------------------------------------------------------
TYPE findings_Rec_Type IS RECORD (
      question_code       VARCHAR2(1000) 
    , section             VARCHAR2(1000)
    , sub_section         VARCHAR2(1000) 
    , question            VARCHAR2(1000) 
    , answer               VARCHAR2(1000)
    , nayn                 VARCHAR2(10)
    , auditor_comments     VARCHAR2(2000) --CLOB
    , find_attribute1      VARCHAR2(150)
    , find_attribute2      VARCHAR2(150)
    , find_attribute3      VARCHAR2(150)
    , find_attribute4      VARCHAR2(150)
    , find_attribute5      VARCHAR2(150)
    );
/* Payment Global Record Declaration */
G_findings_rec  findings_Rec_Type;
TYPE findings_tbl_type     IS TABLE OF findings_Rec_Type;  
gc_findings_tbl findings_tbl_type;
-----------------------------------------------------------------
-- VIOLATION RECORD
-----------------------------------------------------------------
TYPE violation_Rec_Type IS RECORD (
     viol_code                 VARCHAR2(1000)
   , viol_flag                 VARCHAR2(150)
   , viol_text                  VARCHAR2(1000)
   , viol_section               VARCHAR2(1000)
   , viol_sub_section           VARCHAR2(1000)
   , viol_question              VARCHAR2(1000)
   , viol_auditor_comments      VARCHAR2(2050) -- CLOB
  , viol_attribute1            VARCHAR2(150)
   , viol_attribute2            VARCHAR2(150)
   , viol_attribute3            VARCHAR2(150)
   , viol_attribute4            VARCHAR2(150)
   , viol_attribute5            VARCHAR2(150)
    );
/* Tender Global Record Declaration */
G_violation_Rec  violation_Rec_Type;
TYPE violation_tbl_type     IS TABLE OF violation_Rec_Type;  
gc_violation_tbl violation_tbl_type;
/* Record Type Declaration */
--TYPE order_tbl_type IS TABLE OF order_rec_type INDEX BY BINARY_INTEGER;
-----------------------------------------------------------------
-- AUDIT RECORD
-----------------------------------------------------------------
TYPE audit_Rec_Type IS RECORD (
      transmission_status         VARCHAR2(150) 
    , client                      VARCHAR2(150) 
    , inspection_no               VARCHAR2(150) 
    , inspection_id               VARCHAR2(250) 
    , inspection_type             VARCHAR2(150) 
    , service_type                VARCHAR2(150) 
    , qa_profile                  VARCHAR2(150) 
    , status                      VARCHAR2(150) 
    , complete_by_start_date      DATE 
    , complete_by_end_date        DATE 
    , audit_schduled_date         DATE 
    , inspection_date             DATE 
    , inspection_time_in          VARCHAR2(150) 
    , inspection_time_out         VARCHAR2(150) 
    , inspection_schduled_date    DATE 
    , initial_inspection_date     DATE 
    , relationships               VARCHAR2(150) 
    , inspectors_schduled         VARCHAR2(10) --DATE 
    , inspection_month            VARCHAR2(10) 
    , inspection_year             VARCHAR2(10) 
    , insert_line_id              NUMBER
    , attribute1                  VARCHAR2(150)
    , attribute2                  VARCHAR2(150)
    , attribute3                  VARCHAR2(150)
    , attribute4                  VARCHAR2(150)
    , attribute5                  VARCHAR2(150)
    );
/* Global Record  Declaration for Header */
G_audit_rec  audit_Rec_Type;
TYPE audit_tbl_type     IS TABLE OF audit_Rec_Type;  
--header_match_rec1 XX_QA_SC_VEN_AUDIT_BPEL_PKG.header_match_rec;
--header_match_rec2 header_match_rec1%TYPE;
--header_match_rec2 header_match_rec1;
PROCEDURE VENDOR_AUDIT_RESULT_PUB(p_header_rec    IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.header_match_rec
                                 ,p_audit_rec     IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.audit_Rec_Type
                                 ,p_vendor_tbl    IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.vendor_tbl_Type
                                 ,p_auditor_tbl   IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.auditors_tbl_type
                                 ,p_findings_tbl  IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.findings_tbl_type
                                 ,p_violation_tbl IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.violation_tbl_type 
                                ,x_lc_return_cd     OUT VARCHAR2
                                ,x_lc_return_msg    OUT VARCHAR2 
                               );   
END XX_QA_SC_VEN_ADT_RESULT_PKG;
/
SHOW ERRORS PACKAGE XX_OM_HVOP_ERROR_PROCESS;
EXIT;


