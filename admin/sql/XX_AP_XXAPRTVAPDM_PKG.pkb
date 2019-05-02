CREATE OR REPLACE PACKAGE BODY "APPS"."XX_AP_XXAPRTVAPDM_PKG" 
  -- +=========================================================================
  -- +
  -- |                  Office Depot - Project Simplify
  -- |
  -- +=========================================================================
  -- +
  -- | Name        :  XX_AP_XXAPRTVAPDM_PKG.pkb                       |
  -- | Description :  Plsql package for XXAPRTVAPDM Report
  -- |
  -- |                Created this package to avoid using dblinks in rdf
  -- |
  -- | RICE ID     :  R1050
  -- |
  -- |Change Record:
  -- |
  -- |===============
  -- |
  -- |Version   Date        Author             Remarks
  -- |
  -- |========  =========== ================== ================================
  -- |
  -- |1.0       29-Apr-2013 Paddy Sanjeevi     Initial version
  -- |
  -- |                                         Defect 23208
  -- |
  -- |1.1       28-May-2013 Paddy Sanjeevi     Modified column mapping
  -- |
  -- |1.2       31-May-2013 Paddy Sanjeevi     Modified to add cursor in
  -- |
  -- |                                         the procedure CF_voucher_num1
  -- |
  -- |1.3       28-Jun-2013 Paddy Sanjeevi     Added TRIM in cf_VendorProduct
  -- |
  -- |1.4       06-Jul-2013 Paddy Sanjeevi     Added TRIM in cf_legacy_inv_num
  -- |
  -- |1.5       06-Jul-2013 Paddy Sanjeevi     Added TRIM in
  -- CF_FreightBillFormula|
  -- |1.6       19-AUG-2017 Digamber S     Added p_source   column in all
  -- procedures and functions to resolve the data source Legacy or EBiz

  -- |1.7       02-FEB-2017 Ragni Gupta		Moved freight bill assignment condition out of ELSE block
  --       and commented call of invoice approval pkg to enahnce performance
  -- |1.8       12-APR-2018 Digamber S     Added new function before_report_trigger_c
  --                                       for new RTV APDM consolidation report
  -- |1.9        14-Dec-2018 Ragni Gupta   NAIT-72725, to remove dblink dependency
  -- |1.10		28-FEB-2019  Raj Jose      NAIT-86183 Performance improvements
  -- +=========================================================================
  -- +
AS

-----
  -- Function to get invoice status
  -- Check the invoices which are validated.
  -------
FUNCTION get_inv_status(
    p_invoice_id NUMBER )
  RETURN VARCHAR2
IS
  v_status VARCHAR2(1):='N';
BEGIN
  xla_security_pkg.set_security_context(602);
  SELECT 'Y'
  INTO v_status
  FROM dual
  WHERE NOT EXISTS
    (SELECT 'x'
    FROM ap_holds_all
    WHERE invoice_id         =p_invoice_id
    AND release_lookup_code IS NULL
    )
  AND EXISTS
    (SELECT 'x'
    FROM xla_events xev,
      xla_transaction_entities xte
    WHERE xte.source_id_int_1=p_invoice_id
    AND xte.application_id   = 200
    AND xte.entity_code      = 'AP_INVOICES'
    AND xev.entity_id        = xte.entity_id
    AND xev.event_type_code LIKE '%VALIDATED%'
	AND xte.application_id = xev.application_id --/*Raj 28-Feb-2019 NAIT-86183 added to access application_id partition */
	AND xev.application_id = 200 --NAIT-86183
    );
  RETURN(v_status);
EXCEPTION
WHEN OTHERS THEN
  RETURN(v_status);
END get_inv_status;
-----
PROCEDURE get_invoice_batch(
    p_batch_name VARCHAR2)
AS
  -- Procedure to get validated Invoice batch
  CURSOR c_rtv_valid_inv
  IS
    SELECT ai.org_id,
      ai.vendor_site_id ,
      ai.invoice_num,
      TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
    FROM ap_invoices_all ai
    WHERE 1                  =1
    AND ai.last_update_date >= sysdate-7
    ---AND ai.last_update_date >= xx_ap_iby_pmnt_batch_pkg.cutoff_date_eligible
    AND ai.invoice_num LIKE 'RTV%'
    AND ai.org_id                                           =fnd_profile.value ('ORG_ID')
    -- AND XX_AP_XXAPRTVAPDM_PKG.get_inv_status(ai.invoice_id) = 'Y' -- Validated Invoice /* Raj 28-Feb-2019 Jira#NAIT-86183 SQL consuming 375 seconds mainly due to PL/SQL context switching */
	-- Raj 28-Feb-2019 Jira#NAIT-86183 added the logic of get_inv_status in below and conditions
    AND NOT EXISTS 
    (
	  SELECT 1
	  FROM   AP_HOLDS_ALL
	  WHERE invoice_id         = AI.INVOICE_ID
      AND   release_lookup_code IS NULL
	) 
    AND EXISTS 
    (
	 SELECT 1
	 FROM xla_events xev,
          xla_transaction_entities xte
     WHERE 1=1 
	 AND xte.application_id   = 200 
     AND xte.ledger_id        = AI.SET_OF_BOOKS_ID	 
	 AND xte.entity_code      = 'AP_INVOICES'
	 AND NVL(xte.source_id_int_1,-99) = AI.INVOICE_ID
	 AND xev.entity_id        =  xte.entity_id
	 AND xev.application_id   =  xte.application_id
	 AND xev.application_id   =  200 
     AND xev.event_type_code LIKE '%VALIDATED%'
	) 
	--Raj End 28-Feb-2019 Jira#NAIT-86183
    AND ai.source                                          IN
      (SELECT val.target_value1
      FROM xx_fin_translatedefinition def ,
        xx_fin_translatevalues val
      WHERE 1                  = 1
      AND def.translation_name = 'AP_INVOICE_SOURCE'
      AND def.translate_id     = val.translate_id
      AND val.target_value1 LIKE '%RTV%'
      )
  AND ( --AI.VOUCHER_NUM IS NOT NULL
    NVL(ai.voucher_num, ai.doc_sequence_value) IS NOT NULL
  OR EXISTS
    (SELECT 1
    FROM xx_ap_rtv_hdr_attr xarh,
      xx_ap_rtv_lines_attr xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code = 'DY'
    AND xarh.invoice_num    = ai.invoice_num
    ))
  AND NOT EXISTS
    (SELECT 'x'
    FROM xx_ap_confirmed_payment_batch
    WHERE payment_batch =ai.invoice_num
    AND rtv            IN ('F','Y') -- Defect 28104
    AND checkrun_id     =ai.vendor_site_id
    )
  ORDER BY ai.vendor_id,
    ai.invoice_num;
  --------Parameters---------
  ln_conc_request_id   NUMBER := 0;
  lb_print_option      BOOLEAN;
  lc_error_loc         VARCHAR2(4000) := NULL;
  lc_error_debug       VARCHAR2(4000) := NULL;
  lc_req_data          VARCHAR2(100)  := NULL;
  lc_rtv_error_status  VARCHAR2(1)    := 'N';
  lc_chbk_error_status VARCHAR2(1)    := 'N';
  ln_org_id            NUMBER;
  ---LN_VENDOR_ID         number       := 0;
  -- l_batch_name VARCHAR2(50) := fnd_global.conc_request_id ;
BEGIN

  xla_security_pkg.set_security_context(602);
  --x_ret_code := 0;
  ln_org_id :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, 'Batch Name :'||TO_CHAR(p_batch_name));
  ln_conc_request_id :=fnd_global.conc_request_id ;
  FOR lcu_rtv_apdm IN c_rtv_valid_inv
  LOOP
    lc_error_loc   := 'Inserting into custom table for RTV Batch' ;
    lc_error_debug := 'Inserting the custom table for the Invoice Number : '|| lcu_rtv_apdm.invoice_num;
    --*************************************************************************
    -- ***
    -- Inserting in the custom table with RTV to 'F' to indicate Formatting
    -- status
    --*************************************************************************
    -- ***
    BEGIN
      INSERT
      INTO xx_ap_confirmed_payment_batch
        (
          payment_batch ,
          rtv ,
          chargeback ,
          last_update_date ,
          last_updated_by ,
          creation_date ,
          created_by ,
          last_update_login ,
          request_id ,
          checkrun_id ,
          org_id ,
          chb_request_id,
          attribute1
        )
        VALUES
        (
          lcu_rtv_apdm.invoice_num ,
          'F' ,
          'N' ,
          sysdate ,
          fnd_global.user_id ,
          sysdate ,
          fnd_global.user_id ,
          fnd_global.user_id ,
          ln_conc_request_id ,
          lcu_rtv_apdm.vendor_site_id ,
          lcu_rtv_apdm.org_id ,
          NULL,
          p_batch_name
        );
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Error while inserting into xx_ap_confirmed_payment_batch '||' ,'||sqlerrm);
    END ;
  END LOOP;
END;
PROCEDURE BEFORE_REPORT_TRIGGER_C
  (
    p_request_id NUMBER,
    p_country    VARCHAR2,
    P_RTV_NUMBER  NUMBER,
    P_batch_name VARCHAR2
  )
IS
  
  /* Raj 28-Feb-2019 commented as part of Jira#NAIT-86183 the below SQL is inefficient taking avg 5400 seconds per execution 
  CURSOR c1
  IS
    SELECT AI.invoice_num ,
      AI.invoice_id ,
      AI.INVOICE_DATE ,
      -- AI.VOUCHER_NUM ,
      NVL(AI.VOUCHER_NUM, AI.doc_sequence_value) VOUCHER_NUM ,
      AI.vendor_site_id ,
      (NVL( TO_NUMBER( PVSA.ATTRIBUTE9),PVSA.VENDOR_SITE_ID)) LEGACY_VENDOR,
      DECODE ( NVL(P_COUNTRY,'US') , 'US','USTR','CA','CNTR',NVL(P_COUNTRY, 'US')) AP_COMPANY
    FROM ap_invoices_all AI ,
      ap_suppliers PV --po_vendors  PV   Modified for R12
      ,
      ap_supplier_sites_all PVSA --po_vendor_sites_all PVSA  Modified for R12
      ,
      xx_fin_translatedefinition DEF ,
      xx_fin_translatevalues VAL
    WHERE 1               =1
    --AND ai.vendor_site_id = NVL(p_vendor_id, ai.vendor_site_id)
    AND ai.invoice_id = NVL(P_RTV_NUMBER, ai.invoice_id)
    AND AI.INVOICE_NUM LIKE 'RTV%'
      -- AND AI.voucher_num             IS NOT NULL
    AND NVL(AI.VOUCHER_NUM, AI.doc_sequence_value) IS NOT NULL
      --AND AI.invoice_type_lookup_code = 'DEBIT' -- 'CREDIT'
    AND VAL.target_value1 =AI.SOURCE
    AND VAL.target_value1 LIKE '%RTV%'
    AND DEF.translate_id     = VAL.translate_id
    AND DEF.translation_name = 'AP_INVOICE_SOURCE'
    AND AI.vendor_site_id    = PVSA.vendor_site_id
    AND pv.vendor_id         = pvsa.vendor_id
    AND EXISTS
      (SELECT 1
      FROM xx_ap_confirmed_payment_batch bt
      WHERE bt.payment_batch = ai.invoice_num
      AND checkrun_id        = ai.vendor_site_id
      AND Attribute1         = P_batch_name
      )
    --AND DECODE(APPS.AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, ai.invoice_amount,ai.payment_status_flag,ai.invoice_type_lookup_code), 'NEVER APPROVED', 'Never Validated', 'NEEDS REAPPROVAL', 'Needs Revalidation' , 'CANCELLED', 'Cancelled', 'Validated') = 'Validated'
  AND XX_AP_XXAPRTVAPDM_PKG.get_inv_status(ai.invoice_id) = 'Y'
    ORDER BY PV.SEGMENT1 ,
    AI.INVOICE_NUM ;
  */ 	

  /* Raj 28-Feb-2019 added as part of Jira#NAIT-86183 the below SQL completes less than 4 seconds per execution 
     As part of this SQL created index XX_AP_CNF_PAYMNT_BATCH_N2 ON XX_AP_CONFIRMED_PAYMENT_BATCH ATTRIBUTE1 column.
	 If invoice id is given as input SQL will drive from AP_INVOICES_ALL else will drive from XX_AP_CONFIRMED_PAYMENT_BATCH on the new _N2 index
  */ 
  CURSOR c1
  IS
  SELECT AI.invoice_num ,
         AI.invoice_id ,
         AI.INVOICE_DATE ,
         AI.VOUCHER_NUM ,
         AI.vendor_site_id ,
         (NVL( TO_NUMBER( PVSA.ATTRIBUTE9),PVSA.VENDOR_SITE_ID)) LEGACY_VENDOR,
         DECODE ( NVL(P_COUNTRY,'US') , 'US','USTR','CA','CNTR',NVL(P_COUNTRY, 'US')) AP_COMPANY
	FROM 
	(   
		SELECT AI.INVOICE_NUM ,
			   AI.INVOICE_ID ,
			   AI.INVOICE_DATE ,
			   NVL(AI.VOUCHER_NUM, AI.DOC_SEQUENCE_VALUE) VOUCHER_NUM ,
			   AI.VENDOR_SITE_ID,
			   AI.SET_OF_BOOKS_ID
		FROM   AP_INVOICES_ALL AI,
			   XX_AP_CONFIRMED_PAYMENT_BATCH BT,
			   XX_FIN_TRANSLATEDEFINITION DEF,
			   XX_FIN_TRANSLATEVALUES VAL
		WHERE 1           =1
		AND  AI.INVOICE_ID = NVL(P_RTV_NUMBER, ai.invoice_id)
		AND  AI.INVOICE_NUM LIKE 'RTV%'
		AND NVL(AI.VOUCHER_NUM, AI.DOC_SEQUENCE_VALUE) IS NOT NULL
		AND BT.PAYMENT_BATCH = AI.INVOICE_NUM
		AND BT.CHECKRUN_ID        = AI.VENDOR_SITE_ID
		AND BT.ATTRIBUTE1         = P_batch_name
		AND AI.SOURCE = VAL.TARGET_VALUE1
		AND VAL.TARGET_VALUE1 LIKE '%RTV%' 
		AND DEF.TRANSLATE_ID     = VAL.TRANSLATE_ID
		AND DEF.TRANSLATION_NAME = 'AP_INVOICE_SOURCE'
		GROUP BY /*Raj did group by as XX_AP_CONFIRMED_PAYMENT_BATCH can have duplicate entries for invoice_num and vendor_site_id combination */
			   AI.SET_OF_BOOKS_ID, 
			   AI.INVOICE_NUM ,
			   AI.INVOICE_ID ,
			   AI.INVOICE_DATE ,
			   NVL(AI.VOUCHER_NUM, AI.DOC_SEQUENCE_VALUE),
			   AI.VENDOR_SITE_ID
	) AI,
	  AP_SUPPLIERS PV ,
	  AP_SUPPLIER_SITES_ALL PVSA
	WHERE 1 = 1
	AND AI.VENDOR_SITE_ID    = PVSA.VENDOR_SITE_ID
	AND PV.VENDOR_ID         = PVSA.VENDOR_ID
	--AND XX_AP_XXAPRTVAPDM_PKG.get_inv_status(ai.invoice_id) = 'Y' PLSQL context switching consuming lot of CPU time moved the logic of get_inv_status to below AND conditions
	AND NOT EXISTS 
		(
		  SELECT 1
		  FROM   AP_HOLDS_ALL
		  WHERE invoice_id         = AI.INVOICE_ID
		  AND   release_lookup_code IS NULL
		) 
	AND EXISTS 
		(
		 SELECT 1
		 FROM xla_events xev,
			  xla_transaction_entities xte
		 WHERE 1=1 
		 AND xte.application_id   = 200 
		 AND xte.ledger_id        = AI.SET_OF_BOOKS_ID	 
		 AND xte.entity_code      = 'AP_INVOICES'
		 AND NVL(xte.source_id_int_1,-99) = AI.INVOICE_ID
		 AND xev.application_id   = xte.application_id /*Added the application_id join to access the partition in xev*/
		 AND xev.application_id   = 200
		 AND xev.entity_id        = xte.entity_id
		 AND xev.event_type_code LIKE '%VALIDATED%'
		) 
	ORDER BY PV.SEGMENT1 ,
			 AI.INVOICE_NUM	
	;	   
   

CURSOR c2 (l_invoice_nbr VARCHAR2, l_vendor_site_id NUMBER)
  IS
    SELECT XARH.INVOICE_NUM,
      --  xarh.VOUCHER_NUM voucher_nbr ,
      xarl.item_description product_descr ,
      to_number(xarl.line_amount) gross_amt ,
      to_number(xarl.qty) rtv_quantity ,
      xarl.serial_num serial_number ,
      xarl.sku ,
      --xarh.location department
      CF_DeptFormula(xarl.sku, l_vendor_site_id) department
    FROM XX_AP_RTV_HDR_ATTR xarh,
      XX_AP_RTV_LINES_ATTR xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code = 'DY'
    AND xarh.Record_Status  = 'C'
      --AND XARH.VOUCHER_NUM = l_voucher_nbr;
    AND xarh.invoice_num = l_invoice_nbr;
    --Version 1.9 changes start
  /*CURSOR c3 (l_voucher_nbr VARCHAR2, l_vendor VARCHAR2,l_ap_company VARCHAR2 )
  IS
    SELECT ad.voucher_nbr ,
      AD.descr product_descr ,
      AD.GROSS_AMT GROSS_AMT ,
      DECODE(SIGN(AD.INVOICE_QTY),-1,AD.INVOICE_QTY*-1,AD.INVOICE_QTY) RTV_QUANTITY,
      AD.part serial_number ,
      TO_CHAR(ad.sku) sku ,
      ad.gl_dept DEPARTMENT,
      ap_company,
      AP_VENDOR
    FROM od.apaydtl@legacydb2 ad
    WHERE ad.ap_vendor = lpad(TO_CHAR(l_vendor),9,'0') -- 36717
    AND ad.voucher_nbr = l_voucher_nbr                 -- RM1705
    AND AD.AP_COMPANY  = l_ap_company;                 --CNEX
    */
    --Version 1.9 changes ends
  /*SELECT ad.voucher_nbr ,
  AD.product_descr ,
  AD.GROSS_AMT ,
  ad.rtv_quantity ,
  AD.serial_number ,
  AD.SKU ,
  AD.DEPARTMENT
  FROM TABLE(XX_AP_XXAPRTVAPDM_PKG.XX_AP_LEGACYDB2(P_VENDOR_SITE_ID=>l_vendor)) AD
  WHERE AD.VOUCHER_NBR = L_VOUCHER_NBR
  --- AND ad.ap_vendor     = lpad(TO_CHAR(l_vendor),9,'0')
  AND AD.AP_COMPANY = l_ap_company;*/
  --table(XX_AP_XXAPRTVAPDM_PKG.XX_AP_LEGACYDB2(P_VENDOR_SITE_ID=>754220)) a;
BEGIN
  xla_security_pkg.set_security_context(602);
  -- populate data in Payment batch table
  xx_ap_xxaprtvapdm_pkg.get_invoice_batch(P_batch_name);
  FOR i IN c1
  LOOP
    dbms_output.put_line('First Loop '||i.voucher_num ||'  '||i.invoice_num);
    fnd_file.put_line(fnd_file.log, 'First Loop '||i.voucher_num ||'  '||i.invoice_num||' P_REQUEST_ID '||P_REQUEST_ID);
    BEGIN
      --FOR j IN c2(i.voucher_num )
      FOR j IN c2(i.invoice_num, i.vendor_Site_id )
      LOOP
        dbms_output.put_line('Second  Loop '||i.voucher_num);
        fnd_file.put_line(fnd_file.log, 'Second Loop '||i.voucher_num ||'  '||j.invoice_num);
        INSERT
        INTO XX_AP_XXAPRTVAPDM_TMP
          (
            REQUEST_ID ,
            VENDOR_ID ,
            LEGACY_VENDOR,
            INVOICE_NUM ,
            VOUCHER_NBR ,
            PRODUCT_DESCR ,
            GROSS_AMT ,
            RTV_QUANTITY ,
            SERIAL_NUMBER ,
            SKU ,
            DEPARTMENT ,
            AP_COMPANY,
            db_source
          )
          VALUES
          (
            P_REQUEST_ID ,
            I.vendor_site_id ,
            I.LEGACY_VENDOR,
            I.INVOICE_NUM ,
            I.VOUCHER_NUM ,
            J.PRODUCT_DESCR ,
            J.GROSS_AMT,
            J.RTV_QUANTITY ,
            J.SERIAL_NUMBER,
            J.SKU ,
            J.DEPARTMENT,
            I.AP_COMPANY,
            'EBIZ'
          ) ;
        FND_FILE.PUT_LINE(FND_FILE.log,'After Insert in XX_AP_XXAPRTVAPDM_TMP for EBIZ');
        --- commit;
        dbms_output.put_line(I.voucher_num );
        dbms_output.put_line( I.vendor_site_id );
      END LOOP;
      COMMIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'In no data found exception '||SQLERRM);
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Report Trigger Failure C2 Cursor Ebiz '||SQLERRM);
      dbms_output.put_line('Before Report Trigger Failure C2 Cursor Ebiz '||SQLERRM);
    END;
    --Version 1.9 changes start
   /* BEGIN
      FOR j IN c3
      (
        i.voucher_num ,i.legacy_vendor,i.AP_COMPANY
      )
      LOOP
        INSERT
        INTO XX_AP_XXAPRTVAPDM_TMP
          (
            REQUEST_ID ,
            VENDOR_ID ,
            LEGACY_VENDOR,
            INVOICE_NUM ,
            VOUCHER_NBR ,
            PRODUCT_DESCR ,
            GROSS_AMT ,
            RTV_QUANTITY ,
            SERIAL_NUMBER ,
            SKU ,
            DEPARTMENT ,
            AP_COMPANY,
            DB_SOURCE
          )
          VALUES
          (
            P_REQUEST_ID ,
            I.vendor_site_id ,
            I.LEGACY_VENDOR,
            I.INVOICE_NUM ,
            I.VOUCHER_NUM ,
            J.PRODUCT_DESCR ,
            J.GROSS_AMT,
            J.RTV_QUANTITY ,
            J.SERIAL_NUMBER,
            J.SKU ,
            J.DEPARTMENT,
            I.AP_COMPANY,
            'LEGACY'
          ) ;
        --- commit;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After Insert in XX_AP_XXAPRTVAPDM_TMP for LEGACY');
        dbms_output.put_line(I.voucher_num );
        dbms_output.put_line( I.vendor_site_id );
      END LOOP;
      COMMIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'in NO_DATA_FOUND');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Report Trigger Failure C3 Cursor DB2 connection '||SQLERRM);
      dbms_output.put_line('Before Report Trigger Failure C3 Cursor DB2 connection '||SQLERRM);
    END;*/
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,' Before Report Trigger Failure '||SQLERRM);
  dbms_output.put_line(' Before Report Trigger Failure '||sqlerrm);
end BEFORE_REPORT_TRIGGER_C;

PROCEDURE BEFORE_REPORT_TRIGGER(
    p_request_id NUMBER,
    p_country    VARCHAR2,
    P_VENDOR_ID  NUMBER,
    P_batch_name VARCHAR2)
IS
  CURSOR c1
  IS
    SELECT AI.invoice_num ,
      AI.invoice_id ,
      AI.INVOICE_DATE ,
      -- AI.VOUCHER_NUM ,
      NVL(AI.VOUCHER_NUM, AI.doc_sequence_value) VOUCHER_NUM ,
      AI.vendor_site_id ,
      (NVL( TO_NUMBER( PVSA.ATTRIBUTE9),PVSA.VENDOR_SITE_ID)) LEGACY_VENDOR,
      DECODE ( NVL(P_COUNTRY,'US') , 'US','USTR','CA','CNTR',NVL(P_COUNTRY, 'US')) AP_COMPANY
    FROM ap_invoices_all AI ,
      ap_suppliers PV --po_vendors  PV   Modified for R12
      ,
      ap_supplier_sites_all PVSA --po_vendor_sites_all PVSA  Modified for R12
      ,
      xx_fin_translatedefinition DEF ,
      xx_fin_translatevalues VAL
    WHERE 1               =1
    AND ai.vendor_site_id = NVL(p_vendor_id, ai.vendor_site_id)
    AND AI.INVOICE_NUM LIKE 'RTV%'
      -- AND AI.voucher_num             IS NOT NULL
    AND NVL(AI.VOUCHER_NUM, AI.doc_sequence_value) IS NOT NULL
      --AND AI.invoice_type_lookup_code = 'DEBIT' -- 'CREDIT'
    AND VAL.target_value1 =AI.SOURCE
    AND VAL.target_value1 LIKE '%RTV%'
    AND DEF.translate_id     = VAL.translate_id
    AND DEF.translation_name = 'AP_INVOICE_SOURCE'
    AND AI.vendor_site_id    = PVSA.vendor_site_id
    AND pv.vendor_id         = pvsa.vendor_id
    AND EXISTS
      (SELECT 1
      FROM xx_ap_confirmed_payment_batch bt
      WHERE bt.payment_batch = ai.invoice_num
      AND checkrun_id        = ai.vendor_site_id
      AND Attribute1         = P_batch_name
      )
  --AND DECODE(APPS.AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, ai.invoice_amount,ai.payment_status_flag,ai.invoice_type_lookup_code), 'NEVER APPROVED', 'Never Validated', 'NEEDS REAPPROVAL', 'Needs Revalidation' , 'CANCELLED', 'Cancelled', 'Validated') = 'Validated'
   AND NOT EXISTS (SELECT 'x'
                 FROM AP_HOLDS_ALL
             WHERE INVOICE_ID=AI.INVOICE_ID
              AND RELEASE_LOOKUP_CODE IS NULL
               )
      AND EXISTS
        (SELECT 'x'
        FROM XLA_EVENTS XEV,
          XLA_TRANSACTION_ENTITIES XTE
        WHERE XTE.SOURCE_ID_INT_1=AI.INVOICE_ID
        AND XTE.APPLICATION_ID   = 200
        AND XTE.ENTITY_CODE      = 'AP_INVOICES'
        AND XEV.ENTITY_ID        = XTE.ENTITY_ID
        AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
		AND XTE.APPLICATION_ID   = XEV.APPLICATION_ID /*Raj NAIT-86183 added the application_id filter to access the partition in xev */ 
        AND XEV.APPLICATION_ID = 200  	/*Raj NAIT-86183 added the application_id filter to access the partition in xev */ 	
        )
  ORDER BY PV.SEGMENT1 ,
    AI.INVOICE_NUM ;
  CURSOR c2 (l_invoice_nbr VARCHAR2)
  IS
    SELECT XARH.INVOICE_NUM,
      --  xarh.VOUCHER_NUM voucher_nbr ,
      xarl.item_description product_descr ,
      to_number(xarl.line_amount) gross_amt ,
      to_number(xarl.qty) rtv_quantity ,
      xarl.serial_num serial_number ,
      xarl.sku ,
      --xarh.location department
      CF_DeptFormula(xarl.sku, p_vendor_id) department
    FROM XX_AP_RTV_HDR_ATTR xarh,
      XX_AP_RTV_LINES_ATTR xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code = 'DY'
    AND xarh.Record_Status  = 'C'
      --AND XARH.VOUCHER_NUM = l_voucher_nbr;
    AND xarh.invoice_num = l_invoice_nbr;
    --Version 1.9 changes start
  /*CURSOR c3 (l_voucher_nbr VARCHAR2, l_vendor VARCHAR2,l_ap_company VARCHAR2 )
  IS
    SELECT ad.voucher_nbr ,
      AD.product_descr ,
      AD.GROSS_AMT ,
      ad.rtv_quantity ,
      AD.serial_number ,
      AD.SKU ,
      AD.DEPARTMENT
    FROM TABLE(XX_AP_XXAPRTVAPDM_PKG.XX_AP_LEGACYDB2(P_VENDOR_SITE_ID=>l_vendor)) AD
    WHERE AD.VOUCHER_NBR = L_VOUCHER_NBR
      --- AND ad.ap_vendor     = lpad(TO_CHAR(l_vendor),9,'0')
    AND AD.AP_COMPANY = l_ap_company;*/
    --Version 1.9 changes ends
  --table(XX_AP_XXAPRTVAPDM_PKG.XX_AP_LEGACYDB2(P_VENDOR_SITE_ID=>754220)) a;
BEGIN

 xla_security_pkg.set_security_context(602);

  FOR i IN c1
  LOOP
    dbms_output.put_line('First Loop '||i.voucher_num ||'  '||i.invoice_num);
    fnd_file.put_line(fnd_file.log, 'First Loop '||i.voucher_num ||'  '||i.invoice_num);
    BEGIN


      --FOR j IN c2(i.voucher_num )
      FOR j IN c2(i.invoice_num )
      LOOP
        dbms_output.put_line('Second  Loop '||i.voucher_num);
        fnd_file.put_line(fnd_file.log, 'Second Loop '||i.voucher_num ||'  '||j.invoice_num);
        INSERT
        INTO XX_AP_XXAPRTVAPDM_TMP
          (
            REQUEST_ID ,
            VENDOR_ID ,
            LEGACY_VENDOR,
            INVOICE_NUM ,
            VOUCHER_NBR ,
            PRODUCT_DESCR ,
            GROSS_AMT ,
            RTV_QUANTITY ,
            SERIAL_NUMBER ,
            SKU ,
            DEPARTMENT ,
            AP_COMPANY,
            db_source
          )
          VALUES
          (
            P_REQUEST_ID ,
            I.vendor_site_id ,
            I.LEGACY_VENDOR,
            I.INVOICE_NUM ,
            I.VOUCHER_NUM ,
            J.PRODUCT_DESCR ,
            J.GROSS_AMT,
            J.RTV_QUANTITY ,
            J.SERIAL_NUMBER,
            J.SKU ,
            J.DEPARTMENT,
            I.AP_COMPANY,
            'EBIZ'
          ) ;
        FND_FILE.PUT_LINE(FND_FILE.log,'After Insert in XX_AP_XXAPRTVAPDM_TMP for EBIZ');
        --- commit;
        dbms_output.put_line(I.voucher_num );
        dbms_output.put_line( I.vendor_site_id );
      END LOOP;
      COMMIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'In no data found exception '||SQLERRM);
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Report Trigger Failure C2 Cursor Ebiz '||SQLERRM);
      dbms_output.put_line('Before Report Trigger Failure C2 Cursor Ebiz '||SQLERRM);
    END;
    --Version 1.9 changes start
    /*BEGIN
      FOR j IN c3
      (
        i.voucher_num ,i.legacy_vendor,i.AP_COMPANY
      )
      LOOP
        INSERT
        INTO XX_AP_XXAPRTVAPDM_TMP
          (
            REQUEST_ID ,
            VENDOR_ID ,
            LEGACY_VENDOR,
            INVOICE_NUM ,
            VOUCHER_NBR ,
            PRODUCT_DESCR ,
            GROSS_AMT ,
            RTV_QUANTITY ,
            SERIAL_NUMBER ,
            SKU ,
            DEPARTMENT ,
            AP_COMPANY,
            DB_SOURCE
          )
          VALUES
          (
            P_REQUEST_ID ,
            I.vendor_site_id ,
            I.LEGACY_VENDOR,
            I.INVOICE_NUM ,
            I.VOUCHER_NUM ,
            J.PRODUCT_DESCR ,
            J.GROSS_AMT,
            J.RTV_QUANTITY ,
            J.SERIAL_NUMBER,
            J.SKU ,
            J.DEPARTMENT,
            I.AP_COMPANY,
            'LEGACY'
          ) ;
        --- commit;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After Insert in XX_AP_XXAPRTVAPDM_TMP for LEGACY');
        dbms_output.put_line(I.voucher_num );
        dbms_output.put_line( I.vendor_site_id );
      END LOOP;
      COMMIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'in NO_DATA_FOUND');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Report Trigger Failure C3 Cursor DB2 connection '||SQLERRM);
      dbms_output.put_line('Before Report Trigger Failure C3 Cursor DB2 connection '||SQLERRM);
    END;*/
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,' Before Report Trigger Failure '||SQLERRM);
  dbms_output.put_line(' Before Report Trigger Failure '||SQLERRM);
END;
PROCEDURE G_RTV_layoutGroupFilter
  (
    p_source         IN VARCHAR2 ,
    p_vendor_site_id IN NUMBER ,
    p_country_cd     IN VARCHAR2 ,
    p_legacy_o OUT NUMBER ,
    p_vendor_prefix_o OUT VARCHAR2
  )
IS
  ln_legacy        NUMBER:=0;
  lc_vendor_prefix VARCHAR2(50);
BEGIN
  IF p_source         = 'EBIZ' THEN
    p_legacy_o       := 0;
    p_vendor_prefix_o:=NULL;
    --Version 1.9 changes start
  /*ELSE
    SELECT 1 ,
      LTRIM(RTRIM(VM.vendor_prefix))
    INTO ln_legacy ,
      lc_vendor_prefix
    FROM od.venmst@legacydb2 VM ,
      od.ventrd@legacydb2 VT
    WHERE VT.vendor_id            = p_vendor_site_id
    AND VT.master_vendor_id       = VM.master_vendor_id
    AND VT.master_vendor_id      <> 0
    AND SUBSTR(VT.country_cd,1,2) = p_country_cd;
    p_legacy_o                   :=ln_legacy;
    p_vendor_prefix_o            :=lc_vendor_prefix;*/
    --Version 1.9 changes ends
  END IF;
EXCEPTION
WHEN OTHERS THEN
  p_legacy_o       := 0;
  p_vendor_prefix_o:=NULL;
END G_RTV_layoutGroupFilter;
FUNCTION CF_worksheetnoFormula(
    p_source        IN VARCHAR2 ,
    p_rtv_nbr       IN NUMBER ,
    p_legacy_loc_id IN NUMBER ,
    p_sku           IN NUMBER,
    p_invoice_nbr   IN VARCHAR2
    --p_invoice_id    IN NUMBER
  )
  RETURN NUMBER
IS
  ln_worksheet_no NUMBER;
BEGIN
  IF p_source = 'EBIZ' THEN
    BEGIN
      SELECT xarl.WORKSHEET_NUM
      INTO ln_worksheet_no
      FROM XX_AP_RTV_HDR_ATTR xarh,
        XX_AP_RTV_LINES_ATTR xarl
      WHERE xarh.header_id    =xarl.header_id
      AND xarh.frequency_code ='DY'
      AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND rownum=1;
      --AND xarh.invoice_id = p_invoice_id;
    EXCEPTION
    WHEN OTHERS THEN
      ln_worksheet_no:=NULL;
    END;
    --Version 1.9 changes start
  /*ELSE
    BEGIN
      SELECT DISTINCT RTVD.WORKSHEET_NBR -- Added "DISTINCT" for Defect 15156
      INTO ln_worksheet_no               --:CP_WORKSHEET_NO
      FROM OD.RTVDOCD@legacydb2 RTVD
      WHERE RTVD.RTV_NBR = p_rtv_nbr
      AND RTVD.LOC_ID    = p_legacy_loc_id
      AND RTVD.SKU       = p_sku;
    EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        SELECT DISTINCT RTVDH.WORKSHEET_NBR -- Added "DISTINCT" for Defect 15156
        INTO ln_worksheet_no
        FROM OD.RTVDOCD_HIST@legacydb2 RTVDH
        WHERE RTVDH.RTV_NBR = p_rtv_nbr
        AND RTVDH.LOC_ID    = p_legacy_loc_id --#store_id_num
        AND RTVDH.SKU       = p_sku;
      EXCEPTION
      WHEN OTHERS THEN
        ln_worksheet_no:=NULL;
      END;
    END;*/
    --Version 1.9 changes ends
  END IF;
  RETURN(ln_worksheet_no);
EXCEPTION
WHEN OTHERS THEN
  ln_worksheet_no:=NULL;
  RETURN(ln_worksheet_no);
END CF_worksheetnoFormula;
FUNCTION CF_voucher_num1Formula(
    p_source      IN VARCHAR2 ,
    p_voucher_nbr IN VARCHAR2)
  RETURN VARCHAR2
IS
  lc_voucher_nbr VARCHAR2(50);
  --Version 1.9 changes start
  /*CURSOR c1
  IS
    SELECT LTRIM(RTRIM(voucher_nbr)) voucher_nbr
    FROM OD.APAYHDR@legacydb2
    WHERE voucher_nbr = p_voucher_nbr;*/
    --Version 1.9 changes ends
BEGIN
  IF p_source      = 'EBIZ' THEN
    lc_Voucher_nbr:= p_voucher_nbr;
    --Version 1.9 changes start
  /*ELSE
    FOR cur IN C1
    LOOP
      lc_Voucher_nbr:=cur.voucher_nbr;
    END LOOP;
    */
    --Version 1.9 changes ends
    /*
    SELECT voucher_nbr
    INTO lc_Voucher_nbr
    FROM OD.APAYHDR@legacydb2
    WHERE voucher_nbr  = p_voucher_nbr;
    */
    RETURN(lc_voucher_nbr);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_voucher_nbr:=NULL;
  RETURN(lc_voucher_nbr);
END CF_voucher_num1Formula;
FUNCTION CF_VendorProductFormula(
    p_source      IN VARCHAR2 ,
    p_country_cd  IN VARCHAR2 ,
    p_sku         IN NUMBER ,
    p_vendor_id   IN NUMBER ,
    p_invoice_nbr IN VARCHAR2
    --p_invoice_id IN NUMBER
  )
  RETURN VARCHAR2
IS
  lc_vendor_product VARCHAR2(50);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Vendor Product Formula p_source:'|| p_source||' p_invoice_nbr:'||p_invoice_nbr);
  IF p_source = 'EBIZ' THEN
    SELECT LTRIM(RTRIM( xarl.VENDOR_PRODUCT_CODE ))
    INTO lc_vendor_product
    FROM XX_AP_RTV_HDR_ATTR xarh,
      XX_AP_RTV_LINES_ATTR xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code ='DY'
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND rownum = 1
    AND xarl.sku         = p_sku; -- p_invoice_id;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Vendor Product Formula lc_vendor_product :'|| lc_vendor_product);
 --Version 1.9 changes start
  /*ELSE
    SELECT LTRIM(RTRIM(IV.vendor_product_cd))
    INTO lc_vendor_product
    FROM od.itemven@legacydb2 IV
    WHERE IV.country_cd = p_country_cd
    AND IV.sku          = p_sku
    AND IV.vendor_id    = p_vendor_id;*/
    --Version 1.9 changes ends
  END IF;
  RETURN(lc_vendor_product);
EXCEPTION
WHEN OTHERS THEN
  lc_vendor_product:=NULL;
  RETURN(lc_vendor_product);
END CF_VendorProductFormula;
FUNCTION CF_rtv_nbrFormula(
    p_source      IN VARCHAR2 ,
    p_voucher_nbr IN VARCHAR2 ,
    p_ap_company  IN VARCHAR2 ,
    p_vendor      IN VARCHAR2 ,
    p_invoice_nbr IN VARCHAR2 )
  RETURN VARCHAR2
IS
  ln_rtv_nbr VARCHAR2(52);
BEGIN
  IF p_source = 'EBIZ' THEN
    SELECT  xarh.RTV_NUMBER
    INTO ln_rtv_nbr
    FROM XX_AP_RTV_HDR_ATTR xarh
    WHERE 1              =1
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND xarh.Frequency_Code = 'DY'
    AND Rownum           =1
    AND EXISTS
      (SELECT 1
      FROM Xx_Ap_Rtv_Lines_Attr xarl
      WHERE 1          =1
      AND xarh.Rtv_Number = xarl.Rtv_Number
      AND xarh.Header_Id  = xarl.Header_Id
      );
 --Version 1.9 changes start
  /*ELSE
    SELECT LTRIM(RTRIM(SUBSTR(invoice_nbr,4,LENGTH(invoice_nbr))))
    INTO ln_rtv_nbr
    FROM OD.APAYHDR@legacydb2
    WHERE voucher_nbr = p_Voucher_nbr
    AND ap_vendor     = LPAD(p_vendor,9,'0')
    AND ap_company    = p_ap_company;*/
    --Version 1.9 changes ends
  END IF;
  RETURN(ln_rtv_nbr);
EXCEPTION
WHEN OTHERS THEN
  ln_rtv_nbr:=NULL;
  RETURN(ln_rtv_nbr);
END CF_rtv_nbrFormula;
FUNCTION CF_legacy_loc_idFormula(
    p_source      IN VARCHAR2 ,
    p_voucher_nbr IN VARCHAR2 ,
    p_vendor      IN VARCHAR2 ,
    p_invoice_nbr IN VARCHAR2 )
  RETURN VARCHAR2
IS
  ln_loc_id NUMBER;
BEGIN
  IF p_source = 'EBIZ' THEN
    SELECT xarh.LOCATION
    INTO ln_loc_id
    FROM XX_AP_RTV_HDR_ATTR xarh
    WHERE 1              =1
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND xarh.Frequency_Code = 'DY'
    AND Rownum           =1
    AND EXISTS
      (SELECT 1
      FROM Xx_Ap_Rtv_Lines_Attr xarl
      WHERE 1          =1
      AND xarh.Rtv_Number = xarl.Rtv_Number
      AND xarh.Header_Id  = xarl.Header_Id
      );
      --Version 1.9 changes start
  /*ELSE
    SELECT loc_id
    INTO ln_loc_id
    FROM OD.APAYHDR@legacydb2
    WHERE voucher_nbr = p_Voucher_nbr
    AND ap_vendor     = LPAD(p_vendor,9,'0');*/
    --Version 1.9 changes ends
  END IF;
  RETURN(ln_loc_id);
EXCEPTION
WHEN OTHERS THEN
  ln_loc_id := NULL;
  RETURN(ln_loc_id);
END CF_legacy_loc_idFormula;
FUNCTION CF_legacy_inv_numFormula(
    p_source      IN VARCHAR2 ,
    p_voucher_nbr IN VARCHAR2 ,
    p_ap_company  IN VARCHAR2 ,
    p_vendor      IN VARCHAR2 ,
    p_invoice_nbr IN VARCHAR2 )
  RETURN VARCHAR2
IS
  lc_inv_num VARCHAR2(52);
BEGIN
  IF p_source = 'EBIZ' THEN
    SELECT 'RTV'
      ||xarh.RTV_NUMBER
    INTO lc_inv_num
    FROM XX_AP_RTV_HDR_ATTR xarh
    WHERE 1              =1
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND xarh.Frequency_Code = 'DY'
    AND Rownum           =1
    AND EXISTS
      (SELECT 1
      FROM Xx_Ap_Rtv_Lines_Attr xarl
      WHERE 1          =1
      AND xarh.Rtv_Number = xarl.Rtv_Number
      AND xarh.Header_Id  = xarl.Header_Id
      );
    fnd_file.put_line(fnd_file.LOG,' p_voucher_nbr '||p_voucher_nbr || '  lc_inv_num '||lc_inv_num);
    --Version 1.9 changes start
  /*ELSE
    SELECT LTRIM(RTRIM(invoice_nbr))
    INTO lc_inv_num
    FROM OD.APAYHDR@legacydb2
    WHERE voucher_nbr = p_voucher_nbr
    AND ap_company    = p_ap_company
    AND ap_vendor     = LPAD(p_vendor,9,'0');
    fnd_file.put_line(fnd_file.LOG,' Else p_voucher_nbr '||p_voucher_nbr || '  lc_inv_num '||lc_inv_num);
    */
    --Version 1.9 changes ends
  END IF;
  RETURN (lc_inv_num);
EXCEPTION
WHEN OTHERS THEN
  lc_inv_num:=NULL;
  RETURN(lc_inv_num);
END CF_legacy_inv_numFormula;
FUNCTION CF_gstFormula(
    p_source         IN VARCHAR2 ,
    p_vendor_site_id IN NUMBER,
    p_country_cd     IN VARCHAR2)
  RETURN VARCHAR2
IS
  lc_gst_flg VARCHAR2(1);
BEGIN
  IF p_source   = 'EBIZ' THEN
    lc_gst_flg := NULL;
    --Version 1.9 changes start
  /*ELSE
    SELECT LTRIM(RTRIM(VT1.gst_tax_flg))
    INTO lc_gst_flg
    FROM od.ventrd@legacydb2 VT1
    WHERE VT1.vendor_id = p_vendor_site_id
    AND VT1.country_cd  = p_country_cd;*/
    --Version 1.9 changes ends
  END IF;
  RETURN(lc_gst_flg);
EXCEPTION
WHEN OTHERS THEN
  lc_gst_flg := NULL;
  RETURN(lc_gst_flg);
END CF_gstFormula;
FUNCTION CF_Freight_carrierFormula(
    p_source      IN VARCHAR2 ,
    p_carrier_id  IN NUMBER,
    p_invoice_nbr IN VARCHAR2
    --p_invoice_id IN NUMBER
  )
  RETURN VARCHAR2
IS
  lc_carrier_name VARCHAR2(100);
BEGIN
  IF p_source = 'EBIZ' THEN
    SELECT xarh.CARRIER_NAME
    INTO lc_carrier_name
    FROM XX_AP_RTV_HDR_ATTR xarh
    WHERE 1                 =1
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND xarh.Frequency_Code = 'DY'
    AND Rownum              =1
    AND EXISTS
      (SELECT 1
      FROM Xx_Ap_Rtv_Lines_Attr xarl
      WHERE 1             =1
      AND xarh.Rtv_Number = xarl.Rtv_Number
      AND xarh.Header_Id  = xarl.Header_Id
      );
      --Version 1.9 changes start
  /*ELSE
    SELECT LTRIM(RTRIM(carrier_name))
    INTO lc_carrier_name
    FROM od.carrier@legacydb2
    WHERE carrier_id = p_carrier_id;*/
    --Version 1.9 changes ends
  END IF;
  RETURN (lc_carrier_name);
EXCEPTION
WHEN OTHERS THEN
  RETURN('UNKNOWN');
END CF_Freight_carrierFormula;
PROCEDURE CF_FreightBillFormula(
    p_source        IN VARCHAR2 ,
    p_voucher_nbr   IN VARCHAR2,
    p_invoice_nbr   IN VARCHAR2 ,
    p_rtv_nbr       IN NUMBER ,
    p_legacy_loc_id IN NUMBER ,
    p_carrier_id    IN NUMBER ,
    p_frightbill_o OUT VARCHAR2 )
IS
--Version 1.9 changes start
  /*CURSOR lcu_frightbill
  IS
    SELECT rtrim(ltrim(FB.out_frt_bill_nbr)) bill
    FROM OD.frtbill@legacydb2 FB
    WHERE FB.ship_doc_nbr = p_rtv_nbr
    AND FB.loc_id         = p_legacy_loc_id
    AND FB.carrier_id     = p_carrier_id
    ORDER BY FB.out_frt_bill_nbr ASC;
  CURSOR lcu_frightbill_hist
  IS
    SELECT rtrim(ltrim(FB.out_frt_bill_nbr)) bill
    FROM OD.frtbill_hist@legacydb2 FB
    WHERE FB.ship_doc_nbr = p_rtv_nbr
    AND FB.loc_id         = p_legacy_loc_id
    AND FB.carrier_id     = p_carrier_id
    ORDER BY FB.out_frt_bill_nbr ASC;

  frightbill_rec lcu_frightbill%ROWTYPE; */
  --Version 1.9 changes ends
  lc_freight_bill VARCHAR2(2000);
  v_cnt           NUMBER:=0;
BEGIN
  IF p_source = 'EBIZ' THEN
    SELECT DISTINCT xarh.FREIGHT_BILL_NUM1
      ||' '
      || xarh.FREIGHT_BILL_NUM2
      ||' '
      || xarh.FREIGHT_BILL_NUM3
      ||' '
      || xarh.FREIGHT_BILL_NUM4
      ||' '
      || xarh.FREIGHT_BILL_NUM5
      ||' '
      || xarh.FREIGHT_BILL_NUM6
      ||' '
      || xarh.FREIGHT_BILL_NUM7
      ||' '
      || xarh.FREIGHT_BILL_NUM8
      ||' '
      || xarh.FREIGHT_BILL_NUM9
      ||' '
      || xarh.FREIGHT_BILL_NUM10
    INTO Lc_Freight_Bill
    FROM Xx_Ap_Rtv_Hdr_Attr xarh
    WHERE 1                 =1
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND xarh.Frequency_Code = 'DY'
    AND Rownum              =1
    AND EXISTS
      (SELECT 1
      FROM Xx_Ap_Rtv_Lines_Attr xarl
      WHERE 1             =1
      AND xarh.Rtv_Number = xarl.Rtv_Number
      AND xarh.Header_Id  = xarl.Header_Id
      );
      --Version 1.9 changes start
  /*ELSE
    SELECT COUNT(1)
    INTO v_cnt
    FROM OD.frtbill@legacydb2 FB
    WHERE FB.ship_doc_nbr = p_rtv_nbr
    AND FB.loc_id         = p_legacy_loc_id
    AND FB.carrier_id     = p_carrier_id;
    IF v_cnt             <> 0 THEN
      --     OPEN lcu_frightbill;
      --     FETCH lcu_frightbill INTO frightbill_rec;
      --     IF (lcu_frightbill%ROWCOUNT != 0) THEN
      --     close lcu_frightbill;
      FOR lcu_frtbil IN lcu_frightbill
      LOOP
        lc_freight_bill := lc_freight_bill||' '||lcu_frtbil.bill;
      END LOOP;
      lc_freight_bill := lc_freight_bill||' '||frightbill_rec.bill;
    ELSE
      FOR lcu_frtbil_hist IN lcu_frightbill_hist
      LOOP
        lc_freight_bill := lc_freight_bill||' '||lcu_frtbil_hist.bill;
      END LOOP;
    END IF;
    --  CLOSE lcu_frightbill;
    */
    --Version 1.9 changes ends
  END IF;
  p_frightbill_o:=LTRIM(RTRIM(lc_freight_bill));
EXCEPTION
WHEN OTHERS THEN
  lc_freight_bill:=NULL;
  p_frightbill_o :=NULL;
END CF_FreightBillFormula;
PROCEDURE CF_Disposition_Code(
    p_source      IN VARCHAR2 ,
    p_invoice_nbr IN VARCHAR2,
    -- p_invoice_id     IN NUMBER ,
    p_rtv_nbr        IN NUMBER ,
    p_legacy_loc_id  IN NUMBER ,
    p_vendor_site_id IN NUMBER ,
    p_country_cd     IN VARCHAR2 ,
    p_reason_cd_o OUT VARCHAR2 ,
    p_rga_nbr_o OUT VARCHAR2 ,
    p_carrier_id_o OUT NUMBER ,
    p_ship_name_o OUT VARCHAR2 ,
    p_ship_addr_line_1_o OUT VARCHAR2 ,
    p_ship_addr_line_2_o OUT VARCHAR2 ,
    p_ship_city_o OUT VARCHAR2 ,
    p_ship_state_o OUT VARCHAR2 ,
    p_ship_zip_o OUT VARCHAR2 ,
    p_ship_country_cd_o OUT VARCHAR2 ,
    p_cont_rga_flg_o OUT VARCHAR2 ,
    p_rtv_rga_o OUT VARCHAR2 ,
    p_fax_dd_wrksht_flg_o OUT VARCHAR2 ,
    p_cont_destroy_flg_o OUT VARCHAR2 ,
    p_rtv_destroy_rga_o OUT VARCHAR2 )
IS
  lc_reason_cd         VARCHAR2(20);
  lc_rga_nbr           VARCHAR2(30);
  ln_carrier_id        NUMBER(20);
  lc_ship_name         VARCHAR2(50);
  lc_ship_addr_line_1  VARCHAR2(50);
  lc_ship_addr_line_2  VARCHAR2(50);
  lc_ship_city         VARCHAR2(50);
  lc_ship_state        VARCHAR2(50);
  lc_ship_zip          VARCHAR2(50);
  lc_ship_country_cd   VARCHAR2(50);
  lc_cont_rga_flg      VARCHAR2(5);
  lc_rtv_rga           VARCHAR2(20);
  lc_fax_dd_wrksht_flg VARCHAR2(5);
  lc_cont_destroy_flg  VARCHAR2(5);
  lc_rtv_destroy_rga   VARCHAR2(20);
  lc_disp_cd           VARCHAR2(5);
  lc_disp_descr        VARCHAR2(50);
BEGIN
  IF p_source              = 'EBIZ' THEN
    p_reason_cd_o         := NULL;
    p_rga_nbr_o           := NULL;
    p_carrier_id_o        := NULL;
    p_ship_name_o         := NULL;
    p_ship_addr_line_1_o  := NULL;
    p_ship_addr_line_2_o  := NULL;
    p_ship_city_o         := NULL;
    p_ship_state_o        := NULL;
    p_ship_zip_o          := NULL;
    p_ship_country_cd_o   := NULL;
    p_cont_rga_flg_o      := NULL;
    p_rtv_rga_o           := NULL;
    p_fax_dd_wrksht_flg_o := NULL;
    p_cont_destroy_flg_o  := NULL;
    p_rtv_destroy_rga_o   := NULL;
    SELECT DISTINCT xarh.Return_code ,
      xarl.RGA_NUMBER ,
      xarh.ship_name ,
      xarh.Ship_address1 ,
      xarh.Ship_address2 ,
      xarh.Ship_address3 ,
      trim(rtrim(SUBSTR( xarh.SHIP_ADDRESS4 ,1,instr(xarh.SHIP_ADDRESS4,',')), ',')) ,
      trim(Ltrim(SUBSTR( xarh.SHIP_ADDRESS4 ,instr(xarh.SHIP_ADDRESS4,','), LENGTH(xarh.SHIP_ADDRESS4)),',')) ,
      xarh.Ship_address5
      --p_carrier_id_o    ,
      -- p_cont_rga_flg_o   ,
      --    p_rtv_rga_o
      --  p_fax_dd_wrksht_flg_o ,
      --  p_cont_destroy_flg_o ,
      --  p_rtv_destroy_rga_o
    INTO p_reason_cd_o ,
      p_rga_nbr_o ,
      p_ship_name_o ,
      p_ship_addr_line_1_o ,
      p_ship_addr_line_2_o ,
      p_ship_city_o ,
      p_ship_state_o ,
      p_ship_zip_o ,
      p_ship_country_cd_o
      --  p_carrier_id_o    ,
      -- p_cont_rga_flg_o   ,
      --  p_rtv_rga_o        ,
      --  p_fax_dd_wrksht_flg_o ,
      --  p_cont_destroy_flg_o ,
      --  p_rtv_destroy_rga_o
    FROM XX_AP_RTV_HDR_ATTR xarh,
      XX_AP_RTV_LINES_ATTR xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code ='DY'
    AND ( xarh.Invoice_Num  = P_Invoice_Nbr
    OR xarh.Rtv_Number      = Ltrim(P_Invoice_Nbr,'RTV'))
    AND xarh.Record_Status  = 'C'
    AND rownum              =1;
  --Version 1.9 changes start
  /*ELSE
    BEGIN
      SELECT LTRIM(RTRIM(RTVH.reason_cd)) ,
        LTRIM(RTRIM(RTVH.rga_nbr)) ,
        RTVH.carrier_id ,
        LTRIM(RTRIM(RTVH.ship_name)) ,
        LTRIM(RTRIM(RTVH.ship_addr_line_1)) ,
        LTRIM(RTRIM(RTVH.ship_addr_line_2)) ,
        LTRIM(RTRIM(RTVH.ship_city)) ,
        LTRIM(RTRIM(RTVH.ship_state)) ,
        LTRIM(RTRIM(RTVH.ship_zip)) ,
        LTRIM(RTRIM(RTVH.ship_country_cd))
      INTO lc_reason_cd ,
        lc_rga_nbr ,
        ln_carrier_id ,
        lc_ship_name ,
        lc_ship_addr_line_1 ,
        lc_ship_addr_line_2 ,
        lc_ship_city ,
        lc_ship_state ,
        lc_ship_zip ,
        lc_ship_country_cd
      FROM od.rtvdoch@legacydb2 RTVH
      WHERE RTVH.rtv_nbr = p_rtv_nbr
      AND RTVH.loc_id    = p_legacy_loc_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT LTRIM(RTRIM(RTVH.reason_cd)),
          LTRIM(RTRIM(RTVH.rga_nbr)),
          RTVH.carrier_id,
          LTRIM(RTRIM(RTVH.ship_name)),
          LTRIM(RTRIM(RTVH.ship_addr_line_1)),
          LTRIM(RTRIM(RTVH.ship_addr_line_2)),
          LTRIM(RTRIM(RTVH.ship_city)),
          LTRIM(RTRIM(RTVH.ship_state)),
          LTRIM(RTRIM(RTVH.ship_zip)),
          LTRIM(RTRIM(RTVH.ship_country_cd))
        INTO lc_reason_cd ,
          lc_rga_nbr ,
          ln_carrier_id ,
          lc_ship_name ,
          lc_ship_addr_line_1 ,
          lc_ship_addr_line_2 ,
          lc_ship_city ,
          lc_ship_state ,
          lc_ship_zip ,
          lc_ship_country_cd
        FROM od.rtvdoch_hist@legacydb2 RTVH
        WHERE RTVH.rtv_nbr = p_rtv_nbr
        AND RTVH.loc_id    = p_legacy_loc_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_carrier_id := NULL;
      WHEN OTHERS THEN
        ln_carrier_id := NULL;
      END;
    WHEN OTHERS THEN
      ln_carrier_id := NULL;
    END;
    p_reason_cd_o        :=lc_reason_cd;
    p_rga_nbr_o          :=lc_rga_nbr;
    p_carrier_id_o       :=ln_carrier_id;
    p_ship_name_o        :=lc_ship_name;
    p_ship_addr_line_1_o :=lc_ship_addr_line_1;
    p_ship_addr_line_2_o :=lc_ship_addr_line_2;
    p_ship_city_o        :=lc_ship_city;
    p_ship_state_o       :=lc_ship_state;
    p_ship_zip_o         :=lc_ship_zip;
    p_ship_country_cd_o  :=lc_ship_country_cd;
    BEGIN
      SELECT LTRIM(RTRIM(RTVV.cont_rga_flg)) ,
        LTRIM(RTRIM(RTVV.rtv_rga)) ,
        LTRIM(RTRIM(RTVV.fax_dd_wrksht_flg)) ,
        LTRIM(RTRIM(RTVV.cont_destroy_flg)) ,
        LTRIM(RTRIM(RTVV.rtv_destroy_rga))
      INTO lc_cont_rga_flg ,
        lc_rtv_rga ,
        lc_fax_dd_wrksht_flg ,
        lc_cont_destroy_flg ,
        lc_rtv_destroy_rga
      FROM od.rtvven@legacydb2 RTVV
      WHERE RTVV.vendor_id = p_vendor_site_id
      AND RTVV.country_cd  = p_country_cd;
    EXCEPTION
    WHEN OTHERS THEN
      lc_cont_rga_flg      := '';
      lc_rtv_rga           := '';
      lc_fax_dd_wrksht_flg := '';
      lc_cont_destroy_flg  := '';
      lc_rtv_destroy_rga   := '';
    END;
    p_cont_rga_flg_o      :=lc_cont_rga_flg;
    p_rtv_rga_o           :=lc_rtv_rga;
    p_fax_dd_wrksht_flg_o :=lc_fax_dd_wrksht_flg;
    p_cont_destroy_flg_o  :=lc_cont_destroy_flg;
    p_rtv_destroy_rga_o   :=lc_rtv_destroy_rga; */
    --Version 1.9 changes ends
  END IF;
END cf_disposition_code;
FUNCTION CF_DeptFormula(
    p_sku       IN NUMBER,
    p_vendor_id IN NUMBER)
  RETURN NUMBER
IS
  ln_dept   NUMBER;
  ln_org_id NUMBER;
BEGIN
  SELECT ship_to_location_id
  INTO ln_org_id
  FROM ap_supplier_sites_all
  WHERE vendor_site_id = p_vendor_id;
  SELECT DISTINCT mc.segment3
  INTO ln_dept
  FROM mtl_item_categories mic,
    mtl_categories_b mc,
    mtl_system_items_b msib
  WHERE msib.inventory_item_id = mic.inventory_item_id
  AND mic.category_id          = mc.category_id
  AND msib.segment1            = TO_CHAR(p_sku)
  AND msib.organization_id     = ln_org_id
  AND mc.segment3             IS NOT NULL;
  RETURN ln_dept;
EXCEPTION
WHEN OTHERS THEN
  ln_dept := NULL;
  RETURN ln_dept;
END CF_DeptFormula;
FUNCTION XX_AP_LEGACYDB2(
    P_VENDOR_SITE_ID NUMBER )
  RETURN XX_AP_XXAPRTVAPDM_PKG.RECORD_LEGACYDB2_CTT pipelined
IS
--Version 1.9 changes start
  /*CURSOR v1
  IS
    SELECT ad.voucher_nbr ,
      AD.descr product_descr ,
      AD.GROSS_AMT GROSS_AMT ,
      DECODE(SIGN(AD.INVOICE_QTY),-1,AD.INVOICE_QTY*-1,AD.INVOICE_QTY) RTV_QUANTITY,
      AD.part serial_number ,
      TO_CHAR(AD.SKU) SKU ,
      AD.GL_DEPT,
      AP_COMPANY
    FROM OD.APAYDTL@LEGACYDB2 AD
    WHERE 1          =1
    AND AD.AP_VENDOR = LPAD(TO_CHAR(P_VENDOR_SITE_ID),9,'0');*/
    --Version 1.9 changes ends
TYPE RECORD_LEGACYDB2_CTT
IS
  TABLE OF XX_AP_XXAPRTVAPDM_PKG.RECORD_LEGACYDB2 INDEX BY PLS_INTEGER;
  L_RECORD_LEGACYDB2 RECORD_LEGACYDB2_CTT;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  n NUMBER := 0;
BEGIN
--Version 1.9 changes start
  /*IF L_RECORD_LEGACYDB2.count > 0 THEN
    L_RECORD_LEGACYDB2.delete;
  END IF;
  FOR i IN v1
  LOOP
    L_RECORD_LEGACYDB2(N).VOUCHER_NBR   :=I.VOUCHER_NBR;
    L_RECORD_LEGACYDB2(N).PRODUCT_DESCR :=I.PRODUCT_DESCR;
    L_RECORD_LEGACYDB2(N).GROSS_AMT     :=I.GROSS_AMT;
    L_RECORD_LEGACYDB2(N). RTV_QUANTITY :=I.RTV_QUANTITY;
    L_RECORD_LEGACYDB2(N).SERIAL_NUMBER :=I.SERIAL_NUMBER;
    L_RECORD_LEGACYDB2(N).SKU           :=I.SKU;
    L_RECORD_LEGACYDB2(N).DEPARTMENT    :=I.GL_DEPT;
    L_RECORD_LEGACYDB2(N).AP_COMPANY    :=i.AP_COMPANY;
    n                                   := n+1;
  END LOOP;
  */
  --Version 1.9 changes ends
  IF L_RECORD_LEGACYDB2.COUNT            = 0 THEN
    L_RECORD_LEGACYDB2(N).VOUCHER_NBR   :=NULL;
    L_RECORD_LEGACYDB2(N).PRODUCT_DESCR :=NULL;
    L_RECORD_LEGACYDB2(N).GROSS_AMT     :=NULL;
    L_RECORD_LEGACYDB2(N). RTV_QUANTITY :=NULL;
    L_RECORD_LEGACYDB2(N).SERIAL_NUMBER :=NULL;
    L_RECORD_LEGACYDB2(N).SKU           :=NULL;
    L_RECORD_LEGACYDB2(N).DEPARTMENT    :=NULL;
    L_RECORD_LEGACYDB2(N).AP_COMPANY    :=NULL;
  END IF;

  FOR i IN L_RECORD_LEGACYDB2.First .. L_RECORD_LEGACYDB2.last
  LOOP
    --dbms_output.put_line('Test '||l_chargeback_db(i).vendor_id);
    pipe row ( L_RECORD_LEGACYDB2(i) ) ;
  END LOOP;

  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ) ;
  END LOOP;

end xx_ap_legacydb2;

END XX_AP_XXAPRTVAPDM_PKG;