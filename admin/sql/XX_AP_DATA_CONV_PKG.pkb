create or replace
PACKAGE BODY XX_AP_DATA_CONV_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                         	|
-- |                       WIPRO Technologies                                 	|
-- +============================================================================+
-- | Name   :      AP Data Conversion                                         	|
-- | Rice ID:      R1090                                                      	|
-- |                                                                          	|
-- |                                                                          	|
-- |Change Record:                                                           	  |
-- |===============                                                           	|
-- |Version   Date          Author            Remarks                         	|
-- |=======   ==========   ===============    =======================         	|
-- |1.0       24 Jan 2008  Samitha U M       Initial version                  	|
-- |1.1       04-Feb 2008  Samitha U M       Location  picked based           	|
-- |                                         on the State,Accured Tax         	|
-- |                                         for CAD SOB                      	|
-- |1.2       10-Mar 2008  Afan Sheriff      Added code to incorporate        	|
-- |                                         the changes for ftp              	|
-- |                                         send to detination               	|
-- |1.3       17-Aug-2009  Ganga Devi R      Added few more parameters and    	|
-- |                                         changed the code as per R 1.0.2  	|
-- |                                        -Defect #1337                     	|
-- |1.4       20-Aug-2009  Ganga Devi R      Added condition to check for     	|
-- |                                         Tax Amount>0 as per R 1.0.2      	|
-- |                                        -Defect #1337                     	|
-- |1.5       01-Sep-2009  Ganga Devi R      Added condition to check accrued 	|
-- |                                         tax for credit memo invoices     	|
-- |                                         as per defect #16176             	|
-- |1.6       28-Sep-2009  Rani asaithambi   Added County as a parameter,     	|
-- |                                         included the field county and     	|
-- |                                         vendor_site_code           	      |
-- |                                         for the  R 1.1-Defect #2428        |
-- |1.7       24-MAR-2010  Venkatesh B       Added join condition to check the  |
-- |                                         cancelled date of invoice is null  |
-- |                                         or not for the defect #4491        |
-- |1.8       24-MAR-2010  Venkatesh B       Added join condition to check the  |
-- |                                         invoice vendor id for the          |
-- |                                         defect #4948                       |
-- |                                                      	                    |
-- |1.9       16-SEP-2010  Joe Klein         For CR766:                         |
-- |                                         1)Change to pick up credit memos   |
-- |                                           TAX1, TAX2, etc.                 |
-- |                                         2)Change to select based on invoice|
-- |                                           distribution accounting date     |
-- |                                           instead of invoice hdr GL date.  |
-- |                                         3)Comment any special code based on|
-- |                                           p_NonZero_Tax_Accrued parameter  |
-- |                                           so that all negative and positive|
-- |                                           credit memos are selected.       |
-- |2.0       13-AUG-2013  Aradhna S         Modified for R12 retrofit          |
-- |                                                      	                    |
-- |2.1       13-JAN-2014  Sinon Perlas      Modified to retrieve accrued tax   |
-- |                                         amount from a new table in     R12 |
-- 
-- |3.0       19-MARCH-2014                   MODIFIED FOR DEFECT 28918
-- |                                                      	                |
-- |4.0       27-OCT-2015  Harvinder Rakhra  Retrofit R12.2. Removed Schema Prefix|
-- |                                                      	                |
-- +============================================================================+
-- +============================================================================+
-- | Name       :  AP_DATA_CONV                                                 |
-- | Parameters : x_error_buff ,x_ret_code,p_invoice_source                     |
-- |             ,p_state_from,p_state_to,p_city,p_county,p_location            |
-- |             ,p_legal_entity,p_acctno_from,p_acctno_to                      |
-- |             ,p_NonZero_Tax_Accrued,p_from_date,p_to_date,p_delimiter       |
-- |             ,p_file_path,p_dest_file_path,p_file_name,p_file_extension     |
-- +============================================================================+
   gc_file_name         VARCHAR2(100);
   gt_file              UTL_FILE.FILE_TYPE;

PROCEDURE AP_DATA_CONV(  x_error_buff             OUT      VARCHAR2
                        ,x_ret_code               OUT      NUMBER
                        ,P_Invoice_Source         In       Varchar2
                        ,P_Org_Id                 In       Number
                        ,p_state_from             IN       VARCHAR2
                        ,p_state_to               IN       VARCHAR2
			                  ,p_county                 IN       VARCHAR2   --Added for the defect 2428 R1.1
                        ,p_city                   IN       VARCHAR2
                        ,p_location               IN       VARCHAR2
                        ,p_legal_entity           IN       VARCHAR2
                        ,p_acctno_from            IN       VARCHAR2
                        ,p_acctno_to              IN       VARCHAR2
                        ,p_NonZero_Tax_Accrued    IN       VARCHAR2
                        ,p_from_date              IN       VARCHAR2
                        ,p_to_date                IN       VARCHAR2
                        ,p_delimiter              IN       VARCHAR2
                        ,p_file_path              IN       VARCHAR2
                        ,p_dest_file_path         IN       VARCHAR2
                        ,p_file_name              IN       VARCHAR2
                        ,P_File_Extension         In       Varchar2

			 )
AS

--Added lc_user_name,ln_user_id,ln_request_id,ld_from_date and ld_to_date for R 1.0.2-Defect #1337

  lc_source_file_path        VARCHAR2(500);
  lc_invoice_num_tax         VARCHAR2(100);
  ln_count                   NUMBER;
  lc_matched_po              VARCHAR2(25);
  lc_source_file_name        VARCHAR2(1000);
  lc_dest_file_name          VARCHAR2(1000);
--ln_req_id                  NUMBER(10);
  lc_gl_acount               VARCHAR2(25);
  lc_gl_location             VARCHAR2(25);
--lc_gl_department           VARCHAR2(25); --Commented for R 1.0.2-defect #1337
  lc_lob                     VARCHAR2(25);
  lc_targetvalue1            xx_fin_translatevalues.target_value1%TYPE;
  ap_data_conv_rec_type      ap_data_conv_rec;
  ap_data_ref_rec_type       ap_data_ref_rec;
  lc_ca_org_id               NUMBER :=0;
  lc_to_write                VARCHAR2(5000);
  lc_open_file_flag          VARCHAR2(1);
  lc_close_file              VARCHAR2(1);
  lc_po_numer                VARCHAR2(50);
  ln_po_lin_num              NUMBER;
  lc_po_location_id          po_distributions_all.deliver_to_location_id%TYPE;
  lc_po_location_num         hr_locations.attribute1%TYPE;
  ln_req_id_ftp              NUMBER(10);
  lb_result                  boolean;
  lc_phase                   varchar2(1000);
  lc_status                  varchar2(1000);
  lc_dev_phase               varchar2(1000);
  lc_dev_status              varchar2(1000);
  lc_message                 varchar2(1000);
  lc_user_name               varchar2(100);
  ln_user_id                 NUMBER(15):=FND_GLOBAL.USER_ID;
  ln_request_id              NUMBER(15):=FND_GLOBAL.CONC_REQUEST_ID;
  ld_from_date               DATE;
  ld_to_date                 DATE;
  Ex_User_Exc_Ca_Org_Id      Exception;


---------------------------------Cursor to Fetch the invoice details -------------------------------
TYPE lcu_ap_detail_data is REF CURSOR;               --Added Ref Cursor for  R 1.0.2-Defect #1337
Ap_Detail_Data  Lcu_Ap_Detail_Data;                  --Added for R 1.0.2-Defect #1337
 /*CURSOR c_ap_invoice_header (lc_targetvalue1 xx_fin_translatevalues.target_value1%TYPE)
 IS*/
 lc_ap_select_qry Varchar2(32767) :=
                    'SELECT  /*+ FULL(GCC) */'                                   --CR766/defect 4491 - Added hint to improve performance
                    ||' AI.source                    INVOICE_SOURCE'    --Added as per R 1.0.2-Defect #1337
                    ||',AI.invoice_id                INVOICE_ID'
                    ||',AID.invoice_distribution_id  INVOICE_DIST_ID'
                    ||',AI.invoice_num               INVOICE_NUM'
                    ||',AI.amount_paid               AMOUNT_PAID'
                  --   ,AI.voucher_num               VOUCHER_NUM         Commented for R 1.0.2-Defect #1337
                   ------- ||',AID.line_type_lookup_code    LINE_TYPE_CODE'   ---------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
		   ||',AIL.line_type_lookup_code    LINE_TYPE_CODE'   ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                   ||',AID.po_distribution_id       DISTRIBUTION_ID'
		    ||',AID.attribute8               ACCRUED_TAX'
                    ||',AID.amount                   LINE_LEVEL_AMOUNT'
		    ||',AI.invoice_amount            GROSS_AMOUNT'
                    ||',AI.invoice_date              INVOICE_DATE'
                    ||',FFVV.attribute4              VENDOR_STATE'
		                ||',DECODE(HL.country,''US'',HL.region_1,''CA'',HL.region_2,HL.region_1) COUNTY'         --Added for R 1.1 Defect #2428
		                ||',HL.town_or_city              VENDOR_CITY'     --Added for R 1.0.2 Defect #1337
                    ||',AI.payment_status_flag       STATUS_FLAG'
                    ||',GCC.segment3                 ACCT_NO'
                    ||',GCC.segment1                 ENTITY'
                    ||',GCC.segment4                 LOCATION'
                    ||',GCC.segment6                 LOB'
                    ||',AID.accounting_date          GL_ACOUNTING_DATE'
                    ||',PVS.vendor_id                VENDOR_ID'
		                ||',PVS.vendor_site_code         VENODR_SITE_CODE' --Added for R 1.1 Defect #2428
                    ||',PV.vendor_name               VENDOR_NAME'
                    ||',DECODE(PVS.country,''US'',PVS.STATE,''CA'',PVS.province,PVS.state) STATE'
                    ||',PVS.city                     CITY'
		                ||',AI.invoice_currency_code     CURRENCY'
                    ||',AID.dist_code_combination_id DIST_CODE'
                    ||',GCC.segment2                 DEPARTMENT'
                    ||',AI.org_id                    ORG_ID'
                    ||',PV.segment1                  VENDOR_NUMBER'
                    ||',AID.distribution_line_number distribution_line_number'  --CR766 Added this column
            ||'   FROM  ap_invoices                  AI'
	            ||',ap_invoice_lines             AIL'                 ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                    ||',ap_invoice_distributions     AID'
                 -------   ||',po_vendor_sites              PVS'          ---------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                 -------   ||',po_vendors                   PV'            ---------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
		     ||',ap_supplier_sites              PVS'              ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                    ||',ap_suppliers                   PV'                ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                    ||',gl_code_combinations         GCC'
                    ||',fnd_flex_values              FFVV'
                    ||',fnd_flex_value_sets          FFVS'
                  -------  ||',hr_locations_all             HL';          ---------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
		     ||',hr_locations            HL';                  ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
    lc_ap_where_qry Varchar2(32767) :=
            '   WHERE    AID.invoice_id                = AI.invoice_id'
	     ||' AND      AIL.invoice_id                = AI.invoice_id'       ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
	     ||' AND AIL.line_number = AID.invoice_line_number'               ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
	          ||' AND      AI.vendor_site_id             = PVS.vendor_site_id'
            ||' AND      PV.vendor_id                  = PVS.vendor_id'
            ||' AND      AID.dist_code_combination_id  = GCC.code_combination_id'
            ||' AND      FFVV.flex_value_set_id        = ffvs.flex_value_set_id'            --Added for the Defect 3719----
            ||' AND      GCC.segment4                  = ffvv.flex_value'
	          ||' AND      AI.org_id                     ='|| P_org_id--FND_PROFILE.VALUE(''ORG_ID'')'     --Added for R 1.1 Defect #2428
            --Added below conditions for R 1.0.2 Defect #1337
            ||' AND      GCC.enabled_flag              = ''Y'''
            ||' AND      FFVV.attribute4        BETWEEN  '''||p_state_from ||'''  AND  '''||p_state_to||''''
	          ||' AND      SUBSTR(HL.location_code,1,INSTR(HL.location_code,'':'')-1) = GCC.segment4 '
            ||' AND      HL.inactive_date                IS NULL'
            ||' AND      AID.accounting_date BETWEEN  TO_DATE('''||p_from_date||''',''YYYY/MM/DD HH24:MI:SS'') AND TO_DATE('''||p_to_date||''',''YYYY/MM/DD HH24:MI:SS'')'  --CR766 added
          --||' AND      AI.GL_DATE          BETWEEN  TO_DATE('''||p_from_date||''',''YYYY/MM/DD HH24:MI:SS'') AND TO_DATE('''||p_to_date||''',''YYYY/MM/DD HH24:MI:SS'')'  --Added for R 1.0.2-defect #1337  --CR766 commented
          --||' AND      AI.invoice_date     BETWEEN  TO_DATE(p_from_date,'YYYY/MM/DD HH24:MI:SS') AND TO_DATE(p_to_date,'YYYY/MM/DD HH24:MI:SS') --Commented for R 1.0.2-defect #1337
        --------------   ||' AND      AID.line_type_lookup_code    != ''TAX'''  	---------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
	      ||' AND     AIL.line_type_lookup_code != ''TAX'''  ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
            -- CR766 in below select, change ''%_TAX'' to ''%_TAX%'' in order to pick up credit memos with invoice number ending in TAX1, TAX2, etc.
            ||' AND      NOT EXISTS  (
                                                       SELECT 1
                                                       FROM   ap_invoices
                                                       WHERE  invoice_num = AI.invoice_num
                                                       AND    invoice_num LIKE ''%_TAX%''
                                                       AND    invoice_type_lookup_code = ''CREDIT''
                                                       )';
          --||'ORDER BY  AI.invoice_num ';


 BEGIN

     Fnd_File.Put_Line(Fnd_File.Log,'**org_id***'||P_org_id);

------------------------------------Fetching the XXFIN_OUTBOUND Directory Path from the table---------------------
       BEGIN
               SELECT directory_path
               INTO   lc_source_file_path
               FROM   dba_directories
               WHERE  directory_name = p_file_path;
       EXCEPTION
       WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the File Path XXFIN_OUTBOUND  :'  || SQLERRM);
       END;
-------------------------------------To get the File name appended with the Time Stamp----------------------------
  --Start of changes for R 1.0.2-Defect #1337
       BEGIN
          SELECT user_name
          INTO lc_user_name
          FROM fnd_user
          WHERE user_id=ln_user_id;
       EXCEPTION
       WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the User Name  :'   || SQLERRM);
       END;
        ld_from_date:=FND_DATE.CANONICAL_TO_DATE(p_from_date);
        ld_to_date:=FND_DATE.CANONICAL_TO_DATE(p_to_date);
        gc_file_name := p_file_name
                     --|| TO_CHAR(SYSDATE, 'DDMONYYYYHHMMSS') Commented for R 1.0.2-defect#1337
                       ||p_state_from
                       ||'-'
                       ||p_state_to
                       ||'-'
                       ||TO_CHAR(ld_from_date,'mmyy')
                       ||'-'
                       ||TO_CHAR(ld_to_date,'mmyy')
                       ||'-'
                       ||lc_user_name
                       ||'-'
                       ||ln_request_id
                       ||p_file_extension;
  --End of changes for R 1.0.2-Defect #1337
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The File Name                       : ' || gc_file_name);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || p_file_path);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || p_dest_file_path);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');


-------------------------------------Writing the File Headings--------------------------------------------

--Label changed for 'GL Posting date,Acct No,Entity,Department,AP Line Level Amount and Supplier Number as per R 1.0.2-Defect #1337

       lc_to_write:='Invoice Source'
                    || p_delimiter  || 'Accounting Date'
                    || p_delimiter  || 'GL Account Description'
                    || p_delimiter  || 'GL Acct No'
                    || p_delimiter  || 'Company'
                    || p_delimiter  || 'PO Location'
                    || p_delimiter  || 'GL Location No '
                    || p_delimiter  || 'GL Location Desc '
                    || p_delimiter  || 'OD State'       --Added as per R 1.0.2-Defect #1337
                    || p_delimiter  || 'OD County'      --Added for R 1.1 Defect #2428
                    || p_delimiter  || 'OD City'        --Added as per R 1.0.2-Defect #1337
                    || p_delimiter  || 'Cost Center'
                    || p_delimiter  || 'LOB'
                    || p_delimiter  || 'Line Type'
                    || p_delimiter  || 'Line Item Amt'
                    || p_delimiter  || 'Supplier No'
                    || p_delimiter  || 'Site/Vendor ID'     --Added for R 1.1 Defect #2428
                    || p_delimiter  || 'Vendor Name'
                    || p_delimiter  || 'Vendor State'
                    || p_delimiter  || 'Vendor City'
                  --|| p_delimiter  || 'Voucher Number'     --Commented as per R 1.0.2-Defect #1337
                    || p_delimiter  || 'Invoice Number'
                    || p_delimiter  || 'Invoice Date'
                  --|| p_delimiter  || 'State'              --Commented as per R 1.0.2-Defect #1337
                    || p_delimiter  || 'PO  No'
                    || p_delimiter  || 'PO Line No'
                    || p_delimiter  || 'Credit Memo Date'
                    || p_delimiter  || 'Credit Memo number '
                    || p_delimiter  || 'Credit Memo Amount'
                    || p_delimiter  || 'Currency '
                    || p_delimiter  || 'Sales Tax'
                    || p_delimiter  || 'Gross Invoice Amt'
                    || p_delimiter  || 'Payment Date'
                    || p_delimiter  || 'Accrued Tax'
                    || p_delimiter  || 'Amt Paid';

---------------------------------Calling the procedure to open the File and write the headings -------------------------
                   lc_close_file      := 'N';
                   lc_open_file_flag  := 'Y';

                   AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);

--------------------------------  To fetch the value Set name for Account Desc,Location Dec,Department,LOB-------------

        SELECT  XFT.Target_Value1
               ,XFT.Target_Value2
               ,XFT.Target_Value3
               ,XFT.Target_Value4
        INTO    lc_targetvalue1
               ,lc_lob
               ,lc_gl_location
               ,lc_gl_acount
        FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFT
        WHERE  XFTD.translate_id = XFT.translate_id
        AND    XFTD.translation_name = 'XX_AP_GLVALUESETS'
        AND    XFT.enabled_flag = 'Y';
 --FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_targetvalue1 '|| lc_targetvalue1);
----------------------------------------------------To fetch the ORG_ID for CAD---------------------------------------
        BEGIN

              SELECT  HOU.organization_id
              INTO    lc_ca_org_id
              FROM    xx_fin_translatedefinition  XFTD
                     ,xx_fin_translatevalues      XFTV
                     ,hr_organization_units       HOU
              WHERE  translation_name = 'OD_COUNTRY_DEFAULTS'
              AND    XFTV.translate_id = XFTD.translate_id
              AND    XFTV.source_value1  = 'CA'
              AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
              AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
              AND    XFTV.enabled_flag = 'Y'
              AND    XFTD.enabled_flag = 'Y'
              AND    XFTV.target_value2=HOU.name;

        EXCEPTION
        WHEN OTHERS   THEN
             RAISE EX_USER_EXC_CA_ORG_ID;
        END;

  ---------------------------------- Fetching values from the cursor  -----------------------------------------------
  --Added dynamic sql for R 1.0.2-defect #1337

   IF p_invoice_source IS NOT NULL THEN
     lc_ap_where_qry:=lc_ap_where_qry ||' AND AI.source = '''||p_invoice_source||'''';
   END IF;

   IF lc_targetvalue1 IS NOT NULL THEN
     lc_ap_where_qry:=lc_ap_where_qry ||' AND FFVS.flex_value_set_name = '''||lc_targetvalue1||'''';
   END IF;

   IF p_legal_entity IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND GCC.segment1 = '''||p_legal_entity||'''' ;
   END IF;

   IF p_acctno_from IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND GCC.segment3 >= '''||p_acctno_from||'''' ;
   END IF;

   IF p_acctno_to IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND GCC.segment3 <= '''||p_acctno_to||'''' ;
   END IF;

   IF p_location IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND GCC.segment4 = '''||p_location||'''' ;
   END IF;

   IF p_city IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND HL.town_or_city = '''||p_city||'''';
   END IF;

   /*Added for R 1.1 Defect #2428 starts here */
   IF p_county IS NOT NULL THEN
        lc_ap_where_qry:=lc_ap_where_qry||' AND DECODE(HL.country,''US'',HL.region_1,''CA'',HL.region_2,HL.region_1) = '''||p_county||'''';
   END IF;
   /*Added for R 1.1 Defect #2428 ends here */

   --CR766 commented below block
   --IF p_NonZero_Tax_Accrued ='Y' THEN
   --     lc_ap_where_qry:=lc_ap_where_qry||' AND  AID.attribute8 IS NOT NULL AND AID.attribute8>0 ';
   --END IF;

   lc_ap_where_qry:=lc_ap_where_qry ||' ORDER BY AI.invoice_num' ;

   --     Fnd_File.Put_Line(Fnd_File.Log,lc_ap_select_qry||lc_ap_where_qry );

    

    OPEN ap_detail_data FOR lc_ap_select_qry||lc_ap_where_qry;    --Opening REF Cursor
    Loop

      Fetch Ap_Detail_Data Into Ap_Data_Ref_Rec_Type;

      EXIT WHEN ap_detail_data%NOTFOUND;

      -- FOR lcu_ap_invoice_header_rec IN ap_detail_data (lc_gl_department)
       --LOOP

           lc_open_file_flag :='N';

           FND_FILE.PUT_LINE(FND_FILE.LOG,'********INVOICE DETAILS ***********' );
           FND_FILE.PUT_LINE(FND_FILE.LOG,'INVOICE_NUM                         :'||ap_data_ref_rec_type.lr_invoice_num);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'INVOICE_ID                          :'||ap_data_ref_rec_type.lr_invoice_id);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'PO_DISTRIBUTION_ID                  :'||ap_data_ref_rec_type.lr_po_distribution_id);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'INVOICE_ DISTRIBUTION_ID            :'||ap_data_ref_rec_type.lr_invoice_dist_id);

--Commented recored variable for R 1.0.2-defect #1337
           ap_data_conv_rec_type.lr_gl_acct_desc              := NULL;
         --ap_data_conv_rec_type.lr_acct_no                   := NULL;
         --ap_data_conv_rec_type.lr_entity                    := NULL;
           ap_data_conv_rec_type.lr_po_location               := NULL;
           ap_data_conv_rec_type.lr_gl_loc_desc               := NULL;
           ap_data_conv_rec_type.lr_gl_loc_no                 := NULL;
         --ap_data_conv_rec_type.lr_department                := NULL;
           ap_data_conv_rec_type.lr_sales_channel_LOB         := NULL;
         --ap_data_conv_rec_type.lr_line_type_code            := NULL;
         --ap_data_conv_rec_type.lr_line_level_amount         := NULL;
         --ap_data_conv_rec_type.lr_vendor_num                := NULL;
         --ap_data_conv_rec_type.lr_vendor_name               := NULL;
         --ap_data_conv_rec_type.lr_voucher_num               := NULL;
         --ap_data_conv_rec_type.lr_invoice_num               := NULL;
         --ap_data_conv_rec_type.lr_invoice_date              := NULL;
         --ap_data_conv_rec_type.lr_state                     := NULL;
           ap_data_conv_rec_type.lr_po_number                 := NULL;
           ap_data_conv_rec_type.lr_line_num                  := NULL;
           ap_data_conv_rec_type.lr_cr_invoice_date           := NULL;
           ap_data_conv_rec_type.lr_cr_invoice_num            := NULL;
           ap_data_conv_rec_type.lr_cr_invoice_amount         := NULL;
         --ap_data_conv_rec_type.lr_currency                  := NULL;
           ap_data_conv_rec_type.lr_sales_tax                 := NULL;
         --ap_data_conv_rec_type.lr_gross_amount              := NULL;
           ap_data_conv_rec_type.lr_payment_date              := NULL;
         --ap_data_conv_rec_type.lr_accrued_tax               := NULL;
         --ap_data_conv_rec_type.lr_amount_paid               := NULL;

-------------------------------------  To Get the GL Account Description   --------------------------------------------

           BEGIN
                SELECT ffvv.description
                INTO   ap_data_conv_rec_type.lr_gl_acct_Desc
                FROM   fnd_flex_values_vl           FFVV
                       ,fnd_flex_value_sets          FFVS
                WHERE  FFVV.flex_value_set_id       = FFVS.flex_value_set_id
                AND    FFVV.flex_value              =  ap_data_ref_rec_type.lr_acct_no
                AND    FFVS.flex_value_set_name     = lc_gl_acount;
           EXCEPTION
           WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the GL Account Description  :'
                                      || SQLERRM );
           END;

----------------------- To Get the GL Location  Description  -------------------------------------------
         BEGIN
            SELECT  ffvv.description
            INTO    ap_data_conv_rec_type.lr_gl_loc_Desc
            FROM    fnd_flex_values_vl           FFVV
                   ,fnd_flex_value_sets          FFVS
            WHERE   FFVV.flex_value_set_id       = FFVS.flex_value_set_id
            AND     FFVV.flex_value              = ap_data_ref_rec_type.lr_location
            AND     FFVS.flex_value_set_name     = lc_targetvalue1;
         EXCEPTION
         WHEN OTHERS   THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the The GL Location  Description  :'
                                       || SQLERRM );
         END;

----------------------- To Get the GL Location  Number -------------------------------------------


        ap_data_conv_rec_type.lr_gl_loc_no :=ap_data_ref_rec_type.lr_location;       --------- Added for defect #3719-----


-------------------- --- To Get the LOB(Sales Channel)  Description  -------------------------------------
        BEGIN
            SELECT ffvv.description
            INTO   ap_data_conv_rec_type.lr_sales_channel_LOB
            FROM   fnd_flex_values_vl           FFVV
                   ,fnd_flex_value_sets          FFVS
            WHERE  FFVV.flex_value_set_id       = FFVS.flex_value_set_id
            AND    FFVV.flex_value              = ap_data_ref_rec_type.lr_lob
            AND    FFVS.flex_value_set_name     = lc_lob;
       EXCEPTION
       WHEN OTHERS   THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching The LOB(Sales Channel)  Description  :'
                                      || SQLERRM );
       END;

/*---------------------To Get the Department    ---------------------------------------------------------------
        BEGIN
            SELECT   ffvv.description
            INTO    ap_data_conv_rec_type.lr_department
            FROM    fnd_flex_values_vl           FFVV
                   ,fnd_flex_value_sets          FFVS
            WHERE  FFVV.flex_value_set_id       = FFVS.flex_value_set_id
            AND    FFVV.flex_value              = lcu_ap_invoice_header_rec.DEPARTMENT
            AND    FFVS.flex_value_set_name     = lc_gl_department;
         EXCEPTION
         WHEN OTHERS   THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching  the Department  :'
                                      || SQLERRM );
         END;
*/
---------------------To Get the Department   Number---------------------------------------------------------------

       --  ap_data_conv_rec_type.lr_department:=ap_data_ref_rec.lr_department;

                 ---- SINON  ADDED CODE BELOW OF DEFECT 2720: GET ACCRUED TAX FROM NEW R12 TABLE ----
--------------------To Get accrued tax    ---------------------------------------------------------------
         IF (nvl(ap_data_ref_rec_type.lr_accrued_tax,0) = 0) THEN     --Fix for missing accrued tax for 11i SINON 030814 BELOW
	       BEGIN
     
         FND_FILE.PUT_LINE(FND_FILE.LOG,'ap_data_ref_rec_type.lr_invoice_id : ' || ap_data_ref_rec_type.lr_invoice_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'ap_data_ref_rec_type.lr_distribution_line_number : ' || ap_data_ref_rec_type.lr_distribution_line_number);


                       SELECT  SUM(txl.tax_amt)
                       -- into    ap_data_conv_rec_type.lr_accrued_tax
  			               INTO    ap_data_ref_rec_type.lr_accrued_tax
                       FROM    ZX_LINES  txl
                       WHERE   txl.trx_id       = ap_data_ref_rec_type.lr_invoice_id
                       --AND     txl.trx_line_id  = ap_data_ref_rec_type.lr_distribution_line_number
                       AND     txl.self_assessed_flag = 'Y';
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ap_data_ref_rec_type.lr_accrued_tax : ' || ap_data_ref_rec_type.lr_accrued_tax);
         EXCEPTION
         WHEN OTHERS   THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching accrued tax amount  :'
                                      || SQLERRM );
       
         END;
         END IF;       --Fix for missing accrued tax for 11i SINON 030814 ABOVE


		  ---- SINON  ADDED CODE ABOVE OF DEFECT 2720: GET ACCRUED TAX FROM NEW R12 TABLE ----

--------------------To fetch the Check date for the  Paid invoices------------------

        IF ( ap_data_ref_rec_type.lr_status_flag !='N')
        THEN

             BEGIN
                  SELECT  AC.check_date
                  INTO    ap_data_conv_rec_type.lr_payment_date
                  FROM    ap_checks                  AC
                         ,ap_invoice_payments        AIP
                  WHERE  AC.check_id                 =AIP.check_id
                  AND    AIP.invoice_id              =ap_data_ref_rec_type.lr_invoice_id
                  AND    AC.status_lookup_code  NOT IN ('OVERFLOW'
                                                       ,'SET UP'
                                                       ,'SPOILED'
                                                       ,'STOP INITIATED'
                                                       ,'UNCONFIRMED SET UP'
                                                       ,'VOIDED'
                                                      );
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'There is  Payment details for the Invoice');
                ap_data_conv_rec_type.lr_payment_date :='';
            WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Check date  :'
                                                || SQLERRM );
            END;
--------------------To fetch the Check date for the  NOT Paid invoices------------------
       ELSE
                 ap_data_conv_rec_type.lr_payment_date :='';
       END IF;

------------------- To get the Credit Memo Invoice No matching to the invoice ----------------------------
      --lc_invoice_num_tax := ap_data_ref_rec_type.lr_invoice_num||'_TAX';  --CR766 commented
        lc_invoice_num_tax := ap_data_ref_rec_type.lr_invoice_num||'_TAX%'; --CR766 added in order to get credit memos TAX1, TAX2, etc.

 ------------------- To Calculate the Sales Tax Amount  ------------------------------
        BEGIN
               SELECT  SUM(AID.amount)
               INTO    ap_data_conv_rec_type.lr_sales_tax
               FROM    ap_invoice_distributions    AID
	              , ap_invoice_lines    AIL               ---- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                      ,ap_invoices                 AI
               WHERE   AI.invoice_id                = AID.Invoice_id
	         AND   AIL.invoice_id                = AI.invoice_id       ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
	         AND   AIL.line_number              = AID.invoice_line_number               ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                 AND   AI.invoice_id                = ap_data_ref_rec_type.lr_invoice_id
               ----  AND   AID.line_type_lookup_code    = 'TAX';  ---------- commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
		 AND   AIL.line_type_lookup_code    = 'TAX';  ---------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
        EXCEPTION
        WHEN OTHERS   THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Sales Tax Amount For USD :'
                                             || SQLERRM );
        END;

--------Accured Tax If it is not a Partially paid Invoice ------------------------------------------------

       --ap_data_ref_rec_type.lr_accrued_tax         :=0;   Commented for R 1.0.2-Defect #1337
        ln_count:= 0;

--------------------- To Check Whether there is a matching Credit memo-------------------------------------
            BEGIN
                SELECT COUNT(AI.invoice_id)
                INTO   ln_count
                FROM   ap_invoices AI
                WHERE  AI.invoice_num  LIKE lc_invoice_num_tax
                AND    AI.vendor_id = ap_data_ref_rec_type.lr_vendor_id  --Added for defect #4948
                AND    AI.cancelled_date IS NULL;                        --Added for defect #4948


            EXCEPTION
            WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Credit Memo Count  :'
                                 || SQLERRM );
            END;

             IF   (ln_count >0 )         THEN
-------To Fetch the Credit memo  No,Credit memo  amount,Invoice Date  for invoices with  Partially Paid Invoices With  Credit Memos--------
                 BEGIN
                      SELECT  AI.invoice_num
                             ,AI.invoice_amount
                             ,AI.invoice_date
                      INTO    ap_data_conv_rec_type.lr_cr_invoice_num
                             ,ap_data_conv_rec_type.lr_cr_invoice_amount
                             ,ap_data_conv_rec_type.lr_cr_invoice_date
                      FROM    ap_invoices AI, ap_invoice_distributions AID  --CR766 added AID join since CR766 allowed for multiple credit memos (TAX1, TAX2, etc) for a single invoice
                      WHERE   AI.invoice_num LIKE lc_invoice_num_tax
                        AND   AI.invoice_id = AID.invoice_id                                                                     --CR766 added condition
                        AND   AID.dist_code_combination_id = ap_data_ref_rec_type.lr_dist_code                                   --CR766 added condition
                        AND   to_number(nvl(substr(AID.description,21),0)) = ap_data_ref_rec_type.lr_distribution_line_number    --CR766 added condition
                        AND   AI.vendor_id = ap_data_ref_rec_type.lr_vendor_id   --Added for defect #4948
                        AND   AI.cancelled_date IS NULL;     --Added for defect #4491
                  EXCEPTION
                  WHEN OTHERS   THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Invoice Numeber for the Credit Memo  :'
                                 || SQLERRM );
                  END;
      /**            IF  ( lc_ca_org_id!= 0)   THEN
                      IF (ap_data_ref_rec_type.lr_org_id = lc_ca_org_id )                   THEN 
 ------------------- To Calculate the Accured  Tax Amount  Canada ------------------------------
                              BEGIN
                                  ------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013

                                      SELECT  SUM(AID.amount)                      ---------Added for defect #3719
                                        INTO    ap_data_ref_rec_type.lr_accrued_tax
                                        FROM    ap_invoice_distributions    AID        ------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					       , ap_invoice_lines    AIL     ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                                               ,ap_invoices                 AI
                                               ---------- ,ap_tax_codes                ATC                ------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					       ,zx_rates_b                ATC                   ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                                        WHERE  AI.invoice_id                = AID.Invoice_id
					AND    AI.invoice_id                = AIL.Invoice_id     ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					AND    AIL.line_number              = AID.invoice_line_number   ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                                        AND    AI.invoice_num               = lc_invoice_num_tax
                                        ----AND    AID.line_type_lookup_code    = 'TAX'                    ------- commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					AND    AIL.line_type_lookup_code    = 'TAX'                    ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                                        --------AND    ATC.tax_id                   = AID.tax_code_id     ------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					AND    ATC.tax_rate_id                   = AIL.tax_rate_id        ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
                                        --------AND    ATC.name LIKE 'PST%'  ------- Commented by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					AND    ATC.tax_rate_code LIKE 'PST%'   ------- Added by Aradhna Sharma for R12 retrofit on 13-Aug-2013
					AND    AID.amount >0;
                                EXCEPTION
                                WHEN OTHERS   THEN
                                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Sales Tax Amount For CAD  :'
                                                                           || SQLERRM ); 
                                END;
 ------------------- To Calculate the Accured  Tax Amount  for US ------------------------------
                          ELSE
                                ap_data_ref_rec_type.lr_accrued_tax         :=ap_data_ref_rec_type.lr_accrued_tax;
                          END IF;    
                  END IF; **/
           -- ELSIF (ln_count = 0) THEN
              -- ap_data_ref_rec_type.lr_accrued_tax := NULL;               --Added for defect 4948
            END IF;

--Commented for R 1.0.2-Defect#1337
   /* ap_data_conv_rec_type.lr_gl_acct_date        :=ap_data_conv_rec_type.GL_ACOUNTING_DATE;
      ap_data_conv_rec_type.lr_acct_no             :=ap_data_conv_rec_type.ACCT_NO;
      ap_data_conv_rec_type.lr_entity              :=ap_data_conv_rec_type.ENTITY;
      ap_data_conv_rec_type.lr_line_type_code      :=ap_data_conv_rec_type.LINE_TYPE_CODE;
      ap_data_conv_rec_type.lr_line_level_amount   :=ap_data_conv_rec_type.LINE_LEVEL_AMOUNT;
      ap_data_conv_rec_type.lr_vendor_num          :=ap_data_conv_rec_type.VENDOR_NUMBER;
      ap_data_conv_rec_type.lr_vendor_name         :=ap_data_conv_rec_type.VENDOR_NAME;
      ap_data_conv_rec_type.lr_vendor_city         :=ap_data_conv_rec_type.VENDOR_CITY;
      ap_data_conv_rec_type.lr_vendor_state         :=ap_data_conv_rec_type.VENDOR_STATE;
      ap_data_conv_rec_type.lr_voucher_num         :=lcu_ap_invoice_header_rec.VOUCHER_NUM;
      ap_data_conv_rec_type.lr_invoice_num         :=ap_data_conv_rec_type.INVOICE_NUM;
      ap_data_conv_rec_type.lr_invoice_date        :=ap_data_conv_rec_type.INVOICE_DATE;
      ap_data_conv_rec_type.lr_state               :=lcu_ap_invoice_header_rec.STATE;
      ap_data_conv_rec_type.lr_currency            :=ap_data_conv_rec_type.CURRENCY;
      ap_data_conv_rec_type.lr_gross_amount        :=ap_data_conv_rec_type.GROSS_AMOUNT;
      ap_data_conv_rec_type.lr_amount_paid         :=ap_data_conv_rec_type.AMOUNT_PAID;*/
      lc_po_numer        :=NULL;
      ln_po_lin_num      :=NULL;
      lc_po_location_id  :=NULL;
      lc_po_location_num :=NULL;

-------To Check Whether the Invoice is having a matching PO -----------------------------------------------------

        IF ( ap_data_ref_rec_type.lr_po_distribution_id IS NOT NULL) THEN
            BEGIN


                 SELECT   PHA.segment1
                         ,PLA.line_num
                         ,PDA.deliver_to_location_id
                 INTO     lc_po_numer
                         ,ln_po_lin_num
                         ,lc_po_location_id
                 FROM     po_headers                   PHA
                         ,po_lines                    PLA
                         ,po_line_locations           PLLA
                         ,po_distributions            PDA
                 WHERE   PHA.po_header_id         = PLA.po_header_id
                 AND     PLA.po_line_id           = PLLA.po_line_id
                 AND     PLLA.line_location_id    = PDA.line_location_id
                 AND     PDA.po_distribution_id   = ap_data_ref_rec_type.lr_po_distribution_id;

                 IF  (lc_po_location_id IS NOT NULL) THEN

                     SELECT HL.attribute1
                     INTO   lc_po_location_num
                     FROM   hr_locations                HL
                     WHERE  HL.location_id = lc_po_location_id;

                 END IF;

             EXCEPTION
             WHEN OTHERS   THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the PO Details  :'|| SQLERRM );
             END;

               ap_data_conv_rec_type.lr_po_location        :=lc_po_location_num;
               ap_data_conv_rec_type.lr_po_number          :=lc_po_numer;
               ap_data_conv_rec_type.lr_line_num           :=ln_po_lin_num;

------------------------------Calling the Procedure AP_DATA_WRITE_FILE to write into the file  with the PO Details -----------------------------------------------------
             --IF p_NonZero_Tax_Accrued ='N' and ln_count = 0 THEN                         --Added condition for defect #16176   --CR766 commented
             --   ap_data_ref_rec_type.lr_accrued_tax := 0;                                                                      --CR766 commented
             --END IF;                                                                                                           --CR766 commented

               lc_to_write :=  ap_data_ref_rec_type.lr_invoice_source                      --Added as per R 1.0.2-Defect #1337
                               || p_delimiter  || ap_data_ref_rec_type.lr_gl_acct_date
                               || p_delimiter  || ap_data_conv_rec_type.lr_gl_acct_Desc
                               || p_delimiter  || ap_data_ref_rec_type.lr_acct_no
                               || p_delimiter  || ap_data_ref_rec_type.lr_entity
                               || p_delimiter  || ap_data_conv_rec_type.lr_po_location
                               || p_delimiter  || ap_data_conv_rec_type.lr_gl_loc_no
                               || p_delimiter  || ap_data_conv_rec_type.lr_gl_loc_Desc
                               || p_delimiter  || ap_data_ref_rec_type.lr_vendor_state      --Added as per R 1.0.2-Defect #1337
                               || p_delimiter  || ap_data_ref_rec_type.lr_county             --Added as per R 1.1-Defect #2428
                               || p_delimiter  || ap_data_ref_rec_type.lr_vendor_city       --Added as per R 1.0.2-Defect #1337
                               || p_delimiter  || ap_data_ref_rec_type.lr_department
                               || p_delimiter  || ap_data_conv_rec_type.lr_sales_channel_LOB
                               || p_delimiter  || ap_data_ref_rec_type.lr_line_type_code
                               || p_delimiter  || ap_data_ref_rec_type.lr_line_level_amount
                               || p_delimiter  || ap_data_ref_rec_type.lr_vendor_num
                               || p_delimiter  || ap_data_ref_rec_type.lr_vendor_site_code   --Added as per R 1.1-Defect #2428
                               || p_delimiter  || ap_data_ref_rec_type.lr_vendor_name
                               || p_delimiter  || ap_data_ref_rec_type.lr_state
                               || p_delimiter  || ap_data_ref_rec_type.lr_city
                            -- || p_delimiter  || ap_data_conv_rec_type.lr_voucher_num      --Commented as per R 1.0.2-Defect #1337
                               || p_delimiter  || ap_data_ref_rec_type.lr_invoice_num
                               || p_delimiter  || ap_data_ref_rec_type.lr_invoice_date
                             --|| p_delimiter  || ap_data_conv_rec_type.lr_state            --Commented as per R 1.0.2-Defect #1337
                               || p_delimiter  || ap_data_conv_rec_type.lr_po_number
                               || p_delimiter  || ap_data_conv_rec_type.lr_line_num
                               || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_date
                               || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_num
                               || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_amount
                               || p_delimiter  || ap_data_ref_rec_type.lr_currency
                               || p_delimiter  || ap_data_conv_rec_type.lr_sales_tax
                               || p_delimiter  || ap_data_ref_rec_type.lr_gross_amount
                               || p_delimiter  || ap_data_conv_rec_type.lr_payment_date
                               || p_delimiter  || ap_data_ref_rec_type.lr_accrued_tax
                               || p_delimiter  || ap_data_ref_rec_type.lr_amount_paid ;

              --IF p_NonZero_Tax_Accrued ='Y' THEN                                          --Added condition for defect #16176   --CR766 commented
              --    IF ln_count > 0 THEN                                                                                          --CR766 commented
              --      AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);                                --CR766 commented
              --    END IF;                                                                                                       --CR766 commented
              --ELSE                                                                                                              --CR766 commented
                    AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);
              --END IF;                                                                                                           --CR766 commented
          ELSE

------- Calling the Procedure AP_DATA_WRITE_FILE to write into the file  without  the PO Details -----------------------------------------------------
               --IF p_NonZero_Tax_Accrued ='N' and ln_count = 0 THEN                       --Added condition for defect #16176    --CR766 commented
               --   ap_data_ref_rec_type.lr_accrued_tax := 0;                                                                     --CR766 commented
               --END IF;                                                                                                          --CR766 commented
            lc_to_write :=  ap_data_ref_rec_type.lr_invoice_source                       --Added as per R 1.0.2-Defect #1337
                          || p_delimiter  || ap_data_ref_rec_type.lr_gl_acct_date
                          || p_delimiter  || ap_data_conv_rec_type.lr_gl_acct_Desc
                          || p_delimiter  || ap_data_ref_rec_type.lr_acct_no
                          || p_delimiter  || ap_data_ref_rec_type.lr_entity
                          || p_delimiter  || ap_data_conv_rec_type.lr_po_location
                          || p_delimiter  || ap_data_conv_rec_type.lr_gl_loc_no
                          || p_delimiter  || ap_data_conv_rec_type.lr_gl_loc_Desc
                          || p_delimiter  || ap_data_ref_rec_type.lr_vendor_state      --Added as per R 1.0.2-Defect #1337
                          || p_delimiter  || ap_data_ref_rec_type.lr_county             --Added as per R 1.1-Defect #2428
                          || p_delimiter  || ap_data_ref_rec_type.lr_vendor_city       --Added as per R 1.0.2-Defect #1337
                          || p_delimiter  || ap_data_ref_rec_type.lr_department
                          || p_delimiter  || ap_data_conv_rec_type.lr_sales_channel_LOB
                          || p_delimiter  || ap_data_ref_rec_type.lr_line_type_code
                          || p_delimiter  || ap_data_ref_rec_type.lr_line_level_amount
                          || p_delimiter  || ap_data_ref_rec_type.lr_vendor_num
                          || p_delimiter  || ap_data_ref_rec_type.lr_vendor_site_code   --Added as per R 1.1-Defect #2428
                          || p_delimiter  || ap_data_ref_rec_type.lr_vendor_name
                          || p_delimiter  || ap_data_ref_rec_type.lr_state
                          || p_delimiter  || ap_data_ref_rec_type.lr_city
                        --|| p_delimiter  || ap_data_conv_rec_type.lr_voucher_num      --Commented as per R 1.0.2-Defect #1337
                          || p_delimiter  || ap_data_ref_rec_type.lr_invoice_num
                          || p_delimiter  || ap_data_ref_rec_type.lr_invoice_date
                        --|| p_delimiter  || ap_data_conv_rec_type.lr_state            --Commented as per R 1.0.2-Defect #1337
                          || p_delimiter  || ap_data_conv_rec_type.lr_po_number
                          || p_delimiter  || ap_data_conv_rec_type.lr_line_num
                          || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_date
                          || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_num
                          || p_delimiter  || ap_data_conv_rec_type.lr_cr_invoice_amount
                          || p_delimiter  || ap_data_ref_rec_type.lr_currency
                          || p_delimiter  || ap_data_conv_rec_type.lr_sales_tax
                          || p_delimiter  || ap_data_ref_rec_type.lr_gross_amount
                          || p_delimiter  || ap_data_conv_rec_type.lr_payment_date
                          || p_delimiter  || ap_data_ref_rec_type.lr_accrued_tax
                          || p_delimiter  || ap_data_ref_rec_type.lr_amount_paid ;


              --IF p_NonZero_Tax_Accrued ='Y' THEN                                      --Added condition for defect #16176    --CR766 commented
              --    IF ln_count > 0 THEN                                                                                       --CR766 commented
              --      AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);                             --CR766 commented
              --    END IF;                                                                                                    --CR766 commented
              --ELSE                                                                                                           --CR766 commented
	             AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);
	            --END IF;                                                                                                        --CR766 commented
	       END IF;
        --END LOOP;
    END LOOP;--Ref Cursor loop
  -------     Calling the Procedure AP_DATA_WRITE_FILE to Close the file-----------------------------------------------------

        lc_close_file:= 'Y';
        AP_DATA_WRITE_FILE(lc_to_write,p_file_path,lc_open_file_flag,lc_close_file);

-------------- Call the Common file copy Program Copy to $XXFIN_DATA/ftp/out/hyperion--------------

       lc_source_file_name  :=  lc_source_file_path || '/' || gc_file_name;
       lc_dest_file_name    :=  p_dest_file_path  || '/' || gc_file_name;


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copied  Path     : ' || lc_dest_file_name);

      /* ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                               'xxfin'
                                               ,'XXCOMFILCOPY'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,lc_source_file_name
                                               ,lc_dest_file_name
                                               ,'N'
                                               ,NULL
                                              );

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copy Program is submitted '
                                     || ' Request id : ' || ln_req_id);

        commit;

        lb_result:= fnd_concurrent.wait_for_request(ln_req_id,1,0,
                         lc_phase      ,
                         lc_status     ,
                         lc_dev_phase  ,
                         lc_dev_status ,
                         lc_message    );
*/
       ln_req_id_ftp := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,gc_file_name                           --source_file_name
                                               ,Gc_File_Name                           --destination_file_name
                                               ,'Y'                                    -- Delete source file?
                                               ,NULL
                                              );

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The FTP Put Program is submitted '
                                     || ' Request id : ' || ln_req_id_ftp);



    EXCEPTION
    WHEN EX_USER_EXC_CA_ORG_ID  THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while Fetching the Org_IG for Canada  :'
                                     ||'Program'|| SQLERRM );

    WHEN OTHERS THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised in  Procedure AP_DATA_CONV  :'|| SQLERRM );

 END AP_DATA_CONV;

PROCEDURE AP_DATA_WRITE_FILE(  ap_data_conv_write                IN  VARCHAR2
                               ,p_file_path                      IN  VARCHAR2
                               ,p_open_file_flag                 IN  VARCHAR2
                               ,p_close_file_flag                IN  VARCHAR2
                                )
AS

     ln_buffer   BINARY_INTEGER := 32767;

BEGIN


      IF (p_open_file_flag = 'Y' ) AND ( p_close_file_flag ='N') THEN
             BEGIN
  ---------------------------------- Opening the File and writing the headings  -----------------------------------------------

                   gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,'w',ln_buffer);
                   UTL_FILE.PUT_LINE(gt_file,ap_data_conv_write);

             EXCEPTION
             WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file  : '|| SQLERRM);
             END;
      ELSIF (p_open_file_flag = 'N' ) AND ( p_close_file_flag ='N') THEN
--------------------------------------Writing the values  into the file       --------------------------------------------

             UTL_FILE.PUT_LINE(gt_file,ap_data_conv_write);

      ELSIF (p_open_file_flag = 'N' ) AND ( p_close_file_flag ='Y') THEN
--------------------------------------Closing the File      --------------------------------------------

         UTL_FILE.fclose(gt_file);
      END IF;
   EXCEPTION
   WHEN OTHERS             THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised in  Procedure AP_DATA_WRITE_FILE  :'|| SQLERRM );

  END AP_DATA_WRITE_FILE;

END XX_AP_DATA_CONV_PKG;

/