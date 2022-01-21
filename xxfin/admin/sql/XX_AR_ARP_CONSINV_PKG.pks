SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AR_ARP_CONSINV

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_ARP_CONSINV IS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_ARP_CONSINV.pkb                                           |
---|                                                                                            |
---|    Description     : Avoid non-AOPS transactions in Cons Billing                           |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR               DESCRIPTION                      |
---|    ------------    ----------------- ---------------      ---------------------            |
---|    1.0                            Initial Version                  |
---+============================================================================================+

   PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
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
                   );

END XX_AR_ARP_CONSINV;
/
SHOW ERR