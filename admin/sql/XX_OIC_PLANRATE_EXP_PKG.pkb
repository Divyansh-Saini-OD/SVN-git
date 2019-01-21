CREATE OR REPLACE
PACKAGE BODY APPS.XX_OIC_PLANRATE_EXP_PKG AS
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_PLANRATE_EXP_PKG.pkb                         |
   -- | Description : Package to export data as a part of the OIC PLAN    |
   -- |               COPY Object                                         |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07   1.0        This package is used to implement export    |
   -- |                      the data in the XML file to target instance  |
   -- +===================================================================+
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_export_prc
   --
   -- Description   : Main procedure to export the Compensation Plan/Rate table
   --                 data
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
  PROCEDURE cnc_export_prc(p_export_type IN  VARCHAR2,
                           p_exp_val1    IN  NUMBER,
                           p_exp_val2    IN  NUMBER,
                           p_exp_val3    IN  NUMBER,
                           p_exp_val4    IN  NUMBER,
                           p_exp_xml     OUT NOCOPY CLOB,
                           p_errorlog    OUT NOCOPY CLOB) IS

  l_copy_xml            CLOB    := ' ';
  l_copy_xml1           CLOB    := ' ';

  BEGIN
     ---------------------------------------------------------------------------
     -- Create the top XML header
     ---------------------------------------------------------------------------
       l_copy_xml := '<?xml version="1.0"?>' || CHR(10) ||
                      '<OIC_PLAN_COPY>' || CHR(10);
     ---------------------------------------------------------------------------
     -- Check for export type and obtain the data file for each plan/rate
     ---------------------------------------------------------------------------
       IF p_export_type  = 'PLANCOPY' THEN
           FOR i IN 1 .. 4
           LOOP
               CASE i
               WHEN 1 THEN
                    IF p_exp_val1 IS NOT NULL THEN
                       cnc_get_plandata_prc(p_exp_val1, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '<PLANCOPY>' ||CHR(10));
                       DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '</PLANCOPY>' || CHR(10));
                       l_tbl_level_id := 0;
                    END IF;
               WHEN 2 THEN
                    IF p_exp_val2 IS NOT NULL THEN
                       cnc_get_plandata_prc(p_exp_val2, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '<PLANCOPY>' ||CHR(10));
                       DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '</PLANCOPY>' || CHR(10));
                       l_tbl_level_id := 0;
                    END IF;
               WHEN 3 THEN
                    IF p_exp_val3 IS NOT NULL THEN
                       cnc_get_plandata_prc(p_exp_val3, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '<PLANCOPY>' ||CHR(10));
                       DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '</PLANCOPY>' || CHR(10));
                       l_tbl_level_id := 0;
                    END IF;
               WHEN 4 THEN
                    IF p_exp_val4 IS NOT NULL THEN
                       cnc_get_plandata_prc(p_exp_val4, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '<PLANCOPY>' ||CHR(10));
                       DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '</PLANCOPY>' || CHR(10));
                       l_tbl_level_id := 0;
                    END IF;
               END CASE;
           END LOOP;
     ---------------------------------------------------------------------------
     -- Complete the Plan Copy XML data file generation
     ---------------------------------------------------------------------------
           DBMS_LOB.APPEND(l_copy_xml, CHR(10) || '</OIC_PLAN_COPY>');
     ---------------------------------------------------------------------------
     -- If export type is rate copy
     ---------------------------------------------------------------------------
       ELSE
      
           FOR i IN 1 .. 4
           LOOP
               CASE i
               WHEN 1 THEN
                    IF p_exp_val1 IS NOT NULL THEN
                       cnc_get_ratedata_prc(p_exp_val1, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '<RATECOPY>' || CHR(10));
                       DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                       DBMS_LOB.APPEND(l_copy_xml, '</RATECOPY>' || CHR(10));
                       l_tbl_level_id := 0;
                    END IF;
               WHEN 2 THEN
                    IF p_exp_val2 IS NOT NULL THEN
                      cnc_get_ratedata_prc(p_exp_val2, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '<RATECOPY>' || CHR(10));
                      DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '</RATECOPY>' || CHR(10));
                      l_tbl_level_id := 0;
                    END IF;
               WHEN 3 THEN
                    IF p_exp_val3 IS NOT NULL THEN
                      cnc_get_ratedata_prc(p_exp_val3, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '<RATECOPY>' || CHR(10));
                      DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '</RATECOPY>' || CHR(10));
                      l_tbl_level_id := 0;
                    END IF;
               WHEN 4 THEN
                    IF p_exp_val4 IS NOT NULL THEN
                      cnc_get_ratedata_prc(p_exp_val4, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '<RATECOPY>' || CHR(10));
                      DBMS_LOB.APPEND(l_copy_xml, l_copy_xml1);
                      DBMS_LOB.APPEND(l_copy_xml, '</RATECOPY>' || CHR(10));
                      l_tbl_level_id := 0;
                    END IF;
               END CASE;
           END LOOP;
     ---------------------------------------------------------------------------
     -- Complete the Rate Copy XML data file generation
     ---------------------------------------------------------------------------
           DBMS_LOB.APPEND(l_copy_xml, CHR(10) || '</OIC_PLAN_COPY>');
       END IF;
     BEGIN
          p_exp_xml := l_copy_xml;
     EXCEPTION
     WHEN OTHERS THEN
          cnc_write_log_prc('p_exp_xml: ' || SUBSTR(SQLERRM,1,256));
          RAISE;
     END;
     p_errorlog := g_errorlog;
  EXCEPTION
  WHEN others THEN
       cnc_write_log_prc('cnc_export_prc: ' || SUBSTR(SQLERRM,1,256));
       p_errorlog := g_errorlog;
       p_exp_xml  := 'Error generating XML file ' || p_errorlog;
  END cnc_export_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_plandata_prc
   --
   -- Description   : Procedure to retrieve the data for a given compensation
   --                 plan
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_plandata_prc(p_comp_plan_id IN  NUMBER,
                                 p_datafile_xml OUT NOCOPY CLOB) IS
   l_tbl_level     l_tbl_type_level;
   l_tbl_level_id  NUMBER := 0;
   l_max_level     NUMBER := 1;
   l_xml           CLOB   := ' ';
   l_expr_str      CLOB   := ' ';
   l_formula_str   CLOB   := ' ';
   l_planele_str   CLOB   := ' ';
   l_expr_xml      CLOB   := ' ';
   l_formula_xml   CLOB   := ' ';
   l_planele_xml   CLOB   := ' ';
   l_plan_xml      CLOB   := ' ';
   l_expr_ctxt     DBMS_XMLGEN.ctxHandle;
   l_sql           CLOB   := ' ';
  BEGIN

     ---------------------------------------------------------------------------
     -- Call to cnc_get_plan_expr_prc so as to retrieve the hierarchy data
     -- On completion l_tbl_level will contain the level data
     ---------------------------------------------------------------------------
     l_tbl_level.DELETE;
     cnc_get_plan_expr_prc(p_comp_plan_id,l_tbl_level);


     FOR l_main IN REVERSE l_tbl_level.FIRST .. l_tbl_level.LAST
     LOOP
         FOR l_sub IN l_tbl_level.FIRST .. l_main
         LOOP
             IF (l_tbl_level(l_main).l_name = l_tbl_level(l_sub).l_name
                 AND l_tbl_level(l_main).l_type = l_tbl_level(l_sub).l_type
                 AND l_tbl_level(l_sub).l_level <= l_tbl_level(l_main).l_level
                 AND l_main != l_sub) THEN
                 l_tbl_level(l_sub).l_name     := NULL;
                 l_tbl_level(l_sub).l_stname   := NULL;
                 l_tbl_level(l_sub).l_type     := NULL;
                 l_tbl_level(l_sub).l_level    := NULL;
             ELSIF (l_tbl_level(l_main).l_name = l_tbl_level(l_sub).l_name
                 AND l_tbl_level(l_main).l_type = l_tbl_level(l_sub).l_type
                 AND l_tbl_level(l_sub).l_level > l_tbl_level(l_main).l_level
                 AND l_main != l_sub) THEN
                 l_tbl_level(l_main).l_level   := l_tbl_level(l_sub).l_level;
                 l_tbl_level(l_sub).l_name     := NULL;
                 l_tbl_level(l_sub).l_stname   := NULL;
                 l_tbl_level(l_sub).l_type     := NULL;
                 l_tbl_level(l_sub).l_level    := NULL;
             END IF;
         END LOOP;
     END LOOP;
     IF l_tbl_level.EXISTS(1) THEN
     ---------------------------------------------------------------------------
     -- Write the hierarchy data as XML data
     ---------------------------------------------------------------------------
        l_xml := l_xml || '<HIERARCHY>';
        FOR l IN l_tbl_level.FIRST .. l_tbl_level.LAST
        LOOP
          IF l_tbl_level(l).l_name IS NOT NULL THEN
            DBMS_LOB.APPEND(l_xml, chr(10) || '<RECORD>' || chr(10) || '<NAME>' ||l_tbl_level(l).l_name ||'</NAME>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<STNAME>' || l_tbl_level(l).l_stname ||'</STNAME>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<TYPE>'   || l_tbl_level(l).l_type || '</TYPE>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<LEVEL>'  || TO_CHAR(l_tbl_level(l).l_level) ||'</LEVEL>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '</RECORD>');

            CASE l_tbl_level(l).l_type
     ---------------------------------------------------------------------------
     -- Create the string of expression id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'EXPRESSION' THEN
                         DBMS_LOB.APPEND(l_expr_str, '''' || l_tbl_level(l).l_name || ''', ');
     ---------------------------------------------------------------------------
     -- Create the string of formula id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'FORMULA' THEN
                         DBMS_LOB.APPEND(l_formula_str, '''' || l_tbl_level(l).l_name || ''', ');
     ---------------------------------------------------------------------------
     -- Create the string of plan element id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'PLANELEMENT' THEN
                         DBMS_LOB.APPEND(l_planele_str, '''' || l_tbl_level(l).l_name || ''', ');
            END CASE;
          END IF;
        END LOOP;
        DBMS_LOB.APPEND(l_xml, chr(10) || '</HIERARCHY>');
     END IF;
     l_expr_str    := RTRIM(l_expr_str,', ');
     l_formula_str := RTRIM(l_formula_str,', ');
     l_planele_str := RTRIM(l_planele_str,', ');
     ---------------------------------------------------------------------------
     -- Create the XML for dependent expressions
     ---------------------------------------------------------------------------
     IF l_expr_str IS NOT NULL and length(l_expr_str) > 1THEN
        l_sql       := 'SELECT * FROM cn_calc_sql_exps_all WHERE org_id =  ' ||
                       to_number(FND_PROFILE.VALUE('ORG_ID')) ||
                       ' AND name IN ('||l_expr_str||')';

        l_expr_ctxt := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_EXPR');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_CALC_SQL_EXPR_ALL');
        l_expr_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_expr_xml  := SUBSTR(l_expr_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML for dependent formulas
     ---------------------------------------------------------------------------
     --IF l_formula_str IS NOT NULL THEN
    --  nagesh
     IF l_formula_str IS NOT NULL and length(l_formula_str) > 1 THEN
        l_sql          := 'SELECT * FROM XX_OIC_formulacopy_v WHERE org_id = ' ||
                          FND_PROFILE.VALUE('ORG_ID') ||
                          ' AND name IN ('||l_formula_str||')';

        l_expr_ctxt    := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_FORMULA');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_CALC_FORMULAS_ALL');
        l_formula_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_formula_xml  := SUBSTR(l_formula_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;
     ---------------------------------------------------------------------------
     -- Create the XML for dependent plan elements
     ---------------------------------------------------------------------------
     IF l_planele_str IS NOT NULL and length(l_planele_str) > 1 THEN
        l_sql          := 'SELECT * FROM XX_OIC_planelementcopy_v WHERE delete_flag = ''N'' AND name IN (' || l_planele_str ||')';
        l_expr_ctxt    := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_PELE');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_QUOTAS_ALL');
        l_planele_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_planele_xml  := SUBSTR(l_planele_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML for the Compensation plan
     ---------------------------------------------------------------------------
     IF p_comp_plan_id IS NOT NULL THEN
        l_sql       :=  'SELECT * FROM XX_OIC_plancopy_v WHERE comp_plan_id = '||
                        p_comp_plan_id;
        l_expr_ctxt := DBMS_XMLGen.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'COMP_PLAN');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_COMP_PLANS_ALL');
        l_plan_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_plan_xml  := SUBSTR(l_plan_xml,22);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;
     ---------------------------------------------------------------------------
     -- Create the XML data file for the given compensation plan
     ---------------------------------------------------------------------------
     p_datafile_xml  := ' ';
     DBMS_LOB.APPEND(p_datafile_xml, l_xml);
     DBMS_LOB.APPEND(p_datafile_xml, CHR(10) || '<DEPENDENTS>' || CHR(10));
     DBMS_LOB.APPEND(p_datafile_xml, l_expr_xml);
     DBMS_LOB.APPEND(p_datafile_xml, l_formula_xml);
     DBMS_LOB.APPEND(p_datafile_xml, l_planele_xml);
     DBMS_LOB.APPEND(p_datafile_xml, '</DEPENDENTS>' || CHR(10));
     DBMS_LOB.APPEND(p_datafile_xml, l_plan_xml);
  EXCEPTION
  WHEN OTHERS THEN
       cnc_write_log_prc('cnc_get_plandata_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_get_plandata_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_ratedata_prc
   --
   -- Description   : Procedure to retrieve the XML data for a given rate table
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_ratedata_prc (p_rate_schedule_id IN  NUMBER,
                                  p_datafile_xml     OUT NOCOPY CLOB
                                 ) IS
   l_tbl_level     l_tbl_type_level;
   l_tbl_level_id  NUMBER           := 0;
   l_max_level     NUMBER           := 1;
   l_xml           CLOB             := ' ';
   l_expr_str      CLOB             := ' ';
   l_formula_str   CLOB             := ' ';
   l_planele_str   CLOB             := ' ';
   l_expr_xml      CLOB             := ' ';
   l_formula_xml   CLOB             := ' ';
   l_planele_xml   CLOB             := ' ';
   l_rate_xml      CLOB             := ' ';
   l_expr_ctxt     DBMS_XMLGEN.ctxHandle;
   l_sql           CLOB             := ' ';
  BEGIN

     ---------------------------------------------------------------------------
     -- Call to cnc_get_rate_expr_prc so as to retrieve the hierarchy data
     -- On completion l_tbl_level will contain the level data
     ---------------------------------------------------------------------------
     l_tbl_level.DELETE;
     cnc_get_rate_expr_prc(p_rate_schedule_id,l_tbl_level);
     --cnc_write_log_prc('step1 -'||l_tbl_level);
     
     FOR l_main IN REVERSE l_tbl_level.FIRST .. l_tbl_level.LAST
     LOOP
     
         FOR l_sub IN l_tbl_level.FIRST .. l_main
         LOOP
             IF (l_tbl_level(l_main).l_name = l_tbl_level(l_sub).l_name
                 AND l_tbl_level(l_main).l_type = l_tbl_level(l_sub).l_type
                 AND l_tbl_level(l_sub).l_level <= l_tbl_level(l_main).l_level
                 AND l_main != l_sub) THEN
                 l_tbl_level(l_sub).l_name     := NULL;
                 l_tbl_level(l_sub).l_stname   := NULL;
                 l_tbl_level(l_sub).l_type     := NULL;
                 l_tbl_level(l_sub).l_level    := NULL;
             ELSIF (l_tbl_level(l_main).l_name = l_tbl_level(l_sub).l_name
                 AND l_tbl_level(l_main).l_type = l_tbl_level(l_sub).l_type
                 AND l_tbl_level(l_sub).l_level > l_tbl_level(l_main).l_level
                 AND l_main != l_sub) THEN
                 l_tbl_level(l_main).l_level   := l_tbl_level(l_sub).l_level;
                 l_tbl_level(l_sub).l_name     := NULL;
                 l_tbl_level(l_sub).l_stname   := NULL;
                 l_tbl_level(l_sub).l_type     := NULL;
                 l_tbl_level(l_sub).l_level    := NULL;
             END IF;
         END LOOP;
     END LOOP;

     IF l_tbl_level.EXISTS(1) THEN
     ---------------------------------------------------------------------------
     -- Write the hierarchy data as XML data
     ---------------------------------------------------------------------------
        DBMS_LOB.APPEND(l_xml, '<HIERARCHY>');

        FOR l IN l_tbl_level.FIRST .. l_tbl_level.LAST
        LOOP
          IF l_tbl_level(l).l_name IS NOT NULL THEN
            DBMS_LOB.APPEND(l_xml, chr(10) || '<RECORD>' || chr(10) || '<NAME>' ||l_tbl_level(l).l_name ||'</NAME>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<STNAME>' || l_tbl_level(l).l_stname ||'</STNAME>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<TYPE>'   || l_tbl_level(l).l_type || '</TYPE>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '<LEVEL>'  || TO_CHAR(l_tbl_level(l).l_level) ||'</LEVEL>');
            DBMS_LOB.APPEND(l_xml, chr(10) || '</RECORD>');

            CASE l_tbl_level(l).l_type
     ---------------------------------------------------------------------------
     -- Create the string of expression id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'EXPRESSION' THEN
                         DBMS_LOB.APPEND(l_expr_str, '''' || l_tbl_level(l).l_name || ''', ');
     ---------------------------------------------------------------------------
     -- Create the string of formula id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'FORMULA' THEN
                         DBMS_LOB.APPEND(l_formula_str, '''' || l_tbl_level(l).l_name || ''', ');
     ---------------------------------------------------------------------------
     -- Create the string of plan element id's so as to create the where clause
     ---------------------------------------------------------------------------
                 WHEN 'PLANELEMENT' THEN
                         DBMS_LOB.APPEND(l_planele_str, '''' || l_tbl_level(l).l_name || ''', ');
            END CASE;
          END IF;
        END LOOP;

        DBMS_LOB.APPEND(l_xml, chr(10) || '</HIERARCHY>');

     END IF;
     l_expr_str    := RTRIM(l_expr_str,', ');
     l_formula_str := RTRIM(l_formula_str,', ');
     l_planele_str := RTRIM(l_planele_str,', ');
  
     ---------------------------------------------------------------------------
     -- Create the XML for dependent expressions
     ---------------------------------------------------------------------------
     IF l_expr_str IS NOT NULL and length(l_expr_str) > 1THEN
        l_sql       := 'SELECT * FROM cn_calc_sql_exps_all WHERE org_id =  ' ||
                       to_number(FND_PROFILE.VALUE('ORG_ID')) ||
                       ' AND name IN ('||l_expr_str||')';
        l_expr_ctxt := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_EXPR');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_CALC_SQL_EXPR_ALL');
        l_expr_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_expr_xml  := SUBSTR(l_expr_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML for dependent formulas
     ---------------------------------------------------------------------------
     IF l_formula_str IS NOT NULL and length(l_formula_str) > 1THEN
        l_sql          := 'SELECT * FROM XX_OIC_formulacopy_v WHERE org_id = ' ||
                          FND_PROFILE.VALUE('ORG_ID') ||
                          ' AND name IN ('||l_formula_str||')';
        l_expr_ctxt    := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_FORMULA');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_CALC_FORMULAS_ALL');
        l_formula_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_formula_xml  := SUBSTR(l_formula_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML for dependent plan elements
     ---------------------------------------------------------------------------
     IF l_planele_str IS NOT NULL and length(l_planele_str) > 1THEN
        l_sql          := 'SELECT * FROM XX_OIC_planelementcopy_v WHERE delete_flag = ''N'' AND name IN (' || l_planele_str ||')';
        l_expr_ctxt    := DBMS_XMLGEN.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'DEPENDENT_PELE');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_QUOTAS_ALL');
        l_planele_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_planele_xml  := SUBSTR(l_planele_xml,23);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML for the Compensation plan
     ---------------------------------------------------------------------------
     IF p_rate_schedule_id IS NOT NULL THEN
        l_sql       :=  'SELECT * FROM XX_OIC_ratecopy_v WHERE rate_schedule_id = '||
                        p_rate_schedule_id;
        l_expr_ctxt := DBMS_XMLGen.newContext(l_sql);
        DBMS_XMLGEN.setRowsetTag(l_expr_ctxt, 'RATE_TABLE');
        DBMS_XMLGEN.setRowTag(l_expr_ctxt, 'CN_RATE_SCHEDULES_ALL');
        l_rate_xml  := DBMS_XMLGEN.GetXML(l_expr_ctxt);
        l_rate_xml  := SUBSTR(l_rate_xml,22);
        DBMS_XMLGEN.closeContext(l_expr_ctxt);
     END IF;

     ---------------------------------------------------------------------------
     -- Create the XML data file for the given compensation plan
     ---------------------------------------------------------------------------
     p_datafile_xml  := ' ';
     DBMS_LOB.APPEND(p_datafile_xml, l_xml);
     DBMS_LOB.APPEND(p_datafile_xml, CHR(10) || '<DEPENDENTS>' || CHR(10));
     DBMS_LOB.APPEND(p_datafile_xml, l_expr_xml);
     DBMS_LOB.APPEND(p_datafile_xml, l_formula_xml);
     DBMS_LOB.APPEND(p_datafile_xml, l_planele_xml);
     DBMS_LOB.APPEND(p_datafile_xml, '</DEPENDENTS>' || CHR(10));
     DBMS_LOB.APPEND(p_datafile_xml, l_rate_xml);

  EXCEPTION
  WHEN OTHERS THEN
       cnc_write_log_prc('cnc_get_ratedata_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_get_ratedata_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_plan_expr_prc
   --
   -- Description   : This procedure finds the Plan elements bound to the given
   --                 Compensation plan and then identifies the expressions that
   --                 are associated to those Plan elements. These expressions
   --                 are the top level expressions associated to the Plan.
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_plan_expr_prc(p_comp_plan_id IN  NUMBER
                                 ,p_tbl_level    OUT l_tbl_type_level) IS
     ---------------------------------------------------------------------------
     -- Cursor c_quotas is used to retrieve the name of the compensation plan
     -- and the plan element on passing compensation_plan_id as a parameter
     ---------------------------------------------------------------------------
    CURSOR c_quotas IS
     SELECT  CCPA.name               COMPENSATION_PLAN,
             CQA.quota_id,
             CQA.name                PLAN_ELEMENT
      FROM   cn_comp_plans_all       CCPA,
             cn_quota_assigns_all    CQAA,
             cn_quotas_all           CQA
     WHERE  1                          =  1
       AND  CQAA.comp_plan_id       (+)=  CCPA.comp_plan_id
       AND  CQAA.org_id             (+)=  CCPA.org_id
       AND  CQA.quota_id            (+)=  CQAA.quota_id
       AND  CQA.org_id              (+)=  CQAA.org_id
       AND  CQA.delete_flag         (+)=  'N'
       AND  CCPA.comp_plan_id          =  p_comp_plan_id;

     ---------------------------------------------------------------------------
     -- Cursor c_expression is to retrieve all the expressions associated to the
     -- plan element
     -- Input parameter to the cursor is the id of a plan element
     ---------------------------------------------------------------------------
    CURSOR c_expression(p_plan_ele_id NUMBER) IS
     SELECT  CCSEA.name              EXPRESSION_INPUT,
             CCSEA.calc_sql_exp_id   EXPRESSION_INPUT_ID,
             CCSEA1.name             EXPRESSION_OUTPUT,
             CCSEA1.calc_sql_exp_id  EXPRESSION_OUTPUT_ID,
             CCSEA2.name             EXPRESSION_FORECAST,
             CCSEA2.calc_sql_exp_id  EXPRESSION_FORECAST_ID
       FROM  cn_quotas_all           CQA,
             cn_calc_formulas_all    CCFA,
             cn_formula_inputs_all   CFIA,
             cn_calc_sql_exps_all    CCSEA,
             cn_calc_sql_exps_all    CCSEA1,
             cn_calc_sql_exps_all    CCSEA2
      WHERE  1                          =  1
        AND  CCFA.calc_formula_id    (+)=  CQA.calc_formula_id
        AND  CCFA.org_id             (+)=  CQA.org_id
        AND  CFIA.calc_formula_id    (+)=  CCFA.calc_formula_id
        AND  CFIA.org_id             (+)=  CCFA.org_id
        AND  CCSEA.calc_sql_exp_id   (+)=  CFIA.calc_sql_exp_id
        AND  CCSEA1.calc_sql_exp_id  (+)=  CCFA.output_exp_id
        AND  CCSEA2.calc_sql_exp_id  (+)=  CCFA.f_output_exp_id
        AND  CQA.delete_flag         (+)=  'N'
        AND  CQA.quota_id               =  p_plan_ele_id;

   l_level_num NUMBER := 1;
   BEGIN
     p_tbl_level.DELETE;
     FOR rec_quotas IN c_quotas
     LOOP
     ---------------------------------------------------------------------------
     -- Insert the Plan Element received as input into the hierarchy table
     ---------------------------------------------------------------------------
         rec_level.l_name            := rec_quotas.PLAN_ELEMENT;
         rec_level.l_stname          := rec_quotas.quota_id||'PE';
         rec_level.l_level           := l_level_num;
         rec_level.l_type            := 'PLANELEMENT';
         l_tbl_level_id              := l_tbl_level_id + 1;
         l_tbl_level(l_tbl_level_id) := rec_level;

         FOR rec_expression IN c_expression(rec_quotas.quota_id)
         LOOP
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- input expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_input IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_input_id,
                                rec_expression.expression_input,
                                l_level_num+1
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- output expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_output IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_output_id,
                                rec_expression.expression_output,
                                l_level_num+1
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- forecast expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_forecast IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_forecast_id,
                                rec_expression.expression_forecast,
                                l_level_num+1
                               );
           END IF;
         END LOOP;
     END LOOP;
     p_tbl_level := l_tbl_level;
   EXCEPTION
   WHEN OTHERS THEN
       cnc_write_log_prc('cnc_get_plan_expr_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_get_plan_expr_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_get_rate_expr_prc
   --
   -- Description   : This procedure finds the expressions that are associated
   --                 to the given rate tables.
   -----------------------------------------------------------------------------
  PROCEDURE cnc_get_rate_expr_prc (p_rate_schedule_id IN  NUMBER,
                                   p_tbl_level        OUT l_tbl_type_level
                                  ) IS
     ---------------------------------------------------------------------------
     -- Cursor c_expression is to retrieve all the expressions associated to the
     -- Rate table
     -- Input parameter to the cursor is the id of a rate schedule table
     ---------------------------------------------------------------------------
    CURSOR c_expression IS
     SELECT  CCSEA.name              EXPRESSION_INPUT,
             CCSEA.calc_sql_exp_id   EXPRESSION_INPUT_ID,
             CCSEA1.name             EXPRESSION_OUTPUT,
             CCSEA1.calc_sql_exp_id  EXPRESSION_OUTPUT_ID,
             CCSEA2.name             EXPRESSION_FORECAST,
             CCSEA2.calc_sql_exp_id  EXPRESSION_FORECAST_ID
       FROM  cn_rate_schedules_all   CRSA,
             cn_rt_formula_asgns_all CRFAA,
             cn_calc_formulas_all    CCFA,
             cn_formula_inputs_all   CFIA,
             cn_calc_sql_exps_all    CCSEA,
             cn_calc_sql_exps_all    CCSEA1,
             cn_calc_sql_exps_all    CCSEA2
      WHERE  CRFAA.rate_schedule_id    = CRSA.rate_schedule_id
        AND  CRFAA.org_id            = CRSA.org_id
        AND  CCFA.calc_formula_id      = CRFAA.calc_formula_id
        AND  CCFA.org_id              = CRFAA.org_id
        AND  CFIA.calc_formula_id     = CCFA.calc_formula_id
        AND  CFIA.org_id               = CCFA.org_id
        AND  CCSEA.calc_sql_exp_id  (+)= CFIA.calc_sql_exp_id
        AND  CCSEA1.calc_sql_exp_id (+)= CCFA.output_exp_id
        AND  CCSEA2.calc_sql_exp_id (+)= CCFA.f_output_exp_id
        AND  CRSA.rate_schedule_id     = p_rate_schedule_id;

   l_level_num NUMBER := 1;
   BEGIN
     p_tbl_level.DELETE;
         FOR rec_expression IN c_expression
         LOOP

     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- input expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_input IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_input_id,
                                rec_expression.expression_input,
                                l_level_num
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- output expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_output IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_output_id,
                                rec_expression.expression_output,
                                l_level_num
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- forecast expression associated to the plan element
     ---------------------------------------------------------------------------
           IF rec_expression.expression_forecast IS NOT NULL THEN
             cnc_parse_expr_prc(rec_expression.expression_forecast_id,
                                rec_expression.expression_forecast,
                                l_level_num
                               );
           END IF;
         END LOOP;
     p_tbl_level := l_tbl_level;
   EXCEPTION
   WHEN OTHERS THEN
       cnc_write_log_prc('cnc_get_rate_expr_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
   END cnc_get_rate_expr_prc;
   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_expr_prc
   -- Description   : Procedure to parse the expression and look for either
   --                 embedded expressions or formulas or plan elements
   --                 If embedded elements are found then they are sent for
   --                 parsing again
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_expr_prc(p_expr_id IN NUMBER,
                               p_expr    IN VARCHAR2,
                               p_level   IN NUMBER) IS

     ---------------------------------------------------------------------------
     -- Cursor c_sql_select is to retrieve the sql select column for the given
     -- expression
     -- Input parameter to the cursor is the id of a expression
     ---------------------------------------------------------------------------
    CURSOR c_sql_select(p_expr_id NUMBER) IS
     SELECT CCSEA.sql_select
       FROM cn_calc_sql_exps_all CCSEA
      WHERE CCSEA.calc_sql_exp_id = p_expr_id;

     ---------------------------------------------------------------------------
     -- Cursor c_calc_edges is to retrieve name and id of all the expressions
     -- that are embedded in the given expression
     -- Input parameter to the cursor is the id of a expression
     ---------------------------------------------------------------------------
    CURSOR c_calc_edges(p_parent_id NUMBER) IS
     SELECT CCSEA.calc_sql_exp_id   EXPR_ID,
            CCSEA.name              EXPRESSION
       FROM cn_calc_sql_exps_all CCSEA
      WHERE CCSEA.calc_sql_exp_id IN (SELECT CCEA.child_id
                                        FROM cn_calc_edges_all CCEA
                                       WHERE CCEA.parent_id = p_parent_id
                                         and CCEA.edge_type = 'EE');

    l_tbl_embed_formula l_tbl_type_formula;
    l_tbl_embed_planele l_tbl_type_planele;
  BEGIN
  
     ---------------------------------------------------------------------------
     -- Insert the expression received as input into the hierarchy
     ---------------------------------------------------------------------------
         rec_level.l_name            := p_expr;
         rec_level.l_level           := p_level;
         rec_level.l_stname          := NULL;
         rec_level.l_type            := 'EXPRESSION';
         l_tbl_level_id              := l_tbl_level_id + 1;
         l_tbl_level(l_tbl_level_id) := rec_level;

     ---------------------------------------------------------------------------
     -- Finds the embedded expression for the given expression and if found then
     -- recursively calls the procedure again to parse it
     ---------------------------------------------------------------------------
         FOR rec_calc_edges IN c_calc_edges(p_expr_id)
         LOOP
             cnc_parse_expr_prc(rec_calc_edges.expr_id,
                                rec_calc_edges.expression,
                                p_level+1);
         END LOOP;

     ---------------------------------------------------------------------------
     -- Parse the sql_select column to look for
     -- embedded plan elements or formulas.
     ---------------------------------------------------------------------------
            FOR rec_sql_select IN c_sql_select(p_expr_id)
            LOOP
                cnc_parse_sql_prc(p_sql_select  => rec_sql_select.sql_select,
                                  p_tbl_formula => l_tbl_embed_formula,
                                  p_tbl_planele => l_tbl_embed_planele);
            END LOOP;
     ---------------------------------------------------------------------------
     -- If the cnc_parse_sql_prc procedure returned any embedded formulas, then
     -- parse the formulas
     ---------------------------------------------------------------------------
            IF l_tbl_embed_formula.EXISTS(1) THEN
               FOR i in l_tbl_embed_formula.FIRST ..
                                                     l_tbl_embed_formula.LAST
               LOOP
                 cnc_parse_formula_prc(l_tbl_embed_formula(i).l_formula,
                                       l_tbl_embed_formula(i).l_calc_formula_id,
                                       l_tbl_embed_formula(i).l_storedname,
                                       p_level+1
                                      );
               END LOOP;
            END IF;

     ---------------------------------------------------------------------------
     -- If the cnc_parse_sql_prc procedure returned any embedded plan elements
     -- then parse the plan elements
     ---------------------------------------------------------------------------
            IF l_tbl_embed_planele.EXISTS(1) THEN
               FOR j in l_tbl_embed_planele.FIRST .. l_tbl_embed_planele.LAST
               LOOP
                   cnc_parse_planele_prc(l_tbl_embed_planele(j).l_plan_element
                                        ,l_tbl_embed_planele(j).l_quota_id
                                        ,l_tbl_embed_planele(j).l_storedname
                                        ,p_level+1);
               END LOOP;
            END IF;
  EXCEPTION
  WHEN OTHERS THEN
       cnc_write_log_prc('cnc_parse_expr_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_parse_expr_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_sql_prc
   --
   -- Description   : This procedure parses the SQL_SELECT column for a given
   --                 expression. Any references to plan elements are stored in
   --                 the plsql table p_tbl_planele and references to formulas
   --                 are stored in plsql table p_tbl_formula
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_sql_prc(p_sql_select  IN  VARCHAR2,
                              p_tbl_formula OUT l_tbl_type_formula,
                              p_tbl_planele OUT l_tbl_type_planele
                             ) IS

   l_sql_select_left     VARCHAR2(4000) := p_sql_select;
   l_ix                  NUMBER         := 0;
   l_seg                 VARCHAR2(4000) := NULL;
   l_ix2                 NUMBER         := 0;
   l_seg2                VARCHAR2(4000) := NULL;
   l_disp_seg            VARCHAR2(4000) := NULL;
   l_table_id            NUMBER         := 0;
   l_table_name          VARCHAR2(80)   := NULL;
   l_formula_tbl_id      NUMBER         := 0;
   l_planele_tbl_id      NUMBER         := 0;
   l_formula_stored_name VARCHAR2(100)  := NULL;

   TYPE l_tbl_type_vt IS TABLE OF VARCHAR2(80);

   l_tbl_sel_pieces      l_tbl_type_vt  := l_tbl_type_vt('RateResult',
                                                         'ForecastAmount',
                                                         'ABS(',
                                                         'CEIL(',
                                                         'EXP(',
                                                         'FLOOR(',
                                                         'GREATEST(',
                                                         'LEAST(',
                                                         'MOD(',
                                                         'POWER(',
                                                         'ROUND(',
                                                         'SIGN(',
                                                         'SQRT(',
                                                         'TO_NUMBER(',
                                                         'TRUNC(',
                                                         'AVG(',
                                                         'COUNT(',
                                                         'MAX(',
                                                         'MIN(',
                                                         'STDDEV(',
                                                         'SUM(',
                                                         'VARIANCE(',
                                                         'DECODE(',
                                                         'NVL(',
                                                         '*',
                                                         '/',
                                                         '.',
                                                         '-',
                                                         '+',
                                                         ',',
                                                         ')',
                                                         '('
                                                        );

   l_tbl_disp_pieces     l_tbl_type_vt  := l_tbl_sel_pieces;

   l_tbl_opers           l_tbl_type_vt  := l_tbl_type_vt( '/',
                                                          '+',
                                                          '*',
                                                          '-',
                                                          ' ',
                                                          ',',
                                                          ')'
                                                        );

   l_ct                  NUMBER         := 0;
   l_success             BOOLEAN;
   l_found_num           BOOLEAN;
   rec_planele           rec_type_planele;
   rec_formula           rec_type_formula;

   CURSOR c_calc_formulas(p_segment IN VARCHAR2) IS
      SELECT CCFA.NAME,
             CCFA.calc_formula_id
        FROM cn_calc_formulas_all CCFA
       WHERE UPPER('cn_formula_'
                   || CCFA.calc_formula_id
                   || '_'
                   || CCFA.org_id
                   || '_pkg.get_result(p_commission_line_id)'
                  ) = UPPER(p_segment);

   CURSOR c_quotas(p_segment IN VARCHAR2) IS
      SELECT CQA.NAME,
             CQA.quota_id
        FROM cn_quotas_all CQA
       WHERE CQA.quota_id || 'PE' = p_segment;

   CURSOR c_get_tbl(p_segment IN VARCHAR2) IS
      SELECT COA.user_name,
             COA.object_id,
             COA.name
       FROM  cn_objects_all COA
      WHERE  COA.calc_eligible_flag =  'Y'
        AND  COA.object_type        IN ('TBL', 'VIEW')
            AND  COA.user_name          IS NOT NULL
        AND  COA.alias              =  p_segment;

   CURSOR c_get_col(p_segment  IN VARCHAR2
                , p_table_id IN NUMBER) IS
      SELECT COA.user_name
        FROM cn_objects_all COA
       WHERE COA.table_id          = p_table_id
         AND COA.calc_formula_flag = 'Y'
             AND COA.object_type       = 'COL'
             AND COA.user_name         IS NOT NULL
         AND COA.name              = p_segment;

   CURSOR c_user_objects(p_sql_select_left IN VARCHAR2) IS
      SELECT UO.object_name
        FROM user_objects UO
       WHERE UO.object_type = 'FUNCTION'
         AND UO.status      = 'VALID'
         AND UO.object_name = SUBSTR(p_sql_select_left,1, INSTR(p_sql_select_left,'(')-1);
  BEGIN
     ---------------------------------------------------------------------------
     -- Translate RateResult
     ---------------------------------------------------------------------------
   l_tbl_disp_pieces(1) := cn_api.get_lkup_meaning('RATE_TABLE_RESULT',
                                                   'EXPRESSION_TYPE'
                                                  );
     ---------------------------------------------------------------------------
     -- Translate ForecastAmount
     ---------------------------------------------------------------------------
   l_tbl_disp_pieces(2) := cn_api.get_lkup_meaning('FORECAST_AMOUNT',
                                                   'EXPRESSION_TYPE'
                                                  );

     ---------------------------------------------------------------------------
     -- set p_sql_select to upper
     ---------------------------------------------------------------------------
   l_sql_select_left    := UPPER(p_sql_select);

     ---------------------------------------------------------------------------
     -- Build piped sql select
     ---------------------------------------------------------------------------
   LOOP
     ---------------------------------------------------------------------------
     -- Usage of l_ct is to defend against infinite loop
     ---------------------------------------------------------------------------
      l_ct              := l_ct + 1;
      l_success         := FALSE;

     ---------------------------------------------------------------------------
     -- Parse to search plan element
     ---------------------------------------------------------------------------
      IF SUBSTR(l_sql_select_left, 1, 1) = '(' THEN
     ---------------------------------------------------------------------------
     -- Get close parenthesis
     ---------------------------------------------------------------------------
             l_ix       := INSTR(l_sql_select_left, '.');
             l_seg      := SUBSTR(l_sql_select_left,2,l_ix-2);
             l_ix2      := INSTR(l_sql_select_left, ')');
             l_seg2     := SUBSTR(l_sql_select_left,l_ix+1,l_ix2-l_ix-1);
             l_disp_seg := NULL;

     ---------------------------------------------------------------------------
     -- Get display name of Plan Element
     ---------------------------------------------------------------------------
         FOR rec_quotas IN c_quotas(l_seg)
         LOOP
             l_disp_seg  := rec_quotas.name;
             IF l_disp_seg IS NOT NULL THEN
                rec_planele.l_plan_element        := l_disp_seg;
                rec_planele.l_quota_id            := rec_quotas.quota_id;
                rec_planele.l_storedname          := l_seg;
                l_planele_tbl_id                  := l_planele_tbl_id + 1;
                p_tbl_planele(l_planele_tbl_id)   := rec_planele;
                l_sql_select_left                 := SUBSTR(l_sql_select_left,
                                                            l_ix2+1);
                l_success                         := TRUE;
             END IF;
         END LOOP;
     ---------------------------------------------------------------------------
     -- End of parse to search plan element
     ---------------------------------------------------------------------------
     END IF;

     ---------------------------------------------------------------------------
     -- Parse for quoted constant
     ---------------------------------------------------------------------------
     IF SUBSTR(l_sql_select_left, 1, 1) = '''' AND l_success = FALSE THEN
     ---------------------------------------------------------------------------
     -- Get close quote
     ---------------------------------------------------------------------------
        l_ix := instr(l_sql_select_left, '''', 2);
        IF l_ix = 0 THEN
           RAISE_APPLICATION_ERROR(-20103, 'Error occured while parsing the '||
                                           'expressions SQL_SELECT column.' ||
                                           'The SQL_SELECT that was being ' ||
                                           'parsed at the time of exception' ||
                                           ' is: '||p_sql_select
                                  );
        END IF;

        l_sql_select_left  := substr(l_sql_select_left, l_ix+1);
        l_success            := TRUE;
     ---------------------------------------------------------------------------
     -- End of Parse for quoted constant
     ---------------------------------------------------------------------------
     END IF;

     ---------------------------------------------------------------------------
     -- Parse for numeric value
     ---------------------------------------------------------------------------
     IF l_success = FALSE THEN
        l_found_num := FALSE;
        WHILE SUBSTR(l_sql_select_left,1,1) BETWEEN '0' AND '9'
           OR SUBSTR(l_sql_select_left,1,1) = '.'
        LOOP
            l_sql_select_left  := substr(l_sql_select_left, 2);
            l_found_num          := true;
            l_success            := true;
        END LOOP;
     ---------------------------------------------------------------------------
     -- End of parse for numeric value
     ---------------------------------------------------------------------------
     END IF;

     ---------------------------------------------------------------------------
     -- Parse for canned value
     ---------------------------------------------------------------------------
     IF l_success = FALSE THEN
       FOR i IN 1..l_tbl_sel_pieces.count
       LOOP
         IF SUBSTR(l_sql_select_left,
                   1,
                   LENGTH(l_tbl_sel_pieces(i))
                  ) = UPPER(l_tbl_sel_pieces(i)) THEN
            l_sql_select_left    := SUBSTR(l_sql_select_left,
                                           LENGTH(l_tbl_sel_pieces(i))+1
                                          );
            l_success            := TRUE;
            EXIT;
         END IF;
       END LOOP;
     ---------------------------------------------------------------------------
     -- End of parse for canned value
     ---------------------------------------------------------------------------
     END IF;

     ---------------------------------------------------------------------------
     -- Parse for formula value
     ---------------------------------------------------------------------------
      IF l_success = FALSE  AND SUBSTR(l_sql_select_left,
                                       1,
                                       10) = UPPER('cn_formula') THEN
     ---------------------------------------------------------------------------
     -- Parse for p_commission_line_id
     ---------------------------------------------------------------------------
         l_ix               := INSTR(l_sql_select_left,
                                     UPPER('p_commission_line_id')
                                    );
         l_seg              := SUBSTR(l_sql_select_left,1,l_ix+20);
         l_sql_select_left  := SUBSTR(l_sql_select_left, l_ix+21);

         l_formula_stored_name := l_seg;
         FOR rec_calc_formulas IN c_calc_formulas(l_seg)
         LOOP
           l_seg                           := rec_calc_formulas.name;
           rec_formula.l_formula           := l_seg;
           rec_formula.l_calc_formula_id   := rec_calc_formulas.calc_formula_id;
           rec_formula.l_storedname        := l_formula_stored_name;
           l_formula_tbl_id                := l_formula_tbl_id + 1;
           p_tbl_formula(l_formula_tbl_id) := rec_formula;
           l_success := TRUE;
         END LOOP;
     ---------------------------------------------------------------------------
     -- End of parse for formula value
     ---------------------------------------------------------------------------
      END IF;

     ---------------------------------------------------------------------------
     -- Parse for user-defined function
     ---------------------------------------------------------------------------
      IF l_success = FALSE THEN
         FOR f IN c_user_objects(l_sql_select_left)
         LOOP
           IF SUBSTR(l_sql_select_left,
                     1,
                     length(f.object_name)+1) = UPPER(f.object_name) || '(' THEN
              -- found a function
              l_sql_select_left  := SUBSTR(l_sql_select_left,
                                           length(f.object_name)+2);
              l_success          := TRUE;
           END IF;
         END LOOP;
     ---------------------------------------------------------------------------
     -- End of parse for user-defined function
     ---------------------------------------------------------------------------
     END IF;

     ---------------------------------------------------------------------------
     -- Trim spaces
     ---------------------------------------------------------------------------
     IF l_success = FALSE AND SUBSTR(l_sql_select_left,1,1) = ' ' THEN
            l_sql_select_left := substr(l_sql_select_left,2);
            l_success := true;
     END IF;

     ---------------------------------------------------------------------------
     -- Parse for elements like [something].[something else]
     ---------------------------------------------------------------------------
     IF l_success = FALSE AND l_sql_select_left IS NOT NULL THEN
     ---------------------------------------------------------------------------
     -- Parse for dot and table alias
     ---------------------------------------------------------------------------
        l_ix       := INSTR(l_sql_select_left, '.');
        l_seg      := SUBSTR(l_sql_select_left, 1, l_ix - 1);
        l_disp_seg := NULL;
        OPEN  c_get_tbl(l_seg);
        FETCH c_get_tbl INTO l_disp_seg, l_table_id, l_table_name;
        CLOSE c_get_tbl;
        IF l_disp_seg IS NULL THEN
           RAISE FND_API.G_EXC_ERROR;
        END IF;

        l_sql_select_left  := SUBSTR(l_sql_select_left, l_ix+1);
        l_ix               := LENGTH(l_sql_select_left) + 1;

        FOR c IN 1..l_tbl_opers.count LOOP
           IF INSTR(l_sql_select_left, l_tbl_opers(c)) BETWEEN 1 AND l_ix THEN
              l_ix := INSTR(l_sql_select_left, l_tbl_opers(c));
           END IF;
        END LOOP;

        l_seg      := SUBSTR(l_sql_select_left, 1, l_ix - 1);
        l_disp_seg := NULL;
            OPEN  c_get_col(l_seg, l_table_id);
        FETCH c_get_col into l_disp_seg;
        CLOSE c_get_col;

        IF l_disp_seg IS NULL THEN
           RAISE FND_API.G_EXC_ERROR;
        END IF;

        l_sql_select_left  := substr(l_sql_select_left, l_ix);
            l_success   := true;
     ---------------------------------------------------------------------------
     -- End of parse for elements like [something].[something else]
     ---------------------------------------------------------------------------
     END IF;

     IF l_ct = 400 THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

     IF l_success = FALSE THEN
     ---------------------------------------------------------------------------
     -- End of total parse
     ---------------------------------------------------------------------------
        EXIT;
     END IF;
   END LOOP;

  EXCEPTION
  WHEN OTHERS THEN
      RAISE;
  END cnc_parse_sql_prc;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_formula_prc
   --
   -- Description   : This procedure parses the given formula to obtain all the
   --                 expressions associated and calls cn_parse_expression_prc
   --                 so as to explore the next level of embedded elements
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_formula_prc(p_formula    IN VARCHAR2,
                                  p_formula_id IN NUMBER,
                                  p_storedname IN VARCHAR2,
                                  p_level      IN NUMBER) IS
     ---------------------------------------------------------------------------
     -- Cursor to retrieve the expressions associated to a formula
     -- Input parameter to the cursor is the id of a formula
     ---------------------------------------------------------------------------
     CURSOR c_get_formula_expr(p_calc_formula_id NUMBER) IS
      SELECT  CCFA.name               FORMULA,
              CCSEA.name              EXPRESSION_INPUT,
              CCSEA.calc_sql_exp_id   EXPRESSION_INPUT_ID,
              CCSEA1.name             EXPRESSION_OUTPUT,
              CCSEA1.calc_sql_exp_id  EXPRESSION_OUTPUT_ID,
              CCSEA2.name             EXPRESSION_FORECAST,
              CCSEA2.calc_sql_exp_id  EXPRESSION_FORECAST_ID
        FROM  cn_calc_formulas_all    CCFA,
              cn_formula_inputs_all   CFIA,
              cn_calc_sql_exps_all    CCSEA,
              cn_calc_sql_exps_all    CCSEA1,
              cn_calc_sql_exps_all    CCSEA2
       WHERE  1                          =  1
         AND  CFIA.calc_formula_id    (+)=  CCFA.calc_formula_id
         AND  CFIA.org_id             (+)=  CCFA.org_id
         AND  CCSEA.calc_sql_exp_id   (+)=  CFIA.calc_sql_exp_id
         AND  CCSEA1.calc_sql_exp_id  (+)=  CCFA.output_exp_id
         AND  CCSEA2.calc_sql_exp_id  (+)=  CCFA.f_output_exp_id
         AND  CCFA.calc_formula_id       =  p_calc_formula_id
         AND  CCFA.org_id                =  FND_PROFILE.VALUE('ORG_ID');
  BEGIN
     ---------------------------------------------------------------------------
     -- Insert the formula received as input into the hierarchy table
     ---------------------------------------------------------------------------
         rec_level.l_name            := p_formula;
         rec_level.l_stname          := p_storedname;
         rec_level.l_level           := p_level;
         rec_level.l_type            := 'FORMULA';
         l_tbl_level_id              := l_tbl_level_id + 1;
         l_tbl_level(l_tbl_level_id) := rec_level;

     ---------------------------------------------------------------------------
     -- Loop through the cursor c_get_formula_expr in order to obtain all the
     -- expressions associated to the formula
     ---------------------------------------------------------------------------
         FOR rec_get_formula_expr IN c_get_formula_expr(p_formula_id)
         LOOP
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- input expression associated to the formula
     ---------------------------------------------------------------------------
           IF rec_get_formula_expr.expression_input IS NOT NULL THEN
             cnc_parse_expr_prc(rec_get_formula_expr.expression_input_id,
                                rec_get_formula_expr.expression_input,
                                p_level+1
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- output expression associated to the formula
     ---------------------------------------------------------------------------
           IF rec_get_formula_expr.expression_output IS NOT NULL THEN
             cnc_parse_expr_prc(rec_get_formula_expr.expression_output_id,
                                rec_get_formula_expr.expression_output,
                                p_level+1
                               );
           END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- forecast expression associated to the formula
     ---------------------------------------------------------------------------
           IF rec_get_formula_expr.expression_forecast IS NOT NULL THEN
             cnc_parse_expr_prc(rec_get_formula_expr.expression_forecast_id,
                                rec_get_formula_expr.expression_forecast,
                                p_level+1
                               );
           END IF;
         END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
       cnc_write_log_prc('cnc_parse_formula_prc: ' || SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_parse_formula_prc;

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
                                 ) IS
     ---------------------------------------------------------------------------
     -- Cursor to retrieve the expressions associated to a plan element
     -- Input parameter to the cursor is the id of plan element
     ---------------------------------------------------------------------------
    CURSOR c_planele_expr(p_plan_ele_id NUMBER) IS
     SELECT  CCSEA.name              EXPRESSION_INPUT,
             CCSEA.calc_sql_exp_id   EXPRESSION_INPUT_ID,
             CCSEA1.name             EXPRESSION_OUTPUT,
             CCSEA1.calc_sql_exp_id  EXPRESSION_OUTPUT_ID,
             CCSEA2.name             EXPRESSION_FORECAST,
             CCSEA2.calc_sql_exp_id  EXPRESSION_FORECAST_ID
       FROM  cn_quotas_all           CQA
            ,cn_calc_formulas_all    CCFA
            ,cn_formula_inputs_all   CFIA
            ,cn_calc_sql_exps_all    CCSEA
            ,cn_calc_sql_exps_all    CCSEA1
            ,cn_calc_sql_exps_all    CCSEA2
      WHERE  1                          =  1
        AND  CCFA.calc_formula_id    (+)=  CQA.calc_formula_id
        AND  CCFA.org_id             (+)=  CQA.org_id
        AND  CFIA.calc_formula_id    (+)=  CCFA.calc_formula_id
        AND  CFIA.org_id             (+)=  CCFA.org_id
        AND  CCSEA.calc_sql_exp_id   (+)=  CFIA.calc_sql_exp_id
        AND  CCSEA1.calc_sql_exp_id  (+)=  CCFA.output_exp_id
        AND  CCSEA2.calc_sql_exp_id  (+)=  CCFA.f_output_exp_id
        AND  CQA.delete_flag         (+)=  'N'
        AND  CQA.quota_id               =  p_plan_ele_id;
  BEGIN
     ---------------------------------------------------------------------------
     -- Insert the Plan Element received as input into the hierarchy table
     ---------------------------------------------------------------------------
       rec_level.l_name            := p_planelement;
       rec_level.l_stname          := p_storedname;
       rec_level.l_level           := p_level;
       rec_level.l_type            := 'PLANELEMENT';
       l_tbl_level_id              := l_tbl_level_id + 1;
       l_tbl_level(l_tbl_level_id) := rec_level;
     ---------------------------------------------------------------------------
     -- Loop through the cursor c_planele_expr in order to obtain all the
     -- expressions associated to the formula
     ---------------------------------------------------------------------------
       FOR rec_planele_expr IN c_planele_expr(p_quota_id)
       LOOP
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- input expression associated to the plan element
     ---------------------------------------------------------------------------
         IF rec_planele_expr.expression_input IS NOT NULL THEN
           cnc_parse_expr_prc(rec_planele_expr.expression_input_id,
                              rec_planele_expr.expression_input,
                              p_level+1
                             );
         END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- output expression associated to the plan element
     ---------------------------------------------------------------------------
         IF rec_planele_expr.expression_output IS NOT NULL THEN
           cnc_parse_expr_prc(rec_planele_expr.expression_output_id,
                              rec_planele_expr.expression_output,
                              p_level+1
                             );
         END IF;
     ---------------------------------------------------------------------------
     -- Call cnc_parse_expr_prc to find all the embedded elements in the
     -- forecast expression associated to the plan element
     ---------------------------------------------------------------------------
         IF rec_planele_expr.expression_forecast IS NOT NULL THEN
           cnc_parse_expr_prc(rec_planele_expr.expression_forecast_id,
                              rec_planele_expr.expression_forecast,
                              p_level+1
                             );
         END IF;
       END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
       cnc_write_log_prc('cnc_parse_planele_prc: ' ||SUBSTR(SQLERRM,1,256));
       RAISE;
  END cnc_parse_planele_prc;

     -----------------------------------------------------------------------------
   -- Procedure     : cnc_write_log_prc
   --
   -- Description   : This procedure writes the log file for the entire program
   -----------------------------------------------------------------------------
  PROCEDURE cnc_write_log_prc(p_message IN VARCHAR2) IS
  BEGIN
       g_errorlog := g_errorlog || CHR(10) || p_message;
  EXCEPTION
  WHEN OTHERS THEN
       RAISE;
  END cnc_write_log_prc;

END XX_OIC_PLANRATE_EXP_PKG;
/