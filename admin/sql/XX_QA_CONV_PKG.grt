REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : XX_QA_CONV_PKG.grt                                                         |--
--|                                                                                             |--
--| Purpose        : Create Grant Privilegs                                                     |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              21-Jun-2010       Paddy Sanjeevi          Original                         |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating the Custom Table ......
PROMPT

grant all on APPS.XX_QA_HIS_PLAN_PKG to u510093,u499103;

grant all on APPS.XX_QA_MAIN_PLAN_PKG to u510093,u499103;

grant all on APPS.XX_QA_CONV_PKG to u510093,u499103;

grant all on qa.qa_results_interface to u510093,u499103;

grant select on qa.qa_plans to u510093,u499103;

grant select on qa.qa_results to u510093,u499103;

GRANT SELECT ON QA.QA_INTERFACE_ERRORS TO u510093,u499103;

grant select on apps.fnd_documents to u510093, u499103;

grant select on apps.fnd_documents_tl TO u510093,u499103;

grant select on apps.fnd_document_datatypes TO u510093,u499103;

grant select on apps.FND_ATTACHED_DOCUMENTS TO u510093,u499103;

grant select on apps.Q_OD_PB_APPROVAL_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_APPROVAL_PLAN_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ATS_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CA_REQUEST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CA_REQUEST_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ECR_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ECR_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FAILURE_CODES_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_ODC_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_RTLF_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_US_IV to u510093,u499103;

grant select on apps.Q_OD_PB_MONTHLY_CAR_SUMMARY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_MONTHLY_DEFECT_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PPT_CAP_APPROVAL_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PRE_PURCHASE_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PRE_PURCHASE_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PROTOCOL_REVIEW_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PSI_IC_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PSI_IC_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_QA_REPORTING_IV to u510093,u499103;

grant select on apps.Q_OD_PB_QUALITY_INVOICES_IV to u510093,u499103;

grant select on apps.Q_OD_PB_REGULATORY_CERT_IV to u510093,u499103;

grant select on apps.Q_OD_PB_REG_FEES_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TESTING_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TESTING_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TEST_DETAILS_IV to u510093,u499103;

grant select on apps.Q_OD_PB_WITHDRAW_IV to u510093,u499103;

grant select on apps.Q_OD_PB_WITHDRAW_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_APPROVAL_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_APPROVAL_PLAN_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ATS_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CA_REQUEST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CA_REQUEST_HISTORY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ECR_IV to u510093,u499103;

grant select on apps.Q_OD_PB_ECR_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FAILURE_CODES_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_ODC_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_RTLF_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FQA_US_IV to u510093,u499103;

grant select on apps.Q_OD_PB_MONTHLY_CAR_SUMMARY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_MONTHLY_DEFECT_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PPT_CAP_APPROVAL_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PRE_PURCHASE_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PRE_PURCHASE_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PROTOCOL_REVIEW_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PSI_IC_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PSI_IC_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_QA_REPORTING_IV to u510093,u499103;

grant select on apps.Q_OD_PB_QUALITY_INVOICES_IV to u510093,u499103;

grant select on apps.Q_OD_PB_REGULATORY_CERT_IV to u510093,u499103;

grant select on apps.Q_OD_PB_REG_FEES_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TESTING_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TESTING_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TEST_DETAILS_IV to u510093,u499103;

grant select on apps.Q_OD_PB_WITHDRAW_IV to u510093,u499103;

grant select on apps.Q_OD_PB_WITHDRAW_HIST_IV to u510093,u499103;

grant select on apps.FND_DOCUMENTS_SHORT_TEXT to u510093,u499103;

grant select on apps.fnd_attached_docs_form_vl to u510093,u499103;






grant select on apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V to u510093,u499103;

grant select on apps.Q_OD_PB_AUTHORIZATIONTO_SHI_IV to u510093,u499103;

grant select on apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V to u510093,u499103;

grant select on apps.Q_OD_PB_AUTHORIZATION_TO_SH_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMERCOMPLAINTS__IV to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V to u510093,u499103;

grant select on apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V to u510093,u499103;

grant select on apps.Q_OD_PB_FIRST_ARTICLE_HISTO_IV to u510093,u499103;

grant select on apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V to u510093,u499103;

grant select on apps.Q_OD_PB_FIRST_ARTICLE_INSPE_IV to u510093,u499103;

grant select on apps.Q_OD_PB_INSPECTION_ACTIVITY_V to u510093,u499103;

grant select on apps.Q_OD_PB_INSPECTION_ACTIVITY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_INSPECTION_ACTIVITY__V to u510093,u499103;

grant select on apps.Q_OD_PB_INSPECTION_ACTIVITY_IV to u510093,u499103;

grant select on apps.Q_OD_PB_INVOICE_LICENSE_HIST_V to u510093,u499103;

grant select on apps.Q_OD_PB_INVOICE_LICENSE_HIS_IV to u510093,u499103;

grant select on apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V to u510093,u499103;

grant select on apps.Q_OD_PB_IN_HOUSE_ARTWORK_RE_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PROCEDURES_LOG_HISTO_V to u510093,u499103;

grant select on apps.Q_OD_PB_PROCEDURES_LOG_HIST_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PROCEDURES_LOG_V to u510093,u499103;

grant select on apps.Q_OD_PB_PROCEDURES_LOG_IV to u510093,u499103;

grant select on apps.Q_OD_PB_RETURNED_GOODS_ANALY_V to u510093,u499103;

grant select on apps.Q_OD_PB_RETURNED_GOODS_ANAL_IV to u510093,u499103;

grant select on apps.Q_OD_PB_SERVICE_PROV_SCORECA_V to u510093,u499103;

grant select on apps.Q_OD_PB_SERVICE_PROV_SCOREC_IV to u510093,u499103;

grant select on apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V to u510093,u499103;

grant select on apps.Q_OD_PB_SPEC_APPROVAL_HISTO_IV to u510093,u499103;

grant select on apps.Q_OD_PB_SPEC_APPROVAL_V to u510093,u499103;

grant select on apps.Q_OD_PB_SPEC_APPROVAL_IV to u510093,u499103;

grant select on apps.Q_OD_PB_PROB_TERM_FACTORY_LI_V to u510093,u499103;

grant select on apps.Q_OD_PB_PROB_TERM_FACTORY_L_IV to u510093,u499103;

grant select on apps.Q_OD_PB_TERMINATED_FACTORY_H_V to u510093,u499103;

grant select on apps.Q_OD_PB_TERMINATED_FACTORY__IV to u510093,u499103;
