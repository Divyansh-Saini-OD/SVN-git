CREATE OR REPLACE PACKAGE xx_fin_country_defaults_pkg AS
  /**********************************************************************************
   NAME:       xx_fin_country_defaults_pkg
   PURPOSE:    This package returns country default values based on the OD_COUNTRY_DEFAULTS
               translation.

   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     15-OCT-2007 Greg Dill, Providge Consulting, LLC. Created base version.
  **********************************************************************************/
  --Procedure to translate the country to all out values
  PROCEDURE p_all_values (p_country IN VARCHAR2,
                          p_trx_date IN DATE DEFAULT SYSDATE,
                          x_sob_short_name IN OUT VARCHAR2,
                          x_operating_unit_name IN OUT VARCHAR2,
                          x_currency_code IN OUT VARCHAR2,
                          x_coa_name IN OUT VARCHAR2,
                          x_error_message IN OUT VARCHAR2,
                          x_set_of_books_id IN OUT NUMBER,
                          x_org_id IN OUT NUMBER);

  --Function to translate the country to set_of_books_id
  FUNCTION f_set_of_books_id (p_country IN VARCHAR2 DEFAULT NULL,
                              p_trx_date IN DATE DEFAULT SYSDATE) RETURN NUMBER;

  --Function to translate the country to org_id
  FUNCTION f_org_id (p_country IN VARCHAR2 DEFAULT NULL,
                     p_trx_date IN DATE DEFAULT SYSDATE) RETURN NUMBER;

END xx_fin_country_defaults_pkg;
/
