 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF 
 SET FEEDBACK OFF
 SET TERM ON  

 PROMPT Creating Package Spec XX_AR_GL_TRANSFER_PKG_NEW
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE XX_AR_GL_TRANSFER_PKG_NEW
 AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :    XX_AR_GL_TRANSFER_PKG                                   |
 -- | RICE :    E2015                                                   |
 -- | Description : This package is used to submit the General Ledger   |
 -- |               transfer program for AR                             |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       14-OCT-08    Aravind A            Initial version        |
 -- +===================================================================+

 -- +===================================================================+
 -- | Name        : SUBMIT_PROGRAM                                      |
 -- | Description : The procedure is used to accomplish the following   |
 -- |               tasks:                                              |
 -- |               1. Submit the General Ledger Transfer Program       |
 -- |               2. Submit the OD Receivables Multithread            |
 -- |                  General Ledger Journal Import program            |
 -- |               3. Log the details about the GL Transfer program    |
 -- |                  to the custom table XX_FIN_PROGRAM_STATS         |
 -- |                                                                   |
 -- | Parameters  : p_start_date                                        |
 -- |               ,p_post_through_date                                |
 -- |               ,p_gl_posted_date                                   |
 -- |               ,p_post_in_summary                                  |
 -- |               ,p_run_journal_imp                                  |
 -- |               ,p_transaction_type                                 |
 -- |               ,p_wave_num                                         |
 -- |               ,p_run_date                                         |
 -- |               ,p_child_to_xptr                                    |
 -- |               ,p_batch_size                                       |
 -- |               ,p_max_wait_int                                     |
 -- |               ,p_max_wait_time                                    |
 -- |               ,p_email_id                                         |
 -- |                                                                   |
 -- | Returns     : x_error_buff                                        |
 -- |               ,x_ret_code                                         |
 -- +===================================================================+

    PROCEDURE SUBMIT_PROGRAM(
                             x_error_buff            OUT      VARCHAR2
                             ,x_ret_code             OUT      NUMBER
                             ,p_start_date           IN       VARCHAR2
                             ,p_post_through_date    IN       VARCHAR2
                             ,p_gl_posted_date       IN       VARCHAR2
                             ,p_post_in_summary      IN       VARCHAR2
                             ,p_run_journal_imp      IN       VARCHAR2
                             ,p_transaction_type     IN       VARCHAR2
                             ,p_wave_num             IN       NUMBER
                             ,p_run_date             IN       VARCHAR2
                             ,p_child_to_xptr        IN       VARCHAR2
                             ,p_batch_size           IN       NUMBER
                             ,p_max_wait_int         IN       PLS_INTEGER   
                             ,p_max_wait_time        IN       PLS_INTEGER   
                             ,p_email_id             IN       VARCHAR2
                            );

 END XX_AR_GL_TRANSFER_PKG_NEW;
 
/
SHOW ERROR