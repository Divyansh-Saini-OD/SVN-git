SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_CRM_HVOP_ERR_REP

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE apps.XX_CRM_HVOP_ERR_REP
 AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_CRM_HVOP_ERR_REP                                                 |
-- | Description : This Package is used to check the status of the Customer information|
-- |               of the Errored HVOP data.                                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MASTER                                                              |
-- | Description : This procedure is used to trigger the output pgm and the mailer pgm.|
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE MASTER ( x_error_buff                 OUT VARCHAR2
                      ,x_ret_code                   OUT NUMBER
                      ,p_start_date                 IN  VARCHAR2
                      ,p_end_date                   IN  VARCHAR2
                      );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : CUST_INFO_STATUS                                                    |
-- | Description : This procedure is used to check the status of the customer info.    |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE CUST_INFO_STATUS ( x_error_buff                 OUT VARCHAR2
                                ,x_ret_code                   OUT NUMBER
                                ,p_start_date                 IN  VARCHAR2
                                ,p_end_date                   IN  VARCHAR2
                                );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : REC_STATUS                                                          |
-- | Description : This procedure is used to check the status of the customer.         |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE REC_STATUS ( p_message_code            IN   VARCHAR2
                          ,p_message_text            IN   VARCHAR2
                          ,p_cust_orig_sys_ref       IN   VARCHAR2
                          ,p_bill_to_orig_sys_ref    IN   VARCHAR2
                          ,p_ship_to_orig_sys_ref    IN   VARCHAR2
                          ,p_doc_orig_sys_ref        IN   VARCHAR2
                          ,x_err_level               OUT  VARCHAR2
                          ,x_status                  OUT  VARCHAR2
                          ,x_use_code                OUT  VARCHAR2
                          ,x_spc_flag                OUT  VARCHAR2
                          );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : REC_ERR_DETAILS                                                     |
-- | Description : This procedure is used to display the details of the HVOP error     |
-- |               record.                                                             |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 28-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE REC_ERR_DETAILS ( p_err_level            IN VARCHAR2
                               ,p_status               IN VARCHAR2
                               ,p_use_code             IN VARCHAR2
                               ,p_cust_orig_sys_ref    IN VARCHAR2
                               ,p_spc_flag             IN VARCHAR2
                               );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : PRINT_OUTPUT                                                        |
-- | Description : This procedure is used to print the output.                         |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 28-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE PRINT_OUTPUT ( p_message   IN VARCHAR2);

 END XX_CRM_HVOP_ERR_REP;

/
SHO ERROR