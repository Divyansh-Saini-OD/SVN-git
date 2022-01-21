create or replace package XX_PO_POM_INT_EXT_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 	 :  XX_PO_POM_INT_EXT_PKG                                                       |
-- |  RICE ID 	 :  I2193_PO to EBS Interface     			                        			|
-- |  Description:  Use this package for all extra functionality hook to PO Interface     		|
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01/22/2018   Madhu Bolli   Initial version                                     |
-- +============================================================================================+


/************************************************************************************************
 *	launch_trade_unappr_po_wf()								  									*
 *  This procedure will be used to launch the POApproval for Unapproved PO's which		  		*
 *  are in 'INCOMPLETE'/'REQUIRES REAPPROVAL status.											*
 *  TestCase: Sometimes when PO interface creates PO, the PO creates but the approval workflow  *
 *            never creates andand it will be in this INCOMPLETE/REQUIRES REAPPROVAL status.    *
 * 									  															*
 ************************************************************************************************/

PROCEDURE launch_trade_unappr_po_wf(p_errbuf OUT VARCHAR2
							,p_retcode OUT VARCHAR2
							,p_run_for_days NUMBER DEFAULT 1
							,p_po_number    VARCHAR2
						    ,p_debug       VARCHAR2); 
                   	  
END XX_PO_POM_INT_EXT_PKG;
/