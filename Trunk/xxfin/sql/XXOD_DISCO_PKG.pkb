SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY xxod_disco_pkg AS
/******************************************************************************
   NAME:       XXOD_DISCO_PKG
   PURPOSE:
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/9/2007     Michelle Gautier  Created this package body.
   1.1        1/11/2016    Vasu Raparla      Removed Schema References for R.1.2.2
******************************************************************************/
   FUNCTION amw_icm_get_assertions (p_ctrl_rev_id NUMBER)
      RETURN VARCHAR2 IS
/******************************************************************************
   NAME:       AMW_ICM_Get_Assertions
   PURPOSE:    Retrieves existing assretions for the given  control version id,
               and creates output string to display them in one line for the
              OD ICM Risk and Control Matrix/External Review Reports.
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/8/2007     M.Gautier       Created this function for ICM Reports
   NOTES:
   Automatically available Auto Replace Keywords:
      Object Name:     AMW_ICM_Get_Assertions
      Sysdate:         5/8/2007
/******************************************************************************/
      --Select existing assertions for given control
      CURSOR acur IS
         SELECT alo.meaning asst_val
           FROM AMW_LOOKUPS alo, amw_control_assertions aca
          WHERE alo.lookup_type = 'AMW_CONTROL_ASSERTIONS'
            AND aca.assertion_code = alo.lookup_code
            AND aca.control_rev_id = p_ctrl_rev_id;
      l_decode      VARCHAR2 (5);
      x_assertion   VARCHAR2 (60);                 -- assertions output string
      l_sep         VARCHAR2 (3);          -- semicolon to separate assertions
   BEGIN
      x_assertion := NULL;
--decode asserions'values for the given control
      FOR c1 IN acur
      LOOP
         l_decode := NULL;
         DBMS_OUTPUT.put_line (' record is ' || c1.asst_val);
         IF c1.asst_val = 'Accuracy' THEN
            l_decode := ' A ';
         ELSIF c1.asst_val = 'Completeness' THEN
            l_decode := ' C ';
         ELSIF c1.asst_val = 'Cut-off' THEN
            l_decode := ' CO ';
         ELSIF c1.asst_val = 'Existence or Occurrence' THEN
            l_decode := ' E ';
         ELSIF c1.asst_val = 'Presentation' THEN
            l_decode := ' P ';
         ELSIF c1.asst_val = 'Presentation and Disclosure' THEN
            l_decode := ' PD ';
         ELSIF c1.asst_val = 'Recording' THEN
            l_decode := ' RC ';
         ELSIF c1.asst_val = 'Restricted Access' THEN
            l_decode := ' RA ';
         ELSIF c1.asst_val = 'Rights and Obligations' THEN
            l_decode := ' RO ';
         ELSIF c1.asst_val = 'Validity' THEN
            l_decode := ' V ';
         ELSIF c1.asst_val = 'Valuation and Measurement' THEN
            l_decode := ' VM ';
         END IF;
         IF (x_assertion IS NULL OR l_decode IS NULL) THEN
            l_sep := NULL;
         ELSE
            l_sep := ';';
         END IF;
         x_assertion := x_assertion || l_sep || l_decode;
         DBMS_OUTPUT.put_line (' x_assert ' || x_assertion);
      END LOOP;
      RETURN x_assertion;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         NULL;
      WHEN OTHERS THEN
         NULL;
         RAISE;
   END amw_icm_get_assertions;
   FUNCTION get_transaction_id (p_asset_id NUMBER
                            ,p_book_type_code VARCHAR
                            ,p_as_of_date VARCHAR
                            )
RETURN NUMBER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  get_transaction_id                            |
-- | RICE ID          :  R0143                                         |
-- | Description      :  This function is used to derive the max trans |
-- |                     for active assets                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 18-AUG-2007  Sudha            Initial draft version       |
-- |                      Seetharaman           |       -- |                                                                   |
-- +===================================================================+
 IS
ln_trans_number NUMBER;
BEGIN
SELECT MAX(transaction_header_id_in) INTO ln_trans_number
FROM fa_books
WHERE asset_id =p_asset_id
AND book_type_code =p_book_type_code
AND date_effective <=p_as_of_date
AND NVL(date_ineffective,p_as_of_date)+1 > p_as_of_date;
RETURN ln_trans_number;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END get_transaction_id;
FUNCTION get_period_open_date( p_period1 VARCHAR,
                               p_book VARCHAR
                              )
RETURN DATE AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  get_period_open_date                          |
-- | RICE ID          :  R1060,R1061,R0298                             |
-- | Description      :  This function is used to derive the open      |
-- |                     period date                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 18-AUG-2007  Sudha            Initial draft version       |
-- |                      Seetharaman                                  |
-- |DRAFT 1B 03-JUN-2008  Ganesan JV       The Exceptions are handled  |
-- |                                       for defect# 7606            |
-- |                                       Changed for Returning the   |
-- |                                       period open date with time  |
-- +===================================================================+
ld_period_open_date DATE; 
BEGIN
SELECT period_open_date INTO ld_period_open_date
FROM fa_deprn_periods
WHERE book_type_code =p_book
AND period_name =p_period1 ;
/*
  Changed the Return value from 
  RETURN TO_DATE(TO_CHAR(ld_period_open_date,'DD-MON-RR'),'DD-MON-RR');
  for returning the date with time. 
*/
RETURN ld_period_open_date;
EXCEPTION
WHEN NO_DATA_FOUND THEN -- When from date is given that is not opened in the book there should be no data and it comes into this block
   ld_period_open_date := sysdate+1; 
   --RETURN TO_DATE(TO_CHAR(ld_period_open_date,'DD-MON-RR'),'DD-MON-RR');
RETURN ld_period_open_date;
WHEN OTHERS THEN 
   ld_period_open_date := sysdate+1;

   --RETURN TO_DATE(TO_CHAR(ld_period_open_date,'DD-MON-RR'),'DD-MON-RR');
   RETURN ld_period_open_date;

END get_period_open_date;

FUNCTION get_period_close_date( p_period2 VARCHAR,
                               p_book VARCHAR
                              )
RETURN DATE AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  get_period_close_date                         |
-- | RICE ID          :  R1060,R1061,R0298                             |
-- | Description      :  This function is used to period  close date   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 18-AUG-2007  Sudha            Initial draft version       |
-- |                      Seetharaman                                  |
-- |DRAFT 1B 03-JUN-2008  Ganesan JV       The Exceptions are handled  |
-- |                                       for defect# 7606            |
-- |                                       Changed for Returning the   |
-- |                                       period close date with time |
-- +===================================================================+
ld_period_close_date DATE; 
BEGIN
   SELECT NVL(period_close_date,SYSDATE) INTO ld_period_close_date
   FROM fa_deprn_periods
   WHERE book_type_code =p_book
   AND period_name =p_period2 ;

   /*
   Changed the Return value from 
   RETURN TO_DATE(TO_CHAR(ld_period_close_date,'DD-MON-RR'),'DD-MON-RR');
   for returning the date with time. 
   */
   RETURN ld_period_close_date;

EXCEPTION
WHEN NO_DATA_FOUND THEN -- When to date is given that is not opened in the book there should be no data
	BEGIN
   /* When the period-to is not opened then 
      the latest period opened needs to 
      be fetched.
   */
	SELECT NVL(period_close_date,SYSDATE) INTO ld_period_close_date
	FROM fa_deprn_periods
	WHERE book_type_code =p_book
	AND period_counter = (SELECT MAX(period_counter)
                              FROM fa_deprn_periods WHERE book_type_code = p_book);
	--RETURN TO_DATE(TO_CHAR(ld_period_close_date,'DD-MON-RR'),'DD-MON-RR');	 
   RETURN ld_period_close_date;

	EXCEPTION
	WHEN OTHERS THEN
   /* When there is no periods opened in the book.
      It comes to this Block and sysdate will be returned.
   */
	ld_period_close_date := SYSDATE; 
	--RETURN TO_DATE(TO_CHAR(ld_period_close_date,'DD-MON-RR'),'DD-MON-RR');	 
        RETURN ld_period_close_date;
	END;
WHEN OTHERS THEN
	BEGIN
	SELECT NVL(period_close_date,SYSDATE) INTO ld_period_close_date
	FROM fa_deprn_periods
	WHERE book_type_code =p_book
	AND period_counter = (SELECT MAX(period_counter)
									 FROM fa_deprn_periods WHERE book_type_code = p_book); 
	EXCEPTION
	WHEN OTHERS THEN
	ld_period_close_date := SYSDATE;
	--RETURN TO_DATE(TO_CHAR(ld_period_close_date,'DD-MON-RR'),'DD-MON-RR');
        RETURN ld_period_close_date; 
	END;
END get_period_close_date;
 FUNCTION  SHORT_TERM(p_company VARCHAR2
                                 ,p_fiscal_year NUMBER
                                  ,p_lease_number VARCHAR2)
RETURN NUMBER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD FA CAPITAL LEASE ROLLFORWARD SCHEDULE REPORT        |
-- | Rice id  :   R0488                                                  |
-- | Description : Fetch the sum of the payment amount need to be        |
-- |               paid for the next year for particular lease belongs   |
-- |               to an entity                                          |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       17-AUG-2007    Kantharaja Velayutham     Initial version   |
-- |                         Wipro Technologies                          |
-- +=====================================================================+
ln_balance NUMBER;
BEGIN
SELECT                            SUM(FAS.principal) INTO ln_balance
FROM                              fa_leases            FL
                                 ,gl_code_combinations   GCC
                                 ,fa_amort_schedules      FAS
WHERE                            TO_CHAR(FAS.payment_date,'YYYY')     BETWEEN
                                 TO_CHAR(ADD_MONTHS(TO_DATE('01-Jan-' || p_Fiscal_Year),12),'YYYY')
AND                              TO_CHAR(ADD_MONTHS(TO_DATE('31-Dec-' || p_Fiscal_Year),12),'YYYY')
AND                              FL.dist_code_combination_id=GCC.code_combination_id
AND                              FL.fasb_lease_type='CAPITALIZED'
AND                              FAS.payment_schedule_id=FL.payment_schedule_id
AND                              GCC.segment1 LIKE NVL(p_company,gcc.segment1)
AND                               FL.lease_number = p_lease_number;
RETURN ln_balance;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END SHORT_TERM;
 FUNCTION  LONG_TERM(p_company VARCHAR2
                                 ,p_fiscal_year NUMBER
                                  ,p_lease_number VARCHAR2)
RETURN NUMBER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD FA CAPITAL LEASE ROLLFORWARD SCHEDULE REPORT        |
-- | Rice id  :   R0488                                                  |
-- | Description : Fetch the sum of the payment amount need to be        |
-- |              paid for the rest of the years for a particular lease  |
-- |               belongs  to an entity                                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      17-AUG-2007    Kantharaja Velayutham    Initial version     |
-- |                         Wipro Technologies                          |
-- |                                                                     |
-- |2.0      16-OCT-2007    Anusha Ramanujam         Defect ID. 2290     |
-- |                        Wipro Technologies                           |
-- +=====================================================================+
 ln_balance NUMBER;
 BEGIN
 SELECT                   FAS.lease_obligation INTO ln_balance
 FROM                     fa_leases FL
                         ,gl_code_combinations GCC
                         ,fa_amort_schedules FAS
 WHERE                    FAS.payment_date = TO_CHAR(ADD_MONTHS(TO_DATE('01-Jan-' ||p_Fiscal_Year),23),'DD-MON-YY')     --Changed by Anusha for defect# 2290
 AND                      FL.dist_code_combination_id=GCC.code_combination_id
 AND                      FL.fasb_lease_type='CAPITALIZED'
 AND                      FAS.payment_schedule_id=FL.payment_schedule_id
 AND                     GCC.segment1 LIKE NVL(p_Company,GCC.segment1)      --Replaced '=' with 'LIKE' by Anusha for defect# 2290
AND                      FL.lease_number= p_lease_number;
 RETURN ln_balance;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END LONG_TERM;
FUNCTION    CUR_YEAR(p_company VARCHAR2
                                              ,p_fiscal_year NUMBER
                                             ,p_lease_number VARCHAR2)
RETURN NUMBER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD FA CAPITAL LEASE ROLLFORWARD SCHEDULE REPORT        |
-- | Rice id  :   R0488                                                  |
-- | Description : Fetch the sum of the payment amount need to be        |
-- |              paid for the current year for a particular lease       |
-- |               belongs  to an entity                                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       17-AUG-2007    Kantharaja Velayutham     Initial version   |
-- |                         Wipro Technologies                          |
-- +=====================================================================+
ln_balance NUMBER;
BEGIN
SELECT
                                  SUM(FAS.payment_amount) INTO ln_balance
FROM                              fa_leases  FL
                                 ,gl_code_combinations GCC
                                 ,fa_amort_schedules FAS
WHERE                            TO_CHAR(FAS.payment_date,'YYYY') BETWEEN
                                 TO_CHAR(TO_DATE('01-Jan-' ||p_Fiscal_Year ),'YYYY')
AND                              TO_CHAR(TO_DATE('31-Dec-' ||p_Fiscal_Year),'YYYY')
AND                              FL.dist_code_combination_id=GCC.code_combination_id
AND                              FAS.payment_schedule_id=FL.payment_schedule_id
AND                              FL.FASB_LEASE_TYPE='CAPITALIZED'
AND                              GCC.segment1 LIKE NVL(p_Company,gcc.segment1)
AND                              FL.lease_number = TO_CHAR(p_lease_number);
RETURN ln_balance;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END CUR_YEAR;
FUNCTION    CUR_PRL(p_company VARCHAR2
                         ,p_fiscal_year NUMBER
                         ,p_lease_number VARCHAR2)
RETURN NUMBER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD FA CAPITAL LEASE ROLLFORWARD SCHEDULE REPORT        |
-- | Rice id  :   R0488                                                  |
-- | Description : Fetch the sum of the principal amount need to be      |
-- |               paid for the current year for a particular lease      |
-- |               belongs  to an entity                                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      03-OCT-2007     Anusha Ramanujam     Defect ID. 2290        |
-- |                                                                     |
-- +=====================================================================+
ln_principal     NUMBER;
BEGIN
SELECT
                                  SUM(FAS.principal) INTO ln_principal
FROM                              fa_leases  FL
                                 ,gl_code_combinations GCC
                                 ,fa_amort_schedules FAS
WHERE                            TO_CHAR(FAS.payment_date,'YYYY') BETWEEN
                                 TO_CHAR(TO_DATE('01-Jan-' ||p_Fiscal_Year ),'YYYY')
AND                              TO_CHAR(TO_DATE('31-Dec-' ||p_Fiscal_Year),'YYYY')
AND                              FL.dist_code_combination_id=GCC.code_combination_id
AND                              FAS.payment_schedule_id=FL.payment_schedule_id
AND                              FL.FASB_LEASE_TYPE='CAPITALIZED'
AND                              GCC.segment1 LIKE NVL(p_Company,gcc.segment1)
AND                              FL.lease_number = TO_CHAR(p_lease_number);
RETURN ln_principal;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END CUR_PRL;
FUNCTION    CUR_INT(p_company VARCHAR2
                         ,p_fiscal_year NUMBER
                         ,p_lease_number VARCHAR2)
RETURN NUMBER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD FA CAPITAL LEASE ROLLFORWARD SCHEDULE REPORT        |
-- | Rice id  :   R0488                                                  |
-- | Description : Fetch the sum of  interest need to be                 |
-- |               paid for the current year for a particular lease      |
-- |               belongs  to an entity                                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      03-OCT-2007     Anusha Ramanujam     Defect ID. 2290        |
-- |                                                                     |
-- +=====================================================================+
ln_interest     NUMBER;
BEGIN
SELECT
                                  SUM(FAS.interest) INTO ln_interest
FROM                              fa_leases  FL
                                 ,gl_code_combinations GCC
                                 ,fa_amort_schedules FAS
WHERE                            TO_CHAR(FAS.payment_date,'YYYY') BETWEEN
                                 TO_CHAR(TO_DATE('01-Jan-' ||p_Fiscal_Year ),'YYYY')
AND                              TO_CHAR(TO_DATE('31-Dec-' ||p_Fiscal_Year),'YYYY')
AND                              FL.dist_code_combination_id=GCC.code_combination_id
AND                              FAS.payment_schedule_id=FL.payment_schedule_id
AND                              FL.FASB_LEASE_TYPE='CAPITALIZED'
AND                              GCC.segment1 LIKE NVL(p_Company,gcc.segment1)
AND                              FL.lease_number = TO_CHAR(p_lease_number);
RETURN ln_interest;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END CUR_INT;
FUNCTION get_financial_year_amt(p_company VARCHAR2, p_state VARCHAR2,p_gl_date DATE)
RETURN NUMBER  IS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD AR GROSS SALE DESTINATION BY STATE                  |
-- | Rice id  :   R1066                                                  |
-- | Description : Fetch the sum of the gross sale for the particular    |
-- |               finnancial year                                       |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       21-AUG-2007    Sree Hari                Initial version    |
-- |2.0       20-SEP-2007    Shabbar Hasan            Defect No. 1758    |
-- |3.0       11-Jan-2007    Christina S              Defect No. 3498    |
-- |4.0       26-Jun-2008    Ganesan JV               Defect No. 8206    |
-- +=====================================================================+
ln_total_famount NUMBER;
ln_famount       NUMBER;
ln_adj_amount    NUMBER;
ld_yr_date       DATE;
BEGIN

SELECT TRUNC(p_gl_date,'YYYY') INTO ld_yr_date -- Removed TO_DATE() fn. by Ganesan for defect 8206
FROM DUAL;
ln_famount := 0; -- Initialising the Variables.
ln_adj_amount := 0;
IF (p_company IS NOT NULL) AND (p_state IS NOT NULL) THEN
   For Inv_cur IN (SELECT /*+ NO_USE_NL(RCTA RCTGL HCSU HCAS HPS HL) FULL(GCC) FULL(HL) FULL(TYPES) ORDERED PARALLEL(RCTA,4) PARALLEL(RCTGL,4) PARALLEL(HCSU,4) PARALLEL(HCAS,4) PARALLEL(HPS,4) PARALLEL(HL,4) */
                 SUM(RCTGL.acctd_amount) acctd_amount -- Changed by Ganesan for improving performance for defect 8206
            FROM hz_party_sites HPS
               ,hz_locations HL
               ,HZ_CUST_ACCT_SITES HCAS
               --,RA_CUSTOMER_TRX_LINES RCTL -- Commented by Ganesan for improving performance for defect 8206
               ,HZ_CUST_SITE_USES HCSU
               ,RA_CUSTOMER_TRX RCTA
               ,RA_CUST_TRX_LINE_GL_DIST RCTGL
               ,gl_code_combinations GCC
               ,RA_CUST_TRX_TYPES  types
            WHERE  HPS.location_id = HL.location_id
               AND HPS.party_site_id = HCAS.party_site_id
               AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
               --AND RCTL.customer_trx_line_id = RCTGL.customer_trx_line_id-- Commented by Ganesan for improving performance for defect 8206
               --AND RCTA.customer_trx_id=RCTL.customer_trx_id-- Commented by Ganesan for improving performance for defect 8206
               AND NVL(RCTA.ship_to_site_use_id,RCTA.bill_to_site_use_id) = HCSU.site_use_id
               AND RCTA.customer_trx_id = RCTGL.customer_trx_id
               AND RCTGL.code_combination_id= GCC.code_combination_id
               AND RCTGL.account_class='REV'
               AND RCTA.cust_trx_type_id = TYPES.cust_trx_type_id
               AND TYPES.TYPE IN ( 'CM', 'INV', 'DM' )
               --AND RCTA.invoice_currency_code ='USD'               --Commented this condition for defect no. 1758
               AND RCTA.complete_flag = 'Y'                          --Added this condition for defect no. 1758
               AND GCC.segment1 = p_company -- Changed by Ganesan for improving performance for defect 8206 NVL(p_company,'%')  -- Changed for defect no.3498
               AND HL.state = p_state -- Changed by Ganesan for improving performance for defect 8206 NVL(p_state,'%')        -- Changed for defect no.3498
               AND RCTGL.gl_date BETWEEN ld_yr_date AND p_gl_date)
   Loop
    ln_famount := Inv_cur.acctd_amount; -- Changed by Ganesan for improving performance for defect 8206
   End Loop;
   -- This query is added for defect no. 1758
   For Adj_Cur in (SELECT SUM(AD.acctd_amount) acctd_amount -- Changed by Ganesan for improving performance for defect 8206
             FROM AR_ADJUSTMENTS AD,
                RA_CUSTOMER_TRX RCTA,
               gl_code_combinations GCC,
                    HZ_CUST_SITE_USES HCSU,
                   HZ_CUST_ACCT_SITES HCAS,
                   hz_party_sites HPS,
                   hz_locations HL
                   --AR_PAYMENT_SCHEDULES APS
            WHERE  AD.customer_trx_id = RCTA.customer_trx_id
            --AND  AD.payment_schedule_id = APS.payment_schedule_id
              AND  HCSU.site_use_id=NVL(RCTA.ship_to_site_use_id, RCTA.bill_to_site_use_id)
              AND  HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
              AND  HCAS.party_site_id = HPS.party_site_id
              AND  HPS.location_id = HL.location_id
              AND  GCC.code_combination_id = (SELECT RCTGL.code_combination_id
                                              FROM  RA_CUST_TRX_LINE_GL_DIST RCTGL
                                              WHERE RCTGL.customer_trx_id = RCTA.customer_trx_id
                                                AND RCTGL.account_class='REV'
                                                AND rownum<2)
              AND  AD.chargeback_customer_trx_id IS NULL
              AND  AD.approved_by IS NOT NULL
              AND  AD.STATUS ='A'
              AND  RCTA.complete_flag='Y'
              AND  GCC.segment1 = p_company -- Changed by Ganesan for improving performance for defect 8206 NVL(p_company,'%')  -- Changed for defect no.3498
              AND  HL.state = p_state -- Changed by Ganesan for improving performance for defect 8206 NVL(p_state,'%')        -- Changed for defect no.3498
              AND  AD.gl_date  BETWEEN ld_yr_date AND p_gl_date
            )
   Loop
      ln_adj_amount := adj_cur.acctd_amount; -- Changed by Ganesan for improving performance for defect 8206
   End Loop;
END IF;
ln_total_famount := NVL(ln_famount,0) + NVL(ln_adj_amount,0);
RETURN ln_total_famount;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END get_financial_year_amt;
FUNCTION get_financial_qurtr_amt(p_company VARCHAR2, p_state VARCHAR2,p_gl_date DATE )
RETURN NUMBER  AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name     :   OD AR GROSS SALE DESTINATION BY STATE                  |
-- | Rice id  :   R1066                                                  |
-- | Description : Fetch the sum of the gross sale for the particular    |
-- |               quarter                                               |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       21-AUG-2007    Sree Hari                Initial version    |
-- |2.0       20-SEP-2007    Shabbar Hasan            Defect No. 1758    |
-- |3.0       11-Jan-2007    Christina S              Defect No. 3498    |
-- |4.0       26-Jun-2008    Ganesan JV               Defect No. 8206    |
-- +=====================================================================+
ln_total_qamount NUMBER;
ln_qamount       NUMBER;
ln_adj_amount    NUMBER;
ld_qt_date       DATE;

BEGIN
SELECT TRUNC(p_gl_date,'Q') INTO ld_qt_date -- Removed TO_DATE() fn. by Ganesan for defect 8206
FROM DUAL;
/* Added by Ganesan for improving the performance for defect 8206.*/
ln_qamount:=0; -- Initialising the variables.
ln_adj_amount:=0;
IF (p_company IS NOT NULL) AND (p_state IS NOT NULL) THEN
   For Inv_cur IN (SELECT /*+ NO_USE_NL(RCTA RCTGL HCSU HCAS HPS HL) FULL(GCC) FULL(HL) FULL(TYPES) ORDERED PARALLEL(RCTA,4) PARALLEL(RCTGL,4) PARALLEL(HCSU,4) PARALLEL(HCAS,4) PARALLEL(HPS,4) PARALLEL(HL,4) */
                   sum(RCTGL.acctd_amount) acctd_amount                   -- Changed by Ganesan for improving performance for defect 8206                   
            FROM  hz_party_sites HPS
               ,hz_locations HL
               ,HZ_CUST_ACCT_SITES HCAS
               --,RA_CUSTOMER_TRX_LINES RCTL
               ,HZ_CUST_SITE_USES HCSU
               ,RA_CUSTOMER_TRX RCTA
               ,RA_CUST_TRX_LINE_GL_DIST RCTGL
               ,gl_code_combinations GCC
               ,RA_CUST_TRX_TYPES  types
            WHERE HPS.location_id = HL.location_id
               AND HPS.party_site_id = HCAS.party_site_id
               AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
               --AND RCTL.customer_trx_line_id = RCTGL.customer_trx_line_id-- Commented by Ganesan for improving performance for defect 8206
               --AND RCTA.customer_trx_id=RCTL.customer_trx_id-- Commented by Ganesan for improving performance for defect 8206
               AND NVL(RCTA.ship_to_site_use_id,RCTA.bill_to_site_use_id) = HCSU.site_use_id
               AND RCTA.customer_trx_id = RCTGL.customer_trx_id
               AND RCTGL.code_combination_id=gcc.code_combination_id
               AND RCTGL.account_class='REV'
               AND RCTA.cust_trx_type_id = TYPES.cust_trx_type_id
               AND TYPES.TYPE IN ( 'CM', 'INV', 'DM' )
            --AND RCTA.invoice_currency_code ='USD'  --Commented this condition for defect no. 1758
               AND RCTA.complete_flag = 'Y'             --Added this condition for defect no. 1758
               AND GCC.segment1 = p_company -- Changed by Ganesan for improving performance for defect 8206 NVL(p_company,'%')  -- Changed for defect no.3498
               AND HL.state = p_state -- Changed by Ganesan for improving performance for defect 8206 NVL(p_state,'%')        -- Changed for defect no.3498
               AND RCTGL.gl_date BETWEEN ld_qt_date AND p_gl_date)
   Loop
   ln_qamount :=Inv_cur.acctd_amount; -- Changed by Ganesan for improving performance for defect 8206
   End Loop;
   -- This query is added for defect no. 1758
   For Adj_Cur in (SELECT sum(AD.acctd_amount) acctd_amount -- Changed by Ganesan for improving performance for defect 8206                   
             FROM AR_ADJUSTMENTS AD,
                RA_CUSTOMER_TRX RCTA,
               gl_code_combinations GCC,
                    HZ_CUST_SITE_USES HCSU,
                   HZ_CUST_ACCT_SITES HCAS,
                   hz_party_sites HPS,
                   hz_locations HL
                   --AR_PAYMENT_SCHEDULES APS
            WHERE  AD.customer_trx_id = RCTA.customer_trx_id
            --AND    AD.payment_schedule_id = APS.payment_schedule_id
            AND    HCSU.site_use_id=NVL(RCTA.ship_to_site_use_id, RCTA.bill_to_site_use_id)
            AND    HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
            AND    HCAS.party_site_id = HPS.party_site_id
            AND    HPS.location_id = HL.location_id
            AND    GCC.code_combination_id = (SELECT RCTGL.code_combination_id
                     FROM  RA_CUST_TRX_LINE_GL_DIST RCTGL
                       WHERE RCTGL.customer_trx_id = RCTA.customer_trx_id
                       AND   RCTGL.account_class='REV'
                       AND rownum<2)
            AND    AD.chargeback_customer_trx_id IS NULL
            AND    AD.approved_by IS NOT NULL
            AND    AD.STATUS ='A'
            AND    RCTA.complete_flag='Y'
            AND    GCC.segment1 = p_company -- Changed by Ganesan for improving performance for defect 8206 NVL(p_company,'%')  -- Changed for defect no.3498
            AND    HL.state = p_state -- Changed by Ganesan for improving performance for defect 8206 NVL(p_state,'%')        -- Changed for defect no.3498
            AND    AD.gl_date BETWEEN ld_qt_date AND p_gl_date
            )
   Loop
      ln_adj_amount:= adj_cur.acctd_amount; -- Changed by Ganesan for improving performance for defect 8206
   End Loop;
END IF;
ln_total_qamount := NVL(ln_qamount,0) + NVL(ln_adj_amount,0);
RETURN ln_total_qamount;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN NULL;
WHEN TOO_MANY_ROWS THEN
   RETURN NULL;
END get_financial_qurtr_amt;
END xxod_disco_pkg;
/
sho err