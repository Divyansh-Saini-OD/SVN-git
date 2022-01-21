-- +==========================================================================+
-- |                       Office Depot - Project Simplify                    |
-- |                         WIPRO Technologies                               |
-- +==========================================================================+
-- | Name             : PO Mass Update                                        |
-- | Description      : The Standard view PO_HEADERS_INQ_PO_V is extended to  |
-- |                    include batch_num by joining two custom tables        |
-- |                    xx_po_allocation_header and  xx_po_allocation_lines   |
-- |                                                                          |
-- | SQL Script to create the following object                                |
-- | View             : XX_PO_HEADERS_INQ_PO_V                                |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version     Date           Author                    Remarks              |
-- |=======     ==========     =============             =====================|
-- | V1.0       21-MAY-2007    MadanKumar J              Initial version      |
-- |                                                                          |
-- +==========================================================================+
 
SET SHOW            OFF
SET VERIFY          OFF
SET TERM            OFF
SET ECHO            OFF
SET TAB             OFF
SET FEEDBACK        ON
 
PROMPT
PROMPT Dropping View XX_PO_HEADERS_INQ_PO_V
PROMPT
 
DROP VIEW XX_PO_HEADERS_INQ_PO_V;
 
PROMPT
PROMPT Creating the Custom View XX_PO_HEADERS_INQ_PO_V
PROMPT
 
WHENEVER SQLERROR EXIT 1
 
PROMPT
PROMPT Creating View XX_PO_HEADERS_INQ_PO_V
PROMPT
 
CREATE OR REPLACE VIEW XX_PO_HEADERS_INQ_PO_V(
  row_id
, po_release_flag
, creation_date
, acceptance_due_date
, amount_limit
, approved_date
, authorization_status
, blanket_total_amount
, closed_date
, comments
, end_date
, end_date_active
, firm_date
, government_context
, min_release_amount
, note_to_authorizer
, note_to_receiver
, note_to_vendor
, print_count
, printed_date
, quote_vendor_quote_number
, quote_warning_delay
, quote_warning_delay_unit
, rate, rate_date
, rate_type
, reply_date
, revised_date
, revision_num
, rfq_close_date
, start_date
, start_date_active
, vendor_order_num
, agent_id
, bill_to_location_id
, from_header_id
, po_header_id
, ship_to_location_id
, terms_id
, vendor_contact_id
, vendor_id
, vendor_site_id
, closed_code
, currency_code
, firm_status_lookup_code
, fob_lookup_code
, freight_terms_lookup_code
, from_type_lookup_code
, quotation_class_code
, quote_type_lookup_code
, reply_method_lookup_code
, ship_via_lookup_code
, status_lookup_code
, type_lookup_code
, ussgl_transaction_code
, acceptance_required_flag
, approval_required_flag
, approved_flag
, cancel_flag
, confirming_order_flag
, enabled_flag
, frozen_flag
, summary_flag
, user_hold_flag
, created_by
, order_date
, last_updated_by
, last_update_date
, last_update_login
, program_application_id
, program_id
, program_update_date
, request_id
, po_num
, segment2
, segment3
, segment4
, segment5
, attribute_category
, attribute1
, attribute2
, attribute3
, attribute4
, attribute5
, attribute6
, attribute7
, attribute8
, attribute9
, attribute10
, attribute11
, attribute12
, attribute13
, attribute14
, attribute15
, doc_type_name
, can_preparer_approve_flag
, security_level_code
, vendor_name
, type_1099
, vat_code
, vendor_site_code
, address_line1
, address_line2
, address_line3
, city
, state
, zip
, country
, phone
, fax
, vendor_contact
, terms_name
, ship_to_location
, bill_to_location
, rate_conversion_type
, authorization_status_dsp
, fob_dsp
, freight_terms_dsp
, closed_code_dsp
, cancel_date
, cancel_reason
, cancelled_by
, hold_by
, hold_date
, hold_reason
, release_num
, release_type
, po_release_id
, pcard_id
, price_update_tolerance
, pay_on_code
, pay_on_dsp
, global_agreement_flag
, owning_org_id
, cbc_accounting_date
, consigned_consumption_flag
, conterms_exist_flag
, conterms_articles_upd_date
, conterms_deliv_upd_date
, shipping_control
, shipping_control_dsp
, pending_signature_flag
, change_summary
,batch_num)
AS
SELECT POH.ROWID
       , 'PO'
       , POH.CREATION_DATE
       , POH.ACCEPTANCE_DUE_DATE
       , POH.AMOUNT_LIMIT
       , POH.APPROVED_DATE
       , NVL(POH.AUTHORIZATION_STATUS,'INCOMPLETE')
       , POH.BLANKET_TOTAL_AMOUNT
       , POH.CLOSED_DATE 
       , POH.COMMENTS 
       , POH.END_DATE 
       , POH.END_DATE_ACTIVE 
       , POH.FIRM_DATE 
       , POH.GOVERNMENT_CONTEXT 
       , POH.MIN_RELEASE_AMOUNT 
       , POH.NOTE_TO_AUTHORIZER 
       , POH.NOTE_TO_RECEIVER 
       , POH.NOTE_TO_VENDOR 
       , POH.PRINT_COUNT 
       , POH.PRINTED_DATE 
       , POH.QUOTE_VENDOR_QUOTE_NUMBER 
       , POH.QUOTE_WARNING_DELAY 
       , POH.QUOTE_WARNING_DELAY_UNIT 
       , POH.RATE 
       , POH.RATE_DATE
       , POH.RATE_TYPE 
       , POH.REPLY_DATE 
       , POH.REVISED_DATE 
       , POH.REVISION_NUM 
       , POH.RFQ_CLOSE_DATE 
       , POH.START_DATE 
       , POH.START_DATE_ACTIVE 
       , POH.VENDOR_ORDER_NUM 
       , POH.AGENT_ID 
       , POH.BILL_TO_LOCATION_ID 
       , POH.FROM_HEADER_ID 
       , POH.PO_HEADER_ID 
       , POH.SHIP_TO_LOCATION_ID 
       , POH.TERMS_ID 
       , POH.VENDOR_CONTACT_ID 
       , POH.VENDOR_ID 
       , POH.VENDOR_SITE_ID 
       , NVL(POH.CLOSED_CODE, 'OPEN') 
       , POH.CURRENCY_CODE 
       , NVL(POH.FIRM_STATUS_LOOKUP_CODE,'N') 
       , POH.FOB_LOOKUP_CODE 
       , POH.FREIGHT_TERMS_LOOKUP_CODE 
       , POH.FROM_TYPE_LOOKUP_CODE 
       , POH.QUOTATION_CLASS_CODE 
       , POH.QUOTE_TYPE_LOOKUP_CODE 
       , POH.REPLY_METHOD_LOOKUP_CODE
       , POH.SHIP_VIA_LOOKUP_CODE 
       , POH.STATUS_LOOKUP_CODE 
       , POH.TYPE_LOOKUP_CODE 
       , POH.USSGL_TRANSACTION_CODE 
       , POH.ACCEPTANCE_REQUIRED_FLAG 
       , POH.APPROVAL_REQUIRED_FLAG 
       , POH.APPROVED_FLAG 
       , DECODE (POH.CANCEL_FLAG
                 ,'I', NULL
                 ,POH.CANCEL_FLAG)
       , POH.CONFIRMING_ORDER_FLAG 
       , POH.ENABLED_FLAG 
       , NVL(POH.FROZEN_FLAG, 'N') 
       , POH.SUMMARY_FLAG 
       , NVL(POH.USER_HOLD_FLAG, 'N') 
       , POH.CREATED_BY 
       , POH.CREATION_DATE
       , POH.LAST_UPDATED_BY
       , POH.LAST_UPDATE_DATE 
       , POH.LAST_UPDATE_LOGIN
       , POH.PROGRAM_APPLICATION_ID
       , POH.PROGRAM_ID 
       , POH.PROGRAM_UPDATE_DATE 
       , POH.REQUEST_ID 
       , POH.SEGMENT1 
       , POH.SEGMENT2 
       , POH.SEGMENT3 
       , POH.SEGMENT4 
       , POH.SEGMENT5 
       , POH.ATTRIBUTE_CATEGORY 
       , POH.ATTRIBUTE1 
       , POH.ATTRIBUTE2 
       , POH.ATTRIBUTE3 
       , POH.ATTRIBUTE4 
       , POH.ATTRIBUTE5 
       , POH.ATTRIBUTE6 
       , POH.ATTRIBUTE7 
       , POH.ATTRIBUTE8 
       , POH.ATTRIBUTE9 
       , POH.ATTRIBUTE10
       , POH.ATTRIBUTE11 
       , POH.ATTRIBUTE12 
       , POH.ATTRIBUTE13 
       , POH.ATTRIBUTE14 
       , POH.ATTRIBUTE15
       , PDTL.TYPE_NAME 
       , PDT.CAN_PREPARER_APPROVE_FLAG 
       , PDT.SECURITY_LEVEL_CODE
       , V.VENDOR_NAME 
       , V.TYPE_1099
       , V.VAT_CODE 
       , VS.VENDOR_SITE_CODE
       , VS.ADDRESS_LINE1 
       , VS.ADDRESS_LINE2 
       , VS.ADDRESS_LINE3 
       , VS.CITY 
       , VS.STATE
       , VS.ZIP
       , VS.COUNTRY 
       , DECODE (VS.PHONE
                ,NULL, NULL
                ,'('||VS.AREA_CODE||') '||VS.PHONE) 
       , DECODE (VS.FAX
                ,NULL, NULL
                ,'('||VS.FAX_AREA_CODE||') '||VS.FAX) 
       , DECODE (VC.LAST_NAME
                ,NULL, NULL
                ,VC.LAST_NAME||', '|| VC.FIRST_NAME) 
       , AT.NAME 
       , HRL1.LOCATION_CODE 
       , HRL2.LOCATION_CODE 
       , NULL 
       , NULL 
       , NULL 
       , NULL
       , NULL
       , TO_DATE(NULL) 
       , NULL 
       , TO_NUMBER(NULL) 
       , TO_NUMBER(NULL) 
       , TO_DATE(NULL) 
       , NULL
       , TO_NUMBER(NULL) 
       , NULL 
       , TO_NUMBER(NULL) 
       , POH.PCARD_ID
       , POH.PRICE_UPDATE_TOLERANCE 
       , POH.PAY_ON_CODE 
       , NULL
       , POH.GLOBAL_AGREEMENT_FLAG 
       , POH.ORG_ID
       , POH.CBC_ACCOUNTING_DATE
       , POH.CONSIGNED_CONSUMPTION_FLAG 
       , POH.CONTERMS_EXIST_FLAG 
       , POH.CONTERMS_ARTICLES_UPD_DATE 
       , POH.CONTERMS_DELIV_UPD_DATE 
       , POH.SHIPPING_CONTROL
       , NULL 
       ,POH.PENDING_SIGNATURE_FLAG 
       ,POH.CHANGE_SUMMARY
       ,XXAH.BATCH_NO
FROM   xx_po_allocation_header XXAH
      ,xx_po_allocation_lines XXAL
      ,PO_DOCUMENT_TYPES_ALL_B PDT
      ,PO_DOCUMENT_TYPES_ALL_TL PDTL
      ,PO_VENDORS V
      ,PO_VENDOR_SITES_ALL VS
      ,PO_VENDOR_CONTACTS VC
      ,AP_TERMS AT
      ,HR_LOCATIONS_ALL_TL HRL1
      ,HR_LOCATIONS_ALL_TL HRL2
      ,PO_HEADERS_ALL POH 
WHERE PDT.DOCUMENT_TYPE_CODE IN ('PO') 
AND   PDT.DOCUMENT_SUBTYPE = POH.TYPE_LOOKUP_CODE 
AND   PDT.DOCUMENT_TYPE_CODE = PDTL.DOCUMENT_TYPE_CODE 
AND   PDT.DOCUMENT_SUBTYPE = PDTL.DOCUMENT_SUBTYPE 
AND   PDTL.LANGUAGE = USERENV('LANG') 
AND   NVL(PDT.ORG_ID, -99) = NVL(PDTL.ORG_ID, -99) 
AND   NVL(PDT.ORG_ID,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1 ,1),' ', NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) = NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ', NULL, SUBSTRB (USERENV('CLIENT_INFO'),1,10))),-99) 
AND   V.VENDOR_ID (+) = POH.VENDOR_ID 
AND   VS.VENDOR_SITE_ID (+) = POH.VENDOR_SITE_ID
AND   VC.VENDOR_CONTACT_ID (+) = POH.VENDOR_CONTACT_ID 
AND   AT.TERM_ID (+) = POH.TERMS_ID 
AND   HRL1.LOCATION_ID (+) = POH.SHIP_TO_LOCATION_ID 
AND   HRL1.LANGUAGE (+) = USERENV('LANG') 
AND   HRL2.LOCATION_ID (+) = POH.BILL_TO_LOCATION_ID 
AND   HRL2.LANGUAGE (+) = USERENV('LANG') 
AND   ((NVL(POH.GLOBAL_AGREEMENT_FLAG,'N') = 'Y' 
AND   EXISTS (
              SELECT 'ENABLED IN CURRENT OU'
              FROM   PO_GA_ORG_ASSIGNMENTS POGA
                     , PO_SYSTEM_PARAMETERS PSP 
              WHERE POH.PO_HEADER_ID = POGA.PO_HEADER_ID 
              AND POGA.ENABLED_FLAG ='Y' 
              AND PSP.ORG_ID IN (POGA.ORGANIZATION_ID, POGA.PURCHASING_ORG_ID) 
              )
AND   POH.AUTHORIZATION_STATUS = 'APPROVED' 
AND   NVL(POH.CLOSED_CODE,'OPEN') <> 'FINALLY CLOSED' 
AND   NVL(POH.CANCEL_FLAG,'N') = 'N' 
AND   NVL(POH.FROZEN_FLAG,'N') = 'N' 
AND   (TRUNC(SYSDATE) BETWEEN NVL(TRUNC(POH.START_DATE) , TRUNC(SYSDATE) -1) 
AND   NVL(TRUNC(POH.END_DATE) , TRUNC(SYSDATE)+1) 
OR    ( TRUNC(POH.START_DATE) IS NOT NULL 
AND   TRUNC(SYSDATE) <= TRUNC(POH.START_DATE)) ) )
OR    NVL(POH.ORG_ID, NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1, 1), ' ', NULL, SUBSTRB(USERENV('CLIENT_INFO'),1, 10))),-99)) = NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1, 1), ' ', NULL, SUBSTRB(USERENV('CLIENT_INFO'),1, 10))),-99) )
AND   XXAH.allocation_header_id(+)=XXAL.allocation_header_id 
AND   POH.po_header_id = XXAL.po_header_id(+);
/
show errors
