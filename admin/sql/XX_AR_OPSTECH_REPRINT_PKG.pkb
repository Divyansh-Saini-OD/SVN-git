CREATE OR REPLACE
PACKAGE BODY XX_AR_OPSTECH_REPRINT_PKG
AS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Provide Consulting                                       |
  ---+============================================================================================+
  ---|    Application  :        AR                                                                |
  ---|                                                                                            |
  ---|    Name         :        XX_AR_OPSTECH_REPRINT_PKG.pkb                                     |
  ---|                                                                                            |
  ---|    Description  :        Generate text file from Oracle AR to OD's Ebill Central System    |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             20-AUG-2018       Prashant J           Initial Version                  |
  ---|    1.1             22-OCT-2018       Aniket J             Updated for Child                |
  ---|    1.2             23-OCT-2018       Aniket J             Updated for SKU Code             |
  ---+============================================================================================+
  g_pkb_version      NUMBER (2, 1) := '1.1';
  
  --==================================================
  --Main procedure that extracts the data from Source To a file
  --===================================================
PROCEDURE XX_OPSTECH_REPRINT_MAIN(x_error_buff    OUT NOCOPY VARCHAR2,
								  x_ret_code      OUT NOCOPY VARCHAR2,
								  p_file_path     IN VARCHAR2,
								  p_aops_number   IN VARCHAR2,
								  p_trx_date_from IN VARCHAR2,
								  p_trx_date_to   IN VARCHAR2,
								  p_debug_flag    IN VARCHAR2)
IS
  -- Variables
  -- UTL FILE Details
  lc_file_handle UTL_FILE.file_type;
  p_file_name         VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path     VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_src VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_dst VARCHAR2 (100) := TO_CHAR (NULL);
  lc_dba_dir_path_arc VARCHAR2 (100) := TO_CHAR (NULL);
  ln_req_id           NUMBER;
  lc_wait             BOOLEAN;
  lc_conc_phase       VARCHAR2 (50);
  lc_conc_status      VARCHAR2 (50);
  lc_dev_phase        VARCHAR2 (50);
  lc_dev_status       VARCHAR2 (50);
  lc_conc_message     VARCHAR2 (50);
  lc_err_msg          VARCHAR2 (1000);
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
  ln_inventory_item_id    NUMBER;
  lc_description          NUMBER;
  lc_uom_code             NUMBER;
  ln_quantity_invoiced    NUMBER;
  ln_unit_selling_price   NUMBER;
  ln_extended_amount      NUMBER;
  ln_tax_amount           NUMBER;
  ln_org_id               NUMBER;
  --Order Info values
  lc_order_level_comment        xx_om_header_attributes_all.comments%TYPE               := NULL;
  lc_purchase_order_number      ra_customer_trx_all.purchase_order%TYPE                 := NULL;
  ln_order_header_id            ra_customer_trx_all.attribute14%TYPE                    := NULL;
  ln_orig_inv_number            oe_order_headers.order_number%TYPE                      := NULL;
  lc_transaction_class          ra_cust_trx_types_all.type%TYPE                         := NULL;
  ln_ship_to_site_use_id        ra_customer_trx_all.ship_to_site_use_id%TYPE            := NULL;
  lc_cost_center_desc_hdr       xx_om_header_attributes_all.cust_dept_description%TYPE  := NULL;
  lc_cost_center_dept           xx_om_header_attributes_all.cost_center_dept%TYPE       := NULL;
  ld_ordered_date               oe_order_headers.ordered_date%TYPE                      := NULL;
  lc_bill_to_contact_name       xx_om_header_attributes_all.cust_contact_name%TYPE      := NULL;
  lc_customer_name              hz_parties.party_name%TYPE          					:= NULL;
  lc_bill_to_name               xx_om_header_attributes_All.bill_to_name%TYPE           := NULL;
  lc_term_description           ra_terms.description%TYPE								:= NULL;
  --error handling
  lc_error_location   VARCHAR2(1000) := NULL;
  lc_error_debug      VARCHAR2(1000) := NULL;
  lc_err_location_msg VARCHAR2(1000);
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
  ln_limit_size      NUMBER       := 500; --Since we have max 1800 ops customer
  ln_cust_count      NUMBER       := 0;
  lc_ar_cons_prcss   VARCHAR2(2)  := 'N';
  ld_trx_date_from   DATE;
  ld_trx_date_to     DATE;
  ln_item_master_org NUMBER := NULL;
  
  --+============================================================
  -- Cursor for getting the Invoice Header Information
  --+============================================================
 CURSOR lcu_header(p_aops_number IN VARCHAR2 ,p_trx_date_from IN DATE ,p_trx_date_to IN DATE)
 IS
 SELECT rct.customer_trx_id,
        XX_AR_OPSTECH_REPRINT_PKG.get_bill_date(rct.customer_trx_id) billing_date,
		rct.trx_number,
        (SELECT SUBSTR(rt.description, 1, 15) 
		   FROM  ra_terms_tl rt 
		  WHERE 1=1 
		    AND rt.LANGUAGE = USERENV('lang')
		    AND rt.term_id  = rct.term_id
		) name,
        XX_AR_OPSTECH_REPRINT_PKG.get_bill_due_date(rct.customer_trx_id) due_date,
		hca.cust_account_id cust_acct_id
   FROM ra_customer_trx rct ,
        hz_cust_accounts hca 
  WHERE 1 = 1
    AND rct.bill_to_customer_id = hca.cust_account_id
    AND rct.attribute15         = 'P'
	AND SUBSTR(hca.orig_system_reference,1,8) = p_aops_number
    AND rct.trx_date BETWEEN NVL(p_trx_date_from,rct.trx_date) AND NVL(p_trx_date_to,rct.trx_date)   
    AND EXISTS (SELECT 1
				  FROM xx_ar_opstech_file xaof
			 	 WHERE xaof.cust_account_id      = hca.cust_account_id
				   AND xaof.aops_customer_number = p_aops_number
				   AND xaof.aops_customer_number = SUBSTR(hca.orig_system_reference,1,8)
				   AND xaof.processed_flag       = 'S')
  ORDER BY rct.billing_date DESC;
  --+=================================================================
  -- Cursor to fetch invoice related information.
  --+=================================================================
  CURSOR lcu_inv_lines( p_customer_trx_id IN NUMBER , ln_item_master_org IN NUMBER )
  IS
  SELECT rctl.customer_trx_id,
         rctl.customer_trx_line_id,
         rctl.line_number,
         rctl.description product_description,
         rctl.translated_description product_code,
         rctl.uom_code unit_of_measure,
         nvl(rctl.quantity_invoiced,rctl.quantity_credited) shipped_quantity,
         rctl.unit_selling_price unit_selling_price,
         rctl.extended_amount extended_amount,
         rctl.org_id org_id
	FROM ra_customer_trx_lines_all rctl
   WHERE rctl.line_type        = 'LINE'
	 AND rctl.customer_trx_id  = p_customer_trx_id
	 AND rctl.org_id           = FND_GLOBAL.org_id
	 AND rctl.translated_description IS NOT NULL 
	 ORDER BY rctl.customer_trx_id,
			  rctl.customer_trx_line_id,
			  rctl.line_number;


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
	   
 
 BEGIN
  -- To catch exception out side block added
  --+=================================================================
	-- Initialize FND request 
	--+=================================================================
    ln_request_id   := fnd_global.conc_request_id;
    lc_request_data := fnd_conc_global.request_data;
 
 IF (lc_request_data IS NULL) THEN 
  BEGIN
    --+=================================================================
    -- Get profile operating unit
    --+=================================================================
    ln_operating_unit := fnd_profile.VALUE ('ORG_ID');
    --+=================================================================
    -- Assign billing date to as of date parameter
    --+=================================================================
    --  g_as_of_date := TRUNC (fnd_conc_date.string_to_date (p_as_of_date));
    ld_trx_date_from := FND_DATE.CANONICAL_TO_DATE(p_trx_date_from);
    ld_trx_date_to   := FND_DATE.CANONICAL_TO_DATE(p_trx_date_to);
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
       WHERE 1 = 1
         AND odef.organization_name = 'OD_ITEM_MASTER';
      fnd_file.put_line (fnd_file.LOG, 'Item Master Organization ID :' || ln_item_master_org );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ln_item_master_org := TO_NUMBER (NULL);
      fnd_file.put_line (fnd_file.LOG, 'In No data found, Item Master Organization ID :' || ln_item_master_org );
    WHEN OTHERS THEN
      ln_item_master_org := TO_NUMBER (NULL);
      FND_FILE.PUT_LINE (FND_FILE.log, 'In Other errors, Item Master Organization ID :' || ln_item_master_org );
    END;
    --+=================================================================
    -- Assign File Name details and OPen the file
    --+=================================================================
    p_file_name    := 'XX_OPSTECH_REPRINT_'||ln_request_id||'_'|| TO_CHAR (SYSDATE, 'DDMONYYYYHH24MISS')||'.txt';
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'w', 32767);
    --+=================================================================
    -- start processing
    --+=================================================================
    lc_err_location_msg := ' Parameters ==>' || CHR(13) || 
						   ' Debug flag : ' || p_debug_flag || CHR(13) || 
						   ' File Path  : ' || p_file_path || CHR(13) ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    --Initialization of parameters
    --Default Logs
    lc_err_location_msg := ' Profile Values ==>' || CHR(13) || 
						   ' WRITEN_OFF_AMT_LOW_VALUE: '||xx_ar_gen_ebill_pkg.ln_write_off_amt_low || 
						   ' WRITEN_OFF_AMT_HIGH_VALUE: '||xx_ar_gen_ebill_pkg.ln_write_off_amt_high;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    --==============================================================
    -- Open cursor for header on the basis of AOPS number and bill date range 
    --==============================================================
    OPEN lcu_header(p_aops_number,ld_trx_date_from,ld_trx_date_to);
    -- Header loop Start
    LOOP
      FETCH lcu_header BULK COLLECT INTO vidheader LIMIT ln_limit_size;
      EXIT
    WHEN vidheader.COUNT = 0;
      --
      --================================
      --Load Invoice related information by PL SQL table
      --================================
      IF vidheader.COUNT > 0 THEN
        lc_ar_cons_prcss := 'Y';
        FOR i IN 1 .. vidheader.COUNT
        LOOP
		         
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
            WHERE 1 = 1
              AND rctt.cust_trx_type_id   = rca.cust_trx_type_id
              AND rca.customer_trx_id     = vidheader(i).customer_trx_id;
          EXCEPTION
          WHEN OTHERS THEN
            ln_trx_number            := NULL;
            lc_purchase_order_number := NULL;
            ln_order_header_id       := NULL;
            ln_ship_to_site_use_id   := NULL;
            lc_transaction_class     := NULL;
          END;
         
          lc_err_location_msg := 'Sales Order Header ID :' || ln_order_header_id;
          xx_ar_ebl_common_util_pkg.put_log_line(lb_debug_flag ,FALSE ,lc_err_location_msg );
		  
          vidheader(i).trx_number := ln_trx_number;
          ln_total_inv_amt  := XX_AR_OPSTECH_REPRINT_PKG.get_inv_amounts( vidheader(i).customer_trx_id , 'INV_AMT');
          ln_total_tax_amt  := XX_AR_OPSTECH_REPRINT_PKG.get_inv_amounts( vidheader(i).customer_trx_id , 'TAX_AMT');
          ln_total_frgt_amt := XX_AR_OPSTECH_REPRINT_PKG.get_inv_amounts( vidheader(i).customer_trx_id , 'FRT_AMT');
          --+==========================================================
          -- For getting the Total Gross Sale  Amount
          --+==========================================================
          ln_total_grsale_amt := ln_total_inv_amt - ( ln_total_frgt_amt + ln_total_tax_amt );
          --+==========================================================
          -- For Get Ship to Name from order headers info
          --+==========================================================
          lc_customer_name := XX_AR_OPSTECH_REPRINT_PKG.get_cust_name(vidheader(i).cust_acct_id);
          --+==========================================================
          -- Get Orig INV number in case of Credit Memo
          --+==========================================================
          IF lc_transaction_class = 'CM' THEN
            ln_orig_inv_number   := XX_AR_OPSTECH_REPRINT_PKG.get_orig_inv_num (ln_order_header_id);
			lc_term_description  := XX_AR_OPSTECH_REPRINT_PKG.get_cm_pay_term (vidheader(i).cust_acct_id);
          ELSE
            ln_orig_inv_number  := NULL;
			lc_term_description := NULL;
          END IF;
          --+==========================================================
          -- For getting the Order Information
          --+==========================================================
          BEGIN
           SELECT XOHA.comments order_level_comment,
                  XOHA.cust_dept_description,
                  XOHA.cost_center_dept,
                  OEHA.ordered_date ordered_Date,
                  XOHA.cust_contact_name
             INTO lc_order_level_comment,
                  lc_cost_center_desc_hdr,
                  lc_cost_center_dept ,
                  ld_ordered_date,
                  lc_bill_to_contact_name
             FROM xx_om_header_attributes_all XOHA,
                  oe_order_headers_all OEHA
            WHERE 1 = 1
              AND XOHA.header_id = OEHA.header_id
              AND OEHA.header_id = ln_order_header_id;
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
          UTL_FILE.put_line(lc_file_handle,'H' || CHR(9) 
		  || RPAD(ln_trx_number,20) || CHR(9) 
		  || RPAD(NVL(TO_CHAR(ln_orig_inv_number),' '),20) || CHR(9) 
		  || NVL( vidheader(i).billing_date, RPAD(' ',8,' ') ) || CHR(9) 
		  || RPAD(' ',30) || CHR(9) 
		  || CHR(9) || NVL( vidheader(i).due_date, RPAD (' ', 8, ' ') ) || CHR(9) 
		  || RPAD( NVL(vidheader(i).name,lc_term_description) ,15 ) || CHR(9) 
		  || RPAD(lc_cost_center_dept ,30) || CHR(9) 
          || RPAD(lc_customer_name,30) || CHR(9)
          || NULL || CHR(9) 
		  || RPAD(lc_bill_to_contact_name,30) || CHR(9) 
          || RPAD(lc_purchase_order_number,30) || CHR(9) 
          || NULL || CHR(9) 
		  || NVL(TO_CHAR(ld_ordered_date,'MM/DD/YYYY'),RPAD (' ', 8, ' ')) || CHR(9) 
		  || NULL || CHR(9) 
		  || NULL || CHR(9) 
		  || LPAD(TRIM(TO_CHAR(NVL(ln_total_grsale_amt,0),'999999990.99')),13) || CHR(9) 
		  || LPAD(TRIM(TO_CHAR(NVL(ln_total_frgt_amt,0),'999999990.99')),13) || CHR(9) 
		  || LPAD(TRIM(TO_CHAR(NVL(ln_total_tax_amt,0), '999999990.99')),13) || CHR(9) 
		  || LPAD(TRIM(TO_CHAR(NVL(ln_total_inv_amt,0),'999999990.99')),13) || CHR(13));
          --+==========================================================
          -- For getting the Line Information START
          --+==========================================================
          lc_err_location_msg := 'Opening the lcu_line cursor for trx_id : '|| vidheader(i).customer_trx_id;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
		  
          OPEN lcu_inv_lines (vidheader(i).customer_trx_id, ln_item_master_org);
          LOOP
            FETCH lcu_inv_lines BULK COLLECT INTO vidline LIMIT ln_limit_size;
            EXIT
          WHEN vidline.COUNT = 0;
            IF vidline.COUNT > 0 THEN
              lc_err_location_msg := ' In Line Printing if line count > 0  ';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
              FOR j IN 1 .. vidline.COUNT
              LOOP
                                 
				  UTL_FILE.put_line(lc_file_handle,'D' || CHR(9) 
				  || vidline(j).line_number || CHR(9) 
				  || RPAD(ln_trx_number ,20) || CHR(9) 
				  || RPAD(vidline(j).product_code , 9 ) || CHR(9) 
				  || RPAD(vidline(j).product_description ,30) || CHR(9) 
				  || NVL(vidline(j).shipped_quantity , 0) || CHR(9) 
				  || RPAD (vidline(j).unit_of_measure ,2 ) || CHR(9)
				  || LPAD(TRIM(TO_CHAR(vidline(j).unit_selling_price,'999999990.99')),13) || CHR(9) 
				  || NULL || CHR(9) 
				  || NULL || CHR(9) 
				  || NULL || CHR(13));
				              
			  END LOOP; ---vidline
            END IF;      --Count iF
          END LOOP;      -- LINE lopp
          CLOSE lcu_inv_lines;
          
		IF vidheader(i).billing_date IS NOT NULL THEN 
  		 BEGIN		  
            UPDATE XX_AR_OPSTECH_FILE
               SET reprocess_flag         = 'Y',
                   reprocess_request_id   = ln_request_id,
                   last_update_date       = SYSDATE
             WHERE aops_customer_number = p_aops_number
			   AND TO_CHAR(billing_date,'MM/DD/YYYY') = vidheader(i).billing_date;
          EXCEPTION
          WHEN OTHERS THEN
            lc_errormsg := (' Exception for Update Reprocess Flag  for AOPS Customer '|| p_aops_number || ' '|| SQLERRM );
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_errormsg );
          END;
		 END IF;		  
          lc_err_location_msg := ' OPSTECH File Table UPDATE Done FOR '|| ln_trx_number;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
        END LOOP; -- viheader loop
      END IF ;    -- Count IF Ended
    END LOOP;     -- Header loop end
    CLOSE lcu_header;
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
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.charsetmismatch THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' charsetmismatch :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.delete_failed THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' delete_failed :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.file_open THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' file_open :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.internal_error THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' internal_error :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_filehandle THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_filehandle :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_filename THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_filename :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_maxlinesize THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_maxlinesize :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_mode THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_mode :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_offset THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_offset :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_operation THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_operation :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.invalid_path THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' invalid_path :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.read_error THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' read_error :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.rename_failed THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' rename_failed :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN UTL_FILE.write_error THEN
    lc_errormsg := ( ' eBill generate_file Errored :- ' || ' write_error :: ' || SQLERRM || SQLCODE );
    fnd_file.put_line (fnd_file.LOG, lc_errormsg);
    ROLLBACK;
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    RAISE;
  WHEN l_exp_up_cons_tbl THEN
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    lc_errormsg := (' Exception in Cons INV table Update :FILE Make 0 Byte : '||lc_error_debug || SQLERRM);
    RAISE;
  WHEN l_exp_insert_stg THEN
    UTL_FILE.fclose_all;
    lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767);
    UTL_FILE.fclose(lc_file_handle);
    lc_errormsg := (' Exception in STG Table insertion :FILE Make 0 Byte : '||lc_error_debug || SQLERRM);
    RAISE;
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in Location: '||lc_error_location );
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in main procedure : '||lc_error_debug || SQLERRM);
    lc_errormsg := (' Exception in main procedure : '||lc_error_debug || SQLERRM);
    RAISE;
  END;
  --+=========================================
  -- update status on the basis of file creation
  --+=========================================
  xx_ops_update_status( lc_errormsg , lc_ar_cons_prcss , ln_request_id , NULL,'FILE_CREATE' );
  --+=========================================
  -- Calling the common file copy program
  --+=========================================
	 BEGIN
	  FOR lcu_ftp_path_rec IN lcu_translation_ftp_value
	  LOOP
		IF lcu_ftp_path_rec.source_value2 = 'SOURCE_FILE_PATH' THEN
		   lc_dba_dir_path_src := lcu_ftp_path_rec.dir_path ;
		ELSIF lcu_ftp_path_rec.source_value2   = 'DEST_FILE_PATH' THEN
		   lc_dba_dir_path_dst := lcu_ftp_path_rec.dir_path;
		ELSIF lcu_ftp_path_rec.source_value2 = 'ARC_FILE_PATH' THEN
		   lc_dba_dir_path_arc := lcu_ftp_path_rec.dir_path;
		END IF;
	  END LOOP;
	 EXCEPTION WHEN OTHERS THEN 
	 lc_dba_dir_path_src:= NULL;
	 lc_dba_dir_path_dst:= NULL;
	 lc_dba_dir_path_arc:= NULL;
	 END;
  
  IF lc_ar_cons_prcss = 'Y' THEN
   
    lc_errormsg         := NULL;
    lc_err_location_msg := ' Calling OD common file copy..  '
						|| ' SRC : '|| lc_dba_dir_path_src 
						|| ' DST : '|| lc_dba_dir_path_dst 
						|| ' ARC : '|| lc_dba_dir_path_arc;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  
  IF lc_dba_dir_path_src IS NOT NULL AND 
     lc_dba_dir_path_dst IS NOT NULL AND 
	 lc_dba_dir_path_arc IS NOT NULL THEN 
      --To set environment context.
      /*ln_responsibility_id := fnd_global.resp_id;
      ln_application_id    := fnd_global.resp_appl_id ;
      fnd_global.apps_initialize (ln_user_id,ln_responsibility_id,ln_application_id);
	  */
      --Submit the request to transfer file
      ln_req_id := fnd_request.submit_request
                      ('XXFIN',
                       'XXAROPSCOPY',  
                       '',
                       TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS'),  
                       TRUE,
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
	   
		/*lc_wait   := fnd_concurrent.wait_for_request(ln_req_id,
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
        lc_err_location_msg   := 'File Copy of the Ebill File Failed : ' || p_file_name || 
								 ': Please check the Log file for Request ID : ' || ln_req_id;								 
        lc_errormsg           := lc_err_location_msg;        
		XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
        
        fnd_file.put_line (fnd_file.LOG, lc_err_msg || ' : ' || SQLCODE || ' : ' || SQLERRM );
        -- update the STG table for any error records
        BEGIN
          UPDATE XX_AR_OPSTECH_FILE
          SET reprocess_flag          = 'E',
		      reprocess_error_message = lc_errormsg,
              last_update_date        = SYSDATE
          WHERE aops_customer_number = p_aops_number
          AND reprocess_request_id   = ln_request_id;
         
		 xx_ops_update_status( lc_errormsg , NULL , ln_request_id , NULL,'FILE_TRANSFER' );
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.LOG, ' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
          lc_errormsg := (' Exception in STG table Update  : ' || SQLCODE || ' : ' || SQLERRM );
        END;
      ELSE
        BEGIN
          UPDATE XX_AR_OPSTECH_FILE
          SET reprocess_flag         = 'S',
              last_update_date         = SYSDATE
          WHERE aops_customer_number = p_aops_number
          AND reprocess_request_id   = ln_request_id;
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
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in File Main Process: '||lc_errormsg || SQLERRM);
  ROLLBACK;
  RAISE;
END XX_OPSTECH_REPRINT_MAIN;

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
  -- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version               |
  -- +===================================================================================+
  FUNCTION get_cust_name(
      p_account_id IN NUMBER)
    RETURN VARCHAR2
  IS
    lc_cust_name hz_parties.party_name%TYPE;
    lc_err_location_msg VARCHAR2(1000) := NULL;
  BEGIN
    lc_cust_name:=NULL;
    
	SELECT HP.party_name CUSTOMER_NAME
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
    fnd_file.put_line(fnd_file.LOG,' No data found while deriving Cust Name : for cust_account_id id: '||p_account_id);
    RETURN lc_cust_name;
  WHEN OTHERS THEN
    lc_cust_name:=NULL;
    fnd_file.put_line(fnd_file.LOG,' Exception in deriving Cust Name  : '||SQLERRM);
    RETURN lc_cust_name;
  END get_cust_name;
  
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_inv_amounts                                                     |
-- | Description : This function is used to get INV amounts from trx id and type       |
-- |Parameters   : p_in_amt_type, p_in_cust_trx_id                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	FUNCTION get_inv_amounts(p_in_cust_trx_id IN NUMBER,
		                     p_in_amt_type    IN VARCHAR2)
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
	  fnd_file.put_line(fnd_file.LOG,' Exception in deriving the amounts : '||SQLERRM);
	  RETURN ln_amount;
	END get_inv_amounts;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_orig_inv_num                                                    |
-- | Description : This function is used to get Orig inv for Creditt Memo              |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	FUNCTION get_orig_inv_num(p_in_ord_hdr_id IN NUMBER)
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

	  RETURN ln_orig_inv_num;
	EXCEPTION
	WHEN OTHERS THEN
	  ln_orig_inv_num:= NULL;
	  fnd_file.put_line(fnd_file.LOG,' Exception in getting reference INV details : '||SQLERRM);
	  RETURN ln_orig_inv_num;
	END get_orig_inv_num;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_cm_pay_term                                                     |
-- | Description : This function is used to get Orig inv for Credit Memo               |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	FUNCTION get_cm_pay_term(p_in_cust_acct_id IN NUMBER)
	  RETURN VARCHAR2
	IS
	  ln_pay_term_desc VARCHAR2(60):= NULL;
	BEGIN
				SELECT rt.description
				  INTO ln_pay_term_desc
				  FROM hz_cust_accounts_all hca ,
				       hz_customer_profiles hcp,
				       ra_terms rt
				 WHERE hcp.cust_account_id   = hca.cust_account_id
				   AND hcp.cons_inv_flag     = 'Y'
				   AND rt.term_id            = hcp.standard_terms
				   AND hcp.site_use_id IS NULL
				   AND hca.cust_account_id   = p_in_cust_acct_id ;
				

	  RETURN ln_pay_term_desc;
	EXCEPTION
	WHEN OTHERS THEN
	  ln_pay_term_desc:= NULL;
	  fnd_file.put_line(fnd_file.LOG,' Exception in getting Payment Term for CM : '||SQLERRM);
	  RETURN ln_pay_term_desc;
	END get_cm_pay_term;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_bill_date                                                       |
-- | Description : This function is used to get Bill to date from STG and HIST tab     |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	FUNCTION get_bill_date(p_in_cust_trx_id IN NUMBER)
	  RETURN VARCHAR2
	IS
	  lc_bill_date VARCHAR2(60):= NULL;
	BEGIN
				SELECT TO_CHAR(bill_from_date,'MM/DD/YYYY')
				INTO  lc_bill_date
				FROM  xx_ar_opstech_bill_stg 
				WHERE customer_trx_id =p_in_cust_trx_id ;						

	  RETURN lc_bill_date;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	
				SELECT TO_CHAR(bill_from_date,'MM/DD/YYYY') 
				INTO lc_bill_date
				FROM xx_ar_opstech_bill_hist 
				WHERE customer_trx_id  = p_in_cust_trx_id ;
	
	RETURN lc_bill_date;
	WHEN OTHERS THEN
	  lc_bill_date:= NULL;
	  fnd_file.put_line(fnd_file.LOG,' Exception in getting bill from date for CM : '||SQLERRM);
	  RETURN lc_bill_date;
	END get_bill_date;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_bill_due_date                                                   |
-- | Description : This function is used to get Bill Due date from STG and HIST tab    |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	FUNCTION get_bill_due_date(p_in_cust_trx_id IN NUMBER)
	  RETURN VARCHAR2
	IS
	  lc_bill_due_date VARCHAR2(60):= NULL;  
	BEGIN
				SELECT TO_CHAR(bill_due_date,'MM/DD/YYYY') 
				INTO  lc_bill_due_date
				FROM  xx_ar_opstech_bill_stg 
				WHERE customer_trx_id =p_in_cust_trx_id ;						

	  RETURN lc_bill_due_date;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	
				SELECT TO_CHAR(bill_due_date,'MM/DD/YYYY')  
				INTO lc_bill_due_date
				FROM xx_ar_opstech_bill_hist 
				WHERE customer_trx_id  = p_in_cust_trx_id ;
	
	RETURN lc_bill_due_date;
	WHEN OTHERS THEN
	  lc_bill_due_date:= NULL;
	  fnd_file.put_line(fnd_file.LOG,' Exception in getting bill due date for CM : '||SQLERRM);
	  RETURN lc_bill_due_date;
	END get_bill_due_date;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ops_update_status                                                |
-- | Description : Update the STG table for status 							           |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	PROCEDURE xx_ops_update_status(p_errormsg      IN VARCHAR2,
								   p_ar_cons_prcss IN VARCHAR2,
								   p_request_id    IN NUMBER,
								   p_cust_acct_id  IN NUMBER,
								   p_err_level     IN VARCHAR2)
	IS
	BEGIN
	  IF p_err_level   = 'FILE_CREATE' THEN
		IF(p_errormsg IS NOT NULL AND p_cust_acct_id IS NULL) THEN
		  UPDATE XX_AR_OPSTECH_FILE
		  SET reprocess_error_message   = p_errormsg,
			  reprocess_status          = 'FILE_CREATION_FAILED',
			  reprocess_flag            = 'E'
		  WHERE reprocess_request_id    = p_request_id;
		ELSIF p_ar_cons_prcss = 'Y' THEN
		  UPDATE XX_AR_OPSTECH_FILE
		  SET reprocess_status       = 'FILE_CREATION_SUCCESS',
			  reprocess_flag         = 'S'
		  WHERE reprocess_request_id = p_request_id;
		END IF;
	  ELSIF p_err_level = 'FILE_TRANSFER' THEN
		IF p_errormsg  IS NOT NULL THEN
		  UPDATE XX_AR_OPSTECH_FILE
		  SET reprocess_error_message   = p_errormsg,
			  reprocess_status          = 'FILE_TRANSFER_FAILED',
			  reprocess_flag            = 'E'
		  WHERE reprocess_request_id  = p_request_id;
		ELSE
		  UPDATE XX_AR_OPSTECH_FILE
		  SET reprocess_status       = 'FILE_TRANSFER_SUCCESS',
			  reprocess_flag         = 'S'
		  WHERE reprocess_request_id = p_request_id;
		END IF;
	  END IF;
	END;
 END XX_AR_OPSTECH_REPRINT_PKG;
/
SHOW ERRORS;
EXIT;