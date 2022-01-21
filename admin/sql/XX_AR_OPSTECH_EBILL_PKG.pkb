CREATE OR REPLACE 
PACKAGE BODY XX_AR_OPSTECH_EBILL_PKG
AS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Providge Consulting                                      |
  ---+============================================================================================+
  ---|    Application  :        AR                                                                |
  ---|                                                                                            |
  ---|    Name         :        XX_AR_OPSTECH_EBILL_PKG.pkb                                       |
  ---|                                                                                            |
  ---|    Description  :        Generate text file from Oracle AR to OD's Ebill Central System    |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             20-AUG-2018       Aniket J           Initial Version                    |
  ---|    1.1             27-SEP-2018       Aniket J           Updated Translation for FTP		  |
  ---|    1.2             27-SEP-2018       Aniket J           Updated Logs in PKG		          |
  ---|    1.3             11-NOV-2018       Aniket J           Updated for Child Program          |
  ---|    1.4             14-DEC-2018       Aniket J           Updated for NAIT-75751             |
  ---+============================================================================================+
  g_pkb_version      NUMBER (2, 1) := '1.1';
  
  --==================================================
  --Main procedure that extracts the data from Source To a file
  --===================================================
 PROCEDURE xx_opstech_ebill_main(
    x_error_buff  OUT NOCOPY VARCHAR2 ,
    x_ret_code    OUT NOCOPY   VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_as_of_date  IN VARCHAR2 ,
    p_debug_flag  IN VARCHAR2 )
IS
  -- Variables
  -- UTL FILE Details
  lc_file_handle UTL_FILE.file_type;
  p_file_name         VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_src VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_dst VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_arc VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path     VARCHAR2 (100) := TO_CHAR (NULL);
  
  ---
  ln_req_id            NUMBER;
  lc_wait              BOOLEAN;
  lc_conc_phase        VARCHAR2 (50);
  lc_conc_status       VARCHAR2 (50);
  lc_dev_phase         VARCHAR2 (50);
  lc_dev_status        VARCHAR2 (50);
  lc_conc_message      VARCHAR2 (50);
  lc_err_msg           VARCHAR2 (1000);
  ln_responsibility_id NUMBER;
  ln_application_id    NUMBER;
    
  --Records Type
  TYPE idheader IS TABLE OF header_rec_type INDEX BY BINARY_INTEGER;
  TYPE idline IS TABLE OF line_rec_type INDEX BY BINARY_INTEGER;
  
  --Initialize
  vidheader idheader ; 
  vidline idline ;     
  --Count Variables
  lc_prev_cbi_id ar_cons_inv_all.cons_inv_id%TYPE := 0;
  lc_curr_cbi_id ar_cons_inv_all.cons_inv_id%TYPE := 0;
  --Values Capturing
  ln_attr_group_id        NUMBER;
  ld_issue_date           DATE := TO_DATE (NULL);
  ln_total_inv_amt        NUMBER;
  ln_total_frgt_amt       NUMBER;
  ln_total_grsale_amt     NUMBER;
  ln_total_tax_amt        NUMBER;
  ln_trx_number           NUMBER;
  ln_customer_trx_line_id NUMBER;
  ln_line_number          NUMBER;
  lc_description          NUMBER;
  lc_uom_code             NUMBER;
  ln_quantity_invoiced    NUMBER;
  ln_unit_selling_price   NUMBER;
  ln_extended_amount      NUMBER;
  ln_tax_amount           NUMBER;
  ln_org_id               NUMBER;
  --Order Info values
  lc_order_level_comment   xx_om_header_attributes_all.comments%TYPE              := NULL;
  lc_purchase_order_number ra_customer_trx_all.purchase_order%TYPE                := NULL;
  ln_order_header_id       ra_customer_trx_all.attribute14%TYPE                   := NULL;
  ln_orig_inv_number       oe_order_headers.order_number%TYPE                     := NULL;
  lc_transaction_class     ra_cust_trx_types_all.type%TYPE                        := NULL;
  ln_ship_to_site_use_id   ra_customer_trx_all.ship_to_site_use_id%TYPE           := NULL;
  lc_cost_center_desc_hdr  xx_om_header_attributes_all.CUST_DEPT_DESCRIPTION%TYPE := NULL;
  lc_cost_center_dept      xx_om_header_attributes_all.cost_center_dept%TYPE      := NULL;
  ld_ordered_date          oe_order_headers.ordered_date%TYPE                     := NULL;
  lc_bill_to_contact_name  xx_om_header_attributes_all.cust_contact_name%TYPE     := NULL;
  lc_cust_name             hz_parties.party_name%TYPE          					  := NULL;
  lc_bill_to_name          xx_om_header_attributes_All.bill_to_name%TYPE          := NULL;
  lc_cust_sku 			   ra_customer_trx_lines.translated_description%TYPE	  := NULL;		
  --error handling
  lc_error_location   VARCHAR2(1000) := NULL;
  lc_error_debug      VARCHAR2(1000) := NULL;
  lc_err_location_msg VARCHAR2(1000) := NULL;
  lb_debug_flag       BOOLEAN;
  lc_errormsg         VARCHAR2 (4000) := NULL;
  --User Defined Exception
  l_exp_insert_stg  EXCEPTION;
  l_exp_up_cons_tbl EXCEPTION;
  -- FND related columns
  ln_request_id   NUMBER := fnd_global.conc_request_id;
  ln_user_id      NUMBER := fnd_global.user_id ;
  lc_request_data VARCHAR2(30);
  -- New variable for
  ln_operating_unit  NUMBER := NULL;
  lc_error_loc       VARCHAR2(2000);
  lc_error_msg       VARCHAR2(2000);
  ln_error_code      VARCHAR2(20);
  ln_limit_size      NUMBER        := 500; --Since we have max 1800 ops customer
  ln_cust_count      NUMBER        := 0;
  lc_ar_cons_prcss   VARCHAR2(2)   := 'N';
  ln_cust_acct       NUMBER        := 0;
  ln_item_master_org NUMBER        := NULL;
  --+============================================================
  -- Cursor for getting the Invoice Header Information
  --+============================================================
  CURSOR lcu_header(p_attr_group_id NUMBER)
  IS
    SELECT *
    FROM
      (SELECT TO_CHAR (NULL) trx_number,
        aci.site_use_id billing_site_id,
        aci.term_id term_id,
        aci.cons_inv_id cons_inv_id,
        aci.cons_billing_number cons_billing_number,
        acitl.customer_trx_id customer_trx_id,
        SUBSTR(hca.orig_system_reference,1,8) orig_system_reference,
        TO_CHAR (NULL) site_use_code,
        TO_CHAR (NULL) purchase_order_number,
        TO_CHAR (NULL) bill_to_customer_number,
        aci.cut_off_date cut_off_date,
        TO_CHAR(aci.bill_to_date,'MM/DD/YYYY') bill_to_date,
        TO_CHAR(aci.due_date,'MM/DD/YYYY') due_date,
        aci.term_name NAME,
        TO_CHAR (NULL) interface_header_attribute2,
        TO_CHAR (NULL) tax_registration_number,
        TO_CHAR (NULL) ship_to_contact,
        TO_DATE (NULL) TRX_DATE,
        TO_CHAR (NULL) ship_to_location,
        hca.account_name ,
        aci.org_id org_id,
        xcae.extension_id extension_id,
        aci.customer_id customer_id,
        TO_CHAR (NULL) ordsourcecd,
        NULL specl_handlg_cd,
        NULL billing_term,
        TO_DATE (NULL) invoice_date,
        TO_CHAR (NULL) billing_id,
        xcae.n_ext_attr2 cust_doc_id,
        xcae.creation_date,
        xcae.cust_account_id ,
        xcae.c_ext_attr14 ,
        xcae.c_ext_attr3
      FROM
        (SELECT arci.customer_id,
          TRUNC (arci.due_date) due_date,
          TO_DATE(arci.attribute1) - 1 bill_to_date,
          arci.cons_billing_number,
          arci.cons_inv_id,
          hzcp.standard_terms term_id,
          SUBSTR (rt.description, 1, 15) term_name,
          arci.site_use_id,
          TO_DATE(arci.attribute1) - 1 cut_off_date,
          arci.currency_code,
          arci.issue_date,
          arci.org_id
        FROM ar_cons_inv arci,
          hz_customer_profiles hzcp,
          ra_terms_tl rt
        WHERE hzcp.cust_account_id = arci.customer_id
        AND hzcp.site_use_id       = arci.site_use_id
        AND rt.term_id             = hzcp.standard_terms
        AND rt.language            =USERENV('LANG')
        AND arci.status           IN ( 'FINAL' ,'ACCEPTED')
        AND ( arci.attribute4     IS NULL
        AND arci.attribute15      IS NULL)
        ) aci,
      (SELECT extension_id,
        cust_account_id,
        c_ext_attr14 ,
        c_ext_attr3,
        n_ext_attr2,
        creation_date
      FROM xx_cdh_cust_acct_ext_b
      WHERE c_ext_attr1                  = 'Consolidated Bill'
      AND c_ext_attr3                    = 'OPSTECH'
      AND c_ext_attr16                   = 'COMPLETE'
      AND c_ext_attr2                    = 'Y'
      AND attr_group_id                  = p_attr_group_id
      AND d_ext_attr1                   <= g_as_of_date
      AND NVL(d_ext_attr2,g_as_of_date) >= g_as_of_date
      ) xcae,
      (SELECT a.cons_inv_id,
        a.customer_trx_id
      FROM ar_cons_inv_trx_lines_all a
      WHERE 1 = 1
      GROUP BY A.Cons_Inv_Id,
        a.customer_trx_id
      ) acitl,
      hz_cust_accounts hca
    WHERE 1                  = 1
    AND aci.cons_inv_id      = acitl.cons_inv_id
    AND aci.customer_id      = xcae.cust_account_id
    AND xcae.cust_account_id = hca.cust_account_id
    AND EXISTS
      (SELECT 1
      FROM ar_payment_schedules arps
      WHERE 1                  = 1
      AND arps.customer_trx_id = acitl.customer_trx_id
      AND arps.amount_due_original NOT BETWEEN ln_write_off_amt_low AND ln_write_off_amt_high
      )
    AND xx_ar_inv_freq_pkg.compute_effective_date (xcae.c_ext_attr14, aci.cut_off_date ) = g_as_of_date
     ORDER BY xcae.cust_account_id
      );
      
    --+=================================================================
    -- Cursor to fetch invoice related information.
    --+=================================================================
    CURSOR lcu_inv_lines( p_customer_trx_id IN NUMBER ,p_cons_inv_id IN NUMBER , ln_item_master_org IN NUMBER )
    IS
	SELECT customer_trx_id customer_trx_id,
	  customer_trx_line_id customer_trx_line_id,
	  line_number line_number,
	  (SELECT mtlsi.segment1 item_number
	  FROM mtl_system_items mtlsi
	  WHERE 1                     = 1
	  AND mtlsi.organization_id   = ln_item_master_org
	  AND mtlsi.inventory_item_id = line.inventory_item_id
	  ) inventory_item_id,
	  description description,
	  uom_code uom_code,
	  quantity_invoiced quantity_invoiced,
	  unit_selling_price unit_selling_price,
	  extended_amount extended_amount,
	  tax_amount tax_amount,
	  org_id org_id
	FROM ar_cons_inv_trx_lines line
	WHERE customer_trx_id = p_customer_trx_id
	AND cons_inv_id       = p_cons_inv_id
	AND EXISTS (SELECT 1
				FROM  ra_customer_trx_lines l
				WHERE l.customer_trx_line_id    = line.customer_trx_line_id
				AND   l.translated_description IS NOT NULL
				)
	ORDER BY line.customer_trx_id,
	  line.customer_trx_line_id,
	  line.line_number ;
 
--+=================================================================
-- Cursor to fetch FTP paths information.
--+=================================================================
	CURSOR lcu_translation_ftp_value
	IS
	  SELECT xftv.source_value1 ,
		xftv.source_value2,
		xftv.target_value1,
		NVL(xftv.target_value2, dir.directory_path) dir_path
	  FROM xx_fin_translatedefinition xftd ,
		xx_fin_translatevalues xftv ,
		dba_directories dir
	  WHERE xftd.translate_id   = xftv.translate_id
	  AND xftv.source_value1    = 'OPSTECH'
	  AND xftd.translation_name ='XX_AR_EBL_OPSTCH_PATH'
	  AND xftv.enabled_flag     ='Y'
	  AND xftv.target_value1    = dir.directory_name(+)
	  AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1));
    -- Body
 BEGIN
    -- To catch exception out side block added
	--+=================================================================
	-- Initialize FND request 
	--+=================================================================
    ln_request_id   := fnd_global.conc_request_id;
    lc_request_data := fnd_conc_global.request_data;
 
    IF (lc_request_data IS NULL) THEN 
    -- To catch exception out side block added
    BEGIN 
	      --+=================================================================
		  -- Parameters Passed 
		  --+=================================================================
		  lc_err_location_msg := ' Parameters ==>' || CHR(13) ||
								 ' File Path : ' || p_file_path || CHR(13) ||
								 ' Billing Date : '|| p_as_of_date || CHR(13) ||
								 ' Debug flag : ' || p_debug_flag || CHR(13) ;
		  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
		  
		  --Initialization of parameters
		  --Default Logs
		  lc_err_location_msg := ' Profile Values ==>' || CHR(13) ||
								 ' WRITEN_OFF_AMT_LOW_VALUE  :  '||xx_ar_gen_ebill_pkg.ln_write_off_amt_low ||
								 ' WRITEN_OFF_AMT_HIGH_VALUE :  '||xx_ar_gen_ebill_pkg.ln_write_off_amt_high;								 
		  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
		  --+=================================================================
		  -- Get profile operating unit
		  --+=================================================================
		  ln_operating_unit := fnd_profile.VALUE ('ORG_ID');

		  --+=================================================================
		  -- Assign billing date to as of date parameter
		  --+=================================================================
		  g_as_of_date := TRUNC (fnd_conc_date.string_to_date (p_as_of_date));
		  
		  --+=================================================================
		  lc_err_location_msg := ' Billing Date after Canonical Format: '|| g_as_of_date || CHR(13);								 
		  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );		  

		  --+=================================================================
		  -- Assign debug flag value
		  --+=================================================================
		  IF (p_debug_flag = 'Y') THEN
			lb_debug_flag := TRUE;
			g_debug_flag  := TRUE;
		  ELSE
			lb_debug_flag := FALSE;
			g_debug_flag  := FALSE;
		  END IF;

		  -- ================================
		  -- Get Item Master Organization ID
		  -- ================================
		  BEGIN
			SELECT odef.organization_id
			INTO ln_item_master_org
			FROM org_organization_definitions odef
			WHERE 1                    = 1
			AND odef.organization_name = 'OD_ITEM_MASTER';
			--fnd_file.put_line (fnd_file.LOG, 'Item Master Organization ID :' || ln_item_master_org );
		  EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			ln_item_master_org := TO_NUMBER (NULL);
			fnd_file.put_line (fnd_file.log, 'In No data found, Item Master Organization ID :' || ln_item_master_org );
		  WHEN OTHERS THEN
			ln_item_master_org := TO_NUMBER (NULL);
			fnd_file.put_line (fnd_file.log, 'In Other errors, Item Master Organization ID :' || ln_item_master_org );
		  END;
		  
		  --+=================================================================
		  -- Assign File Name details and OPen the file
		  --+=================================================================
		  p_file_name    := 'XX_OPSTECH_'||ln_request_id||'_'|| TO_CHAR (SYSDATE, 'DDMONYYYYHH24MISS')||'.txt';
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'w', 32767);
		  
		  --+=================================================================
		  -- start processing for file processing
		  --+=================================================================		  

		  --==============================================================
		  -- Get the group id information 
		  --==============================================================

		  --Group id
			  BEGIN
				SELECT attr_group_id
				INTO ln_attr_group_id
				FROM ego_attr_groups_v
				WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
				AND attr_group_name   = 'BILLDOCS' ;
			  EXCEPTION
			  WHEN OTHERS THEN
				--Making default as Central E bill Group ID
				ln_attr_group_id := 166 ;
			  END;
			  
		  
		  --==============================================================
		  -- Initialize the customer count to stop multiple insertion in the FILE table 
		  --==============================================================
		  ln_cust_acct := 0 ;
		  
		  --==============================================================
		  -- Open cursor for header on the basis for cust id and billing term logic
		  --==============================================================
	 
	 OPEN lcu_header(ln_attr_group_id);
	
        	-- Header loop Start
		    LOOP
			    FETCH lcu_header BULK COLLECT INTO vidheader LIMIT ln_limit_size;
			    EXIT
		        WHEN vidheader.COUNT = 0;
			
			--================================
			--Load Invoice related information by PL SQL table
			--================================
			
			IF vidheader.COUNT > 0 THEN
			  lc_ar_cons_prcss := 'Y';
			  
			  FOR i IN 1 .. vidheader.COUNT
			   
       		   LOOP
				--==============================================================
				-- Insert file details for processing
				--==============================================================
				BEGIN
		
                	IF ln_cust_acct        <> vidheader(i).cust_account_id THEN
					
						ln_cust_acct         := vidheader(i).cust_account_id ;
						ln_cust_count       := ln_cust_count+1 ;
						lc_err_location_msg := ' Insert Record into XX_AR_OPSTECH_FILE TAB   : '|| ln_cust_acct;
					    xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );
						
					INSERT
					INTO XX_AR_OPSTECH_FILE
					  (
						process_id ,
						cust_doc_id ,
						cons_billing_number ,
						aops_customer_number,
						customer_name,
						cust_account_id ,
						billing_term ,
						delivery_method ,
						billing_date ,
						file_type ,
						p_file_name ,
						org_id ,
						status ,
						processed_flag ,
						request_id ,
						reprocess_flag ,
						reprocess_request_id,
						error_message ,
						last_update_date ,
						last_updated_by ,
						creation_date ,
						created_by ,
						last_update_login
					  )
					  VALUES
					  (
						xx_ar_opstech_file_s.NEXTVAL,
						vidheader(i).cust_doc_id,
						vidheader(i).cons_billing_number,
						vidheader(i).orig_system_reference,
						vidheader(i).account_name,
						vidheader(i).cust_account_id ,
						vidheader(i).c_ext_attr14,
						vidheader(i).c_ext_attr3,
						g_as_of_date,
						'TXT',
						p_file_name,
						ln_operating_unit,
						'READY_FOR_PROCESS',
						'N',
						ln_request_id,
						'N',
						NULL,
						NULL,
						SYSDATE,
						ln_user_id,
						SYSDATE,
						ln_user_id,
						ln_user_id
					  );
					
					COMMIT;
					
				  END IF;
			EXCEPTION
			  WHEN OTHERS THEN
				  fnd_file.put_line(fnd_file.log,' Exception in File Record Insertion For Cust Doc Id   : '|| vidheader(i).cust_doc_id);
				  lc_errormsg := (' Exception in File Table insert ' || SQLERRM);
			  ROLLBACK;
			  RAISE; -- Making Concurrent Program In Error
		END;
				
				--==============================================================
				-- Making this as SAVE POINT For processing
				--==============================================================		
				
			 SAVEPOINT insertsuccrec;
				
				BEGIN
				  SELECT rca.trx_number ,
					rca.purchase_order ,
					rca.attribute14 ,
					rca.ship_to_site_use_id ,
					rctt.TYPE
				  INTO ln_trx_number ,
					lc_purchase_order_number ,
					ln_order_header_id ,
					ln_ship_to_site_use_id ,
					lc_transaction_class
				  FROM ra_customer_trx rca ,
					ra_cust_trx_types_all rctt
				  WHERE 1                   =1
				  AND rctt.cust_trx_type_id = rca.cust_trx_type_id
				  AND customer_trx_id       = vidheader (i).customer_trx_id;
				EXCEPTION
				WHEN OTHERS THEN
				  ln_trx_number            := NULL;
				  lc_purchase_order_number := NULL;
				  ln_order_header_id       := NULL;
				  ln_ship_to_site_use_id   := NULL;
				  lc_transaction_class     := NULL;
				END;
								
				vidheader (i).trx_number            := ln_trx_number;
				vidheader (i).purchase_order_number := lc_purchase_order_number;
				ln_total_inv_amt                    := XX_AR_OPSTECH_EBILL_PKG.get_inv_amounts( vidheader (i).customer_trx_id , 'INV_AMT');
				ln_total_tax_amt                    := XX_AR_OPSTECH_EBILL_PKG.get_inv_amounts( vidheader (i).customer_trx_id , 'TAX_AMT');
				ln_total_frgt_amt                   := XX_AR_OPSTECH_EBILL_PKG.get_inv_amounts( vidheader (i).customer_trx_id , 'FRT_AMT');
				
				--+==========================================================
				-- For getting the Total Gross Sale  Amount
				--+==========================================================
				ln_total_grsale_amt := ln_total_inv_amt - ( ln_total_frgt_amt + ln_total_tax_amt );
								
				--+==========================================================
				-- For Get Ship to Name from order HDR info
				--+==========================================================
				lc_cust_name := XX_AR_OPSTECH_EBILL_PKG.get_cust_name(vidheader(i).cust_account_id);
								
				--+==========================================================
				-- Get Orig INV number in case of Credit Memo
				--+==========================================================
				IF lc_transaction_class = 'CM' THEN
				  ln_orig_inv_number   := XX_AR_OPSTECH_EBILL_PKG.get_orig_inv_num (ln_order_header_id ) ;
				ELSE
				  ln_orig_inv_number:= NULL;
				END IF;
				--+==========================================================
				-- For getting the Order Information
				--+==========================================================
				BEGIN
				  SELECT xoha.comments order_level_comment ,
					xoha.cust_dept_description,
					xoha.cost_center_dept,
					oeha.ordered_date ,
					xoha.cust_contact_name
				  INTO lc_order_level_comment,
					lc_cost_center_desc_hdr,
					lc_cost_center_dept ,
					ld_ordered_date,
					lc_bill_to_contact_name
				  FROM xx_om_header_attributes_all xoha,
					oe_order_headers oeha
				  WHERE 1            =1
				  AND xoha.header_id = oeha.header_id
				  AND oeha.header_id = ln_order_header_id;
				EXCEPTION
				WHEN OTHERS THEN
				  lc_cost_center_desc_hdr := NULL;
				  lc_cost_center_dept     := NULL;
				  lc_order_level_comment  := NULL;
				  ld_ordered_date         := NULL;
				  lc_bill_to_contact_name := NULL;
				END;				
				--+==========================================================
				-- Header file writing in below line
				--+==========================================================
				UTL_FILE.PUT_LINE(lc_file_handle,'H' || CHR(9) 
						|| RPAD(ln_trx_number,20) || CHR(9) 
						|| RPAD(NVL(TO_CHAR(ln_orig_inv_number),' '),20) || CHR(9) 
						|| NVL( vidheader (i).bill_to_date,  RPAD(' ',8,' ') )   || CHR(9) 
						|| RPAD(' ',30) || CHR(9)
						|| NVL( vidheader (i).due_date,  RPAD (' ', 8, ' ') )  || CHR(9) 
						|| RPAD( vidheader (i).NAME , 15 )  || CHR(9) 
						|| RPAD(lc_cost_center_dept ,30) || CHR(9)   
						|| RPAD(lc_cust_name,30) || CHR(9)      
						|| NULL || CHR(9) 
						|| RPAD(lc_bill_to_contact_name,30) || CHR(9) 
						|| RPAD(lc_purchase_order_number,30) || CHR(9) 
						|| NULL || CHR(9) 
						|| NVL(TO_CHAR(ld_ordered_date,'MM/DD/YYYY'),RPAD (' ', 8, ' ')) || CHR(9) 
						|| NULL || CHR(9) 
						|| NULL || CHR(9) 
						|| LPAD(TRIM(TO_CHAR(NVL(ln_total_grsale_amt,0),'999999990.99')),13)|| CHR(9) 
						|| LPAD(TRIM(TO_CHAR(NVL(ln_total_frgt_amt,0),'999999990.99')),13)  || CHR(9) 
						|| LPAD(TRIM(TO_CHAR(NVL(ln_total_tax_amt,0), '999999990.99')),13)  || CHR(9) 
						|| LPAD(TRIM(TO_CHAR(NVL(ln_total_inv_amt,0),'999999990.99')),13)   || CHR(13)); 
				--+==========================================================
				-- For getting the Line Information START
				--+==========================================================
				lc_err_location_msg := 'Before Line Cursor Open For trx_id : '|| vidheader (i).customer_trx_id;
				xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );				
				--+==========================================================
				-- OPEN Line Level Cursor 
				--+==========================================================			
			 OPEN lcu_inv_lines (vidheader (i).customer_trx_id, vidheader (i).cons_inv_id ,ln_item_master_org);
				LOOP
					FETCH lcu_inv_lines BULK COLLECT INTO vidline LIMIT ln_limit_size;
				    EXIT
					WHEN vidline.COUNT       = 0;
						IF vidline.COUNT       > 0 THEN				  
						lc_err_location_msg := ' After Line Cursor Open Printing Start';
						xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );
								
							FOR j IN 1 .. vidline.COUNT
							LOOP
								BEGIN 
									SELECT translated_description
									INTO   lc_cust_sku
									FROM  ra_customer_trx_lines l
									WHERE l.customer_trx_line_id    = vidline (j).customer_trx_line_id
									AND   l.translated_description IS NOT NULL;
								EXCEPTION WHEN OTHERS THEN 
								lc_err_location_msg := ' Exception in OD SKU details : '|| vidline (j).customer_trx_line_id;
								xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );
				     			END;							
							  --+==========================================================
							  --  Line Information Writing in file
							  --+==========================================================
							  UTL_FILE.put_line(lc_file_handle,'D' || CHR(9) 
							  || vidline (j).line_number || CHR(9) 
							  || RPAD(ln_trx_number ,20)  || CHR(9) 
							  || RPAD(lc_cust_sku , 9 ) || CHR(9) 
							  || RPAD(vidline (j).description ,30)  || CHR(9) 
							  || NVL(vidline (j).quantity_invoiced , 0)|| CHR(9) 
							  || RPAD (vidline (j).uom_code ,2 )  || CHR(9) 
							  || LPAD(TRIM(TO_CHAR(vidline (j).unit_selling_price,'999999990.99')),13) || CHR(9) 
							  || NULL || CHR(9) 
							  || NULL || CHR(9) 
							  || NULL || CHR(13) );
							
							END LOOP; ---Vidline			
						END IF;   --Count iF
					END LOOP;  -- LINE Loop
		     CLOSE lcu_inv_lines;
				--+==========================================================
				-- Insert Records in STG table
				--+==========================================================
       			 BEGIN
						INSERT
						  INTO XX_AR_OPSTECH_BILL_STG
							(
							  cons_inv_id ,
							  customer_id ,
							  trx_number ,
							  orig_inv_number,
							  customer_trx_id ,
							  cons_billing_number,
							  cust_doc_id ,
							  billing_term ,
							  delivery_method ,
							  bill_from_date ,
							  bill_due_date ,
							  billing_date,
							  org_id ,
							  bill_to_site_id ,
							  ship_to_site_id ,
							  status ,
							  processed_flag ,
							  request_id ,
							  error_message ,
							  last_update_date ,
							  last_updated_by ,
							  creation_date ,
							  created_by ,
							  last_update_login ,
							  total_inv_amt ,
							  total_tax_amt ,
							  total_frieght_amt ,
							  total_gross_sale_amt
							)
							VALUES
							(
							  vidheader (i).cons_inv_id,
							  vidheader (i).customer_id,
							  ln_trx_number,
							  ln_orig_inv_number,
							  vidheader (i).customer_trx_id,
							  vidheader (i).cons_billing_number,
							  vidheader (i).cust_doc_id ,
							  vidheader(i).c_ext_attr14,
							  'OPSTECH',
							  TO_DATE(vidheader (i).bill_to_date,'mm/dd/yyyy') ,
							  TO_DATE(vidheader (i).due_date , 'mm/dd/yyyy'),
							  g_as_of_date,
							  vidheader (i).org_id ,
							  vidheader (i).billing_site_id ,
							  ln_ship_to_site_use_id ,
							  'FILE_GENERATED',
							  'Y',
							  ln_request_id,
							  NULL,
							  SYSDATE,
							  ln_user_id,
							  SYSDATE,
							  ln_user_id,
							  ln_user_id,
							  ln_total_inv_amt,
							  ln_total_tax_amt,
							  ln_total_frgt_amt,
							  ln_total_grsale_amt
							);
							
				  lc_err_location_msg := ' STG Table Insert Done FOR '|| ln_trx_number;
				  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );

						BEGIN
							
							UPDATE ar_cons_inv_all
							SET attribute4 = 'Y'||'|'||ln_request_id , -- Added NAIT-75751 replace - by | for SOX report 'Y-'||ln_request_id ,
							  attribute15       = 'Y' ,
							  last_updated_by   = ln_user_id ,
							  last_update_date  = SYSDATE ,
							  last_update_login = ln_user_id
							WHERE cons_inv_id   = vidheader (i).cons_inv_id;
							
							UPDATE ra_customer_trx
							SET attribute15       = 'P' ,
							  last_updated_by     = ln_user_id ,
							  last_update_date    = SYSDATE ,
							  last_update_login   = ln_user_id
							WHERE customer_trx_id = vidheader (i).customer_trx_id;
						
						EXCEPTION
							  WHEN OTHERS THEN
								ROLLBACK TO insertsuccrec;
								lc_errormsg := (' Exception for Update AR CONS table cons inv id  '|| vidheader (i).cons_inv_id || ' '|| SQLERRM );
								xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_errormsg );
								RAISE l_exp_up_cons_tbl;
						END;
								
					  lc_err_location_msg := ' CONS INV Table UPDATE Done FOR '|| ln_trx_number;
					  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
					
					 EXCEPTION
						  WHEN OTHERS THEN
							  lc_err_location_msg := ' Exception for Insert STG table for  '|| ln_trx_number;
							  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
						  ROLLBACK TO insertsuccrec;
							  lc_error_debug := SQLERRM ;
							  xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_error_debug );
						  RAISE l_exp_insert_stg;
					END ;
		 
                  END LOOP; -- viheader loop
		       END IF ;    -- Count IF Ended		 
	         END LOOP;     -- Header loop end		   
         CLOSE lcu_header;

		  fnd_file.put_line(fnd_file.log,'Total Customers count Processed by this Batch: '|| ln_cust_count);		  
		  --+=========================================
		  -- Close the file handler
		  --+=========================================
		  UTL_FILE.fclose (lc_file_handle);

	  EXCEPTION
		WHEN UTL_FILE.access_denied THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' access_denied :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.charsetmismatch THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' charsetmismatch :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.DELETE_FAILED THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' delete_failed :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.file_open THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' file_open :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.fclose(lc_file_handle);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.internal_error THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' internal_error :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_filehandle THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_filehandle :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_filename THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_filename :: ' || SQLERRM || SQLCODE );
		  FND_FILE.PUT_LINE (FND_FILE.log, LC_ERRORMSG);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.fclose(lc_file_handle);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_maxlinesize THEN
		  LC_ERRORMSG := ( ' eBill generate_file Errored :- ' || ' invalid_maxlinesize :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.fclose(lc_file_handle);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_mode THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_mode :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_offset THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_offset :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_operation THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_operation :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.invalid_path THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_path :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.read_error THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' read_error :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.rename_failed THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' rename_failed :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN UTL_FILE.write_error THEN
		  lc_errormsg := ( ' eBill generate_file Errored :- ' || ' write_error :: ' || SQLERRM || SQLCODE );
		  fnd_file.put_line (fnd_file.LOG, lc_errormsg);
		  ROLLBACK;
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.FCLOSE(LC_FILE_HANDLE);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN l_exp_up_cons_tbl THEN
		  UTL_FILE.fclose_all;
		  lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
		  UTL_FILE.fclose(lc_file_handle);
		  LC_ERRORMSG := (' Exception in Cons INV table Update :FILE Make 0 Byte : '||LC_ERROR_DEBUG || SQLERRM);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN l_exp_insert_stg THEN
		  UTL_FILE.fclose_all;
		  LC_FILE_HANDLE := UTL_FILE.FOPEN (P_FILE_PATH, P_FILE_NAME, 'W', 32767);
		  UTL_FILE.fclose(lc_file_handle);
		  lc_errormsg := (' Exception in STG Table insertion :FILE Make 0 Byte : '||lc_error_debug || SQLERRM);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		WHEN OTHERS THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in Location: '||lc_error_location );
		  FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in main procedure : '||lc_error_debug || SQLERRM);
		  lc_errormsg := (' Exception in main procedure : '||lc_error_debug || SQLERRM);
		  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
		  RAISE;
		END;
		
    --+=========================================
    -- update status on the basis of file creation
    --+=========================================
    xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
	
	IF lc_ar_cons_prcss = 'Y' THEN 
    --+=========================================
    -- Calling the common file copy program
    --+=========================================
		BEGIN
			  FOR lcu_ftp_path_rec IN lcu_translation_ftp_value
			  LOOP
				IF lcu_ftp_path_rec.source_value2    = 'SOURCE_FILE_PATH' THEN
				  lc_dba_dir_path_src               := lcu_ftp_path_rec.dir_path ;
				ELSIF lcu_ftp_path_rec.source_value2 = 'DEST_FILE_PATH' THEN
				  lc_dba_dir_path_dst               := lcu_ftp_path_rec.dir_path;
				ELSIF lcu_ftp_path_rec.source_value2 = 'ARC_FILE_PATH' THEN
				  lc_dba_dir_path_arc               := lcu_ftp_path_rec.dir_path;
				END IF;
			  END LOOP;
		EXCEPTION
			WHEN OTHERS THEN
			  lc_dba_dir_path_src:= NULL;
			  lc_dba_dir_path_dst:= NULL;
			  lc_dba_dir_path_arc:= NULL;
		END ;
	
    lc_err_location_msg := ' Calling OD common file copy.. '
							|| ' SRC :'	|| lc_dba_dir_path_src 
							|| ' DST :' || lc_dba_dir_path_dst 
							|| ' ARC :'	|| lc_dba_dir_path_arc;							
    xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
	
    IF lc_dba_dir_path_src IS NOT NULL AND 
	   lc_dba_dir_path_dst IS NOT NULL AND 
	   lc_dba_dir_path_arc IS NOT NULL THEN 
      
		/*  --To set environment context. 
		  ln_responsibility_id := fnd_global.resp_id;
		  ln_application_id    := fnd_global.resp_appl_id ;
		  fnd_global.apps_initialize (ln_user_id,ln_responsibility_id,ln_application_id);
		*/		  
				  --Submit the request to transfer file
			ln_req_id := fnd_request.submit_request   ('XXFIN',
													   'XXAROPSCOPY',  --New opstech program added
													   '',
													   TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS'),  
													   TRUE, --Added sub request true for parent child 
							                           lc_dba_dir_path_src || '/' || p_file_name,
													   lc_dba_dir_path_dst || '/' || p_file_name,
													   'N',
													   lc_dba_dir_path_arc
													  );

		   COMMIT;
				  
			lc_err_location_msg := ' Child Request Id  '|| ln_req_id ;
		    xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
		  
           IF ln_req_id > 0 THEN			
		  --Added for parent child program 
		  FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'COMPLETE');
			/*lc_wait := fnd_concurrent.wait_for_request(ln_req_id,
													   10,
													   0,
													   lc_conc_phase,
													   lc_conc_status,
													   lc_dev_phase,
													   lc_dev_status,
													   lc_conc_message
				);
		    */		
		    END IF;
			
      		IF TRIM (lc_conc_status) = 'Error' THEN			
				lc_err_location_msg   := 'File Copy of the Ebill File Failed : ' 
										 || p_file_name || ': Please check the Log file for Request ID : ' 
										 || ln_req_id;										  
				lc_errormsg           :=  lc_err_location_msg;				
				xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,TRUE ,lc_err_location_msg );
								
				fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' : ' || SQLCODE || ' : ' || SQLERRM );
				
				-- UPDATE THE STG TABLE FOR ANY ERROR RECORDS
					BEGIN
					  UPDATE XX_AR_OPSTECH_BILL_STG
					  SET status       = 'FILE_TRANSFER_FAILED',
						processed_flag = 'E',
						error_message  = 'File Transfer Program Went in Error '
					  WHERE request_id = ln_request_id;
					  xx_ops_update_status( lc_errormsg , NULL , ln_request_id , NULL,'FILE_TRANSFER' );
					EXCEPTION
					WHEN OTHERS THEN
					  fnd_file.put_line (fnd_file.LOG, ' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
					  lc_errormsg := (' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
					END;		    
			ELSE			
				    BEGIN
					  UPDATE XX_AR_OPSTECH_BILL_STG
					  SET status       = 'FILE_TRANSFER_SUCCESS' ,
						processed_flag = 'S'
					  WHERE request_id = ln_request_id;
					  xx_ops_update_status( lc_errormsg , NULL , ln_request_id , NULL,'FILE_TRANSFER' );
					EXCEPTION
					WHEN OTHERS THEN
					  fnd_file.put_line (fnd_file.LOG, ' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
					  lc_errormsg := (' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
					END;
	      END IF;			
      ELSE
      -- =======================================================================
      -- The output file path is blank. Hence we cannot
      -- ftp the file to the XXFIN_DATA/ftp/out/arinvoice/OPSTECH
      -- folder. Manual copy is possible by going to the XXFIN_OPSTECH folder.
      -- =======================================================================
				   fnd_file.put_line (fnd_file.LOG, ' No Translation Values Set up For FTP Please check Translation XX_AR_EBL_OPSTCH_PATH SET UP : ' );
				   lc_errormsg := (' No Translation Values Set up For FTP Please check Translation XX_AR_EBL_OPSTCH_PATH SET UP : ' );
				   xx_ops_update_status( lc_errormsg , NULL , ln_request_id , NULL,'FILE_TRANSFER' );
     END IF;					
   END IF;    
  END IF; 
   
  COMMIT;
--Exceptions
  EXCEPTION
  WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,' Exception in File Main Process: '||lc_errormsg || SQLERRM);
    ROLLBACK;
    RAISE;
  END xx_opstech_ebill_main;  
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : get_cust_name                                                       |
  -- | Description : This function is used to build cust name from cust acct id          |
  -- |Parameters   : p_account_id                                                        |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
  -- +===================================================================================+
  FUNCTION get_cust_name(
      p_account_id IN NUMBER)
    RETURN VARCHAR2
  IS
    lc_cust_name hz_parties.party_name%TYPE;
    lc_err_location_msg VARCHAR2(1000) := NULL;
  BEGIN
    lc_cust_name:=NULL;
    
	SELECT HP.party_name 
    INTO lc_cust_name
    FROM 
      hz_cust_accounts hca,
      hz_parties hp
    WHERE 1=1
	AND hca.party_id                  = hp.party_id
    AND hca.cust_account_id           = p_account_id;    
    
    RETURN lc_cust_name;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    lc_cust_name:=NULL;
    fnd_file.put_line(fnd_file.LOG,' No data found Exception in get_cust_name : for cust_account_id: '||p_account_id);
    RETURN lc_cust_name;
  WHEN OTHERS THEN
    lc_cust_name:=NULL;
    fnd_file.put_line(fnd_file.LOG,' Exception in function get_cust_name : '||SQLERRM);
    RETURN lc_cust_name;
  END get_cust_name;
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : get_inv_amounts                                                     |
  -- | Description : This function is used to get INV amoutns from trx id and type       |
  -- |Parameters   : p_in_amt_type, p_in_cust_trx_id                                  |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
  -- +===================================================================================+
 FUNCTION get_inv_amounts(
    p_in_cust_trx_id IN NUMBER ,
    p_in_amt_type    IN VARCHAR2 )
  RETURN NUMBER
IS
  ln_amount             NUMBER;
  ln_total_inv_amtfn    NUMBER;
  ln_total_frgt_amtfn   NUMBER;
  ln_total_grsale_amtfn NUMBER;
  ln_total_tax_amtfn    NUMBER;
  lc_err_location_msg   VARCHAR2(1000) := NULL;
 BEGIN
  ln_amount:=0;
  --+==========================================================
  -- For getting the Total Invoice Amount
  --+==========================================================
  IF p_in_amt_type = 'INV_AMT' THEN
    BEGIN
      SELECT NVL (SUM (aitsv.extended_amount), 0)
      INTO ln_total_inv_amtfn
      FROM ra_customer_trx_lines aitsv
      WHERE 1                   = 1
      AND aitsv.customer_trx_id = p_in_cust_trx_id ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_total_inv_amtfn := 0;
    WHEN OTHERS THEN
      ln_total_inv_amtfn := 0;
    END;
    ln_amount := ln_total_inv_amtfn ;
    --+==========================================================
    -- For getting the Total Tax Amount
    --+==========================================================
  ELSIF p_in_amt_type = 'TAX_AMT' THEN
    BEGIN
      SELECT NVL(SUM (aitsv.extended_amount), 0)
      INTO ln_total_tax_amtfn
      FROM ra_customer_trx_lines aitsv,
        zx_rates_b vat -- ar_vat_tax_vl vat
      WHERE 1                   = 1
      AND aitsv.customer_trx_id = p_in_cust_trx_id
      AND aitsv.line_type       = 'TAX'
      AND vat.tax_rate_id(+)    = aitsv.vat_tax_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_total_tax_amtfn := 0;
    WHEN OTHERS THEN
      ln_total_tax_amtfn := 0;
    END;
    ln_amount := ln_total_tax_amtfn ;
    --+==========================================================
    -- For getting the Total FRGHT Amount
    --+==========================================================
  ELSIF p_in_amt_type = 'FRT_AMT' THEN
    BEGIN
      SELECT NVL(SUM(a.extended_amount),0)
      INTO ln_total_frgt_amtfn
      FROM ra_customer_trx_lines a
      WHERE 1             = 1
      AND customer_trx_id = p_in_cust_trx_id
      AND EXISTS
        (SELECT 1
        FROM fnd_lookup_values
        WHERE lookup_type = 'OD_FEES_ITEMS'
        AND attribute7    = 'DELIVERY'
        AND attribute6    = a.inventory_item_id
        AND LANGUAGE      = USERENV ('LANG')
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_total_frgt_amtfn := 0;
    WHEN OTHERS THEN
      ln_total_frgt_amtfn := 0;
    END;
    ln_amount := ln_total_frgt_amtfn ;
  END IF;
  RETURN ln_amount;
 EXCEPTION
 WHEN OTHERS THEN
  ln_amount:=0;
  fnd_file.put_line(fnd_file.LOG,' Exception in function get_inv_amounts : '||SQLERRM);
  RETURN ln_amount;
 END get_inv_amounts;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_orig_inv_num                                                    |
-- | Description : This function is used to get Orig inv for Credit Memo               |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+
	FUNCTION get_orig_inv_num(
		p_in_ord_hdr_id IN NUMBER )
	  RETURN NUMBER
	IS
	  ln_orig_inv_num NUMBER;
	BEGIN
	  SELECT ooh.order_number
	  INTO ln_orig_inv_num
	  FROM xx_om_line_attributes_all XOLA,
		oe_order_lines_all OOL,
		oe_order_headers_all OOH
	  WHERE 1                       =1
	  AND XOLA.line_id              = OOL.line_id
	  AND OOL.header_id             = p_in_ord_hdr_id
	  AND OOH.orig_sys_document_ref = XOLA.ret_orig_order_num
	  AND ROWNUM                    = 1;
	  /*
	  SELECT ooh.order_number
	  INTO ln_orig_inv_num
	  FROM xx_om_line_attributes_v XOLA,
	  xx_oe_order_lines_v OOL,
	  xx_oe_order_headers_v OOH
	  WHERE XOLA.line_id            = OOL.line_id
	  AND OOL.header_id             = p_in_ord_hdr_id
	  AND OOH.orig_sys_document_ref = XOLA.ret_orig_order_num
	  AND ROWNUM                    = 1;
	  */
	  RETURN ln_orig_inv_num;
	EXCEPTION
	WHEN OTHERS THEN
	  ln_orig_inv_num:= NULL;
	  fnd_file.put_line(fnd_file.LOG,' Exception in get_orig_inv_num function : '||SQLERRM);
	  RETURN ln_orig_inv_num;
	END get_orig_inv_num;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ops_update_status                                                |
-- | Description : Update the error in the FILE table 						           |
-- |Parameters   : 					                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+
	PROCEDURE xx_ops_update_status(
		p_errormsg      IN VARCHAR2 ,
		p_ar_cons_prcss IN VARCHAR2 ,
		p_request_id    IN NUMBER,
		p_cust_acct_id  IN NUMBER,
		p_err_level     IN VARCHAR2)
	IS 
	PRAGMA  AUTONOMOUS_TRANSACTION;
	BEGIN
	  IF p_err_level   = 'FILE_CREATE' THEN
		IF(p_errormsg IS NOT NULL AND p_cust_acct_id IS NULL) THEN
		  
		  UPDATE XX_AR_OPSTECH_FILE
		  SET error_message     = p_errormsg,
			  status            = 'FILE_CREATION_FAILED',
			  processed_flag    = 'E'
		  WHERE request_id      = p_request_id;
		ELSIF p_ar_cons_prcss = 'Y' THEN
		  UPDATE XX_AR_OPSTECH_FILE
		  SET status         = 'FILE_CREATION_SUCCESS',
			  processed_flag = 'Y'
		  WHERE request_id = p_request_id;
		END IF;
	  ELSIF p_err_level = 'FILE_TRANSFER' THEN
		IF p_errormsg  IS NOT NULL THEN
		  UPDATE XX_AR_OPSTECH_FILE
		  SET error_message   = p_errormsg,
			  status          = 'FILE_TRANSFER_FAILED',
			  processed_flag  = 'E'
		  WHERE request_id  = p_request_id;
		ELSE
		  UPDATE XX_AR_OPSTECH_FILE
		  SET status         = 'FILE_TRANSFER_SUCCESS',
			  processed_flag = 'S'
		  WHERE request_id = p_request_id;
		END IF;
	  END IF;
	  COMMIT;
  EXCEPTION WHEN OTHERS THEN
	ROLLBACK;
	 fnd_file.put_line(fnd_file.LOG,' Exception in xx_ops_update_status proc : '||SQLERRM);
  END XX_OPS_UPDATE_STATUS;
 END XX_AR_OPSTECH_EBILL_PKG;
/
SHOW ERRORS;
EXIT;