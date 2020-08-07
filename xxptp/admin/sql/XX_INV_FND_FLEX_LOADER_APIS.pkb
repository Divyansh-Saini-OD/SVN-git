SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_FND_FLEX_LOADER_APIS 
AS
-- +===================================================================================================== +
-- |                  Office Depot - Project Simplify                                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                                          |
-- +======================================================================================================+
-- | Name       : XX_INV_FND_FLEX_LOADER_APIS                                                             |
-- | Description: Modified FND_FLEX_LOADER_APIS for adding timestamp to creation_date and last_update_date|
-- |              of value set values.                                                                    |
-- |                                                                                                      |
-- |Change Record:                                                                                        |
-- |===============                                                                                       |
-- |Version   Date         Author             Remarks                                                     |
-- |=======   ==========   ===============    ==============================                              |
-- |DRAFT 1A  25-JUL-2007  Siddharth Singh    Modified FND_FLEX_LOADER_APIS for adding timestamp to       |
-- |                                          creation_date and last_update_date of value set values      |
-- |1.0       01-AUG-2007  Jayshree Kale      Reviewed                                                    |
-- |1.1       22-JUL-2016  Madhu Bolli        Retrofitted for 12.2.5 (Above FND_FLEX_LOADER_APIS version -|
-- |											:AFFFLDRB.pls 120.25.12020000.3                           |
-- |1.2       09-SEP-2016  Madhu Bolli        Retrofitted for 12.2.5 (Above FND_FLEX_LOADER_APIS version -|
-- |											:AFFFLDRB.pls 120.25.12020000.5                           |
-- +======================================================================================================+




-- ==================================================
-- Constants and Types.
-- ==================================================
g_newline               VARCHAR2(10);
g_api_name              CONSTANT VARCHAR2(10) := 'LDR.';
g_date_mask             CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
g_default_lud           DATE;
g_debug_on              BOOLEAN;
g_left_margin           VARCHAR2(100);
g_line_size             CONSTANT NUMBER := 99;
g_lub_seed_boundary     CONSTANT NUMBER := 1000;
g_unset_lub             CONSTANT NUMBER := -9;
g_unset_lud             CONSTANT DATE := To_date('1234/05/06 07:08:09', g_date_mask);
g_numof_changes         NUMBER;
g_numof_changes_kff_str NUMBER;
g_srs_loader_flex_name  VARCHAR2(40);
g_default_argument      CONSTANT VARCHAR2(100) := chr(0);
g_nvl_value             CONSTANT VARCHAR2(100) := '$FLEX$.$NULL$';
g_null_value_constant   CONSTANT VARCHAR2(100) := fnd_load_util.null_value();
g_null_value            VARCHAR2(100);
g_lock_handle           VARCHAR2(128);
g_root_error            VARCHAR2(32000);
g_call_stack            VARCHAR2(32000);
g_savepoint_entity_name VARCHAR2(30);
g_is_commit_ok          BOOLEAN;

ENTITY_VALUE_SET        CONSTANT VARCHAR2(30) := 'VALUE_SET';
ENTITY_DESC_FLEX        CONSTANT VARCHAR2(30) := 'DESC_FLEX';
ENTITY_KEY_FLEX         CONSTANT VARCHAR2(30) := 'KEY_FLEX';

-- ERROR_ constants
ERROR_LDR_GENERIC              CONSTANT NUMBER := -20000;
ERROR_WHEN_OTHERS              CONSTANT NUMBER := -20001;
ERROR_NOT_EXIST                CONSTANT NUMBER := -20002;
ERROR_UNABLE_TO_LOCK           CONSTANT NUMBER := -20003;
ERROR_UNKNOWN_UP_PHASE         CONSTANT NUMBER := -20004;

ERROR_VST_GENERIC              CONSTANT NUMBER := -20100;
ERROR_VST_TYPE_MISMATCH        CONSTANT NUMBER := -20101;
ERROR_VST_NOT_TABLE_VST        CONSTANT NUMBER := -20102;
ERROR_VST_NOT_UEXIT_VST        CONSTANT NUMBER := -20103;
ERROR_VST_INVALID_PARENT       CONSTANT NUMBER := -20104;
ERROR_VST_INVALID_CH_RNG       CONSTANT NUMBER := -20105;

ERROR_DFF_GENERIC              CONSTANT NUMBER := -20200;
ERROR_DFF_NO_SRS_LOCK          CONSTANT NUMBER := -20201;
ERROR_DFF_NO_LDT_DATA          CONSTANT NUMBER := -20202;
ERROR_DFF_INV_PROT_FLG         CONSTANT NUMBER := -20203;
ERROR_DFF_COL_USED             CONSTANT NUMBER := -20204;
ERROR_DFF_COL_NOT_REG          CONSTANT NUMBER := -20205;

ERROR_KFF_GENERIC              CONSTANT NUMBER := -20300;
ERROR_KFF_NO_QUALIFIERS        CONSTANT NUMBER := -20301;
ERROR_KFF_NOT_QUALIFIED        CONSTANT NUMBER := -20302;
ERROR_KFF_COL_USED             CONSTANT NUMBER := -20303;
ERROR_KFF_COL_NOT_REG          CONSTANT NUMBER := -20304;


SUBTYPE app_type          IS fnd_application%ROWTYPE;
SUBTYPE tbl_type          IS fnd_tables%ROWTYPE;
SUBTYPE col_type          IS fnd_columns%ROWTYPE;
SUBTYPE resp_type         IS fnd_responsibility%ROWTYPE;

SUBTYPE vst_set_type      IS fnd_flex_value_sets%ROWTYPE;
SUBTYPE vst_tbl_type      IS fnd_flex_validation_tables%ROWTYPE;
SUBTYPE vst_evt_type      IS fnd_flex_validation_events%ROWTYPE;
SUBTYPE vst_scr_type      IS fnd_flex_value_rules%ROWTYPE;
SUBTYPE vst_scr_tl_type   IS fnd_flex_value_rules_tl%ROWTYPE;
SUBTYPE vst_scl_type      IS fnd_flex_value_rule_lines%ROWTYPE;
SUBTYPE vst_scu_type      IS fnd_flex_value_rule_usages%ROWTYPE;
SUBTYPE vst_rgr_type      IS fnd_flex_hierarchies%ROWTYPE;
SUBTYPE vst_rgr_tl_type   IS fnd_flex_hierarchies_tl%ROWTYPE;
SUBTYPE vst_val_type      IS fnd_flex_values%ROWTYPE;
SUBTYPE vst_val_tl_type   IS fnd_flex_values_tl%ROWTYPE;
SUBTYPE vst_vlh_type      IS fnd_flex_value_norm_hierarchy%ROWTYPE;

SUBTYPE dff_flx_type      IS fnd_descriptive_flexs%ROWTYPE;
SUBTYPE dff_flx_tl_type   IS fnd_descriptive_flexs_tl%ROWTYPE;
SUBTYPE dff_ref_type      IS fnd_default_context_fields%ROWTYPE;
SUBTYPE dff_ctx_type      IS fnd_descr_flex_contexts%ROWTYPE;
SUBTYPE dff_ctx_tl_type   IS fnd_descr_flex_contexts_tl%ROWTYPE;
SUBTYPE dff_seg_type      IS fnd_descr_flex_column_usages%ROWTYPE;
SUBTYPE dff_seg_tl_type   IS fnd_descr_flex_col_usage_tl%ROWTYPE;

SUBTYPE kff_flx_type      IS fnd_id_flexs%ROWTYPE;
SUBTYPE kff_flq_type      IS fnd_segment_attribute_types%ROWTYPE;
SUBTYPE kff_sgq_type      IS fnd_value_attribute_types%ROWTYPE;
SUBTYPE kff_sgq_tl_type   IS fnd_val_attribute_types_tl%ROWTYPE;
SUBTYPE kff_str_type      IS fnd_id_flex_structures%ROWTYPE;
SUBTYPE kff_str_tl_type   IS fnd_id_flex_structures_tl%ROWTYPE;
SUBTYPE kff_wfp_type      IS fnd_flex_workflow_processes%ROWTYPE;
SUBTYPE kff_sha_type      IS fnd_shorthand_flex_aliases%ROWTYPE;
SUBTYPE kff_cvr_type      IS fnd_flex_validation_rules%ROWTYPE;
SUBTYPE kff_cvr_tl_type   IS fnd_flex_vdation_rules_tl%ROWTYPE;
SUBTYPE kff_cvl_type      IS fnd_flex_validation_rule_lines%ROWTYPE;
SUBTYPE kff_seg_type      IS fnd_id_flex_segments%ROWTYPE;
SUBTYPE kff_seg_tl_type   IS fnd_id_flex_segments_tl%ROWTYPE;
SUBTYPE kff_fqa_type      IS fnd_segment_attribute_values%ROWTYPE;

TYPE vtv_rec_type IS RECORD
  (
   id_flex_application_id NUMBER,
   id_flex_code           VARCHAR2(10),
   segment_attribute_type VARCHAR2(100),
   value_attribute_type   VARCHAR2(100),
   assignment_date        DATE,
   lookup_type            VARCHAR2(100),
   default_value          VARCHAR2(100),
   qualifier_value        VARCHAR2(100)
   );

TYPE vtv_arr_type IS TABLE OF vtv_rec_type INDEX BY BINARY_INTEGER;
TYPE dff_seg_arr_type IS TABLE OF dff_seg_type INDEX BY BINARY_INTEGER;

-- ==================================================
-- Helper functions.
-- ==================================================

-- ------------------------------------------------
FUNCTION apps_schema 
  RETURN VARCHAR2
IS
   l_schema VARCHAR2(30);
BEGIN
   SELECT oracle_username
     INTO l_schema
     FROM fnd_oracle_userid
     WHERE read_only_flag = 'U';

   RETURN l_schema;

   EXCEPTION 
      WHEN OTHERS THEN
         RETURN NULL;
END apps_schema;

-- -------------------------------------------------
PROCEDURE actualize_view
  (p_view_name                    IN VARCHAR2,
   p_flex_indicator               IN VARCHAR2,
   p_app_id                       IN NUMBER,
   p_app_flex                     IN VARCHAR2)
IS
   l_sys_context VARCHAR2(500);
   l_ed_name VARCHAR2(500);
   l_db_version VARCHAR2(64);
   l_view_owner VARCHAR2(30);
   l_view_name VARCHAR2(30);
   l_edition_name VARCHAR2(30);
   l_curr_ed_name VARCHAR2(30);

BEGIN

-- The following checks for database versions must be done in ascending
-- version sequence, since older database versions of dbms_db_version
-- may not have the ver_le_xxxx check included.  The conditional compilation 
-- does not do further $elsif evaluation once the DBMS_DB_VERSION check is 
-- true. In this case, we do not want the actual code included to be compiled 
-- unless the DB version is 11.2 or later.

   $if DBMS_DB_VERSION.VER_LE_10_1 $then
      NULL;
   $elsif DBMS_DB_VERSION.VER_LE_10_2 $then
      NULL;
   $elsif DBMS_DB_VERSION.VER_LE_11_1 $then
      NULL;
   $else
      l_view_owner := apps_schema();
     BEGIN
      IF (p_flex_indicator = 'K') THEN
         SELECT concatenated_segs_view_name
           INTO l_view_name
           FROM fnd_id_flexs
           WHERE application_id = p_app_id
           AND id_flex_code = p_app_flex;
      ELSIF (p_flex_indicator = 'D') THEN
         SELECT concatenated_segs_view_name
           INTO l_view_name
           FROM fnd_descriptive_flexs
           WHERE application_id = p_app_id
           AND descriptive_flexfield_name = p_app_flex;
      ELSE
         l_view_name := UPPER(p_view_name);
      END IF;

      EXCEPTION
         WHEN OTHERS THEN
            NULL;
     END;

     BEGIN
      IF (l_view_name IS NOT NULL) THEN
         SELECT edition_name
           INTO l_edition_name
           FROM all_objects
           WHERE owner = l_view_owner
           AND object_name = l_view_name
           AND object_type = 'VIEW';

          IF (l_edition_name < sys_context('userenv','current_edition_name')) THEN
            -- actualize view object into current edition
             execute immediate 'alter view "'||l_view_owner||'","'||l_view_name||'"compile';
          END IF;
      END IF;

      EXCEPTION
         WHEN OTHERS THEN
            NULL;
     END;
   $end

END actualize_view;


-- --------------------------------------------------
PROCEDURE set_context
  (p_name                         IN VARCHAR2,
   p_value                        IN VARCHAR2)
  IS
BEGIN
   NULL;
END set_context;

-- --------------------------------------------------
PROCEDURE set_debugging(p_debug_flag IN VARCHAR2)
  IS
BEGIN
   IF (Nvl(Upper(Substr(p_debug_flag,1,1)),'N') = 'Y') THEN
      g_debug_on := TRUE;
    ELSE
      g_debug_on := FALSE;
   END IF;
END set_debugging;

-- --------------------------------------------------
FUNCTION indent_lines(p_text   IN VARCHAR2,
                      p_indent IN NUMBER) RETURN VARCHAR2
  IS
     l_result    VARCHAR2(32000);
     l_vc2       VARCHAR2(32000);
     l_text      VARCHAR2(32000);
     l_lm_length NUMBER;
     l_nl_used   BOOLEAN;
     l_nl_pos    NUMBER;
     l_cut_pos   NUMBER;
BEGIN
   l_text := p_text;
   l_lm_length := Nvl(Length(g_left_margin), 0);
   --
   -- +---------------------------------------------
   -- |left
   -- |margin  indent
   -- <------><---->
   -- | | | | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n
   -- | | | |       xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n
   -- | | | |       xxxxxxxxxxxxxxxxxxxxxxx\n
   -- <-------------------------------------------->
   -- |           line size
   -- +---------------------------------------------
   --
   --
   -- First Line.
   --

   l_nl_pos := Instr(l_text, g_newline, 1, 1);
   l_nl_used := FALSE;

   IF ((0 < l_nl_pos) AND (l_nl_pos < g_line_size - l_lm_length)) THEN
      l_cut_pos := l_nl_pos - 1;
      l_nl_used := TRUE;
    ELSE
      l_cut_pos := g_line_size - l_lm_length;
   END IF;

   l_result := (g_left_margin ||
                Substr(l_text, 1, l_cut_pos) ||
                g_newline);

   IF (l_nl_used) THEN
      l_cut_pos := l_cut_pos + 1;
   END IF;

   l_text := Substr(l_text, l_cut_pos + 1);

   --
   -- Remaining Lines:
   --
   WHILE (l_text IS NOT NULL) LOOP
      l_nl_pos := Instr(l_text, g_newline, 1, 1);
      l_nl_used := FALSE;

      IF ((0 < l_nl_pos) AND (l_nl_pos < g_line_size - p_indent - l_lm_length)) THEN
         l_cut_pos := l_nl_pos - 1;
         l_nl_used := TRUE;
       ELSE
         l_cut_pos := g_line_size - p_indent - l_lm_length;
      END IF;

      l_result := (l_result ||
                   g_left_margin ||
                   Rpad(' ', p_indent, ' ') ||
                   Substr(l_text, 1, l_cut_pos) ||
                   g_newline);

      IF (l_nl_used) THEN
         l_cut_pos := l_cut_pos + 1;
      END IF;

      l_text := Substr(l_text, l_cut_pos + 1);
   END LOOP;
   RETURN(l_result);
EXCEPTION
   WHEN OTHERS THEN
      RETURN(p_text);
END indent_lines;

-- --------------------------------------------------
PROCEDURE debug_raw(p_debug IN VARCHAR2)
  IS
BEGIN
   --
   -- Sample Output :
   --
   --<debug>
   --
   IF (g_debug_on) THEN
      fnd_file.put(fnd_file.Log, p_debug);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END debug_raw;

-- --------------------------------------------------
PROCEDURE debug(p_debug IN VARCHAR2)
  IS
BEGIN
   --
   -- Sample Output :
   --
   -- left
   -- margin
   --<------>
   --| | | | <debug>
   --
   IF (g_debug_on) THEN
      debug_raw(indent_lines(p_debug, 9));
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END debug;

-- --------------------------------------------------
PROCEDURE debug(p_func_name  IN VARCHAR2,
                p_debug1     IN VARCHAR2,
                p_debug2     IN VARCHAR2 DEFAULT NULL,
                p_debug3     IN VARCHAR2 DEFAULT NULL,
                p_debug4     IN VARCHAR2 DEFAULT NULL,
                p_debug5     IN VARCHAR2 DEFAULT NULL)
  IS
BEGIN
   --
   -- Sample Output :
   --
   -- left
   -- margin
   --<------>
   --| | | | FUNCTION:LDR.up_kff_column()
   --| | | | DEBUG   :UMODE:,CMODE:,APPS:SQLGL,KFF:GL#,COL:SEGMENT9,USG:K
   --| | | |
   --
   IF (g_debug_on) THEN
      debug('FUNCTION:' || p_func_name);
      debug('DEBUG   :' || p_debug1);
      IF (p_debug2 IS NOT NULL) THEN
         debug('DEBUG   :' || p_debug2);
      END IF;
      IF (p_debug3 IS NOT NULL) THEN
         debug('DEBUG   :' || p_debug3);
      END IF;
      IF (p_debug4 IS NOT NULL) THEN
         debug('DEBUG   :' || p_debug4);
      END IF;
      IF (p_debug5 IS NOT NULL) THEN
         debug('DEBUG   :' || p_debug5);
      END IF;
      debug(' ');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END debug;

-- --------------------------------------------------
PROCEDURE debug_exception(p_func_name  IN VARCHAR2,
                          p_error      IN VARCHAR2)
  IS
     l_sqlerrm VARCHAR2(32000) := NULL;
BEGIN
   --
   -- Sample Output :
   --
   --|  ERROR in flex loader function :'LDR.get_app(short_name, P)'
   --|  DEBUG   :Error...
   --|  SQLERRM :ORA-0000: normal, successful completion
   --|
   --
   IF (g_debug_on) THEN
      IF (SQLCODE <> 0) THEN
         l_sqlerrm := indent_lines('SQLERRM :' || Sqlerrm, 9);
       ELSE
         --
         -- SQLERRM is already indented.
         --
         l_sqlerrm := g_left_margin || 'SQLERRM :' || Sqlerrm || g_newline;
      END IF;

      debug('ERROR in flex loader function :'''|| p_func_name || '''');
      debug('DEBUG   :' || p_error);
      debug_raw(l_sqlerrm);
      debug(' ');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END debug_exception;

-- --------------------------------------------------
PROCEDURE debug_exception_top_level(p_func_name IN VARCHAR2)
  IS
BEGIN
   IF (g_debug_on) THEN
      debug_exception(p_func_name, 'Top Level EXCEPTION OTHERS.');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END debug_exception_top_level;

-- --------------------------------------------------
PROCEDURE raise_error(p_func_name  IN VARCHAR2,
                      p_error_code IN NUMBER,
                      p_error      IN VARCHAR2,
                      p_solution   IN VARCHAR2 DEFAULT NULL)
  IS
     l_error VARCHAR2(32000);
BEGIN
   IF (g_debug_on) THEN
      debug_exception(p_func_name, p_error);
   END IF;

   IF (p_solution IS NULL) THEN
      l_error := p_error || '.';
    ELSE
      l_error := p_error || '. ' || p_solution || '.';
   END IF;

   raise_application_error(p_error_code, l_error, TRUE);

EXCEPTION
   WHEN OTHERS THEN
      IF (g_root_error IS NULL) THEN
         --
         -- This is the main error, record the error, and the call stack.
         --
         g_root_error := dbms_utility.format_error_stack();
         g_call_stack := dbms_utility.format_call_stack();
         g_is_commit_ok := FALSE;
      END IF;
      RAISE;
END raise_error;

-- --------------------------------------------------
PROCEDURE raise_not_exist(p_func_name IN VARCHAR2,
                          p_solution  IN VARCHAR2,
                          p_key1      IN VARCHAR2,
                          p_value1    IN VARCHAR2,
                          p_key2      IN VARCHAR2 DEFAULT NULL,
                          p_value2    IN VARCHAR2 DEFAULT NULL,
                          p_key3      IN VARCHAR2 DEFAULT NULL,
                          p_value3    IN VARCHAR2 DEFAULT NULL,
                          p_key4      IN VARCHAR2 DEFAULT NULL,
                          p_value4    IN VARCHAR2 DEFAULT NULL,
                          p_key5      IN VARCHAR2 DEFAULT NULL,
                          p_value5    IN VARCHAR2 DEFAULT NULL,
                          p_key6      IN VARCHAR2 DEFAULT NULL,
                          p_value6    IN VARCHAR2 DEFAULT NULL,
                          p_key7      IN VARCHAR2 DEFAULT NULL,
                          p_value7    IN VARCHAR2 DEFAULT NULL)
  IS
     l_error VARCHAR2(32000);
BEGIN
   l_error := (Upper(p_func_name) || ' is not able to find ' ||
               Upper(p_key1) || ':''' || p_value1 || '''');
   IF (p_key2 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key2) || ':''' || p_value2 || '''';
   END IF;
   IF (p_key3 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key3) || ':''' || p_value3 || '''';
   END IF;
   IF (p_key4 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key4) || ':''' || p_value4 || '''';
   END IF;
   IF (p_key5 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key5) || ':''' || p_value5 || '''';
   END IF;
   IF (p_key6 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key6) || ':''' || p_value6 || '''';
   END IF;
   IF (p_key7 IS NOT NULL) THEN
      l_error := l_error || ', ' || Upper(p_key7) || ':''' || p_value7 || '''';
   END IF;

   raise_error(p_func_name, ERROR_NOT_EXIST, l_error, p_solution);
   --
   -- No exception handling here.
   --
END raise_not_exist;

-- --------------------------------------------------
FUNCTION signature(p_func_name IN VARCHAR2,
                   p_arg1      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg2      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg3      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg4      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg5      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg6      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg7      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg8      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg9      IN VARCHAR2 DEFAULT g_default_argument,
                   p_arg10     IN VARCHAR2 DEFAULT g_default_argument)
  RETURN VARCHAR2
  IS
     l_signature VARCHAR2(32000);

     PROCEDURE add_argument(px_signature IN OUT nocopy VARCHAR2,
                            p_arg        IN VARCHAR2 DEFAULT g_default_argument)
       IS
     BEGIN
        IF (Nvl(p_arg, 'X') <> g_default_argument) THEN
           px_signature := px_signature || ', ' || p_arg;
        END IF;
     END add_argument;

BEGIN
   l_signature := p_func_name || '(';

   --
   -- Add first argument (no comma before first arg)
   --
   IF (Nvl(p_arg1, 'X') <> g_default_argument) THEN
      l_signature := l_signature || p_arg1;
   END IF;

   --
   -- Add other arguments
   --
   add_argument(l_signature, p_arg2);
   add_argument(l_signature, p_arg3);
   add_argument(l_signature, p_arg4);
   add_argument(l_signature, p_arg5);
   add_argument(l_signature, p_arg6);
   add_argument(l_signature, p_arg7);
   add_argument(l_signature, p_arg8);
   add_argument(l_signature, p_arg9);
   add_argument(l_signature, p_arg10);

   l_signature := l_signature || ')';

   RETURN l_signature;
EXCEPTION
   WHEN OTHERS THEN
      RETURN p_func_name || '(signature)';
END signature;

-- --------------------------------------------------
PROCEDURE raise_when_others(p_func_name IN VARCHAR2,
                            p_arg1      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg2      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg3      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg4      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg5      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg6      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg7      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg8      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg9      IN VARCHAR2 DEFAULT g_default_argument,
                            p_arg10     IN VARCHAR2 DEFAULT g_default_argument)
IS
   l_error VARCHAR2(32000);
BEGIN
   l_error := signature(p_func_name,
                        p_arg1, p_arg2, p_arg3, p_arg4, p_arg5,
                        p_arg6, p_arg7, p_arg8, p_arg9, p_arg10) ||
     ' raised exception';

   raise_error(p_func_name, ERROR_WHEN_OTHERS, l_error);

   -- No exception handling here
end raise_when_others;

-- --------------------------------------------------
PROCEDURE report_exception
  IS
     PROCEDURE print(p_text IN VARCHAR2)
       IS
     BEGIN
        fnd_file.put_line(fnd_file.Log, p_text);
     END print;
BEGIN
   print(Rpad('=', 80, '='));
   print(g_root_error);
   print(' ');
   print(Rpad('-', 5, '-') || ' Error Message Stack ' || Rpad('-', 5, '-'));
   print(dbms_utility.format_error_stack());
   print(' ');
   print(dbms_utility.format_call_stack());
   print(rpad('=', 80, '='));

   g_root_error := NULL;
   g_call_stack := NULL;

EXCEPTION
   WHEN OTHERS THEN
      g_root_error := NULL;
      g_call_stack := NULL;

      raise_when_others('report_exception');
END report_exception;

-- --------------------------------------------------
PROCEDURE report_public_api_exception
  (p_func_name IN VARCHAR2,
   p_arg1      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg2      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg3      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg4      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg5      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg6      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg7      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg8      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg9      IN VARCHAR2 DEFAULT g_default_argument,
   p_arg10     IN VARCHAR2 DEFAULT g_default_argument)
  IS
BEGIN
   IF (g_debug_on) THEN
      --
      -- GEO!!
      --
      debug_exception_top_level(p_func_name);
   END IF;

   BEGIN
      --
      -- Add the caller's signature to the exception stack
      --
      raise_when_others(p_func_name,
                        p_arg1, p_arg2, p_arg3, p_arg4, p_arg5,
                        p_arg6, p_arg7, p_arg8, p_arg9, p_arg10);
   EXCEPTION
      WHEN OTHERS THEN
         report_exception();
   END;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others('report_public_api_exception',
                        p_func_name);
END report_public_api_exception;

-- --------------------------------------------------
PROCEDURE set_left_margin(p_indent_unindent IN NUMBER)
  IS
BEGIN
   IF (p_indent_unindent = 1) THEN
      g_left_margin := g_left_margin || '| ';
    ELSIF (p_indent_unindent = -1) THEN
      g_left_margin := Rtrim(Rtrim(g_left_margin, ' '), '|');
    ELSE
      NULL;
   END IF;
END set_left_margin;

-- --------------------------------------------------
PROCEDURE init(p_entity       IN VARCHAR2,
               p_upload_phase IN VARCHAR2)
  IS
     l_func_name    VARCHAR2(80);
     l_vc2          VARCHAR2(2000);
     l_upload_phase VARCHAR2(100);
BEGIN
   l_func_name := g_api_name || 'init()';

   l_upload_phase := Nvl(p_upload_phase, 'LEAF');
   IF (g_debug_on) THEN
      --
      -- Sample Output:
      --
      --
      --| | +--KFF_COLUMN------------ 2002/08/22 14:21:15 --
      --| | |
      --
      IF (l_upload_phase IN ('BEGIN', 'LEAF')) THEN
         l_vc2 := (Rpad(g_left_margin || '+-' || '-' || p_entity,
                        g_line_size - 23,
                        '-') ||
                   ' ' || To_char(Sysdate, g_date_mask) ||
                   ' -' || '-' ||
                   g_newline);
         debug_raw(l_vc2);
         set_left_margin(1);
         debug(' ');
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
END init;

-- --------------------------------------------------
PROCEDURE done(p_entity       IN VARCHAR2,
               p_upload_phase IN VARCHAR2)
  IS
     l_func_name    VARCHAR2(80);
     l_vc2          VARCHAR2(2000);
     l_upload_phase VARCHAR2(100);
BEGIN
   l_func_name := g_api_name || 'done()';

   l_upload_phase := Nvl(p_upload_phase, 'LEAF');
   IF (g_debug_on) THEN
      --
      -- Sample Output:
      --
      --| | | +---------------------------------KFF_COLUMN--
      --| | |
      --
      IF (l_upload_phase IN ('LEAF', 'END')) THEN
         set_left_margin(-1);
         l_vc2 := (Rpad(g_left_margin || '+',
                        g_line_size - Length(p_entity) - 2,
                        '-') ||
                   p_entity || '--' ||
                   g_newline);
         debug_raw(l_vc2);
         debug(' ');
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
END done;

-- --------------------------------------------------
PROCEDURE start_transaction(p_entity_name IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'start_transaction()';

   IF (g_savepoint_entity_name IS NOT NULL) THEN
      raise_error(l_func_name, ERROR_LDR_GENERIC,
                  'Flex developer error. ' ||
                  'Loader should not start a new transaction while it is ' ||
                  'processing an existing transaction. Entity Name of ' ||
                  'existing transaction: ' || g_savepoint_entity_name);
   END IF;

   IF (p_entity_name = ENTITY_VALUE_SET) THEN
      SAVEPOINT savepoint_value_set;

    ELSIF (p_entity_name = ENTITY_DESC_FLEX) THEN
      SAVEPOINT savepoint_desc_flex;

    ELSIF (p_entity_name = ENTITY_KEY_FLEX) THEN
      SAVEPOINT savepoint_key_flex;

    ELSE
      raise_error(l_func_name, ERROR_LDR_GENERIC,
                  'Flex developer error. Unknown Entity Name');
   END IF;

   g_savepoint_entity_name := p_entity_name;
   g_is_commit_ok := TRUE;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others('start_transaction',
                        p_entity_name);
END start_transaction;

-- --------------------------------------------------
PROCEDURE finish_transaction(p_entity_name IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'finish_transaction()';

   IF (g_savepoint_entity_name IS NULL) THEN
      raise_error(l_func_name, ERROR_LDR_GENERIC,
                  'Flex developer error. No transaction was started');
   END IF;

   IF (g_is_commit_ok IS NULL) THEN
      raise_error(l_func_name, ERROR_LDR_GENERIC,
                  'Flex developer error. Commit state is set to null');
    ELSIF (g_is_commit_ok) THEN
      --
      -- Let FNDLOAD do the commit.
      --
      NULL;

    ELSE
      --
      -- There was an error, rollback to the savepoint.
      --
      IF (g_savepoint_entity_name = ENTITY_VALUE_SET) THEN
         ROLLBACK TO savepoint_value_set;

       ELSIF (g_savepoint_entity_name = ENTITY_DESC_FLEX) THEN
         ROLLBACK TO savepoint_desc_flex;

       ELSIF (g_savepoint_entity_name = ENTITY_KEY_FLEX) THEN
         ROLLBACK TO savepoint_key_flex;

       ELSE
      raise_error(l_func_name, ERROR_LDR_GENERIC,
                  'Flex developer error. Unknown Savepoint Entity Name: ' ||
                  g_savepoint_entity_name);

      END IF;
   END IF;

   g_savepoint_entity_name := NULL;
   g_is_commit_ok := NULL;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others('finish_transaction',
                        p_entity_name);
END finish_transaction;

-- --------------------------------------------------
FUNCTION is_upload_allowed(p_custom_mode                  IN VARCHAR2,
                           p_file_owner                   IN VARCHAR2,
                           p_file_last_update_date        IN VARCHAR2,
                           p_db_last_updated_by           IN NUMBER,
                           p_db_last_update_date          IN DATE,
                           x_file_who                     IN OUT nocopy fnd_flex_loader_apis.who_type)
  RETURN BOOLEAN
  IS
     l_func_name  VARCHAR2(80);
     l_db_who     who_type;
     l_file_owner VARCHAR2(100);
     l_db_owner   VARCHAR2(100);
     l_return     BOOLEAN;
     l_vc2        VARCHAR2(100);
BEGIN
   l_func_name := g_api_name || 'is_upload_allowed()';
   --
   -- Set File (Source) WHO.
   --
   BEGIN
      l_file_owner                 := p_file_owner;
      x_file_who.last_updated_by   := fnd_load_util.owner_id(l_file_owner);
      --
      -- Remove the time component from file LUD. We used to use Sysdate for
      -- NULL case, but it is better to use a fixed date.
      --
     /* x_file_who.last_update_date  := Trunc(Nvl(To_date(p_file_last_update_date,
                                                        g_date_mask),
                                                g_default_lud));
     */ -- Commented on 25/07/2007 Gowri                                                
     
     --Added on on 25/07/2007 Gowri
     x_file_who.last_update_date  := Nvl(To_date(p_file_last_update_date, g_date_mask), g_default_lud);

      x_file_who.last_update_login := 0;
      x_file_who.created_by        := x_file_who.last_updated_by;
      x_file_who.creation_date     := x_file_who.last_update_date;
   EXCEPTION
      WHEN OTHERS THEN
         l_file_owner                 := 'SEED'; -- 1
         x_file_who.last_updated_by   := fnd_load_util.owner_id(l_file_owner);
         --x_file_who.last_update_date  := Trunc(g_default_lud);-- Commented on 25/07/2007 Gowri  
         
         --Added on on 25/07/2007 Gowri
         x_file_who.last_update_date  := g_default_lud; 
         
         x_file_who.last_update_login := 0;
         x_file_who.created_by        := x_file_who.last_updated_by;
         x_file_who.creation_date     := x_file_who.last_update_date;
   END;

   --
   -- Set DB (Destination) WHO
   --
   l_db_who.last_updated_by   := Nvl(p_db_last_updated_by,
                                     x_file_who.last_updated_by);
   l_db_owner                 := fnd_load_util.owner_name(l_db_who.last_updated_by);
   l_db_who.last_update_date  := Nvl(p_db_last_update_date,
                                     x_file_who.last_update_date - 1);
   l_db_who.last_update_login := 0;
   l_db_who.created_by        := l_db_who.last_updated_by;
   l_db_who.creation_date     := l_db_who.last_update_date;

   --
   -- Check if UPLOAD is allowed. i.e. no customizations.
   --
   -- Return TRUE  if
   -- - custom_mode = 'FORCE'.
   -- - db (destination) is owned by SEED but file (source)is not owned by SEED.
   -- - owners are same but destination is older.
   --
   --  IF ((p_custom_mode = 'FORCE') OR
   --   ((l_db_who.last_updated_by = 1) AND
   --   (x_file_who.last_updated_by <> 1)) OR
   --   ((l_db_who.last_updated_by = x_file_who.last_updated_by) AND
   --   (l_db_who.last_update_date <= x_file_who.last_update_date)))

   l_return := fnd_load_util.upload_test
     (p_file_id     => x_file_who.last_updated_by,
      p_file_lud    => x_file_who.last_update_date,
      p_db_id       => l_db_who.last_updated_by,
      p_db_lud      => l_db_who.last_update_date,
      p_custom_mode => p_custom_mode);

   IF (l_return IS NULL) THEN
      l_vc2 := 'NULL';
      l_return := FALSE;
    ELSIF (l_return) THEN
      l_vc2 := 'TRUE';
    ELSE
      l_vc2 := 'FALSE';
   END IF;

   IF (g_debug_on) THEN
      --
      -- Print out [F]ile/[D]atabase [O]wner/last_update_[D]ate.
      --
      IF (p_custom_mode IS NOT NULL) THEN
         l_vc2 := l_vc2 || ' (CUSTOM_MODE = ' || p_custom_mode || ')';
      END IF;
      debug(l_func_name || ' = ' || l_vc2,
            ('File LUB: ' || Rpad(x_file_who.last_updated_by ||
                                  '/' || l_file_owner, 15) ||
             '  LUD: ' || To_char(x_file_who.last_update_date, g_date_mask)),
            ('  DB LUB: ' || Rpad(l_db_who.last_updated_by ||
                                  '/' || l_db_owner, 15) ||
             '  LUD: ' || To_char(l_db_who.last_update_date, g_date_mask)));

   END IF;

   --
   -- If upload is allowed then there will be changes.
   --
   IF (l_return) THEN
      g_numof_changes := g_numof_changes + 1;
   END IF;
   RETURN(l_return);
EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RETURN(FALSE);
END is_upload_allowed;

-- --------------------------------------------------
PROCEDURE create_lock(p_lock_name   IN VARCHAR2,
                      x_lock_handle OUT nocopy VARCHAR2)
  IS
     PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   dbms_lock.allocate_unique(lockname        => p_lock_name,
                             lockhandle      => x_lock_handle,
                             expiration_secs => 1*24*60*60); -- 1 day.

   COMMIT;
END create_lock;

-- --------------------------------------------------
PROCEDURE lock_entity(p_entity_name IN VARCHAR2,
                      p_key1        IN VARCHAR2,
                      p_key2        IN VARCHAR2 DEFAULT NULL)
  IS
     l_func_name   VARCHAR2(80);
     l_lock_name   VARCHAR2(128);
     l_lock_handle VARCHAR2(128);
     l_lock_status INTEGER;
BEGIN
   l_func_name := g_api_name || 'lock_entity()';
   l_lock_name := p_entity_name || '.' || p_key1 || '.' || p_key2;

   create_lock(l_lock_name, l_lock_handle);

   IF (g_debug_on) THEN
      debug(l_func_name,
            'Lock Name : ' || l_lock_name,
            'Lock Handle : ' || l_lock_handle,
            'Requesting the lock. Sysdate: ' || To_char(Sysdate, g_date_mask));
   END IF;

   l_lock_status := dbms_lock.request(lockhandle        => l_lock_handle,
                                      lockmode          => dbms_lock.x_mode,
                                      timeout           => dbms_lock.maxwait,
                                      release_on_commit => TRUE);

   IF (l_lock_status <> 0) THEN
      raise_error(l_func_name, ERROR_UNABLE_TO_LOCK,
                  'Unable to lock entity : ' || l_lock_name ||
                  '. dbms_lock.request() returned : ' ||
                  l_lock_status);
   END IF;

   g_lock_handle := l_lock_handle;

   IF (g_debug_on) THEN
      debug(l_func_name, 'Got the lock. Sysdate: ' ||
                         To_char(Sysdate, g_date_mask));
   END IF;
END lock_entity;

-- --------------------------------------------------
PROCEDURE release_entity
  IS
     l_func_name   VARCHAR2(80);
     l_lock_status INTEGER;
BEGIN
   l_func_name := g_api_name || 'release_entity()';

   IF (g_lock_handle is not null) THEN
      IF (g_debug_on) THEN
         debug(l_func_name,
               'Lock Handle : ' || g_lock_handle,
               'Releasing the lock. Sysdate: ' || To_char(Sysdate, g_date_mask));
      END IF;

      l_lock_status := dbms_lock.release(lockhandle => g_lock_handle);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Released the lock. Release Status: ' || l_lock_status || ', Sysdate: ' || To_char(Sysdate, g_date_mask));
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
END release_entity;

-- --------------------------------------------------
FUNCTION get_sample_template(p_key     IN VARCHAR2,
                             x_value   OUT nocopy VARCHAR2)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_sample_template(F)';
   SELECT 'Sample Template'
     INTO x_value
     FROM dual
     WHERE 'KEY_COLUMN' = p_key;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_key);
END get_sample_template;
--
PROCEDURE get_sample_template(p_key     IN VARCHAR2,
                              x_value   OUT nocopy VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_sample_template(P)';
   IF (NOT get_sample_template(p_key, x_value)) THEN
      raise_not_exist(l_func_name,
                      'Please define KEY',
                      'KEY', p_key);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_key);
END get_sample_template;

-- --------------------------------------------------
FUNCTION get_app(p_application_short_name IN VARCHAR2,
                 x_app                    OUT nocopy app_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_app(short_name, F)';
   SELECT *
     INTO x_app
     FROM fnd_application
     WHERE application_short_name = p_application_short_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name);
END get_app;
--
PROCEDURE get_app(p_application_short_name IN VARCHAR2,
                  x_app                    OUT nocopy app_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_app(short_name, P)';
   IF (NOT get_app(p_application_short_name, x_app)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Register form and ' ||
                      'register the application.',
                      'APP Short Name', p_application_short_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name);
END get_app;
--
FUNCTION get_app(p_application_id IN NUMBER,
                 x_app            OUT nocopy app_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_app(id, F)';
   SELECT *
     INTO x_app
     FROM fnd_application
     WHERE application_id = p_application_id;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_id);
END get_app;
--
PROCEDURE get_app(p_application_id IN NUMBER,
                  x_app            OUT nocopy app_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_app(id, P)';
   IF (NOT get_app(p_application_id, x_app)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Register form and ' ||
                      'register the application.',
                      'APP ID', To_char(p_application_id));
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_id);
END get_app;

-- --------------------------------------------------
FUNCTION get_tbl(p_application_short_name IN VARCHAR2,
                 p_table_name             IN VARCHAR2,
                 x_tbl                    OUT nocopy tbl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
     l_app       app_type;
BEGIN
   l_func_name := g_api_name || 'get_tbl(F)';
   --
   -- Make sure Application exists.
   --
   get_app(p_application_short_name, l_app);

   SELECT *
     INTO x_tbl
     FROM fnd_tables
     WHERE application_id = l_app.application_id
     AND table_name = p_table_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_table_name);
END get_tbl;
--
PROCEDURE get_tbl(p_application_short_name IN VARCHAR2,
                  p_table_name             IN VARCHAR2,
                  x_tbl                    OUT nocopy tbl_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_tbl(P)';
   IF (NOT get_tbl(p_application_short_name, p_table_name, x_tbl)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Database->Table form and ' ||
                      'register the table, or use AD_DD PL/SQL package, ' ||
                      'or use FNDLOAD (afdict.lct).',
                      'APP Short Name', p_application_short_name,
                      'Table Name', p_table_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_table_name);
END get_tbl;

-- --------------------------------------------------
FUNCTION get_col(p_application_id IN NUMBER,
                 p_table_name     IN VARCHAR2,
                 p_column_name    IN VARCHAR2,
                 x_col            OUT nocopy col_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
     l_app       app_type;
     l_tbl       tbl_type;
BEGIN
   l_func_name := g_api_name || 'get_col(F)';
   --
   -- Make sure Application exists.
   --
   get_app(p_application_id, l_app);

   --
   -- Make sure Table exists.
   --
   get_tbl(l_app.application_short_name, p_table_name, l_tbl);

   SELECT *
     INTO x_col
     FROM fnd_columns
     WHERE application_id = l_tbl.application_id
     AND table_id = l_tbl.table_id
     AND column_name = p_column_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_id,
                        p_table_name,
                        p_column_name);
END get_col;
--
PROCEDURE get_col(p_application_id IN NUMBER,
                  p_table_name     IN VARCHAR2,
                  p_column_name    IN VARCHAR2,
                  x_col            OUT nocopy col_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_col(P)';
   IF (NOT get_col(p_application_id, p_table_name, p_column_name, x_col)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Database->Table form and '||
                      'register the column, or use AD_DD PL/SQL package, ' ||
                      'or use FNDLOAD (afdict.lct).',
                      'APP Id', To_char(p_application_id),
                      'Table Name', p_table_name,
                      'Column Name', p_column_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_id,
                        p_table_name,
                        p_column_name);
END get_col;

-- --------------------------------------------------
FUNCTION get_resp(p_application_short_name IN VARCHAR2,
                  p_responsibility_key     IN VARCHAR2,
                  x_resp                   OUT nocopy resp_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
     l_app       app_type;
BEGIN
   l_func_name := g_api_name || 'get_resp(F)';
   --
   -- Make sure Application exists.
   --
   get_app(p_application_short_name, l_app);

   SELECT *
     INTO x_resp
     FROM fnd_responsibility
     WHERE application_id = l_app.application_id
     AND responsibility_key = p_responsibility_key;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_responsibility_key);
END get_resp;
--
PROCEDURE get_resp(p_application_short_name IN VARCHAR2,
                   p_responsibility_key     IN VARCHAR2,
                   x_resp                   OUT nocopy resp_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_resp(P)';
   IF (NOT get_resp(p_application_short_name, p_responsibility_key,
                    x_resp)) THEN
      raise_not_exist(l_func_name,
                      'Please use System Administrator:' ||
                      'Security->Responsibility->Define form and ' ||
                      'create the responsibility, ' ||
                      'or use FNDLOAD (afscursp.lct).',
                      'APP Short Name', p_application_short_name,
                      'RESP Key', p_responsibility_key);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_responsibility_key);
END get_resp;

-- --------------------------------------------------
FUNCTION get_vst_set(p_flex_value_set_name IN VARCHAR2,
                     x_vst_set             OUT nocopy vst_set_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_set(F)';
   SELECT *
     INTO x_vst_set
     FROM fnd_flex_value_sets
     WHERE flex_value_set_name = p_flex_value_set_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_flex_value_set_name);
END get_vst_set;
--
PROCEDURE get_vst_set(p_flex_value_set_name IN VARCHAR2,
                      x_vst_set             OUT nocopy vst_set_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_set(P)';
   IF (NOT get_vst_set(p_flex_value_set_name, x_vst_set)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Validation->Set form and ' ||
                      'create the value set, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_flex_value_set_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_flex_value_set_name);
END get_vst_set;

-- --------------------------------------------------
FUNCTION get_vst_tbl(p_vst_set IN vst_set_type,
                     x_vst_tbl OUT nocopy vst_tbl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_tbl(F)';
   SELECT *
     INTO x_vst_tbl
     FROM fnd_flex_validation_tables
     WHERE flex_value_set_id = p_vst_set.flex_value_set_id;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id);
END get_vst_tbl;
--
PROCEDURE get_vst_tbl(p_vst_set IN vst_set_type,
                      x_vst_tbl OUT nocopy vst_tbl_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_tbl(P)';
   IF (NOT get_vst_tbl(p_vst_set, x_vst_tbl)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Validation->Set form and ' ||
                      'create the table validated value set, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id);
END get_vst_tbl;

-- --------------------------------------------------
FUNCTION get_vst_evt(p_vst_set    IN vst_set_type,
                     p_event_code IN VARCHAR2,
                     x_vst_evt    OUT nocopy vst_evt_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_evt(F)';
   SELECT *
     INTO x_vst_evt
     FROM fnd_flex_validation_events
     WHERE flex_value_set_id = p_vst_set.flex_value_set_id
     AND event_code = p_event_code;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_event_code);
END get_vst_evt;
--
PROCEDURE get_vst_evt(p_vst_set    IN vst_set_type,
                      p_event_code IN VARCHAR2,
                      x_vst_evt    OUT nocopy vst_evt_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_evt(P)';
   IF (NOT get_vst_evt(p_vst_set, p_event_code, x_vst_evt)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Validation->Set form and ' ||
                      'create the user exit validated value set, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Event Code', p_event_code);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_event_code);
END get_vst_evt;

-- --------------------------------------------------
FUNCTION get_vst_scr(p_vst_set               IN vst_set_type,
                     p_flex_value_rule_name  IN VARCHAR2,
                     p_parent_flex_value_low IN VARCHAR2,
                     x_vst_scr               OUT nocopy vst_scr_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scr(F)';
   IF (p_vst_set.validation_type = 'D') THEN
      SELECT *
        INTO x_vst_scr
        FROM fnd_flex_value_rules
        WHERE flex_value_set_id = p_vst_set.flex_value_set_id
        AND parent_flex_value_low = p_parent_flex_value_low
        AND flex_value_rule_name = p_flex_value_rule_name;
    ELSE
      SELECT *
        INTO x_vst_scr
        FROM fnd_flex_value_rules
        WHERE flex_value_set_id = p_vst_set.flex_value_set_id
        AND flex_value_rule_name = p_flex_value_rule_name;
   END IF;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_flex_value_rule_name,
                        p_parent_flex_value_low);
END get_vst_scr;
--
PROCEDURE get_vst_scr(p_vst_set               IN vst_set_type,
                      p_flex_value_rule_name  IN VARCHAR2,
                      p_parent_flex_value_low IN VARCHAR2,
                      x_vst_scr               OUT nocopy vst_scr_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scr(P)';
   IF (NOT get_vst_scr(p_vst_set, p_flex_value_rule_name,
                       p_parent_flex_value_low,
                       x_vst_scr)) THEN
      raise_not_exist(l_func_name,
                      'Please use System Administrator:' ||
                      'Security->Responsibility->ValueSet->Define form and ' ||
                      'create the security rule, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Security Rule', p_flex_value_rule_name,
                      'Parent Value', p_parent_flex_value_low);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_flex_value_rule_name,
                        p_parent_flex_value_low);
END get_vst_scr;
--
FUNCTION get_vst_scr_tl(p_vst_scr    IN vst_scr_type,
                        p_language   IN VARCHAR2,
                        x_vst_scr_tl OUT nocopy vst_scr_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scr_tl(F)';
   SELECT *
     INTO x_vst_scr_tl
     FROM fnd_flex_value_rules_tl
     WHERE flex_value_rule_id = p_vst_scr.flex_value_rule_id
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_scr.flex_value_set_id,
                        p_vst_scr.flex_value_rule_name,
                        p_vst_scr.flex_value_rule_id,
                        p_language);
END get_vst_scr_tl;

-- --------------------------------------------------
FUNCTION get_vst_scl(p_vst_set                   IN vst_set_type,
                     p_vst_scr                   IN vst_scr_type,
                     p_include_exclude_indicator IN VARCHAR2,
                     p_flex_value_low            IN VARCHAR2,
                     p_flex_value_high           IN VARCHAR2,
                     x_vst_scl                   OUT nocopy vst_scl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scl(F)';
   IF (p_vst_set.validation_type = 'D') THEN
      SELECT *
        INTO x_vst_scl
        FROM fnd_flex_value_rule_lines
        WHERE flex_value_set_id = p_vst_scr.flex_value_set_id
        AND flex_value_rule_id = p_vst_scr.flex_value_rule_id
        AND parent_flex_value_low = p_vst_scr.parent_flex_value_low
        AND include_exclude_indicator = p_include_exclude_indicator
        AND flex_value_low = p_flex_value_low
        AND flex_value_high = p_flex_value_high;
    ELSE
      SELECT *
        INTO x_vst_scl
        FROM fnd_flex_value_rule_lines
        WHERE flex_value_set_id = p_vst_scr.flex_value_set_id
        AND flex_value_rule_id = p_vst_scr.flex_value_rule_id
        AND include_exclude_indicator = p_include_exclude_indicator
        AND flex_value_low = p_flex_value_low
        AND flex_value_high = p_flex_value_high;
   END IF;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_vst_scr.flex_value_rule_name,
                        p_vst_scr.flex_value_rule_id,
                        p_vst_scr.parent_flex_value_low,
                        p_include_exclude_indicator,
                        p_flex_value_low,
                        p_flex_value_high);
END get_vst_scl;
--
PROCEDURE get_vst_scl(p_vst_set                   IN vst_set_type,
                      p_vst_scr                   IN vst_scr_type,
                      p_include_exclude_indicator IN VARCHAR2,
                      p_flex_value_low            IN VARCHAR2,
                      p_flex_value_high           IN VARCHAR2,
                      x_vst_scl                   OUT nocopy vst_scl_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scl(P)';
   IF (NOT get_vst_scl(p_vst_set, p_vst_scr, p_include_exclude_indicator,
                       p_flex_value_low, p_flex_value_high,
                       x_vst_scl)) THEN
      raise_not_exist(l_func_name,
                      'Please use System Administrator:' ||
                      'Security->Responsibility->ValueSet->Define form and ' ||
                      'create the security rule line, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Security Rule', p_vst_scr.flex_value_rule_name,
                      'Parent Value', p_vst_scr.parent_flex_value_low,
                      'I/E Indicator', p_include_exclude_indicator,
                      'Value Low', p_flex_value_low,
                      'Value High', p_flex_value_high);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_vst_scr.flex_value_rule_name,
                        p_vst_scr.flex_value_rule_id,
                        p_vst_scr.parent_flex_value_low,
                        p_include_exclude_indicator,
                        p_flex_value_low,
                        p_flex_value_high);
END get_vst_scl;

-- --------------------------------------------------
FUNCTION get_vst_scu(p_vst_set IN vst_set_type,
                     p_vst_scr IN vst_scr_type,
                     p_resp    IN resp_type,
                     x_vst_scu OUT nocopy vst_scu_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scu(F)';
   IF (p_vst_set.validation_type = 'D') THEN
      SELECT *
        INTO x_vst_scu
        FROM fnd_flex_value_rule_usages
        WHERE application_id = p_resp.application_id
        AND responsibility_id = p_resp.responsibility_id
        AND flex_value_set_id = p_vst_scr.flex_value_set_id
        AND flex_value_rule_id = p_vst_scr.flex_value_rule_id
        AND parent_flex_value_low = p_vst_scr.parent_flex_value_low;
    ELSE
      SELECT *
        INTO x_vst_scu
        FROM fnd_flex_value_rule_usages
        WHERE application_id = p_resp.application_id
        AND responsibility_id = p_resp.responsibility_id
        AND flex_value_set_id = p_vst_scr.flex_value_set_id
        AND flex_value_rule_id = p_vst_scr.flex_value_rule_id;
   END IF;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_vst_scr.flex_value_rule_name,
                        p_vst_scr.flex_value_rule_id,
                        p_vst_scr.parent_flex_value_low,
                        p_resp.application_id,
                        p_resp.responsibility_key,
                        p_resp.responsibility_id);
END get_vst_scu;
--
PROCEDURE get_vst_scu(p_vst_set IN vst_set_type,
                      p_vst_scr IN vst_scr_type,
                      p_resp    IN resp_type,
                      x_vst_scu OUT nocopy vst_scu_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_scu(P)';
   IF (NOT get_vst_scu(p_vst_set, p_vst_scr, p_resp,
                       x_vst_scu)) THEN
      raise_not_exist(l_func_name,
                      'Please use System Administrator:' ||
                      'Security->Responsibility->ValueSet->Assign form and ' ||
                      'create the security rule usage, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Security Rule', p_vst_scr.flex_value_rule_name,
                      'Parent Value', p_vst_scr.parent_flex_value_low,
                      'App ID', p_resp.application_id,
                      'Resp Key', p_resp.responsibility_key);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_vst_scr.flex_value_rule_name,
                        p_vst_scr.flex_value_rule_id,
                        p_vst_scr.parent_flex_value_low,
                        p_resp.application_id,
                        p_resp.responsibility_key,
                        p_resp.responsibility_id);
END get_vst_scu;

-- --------------------------------------------------
FUNCTION get_vst_rgr(p_vst_set        IN vst_set_type,
                     p_hierarchy_code IN VARCHAR2,
                     x_vst_rgr        OUT nocopy vst_rgr_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_rgr(F)';
   SELECT *
     INTO x_vst_rgr
     FROM fnd_flex_hierarchies
     WHERE flex_value_set_id = p_vst_set.flex_value_set_id
     AND hierarchy_code = p_hierarchy_code;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_hierarchy_code);
END get_vst_rgr;
--
PROCEDURE get_vst_rgr(p_vst_set        IN vst_set_type,
                      p_hierarchy_code IN VARCHAR2,
                      x_vst_rgr        OUT nocopy vst_rgr_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_rgr(P)';
   IF (NOT get_vst_rgr(p_vst_set, p_hierarchy_code, x_vst_rgr)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Groups form and ' ||
                      'create the hierarchy, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Hierarchy Code', p_hierarchy_code);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_hierarchy_code);
END get_vst_rgr;
--
FUNCTION get_vst_rgr_tl(p_vst_rgr    IN vst_rgr_type,
                        p_language   IN VARCHAR2,
                        x_vst_rgr_tl OUT nocopy vst_rgr_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_rgr_tl(F)';
   SELECT *
     INTO x_vst_rgr_tl
     FROM fnd_flex_hierarchies_tl
     WHERE flex_value_set_id = p_vst_rgr.flex_value_set_id
     AND hierarchy_id = p_vst_rgr.hierarchy_id
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_rgr.flex_value_set_id,
                        p_vst_rgr.hierarchy_code,
                        p_vst_rgr.hierarchy_id,
                        p_language);
END get_vst_rgr_tl;

-- --------------------------------------------------
FUNCTION get_vst_val(p_vst_set               IN vst_set_type,
                     p_parent_flex_value_low IN VARCHAR2,
                     p_flex_value            IN VARCHAR2,
                     x_vst_val               OUT nocopy vst_val_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_val(F)';
   IF (p_vst_set.validation_type IN ('D', 'Y')) THEN
      SELECT *
        INTO x_vst_val
        FROM fnd_flex_values
        WHERE flex_value_set_id = p_vst_set.flex_value_set_id
        AND (parent_flex_value_low = p_parent_flex_value_low OR
             (parent_flex_value_low IS NULL AND
              p_parent_flex_value_low IS NULL))
        AND flex_value = p_flex_value;
    ELSE
      SELECT *
        INTO x_vst_val
        FROM fnd_flex_values
        WHERE flex_value_set_id = p_vst_set.flex_value_set_id
        AND flex_value = p_flex_value;
   END IF;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_parent_flex_value_low,
                        p_flex_value);
END get_vst_val;
--
PROCEDURE get_vst_val(p_vst_set               IN vst_set_type,
                      p_parent_flex_value_low IN VARCHAR2,
                      p_flex_value            IN VARCHAR2,
                      x_vst_val               OUT nocopy vst_val_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_val(P)';
   IF (NOT get_vst_val(p_vst_set, p_parent_flex_value_low,
                       p_flex_value, x_vst_val)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Validation->Value form and ' ||
                      'create the value, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set', p_vst_set.flex_value_set_name,
                      'Parent Value', p_parent_flex_value_low,
                      'Flex Value', p_flex_value);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id,
                        p_parent_flex_value_low,
                        p_flex_value);
END get_vst_val;
--
FUNCTION get_vst_val_tl(p_vst_val    IN vst_val_type,
                        p_language   IN VARCHAR2,
                        x_vst_val_tl OUT nocopy vst_val_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_val_tl(F)';
   SELECT *
     INTO x_vst_val_tl
     FROM fnd_flex_values_tl
     WHERE flex_value_id = p_vst_val.flex_value_id
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_val.flex_value_set_id,
                        p_vst_val.parent_flex_value_low,
                        p_vst_val.flex_value,
                        p_vst_val.flex_value_id,
                        p_language);
END get_vst_val_tl;

-- --------------------------------------------------
FUNCTION get_vst_vlh(p_vst_val               IN vst_val_type,
                     p_range_attribute       IN VARCHAR2,
                     p_child_flex_value_low  IN VARCHAR2,
                     p_child_flex_value_high IN VARCHAR2,
                     x_vst_vlh               OUT nocopy vst_vlh_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_vlh(F)';
   SELECT *
     INTO x_vst_vlh
     FROM fnd_flex_value_norm_hierarchy
     WHERE flex_value_set_id = p_vst_val.flex_value_set_id
     AND parent_flex_value = p_vst_val.flex_value
     AND range_attribute = p_range_attribute
     AND child_flex_value_low = p_child_flex_value_low
     AND child_flex_value_high = p_child_flex_value_high;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_val.flex_value_set_id,
                        p_vst_val.parent_flex_value_low,
                        p_vst_val.flex_value,
                        p_vst_val.flex_value_id,
                        p_range_attribute,
                        p_child_flex_value_low,
                        p_child_flex_value_high);
END get_vst_vlh;
--
PROCEDURE get_vst_vlh(p_vst_val               IN vst_val_type,
                      p_range_attribute       IN VARCHAR2,
                      p_child_flex_value_low  IN VARCHAR2,
                      p_child_flex_value_high IN VARCHAR2,
                      x_vst_vlh               OUT nocopy vst_vlh_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_vst_vlh(P)';
   IF (NOT get_vst_vlh(p_vst_val, p_range_attribute,
                        p_child_flex_value_low, p_child_flex_value_high,
                        x_vst_vlh)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Application->Validation->Value form and ' ||
                      'create the value hierarchy, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'Value Set Id', p_vst_val.flex_value_set_id,
                      'Parent Value', p_vst_val.flex_value,
                      'Range Attribute', p_range_attribute,
                      'Child Value Low', p_child_flex_value_low,
                      'Child Value High', p_child_flex_value_high);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_val.flex_value_set_id,
                        p_vst_val.parent_flex_value_low,
                        p_vst_val.flex_value,
                        p_vst_val.flex_value_id,
                        p_range_attribute,
                        p_child_flex_value_low,
                        p_child_flex_value_high);
END get_vst_vlh;

-- --------------------------------------------------
PROCEDURE get_vtv_arr(p_vst_set      IN vst_set_type,
                      x_vtv_arr_size OUT nocopy NUMBER,
                      x_vtv_arr      OUT nocopy vtv_arr_type)
  IS
     l_func_name VARCHAR2(80);

     CURSOR vtv_cur(p_flex_value_set_id IN NUMBER) IS
        SELECT
          fvq.id_flex_application_id,
          fvq.id_flex_code,
          fvq.segment_attribute_type,
          fvq.value_attribute_type,
          fvq.assignment_date,
          vat.lookup_type,
          vat.default_value,
          NULL
          FROM fnd_flex_validation_qualifiers fvq,
          fnd_value_attribute_types vat
          WHERE fvq.flex_value_set_id    = p_flex_value_set_id
          AND fvq.id_flex_application_id = vat.application_id(+)
          AND fvq.id_flex_code           = vat.id_flex_code(+)
          AND fvq.segment_attribute_type = vat.segment_attribute_type(+)
          AND fvq.value_attribute_type   = vat.value_attribute_type(+)
          ORDER BY fvq.assignment_date, fvq.value_attribute_type;
     i NUMBER;
BEGIN
   l_func_name := g_api_name || 'get_vtv_arr()';
   i := 0;
   FOR vtv_rec IN vtv_cur(p_vst_set.flex_value_set_id) LOOP
      i := i + 1;
      x_vtv_arr(i).id_flex_application_id := vtv_rec.id_flex_application_id;
      x_vtv_arr(i).id_flex_code           := vtv_rec.id_flex_code;
      x_vtv_arr(i).segment_attribute_type := vtv_rec.segment_attribute_type;
      x_vtv_arr(i).value_attribute_type   := vtv_rec.value_attribute_type;
      x_vtv_arr(i).assignment_date        := vtv_rec.assignment_date;
      x_vtv_arr(i).lookup_type            := vtv_rec.lookup_type;
      x_vtv_arr(i).default_value          := vtv_rec.default_value;
      x_vtv_arr(i).qualifier_value        := NULL;
   END LOOP;
   x_vtv_arr_size := i;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_vst_set.flex_value_set_name,
                        p_vst_set.flex_value_set_id);
END get_vtv_arr;

-- --------------------------------------------------
FUNCTION get_dff_flx(p_application_short_name     IN VARCHAR2,
                     p_descriptive_flexfield_name IN VARCHAR2,
                     x_dff_flx                    OUT nocopy dff_flx_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
     l_app       app_type;
BEGIN
   l_func_name := g_api_name || 'get_dff_flx(F)';
   --
   -- Make sure Application exists.
   --
   get_app(p_application_short_name, l_app);

   SELECT *
     INTO x_dff_flx
     FROM fnd_descriptive_flexs
     WHERE application_id =  l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_descriptive_flexfield_name);
END get_dff_flx;
--
PROCEDURE get_dff_flx(p_application_short_name     IN VARCHAR2,
                      p_descriptive_flexfield_name IN VARCHAR2,
                      x_dff_flx                    OUT nocopy dff_flx_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_flx(P)';
   IF (NOT get_dff_flx(p_application_short_name, p_descriptive_flexfield_name,
                       x_dff_flx)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Descriptive->Register form and ' ||
                      'register the descriptive flexfield, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Short Name', p_application_short_name,
                      'DFF Name', p_descriptive_flexfield_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_descriptive_flexfield_name);
END get_dff_flx;
--
FUNCTION get_dff_flx_tl(p_dff_flx    IN dff_flx_type,
                        p_language   IN VARCHAR2,
                        x_dff_flx_tl OUT nocopy dff_flx_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_flx_tl(F)';
   SELECT *
     INTO x_dff_flx_tl
     FROM fnd_descriptive_flexs_tl
     WHERE application_id = p_dff_flx.application_id
     AND descriptive_flexfield_name = p_dff_flx.descriptive_flexfield_name
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_flx.application_id,
                        p_dff_flx.descriptive_flexfield_name,
                        p_language);
END get_dff_flx_tl;

-- --------------------------------------------------
FUNCTION get_dff_ref(p_dff_flx                    IN dff_flx_type,
                     p_default_context_field_name IN VARCHAR2,
                     x_dff_ref                    OUT nocopy dff_ref_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_ref(F)';
   SELECT *
     INTO x_dff_ref
     FROM fnd_default_context_fields
     WHERE application_id = p_dff_flx.application_id
     AND descriptive_flexfield_name = p_dff_flx.descriptive_flexfield_name
     AND default_context_field_name = p_default_context_field_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_flx.application_id,
                        p_dff_flx.descriptive_flexfield_name,
                        p_default_context_field_name);
END get_dff_ref;
--
PROCEDURE get_dff_ref(p_dff_flx                    IN dff_flx_type,
                      p_default_context_field_name IN VARCHAR2,
                      x_dff_ref                    OUT nocopy dff_ref_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_ref(P)';
   IF (NOT get_dff_ref(p_dff_flx, p_default_context_field_name,
                       x_dff_ref)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Descriptive->Register form and ' ||
                      'create the reference field, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_dff_flx.application_id),
                      'DFF Name', p_dff_flx.descriptive_flexfield_name,
                      'Reference Field', p_default_context_field_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_flx.application_id,
                        p_dff_flx.descriptive_flexfield_name,
                        p_default_context_field_name);
END get_dff_ref;

-- --------------------------------------------------
FUNCTION get_dff_ctx(p_dff_flx                      IN dff_flx_type,
                     p_descriptive_flex_context_cod IN VARCHAR2,
                     x_dff_ctx                      OUT nocopy dff_ctx_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_ctx(F)';
   SELECT *
     INTO x_dff_ctx
     FROM fnd_descr_flex_contexts
     WHERE application_id = p_dff_flx.application_id
     AND descriptive_flexfield_name = p_dff_flx.descriptive_flexfield_name
     AND descriptive_flex_context_code = p_descriptive_flex_context_cod;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_flx.application_id,
                        p_dff_flx.descriptive_flexfield_name,
                        p_descriptive_flex_context_cod);
END get_dff_ctx;
--
PROCEDURE get_dff_ctx(p_dff_flx                      IN dff_flx_type,
                      p_descriptive_flex_context_cod IN VARCHAR2,
                      x_dff_ctx                      OUT nocopy dff_ctx_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_ctx(P)';
   IF (NOT get_dff_ctx(p_dff_flx, p_descriptive_flex_context_cod,
                       x_dff_ctx)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Descriptive->Segments form and ' ||
                      'create the context, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_dff_flx.application_id),
                      'DFF Name', p_dff_flx.descriptive_flexfield_name,
                      'Context Code', p_descriptive_flex_context_cod);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_flx.application_id,
                        p_dff_flx.descriptive_flexfield_name,
                        p_descriptive_flex_context_cod);
END get_dff_ctx;
--
FUNCTION get_dff_ctx_tl(p_dff_ctx    IN dff_ctx_type,
                        p_language   IN VARCHAR2,
                        x_dff_ctx_tl OUT nocopy dff_ctx_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_ctx_tl(F)';
   SELECT *
     INTO x_dff_ctx_tl
     FROM fnd_descr_flex_contexts_tl
     WHERE application_id = p_dff_ctx.application_id
     AND descriptive_flexfield_name = p_dff_ctx.descriptive_flexfield_name
     AND descriptive_flex_context_code = p_dff_ctx.descriptive_flex_context_code
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_ctx.application_id,
                        p_dff_ctx.descriptive_flexfield_name,
                        p_dff_ctx.descriptive_flex_context_code,
                        p_language);
END get_dff_ctx_tl;

-- --------------------------------------------------
FUNCTION get_dff_seg(p_dff_ctx                 IN dff_ctx_type,
                     p_application_column_name IN VARCHAR2,
                     x_dff_seg                 OUT nocopy dff_seg_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_seg(F)';
   SELECT *
     INTO x_dff_seg
     FROM fnd_descr_flex_column_usages
     WHERE application_id = p_dff_ctx.application_id
     AND descriptive_flexfield_name = p_dff_ctx.descriptive_flexfield_name
     AND descriptive_flex_context_code = p_dff_ctx.descriptive_flex_context_code
     AND application_column_name = p_application_column_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_ctx.application_id,
                        p_dff_ctx.descriptive_flexfield_name,
                        p_dff_ctx.descriptive_flex_context_code,
                        p_application_column_name);
END get_dff_seg;
--
PROCEDURE get_dff_seg(p_dff_ctx                 IN dff_ctx_type,
                      p_application_column_name IN VARCHAR2,
                      x_dff_seg                 OUT nocopy dff_seg_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_seg(P)';
   IF (NOT get_dff_seg(p_dff_ctx, p_application_column_name,
                       x_dff_seg)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Descriptive->Segments form and ' ||
                      'create the segment, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_dff_ctx.application_id),
                      'DFF Name', p_dff_ctx.descriptive_flexfield_name,
                      'Context Code', p_dff_ctx.descriptive_flex_context_code,
                      'Segment Col Name', p_application_column_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_ctx.application_id,
                        p_dff_ctx.descriptive_flexfield_name,
                        p_dff_ctx.descriptive_flex_context_code,
                        p_application_column_name);
END get_dff_seg;
--
FUNCTION get_dff_seg_tl(p_dff_seg    IN dff_seg_type,
                        p_language   IN VARCHAR2,
                        x_dff_seg_tl OUT nocopy dff_seg_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_dff_seg_tl(F)';
   SELECT *
     INTO x_dff_seg_tl
     FROM fnd_descr_flex_col_usage_tl
     WHERE application_id = p_dff_seg.application_id
     AND descriptive_flexfield_name = p_dff_seg.descriptive_flexfield_name
     AND descriptive_flex_context_code = p_dff_seg.descriptive_flex_context_code
     AND application_column_name = p_dff_seg.application_column_name
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_dff_seg.application_id,
                        p_dff_seg.descriptive_flexfield_name,
                        p_dff_seg.descriptive_flex_context_code,
                        p_dff_seg.application_column_name,
                        p_dff_seg.end_user_column_name,
                        p_language);
END get_dff_seg_tl;

-- --------------------------------------------------
FUNCTION get_kff_flx(p_application_short_name IN VARCHAR2,
                     p_id_flex_code           IN VARCHAR2,
                     x_kff_flx                OUT nocopy kff_flx_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
     l_app       app_type;
BEGIN
   l_func_name := g_api_name || 'get_kff_flx(F)';
   --
   -- Make sure Application exists.
   --
   get_app(p_application_short_name, l_app);

   SELECT *
     INTO x_kff_flx
     FROM fnd_id_flexs
     WHERE application_id = l_app.application_id
     AND id_flex_code = p_id_flex_code;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_id_flex_code);
END get_kff_flx;
--
PROCEDURE get_kff_flx(p_application_short_name IN VARCHAR2,
                      p_id_flex_code           IN VARCHAR2,
                      x_kff_flx                OUT nocopy kff_flx_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_flx(P)';
   IF (NOT get_kff_flx(p_application_short_name, p_id_flex_code,
                       x_kff_flx)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Register form and ' ||
                      'register the key flexfield, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Short Name', p_application_short_name,
                      'KFF Code', p_id_flex_code);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_id_flex_code);
END get_kff_flx;

-- --------------------------------------------------
FUNCTION get_kff_flq(p_kff_flx                IN kff_flx_type,
                     p_segment_attribute_type IN VARCHAR2,
                     x_kff_flq                OUT nocopy kff_flq_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_flq(F)';
   SELECT *
     INTO x_kff_flq
     FROM fnd_segment_attribute_types
     WHERE application_id = p_kff_flx.application_id
     AND id_flex_code = p_kff_flx.id_flex_code
     AND segment_attribute_type = p_segment_attribute_type;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_segment_attribute_type);
END get_kff_flq;
--
PROCEDURE get_kff_flq(p_kff_flx                IN kff_flx_type,
                      p_segment_attribute_type IN VARCHAR2,
                      x_kff_flq                OUT nocopy kff_flq_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_flq(P)';
   IF (NOT get_kff_flq(p_kff_flx, p_segment_attribute_type,
                       x_kff_flq)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Register form and ' ||
                      'create the flexfield qualifier, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_flx.application_id),
                      'KFF Code', p_kff_flx.id_flex_code,
                      'Flex Qual', p_segment_attribute_type);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_segment_attribute_type);
END get_kff_flq;

-- --------------------------------------------------
FUNCTION get_kff_sgq(p_kff_flq              IN kff_flq_type,
                     p_value_attribute_type IN VARCHAR2,
                     x_kff_sgq              OUT nocopy kff_sgq_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_sgq(F)';
   SELECT *
     INTO x_kff_sgq
     FROM fnd_value_attribute_types
     WHERE application_id = p_kff_flq.application_id
     AND id_flex_code = p_kff_flq.id_flex_code
     AND segment_attribute_type = p_kff_flq.segment_attribute_type
     AND value_attribute_type = p_value_attribute_type;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flq.application_id,
                        p_kff_flq.id_flex_code,
                        p_kff_flq.segment_attribute_type,
                        p_value_attribute_type);
END get_kff_sgq;
--
PROCEDURE get_kff_sgq(p_kff_flq              IN kff_flq_type,
                      p_value_attribute_type IN VARCHAR2,
                      x_kff_sgq              OUT nocopy kff_sgq_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_sgq(P)';
   IF (NOT get_kff_sgq(p_kff_flq, p_value_attribute_type,
                       x_kff_sgq)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Register form and ' ||
                      'create the segment qualifier, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_flq.application_id),
                      'KFF Code', p_kff_flq.id_flex_code,
                      'Flex Qual', p_kff_flq.segment_attribute_type,
                      'Segment Qual', p_value_attribute_type);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flq.application_id,
                        p_kff_flq.id_flex_code,
                        p_kff_flq.segment_attribute_type,
                        p_value_attribute_type);
END get_kff_sgq;
--
FUNCTION get_kff_sgq_tl(p_kff_sgq    IN kff_sgq_type,
                        p_language   IN VARCHAR2,
                        x_kff_sgq_tl OUT nocopy kff_sgq_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_sgq_tl(F)';
   SELECT *
     INTO x_kff_sgq_tl
     FROM fnd_val_attribute_types_tl
     WHERE application_id = p_kff_sgq.application_id
     AND id_flex_code = p_kff_sgq.id_flex_code
     AND segment_attribute_type = p_kff_sgq.segment_attribute_type
     AND value_attribute_type = p_kff_sgq.value_attribute_type
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_sgq.application_id,
                        p_kff_sgq.id_flex_code,
                        p_kff_sgq.segment_attribute_type,
                        p_kff_sgq.value_attribute_type,
                        p_language);
END get_kff_sgq_tl;

-- --------------------------------------------------
FUNCTION get_kff_str(p_kff_flx                IN kff_flx_type,
                     p_id_flex_structure_code IN VARCHAR2,
                     x_kff_str                OUT nocopy kff_str_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_str(code,F)';
   SELECT *
     INTO x_kff_str
     FROM fnd_id_flex_structures
     WHERE application_id =  p_kff_flx.application_id
     AND id_flex_code = p_kff_flx.id_flex_code
     AND id_flex_structure_code = p_id_flex_structure_code;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_id_flex_structure_code);
END get_kff_str;
--
PROCEDURE get_kff_str(p_kff_flx                IN kff_flx_type,
                      p_id_flex_structure_code IN VARCHAR2,
                      x_kff_str                OUT nocopy kff_str_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_str(code,P)';
   IF (NOT get_kff_str(p_kff_flx, p_id_flex_structure_code,
                       x_kff_str)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Segments form and ' ||
                      'create the structure, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_flx.application_id),
                      'KFF Code', p_kff_flx.id_flex_code,
                      'Structure Code', p_id_flex_structure_code);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_id_flex_structure_code);
END get_kff_str;
--
FUNCTION get_kff_str(p_kff_flx     IN kff_flx_type,
                     p_id_flex_num IN NUMBER,
                     x_kff_str     OUT nocopy kff_str_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_str(num,F)';
   SELECT *
     INTO x_kff_str
     FROM fnd_id_flex_structures
     WHERE application_id =  p_kff_flx.application_id
     AND id_flex_code = p_kff_flx.id_flex_code
     AND id_flex_num = p_id_flex_num;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_id_flex_num);
END get_kff_str;
--
PROCEDURE get_kff_str(p_kff_flx     IN kff_flx_type,
                      p_id_flex_num IN NUMBER,
                      x_kff_str     OUT nocopy kff_str_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_str(num,P)';
   IF (NOT get_kff_str(p_kff_flx, p_id_flex_num,
                       x_kff_str)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Segments form and ' ||
                      'create the structure, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_flx.application_id),
                      'KFF Code', p_kff_flx.id_flex_code,
                      'Structure Num', To_char(p_id_flex_num));
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flx.application_id,
                        p_kff_flx.id_flex_code,
                        p_id_flex_num);
END get_kff_str;
--
FUNCTION get_kff_str_tl(p_kff_str    IN kff_str_type,
                        p_language   IN VARCHAR2,
                        x_kff_str_tl OUT nocopy kff_str_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_str_tl(F)';
   SELECT *
     INTO x_kff_str_tl
     FROM fnd_id_flex_structures_tl
     WHERE application_id =  p_kff_str.application_id
     AND id_flex_code = p_kff_str.id_flex_code
     AND id_flex_num = p_kff_str.id_flex_num
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_language);
END get_kff_str_tl;

-- --------------------------------------------------
FUNCTION get_kff_wfp(p_kff_str      IN kff_str_type,
                     p_wf_item_type IN VARCHAR2,
                     x_kff_wfp      OUT nocopy kff_wfp_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_wfp(F)';
   SELECT *
     INTO x_kff_wfp
     FROM fnd_flex_workflow_processes
     WHERE application_id =  p_kff_str.application_id
     AND id_flex_code = p_kff_str.id_flex_code
     AND id_flex_num = p_kff_str.id_flex_num
     AND wf_item_type = p_wf_item_type;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_wf_item_type);
END get_kff_wfp;
--
PROCEDURE get_kff_wfp(p_kff_str      IN kff_str_type,
                      p_wf_item_type IN VARCHAR2,
                      x_kff_wfp      OUT nocopy kff_wfp_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_wfp(P)';
   IF (NOT get_kff_wfp(p_kff_str, p_wf_item_type,
                       x_kff_wfp)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Accounts form and ' ||
                      'create the WF Item Type, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_str.application_id),
                      'KFF Code', p_kff_str.id_flex_code,
                      'Structure Code', p_kff_str.id_flex_structure_code,
                      'WF Item Type', p_wf_item_type);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_wf_item_type);
END get_kff_wfp;

-- --------------------------------------------------
FUNCTION get_kff_sha(p_kff_str    IN kff_str_type,
                     p_alias_name IN VARCHAR2,
                     x_kff_sha    OUT nocopy kff_sha_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_sha(F)';
   SELECT *
     INTO x_kff_sha
     FROM fnd_shorthand_flex_aliases
     WHERE application_id =  p_kff_str.application_id
     AND id_flex_code = p_kff_str.id_flex_code
     AND id_flex_num = p_kff_str.id_flex_num
     AND alias_name = p_alias_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_alias_name);
END get_kff_sha;
--
PROCEDURE get_kff_sha(p_kff_str    IN kff_str_type,
                      p_alias_name IN VARCHAR2,
                      x_kff_sha    OUT nocopy kff_sha_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_sha(P)';
   IF (NOT get_kff_sha(p_kff_str, p_alias_name,
                       x_kff_sha)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Aliases form and ' ||
                      'create the alias, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_str.application_id),
                      'KFF Code', p_kff_str.id_flex_code,
                      'Structure Code', p_kff_str.id_flex_structure_code,
                      'Alias Name', p_alias_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_alias_name);
END get_kff_sha;

-- --------------------------------------------------
FUNCTION get_kff_cvr(p_kff_str                   IN kff_str_type,
                     p_flex_validation_rule_name IN VARCHAR2,
                     x_kff_cvr                   OUT nocopy kff_cvr_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_cvr(F)';
   SELECT *
     INTO x_kff_cvr
     FROM fnd_flex_validation_rules
     WHERE application_id =  p_kff_str.application_id
     AND id_flex_code = p_kff_str.id_flex_code
     AND id_flex_num = p_kff_str.id_flex_num
     AND flex_validation_rule_name = p_flex_validation_rule_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_flex_validation_rule_name);
END get_kff_cvr;
--
PROCEDURE get_kff_cvr(p_kff_str                   IN kff_str_type,
                      p_flex_validation_rule_name IN VARCHAR2,
                      x_kff_cvr                   OUT nocopy kff_cvr_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_cvr(P)';
   IF (NOT get_kff_cvr(p_kff_str, p_flex_validation_rule_name,
                       x_kff_cvr)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->CrossValidation form and ' ||
                      'create the cross validation rule, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_str.application_id),
                      'KFF Code', p_kff_str.id_flex_code,
                      'Structure Code', p_kff_str.id_flex_structure_code,
                      'CVR Name', p_flex_validation_rule_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_flex_validation_rule_name);
END get_kff_cvr;
--
FUNCTION get_kff_cvr_tl(p_kff_cvr    IN kff_cvr_type,
                        p_language   IN VARCHAR2,
                        x_kff_cvr_tl OUT nocopy kff_cvr_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_cvr_tl(F)';
   SELECT *
     INTO x_kff_cvr_tl
     FROM fnd_flex_vdation_rules_tl
     WHERE application_id =  p_kff_cvr.application_id
     AND id_flex_code = p_kff_cvr.id_flex_code
     AND id_flex_num = p_kff_cvr.id_flex_num
     AND flex_validation_rule_name = p_kff_cvr.flex_validation_rule_name
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_cvr.application_id,
                        p_kff_cvr.id_flex_code,
                        p_kff_cvr.id_flex_num,
                        p_kff_cvr.flex_validation_rule_name,
                        p_language);
END get_kff_cvr_tl;

-- --------------------------------------------------
FUNCTION get_kff_cvl(p_kff_cvr                    IN kff_cvr_type,
                     p_include_exclude_indicator  IN VARCHAR2,
                     p_concatenated_segments_low  IN VARCHAR2,
                     p_concatenated_segments_high IN VARCHAR2,
                     x_kff_cvl                    OUT nocopy kff_cvl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_cvl(F)';
   SELECT *
     INTO x_kff_cvl
     FROM fnd_flex_validation_rule_lines
     WHERE application_id =  p_kff_cvr.application_id
     AND id_flex_code = p_kff_cvr.id_flex_code
     AND id_flex_num = p_kff_cvr.id_flex_num
     AND flex_validation_rule_name = p_kff_cvr.flex_validation_rule_name
     AND include_exclude_indicator = p_include_exclude_indicator
     AND concatenated_segments_low = p_concatenated_segments_low
     AND concatenated_segments_high = p_concatenated_segments_high;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_cvr.application_id,
                        p_kff_cvr.id_flex_code,
                        p_kff_cvr.id_flex_num,
                        p_kff_cvr.flex_validation_rule_name,
                        p_include_exclude_indicator,
                        p_concatenated_segments_low,
                        p_concatenated_segments_high);
END get_kff_cvl;
--
PROCEDURE get_kff_cvl(p_kff_cvr                    IN kff_cvr_type,
                      p_include_exclude_indicator  IN VARCHAR2,
                      p_concatenated_segments_low  IN VARCHAR2,
                      p_concatenated_segments_high IN VARCHAR2,
                      x_kff_cvl                    OUT nocopy kff_cvl_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_cvl(P)';
   IF (NOT get_kff_cvl(p_kff_cvr, p_include_exclude_indicator,
                       p_concatenated_segments_low,
                       p_concatenated_segments_high,
                       x_kff_cvl)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->CrossValidation form and ' ||
                      'create the cross validation rule line, ' ||
                      'or use FNDLOAD (afffload.lct)',
                      'APP Id', To_char(p_kff_cvr.application_id),
                      'KFF Code', p_kff_cvr.id_flex_code,
                      'Structure Num', To_char(p_kff_cvr.id_flex_num),
                      'CVR Name', p_kff_cvr.flex_validation_rule_name,
                      'I/E Indicator', p_include_exclude_indicator,
                      'Segments Low', p_concatenated_segments_low,
                      'Segments High', p_concatenated_segments_high);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_cvr.application_id,
                        p_kff_cvr.id_flex_code,
                        p_kff_cvr.id_flex_num,
                        p_kff_cvr.flex_validation_rule_name,
                        p_include_exclude_indicator,
                        p_concatenated_segments_low,
                        p_concatenated_segments_high);
END get_kff_cvl;

-- --------------------------------------------------
FUNCTION get_kff_seg(p_kff_str                 IN kff_str_type,
                     p_application_column_name IN VARCHAR2,
                     x_kff_seg                 OUT nocopy kff_seg_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_seg(F)';
   SELECT *
     INTO x_kff_seg
     FROM fnd_id_flex_segments
     WHERE application_id =  p_kff_str.application_id
     AND id_flex_code = p_kff_str.id_flex_code
     AND id_flex_num = p_kff_str.id_flex_num
     AND application_column_name = p_application_column_name;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_application_column_name);
END get_kff_seg;
--
PROCEDURE get_kff_seg(p_kff_str                 IN kff_str_type,
                      p_application_column_name IN VARCHAR2,
                      x_kff_seg                 OUT nocopy kff_seg_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_seg(P)';
   IF (NOT get_kff_seg(p_kff_str, p_application_column_name,
                       x_kff_seg)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Segments form and ' ||
                      'create the segment, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_str.application_id),
                      'KFF Code', p_kff_str.id_flex_code,
                      'Structure Code', p_kff_str.id_flex_structure_code,
                      'COL Name', p_application_column_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_str.application_id,
                        p_kff_str.id_flex_code,
                        p_kff_str.id_flex_structure_code,
                        p_kff_str.id_flex_num,
                        p_application_column_name);
END get_kff_seg;
--
FUNCTION get_kff_seg_tl(p_kff_seg    IN kff_seg_type,
                        p_language   IN VARCHAR2,
                        x_kff_seg_tl OUT nocopy kff_seg_tl_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_seg_tl(F)';
   SELECT *
     INTO x_kff_seg_tl
     FROM fnd_id_flex_segments_tl
     WHERE application_id =  p_kff_seg.application_id
     AND id_flex_code = p_kff_seg.id_flex_code
     AND id_flex_num = p_kff_seg.id_flex_num
     AND application_column_name = p_kff_seg.application_column_name
     AND language = p_language;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_seg.application_id,
                        p_kff_seg.id_flex_code,
                        p_kff_seg.id_flex_num,
                        p_kff_seg.application_column_name,
                        p_kff_seg.segment_name,
                        p_language);
END get_kff_seg_tl;

-- --------------------------------------------------
FUNCTION get_kff_fqa(p_kff_flq IN kff_flq_type,
                     p_kff_seg IN kff_seg_type,
                     x_kff_fqa OUT nocopy kff_fqa_type)
  RETURN BOOLEAN
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_fqa(F)';
   SELECT *
     INTO x_kff_fqa
     FROM fnd_segment_attribute_values
     WHERE application_id =  p_kff_flq.application_id
     AND id_flex_code = p_kff_flq.id_flex_code
     AND segment_attribute_type = p_kff_flq.segment_attribute_type
     AND id_flex_num = p_kff_seg.id_flex_num
     AND application_column_name = p_kff_seg.application_column_name
     AND p_kff_seg.application_id = p_kff_flq.application_id
     AND p_kff_seg.id_flex_code = p_kff_flq.id_flex_code;
   RETURN TRUE;
EXCEPTION
   WHEN no_data_found THEN
      RETURN FALSE;
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flq.application_id,
                        p_kff_flq.id_flex_code,
                        p_kff_flq.segment_attribute_type,
                        p_kff_seg.application_id,
                        p_kff_seg.id_flex_code,
                        p_kff_seg.id_flex_num,
                        p_kff_seg.application_column_name);
END get_kff_fqa;
--
PROCEDURE get_kff_fqa(p_kff_flq IN kff_flq_type,
                      p_kff_seg IN kff_seg_type,
                      x_kff_fqa OUT nocopy kff_fqa_type)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'get_kff_fqa(P)';
   IF (NOT get_kff_fqa(p_kff_flq, p_kff_seg,
                       x_kff_fqa)) THEN
      raise_not_exist(l_func_name,
                      'Please use Application Developer:' ||
                      'Flexfield->Key->Register form and ' ||
                      'create the flexfield qualifier, ' ||
                      'or use FNDLOAD (afffload.lct).',
                      'APP Id', To_char(p_kff_flq.application_id),
                      'KFF Code', p_kff_flq.id_flex_code,
                      'Flex Qual', p_kff_flq.segment_attribute_type,
                      'Structure Num', To_char(p_kff_seg.id_flex_num),
                      'COL Name', p_kff_seg.application_column_name);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_kff_flq.application_id,
                        p_kff_flq.id_flex_code,
                        p_kff_flq.segment_attribute_type,
                        p_kff_seg.application_id,
                        p_kff_seg.id_flex_code,
                        p_kff_seg.id_flex_num,
                        p_kff_seg.application_column_name);
END get_kff_fqa;

-- --------------------------------------------------
PROCEDURE populate_kff_flexq_assign
  IS
     l_func_name VARCHAR2(80);

     CURSOR missing_sav_cur IS
        SELECT
          ifsg.application_id,
          ifsg.id_flex_code,
          ifsg.id_flex_num,
          ifsg.application_column_name,
          sat.segment_attribute_type,

          ifsg.created_by        ifsg_created_by,
          ifsg.creation_date     ifsg_creation_date,
          ifsg.last_updated_by   ifsg_last_updated_by,
          ifsg.last_update_date  ifsg_last_update_date,
          ifsg.last_update_login ifsg_last_update_login,

          sat.created_by         sat_created_by,
          sat.creation_date      sat_creation_date,
          sat.last_updated_by    sat_last_updated_by,
          sat.last_update_date   sat_last_update_date,
          sat.last_update_login  sat_last_update_login,

          sat.global_flag
          FROM fnd_id_flex_segments ifsg, fnd_segment_attribute_types sat
          WHERE sat.application_id = ifsg.application_id
          AND sat.id_flex_code = ifsg.id_flex_code
          AND NOT exists
          (SELECT NULL
           FROM fnd_segment_attribute_values sav
           WHERE sav.application_id = ifsg.application_id
           AND sav.id_flex_code = ifsg.id_flex_code
           AND sav.id_flex_num = ifsg.id_flex_num
           AND sav.application_column_name = ifsg.application_column_name
           AND sav.segment_attribute_type = sat.segment_attribute_type);

     l_who who_type;
BEGIN
   l_func_name := g_api_name || 'populate_kff_flexq_assign()';
   --
   -- Populate the cross product table. Copied from AFFFKAIB.pls
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Populating KFF_FLEXQ_ASSIGN.(no-TL)');
   END IF;

   --
   -- This code fixes if there are data inconsistencies.
   --
   FOR missing_sav_rec IN missing_sav_cur LOOP
      --
      -- Compute the who data of missing row
      --
      IF (missing_sav_rec.sat_creation_date >
          missing_sav_rec.ifsg_creation_date) THEN
         --
         -- Flex Qualifier was created last, SAV row should get
         -- the WHO data from Flex Qualifier.
         --

         l_who.created_by := missing_sav_rec.sat_created_by;
         l_who.creation_date := missing_sav_rec.sat_creation_date;
         l_who.last_updated_by := missing_sav_rec.sat_last_updated_by;
         l_who.last_update_date := missing_sav_rec.sat_last_update_date;
         l_who.last_update_login := missing_sav_rec.sat_last_update_login;
       ELSE

         l_who.created_by := missing_sav_rec.ifsg_created_by;
         l_who.creation_date := missing_sav_rec.ifsg_creation_date;
         l_who.last_updated_by := missing_sav_rec.ifsg_last_updated_by;
         l_who.last_update_date := missing_sav_rec.ifsg_last_update_date;
         l_who.last_update_login := missing_sav_rec.ifsg_last_update_login;
      END IF;

      --
      -- Insert the missing row
      --
      INSERT INTO fnd_segment_attribute_values
        (
         application_id,
         id_flex_code,
         id_flex_num,
         application_column_name,
         segment_attribute_type,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         attribute_value
         )
        SELECT
        ifsg.application_id,
        ifsg.id_flex_code,
        ifsg.id_flex_num,
        ifsg.application_column_name,
        sat.segment_attribute_type,

        l_who.created_by,
        l_who.creation_date,
        l_who.last_updated_by,
        l_who.last_update_date,
        l_who.last_update_login,

        sat.global_flag
        FROM fnd_id_flex_segments ifsg, fnd_segment_attribute_types sat
        WHERE sat.application_id = ifsg.application_id
        AND sat.id_flex_code = ifsg.id_flex_code
        AND ifsg.application_id = missing_sav_rec.application_id
        AND ifsg.id_flex_code = missing_sav_rec.id_flex_code
        AND ifsg.id_flex_num = missing_sav_rec.id_flex_num
        AND ifsg.application_column_name = missing_sav_rec.application_column_name
        AND sat.segment_attribute_type = missing_sav_rec.segment_attribute_type
        AND NOT exists
        (SELECT NULL
         FROM fnd_segment_attribute_values sav
         WHERE sav.application_id = ifsg.application_id
         AND sav.id_flex_code = ifsg.id_flex_code
         AND sav.id_flex_num = ifsg.id_flex_num
         AND sav.application_column_name = ifsg.application_column_name
         AND sav.segment_attribute_type = sat.segment_attribute_type);

      IF (SQL%rowcount > 0) THEN
         g_numof_changes := g_numof_changes + 1;
      END IF;
   END LOOP;

EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name);
END populate_kff_flexq_assign;

-- --------------------------------------------------
PROCEDURE populate_kff_segq_assign
  IS
     l_func_name VARCHAR2(80);
     l_sysdate   DATE;
BEGIN
   l_func_name := g_api_name || 'populate_kff_segq_assign()';
   --
   -- Populate the qualifiers table. Copied from AFFFKAIB.pls
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Populating KFF_SEGQ_ASSIGN.(no-TL)');
   END IF;

   l_sysdate := Sysdate;
   INSERT INTO fnd_flex_validation_qualifiers
     (
      flex_value_set_id,
      id_flex_application_id,
      id_flex_code,
      segment_attribute_type,
      value_attribute_type,
      assignment_date
      )
     SELECT DISTINCT ifsg.flex_value_set_id,
     ifsg.application_id,
     ifsg.id_flex_code,
     vat.segment_attribute_type,
     vat.value_attribute_type,
     l_sysdate
     FROM
     fnd_val_attribute_types_vl vat,
     fnd_segment_attribute_values sav,
     fnd_id_flex_segments_vl ifsg
     WHERE sav.application_id = ifsg.application_id
     AND sav.id_flex_code = ifsg.id_flex_code
     AND sav.id_flex_num = ifsg.id_flex_num
     AND sav.application_column_name = ifsg.application_column_name
     AND sav.attribute_value = 'Y'
     AND vat.application_id = sav.application_id
     AND vat.id_flex_code = sav.id_flex_code
     AND vat.segment_attribute_type = sav.segment_attribute_type
     AND ifsg.enabled_flag = 'Y'
     AND ifsg.flex_value_set_id IS NOT NULL
     AND NOT exists
     (SELECT NULL
      FROM fnd_flex_validation_qualifiers fvq
      WHERE fvq.flex_value_set_id = ifsg.flex_value_set_id
      AND fvq.id_flex_application_id = ifsg.application_id
      AND fvq.id_flex_code = ifsg.id_flex_code
      AND fvq.segment_attribute_type = sav.segment_attribute_type
      AND fvq.value_attribute_type = vat.value_attribute_type);
   IF (SQL%rowcount > 0) THEN
      g_numof_changes := g_numof_changes + 1;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name);
END populate_kff_segq_assign;

-- --------------------------------------------------
PROCEDURE delete_compiled_data(p_mode                       IN VARCHAR2,
                               p_application_id             IN NUMBER,
                               p_descriptive_flexfield_name IN VARCHAR2 DEFAULT NULL,
                               p_id_flex_code               IN VARCHAR2 DEFAULT NULL,
                               p_id_flex_num                IN NUMBER DEFAULT NULL)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'delete_compiled_data()';

   IF (p_mode = 'DFF') THEN

      DELETE FROM fnd_compiled_descriptive_flexs fcdf
        WHERE fcdf.application_id = p_application_id
        AND fcdf.descriptive_flexfield_name = p_descriptive_flexfield_name;

    ELSIF (p_mode = 'KFF-STR') THEN

      DELETE FROM fnd_compiled_id_flex_structs fcifs
        WHERE fcifs.application_id = p_application_id
        AND fcifs.id_flex_code = p_id_flex_code
        AND fcifs.id_flex_num = p_id_flex_num;

      DELETE FROM fnd_compiled_id_flexs fcif
        WHERE fcif.application_id = p_application_id
        AND fcif.id_flex_code = p_id_flex_code;

   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_mode,
                        p_application_id,
                        p_descriptive_flexfield_name,
                        p_id_flex_code,
                        p_id_flex_num);
END delete_compiled_data;

-- --------------------------------------------------
FUNCTION apps_initialize
  RETURN BOOLEAN
  IS
     l_func_name    VARCHAR2(80);
     l_user_id      NUMBER;
     l_resp_id      NUMBER;
     l_resp_appl_id NUMBER;
BEGIN
   l_func_name := g_api_name || 'apps_initialize';

   l_user_id      := fnd_global.user_id;
   l_resp_id      := fnd_global.resp_id;
   l_resp_appl_id := fnd_global.resp_appl_id;
   --
   -- If context is not set:
   -- Set the Apps Context. This is a workaround. CP team should set
   -- an ANONYMOUS context. See bug2014695.
   --
   IF (l_user_id <> -1 OR
       l_resp_id <> -1 OR
       l_resp_appl_id <> -1) THEN
      --
      -- Context was already set.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, ('Apps Context was already set to ' ||
                             '(user_id=' || l_user_id ||
                             ', resp_id=' || l_resp_id ||
                             ', resp_appl_id=' || l_resp_appl_id || ')'));
      END IF;

    ELSE

      SELECT u.user_id
        INTO l_user_id
        FROM fnd_user u
        WHERE u.user_name = 'SYSADMIN';

      SELECT r.application_id, r.responsibility_id
        INTO l_resp_appl_id, l_resp_id
        FROM fnd_application a, fnd_responsibility r
        WHERE r.application_id = a.application_id
        AND a.application_short_name = 'SYSADMIN'
        AND r.responsibility_key = 'SYSTEM_ADMINISTRATOR';

      fnd_global.apps_initialize(user_id      => l_user_id,
                                 resp_id      => l_resp_id,
                                 resp_appl_id => l_resp_appl_id);

      IF (g_debug_on) THEN
         debug(l_func_name, ('Apps Context is set to (SYSADMIN)=' ||
                             '(user_id=' || l_user_id ||
                             ', resp_id=' || l_resp_id ||
                             ', resp_appl_id=' || l_resp_appl_id || ')'));
      END IF;
   END IF;
   RETURN(TRUE);
EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug(l_func_name,('Unable to set SYSADMIN context. ' ||
                            'SQLERRM : ' || Sqlerrm ||
                            'fnd_message : ' || fnd_message.get));
      END IF;
      RETURN(FALSE);
END apps_initialize;

-- --------------------------------------------------
function submit_cp_request(p_application_short_name  in varchar2,
                           p_concurrent_program_name in varchar2,
                           px_description            in out nocopy varchar2,
                           p_argument_count          in number,
                           p_argument1               in varchar2,
                           p_argument2               in varchar2 default null,
                           p_argument3               in varchar2 default null,
                           p_argument4               in varchar2 default null,
                           p_argument5               in varchar2 default null)
  return varchar2
is
   l_request_id     number;
   l_request_id_vc2 varchar2(1000);
   l_description    varchar2(32000);
   l_argument2      VARCHAR2(1024);
   l_argument3      VARCHAR2(1024);
   l_argument4      VARCHAR2(1024);
   l_argument5      VARCHAR2(1024);
begin
   l_argument2 := g_default_argument;
   l_argument3 := g_default_argument;
   l_argument4 := g_default_argument;
   l_argument5 := g_default_argument;

   --
   -- Dump the arguments to description.
   --
   l_description := 'Flex Loader: ' || p_concurrent_program_name || '(' || p_argument1;

   if (p_argument_count > 1) then
      l_argument2 := p_argument2;
      l_description := l_description || ',' || l_argument2;

      if (p_argument_count > 2) then
         l_argument3 := p_argument3;
         l_description := l_description || ',' || l_argument3;

         if (p_argument_count > 3) then
            l_argument4 := p_argument4;
            l_description := l_description || ',' || l_argument4;

            if (p_argument_count > 4) then
               l_argument5 := p_argument5;
               l_description := l_description || ',' || l_argument5;
            end if;
         end if;
      end if;
   end if;

   l_description := l_description || ')';

   px_description := substrb(l_description, 1, 240);

   --
   -- See if the same request with the same arguments was already submitted.
   --
   begin
      SELECT request_id
        INTO l_request_id
        FROM fnd_concurrent_requests fcr,
             fnd_concurrent_programs fcp,
             fnd_application fa
        WHERE fa.application_short_name = p_application_short_name
        AND fcp.application_id = fa.application_id
        AND fcp.concurrent_program_name = p_concurrent_program_name
        AND fcr.program_application_id = fcp.application_id
        AND fcr.concurrent_program_id  = fcp.concurrent_program_id
        AND fcr.status_code in ('I',  -- ' Normal'
                                'Q',  -- 'StandBy'
                                'R')  -- '  Normal'
        AND fcr.phase_code = 'P'      -- 'Pending'
        --
        -- p_argument1 is mandatory and cannot be NULL
        --
        AND nvl(fcr.argument1, g_nvl_value) = p_argument1
        --
        -- Other arguments are optional and can be NULL
        --
        AND ((p_argument_count < 2) OR
             (nvl(fcr.argument2, g_nvl_value) = nvl(l_argument2, g_nvl_value)))
        AND ((p_argument_count < 3) OR
             (nvl(fcr.argument3, g_nvl_value) = nvl(l_argument3, g_nvl_value)))
        AND ((p_argument_count < 4) OR
             (nvl(fcr.argument4, g_nvl_value) = nvl(l_argument4, g_nvl_value)))
        AND ((p_argument_count < 5) OR
             (nvl(fcr.argument5, g_nvl_value) = nvl(l_argument5, g_nvl_value)))
        AND ROWNUM = 1;

      l_request_id_vc2 := To_char(l_request_id) || ' was already submitted';
   exception
      when others then
         l_request_id_vc2 := '0';
   end;

   if (l_request_id_vc2 = '0') then

      l_request_id_vc2 := fnd_request.submit_request
        (application => p_application_short_name,
         program     => p_concurrent_program_name,
         description => px_description,
         start_time  => NULL,
         sub_request => FALSE,
         argument1   => p_argument1,
         argument2   => l_argument2,
         argument3   => l_argument3,
         argument4   => l_argument4,
         argument5   => l_argument5);

   end if;

   return l_request_id_vc2;

exception
   when others THEN
      --
      -- GEO report the error!!
      --
      return '0';
end submit_cp_request;

-- --------------------------------------------------
PROCEDURE call_cp(p_mode                       IN VARCHAR2,
                  p_upload_mode                IN VARCHAR2,
                  p_application_short_name     IN VARCHAR2 DEFAULT NULL,
                  p_id_flex_code               IN VARCHAR2 DEFAULT NULL,
                  p_id_flex_structure_code     IN VARCHAR2 DEFAULT NULL,
                  p_descriptive_flexfield_name IN VARCHAR2 DEFAULT NULL,
                  p_flex_value_set_name        IN VARCHAR2 DEFAULT NULL)
  IS
     l_func_name      VARCHAR2(80);
     l_vst_set        vst_set_type;
     l_dff_flx        dff_flx_type;
     l_kff_flx        kff_flx_type;
     l_kff_str        kff_str_type;
     l_request_id_vc2 VARCHAR2(1000);
     l_set_usage_flag VARCHAR2(10);
     l_description    VARCHAR2(240);

BEGIN
   l_func_name := g_api_name || 'call_cp(' || p_mode || ')';
   --
   -- Get the definitions.
   --
   IF (p_mode = 'VST') THEN
      IF (NOT get_vst_set(p_flex_value_set_name,
                          l_vst_set)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Unable to find VST.');
         END IF;
         GOTO label_done;
      END IF;
    ELSIF (p_mode = 'DFF') THEN
      IF (NOT get_dff_flx(p_application_short_name,
                          p_descriptive_flexfield_name,
                          l_dff_flx)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Unable to find DFF.');
         END IF;
         GOTO label_done;
      END IF;
    ELSIF (p_mode LIKE 'KFF%') THEN
      IF (NOT get_kff_flx(p_application_short_name,
                          p_id_flex_code,
                          l_kff_flx)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Unable to find KFF.');
         END IF;
         GOTO label_done;
      END IF;
      IF (p_mode = 'KFF-STR') THEN
         IF (NOT get_kff_str(l_kff_flx,
                             p_id_flex_structure_code,
                             l_kff_str)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Unable to find KFF-STR.');
            END IF;
            GOTO label_done;
         END IF;
      END IF;
   END IF;

   --
   -- Initialize the apps context.
   --
   IF (NOT apps_initialize()) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, ('Cannot set Apps Context, cannot submit ' ||
                             'concurrent programs.'));
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Submit compile requests with high priority.
   --
   fnd_profile.put('CONC_PRIORITY', 1);

   IF (p_mode = 'VST') THEN
      --
      -- Nothing to compile in NLS mode.
      --
      IF (p_upload_mode = 'NLS') THEN
         GOTO label_done;
      END IF;

      --
      -- Compile the value hierarchies.
      --
      l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                            p_concurrent_program_name => 'FDFCHY',
                                            px_description            => l_description,
                                            p_argument_count          => 1,
                                            p_argument1               => p_flex_value_set_name);

   ELSIF (p_mode = 'DFF') THEN
      delete_compiled_data(p_mode                       => p_mode,
                           p_application_id             => l_dff_flx.application_id,
                           p_descriptive_flexfield_name => p_descriptive_flexfield_name);

      --
      -- Submit compiler request if this DFF is frozen.
      --
      IF (l_dff_flx.freeze_flex_definition_flag = 'Y') THEN
         --
         -- Compile non-compiled flexfields
         --
         l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                               p_concurrent_program_name => 'FDFCMPN',
                                               px_description            => l_description,
                                               p_argument_count          => 1,
                                               p_argument1               => 'N');

         if (l_request_id_vc2 = '0') then
            --
            -- Probably FDFCMPN has not been defined yet.
            -- This section of the code should be removed later.
            --
            if (g_debug_on) then
               debug(l_func_name, 'FDFCMPN is not defined.');
            end if;
            l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                                  p_concurrent_program_name => 'FDFCMPD',
                                                  px_description            => l_description,
                                                  p_argument_count          => 3,
                                                  p_argument1               => 'D',
                                                  p_argument2               => p_application_short_name,
                                                  p_argument3               => p_descriptive_flexfield_name);
         end if;

       ELSE
         l_request_id_vc2 := 'DFF is not frozen.';

      END IF;

    ELSIF (p_mode = 'KFF') THEN
      GOTO label_fndffvgn;

    ELSIF (p_mode = 'KFF-STR') THEN
      delete_compiled_data(p_mode           => p_mode,
                           p_application_id => l_kff_flx.application_id,
                           p_id_flex_code   => p_id_flex_code,
                           p_id_flex_num    => l_kff_str.id_flex_num);

      --
      -- Submit compiler request if this KFF Structure is frozen.
      --
      IF (l_kff_str.freeze_flex_definition_flag = 'Y') THEN
         --
         -- Compile non-compiled flexfields
         --
         l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                               p_concurrent_program_name => 'FDFCMPN',
                                               px_description            => l_description,
                                               p_argument_count          => 1,
                                               p_argument1               => 'N');

         if (l_request_id_vc2 = '0') then
            --
            -- Probably FDFCMPN has not been defined yet.
            -- This section of the code should be removed later.
            --
            if (g_debug_on) then
               debug(l_func_name, 'FDFCMPN is not defined.');
            end if;
            l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                                  p_concurrent_program_name => 'FDFCMPK',
                                                  px_description            => l_description,
                                                  p_argument_count          => 4,
                                                  p_argument1               => 'K',
                                                  p_argument2               => p_application_short_name,
                                                  p_argument3               => p_id_flex_code,
                                                  p_argument4               => l_kff_str.id_flex_num);
         end if;

       ELSE
         l_request_id_vc2 := 'KFF Structure is not frozen.';

      END IF;
   END IF;

   IF (g_debug_on) THEN
      IF (l_request_id_vc2 = '0') THEN
         debug(l_func_name, ('Unable to submit ' || l_description || '. ' ||
                             'ERROR: ' || fnd_message.get));
       ELSE
         debug(l_func_name, ('Submitted ' || l_description || '. ' ||
                             'Request ID: ' || l_request_id_vc2));
      END IF;
   END IF;

<<label_fndffvgn>>
   --
   -- Generate the view.
   --
   IF (p_mode = 'VST') THEN
      GOTO label_done;
   ELSIF (p_mode = 'DFF') THEN
      --
      -- Nothing to generate in NLS mode.
      --
      IF (p_upload_mode = 'NLS') THEN
         GOTO label_done;
      END IF;

      IF (p_descriptive_flexfield_name LIKE '$SRS$.%') THEN
         GOTO label_done;
      ELSE
         --
         -- Submit generate view request if this DFF is frozen.
         --
         IF (l_dff_flx.freeze_flex_definition_flag = 'Y') THEN
            --
            -- Generate _DFV.
            --
            l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                                  p_concurrent_program_name => 'FDFVGN',
                                                  px_description            => l_description,
                                                  p_argument_count          => 3,
                                                  p_argument1               => '3',
                                                  p_argument2               => l_dff_flx.application_id,
                                                  p_argument3               => p_descriptive_flexfield_name);

            actualize_view(NULL, 'D', l_dff_flx.application_id, p_descriptive_flexfield_name);

          ELSE
            l_request_id_vc2 := 'DFF is not frozen.';

         END IF;
      END IF;
   ELSIF (p_mode = 'KFF') THEN
      --
      -- Nothing to generate in NLS mode.
      --
      IF (p_upload_mode = 'NLS') THEN
         GOTO label_done;
      END IF;

      --
      -- Generate _KFV.
      --
      IF ((p_application_short_name = 'INV' AND p_id_flex_code = 'MSTK') OR
          (p_application_short_name = 'INV' AND p_id_flex_code = 'MTLL') OR
          (p_application_short_name = 'INV' AND p_id_flex_code = 'MICG') OR
          (p_application_short_name = 'INV' AND p_id_flex_code = 'MDSP') OR
          (p_application_short_name = 'INV' AND p_id_flex_code = 'SERV')) THEN
         l_set_usage_flag := 'Y';
      ELSE
         l_set_usage_flag := 'N';
      END IF;

      l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                            p_concurrent_program_name => 'FDFVGN',
                                            px_description            => l_description,
                                            p_argument_count          => 5,
                                            p_argument1               => '2',
                                            p_argument2               => l_kff_flx.application_id,
                                            p_argument3               => p_id_flex_code,
                                            p_argument4               => NULL,
                                            p_argument5               => l_set_usage_flag);

      actualize_view(NULL, 'K', l_kff_flx.application_id, p_id_flex_code);

    ELSIF (p_mode = 'KFF-STR') THEN
      --
      -- Nothing to generate in NLS mode.
      --
      IF (p_upload_mode = 'NLS') THEN
         GOTO label_done;
      END IF;

      --
      -- Generate Structure View.
      --
      IF (l_kff_str.structure_view_name IS NULL) THEN
         GOTO label_done;
      ELSE
         --
         -- Submit generate view request if this KFF Structure is frozen.
         --
         IF (l_kff_str.freeze_flex_definition_flag = 'Y') THEN

            l_request_id_vc2 := submit_cp_request(p_application_short_name  => 'FND',
                                                  p_concurrent_program_name => 'FDFVGN',
                                                  px_description            => l_description,
                                                  p_argument_count          => 5,
                                                  p_argument1               => '1',
                                                  p_argument2               => l_kff_str.application_id,
                                                  p_argument3               => p_id_flex_code,
                                                  p_argument4               => l_kff_str.id_flex_num,
                                                  p_argument5               => l_kff_str.structure_view_name);

            actualize_view(l_kff_str.structure_view_name, NULL, l_kff_str.application_id, p_id_flex_code);
          ELSE
            l_request_id_vc2 := 'KFF Structure is not frozen.';

         END IF;
      END IF;
   END IF;

   IF (g_debug_on) THEN
      IF (l_request_id_vc2 = '0') THEN
         debug(l_func_name, ('Unable to submit ' || l_description || '. ' ||
                             'ERROR: ' || fnd_message.get));
       ELSE
         debug(l_func_name, ('Submitted ' || l_description || '. ' ||
                             'Request ID: ' || l_request_id_vc2));
      END IF;
   END IF;

<<label_done>>
   fnd_message.clear();

EXCEPTION
   WHEN OTHERS THEN
      --
      -- GEO!!
      --
      IF (g_debug_on) THEN
         debug(l_func_name, ('Not handling the top level exception. ' ||
                             'SQLERRM : ' || Sqlerrm));
      END IF;

      BEGIN
         fnd_message.clear();
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
END call_cp;

-- --------------------------------------------------
PROCEDURE upload_value_qualifier_value
  (p_caller_entity                IN VARCHAR2,
   p_upload_phase                 IN VARCHAR2,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2,
   p_compiled_value_attribute_val IN VARCHAR2)
  IS
     l_func_name    VARCHAR2(80);
     l_app          app_type;
     l_kff_flx      kff_flx_type;
     l_kff_flq      kff_flq_type;
     l_kff_sgq      kff_sgq_type;

     l_vst_set      vst_set_type;
     l_vst_val      vst_val_type;

     l_vtv_arr_size NUMBER;
     l_vtv_arr      vtv_arr_type;

     i              NUMBER;
     l_cva          VARCHAR2(32000);
     l_pos          NUMBER;
     l_assigned     BOOLEAN;
     l_file_who     fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'upload_value_qualifier_value()';
   init('VALUE_QUALIFIER_VALUE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',CALL:'  || p_caller_entity ||
            ',VSET:'  || p_flex_value_set_name ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',VAL:'   || p_flex_value ||
            ',CVAL:'  || p_compiled_value_attribute_val);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set and Value exist.
   --
   get_vst_set(p_flex_value_set_name,
               l_vst_set);
   get_vst_val(l_vst_set,
               p_parent_flex_value_low,
               p_flex_value,
               l_vst_val);

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_val.last_updated_by,
        p_db_last_update_date          => l_vst_val.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Get the application_id
   --
   IF (p_caller_entity = 'KFF_QUALIFIER_VALUE') THEN
      get_app(p_application_short_name, l_app);
    ELSE
      IF (NOT get_app(p_application_short_name, l_app)) THEN
         GOTO label_done;
      END IF;
   END IF;

   IF (p_caller_entity = 'KFF_QUALIFIER_VALUE') THEN
      --
      -- Make sure KFF, Flexfield Qualifier and Segment Qualifier exist.
      --
      get_kff_flx(p_application_short_name,
                  p_id_flex_code,
                  l_kff_flx);
      get_kff_flq(l_kff_flx,
                  p_segment_attribute_type,
                  l_kff_flq);
      get_kff_sgq(l_kff_flq,
                  p_value_attribute_type,
                  l_kff_sgq);
   END IF;

   --
   -- Usual upload.
   --

   --
   -- Get the qualifier details for this value set.
   --
   get_vtv_arr(l_vst_set,
               l_vtv_arr_size,
               l_vtv_arr);

   IF (p_caller_entity = 'KFF_QUALIFIER_VALUE') THEN
      IF (l_vtv_arr_size = 0) THEN
         raise_error(l_func_name, ERROR_KFF_NO_QUALIFIERS,
                     'There are no qualifiers defined for Value Set : ' ||
                     l_vst_set.flex_value_set_name);
      END IF;
   END IF;

   --
   -- De-normalize the concatenated qualifier values.
   --
   l_cva := l_vst_val.compiled_value_attributes || g_newline;
   i := 1;
   WHILE ((l_cva IS NOT NULL) AND (i <= l_vtv_arr_size)) LOOP
      l_pos := Instr(l_cva, g_newline, 1, 1);
      l_vtv_arr(i).qualifier_value := Substr(l_cva, 1, l_pos - 1);
      l_cva := Substr(l_cva, l_pos + 1);
      i := i + 1;
   END LOOP;

   WHILE (i <= l_vtv_arr_size) LOOP
      l_vtv_arr(i).qualifier_value := l_vtv_arr(i).default_value;
      i := i + 1;
   END LOOP;

   --
   -- Concatenate the values.
   --
   i := 0;
   l_cva := NULL;
   l_assigned := FALSE;
   FOR i IN 1..l_vtv_arr_size LOOP
      IF ((l_vtv_arr(i).id_flex_application_id = l_app.application_id) AND
          (l_vtv_arr(i).id_flex_code           = p_id_flex_code) AND
          (l_vtv_arr(i).segment_attribute_type = p_segment_attribute_type) AND
          (l_vtv_arr(i).value_attribute_type   = p_value_attribute_type)) THEN
         IF (p_compiled_value_attribute_val IS NOT NULL) THEN
            l_vtv_arr(i).qualifier_value := p_compiled_value_attribute_val;
         END IF;
         l_assigned := TRUE;
      END IF;
      l_cva := l_cva || g_newline || l_vtv_arr(i).qualifier_value;
   END LOOP;

   IF (p_caller_entity = 'KFF_QUALIFIER_VALUE') THEN
      IF (NOT l_assigned) THEN
         raise_error(l_func_name, ERROR_KFF_NOT_QUALIFIED,
                     p_flex_value_set_name ||
                     ' value set is not qualified by the qualifier: '   ||
                     ' APP Id: '    || l_kff_sgq.application_id         ||
                     ' KFF Code: '  || l_kff_sgq.id_flex_code           ||
                     ' FLEX Qual: ' || l_kff_sgq.segment_attribute_type ||
                     ' SEG Qual: '  || l_kff_sgq.value_attribute_type);
      END IF;
   END IF;

   --
   -- Remove the first newline.
   --
   l_cva := Substr(l_cva, Length(g_newline) + 1);

   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VALUE_QUALIFIER_VALUE.(no-TL)');
   END IF;
   UPDATE fnd_flex_values SET
     last_updated_by           = l_file_who.last_updated_by,
     last_update_date          = l_file_who.last_update_date,
     last_update_login         = l_file_who.last_update_login,
     compiled_value_attributes = l_cva
     WHERE flex_value_set_id = l_vst_set.flex_value_set_id
     AND flex_value_id = l_vst_val.flex_value_id;

   <<label_done>>
   done('VALUE_QUALIFIER_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_caller_entity,
                        p_flex_value_set_name,
                        p_application_short_name,
                        p_id_flex_code,
                        p_segment_attribute_type,
                        p_value_attribute_type,
                        p_parent_flex_value_low,
                        p_flex_value,
                        p_compiled_value_attribute_val);
END upload_value_qualifier_value;

-- ==================================================
--  VALUE_SET
-- ==================================================
PROCEDURE up_value_set
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_validation_type              IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_longlist_flag                IN VARCHAR2,
   p_format_type                  IN VARCHAR2,
   p_maximum_size                 IN VARCHAR2,
   p_number_precision             IN VARCHAR2,
   p_alphanumeric_allowed_flag    IN VARCHAR2,
   p_uppercase_only_flag          IN VARCHAR2,
   p_numeric_mode_enabled_flag    IN VARCHAR2,
   p_minimum_value                IN VARCHAR2,
   p_maximum_value                IN VARCHAR2,
   p_parent_flex_value_set_name   IN VARCHAR2,
   p_dependant_default_value      IN VARCHAR2,
   p_dependant_default_meaning    IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name         VARCHAR2(80);
     l_parent_vst_set    vst_set_type;
     l_parent_vst_set_id NUMBER := NULL;
     l_vst_set           vst_set_type;
     l_file_who          fnd_flex_loader_apis.who_type;
     l_count             NUMBER;
BEGIN
   l_func_name := g_api_name || 'up_value_set()';
   init('VALUE_SET', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',VSET:'  || p_flex_value_set_name ||
            ',VTYPE:' || p_validation_type ||
            ',FTYPE:' || p_format_type);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      start_transaction(ENTITY_VALUE_SET);
      lock_entity('VALUE_SET',
                  p_flex_value_set_name);

      g_numof_changes := 0;
      --
      -- Gather WHO Information.
      --
      IF (get_vst_set(p_flex_value_set_name => p_flex_value_set_name,
                      x_vst_set             => l_vst_set)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_vst_set.last_updated_by,
           p_db_last_update_date          => l_vst_set.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating VALUE_SET.(non-MLS)');
         END IF;
         UPDATE fnd_flex_value_sets SET
           last_updated_by   = l_file_who.last_updated_by,
           last_update_date  = l_file_who.last_update_date,
           last_update_login = l_file_who.last_update_login,
           description       = Nvl(p_description, description)
           WHERE flex_value_set_name = p_flex_value_set_name
           AND userenv('LANG') = (SELECT language_code
                                  FROM fnd_languages
                                  WHERE installed_flag = 'B');
         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'No entity to translate.');
            END IF;
         END IF;
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --
         IF (p_validation_type IN ('D','Y')) THEN
            --
            -- Make sure Parent Value Set exists.
            --
            get_vst_set(p_parent_flex_value_set_name, l_parent_vst_set);
            l_parent_vst_set_id := l_parent_vst_set.flex_value_set_id;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Updating VALUE_SET.(non-MLS)');
         END IF;
         UPDATE fnd_flex_value_sets SET
           last_updated_by           = l_file_who.last_updated_by,
           last_update_date          = l_file_who.last_update_date,
           last_update_login         = l_file_who.last_update_login,
           description               = p_description,
           validation_type           = p_validation_type,
           protected_flag            = p_protected_flag,
           security_enabled_flag     = p_security_enabled_flag,
           longlist_flag             = p_longlist_flag,
           format_type               = p_format_type,
           maximum_size              = p_maximum_size,
           number_precision          = p_number_precision,
           alphanumeric_allowed_flag = p_alphanumeric_allowed_flag,
           uppercase_only_flag       = p_uppercase_only_flag,
           numeric_mode_enabled_flag = p_numeric_mode_enabled_flag,
           minimum_value             = p_minimum_value,
           maximum_value             = p_maximum_value,
           parent_flex_value_set_id  = l_parent_vst_set_id,
           dependant_default_value   = p_dependant_default_value,
           dependant_default_meaning = p_dependant_default_meaning
           WHERE flex_value_set_name = p_flex_value_set_name;

         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Inserting VALUE_SET.(non-MLS)');
            END IF;
            INSERT INTO fnd_flex_value_sets
              (
               flex_value_set_id,
               flex_value_set_name,

               created_by,
               creation_date,
               last_updated_by,
               last_update_date,
               last_update_login,

               description,
               validation_type,
               protected_flag,
               security_enabled_flag,
               longlist_flag,
               format_type,
               maximum_size,
               number_precision,
               alphanumeric_allowed_flag,
               uppercase_only_flag,
               numeric_mode_enabled_flag,
               minimum_value,
               maximum_value,
               parent_flex_value_set_id,
               dependant_default_value,
               dependant_default_meaning
               )
              VALUES
              (
               fnd_flex_value_sets_s.NEXTVAL,
               p_flex_value_set_name,

               l_file_who.created_by,
               l_file_who.creation_date,
               l_file_who.last_updated_by,
               l_file_who.last_update_date,
               l_file_who.last_update_login,

               p_description,
               p_validation_type,
               p_protected_flag,
               p_security_enabled_flag,
               p_longlist_flag,
               p_format_type,
               p_maximum_size,
               p_number_precision,
               p_alphanumeric_allowed_flag,
               p_uppercase_only_flag,
               p_numeric_mode_enabled_flag,
               p_minimum_value,
               p_maximum_value,
               l_parent_vst_set_id,
               p_dependant_default_value,
               p_dependant_default_meaning
               );
         END IF;
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
      --
      -- Compile value hierarchies.
      --
      IF (g_numof_changes > 0) THEN
         SELECT COUNT(*)
           INTO l_count
           FROM fnd_flex_value_norm_hierarchy
           WHERE flex_value_set_id =
           (SELECT flex_value_set_id
            FROM fnd_flex_value_sets
            WHERE flex_value_set_name = p_flex_value_set_name);
         IF (l_count > 0) THEN
            call_cp(p_mode                => 'VST',
                    p_upload_mode         => p_upload_mode,
                    p_flex_value_set_name => p_flex_value_set_name);
         END IF;
      END IF;
      finish_transaction(ENTITY_VALUE_SET);
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('VALUE_SET', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      --
      -- First report the existing exception
      --
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name);

      BEGIN
         release_entity();
         IF (p_upload_phase = 'END') THEN
            finish_transaction(ENTITY_VALUE_SET);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            report_public_api_exception(l_func_name,
                                        p_upload_phase,
                                        p_flex_value_set_name);
      END;
END up_value_set;

-- --------------------------------------------------
PROCEDURE up_vset_depends_on
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_ind_flex_value_set_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_ind_validation_type          IN VARCHAR2,
   p_dep_validation_type          IN VARCHAR2)
  IS
     l_func_name    VARCHAR2(80);
     l_dep_vst_set  vst_set_type;
     l_ind_vst_set  vst_set_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_depends_on()';
   init('VSET_DEPENDS_ON', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:'  || p_upload_mode ||
            ',DEP_VSET:' || p_flex_value_set_name ||
            ',IND_VSET:' || p_ind_flex_value_set_name ||
            ',VTYPES:' || p_dep_validation_type || '->' || p_ind_validation_type);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Sets exist.
   --
   get_vst_set(p_ind_flex_value_set_name, l_ind_vst_set);
   get_vst_set(p_flex_value_set_name, l_dep_vst_set);

   IF ((l_dep_vst_set.validation_type = 'D' AND
        l_ind_vst_set.validation_type = 'I') OR
       (l_dep_vst_set.validation_type = 'Y' AND
        l_ind_vst_set.validation_type = 'X')) THEN
      NULL;
    ELSE
      raise_error(l_func_name, ERROR_VST_TYPE_MISMATCH,
                  'Independent Value Set Validation Type Mismatch',
                  'Please make sure Dependent Value Set depends on ' ||
                  'an Independent Value Set');
   END IF;

   <<label_done>>
   done('VSET_DEPENDS_ON', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_ind_flex_value_set_name);
END up_vset_depends_on;

-- --------------------------------------------------
PROCEDURE up_vset_table
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_summary_allowed_flag         IN VARCHAR2,
   p_value_column_name            IN VARCHAR2,
   p_value_column_type            IN VARCHAR2,
   p_value_column_size            IN VARCHAR2,
   p_id_column_name               IN VARCHAR2,
   p_id_column_type               IN VARCHAR2,
   p_id_column_size               IN VARCHAR2,
   p_meaning_column_name          IN VARCHAR2,
   p_meaning_column_type          IN VARCHAR2,
   p_meaning_column_size          IN VARCHAR2,
   p_enabled_column_name          IN VARCHAR2,
   p_compiled_attribute_column_na IN VARCHAR2,
   p_hierarchy_level_column_name  IN VARCHAR2,
   p_start_date_column_name       IN VARCHAR2,
   p_end_date_column_name         IN VARCHAR2,
   p_summary_column_name          IN VARCHAR2,
   p_additional_where_clause      IN VARCHAR2,
   p_additional_quickpick_columns IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_vst_set    vst_set_type;
     l_vst_tbl    vst_tbl_type;
     l_table_app  app_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_result     VARCHAR2(100);
     l_message    VARCHAR2(32000);
BEGIN
   l_func_name := g_api_name || 'up_vset_table()';
   init('VSET_TABLE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',TNAME:' || p_application_table_name);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set exists.
   --
   get_vst_set(p_flex_value_set_name, l_vst_set);

   IF (l_vst_set.validation_type <> 'F') THEN
      raise_error(l_func_name, ERROR_VST_NOT_TABLE_VST, 'Not a table validated value set');
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_vst_tbl(p_vst_set => l_vst_set,
                   x_vst_tbl => l_vst_tbl)) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_tbl.last_updated_by,
        p_db_last_update_date          => l_vst_tbl.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --
   IF (p_table_application_short_name IS NOT NULL) THEN
      --
      -- Make sure Application exists.
      --
      get_app(p_table_application_short_name, l_table_app);
   END IF;

   --
   -- Validate the table value set
   --
--   fnd_flex_val_api.validate_table_vset
--     (p_flex_value_set_name           => p_flex_value_set_name,
--      p_id_column_name                => p_id_column_name,
--      p_value_column_name             => p_value_column_name,
--      p_meaning_column_name           => p_meaning_column_name,
--      p_additional_quickpick_columns  => p_additional_quickpick_columns,
--      p_application_table_name        => p_application_table_name,
--      p_additional_where_clause       => p_additional_where_clause,
--      x_result                        => l_result,
--      x_message                       => l_message);
--
--   IF (l_result = 'Failure') THEN
--      raise_error(l_func_name, l_message);
--   END IF;

   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VSET_TABLE.(no-TL)');
   END IF;
   UPDATE fnd_flex_validation_tables SET
     last_updated_by                = l_file_who.last_updated_by,
     last_update_date               = l_file_who.last_update_date,
     last_update_login              = l_file_who.last_update_login,
     table_application_id           = l_table_app.application_id,
     application_table_name         = p_application_table_name,
     summary_allowed_flag           = p_summary_allowed_flag,
     value_column_name              = p_value_column_name,
     value_column_type              = p_value_column_type,
     value_column_size              = p_value_column_size,
     id_column_name                 = p_id_column_name,
     id_column_type                 = p_id_column_type,
     id_column_size                 = p_id_column_size,
     meaning_column_name            = p_meaning_column_name,
     meaning_column_type            = p_meaning_column_type,
     meaning_column_size            = p_meaning_column_size,
     enabled_column_name            = p_enabled_column_name,
     compiled_attribute_column_name = p_compiled_attribute_column_na,
     hierarchy_level_column_name    = p_hierarchy_level_column_name,
     start_date_column_name         = p_start_date_column_name,
     end_date_column_name           = p_end_date_column_name,
     summary_column_name            = p_summary_column_name,
     additional_where_clause        = p_additional_where_clause,
     additional_quickpick_columns   = p_additional_quickpick_columns
     WHERE flex_value_set_id = l_vst_set.flex_value_set_id;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting VSET_TABLE.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_validation_tables
        (
         flex_value_set_id,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         table_application_id,
         application_table_name,
         summary_allowed_flag,
         value_column_name,
         value_column_type,
         value_column_size,
         id_column_name,
         id_column_type,
         id_column_size,
         meaning_column_name,
         meaning_column_type,
         meaning_column_size,
         enabled_column_name,
         compiled_attribute_column_name,
         hierarchy_level_column_name,
         start_date_column_name,
         end_date_column_name,
         summary_column_name,
         additional_where_clause,
         additional_quickpick_columns
         )
        VALUES
        (
         l_vst_set.flex_value_set_id,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         l_table_app.application_id,
         p_application_table_name,
         p_summary_allowed_flag,
         p_value_column_name,
         p_value_column_type,
         p_value_column_size,
         p_id_column_name,
         p_id_column_type,
         p_id_column_size,
         p_meaning_column_name,
         p_meaning_column_type,
         p_meaning_column_size,
         p_enabled_column_name,
         p_compiled_attribute_column_na,
         p_hierarchy_level_column_name,
         p_start_date_column_name,
         p_end_date_column_name,
         p_summary_column_name,
         p_additional_where_clause,
         p_additional_quickpick_columns
         );
   END IF;

   <<label_done>>
   done('VSET_TABLE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name);
END up_vset_table;

-- --------------------------------------------------
PROCEDURE up_vset_event
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_event_code                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_user_exit                    IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_vst_evt   vst_evt_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_event()';
   init('VSET_EVENT', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',ECODE:' || p_event_code);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set exists.
   --
   get_vst_set(p_flex_value_set_name, l_vst_set);

   IF (NOT (l_vst_set.validation_type IN ('U', 'P'))) THEN
      raise_error(l_func_name, ERROR_VST_NOT_UEXIT_VST, 'Not a user_exit validated value set');
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_vst_evt(p_vst_set    => l_vst_set,
                   p_event_code => p_event_code,
                   x_vst_evt    => l_vst_evt)) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_evt.last_updated_by,
        p_db_last_update_date          => l_vst_evt.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VSET_EVENT.(no-TL)');
   END IF;
   UPDATE fnd_flex_validation_events SET
     last_updated_by   = l_file_who.last_updated_by,
     last_update_date  = l_file_who.last_update_date,
     last_update_login = l_file_who.last_update_login,
     user_exit         = p_user_exit
     WHERE flex_value_set_id = l_vst_set.flex_value_set_id
     AND event_code = p_event_code;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting VSET_EVENT.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_validation_events
        (
         flex_value_set_id,
         event_code,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         user_exit
         )
        VALUES
        (
         l_vst_set.flex_value_set_id,
         p_event_code,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         p_user_exit
         );
   END IF;

   <<label_done>>
   done('VSET_EVENT', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_event_code);
END up_vset_event;

-- --------------------------------------------------
PROCEDURE up_vset_security_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2,
   p_error_message                IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_vst_set    vst_set_type;
     l_vst_scr    vst_scr_type;
     l_vst_scr_tl vst_scr_tl_type;
    -- l_file_who   who_type;
     l_file_who   fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_security_rule()';
   init('VSET_SECURITY_RULE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',VSET:'  || p_flex_value_set_name ||
            ',SECR:'  || p_flex_value_rule_name ||
            ',PRNT:'  || p_parent_flex_value_low);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_vst_set(p_flex_value_set_name,
                      l_vst_set)) THEN
         IF (get_vst_scr(l_vst_set,
                         p_flex_value_rule_name,
                         p_parent_flex_value_low,
                         l_vst_scr)) THEN
            NULL;
         END IF;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_vst_scr_tl(l_vst_scr,
                            userenv('LANG'),
                            l_vst_scr_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_vst_scr_tl.last_updated_by,
              p_db_last_update_date          => l_vst_scr_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating VSET_SECURITY_RULE.(MLS)');
         END IF;
         fnd_flex_value_rules_pkg.translate_row
           (x_flex_value_set_name          => p_flex_value_set_name,
            x_parent_flex_value_low        => p_parent_flex_value_low,
            x_flex_value_rule_name         => p_flex_value_rule_name,
            x_who                          => l_file_who,
            x_error_message                => p_error_message,
            x_description                  => p_description);
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_vst_scr.last_updated_by,
              p_db_last_update_date          => l_vst_scr.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         --
         -- Make sure Value Set exists.
         --
         get_vst_set(p_flex_value_set_name, l_vst_set);

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading VSET_SECURITY_RULE.(MLS)');
         END IF;
         fnd_flex_value_rules_pkg.load_row
           (x_flex_value_set_name          => p_flex_value_set_name,
            x_parent_flex_value_low        => p_parent_flex_value_low,
            x_flex_value_rule_name         => p_flex_value_rule_name,
            x_who                          => l_file_who,
            x_parent_flex_value_high       => p_parent_flex_value_high,
            x_error_message                => p_error_message,
            x_description                  => p_description);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('VSET_SECURITY_RULE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_flex_value_rule_name,
                                  p_parent_flex_value_low);
END up_vset_security_rule;

-- --------------------------------------------------
PROCEDURE up_vset_security_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_flex_value_low               IN VARCHAR2,
   p_flex_value_high              IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_vst_scr   vst_scr_type;
     l_vst_scl   vst_scl_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_security_line()';
   init('VSET_SECURITY_LINE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',SECR:'  || p_flex_value_rule_name ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',IE:'    || p_include_exclude_indicator ||
            ',LOW:'   || p_flex_value_low ||
            ',HIGH:'  || p_flex_value_high);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set and Security Rule exist.
   --
   get_vst_set(p_flex_value_set_name,
               l_vst_set);

   get_vst_scr(l_vst_set,
               p_flex_value_rule_name,
               p_parent_flex_value_low,
               l_vst_scr);

   --
   -- Gather WHO Information.
   --
   IF (get_vst_scl(l_vst_set,
                   l_vst_scr,
                   p_include_exclude_indicator,
                   p_flex_value_low,
                   p_flex_value_high,
                   l_vst_scl  )) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_scl.last_updated_by,
        p_db_last_update_date          => l_vst_scl.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VSET_SECURITY_LINE.(no-TL)');
   END IF;
   IF (l_vst_set.validation_type = 'D') THEN
      UPDATE fnd_flex_value_rule_lines SET
        last_updated_by        = l_file_who.last_updated_by,
        last_update_date       = l_file_who.last_update_date,
        last_update_login      = l_file_who.last_update_login,
        parent_flex_value_high = p_parent_flex_value_high
        WHERE flex_value_set_id = l_vst_set.flex_value_set_id
        AND flex_value_rule_id = l_vst_scr.flex_value_rule_id
        AND parent_flex_value_low = p_parent_flex_value_low
        AND include_exclude_indicator = p_include_exclude_indicator
        AND flex_value_low = p_flex_value_low
        AND flex_value_high = p_flex_value_high;
    ELSE
      UPDATE fnd_flex_value_rule_lines SET
        last_updated_by        = l_file_who.last_updated_by,
        last_update_date       = l_file_who.last_update_date,
        last_update_login      = l_file_who.last_update_login,
        parent_flex_value_low  = p_parent_flex_value_low,
        parent_flex_value_high = p_parent_flex_value_high
        WHERE flex_value_set_id = l_vst_set.flex_value_set_id
        AND flex_value_rule_id = l_vst_scr.flex_value_rule_id
        AND include_exclude_indicator = p_include_exclude_indicator
        AND flex_value_low = p_flex_value_low
        AND flex_value_high = p_flex_value_high;
   END IF;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting VSET_SECURITY_LINE.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_value_rule_lines
        (
         flex_value_set_id,
         flex_value_rule_id,
         parent_flex_value_low,
         include_exclude_indicator,
         flex_value_low,
         flex_value_high,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         parent_flex_value_high
         )
        VALUES
        (
         l_vst_set.flex_value_set_id,
         l_vst_scr.flex_value_rule_id,
         p_parent_flex_value_low,
         p_include_exclude_indicator,
         p_flex_value_low,
         p_flex_value_high,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         p_parent_flex_value_high
         );
   END IF;

   <<label_done>>
   done('VSET_SECURITY_LINE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_flex_value_rule_name,
                                  p_parent_flex_value_low,
                                  p_include_exclude_indicator,
                                  p_flex_value_low,
                                  p_flex_value_high);
END up_vset_security_line;

-- --------------------------------------------------
PROCEDURE up_vset_security_usage
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_application_short_name       IN VARCHAR2,
   p_responsibility_key           IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_vst_scr   vst_scr_type;
     l_vst_scu   vst_scu_type;
     l_resp      resp_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_security_usage()';
   init('VSET_SECURITY_USAGE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',SECR:'  || p_flex_value_rule_name ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',APPS:'  || p_application_short_name ||
            ',RESP:'  || p_responsibility_key);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set, Security Rule and Responsibility exist.
   --
   get_vst_set(p_flex_value_set_name,
               l_vst_set);

   get_vst_scr(l_vst_set,
               p_flex_value_rule_name,
               p_parent_flex_value_low,
               l_vst_scr);

   get_resp(p_application_short_name,
            p_responsibility_key,
            l_resp);

   --
   -- Gather WHO Information.
   --
   IF (get_vst_scu(l_vst_set,
                   l_vst_scr,
                   l_resp,
                   l_vst_scu)) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_scu.last_updated_by,
        p_db_last_update_date          => l_vst_scu.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VSET_SECURITY_USAGE.(no-TL)');
   END IF;
   IF (l_vst_set.validation_type = 'D') THEN
      UPDATE fnd_flex_value_rule_usages SET
        last_updated_by        = l_file_who.last_updated_by,
        last_update_date       = l_file_who.last_update_date,
        last_update_login      = l_file_who.last_update_login,
        parent_flex_value_high = p_parent_flex_value_high
        WHERE application_id = l_resp.application_id
        AND responsibility_id = l_resp.responsibility_id
        AND flex_value_set_id = l_vst_set.flex_value_set_id
        AND flex_value_rule_id = l_vst_scr.flex_value_rule_id
        AND parent_flex_value_low = p_parent_flex_value_low;
    ELSE
      UPDATE fnd_flex_value_rule_usages SET
        last_updated_by        = l_file_who.last_updated_by,
        last_update_date       = l_file_who.last_update_date,
        last_update_login      = l_file_who.last_update_login,
        parent_flex_value_low  = p_parent_flex_value_low,
        parent_flex_value_high = p_parent_flex_value_high
        WHERE application_id = l_resp.application_id
        AND responsibility_id = l_resp.responsibility_id
        AND flex_value_set_id = l_vst_set.flex_value_set_id
        AND flex_value_rule_id = l_vst_scr.flex_value_rule_id;
   END IF;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting VSET_SECURITY_USAGE.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_value_rule_usages
        (
         application_id,
         responsibility_id,
         flex_value_set_id,
         flex_value_rule_id,
         parent_flex_value_low,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         parent_flex_value_high
         )
        VALUES
        (
         l_resp.application_id,
         l_resp.responsibility_id,
         l_vst_set.flex_value_set_id,
         l_vst_scr.flex_value_rule_id,
         p_parent_flex_value_low,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         p_parent_flex_value_high
         );
   END IF;

   <<label_done>>
   done('VSET_SECURITY_USAGE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_flex_value_rule_name,
                                  p_parent_flex_value_low,
                                  p_application_short_name,
                                  p_responsibility_key);
END up_vset_security_usage;

-- --------------------------------------------------
PROCEDURE up_vset_rollup_group
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_hierarchy_code               IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_hierarchy_name               IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_vst_set    vst_set_type;
     l_vst_rgr    vst_rgr_type;
     l_vst_rgr_tl vst_rgr_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_rollup_group()';
   init('VSET_ROLLUP_GROUP', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',HIER:'  || p_hierarchy_code);
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_vst_set(p_flex_value_set_name,
                   l_vst_set)) THEN
      IF (get_vst_rgr(l_vst_set,
                      p_hierarchy_code,
                      l_vst_rgr)) THEN
         NULL;
      END IF;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- MLS translation.
      --

      --
      -- Gather WHO Information.
      --
      IF (get_vst_rgr_tl(l_vst_rgr,
                         userenv('LANG'),
                         l_vst_rgr_tl)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_vst_rgr_tl.last_updated_by,
           p_db_last_update_date          => l_vst_rgr_tl.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating VSET_ROLLUP_GROUP.(MLS)');
      END IF;
      fnd_flex_hierarchies_pkg.translate_row
        (x_flex_value_set_name          => p_flex_value_set_name,
         x_hierarchy_code               => p_hierarchy_code,
         x_who                          => l_file_who,
         x_hierarchy_name               => p_hierarchy_name,
         x_description                  => p_description);
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_vst_rgr.last_updated_by,
           p_db_last_update_date          => l_vst_rgr.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      --
      -- Make sure Value Set exists.
      --
      get_vst_set(p_flex_value_set_name, l_vst_set);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Uploading VSET_ROLLUP_GROUP.(MLS)');
      END IF;
      fnd_flex_hierarchies_pkg.load_row
        (x_flex_value_set_name          => p_flex_value_set_name,
         x_hierarchy_code               => p_hierarchy_code,
         x_who                          => l_file_who,
         x_hierarchy_name               => p_hierarchy_name,
         x_description                  => p_description);
   END IF;

   <<label_done>>
   done('VSET_ROLLUP_GROUP', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_hierarchy_code);
END up_vset_rollup_group;

-- --------------------------------------------------
PROCEDURE up_vset_qualifier
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_qualifier()';
   init('VSET_QUALIFIER', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',APPS:'  || p_id_flex_application_short_na ||
            ',KFF:'   || p_id_flex_code ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type ||
            ',ORDER:' || p_assignment_order);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --

   --
   -- Make sure Value Set exists.
   --
   get_vst_set(p_flex_value_set_name, l_vst_set);

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_set.last_updated_by,
        p_db_last_update_date          => l_vst_set.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
         debug(l_func_name, 'For data integrity upload must be done.');
      END IF;
      --
      -- Clear the customization message
      --
      fnd_message.clear();
   END IF;

   --
   -- Populate cross product tables.
   --
   populate_kff_flexq_assign();
   populate_kff_segq_assign();

   <<label_done>>
   done('VSET_QUALIFIER', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_id_flex_application_short_na,
                                  p_id_flex_code,
                                  p_segment_attribute_type,
                                  p_value_attribute_type);
END up_vset_qualifier;

-- --------------------------------------------------
PROCEDURE up_vset_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_summary_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_parent_flex_value_high       IN VARCHAR2,
   p_rollup_hierarchy_code        IN VARCHAR2,
   p_hierarchy_level              IN VARCHAR2,
   p_compiled_value_attributes    IN VARCHAR2,
   p_value_category               IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_attribute16                  IN VARCHAR2,
   p_attribute17                  IN VARCHAR2,
   p_attribute18                  IN VARCHAR2,
   p_attribute19                  IN VARCHAR2,
   p_attribute20                  IN VARCHAR2,
   p_attribute21                  IN VARCHAR2,
   p_attribute22                  IN VARCHAR2,
   p_attribute23                  IN VARCHAR2,
   p_attribute24                  IN VARCHAR2,
   p_attribute25                  IN VARCHAR2,
   p_attribute26                  IN VARCHAR2,
   p_attribute27                  IN VARCHAR2,
   p_attribute28                  IN VARCHAR2,
   p_attribute29                  IN VARCHAR2,
   p_attribute30                  IN VARCHAR2,
   p_attribute31                  IN VARCHAR2,
   p_attribute32                  IN VARCHAR2,
   p_attribute33                  IN VARCHAR2,
   p_attribute34                  IN VARCHAR2,
   p_attribute35                  IN VARCHAR2,
   p_attribute36                  IN VARCHAR2,
   p_attribute37                  IN VARCHAR2,
   p_attribute38                  IN VARCHAR2,
   p_attribute39                  IN VARCHAR2,
   p_attribute40                  IN VARCHAR2,
   p_attribute41                  IN VARCHAR2,
   p_attribute42                  IN VARCHAR2,
   p_attribute43                  IN VARCHAR2,
   p_attribute44                  IN VARCHAR2,
   p_attribute45                  IN VARCHAR2,
   p_attribute46                  IN VARCHAR2,
   p_attribute47                  IN VARCHAR2,
   p_attribute48                  IN VARCHAR2,
   p_attribute49                  IN VARCHAR2,
   p_attribute50                  IN VARCHAR2,
   p_attribute_sort_order         IN VARCHAR2 DEFAULT NULL,
   p_flex_value_meaning           IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_vst_set    vst_set_type;
     l_vst_rgr    vst_rgr_type;
     l_vst_val    vst_val_type;
     l_vst_val_tl vst_val_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_flex_value_meaning fnd_flex_values_tl.flex_value_meaning%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_vset_value()';
   init('VSET_VALUE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',VSET:'  || p_flex_value_set_name ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',VAL:'   || p_flex_value);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Make sure Value Set exists.
      --
      get_vst_set(p_flex_value_set_name, l_vst_set);

      --
      -- Gather WHO Information.
      --
      IF (get_vst_val(l_vst_set,
                      p_parent_flex_value_low,
                      p_flex_value,
                      l_vst_val)) THEN
         NULL;
      END IF;

      IF (l_vst_set.validation_type IN ('D', 'Y') AND
          p_parent_flex_value_low IS NULL) THEN
         raise_error(l_func_name, ERROR_VST_INVALID_PARENT,
                     'NULL is not a valid parent value');
      END IF;

      l_flex_value_meaning := Nvl(p_flex_value_meaning, p_flex_value);

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_vst_val_tl(l_vst_val,
                            userenv('LANG'),
                            l_vst_val_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_vst_val_tl.last_updated_by,
              p_db_last_update_date          => l_vst_val_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating VSET_VALUE.(MLS)');
         END IF;
         fnd_flex_values_pkg.translate_row
           (x_flex_value_set_name          => p_flex_value_set_name,
            x_parent_flex_value_low        => p_parent_flex_value_low,
            x_flex_value                   => p_flex_value,
            x_who                          => l_file_who,
            x_flex_value_meaning           => l_flex_value_meaning,
            x_description                  => p_description);
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_vst_val.last_updated_by,
              p_db_last_update_date          => l_vst_val.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         l_vst_rgr.hierarchy_id := NULL;
         IF (p_rollup_hierarchy_code IS NOT NULL) THEN
            --
            -- Make sure Rollup Group exists.
            --
            get_vst_rgr(l_vst_set, p_rollup_hierarchy_code, l_vst_rgr);
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading VSET_VALUE.(MLS)');
         END IF;
         fnd_flex_values_pkg.load_row
           (x_flex_value_set_name          => p_flex_value_set_name,
            x_parent_flex_value_low        => p_parent_flex_value_low,
            x_flex_value                   => p_flex_value,
            x_who                          => l_file_who,
            x_enabled_flag                 => p_enabled_flag,
            x_summary_flag                 => p_summary_flag,
            x_start_date_active            => To_date(p_start_date_active,
                                                      g_date_mask),
            x_end_date_active              => To_date(p_end_date_active,
                                                      g_date_mask),
            x_parent_flex_value_high       => p_parent_flex_value_high,
            x_structured_hierarchy_level   => l_vst_rgr.hierarchy_id,
            x_hierarchy_level              => p_hierarchy_level,
            x_compiled_value_attributes    => p_compiled_value_attributes,
            x_value_category               => p_value_category,
            x_attribute1                   => p_attribute1,
            x_attribute2                   => p_attribute2,
            x_attribute3                   => p_attribute3,
           x_attribute4                   => p_attribute4,
           x_attribute5                   => p_attribute5,
           x_attribute6                   => p_attribute6,
           x_attribute7                   => p_attribute7,
           x_attribute8                   => p_attribute8,
           x_attribute9                   => p_attribute9,
           x_attribute10                  => p_attribute10,
           x_attribute11                  => p_attribute11,
           x_attribute12                  => p_attribute12,
           x_attribute13                  => p_attribute13,
           x_attribute14                  => p_attribute14,
           x_attribute15                  => p_attribute15,
           x_attribute16                  => p_attribute16,
           x_attribute17                  => p_attribute17,
           x_attribute18                  => p_attribute18,
           x_attribute19                  => p_attribute19,
           x_attribute20                  => p_attribute20,
           x_attribute21                  => p_attribute21,
           x_attribute22                  => p_attribute22,
           x_attribute23                  => p_attribute23,
           x_attribute24                  => p_attribute24,
           x_attribute25                  => p_attribute25,
           x_attribute26                  => p_attribute26,
           x_attribute27                  => p_attribute27,
           x_attribute28                  => p_attribute28,
           x_attribute29                  => p_attribute29,
           x_attribute30                  => p_attribute30,
           x_attribute31                  => p_attribute31,
           x_attribute32                  => p_attribute32,
           x_attribute33                  => p_attribute33,
           x_attribute34                  => p_attribute34,
           x_attribute35                  => p_attribute35,
           x_attribute36                  => p_attribute36,
           x_attribute37                  => p_attribute37,
           x_attribute38                  => p_attribute38,
           x_attribute39                  => p_attribute39,
           x_attribute40                  => p_attribute40,
           x_attribute41                  => p_attribute41,
           x_attribute42                  => p_attribute42,
           x_attribute43                  => p_attribute43,
           x_attribute44                  => p_attribute44,
           x_attribute45                  => p_attribute45,
           x_attribute46                  => p_attribute46,
           x_attribute47                  => p_attribute47,
           x_attribute48                  => p_attribute48,
           x_attribute49                  => p_attribute49,
           x_attribute50                  => p_attribute50,
           x_attribute_sort_order         => p_attribute_sort_order,
           x_flex_value_meaning           => l_flex_value_meaning,
           x_description                  => p_description);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('VSET_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_parent_flex_value_low,
                                  p_flex_value);
END up_vset_value;

-- --------------------------------------------------
PROCEDURE up_vset_value_hierarchy
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value            IN VARCHAR2,
   p_range_attribute              IN VARCHAR2,
   p_child_flex_value_low         IN VARCHAR2,
   p_child_flex_value_high        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_vst_val   vst_val_type;
     l_vst_vlh   vst_vlh_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_vset_value_hierarchy()';
   init('VSET_VALUE_HIERARCHY', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',PRNT:'  || p_parent_flex_value ||
            ',RANGE:' || p_range_attribute ||
            ',LOW:'   || p_child_flex_value_low ||
            ',HIGH:'  || p_child_flex_value_high);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure Value Set and Value exist.
   --
   get_vst_set(p_flex_value_set_name,
               l_vst_set);

   IF (l_vst_set.validation_type IN ('D', 'X', 'Y', 'U', 'P', 'F', 'N')) THEN
      raise_error(l_func_name, ERROR_VST_INVALID_CH_RNG,
                  'Child ranges cannot be defined for D, X, Y, U, P, F, N vsets');
   END IF;

   get_vst_val(l_vst_set,
               NULL,
               p_parent_flex_value,
               l_vst_val);

   --
   -- Gather WHO Information.
   --
   IF (NOT get_vst_vlh(l_vst_val,
                       p_range_attribute,
                       p_child_flex_value_low,
                       p_child_flex_value_high,
                       l_vst_vlh)) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_vst_vlh.last_updated_by,
        p_db_last_update_date          => l_vst_vlh.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --
   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating VSET_VALUE_HIERARCHY.(no-TL)');
   END IF;
   UPDATE fnd_flex_value_norm_hierarchy SET
     last_updated_by   = l_file_who.last_updated_by,
     last_update_date  = l_file_who.last_update_date,
     last_update_login = l_file_who.last_update_login,
     start_date_active = To_date(p_start_date_active, g_date_mask),
     end_date_active   = To_date(p_end_date_active, g_date_mask)
     WHERE flex_value_set_id = l_vst_set.flex_value_set_id
     AND parent_flex_value = l_vst_val.flex_value
     AND range_attribute = p_range_attribute
     AND child_flex_value_low = p_child_flex_value_low
     AND child_flex_value_high = p_child_flex_value_high;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting VSET_VALUE_HIERARCHY.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_value_norm_hierarchy
        (
         flex_value_set_id,
         parent_flex_value,
         range_attribute,
         child_flex_value_low,
         child_flex_value_high,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         start_date_active,
         end_date_active
         )
        VALUES
        (
         l_vst_set.flex_value_set_id,
         l_vst_val.flex_value,
         p_range_attribute,
         p_child_flex_value_low,
         p_child_flex_value_high,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         To_date(p_start_date_active, g_date_mask),
         To_date(p_end_date_active, g_date_mask)
         );
   END IF;

   <<label_done>>
   done('VSET_VALUE_HIERARCHY', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_parent_flex_value,
                                  p_range_attribute,
                                  p_child_flex_value_low,
                                  p_child_flex_value_high);
END up_vset_value_hierarchy;

-- --------------------------------------------------
PROCEDURE up_vset_value_qual_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_compiled_value_attribute_val IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_vset_value_qual_value()';
   init('VSET_VALUE_QUAL_VALUE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',VSET:'  || p_flex_value_set_name ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',VAL:'   || p_flex_value ||
            ',APPS:'  || p_id_flex_application_short_na ||
            ',KFF:'   || p_id_flex_code ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type ||
            ',CVAL:'  || p_compiled_value_attribute_val);
   END IF;

   upload_value_qualifier_value
     (p_caller_entity                => 'VSET_VALUE_QUAL_VALUE',
      p_upload_phase                 => p_upload_phase,
      p_upload_mode                  => p_upload_mode,
      p_custom_mode                  => p_custom_mode,
      p_flex_value_set_name          => p_flex_value_set_name,
      p_application_short_name       => p_id_flex_application_short_na,
      p_id_flex_code                 => p_id_flex_code,
      p_segment_attribute_type       => p_segment_attribute_type,
      p_value_attribute_type         => p_value_attribute_type,
      p_parent_flex_value_low        => p_parent_flex_value_low,
      p_flex_value                   => p_flex_value,
      p_owner                        => p_owner,
      p_last_update_date             => p_last_update_date,
      p_compiled_value_attribute_val => p_compiled_value_attribute_val);

   <<label_done>>
   done('VSET_VALUE_QUAL_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_flex_value_set_name,
                                  p_parent_flex_value_low,
                                  p_flex_value,
                                  p_id_flex_application_short_na,
                                  p_id_flex_code,
                                  p_segment_attribute_type,
                                  p_value_attribute_type);
END up_vset_value_qual_value;

-- ==================================================
--  DESC_FLEX
-- ==================================================
FUNCTION get_srs_loader_flex_name
  RETURN VARCHAR2
  IS
     l_func_name VARCHAR2(80);
     l_return    VARCHAR2(40);
     l_counter   NUMBER;
BEGIN
   l_func_name := g_api_name || 'get_srs_loader_flex_name()';
   l_counter := 0;
   WHILE (l_counter < 1000) LOOP
      BEGIN
         SELECT '$SRS$.$FLEX$.$LOADER$.' || hash_value
           INTO l_return
           FROM fnd_flex_hash
           WHERE hash_value = l_counter
           FOR UPDATE NOWAIT;
         EXIT;
      EXCEPTION
         WHEN OTHERS THEN
            l_counter := l_counter + 1;
      END;
   END LOOP;

   IF (l_counter = 1000) THEN
      raise_error(l_func_name, ERROR_DFF_NO_SRS_LOCK,
                  'Unable to lock a row for SRS handling',
                  'Please re-run FNDLOAD');
   END IF;

   RETURN l_return;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name);
END get_srs_loader_flex_name;

-- --------------------------------------------------
PROCEDURE delete_srs_desc_flex(p_application_short_name     IN VARCHAR2,
                               p_descriptive_flexfield_name IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_app app_type;
BEGIN
   l_func_name := g_api_name || 'delete_srs_desc_flex()';

   get_app(p_application_short_name, l_app);

   DELETE
     FROM fnd_descriptive_flexs
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

   DELETE
     FROM fnd_descriptive_flexs_tl
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

   DELETE
     FROM fnd_descr_flex_contexts
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

   DELETE
     FROM fnd_descr_flex_contexts_tl
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

   DELETE
     FROM fnd_descr_flex_column_usages
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

   DELETE
     FROM fnd_descr_flex_col_usage_tl
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = p_descriptive_flexfield_name;

EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_descriptive_flexfield_name);
END delete_srs_desc_flex;

-- --------------------------------------------------
PROCEDURE rename_srs_loader_flex(p_application_short_name     IN VARCHAR2,
                                 p_descriptive_flexfield_name IN VARCHAR2,
                                 p_title                      IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_app app_type;
BEGIN
   l_func_name := g_api_name || 'rename_srs_loader_flex()';

   get_app(p_application_short_name, l_app);

   UPDATE fnd_descriptive_flexs
     SET descriptive_flexfield_name = p_descriptive_flexfield_name
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

   UPDATE fnd_descriptive_flexs_tl
     SET descriptive_flexfield_name = p_descriptive_flexfield_name,
         title = p_title
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

   UPDATE fnd_descr_flex_contexts
     SET descriptive_flexfield_name = p_descriptive_flexfield_name
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

   UPDATE fnd_descr_flex_contexts_tl
     SET descriptive_flexfield_name = p_descriptive_flexfield_name
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

   UPDATE fnd_descr_flex_column_usages
     SET descriptive_flexfield_name = p_descriptive_flexfield_name
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

   UPDATE fnd_descr_flex_col_usage_tl
     SET descriptive_flexfield_name = p_descriptive_flexfield_name
     WHERE application_id = l_app.application_id
     AND descriptive_flexfield_name = g_srs_loader_flex_name;

EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_descriptive_flexfield_name,
                        p_title);
END rename_srs_loader_flex;

-- --------------------------------------------------
-- Upload logic for SRS:
--
-- Owners are grouped into 2 categories:
--    SEED   : LAST_UPDATED_BY <= g_lub_seed_boundary
--    CUSTOM : LAST_UPDATED_BY >  g_lub_seed_boundary
--
-- Overall SRS data is grouped into 3 categories:
--    ALL_SEED   :  All LUBs <= g_lub_seed_boundary
--    SOME_SEED  : Some LUBs <= g_lub_seed_boundary < Some LUBs
--    ALL_CUSTOM :  All LUBs >  g_lub_seed_boundary
--
-- Then following logic is applied:
--
-- LDT         DB          Result
-- ----------  ----------  -------------------------------------
-- ALL_SEED    ALL_SEED    Decide using max SEED LUBs and LUDs
-- ALL_SEED    SOME_SEED   Decide using max SEED LUBs and LUDs
-- SOME_SEED   ALL_SEED    Decide using max SEED LUBs and LUDs
-- SOME_SEED   SOME_SEED   Decide using max SEED LUBs and LUDs
--
-- ALL_SEED    ALL_CUSTOM  Upload
-- SOME_SEED   ALL_CUSTOM  Upload
--
-- ALL_CUSTOM  ALL_SEED    Ignore
-- ALL_CUSTOM  SOME_SEED   Ignore
--
-- ALL_CUSTOM  ALL_CUSTOM  Decide using max CUSTOM LUBs and LUDs
--
-- --------------------------------------------------
PROCEDURE upload_srs_desc_flex
  (p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_title                        IN VARCHAR2)
  IS
     l_func_name          VARCHAR2(80);

     i                    NUMBER;
     l_boolean            BOOLEAN;
     l_is_upload_allowed  BOOLEAN;

     l_header1            VARCHAR2(200);
     l_header2            VARCHAR2(200);

     l_ldt_dff_seg_arr    dff_seg_arr_type;
     l_ldt_dff_seg_count  NUMBER;

     l_ldt_data_status    VARCHAR2(30);
     l_ldt_max_seed_lub   NUMBER;
     l_ldt_max_seed_lud   DATE;
     l_ldt_max_custom_lub NUMBER;
     l_ldt_max_custom_lud DATE;

     l_db_dff_seg_arr     dff_seg_arr_type;
     l_db_dff_seg_count   NUMBER;

     l_db_data_status     VARCHAR2(30);
     l_db_max_seed_lub    NUMBER;
     l_db_max_seed_lud    DATE;
     l_db_max_custom_lub  NUMBER;
     l_db_max_custom_lud  DATE;

     PROCEDURE compute_max_lub_and_max_lud
       (px_max_seed_lub    IN OUT nocopy NUMBER,
        px_max_seed_lud    IN OUT nocopy DATE,
        px_max_custom_lub  IN OUT nocopy NUMBER,
        px_max_custom_lud  IN OUT nocopy DATE,
        p_lub              IN NUMBER,
        p_lud              IN DATE,
        p_debug            IN VARCHAR2)
       IS
          l_debug VARCHAR2(2000);
     BEGIN
        l_debug := Rpad(p_debug, 40);
        --
        -- Compute the max SEED/CUSTOM LUB/LUD.
        --
        IF (p_lub <= g_lub_seed_boundary) THEN
           --
           -- This is assumed to be SEED data.
           --
           l_debug := l_debug || ' S:';
           IF (p_lub > px_max_seed_lub) THEN
              px_max_seed_lub := p_lub;
              l_debug := l_debug || '+';
            ELSIF (p_lub = px_max_seed_lub) THEN
              l_debug := l_debug || '=';
            ELSE
              l_debug := l_debug || '-';
           END IF;

           IF (p_lud > px_max_seed_lud) THEN
              px_max_seed_lud := p_lud;
              l_debug := l_debug || '+';
            ELSIF (p_lud = px_max_seed_lud) THEN
              l_debug := l_debug || '=';
            ELSE
              l_debug := l_debug || '-';
           END IF;

         ELSE
           --
           -- This is assumed to be CUSTOM data.
           --
           l_debug := l_debug || ' C:';
           IF (p_lub > px_max_custom_lub) THEN
              px_max_custom_lub := p_lub;
              l_debug := l_debug || '+';
            ELSIF (p_lub = px_max_custom_lub) THEN
              l_debug := l_debug || '=';
            ELSE
              l_debug := l_debug || '-';
           END IF;

           IF (p_lud > px_max_custom_lud) THEN
              px_max_custom_lud := p_lud;
              l_debug := l_debug || '+';
            ELSIF (p_lud = px_max_custom_lud) THEN
              l_debug := l_debug || '=';
            ELSE
              l_debug := l_debug || '-';
           END IF;

        END IF;

        IF (g_debug_on) THEN
           debug(l_debug || ' ' ||
                 Rpad(p_lub || '/' || fnd_load_util.owner_name(p_lub),
                      15) || ' ' ||
                 To_char(p_lud, g_date_mask));
        END IF;

     END compute_max_lub_and_max_lud;

     PROCEDURE compute_max_who
       (p_application_short_name       IN VARCHAR2,
        p_descriptive_flexfield_name   IN VARCHAR2,
        px_data_status                 IN OUT nocopy VARCHAR2,
        px_max_seed_lub                IN OUT nocopy NUMBER,
        px_max_seed_lud                IN OUT nocopy DATE,
        px_max_custom_lub              IN OUT nocopy NUMBER,
        px_max_custom_lud              IN OUT nocopy DATE,
        px_dff_seg_arr                 IN OUT nocopy dff_seg_arr_type,
        px_dff_seg_count               IN OUT nocopy NUMBER)
       IS
          CURSOR l_dff_seg_cursor(p_application_id               IN NUMBER,
                                  p_descriptive_flexfield_name   IN VARCHAR2,
                                  p_descriptive_flex_context_cod IN VARCHAR2)
            IS
               SELECT *
                 FROM fnd_descr_flex_column_usages
                 WHERE application_id = p_application_id
                 AND descriptive_flexfield_name = p_descriptive_flexfield_name
                 AND descriptive_flex_context_code = p_descriptive_flex_context_cod
                 ORDER BY application_column_name;

          l_dff_flx        dff_flx_type;
          l_dff_ctx        dff_ctx_type;
     BEGIN
        px_data_status    := 'NOT_COMPUTED';
        px_max_seed_lub   := g_unset_lub;
        px_max_seed_lud   := g_unset_lud;
        px_max_custom_lub := g_unset_lub;
        px_max_custom_lud := g_unset_lud;

        --
        -- Get SRS Desc Flex.
        --
        IF (NOT get_dff_flx(p_application_short_name,
                            p_descriptive_flexfield_name,
                            l_dff_flx)) THEN
           --
           -- SRS Desc Flex doesn't exist.
           --
           IF (g_debug_on) THEN
              debug(l_func_name,
                    'SRS: Desc Flex does not exist.',
                    'APPLICATION_SHORT_NAME=' || p_application_short_name,
                    'DESCRIPTIVE_FLEXFIELD_NAME=' || p_descriptive_flexfield_name);
           END IF;
           px_data_status := 'DOES_NOT_EXIST';
           GOTO label_done;
        END IF;

        compute_max_lub_and_max_lud
          (px_max_seed_lub,
           px_max_seed_lud,
           px_max_custom_lub,
           px_max_custom_lud,
           l_dff_flx.last_updated_by,
           l_dff_flx.last_update_date,
           l_dff_flx.descriptive_flexfield_name);

        --
        -- Get the SRS Desc Flex Global Data Elements Context.
        --
        IF (NOT get_dff_ctx(l_dff_flx,
                            'Global Data Elements',
                            l_dff_ctx)) THEN
           --
           -- SRS Desc Flex Global Data Elements doesn't exist.
           --
           IF (g_debug_on) THEN
              debug(l_func_name,
                    'SRS: Desc Flex Global Ctx does not exist.',
                    'APPLICATION_SHORT_NAME=' || p_application_short_name,
                    'DESCRIPTIVE_FLEXFIELD_NAME=' || p_descriptive_flexfield_name);
           END IF;
           px_data_status := 'DOES_NOT_EXIST';
           GOTO label_done;
        END IF;

        compute_max_lub_and_max_lud
          (px_max_seed_lub,
           px_max_seed_lud,
           px_max_custom_lub,
           px_max_custom_lud,
           l_dff_ctx.last_updated_by,
           l_dff_ctx.last_update_date,
           '  ' || l_dff_ctx.descriptive_flex_context_code);

        --
        -- Get the SRS Parameters.
        --
        i := 0;
        FOR l_dff_seg_cursor_rec IN l_dff_seg_cursor(l_dff_flx.application_id,
                                                     l_dff_flx.descriptive_flexfield_name,
                                                     l_dff_ctx.descriptive_flex_context_code) LOOP
           i := i + 1;
           px_dff_seg_arr(i) := l_dff_seg_cursor_rec;

           compute_max_lub_and_max_lud
             (px_max_seed_lub,
              px_max_seed_lud,
              px_max_custom_lub,
              px_max_custom_lud,
              px_dff_seg_arr(i).last_updated_by,
              px_dff_seg_arr(i).last_update_date,
              '    ' || px_dff_seg_arr(i).application_column_name ||
              '.' || px_dff_seg_arr(i).end_user_column_name);
        END LOOP;
        px_dff_seg_count := i;

        --
        -- Compute the final status of data
        --
        IF (px_max_custom_lub = g_unset_lub) THEN
           px_data_status := 'ALL_SEED';

         ELSIF (px_max_seed_lub = g_unset_lub) THEN
           px_data_status := 'ALL_CUSTOM';

         ELSE
           px_data_status := 'SOME_SEED';

        END IF;

        IF (g_debug_on) THEN
           debug(l_header2);
           debug('Max LUB and max LUD                   SEED:   ' ||
                 Rpad(px_max_seed_lub || '/' ||
                      fnd_load_util.owner_name(px_max_seed_lub),
                      15) || ' ' ||
                 To_char(px_max_seed_lud, g_date_mask));
           debug('                                    CUSTOM:   ' ||
                 Rpad(px_max_custom_lub || '/' ||
                      fnd_load_util.owner_name(px_max_custom_lub),
                      15) || ' ' ||
                 To_char(px_max_custom_lud, g_date_mask));
           debug('                              Final Status:   ' ||
                 px_data_status);

           debug(' ');
        END IF;

        <<label_done>>
          NULL;
     END compute_max_who;

BEGIN
   l_func_name := g_api_name || 'upload_srs_desc_flex()';

   init('SRS_DESC_FLEX', 'LEAF');
   IF (g_debug_on) THEN
      debug(l_func_name,
            'CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || p_descriptive_flexfield_name);

      l_header1 := Rpad('Entity', 41) || Rpad('Owner', 21) || 'Last Update Date';
      l_header2 := Rpad('-', 40, '-') || ' ' || Rpad('-', 20, '-') || ' ' || Rpad('-', 19, '-');
      debug(l_header1);
      debug(l_header2);
   END IF;

   --
   -- Compute Max WHO and Status for LDT data
   --
   compute_max_who(p_application_short_name,
                   g_srs_loader_flex_name,
                   l_ldt_data_status,
                   l_ldt_max_seed_lub,
                   l_ldt_max_seed_lud,
                   l_ldt_max_custom_lub,
                   l_ldt_max_custom_lud,
                   l_ldt_dff_seg_arr,
                   l_ldt_dff_seg_count);

   IF (l_ldt_data_status = 'DOES_NOT_EXIST') THEN
      --
      -- This should not happen.
      --
      raise_error(l_func_name, ERROR_DFF_NO_LDT_DATA,
                  'LDT SRS data does not exist',
                  'Please file a bug against 510/FLEXFIELDS');
   END IF;

   IF (g_debug_on) THEN
      debug(l_header1);
      debug(l_header2);
   END IF;

   --
   -- Compute Max WHO and Status for DB data
   --
   compute_max_who(p_application_short_name,
                   p_descriptive_flexfield_name,
                   l_db_data_status,
                   l_db_max_seed_lub,
                   l_db_max_seed_lud,
                   l_db_max_custom_lub,
                   l_db_max_custom_lud,
                   l_db_dff_seg_arr,
                   l_db_dff_seg_count);

   IF (l_db_data_status = 'DOES_NOT_EXIST') THEN
      --
      -- This can happen. This is the first time an SRS definition is uploaded.
      --
      GOTO label_insert_ldt;
   END IF;

   --
   -- Now we have LDT and DB data.
   -- It is time to do version checking.
   --

   --
   -- Following IF is added for future use.
   -- It simply is GOTO label_usual_upload;
   --
   IF (l_db_dff_seg_count = l_ldt_dff_seg_count) THEN
      --
      -- Both have same number of parameters.
      --
      --
      -- Let's see if the order and the names are same.
      --
      l_boolean := TRUE;
      FOR i IN 1..l_db_dff_seg_count LOOP
         IF ((l_db_dff_seg_arr(i).application_column_name =
              l_ldt_dff_seg_arr(i).application_column_name) AND
             (l_db_dff_seg_arr(i).end_user_column_name =
              l_ldt_dff_seg_arr(i).end_user_column_name) AND
             (l_db_dff_seg_arr(i).column_seq_num =
              l_ldt_dff_seg_arr(i).column_seq_num)) THEN
            NULL;
          ELSE
            l_boolean := FALSE;
            EXIT;
         END IF;
      END LOOP;

      IF (l_boolean) THEN
         --
         -- Everything matched, structures are same.
         --
         GOTO label_usual_upload;
       ELSE
         --
         -- There is change in the structure.
         --
         GOTO label_usual_upload;
      END IF;
    ELSE
      --
      -- Different number of parameters.
      --
      GOTO label_usual_upload;
   END IF;

   <<label_usual_upload>>
     BEGIN
        l_is_upload_allowed := FALSE;

        IF (l_ldt_data_status IN ('ALL_SEED', 'SOME_SEED')) THEN
           --
           -- LDT has SEED data.
           --
           IF (l_db_data_status IN ('ALL_SEED', 'SOME_SEED')) THEN
              --
              -- DB has SEED data.
              --
              l_is_upload_allowed := fnd_load_util.upload_test
                (p_file_id     => l_ldt_max_seed_lub,
                 p_file_lud    => l_ldt_max_seed_lud,
                 p_db_id       => l_db_max_seed_lub,
                 p_db_lud      => l_db_max_seed_lud,
                 p_custom_mode => p_custom_mode);
            ELSIF (l_db_data_status IN ('ALL_CUSTOM')) THEN
              --
              -- DB is ALL_CUSTOM.
              -- SRS customizations are not supported.
              -- Overwrite the customizations.
              --
              -- This branch is very unlikely.
              --
              l_is_upload_allowed := TRUE;
           END IF;

         ELSIF (l_ldt_data_status IN ('ALL_CUSTOM')) THEN
           --
           -- LDT is ALL_CUSTOM.
           --
           IF (l_db_data_status IN ('ALL_SEED', 'SOME_SEED')) THEN
              --
              -- DB has SEED data...
              -- SRS customizations are not supported.
              -- Preserve the seed data.
              --
              -- This branch is very unlikely.
              --
              l_is_upload_allowed := FALSE;

            ELSIF (l_db_data_status IN ('ALL_CUSTOM')) THEN
              --
              -- DB is ALL_CUSTOM.
              -- Customer might be moving CUSTOM SRS from one db to another.
              --
              l_is_upload_allowed := fnd_load_util.upload_test
                (p_file_id     => l_ldt_max_custom_lub,
                 p_file_lud    => l_ldt_max_custom_lud,
                 p_db_id       => l_db_max_custom_lub,
                 p_db_lud      => l_db_max_custom_lud,
                 p_custom_mode => p_custom_mode);
           END IF;
        END IF;

        IF (l_is_upload_allowed) THEN
           IF (g_debug_on) THEN
              debug(l_func_name, 'SRS: Upload is allowed.');
           END IF;
           GOTO label_insert_ldt;
         ELSE
           IF (g_debug_on) THEN
              debug(l_func_name, 'SRS: Upload is not allowed.');
           END IF;
           GOTO label_done;
        END IF;
     END;

     <<label_insert_ldt>>
     BEGIN
        --
        -- Delete the existing DB SRS Desc Flex.
        --
        delete_srs_desc_flex(p_application_short_name,
                             p_descriptive_flexfield_name);

        --
        -- Rename the LDT SRS Desc Flex.
        --
        rename_srs_loader_flex(p_application_short_name,
                               p_descriptive_flexfield_name,
                               p_title);

        --
        -- 1 Flex, 1 Global Data Elements, Parameters
        --
        g_numof_changes := g_numof_changes + 1 + 1 + l_ldt_dff_seg_count;

        GOTO label_done;
     END;

   <<label_done>>
     BEGIN
        --
        -- We are done with LDT SRS Desc Flex.
        --
        delete_srs_desc_flex(p_application_short_name,
                             g_srs_loader_flex_name);
     END;
   done('SRS_DESC_FLEX', 'LEAF');
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_application_short_name,
                        p_descriptive_flexfield_name,
                        p_title);
END upload_srs_desc_flex;

-- --------------------------------------------------
PROCEDURE up_desc_flex
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_context_column_name          IN VARCHAR2,
   p_context_required_flag        IN VARCHAR2,
   p_context_user_override_flag   IN VARCHAR2,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_default_context_value        IN VARCHAR2,
   p_context_default_type         IN VARCHAR2 DEFAULT NULL,
   p_context_default_value        IN VARCHAR2 DEFAULT NULL,
   p_context_override_value_set_n IN VARCHAR2 DEFAULT NULL,
   p_context_runtime_property_fun IN VARCHAR2 DEFAULT NULL,
   p_context_synchronization_flag IN VARCHAR2 DEFAULT NULL,
   p_title                        IN VARCHAR2,
   p_form_context_prompt          IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_tbl        tbl_type;
     l_dff_flx    dff_flx_type;
     l_dff_flx_tl dff_flx_tl_type;
     l_dff_ctx    dff_ctx_type;
     l_vst_set    vst_set_type;
     l_app        app_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_descriptive_flexfield_name  fnd_descriptive_flexs_vl.descriptive_flexfield_name%TYPE;
     l_title                       fnd_descriptive_flexs_vl.title%TYPE;
     l_concatenated_segs_view_name fnd_descriptive_flexs_vl.concatenated_segs_view_name%TYPE;
     l_context_synchronization_flag fnd_descriptive_flexs.context_synchronization_flag%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_desc_flex()';
   l_descriptive_flexfield_name := p_descriptive_flexfield_name;
   l_title := p_title;

   init('DESC_FLEX', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || l_descriptive_flexfield_name);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      start_transaction(ENTITY_DESC_FLEX);
      lock_entity('DESC_FLEX',
                  p_application_short_name,
                  p_descriptive_flexfield_name);

      g_numof_changes := 0;
      --
      -- Gather WHO Information.
      --
      IF (get_dff_flx(p_application_short_name,
                      l_descriptive_flexfield_name,
                      l_dff_flx)) THEN
         NULL;
      END IF;

      -- Bug 13885279, this NLS code is no longer need as it has been moved
      -- to up_desc_flex_nls() and called from afffload.lct. We are leaving
      -- this code here for backward compatibility. If old vrsn of lct file 
      -- is used, it will not cause bug 13885279. Also other code may call
      -- up_desc_flex like afcpprog.lct which have not been modified to call
      -- up_desc_flex_nls().
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_dff_flx_tl(l_dff_flx,
                            userenv('LANG'),
                            l_dff_flx_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_dff_flx_tl.last_updated_by,
              p_db_last_update_date          => l_dff_flx_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating DESC_FLEX.(MLS)');
         END IF;
         fnd_descriptive_flexs_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
            x_who                          => l_file_who,
            x_title                        => l_title,
            x_form_context_prompt          => p_form_context_prompt,
            x_description                  => p_description);
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_dff_flx.last_updated_by,
              p_db_last_update_date          => l_dff_flx.last_update_date,
              x_file_who                     => l_file_who)) THEN

            --
            -- SRS DFFs are handled in upload_srs_desc_flex().
            --
            IF (l_descriptive_flexfield_name NOT LIKE '$SRS$.%')  THEN
               IF (g_debug_on) THEN
                  debug(l_func_name, 'Upload is not allowed because of customization.');
               END IF;
               GOTO label_done;
            else
               --
               -- Clear the customization message
               --
               fnd_message.clear();
            END IF;
         END IF;

         IF (l_descriptive_flexfield_name LIKE '$SRS$.%')  THEN
            --
            -- Come up with a unique LDT SRS Desc Flex Name.
            --
            g_srs_loader_flex_name := get_srs_loader_flex_name();

            --
            -- Delete the old LDT SRS Desc Flex.
            --
            delete_srs_desc_flex(p_application_short_name,
                                 g_srs_loader_flex_name);

            --
            -- LDT SRS Desc Flex.
            --
            l_descriptive_flexfield_name := g_srs_loader_flex_name;
            l_title := g_srs_loader_flex_name;
            IF (g_debug_on) THEN
               debug(l_func_name, 'SRS: Switched name to ' || l_descriptive_flexfield_name);
            END IF;
         END IF;

         --
         -- Make sure Table exists.
         --
         get_tbl(p_table_application_short_name,
                 p_application_table_name,
                 l_tbl);

         --
         -- Make sure Context Override Value Set exists.
         --
         IF (p_context_override_value_set_n IS NOT NULL) THEN
            get_vst_set(p_context_override_value_set_n, l_vst_set);
         END IF;

         --
         -- Check protected flag
         --
         IF (p_descriptive_flexfield_name LIKE '$SRS$.%') THEN
            IF (p_protected_flag <> 'S') THEN
               raise_error(l_func_name, ERROR_DFF_INV_PROT_FLG,
                           'PROTECTED_FLAG (' || p_protected_flag || ') must be S for SRS DFFs',
                           'Please fix this problem in source DB and re-download the ldt file');
            END IF;
          ELSE
            IF (p_protected_flag NOT IN ('Y', 'N')) THEN
               raise_error(l_func_name, ERROR_DFF_INV_PROT_FLG,
                           'PROTECTED_FLAG (' || p_protected_flag || ') must be either Y (developer DFF) or N (customer DFF)',
                           'Please fix this problem in source DB and re-download the ldt file');
            END IF;
         END IF;

         --
         -- Intentional/Unintentional NULL handling.
         --
         IF (p_concatenated_segs_view_name IS NULL) THEN
            l_concatenated_segs_view_name := l_dff_flx.concatenated_segs_view_name;
          ELSIF (p_concatenated_segs_view_name = g_null_value) THEN
            l_concatenated_segs_view_name := NULL;
          ELSE
            l_concatenated_segs_view_name := p_concatenated_segs_view_name;
         END IF;

         --
         -- Default value for context synchronization flag
         -- for backward compatibility
         --
         -- If parameter is not 'Y' / 'N'
         --   try db value first,
         --   if db value is also not 'Y' / 'N' then
         --     for conc program, sync flag is  'N'
         --     else
         --       if reference field has a value AND display flag is off then
         --         sync flag is 'Y'
         --       else sync flag is 'N'
         --
         l_context_synchronization_flag := Nvl(p_context_synchronization_flag, 'X');
         IF (l_context_synchronization_flag NOT IN ('Y', 'N')) THEN
            IF (l_dff_flx.context_synchronization_flag IN ('Y', 'N')) THEN
               l_context_synchronization_flag := l_dff_flx.context_synchronization_flag;
            ELSE
               IF (p_descriptive_flexfield_name LIKE '$SRS$.%') THEN
                  l_context_synchronization_flag := 'N';
               ELSE
                  IF ((p_default_context_field_name is NOT NULL) AND
                      (p_context_user_override_flag = 'N')) THEN
                     l_context_synchronization_flag := 'Y';
                  ELSE
                     l_context_synchronization_flag := 'N';
                  END IF;
               END IF;
            END IF;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading DESC_FLEX.(MLS)');
         END IF;
         fnd_descriptive_flexs_pkg.load_row
           (x_application_short_name       => p_application_short_name,
            x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
            x_who                          => l_file_who,
            x_table_application_short_name => p_table_application_short_name,
            x_application_table_name       => p_application_table_name,
            x_concatenated_segs_view_name  => l_concatenated_segs_view_name,
            x_context_required_flag        => p_context_required_flag,
            x_context_column_name          => p_context_column_name,
            x_context_user_override_flag   => p_context_user_override_flag,
            x_concatenated_segment_delimit => p_concatenated_segment_delimit,
            x_freeze_flex_definition_flag  => p_freeze_flex_definition_flag,
            x_protected_flag               => p_protected_flag,
            x_default_context_field_name   => p_default_context_field_name,
            x_default_context_value        => p_default_context_value,
            x_context_default_type         => p_context_default_type,
            x_context_default_value        => p_context_default_value,
            x_context_override_value_set_n => p_context_override_value_set_n,
            x_context_runtime_property_fun => p_context_runtime_property_fun,
            x_context_synchronization_flag => l_context_synchronization_flag,
            x_title                        => l_title,
            x_form_context_prompt          => p_form_context_prompt,
            x_description                  => p_description);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- LDT SRS Desc Flex.
         --
         IF (l_descriptive_flexfield_name LIKE '$SRS$.%') THEN
            l_descriptive_flexfield_name := g_srs_loader_flex_name;
            IF (g_debug_on) THEN
               debug(l_func_name, 'SRS: Switched name to ' || l_descriptive_flexfield_name);
            END IF;
         END IF;

         IF (l_descriptive_flexfield_name NOT LIKE '$SRS$.%') THEN
            --
            -- Make sure Context column is marked in fnd_columns.
            --
            fnd_flex_loader_apis.up_dff_column
              (p_upload_phase               => 'LEAF',
               p_upload_mode                => NULL,
               p_application_short_name     => p_application_short_name,
               p_descriptive_flexfield_name => l_descriptive_flexfield_name,
               p_column_name                => p_context_column_name,
               p_owner                      => p_owner,
               p_last_update_date           => p_last_update_date,
               p_flexfield_usage_code       => 'C');
         END IF;

         --
         -- Make sure Global Context is created.
         --
         get_dff_flx(p_application_short_name,
                     l_descriptive_flexfield_name,
                     l_dff_flx);

         IF (NOT get_dff_ctx(l_dff_flx,
                             'Global Data Elements',
                             l_dff_ctx)) THEN
            fnd_flex_loader_apis.up_dff_context
              (p_upload_phase                 => 'BEGIN',
               p_upload_mode                  => NULL,
               p_application_short_name       => p_application_short_name,
               p_descriptive_flexfield_name   => l_descriptive_flexfield_name,
               p_descriptive_flex_context_cod => 'Global Data Elements',
               p_owner                        => p_owner,
               p_last_update_date             => p_last_update_date,
               p_enabled_flag                 => 'Y',
               p_global_flag                  => 'Y',
               p_descriptive_flex_context_nam => 'Global Data Elements',
               p_description                  => 'Global Data Element Context');
         END IF;

         IF (p_descriptive_flexfield_name LIKE '$SRS$.%') THEN
            g_numof_changes := 0;
            upload_srs_desc_flex(p_custom_mode                => p_custom_mode,
                                 p_application_short_name     => p_application_short_name,
                                 p_descriptive_flexfield_name => p_descriptive_flexfield_name,
                                 p_title                      => p_title);
         END IF;
      END IF; -- p_upload_mode
      --
      -- Compile Flex, Generate View.
      --
      IF (g_numof_changes > 0) THEN
         call_cp(p_mode                       => 'DFF',
                 p_upload_mode                => p_upload_mode,
                 p_application_short_name     => p_application_short_name,
                 p_descriptive_flexfield_name => p_descriptive_flexfield_name);
      END IF;
      finish_transaction(ENTITY_DESC_FLEX);
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF; -- p_upload_phase

   <<label_done>>
   done('DESC_FLEX', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_descriptive_flexfield_name);

      BEGIN
         release_entity();
         IF (p_upload_phase = 'END') THEN
            finish_transaction(ENTITY_DESC_FLEX);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            report_public_api_exception(l_func_name,
                                        p_upload_phase,
                                        p_application_short_name,
                                        p_descriptive_flexfield_name);
      END;
END up_desc_flex;

-- --------------------------------------------------
PROCEDURE up_dff_column
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_column_name                  IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_flexfield_usage_code         IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_dff_flx   dff_flx_type;
     l_col       col_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_dff_column()';
   init('DFF_COLUMN', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || p_descriptive_flexfield_name ||
            ',COL:'   || p_column_name ||
            ',USG:'   || p_flexfield_usage_code);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure DFF and Column exist.
   --
   get_dff_flx(p_application_short_name,
               p_descriptive_flexfield_name,
               l_dff_flx);

   get_col(l_dff_flx.table_application_id,
           l_dff_flx.application_table_name,
           p_column_name,
           l_col);

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_col.last_updated_by,
        p_db_last_update_date          => l_col.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
         debug(l_func_name, 'For data integrity upload must be done.');
      END IF;

      --
      -- Clear the customization message
      --
      fnd_message.clear();
   END IF;

   --
   -- Usual upload.
   --
   IF ((p_descriptive_flexfield_name NOT LIKE '$SRS$.%') AND
       (p_flexfield_usage_code IN ('C','D'))) THEN
      --
      -- Make sure column is not in use.
      --
      IF ((((l_col.flexfield_application_id IS NULL) OR
            (l_col.flexfield_application_id = l_dff_flx.application_id)) AND
           ((l_col.flexfield_name IS NULL) OR
            (l_col.flexfield_name = p_descriptive_flexfield_name)) AND
           ((l_col.flexfield_usage_code IS NULL) OR
            (l_col.flexfield_usage_code = p_flexfield_usage_code))) OR
          (l_col.flexfield_usage_code = 'N') OR
          ((l_col.flexfield_application_id = l_dff_flx.application_id) AND
           (l_col.flexfield_name = p_descriptive_flexfield_name) AND
           (l_col.flexfield_usage_code = 'D') AND
           (p_flexfield_usage_code = 'C'))) THEN

         IF (g_debug_on) THEN
            debug(l_func_name, 'Updating DFF_COLUMN.(no-TL)');
         END IF;
         UPDATE fnd_columns SET
           last_updated_by          = l_file_who.last_updated_by,
           last_update_date         = l_file_who.last_update_date,
           last_update_login        = l_file_who.last_update_login,
           flexfield_application_id = Decode(p_flexfield_usage_code,
                                             'N', NULL,
                                             l_dff_flx.application_id),
           flexfield_name           = Decode(p_flexfield_usage_code,
                                             'N', NULL,
                                             l_dff_flx.descriptive_flexfield_name),
           flexfield_usage_code     = p_flexfield_usage_code
           WHERE application_id = l_col.application_id
           AND table_id = l_col.table_id
           AND column_name = l_col.column_name;
         IF (SQL%rowcount > 0) THEN
            g_numof_changes := g_numof_changes + 1;
         END IF;
       ELSE
         raise_error(l_func_name, ERROR_DFF_COL_USED,
                     'COL:' || p_column_name || ' is used by ' ||
                     'APP Id:' || To_char(l_col.flexfield_application_id) ||
                     ' Flex Name:' || l_col.flexfield_name ||
                     ' Usage Code:' || l_col.flexfield_usage_code,
                     'You cannot use it in another flexfield');
      END IF;
   END IF;

   <<label_done>>
   done('DFF_COLUMN', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_descriptive_flexfield_name,
                                  p_column_name);
END up_dff_column;

-- --------------------------------------------------
PROCEDURE up_dff_ref_field
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_dff_flx   dff_flx_type;
     l_dff_ref   dff_ref_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_dff_ref_field()';
   init('DFF_REF_FIELD', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || p_descriptive_flexfield_name ||
            ',REF:'   || p_default_context_field_name);
   END IF;

   IF (p_descriptive_flexfield_name LIKE '$SRS$.%') THEN
      --
      -- No Reference Field for SRS.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No Reference Field for $SRS$.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_dff_flx(p_application_short_name,
                   p_descriptive_flexfield_name,
                   l_dff_flx)) THEN
      IF (get_dff_ref(l_dff_flx,
                      p_default_context_field_name,
                      l_dff_ref)) THEN
         NULL;
      END IF;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_dff_ref.last_updated_by,
        p_db_last_update_date          => l_dff_ref.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- non-MLS translation.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating DFF_REF_FIELD.(non-MLS)');
      END IF;
      UPDATE fnd_default_context_fields SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        description       = Nvl(p_description, description)
        WHERE application_id = (SELECT application_id
                                FROM fnd_application
                                WHERE application_short_name = p_application_short_name)
        AND descriptive_flexfield_name = p_descriptive_flexfield_name
        AND default_context_field_name = p_default_context_field_name
        AND userenv('LANG') = (SELECT language_code
                               FROM fnd_languages
                               WHERE installed_flag = 'B');
      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'No entity to translate.');
         END IF;
      END IF;
      GOTO label_done;
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Make sure DFF exists.
      --
      get_dff_flx(p_application_short_name,
                  p_descriptive_flexfield_name,
                  l_dff_flx);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Updating DFF_REF_FIELD.(non-MLS)');
      END IF;
      UPDATE fnd_default_context_fields SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        description       = p_description
        WHERE application_id = l_dff_flx.application_id
        AND descriptive_flexfield_name = l_dff_flx.descriptive_flexfield_name
        AND default_context_field_name = p_default_context_field_name;

      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Inserting DFF_REF_FIELD.(non-MLS)');
         END IF;
         INSERT INTO fnd_default_context_fields
           (
            application_id,
            descriptive_flexfield_name,
            default_context_field_name,

            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,

            description
            )
           VALUES
           (
            l_dff_flx.application_id,
            l_dff_flx.descriptive_flexfield_name,
            p_default_context_field_name,

            l_file_who.created_by,
            l_file_who.creation_date,
            l_file_who.last_updated_by,
            l_file_who.last_update_date,
            l_file_who.last_update_login,

            p_description
            );
      END IF;
   END IF;

   <<label_done>>
   done('DFF_REF_FIELD', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_descriptive_flexfield_name,
                                  p_default_context_field_name);
END up_dff_ref_field;

-- --------------------------------------------------
PROCEDURE up_dff_context
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_descriptive_flex_context_cod IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_global_flag                  IN VARCHAR2,
   p_descriptive_flex_context_nam IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_dff_flx    dff_flx_type;
     l_dff_ctx    dff_ctx_type;
     l_dff_ctx_tl dff_ctx_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_descriptive_flexfield_name fnd_descriptive_flexs_vl.descriptive_flexfield_name%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_dff_context()';
   l_descriptive_flexfield_name := p_descriptive_flexfield_name;

   init('DFF_CONTEXT', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || l_descriptive_flexfield_name ||
            ',CTX:'   || p_descriptive_flex_context_cod);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_dff_flx(p_application_short_name,
                      l_descriptive_flexfield_name,
                      l_dff_flx)) THEN
         IF (get_dff_ctx(l_dff_flx,
                         p_descriptive_flex_context_cod,
                         l_dff_ctx)) THEN
            NULL;
         END IF;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_dff_ctx_tl(l_dff_ctx,
                            userenv('LANG'),
                            l_dff_ctx_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_dff_ctx_tl.last_updated_by,
              p_db_last_update_date          => l_dff_ctx_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating DFF_CONTEXT.(MLS)');
         END IF;
         fnd_descr_flex_contexts_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
            x_descriptive_flex_context_cod => p_descriptive_flex_context_cod,
            x_who                          => l_file_who,
            x_description                  => p_description,
            x_descriptive_flex_context_nam => p_descriptive_flex_context_nam);
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_dff_ctx.last_updated_by,
              p_db_last_update_date          => l_dff_ctx.last_update_date,
              x_file_who                     => l_file_who)) THEN

            --
            -- SRS DFFs are handled in upload_srs_desc_flex().
            --
            IF (l_descriptive_flexfield_name NOT LIKE '$SRS$.%')  THEN
               IF (g_debug_on) THEN
                  debug(l_func_name, 'Upload is not allowed because of customization.');
               END IF;
               GOTO label_done;
            else
               --
               -- Clear the customization message
               --
               fnd_message.clear();
            END IF;
         END IF;

         IF (l_descriptive_flexfield_name LIKE '$SRS$.%')  THEN
            --
            -- LDT SRS Desc Flex Global Data Elements.
            --
            l_descriptive_flexfield_name := g_srs_loader_flex_name;
            IF (g_debug_on) THEN
               debug(l_func_name, 'SRS: Switched name to ' || l_descriptive_flexfield_name);
            END IF;
         END IF;

         --
         -- Make sure DFF exists.
         --
         get_dff_flx(p_application_short_name,
                     l_descriptive_flexfield_name,
                     l_dff_flx);

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading DFF_CONTEXT.(MLS)');
         END IF;
         fnd_descr_flex_contexts_pkg.load_row
           (x_application_short_name       => p_application_short_name,
            x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
            x_descriptive_flex_context_cod => p_descriptive_flex_context_cod,
            x_who                          => l_file_who,
            x_enabled_flag                 => p_enabled_flag,
            x_global_flag                  => p_global_flag,
            x_description                  => p_description,
            x_descriptive_flex_context_nam => p_descriptive_flex_context_nam);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('DFF_CONTEXT', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_descriptive_flexfield_name,
                                  p_descriptive_flex_context_cod);
END up_dff_context;

-- --------------------------------------------------
PROCEDURE up_dff_segment
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_descriptive_flex_context_cod IN VARCHAR2,
   p_end_user_column_name         IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_column_seq_num               IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_display_flag                 IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_display_size                 IN VARCHAR2,
   p_maximum_description_len      IN VARCHAR2,
   p_concatenation_description_le IN VARCHAR2,
   p_range_code                   IN VARCHAR2,
   p_default_type                 IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_runtime_property_function    IN VARCHAR2 DEFAULT NULL,
   p_srw_param                    IN VARCHAR2,
   p_form_left_prompt             IN VARCHAR2,
   p_form_above_prompt            IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_dff_flx    dff_flx_type;
     l_dff_ctx    dff_ctx_type;
     l_dff_seg    dff_seg_type;
     l_dff_seg_tl dff_seg_tl_type;
     l_vst_set    vst_set_type;
     l_col        col_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_descriptive_flexfield_name fnd_descriptive_flexs_vl.descriptive_flexfield_name%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_dff_segment()';
   l_descriptive_flexfield_name := p_descriptive_flexfield_name;

   init('DFF_SEGMENT', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',DFF:'   || l_descriptive_flexfield_name ||
            ',CTX:'   || p_descriptive_flex_context_cod ||
            ',SEG:'   || p_end_user_column_name ||
            ',COL:'   || p_application_column_name);
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_dff_flx(p_application_short_name,
                   l_descriptive_flexfield_name,
                   l_dff_flx)) THEN
      IF (get_dff_ctx(l_dff_flx,
                      p_descriptive_flex_context_cod,
                      l_dff_ctx)) THEN
         IF (get_dff_seg(l_dff_ctx,
                         p_application_column_name,
                         l_dff_seg)) THEN
            NULL;
         END IF;
      END IF;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- MLS translation.
      --

      --
      -- Gather WHO Information.
      --
      IF (get_dff_seg_tl(l_dff_seg,
                         userenv('LANG'),
                         l_dff_seg_tl)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_dff_seg_tl.last_updated_by,
           p_db_last_update_date          => l_dff_seg_tl.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating DFF_SEGMENT.(MLS)');
      END IF;
      fnd_descr_flex_col_usage_pkg.translate_row
        (x_application_short_name       => p_application_short_name,
         x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
         x_descriptive_flex_context_cod => p_descriptive_flex_context_cod,
         x_application_column_name      => p_application_column_name,
         x_who                          => l_file_who,
         x_form_left_prompt             => p_form_left_prompt,
         x_form_above_prompt            => p_form_above_prompt,
         x_description                  => p_description);
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_dff_seg.last_updated_by,
           p_db_last_update_date          => l_dff_seg.last_update_date,
           x_file_who                     => l_file_who)) THEN

         --
         -- SRS DFFs are handled in upload_srs_desc_flex().
         --
         IF (l_descriptive_flexfield_name NOT LIKE '$SRS$.%')  THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         else
            --
            -- Clear the customization message
            --
            fnd_message.clear();
         END IF;
      END IF;

      IF (l_descriptive_flexfield_name LIKE '$SRS$.%')  THEN
         --
         -- LDT SRS Desc Flex Global Data Elements.
         --
         l_descriptive_flexfield_name := g_srs_loader_flex_name;
         IF (g_debug_on) THEN
            debug(l_func_name, 'SRS: Switched name to ' || l_descriptive_flexfield_name);
         END IF;
      END IF;

      --
      -- Make sure DFF, Context and Column exist.
      --
      get_dff_flx(p_application_short_name,
                  l_descriptive_flexfield_name,
                  l_dff_flx);

      get_dff_ctx(l_dff_flx,
                  p_descriptive_flex_context_cod,
                  l_dff_ctx);

      get_col(l_dff_flx.table_application_id,
              l_dff_flx.application_table_name,
              p_application_column_name,
              l_col);

      IF ((((l_col.flexfield_application_id = l_dff_flx.application_id) AND
            (l_col.flexfield_name = l_dff_flx.descriptive_flexfield_name)) OR
           (l_dff_flx.descriptive_flexfield_name LIKE '$SRS$.%')) AND
          (l_col.flexfield_usage_code = 'D')) THEN
         NULL;
       ELSE
         raise_error(l_func_name, ERROR_DFF_COL_NOT_REG,
                     'COL:' || l_col.column_name ||
                     ' is not registered properly. It is registered as ' ||
                     'APP Id:' || To_char(l_col.flexfield_application_id) ||
                     ' Flex Name:' || l_col.flexfield_name ||
                     ' Usage Code:' || l_col.flexfield_usage_code,
                     'Please use Application Developer:' ||
                     'Flexfield->Descriptive->Register form and ' ||
                     'make sure column is enabled. If this column is ' ||
                     'not in the list, it means it is used by another ' ||
                     'flexfield and you cannot use it');
      END IF;

      --
      -- Check for duplicate column usage between Global and any Context
      --
      DECLARE
        l_error_msg VARCHAR2(2000);
        l_ctx_code  fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE;
      BEGIN
         SELECT fdfc.descriptive_flex_context_code
           INTO l_ctx_code
           FROM fnd_descr_flex_column_usages fdfcu,
                fnd_descr_flex_contexts fdfc
          WHERE fdfcu.application_column_name = p_application_column_name
            AND fdfcu.descriptive_flex_context_code = fdfc.descriptive_flex_context_code
            AND fdfcu.descriptive_flexfield_name = fdfc.descriptive_flexfield_name
            AND fdfcu.application_id = fdfc.application_id
            AND fdfc.descriptive_flexfield_name = l_dff_ctx.descriptive_flexfield_name
            AND fdfc.application_id = l_dff_ctx.application_id
            AND fdfc.global_flag <> l_dff_ctx.global_flag
            AND ROWNUM < 2;

         IF (l_dff_ctx.global_flag = 'Y') THEN
            l_error_msg := 'Global Segment cannot be uploaded. ' ||
              'Its Column (' || p_application_column_name ||
              ') is already used in non-Global Context (' || l_ctx_code || ')';
          ELSE
            l_error_msg := 'Context sensitive segment cannot be uploaded. ' ||
              'Its Column (' || p_application_column_name ||
              ') is already used in Global Context';
         END IF;

         raise_error(l_func_name, ERROR_VST_GENERIC, l_error_msg);
      EXCEPTION
         WHEN no_data_found THEN
            NULL;
      END;

      IF (p_flex_value_set_name IS NOT NULL) THEN
         --
         -- Make sure Value Set exists.
         --
         get_vst_set(p_flex_value_set_name, l_vst_set);
      END IF;

      IF (g_debug_on) THEN
         debug(l_func_name, 'Uploading DFF_SEGMENT.(MLS)');
      END IF;
      fnd_descr_flex_col_usage_pkg.load_row
        (x_application_short_name       => p_application_short_name,
         x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
         x_descriptive_flex_context_cod => p_descriptive_flex_context_cod,
         x_application_column_name      => p_application_column_name,
         x_who                          => l_file_who,
         x_end_user_column_name         => p_end_user_column_name,
         x_column_seq_num               => p_column_seq_num,
         x_enabled_flag                 => p_enabled_flag,
         x_required_flag                => p_required_flag,
         x_security_enabled_flag        => p_security_enabled_flag,
         x_display_flag                 => p_display_flag,
         x_display_size                 => p_display_size,
         x_maximum_description_len      => p_maximum_description_len,
         x_concatenation_description_le => p_concatenation_description_le,
         x_flex_value_set_name          => p_flex_value_set_name,
         x_range_code                   => p_range_code,
         x_default_type                 => p_default_type,
         x_default_value                => p_default_value,
         x_runtime_property_function    => p_runtime_property_function,
         x_srw_param                    => p_srw_param,
         x_form_left_prompt             => p_form_left_prompt,
         x_form_above_prompt            => p_form_above_prompt,
         x_description                  => p_description);
   END IF;

   <<label_done>>
   done('DFF_SEGMENT', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_descriptive_flexfield_name,
                                  p_descriptive_flex_context_cod,
                                  p_application_column_name,
                                  p_end_user_column_name);
END up_dff_segment;

-- ==================================================
--  KEY_FLEX
-- ==================================================

-- --------------------------------------------------
-- Updates all foreign references of id_flex_num
-- --------------------------------------------------
PROCEDURE fix_id_flex_num(p_application_id         IN NUMBER,
                          p_id_flex_code           IN VARCHAR2,
                          p_id_flex_num_old        IN NUMBER,
                          p_id_flex_num_new        IN NUMBER)
  IS
BEGIN
   --
   -- Update qualifier assignments
   --
   UPDATE fnd_segment_attribute_values
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Update segments
   --
   UPDATE fnd_id_flex_segments
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_id_flex_segments_tl
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Update shorthand aliases
   --
   UPDATE fnd_shorthand_flex_aliases
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Update cross validation lines/rules/stats
   --
   UPDATE fnd_flex_exclude_rule_lines
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_flex_include_rule_lines
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_flex_validation_rule_lines
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_flex_validation_rules
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_flex_vdation_rules_tl
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_flex_validation_rule_stats
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Update Account Generator Processes
   --
   UPDATE fnd_flex_workflow_processes
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Update structure
   --
   UPDATE fnd_id_flex_structures
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   UPDATE fnd_id_flex_structures_tl
     SET id_flex_num = p_id_flex_num_new
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   --
   -- Delete compiled data
   --
   DELETE FROM fnd_compiled_id_flex_structs
     WHERE application_id = p_application_id
     AND id_flex_code = p_id_flex_code
     AND id_flex_num = p_id_flex_num_old;

   IF (g_debug_on) THEN
      debug('LDR.fix_id_flex_num', 'Old id_flex_num: ' || p_id_flex_num_old ||
            ', New id_flex_num: ' || p_id_flex_num_new);
   END IF;
END fix_id_flex_num;

-- --------------------------------------------------
PROCEDURE up_key_flex
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_allow_id_valuesets           IN VARCHAR2,
   p_dynamic_inserts_feasible_fla IN VARCHAR2,
   p_index_flag                   IN VARCHAR2,
   p_unique_id_column_name        IN VARCHAR2,
   p_application_table_type       IN VARCHAR2,
   p_set_defining_column_name     IN VARCHAR2,
   p_maximum_concatenation_len    IN VARCHAR2,
   p_concatenation_len_warning    IN VARCHAR2,
   p_id_flex_name                 IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_tbl       tbl_type;
     l_app       app_type;
     l_kff_flx   kff_flx_type;
     l_kff_str   kff_str_type;
     l_101_code  VARCHAR2(2000);
     l_count     NUMBER;
     l_file_who fnd_flex_loader_apis.who_type;
     l_concatenated_segs_view_name fnd_id_flexs.concatenated_segs_view_name%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_key_flex()';
   init('KEY_FLEX', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      start_transaction(ENTITY_KEY_FLEX);
      lock_entity('KEY_FLEX',
                  p_application_short_name,
                  p_id_flex_code);

      g_numof_changes := 0;
      --
      -- Gather WHO Information.
      --
      IF (get_kff_flx(p_application_short_name,
                      p_id_flex_code,
                      l_kff_flx)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_kff_flx.last_updated_by,
           p_db_last_update_date          => l_kff_flx.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating KEY_FLEX.(non-MLS)');
         END IF;
         UPDATE fnd_id_flexs SET
           last_updated_by   = l_file_who.last_updated_by,
           last_update_date  = l_file_who.last_update_date,
           last_update_login = l_file_who.last_update_login,
           id_flex_name      = Nvl(p_id_flex_name, id_flex_name),
           description       = Nvl(p_description, description)
           WHERE application_id = (SELECT application_id
                                   FROM fnd_application
                                   WHERE application_short_name = p_application_short_name)
           AND id_flex_code = p_id_flex_code
           AND userenv('LANG') = (SELECT language_code
                                  FROM fnd_languages
                                  WHERE installed_flag = 'B');
         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'No entity to translate.');
            END IF;
         END IF;
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Make sure Application and Table exist.
         --
         get_app(p_application_short_name,
                 l_app);

         get_tbl(p_table_application_short_name,
                 p_application_table_name,
                 l_tbl);

         --
         -- Intentional/Unintentional NULL handling.
         --
         IF (p_concatenated_segs_view_name IS NULL) THEN
            l_concatenated_segs_view_name := l_kff_flx.concatenated_segs_view_name;
          ELSIF (p_concatenated_segs_view_name = g_null_value) THEN
            l_concatenated_segs_view_name := NULL;
          ELSE
            l_concatenated_segs_view_name := p_concatenated_segs_view_name;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Updating KEY_FLEX.(non-MLS)');
         END IF;
         UPDATE fnd_id_flexs SET
           last_updated_by               = l_file_who.last_updated_by,
           last_update_date              = l_file_who.last_update_date,
           last_update_login             = l_file_who.last_update_login,
           table_application_id          = l_tbl.application_id,
           application_table_name        = l_tbl.table_name,
           concatenated_segs_view_name   = l_concatenated_segs_view_name,
           allow_id_valuesets            = p_allow_id_valuesets,
           dynamic_inserts_feasible_flag = p_dynamic_inserts_feasible_fla,
           index_flag                    = p_index_flag,
           unique_id_column_name         = p_unique_id_column_name,
           application_table_type        = p_application_table_type,
           set_defining_column_name      = p_set_defining_column_name,
           maximum_concatenation_len     = p_maximum_concatenation_len,
           concatenation_len_warning     = p_concatenation_len_warning,
           id_flex_name                  = p_id_flex_name,
           description                   = p_description
           WHERE application_id = l_app.application_id
           AND id_flex_code = p_id_flex_code;

         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Inserting KEY_FLEX.(non-MLS)');
            END IF;
            INSERT INTO fnd_id_flexs
              (
               application_id,
               id_flex_code,

               created_by,
               creation_date,
               last_updated_by,
               last_update_date,
               last_update_login,

               table_application_id,
               application_table_name,
               concatenated_segs_view_name,
               allow_id_valuesets,
               dynamic_inserts_feasible_flag,
               index_flag,
               unique_id_column_name,
               application_table_type,
               set_defining_column_name,
               maximum_concatenation_len,
               concatenation_len_warning,
               id_flex_name,
               description
               )
              VALUES
              (
               l_app.application_id,
               p_id_flex_code,

               l_file_who.created_by,
               l_file_who.creation_date,
               l_file_who.last_updated_by,
               l_file_who.last_update_date,
               l_file_who.last_update_login,

               l_tbl.application_id,
               l_tbl.table_name,
               l_concatenated_segs_view_name,
               p_allow_id_valuesets,
               p_dynamic_inserts_feasible_fla,
               p_index_flag,
               p_unique_id_column_name,
               p_application_table_type,
               p_set_defining_column_name,
               p_maximum_concatenation_len,
               p_concatenation_len_warning,
               p_id_flex_name,
               p_description
               );
         END IF;
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Make sure columns are marked in fnd_columns.
         --
         fnd_flex_loader_apis.up_kff_column
           (p_upload_phase           => 'LEAF',
            p_upload_mode            => NULL,
            p_application_short_name => p_application_short_name,
            p_id_flex_code           => p_id_flex_code,
            p_column_name            => p_unique_id_column_name,
            p_owner                  => p_owner,
            p_last_update_date       => p_last_update_date,
            p_flexfield_usage_code   => 'I');

         IF (p_set_defining_column_name IS NOT NULL) THEN
            fnd_flex_loader_apis.up_kff_column
              (p_upload_phase           => 'LEAF',
               p_upload_mode            => NULL,
               p_application_short_name => p_application_short_name,
               p_id_flex_code           => p_id_flex_code,
               p_column_name            => p_set_defining_column_name,
               p_owner                  => p_owner,
               p_last_update_date       => p_last_update_date,
               p_flexfield_usage_code   => 'S');
         END IF;

         --
         -- Make sure there is at least one structure.
         --
         get_app(p_application_short_name,
                 l_app);

         SELECT COUNT(*)
           INTO l_count
           FROM fnd_id_flex_structures
           WHERE application_id = l_app.application_id
           AND id_flex_code = p_id_flex_code;

         IF (l_count = 0) THEN
            --
            -- Create the 101 structure.
            --
            get_kff_flx(p_application_short_name,
                        p_id_flex_code,
                        l_kff_flx);

            l_101_code := REPLACE(Upper(p_id_flex_name),' ','_');
            fnd_flex_loader_apis.up_kff_structure
              (p_upload_phase                 => 'BEGIN',
               p_upload_mode                  => NULL,
               p_application_short_name       => p_application_short_name,
               p_id_flex_code                 => p_id_flex_code,
               p_id_flex_structure_code       => l_101_code,
               p_owner                        => p_owner,
               p_last_update_date             => p_last_update_date,
               p_concatenated_segment_delimit => '.',
               p_cross_segment_validation_fla => 'N',
               p_dynamic_inserts_allowed_flag => 'N',
               p_enabled_flag                 => 'Y',
               p_freeze_flex_definition_flag  => 'N',
               p_freeze_structured_hier_flag  => 'N',
               p_shorthand_enabled_flag       => 'N',
               p_shorthand_length             => NULL,
               p_structure_view_name          => NULL,
               p_id_flex_structure_name       => p_id_flex_name,
               p_description                  => NULL,
               p_shorthand_prompt             => NULL);

            --
            -- Update the id_flex_num to 101.
            --
            get_kff_str(l_kff_flx,
                        l_101_code,
                        l_kff_str);

            IF (l_kff_str.id_flex_num <> 101) THEN
               fix_id_flex_num(p_application_id  => l_kff_str.application_id,
                               p_id_flex_code    => l_kff_str.id_flex_code,
                               p_id_flex_num_old => l_kff_str.id_flex_num,
                               p_id_flex_num_new => 101);
            END IF;
         END IF;

         --
         -- Populate the missing wf processes.
         --
         DECLARE
            CURSOR missing_wfp_cur(p_application_id IN NUMBER,
                                   p_id_flex_code   IN VARCHAR2)
              IS
                 SELECT
                   ifst.id_flex_structure_code,
                   fwp.wf_item_type
                   FROM (SELECT DISTINCT
                         fwpx.application_id,
                         fwpx.id_flex_code,
                         fwpx.wf_item_type
                         FROM fnd_flex_workflow_processes fwpx
                         ) fwp,
                        fnd_id_flex_structures ifst
                   WHERE ifst.application_id = p_application_id
                   AND ifst.id_flex_code = p_id_flex_code
                   AND fwp.application_id = ifst.application_id
                   AND fwp.id_flex_code = ifst.id_flex_code
                   AND NOT exists
                   (SELECT NULL
                    FROM fnd_flex_workflow_processes fwp2
                    WHERE fwp2.application_id = ifst.application_id
                    AND fwp2.id_flex_code = ifst.id_flex_code
                    AND fwp2.id_flex_num = ifst.id_flex_num
                    AND fwp2.wf_item_type = fwp.wf_item_type);
         BEGIN
            FOR missing_wfp_rec IN missing_wfp_cur(l_app.application_id,
                                                   p_id_flex_code)
              LOOP
                 up_kff_wf_process
                   (p_upload_phase           => 'LEAF',
                    p_upload_mode            => NULL,
                    p_application_short_name => p_application_short_name,
                    p_id_flex_code           => p_id_flex_code,
                    p_id_flex_structure_code => missing_wfp_rec.id_flex_structure_code,
                    p_wf_item_type           => missing_wfp_rec.wf_item_type,
                    p_owner                  => p_owner,
                    p_last_update_date       => p_last_update_date,
                    p_wf_process_name        => 'DEFAULT_ACCOUNT_GENERATION');
              END LOOP;
         END;
      END IF;
      --
      -- Compile Flex, Generate View.
      --
      IF (g_numof_changes > 0) THEN
         call_cp(p_mode                       => 'KFF',
                 p_upload_mode                => p_upload_mode,
                 p_application_short_name     => p_application_short_name,
                 p_id_flex_code               => p_id_flex_code);
      END IF;
      finish_transaction(ENTITY_KEY_FLEX);
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KEY_FLEX', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code);

      BEGIN
         release_entity();
         IF (p_upload_phase = 'END') THEN
            finish_transaction(ENTITY_KEY_FLEX);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            report_public_api_exception(l_func_name,
                                        p_upload_phase,
                                        p_application_short_name,
                                        p_id_flex_code);
      END;
END up_key_flex;

-- --------------------------------------------------
PROCEDURE up_kff_column
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_column_name                  IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_flexfield_usage_code         IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_col       col_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_column()';
   init('KFF_COLUMN', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',COL:'   || p_column_name ||
            ',USG:'   || p_flexfield_usage_code);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure KFF and Column exist.
   --
   get_kff_flx(p_application_short_name,
               p_id_flex_code,
               l_kff_flx);

   get_col(l_kff_flx.table_application_id,
           l_kff_flx.application_table_name,
           p_column_name,
           l_col);

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_col.last_updated_by,
        p_db_last_update_date          => l_col.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
         debug(l_func_name, 'For data integrity upload must be done.');
      END IF;
      --
      -- Clear the customization message
      --
      fnd_message.clear();
   END IF;

   --
   -- Usual upload.
   --
   IF (p_flexfield_usage_code IN ('I','S','Q','K')) THEN
      --
      -- Make sure column is not in use.
      --
      IF ((((l_col.flexfield_application_id IS NULL) OR
            (l_col.flexfield_application_id = l_kff_flx.application_id)) AND
           ((l_col.flexfield_name IS NULL) OR
            (l_col.flexfield_name = p_id_flex_code)) AND
           ((l_col.flexfield_usage_code IS NULL) OR
            (l_col.flexfield_usage_code = p_flexfield_usage_code))) OR
          (l_col.flexfield_usage_code = 'N')) THEN

         IF (g_debug_on) THEN
            debug(l_func_name, 'Updating KFF_COLUMN.(no-TL)');
         END IF;
         UPDATE fnd_columns SET
           last_updated_by          = l_file_who.last_updated_by,
           last_update_date         = l_file_who.last_update_date,
           last_update_login        = l_file_who.last_update_login,
           flexfield_application_id = NULL,
           flexfield_name           = NULL,
           flexfield_usage_code     = p_flexfield_usage_code
           WHERE application_id = l_col.application_id
           AND table_id = l_col.table_id
           AND column_name = l_col.column_name;
         IF (SQL%rowcount > 0) THEN
            g_numof_changes := g_numof_changes + 1;
         END IF;
       ELSE
         raise_error(l_func_name, ERROR_KFF_COL_USED,
                     'COL:' || p_column_name || ' is used by ' ||
                     'APP Id:' || To_char(l_col.flexfield_application_id) ||
                     ' Flex Name:' || l_col.flexfield_name ||
                     ' Usage Code:' || l_col.flexfield_usage_code,
                     'You cannot use it in another flexfield');
      END IF;
   END IF;

   <<label_done>>
   done('KFF_COLUMN', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_column_name);
END up_kff_column;

-- --------------------------------------------------
PROCEDURE up_kff_flex_qual
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_global_flag                  IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_unique_flag                  IN VARCHAR2,
   p_segment_prompt               IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_flq   kff_flq_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_flex_qual()';
   init('KFF_FLEX_QUAL', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',FLEXQ:' || p_segment_attribute_type);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_kff_flx(p_application_short_name,
                      p_id_flex_code,
                      l_kff_flx)) THEN
         IF (get_kff_flq(l_kff_flx,
                         p_segment_attribute_type,
                         l_kff_flq)) THEN
            NULL;
         END IF;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_kff_flq.last_updated_by,
           p_db_last_update_date          => l_kff_flq.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating KFF_FLEX_QUAL.(non-MLS)');
         END IF;
         UPDATE fnd_segment_attribute_types SET
           last_updated_by   = l_file_who.last_updated_by,
           last_update_date  = l_file_who.last_update_date,
           last_update_login = l_file_who.last_update_login,
           segment_prompt    = Nvl(p_segment_prompt, segment_prompt),
           description       = Nvl(p_description, description)
           WHERE application_id = (SELECT application_id
                                   FROM fnd_application
                                   WHERE application_short_name = p_application_short_name)
           AND id_flex_code = p_id_flex_code
           AND segment_attribute_type = p_segment_attribute_type
           AND userenv('LANG') = (SELECT language_code
                                  FROM fnd_languages
                                  WHERE installed_flag = 'B');
         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'No entity to translate.');
            END IF;
         END IF;
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Make sure KFF exists.
         --
         get_kff_flx(p_application_short_name,
                     p_id_flex_code,
                     l_kff_flx);

         IF (g_debug_on) THEN
            debug(l_func_name, 'Updating KFF_FLEX_QUAL.(non-MLS)');
         END IF;
         UPDATE fnd_segment_attribute_types SET
           last_updated_by   = l_file_who.last_updated_by,
           last_update_date  = l_file_who.last_update_date,
           last_update_login = l_file_who.last_update_login,
           global_flag       = p_global_flag,
           required_flag     = p_required_flag,
           unique_flag       = p_unique_flag,
           segment_prompt    = p_segment_prompt,
           description       = p_description
           WHERE application_id = l_kff_flx.application_id
           AND id_flex_code = l_kff_flx.id_flex_code
           AND segment_attribute_type = p_segment_attribute_type;

         IF (SQL%notfound) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Inserting KFF_FLEX_QUAL.(non-MLS)');
            END IF;
            INSERT INTO fnd_segment_attribute_types
              (
               application_id,
               id_flex_code,
               segment_attribute_type,

               created_by,
               creation_date,
               last_updated_by,
               last_update_date,
               last_update_login,

               global_flag,
               required_flag,
               unique_flag,
               segment_prompt,
               description
               )
              VALUES
              (
               l_kff_flx.application_id,
               l_kff_flx.id_flex_code,
               p_segment_attribute_type,

               l_file_who.created_by,
               l_file_who.creation_date,
               l_file_who.last_updated_by,
               l_file_who.last_update_date,
               l_file_who.last_update_login,

               p_global_flag,
               p_required_flag,
               p_unique_flag,
               p_segment_prompt,
               p_description
               );
         END IF;
         --
         -- Populate the cross product table.
         --
         populate_kff_flexq_assign();

      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- non-MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_FLEX_QUAL', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_segment_attribute_type);
END up_kff_flex_qual;

-- --------------------------------------------------
PROCEDURE up_kff_segment_qual
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_required_flag                IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_lookup_type                  IN VARCHAR2,
   p_derivation_rule_code         IN VARCHAR2,
   p_derivation_rule_value1       IN VARCHAR2,
   p_derivation_rule_value2       IN VARCHAR2,
   p_prompt                       IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_kff_flx    kff_flx_type;
     l_kff_flq    kff_flq_type;
     l_kff_sgq    kff_sgq_type;
     l_kff_sgq_tl kff_sgq_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_segment_qual()';
   init('KFF_SEGMENT_QUAL', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type);
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_kff_flx(p_application_short_name,
                   p_id_flex_code,
                   l_kff_flx)) THEN
      IF (get_kff_flq(l_kff_flx,
                      p_segment_attribute_type,
                      l_kff_flq)) THEN
         IF (get_kff_sgq(l_kff_flq,
                         p_value_attribute_type,
                         l_kff_sgq)) THEN
            NULL;
         END IF;
      END IF;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- MLS translation.
      --

      --
      -- Gather WHO Information.
      --
      IF (get_kff_sgq_tl(l_kff_sgq,
                         userenv('LANG'),
                         l_kff_sgq_tl)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_kff_sgq_tl.last_updated_by,
           p_db_last_update_date          => l_kff_sgq_tl.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating KFF_SEGMENT_QUAL.(MLS)');
      END IF;
      fnd_val_attribute_types_pkg.translate_row
        (x_application_short_name       => p_application_short_name,
         x_id_flex_code                 => p_id_flex_code,
         x_segment_attribute_type       => p_segment_attribute_type,
         x_value_attribute_type         => p_value_attribute_type,
         x_who                          => l_file_who,
         x_prompt                       => p_prompt,
         x_description                  => p_description);
      GOTO label_done;
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_kff_sgq.last_updated_by,
           p_db_last_update_date          => l_kff_sgq.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      --
      -- Make sure KFF and Flexfield Qualifier exist.
      --
      get_kff_flx(p_application_short_name,
                  p_id_flex_code,
                  l_kff_flx);

      get_kff_flq(l_kff_flx,
                  p_segment_attribute_type,
                  l_kff_flq);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Uploading KFF_SEGMENT_QUAL.(MLS)');
      END IF;
      fnd_val_attribute_types_pkg.load_row
        (x_application_short_name       => p_application_short_name,
         x_id_flex_code                 => p_id_flex_code,
         x_segment_attribute_type       => p_segment_attribute_type,
         x_value_attribute_type         => p_value_attribute_type,
         x_who                          => l_file_who,
         x_required_flag                => p_required_flag,
         x_application_column_name      => p_application_column_name,
         x_default_value                => p_default_value,
         x_lookup_type                  => p_lookup_type,
         x_derivation_rule_code         => p_derivation_rule_code,
         x_derivation_rule_value1       => p_derivation_rule_value1,
         x_derivation_rule_value2       => p_derivation_rule_value2,
         x_prompt                       => p_prompt,
         x_description                  => p_description);

      --
      -- Make sure application column is marked in fnd_columns.
      --
      fnd_flex_loader_apis.up_kff_column
        (p_upload_phase           => 'LEAF',
         p_upload_mode            => NULL,
         p_application_short_name => p_application_short_name,
         p_id_flex_code           => p_id_flex_code,
         p_column_name            => p_application_column_name,
         p_owner                  => p_owner,
         p_last_update_date       => p_last_update_date,
         p_flexfield_usage_code   => 'Q');

      --
      -- Populate the cross product table.
      --
      populate_kff_segq_assign();

   END IF;

   <<label_done>>
   done('KFF_SEGMENT_QUAL', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_segment_attribute_type,
                                  p_value_attribute_type);
END up_kff_segment_qual;

-- --------------------------------------------------
FUNCTION is_single_structure_kff(p_kff_flx IN kff_flx_type)
  RETURN BOOLEAN
  IS
     l_return BOOLEAN;
BEGIN
   l_return := FALSE;

   IF ((p_kff_flx.set_defining_column_name IS NULL) OR
       (p_kff_flx.application_id = 401 AND p_kff_flx.id_flex_code = 'MSTK') OR
       (p_kff_flx.application_id = 401 AND p_kff_flx.id_flex_code = 'MTLL') OR
       (p_kff_flx.application_id = 401 AND p_kff_flx.id_flex_code = 'MICG') OR
       (p_kff_flx.application_id = 401 AND p_kff_flx.id_flex_code = 'MDSP') OR
       (p_kff_flx.application_id = 401 AND p_kff_flx.id_flex_code = 'SERV')) THEN
      l_return := TRUE;
   END IF;

   RETURN l_return;

END is_single_structure_kff;

-- --------------------------------------------------
PROCEDURE up_kff_structure
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_cross_segment_validation_fla IN VARCHAR2,
   p_dynamic_inserts_allowed_flag IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_freeze_structured_hier_flag  IN VARCHAR2,
   p_shorthand_enabled_flag       IN VARCHAR2,
   p_shorthand_length             IN VARCHAR2,
   p_structure_view_name          IN VARCHAR2,
   p_id_flex_structure_name       IN VARCHAR2,
   p_description                  IN VARCHAR2,
   p_shorthand_prompt             IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_kff_flx    kff_flx_type;
     l_kff_str    kff_str_type;
     l_kff_str_tl kff_str_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_count      NUMBER;
     l_kff_str2   kff_str_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_structure()';
   init('KFF_STRUCTURE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      g_numof_changes_kff_str := g_numof_changes;
      --
      -- Gather WHO Information.
      --
      IF (get_kff_flx(p_application_short_name,
                      p_id_flex_code,
                      l_kff_flx)) THEN
         IF (get_kff_str(l_kff_flx,
                         p_id_flex_structure_code,
                         l_kff_str)) THEN
            NULL;
         END IF;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_kff_str_tl(l_kff_str,
                            userenv('LANG'),
                            l_kff_str_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_str_tl.last_updated_by,
              p_db_last_update_date          => l_kff_str_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating KFF_STRUCTURE.(MLS)');
         END IF;
         fnd_id_flex_structures_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_who                          => l_file_who,
            x_id_flex_structure_name       => p_id_flex_structure_name,
            x_description                  => p_description,
            x_shorthand_prompt             => p_shorthand_prompt);
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_str.last_updated_by,
              p_db_last_update_date          => l_kff_str.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         --
         -- Make sure KFF exists.
         --
         get_kff_flx(p_application_short_name,
                     p_id_flex_code,
                     l_kff_flx);

         --
         -- Check the consistency of single structure KFFs.
         --
         IF (is_single_structure_kff(l_kff_flx)) THEN

            SELECT COUNT(*)
              INTO l_count
              FROM fnd_id_flex_structures
              WHERE application_id = l_kff_flx.application_id
              AND id_flex_code = l_kff_flx.id_flex_code;

            IF (l_count > 1) THEN
               --
               -- There cannot be more than 1 structure.
               --
               raise_error(l_func_name, ERROR_KFF_GENERIC,
                           'Single structure KFF: There are more than 1 structures defined',
                           'Please apply patch 3498448 or one of its replacements');

             ELSIF (l_count = 1) THEN
               --
               -- Make sure primary keys are right.
               --
               SELECT *
                 INTO l_kff_str2
                 FROM fnd_id_flex_structures
                 WHERE application_id = l_kff_flx.application_id
                 AND id_flex_code = l_kff_flx.id_flex_code;

               IF (l_kff_str2.id_flex_structure_code <> p_id_flex_structure_code) THEN
                  raise_error(l_func_name, ERROR_KFF_GENERIC,
                              'Single structure KFF: Structure code does not match. ' ||
                              'Structure Code in DB: ' || l_kff_str2.id_flex_structure_code ||
                              ', Structure Code in LDT: ' || p_id_flex_structure_code,
                              'Please apply patch 3498448 or one of its replacements');
               END IF;

               IF (l_kff_str2.id_flex_num <> 101) THEN
                  fix_id_flex_num(p_application_id  => l_kff_str2.application_id,
                                  p_id_flex_code    => l_kff_str2.id_flex_code,
                                  p_id_flex_num_old => l_kff_str2.id_flex_num,
                                  p_id_flex_num_new => 101);
               END IF;

             ELSIF (l_count = 0) THEN
               --
               -- This is the first time this KFF is being uploaded.
               --
               NULL;
            END IF; -- l_count
         END IF; -- Single structure only KFF

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading KFF_STRUCTURE.(MLS)');
         END IF;
         fnd_id_flex_structures_pkg.load_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_who                          => l_file_who,
            x_concatenated_segment_delimit => p_concatenated_segment_delimit,
            x_cross_segment_validation_fla => p_cross_segment_validation_fla,
            x_dynamic_inserts_allowed_flag => p_dynamic_inserts_allowed_flag,
            x_enabled_flag                 => p_enabled_flag,
            x_freeze_flex_definition_flag  => p_freeze_flex_definition_flag,
            x_freeze_structured_hier_flag  => p_freeze_structured_hier_flag,
            x_shorthand_enabled_flag       => p_shorthand_enabled_flag,
            x_shorthand_length             => p_shorthand_length,
            x_structure_view_name          => p_structure_view_name,
            x_id_flex_structure_name       => p_id_flex_structure_name,
            x_description                  => p_description,
            x_shorthand_prompt             => p_shorthand_prompt);

         --
         -- Make sure id_flex_num is 101 for single structure KFF.
         --
         IF (is_single_structure_kff(l_kff_flx)) THEN
            get_kff_str(l_kff_flx,
                        p_id_flex_structure_code,
                        l_kff_str2);

            IF (l_kff_str2.id_flex_num <> 101) THEN
               fix_id_flex_num(p_application_id  => l_kff_str2.application_id,
                               p_id_flex_code    => l_kff_str2.id_flex_code,
                               p_id_flex_num_old => l_kff_str2.id_flex_num,
                               p_id_flex_num_new => 101);
            END IF;
         END IF;

      END IF; -- p_upload_mode
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
      --
      -- Compile Flex, Generate View.
      --
      IF (g_numof_changes > g_numof_changes_kff_str) THEN
         call_cp(p_mode                       => 'KFF-STR',
                 p_upload_mode                => p_upload_mode,
                 p_application_short_name     => p_application_short_name,
                 p_id_flex_code               => p_id_flex_code,
                 p_id_flex_structure_code     => p_id_flex_structure_code);
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_STRUCTURE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code);
END up_kff_structure;

-- --------------------------------------------------
PROCEDURE up_kff_wf_process
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_wf_item_type                 IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_wf_process_name              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_str   kff_str_type;
     l_kff_wfp   kff_wfp_type;
     l_dummy     NUMBER;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_wf_process()';
   init('KFF_WF_PROCESS', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',WFI:'   || p_wf_item_type ||
            ',WFP:'   || p_wf_process_name);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure KFF and Structure exist.
   --
   get_kff_flx(p_application_short_name,
               p_id_flex_code,
               l_kff_flx);

   get_kff_str(l_kff_flx,
               p_id_flex_structure_code,
               l_kff_str);

   --
   -- Gather WHO Information.
   --
   IF (get_kff_wfp(l_kff_str,
                   p_wf_item_type,
                   l_kff_wfp)) THEN
      NULL;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_kff_wfp.last_updated_by,
        p_db_last_update_date          => l_kff_wfp.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --

   --
   -- Make sure Item Type and Process exist.
   -- Copied from AFFFWFPB.pls
   --
   BEGIN
      SELECT 1
        INTO l_dummy
        FROM wf_item_types_vl
        WHERE name = p_wf_item_type;
   EXCEPTION
      WHEN OTHERS THEN
         --
         -- GEO !!!
         --
         raise_not_exist(l_func_name,
                         'Please create the workflow item type.',
                         'WF Item Type', p_wf_item_type);
   END;
   BEGIN
      SELECT 1
        INTO l_dummy
        FROM wf_runnable_processes_v
        WHERE item_type = p_wf_item_type
        AND process_name = p_wf_process_name;
   EXCEPTION
      WHEN OTHERS THEN
         --
         -- GEO !!!
         --
         raise_not_exist(l_func_name,
                         'Please create the runnable workflow process.',
                         'WF Process Name', p_wf_process_name);
   END;

   IF (g_debug_on) THEN
      debug(l_func_name, 'Updating KFF_WF_PROCESS.(no-TL)');
   END IF;
   UPDATE fnd_flex_workflow_processes SET
     last_updated_by   = l_file_who.last_updated_by,
     last_update_date  = l_file_who.last_update_date,
     last_update_login = l_file_who.last_update_login,
     wf_process_name   = p_wf_process_name
     WHERE application_id = l_kff_flx.application_id
     AND id_flex_code = l_kff_flx.id_flex_code
     AND id_flex_num = l_kff_str.id_flex_num
     AND wf_item_type = p_wf_item_type;

   IF (SQL%notfound) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Inserting KFF_WF_PROCESS.(no-TL)');
      END IF;
      INSERT INTO fnd_flex_workflow_processes
        (
         application_id,
         id_flex_code,
         id_flex_num,
         wf_item_type,

         created_by,
         creation_date,
         last_updated_by,
         last_update_date,
         last_update_login,

         wf_process_name
         )
        VALUES
        (
         l_kff_flx.application_id,
         l_kff_flx.id_flex_code,
         l_kff_str.id_flex_num,
         p_wf_item_type,

         l_file_who.created_by,
         l_file_who.creation_date,
         l_file_who.last_updated_by,
         l_file_who.last_update_date,
         l_file_who.last_update_login,

         p_wf_process_name
         );
   END IF;

   <<label_done>>
   done('KFF_WF_PROCESS', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_wf_item_type);
END up_kff_wf_process;

-- --------------------------------------------------
PROCEDURE up_kff_sh_alias
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_alias_name                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_concatenated_segments        IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_attribute_category           IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_str   kff_str_type;
     l_kff_sha   kff_sha_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_sh_alias()';
   init('KFF_SH_ALIAS', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',SHA:'   || p_alias_name);
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_kff_flx(p_application_short_name,
                   p_id_flex_code,
                   l_kff_flx)) THEN
      IF (get_kff_str(l_kff_flx,
                      p_id_flex_structure_code,
                      l_kff_str)) THEN
         IF (get_kff_sha(l_kff_str,
                         p_alias_name,
                         l_kff_sha)) THEN
            NULL;
         END IF;
      END IF;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_kff_sha.last_updated_by,
        p_db_last_update_date          => l_kff_sha.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- non-MLS translation.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating KFF_SH_ALIAS.(non-MLS)');
      END IF;
      UPDATE fnd_shorthand_flex_aliases SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        description       = Nvl(p_description, description)
        WHERE ((application_id, id_flex_code, id_flex_num) =
               (SELECT application_id, id_flex_code, id_flex_num
                FROM fnd_id_flex_structures
                WHERE application_id = (SELECT application_id
                                        FROM fnd_application
                                        WHERE application_short_name = p_application_short_name)
                AND id_flex_code = p_id_flex_code
                AND id_flex_structure_code = p_id_flex_structure_code))
        AND alias_name = p_alias_name
        AND userenv('LANG') = (SELECT language_code
                               FROM fnd_languages
                               WHERE installed_flag = 'B');
      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'No entity to translate.');
         END IF;
      END IF;
      GOTO label_done;
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Make sure KFF and Structure exist.
      --
      get_kff_flx(p_application_short_name,
                  p_id_flex_code,
                  l_kff_flx);

      get_kff_str(l_kff_flx,
                  p_id_flex_structure_code,
                  l_kff_str);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Updating KFF_SH_ALIAS.(non-MLS)');
      END IF;
      UPDATE fnd_shorthand_flex_aliases SET
        last_updated_by       = l_file_who.last_updated_by,
        last_update_date      = l_file_who.last_update_date,
        last_update_login     = l_file_who.last_update_login,
        concatenated_segments = p_concatenated_segments,
        enabled_flag          = p_enabled_flag,
        start_date_active     = To_date(p_start_date_active, g_date_mask),
        end_date_active       = To_date(p_end_date_active, g_date_mask),
        attribute_category    = p_attribute_category,
        attribute1            = p_attribute1,
        attribute2            = p_attribute2,
        attribute3            = p_attribute3,
        attribute4            = p_attribute4,
        attribute5            = p_attribute5,
        attribute6            = p_attribute6,
        attribute7            = p_attribute7,
        attribute8            = p_attribute8,
        attribute9            = p_attribute9,
        attribute10           = p_attribute10,
        attribute11           = p_attribute11,
        attribute12           = p_attribute12,
        attribute13           = p_attribute13,
        attribute14           = p_attribute14,
        attribute15           = p_attribute15,
        description           = p_description
        WHERE application_id = l_kff_flx.application_id
        AND id_flex_code = l_kff_flx.id_flex_code
        AND id_flex_num = l_kff_str.id_flex_num
        AND alias_name = p_alias_name;

      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Inserting KFF_SH_ALIAS.(non-MLS)');
         END IF;
         INSERT INTO fnd_shorthand_flex_aliases
           (
            application_id,
            id_flex_code,
            id_flex_num,
            alias_name,

            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,

            concatenated_segments,
            enabled_flag,
            start_date_active,
            end_date_active,
            attribute_category,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            description
            )
           VALUES
           (
            l_kff_flx.application_id,
            l_kff_flx.id_flex_code,
            l_kff_str.id_flex_num,
            p_alias_name,

            l_file_who.created_by,
            l_file_who.creation_date,
            l_file_who.last_updated_by,
            l_file_who.last_update_date,
            l_file_who.last_update_login,

            p_concatenated_segments,
            p_enabled_flag,
            To_date(p_start_date_active, g_date_mask),
            To_date(p_end_date_active, g_date_mask),
            p_attribute_category,
            p_attribute1,
            p_attribute2,
            p_attribute3,
            p_attribute4,
            p_attribute5,
            p_attribute6,
            p_attribute7,
            p_attribute8,
            p_attribute9,
            p_attribute10,
            p_attribute11,
            p_attribute12,
            p_attribute13,
            p_attribute14,
            p_attribute15,
            p_description
            );
      END IF;
   END IF;

   <<label_done>>
   done('KFF_SH_ALIAS', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_alias_name);
END up_kff_sh_alias;

-- --------------------------------------------------
FUNCTION check_cvr_trigger(p_trigger_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
     l_func_name VARCHAR2(80);
     l_status    user_triggers.status%TYPE;
BEGIN
   l_func_name := g_api_name || 'check_cvr_trigger()';
   --
   -- Get the status of this trigger
   --
   SELECT status
     INTO l_status
     FROM user_triggers
     WHERE trigger_name = p_trigger_name;


   IF (l_status <> 'ENABLED') THEN
      RETURN (p_trigger_name || ' trigger is not ENABLED.' || g_newline);
   END IF;

   RETURN NULL;
EXCEPTION
   WHEN no_data_found THEN
      RETURN (p_trigger_name || ' trigger does not exist.' || g_newline);
   WHEN OTHERS THEN
      raise_when_others(l_func_name,
                        p_trigger_name);
END check_cvr_trigger;

-- --------------------------------------------------
PROCEDURE check_cvr_triggers
  IS
     l_func_name  VARCHAR2(80);
     l_vc2 VARCHAR2(32000);
BEGIN
   l_func_name := g_api_name || 'check_cvr_triggers()';
   l_vc2 := NULL;
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VALIDATION_RULES_T1');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VALIDATION_RULES_T2');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VALIDATION_RULES_T3');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VAL_RULE_LINES_T1');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VAL_RULE_LINES_T2');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VAL_RULE_LINES_T3');
   l_vc2 := l_vc2 || check_cvr_trigger('FND_FLEX_VAL_RULE_LINES_T4');

   IF (l_vc2 IS NOT NULL) THEN
      raise_error(l_func_name, ERROR_KFF_GENERIC,
                  l_vc2,
                  'Please run $FND_TOP/patch/115/sql/afeffs04.sql');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      raise_when_others(l_func_name);
END check_cvr_triggers;

-- --------------------------------------------------
PROCEDURE up_kff_cvr_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_flex_validation_rule_name    IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_error_segment_column_name    IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_error_message_text           IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_kff_flx    kff_flx_type;
     l_kff_str    kff_str_type;
     l_kff_cvr    kff_cvr_type;
     l_kff_cvr_tl kff_cvr_tl_type;
     l_file_who   fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_cvr_rule()';
   --
   -- CVR stats table is populated by triggers.
   --
   init('KFF_CVR_RULE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',CVR:'   || p_flex_validation_rule_name);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_kff_flx(p_application_short_name,
                      p_id_flex_code,
                      l_kff_flx)) THEN
         IF (get_kff_str(l_kff_flx,
                         p_id_flex_structure_code,
                         l_kff_str)) THEN
            IF (get_kff_cvr(l_kff_str,
                            p_flex_validation_rule_name,
                            l_kff_cvr)) THEN
               NULL;
            END IF;
         END IF;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_kff_cvr_tl(l_kff_cvr,
                            userenv('LANG'),
                            l_kff_cvr_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_cvr_tl.last_updated_by,
              p_db_last_update_date          => l_kff_cvr_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating KFF_CVR_RULE.(MLS)');
         END IF;
         fnd_flex_vdation_rules_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_flex_validation_rule_name    => p_flex_validation_rule_name,
            x_who                          => l_file_who,
            x_error_message_text           => p_error_message_text,
            x_description                  => p_description);
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_cvr.last_updated_by,
              p_db_last_update_date          => l_kff_cvr.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         --
         -- Make sure KFF and Structure exist.
         --
         get_kff_flx(p_application_short_name,
                     p_id_flex_code,
                     l_kff_flx);

         get_kff_str(l_kff_flx,
                     p_id_flex_structure_code,
                     l_kff_str);

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading KFF_CVR_RULE.(MLS)');
         END IF;
         fnd_flex_vdation_rules_pkg.load_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_flex_validation_rule_name    => p_flex_validation_rule_name,
            x_who                          => l_file_who,
            x_enabled_flag                 => p_enabled_flag,
            x_error_segment_column_name    => p_error_segment_column_name,
            x_start_date_active            => To_date(p_start_date_active,
                                                      g_date_mask),
            x_end_date_active              => To_date(p_end_date_active,
                                                      g_date_mask),
            x_error_message_text           => p_error_message_text,
            x_description                  => p_description);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         NULL;
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_CVR_RULE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_flex_validation_rule_name);

      BEGIN
         check_cvr_triggers();
      EXCEPTION
         WHEN OTHERS THEN
            report_public_api_exception(l_func_name,
                                        p_upload_phase,
                                        p_application_short_name,
                                        p_id_flex_code,
                                        p_id_flex_structure_code,
                                        p_flex_validation_rule_name);
      END;
END up_kff_cvr_rule;

-- --------------------------------------------------
PROCEDURE up_kff_cvr_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_flex_validation_rule_name    IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_concatenated_segments_low    IN VARCHAR2,
   p_concatenated_segments_high   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_str   kff_str_type;
     l_kff_cvr   kff_cvr_type;
     l_kff_cvl   kff_cvl_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_cvr_line()';
   --
   -- CVR stats and I/E tables are populated by triggers.
   --
   init('KFF_CVR_LINE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',CVR:'   || p_flex_validation_rule_name ||
            ',IE:'    || p_include_exclude_indicator ||
            ',LOW:'   || p_concatenated_segments_low ||
            ',HIGH:'  || p_concatenated_segments_high);
   END IF;

   --
   -- Gather WHO Information.
   --
   IF (get_kff_flx(p_application_short_name,
                   p_id_flex_code,
                   l_kff_flx)) THEN
      IF (get_kff_str(l_kff_flx,
                      p_id_flex_structure_code,
                      l_kff_str)) THEN
         IF (get_kff_cvr(l_kff_str,
                         p_flex_validation_rule_name,
                         l_kff_cvr)) THEN
            IF (get_kff_cvl(l_kff_cvr,
                            p_include_exclude_indicator,
                            p_concatenated_segments_low,
                            p_concatenated_segments_high,
                            l_kff_cvl)) THEN
               NULL;
            END IF;
         END IF;
      END IF;
   END IF;

   --
   -- Check WHO Information.
   --
   IF (NOT is_upload_allowed
       (p_custom_mode                  => p_custom_mode,
        p_file_owner                   => p_owner,
        p_file_last_update_date        => p_last_update_date,
        p_db_last_updated_by           => l_kff_cvl.last_updated_by,
        p_db_last_update_date          => l_kff_cvl.last_update_date,
        x_file_who                     => l_file_who)) THEN
      IF (g_debug_on) THEN
         debug(l_func_name, 'Upload is not allowed because of customization.');
      END IF;
      GOTO label_done;
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- non-MLS translation.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'Translating KFF_CVR_LINE.(non-MLS)');
      END IF;
      UPDATE fnd_flex_validation_rule_lines SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        description       = Nvl(p_description, description)
        WHERE ((application_id, id_flex_code, id_flex_num) =
               (SELECT application_id, id_flex_code, id_flex_num
                FROM fnd_id_flex_structures
                WHERE application_id = (SELECT application_id
                                        FROM fnd_application
                                        WHERE application_short_name = p_application_short_name)
                AND id_flex_code = p_id_flex_code
                AND id_flex_structure_code = p_id_flex_structure_code))
        AND flex_validation_rule_name = p_flex_validation_rule_name
        AND include_exclude_indicator = p_include_exclude_indicator
        AND concatenated_segments_low = p_concatenated_segments_low
        AND concatenated_segments_high = p_concatenated_segments_high
        AND userenv('LANG') = (SELECT language_code
                               FROM fnd_languages
                               WHERE installed_flag = 'B');
      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'No entity to translate.');
         END IF;
      END IF;
      GOTO label_done;
    ELSE
      --
      -- Usual upload.
      --

      --
      -- Make sure KFF, Structure and CVR exist.
      --
      get_kff_flx(p_application_short_name,
                  p_id_flex_code,
                  l_kff_flx);

      get_kff_str(l_kff_flx,
                  p_id_flex_structure_code,
                  l_kff_str);

      get_kff_cvr(l_kff_str,
                  p_flex_validation_rule_name,
                  l_kff_cvr);

      IF (g_debug_on) THEN
         debug(l_func_name, 'Updating KFF_CVR_LINE.(non-MLS)');
      END IF;
      UPDATE fnd_flex_validation_rule_lines SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        enabled_flag      = p_enabled_flag,
        description       = p_description
        WHERE application_id = l_kff_flx.application_id
        AND id_flex_code = l_kff_flx.id_flex_code
        AND id_flex_num = l_kff_str.id_flex_num
        AND flex_validation_rule_name = l_kff_cvr.flex_validation_rule_name
        AND include_exclude_indicator = p_include_exclude_indicator
        AND concatenated_segments_low = p_concatenated_segments_low
        AND concatenated_segments_high = p_concatenated_segments_high;

      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Inserting KFF_CVR_LINE.(non-MLS)');
         END IF;
         --
         -- rule_line_id is populated by fnd_flex_val_rule_lines_t1 trigger.
         --
         INSERT INTO fnd_flex_validation_rule_lines
           (
            application_id,
            id_flex_code,
            id_flex_num,
            flex_validation_rule_name,
            include_exclude_indicator,
            concatenated_segments_low,
            concatenated_segments_high,

            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,

            enabled_flag,
            description
            )
           VALUES
           (
            l_kff_flx.application_id,
            l_kff_flx.id_flex_code,
            l_kff_str.id_flex_num,
            l_kff_cvr.flex_validation_rule_name,
            p_include_exclude_indicator,
            p_concatenated_segments_low,
            p_concatenated_segments_high,

            l_file_who.created_by,
            l_file_who.creation_date,
            l_file_who.last_updated_by,
            l_file_who.last_update_date,
            l_file_who.last_update_login,

            p_enabled_flag,
            p_description
            );
      END IF;
   END IF;

   <<label_done>>
   done('KFF_CVR_LINE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_flex_validation_rule_name,
                                  p_include_exclude_indicator,
                                  p_concatenated_segments_low,
                                  p_concatenated_segments_high);

      BEGIN
         check_cvr_triggers();
      EXCEPTION
         WHEN OTHERS THEN
            report_public_api_exception(l_func_name,
                                        p_upload_phase,
                                        p_application_short_name,
                                        p_id_flex_code,
                                        p_id_flex_structure_code,
                                        p_flex_validation_rule_name,
                                        p_include_exclude_indicator,
                                        p_concatenated_segments_low,
                                        p_concatenated_segments_high);
      END;
END up_kff_cvr_line;

-- --------------------------------------------------
PROCEDURE up_kff_segment
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_segment_name                 IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_segment_num                  IN VARCHAR2,
   p_application_column_index_fla IN VARCHAR2,
   p_enabled_flag                 IN VARCHAR2,
   p_required_flag                IN VARCHAR2,
   p_display_flag                 IN VARCHAR2,
   p_display_size                 IN VARCHAR2,
   p_security_enabled_flag        IN VARCHAR2,
   p_maximum_description_len      IN VARCHAR2,
   p_concatenation_description_le IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_range_code                   IN VARCHAR2,
   p_default_type                 IN VARCHAR2,
   p_default_value                IN VARCHAR2,
   p_runtime_property_function    IN VARCHAR2 DEFAULT NULL,
   p_additional_where_clause      IN VARCHAR2 DEFAULT NULL,
   p_form_left_prompt             IN VARCHAR2,
   p_form_above_prompt            IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_kff_flx    kff_flx_type;
     l_kff_str    kff_str_type;
     l_kff_seg    kff_seg_type;
     l_kff_seg_tl kff_seg_tl_type;
     l_vst_set    vst_set_type;
     l_col        col_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_segment()';
   init('KFF_SEGMENT', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',SEG:'   || p_segment_name ||
            ',COL:'   || p_application_column_name);
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_kff_flx(p_application_short_name,
                      p_id_flex_code,
                      l_kff_flx)) THEN
         IF (get_kff_str(l_kff_flx,
                         p_id_flex_structure_code,
                         l_kff_str)) THEN
            IF (get_kff_seg(l_kff_str,
                            p_application_column_name,
                            l_kff_seg)) THEN
               NULL;
            END IF;
         END IF;
      END IF;

      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --

         --
         -- Gather WHO Information.
         --
         IF (get_kff_seg_tl(l_kff_seg,
                            userenv('LANG'),
                            l_kff_seg_tl)) THEN
            NULL;
         END IF;

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_seg_tl.last_updated_by,
              p_db_last_update_date          => l_kff_seg_tl.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating KFF_SEGMENT.(MLS)');
         END IF;
         fnd_id_flex_segments_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_application_column_name      => p_application_column_name,
            x_who                          => l_file_who,
            x_form_left_prompt             => p_form_left_prompt,
            x_form_above_prompt            => p_form_above_prompt,
            x_description                  => p_description);
         GOTO label_done;
       ELSE
         --
         -- Usual upload.
         --

         --
         -- Check WHO Information.
         --
         IF (NOT is_upload_allowed
             (p_custom_mode                  => p_custom_mode,
              p_file_owner                   => p_owner,
              p_file_last_update_date        => p_last_update_date,
              p_db_last_updated_by           => l_kff_seg.last_updated_by,
              p_db_last_update_date          => l_kff_seg.last_update_date,
              x_file_who                     => l_file_who)) THEN
            IF (g_debug_on) THEN
               debug(l_func_name, 'Upload is not allowed because of customization.');
            END IF;
            GOTO label_done;
         END IF;

         --
         -- Make sure KFF, Structure and Column exist.
         --
         get_kff_flx(p_application_short_name,
                     p_id_flex_code,
                     l_kff_flx);

         get_kff_str(l_kff_flx,
                     p_id_flex_structure_code,
                     l_kff_str);

         get_col(l_kff_flx.table_application_id,
                 l_kff_flx.application_table_name,
                 p_application_column_name,
                 l_col);

         IF (((l_col.flexfield_application_id IS NULL) OR
              (l_col.flexfield_application_id = l_kff_flx.application_id)) AND
             ((l_col.flexfield_name IS NULL) OR
              (l_col.flexfield_name = l_kff_flx.id_flex_code)) AND
             (l_col.flexfield_usage_code = 'K')) THEN
            NULL;
          ELSE
            raise_error(l_func_name, ERROR_KFF_COL_NOT_REG,
                        'COL:' || l_col.column_name ||
                        ' is not registered properly. It is registered as ' ||
                        'APP Id:' || To_char(l_col.flexfield_application_id) ||
                        ' Flex Name:' || l_col.flexfield_name ||
                        ' Usage Code:' || l_col.flexfield_usage_code,
                        'Please use Application Developer:' ||
                        'Flexfield->Key->Register form and ' ||
                        'make sure column is enabled. If this column is ' ||
                        'not in the list, it means it is used by another ' ||
                        'flexfield and you cannot use it');
         END IF;

         IF (p_flex_value_set_name IS NOT NULL) THEN
            get_vst_set(p_flex_value_set_name, l_vst_set);
         END IF;

         IF (g_debug_on) THEN
            debug(l_func_name, 'Uploading KFF_SEGMENT.(MLS)');
         END IF;
         fnd_id_flex_segments_pkg.load_row
           (x_application_short_name       => p_application_short_name,
            x_id_flex_code                 => p_id_flex_code,
            x_id_flex_structure_code       => p_id_flex_structure_code,
            x_application_column_name      => p_application_column_name,
            x_who                          => l_file_who,
            x_segment_name                 => p_segment_name,
            x_segment_num                  => p_segment_num,
            x_application_column_index_fla => p_application_column_index_fla,
            x_enabled_flag                 => p_enabled_flag,
            x_required_flag                => p_required_flag,
            x_display_flag                 => p_display_flag,
            x_display_size                 => p_display_size,
            x_security_enabled_flag        => p_security_enabled_flag,
            x_maximum_description_len      => p_maximum_description_len,
            x_concatenation_description_le => p_concatenation_description_le,
            x_flex_value_set_name          => p_flex_value_set_name,
            x_range_code                   => p_range_code,
            x_default_type                 => p_default_type,
            x_default_value                => p_default_value,
            x_runtime_property_function    => p_runtime_property_function,
            x_additional_where_clause      => p_additional_where_clause,
            x_form_left_prompt             => p_form_left_prompt,
            x_form_above_prompt            => p_form_above_prompt,
            x_description                  => p_description);
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      IF (p_upload_mode = 'NLS') THEN
         --
         -- MLS translation.
         --
         NULL;
       ELSE
         --
         -- Usual upload.
         --
         --
         -- Populate cross product tables.
         --
         populate_kff_flexq_assign();
         populate_kff_segq_assign();
      END IF;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_SEGMENT', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_application_column_name,
                                  p_segment_name);
END up_kff_segment;

-- --------------------------------------------------
PROCEDURE up_kff_flexq_assign
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_attribute_value              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_flq   kff_flq_type;
     l_kff_str   kff_str_type;
     l_kff_seg   kff_seg_type;
     l_kff_fqa   kff_fqa_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_flexq_assign()';
   init('KFF_FLEXQ_ASSIGN', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  ||
            ',CMODE:' || p_custom_mode  ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',COL:'   || p_application_column_name ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',AVAL:'  || p_attribute_value);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Make sure KFF, Flex Qual, Structure and Segment exist.
   --
   get_kff_flx(p_application_short_name,
               p_id_flex_code,
               l_kff_flx);

   get_kff_flq(l_kff_flx,
               p_segment_attribute_type,
               l_kff_flq);

   get_kff_str(l_kff_flx,
               p_id_flex_structure_code,
               l_kff_str);

   get_kff_seg(l_kff_str,
               p_application_column_name,
               l_kff_seg);

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Gather WHO Information.
      --
      IF (get_kff_fqa(l_kff_flq,
                      l_kff_seg,
                      l_kff_fqa)) THEN
         NULL;
      END IF;

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_kff_fqa.last_updated_by,
           p_db_last_update_date          => l_kff_fqa.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
         END IF;
         GOTO label_done;
      END IF;

      --
      -- Usual upload.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'Updating KFF_FLEXQ_ASSIGN.(no-TL)');
      END IF;
      UPDATE fnd_segment_attribute_values SET
        last_updated_by   = l_file_who.last_updated_by,
        last_update_date  = l_file_who.last_update_date,
        last_update_login = l_file_who.last_update_login,
        attribute_value   = p_attribute_value
        WHERE application_id = l_kff_flx.application_id
        AND id_flex_code = l_kff_flx.id_flex_code
        AND id_flex_num = l_kff_str.id_flex_num
        AND application_column_name = l_kff_seg.application_column_name
        AND segment_attribute_type = l_kff_flq.segment_attribute_type;

      IF (SQL%notfound) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Inserting KFF_FLEXQ_ASSIGN.(no-TL)');
         END IF;
         INSERT INTO fnd_segment_attribute_values
           (
            application_id,
            id_flex_code,
            id_flex_num,
            application_column_name,
            segment_attribute_type,

            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,

            attribute_value
            )
           VALUES
           (
            l_kff_flx.application_id,
            l_kff_flx.id_flex_code,
            l_kff_str.id_flex_num,
            l_kff_seg.application_column_name,
            l_kff_flq.segment_attribute_type,

            l_file_who.created_by,
            l_file_who.creation_date,
            l_file_who.last_updated_by,
            l_file_who.last_update_date,
            l_file_who.last_update_login,

            p_attribute_value
            );
      END IF;
    ELSIF (p_upload_phase = 'END') THEN
      --
      -- Usual upload.
      --
      NULL;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_FLEXQ_ASSIGN', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_application_column_name,
                                  p_segment_attribute_type);
END up_kff_flexq_assign;

-- --------------------------------------------------
PROCEDURE up_kff_segq_assign
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_id_flex_structure_code       IN VARCHAR2,
   p_application_column_name      IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2 DEFAULT NULL,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_kff_flx   kff_flx_type;
     l_kff_str   kff_str_type;
     l_kff_seg   kff_seg_type;
     l_kff_flq   kff_flq_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_segq_assign()';
   init('KFF_SEGQ_ASSIGN', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',STR:'   || p_id_flex_structure_code ||
            ',COL:'   || p_application_column_name ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   --
   -- Usual upload.
   --

   --
   -- Make sure KFF, Flex Qual, Structure and Segment exist.
   --
   get_kff_flx(p_application_short_name,
               p_id_flex_code,
               l_kff_flx);

   get_kff_flq(l_kff_flx,
               p_segment_attribute_type,
               l_kff_flq);

   get_kff_str(l_kff_flx,
               p_id_flex_structure_code,
               l_kff_str);

   get_kff_seg(l_kff_str,
               p_application_column_name,
               l_kff_seg);

   IF (l_kff_seg.flex_value_set_id IS NOT NULL) THEN
      populate_kff_segq_assign();
   END IF;

   <<label_done>>
   done('KFF_SEGQ_ASSIGN', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_id_flex_structure_code,
                                  p_application_column_name,
                                  p_segment_attribute_type,
                                  p_value_attribute_type);
END up_kff_segq_assign;

-- --------------------------------------------------
PROCEDURE up_kff_qualifier
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
     l_vst_set   vst_set_type;
     l_kff_flx   kff_flx_type;
     l_kff_flq   kff_flq_type;
     l_kff_sgq   kff_sgq_type;
     l_file_who  fnd_flex_loader_apis.who_type;
BEGIN
   l_func_name := g_api_name || 'up_kff_qualifier()';
   init('KFF_QUALIFIER', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            'UMODE:'  || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',VSET:'  || p_flex_value_set_name ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type ||
            ',ORDER:' || p_assignment_order);
   END IF;

   IF (p_upload_mode = 'NLS') THEN
      --
      -- No translation here.
      --
      IF (g_debug_on) THEN
         debug(l_func_name, 'No translation here.');
      END IF;
      GOTO label_done;
   END IF;

   IF (p_upload_phase = 'BEGIN') THEN
      --
      -- Usual upload.
      --

      --
      -- Make sure Value Set exists.
      --
      get_vst_set(p_flex_value_set_name, l_vst_set);

      --
      -- Check WHO Information.
      --
      IF (NOT is_upload_allowed
          (p_custom_mode                  => p_custom_mode,
           p_file_owner                   => p_owner,
           p_file_last_update_date        => p_last_update_date,
           p_db_last_updated_by           => l_vst_set.last_updated_by,
           p_db_last_update_date          => l_vst_set.last_update_date,
           x_file_who                     => l_file_who)) THEN
         IF (g_debug_on) THEN
            debug(l_func_name, 'Upload is not allowed because of customization.');
            debug(l_func_name, 'For data integrity upload must be done.');
         END IF;
         --
         -- Clear the customization message
         --
         fnd_message.clear();
      END IF;

      --
      -- Make sure KFF, Flexfield Qualifier and Segment Qualifier exist.
      --
      get_kff_flx(p_application_short_name,
                  p_id_flex_code,
                  l_kff_flx);
      get_kff_flq(l_kff_flx,
                  p_segment_attribute_type,
                  l_kff_flq);
      get_kff_sgq(l_kff_flq,
                  p_value_attribute_type,
                  l_kff_sgq);

      --
      -- Populate cross product tables.
      --
      populate_kff_flexq_assign();
      populate_kff_segq_assign();
    ELSIF (p_upload_phase = 'END') THEN
      --
      -- Usual upload.
      --
      NULL;
    ELSE
      raise_error(l_func_name, ERROR_UNKNOWN_UP_PHASE, 'Unknown UPLOAD_PHASE');
   END IF;

   <<label_done>>
   done('KFF_QUALIFIER', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_flex_value_set_name,
                                  p_segment_attribute_type,
                                  p_value_attribute_type);
END up_kff_qualifier;

-- --------------------------------------------------
PROCEDURE up_kff_qualifier_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_flex_value_set_name          IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_compiled_value_attribute_val IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_kff_qualifier_value()';
   init('KFF_QUALIFIER_VALUE', p_upload_phase);
   IF (g_debug_on) THEN
      debug(l_func_name,
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode ||
            ',CMODE:' || p_custom_mode ||
            ',APPS:'  || p_application_short_name ||
            ',KFF:'   || p_id_flex_code ||
            ',VSET:'  || p_flex_value_set_name ||
            ',FLEXQ:' || p_segment_attribute_type ||
            ',SEGQ:'  || p_value_attribute_type ||
            ',PRNT:'  || p_parent_flex_value_low ||
            ',VAL:'   || p_flex_value ||
            ',CVAL:'  || p_compiled_value_attribute_val);
   END IF;

   upload_value_qualifier_value
     (p_caller_entity                => 'KFF_QUALIFIER_VALUE',
      p_upload_phase                 => p_upload_phase,
      p_upload_mode                  => p_upload_mode,
      p_custom_mode                  => p_custom_mode,
      p_flex_value_set_name          => p_flex_value_set_name,
      p_application_short_name       => p_application_short_name,
      p_id_flex_code                 => p_id_flex_code,
      p_segment_attribute_type       => p_segment_attribute_type,
      p_value_attribute_type         => p_value_attribute_type,
      p_parent_flex_value_low        => p_parent_flex_value_low,
      p_flex_value                   => p_flex_value,
      p_owner                        => p_owner,
      p_last_update_date             => p_last_update_date,
      p_compiled_value_attribute_val => p_compiled_value_attribute_val);

   <<label_done>>
   done('KFF_QUALIFIER_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      report_public_api_exception(l_func_name,
                                  p_upload_phase,
                                  p_application_short_name,
                                  p_id_flex_code,
                                  p_flex_value_set_name,
                                  p_segment_attribute_type,
                                  p_value_attribute_type,
                                  p_parent_flex_value_low,
                                  p_flex_value);
END up_kff_qualifier_value;

-- --------------------------------------------------
FUNCTION get_qualifier_value
  (p_compiled_value_attributes    IN VARCHAR2,
   p_assignment_order             IN VARCHAR2)
  RETURN VARCHAR2
  IS
     l_newline        VARCHAR2(10);
     l_newline_length NUMBER;
     l_pos1           NUMBER;
     l_pos2           NUMBER;
     l_cva            VARCHAR2(32000);
BEGIN
   l_newline := fnd_global.newline; -- for pragma rnps.
   l_newline_length := Length(l_newline);

   l_cva := l_newline || p_compiled_value_attributes || l_newline;
   l_pos1 := Instr(l_cva, l_newline, 1, p_assignment_order);
   l_pos2 := Instr(l_cva, l_newline, 1, p_assignment_order + 1);
   RETURN(Substr(l_cva, l_pos1 + l_newline_length,
                 l_pos2 - l_pos1 - l_newline_length));
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END get_qualifier_value;

/****** Should be removed later - begin ******/
-- ==================================================
--  VALUE_SECURITY_RULE
-- ==================================================
PROCEDURE up_value_security_rule
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2,
   p_error_message                IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_value_security_rule()';
   init('VALUE_SECURITY_RULE', p_upload_phase);
   up_vset_security_rule
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_flex_value_rule_name            => p_flex_value_rule_name,
      p_parent_flex_value_low           => p_parent_flex_value_low,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_parent_flex_value_high          => p_parent_flex_value_high,
      p_error_message                   => p_error_message,
      p_description                     => p_description);
   <<label_done>>
   done('VALUE_SECURITY_RULE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_value_security_rule;

-- --------------------------------------------------
PROCEDURE up_vsec_line
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_include_exclude_indicator    IN VARCHAR2,
   p_flex_value_low               IN VARCHAR2,
   p_flex_value_high              IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_vsec_line()';
   init('VSEC_LINE', p_upload_phase);
   up_vset_security_line
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_flex_value_rule_name            => p_flex_value_rule_name,
      p_parent_flex_value_low           => p_parent_flex_value_low,
      p_include_exclude_indicator       => p_include_exclude_indicator,
      p_flex_value_low                  => p_flex_value_low,
      p_flex_value_high                 => p_flex_value_high,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_parent_flex_value_high          => p_parent_flex_value_high);
   <<label_done>>
   done('VSEC_LINE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_vsec_line;

-- --------------------------------------------------
PROCEDURE up_vsec_usage
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_flex_value_rule_name         IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_application_short_name       IN VARCHAR2,
   p_responsibility_key           IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_parent_flex_value_high       IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_vsec_usage()';
   init('VSEC_USAGE', p_upload_phase);
   up_vset_security_usage
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_flex_value_rule_name            => p_flex_value_rule_name,
      p_parent_flex_value_low           => p_parent_flex_value_low,
      p_application_short_name          => p_application_short_name,
      p_responsibility_key              => p_responsibility_key,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_parent_flex_value_high          => p_parent_flex_value_high);
   <<label_done>>
   done('VSEC_USAGE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_vsec_usage;

-- ==================================================
-- VALUE_ROLLUP_GROUP
-- ==================================================
PROCEDURE up_value_rollup_group
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_hierarchy_code               IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_hierarchy_name               IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_value_rollup_group()';
   init('VALUE_ROLLUP_GROUP', p_upload_phase);
   up_vset_rollup_group
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_hierarchy_code                  => p_hierarchy_code,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_hierarchy_name                  => p_hierarchy_name,
      p_description                     => p_description);
   <<label_done>>
   done('VALUE_ROLLUP_GROUP', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_value_rollup_group;

-- ==================================================
-- VALUE_SET_VALUE
-- ==================================================
PROCEDURE up_value_set_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_enabled_flag                 IN VARCHAR2,
   p_summary_flag                 IN VARCHAR2,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2,
   p_parent_flex_value_high       IN VARCHAR2,
   p_rollup_flex_value_set_name   IN VARCHAR2,
   p_rollup_hierarchy_code        IN VARCHAR2,
   p_hierarchy_level              IN VARCHAR2,
   p_compiled_value_attributes    IN VARCHAR2,
   p_value_category               IN VARCHAR2,
   p_attribute1                   IN VARCHAR2,
   p_attribute2                   IN VARCHAR2,
   p_attribute3                   IN VARCHAR2,
   p_attribute4                   IN VARCHAR2,
   p_attribute5                   IN VARCHAR2,
   p_attribute6                   IN VARCHAR2,
   p_attribute7                   IN VARCHAR2,
   p_attribute8                   IN VARCHAR2,
   p_attribute9                   IN VARCHAR2,
   p_attribute10                  IN VARCHAR2,
   p_attribute11                  IN VARCHAR2,
   p_attribute12                  IN VARCHAR2,
   p_attribute13                  IN VARCHAR2,
   p_attribute14                  IN VARCHAR2,
   p_attribute15                  IN VARCHAR2,
   p_attribute16                  IN VARCHAR2,
   p_attribute17                  IN VARCHAR2,
   p_attribute18                  IN VARCHAR2,
   p_attribute19                  IN VARCHAR2,
   p_attribute20                  IN VARCHAR2,
   p_attribute21                  IN VARCHAR2,
   p_attribute22                  IN VARCHAR2,
   p_attribute23                  IN VARCHAR2,
   p_attribute24                  IN VARCHAR2,
   p_attribute25                  IN VARCHAR2,
   p_attribute26                  IN VARCHAR2,
   p_attribute27                  IN VARCHAR2,
   p_attribute28                  IN VARCHAR2,
   p_attribute29                  IN VARCHAR2,
   p_attribute30                  IN VARCHAR2,
   p_attribute31                  IN VARCHAR2,
   p_attribute32                  IN VARCHAR2,
   p_attribute33                  IN VARCHAR2,
   p_attribute34                  IN VARCHAR2,
   p_attribute35                  IN VARCHAR2,
   p_attribute36                  IN VARCHAR2,
   p_attribute37                  IN VARCHAR2,
   p_attribute38                  IN VARCHAR2,
   p_attribute39                  IN VARCHAR2,
   p_attribute40                  IN VARCHAR2,
   p_attribute41                  IN VARCHAR2,
   p_attribute42                  IN VARCHAR2,
   p_attribute43                  IN VARCHAR2,
   p_attribute44                  IN VARCHAR2,
   p_attribute45                  IN VARCHAR2,
   p_attribute46                  IN VARCHAR2,
   p_attribute47                  IN VARCHAR2,
   p_attribute48                  IN VARCHAR2,
   p_attribute49                  IN VARCHAR2,
   p_attribute50                  IN VARCHAR2,
   p_flex_value_meaning           IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_value_set_value()';
   init('VALUE_SET_VALUE', p_upload_phase);
   up_vset_value
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_parent_flex_value_low           => p_parent_flex_value_low,
      p_flex_value                      => p_flex_value,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_enabled_flag                    => p_enabled_flag,
      p_summary_flag                    => p_summary_flag,
      p_start_date_active               => p_start_date_active,
      p_end_date_active                 => p_end_date_active,
      p_parent_flex_value_high          => p_parent_flex_value_high,
      p_rollup_hierarchy_code           => p_rollup_hierarchy_code,
      p_hierarchy_level                 => p_hierarchy_level,
      p_compiled_value_attributes       => p_compiled_value_attributes,
      p_value_category                  => p_value_category,
      p_attribute1                      => p_attribute1,
      p_attribute2                      => p_attribute2,
      p_attribute3                      => p_attribute3,
      p_attribute4                      => p_attribute4,
      p_attribute5                      => p_attribute5,
      p_attribute6                      => p_attribute6,
      p_attribute7                      => p_attribute7,
      p_attribute8                      => p_attribute8,
      p_attribute9                      => p_attribute9,
      p_attribute10                     => p_attribute10,
      p_attribute11                     => p_attribute11,
      p_attribute12                     => p_attribute12,
      p_attribute13                     => p_attribute13,
      p_attribute14                     => p_attribute14,
      p_attribute15                     => p_attribute15,
      p_attribute16                     => p_attribute16,
      p_attribute17                     => p_attribute17,
      p_attribute18                     => p_attribute18,
      p_attribute19                     => p_attribute19,
      p_attribute20                     => p_attribute20,
      p_attribute21                     => p_attribute21,
      p_attribute22                     => p_attribute22,
      p_attribute23                     => p_attribute23,
      p_attribute24                     => p_attribute24,
      p_attribute25                     => p_attribute25,
      p_attribute26                     => p_attribute26,
      p_attribute27                     => p_attribute27,
      p_attribute28                     => p_attribute28,
      p_attribute29                     => p_attribute29,
      p_attribute30                     => p_attribute30,
      p_attribute31                     => p_attribute31,
      p_attribute32                     => p_attribute32,
      p_attribute33                     => p_attribute33,
      p_attribute34                     => p_attribute34,
      p_attribute35                     => p_attribute35,
      p_attribute36                     => p_attribute36,
      p_attribute37                     => p_attribute37,
      p_attribute38                     => p_attribute38,
      p_attribute39                     => p_attribute39,
      p_attribute40                     => p_attribute40,
      p_attribute41                     => p_attribute41,
      p_attribute42                     => p_attribute42,
      p_attribute43                     => p_attribute43,
      p_attribute44                     => p_attribute44,
      p_attribute45                     => p_attribute45,
      p_attribute46                     => p_attribute46,
      p_attribute47                     => p_attribute47,
      p_attribute48                     => p_attribute48,
      p_attribute49                     => p_attribute49,
      p_attribute50                     => p_attribute50,
      p_attribute_sort_order            => NULL,
      p_flex_value_meaning              => p_flex_value_meaning,
      p_description                     => p_description);
   <<label_done>>
   done('VALUE_SET_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_value_set_value;

-- --------------------------------------------------
PROCEDURE up_val_norm_hierarchy
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value            IN VARCHAR2,
   p_range_attribute              IN VARCHAR2,
   p_child_flex_value_low         IN VARCHAR2,
   p_child_flex_value_high        IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_start_date_active            IN VARCHAR2,
   p_end_date_active              IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_val_norm_hierarchy()';
   init('VAL_NORM_HIERARCHY', p_upload_phase);
   up_vset_value_hierarchy
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_parent_flex_value               => p_parent_flex_value,
      p_range_attribute                 => p_range_attribute,
      p_child_flex_value_low            => p_child_flex_value_low,
      p_child_flex_value_high           => p_child_flex_value_high,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_start_date_active               => p_start_date_active,
      p_end_date_active                 => p_end_date_active);
   <<label_done>>
   done('VAL_NORM_HIERARCHY', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_val_norm_hierarchy;

-- --------------------------------------------------
PROCEDURE up_val_qual_value
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_flex_value_set_name          IN VARCHAR2,
   p_parent_flex_value_low        IN VARCHAR2,
   p_flex_value                   IN VARCHAR2,
   p_id_flex_application_short_na IN VARCHAR2,
   p_id_flex_code                 IN VARCHAR2,
   p_segment_attribute_type       IN VARCHAR2,
   p_value_attribute_type         IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_assignment_order             IN VARCHAR2,
   p_assignment_date              IN VARCHAR2,
   p_compiled_value_attribute_val IN VARCHAR2)
  IS
     l_func_name VARCHAR2(80);
BEGIN
   l_func_name := g_api_name || 'up_val_qual_value()';
   init('VAL_QUAL_VALUE', p_upload_phase);
   up_vset_value_qual_value
     (p_upload_phase                    => p_upload_phase,
      p_upload_mode                     => p_upload_mode,
      p_custom_mode                     => p_custom_mode,
      p_flex_value_set_name             => p_flex_value_set_name,
      p_parent_flex_value_low           => p_parent_flex_value_low,
      p_flex_value                      => p_flex_value,
      p_id_flex_application_short_na    => p_id_flex_application_short_na,
      p_id_flex_code                    => p_id_flex_code,
      p_segment_attribute_type          => p_segment_attribute_type,
      p_value_attribute_type            => p_value_attribute_type,
      p_owner                           => p_owner,
      p_last_update_date                => p_last_update_date,
      p_compiled_value_attribute_val    => p_compiled_value_attribute_val);
   <<label_done>>
   done('VAL_QUAL_VALUE', p_upload_phase);
EXCEPTION
   WHEN OTHERS THEN
      IF (g_debug_on) THEN
         debug_exception_top_level(l_func_name);
      END IF;
      RAISE;
END up_val_qual_value;

PROCEDURE up_desc_flex_nls
  (p_upload_phase                 IN VARCHAR2 DEFAULT NULL,
   p_upload_mode                  IN VARCHAR2,
   p_custom_mode                  IN VARCHAR2 DEFAULT NULL,
   p_application_short_name       IN VARCHAR2,
   p_descriptive_flexfield_name   IN VARCHAR2,
   p_owner                        IN VARCHAR2,
   p_last_update_date             IN VARCHAR2 DEFAULT NULL,
   p_table_application_short_name IN VARCHAR2,
   p_application_table_name       IN VARCHAR2,
   p_concatenated_segs_view_name  IN VARCHAR2 DEFAULT NULL,
   p_context_column_name          IN VARCHAR2,
   p_context_required_flag        IN VARCHAR2,
   p_context_user_override_flag   IN VARCHAR2,
   p_concatenated_segment_delimit IN VARCHAR2,
   p_freeze_flex_definition_flag  IN VARCHAR2,
   p_protected_flag               IN VARCHAR2,
   p_default_context_field_name   IN VARCHAR2,
   p_default_context_value        IN VARCHAR2,
   p_context_default_type         IN VARCHAR2 DEFAULT NULL,
   p_context_default_value        IN VARCHAR2 DEFAULT NULL,
   p_context_override_value_set_n IN VARCHAR2 DEFAULT NULL,
   p_context_runtime_property_fun IN VARCHAR2 DEFAULT NULL,
   p_context_synchronization_flag IN VARCHAR2 DEFAULT NULL,
   p_title                        IN VARCHAR2,
   p_form_context_prompt          IN VARCHAR2,
   p_description                  IN VARCHAR2)
  IS
     l_func_name  VARCHAR2(80);
     l_tbl        tbl_type;
     l_dff_flx    dff_flx_type;
     l_dff_flx_tl dff_flx_tl_type;
     l_dff_ctx    dff_ctx_type;
     l_vst_set    vst_set_type;
     l_app        app_type;
     l_file_who   fnd_flex_loader_apis.who_type;
     l_descriptive_flexfield_name  fnd_descriptive_flexs_vl.descriptive_flexfield_name%TYPE;
     l_title                       fnd_descriptive_flexs_vl.title%TYPE;
     l_concatenated_segs_view_name fnd_descriptive_flexs_vl.concatenated_segs_view_name%TYPE;
     l_context_synchronization_flag fnd_descriptive_flexs.context_synchronization_flag%TYPE;
BEGIN
   l_func_name := g_api_name || 'up_desc_flex_nls()';
   l_descriptive_flexfield_name := p_descriptive_flexfield_name;
   l_title := p_title;

   IF (g_debug_on) THEN 
      debug(l_func_name, 
            'PHASE:'  || p_upload_phase ||
            ',UMODE:' || p_upload_mode  || 
            ',CMODE:' || p_custom_mode  || 
            ',APPS:'  || p_application_short_name || 
            ',DFF:'   ||l_descriptive_flexfield_name);
   END IF; 

   IF (g_savepoint_entity_name IS NULL) THEN
       start_transaction(ENTITY_DESC_FLEX);
   END IF;

   IF (g_lock_handle IS NULL) THEN
       lock_entity('DESC_FLEX',
                    p_application_short_name,
                    p_descriptive_flexfield_name);
   END IF;

   g_numof_changes := 0;

      --
      -- Gather WHO Information.
      --
    IF (get_dff_flx_tl(l_dff_flx,
                       userenv('LANG'),
                     l_dff_flx_tl)) THEN
        NULL;
    END IF;

     --
     -- Check WHO Information.
     --
     IF (is_upload_allowed
        (p_custom_mode                  => p_custom_mode,
         p_file_owner                   => p_owner,
         p_file_last_update_date        => p_last_update_date,
         p_db_last_updated_by           => l_dff_flx_tl.last_updated_by,
         p_db_last_update_date          => l_dff_flx_tl.last_update_date,
         x_file_who                     => l_file_who)) THEN

         IF (g_debug_on) THEN
            debug(l_func_name, 'Translating DESC_FLEX.(MLS)');
         END IF;

         fnd_descriptive_flexs_pkg.translate_row
           (x_application_short_name       => p_application_short_name,
            x_descriptive_flexfield_name   => l_descriptive_flexfield_name,
            x_who                          => l_file_who,
            x_title                        => l_title,
            x_form_context_prompt          => p_form_context_prompt,
            x_description                  => p_description);
      ELSE
       IF (g_debug_on) THEN 
          debug(l_func_name, 'Upload is not allowed because of customization.');
       END IF;  
      END IF;
END;



/****** Should be removed later - end ******/

BEGIN
   g_debug_on := FALSE;
   g_left_margin := '';
   g_numof_changes := 0;
   g_numof_changes_kff_str := 0;
   g_lock_handle := NULL;
   g_root_error := NULL;
   g_call_stack := NULL;
   g_savepoint_entity_name := NULL;
   g_is_commit_ok := NULL;

   --
   -- Declaring a constant and then assigning a global variable to it solves
   -- 2 problems.
   --
   -- 1. Because of purity problems, fnd_load_util.null_value() cannot be
   --    called here.
   --    It has to be called when a constant variable is declared.
   -- 2. PL/SQL has a bug and if a constant is initialized with a function call,
   --    PL/SQL calls that function every time this constant is used.
   --
   -- So, declaring a constant variable and initializing it
   -- with fnd_load_util.null_value() solves the purity problem.
   -- Then copying this value to another global variable solves
   -- the PL/SQL problem.
   --
   g_null_value  := g_null_value_constant;

   g_newline     := fnd_global.newline();
   --
   -- Old ldt files do not have LAST_UPDATE_DATE data in them. So
   -- use 2001/12/15 as their last update date. This is the date when
   -- this change was added. It is as good as any other date.
   -- Do not change this date, otherwise it will cause unnecessary
   -- re-uploads.
   --
   --g_default_lud := To_date('2001/12/15 00:00:00', g_date_mask);--Commented 25/07/2007 Gowri
   
   --Added on 25/07/2007 Gowri
   g_default_lud := To_date(To_char(SYSDATE,g_date_mask), g_date_mask);
   
END XX_INV_FND_FLEX_LOADER_APIS;
/
SHOW ERRORS;

EXIT;