create or replace 
PACKAGE XXOD_OMX_AR_UPD_DUEDATE_PKG
AS
-- +============================================================================================+
-- |  Office Depot                                                                          	|
-- +============================================================================================+
-- |  Name:  XXOD_OMX_AR_UPD_DUEDATE_PKG                                                     	|
-- |                                                                                            |
-- |  Description:  This package updates the Due Date of  all OMX ODN invoices                  | 
-- |                									        		                        |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         28-FEB-2017  Punit Gupta      Initial version                                  |
-- +============================================================================================+
  
PROCEDURE post_process_invoices(errbuff OUT VARCHAR2,
                                retcode OUT VARCHAR2);
                                
END XXOD_OMX_AR_UPD_DUEDATE_PKG;
/