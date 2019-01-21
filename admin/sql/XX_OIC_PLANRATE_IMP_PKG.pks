SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_OIC_PLANRATE_IMP_PKG AUTHID CURRENT_USER AS
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_PLANRATE_IMP_PKG.pks                               |
   -- | Description : Package to create an XPATH Simulation so as to      |
   -- |               handle XML data                                     |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07   1.0       This package is used to import the plans into|
   -- |                      target instance                              |
   -- |                                                                   |
    -- +==================================================================+
    TYPE rec_type_ref_name IS RECORD (l_name   VARCHAR2(100),
                                      l_stname VARCHAR2(100),
                                      l_type   VARCHAR2(100));

    TYPE g_tbl_type_ref_name IS TABLE OF rec_type_ref_name
                                      INDEX BY BINARY_INTEGER;

    g_tbl_ref_name  g_tbl_type_ref_name;

    g_ref_tbl_id           NUMBER := 0;

    g_errorlog             CLOB   := ' ';

    TYPE rec_type_created_ele IS RECORD (l_name   VARCHAR2(100),
                                         l_type   VARCHAR2(100));

    TYPE g_tbl_type_created_ele IS TABLE OF rec_type_created_ele
                                      INDEX BY BINARY_INTEGER;

    rec_created_ele        rec_type_created_ele;

    g_tbl_created_ele_id   NUMBER := 0;

    g_tbl_created_ele      g_tbl_type_created_ele;

    TYPE g_tbl_type_formula IS TABLE OF VARCHAR2(200)
                                     INDEX BY BINARY_INTEGER;

    TYPE g_tbl_type_planele IS TABLE OF VARCHAR2(200)
                                     INDEX BY BINARY_INTEGER;

  ------------------------------------------------------------------------------
  --  Global Exceptions
  ------------------------------------------------------------------------------
    g_parse_error                 EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_parse_error, -20101);

    g_no_revclass_error           EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_no_revclass_error, -20102);

    g_sql_parse_error             EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_sql_parse_error, -20103);

    g_create_compplan_error       EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_compplan_error, -20104);

    g_assign_planelement_error    EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_assign_planelement_error, -20105);

    g_create_role_error           EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_role_error, -20106);

    g_assign_planrole_error       EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_assign_planrole_error, -20107);

    g_formula_not_found_error     EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_formula_not_found_error, -20108);

    g_planele_not_found_error     EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_planele_not_found_error, -20109);

    g_exp_not_valid_error         EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_exp_not_valid_error, -20110);

    g_create_exp_error            EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_exp_error, -20111);

    g_create_ratedim_error        EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_ratedim_error, -20112);

    g_create_ratesch_error        EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_ratesch_error, -20113);

    g_update_commsn_error         EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_update_commsn_error, -20114);

    g_create_formula_error        EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_formula_error, -20115);

    g_formula_notcmp_error        EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_formula_notcmp_error, -20116);

    g_gen_formula_error           EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_gen_formula_error, -20117);

    g_create_planele_error        EXCEPTION;

    PRAGMA EXCEPTION_INIT(g_create_planele_error, -20118);

  ------------------------------------------------------------------------------
  --Function: CNC_RETDOMDOC_FNC
  --Function to accept XML data in a CLOB object and return XML DOMDocument
  ------------------------------------------------------------------------------
    FUNCTION cnc_retdomdoc_fnc(p_xml CLOB) RETURN xmldom.DOMDocument;

  ------------------------------------------------------------------------------
  --  Function: cn_created_ele_fnc
  --  Function to validate if the element was created by the program or if it
  --  existed prior to this program
  ------------------------------------------------------------------------------
    FUNCTION cn_created_ele_fnc(p_name IN VARCHAR2, p_type IN VARCHAR2)
             RETURN BOOLEAN;

  ------------------------------------------------------------------------------
  --Procedure: CNC_SUBMIT_PLANRATE_PRC
  --Procedure to call the concurrent program
  ------------------------------------------------------------------------------
    PROCEDURE cnc_submit_planrate_prc(p_xml_file   IN  CLOB,
                                      p_request_id OUT NUMBER,
                                      p_seq_id     OUT NUMBER,
                                      p_debug_flag IN  VARCHAR2);

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_PLANRATE_PRC
  --Procedure to determine the type of import and call the suitable procedure
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_planrate_prc(errbuf       OUT VARCHAR2,
                                      retcode      OUT NUMBER,
                                      p_seq_id     IN  NUMBER,
                                      p_debug_flag IN  VARCHAR2 DEFAULT 'N');

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_PLAN_PRC
  --Procedure to import the xml plan data into the target OIC instance
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_plan_prc(p_xml_file IN CLOB);

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_RATE_PRC
  --Procedure to import the xml rate data into the target OIC instance
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_rate_prc(p_xml_file IN CLOB);
  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_EXPRESSION_PRC
  --Creates an expression using the data provided in p_expr_xml
  --p_exp_type is used to find the type of expression, whether input, output or
  --forecast
  ------------------------------------------------------------------------------
    PROCEDURE cnc_create_expression_prc(p_expr_xml IN  CLOB,
                                        p_exp_type IN  VARCHAR2,
                                        p_x_exp_id OUT NUMBER);

  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_FORMULA_PRC
  --Procedure to create a formula using the data in p_formula_xml
  ------------------------------------------------------------------------------
    PROCEDURE cnc_create_formula_prc(p_formula_xml IN CLOB,
                                     p_tag_type    IN VARCHAR2);

  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_PLANELE_PRC
  --Procedure to create the plan element with the data in p_planele_xml
  ------------------------------------------------------------------------------
    PROCEDURE cnc_create_planele_prc(p_planele_xml IN CLOB,
                                     p_tag_type    IN VARCHAR2);

   -----------------------------------------------------------------------------
   -- Procedure     : CNC_PARSE_SQL_PRC
   --
   -- Description   : This procedure parses the SQL_SELECT column for a given
   --                 expression. Any references to plan elements are stored in
   --                 the plsql table p_tbl_planele and references to formulas
   --                 are stored in plsql table p_tbl_formula
   -----------------------------------------------------------------------------
    PROCEDURE cnc_parse_sql_prc(p_sql_select  IN  VARCHAR2,
                                p_tbl_formula OUT g_tbl_type_formula,
                                p_tbl_planele OUT g_tbl_type_planele);

   -----------------------------------------------------------------------------
   -- Procedure     : CNC_WRITE_LOG_PRC
   --
   -- Description   : This procedure writes the log file for the entire program
   -----------------------------------------------------------------------------
    PROCEDURE cnc_write_log_prc(p_message IN VARCHAR2);

END XX_OIC_PLANRATE_IMP_PKG;
/