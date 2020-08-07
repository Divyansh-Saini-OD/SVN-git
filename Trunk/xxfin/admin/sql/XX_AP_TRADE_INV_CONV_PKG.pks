create or replace package XX_AP_TRADE_INV_CONV_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_TRADE_INV_CONV_PKG                                                        |
-- |  RICE ID 	 :       			                                                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         14-JUL-2017  Havish Kasina    Initial version                                  |
-- +============================================================================================+
	  
TYPE varchar2_table IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;

PROCEDURE log_exception ( p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		                 ,p_error_msg          IN  VARCHAR2);
						 
PROCEDURE parse(p_delimstring IN  VARCHAR2
               ,p_table       OUT varchar2_table
               ,p_nfields     OUT INTEGER
               ,p_delim       IN  VARCHAR2 DEFAULT '|'
               ,p_error_msg   OUT VARCHAR2
               ,p_retcode     OUT VARCHAR2);

PROCEDURE load_data_to_interface_table(p_errbuf         OUT  VARCHAR2
                                      ,p_retcode        OUT  VARCHAR2
									  ,p_debug          IN   VARCHAR2
									  ,p_status         IN   VARCHAR2);
               
PROCEDURE load_staging(p_errbuf         OUT  VARCHAR2
                      ,p_retcode        OUT  VARCHAR2
                      ,p_filepath       IN   VARCHAR2
                      ,p_file_name 	    IN   VARCHAR2
                      ,p_debug          IN   VARCHAR2);
                      	  
END XX_AP_TRADE_INV_CONV_PKG;
/
SHOW ERRORS;