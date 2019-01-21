SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- | Name        : RA_CUSTOMER_TRX_PARTIAL_V1.vw                               |
-- | Description :                                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	                   |
-- |======= =========== ============= =========================================|
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

 CREATE OR REPLACE FORCE VIEW APPS.RA_CUSTOMER_TRX_PARTIAL_V1 (ROW_ID, CUSTOMER_TRX_ID, TRX_NUMBER, OLD_TRX_NUMBER, CT_RELATED_TRX_NUMBER, CT_MODEL_TRX_NUMBER, TRX_DATE, TERM_DUE_DATE, PREVIOUS_CUSTOMER_TRX_ID, INITIAL_CUSTOMER_TRX_ID, RELATED_BATCH_SOURCE_ID, RELATED_CUSTOMER_TRX_ID, CUST_TRX_TYPE_ID, BATCH_ID, BATCH_SOURCE_ID, REASON_CODE, TERM_ID, PRIMARY_SALESREP_ID, AGREEMENT_ID, CREDIT_METHOD_FOR_RULES, CREDIT_METHOD_FOR_INSTALLMENTS, RECEIPT_METHOD_ID, INVOICING_RULE_ID, SHIP_VIA, FOB_POINT, FINANCE_CHARGES, COMPLETE_FLAG, CUSTOMER_BANK_ACCOUNT_ID, RECURRED_FROM_TRX_NUMBER, STATUS_TRX, DEFAULT_TAX_EXEMPT_FLAG, SOLD_TO_CUSTOMER_ID, SOLD_TO_SITE_USE_ID, SOLD_TO_CONTACT_ID, BILL_TO_CUSTOMER_ID, BILL_TO_SITE_USE_ID, RAA_BILL_TO_ADDRESS_ID, BILL_TO_CONTACT_ID, BILL_TO_TAXPAYER_ID, SHIP_TO_CUSTOMER_ID, SHIP_TO_SITE_USE_ID, RAA_SHIP_TO_ADDRESS_ID, SHIP_TO_CONTACT_ID, SHIP_TO_TAXPAYER_ID, REMIT_TO_ADDRESS_ID, INVOICE_CURRENCY_CODE, CREATED_FROM, SET_OF_BOOKS_ID, PRINTING_ORIGINAL_DATE,
  PRINTING_LAST_PRINTED, PRINTING_OPTION, PRINTING_COUNT, PRINTING_PENDING, LAST_PRINTED_SEQUENCE_NUM, PURCHASE_ORDER, PURCHASE_ORDER_REVISION, PURCHASE_ORDER_DATE, CUSTOMER_REFERENCE, CUSTOMER_REFERENCE_DATE, COMMENTS, INTERNAL_NOTES, EXCHANGE_RATE_TYPE, EXCHANGE_DATE, EXCHANGE_RATE, TERRITORY_ID, END_DATE_COMMITMENT, START_DATE_COMMITMENT, ORIG_SYSTEM_BATCH_NAME, SHIP_DATE_ACTUAL, WAYBILL_NUMBER, DOC_SEQUENCE_ID, DOC_SEQUENCE_VALUE, PAYING_CUSTOMER_ID, PAYING_SITE_USE_ID, ATTRIBUTE_CATEGORY, ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, INTERFACE_HEADER_CONTEXT, INTERFACE_HEADER_ATTRIBUTE1, INTERFACE_HEADER_ATTRIBUTE2, INTERFACE_HEADER_ATTRIBUTE3, INTERFACE_HEADER_ATTRIBUTE4, INTERFACE_HEADER_ATTRIBUTE5, INTERFACE_HEADER_ATTRIBUTE6, INTERFACE_HEADER_ATTRIBUTE7, INTERFACE_HEADER_ATTRIBUTE8, INTERFACE_HEADER_ATTRIBUTE9,
  INTERFACE_HEADER_ATTRIBUTE10, INTERFACE_HEADER_ATTRIBUTE11, INTERFACE_HEADER_ATTRIBUTE12, INTERFACE_HEADER_ATTRIBUTE13, INTERFACE_HEADER_ATTRIBUTE14, INTERFACE_HEADER_ATTRIBUTE15, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE_CATEGORY, DEFAULT_USSGL_TRANSACTION_CODE, LAST_UPDATE_DATE, LAST_UPDATED_BY, CREATION_DATE, CREATED_BY, LAST_UPDATE_LOGIN, REQUEST_ID, RAC_BILL_TO_CUSTOMER_NAME, RAC_BILL_TO_CUSTOMER_NUM, SU_BILL_TO_LOCATION, RAA_BILL_TO_ADDRESS1, RAA_BILL_TO_ADDRESS2, RAA_BILL_TO_ADDRESS3_DB, RAA_BILL_TO_ADDRESS3, RAA_BILL_TO_CITY, RAA_BILL_TO_COUNTY, RAA_BILL_TO_STATE, RAA_BILL_TO_PROVINCE, RAA_BILL_TO_POSTAL_CODE,
  FT_BILL_TO_COUNTRY, RAA_BILL_TO_CONCAT_ADDRESS, RACO_BILL_TO_CONTACT_NAME, RAC_SHIP_TO_CUSTOMER_NAME, RAC_SHIP_TO_CUSTOMER_NUM, SU_SHIP_TO_LOCATION, RAA_SHIP_TO_ADDRESS1, RAA_SHIP_TO_ADDRESS2, RAA_SHIP_TO_ADDRESS3_DB, RAA_SHIP_TO_ADDRESS3, RAA_SHIP_TO_CITY, RAA_SHIP_TO_COUNTY, RAA_SHIP_TO_STATE, RAA_SHIP_TO_PROVINCE, RAA_SHIP_TO_POSTAL_CODE, FT_SHIP_TO_COUNTRY, RAA_SHIP_TO_CONCAT_ADDRESS, RACO_SHIP_TO_CONTACT_NAME, RAC_SOLD_TO_CUSTOMER_NAME, RAC_SOLD_TO_CUSTOMER_NUM, RAC_PAYING_CUSTOMER_NAME, RAC_PAYING_CUSTOMER_NUM, SU_PAYING_CUSTOMER_LOCATION, RAA_REMIT_TO_ADDRESS1, RAA_REMIT_TO_ADDRESS2, RAA_REMIT_TO_ADDRESS3_DB, RAA_REMIT_TO_ADDRESS3, RAA_REMIT_TO_CITY, RAA_REMIT_TO_COUNTY, RAA_REMIT_TO_STATE, RAA_REMIT_TO_PROVINCE, RAA_REMIT_TO_POSTAL_CODE, FT_REMIT_TO_COUNTRY, RAA_CONCAT_REMIT_TO_ADDRESS, APBA_BANK_ACCOUNT_NAME, APBA_BANK_ACCOUNT_NUM, APBA_INACTIVE_DATE, APB_CUSTOMER_BANK_NAME, APB_CUSTOMER_BANK_BRANCH_NAME, ARM_RECEIPT_METHOD_NAME, ARM_PAYMENT_TYPE_CODE,
  ARC_CREATION_METHOD_CODE, BS_BATCH_SOURCE_NAME, BS_AUTO_TRX_NUMBERING_FLAG, BS_COPY_DOC_NUMBER_FLAG, RAB_BATCH_NAME, CTT_TYPE_NAME, CTT_CLASS, RAS_PRIMARY_SALESREP_NAME, RAS_PRIMARY_SALESREP_NUM, RAT_TERM_NAME, RAT_TERM_IN_USE_FLAG, SOA_AGREEMENT_NAME, OF_SHIP_VIA_NAME, OF_ORGANIZATION_ID, AL_FOB_MEANING, AL_DEFAULT_TAX_EXEMPT_FLAG, CT_REFERENCE, GD_GL_DATE, GDCT_USER_EXCHANGE_RATE_TYPE, CT_INVOICE_FOR_CB, PS_DISPUTE_AMOUNT, PS_DISPUTE_DATE, DH_MAX_DISPUTE_DATE, REV_RECOG_RUN_FLAG, POSTED_FLAG, SELECTED_FOR_PAYMENT_FLAG, ACTIVITY_FLAG, CTT_POST_TO_GL_FLAG, CTT_OPEN_RECEIVABLES_FLAG, CTT_ALLOW_FREIGHT_FLAG, CTT_CREATION_SIGN, CTT_ALLOW_OVERAPPLICATION_FLAG, CTT_NATURAL_APP_ONLY_FLAG, CTT_TAX_CALCULATION_FLAG, CTT_DEFAULT_STATUS, CTT_DEFAULT_TERM, CTT_DEFAULT_PRINTING_OPTION, RULES_FLAG, PRINTED_FLAG, CM_AGAINST_TRX_FLAG, SITE_STATUS, CUSTOMER_STATUS, OVERRIDE_TERMS, COMMITMENTS_EXIST_FLAG, AGREEMENTS_EXIST_FLAG, ATCHMT_FLAG, GLOBAL_ATTRIBUTE21, GLOBAL_ATTRIBUTE22, GLOBAL_ATTRIBUTE23
  , GLOBAL_ATTRIBUTE24, GLOBAL_ATTRIBUTE25, GLOBAL_ATTRIBUTE26, GLOBAL_ATTRIBUTE27, GLOBAL_ATTRIBUTE28, GLOBAL_ATTRIBUTE29, GLOBAL_ATTRIBUTE30, BS_BATCH_SOURCE_TYPE, RA_BILLING_NUMBER, REVERSED_CASH_RECEIPT_ID, DEFAULT_REFERENCE)
AS
  SELECT
    /*+ use_nl(CT GD) */
    CT.ROWID ,
    CT.CUSTOMER_TRX_ID ,
    CT.TRX_NUMBER ,
    CT.OLD_TRX_NUMBER ,
    CT_REL.TRX_NUMBER ,
    CT.RECURRED_FROM_TRX_NUMBER ,
    CT.TRX_DATE ,
    ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE(CT.CUSTOMER_TRX_ID , CT.TERM_ID, CT.TRX_DATE) ,
    CT.PREVIOUS_CUSTOMER_TRX_ID ,
    CT.INITIAL_CUSTOMER_TRX_ID ,
    CT.RELATED_BATCH_SOURCE_ID ,
    CT.RELATED_CUSTOMER_TRX_ID ,
    CT.CUST_TRX_TYPE_ID ,
    CT.BATCH_ID ,
    CT.BATCH_SOURCE_ID ,
    CT.REASON_CODE ,
    CT.TERM_ID ,
    CT.PRIMARY_SALESREP_ID ,
    CT.AGREEMENT_ID ,
    CT.CREDIT_METHOD_FOR_RULES ,
    CT.CREDIT_METHOD_FOR_INSTALLMENTS ,
    CT.RECEIPT_METHOD_ID ,
    CT.INVOICING_RULE_ID ,
    CT.SHIP_VIA ,
    CT.FOB_POINT ,
    CT.FINANCE_CHARGES ,
    CT.COMPLETE_FLAG ,
    CT.CUSTOMER_BANK_ACCOUNT_ID ,
    CT.RECURRED_FROM_TRX_NUMBER ,
    CT.STATUS_TRX ,
    CT.DEFAULT_TAX_EXEMPT_FLAG ,
    CT.SOLD_TO_CUSTOMER_ID ,
    CT.SOLD_TO_SITE_USE_ID ,
    CT.SOLD_TO_CONTACT_ID ,
    CT.BILL_TO_CUSTOMER_ID ,
    CT.BILL_TO_SITE_USE_ID ,
    RAA_BILL.CUST_ACCT_SITE_ID ,
    CT.BILL_TO_CONTACT_ID ,
    RAC_BILL_PARTY.JGZZ_FISCAL_CODE ,
    CT.SHIP_TO_CUSTOMER_ID ,
    CT.SHIP_TO_SITE_USE_ID ,
    RAA_SHIP.CUST_ACCT_SITE_ID ,
    CT.SHIP_TO_CONTACT_ID ,
    RAC_SHIP_PARTY.JGZZ_FISCAL_CODE ,
    CT.REMIT_TO_ADDRESS_ID ,
    CT.INVOICE_CURRENCY_CODE ,
    CT.CREATED_FROM ,
    CT.SET_OF_BOOKS_ID ,
    CT.PRINTING_ORIGINAL_DATE ,
    CT.PRINTING_LAST_PRINTED ,
    CT.PRINTING_OPTION ,
    CT.PRINTING_COUNT ,
    CT.PRINTING_PENDING ,
    CT.LAST_PRINTED_SEQUENCE_NUM ,
    CT.PURCHASE_ORDER ,
    CT.PURCHASE_ORDER_REVISION ,
    CT.PURCHASE_ORDER_DATE ,
    CT.CUSTOMER_REFERENCE ,
    CT.CUSTOMER_REFERENCE_DATE ,
    CT.COMMENTS ,
    CT.INTERNAL_NOTES ,
    CT.EXCHANGE_RATE_TYPE ,
    CT.EXCHANGE_DATE ,
    CT.EXCHANGE_RATE ,
    CT.TERRITORY_ID ,
    CT.END_DATE_COMMITMENT ,
    CT.START_DATE_COMMITMENT ,
    CT.ORIG_SYSTEM_BATCH_NAME ,
    CT.SHIP_DATE_ACTUAL ,
    CT.WAYBILL_NUMBER ,
    CT.DOC_SEQUENCE_ID ,
    CT.DOC_SEQUENCE_VALUE ,
    CT.PAYING_CUSTOMER_ID ,
    CT.PAYING_SITE_USE_ID ,
    CT.ATTRIBUTE_CATEGORY ,
    CT.ATTRIBUTE1 ,
    CT.ATTRIBUTE2 ,
    CT.ATTRIBUTE3 ,
    CT.ATTRIBUTE4 ,
    CT.ATTRIBUTE5 ,
    CT.ATTRIBUTE6 ,
    CT.ATTRIBUTE7 ,
    CT.ATTRIBUTE8 ,
    CT.ATTRIBUTE9 ,
    CT.ATTRIBUTE10 ,
    CT.ATTRIBUTE11 ,
    CT.ATTRIBUTE12 ,
    CT.ATTRIBUTE13 ,
    CT.ATTRIBUTE14 ,
    CT.ATTRIBUTE15 ,
    CT.INTERFACE_HEADER_CONTEXT ,
    CT.INTERFACE_HEADER_ATTRIBUTE1 ,
    CT.INTERFACE_HEADER_ATTRIBUTE2 ,
    CT.INTERFACE_HEADER_ATTRIBUTE3 ,
    CT.INTERFACE_HEADER_ATTRIBUTE4 ,
    CT.INTERFACE_HEADER_ATTRIBUTE5 ,
    CT.INTERFACE_HEADER_ATTRIBUTE6 ,
    CT.INTERFACE_HEADER_ATTRIBUTE7 ,
    CT.INTERFACE_HEADER_ATTRIBUTE8 ,
    CT.INTERFACE_HEADER_ATTRIBUTE9 ,
    CT.INTERFACE_HEADER_ATTRIBUTE10 ,
    CT.INTERFACE_HEADER_ATTRIBUTE11 ,
    CT.INTERFACE_HEADER_ATTRIBUTE12 ,
    CT.INTERFACE_HEADER_ATTRIBUTE13 ,
    CT.INTERFACE_HEADER_ATTRIBUTE14 ,
    CT.INTERFACE_HEADER_ATTRIBUTE15 ,
    CT.GLOBAL_ATTRIBUTE1 ,
    CT.GLOBAL_ATTRIBUTE2 ,
    CT.GLOBAL_ATTRIBUTE3 ,
    CT.GLOBAL_ATTRIBUTE4 ,
    CT.GLOBAL_ATTRIBUTE5 ,
    CT.GLOBAL_ATTRIBUTE6 ,
    CT.GLOBAL_ATTRIBUTE7 ,
    CT.GLOBAL_ATTRIBUTE8 ,
    CT.GLOBAL_ATTRIBUTE9 ,
    CT.GLOBAL_ATTRIBUTE10 ,
    CT.GLOBAL_ATTRIBUTE11 ,
    CT.GLOBAL_ATTRIBUTE12 ,
    CT.GLOBAL_ATTRIBUTE13 ,
    CT.GLOBAL_ATTRIBUTE14 ,
    CT.GLOBAL_ATTRIBUTE15 ,
    CT.GLOBAL_ATTRIBUTE16 ,
    CT.GLOBAL_ATTRIBUTE17 ,
    CT.GLOBAL_ATTRIBUTE18 ,
    CT.GLOBAL_ATTRIBUTE19 ,
    CT.GLOBAL_ATTRIBUTE20 ,
    CT.GLOBAL_ATTRIBUTE_CATEGORY ,
    CT.DEFAULT_USSGL_TRANSACTION_CODE ,
    CT.LAST_UPDATE_DATE ,
    CT.LAST_UPDATED_BY ,
    CT.CREATION_DATE ,
    CT.CREATED_BY ,
    CT.LAST_UPDATE_LOGIN ,
    CT.REQUEST_ID ,
    RAC_BILL_PARTY.PARTY_NAME ,
    RAC_BILL.ACCOUNT_NUMBER ,
    SU_BILL.LOCATION ,
    RAA_BILL_LOC.ADDRESS1 ,
    RAA_BILL_LOC.ADDRESS2 ,
    RAA_BILL_LOC.ADDRESS3 ,
    DECODE( RAA_BILL.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.FORMAT_LAST_ADDRESS_LINE(RAA_BILL_LOC.ADDRESS_STYLE, RAA_BILL_LOC.ADDRESS3, RAA_BILL_LOC.ADDRESS4, RAA_BILL_LOC.CITY, RAA_BILL_LOC.COUNTY, RAA_BILL_LOC.STATE, RAA_BILL_LOC.PROVINCE, FT_BILL.TERRITORY_SHORT_NAME, RAA_BILL_LOC.POSTAL_CODE) ) ,
    RAA_BILL_LOC.CITY ,
    RAA_BILL_LOC.COUNTY ,
    RAA_BILL_LOC.STATE ,
    RAA_BILL_LOC.PROVINCE ,
    RAA_BILL_LOC.POSTAL_CODE ,
    FT_BILL.TERRITORY_SHORT_NAME ,
    DECODE( RAA_BILL.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.ARXTW_FORMAT_ADDRESS(RAA_BILL_LOC.ADDRESS_STYLE, RAA_BILL_LOC.ADDRESS1, RAA_BILL_LOC.ADDRESS2, RAA_BILL_LOC.ADDRESS3, RAA_BILL_LOC.ADDRESS4, RAA_BILL_LOC.CITY, RAA_BILL_LOC.COUNTY, RAA_BILL_LOC.STATE, RAA_BILL_LOC.PROVINCE, RAA_BILL_LOC.POSTAL_CODE, FT_BILL.TERRITORY_SHORT_NAME) ) ,
    DECODE(SUBSTRB(RACO_BILL_PARTY.PERSON_LAST_NAME,1,50), NULL, SUBSTRB(RACO_BILL_PARTY.PERSON_FIRST_NAME,1,40), SUBSTRB(RACO_BILL_PARTY.PERSON_LAST_NAME,1,50)
    ||', '
    || SUBSTRB(RACO_BILL_PARTY.PERSON_FIRST_NAME,1,40)) ,
    RAC_SHIP_PARTY.PARTY_NAME ,
    RAC_SHIP.ACCOUNT_NUMBER ,
    SU_SHIP.LOCATION ,
    RAA_SHIP_LOC.ADDRESS1 ,
    RAA_SHIP_LOC.ADDRESS2 ,
    RAA_SHIP_LOC.ADDRESS3 ,
    DECODE( RAA_SHIP.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.FORMAT_LAST_ADDRESS_LINE(RAA_SHIP_LOC.ADDRESS_STYLE, RAA_SHIP_LOC.ADDRESS3, RAA_SHIP_LOC.ADDRESS4, RAA_SHIP_LOC.CITY, RAA_SHIP_LOC.COUNTY, RAA_SHIP_LOC.STATE, RAA_SHIP_LOC.PROVINCE, FT_SHIP.TERRITORY_SHORT_NAME, RAA_SHIP_LOC.POSTAL_CODE) ) ,
    RAA_SHIP_LOC.CITY ,
    RAA_SHIP_LOC.COUNTY ,
    RAA_SHIP_LOC.STATE ,
    RAA_SHIP_LOC.PROVINCE ,
    RAA_SHIP_LOC.POSTAL_CODE ,
    FT_SHIP.TERRITORY_SHORT_NAME ,
    DECODE( RAA_SHIP.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.ARXTW_FORMAT_ADDRESS(RAA_SHIP_LOC.ADDRESS_STYLE, RAA_SHIP_LOC.ADDRESS1, RAA_SHIP_LOC.ADDRESS2, RAA_SHIP_LOC.ADDRESS3, RAA_SHIP_LOC.ADDRESS4, RAA_SHIP_LOC.CITY, RAA_SHIP_LOC.COUNTY, RAA_SHIP_LOC.STATE, RAA_SHIP_LOC.PROVINCE, RAA_SHIP_LOC.POSTAL_CODE, FT_SHIP.TERRITORY_SHORT_NAME) ) ,
    DECODE(SUBSTRB(RACO_SHIP_PARTY.PERSON_LAST_NAME,1,50), NULL, SUBSTRB(RACO_SHIP_PARTY.PERSON_FIRST_NAME,1,40), SUBSTRB(RACO_SHIP_PARTY.PERSON_LAST_NAME,1,50)
    || ', '
    || SUBSTRB(RACO_SHIP_PARTY.PERSON_FIRST_NAME,1,40)) ,
    RAC_SOLD_PARTY.PARTY_NAME ,
    RAC_SOLD.ACCOUNT_NUMBER ,
    RAC_PAYING_PARTY.PARTY_NAME ,
    RAC_PAYING.ACCOUNT_NUMBER ,
    SU_PAYING.LOCATION ,
    RAA_REMIT_LOC.ADDRESS1 ,
    RAA_REMIT_LOC.ADDRESS2 ,
    RAA_REMIT_LOC.ADDRESS3 ,
    DECODE( RAA_REMIT.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.FORMAT_LAST_ADDRESS_LINE(RAA_REMIT_LOC.ADDRESS_STYLE, RAA_REMIT_LOC.ADDRESS3, RAA_REMIT_LOC.ADDRESS4, RAA_REMIT_LOC.CITY, RAA_REMIT_LOC.COUNTY, RAA_REMIT_LOC.STATE, RAA_REMIT_LOC.PROVINCE, FT_REMIT.TERRITORY_SHORT_NAME, RAA_REMIT_LOC.POSTAL_CODE) ) ,
    RAA_REMIT_LOC.CITY ,
    RAA_REMIT_LOC.COUNTY ,
    RAA_REMIT_LOC.STATE ,
    RAA_REMIT_LOC.PROVINCE ,
    RAA_REMIT_LOC.POSTAL_CODE ,
    FT_REMIT.TERRITORY_SHORT_NAME ,
    DECODE( RAA_REMIT.CUST_ACCT_SITE_ID, NULL, NULL, ARH_ADDR_PKG.ARXTW_FORMAT_ADDRESS(RAA_REMIT_LOC.ADDRESS_STYLE, RAA_REMIT_LOC.ADDRESS1, RAA_REMIT_LOC.ADDRESS2, RAA_REMIT_LOC.ADDRESS3, RAA_REMIT_LOC.ADDRESS4, RAA_REMIT_LOC.CITY, RAA_REMIT_LOC.COUNTY, RAA_REMIT_LOC.STATE, RAA_REMIT_LOC.PROVINCE, RAA_REMIT_LOC.POSTAL_CODE, FT_REMIT.TERRITORY_SHORT_NAME) ) ,
    APBA.BANK_ACCOUNT_NAME ,
    LPAD(SUBSTR(BANK_ACCOUNT_NUM,-4),LENGTH(BANK_ACCOUNT_NUM),'*')
    --, ARP_BANK_PKG.MASK_ACCOUNT_NUMBER(APBA.BANK_ACCOUNT_NUM, APBA.BANK_BRANCH_ID)
    ,
    APBA.INACTIVE_DATE ,
    APB.BANK_NAME ,
    APB.BANK_BRANCH_NAME ,
    ARM.NAME ,
    ARM.PAYMENT_TYPE_CODE ,
    ARC.CREATION_METHOD_CODE ,
    BS.NAME ,
    BS.AUTO_TRX_NUMBERING_FLAG ,
    BS.COPY_DOC_NUMBER_FLAG ,
    RAB.NAME ,
    CTT.NAME ,
    CTT.TYPE ,
    ARPT_SQL_FUNC_UTIL.get_salesrep_name_number(CT.PRIMARY_SALESREP_ID,'NAME') ,
    ARPT_SQL_FUNC_UTIL.get_salesrep_name_number(CT.PRIMARY_SALESREP_ID,'NUMBER') ,
    RAT.NAME ,
    RAT.IN_USE ,
    SOA.NAME ,
    ORF.DESCRIPTION ,
    ORF.ORGANIZATION_ID ,
    AL_FOB.MEANING ,
    AL_TAX.MEANING ,
    CT.ct_reference ,
    GD.GL_DATE ,
    GDCT.USER_CONVERSION_TYPE ,
    ARPT_SQL_FUNC_UTIL.GET_CB_INVOICE( CT.CUSTOMER_TRX_ID, CTT.TYPE) ,
    ARPT_SQL_FUNC_UTIL.GET_DISPUTE_AMOUNT( CT.CUSTOMER_TRX_ID, CTT.TYPE, CTT.ACCOUNTING_AFFECT_FLAG ) ,
    ARPT_SQL_FUNC_UTIL.GET_DISPUTE_DATE( CT.CUSTOMER_TRX_ID, CTT.TYPE, CTT.ACCOUNTING_AFFECT_FLAG ) ,
    ARPT_SQL_FUNC_UTIL.GET_MAX_DISPUTE_DATE( CT.CUSTOMER_TRX_ID, CTT.TYPE, CTT.ACCOUNTING_AFFECT_FLAG ) ,
    ARPT_SQL_FUNC_UTIL.GET_REVENUE_RECOG_RUN_FLAG(CT.CUSTOMER_TRX_ID, CT.INVOICING_RULE_ID) ,
    ARPT_SQL_FUNC_UTIL.GET_POSTED_FLAG( CT.CUSTOMER_TRX_ID, CTT.POST_TO_GL, CT.COMPLETE_FLAG ) ,
    ARPT_SQL_FUNC_UTIL.GET_SELECTED_FOR_PAYMENT_FLAG( CT.CUSTOMER_TRX_ID, CTT.ACCOUNTING_AFFECT_FLAG, CT.COMPLETE_FLAG ) ,
    ARPT_SQL_FUNC_UTIL.GET_ACTIVITY_FLAG( CT.CUSTOMER_TRX_ID, CTT.ACCOUNTING_AFFECT_FLAG, CT.COMPLETE_FLAG, CTT.TYPE, CT.INITIAL_CUSTOMER_TRX_ID, CT.PREVIOUS_CUSTOMER_TRX_ID ) ,
    CTT.POST_TO_GL ,
    CTT.ACCOUNTING_AFFECT_FLAG ,
    CTT.ALLOW_FREIGHT_FLAG ,
    CTT.CREATION_SIGN ,
    CTT.ALLOW_OVERAPPLICATION_FLAG ,
    CTT.NATURAL_APPLICATION_ONLY_FLAG ,
    CTT.TAX_CALCULATION_FLAG ,
    CTT.DEFAULT_STATUS ,
    CTT.DEFAULT_TERM ,
    CTT.DEFAULT_PRINTING_OPTION ,
    DECODE(CT.INVOICING_RULE_ID, NULL, 'N', 'Y') ,
    DECODE(CT.PRINTING_LAST_PRINTED, NULL, 'N', 'Y') ,
    DECODE(CT.PREVIOUS_CUSTOMER_TRX_ID, NULL, 'N', 'Y') ,
    SU_BILL.STATUS ,
    RAC_BILL.STATUS ,
    ARPT_SQL_FUNC_UTIL.GET_OVERRIDE_TERMS(CT.BILL_TO_CUSTOMER_ID, CT.BILL_TO_SITE_USE_ID) ,
    DECODE(CT.INITIAL_CUSTOMER_TRX_ID, NULL, DECODE(CTT.TYPE, 'DEP', 'N', 'GUAR', 'N', 'CB', 'N', 'Y' ), 'Y') ,
    DECODE(CT.AGREEMENT_ID, NULL, DECODE(CTT.TYPE, 'CM', 'N', ARPT_SQL_FUNC_UTIL.GET_AGREEMENTS_EXIST_FLAG( CT.BILL_TO_CUSTOMER_ID, CT.TRX_DATE) ), 'Y') ,
    FND_ATTACHMENT_UTIL_PKG.GET_ATCHMT_EXISTS('RA_CUSTOMER_TRX', CT.CUSTOMER_TRX_ID) ,
    CT.GLOBAL_ATTRIBUTE21 ,
    CT.GLOBAL_ATTRIBUTE22 ,
    CT.GLOBAL_ATTRIBUTE23 ,
    CT.GLOBAL_ATTRIBUTE24 ,
    CT.GLOBAL_ATTRIBUTE15 ,
    CT.GLOBAL_ATTRIBUTE26 ,
    CT.GLOBAL_ATTRIBUTE27 ,
    CT.GLOBAL_ATTRIBUTE28 ,
    CT.GLOBAL_ATTRIBUTE29 ,
    CT.GLOBAL_ATTRIBUTE30 ,
    BS.BATCH_SOURCE_TYPE ,
    NULL ,
    CT.REVERSED_CASH_RECEIPT_ID ,
    BS.DEFAULT_REFERENCE
  FROM RA_CUST_TRX_LINE_GL_DIST GD,
    RA_CUSTOMER_TRX CT,
    HZ_CUST_ACCOUNTS RAC_BILL,
    HZ_PARTIES RAC_BILL_PARTY,
    HZ_CUST_ACCOUNTS RAC_SHIP,
    HZ_PARTIES RAC_SHIP_PARTY,
    HZ_CUST_ACCOUNTS RAC_SOLD,
    HZ_PARTIES RAC_SOLD_PARTY,
    HZ_CUST_ACCOUNTS RAC_PAYING,
    HZ_PARTIES RAC_PAYING_PARTY,
    HZ_CUST_SITE_USES SU_BILL,
    HZ_CUST_SITE_USES SU_SHIP,
    HZ_CUST_SITE_USES SU_PAYING,
    FND_TERRITORIES_VL FT_BILL,
    FND_TERRITORIES_VL FT_SHIP,
    FND_TERRITORIES_VL FT_REMIT,
    HZ_CUST_ACCT_SITES RAA_BILL,
    HZ_PARTY_SITES RAA_BILL_PS,
    HZ_LOCATIONS RAA_BILL_LOC,
    HZ_CUST_ACCT_SITES RAA_SHIP,
    HZ_PARTY_SITES RAA_SHIP_PS,
    HZ_LOCATIONS RAA_SHIP_LOC,
    HZ_CUST_ACCT_SITES RAA_REMIT,
    HZ_PARTY_SITES RAA_REMIT_PS,
    HZ_LOCATIONS RAA_REMIT_LOC,
    HZ_CUST_ACCOUNT_ROLES RACO_SHIP,
    HZ_PARTIES RACO_SHIP_PARTY,
    HZ_RELATIONSHIPS RACO_SHIP_REL,
    HZ_CUST_ACCOUNT_ROLES RACO_BILL,
    HZ_PARTIES RACO_BILL_PARTY,
    HZ_RELATIONSHIPS RACO_BILL_REL,
    AP_BANK_ACCOUNTS APBA,
    AP_BANK_BRANCHES APB,
    AR_RECEIPT_METHODS ARM,
    AR_RECEIPT_CLASSES ARC,
    RA_BATCH_SOURCES BS,
    RA_BATCHES RAB,
    RA_CUST_TRX_TYPES CTT,
    RA_TERMS RAT,
    SO_AGREEMENTS SOA,
    ORG_FREIGHT ORF,
    GL_DAILY_CONVERSION_TYPES GDCT,
    RA_CUSTOMER_TRX CT_REL,
    AR_LOOKUPS AL_FOB,
    AR_LOOKUPS AL_TAX
  WHERE CT.CUSTOMER_TRX_ID                = GD.CUSTOMER_TRX_ID
  AND 'REC'                               = GD.ACCOUNT_CLASS
  AND 'Y'                                 = GD.LATEST_REC_FLAG
  AND CT.RELATED_CUSTOMER_TRX_ID          = CT_REL.CUSTOMER_TRX_ID(+)
  AND CT.BILL_TO_CUSTOMER_ID              = RAC_BILL.CUST_ACCOUNT_ID
  AND RAC_BILL.PARTY_ID                   = RAC_BILL_PARTY.PARTY_ID
  AND CT.SHIP_TO_CUSTOMER_ID              = RAC_SHIP.CUST_ACCOUNT_ID(+)
  AND RAC_SHIP.PARTY_ID                   = RAC_SHIP_PARTY.PARTY_ID(+)
  AND CT.SOLD_TO_CUSTOMER_ID              = RAC_SOLD.CUST_ACCOUNT_ID(+)
  AND RAC_SOLD.PARTY_ID                   = RAC_SOLD_PARTY.PARTY_ID(+)
  AND CT.PAYING_CUSTOMER_ID               = RAC_PAYING.CUST_ACCOUNT_ID(+)
  AND RAC_PAYING.PARTY_ID                 = RAC_PAYING_PARTY.PARTY_ID(+)
  AND CT.BILL_TO_SITE_USE_ID              = SU_BILL.SITE_USE_ID
  AND CT.SHIP_TO_SITE_USE_ID              = SU_SHIP.SITE_USE_ID(+)
  AND CT.PAYING_SITE_USE_ID               = SU_PAYING.SITE_USE_ID(+)
  AND SU_BILL.CUST_ACCT_SITE_ID           = RAA_BILL.CUST_ACCT_SITE_ID
  AND RAA_BILL.PARTY_SITE_ID              = RAA_BILL_PS.PARTY_SITE_ID
  AND RAA_BILL_LOC.LOCATION_ID            = RAA_BILL_PS.LOCATION_ID
  AND SU_SHIP.CUST_ACCT_SITE_ID           = RAA_SHIP.CUST_ACCT_SITE_ID(+)
  AND RAA_SHIP.PARTY_SITE_ID              = RAA_SHIP_PS.PARTY_SITE_ID(+)
  AND RAA_SHIP_LOC.LOCATION_ID(+)         = RAA_SHIP_PS.LOCATION_ID
  AND CT.BILL_TO_CONTACT_ID               = RACO_BILL.CUST_ACCOUNT_ROLE_ID(+)
  AND RACO_BILL.PARTY_ID                  = RACO_BILL_REL.PARTY_ID(+)
  AND RACO_BILL_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
  AND RACO_BILL_REL.OBJECT_TABLE_NAME(+)  = 'HZ_PARTIES'
  AND RACO_BILL_REL.DIRECTIONAL_FLAG(+)   = 'F'
  AND RACO_BILL.ROLE_TYPE(+)              = 'CONTACT'
  AND RACO_BILL_REL.SUBJECT_ID            = RACO_BILL_PARTY.PARTY_ID(+)
  AND CT.SHIP_TO_CONTACT_ID               = RACO_SHIP.CUST_ACCOUNT_ROLE_ID(+)
  AND RACO_SHIP.PARTY_ID                  = RACO_SHIP_REL.PARTY_ID(+)
  AND RACO_SHIP_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
  AND RACO_SHIP_REL.OBJECT_TABLE_NAME(+)  = 'HZ_PARTIES'
  AND RACO_SHIP_REL.DIRECTIONAL_FLAG(+)   = 'F'
  AND RACO_SHIP.ROLE_TYPE(+)              = 'CONTACT'
  AND RACO_SHIP_REL.SUBJECT_ID            = RACO_SHIP_PARTY.PARTY_ID(+)
  AND CT.REMIT_TO_ADDRESS_ID              = RAA_REMIT.CUST_ACCT_SITE_ID(+)
  AND RAA_REMIT.PARTY_SITE_ID             = RAA_REMIT_PS.PARTY_SITE_ID(+)
  AND RAA_REMIT_LOC.LOCATION_ID(+)        = RAA_REMIT_PS.LOCATION_ID
  AND RAA_BILL_LOC.COUNTRY                = FT_BILL.TERRITORY_CODE(+)
  AND RAA_SHIP_LOC.COUNTRY                = FT_SHIP.TERRITORY_CODE(+)
  AND RAA_REMIT_LOC.COUNTRY               = FT_REMIT.TERRITORY_CODE(+)
  AND CT.CUSTOMER_BANK_ACCOUNT_ID         = APBA.BANK_ACCOUNT_ID(+)
  AND APBA.BANK_BRANCH_ID                 = APB.BANK_BRANCH_ID(+)
  AND CT.RECEIPT_METHOD_ID                = ARM.RECEIPT_METHOD_ID(+)
  AND ARM.RECEIPT_CLASS_ID                = ARC.RECEIPT_CLASS_ID(+)
  AND CT.BATCH_SOURCE_ID                  = BS.BATCH_SOURCE_ID
  AND CT.BATCH_ID                         = RAB.BATCH_ID(+)
  AND CT.CUST_TRX_TYPE_ID                 = CTT.CUST_TRX_TYPE_ID
  AND CTT.TYPE                           <> 'BR'
  AND CT.TERM_ID                          = RAT.TERM_ID(+)
  AND CT.AGREEMENT_ID                     = SOA.AGREEMENT_ID(+)
  AND CT.EXCHANGE_RATE_TYPE               = GDCT.CONVERSION_TYPE(+)
  AND 'FOB'                               = AL_FOB.LOOKUP_TYPE(+)
  AND CT.FOB_POINT                        = AL_FOB.LOOKUP_CODE(+)
  AND CT.SHIP_VIA                         = ORF.FREIGHT_CODE(+)
  AND CT.ORG_ID                           = ORF.ORGANIZATION_ID(+)
  AND 'TAX_CONTROL_FLAG'                  = AL_TAX.LOOKUP_TYPE(+)
  AND CT.DEFAULT_TAX_EXEMPT_FLAG          = AL_TAX.LOOKUP_CODE(+)
  AND RACO_SHIP_REL.STATUS(+)             = 'A'
  AND RACO_BILL_REL.STATUS(+)             = 'A' ;


SHOW ERRORS;
