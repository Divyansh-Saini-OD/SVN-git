SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_OIC_PLANRATE_EXP_PKG AUTHID CURRENT_USER AS
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_PLANRATE_EXP_PKG.pks                              |
   -- | Description : Package to export data as a part of the OIC PLAN    |
   -- |               COPY Object                                         |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07  1.0        This package is used to implement export     |
   -- |                      the data in the XML file from source instance|
   -- |                                                                   |
    -- +==================================================================+
  TYPE rec_type_level IS RECORD (l_name      VARCHAR2(200),
                                 l_stname    VARCHAR2(200),
                                 l_type      VARCHAR2(15),
                                 l_level     NUMBER
                                );

  TYPE l_tbl_type_level IS TABLE of rec_type_level INDEX BY BINARY_INTEGER;

  TYPE rec_type_formula IS RECORD (l_formula         VARCHAR2(200),
                                   l_calc_formula_id NUMBER,
                                   l_storedname      VARCHAR2(200)
                                  );

  TYPE l_tbl_type_formula IS TABLE OF rec_type_formula INDEX BY BINARY_INTEGER;

  TYPE rec_type_planele IS RECORD (l_plan_element VARCHAR2(200),
                                   l_quota_id     NUMBER,
                                   l_storedname   VARCHAR2(200)
                                  );

  TYPE l_tbl_type_planele IS TABLE OF rec_type_planele INDEX BY BINARY_INTEGER;

  l_tbl_level        l_tbl_type_level;
  l_tbl_level_id     NUMBER := 0;
  rec_level          rec_type_level;
  g_errorlog         CLOB;
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_export_prc
   --
   -- Description   : Main procedure to export the Compensation Plan/Rate table
   --                 data
   -----------------------------------------------------------------------------
  PROCEDURE cnc_export_prc (p_export_type IN  VARCHAR2,
                            p_exp_val1    IN  NUMBER,
                            p_exp_val2    IN  NUMBER,
                            p_exp_val3    IN  NUMBER,
                            p_exp_val4    IN  NUMBER,
                            p_exp_xml     OUT NOCOPY CLOB,
                            p_errorlog    OUT NOCOPY CLOB
                           );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_plandata_prc
   --
   -- Description   : Procedure to retrieve the data for a given compensation
   --                 plan
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_plandata_prc (p_comp_plan_id IN  NUMBER,
                                  p_datafile_xml OUT NOCOPY CLOB
                                 );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_ratedata_prc
   --
   -- Description   : Procedure to retrieve the XML data for a given rate table
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_ratedata_prc (p_rate_schedule_id IN  NUMBER,
                                  p_datafile_xml     OUT NOCOPY CLOB
                                 );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_plan_expr_prc
   --
   -- Description   : This procedure finds the Plan elements bound to the given
   --                 Compensation plan and then identifies the expressions that
   --                 are associated to those Plan elements. These expressions
   --                 are the top level expressions associated to the Plan.
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_plan_expr_prc (p_comp_plan_id IN  NUMBER,
                                   p_tbl_level    OUT l_tbl_type_level
                                  );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_rate_expr_prc
   --
   -- Description   : This procedure finds the expressions that are associated
   --                 to the given rate tables.
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_rate_expr_prc (p_rate_schedule_id IN  NUMBER,
                                   p_tbl_level        OUT l_tbl_type_level
                                  );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_expr_prc
   -- Description   : Procedure to parse the expression and look for either
   --                 embedded expressions or formulas or plan elements
   --                 If embedded elements are found then they are sent for
   --                 parsing again
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_expr_prc (p_expr_id IN NUMBER,
                                p_expr    IN VARCHAR2,
                                p_level   IN NUMBER
                                );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_formula_prc
   --
   -- Description   : This procedure parses the given formula to obtain all the
   --                 expressions associated and calls cn_parse_expression_prc
   --                 so as to explore the next level of embedded elements
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_formula_prc (p_formula    IN VARCHAR2,
                                   p_formula_id IN NUMBER,
                                   p_storedname IN VARCHAR2,
                                   p_level      IN NUMBER
                                  );
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_planele_prc
   --
   -- Description   : This procedure parses the given planelement to obtain all
   --                 the expressions associated and calls
   --                 cn_parse_expression_prc so as to explore the next level
   --                 of embedded elements
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_planele_prc(p_planelement IN VARCHAR2,
                                  p_quota_id    IN NUMBER,
                                  p_storedname  IN VARCHAR2,
                                  p_level       IN NUMBER
                                 );
     ---------------------------------------------------------------------------
     -- If the expression does not contain any embedded expression then
     -- the expression is sent for parsing the sql_select column to look for
     -- embedded plan elements or formulas.
     ---------------------------------------------------------------------------
  PROCEDURE cnc_parse_sql_prc(p_sql_select       IN  VARCHAR2,
                              p_tbl_formula      OUT l_tbl_type_formula,
                              p_tbl_planele      OUT l_tbl_type_planele
                             );
   -----------------------------------------------------------------------------
   -- Procedure     : CNC_WRITE_LOG_PRC
   --
   -- Description   : This procedure writes the log file for the entire program
   -----------------------------------------------------------------------------
  PROCEDURE cnc_write_log_prc(p_message IN VARCHAR2);

END XX_OIC_PLANRATE_EXP_PKG;
/