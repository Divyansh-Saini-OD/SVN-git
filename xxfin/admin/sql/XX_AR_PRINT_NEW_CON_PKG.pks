SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AR_PRINT_NEW_CON_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_PRINT_NEW_CON_PKG IS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_PRINT_NEW_CON_PKG.pks                                           |
---|                                                                                            |
---|    Description     : Avoid non-AOPS transactions in Cons Billing                           |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             10-Feb-2008       Rani A             Initial Version - CR 318           |
---|                                                         Defect# 8934                       |
-- |    1.1             03-MAR-2010       Sambasiva Reddy D  Modified for Defect #4422          |
-- |                                                         Customized for multi threading     |
-- |                                                         (added customer range)             |
---|                                                                                            |
---+============================================================================================+

   PROCEDURE MAIN (x_errbuf                   OUT NOCOPY      VARCHAR2
                  ,x_retcode                  OUT NOCOPY      NUMBER
                  ,p_print_option             IN              VARCHAR2
                  ,p_customer_name            IN              VARCHAR2
                  ,p_customer_number          IN              VARCHAR2
                  ,p_bill_to_site             IN              VARCHAR2
                  ,p_cut_off_date             IN              VARCHAR2
                  ,p_last_day_of_month        IN              VARCHAR2
                  ,p_payment_term             IN              VARCHAR2
                  ,p_currency                 IN              VARCHAR2
                  ,p_type                     IN              VARCHAR2
                  ,p_preprinted_stationery    IN              VARCHAR2
                  ,p_org_id                   IN              VARCHAR2
                  ,p_cust_name_low            IN              VARCHAR2
                  ,p_cust_name_high           IN              VARCHAR2
                  ,p_cust_num_low             IN              VARCHAR2
                  ,p_cust_num_high            IN              VARCHAR2
                  ,p_no_workers               IN              NUMBER     DEFAULT 10
                  ,p_run_std_prg              IN              NUMBER
                  ,p_cust_trx_id              IN              NUMBER
                  );

   END XX_AR_PRINT_NEW_CON_PKG;
/
SHO ERR