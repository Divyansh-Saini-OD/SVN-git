-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | NAME        : XX_AP_AE_LINES_ALL_V_xxapps_history_query.vw               |
-- | RICE#       : R0527  OD: GL Account Analysis Subledger Detail (Excel)    |                                          
-- | DESCRIPTION : Create the view of ap_ae_lines_all to support the          |
-- |               use of rowid in the report while using archive             |
-- |               responsibilities archiving                                 |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     26-SEP-2012  Adithya	            Initial version-defect#19822  |
-- |                                                                          |
-- +==========================================================================+

CREATE OR REPLACE FORCE VIEW XXAPPS_HISTORY_QUERY.XX_AP_AE_LINES_ALL_V
  (ROW_ID
  ,AE_LINE_ID
  ,AE_HEADER_ID
  ,AE_LINE_NUMBER
  ,AE_LINE_TYPE_CODE
  ,CODE_COMBINATION_ID
  ,CURRENCY_CODE
  ,CURRENCY_CONVERSION_TYPE
  ,CURRENCY_CONVERSION_DATE
  ,CURRENCY_CONVERSION_RATE
  ,ENTERED_DR
  ,ENTERED_CR
  ,ACCOUNTED_DR
  ,ACCOUNTED_CR
  ,SOURCE_TABLE
  ,SOURCE_ID
  ,ACCOUNT_OVERLAY_SOURCE_ID
  ,GL_SL_LINK_ID
  ,DESCRIPTION
  ,ACCOUNTING_ERROR_CODE
  ,GL_TRANSFER_ERROR_CODE
  ,THIRD_PARTY_ID
  ,THIRD_PARTY_SUB_ID
  ,STAT_AMOUNT
  ,SUBLEDGER_DOC_SEQUENCE_ID
  ,SUBLEDGER_DOC_SEQUENCE_VALUE
  ,ORG_ID
  ,CREATION_DATE
  ,USSGL_TRANSACTION_CODE
  ,CREATED_BY
  ,LAST_UPDATE_DATE
  ,LAST_UPDATED_BY
  ,LAST_UPDATE_LOGIN
  ,PROGRAM_UPDATE_DATE
  ,PROGRAM_APPLICATION_ID
  ,PROGRAM_ID
  ,REQUEST_ID
  ,REFERENCE1
  ,REFERENCE2
  ,REFERENCE3
  ,REFERENCE4
  ,REFERENCE5
  ,REFERENCE6
  ,REFERENCE7
  ,REFERENCE8
  ,REFERENCE9
  ,REFERENCE10
  ,APPLIED_FROM_TRX_HDR_TABLE
  ,APPLIED_FROM_TRX_HDR_ID
  ,APPLIED_TO_TRX_HDR_TABLE
  ,APPLIED_TO_TRX_HDR_ID
  ,TAX_CODE_ID
  ,TAXABLE_ENTERED_DR
  ,TAXABLE_ENTERED_CR
  ,TAXABLE_ACCOUNTED_DR
  ,TAXABLE_ACCOUNTED_CR
  ,TAX_LINK_ID)
AS
  SELECT ROWIDTOCHAR(ROWID) row_id,
    ae_line_id,
    ae_header_id,
    ae_line_number,
    ae_line_type_code,
    code_combination_id,
    currency_code,
    currency_conversion_type,
    currency_conversion_date,
    currency_conversion_rate,
    entered_dr,
    entered_cr,
    accounted_dr,
    accounted_cr,
    source_table,
    source_id,
    account_overlay_source_id,
    gl_sl_link_id,
    description,
    accounting_error_code,
    gl_transfer_error_code,
    third_party_id,
    third_party_sub_id,
    stat_amount,
    subledger_doc_sequence_id,
    subledger_doc_sequence_value,
    org_id,
    creation_date,
    ussgl_transaction_code,
    created_by,
    last_update_date,
    last_updated_by,
    last_update_login,
    program_update_date,
    program_application_id,
    program_id,
    request_id,
    reference1,
    reference2,
    reference3,
    reference4,
    reference5,
    reference6,
    reference7,
    reference8,
    reference9,
    reference10,
    applied_from_trx_hdr_table,
    applied_from_trx_hdr_id,
    applied_to_trx_hdr_table,
    applied_to_trx_hdr_id,
    tax_code_id,
    taxable_entered_dr,
    taxable_entered_cr,
    taxable_accounted_dr,
    taxable_accounted_cr,
    tax_link_id
FROM xxapps_history_query.ap_ae_lines_all;