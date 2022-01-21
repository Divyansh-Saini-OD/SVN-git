CREATE OR REPLACE
PACKAGE XXOD_GL_IRS_QTRLY_EXTRACT_PKG AS
-- +===========================================================================+
-- |2.0 - 19-Dec-2013 - Jay Gupta - Defect#27309 - Adding Ledger Parameter     |
-- |2.1 - 19-Mar-2014 - Jay Gupta - Defect#28419 - Removing Ledger Parameter   |
-- |2.2-  08-DEC-2016 - Punita Kumari -Defect#40349- Incorporate the change of |
-- |                                   defect#31281 with retrofit 12.2         |
-- +===========================================================================+
PROCEDURE Extract_Journal(p_ret_code OUT NUMBER
				 ,p_err_msg  OUT VARCHAR2
		--V2.1		 ,p_ledger_id NUMBER -- V2.0
				 ,p_directory VARCHAR2
                 ,p_file_name VARCHAR2
				 ,p_debug_flag VARCHAR2
                 ,p_file_path  VARCHAR2
                 ,p_period_name_begin VARCHAR2
                 ,p_period_name_end VARCHAR2);
 
PROCEDURE Extract_COA(p_ret_code OUT NUMBER
		     ,p_err_msg  OUT VARCHAR2
		     ,p_directory VARCHAR2
		     ,p_file_name VARCHAR2
		     ,p_debug_flag VARCHAR2
             ,p_file_path  VARCHAR2);
                     
PROCEDURE Extract_Balances(p_ret_code OUT NUMBER
			   ,p_err_msg  OUT VARCHAR2
          --V2.1     ,p_ledger_id NUMBER -- V2.0
			   ,p_directory VARCHAR2
			   ,p_file_name VARCHAR2
			   ,p_debug_flag VARCHAR2
               ,p_file_path  VARCHAR2
               ,p_period_name_begin VARCHAR2
               ,p_period_name_end VARCHAR2);
			   
/*For defect# 31281*/               
PROCEDURE copyftp(p_ret_code OUT NUMBER
             	 ,p_err_msg  OUT VARCHAR2
		 ,p_source_file  VARCHAR2
                 ,p_dest_directory      VARCHAR2
                 ,p_dest_file		VARCHAR2
                 ,p_parent_request_id 	NUMBER); 

END XXOD_GL_IRS_QTRLY_EXTRACT_PKG;
/