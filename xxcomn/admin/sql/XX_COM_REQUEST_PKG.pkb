create or replace
PACKAGE BODY XX_COM_REQUEST_PKG AS

TYPE ARG_ARRAY_TYPE IS VARRAY(100) OF VARCHAR2(240);                  -- 100 arg values passed to fnd_request api
TYPE VAR_ARRAY_TYPE IS TABLE OF VARCHAR2(240) INDEX BY VARCHAR2(100); -- associative array of name/val pairs
                                                                      -- and then augmented with current arg values for Segment default types (A)
TYPE VALUE_SET_REC_TYPE IS RECORD (recvalue VARCHAR2(240)
                                  ,meaning  VARCHAR2(2000)
                                  ,id       VARCHAR2(100));

TYPE SQL_TEXT_TYPE IS TABLE OF VARCHAR2(32767) INDEX BY VARCHAR2(100); -- associative array of sql for dynamic execution



-- ===========================================================================
-- procedure for printing to the output
-- ===========================================================================
PROCEDURE PUT_OUT_LINE (
   p_buffer     IN  VARCHAR2 := ' '
) IS
BEGIN
  -- if in concurrent program, print to output file
--  IF (FND_GLOBAL.conc_request_id > 0) THEN -- fnd_global.conc_request_id gets reset when apps_initialize is called to set context
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
--  ELSE
--    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
--  END IF;
END PUT_OUT_LINE;


-- ===========================================================================
-- procedure for printing to the log
-- ===========================================================================
PROCEDURE PUT_LOG_LINE (
  p_buffer     IN      VARCHAR2      DEFAULT ' '
) IS
BEGIN
  -- if in concurrent program, write to log file
--  IF (FND_GLOBAL.conc_request_id > 0) THEN -- fnd_global.conc_request_id gets reset when apps_initialize is called to set context
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
--  ELSE
--    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
--    XX_COM_ERROR_LOG_PUB.log_error(p_module_name => 'ESP', p_error_message => p_buffer);
--  END IF;
END PUT_LOG_LINE;


PROCEDURE PUT_ERR_LINE (
  ls_esp_job_name IN VARCHAR2
 ,ls_esp_job_qual IN VARCHAR2
 ,p_buffer        IN VARCHAR2 := ' '
) IS
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'ESP'
                                ,p_program_name  => 'XX_COM_REQUEST_PKG'
                                ,p_attribute1    => ls_esp_job_name
                                ,p_attribute2    => ls_esp_job_qual
                                ,p_error_message => p_buffer);
END;


FUNCTION DECODE_BOOLEAN(
  ps_value IN VARCHAR2
) RETURN BOOLEAN
IS
BEGIN
  IF INSTR('YT1',UPPER(SUBSTR(NVL(ps_value,'N'),1,1)))>0 THEN
     RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;

-- ===========================================================================
-- function GET_TRANSLATION_ID looks up the translation id by name
-- =========================================================================== 
FUNCTION GET_TRANSLATION_ID(
    p_translation_name IN VARCHAR2
) RETURN xx_fin_translatedefinition.translate_id%TYPE
IS
    v_translate_id XX_FIN_TRANSLATEDEFINITION.translate_id%TYPE;
    p_trx_date     DATE := TRUNC(SYSDATE);
BEGIN
    SELECT translate_id
      INTO v_translate_id
      FROM XX_FIN_TRANSLATEDEFINITION
     WHERE translation_name = p_translation_name
       AND enabled_flag = 'Y'
       AND (    start_date_active <= p_trx_date
            AND (end_date_active >= p_trx_date OR end_date_active IS NULL)
           );
    RETURN v_translate_id;   
END GET_TRANSLATION_ID;

-- ===========================================================================
-- function GET_TRANSLATION_ID looks for a translation id whose name is a
-- combination of the base translation name and job name.  
-- If not found, it falls back to the base translation.
-- =========================================================================== 
FUNCTION GET_TRANSLATION_ID(
  p_translation_name IN VARCHAR2
 ,p_esp_job_name     IN VARCHAR2
)
RETURN xx_fin_translatedefinition.translate_id%TYPE
IS
  v_translate_id XX_FIN_TRANSLATEDEFINITION.translate_id%TYPE;
  p_trx_date     DATE := SYSDATE;
BEGIN
  v_translate_id := GET_TRANSLATION_ID(REPLACE(p_translation_name,'COMN',SUBSTR(p_esp_job_name,1,4)));
  RETURN v_translate_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    v_translate_id := GET_TRANSLATION_ID(p_translation_name);
    RETURN v_translate_id;
END GET_TRANSLATION_ID;


-- FORWARD DECLARATION
FUNCTION EXPLODE_ARGS (
   p_vars      IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_string    IN     VARCHAR2
  ,p_delimiter IN     VARCHAR2 := ',' 
)RETURN ARG_ARRAY_TYPE;
-- FORWARD DECLARATION
FUNCTION DEFAULT_ARG_VAL(p_vars            IN OUT NOCOPY VAR_ARRAY_TYPE
                        ,p_args_for_dynsql IN OUT NOCOPY ARG_ARRAY_TYPE
                        ,p_default_type    IN VARCHAR2
                        ,p_default_value   IN VARCHAR2
                        ,p_bind_cdl        IN VARCHAR2)
RETURN VARCHAR2;
-- FORWARD DECLARATION
PROCEDURE ADD_VAR (
   p_vars IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_n    IN     VARCHAR2
  ,p_v    IN     VARCHAR2
);


-- ===========================================================================
-- function RESOLVE_ARG substitutes arg value with value from associative
--   array, if present.  E.G., if p_arg='!XYZ', return value would be 
--   p_variables('!XYZ'), if it is in the array.
-- 
--   This function will fall back to value found in xx_fin_translatevalues.
-- =========================================================================== 
FUNCTION RESOLVE_ARG (
   p_vars        IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_arg         IN VARCHAR2
)
RETURN VARCHAR2
IS
  ls_arg            VARCHAR2(100) := UPPER(p_arg);
  ls_dynval         VARCHAR2(100);
--  ls_job_name       VARCHAR2(100);
  lsa_vset_args     ARG_ARRAY_TYPE := NULL;
  ls_default_type   XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
  ls_default_value  XX_FIN_TRANSLATEVALUES.target_value2%TYPE;
  ls_bind_values    XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
  ln_translation_id NUMBER;
  ld_sysdate        DATE := TRUNC(SYSDATE);
BEGIN
  IF p_vars.EXISTS(ls_arg) THEN
    RETURN p_vars(ls_arg);
  END IF;

  IF SUBSTR(NVL(ls_arg,' '),1,1) <> '!' THEN
    RETURN p_arg;
  END IF;

--  ls_job_name := p_vars('!XX_ESP_JOB_NAME');

  ln_translation_id := p_vars('!XX_ARG_DEF_TRANSLATION_ID');
  BEGIN   -- uncomment this block if variables are needed that apply to a specific jobname but any jobqualifier 
          --    (overridding the catch-all variables of the following query)
--  SELECT target_value1 default_type, target_value2 default_value, target_value3 bind_values
--    INTO ls_default_type, ls_default_value, ls_bind_values
--    FROM XX_FIN_TRANSLATEVALUES
--   WHERE translate_id  = ln_translation_id
--     AND source_value1 = ls_job_name
--     AND source_value2 = '%'
--     AND UPPER(source_value3) = ls_arg
--     AND enabled_flag  = 'Y'
--     AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate);

--  EXCEPTION WHEN NO_DATA_FOUND THEN BEGIN

              -- these variables apply regardless of the current jobname/jobqual
    SELECT target_value1 default_type, target_value2 default_value, target_value3 bind_values
      INTO ls_default_type, ls_default_value, ls_bind_values
      FROM XX_FIN_TRANSLATEVALUES
     WHERE translate_id  = ln_translation_id
       AND source_value1 = '%'
       AND source_value2 = '%'
       AND UPPER(source_value3) = ls_arg
       AND enabled_flag  = 'Y'
       AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate);

    EXCEPTION WHEN NO_DATA_FOUND THEN
      RETURN p_arg; -- give up
--  END;
  END;
  IF ls_default_type = 'S' THEN
     lsa_vset_args := EXPLODE_ARGS(p_vars,NULL); -- blank args for use in dynamic sql
  END IF;
  ls_dynval := DEFAULT_ARG_VAL(p_vars,lsa_vset_args,ls_default_type,ls_default_value,ls_bind_values);
  ADD_VAR(p_vars,ls_arg,ls_dynval);
  RETURN ls_dynval;

END RESOLVE_ARG;


-- =============================================================================
-- function ADD_VAR adds the name/value pair to the variables associative array
-- ============================================================================= 
PROCEDURE ADD_VAR (
   p_vars IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_n    IN     VARCHAR2
  ,p_v    IN     VARCHAR2
)
IS
  ls_n    VARCHAR2(100) := TRIM(UPPER(P_n));
BEGIN
  IF ls_n IS NOT NULL THEN
    IF SUBSTR(ls_n,1,1)<>'!' THEN 
      ls_n := '!' || ls_n;
    END IF;
    p_vars(ls_n) := TRIM(p_v);
    put_log_line('VAR: ' || ls_n || '="' || p_vars(ls_n) || '"');
  END IF;
END ADD_VAR;

-- ===========================================================================
-- function used to separate the delimited arg into an array
--   of 100 string values initialized to CHR(0)
-- =========================================================================== 
FUNCTION EXPLODE_ARGS (
   p_vars      IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_string    IN     VARCHAR2
  ,p_delimiter IN     VARCHAR2 := ',' 
)
RETURN ARG_ARRAY_TYPE
IS
  n_index          NUMBER := 0;
  n_pos            NUMBER := 0;
  n_hold_pos       NUMBER := 1;

  a_return_tab     ARG_ARRAY_TYPE := ARG_ARRAY_TYPE();
BEGIN
  IF LENGTH(p_string)>0 THEN -- If arg string is null, do not initialize any args; if a single arg should be initialized to null, just pass in whitespace.
    LOOP
      n_pos := INSTR(p_string,p_delimiter,n_hold_pos);
      a_return_tab.EXTEND;
      n_index := n_index + 1;
      IF n_pos > 0 THEN
        a_return_tab(n_index) := RESOLVE_ARG(p_vars,LTRIM(SUBSTR(p_string,n_hold_pos,n_pos-n_hold_pos)));
        --put_log_line('Arg' || n_index || '="' || a_return_tab(n_index) || '"');
      ELSE
        a_return_tab(n_index) := RESOLVE_ARG(p_vars,LTRIM(SUBSTR(p_string,n_hold_pos)));
        --put_log_line('Arg' || n_index || '="' || a_return_tab(n_index) || '"');
        EXIT;
      END IF;
      n_hold_pos := n_pos+1;
    END LOOP;
  END IF;
  WHILE n_index<100 LOOP
    n_index := n_index + 1;
    a_return_tab.EXTEND;
    a_return_tab(n_index) := CHR(0);
  END LOOP;
  RETURN a_return_tab;
END EXPLODE_ARGS;


-- ===========================================================================
-- SYNOPSIS
--    FUNCTION VALUE_SET_QUERY
-- DESCRIPTION
--    Adapted by Bushrod Thomas for OD from OKCAURUL.pll PROCEDURE query_dff_by_value
--    which is the method the Submit Request form FNDRSRUN uses to get validation set LOVs
--    and also used in the SQL and Segment default_type's default_value resolution (see $FLEX$.)
--
--    This function puts together the sql used to query a value set
-- ===========================================================================
 FUNCTION VALUE_SET_QUERY(
    p_application_table_name  IN VARCHAR2
   ,p_value_column_name       IN VARCHAR2
   ,p_value_column_type       IN VARCHAR2
   ,p_meaning_column_name     IN VARCHAR2
   ,p_meaning_column_type     IN VARCHAR2
   ,p_id_column_name          IN VARCHAR2
   ,p_id_column_type          IN VARCHAR2
   ,p_additional_where_clause IN VARCHAR2
   ,p_enabled_column_name     IN VARCHAR2
   ,p_start_date_column_name  IN VARCHAR2
   ,p_end_date_column_name    IN VARCHAR2
) 
RETURN VARCHAR2
IS
    ls_query VARCHAR2(32767);
BEGIN
    ls_query := 'SELECT ';

    IF p_value_column_type IN ('C','V') THEN
      ls_query := ls_query || p_value_column_name || ' VALUE, ';
    ELSE 
      ls_query := ls_query || 'to_char(' || p_value_column_name || ') VALUE, ';
    END IF; 

    IF p_meaning_column_type IN ('C','V') THEN
      ls_query := ls_query || p_meaning_column_name || ' MEANING, ';
    ELSE 
      ls_query := ls_query || 'to_char(' || p_meaning_column_name || ') MEANING ';
    END IF;

    IF p_id_column_type IN ('C','V') THEN
      ls_query := ls_query || p_id_column_name || ' ID ';
    ELSE
      ls_query := ls_query || 'to_char(' || p_id_column_name || ') ID ';
    END IF; 

    ls_query := ls_query || 'FROM ' || p_application_table_name || ' WHERE ' || p_value_column_name || '=:1 ';

    IF p_enabled_column_name <> '''Y''' THEN
      ls_query := ls_query || 'AND ' || p_enabled_column_name || '=''Y'' ';
    END IF;

    IF UPPER(p_start_date_column_name) <> 'TO_DATE(NULL)' OR UPPER(p_end_date_column_name) <> 'TO_DATE(NULL)' THEN
      ls_query := ls_query || 'AND TRUNC(SYSDATE) BETWEEN NVL(' || p_start_date_column_name || ',TRUNC(SYSDATE)) AND NVL(' || p_end_date_column_name || ',TRUNC(SYSDATE)) ';
    END IF;

    IF p_additional_where_clause IS NOT NULL THEN
        IF UPPER(SUBSTR(p_additional_where_clause,1,5))='WHERE' THEN
          ls_query := ls_query || 'AND ' || SUBSTR(p_additional_where_clause,7);
        ELSIF UPPER(SUBSTR(p_additional_where_clause,1,5))='ORDER' THEN
          ls_query := ls_query || p_additional_where_clause;
        ELSE
          ls_query := ls_query || 'AND ' || p_additional_where_clause;
        END IF;
    END IF;

    RETURN ls_query;
END VALUE_SET_QUERY;


-- =============================================================================
-- procedure PARSE_BIND_NAMES replaces complex multipart (:X.X :Y.Y) sql bind names 
--   with simple names (e.g., :1 :2) and adds the original bind names to an associative
--   array by value_set_name and param position so that they can be properly bound later
-- ============================================================================= 
PROCEDURE PARSE_BIND_NAMES (
   pa_sql_text      IN OUT NOCOPY SQL_TEXT_TYPE
  ,pa_vars          IN OUT NOCOPY VAR_ARRAY_TYPE
  ,p_value_set_name IN FND_FLEX_VALUE_SETS.flex_value_set_name%TYPE
)
IS
  ls_sql_w_uniform_bind_vars VARCHAR2(32767) := pa_sql_text(p_value_set_name);
  ls_bind_variable           VARCHAR2(100);
  ln_index                   NUMBER := 1; -- First bind variable is for the implied default value
BEGIN
  ls_sql_w_uniform_bind_vars := REGEXP_REPLACE(ls_sql_w_uniform_bind_vars,':\$Profiles\$\.(\w*)','FND_PROFILE.VALUE(''\1'')',1,0,'i');
  LOOP
     ls_bind_variable := REGEXP_SUBSTR(ls_sql_w_uniform_bind_vars,':\$FLEX\$\.(\w*)(\.MEANING|\.ID|\.VALUE)*',1,1,'i');
  EXIT WHEN ls_bind_variable IS NULL;
     ln_index := ln_index + 1;
     ls_sql_w_uniform_bind_vars := REGEXP_REPLACE(ls_sql_w_uniform_bind_vars,REPLACE(ls_bind_variable,'$','\$'),':' || ln_index,1,1);
--put_log_line('  PARSE_BIND_NAMES ' || p_value_set_name || '.PARAM' || ln_index || ' = ' || UPPER(ls_bind_variable), 5);
     pa_vars(p_value_set_name || '.PARAM' || ln_index) := REPLACE(UPPER(ls_bind_variable),':$FLEX$.','');
  END LOOP;
  pa_vars(p_value_set_name || '.PARAMCOUNT') := ln_index;
  IF ln_index>0 THEN
    pa_sql_text(p_value_set_name) := ls_sql_w_uniform_bind_vars;
  END IF;
END;


FUNCTION EXEC_DEFAULT_VAL_SQL (
    p_sql  IN VARCHAR2
   ,p_args IN ARG_ARRAY_TYPE
   ,n_args IN NUMBER
)
RETURN VARCHAR2
IS
  lr_result VARCHAR2(240);
BEGIN
  IF n_args = 0 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result;
  ELSIF n_args = 1 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1);
  ELSIF n_args = 2 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2);  
  ELSIF n_args = 3 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3);  
  ELSIF n_args = 4 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4);  
  ELSIF n_args = 5 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5);  
  ELSIF n_args = 6 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6);  
  ELSIF n_args = 7 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7);  
  ELSIF n_args = 8 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8);  
  ELSIF n_args = 9 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9);
  ELSIF n_args = 10 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10);  
  ELSIF n_args = 11 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11);    
  ELSIF n_args = 12 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12);
  ELSIF n_args = 13 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13);
  ELSIF n_args = 14 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14);
  ELSIF n_args = 15 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15);
  ELSIF n_args = 16 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16);
  ELSIF n_args = 17 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17);
  ELSIF n_args = 18 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18);
  ELSIF n_args = 19 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18),p_args(19);
  ELSIF n_args = 20 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)  
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18),p_args(19),p_args(20);
  END IF;
  RETURN lr_result;
END EXEC_DEFAULT_VAL_SQL;

FUNCTION EXEC_VALUE_SET_SQL (
    p_sql  IN VARCHAR2
   ,p_args IN ARG_ARRAY_TYPE
   ,n_args IN NUMBER
)
RETURN VALUE_SET_REC_TYPE
IS
  lr_result VALUE_SET_REC_TYPE;
BEGIN
  IF n_args = 0 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result;
  ELSIF n_args = 1 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1);
  ELSIF n_args = 2 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2);  
  ELSIF n_args = 3 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3);  
  ELSIF n_args = 4 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4);  
  ELSIF n_args = 5 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5);  
  ELSIF n_args = 6 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6);  
  ELSIF n_args = 7 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7);  
  ELSIF n_args = 8 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8);  
  ELSIF n_args = 9 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9);
  ELSIF n_args = 10 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10);  
  ELSIF n_args = 11 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11);    
  ELSIF n_args = 12 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12);
  ELSIF n_args = 13 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13);
  ELSIF n_args = 14 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14);
  ELSIF n_args = 15 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15);
  ELSIF n_args = 16 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16);
  ELSIF n_args = 17 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17);
  ELSIF n_args = 18 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18);
  ELSIF n_args = 19 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18),p_args(19);
  ELSIF n_args = 20 THEN
    EXECUTE IMMEDIATE p_sql INTO lr_result USING p_args(1),p_args(2),p_args(3),p_args(4),p_args(5),p_args(6),p_args(7),p_args(8),p_args(9),p_args(10)  
                                                ,p_args(11),p_args(12),p_args(13),p_args(14),p_args(15),p_args(16),p_args(17),p_args(18),p_args(19),p_args(20);
  END IF;
  RETURN lr_result;
END EXEC_VALUE_SET_SQL;



-- ===========================================================================
-- SYNOPSIS
--    FUNCTION DEFAULT_ARG_VAL
-- DESCRIPTION
--    Adapted by Bushrod Thomas for OD from GMPCOM.pll PROCEDURE default_header_flex 
--    which is the method the Submit Request form FNDRSRUN uses to populate default args.
--
--    Also See Lookup set: FLEX_DEFAULT_TYPE
-- ===========================================================================
FUNCTION DEFAULT_ARG_VAL(p_vars            IN OUT NOCOPY VAR_ARRAY_TYPE
                        ,p_args_for_dynsql IN OUT NOCOPY ARG_ARRAY_TYPE
                        ,p_default_type    IN VARCHAR2
                        ,p_default_value   IN VARCHAR2
                        ,p_bind_cdl        IN VARCHAR2)
RETURN VARCHAR2
IS
  ls_sql             VARCHAR2(240) := NULL;
  ls_default_value   VARCHAR2(240) := NULL;
  X_default_value    VARCHAR2(240) := NULL;
  ls_bind_variable   VARCHAR2(100);  
  ln_index           NUMBER := 0;
  n_pos              NUMBER := 0;
  n_hold_pos         NUMBER := 1;
BEGIN
  IF p_default_type = 'C' THEN    -- Constant
     X_default_value := RESOLVE_ARG(p_vars,p_default_value);

  ELSIF p_default_type = 'P' THEN -- Profile
     X_default_value := FND_PROFILE.VALUE(p_default_value);

  ELSIF p_default_type = 'D' THEN -- Current Date
     X_default_value := TO_CHAR(SYSDATE, 'DD-MON-RRRR');

  ELSIF p_default_type = 'T' THEN -- Current Time
     X_default_value := to_char(SYSDATE, 'DD-MON-RRRR HH24:MI:SS');

  ELSIF p_default_type = 'S' THEN -- SQL Statement
     -- Don't think we can get :PARAMETER values without a form block
     -- Also not sure about :$ATTRIBUTEGROUP$., :$OBJECT$., :WORK_ORDER.  (need to research further)
     -- For $PROFILES$ block, this transforms fields like $PROFILES$.GL_SET_OF_BKS_ID to FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
     ls_sql := REGEXP_REPLACE(p_default_value,':\$Profiles\$\.(\w*)','FND_PROFILE.VALUE(''\1'')',1,0,'i');
     
     IF p_bind_cdl IS NOT NULL THEN
        LOOP
          n_pos := INSTR(p_bind_cdl,',',n_hold_pos);
          ln_index := ln_index + 1;
          IF n_pos > 0 THEN
            p_args_for_dynsql(ln_index) := RESOLVE_ARG(p_vars,LTRIM(SUBSTR(p_bind_cdl,n_hold_pos,n_pos-n_hold_pos)));
          ELSE
            p_args_for_dynsql(ln_index) := RESOLVE_ARG(p_vars,LTRIM(SUBSTR(p_bind_cdl,n_hold_pos)));
            EXIT;
          END IF;
          n_hold_pos := n_pos+1;
        END LOOP;
     ELSE
       LOOP
         ls_bind_variable := REGEXP_SUBSTR(ls_sql,':\$FLEX\$\.(\w*)(\.MEANING|\.ID|\.VALUE)*',1,1,'i');
         EXIT WHEN ls_bind_variable IS NULL;
         ln_index := ln_index + 1;
         ls_sql := REGEXP_REPLACE(ls_sql,REPLACE(ls_bind_variable,'$','\$'),':' || ln_index,1,1);
         put_log_line('bind variable: ' || ls_bind_variable);
         put_log_line('new sql: ' || ls_sql);
         put_log_line('looking for: ' || UPPER(SUBSTR(ls_bind_variable,9)));
         p_args_for_dynsql(ln_index) := p_vars(UPPER(SUBSTR(ls_bind_variable,9))); -- remove the prefix :$FLEX$.
         put_log_line('found: ' || p_vars(UPPER(SUBSTR(ls_bind_variable,9))));
       END LOOP;
     END IF;
      
     put_log_line('sql default_value:' || ls_sql);
     X_default_value := EXEC_DEFAULT_VAL_SQL(ls_sql,p_args_for_dynsql,ln_index);

  ELSIF p_default_type = 'A' THEN -- Segment
     -- "Search the table with the default value and get the application column name."
     -- This apparently copies the value from previously evaluated (or entered) parameters
     -- As of 11/21/2008, there are 78 concurrent programs using this type
     ls_default_value := UPPER(p_default_value);
     IF p_vars.EXISTS(ls_default_value) THEN
        X_default_value := p_vars(ls_default_value);
     ELSE
        put_log_line('Segment ' || ls_default_value || ' not found.');
     END IF;

--ELSEF p_default_type = 'E' THEN -- Environment Variable
     -- This type is disabled and no programs are using it
     -- X_default_value := ?

--ELSIF p_default_type = 'F' THEN -- Field
     -- Not sure how to do this or if it's possible without Form context
     -- As of 11/21/2008, there are no concurrent programs using this default type
     -- X_default_value := NAME_IN(V_default_value);

  END IF;

  RETURN X_default_value;
END DEFAULT_ARG_VAL;


FUNCTION IS_NUMBER(p_str IN VARCHAR2)
RETURN BOOLEAN
IS
  ln_val NUMBER;
BEGIN
  ln_val := TO_NUMBER(p_str);
  RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END;


-- ===========================================================================
-- function to emulate validation set formatting
--
-- See "Value Formats" page in Online Help
-- Also See FND_LOOKUPS where lookup_type='FIELD_TYPE'
--
-- format_type	meaning			count in FND_FLEX_VALUE_SETS (as of 12/4/2008)
--------------------------------------------------------------------
--C		Char			11567
--N		Number			1348
--X		Standard Date		202
--D		Date			61 (will be obsolete in Release 12)
--Y		Standard DateTime	42
--I		Time			5
--T		DateTime		2 (will be obsolete in Release 12)
--Z		Standard Time		0
--M		Money			0
-- ===========================================================================
FUNCTION FORMAT_VALUE(p_orig_value  IN VARCHAR2
                     ,p_format_type IN VARCHAR2)
RETURN VARCHAR2
IS
  ls_formatted_value VARCHAR2(240) := p_orig_value;
BEGIN
  IF p_format_type = 'Y' THEN -- Standard DateTime
     ls_formatted_value := TO_CHAR(TO_DATE(ls_formatted_value,'DD-MON-RR HH24:MI:SS'),'RRRR/MM/DD HH24:MI:SS');
  END IF;

  RETURN ls_formatted_value;
END;


FUNCTION submit_request( 
   p_application IN VARCHAR2
  ,p_program     IN VARCHAR2
  ,p_description IN VARCHAR2
  ,p_args        IN ARG_ARRAY_TYPE
) RETURN FND_CONCURRENT_REQUESTS.request_id%TYPE
IS PRAGMA AUTONOMOUS_TRANSACTION;
  ln_conc_request_id FND_CONCURRENT_REQUESTS.request_id%TYPE := 0;
BEGIN
  ln_conc_request_id := 
    XX_FND_REQUEST.submit_request
    ( application => p_application
     ,program     => p_program
     ,description => p_description
     ,argument1   => p_args(1)
     ,argument2   => p_args(2)
     ,argument3   => p_args(3)
     ,argument4   => p_args(4)
     ,argument5   => p_args(5)
     ,argument6   => P_args(6)
     ,argument7   => p_args(7)
     ,argument8   => p_args(8)
     ,argument9   => p_args(9)
     ,argument10  => p_args(10)
     ,argument11  => p_args(11)
     ,argument12  => p_args(12)
     ,argument13  => p_args(13)
     ,argument14  => p_args(14)
     ,argument15  => p_args(15)
     ,argument16  => p_args(16)
     ,argument17  => p_args(17)
     ,argument18  => p_args(18)
     ,argument19  => p_args(19)
     ,argument20  => p_args(20)
     ,argument21  => p_args(21)
     ,argument22  => p_args(22)
     ,argument23  => p_args(23)
     ,argument24  => p_args(24)
     ,argument25  => p_args(25)
     ,argument26  => p_args(26)
     ,argument27  => p_args(27)
     ,argument28  => p_args(28)
     ,argument29  => p_args(29)
     ,argument30  => p_args(30)
     ,argument31  => p_args(31)
     ,argument32  => p_args(32)
     ,argument33  => p_args(33)
     ,argument34  => p_args(34)
     ,argument35  => p_args(35)
     ,argument36  => p_args(36)
     ,argument37  => p_args(37)
     ,argument38  => p_args(38)
     ,argument39  => p_args(39)  
     ,argument40  => p_args(40)
     ,argument41  => p_args(41)
     ,argument42  => p_args(42)
     ,argument43  => p_args(43)
     ,argument44  => p_args(44)
     ,argument45  => p_args(45)
     ,argument46  => p_args(46)
     ,argument47  => p_args(47)
     ,argument48  => p_args(48)
     ,argument49  => p_args(49)
     ,argument50  => p_args(50)
     ,argument51  => p_args(51)
     ,argument52  => p_args(52)
     ,argument53  => p_args(53)
     ,argument54  => p_args(54)
     ,argument55  => p_args(55)
     ,argument56  => p_args(56)
     ,argument57  => p_args(57)
     ,argument58  => p_args(58)
     ,argument59  => p_args(59)
     ,argument60  => p_args(60)
     ,argument61  => p_args(61)
     ,argument62  => p_args(62)
     ,argument63  => p_args(63)
     ,argument64  => p_args(64)
     ,argument65  => p_args(65)
     ,argument66  => p_args(66)
     ,argument67  => p_args(67)
     ,argument68  => p_args(68)
     ,argument69  => p_args(69)
     ,argument70  => p_args(70)
     ,argument71  => p_args(71)
     ,argument72  => p_args(72)
     ,argument73  => p_args(73)
     ,argument74  => p_args(74)
     ,argument75  => p_args(75)
     ,argument76  => p_args(76)
     ,argument77  => p_args(77)
     ,argument78  => p_args(78)
     ,argument79  => p_args(79)
     ,argument80  => p_args(80)
     ,argument81  => p_args(81)
     ,argument82  => p_args(82)
     ,argument83  => p_args(83)
     ,argument84  => p_args(84)
     ,argument85  => p_args(85)
     ,argument86  => p_args(86)
     ,argument87  => p_args(87)
     ,argument88  => p_args(88)
     ,argument89  => p_args(89)
     ,argument90  => p_args(90)
     ,argument91  => p_args(91)
     ,argument92  => p_args(92)
     ,argument93  => p_args(93)
     ,argument94  => p_args(94)
     ,argument95  => p_args(95)
     ,argument96  => p_args(96)
     ,argument97  => p_args(97)
     ,argument98  => p_args(98)
     ,argument99  => p_args(99)
     ,argument100 => p_args(100)
    );

  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (ln_conc_request_id > 0) THEN
    -- =========================================================================
    -- if a child request, then update it for concurrent mgr to process 
    -- =========================================================================
-- not submitting as child request, so this is unnecessary        
--    UPDATE fnd_concurrent_requests
--       SET phase_code = 'P',
--           status_code = 'I'
--     WHERE request_id = ln_conc_request_id;

    COMMIT; -- must commit work so that the concurrent manager polls the request 
  ELSE 
    FND_MESSAGE.raise_error;
  END IF;

  RETURN ln_conc_request_id;

END submit_request;

-- ===========================================================================
-- procedure for submitting job
-- ===========================================================================
PROCEDURE SUBMIT
(
     Errbuf          OUT NOCOPY VARCHAR2
    ,Retcode         OUT NOCOPY VARCHAR2
    ,p_esp_job_name  IN  VARCHAR2
    ,p_simulate      IN  VARCHAR2 := NULL
)
IS
  ls_esp_job_name               VARCHAR2(100)  := TRIM(p_esp_job_name);
  ls_esp_job_qual               VARCHAR2(100);
  ln_conc_request_id            NUMBER         := 0;
  ln_resp_id                    NUMBER         := NULL;
  ln_resp_appl_id               NUMBER         := NULL;
  v_return_msg                  VARCHAR2(4000) := NULL;
  v_phase_code                  VARCHAR2(30)   := NULL;
  v_phase_desc                  VARCHAR2(80)   := NULL;
  v_status_code                 VARCHAR2(30)   := NULL;
  v_status_desc                 VARCHAR2(80)   := NULL;
  b_success                     BOOLEAN        := NULL;      
  ld_sysdate                    DATE           := TRUNC(SYSDATE);
  ls_description                VARCHAR2(50);
  lsa_vset_args                 ARG_ARRAY_TYPE;
  lsa_args                      ARG_ARRAY_TYPE;
  lsa_bind_vals                 ARG_ARRAY_TYPE;
  lsa_vars                      VAR_ARRAY_TYPE;
  ln_index                      NUMBER;
  ln_index2                     NUMBER;
  ln_min_params                 NUMBER := 0;
  ls_responsibility_name        XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
  ls_program_appl_name          XX_FIN_TRANSLATEVALUES.target_value2%TYPE;
  ls_program_short_name         XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
  ls_program_args               XX_FIN_TRANSLATEVALUES.target_value4%TYPE;
  ln_check_4done_every_x_secs   XX_FIN_TRANSLATEVALUES.target_value5%TYPE;
  ln_max_wait_seconds           XX_FIN_TRANSLATEVALUES.target_value6%TYPE;
  ln_watch_only_to_child_level  NUMBER;
  ls_use_program_defaults       XX_FIN_TRANSLATEVALUES.target_value8%TYPE;
  ls_fail_on_warning            XX_FIN_TRANSLATEVALUES.target_value17%TYPE;
  ls_default_val                VARCHAR2(240);
  ls_formatted_val              VARCHAR2(240);
  ls_value_set_rec              VALUE_SET_REC_TYPE;
  lsa_sql_text                  SQL_TEXT_TYPE;
  ln_run_as_user_id             NUMBER;
  ln_start_time                 NUMBER;
  ln_end_time                   NUMBER;

  ln_job_def_translation_id     XX_FIN_TRANSLATEDEFINITION.translate_id%TYPE;
  ln_arg_def_translation_id     XX_FIN_TRANSLATEDEFINITION.translate_id%TYPE;

  ls_template_app               XDO_TEMPLATES_B.application_short_name%TYPE;
  ls_template_code              XDO_TEMPLATES_B.template_code%TYPE;
  ls_template_language          XDO_TEMPLATES_B.default_language%TYPE;
  ls_template_territory         XDO_TEMPLATES_B.default_territory%TYPE;
  ls_template_output_format     FND_LOOKUPS.lookup_code%TYPE; -- see FND_LOOKUPS where lookup_type='XDO_OUTPUT_TYPE'
  ls_template_def_app           XDO_TEMPLATES_B.application_short_name%TYPE;
  ls_template_def_code          XDO_TEMPLATES_B.template_code%TYPE;
  ls_template_def_language      XDO_TEMPLATES_B.default_language%TYPE;
  ls_template_def_territory     XDO_TEMPLATES_B.default_territory%TYPE;
  ls_template_def_output_format FND_LOOKUPS.lookup_code%TYPE := 'PDF';

  ls_printer                    FND_PRINTER.printer_name%TYPE;
  ls_style                      FND_PRINTER_STYLES.printer_style_name%TYPE;
  ln_copies                     NUMBER;

  ln_completed_unsuccessfully   NUMBER;
  ln_incomplete                 NUMBER;
  lb_simulating                 BOOLEAN := DECODE_BOOLEAN(p_simulate);
  ls_unvalidated                VARCHAR2(100) := '';
  lb_use_program_defaults       BOOLEAN;
  lb_fail_on_warning            BOOLEAN;
  ls_simulate_output            VARCHAR2(4000);
  ls_user_program_name          FND_CONCURRENT_PROGRAMS_TL.user_concurrent_program_name%TYPE;
BEGIN
  Retcode := 0;

  ls_description := p_esp_job_name;
  ln_index := INSTR(ls_esp_job_name,'.');
  IF ln_index>0 THEN -- job name has both name and qual
    ls_esp_job_qual := TRIM(SUBSTR(p_esp_job_name,ln_index+1));
    ls_esp_job_name := TRIM(SUBSTR(p_esp_job_name,1,ln_index-1));
  END IF;
  IF FND_GLOBAL.conc_request_id>0 THEN
    ls_description := ls_description || '-' || FND_GLOBAL.conc_request_id;
  END IF;

  put_log_line('esp_job_name: "' || ls_esp_job_name || '"');
  put_log_line('esp_job_qual: "' || ls_esp_job_qual || '"');
  ln_job_def_translation_id := GET_TRANSLATION_ID(GC_JOB_DEF_TRANS_NAME, ls_esp_job_name);
  ln_arg_def_translation_id := GET_TRANSLATION_ID(GC_ARG_DEF_TRANS_NAME, ls_esp_job_name);
  ADD_VAR(lsa_vars,'XX_ARG_DEF_TRANSLATION_ID',ln_arg_def_translation_id);
--  ADD_VAR(lsa_vars,'XX_ESP_JOB_NAME',ls_esp_job_name);

  -- ===========================================================================
  -- get job definition from translation table
  -- ===========================================================================
  BEGIN
    SELECT target_value1
          ,target_value2
          ,target_value3
          ,target_value4
          ,NVL(target_value5,15) -- 15 seconds
          ,TO_NUMBER(NVL(target_value6,0))
          ,DECODE(target_value7,null,9999,0,9999,target_value7) -- 0 or null -> 9999 means wait for ~all~ children
          ,target_value8
          ,target_value9
          ,target_value10
          ,target_value11
          ,target_value12
          ,target_value13
          ,target_value14
          ,target_value15
          ,NVL(target_value16,0)
          ,target_value17
      INTO ls_responsibility_name
          ,ls_program_appl_name
          ,ls_program_short_name
          ,ls_program_args
          ,ln_check_4done_every_x_secs
          ,ln_max_wait_seconds
          ,ln_watch_only_to_child_level
          ,ls_use_program_defaults
          ,ls_template_app
          ,ls_template_code
          ,ls_template_language
          ,ls_template_territory
          ,ls_template_output_format
          ,ls_printer
          ,ls_style
          ,ln_copies
          ,ls_fail_on_warning
      FROM XX_FIN_TRANSLATEVALUES
     WHERE translate_id   = ln_job_def_translation_id
       AND source_value1 = ls_esp_job_name
       AND source_value2 = ls_esp_job_qual
       AND enabled_flag  = 'Y'
       AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate);

     EXCEPTION WHEN NO_DATA_FOUND THEN
       RAISE_APPLICATION_ERROR(-20201, 'Job/Qual not found in translation table.');
  END;

  IF p_simulate ='ESP' THEN
    ln_max_wait_seconds := -1;
  END IF;
  
  put_log_line('Responsibility:'       || ls_responsibility_name);
  put_log_line('Program App:'          || ls_program_appl_name);
  put_log_line('Program Name:'         || ls_program_short_name);
  put_log_line('Program Args:'         || ls_program_args);
  put_log_line('Check Interval:'       || ln_check_4done_every_x_secs); 
  put_log_line('Max Wait:'             || ln_max_wait_seconds);   
  put_log_line('Child Wait Level:'     || ln_watch_only_to_child_level);     
  put_log_line('Use Program Defaults:' || ls_use_program_defaults);

--  ls_use_program_defaults := 'N';
--  ls_program_args := '';
--  ls_program_short_name:='XXSUPAUDTR';

  lb_use_program_defaults := DECODE_BOOLEAN(ls_use_program_defaults);
  
  lsa_vset_args := EXPLODE_ARGS(lsa_vars,NULL); -- blank args for use in validation set sql

  -- ===========================================================================
  -- get arg definition from translation table
  -- ===========================================================================
  FOR lr_arg IN
    (SELECT UPPER(source_value3) var_or_param_name_or_position
           ,target_value1 default_type
           ,target_value2 default_value
           ,target_value3 bind_values
       FROM XX_FIN_TRANSLATEVALUES
      WHERE translate_id  = ln_arg_def_translation_id
        AND source_value1 = ls_esp_job_name
        AND source_value2 = ls_esp_job_qual
        AND enabled_flag  = 'Y'
        AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate)
     ORDER BY target_value4) -- variable eval order
  LOOP
    IF SUBSTR(lr_arg.var_or_param_name_or_position,1,1) = '!' THEN
      ADD_VAR(lsa_vars,SUBSTR(lr_arg.var_or_param_name_or_position,2),DEFAULT_ARG_VAL(lsa_vars,lsa_vset_args,lr_arg.default_type,lr_arg.default_value,lr_arg.bind_values));
    ELSE
      IF IS_NUMBER(lr_arg.var_or_param_name_or_position) THEN
        IF TO_NUMBER(lr_arg.var_or_param_name_or_position) > ln_min_params THEN
          ln_min_params := TO_NUMBER(lr_arg.var_or_param_name_or_position); -- should pass at least this many params
        END IF;
      END IF;
      lsa_vars(lr_arg.var_or_param_name_or_position || '_OVERRIDE_DEFTYPE') := lr_arg.default_type;
      lsa_vars(lr_arg.var_or_param_name_or_position || '_OVERRIDE_DEFVAL')  := lr_arg.default_value;
      lsa_vars(lr_arg.var_or_param_name_or_position || '_OVERRIDE_BINDCDL') := lr_arg.bind_values;
    END IF;
  END LOOP;


  -- ===========================================================================
  -- lookup responsibility appl and id
  -- ===========================================================================
--  BEGIN -- first check by key, then by name
--    SELECT application_id,responsibility_id
--      INTO ln_resp_appl_id,ln_resp_id
--      FROM FND_RESPONSIBILITY
--     WHERE responsibility_key=ls_responsibility_name;
--  EXCEPTION WHEN NO_DATA_FOUND THEN
    SELECT application_id,responsibility_id
      INTO ln_resp_appl_id,ln_resp_id
      FROM FND_RESPONSIBILITY_TL
     WHERE responsibility_name=ls_responsibility_name;
--  END;

  put_log_line('application_id:'    || ln_resp_appl_id);
  put_log_line('responsibility_id:' || ln_resp_id);

  -- ===========================================================================
  -- set responsibility context
  -- ===========================================================================
    ln_run_as_user_id := FND_GLOBAL.user_id;
    IF INSTR(FND_GLOBAL.user_name,'_COMMON') > 0 THEN 
      BEGIN
        SELECT user_id INTO ln_run_as_user_id FROM FND_USER WHERE USER_NAME=REPLACE(FND_GLOBAL.user_name,'_COMMON');
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL; -- just use current user_id
      END;
    END IF;

    FND_GLOBAL.apps_initialize(
      user_id => ln_run_as_user_id
     ,resp_id => ln_resp_id
     ,resp_appl_id => ln_resp_appl_id
    );

    put_log_line('user_id:' || FND_GLOBAL.user_id);
  
  lsa_args := EXPLODE_ARGS(lsa_vars,ls_program_args);

  -- ===========================================================================
  -- Set Parameter Default Values
  -- ===========================================================================
  IF NOT lb_use_program_defaults THEN
    ln_index := 1;  

    WHILE ln_index<=100 AND (NVL(lsa_args(ln_index),'X')<>CHR(0) OR ln_index <= ln_min_params) LOOP
      IF lsa_vars.EXISTS(ln_index || '_OVERRIDE_DEFTYPE') THEN
        lsa_args(ln_index) := DEFAULT_ARG_VAL(lsa_vars,lsa_vset_args,lsa_vars(ln_index || '_OVERRIDE_DEFTYPE'),lsa_vars(ln_index || '_OVERRIDE_DEFVAL'),lsa_vars(ln_index || '_OVERRIDE_BINDCDL'));
      ELSIF lsa_args(ln_index)=CHR(0) THEN
        lsa_args(ln_index) := '';
      END IF;
      put_log_line('   arg(' || ln_index || ')=' || lsa_args(ln_index));
      ln_index := ln_index+1;
    END LOOP;
    
  END IF;

  IF lb_use_program_defaults OR lb_simulating THEN 
    ln_index := 1;

    FOR lr_param IN
        (SELECT C.end_user_column_name param_name, S.flex_value_set_name vset_name, L.meaning vset_type
               ,UPPER(C.end_user_column_name) end_user_column_name,C.default_type,C.default_value,C.required_flag
               ,UPPER(S.flex_value_set_name) flex_value_set_name, S.format_type
               ,T.application_table_name,T.additional_where_clause
               ,T.enabled_column_name,T.start_date_column_name,T.end_date_column_name
               ,T.value_column_name,T.meaning_column_name,T.id_column_name
               ,T.value_column_type,T.meaning_column_type,T.id_column_type               
               -- T.hierarchy_level_column_name ??, T.summary allowed_flag ??, T.summary_column_name ??
           FROM FND_DESCR_FLEX_COLUMN_USAGES C, FND_APPLICATION A, FND_FLEX_VALUE_SETS S, FND_FLEX_VALIDATION_TABLES T, FND_LOOKUPS L
          WHERE A.application_short_name=ls_program_appl_name
            AND A.application_id = C.application_id
            AND C.descriptive_flexfield_name = '$SRS$.' || ls_program_short_name
            AND C.descriptive_flex_context_code = 'Global Data Elements'
            AND C.enabled_flag = 'Y'
            AND C.flex_value_set_id = S.flex_value_set_id
            AND S.flex_value_set_id = T.flex_value_set_id (+)
            AND L.lookup_type='FIELD_TYPE'
            AND S.format_type=L.lookup_code (+)
      ORDER BY C.column_seq_num)
    LOOP
      IF lr_param.application_table_name IS NOT NULL AND NOT lsa_sql_text.EXISTS(lr_param.flex_value_set_name) THEN
         lsa_sql_text(lr_param.flex_value_set_name) := VALUE_SET_QUERY(p_application_table_name  => lr_param.application_table_name
                                                                      ,p_value_column_name       => lr_param.value_column_name
                                                                      ,p_value_column_type       => lr_param.value_column_type                                                                      
                                                                      ,p_meaning_column_name     => NVL(lr_param.meaning_column_name,lr_param.value_column_name)
                                                                      ,p_meaning_column_type     => NVL(lr_param.meaning_column_type,lr_param.value_column_type)
                                                                      ,p_id_column_name          => NVL(lr_param.id_column_name,lr_param.value_column_name)
                                                                      ,p_id_column_type          => NVL(lr_param.id_column_type,lr_param.value_column_type)
                                                                      ,p_additional_where_clause => TRIM(lr_param.additional_where_clause)
                                                                      ,p_enabled_column_name     => lr_param.enabled_column_name
                                                                      ,p_start_date_column_name  => lr_param.start_date_column_name
                                                                      ,p_end_date_column_name    => lr_param.end_date_column_name);
         PARSE_BIND_NAMES(lsa_sql_text,lsa_vars,lr_param.flex_value_set_name);
--         lsa_vars(lr_param.flex_value_set_name || '.ID_COLUMN_NAME')    := lr_param.id_column_name;
--         lsa_vars(lr_param.flex_value_set_name || '.VALUE_COLUMN_NAME') := lr_param.value_column_name;
      END IF;
--      lsa_vars('PARAM_NAME.' || ln_index) := lr_param.end_user_column_name;
--      lsa_vars('PARAM_VSET.' || ln_index) := lr_param.flex_value_set_name;

      IF NVL(lsa_args(ln_index),CHR(0))=CHR(0) THEN
        IF NOT lb_use_program_defaults THEN
          lsa_args(ln_index) := ''; -- if simulating and there are more params than args provided
        ELSE
          put_log_line('Defaulting param ''' || lr_param.end_user_column_name || ''' type=' || lr_param.default_type || ' value="' || lr_param.default_value || '"');
          IF lsa_vars.EXISTS(lr_param.end_user_column_name || '_OVERRIDE_TYPE') THEN
            lsa_args(ln_index) := DEFAULT_ARG_VAL(lsa_vars,lsa_vset_args,lsa_vars(lr_param.end_user_column_name || '_OVERRIDE_DEFTYPE'),lsa_vars(lr_param.end_user_column_name || '_OVERRIDE_DEFVAL'),lsa_vars(lr_param.end_user_column_name || '_OVERRIDE_BINDCDL'));
          ELSIF lsa_vars.EXISTS(ln_index || '_OVERRIDE_TYPE') THEN
            lsa_args(ln_index) := DEFAULT_ARG_VAL(lsa_vars,lsa_vset_args,lsa_vars(ln_index || '_OVERRIDE_DEFTYPE'),lsa_vars(ln_index || '_OVERRIDE_DEFVAL'),lsa_vars(ln_index || '_OVERRIDE_BINDCDL'));
          ELSE
            lsa_args(ln_index) := DEFAULT_ARG_VAL(lsa_vars,lsa_vset_args,lr_param.default_type,lr_param.default_value,NULL);
          END IF;
        END IF;
      END IF;
      put_log_line('   arg(' || ln_index || ')=' || lsa_args(ln_index));

     -- ===========================================================================
     -- Validate and get .VALUE, .MEANING, and .ID
     -- ===========================================================================
      IF lsa_args(ln_index) IS NULL THEN
        SELECT lsa_args(ln_index) RECVALUE, lsa_args(ln_index) MEANING, lsa_args(ln_index) ID INTO ls_value_set_rec FROM SYS.DUAL;
        IF lr_param.required_flag = 'N' THEN
          ls_unvalidated := ' (Not Required)';
          put_log_line('     not required');          
        ELSE
          ls_unvalidated := ' !!! REQUIRED BUT NOT PROVIDED';
          put_log_line('     !!! arg(' || ln_index || ') required but not provided !!!');
        END IF;
      ELSIF NOT lsa_sql_text.EXISTS(lr_param.flex_value_set_name) THEN
         put_log_line('    no query for ' || lr_param.flex_value_set_name);
         SELECT lsa_args(ln_index) RECVALUE, lsa_args(ln_index) MEANING, lsa_args(ln_index) ID INTO ls_value_set_rec FROM SYS.DUAL;
      ELSE
        BEGIN
--          put_log_line('lsa_sql_text(' || lr_param.flex_value_set_name || ')=' || lsa_sql_text(lr_param.flex_value_set_name));
          lsa_vset_args(1) := lsa_args(ln_index); -- query validation set by default value
          ln_index2 := 1;
          put_log_line('     Value set ' || lr_param.flex_value_set_name || ' param count: ' || lsa_vars(lr_param.flex_value_set_name || '.PARAMCOUNT'));
          put_log_line('      bind arg 1:');
          put_log_line('        value = ' || lsa_args(ln_index));
          WHILE ln_index2 < lsa_vars(lr_param.flex_value_set_name || '.PARAMCOUNT') LOOP
            ln_index2 := ln_index2 + 1;
            put_log_line('      bind arg ' || ln_index2 || ': ' || lsa_vars(lr_param.flex_value_set_name || '.PARAM' || ln_index2) );
            lsa_vset_args(ln_index2) := lsa_vars(lsa_vars(lr_param.flex_value_set_name || '.PARAM' || ln_index2));
            put_log_line('        value = ' || lsa_vars(lsa_vars(lr_param.flex_value_set_name || '.PARAM' || ln_index2)));
          END LOOP;
          BEGIN
            put_log_line('     Executing sql: ' || lsa_sql_text(lr_param.flex_value_set_name));
            ls_value_set_rec := EXEC_VALUE_SET_SQL(lsa_sql_text(lr_param.flex_value_set_name),lsa_vset_args,ln_index2);

            EXCEPTION WHEN OTHERS THEN BEGIN  -- try querying by id column instead of value column
              put_log_line('     Record not found by value for ' || lr_param.flex_value_set_name || ' -- trying by id');
              ls_value_set_rec := EXEC_VALUE_SET_SQL(REPLACE(lsa_sql_text(lr_param.flex_value_set_name),lr_param.value_column_name||'=:1',lr_param.id_column_name||'=:1'),lsa_vset_args,ln_index2);

              EXCEPTION WHEN OTHERS THEN BEGIN    -- try with outer select (see validation set AP_JE_CATEGORIES where AP_SRS_ACCT_METHOD=Accrual)
                lsa_vset_args(ln_index2+1) := lsa_vset_args(1);
                lsa_vset_args(ln_index2+2) := lsa_vset_args(1);
                ls_value_set_rec := EXEC_VALUE_SET_SQL('SELECT * FROM (' || lsa_sql_text(lr_param.flex_value_set_name) || ') WHERE VALUE=:' || (ln_index2+1) || ' OR ID=:' || (ln_index2+2),lsa_vset_args,ln_index2+2);
                put_log_line('     Validated with outer SELECT where bind args ' || (ln_index2+1) || ' and ' || (ln_index2+2) || ' = bind arg 1 :  ');
                put_log_line('       SELECT * FROM (' || lsa_sql_text(lr_param.flex_value_set_name) || ') WHERE VALUE=:' || (ln_index2+1) || ' OR ID=:' || (ln_index2+2));

                EXCEPTION WHEN OTHERS THEN BEGIN
                  put_log_line('     Record not found by value or id for ' || lr_param.flex_value_set_name || ' -- *** UNVALIDATED - defaulting to provided value but may not be valid for responsibility');
                  ls_unvalidated := ' *** UNVALIDATED'; 

                  SELECT lsa_args(ln_index) RECVALUE, lsa_args(ln_index) MEANING, lsa_args(ln_index) ID INTO ls_value_set_rec FROM SYS.DUAL;
                  -- don't blow up if not all variables are bound since there are form blocks we do not have access to and validation set values may not be needed.
                END;
              END;
            END;
          END;
        END;
      END IF;

      IF NVL(ls_value_set_rec.ID,'<<NULL>>') <> NVL(lsa_args(ln_index),'<<NULL>>') THEN
         lsa_args(ln_index) := ls_value_set_rec.ID;
         put_log_line('   arg(' || ln_index || ')=' || lsa_args(ln_index));
      END IF;

      lsa_vars(lr_param.flex_value_set_name)                := ls_value_set_rec.ID; -- default value-- will be same as .VALUE if ID not defined
      lsa_vars(lr_param.flex_value_set_name  || '.VALUE')   := ls_value_set_rec.RECVALUE;
      lsa_vars(lr_param.flex_value_set_name  || '.MEANING') := ls_value_set_rec.MEANING;
      lsa_vars(lr_param.flex_value_set_name  || '.ID')      := ls_value_set_rec.ID;
      lsa_vars(lr_param.end_user_column_name)               := ls_value_set_rec.ID; -- default value-- will be same as .VALUE if ID not defined
      lsa_vars(lr_param.end_user_column_name || '.VALUE')   := ls_value_set_rec.RECVALUE;
      lsa_vars(lr_param.end_user_column_name || '.MEANING') := ls_value_set_rec.MEANING;
      lsa_vars(lr_param.end_user_column_name || '.ID')      := ls_value_set_rec.ID;
      put_log_line('     ' || lr_param.end_user_column_name || '.VALUE   and ' || lr_param.flex_value_set_name || '.VALUE = '   || ls_value_set_rec.RECVALUE);
      put_log_line('     ' || lr_param.end_user_column_name || '.MEANING and ' || lr_param.flex_value_set_name || '.MEANING = ' || ls_value_set_rec.MEANING);
      put_log_line('     ' || lr_param.end_user_column_name || '.ID      and ' || lr_param.flex_value_set_name || '.ID = '      || ls_value_set_rec.ID);

      ls_formatted_val := FORMAT_VALUE(lsa_args(ln_index),lr_param.format_type);
      IF ls_formatted_val<>lsa_args(ln_index) THEN
         lsa_args(ln_index) := ls_formatted_val;
         put_log_line('   Formatted arg(' || ln_index || ')=' || lsa_args(ln_index));
      END IF;

      IF lb_simulating THEN
        --ls_simulate_output := ls_simulate_output || chr(9) || ln_index || ': ' || lr_param.name || lsa_args(ln_index) || ls_unvalidated;

        -- program XXFIN.XXCEXAVTRXBS has invalid xml character... replacing with -
        -- No need for varied XML element name, so don't need this dynamic sql
        --lsa_vset_args(1) := ln_index || ': ' || REPLACE(lr_param.name,CHR(14844051),'-') || lsa_args(ln_index) || ls_unvalidated;
        --ls_simulate_output := ls_simulate_output || EXEC_DEFAULT_VAL_SQL('SELECT  XMLElement("ARG' || ln_index || '", :1) FROM SYS.DUAL', lsa_vset_args, 1);
        IF SUBSTR(lsa_args(ln_index),1,1)='0' THEN
          lsa_args(ln_index) := '''' || lsa_args(ln_index); -- a value such as 00001 may appear as 1 in Excel if not preceded with a single quote.
        END IF;
        SELECT  ls_simulate_output || '<ARG><num>' || ln_index || '</num>'
                                   || XMLElement("aname", REPLACE(lr_param.param_name,CHR(14844051),'-'))
                                   || XMLElement("vset", lr_param.vset_name)
                                   || '<type>' || lr_param.vset_type || '</type>'
                                   || XMLElement("val", lsa_args(ln_index))
                                   || XMLElement("comment", ls_unvalidated)
                                   || '</ARG>' INTO ls_simulate_output FROM SYS.DUAL;
        ls_unvalidated := '';
      END IF;

      ln_index := ln_index+1;
    END LOOP;
  END IF;


  -- ===========================================================================
  -- Get program name to verify it exists and to add to description
  -- ===========================================================================
  BEGIN
    SELECT P.user_concurrent_program_name
      INTO ls_user_program_name
      FROM FND_CONCURRENT_PROGRAMS_VL P, FND_APPLICATION_VL A
     WHERE A.application_short_name=ls_program_appl_name
       AND A.application_id=P.application_id
       AND P.concurrent_program_name=ls_program_short_name
       AND P.enabled_flag='Y';
    put_log_line('Program: ' || ls_user_program_name);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    IF lb_simulating THEN
      ls_user_program_name := '!!!ERROR - PROGRAM NOT FOUND OR NOT ENABLED!!!';
    ELSE
      RAISE_APPLICATION_ERROR(-20202, 'Program "' || ls_program_appl_name || '.' || ls_program_short_name || '" not found or not enabled');
    END IF;
  END;

  -- ===========================================================================
  -- when simulating, output job details and return
  -- ===========================================================================
  IF lb_simulating THEN
    IF INSTR('0123456789.+-',SUBSTR(ls_program_args,1,1))>0 THEN 
      ls_program_args := '''' || ls_program_args; -- EXCEL may format as a number unless preceded with quote... for instance, these args: 10100912,10100912 may appear as 1,010,091,210,100,910
    END IF;
--    ls_simulate_output := ls_esp_job_name || '.' || ls_esp_job_qual || chr(9) || ls_program_appl_name || chr(9) || ls_program_short_name || chr(9) || ls_user_program_name || chr(9) || ls_program_args || ls_simulate_output;
    SELECT XMLElement("NAME", ls_esp_job_name || '.' || ls_esp_job_qual) ||
           XMLElement("APP", ls_program_appl_name) ||
           XMLElement("PROGRAM", ls_program_short_name) ||
           XMLElement("USER_PROGRAM", ls_user_program_name) ||
           XMLElement("ARGS", ls_program_args) ||
           ls_simulate_output INTO ls_simulate_output FROM SYS.DUAL;
    put_out_line('<JOB>' || ls_simulate_output || '</JOB>');
    put_log_line('<JOB>' || ls_simulate_output || '</JOB>');
    put_log_line('Done Simulating');
    RETURN;
  END IF;


  -- ===========================================================================
  -- Set request options
  -- ===========================================================================
--  b_success := FND_REQUEST.set_options (
--   implicit           => ,    -- default 'NO'
--   protected          => ,    -- default 'NO'
--   language           => ,    -- default NULL
--	 territory          => ,    -- default NULL
--	 datagroup          => ,    -- default NULL
--     numeric_characters => '.,' -- default NULL
--  );

  -- ===========================================================================
  -- See if an XML Publisher template is defined for the program
  -- ===========================================================================
  IF ls_template_app      IS NULL OR ls_template_code      IS NULL OR
     ls_template_language IS NULL OR ls_template_territory IS NULL
  THEN BEGIN
      SELECT application_short_name,template_code       ,default_language        ,default_territory
        INTO ls_template_def_app   ,ls_template_def_code,ls_template_def_language,ls_template_def_territory
        FROM XDO_TEMPLATES_VL
       WHERE ds_app_short_name = ls_program_appl_name  -- 'XXFIN'
         AND data_source_code  = ls_program_short_name -- 'XXAPINVINTAUDIT'
         AND template_status   = 'E' -- enabled (see FND_LOOKUPS WHERE lookup_type ='XDO_DATA_SOURCE_STATUS')
         AND ld_sysdate BETWEEN start_date AND NVL(end_date,ld_sysdate)
         AND ROWNUM=1; -- Oracle SRS Form FNDRSRUN just defaults the first one using this query, if there are multiple

       ls_template_app           := NVL(ls_template_app          ,ls_template_def_app);
       ls_template_code          := NVL(ls_template_code         ,ls_template_def_code);
       ls_template_language      := NVL(ls_template_language     ,ls_template_def_language);
       ls_template_territory     := NVL(ls_template_territory    ,ls_template_def_territory);
       ls_template_output_format := NVL(ls_template_output_format,ls_template_def_output_format);
     EXCEPTION WHEN NO_DATA_FOUND THEN
       NULL; -- no problem; template layout will not be added (unless improperly specified in translation)
    END;
  END IF;

  -- ===========================================================================
  -- setup XML Publisher template layout
  -- ===========================================================================
  IF ls_template_app       IS NOT NULL AND ls_template_code          IS NOT NULL AND ls_template_language IS NOT NULL AND 
     ls_template_territory IS NOT NULL AND ls_template_output_format IS NOT NULL
  THEN
    IF ls_template_territory = '00' OR ls_template_language = '00' THEN
      SELECT DECODE(ls_template_language ,'00',LOWER(iso_language),ls_template_language)
            ,DECODE(ls_template_territory,'00',      iso_territory,ls_template_territory)
        INTO ls_template_language, ls_template_territory
        FROM fnd_languages_vl
       WHERE language_code = FND_GLOBAL.CURRENT_LANGUAGE;
    END IF;

    b_success := FND_REQUEST.add_layout( template_appl_name   => ls_template_app           -- 'XXFIN'
                                        ,template_code        => ls_template_code          -- 'XXAPINVINTAUDIT'
                                        ,template_language    => ls_template_language      -- 'en'
                                        ,template_territory   => ls_template_territory     -- 'US'
                                        ,output_format        => ls_template_output_format -- 'PDF'
                                       );
  END IF;


  -- ===========================================================================
  -- set printer options
  -- ===========================================================================
  IF ln_copies>0 THEN
    IF ls_printer IS NULL AND ls_style IS NULL THEN
      b_success := FND_REQUEST.set_print_options(printer => ls_printer
                                                ,style   => ls_style
                                                ,copies  => ln_copies);
    ELSIF ls_style IS NULL THEN
      b_success := FND_REQUEST.set_print_options(printer => ls_printer
                                                ,copies  => ln_copies);
    ELSIF ls_printer IS NULL THEN
      b_success := FND_REQUEST.set_print_options(style   => ls_style
                                                ,copies  => ln_copies);
    ELSE 
      b_success := FND_REQUEST.set_print_options(copies  => ln_copies);
    END IF;
  END IF;

  -- ===========================================================================
  -- submit the request
  -- ===========================================================================
  ln_conc_request_id := submit_request(p_application => ls_program_appl_name
                                      ,p_program     => ls_program_short_name
                                      ,p_description => ls_description
                                      ,p_args        => lsa_args);
  IF (ln_conc_request_id <=0) THEN
    RAISE_APPLICATION_ERROR(-20203, 'Error submitting job-- submit_request returned request_id <=0');
  ELSE
    put_log_line('Submitted request_id: ' || ln_conc_request_id);
  END IF;

  Errbuf := ln_conc_request_id;

  -- =========================================================================
  -- wait until program completes
  -- =========================================================================
  IF ln_max_wait_seconds >=0 THEN -- 0 means wait indefinitely; -1 means don't wait

    lb_fail_on_warning := DECODE_BOOLEAN(ls_fail_on_warning);
    SELECT TO_NUMBER(((TO_CHAR(SYSDATE, 'J') - 1 ) * 86400) + TO_CHAR(SYSDATE, 'SSSSS')) INTO ln_start_time FROM SYS.DUAL;

    IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => ln_conc_request_id
       ,interval      => ln_check_4done_every_x_secs
       ,max_wait      => ln_max_wait_seconds
       ,phase         => v_phase_desc
       ,status        => v_status_desc
       ,dev_phase     => v_phase_code
       ,dev_status    => v_status_code
       ,message       => v_return_msg
      )
    THEN
      RAISE_APPLICATION_ERROR( -20204, v_return_msg );
    END IF;

    -- even when parent fails, wait for any spawned children to finish
    IF ln_watch_only_to_child_level > 1 THEN -- wait for children -- when 1 then skip because the job has already finished by wait_for_request above

      -- status and phase codes and meanings are in fnd_lookups:
      --   select lookup_code,meaning from fnd_lookups where lookup_type='CP_STATUS_CODE' order by lookup_code
      --   select lookup_code,meaning from fnd_lookups where lookup_type='CP_PHASE_CODE' order by lookup_code
      LOOP
        IF lb_fail_on_warning = TRUE THEN
          SELECT COUNT(CASE WHEN phase_code='C' AND status_code<>'C' THEN 1 ELSE NULL END)
                ,COUNT(CASE WHEN phase_code<>'C' THEN 1 ELSE NULL END)
            INTO ln_completed_unsuccessfully, ln_incomplete
            FROM FND_CONCURRENT_REQUESTS
           WHERE LEVEL<=ln_watch_only_to_child_level
          CONNECT BY PRIOR request_id = parent_request_id
            START WITH request_id = ln_conc_request_id;
        ELSE 
          SELECT COUNT(CASE WHEN phase_code='C' AND status_code<>'C' AND status_code<>'G' THEN 1 ELSE NULL END)
                ,COUNT(CASE WHEN phase_code<>'C' THEN 1 ELSE NULL END)
            INTO ln_completed_unsuccessfully, ln_incomplete
            FROM FND_CONCURRENT_REQUESTS
           WHERE LEVEL<=ln_watch_only_to_child_level
          CONNECT BY PRIOR request_id = parent_request_id
            START WITH request_id = ln_conc_request_id;
        END IF;

        EXIT WHEN ln_incomplete=0;

        IF ln_max_wait_seconds>0 THEN -- 0 means wait indefinitely
          SELECT TO_NUMBER(((TO_CHAR(SYSDATE, 'J') - 1 ) * 86400) + To_Char(SYSDATE, 'SSSSS')) INTO ln_end_time FROM SYS.DUAL;
          IF (ln_end_time - ln_start_time) >= ln_max_wait_seconds THEN
            put_log_line('Max time to wait exceeded');
	          EXIT;
          END IF;
        END IF;

        DBMS_LOCK.SLEEP(ln_check_4done_every_x_secs);
      END LOOP;

      IF ln_completed_unsuccessfully>0 THEN
        IF lb_fail_on_warning THEN
          RAISE_APPLICATION_ERROR( -20205, 'Concurrent Request completed, but job or child had an error or warning.' );
        ELSE
          RAISE_APPLICATION_ERROR( -20206, 'Concurrent Request completed, but job or child had an error.' );
        END IF;
      END IF;

    END IF;  -- done waiting for child jobs

    -- This is the failure message from the parent job, when children completed successfully
    IF (upper(v_status_code) <> 'NORMAL') THEN
      IF (upper(v_status_code) = 'WARNING') THEN
        IF lb_fail_on_warning THEN
          RAISE_APPLICATION_ERROR( -20207, 'Concurrent Request completed with a warning.' );
        END IF;
      ELSE
        RAISE_APPLICATION_ERROR( -20208, 'Concurrent Request completed with an error.' );
      END IF;
    END IF;

  END IF; -- done waiting for completion

  put_log_line('Done');

  EXCEPTION WHEN OTHERS THEN
    PUT_ERR_LINE(ls_esp_job_name,ls_esp_job_qual,SQLERRM);  
    RAISE_APPLICATION_ERROR(-20209, SQLERRM);
END SUBMIT;
   
FUNCTION COUNT_CHR (
  p_str IN VARCHAR2
 ,p_chr IN VARCHAR2
) RETURN NUMBER AS
  n NUMBER := 0;
  i NUMBER := 0;
BEGIN
  IF p_str IS NULL THEN 
    RETURN -1;
  ELSE
    FOR i IN 1..LENGTH(p_str) LOOP
      IF SUBSTR(p_str,i,1)=p_chr THEN 
        n := n + 1;
      END IF;
    END LOOP;
  END IF;
  RETURN n;
END COUNT_CHR;

FUNCTION COUNT_PARMS (
  p_application_name  IN VARCHAR2
 ,p_program_shortname IN VARCHAR2
) RETURN NUMBER AS
  n NUMBER;
BEGIN
  SELECT COUNT(1) INTO n
           FROM FND_DESCR_FLEX_COLUMN_USAGES C, FND_APPLICATION A
          WHERE A.application_short_name=p_application_name
            AND A.application_id = C.application_id
            AND C.descriptive_flexfield_name = '$SRS$.' || p_program_shortname
            AND C.descriptive_flex_context_code = 'Global Data Elements'
            AND C.enabled_flag = 'Y'
      ORDER BY C.column_seq_num;
  RETURN n;
END COUNT_PARMS;


PROCEDURE LIST_MISMATCHED_PARAMS (
  Errbuf             OUT NOCOPY VARCHAR2
 ,Retcode            OUT NOCOPY VARCHAR2
 ,p_translation_name IN VARCHAR2
) IS
  ls_arg         VARCHAR2(240);
  ls_val         VARCHAR2(240);
  ln_pos         NUMBER;
  ln_hold_pos    NUMBER;
  ln_index       NUMBER;
  ln_arg_tran_id NUMBER;
  ln_job_tran_id NUMBER;  
  ln_count       NUMBER;
  ln_problems    NUMBER := 0;
  ld_sysdate     DATE := TRUNC(SYSDATE);
BEGIN
  FOR lr_bad IN -- compare arg count with param count
   (SELECT * FROM
      (SELECT V.source_value1 jobname,V.source_value2 jobqual,V.target_value2 appname,V.target_value3 progname,COUNT_CHR(V.target_value4,',')+1 cc,COUNT_PARMS(V.target_value2,V.target_value3) pc,V.target_value4 args,UPPER(SUBSTR(NVL(V.target_value8,'N'),1,1)) useDefaults
        FROM XX_FIN_TRANSLATEDEFINITION T,XX_FIN_TRANSLATEVALUES V WHERE T.translation_name=p_translation_name AND T.translate_id=V.translate_id 
         AND V.enabled_flag = 'Y' AND ld_sysdate BETWEEN NVL(V.start_date_active,ld_sysdate) AND NVL(V.end_date_active,ld_sysdate)
       ORDER BY V.target_value2,V.target_value3,V.source_value1,source_value2)
    WHERE cc<>pc AND useDefaults<>'Y')
  LOOP
    ln_problems := ln_problems + 1;
    PUT_OUT_LINE(lr_bad.jobname || '.' || lr_bad.jobqual || ': ' || lr_bad.appname || '.' || lr_bad.progname || ' expects ' || lr_bad.pc || ' but has ' || lr_bad.cc || ' -- "' || lr_bad.args || '"');
  END LOOP;

  PUT_OUT_LINE('');

  ln_arg_tran_id := GET_TRANSLATION_ID(REPLACE(p_translation_name,'_JOB_','_ARG_'));
  ln_job_tran_id := GET_TRANSLATION_ID(p_translation_name);  

  FOR lr_job IN -- Check for missing variables
   (SELECT V.source_value1 jobname,V.source_value2 jobqual,V.target_value4 args
    FROM xx_fin_translatedefinition T,xx_fin_translatevalues V where T.translation_name=p_translation_name AND T.translate_id=V.translate_id AND V.target_value4 LIKE '%!%' 
     AND V.enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(V.start_date_active,ld_sysdate) AND NVL(V.end_date_active,ld_sysdate)
    ORDER BY V.source_value1,V.source_value2)
  LOOP
    ln_index    := 0;
    ln_pos      := 0;
    ln_hold_pos := 1;
    LOOP
      ln_pos := INSTR(lr_job.args,',',ln_hold_pos);
      ln_index := ln_index + 1;
      IF ln_pos > 0 THEN
        ls_arg := UPPER(LTRIM(SUBSTR(lr_job.args,ln_hold_pos,ln_pos-ln_hold_pos)));
      ELSE
        ls_arg := UPPER(LTRIM(SUBSTR(lr_job.args,ln_hold_pos)));
      END IF;

      IF SUBSTR(ls_arg,1,1)='!' THEN
        SELECT COUNT(1) INTO ln_count FROM XX_FIN_TRANSLATEVALUES V 
         WHERE V.translate_id = ln_arg_tran_id AND UPPER(V.source_value3)=ls_arg AND V.source_value1='%' AND V.source_value2='%'
           AND V.enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(V.start_date_active,ld_sysdate) AND NVL(V.end_date_active,ld_sysdate);
        IF ln_count = 0 THEN
          SELECT COUNT(1) INTO ln_count FROM XX_FIN_TRANSLATEVALUES V 
           WHERE V.translate_id = ln_arg_tran_id AND UPPER(V.source_value3)=ls_arg AND V.source_value1=lr_job.jobname AND V.source_value2=lr_job.jobqual
             AND V.enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(V.start_date_active,ld_sysdate) AND NVL(V.end_date_active,ld_sysdate);
        END IF;
        IF ln_count = 0 THEN
          ln_problems := ln_problems + 1;
          PUT_OUT_LINE('Variable ' || lr_job.jobname || '.' || lr_job.jobqual || ' not defined: ' || ls_arg);
        ELSIF ln_count > 1 THEN
          ln_problems := ln_problems + 1;
          PUT_OUT_LINE('Variable ' || lr_job.jobname || '.' || lr_job.jobqual || ' over defined: ' || ls_arg);
        END IF;
      END IF;

      EXIT WHEN ln_pos <= 0;
      ln_hold_pos := ln_pos+1;
    END LOOP;

  END LOOP;

  PUT_OUT_LINE('');

  FOR lr_job IN -- Check for dup translations
   (SELECT source_value1 jobname,source_value2 jobqual,target_value1 resp,target_value2 appname,target_value3 progname,target_value4 args
      FROM XX_FIN_TRANSLATEVALUES 
      WHERE translate_id=ln_job_tran_id and source_value1 || '.' || source_value2 IN
           (SELECT source_value1 || '.' || source_value2 FROM XX_FIN_TRANSLATEVALUES WHERE translate_id=ln_job_tran_id
               AND enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate)
            GROUP BY source_value1,source_value2 HAVING COUNT(1)>1)
        AND enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate)
      ORDER BY source_value1,source_value2)
  LOOP
    ln_problems := ln_problems + 1;
    PUT_OUT_LINE('DUPLICATE ' || lr_job.jobname || '.' || lr_job.jobqual || ': ' || lr_job.appname || '.' || lr_job.progname || ' responsibility: ' || lr_job.resp || ' args: "' || lr_job.args || '"');
  END LOOP;

  PUT_OUT_LINE('');
  PUT_OUT_LINE(ln_problems || ' problems found.');

  EXCEPTION WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR( -20210, SQLERRM);
END LIST_MISMATCHED_PARAMS;



PROCEDURE LIST_JOBS (
  Errbuf             OUT NOCOPY VARCHAR2
 ,Retcode            OUT NOCOPY VARCHAR2
 ,p_translation_name IN VARCHAR2
) IS
  ln_job_tran_id        NUMBER := GET_TRANSLATION_ID(p_translation_name);
  ln_jobcount           NUMBER := 0;
  ld_sysdate            DATE   := TRUNC(SYSDATE);
BEGIN
  PUT_OUT_LINE('<?xml version="1.0"?>');
  PUT_OUT_LINE('<JOBS>');
  FOR lr_job IN
   (SELECT source_value1 jobname,source_value2 jobqual,target_value4 args
    FROM xx_fin_translatevalues where translate_id=ln_job_tran_id 
    AND enabled_flag  = 'Y' AND ld_sysdate BETWEEN NVL(start_date_active,ld_sysdate) AND NVL(end_date_active,ld_sysdate)
    ORDER BY source_value1,substr(source_value2,7,2))
  LOOP
    ln_jobcount := ln_jobcount + 1;
    BEGIN
      SUBMIT(Errbuf         => Errbuf
            ,Retcode        => Retcode
            ,p_esp_job_name => lr_job.jobname || '.' || lr_job.jobqual
            ,p_simulate     => 'Y');
    EXCEPTION WHEN OTHERS THEN 
      PUT_LOG_LINE('  Error simulating job ' || lr_job.jobname || '.' || lr_job.jobqual || ' : ' || SQLERRM);
    END;
  END LOOP;

  PUT_OUT_LINE('</JOBS>');
  PUT_LOG_LINE(ln_jobcount || ' active jobs.');

  EXCEPTION WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR( -20211, SQLERRM);
END LIST_JOBS;


END XX_COM_REQUEST_PKG;
/