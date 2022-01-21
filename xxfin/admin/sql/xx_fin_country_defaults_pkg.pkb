CREATE OR REPLACE PACKAGE BODY xx_fin_country_defaults_pkg IS
  /**********************************************************************************
   NAME:       xx_fin_country_defaults_pkg
   PURPOSE:    This package returns country default values based on the OD_COUNTRY_DEFAULTS
               translation.

   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     15-OCT-2007 Greg Dill, Providge Consulting, LLC. Created base version.
  -- 1.1     22-JUL-2013 Veronica M                           I1141 - Modified for R12 Upgrade Retrofit.
  **********************************************************************************/
  gc_error_message    VARCHAR2(250);
  gc_source_value2    xx_fin_translatevalues.source_value2%TYPE;
  gc_source_value3    xx_fin_translatevalues.source_value3%TYPE;
  gc_source_value4    xx_fin_translatevalues.source_value4%TYPE;
  gc_source_value5    xx_fin_translatevalues.source_value5%TYPE;
  gc_source_value6    xx_fin_translatevalues.source_value6%TYPE;
  gc_source_value7    xx_fin_translatevalues.source_value7%TYPE;
  gc_source_value8    xx_fin_translatevalues.source_value8%TYPE;
  gc_source_value9    xx_fin_translatevalues.source_value9%TYPE;
  gc_source_value10   xx_fin_translatevalues.source_value10%TYPE;
  gc_target_value1    xx_fin_translatevalues.target_value1%TYPE;
  gc_target_value2    xx_fin_translatevalues.target_value2%TYPE;
  gc_target_value3    xx_fin_translatevalues.target_value3%TYPE;
  gc_target_value4    xx_fin_translatevalues.target_value4%TYPE;
  gc_target_value5    xx_fin_translatevalues.target_value5%TYPE;
  gc_target_value6    xx_fin_translatevalues.target_value6%TYPE;
  gc_target_value7    xx_fin_translatevalues.target_value7%TYPE;
  gc_target_value8    xx_fin_translatevalues.target_value8%TYPE;
  gc_target_value9    xx_fin_translatevalues.target_value9%TYPE;
  gc_target_value10   xx_fin_translatevalues.target_value10%TYPE;
  gc_target_value11   xx_fin_translatevalues.target_value11%TYPE;
  gc_target_value12   xx_fin_translatevalues.target_value12%TYPE;
  gc_target_value13   xx_fin_translatevalues.target_value13%TYPE;
  gc_target_value14   xx_fin_translatevalues.target_value14%TYPE;
  gc_target_value15   xx_fin_translatevalues.target_value15%TYPE;
  gc_target_value16   xx_fin_translatevalues.target_value16%TYPE;
  gc_target_value17   xx_fin_translatevalues.target_value17%TYPE;
  gc_target_value18   xx_fin_translatevalues.target_value18%TYPE;
  gc_target_value19   xx_fin_translatevalues.target_value19%TYPE;
  gc_target_value20   xx_fin_translatevalues.target_value20%TYPE;
  gc_translation_name xx_fin_translatedefinition.translation_name%TYPE := 'OD_COUNTRY_DEFAULTS';
  gn_org_id           hr_operating_units.organization_id%TYPE;
  --gn_set_of_books_id  gl_sets_of_books.set_of_books_id%TYPE;       
  gn_set_of_books_id  gl_ledgers.ledger_id%TYPE;                     --Commented/Added by Veronica for R12 Retrofit Upgrade on 22 July,2013   

  --Procedure to translate the country to all out values
  PROCEDURE p_all_values (p_country IN VARCHAR2,
                          p_trx_date IN DATE DEFAULT SYSDATE,
                          x_sob_short_name IN OUT VARCHAR2,
                          x_operating_unit_name IN OUT VARCHAR2,
                          x_currency_code IN OUT VARCHAR2,
                          x_coa_name IN OUT VARCHAR2,
                          x_error_message IN OUT VARCHAR2,
                          x_set_of_books_id IN OUT NUMBER,
                          x_org_id IN OUT NUMBER) IS
  BEGIN
    xx_fin_translate_pkg.xx_fin_translatevalue_proc (p_translation_name => gc_translation_name,
                                                     p_trx_date => p_trx_date,
                                                     p_source_value1 => p_country,
                                                     p_source_value2 => gc_source_value2,
                                                     p_source_value3 => gc_source_value3,
                                                     p_source_value4 => gc_source_value4,
                                                     p_source_value5 => gc_source_value5,
                                                     p_source_value6 => gc_source_value6,
                                                     p_source_value7 => gc_source_value7,
                                                     p_source_value8 => gc_source_value8,
                                                     p_source_value9 => gc_source_value9,
                                                     p_source_value10 => gc_source_value10,
                                                     x_target_value1 => x_sob_short_name,
                                                     x_target_value2 => x_operating_unit_name,
                                                     x_target_value3 => x_currency_code,
                                                     x_target_value4 => x_coa_name,
                                                     x_target_value5 => gc_target_value5,
                                                     x_target_value6 => gc_target_value6,
                                                     x_target_value7 => gc_target_value7,
                                                     x_target_value8 => gc_target_value8,
                                                     x_target_value9 => gc_target_value9,
                                                     x_target_value10 => gc_target_value10,
                                                     x_target_value11 => gc_target_value11,
                                                     x_target_value12 => gc_target_value12,
                                                     x_target_value13 => gc_target_value13,
                                                     x_target_value14 => gc_target_value14,
                                                     x_target_value15 => gc_target_value15,
                                                     x_target_value16 => gc_target_value16,
                                                     x_target_value17 => gc_target_value17,
                                                     x_target_value18 => gc_target_value18,
                                                     x_target_value19 => gc_target_value19,
                                                     x_target_value20 => gc_target_value20,
                                                     x_error_message => x_error_message);

    /* If lookup was successful */
    IF x_error_message IS NULL THEN
      /* Retrieve the org_id */
      BEGIN
        SELECT organization_id
        INTO x_org_id
        FROM hr_operating_units
        WHERE NAME = x_operating_unit_name;

      EXCEPTION
        WHEN OTHERS THEN
          x_org_id := -1;
      END; 

      /* Retrieve the set_of_books_id */
      BEGIN
        SELECT --set_of_books_id
		         ledger_id                         --Commented/Added by Veronica for R12 Retrofit Upgrade on 22 July,2013
        INTO x_set_of_books_id
        FROM -- gl_sets_of_books
		        gl_ledgers                        --Commented/Added by Veronica for R12 Retrofit Upgrade on 22 July,2013
        WHERE short_name = x_sob_short_name;

      EXCEPTION
        WHEN OTHERS THEN
          x_set_of_books_id := -1;
      END; 

    ELSE
      x_org_id := -1;
      x_set_of_books_id := -1;
    END IF;

  END p_all_values;

  --Function to translate the country to set_of_books_id
  FUNCTION f_set_of_books_id (p_country IN VARCHAR2 DEFAULT NULL,
                              p_trx_date IN DATE DEFAULT SYSDATE) RETURN NUMBER IS
  BEGIN
    p_all_values (p_country => p_country,
                  p_trx_date => p_trx_date,
                  x_sob_short_name => gc_target_value1,
                  x_operating_unit_name => gc_target_value2,
                  x_currency_code => gc_target_value3,
                  x_coa_name => gc_target_value4,
                  x_error_message => gc_error_message,
                  x_set_of_books_id => gn_set_of_books_id,
                  x_org_id => gn_org_id);

    /* Return the set_of_books_id */
    RETURN gn_set_of_books_id;
  END f_set_of_books_id;

  --Function to translate the country to org_id
  FUNCTION f_org_id (p_country IN VARCHAR2 DEFAULT NULL,
                     p_trx_date IN DATE DEFAULT SYSDATE) RETURN NUMBER IS
  BEGIN
    p_all_values (p_country => p_country,
                  p_trx_date => p_trx_date,
                  x_sob_short_name => gc_target_value1,
                  x_operating_unit_name => gc_target_value2,
                  x_currency_code => gc_target_value3,
                  x_coa_name => gc_target_value4,
                  x_error_message => gc_error_message,
                  x_set_of_books_id => gn_set_of_books_id,
                  x_org_id => gn_org_id);

    /* Return the set_of_books_id */
    RETURN gn_org_id;
  END f_org_id;

END xx_fin_country_defaults_pkg;
/
