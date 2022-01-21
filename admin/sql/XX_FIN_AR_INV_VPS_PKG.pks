SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE XX_FIN_AR_INV_VPS_PKG
AS
-- +============================================================================================+
-- |  Office Depot                                                                          	|
-- +============================================================================================+
-- |  Name:  XX_FIN_AR_INV_VPS_PKG                                                     	        |
-- |                                                                                            |
-- |  Description:  This package is validate and update VPS invoices                            | 
-- |                to create inv through Auto Invoices.        		                        |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         12-JUN-2017  Thejaswini Rajula    Initial version                              |
-- +============================================================================================+
  PROCEDURE pre_process_invoices(errbuff OUT VARCHAR2,
                                 retcode OUT VARCHAR2,
                                 trans_source IN VARCHAR2 DEFAULT NULL
                                 );
                               
/*PROCEDURE process_auto_invoice(  
                                 errbuff             OUT VARCHAR2
                                ,retcode             OUT VARCHAR2
                                ,p_AI_thread_count   IN  NUMBER
                                ,p_org_id            IN  NUMBER
                                ,p_batch_source_id   IN  NUMBER
                                ,p_batch_source_name IN  VARCHAR2                               
                               ); */

PROCEDURE post_process_invoices(errbuff OUT VARCHAR2,
                                retcode OUT VARCHAR2);
                                
PROCEDURE post_proc_validate_process(errbuff OUT VARCHAR2,
                                     retcode OUT VARCHAR2);                                
                               
END XX_FIN_AR_INV_VPS_PKG;
/
SHOW ERRORS;
