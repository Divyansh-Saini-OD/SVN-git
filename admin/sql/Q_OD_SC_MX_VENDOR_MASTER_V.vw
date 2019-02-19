CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."Q_OD_SC_MX_VENDOR_MASTER_V" ("ROW_ID", "PLAN_ID", "PLAN_NAME", "ORGANIZATION_ID", "ORGANIZATION_NAME", "COLLECTION_ID", "OCCURRENCE", "LAST_UPDATE_DATE", "LAST_UPDATED_BY_ID", "LAST_UPDATED_BY", "CREATION_DATE", "CREATED_BY_ID", "CREATED_BY", "LAST_UPDATE_LOGIN", "OD_SC_VENDOR_NUMBER", "OD_SC_VENDOR_NAME", "OD_SC_VEND_TYPE", "OD_SC_VENDOR_STATUS", "OD_SC_ACTIVATION_DATE", "OD_SC_INACTIVE_DATE", "OD_SC_REACTIVATE_DATE", "OD_SC_DOC_VAL_DATE", "OD_SC_FQA_APRVL_D", "OD_SC_AUDIT_AGENT", "OD_SC_VEND_CONT_NAME", "OD_SC_VEND_PHONE", "OD_SC_VEND_FAX", "OD_SC_VEND_EMAIL", "OD_SC_VEND_ADDRESS", "OD_SC_FACTORY_NUMBER", "OD_SC_FACTORY_NAME", "OD_SC_FACT_CONT_NAME", "OD_SC_FACTORY_EMAIL", "OD_SC_FACTORY_ADDRESS", "OD_SC_FACTORY_PHONE", "OD_SC_FACTORY_FAX", " OD_SC_EUROPE_RGN", "OD_SC_EU_SUB_RGN", "OD_SC_EU_VEND_NO", "OD_SC_EU_FACTORY_NO", "OD_SC_EU_VEND_STATUS" , "OD_SC_EU_CONTACT", "OD_SC_MEXICO_REGION", "OD_SC_MX_SUB_RGN", "OD_SC_MX_VEND_NO",
  "OD_SC_MEX_FACTORY_NO", "OD_SC_MX_VEND_STATUS", "OD_SC_MX_CONTACT", "OD_SC_ASIA_REGION", "OD_SC_AS_SUB_RGN", "OD_SC_AS_VEND_NO", "OD_SC_ASIA_FACTORY_NO", "OD_SC_AS_VEND_STATUS", "OD_SC_ASIA_CONTACT", "OD_SC_DEPARTMENT", "OD_SC_PRODUCT", "OD_SC_MERCHANT", "OD_SC_AUDIT_REQUIRED", "OD_SC_AUDIT_WAIVER", "OD_SC_AUDIT_WAIVER_STATUS", " OD_SC_AUDTWAIV_APR_D", "OD_SC_VEND_REGION", "OD_SC_VEND_COMMENTS", "OD_SC_CNT_OF_ORGN", "OD_SC_CNT_OF_DESTN", "OD_SC_CIP", "OD_SC_POTRM_APR_D", "OD_SC_FOB_VALUE", "OD_SC_LEAD_AUDITOR", "OD_SC_AUDITOR", "OD_SC_PREAUDT_SCHED_D", "OD_SC_PREAUDT_RESULT", "OD_SC_ZT_STATUS", "OD_SC_ZT_APRVL_D", "OD_SC_ZT_APPROVER", " OD_SC_FZT_APPROVER", "OD_SC_FZT_APRVL_D", "OD_SC_PREAUDIT_COMMENTS", "OD_SC_STRAUDT_REQ_D", "OD_SC_PAYMENT_RETAINER", "OD_SC_STR_PAYMENT_APPROVER", "OD_PB_PAYRTN_APRVL_DATE", "OD_SC_VENDPAY_RCVD_D", "OD_SC_STRAUDT_SCHD_D", "OD_SC_REQ_AUDIT_DATE", "OD_SC_STR_AUDIT_RESULT", "OD_SC_CAP_ASSIGNMENT", "OD_SC_CAP_SENT_D", "OD_SC_CAP_RECD_D",
  "OD_SC_STRAUDT_CAP_STATUS", "OD_SC_CAP_RESP_D", "OD_SC_CAP_REV_COMMENTS", "OD_SC_CAP_PREAPPROVER", "OD_SC_STRAUDT_GSO_APR_D", "OD_SC_CAP_FINAL_APPROVER", "OD_SC_SRTAUDT_US_APR_D", "OD_SC_VEND_INITIATE", "OD_SC_INITSTR_NOTIFY", "OD_SC_VENDPAY_NOTIFY", "OD_SC_REGRUSH_NOTIFY", "OD_SC_AUDRESZT_NOTIFY", "OD_SC_RECAUDIT_NOTIFY", "OD_SC_CAP_NOTIFY", "OD_SC_VENDSK_NOTIFY", "OD_SC_NB_NOTIFY", "OD_SC_VENDOR_TAX_ID", "OD_SC_CIP_ACTIVE_DATE", "OD_SC_CIP_DEACTIVE_DATE", "OD_SC_INSPECTION_TYPE", "OD_SC_PROJ_NUM", "OD_SC_PROJ_STATUS", "OD_SC_VEND_DESK_REQ_DATE", "OD_SC_SHARED_FACTORY", "OD_SC_PENDING_STATUS_CHANGE", "OD_SC_SUB_CAT_PROD_CLASS_CODE", "OD_SC_DOCUMENT_COMMENTS", "OD_SC_AUDIT_STATUS_NOTIFY", "TRANSACTION_NUMBER")
AS
  SELECT
    /*+ LEADING(qp) USE_NL(qp qr) push_pred(PH)
    USE_NL(PH PR)*/
    qr.rowid row_id,
    qr.plan_id,
    qp.name plan_name,
    qr.organization_id,
    hou.name organization_name,
    qr.collection_id,
    qr.occurrence,
    qr.qa_last_update_date last_update_date,
    qr.qa_last_updated_by last_updated_by_id,
    fu2.user_name last_updated_by,
    qr.qa_creation_date creation_date,
    qr.qa_created_by created_by_id,
    fu.user_name created_by,
    qr.last_update_login,
    qr.CHARACTER1 "OD_SC_VENDOR_NUMBER",
    qr.CHARACTER2 "OD_SC_VENDOR_NAME",
    qr.CHARACTER3 "OD_SC_VEND_TYPE",
    qr.CHARACTER4 "OD_SC_VENDOR_STATUS",
    to_date(qr.CHARACTER5, 'YYYY/MM/DD') "OD_SC_ACTIVATION_DATE",
    to_date(qr.CHARACTER6, 'YYYY/MM/DD') "OD_SC_INACTIVE_DATE",
    to_date(qr.CHARACTER7, 'YYYY/MM/DD') "OD_SC_REACTIVATE_DATE",
    to_date(qr.CHARACTER8, 'YYYY/MM/DD') "OD_SC_DOC_VAL_DATE",
    TO_date(qr.CHARACTER9, 'YYYY/MM/DD') "OD_SC_FQA_APRVL_D",
    qr.CHARACTER10 "OD_SC_AUDIT_AGENT",
    qr.CHARACTER11 "OD_SC_VEND_CONT_NAME",
    qr.CHARACTER12 "OD_SC_VEND_PHONE",
    qr.CHARACTER13 "OD_SC_VEND_FAX",
    qr.CHARACTER14 "OD_SC_VEND_EMAIL",
    qr.CHARACTER15 "OD_SC_VEND_ADDRESS",
    qr.CHARACTER16 "OD_SC_FACTORY_NUMBER",
    qr.CHARACTER17 "OD_SC_FACTORY_NAME",
    qr.CHARACTER18 "OD_SC_FACT_CONT_NAME",
    qr.CHARACTER19 "OD_SC_FACTORY_EMAIL",
    qr.CHARACTER20 "OD_SC_FACTORY_ADDRESS",
    qr.CHARACTER21 "OD_SC_FACTORY_PHONE",
    qr.CHARACTER22 "OD_SC_FACTORY_FAX",
    qr.CHARACTER23 "OD_SC_EUROPE_RGN",
    qr.CHARACTER24 "OD_SC_EU_SUB_RGN",
    qr.CHARACTER25 " OD_SC_EU_VEND_NO",
    qr.CHARACTER26 "OD_SC_EU_FACTORY_NO",
    qr.CHARACTER27 "OD_SC_EU_VEND_STATUS",
    qr.CHARACTER28 "OD_SC_EU_CONTACT",
    qr.CHARACTER29 "OD_SC_MEXICO_REGION",
    qr.CHARACTER30 "OD_SC_MX_SUB_RGN",
    qr.CHARACTER31 "OD_SC_MX_VEND_NO",
    qr.CHARACTER32 "OD_SC_MEX_FACTORY_NO",
    qr.CHARACTER33 "OD_SC_MX_VEND_STATUS",
    qr.CHARACTER34 "OD_SC_MX_CONTACT",
    qr.CHARACTER35 "OD_SC_ASIA_REGION",
    qr.CHARACTER36 "OD_SC_AS_SUB_RGN",
    qr.CHARACTER37 "OD_SC_AS_VEND_NO",
    qr.CHARACTER38 "OD_SC_ASIA_FACTORY_NO",
    qr.CHARACTER39 "OD_SC_AS_VEND_STATUS",
    qr.CHARACTER40 "OD_SC_ASIA_CONTACT" ,
    qr.CHARACTER41 "OD_SC_DEPARTMENT",
    qr.CHARACTER42 "OD_SC_PRODUCT",
    qr.CHARACTER43 "OD_SC_MERCHANT",
    qr.CHARACTER44 "OD_SC_AUDIT_REQUIRED",
    qr.CHARACTER45 "OD_SC_AUDIT_WAIVER",
    qr.CHARACTER46 "OD_SC_AUDIT_WAIVER_STATUS",
    to_date(qr.CHARACTER47, 'YYYY/MM/DD') "OD_SC_AUDTWAIV_APR_D",
    qr.CHARACTER48 "OD_SC_VEND_REGION",
    qr.COMMENT1 "OD_SC_VEND_COMMENTS",
    qr.CHARACTER49 "OD_SC_CNT_OF_ORGN",
    qr.CHARACTER50 "OD_SC_CNT_OF_DESTN",
    qr.CHARACTER51 "OD_SC_CIP",
    to_date(qr.CHARACTER52, 'YYYY/MM/DD') "OD_SC_POTRM_APR_D",
    qltdate.any_to_number(qr.CHARACTER53) "OD_SC_FOB_VALUE",
    qr.CHARACTER54 "OD_SC_LEAD_AUDITOR",
    qr.CHARACTER55 "OD_SC_AUDITOR",
    to_date(qr.CHARACTER56, 'YYYY/MM/DD') "OD_SC_PREAUDT_SCHED_D",
    qr.CHARACTER57 "OD_SC_PREAUDT_RESULT",
    qr.CHARACTER58 "OD_SC_ZT_STATUS",
    to_DATE(qr.CHARACTER59, 'YYYY/MM/DD') "OD_SC_ZT_APRVL_D",
    qr.CHARACTER60 "OD_SC_ZT_APPROVER",
    qr.CHARACTER61 "OD_SC_FZT_APPROVER",
    to_date(qr.CHARACTER62, 'YYYY/MM/DD') "OD_SC_FZT_APRVL_D",
    qr.COMMENT2 "OD_SC_PREAUDIT_COMMENTS",
    to_date(qr.CHARACTER63, 'YYYY/MM/DD') "OD_SC_STRAUDT_REQ_D",
    qr.CHARACTER64 "OD_SC_PAYMENT_RETAINER",
    qr.CHARACTER65 "OD_SC_STR_PAYMENT_APPROVER",
    to_date(qr.CHARACTER66, 'YYYY/MM/DD') "OD_PB_PAYRTN_APRVL_DATE",
    to_date(qr.CHARACTER67, 'YYYY/MM/DD') "OD_SC_VENDPAY_RCVD_D",
    to_date(qr.CHARACTER68, 'YYYY/MM/DD') "OD_SC_STRAUDT_SCHD_D",
    to_date(qr.CHARACTER69, 'YYYY/MM/DD') "OD_SC_REQ_AUDIT_DATE",
    qr.CHARACTER70 "OD_SC_STR_AUDIT_RESULT",
    qr.CHARACTER71 "OD_SC_CAP_ASSIGNMENT",
    to_date(qr.CHARACTER72, 'YYYY/MM/DD') "OD_SC_CAP_SENT_D",
    to_date(qr.CHARACTER73, 'YYYY/MM/DD') "OD_SC_CAP_RECD_D",
    qr.CHARACTER74 "OD_SC_STRAUDT_CAP_STATUS",
    to_date(qr.CHARACTER75, 'YYYY/MM/DD') "OD_SC_CAP_RESP_D",
    qr.COMMENT3 "OD_SC_CAP_REV_COMMENTS",
    qr.CHARACTER76 "OD_SC_CAP_PREAPPROVER",
    to_date(qr.CHARACTER77, 'YYYY/MM/DD') "OD_SC_STRAUDT_GSO_APR_D",
    qr.CHARACTER78 "OD_SC_CAP_FINAL_APPROVER",
    to_date(qr.CHARACTER79, 'YYYY/MM/DD') "OD_SC_SRTAUDT_US_APR_D",
    qr.CHARACTER80 "OD_SC_VEND_INITIATE",
    qr.CHARACTER81 "OD_SC_INITSTR_NOTIFY",
    qr.CHARACTER82 "OD_SC_VENDPAY_NOTIFY",
    qr.CHARACTER83 "OD_SC_REGRUSH_NOTIFY",
    qr.CHARACTER84 "OD_SC_AUDRESZT_NOTIFY",
    qr.CHARACTER85 "OD_SC_RECAUDIT_NOTIFY" ,
    qr.CHARACTER86 "OD_SC_CAP_NOTIFY",
    qr.CHARACTER87 "OD_SC_VENDSK_NOTIFY",
    qr.CHARACTER88 "OD_SC_NB_NOTIFY",
    qr.CHARACTER89 "OD_SC_VENDOR_TAX_ID",
    to_date(qr.CHARACTER90, 'YYYY/MM/DD') "OD_SC_CIP_ACTIVE_DATE" ,
    to_date(qr.CHARACTER91, 'YYYY/MM/DD') "OD_SC_CIP_DEACTIVE_DATE",
    qr.CHARACTER92 "OD_SC_INSPECTION_TYPE",
    qr.CHARACTER93 "OD_SC_PROJ_NUM",
    qr.CHARACTER94 " OD_SC_PROJ_STATUS",
    to_date(qr.CHARACTER95, 'YYYY/MM/DD') "OD_SC_VEND_DESK_REQ_DATE",
    qr.CHARACTER96 "OD_SC_SHARED_FACTORY",
    qr.CHARACTER97 "OD_SC_PENDING_STATUS_CHANGE",
    qr.CHARACTER98 "OD_SC_SUB_CAT_PROD_CLASS_CODE",
    QR.COMMENT4 "OD_SC_DOCUMENT_COMMENTS",
    QR.CHARACTER99 "OD_SC_AUDIT_STATUS_NOTIFY",
    QR.TRANSACTION_NUMBER "TRANSACTION_NUMBER"
  FROM qa_results qr,
    qa_plans qp,
    fnd_user_view fu,
    fnd_user_view fu2,
    hr_organization_units hou
  WHERE qp.plan_id          = 424
  AND qr.plan_id            = 424
  AND qp.plan_id            = qr.plan_id
  AND qr.qa_created_by      = fu.user_id
  AND qr.qa_last_updated_by = fu2.user_id
  AND QR.ORGANIZATION_ID    = HOU.ORGANIZATION_ID
  AND (Qr.status           IS NULL
  OR qr.status              = 2);
/