create or replace PACKAGE xxod_disco_pkg AS
/******************************************************************************
   NAME:       XXOD_DISCO_PKG
   PURPOSE:    Contains Functions and Procedures used by Discoverer Reports
              1. AMW_ICM_Get_Assertions
              2. GET_TRANSACTION_ID

   REVISIONS:
   Ver        Date        Author            Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/9/2007    Michelle Gautier  Created this package.
   1.1        8/18/2007   Sudha             Added the function get_transaction_id
                                            get_period_open_date and
                                            get_period_close_date

   1.2        8/27/2007   Sreehari          Added the function get_financial_year_amt
                                            and get_financial_qurtr_amt

   1.3        9/28/2007   Anusha Ramanujam  Added the functions cur_int and cur_prl

******************************************************************************/
   FUNCTION amw_icm_get_assertions (p_ctrl_rev_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_transaction_id (
      p_asset_id         NUMBER
    , p_book_type_code   VARCHAR
    , p_as_of_date       VARCHAR
   )
      RETURN NUMBER;

   FUNCTION get_period_open_date (p_period1 VARCHAR, p_book VARCHAR)
      RETURN DATE;

   FUNCTION get_period_close_date (p_period2 VARCHAR, p_book VARCHAR)
      RETURN DATE;

   FUNCTION short_term (
      p_company        VARCHAR2
    , p_fiscal_year    NUMBER
    , p_lease_number   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION long_term (
      p_company        VARCHAR2
    , p_fiscal_year    NUMBER
    , p_lease_number   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION cur_year (
      p_company        VARCHAR2
    , p_fiscal_year    NUMBER
    , p_lease_number   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION cur_int(
      p_company       VARCHAR2
     ,p_fiscal_year   NUMBER
     ,p_lease_number  VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION cur_prl(
      p_company       VARCHAR2
     ,p_fiscal_year   NUMBER
     ,p_lease_number  VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION get_financial_year_amt (
      p_company   VARCHAR2
    , p_state     VARCHAR2
    , p_gl_date   DATE
   )
      RETURN NUMBER;

   FUNCTION get_financial_qurtr_amt (
      p_company   VARCHAR2
    , p_state     VARCHAR2
    , p_gl_date   DATE
   )
      RETURN NUMBER;
END xxod_disco_pkg;
/


