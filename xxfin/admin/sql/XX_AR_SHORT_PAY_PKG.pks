SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_AR_SHORT_PAY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  XX_AR_SHORT_PAY_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   Short Pay Workflow                                     |
-- | Rice id  :   E1326                                                  |
-- | Description : TO Identify the valid Short Paid Invoices and creating|
-- |               a Task for the Research Team Member linked to a       |
-- |               Collector who is linked to the Customer               |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       28-JUN-2007   Chaitanya Nath.G      Initial version        |
-- |                       Wipro Technologies                            |
-- |1.1       04-AUG-2008  Ram                    Fix for Defect 9525    |
-- |1.2       20-APR-2012  Bapuji Nanapaneni      Fix for Defect 17760   |
-- +=====================================================================+

-- +==========================================================================+
-- | Name : NOTIFY                                                            |
-- | Description :   TO Identify the valid Short Paid Invoices and creating   |
-- |                 a Task for the Research Team Member linked to a          |
-- |                 Collector who is linked to the Customer                  |
-- |                                                                          |
-- | Parameters :   p_receipt_date_from ,p_task_type,p_task_status,           |
-- |                p_owner_code,p_receipt_date_prior                         |
-- |   Returns :    x_error_buff,x_ret_code                                   |
-- +==========================================================================+

   PROCEDURE NOTIFY(
       x_error_buff          OUT  VARCHAR2
      ,x_ret_code            OUT  NUMBER
      ,p_receipt_date_from   IN   DATE
      ,p_task_type           IN   VARCHAR2
      ,p_task_status         IN   VARCHAR2
      ,p_owner_code          IN   VARCHAR2
      ,p_receipt_date_prior  IN   DATE            --Added  for Defect 9525
                    );
                    
-- +==========================================================================+
-- | Name : VALIDATE__DIS_CUST                                                |
-- | Description : Identify if customer aganist an invoice is a flat discount |
-- |               customer from transalate values and return activity name   |
-- |               and percentage of discount the customer is eligable        |
-- |                                                                          |
-- | Parameters :   p_customer_number                                         |
-- |                                                                          |
-- |   Returns :    x_activity_name, x_dis_percentage                         |
-- +==========================================================================+
                    
/* Added for Defect 17760 */
PROCEDURE validate_dis_cust( p_customer_number  IN  VARCHAR2
                           , x_activity_name    OUT VARCHAR2
                           , x_dis_percentage   OUT NUMBER
                           );
END XX_AR_SHORT_PAY_PKG;
/

SHO ERR 