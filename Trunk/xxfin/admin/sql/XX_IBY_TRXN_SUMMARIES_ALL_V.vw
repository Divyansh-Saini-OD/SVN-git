-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_TRXN_SUMMARIES_ALL_V.vw                                  |
-- | View Name  : XX_IBY_TRXN_SUMMARIES_ALL_V                                     |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_TRXN_SUMMARIES_ALL                                        |
-- |                                                                              |
-- |                  Columns excluded:   instrnumber                             |
-- |                                      instrnum_hash                           |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    04-JAN-2017  Avinash B		 R12.2 GSCC Changes               |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_IBY_TRXN_SUMMARIES_ALL_V
AS
SELECT trxnmid
      ,transactionid
      ,tangibleid
      ,payeeid
      ,bepid
      ,mpayeeid
      ,ecappid
      ,org_id
      ,paymentmethodname
      ,mtangibleid
      ,payeeinstrid
      ,payerid
      ,payerinstrid
      ,detaillookup
      ,amount
      ,currencynamecode
      ,status
      ,updatedate
      ,trxntypeid
      ,errorlocation
      ,bepcode
      ,bepmessage
      ,batchid
      ,settledate
      ,mbatchid
      ,reqdate
      ,reqtype
      ,reqseq
      ,desturl
      ,nlslang
      ,needsupdt
      ,overall_score
      ,object_version_number
      ,last_update_date
      ,last_updated_by
      ,creation_date
      ,created_by
      ,last_update_login
      ,instrtype
      ,security_group_id
      ,sales_rep_party_id
      ,bepkey
      ,cust_account_id
      ,instrsubtype
      ,sub_key_id
      ,ecbatchid
      ,trxnref
      ,instrnum_hash
      ,instrnum_length
      ,instrnum_sec_segment_id
      ,cc_issuer_range_id
      ,proc_reference_code
      ,proc_reference_amount
      ,settlement_customer_reference
      ,acct_site_use_id
      ,acct_site_id
      ,first_trxn_flag
      ,salt_version
      ,process_profile_code
      ,org_type
      ,legal_entity_id
      ,bill_to_address_id
      ,factored_flag
      ,payment_channel_code
      ,br_maturity_date
      ,settlement_due_date
      ,call_app_service_req_code
      ,bank_charge_bearer_code
      ,dirdeb_instruction_code
      ,debit_advice_delivery_method
      ,debit_advice_email
      ,debit_advice_fax
      ,payer_party_id
      ,debit_auth_flag
      ,debit_auth_method
      ,debit_auth_reference
      ,payer_instr_assignment_id
      ,payer_notification_required
      ,payer_notification_created
      ,ar_receipt_method_id
      ,br_drawee_issued_flag
      ,br_signed_flag
      ,initiator_extension_id
      ,logical_group_reference
      ,seq_type
      ,service_level
      ,localinstr
      ,category_purpose
      ,debit_authorization_id
      ,creditor_reference
      ,purpose_code
 FROM iby_trxn_summaries_all;
