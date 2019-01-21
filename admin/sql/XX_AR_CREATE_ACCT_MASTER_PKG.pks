SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM         ON

PROMPT Creating Package Specification XX_AR_CREATE_ACCT_MASTER_PKG 
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE XX_AR_CREATE_ACCT_MASTER_PKG
AS


-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       WIPRO Technologies                                |
-- +=========================================================================+
-- | Name : XX_AR_CREATE_ACCT_MASTER_PKG                                     |
-- | RICE ID :  E0080                                                        |
-- | Description : The master will call the child (E0080B) based on the      |
-- |               batching logic and then submitting auto invoice master    |
-- |               program and E0080A,E0081, XX_AR_EXCL_HED_INVOICES         |
-- |               and Prepayments Matching Program                          |
-- | Change Record:                                                          |
-- |===============                                                          |
-- |Version   Date              Author              Remarks                  |
-- |======   ==========     =============        =========================== |
-- |Draft 1A  03-Mar-08      Manovinayak         Initial version             |
-- |                         Wipro Technologies                              |
-- |1.0       11-Mar-08      Manovinayak         Added two concurrent        |
-- |                         Wipro Technologies  requests for the            |
-- |                                             defects#4609,4076           |
-- |1.1       20-Mar-08      Manovinayak         Added Procedure             |
-- |                         Wipro Technologies  XX_AR_POST_UPDATES_PROC     |
-- |                                             for PERF                    |
-- |1.2       13-Aug-08      Manovinayak         Added the function          |
-- |                         Wipro Technologies  XX_AR_STATUS_FUNC for       |
-- |                                             the defect#9687             |
-- |1.3       09-Sep-08      Sowmya.M.S          Added a procedure           |
-- |                         Wipro               XX_HVOP_RUNNING_CHECK_PROC  |
-- |                                             for defect#10864            |
-- |1.4       10-Oct-08      Sowmya.M.S          Added a parameter           |
-- |                         Wipro               p_check_record based on     |
-- |                                             which HVOP_CHECK_PROC       |
-- |                                             will be called - for        |
-- |                                             Defect#10864                |
-- |1.5       15-Oct-08      Sowmya.M.S          Added a parameter           |
-- |                         Wipro               p_wave_number to identify   |
-- |                                             which Wave- Defect#11957    |
-- |1.6       17-MAR-2011    P.Marco             E0080 Release 11.3          | 
-- |                                             Summarization of POS        |
-- |                                             Sales/Returns               |
-- | 12.0      24-OCT-2012   R.Aldridge          Defect 20687 - Enable batch |
-- |                                             group processing            |
-- +=========================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_CREATE_ACCT_MASTER_PROC                               |
-- | Description : The procedure will call the child (E0080B) based on   |
-- |               the batching logic and then submitting auto invoice   |
-- |               master program and E0080A,E0081,                      |
-- |               XX_AR_EXCL_HED_INVOICES and                           |
-- |               Prepayments Matching Program                          |
-- | Parameters :p_batch_source,p_max_thread_count,p_batch_size,         |
-- |             p_display_log,p_error_message,p_number_of_instances,    |
-- |             p_number_of_instances,p_rerun_flag,p_email_address      |
-- |             ,p_autoinvoice_batch_source,p_sleep and p_wait_time     |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_CREATE_ACCT_MASTER_PROC(
                                        x_err_buff                  OUT VARCHAR2
                                       ,x_ret_code                  OUT NUMBER
                                       ,p_org_id                    IN  NUMBER
                                       ,p_batch_group               IN  VARCHAR2
                                       ,p_batch_source              IN  VARCHAR2 DEFAULT NULL
                                       ,p_max_thread_count          IN  NUMBER
                                       ,p_batch_size                IN  NUMBER
                                       ,p_display_log               IN  VARCHAR2  DEFAULT 'N'
                                       ,p_error_message             IN  VARCHAR2  DEFAULT 'N'
                                       ,p_number_of_instances       IN  NUMBER
                                       ,p_rerun_flag                IN  VARCHAR2
                                       ,p_email_address             IN  VARCHAR2 DEFAULT NULL
                                       ,p_autoinvoice_batch_source  IN  VARCHAR2
                                       ,p_check_record              IN  VARCHAR2 DEFAULT 'N' 
                                       ,p_sleep_time                IN  NUMBER    
                                       ,p_wave_number               IN  VARCHAR2  
                                       );
-- +=====================================================================+
-- | Name :  XX_AR_POST_UPDATES_PROC                                     |
-- | Description : The procedure will call the post update programs      |
-- |               E0080A,E0081,XX_AR_EXCL_HED_INVOICES and              |
-- |               Prepayments Matching Program                          |
-- | Parameters :p_batch_source,p_display_log,p_error_message,           |
-- |             p_number_of_instances,p_number_of_instances,p_rerun_flag|
-- |             p_email_address, p_autoinvoice_batch_source,p_request_id|
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

--Added procedure on 20-Mar-2008 for PERF
PROCEDURE XX_AR_POST_UPDATES_PROC(
                                  p_batch_group               IN  VARCHAR2
                                 ,p_batch_source              IN  VARCHAR2
                                 ,p_display_log               IN  VARCHAR2 DEFAULT 'N'
                                 ,p_error_message             IN  VARCHAR2 DEFAULT 'N'
                                 ,p_rerun_flag                IN  VARCHAR2
                                 ,p_email_address             IN  VARCHAR2 DEFAULT NULL
                                 ,p_autoinvoice_batch_source  IN  VARCHAR2  
                                 ,p_request_id                IN  NUMBER
                                 ,p_org_id                    IN  NUMBER);

-- +=====================================================================+
-- | Name :  XX_AR_STATUS_FUNC                                           |
-- | Description : This function will derive and return the final status |
-- |              of the Master Program based on its child program status|
-- | Returns :  x_ret_code                                               |
-- +=====================================================================+
   FUNCTION XX_AR_STATUS_FUNC  RETURN  NUMBER;


--Added procedure for defect#10864
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- | Name : XX_HVOP_RUNNING_CHECK_PROC                                   |
-- +=====================================================================+
-- | Description :   To check if HVOP process is running when  E0080     |
-- |                 program polls  records.                             |
-- |  Parameters :   p_sleep_time , p_batch_source                       |
-- +=====================================================================+
PROCEDURE   XX_HVOP_RUNNING_CHECK_PROC(
                                        p_sleep_time    IN  NUMBER
                                       ,p_batch_source  IN  VARCHAR2
                                       ,p_batch_group   IN  VARCHAR2
                                       );

END XX_AR_CREATE_ACCT_MASTER_PKG;
/
SHO ERR;