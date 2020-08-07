CREATE OR REPLACE 
PACKAGE BODY APPS.XX_AP_VPS_EXTRACT_PKG
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
-- +============================================================================================+
AS
-- +======================================================================+
-- | Name        :  get_location                                  		  |
-- | Description :  This function is to get expense location			  |
-- |                                                                      |
-- | Parameters  :  p_po_header_id                        				  |
-- |                                                                      |
-- | Returns     :  v_location                                            |
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
	SELECT	a.source,
			'USTR',
			NVL(aps.attribute9,NVL(aps.vendor_site_code_alt,aps.vendor_site_id)) ap_vendor,
			a.invoice_num,
			TO_CHAR(a.invoice_date,'MM-DD-YYYY') invoice_date,
			TO_CHAR(a.creation_date,'MM-DD-YYYY') entry_dt,
			l.line_number,
			LTRIM(SUBSTR(hrl.location_code,1,6),'0') location,
			pol.unit_price po_price,
			NULL avg_cost,
			msi.segment1 item,
			l.line_type_lookup_code,
			l.quantity_invoiced,
			l.unit_price,
			l.amount,
			l.attribute11 reason_cd,
			a.voucher_num,
			l.description voucher_line_desc,
			pol.quantity original_po_qty,
			pol.unit_price original_po_cost,
			ph.segment1 ap_po_nbr,
			pol.line_num po_line_nbr,
			gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7 gl_account_id,
			aid.period_name
	FROM	mtl_system_items_b msi,
			po_lines_all pol,
			gl_code_combinations gcc,
			hr_locations_all hrl, 
			po_headers_all ph,
			ap_supplier_sites_all aps,
			ap_invoice_distributions_all aid,       
			ap_invoice_lines_all l,
			ap_invoices_all a
	WHERE 1=1
    AND EXISTS (SELECT 'x'
                 FROM  xx_fin_translatevalues tv
                      ,xx_fin_translatedefinition td
                WHERE td.TRANSLATION_NAME 	='XX_AP_TR_MATCH_INVOICES'
                AND tv.TRANSLATE_ID  		=td.TRANSLATE_ID
                AND tv.enabled_flag			='Y'
                AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
                AND tv.target_value1		=a.source
               )
	AND EXISTS (SELECT 'x'
				FROM XLA_EVENTS XEV,
					 XLA_TRANSACTION_ENTITIES XTE
				WHERE XTE.SOURCE_ID_INT_1=a.invoice_id
				AND XTE.APPLICATION_ID   = 200
				AND XTE.ENTITY_CODE      = 'AP_INVOICES'       
				AND XEV.ENTITY_ID        = XTE.ENTITY_ID
				AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
				AND xev.last_update_date BETWEEN p_inv_date AND SYSDATE
				)
	AND NOT EXISTS  (SELECT 'x'       
					 FROM AP_HOLDS_ALL
					 WHERE INVOICE_ID=a.invoice_id
					 AND RELEASE_LOOKUP_CODE IS NULL
					)
	AND l.invoice_id			=a.invoice_id
	AND a.last_update_date 		BETWEEN p_inv_date AND SYSDATE 					
	AND aid.invoice_id 			= l.invoice_id
	AND aid.invoice_line_number = l.line_number  
    AND aps.vendor_site_id		=a.vendor_site_id
    AND ph.po_header_id(+)		=NVL(a.po_header_id,a.quick_po_header_id)
	AND hrl.location_id 		= l.ship_to_location_id
	AND gcc.code_combination_id	=aid.dist_code_combination_id  
	AND pol.po_line_id(+)		=l.po_line_id
	AND msi.inventory_item_id(+)=l.inventory_item_id
	AND msi.organization_id(+)+0=441
	AND 'APPROVED'				=AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.invoice_id, 
																	 a.invoice_amount,
																	 a.payment_status_flag,
																	 a.invoice_type_lookup_code
																	);
	TYPE matched_inv_tab_type IS TABLE OF matched_inv_cur%ROWTYPE;
	CURSOR unmatched_inv_cur IS
	SELECT 	ai.source,
			'USTR',
			ai.invoice_num,
			TO_CHAR(ai.invoice_date,'MM-DD-YYYY') invoice_date,
			NVL(aps.attribute9,NVL(aps.vendor_site_code_alt,aps.vendor_site_id)) ap_vendor,
			ai.quick_po_header_id,
			pol.line_num line_num,
			pol.unit_price po_price,     
			NULL avg_cost,          
			msi.segment1 sku,
			l.line_type_lookup_code,
			l.unit_price list_price_per_unit,
			l.quantity_invoiced invoie_qty,
			l.amount
	FROM 
		    mtl_system_items_b msi,
  		    po_lines_all pol,
		    ap_supplier_sites_all aps,
		    ap_invoice_lines_all l,
		    ap_invoices_all ai
	WHERE 1=1
    AND ai.invoice_type_lookup_code 	= 'STANDARD'
    AND ai.invoice_num 					NOT LIKE '%ODDBUIA%'
    AND ai.cancelled_date 				IS NULL
    AND ai.validation_request_id		=-9999999999
    AND l.invoice_id					=ai.invoice_id
    AND aps.vendor_site_id				=ai.vendor_site_id+0
    AND pol.po_header_id(+)				=NVL(ai.po_header_id,ai.quick_po_header_id)
    AND pol.item_id(+)					=l.inventory_item_id  
    AND msi.inventory_item_id(+)		=l.inventory_item_id
    AND msi.organization_id(+)+0		=441  
	UNION
	SELECT	ai.source,
			'USTR',
			ai.invoice_num,
			TO_CHAR(ai.invoice_date,'MM-DD-YYYY') invoice_date,
			NVL(aps.attribute9,NVL(aps.vendor_site_code_alt,aps.vendor_site_id)) ap_vendor,
			ai.quick_po_header_id,
			pol.line_num po_line_num,
			pol.unit_price po_price,     
			NULL avg_cost,          
			msi.segment1 sku,
			l.line_type_lookup_code,
			l.unit_price list_price_per_unit,
			l.quantity_invoiced invoie_qty,
			l.amount 
	FROM 	mtl_system_items_b msi,
			po_lines_all pol,
			ap_supplier_sites_all aps,
			ap_invoice_lines_all l,
			ap_invoices_all ai,
		    (SELECT		DISTINCT invoice_id
						FROM ap_holds_all aph
						WHERE aph.creation_date > '01-JAN-11' 
						AND NVL(aph.status_flag,'S')= 'S'			   
						AND aph.release_lookup_code IS NULL
			)h 
	WHERE ai.invoice_id				=h.invoice_id
	AND ai.invoice_type_lookup_code = 'STANDARD'
	AND ai.invoice_num 				NOT LIKE '%ODDBUIA%'
	AND ai.cancelled_date 			IS NULL
	AND ai.validation_request_id 	IS NULL
	AND ai.creation_date 			> '31-OCT-17'
	AND l.invoice_id				=ai.invoice_id
	AND aps.vendor_site_id			=ai.vendor_site_id+0
	AND pol.po_header_id(+)			=NVL(ai.po_header_id,ai.quick_po_header_id)
	AND pol.item_id(+)				=l.inventory_item_id  
	AND msi.inventory_item_id(+)	=l.inventory_item_id
	AND msi.organization_id(+)+0	=441     
	AND EXISTS (SELECT 'x'
				FROM xx_fin_translatedefinition xftd, 
					 xx_fin_translatevalues xftv,
					 ap_supplier_sites_all site
				WHERE site.vendor_site_id =ai.vendor_site_id+0
				AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES' 
				AND xftd.translate_id     = xftv.translate_id
				AND xftv.target_value1    = site.attribute8||''
				AND xftv.enabled_flag     = 'Y'
				AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
				)   		
	AND EXISTS (SELECT 'x'
				FROM xx_fin_translatedefinition xftd, 
					 xx_fin_translatevalues xftv 
				WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
				AND xftd.translate_id	 	= xftv.translate_id
				AND xftv.target_value1    	= ai.source||''
				AND xftv.enabled_flag     	= 'Y'
				AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
				);
	TYPE unmatched_inv_tab_type IS TABLE OF unmatched_inv_cur%ROWTYPE;
	CURSOR get_dir_path
	IS
		SELECT directory_path 
		FROM dba_directories 
		WHERE directory_name = 'XXFIN_OUTBOUND';
	CURSOR get_inv_date 
	IS 
		SELECT b.actual_start_date	program_run_date	--TO_DATE(b.actual_start_date,'DD-MON-YYYY') 
        FROM  (
			SELECT ROWNUM AS rn, cp.actual_start_date 
            FROM (
                SELECT actual_start_date  
                FROM   fnd_concurrent_requests
                WHERE  concurrent_program_id = (SELECT concurrent_program_id
                                                 FROM   fnd_concurrent_programs_vl
                                                 WHERE  user_concurrent_program_name = 'OD: AP VPS Invoice Extract'
                                                )
                ORDER BY actual_start_date DESC) cp) b
        WHERE  rn = 2;
	l_unmatched_tab 				unmatched_inv_tab_type; 
	l_matched_tab 					matched_inv_tab_type; 
	lf_um_file              		UTL_FILE.file_type;
	l_um_file_header        		VARCHAR2(32000);
	lc_um_file_content				VARCHAR2(32000);
	lf_m_file             			UTL_FILE.file_type;
	l_m_file_header         		VARCHAR2(32000);
	lc_m_file_content				VARCHAR2(32000);
	ln_chunk_size           		BINARY_INTEGER:= 32767;
	lc_um_file_name					VARCHAR2(250) :='UNMATCHED_INV_DATA_'||TO_CHAR(SYSDATE,'DDMMYYYY');
	lc_m_file_name					VARCHAR2(250) :='MATCHED_INV_DATA_'||TO_CHAR(SYSDATE,'DDMMYYYY');
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
BEGIN
	--get file dir path
	OPEN get_dir_path;
	FETCH get_dir_path INTO lc_dirpath;
	CLOSE get_dir_path;

	OPEN get_inv_date;
	FETCH get_inv_date INTO ld_date;
	CLOSE get_inv_date;
	
	IF ld_date IS NULL then
	ld_date := SYSDATE-1;
	END IF;
		
	SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','INSTANCE_NAME')),1,8) 
	INTO lc_instance_name
	FROM dual;
	  
	SELECT NAME
	INTO   lc_file_name_instance
	FROM   v$database;
	
	OPEN matched_inv_cur (ld_date);
	FETCH matched_inv_cur BULK COLLECT INTO l_matched_tab;
	CLOSE matched_inv_cur;
	fnd_file.put_line(fnd_file.LOG,'Matched Invoice Count :'||l_matched_tab.COUNT);
	IF l_matched_tab.COUNT>0 THEN
		BEGIN
			lf_m_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									   lc_m_file_name
									   || '.txt',
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
		fnd_file.put_line(fnd_file.LOG,
									 'Matched Invoice File Created: '
								  || lc_m_file_name
								  || '.txt');
		-- copy to matched invoice file to xxfin_data/vps dir
		lc_dest_file_name := '/app/ebs/ct'||lc_instance_name||'/xxfin/ftp/out/vps/'||lc_m_file_name;
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 
																   'XXCOMFILCOPY', 
																   '', 
																   '', 
																   FALSE, 
																   lc_dirpath||'/'||lc_m_file_name||'.txt', --Source File Name
																   lc_dest_file_name,            --Dest File Name
																   '', '', 'Y'                   --Deleting the Source File
																  );
		IF ln_conc_file_copy_request_id > 0
		THEN
			COMMIT;
			fnd_file.put_line(fnd_file.LOG,'While Waiting to extract Matched Invoices for VPS to Finish');
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
			fnd_file.put_line(fnd_file.LOG,'Status :'||lc_status);
			fnd_file.put_line(fnd_file.LOG,'dev_phase :'||lc_dev_phase);
			fnd_file.put_line(fnd_file.LOG,'dev_status :'||lc_dev_status);
			fnd_file.put_line(fnd_file.LOG,'Message :'||lc_message);
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
	BEGIN
		lf_um_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
									   lc_um_file_name
									   || '.txt',
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
								l_unmatched_tab(i).invoie_qty
								||'|'||
								l_unmatched_tab(i).amount;
			UTL_FILE.put_line(lf_um_file,lc_um_file_content);
		END LOOP;
		UTL_FILE.fclose(lf_um_file);
		fnd_file.put_line(fnd_file.LOG,
									 'Unmatched Invoice File Created: '
								  || lc_um_file_name
								  || '.txt');
		-- copy unmatched invoice file to vps dir
		lc_dest_file_name := '/app/ebs/ct'||lc_instance_name||'/xxfin/ftp/out/vps/'||lc_um_file_name;
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 
																   'XXCOMFILCOPY', 
																   '', 
																   '', 
																   FALSE, 
																   lc_dirpath||'/'||lc_um_file_name||'.txt', --Source File Name
																   lc_dest_file_name,            --Dest File Name
																   '', '', 'Y'                   --Deleting the Source File
																  );
		IF ln_conc_file_copy_request_id > 0
		THEN
			COMMIT;
			fnd_file.put_line(fnd_file.LOG,'While Waiting to extract UnMatched Invoiced for VPS to Finish');
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
			fnd_file.put_line(fnd_file.LOG,'Status :'||lc_status);
			fnd_file.put_line(fnd_file.LOG,'dev_phase :'||lc_dev_phase);
			fnd_file.put_line(fnd_file.LOG,'dev_status :'||lc_dev_status);
			fnd_file.put_line(fnd_file.LOG,'Message :'||lc_message);
		END IF;					
		EXCEPTION WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);
		END;
	END IF;
EXCEPTION WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.LOG,SQLCODE||SQLERRM);		
END invoice_vps_extract;  
END XX_AP_VPS_EXTRACT_PKG;
/