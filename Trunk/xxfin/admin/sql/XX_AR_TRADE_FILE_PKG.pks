 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF 
 SET FEEDBACK OFF
 SET TERM ON  

 PROMPT CREATING PACKAGE SPEC XX_AR_TRADE_FILE_PKG
 PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL
 WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_AR_TRADE_FILE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_TRADE_FILE_PKG  I2097(Defect 2795)      |
-- | Description      :  This Package is used to transmit the Trade    |
-- |                     File to third party Vendors such as           |
-- |                     DNB,EQUIFAX and CRM with the aging Information|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-Oct-2009  Vinaykumar S   Initial draft version(CR 600)|
-- |2.0       12-JUL-2010  Debra Gaudard  CR 785                                                                   |
-- +===================================================================+

/*  CR 785 removed p_credit_agent from the parms */
PROCEDURE XX_AR_TRADE_FILE_MAIN(x_errbuf            OUT  NOCOPY VARCHAR2
                               ,x_retcode           OUT  NOCOPY VARCHAR2
                               ,p_thread_count       IN   NUMBER
                               );

/*  CR 785 removed p_credit_agent from the parms */
PROCEDURE XX_AR_TRADE_FILE_EXTRACT ( x_errbuf       OUT  NOCOPY    VARCHAR2
                                    ,x_retcode      OUT  NOCOPY    VARCHAR2
                                    ,p_thread_count IN   NUMBER);


/*  CR 785 removed p_credit_agent & p_credit_cust_flag from the parms */
PROCEDURE XX_AR_TRADE_FILE_EXTRACT_CHILD ( x_errbuf            OUT  NOCOPY    VARCHAR2
                                          ,x_retcode           OUT  NOCOPY    VARCHAR2
                                          ,p_from_cust_acct_id IN             NUMBER
                                          ,p_to_cust_acct_id   IN             NUMBER
                                          ,p_request_id        IN             NUMBER
                                          ,p_extract_file_path IN             VARCHAR2
                                          ,p_source_dir_path   IN             VARCHAR2
                                          ,p_aging_bucket_name IN             VARCHAR2
                                          ,p_file_serial_no    IN             NUMBER
                                          );

END XX_AR_TRADE_FILE_PKG;

/
SHOW ERR