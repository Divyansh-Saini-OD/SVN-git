SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XXOD_TRADE_PAYMENT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE xxod_trade_payment_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wipro                                            |
-- +===================================================================+
-- | Name             :  XXOD_TRADE_PAYMENT_PKG                        |
-- | Description      :  This Package is used by to Extract Vendor ,   |
-- |                     Invoice and Journal Information               |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           	Remarks                |
-- |=======   ==========  =============    ======================      |
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar     Initial draft version     |
-- |1.1       20-Mar-09     Manovinayak      Changes for defect 12418  |
-- +===================================================================+
AS
PROCEDURE write_log(p_debug_flag VARCHAR2,
p_msg VARCHAR2);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wipro                                            |
-- +===================================================================+
-- | Name             :  write_log				       |
-- | Description      :  This procedure is used to write in to log file|
-- |                     based on the debug flag                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks                   |
-- |=======   ==========  	=============    ===========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version        |
-- +===================================================================+
PROCEDURE generate_file(p_directory VARCHAR2
,   p_file_name VARCHAR2
,   p_request_id NUMBER);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  generate_file			                          |
-- | Description      :  This procedure is used to generate a output   |
-- |                     extract file and it calls XPTR                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks                   |
-- |=======   ==========  	=============    ===========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version        |
-- +===================================================================+
FUNCTION get_legacy_value(p_translate_id NUMBER
,   p_target_value VARCHAR2
)
RETURN VARCHAR2;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  Get_Legacy_Value				                    |
-- | Description      :  This function is used to get the legacy value |
-- |                     from the translations table                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks                   |
-- |=======   ==========  	=============    ===========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version        |
-- +===================================================================+
PROCEDURE extract_vendor(p_ret_code OUT NUMBER
,   p_err_msg OUT VARCHAR2
,   p_directory VARCHAR2
,   p_file_name VARCHAR2
,   p_debug_flag VARCHAR2
,   p_file_path  VARCHAR2
);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  Extract_Vendor 				                    |
-- | Description      :  This procedure is used to extract the vendor  |
-- |                     information                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks                   |
-- |=======   ==========  	=============    ===========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version        |
-- |DRAFT 1.1 09-Oct-2008  Ganesan JV 	   Added file_path Parameter    |
-- +===================================================================+
PROCEDURE extract_journal(p_ret_code OUT NUMBER
,   p_err_msg OUT VARCHAR2
,   p_directory VARCHAR2
,   p_file_name VARCHAR2
,   p_debug_flag VARCHAR2
,   p_file_path  VARCHAR2
,   p_period_name VARCHAR2  -- Added for defect 12418
);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  Extract_Journal 										  |
-- | Description      :  This procedure is used t extract the journal  |
-- |                     details for the last close period             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks         |
-- |=======   ==========  	=============    ==========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version   |
-- |DRAFT 1.1 09-Oct-2008  Ganesan JV 	   Added file_path Parameter   |
-- |DRAFT 1.2 20-Oct-2009  Mano Vinayak   Added period_name parameter  |
-- +===================================================================+
PROCEDURE extract_invoices(p_ret_code OUT NUMBER
,   p_err_msg OUT VARCHAR2
,   p_directory VARCHAR2
,   p_file_name VARCHAR2
,   p_debug_flag VARCHAR2
,   p_file_path  VARCHAR2 
,   p_period_name VARCHAR2 -- Added for defect 12418
);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  extract_invoices			                         |
-- | Description      :  This procedure is used to extract the invoices|
-- |                     information based on 		                     |
---                             last closed period     					       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks                  |
-- |=======   ==========  	=============    ==========================|
-- |DRAFT 1.0 11-Oct-2007  Senthil Kumar 	Initial draft version        |
-- |DRAFT 1.1 09-Oct-2008  Ganesan JV 	   Added file_path Parameter   |
-- |DRAFT 1.2 20-Oct-2009  Mano Vinayak   Added period_name parameter  |
-- +===================================================================+
END xxod_trade_payment_pkg;
/

SHO ERR;
