 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_AR_AUTO_CM_TO_INVOICE_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_AUTO_CM_TO_INVOICE_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_AUTO_CM_TO_INVOICE_PKG                                 |
-- | RICE ID : E2057                                                     |
-- | Description : This packages helps to  autoapplication               |
-- |               of credit memo to open invoices based                 |
--.|               on the age calculated using profile value             |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 24-MAR-2010    Cindhu Nagarajan      Initial version        |
-- |                         Wipro Technologies   CR 733 Defect 4019     |
-- |1.1      21-APR-2010    Cindhu Nagarajan      Added Parameter for    |
-- |                         Wipro Technologies   testing purposes       |
-- |                                              CR 733 Defect 4019     |
-- |1.2      26-APR-2010    Cindhu Nagarajan      Added the Procedure    |
-- |                                              check child requests   |
-- |                                              status and removed     |
-- |                                              submit child procedure |
-- |                                              to improve performance |
-- |                                              for CR 733 Defect 4019 |
-- |1.3      28-May-2010    Cindhu Nagarajan      Added parameter        |
-- |                                              for Defect # 6098      |
-- +=====================================================================+
-- +=====================================================================+
-- | Name :  IDENTIFY_CM_MAIN                                            |
-- | RICE ID : E2057                                                     |
-- | Description : This procedure will call the private procedures namely|
-- |               insert header table, get batch size and also cal      |
-- |               submit child proc,generate report proc. This procedure|
-- |               is the main procedure which inturn helps in auto      |
-- |               application of cm to inv based on the age calc using  |
-- |               profile value. It helps to get all possible eligible  |
-- |               credit memo and insert in the header and update with  |
-- |               batch id for each customer site id.                   |
-- |                                                                     |
-- | Parameters :  p_batch_size,p_debug_flag,p_bulk_limit,p_cycle_date,  |
-- |               p_cm_number,p_gather_stats                            |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+
PROCEDURE IDENTIFY_CM_MAIN ( x_err_buff         OUT NOCOPY VARCHAR2
                            ,x_ret_code         OUT NOCOPY NUMBER
                            ,p_batch_size       IN NUMBER
                            ,p_debug_flag       IN VARCHAR2
                            ,p_bulk_limit       IN NUMBER
                            ,p_cycle_date       IN VARCHAR2
                            ,p_cm_number        IN VARCHAR2
                            ,p_cust_acct_id     IN NUMBER      -- Added on 21-APR-2010
                            ,p_gather_stats     IN VARCHAR2    -- Added for Defect# 6098
                           );

---Commented on 26-APR-2010 ** START**
/*-- +=====================================================================+
-- | Name :  SUBMIT_CHILD                                                |
-- | Description : The procedure is used to submit the cm match program. |
-- |               All eligible credit memo match with open invoices by  |
-- |               reference match and exact amount match. Submit child  |
-- |               helps to submit the cm match procedure which inturn   |
-- |               call the reference match and exact amount match       |
-- |               procedures.                                           |
-- |                                                                     |
-- | Parameters :  p_debug_flag,p_cycle_date                             |
-- +=====================================================================+

PROCEDURE SUBMIT_CHILD(p_debug_flag  IN VARCHAR2
                      ,p_cycle_date  IN VARCHAR2
                      ,p_match_type  IN VARCHAR2
                      ,x_error       OUT NUMBER
                      );*/

---Commented on 26-APR-2010 ** END**

-- +=====================================================================+
-- | Name :  CM_MATCH_PROCESS                                            |
-- | Description : The procedure is used to submit the matching process  |
-- |               procedures. Autoapply of CM to invoice can be done    |
-- |               by two matching process. Reference match and exact    |
-- |               amount match. The cm match process procedure helps to |
-- |               call the reference match procedure and exact amount   |
-- |               procedure to find possible invoices to apply cm       |
-- |                                                                     |
-- | Parameters :  p_match_type,p_batch_id,p_debug_flag,p_cycle_date     |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+
PROCEDURE CM_MATCH_PROCESS  (  x_err_buff        OUT NOCOPY  VARCHAR2
                              ,x_ret_code        OUT NOCOPY  NUMBER
--                            ,p_match_type      IN  VARCHAR2  -----Commented on 26-APR-2010
                              ,p_batch_id        IN  NUMBER
                              ,p_debug_flag      IN  VARCHAR2
                              ,p_cycle_date      IN  VARCHAR2
                            );


-- +=====================================================================+
-- | Name :  GENERATE_REPORT                                             |
-- | Description : The procedure is used to print the output in a report |
-- |               The report fields have been updated in the header and |
-- |               detail table. This procedure will fetch those records |
-- |               and give as report output in concurrent program       |
-- |                                                                     |
-- | Parameters :   p_debug_flag,p_gather_stats                          |
-- | Returns    :                                                        |
-- +=====================================================================+
PROCEDURE GENERATE_REPORT(p_debug_flag    IN VARCHAR2
                         ,p_gather_stats  IN VARCHAR2
                         );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  debug_message                                 |
-- | Description      : This Procedure is used to print the debug      |
-- |                    messages wherever required                     |
-- | Parameters :       p_debug_flag,p_debug_msg                       |
-- +===================================================================+

PROCEDURE DEBUG_MESSAGE(p_debug_flag       IN       VARCHAR2
                       ,p_debug_msg        IN       VARCHAR2
                       );

-- +====================================================================+
-- | Name : GET_INV_DISPUTE_STATUS                                      |
---| Rice Id : E2057                                                    |
-- | Description : It accepts the inv trx id and it will check          |
-- |               whether the passed invoice is in complete or approved|
-- |               status and it implies the invoice is ready for       |
-- |               auto application process                             |
-- | Parameters :  p_set_of_books_id, p_currency_code, p_period_name    |
-- +====================================================================+
FUNCTION GET_INV_DISPUTE_STATUS(p_inv_trx_id    IN NUMBER)
RETURN VARCHAR2;


END XX_AR_AUTO_CM_TO_INVOICE_PKG;
/
SHOW ERRORS;
