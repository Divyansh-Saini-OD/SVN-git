create or replace PACKAGE BODY      XX_AP_VPS_EXTRACT_PKG
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 	 	:  XX_AP_VPS_EXTRACT_PKG                                                    |
-- |  Description	:  PLSQL Package to extract Matched and UnMatched Invoiced for VPS          |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- | 1.1         04/17/18     Paddy Sanjeevi   Defect 37766, fixed duplicate lines              |
-- | 1.2         04/25/18     Paddy Sanjeevi   Added to use xla_ae_headers for accounting_date  |
-- | 1.3         05/29/18     Paddy Sanjeevi   Added group by xla sql to avoid duplicate        |
-- | 1.4         01/24/19     BIAS             INSTANCE_NAME is replaced with DB_NAME for OCI   |  
-- |                                           Migration Project
-- | 1.5         07/28/20     Bhargavi Ankolekar    This is for jira#NAIT-146750                |
-- +============================================================================================+
AS

-- +======================================================================+
-- | Name        :  get_location                                  		  |
-- | Description :  This function is to get expense location			  |
-- |                                                                      |
-- | Parameters  :  p_po_header_id                        				  |
-- |                                                                      |
-- | Returns     :  v_location .                                          |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_move_archive(p_copy_file IN VARCHAR2)
IS


  lc_dest_file_name            VARCHAR2(200);
  lc_source_file_name          VARCHAR2(200);
  lc_instance_name             VARCHAR2(30);
  lb_complete                  BOOLEAN;
  lc_phase                     VARCHAR2(100);
  lc_status                    VARCHAR2(100);
  lc_dev_phase                 VARCHAR2(100);
  lc_dev_status                VARCHAR2(100);
  lc_message                   VARCHAR2(100);
  ln_request_id				   NUMBER;
BEGIN
  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV', 'DB_NAME') ), 1, 8)
  INTO lc_instance_name
  FROM DUAL;

    lc_source_file_name          := '/app/ebs/ct' || lc_instance_name || '/xxfin/ftp/out/vps/'||p_copy_file;
    lc_dest_file_name            := '/app/ebs/ct' || lc_instance_name || '/xxfin/archive/outbound/' || p_copy_file;
    ln_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE,
											    lc_source_file_name,
									            lc_dest_file_name,
												'', '', 'N'
											   );
    IF ln_request_id > 0 THEN
      COMMIT;
      -- wait for request to finish
      lb_complete := fnd_concurrent.wait_for_request(request_id => ln_request_id,
													 interval => 10,
													 max_wait => 0,
													 phase => lc_phase,
													 status => lc_status,
													 dev_phase => lc_dev_phase,
													 dev_status => lc_dev_status,
													 MESSAGE => lc_message);
    END IF;
    COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||SQLERRM);
END xx_move_archive;

-- +======================================================================+
-- | Name        :  get_location                                  		  |
-- | Description :  This function is to get expense location			  |
-- |                                                                      |
-- | Parameters  :  p_po_header_id                        				  |
-- |                                                                      |
-- | Returns     :  v_location .                                          |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_ap_get_gl_acct
  (p_invoice_id IN NUMBER,
   p_line_no	IN NUMBER,
   p_line_type	IN VARCHAR2
   )
RETURN VARCHAR2
IS

ln_ccid NUMBER:=0;
lc_acct VARCHAR2(500):=NULL;
BEGIN
  IF p_line_type='ITEM' THEN

	 BEGIN
	   SELECT dist_code_combination_id
	     INTO ln_ccid
	     FROM ap_invoice_distributions_all
        WHERE invoice_id=p_invoice_id
          AND invoice_line_number=p_line_no
          AND line_type_lookup_code='ITEM';
	 EXCEPTION
	   WHEN others THEN
	     ln_ccid:=NULL;
	 END;
     IF ln_ccid IS NULL THEN
   	    BEGIN
	      SELECT dist_code_combination_id
	        INTO ln_ccid
	        FROM ap_invoice_distributions_all
           WHERE invoice_id=p_invoice_id
             AND invoice_line_number=p_line_no
             AND line_type_lookup_code='ACCRUAL'
			 AND ROWNUM<2;

          IF ln_ccid IS NOT NULL THEN
  		     SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7
		       INTO lc_acct
		       FROM gl_code_combinations gcc
		      WHERE gcc.code_combination_id=ln_ccid;
		  END IF;
	    EXCEPTION
	      WHEN others THEN
	        ln_ccid:=NULL;
	    END;
	 ELSE
	    SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7
		  INTO lc_acct
		  FROM gl_code_combinations gcc
		 WHERE code_combination_id=ln_ccid;

	 END IF;
  ELSIF p_line_type='MISCELLANEOUS' THEN
    BEGIN
      SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7
	    INTO lc_acct
	    FROM gl_code_combinations gcc,
		     ap_invoice_distributions_all aid
	   WHERE aid.invoice_id=p_invoice_id
	     AND aid.invoice_line_number=p_line_no
		 AND line_type_lookup_code='MISCELLANEOUS'
		 AND ROWNUM<2;
	EXCEPTION
	  WHEN others THEN
	    lc_acct:=NULL;
	END;
  ELSIF p_line_type='FREIGHT' THEN
    BEGIN
      SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7
	    INTO lc_acct
	    FROM gl_code_combinations gcc,
		     ap_invoice_distributions_all aid
	   WHERE aid.invoice_id=p_invoice_id
	     AND aid.invoice_line_number=p_line_no
		 AND line_type_lookup_code='FREIGHT'
		 AND ROWNUM<2;
	EXCEPTION
	  WHEN others THEN
	    lc_acct:=NULL;
	END;
  END IF;
  RETURN(lc_acct);
EXCEPTION
  WHEN others THEN
    RETURN(lc_acct);
END xx_ap_get_gl_acct;


-- +======================================================================+
-- | Name        :  get_location                                  		  |
-- | Description :  This function is to get expense location			  |
-- |                                                                      |
-- | Parameters  :  p_po_header_id                        				  |
-- |                                                                      |
-- | Returns     :  v_location .                                          |
-- |                                                                      |
-- +======================================================================+
	FUNCTION get_location(p_po_header_id IN NUMBER)
	RETURN VARCHAR2
	IS
		v_location VARCHAR2(10);
	BEGIN
		SELECT SUBSTR(hrl.location_code,1,6)
		INTO v_location
		FROM hr_locations_all hrl,
			 po_line_locations_all pll
		WHERE pll.po_header_id=p_po_header_id
		AND ROWNUM<2
		AND hrl.location_id=pll.ship_to_location_id;
		RETURN(v_location);
	EXCEPTION
	WHEN others THEN
		v_location:=NULL;
		RETURN(v_location);
	END get_location;
-- +======================================================================+
-- | Name        :  invoice_vps_extract                                   |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                "OD: AP VPS Invoice Extract" to extract matched and   |
-- |                UnMatched Invoices									  |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+
	PROCEDURE invoice_vps_extract( p_errbuf       OUT  VARCHAR2
							  ,p_retcode      OUT  VARCHAR2
							 )
	AS
		CURSOR matched_inv_cur(p_inv_date DATE)
		IS
		SELECT	 /*+ LEADING (h) */
				    a.source,
					'USTR',
					NVL(aps.attribute9,NVL(aps.vendor_site_code_alt,aps.vendor_site_id)) ap_vendor,
					a.last_update_date,
					a.invoice_num,
					TO_CHAR(a.invoice_date,'MM-DD-YYYY') invoice_date,
					TO_CHAR(a.creation_date,'MM-DD-YYYY') entry_dt,
					l.line_number,
					get_location(a.quick_po_header_id) location,
					pol.unit_price po_price,
					NULL avg_cost,
					msi.segment1 item,
					l.line_type_lookup_code,
					l.quantity_invoiced,
					l.unit_price,
					l.amount,
					l.attribute11 reason_cd,
					a.doc_sequence_value voucher_num,
					l.description voucher_line_desc,
					pol.quantity original_po_qty,
					pol.unit_price original_po_cost,
					ph.segment1 ap_po_nbr,
					pol.line_num po_line_nbr,
					xx_ap_get_gl_acct(l.invoice_id,l.line_number,l.line_type_lookup_code) gl_account_id,
					(	SELECT aid.period_name
						FROM ap_invoice_distributions_all aid
						WHERE aid.invoice_id            =a.invoice_id
						AND ROWNUM                 <2
					) period_name
			FROM	mtl_system_items_b msi,
					po_lines_all pol,
					hr_locations_all hrl,
					po_headers_all ph,
					ap_supplier_sites_all aps,
					ap_invoice_lines_all l,
					ap_invoices_all a,
					(SELECT xte.source_id_int_1
					   FROM xla_events xe,
							xla_transaction_entities xte,
							xla_ae_headers xah
					  WHERE xah.gl_transfer_date  BETWEEN p_inv_date AND SYSDATE
						AND xah.application_id=200
						AND xe.event_id=xah.event_id
						AND xe.application_id=xah.application_id
						AND xe.entity_id=xah.entity_id
						AND xte.application_id=xe.application_id
						AND XTE.ENTITY_CODE      = 'AP_INVOICES'
						AND xte.entity_id=xe.entity_id
						AND xe.event_status_code='P'
						AND xe.process_status_code='P'
					  GROUP BY xte.source_id_int_1
					) h
			WHERE a.invoice_id=h.source_id_int_1
			AND l.invoice_id			=a.invoice_id
			AND l.line_type_lookup_code<>'TAX'
			AND l.amount<>0
			AND a.source				<>'US_OD_CONSIGNMENT_SALES'
			AND a.invoice_num NOT LIKE '%ODDBUIA%'
			AND a.cancelled_date IS NULL
			AND aps.vendor_site_id		= a.vendor_site_id
			AND ph.po_header_id(+)		= NVL(a.po_header_id,a.quick_po_header_id)
			AND hrl.location_id 		= l.ship_to_location_id
			AND pol.po_line_id(+)		=l.po_line_id
			AND msi.inventory_item_id(+)=l.inventory_item_id
			AND msi.organization_id(+)+0=441
			AND EXISTS (SELECT 'x'
						 FROM  xx_fin_translatevalues tv
							  ,xx_fin_translatedefinition td
						WHERE td.TRANSLATION_NAME 	='XX_AP_TR_MATCH_INVOICES'
						AND tv.TRANSLATE_ID  		=td.TRANSLATE_ID
						AND tv.enabled_flag			='Y'
						AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
						AND tv.target_value1		=a.source
					   )
			AND EXISTS ( SELECT 'x'
						   FROM XX_FIN_TRANSLATEDEFINITION XFTD,
					            XX_FIN_TRANSLATEVALUES XFTV,
					            AP_SUPPLIER_SITES_ALL SITE
					      WHERE SITE.VENDOR_SITE_ID     = aps.VENDOR_SITE_ID+0
 					        AND XFTD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
             				AND XFTD.TRANSLATE_ID     = XFTV.TRANSLATE_ID
			  	  	        AND XFTV.TARGET_VALUE1    = SITE.ATTRIBUTE8||''
							AND XFTV.ENABLED_FLAG = 'Y'
							AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
					   )
		UNION ALL
			SELECT   /*+ LEADING (j) */
					a.source,
					'USTR' "USTR",
					NVL(aps.attribute9,NVL(aps.vendor_site_code_alt,aps.vendor_site_id)) ap_vendor,
					a.last_update_date,
					a.invoice_num,
					TO_CHAR(a.invoice_date,'MM-DD-YYYY') invoice_date,
					TO_CHAR(a.creation_date,'MM-DD-YYYY') entry_dt,
					trd.invoice_line_id,
					trd.location_number location,
					NULL po_price,
					trd.cost avg_cost,
					trd.sku item,
					trd.line_type line_type_lookup_code,
					DECODE (quantity_sign,'+',TRD.QUANTITY, '-', (-1)*QUANTITY) quantity_invoiced,
					NULL unit_price,
					DECODE ((SELECT TARGET_VALUE8
							FROM XX_FIN_TRANSLATEVALUES
							WHERE TRANSLATE_ID IN (SELECT TRANSLATE_ID
							FROM XX_FIN_TRANSLATEDEFINITION
							WHERE TRANSLATION_NAME = 'AP_CONSIGN_LIABILITY'
							AND ENABLED_FLAG = 'Y')
							AND SOURCE_VALUE2 = TRD.AP_VENDOR
							AND SOURCE_VALUE1 = 'USA'),NULL,TRD.PO_COST * (DECODE (quantity_sign,'+',TRD.QUANTITY, '-', (-1)*QUANTITY)) ,TRD.COST * (DECODE (quantity_sign,'+',TRD.QUANTITY, '-', (-1)*QUANTITY)))  amount,     --trd.mdse_amount amount,
					NULL reason_cd,
					a.doc_sequence_value voucher_num,
					DECODE(trd.consign_flag, 'Y', trd.line_description,'N', 'UNABSORBED COSTS', trd.line_description) voucher_line_desc,
					NULL original_po_qty,
					NULL original_po_cost,
					NULL ap_po_nbr,
					NULL po_line_nbr,
					(	SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7
						FROM ap_invoice_distributions_all aid,
							 gl_code_combinations gcc
						WHERE 1                     =1
						AND aid.invoice_id            =a.invoice_id
						AND gcc.code_combination_id =aid.dist_code_combination_id
						AND ROWNUM                 <=1
					) gl_account_id,
					(	SELECT aid.period_name
						FROM ap_invoice_distributions_all aid,
							 gl_code_combinations gcc
						WHERE 1                     =1
						AND aid.invoice_id            =a.invoice_id
						AND gcc.code_combination_id =aid.dist_code_combination_id
						AND ROWNUM                 <=1
					) period_name
				FROM ap_supplier_sites_all aps,
					 xx_ap_trade_inv_lines trd,
					 ap_invoices_all a,
					(SELECT xte.source_id_int_1
					   FROM xla_events xe,
							xla_transaction_entities xte,
							xla_ae_headers xah
					  WHERE xah.gl_transfer_date  BETWEEN p_inv_date AND SYSDATE
						AND xah.application_id=200
						AND xe.event_id=xah.event_id
						AND xe.application_id=xah.application_id
						AND xe.entity_id=xah.entity_id
						AND xte.application_id=xe.application_id
						AND XTE.ENTITY_CODE      = 'AP_INVOICES'
						AND xte.entity_id=xe.entity_id
						AND xe.event_status_code='P'
						AND xe.process_status_code='P'
					  GROUP BY xte.source_id_int_1
					) j
				WHERE a.invoice_id=j.source_id_int_1
  	 			  AND aps.vendor_site_id =a.vendor_site_id
				  AND a.invoice_num NOT LIKE '%ODDBUIA%'
				  AND a.cancelled_date IS NULL
				  AND a.source           ='US_OD_CONSIGNMENT_SALES'
			      AND trd.invoice_number =a.invoice_num
				  AND trd.cost    <> 0
				  AND trd.consign_flag   = 'Y'
				ORDER BY invoice_num,line_number,source;

		TYPE matched_inv_tab_type IS TABLE OF matched_inv_cur%ROWTYPE;
		CURSOR unmatched_inv_cur IS
			SELECT
				  AI.SOURCE SOURCE,
				  'USTR',
				  AI.INVOICE_NUM INVOICE_NUM,
				  TO_CHAR(AI.INVOICE_DATE,'MM-DD-YYYY') INVOICE_DATE,
				  NVL(APS.ATTRIBUTE9,NVL(APS.VENDOR_SITE_CODE_ALT,APS.VENDOR_SITE_ID))
				  AP_VENDOR,
				  AI.QUICK_PO_HEADER_ID,
				  L.LINE_NUMBER LINE_NUM,----POL.LINE_NUM LINE_NUM, Changing the po line number to invoice line num as per the jira #NAIT-146750
				  POL.UNIT_PRICE PO_PRICE,
				  NULL AVG_COST,
				  MSI.SEGMENT1	SKU,	--	DECODE(L.LINE_TYPE_LOOKUP_CODE, 'ITEM', MSI.SEGMENT1, NULL) SKU,
				  L.LINE_TYPE_LOOKUP_CODE,
				  L.UNIT_PRICE LIST_PRICE_PER_UNIT,
				  L.QUANTITY_INVOICED INVOICE_QTY,
				  L.AMOUNT
			FROM
				  MTL_SYSTEM_ITEMS_B MSI,
				  PO_LINES_ALL POL,
				  AP_SUPPLIER_SITES_ALL APS,
				  AP_INVOICE_LINES_ALL L,
				  AP_INVOICES_ALL AI
			WHERE
				  1                             =1
				AND AI.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
				AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
				AND AI.CANCELLED_DATE       IS NULL
				AND AI.VALIDATION_REQUEST_ID =-9999999999
				AND L.INVOICE_ID             =AI.INVOICE_ID
				AND APS.VENDOR_SITE_ID       =AI.VENDOR_SITE_ID+0
				AND POL.PO_HEADER_ID(+)      =NVL(AI.PO_HEADER_ID,AI.QUICK_PO_HEADER_ID)
				AND POL.ITEM_ID(+)           =L.INVENTORY_ITEM_ID
				AND MSI.INVENTORY_ITEM_ID(+) =L.INVENTORY_ITEM_ID
				AND MSI.ORGANIZATION_ID(+)+0 =441
				AND EXISTS
				  (
					SELECT
					  'x'
					FROM
						XX_FIN_TRANSLATEDEFINITION XFTD,
						XX_FIN_TRANSLATEVALUES XFTV,
						AP_SUPPLIER_SITES_ALL SITE
					WHERE
						SITE.VENDOR_SITE_ID   =	AI.VENDOR_SITE_ID+0
					AND XFTD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
					AND XFTD.TRANSLATE_ID     = XFTV.TRANSLATE_ID
					AND XFTV.TARGET_VALUE1    = SITE.ATTRIBUTE8
					  ||''
					AND XFTV.ENABLED_FLAG = 'Y'
					AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
				  )
				UNION ALL
				SELECT /*+ LEADING (h) INDEX(aps AP_SUPPLIER_SITES_U1) */
				  AI.SOURCE SOURCE,
				  'USTR',
				  AI.INVOICE_NUM INVOICE_NUM,
				  TO_CHAR(AI.INVOICE_DATE,'MM-DD-YYYY') INVOICE_DATE,
				  NVL(APS.ATTRIBUTE9,NVL(APS.VENDOR_SITE_CODE_ALT,APS.VENDOR_SITE_ID))
				  AP_VENDOR,
				  AI.QUICK_PO_HEADER_ID,
				  L.LINE_NUMBER LINE_NUM,----POL.LINE_NUM LINE_NUM, Changing the po line number to invoice line num as per the jira #NAIT-146750
				  POL.UNIT_PRICE PO_PRICE,
				  NULL AVG_COST,
				  MSI.SEGMENT1	SKU,
				  L.LINE_TYPE_LOOKUP_CODE,
				  L.UNIT_PRICE LIST_PRICE_PER_UNIT,
				  L.QUANTITY_INVOICED INVOICE_QTY,
				  L.AMOUNT
				FROM
				  MTL_SYSTEM_ITEMS_B MSI,
				  PO_LINES_ALL POL,
				  AP_SUPPLIER_SITES_ALL APS,
				  AP_INVOICE_LINES_ALL L,
				  AP_INVOICES_ALL AI,
				  (
					SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */
					  DISTINCT INVOICE_ID
					FROM
					  AP_HOLDS_ALL APH
					WHERE
					  APH.CREATION_DATE          > '01-JAN-11'
					AND NVL(APH.STATUS_FLAG,'S') = 'S'
					AND APH.RELEASE_LOOKUP_CODE IS NULL
				  )
				  H
				WHERE
				  AI.INVOICE_ID                 =H.INVOICE_ID
				AND AI.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
				AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
				AND AI.CANCELLED_DATE        IS NULL
				AND AI.VALIDATION_REQUEST_ID IS NULL
				AND L.INVOICE_ID              =AI.INVOICE_ID
				AND APS.VENDOR_SITE_ID        =AI.VENDOR_SITE_ID+0
				AND POL.PO_HEADER_ID(+)       =NVL(AI.PO_HEADER_ID,AI.QUICK_PO_HEADER_ID)
				AND POL.ITEM_ID(+)            =L.INVENTORY_ITEM_ID
				AND MSI.INVENTORY_ITEM_ID(+)  =L.INVENTORY_ITEM_ID
				AND MSI.ORGANIZATION_ID(+)+0  =441
				AND EXISTS
				  (
					SELECT
					  'x'
					FROM
					  XX_FIN_TRANSLATEDEFINITION XFTD,
					  XX_FIN_TRANSLATEVALUES XFTV,
					  AP_SUPPLIER_SITES_ALL SITE
					WHERE
					  SITE.VENDOR_SITE_ID     =AI.VENDOR_SITE_ID+0
					AND XFTD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
					AND XFTD.TRANSLATE_ID     = XFTV.TRANSLATE_ID
					AND XFTV.TARGET_VALUE1    = SITE.ATTRIBUTE8
					  ||''
					AND XFTV.ENABLED_FLAG = 'Y'
					AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,
					  SYSDATE)
				  )
				AND EXISTS
				  (
					SELECT
					  'x'
					FROM
					  XX_FIN_TRANSLATEDEFINITION XFTD,
					  XX_FIN_TRANSLATEVALUES XFTV
					WHERE
					  XFTD.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
					AND XFTD.TRANSLATE_ID   = XFTV.TRANSLATE_ID
					AND XFTV.TARGET_VALUE1  = AI.SOURCE
					  ||''
					AND XFTV.ENABLED_FLAG = 'Y'
					AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,
					  SYSDATE)
				  );
		TYPE unmatched_inv_tab_type IS TABLE OF unmatched_inv_cur%ROWTYPE;
		CURSOR get_dir_path
		IS
			SELECT directory_path
			FROM dba_directories
			WHERE directory_name = 'XXFIN_OUTBOUND';
		CURSOR get_inv_date
		IS
			SELECT b.actual_start_date
  			  FROM fnd_concurrent_requests b
			 WHERE request_id = (SELECT MAX(request_id)
							       FROM fnd_concurrent_requests b,
										fnd_concurrent_programs_vl a
			                      WHERE a.concurrent_program_name = 'XXODAPVPSE'
			                        AND b.concurrent_program_id=a.concurrent_program_id
								    AND b.phase_code='C'
									AND b.status_code='C'
								);



		l_unmatched_tab 				unmatched_inv_tab_type;
		l_matched_tab 					matched_inv_tab_type;
		lf_um_file              		UTL_FILE.file_type;
		l_um_file_header        		VARCHAR2(32000);
		lc_um_file_content				VARCHAR2(32000);
		lf_m_file             			UTL_FILE.file_type;
		l_m_file_header         		VARCHAR2(32000);
		lc_m_file_content				VARCHAR2(32000);
		ln_chunk_size           		BINARY_INTEGER:= 32767;
		lc_um_file_name					VARCHAR2(250) :='UNMATCHED_INV_DATA.txt';	--'UNMATCHED_INV_DATA_'||TO_CHAR(SYSDATE,'MMDDYYYY')||'.txt';
		lc_m_file_name					VARCHAR2(250) :='MATCHED_INV_DATA_'||TO_CHAR(SYSDATE,'MMDDYYYY_HH24MI')||'.txt';
		lc_dest_file_name  				VARCHAR2(200);
		ln_conc_file_copy_request_id 	NUMBER;
		lc_dirpath						VARCHAR2(500);
		lc_file_name_instance			VARCHAR2(250);
		ld_date							DATE;
		lc_instance_name			   	VARCHAR2(30);
		lb_complete        		   		BOOLEAN;
		lc_phase           		   		VARCHAR2(100);
		lc_status          		   		VARCHAR2(100);
		lc_dev_phase       		   		VARCHAR2(100);
		lc_dev_status      		   		VARCHAR2(100);
		lc_message         		   		VARCHAR2(100);
		lc_match_file					VARCHAR2(1):='N';
		lc_unmatch_file					VARCHAR2(1):='N';
BEGIN
	xla_security_pkg.set_security_context(602);
	--get file dir path
	OPEN get_dir_path;
	FETCH get_dir_path INTO lc_dirpath;
	CLOSE get_dir_path;
	OPEN get_inv_date;
	FETCH get_inv_date INTO ld_date;
	CLOSE get_inv_date;
	fnd_file.put_line(fnd_file.LOG,'Last Run Date : '||to_char(ld_date,'DD-MON-RR HH24:MI:SS'));
	IF ld_date IS NULL then
	ld_date := SYSDATE-1;
	END IF;
	SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),1,8)
	INTO lc_instance_name
	FROM dual;
	OPEN  matched_inv_cur (ld_date);
	FETCH matched_inv_cur BULK COLLECT INTO l_matched_tab;
	CLOSE matched_inv_cur;
	fnd_file.put_line(fnd_file.LOG,'Matched Invoice Count :'||l_matched_tab.COUNT);
	IF l_matched_tab.COUNT>0 THEN
	    lc_match_file					:='Y';
		BEGIN
			lf_m_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									   lc_m_file_name,
									   'w',
									   ln_chunk_size);
			l_m_file_header :=
								'SOURCE'
								||'|'||'USTR'
								||'|'||'AP_VENDOR'
								||'|'||'INVOICE_NUM'
								||'|'||'INVOICE_DATE'
								||'|'||'ENTRY_DT'
								||'|'||'LINE_NUMBER'
								||'|'||'LOCATION'
								||'|'||'PO_PRICE'
								||'|'||'AVG_COST'
								||'|'||'ITEM'
								||'|'||'LINE_TYPE_LOOKUP_CODE'
								||'|'||'QUANTITY_INVOICED'
								||'|'||'UNIT_PRICE'
								||'|'||'AMOUNT'
								||'|'||'REASON_CD'
								||'|'||'VOUCHER_NUM'
								||'|'||'VOUCHER_LINE_DESC'
								||'|'||'ORIGINAL_PO_QTY'
								||'|'||'ORIGINAL_PO_COST'
								||'|'||'AP_PO_NBR'
								||'|'||'PO_LINE_NBR'
								||'|'||'GL_ACCOUNT_ID'
								||'|'||'PERIOD_NAME';
			UTL_FILE.put_line(lf_m_file,l_m_file_header);
			FOR i IN 1.. l_matched_tab.COUNT
			LOOP
				lc_m_file_content :=
							l_matched_tab(i).source
							||'|'||'USTR'
							||'|'||l_matched_tab(i).ap_vendor
							||'|'||l_matched_tab(i).invoice_num
							||'|'||l_matched_tab(i).invoice_date
							||'|'||l_matched_tab(i).entry_dt
							||'|'||l_matched_tab(i).line_number
							||'|'||l_matched_tab(i).location
							||'|'||l_matched_tab(i).po_price
							||'|'||l_matched_tab(i).avg_cost
							||'|'||l_matched_tab(i).item
							||'|'||l_matched_tab(i).line_type_lookup_code
							||'|'||l_matched_tab(i).quantity_invoiced
							||'|'||l_matched_tab(i).unit_price
							||'|'||l_matched_tab(i).amount
							||'|'||l_matched_tab(i).reason_cd
							||'|'||l_matched_tab(i).voucher_num
							||'|'||l_matched_tab(i).voucher_line_desc
							||'|'||l_matched_tab(i).original_po_qty
							||'|'||l_matched_tab(i).original_po_cost
							||'|'||l_matched_tab(i).ap_po_nbr
							||'|'||l_matched_tab(i).po_line_nbr
							||'|'||l_matched_tab(i).gl_account_id
							||'|'||l_matched_tab(i).period_name;
					UTL_FILE.put_line(lf_m_file,lc_m_file_content);
			END LOOP;
		UTL_FILE.fclose(lf_m_file);
		fnd_file.put_line(fnd_file.LOG,'Matched Invoice File Created: '|| lc_m_file_name);
		-- copy to matched invoice file to xxfin_data/vps dir
		lc_dest_file_name := '/app/ebs/ct'||lc_instance_name||'/xxfin/ftp/out/vps/'||lc_m_file_name;
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
																   'XXCOMFILCOPY',
																   '',
																   '',
																   FALSE,
																   lc_dirpath||'/'||lc_m_file_name, --Source File Name
																   lc_dest_file_name,            --Dest File Name
																   '', '', 'Y'                   --Deleting the Source File
																  );
		IF ln_conc_file_copy_request_id > 0
		THEN
			COMMIT;
			-- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
															request_id   => ln_conc_file_copy_request_id,
															interval     => 10,
															max_wait     => 0,
															phase        => lc_phase,
															status       => lc_status,
															dev_phase    => lc_dev_phase,
															dev_status   => lc_dev_status,
															message      => lc_message
															);
		END IF;
		EXCEPTION WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
		END;
	END IF;
	OPEN unmatched_inv_cur;
	FETCH unmatched_inv_cur BULK COLLECT INTO l_unmatched_tab;
	CLOSE unmatched_inv_cur;
	fnd_file.put_line(fnd_file.LOG,'');
	fnd_file.put_line(fnd_file.LOG,'Unmatched Invoice Count :'||l_unmatched_tab.COUNT);
	IF l_unmatched_tab.COUNT>0 THEN
	   lc_unmatch_file:='Y';
	BEGIN
		lf_um_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									   lc_um_file_name,
									   'w',
									   ln_chunk_size);
		l_um_file_header :=
							'SOURCE'
							||'|'||'USTR'
							||'|'||'INOVICE#'
							||'|'||'INVOICE_DATE'
							||'|'||'VENDOR'
							||'|'||'LOCATION'
							||'|'||'PO_PRICE'
							||'|'||'AVG_COST'
							||'|'||'SKU'
							||'|'||'LINE_NUM'
							||'|'||'LIST_PRICE_PER_UNIT'
							||'|'||'QTY'
							||'|'||'AMOUNT';
		UTL_FILE.put_line(lf_um_file, l_um_file_header);
		FOR i IN 1.. l_unmatched_tab.COUNT
		LOOP
			lc_um_file_content :=
							l_unmatched_tab(i).source
							||'|'||
							'USTR'
							||'|'||
							l_unmatched_tab(i).invoice_num
							||'|'||
							l_unmatched_tab(i).invoice_date
							||'|'||
							l_unmatched_tab(i).ap_vendor
							||'|'||
							get_location(l_unmatched_tab(i).quick_po_header_id)
							||'|'||
							l_unmatched_tab(i).po_price
							||'|'||
							l_unmatched_tab(i).avg_cost
							||'|'||
							l_unmatched_tab(i).SKU
							||'|'||
							l_unmatched_tab(i).line_num
							||'|'||
							l_unmatched_tab(i).LIST_PRICE_PER_UNIT
							||'|'||
							l_unmatched_tab(i).invoice_qty
							||'|'||
							l_unmatched_tab(i).amount;
			UTL_FILE.put_line(lf_um_file,lc_um_file_content);
		END LOOP;
		UTL_FILE.fclose(lf_um_file);
		fnd_file.put_line(fnd_file.LOG,'Unmatched Invoice File Created: '|| lc_um_file_name);
		-- copy unmatched invoice file to vps dir
		lc_dest_file_name := '/app/ebs/ct'||lc_instance_name||'/xxfin/ftp/out/vps/'||lc_um_file_name;
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
																   'XXCOMFILCOPY',
																   '',
																   '',
																   FALSE,
																   lc_dirpath||'/'||lc_um_file_name, --Source File Name
																   lc_dest_file_name,            --Dest File Name
																   '', '', 'Y'                   --Deleting the Source File
																  );
		IF ln_conc_file_copy_request_id > 0
		THEN
			COMMIT;
			-- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request (
															request_id   => ln_conc_file_copy_request_id,
															interval     => 10,
															max_wait     => 0,
															phase        => lc_phase,
															status       => lc_status,
															dev_phase    => lc_dev_phase,
															dev_status   => lc_dev_status,
															message      => lc_message
															);
		END IF;
		EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
		END;
	END IF;
	IF lc_match_file='Y' THEN
	   xx_move_archive(lc_m_file_name);
	END IF;
	IF lc_unmatch_file='Y' THEN
	   xx_move_archive(lc_um_file_name);
	END IF;

EXCEPTION WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
END invoice_vps_extract;
END XX_AP_VPS_EXTRACT_PKG;
/
SHOW ERRORS;