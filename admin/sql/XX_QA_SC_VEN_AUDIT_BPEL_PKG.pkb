SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_QA_SC_VEN_AUDIT_BPEL_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_QA_SC_ADUIT_RESULT_PKG                                       |
-- | Description      : This Program will load all SC Audit data             |
-- |                    into EBIZ                                            |
-- +=========================================================================+


PROCEDURE VENDOR_AUDIT_RESULT(p_header_rec    IN header_match_rec       
                             ,p_audit_rec     IN audit_Rec_Type
                             ,p_vendor_tbl    IN vendor_tbl_Type
                             ,p_auditor_tbl   IN auditors_tbl_type
                             ,p_findings_tbl  IN findings_tbl_type
                             ,p_violation_tbl IN violation_tbl_type
                             ,x_return_cd     OUT VARCHAR2
                             ,x_return_msg    OUT VARCHAR2)
IS


-- Constant variables
lc_prcoess_status     VARCHAR2(2) := '1';
lc_org_code           VARCHAR2(10) := 'PRJ';
lc_plan_name          VARCHAR2(50) := 'OD_SC_VENDOR_AUDIT';
lc_insert_type        VARCHAR2(2) := '1';
lc_matching_elements  VARCHAR2(50) := '';
ln_vio_count          NUMBER := 0;
ln_find_count         NUMBER := 0;
ln_count              NUMBER := 0;
ln_audit_count        number := 0;
lc_vend_exists_count  NUMBER := 0;
-- ******* temporary variables for Header Record *********************
lc_message_invoke_for VARCHAR2(100);
lc_vendor_id          NUMBER; --VARCHAR2(150);
lc_vendor_name        VARCHAR2(150);
lc_msg_time           DATE;

-- *******temporary variables for Audit Record ***********************
lc_trans_status                VARCHAR2(150) ;
lc_client                      VARCHAR2(150) ;
lc_inspection_no               VARCHAR2(150) ;
lc_inspection_id               VARCHAR2(150) ;
lc_inspection_type             VARCHAR2(150) ;
lc_service_type                VARCHAR2(150) ;
lc_qa_profile                  VARCHAR2(150) ;
lc_status                      VARCHAR2(150) ;
ld_complete_by_start_date      DATE ;
ld_complete_by_end_date        DATE ;
ld_audit_schduled_date         DATE ;
ld_inspection_date             DATE ;
lc_inspection_time_in          VARCHAR2(10) ;
lc_inspection_time_out         VARCHAR2(10) ;
ld_inspection_schduled_date    DATE ;
ld_initial_inspection_date     DATE ;
lc_relationships               VARCHAR2(150) ;
ld_inspectors_schduled         VARCHAR2(150); 
lc_inspection_month            VARCHAR2(10) ;
lc_inspection_year             VARCHAR2(4) ;


-- ************temporary variables for VEMDOR Record table type**************
-- *****Not using for this release ******
lc_od_vendor_no                VARCHAR2(150); 
lc_sc_vendor                   VARCHAR2(150);
--lc_vendor_address        contact_add_Rec_Type;
--lc_vendor_contact      vend_contact_Rec_Type;
lc_entity_id                   VARCHAR2(150);
lc_od_factory_no               VARCHAR2(150);
lc_factory_name                 VARCHAR2(150);
lc_base_address                VARCHAR2(150);
lc_city                        VARCHAR2(150);
lc_state                       VARCHAR2(150);
lc_country                     VARCHAR2(150); 
--lc_factory_contacts          vend_contact_Rec_Type;
lc_factory_status              VARCHAR2(150);
lc_factory_contacts            VARCHAR2(150);
lc_invoice_no                  VARCHAR2(150);
ld_invoice_date                DATE ;
lc_invoice_amount              VARCHAR2(150);
lc_payment_method              VARCHAR2(150);
ld_payment_date                DATE;
lc_payment_amount              VARCHAR2(150);
lc_grade                       VARCHAR2(150);
lc_region                      VARCHAR2(150);
lc_sub_region                  VARCHAR2(150);
lc_ven_contact_name            VARCHAR2(150);
lc_ven_address_1               VARCHAR2(150);
lc_ven_address_2               VARCHAR2(150);
lc_ven_address_3               VARCHAR2(150);
lc_ven_address_4               VARCHAR2(150);
lc_ven_address_city            VARCHAR2(150);
lc_ven_address_state           VARCHAR2(150);
lc_ven_address_country         VARCHAR2(150);
lc_ven_contact_type            VARCHAR2(150);
lc_ven_contact_no              VARCHAR2(150);
lc_contact_address             VARCHAR2(150);
lc_contact_address_1           VARCHAR2(150);
lc_contact_address_2           VARCHAR2(150);
lc_contact_ddress_3            VARCHAR2(150);
lc_contact_address_4           VARCHAR2(150);
lc_contact_address_city        VARCHAR2(150);
lc_contact_address_state       VARCHAR2(150);
lc_contact_address_country     VARCHAR2(150);
lc_ven_contact                 VARCHAR2(150);
lc_agent                       VARCHAR2(150);
lc_rush_audit                  VARCHAR2(150); 
lc_factory_phone               VARCHAR2(150);


-- ***************temporary variables for AUDITORS Record table type ***********
-- *****Not using for this release ******
lc_od_sc_auditor_name      VARCHAR2(150) := '';
lc_od_sc_auditor_level     VARCHAR2(150):= '';  
-- temporary variables for FINDINGS Record table type
lc_question_code        VARCHAR2(150);
lc_section              VARCHAR2(150);
lc_sub_section          VARCHAR2(150); 
lc_question             VARCHAR2(150); 
lc_answer               VARCHAR2(150);
lc_nayn                 VARCHAR2(40);
lc_auditor_comments     VARCHAR2(150);
-- temporary variables for VIOLATIONS Record table type
lc_viol_code            VARCHAR2(150);
lc_viol_flag            VARCHAR2(150);
lc_viol_text            VARCHAR2(150);
lc_viol_section         VARCHAR2(150);
lc_viol_sub_section     VARCHAR2(150);
lc_viol_question        VARCHAR2(150);
lc_viol_auditor_comments VARCHAR2(150);
--lc_vio_question VARChAR2(100);
--lc_vio_anser VARCHAR2(100);
--l_data_rec g_collect_plan_rec;
--l_data_rec := g_collection_plan_tbl(g_collect_plan_rec);
lc_interface_error_status   VARCHAR2(3):= NULL;

lx_return_cd VARCHAR2(100);
lx_return_msg VARCHAR2(100);

lc_dft_vendor_id        VARCHAR2(150);
lc_dft_region           VARCHAR2(150);
lc_dft_region_sub       VARCHAR2(150);
lc_dft_service_type     VARCHAR2(150);
lc_dft_factory_id       VARCHAR2(150);
lc_dft_agent            VARCHAR2(150);
lc_dft_grade            VARCHAR2(150);
ld_dft_inspect_date     DATE;
lc_match_flag           VARCHAR2(1) := 'Y';
lc_match_msg            VARCHAR2(2500):= 'Final Data was not matched with Drfat for';
v_request_id            NUMBER;
v_user_id               NUMBER := 500904;
lc_log_msg              VARCHAR2(200);
x_proc_return_cd             VARCHAR2(100);
x_proc_return_msg            VARCHAR2(2000);

--temp_header_match_rec1   XX_QA_SC_VEN_ADT_RESULT_PKG.header_match_rec;  

BEGIN
--lc_log_msg := p_audit_rec.transmission_status + ' message Received.';
--
--Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
--                          ,p_error_message_code =>  'XX_QA_LOG_MSG'
--                          ,p_error_msg          =>   lc_log_msg);
 
 
-- temp_header_match_rec := p_header_rec;
 
XX_QA_SC_VEN_ADT_RESULT_PKG.VENDOR_AUDIT_RESULT_PUB(p_header_rec  => p_header_rec         
                                                   ,p_audit_rec   => p_audit_rec     
                                                   ,p_vendor_tbl  => p_vendor_tbl
                                                   ,p_auditor_tbl => p_auditor_tbl
                                                   ,p_findings_tbl => p_findings_tbl
                                                   ,p_violation_tbl=> p_violation_tbl 
                                                   ,x_lc_return_cd => x_proc_return_cd
                                                   ,x_lc_return_msg => x_proc_return_msg
                                                     );     



--x_return_cd := x_proc_return_cd;
x_return_cd := 'Y';
--EXCEPTION
-- WHEN OTHERS THEN
 -- x_return_cd := 'N';
 -- x_return_msg := 'Error in Executing the Audit Result Pacakge' || lc_od_sc_auditor_name || sqlerrm;
END   VENDOR_AUDIT_RESULT;                          

END XX_QA_SC_VEN_AUDIT_BPEL_PKG;
/
SHOW ERRORS PACKAGE XX_QA_SC_VEN_AUDIT_BPEL_PKG;
EXIT;