CREATE OR REPLACE PACKAGE BODY xx_ap_inv_validate_pkg
IS
   gc_pcard_acct_num  VARCHAR2(50);
-- +=================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                |
-- |                                                                                                                 |
-- +=================================================================================================================+
-- | Name :  XX_AP_INV_VALIDATE_PKG                                                                                  |
-- | Description : the following for invoices in the invoices staging tables:                                        |
-- |  * Purge records from Invoice staging tables                                                                    |
-- |     * checks for invoices that have already been imported into AP                                               |
-- |  * Check and Submit the Concurrent Request Emailer program to notify vendor of existing duplicate files         |
-- |  * Create vendor and bank records for Extensity invoices with no existing supplier records.                     |
-- |  * Populates the terms date with the receipt date for TDM Expense PO invoices                                   |
-- |  * Translates the Project Numbers and Task Numbers to Project ID and Task ID.                                   |
-- |  * Builds invoice details from PO distribution line for the TDM PO invoices without any detail lines.           |
-- |  * Translates legacy GL account codes to Oracle GL account codes                                                |
-- |  * Import records from Invoice staging tablesto AP interface tables                                             |
--       * Translates Project Numbers, Task Numbers and Expenditure Org Name to Project ID,                          |
-- |    Task ID, Expenditure Org ID, Terms and Tax Codes for each invoice lines in                                   |
-- |  RICE : I0013                                                                                                   |
-- |Change Record:                                                                                                   |
-- |===============                                                                                                  |
-- |Version   Date              Author              Remarks                                                          |
-- |======   ==========     =============        =======================                                             |
-- |1.0       26-MAY-2007   Stedfield Thomas        Initial version                                                  |
-- |1.1       17-AUG-2007   Anamitra Banerjee       Populated attribute7 on Invoice Headers with Source              |
-- |1.2       18-SEP-2007   Greg Dill               Changes for defect IDs 1900 and 2023                             |
-- |1.3       21-SEP-2007   Agnes Poornima M        Updated XX_AP_CREATE_PO_INV_LINES for Defect # 2021 and 1936     |
-- |1.4       24-SEP-2007   Greg Dill               Changes for defect IDs 1900                                      |
-- |1.5       26-SEP-2007   Sandeep Pandhare        Changes for defect IDs 2102 - Populate Tax_code                  |
-- |1.6       27-SEP-2007   Sandeep Pandhare        Changes for defect IDs 2109 - Create TAX line for RETAIL LEASE   |
-- |1.7       08-Oct-2007   Sandeep Pandhare        Changes for defect IDs 2103 - Update Control Totals              |
-- |1.8       09-OCT-2007   Chaitanya Nath.G        Changed as per the defect ID 1936                                |
-- |1.9       15-OCT-2007   Chaitanya Nath.G        Changed as per the Defect Id 2410                                |
-- |1.10      15-OCT-2007   Sandeep Pandhare        Changed as per the Defect Id 2326                                |
-- |1.11      15-OCT-2007   Sandeep Pandhare        Changed as per the Defect Id 2428                                |
-- |1.12      17-OCT-2007   Sandeep Pandhare        Changed as per the Defect Id 2362                                |
-- |1.13      19-OCT-2007   Greg Dill               Changes for defect ID 2366                                       |
-- |1.14      21-OCT-2007   Sandeep Pandhare        Changes for defect ID 2053                                       |
-- |1.15      23-OCT-2007   Sandeep Pandhare        Changes for defect ID 2491                                       |
-- |1.15      18-DEC-2007   Sandeep Pandhare        Changes for defect ID 3087                                       |
-- |1.16      15-JAN-2008   Sandeep Pandhare        Defect-3527 Missing ORG Id for Extensity Interface               |
-- |1.17      18-JAN-2008   Prakash Sankaran        Defect 3681 - Performance problems on GL_CODE_COMBINATIONS       |
-- |1.18      21-JAN-2008   Greg Dill               Re-incorporated changes for defect ID 1900                       |
-- |1.19      06-FEB-2008   Greg Dill               Changes for defect ID 3973 - using passed expenditure type if one|
--                                                  exists, otherwise lookup GL account default.                     |
--                                                  Fixed GL account flex lookup loop issue.                         |
-- |1.20      12-FEB-2008   Greg Dill               Changes for defect ID 3973 - reset variables within Project loop |
-- |1.21      13-FEB-2008   Aravind A.              Changes for defect 3845 called package to build voucher for Non  |
-- |                                                PO lines as part of CR#326                                       |
-- |1.22      03-MAR-2008   Aravind A.              Fixed defect 4998 called the package to build voucher for non PO |
-- |                                                lines for all sources as part of CR#354                          |
-- |1.23      17-MAR-2008   Aravind A.              Changes for defect 5000                                          |
-- |1.24      20-MAR-2008   Sandeep Pandhare        Defect 5600 For Invalid location and missing company, pass the   |
-- |                                                invalid distribution to Open Interface tables.                   |    
-- |1.25      08-APR-2008   Sandeep Pandhare        Defect 6024 Modify Cost Center for certain Accounts              |
-- |1.26      18-APR-2008   Sandeep Pandhare        Defect 6028 Performance Tuning                                   |
-- |1.27      8-MAY-2008   Sandeep Pandhare         CR 388 Defect 6682 POET changes                                  |
-- |1.28      3-June-2008   Sandeep Pandhare        Defect 7592                                                      |
-- |1.28      7-June-2008   Sandeep Pandhare        Defect 7746 - EDI Expense Invoices                               |
-- |1.29      9-June-2008   Sandeep Pandhare        Defect 7841 - Retail Lease Changes                               | 
-- |1.30      27-Jun-2008   Sandeep Pandhare        Defect 6553 - Garnishment Change                                 | 
-- |1.31      07-Aug-2008   Sandeep Pandhare        Defect 9600 - Remove Default Dates                               | 
-- |1.32      16-Aug-2008   Sandeep Pandhare        Defect 9909 - Map po_number to global_attribute12                | 
-- |1.33      19-Aug-2008   Sandeep Pandhare        Defect 9971 - Extensity - employee# same as supplier number.     | 
-- |1.34      27-Aug-2008   Sandeep Pandhare        Defect 10194 - Extensity - Project Number to Global Attribute11  | 
-- |1.35      05-SEP-2008   Sandeep Pandhare        Defect 10805 - Extensity - AMEX data not being loaded            | 
-- |1.35      16-SEP-2008   Sandeep Pandhare        Defect 11205 - Blank Global Attribute11 for non Extensity source | 
-- |1.36      23-SEP-2008   Sandeep Pandhare        Defect 11307 - Added log statements for Extensity 11307          | 
-- |1.37      14-OCT-2008   Joe Klein               Defect 11880 - Don't print output header lines if no detail lines|
-- |1.38      21-NOV-2008   Joe Klein               Defect 12231 - Only execute XX_AP_PROCESS_REASON_CD proc for     |
-- |                                                SOURCE = 'US_OD_TRADE_EDI.  This is to prevent contention and    |
-- |                                                deadlocking for other sources with the same batch id.            |
-- |1.39      18-DEC-2008   Joe Klein               Defect 12231 - Backed out changes in previous update, version    |
-- |                                                1.38.  Made additional changes to XX_AP_PROCESS_REASON_CD proc   |
-- |                                                adding source code as an inbound parameter.                      |
-- |                                                1) Only open cursor 'get_discount_amt_info' if source_cd =       |
-- |                                                   'US_OD_TRADE_EDI'.                                            |
-- |                                                2) Added p_source (source_cd) to cursor                          |
-- |                                                   'updt_chargeback_invoices' to prevent contention when other   |
-- |                                                   sources are running concurrently.                             | 
-- |1.40     03-JUL-2009     Peter Marco            Defect 437   -  Employee "Supplier site ID" in                   |
-- |                                                            the supplier file is not maching with the            |
-- |                                                             "Supplier match id"                                 |
-- |1.50     09-JUL-2009     Ranjith T              Changes for Prod defect 622                                      |
-- |1.55     13-JUL-2009     Peter Marco            Added Decode statement per defect 444 Attribute10 null for       |
-- |                                                Extensity invoices                                               |   
-- |1.60     02-AUG-2010     Peter Marco	    AP - E1281 / E1282 (CR-729) - TDM Invoice Build - Report             | 
-- |                                                corrections and Ability to manage Invoices w/ issues 	         |
-- |1.65                                                                                                             |
-- |1.70     21-SEP-2011     Peter Marco            CR894 Pcard (Application changes)                                |
-- |1.75     29-SEP-2011     Peter Marco            CR894 Pcard defects 14094,14901                                  |
-- |2.00     04-OCT-2011     Peter Marco            CR894 Pcard defects 14096                                        |
-- |2.10     27-OCT-2011     Peter Marco            CR894 PCard defect 14767                                         |
-- |2.15     14-FEB-2012     Abdul Khan             QC Defect 15689 - Performance issue while running the program    |
-- |                                                during month end. Use XX_GL_CODE_COMBINATIONS_N8 index           |
-- |2.2      19-JUN-2012     Paddy Sanjeevi         Defect 19041                                                     |
-- |2.3      01-AUG-2012     Sinon Perlas           Defect 19421                                                     |
-- |2.4      19-SEP-2012     Paddy Sanjeevi         Defect 19205                                                     |
-- |2.5      04-JUN-2013     Darshini Gangadhar     I0013 - Modified for R12 Upgrade Retrofit                        |
-- |2.6      18-SEP-2013     Darshini Gangadhar     I0013 - Modified to change payment_method_lookup_code to         |
-- |                                                payment_method_code                                              |
-- |2.7      08-Oct-2013     Paddy Sanjeevi	        Added OTM Retrofit for R12                                       |
-- |2.8      18-Dec-2013     Paddy Sanjeevi         Added prorate_across_flag for Tax line (Defect 25144)            |
-- |2.9      17-Jan-2013     Paddy Sanjeevi         Added for Defect 25382                                           |
-- |2.9      26-Feb-2014     Darshini               Added for Defect 28446                                           |
-- |2.10     06-Oct-2014     Paddy Sanjeevi         Defect 31882                                                     |
-- |2.11     04-Jun-2015     Harvinder Rakhra       Defect 33354                                                     |
-- |2.12     17-Nov-2015     Harvinder Rakhra       Retrofit R12.2                                                   |
-- |2.13     30-Mar-2017     Havish Kasina          Added for the AP Trade Match                                     |
-- |2.14     04-Oct-2017     Havish Kasina          Added the logic to update the EDI and TDM sources if the PO is   |
-- |                                                Dropship then updating the source to DROPSHIP                    |
-- |2.15     20-Oct-2017     Havish Kasina          Added the logic to identify the miscellaneous created for the    |
-- |                                                Distribution Variance Tolerance                                  |
-- |2.16     03-Nov-2017     Havish Kasina          Populating the Reason code value in the Attribute11 in the lines |
-- |                                                staging table                                                    |
-- |2.17     14-Nov-2017     Havish Kasina          If PO is Dropship then create the Miscellaneous line with Reason |
-- |                                                Code DV. Else GV reason code                                     |
-- |2.18     21-Dec-2017     Havish Kasina          Added the UNIT_OF_MEAS_LOOKUP_CODE field in the insert statement |
-- |                                                for AP_INVOICE_LINES_INTERFACE table                             |
-- |2.19     15-Mar-2018     Havish Kasina          Commented the debug messages                                     |
-- |2.20     16-Apr-2018     Havish Kasina          Added the NVL(ld_terms_date,invoices_updt.invoice_date)          |
-- |2.21     12-DEC-2018     Vivek Kumar            Added logic to include DL for Duplicate Invoice for NAIT-51088	 | 
-- |3.0      03-MAR-2019     Vivek Kumar            Modified for NAIT-82494
-- +=================================================================================================================+

PROCEDURE XX_AP_OTM_UPDATE(p_group_id IN VARCHAR2)
IS

ln_batch_id NUMBER;

BEGIN

  SELECT XX_AP_INV_BATCH_INTFC_STG_S.nextval 
    INTO ln_batch_id
    FROM dual;      

  UPDATE xx_ap_inv_interface_stg
     SET batch_id=ln_batch_id
   WHERE RTRIM (SOURCE) = 'US_OD_OTM'
     AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL)
     AND external_doc_ref IS NULL
     AND global_attribute16 IS NULL;

  IF SQL%FOUND THEN
     BEGIN
       INSERT 
         INTO XX_AP_INV_BATCH_INTERFACE_STG
	     (batch_id,
	      creation_date)
       VALUES 
  	     (ln_batch_id,
	      SYSDATE);
     EXCEPTION
       WHEN others THEN
	 fnd_file.put_line(fnd_file.LOG,'Unable to insert record in xx_ap_inv_batch_interface_stg for OTM Invoice');
     END;
  END IF;
  COMMIT;
EXCEPTION
  WHEN others THEN
    fnd_file.put_line(fnd_file.LOG,'When others in xx_ap_otm_update : '||SQLERRM);
END XX_AP_OTM_UPDATE;

-- Added for the AP Trade match
-- +===================================================================+
-- | Name        : xx_insert_ap_tr_match_excepns                       |
-- |                                                                   |
-- | Description : This procedure is used to insert the exception      |
-- |               records into staging table XX_AP_TR_MATCH_EXCEPTIONS|                       
-- |                                                                   |
-- +===================================================================+
PROCEDURE XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            IN  number,
                                        p_invoice_num           IN  varchar2,
                                        p_vendor_id             IN  number ,
                                        p_vendor_site_id        IN  number ,
		                                p_invoice_line_id       IN  number ,
		                                p_invoice_line_num      IN  number ,
		                                p_po_num                IN  varchar2,
		                                p_po_header_id          IN  number,
		                                p_po_line_id            IN  number,
		                                p_po_line_num           IN  number,
		                                p_exception_code        IN  varchar2,
		                                p_exception_description IN  varchar2,
		                                p_process_flag          IN  varchar2
										)
IS
     ln_user_id    NUMBER := FND_GLOBAL.USER_ID;
	 ln_login_id   NUMBER := FND_GLOBAL.LOGIN_ID;
BEGIN
  -- Inserting the records into XX_AP_TR_MATCH_EXCEPTIONS table for Trade Match Exceptions
    INSERT INTO XX_AP_TR_MATCH_EXCEPTIONS(INVOICE_ID ,
                                          INVOICE_NUM ,
										  VENDOR_ID ,
										  VENDOR_SITE_ID ,
										  INVOICE_LINE_ID ,
										  INVOICE_LINE_NUM ,
										  PO_NUM ,
										  PO_HEADER_ID ,
										  PO_LINE_ID ,
										  PO_LINE_NUM ,
										  EXCEPTION_CODE ,
										  EXCEPTION_DESCRIPTION ,
										  PROCESS_FLAG ,
										  CREATION_DATE ,
										  CREATED_BY ,
										  LAST_UPDATED_BY ,
										  LAST_UPDATE_LOGIN ,
										  LAST_UPDATE_DATE
										  )
								VALUES   (p_invoice_id ,
                                          p_invoice_num ,
                                          p_vendor_id ,
                                          p_vendor_site_id ,
		                                  p_invoice_line_id ,
		                                  p_invoice_line_num ,
		                                  p_po_num ,
		                                  p_po_header_id ,
		                                  p_po_line_id ,
		                                  p_po_line_num ,
		                                  p_exception_code ,
		                                  p_exception_description ,
		                                  p_process_flag ,
										  SYSDATE,             --creation_date
                                          ln_user_id,          --created_by 
										  ln_user_id,          --last_updated_by
										  ln_login_id,         --last_update_login
                                          SYSDATE             --last_update_date                                          
                                          );
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
	   fnd_file.put_line(fnd_file.log,'Insert into XX_AP_TR_MATCH_EXCEPTIONS table for Trade Match Excetpions : '||SQLERRM); 
END;

-- +===================================================================+
-- | Name        : xx_ap_latest_received_date                          |
-- |                                                                   |
-- | Description : This procedure is used to get the latest received   |
-- |               date                                                |                       
-- |                                                                   |
-- +===================================================================+
PROCEDURE XX_AP_LATEST_RECEIVED_DATE(p_po_num                 IN   VARCHAR2,
                                     p_invoice_num            IN   VARCHAR2,
                                     o_latest_received_date   OUT  DATE)
IS
--Get the latest_received_date using the following query
BEGIN
    o_latest_received_date := NULL;
    SELECT TO_DATE(a.attribute1,'MM/DD/YY')
	  INTO o_latest_received_date
      FROM rcv_shipment_headers a
     WHERE a.shipment_header_id IN ( SELECT MAX(shipment_header_id)
		                               FROM  rcv_shipment_lines RSL
			                                ,po_line_locations_all PLL
			                                ,po_lines_all PL
			                                ,po_headers_all PH
			                                ,xx_ap_inv_lines_interface_stg  LINES
			                                ,xx_ap_inv_interface_stg HDR
		                              WHERE HDR.invoice_num = p_invoice_num 
		                                AND LINES.invoice_id = HDR.invoice_id
		                                AND LINES.line_type_lookup_code = 'ITEM'
		                                AND ph.segment1 = hdr.po_number
		                                AND pl.po_header_id = ph.po_header_id
		                                AND PL.line_num = LINES.po_line_number
		                                AND PLL.po_line_id = PL.po_line_id 
		                                AND NVL(PLL.inspection_required_flag,'N') = 'N'
		                                AND PLL.receipt_required_flag = 'Y'
		                                AND RSL.po_header_id = pl.po_header_id
		                                AND RSL.po_line_id = pl.po_line_id);
		   		   	
EXCEPTION
	WHEN OTHERS 
	THEN
	   o_latest_received_date := NULL;
END;

-- +===================================================================+
-- | Name        : xx_ap_tr_terms_date                                 |
-- |                                                                   |
-- | Description : This procedure is used to get the terms date, goods |
-- |               received date and invoice received date             |                       
-- |                                                                   |
-- +===================================================================+						
PROCEDURE XX_AP_TR_TERMS_DATE ( p_invoice_num            IN  VARCHAR2,
                                p_invoice_id             IN  NUMBER,
                                p_sup_site_terms_basis   IN  VARCHAR2,
								p_match_type             IN  VARCHAR2,
								p_drop_ship_flag         IN  VARCHAR2,
								p_po_num                 IN  VARCHAR2,
								p_invoice_date           IN  DATE,
								p_inv_creation_date      IN  DATE,
								p_terms_date             OUT DATE,
								p_goods_received_date    OUT DATE,
								p_invoice_received_date  OUT DATE
							   )
IS
  ld_latest_received_date   DATE;
  ld_invoice_date           DATE;
  ld_invoice_creation_date  DATE;
BEGIN
  ld_latest_received_date  := NULL;
  ld_invoice_date          := p_invoice_date;
  ld_invoice_creation_date := p_inv_creation_date;
  
      --fnd_file.put_line(fnd_file.log,'invoice_num :'||p_invoice_num);
	  --fnd_file.put_line(fnd_file.log,'Supplier Site Terms Basis :'||p_sup_site_terms_basis);
	  --fnd_file.put_line(fnd_file.log,'Match Type :'||p_match_type);
	  --fnd_file.put_line(fnd_file.log,'Drop Ship Flag :'||p_drop_ship_flag);
	  --fnd_file.put_line(fnd_file.log,'PO Number :'||p_po_num);
	  --fnd_file.put_line(fnd_file.log,'Invoice Date :'||p_invoice_date);
	  --fnd_file.put_line(fnd_file.log,'Invoice Creation Date :'||p_inv_creation_date);
  
	-- To get the Terms Date, Goods Received Date and Invoice received date
	-- Scenarios 1 and 2
	
	  IF ( p_match_type = '3-Way'
		   AND p_sup_site_terms_basis = 'Goods Received'
		   AND p_drop_ship_flag = 'N')
	  THEN
	  
	    --fnd_file.put_line(fnd_file.log,'5. E1281 ');
		 -- To get the latest received date
		 XX_AP_LATEST_RECEIVED_DATE(p_po_num                 =>  p_po_num,
		                            p_invoice_num            =>  p_invoice_num,
                                    o_latest_received_date   =>  ld_latest_received_date);
		 
		 IF  ld_latest_received_date IS NOT NULL -- If Receipt exists
		 THEN		     
		    p_terms_date             := ld_latest_received_date;
			p_goods_received_date    := ld_latest_received_date;
			p_invoice_received_date  := ld_invoice_creation_date;
			
		 ELSE -- If Receipt does not exist
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := NULL;
			p_invoice_received_date  := ld_invoice_creation_date;
	     
			XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => NULL,
										  p_invoice_num           => p_invoice_num,
										  p_vendor_id             => NULL ,
										  p_vendor_site_id        => NULL,
										  p_invoice_line_id       => NULL,
										  p_invoice_line_num      => NULL,
										  p_po_num                => p_po_num,
										  p_po_header_id          => null,
										  p_po_line_id            => null,
										  p_po_line_num           => null,
										  p_exception_code        => 'H001',
										  p_exception_description => 'NO Receipt Exists for the Invoice :'|| p_invoice_num||' '||'and PO :'||p_po_num ,
										  p_process_flag          => 'N'
										 );
		 END IF;
		 
	-- Scenarios 3 and 4	 
	  ELSIF  ( p_match_type = '3-Way'
		       AND p_sup_site_terms_basis = 'Invoice'
		       AND p_drop_ship_flag = 'N')
	     THEN
		    -- fnd_file.put_line(fnd_file.log,'6. E1281 ');
		 -- To get the latest received date
		 XX_AP_LATEST_RECEIVED_DATE(p_po_num                 =>  p_po_num,
		                            p_invoice_num            =>  p_invoice_num,
                                    o_latest_received_date   =>  ld_latest_received_date);
		 
		 IF  ld_latest_received_date IS NOT NULL -- If Receipt exists
		 THEN		     
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := ld_latest_received_date;
			p_invoice_received_date  := ld_invoice_creation_date;
			
		 ELSE -- If Receipt does not exist
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := NULL;
			p_invoice_received_date  := ld_invoice_creation_date;
	     
			XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => NULL,
										  p_invoice_num           => p_invoice_num,
										  p_vendor_id             => NULL ,
										  p_vendor_site_id        => NULL,
										  p_invoice_line_id       => NULL,
										  p_invoice_line_num      => NULL,
										  p_po_num                => p_po_num,
										  p_po_header_id          => null,
										  p_po_line_id            => null,
										  p_po_line_num           => null,
										  p_exception_code        => 'H001',
										  p_exception_description => 'NO Receipt Exists for the Invoice :'|| p_invoice_num||' '||'and PO :'||p_po_num ,
										  p_process_flag          => 'N'
										 );
	     END IF;
		 
	-- Scenario 5		  
	    ELSIF  (p_match_type = '2-Way'
		        AND p_sup_site_terms_basis = 'Goods Received'
		        AND p_drop_ship_flag IN ('N','Y')
			    )
	     THEN
             -- fnd_file.put_line(fnd_file.log,'7. E1281 ');
	         p_terms_date             := ld_invoice_date;
			 p_goods_received_date    := NULL;
			 p_invoice_received_date  := ld_invoice_creation_date;
		 
	-- Scenario 6
	 ELSIF  ( p_match_type = '2-Way'
		      AND p_sup_site_terms_basis = 'Invoice'
		      AND p_drop_ship_flag IN ('N','Y')
			)
	     THEN
             -- fnd_file.put_line(fnd_file.log,'8. E1281 ');
	         p_terms_date             := ld_invoice_date;
			 p_goods_received_date    := NULL;
			 p_invoice_received_date  := ld_invoice_creation_date;
	 ELSE
            p_terms_date             := p_invoice_date;
	        p_goods_received_date    := NULL;
	        p_invoice_received_date  := NULL;
	 END IF;
	 
	 --fnd_file.put_line(fnd_file.log,'Terms Date :'||p_terms_date);
	 --fnd_file.put_line(fnd_file.log,'Goods Received Date :'||p_goods_received_date);
	 --fnd_file.put_line(fnd_file.log,'Invoice Received Date :'||p_invoice_received_date);

EXCEPTION
  WHEN OTHERS 
  THEN
       --fnd_file.put_line(fnd_file.log,'9. E1281 ');
       p_terms_date             := p_invoice_date;
	   p_goods_received_date    := NULL;
	   p_invoice_received_date  := NULL;
	   --fnd_file.put_line(fnd_file.log,'Terms Date :'||p_terms_date);
	   --fnd_file.put_line(fnd_file.log,'Goods Received Date :'||p_goods_received_date);
	   --fnd_file.put_line(fnd_file.log,'Invoice Received Date :'||p_invoice_received_date);
	   fnd_file.put_line(fnd_file.log,'Unable to get the Terms Date, Goods Received Date and Invoice Received Date :'||SQLERRM);
		
END XX_AP_TR_TERMS_DATE;
	   
 
-- +===================================================================+
-- | Name        : xx_ap_otm_invoice                                   |
-- |                                                                   |
-- | Description : This procedure is used to process invoices from OTM |
-- |               in the ap invoice staging tables                    |                       
-- |                                                                   |
-- | Parameters  : p_source, p_group_id                                |
-- |                                                                   |
-- | Returns     : None                                                |
-- +===================================================================+
PROCEDURE XX_AP_OTM_INVOICE(p_source IN VARCHAR2,p_group_id IN VARCHAR2)
IS

CURSOR c1 (p_source     IN       VARCHAR2,
           p_group_id   IN       VARCHAR2
          )
IS
SELECT *
  FROM xx_ap_inv_interface_stg
 WHERE RTRIM (SOURCE) = p_source
   AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL)
   AND external_doc_ref IS NULL
   AND global_attribute16 IS NULL;

CURSOR c2 (p_invoice_id IN NUMBER)
IS
SELECT b.invoice_num,
       b.invoice_id,
       b.invoice_date,
       b.source, 
       a.line_number, 
       a.invoice_line_id,
       UPPER (NVL (a.line_type_lookup_code, 'ITEM')) line_type_lookup_code,
       a.line_group_number,           
       a.amount, 
       a.accounting_date, 
       a.description,
       a.prorate_across_flag,
       a.dist_code_concatenated, 
       a.dist_code_combination_id,
       a.external_doc_line_ref, 
       a.legacy_segment2,
       a.legacy_segment3,
       a.legacy_segment4,
       a.GLOBAL_ATTRIBUTE11
  FROM xx_ap_inv_lines_interface_stg a,
       xx_ap_inv_interface_stg b
 WHERE a.invoice_id = b.invoice_id
   AND a.invoice_id = p_invoice_id
   AND a.external_doc_line_ref IS NULL
   AND a.global_attribute16 IS NULL;


 v_company 			 VARCHAR2(150);
 v_lob	    			 VARCHAR2(150);
 v_location_type		 VARCHAR2(150);
 v_cost_center_type		 VARCHAR2(150);

 v_intercompany                  gl_code_combinations.segment5%TYPE:='0000';
 v_future                        gl_code_combinations.segment7%TYPE := '000000';
 v_user_id                       NUMBER:= NVL (fnd_profile.VALUE ('USER_ID'), 0);
 v_vendor_site_id                NUMBER;
 v_vendor_id                     NUMBER;
 v_org_id                        po_vendor_sites_all.org_id%TYPE;
 v_count                         NUMBER;
 v_terms_id			 NUMBER;
 v_payment_method		 VARCHAR2(25);
 v_pay_group_lookup		 VARCHAR2(25);

 v_full_gl_code                  VARCHAR2 (2000);
 v_ccid                          NUMBER;
 lc_coa_id                       gl_sets_of_books_v.chart_of_accounts_id%TYPE;
 lc_error_flag                   VARCHAR2 (1)   := 'N';
 lc_error_loc                    VARCHAR2 (2000);
 lc_loc_err_msg                  VARCHAR2 (2000);
 v_cnt				 NUMBER:=0;

BEGIN

SELECT COUNT(1)
  INTO v_cnt
  FROM xx_ap_inv_interface_stg
 WHERE RTRIM (SOURCE) = p_source
   AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL)
   AND external_doc_ref IS NULL
   AND global_attribute16 IS NULL;

IF v_cnt>0 THEN
  
  FOR cur IN C1(p_source,p_group_id)
  LOOP

    v_vendor_id 	:= NULL;
    v_vendor_site_id 	:= NULL;
    v_org_id 		:= NULL;
    v_terms_id		:= NULL;
    v_payment_method	:= NULL;
    v_pay_group_lookup	:= NULL;

    BEGIN
      SELECT b.vendor_site_id, a.vendor_id, b.org_id,b.terms_id, b.payment_method_lookup_code, b.pay_group_lookup_code
        INTO v_vendor_site_id, v_vendor_id, v_org_id, v_terms_id, v_payment_method, v_pay_group_lookup
        FROM ap_supplier_sites_all b,
  	     ap_suppliers a
       WHERE a.segment1=cur.vendor_num
         AND a.end_date_active IS NULL
         AND b.vendor_id=a.vendor_id
	 AND b.vendor_site_code=cur.vendor_site_code
         AND b.pay_site_flag='Y'
	 AND (b.inactive_date IS NULL OR b.inactive_date>SYSDATE);
    EXCEPTION
      WHEN OTHERS THEN
        lc_error_loc := 'Error deriving the vendor / vendor site id';
        fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_NO_VENDOR ');
        fnd_message.set_token ('ERR_LOC', lc_error_loc);
        fnd_message.set_token ('ERR_DEBUG','Vendor No : '||cur.vendor_num||','||cur.vendor_site_code);
        fnd_message.set_token ('ERR_ORA', SQLERRM);
        lc_loc_err_msg := fnd_message.get;
        fnd_file.put_line (fnd_file.LOG, '*** Unable to derive Vendor and Vendor Site Id :'||cur.vendor_num||','||cur.vendor_site_code);
        xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound OTM invoices'
                            );
    END;
    BEGIN
      INSERT 
        INTO ap_invoices_interface
                (invoice_id,
                 invoice_num,
                 invoice_type_lookup_code,
                 invoice_date,
	         vendor_id,
                 vendor_site_id,
                 invoice_amount,
                 invoice_currency_code,
                 terms_id,
                 description, 
		 last_update_date, 
		 last_updated_by,
                 last_update_login, 
		 creation_date, 
		 created_by,
                 attribute_category,
                 attribute7,
                 attribute10,
                 attribute11,
		 SOURCE,
                 GROUP_ID,
                 payment_method_lookup_code,
                 pay_group_lookup_code,
                 org_id,
                 vendor_email_address,
                 external_doc_ref,
		 goods_received_date
                )
         VALUES 
		(
		 cur.invoice_id,
                 cur.invoice_num, 
                 cur.invoice_type_lookup_code,
                 NVL (cur.invoice_date, SYSDATE),
                 v_vendor_id, 
                 v_vendor_site_id,
                 cur.invoice_amount,
                 'USD',
                 v_terms_id,
                 cur.description, 
		 SYSDATE,
                 v_user_id,
                 NULL,              --last_update_login
                 SYSDATE,           --creation_date
                 v_user_id,         --created_by
                 cur.attribute_category,
                 cur.source,
                 cur.attribute10,
                 cur.attribute11,
		 cur.source,
                 cur.GROUP_ID,
		 v_payment_method, 
		 v_pay_group_lookup,
		 v_org_id,
                 cur.vendor_email_address,
                 cur.external_doc_ref,
		 NVL (cur.invoice_date, SYSDATE)
                );
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_INTERFACE '||SQLERRM);   
        lc_error_loc := 'Unable to insert Invoice ap_invoices_interface';
        fnd_message.set_name ('XXFIN',' XX_AP_0004_ERROR_NO_INSERT_HEADER ');
        fnd_message.set_token ('ERR_LOC', lc_error_loc);
        fnd_message.set_token ('ERR_DEBUG', 'Invoice/Vendor/Site : '|| cur.invoice_num||','||cur.vendor_num||','||cur.vendor_site_code);
        fnd_message.set_token ('ERR_ORA', SQLERRM);
        lc_loc_err_msg := fnd_message.get;
        fnd_file.put_line (fnd_file.LOG,  'Unable to insert Header for Invoice/Vendor/Site : '|| cur.invoice_num||','||cur.vendor_num||','||cur.vendor_site_code);
        xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound OTM invoices'
                            );
    END;
    ------------------------------------------------------
    -- Updates invoice header records that are processed --
    ------------------------------------------------------
    UPDATE xx_ap_inv_interface_stg
       SET global_attribute16 = 'PROCESSED'
     WHERE invoice_id = cur.invoice_id;
  
    FOR cr IN c2(cur.invoice_id)
    LOOP

      v_company 		:=NULL;
      v_location_type		:=NULL;
      v_cost_center_type	:=NULL;
      v_lob	    		:=NULL;

      BEGIN
        SELECT ffv.attribute1,
               ffv.attribute2
          INTO v_company, 
               v_location_type
          FROM fnd_flex_values ffv,
               fnd_flex_value_sets vs	
         WHERE vs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
           AND ffv.flex_value_set_id=vs.flex_value_set_id
           AND ffv.flex_value=cr.legacy_segment4
           AND ffv.enabled_flag='Y';
      EXCEPTION 
         WHEN others THEN
           fnd_file.put_line (fnd_file.LOG,'Unable to derive company for the location :'||cr.legacy_segment4);	
           xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at deriving company for location',
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => 'Error at deriving company for location : '||cr.legacy_segment4,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound OTM invoices'
                            );
      END;

	BEGIN
        SELECT ffv.attribute1
          INTO v_cost_center_type
          FROM fnd_flex_values ffv,
               fnd_flex_value_sets vs	
         WHERE vs.flex_value_set_name='OD_GL_GLOBAL_COST_CENTER'
           AND ffv.flex_value_set_id=vs.flex_value_set_id
           AND ffv.flex_value=cr.legacy_segment2
           AND ffv.enabled_flag='Y';
      EXCEPTION 
         WHEN others THEN
	     fnd_file.put_line (fnd_file.LOG,'Unable to derive cost center type for the Cost Center :'||cr.legacy_segment2);	
           xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at deriving CC type for cost center',
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => 'Error at deriving CC type for cost center : '||cr.legacy_segment2,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound OTM invoices'
                            );
      END;

	BEGIN
        SELECT tv.target_value1
	    INTO v_lob
          FROM xx_fin_translatevalues tv,
	         xx_fin_translatedefinition td
         WHERE td.translation_name = 'GL_COSTCTR_LOC_TO_LOB'
           AND td.enabled_flag = 'Y'
           AND (td.start_date_active <= TRUNC(SYSDATE)
           AND (td.end_date_active >= TRUNC(SYSDATE) OR td.end_date_active IS NULL))
           AND tv.translate_id=td.translate_id
           AND tv.source_value1=v_cost_center_type
           AND tv.source_value2=v_location_type
           AND tv.enabled_flag          = 'Y'
           AND (tv.start_date_active   <= TRUNC(SYSDATE)
           AND (tv.end_date_active     >= TRUNC(SYSDATE) OR tv.end_date_active IS NULL));
      EXCEPTION 
        WHEN others THEN
          fnd_file.put_line (fnd_file.LOG,'Unable to derive LOB the CC TYPE/LOC TYPE :'||v_cost_center_type||','||v_location_type);	
          xx_com_error_log_pub.log_error
                   (p_program_type           => 'CONCURRENT PROGRAM',
                    p_program_name           => 'XXAPINVINTFC',
                    p_module_name            => 'AP',
                    p_error_location         => 'Error at deriving LOB ',
                    p_error_message_count    => 1,
                    p_error_message_code     => 'E',
                    p_error_message          => 'Error at deriving LOB for location/cc type : '||v_cost_center_type||','||v_location_type,
                    p_error_message_severity => 'Major',
                    p_notify_flag            => 'N',
                    p_object_type            => 'Processing AP Inbound OTM invoices'
                   );
      END;
      BEGIN
        SELECT gsb.chart_of_accounts_id
          INTO lc_coa_id
          FROM gl_sets_of_books_v gsb
         WHERE gsb.set_of_books_id =fnd_profile.VALUE ('GL_SET_OF_BKS_ID'); 
      EXCEPTION
        WHEN others THEN
	    lc_coa_id:=NULL;
      END;

      v_full_gl_code :=v_company || '.'|| 
			     cr.legacy_segment2|| '.'||
			     cr.legacy_segment3|| '.'||
			     cr.legacy_segment4|| '.'||
			     v_intercompany|| '.'|| 
			     v_lob|| '.' ||
			     v_future;
      BEGIN
        SELECT /*+ INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */ 
     	         code_combination_id 
          INTO v_ccid
          FROM gl_code_combinations
         WHERE chart_of_accounts_id = lc_coa_id
           AND segment1 = v_company
           AND segment2 = cr.legacy_segment2 -- cost center
           AND segment3 = cr.legacy_segment3 -- account
           AND segment4 = cr.legacy_segment4 -- location
           AND segment5 = v_intercompany
           AND segment6 = v_lob
           AND segment7 = v_future
           AND enabled_flag='Y';
      EXCEPTION
        WHEN others THEN
	    v_ccid:=NULL;
          fnd_file.put_line (fnd_file.LOG,'Invalid code combinations from DIST_CODE_CONCATENATED');
          xx_com_error_log_pub.log_error
                   (p_program_type           => 'CONCURRENT PROGRAM',
                    p_program_name           => 'XXAPINVINTFC',
                    p_module_name            => 'AP',
                    p_error_location         => 'Error at deriving CCID',
                    p_error_message_count    => 1,
                    p_error_message_code     => 'E',
                    p_error_message          => 'Error at deriving CCID for Invoice No : '||cr.invoice_num||','|| v_full_gl_code,
                    p_error_message_severity => 'Major',
                    p_notify_flag            => 'N',
                    p_object_type            => 'Processing AP Inbound OTM invoices'
                   );
      END;
      BEGIN
	  INSERT 
	    INTO ap_invoice_lines_interface
               (invoice_id,
                invoice_line_id,
                line_number,
                line_type_lookup_code,
                amount,
                description,
                dist_code_concatenated,
                dist_code_combination_id, 
  	        last_updated_by,
                last_update_date,
                last_update_login,
                created_by,
                creation_date,
		org_id,
                global_attribute11   -- defect 10194
               )
	  VALUES
	       (cr.invoice_id,
                cr.invoice_line_id,
                cr.line_number,
                cr.line_type_lookup_code,
                cr.amount,
                cr.description,
                DECODE(v_full_gl_code, '....0000..000000', NULL, '.....000...00000....', null,v_full_gl_code), 
                v_ccid, 
	        v_user_id,          --last_updated_by
                SYSDATE,            --last_update_date
                NULL,               --last_update_login
                v_user_id,          --created_by
                SYSDATE,            --creation_date
                v_org_id,
                cr.global_attribute11   
               );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_LINES_INTERFACE '||SQLERRM);   
          lc_error_loc := 'Unable to insert invoice line.  ';
          fnd_message.set_name('XXFIN',' XX_AP_0005_ERROR_NO_INSERT_LINE ');
          fnd_message.set_token ('ERR_LOC', lc_error_loc);
          fnd_message.set_token ('ERR_DEBUG','Invoice/Line No : '||cur.invoice_num||','||TO_CHAR(cr.line_number));
          fnd_message.set_token ('ERR_ORA', SQLERRM);
          lc_loc_err_msg := fnd_message.get;
          fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
          xx_com_error_log_pub.log_error
                            (p_program_type                => 'CONCURRENT PROGRAM',
                             p_program_name                => 'XXAPINVINTFC',
                             p_module_name                 => 'AP',
                             p_error_location              => lc_error_loc,
                             p_error_message_count         => 1,
                             p_error_message_code          => 'E',
                             p_error_message               => lc_loc_err_msg,
                             p_error_message_severity      => 'Major',
                             p_notify_flag                 => 'N',
                             p_object_type                 => 'Processing AP Inbound OTM invoices'
                            );
      END;   
      -----------------------------------------------------
      -- Updates invoice line records that are processed --
      -----------------------------------------------------
      UPDATE xx_ap_inv_lines_interface_stg
         SET global_attribute16 = 'PROCESSED'
       WHERE invoice_line_id = cr.invoice_line_id;
    END LOOP;  --
  END LOOP;
  COMMIT;
ELSE
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception when others in XX_AP_OTM_INVOICE :'||SQLERRM);
END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No records found to process for the Source :'||p_source);
END XX_AP_OTM_INVOICE;

    --------------------------------------------
 -- Translate Project Number to Project ID --
 --------------------------------------------
   FUNCTION f_project_inbound (v_project_num_in IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      v_project_number   pa_projects_all.segment1%TYPE    := v_project_num_in;
      v_project_id       pa_projects_all.project_id%TYPE;
   BEGIN
      SELECT project_id
        INTO v_project_id
        FROM pa_projects_all
       WHERE (   segment1 = v_project_number
              OR (segment1 = v_project_num_in AND segment1 IS NULL)
             )
         AND enabled_flag = 'Y';
      RETURN v_project_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END f_project_inbound;
 --------------------------------------------------------------------------
-- Use  a combined Task Number and Project Number to derive the Task ID --
--------------------------------------------------------------------------
   FUNCTION f_task_inbound (
      v_task_num_in      IN   VARCHAR2 DEFAULT NULL,
      v_project_num_in   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      v_task_number      pa_tasks.task_number%TYPE         := v_task_num_in;
      v_project_number   pa_projects_all.segment1%TYPE    := v_project_num_in;
      v_task_id          pa_tasks.task_id%TYPE;
      v_project_id       pa_projects_all.project_id%TYPE;
   BEGIN
      SELECT a.task_id, a.project_id
        INTO v_task_id, v_project_id
        FROM pa_tasks a, pa_projects_all b
       WHERE     a.project_id = b.project_id
             AND (task_number = v_task_number AND segment1 = v_project_number
                 )
          OR     (task_number = v_task_num_in AND segment1 = v_project_num_in
                 )
             AND (task_number IS NULL AND segment1 IS NULL);
      RETURN v_task_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END f_task_inbound;
 -----------------------------------------------------------
-- Translate Expenditure Org Name to Expenditure Org ID --
-----------------------------------------------------------
   FUNCTION f_exp_org_name_inbound (v_exp_org_name_in IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      v_exp_org_name      pa_segment_value_lookups.segment_value%TYPE
                                                         := v_exp_org_name_in;
      v_organization_id   hr_organization_units_v.organization_id%TYPE;
   BEGIN
      SELECT a.organization_id
        INTO v_organization_id
        FROM hr_organization_units_v a, pa_segment_value_lookups b
       WHERE     a.NAME = b.segment_value_lookup
             AND b.segment_value_lookup_set_id =
                    (SELECT segment_value_lookup_set_id
                       FROM pa_segment_value_lookup_sets
                      WHERE segment_value_lookup_set_name =
                                              'EXPENDITURE ORG TO COST CENTER')
             AND ROWNUM = 1
             AND b.segment_value = v_exp_org_name
          OR (b.segment_value = v_exp_org_name_in AND b.segment_value IS NULL
             );
      RETURN v_organization_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END f_exp_org_name_inbound;
 --------------------------------------------------------------------------
-- Translate GL Account segment to populate the Expenditure Type column --
--------------------------------------------------------------------------
   FUNCTION f_exp_type_inbound (v_gl_account_in IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      v_gl_account         pa_segment_value_lookups.segment_value%TYPE
                                                           := v_gl_account_in;
      v_expenditure_type   pa_segment_value_lookups.segment_value_lookup%TYPE;
   BEGIN
      SELECT segment_value_lookup
        INTO v_expenditure_type
        FROM pa_segment_value_lookups
       WHERE     segment_value_lookup_set_id =
                    (SELECT segment_value_lookup_set_id
                       FROM pa_segment_value_lookup_sets
                      WHERE segment_value_lookup_set_name =
                                                 'EXPENDITURE TYPE TO ACCOUNT')
--             AND ROWNUM = 1  /* Defect 2362 - if you have multiple Expenditure Type then ignore it */
             AND segment_value = v_gl_account
          OR (segment_value = v_gl_account_in AND segment_value IS NULL);
      RETURN v_expenditure_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN TOO_MANY_ROWS
      THEN
         RETURN 'MULTIPLE';
      WHEN OTHERS
      THEN
      /* Defect 2362 - if you have multiple Expenditure Type then ignore it */
         RETURN NULL;
   END f_exp_type_inbound;
   PROCEDURE xx_ap_update_source (errbuff OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
   BEGIN
------------------------------
-- Update Invoice Sources   --
------------------------------
      fnd_file.put_line (fnd_file.LOG,
                         'Update Invoice sources in staging tables     '
                        );
      UPDATE xx_ap_inv_interface_stg
         SET SOURCE = 'US_OD_CONSIGNMENT_SALES'
       WHERE SOURCE = 'US_OD_CONSIGNMENT_SA';
      UPDATE xx_ap_inv_interface_stg
         SET SOURCE = 'US_OD_RTV_MERCHANDISING'
       WHERE SOURCE = 'US_OD_RTV_MERCHANDIS';
      UPDATE xx_ap_inv_interface_stg
         SET SOURCE = 'US_OD_RTV_CONSIGNMENT'
       WHERE SOURCE = 'US_OD_RTV_CONSIGNMEN';
      COMMIT;
   END xx_ap_update_source;
   PROCEDURE xx_ap_invoices_purge (
      errbuff      OUT      VARCHAR2,
      retcode      OUT      VARCHAR2,
      p_source     IN       VARCHAR2,
      p_group_id   IN       VARCHAR2
   )
   IS
   LN_PURGE_DAYS  NUMBER;   --added Per 729
   BEGIN
 ------------------------------
-- Purge duplicate invoices --
------------------------------
      fnd_file.put_line
                 (fnd_file.LOG,
                  'Purging processed duplicate records in staging tables     '
                 );
      BEGIN  
          DELETE FROM xx_ap_inv_batch_interface_stg
            WHERE batch_id IN (
                     SELECT DISTINCT batch_id
                                FROM xx_ap_inv_interface_stg
                               WHERE RTRIM (SOURCE) = p_source
                                 AND (GROUP_ID = p_group_id
                                      OR GROUP_ID IS NULL
                                     )
                                 AND external_doc_ref IS NOT NULL);
      END;
      -----------------------------------------------------------------------
      -- Bug discovered during CR729 tesing.  Staging tbl lines are not being 
      -- deleted correctly.  Moved deletion code for the
      -- xx_ap_inv_lines_interface_stg lines to be before the 
      -- xx_ap_inv_interface_stg records.
      ----------------------------------------------------------------------
      BEGIN
          DELETE FROM xx_ap_inv_lines_interface_stg
            where INVOICE_ID in (
                     SELECT invoice_id
                       FROM xx_ap_inv_interface_stg
                      WHERE RTRIM (SOURCE) = p_source
                        AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL))
              and EXTERNAL_DOC_LINE_REF is not null;
      END;         
      BEGIN        
          DELETE from XX_AP_INV_INTERFACE_STG
            WHERE RTRIM (SOURCE) = p_source
              and (GROUP_ID = P_GROUP_ID or GROUP_ID is null)
              and EXTERNAL_DOC_REF is not null;              
      END;
----------------------------------------
 -- Purge records that are XX day old --
 ----------------------------------------
-------------------------------------------------------------
-- Per CR729: added select from the fnd_lookup_values below.
-- OD_AP_INV_PURGE_STG_TABLE Lookup will contain sources that need
-- to be purged other then (default)30 days.  Ex. US_OD_TDM will
-- be purged 90 days. 
--------------------------------------------------------------
    BEGIN
      SELECT TO_NUMBER(MEANING) 
        INTO  LN_PURGE_DAYS
        FROM fnd_lookup_values_vl
       WHERE LOOKUP_TYPE = 'OD_AP_INV_PURGE_STG_TABLE'
         AND lookup_code = p_source;
    EXCEPTION
            WHEN NO_DATA_FOUND
             THEN
                  -- Purge default for source not in the 
                  -- OD_AP_INV_PURGE_STG_TABLE lookup
                  ln_purge_days := 30;
            WHEN OTHERS
              THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,
                       'Calling xx_ap_invoices_purge Proc ');              
                 FND_FILE.PUT_LINE(FND_FILE.LOG,
                       'Error: OD_AP_INV_PURGE_STG_TABLE Lookup '||SQLERRM);                
     END;
      FND_FILE.PUT_LINE (FND_FILE.LOG,
                         'Purging '||LN_PURGE_DAYS ||
                         ' day old records in staging tables: Source - '||
                         p_source
                        );
     BEGIN 
         DELETE from XX_AP_INV_BATCH_INTERFACE_STG
            WHERE batch_id IN (
                     SELECT DISTINCT batch_id
                                FROM xx_ap_inv_interface_stg
                               WHERE RTRIM (SOURCE) = p_source
                                 AND (GROUP_ID = p_group_id
                                      OR GROUP_ID IS NULL
                                     ))
              AND TRUNC (CREATION_DATE) 
                   < TRUNC (SYSDATE - LN_PURGE_DAYS); -- Added ln_purge_days 
                                                      -- variable per CR729
      END;
      -----------------------------------------------------------------------
      -- Bug discovered during CR729 tesing.  Staging tbl lines are not being 
      -- deleted correctly.  Moved deletion code for the
      -- xx_ap_inv_lines_interface_stg lines to be before the 
      -- xx_ap_inv_interface_stg records.
      ----------------------------------------------------------------------
       BEGIN
          DELETE FROM xx_ap_inv_lines_interface_stg
            where INVOICE_ID in (
                     SELECT invoice_id
                       FROM xx_ap_inv_interface_stg
                      WHERE RTRIM (SOURCE) = p_source
                        and (GROUP_ID = P_GROUP_ID or GROUP_ID is null))
              AND TRUNC (CREATION_DATE)
                   < TRUNC (sysdate - LN_PURGE_DAYS); -- Added ln_purge_days 
                                                      -- variable per CR729
       END;
       begin
          DELETE FROM xx_ap_inv_interface_stg
            WHERE RTRIM (SOURCE) = p_source
              and (GROUP_ID = P_GROUP_ID or GROUP_ID is null)
              AND TRUNC (CREATION_DATE) 
                       < TRUNC (SYSDATE - LN_PURGE_DAYS); -- Added ln_purge_days 
                                                          -- variable per CR729
       END; 
      COMMIT;
   END xx_ap_invoices_purge;
   PROCEDURE xx_ap_duplicate_invoices (
      errbuff      OUT      VARCHAR2,
      retcode      OUT      VARCHAR2,
      p_source     IN       VARCHAR2,
      p_group_id   IN       VARCHAR2
   )
   IS
      CURSOR c1 (
         errbuff      OUT      VARCHAR2,
         retcode      OUT      VARCHAR2,
         p_source     IN       VARCHAR2,
         p_group_id   IN       VARCHAR2
      )
      IS
         SELECT DISTINCT aps.vendor_name, b.invoice_num, aps.segment1, a.SOURCE,
                         a.GROUP_ID, a.invoice_id,
                         RTRIM (a.attribute10) attribute10,
                         a.vendor_email_address,
                         NVL (d.meaning, NULL) meaning
                    FROM xx_ap_inv_interface_stg a,
                         ap_invoices_all b,
						 -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
                         -- po_vendors c,
						 ap_suppliers aps,
						 -- end of addition
                         fnd_lookup_values_vl d
                   WHERE RTRIM (b.attribute10) = RTRIM (a.attribute10)
                     AND a.SOURCE = d.lookup_code
                     AND d.lookup_type = 'SOURCE'
                     AND a.SOURCE = p_source
                     AND (a.GROUP_ID = p_group_id OR a.GROUP_ID IS NULL)
                     AND a.invoice_num = b.invoice_num
                     AND b.vendor_id = aps.vendor_id
                     AND a.global_attribute16 IS NULL;
      -- denotes unprocessed invoice records
      v_count_invoices             NUMBER;
      cnt                          NUMBER := 0;
      v_email_address              VARCHAR2 (240);
      v_check_dup_invoice_exists   VARCHAR2 (1);
      l_request_id                 NUMBER;
      ln_main_prog_req_id          NUMBER        := fnd_global.conc_request_id;
      lc_error_loc                 VARCHAR2 (2000);
      lc_error_debug               VARCHAR2 (2000);
      lc_loc_err_msg               VARCHAR2 (2000);
	  lc_instance_name             VARCHAR2(30);	-- Added for NAIT-51088
	  lc_email_to                  VARCHAR2(2000);  -- Added for NAIT-51088
   BEGIN
      fnd_file.put_line
                       (fnd_file.LOG,
                        'Checking for duplicate invoices in staging tables   ' || SYSDATE
                       );
      FOR invoices_rec IN c1 (errbuff, retcode, p_source, p_group_id)
      LOOP
         BEGIN
            SELECT COUNT (1)
              INTO v_count_invoices
              FROM ap_invoices_all a
             WHERE a.attribute10 = invoices_rec.attribute10
               AND a.invoice_num = invoices_rec.invoice_num
               AND RTRIM (a.SOURCE) = p_source;
            IF v_count_invoices > 0
            THEN
               cnt := cnt + 1;
               IF cnt = 1
               THEN
			      ----Added For NAIT-82494 ----
				  fnd_file.put_line(fnd_file.output,
                                    'Source Name: '
					              || p_source
                  );
				  
                  fnd_file.put_line
                  (fnd_file.output,
                    '                                              Duplicate Invoices'
                  );
				  
                  fnd_file.put_line (fnd_file.output,
				             /*      RPAD('Vendor Source',32,' ')
                                  || ' '*/--Commented For NAIT-82494
                                     RPAD('Vendor Name',43, ' ')
                                  || ' '
                                  || 'Invoice Number'
                                 );
                  fnd_file.put_line
                  (fnd_file.output,
                    '=============================================================================================================='
                  );
                END IF;
               fnd_file.put_line (fnd_file.output,
                      /*             RPAD(invoices_rec.meaning,32,' ')
                                  || ' '*/ --COmmented For NAIT-82494
                                     RPAD(invoices_rec.vendor_name,43, ' ')
                                  || ' '
                                  || invoices_rec.invoice_num
                                 );
-------------------------------
-- Update duplicate invoices --
-------------------------------
               UPDATE xx_ap_inv_interface_stg
                  SET external_doc_ref = 'DUPLICATE INVOICE',
                      global_attribute16 = 'PROCESSED'
                WHERE invoice_id = invoices_rec.invoice_id;
               UPDATE xx_ap_inv_lines_interface_stg
                  SET external_doc_line_ref = 'DUPLICATE INVOICE',
                      global_attribute16 = 'PROCESSED'
                WHERE invoice_id = invoices_rec.invoice_id;
--               COMMIT;   defect 6028
            END IF;
         END;
--         COMMIT; defect 6028
      END LOOP;
      IF cnt > 0
               THEN
                 fnd_file.put_line
                 (fnd_file.output,
                 '=============================================================================================================='
                 );
      END IF;
         COMMIT;
		 /* Commented for NAIT-82494
 --------------------------------------------------
-- Submit the Concurrent Request Emailer program --
---------------------------------------------------
      BEGIN
         SELECT DISTINCT vendor_email_address, 'Y'
                    INTO v_email_address, v_check_dup_invoice_exists
                    FROM xx_ap_inv_interface_stg
                   WHERE external_doc_ref IS NOT NULL
                     AND RTRIM (SOURCE) = p_source
                     AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'No Duplicate Invoice Record exists   '
                              );
      END;
	  
	  -- Start DL Addition for Duplicate Invoice for NAIT-51088
	  BEGIN
         SELECT SYS_CONTEXT ('USERENV', 'INSTANCE_NAME')
           INTO lc_instance_name
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_instance_name := NULL;
         fnd_file.put_line (fnd_file.LOG, 'No data found while getting the Instance Name : '
                    || lc_instance_name
                   );
         WHEN OTHERS
         THEN
            lc_instance_name := NULL;
            fnd_file.put_line (fnd_file.LOG,  'Exception while getting the Instance Name : '
                    || lc_instance_name
                   );
      END;
	  
	   lc_email_to :=null;
	   
	   BEGIN
	 
          SELECT target_value2
          INTO lc_email_to
          FROM xx_fin_translatevalues
          WHERE translate_id IN
            (SELECT translate_id
            FROM xx_fin_translatedefinition
            WHERE translation_name = 'XX_AP_TRADE_INV_EMAIL'
            AND enabled_flag       = 'Y'
            )
          AND source_value1 = 'TRADE_DUP_INVOICE';
       EXCEPTION
          WHEN OTHERS THEN
            lc_email_to := NULL;
       END; 

lc_email_to :=lc_email_to||','||v_email_address ; 

	   -- End DL Addition for NAIT-51088
	  
      IF v_check_dup_invoice_exists = 'Y'
      THEN
         BEGIN
            fnd_file.put_line
                       (fnd_file.LOG,
                        'Submitting the Concurrent Request Emailer program   '
                       );
            l_request_id :=
               fnd_request.submit_request
                  ('xxfin',
                   'XXODROEMAILER',
                   NULL,
                   NULL,
                   FALSE,
                   NULL,
                 --v_email_address, -- Commented For NAIT 51088
				   lc_email_to,  --- Added to include DL for email for for NAIT-51088
               --- '--- Duplicate Invoices Notice Sent By Office Depot.',  --Commented to include Instance Name in subject for for NAIT-51088
				   lc_instance_name||'-'||'Duplicate Invoices Notice Sent By Office Depot.', -- Added to include Instance Name in subject for NAIT-51088
                   'See the attachment with duplicate invoices that need to be addressed.',
                   'Y',
                   ln_main_prog_req_id,
                   CHR (0),
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   ''
                  );
-- defect 6028            COMMIT;
            IF l_request_id = 0
            THEN
               fnd_file.put_line
                        (fnd_file.LOG,
                         'The Concurrent Request Emailer Program Has Failed.'
                        );
            ELSE
               fnd_file.put_line
                  (fnd_file.LOG,
                      'The Concurrent Request Emailer Program Has Been Submitted.  Request ID is   '
                   || l_request_id
                  );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_error_loc :=
                    'Error Occurred while running the Common Emailer Program';
               fnd_message.set_name ('XXFIN',
                                     ' XX_AP_0001_ERROR_NO_EMAILER_PROG '
                                    );
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_DEBUG', lc_error_debug);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_loc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
               xx_com_error_log_pub.log_error
                            (p_program_type                => 'CONCURRENT PROGRAM',
                             p_program_name                => 'XXAPINVINTFC',
                             p_module_name                 => 'AP',
                             p_error_location              =>    'Error at '
                                                              || SUBSTR
                                                                    (lc_error_loc,
                                                                     1,
                                                                     50
                                                                    ),
                             p_error_message_count         => 1,
                             p_error_message_code          => 'E',
                             p_error_message               => lc_loc_err_msg,
                             p_error_message_severity      => 'Major',
                             p_notify_flag                 => 'N',
                             p_object_type                 => 'Processing AP Inbound invoices'
                            );
         END; 
      END IF;*/
   END xx_ap_duplicate_invoices;
--------------------------------------------------------------------
-- +===================================================================+
-- | Name        : XX_EDI_UPDATE_CONTROL_TOTALS                          |
-- |                                                                   |
-- | Description : This procedure is used to update the control totals |
-- |               for count of Invoices and total invoice amount in  |
-- |               XX_AP_INV_BATCH_INTERFACE_STG table. Defect 7746   |
-- |                                                                  |
-- | Parameters  : None                                               |
-- |                                                                  |
-- | Returns     : None                                               |
-- +===================================================================+
   PROCEDURE xx_EDI_update_control_totals
   IS
      CURSOR get_EDI_info
      IS
         SELECT   b.SOURCE, COUNT (b.invoice_id),
                  SUM (b.invoice_amount)
              FROM xx_ap_inv_interface_stg b
              WHERE  b.batch_id is NULL
              AND b.global_attribute16 is NULL
              AND b.source = 'US_OD_EXPENSE_EDI'
              GROUP BY b.SOURCE;
      v_source              VARCHAR2 (30);
      v_filename            VARCHAR2 (100);
      ln_batch_id           NUMBER;
      ln_count_invoices     NUMBER;
      ln_total_inv_amount   NUMBER;
      l_request_id          NUMBER;
      ln_main_prog_req_id   NUMBER          := fnd_global.conc_request_id;
      ln_count_updates      NUMBER          := 0;
      lc_error_loc          VARCHAR2 (2000);
      lc_error_debug        VARCHAR2 (2000);
      lc_loc_err_msg        VARCHAR2 (2000);
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Creating Control Totals in staging tables for Expense EDI.'
                        );
      OPEN get_EDI_info;
      LOOP
         FETCH get_EDI_info
          INTO v_source, ln_count_invoices,
               ln_total_inv_amount;
         EXIT WHEN get_EDI_info%NOTFOUND;
-- Get the next Batch#
        begin
         select  XX_AP_INV_BATCH_INTFC_STG_S.nextval 
         into ln_batch_id
         from dual;      
        end;
        Begin 
          Insert into xx_ap_inv_batch_interface_stg 
          (
          BATCH_ID ,
          FILE_NAME,
          CREATION_DATE,
          CREATION_TIME ,
          INVOICE_COUNT ,
          TOTAL_BATCH_AMOUNT )         
          values (  ln_batch_id,
                    'AP_EXPENSE_NA_EDI',
                    sysdate,
                    sysdate,
                    ln_count_invoices,
                    ln_total_inv_amount
                    );
         End;
-- Update batch id on the header table.
        begin
          UPDATE xx_ap_inv_interface_stg
            SET batch_id = ln_batch_id
            WHERE batch_id is null
            and source = 'US_OD_EXPENSE_EDI'
            and global_attribute16 is null;
         end;
      END LOOP;
      CLOSE get_EDI_info;
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'Total Updates for EDI Expenses information: '
                         ||  ln_batch_id
                        );
   END xx_EDI_update_control_totals;
-- +===================================================================+
-- | Name        : XX_AP_UPDATE_CONTROL_TOTALS                            |
-- |                                                                      |
-- | Description : This procedure is used to update the control totals    |
-- |               for count of Invoices and total invoice amount in      |
-- |               XX_AP_INV_BATCH_INTERFACE_STG table.                   |
-- |                                                                      |
-- | Parameters  : None                                                   |
-- |                                                                      |
-- | Returns     : None                                                   |
-- +===================================================================+
   PROCEDURE xx_ap_update_control_totals
   IS
      CURSOR get_batch_info
      IS
         SELECT   a.file_name, a.batch_id, b.SOURCE, COUNT (b.invoice_id),
                  SUM (b.invoice_amount)
             FROM xx_ap_inv_batch_interface_stg a, xx_ap_inv_interface_stg b
            WHERE a.batch_id = b.batch_id
              AND a.invoice_count IS NULL
              AND a.total_batch_amount IS NULL
--         AND b.source = 'US_OD_RENT'
         GROUP BY a.file_name, a.batch_id, b.SOURCE;
      v_source              VARCHAR2 (30);
      v_filename            VARCHAR2 (100);
      ln_batch_id           NUMBER;
      ln_count_invoices     NUMBER;
      ln_total_inv_amount   NUMBER;
      l_request_id          NUMBER;
      ln_main_prog_req_id   NUMBER          := fnd_global.conc_request_id;
      ln_count_updates      NUMBER          := 0;
      lc_error_loc          VARCHAR2 (2000);
      lc_error_debug        VARCHAR2 (2000);
      lc_loc_err_msg        VARCHAR2 (2000);
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Updating Control Totals in staging tables .....   '
                        );
      OPEN get_batch_info;
      LOOP
         FETCH get_batch_info
          INTO v_filename, ln_batch_id, v_source, ln_count_invoices,
               ln_total_inv_amount;
         EXIT WHEN get_batch_info%NOTFOUND;
         UPDATE xx_ap_inv_batch_interface_stg
            SET invoice_count = ln_count_invoices,
                total_batch_amount = ln_total_inv_amount
          WHERE batch_id = ln_batch_id;
         ln_count_updates := ln_count_updates + 1;
      END LOOP;
      CLOSE get_batch_info;
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'Total Updates for Control information: '
                         || ln_count_updates
                        );
   END xx_ap_update_control_totals;
-- +===================================================================+
-- | Name        : XX_AP_PROCESS_REASON_CD                             |
-- |                                                                   |
-- | Description : This procedure is used to update the AMOUNT_APPLICABLE_BY_DISCOUNT |
-- |               based on the reason codes. (DEFECT 2326)                        |
-- |               Also, Defect 3087 - Chargeback Invoices from Integral
-- |                                                                  |
-- | Parameters  : None                                               |
-- |                                                                  |
-- | Returns     : None                                               |
-- +===================================================================+
   PROCEDURE xx_ap_process_reason_cd (
      errbuff      OUT      VARCHAR2,
      retcode      OUT      VARCHAR2,
      p_batch_id   IN       NUMBER,
      p_source     IN       VARCHAR2    --Defect 12231
   )
   IS
-- variables
-- use attribute11 on ap_invoice_lines_interface as reason code
-- join xx_ap_inv_interface_stg, xx_ap_inv_lines_interface_stg, ap_invoice_lines_interface to get the sum amount
-- update the invoice header  with amount_applicable_discount
-- AP_INVOICE_INTERFACE: attribute7 = source
-- AP_INVOICE_LINES_INTERFACE: attribute11 = reason_code (populate it in the insert statement))
      CURSOR get_discount_amt_info
      IS
         SELECT   c.batch_id, b.invoice_id, SUM (a.amount)
             FROM ap_invoice_lines_interface a,
                  ap_invoices_interface b,
                  xx_ap_inv_interface_stg c
            WHERE c.batch_id = p_batch_id
              AND c.global_attribute16 = 'PROCESSED'
              AND b.invoice_id = c.invoice_id
              AND a.line_type_lookup_code = 'ITEM'
              AND a.attribute11 NOT IN
                     ('CF',
                      'CO',
                      'DA',
                      'DF',
                      'FP',
                      'LX',
                      'MB',
                      'MF',
                      'NI',
                      'NS',
                      'PA',
                      'PU',
                      'SL',
                      'XD',
                      'FA'
                     )
              AND b.invoice_id = a.invoice_id
              AND b.attribute7 = 'US_OD_TRADE_EDI'                   -- source
         GROUP BY c.batch_id, b.invoice_id;
-- Defect 3087 Chargeback Invoices
      CURSOR updt_chargeback_invoices
      IS
         SELECT   c.batch_id, b.invoice_id
             FROM ap_invoice_lines_interface a,
                  ap_invoices_interface b,
                  xx_ap_inv_interface_stg c
            WHERE c.batch_id = p_batch_id
              AND b.attribute7 = p_source              --Defect 12231
              AND c.global_attribute16 = 'PROCESSED'
              AND b.invoice_id = c.invoice_id
              AND a.line_type_lookup_code = 'ITEM'
              AND a.attribute11 IN
                     ('SH', 'PD', 'P!','S!')
              AND b.invoice_id = a.invoice_id;
      ln_batch_id           NUMBER;
      ln_invoice_id         NUMBER;
      ln_total_inv_amount   NUMBER;
      l_request_id          NUMBER;
      ln_main_prog_req_id   NUMBER          := fnd_global.conc_request_id;
      lc_error_loc          VARCHAR2 (2000);
      lc_error_debug        VARCHAR2 (2000);
      lc_loc_err_msg        VARCHAR2 (2000);
   BEGIN
      fnd_file.put_line
                      (fnd_file.LOG,
                       '                                                    '
                      );
      fnd_file.put_line
         (fnd_file.LOG,
             'Updating AMOUNT APPLICABLE TO DISCOUNT in Open Payables Interface tables for Batch Id '
          || p_batch_id
          || ' .....   '
         );
      IF p_source = 'US_OD_TRADE_EDI'      --Defect 12231
      THEN
	      OPEN get_discount_amt_info;
	      LOOP
		 FETCH get_discount_amt_info
		  INTO ln_batch_id, ln_invoice_id, ln_total_inv_amount;
		 EXIT WHEN get_discount_amt_info%NOTFOUND;
	         -- check if amount_applicable_to_discount is greater than zero then call the update statement
		 BEGIN
		    UPDATE ap_invoices_interface
		       SET amount_applicable_to_discount = ln_total_inv_amount
		     WHERE invoice_id = ln_invoice_id;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       fnd_file.put_line (fnd_file.LOG,
					     'Batch_ID:'
					  || ln_batch_id
					  || ' Invoice_ID:'
					  || ln_invoice_id
					  || ' UPDATE FAILED.'
					 );
		 END;
		 fnd_file.put_line (fnd_file.LOG,
				       'Batch_ID:'
				    || ln_batch_id
				    || ' Invoice_ID:'
				    || ln_invoice_id
				    || ' Amount(DISC):'
				    || ln_total_inv_amount
				   );
	      END LOOP;
	      CLOSE get_discount_amt_info;
	      COMMIT;
	      fnd_file.put_line
			     (fnd_file.LOG,
				 'Updates for DFI Calculation Completed for Batch Id '
			      || ln_batch_id
			     );
      END IF;
      fnd_file.put_line
         (fnd_file.LOG,
             'Updating Chargeback Invoices in Open Payables and Staging tables '
          || p_batch_id
          || ' .....   '
         );
      OPEN updt_chargeback_invoices;
      LOOP
         FETCH updt_chargeback_invoices
          INTO ln_batch_id, ln_invoice_id;
         EXIT WHEN updt_chargeback_invoices%NOTFOUND;
-- check if amount_applicable_to_discount is greater than zero then call the update statement
         BEGIN
            UPDATE ap_invoices_interface
               SET attribute12 = 'Y'
             WHERE invoice_id = ln_invoice_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Batch_ID:'
                                  || ln_batch_id
                                  || ' Invoice_ID:'
                                  || ln_invoice_id
                                  || ' UPDATE for Chargeback Invoices (INTFC) FAILED.'
                                 );
         END;
         BEGIN
            UPDATE XX_AP_INV_INTERFACE_STG
               SET attribute12 = 'Y'
             WHERE invoice_id = ln_invoice_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Batch_ID:'
                                  || ln_batch_id
                                  || ' Invoice_ID:'
                                  || ln_invoice_id
                                  || ' UPDATE for Chargeback Invoices (STG) FAILED.'
                                 );
         END;
      END LOOP;
      CLOSE updt_chargeback_invoices;
      COMMIT;
      fnd_file.put_line
                     (fnd_file.LOG,
                         'Updates for Chargeback Invoices completed for Batch Id '
                      || ln_batch_id
                     );
   END xx_ap_process_reason_cd;
-- +===================================================================+
-- | Name        : xx_ap_pcard_update_proc                             |
-- |                                                                   |
-- | Description : This procedure is used to update pcard values       |
-- |               on the staging table per CR894                      |                       
-- |                                                                   |
-- | Parameters  : None                                                |
-- |                                                                   |
-- | Returns     : None                                                |
-- +===================================================================+
   PROCEDURE xx_ap_pcard_update_proc (    errbuff   OUT   VARCHAR2,
                                          retcode   OUT   VARCHAR2)
   IS
      CURSOR get_pcard_info
      IS
         SELECT invoice_id
           FROM xx_ap_inv_interface_stg 
          WHERE source = 'US_OD_PCARD'
            AND (global_attribute16 <> 'PROCESSED'
                 OR global_attribute16 IS NULL) ;
       CURSOR get_pcard_details (p_invoice_num NUMBER)
       IS
         SELECT    invoice_id
                  ,invoice_line_id
                  ,line_number
                  ,amount
                  ,accounting_date
                  ,description
                  ,dist_code_concatenated
                  ,last_update_date
                  ,creation_date
                  ,stat_amount
                  ,oracle_gl_company
                  ,oracle_gl_cost_center
                  ,oracle_gl_location
                  ,oracle_gl_account
                  ,oracle_gl_intercompany
                  ,oracle_gl_lob
                  ,oracle_gl_future1
            FROM   xx_ap_inv_lines_interface_stg
            where invoice_ID = p_invoice_num
            AND   NVL(STAT_AMOUNT,0) <> 0;
      lrec_detail_tbl     XX_AP_INVINB_PCARD_DTL_TBL;
      ln_invoice_id             xx_ap_inv_lines_interface_stg.invoice_id%type;     
      ln_amount                 xx_ap_inv_lines_interface_stg.amount%type;     
      ld_accounting_date        xx_ap_inv_lines_interface_stg.accounting_date%type;     
      lc_description            xx_ap_inv_lines_interface_stg.description%type;     
      lc_dist_code_concatenated xx_ap_inv_lines_interface_stg.dist_code_concatenated%type;     
      ld_last_update_date       xx_ap_inv_lines_interface_stg.last_update_date%type;       
      ld_creation_date          xx_ap_inv_lines_interface_stg.creation_date%type;     
      ln_stat_amount            xx_ap_inv_lines_interface_stg.amount%type;     
      lc_oracle_gl_company      xx_ap_inv_lines_interface_stg.oracle_gl_company%type;     
      lc_oracle_gl_cost_center  xx_ap_inv_lines_interface_stg.oracle_gl_cost_center%type;     
      lc_oracle_gl_location     xx_ap_inv_lines_interface_stg.oracle_gl_location%type;     
      lc_oracle_gl_account      xx_ap_inv_lines_interface_stg.oracle_gl_account%type;     
      lc_oracle_gl_intercompany xx_ap_inv_lines_interface_stg.oracle_gl_intercompany%type;     
      lc_oracle_gl_lob          xx_ap_inv_lines_interface_stg.oracle_gl_lob%type;     
      lc_oracle_gl_future1      xx_ap_inv_lines_interface_stg.oracle_gl_future1%type; 
      ln_line_number            xx_ap_inv_lines_interface_stg.line_number%type; 
      ln_item_invoice_line_id   xx_ap_inv_lines_interface_stg.invoice_line_id%type;  
      ln_invoce_id          NUMBER;
      ln_invoice_num        xx_ap_inv_interface_stg.invoice_num%type; 
      ln_cur_line_number    NUMBER;
      ln_invoice_line_id    xx_ap_inv_lines_interface_stg.invoice_line_id%type;      
      lc_current_date       VARCHAR2(50);
      ln_temp_inv_number    xx_ap_inv_interface_stg.invoice_num%type; 
      lc_supplier_number    xx_ap_inv_interface_stg.attribute10%type;
      lc_site_name          xx_ap_inv_interface_stg.vendor_site_code%type; 
      ln_site_id            xx_ap_inv_interface_stg.vendor_site_id%type;
      ln_count_invoices     NUMBER;
      ln_account_number     NUMBER;
      ln_count_updates      NUMBER   := 0;
      lc_error_loc          VARCHAR2 (2000);
      lc_error_debug        VARCHAR2 (2000);
      lc_loc_err_msg        VARCHAR2 (2000);
      lc_database           VARCHAR2 (25);
      ln_user_id                       NUMBER
                                := NVL (fnd_profile.VALUE ('USER_ID'), 0);
   BEGIN
      ----------------------------------------------------
      -- Production environment will not include timestamp
      -- -------------------------------------------------
      SELECT name
        INTO lc_database 
        FROM V$database;       
      IF  lc_database = 'GSIPRDGB' THEN 
           lc_current_date := TO_CHAR (SYSDATE, '-MMYY');
      ELSE     
           lc_current_date := TO_CHAR (SYSDATE, '-MMYYHHMISS');    -- removed :per defect 14091 
      END IF;
      fnd_file.put_line (fnd_file.LOG,
                         'Lookup of Account number for Pcard. '
                        );
      lc_error_loc := 'Looking up PCard info on XX_PCARD_DETAILS';   
      BEGIN 
           SELECT TV.target_value1,
               TV.target_value2,
               TV.target_value3,
               assa.vendor_site_id            
          INTO ln_account_number,
               lc_supplier_number,
               lc_site_name,
               ln_site_id                                    -- added per defect 14094
          FROM XX_FIN_TRANSLATEDEFINITION TD
              ,XX_FIN_TRANSLATEVALUES   TV
			  -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
              --,po_vendor_sites_all vs
			  ,ap_supplier_sites_all assa
			  -- end of addition
         WHERE TD.translate_id = TV.translate_id
           AND TV.target_value3 = assa.vendor_site_code
           AND TD.translation_name = 'XX_PCARD_DETAILS'
           AND TV.source_value1  = 'JP MORGAN CHASE'
           AND TD.enabled_flag   = 'Y';  
      END;
      fnd_file.put_line (fnd_file.LOG,
                         'Pcard update values from XX_PCARD_DETAILS table:'
                        );  
      gc_pcard_acct_num :=  ln_account_number || lc_current_date;
      fnd_file.put_line (fnd_file.LOG,
                         'Pcard account number = '||gc_pcard_acct_num
                        ||' supplier number = ' || lc_supplier_number
                        ||' site name = '|| lc_site_name
                        );
      lc_error_loc := 'Updating update pcard invoice data.';
      ln_count_invoices  := 0;
      OPEN get_pcard_info;
      lc_error_loc := 'Opening Fetch for get_pcard_info';
      LOOP
         FETCH get_pcard_info
          INTO ln_invoce_id;
         EXIT WHEN get_pcard_info%NOTFOUND;
         ln_count_invoices := ln_count_invoices +1;
         lc_error_loc := 'updating  xx_ap_inv_interface_stg for pcard';
         BEGIN
          UPDATE xx_ap_inv_interface_stg
            SET vendor_num       = lc_supplier_number, 
                vendor_site_code = lc_site_name,
                attribute10      = ln_site_id,              --updated per defect 14094
                vendor_site_id   = ln_site_id,
                last_updated_by  = ln_user_id,
                last_update_date = sysdate
            WHERE invoice_id     = ln_invoce_id ;
          END;
            -------------------------------------------------
            --Open cursor to look to tax lines to be inserted   -- added cursor per defects 14096
            -------------------------------------------------
            OPEN get_pcard_details (ln_invoce_id);
            lc_error_loc := 'Opening Fetch for get_pcard_details';
            LOOP
               FETCH get_pcard_details
                INTO   ln_invoice_id
                      ,ln_item_invoice_line_id 
                      ,ln_cur_line_number                                       --added per defect 14767
                      ,ln_amount
                      ,ld_accounting_date
                      ,lc_description
                      ,lc_dist_code_concatenated
                      ,ld_last_update_date
                      ,ld_creation_date
                      ,ln_stat_amount
                      ,lc_oracle_gl_company
                      ,lc_oracle_gl_cost_center
                      ,lc_oracle_gl_location
                      ,lc_oracle_gl_account
                      ,lc_oracle_gl_intercompany
                      ,lc_oracle_gl_lob
                      ,lc_oracle_gl_future1;
             EXIT WHEN get_pcard_details%NOTFOUND;
                 lc_error_loc := 'Select next invoice line id for get_pcard_details';
                 SELECT ap_invoice_lines_interface_s.NEXTVAL 
                   INTO ln_invoice_line_id 
                   from dual; 
                 lc_error_loc := 'Select next line number for get_pcard_details';
                 SELECT max(line_number)
                      INTO ln_line_number                       
                      FROM xx_ap_inv_lines_interface_stg
                     where invoice_ID = ln_invoce_id;
                lc_error_loc := 'update item amount for get_pcard_details';
               UPDATE xx_ap_inv_lines_interface_stg 
                   SET   amount = ln_amount - ln_stat_amount
                        ,stat_amount = 0
                        ,AMOUNT_INCLUDES_TAX_FLAG  = 'N'
                        ,line_group_number = ln_cur_line_number                 --added per defect 14767
                 where  invoice_line_id = ln_item_invoice_line_id;
                 lc_error_loc := 'Inserting tax lines into get_pcard_details';
                 INSERT INTO xx_ap_inv_lines_interface_stg
                     (
                       invoice_id
                      ,invoice_line_id
                      ,line_number 
                      ,line_group_number                                        --added per defect 14767
                      ,line_type_lookup_code
                      ,tax_code
                      ,prorate_across_flag
                      ,amount
                      ,oracle_gl_company         -- Company
                      ,oracle_gl_cost_center     -- Cost Center
                      ,oracle_gl_location        -- Location
                      ,oracle_gl_account         -- Account
                      ,oracle_gl_intercompany    -- InterCompany
                      ,oracle_gl_lob             -- Line of Business 
                      ,oracle_gl_future1         -- GL Future
                      ,description
                      ,accounting_date
                      ,dist_code_concatenated
                      ,creation_date 
                      ,created_by
                      ,last_updated_by
                      ,last_update_date
                      ,last_update_login         
                     )
                     VALUES (
                       ln_invoice_id 
                      ,ln_invoice_line_id
                      ,ln_line_number +1
                      ,ln_cur_line_number                                       -- added per defect 14767
                      ,'TAX'
                      ,'SALES'
                      ,'Y'
                      ,ln_stat_amount
                      ,lc_oracle_gl_company
                      ,lc_oracle_gl_cost_center 
                      ,lc_oracle_gl_location 
                      ,lc_oracle_gl_account
                      ,lc_oracle_gl_InterCompany            
                      ,lc_oracle_gl_lob
                      ,lc_oracle_gl_future1
                      ,lc_description
                      ,ld_accounting_date
                      ,LC_DIST_CODE_CONCATENATED
                      ,sysdate
                      ,ln_user_id
                      ,ln_user_id
                      ,sysdate
                      ,ln_user_id
                     ) ;
                COMMIT;
          END LOOP;
          CLOSE get_pcard_details;
      END LOOP;
      CLOSE get_pcard_info;
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'Total Updates for PCard Invoice updated: '
                         ||  ln_count_invoices
                        );
   EXCEPTION
      WHEN OTHERS
         THEN     
             fnd_file.put_line (fnd_file.LOG,
                        'When other exception occured in xx_ap_pcard_update_proc' );
             fnd_file.put_line (fnd_file.LOG,
                        lc_error_loc || SQLERRM );
             errbuff := lc_error_loc ||' '|| SQLERRM;
             ROLLBACK;                        
             retcode := 1;                        
   END  xx_ap_pcard_update_proc;
-- +===================================================================+
-- | Name        : XX_AP_UPDATE_INTEGRAL_SOURCE                             |
-- |                                                                   |
-- | Description : This procedure is used to update the missing source |
-- |               for INTERGRAL files                                |
-- |                                                                  |
-- | Parameters  : None                                               |
-- |                                                                  |
-- | Returns     : None                                               |
-- +===================================================================+
   PROCEDURE xx_ap_update_integral_source (
      errbuff   OUT   VARCHAR2,
      retcode   OUT   VARCHAR2
   )
   IS
-- For source of Integral file, if there are any sources that are blank then update the source to `US_OD_INTEGRAL_ONLINE¿
-- Join the Batch table and Header table (Staging) where filename is Integral and the data is not processed in Header 
--staging and get the Batch Id.
-- Get the source for that BATCH and if it is null then populate the source value.
      CURSOR get_null_source_info
      IS
         SELECT a.file_name, b.batch_id, invoice_id
           FROM xx_ap_inv_batch_interface_stg a,
                xx_ap_inv_interface_stg b
          WHERE a.file_name LIKE '%INTEGRAL%'
            AND b.batch_id = a.batch_id
            AND b.SOURCE IS NULL
            AND b.global_attribute16 IS NULL;
      ln_batch_id           NUMBER;
      ln_invoice_id         NUMBER;
      lc_filename           VARCHAR2 (2000);
      l_request_id          NUMBER;
      ln_main_prog_req_id   NUMBER          := fnd_global.conc_request_id;
      lc_error_loc          VARCHAR2 (2000);
      lc_error_debug        VARCHAR2 (2000);
      lc_loc_err_msg        VARCHAR2 (2000);
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Updating Source for Integral File ...... '
                        );
      OPEN get_null_source_info;
      LOOP
         FETCH get_null_source_info
          INTO lc_filename, ln_batch_id, ln_invoice_id;
         EXIT WHEN get_null_source_info%NOTFOUND;
         BEGIN
            UPDATE xx_ap_inv_interface_stg
               SET SOURCE = 'US_OD_INTEGRAL_ONLINE'
             WHERE batch_id = ln_batch_id
               AND invoice_id = ln_invoice_id
               AND SOURCE IS NULL
               AND global_attribute16 IS NULL;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Batch_ID:'
                                  || ln_batch_id
                                  || ' Invoice_ID:'
                                  || ln_invoice_id
                                  || ' UPDATE FAILED.'
                                 );
         END;
      END LOOP;
      CLOSE get_null_source_info;
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                         'Updates for INTEGRAL missing source is completed. '
                        );
   END xx_ap_update_integral_source;
-----------------------------------------------------------------

-- +===================================================================+
-- | Name        : xx_ap_validate_inv_interface                        |
-- |                                                                   |
-- | Description :                				       |
-- |                                                                   |
-- | Parameters  : Input: Source, Group Id                             |
-- |                                                                   |
-- | Returns     : None                                                |
-- +===================================================================+
PROCEDURE xx_ap_validate_inv_interface (
			      		errbuff      OUT      VARCHAR2,
			      		retcode      OUT      VARCHAR2,
			      		p_source     IN       VARCHAR2,
			      		p_group_id   IN       VARCHAR2
				   	)	
IS
CURSOR c2 (errbuff      OUT      VARCHAR2,
           retcode      OUT      VARCHAR2,
           p_source     IN       VARCHAR2,
           p_group_id   IN       VARCHAR2
          )
IS
SELECT *
  FROM xx_ap_inv_interface_stg
 WHERE RTRIM (SOURCE) = p_source
   AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL)
   AND external_doc_ref IS NULL
   AND global_attribute16 IS NULL;
      CURSOR c3 (p_invoice_id IN NUMBER)
      IS
         SELECT a.line_number, b.invoice_id,
                xx_po_global_vendor_pkg.f_translate_inbound
                                         (RTRIM (b.attribute10)
                                         ) vendor_site_id,
                RTRIM (b.attribute10) od_global_vendor_id, a.invoice_line_id,
                b.invoice_num, b.invoice_date,
                UPPER (NVL (a.line_type_lookup_code, 'ITEM')
                      ) line_type_lookup_code,
                a.line_group_number,                                             --added per defect 14767     
                b.SOURCE, a.amount, a.accounting_date, a.description,a.prorate_across_flag,
                a.tax_code, a.po_header_id, a.po_number, a.po_line_id,
                a.po_line_number, a.po_distribution_num, a.po_unit_of_measure,
                a.quantity_invoiced, a.ship_to_location_code, a.unit_price,
                a.inventory_item_id,-- Added for Trade Match
                a.dist_code_concatenated, a.dist_code_combination_id,
                a.last_updated_by, a.last_update_date, a.last_update_login,
                a.created_by, a.creation_date, a.attribute_category,
                a.attribute1, a.attribute2, a.attribute3, a.attribute4,
                a.attribute5, a.attribute6, a.attribute7, a.attribute8,
                a.attribute9, a.attribute10, a.attribute11, a.attribute12,
                a.attribute13, a.attribute14, a.attribute15,
                a.global_attribute_category, a.global_attribute1,
                a.global_attribute2, a.global_attribute3, a.global_attribute4,
                a.global_attribute5, a.global_attribute6, a.global_attribute7,
                a.global_attribute8, a.global_attribute9,
                a.global_attribute10, a.global_attribute11,
                a.global_attribute12, a.global_attribute13,
                a.global_attribute14, a.global_attribute15,
                a.global_attribute16, a.global_attribute17,
                a.global_attribute18, a.global_attribute19,
                a.global_attribute20, a.account_segment, a.balancing_segment,
                a.cost_center_segment, a.project_id, a.task_id,
                a.expenditure_type, a.expenditure_item_date,
                a.expenditure_organization_id, a.org_id, a.receipt_number,
                a.receipt_line_number, a.match_option, a.tax_code_id,
                a.external_doc_line_ref, a.legacy_segment1, a.legacy_segment2,
                a.legacy_segment3, a.legacy_segment4, a.legacy_segment5,
                a.legacy_segment6, a.legacy_segment7, a.legacy_segment8,
                a.legacy_segment9, a.legacy_segment10, a.reason_code,
                a.oracle_gl_company, a.oracle_gl_cost_center,
                a.oracle_gl_location, a.oracle_gl_account,
                a.oracle_gl_intercompany, a.oracle_gl_lob,
                a.oracle_gl_future1,
				a.item_description--Added for defect# 28446	
           FROM xx_ap_inv_lines_interface_stg a,
                xx_ap_inv_interface_stg b
          WHERE a.invoice_id = b.invoice_id
            AND a.invoice_id = p_invoice_id
            AND a.external_doc_line_ref IS NULL
            AND a.global_attribute16 IS NULL;
	  
invoices_updt                   c2%ROWTYPE;
inv_lines_updt                  c3%ROWTYPE;
v_user_id                       NUMBER:= NVL (fnd_profile.VALUE ('USER_ID'), 0);
-- Added as per the Defect ID : 2410
lc_reject_code_table   CONSTANT ap_interface_rejections.parent_table%TYPE:= 'AP_INVOICES_INTERFACE';
lc_company                      VARCHAR2 (2000);
-- Added as per the Defect ID : 2410
lc_reject_code_type    CONSTANT ap_interface_rejections.reject_lookup_code%TYPE:= 'INVALID CODE COMBINATION';
v_vendor_site_id                NUMBER;
v_vendor_id                     NUMBER;
-- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
--v_org_id                        po_vendor_sites_all.org_id%TYPE;
v_org_id                        ap_supplier_sites_all.org_id%TYPE;
-- end of addition
v_employee_id                   NUMBER;            -- Oracle Employee ID
v_count                         NUMBER;
v_project_id                    NUMBER;
v_task_id                       NUMBER;
v_expenditure_org_id            NUMBER;
v_expenditure_type              VARCHAR2 (80);
v_expenditure_item_date         DATE;
v_TERMS_DATE                    date;
v_date_goods_rec                DATE;    --added CR729
v_tax_code                      VARCHAR2 (50);
v_province                      VARCHAR2 (50);
v_terms_name                    VARCHAR2 (50);
v_full_gl_code                  VARCHAR2 (2000);
v_tax_account                   VARCHAR2 (2000);
v_ccid                          NUMBER;
lc_coa_id                       gl_sets_of_books_v.chart_of_accounts_id%TYPE;
-- Added as per the Defect Id 2410
v_error_message                 VARCHAR2 (240);
-- Added as per the Defect Id 2410
lc_concurrent_program_name      fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
lc_error_flag                   VARCHAR2 (1)   := 'N';
lc_error_loc                    VARCHAR2 (2000);
lc_error_debug                  VARCHAR2 (2000);
lc_loc_err_msg                  VARCHAR2 (2000);
x_seg1_company                  VARCHAR2 (2000);
x_seg2_costctr                  VARCHAR2 (2000);
x_seg3_account                  VARCHAR2 (2000);
x_seg4_location                 VARCHAR2 (2000);
x_seg5_interco                  VARCHAR2 (2000);
x_seg6_lob                      VARCHAR2 (2000);
x_seg7_future                   VARCHAR2 (2000);
x_ccid                          VARCHAR2 (2000);
x_error_message                 VARCHAR2 (2000);
x_target_value1                 VARCHAR2 (2000);
x_target_value2                 VARCHAR2 (2000);
x_target_value3                 VARCHAR2 (2000);
x_target_value4                 VARCHAR2 (2000);
x_target_value5                 VARCHAR2 (2000);
x_target_value6                 VARCHAR2 (2000);
x_target_value7                 VARCHAR2 (2000);
x_target_value8                 VARCHAR2 (2000);
x_target_value9                 VARCHAR2 (2000);
x_target_value10                VARCHAR2 (2000);
x_target_value11                VARCHAR2 (2000);
x_target_value12                VARCHAR2 (2000);
x_target_value13                VARCHAR2 (2000);
x_target_value14                VARCHAR2 (2000);
x_target_value15                VARCHAR2 (2000);
x_target_value16                VARCHAR2 (2000);
x_target_value17                VARCHAR2 (2000);
x_target_value18                VARCHAR2 (2000);
x_target_value19                VARCHAR2 (2000);
x_target_value20                VARCHAR2 (2000);
-- Retail Lease Flag defect2109
ln_invoice_line_id              ap_invoice_lines_interface.invoice_line_id%TYPE;
lc_rtl_flag                     VARCHAR2 (1):= 'N';
ln_tax_code_id                  ap_invoice_lines_interface.tax_code_id%TYPE;
-- defect 2326
ln_curr_batch_id                NUMBER   := 0;
ln_prev_batch_id                NUMBER   := 0;
lc_gl_segment1                  VARCHAR2 (5);
lc_gl_segment2                  VARCHAR2 (5);
lc_gl_segment3                  VARCHAR2 (8);
lc_gl_segment4                  VARCHAR2 (6);
lc_gl_segment5                  VARCHAR2 (5);
lc_gl_segment6                  VARCHAR2 (2);
lc_gl_segment7                  VARCHAR2 (6);
l_request_id                    NUMBER   := 0;   -- FOR Defect 19421 - sinon
-- Added for Prod defect#622
LC_CASE_IDENTIFIER              XX_AP_INV_LINES_INTERFACE_STG.GLOBAL_ATTRIBUTE1%type;
lc_pymnt_mthd_cd		VARCHAR2(30);
-- Added for the AP Trade Match
lc_match_type                   VARCHAR2(50);
lc_po_type                      VARCHAR2(30);
lc_closed_code                  VARCHAR2(30);
lc_terms_date_basis             VARCHAR2(30);	
lc_authorization_status         VARCHAR2(30);
lc_drop_ship_flag               VARCHAR2(1);
ld_terms_date                   DATE;
ld_goods_received_date          DATE;
ld_invoice_received_date        DATE;
ln_invoice_id                   NUMBER;
ln_total_invoice_lines_amt      NUMBER;
ln_invoice_hdr_amt              NUMBER;
ln_difference_amt               NUMBER;
ln_dist_var_neg_amt             NUMBER;
ln_dist_var_pos_amt             NUMBER;
ln_line_number                  NUMBER;
lc_gl_account                   VARCHAR2(50);
lc_dm_invoice_num               VARCHAR2(50);
ln_max_freight_amt              NUMBER;
ln_freight_amt                  NUMBER;
ln_chargeback_inv_exists        NUMBER;
ln_po_header_id                 NUMBER;
lc_inspection_req_flag          VARCHAR2(10);
lc_receipt_req_flag             VARCHAR2(10);
lc_gl_string                    VARCHAR2(100);
lc_description                  VARCHAR2(100);
lc_reason_code                  VARCHAR2(30);

BEGIN
  --Version 2.11. Defect 33354
  BEGIN
     EXECUTE IMMEDIATE 'ALTER SESSION SET "_optimizer_extended_cursor_sharing_rel"=NONE';
     fnd_file.put_line(fnd_file.LOG,'ALTER SESSION COMMAND EXECUTED');
  EXCEPTION
  WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.LOG,'+-----------------------------------------------------+');
     fnd_file.put_line(fnd_file.LOG,'EXECUTE IMMEDIATE ALTER SESSION SET::ERROR :'||SQLERRM);
     fnd_file.put_line(fnd_file.LOG,'+-----------------------------------------------------+');
  END;

  --Printing the Parameters
  lc_error_loc := 'Printing the Parameters of the program';
  lc_error_debug := '';
  fnd_file.put_line(fnd_file.LOG, '         ');
  fnd_file.put_line(fnd_file.LOG, '         ');
  fnd_file.put_line(fnd_file.LOG,'Given AP Interface Invoice Program Parameters          ');
  fnd_file.put_line(fnd_file.LOG,'+-----------------------------------------------------+');
  fnd_file.put_line (fnd_file.LOG, 'Source:  ' || p_source);
  fnd_file.put_line (fnd_file.LOG, 'Group:   ' || p_group_id);
  fnd_file.put_line(fnd_file.LOG,'+-----------------------------------------------------+');
	
  IF p_source='US_OD_OTM' THEN
     XX_AP_OTM_UPDATE(p_group_id);
  END IF;


  -- Create the batch for EDI Expense Invoices defect 7746
  IF p_source  = 'US_OD_EXPENSE_EDI'  THEN                       -- added conditional statement 10/5/2011
                                                                     -- per performance testing.   
     xx_ap_inv_validate_pkg.xx_EDI_update_control_totals();
  END IF;
  xx_ap_inv_validate_pkg.xx_ap_update_control_totals;
  BEGIN
    -- To Get the Concurrent Program Name
    lc_error_loc := 'Get the Concurrent Program Name:';
    lc_error_debug :='Concurrent Program id: ' || fnd_global.conc_program_id;
    SELECT user_concurrent_program_name
      INTO lc_concurrent_program_name
      FROM fnd_concurrent_programs_vl
     WHERE concurrent_program_id = fnd_global.conc_program_id;
  EXCEPTION
    WHEN OTHERS THEN
      fnd_message.set_name ('XXFIN', ' XX_AP_0002_ERROR_NO_CONC_PROG');
      fnd_message.set_token ('ERR_LOC', lc_error_loc);
      fnd_message.set_token ('ERR_DEBUG', lc_error_debug);
      fnd_message.set_token ('ERR_ORA', SQLERRM);
      lc_loc_err_msg := fnd_message.get;
      fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
      xx_com_error_log_pub.log_error
                           (p_program_type                => 'CONCURRENT PROGRAM',
                            p_program_name                => 'XXAPINVINTFC',
                            p_module_name                 => 'AP',
                            p_error_location              => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                            p_error_message_count         => 1,
                            p_error_message_code          => 'E',
                            p_error_message               => lc_loc_err_msg,
                            p_error_message_severity      => 'Major',
                            p_notify_flag                 => 'N',
                            p_object_type                 => 'Processing AP Inbound invoices'
                           );
  END;
  -------------------------------------------------------------
  --  Update Invoice_number and invoice date for pcard files --
  -------------------------------------------------------------
  IF p_source = 'US_OD_PCARD' THEN
     xx_ap_inv_validate_pkg.xx_ap_pcard_update_proc(errbuff, retcode);
  END IF;
  --------------------------------------------------------
  --  Update Missing Invoice Sources for INTEGRAL files --
  --------------------------------------------------------
  xx_ap_inv_validate_pkg.xx_ap_update_integral_source (errbuff, retcode);
  ----------------------------
  --  Update Invoice Sources --
  ----------------------------
  xx_ap_inv_validate_pkg.xx_ap_update_source (errbuff, retcode);
  ----------------------------
  --  Purge invoice records --
  ----------------------------
  xx_ap_inv_validate_pkg.xx_ap_invoices_purge (errbuff,
                                                   retcode,
                                                   p_source,
                                                   p_group_id
                                                  );
  --------------------------------
  -- report duplicate invoices --
  --------------------------------
  xx_ap_inv_validate_pkg.xx_ap_duplicate_invoices (errbuff,
                                                       retcode,
                                                       p_source,
                                                       p_group_id
                                                      );
  -----------------------------------------------------------------
  -- Check if non-processed invoices are available to be imported --
  ------------------------------------------------------------------
   BEGIN
    SELECT COUNT (1)
      INTO v_count
      FROM xx_ap_inv_interface_stg
     WHERE RTRIM (SOURCE) = p_source
       AND (GROUP_ID = p_group_id OR GROUP_ID IS NULL)
       AND external_doc_ref IS NULL
       AND global_attribute16 IS NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lc_error_flag := 'Y';
  END;
  IF v_count > 0  THEN

   IF p_source<>'US_OD_OTM' THEN  -- Defect 21393

     lc_error_flag := 'N';
     FOR invoices_updt IN c2 (errbuff, retcode, p_source, p_group_id)
     LOOP
         lc_case_identifier := '';  -- defect 622
 	 -------------------------------------
	 -- Validating the vendor information--
	 -------------------------------------
         v_vendor_id := NULL;
         v_vendor_site_id := NULL;
         v_org_id := NULL;


	 -- BEGIN Defect 31882  

	 lc_pymnt_mthd_cd:=NULL;

         IF invoices_updt.source='US_OD_CONSIGNMENT_SALES' THEN
	    lc_pymnt_mthd_cd:=invoices_updt.payment_method_lookup_code;
         END IF;

	 -- END Defect 31882  

         --defect 2326
         IF (ln_curr_batch_id = 0)  THEN
             ln_curr_batch_id := invoices_updt.batch_id;
         END IF;
         IF (ln_curr_batch_id <> invoices_updt.batch_id) THEN
 	    -- call the procedure to process for this batch id.
            xx_ap_inv_validate_pkg.xx_ap_process_reason_cd
                                                             (errbuff,
                                                              retcode,
                                                              ln_curr_batch_id,
							      p_source
                                                             );
	     -- SANDEEP call procedure to with batch_id to identify the Integral data with no source
                  ln_curr_batch_id := invoices_updt.batch_id;
         END IF;

       -- Modified for defect 19205

       BEGIN
         SELECT vendor_site_id, vendor_id, org_id
           INTO v_vendor_site_id, v_vendor_id, v_org_id
		   -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
           --FROM po_vendor_sites_all
		   FROM ap_supplier_sites_all
		   -- end of addition
          WHERE (    vendor_site_id = RTRIM (invoices_updt.attribute10)
                  OR vendor_site_id =xx_po_global_vendor_pkg.f_translate_inbound
                                            (RTRIM (invoices_updt.attribute10))
                )
            AND (inactive_date IS NULL OR inactive_date>SYSDATE);
       EXCEPTION
         WHEN OTHERS THEN
		 
		 
           BEGIN
             SELECT vendor_site_id, vendor_id, org_id
               INTO v_vendor_site_id, v_vendor_id, v_org_id
			   -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
               --FROM po_vendor_sites_all
			   FROM ap_supplier_sites_all
			   -- end of addition
              WHERE vendor_site_code_alt =TO_CHAR(TO_NUMBER(invoices_updt.attribute10))
                AND pay_site_flag='Y'
                AND inactive_date IS NULL;
	   EXCEPTION
	     WHEN others THEN
               lc_error_loc := 'Error deriving the vendor identifier';
               fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_NO_VENDOR ');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_DEBUG','OD Global Vendor ID:  '|| invoices_updt.attribute10);
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_loc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, '********* Cannot find Vendor for Attribute10=' ||
                                                    invoices_updt.attribute10);
               xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound invoices'
                            );
	   END;
       END;

       -- BEGIN Defect 31882

       IF invoices_updt.source='US_OD_CONSIGNMENT_SALES' AND lc_pymnt_mthd_cd IS NULL THEN

	  BEGIN	
	   SELECT xftv.target_value10
	     INTO lc_pymnt_mthd_cd
	     FROM xx_fin_translatedefinition xftd ,
                  xx_fin_translatevalues xftv
	    WHERE Xftd.Translate_Id   = Xftv.Translate_Id
              AND Xftd.Translation_Name = 'AP_CONSIGN_LIABILITY'
              AND xftv.source_value2=SUBSTR(invoices_updt.attribute10,2)
              AND Xftv.Target_Value9=LTRIM(RTRIM(invoices_updt.pay_group_lookup_code))
              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
              AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
              AND Xftv.Enabled_Flag = 'Y'
              AND Xftd.Enabled_Flag = 'Y';
	  EXCEPTION
	    WHEN others THEN
	      lc_pymnt_mthd_cd:=NULL;
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to derive payment method for the Vendor for Attribute10=' || invoices_updt.attribute10);
	  END;

       END IF;

       -- END Defect 31882

       IF invoices_updt.SOURCE = 'US_OD_EXTENSITY' THEN
          BEGIN
	    -------------------------------------
	    -- Deriving the Oracle employee ID --
	    -------------------------------------
            v_employee_id := NULL;
            SELECT person_id
              INTO v_employee_id
              FROM per_all_people_f
             WHERE employee_number =SUBSTR (invoices_updt.attribute10, 5)
               AND trunc(sysdate) between effective_start_date and effective_end_date; 
            --Employee numbers in xx_ap_inv_interface_stg.attribute10 are always lpaded to 9 characters,
          EXCEPTION
            WHEN OTHERS THEN
              lc_error_loc := 'Error deriving the Oracle Employee ID';
              fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_NO_EMPLOYEE ');
              fnd_message.set_token ('ERR_LOC', lc_error_loc);
              fnd_message.set_token ('ERR_DEBUG','OD Global Vendor ID:  '|| invoices_updt.attribute10);
              fnd_message.set_token ('ERR_ORA', SQLERRM);
              lc_loc_err_msg := fnd_message.get;
              fnd_file.put_line (fnd_file.LOG, ' Cannot find Employee for Empl#=' ||
                                                    SUBSTR (invoices_updt.attribute10, 5));
              xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound invoices'
                            );
          END;
       END IF;  --       IF invoices_updt.SOURCE = 'US_OD_EXTENSITY' THEN
       BEGIN
	 ----------------------------------------------------
	 -- Translating Peoplesoft and Integral Terms Name --
	 ----------------------------------------------------
         v_terms_name := NULL;
         IF (invoices_updt.terms_name IS NOT NULL) THEN                                             
	     -- defect 2491
             xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                    ('AP_PAYMENT_TERMS',     --translation_name
                                     SYSDATE,
                                     NULL,                      --source_value1
                                     invoices_updt.terms_name,  --source_value2
                                     NULL,                      --source_value3
                                     NULL,                      --source_value4
                                     NULL,                      --source_value5
                                     NULL,                      --source_value6
                                     NULL,                      --source_value7
                                     NULL,                      --source_value8
                                     NULL,                      --source_value9
                                     NULL,                      --source_value10
                                     x_target_value1,
                                     x_target_value2,
                                     x_target_value3,
                                     x_target_value4,
                                     x_target_value5,
                                     x_target_value6,
                                     x_target_value7,
                                     x_target_value8,
                                     x_target_value9,
                                     x_target_value10,
                                     x_target_value11,
                                     x_target_value12,
                                     x_target_value13,
                                     x_target_value14,
                                     x_target_value15,
                                     x_target_value16,
                                     x_target_value17,
                                     x_target_value18,
                                     x_target_value19,
                                     x_target_value20,
                                     x_error_message
                                    );
             v_terms_name := NVL (x_target_value2, x_target_value3);
         END IF;
       EXCEPTION
         WHEN OTHERS THEN
           lc_error_loc := 'Error deriving the Terms Name';
           fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_TERMS_NAME ');
           fnd_message.set_token ('ERR_LOC', lc_error_loc);
           fnd_message.set_token ('ERR_DEBUG',
                                            'Terms Name:  '
                                         || invoices_updt.terms_name
                                         || '  for OD Global Vendor ID:  '
                                         || invoices_updt.attribute10
                                        );
           fnd_message.set_token ('ERR_ORA', SQLERRM);
           lc_loc_err_msg := fnd_message.get;
           fnd_file.put_line (fnd_file.LOG, lc_error_loc || 
                                                              'Terms Name:  '
                                         || invoices_updt.terms_name
                                         || '  for OD Global Vendor ID:  '
                                         || invoices_updt.attribute10);
           xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound invoices'
                            );
       END;
       ------------------------------------------------------
       -- Processing for TDM Expenses invoices  --
       ------------------------------------------------------
       IF     invoices_updt.SOURCE = 'US_OD_TDM'
          AND invoices_updt.GROUP_ID = 'TDM-EXPENSE' THEN
	  ------------------------------------------------------
	  -- Populates the terms date with the receipt date  --
	  ------------------------------------------------------
          v_terms_date := invoices_updt.invoice_date;
          xx_ap_inv_terms_pkg.inv_terms_date (invoices_updt.invoice_num,
                                                   invoices_updt.po_number,
                                                   V_TERMS_DATE,
                                                   V_DATE_GOODS_REC,  --added CR729
                                                   invoices_updt.attribute15, -- added CR729
                                                   v_vendor_id
                                                  );
          INVOICES_UPDT.TERMS_DATE := V_TERMS_DATE;
          invoices_updt.goods_received_date := v_date_goods_rec;   -- Added per CR729
	  --fnd_file.put_line (fnd_file.LOG, 'TERMS Package returns:' || v_terms_date );
	  -------------------------------------------------------------
	  -- Builds the TDM expense invoice lines from the PO lines  --
	  -------------------------------------------------------------
          --xx_ap_inv_validate_pkg.xx_ap_create_po_inv_lines (p_group_id);-- Changed as per the Defect ID 1936
       ELSIF invoices_updt.SOURCE = 'US_OD_EXTENSITY' THEN
         fnd_file.put_line (fnd_file.LOG, '***** OD: Check Employee =' || v_employee_id || ' ' || SUBSTR 				(invoices_updt.attribute10, 5) || ' ' 
	         || v_vendor_site_id || ' ' || v_vendor_id ||  ' Invoice Num = ' || invoices_updt.invoice_num);            
         -- DEFECT 10805 Exclude vendors like AMEX
         IF (v_employee_id IS NOT NULL) THEN
             -- Defect 9971
             v_vendor_site_id := null;
             v_vendor_id := null;
	     ------------------------------------------------------------------------------
	     -- Create new supplier and bank info for OD employees using the Employee ID --
	     ------------------------------------------------------------------------------
             xx_po_employee_vendor_proc (v_employee_id,
                                           v_vendor_id,
                                           v_vendor_site_id
                                        );
             fnd_file.put_line (fnd_file.LOG, 'OD: Create Employee ' || v_employee_id || ' ' || v_vendor_site_id
                            || ' ' || v_vendor_id ||  ' Invoice Num = ' || invoices_updt.invoice_num);
         END IF;   --Defect 10805 IF (v_employee_id IS NOT NULL) THEN
	 -- Defect 3527 Org Id is missing in the Interface tables when Supplier is created using Employee Id
         BEGIN
           SELECT  org_id
             INTO  v_org_id
			 -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
             --FROM po_vendor_sites_all
			 FROM ap_supplier_sites_all
			 -- end of addition
            WHERE vendor_site_id = v_vendor_site_id;
         EXCEPTION
           WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.LOG, 'Error in deriving ORG ID for site_id = ' || v_vendor_site_id
                                || ' Invoice Id = ' || invoices_updt.invoice_id);
         END;
       END IF;   --ELSIF invoices_updt.SOURCE = 'US_OD_EXTENSITY' THEN

    	 ------------------------------------------------------
       -- Defect 19421 -Override Terms_name for specific Vendor.  If Vendor is in translation table use 
       -- the terms on the translation table
       ------------------------------------------------------

      IF invoices_updt.invoice_type_lookup_code <> 'STANDARD' THEN
       BEGIN
        SELECT xval.SOURCE_VALUE3
          INTO v_terms_name
          FROM xx_fin_translatevalues xval
              ,xx_fin_translatedefinition xdef
			  -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
              --,po_vendors   vend
			  ,ap_suppliers aps
			  --,po_vendor_sites_all vnst
			  ,ap_supplier_sites_all assa
			  -- end of addition
          WHERE xdef.translation_name =  'AP_RTV_PAY_TERM'
            AND xdef.translate_id = xval.translate_id
            and v_vendor_id = aps.vendor_id
            and v_vendor_site_id = assa.vendor_site_id
            AND aps.vendor_name = xval.SOURCE_VALUE1
            --AND invoices_updt.vendor_name = xval.SOURCE_VALUE1
            AND assa.vendor_site_code = NVL(xval.SOURCE_VALUE2, assa.vendor_site_code)
            AND invoices_updt.SOURCE = NVL(xval.SOURCE_VALUE4, invoices_updt.SOURCE) 
            AND trunc(SYSDATE) BETWEEN xval.START_DATE_ACTIVE  AND NVL (xval.end_date_active, trunc(sysdate));
       EXCEPTION
           when TOO_MANY_ROWS then
             fnd_file.put_line (fnd_file.LOG, 'More than one translation found for vendor = ' || 
                invoices_updt.vendor_name || ' Vendor site = ' || v_vendor_site_id 
                                          || ' Source = '       || invoices_updt.SOURCE); 
             -- send email to AP group if error found 
             l_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                               ,'XXODEMAILER'
                                               ,NULL
                                               ,SYSDATE
                                               ,FALSE
                                               ,'FC-EFT@officedepot.com'
                                               ,'More than one translation found for vendor'                        
                                               ,'More than one translation found for vendor ' || 
                invoices_updt.vendor_name || ' in Vendor site ' || v_vendor_site_id 
                                          || ' for Source '       || invoices_updt.SOURCE || 
                                          '.  Please correct the translation values.  Thanks.');  
              IF l_request_id = 0 THEN
               fnd_file.put_line
                        (fnd_file.LOG,
                         'The Concurrent Request Emailer Program Has Failed on RTV PAY TERM.' 
                        );
              ELSE
               fnd_file.put_line
                  (fnd_file.LOG,
                      'The Concurrent Request Emailer Program Has Been Submitted.  Request ID is   '
                   || l_request_id
                  );
              END IF;
           WHEN NO_DATA_FOUND THEN
             fnd_file.put_line (fnd_file.LOG, 'NOT AN ERROR-New Terms not found for ' || 
                invoices_updt.vendor_name || ' Vendor site = ' || v_vendor_site_id  || 'vendor id = ' || v_vendor_id 
                                          --|| ' Vendor site code = ' || vnst.vendor_site_code 
                                          || ' Source = '       || invoices_updt.SOURCE);
           WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.LOG, 'Error in deriving New Terms_name for vendor = ' || 
                invoices_updt.vendor_name || ' Vendor site = ' || v_vendor_site_id  || 'vendor id = ' || v_vendor_id 
                                          --|| ' Vendor site code = ' || vnst.vendor_site_code 
                                          || ' Source = '       || invoices_updt.SOURCE ||
                                          'Error Code : ' || SQLCODE || 'Error Message : '||SQLERRM);
       END;
       END IF;  
	   
	   -- Intialising the Terms Date, Goods Received Date and Invoice Received Date
	      ld_terms_date              :=  NVL (invoices_updt.terms_date,invoices_updt.invoice_date);
          ld_goods_received_date     :=  NVL (invoices_updt.goods_received_date,invoices_updt.invoice_date);
          ld_invoice_received_date   :=  NVL (invoices_updt.invoice_received_date,invoices_updt.invoice_date);
	   
       ------------------------------------------------------
       -- Adding changes for AP Trade Match --
       ------------------------------------------------------  
	   
	   IF invoices_updt.SOURCE IN ('US_OD_TDM',
	                               'US_OD_TRADE_EDI',
								   'US_OD_DCI_TRADE',
								   'US_OD_DROPSHIP',
								   'US_OD_RTV_CONSIGNMENT',
								   'US_OD_CONSIGNMENT_SALES',
								   'US_OD_INTEGRAL_ONLINE',
								   'US_OD_CONSIGN_INV',
								   'US_OD_VENDOR_PROGRAM',
								   'US_OD_RTV_MERCHANDISING')
	   THEN
			-- Initialise the PO Number 
	      invoices_updt.po_number := invoices_updt.po_number;
		  
	   END IF;
	   
       IF invoices_updt.SOURCE IN ('US_OD_TDM',
	                               'US_OD_TRADE_EDI',
								   'US_OD_DCI_TRADE',
								   'US_OD_DROPSHIP',
								   'MANUAL INVOICE ENTRY')
	      AND (invoices_updt.GROUP_ID IS NULL OR invoices_updt.GROUP_ID = 'TDM-TRADE')
		  AND invoices_updt.invoice_type_lookup_code = 'STANDARD'
	   THEN 
	        ld_terms_date            := NULL;
            ld_goods_received_date   := NULL;
            ld_invoice_received_date := NULL;
	      		  
	      -- To get the terms_date_basis
		  BEGIN 
		     lc_terms_date_basis := NULL;
			 
			 SELECT terms_date_basis 
			   INTO lc_terms_date_basis
			   FROM ap_supplier_sites_all
			  WHERE vendor_id = v_vendor_id
				AND vendor_site_id = v_vendor_site_id;
		  EXCEPTION
		    WHEN NO_DATA_FOUND
			 THEN
			    fnd_file.put_line(fnd_file.log,'No data found for the Supplier site match and Terms Data Basis '||SQLERRM);
				lc_terms_date_basis := NULL;
			WHEN OTHERS
			 THEN
			    fnd_file.put_line(fnd_file.log,'Unable to get the Supplier site match and Terms Data Basis '||SQLERRM);
				lc_terms_date_basis := NULL;
		  END;
				
		 -- To check the Vendor does not exist for the Invoice		
		   IF v_vendor_id IS NULL
		   THEN
				
		      XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => invoices_updt.invoice_id,
											p_invoice_num           => invoices_updt.invoice_num,
											p_vendor_id             => v_vendor_id ,
											p_vendor_site_id        => v_vendor_site_id,
											p_invoice_line_id       => null,
											p_invoice_line_num      => null,
											p_po_num                => invoices_updt.po_number,
											p_po_header_id          => null,
											p_po_line_id            => null,
											p_po_line_num           => null,
											p_exception_code        => 'E001',
											p_exception_description => 'Vendor/Vendor Site does not exists for the Invoice :'|| invoices_updt.invoice_num,
											p_process_flag          => 'N'
											);
		   END IF;
		   
		  -- To derive the Drop ship flag, Authorization status and closed code
		   BEGIN 
		     lc_po_type:= NULL;
			 lc_authorization_status := NULL;
			 lc_closed_code := NULL;
			 
			 IF invoices_updt.po_number LIKE '%-%'
			 THEN
			    SELECT attribute_category,authorization_status, closed_code,po_header_id
			      INTO lc_po_type, lc_authorization_status, lc_closed_code,ln_po_header_id
			      FROM po_headers_all
			     WHERE segment1 = invoices_updt.po_number;   --'POM-'||LPAD(invoices_updt.po_number,9,0);
			 ELSE
			    SELECT attribute_category,authorization_status, closed_code,po_header_id
			      INTO lc_po_type, lc_authorization_status, lc_closed_code,ln_po_header_id
			      FROM po_headers_all
			     WHERE NVL(SUBSTR(segment1, 0, INSTR(segment1, '-')-1),segment1)= invoices_updt.po_number;
			 END IF;
			  
		  EXCEPTION
		    WHEN NO_DATA_FOUND
			 THEN
			    fnd_file.put_line(fnd_file.log,'No data found for the Drop ship flag, Authorization status and closed code '||SQLERRM);
				lc_po_type:= NULL;
			    lc_authorization_status := NULL;
			    lc_closed_code := NULL;
				ln_po_header_id := NULL;
			WHEN OTHERS
			 THEN
			    fnd_file.put_line(fnd_file.log,'Unable to get the Drop ship flag, Authorization status and closed code '||SQLERRM);
				lc_po_type:= NULL;
			    lc_authorization_status := NULL;
			    lc_closed_code := NULL;
				ln_po_header_id := NULL;
		  END;
		  
		  -- Intialise the 
		   invoices_updt.attribute5 := lc_po_type;
		   
		  IF lc_po_type LIKE 'DropShip%'
		  THEN
		      lc_drop_ship_flag := 'Y';
		  ELSE 
		      lc_drop_ship_flag := 'N';
		  END IF;
		  
		  -- To get the 2-Way or 3-Way match
		  BEGIN 
		     lc_inspection_req_flag := NULL;
			 lc_receipt_req_flag := NULL;
			 
			 SELECT DISTINCT inspection_required_flag,receipt_required_flag 
			   INTO lc_inspection_req_flag, lc_receipt_req_flag
               FROM po_line_locations_all 
              WHERE po_header_id = ln_po_header_id;

		  EXCEPTION
		    WHEN NO_DATA_FOUND
			 THEN
			    fnd_file.put_line(fnd_file.log,'No data found for the Inspection Required Flag and Receipt Required Flag '||SQLERRM);
				lc_inspection_req_flag := NULL;
			    lc_receipt_req_flag := NULL;
			WHEN OTHERS
			 THEN
			    fnd_file.put_line(fnd_file.log,'Unable to get the Inspection Required Flag and Receipt Required Flag '||SQLERRM);
				lc_inspection_req_flag := NULL;
			    lc_receipt_req_flag := NULL;
		  END;
		  
		  -- To get the 2-Way or 3-Way match
		  IF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'N'
		  THEN
		       lc_match_type := '2-Way';
		  ELSIF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'Y'
		  THEN
		       lc_match_type := '3-Way';
		  END IF;
		 
         -- Invalid PO, Status is CLOSED/ NOT Approved for the Invoice		 
		  IF (lc_closed_code IN ('CLOSED','FINALLY CLOSED') OR lc_authorization_status <> 'APPROVED')
		  THEN
		  
		    XX_INSERT_AP_TR_MATCH_EXCEPNS  (p_invoice_id            => invoices_updt.invoice_id,
											p_invoice_num           => invoices_updt.invoice_num,
											p_vendor_id             => v_vendor_id ,
											p_vendor_site_id        => v_vendor_site_id,
											p_invoice_line_id       => null,
											p_invoice_line_num      => null,
											p_po_num                => invoices_updt.po_number,
											p_po_header_id          => null,
											p_po_line_id            => null,
											p_po_line_num           => null,
											p_exception_code        => 'E002',
											p_exception_description => 'Invalid PO, Status is CLOSED/NOT Approved for the Invoice :'|| invoices_updt.invoice_num,
											p_process_flag          => 'N'
											);
		  END IF;
		  
		 -- If PO does not exist
		  IF invoices_updt.po_number IS NULL
		  THEN
		     
			XX_INSERT_AP_TR_MATCH_EXCEPNS  (p_invoice_id            => invoices_updt.invoice_id,
											p_invoice_num           => invoices_updt.invoice_num,
											p_vendor_id             => v_vendor_id ,
											p_vendor_site_id        => v_vendor_site_id,
											p_invoice_line_id       => null,
											p_invoice_line_num      => null,
											p_po_num                => invoices_updt.po_number,
											p_po_header_id          => null,
											p_po_line_id            => null,
											p_po_line_num           => null,
											p_exception_code        => 'E004',
											p_exception_description => 'Invalid PO for the Invoice :'|| invoices_updt.invoice_num,
											p_process_flag          => 'N'
											);
		  END IF;
		  
		  -- Calling  XX_AP_TR_TERMS_DATE procedure to get the terms_date, goods received date and Invoice received date 
		  XX_AP_TR_TERMS_DATE ( p_invoice_num            =>  invoices_updt.invoice_num,
		                        p_invoice_id             =>  invoices_updt.invoice_id,
                                p_sup_site_terms_basis   =>  lc_terms_date_basis,
								p_match_type             =>  lc_match_type,
								p_drop_ship_flag         =>  lc_drop_ship_flag,
								p_po_num                 =>  invoices_updt.po_number,
								p_invoice_date           =>  invoices_updt.invoice_date,
								p_inv_creation_date      =>  invoices_updt.creation_date,
								p_terms_date             =>  ld_terms_date,
								p_goods_received_date    =>  ld_goods_received_date,
								p_invoice_received_date  =>  ld_invoice_received_date
							   );
		
	   END IF;  
-- End of changes for AP Trade Match	

     /* Added for E3522 -- If the PO is Dropship, then we are updating the source to Dropship for the EDI and TDM Sources */
    IF invoices_updt.source IN ('US_OD_TDM','US_OD_TRADE_EDI')
       AND (invoices_updt.group_id IS NULL OR invoices_updt.group_id = 'TDM-TRADE')
    THEN 
	    lc_po_type := NULL;

		BEGIN
    		SELECT attribute_category
    		  INTO lc_po_type
    		  FROM po_headers_all
    		 WHERE segment1 = invoices_updt.po_number; 
	    EXCEPTION
			WHEN OTHERS
			THEN
			   lc_po_type := NULL;
		END;
    	
    	IF lc_po_type LIKE 'DropShip%'  
    	THEN
		    IF invoices_updt.source = 'US_OD_TDM'
			THEN
                invoices_updt.source := 'US_OD_DROPSHIP';
    		    invoices_updt.attribute7 := 'US_OD_DROPSHIP';
    		    invoices_updt.attribute2 := NULL;
    		    invoices_updt.group_id := NULL;  
				
            ELSIF invoices_updt.source = 'US_OD_TRADE_EDI'
            THEN
			    invoices_updt.source := 'US_OD_DROPSHIP';
    		    invoices_updt.attribute7 := 'US_OD_DROPSHIP';
    		    invoices_updt.attribute2 := 'Y';
    		    invoices_updt.group_id := NULL; 
			END IF;
    	END IF; -- lc_po_type LIKE 'DropShip%' 
    END IF;
	/* End of E3522 Changes */
	   	  	       
       ------------------------------------------------------
       -- Copies the non-duplicate invoice header records --
       ------------------------------------------------------
       BEGIN
  --	 fnd_file.put_line (fnd_file.LOG, 'Before Header Insert: SiteId=' || v_vendor_site_id
	 --                                || ' Invoice Num = ' ||invoices_updt.invoice_num);
    INSERT 
	   INTO ap_invoices_interface
                           (invoice_id,
                            invoice_num,
                            invoice_type_lookup_code,
                            invoice_date,
                            po_number, vendor_id,
                            vendor_num,
                            vendor_name, vendor_site_id,
                            vendor_site_code,
                            invoice_amount,
                            invoice_currency_code,
                            terms_id,
                            terms_name,
                            description, last_update_date, last_updated_by,
                            last_update_login, creation_date, created_by,
                            attribute_category,
                            attribute1,
                            attribute2,
                            attribute3,
                            attribute4,
                            attribute5,
                            attribute6, attribute7,
                            attribute8,
                            attribute9,
                            attribute10,
                            attribute11,
                            attribute12,
                            attribute13,
                            attribute14,
                            attribute15, SOURCE,
							status, -- Added for the Trade Match 
                            GROUP_ID,
                            payment_currency_code,
                            voucher_num,
							-- Commented and added by Darshini for R12 Upgrade Retrofit
                            --payment_method_lookup_code,
							payment_method_code,
							-- end of addition
                            pay_group_lookup_code,
                            goods_received_date,
                            invoice_received_date,
                            gl_date,
                            accts_pay_code_combination_id,
                            exclusive_payment_flag, org_id,
                            amount_applicable_to_discount,
                            vendor_email_address,
                            terms_date,
                            external_doc_ref
                           )
         VALUES 	   (invoices_updt.invoice_id,
                            DECODE(p_source,'US_OD_PCARD',gc_pcard_acct_num,invoices_updt.invoice_num),  --CR894
                            invoices_updt.invoice_type_lookup_code,
                            NVL (invoices_updt.invoice_date, SYSDATE),
                            invoices_updt.po_number, v_vendor_id, -- vendor id
                            invoices_updt.vendor_num,
                            invoices_updt.vendor_name, v_vendor_site_id,
                            -- vendor_site_id
                            invoices_updt.vendor_site_code,
                            invoices_updt.invoice_amount,
                            invoices_updt.invoice_currency_code,
                            invoices_updt.terms_id,                 -- term_id
                            NVL (v_terms_name, invoices_updt.terms_name),
                            --terms_name
                            invoices_updt.description, SYSDATE,
                                                               --last_update_date
                                                               v_user_id,
                            --last_updated_by
                            NULL,                          --last_update_login
                                 SYSDATE,                      --creation_date
                                         v_user_id,               --created_by
                            invoices_updt.attribute_category,
                            invoices_updt.attribute1,
                            invoices_updt.attribute2,
                            invoices_updt.attribute3,
                            invoices_updt.attribute4,
                            invoices_updt.attribute5,
                            invoices_updt.attribute6, invoices_updt.SOURCE,
			    --attribute7,   Modified by Anamitra Banerjee to eliminate custom Event Alerts in AP
                            invoices_updt.attribute8,
                            DECODE (invoices_updt.attribute9,
                                    '0', NULL,
                                    invoices_updt.attribute9
                                   ),
                            DECODE (invoices_updt.SOURCE,                   -- Added Decode per defect 444
                                    'US_OD_EXTENSITY', NULL,                -- NULL out attribute10   
                                     invoices_updt.attribute10),  
                            invoices_updt.attribute11,
                            invoices_updt.attribute12,
                            invoices_updt.attribute13,
                            invoices_updt.attribute14,
                            invoices_updt.attribute15, invoices_updt.SOURCE,
							invoices_updt.status,
                            invoices_updt.GROUP_ID,
                            invoices_updt.payment_currency_code,
                            invoices_updt.voucher_num,
                            DECODE(invoices_updt.source,'US_OD_CONSIGNMENT_SALES',lc_pymnt_mthd_cd,invoices_updt.payment_method_lookup_code), -- Defect 31882
                            invoices_updt.pay_group_lookup_code,
--                            NVL (invoices_updt.goods_received_date,
--                                 invoices_updt.invoice_date
--                                ),                       --goods_received_date
                            ld_goods_received_date,
                            --NVL (-- INVOICES_UPDT.TERMS_DATE, removed per CR729
                            --     invoices_updt.goods_received_date, --added per CRC279
                            --     invoices_updt.invoice_date/
                            --    ),
                               -- Defect 2053 goods_received_date = Terms date
							ld_invoice_received_date,
                            --NVL (invoices_updt.invoice_received_date,
                            --     invoices_updt.invoice_date
                            --    ), -- invoice_received_date
                            NULL,  -- Defect 9600 SYSDATE,          --gl_date,
                            invoices_updt.accts_pay_code_combination_id,
                            invoices_updt.exclusive_payment_flag, v_org_id,
                            invoices_updt.amount_applicable_to_discount,
                            invoices_updt.vendor_email_address,
                            NVL(ld_terms_date,invoices_updt.invoice_date),
							--NVL (invoices_updt.terms_date,
                            --     invoices_updt.invoice_date
                            --    ),                                --terms date
                            invoices_updt.external_doc_ref
                           );
--               COMMIT;   defect 6028
       EXCEPTION
         WHEN OTHERS THEN
	   --lc_error_flag := 'Y';
           fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_INTERFACE '||SQLERRM);   
           lc_error_loc := 'Unable to insert Invoice Number  ';
           fnd_message.set_name ('XXFIN',' XX_AP_0004_ERROR_NO_INSERT_HEADER ');
           fnd_message.set_token ('ERR_LOC', lc_error_loc);
           fnd_message.set_token ('ERR_DEBUG',
                                            'Invoice Number:  '
                                         || invoices_updt.invoice_num
                                         || '  for OD Global Vendor ID:  '
                                         || invoices_updt.attribute10
                                        );
           fnd_message.set_token ('ERR_ORA', SQLERRM);
           lc_loc_err_msg := fnd_message.get;
           fnd_file.put_line (fnd_file.LOG,  'Unable to insert Invoice Number  '       
                                         || invoices_updt.invoice_num
                                         || '  for OD Global Vendor ID:  '
                                         || invoices_updt.attribute10
                                        );
           xx_com_error_log_pub.log_error
                            (p_program_type           => 'CONCURRENT PROGRAM',
                             p_program_name           => 'XXAPINVINTFC',
                             p_module_name            => 'AP',
                             p_error_location         => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                             p_error_message_count    => 1,
                             p_error_message_code     => 'E',
                             p_error_message          => lc_loc_err_msg,
                             p_error_message_severity => 'Major',
                             p_notify_flag            => 'N',
                             p_object_type            => 'Processing AP Inbound invoices'
                            );
       END;
       -- fnd_file.put_line (fnd_file.LOG, 'After Header Insert: SiteId=' || v_vendor_site_id
       -- 	|| ' Invoice Num = ' ||invoices_updt.invoice_num);
       ------------------------------------------------------
       -- Updates invoice header records that are processed --
       ------------------------------------------------------
       UPDATE xx_ap_inv_interface_stg
          SET global_attribute16 = 'PROCESSED'
        WHERE invoice_id = invoices_updt.invoice_id;
       --            COMMIT;  defect 6028
       IF (lc_error_flag = 'N')  THEN
          FOR inv_lines_updt IN c3 (invoices_updt.invoice_id)
          LOOP
            lc_company := NULL;
            v_ccid := NULL;
            v_error_message := NULL;
            -- Defect 9909 Blank the PO Number for Expense EDI
            IF invoices_updt.SOURCE = 'US_OD_EXPENSE_EDI' THEN
               inv_lines_updt.po_number := null ;   
               inv_lines_updt.po_line_id := null ;   
               inv_lines_updt.po_line_number := null ;   
            END IF;
            IF (inv_lines_updt.dist_code_concatenated IS NOT NULL) THEN -- Added as per the Defect Id 2410
               BEGIN
		 ------------------------------------------------------------
		 -- Deriving the GL Company segment from GL Location segment --
                 IF     inv_lines_updt.oracle_gl_location IS NOT NULL
                    AND inv_lines_updt.oracle_gl_company IS NULL       THEN
	            /* Lookup the company default value for this location */
                    lc_company := xx_gl_translate_utl_pkg.derive_company_from_location 				  				  		  (inv_lines_updt.oracle_gl_location, v_org_id);
                    inv_lines_updt.dist_code_concatenated :=lc_company||inv_lines_updt.dist_code_concatenated;
                    fnd_file.put_line(fnd_file.LOG,
                                             'ODP (Company=NULL) DIST_CD_CONCAT: '
                                            || inv_lines_updt.dist_code_concatenated
                                            || ' for Invoice:'
                                            || inv_lines_updt.invoice_id
                                            || ' and Location:'
                                            || inv_lines_updt.oracle_gl_location
                                            );
                 END IF;
                 SELECT gsb.chart_of_accounts_id
                   INTO lc_coa_id
                   FROM gl_sets_of_books_v gsb
                  WHERE gsb.set_of_books_id =fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
                 lc_gl_segment1 := SUBSTR(inv_lines_updt.dist_code_concatenated,1,4);
                 lc_gl_segment2 := SUBSTR(inv_lines_updt.dist_code_concatenated,6,5);
                 lc_gl_segment3 := SUBSTR(inv_lines_updt.dist_code_concatenated,12,8);
                 lc_gl_segment4 := SUBSTR(inv_lines_updt.dist_code_concatenated,21,6);
                 lc_gl_segment5 := SUBSTR(inv_lines_updt.dist_code_concatenated,28,4);
                 lc_gl_segment6 := SUBSTR(inv_lines_updt.dist_code_concatenated,33,2);
                 lc_gl_segment7 := SUBSTR(inv_lines_updt.dist_code_concatenated,36,6);
		 -- defect 6024 
		 IF (   SUBSTR(inv_lines_updt.dist_code_concatenated,12,1) = '1'
                     OR SUBSTR(inv_lines_updt.dist_code_concatenated,12,1) = '2'
                     OR SUBSTR(inv_lines_updt.dist_code_concatenated,12,1) = '3'
                     OR SUBSTR(inv_lines_updt.dist_code_concatenated,12,1) = '4'
                     OR SUBSTR(inv_lines_updt.dist_code_concatenated,12,1) = '5'
                    )   THEN
		    --fnd_file.put_line (fnd_file.LOG, 'Cost Center: ' || lc_gl_segment2 || ' has been modified to 00000.');
                    lc_gl_segment2 := '00000';                       
                  END IF;
		  -- fnd_file.put_line (fnd_file.LOG, 'Company:' || lc_gl_segment1);
		  -- fnd_file.put_line (fnd_file.LOG, 'Cost Center: ' || lc_gl_segment2);
		  -- fnd_file.put_line (fnd_file.LOG, 'Account: ' || lc_gl_segment3);
		  -- fnd_file.put_line (fnd_file.LOG, 'Location: ' || lc_gl_segment4);
		  -- fnd_file.put_line (fnd_file.LOG, 'Inter Company: ' || lc_gl_segment5);
		  -- fnd_file.put_line (fnd_file.LOG, 'LOB: ' || lc_gl_segment6);
		  -- fnd_file.put_line (fnd_file.LOG, 'Future: ' || lc_gl_segment7);
		  --  defect 6024         v_full_gl_code := inv_lines_updt.dist_code_concatenated;
		  v_full_gl_code := lc_gl_segment1 || '.' || 
                                    lc_gl_segment2 || '.' ||
                                    lc_gl_segment3 || '.' ||
                                    lc_gl_segment4 || '.' ||
                                    lc_gl_segment5 || '.' ||
                                    lc_gl_segment6 || '.' ||
                                    lc_gl_segment7 ;
		  fnd_file.put_line (fnd_file.LOG,'0. v_full_gl_code=' || v_full_gl_code);       --PJM                                     
		  -- end of defect 6024                                          
                  BEGIN
		    SELECT /*+ INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */ 
			  	code_combination_id -- Added Hint for QC Defect 16589
                      INTO v_ccid
                      FROM gl_code_combinations
                     WHERE chart_of_accounts_id = lc_coa_id
                       AND segment1 = lc_gl_segment1
                       AND segment2 = lc_gl_segment2
                       AND    segment3 = lc_gl_segment3
                       AND    segment4 = lc_gl_segment4
                       AND    segment5 = lc_gl_segment5
                       AND    segment6 = lc_gl_segment6
                       AND    segment7 = lc_gl_segment7;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      v_error_message :='Invalid code combinations from DIST_CODE_CONCATENATED';
                  END;
                  fnd_file.put_line (fnd_file.LOG,'ODP CCID: ' || v_ccid);   --PJM
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
	           --defect 5600
                   v_full_gl_code := inv_lines_updt.dist_code_concatenated;
                   fnd_file.put_line (fnd_file.LOG,'3. v_full_gl_code=' || v_full_gl_code);
                   fnd_file.put_line
                   (fnd_file.LOG,
                                         'EXCEPTION: ODP (Company=NULL) DIST_CD_CONCAT: '
                                      || inv_lines_updt.dist_code_concatenated
                                      || ' for Invoice:'
                                      || inv_lines_updt.invoice_id
                                      || ' and Location:'
                                      || inv_lines_updt.oracle_gl_location
                                     );                        
                   lc_error_loc :='Error deriving the GL Company segment from GL Location segment';
                   fnd_message.set_name('XXFIN',' XX_AP_0003_ERROR_NO_COMPANY ');
                   fnd_message.set_token ('ERR_LOC', lc_error_loc);
                   fnd_message.set_token
                                         ('ERR_DEBUG',
                                             'Location:  '
                                          || inv_lines_updt.oracle_gl_location
                                          || '  for OD Global Vendor ID:  '
                                          || inv_lines_updt.od_global_vendor_id
                                         );
                   fnd_message.set_token ('ERR_ORA', SQLERRM);
                   lc_loc_err_msg := fnd_message.get;
                   fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                   xx_com_error_log_pub.log_error
                              (p_program_type            => 'CONCURRENT PROGRAM',
                               p_program_name            => 'XXAPINVINTFC',
                               p_module_name             => 'AP',
                               p_error_location          => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                               p_error_message_count     => 1,
                               p_error_message_code      => 'E',
                               p_error_message           => lc_loc_err_msg,
                               p_error_message_severity  => 'Major',
                               p_notify_flag             => 'N',
                               p_object_type             => 'Processing AP Inbound invoices'
                              );                        
		   --  end of defect                          
                 WHEN OTHERS THEN
                   lc_error_loc :='Error deriving the GL Company segment from GL Location segment';
                   fnd_message.set_name('XXFIN',' XX_AP_0003_ERROR_NO_COMPANY ');
                   fnd_message.set_token ('ERR_LOC', lc_error_loc);
                   fnd_message.set_token
                                         ('ERR_DEBUG',
                                             'Location:  '
                                          || inv_lines_updt.oracle_gl_location
                                          || '  for OD Global Vendor ID:  '
                                          || inv_lines_updt.od_global_vendor_id
                                         );
                   fnd_message.set_token ('ERR_ORA', SQLERRM);
                   lc_loc_err_msg := fnd_message.get;
                   fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                   xx_com_error_log_pub.log_error
                              (p_program_type            => 'CONCURRENT PROGRAM',
                               p_program_name            => 'XXAPINVINTFC',
                               p_module_name             => 'AP',
                               p_error_location          => 'Error at '|| SUBSTR(lc_error_loc,1,50),
                               p_error_message_count     => 1,
                               p_error_message_code      => 'E',
                               p_error_message           => lc_loc_err_msg,
                               p_error_message_severity  => 'Major',
                               p_notify_flag             => 'N',
                               p_object_type             => 'Processing AP Inbound invoices'
                              );
               END;
            ELSE   -- IF (inv_lines_updt.dist_code_concatenated IS NOT NULL) THEN -- Added as per the Defect Id 2410
	      ----------------------------------------------------------------------------------
	      --  Call PS GL Code translation package to return GL code combinations and CCID --
	      ----------------------------------------------------------------------------------
              --Check if the the DIST_CODE_CONCAT IS NULL THEN LOOK FOR PS translate
              xx_cnv_gl_psfin_pkg.translate_ps_values
                        (inv_lines_updt.legacy_segment1   --p_ps_business_unit
                                                       ,
                         inv_lines_updt.legacy_segment3      --p_ps_department
                                                       ,
                         inv_lines_updt.legacy_segment5         --p_ps_account
                                                       ,
                         inv_lines_updt.legacy_segment2  --p_ps_operating_unit
                                                       ,
                         NULL                                 --p_ps_affiliate
                             ,
                         inv_lines_updt.legacy_segment4   --p_ps_sales_channel
                                                       ,
                         'NO'                      --p_use_stored_combinations
                             ,
                         'NO'                           --p_convert_gl_history
                             ,
                         x_seg1_company,
                         x_seg2_costctr,
                         x_seg3_account,
                         x_seg4_location,
                         x_seg5_interco,
                         x_seg6_lob,
                         x_seg7_future,
                         x_ccid,
                         x_error_message,
                         'NO',                                  -- defect 2362
                         v_org_id                               -- defect 2362
                        );
              v_ccid := x_ccid;
	      -- defect 6024 
              IF (    SUBSTR(inv_lines_updt.legacy_segment5,1,1) = '1'
                  OR  SUBSTR(inv_lines_updt.legacy_segment5,1,1) = '2'
                  OR  SUBSTR(inv_lines_updt.legacy_segment5,1,1) = '3'
                  OR  SUBSTR(inv_lines_updt.legacy_segment5,1,1) = '4'
                  OR  SUBSTR(inv_lines_updt.legacy_segment5,1,1) = '5'
                 )     THEN
		 --fnd_file.put_line (fnd_file.LOG, 'Cost Center from xx_cnv_gl_psfin_pkg.translate_ps_values: ' 				 --|| x_seg2_costctr || ' has been modified to 00000.');
	         x_seg2_costctr := '00000';                       
                 v_ccid := null;
              END IF;                        
	      -- end of defect                      
              v_full_gl_code :=x_seg1_company || '.'|| 
			       x_seg2_costctr || '.'||
			       x_seg3_account || '.'||
			       x_seg4_location|| '.'||
			       x_seg5_interco || '.'|| 
			       x_seg6_lob    || '.' ||
			       x_seg7_future;
	      -- fnd_file.put_line (fnd_file.LOG,'1. v_full_gl_code=' || v_full_gl_code);
            END IF; -- IF (inv_lines_updt.dist_code_concatenated IS NOT NULL) THEN -- Added as per the Defect Id 2410
            -- Added as per the Defect Id 2410
            IF (x_error_message IS NOT NULL)  THEN
                v_error_message := SUBSTR (x_error_message, 1, 240);
            END IF;
            -----------------------------------------------------------------------
            -- Only lookup the project related data if there is a project number --
            -----------------------------------------------------------------------
            IF inv_lines_updt.global_attribute19 IS NULL THEN
               v_expenditure_item_date := NULL;
               v_expenditure_org_id := NULL;
               v_expenditure_type := NULL;
               v_project_id := NULL;
               v_task_id := NULL;
            ELSE
              BEGIN
  		-------------------------------------------------
	        -- Deriving the Project ID from Project Number --
	        -------------------------------------------------
	        -- CR 388 defect 6682
                v_full_gl_code := null;
                v_ccid := null;    
	        -- fnd_file.put_line (fnd_file.LOG,'2. v_full_gl_code=' || v_full_gl_code);
                v_project_id := NULL;
                SELECT xx_ap_inv_validate_pkg.f_project_inbound
                                               (inv_lines_updt.global_attribute19)
                  INTO v_project_id
                  FROM xx_ap_inv_lines_interface_stg
                 WHERE invoice_id = inv_lines_updt.invoice_id
                   AND invoice_line_id = inv_lines_updt.invoice_line_id;
              EXCEPTION
                WHEN OTHERS THEN
                  lc_error_loc :='Error deriving the Project ID from Project Number';
                  fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_NO_PROJECT ');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token
                                            ('ERR_DEBUG',
                                                'Project Number:  '
                                             || inv_lines_updt.global_attribute19
                                             || '  for OD Global Vendor ID:  '
                                             || inv_lines_updt.od_global_vendor_id
                                            );
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_loc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, 'Error deriving the Project ID from '
                                             ||   'Project Number:  '
                                             || inv_lines_updt.global_attribute19
                                             || '  for OD Global Vendor ID:  '
                                             || inv_lines_updt.od_global_vendor_id
                                            );                           
                  xx_com_error_log_pub.log_error
                               (p_program_type                => 'CONCURRENT PROGRAM',
                                p_program_name                => 'XXAPINVINTFC',
                                p_module_name                 => 'AP',
                                p_error_location              =>    'Error at '
                                                                 || SUBSTR
                                                                       (lc_error_loc,
                                                                        1,
                                                                        50
                                                                       ),
                                p_error_message_count         => 1,
                                p_error_message_code          => 'E',
                                p_error_message               => lc_loc_err_msg,
                                p_error_message_severity      => 'Major',
                                p_notify_flag                 => 'N',
                                p_object_type                 => 'Processing AP Inbound invoices'
                               );
              END;
              BEGIN
	        -------------------------------------------------------------------------
	        -- Deriving the Task ID from a combined Project Number and Task Number --
	        -------------------------------------------------------------------------
                v_task_id := NULL;
                SELECT xx_ap_inv_validate_pkg.f_task_inbound
                                              (inv_lines_updt.global_attribute20,
                                               inv_lines_updt.global_attribute19
                                              )
                  INTO v_task_id
                  FROM xx_ap_inv_lines_interface_stg
                 WHERE invoice_id = inv_lines_updt.invoice_id
                   AND invoice_line_id = inv_lines_updt.invoice_line_id;
              EXCEPTION
                WHEN OTHERS THEN
                  lc_error_loc :='Error deriving the Task ID from Project Number and Task Number';
                  fnd_message.set_name ('XXFIN',' XX_AP_0003_ERROR_NO_TASK ');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_DEBUG',
                                              'Project Number and Task Number:  '
                                           || inv_lines_updt.global_attribute19
                                           || '  -   '
                                           || inv_lines_updt.global_attribute20
                                           || '  for OD Global Vendor ID:  '
                                           || inv_lines_updt.od_global_vendor_id
                                          );
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_loc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                  xx_com_error_log_pub.log_error
                               (p_program_type                => 'CONCURRENT PROGRAM',
                                p_program_name                => 'XXAPINVINTFC',
                                p_module_name                 => 'AP',
                                p_error_location              =>    'Error at '
                                                                 || SUBSTR
                                                                       (lc_error_loc,
                                                                        1,
                                                                        50
                                                                       ),
                                p_error_message_count         => 1,
                                p_error_message_code          => 'E',
                                p_error_message               => lc_loc_err_msg,
                                p_error_message_severity      => 'Major',
                                p_notify_flag                 => 'N',
                                p_object_type                 => 'Processing AP Inbound invoices'
                               );
              END;
              v_expenditure_item_date := inv_lines_updt.invoice_date;
              BEGIN
		----------------------------------------------------------
		-- Deriving Expenditure Org Name from Expenditure Org ID  --
		----------------------------------------------------------
                v_expenditure_org_id := NULL;
		-- CR 388 Added NVL statement
	        SELECT xx_ap_inv_validate_pkg.f_exp_org_name_inbound
                                         (nvl(inv_lines_updt.global_attribute18,inv_lines_updt.oracle_gl_cost_center))
                  INTO v_expenditure_org_id
                  FROM xx_ap_inv_lines_interface_stg
                 WHERE invoice_id = inv_lines_updt.invoice_id
                   AND invoice_line_id =inv_lines_updt.invoice_line_id;
              EXCEPTION
                WHEN OTHERS THEN
                  lc_error_loc :='Error deriving the Expenditure Org Name from Expenditure Org ID';
                  fnd_message.set_name('XXFIN',' XX_AP_0003_ERROR_NO_EXP_ORG ');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token
                                         ('ERR_DEBUG',
                                             'Expenditure Org Name:  '
                                          || inv_lines_updt.global_attribute18
                                          || '  for OD Global Vendor ID:  '
                                          || inv_lines_updt.od_global_vendor_id
                                         );
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_loc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                  xx_com_error_log_pub.log_error
                              (p_program_type                => 'CONCURRENT PROGRAM',
                               p_program_name                => 'XXAPINVINTFC',
                               p_module_name                 => 'AP',
                               p_error_location              =>    'Error at '
                                                                || SUBSTR
                                                                      (lc_error_loc,
                                                                       1,
                                                                       50
                                                                      ),
                               p_error_message_count         => 1,
                               p_error_message_code          => 'E',
                               p_error_message               => lc_loc_err_msg,
                               p_error_message_severity      => 'Major',
                               p_notify_flag                 => 'N',
                               p_object_type                 => 'Processing AP Inbound invoices'
                              );
              END;
	      ------------------------------------------------------------
	      -- If no value was passed then derive the Expenditure Type from GL Account segment --
	      ------------------------------------------------------------
              IF inv_lines_updt.expenditure_type IS NULL THEN
                 BEGIN
		   --fnd_file.put_line(fnd_file.LOG,'Deriving the Expenditure Type from GL Account segment');
  	           v_expenditure_type := NULL;
                   SELECT xx_ap_inv_validate_pkg.f_exp_type_inbound
                                          (NVL (inv_lines_updt.oracle_gl_account,
                                                x_seg3_account
                                               )
                                          )
                      INTO v_expenditure_type
                      FROM xx_ap_inv_lines_interface_stg
                     WHERE invoice_id = inv_lines_updt.invoice_id
                       AND invoice_line_id =inv_lines_updt.invoice_line_id;
                   IF v_expenditure_type = 'MULTIPLE' THEN
                      v_expenditure_type :=inv_lines_updt.expenditure_type;
                      fnd_file.put_line(fnd_file.LOG,
                                         'Multiple values for Expenditure Type='
                                      || inv_lines_updt.expenditure_type
                                      || ' has been found.'
                                     );
                      -- Defect 2362 Send the original expenditure type if you find multiple values 
                   END IF;
                 EXCEPTION
                   WHEN OTHERS THEN
                     lc_error_loc :='Error deriving the Expenditure Type from GL Account segment';
                     fnd_message.set_name('XXFIN',' XX_AP_0003_ERROR_NO_EXP_TYPE ');
                     fnd_message.set_token ('ERR_LOC', lc_error_loc);
                     fnd_message.set_token
                                        ('ERR_DEBUG',
                                            'Expenditure Type:  '
                                         || NVL
                                               (inv_lines_updt.oracle_gl_account,
                                                x_seg3_account
                                               )
                                         || '  for OD Global Vendor ID:  '
                                         || inv_lines_updt.od_global_vendor_id
                                        );
                     fnd_message.set_token ('ERR_ORA', SQLERRM);
                     lc_loc_err_msg := fnd_message.get;
                     fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                     xx_com_error_log_pub.log_error
                                 (p_program_type                => 'CONCURRENT PROGRAM',
                                  p_program_name                => 'XXAPINVINTFC',
                                  p_module_name                 => 'AP',
                                  p_error_location              =>    'Error at '
                                                                   || SUBSTR
                                                                         (lc_error_loc,
                                                                          1,
                                                                          50
                                                                         ),
                                  p_error_message_count         => 1,
                                  p_error_message_code          => 'E',
                                  p_error_message               => lc_loc_err_msg,
                                  p_error_message_severity      => 'Major',
                                  p_notify_flag                 => 'N',
                                  p_object_type                 => 'Processing AP Inbound invoices'
                                 );
                 END;
              ELSE   --               IF inv_lines_updt.expenditure_type IS NULL THEN
                       --Expenditure type value was passed, use it
                v_expenditure_type := inv_lines_updt.expenditure_type;
              END IF;
            END IF;   -- End of ELSE
            BEGIN
  	      ------------------------------------------------------
		-- Deriving the Canadian Tax code from the Province --
	      ------------------------------------------------------
              v_province := NULL;
              v_tax_code := NULL;
	      -- Change for defect 2102 for Canadian Tax Code
              SELECT tax_code
                INTO v_tax_code
                FROM xx_ap_inv_lines_interface_stg
               WHERE invoice_id = inv_lines_updt.invoice_id
                 AND invoice_line_id = inv_lines_updt.invoice_line_id;
              IF inv_lines_updt.SOURCE != 'US_OD_UTILITIES' THEN
	         IF (    SUBSTR (v_tax_code, 1, 3) = 'PST'
                      OR SUBSTR (v_tax_code, 1, 1) = 'Q'
                    )                         THEN
		     SELECT province
                       INTO v_province
					   -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
                       --FROM po_vendor_sites_all
					   FROM ap_supplier_sites_all
					   -- end of addition
                      WHERE vendor_site_id =inv_lines_updt.od_global_vendor_id
                         OR vendor_site_id =(SELECT xx_po_global_vendor_pkg.f_translate_inbound
                                                (inv_lines_updt.od_global_vendor_id
                                                )
                                               FROM DUAL);
                 END IF;
              END IF;
              IF v_province IS NOT NULL THEN
                 xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               ('AP_CA_PROVINCE_TAX_CODES'  --translation_name
                                                          ,
                                SYSDATE,
                                v_province                     --source_value1
                                          ,
                                NULL                           --source_value2
                                    ,
                                NULL                           --source_value3
                                    ,
                                NULL                           --source_value4
                                    ,
                                NULL                           --source_value5
                                    ,
                                NULL                           --source_value6
                                    ,
                                NULL                           --source_value7
                                    ,
                                NULL                           --source_value8
                                    ,
                                NULL                           --source_value9
                                    ,
                                NULL                          --source_value10
                                    ,
                                x_target_value1,
                                x_target_value2,
                                x_target_value3,
                                x_target_value4,
                                x_target_value5,
                                x_target_value6,
                                x_target_value7,
                                x_target_value8,
                                x_target_value9,
                                x_target_value10,
                                x_target_value11,
                                x_target_value12,
                                x_target_value13,
                                x_target_value14,
                                x_target_value15,
                                x_target_value16,
                                x_target_value17,
                                x_target_value18,
                                x_target_value19,
                                x_target_value20,
                                x_error_message
                               );
                        v_tax_code := x_target_value1;
              END IF;  --               IF v_province IS NOT NULL THEN
            EXCEPTION
              WHEN OTHERS THEN
                lc_error_loc :='Error deriving the Canadian Tax Code';
                fnd_message.set_name('XXFIN',' XX_AP_0003_ERROR_NO_TAX_CODE ');
                fnd_message.set_token ('ERR_LOC', lc_error_loc);
                fnd_message.set_token
                                           ('ERR_DEBUG',
                                               'OD Global Vendor ID:  '
                                            || inv_lines_updt.od_global_vendor_id
                                           );
                fnd_message.set_token ('ERR_ORA', SQLERRM);
                lc_loc_err_msg := fnd_message.get;
                fnd_file.put_line (fnd_file.LOG, 'Error deriving the Canadian Tax Code'
                                           ||   ' OD Global Vendor ID:  '
                                            || inv_lines_updt.od_global_vendor_id
                                           );                        
                xx_com_error_log_pub.log_error
                            (p_program_type                => 'CONCURRENT PROGRAM',
                             p_program_name                => 'XXAPINVINTFC',
                             p_module_name                 => 'AP',
                             p_error_location              =>    'Error at '
                                                              || SUBSTR
                                                                    (lc_error_loc,
                                                                     1,
                                                                     50
                                                                    ),
                             p_error_message_count         => 1,
                             p_error_message_code          => 'E',
                             p_error_message               => lc_loc_err_msg,
                             p_error_message_severity      => 'Major',
                             p_notify_flag                 => 'N',
                             p_object_type                 => 'Processing AP Inbound invoices'
                            );
            END;
	   -- defect 2109
	   -- Identify the RETAIL LEASE line as SOURCE= 'US_OD_RENT'
	   -- Recalculate the invoice line Amount value by subtracting the tax amount value in 
	   -- global_attribute13 from the value in the AMOUNT column.
	   -- Create a second invoice line for any invoice line that has a value populated 
	   -- in the global_attribute13 column.
	   -- The second line should have a value of TAX in the ITEM_TYPE_LOOKUP_CODE, 
	   -- TAX_CODE value should be SALES and the AMOUNT should be the value in global_attribute13 column
           lc_rtl_flag := 'N';
           IF     (p_source = 'US_OD_RENT')
              AND (NVL (inv_lines_updt.global_attribute13, 0) <> 0)
                  THEN                                         -- RETAIL LEASE
              lc_rtl_flag := 'Y';
	      /* Defect 7841 Remove the subtraction of insertthe tax line amount from the item amount 
                     inv_lines_updt.global_attribute13 :=
                           CAST (inv_lines_updt.global_attribute13 AS NUMBER);
                     inv_lines_updt.amount :=
                          inv_lines_updt.amount
                        - inv_lines_updt.global_attribute13;
	      */
           END IF;
           ln_tax_code_id := NULL;
           BEGIN
		    -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
             /*SELECT tax_id
               INTO ln_tax_code_id
               FROM ap_tax_codes_all
              WHERE NAME = NVL (v_tax_code, inv_lines_updt.tax_code)
                AND org_id = v_org_id;*/
			  SELECT distinct tax_id
               INTO ln_tax_code_id
               FROM zx_taxes_b ztb,zx_rates_b zrb,zx_accounts za
              --WHERE ztb.tax = NVL (v_tax_code, inv_lines_updt.tax_code)
			  WHERE zrb.tax_rate_code = NVL (v_tax_code, inv_lines_updt.tax_code)
                AND ztb.tax = zrb.tax
                AND za.tax_account_entity_id = zrb.tax_rate_id
                and ztb.tax_regime_code= zrb.tax_regime_code
				AND zrb.tax_regime_code IN ('OD_CA_SALES_TAX','OD_US_SALES_TAX')
                AND za.internal_organization_id =v_org_id;
			-- end of addition
           EXCEPTION
             WHEN OTHERS THEN
               ln_tax_code_id := NULL;                     
		--                        fnd_file.put_line (fnd_file.LOG, 'No Tax Code found:');
           END;
	   --------------------------------------------------
	   -- Copies the non-duplicate invoice line records --
	   ---------------------------------------------------
	   BEGIN
	     -- Defect 6553 if source = garnishment  then populate the attribute12 with global_attribute1,
	     -- global_attribute2, global_attribute4,global_attribute5,global_attribute6, global_attribute7
	     IF (p_source = 'US_OD_PAYROLL_GARNISHMENT')    THEN
                inv_lines_updt.attribute12 := inv_lines_updt.global_attribute1 || '*' ||
                                              inv_lines_updt.global_attribute2 || '*' ||
                                              inv_lines_updt.global_attribute4 || '*' ||
                                              inv_lines_updt.global_attribute5 || '*' ||
                                              inv_lines_updt.global_attribute6 || '*' ||
                                              inv_lines_updt.global_attribute7 ;  
                -- Per Prod defect #622 Getting the case identifier for later updating the header record
                lc_case_identifier := inv_lines_updt.global_attribute1;
             END IF;
	     -- Defect 11205 
             IF invoices_updt.SOURCE <> 'US_OD_EXTENSITY' THEN
               inv_lines_updt.global_attribute11 := NULL;           
             END IF;
	     --  fnd_file.put_line (fnd_file.LOG, 'Before LINE Insert: SiteId=' || v_vendor_site_id
	     --  || ' Invoice Num = ' ||invoices_updt.invoice_num || ' LineType =' || 	     	     --inv_lines_updt.line_type_lookup_code
	     --                                || ' Attr10=' || invoices_updt.attribute10);
             INSERT 
	       INTO ap_invoice_lines_interface
                    (invoice_id,
                     invoice_line_id,
                     line_number,
                     line_type_lookup_code,
                     line_group_number,                            --added per defect 14767
                     amount,
                     accounting_date,
                     description,
                     prorate_across_flag,                          --added per defect 14767 
                     tax_code,
                     po_header_id,
                     po_number,
                     po_line_id,
                     po_line_number,
                     po_distribution_num,
                     po_unit_of_measure,
                     quantity_invoiced,
					 inventory_item_id, -- Added for Trade Match
                     ship_to_location_code,
                     unit_price, dist_code_concatenated,
                     dist_code_combination_id, last_updated_by,
                     last_update_date,
                     last_update_login,
                     created_by,
                     creation_date,
                     attribute_category,
                     attribute1,
                     attribute2,
                     attribute3,
                     attribute4,
                     attribute5,
                     attribute6,
                     attribute7,
                     attribute8,
                     attribute9,
                     attribute10,
                     attribute11,
                     attribute12,
                     attribute13,
                     attribute14,
                     attribute15,
					 unit_of_meas_lookup_code,
                     account_segment,
                     balancing_segment,
                     cost_center_segment,
                     project_id, task_id,
                     expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id, org_id,
                     receipt_number,
                     receipt_line_number,
                     match_option,
                     tax_code_id,
                     external_doc_line_ref,
                     global_attribute11   -- defect 10194
                    )
             VALUES
		 (inv_lines_updt.invoice_id,
                  inv_lines_updt.invoice_line_id,
                  inv_lines_updt.line_number,
                  inv_lines_updt.line_type_lookup_code,
                  decode(inv_lines_updt.SOURCE, 'US_OD_PCARD',inv_lines_updt.line_group_number,NULL),--added per defect 14767
                  inv_lines_updt.amount,
                  NULL, --Defect 9600 NVL (inv_lines_updt.accounting_date,SYSDATE),
                  --inv_lines_updt.description,  --- Removed for Defect 25382
		  NVL(inv_lines_updt.description,invoices_updt.description), -- Added for Defect 25382
                  decode(inv_lines_updt.SOURCE,'US_OD_PCARD',inv_lines_updt.prorate_across_flag,NULL),--added/defect 14767                                  
                  decode(inv_lines_updt.SOURCE, 'US_OD_RENT', null, NVL (v_tax_code, inv_lines_updt.tax_code)),
                                                                           -- Defect 7841 tax_code
                  inv_lines_updt.po_header_id,
                  inv_lines_updt.po_number,
                  inv_lines_updt.po_line_id,
                  inv_lines_updt.po_line_number,
                  inv_lines_updt.po_distribution_num,
                  inv_lines_updt.po_unit_of_measure,
                  inv_lines_updt.quantity_invoiced,
				  inv_lines_updt.inventory_item_id, -- Added for Trade Match
                  inv_lines_updt.ship_to_location_code,
                  inv_lines_updt.unit_price,
                  DECODE(v_full_gl_code, '....0000..000000', NULL, '.....000...00000....', null,v_full_gl_code), 
										-- Defect 7592 v_full_gl_code        
                  v_ccid, v_user_id,          --last_updated_by
                  SYSDATE,                   --last_update_date
                  NULL,                     --last_update_login
                  v_user_id,                       --created_by
                  SYSDATE,                      --creation_date
                  inv_lines_updt.attribute_category,
                  inv_lines_updt.attribute1,
                  inv_lines_updt.attribute2,
                  inv_lines_updt.attribute3,
                  DECODE(invoices_updt.source,'US_OD_TRADE_EDI',inv_lines_updt.attribute4,'US_OD_DROPSHIP',inv_lines_updt.attribute4,NULL), -- Invoice unit_of_meas_lookup_code
                  inv_lines_updt.attribute5,
                  inv_lines_updt.attribute6,
                  inv_lines_updt.attribute7,
                  inv_lines_updt.attribute8,
                  inv_lines_updt.attribute9,
                  inv_lines_updt.attribute10,
                  inv_lines_updt.reason_code,
                                    -- defect 2326 inv_lines_updt.attribute11,
                  inv_lines_updt.attribute12,
                  inv_lines_updt.attribute13,
                  inv_lines_updt.attribute14,
                  inv_lines_updt.attribute15,
				  DECODE(invoices_updt.source,'US_OD_TRADE_EDI',inv_lines_updt.attribute5,'US_OD_DROPSHIP',inv_lines_updt.attribute5,NULL), -- Invoice unit_of_meas_lookup_code
                  inv_lines_updt.account_segment,
                  inv_lines_updt.balancing_segment,
                  inv_lines_updt.cost_center_segment,
                  v_project_id, v_task_id,
                  v_expenditure_type,       -- expenditure_type
                  NVL(v_expenditure_item_date,inv_lines_updt.expenditure_item_date), --expenditure_item_date
                  v_expenditure_org_id, v_org_id,
                                  -- defect 2102 inv_lines_updt.org_id,
                  inv_lines_updt.receipt_number,
                  inv_lines_updt.receipt_line_number,
                  inv_lines_updt.match_option,
                  decode(inv_lines_updt.SOURCE, 'US_OD_RENT', null,ln_tax_code_id),    -- defect 2102, 7841
                  inv_lines_updt.external_doc_line_ref,inv_lines_updt.global_attribute11    -- defect 10194
                 );
           EXCEPTION
             WHEN OTHERS THEN
               fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_LINES_INTERFACE '||SQLERRM);   
               lc_error_loc := 'Unable to insert invoice line.  ';
               fnd_message.set_name('XXFIN',' XX_AP_0005_ERROR_NO_INSERT_LINE ');
               fnd_message.set_token ('ERR_LOC', lc_error_loc);
               fnd_message.set_token ('ERR_DEBUG',
                                                  'Invoice line ID:  '
                                               || inv_lines_updt.invoice_id
                                               || '  for Invoice Num:  '
                                               || inv_lines_updt.invoice_num
                                              );
               fnd_message.set_token ('ERR_ORA', SQLERRM);
               lc_loc_err_msg := fnd_message.get;
               fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
               xx_com_error_log_pub.log_error
                            (p_program_type                => 'CONCURRENT PROGRAM',
                             p_program_name                => 'XXAPINVINTFC',
                             p_module_name                 => 'AP',
                             p_error_location              =>    'Error at '
                                                              || SUBSTR
                                                                    (lc_error_loc,
                                                                     1,
                                                                     50
                                                                    ),
                             p_error_message_count         => 1,
                             p_error_message_code          => 'E',
                             p_error_message               => lc_loc_err_msg,
                             p_error_message_severity      => 'Major',
                             p_notify_flag                 => 'N',
                             p_object_type                 => 'Processing AP Inbound invoices'
                            );
           END;                                  -- end lines insertion
           --fnd_file.put_line (fnd_file.LOG, 'After LINE Insert: SiteId=' || v_vendor_site_id
	   --                                || ' Invoice Num = ' ||invoices_updt.invoice_num || ' LineType =' || 	   	   --inv_lines_updt.line_type_lookup_code        
	   --                                || ' Attr10=' || invoices_updt.attribute10);
	   -----------------------------------------------------
	   -- Insert invoice line records for TAX line of RETAIL LEASE (defect 2109) --
	   -----------------------------------------------------
           IF lc_rtl_flag = 'Y'  THEN
	      -- ------------------------------------------------------------
	      -- Select Tax Line Invoice Line ID
	      -- ------------------------------------------------------------
              BEGIN
                lc_error_loc :='Getting next Invoice Line ID for tax ' || 'line.';
		SELECT ap_invoice_lines_interface_s.NEXTVAL
                  INTO ln_invoice_line_id
                  FROM DUAL;
              END;
              ln_tax_code_id := NULL;
              BEGIN
			  -- commented and added by Darshini(v2.5) for R12 Upgrade Retrofit
                /*SELECT tax_id
                  INTO ln_tax_code_id
                  FROM ap_tax_codes_all
                 WHERE NAME =  NVL (v_tax_code, inv_lines_updt.tax_code) -- 'SALES'  Defect 7841
                   AND org_id = v_org_id;*/
		     SELECT distinct tax_id
               INTO ln_tax_code_id
               FROM zx_taxes_b ztb,zx_rates_b zrb,zx_accounts za
              --WHERE ztb.tax = NVL (v_tax_code, inv_lines_updt.tax_code)
			  WHERE zrb.tax_rate_code = NVL (v_tax_code, inv_lines_updt.tax_code)
                AND ztb.tax = zrb.tax
                AND za.tax_account_entity_id = zrb.tax_rate_id
                and ztb.tax_regime_code= zrb.tax_regime_code
				AND zrb.tax_regime_code IN ('OD_CA_SALES_TAX','OD_US_SALES_TAX')
                AND za.internal_organization_id =v_org_id;
			-- end of addition
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line (fnd_file.LOG,'No Tax Code found:');
              END; 
              BEGIN
                IF ( inv_lines_updt.tax_code = 'GST_INPUT_CR') THEN
                    --v_full_gl_code  := '....0000..000000';
					--Added for defect# 28446
					v_full_gl_code :=inv_lines_updt.item_description; --Added for defect# 28446
					BEGIN                    
                             SELECT gsb.chart_of_accounts_id
                                INTO lc_coa_id
                                FROM gl_sets_of_books_v gsb
                               WHERE gsb.set_of_books_id = fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                lc_coa_id := NULL;
                             WHEN OTHERS THEN
                                FND_FILE.PUT_LINE(FND_FILE.LOG, 'COA select failed');
                                FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
                          END;
                          
                          FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_coa_id = '||lc_coa_id);
                         
                          BEGIN
                             SELECT code_combination_id
                                 INTO v_ccid
                                 FROM gl_code_combinations
                               WHERE chart_of_accounts_id = lc_coa_id
                                     AND    segment1 = SUBSTR(v_full_gl_code,1,4)
                                     AND    segment2 = SUBSTR(v_full_gl_code,6,5)
                                     AND    segment3 = SUBSTR(v_full_gl_code,12,8)
                                     AND    segment4 = SUBSTR(v_full_gl_code,21,6)
                                     AND    segment5 = SUBSTR(v_full_gl_code,28,4)
                                     AND    segment6 = SUBSTR(v_full_gl_code,33,2)
                                     AND    segment7 = SUBSTR(v_full_gl_code,36,6);
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                v_ccid := NULL;
                             WHEN OTHERS THEN
                                FND_FILE.PUT_LINE(FND_FILE.LOG, 'CCID select failed');
                                FND_FILE.PUT_LINE (FND_FILE.LOG,'Error:: ' || SQLERRM );
                          END;
                    --v_ccid := null; --end
                ELSE
                  IF ( inv_lines_updt.tax_code = 'SALES') THEN
		     -- If source is 'US_OD_RENT' and US for line_type = TAX change the account#
		     -- from the Translation table and get Account Number
		     --                      Begin
		     v_tax_account := null;
                     x_target_value1 := null;
                     xx_fin_translate_pkg.xx_fin_translatevalue_proc
                               ('AP_SALES_TAX_ACCOUNT'  --translation_name
                                                          ,
                                SYSDATE,
                                'US_OD_RENT'                     --source_value1
                                          ,
                                'SALES'                           --source_value2
                                    ,
                                NULL                           --source_value3
                                    ,
                                NULL                           --source_value4
                                    ,
                                NULL                           --source_value5
                                    ,
                                NULL                           --source_value6
                                    ,
                                NULL                           --source_value7
                                    ,
                                NULL                           --source_value8
                                    ,
                                NULL                           --source_value9
                                    ,
                                NULL                          --source_value10
                                    ,
                                x_target_value1,
                                x_target_value2,
                                x_target_value3,
                                x_target_value4,
                                x_target_value5,
                                x_target_value6,
                                x_target_value7,
                                x_target_value8,
                                x_target_value9,
                                x_target_value10,
                                x_target_value11,
                                x_target_value12,
                                x_target_value13,
                                x_target_value14,
                                x_target_value15,
                                x_target_value16,
                                x_target_value17,
                                x_target_value18,
                                x_target_value19,
                                x_target_value20,
                                x_error_message
                               );
                     v_tax_account := x_target_value1;
                     lc_gl_segment1 := SUBSTR(v_full_gl_code,1,4);
                     lc_gl_segment2 := SUBSTR(v_full_gl_code,6,5);
                     lc_gl_segment3 := SUBSTR(v_full_gl_code,12,8);
                     lc_gl_segment4 := SUBSTR(v_full_gl_code,21,6);
                     lc_gl_segment5 := SUBSTR(v_full_gl_code,28,4);
                     lc_gl_segment6 := SUBSTR(v_full_gl_code,33,2);
                     lc_gl_segment7 := SUBSTR(v_full_gl_code,36,6);
                     v_full_gl_code := lc_gl_segment1 || '.' || 
                                       lc_gl_segment2 || '.' ||
                                       v_tax_account  || '.' ||
                                       lc_gl_segment4 || '.' ||
                                       lc_gl_segment5 || '.' ||
                                       lc_gl_segment6 || '.' ||
                                       lc_gl_segment7 ;
		    /* fnd_file.put_line (fnd_file.LOG, '2.Sandeep:Tax Code Account retrieved from:' ||  v_tax_account || '-' 
                      || v_full_gl_code || ' ' || inv_lines_updt.dist_code_concatenated);    */
                  END IF;  --IF ( inv_lines_updt.tax_code = 'SALES') THEN
                END IF; --IF ( inv_lines_updt.tax_code = 'GST_INPUT_CR') THEN
              END; 
	      -- end of Defect 7841  
	      BEGIN
		--fnd_file.put_line (fnd_file.LOG, 'Before LINE Insert: (RETAIL-LEASE) SiteId=' || v_vendor_site_id
		--|| ' Invoice Num = ' ||invoices_updt.invoice_num || ' LineType =' || 	        				--inv_lines_updt.line_type_lookup_code);
                INSERT 
		  INTO ap_invoice_lines_interface
                       (invoice_id,
                        invoice_line_id,
                        line_number, 
                        line_type_lookup_code,
                        amount,
                        accounting_date,
                        description, tax_code,
                        po_header_id,
                        po_number,
                        po_line_id,
                        po_line_number,
                        po_distribution_num,
                        po_unit_of_measure,
                        quantity_invoiced,
						inventory_item_id,
                        ship_to_location_code,
                        unit_price,
                        dist_code_concatenated,
                        dist_code_combination_id,
                        last_updated_by,
                        last_update_date,
                        last_update_login,
                        created_by,
                        creation_date,
                        attribute_category,
                        attribute1,
                        attribute2,
                        attribute3,
                        attribute4,
                        attribute5,
                        attribute6,
                        attribute7,
                        attribute8,
                        attribute9,
                        attribute10,
                        attribute11,
                        attribute12,
                        attribute13,
                        attribute14,
                        attribute15,
						unit_of_meas_lookup_code,
                        account_segment,
                        balancing_segment,
                        cost_center_segment,
                        project_id, task_id,
                        expenditure_type,
                        expenditure_item_date,
                        expenditure_organization_id, org_id,
                        receipt_number,
                        receipt_line_number,
                        match_option,
                        tax_code_id,
                        external_doc_line_ref,
		        prorate_across_flag
                       )
              VALUES  (inv_lines_updt.invoice_id,
                       ln_invoice_line_id,
                       inv_lines_updt.line_number + 1,
                       -- Line incremented for defect 2109
                       'TAX',
                       --inv_lines_updt.line_type_lookup_code,
                       inv_lines_updt.global_attribute13,
                       -- Tax amount
                       NULL, -- Defect 9600 NVL (inv_lines_updt.accounting_date, SYSDATE),
	               --inv_lines_updt.description,  --- Removed for Defect 25382
	    	       NVL(inv_lines_updt.description,invoices_updt.description), -- Added for Defect 25382
                       NVL (v_tax_code, inv_lines_updt.tax_code), -- Defect 7841 --'SALES', -- tax_code defect 2109
                       inv_lines_updt.po_header_id,
                       inv_lines_updt.po_number,
                       inv_lines_updt.po_line_id,
                       inv_lines_updt.po_line_number,
                       inv_lines_updt.po_distribution_num,
                       inv_lines_updt.po_unit_of_measure,
                       inv_lines_updt.quantity_invoiced,
					   inv_lines_updt.inventory_item_id,
                       inv_lines_updt.ship_to_location_code,
                       inv_lines_updt.unit_price,
                       DECODE(v_full_gl_code, '....0000..000000', NULL,'.....000...00000....', null, v_full_gl_code), 
							-- Defect 7592 v_full_gl_code
                       v_ccid,
                       v_user_id,               --last_updated_by
                       SYSDATE,                --last_update_date
                       NULL   ,               --last_update_login
                       v_user_id,                    --created_by
                       SYSDATE,                   --creation_date
                       inv_lines_updt.attribute_category,
					   inv_lines_updt.attribute1,
                       inv_lines_updt.attribute2,
                       inv_lines_updt.attribute3,
                       DECODE(invoices_updt.source,'US_OD_TRADE_EDI',inv_lines_updt.attribute4,'US_OD_DROPSHIP',inv_lines_updt.attribute4,NULL), -- Invoice Unit of Measure
                       inv_lines_updt.attribute5,
                       inv_lines_updt.attribute6,
                       inv_lines_updt.attribute7,
                       inv_lines_updt.attribute8,
                       inv_lines_updt.attribute9,
                       inv_lines_updt.attribute10,
                       inv_lines_updt.attribute11,
                       inv_lines_updt.attribute12,
                       inv_lines_updt.attribute13,
                       inv_lines_updt.attribute14,
                       inv_lines_updt.attribute15,
					   DECODE(invoices_updt.source,'US_OD_TRADE_EDI',inv_lines_updt.attribute5,'US_OD_DROPSHIP',inv_lines_updt.attribute5,NULL), -- PO Unit of Measure
                       inv_lines_updt.account_segment,
                       inv_lines_updt.balancing_segment,
                       inv_lines_updt.cost_center_segment,
                       v_project_id, v_task_id,
                       v_expenditure_type,    -- expenditure_type
                       NVL(v_expenditure_item_date,inv_lines_updt.expenditure_item_date), --expenditure_item_date
                       v_expenditure_org_id, v_org_id,
                       -- defect 2102 inv_lines_updt.org_id,
                       inv_lines_updt.receipt_number,
                       inv_lines_updt.receipt_line_number,
                       inv_lines_updt.match_option,
                       ln_tax_code_id,           -- defect 2102,
                       inv_lines_updt.external_doc_line_ref,DECODE(invoices_updt.SOURCE,'US_OD_RENT','N',NULL) -- Defect 25144
                      );
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_LINES_INTERFACE (RETAIL-LEASE)'||SQLERRM);            	          lc_error_loc :='Unable to insert invoice TAX line.  ';
                  fnd_message.set_name('XXFIN',' XX_AP_0005_ERROR_NO_INSERT_LINE ');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_DEBUG',
                                                     'Invoice line ID:  '
                                                  || inv_lines_updt.invoice_id
                                                  || '  for Invoice Num:  '
                                                  || inv_lines_updt.invoice_num
                                                 );
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_loc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
                  xx_com_error_log_pub.log_error
                              (p_program_type                => 'CONCURRENT PROGRAM',
                               p_program_name                => 'XXAPINVINTFC',
                               p_module_name                 => 'AP',
                               p_error_location              =>    'Error at '
                                                                || SUBSTR
                                                                      (lc_error_loc,
                                                                       1,
                                                                       50
                                                                      ),
                               p_error_message_count         => 1,
                               p_error_message_code          => 'E',
                               p_error_message               => lc_loc_err_msg,
                               p_error_message_severity      => 'Major',
                               p_notify_flag                 => 'N',
                               p_object_type                 => 'Processing AP Inbound invoices'
                              );
              END;
	      -- fnd_file.put_line (fnd_file.LOG, 'After LINE Insert: (RETAIL-LEASE) SiteId=' || v_vendor_site_id
              -- || ' Invoice Num = ' ||invoices_updt.invoice_num || ' LineType =' ||               -- 	      -- 	      --inv_lines_updt.line_type_lookup_code);
           END IF;  -- IF lc_rtl_flag = 'Y'  THEN
           -----------------------------------------------------
           -- Updates invoice line records that are processed --
           -----------------------------------------------------
           UPDATE xx_ap_inv_lines_interface_stg
              SET global_attribute16 = 'PROCESSED'
            WHERE invoice_line_id = inv_lines_updt.invoice_line_id;
           -- Defect 9909 Blank the PO Number for Expense EDI
           if invoices_updt.SOURCE = 'US_OD_EXPENSE_EDI' then
              UPDATE xx_ap_inv_lines_interface_stg
                 SET global_attribute12 = po_number, po_number = null -- defect 9909
               WHERE invoice_line_id = inv_lines_updt.invoice_line_id; 
           end if;
           -- defect 6028                  COMMIT;
          END LOOP;                                     -- end lines loop
       END IF;  --       IF (lc_error_flag = 'N')  THEN
       IF (p_source = 'US_OD_PAYROLL_GARNISHMENT') THEN
             -- Per Prod defect #622 updating the description of header record
                UPDATE  ap_invoices_interface 
                SET     description = lc_case_identifier
                WHERE   invoice_id = invoices_updt.invoice_id;
       END IF;
      -- defect 6028            COMMIT;
	  
	   -- Adding changes for E3522 Trade Match Foundation 
	  -- Changes for Distribution Variance Tolerance
	   IF invoices_updt.SOURCE IN ('US_OD_TRADE_EDI',
								   'US_OD_DCI_TRADE',
								   'US_OD_TDM',
								   'US_OD_DROPSHIP'
								  -- 'US_OD_RTV_CONSIGNMENT',
								  -- 'US_OD_CONSIGNMENT_SALES',
								  --  'US_OD_INTEGRAL_ONLINE',
								  --  'US_OD_CONSIGN_INV',
								  --  'US_OD_VENDOR_PROGRAM',
								  --  'US_OD_RTV_MERCHANDISING'
								  )
		  AND (invoices_updt.GROUP_ID IS NULL OR invoices_updt.GROUP_ID = 'TDM-TRADE')
		  AND invoices_updt.invoice_type_lookup_code = 'STANDARD'
	   THEN
		--  To get the invoice header amount and sum of invoice lines amount for the invoice_id
         BEGIN	
            lc_error_loc :='Getting the invoice header amount and sum of invoice lines amount for the invoice_id.';			 
            ln_invoice_id := NULL;
			ln_total_invoice_lines_amt := NULL;
			ln_invoice_hdr_amt := NULL;	
			ln_difference_amt := NULL;
			lc_reason_code    := NULL;
			
            SELECT a.invoice_id, 
			       SUM(NVL(b.amount,0)),
				   a.invoice_amount
			  INTO ln_invoice_id,
			       ln_total_invoice_lines_amt,
				   ln_invoice_hdr_amt
              FROM xx_ap_inv_lines_interface_stg b,
                   xx_ap_inv_interface_stg a
             WHERE a.invoice_id =invoices_updt.invoice_id
               AND b.invoice_id=a.invoice_id
             GROUP BY a.invoice_id ,a.invoice_amount; 
			 
			 ln_difference_amt := ln_invoice_hdr_amt - ln_total_invoice_lines_amt;
			 
		  EXCEPTION
		     WHEN OTHERS 
			 THEN
			    fnd_file.put_line(fnd_file.log,'Unable to get the invoice header amount and sum of invoice lines amount for the invoice_id :'||invoices_updt.invoice_id);
		  END;
		  
		  IF (ln_difference_amt > 0 OR  ln_difference_amt < 0)
		  THEN
		     -- To fetch the maximum line number
		     BEGIN	
                ln_invoice_line_id := NULL;
			    ln_line_number := NULL;
			
			    lc_error_loc :='Getting the Maximum Line Number for the invoice'; 
			    SELECT MAX(LINE_NUMBER) 
			      INTO ln_line_number
			      FROM ap_invoice_lines_interface
                 WHERE INVOICE_ID = invoices_updt.invoice_id;
		     EXCEPTION
		     WHEN OTHERS 
			 THEN
			   -- fnd_file.put_line(fnd_file.log,'Unable to get the new Invoice Line ID for new line');
			   ln_line_number := NULL;
		     END;
			 
			 -- To get the Reason CODE
			 IF lc_drop_ship_flag = 'Y'
			 THEN
			    lc_reason_code := 'DV';
		     ELSE
			    lc_reason_code := 'GV';
			 END IF;
		  
		     -- To fetch the GL Account and Description from the Translation for the Reason Code GV
             BEGIN		
			 lc_gl_account := NULL;
			 lc_description := NULL;
			 
             lc_error_loc :='Getting the reason code mapping for Gross Variance';		 
			    SELECT b.target_value6,
                       b.target_value2				
				  INTO lc_gl_account,
				       lc_description
				  FROM xx_fin_translatevalues b, 
					   xx_fin_translatedefinition a
				 WHERE a.translation_name='OD_AP_REASON_CD_ACCT_MAP'
				   AND b.translate_id=a.translate_id
				   AND b.enabled_flag='Y'
				   AND b.target_value1 = lc_reason_code
				   AND nvl(b.end_date_active,SYSDATE+1)>SYSDATE;
		     EXCEPTION
		     WHEN OTHERS 
			 THEN
			   -- fnd_file.put_line(fnd_file.log,'Unable to get the new Invoice Line ID for new line');
			   lc_gl_account := NULL;
			   lc_description := NULL;
		     END;
			 
			 -- To fetch the gl string from the PO Line Num = 1
			 BEGIN
			    lc_gl_string := NULL;
				SELECT /*+ cardinality(poh 1) INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */
                       gcck.concatenated_segments
				  INTO lc_gl_string
                  FROM po_headers_all poh,
                       po_lines_all pol,
                       po_distributions_all pod,
                       gl_code_combinations_kfv gcck
                 WHERE poh.po_header_id = pol.po_header_id
                   AND poh.po_header_id = pod.po_header_id
                   AND pol.po_line_id = pod.po_line_id
                   AND pod.code_combination_id = gcck.code_combination_id 
                   AND poh.segment1 = invoices_updt.po_number
                   AND pol.line_num = 1;
			 EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
				    lc_gl_string := NULL;
				WHEN OTHERS 
                THEN
				    lc_gl_string := NULL;
             END;
			   		 
		     BEGIN
                INSERT INTO ap_invoice_lines_interface
									   (invoice_id,
										invoice_line_id,
										line_number, 
										line_type_lookup_code,
										amount,
										accounting_date,
										description, 
										tax_code,
										po_header_id,
										po_number,
										po_line_id,
										po_line_number,
										po_distribution_num,
										po_unit_of_measure,
										quantity_invoiced,
										inventory_item_id,
										ship_to_location_code,
										unit_price,
										dist_code_concatenated,
										dist_code_combination_id,
										last_updated_by,
										last_update_date,
										last_update_login,
										created_by,
										creation_date,
										attribute_category,
										attribute1,
										attribute2,
										attribute3,
										attribute4,
										attribute5,
										attribute6,
										attribute7,
										attribute8,
										attribute9,
										attribute10,
										attribute11,
										attribute12,
										attribute13,
										attribute14,
										attribute15,
										account_segment,
										balancing_segment,
										cost_center_segment,
										project_id, 
										task_id,
										expenditure_type,
										expenditure_item_date,
										expenditure_organization_id, 
										org_id,
										receipt_number,
										receipt_line_number,
										match_option,
										tax_code_id,
										external_doc_line_ref,
								        prorate_across_flag
									   )
							  SELECT    invoice_id,
										ap_invoice_lines_interface_s.NEXTVAL,  -- ln_invoice_line_id,
										ln_line_number + 1, 
										'MISCELLANEOUS', --line_type_lookup_code,
										ln_difference_amt,
										NULL,
										lc_description,
										NULL,
										NULL, -- po_header_id,
										NULL, -- po_number,
										NULL, -- po_line_id,
										NULL, -- po_line_number,
										NULL, -- po_distribution_num,
										NULL, -- po_unit_of_measure,
										NULL,
										NULL,
										NULL,
										NULL,
										SUBSTR(lc_gl_string,1,4)||'.'||
                                        SUBSTR(lc_gl_string,6,5)||'.'||
                                        NVL(lc_gl_account,SUBSTR(lc_gl_string,12,8))||'.'||
                                        SUBSTR(lc_gl_string,21,6)||'.'||
                                        SUBSTR(lc_gl_string,28,4)||'.'||
                                        SUBSTR(lc_gl_string,33,2)||'.'||
                                        SUBSTR(lc_gl_string,36,6),
										NULL,
										last_updated_by,
										last_update_date,
										last_update_login,
										created_by,
										creation_date,
										attribute_category,
										attribute1,
										attribute2,
										attribute3,
										attribute4,
										attribute5,
										attribute6,
										attribute7,
										attribute8,
										attribute9,
										'Y', -- Added for Version 2.15
										lc_reason_code,
										attribute12,
										attribute13,
										attribute14,
										attribute15,
										account_segment,
										balancing_segment,
										cost_center_segment,
										project_id, task_id,
										expenditure_type,
										expenditure_item_date,
										expenditure_organization_id, 
										org_id,
										receipt_number,
										receipt_line_number,
										match_option,
										tax_code_id,
										external_doc_line_ref,
								        prorate_across_flag
								 FROM   ap_invoice_lines_interface
								WHERE   invoice_id = invoices_updt.invoice_id
								  AND   line_type_lookup_code = 'ITEM'
								  AND   line_number = 1;
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log,'Insert into AP_INVOICES_LINES_INTERFACE '||SQLERRM);            	         
				  lc_error_loc :='Unable to insert invoice line.';
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_DEBUG',
                                                     'Invoice line ID:  '
                                                  || invoices_updt.invoice_id
                                                  || '  for Invoice Num:  '
                                                  || invoices_updt.invoice_num
                                                 );
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_loc_err_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG, lc_loc_err_msg);
              END;
			
		  END IF; -- (ln_difference_amt > 0 OR  ln_difference_amt < 0)
						 		  
		END IF; -- End of E3522 Trade Match Foundation changes
				
     END LOOP;                                          -- end header loop
     COMMIT;   -- defect 6028
     -- defect 2326 DFI calculation --------------------------------
     fnd_file.put_line
                          (fnd_file.LOG,
                              'Updates for DFI Calculation for Last Batch Id '
                           || ln_curr_batch_id
                          );
     xx_ap_inv_validate_pkg.xx_ap_process_reason_cd (errbuff,
                                                         retcode,
                                                         ln_curr_batch_id,
							                                           p_source
                                                          );
     -- SANDEEP call procedure to with batch_id to identify the Integral data with no source
     -------------------------------------------------------------
     -- IF condition added as per the Defect ID 1936
     --Fixed Defect 5000
     --Called package to build voucher for non PO based invoices prior to PO based invoices.
     IF p_source <> 'US_OD_PCARD' THEN 
        fnd_file.put_line (fnd_file.LOG, 'Executing XX_AP_CREATE_NON_PO_INV_LINES for'
                                               || 'source =' ||p_source );         
        XX_AP_INV_BLD_NON_PO_LINES_PKG.XX_AP_CREATE_NON_PO_INV_LINES(p_source);    
     END IF;
     -------------------------------------------------------------
     -- Builds the TDM expense invoice lines from the PO lines  --
     --------------------------------------------------------------
     IF (p_source = 'US_OD_TDM' AND p_group_id = 'TDM-EXPENSE') THEN
        --XX_AP_INV_BLD_NON_PO_LINES_PKG.XX_AP_CREATE_NON_PO_INV_LINES(p_group_id);    --Fixed defect 3845
        xx_ap_inv_build_po_lines_pkg.xx_ap_create_po_inv_lines (p_group_id);
     END IF;
     --XX_AP_INV_BLD_NON_PO_LINES_PKG.XX_AP_CREATE_NON_PO_INV_LINES(p_source);           --Fixed defect 4998
     -- Close of additions as per the Defect ID 1936
	 
	 -- Added for the AP Trade Match
	 IF (p_source = ('US_OD_TDM') AND (p_group_id IS NULL OR p_group_id='TDM-TRADE')) OR (p_source = 'US_OD_DCI_TRADE')
	 THEN
	    fnd_file.put_line (fnd_file.LOG, 'Executing xx_ap_create_trdpo_inv_lines for source =' ||p_source );
	    xx_ap_inv_build_po_lines_pkg.xx_ap_create_trdpo_inv_lines (p_group_id);
	 END IF;
	 -- End of adding changes for AP Trade Match
	 
   ELSIF p_source='US_OD_OTM' THEN  -- Defect 21393
      XX_AP_OTM_INVOICE(p_source,p_group_id);
   END IF;
  ELSE	--  IF v_count > 0  THE
    fnd_file.put_line (fnd_file.LOG, '');
    fnd_file.put_line(fnd_file.LOG,'+---------------------------------------------------------------+');
    fnd_file.put_line(fnd_file.LOG,('---------No record is available to be imported------------------'));
    fnd_file.put_line(fnd_file.LOG,'+---------------------------------------------------------------+');
    fnd_file.put_line (fnd_file.LOG, '');
  END IF;
    
END xx_ap_validate_inv_interface;
END xx_ap_inv_validate_pkg;
/
SHOW ERRORS;
