create or replace PACKAGE BODY   XX_AP_CUSTOMER_REBATE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_AP_CUSTOMER_REBATE_PKG.pkb		                   |
-- | RICE ID     :  E3515                                              |
-- | Description :  Plsql package for AP Customer Rebate invoices      |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date        Author             Remarks                  |
-- | ========  =========== ================== =========================|
-- | 1.0       25-Aug-2016 Radhika Patnala    Initial version          |
-- | 1.1       23-Sep-2016 Paddy Sanjeevi     Defect 39429             |
-- | 1.2       15-Nov-2016 Praveen Vanga      GSCC Schema Reference Fix|
-- +===================================================================+
 AS
 --|====================================================================|
 -- | Procedure used to log based on gb_debug value or if p_force is TRUE.|
 -- | Will log to dbms_output if request id is not set,			  |
 -- | else will log to concurrent program log file.  Will prepend	  |
 -- | timestamp to each message logged.  This is useful for determining	  |
 -- | elapse times.							  |
 -- | PROCEDURE   :  print_debug_msg                            	  |
 -- |                                                                   |
 -- | DESCRIPTION : Checks if special chars exist in a string           |
 -- |                                                                   |
 -- |                                                                   |
 -- | RETURNS    : Varchar (if junck character exists or not)           |
 -- |===================================================================|
PROCEDURE print_debug_msg (P_Message  In  Varchar2,
		           p_force    IN  BOOLEAN DEFAULT FALSE)
IS
	lc_message  VARCHAR2(4000) := NULL;
    BEGIN
      IF (gc_debug = 'Y' OR p_force)  THEN
         Lc_Message :=P_Message;
	 fnd_file.Put_Line(Fnd_File.log,Lc_Message);
      END IF;
    EXCEPTION
	WHEN others  THEN
			NULL;
END print_debug_msg;
-- +===================================================================+
-- | FUNCTION   : find_special_chars                                   |
-- |                                                                   |
-- | DESCRIPTION: Checks if special chars exist in a string            |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+
FUNCTION find_special_chars(p_string IN VARCHAR2) RETURN VARCHAR2 
IS
  v_string         VARCHAR2(4000);
  v_char           VARCHAR2(1);
  v_out_string     VARCHAR2(4000) := NULL;
  BEGIN
    v_string := LTRIM(RTRIM(upper(p_string)));
   BEGIN
    SELECT LENGTH(TRIM(TRANSLATE(v_string,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-/', ' ')))
      INTO v_out_string
      FROM DUAL;
   EXCEPTION
     WHEN others THEN
	v_out_string:=NULL;
   END;
  IF v_out_string IS NOT NULL THEN
     RETURN 'JUNK_CHARS_EXIST';
   ELSE
     RETURN v_string;
   END IF;
END Find_Special_Chars;
-- +======================================================================+
-- | Name        :  submit_validation_report                              |
-- | Description :  This procedure submits custom report and sends the    |
-- |                report output to 				          |
-- |                ODS Rebate / Sales and  Margin Accounting team           |
-- |                and  expense.payables@officedepot.com                 |
-- |									  |
-- |                                                                      |
-- | Parameters  :  p_request_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE submit_validation_report(p_request_id NUMBER)
IS
  v_addlayout 			BOOLEAN;
  v_wait 		        BOOLEAN;
  v_request_id 			NUMBER;
  vc_request_id 		NUMBER;
  v_file_name 			VARCHAR2(100);
  v_dfile_name			VARCHAR2(100);
  v_sfile_name 			VARCHAR2(100);
  x_dummy			VARCHAR2(6000) 	;
  v_dphase			VARCHAR2(100)	;
  v_dstatus			VARCHAR2(100)	;
  v_phase			VARCHAR2(100)   ;
  v_status			VARCHAR2(100)   ;
  x_cdummy			VARCHAR2(6000) 	;
  v_cdphase			VARCHAR2(100)	;
  v_cdstatus			VARCHAR2(100)	;
  v_cphase			VARCHAR2(100)   ;
  v_cstatus			VARCHAR2(100)   ;
  v_recipient			VARCHAR2(100);
  lc_first_rec  		VARCHAR2(1);
  lc_temp_email 		VARCHAR2(2000);
  lc_boolean            	BOOLEAN;
  lc_boolean1           	BOOLEAN;
  conn 			utl_smtp.connection;
  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL 		TYPE_TAB_EMAIL;
BEGIN
     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
     SELECT TV.target_value3
           ,TV.target_value4
           ,TV.target_value5
     INTO
            EMAIL_TBL(3)
           ,EMAIL_TBL(4)
           ,EMAIL_TBL(5)
     FROM   XX_FIN_TRANSLATEVALUES TV
           ,XX_FIN_TRANSLATEDEFINITION TD
     WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
     AND   TRANSLATION_NAME = 'EBS_NOTIFICATIONS'
     AND   source_value1    = 'AP_CUSTOMER_REBATE';
     ------------------------------------
     --Building string of email addresses
     ------------------------------------
     lc_first_rec  := 'Y';
     For ln_cnt in 3..5 Loop
          IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
               IF lc_first_rec = 'Y' THEN
                   lc_temp_email := EMAIL_TBL(ln_cnt);
                   lc_first_rec := 'N';
               ELSE
                   lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
               END IF;
          END IF;
     End loop ;
       IF lc_temp_email IS NULL THEN
	  lc_temp_email:='ebs_test_notifications@officedepot.com';
       END IF;
     EXCEPTION
       WHEN others then
         lc_temp_email:='ebs_test_notifications@officedepot.com';
     END;
   v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
	 	               			   template_code => 'XXAPRBRP',
			  				   template_language => 'en',
							   template_territory => 'US',
			        			   output_format => 'EXCEL');
  IF (v_addlayout) THEN
     fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
  ELSE
     fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
  END IF;
  lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);
  lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXAPRBRP','OD: Customer Rebate Upload Report',NULL,FALSE,
		p_request_id,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
  IF v_request_id>0 THEN
     COMMIT;
     v_file_name:='XXAPRBRP_'||to_char(v_request_id)||'_1.xls';
     v_sfile_name:='OD_AP_Customer_Rebate_Validation'||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')||'.xls';
     v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
  END IF;
  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
     IF v_dphase = 'COMPLETE' THEN
        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;
        vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
	IF vc_request_id>0 THEN
	   COMMIT;
        END IF;
 	IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
			v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN
	   IF v_cdphase = 'COMPLETE' THEN  -- child
	      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email List :'||lc_temp_email);
  	        conn := xx_pa_pb_mail.begin_mail(
	  	        sender => 'noreply@officedepot.com',
	  	        recipients => lc_temp_email,
			cc_recipients=>NULL,
		        subject => 'OD: Customer Rebate Upload Report',
		        mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
             xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
             xx_pa_pb_mail.end_attachment(conn => conn);
             xx_pa_pb_mail.attach_text( conn => conn,
  		                        data => 'Please find the attached report for the details' 
				      );
             xx_pa_pb_mail.end_mail( conn => conn );
	     COMMIT;
	   END IF; --IF v_cdphase = 'COMPLETE' THEN -- child
 	END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
     END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main
  END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in submit_purge_er_report :'||SQLERRM);
END submit_validation_report;
-- +====================================================================+
-- | Name        :  purge_proc                                          |
-- | Description :  This procedure is to purge the processed records    |
-- |                in the custom table XX_AP_BULK_CHECK_INVOICE_STG       |
-- | Parameters  :                                                      |
-- +====================================================================+
PROCEDURE purge_proc
IS
CURSOR C1
IS
SELECT rowid drowid
  FROM XX_AP_BULK_CHECK_INVOICE_STG
 WHERE process_Flag=7
   AND creation_date<SYSDATE-90;
i NUMBER:=0;
BEGIN
  FOR cur IN C1 LOOP
    i:=i+1;
    IF i>=5000 THEN
       COMMIT;
       i:=i+1;
    END IF;
    DELETE
      FROM XX_AP_BULK_CHECK_INVOICE_STG
     WHERE rowid=cur.drowid;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in Purging Processed Records : '||SQLERRM);
END purge_proc;
--+============================================================================+
--| Name          : validate_records                                           |
--| Description   : This procedure will Validate records in Staging invoice    |
--|                		Header and invoice Line records                |
--| Parameters    : x_val_records   OUT NUMBER                                 |
--|                 x_inval_records OUT NUMBER                                 |
--|                 x_return_status  OUT VARCHAR2                              |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE  validate_records
IS 
  i                      NUMBER;
  j                      NUMBER;
  ln_hdr_cnt             NUMBER:=0;
  ln_line_cnt            NUMBER :=0;      
  l_invoice_line_id      NUMBER:=0;
  l_line_amount          NUMBER:=0;
  ln_line_validate_flag_count    Number :=0;
  l_org_id               Number;
  l_err_buff             Varchar2(5000);
  v_vendor_name          ap_suppliers.vendor_name%type ;
  v_vendor_id            ap_suppliers.vendor_id%type ;
  v_vendor_site_id       ap_supplier_sites_all.vendor_site_id%type;
  v_dist_ccid            Number;
  l_idxs                 Number;
  l_inv_hdr_process_flag Number ;
  l_inv_hdr_err_msg      Varchar2(2000);
  l_error_message        Varchar2(3000);
  l_inv_num              Varchar2(200);
  l_is_line_failed       Varchar2(1);
  l_inv_line_validate_flag  Number;
  l_inv_line_err_msg     Varchar2(2000);
  v_inv_line_err_msg     Varchar2(2000);
  ln_invoice_number      Varchar2(50);
  ln_total_hdr_success   Number:=0;
  ln_total_ln_success    Number:=0;
  l_inv_hdr_cnt          Number:=0;
  l_inv_line_cnt         Number:=0;
  ln_line_no             Number:=0;
  lc_coa_id              Number:=0;
  lc_company   Varchar2(25):=NULL; 
  lc_cost_center Varchar2(25):=NULL; 
  lc_account  Varchar2(25):=NULL;
  lc_location  Varchar2(25):=NULL;
  lc_intercompany  Varchar2(25):=NULL;
  lc_lob Varchar2(25):=NULL;
  lc_future  Varchar2(25):=NULL;
--------------------------------------------
-- Cursor to get distinct header invoices 
---------------------------------------------
CURSOR c_inv_header  
IS
SELECT DISTINCT  
         vendor_no
  		,vendor_site_code           
		,invoice_amt
		,description 
		,vendor_id
		,vendor_site_id
		,invoice_id
		,inv_process_flag
		,error_flag
		,error_message                     
  FROM  XX_AP_BULK_CHECK_INVOICE_STG 
 WHERE  process_flag=2
   AND  request_id=gn_request_id;
TYPE l_inv_header_tab IS TABLE OF  c_inv_header%ROWTYPE INDEX BY PLS_INTEGER;  
v_inv_header_tab  l_inv_header_tab;  
--------------------------------------------
-- Cursor to get invoices lines
--------------------------------------------- 
CURSOR c_inv_line 
IS
SELECT  line_description
	    ,distcode_concatenated
	    ,Vendor_no                     
	    ,vendor_site_code    
	    ,line_amount       
	    ,description 
	    ,dist_ccid
	    ,line_validate_flag
	    ,error_flag
	    ,error_message
	    ,rowid drowid
  FROM   XX_AP_BULK_CHECK_INVOICE_STG 
 WHERE   process_flag=2
   AND   request_id=gn_request_id;     
TYPE l_inv_line_tab IS TABLE OF c_inv_line%ROWTYPE INDEX BY PLS_INTEGER;
V_inv_line_tab l_inv_line_tab; 
---------------------------------------------
-- Cursor to generate the invoice num
---------------------------------------------
CURSOR c_inv_num 
IS
SELECT  DISTINCT Vendor_no                     
		,vendor_site_code           
		,invoice_amt
  FROM  XX_AP_BULK_CHECK_INVOICE_STG 
 WHERE  inv_process_flag=4
   AND  request_id=gn_request_id;
---------------------------------------------
--Cursor to get the Line information
---------------------------------------------
CURSOR lcu_line(p_request_id 		IN NUMBER,
		p_vendor_no  		IN VARCHAR2,
	        p_vend_site_code 	IN VARCHAR2,
		p_hdr_amt 		IN NUMBER)
IS
SELECT rowid drowid
      ,vendor_no
      ,vendor_site_code
      ,invoice_amt
 FROM XX_AP_BULK_CHECK_INVOICE_STG 
WHERE request_id=p_request_id
  AND vendor_no=p_vendor_no
  AND vendor_site_code=p_vend_site_code
  AND invoice_amt=p_hdr_amt;		   
BEGIN
 print_debug_msg (p_message=>'------Header records validation------',P_force     => TRUE);
OPEN c_inv_header;
  LOOP
     FETCH c_inv_header BULK COLLECT INTO v_inv_header_tab;
EXIT WHEN v_inv_header_tab.COUNT = 0;
FOR i IN v_inv_header_tab.FIRST .. v_inv_header_tab.LAST  Loop
	ln_hdr_cnt:=ln_hdr_cnt+1;
	l_inv_hdr_process_flag:=4;
	l_inv_hdr_err_msg:= NULL; 
--==========================================================================================
-- Validate Supplier  and Derive Supplier Site id Details
--==========================================================================================
    BEGIN 
     IF gc_debug='Y' THEN
       print_debug_msg(p_message => 'Vendor no         : '||v_inv_header_tab(i).vendor_no, p_force => FALSE); 
       print_debug_msg(p_message => 'Vendor site code  : '||v_inv_header_tab(i).vendor_site_code, p_force => FALSE); 
     END IF;
           SELECT asus.vendor_site_id,asu.vendor_id
	     INTO v_vendor_site_id,v_vendor_id
	     FROM ap_suppliers asu
		  ,ap_supplier_sites_all asus
	    WHERE asu.vendor_id = asus.vendor_id  
	      AND asu.segment1=v_inv_header_tab(i).vendor_no
	      AND asus.vendor_site_code= v_inv_header_tab(i).vendor_site_code
	      AND (asu.end_date_active IS NULL or asu.end_date_active>=SYSDATE)
	      AND (asus.inactive_date IS NULL or asus.inactive_date >= SYSDATE)
	      AND asus.org_id = (SELECT organization_id
				   FROM hr_operating_units
				  WHERE NAME = 'OU_US');
	   v_inv_header_tab(i).vendor_id:=v_vendor_id;	
	   v_inv_header_tab(i).vendor_site_id:=v_vendor_site_id;
     IF gc_debug='Y' THEN
       print_debug_msg(p_message => 'Vendor id         : '||v_vendor_id, p_force => FALSE);
       print_debug_msg(p_message => 'Vendor site id    : '||v_vendor_site_id, p_force => FALSE);
     END IF;
  EXCEPTION
   WHEN no_data_found THEN 
    l_inv_hdr_process_flag :=3;
    l_inv_hdr_err_msg:= 'Invalid Supplier Global No.'||'/'||'Invalid Supplier Site No. ';
    print_debug_msg(p_message => l_inv_hdr_err_msg||' : '||' Vendor '||v_inv_header_tab(i).vendor_no||' and Vendor Site Code : '||v_inv_header_tab(i).vendor_site_code
	           ,p_force => FALSE); 
   WHEN others THEN
    l_inv_hdr_process_flag :=3;
    l_inv_hdr_err_msg:= 'When others in Supplier Validation'||' - '||SQLCODE || ' - '|| SUBSTR (SQLERRM,1,1500);
    Print_debug_msg(p_message => l_inv_hdr_err_msg, p_force => FALSE); 
  END;
--==========================================================================================
-- Validate Header Description has special Characters 
--==========================================================================================
   IF gc_debug='Y' THEN
      print_debug_msg(p_message => 'Header description : '||v_inv_header_tab(i).description, p_force => FALSE);
   END IF;  

   IF (v_inv_header_tab(i).description IS NULL)  THEN
      l_inv_hdr_process_flag :=3;
      l_inv_hdr_err_msg:= l_inv_hdr_err_msg||' Missing Header Description. ';      
      Print_debug_msg(p_message =>l_inv_hdr_err_msg||v_inv_header_tab(i).description
                    ,p_force => FALSE);
   ELSIF  (find_special_chars(v_inv_header_tab(i).description) = 'JUNK_CHARS_EXIST') THEN
      l_inv_hdr_process_flag :=3;
      l_inv_hdr_err_msg:= l_inv_hdr_err_msg||' Header Description Containing Special Characters. '; 
       Print_debug_msg(p_message =>l_inv_hdr_err_msg||v_inv_header_tab(i).description
                  ,p_force => FALSE);  
   ELSE 
     NULL;   
   END IF;

   IF (v_inv_header_tab(i).invoice_amt <=0)  THEN  -- Defect 39429
      l_inv_hdr_process_flag :=3;
      l_inv_hdr_err_msg:= l_inv_hdr_err_msg||' Invalid Invoice Amount';      
      Print_debug_msg(p_message =>l_inv_hdr_err_msg||v_inv_header_tab(i).description
                    ,p_force => FALSE);
   END IF;

   
 IF  l_inv_hdr_process_flag =3  THEN
     v_inv_header_tab(i).inv_process_flag:=3;
     v_inv_header_tab(i).error_flag:='Y';
     v_inv_header_tab(i).error_message:=LTRIM(RTRIM(l_inv_hdr_err_msg)); 
     IF gc_debug='Y' THEN
      print_debug_msg(p_message => 'Inv_process_flag  : '||v_inv_header_tab(i).inv_process_flag, p_force => FALSE);
      print_debug_msg(p_message => 'Error_flag        : '||v_inv_header_tab(i).inv_process_flag, p_force => FALSE);
      print_debug_msg(p_message => 'Error_message     : '||v_inv_header_tab(i).error_message   , p_force => FALSE);
      END IF;
  ELSE
      v_inv_header_tab(i).inv_process_flag:=4;
      IF gc_debug='Y' THEN
      print_debug_msg(p_message => 'Inv_process_flag  : '||v_inv_header_tab(i).inv_process_flag, p_force => FALSE);
      END IF;
  End IF;	    
END  LOOP;
 --===============================================================================================
 -- Updating the staging table Header record with vendor num,sitecode ,invoice process flag values  
 --===============================================================================================
    IF v_inv_header_tab.COUNT > 0 THEN
       BEGIN
	  FORALL l_idxs  IN v_inv_header_tab.FIRST .. v_inv_header_tab.LAST
	     UPDATE XX_AP_BULK_CHECK_INVOICE_STG
	        SET inv_process_flag = v_inv_header_tab (l_idxs).inv_process_flag,
		    error_flag = v_inv_header_tab (l_idxs).ERROR_FLAG,
     		    error_message  = v_inv_header_tab (l_idxs).ERROR_MESSAGE,
		    vendor_id = v_inv_header_tab (l_idxs).vendor_id,
	            vendor_site_id=v_inv_header_tab (l_idxs).vendor_site_id
	      WHERE vendor_no=v_inv_header_tab(l_idxs).vendor_no
		AND vendor_site_code=v_inv_header_tab(l_idxs).vendor_site_code
		AND invoice_amt =v_inv_header_tab(l_idxs).invoice_amt
		AND request_id = gn_request_id;  
	EXCEPTION
	    WHEN others THEN
	       l_error_message :='When Others Exception  during the bulk update of invoice staging table'
				 || SQLCODE
				 || ' - '
				 || SUBSTR (SQLERRM, 1,1500);
		print_debug_msg (p_message   => l_error_message,P_force     => FALSE);
	 END;
    END IF;                          -- IF v_inv_header_tab.COUNT > 0   
END LOOP;
Close c_inv_header; 
	print_debug_msg (p_message=>'------Header records validation End------',P_force     => True);	
	print_debug_msg (p_message=>'Total Invoice Header records validated'||' : '||ln_hdr_cnt,P_force     => TRUE);
--===========================================================================================
-- Validate  line  level records and bulk update the invoice line values 
--========================================================================================== 
    print_debug_msg (p_message=>'------Line records validation------',P_force     => TRUE);
OPEN  c_inv_line;
	 ln_line_cnt := 0; 
	 l_is_line_failed := 'N';
 LOOP
  FETCH c_inv_line BULK COLLECT INTO v_inv_line_tab;
EXIT WHEN v_inv_line_tab.COUNT = 0; 
FOR j in v_inv_line_tab.FIRST .. v_inv_line_tab.LAST  LOOP
         l_inv_line_validate_flag :=4;
	 l_inv_line_err_msg:= NULL;
	 ln_line_cnt :=ln_line_cnt +1;
 IF gc_debug='Y' THEN
       print_debug_msg(p_message => 'Vendor no         : '||v_inv_line_tab(j).vendor_no, p_force => FALSE);
       print_debug_msg(p_message => 'Vendor site code  : '||v_inv_line_tab(j).vendor_site_code, p_force => FALSE);
     END IF;
--==========================================================================================
-- Validate weather the line Distribution Code exists or not
--========================================================================================== 
BEGIN    
         lc_coa_id:=0;
         lc_company :=NULL; 
         lc_cost_center :=NULL; 
         lc_account  :=NULL;
         lc_location :=NULL;
         lc_intercompany :=NULL;
         lc_lob :=NULL;
         lc_future :=NULL;
     	  BEGIN
           SELECT gsb.chart_of_accounts_id
             INTO lc_coa_id
             FROM gl_sets_of_books_v gsb
            WHERE gsb.set_of_books_id =fnd_profile.VALUE ('GL_SET_OF_BKS_ID'); 
       	  EXCEPTION
           WHEN others THEN
	    lc_coa_id:=NULL;
           END;
           IF gc_debug='Y' THEN
             print_debug_msg(p_message => 'Distcode_Concateneated  : '||v_inv_line_tab(j).DISTCODE_CONCATENATED, p_force => FALSE);
            END IF;
	 lc_company := substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,1,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,1)-1); -- company (segment1)
 	 lc_cost_center := substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,1)+1,(instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,2)- instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,1)-1));-- cost center (segment2)
 	 lc_account := substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,2)+1,(instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,3)- instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,2)-1)); -- account (segment3)
 	 lc_location :=substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,3)+1,(instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,4)- instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,3)-1)); -- location (segment4)
 	 lc_intercompany :=substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,4)+1,(instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,5)- instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,4)-1));  -- intercompany (segment5)
 	 lc_lob :=substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,5)+1,(instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,6)- instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,5)-1));	    -- lob(segment6)
	 lc_future :=substr(v_inv_line_tab(j).DISTCODE_CONCATENATED,instr(v_inv_line_tab(j).DISTCODE_CONCATENATED,'.', 1,6)+1,length(v_inv_line_tab(j).DISTCODE_CONCATENATED));  --future (segment7)
                 IF gc_debug='Y' THEN
                      print_debug_msg(p_message =>'lc_company     : '||lc_company , p_force => FALSE);
                      print_debug_msg(p_message =>'lc_cost_center : '||lc_cost_center, p_force => FALSE);
                      print_debug_msg(p_message =>'lc_account     : '||lc_account, p_force => FALSE);
                      print_debug_msg(p_message =>'lc_location    : '||lc_location, p_force => FALSE);
                      print_debug_msg(p_message =>'lc_intercompany: '||lc_intercompany, p_force => FALSE);
                      print_debug_msg(p_message =>'lc_lob         : '||lc_lob, p_force => FALSE);
                      print_debug_msg(p_message =>'lc_future      : '||lc_future, p_force => FALSE);
                 END IF;
			SELECT /*+ INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */
	                        code_combination_id
            	         INTO v_dist_ccid
	                 FROM gl_code_combinations
                        WHERE chart_of_accounts_id = lc_coa_id
                          AND segment1 = ltrim(rtrim(lc_company))  -- company
                          AND segment2 = ltrim(rtrim(lc_cost_center))  -- cost center
                          AND segment3 = ltrim(rtrim(lc_account))  -- account
                          AND segment4 = ltrim(rtrim(lc_location))  -- location
                          AND segment5 = ltrim(rtrim(lc_intercompany))  -- intercompany
                          AND segment6 = ltrim(rtrim(lc_lob))  -- lob
                          AND segment7 = ltrim(rtrim(lc_future))  -- future
                          AND enabled_flag='Y';
                  v_inv_line_tab(j).dist_ccid:=v_dist_ccid;
                  IF gc_debug='Y' THEN
                     print_debug_msg(p_message => 'v_dist_ccid : '||v_dist_ccid, p_force => FALSE);
                    END IF;
EXCEPTION
  WHEN no_data_found THEN
	    l_inv_line_validate_flag :=3;
      l_inv_line_err_msg :='Invalid GL Distribution. ';
     print_debug_msg(p_message => l_inv_line_err_msg||':'||v_inv_line_tab(j).DISTCODE_CONCATENATED , p_force => FALSE); 		
  WHEN others THEN
    l_inv_line_validate_flag :=3;
    l_inv_line_err_msg := 'When others in Account Validation'||SQLCODE || ' - '|| SUBSTR (SQLERRM,1,1500);
    print_debug_msg(p_message => l_inv_line_err_msg||':'||v_inv_line_tab(j).DISTCODE_CONCATENATED, p_force => FALSE);   
END;
--==========================================================================================
-- Validate weather the Line Description has special Characters 
--===========================================================================================
 IF gc_debug='Y' THEN     
    print_debug_msg(p_message => 'Line Description Containing Special Characters.'||v_inv_line_tab(j).line_description, p_force => FALSE);      
    END IF;
 
 
    IF (v_inv_line_tab(j).line_description IS NULL) THEN 
        l_inv_line_validate_flag :=3;
        l_inv_line_err_msg:= l_inv_line_err_msg||' Missing Line Description. ';      
        Print_debug_msg(p_message =>l_inv_line_err_msg||v_inv_line_tab(j).line_description
                    ,p_force => FALSE);
    ELSIF  (find_special_chars(v_inv_line_tab(j).line_description) = 'JUNK_CHARS_EXIST') THEN
        l_inv_line_validate_flag :=3;
        l_inv_line_err_msg:= l_inv_line_err_msg||' Line Description Containing Special Characters. '; 
        Print_debug_msg(p_message =>l_inv_line_err_msg||v_inv_line_tab(j).line_description
                    ,p_force => FALSE); 
    ELSE
       NULL;
    END IF;    


    IF gc_debug='Y' THEN     
    print_debug_msg(p_message => 'Line Description        :'||v_inv_line_tab(j).line_description, p_force => FALSE);      
    END IF;


   IF (v_inv_line_tab(j).line_amount <=0) THEN 

        l_inv_line_validate_flag :=3;
        l_inv_line_err_msg:= l_inv_line_err_msg||' Invalid Line Amount';      

   END IF;

    IF l_inv_line_validate_flag=3  THEN 

       v_inv_line_tab(j).Line_Validate_flag:=3;
       v_inv_line_tab(j).error_flag:='Y';
       IF v_inv_line_tab(j).error_message IS NULL  THEN
           v_inv_line_tab(j).error_message:= v_inv_line_tab(j).error_message||LTRIM(RTRIM(l_inv_line_err_msg)); 
       ELSE
           v_inv_line_tab(j).error_message:= v_inv_line_tab(j).error_message||' '||LTRIM(RTRIM(l_inv_line_err_msg)); 
       END IF;
       l_is_line_failed := 'Y';
 
       IF gc_debug='Y' THEN     
          print_debug_msg(p_message => 'Line_Validate_flag        :'||v_inv_line_tab(j).line_validate_flag, p_force => FALSE);  
          print_debug_msg(p_message => 'Error_flag                :'||v_inv_line_tab(j).error_flag, p_force => FALSE);      
          print_debug_msg(p_message => 'Error_message             :'||v_inv_line_tab(j).error_message, p_force => FALSE);      
       END IF; 
    ELSE

       v_inv_line_tab(j).Line_Validate_flag:=4;
       IF gc_debug='Y' THEN     
         print_debug_msg(p_message => 'Line_Validate_flag        :'||v_inv_line_tab(j).line_validate_flag, p_force => FALSE);  
       END IF;
    END IF;		 
END LOOP; --- Line Level close -- For j in v_inv_line_tab.FIRST 
 --==========================================================================================
 -- updateing the linlevel record with dist_id ,line_validate_flag
 --===========================================================================================
    IF v_inv_line_tab.COUNT > 0 THEN
     BEGIN
	  FORALL l_idxs 	  IN v_inv_line_tab.FIRST .. v_inv_line_tab.LAST
	    UPDATE XX_AP_BULK_CHECK_INVOICE_STG
	       SET  line_validate_flag = v_inv_line_tab (l_idxs).Line_Validate_flag
 		        ,error_flag    = decode(error_FLAG, 'Y', 'Y', v_inv_line_tab (l_idxs).error_flag)
		        ,error_Message = v_inv_line_tab (l_idxs).Error_Message
		        ,dist_ccid  = v_inv_line_tab (l_idxs).dist_ccid
	     WHERE rowid = v_inv_line_tab(l_idxs).drowid
	       AND request_id = gn_request_id;
	 EXCEPTION
	  WHEN OTHERS   THEN
		  l_error_message :='When Others Exception  during the bulk update of invoice staging table'
				   || SQLCODE
				   || ' - '
				 || SUBSTR (SQLERRM, 1, 3800);
		  print_debug_msg (p_message   =>l_error_message,p_force     => FALSE);
		  END;
    END IF;                          -- IF v_inv_line_tab.COUNT > 0      
END LOOP ;
CLOSE c_inv_line;
	 print_debug_msg (p_message=>'------Line records validation End------',P_force     => TRUE);
	 print_debug_msg (p_message=>'Total Invoice line records validated'||' : '||ln_line_cnt,P_force     => TRUE);
--=============================================================================
-- Validating the Unbalanced Invoice Header and Line
--=============================================================================
BEGIN
	  UPDATE XX_AP_BULK_CHECK_INVOICE_STG oinv
	     SET oinv.inv_process_flag = 3
	        ,oinv.ERROR_FLAG = 'Y'
  		   ,oinv.ERROR_Message = trim(oinv.ERROR_Message||' Unbalanced Invoice Header and Line.')
	   WHERE request_id=gn_request_id
          AND process_flag=2
          AND oinv.invoice_amt+0 <> (SELECT SUM(iinv.line_amount) 
	   		                   FROM XX_AP_BULK_CHECK_INVOICE_STG iinv 
			                  WHERE iinv.vendor_no = oinv.vendor_no
			                    AND iinv.vendor_site_code=oinv.vendor_site_code 
			                    AND iinv.invoice_amt=oinv.invoice_amt
                          		    AND iinv.request_id=gn_request_id);
EXCEPTION
       WHEN  others  THEN
        l_error_message :='Unbalanced Invoice Header and Line'
       					   || SQLCODE
       					   || ' - '
       					   || SUBSTR (SQLERRM, 1,1500);
		print_debug_msg (p_message=>l_error_message,p_force=> FALSE);
END;  
 --=============================================================================
 -- Validating the Invoice Amount is Greater than 100K
 --============================================================================= 
BEGIN
  UPDATE XX_AP_BULK_CHECK_INVOICE_STG oinv
     SET oinv.inv_process_flag = 3
	   ,oinv.ERROR_FLAG = 'Y'
	   ,oinv.ERROR_Message =trim(oinv.ERROR_Message||' Invoice Amount Greater than 100K.')
   WHERE request_id = gn_request_id
     AND process_flag=2
     AND oinv.invoice_amt>100000
     AND EXISTS ( SELECT 'x' 
		         FROM XX_AP_BULK_CHECK_INVOICE_STG iinv 
		        WHERE iinv.vendor_no = oinv.vendor_no 
			     AND iinv.vendor_site_code=oinv.vendor_site_code
		          AND iinv.invoice_amt=oinv.invoice_amt 
                     AND iinv.request_id=gn_request_id);
  EXCEPTION
	WHEN  others  THEN
		l_error_message :=' Invoice Amount Greater than 100K'
		    		    || SQLCODE
    				    || ' - '
				    || SUBSTR (SQLERRM, 1, 1500);
		print_debug_msg (p_message   =>l_error_message,p_force     => FALSE);
END;
--=============================================================================
  -- Validating if one of Invoice line is falied -fail the total invoice
--============================================================================ 
BEGIN
  UPDATE XX_AP_BULK_CHECK_INVOICE_STG oinv
     SET oinv.inv_process_flag = 3
	   ,oinv.ERROR_FLAG = 'Y'
   WHERE request_id =gn_request_id
     AND process_Flag=2
     AND  EXISTS ( SELECT '1' 
				FROM  XX_AP_BULK_CHECK_INVOICE_STG iinv 
		          WHERE  iinv.vendor_no = oinv.vendor_no 
				  AND  iinv.vendor_site_code=oinv.vendor_site_code
				  AND  iinv.invoice_amt=oinv.invoice_amt 
				  AND  iinv.line_validate_flag = 3	
            AND  iinv.request_id=gn_request_id);
 EXCEPTION
         WHEN  others  THEN
                l_error_message :='One of the Invoice line is falied'
				   || SQLCODE
				   || ' - '
				   || SUBSTR (SQLERRM, 1, 1500);
	        print_debug_msg (p_message   =>l_error_message,p_force  => FALSE);
END;
COMMIT;
--===============================================================================
-- Update the staging table with invoice number for all validated success records
--===============================================================================
BEGIN
  For l_inv_num in c_inv_num loop 
	--========================================================================
	-- Generating Invvoice Number using Sequence 
	--=======================================================================
     BEGIN
       SELECT  'SPRB2'||LPAD(XX_AP_CUSTOMER_REBATE_S.NEXTVAL,8,0)
	    INTO ln_invoice_number 
   	    FROM  dual;
       UPDATE  XX_AP_BULK_CHECK_INVOICE_STG oinv
	     SET oinv.invoice_num =ln_invoice_number
	   WHERE oinv.request_id=gn_request_id
  	     AND  oinv.vendor_no = l_inv_num.vendor_no 
		AND  oinv.vendor_site_code=l_inv_num.vendor_site_code
		AND  oinv.invoice_amt=l_inv_num.invoice_amt 
		AND  oinv.inv_process_flag = 4;
     EXCEPTION
	  WHEN  Others  THEN
			   l_error_message :='Failed when generating the Invoice Num'
								 || SQLCODE
								 || ' - '
								 || SUBSTR (SQLERRM, 1, 1500);
			   print_debug_msg (p_message   =>l_error_message,p_force     => FALSE); 
     END;
   End LOOP; 
   COMMIT;    
--===============================================================================
-- To update line number in the staging table
--===============================================================================
  FOR cur IN c_inv_header  LOOP
     ln_line_no:=0;
	FOR c IN lcu_line(gn_request_id,cur.vendor_no,cur.vendor_site_code,cur.invoice_amt) LOOP
	  ln_line_no:=ln_line_no+1;
	  UPDATE XX_AP_BULK_CHECK_INVOICE_STG
	     SET line_number=ln_line_no
	   WHERE rowid=c.drowid;
        END LOOP;
       COMMIT;
    END LOOP;
 --==========================================================================================
 -- Deleting the pl/sql records data
 --==========================================================================================           
        V_inv_line_tab.DELETE;
        v_inv_header_tab.DELETE;
     SELECT COUNT(DISTINCT invoice_num),COUNT(1)
         INTO ln_total_hdr_success,ln_total_ln_success
         FROM XX_AP_BULK_CHECK_INVOICE_STG 
       WHERE request_id=gn_request_id
         AND inv_process_flag=4
         AND invoice_num||'' IS NOT NULL;        
    print_debug_msg('Total Validation Success Invoice Headers :'||TO_CHAR(ln_total_hdr_success),p_force     => TRUE);
    print_debug_msg('Total Validation Success Invoice Lines :'||TO_CHAR(ln_total_ln_success),p_force     => TRUE);
EXCEPTION 
  WHEN  others  THEN
    l_error_message :='Failed when generating the Invoice Num'
		    || SQLCODE
		    || ' - '
		    || SUBSTR (SQLERRM, 1, 1500);
   print_debug_msg (p_message   =>l_error_message,p_force     => FALSE); 
END;
END  validate_records;
--+============================================================================+
--| Name          : load_invoices  		                               |
--| Description   : This procedure will insert records in           invoice    |
--|                 interface Header and invoice interafec Line records        |
--|								      	       |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE load_invoices  IS
--==============================================================================
-- Cursor Declarations for invoices
--==============================================================================
 CURSOR C_inv_hdr 
 IS
  SELECT  DISTINCT 
           invoice_num
	  ,vendor_no                     
	  ,vendor_site_code           
	  ,invoice_amt
	  ,trunc(invoice_date) invoice_date
	  ,description 
	  ,vendor_id
	  ,vendor_site_id
    FROM  XX_AP_BULK_CHECK_INVOICE_STG 
   WHERE  inv_process_flag=4
     AND  request_id=gn_request_id;
--==============================================================================
-- Cursor Declarations for invoice Lines
--==============================================================================
 CURSOR C_inv_line(p_invoice_num Varchar2) 
 IS 
 SELECT  trunc(invoice_date) invoice_date
	,line_amount
	,line_description
	,dist_ccid
   FROM XX_AP_BULK_CHECK_INVOICE_STG XABCI  
  WHERE invoice_num=p_invoice_num
    AND request_id=gn_request_id;
--===================================================================================
-- Variables Declaration used for getting the data into PL/SQL Table for processing
--===================================================================================
      l_process_status_flag          VARCHAR2(1);
      l_org_id                       NUMBER:= fnd_profile.value('ORG_ID');
      l_user_id                      NUMBER:= fnd_global.user_id;
      l_invoice_line_id              NUMBER;
      ln_invoice_number              ap_invoices_all.invoice_num%type:=NULL; 
      ln_line_num                    NUMBER;
      lp_hdr_loopcnt                 NUMBER;
      lp_line_loopcnt                NUMBER;
      l_error_message                Varchar2(2000);   
BEGIN
  l_process_status_flag := 'Y';
  lp_hdr_loopcnt := 0;
  lp_line_loopcnt:=0;
  print_debug_msg (p_message=>'------Insert Validated  records into interafce Table------',P_force     => TRUE);
  --===========================================================================
   -- Load the validated records in staging table into invoice  interface table  
  --===========================================================================  
  FOR l_inv_hdr in C_inv_hdr   LOOP
  --===========================================================================
  -- Generating the Invoice Number 
  --===========================================================================   
	BEGIN       
           INSERT   INTO  AP_INVOICES_INTERFACE
                        (	
                         invoice_id,
			 invoice_num,
			 vendor_id,
			 vendor_site_id,
			 invoice_amount,
			 invoice_date,
			 description,
			 invoice_type_lookup_code,
			 source,
			 attribute7 , 
			 gl_date,
			 org_id,
			 last_update_date,
			 last_updated_by,
			 last_update_login,
			 creation_date,
			 created_by
			)
		VALUES
		       (ap_invoices_interface_s.NEXTVAL,
			l_inv_hdr.invoice_num,
			l_inv_hdr.vendor_id,
			l_inv_hdr.vendor_site_id,
			l_inv_hdr.invoice_amt,
			l_inv_hdr.invoice_date,
			substr(l_inv_hdr.description,1,32),
			decode(sign(l_inv_hdr.invoice_amt),1,'STANDARD',-1,'CREDIT'),
			'US_OD_REBATES',  -- Source Derivation
			'US_OD_REBATES',  -- Attribute7    
			 sysdate,
			l_org_id,
			sysdate,
			l_user_id,
		        g_login_id,
			sysdate,
			l_user_id
			);
				lp_hdr_loopcnt:=lp_hdr_loopcnt+1;
				l_process_status_flag := 'Y';
  EXCEPTION
       WHEN others  THEN
	 l_process_status_flag := 'N';
	 l_error_message := SQLCODE || ' - '|| SQLERRM;
	 print_debug_msg(p_message=>' ERROR: while Inserting Records in Header Inteface Table'
											  ,p_force=> FALSE);  
  END;
      IF l_process_status_flag='N' THEN
      UPDATE XX_AP_BULK_CHECK_INVOICE_STG
         SET error_flag ='Y',
            error_message=error_message||'Failed at Interafce Invoice header record insertion'
            Where invoice_num= l_inv_hdr.invoice_num;
      End IF ;
   --==================================================================================
   -- Load the validated records From staging table into invoice  Lines interface table  
  --=================================================================================== 
   IF l_process_status_flag = 'Y'  THEN 
	ln_line_num:=0;  
       FOR l_inv_line in C_inv_line(l_inv_hdr.invoice_num)  LOOP
		  ln_line_num:= ln_line_num+1; 
		BEGIN  
	          INSERT INTO  AP_INVOICE_LINES_INTERFACE
                           (
			    invoice_id,
			    invoice_line_id,
			    line_number,
			    description,
			    line_type_lookup_code,
			    amount,
			    dist_code_combination_id,
			    accounting_date,
			    last_update_date,
			    last_updated_by,
			    last_update_login,
			    creation_date,
			    created_by
			   )
		    VALUES 
			  (
			  ap_invoices_interface_s.currval,
			  ap_invoice_lines_interface_s.nextval,
			  ln_line_num,       -- Individual Invoice line No
			  substr(l_inv_line.line_description,1,30), 
			  'ITEM',            -- line_type_lookup_code
			   l_inv_line.line_amount,
		           l_inv_line.dist_ccid,
			   sysdate,
			   sysdate,
     			   l_user_id,
			   g_login_id,
			   sysdate,
			   l_user_id
			   );
		  lp_line_loopcnt:=lp_line_loopcnt+1;	
 		 EXCEPTION
			WHEN others THEN
				l_process_status_flag := 'N';
				l_error_message := SQLCODE || ' - '|| SQLERRM;
			        print_debug_msg(p_message=>'ERROR: while Inserting Records in lines Inteface Table'||l_error_message 
						,p_force=> FALSE); 
		END;
        End LOOP; 
      END IF;
    End LOOP;
		  print_debug_msg(p_message=>'Total Invoice header  records in ap_invoices_interaface table'||' : '||lp_hdr_loopcnt
				 ,p_force=> TRUE); 
		  print_debug_msg(p_message=>'Total Invoice line records in ap_invoice_lines_interaface table'||' : '||lp_line_loopcnt
				 ,p_force=> TRUE); 
		  print_debug_msg (p_message=>'------Insert Validated  records into interafce Table  End------'
                                 ,P_force => TRUE);
  --================================================================================================
	   -- Set the process flag to '7' for all the records that processed for the current request ID
  --================================================================================================
				  UPDATE XX_AP_BULK_CHECK_INVOICE_STG
					 SET Process_flag=7
				   WHERE request_id=gn_request_id;   
			COMMIT;	 
EXCEPTION 
  WHEN others THEN
   l_process_status_flag := 'Y';
   l_error_message := SQLCODE || ' - '|| SQLERRM;
   print_debug_msg(p_message=>' ERROR: while Inserting Records in lines Inteface Table'
		  ,p_force=> TRUE); 
End  load_invoices ;
--+==================================================================+
--| Name          : process_rebate                                   |
--| Description   : process_rebate procedure will be called from the |
--|                 concurrent program for invoice Interface         |
--| Parameters    : p_debug_level          IN     VARCHAR2           |
--| Returns       :                                                  |
--|                 x_errbuf               OUT    VARCHAR2           |
--|                 x_retcode              OUT    NUMBER             |
--+==================================================================+
PROCEDURE   process_rebate(x_errbuf           OUT NOCOPY VARCHAR2,
                     x_retcode          OUT NOCOPY NUMBER,
                     p_debug_level      IN  VARCHAR2)
IS
--================================================================
-- Declaring local variables
--================================================================
   l_procedure                   VARCHAR2 (30) := 'process_rebate';
   l_return_status               VARCHAR2 (100);
   l_err_buff                    VARCHAR2 (4000);
   l_inval_records PLS_INTEGER   := 0;
   l_val_records PLS_INTEGER     := 0;
BEGIN
--================================================================
--Initializing Global variables
--================================================================
     gc_debug := p_debug_level;      
		 print_debug_msg (
		 p_message   => 'Debug Flag :' || p_debug_level,
		 p_force     => TRUE);
--==========================================================================
--Updating Request Id into XX_AP_BULK_CHECK_INVOICE_STG Staging table     -- 
--==========================================================================
     UPDATE XX_AP_BULK_CHECK_INVOICE_STG
        SET process_Flag=7
      WHERE process_flag=1
        AND vendor_no IS NULL
        AND vendor_site_code IS NULL
        AND NVL(invoice_amt,0)=0
        AND description IS NULL
	   AND NVL(line_amount,0)=0
	   AND distcode_concatenated IS NULL
	   AND line_description IS NULL;
      UPDATE XX_AP_BULK_CHECK_INVOICE_STG
         SET INV_PROCESS_FLAG = 2
		  ,PROCESS_FLAG=2
		  ,REQUEST_ID = gn_request_id          
             ,description=regexp_replace(description, '(^[[:space:]]+)|([[:space:]]+$)',null)
             ,line_description=regexp_replace(line_description, '(^[[:space:]]+)|([[:space:]]+$)',null)
	  WHERE PROCESS_FLAG = 1;
     COMMIT;
--==================================================================
-- Validate the records invoking the API  validate_records()    -- 
--==================================================================
print_debug_msg(p_message => 'Invoking the procedure validate_records()', p_force => true);
	  validate_records;
--===========================================================================
-- Load the validated records in staging table into interface table    -- 
--===========================================================================  
print_debug_msg(p_message => 'Invoking the procedure  Load_invoices()', p_force => true);
	  load_invoices;
--===========================================================================
-- Submit Validation report    -- 
--===========================================================================  
print_debug_msg(p_message => 'Invoking the submit report procedure', p_force => true);
	  submit_validation_report(gn_request_id);
--===========================================================================
-- Submit Purge Procedure   -- 
--===========================================================================  
print_debug_msg(p_message => 'Invoking the Purge_poc procedure', p_force => true);
         purge_proc;
EXCEPTION    
WHEN others THEN 
 x_retcode := 2;
 x_errbuf :='Exception in XX_AP_CUSTOMER_REBATE_PKG.process_rebate() - '
             || SQLCODE
             || ' '
             || SUBSTR (SQLERRM, 1, 1500); 
print_debug_msg(p_message => 'Exception at invoking the process_rebate procedure', p_force => true);
END process_rebate;
END XX_AP_CUSTOMER_REBATE_PKG;
/
SHOW ERRORS;