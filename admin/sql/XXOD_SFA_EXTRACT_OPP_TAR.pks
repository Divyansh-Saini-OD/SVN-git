CREATE OR REPLACE PACKAGE XXOD_SFA_EXTRACT_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                  IT Convergence/Wirpo?Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :  XXOD_TRADE_PAYMENT_PKG                                                               |
-- | Description      :  This Package is used by to Extract Login, Opportunities and Targets Information|
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 17-Oct-2007  	Van Neel	Initial draft version                                              |
-- +===================================================================+                                |

PROCEDURE write_log(p_debug_flag VARCHAR2,
				      p_msg VARCHAR2);


PROCEDURE generate_file(p_directory VARCHAR2
					    ,p_file_name VARCHAR2
					    ,p_request_id NUMBER
					    ,p_error_msg OUT VARCHAR2);


PROCEDURE Extract_SFA_Login(errbuf OUT VARCHAR2, retcode OUT NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      );


PROCEDURE Extract_SFA_OPP(errbuf OUT VARCHAR2, retcode OUT NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      );

PROCEDURE Extract_SFA_Target(errbuf OUT VARCHAR2, retcode OUT NUMBER,
					     p_year NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      );



END XXOD_SFA_EXTRACT_PKG;
/
