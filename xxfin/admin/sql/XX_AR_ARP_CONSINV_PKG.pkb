SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_ARP_CONSINV

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_ARP_CONSINV
AS
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
                   )
                   IS
ln_consinv_id NUMBER;
ln_program_id NUMBER;
lc_cut_off_date       VARCHAR2(20);

   BEGIN

      ln_program_id := fnd_global.conc_request_id ;
lc_cut_off_date := to_char(to_date(p_cut_off_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YY');
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PRINT_OPTION: '||p_print_option);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_TYPE: '||p_type);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CURRENCY: '||p_currency);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUST_NAME: '||to_char(p_customer_name));
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUST_NUM: '||p_customer_number);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_BILL_TO_SITE: '||to_char(p_bill_to_site));
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUT_OFF_DATE: '||lc_cut_off_date);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_LAST_DAY_OF_MONTH: '||p_last_day_of_month);
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_TERMS_ID: '||to_char(p_payment_term));
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CONSINV_ID: '||to_char(ln_consinv_id));
FND_FILE.PUT_LINE(FND_FILE.LOG,'P_REQUEST_ID: '||to_char(ln_program_id));

     /**  Call program to generate consolidated billing information with user parameters  **/
FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling API - PENDING');

     arp_consinv.report(p_print_option,
                        p_type,
                        p_currency,
                        p_customer_name,
                        p_customer_number,
                        p_bill_to_site, 
                       -- to_char(to_date(p_cut_off_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YY'),
                        lc_cut_off_date,
                        p_last_day_of_month,
                        p_payment_term,
                        ln_consinv_id,
                        ln_program_id,
                        'PENDING');

FND_FILE.PUT_LINE(FND_FILE.LOG,'Out of API - PENDING');
FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling API - PRINTED');

     arp_consinv.report(p_print_option,
                        p_type,
                        p_currency,
                        p_customer_name,
                        p_customer_number,
                        p_bill_to_site, 
                       -- to_char(to_date(p_cut_off_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YY'),
                        lc_cut_off_date,
                        p_last_day_of_month,
                        p_payment_term,
                        ln_consinv_id,
                        ln_program_id,
                        'PRINTED');

FND_FILE.PUT_LINE(FND_FILE.LOG,'Out of API-PRINTED');

   EXCEPTION
   WHEN OTHERS THEN

      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error While : ' );

   END MAIN;

END XX_AR_ARP_CONSINV;
/
SHOW ERR