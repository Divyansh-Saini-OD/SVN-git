SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_INV_FREQ_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE BODY XX_AR_INV_FREQ_PKG AS

-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- | Name :      AR Invoice Frequency ronization                                        |
-- | Description : To pupulate the invoices according to the customer                   |
-- |                documents                                                           |
-- |                                                                                    |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       09-AUG-2007  Gowri Shankar        Initial version                         |
-- |                                                                                    |
-- |1.1       13-DEC-2007  Afan Sheriff         Defect 2952                             |
-- |                                                                                    |
-- |1.2       18-MAR-2008  Gowri Shankar        Adding New Payment terms for            |
-- |                                                the Frequency MNTHDAY               |
-- |                                                                                    |
-- |1.3       14-APR-2008  Afan Sheriff         Performance related changes. Remove     |
-- |                                            the query to get program name.          |
-- |                                                                                    |
-- |1.4       13-MAY-2008  Agnes Poornima M     Performance related changes.            |
-- |                                            Created Wrapper programs.               |
-- |                                                                                    |
-- |1.5       27-MAY-2008  Gowri Shankar        Chanegs for traceability and sync       |
-- |                                                                                    |
-- |1.6       13-JUN-2008  Sambasiva Reddy D    Changes for performance                 |
-- |                                                                                    |
-- |1.7       18-JUN-2008  Gowri Shankar        Defect# 8253 To Add the printer         |
-- |                                            parameter                               |
-- |                                                                                    |
-- |1.8       21-JUN-2008  Gowri Shankar        Changes for the Summary info in         |
-- |                                            log file and handling exception         |
-- |                                            from COMPUTE_EFFECTIVE_DATE             |
-- |                                                                                    |
-- |1.9       21-JUN-2008  Gowri Shankar        Defect# 8350                            |
-- |                                            Changes for New Payment term            |
-- |                                                                                    |
-- |2.0       27-JUN-2008  Gowri Shankar        Defect# 8479                            |
-- |                                            Excluding NON SPC and NON pro card      |
-- |                                                        POS Orders                  |
-- |                                                                                    |
-- |2.1       02-JUL-2008  Sambasiva Reddy D    Defect# 8612                            |
-- |                                            Excluding Fully paid transactions       |
-- |                                                                                    |
-- |2.2       14-JUL-2008  Gowri Shankar        Defect# 8726                            |
-- |                                            Zipping Program                         |
-- |                                                                                    |
-- |2.3       23-JUL-2008  Gowri Shankar        Defect# 9131, 9076                      |
-- |                                            Copying the O/P file of the             |
-- |                                            Multiple threads of Certegy reports     |
-- |                                            To Add "As of Date" Parameter           |
-- |                                                                                    |
-- |2.4       26-JUL-2008  Gowri Shankar        Fix for the Defect# 9278                |
-- |                                                                                    |
-- |2.5       20-AUG-2008  Gowri Shankar        Fix for the Defect# 10103               |
-- |                                                                                    |
-- |                                                                                    |
-- |2.6       02-sep-2008  Mohanakrishnan       Fix for defect 10341                    |
-- |2.7       04-SEP-2008  Gowri Shankar        Defect# 9632, Perf improvement          |
-- |                                                                                    |
---|2.8       01-Dec-08    Mohanakrishnan       Defect 12227, perf improvement          |
-- |                                                                                    |
-- |2.9       01-Dec-2008  Sambasiva Reddy      Defect# 12223, Adding a additional      |
-- |                                            Printer                                 |
-- |2.10      30-Dec-2008  Shobana S            Defect 12710(CR 460)                    |
-- |2.11      07-Feb-2009  Ranjith Prabhu       Commented for the Defect 13101          |
-- |2.12      02-Mar-2009  Shobans S            Defect 13337                            |
-- |2.13      01-JUL-2009  Ranjith Prabu        Changes to handle week sunday for       |
-- |                                            the Defect # 352                        |
-- |2.14      14-JUL-2009  RamyaPriya M         Changed for the defect # 631 (CR 662)   |
-- |2.15      05-AUG-2009  Sambasiva Reddy D    Changed for the Defect # 1820           |
-- |2.16      12-AUG-2009  Kantharaja VelayuthamChanged for the Defect # 1375           |
-- |2.17      26-AUG-2009  Sambasiva Reddy D    Changed for the Defect # 2308           |
-- |2.18      31-Aug-2009  Tamil Vendhan L      Changed for the R1.1 Defect # 1451      |
-- |                                            (CR 626)                                |
-- |2.17      23-sep-2009  Mohanakrishna        Changed for the Defect # 2742           |
-- |2.17      22-Oct-2009  Mohanakrishna        Changed for the Defect # 3136           |
-- |2.17      15-JAN-2010  Sambasiva Reddy D    Changed for the Defect # 4046           |
-- |2.18      06-JAN-2009  Tamil Vendhan L      Modified for R1.2 CR 466 Defect 1201    |
-- |2.19      20-JAN-2010  Tamil Vendhan L      Modified for R1.2 Defect 4095           |
-- |2.20      11-MAR-2010  Tamil Vendhan L      Modified for R1.3 CR 738 Defect 2766    |
-- |                                            and Defect 2858                         |
-- |2.21      07-APR-2010  Sneha Anand          Modified for R1.3 Defect 3853,4761      |
-- |                                             and 4762                               |
-- |2.22      12-MAY-2010  Ranjith Thangasamy   Modified for defect 5901                |
-- |2.23      29-APR-2010  Gokila Tamilselvam   Modified the code for R1.4 CR# 586      |
-- |                                            eBilling.                               |
-- |                                            1. Modified the combo logic.            |
-- |                                            2. Added status to CDH cust acct table. |
-- |                                            3. Added eBilling logic to infocopy     |
-- |                                               handling function.                   |
-- |2.24      14-JUN-2010  Ranjith Thangasamy   Change for Defect  6375                 |
-- |2.25      25-JUN-2010  Sneha Anand          Modified for Defect 6342 the procedure  |
-- |                                            XX_MULTI_THREAD_SPL  to handle the      |
-- |                                            completion staus of the Parallel program|
-- |2.25      20-JUL-2010  Sambasiva Reddy D    Modified for defect 6818 (Changed multi-|
-- |                                            threading approach)                     |
-- |2.26      22-JUL-2010  Sambasiva Reddy S    Modifed for defect 6818                 |
-- |                                            gathering stats                         |
-- |2.27      14-OCT-2013  Arun Gannarapu       Added COMPUTE_EFFECTIVE_DATE function   |
-- |                                            to return the billable date using the   |
-- |                                            billing cycle setups as part of R12     |
-- |                                            upgrade                                 |
-- |                                                                                    |
-- |2.28      21-FEB-2014  R.Aldridge           Performance Defect 28444 - Added hint   |
-- |                                            to cursor c_inv_cust_doc                |
-- |2.29      16-MAY-2014  Arun Gannarapu       Made changes to add TRUNC to compute    |
-- |                                           effective date --defect 29928            |
-- |2.30      05-OCT-2015  Shaik Ghouse        Made changes for Performance Improvement |
-- |                                           especially for month end billing run     |
-- |                                           for Defect # 35572                       |
-- |2.31      20-OCT-2015  Shaik Ghouse        Removed Schema name for Custom Objects   | 
-- |                                           for R12.2	                            |
-- |2.32      10-FEB-2016  Havish Kasina       Changes done as per Defect 36553         |
-- |                                           (Gift Card Changes). Replaced the Profile|
-- |                                           option with new Translation to get the   |
-- |                                           payment type code                        |
-- |2.33       02-APR-2018  Punit Gupta CG      Retrofit Billing Programs with           |
-- |                                           custom OM Views- Defect NAIT-31697       |
-- |2.34       28-JAN-2019  Dinesh Nagapuri    Bill Complete-No Billing files were      |
-- |										   generated yet there were Info docs NAIT-80765|
-- +====================================================================================+

        gn_gc_amt                     NUMBER;
        --Added this global variable for R1.1 Defect # 1451 (CR 626)
--        gc_comp_effec_date            FND_PROFILE_OPTION_VALUES.profile_option_value%type := FND_PROFILE.VALUE('XX_AR_COMPUTE_EFFECTIVE_DATE');   -- Added for R1.2 Defect 4095   -- Commented for R1.3 CR 738 Defect 2766


-- +===================================================================+
-- | Name : COMPUTE_EFFECTIVE_DATE                                     |
-- | Description : Billing Date (Balance Forward Billing)              |
-- | The logic is to derive billing date is to find the first billable |
-- | date on or after the transaction date                             |
-- | and to use that as the billing date on the invoice.               |
-- | Returns  : ld_billable_date                                       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        ==============         |
--            14-OCT-2013  Arun Gannarapu       Added as part of R12 upgrade |  
-- +===================================================================+


  FUNCTION COMPUTE_EFFECTIVE_DATE( p_payment_term   IN VARCHAR2 --Added for the Defect# 9632
                                  ,p_invoice_creation_date     IN    DATE
                                  )
  RETURN DATE IS
  
  ld_billable_date ar_cons_bill_cycle_dates.billable_date%TYPE;
  BEGIN 
  
   SELECT MIN(bcd.billable_date)
   INTO ld_billable_date 
   FROM ar_cons_bill_cycle_dates bcd,
        ar_cons_bill_cycles_b bc,
        ra_terms t
   WHERE t.name = p_payment_term --'EM-BI16EOMN30'
   AND t.billing_cycle_id = bc.billing_cycle_id
   AND bc.bill_cycle_type = 'RECURRING'
   AND bcd.billing_cycle_id = t.billing_cycle_id
   AND bcd.billable_date >= TRUNC(p_invoice_creation_date);
   
   RETURN(ld_billable_date);
 
  EXCEPTION
    WHEN OTHERS
    THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'payment term '||p_payment_term || 'P_invoice_creation_date '|| p_invoice_creation_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while getting Compute Effective date: '||SQLERRM);
      RETURN (NULL);
  END COMPUTE_EFFECTIVE_DATE;

-- +===================================================================+
-- | Name : COMPUTE_EFFECTIVE_DATE                                     |
-- | Description : To compute the effective print date for the Invoice |
-- |                 ,based on the Invoice creation date, frequency    |
-- |                 ,payment term                                     |
-- |                                                                   |
-- | Parameters : p_extension_id, p_invoice_creation_date              |
-- |                                                                   |
-- |   Returns  : ld_date_eff                                          |
-- +===================================================================+

    FUNCTION COMPUTE_EFFECTIVE_DATE_old(
                                    --p_extension_id              IN    NUMBER    --Commented for the Defect# 9632
                                    p_payment_term   IN VARCHAR2 --Added for the Defect# 9632
                                   ,p_invoice_creation_date     IN    DATE
                                   )  RETURN DATE IS

        lc_cur_frequency              VARCHAR2(1000);
        lc_cur_payment_term           VARCHAR2(1000);
        lc_cur_daynumber              VARCHAR2(10);
        lc_cur_day                    VARCHAR2(50);
        lc_cur_month                  VARCHAR2(50);
        lc_cur_quarter                VARCHAR2(10);
        lc_cur_year                   VARCHAR2(10);

        lc_frequency                  VARCHAR2(1000);
        lc_payment_term               VARCHAR2(1000);
        lc_daynumber                  VARCHAR2(10);
        lc_day                        VARCHAR2(50);
        lc_month                      VARCHAR2(50);
        lc_quarter                    VARCHAR2(10);
        lc_year                       VARCHAR2(10);

        lc_daynumber_eff              VARCHAR2(50);
        lc_month_eff                  VARCHAR2(50);
        lc_year_eff                   VARCHAR2(50);
        ld_date_eff                   DATE;

        --For the Month frquency of FIRST_MONTH, SECOND_MONTH, THIRD_MONTH, FOURTH, LAST_MONTH
        lc_first_day_of_month         VARCHAR2(50);
        ln_first_monday_daynumber     NUMBER;
        ln_monday_daynumber           NUMBER;

        lc_last_day_of_month          VARCHAR2(50);
        ld_last_date_month            DATE;
        ld_last_monday_date           DATE;

        ln_first_sunday_daynumber     NUMBER;
        ld_last_sunday_date           DATE;
        ln_sunday_daynumber           NUMBER;

        ln_first_tuesday_daynumber    NUMBER;
        ld_last_tuesday_date          DATE;
        ln_tuesday_daynumber          NUMBER;

        ln_first_wednesday_daynumber  NUMBER;
        ld_last_wednesday_date        DATE;
        ln_wednesday_daynumber        NUMBER;

        ln_first_thursday_daynumber   NUMBER;
        ld_last_thursday_date         DATE;
        ln_thursday_daynumber         NUMBER;

        ln_first_friday_daynumber     NUMBER;
        ld_last_friday_date           DATE;
        ln_friday_daynumber           NUMBER;

        ln_first_saturday_daynumber   NUMBER;
        ld_last_saturday_date         DATE;
        ln_saturday_daynumber         NUMBER;

        --For the WEEK frequency of SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
        lc_day_of_week                VARCHAR2(50);
        ld_week_date_eff              DATE;

        --For the SEMI frequency
        ld_start_period_date          DATE;
        ld_end_period_date            DATE;
        ln_semi_start_date            NUMBER := NULL;  --Added for the Defect# 8350
        ln_semi_end_date              NUMBER := NULL;  --Added for the Defect# 8350

        --Exceptions
        lc_frequency_valid            VARCHAR2(1) := 'N';
        lc_payment_term_valid         VARCHAR2(1) := 'N';
        lc_error_loc                  VARCHAR2(4000);
        lc_error_debug                VARCHAR2(4000);
        gc_concurrent_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

    BEGIN

        BEGIN

            lc_error_loc := 'Getting the Concurrent Program name';
            lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;

          /*  SELECT FCPT.user_concurrent_program_name   --Commented to improve Performance.
            INTO   gc_concurrent_program_name
            FROM   fnd_concurrent_programs_tl FCPT
            WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
            AND    FCPT.language = 'US';

        EXCEPTION WHEN NO_DATA_FOUND THEN
            gc_concurrent_program_name := NULL;*/  --Commented to improve Performance.

            gc_concurrent_program_name := 'XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE - Billing';
        END;

        --To get the Day details of Current Date
        SELECT
             TO_CHAR(SYSDATE,'DD')
            ,TO_CHAR(SYSDATE,'DAY')
            ,TO_CHAR(SYSDATE,'MM')
            ,TO_CHAR(SYSDATE,'Q')
            ,TO_CHAR(SYSDATE,'YYYY')
        INTO
             lc_cur_daynumber
            ,lc_cur_day
            ,lc_cur_month
            ,lc_cur_quarter
            ,lc_cur_year
        FROM DUAL;

        --To get the Day details of Current Date
        SELECT
             TO_CHAR(p_invoice_creation_date,'DD')
            ,TO_CHAR(p_invoice_creation_date,'DAY')
            ,TO_CHAR(p_invoice_creation_date,'MM')
            ,TO_CHAR(p_invoice_creation_date,'Q')
            ,TO_CHAR(p_invoice_creation_date,'YYYY')
        INTO
             lc_daynumber
            ,lc_day
            ,lc_month
            ,lc_quarter
            ,lc_year
        FROM DUAL;

        --Comment for the Defect# 9632
        /*lc_error_loc := 'Getting the Frequency, Payment Term';
        lc_error_debug := 'Extension id: '||p_extension_id;

        SELECT RT.attribute1, RT.attribute2
        INTO   lc_frequency, lc_payment_term
        FROM   xx_cdh_a_ext_billdocs_v XCAEB
               ,ra_terms               RT                   --Defect 2952.
        WHERE  XCAEB.extension_id = p_extension_id
               and RT.name = XCAEB.billdocs_payment_term;   --Defect 2952.*/

        --Added for the Defect# 9632
        lc_error_loc := 'Getting the Frequency, Payment Term';
        lc_error_debug := 'Billing Payment Term: '||p_payment_term;
        BEGIN
           SELECT RT.attribute1, RT.attribute2
           INTO   lc_frequency, lc_payment_term
           FROM   ra_terms RT
           WHERE  RT.name = p_payment_term;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_loc);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Term is not defined in RA_TERMS table.');
        END;

        --Start of addition for the new Frequencies

        IF (lc_frequency = 'MNTHDAY') THEN

            lc_frequency_valid := 'Y';

            --Sunday Frequencies
            IF ((lc_payment_term = 'SUNDAY1') OR (lc_payment_term = 'SUNDAY2') OR (lc_payment_term = 'SUNDAY3') OR (lc_payment_term = 'SUNDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',1
                              ,'MON',7
                              ,'TUE',6
                              ,'WED',5
                              ,'THU',4
                              ,'FRI',3
                              ,'SAT',2)
                INTO   ln_first_sunday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'SUNDAY1',ln_first_sunday_daynumber
                              ,'SUNDAY2',ln_first_sunday_daynumber+7
                              ,'SUNDAY3',ln_first_sunday_daynumber+14
                              ,'SUNDAY4',ln_first_sunday_daynumber+21)
                INTO   ln_sunday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_sunday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Sunday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',1
                              ,'MON',7
                              ,'TUE',6
                              ,'WED',5
                              ,'THU',4
                              ,'FRI',3
                              ,'SAT',2)
                    INTO   ln_first_sunday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'SUNDAY1',ln_first_sunday_daynumber
                              ,'SUNDAY2',ln_first_sunday_daynumber+7
                              ,'SUNDAY3',ln_first_sunday_daynumber+14
                              ,'SUNDAY4',ln_first_sunday_daynumber+21)
                    INTO   ln_sunday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_sunday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'SUNDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month
                            ,'MON',ld_last_date_month-1
                            ,'TUE',ld_last_date_month-2
                            ,'WED',ld_last_date_month-3
                            ,'THU',ld_last_date_month-4
                            ,'FRI',ld_last_date_month-5
                            ,'SAT',ld_last_date_month-6)
                INTO   ld_last_sunday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Sunday then , get the LAST Sunday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_sunday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month
                            ,'MON',ld_last_date_month-1
                            ,'TUE',ld_last_date_month-2
                            ,'WED',ld_last_date_month-3
                            ,'THU',ld_last_date_month-4
                            ,'FRI',ld_last_date_month-5
                            ,'SAT',ld_last_date_month-6)
                    INTO   ld_last_sunday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_sunday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_sunday_date,'MM');
                lc_year_eff := to_char(ld_last_sunday_date,'YYYY');

            END IF;

            --Monday Frequencies

            IF ((lc_payment_term = 'MONDAY1') OR (lc_payment_term = 'MONDAY2') OR (lc_payment_term = 'MONDAY3') OR (lc_payment_term = 'MONDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',2
                              ,'MON',1
                              ,'TUE',7
                              ,'WED',6
                              ,'THU',5
                              ,'FRI',4
                              ,'SAT',3)
                INTO   ln_first_monday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'MONDAY1',ln_first_monday_daynumber
                              ,'MONDAY2',ln_first_monday_daynumber+7
                              ,'MONDAY3',ln_first_monday_daynumber+14
                              ,'MONDAY4',ln_first_monday_daynumber+21)
                INTO   ln_monday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_monday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Month goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',2
                              ,'MON',1
                              ,'TUE',7
                              ,'WED',6
                              ,'THU',5
                              ,'FRI',4
                              ,'SAT',3)
                    INTO   ln_first_monday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'MONDAY1',ln_first_monday_daynumber
                              ,'MONDAY2',ln_first_monday_daynumber+7
                              ,'MONDAY3',ln_first_monday_daynumber+14
                              ,'MONDAY4',ln_first_monday_daynumber+21)
                    INTO   ln_monday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_monday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'MONDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-6
                            ,'MON',ld_last_date_month
                            ,'TUE',ld_last_date_month-1
                            ,'WED',ld_last_date_month-2
                            ,'THU',ld_last_date_month-3
                            ,'FRI',ld_last_date_month-4
                            ,'SAT',ld_last_date_month-5)
                INTO   ld_last_monday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Monday then , get the LAST Monday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_monday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-6
                            ,'MON',ld_last_date_month
                            ,'TUE',ld_last_date_month-1
                            ,'WED',ld_last_date_month-2
                            ,'THU',ld_last_date_month-3
                            ,'FRI',ld_last_date_month-4
                            ,'SAT',ld_last_date_month-5)
                    INTO   ld_last_monday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_monday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_monday_date,'MM');
                lc_year_eff := to_char(ld_last_monday_date,'YYYY');

            END IF;

            --Tuesday Frequencies
            IF ((lc_payment_term = 'TUESDAY1') OR (lc_payment_term = 'TUESDAY2') OR (lc_payment_term = 'TUESDAY3') OR (lc_payment_term = 'TUESDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',3
                              ,'MON',2
                              ,'TUE',1
                              ,'WED',7
                              ,'THU',6
                              ,'FRI',5
                              ,'SAT',4)
                INTO   ln_first_tuesday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'TUESDAY1',ln_first_tuesday_daynumber
                              ,'TUESDAY2',ln_first_tuesday_daynumber+7
                              ,'TUESDAY3',ln_first_tuesday_daynumber+14
                              ,'TUESDAY4',ln_first_tuesday_daynumber+21)
                INTO   ln_tuesday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_tuesday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Tuesday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',3
                              ,'MON',2
                              ,'TUE',1
                              ,'WED',7
                              ,'THU',6
                              ,'FRI',5
                              ,'SAT',4)
                    INTO   ln_first_tuesday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'TUESDAY1',ln_first_tuesday_daynumber
                              ,'TUESDAY2',ln_first_tuesday_daynumber+7
                              ,'TUESDAY3',ln_first_tuesday_daynumber+14
                              ,'TUESDAY4',ln_first_tuesday_daynumber+21)
                    INTO   ln_tuesday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_tuesday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'TUESDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-5
                            ,'MON',ld_last_date_month-6
                            ,'TUE',ld_last_date_month
                            ,'WED',ld_last_date_month-1
                            ,'THU',ld_last_date_month-2
                            ,'FRI',ld_last_date_month-3
                            ,'SAT',ld_last_date_month-4)
                INTO   ld_last_tuesday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Tuesday then , get the LAST Tuesday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_tuesday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-5
                            ,'MON',ld_last_date_month-6
                            ,'TUE',ld_last_date_month
                            ,'WED',ld_last_date_month-1
                            ,'THU',ld_last_date_month-2
                            ,'FRI',ld_last_date_month-3
                            ,'SAT',ld_last_date_month-4)
                    INTO   ld_last_tuesday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_tuesday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_tuesday_date,'MM');
                lc_year_eff := to_char(ld_last_tuesday_date,'YYYY');

            END IF;

            --Wednesday Frequencies
            IF ((lc_payment_term = 'WEDNESDAY1') OR (lc_payment_term = 'WEDNESDAY2') OR (lc_payment_term = 'WEDNESDAY3') OR (lc_payment_term = 'WEDNESDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',4
                              ,'MON',3
                              ,'TUE',2
                              ,'WED',1
                              ,'THU',7
                              ,'FRI',6
                              ,'SAT',5)
                INTO   ln_first_wednesday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'WEDNESDAY1',ln_first_wednesday_daynumber
                              ,'WEDNESDAY2',ln_first_wednesday_daynumber+7
                              ,'WEDNESDAY3',ln_first_wednesday_daynumber+14
                              ,'WEDNESDAY4',ln_first_wednesday_daynumber+21)
                INTO   ln_wednesday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_wednesday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Wednesday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',4
                              ,'MON',3
                              ,'TUE',2
                              ,'WED',1
                              ,'THU',7
                              ,'FRI',6
                              ,'SAT',5)
                    INTO   ln_first_wednesday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'WEDNESDAY1',ln_first_wednesday_daynumber
                              ,'WEDNESDAY2',ln_first_wednesday_daynumber+7
                              ,'WEDNESDAY3',ln_first_wednesday_daynumber+14
                              ,'WEDNESDAY4',ln_first_wednesday_daynumber+21)
                    INTO   ln_wednesday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_wednesday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'WEDNESDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-4
                            ,'MON',ld_last_date_month-5
                            ,'TUE',ld_last_date_month-6
                            ,'WED',ld_last_date_month
                            ,'THU',ld_last_date_month-1
                            ,'FRI',ld_last_date_month-2
                            ,'SAT',ld_last_date_month-3)
                INTO   ld_last_wednesday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Wednesday then , get the LAST Wednesday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_wednesday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-4
                            ,'MON',ld_last_date_month-5
                            ,'TUE',ld_last_date_month-6
                            ,'WED',ld_last_date_month
                            ,'THU',ld_last_date_month-1
                            ,'FRI',ld_last_date_month-2
                            ,'SAT',ld_last_date_month-3)
                    INTO   ld_last_wednesday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_wednesday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_wednesday_date,'MM');
                lc_year_eff := to_char(ld_last_wednesday_date,'YYYY');

            END IF;

            --Thursday Frequencies
            IF ((lc_payment_term = 'THURSDAY1') OR (lc_payment_term = 'THURSDAY2') OR (lc_payment_term = 'THURSDAY3') OR (lc_payment_term = 'THURSDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',5
                              ,'MON',4
                              ,'TUE',3
                              ,'WED',2
                              ,'THU',1
                              ,'FRI',7
                              ,'SAT',6)
                INTO   ln_first_thursday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'THURSDAY1',ln_first_thursday_daynumber
                              ,'THURSDAY2',ln_first_thursday_daynumber+7
                              ,'THURSDAY3',ln_first_thursday_daynumber+14
                              ,'THURSDAY4',ln_first_thursday_daynumber+21)
                INTO   ln_thursday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_thursday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Thursday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',5
                              ,'MON',4
                              ,'TUE',3
                              ,'WED',2
                              ,'THU',1
                              ,'FRI',7
                              ,'SAT',6)
                    INTO   ln_first_thursday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'THURSDAY1',ln_first_thursday_daynumber
                              ,'THURSDAY2',ln_first_thursday_daynumber+7
                              ,'THURSDAY3',ln_first_thursday_daynumber+14
                              ,'THURSDAY4',ln_first_thursday_daynumber+21)
                    INTO   ln_thursday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_thursday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'THURSDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-3
                            ,'MON',ld_last_date_month-4
                            ,'TUE',ld_last_date_month-5
                            ,'WED',ld_last_date_month-6
                            ,'THU',ld_last_date_month
                            ,'FRI',ld_last_date_month-1
                            ,'SAT',ld_last_date_month-2)
                INTO   ld_last_thursday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Thursday then , get the LAST Thursday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_thursday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-3
                            ,'MON',ld_last_date_month-4
                            ,'TUE',ld_last_date_month-5
                            ,'WED',ld_last_date_month-6
                            ,'THU',ld_last_date_month
                            ,'FRI',ld_last_date_month-1
                            ,'SAT',ld_last_date_month-2)
                    INTO   ld_last_thursday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_thursday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_thursday_date,'MM');
                lc_year_eff := to_char(ld_last_thursday_date,'YYYY');

            END IF;

            --Friday Frequencies

            IF ((lc_payment_term = 'FRIDAY1') OR (lc_payment_term = 'FRIDAY2') OR (lc_payment_term = 'FRIDAY3') OR (lc_payment_term = 'FRIDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',6
                              ,'MON',5
                              ,'TUE',4
                              ,'WED',3
                              ,'THU',2
                              ,'FRI',1
                              ,'SAT',7)
                INTO   ln_first_friday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'FRIDAY1',ln_first_friday_daynumber
                              ,'FRIDAY2',ln_first_friday_daynumber+7
                              ,'FRIDAY3',ln_first_friday_daynumber+14
                              ,'FRIDAY4',ln_first_friday_daynumber+21)
                INTO   ln_friday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_friday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Friday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',6
                              ,'MON',5
                              ,'TUE',4
                              ,'WED',3
                              ,'THU',2
                              ,'FRI',1
                              ,'SAT',7)
                    INTO   ln_first_friday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'FRIDAY1',ln_first_friday_daynumber
                              ,'FRIDAY2',ln_first_friday_daynumber+7
                              ,'FRIDAY3',ln_first_friday_daynumber+14
                              ,'FRIDAY4',ln_first_friday_daynumber+21)
                    INTO   ln_friday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_friday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'FRIDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-2
                            ,'MON',ld_last_date_month-3
                            ,'TUE',ld_last_date_month-4
                            ,'WED',ld_last_date_month-5
                            ,'THU',ld_last_date_month-6
                            ,'FRI',ld_last_date_month
                            ,'SAT',ld_last_date_month-1)
                INTO   ld_last_friday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Friday then , get the LAST Friday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_friday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-2
                            ,'MON',ld_last_date_month-3
                            ,'TUE',ld_last_date_month-4
                            ,'WED',ld_last_date_month-5
                            ,'THU',ld_last_date_month-6
                            ,'FRI',ld_last_date_month
                            ,'SAT',ld_last_date_month-1)
                    INTO   ld_last_friday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_friday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_friday_date,'MM');
                lc_year_eff := to_char(ld_last_friday_date,'YYYY');

            END IF;

            --Saturday Frequencies
            IF ((lc_payment_term = 'SATURDAY1') OR (lc_payment_term = 'SATURDAY2') OR (lc_payment_term = 'SATURDAY3') OR (lc_payment_term = 'SATURDAY4')) THEN

                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY'));

                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',7
                              ,'MON',6
                              ,'TUE',5
                              ,'WED',4
                              ,'THU',3
                              ,'FRI',2
                              ,'SAT',1)
                INTO   ln_first_saturday_daynumber
                FROM DUAL;

                SELECT DECODE(lc_payment_term
                              ,'SATURDAY1',ln_first_saturday_daynumber
                              ,'SATURDAY2',ln_first_saturday_daynumber+7
                              ,'SATURDAY3',ln_first_saturday_daynumber+14
                              ,'SATURDAY4',ln_first_saturday_daynumber+21)
                INTO   ln_saturday_daynumber
                FROM DUAL;

                IF (TO_NUMBER (lc_daynumber) > ln_saturday_daynumber) THEN

                    lc_month := lc_month+1;

                    --If the Saturday goes beyond December, make it as Next Year January
                    IF (lc_month > 12) THEN

                        lc_month := 1;
                        lc_year  := lc_year+1;

                    END IF;

                    lc_first_day_of_month := to_char(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),'DY');

                    SELECT DECODE(lc_first_day_of_month
                              ,'SUN',7
                              ,'MON',6
                              ,'TUE',5
                              ,'WED',4
                              ,'THU',3
                              ,'FRI',2
                              ,'SAT',1)
                    INTO   ln_first_saturday_daynumber
                    FROM   DUAL;

                    SELECT DECODE(lc_payment_term
                              ,'SATURDAY1',ln_first_saturday_daynumber
                              ,'SATURDAY2',ln_first_saturday_daynumber+7
                              ,'SATURDAY3',ln_first_saturday_daynumber+14
                              ,'SATURDAY4',ln_first_saturday_daynumber+21)
                    INTO   ln_saturday_daynumber
                    FROM DUAL;

                END IF;

                lc_daynumber_eff  := ln_saturday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;

            END IF;

            IF ((lc_payment_term = 'SATURDAYL')) THEN

                lc_payment_term_valid := 'Y';

                ld_last_date_month := LAST_DAY(p_invoice_creation_date);

                lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-1
                            ,'MON',ld_last_date_month-2
                            ,'TUE',ld_last_date_month-3
                            ,'WED',ld_last_date_month-4
                            ,'THU',ld_last_date_month-5
                            ,'FRI',ld_last_date_month-6
                            ,'SAT',ld_last_date_month)
                INTO   ld_last_saturday_date
                FROM   DUAL;

                --If the Invoice Creation Date is falling after the LAST Saturday then , get the LAST Saturday of the Next month
                IF (TRUNC(p_invoice_creation_date)> TRUNC(ld_last_saturday_date)) THEN

                    ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,1));
                    lc_last_day_of_month := to_char(ld_last_date_month,'DY');

                    SELECT  DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-1
                            ,'MON',ld_last_date_month-2
                            ,'TUE',ld_last_date_month-3
                            ,'WED',ld_last_date_month-4
                            ,'THU',ld_last_date_month-5
                            ,'FRI',ld_last_date_month-6
                            ,'SAT',ld_last_date_month)
                    INTO   ld_last_saturday_date
                     FROM   DUAL;

                END IF;

                lc_daynumber_eff := to_char(ld_last_saturday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_saturday_date,'MM');
                lc_year_eff := to_char(ld_last_saturday_date,'YYYY');

            END IF;

        END IF;

        IF (lc_frequency = 'WDAY') THEN

            lc_frequency_valid := 'Y';

            lc_day_of_week := to_char(p_invoice_creation_date,'DY');

            lc_payment_term_valid := 'Y';

            --Getting the date of the next coming Monday
            SELECT  DECODE(lc_day_of_week
                    ,'SUN',p_invoice_creation_date+1
                    ,'MON',p_invoice_creation_date
                    ,'TUE',p_invoice_creation_date
                    ,'WED',p_invoice_creation_date
                    ,'THU',p_invoice_creation_date
                    ,'FRI',p_invoice_creation_date+3
                    ,'SAT',p_invoice_creation_date+2)
            INTO   ld_week_date_eff
            FROM   DUAL;


            RETURN (ld_week_date_eff);

        END IF;

        IF (lc_frequency = 'MNTH') THEN

            lc_frequency_valid := 'Y';

            IF (lc_payment_term = '1') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 1) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 1;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 1;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '2') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 2) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 2;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 2;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '3') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 3) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 3;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 3;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '4') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 4) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 4;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 4;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;



            END IF;

            IF (lc_payment_term = '5') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 5) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 5;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 5;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '6') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 6) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 6;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 6;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '7') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 7) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 7;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 7;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '8') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 8) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 8;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 8;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '9') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 9) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 9;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 9;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '10') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 10) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 10;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 10;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '11') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 11) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 11;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 11;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '12') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 12) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 12;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 12;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '13') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 13) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 13;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 13;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '14') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 14) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 14;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 14;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '15') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 15) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 15;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 15;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '16') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 16) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 16;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 16;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '17') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 17) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 17;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 17;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '18') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 18) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 18;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 18;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '19') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 19) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 19;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 19;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '20') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 20) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 20;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 20;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '21') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 21) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 21;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 21;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '22') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 22) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 22;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 22;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '23') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 23) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 23;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 23;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '24') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 24) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 24;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 24;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '25') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 25) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 25;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 25;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '26') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 26) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 26;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 26;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '27') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 27) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 27;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 27;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;

            IF (lc_payment_term = '28') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 28) THEN      --Day


                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 28;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 28;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

            END IF;
            IF (lc_payment_term = '29') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 29) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 29;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 29;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

                    --Checking for the February 29, non Leap year              --Commented for defect 1375
                  /*IF (lc_month_eff = 2 AND ( MOD(lc_year_eff,4) != 0 ) ) THEN

                        --Setting as March 1
                        lc_month_eff := lc_month_eff+1;
                        lc_daynumber_eff := 1;

                    END IF;*/
                  -- Start of Changes for Defect 1375

--                ld_last_date_month   := LAST_DAY(p_invoice_creation_date);
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');

                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb29 , set as Feb 28(EOM)

                END IF;
                  -- End of Changes for Defect 1375

            END IF;
            IF (lc_payment_term = '30') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 30) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 30;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 30;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

                --Checking for the February 30, non Leap year, setting as March 2              --Commented for defect 1375
              /*IF (lc_month_eff = 2 AND ( MOD(lc_year_eff,4) != 0 ) ) THEN

                    --Setting as March 2
                    lc_month_eff := lc_month_eff+1;
                    lc_daynumber_eff := 2;

                END IF;

                --Checking for the February 31, Leap year, setting as March 1
                IF (lc_month_eff = 2 AND ( MOD(lc_year_eff,4) = 0 ) ) THEN

                    --Setting as March 2
                    lc_month_eff := lc_month_eff+1;
                    lc_daynumber_eff := 1;

                END IF;*/
                  -- Start of Changes for Defect 1375

--                ld_last_date_month   := LAST_DAY(p_invoice_creation_date);
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');

                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb30 , set as Feb 28(EOM)

                END IF;
                  -- End of Changes for Defect 1375

            END IF;
            IF (lc_payment_term = '31') THEN

                lc_payment_term_valid := 'Y';

                IF (lc_daynumber > 31) THEN      --Day

                    lc_month_eff := lc_month+1;
                    lc_daynumber_eff := 31;       --Day
                    lc_year_eff := lc_year;

                    IF (lc_month_eff > 12) THEN

                        lc_month_eff := 1;
                        lc_year_eff := lc_year+1;

                    END IF;

                ELSE

                    lc_daynumber_eff := 31;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;

                END IF;

                --Checking for the February 31, non Leap year, setting as March 3          --Commented for Defect 1375
              /*IF (lc_month_eff = 2 AND ( MOD(lc_year_eff,4) != 0 ) ) THEN

                    --Setting as March 2
                    lc_month_eff := lc_month_eff+1;
                    lc_daynumber_eff := 3;

                END IF;

                --Checking for the February 31, Leap year, setting as March 2
                IF (lc_month_eff = 2 AND ( MOD(lc_year_eff,4) = 0 ) ) THEN

                    --Setting as March 2
                    lc_month_eff := lc_month_eff+1;
                    lc_daynumber_eff := 2;

                END IF;

                --Checking if for April 31, June 31, Sep 31, Nov31, setting as the 1 of the next month
                IF( (lc_month_eff = 4) OR (lc_month_eff = 6) OR (lc_month_eff = 9) OR (lc_month_eff = 11) ) THEN

                    --setting as the 1 of the next month
                    lc_month_eff := lc_month_eff+1;
                    lc_daynumber_eff := 1;

                END IF;*/
                  -- Start of Changes for Defect 1375

--                ld_last_date_month   := LAST_DAY(p_invoice_creation_date);
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');

                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb31,April 31,June 31, Sep 31, Nov 31 Set EOM as effective date

                END IF;
                  -- End of Changes for Defect 1375

            END IF;

        ELSIF (lc_frequency like 'DAIL%') THEN

            lc_frequency_valid := 'Y';
            lc_payment_term_valid := 'Y';

            lc_daynumber_eff := lc_daynumber;
            lc_month_eff     := lc_month;
            lc_year_eff      := lc_year;

        ELSIF (lc_frequency = 'QUAR') THEN

            lc_frequency_valid := 'Y';
            lc_payment_term_valid := 'Y';
            --Fourth Quarter
            IF (lc_month > 9) THEN

                lc_daynumber_eff := '31';
                lc_month_eff     := '12';
                lc_year_eff      := lc_year;
            --Third Quarter
            ELSIF (lc_month > 6) THEN

                lc_daynumber_eff := '30';
                lc_month_eff     := '09';
                lc_year_eff      := lc_year;
            --Second Quarter
            ELSIF (lc_month > 3) THEN

                lc_daynumber_eff := '30';
                lc_month_eff     := '06';
                lc_year_eff      := lc_year;
            --First Quarter
            ELSE

                lc_daynumber_eff := '31';
                lc_month_eff     := '03';
                lc_year_eff      := lc_year;

            END IF;

        ELSIF (lc_frequency = 'WEEK') THEN

            lc_frequency_valid := 'Y';

            lc_day_of_week := to_char(p_invoice_creation_date,'DY');

            -- below if block added for defect 352
            IF (lc_payment_term = 'SUNDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming SUNDAY
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date
                        ,'MON',p_invoice_creation_date+6
                        ,'TUE',p_invoice_creation_date+5
                        ,'WED',p_invoice_creation_date+4
                        ,'THU',p_invoice_creation_date+3
                        ,'FRI',p_invoice_creation_date+2
                        ,'SAT',p_invoice_creation_date+1)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;


        --    IF (lc_payment_term = 'SUNDAY' OR lc_payment_term = 'MONDAY') THEN  commented for defect 352
           IF (lc_payment_term = 'MONDAY')  THEN  --added for defect 352
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+1
                        ,'MON',p_invoice_creation_date
                        ,'TUE',p_invoice_creation_date+6
                        ,'WED',p_invoice_creation_date+5
                        ,'THU',p_invoice_creation_date+4
                        ,'FRI',p_invoice_creation_date+3
                        ,'SAT',p_invoice_creation_date+2)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term = 'TUESDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+2
                        ,'MON',p_invoice_creation_date+1
                        ,'TUE',p_invoice_creation_date
                        ,'WED',p_invoice_creation_date+6
                        ,'THU',p_invoice_creation_date+5
                        ,'FRI',p_invoice_creation_date+4
                        ,'SAT',p_invoice_creation_date+3)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term = 'WEDNESDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+3
                        ,'MON',p_invoice_creation_date+2
                        ,'TUE',p_invoice_creation_date+1
                        ,'WED',p_invoice_creation_date
                        ,'THU',p_invoice_creation_date+6
                        ,'FRI',p_invoice_creation_date+5
                        ,'SAT',p_invoice_creation_date+4)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term = 'THURSDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+4
                        ,'MON',p_invoice_creation_date+3
                        ,'TUE',p_invoice_creation_date+2
                        ,'WED',p_invoice_creation_date+1
                        ,'THU',p_invoice_creation_date
                        ,'FRI',p_invoice_creation_date+6
                        ,'SAT',p_invoice_creation_date+5)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term = 'FRIDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+5
                        ,'MON',p_invoice_creation_date+4
                        ,'TUE',p_invoice_creation_date+3
                        ,'WED',p_invoice_creation_date+2
                        ,'THU',p_invoice_creation_date+1
                        ,'FRI',p_invoice_creation_date
                        ,'SAT',p_invoice_creation_date+6)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term = 'SATURDAY') THEN

                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+6
                        ,'MON',p_invoice_creation_date+5
                        ,'TUE',p_invoice_creation_date+4
                        ,'WED',p_invoice_creation_date+3
                        ,'THU',p_invoice_creation_date+2
                        ,'FRI',p_invoice_creation_date+1
                        ,'SAT',p_invoice_creation_date)
                INTO   ld_week_date_eff
                FROM   DUAL;

            END IF;

            IF (lc_payment_term_valid = 'N') THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);

            END IF;

            RETURN (ld_week_date_eff);

        END IF;

        IF (lc_frequency = 'SEMI') THEN

            lc_frequency_valid := 'Y';

            /*IF (lc_payment_term = '1-16') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('16'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '2-17') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('02'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('17'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '3-18') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('03'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('18'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '4-19') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('04'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('19'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '5-20') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('05'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('20'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '6-21') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('06'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('21'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '7-22') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('07'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('22'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '8-23') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('08'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('23'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '9-24') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('09'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('24'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '10-25') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('10'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('25'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '11-26') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('11'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('26'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '12-27') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('12'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('27'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '13-28') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('13'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('28'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term = '14-29') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('14'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                --if February month and leap year, last date of the month as 29th Feb

                IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN

                    ld_end_period_date := LAST_DAY(p_invoice_creation_date);

                --if February month and leap year, last date of the month as 29th Feb
                ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN

                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;

                ELSE

                    ld_end_period_date   := to_date('29'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                END IF;


                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;

            IF (lc_payment_term LIKE '15-3%') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('15'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                 --if February month and leap year, last date of the month as 29th Feb

                IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN

                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;

                --if February month and leap year, last date of the month as 29th Feb
                ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN

                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+2;

                ELSE

                    ld_end_period_date   := to_date('30'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                END IF;

                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;*/


            --Commented for the Defect# 8350
            /*IF (lc_payment_term LIKE '15-E%') THEN

                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('15'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                ld_end_period_date := LAST_DAY(p_invoice_creation_date);


                IF (p_invoice_creation_date < ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            END IF;*/

            /*Start of Addition for the Defect# 8350, for the new Payment Term 16-EOM*/
            IF (lc_payment_term LIKE '%-EOM') THEN

                lc_payment_term_valid := 'Y';

                lc_error_loc := 'Getting the Start for SEMI term type (EOM)';

                ln_semi_start_date := SUBSTR(lc_payment_term,1,INSTR(lc_payment_term,'-',1,1)-1 );

                ld_start_period_date := TO_DATE(ln_semi_start_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                ld_end_period_date := LAST_DAY(p_invoice_creation_date);


                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

            ELSIF (lc_payment_term LIKE '%-%') THEN

                lc_payment_term_valid := 'Y';
                ln_semi_start_date := SUBSTR(lc_payment_term,1,INSTR(lc_payment_term,'-',1,1)-1 );
                ln_semi_end_date := SUBSTR(lc_payment_term,INSTR(lc_payment_term,'-',1,1)+1 );
                ld_last_date_month   := LAST_DAY(p_invoice_creation_date);                -- Added for Defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');                  -- Added for Defect 1375
                ld_start_period_date := to_date(ln_semi_start_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                --Commented for the Defect# 9278
                --ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                --if February month and leap year, last date of the month as 29th Feb

                IF (ln_semi_end_date = 29) THEN

                  /*IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN

                        ld_end_period_date := LAST_DAY(p_invoice_creation_date);

                    --if February month and leap year, last date of the month as 29th Feb
                    ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN

                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;

                    ELSE

                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    END IF;*/             --commented for defect 1375

                     -- Start of Changes for Defect 1375

                    IF ln_semi_end_date > lc_last_day_of_month THEN

                       ld_end_period_date   := TO_DATE(lc_last_day_of_month||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                    ELSE

                       ld_end_period_date   := TO_DATE(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                    END IF;
                    -- End of Changes for Defect 1375

                ELSIF (ln_semi_end_date = 30) THEN

                  /*IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN

                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;

                    --if February month and leap year, last date of the month as 29th Feb
                    ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN

                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+2;

                    ELSE

                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                    END IF;*/                  --commented for defect 1375

                    -- Start of Changes for Defect 1375

                    IF ln_semi_end_date > lc_last_day_of_month THEN

                       ld_end_period_date   := TO_DATE(lc_last_day_of_month||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                    ELSE

                       ld_end_period_date   := TO_DATE(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');

                    END IF;
                    -- End of Changes for Defect 1375

                ELSE

                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');


                END IF;


                IF (p_invoice_creation_date <= ld_start_period_date) THEN

                    ld_week_date_eff := ld_start_period_date;

                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN

                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);

                ELSE

                    ld_week_date_eff := ld_end_period_date;

                END IF;

                IF (ln_semi_start_date >= ln_semi_end_date) THEN

                    lc_payment_term_valid := 'N';
                    ld_week_date_eff := NULL;

                END IF;

            END IF;

            /*End of Addition for the Defect# 8350, for the new Payment Term 16-EOM*/

            IF (lc_payment_term_valid = 'N') THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);

            END IF;

            RETURN(ld_week_date_eff);

        END IF;

        --If the Frequency is invalid
        IF (lc_frequency_valid = 'N') THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Frequency: '||lc_frequency||' is not valid; '||'Payment Term: '||lc_payment_term||'; Billing Payment Term: '||p_payment_term);

-- Commented for defect # 2308
/*            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AR'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Frequency: '||lc_frequency||' is not valid'
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'AR Frequency ');
*/
            RETURN (NULL);

        END IF;

        --If the Payment term is invalid
        IF (lc_payment_term_valid = 'N') THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);

-- Commented for defect # 2308
/*            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AR'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Payment Term: '||lc_payment_term||' is not valid'
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'AR Frequency ');
*/
            RETURN (NULL);

        END IF;


        --FND_FILE.PUT_LINE(FND_FILE.LOG, lc_payment_term);

        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_month_eff :'||lc_month);

        --FND_FILE.PUT_LINE(FND_FILE.LOG, lc_daynumber_eff||'-'||lc_month_eff||'-'||lc_year_eff);

        SELECT TO_DATE(lc_daynumber_eff||'-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YYYY')
        INTO ld_date_eff
        FROM DUAL;

        RETURN (ld_date_eff);

    EXCEPTION WHEN OTHERS THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_loc);
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||lc_error_debug);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Frequency: '||lc_frequency||'Payment Term: '||lc_payment_term||'Billing Payment Term: '||p_payment_term);

-- Commented for defect # 2308
/*        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
             p_program_type            => 'CONCURRENT PROGRAM'
            ,p_program_name            => gc_concurrent_program_name
            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
            ,p_module_name             => 'AR'
            ,p_error_location          => ''
            ,p_error_message_count     => 1
            ,p_error_message_code      => 'E'
            ,p_error_message           => SQLERRM
            ,p_error_message_severity  => 'Major'
            ,p_notify_flag             => 'N'
            ,p_object_type             => 'AR Frequency ');
*/
        RETURN (NULL);


    END COMPUTE_EFFECTIVE_DATE_old;

-- Below function is added for the R1.1 Defect # 1451 (CR 626)

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Gift card Invoices                                                  |
-- | Description : To Populate the Invoices paid by Gift Card                          |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       27-Aug-09    Tamil Vendhan L      Initial Version                        |
-- |1.1       02-APR-2018  Punit Gupta CG       Retrofit Billing Programs with         |
-- |                                            custom OM Views- Defect NAIT-31697     |
-- +===================================================================================+

--Below function is added for the R1.1 Defect # 1451 (CR 626)

FUNCTION GIFT_CARD_INV (
                         p_customer_trx_id   IN   NUMBER
                        ,p_header_id         IN   VARCHAR2
                       ) RETURN VARCHAR2 IS

   lc_gc_processed      VARCHAR2(1)     := 'Y';
   ln_gc_count          NUMBER          := 0;
   ln_non_gc_count      NUMBER          := 0;
   ln_ext_amt           NUMBER          := 0;
   ln_cust_trx_id       NUMBER(15)      := p_customer_trx_id;
   lc_error_loc         VARCHAR2(4000)  := NULL;
   lc_error_debug       VARCHAR2(4000)  := NULL;
   --lc_gc_payment_code   fnd_profile_option_values.profile_option_value%type     := FND_PROFILE.VALUE('OD_BILLING_GIFTCARD_PAYMENT_TYPE'); --Commented by Havish Kasina as per Version 2.32
   lc_translation_name  VARCHAR2(50)    := 'XXOD_GIFTCARD_PAY_TYPE';  --Added by Havish Kasina as per Version 2.32
   ln_gc_amt1           NUMBER          := 0;  --Added by Havish Kasina as per Version 2.32
   ln_gc_amt2           NUMBER          := 0;  --Added by Havish Kasina as per Version 2.32

   BEGIN
      gn_gc_amt := 0;
      lc_error_loc   := 'Getting the count for gift card,non gift card orders and total gift card amount ';
      lc_error_debug := 'Getting the count for gift card,non gift card orders and total gift card amount for the cust_trx_id: '||ln_cust_trx_id;
      --Commented by Havish Kasina as per Version 2.32
    /* SELECT  NVL(SUM(DECODE(OP.attribute11,lc_gc_payment_code,1,0)),0)
             ,NVL(SUM(DECODE(OP.attribute11,lc_gc_payment_code,0,1)),0)
             ,NVL(SUM(OP.payment_amount),0)
      INTO    ln_gc_count
             ,ln_non_gc_count
             ,gn_gc_amt
      FROM    oe_payments OP
      WHERE   OP.header_id        = p_header_id; */
      
      --Added by Havish Kasina as per Version 2.32
		
	   SELECT  COUNT(1) , 
	           NVL(SUM(OP.payment_amount),0) 
		 INTO  ln_non_gc_count,
		       ln_gc_amt1
         FROM  xx_oe_payments_v OP -- Commented and Changed by Punit CG on 02-APR-2018 for Defect NAIT-31697
		       --oe_payments OP
        WHERE  NOT EXISTS ( SELECT 1 
		                      FROM xx_fin_translatedefinition def,
                                   xx_fin_translatevalues val
                             WHERE OP.attribute11 = val.target_value1
                               AND def.translate_id = val.translate_id
                               AND def.translation_name = lc_translation_name)
          AND  OP.header_id   =  p_header_id;

       SELECT  COUNT(1) , 
	           NVL(SUM(OP.payment_amount),0) 
	     INTO  ln_gc_count,
		       ln_gc_amt2
         FROM  xx_oe_payments_v OP -- Commented and Changed by Punit CG on 02-APR-2018 for Defect NAIT-31697
		       --oe_payments OP
        WHERE  EXISTS ( SELECT 1 
		                  FROM xx_fin_translatedefinition def,
                               xx_fin_translatevalues val
                         WHERE OP.attribute11 = val.target_value1
                           AND def.translate_id = val.translate_id
                           AND def.translation_name = lc_translation_name)
          AND  OP.header_id   =  p_header_id; 		  

		gn_gc_amt := ln_gc_amt1 + ln_gc_amt2;
	-- End of adding changes by Havish Kasina as per Version 2.32
	
      IF ln_gc_count = 0 AND ln_non_gc_count = 0 THEN
         lc_gc_processed := 'Y';
      ELSIF ln_non_gc_count > 0 THEN
         lc_gc_processed := 'N';
      ELSE
        lc_error_loc   := 'Fetching the total amount of the Invoice';
        lc_error_debug := 'Fetching the total amount of the Invoice for the customer_trx_id: '||ln_cust_trx_id;
         SELECT  NVL(SUM(rctl.extended_amount),0)
         INTO    ln_ext_amt
         FROM    ra_customer_trx_lines_all RCTL
         WHERE   RCTL.customer_trx_id = ln_cust_trx_id;

         IF(ln_ext_amt > gn_gc_amt ) THEN
               lc_gc_processed := 'Y';
         ELSE
               lc_gc_processed := 'N';
         END IF;
      END IF;

   RETURN (lc_gc_processed);

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
         lc_gc_processed := 'N';
         RETURN (lc_gc_processed);

   END gift_card_inv;

    --Below function is added for the R1.1 Defect # 1451 (CR 626)

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Gift card Credit Memos                                              |
-- | Description : To Populate the Credit Memos whose original Invoices carries one or |
-- |               gift cards                                                          |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       27-Aug-09    Tamil Vendhan L                     Initial Version         |
-- +===================================================================================+

    --Below function is added for the R1.1 Defect # 1451 (CR 626)

FUNCTION GIFT_CARD_CM (
                        p_customer_trx_id        IN   NUMBER
                       ,p_header_id              IN   VARCHAR2
                      )RETURN VARCHAR2 IS

   ln_header_id         NUMBER;
   ln_gc_count          NUMBER          := 0;
   ln_non_gc_count      NUMBER          := 0;
   lc_gc_processed      VARCHAR2(1)     := 'Y';
   ln_ext_amt           NUMBER          := 0;
   ln_cust_trx_id       NUMBER(15)      := p_customer_trx_id;
   lc_error_loc         VARCHAR2(4000)  := NULL;
   lc_error_debug       VARCHAR2(4000)  := NULL;
   -- lc_gc_payment_code   fnd_profile_option_values.profile_option_value%type     := FND_PROFILE.VALUE('OD_BILLING_GIFTCARD_PAYMENT_TYPE'); -- Commented as per Version 2.32

   BEGIN
      gn_gc_amt := 0;

      BEGIN
         lc_error_loc   := 'Fetching the original transaction header id in case if it is a gift card order';
         lc_error_debug := 'Fetching the original trx header id for the customer_trx_id: '||ln_cust_trx_id;
--commented for defect 3136
/*
         SELECT  NVL(SUM(DECODE(OP.attribute11,lc_gc_payment_code,1,0)),0)
                ,NVL(SUM(DECODE(OP.attribute11,lc_gc_payment_code,0,1)),0)
         INTO    ln_gc_count
                ,ln_non_gc_count
         FROM   xx_om_return_tenders_all ORT
               ,oe_order_lines_all OOL
               ,xx_om_line_attributes_all XOLA
               ,oe_payments OP
               ,ra_customer_trx_all RCT
         WHERE  ORT.header_id            =    OOL.header_id
         AND    OOL.line_id              =    XOLA.line_id
         AND    XOLA.ret_ref_header_id   =    OP.header_id
         AND    ORT.header_id             =   RCT.attribute14
         AND    RCT.customer_trx_id      =    ln_cust_trx_id;
*/

         SELECT  COUNT(ORT.header_id)
                 ,NVL(SUM(ORT.credit_amount),0)
         INTO    ln_gc_count
                ,gn_gc_amt
         FROM   xx_om_return_tenders_all ORT
               ,ra_customer_trx_all RCT
         WHERE  ORT.header_id             =   RCT.attribute14
         AND    RCT.customer_trx_id      =    ln_cust_trx_id;

      EXCEPTION
         WHEN OTHERS THEN
            ln_gc_count       := 0;
            ln_non_gc_count   := 0;
      END;

-- End of changes for  defect 3136

      lc_error_loc   := 'Getting the count for gift card and non gift card orders';
      lc_error_debug := 'Getting the count for gift card and non gift card orders for the header id: '||ln_header_id;

     -- IF ln_gc_count = 0 AND ln_non_gc_count = 0  THEN
     -- commented for 3136
      IF ln_gc_count = 0  THEN
         lc_gc_processed := 'Y';
    -- ELSIF ln_non_gc_count > 0 THEN
    --  lc_gc_processed := 'N';
         -- commented for 3136
      ELSE
         lc_error_loc   := 'Fetching the total amount of the credit memo';
         lc_error_debug := 'Fetching the total amount of the credit memo for the customer_trx_id: '||ln_cust_trx_id;
         SELECT  NVL(SUM(rctl.extended_amount),0)
         INTO    ln_ext_amt
         FROM    ra_customer_trx_lines_all RCTL
         WHERE   RCTL.customer_trx_id = ln_cust_trx_id;
-- commented for 3136
/*
         lc_error_loc   := 'Fetching the gift card total amount';
         lc_error_debug := 'Fetching the gift card total amount for the customer_trx_id: '||ln_cust_trx_id;
         SELECT  NVL(SUM(ORT.credit_amount),0)
         INTO    gn_gc_amt
         FROM    xx_om_return_tenders_all ORT
         WHERE   ORT.header_id       = p_header_id;
*/
            IF(abs(ln_ext_amt) > abs(gn_gc_amt)) THEN
               lc_gc_processed := 'Y';
            ELSE
               lc_gc_processed := 'N';
            END IF;

         END IF;

   RETURN (lc_gc_processed);

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
         lc_gc_processed := 'N';
         RETURN (lc_gc_processed);

   END gift_card_cm;

--Below function is added for the R1.2 Defect # 1201 (CR 466)

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Address Exception Handling                                          |
-- | Description : To Handle address exceptions                                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       22-Dec-09    Tamil Vendhan L      Initial Version                        |
-- +===================================================================================+

FUNCTION XX_AR_ADDR_EXCP_HANDLING ( p_cust_account_id     NUMBER
                                   ,p_cust_doc_id         NUMBER
                                   ,p_attr_group_id       NUMBER
                                   ,p_bill_to_site_use_id NUMBER
                                   ,p_ship_to_site_use_id NUMBER
                                   )
RETURN NUMBER AS

   ln_site_use_id        NUMBER;
   lc_delivery_method    VARCHAR2(10);
   lc_paydoc_flag        VARCHAR2(1);
   lc_direct_flag        VARCHAR2(1);
   ln_site_attr_id       NUMBER;
   lc_error_loc          VARCHAR2(1000);
   lc_error_debug        VARCHAR2(1000);
   ln_cust_acct_site_id  hz_cust_acct_sites_all.cust_acct_site_id%type;

   BEGIN
      IF p_cust_doc_id IS NOT NULL THEN

         lc_error_loc   := 'Before first select statement';
         lc_error_debug := 'Fetching details for the cust_doc_id: '||p_cust_doc_id||' and cust_account_id: '||p_cust_account_id||'and attr group id: '||p_attr_group_id;

         BEGIN
            SELECT XCCAE.c_ext_attr3
                  ,XCCAE.c_ext_attr2
                  ,XCCAE.c_ext_attr7
            INTO   lc_delivery_method
                  ,lc_paydoc_flag
                  ,lc_direct_flag
            FROM   xx_cdh_cust_acct_ext_b  XCCAE
            WHERE  XCCAE.cust_account_id   = p_cust_account_id
            AND    XCCAE.n_ext_attr2       = p_cust_doc_id
            AND    XCCAE.attr_group_id     = p_attr_group_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lc_delivery_method := NULL;
               lc_paydoc_flag     := NULL;
               lc_direct_flag     := NULL;
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at :'||lc_error_loc||'Error while: '||lc_error_debug||''||SQLERRM);
         END;

         lc_error_loc   := 'After first select statement';
         lc_error_debug := 'Cannot fetch details for the cust_doc_id: '||p_cust_doc_id||' and cust_account_id: '||p_cust_account_id;

         IF (lc_paydoc_flag = 'N' AND lc_delivery_method <> 'EDI') THEN

         BEGIN
            SELECT attr_group_id
            INTO   ln_site_attr_id
            FROM   ego_attr_groups_v
            WHERE  attr_group_type   = 'XX_CDH_CUST_ACCT_SITE'
            AND    attr_group_name   = 'BILLDOCS';

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            ln_site_attr_id := 0;
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at :'||lc_error_loc||'Error while: '||lc_error_debug||''||SQLERRM);

         END;

            BEGIN
               lc_error_loc   := 'Inside Infodoc Address exception select statement';
               lc_error_debug := 'Fetching details for the cust_account_id: '||p_cust_account_id;

               SELECT cust_acct_site_id
               INTO   ln_cust_acct_site_id
               FROM   hz_cust_site_uses_all
               WHERE  site_use_id = p_ship_to_site_use_id;

               SELECT HCSU.site_use_id
               INTO   ln_site_use_id
               FROM   xx_cdh_acct_site_ext_b XCASE
                     ,hz_cust_acct_sites_all HCAS
                     ,hz_cust_site_uses_all  HCSU
               WHERE  XCASE.cust_acct_site_id = ln_cust_acct_site_id
               AND    XCASE.n_ext_attr1       = p_cust_doc_id
               AND    HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
               AND    XCASE.c_ext_attr5       = HCAS.orig_system_reference
               AND    XCASE.attr_group_id     = ln_site_attr_id
               AND    HCSU.site_use_code      = 'SHIP_TO'
               AND    XCASE.c_ext_attr20      = 'Y';                 -- Added for R1.3 CR 738 Defect 2766

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  IF (lc_direct_flag = 'Y') THEN
                     lc_error_loc   := 'Inside Infodoc direct select statement';
                     lc_error_debug := 'Fetching details for the cust_account_id: '||p_cust_account_id;

                     SELECT  HCSU.site_use_id
                     INTO    ln_site_use_id
                     FROM    hz_cust_acct_sites HCAS
                            ,hz_cust_site_uses  HCSU
                     WHERE   HCAS.cust_account_id   = p_cust_account_id
                     AND     HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
                     AND     HCSU.site_use_code     = 'BILL_TO'
                     AND     HCSU.primary_flag      = 'Y';

                  ELSE
                     ln_site_use_id := p_ship_to_site_use_id;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'ship_to_site_use_id :'||p_ship_to_site_use_id);
                  END IF;
            END;
         ELSIF (lc_paydoc_flag = 'Y' OR lc_delivery_method = 'EDI') THEN
            ln_site_use_id := p_bill_to_site_use_id;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'bill_to_site_use_id :'||p_bill_to_site_use_id);
        END IF;
      ELSE
         lc_error_loc   := 'Inside select statement when cust_doc_id is NULL';
         lc_error_debug := 'Fetching details for the cust_account_id: '||p_cust_account_id;
         ln_site_use_id := p_bill_to_site_use_id;
      END IF;
   RETURN (ln_site_use_id);
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error at :'||lc_error_loc||'Error while: '||lc_error_debug||''||SQLERRM);
   END XX_AR_ADDR_EXCP_HANDLING;

-- End of changes for R1.2 Defect 1201 (CR 466)

--Below function is added for the R1.3 Defect # 2766 (CR 738)

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Infocopies handling logic                                           |
-- | Description : This function will return 'Y' or 'N' depending upon whether the     |
-- |               infocopy can be sent or not                                         |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       01-Apr-10    Tamil Vendhan L      Initial Version                        |
-- +===================================================================================+

FUNCTION XX_AR_INFOCOPY_HANDLING (p_cust_trx_id      IN NUMBER
                                 ,p_cust_doc_id      IN NUMBER
                                 ,p_cust_acct_id     IN NUMBER
                                 ,p_effec_start_date IN DATE
                                 ,p_info_pay_term    IN VARCHAR2
                                 ,p_attr_group_id    IN NUMBER
                                 ,p_as_of_date       IN DATE
                                 ,p_attribute15      IN VARCHAR2    -- added for Defect 6375
                                 )
RETURN VARCHAR2 AS

    ld_est_prnt_date      DATE          := NULL;
    lc_infocopy_flag      VARCHAR2(1)   := NULL;
    ld_cut_off_date       DATE          := NULL;
    lc_paydoc_term        VARCHAR2(150) := NULL;
    lc_error_location     VARCHAR2(2000):= NULL;

    BEGIN
       lc_error_location := 'Checking for the existence of cust doc id and customer trx id combination in freq history table';
       BEGIN
          BEGIN
             SELECT 'N'
             INTO   lc_infocopy_flag
             FROM   DUAL
             WHERE EXISTS (
                            SELECT 1 FROM xx_ar_invoice_freq_history xaifh
                            WHERE xaifh.customer_document_id = p_cust_doc_id
                            AND   xaifh.invoice_id           = p_cust_trx_id
                           );
          EXCEPTION WHEN NO_DATA_FOUND THEN         --- Moved the Union Query from the above select into a seperate step for performance considerations as part of 6375
               SELECT 'N'
                INTO   lc_infocopy_flag
                FROM   DUAL
                WHERE EXISTS (
                               SELECT 1 FROM xx_ar_invoice_frequency xaif
                               WHERE xaif.customer_document_id = p_cust_doc_id
                               AND   xaif.invoice_id           = p_cust_trx_id
                              );
          END;

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             lc_error_location := 'Fetching the estimated print date';
             BEGIN
                SELECT estimated_print_date
                INTO   ld_est_prnt_date
                FROM   xx_ar_invoice_freq_history
                WHERE  invoice_id  = p_cust_trx_id
                AND    paydoc_flag = 'Y';

                lc_error_location := 'Checking whether infocopy can be sent or not by passing estimated print date and infodoc freq to comp effec date';
                IF xx_ar_inv_freq_pkg.compute_effective_date(p_info_pay_term,ld_est_prnt_date) >= p_effec_start_date THEN
                   lc_infocopy_flag := 'Y';
                ELSE
                   lc_infocopy_flag := 'N';
                END IF;

             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   lc_error_location := 'Fetching the cut off date (attribute1 - 1)';
                   BEGIN
                      SELECT (TO_DATE(aci.attribute1,'DD-MON-RR') - 1)
                      INTO   ld_cut_off_date
                      FROM   ar_cons_inv_all     ACI
                            ,ar_cons_inv_trx_all ACIT
                      WHERE  aci.cons_inv_id      = acit.cons_inv_id
                      AND    acit.customer_trx_id = p_cust_trx_id
                      AND    aci.customer_id = p_cust_acct_id
                      AND    (aci.attribute2       IS NOT NULL
                              OR
                              aci.attribute4       IS NOT NULL
                              OR
                              aci.attribute10      IS NOT NULL
                              OR                                  -- Added for R1.4 CR# 586 eBilling.
                              aci.attribute15      IS NOT NULL
                             );

                      lc_error_location := 'Checking whether infocopy can be sent or not by passing cut off date and infodoc freq to comp effec date';
                      IF xx_ar_inv_freq_pkg.compute_effective_date(p_info_pay_term,ld_cut_off_date) >= p_effec_start_date THEN
                         lc_infocopy_flag := 'Y';
                      ELSE
                         lc_infocopy_flag := 'N';
                      END IF;

                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                         lc_error_location := 'Cheking whether paydoc falls under the same frequency';
                         BEGIN
                           IF p_attribute15 IN ('N','Y') THEN                   -- Added IF condition for defect 6375

                              SELECT c_ext_attr14
                              INTO   lc_paydoc_term
                              FROM   xx_cdh_cust_acct_ext_b
                              WHERE  c_ext_attr2            = 'Y'
                              AND    p_as_of_date           >= d_ext_attr1
                              AND    (d_ext_attr2           IS NULL
                                      OR
                                      p_as_of_date          <= d_ext_attr2
                                     )
                              AND    cust_account_id        = p_cust_acct_id
                              AND    attr_group_id          = p_attr_group_id
                              AND    c_ext_attr16           = 'COMPLETE'   -- Added for R1.4 CR# 586 eBilling
                              AND    ROWNUM                 < 2;

                              IF xx_ar_inv_freq_pkg.compute_effective_date(lc_paydoc_term,p_as_of_date) = p_as_of_date THEN
                                 lc_infocopy_flag := 'Y';
                              ELSE
                                 lc_infocopy_flag := 'N';
                              END IF;
                           -- Start of changes for defect 6375
                           ELSE
                              lc_infocopy_flag := 'N';
                           END IF;
                           -- Changs for defect 6375 ends
                         EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                            lc_infocopy_flag := 'N';
                         END;
                   END;
             END;
       END;
       RETURN (lc_infocopy_flag);

    EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'When others exception in '||lc_error_location||SQLERRM);
          RETURN ('N');

    END XX_AR_INFOCOPY_HANDLING;

-- Added the below procedure for R1.3 CR 738 Defect 2766

-- +===================================================================+
-- | Name : SYNCH_MASTER                                               |
-- | Description : This Program will collect all the valid customer    |
-- |               documents for the current billing cycle and         |
-- |               Populates a temporary staging table. This table will|
-- |               be used to batch the records into multiple threads. |
-- |               This program then submits a OD: AR Invoice Manage   |
-- |               Frequencies thread for each of the batches          |
-- |                                                                   |
-- | Program "OD: AR Invoice Manage Frequencies Master"                |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+

PROCEDURE SYNCH_MASTER (x_error_buff         OUT VARCHAR2
                       ,x_ret_code           OUT NUMBER
                       ,p_batch_size         IN  NUMBER
                       ,p_as_of_date         IN  VARCHAR2
                       ,p_no_workers         IN  NUMBER      -- Added for defect #6818 on 7/20/2010
                       ,p_gather_stats       IN  VARCHAR2 DEFAULT 'Y' -- Added for defect #6818 on 7/22/2010
                       )
    AS
    CURSOR lcu_cust_doc_ids(p_cycle_date DATE
                           ,p_org_id NUMBER
                           ,p_attr_group_id NUMBER
                           )
    IS
    SELECT cust_account_id
          ,extension_id
          ,c_ext_attr2
          ,n_ext_attr2
          ,n_ext_attr1
          ,c_ext_attr14
          ,c_ext_attr3
          ,c_ext_attr4
          ,c_ext_attr7
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,c_ext_attr13
          ,d_ext_attr1
          ,d_ext_attr2
          ,p_org_id
          ,DECODE( n_ext_attr15
                  ,NULL,cust_account_id
                  ,xx_ar_ebl_cons_invoices.get_cust_id(n_ext_attr15,p_attr_group_id)
                  )                             parent_cust_acct_id    -- Added this column for R1.4 CR# 586 eBilling.
          ,n_ext_attr15                         parent_cust_doc_id     -- Added this column for R1.4 CR# 586 eBilling.
          ,c_ext_attr15                         mail_to_attention      -- Added this column for R1.4 CR# 586 eBilling.
    FROM   xx_cdh_cust_acct_ext_b
    WHERE  p_cycle_date                                            >= d_ext_attr1
    AND    (d_ext_attr2                                             IS NULL
            OR
            p_cycle_date                                           <= d_ext_attr2)
    AND    xx_ar_inv_freq_pkg.compute_effective_date(c_ext_attr14
                                                    ,p_cycle_date) = p_cycle_date
    AND    c_ext_attr1                                             = 'Invoice'
    AND    c_ext_attr16                                            = 'COMPLETE'  -- Added this condition for R1.4 CR# 586 eBilling.
    AND    attr_group_id                                           = p_attr_group_id
--    and    cust_account_id     = 307405 -- Added for TESTING 
    ;

   CURSOR lcu_child_requests (p_parent_request_id  NUMBER)
   IS
   SELECT request_id,parent_request_id,status_code
   FROM   fnd_concurrent_requests
   WHERE parent_request_id = p_parent_request_id;

    ln_attr_group_id                 ego_attr_groups_v.attr_group_id%TYPE;
    TYPE lt_cust_doc_id    IS TABLE OF xx_ar_inv_freq_master%ROWTYPE;
    lt_cust_docs                  lt_cust_doc_id;
    ln_batch_id                      xx_ar_inv_freq_master.batch_id%TYPE;
    ln_max_term                      NUMBER := fnd_profile.value('XX_AR_MAXIMUM_PAYMENT_TERM_PERIOD');
    ln_max_trx_id                    ra_customer_trx_all.customer_trx_id%TYPE;
    ln_child_req_id                  fnd_concurrent_requests.request_id%TYPE;
    ln_translate_id                  xx_fin_translatevalues.translate_id%TYPE;
    ln_translate_value_id            xx_fin_translatevalues.translate_value_id%TYPE;
    ln_org_id                        NUMBER := fnd_profile.value('ORG_ID');
    ln_conc_prog_id                  fnd_concurrent_requests.concurrent_program_id%TYPE      := 0;
    ln_application_id                fnd_concurrent_requests.program_application_id%TYPE     := 0;
    ln_request_id                    fnd_concurrent_requests.request_id%TYPE                 := 0;
    ln_par_req_id                    fnd_concurrent_requests.parent_request_id%TYPE          := 0;
    lc_req_state                     fnd_concurrent_requests.status_code%TYPE                := NULL;
    ld_req_date                      fnd_concurrent_requests.request_date%TYPE               := NULL;
    ld_act_strt_date                 fnd_concurrent_requests.actual_start_date%TYPE          := NULL;
    ld_act_comp_date                 fnd_concurrent_requests.actual_completion_date%TYPE     := NULL;
    ln_rec_count                     NUMBER(15)                                              := 0;
    ln_insert_cnt                    xx_ar_inv_freq_master.insert_count%TYPE                 := 0;
    ln_prnt_date_failed_cnt          xx_ar_inv_freq_master.prnt_date_failed_cnt%TYPE         := 0;
    ln_combo_pay_failed_cnt          xx_ar_inv_freq_master.combo_pay_failed_cnt%TYPE         := 0;
    ln_combo_info_failed_cnt         xx_ar_inv_freq_master.combo_info_failed_cnt%TYPE        := 0;
    ln_fetch_inv_failed_cnt          xx_ar_inv_freq_master.fetch_inv_failed_cnt%TYPE         := 0;
    lc_error_location                VARCHAR2(4000)                                          := NULL;
    lc_error_debug                   VARCHAR2(4000)                                          := NULL;
    lc_request_data                  VARCHAR2(240);
    ld_as_of_date                    DATE                                                    := fnd_date.canonical_to_date(P_AS_OF_DATE);
    lc_printer                       VARCHAR2(100);
    lc_style                         VARCHAR2(100);
    ln_copies                        NUMBER;
    lb_print_options                 BOOLEAN;
    ln_parent_request_id             NUMBER;

-- Start of defect # 6818 (7/20/2010)
    CURSOR lcu_batch(p_org_id NUMBER) IS
       SELECT cust_account_id
             ,extension_id 
       FROM   XX_AR_INV_FREQ_MASTER
       WHERE  org_id = p_org_id
       ORDER BY cust_account_id;  
       
    TYPE cust_doc_rec_type IS RECORD( cust_account_id           xx_ar_inv_freq_master.cust_account_id%TYPE
                                     ,extension_id              xx_ar_inv_freq_master.extension_id%TYPE
                                    );
    TYPE cust_doc_tbl_type IS TABLE OF cust_doc_rec_type INDEX BY BINARY_INTEGER;
    lt_cust_doc_tbl_type          cust_doc_tbl_type;

    ln_total_doc                     NUMBER:=0;
    ln_batch_doc                     NUMBER;
    ln_cust_acct_id                  NUMBER;
-- End of defect # 6818 (7/20/2010)

    BEGIN
       lc_error_location := 'Getting request data';
       lc_error_debug    := NULL;
       lc_request_data:=FND_CONC_GLOBAL.request_data();

-- Added below log messages for defect # 6818 on 7/20/2010
       FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
       FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
       FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
       IF ( lc_request_data IS NULL) THEN

          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'**** Parameters ****');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'p_batch_size   :'||p_batch_size);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'p_as_of_date   :'||p_as_of_date);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'p_no_workers   :'||p_no_workers);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'p_gather_stats :'||p_gather_stats);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'**** Parameters ****');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

       -- Fetching billdocs attribute group id
          lc_error_location := 'Fetching billdocs attribute group id';
          lc_error_debug    := NULL;

          SELECT attr_group_id
          INTO ln_attr_group_id
          FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
          AND attr_group_name   = 'BILLDOCS' ;

       -- Truncating stale records
          lc_error_location := 'Deleting stale records';
          lc_error_debug    := NULL;

-- Added below log messages for defect # 6818 on 7/20/2010
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');  -- Added for Defect # 6818
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Alter and Truncate Partition XX_AR_INV_FEQ_MASTER');

          EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.XX_AR_INV_FREQ_MASTER TRUNCATE PARTITION XX_AR_INV_FREQ_MASTER_'||to_char(ln_org_id);

       -- Fetching the document level info of the valid documents of the customer for the current billing cycle and Inserting into xx_ar_inv_freq_master
          lc_error_location := 'Opening --lcu_cust_doc_ids. Fetching the document level info of the valid documents of the customer for the current billing cycle and Inserting into xx_ar_inv_freq_master';
          lc_error_debug    := NULL;

-- Added below log messages for defect # 6818 on 7/20/2010
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Open Cursor lcu_cust_doc_ids....');

          OPEN lcu_cust_doc_ids(ld_as_of_date
                                ,ln_org_id
                                ,ln_attr_group_id
                                );
          LOOP

/*             SELECT xx_ar_inv_freq_batch_s.NEXTVAL
                   INTO ln_batch_id
                   FROM DUAL;
*/  -- Commented for defect 6818 on 7/20/2010

             FETCH lcu_cust_doc_ids BULK COLLECT INTO lt_cust_docs LIMIT P_BATCH_SIZE;

                   FORALL i IN 1..lt_cust_docs.COUNT
                     -- INSERT INTO XX_AR_INV_FREQ_MASTER VALUES lt_cust_docs(i);  -- Commented for Defect #35572
					    INSERT INTO XX_AR_INV_FREQ_MASTER_GTT VALUES lt_cust_docs(i); -- Added for Defect #35572
                     ln_total_doc := ln_total_doc + lt_cust_docs.COUNT;  --Added for Defect # 6818 on 7/20/2010

/*                      UPDATE XX_AR_INV_FREQ_MASTER
                      SET BATCH_ID = ln_batch_id
                      where batch_id is null
                      AND org_id = ln_org_id;
*/  -- Commented for defect 6818 on 7/20/2010
                      EXIT WHEN lcu_cust_doc_ids%NOTFOUND;
          END LOOP;
          CLOSE lcu_cust_doc_ids;
          
          
          -- Added for Defect #35572  -- Start
		  
		    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total rows select from  XX_AR_INV_FREQ_MASTER_GTT SQL Count '||Sql%Rowcount) ;
		  
         	    ln_total_doc :=   Sql%Rowcount ; 
		  
		    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total rows select from  XX_AR_INV_FREQ_MASTER_GTT   : '||ln_total_doc);

		    INSERT INTO XX_AR_INV_FREQ_MASTER
  			(SELECT *
    				FROM XX_AR_INV_FREQ_MASTER_GTT xaifm
    				WHERE 1                 =1
    				AND billdocs_paydoc_ind = 'Y'
    				AND EXISTS
      				(SELECT /*+ LEADING(XAIFM) USE_NL(XAIFM RCT) */ 
        			1
        			-- End of R1.4 CR# 586 changes.
      				FROM ra_customer_trx_all RCT
      				WHERE RCT.complete_flag         = 'Y'
      				AND XAIFM.billdocs_paydoc_ind   = 'Y'
      				AND RCT.attribute15             = 'N'
      				AND RCT.printing_original_date IS NULL
      				AND RCT.org_id                  = ln_org_id
      				AND RCT.bill_to_customer_id     = XAIFM.cust_account_id
      				AND RCT.printing_option         = 'PRI'
     				 )
    				UNION ALL
    				SELECT *
    				FROM XX_AR_INV_FREQ_MASTER_GTT xaifm
    				WHERE 1=1
    				AND billdocs_paydoc_ind = 'N'
  			);
		  
	     FND_FILE.PUT_LINE (FND_FILE.LOG,'Filtered Total rows for Batch Process from XX_AR_INV_FREQ_MASTER_GTT to XX_AR_INV_FREQ_MASTER  SQL COUNT'||Sql%Rowcount) ;
		  
		   ln_total_doc :=   Sql%Rowcount ; 
		  
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Filtered Total rows for Batch Process from XX_AR_INV_FREQ_MASTER_GTT to XX_AR_INV_FREQ_MASTER  : '||ln_total_doc);
         
         -- Added for Defect #35572  -- End

-- Start of defect # 6818 (7/20/2010)
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Closing Cursor lcu_cust_doc_ids...');
          lc_error_location := 'Gathering table stats on XX_AR_INV_FREQ_MASTER';
          lc_error_debug    := NULL;
          IF p_gather_stats = 'Y' THEN  -- Added for 6818 on 7/22/2010
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Gathering table Stats -- > START :'||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
             DBMS_STATS.GATHER_TABLE_STATS('XXFIN','XX_AR_INV_FREQ_MASTER',CASCADE=> TRUE ,partname=> 'XX_AR_INV_FREQ_MASTER_'||to_char(ln_org_id));
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Gathering table Stats -- > END :'||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
          END IF;
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Customer Documents : '||ln_total_doc);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
-- End of defect # 6818 (7/20/2010)

       -- Submitting the "OD: AR Invoice Manage Frequencies" in batches
          lc_error_location := 'Submitting the "OD: AR Invoice Manage Frequencies" in batches';
          lc_error_debug    := NULL;
      SELECT fcpa.arguments printer,
           fcp.print_style style,
           fcpa.number_of_copies copies
      INTO lc_printer
          ,lc_style
                ,ln_copies
      FROM fnd_concurrent_requests fcp,
           fnd_conc_pp_actions fcpa
     WHERE fcp.request_id = fcpa.concurrent_request_id
       AND fcpa.action_type = 1   -- printer options
       AND fcpa.status_s_flag = 'Y'
       AND fcp.request_id = FND_GLOBAL.CONC_REQUEST_ID;

-- Start of defect # 6818 (7/20/2010)
      IF ln_total_doc > 0 THEN

         ln_batch_doc := ceil(ln_total_doc/p_no_workers);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Max No.of Customer Documents to be considered in each Batch : '||ln_batch_doc);

         FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Start -- Submitting Child programs....');

         OPEN lcu_batch(ln_org_id);
            LOOP

            FETCH lcu_batch BULK COLLECT INTO lt_cust_doc_tbl_type LIMIT ln_batch_doc;
               EXIT WHEN lt_cust_doc_tbl_type.COUNT=0;
               SELECT xx_ar_inv_freq_batch_s.NEXTVAL
               INTO ln_batch_id
               FROM DUAL;

               ln_cust_acct_id := lt_cust_doc_tbl_type(lt_cust_doc_tbl_type.last).cust_account_id;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch ID : '||ln_batch_id);

               UPDATE XX_AR_INV_FREQ_MASTER
               SET BATCH_ID = ln_batch_id
               WHERE batch_id IS NULL
               AND org_id = ln_org_id
               AND cust_account_id <= ln_cust_acct_id;

               IF SQL%ROWCOUNT > 0 THEN

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.of customer documents in this Batch : '||SQL%ROWCOUNT);

                  lb_print_options := FND_REQUEST.set_print_options
                                  ( printer         => lc_printer
                                   ,style           => lc_style
                                   ,copies          => ln_copies
                                   ,save_output     => TRUE
                                   ,print_together  => 'N'
                                   );
                 ln_child_req_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                           ,'XX_AR_INV_FREQ_PKG_SYNCH'
                                                           ,NULL
                                                           ,NULL
                                                           ,TRUE
                                                           ,ln_batch_id
                                                           ,p_as_of_date
                                                           );  

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XX_AR_INV_FREQ_PKG_SYNCH :'||ln_child_req_id);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

               END IF;
            END LOOP;
         CLOSE lcu_batch;
         COMMIT;
       -- Pausing the Master for the childs to execute
          lc_error_location := 'Pausing the Master for the childs to execute';
          lc_error_debug    := NULL;
          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED'
                                         ,request_data=>'child_processing_over');

          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'End of child programs execution...');

      ELSE

         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Childs to execute');

      END IF; 

-- End of defect # 6818 (7/20/2010)

  -- Commented for defect 6818 on 7/20/2010
/*
          FOR lr_batch_id IN (SELECT DISTINCT batch_id
                              FROM   xx_ar_inv_freq_master
                              WHERE  org_id = ln_org_id)
          LOOP

               lb_print_options := FND_REQUEST.set_print_options
                                    ( printer         => lc_printer
                                      ,style           => lc_style
                                      ,copies          => ln_copies
                                      ,save_output     => TRUE
                                      ,print_together  => 'N'
                                      );
             ln_child_req_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                           ,'XX_AR_INV_FREQ_PKG_SYNCH'
                                                           ,NULL
                                                           ,NULL
                                                           ,TRUE
                                                           ,lr_batch_id.batch_id
                                                           ,p_as_of_date
                                                           );  
             COMMIT;


          END LOOP;

       -- Pausing the Master for the childs to execute
          lc_error_location := 'Pausing the Master for the childs to execute';
          lc_error_debug    := NULL;
          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED'
                                         ,request_data=>'child_processing_over');
          COMMIT;
*/

       ELSE
       -- Master restarts for doing further processing and to log messages

       -- fetching the translate id and transalte value id for the translation "OD_AR_INVOICE_TRX_ID"
/*          lc_error_location := 'fetching the translate id and transalte value id for the translation "OD_AR_INVOICE_TRX_ID"';
          lc_error_debug    := NULL;
          BEGIN
             SELECT val.translate_id
                   ,val.translate_value_id
             INTO   ln_translate_id
                   ,ln_translate_value_id
             FROM   xx_fin_translatedefinition DEF
                   ,xx_fin_translatevalues VAL
             WHERE  DEF.translate_id = VAL.translate_id
             AND    DEF.translation_name = 'OD_AR_INVOICE_TRX_ID'
             AND    val.source_value1=ln_org_id
             AND    SYSDATE BETWEEN DEF.start_date_active AND NVL(DEF.end_date_active,sysdate+1)
             AND    SYSDATE BETWEEN VAL.start_date_active AND NVL(VAL.end_date_active,sysdate+1)
             AND    DEF.enabled_flag = 'Y'
             AND    VAL.enabled_flag = 'Y';
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_translate_id       := 0;
                ln_translate_value_id := 0;
                FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found in fetching the translate id and translate value id');
             WHEN OTHERS THEN
                ln_translate_id       := 0;
                ln_translate_value_id := 0;
                FND_FILE.PUT_LINE (FND_FILE.LOG,'when others while fetching the translate id and translate value id');
          END;

       -- Fetching the Maximum customer trx id among the transactions created 1 month before
          lc_error_location := 'Fetching the Maximum customer trx id among the transactions created 1 month before';
          lc_error_debug    := NULL;
          BEGIN
             SELECT MAX(customer_trx_id)
             INTO   ln_max_trx_id
             FROM   ra_customer_trx_all
             WHERE  creation_date BETWEEN (ld_as_of_date - (ln_max_term+1)) AND (ld_as_of_date - ln_max_term);
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 ln_max_trx_id := 0;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found while getting the maximum trx id from ra_customer_trx_all');
              WHEN OTHERS THEN
                 ln_max_trx_id := 0;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'When Others while getting the maximum trx id from ra_customer_trx_all');
          END;

       -- Updating the translate "OD_AR_INVOICE_TRX_ID" with the maximum trx id fetched before
          lc_error_location := 'Updating the translate "OD_AR_INVOICE_TRX_ID" with the maximum trx id fetched before';
          lc_error_debug    := NULL;
          IF (ln_max_trx_id IS NOT NULL) THEN
             UPDATE xx_fin_translatevalues
             SET   target_value1        = ln_max_trx_id
-- Start of changes for R1.3 defect 4761
               ,last_updated_by      = FND_GLOBAL.USER_ID
               ,last_update_date     = SYSDATE
               ,last_update_login    = FND_GLOBAL.USER_ID
 -- End of changes for R1.3 defect 4761
             WHERE translate_id         = ln_translate_id
             AND   translate_value_id   = ln_translate_value_id
             AND   source_value1        = ln_org_id;
          END IF;*/               -- Commented for R1.3 CR 738 Defect 2766
       -- Updating the ra_customer_trx_all table
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Start updation on ra_customer_trx_all -- printing_original_date is not null');

          lc_error_location := 'Updating the ra_customer_trx_all table';
          lc_error_debug    := NULL;
          UPDATE /*+ index(RCT XX_AR_CUSTOMER_TRX_N4) */ ra_customer_trx_all RCT
          SET RCT.attribute15                                       = 'P'
-- Start of changes for R1.3 defect 4761
             ,last_updated_by      = FND_GLOBAL.USER_ID
             ,last_update_date     = SYSDATE
             ,program_id           = FND_GLOBAL.CONC_PROGRAM_ID
             ,request_id           = FND_GLOBAL.CONC_REQUEST_ID
             ,last_update_login    = FND_GLOBAL.USER_ID
-- End of changes for R1.3 defect 4761
          WHERE RCT.attribute15                                     = 'N'
          AND RCT.printing_original_date IS NOT NULL AND rct.org_id = ln_org_id ;

          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
          FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'completion of updation on ra_customer_trx_all -- printing_original_date is not null');

       -- Inserting data into XX_FIN_PROGRAM_STATS
          lc_error_location := 'Inserting data into XX_FIN_PROGRAM_STATS';
          lc_error_debug    := NULL;
          BEGIN
             SELECT fcr.concurrent_program_id
                   ,fcr.program_application_id
                   ,fcr.request_id
                   ,fcr.parent_request_id
                   ,fcr.status_code
                   ,fcr.request_date
                   ,fcr.actual_start_date
                   ,fcr.actual_completion_date
             INTO   ln_conc_prog_id
                   ,ln_application_id
                   ,ln_request_id
                   ,ln_par_req_id
                   ,lc_req_state
                   ,ld_req_date
                  ,ld_act_strt_date
                   ,ld_act_comp_date
             FROM   fnd_concurrent_requests fcr
             WHERE  fcr.request_id = fnd_global.conc_request_id;

             SELECT COUNT(DISTINCT cust_account_id)
             INTO   ln_rec_count
             FROM   xx_ar_inv_freq_master
             WHERE  org_id = ln_org_id;

             INSERT INTO XX_FIN_PROGRAM_STATS(
                             program_short_name
                             ,concurrent_program_id
                             ,application_id
                             ,request_id
                             ,parent_request_id
                             ,request_submitted_time
                             ,request_start_time
                             ,request_end_time
                             ,request_status
                             ,count
                             ,total_dr
                             ,total_cr
                             ,sob
                             ,currency
                             ,attribute1
                             ,attribute2
                             ,attribute3
                             ,attribute4
                             ,attribute5
                             ,run_date
                             ,event_number
                             ,group_id
                             ,org_id
                            )
                      VALUES(
                             'XX_AR_INV_FREQ_SYNCH_MASTER'
                             ,ln_conc_prog_id
                             ,ln_application_id
                             ,ln_request_id
                             ,ln_par_req_id
                             ,ld_req_date
                             ,ld_act_strt_date
                             ,SYSDATE
                             ,'C'
                             ,ln_rec_count
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                                   );
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
          END;

       -- Logging record counts processed and failed
          lc_error_location := 'Logging record counts processed and failed';
          lc_error_debug    := NULL;
          BEGIN
             SELECT NVL(SUM(insert_count),0)
                   ,NVL(SUM(prnt_date_failed_cnt),0)
                   ,NVL(SUM(combo_pay_failed_cnt),0)
                   ,NVL(SUM(combo_info_failed_cnt),0)
                   ,NVL(SUM(fetch_inv_failed_cnt),0)
             INTO   ln_insert_cnt
                   ,ln_prnt_date_failed_cnt
                   ,ln_combo_pay_failed_cnt
                   ,ln_combo_info_failed_cnt
                   ,ln_fetch_inv_failed_cnt
             FROM   xx_ar_inv_freq_master
             WHERE  org_id = ln_org_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_insert_cnt            := 0;
                ln_prnt_date_failed_cnt  := 0;
                ln_combo_pay_failed_cnt  := 0;
                ln_combo_info_failed_cnt := 0;
                ln_fetch_inv_failed_cnt  := 0;
                FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found in fetching the processed and failed records count');
             WHEN OTHERS THEN
                ln_insert_cnt            := 0;
                ln_prnt_date_failed_cnt  := 0;
                ln_combo_pay_failed_cnt  := 0;
                ln_combo_info_failed_cnt := 0;
                ln_fetch_inv_failed_cnt  := 0;
                FND_FILE.PUT_LINE (FND_FILE.LOG,'when others while fetching the processed and failed records count');
          END;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records inserted into the Frequency table: '||ln_insert_cnt);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records not inserted into the Frequency table due to failure in deriving in ESTIMATED PRINT DATE: '||ln_prnt_date_failed_cnt);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Paydoc Records not inserted into the Frequency table due to Combo Logic: '||ln_combo_pay_failed_cnt);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Info Records not inserted into the Frequency table due to Combo Logic: '||ln_combo_info_failed_cnt);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records not inserted into the Frequency table due to failure in fetching records in c_cust_invoices: '||ln_fetch_inv_failed_cnt);

           ln_parent_request_id := FND_GLOBAL.CONC_REQUEST_ID;
           FOR lr_child_request IN lcu_child_requests(ln_parent_request_id)
            LOOP
               IF lr_child_request.status_code = 'E' THEN
                  x_ret_code := 2;
                  EXIT;
               ELSIF lr_child_request.status_code = 'G' THEN
                  x_ret_code := 1;
               END IF;
            END LOOP;
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_debug);
       ROLLBACK;
       x_ret_code := 2;

    END SYNCH_MASTER;

-- End of changes for R1.3 Defect 2766 CR 738

-- +===================================================================+
-- | Name : SYNCH                                                      |
-- | Description : This Program automatically will picks all the new   |
-- |                 invoices and inserts into the frequency table,    |
-- |                  by computing the efffective print date           |
-- |                                                                   |
-- | Program "OD: AR Invoice Manage Frequencies"                       |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+

PROCEDURE SYNCH  (x_error_buff         OUT VARCHAR2
                 ,x_ret_code           OUT NUMBER
                 ,p_batch_id           IN  NUMBER                         -- Added "p_batch_id" for R1.3 CR 738 Defect 2766
                 ,p_as_of_date         IN  VARCHAR2                       -- Added "p_as_of_date" for R1.3 CR 738 Defect 2858
                 )
    AS

-- defect 12227
   /*
      CURSOR c_inv_cust_doc (
                           p_conv_invoice_source    VARCHAR2
                          ,p_poe_order_source_id    NUMBER
                          ,p_hed_order_source_id    NUMBER
                          ,p_org_id                 NUMBER)IS
    (
        SELECT
                XCCAE.extension_id
               ,XCCAE.billdocs_doc_id
               ,XCCAE.billdocs_cust_doc_id
               ,XCCAE.billdocs_delivery_meth
               ,XCCAE.billdocs_paydoc_ind
               ,XCCAE.billdocs_combo_type
               ,RCT.customer_trx_id
               ,RCT.creation_date
               ,RCT.trx_number
               ,XCCAE.cust_account_id                  --Added for traceability
               ,XCCAE.billdocs_special_handling        --Added for traceability
               ,XCCAE.billdocs_payment_term            --Added for traceability
               ,ARM.payment_type_code
        FROM
               ra_customer_trx_all RCT
               ,ra_batch_sources_all RBS
               ,xx_cdh_a_ext_billdocs_v XCCAE
               ,oe_order_headers_all OOH
               , ar_receipt_methods  ARM
        WHERE
               RCT.bill_to_customer_id = XCCAE.cust_account_id
               AND XCCAE.billdocs_doc_type = 'Invoice'
               AND RBS.batch_source_id = RCT.batch_source_id
               AND RCT.receipt_method_id = ARM.receipt_method_id(+)
               AND OOH.header_id(+) = DECODE(RCT.attribute_category, 'SALES_ACCT',RCT.attribute14, NULL)
               AND RBS.name <> p_conv_invoice_source
               AND RCT.complete_flag = 'Y'
               AND RCT.attribute15 IS NULL
               AND RCT.org_id = p_org_id
               AND OOH.order_source_id(+) != p_poe_order_source_id  -- Excluding the POS Orders(Non SPC)
               AND OOH.order_source_id(+) != p_hed_order_source_id  -- Excluding the HED Orders
    );
*/
-- Below cursor commented for R1.3 Defect 2766 CR 738
/*-- start defect 12227
    CURSOR c_inv_cust_doc (
                          p_attr_group_id           NUMBER
                         ,p_org_id                  NUMBER
                         ,p_trx_id                  NUMBER  -- Added for Defect # 4046
                         )IS
    (
    -- SELECT /*+ use_nl(XCCAE RCT) index(RCT XX_AR_CUSTOMER_TRX_N4) index(XCCAE XX_CDH_CUST_ACCT_EXT_B_N1)*/
--     SELECT /*+ ordered use_hash(XCCAE) index(RCT XX_AR_CUSTOMER_TRX_N4)*/ -- added for defect 2742
/*         XCCAE.extension_id
        ,XCCAE.n_ext_attr1       billdocs_doc_id
        ,XCCAE.n_ext_attr2       billdocs_cust_doc_id
        ,XCCAE.c_ext_attr3       billdocs_delivery_meth
        ,XCCAE.c_ext_attr2       billdocs_paydoc_ind
        ,XCCAE.c_ext_attr13      billdocs_combo_type
        ,RCT.customer_trx_id
--        ,RCT.creation_date       creation_date --  defect 13172 , reverted back this change.     -- Commented for R1.2 Defect 4095
        ,DECODE(gc_comp_effec_date
               ,'TRX_DATE',RCT.trx_date
               ,RCT.creation_date
               ) creation_date         -- Added for R1.2 Defect 4095
      -- ,rct.trx_date         creation_date --  defect 13172 , need to revert back this change. Commented on 06/18/09
        ,RCT.trx_number
        ,XCCAE.cust_account_id
        ,XCCAE.c_ext_attr14      billdocs_payment_term
        ,XCCAE.c_ext_attr4       billdocs_special_handling
        ,ARM.payment_type_code
        ,XCCAE.c_ext_attr7       direct_flag     -- For fetching direct/indirect flag, Added for Defect 12710
        ,RCT.attribute14         header_id       --Added for Defect# 1451 CR 626
    FROM ra_customer_trx_all           RCT
        ,ar_receipt_methods            ARM
        ,xx_cdh_cust_acct_ext_b  XCCAE
   WHERE 1=1
   AND RCT.complete_flag       = 'Y'
   AND RCT.attribute15         = 'N'
   AND RCT.org_id              = p_org_id
   AND RCT.customer_trx_id     > p_trx_id   -- Added for Defect # 4046
   AND RCT.bill_to_customer_id = XCCAE.cust_account_id
   AND XCCAE.attr_group_id     = p_attr_group_id
   AND XCCAE.c_ext_attr1       = 'Invoice'
   AND RCT.receipt_method_id   = ARM.receipt_method_id(+)
   AND RCT.printing_option     = 'PRI'
   AND RCT.printing_original_date IS NULL
-- Added the below condition for Defect# 631 (CR#662)
   AND NOT EXISTS (SELECT  1
                   FROM    fnd_lookup_values_vl  FLV
                   WHERE   FLV.lookup_type    = 'OD_BILLING_EXCLUDE_CUSTOMERS'
                   AND     FLV.enabled_flag   = 'Y'
                   AND     trunc(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
                   AND     FLV.meaning        = XCCAE.cust_account_id
                   )
   ) ;
-- end of defect 12227*/

-- Below cursor added for R1.3 Defect 2766 CR 738
    CURSOR c_inv_cust_doc (
                           p_org_id                  NUMBER
--                          ,p_trx_id                  NUMBER  -- Added for Defect # 4046   -- Commented for R1.3 CR 738 Defect 2766
                          ,p_attr_group_id           NUMBER
                          ,p_as_of_date              DATE
                          )IS
    (
     SELECT /*+ LEADING(XAIFM) USE_NL(XAIFM RCT) */ 
            XAIFM.extension_id
           ,XAIFM.billdocs_doc_id
           ,XAIFM.billdocs_cust_doc_id
           ,XAIFM.billdocs_delivery_meth
           ,XAIFM.billdocs_paydoc_ind
           ,XAIFM.billdocs_combo_type
           ,RCT.customer_trx_id
           ,RCT.trx_number
		   ,NVL(RCT.BILLING_DATE,TRX_DATE) BILLING_DATE						-- Added for NAIT-80765
           ,XAIFM.cust_account_id
           ,XAIFM.billdocs_payment_term
           ,XAIFM.billdocs_special_handling
           ,ARM.payment_type_code
           ,XAIFM.direct_flag
           ,RCT.attribute14         header_id
           -- Added the below three columns for eBilling R1.4 CR# 586.
           ,XAIFM.parent_cust_acct_id
           ,XAIFM.parent_cust_doc_id
           ,XAIFM.mail_to_attention
           -- End of R1.4 CR# 586 changes.
     FROM   ra_customer_trx_all                 RCT
           ,ar_receipt_methods                  ARM
           ,xx_ar_inv_freq_master               XAIFM
     WHERE  RCT.complete_flag       = 'Y'
     AND    XAIFM.batch_id          = p_batch_id
     AND    XAIFM.org_id            = p_org_id
     AND    XAIFM.billdocs_paydoc_ind = 'Y'
     AND    RCT.attribute15 = 'N'
     AND    RCT.printing_original_date IS NULL
     AND    RCT.org_id              = p_org_id
  --   AND    RCT.customer_trx_id     > p_trx_id               -- Commented for R1.3 CR 738 Defect 2766
     AND    RCT.bill_to_customer_id = XAIFM.cust_account_id
     AND    RCT.receipt_method_id   = ARM.receipt_method_id(+)
     AND    RCT.printing_option     = 'PRI'
     AND   NOT EXISTS (SELECT  1
                       FROM    fnd_lookup_values_vl  FLV
                       WHERE   FLV.lookup_type    = 'OD_BILLING_EXCLUDE_CUSTOMERS'
                       AND     FLV.enabled_flag   = 'Y'
                       AND     trunc(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
                       AND     FLV.meaning        = XAIFM.cust_account_id
                       )
    UNION ALL
    SELECT XAIFM.extension_id
           ,XAIFM.billdocs_doc_id
           ,XAIFM.billdocs_cust_doc_id
           ,XAIFM.billdocs_delivery_meth
           ,XAIFM.billdocs_paydoc_ind
           ,XAIFM.billdocs_combo_type
           ,RCT.customer_trx_id
           ,RCT.trx_number
		   ,NVL(RCT.BILLING_DATE,TRX_DATE) BILLING_DATE						-- Added for NAIT-80765
           ,XAIFM.cust_account_id
           ,XAIFM.billdocs_payment_term
           ,XAIFM.billdocs_special_handling
           ,ARM.payment_type_code
           ,XAIFM.direct_flag
           ,RCT.attribute14         header_id
           -- Added the below three columns for eBilling R1.4 CR# 586.
           ,XAIFM.parent_cust_acct_id
           ,XAIFM.parent_cust_doc_id
           ,XAIFM.mail_to_attention
           -- End of R1.4 CR# 586 changes.
     FROM   ra_customer_trx_all                 RCT
           ,ar_receipt_methods                  ARM
           ,xx_ar_inv_freq_master               XAIFM
     WHERE  RCT.complete_flag       = 'Y'
     AND    XAIFM.batch_id          = p_batch_id
     AND    XAIFM.org_id            = p_org_id
     AND   XAIFM.billdocs_paydoc_ind = 'N'
     AND xx_ar_inv_freq_pkg.xx_ar_infocopy_handling (RCT.customer_trx_id
                                                     ,XAIFM.billdocs_cust_doc_id
                                                     ,RCT.bill_to_customer_id
                                                     ,XAIFM.billdocs_eff_start_date
                                                     ,XAIFM.billdocs_payment_term
                                                     ,p_attr_group_id
                                                     ,p_as_of_date
                                                     ,RCT.attribute15  -- Added for Defect 6375
                                                     ) = 'Y'

     AND    RCT.org_id              = p_org_id
   --  AND    RCT.customer_trx_id     > p_trx_id                  -- Commented for R1.3 CR 738 Defect 2766
     AND    RCT.bill_to_customer_id = XAIFM.cust_account_id
     AND    RCT.receipt_method_id   = ARM.receipt_method_id(+)
     AND    RCT.printing_option     = 'PRI'
     AND   NOT EXISTS (SELECT  1
                       FROM    fnd_lookup_values_vl  FLV
                       WHERE   FLV.lookup_type    = 'OD_BILLING_EXCLUDE_CUSTOMERS'
                       AND     FLV.enabled_flag   = 'Y'
                       AND     trunc(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
                       AND     FLV.meaning        = XAIFM.cust_account_id
                       )

    ) ;
-- end of changes for R1.3 CR 738 Defect 2766

/* Start of Changes for Defect 12710 */

    CURSOR c_cust_invoices (
                            p_customer_trx_id   IN NUMBER) IS
    ( SELECT RCT.bill_to_site_use_id
            ,RCT.ship_to_site_use_id
            ,HCSU.cust_acct_site_id
            ,RCTT.type inv_type           -- Added for Defect # 1820
            ,RCT.attribute14 header_id     -- Added for Defect # 1820
      FROM   ra_customer_trx_all    RCT
            ,ra_cust_trx_types       RCTT
            ,ar_lookups              AL
            ,hz_cust_site_uses_all   HCSU
      WHERE  RCT.customer_trx_id             = p_customer_trx_id
      AND    RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
      AND    RCT.ship_to_site_use_id         = HCSU.site_use_id
      AND    AL.lookup_code                  = DECODE ( RCTT.type , 'DEP' , 'INV' , RCTT.type )
      AND    AL.lookup_type                  ='INV/CM/ADJ');


/* End of Changes for the Defect 12710 */

    ld_estimated_print_date         DATE;
    ln_user_id                      NUMBER := FND_PROFILE.VALUE('USER_ID');
    ln_login_id                     NUMBER := FND_PROFILE.VALUE('LOGIN_ID');
    ln_org_id                       NUMBER := FND_PROFILE.VALUE('ORG_ID');
    ln_insert_count                 NUMBER := 0;   --To track the no: of invoices inserted into the frequency table
    ln_not_insert_count_pr_date     NUMBER := 0;   --To track the no: of invoices not inserted into the frequency table
   -- ln_not_insert_count_combo       NUMBER := 0;   --To track the no: of invoices not inserted into the frequency table  -- Commented for Defect 13337
    ln_not_fetch_invoice_count      NUMBER := 0;   --To track the no: of invoices not inserted into the frequency table  --Added for the defect 12227
    ln_poe_order_source_id          oe_order_sources.order_source_id%TYPE;
    ln_hed_order_source_id          oe_order_sources.order_source_id%TYPE;
    lc_conversion_invoice_src       ra_batch_sources_all.name%TYPE := NULL;
    lc_pos_order_src                oe_order_sources.name%TYPE := NULL;
    lc_hed_order_src                oe_order_sources.name%TYPE := NULL;
    lc_error_location               VARCHAR2(4000) := NULL;
    lc_error_debug                  VARCHAR2(4000) := NULL;
    lc_combo_type                   xx_cdh_a_ext_billdocs_v.billdocs_combo_type%TYPE;
    lc_payment_code                 ar_receipt_methods.payment_type_code%TYPE;
    ln_amount_due_remaining         ar_payment_schedules_all.amount_due_remaining%TYPE;           -- Added for Defect# 8612
    ln_amount_due_original          ar_payment_schedules_all.amount_due_original%TYPE;
    lc_eff_print_date_err           VARCHAR2(1) := 'N';
    ln_attr_group_id                NUMBER;                  -- Added for Defect 12227
    ln_attr_group_id_site           NUMBER;
    lc_process_record               VARCHAR2(1) := 'N';
    ln_site_use_id                  NUMBER ;
    lc_inv_processed                VARCHAR2(1):= 'N' ;
    lc_cust_invoices                c_cust_invoices%ROWTYPE;
    ln_not_insert_count_combo_pay   NUMBER := 0;   --To track the no: of Paydoc invoices not inserted into the frequency table (13337)
    ln_not_insert_count_combo_info  NUMBER := 0;   --To track the no: of Infodoc invoices not inserted into the frequency table(13337)
    --End of Changes for defect 12710
	l_bypass_trx            		BOOLEAN:= FALSE;		--Added for NAIT-80765
	lc_bill_comp_flag				VARCHAR2(1):= 'N' ;     --Added for NAIT-80765
    lc_mail_to_attention            xx_cdh_cust_acct_ext_b.c_ext_attr15%TYPE   := NULL; -- Added for R1.4 CR# 586 eBilling.
    ld_due_date                     ar_payment_schedules.due_date%TYPE;                 -- Added for R1.4 CR# 586 eBilling.

    --Start of Changes for defect 12227
-- Comented for R1.3 CR 738 Defect 2766
/*     ln_rec_count                   NUMBER := 0;
     ln_conc_prog_id                fnd_concurrent_requests.concurrent_program_id%TYPE      := 0;
     ln_application_id              fnd_concurrent_requests.program_application_id%TYPE     := 0;
     ln_request_id                  fnd_concurrent_requests.request_id%TYPE                 := 0;
     ln_par_req_id                  fnd_concurrent_requests.parent_request_id%TYPE          := 0;
     lc_req_state                   fnd_concurrent_requests.status_code%TYPE                := NULL;
     ld_req_date                    fnd_concurrent_requests.request_date%TYPE               := NULL;
     ld_act_strt_date               fnd_concurrent_requests.actual_start_date%TYPE          := NULL;
     ld_act_comp_date               fnd_concurrent_requests.actual_completion_date%TYPE     := NULL;*/
    --End of Changes for defect 12227
-- End of changes for R1.3 CR 738 Defect 2766

     ln_write_off_amt_low  NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW');   --Added for the Defect# 631 (CR 662)
     ln_write_off_amt_high NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH');  --Added for the Defect# 631 (CR 662)

     -- Commented for Defect# 1451 CR 626.
     --lc_gc_payment_code     VARCHAR2(5) := FND_PROFILE.VALUE('OD_BILLING_GIFTCARD_PAYMENT_TYPE');  --Added for the Defect# 1820
     ln_no_gift_card        NUMBER := 2;  -- Added for the Defect # 1820

     -- Start for defect # 4046

--        ln_max_trx_id          NUMBER;                -- Commented for R1.3 CR 738 Defect 2766
        ln_trx_id              NUMBER;
--        ln_translate_id        XX_FIN_TRANSLATEVALUES.translate_id%TYPE;          -- Commented for R1.3 CR 738 Defect 2766
--        ln_translate_value_id  XX_FIN_TRANSLATEVALUES.translate_value_id%TYPE;     -- Commented for R1.3 CR 738 Defect 2766
     ld_as_of_date         DATE    := fnd_date.canonical_to_date(P_AS_OF_DATE);     -- Added for R1.3 CR 738 Defect 2766
     -- End for defect # 4046

    BEGIN

        lc_error_location := 'Getting the translation Values for the Conversion Invoices, HED and POS(Non-SPC)';
        lc_error_debug    := NULL;

/* -- COMMETED FOR DEFECT 12227, DEFAULTING OF ATTRIBUTE15 TO 'P' IS DONE IN E0080, HENCE BELOW CODE IS NOT REQUIRED

        SELECT XFTV.source_value1, XFTV.source_value2, XFTV.source_value3
        INTO   lc_conversion_invoice_src, lc_pos_order_src, lc_hed_order_src
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'OD_AR_BILLING_SOURCE_EXCL'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_error_location := 'Getting the Source ID for the POS(Non-SPC) Order';
        lc_error_debug    := 'POS(Non-SPC) Order Source: '||lc_pos_order_src;

        SELECT order_source_id
        INTO   ln_poe_order_source_id
        FROM   oe_order_sources
        WHERE  name = lc_pos_order_src;

        lc_error_location := 'Getting the Source ID for the HED Order';
        lc_error_debug    := 'HED Order Source: '||lc_hed_order_src;

        SELECT order_source_id
        INTO   ln_hed_order_source_id
        FROM   oe_order_sources
        WHERE  name = lc_hed_order_src;
        */
        FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_LOW_VALUE: '||ln_write_off_amt_low);   --Added for the Defect# 631 (CR 662)
        FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_HIGH_VALUE: '||ln_write_off_amt_high); --Added for the Defect# 631 (CR 662)

        -- Commented for Defect# 1451 CR 626.
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'PROFILE: OD_BILLING_GIFTCARD_PAYMENT_TYPE: '||lc_gc_payment_code); --Added for the Defect# 1820

        -- DEFECT 12227 START
        SELECT attr_group_id
          INTO ln_attr_group_id
          FROM ego_attr_groups_v
         WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
           AND attr_group_name = 'BILLDOCS' ;

        SELECT attr_group_id
          INTO ln_attr_group_id_site
          FROM ego_attr_groups_v
         WHERE attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
           AND attr_group_name = 'BILLDOCS';

/*        FND_FILE.PUT_LINE(FND_FILE.LOG,'CDH Entensible Attributes - XX_CDH_CUST_ACCOUNT : '||ln_attr_group_id
                                        ||' ,  XX_CDH_CUST_ACCT_SITE : '||ln_attr_group_id_site);*/                   -- Commented for R1.3 CR 738 Defect 2766

        FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_CDH_CUST_ACCT_SITE : '||ln_attr_group_id_site);       -- Added for R1.3 CR 738 Defect 2766

        -- END 12227

        -- Start for defect # 4046

    FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

-- Commented the below block for R1.3 CR 738 Defect 2766

/*      BEGIN
              SELECT max(customer_trx_id)
              INTO   ln_max_trx_id
              FROM   ra_customer_trx_all;

      EXCEPTION
           WHEN NO_DATA_FOUND THEN

           ln_max_trx_id := 0;
           FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found while getting the maximum trx id from ra_customer_trx_all');
           WHEN OTHERS THEN

           ln_max_trx_id := 0;
           FND_FILE.PUT_LINE (FND_FILE.LOG,'When others while getting the maximum trx id from ra_customer_trx_all');
      END;*/

-- End of changes for R1.3 Defect 2766 CR 738

/*      BEGIN
              SELECT val.target_value1
--                    ,val.translate_id                     -- Commented for R1.3 CR 738 Defect 2766
--                    ,val.translate_value_id               -- Commented for R1.3 CR 738 Defect 2766
              INTO   ln_trx_id
--                    ,ln_translate_id                      -- Commented for R1.3 CR 738 Defect 2766
--                    ,ln_translate_value_id                -- Commented for R1.3 CR 738 Defect 2766
              FROM   xx_fin_translatedefinition DEF
                    ,xx_fin_translatevalues VAL
              WHERE  DEF.translate_id = VAL.translate_id
              AND    DEF.translation_name = 'OD_AR_INVOICE_TRX_ID'
              AND    val.source_value1=ln_org_id
              AND    SYSDATE BETWEEN DEF.start_date_active AND NVL(DEF.end_date_active,sysdate+1)
              AND    SYSDATE BETWEEN VAL.start_date_active AND NVL(VAL.end_date_active,sysdate+1)
              AND    DEF.enabled_flag = 'Y'
              AND    VAL.enabled_flag = 'Y';
      EXCEPTION
           WHEN NO_DATA_FOUND THEN

           ln_trx_id := 0;
           FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found for the maximum trx id : '||ln_trx_id);
           WHEN OTHERS THEN

           ln_trx_id := 0;
           FND_FILE.PUT_LINE (FND_FILE.LOG,'When Others for the maximum trx id : '||ln_trx_id);
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG,'Org ID :' ||ln_org_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Previous Maximum customer_trx_id from ra_customer_trx_all :' ||ln_trx_id);
--      FND_FILE.PUT_LINE (FND_FILE.LOG,'Current Maximum customer_trx_id from ra_customer_trx_all :'  ||ln_max_trx_id);*/  -- Commented for R1.3 CR 738 Defect 2766

        -- End for defect # 4046

        lc_error_location := 'Opening the Cursor';
        lc_error_debug    := '';

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Conversion Invoice Source: '||lc_conversion_invoice_src);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Hedberg Order Source ID: '||ln_poe_order_source_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'POE Order Source ID: '||ln_hed_order_source_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG ID: '||ln_org_id);

        -- Start for Defect # 4046

        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Opening the Cursor  -- c_inv_cust_doc');

        -- End for Defect # 4046

--        FOR lcu_inv_cust_doc IN c_inv_cust_doc(ln_attr_group_id, ln_org_id, ln_trx_id)  -- Added ln_trx_id for defect # 4046   -- Commented for R1.3 CR 738 Defect 2766
        FOR lcu_inv_cust_doc IN c_inv_cust_doc(ln_org_id, ln_attr_group_id,ld_as_of_date)              -- Added for R1.3 CR 738 Defect 2766
        LOOP

		--- *** Start for Bill Complete Change NAIT-80765 *** ---
			--- Skip the process, to exclude creation of docs if billing date for transaction is in future i.e if no consolidated bills got generated already
		    l_bypass_trx    		 := FALSE;
		    lc_bill_comp_flag	 	 := 'N';
			BEGIN
				SELECT 'Y'
				INTO lc_bill_comp_flag
				FROM oe_order_headers_all ooh,
					 xx_om_header_attributes_all xoha
				WHERE ooh.order_number       = TO_NUMBER(lcu_inv_cust_doc.trx_number)
				AND ooh.header_id            = xoha.header_id
				AND NVL(bill_comp_flag,'N') IN ('B','Y')
				AND ROWNUM <2;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
				lc_bill_comp_flag	:='N';
			WHEN OTHERS THEN
				lc_bill_comp_flag	:='N';
				FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception in finding Bill Complete Customer : '||SQLERRM);
			END;
			
			IF lc_bill_comp_flag ='Y' AND lcu_inv_cust_doc.billing_date > ld_as_of_date
			THEN
				l_bypass_trx	:=	TRUE;
			END IF;
			
			IF NOT l_bypass_trx THEN
			/* --- *** End for Bill Complete Change NAIT-80765 *** --- */ 
           lc_eff_print_date_err := 'N';
           lc_combo_type   := lcu_inv_cust_doc.billdocs_combo_type;
           lc_payment_code := lcu_inv_cust_doc.payment_type_code;

--           ln_rec_count := c_inv_cust_doc%ROWCOUNT;                 --Added for the defect 12227     -- Commented for R1.3 CR 738 Defect 2766
            /*Start of Changes for the defect 12710 */
           lc_process_record            := 'N';
           ln_site_use_id               := NULL ;
           lc_inv_processed             := 'N';
           ln_no_gift_card              := 2;   -- Added for Defect # 1820
           
           lc_mail_to_attention         := NULL; -- Added for R1.4 CR# 586 eBilling.
                   -- Below update block added for defect 5901 
                  IF lcu_inv_cust_doc.billdocs_paydoc_ind = 'Y' THEN
                       UPDATE  ar_payment_schedules_all arps
                       SET     arps.exclude_from_cons_bill_flag = 'Y'
                         -- Start of changes for R1.3 defect 4761
                              ,last_updated_by      = FND_GLOBAL.USER_ID
                              ,last_update_date     = SYSDATE
                              ,program_id           = FND_GLOBAL.CONC_PROGRAM_ID
                              ,request_id           = FND_GLOBAL.CONC_REQUEST_ID
                              ,last_update_login    = FND_GLOBAL.USER_ID
                        -- End of changes for R1.3 defect 4761
                       WHERE   1 = 1
                       AND arps.customer_trx_id =lcu_inv_cust_doc.customer_trx_id  ;
                  END IF;
         -- End of changes for defect 5901
           OPEN c_cust_invoices(lcu_inv_cust_doc.customer_trx_id) ;
           FETCH c_cust_invoices INTO lc_cust_invoices;

              IF (c_cust_invoices%FOUND) THEN
                 lc_inv_processed := 'Y' ;

                   -- Start for Defect # 1820
                   IF lc_cust_invoices.inv_type = 'INV' THEN
                    /*BEGIN                                       -- Commented for the R1.1 Defect # 1451 (CR 626)
                        SELECT  1
                        INTO    ln_no_gift_card
                        FROM    oe_payments OP
                        WHERE   OP.header_id = lc_cust_invoices.header_id
                        AND     OP.attribute11 <> lc_gc_payment_code
                        AND     ROWNUM=1;
                      EXCEPTION
                        WHEN OTHERS THEN
                          ln_no_gift_card := 2;
                      END;*/
                      lc_inv_processed := xx_ar_inv_freq_pkg.gift_card_inv( lcu_inv_cust_doc.customer_trx_id
                                                                           ,lcu_inv_cust_doc.header_id);        -- Added for the R1.1 Defect # 1451 (CR 626)
                    ELSE
                    /*BEGIN                                       -- Commented for the R1.1 Defect # 1451 (CR 626)
                        SELECT  1
                        INTO    ln_no_gift_card
                        FROM    xx_om_return_tenders_All ORT
                        WHERE   ORT.header_id = lc_cust_invoices.header_id
                        AND     ORT.od_payment_type <> lc_gc_payment_code
                        AND     ROWNUM=1;
                      EXCEPTION
                        WHEN OTHERS THEN
                          ln_no_gift_card := 2;
                      END;*/
                      lc_inv_processed := xx_ar_inv_freq_pkg.gift_card_cm(lcu_inv_cust_doc.customer_trx_id
                                                                         ,lcu_inv_cust_doc.header_id);   -- Added for the R1.1 Defect # 1451 (CR 626)
                    END IF;

                    /*IF ln_no_gift_card = 1 THEN   */       -- Commented for the R1.1 Defect # 1451 (CR 626)
                      IF lc_inv_processed = 'N' THEN
                         UPDATE ra_customer_trx_all RCT               -- Added as a part of the defect # 1375
                         SET    RCT.attribute15 = 'Y'
       -- Start of changes for R1.3 defect 4761
                              ,last_updated_by      = FND_GLOBAL.USER_ID
                              ,last_update_date     = SYSDATE
                              ,program_id           = FND_GLOBAL.CONC_PROGRAM_ID
                              ,request_id           = FND_GLOBAL.CONC_REQUEST_ID
                              ,last_update_login    = FND_GLOBAL.USER_ID
    -- End of changes for R1.3 defect 4761
                         WHERE  RCT.customer_trx_id =lcu_inv_cust_doc.customer_trx_id;
                      END IF;

                   -- End for Defect # 1820

              ELSE
                 lc_inv_processed := 'N' ;
                 ln_not_fetch_invoice_count := ln_not_fetch_invoice_count + 1;     --Added for the defect 12227
              END IF;

           CLOSE c_cust_invoices;
            /* End of Changes for Defect 12710 */

           IF (lc_inv_processed = 'Y') THEN

                      /* Added for Defect# 8612 */
              BEGIN
                 SELECT   NVL(SUM(amount_due_remaining),0)
                         ,NVL(SUM(amount_due_original),0)
                         ,due_date                             -- Added the column as part of R1.4 CR#586 eBilling.
                 INTO     ln_amount_due_remaining
                         ,ln_amount_due_original
                         ,ld_due_date                          -- Added the column as part of R1.4 CR#586 eBilling.
                 FROM     ar_payment_schedules_all
                 WHERE    customer_trx_id = lcu_inv_cust_doc.customer_trx_id
                 GROUP BY customer_trx_id
                          ,due_date;                           -- Added the column as part of R1.4 CR#586 eBilling.
                 EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                    ln_amount_due_remaining := 0;
                    ln_amount_due_original  := 0;
                    ld_due_date             := NULL;           -- Added the column as part of R1.4 CR#586 eBilling.
                 WHEN OTHERS THEN
                    ln_amount_due_remaining := 0;
                    ln_amount_due_original  := 0;
                    ld_due_date             := NULL;           -- Added the column as part of R1.4 CR#586 eBilling.

              END;
           /* Ended for Defect# 8612 */

           /*Added for Defect 12710 */
              IF (lcu_inv_cust_doc.billdocs_paydoc_ind = 'N' AND
                 lcu_inv_cust_doc.billdocs_delivery_meth <> 'EDI') THEN

                 BEGIN

                    SELECT  HCSU.site_use_id
                           ,XCASE.c_ext_attr3     -- Added this column as part of R1.4 CR# 586.
                    INTO    ln_site_use_id
                           ,lc_mail_to_attention   -- Added this column as part of R1.4 CR# 586.
                    FROM    xx_cdh_acct_site_ext_b  XCASE
                           ,hz_cust_site_uses_all  HCSU
                           ,hz_cust_acct_sites_all  HCAS
                    WHERE   XCASE.cust_acct_site_id = lc_cust_invoices.cust_acct_site_id
                    AND     XCASE.n_ext_attr1       = lcu_inv_cust_doc.billdocs_cust_doc_id
                    AND     HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
                    AND     XCASE.c_ext_attr5       = HCAS.orig_system_reference
                    AND     XCASE.attr_group_id     = ln_attr_group_id_site
                    AND     HCSU.site_use_code      = 'SHIP_TO'
                    AND     XCASE.c_ext_attr20      = 'Y';                      -- Added for R1.3 CR 738 Defect 2766

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Account Site use Id for Infodoc Exception Address: '
                                      ||ln_site_use_id||'Trx Number'||lcu_inv_cust_doc.trx_number);

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN

                     IF (lcu_inv_cust_doc.direct_flag = 'Y') THEN

                        SELECT  HCSU.site_use_id
                        INTO    ln_site_use_id
                        FROM    hz_cust_acct_sites HCAS
                               ,hz_cust_site_uses  HCSU
                        WHERE HCAS.cust_account_id = lcu_inv_cust_doc.cust_account_id
                        AND   HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
                        AND   HCSU.site_use_code   = 'BILL_TO'
                        AND   primary_flag         = 'Y';


                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Account Site use Id for Infodoc- Direct '
                                       ||ln_site_use_id||'Trx Number '||lcu_inv_cust_doc.trx_number);

                     ELSE

                        ln_site_use_id  := lc_cust_invoices.ship_to_site_use_id ;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Account Site use Id for Infodoc- Indirect '
                                       ||ln_site_use_id||'Trx Number '||lcu_inv_cust_doc.trx_number);

                     END IF;

                 END;

              ELSIF (lcu_inv_cust_doc.billdocs_paydoc_ind = 'Y'
                     AND lcu_inv_cust_doc.billdocs_delivery_meth <> 'EDI') THEN

                 ln_site_use_id  := lc_cust_invoices.bill_to_site_use_id ;

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'cust Acct site use id for paydoc:  '
                                   ||ln_site_use_id||' trx_number'||lcu_inv_cust_doc.trx_number);

              END IF;

              /*End of Changes for Defect 12710 */

              -- IF ln_amount_due_remaining != 0 THEN    /* Added IF condition for Defect# 8612 */  -- Commented for Defect 12710

              -- Commented for Defect 13337

             /* IF (lcu_inv_cust_doc.billdocs_delivery_meth = 'EDI' AND ln_amount_due_remaining != 0)  THEN  -- Added for Defect 12710
              -- Start of Combo Logic Added by Ranjith
              --Fix for the Defect# 10103
                 IF( (lc_combo_type = 'CR'
                    AND ln_amount_due_original < 0
                    AND NVL(lc_payment_code,'X') <> 'CREDIT_CARD')
                    OR
                    (lc_combo_type = 'DB'                   -- Scenario for Combo type DB
                    AND ln_amount_due_original>= 0
                    AND NVL(lc_payment_code,'X') <> 'CREDIT_CARD')
                    OR
                    (lc_combo_type = 'CC'                   -- Scenario for Combo type CC
                     AND ln_amount_due_original< 0  )
                    OR
                    (lc_combo_type = 'DC'                   -- Scenario for Combo type DC
                    AND ln_amount_due_original>= 0  )
                    OR
                    (lc_combo_type IS NULL                  -- Scenario if Combo type is NULL
                    AND NVL(lc_payment_code,'X') <> 'CREDIT_CARD'))
                 THEN                                              -- End of combo Logic
                    lc_process_record :='Y' ;           -- Added for Defect 12710
                 ELSE
                    ln_not_insert_count_combo := ln_not_insert_count_combo + 1;   -- Added for defect 12710

                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice Number: '||lcu_inv_cust_doc.trx_number||
                                      '; Invoice Amount: '||ln_amount_due_original||' ; Combo Type: '
                                      ||lc_combo_type||' ; Payment Code: '||lc_payment_code);
                   FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                 END IF;
              ELSE
                lc_process_record :='Y' ;              --Added for defect 12710...........
              END IF; */

                -- Start of Changes for Defect 13337
              IF (lcu_inv_cust_doc.billdocs_paydoc_ind = 'Y' ) THEN
                 IF (lc_combo_type IS NULL AND lcu_inv_cust_doc.billdocs_delivery_meth IN ('PRINT','EDI','ePDF','eXLS','eTXT')) THEN -- Added 'ePDF' as part of R1.4 CR# 586 eBilling.
                     lc_process_record := 'Y';
                 ELSIF (lc_combo_type IN ( 'CR','DB')) THEN
                    IF (lcu_inv_cust_doc.billdocs_delivery_meth = 'PRINT' OR
                        lcu_inv_cust_doc.billdocs_delivery_meth = 'EDI' OR
                        lcu_inv_cust_doc.billdocs_delivery_meth = 'ePDF') THEN  -- Added 'OR' condition 'ePDF' as part of R1.4 CR# 586 eBilling.
                          IF((lc_combo_type = 'CR' AND ln_amount_due_original < 0 ) OR
                             (lc_combo_type = 'DB' AND ln_amount_due_original > 0)  ) THEN
                             lc_process_record := 'Y';
                             IF (lcu_inv_cust_doc.billdocs_delivery_meth = 'PRINT' AND
                                 lcu_inv_cust_doc.billdocs_special_handling IS NOT NULL) THEN
                             -- If Combotype For Special Handling invoices is CR 0r DB then send to Certegy
                                lcu_inv_cust_doc.billdocs_special_handling := NULL;
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending Special Handling invoices to '
                                                 ||'Certegy Since the Combo Type is CR/DB : '
                                                 ||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '
                                                 ||ln_amount_due_original||' ; Delivery Method: '
                                                 ||lcu_inv_cust_doc.billdocs_delivery_meth||'; Combo Type: '
                                                 ||lc_combo_type);
                             END IF;
                          ELSE
                               ln_not_insert_count_combo_pay := ln_not_insert_count_combo_pay + 1;
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'Paydoc-Invoice Not Processed Since It '
                                                 ||'Failed The Combo Logic: Invoice Number: '
                                                 ||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '
                                                 ||ln_amount_due_original||' ; Delivery Method: '
                                                 ||lcu_inv_cust_doc.billdocs_delivery_meth||'; Combo Type: '
                                                 ||lc_combo_type);
                          END IF;
                    ELSE--Delivery method
                        ln_not_insert_count_combo_pay := ln_not_insert_count_combo_pay + 1;
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'Paydoc-Invoice Not Processed Since '
                                                 ||'Delivery Method Is Not PRINT Or EDI: '
                                                 ||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '
                                                 ||ln_amount_due_original||' ; Delivery Method: '
                                                 ||lcu_inv_cust_doc.billdocs_delivery_meth||'; Combo Type: '
                                                 ||lc_combo_type);
                    END IF;
                 ELSE --combo not NULL/DB/CR
                    ln_not_insert_count_combo_pay := ln_not_insert_count_combo_pay + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Paydoc-Invoice Not Processed Since It '
                                                 ||'Failed The Combo Logic: Combo Type is Other than '
                                                 ||'NULL,DB and CR Or Delivery Method is not PRINT/EDI: Invoice Number: '
                                                 ||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '
                                                 ||ln_amount_due_original||' ; Delivery Method: '
                                                 ||lcu_inv_cust_doc.billdocs_delivery_meth||'; Combo Type: '
                                                 ||lc_combo_type);
                 END IF;
              ELSE --infodoc
                 IF (lc_combo_type IS NULL AND lcu_inv_cust_doc.billdocs_delivery_meth IN ('PRINT','EDI','ePDF','eXLS','eTXT')) THEN   -- Added 'ePDF' as part of R1.4 CR# 586 eBilling.
                    lc_process_record :='Y';          -- Process Infodoc only if Combo Type is NULL
                 ELSE
                    ln_not_insert_count_combo_info := ln_not_insert_count_combo_info + 1;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Info Doc-Invoice Not Processed Since It '
                                      ||'Failed The Combo Logic OR Delivery Method is not EDI/PRINT: Invoice Number: '
                                      ||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '
                                      ||ln_amount_due_original||' ; Delivery Method: '
                                      ||lcu_inv_cust_doc.billdocs_delivery_meth||'; Combo Type: '
                                      ||lc_combo_type);
                 END IF;
              END IF;
              -- End of Changes for Defect 13337

             /* IF (lc_process_record ='Y' AND ln_amount_due_remaining != 0 )  THEN -- Added for defect 12710
             */--Commented for the defect# 631 (CR 662)
               -- Added for the defect# 631 (CR 662)
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Cycle Date: '||ld_as_of_date);
               IF ((lc_process_record ='Y') AND (ln_amount_due_original NOT BETWEEN ln_write_off_amt_low AND ln_write_off_amt_high)) THEN
                 -- Commented for R1.3 CR 738 Defect 2766 (Start of changes for R1.3 CR 738 Defect 2766)
/*                 ld_estimated_print_date := XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE(
                                           --lcu_inv_cust_doc.extension_id          --Commented for the Defect# 9632
                                             lcu_inv_cust_doc.billdocs_payment_term  --Added for the Defect# 9632
                                            ,TRUNC(lcu_inv_cust_doc.creation_date));   -- Commented for R1.3 CR 738 Defect 2766*/
                   ld_estimated_print_date := ld_as_of_date;
                 -- End of changes for R1.3 CR 738 Defect 2766
               --Added for handling the exception while deriving the Effective Print Date of Invoice
                 IF (ld_estimated_print_date IS NOT NULL ) then

                    -- Added the below conditions as part of R1.4 CR# 586 eBilling.
                    IF lc_mail_to_attention IS NULL THEN
                       lc_mail_to_attention := NVL(lcu_inv_cust_doc.mail_to_attention,'ACCTS PAYABLE');
                    END IF;
                    lc_mail_to_attention    := 'ATTN: '||lc_mail_to_attention;
                    -- End of changes for R1.4 CR# 586 eBilling.

                    ln_insert_count := ln_insert_count + 1;
                    INSERT
                    INTO xx_ar_invoice_frequency
                      (document_id
                      ,customer_document_id
                      ,doc_delivery_method
                      ,doc_combo_type
                      ,paydoc_flag
                      ,invoice_id
                      ,org_id
                      ,estimated_print_date
                      ,billdocs_special_handling      --Added for traceability
                      ,bill_to_customer_id            --Added for traceability
                      ,extension_id                   --Added for traceability
                      ,billdocs_payment_term          --Added for traceability
                      ,last_update_date
                      ,last_updated_by
                      ,creation_date
                      ,created_by
                      ,last_update_login
                      ,attribute1
                      ,site_use_id              -- Added for Defect 12710
                      ,attribute4               -- Added for the R1.1 Defect # 1451 CR 626
                      ,attribute2               -- Added for the R1.3 Defect # 4762
                      -- Added the below columns as part of R1.4 CR# 586 eBilling.
                      ,direct_flag
                      ,parent_cust_acct_id
                      ,parent_cust_doc_id
                      ,mail_to_attention
                      ,amount_due_original
                      ,amount_due_remaining
                      ,due_date
                      --  End of changes for R1.4 CR# 586 eBilling.
                       )
                    VALUES(lcu_inv_cust_doc.billdocs_doc_id
                      ,lcu_inv_cust_doc.billdocs_cust_doc_id
                      ,lcu_inv_cust_doc.billdocs_delivery_meth
                      ,lcu_inv_cust_doc.billdocs_combo_type
                      ,lcu_inv_cust_doc.billdocs_paydoc_ind
                      ,lcu_inv_cust_doc.customer_trx_id
                      ,ln_org_id
                      ,ld_estimated_print_date
                      ,lcu_inv_cust_doc.billdocs_special_handling  --Added for traceability
                      ,lcu_inv_cust_doc.cust_account_id            --Added for traceability
                      ,lcu_inv_cust_doc.extension_id               --Added for traceability
                      ,lcu_inv_cust_doc.billdocs_payment_term      --Added for traceability
                      ,SYSDATE
                      ,ln_user_id
                      ,SYSDATE
                      ,ln_user_id
                      ,ln_login_id
                      ,fnd_global.conc_request_id
                      ,ln_site_use_id                                  -- Added for Defect 12710
                      ,gn_gc_amt                                       -- Added for the R1.1 Defect # 1451 (CR 626)
                      ,lc_cust_invoices.inv_type                       -- Added for the R1.3 Defect # 4762
                      -- Added the below columns as part for R1.4 CR# 586 R1.4.
                      ,lcu_inv_cust_doc.direct_flag
                      ,lcu_inv_cust_doc.parent_cust_acct_id
                      ,NVL(lcu_inv_cust_doc.parent_cust_doc_id,lcu_inv_cust_doc.billdocs_cust_doc_id)
                      ,lc_mail_to_attention
                      ,ln_amount_due_original
                      ,ln_amount_due_remaining
                      ,ld_due_date
                      -- End of changes for R1.4 CR# 586 eBilling.
                      );
 -- added to exclude individual invoices being consolidated - defect 12710
-- Commented for defect 5901. Update block moved outside the if condition.

/*
                  IF lcu_inv_cust_doc.billdocs_paydoc_ind = 'Y' THEN
                       UPDATE  ar_payment_schedules_all arps
                       SET     arps.exclude_from_cons_bill_flag = 'Y'
             -- Start of changes for R1.3 defect 4761
                              ,last_updated_by      = FND_GLOBAL.USER_ID
                              ,last_update_date     = SYSDATE
                              ,program_id           = FND_GLOBAL.CONC_PROGRAM_ID
                              ,request_id           = FND_GLOBAL.CONC_REQUEST_ID
                              ,last_update_login    = FND_GLOBAL.USER_ID
           -- End of changes for R1.3 defect 4761
                       WHERE   1 = 1
                       AND arps.customer_trx_id =lcu_inv_cust_doc.customer_trx_id  ;

                  END IF;
 */                  
                 ELSE   --Added for handling the exception while deriving the Effective Print Date of Invoice

                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in Deriving the Effective Print Date');
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Extension id: '||lcu_inv_cust_doc.extension_id||
                                      ' ; Invoice id: '||lcu_inv_cust_doc.customer_trx_id||' ; Invoice Number: '
                                      ||lcu_inv_cust_doc.trx_number);
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Document id: '||lcu_inv_cust_doc.billdocs_doc_id||
                                      ' ; Customer Document id: '||lcu_inv_cust_doc.billdocs_doc_id||
                                      ' ; Bill Docs Payment Term: '||lcu_inv_cust_doc.billdocs_payment_term);

                   FND_FILE.PUT_LINE(FND_FILE.LOG, '');

                   ln_not_insert_count_pr_date := ln_not_insert_count_pr_date + 1;
                   lc_eff_print_date_err       := 'Y';
                 END IF;

            --  ELSE        -- Commented for Defect 12710

                --  ln_not_insert_count_combo := ln_not_insert_count_combo + 1;     -- Commented for Defect 12710

                  /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice Number: '||lcu_inv_cust_doc.trx_number||'; Invoice Amount: '||ln_amount_due_original||' ; Combo Type: '||lc_combo_type||' ; Payment Code: '||lc_payment_code);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ''); */

              END IF; -- lc_process_record ='Y'

                   --Fix for the Defect# 10103
              IF ( lc_eff_print_date_err = 'N' AND lcu_inv_cust_doc.billdocs_paydoc_ind = 'Y') THEN      -- Added paydoc indicator condition as part of R1.3 CR 738 Defect 2766
                 UPDATE ra_customer_trx_all RCT
                 SET    RCT.attribute15 = 'Y'
      -- Start of changes for R1.3 defect 4761
                       ,last_updated_by      = FND_GLOBAL.USER_ID
                       ,last_update_date     = SYSDATE
                       ,program_id           = FND_GLOBAL.CONC_PROGRAM_ID
                       ,request_id           = FND_GLOBAL.CONC_REQUEST_ID
                       ,last_update_login    = FND_GLOBAL.USER_ID
    -- End of changes for R1.3 defect 4761
                 WHERE  RCT.customer_trx_id =lcu_inv_cust_doc.customer_trx_id;
              END IF;

           END IF;      -- lc_inv_processed           -- Added for the Defect 12710
		   ELSE				--if for l_bypass_trx     -- Added for NAIT-80765
				FND_FILE.PUT_LINE(FND_FILE.LOG, 'Skipping for Bill Complete Customer Since Billing Date is pushed to future trx_number : '||lcu_inv_cust_doc.trx_number);
		   END	IF;
        END LOOP;

-- updated added for defect 12227. to update the bills of consol invoices and transaction type set as "Do not print"
-- so that they wont add load on main cursor.

        -- Start for Defect # 4046
-- Start of changes for R1.3 Defect 2766 CR 738
/*        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Start updation on ra_customer_trx_all -- printing_original_date is not null');*/

        -- End for Defect # 4046
-- Below update statement was moved to main program as a part of CR 738 Defect 2766
--        UPDATE /*+ index(RCT XX_AR_CUSTOMER_TRX_N4) */ ra_customer_trx_all RCT
/*        SET RCT.attribute15 = 'P'
        WHERE RCT.attribute15 = 'N'
        AND RCT.printing_original_date IS NOT NULL AND rct.org_id = ln_org_id ;

        -- Start for Defect # 4046

        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'completion of updation on ra_customer_trx_all -- printing_original_date is not null');*/
-- End of changes for R1.3 Defect 2766 CR 738
        -- End for Defect # 4046

-- end defect 12227

--Start of changes for the defect 12227
-- Commented the below block for R1.3 CR 738 Defect 2766
/*BEGIN
       lc_error_location := 'Getting the concurrent request details';
          SELECT fcr.concurrent_program_id
                 ,fcr.program_application_id
                 ,fcr.request_id
                 ,fcr.parent_request_id
                 ,fcr.status_code
                 ,fcr.request_date
                 ,fcr.actual_start_date
                 ,fcr.actual_completion_date
          INTO    ln_conc_prog_id
                 ,ln_application_id
                 ,ln_request_id
                 ,ln_par_req_id
                 ,lc_req_state
                 ,ld_req_date
                 ,ld_act_strt_date
                 ,ld_act_comp_date
          FROM   fnd_concurrent_requests fcr
          WHERE  fcr.request_id = fnd_global.conc_request_id;

       lc_error_location := 'Inserting the concurrent request details into XX_FIN_PROGRAM_STATS';
          INSERT INTO XX_FIN_PROGRAM_STATS(
                          program_short_name
                          ,concurrent_program_id
                          ,application_id
                          ,request_id
                          ,parent_request_id
                          ,request_submitted_time
                          ,request_start_time
                          ,request_end_time
                          ,request_status
                          ,count
                          ,total_dr
                          ,total_cr
                          ,sob
                          ,currency
                          ,attribute1
                          ,attribute2
                          ,attribute3
                          ,attribute4
                          ,attribute5
                          ,run_date
                          ,event_number
                          ,group_id
                          ,org_id
                         )
                   VALUES(
                          'XX_AR_INV_FREQ_PKG_SYNCH'
                          ,ln_conc_prog_id
                          ,ln_application_id
                          ,ln_request_id
                          ,ln_par_req_id
                          ,ld_req_date
                          ,ld_act_strt_date
                          ,SYSDATE
                          ,'C'
                          ,ln_rec_count
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                         );
EXCEPTION
     WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
END;*/
-- End of changes for R1.3 Defect 2766 CR 738
--End of Changes for the defect 12227

      -- Strat for Defect # 4046
-- Commented the below update statement for R1.3 CR 738 Defect 2766 (below update statement was moved to main program)
/*        UPDATE xx_fin_translatevalues
        SET target_value1 = ln_max_trx_id
        WHERE translate_id = ln_translate_id
        AND   translate_value_id= ln_translate_value_id
        AND   source_value1 = ln_org_id;*/
-- End of changes for R1.3 CR 738 Defect 2766
     -- End for Defect # 4046

-- Below update statement added for R1.3 CR 738 Defect 2766
        UPDATE xx_ar_inv_freq_master
        SET    fetch_inv_failed_cnt  = ln_not_fetch_invoice_count
              ,combo_pay_failed_cnt  = ln_not_insert_count_combo_pay
              ,combo_info_failed_cnt = ln_not_insert_count_combo_info
              ,insert_count          = ln_insert_count
              ,prnt_date_failed_cnt  = ln_not_insert_count_pr_date
        WHERE  batch_id              = p_batch_id
        AND    org_id                = ln_org_id
        AND    ROWNUM                = 1;
-- End of changes for R1.3 CR 738 Defect 2766

        COMMIT;

        --Added for printing the summary information of the Ivoices processed.
        FND_FILE.PUT_LINE(FND_FILE.LOG, '-----------------------------------------------');

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records inserted into the Frequency table: '||ln_insert_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records not inserted into the Frequency table due to failure in deriving in ESTIMATED PRINT DATE: '||ln_not_insert_count_pr_date);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Paydoc Records not inserted into the Frequency table due to Combo Logic: '||ln_not_insert_count_combo_pay);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Info Records not inserted into the Frequency table due to Combo Logic: '||ln_not_insert_count_combo_info);  -- Added for Defect 13337
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Records not inserted into the Frequency table due to failure in fetching records in c_cust_invoices: '||ln_not_fetch_invoice_count);

      -- Strat for Defect # 4046

/*        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Start of updation on ra_customer_trx_all -- printing_original_date is not null');*/

     -- End for Defect # 4046

    EXCEPTION
        WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_debug);
        ROLLBACK;
        x_ret_code := 2;

    END SYNCH;

/* Commented to the Defect 13101
-- +===================================================================+
-- | Name : ERR_HANDLE                                                 |
-- | Description : This program is used to update the RA_CUSTOMER_TRX  |
-- |                 table. The attribute15 is set to Y if the previous|
-- |                 programs miss to update the same.                 |
-- |                                                                   |
-- | Program "OD: AR Invoice Error Handles"                            |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+
    PROCEDURE ERR_HANDLE (x_error_buff         OUT VARCHAR2
                          ,x_ret_code           OUT NUMBER)
    AS

    --Commeneted for the Defect# 9729

    CURSOR c_rem_inv_update IS
    (
        SELECT
                XAIF.invoice_id
        FROM
                xx_ar_invoice_frequency XAIF
        WHERE
                XAIF.org_id=FND_PROFILE.VALUE('ORG_ID')
    );
    ln_customer_trx_id        NUMBER;
    ln_recs_processed         NUMBER := 0;
    ln_reqid_request_set      NUMBER;
    ln_reqid_request_stage2   NUMBER;
    ln_reqid_inv_print_stg    NUMBER;
    lc_error_loc              VARCHAR2(4000) := NULL;
    lc_error_debug            VARCHAR2(4000) := NULL;

    BEGIN

        --Commeneted, as UPDATION of ATTRIBUTE15 is happening in Manage Frequencies program itself.

        /*FOR lcu_rem_inv_update IN c_rem_inv_update
        LOOP

            UPDATE    ra_customer_trx_all RCT
            SET       RCT.attribute15= 'Y'
            WHERE     RCT.customer_trx_id=lcu_rem_inv_update.invoice_id;

            ln_recs_processed := ln_recs_processed + 1;

        END LOOP;

        --COMMIT;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Completed');

    EXCEPTION WHEN OTHERS THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records processed: '||ln_recs_processed);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_loc);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||lc_error_debug);

    END ERR_HANDLE;  Commented to the Defect 13101 */

-- +===================================================================+
-- | Name : MULTI_THREAD                                               |
-- | Description : This program is used to implement multithreading in |
-- |               the billing programs. The batch size controls the   |
-- |               number of invoices printed in each process.         |
-- |                                                                   |
-- | Program "OD: AR Invoice Print Paper Invoices Parallel"            |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+


PROCEDURE XX_MULTI_THREAD_NEW(
                              x_error_buff                 OUT VARCHAR2
                             ,x_ret_code                   OUT NUMBER
                             ,p_cust_trx_class             IN VARCHAR2
                             ,p_cust_trx_type_id           IN NUMBER
                             ,p_delete_freq_table          IN VARCHAR2
                             ,p_source                     IN VARCHAR2
                             ,p_tax_registration_number    IN VARCHAR2
                             ,p_batch_size                 IN  NUMBER
                             ,p_as_of_date                 IN VARCHAR2)                  --Added for the Defect# 9076

AS
   -- Local Variable declaration
   ln_lower                  NUMBER;
   ln_request_id             NUMBER := -1;
   ln_index                  NUMBER;
   ln_last_cust_id           ra_customer_trx_all.bill_to_customer_id%TYPE;
   ln_first_cust_id          ra_customer_trx_all.bill_to_customer_id%TYPE;
   ln_upper                  NUMBER;
   ln_count                  NUMBER;
   lc_req_data               VARCHAR2(1);
   TYPE inv_rec IS RECORD(
                           cust_num ra_customer_trx_all.bill_to_customer_id%TYPE
                         );
   TYPE t_cust_number     IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
   TYPE t_invoice_id      IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
   r_inv                  inv_rec;
   t_cust_num             t_cust_number ;
   t_inv_id               t_invoice_id;
   lc_invoice_exist       VARCHAR2(1) := 'N';
   ld_print_date          DATE;

   ln_org_id             NUMBER;   --Added for the Defect# 9632

   -- Cursor Declaration for ra_interface_lines_all Table
 CURSOR lcu_count_invoices(  p_lower         NUMBER
                            ,p_print_date    DATE
                            ,p_org_id        NUMBER)  --Added for the Defect# 9632
      IS
      /*SELECT rct.bill_to_customer_id
      FROM ra_customer_trx_all rct,
           xx_ar_invoice_frequency xaif,
           xx_cdh_a_ext_billdocs_v XCAEBV
      WHERE
           XCAEBV.billdocs_cust_doc_id = XAIF.customer_document_id
           and RCT.customer_trx_id = XAIF.invoice_id
           and xaif.estimated_print_date <= sysdate
           and XCAEBV.billdocs_special_handling is  NULL
           and XAIF.doc_delivery_method = 'PRINT'
           and xaif.org_id=FND_PROFILE.VALUE('ORG_ID')
           and rct.bill_to_customer_id  > p_lower
           -- and customer_trx_id between 374135 and 377900
      ORDER BY rct.bill_to_customer_id ;*/
      SELECT XAIF.bill_to_customer_id
      FROM   xx_ar_invoice_frequency XAIF
      WHERE  XAIF.doc_delivery_method = 'PRINT'
      AND    XAIF.billdocs_special_handling IS NULL
      AND    XAIF.estimated_print_date <= p_print_date
      --AND    XAIF.org_id=FND_PROFILE.VALUE('ORG_ID')     --Commented for the Defect# 9632
      AND    XAIF.org_id = p_org_id    --Added for the Defect# 9632
      AND    XAIF.bill_to_customer_id > p_lower
      ORDER BY XAIF.bill_to_customer_id;

   BEGIN

   ln_org_id     := FND_PROFILE.VALUE('ORG_ID');  --Added for the Defect# 9632
   FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG ID: '||ln_org_id);

   ld_print_date := TO_DATE (p_as_of_date, 'YYYY/MM/DD HH24:MI:SS');
   lc_req_data   := FND_CONC_GLOBAL.REQUEST_DATA;

   IF ( lc_req_data = '1' ) THEN

      RETURN;
   END IF;

   ln_last_cust_id := 0;
   lc_invoice_exist := 'N';

       <<THREAD_LOOP>>
       LOOP
       OPEN lcu_count_invoices(ln_last_cust_id, ld_print_date
                                                       , ln_org_id);  --Added for the Defect# 9632
            BEGIN

               FETCH lcu_count_invoices BULK COLLECT INTO t_cust_num LIMIT p_batch_size;

               IF NVL(t_cust_num.FIRST,0) = 0 THEN
                  EXIT THREAD_LOOP;
               ELSE
                  ln_upper            := t_cust_num.last;
                  ln_lower            := t_cust_num.first;
                  ln_last_cust_id := t_cust_num(ln_upper);
                  ln_index            := ln_upper ;
                  ln_first_cust_id     := t_cust_num(ln_lower);
                  --dbms_output.put_line('First Customer '|| ln_first_cust_id);
                  --dbms_output.put_line('Last Customer   '||ln_last_cust_id);

                  SELECT COUNT(1)
                  INTO   ln_count
                  FROM   xx_ar_invoice_frequency XAIF
                  WHERE  XAIF.doc_delivery_method = 'PRINT'
                  AND    XAIF.billdocs_special_handling IS NULL
                  AND    XAIF.estimated_print_date <= ld_print_date
                  AND    XAIF.org_id=FND_PROFILE.VALUE('ORG_ID')
                  AND    XAIF.bill_to_customer_id = ln_last_cust_id;

                  IF ln_count > .7*p_batch_size THEN

                        IF ln_last_cust_id <> ln_first_cust_id
                        THEN
                              ln_request_id := fnd_request.submit_request('XXFIN'
                                                  ,'XXARINVNEW'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE--FALSE
                                                  ,p_cust_trx_class
                                                  ,p_cust_trx_type_id
                                                  ,p_delete_freq_table
                                                  ,p_source
                                                  ,p_tax_registration_number
                                                  ,ln_first_cust_id
                                                  ,ln_last_cust_id
                                                  ,'Y'
                                                  ,p_as_of_date);                  --Added for the Defect# 9076

                           COMMIT;

                        END IF;
                        ln_request_id := fnd_request.submit_request('XXFIN'
                                                  ,'XXARINVNEW'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE--FALSE
                                                  ,p_cust_trx_class
                                                  ,p_cust_trx_type_id
                                                  ,p_delete_freq_table
                                                  ,p_source
                                                  ,p_tax_registration_number
                                                  ,ln_last_cust_id
                                                  ,ln_last_cust_id
                                                  ,'N'
                                                  ,p_as_of_date);                  --Added for the Defect# 9076

                        COMMIT;

                  ELSE
                      ln_request_id := fnd_request.submit_request('XXFIN'
                                                 ,'XXARINVNEW'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE--FALSE
                                                  ,p_cust_trx_class
                                                  ,p_cust_trx_type_id
                                                  ,p_delete_freq_table
                                                  ,p_source
                                                  ,p_tax_registration_number
                                                  ,ln_first_cust_id
                                                  ,ln_last_cust_id
                                                  ,'N'
                                                  ,p_as_of_date);                  --Added for the Defect# 9076

                      COMMIT;

                  END IF;

               END IF;

           END;

       IF lcu_count_invoices%ISOPEN THEN
          CLOSE lcu_count_invoices;
       END IF;

       IF (ln_request_id > 0) THEN
          lc_invoice_exist := 'Y';
       END IF;

       END LOOP;

       IF (lc_invoice_exist = 'Y') THEN
          FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'1');
       END IF;

       COMMIT;
       x_ret_code := 0;
       RETURN;

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
      x_ret_code := 2;

END XX_MULTI_THREAD_NEW;

-- +===================================================================+
-- | Name : MULTI_THREAD                                               |
-- | Description : This program is used to implement multithreading in |
-- |               the billing programs. The batch size controls the   |
-- |               number of invoices printed in each process.         |
-- |                                                                   |
-- | Program "OD: AR Invoice Print Paper Invoices Parallel"            |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+


PROCEDURE XX_MULTI_THREAD_SPL(
                              x_error_buff                OUT VARCHAR2
                             ,x_ret_code                  OUT NUMBER
                             ,p_cust_trx_class            IN VARCHAR2
                             ,p_cust_trx_type_id          IN NUMBER
                             ,p_delete_freq_table         IN VARCHAR2
                             ,p_source                    IN VARCHAR2
                             ,p_tax_registration_number   IN VARCHAR2
                             ,p_batch_size                IN  NUMBER
                             ,p_as_of_date                IN VARCHAR2   --Added for the Defect# 9076
                             ,p_printer_style             IN VARCHAR2   --Added for the Defect#8253
                             ,p_printer_name              IN VARCHAR2   --Added for the Defect#8253
                             ,p_number_copies             IN NUMBER     --Added for the Defect#8253
                             ,p_save_output               IN VARCHAR2   --Added for the Defect#8253
                             ,p_print_together            IN VARCHAR2   --Added for the Defect#8253
                             ,p_validate_printer          IN VARCHAR2   --Added for the Defect#8253
                             ,p_another_printer           IN VARCHAR2   --Added for Defect # 12223
                             )
AS
   -- Local Variable declaration
   ln_lower                  NUMBER;
   ln_request_id             NUMBER := -1;
   ln_index                  NUMBER;
   ln_last_cust_id           ra_customer_trx_all.bill_to_customer_id%TYPE;
   ln_first_cust_id          ra_customer_trx_all.bill_to_customer_id%TYPE;
   ln_upper                  NUMBER;
   ln_count                  NUMBER;
   lc_req_data               VARCHAR2(1);
   TYPE inv_rec IS RECORD(
                           cust_num ra_customer_trx_all.bill_to_customer_id%TYPE
                         );
   TYPE t_cust_number        IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
   TYPE t_invoice_id         IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
   r_inv                     inv_rec;
   t_cust_num                t_cust_number;
   t_inv_id                  t_invoice_id;
   lb_print_option           BOOLEAN;      --Added for the Defect# 8253
   lb_add_layout             BOOLEAN;      --Added for the Defect# 8253
   lb_save_output            BOOLEAN;      --Added for the Defect# 8253
   lc_invoice_exist          VARCHAR2(1) := 'N';
   ld_print_date             DATE;
   ln_org_id                 NUMBER;       --Added for the Defect# 9632
   lb_print_another          BOOLEAN;      --Added for the Defect# 12223
   ln_parent_req_id          NUMBER;       -- Added for the Defect# 6342 on 25-Jun-10
   ln_err_cnt                NUMBER := 0;       -- Added for the Defect# 6342 on 25-Jun-10
   ln_wrn_cnt                NUMBER := 0;       -- Added for the Defect# 6342 on 25-Jun-10
   ln_nrm_cnt                NUMBER := 0;       -- Added for the Defect# 6342 on 25-Jun-10
   ln_term_cnt               NUMBER := 0;       -- Added for the Defect# 6342 on 25-Jun-10

   -- Cursor Declaration for ra_interface_lines_all Table
 CURSOR lcu_count_invoices(p_lower NUMBER
                          ,p_print_date DATE
                          ,p_org_id        NUMBER)  --Added for the Defect# 9632
      IS
      /*SELECT rct.bill_to_customer_id
      FROM ra_customer_trx_all rct,
           xx_ar_invoice_frequency xaif,
           xx_cdh_a_ext_billdocs_v XCAEBV
      WHERE
           XCAEBV.billdocs_cust_doc_id = XAIF.customer_document_id
           and RCT.customer_trx_id = XAIF.invoice_id
           and xaif.estimated_print_date <= sysdate
           and XCAEBV.billdocs_special_handling is  NULL
           and XAIF.doc_delivery_method = 'PRINT'
           and xaif.org_id=FND_PROFILE.VALUE('ORG_ID')
           and rct.bill_to_customer_id  > p_lower
           -- and customer_trx_id between 374135 and 377900
      ORDER BY rct.bill_to_customer_id ;*/
      SELECT XAIF.bill_to_customer_id
      FROM   xx_ar_invoice_frequency XAIF
      WHERE  XAIF.doc_delivery_method = 'PRINT'
      AND    XAIF.billdocs_special_handling IS NOT NULL
      AND    XAIF.estimated_print_date <= p_print_date
      --AND    XAIF.org_id=FND_PROFILE.VALUE('ORG_ID')   --Commented for the Defect# 9632
      AND    XAIF.org_id = p_org_id   --Added for the Defect# 9632
      AND    XAIF.bill_to_customer_id > p_lower
      ORDER BY XAIF.bill_to_customer_id;

BEGIN

   ln_org_id := FND_PROFILE.VALUE('ORG_ID');  --Added for the Defect# 9632
   FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG ID: '||ln_org_id);

   ld_print_date := TO_DATE (p_as_of_date, 'YYYY/MM/DD HH24:MI:SS');
   /*Start of Addition for the Defect# 8253*/
   IF ( p_save_output = 'Y') THEN

      lb_save_output := TRUE;

   ELSE

      lb_save_output := FALSE;

   END IF;
   /*End of Addition for the Defect# 8253*/

   lc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

   IF ( lc_req_data = '1' ) THEN
-- Start of changes for the Defect 6342 on 25-JUN-10
   ln_parent_req_id := FND_GLOBAL.CONC_REQUEST_ID;
   BEGIN
          SELECT SUM(CASE WHEN status_code = 'E'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'G'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'C'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'X'
                          THEN 1 ELSE 0 END)
          INTO   ln_err_cnt
                ,ln_wrn_cnt
                ,ln_nrm_cnt
                ,ln_term_cnt
          FROM   fnd_concurrent_requests
          WHERE  parent_request_id = ln_parent_req_id;

          FND_FILE.put_line(FND_FILE.LOG,'Parent Request ID (Parallel Program): '||ln_parent_req_id);

         IF (ln_err_cnt > 0) OR (ln_term_cnt > 0)THEN
             FND_FILE.put_line(FND_FILE.LOG,'Special Handling Child program ended in Error/Terminated');
             x_error_buff  := 'The Main Parallel Program ending in Error';
             x_ret_code := 2;
         ELSIF (ln_wrn_cnt > 0)THEN
             FND_FILE.put_line(FND_FILE.LOG,'Special Handling Child program ended in Warning');
             x_error_buff  := 'The Main Parallel Program ending in Warning';
             x_ret_code := 1;
         END IF;
         EXCEPTION
          WHEN OTHERS THEN

                 FND_FILE.put_line(FND_FILE.LOG,'Oracle Error Code: '
                                                ||'--'
                                                ||SQLCODE
                                                ||'--'
                                                ||SQLERRM
                                   );
         END;
-- End of changes for the Defect 6342 on 25-JUN-10
       RETURN;
   END IF;

   ln_last_cust_id := 0;
   lc_invoice_exist := 'N';

       <<THREAD_LOOP>>
       LOOP
       OPEN lcu_count_invoices(ln_last_cust_id, ld_print_date
                                  ,ln_org_id);   --Added for the Defect# 9632
            BEGIN

               FETCH lcu_count_invoices BULK COLLECT INTO t_cust_num LIMIT p_batch_size;

               IF NVL(t_cust_num.FIRST,0) = 0 THEN

                  EXIT THREAD_LOOP;

               ELSE
                  ln_upper            := t_cust_num.last;
                  ln_lower            := t_cust_num.first;
                  ln_last_cust_id     := t_cust_num(ln_upper);
                  ln_index            := ln_upper ;
                  ln_first_cust_id    := t_cust_num(ln_lower);

                  --dbms_output.put_line('First Customer '|| ln_first_cust_id);
                  --dbms_output.put_line('Last Customer   '||ln_last_cust_id);

                  SELECT COUNT(1)
                  INTO   ln_count
                  FROM   xx_ar_invoice_frequency XAIF
                  WHERE  XAIF.doc_delivery_method = 'PRINT'
                  AND    XAIF.billdocs_special_handling IS NOT NULL
                  AND    XAIF.estimated_print_date <= ld_print_date
                  AND    XAIF.org_id=FND_PROFILE.VALUE('ORG_ID')
                  AND    XAIF.bill_to_customer_id = ln_last_cust_id;

                  IF ln_count > .7*p_batch_size THEN

                     IF ln_last_cust_id <> ln_first_cust_id THEN

                        lb_add_layout := fnd_request.add_layout(
                                                       template_appl_name    => 'XXFIN'
                                                       ,template_code        => 'XXARINVSPL'
                                                       ,template_language    => 'en'
                                                       ,template_territory   => 'US'
                                                       ,output_format        => 'PDF');

                        IF (lb_add_layout = TRUE) THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'TRUE');
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'FALSE');
                        END IF;

                        lb_print_option := fnd_request.set_print_options(
                                                       printer            => p_printer_name
                                                       ,style             => p_printer_style
                                                       ,copies            => p_number_copies
                                                       ,save_output       => lb_save_output
                                                       ,print_together    => p_print_together
                                                       ,validate_printer  => p_validate_printer);

                        IF (lb_print_option = TRUE) THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
                        END IF;

                        -- Start for Defect # 12223

                        IF (p_another_printer IS NOT NULL) THEN
                                   lb_print_another := FND_REQUEST.add_printer(
                                                        printer         => p_another_printer
                                                       ,copies          => p_number_copies );
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Printer Name :'||p_another_printer);
                        END IF;

                        IF (lb_print_another = TRUE) THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'TRUE');
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'FALSE');
                        END IF;

                        -- End for Defcet # 12223


                        ln_request_id := fnd_request.submit_request( 'XXFIN'
                                                        ,'XXARINVSPL'
                                                        ,NULL
                                                        ,NULL
                                                        ,TRUE--FALSE
                                                        ,p_cust_trx_class
                                                        ,p_cust_trx_type_id
                                                        ,p_delete_freq_table
                                                        ,p_source
                                                        ,p_tax_registration_number
                                                        ,ln_first_cust_id
                                                        ,ln_last_cust_id
                                                        ,'Y'
                                                        ,p_as_of_date);

                        COMMIT;

                     END IF;

                     lb_add_layout := fnd_request.add_layout(
                                                       template_appl_name    => 'XXFIN'
                                                       ,template_code        => 'XXARINVSPL'
                                                       ,template_language    => 'en'
                                                       ,template_territory   => 'US'
                                                       ,output_format        => 'PDF');

                     IF (lb_add_layout = TRUE) THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'TRUE');
                     ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'FALSE');
                     END IF;

                     lb_print_option := fnd_request.set_print_options(
                                                        printer            => p_printer_name
                                                       ,style             => p_printer_style
                                                       ,copies            => p_number_copies
                                                       ,save_output       => lb_save_output
                                                       ,print_together    => p_print_together
                                                       ,validate_printer  => p_validate_printer);

                      IF (lb_print_option = TRUE) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
                      ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
                      END IF;

                        -- Start for Defect # 12223

                        IF (p_another_printer IS NOT NULL) THEN
                                   lb_print_another := FND_REQUEST.add_printer(
                                                        printer         => p_another_printer
                                                       ,copies          => p_number_copies );
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Printer Name :'||p_another_printer);
                        END IF;

                        IF (lb_print_another = TRUE) THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'TRUE');
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'FALSE');
                        END IF;

                        -- End for Defcet # 12223


                      ln_request_id := fnd_request.submit_request( 'XXFIN'
                                                        ,'XXARINVSPL'
                                                        ,NULL
                                                        ,NULL
                                                        ,TRUE--FALSE
                                                        ,p_cust_trx_class
                                                        ,p_cust_trx_type_id
                                                        ,p_delete_freq_table
                                                        ,p_source
                                                        ,p_tax_registration_number
                                                        ,ln_last_cust_id
                                                        ,ln_last_cust_id
                                                        ,'N'
                                                        ,p_as_of_date);

                      COMMIT;

                   ELSE

                      lb_add_layout := fnd_request.add_layout(
                                                        template_appl_name    => 'XXFIN'
                                                       ,template_code        => 'XXARINVSPL'
                                                       ,template_language    => 'en'
                                                       ,template_territory   => 'US'
                                                       ,output_format        => 'PDF');

                      IF (lb_add_layout = TRUE) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'TRUE');
                      ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Adding Layout: '||'FALSE');
                      END IF;


                      lb_print_option := fnd_request.set_print_options(
                                                        printer            => p_printer_name
                                                       ,style             => p_printer_style
                                                       ,copies            => p_number_copies
                                                       ,save_output       => lb_save_output
                                                       ,print_together    => p_print_together
                                                       ,validate_printer  => p_validate_printer);

                      IF (lb_print_option = TRUE) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
                      ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
                      END IF;

                        -- Start for Defect # 12223

                        IF (p_another_printer IS NOT NULL) THEN
                                   lb_print_another := FND_REQUEST.add_printer(
                                                        printer         => p_another_printer
                                                       ,copies          => p_number_copies );
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Printer Name :'||p_another_printer);
                        END IF;

                        IF (lb_print_another = TRUE) THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'TRUE');
                        ELSE
                           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from 2nd Printer Options Set: '||'FALSE');
                        END IF;

                        -- End for Defcet # 12223


                      ln_request_id := fnd_request.submit_request('XXFIN'
                                                        ,'XXARINVSPL'
                                                        ,NULL
                                                        ,NULL
                                                        ,TRUE--FALSE
                                                        ,p_cust_trx_class
                                                        ,p_cust_trx_type_id
                                                        ,p_delete_freq_table
                                                        ,p_source
                                                        ,p_tax_registration_number
                                                        ,ln_first_cust_id
                                                        ,ln_last_cust_id
                                                        ,'N'
                                                        ,p_as_of_date);

                      COMMIT;

                   END IF;

                END IF;

            END;

            IF lcu_count_invoices%ISOPEN THEN
               CLOSE lcu_count_invoices;
            END IF;

            IF (ln_request_id > 0) THEN
               lc_invoice_exist := 'Y';
            END IF;
       END LOOP;

    IF (lc_invoice_exist = 'Y') THEN
       FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'1');
    END IF;

    COMMIT;

    x_ret_code := 0;

    RETURN;

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
      x_ret_code := 2;

END XX_MULTI_THREAD_SPL;

/*Start of the Fix for the Defect# 8726*/

-- +===================================================================+
-- | Name : CERT_RPTZIP                                                |
-- | Description : This program is used wrapper to the Certegy Report  |
-- |               and the zipping program                             |
-- |                                                                   |
-- |                                                                   |
-- | Program "OD: AR Invoice Certegy Report and Zipping"               |
-- |                                                                   |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+

PROCEDURE CERT_RPTZIP     (x_error_buff               OUT VARCHAR2
                          ,x_ret_code                 OUT NUMBER
                          ,p_cust_trx_class           IN VARCHAR2
                          ,p_cust_trx_type_id         IN NUMBER
                          ,p_delete_freq_table        IN VARCHAR2
                          ,p_source                   IN VARCHAR2
                          ,p_tax_registration_number  IN VARCHAR2
                          ,p_batch_size               IN NUMBER
                          ,p_as_of_date               IN VARCHAR2     --Added for the Defect# 9076
                          ,p_data_file_name           IN VARCHAR2
                          ,p_zip_file_name            IN VARCHAR2
                          ,p_done_file_name           IN VARCHAR2
                          ,p_file_size                IN NUMBER
                          ,p_archive_path_zip_file    IN VARCHAR2
                          ,p_archive_path_data_file   IN VARCHAR2
                          ,p_delete_file              IN VARCHAR2) AS

    ln_report_request_id   fnd_concurrent_requests.request_id%TYPE;
    ln_request_id          fnd_concurrent_requests.request_id%TYPE;

    lb_result              BOOLEAN;
    lc_phase               VARCHAR2(1000);
    lc_status              VARCHAR2(1000);
    lc_dev_phase           VARCHAR2(1000);
    lc_dev_status          VARCHAR2(1000);
    lc_message             VARCHAR2(1000);
    lc_country             ar_system_parameters.default_country%TYPE;
    ln_thread_submitted    NUMBER := 0;


    v_req_data VARCHAR2(100);

BEGIN

    v_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

    IF NVL(v_req_data,'FIRST') = 'FIRST' THEN

        ln_report_request_id := fnd_request.submit_request('XXFIN'
                                                  ,'XXARINVNEWP'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE
                                                  ,p_cust_trx_class
                                                  ,p_cust_trx_type_id
                                                  ,p_delete_freq_table
                                                  ,p_source
                                                  ,p_tax_registration_number
                                                  ,p_batch_size
                                                  ,p_as_of_date);                  --Added for the Defect# 9076

        COMMIT;

        fnd_conc_global.set_req_globals(
                                        conc_status => 'PAUSED'
                                       ,request_data => 'SECOND');

    END IF;

    IF NVL(v_req_data,'FIRST') = 'SECOND' THEN
        /*lb_result:=fnd_concurrent.wait_for_request(ln_report_request_id,1,0
                         ,lc_phase
                         ,lc_status
                         ,lc_dev_phase
                         ,lc_dev_status
                         ,lc_message);*/

        BEGIN

            SELECT default_country
            INTO lc_country
            FROM ar_system_parameters;

        EXCEPTION WHEN OTHERS THEN
            lc_country := NULL;

        END;

        BEGIN

            BEGIN
                SELECT FCR.request_id
                INTO   ln_report_request_id
                FROM   fnd_concurrent_requests FCR
                WHERE   FCR.parent_request_id = fnd_global.conc_request_id;
            EXCEPTION WHEN OTHERS THEN
                ln_report_request_id := NULL;
            END;

            fnd_file.put_line(fnd_file.log,'Certegy Master Request ID:'||ln_report_request_id);

           BEGIN
            SELECT 1 INTO ln_thread_submitted
            FROM dual WHERE EXISTS (SELECT FCR.request_id
                                    FROM fnd_concurrent_requests FCR
-- Start of changes for R1.3 Defect 3853
                                       ,xx_ar_invoice_freq_history XAIFH
                            --      WHERE FCR.parent_request_id=ln_report_request_id);
                                    WHERE TO_CHAR(FCR.request_id) = XAIFH.attribute1
                                    AND   FCR.parent_request_id = ln_report_request_id);
           fnd_file.put_line(fnd_file.log,'No of Child Threads:'||ln_thread_submitted);
-- End of changes for R1.3 Defect 3853
           EXCEPTION WHEN OTHERS THEN
                ln_thread_submitted := 2 ;
            END;


        END;
            fnd_file.put_line(fnd_file.log,'ln_thread_submitted ' || ln_thread_submitted);

        IF (ln_thread_submitted = 1) THEN

            ln_request_id := fnd_request.submit_request('XXFIN'
                                                  ,'XXARINVBILLZIP'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE
                                                  ,p_data_file_name||lc_country||'_*_'||ln_report_request_id||'*.xml'
                                                  ,p_zip_file_name
                                                  ,p_done_file_name
                                                  ,p_file_size
                                                  ,p_archive_path_zip_file
                                                  ,p_archive_path_data_file
                                                  ,p_delete_file
                                                  ,ln_report_request_id                --Added for the Defect# 9131
                                                  ,p_data_file_name||lc_country);      --Added for the Defect# 9131

            COMMIT;

            fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                          ,request_data => 'OVER');

            /*lb_result:=fnd_concurrent.wait_for_request(ln_request_id,1,0
                         ,lc_phase
                         ,lc_status
                         ,lc_dev_phase
                         ,lc_dev_status
                         ,lc_message);*/
-- ADDED FOR DEFECT 10341 TO call zipping program to create dummy data files.
        ELSE
            ln_request_id := fnd_request.submit_request('XXFIN'
                                                  ,'XXARINVBILLZIP'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE
                                                  ,p_data_file_name
                                                  ,p_zip_file_name
                                                  ,p_done_file_name
                                                  ,p_file_size
                                                  ,p_archive_path_zip_file
                                                  ,p_archive_path_data_file
                                                  ,p_delete_file
                                                  ,ln_report_request_id
                                                  ,p_data_file_name||lc_country
                                                  ,'Y'); -- ADDED FOR DEFECT 10341

            COMMIT;
-- end of changes Fix for defect 10341
            fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                          ,request_data => 'OVER');

        END IF;

    END IF;

END CERT_RPTZIP;

/*End of the Fix for the Defect# 8726*/


/* Start of Purge Program --Added by Agnes */
-- +===================================================================+
-- | Name : PURGE_HIST                                                 |
-- | Description : This is the program to purge the Frequency History  |
-- |                table.                                             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Program :"OD: AR Purge Invoice Frequency History"                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+
PROCEDURE PURGE_HIST  (x_error_buff               OUT VARCHAR2
                      ,x_ret_code                 OUT NUMBER
                      ,p_purge_date               IN   VARCHAR2) AS

    ld_purge_date DATE;

BEGIN

    ld_purge_date := TO_DATE (p_purge_date,'YYYY/MM/DD HH24:MI:SS');

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Purge Date: '||TO_CHAR(ld_purge_date, 'DD-MON-YYYY'));

    DELETE FROM xx_ar_invoice_freq_history
    WHERE TRUNC(creation_date) <= ld_purge_date;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '');

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No: of Rows Deleted by Purge Program: '||SQL%ROWCOUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Purging History Table Failed   '||SQLERRM);
    x_ret_code := 2;

END PURGE_HIST;
/* End of Purge Program */
-- Start of changes for R1.2 Defect 1201 CR 466 - Added the below procedure REPRINT_IND_DOC_WRAP as part of R1.2 Defect# 1201 CR# 466.
-- +===================================================================+
-- | Name : REPRINT_IND_DOC_WRAP                                       |
-- | Description : 1. This is used to submit the individual reprint    |
-- |                 program for each separate transactions in multiple|
-- |                 trx number parameter if customer number is not    |
-- |                 passed.                                           |
-- |               2. If customer number is passed then only one       |
-- |                 Individual reprint program will be submitted even |
-- |                 in case of multiple trx number parameter passed.  |
-- |                                                                   |
-- | Program :OD: AR Invoice Reprint Paper Invoices - Main             |
-- |                                                                   |
-- | Returns  : x_error_buff,x_ret_code                                |
-- +===================================================================+

 PROCEDURE REPRINT_IND_DOC_WRAP ( x_error_buffer            OUT    VARCHAR2
                                 ,x_return_code             OUT    NUMBER
                                 ,p_infocopy_flag           IN     VARCHAR2
                                 ,p_search_by               IN     VARCHAR2
                                 ,p_cust_account_id         IN     NUMBER
                                 ,p_date_from               IN     VARCHAR2
                                 ,p_date_to                 IN     VARCHAR2
                                 ,p_customer_trx_id         IN     NUMBER
                                 ,p_multiple_trx            IN     VARCHAR2
                                 ,p_open_invoices           IN     VARCHAR2
                                 ,p_cust_doc_id             IN     NUMBER
                                 ,p_mbs_document_id         IN     NUMBER
                                 ,p_override_doc_flag       IN     VARCHAR2
                                 ,p_email_option            IN     VARCHAR2
                                 ,p_dummy                   IN     VARCHAR2
                                 ,p_email_address           IN     VARCHAR2
                                 ,p_fax_number              IN     VARCHAR2
                                 ,p_source                  IN     VARCHAR2
                                )
 AS

    CURSOR c_print
    ( cp_request_id     IN    NUMBER )
    IS
    SELECT fcpa.arguments printer,
           fcp.print_style style,
           fcpa.number_of_copies copies,
           fcp.save_output_flag save_output
      FROM fnd_concurrent_requests fcp,
           fnd_conc_pp_actions fcpa
     WHERE fcp.request_id = fcpa.concurrent_request_id
       AND fcpa.action_type = 1   -- printer options
       AND fcpa.status_s_flag = 'Y'
       AND fcp.request_id = cp_request_id
     ORDER BY fcpa.sequence;

     CURSOR c_user_lang IS
    SELECT LOWER(iso_language) user_language,
           iso_territory user_territory
      FROM fnd_languages_vl
     WHERE language_code = FND_GLOBAL.CURRENT_LANGUAGE;

    lc_multi_trans_num VARCHAR2(1000);
    ln_loop            NUMBER;
    ln_instr_len       NUMBER;
    lc_value           VARCHAR2(1000);
    ln_parent_request_id      NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
    ln_request_id      NUMBER;
    TYPE t_print_tab IS TABLE OF c_print%ROWTYPE
    INDEX BY BINARY_INTEGER;
    a_print_tab             t_print_tab;
    v_user_language          VARCHAR2(30)        DEFAULT NULL;
    v_user_territory         VARCHAR2(30)        DEFAULT NULL;
    LC_APPL_SHORT_NAME          CONSTANT VARCHAR2(50)     := 'XXFIN';
    v_xdo_template_code      VARCHAR2(50)     := 'XXARINVSEL';
    LC_XDO_TEMPLATE_FORMAT      CONSTANT VARCHAR2(30)     := 'PDF';
    b_success boolean;

 BEGIN
    OPEN c_print
    ( cp_request_id  => ln_parent_request_id );

     FETCH c_print
     BULK COLLECT
     INTO a_print_tab;
    CLOSE c_print;

     OPEN c_user_lang;
  FETCH c_user_lang
   INTO v_user_language,
        v_user_territory;
  CLOSE c_user_lang;


    IF ((p_cust_account_id IS NOT NULL) OR (p_multiple_trx IS NULL)) THEN

    IF (a_print_tab.COUNT > 0) THEN
      FOR i_index IN a_print_tab.FIRST..a_print_tab.LAST LOOP
        IF (i_index = a_print_tab.FIRST) THEN
          b_success :=
            FND_REQUEST.set_print_options
            ( printer         => a_print_tab(i_index).printer,
              style           => a_print_tab(i_index).style,
              copies          => a_print_tab(i_index).copies,
              save_output     => (a_print_tab(i_index).save_output = 'Y'),
              print_together  => 'N');

   --          ln_number_copies := a_print_tab(i_index).copies;   -- Added for Defect # 12223

        ELSE
          b_success :=
            FND_REQUEST.add_printer
            ( printer         => a_print_tab(i_index).printer,
              copies          => a_print_tab(i_index).copies );
        END IF;
      END LOOP;
    END IF;

   b_success := FND_REQUEST.add_layout
    ( template_appl_name    => LC_APPL_SHORT_NAME,
      template_code         => v_xdo_template_code,
      template_language     => v_user_language,
      template_territory    => v_user_territory,
      output_format         => LC_XDO_TEMPLATE_FORMAT );

       ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                    ,'XXARINVSEL'
                                                    ,NULL
                                                    ,NULL
                                                    ,FALSE
                                                    ,p_infocopy_flag
                                                    ,p_search_by
                                                    ,p_cust_account_id
                                                    ,p_date_from
                                                    ,p_date_to
                                                    ,p_customer_trx_id
                                                    ,p_multiple_trx
                                                    ,p_open_invoices
                                                    ,p_cust_doc_id
                                                    ,p_mbs_document_id
                                                    ,p_override_doc_flag
                                                    ,p_email_option
                                                    ,p_dummy
                                                    ,p_email_address
                                                    ,p_fax_number
                                                    ,p_source
                                                    );
       COMMIT;

    ELSE

       lc_multi_trans_num := p_multiple_trx;

       SELECT LENGTH(lc_multi_trans_num) - LENGTH(TRANSLATE(lc_multi_trans_num,CHR(0)||',',CHR(0)))
       INTO   ln_loop
       FROM   dual;

       ln_loop := ln_loop + 1;

       FOR i IN 1..ln_loop
       LOOP

          SELECT INSTR(lc_multi_trans_num,',')
          INTO   ln_instr_len
          FROM   dual;

          SELECT  SUBSTR(lc_multi_trans_num,1,ln_instr_len-1)
                 ,SUBSTR(lc_multi_trans_num,ln_instr_len+1)
          INTO    lc_value
                 ,lc_multi_trans_num
          FROM  dual;

          IF lc_value IS NULL THEN
             lc_value := lc_multi_trans_num;
          END IF;

          IF (a_print_tab.COUNT > 0) THEN
      FOR i_index IN a_print_tab.FIRST..a_print_tab.LAST LOOP
        IF (i_index = a_print_tab.FIRST) THEN
          b_success :=
            FND_REQUEST.set_print_options
            ( printer         => a_print_tab(i_index).printer,
              style           => a_print_tab(i_index).style,
              copies          => a_print_tab(i_index).copies,
              save_output     => (a_print_tab(i_index).save_output = 'Y'),
              print_together  => 'N');

        ELSE
          b_success :=
            FND_REQUEST.add_printer
            ( printer         => a_print_tab(i_index).printer,
              copies          => a_print_tab(i_index).copies );
        END IF;
      END LOOP;
    END IF;

        b_success := FND_REQUEST.add_layout( template_appl_name    => LC_APPL_SHORT_NAME
                                            ,template_code         => v_xdo_template_code
                                            ,template_language     => v_user_language
                                            ,template_territory    => v_user_territory
                                            ,output_format         => LC_XDO_TEMPLATE_FORMAT
                                            );

          ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                       ,'XXARINVSEL'
                                                       ,NULL
                                                       ,NULL
                                                       ,FALSE
                                                       ,p_infocopy_flag
                                                       ,p_search_by
                                                       ,p_cust_account_id
                                                       ,p_date_from
                                                       ,p_date_to
                                                       ,p_customer_trx_id
                                                       ,lc_value
                                                       ,p_open_invoices
                                                       ,p_cust_doc_id
                                                       ,p_mbs_document_id
                                                       ,p_override_doc_flag
                                                       ,p_email_option
                                                       ,p_dummy
                                                       ,p_email_address
                                                       ,p_fax_number
                                                       ,p_source
                                                       );

          COMMIT;

       END LOOP;

       COMMIT;

    END IF;

 END REPRINT_IND_DOC_WRAP;
-- End of changes for R1.2 Defect 1201 CR 466
END XX_AR_INV_FREQ_PKG;
/
SHOW ERRORS;