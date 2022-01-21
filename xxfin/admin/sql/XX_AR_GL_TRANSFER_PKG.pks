SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package Spec XX_AR_GL_TRANSFER_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_GL_TRANSFER_PKG
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
-- |Version  Date          Author          Remarks                     |
-- |=======  ===========   =============   ============================|
-- | 1.0     14-OCT-2008   Aravind A       Initial version             |
-- | 1.1     16-SEP-2009   Harini G        Added p_debug_mode parameter|
-- |                                       as per the defect #2504     |
-- | 1.2     28-DEC-2009   RamyaPriya M    Modified for the Defect 2851|
-- | 1.7     15-JAN-2010   Sneha Anand     Performance Changes for     |
-- |                                       Defect #2851                |
-- | 2.0     09-MAR-2010   R.Aldridge      Defect 4925 - 10.3 Release. |
-- |                                       The HV Staging program will |
-- |                                       be submitted by only source |
-- |                                       and SOB now.  Also added a  |
-- |                                       new parameter for           |
-- |                                       determining if staging      |
-- |                                       should be submitted or not. |
-- |                                                                   |
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
   -- |              ,p_post_through_date                                 |
   -- |              ,p_gl_posted_date                                    |
   -- |              ,p_post_in_summary                                   |
   -- |              ,p_run_journal_imp                                   |
   -- |              ,p_transaction_type                                  |
   -- |              ,p_wave_num                                          |
   -- |              ,p_run_date                                          |
   -- |              ,p_child_to_xptr                                     |
   -- |              ,p_batch_size                                        |
   -- |              ,p_max_wait_int                                      |
   -- |              ,p_max_wait_time                                     |
   -- |              ,p_email_id                                          |
   -- |              ,p_debug_mode                                        |
   -- |              ,p_submit_hv_staging                                 |
   -- |                                                                   |
   -- | Returns     : x_error_buff                                        |
   -- |              ,x_ret_code                                          |
   -- +===================================================================+
   PROCEDURE SUBMIT_PROGRAM(x_error_buff           OUT       VARCHAR2
                           ,x_ret_code             OUT       NUMBER
                           ,p_start_date            IN       VARCHAR2
                           ,p_post_through_date     IN       VARCHAR2
                           ,p_gl_posted_date        IN       VARCHAR2
                           ,p_set_of_books_id       IN       NUMBER
                           ,p_org_id                IN       NUMBER
                           ,p_transaction_types     IN       VARCHAR2
                           ,p_wave_num              IN       NUMBER
                           ,p_run_date              IN       VARCHAR2
                           ,p_child_to_xptr         IN       VARCHAR2
                           ,p_email_id              IN       VARCHAR2
                           ,p_worker_number         IN       NUMBER
                           ,p_max_workers           IN       NUMBER
                           ,p_skip_unposted_items   IN       VARCHAR2
                           ,p_skip_revenue_programs IN       VARCHAR2
                           ,p_batch_size            IN       NUMBER
                           ,p_debug_mode            IN       VARCHAR2
                           ,p_submit_hv_staging     IN       VARCHAR2  -- added parameter for 4925
                           );
 END XX_AR_GL_TRANSFER_PKG;
 
/
SHOW ERROR

