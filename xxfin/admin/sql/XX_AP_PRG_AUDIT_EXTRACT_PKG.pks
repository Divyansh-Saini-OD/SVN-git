SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE  BODY XX_AP_PRG_AUDIT_EXTRACT_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE XX_AP_PRG_AUDIT_EXTRACT_PKG AS
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  IT Office Depot                                                                 |
-- +==================================================================================================+
-- | Name             :  XX_AP_AUDIT_EXTRACT_PKG                                                      |
-- | Description      :  This Package is used to Extract Audit data requested from PRG.               |
-- | RICE id          :  I1142                                                                        |
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Version   Date          Author          Remarks                                                   |
-- |=======   ==========    =============   ==========================================================|
-- | 1.0      27-OCT-2010   Lenny Lee       Initial programming.                                      |
-- | 1.1      21-JUL-2011   Lenny Lee       Defect# 12694  modify local variable l_description to     |
-- |                                        varchar2(240).                                            |
-- | 1.2      22-Jul-2013   Paddy Sanjeevi  Modified for R12                                          |
-- | 1.3      24-Jan-2014   Paddy Sanjeevi  Modified for defect 27400                                 |
-- | 1.4      27-JAN-2014   Deepak V        Defect# 27400                                             |
-- | 1.5      03-Feb-2014   Paddy Sanjeevi  Defect# 27400                                             |
-- | 1.6      25-AUG-2014   Madhan Sanjeevi Defect# 31315, 31345                                      |
-- | 1.7      04-NOV-2015   Harvinder Rkahra Retroffit R12.2                                          |
---| 1.8      07-AUG-2018   Priyam Parmar   DEFECT # 49742  CSI Sales Extract                         |
---| 1.9      14-AUG-2018   Jitendra Atale  DEFECT # NAIT-53790 for AP_INVOICES_LINES_ALL Extract     |
---|                                        DEFECT # NAIT-53791 for MTL_SYSTEMS_ITEMS_B Extract       | 
---| 2.0      10-SEP-2018   Jitendra Atale  DEFECT # NAIT-56507 for CSISALEs Extract Name change      |
---| 2.1      10-SEP-2018   Priyam Parmar   DEFECT # NAIT-59122 for XX_AP_RTV_HDR_ATTR and XX_AP_RTV_LINES_ATTR |
-- +==================================================================================================+

PROCEDURE Extract_ap_terms_tl(p_ret_code OUT NUMBER
			  	,p_err_msg  OUT VARCHAR2
			  	,p_directory   VARCHAR2
	   			,p_file_name   VARCHAR2 :='OD_AP_PRG_ap_terms_tl.txt'
			    ,p_debug_flag  VARCHAR2
          ,p_file_path   VARCHAR2
          ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_terms_lines(p_ret_code OUT NUMBER
		      ,p_err_msg  OUT VARCHAR2
		      ,p_directory VARCHAR2
		      ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_terms_lines.txt'
		      ,p_debug_flag VARCHAR2
          ,p_file_path  VARCHAR2
          ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_check_stocks_all(p_ret_code OUT NUMBER
		      ,p_err_msg  OUT VARCHAR2
		      ,p_directory VARCHAR2
		      ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_check_stocks_all.txt'
		      ,p_debug_flag VARCHAR2
          ,p_file_path  VARCHAR2
          ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_checks_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_checks_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_inv_dist_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_inv_dist_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_inv_pymnt_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_inv_pymnt_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
          ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_rcv_trans(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_rcv_trans.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_rcv_ship_hdr(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_rcv_ship_hdr.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_rcv_ship_line(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_rcv_ship_line.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_line_loc_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_line_loc_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_line_types_b(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_line_types_b.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_distr_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_distr_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_lines_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_lines_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_headers_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_headers_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_invoices_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_invoices_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_ap_batches_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_batches_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_vendor_sites_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_vendor_sites_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_vendors(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_vendors.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_po_vendor_contacts(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_po_vendor_contacts.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_gl_code_combo(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_gl_code_combo.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_hr_locations_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_hr_loc_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_lookup_values(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_lookup_values.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_id_flexs(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_id_flexs.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_id_flex_segments(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_id_flex_segments.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_id_flex_structures(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_id_flex_structures.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_flex_values(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_flex_values.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);

PROCEDURE Extract_fnd_flex_value_hier(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_fnd_flex_value_hier.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);


PROCEDURE Extract_ap_tax_codes_all(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_tax_codes_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);


PROCEDURE Extract_mtl_categories_v(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_mtl_categories_v.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  VARCHAR2);


PROCEDURE zipping_files(p_ret_code OUT NUMBER
		     ,p_err_msg     OUT VARCHAR2
		     ,p_directory    IN VARCHAR2
		     ,p_file_name    IN VARCHAR2
		     ,p_debug_flag   IN VARCHAR2
         ,p_file_path    IN VARCHAR2
         );
PROCEDURE Extract_xx_ap_trade_inv_lines (p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_CSISALE_XX_AP_TRADE_INV_LINES.txt'--'OD_AP_PRG_xx_ap_trade_inv_lines.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  varchar2);
PROCEDURE Extract_ap_invoice_lines_all (p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory varchar2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_ap_invoice_lines_all.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date VARCHAR2
         ,p_no_of_days  varchar2);
PROCEDURE Extract_mtl_system_items_b (p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory varchar2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_mtl_system_items_b.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,P_CUTOFF_DATE varchar2
         ,p_no_of_days  varchar2);
PROCEDURE Extract_xx_ap_rtv_hdr_attr (p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
	   		 ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2 := 'OD_AP_PRG_xx_ap_rtv_hdr_attr.txt'
		  	 ,p_debug_flag VARCHAR2
         ,p_file_path  VARCHAR2
         ,p_cutoff_date varchar2
         ,p_no_of_days  VARCHAR2);
         
PROCEDURE Extract_xx_ap_rtv_lines_attr(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_xx_ap_rtv_lines_attr.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date varchar2 ,
    p_no_of_days  VARCHAR2);

END XX_AP_PRG_AUDIT_EXTRACT_PKG;
/