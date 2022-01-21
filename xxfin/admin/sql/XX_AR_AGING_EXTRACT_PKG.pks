SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_AGING_EXTRACT_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_AR_AGING_EXTRACT_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_AGING_EXTRACT_PKG                       |
-- | Description      :  This Package is used by to Extract the        |
-- |                     Aging details at the customer level           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV 	    Initial draft version      |
-- |                                        developed from the AR AGING|
-- |                                        Report - defect 13502      |
-- |1.1       24-Sep-09    Harini G         Modified code to remove    |
-- |                                        collection strategy parameter|
-- |                                        for defect 2322            |
-- +===================================================================+
PROCEDURE AR_AGING_EXTRACT(p_ret_code            OUT   NUMBER
			   ,p_err_msg            OUT   VARCHAR2
                           ,p_reporting_level          VARCHAR2
                           ,p_reporting_entity_id      VARCHAR2
			   ,p_dynamic_group            VARCHAR2
			   ,p_181_past_days_low        NUMBER
			   ,p_181_past_days_high       NUMBER
			   ,p_61_past_days_low         NUMBER
			   ,p_61_past_days_high        NUMBER
			   ,p_31_past_days_low         NUMBER
			   ,p_31_past_days_high        NUMBER
			   ,p_outstanding_amt_low      NUMBER
			   ,p_outstanding_amt_high     NUMBER
			   ,p_collector_low            VARCHAR2
			   ,p_collector_high           VARCHAR2
			   ,p_customer_class           VARCHAR2
			   --,p_collection_strategy      VARCHAR2   Commented for defect 2322
			   ,p_last_payment_date_low    VARCHAR2
			   ,p_last_payment_date_high   VARCHAR2
			   ,p_invoice_date_low         VARCHAR2
			   ,p_invoice_date_high        VARCHAR2
			   ,p_as_of_date               VARCHAR2
			   ,p_customer_num_low         VARCHAR2
			   ,p_customer_num_high        VARCHAR2
			   ,p_salesrep_low             VARCHAR2
			   ,p_salesrep_high            VARCHAR2
			   ,p_debug_flag               VARCHAR2);

    --------------------------------------------------------------------------------------------  
    --Commenting the function that gets the Collection Strategy for defect 2322 - START
    --------------------------------------------------------------------------------------------
/*
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                          Wipro-Office Depot                                |
-- +============================================================================+
-- | Name             :  get_collection_strategy		                |
-- | Description      :  This Procedure is to get the customer collection       |
-- |                       strategy information                                 |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        	Author           	Remarks                 |
-- |=======   ==========  	=============    ===============================|
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV 	    Initial draft version               |
-- |                                        developed from the AR AGING         |
-- |                                        Report                              |
-- +============================================================================+

FUNCTION get_collection_strategy(p_collection_level VARCHAR2
                                ,p_site_use_id NUMBER
				,p_cust_id NUMBER
				,p_party_id NUMBER)
RETURN VARCHAR2;
*/
    --------------------------------------------------------------------------------------------  
    --Commenting the function that gets the Collection Strategy for defect 2322 - END
    --------------------------------------------------------------------------------------------
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                          Wipro-Office Depot                                |
-- +============================================================================+
-- | Name             :  write_log				                |
-- | Description      :  This Function is to get Collection Strategy Information|
-- |                     at the passed level                                    |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        	Author           	Remarks                 |
-- |=======   ==========  	=============    ===============================|
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV 	    Initial draft version               |
-- |                                        developed from the AR AGING         |
-- |                                        Report                              |
-- +============================================================================+
PROCEDURE write_log(p_debug_flag VARCHAR2
		    ,p_msg VARCHAR2);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  IT Convergence/Wirpo?Office Depot                |
-- +===================================================================+
-- | Name             :  write_log				       |
-- | Description      :  This procedure is used to write in to log file|
-- |                     based on the debug flag                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        	Author           	Remarks        |
-- |=======   ==========  	=============    ======================|
-- |DRAFT 1.0 06-Mar-2009  Ganesan JV 	    Initial draft version      |
-- |                                        developed from the AR AGING|
-- |                                        Report                     |
-- +===================================================================+
END XX_AR_AGING_EXTRACT_PKG;
/
SHO ERR;
