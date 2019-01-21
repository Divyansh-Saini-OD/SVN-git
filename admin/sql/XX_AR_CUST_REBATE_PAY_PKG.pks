SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_AR_CUST_REBATE_PAY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  XX_AR_CUST_REBATE_PAY_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name     :  Customer Rebate pay adjustment API                            |
-- | Rice id  :  EXXXX                                                         |
-- | Description : TO identify the valid Short Paid Invoices and creating      |
-- |               an adjustment for the percentage discount customer is       |
-- |               eligible.                                                   |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date              Author              Remarks                    |
-- |======   ==========     =============        ============================= |
-- |1.0      03-MAY-2012    Bapuji Nanapaneni    Initial version for Defect    |
-- |                                             17760                         |
-- +===========================================================================+
-- +==========================================================================+
-- | Name : NOTIFY                                                            |
-- | Description :   TO Identify the valid Short Paid Invoices and create     |
-- |                 adjustment  for the qualified  percentage discount       |
-- |                                                                          |
-- | Parameters :   p_receipt_date_from p_receipt_date_prior                  |
-- |                                                                          |
-- | Returns    :    x_error_buff,x_ret_code                                  |
-- +==========================================================================+

   PROCEDURE NOTIFY( x_error_buff          OUT  VARCHAR2
                   , x_ret_code            OUT  NUMBER
                   , p_receipt_date_from   IN   VARCHAR2
                   , p_receipt_date_to     IN   VARCHAR2
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
END XX_AR_CUST_REBATE_PAY_PKG;
/

SHOW ERRORS PACKAGE XX_AR_CUST_REBATE_PAY_PKG;
--EXIT;