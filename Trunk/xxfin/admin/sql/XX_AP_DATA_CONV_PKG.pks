create or replace
PACKAGE XX_AP_DATA_CONV_PKG
AS
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                       WIPRO Technologies                                	   |
-- +=============================================================================+
-- | Name   :      AP Data Conversion                                         	 |
-- | Rice ID:      R1090                                                     	   |
-- |                                                                         	   |
-- |                                                                         	   |
-- |Change Record:                                                           	   |
-- |===============                                                          	   |
-- |Version   Date          Author              Remarks                      	   |
-- |=======   ==========   ===============      =================================+
-- |1.0                    Samitha U M          Initial version              	   |
-- |1.1                    Samitha U M          Added State Column           	   |
-- |                                            Defect #3719                 	   |
-- |1.2      17-AUG-09     Ganga Devi R         Added Parameters and         	   |
-- |                                            Record Type for              	   |
-- |                                            R 1.0.2-Defect #1337         	   |
-- |1.3      19-SEP-09     Rani asaithambi      Added County as a parameter,	   |
-- |                                            included the field county,	     |
-- |                                            vendor_site_id for the           |
-- |                                            R 1.1-Defect #2428               |
-- |1.4      16-SEP-10     Joe Klein            CR766 Added                      |
-- |                                            distribution_line_number as a    |
-- |3.0       19-MARCH-2014                   MODIFIED FOR DEFECT 28918
--             |

-- +=============================================================================+

-- +=============================================================================+
-- | Name       : AP_DATA_CONV                                               	   |
-- | Parameters : x_error_buff ,x_ret_code,p_invoice_source                  	   |
-- |             ,p_state_from,p_state_to,p_city,p_county,p_location             |
-- |             ,p_legal_entity,p_acctno_from,p_acctno_to                   	   |
-- |             ,p_NonZero_Tax_Accrued,p_from_date,p_to_date,p_delimiter    	   |
-- |             ,p_file_path,p_dest_file_path,p_file_name,p_file_extension  	   |
-- +=============================================================================+

--Added Record type for defect #1337
TYPE ap_data_ref_rec  IS RECORD (lr_invoice_source             ap_invoices_all.source%TYPE
                                ,lr_invoice_id                 ap_invoices_all.invoice_id%TYPE
                                ,lr_invoice_dist_id            ap_invoice_distributions_all.invoice_distribution_id%TYPE
                                ,lr_invoice_num                ap_invoices_all.invoice_num%TYPE
                                ,lr_amount_paid                ap_invoices_all.amount_paid%TYPE
                                ,lr_line_type_code             ap_invoice_distributions_all.line_type_lookup_code%TYPE
                                ,lr_po_distribution_id         ap_invoice_distributions_all.po_distribution_id%TYPE
                                ,lr_accrued_tax                ap_invoice_distributions_all.attribute8%TYPE
                                ,lr_line_level_amount          ap_invoice_distributions_all.amount%TYPE
                                ,lr_gross_amount               ap_invoiceS_all.invoice_amount%TYPE
                                ,lr_invoice_date               ap_invoices_all.invoice_date%TYPE
                                ,lr_vendor_state               fnd_flex_values.attribute4%TYPE
                                ,lr_county                     po_vendor_sites_all.county%TYPE     --Added for the defect 2428
                                ,lr_vendor_city                hr_locations.town_or_city%TYPE
                                ,lr_status_flag                ap_invoices_all.payment_status_flag%TYPE
                                ,lr_acct_no                    gl_code_combinations.segment3%TYPE
                                ,lr_entity                     gl_code_combinations.segment1%TYPE
                                ,lr_location                   gl_code_combinations.segment4%TYPE
                                ,lr_lob                        gl_code_combinations.segment6%TYPE
                                ,lr_gl_acct_date               DATE
                                ,lr_vendor_id                  po_vendor_sites_all.vendor_id%TYPE
                                ,lr_vendor_site_code             po_vendor_sites_all.vendor_site_code%TYPE   --Added for the defect 2428
                                ,lr_vendor_name                po_vendors.vendor_name%TYPE
                                ,lr_state                       po_vendor_sites_all.state%TYPE
                                ,lr_city                        po_vendor_sites_all.city%TYPE
                                ,lr_currency                   ap_invoices_all.invoice_currency_code%TYPE
                                ,lr_dist_code                  ap_invoice_distributions_all.dist_code_combination_id%TYPE
                                ,lr_department                 gl_code_combinations.segment2%TYPE
                                ,lr_org_id                     ap_invoices_all.org_id%TYPE
                                ,lr_vendor_num                 po_vendor_sites_all .vendor_id%TYPE
                                ,lr_distribution_line_number   ap_invoice_distributions_all.distribution_line_number%TYPE  --CR766 added
                                );
--Commented some Record variable for defect #1337
TYPE ap_data_conv_rec IS RECORD (--lr_gl_acct_date                  DATE
                                  lr_gl_acct_Desc                  fnd_flex_values_vl.description%TYPE
                              -- ,lr_acct_no                       gl_code_combinations.segment3%TYPE
                              -- ,lr_entity                        gl_code_combinations.segment1%TYPE
                                 ,lr_po_location                   po_distributions_all.deliver_to_location_id%TYPE
                                 ,lr_gl_loc_no                     gl_code_combinations.segment1%TYPE ---- Added  for defect 3719
                                 ,lr_gl_loc_Desc                   fnd_flex_values_vl.description%TYPE
                               --,lr_department                    fnd_flex_values_vl.description%TYPE
                                 ,lr_sales_channel_LOB             fnd_flex_values_vl.description%TYPE
                               --,lr_line_type_code                ap_invoice_distributions_all.line_type_lookup_code%TYPE
                               --,lr_line_level_amount             ap_invoice_distributions_all.amount%TYPE
                               --,lr_vendor_num                    po_vendor_sites_all .vendor_id%TYPE
                               --,lr_vendor_name                   po_vendors.vendor_name%TYPE
                              -- ,lr_voucher_num                   ap_invoices_all.voucher_num %TYPE
                               --,lr_invoice_num                   ap_invoices_all.invoice_num%TYPE
                               --,lr_invoice_date                  ap_checks_all.check_date%TYPE
                                 ,lr_po_number                     po_headers_all.segment1%TYPE
                                 ,lr_line_num                      po_lines_all.line_num%TYPE
                                 ,lr_cr_invoice_date               DATE
                              -- ,lr_state                         fnd_flex_values.attribute4%TYPE ---- Added  for defect 3719
                                 ,lr_cr_invoice_num                ap_invoices_all.invoice_num%TYPE
                                 ,lr_cr_invoice_amount             ap_invoices_all.invoice_amount%TYPE
                               --,lr_currency                      ap_invoices_all.invoice_currency_code%TYPE
                                 ,lr_sales_tax                     ap_invoices_all.invoice_amount%TYPE
                               --,lr_gross_amount                  ap_invoices_all.invoice_amount%TYPE
                                 ,lr_payment_date                  DATE
                               --,lr_accrued_tax                   ap_invoice_distributions_all.attribute8%TYPE
                                --,lr_amount_paid                   ap_invoices_all.amount_paid  %TYPE
                                   );

--Added few more parameters as per R 1.0.2-Defect #1337
PROCEDURE AP_DATA_CONV(  x_error_buff             OUT      VARCHAR2
                        ,x_ret_code               OUT      NUMBER
                        ,P_Invoice_Source         In       Varchar2
                       ,P_Org_Id                 In       Number

                        ,p_state_from             IN       VARCHAR2
                        ,p_state_to               IN       VARCHAR2
		                  	,p_county                 IN       VARCHAR2  --Added for the defect 2428
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
                      );

PROCEDURE AP_DATA_WRITE_FILE( ap_data_conv_write                IN  VARCHAR2
                             ,p_file_path                      IN  VARCHAR2
                             ,p_open_file_flag                 IN  VARCHAR2
                             ,p_close_file_flag                IN  VARCHAR2
                             );

END XX_AP_DATA_CONV_PKG;

/