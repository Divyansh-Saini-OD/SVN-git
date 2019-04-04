SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_VENDOR_PORTAL_PKG

WHENEVER SQLERROR CONTINUE
create or replace 
PACKAGE BODY XX_AP_VENDOR_PORTAL_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_VENDOR_PORTAL_PKG                                                              |
-- |                                                                                                     |
-- | Description :                                                                                       |
-- | Rice ID     :                                                                                       |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      11-Jul-2017  Havish Kasina    Initial Version                                              |
-- | 2.0      11-Aug-2017  Avinash Baddam   Fixed the type object/table initialization issue.	           |
-- | 3.0      25-Jun-2018  Ragni Gupta      Modified cursor query for invoice_payment_staus to include   |
--                                          paid and accounted invoices as well# NAIT-45779              |
-- | 4.0      12-Jul-2018  Prabeethsoy Nair  Added check_info_inquiry_mul_vend procedure as              |
-- |                                        part of NAIT-49748                                           |
-- | 5.0      13-Jul-2018  Ragni Gupta      Modified inv_payment_status and inv_payment_status for multipl
--                                          vendors to include invoice without POs#NAIT-49750            |
-- | 6.0      24-Jul-2018  Ragni Gupta      Modified query in chargeback details inquiry, NAIT-50752     |
-- | 6.1      27-Jul-2018  Ragni Gupta      Modified query in chargeback details inquiry, NAIT-50752     |
-- | 6.2      08-Aug-2018  Ragni Gupta      Modified query in invoice and payment status to pick DM, NAIT-47685
-- | 6.3      25-Oct-2018  Madhu Bolli      Modified RTV hdr and detail to stop calling legacy db,NAIT-60687 |
-- +=====================================================================================================+
g_proc              VARCHAR2(80)    := NULL;
g_debug             VARCHAR2(1)     := 'N';
gc_success          VARCHAR2(100)   := 'SUCCESS';
gc_failure          VARCHAR2(100)   := 'FAILURE';

-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE            := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE          := FND_GLOBAL.USER_NAME;

BEGIN

  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXFIN'
        ,p_program_type            => 'LOG'
        ,p_attribute15             => 'XX_AP_VENDOR_PORTAL_PKG'
        ,p_attribute16             => g_proc
        ,p_program_id              => 0
        ,p_module_name             => 'AP'
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg  IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.USER_NAME;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXFIN'
      ,p_program_type            => 'ERROR'
      ,p_attribute15             => 'XX_AP_VENDOR_PORTAL_PKG'
      ,p_attribute16             => g_proc
      ,p_program_id              => 0
      ,p_module_name             => 'AP'
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);

END log_error;
-- +===================================================================+
-- | Name  : get_po_loc                                                |
-- | Description     : The get_po_loc function will return the location|
-- |                   number for the respective PO Header ID          |
-- |                                                                   |
-- | Parameters      : p_po_header_id        		                   |
-- +===================================================================+
FUNCTION get_po_loc(p_po_header_id  IN  NUMBER)
  RETURN VARCHAR2
IS
lc_location_number   VARCHAR2(30) := NULL;

BEGIN

   SELECT LTRIM(hl.attribute1,'0')
     INTO lc_location_number
     FROM po_headers_all pha,
          hr_locations hl
    WHERE po_header_id = p_po_header_id -- 514722
      AND pha.ship_to_location_id = hl.location_id;

   RETURN lc_location_number;
EXCEPTION
   WHEN OTHERS
   THEN
   lc_location_number := NULL;
   log_error('Error while getting the location number '||substr(sqlerrm,1,100));
   RETURN lc_location_number;
END;

-- +===================================================================+
-- | Name  : get_po_num                                                |
-- | Description     : The get_po_num function will return the PO      |
-- |                   number for the respective PO Header ID          |
-- |                                                                   |
-- | Parameters      : p_po_header_id        		               |
-- +===================================================================+
FUNCTION get_po_num(p_po_header_id  IN  NUMBER)
  RETURN VARCHAR2
IS
lc_po_number   VARCHAR2(30):= NULL;
BEGIN
   SELECT SUBSTR(segment1,1,7)
     INTO lc_po_number
     FROM po_headers_all
	WHERE po_header_id = p_po_header_id;

	RETURN lc_po_number;
EXCEPTION
  WHEN OTHERS
  THEN
    lc_po_number:= NULL;
	log_error('Error while getting the PO Number '||substr(sqlerrm,1,100));
END;


-- +===================================================================+
-- | Name  : invoice_payment_status                                    |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_invoice_number                                |
-- |                   p_invoice_date_from                             |
-- |                   p_invoice_date_to                               |
-- |                   p_po_number                                     |
-- +===================================================================+
PROCEDURE invoice_payment_status(p_country        	     IN  VARCHAR2,
                                 p_vendor_number         IN  VARCHAR2,
				                 p_invoice_number        IN  VARCHAR2,
				                 p_invoice_date_from     IN  VARCHAR2,
				                 p_invoice_date_to       IN  VARCHAR2,
				                 p_po_number             IN  VARCHAR2,
				                 p_inv_pymt_status_obj   OUT XX_AP_INV_PYMT_STATUS_OBJ_TYPE)
IS
    CURSOR inv_payment_status_cur IS
    ----Added below query for NAIT-45779 by Ragni, 25-JUN-18
SELECT xx_ap_inv_pymt_status_rec_type((CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
  NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)) ,
  ai.invoice_num,
  ai.invoice_date,
  ai.amount_applicable_to_discount,
  (ai.amount_applicable_to_discount-ai.invoice_amount) ,
  ai.discount_amount_taken,
  (ai.amount_applicable_to_discount-ai.discount_amount_taken -(ai.amount_applicable_to_discount-ai.invoice_amount)) ,
  apsa.due_date,
  NVL(aca.check_number,0) ,
  NVL(aca.amount,0) ,
  aca.check_date,
  -- SUBSTR(ai.description,9),
  LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
  -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
  ai.attribute11
  ||'-'
  ||LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
  ai.voucher_num)
FROM ap_invoices_all ai ,
  ap_supplier_sites_all pvsa ,
  ap_payment_schedules_all apsa ,
  ap_invoice_payments_all aipa,
  ap_checks_all aca
WHERE 1=1
AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
AND (p_invoice_number IS NULL OR ai.invoice_num like p_invoice_number)
AND ai.wfapproval_status IN ('MANUALLY APPROVED','NOT REQUIRED','WFAPPROVED')
AND ai.invoice_num NOT LIKE '%BUOI%'
--AND DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_AP_VENDOR_PORTAL_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))) = NVL(:p_po_number,DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_AP_VENDOR_PORTAL_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))))
AND DECODE(ai.org_id, 403,'CAN','USA')      = p_country
AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0')  = LPAD(p_vendor_number,10,'0')
AND ai.vendor_site_id = pvsa.vendor_site_id
AND ai.invoice_id     = apsa.invoice_id
AND ai.invoice_id     = aipa.invoice_id
AND aipa.check_id     = aca.check_id
AND EXISTS (SELECT 1 from po_headers_All
where po_header_id=ai.po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 from po_headers_All
where po_header_id=ai.quick_po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 FROM dual
WHERE (ai.po_header_id IS NULL OR ai.quick_po_header_id IS NULL)
AND p_po_number IS NULL
)
UNION ALL
SELECT xx_ap_inv_pymt_status_rec_type((CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
  NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)) ,
  ai.invoice_num,
  ai.invoice_date,
  ai.amount_applicable_to_discount,
  (ai.amount_applicable_to_discount-ai.invoice_amount),
  ai.discount_amount_taken,
  (ai.amount_applicable_to_discount-ai.discount_amount_taken -(ai.amount_applicable_to_discount-ai.invoice_amount)),
  apsa.due_date,
  0 ,
  0 , --NVL(aca.amount,0),
  NULL , --aca.check_date,
  -- SUBSTR(ai.description,9),
  LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
   -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
  ai.attribute11
  ||'-'
  ||LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
    ai.voucher_num)
FROM ap_invoices_all ai ,
  ap_supplier_sites_all pvsa ,
  ap_payment_schedules_all apsa ,
  xla_events xev,
  xla_transaction_entities xte
WHERE 1 =1
AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
AND (p_invoice_number IS NULL OR ai.invoice_num like p_invoice_number)
AND ai.wfapproval_status IN ('MANUALLY APPROVED','NOT REQUIRED','WFAPPROVED')
AND ai.invoice_num NOT LIKE '%BUOI%'
--AND DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_AP_VENDOR_PORTAL_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))) = NVL(:p_po_number,DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_AP_VENDOR_PORTAL_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))))
AND DECODE(ai.org_id, 403,'CAN','USA')    = p_country
AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0')  = LPAD(p_vendor_number,10,'0')
AND ai.vendor_site_id  = pvsa.vendor_site_id
AND ai.invoice_id      = apsa.invoice_id
AND xte.source_id_int_1=ai.invoice_id
AND xte.entity_code    = 'AP_INVOICES'
AND xte.application_id = 200
AND xev.entity_id      =xte.entity_id
AND xev.application_id =xte.application_id
--AND xev.event_type_code = 'INVOICE VALIDATED' Commented since it was restricting only debit/credit memos -- Ragni Gupta 08-Aug-18
AND (xev.event_type_code = 'INVOICE VALIDATED' or xev.event_type_code = 'DEBIT MEMO VALIDATED' or xev.event_type_code = 'CREDIT MEMO VALIDATED')
AND xev.process_status_code = 'P'
AND xev.event_status_code   ='P'
AND not exists(SELECT 1 from ap_invoice_payments_all aipa
WHERE aipa.invoice_id = ai.invoice_id)
AND EXISTS (SELECT 1 from po_headers_All
where po_header_id=ai.po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 from po_headers_All
where po_header_id=ai.quick_po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 FROM dual
WHERE (ai.po_header_id IS NULL OR ai.quick_po_header_id IS NULL)
AND p_po_number IS NULL
);
--Commented below query for NAIT-45779 by Ragni, 25-JUN-18
/*
  SELECT xx_ap_inv_pymt_status_rec_type(
    (CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
	        			   NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),
            				   ai.invoice_num,
            				   ai.invoice_date,
            				   ai.amount_applicable_to_discount,
           				   (ai.amount_applicable_to_discount-ai.invoice_amount),
            				   ai.discount_amount_taken,
                                           (ai.amount_applicable_to_discount-ai.discount_amount_taken
                                            -(ai.amount_applicable_to_discount-ai.invoice_amount)),
            				   apsa.due_date,
            				   NVL(aca.check_number,0),
            				   NVL(aca.amount,0),
            				   aca.check_date,
            				   -- SUBSTR(ai.description,9),
                               LPAD(get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
            				   -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
							   ai.attribute11||'-'||LPAD(get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
            				   ai.voucher_num)
      FROM  ap_invoices_all ai
	   ,ap_supplier_sites_all pvsa
	   ,ap_payment_schedules_all apsa
	   ,ap_invoice_payments_all aipa
	   ,ap_checks_all aca
     WHERE ai.invoice_num = NVL(p_invoice_number,ai.invoice_num)
       AND DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id)))
	        = NVL(p_po_number,DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))))
       AND DECODE(ai.org_id, 403,'CAN','USA') = p_country
       AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0') = LPAD(p_vendor_number,10,'0')
       AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
       AND ai.vendor_site_id = pvsa.vendor_site_id
       AND ai.invoice_id = apsa.invoice_id
       AND ai.invoice_id = aipa.invoice_id
       AND aipa.check_id = aca.check_id;*/
  i NUMBER;
  lc_debug_flag VARCHAR2(1);
BEGIN
    xla_security_pkg.set_security_context(602);
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;

    --08/11/17 avinash changes to load object type
    OPEN inv_payment_status_cur;
    FETCH inv_payment_status_cur BULK COLLECT INTO p_inv_pymt_status_obj;
    CLOSE inv_payment_status_cur;

EXCEPTION
WHEN OTHERS
THEN
   log_debug_msg('Exception Message while we are getting the Invoice Payment Status....'||SQLERRM);
END;

-- +===================================================================+
-- | Name  : check_info_inquiry                                        |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_invoice_number                                |
-- |                   p_check_date_from                               |
-- |                   p_check_date_to                                 |
-- |                   p_check_number                                  |
-- +===================================================================+
PROCEDURE check_info_inquiry(p_country                IN  VARCHAR2,
                             p_vendor_number  		  IN  VARCHAR2,
			     p_invoice_number         IN  VARCHAR2,
			     p_check_date_from        IN  VARCHAR2,
			     p_check_date_to          IN  VARCHAR2,
			     p_check_number           IN  VARCHAR2,
			     p_chk_info_inquiry_obj   OUT XX_CHK_INF_INQUIRY_OBJ_TYPE)
IS
  CURSOR check_info_cur IS
  --Below query added to display only check information at header level for NAIT-49748 by Ragni Gupta, 12-Jul-18
   SELECT xx_chk_inf_inquiry_rec_type((CASE WHEN aca.org_id = 403 THEN 'CAN' ELSE 'USA' END),
	      				NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),
          				NVL(aca.check_number,0),
          				aca.check_date,
          				aca.status_lookup_code,
                  NVL(aca.amount,0),
					NULL,-- ai.discount_amount_taken,
					NULL,-- ai.invoice_num,
					NULL,--ai. amount,
					aca.vendor_name,
					aca.address_line1,
					aca.address_line2,
					aca.city,
					aca.state,
					aca.zip)
     FROM ap_supplier_sites_all pvsa
	 ,ap_checks_all aca
    WHERE 1=1
      AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0') = LPAD(p_vendor_number,10,'0')
      AND aca.check_number = NVL(p_check_number,aca.check_number)
      AND DECODE(aca.org_id, 403,'CAN','USA') = p_country
      AND aca.check_date BETWEEN NVL(to_date(p_check_date_from,'YYYY-MM-DD'),aca.check_date) AND NVL(to_date(p_check_date_to,'YYYY-MM-DD'),aca.check_date)
      AND pvsa.vendor_site_id = aca.vendor_site_id
      AND  EXISTS (SELECT 1 FROM ap_invoice_payments_all aipa, ap_invoices_all aia
                 WHERE 1=1
                   AND aia.invoice_id = aipa.invoice_id
                             AND aipa.check_id = aca.check_id
                             AND aia.invoice_num = NVL(p_invoice_number, aia.invoice_num));


      --Commented below query for NAIT-49748 by Ragni Gupta, 12-Jul-18
    /*SELECT xx_chk_inf_inquiry_rec_type((CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
	      				NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),
          				NVL(aca.check_number,0),
          				aca.check_date,
          				aca.status_lookup_code,
					NVL(aca.amount,0),
					ai.discount_amount_taken,
					ai.invoice_num,
					aipa.amount,
					aca.vendor_name,
					aca.address_line1,
					aca.address_line2,
					aca.city,
					aca.state,
					aca.zip)
     FROM ap_invoices_all ai
  	 ,ap_supplier_sites_all pvsa
	 ,ap_payment_schedules_all apsa
	 ,ap_invoice_payments_all aipa
	 ,ap_checks_all aca
    WHERE ai.invoice_num = NVL(p_invoice_number,ai.invoice_num)
      AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0') = LPAD(p_vendor_number,10,'0')
      AND aca.check_number = NVL(p_check_number,aca.check_number)
      AND DECODE(ai.org_id, 403,'CAN','USA') = p_country
      AND aca.check_date BETWEEN NVL(to_date(p_check_date_from,'YYYY-MM-DD'),aca.check_date) AND NVL(to_date(p_check_date_to,'YYYY-MM-DD'),aca.check_date)
      AND ai.vendor_site_id = pvsa.vendor_site_id
      AND ai.invoice_id = apsa.invoice_id
      AND ai.invoice_id = aipa.invoice_id
      AND aipa.check_id = aca.check_id;*/
  lc_debug_flag VARCHAR2(1);
BEGIN
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;

    --08/11/17 avinash changes to load object type
    OPEN check_info_cur;
    FETCH check_info_cur BULK COLLECT INTO p_chk_info_inquiry_obj;
    CLOSE check_info_cur;
EXCEPTION
WHEN OTHERS
THEN
    log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
END;

-- +===================================================================+
-- | Name  : check_details_inquiry                                        |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_check_number                                  |
-- +===================================================================+
PROCEDURE check_details_inquiry(
			     p_check_number           IN  VARCHAR2,
			     p_check_details_obj   OUT xx_ap_check_details_obj_type)
IS
  CURSOR check_details_cur IS
    SELECT xx_ap_check_details_rec_type(ai.invoice_num,
                                       ai.invoice_date,
                                       ai.amount_applicable_to_discount,
                                       (ai.amount_applicable_to_discount-ai.invoice_amount),
                                       ai.discount_amount_taken,
                                       (ai.amount_applicable_to_discount-ai.discount_amount_taken-(ai.amount_applicable_to_discount-ai.invoice_amount)),
                                       ai.description )
     FROM  ap_invoices_all ai
          ,ap_supplier_sites_all pvsa
          ,ap_payment_schedules_all apsa
          ,ap_invoice_payments_all aipa
          ,ap_checks_all aca
    WHERE 1=1
      AND aca.check_number = p_check_number
      AND aipa.check_id = aca.check_id
      AND ai.invoice_id = aipa.invoice_id
      AND pvsa.vendor_site_id=ai.vendor_site_id
      AND apsa.invoice_id=ai.invoice_id
      ;

  lc_debug_flag VARCHAR2(1);
BEGIN
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;

    --08/11/17 avinash changes to load object type
    OPEN check_details_cur;
    FETCH check_details_cur BULK COLLECT INTO p_check_details_obj;
    CLOSE check_details_cur;
EXCEPTION
WHEN OTHERS
THEN
    log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
END;

PROCEDURE chargeback_details_inquiry(
			     p_invoice_number           IN  VARCHAR2,
			     p_chargeback_details_obj   OUT XX_AP_CHRGBK_DETAILS_OBJ_TYPE)
IS
  CURSOR chargeback_details_cur IS
    SELECT  XX_AP_CHRGBK_DETAILS_REC_TYPE(CASE WHEN aildm.description like 'QTY%' THEN 'SH-SHORTAGE' WHEN aildm.description like 'Price%' THEN 'PO-PRICING' ELSE NULL END,-- chargeback_type,
        (
        SELECT DISTINCT MC.SEGMENT3
              FROM MTL_ITEM_CATEGORIES MIC,
                MTL_CATEGORIES_B MC,
                MTL_SYSTEM_ITEMS_B MSIB
              WHERE MSIB.INVENTORY_ITEM_ID = MIC.INVENTORY_ITEM_ID
              AND MIC.CATEGORY_ID          = MC.CATEGORY_ID
              AND MSIB.inventory_item_id   = aildm.inventory_item_id
              AND MSIB.ORGANIZATION_ID     = pla.ship_to_organization_id
              AND MC.SEGMENT3             IS NOT NULL ),-- dept,
          msi.segment1,-- sku,
          pl.vendor_product_num,-- vendor_product_code,
          msi.description,-- desc,
          pla.quantity_received,
         --aildm.quantity_invoiced, --Commented as a part of NAIT-50752 by Ragni, 24-Jul-18
		  ail.quantity_invoiced, --take qty invoiced from original invoice, NAIT-50752 by Ragni, 24-Jul-18
		  pl.unit_price,
          --aildm.unit_price, --Commented as a part of NAIT-50752 by Ragni, 24-Jul-18
		  ail.unit_price,     --take unit price from original invoice, NAIT-50752 by Ragni, 24-Jul-18
          aildm.amount,   -- (aidm.amount_applicable_to_discount-aidm.invoice_amount),-- inv_adj_amt,  NAIT-50752  6.1 by Madhu, 27-Jul-18
          ph.segment1,-- po_number,
          aca.check_number)
      FROM  ap_invoice_lines_all ail
	       ,ap_invoices_all ai
		   ,mtl_system_items_b msi
           ,po_line_locations_all pla
           ,po_headers_all ph
           ,po_lines_all pl
           ,ap_checks_all aca
           ,ap_invoice_payments_all aipa
           ,ap_invoice_lines_all aildm
           ,ap_invoices_all aidm
     WHERE aidm.invoice_num = p_invoice_number
       AND aildm.invoice_id =aidm.invoice_id
       AND aipa.invoice_id=aildm.invoice_id
       AND aca.check_id=aipa.check_id
       and ph.po_header_id=aidm.quick_po_header_id
       AND pl.po_header_id=ph.po_header_id
       AND aildm.inventory_item_id=pl.item_id
       AND msi.inventory_item_id=aildm.inventory_item_id
       AND msi.organization_id=pla.ship_to_organization_id
       AND pl.po_header_id=pla.po_header_id
       AND pl.po_line_id=pla.po_line_id
       AND ai.invoice_num = SUBSTR(aidm.invoice_num, 0, LENGTH (aidm.invoice_num)-2)
	   AND ail.invoice_id = ai.invoice_id
	   AND ail.line_number = TO_NUMBER(aildm.attribute5);

  lc_debug_flag VARCHAR2(1);
BEGIN
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;

    OPEN chargeback_details_cur;
    FETCH chargeback_details_cur BULK COLLECT INTO p_chargeback_details_obj;
    CLOSE chargeback_details_cur;
EXCEPTION
WHEN OTHERS
THEN
    log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
END;
-- +===================================================================+
-- | Name  : rtv_details_legacy	                                       |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_document_number                               |
-- |                   p_document_date_from                            |
-- |                   p_document_date_to                              |
-- |                   p_freight_bill_number                           |
-- +===================================================================+
/*
PROCEDURE rtv_details_legacy(p_country         IN  VARCHAR2,
                      p_vendor_number          IN  VARCHAR2,
                      p_document_number        IN  VARCHAR2,
                      p_document_date_from     IN  VARCHAR2,
                      p_document_date_to       IN  VARCHAR2,
                      p_freight_bill_number    IN  VARCHAR2,
                      p_rtv_dtls_obj   	      OUT XX_AP_RTV_DTL_OBJ_TYPE)
IS


   CURSOR legacy_rtv_details_cur IS
	SELECT
		'USA'  country
		,AP_VENDOR vendor_num
		,LTRIM(RTRIM(aph.invoice_nbr)) document_num
		,aph.invoice_dt document_date
		,NULL freight_bill_num
		,aph.loc_id location
		,NULL freight_carrier
		,LTRIM(RTRIM(REPLACE(aph.invoice_nbr,'RTV', ''))) rtv_nbr
	FROM OD.APAYHDR@legacydb2 aph
	WHERE 1=1
	  AND ap_vendor  = LPAD(p_vendor_number,9,'0')
	  AND (p_document_number IS NULL OR LTRIM(RTRIM(invoice_nbr)) = p_document_number)
	  AND invoice_dt between NVL(to_date(p_document_date_from,'YYYY-MM-DD'), invoice_dt) and NVL(to_date(p_document_date_to,'YYYY-MM-DD'), invoice_dt)
	  AND (p_freight_bill_number IS NULL OR
			EXISTS (SELECT 'EXISTS'
					FROM od.frtbill@legacydb2
					WHERE out_frt_bill_nbr = p_freight_bill_number
					  AND ship_doc_nbr = LTRIM(RTRIM(REPLACE(aph.invoice_nbr,'RTV', '')))
	UNION
					SELECT 'EXISTS'
					FROM od.frtbill_hist@legacydb2
					WHERE out_frt_bill_nbr = p_freight_bill_number
					  AND ship_doc_nbr = LTRIM(RTRIM(REPLACE(aph.invoice_nbr,'RTV', '')))
					)
	      );


   -- Get Freight Bill Number
   CURSOR lcu_freightbill_cur(c_invoice_num VARCHAR2, c_carrier_id NUMBER) IS
      SELECT LISTAGG (
            rtrim(ltrim(fb.out_frt_bill_nbr)), ' '
          ) WITHIN GROUP (
                ORDER BY fb.out_frt_bill_nbr ASC
           ) as freight_bill_num
        FROM  od.frtbill@legacydb2 fb
       WHERE fb.ship_doc_nbr       = c_invoice_num
         AND fb.carrier_id         = c_carrier_id
		 AND fb.out_frt_bill_nbr = NVL(p_freight_bill_number , fb.out_frt_bill_nbr)
       ORDER BY fb.out_frt_bill_nbr ASC;

   TYPE lcu_freightbill IS TABLE OF lcu_freightbill_cur%ROWTYPE
   INDEX BY PLS_INTEGER;

   

   CURSOR lcu_freightbill_hist_cur(c_invoice_num VARCHAR2,c_carrier_id NUMBER) IS
      SELECT LISTAGG (
            rtrim(ltrim(fb.out_frt_bill_nbr)), ' '
          ) WITHIN GROUP (
                ORDER BY fb.out_frt_bill_nbr ASC
           ) as freight_bill_num
        FROM  od.frtbill_hist@legacydb2 fb
       WHERE fb.ship_doc_nbr = c_invoice_num
         AND fb.carrier_id   = c_carrier_id
		 AND fb.out_frt_bill_nbr = NVL(p_freight_bill_number , fb.out_frt_bill_nbr)
       ORDER BY FB.out_frt_bill_nbr ASC;

   

   TYPE legacy_rtv_details IS TABLE OF legacy_rtv_details_cur%ROWTYPE
   INDEX BY PLS_INTEGER;

   legacy_rtv_details_tab   LEGACY_RTV_DETAILS;
   lcu_freightbill_tab      LCU_FREIGHTBILL;
   -- lcu_freightbill_hist_tab LCU_FREIGHTBILL;
   f_indx		    NUMBER;
   indx		     	NUMBER;
   lc_debug_flag   	VARCHAR2(1);
   lc_carrier_name 	VARCHAR2(100);
   ln_carrier_id	NUMBER;
   lcu_freightbill_num 	VARCHAR2(100);

   lc_legacy_invoice_num VARCHAR2(100);
BEGIN

   DBMS_OUTPUT.PUT_LINE('BEGIN - rtv_details_legacy');
   lc_debug_flag := 'Y';
   log_debug_msg ('Debug Flag :'||lc_debug_flag);

   IF (lc_debug_flag = 'Y')
   THEN
        g_debug := 'Y';
   ELSE
        g_debug := 'N';
   END IF;

   p_rtv_dtls_obj := XX_AP_RTV_DTL_OBJ_TYPE();

   OPEN legacy_rtv_details_cur;
   FETCH legacy_rtv_details_cur BULK COLLECT INTO legacy_rtv_details_tab;
   CLOSE legacy_rtv_details_cur;

   DBMS_OUTPUT.PUT_LINE('Retrieve Legacy Invoices -  legacy_rtv_details_tab.count is '||legacy_rtv_details_tab.count);

   FOR indx IN 1..legacy_rtv_details_tab.COUNT
   LOOP
      BEGIN
         -- lc_legacy_invoice_num := SUBSTR(legacy_rtv_details_tab(indx).document_num,4,LENGTH(legacy_rtv_details_tab(indx).document_num));
		 lc_legacy_invoice_num := REPLACE(legacy_rtv_details_tab(indx).document_num,'RTV', '');
         DBMS_OUTPUT.PUT_LINE('Retrieve Carrier Name for the invoice_num '||lc_legacy_invoice_num);

		 BEGIN
			lc_legacy_invoice_num := TO_NUMBER(lc_legacy_invoice_num);
		 EXCEPTION
		   WHEN VALUE_ERROR THEN
				 DBMS_OUTPUT.PUT_LINE('Skipped the invoice '||lc_legacy_invoice_num);
		      CONTINUE;
		 END;

          --get carrier name
          BEGIN
   	        SELECT ltrim(rtrim(carrier_name)),rtvh.carrier_id
   	          INTO  lc_carrier_name,ln_carrier_id
   	          FROM od.rtvdoch@legacydb2 rtvh,
   	               od.carrier@legacydb2 car
   	         WHERE rtvh.rtv_nbr   = lc_legacy_invoice_num
   	           AND car.carrier_id = rtvh.carrier_id
			   AND rownum <= 1
			 ORDER BY SHIP_DT;

             DBMS_OUTPUT.PUT_LINE('Successfully Retrieved Carrier Name from legacy db2');

          EXCEPTION
          WHEN no_data_found
		  THEN
        
   	        BEGIN
   	           SELECT ltrim(rtrim(carrier_name)),rtvh.carrier_id
   	             INTO  lc_carrier_name,ln_carrier_id
   	             FROM od.rtvdoch_hist@legacydb2 rtvh,
   	                  od.carrier@legacydb2 car
   	            WHERE rtvh.rtv_nbr  = lc_legacy_invoice_num
   	              AND car.carrier_id = rtvh.carrier_id
				  AND rownum <= 1
				ORDER BY SHIP_DATE;
   	        EXCEPTION
   	        WHEN no_data_found THEN
                DBMS_OUTPUT.PUT_LINE('Carrier not found in both legacy and its history for invoice number : '||lc_legacy_invoice_num);
   	           lc_carrier_name := null;
   	           ln_carrier_id := NULL;
             END;
        
		       DBMS_OUTPUT.PUT_LINE('Carrier not found in both legacy and its history for invoice number : '||lc_legacy_invoice_num);
   	           lc_carrier_name := null;
   	           ln_carrier_id := NULL;
          END;

          DBMS_OUTPUT.PUT_LINE('After Carrier retrieve from legacy -  ln_carrier_id is '||ln_carrier_id);

          --get freight bill number
          lcu_freightbill_num := NULL;
          OPEN lcu_freightbill_cur(lc_legacy_invoice_num,ln_carrier_id);
          FETCH lcu_freightbill_cur INTO lcu_freightbill_num;
          CLOSE lcu_freightbill_cur;

          DBMS_OUTPUT.PUT_LINE('After legacy freight retrive  -  lcu_freightbill_num is '||lcu_freightbill_num);

		
          IF lcu_freightbill_num IS NULL THEN
             OPEN lcu_freightbill_hist_cur(lc_legacy_invoice_num,ln_carrier_id);
             FETCH lcu_freightbill_hist_cur INTO lcu_freightbill_num;
             CLOSE lcu_freightbill_hist_cur;
          END IF;
        
          DBMS_OUTPUT.PUT_LINE('After legacy history freight retrive  -  lcu_freightbill_num is '||lcu_freightbill_num);

		  -- If 'freight bill' value is input and if the frieghtQuery doesnt return match value then no need to add to the output.
		  IF (p_freight_bill_number is NOT NULL AND  lcu_freightbill_num IS NULL)
		   THEN
				CONTINUE;
		  END IF;

          p_rtv_dtls_obj.extend;
          p_rtv_dtls_obj(indx) := xx_ap_rtv_dtl_rec_type('USA'
				    ,legacy_rtv_details_tab(indx).vendor_num
				    ,legacy_rtv_details_tab(indx).document_num
				    ,legacy_rtv_details_tab(indx).document_date
				    ,lcu_freightbill_num
				    ,legacy_rtv_details_tab(indx).location
				    ,lc_carrier_name);

         DBMS_OUTPUT.PUT_LINE('After a record retrieve from legacy db.');

      END;
   END LOOP; --legacy_rtv_details_tab

   DBMS_OUTPUT.PUT_LINE('END - rtv_details');

EXCEPTION
WHEN OTHERS
THEN
    --log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Exception Message while we are getting the rtv_details inquiry....'||SQLERRM);
END rtv_details_legacy;
*/
-- +===================================================================+
-- | Name  : RTV_DETAILS	                                       |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_document_number                               |
-- |                   p_document_date_from                            |
-- |                   p_document_date_to                              |
-- |                   p_freight_bill_number                           |
-- +===================================================================+
PROCEDURE rtv_details(p_country                IN  VARCHAR2,
                      p_vendor_number          IN  VARCHAR2,
                      p_document_number        IN  VARCHAR2,
                      p_document_date_from     IN  VARCHAR2,
                      p_document_date_to       IN  VARCHAR2,
                      p_freight_bill_number    IN  VARCHAR2,
                      p_rtv_dtls_obj   	      OUT XX_AP_RTV_DTL_OBJ_TYPE)
IS
   CURSOR rtv_details_cur IS
      SELECT XX_AP_RTV_DTL_REC_TYPE('USA',
      				    vendor_num,
             			    rtv_number,
             			    creation_date,
 		                    freight_bill_num1||freight_bill_num2||freight_bill_num3||
             			    freight_bill_num4||freight_bill_num5||freight_bill_num6||
             			    freight_bill_num7||freight_bill_num8||freight_bill_num9||
             			    freight_bill_num10,
                          	    location,
             			    carrier_name)
        FROM xx_ap_rtv_hdr_attr
       WHERE rtv_number = NVL(p_document_number,rtv_number)
         AND vendor_num = NVL(p_vendor_number,vendor_num)
         AND creation_date BETWEEN NVL(to_date(p_document_date_from,'YYYY-MM-DD'),creation_date) AND NVL(to_date(p_document_date_to,'YYYY-MM-DD'),creation_date)
         AND ((p_freight_bill_number IS NULL) OR (freight_bill_num1 = p_freight_bill_number OR
              freight_bill_num2 = p_freight_bill_number OR
              freight_bill_num3 = p_freight_bill_number OR
              freight_bill_num4 = p_freight_bill_number OR
              freight_bill_num5 = p_freight_bill_number OR
              freight_bill_num6 = p_freight_bill_number OR
              freight_bill_num7 = p_freight_bill_number OR
              freight_bill_num8 = p_freight_bill_number OR
              freight_bill_num9 = p_freight_bill_number OR
              freight_bill_num10 = p_freight_bill_number));

   indx		     	    NUMBER;
   f_indx		    NUMBER;

   lc_debug_flag   	VARCHAR2(1);
   l_rtv_dtls_obj   XX_AP_RTV_DTL_OBJ_TYPE;

BEGIN

   DBMS_OUTPUT.PUT_LINE('BEGIN - rtv_details');
   lc_debug_flag := 'Y';
   log_debug_msg ('Debug Flag :'||lc_debug_flag);
   IF (lc_debug_flag = 'Y')
   THEN
        g_debug := 'Y';
   ELSE
        g_debug := 'N';
   END IF;
   OPEN rtv_details_cur;
   FETCH rtv_details_cur BULK COLLECT INTO p_rtv_dtls_obj;
   CLOSE rtv_details_cur;

   DBMS_OUTPUT.PUT_LINE('EBS Data count - p_rtv_dtls_obj.count is '||p_rtv_dtls_obj.count);

	/** Begin of 6.3
   -- If the input documentNumber is not null and results returned from EBS tables then not required further.
   IF (NOT (p_document_number IS NOT NULL and p_rtv_dtls_obj.count <> 0)) THEN

	   rtv_details_legacy(p_country
						  ,p_vendor_number
						  ,p_document_number
						  ,p_document_date_from
						  ,p_document_date_to
						  ,p_freight_bill_number
						  ,l_rtv_dtls_obj
	   );

	   IF l_rtv_dtls_obj.count >= 0 THEN

		indx := p_rtv_dtls_obj.count;
		DBMS_OUTPUT.PUT_LINE('l_rtv_dtls_obj.count is '||l_rtv_dtls_obj.count);
		FOR i in 1..l_rtv_dtls_obj.count
		LOOP
				DBMS_OUTPUT.PUT_LINE('In Loop '||i||' with index '||indx);
				p_rtv_dtls_obj.extend;
				p_rtv_dtls_obj(indx + i) := l_rtv_dtls_obj(i);
		END LOOP;

	   END IF;  -- IF l_rtv_dtls_obj.count >= 0
	END IF;   -- IF (NOT (p_document_number IS NOT NULL
	End of 6.3 **/

   DBMS_OUTPUT.PUT_LINE('END - rtv_details');

EXCEPTION
WHEN OTHERS
THEN
    --log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Exception Message while we are getting the rtv_details inquiry....'||SQLERRM);
END rtv_details;

-- +===================================================================+
-- | Name  : RTV_LINE_DETAILS	                                       |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      :          |
-- |                   p_document_number                               |
-- +===================================================================+
PROCEDURE rtv_line_details(
    p_document_number     IN VARCHAR2,
    p_rtv_dtls_obj OUT XX_AP_RTV_DETAILS_OBJ_TYPE)
IS
  CURSOR rtv_details_cur
  IS
        SELECT XX_AP_RTV_DETAILS_REC_TYPE(xrh.location, xrl.sku, xrl.vendor_product_code, xrl.item_description,
										xrl.qty,
										xrl.cost,
										xrl.line_amount,
										NVL(xrl.adjusted_qty,'0'),
									 	NVL(xrl.adjusted_cost,'0.00'),
										NVL(xrl.adjusted_line_amount,'0.00'),
										xrl.worksheet_num,
										xrl.rga_number,
										xrh.carrier_name,
										xrh.freight_bill_num1,
										xrh.freight_bill_num2,
										xrh.freight_bill_num3,
										xrh.freight_bill_num4,
										xrh.freight_bill_num5)
    FROM xx_ap_rtv_hdr_attr xrh,
      xx_ap_rtv_lines_attr xrl
    WHERE xrh.invoice_num = p_document_number
    AND xrh.header_id    =xrl.header_id;
/*
  CURSOR rtv_legacy_details_cur
  IS
  SELECT NULL dept, --?
      apdd.sku,
      NULL vendor_product_code, --?
      apd.descr,
      apdd.rtv_qty,
      apdd.unit_cost cost,       --?
	    apdd.extended_cost ext_cost,
      '0' allow_qty, --allow quantity
      '0.00' allow_cost, --apd.gross_amt/apd.invoice_qty allow_cost,   --?
      '0.00'allow_ext_cost, --apd.gross_amt/apd.invoice_qty allow_ext cost, --?
      NULL,                                     -- worksheet_nbr,
      rtvh.rga_nbr,
      car.carrier_id,
      ltrim(rtrim(car.carrier_name)) carrier_name,
      LTRIM(RTRIM(REPLACE(aph.invoice_nbr,'RTV', ''))) rtv_nbr
    FROM od.apayhdr@legacydb2 aph,
      od.apaydtl@legacydb2 apd,
	    od.rtvdocd@legacydb2 apdd,
      od.rtvdoch@legacydb2 rtvh,
      od.carrier@legacydb2 car
    WHERE 1              =1
    AND aph.invoice_nbr  = p_document_number
    AND apd.voucher_nbr  =aph.voucher_nbr
    AND apdd.rtv_nbr  =rtvh.rtv_nbr
    AND rtvh.rtv_nbr(+)  =LTRIM(RTRIM(REPLACE(aph.invoice_nbr,'RTV', '')))
    AND car.carrier_id(+)=rtvh.carrier_id;

TYPE l_rtv_legacy_details
IS
  TABLE OF rtv_legacy_details_cur%ROWTYPE INDEX BY PLS_INTEGER;
  -- Get Freight Bill Number
  
  CURSOR lcu_freightbill_cur(c_invoice_num VARCHAR2, c_carrier_id NUMBER)
  IS
    SELECT rtrim(ltrim(fb.out_frt_bill_nbr)) freight_bill_num
    FROM od.frtbill@legacydb2 fb
    WHERE fb.ship_doc_nbr   = c_invoice_num
    AND fb.carrier_id       = c_carrier_id
    ORDER BY fb.out_frt_bill_nbr ASC;
TYPE lcu_freightbill
IS
  TABLE OF lcu_freightbill_cur%ROWTYPE INDEX BY PLS_INTEGER;
  */
  indx          NUMBER;
  f_indx        NUMBER;
  lc_debug_flag VARCHAR2(1);
  l_rtv_dtls_obj XX_AP_RTV_DETAILS_OBJ_TYPE;
  --l_freightbill_tab lcu_freightbill;
  --l_rtv_legacy_tab l_rtv_legacy_details;
  lcu_freightbill_num VARCHAR2(100);
  l_freightbill_nbr1 VARCHAR2(100);
BEGIN
  DBMS_OUTPUT.PUT_LINE('BEGIN - rtv_details');
  lc_debug_flag := 'Y';
  log_debug_msg ('Debug Flag :'||lc_debug_flag);
  IF (lc_debug_flag = 'Y') THEN
    g_debug        := 'Y';
  ELSE
    g_debug := 'N';
  END IF;
  OPEN rtv_details_cur;
  FETCH rtv_details_cur BULK COLLECT INTO p_rtv_dtls_obj;
  CLOSE rtv_details_cur;
  /**  Begin of 6.3
  DBMS_OUTPUT.PUT_LINE('EBS Data count - p_rtv_dtls_obj.count is '||p_rtv_dtls_obj.count);
  IF p_rtv_dtls_obj.count = 0 THEN
    OPEN rtv_legacy_details_cur;
    FETCH rtv_legacy_details_cur BULK COLLECT INTO l_rtv_legacy_tab;
    IF l_rtv_legacy_tab.COUNT > 0 THEN
      FOR i IN l_rtv_legacy_tab.FIRST .. l_rtv_legacy_tab.LAST
      LOOP
          lcu_freightbill_num := NULL;
          OPEN lcu_freightbill_cur(l_rtv_legacy_tab(i).rtv_nbr,l_rtv_legacy_tab(i).carrier_id);
          FETCH lcu_freightbill_cur BULK COLLECT INTO l_freightbill_tab;
           FOR i IN l_freightbill_tab.FIRST .. l_freightbill_tab.LAST
            LOOP
             l_freightbill_nbr1 :=l_freightbill_tab(i).freight_bill_num;
            END LOOP;
          CLOSE lcu_freightbill_cur;

        p_rtv_dtls_obj.extend;
        p_rtv_dtls_obj(i) := xx_ap_rtv_details_rec_type( l_rtv_legacy_tab(i).dept,
                                                         l_rtv_legacy_tab(i).sku,
                                                         l_rtv_legacy_tab(i).vendor_product_code,
                                                         l_rtv_legacy_tab(i).descr,
                                                         l_rtv_legacy_tab(i).rtv_qty,
                                                         l_rtv_legacy_tab(i).cost, --?
                                                         l_rtv_legacy_tab(i).ext_cost,                                                                                                                                                                                                      --?
                                                         l_rtv_legacy_tab(i).allow_qty,                                                                                                                                                                                                     --?
                                                         l_rtv_legacy_tab(i).allow_cost,
                                                         l_rtv_legacy_tab(i).allow_ext_cost,--?
                                                         NULL,                                                                                                                                                                                                                              -- worksheet_nbr,
                                                         l_rtv_legacy_tab(i).rga_nbr,
														 l_rtv_legacy_tab(i).carrier_name,
														 l_freightbill_nbr1, NULL, NULL, NULL, NULL );
      END LOOP;
    END IF;
    CLOSE rtv_legacy_details_cur;
  END IF;
   End of 6.3 **/
  DBMS_OUTPUT.PUT_LINE('END - rtv_details');
EXCEPTION
WHEN OTHERS THEN
  --log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
  DBMS_OUTPUT.PUT_LINE('Exception Message while we are getting the rtv_details inquiry....'||SQLERRM);
END rtv_line_details;
-- +===================================================================+
-- | Name  : inv_pay_status_mul_vend                                    |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number_list                            |
-- |                   p_invoice_number                                |
-- |                   p_invoice_date_from                             |
-- |                   p_invoice_date_to                               |
-- |                   p_po_number                                     |
-- +===================================================================+
PROCEDURE inv_pay_status_mul_vend(p_country        	     IN  VARCHAR2,
                                 p_vendor_number_list    IN  STRINGS_ARRAY,
				                 p_invoice_number        IN  VARCHAR2,
				                 p_invoice_date_from     IN  VARCHAR2,
				                 p_invoice_date_to       IN  VARCHAR2,
				                 p_po_number             IN  VARCHAR2,
				                 p_inv_pymt_status_obj   OUT XX_AP_INV_PYMT_STATUS_OBJ_TYPE)
IS
    CURSOR inv_payment_status_cur IS
    ----Added below query for NAIT-45779 by Ragni, 25-JUN-18
SELECT xx_ap_inv_pymt_status_rec_type((CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
  NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)) ,
  ai.invoice_num,
  ai.invoice_date,
  ai.amount_applicable_to_discount,
  (ai.amount_applicable_to_discount-ai.invoice_amount) ,
  ai.discount_amount_taken,
  (ai.amount_applicable_to_discount-ai.discount_amount_taken -(ai.amount_applicable_to_discount-ai.invoice_amount)) ,
  apsa.due_date,
  NVL(aca.check_number,0) ,
  NVL(aca.amount,0) ,
  aca.check_date,
  -- SUBSTR(ai.description,9),
  LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
  -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
  ai.attribute11
  ||'-'
  ||LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
  ai.voucher_num)
FROM ap_invoices_all ai ,
  ap_supplier_sites_all pvsa ,
  table(p_vendor_number_list) vpl,
  ap_payment_schedules_all apsa ,
  ap_invoice_payments_all aipa ,
  ap_checks_all aca
WHERE 1=1
AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
AND (p_invoice_number IS NULL OR ai.invoice_num like p_invoice_number)
AND ai.wfapproval_status IN ('MANUALLY APPROVED','NOT REQUIRED','WFAPPROVED')
AND ai.invoice_num NOT LIKE '%BUOI%'
--AND DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_TEST_WEBSERV_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))) = NVL(:p_po_number,DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,XX_TEST_WEBSERV_PKG.get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))))
AND DECODE(ai.org_id, 403,'CAN','USA')      = p_country
--AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0')  = LPAD(p_vendor_number,10,'0')
AND ltrim(pvsa.vendor_site_code_alt,'0') = ltrim(vpl.COLUMN_VALUE, '0')
AND ai.vendor_site_id = pvsa.vendor_site_id
AND ai.invoice_id     = apsa.invoice_id
AND ai.invoice_id     = aipa.invoice_id
AND aipa.check_id     = aca.check_id
AND EXISTS (SELECT 1 from po_headers_All
where po_header_id=ai.po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 from po_headers_All
where po_header_id=ai.quick_po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 FROM dual
WHERE (ai.po_header_id IS NULL OR ai.quick_po_header_id IS NULL)
AND p_po_number IS NULL
)
UNION ALL
SELECT xx_ap_inv_pymt_status_rec_type((CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
  NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)) ,
  ai.invoice_num,
  ai.invoice_date,
  ai.amount_applicable_to_discount,
  (ai.amount_applicable_to_discount-ai.invoice_amount),
  ai.discount_amount_taken,
  (ai.amount_applicable_to_discount-ai.discount_amount_taken -(ai.amount_applicable_to_discount-ai.invoice_amount)),
  apsa.due_date,
  0 ,
  0 , --NVL(aca.amount,0),
  NULL , --aca.check_date,
  -- SUBSTR(ai.description,9),
  LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
  -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
  ai.attribute11
  ||'-'
  ||LPAD(XX_AP_VENDOR_PORTAL_PKG.get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0) ,
  ai.voucher_num)
FROM ap_invoices_all ai ,
  ap_supplier_sites_all pvsa ,
  table(p_vendor_number_list) vpl,
  ap_payment_schedules_all apsa ,
  xla_events xev,
  xla_transaction_entities xte
WHERE 1 =1
AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
AND (p_invoice_number IS NULL OR ai.invoice_num like p_invoice_number)
AND ai.wfapproval_status IN ('MANUALLY APPROVED','NOT REQUIRED','WFAPPROVED')
AND ai.invoice_num NOT LIKE '%BUOI%'
AND DECODE(ai.org_id, 403,'CAN','USA')    = p_country
--AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0')  = LPAD(p_vendor_number,10,'0')
AND ltrim(pvsa.vendor_site_code_alt,'0') = ltrim(vpl.COLUMN_VALUE, '0')
AND ai.vendor_site_id  = pvsa.vendor_site_id
AND ai.invoice_id      = apsa.invoice_id
AND xte.source_id_int_1=ai.invoice_id
AND xte.entity_code    = 'AP_INVOICES'
AND xte.application_id = 200
AND xev.entity_id      =xte.entity_id
AND xev.application_id =xte.application_id
--AND xev.event_type_code = 'INVOICE VALIDATED' Commented since it was restricting only debit/credit memos -- Ragni Gupta 08-Aug-18
AND (xev.event_type_code = 'INVOICE VALIDATED' or xev.event_type_code = 'DEBIT MEMO VALIDATED' or xev.event_type_code = 'CREDIT MEMO VALIDATED')
AND xev.process_status_code = 'P'
AND xev.event_status_code   ='P'
AND not exists(SELECT 1 from ap_invoice_payments_all aipa
WHERE aipa.invoice_id = ai.invoice_id)
AND EXISTS (SELECT 1 from po_headers_All
where po_header_id=ai.po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 from po_headers_All
where po_header_id=ai.quick_po_header_id
AND segment1 = p_po_number
UNION ALL
SELECT 1 FROM dual
WHERE (ai.po_header_id IS NULL OR ai.quick_po_header_id IS NULL)
AND p_po_number IS NULL
);
--Commented below query for NAIT-45779 by Ragni, 25-JUN-18
/*
  SELECT xx_ap_inv_pymt_status_rec_type(
    (CASE WHEN ai.org_id = 403 THEN 'CAN' ELSE 'USA' END),
	        			   NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),
            				   ai.invoice_num,
            				   ai.invoice_date,
            				   ai.amount_applicable_to_discount,
           				   (ai.amount_applicable_to_discount-ai.invoice_amount),
            				   ai.discount_amount_taken,
                                           (ai.amount_applicable_to_discount-ai.discount_amount_taken
                                            -(ai.amount_applicable_to_discount-ai.invoice_amount)),
            				   apsa.due_date,
            				   NVL(aca.check_number,0),
            				   NVL(aca.amount,0),
            				   aca.check_date,
            				   -- SUBSTR(ai.description,9),
                               LPAD(get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
            				   -- get_po_number(NVL(ai.po_header_id,ai.quick_po_header_id)),
							   ai.attribute11||'-'||LPAD(get_po_loc(NVL(ai.po_header_id,ai.quick_po_header_id)),4,0),
            				   ai.voucher_num)
      FROM  ap_invoices_all ai
	   ,ap_supplier_sites_all pvsa
	   ,ap_payment_schedules_all apsa
	   ,ap_invoice_payments_all aipa
	   ,ap_checks_all aca
     WHERE ai.invoice_num = NVL(p_invoice_number,ai.invoice_num)
       AND DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id)))
	        = NVL(p_po_number,DECODE(NVL(ai.po_header_id,ai.quick_po_header_id),NULL,ai.attribute11,get_po_num(NVL(ai.po_header_id,ai.quick_po_header_id))))
       AND DECODE(ai.org_id, 403,'CAN','USA') = p_country
       AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0') = LPAD(p_vendor_number,10,'0')
       AND ai.invoice_date BETWEEN NVL(to_date(p_invoice_date_from,'YYYY-MM-DD'),ai.invoice_date) AND NVL(to_date(p_invoice_date_to,'YYYY-MM-DD'),ai.invoice_date)
       AND ai.vendor_site_id = pvsa.vendor_site_id
       AND ai.invoice_id = apsa.invoice_id
       AND ai.invoice_id = aipa.invoice_id
       AND aipa.check_id = aca.check_id;*/
  i NUMBER;
  lc_debug_flag VARCHAR2(1);
BEGIN
    xla_security_pkg.set_security_context(602);
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;

    --08/11/17 avinash changes to load object type
    OPEN inv_payment_status_cur;
    FETCH inv_payment_status_cur BULK COLLECT INTO p_inv_pymt_status_obj;
    CLOSE inv_payment_status_cur;

EXCEPTION
WHEN OTHERS
THEN
   log_debug_msg('Exception Message while we are getting the Invoice Payment Status....'||SQLERRM);
END inv_pay_status_mul_vend;



-- +===================================================================+
-- | Name  : check_info_inquiry_mul_vend                               |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        	            	               |
-- |                   p_vendor_number_list                            |
-- |                   p_invoice_number                                |
-- |                   p_check_date_from                               |
-- |                   p_check_date_to                                 |
-- |                   p_check_number                                  |
-- +===================================================================+
PROCEDURE check_info_inquiry_mul_vend(p_country                IN  VARCHAR2,
                             p_vendor_number_list    IN  STRINGS_ARRAY,
			     p_invoice_number         IN  VARCHAR2,
			     p_check_date_from        IN  VARCHAR2,
			     p_check_date_to          IN  VARCHAR2,
			     p_check_number           IN  VARCHAR2,
			     p_chk_info_inquiry_obj   OUT XX_CHK_INF_INQUIRY_OBJ_TYPE)
IS
  CURSOR check_info_cur IS

   SELECT xx_chk_inf_inquiry_rec_type((CASE WHEN aca.org_id = 403 THEN 'CAN' ELSE 'USA' END),
	      				NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),
          				NVL(aca.check_number,0),
          				aca.check_date,
          				aca.status_lookup_code,
					NVL(aca.amount,0),
					NULL, --ai.discount_amount_taken,
					NULL, --ai.invoice_num,
					NULL, --aipa.amount,
					aca.vendor_name,
					aca.address_line1,
					aca.address_line2,
					aca.city,
					aca.state,
					aca.zip)
     FROM ap_supplier_sites_all pvsa
	 ,ap_checks_all aca,
    table(p_vendor_number_list) vpl
    WHERE 1=1
     -- AND LPAD(NVL(pvsa.attribute9,NVL(pvsa.vendor_site_code_alt,pvsa.vendor_site_id)),10,'0') = LPAD(p_vendor_number,10,'0')
      AND ltrim(pvsa.vendor_site_code_alt,'0') = ltrim(vpl.COLUMN_VALUE, '0')
      AND aca.check_number = NVL(p_check_number,aca.check_number)
      AND DECODE(aca.org_id, 403,'CAN','USA') = p_country
      AND aca.check_date BETWEEN NVL(to_date(p_check_date_from,'YYYY-MM-DD'),aca.check_date) AND NVL(to_date(p_check_date_to,'YYYY-MM-DD'),aca.check_date)
      AND pvsa.vendor_site_id = aca.vendor_site_id
      AND  EXISTS (SELECT 1 FROM ap_invoice_payments_all aipa, ap_invoices_all aia
                 WHERE 1=1
                   AND aia.invoice_id = aipa.invoice_id
                             AND aipa.check_id = aca.check_id
                             AND aia.invoice_num = NVL(p_invoice_number, aia.invoice_num));



  lc_debug_flag VARCHAR2(1);
BEGIN
    lc_debug_flag := 'Y';
    log_debug_msg ('Debug Flag :'||lc_debug_flag);
    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF;


    OPEN check_info_cur;
    FETCH check_info_cur BULK COLLECT INTO p_chk_info_inquiry_obj;
    CLOSE check_info_cur;
EXCEPTION
WHEN OTHERS
THEN
    log_debug_msg('Exception Message while we are getting the Check information inquiry....'||SQLERRM);
END check_info_inquiry_mul_vend;

END XX_AP_VENDOR_PORTAL_PKG;
/
SHOW ERRORS;