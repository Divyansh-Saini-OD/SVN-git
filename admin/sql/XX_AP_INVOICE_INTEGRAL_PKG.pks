create or replace package XX_AP_INVOICE_INTEGRAL_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_INVOICE_INTEGRAL_PKG                                                      |
-- |  RICE ID 	 :       			                                                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05/04/2017   Havish Kasina    Initial version                                  |
-- | 1.1         12/25/2017   Havish Kasina    Modified the procedure parameters to seperate    |
-- |                                           the programs                                     |
-- |1.2          06/28/2018   Vivek Kumar         NAIT-48272 (Defect#45304) Send email alert    | 
-- |                                              when there is corrupt File                    |                       
-- +============================================================================================+
	  
TYPE varchar2_table IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
v_inv_num                   VARCHAR2(200);   ---- Added NAIT-48272 (Defect#45304)
v_ven_num                   VARCHAR2(200);   ---- Added NAIT-48272 (Defect#45304)
v_po_num                    VARCHAR2(200);   ---- Added NAIT-48272 (Defect#45304)	


PROCEDURE log_exception ( p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		                 ,p_error_msg          IN  VARCHAR2);
						 
PROCEDURE parse_tdm_dci_file(p_string      IN  VARCHAR2
							,p_table       OUT varchar2_table
							,p_error_msg   OUT VARCHAR2
							,p_errcode     OUT VARCHAR2);
							
PROCEDURE parse_csi_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2);
													
PROCEDURE parse_drp_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2);
						
PROCEDURE parse_edi_file(p_string      IN  VARCHAR2
						,p_table       OUT varchar2_table
						,p_line_table  OUT varchar2_table
						,p_error_msg   OUT VARCHAR2
						,p_errcode     OUT VARCHAR2); 

PROCEDURE load_data_to_staging(p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  VARCHAR2   
                              ,p_source         IN   VARCHAR2
                              ,p_frequency_code IN   VARCHAR2
                              ,p_debug          IN   VARCHAR2
							  ,p_from_date      IN   VARCHAR2
					          ,p_to_date        IN   VARCHAR2
							  ,p_date           IN   VARCHAR2);
               
PROCEDURE load_prestaging(p_errbuf         OUT  VARCHAR2
                         ,p_retcode        OUT  VARCHAR2
                         ,p_filepath       IN   VARCHAR2
					     ,p_source         IN   VARCHAR2
                         ,p_file_name 	   IN   VARCHAR2
                         ,p_debug          IN   VARCHAR2);
                         	  
END XX_AP_INVOICE_INTEGRAL_PKG;
/
SHOW ERRORS;