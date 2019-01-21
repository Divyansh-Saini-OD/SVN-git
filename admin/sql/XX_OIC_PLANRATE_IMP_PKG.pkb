create or replace
PACKAGE BODY      XX_OIC_PLANRATE_IMP_PKG AS

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XXOICPLANRATEIMPB.pls                             |
   -- | Description : Package to import data as a part of the OIC PLAN    |
   -- |               COPY Object                                         |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07  1.0        This package is used to implement import     |
   -- |                      the data in the XML file to target instance  |
   -- |                                                                   |
   -- +===================================================================+

    g_debug_flag                VARCHAR2(1) := NULL;
   -----------------------------------------------------------------------------
    --  Constants to define the type of expression node
    --  that is being passed to CNC_CREATE_EXPRESSION_PRC procedure
   -----------------------------------------------------------------------------
    L_EXP_FINPUT               CONSTANT VARCHAR2(10) := 'FINPUT';
    L_EXP_INPUT                CONSTANT VARCHAR2(10) := 'INPUT';
    L_EXP_OUTPUT               CONSTANT VARCHAR2(10) := 'OUTPUT';
    L_EXP_DEPEND               CONSTANT VARCHAR2(10) := 'DEPENDENT';
    L_EXP_PERFMEAS             CONSTANT VARCHAR2(12) := 'PERFMEASURE';

   -----------------------------------------------------------------------------
    --  Constants to define the type of formula/plan element node
    --  that is being passed to cnc_create_formula_prc/create planele procedure
   -----------------------------------------------------------------------------
    L_DEPENDENT_TAGTYPE       CONSTANT VARCHAR2(10)  := 'DEPENDENT';
    L_MAIN_TAGTYPE            CONSTANT VARCHAR2(10)  := 'MAIN';

   -----------------------------------------------------------------------------
    --  Constants to define the type of element created so as to store in the
    --  table g_tbl_type_created_ele
   -----------------------------------------------------------------------------
    L_EXPR_ELE                CONSTANT VARCHAR2(10)  := 'EXPR';
    L_FORMULA_ELE             CONSTANT VARCHAR2(10)  := 'FORMULA';
    L_RATESCH_ELE             CONSTANT VARCHAR2(10)  := 'RATESCH';
    L_RATEDIM_ELE             CONSTANT VARCHAR2(10)  := 'RATEDIM';
    L_PLANELE_ELE             CONSTANT VARCHAR2(10)  := 'PLANELE';

  ------------------------------------------------------------------------------
  --Function: cnc_retdomdoc_fnc
  --Function to accept XML data in a CLOB object and return XML DOMDocument
  ------------------------------------------------------------------------------
    FUNCTION cnc_retdomdoc_fnc(p_xml IN CLOB) RETURN xmldom.DOMDocument IS
       l_retDoc xmldom.DOMDocument;
       l_parser xmlparser.Parser;
    BEGIN

      IF p_xml IS NULL THEN
         RETURN NULL;
      END IF;

      l_parser   :=xmlparser.newParser;
      xmlparser.parseClob(l_parser,p_xml);
      l_retDoc   := xmlparser.getDocument(l_parser);
      xmlparser.freeParser(l_parser);

      RETURN l_retDoc;
    EXCEPTION
    WHEN OTHERS THEN
        xmlparser.freeParser(l_parser);
        cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
        RETURN l_retdoc;
        RAISE g_parse_error;
    END cnc_retdomdoc_fnc;

  ------------------------------------------------------------------------------
  --  Function: cn_created_ele_fnc
  --  Function to validate if the element was created by the program or if it
  --  existed prior to this program
  --  Returns true if the program created
  --  Returns false if it was created prior to the program
  ------------------------------------------------------------------------------
    FUNCTION cn_created_ele_fnc(p_name IN VARCHAR2, p_type IN VARCHAR2)
             RETURN BOOLEAN IS
    BEGIN
        IF g_tbl_created_ele.EXISTS(1) THEN
           FOR i IN g_tbl_created_ele.FIRST .. g_tbl_created_ele.LAST
           LOOP
               IF g_tbl_created_ele(i).l_name = p_name
                                   AND g_tbl_created_ele(i).l_type = p_type THEN
                  RETURN TRUE;
               END IF;
           END LOOP;
           RETURN FALSE;
        ELSE
           RETURN FALSE;
        END IF;
    EXCEPTION
    WHEN others THEN
         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
         RAISE;
    END cn_created_ele_fnc;

  ------------------------------------------------------------------------------
  --Procedure: CNC_SUBMIT_PLANRATE_PRC
  --Procedure to call the concurrent program
  ------------------------------------------------------------------------------
    PROCEDURE cnc_submit_planrate_prc(p_xml_file   IN  CLOB,
                                      p_request_id OUT NOCOPY NUMBER,
                                      p_seq_id     OUT NOCOPY NUMBER,
                                      p_debug_flag IN  VARCHAR2)
    AS

    --declare variables
    l_application_id NUMBER;
    l_resp_id        NUMBER;

    BEGIN
       BEGIN
          SELECT XX_OIC_xmldata_s.NEXTVAL
            INTO p_seq_id
            FROM DUAL;

          INSERT INTO XX_OIC_xmldata(imp_seq_id, xml_data)
                               VALUES(p_seq_id, p_xml_file);

          COMMIT;
       EXCEPTION
       WHEN OTHERS THEN
            RAISE;
       END;


       p_request_id := FND_REQUEST.SUBMIT_REQUEST
                  (application   => 'XXCRM',
                   program       => 'XX_OIC_IMP_PLAN_COPY',
                   description   => NULL ,
                   start_time    => NULL,
                   sub_request   => FALSE,
                   argument1     => p_seq_id,
                         argument2     => p_debug_flag
                  );
      COMMIT;

       BEGIN
          UPDATE XX_OIC_xmldata SET conc_req_id = p_request_id
                           WHERE imp_seq_id  = p_seq_id;
          COMMIT;
       EXCEPTION
       WHEN OTHERS THEN
            RAISE;
       END;

    EXCEPTION
         WHEN OTHERS THEN
              p_seq_id     := 0;
              p_request_id := 0;
    END cnc_submit_planrate_prc;

  ------------------------------------------------------------------------------
  --Procedure: CNC_WRITE_OUT_PRC
  --Procedure to write the final log
  ------------------------------------------------------------------------------
    PROCEDURE cnc_write_out_prc(p_log_out IN CLOB,
                                p_seq_id  IN NUMBER)
    AS
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN

      UPDATE XX_OIC_xmldata SET
             log_output  = p_log_out
       WHERE imp_seq_id  = p_seq_id;

      fnd_file.put_line(fnd_file.log,g_errorlog);

      COMMIT;

    EXCEPTION
         WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,SUBSTR(SQLERRM,1,256));
    END;

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_PLANRATE_PRC
  --Procedure to determine the type of import and call the suitable procedure
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_planrate_prc(errbuf       OUT  NOCOPY VARCHAR2,
                                      retcode      OUT  NOCOPY NUMBER,
                                      p_seq_id     IN   NUMBER,
                                      p_debug_flag IN   VARCHAR2 DEFAULT 'N')
    IS
         l_indx1      NUMBER       := 0;
         l_indx2      NUMBER       := 0;
         l_imp_type   VARCHAR2(10) := NULL;
         l_xml_file   CLOB         := NULL;
         l_request_id NUMBER       :=  APPS.FND_GLOBAL.CONC_REQUEST_ID;
    BEGIN
        --Set the flag for debug
        g_debug_flag := p_debug_flag;


       -- Call error package to insert error headers for PLANCOPY
        XX_OIC_ERRORS_PKG.cnc_insert_header_record_prc
               ( p_pgm_name     =>    'OIC PLANCOPY IMPORT',
                 p_request_id   =>    l_request_id
               );


        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Begin of OIC Plan Copy program',
                 p_field          => 'cnc_import_planrate_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

        BEGIN
             SELECT CX.xml_data
               INTO l_xml_file
               FROM XX_OIC_xmldata CX
              WHERE CX.imp_seq_id = p_seq_id;
 
        EXCEPTION
        WHEN others THEN
             RAISE;
        END;

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Obtained the data file from table',
                 p_field          => 'cnc_import_planrate_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

        g_errorlog  := NULL;
        l_indx1     := INSTR(l_xml_file,'<',1,3);
        l_indx1     := l_indx1 + 1;
        l_indx2     := INSTR(l_xml_file,'>',1,3);
        l_imp_type  := SUBSTR(l_xml_file,l_indx1,l_indx2 - l_indx1);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Import Type',
                 p_field          => 'cnc_import_planrate_prc',
                 p_field_value    => 'l_imp_type : '||l_imp_type,
                 p_record_id      => NULL
                );
        END IF;

        CASE l_imp_type
        WHEN 'PLANCOPY' THEN
 
             cnc_import_plan_prc(l_xml_file);
 
        WHEN 'RATECOPY' THEN
             cnc_import_rate_prc(l_xml_file);
        ELSE
             RAISE g_parse_error;
        END CASE;

        cnc_write_out_prc(g_errorlog,
                          p_seq_id);

        COMMIT;

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => SUBSTR('End of OIC Plan Copy program',1,250),
                 p_field          => 'cnc_import_planrate_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );


           XX_OIC_ERRORS_PKG.cnc_generate_summary_log_prc
                ( p_program_name    =>   'OIC PLANCOPY IMPORT',
                  p_request_id      =>   l_request_id,
                  p_total_rec_cnt   =>   NULL,
                  p_valid_rec_cnt   =>   NULL,
                  p_error_rec_cnt   =>   NULL,
                  p_retcode         =>   retcode
                );


        END IF;

    EXCEPTION
    WHEN g_no_revclass_error THEN
         cnc_write_log_prc('The Revenue Class is Missing. Please create the revenue class: '|| SUBSTR(SQLERRM,1,2000));
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_parse_error THEN
         cnc_write_log_prc('XML file is corrupt. Please provide a valid XML file.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_sql_parse_error THEN
         cnc_write_log_prc('The expression could not be parsed. Please validate the setups.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_compplan_error THEN
         cnc_write_log_prc('Error occured while creating the compensation plan.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_formula_not_found_error THEN
         cnc_write_log_prc('The formula required for setup is missing.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_exp_not_valid_error THEN
         cnc_write_log_prc('The expression is not valid. Please provide a valid expression.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_exp_error THEN
         cnc_write_log_prc('The expression could not be created.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_ratedim_error THEN
         cnc_write_log_prc('The rate dimension could not be created.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_ratesch_error THEN
         cnc_write_log_prc('The rate schedule could not be created.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_update_commsn_error THEN
         cnc_write_log_prc('The commission rate for rate could not be updated.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_formula_error THEN
         cnc_write_log_prc('The formula could not be created.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_gen_formula_error THEN
         cnc_write_log_prc('The formula could not be generated.');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN g_create_planele_error THEN
         cnc_write_log_prc('The plan element could not be created');
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    WHEN OTHERS THEN
         cnc_write_log_prc('Error occured while processing: '
                           || SUBSTR(SQLERRM,1,2000)
                          );
         cnc_write_out_prc(g_errorlog,
                           p_seq_id);
         ROLLBACK;
    END cnc_import_planrate_prc;

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_PLAN_PRC
  --Procedure to import the xml data into the target OIC instance
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_plan_prc(p_xml_file IN CLOB)
    IS
      l_result               CLOB := NULL;
      l_plancopy_doc         xmldom.DOMDocument;
      l_compplan_doc         xmldom.DOMDocument;
      l_quotas_doc           xmldom.DOMDocument;
      l_hierarchy_doc        xmldom.DOMDocument;
      --l_metrics_doc          xmldom.DOMDocument;

      l_plancopy_nodelist    xmldom.DOMNodeList;
      l_hierarchy_nodelist   xmldom.DOMNodeList;
      l_depexpr_nodelist     xmldom.DOMNodeList;
      l_depformula_nodelist  xmldom.DOMNodeList;
      l_planele_nodelist     xmldom.DOMNodeList;
      l_compplan_nodelist    xmldom.DOMNodeList;
      l_quotasgns_nodelist   xmldom.DOMNodeList;
      --l_metrics_nodelist     xmldom.DOMNodeList;

      l_plancopy_node        xmldom.domNode;
      l_quotasgns_node       xmldom.domNode;
      l_hierarchy_node       xmldom.domNode;
      l_depexpr_node         xmldom.domNode;
      l_depformula_node      xmldom.domNode;
      l_planele_node         xmldom.domNode;
      l_compplan_node        xmldom.domNode;
      --l_metrics_node         xmldom.domNode;

      l_top_tag              VARCHAR2(300)
              := '/OIC_PLAN_COPY/PLANCOPY';
      l_hierarchy_tag        VARCHAR2(300)
              := '/PLANCOPY/HIERARCHY/RECORD';
      l_depexpr_tag          VARCHAR2(300)
              := '/PLANCOPY/DEPENDENTS/DEPENDENT_EXPR/CN_CALC_SQL_EXPR_ALL';
      l_depformula_tag       VARCHAR2(300)
              := '/PLANCOPY/DEPENDENTS/DEPENDENT_FORMULA/CN_CALC_FORMULAS_ALL';
      l_planele_tag          VARCHAR2(300)
              := '/PLANCOPY/DEPENDENTS/DEPENDENT_PELE/CN_QUOTAS_ALL';
      l_compplan_tag         VARCHAR2(300)
              := '/PLANCOPY/COMP_PLAN/CN_COMP_PLANS_ALL';
      l_quotasgns_tag        VARCHAR2(300)
              := '/CN_COMP_PLANS_ALL/CN_QUOTA_ASSIGNS_ALL/XX_OIC_QUOTA_ASSIGN_OBJ';
 
      l_org_id      CONSTANT NUMBER(15)                            := TO_NUMBER (FND_PROFILE.VALUE ('ORG_ID'));
      l_max_level            NUMBER                                := 1;
      l_comp_plan_id         CN_COMP_PLANS.COMP_PLAN_ID%TYPE       := NULL;
      l_compplan_name        CN_COMP_PLANS.NAME%TYPE               := NULL;
      l_expr_exists          NUMBER                                := 0;
      l_formula_exists       NUMBER                                := 0;
      l_planele_exists       NUMBER                                := 0;
      l_planele_name         VARCHAR2(80)                          := NULL;
      l_exp_id               CN_CALC_SQL_EXPS.CALC_SQL_EXP_ID%TYPE := NULL;
      l_expr_name            CN_CALC_SQL_EXPS.NAME%TYPE            := NULL;
      l_formula_name         CN_CALC_FORMULAS.NAME%TYPE            := NULL;
      l_ref_flag             BOOLEAN                               := FALSE;

      l_x_comp_plan_id       CN_COMP_PLANS.COMP_PLAN_ID%TYPE       := 0;
      l_x_return_status      VARCHAR2(10)                          := 'F';
      l_x_loading_status     VARCHAR2(200)                         := NULL;
      l_x_msg_count          NUMBER                                := 0;
      l_x_msg_data           VARCHAR2(32767)                       := NULL;
      l_msg_index_out        VARCHAR2(2000)                        := NULL;
      l_x_error_mesg         VARCHAR2(2000)                        := NULL;
      l_x_error_code         VARCHAR2(200)                         := NULL;
      rec_ref_name           rec_type_ref_name;
      rec_comp_plan          cn_comp_plan_pub.comp_plan_rec_type;
      rec_quota_assign       cn_quota_assign_pub.quota_assign_rec_type;
      l_ovn                  NUMBER;

      l_created_by           NUMBER := 0;
      l_creation_date        DATE   := SYSDATE;
      l_updated_by           NUMBER := 0;
      l_update_date          DATE   := SYSDATE;
      l_last_update_login    NUMBER := 0;

    BEGIN

 
  ------------------------------------------------------------------------------
  --  Create the XML DOMDocument for parsing
  ------------------------------------------------------------------------------
        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Begin cnc_import_plan_prc',
                 p_field          => 'cnc_import_plan_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

        l_plancopy_doc := cnc_retdomdoc_fnc(p_xml_file);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Got l_plancopy_doc',
                 p_field          => 'cnc_import_plan_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
  ------------------------------------------------------------------------------
  --  Set the Org Context
  ------------------------------------------------------------------------------
 
  ------------------------------------------------------------------------------
  -- Get the data for the standard who columns
  ------------------------------------------------------------------------------
      FND_PROFILE.GET ('USER_ID', l_created_by);
      FND_PROFILE.GET ('USER_ID', l_updated_by);
      FND_PROFILE.GET ('LOGIN_ID',l_last_update_login);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Check if plan exists',
                 p_field          => 'cnc_import_plan_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
  ------------------------------------------------------------------------------
  --  Loop through the Compensation plan data
  ------------------------------------------------------------------------------
      l_plancopy_nodelist := xslprocessor.selectnodes(
                                            xmldom.makenode(l_plancopy_doc),
                                            l_top_tag);
       FOR l_plancopy_num IN 0 .. xmldom.getlength (l_plancopy_nodelist) -1
       LOOP
        l_plancopy_node      := xmldom.item (l_plancopy_nodelist,
                                             l_plancopy_num
                                            );
        l_result             := 'a';
        xmldom.writetoclob(l_plancopy_node,l_result);
        l_hierarchy_doc      := cnc_retdomdoc_fnc(l_result);

  ------------------------------------------------------------------------------
  -- Check whether the Compensation plan exists. If so ignore the plan and proceed
  ------------------------------------------------------------------------------
        l_compplan_nodelist := xslprocessor.selectnodes
                                   (xmldom.makenode(l_hierarchy_doc),
                                    l_compplan_tag
                                   );
          FOR l_compplan_num IN 0 .. xmldom.getlength(l_compplan_nodelist) - 1
          LOOP
            l_compplan_node
                            := xmldom.item (l_compplan_nodelist,
                                            l_compplan_num
                                           );
            l_compplan_name := xslprocessor.valueof (l_compplan_node,
                                                     'NAME'
                                                    );
 
          END LOOP;
          BEGIN
               l_comp_plan_id := 0;
               SELECT CCPA.comp_plan_id
                 INTO l_comp_plan_id
                 FROM cn_comp_plans_all CCPA
                WHERE CCPA.name   = l_compplan_name
                  AND CCPA.org_id = FND_PROFILE.VALUE('ORG_ID');
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_comp_plan_id := 0;
          WHEN OTHERS THEN
 
               cnc_write_log_prc('Error occured while processing the data'
                                 ||SUBSTR(SQLERRM,1,2000)
                                );
               RAISE;
          END;
          IF l_comp_plan_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Initialise the variables
  ------------------------------------------------------------------------------
            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Plan needs to be created',
                     p_field          => 'cnc_import_plan_prc',
                     p_field_value    => 'l_comp_plan_id : '||l_comp_plan_id,
                     p_record_id      => NULL
                    );
            END IF;

            g_tbl_ref_name.DELETE;
            g_ref_tbl_id          := 0;
            g_tbl_created_ele.DELETE;
            g_tbl_created_ele_id  := 0;
            l_max_level           := 1;

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Traverse hierarchy',
                 p_field          => 'cnc_import_plan_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

  ------------------------------------------------------------------------------
  --  Create nodelist to traverse Hierarchy table
  --  This block also stores the referred names in the table g_tbl_ref_name so
  --  as to reduce the overhead of again traversing through the data file
  ------------------------------------------------------------------------------
            l_hierarchy_nodelist := xslprocessor.selectnodes (
                                              xmldom.makenode(l_hierarchy_doc),
                                              l_hierarchy_tag);
            FOR l_hierarchy_num IN 0 .. xmldom.getlength(l_hierarchy_nodelist)-1
            LOOP
                l_hierarchy_node      := xmldom.item (l_hierarchy_nodelist,
                                                      l_hierarchy_num
                                                     );

                rec_ref_name.l_name   := xslprocessor.valueof (l_hierarchy_node,
                                                               'NAME'
                                                              );
                rec_ref_name.l_stname := xslprocessor.valueof (l_hierarchy_node,
                                                               'STNAME'
                                                              );
                rec_ref_name.l_type   := xslprocessor.valueof (l_hierarchy_node,
                                                               'TYPE'
                                                              );

  ------------------------------------------------------------------------------
  --  Store the referred names of plan elements and formulas
  --  in the table g_tbl_ref_name in order to facilitate a easy access when
  --  the need arises to replace these referred names with valid names
  --  Also insert in g_tbl_ref_name only if it does not contain the element
  ------------------------------------------------------------------------------
                l_ref_flag := FALSE;
                IF rec_ref_name.l_type <> 'EXPRESSION' THEN
                   IF g_tbl_ref_name.EXISTS(1) THEN
                      FOR i IN g_tbl_ref_name.FIRST .. g_tbl_ref_name.LAST
                      LOOP
                          IF g_tbl_ref_name(i).l_stname = rec_ref_name.l_stname
                          THEN
                             l_ref_flag := TRUE;
  ------------------------------------------------------------------------------
  --  If the element being searched is found in the g_tbl_ref_name, exit the
  --  loop to avoid overhead on search
  ------------------------------------------------------------------------------
                             EXIT;
                          END IF;
                      END LOOP;
                   END IF;
                   IF NOT l_ref_flag THEN
                      g_ref_tbl_id                 := g_ref_tbl_id + 1;
                      g_tbl_ref_name(g_ref_tbl_id) := rec_ref_name;
                   END IF;
                END IF;

  ------------------------------------------------------------------------------
  --  Find the maximum level among the hierarchy elements
  --  so as to process the hierarchy tree starting from the leaves
  ------------------------------------------------------------------------------
               IF (xslprocessor.valueof (l_hierarchy_node, 'LEVEL') >
                   l_max_level
                  )
               THEN
                   l_max_level  := xslprocessor.valueof (l_hierarchy_node,
                                                         'LEVEL'
                                                        );
               END IF;
  ------------------------------------------------------------------------------
  --  End Hierarcy traverse to find the maximum level
  ------------------------------------------------------------------------------
            END LOOP;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Found maximum level',
                     p_field          => 'cnc_import_plan_prc',
                     p_field_value    => 'l_max_level : '||l_max_level,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  Process the levels in descending order
  ------------------------------------------------------------------------------
            FOR I IN REVERSE 1 .. l_max_level
            LOOP
                FOR l_hierarchy_num IN
                                0 .. xmldom.getlength (l_hierarchy_nodelist) - 1
                LOOP
                    l_hierarchy_node := xmldom.item (l_hierarchy_nodelist,
                                                     l_hierarchy_num
                                                    );
                    IF(xslprocessor.valueof(l_hierarchy_node, 'LEVEL') = I) THEN

                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Hierarchy traversal',
                                 p_field          => 'cnc_import_plan_prc',
                                 p_field_value    => 'LEVEL : '||xslprocessor.valueof(l_hierarchy_node, 'LEVEL'),
                                 p_record_id      => NULL
                                );
                        END IF;

                       CASE xslprocessor.valueof (l_hierarchy_node, 'TYPE')
  ------------------------------------------------------------------------------
  --  If the element type is expression
  ------------------------------------------------------------------------------
                       WHEN 'EXPRESSION' THEN
  ------------------------------------------------------------------------------
  --  Process the XML data in the dependent expressions so that the
  --  required expression is processed
  ------------------------------------------------------------------------------
                          l_depexpr_nodelist
                                    := xslprocessor.selectnodes
                                            (
                                              xmldom.makenode(l_hierarchy_doc),
                                              l_depexpr_tag
                                            );
                          FOR l_depexpr_num IN 0 .. xmldom.getlength (
                                                         l_depexpr_nodelist) - 1
                          LOOP
                              l_depexpr_node := xmldom.item (l_depexpr_nodelist,
                                                             l_depexpr_num
                                                            );
                              l_expr_name    := xslprocessor.valueof
                                                       (l_depexpr_node, 'NAME');
                              IF(l_expr_name = xslprocessor.valueof (
                                                               l_hierarchy_node,
                                                               'NAME')
                                ) THEN

                                -- Write additional debug messages
                                IF g_debug_flag = 'Y' THEN
                                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                        (p_error_message  => 'Hierarchy traversal',
                                         p_field          => 'cnc_import_plan_prc',
                                         p_field_value    => 'l_expr_name : '||l_expr_name,
                                         p_record_id      => NULL
                                        );
                                END IF;

                                 l_expr_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the expression being processed exists in the instance
  --  If it doesnot exist, then create the expression
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_expr_exists
                                        FROM cn_calc_sql_exps_all CCSEA
                                       WHERE CCSEA.name = l_expr_name;
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_expr_exists := 0;
                                 WHEN OTHERS THEN
                                      cnc_write_log_prc('Error occured while '||
                                                        'traversing expression '
                                                        || 'hierarchy: '||
                                                        SUBSTR(SQLERRM,1,2000)
                                                       );
                                      RAISE;
                                 END;

                                 IF l_expr_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_depexpr_node,l_result);
                                     cnc_create_expression_prc(l_result,
                                                               L_EXP_DEPEND,
                                                               l_exp_id
                                                              );
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_expr_name
                                                          ,L_EXPR_ELE)
                                     THEN
                                         cnc_write_log_prc
                                          ('Warning: The expression: ' ||
                                           l_expr_name || ' exists.'
                                          );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
  ------------------------------------------------------------------------------
  --  If the element type is Formula
  ------------------------------------------------------------------------------
                       WHEN 'FORMULA' THEN
  ------------------------------------------------------------------------------
  --  Process the dependents XML data so that the required formula is processed
  ------------------------------------------------------------------------------
                          l_depformula_nodelist
                                              := xslprocessor.selectnodes(
                                                         xmldom.makenode(
                                                           l_hierarchy_doc),
                                                         l_depformula_tag);
                          FOR l_depformula_num IN 0 ..
                                 xmldom.getlength (l_depformula_nodelist) - 1
                          LOOP
                              l_depformula_node := xmldom.item (
                                                         l_depformula_nodelist,
                                                         l_depformula_num
                                                               );
                              IF(xslprocessor.valueof (l_depformula_node,
                                                       'NAME'
                                                      )
                                 = xslprocessor.valueof (l_hierarchy_node,
                                                        'NAME')
                                ) THEN
                                 l_formula_name := xslprocessor.valueof
                                                             (
                                                              l_depformula_node,
                                                              'NAME'
                                                             );
                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Hierarchy traversal',
                                             p_field          => 'cnc_import_plan_prc',
                                             p_field_value    => 'l_formula_name : '||l_formula_name,
                                             p_record_id      => NULL
                                            );
                                    END IF;

                                 l_formula_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the formula being processed exists in the instance
  --  If it doesnot exist, then create the formula
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_formula_exists
                                        FROM cn_calc_formulas_all CCFA
                                       WHERE CCFA.name   = l_formula_name
                                         AND CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_formula_exists := 0;
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc('Error occured while '
                                                         || 'traversing formula'
                                                         || ' hierarchy: '||
                                                         SUBSTR(SQLERRM,1,2000)
                                                        );
                                       RAISE;
                                 END;

                                 IF l_formula_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_depformula_node,l_result);
                                     cnc_create_formula_prc(l_result,
                                                            L_DEPENDENT_TAGTYPE
                                                           );
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_formula_name
                                                              ,L_FORMULA_ELE)
                                     THEN
                                         cnc_write_log_prc
                                          ('Warning: The formula: ' ||
                                           l_formula_name || ' exists.'
                                          );
                                         l_result   := 'a';
                                         xmldom.writetoclob(l_depformula_node,l_result);
                                         cnc_create_formula_prc(l_result,
                                                                L_DEPENDENT_TAGTYPE
                                                               );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
  ------------------------------------------------------------------------------
  --  If the element type is Plan Element
  ------------------------------------------------------------------------------
                       WHEN 'PLANELEMENT' THEN
                          l_planele_nodelist
                                      := xslprocessor.selectnodes
                                           (xmldom.makenode(l_hierarchy_doc),
                                            l_planele_tag);
                          FOR l_planele_num IN 0 ..
                                        xmldom.getlength(l_planele_nodelist) - 1
                          LOOP
                              l_planele_node := xmldom.item(l_planele_nodelist,
                                                            l_planele_num);
                              IF(xslprocessor.valueof (l_planele_node, 'NAME')
                                 =
                                 xslprocessor.valueof (l_hierarchy_node, 'NAME')
                                ) THEN
                                 l_planele_name   := xslprocessor.valueof
                                                          (l_planele_node,
                                                           'NAME');

                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Hierarchy traversal',
                                             p_field          => 'cnc_import_plan_prc',
                                             p_field_value    => 'l_planele_name : '||l_planele_name,
                                             p_record_id      => NULL
                                            );
                                    END IF;

                                 l_planele_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the Plan Element being processed exists in the instance
  --  If it doesnot exist, then create the Plan Element
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_planele_exists
                                        FROM cn_quotas_all CQA
                                       WHERE CQA.name        = l_planele_name
                                         AND CQA.delete_flag = 'N'
                                         AND CQA.org_id      = FND_PROFILE.VALUE('ORG_ID');
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_planele_exists := 0;
                                 WHEN OTHERS THEN
                                      cnc_write_log_prc('Error occured while '||
                                                        'traversing plan element'
                                                        || ' hierarchy: '||
                                                        SUBSTR(SQLERRM,1,2000)
                                                       );
                                      RAISE;
                                 END;

                                 IF l_planele_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_planele_node,l_result);
                                     cnc_create_planele_prc
                                                  (l_result,
                                                   L_DEPENDENT_TAGTYPE);
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_planele_name
                                                          ,L_PLANELE_ELE)
                                     THEN
                                         cnc_write_log_prc
                                          ('Warning: The Plan Element: ' ||
                                           l_planele_name || ' exists.'
                                          );
                                         l_result   := 'a';
                                         xmldom.writetoclob(l_planele_node,l_result);
                                         cnc_create_planele_prc
                                                  (l_result,
                                                   L_DEPENDENT_TAGTYPE
                                                  );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
                       ELSE
                          cnc_write_log_prc('Encountered invalid element type '
                                            || 'while parsing hierarchy: '
                                            || xslprocessor.valueof (l_hierarchy_node, 'TYPE')
                                           );
                       END CASE;
                    END IF;
                END LOOP;
  ------------------------------------------------------------------------------
  --  Finished processing all the levels in descending order
  ------------------------------------------------------------------------------
            END LOOP;

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Finished hierarchy traversal',
                 p_field          => 'cnc_import_plan_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

  ------------------------------------------------------------------------------
  --  Start processing the Compensation plan data
  ------------------------------------------------------------------------------
            l_compplan_nodelist := xslprocessor.selectnodes
                                     (xmldom.makenode(l_hierarchy_doc),
                                      l_compplan_tag);
            FOR l_compplan_num IN 0 .. xmldom.getlength(l_compplan_nodelist) - 1
            LOOP
                l_compplan_node
                               := xmldom.item (l_compplan_nodelist,
                                               l_compplan_num);
                l_result := 'a';
                xmldom.writetoclob(l_compplan_node,l_result);
                l_compplan_doc := cnc_retdomdoc_fnc(l_result);

                rec_comp_plan.name
                               := xslprocessor.valueof (l_compplan_node,
                                                        'NAME'
                                                       );
                rec_comp_plan.description
                               := xslprocessor.valueof (l_compplan_node,
                                                        'DESCRIPTION'
                                                       );
                rec_comp_plan.start_date
                               := xslprocessor.valueof (l_compplan_node,
                                                        'START_DATE'
                                                       );
                rec_comp_plan.end_date
                               := xslprocessor.valueof (l_compplan_node,
                                                        'END_DATE'
                                                       );
                rec_comp_plan.status
                               := xslprocessor.valueof (l_compplan_node,
                                                        'STATUS_CODE'
                                                       );
                rec_comp_plan.rc_overlap
                               := xslprocessor.valueof (l_compplan_node,
                                                        'ALLOW_REV_CLASS_OVERLAP'
                                                       );
  ------------------------------------------------------------------------------
  --  Create the Compensation Plan
  ------------------------------------------------------------------------------
                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Calling create_comp_plan API',
                         p_field          => 'cnc_import_plan_prc',
                         p_field_value    => 'rec_comp_plan.name : '||rec_comp_plan.name,
                         p_record_id      => NULL
                        );
                END IF;

                BEGIN
                      cn_comp_plan_pub.create_comp_plan
                                        (p_api_version    => 1,
                                         p_commit         => FND_API.G_FALSE,
                                         x_return_status  => l_x_return_status,
                                         x_msg_count      => l_x_msg_count,
                                         x_msg_data       => l_x_msg_data,
                                         p_comp_plan_rec  => rec_comp_plan,
                                         x_loading_status => l_x_loading_status,
                                         x_comp_plan_id   => l_x_comp_plan_id);

                      IF l_x_return_status <> 'S' THEN
                         IF (fnd_msg_pub.count_msg <> 0) THEN
                            FOR i IN 1 .. fnd_msg_pub.count_msg
                            LOOP
                                fnd_msg_pub.get
                                       (p_msg_index     => i,
                                        p_encoded       => FND_API.G_FALSE,
                                        p_data          => l_x_msg_data,
                                        p_msg_index_out => l_msg_index_out
                                       );
                                l_x_error_mesg := SUBSTR (l_x_error_mesg || '. '
                                                          || l_msg_index_out
                                                          ||': '
                                                          || l_x_msg_data,
                                                          1, 2000);
                            END LOOP;
                         END IF;

                         l_x_error_code := 'Error: Create compensation plan: '||
                                            rec_comp_plan.name;
                         l_x_error_mesg := SUBSTR(l_x_error_mesg,1,3000);
                         cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                           l_x_error_mesg
                                          );
                         ROLLBACK;
                         RAISE g_create_compplan_error;
                      ELSE
                         cnc_write_log_prc('Creation of Compensation plan ' ||
                                           'succeeded with loading status: ' ||
                                           l_x_loading_status
                                          );
                      END IF;
                EXCEPTION
                WHEN OTHERS THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE g_create_compplan_error;
                END;

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Completed create_comp_plan API',
                         p_field          => 'cnc_import_plan_prc',
                         p_field_value    => 'rec_comp_plan.name : '||rec_comp_plan.name,
                         p_record_id      => NULL
                        );
                END IF;

  ------------------------------------------------------------------------------
  --  Get the Plan element data and create the Plan Element
  --  Get also the data required to assign plan element to a compensation plan
  ------------------------------------------------------------------------------
                l_quotasgns_nodelist := xslprocessor.selectnodes
                                              (xmldom.makenode(l_compplan_doc),
                                               l_quotasgns_tag);
                FOR l_quotasgns_num IN 0 ..
                                     xmldom.getlength (l_quotasgns_nodelist) - 1
                LOOP
                    l_quotasgns_node := xmldom.item (l_quotasgns_nodelist,
                                                     l_quotasgns_num);
                    l_result       := 'a';
                    xmldom.writetoclob(l_quotasgns_node,l_result);
                    l_quotas_doc  := cnc_retdomdoc_fnc(l_result);

                    rec_quota_assign.comp_plan_name  := rec_comp_plan.name;
                    rec_quota_assign.quota_name      := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_quotas_doc, '/XX_OIC_QUOTA_ASSIGN_OBJ/CN_QUOTAS_ALL/XX_OIC_QUOTAS_OBJ/NAME');
                    rec_quota_assign.quota_sequence  := xslprocessor.valueof
                                                           (l_quotasgns_node,
                                                            'QUOTA_SEQUENCE'
                                                           );
                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Assigning PE to Plan',
                             p_field          => 'cnc_import_plan_prc',
                             p_field_value    => 'quota_name : '||rec_quota_assign.quota_name,
                             p_record_id      => rec_quota_assign.quota_sequence
                            );
                    END IF;

                    xmldom.freedocument(l_quotas_doc);
                    BEGIN
                         l_planele_exists := 0;
                         SELECT 1
                           INTO l_planele_exists
                           FROM cn_quotas_all CQA
                          WHERE CQA.name        = rec_quota_assign.quota_name
                            AND CQA.delete_flag <> 'Y'
                            AND CQA.org_id      = FND_PROFILE.VALUE('ORG_ID');
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         l_planele_exists := 0;
                    WHEN OTHERS THEN
                         cnc_write_log_prc('Error occured while creating '||
                                           'plan element: ' || SUBSTR(SQLERRM,1,2000));
                         RAISE;
                    END;

                    IF l_planele_exists = 0 THEN
                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Call to create PE',
                                 p_field          => 'cnc_import_plan_prc',
                                 p_field_value    => 'l_planele_exists : '||l_planele_exists,
                                 p_record_id      => NULL
                                );
                        END IF;
  ------------------------------------------------------------------------------
  --  Call cnc_create_planele_prc to create Plan element
  ------------------------------------------------------------------------------
                        cnc_create_planele_prc(l_result, L_MAIN_TAGTYPE);
                    ELSE
                        IF NOT cn_created_ele_fnc(rec_quota_assign.quota_name,
                                                  L_PLANELE_ELE
                                                 )
                        THEN
                            cnc_write_log_prc
                            ('Warning: The Plan Element: ' ||
                              rec_quota_assign.quota_name || ' exists.'
                            );

                            -- Write additional debug messages
                            IF g_debug_flag = 'Y' THEN
                               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                    (p_error_message  => 'Call to create PE',
                                     p_field          => 'cnc_import_plan_prc',
                                     p_field_value    => 'l_planele_exists : '||l_planele_exists,
                                     p_record_id      => NULL
                                    );
                            END IF;

                            cnc_create_planele_prc(l_result, L_MAIN_TAGTYPE);
                        END IF;
                    END IF;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Call create_quota_assign API',
                             p_field          => 'cnc_import_plan_prc',
                             p_field_value    => 'quota_name : '||rec_quota_assign.quota_name,
                             p_record_id      => NULL
                            );
                    END IF;

  ------------------------------------------------------------------------------
  --  Assign the Plan element to the Compensation plan
  ------------------------------------------------------------------------------
                   BEGIN
                        cn_quota_assign_pub.create_quota_assign
                                   (p_api_version          => 1,
                                    p_commit               => FND_API.G_FALSE,
                                    p_quota_assign_rec     => rec_quota_assign,
                                    x_return_status        => l_x_return_status,
                                    x_msg_count            => l_x_msg_count,
                                    x_msg_data             => l_x_msg_data
                                   );
                        IF l_x_return_status <> 'S' THEN
                          IF (fnd_msg_pub.count_msg <> 0) THEN
                            FOR i IN 1 .. fnd_msg_pub.count_msg
                            LOOP
                                fnd_msg_pub.get
                                            (p_msg_index     => i,
                                             p_encoded       => FND_API.G_FALSE,
                                             p_data          => l_x_msg_data,
                                             p_msg_index_out => l_msg_index_out
                                            );
                                l_x_error_mesg := SUBSTR (l_x_error_mesg || ' '
                                                          || l_msg_index_out ||
                                                          l_x_msg_data,
                                                          1,
                                                          2000);
                            END LOOP;
                          END IF;

                          l_x_error_code
                              := 'Error: Assignment of plan: ' ||
                                 rec_quota_assign.comp_plan_name ||
                                 ' and plan element: '||
                                 rec_quota_assign.quota_name;
                          l_x_error_mesg := SUBSTR(l_x_error_mesg,1, 2000);
                          cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                            l_x_error_mesg
                                           );
                          ROLLBACK;
                          RAISE g_assign_planelement_error;
                        ELSE
                          cnc_write_log_prc('Assignment of plan: '||
                                             rec_quota_assign.comp_plan_name ||
                                             ' and plan element: '||
                                             rec_quota_assign.quota_name ||
                                             ' succeeded'
                                           );
                        END IF;
                   EXCEPTION
                   WHEN others THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE g_assign_planelement_error;
                   END;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Done with create_quota_assign API',
                             p_field          => 'cnc_import_plan_prc',
                             p_field_value    => 'quota_name : '||rec_quota_assign.quota_name,
                             p_record_id      => NULL
                            );
                    END IF;

  ------------------------------------------------------------------------------
  --  End of looping through the Quota Assignment data
  ------------------------------------------------------------------------------
                END LOOP;
 
                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'End of plan processing',
                         p_field          => 'cnc_import_plan_prc',
                         p_field_value    => NULL,
                         p_record_id      => NULL
                        );
                END IF;

                xmldom.freedocument(l_compplan_doc);
  ------------------------------------------------------------------------------
  --  End of looping through the Compensation plan data
  ------------------------------------------------------------------------------
            END LOOP;
            xmldom.freedocument(l_hierarchy_doc);
  ------------------------------------------------------------------------------
  --  Commit the compensation plan being processed
  ------------------------------------------------------------------------------
            COMMIT;
            cnc_write_log_prc('The compensation plan: ' ||l_compplan_name
                              ||' was created succesfully.'
                             );
  ------------------------------------------------------------------------------
  --  End of looping through the Plan Copy data
  ------------------------------------------------------------------------------
          ELSE
             cnc_write_log_prc('The compensation plan: ' ||l_compplan_name
                 ||' exists. The program will not recreate'
                 || ' this compensation plan.'
                );
          END IF;
       END LOOP;
       xmldom.freedocument(l_plancopy_doc);
    EXCEPTION
    WHEN OTHERS THEN
         cnc_write_log_prc('Error occured while processing: '
                           || SUBSTR(SQLERRM,1,2000)
                          );
         RAISE;
    END CNC_IMPORT_PLAN_PRC;

  ------------------------------------------------------------------------------
  --Procedure: CNC_IMPORT_RATE_PRC
  --Procedure to import the xml data into the target OIC instance
  ------------------------------------------------------------------------------
    PROCEDURE cnc_import_rate_prc(p_xml_file IN CLOB)
    IS

      CURSOR c_formula_rates(p_calc_formula_id NUMBER) IS
         SELECT CRFAA.rt_formula_asgn_id,
                CRFAA.rate_schedule_id,
                CRFAA.start_date,
                CRFAA.end_date,
                CRSA.name,
                CRSA.commission_unit_code,
                CRFAA.object_version_number,
                CCFA.number_dim
           FROM cn_rt_formula_asgns_all CRFAA,
                cn_calc_formulas_all    CCFA,
                cn_rate_schedules_all   CRSA
          WHERE CRFAA.calc_formula_id  = CCFA.calc_formula_id
            AND CRFAA.org_id           = CCFA.org_id
            AND CRSA.rate_schedule_id  = CRFAA.rate_schedule_id
            AND CRSA.org_id            = CRFAA.org_id
            AND CCFA.calc_formula_id   = p_calc_formula_id
            AND CCFA.org_id            = FND_PROFILE.VALUE('ORG_ID');

      l_xml_file             CLOB;
      l_result               CLOB;
      l_org_id               NUMBER := 0;

      l_ratecopy_doc         xmldom.DOMDocument;
      l_ratesch_doc          xmldom.DOMDocument;
      l_hierarchy_doc        xmldom.DOMDocument;
      l_inexp_doc            xmldom.DOMDocument;
      l_rtdims_doc           xmldom.DOMDocument;
      l_rtasgns_doc          xmldom.DOMDocument;

      l_ratecopy_nodelist    xmldom.DOMNodeList;
      l_ratesch_nodelist     xmldom.DOMNodeList;
      l_hierarchy_nodelist   xmldom.DOMNodeList;
      l_depexpr_nodelist     xmldom.DOMNodeList;
      l_depformula_nodelist  xmldom.DOMNodeList;
      l_planele_nodelist     xmldom.DOMNodeList;
      l_outexpr_nodelist     xmldom.DOMNodeList;
      l_inexpr_nodelist      xmldom.DOMNodeList;
      l_finexpr_nodelist     xmldom.DOMNodeList;
      l_perfmeas_nodelist    xmldom.DOMNodeList;
      l_rtasgns_nodelist     xmldom.DOMNodeList;
      l_rtdims_nodelist      xmldom.DOMNodeList;
      l_rttiers_nodelist     xmldom.DOMNodeList;
      l_rtcommsn_nodelist    xmldom.DOMNodeList;

      l_ratecopy_node        xmldom.domNode;
      l_ratesch_node         xmldom.domNode;
      l_hierarchy_node       xmldom.domNode;
      l_depexpr_node         xmldom.domNode;
      l_depformula_node      xmldom.domNode;
      l_planele_node         xmldom.domNode;
      l_outexp_node          xmldom.domNode;
      l_inexp_node           xmldom.domNode;
      l_perfmeas_node        xmldom.domNode;
      l_rtasgns_node         xmldom.domNode;
      l_rtdims_node          xmldom.domNode;
      l_rttiers_node         xmldom.domNode;
      l_rtcommsn_node        xmldom.domNode;

      l_ratesch_name         CN_RATE_SCHEDULES.NAME%TYPE                 := NULL;
      l_rate_sch_id          CN_RATE_SCHEDULES.RATE_SCHEDULE_ID%TYPE     := NULL;
      l_expr_exists          NUMBER                                      := 0;
      l_formula_exists       NUMBER                                      := 0;
      l_planele_exists       NUMBER                                      := 0;
      l_rt_formula_asgn_id   CN_RT_FORMULA_ASGNS.RT_FORMULA_ASGN_ID%TYPE := NULL;
      l_planele_name         VARCHAR2(80)                                := NULL;
      l_exp_id               CN_CALC_SQL_EXPS.CALC_SQL_EXP_ID%TYPE       := NULL;
      l_expr_name            CN_CALC_SQL_EXPS.NAME%TYPE;
      l_calc_sql_exp_id      CN_CALC_SQL_EXPS.CALC_SQL_EXP_ID%TYPE;
      l_calc_formula_id      CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE;
      rec_ref_name           rec_type_ref_name;
  ------------------------------------------------------------------------------
  --    Parameters for calling the Create Formula API
  ------------------------------------------------------------------------------
      l_formula_name                 CN_CALC_FORMULAS.NAME%TYPE                 := NULL;
      l_formula_description          CN_CALC_FORMULAS.DESCRIPTION%TYPE          := NULL;
      l_formula_type                 CN_CALC_FORMULAS.FORMULA_TYPE%TYPE         := NULL;
      l_formula_status               CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_formula_trx_group_code       CN_CALC_FORMULAS.TRX_GROUP_CODE%TYPE       := NULL;
      l_formula_number_dim           CN_CALC_FORMULAS.NUMBER_DIM%TYPE           := NULL;
      l_number_dim                   CN_CALC_FORMULAS.NUMBER_DIM%TYPE           := NULL;
      l_formula_cumulative_flag      CN_CALC_FORMULAS.CUMULATIVE_FLAG%TYPE      := NULL;
      l_formula_itd_flag             CN_CALC_FORMULAS.ITD_FLAG%TYPE             := NULL;
      l_formula_split_flag           CN_CALC_FORMULAS.SPLIT_FLAG%TYPE           := NULL;
      l_threshold_all_tier_flag      CN_CALC_FORMULAS.THRESHOLD_ALL_TIER_FLAG%TYPE
                                                                        := NULL;
      l_formula_modeling_flag        CN_CALC_FORMULAS.MODELING_FLAG%TYPE        := NULL;
      l_formula_perf_measure_id      CN_CALC_FORMULAS.PERF_MEASURE_ID%TYPE      := NULL;
      l_formula_output_exp_id        CN_CALC_FORMULAS.OUTPUT_EXP_ID%TYPE        := NULL;

      l_formula_input_tbl            CN_CALC_FORMULAS_PVT.input_tbl_type;
      l_formula_input_tbl_id         NUMBER                                     := 0;
      l_formula_rt_assign_tbl        CN_CALC_FORMULAS_PVT.rt_assign_tbl_type;
      l_formula_rt_assign_id         NUMBER                                     := 0;
      l_object_version_number        CN_CALC_FORMULAS.OBJECT_VERSION_NUMBER%TYPE:= NULL;
      l_formula_x_calc_formula_id    CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE      := NULL;
      l_formula_x_formula_status     CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_x_formula_status             CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_rt_formula_exists            NUMBER                                     := NULL;
      rec_formula_input              CN_CALC_FORMULAS_PVT.input_rec_type;
      rec_formula_rt_assign          CN_CALC_FORMULAS_PVT.rt_assign_rec_type;

  ------------------------------------------------------------------------------
  --  Parameters for creating the rate schedules
  ------------------------------------------------------------------------------
      l_rate_name                    CN_RATE_SCHEDULES.NAME%TYPE                 := NULL;
      l_commission_unit_code         CN_RATE_SCHEDULES.COMMISSION_UNIT_CODE%TYPE := NULL;
      l_dim_name                     CN_RATE_DIMENSIONS.NAME%TYPE                := NULL;
      l_dim_description              CN_RATE_DIMENSIONS.DESCRIPTION%TYPE         := NULL;
      l_dim_unit_code                CN_RATE_DIMENSIONS.DIM_UNIT_CODE%TYPE       := NULL;
      l_rate_number_dim              CN_RATE_SCHEDULES.NUMBER_DIM%TYPE           := NULL;
      l_rate_schedule_id             CN_RATE_SCHEDULES.RATE_SCHEDULE_ID%TYPE     := NULL;
      l_rate_dim_sequence            CN_RATE_SCH_DIMS_ALL.RATE_DIM_SEQUENCE%TYPE := NULL;
      l_rate_number_tier             CN_RATE_DIMENSIONS_ALL.NUMBER_TIER%TYPE     := NULL;
      l_rate_dimension_id            CN_RATE_DIMENSIONS_ALL.RATE_DIMENSION_ID%TYPE := NULL;
      rec_rate_tier                  CN_MULTI_RATE_SCHEDULES_PUB.rate_tier_rec_type;
      rec_dim_assign                 CN_MULTI_RATE_SCHEDULES_PUB.dim_assign_rec_type;
      l_dim_assign_tbl               CN_MULTI_RATE_SCHEDULES_PUB.dim_assign_tbl_type;
      l_dim_assign_tbl_id            NUMBER                                      := 0;
      l_rate_tier_tbl                CN_MULTI_RATE_SCHEDULES_PUB.rate_tier_tbl_type;
      l_rate_tier_tbl_id             NUMBER                                      := 0;
      l_tier_coordinates_tbl         CN_MULTI_RATE_SCHEDULES_PUB.tier_coordinates_tbl;
      TYPE l_number_dim_tbl_type     IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
      l_number_dim_tbl               l_number_dim_tbl_type;
      l_number_dim_tbl_id            NUMBER                                      := 0;
      TYPE rec_type_commission       IS RECORD(l_rate_seq               NUMBER,
                                               l_commission_amount      NUMBER,
                                               l_object_version_number  NUMBER
                                               );
      rec_commission                 rec_type_commission;
      TYPE l_tbl_type_commission     IS TABLE OF rec_type_commission INDEX BY BINARY_INTEGER;
      l_tbl_commission               l_tbl_type_commission;
      l_max_level                    NUMBER                := 1;
      l_max_rate_seq                 NUMBER                := 0;
      l_mtrx_count                   NUMBER                := 0;
      l_dim_exists                   NUMBER                := 0;
      l_ref_flag                     BOOLEAN               := FALSE;

      l_x_return_status      VARCHAR2(10)                          := 'F';
      l_x_loading_status     VARCHAR2(200)                         := NULL;
      l_x_msg_count          NUMBER                                := 0;
      l_x_msg_data           VARCHAR2(32767)                       := NULL;
      l_msg_index_out        VARCHAR2(2000)                        := NULL;
      l_x_error_mesg         VARCHAR2(2000)                        := NULL;
      l_x_error_code         VARCHAR2(200)                         := NULL;

      l_created_by        NUMBER := 0;
      l_creation_date     DATE   := SYSDATE;
      l_updated_by        NUMBER := 0;
      l_update_date       DATE   := SYSDATE;
      l_last_update_login NUMBER := 0;

      l_top_tag              VARCHAR2(300)
              := '/OIC_PLAN_COPY/RATECOPY';
      l_hierarchy_tag        VARCHAR2(300)
              := '/RATECOPY/HIERARCHY/RECORD';
      l_depexpr_tag          VARCHAR2(300)
              := '/RATECOPY/DEPENDENTS/DEPENDENT_EXPR/CN_CALC_SQL_EXPR_ALL';
      l_depformula_tag       VARCHAR2(300)
              := '/RATECOPY/DEPENDENTS/DEPENDENT_FORMULA/CN_CALC_FORMULAS_ALL';
      l_planele_tag          VARCHAR2(300)
              := '/RATECOPY/DEPENDENTS/DEPENDENT_PELE/CN_QUOTAS_ALL';
      l_ratesch_tag          VARCHAR2(300)
              := '/RATECOPY/RATE_TABLE/CN_RATE_SCHEDULES_ALL';
      l_rtdims_tag           VARCHAR2(300)
              := '/CN_RATE_SCHEDULES_ALL/CN_RATE_SCH_DIMS_ALL/XX_OIC_RATE_SCH_DIMS_OBJ';
      l_rttiers_tag          VARCHAR2(300)
              := '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/CN_RATE_DIM_TIERS_ALL/XX_OIC_RATE_DIM_TIERS_OBJ';
      l_rtcommsn_tag         VARCHAR2(300)
              := '/CN_RATE_SCHEDULES_ALL/CN_RATE_TIERS_ALL/XX_OIC_RATE_TIERS_OBJ';
      l_rtasgns_tag          VARCHAR2(300)
              := '/CN_RATE_SCHEDULES_ALL/CN_RT_FORMULA_ASGNS_ALL/XX_OIC_RT_FORMULA_ASGN_RT_OBJ';
      l_outexp_tag           VARCHAR2(300)
              := '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/CN_OUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';
      l_inexp_tag            VARCHAR2(300)
              := '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/CN_FORMULA_INPUTS_ALL/XX_OIC_FORMULA_INPUTS_OBJ';
      l_perfmeas_tag         VARCHAR2(300)
              := '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/CN_PERF_MEASURES_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';

    BEGIN
  ------------------------------------------------------------------------------
  --  Create the XML DOMDocument for parsing
  ------------------------------------------------------------------------------
        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Start of rate import',
                 p_field          => 'cnc_import_rate_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

      l_ratecopy_doc := cnc_retdomdoc_fnc(p_xml_file);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Got the rate XML document',
                 p_field          => 'cnc_import_rate_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
  ------------------------------------------------------------------------------
  --  Set the Org Context
  ------------------------------------------------------------------------------
      l_org_id       := FND_PROFILE.VALUE('ORG_ID');

 
  ------------------------------------------------------------------------------
  -- Get the data for the standard who columns
  ------------------------------------------------------------------------------
      FND_PROFILE.GET ('USER_ID', l_created_by);
      FND_PROFILE.GET ('USER_ID', l_updated_by);
      FND_PROFILE.GET ('LOGIN_ID',l_last_update_login);
  ------------------------------------------------------------------------------
  --  Loop through the Rate Table data
  ------------------------------------------------------------------------------

      l_ratecopy_nodelist := xslprocessor.selectnodes(
                                            xmldom.makenode(l_ratecopy_doc),
                                            l_top_tag);
       FOR l_ratecopy_num IN 0 .. xmldom.getlength (l_ratecopy_nodelist) -1
       LOOP
        l_ratecopy_node      := xmldom.item (l_ratecopy_nodelist,
                                             l_ratecopy_num
                                            );
        l_result             := 'a';
        xmldom.writetoclob(l_ratecopy_node,l_result);
        l_hierarchy_doc      := cnc_retdomdoc_fnc(l_result);
  ------------------------------------------------------------------------------
  -- Check whether the Rate table exists. If so ignore the rate and proceed to next
  ------------------------------------------------------------------------------
        l_ratesch_nodelist := xslprocessor.selectnodes
                                   (xmldom.makenode(l_hierarchy_doc),
                                    l_ratesch_tag
                                   );
          FOR l_ratesch_num IN 0 .. xmldom.getlength(l_ratesch_nodelist) - 1
          LOOP
            l_ratesch_node
                            := xmldom.item (l_ratesch_nodelist,
                                            l_ratesch_num
                                           );
            l_ratesch_name := xslprocessor.valueof (l_ratesch_node,
                                                     'NAME'
                                                    );
          END LOOP;
          BEGIN
               l_rate_schedule_id := 0;
               SELECT CRSA.rate_schedule_id
                 INTO l_rate_schedule_id
                 FROM cn_rate_schedules_all CRSA
                WHERE CRSA.name   = l_ratesch_name
                  AND CRSA.org_id = FND_PROFILE.VALUE('ORG_ID');
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_rate_schedule_id := 0;
          WHEN OTHERS THEN
               cnc_write_log_prc('Error occured while processing the data'
                                 ||SUBSTR(SQLERRM,1,2000)
                                );
               RAISE;
          END;

          IF l_rate_schedule_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Initialise the variables
  ------------------------------------------------------------------------------
            g_tbl_ref_name.DELETE;
            g_ref_tbl_id          := 0;
            g_tbl_created_ele.DELETE;
            g_tbl_created_ele_id  := 0;
            l_max_level           := 1;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Processing hierarchy',
                     p_field          => 'cnc_import_rate_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;

  ------------------------------------------------------------------------------
  --  Create nodelist to traverse Hierarchy table
  --  This block also stores the referred names in the table g_tbl_ref_name so
  --  as to reduce the overhead of again traversing through the data file
  ------------------------------------------------------------------------------
            l_hierarchy_nodelist := xslprocessor.selectnodes (
                                              xmldom.makenode(l_hierarchy_doc),
                                              l_hierarchy_tag);
            FOR l_hierarchy_num IN 0 .. xmldom.getlength(l_hierarchy_nodelist)-1
            LOOP
                l_hierarchy_node      := xmldom.item (l_hierarchy_nodelist,
                                                      l_hierarchy_num
                                                     );

                rec_ref_name.l_name   := xslprocessor.valueof (l_hierarchy_node,
                                                               'NAME'
                                                              );
                rec_ref_name.l_stname := xslprocessor.valueof (l_hierarchy_node,
                                                               'STNAME'
                                                              );
                rec_ref_name.l_type   := xslprocessor.valueof (l_hierarchy_node,
                                                               'TYPE'
                                                              );

  ------------------------------------------------------------------------------
  --  Store the referred names of plan elements and formulas
  --  in the table g_tbl_ref_name in order to facilitate a easy access when
  --  the need arises to replace these referred names with valid names
  --  Also insert in g_tbl_ref_name only if it does not contain the element
  ------------------------------------------------------------------------------
                l_ref_flag := FALSE;
                IF rec_ref_name.l_type <> 'EXPRESSION' THEN
                   IF g_tbl_ref_name.EXISTS(1) THEN
                      FOR i IN g_tbl_ref_name.FIRST .. g_tbl_ref_name.LAST
                      LOOP
                          IF g_tbl_ref_name(i).l_stname = rec_ref_name.l_stname
                          THEN
                             l_ref_flag := TRUE;
  ------------------------------------------------------------------------------
  --  If the element being searched is found in the g_tbl_ref_name, exit the
  --  loop to avoid overhead on search
  ------------------------------------------------------------------------------
                             EXIT;
                          END IF;
                      END LOOP;
                   END IF;
                   IF NOT l_ref_flag THEN
                      g_ref_tbl_id                 := g_ref_tbl_id + 1;
                      g_tbl_ref_name(g_ref_tbl_id) := rec_ref_name;
                   END IF;
                END IF;

  ------------------------------------------------------------------------------
  --  Find the maximum level among the hierarchy elements
  --  so as to process the hierarchy tree starting from the leaves
  ------------------------------------------------------------------------------
               IF (xslprocessor.valueof (l_hierarchy_node, 'LEVEL') >
                   l_max_level
                  )
               THEN
                   l_max_level  := xslprocessor.valueof (l_hierarchy_node,
                                                         'LEVEL'
                                                        );
               END IF;
  ------------------------------------------------------------------------------
  --  End Hierarcy traverse to find the maximum level
  ------------------------------------------------------------------------------
            END LOOP;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Found max level',
                     p_field          => 'cnc_import_rate_prc',
                     p_field_value    => 'l_max_level : '||l_max_level,
                     p_record_id      => NULL
                    );
            END IF;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Processing elements',
                     p_field          => 'cnc_import_rate_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  Process the levels in descending order
  ------------------------------------------------------------------------------
            FOR I IN REVERSE 1 .. l_max_level
            LOOP
                FOR l_hierarchy_num IN
                                0 .. xmldom.getlength (l_hierarchy_nodelist) - 1
                LOOP
                    l_hierarchy_node := xmldom.item (l_hierarchy_nodelist,
                                                     l_hierarchy_num
                                                    );
                    IF(xslprocessor.valueof(l_hierarchy_node, 'LEVEL') = I) THEN

                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Hierarchy level',
                                 p_field          => 'cnc_import_rate_prc',
                                 p_field_value    => 'LEVEL : '||xslprocessor.valueof(l_hierarchy_node, 'LEVEL'),
                                 p_record_id      => NULL
                                );
                        END IF;

                       CASE xslprocessor.valueof (l_hierarchy_node, 'TYPE')
  ------------------------------------------------------------------------------
  --  If the element type is expression
  ------------------------------------------------------------------------------
                       WHEN 'EXPRESSION' THEN
  ------------------------------------------------------------------------------
  --  Process the XML data in the dependent expressions so that the
  --  required expression is processed
  ------------------------------------------------------------------------------
                          l_depexpr_nodelist
                                    := xslprocessor.selectnodes
                                            (
                                              xmldom.makenode(l_hierarchy_doc),
                                              l_depexpr_tag
                                            );
                          FOR l_depexpr_num IN 0 .. xmldom.getlength (
                                                         l_depexpr_nodelist) - 1
                          LOOP
                              l_depexpr_node := xmldom.item (l_depexpr_nodelist,
                                                             l_depexpr_num
                                                            );
                              l_expr_name    := xslprocessor.valueof
                                                       (l_depexpr_node, 'NAME');
                              IF(l_expr_name = xslprocessor.valueof (
                                                               l_hierarchy_node,
                                                               'NAME')
                                ) THEN

                                -- Write additional debug messages
                                IF g_debug_flag = 'Y' THEN
                                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                        (p_error_message  => 'Expression',
                                         p_field          => 'cnc_import_rate_prc',
                                         p_field_value    => 'l_expr_name : '||l_expr_name,
                                         p_record_id      => NULL
                                        );
                                END IF;

                                 l_expr_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the expression being processed exists in the instance
  --  If it doesnot exist, then create the expression
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_expr_exists
                                        FROM cn_calc_sql_exps_all CCSEA
                                       WHERE CCSEA.name = l_expr_name;
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_expr_exists := 0;
                                 WHEN OTHERS THEN
                                      cnc_write_log_prc('Error occured while '||
                                                        'traversing expression '
                                                        || 'hierarchy: '||
                                                        SUBSTR(SQLERRM,1,2000)
                                                       );
                                      RAISE;
                                 END;

                                 IF l_expr_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_depexpr_node,l_result);
                                     cnc_create_expression_prc(l_result,
                                                               L_EXP_DEPEND,
                                                               l_exp_id
                                                              );
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_expr_name
                                                          ,L_EXPR_ELE)
                                     THEN
                                         cnc_write_log_prc
                                          ('Warning: The expression: ' ||
                                           l_expr_name || ' exists.'
                                          );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
  ------------------------------------------------------------------------------
  --  If the element type is Formula
  ------------------------------------------------------------------------------
                       WHEN 'FORMULA' THEN
  ------------------------------------------------------------------------------
  --  Process the dependents XML data so that the required formula is processed
  ------------------------------------------------------------------------------
                          l_depformula_nodelist
                                              := xslprocessor.selectnodes(
                                                         xmldom.makenode(
                                                           l_hierarchy_doc),
                                                         l_depformula_tag);
                          FOR l_depformula_num IN 0 ..
                                 xmldom.getlength (l_depformula_nodelist) - 1
                          LOOP
                              l_depformula_node := xmldom.item (
                                                         l_depformula_nodelist,
                                                         l_depformula_num
                                                               );
                              IF(xslprocessor.valueof (l_depformula_node,
                                                       'NAME'
                                                      )
                                 = xslprocessor.valueof (l_hierarchy_node,
                                                        'NAME')
                                ) THEN
                                 l_formula_name := xslprocessor.valueof
                                                             (
                                                              l_depformula_node,
                                                              'NAME'
                                                             );
                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Formula',
                                             p_field          => 'cnc_import_rate_prc',
                                             p_field_value    => 'l_formula_name : '||l_formula_name,
                                             p_record_id      => NULL
                                            );
                                    END IF;
                                 l_formula_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the formula being processed exists in the instance
  --  If it doesnot exist, then create the formula
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_formula_exists
                                        FROM cn_calc_formulas_all CCFA
                                       WHERE CCFA.name   = l_formula_name
                                         AND CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_formula_exists := 0;
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc('Error occured while '
                                                         || 'traversing formula'
                                                         || ' hierarchy: '||
                                                         SUBSTR(SQLERRM,1,2000)
                                                        );
                                       RAISE;
                                 END;

                                 IF l_formula_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_depformula_node,l_result);
                                     cnc_create_formula_prc(l_result,
                                                            L_DEPENDENT_TAGTYPE
                                                           );
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_formula_name
                                                          ,L_FORMULA_ELE)
                                     THEN
                                         l_result   := 'a';
                                         xmldom.writetoclob(l_depformula_node,l_result);
                                         cnc_create_formula_prc(l_result,
                                                                L_DEPENDENT_TAGTYPE
                                                               );
                                         cnc_write_log_prc
                                          ('Warning: The formula: ' ||
                                           l_formula_name || ' exists.'
                                          );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
  ------------------------------------------------------------------------------
  --  If the element type is Plan Element
  ------------------------------------------------------------------------------
                       WHEN 'PLANELEMENT' THEN
                          l_planele_nodelist
                                      := xslprocessor.selectnodes
                                           (xmldom.makenode(l_hierarchy_doc),
                                            l_planele_tag);
                          FOR l_planele_num IN 0 ..
                                        xmldom.getlength(l_planele_nodelist) - 1
                          LOOP
                              l_planele_node := xmldom.item(l_planele_nodelist,
                                                            l_planele_num);
                              IF(xslprocessor.valueof (l_planele_node, 'NAME')
                                 =
                                 xslprocessor.valueof (l_hierarchy_node, 'NAME')
                                ) THEN
                                 l_planele_name   := xslprocessor.valueof
                                                          (l_planele_node,
                                                           'NAME');
                                -- Write additional debug messages
                                IF g_debug_flag = 'Y' THEN
                                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                        (p_error_message  => 'PLANELE',
                                         p_field          => 'cnc_import_rate_prc',
                                         p_field_value    => 'l_planele_name : '||l_planele_name,
                                         p_record_id      => NULL
                                        );
                                END IF;

                                 l_planele_exists := 0;
  ------------------------------------------------------------------------------
  --  Verify if the Plan Element being processed exists in the instance
  --  If it doesnot exist, then create the Plan Element
  ------------------------------------------------------------------------------
                                 BEGIN
                                      SELECT 1
                                        INTO l_planele_exists
                                        FROM cn_quotas_all CQA
                                       WHERE CQA.name        = l_planele_name
                                         AND CQA.delete_flag = 'N'
                                         AND CQA.org_id      = FND_PROFILE.VALUE('ORG_ID');
                                 EXCEPTION
                                 WHEN NO_DATA_FOUND THEN
                                      l_planele_exists := 0;
                                 WHEN OTHERS THEN
                                      cnc_write_log_prc('Error occured while '||
                                                        'traversing plan element'
                                                        || ' hierarchy: '||
                                                        SUBSTR(SQLERRM,1,2000)
                                                       );
                                      RAISE;
                                 END;

                                 IF l_planele_exists = 0 THEN
                                     l_result   := 'a';
                                     xmldom.writetoclob(l_planele_node,l_result);
                                     cnc_create_planele_prc
                                                  (l_result,
                                                   L_DEPENDENT_TAGTYPE);
                                 ELSE
                                     IF NOT cn_created_ele_fnc(l_planele_name
                                                          ,L_PLANELE_ELE)
                                     THEN
                                         l_result   := 'a';
                                         xmldom.writetoclob(l_planele_node,l_result);
                                         cnc_create_planele_prc
                                                  (l_result,
                                                   L_DEPENDENT_TAGTYPE);
                                         cnc_write_log_prc
                                          ('Warning: The Plan Element: ' ||
                                           l_planele_name || ' exists.'
                                          );
                                     END IF;
                                 END IF;
                                 EXIT;
                              END IF;
                          END LOOP;
                       ELSE
                          cnc_write_log_prc('Encountered invalid element type '
                                            || 'while parsing hierarchy: '
                                            || xslprocessor.valueof (l_hierarchy_node, 'TYPE')
                                           );
                       END CASE;
                    END IF;
                END LOOP;
  ------------------------------------------------------------------------------
  --  Finished processing all the levels in descending order
  ------------------------------------------------------------------------------
            END LOOP;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Done with Hierarchy',
                     p_field          => 'cnc_import_rate_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --   Create Rate tables
  ------------------------------------------------------------------------------
            l_ratesch_nodelist := xslprocessor.selectnodes
                                   (xmldom.makenode(l_hierarchy_doc),
                                    l_ratesch_tag
                                   );
            FOR l_ratesch_num IN 0 .. xmldom.getlength(l_ratesch_nodelist) - 1
            LOOP
               l_ratesch_node
                            := xmldom.item (l_ratesch_nodelist,
                                            l_ratesch_num
                                           );
               l_ratesch_name := xslprocessor.valueof (l_ratesch_node,
                                                     'NAME'
                                                    );
                l_result       := 'a';
                xmldom.writetoclob(l_ratesch_node, l_result);
                l_ratesch_doc  := cnc_retdomdoc_fnc(l_result);



                l_formula_rt_assign_tbl.DELETE;
                l_formula_rt_assign_id      := 0;
                rec_formula_rt_assign       := NULL;
                l_dim_assign_tbl_id         := 0;
                l_rate_tier_tbl_id          := 0;
                l_number_dim_tbl_id         := 0;
                l_dim_assign_tbl.DELETE;

                l_rate_name            := xslprocessor.valueof (l_ratesch_node, 'NAME');
                l_commission_unit_code := xslprocessor.valueof (l_ratesch_node, 'COMMISSION_UNIT_CODE');
                l_rate_number_dim      := xslprocessor.valueof (l_ratesch_node, 'NUMBER_DIM');

                BEGIN
                     l_rate_schedule_id := 0;
                     SELECT CRSA.rate_schedule_id
                       INTO l_rate_schedule_id
                       FROM cn_rate_schedules_all CRSA
                      WHERE CRSA.name   = l_rate_name
                        AND CRSA.ORG_ID = FND_PROFILE.VALUE('ORG_ID');
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     l_rate_schedule_id := 0;
                WHEN others THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE;
                END;

                IF l_rate_schedule_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Create Rate Dimensions
  ------------------------------------------------------------------------------
                 l_rate_tier_tbl_id := 0;
                 l_dim_exists       := 0;
                 l_rtdims_nodelist  := xslprocessor.selectnodes (xmldom.makenode(l_ratesch_doc), l_rtdims_tag);
                 FOR l_rtdims_num IN 0 .. xmldom.getlength (l_rtdims_nodelist) -1
                 LOOP
                    l_rtdims_node       := xmldom.item (l_rtdims_nodelist, l_rtdims_num);

                    l_result            := 'a';
                    xmldom.writetoclob(l_rtdims_node,l_result);
                    l_rtdims_doc        := cnc_retdomdoc_fnc(l_result);

                    l_dim_name          := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/NAME');
                    l_dim_description   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/DESCRIPTION');
                    l_dim_unit_code     := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/DIM_UNIT_CODE');
                    l_rate_dim_sequence := xslprocessor.valueof (l_rtdims_node, 'RATE_DIM_SEQUENCE');
                    l_rate_number_tier  := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/NUMBER_TIER');
  ------------------------------------------------------------------------------
  --  Identify the number of tiers for each dimension
  ------------------------------------------------------------------------------
                    l_number_dim_tbl_id                      := l_number_dim_tbl_id + 1;
                    l_number_dim_tbl(l_number_dim_tbl_id)    := l_rate_number_tier;

                    BEGIN
                       SELECT rate_dimension_id
                         INTO l_rate_dimension_id
                         FROM cn_rate_dimensions_all CRDA
                        WHERE CRDA.name = l_dim_name;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         l_rate_dimension_id := 0;
                    WHEN others THEN
                         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                         RAISE;
                    END;

                    IF l_rate_dimension_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Rate Dimension Does not exist. Get the Rate Tiers
  ------------------------------------------------------------------------------
                     l_rate_tier_tbl.DELETE;
                     l_rate_tier_tbl_id := 0;
                     l_rttiers_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtdims_doc), l_rttiers_tag);
                     FOR l_rttiers_num IN 0 .. xmldom.getlength (l_rttiers_nodelist) -1
                     LOOP
                        l_rttiers_node := xmldom.item (l_rttiers_nodelist, l_rttiers_num);
                        rec_rate_tier.tier_sequence         := xslprocessor.valueof (l_rttiers_node, 'TIER_SEQUENCE');
                        rec_rate_tier.value1                := xslprocessor.valueof (l_rttiers_node, 'MINIMUM_AMOUNT');
                        rec_rate_tier.value2                := xslprocessor.valueof (l_rttiers_node, 'MAXIMUM_AMOUNT');
                        rec_rate_tier.object_version_number := xslprocessor.valueof (l_rttiers_node, 'OBJECT_VERSION_NUMBER');
  ------------------------------------------------------------------------------
  --  Rate tier sequence will not be in order
  --  So create rate tiers based on sequence number
  ------------------------------------------------------------------------------
                        l_rate_tier_tbl_id                  := rec_rate_tier.tier_sequence;
                        l_rate_tier_tbl(l_rate_tier_tbl_id) := rec_rate_tier;
                     END LOOP;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'create_dimension API Call',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_dim_name : '||l_dim_name,
                             p_record_id      => NULL
                            );
                    END IF;

                     BEGIN
                         cn_multi_rate_schedules_pub.create_dimension
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_name                 => l_dim_name,
                                         p_description          => l_dim_description,
                                         p_dim_unit_code        => l_dim_unit_code,
                                         p_tiers_tbl            => l_rate_tier_tbl,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                         IF l_x_return_status <> 'S' THEN --Rate Dimension API Return status
                            IF (fnd_msg_pub.count_msg <> 0) THEN
                               FOR i IN 1 .. fnd_msg_pub.count_msg --Message Count
                               LOOP
                                   fnd_msg_pub.get
                                       ( p_msg_index     => i,
                                         p_encoded       => fnd_api.g_false,
                                         p_data          => l_x_msg_data,
                                         p_msg_index_out => l_msg_index_out
                                       );
                                  l_x_error_mesg := SUBSTR (l_x_error_mesg ||
                                                            ' ' ||
                                                            l_msg_index_out ||
                                                            l_x_msg_data,
                                                            1,
                                                            2000);
                               END LOOP;
                            END IF; -- Message Count
                            l_x_error_code := 'Error: Create rate dimension '
                                              || l_dim_name;
                            l_x_error_mesg := SUBSTR (l_x_error_mesg,1, 2000);
                            cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                              l_x_error_mesg
                                             );
                            RAISE g_create_ratedim_error;
                         ELSE
                             cnc_write_log_prc('Creation of Rate Dimension ' ||
                                                l_dim_name || ' succeeded.'
                                              );
                             g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                             rec_created_ele.l_name := l_dim_name;
                             rec_created_ele.l_type := L_RATEDIM_ELE;
                             g_tbl_created_ele(g_tbl_created_ele_id)
                                                         := rec_created_ele;
                         END IF; --Rate Dimension API Return status
                     EXCEPTION
                     WHEN OTHERS THEN
                         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                         RAISE g_create_ratedim_error;
                     END;
                    ELSE
                        l_dim_exists        := 1;
                        IF NOT cn_created_ele_fnc(l_dim_name,L_RATEDIM_ELE) THEN
                           cnc_write_log_prc('Warning: The Rate Dimension: ' ||
                                             l_dim_name || ' exists.'
                                            );
                        END IF;
                    END IF;
                    rec_dim_assign.rate_schedule_name       := l_rate_name;
                    rec_dim_assign.rate_dim_name            := l_dim_name;
                    rec_dim_assign.rate_dim_sequence        := l_rate_dim_sequence;
                    rec_dim_assign.object_version_number    := 0;
                    l_dim_assign_tbl_id                     := l_dim_assign_tbl_id + 1;
                    l_dim_assign_tbl(l_dim_assign_tbl_id)   := rec_dim_assign;
                END LOOP; --rtdims
                xmldom.freedocument(l_rtdims_doc);

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'create_schedule API call',
                         p_field          => 'cnc_import_rate_prc',
                         p_field_value    => 'l_rate_name : '||l_rate_name,
                         p_record_id      => NULL
                        );
                END IF;

  ------------------------------------------------------------------------------
  -- Create the Rate Schedule
  ------------------------------------------------------------------------------
                BEGIN
                      cn_multi_rate_schedules_pub.create_schedule
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_name                 => l_rate_name,
                                         p_commission_unit_code => l_commission_unit_code,
                                         p_dims_tbl             => l_dim_assign_tbl,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                IF l_x_return_status <> 'S' THEN
                   IF (fnd_msg_pub.count_msg <> 0) THEN
                      FOR i IN 1 .. fnd_msg_pub.count_msg
                      LOOP
                          fnd_msg_pub.get (p_msg_index          => i,
                                           p_encoded            => FND_API.G_FALSE,
                                           p_data               => l_x_msg_data,
                                           p_msg_index_out      => l_msg_index_out
                                           );
                          l_x_error_mesg := SUBSTR (l_x_error_mesg || ' '
                                                    || l_msg_index_out||
                                                    l_x_msg_data,
                                                    1,
                                                    2000
                                                   );
                      END LOOP;
                   END IF;                                      --Message Count
                   l_x_error_code := 'Error: Create Rate Table '
                                      || l_rate_name;
                   l_x_error_mesg := SUBSTR (l_x_error_mesg, 1, 2000);
                   cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                     l_x_error_mesg
                                    );
                   RAISE g_create_ratesch_error;
                ELSE
                   cnc_write_log_prc('Creation of Rate Schedule ' ||
                                     l_rate_name || 'succeeded.'
                                    );
                   COMMIT;
                   g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                   rec_created_ele.l_name := l_rate_name;
                   rec_created_ele.l_type := L_RATESCH_ELE;
                   g_tbl_created_ele(g_tbl_created_ele_id)
                                               := rec_created_ele;

                END IF;   --CREATE Rate API Status
                EXCEPTION
                WHEN OTHERS THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE g_create_ratesch_error;
                END; --Create Rate Schedules

  ------------------------------------------------------------------------------
  --  If rate dimension existed then no need for Commission recreation
  ------------------------------------------------------------------------------
               IF l_dim_exists = 0 THEN
  ------------------------------------------------------------------------------
  --  Capture all the commission amount parameters into a PLSQL table
  --  and also find the maximum value of a rate sequence for the rate table
  ------------------------------------------------------------------------------
                  l_rtcommsn_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_ratesch_doc), l_rtcommsn_tag);
                  l_max_rate_seq      := 0;
                  FOR l_rtcommsn_num IN 0 .. xmldom.getlength (l_rtcommsn_nodelist) -1
                  LOOP
                    l_rtcommsn_node                            := xmldom.item (l_rtcommsn_nodelist, l_rtcommsn_num);
                    rec_commission.l_rate_seq                  := xslprocessor.valueof(l_rtcommsn_node,'RATE_SEQUENCE');
                    rec_commission.l_commission_amount         := xslprocessor.valueof(l_rtcommsn_node,'COMMISSION_AMOUNT');
                    rec_commission.l_object_version_number     := xslprocessor.valueof(l_rtcommsn_node,'OBJECT_VERSION_NUMBER');
                    l_tbl_commission(rec_commission.l_rate_seq):= rec_commission;
                    IF rec_commission.l_rate_seq > l_max_rate_seq THEN
                       l_max_rate_seq  := rec_commission.l_rate_seq;
                    END IF;
                  END LOOP;
  ------------------------------------------------------------------------------
  --   If any rate sequence doesnot exist, then capture and handle
  --   such sequences so that the program doesnot error out with
  --   a no data found error.
  ------------------------------------------------------------------------------
                  FOR i IN 1 .. l_max_rate_seq
                  LOOP
                      IF NOT(l_tbl_commission.EXISTS(i)) THEN
                         rec_commission.l_rate_seq              := NULL;
                         rec_commission.l_commission_amount     := NULL;
                         rec_commission.l_object_version_number := NULL;
                         l_tbl_commission(i)                    := rec_commission;
                      END IF;
                  END LOOP;

  ------------------------------------------------------------------------------
  --   The implementaion of commission amount requires a matrix
  --   kind of structure. Since the dimension of the matrix is
  --   not known and PLSQL does not support dynamic matrix creation
  --   this program handles a maximum of 4 dimensions. The variable
  --   l_rate_number_dim holds the number_dim value of the rate schedule
  ------------------------------------------------------------------------------
                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Number of rate tiers',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_rate_number_dim : '||l_rate_number_dim,
                             p_record_id      => NULL
                            );
                    END IF;

                    CASE l_rate_number_dim
  ------------------------------------------------------------------------------
  --  Single dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 1 THEN
                         FOR i IN  1 .. l_rate_number_tier
                         LOOP
                          l_tier_coordinates_tbl(1) := i;

                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'update_rate api',
                                 p_field          => 'cnc_import_rate_prc',
                                 p_field_value    => 'l_tier_coordinates_tbl : '||i,
                                 p_record_id      => NULL
                                );
                        END IF;

                          BEGIN
                            IF (l_rate_number_tier <= l_max_rate_seq) THEN
                               cn_multi_rate_schedules_pub.update_rate
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_rate_schedule_name   => l_rate_name,
                                         p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                         p_commission_amount    => l_tbl_commission(i).l_commission_amount,
                                         p_object_version_number=> l_tbl_commission(i).l_object_version_number,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                               IF l_x_return_status <> 'S' THEN
                                  IF (fnd_msg_pub.count_msg <> 0) THEN
                                     FOR i IN 1 .. fnd_msg_pub.count_msg
                                     LOOP
                                         fnd_msg_pub.get
                                           (p_msg_index          => i,
                                            p_encoded            => FND_API.G_FALSE,
                                            p_data               => l_x_msg_data,
                                            p_msg_index_out      => l_msg_index_out
                                           );
                                         l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out || l_x_msg_data, 1, 2000);
                                     END LOOP;
                                  END IF;
                                  l_x_error_code := 'Error: Update Rate '
                                                    || l_rate_name;
                                  l_x_error_mesg := SUBSTR (l_x_error_mesg,1, 2000);
                                  cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                   );
                                  RAISE g_update_commsn_error;
                               ELSE
                                  cnc_write_log_prc
                                     ('Update of Commission Amount for ' ||
                                      'rate table ' || l_rate_name ||
                                      ' succeeded.'
                                     );
                               END IF;
                            END IF;
                          EXCEPTION
                          WHEN OTHERS THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE g_update_commsn_error;
                          END;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Two dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 2 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;

                                 IF (l_mtrx_count <= l_max_rate_seq) THEN

                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'update_rate api',
                                             p_field          => 'cnc_import_rate_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;

                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);

                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out|| l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                          RAISE g_update_commsn_error;
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Three dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 3 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                               FOR k In 1 .. l_number_dim_tbl(3)
                               LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;
                                 l_tier_coordinates_tbl(3) := k;
                                 IF (l_mtrx_count <= l_max_rate_seq) THEN
                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'update_rate api',
                                             p_field          => 'cnc_import_rate_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;
                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);
                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out||l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                               END LOOP;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Four dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 4 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                               FOR k In 1 .. l_number_dim_tbl(3)
                               LOOP
                                FOR l In 1 .. l_number_dim_tbl(4)
                                LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;
                                 l_tier_coordinates_tbl(3) := k;
                                 l_tier_coordinates_tbl(4) := l;

                                 IF (l_mtrx_count <= l_max_rate_seq) THEN
                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'update_rate api',
                                             p_field          => 'cnc_import_rate_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;
                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);
                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out||l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                                END LOOP;
                               END LOOP;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  END of matrix implementation for Commission rates
  ------------------------------------------------------------------------------
                    ELSE
                          cnc_write_log_prc('The rate dimension value is ' ||
                                            'greater than 4. Value is: ' ||
                                             l_rate_number_dim
                                           );
                    END CASE;
  ------------------------------------------------------------------------------
  --  If rate dimension existed then no need for Commission recreation
  ------------------------------------------------------------------------------
                ELSE
                    cnc_write_log_prc('Error: The rate table ' || l_rate_name ||
                                      'has been associated to existing rate ' ||
                                      'dimensions. Please update the commission'
                                      || ' rates to this rate table manually');
                END IF;
            ELSE
                IF NOT cn_created_ele_fnc(l_rate_name,
                                          L_RATESCH_ELE) THEN
                           cnc_write_log_prc('Warning: The Rate Table: ' ||
                                             l_rate_name || ' exists.'
                                            );
                END IF;
            END IF;
  ------------------------------------------------------------------------------
  -- Get the rate table id for creating the formula
  ------------------------------------------------------------------------------
                BEGIN
                     l_rate_schedule_id := 0;
                     SELECT CRSA.rate_schedule_id
                       INTO l_rate_schedule_id
                       FROM cn_rate_schedules_all CRSA
                      WHERE CRSA.name = l_rate_name;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
 

                     cnc_write_log_prc('Rate Table: ' || l_rate_name || ' not found');
                     RAISE g_create_formula_error;
                WHEN others THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE;
                END;

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Process formulas for rate tables',
                         p_field          => 'cnc_import_rate_prc',
                         p_field_value    => NULL,
                         p_record_id      => NULL
                        );
                END IF;

  ------------------------------------------------------------------------------
  --  Create the formulas which are associated to the rate table
  ------------------------------------------------------------------------------
                l_rtasgns_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_ratesch_doc), l_rtasgns_tag);
                IF (xmldom.getlength (l_rtasgns_nodelist) <> 0) THEN
                FOR l_rtasgns_num IN 0 .. xmldom.getlength (l_rtasgns_nodelist) -1
                LOOP
                    l_rtasgns_node := xmldom.item (l_rtasgns_nodelist, l_rtasgns_num);
                    l_result       := 'a';
                    xmldom.writetoclob(l_rtasgns_node,l_result);
                    l_rtasgns_doc  := cnc_retdomdoc_fnc(l_result);

                    rec_formula_rt_assign.rate_schedule_id      := l_rate_schedule_id;
                    rec_formula_rt_assign.start_date            := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'START_DATE'),'DD-MON-YYYY');
                    rec_formula_rt_assign.end_date              := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'END_DATE'),'DD-MON-YYYY');
                    rec_formula_rt_assign.rate_schedule_name    := l_rate_name;
                    rec_formula_rt_assign.rate_schedule_type    := l_commission_unit_code;

                    l_formula_rt_assign_id                          := l_formula_rt_assign_id + 1;
 
                    l_formula_rt_assign_tbl(l_formula_rt_assign_id) := rec_formula_rt_assign;

  ------------------------------------------------------------------------------
  --  Get the data value for the formula columns
  ------------------------------------------------------------------------------
                    l_formula_name              := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/NAME');
                    l_formula_description       := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/DESCRIPTION');
                    l_formula_type              := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/FORMULA_TYPE');
                    l_formula_status            := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/FORMULA_STATUS');
                    l_formula_trx_group_code    := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/TRX_GROUP_CODE');
                    l_formula_number_dim        := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/NUMBER_DIM');
                    l_formula_cumulative_flag   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/CUMULATIVE_FLAG');
                    l_formula_itd_flag          := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/ITD_FLAG');
                    l_formula_split_flag        := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/SPLIT_FLAG');
                    l_threshold_all_tier_flag   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/THRESHOLD_ALL_TIER_FLAG');
                    l_formula_modeling_flag     := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/MODELING_FLAG');
                    l_object_version_number     := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_RT_OBJ/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_RT_OBJ/OBJECT_VERSION_NUMBER');

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Create Output expression',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_formula_name : '||l_formula_name,
                             p_record_id      => NULL
                            );
                    END IF;

  ------------------------------------------------------------------------------
  --  Create Output expression
  ------------------------------------------------------------------------------
                    l_outexpr_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtasgns_doc), l_outexp_tag);
                    FOR l_outexp_num IN 0 .. xmldom.getlength (l_outexpr_nodelist) -1
                    LOOP
                       l_outexp_node := xmldom.item (l_outexpr_nodelist, l_outexp_num);
                       l_expr_name    := NULL;
                       l_expr_name    := xslprocessor.valueof (l_outexp_node, 'NAME');

  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                       IF l_expr_name IS NOT NULL THEN
                          l_result     := 'a';
                          xmldom.writetoclob(l_outexp_node,l_result);
                          BEGIN
                               SELECT CCSEA.calc_sql_exp_id
                                 INTO l_calc_sql_exp_id
                                 FROM cn_calc_sql_exps_all CCSEA
                                WHERE CCSEA.name = l_expr_name;
                          EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                               l_calc_sql_exp_id := 0;
                          WHEN OTHERS THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE;
                          END;

                          IF l_calc_sql_exp_id = 0 THEN
                             cnc_create_expression_prc(l_result,L_EXP_OUTPUT,l_formula_output_exp_id);
                          ELSE
                             l_formula_output_exp_id := l_calc_sql_exp_id;
                             IF NOT cn_created_ele_fnc(l_expr_name,L_EXPR_ELE) THEN
                                cnc_write_log_prc('Warning: The Expression: ' ||
                                                  l_expr_name || ' exists.'
                                                 );
                             END IF;
                          END IF;
                       END IF;
                    END LOOP;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Create Input expression',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_formula_name : '||l_formula_name,
                             p_record_id      => NULL
                            );
                    END IF;
  ------------------------------------------------------------------------------
  --  Create Input expression
  ------------------------------------------------------------------------------
                   l_inexpr_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtasgns_doc), l_inexp_tag);
                   FOR l_inexp_num IN 0 .. xmldom.getlength (l_inexpr_nodelist) -1
                   LOOP
                    l_inexp_node := xmldom.item (l_inexpr_nodelist, l_inexp_num);
                    l_result      := 'a';
                    xmldom.writetoclob(l_inexp_node,l_result);
                    l_inexp_doc := cnc_retdomdoc_fnc(l_result);

                    l_expr_name := NULL;
                    l_expr_name := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_INPUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/NAME');
  ------------------------------------------------------------------------------
  -- Validate if the expression exists already
  ------------------------------------------------------------------------------
                    IF l_expr_name IS NOT NULL THEN
                      BEGIN
                        SELECT CCSEA.calc_sql_exp_id
                          INTO l_calc_sql_exp_id
                          FROM cn_calc_sql_exps_all CCSEA
                         WHERE CCSEA.name = l_expr_name;
                      EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                         l_calc_sql_exp_id := 0;
                      WHEN OTHERS THEN
                         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                         RAISE;
                      END;

                      IF l_calc_sql_exp_id = 0 THEN
                         CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_INPUT,l_calc_sql_exp_id);
                          rec_formula_input.calc_sql_exp_id := l_calc_sql_exp_id;
                      ELSE
                         rec_formula_input.calc_sql_exp_id := l_calc_sql_exp_id;
                         IF NOT cn_created_ele_fnc(l_expr_name,L_EXPR_ELE) THEN
                            cnc_write_log_prc('Warning: The Expression: ' ||
                                              l_expr_name || ' exists.'
                                             );
                         END IF;
                      END IF;
                    END IF;

                    rec_formula_input.cumulative_flag   := xslprocessor.valueof (l_inexp_node, 'CUMULATIVE_FLAG');
                    rec_formula_input.split_flag        := xslprocessor.valueof (l_inexp_node, 'SPLIT_FLAG');
                    rec_formula_input.rate_dim_sequence := xslprocessor.valueof (l_inexp_node, 'RATE_DIM_SEQUENCE');
                    rec_formula_input.calc_exp_name     := l_expr_name;
                    rec_formula_input.calc_exp_status   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_INPUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/STATUS');

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Create forecast expression',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_formula_name : '||l_formula_name,
                             p_record_id      => NULL
                            );
                    END IF;
  ------------------------------------------------------------------------------
  --  Create Forecast Input expression
  ------------------------------------------------------------------------------
                    l_expr_name := NULL;
                    l_expr_name := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_FORECAST_INPUT_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/NAME');
  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                    IF l_expr_name IS NOT NULL THEN
                       BEGIN
                          SELECT CCSEA.calc_sql_exp_id
                            INTO l_calc_sql_exp_id
                            FROM cn_calc_sql_exps_all CCSEA
                           WHERE CCSEA.name = l_expr_name;
                       EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                           l_calc_sql_exp_id := 0;
                       WHEN OTHERS THEN
                           cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                           RAISE;
                       END;

                       IF l_calc_sql_exp_id = 0 THEN
                          cnc_create_expression_prc(l_result,L_EXP_FINPUT,l_calc_sql_exp_id);
                          rec_formula_input.f_calc_sql_exp_id := l_calc_sql_exp_id;
                       ELSE
                          rec_formula_input.f_calc_sql_exp_id := l_calc_sql_exp_id;
                          IF NOT cn_created_ele_fnc(l_expr_name,L_EXPR_ELE) THEN
                             cnc_write_log_prc('Warning: The Expression: ' ||
                                               l_expr_name || ' exists.'
                                              );
                          END IF;
                       END IF;
                       rec_formula_input.f_calc_exp_name   := l_expr_name;
                       rec_formula_input.f_calc_exp_status := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_FORECAST_INPUT_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/STATUS');
                    END IF;
  ------------------------------------------------------------------------------
  --              END Forecast input;
  ------------------------------------------------------------------------------

                    l_formula_input_tbl_id                      := l_formula_input_tbl_id + 1;
                    l_formula_input_tbl(l_formula_input_tbl_id) := rec_formula_input;
                   END LOOP;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Create Performance expression',
                             p_field          => 'cnc_import_rate_prc',
                             p_field_value    => 'l_formula_name : '||l_formula_name,
                             p_record_id      => NULL
                            );
                    END IF;
  ------------------------------------------------------------------------------
  --  Create Performance Measure
  ------------------------------------------------------------------------------
                   l_perfmeas_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtasgns_doc), l_perfmeas_tag);
                   FOR l_perfmeas_num IN 0 .. xmldom.getlength (l_perfmeas_nodelist) -1
                   LOOP
                       l_perfmeas_node := xmldom.item (l_perfmeas_nodelist, l_perfmeas_num);
                       l_expr_name := NULL;
                       l_expr_name := xslprocessor.valueof (l_perfmeas_node, 'NAME');

  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                       IF l_expr_name IS NOT NULL THEN
                          l_result     := 'a';
                          xmldom.writetoclob(l_perfmeas_node,l_result);
                          BEGIN
                             SELECT CCSEA.calc_sql_exp_id
                               INTO l_calc_sql_exp_id
                               FROM cn_calc_sql_exps_all CCSEA
                              WHERE CCSEA.name = l_expr_name;
                          EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                               l_calc_sql_exp_id := 0;
                          WHEN OTHERS THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE;
                          END;

                          IF l_calc_sql_exp_id = 0 THEN
                             CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_PERFMEAS,l_formula_perf_measure_id);
                          ELSE
                             l_formula_perf_measure_id := l_calc_sql_exp_id;
                             IF NOT cn_created_ele_fnc(l_expr_name,L_EXPR_ELE) THEN
                              cnc_write_log_prc('Warning: The Expression: ' ||
                                                l_expr_name || ' exists.'
                                               );
                             END IF;
                          END IF;
                       END IF;
                   END LOOP;
                   xmldom.freedocument(l_inexp_doc);
  ------------------------------------------------------------------------------
  -- Check if the formula exists. IF yes then create formula, else update
  ------------------------------------------------------------------------------
                   BEGIN
                        l_calc_formula_id := 0;
                        SELECT  CCFA.calc_formula_id
                          INTO  l_calc_formula_id
                          FROM  cn_calc_formulas_all CCFA
                         WHERE  CCFA.NAME   = l_formula_name
                           AND  CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                        l_calc_formula_id := 0;
                   WHEN OTHERS THEN
                        cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                        RAISE;
                   END;

                   IF l_calc_formula_id = 0 THEN
                   BEGIN

                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Call create_formula API',
                                 p_field          => 'cnc_import_rate_prc',
                                 p_field_value    => 'l_formula_name : '||l_formula_name,
                                 p_record_id      => NULL
                                );
                        END IF;


                      cn_calc_formulas_pvt.create_formula
                                        (p_api_version             => 1,
                                         p_commit                  => FND_API.G_FALSE,
                                         p_name                    => l_formula_name,
                                         p_description             => l_formula_description,
                                         p_formula_type            => l_formula_type,
                                         p_trx_group_code          => l_formula_trx_group_code,
                                         p_number_dim              => l_formula_number_dim,
                                         p_cumulative_flag         => l_formula_cumulative_flag,
                                         p_itd_flag                => l_formula_itd_flag,
                                         p_split_flag              => l_formula_split_flag,
                                         p_threshold_all_tier_flag => l_threshold_all_tier_flag,
                                         p_modeling_flag           => l_formula_modeling_flag,
                                         p_perf_measure_id         => l_formula_perf_measure_id,
                                         p_output_exp_id           => l_formula_output_exp_id,
                                         p_f_output_exp_id         => NULL,
                                         p_input_tbl               => l_formula_input_tbl,
                                         p_rt_assign_tbl           => l_formula_rt_assign_tbl,
                                         x_calc_formula_id         => l_formula_x_calc_formula_id,
                                         x_formula_status          => l_formula_x_formula_status,
                                         x_return_status           => l_x_return_status,
                                         x_msg_count               => l_x_msg_count,
                                         x_msg_data                => l_x_msg_data);

                      IF l_x_return_status <> 'S' THEN
                       IF (fnd_msg_pub.count_msg <> 0) THEN
                         FOR i IN 1 .. fnd_msg_pub.count_msg
                         LOOP
                           fnd_msg_pub.get
                                   (p_msg_index          => i,
                                    p_encoded            => fnd_api.g_false,
                                    p_data               => l_x_msg_data,
                                    p_msg_index_out      => l_msg_index_out
                                   );
                           l_x_error_mesg := SUBSTR (l_x_error_mesg || ' '
                                                     || l_msg_index_out
                                                     || l_x_msg_data,
                                                     1,
                                                     2000);
                         END LOOP;
                       END IF;

                       l_x_error_code := 'Error: Create Formula '|| l_formula_name;
                       l_x_error_mesg := SUBSTR (l_x_error_mesg,1,2000);
                       cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                         l_x_error_mesg
                                        );


                       RAISE g_create_formula_error;
                      ELSE
                       cnc_write_log_prc('Creation of Formula '
                                          || l_formula_name ||
                                         ' succeeded with status: ' ||
                                         l_formula_x_formula_status
                                        );
                      END IF;
                   EXCEPTION
                   WHEN OTHERS THEN
 

                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                   END;
  ------------------------------------------------------------------------------
  -- If the formula exists then update the formula
  ------------------------------------------------------------------------------
                   ELSE
                   l_formula_x_calc_formula_id := l_calc_formula_id;
                   BEGIN
                      l_rt_formula_exists := 0;
                      FOR rec_formula_rates IN c_formula_rates(l_calc_formula_id)
                      LOOP
                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Formula exists and has associated rate tables',
                                 p_field          => 'cnc_create_formula_prc',
                                 p_field_value    => 'l_calc_formula_id : '||l_calc_formula_id,
                                 p_record_id      => NULL
                                );
                        END IF;

                        cnc_write_log_prc('Warning: The formula ' || l_formula_name
                                          || ' exists and has rate tables associated to it.'
                                          || ' Program will not override the associations');

                        l_rt_formula_exists := 1;
                        EXIT;
                      END LOOP;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                        NULL;
                   WHEN OTHERS THEN
 

                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                   END;

                   IF l_rt_formula_exists = 0 THEN
                   BEGIN

                      FOR i in l_formula_rt_assign_tbl.FIRST ..l_formula_rt_assign_tbl.LAST
                      LOOP
                          BEGIN
 
                          l_rt_formula_asgn_id := NULL;
                                -- Write additional debug messages
                                IF g_debug_flag = 'Y' THEN
                                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                        (p_error_message  => 'insert_row API to update rt form asso',
                                         p_field          => 'cnc_import_rate_prc',
                                         p_field_value    => 'l_calc_formula_id : '||l_calc_formula_id,
                                         p_record_id      => NULL
                                        );
                                END IF;

                          cnc_write_log_prc('Associating rate table ' ||
                                            l_formula_rt_assign_tbl(i).rate_schedule_name
                                            ||  ' to formula: ' || l_formula_name
                                           );

                          cn_rt_formula_asgns_pkg.insert_row
                                  (
                                   X_RT_FORMULA_ASGN_ID    => l_rt_formula_asgn_id,
                                   X_CALC_FORMULA_ID       => l_calc_formula_id,
                                   X_RATE_SCHEDULE_ID      => l_formula_rt_assign_tbl(i).rate_schedule_id,
                                   X_START_DATE            => l_formula_rt_assign_tbl(i).start_date,
                                   X_END_DATE              => l_formula_rt_assign_tbl(i).end_date,
                                   X_CREATION_DATE         => l_creation_date,
                                   X_CREATED_BY            => l_created_by,
                                   X_LAST_UPDATE_DATE      => l_update_date,
                                   X_LAST_UPDATED_BY       => l_updated_by,
                                   X_LAST_UPDATE_LOGIN     => l_last_update_login
                                  );
                          EXCEPTION
                          WHEN others THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE;
                          END;
                      END LOOP;

                      cnc_write_log_prc
                                       ('Assignment of rate table '
                                       || ' to formula' ||
                                        l_formula_name ||
                                        ' completed successfully.'
                                       );
                   EXCEPTION
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                   END;
                   -- Formula did not have rate assignments, so associated rates
                   END IF;
                   -- Check for the formula existence
                   END IF;

                    BEGIN
                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Call to generate_formula API',
                                 p_field          => 'cnc_import_rate_prc',
                                 p_field_value    => 'l_formula_x_calc_formula_id : '||l_formula_x_calc_formula_id,
                                 p_record_id      => NULL
                                );
                        END IF;

                          CN_CALC_FORMULAS_PVT.generate_formula
                            (p_api_version       => 1,
                             p_commit            => FND_API.G_FALSE,
                             p_calc_formula_id   => l_formula_x_calc_formula_id,
                             p_formula_type      => l_formula_type,
                             p_trx_group_code    => l_formula_trx_group_code,
                             p_number_dim        => l_formula_number_dim,
                             p_itd_flag          => l_formula_itd_flag,
                             p_perf_measure_id   => l_formula_perf_measure_id,
                             p_output_exp_id     => l_formula_output_exp_id,
                             p_f_output_exp_id   => NULL,
                             x_formula_status    => l_x_formula_status,
                             x_return_status     => l_x_return_status,
                             x_msg_count         => l_x_msg_count,
                             x_msg_data          => l_x_msg_data
                            );

                          IF l_x_return_status <> 'S' THEN
                             IF (fnd_msg_pub.count_msg <> 0) THEN
                                FOR i IN 1 .. fnd_msg_pub.count_msg
                                LOOP
                                    fnd_msg_pub.get
                                       (p_msg_index          => i,
                                        p_encoded            => fnd_api.g_false,
                                        p_data               => l_x_msg_data,
                                        p_msg_index_out      => l_msg_index_out
                                       );
                                    l_x_error_mesg := SUBSTR (l_x_error_mesg ||
                                                               ' ' ||
                                                              l_msg_index_out ||
                                                              l_x_msg_data,
                                                              1,
                                                              2000
                                                             );
                                END LOOP;
                             END IF;
                             l_x_error_code := 'Error: Generating Formula ' ||
                                                l_formula_name;
                             l_x_error_mesg := SUBSTR (l_x_error_mesg, 1, 2000);
                             cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                               l_x_error_mesg
                                              );
                             RAISE g_gen_formula_error;
                          ELSE
                              cnc_write_log_prc
                                       ('Generation of Formula ' ||
                                        l_formula_name ||
                                        ' succeeded with status: ' ||
                                          l_x_formula_status
                                       );
                              g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                              rec_created_ele.l_name := l_formula_name;
                              rec_created_ele.l_type := L_FORMULA_ELE;
                              g_tbl_created_ele(g_tbl_created_ele_id)
                                                          := rec_created_ele;
                          END IF;
                    EXCEPTION
                    WHEN OTHERS THEN
                          cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                           RAISE g_gen_formula_error;
                    END;
  ------------------------------------------------------------------------------
  --  End of Formula loop
  ------------------------------------------------------------------------------
                END LOOP;
                xmldom.freedocument(l_rtasgns_doc);
                END IF;
  ------------------------------------------------------------------------------
  --  End of Rate Schedule loop
  ------------------------------------------------------------------------------
            END LOOP;
            xmldom.freedocument(l_ratesch_doc);
            COMMIT;
            cnc_write_log_prc('The rate table: ' ||l_ratesch_name ||
                              'created succesfully.'
                             );

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'End of Program',
                     p_field          => 'cnc_import_rate_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  End of Rate Copy loop
  ------------------------------------------------------------------------------
          ELSE
             cnc_write_log_prc('The rate table: ' ||l_ratesch_name
                 ||' exists. The program will not recreate'
                 || ' this rate table. In order to recreate '
                 || 'this rate table, please delete the '
                 || 'existing rate table.'
                );
          END IF;
          xmldom.freedocument(l_hierarchy_doc);
       END LOOP;
       xmldom.freedocument(l_ratecopy_doc);
    EXCEPTION
    WHEN OTHERS THEN
         cnc_write_log_prc('Error occured while processing: '
                           || SUBSTR(SQLERRM,1,2000)
                          );
         RAISE;
    END cnc_import_rate_prc;

  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_EXPRESSION_PRC
  --Creates an expression using the data provided in p_expr_xml
  --p_exp_type is used to find the type of expression, whether input, output or
  --forecast
  ------------------------------------------------------------------------------
    PROCEDURE CNC_CREATE_EXPRESSION_PRC(p_expr_xml IN CLOB,
                                        p_exp_type IN VARCHAR2,
                                        p_x_exp_id OUT NOCOPY NUMBER) IS
         l_expr_doc              xmldom.DOMDocument;
         l_expr_nodelist         xmldom.DOMNodeList;
         l_expr_node             xmldom.domNode;
         l_expr_tag              VARCHAR2(100)                     := NULL;

         l_name                  CN_CALC_SQL_EXPS.NAME%TYPE        := NULL;
         l_description           CN_CALC_SQL_EXPS.DESCRIPTION%TYPE := NULL;
         l_expression_disp       VARCHAR2(32767)                   := NULL;
         l_sql_select            VARCHAR2(32767)                   := NULL;
         l_sql_from              VARCHAR2(32767)                   := NULL;
         l_piped_expression_disp VARCHAR2(32767)                   := NULL;
         l_piped_sql_select      VARCHAR2(32767)                   := NULL;
         l_piped_sql_from        VARCHAR2(32767)                   := NULL;

         l_x_exp_type_code       CN_CALC_SQL_EXPS.EXP_TYPE_CODE%TYPE := NULL;
         l_x_status              CN_CALC_SQL_EXPS.STATUS%TYPE        := NULL;
         l_x_return_status       VARCHAR2(10)                        := 'F';
         l_x_msg_count           NUMBER                              := 0;
         l_x_msg_data            VARCHAR2(32767)                     := NULL;
         l_msg_index_out         VARCHAR2(2000)                      := NULL;
         l_x_error_mesg          VARCHAR2(2000)                      := NULL;
         l_x_error_code          VARCHAR2(200)                       := NULL;

         tbl_formula             g_tbl_type_formula;
         tbl_planele             g_tbl_type_planele;
         l_calc_formula_id       CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE;
         l_quota_id              CN_QUOTAS.QUOTA_ID%TYPE;

    BEGIN
  ------------------------------------------------------------------------------
  --  Get the XML document for the expression
  ------------------------------------------------------------------------------
        l_expr_doc := cnc_retdomdoc_fnc(p_expr_xml);

        CASE p_exp_type
            WHEN L_EXP_FINPUT THEN
                 l_expr_tag := '/XX_OIC_FORMULA_INPUTS_OBJ/CN_FORECAST_INPUT_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';
            WHEN L_EXP_OUTPUT THEN
                 l_expr_tag := '/XX_OIC_CALC_EXPRESSIONS_OBJ';
            WHEN L_EXP_DEPEND THEN
                 l_expr_tag := '/CN_CALC_SQL_EXPR_ALL';
            WHEN L_EXP_INPUT THEN
                 l_expr_tag := '/XX_OIC_FORMULA_INPUTS_OBJ/CN_INPUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';
            WHEN L_EXP_PERFMEAS THEN
                 l_expr_tag := '/XX_OIC_CALC_EXPRESSIONS_OBJ';
            ELSE
                 cnc_write_log_prc('The expression case is invalid : ' ||
                                    p_exp_type
                                  );
        END CASE;

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'In Create expression',
                 p_field          => 'cnc_create_expression_prc',
                 p_field_value    => 'p_exp_type : '||p_exp_type,
                 p_record_id      => NULL
                );
        END IF;
  ------------------------------------------------------------------------------
  --  Process the expression data
  ------------------------------------------------------------------------------
        l_expr_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_expr_doc), l_expr_tag);
        FOR l_expr_num IN 0 .. xmldom.getlength (l_expr_nodelist) -1
        LOOP
            l_expr_node := xmldom.item (l_expr_nodelist, l_expr_num);

            l_name                   := xslprocessor.valueof (l_expr_node,
                                                              'NAME'
                                                              );
            l_description            := xslprocessor.valueof (l_expr_node, 'DESCRIPTION');
            l_expression_disp        := xslprocessor.valueof (l_expr_node, 'EXPRESSION_DISP');
            l_sql_select             := xslprocessor.valueof (l_expr_node, 'SQL_SELECT');
            l_sql_from               := xslprocessor.valueof (l_expr_node, 'SQL_FROM');
            l_piped_expression_disp  := xslprocessor.valueof (l_expr_node, 'PIPED_EXPRESSION_DISP');
            l_piped_sql_select       := xslprocessor.valueof (l_expr_node, 'PIPED_SQL_SELECT');
            l_piped_sql_from         := xslprocessor.valueof (l_expr_node, 'PIPED_SQL_FROM');

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Processing expression',
                     p_field          => 'cnc_create_expression_prc',
                     p_field_value    => 'l_name : '||l_name,
                     p_record_id      => NULL
                    );
            END IF;

  ------------------------------------------------------------------------------
  --  Parse the expression to find out embedded Plan Elements and Formulas
  ------------------------------------------------------------------------------
            tbl_formula.DELETE;
            tbl_planele.DELETE;
            cnc_parse_sql_prc(l_sql_select, tbl_formula, tbl_planele);
  ------------------------------------------------------------------------------
  --  Parse the expression to replace formula references
  --  so as to match the target instance id values
  ------------------------------------------------------------------------------
            IF tbl_formula.EXISTS(1) THEN
            FOR i IN tbl_formula.FIRST .. tbl_formula.LAST
            LOOP
                FOR j IN g_tbl_ref_name.FIRST .. g_tbl_ref_name.LAST
                LOOP
                    IF (UPPER(tbl_formula(i)) = g_tbl_ref_name(j).l_stname)
                       AND (g_tbl_ref_name(j).l_type = 'FORMULA') THEN
                       l_calc_formula_id := NULL;
                       BEGIN
                            SELECT CCFA.calc_formula_id
                              INTO l_calc_formula_id
                              FROM cn_calc_formulas_all CCFA
                             WHERE CCFA.name   = g_tbl_ref_name(j).l_name
                               AND CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
                       EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                            RAISE g_formula_not_found_error;
                       WHEN OTHERS THEN
                            cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                            RAISE;
                       END;
  ------------------------------------------------------------------------------
  --  Replace the formula package name of source to match that on the target
  --  instance. Replace in both, sql_select as well as piped_sql_select columns
  ------------------------------------------------------------------------------

                       l_sql_select       := REPLACE(l_sql_select,tbl_formula(i),'cn_formula_'||l_calc_formula_id||'_'||fnd_profile.value('ORG_ID')||'_pkg.get_result(p_commission_line_id)');
                       l_piped_sql_select := REPLACE(l_piped_sql_select,tbl_formula(i),'cn_formula_'||l_calc_formula_id||'_'||fnd_profile.value('ORG_ID')||'_pkg.get_result(p_commission_line_id)');
                       EXIT;
                    END IF;
                END LOOP;
            END LOOP;
            END IF;

  ------------------------------------------------------------------------------
  --  Parse the expression to replace plan element references
  --  so as to match the target instance id values
  ------------------------------------------------------------------------------
            IF tbl_planele.EXISTS(1) THEN
            FOR i IN tbl_planele.FIRST .. tbl_planele.LAST
            LOOP
                FOR j IN g_tbl_ref_name.FIRST .. g_tbl_ref_name.LAST
                LOOP
                    IF (UPPER(tbl_planele(i)) = g_tbl_ref_name(j).l_stname)
                       AND (g_tbl_ref_name(j).l_type = 'PLANELEMENT') THEN
                       l_quota_id := NULL;
                       BEGIN
                            SELECT CQA.quota_id
                              INTO l_quota_id
                              FROM cn_quotas_all CQA
                             WHERE CQA.name        = g_tbl_ref_name(j).l_name
                               AND CQA.delete_flag = 'N'
                               AND CQA.org_id      = FND_PROFILE.VALUE('ORG_ID');
                       EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                            RAISE g_planele_not_found_error;
                       WHEN OTHERS THEN
                            cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                            RAISE;
                       END;
  ------------------------------------------------------------------------------
  --  Replace the Plan element reference of source to match that on the target
  --  instance. Replace in both, sql_select as well as piped_sql_select columns
  ------------------------------------------------------------------------------
                       l_sql_select       := REPLACE(l_sql_select,tbl_planele(i),l_quota_id||'PE');
                       l_piped_sql_select := REPLACE(l_piped_sql_select,tbl_planele(i),l_quota_id||'PE');
                       EXIT;
                    END IF;
                END LOOP;
            END LOOP;
            END IF;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Call create_expression API',
                     p_field          => 'cnc_create_expression_prc',
                     p_field_value    => 'l_name : '||l_name,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  API Call to create the expression
  ------------------------------------------------------------------------------
            BEGIN
                 cn_calc_sql_exps_pvt.create_expression
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_name                 => l_name,
                                         p_description          => l_description,
                                         p_expression_disp      => l_expression_disp,
                                         p_sql_select           => l_sql_select,
                                         p_sql_from             => l_sql_from,
                                         p_piped_expression_disp=> l_piped_expression_disp,
                                         p_piped_sql_select     => l_piped_sql_select,
                                         p_piped_sql_from       => l_piped_sql_from,
                                         x_calc_sql_exp_id      => p_x_exp_id,
                                         x_exp_type_code        => l_x_exp_type_code,
                                         x_status               => l_x_status,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);
                 IF l_x_return_status <> 'S' THEN
                    IF (fnd_msg_pub.count_msg <> 0) THEN
                       FOR i IN 1 .. fnd_msg_pub.count_msg
                       LOOP
                           fnd_msg_pub.get (p_msg_index      => i,
                                            p_encoded        => FND_API.G_FALSE,
                                            p_data           => l_x_msg_data,
                                            p_msg_index_out  => l_msg_index_out
                                            );
                           l_x_error_mesg :=
                           SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out ||
                                   l_x_msg_data, 1, 2000
                                  );
                      END LOOP;
                    END IF;
                    l_x_error_code := 'Error: Create expression ' || l_name;
                    l_x_error_mesg := SUBSTR (l_x_error_mesg,1,2000);
                    cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                      l_x_error_mesg
                                     );
                    RAISE g_create_exp_error;
                 ELSE
                    IF l_x_status <> 'VALID' THEN
                        RAISE g_exp_not_valid_error;
                    ELSE
                        cnc_write_log_prc('Creation of expression ' ||
                                          l_name ||
                                          ' succeeded with status: ' ||
                                          l_x_status
                                         );
                        g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                        rec_created_ele.l_name := l_name;
                        rec_created_ele.l_type := L_EXPR_ELE;
                        g_tbl_created_ele(g_tbl_created_ele_id)
                                                    := rec_created_ele;
                    END IF;
                 END IF;
            EXCEPTION
            WHEN OTHERS THEN
                 cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                 RAISE g_exp_not_valid_error;
            END;

        END LOOP;
        xmldom.freedocument(l_expr_doc);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'End of create expression',
                 p_field          => 'cnc_create_expression_prc',
                 p_field_value    => 'l_name : '||l_name,
                 p_record_id      => p_x_exp_id
                );
        END IF;

    EXCEPTION
    WHEN OTHERS THEN
         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
         RAISE;
    END CNC_CREATE_EXPRESSION_PRC;

  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_FORMULA_PRC
  --Procedure to create a formula using the data in p_formula_xml
  ------------------------------------------------------------------------------
    PROCEDURE CNC_CREATE_FORMULA_PRC(p_formula_xml IN CLOB, p_tag_type IN VARCHAR2) IS

      CURSOR c_formula_rates(p_calc_formula_id NUMBER) IS
         SELECT CRFAA.rt_formula_asgn_id,
                CRFAA.rate_schedule_id,
                CRFAA.start_date,
                CRFAA.end_date,
                CRSA.name,
                CRSA.commission_unit_code,
                CRFAA.object_version_number,
                CCFA.number_dim
           FROM cn_rt_formula_asgns_all CRFAA,
                cn_calc_formulas_all    CCFA,
                cn_rate_schedules_all   CRSA
          WHERE CRFAA.calc_formula_id  = CCFA.calc_formula_id
            AND CRFAA.org_id           = CCFA.org_id
            AND CRSA.rate_schedule_id  = CRFAA.rate_schedule_id
            AND CRSA.org_id            = CRFAA.org_id
            AND CCFA.calc_formula_id   = p_calc_formula_id
            AND CCFA.org_id            = FND_PROFILE.VALUE('ORG_ID');

      l_formula_doc          xmldom.DOMDocument;
      l_rtasgns_doc          xmldom.DOMDocument;
      l_inexp_doc            xmldom.DOMDocument;
      l_rtdims_doc           xmldom.DOMDocument;
      l_formula_nodelist     xmldom.DOMNodeList;
      l_outexpr_nodelist     xmldom.DOMNodeList;
      l_inexpr_nodelist      xmldom.DOMNodeList;
      l_finexpr_nodelist     xmldom.DOMNodeList;
      l_perfmeas_nodelist    xmldom.DOMNodeList;
      l_rtasgns_nodelist     xmldom.DOMNodeList;
      l_rtdims_nodelist      xmldom.DOMNodeList;
      l_rttiers_nodelist     xmldom.DOMNodeList;
      l_rtcommsn_nodelist    xmldom.DOMNodeList;
      l_formula_node         xmldom.domNode;
      l_outexp_node          xmldom.domNode;
      l_inexp_node           xmldom.domNode;
      l_perfmeas_node        xmldom.domNode;
      l_rtasgns_node         xmldom.domNode;
      l_rtdims_node          xmldom.domNode;
      l_rttiers_node         xmldom.domNode;
      l_rtcommsn_node        xmldom.domNode;
      l_result               CLOB;
      l_exp_name             CN_CALC_SQL_EXPS.NAME%TYPE;
      l_calc_sql_exp_id      CN_CALC_SQL_EXPS.CALC_SQL_EXP_ID%TYPE;
      l_calc_formula_id      CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE;
      l_formula_tag          VARCHAR2(30)  := NULL;
      l_outexp_tag           VARCHAR2(300) := NULL;
      l_inexp_tag            VARCHAR2(300) := NULL;
      l_perfmeas_tag         VARCHAR2(300) := NULL;
      l_rtasgns_tag          VARCHAR2(300) := NULL;
      l_rtdims_tag           VARCHAR2(300) := '/XX_OIC_RT_FORMULA_ASGN_OBJ/CN_RATE_SCHEDULES_ALL/XX_OIC_RATE_SCHEDULES_OBJ/CN_RATE_SCH_DIMS_ALL/XX_OIC_RATE_SCH_DIMS_OBJ';
      l_rttiers_tag          VARCHAR2(300) := '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/CN_RATE_DIM_TIERS_ALL/XX_OIC_RATE_DIM_TIERS_OBJ';
      l_rtcommsn_tag         VARCHAR2(300) := '/XX_OIC_RT_FORMULA_ASGN_OBJ/CN_RATE_SCHEDULES_ALL/XX_OIC_RATE_SCHEDULES_OBJ/CN_RATE_TIERS_ALL/XX_OIC_RATE_TIERS_OBJ';

  ------------------------------------------------------------------------------
  --    Parameters for calling the Create Formula API
  ------------------------------------------------------------------------------
      l_formula_name                 CN_CALC_FORMULAS.NAME%TYPE                 := NULL;
      l_formula_description          CN_CALC_FORMULAS.DESCRIPTION%TYPE          := NULL;
      l_formula_type                 CN_CALC_FORMULAS.FORMULA_TYPE%TYPE         := NULL;
      l_formula_status               CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_formula_trx_group_code       CN_CALC_FORMULAS.TRX_GROUP_CODE%TYPE       := NULL;
      l_formula_number_dim           CN_CALC_FORMULAS.NUMBER_DIM%TYPE           := NULL;
      l_formula_cumulative_flag      CN_CALC_FORMULAS.CUMULATIVE_FLAG%TYPE      := NULL;
      l_formula_itd_flag             CN_CALC_FORMULAS.ITD_FLAG%TYPE             := NULL;
      l_formula_split_flag           CN_CALC_FORMULAS.SPLIT_FLAG%TYPE           := NULL;
      l_threshold_all_tier_flag      CN_CALC_FORMULAS.THRESHOLD_ALL_TIER_FLAG%TYPE
                                                                        := NULL;
      l_object_version_number        CN_CALC_FORMULAS.OBJECT_VERSION_NUMBER%TYPE:= NULL;
      l_formula_modeling_flag        CN_CALC_FORMULAS.MODELING_FLAG%TYPE        := NULL;
      l_formula_perf_measure_id      CN_CALC_FORMULAS.PERF_MEASURE_ID%TYPE      := NULL;
      l_formula_output_exp_id        CN_CALC_FORMULAS.OUTPUT_EXP_ID%TYPE        := NULL;

      l_formula_input_tbl            CN_CALC_FORMULAS_PVT.input_tbl_type;
      l_formula_input_tbl_id         NUMBER                                     := 0;
      l_formula_rt_assign_tbl        CN_CALC_FORMULAS_PVT.rt_assign_tbl_type;
      l_formula_rt_assign_id         NUMBER                                     := 0;
      l_formula_x_calc_formula_id    CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE      := NULL;
      l_formula_x_formula_status     CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_x_formula_status             CN_CALC_FORMULAS.FORMULA_STATUS%TYPE       := NULL;
      l_rt_formula_exists            NUMBER                                     := NULL;
      rec_formula_input              CN_CALC_FORMULAS_PVT.input_rec_type;
      rec_formula_rt_assign          CN_CALC_FORMULAS_PVT.rt_assign_rec_type;

  ------------------------------------------------------------------------------
  --  Parameters for creating the rate schedules
  ------------------------------------------------------------------------------
      l_rate_name                    CN_RATE_SCHEDULES.NAME%TYPE                 := NULL;
      l_commission_unit_code         CN_RATE_SCHEDULES.COMMISSION_UNIT_CODE%TYPE := NULL;
      l_dim_name                     CN_RATE_DIMENSIONS.NAME%TYPE                := NULL;
      l_dim_description              CN_RATE_DIMENSIONS.DESCRIPTION%TYPE         := NULL;
      l_dim_unit_code                CN_RATE_DIMENSIONS.DIM_UNIT_CODE%TYPE       := NULL;
      l_rate_number_dim              CN_RATE_SCHEDULES.NUMBER_DIM%TYPE           := NULL;
      l_rate_schedule_id             CN_RATE_SCHEDULES.RATE_SCHEDULE_ID%TYPE     := NULL;
      l_rate_dim_sequence            CN_RATE_SCH_DIMS_ALL.RATE_DIM_SEQUENCE%TYPE := NULL;
      l_rate_number_tier             CN_RATE_DIMENSIONS_ALL.NUMBER_TIER%TYPE     := NULL;
      l_rate_dimension_id            CN_RATE_DIMENSIONS_ALL.RATE_DIMENSION_ID%TYPE := NULL;
      rec_rate_tier                  CN_MULTI_RATE_SCHEDULES_PUB.rate_tier_rec_type;
      rec_dim_assign                 CN_MULTI_RATE_SCHEDULES_PUB.dim_assign_rec_type;
      l_dim_assign_tbl               CN_MULTI_RATE_SCHEDULES_PUB.dim_assign_tbl_type;
      l_dim_assign_tbl_id            NUMBER                                      := 0;
      l_rate_tier_tbl                CN_MULTI_RATE_SCHEDULES_PUB.rate_tier_tbl_type;
      l_rate_tier_tbl_id             NUMBER                                      := 0;
      l_tier_coordinates_tbl         CN_MULTI_RATE_SCHEDULES_PUB.tier_coordinates_tbl;
      TYPE l_number_dim_tbl_type     IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
      l_number_dim_tbl               l_number_dim_tbl_type;
      l_number_dim_tbl_id            NUMBER                                      := 0;
      TYPE rec_type_commission       IS RECORD(l_rate_seq               NUMBER,
                                               l_commission_amount      NUMBER,
                                               l_object_version_number  NUMBER
                                               );
      rec_commission                 rec_type_commission;
      TYPE l_tbl_type_commission     IS TABLE OF rec_type_commission INDEX BY BINARY_INTEGER;
      l_tbl_commission               l_tbl_type_commission;
      l_rt_formula_asgn_id           CN_RT_FORMULA_ASGNS.RT_FORMULA_ASGN_ID%TYPE := NULL;
      l_created_by                   NUMBER                := 0;
      l_creation_date                DATE                  := SYSDATE;
      l_updated_by                   NUMBER                := 0;
      l_update_date                  DATE                  := SYSDATE;
      l_last_update_login            NUMBER                := 0;
      l_max_rate_seq                 NUMBER                := 0;
      l_mtrx_count                   NUMBER                := 0;
      l_dim_exists                   NUMBER                := 0;

      l_x_return_status              VARCHAR2(10)                        := 'F';
      l_x_msg_count                  NUMBER;
      l_x_msg_data                   VARCHAR2(32767);
      l_msg_index_out                VARCHAR2(2000);
      l_x_error_mesg                 VARCHAR2(2000);
      l_x_error_code                 VARCHAR2(200);
      xmlc                           varchar2(32000);
      off integer := 1;
  len integer := 4000;


    BEGIN
  ------------------------------------------------------------------------------
  --    Get the XML formula DOMDocument
  ------------------------------------------------------------------------------
        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'In formula creation prog',
                 p_field          => 'cnc_create_formula_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
        l_formula_doc := cnc_retdomdoc_fnc(p_formula_xml);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'got formula doc',
                 p_field          => 'cnc_create_formula_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
  ------------------------------------------------------------------------------
  -- Get the data for the standard who columns
  ------------------------------------------------------------------------------
        FND_PROFILE.GET ('USER_ID', l_created_by);
        FND_PROFILE.GET ('USER_ID', l_updated_by);
        FND_PROFILE.GET ('LOGIN_ID',l_last_update_login);

  ------------------------------------------------------------------------------
  --    Check if the call for this procedure came in from the hierarchy
  --    node or other node and initialise the tag appropriately
  ------------------------------------------------------------------------------
        CASE p_tag_type
        WHEN L_DEPENDENT_TAGTYPE THEN
             l_formula_tag     := '/CN_CALC_FORMULAS_ALL';
        WHEN L_MAIN_TAGTYPE THEN
             l_formula_tag     := '/XX_OIC_CALC_FORMULAS_OBJ';
        ELSE
             cnc_write_log_prc('The formula tag type is invalid: ' ||
                               p_tag_type
                              );
        END CASE;

        l_outexp_tag           := l_formula_tag || '/CN_OUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';
        l_inexp_tag            := l_formula_tag || '/CN_FORMULA_INPUTS_ALL/XX_OIC_FORMULA_INPUTS_OBJ';
        l_perfmeas_tag         := l_formula_tag || '/CN_PERF_MEASURES_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ';
        l_rtasgns_tag          := l_formula_tag || '/CN_RT_FORMULA_ASGNS_ALL/XX_OIC_RT_FORMULA_ASGN_OBJ';

  ------------------------------------------------------------------------------
  --    Create nodelist to traverse Formula
  ------------------------------------------------------------------------------
        l_formula_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_formula_doc), l_formula_tag);
        FOR l_formula_num IN 0 .. xmldom.getlength (l_formula_nodelist) - 1
        LOOP
            l_formula_node := xmldom.item (l_formula_nodelist, l_formula_num);
  ------------------------------------------------------------------------------
  --  Get the data value for the formula columns
  ------------------------------------------------------------------------------
            l_formula_name              := xslprocessor.valueof (l_formula_node, 'NAME');
            l_formula_description       := xslprocessor.valueof (l_formula_node, 'DESCRIPTION');
            l_formula_type              := xslprocessor.valueof (l_formula_node, 'FORMULA_TYPE');
            l_formula_status            := xslprocessor.valueof (l_formula_node, 'FORMULA_STATUS');
            l_formula_trx_group_code    := xslprocessor.valueof (l_formula_node, 'TRX_GROUP_CODE');
            l_formula_number_dim        := xslprocessor.valueof (l_formula_node, 'NUMBER_DIM');
            l_formula_cumulative_flag   := xslprocessor.valueof (l_formula_node, 'CUMULATIVE_FLAG');
            l_formula_itd_flag          := xslprocessor.valueof (l_formula_node, 'ITD_FLAG');
            l_formula_split_flag        := xslprocessor.valueof (l_formula_node, 'SPLIT_FLAG');
            l_threshold_all_tier_flag   := xslprocessor.valueof (l_formula_node, 'THRESHOLD_ALL_TIER_FLAG');
            l_formula_modeling_flag     := xslprocessor.valueof (l_formula_node, 'MODELING_FLAG');
            l_object_version_number     := xslprocessor.valueof (l_formula_node, 'OBJECT_VERSION_NUMBER');


            l_formula_rt_assign_tbl.DELETE;
            l_formula_rt_assign_id      := 0;
            rec_formula_rt_assign       := NULL;
            l_dim_assign_tbl_id         := 0;
            l_rate_tier_tbl_id          := 0;
            l_number_dim_tbl_id         := 0;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Processing formula',
                     p_field          => 'cnc_create_formula_prc',
                     p_field_value    => 'l_formula_name : '||l_formula_name,
                     p_record_id      => NULL
                    );
            END IF;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Creating output exp',
                     p_field          => 'cnc_create_formula_prc',
                     p_field_value    => 'l_formula_name : '||l_formula_name,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  Create Output expression
  ------------------------------------------------------------------------------
            l_outexpr_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_formula_doc), l_outexp_tag);
            FOR l_outexp_num IN 0 .. xmldom.getlength (l_outexpr_nodelist) -1
            LOOP
                l_outexp_node := xmldom.item (l_outexpr_nodelist, l_outexp_num);
                l_exp_name    := NULL;
                l_exp_name    := xslprocessor.valueof (l_outexp_node, 'NAME');

  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                IF l_exp_name IS NOT NULL THEN
                l_result     := 'a';
                xmldom.writetoclob(l_outexp_node,l_result);
                   BEGIN
 
                     SELECT CCSEA.calc_sql_exp_id
                       INTO l_calc_sql_exp_id
                       FROM cn_calc_sql_exps_all CCSEA
                      WHERE CCSEA.name = l_exp_name;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      l_calc_sql_exp_id := 0;
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE;
                   END;
                   IF l_calc_sql_exp_id = 0 THEN
                      CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_OUTPUT,l_formula_output_exp_id);
                   ELSE
                      l_formula_output_exp_id := l_calc_sql_exp_id;
                      IF NOT cn_created_ele_fnc(l_exp_name,L_EXPR_ELE) THEN
                          cnc_write_log_prc('Warning: The Expression: ' ||
                                            l_exp_name || ' exists.'
                                           );
                      END IF;
                   END IF;
                END IF;
            END LOOP;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Creating input exp',
                     p_field          => 'cnc_create_formula_prc',
                     p_field_value    => 'l_formula_name : '||l_formula_name,
                     p_record_id      => NULL
                    );
            END IF;
  ------------------------------------------------------------------------------
  --  Create Input expression
  ------------------------------------------------------------------------------
            l_inexpr_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_formula_doc), l_inexp_tag);
            FOR l_inexp_num IN 0 .. xmldom.getlength (l_inexpr_nodelist) -1
            LOOP
                l_inexp_node := xmldom.item (l_inexpr_nodelist, l_inexp_num);
                l_result      := 'a';
                xmldom.writetoclob(l_inexp_node,l_result);
                l_inexp_doc := cnc_retdomdoc_fnc(l_result);

                l_exp_name := NULL;
                l_exp_name := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_INPUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/NAME');
  ------------------------------------------------------------------------------
  -- Validate if the expression exists already
  ------------------------------------------------------------------------------
                IF l_exp_name IS NOT NULL THEN
                   BEGIN
                      SELECT CCSEA.calc_sql_exp_id
                        INTO l_calc_sql_exp_id
                        FROM cn_calc_sql_exps_all CCSEA
                       WHERE CCSEA.name = l_exp_name;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      l_calc_sql_exp_id := 0;
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE;
                   END;

                   IF l_calc_sql_exp_id = 0 THEN
                      CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_INPUT,l_calc_sql_exp_id);
                      rec_formula_input.calc_sql_exp_id := l_calc_sql_exp_id;
                   ELSE
                       rec_formula_input.calc_sql_exp_id := l_calc_sql_exp_id;
                       IF NOT cn_created_ele_fnc(l_exp_name,L_EXPR_ELE) THEN
                          cnc_write_log_prc('Warning: The Expression: ' ||
                                            l_exp_name || ' exists.'
                                           );
                       END IF;
                   END IF;
                END IF;

                rec_formula_input.cumulative_flag   := xslprocessor.valueof (l_inexp_node, 'CUMULATIVE_FLAG');
                rec_formula_input.split_flag        := xslprocessor.valueof (l_inexp_node, 'SPLIT_FLAG');
                rec_formula_input.rate_dim_sequence := xslprocessor.valueof (l_inexp_node, 'RATE_DIM_SEQUENCE');
                rec_formula_input.calc_exp_name     := l_exp_name;
                rec_formula_input.calc_exp_status   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_INPUT_SQL_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/STATUS');
                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Creating Forecast exp',
                         p_field          => 'cnc_create_formula_prc',
                         p_field_value    => 'l_formula_name : '||l_formula_name,
                         p_record_id      => NULL
                        );
                END IF;

  ------------------------------------------------------------------------------
  --  Create Forecast Input expression
  ------------------------------------------------------------------------------
                l_exp_name := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_FORECAST_INPUT_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/NAME');
  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                IF l_exp_name IS NOT NULL THEN
                   BEGIN
                      SELECT CCSEA.calc_sql_exp_id
                        INTO l_calc_sql_exp_id
                        FROM cn_calc_sql_exps_all CCSEA
                       WHERE CCSEA.name = l_exp_name;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      l_calc_sql_exp_id := 0;
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE;
                   END;
                   IF l_calc_sql_exp_id = 0 THEN
                      CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_FINPUT,l_calc_sql_exp_id);
                      rec_formula_input.f_calc_sql_exp_id := l_calc_sql_exp_id;
                   ELSE
                      rec_formula_input.f_calc_sql_exp_id := l_calc_sql_exp_id;
                      IF NOT cn_created_ele_fnc(l_exp_name,L_EXPR_ELE) THEN
                          cnc_write_log_prc('Warning: The Expression: ' ||
                                            l_exp_name || ' exists.'
                                           );
                      END IF;
                   END IF;
                   rec_formula_input.f_calc_exp_name   := l_exp_name;
                   rec_formula_input.f_calc_exp_status := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_inexp_doc, '/XX_OIC_FORMULA_INPUTS_OBJ/CN_FORECAST_INPUT_EXPS_ALL/XX_OIC_CALC_EXPRESSIONS_OBJ/STATUS');
                END IF;
  ------------------------------------------------------------------------------
  --              END Forecast input;
  ------------------------------------------------------------------------------

                l_formula_input_tbl_id                      := l_formula_input_tbl_id + 1;
                l_formula_input_tbl(l_formula_input_tbl_id) := rec_formula_input;
            END LOOP;

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Creating Performance exp',
                         p_field          => 'cnc_create_formula_prc',
                         p_field_value    => 'l_formula_name : '||l_formula_name,
                         p_record_id      => NULL
                        );
                END IF;

  ------------------------------------------------------------------------------
  --  Create Performance Measure
  ------------------------------------------------------------------------------
            l_perfmeas_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_formula_doc), l_perfmeas_tag);
            FOR l_perfmeas_num IN 0 .. xmldom.getlength (l_perfmeas_nodelist) -1
            LOOP
                l_perfmeas_node := xmldom.item (l_perfmeas_nodelist, l_perfmeas_num);
                l_exp_name := NULL;
                l_exp_name := xslprocessor.valueof (l_perfmeas_node, 'NAME');

  ------------------------------------------------------------------------------
  --  Validate if the expression exists already
  ------------------------------------------------------------------------------
                IF l_exp_name IS NOT NULL THEN
                  l_result     := 'a';
                  xmldom.writetoclob(l_perfmeas_node,l_result);
                   BEGIN
                     SELECT CCSEA.calc_sql_exp_id
                       INTO l_calc_sql_exp_id
                       FROM cn_calc_sql_exps_all CCSEA
                      WHERE CCSEA.name = l_exp_name;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      l_calc_sql_exp_id := 0;
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE;
                   END;
                   IF l_calc_sql_exp_id = 0 THEN
                      CNC_CREATE_EXPRESSION_PRC(l_result,L_EXP_PERFMEAS,l_formula_perf_measure_id);
                   ELSE
                      l_formula_perf_measure_id := l_calc_sql_exp_id;
                      IF NOT cn_created_ele_fnc(l_exp_name,L_EXPR_ELE) THEN
                          cnc_write_log_prc('Warning: The Expression: ' ||
                                            l_exp_name || ' exists.'
                                           );
                      END IF;
                   END IF;
                END IF;
            END LOOP;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'Processing rate tables',
                     p_field          => 'cnc_create_formula_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;

  ------------------------------------------------------------------------------
  --   Create Rate tables
  ------------------------------------------------------------------------------
            l_rtasgns_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_formula_doc), l_rtasgns_tag);
--DBMS_LOB.READ(l_formula_doc, len, off, xmlc); -- Display first part on screen
 
            FOR l_rtasgns_num IN 0 .. xmldom.getlength (l_rtasgns_nodelist) -1
            LOOP
                l_rtasgns_node := xmldom.item (l_rtasgns_nodelist, l_rtasgns_num);
                l_result       := 'a';
                xmldom.writetoclob(l_rtasgns_node,l_result);
                l_rtasgns_doc  := cnc_retdomdoc_fnc(l_result);
                l_dim_assign_tbl_id := 0;
                l_dim_assign_tbl.DELETE;

                l_rate_name            := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_OBJ/CN_RATE_SCHEDULES_ALL/XX_OIC_RATE_SCHEDULES_OBJ/NAME');
                l_commission_unit_code := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_OBJ/CN_RATE_SCHEDULES_ALL/XX_OIC_RATE_SCHEDULES_OBJ/COMMISSION_UNIT_CODE');
                l_rate_number_dim      := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtasgns_doc, '/XX_OIC_RT_FORMULA_ASGN_OBJ/CN_RATE_SCHEDULES_ALL/XX_OIC_RATE_SCHEDULES_OBJ/NUMBER_DIM');

                rec_formula_rt_assign.start_date            := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'START_DATE'),'DD-MON-YYYY');
                rec_formula_rt_assign.end_date              := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'END_DATE'),'DD-MON-YYYY');
                rec_formula_rt_assign.rate_schedule_name    := l_rate_name;
                rec_formula_rt_assign.rate_schedule_type    := l_commission_unit_code;

                BEGIN
                     l_rate_schedule_id := 0;
                     SELECT CRSA.rate_schedule_id
                       INTO l_rate_schedule_id
                       FROM cn_rate_schedules_all CRSA
                      WHERE CRSA.name = l_rate_name;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     l_rate_schedule_id := 0;
                WHEN others THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE;
                END;

                IF l_rate_schedule_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Process Rate Dimensions
  ------------------------------------------------------------------------------
                 l_rate_tier_tbl_id := 0;
                 l_dim_exists       := 0;
                 l_rtdims_nodelist  := xslprocessor.selectnodes (xmldom.makenode(l_rtasgns_doc), l_rtdims_tag);
                 FOR l_rtdims_num IN 0 .. xmldom.getlength (l_rtdims_nodelist) -1
                 LOOP
 
                    l_rtdims_node       := xmldom.item (l_rtdims_nodelist, l_rtdims_num);
                    l_result            := 'a';
                    xmldom.writetoclob(l_rtdims_node,l_result);
                    l_rtdims_doc        := cnc_retdomdoc_fnc(l_result);
                    l_dim_name          := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/NAME');
                    l_dim_description   := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/DESCRIPTION');
                    l_dim_unit_code     := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/DIM_UNIT_CODE');
                    l_rate_dim_sequence := xslprocessor.valueof (l_rtdims_node, 'RATE_DIM_SEQUENCE');
                    l_rate_number_tier  := XX_OIC_XPATH_PKG.cnc_extract_fnc (l_rtdims_doc, '/XX_OIC_RATE_SCH_DIMS_OBJ/CN_RATE_DIMENSIONS_ALL/XX_OIC_RATE_DIMENSIONS_OBJ/NUMBER_TIER');
  ------------------------------------------------------------------------------
  --  Identify the number of tiers for each dimension
  ------------------------------------------------------------------------------
                    l_number_dim_tbl_id                      := l_number_dim_tbl_id + 1;
                    l_number_dim_tbl(l_number_dim_tbl_id)    := l_rate_number_tier;

                    BEGIN
                       SELECT rate_dimension_id
                         INTO l_rate_dimension_id
                         FROM cn_rate_dimensions_all CRDA
                        WHERE CRDA.name = l_dim_name;
 
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         l_rate_dimension_id := 0;
                    WHEN others THEN
                         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                         RAISE;
                    END;

                    IF l_rate_dimension_id = 0 THEN
  ------------------------------------------------------------------------------
  --  Rate Dimension Does not exist. Get the Rate Tiers
  ------------------------------------------------------------------------------
                     l_rate_tier_tbl.DELETE;
                     l_rate_tier_tbl_id := 0;
                     l_rttiers_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtdims_doc), l_rttiers_tag);
                     FOR l_rttiers_num IN 0 .. xmldom.getlength (l_rttiers_nodelist) -1
                     LOOP
                        l_rttiers_node := xmldom.item (l_rttiers_nodelist, l_rttiers_num);
                        rec_rate_tier.tier_sequence         := xslprocessor.valueof (l_rttiers_node, 'TIER_SEQUENCE');
                        rec_rate_tier.value1                := xslprocessor.valueof (l_rttiers_node, 'MINIMUM_AMOUNT');
                        rec_rate_tier.value2                := xslprocessor.valueof (l_rttiers_node, 'MAXIMUM_AMOUNT');
                        rec_rate_tier.object_version_number := xslprocessor.valueof (l_rttiers_node, 'OBJECT_VERSION_NUMBER');
  ------------------------------------------------------------------------------
  --  Rate tier sequence will not be in order
  --  So create rate tiers based on sequence number
  ------------------------------------------------------------------------------
                        l_rate_tier_tbl_id                  := rec_rate_tier.tier_sequence;
                        l_rate_tier_tbl(l_rate_tier_tbl_id) := rec_rate_tier;
                     END LOOP;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Call to create_dimension API',
                             p_field          => 'cnc_create_formula_prc',
                             p_field_value    => 'l_dim_name : '||l_dim_name,
                             p_record_id      => NULL
                            );
                    END IF;

                     BEGIN
 
                         cn_multi_rate_schedules_pub.create_dimension
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_name                 => l_dim_name,
                                         p_description          => l_dim_description,
                                         p_dim_unit_code        => l_dim_unit_code,
                                         p_tiers_tbl            => l_rate_tier_tbl,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                         IF l_x_return_status <> 'S' THEN --Rate Dimension API Return status
                            IF (fnd_msg_pub.count_msg <> 0) THEN
                               FOR i IN 1 .. fnd_msg_pub.count_msg --Message Count
                               LOOP
                                   fnd_msg_pub.get
                                       ( p_msg_index     => i,
                                         p_encoded       => fnd_api.g_false,
                                         p_data          => l_x_msg_data,
                                         p_msg_index_out => l_msg_index_out
                                       );
                                  l_x_error_mesg := SUBSTR (l_x_error_mesg ||
                                                            ' ' ||
                                                            l_msg_index_out ||
                                                            l_x_msg_data,
                                                            1,
                                                            2000);
                               END LOOP;
                            END IF; -- Message Count
                            l_x_error_code := 'Error: Create rate dimension '
                                              || l_dim_name;
                            l_x_error_mesg := SUBSTR (l_x_error_mesg,1, 2000);
                            cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                              l_x_error_mesg
                                             );
                            RAISE g_create_ratedim_error;
                         ELSE
                             cnc_write_log_prc('Creation of Rate Dimension ' ||
                                                l_dim_name || ' succeeded.'
                                              );
                             g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                             rec_created_ele.l_name := l_dim_name;
                             rec_created_ele.l_type := L_RATEDIM_ELE;
                             g_tbl_created_ele(g_tbl_created_ele_id)
                                                         := rec_created_ele;
                         END IF; --Rate Dimension API Return status
                     EXCEPTION
                     WHEN OTHERS THEN
                         cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                         RAISE g_create_ratedim_error;
                     END;
                    ELSE
                        l_dim_exists        := 1;
                        IF NOT cn_created_ele_fnc(l_dim_name,L_RATEDIM_ELE) THEN
                           cnc_write_log_prc('Warning: The Rate Dimension: ' ||
                                             l_dim_name || ' exists.'
                                            );
                        END IF;
                    END IF;
                    rec_dim_assign.rate_schedule_name       := l_rate_name;
                    rec_dim_assign.rate_dim_name            := l_dim_name;
                    rec_dim_assign.rate_dim_sequence        := l_rate_dim_sequence;
                    rec_dim_assign.object_version_number    := 0;
                    l_dim_assign_tbl_id                     := l_dim_assign_tbl_id + 1;
                    l_dim_assign_tbl(l_dim_assign_tbl_id)   := rec_dim_assign;
                END LOOP; --rtdims
  ------------------------------------------------------------------------------
  -- Create the Rate Schedule
  ------------------------------------------------------------------------------
                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Call to create_schedule API',
                         p_field          => 'cnc_create_formula_prc',
                         p_field_value    => 'l_rate_name : '||l_rate_name,
                         p_record_id      => NULL
                        );
                END IF;

                BEGIN
                      cn_multi_rate_schedules_pub.create_schedule
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_name                 => l_rate_name,
                                         p_commission_unit_code => l_commission_unit_code,
                                         p_dims_tbl             => l_dim_assign_tbl,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                IF l_x_return_status <> 'S' THEN
                   IF (fnd_msg_pub.count_msg <> 0) THEN
                      FOR i IN 1 .. fnd_msg_pub.count_msg
                      LOOP
                          fnd_msg_pub.get (p_msg_index          => i,
                                           p_encoded            => FND_API.G_FALSE,
                                           p_data               => l_x_msg_data,
                                           p_msg_index_out      => l_msg_index_out
                                           );
                          l_x_error_mesg := SUBSTR (l_x_error_mesg || ' '
                                                    || l_msg_index_out||
                                                    l_x_msg_data,
                                                    1,
                                                    2000
                                                   );
                      END LOOP;
                   END IF;                                      --Message Count
                   l_x_error_code := 'Error: Create Rate Table '
                                      || l_rate_name;
                   l_x_error_mesg := SUBSTR (l_x_error_mesg, 1, 2000);
                   cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                     l_x_error_mesg
                                    );
                   RAISE g_create_ratesch_error;
                ELSE
                   cnc_write_log_prc('Creation of Rate Schedule ' ||
                                     l_rate_name || 'succeeded.'
                                    );
                   g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                   rec_created_ele.l_name := l_rate_name;
                   rec_created_ele.l_type := L_RATESCH_ELE;
                   g_tbl_created_ele(g_tbl_created_ele_id)
                                               := rec_created_ele;

                END IF;   --CREATE Rate API Status
                EXCEPTION
                WHEN OTHERS THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE g_create_ratesch_error;
                END; --Create Rate Schedules

  ------------------------------------------------------------------------------
  --  If rate dimension existed then no need for Commission recreation
  ------------------------------------------------------------------------------
                IF l_dim_exists = 0 THEN
  ------------------------------------------------------------------------------
  --  Capture all the commission amount parameters into a PLSQL table
  --  and also find the maximum value of a tier sequence for the rate table
  ------------------------------------------------------------------------------
                  l_rtcommsn_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_rtasgns_doc), l_rtcommsn_tag);
                  l_max_rate_seq      := 0;
                  FOR l_rtcommsn_num IN 0 .. xmldom.getlength (l_rtcommsn_nodelist) -1
                  LOOP
                    l_rtcommsn_node                            := xmldom.item (l_rtcommsn_nodelist, l_rtcommsn_num);
                    rec_commission.l_rate_seq                  := xslprocessor.valueof(l_rtcommsn_node,'RATE_SEQUENCE');
                    rec_commission.l_commission_amount         := xslprocessor.valueof(l_rtcommsn_node,'COMMISSION_AMOUNT');
                    rec_commission.l_object_version_number     := xslprocessor.valueof(l_rtcommsn_node,'OBJECT_VERSION_NUMBER');
                    l_tbl_commission(rec_commission.l_rate_seq):= rec_commission;
                    IF rec_commission.l_rate_seq > l_max_rate_seq THEN
                       l_max_rate_seq  := rec_commission.l_rate_seq;
                    END IF;
                  END LOOP;
                  xmldom.freedocument(l_rtasgns_doc);
  ------------------------------------------------------------------------------
  --   If any tier sequence doesnot exist, then capture and handle
  --   such sequences so that the program doesnot error out with
  --   a no data found error.
  ------------------------------------------------------------------------------
                  FOR i IN 1 .. l_max_rate_seq
                  LOOP
                      IF NOT(l_tbl_commission.EXISTS(i)) THEN
                         rec_commission.l_rate_seq              := NULL;
                         rec_commission.l_commission_amount     := NULL;
                         rec_commission.l_object_version_number := NULL;
                         l_tbl_commission(i)                    := rec_commission;
                      END IF;
                  END LOOP;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Number of tiers',
                             p_field          => 'cnc_create_formula_prc',
                             p_field_value    => 'l_rate_number_dim : '||l_rate_number_dim,
                             p_record_id      => NULL
                            );
                    END IF;
  ------------------------------------------------------------------------------
  --   The implementaion of commission amount requires a matrix
  --   kind of structure. Since the dimension of the matrix is
  --   not known and PLSQL does not support dynamic matrix creation
  --   this program handles a maximum of 4 dimensions. The variable
  --   l_rate_number_dim holds the number_dim value of the rate schedule
  ------------------------------------------------------------------------------
                    CASE l_rate_number_dim
  ------------------------------------------------------------------------------
  --  Single dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 1 THEN
                         FOR i IN  1 .. l_rate_number_tier
                         LOOP
                          l_tier_coordinates_tbl(1) := i;

                            -- Write additional debug messages
                            IF g_debug_flag = 'Y' THEN
                               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                    (p_error_message  => 'Coordinates',
                                     p_field          => 'cnc_create_formula_prc',
                                     p_field_value    => 'l_tier_coordinates_tbl : '||i,
                                     p_record_id      => NULL
                                    );
                            END IF;

                          BEGIN
                            IF (l_rate_number_tier <= l_max_rate_seq) THEN
                               cn_multi_rate_schedules_pub.update_rate
                                        (p_api_version          => 1,
                                         p_commit               => FND_API.G_FALSE,
                                         p_rate_schedule_name   => l_rate_name,
                                         p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                         p_commission_amount    => l_tbl_commission(i).l_commission_amount,
                                         p_object_version_number=> l_tbl_commission(i).l_object_version_number,
                                         x_return_status        => l_x_return_status,
                                         x_msg_count            => l_x_msg_count,
                                         x_msg_data             => l_x_msg_data);

                               IF l_x_return_status <> 'S' THEN
                                  IF (fnd_msg_pub.count_msg <> 0) THEN
                                     FOR i IN 1 .. fnd_msg_pub.count_msg
                                     LOOP
                                         fnd_msg_pub.get
                                           (p_msg_index          => i,
                                            p_encoded            => FND_API.G_FALSE,
                                            p_data               => l_x_msg_data,
                                            p_msg_index_out      => l_msg_index_out
                                           );
                                         l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out || l_x_msg_data, 1, 2000);
                                     END LOOP;
                                  END IF;
                                  l_x_error_code := 'Error: Update Rate '
                                                    || l_rate_name;
                                  l_x_error_mesg := SUBSTR (l_x_error_mesg,1, 2000);
                                  cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                   );
                                  RAISE g_update_commsn_error;
                               ELSE
                                  cnc_write_log_prc
                                     ('Update of Commission Amount for ' ||
                                      'rate table ' || l_rate_name ||
                                      ' succeeded.'
                                     );
                               END IF;
                            END IF;
                          EXCEPTION
                          WHEN OTHERS THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE g_update_commsn_error;
                          END;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Two dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 2 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;
                                 IF (l_mtrx_count <= l_max_rate_seq) THEN

                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Coordinates',
                                             p_field          => 'cnc_create_formula_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;
                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);

                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out|| l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                          RAISE g_update_commsn_error;
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Three dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 3 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                               FOR k In 1 .. l_number_dim_tbl(3)
                               LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;
                                 l_tier_coordinates_tbl(3) := k;
                                 IF (l_mtrx_count <= l_max_rate_seq) THEN

                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Coordinates',
                                             p_field          => 'cnc_create_formula_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;

                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);
                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out||l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                               END LOOP;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  Four dimension rate table
  ------------------------------------------------------------------------------
                    WHEN 4 THEN
                         l_mtrx_count := 0;
                         FOR i IN 1 .. l_number_dim_tbl(1)
                         LOOP
                             FOR j IN 1 .. l_number_dim_tbl(2)
                             LOOP
                               FOR k In 1 .. l_number_dim_tbl(3)
                               LOOP
                                FOR l In 1 .. l_number_dim_tbl(4)
                                LOOP
                                 l_mtrx_count              := l_mtrx_count + 1;
                                 l_tier_coordinates_tbl(1) := i;
                                 l_tier_coordinates_tbl(2) := j;
                                 l_tier_coordinates_tbl(3) := k;
                                 l_tier_coordinates_tbl(4) := l;
                                 IF (l_mtrx_count <= l_max_rate_seq) THEN

                                    -- Write additional debug messages
                                    IF g_debug_flag = 'Y' THEN
                                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                            (p_error_message  => 'Coordinates',
                                             p_field          => 'cnc_create_formula_prc',
                                             p_field_value    => 'l_mtrx_count : '||l_mtrx_count,
                                             p_record_id      => NULL
                                            );
                                    END IF;

                                 BEGIN
                                       cn_multi_rate_schedules_pub.update_rate
                                                (p_api_version          => 1,
                                                 p_commit               => FND_API.G_FALSE,
                                                 p_rate_schedule_name   => l_rate_name,
                                                 p_tier_coordinates_tbl => l_tier_coordinates_tbl,
                                                 p_commission_amount    => l_tbl_commission(l_mtrx_count).l_commission_amount,
                                                 p_object_version_number=> l_tbl_commission(l_mtrx_count).l_object_version_number,
                                                 x_return_status        => l_x_return_status,
                                                 x_msg_count            => l_x_msg_count,
                                                 x_msg_data             => l_x_msg_data);
                                       IF l_x_return_status <> 'S' THEN
                                          IF (fnd_msg_pub.count_msg <> 0) THEN
                                             FOR i IN 1 .. fnd_msg_pub.count_msg
                                             LOOP
                                                 fnd_msg_pub.get (p_msg_index          => i,
                                                                  p_encoded            => fnd_api.g_false,
                                                                  p_data               => l_x_msg_data,
                                                                  p_msg_index_out      => l_msg_index_out
                                                                  );
                                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' || l_msg_index_out||l_x_msg_data, 1, 2000);
                                             END LOOP;
                                          END IF;
                                          l_x_error_code
                                                    := 'Error: Update Rate '
                                                       || l_rate_name;
                                          l_x_error_mesg
                                                    := SUBSTR (l_x_error_mesg,
                                                               1,2000
                                                              );
                                          cnc_write_log_prc
                                                  (l_x_error_code || CHR(10) ||
                                                    l_x_error_mesg
                                                  );
                                       ELSE
                                          cnc_write_log_prc
                                             ('Update of Commission Amount for '
                                              || 'rate table ' ||
                                              l_rate_name ||
                                              ' succeeded.'
                                             );
                                       END IF;
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                                       RAISE g_update_commsn_error;
                                 END;
                                 END IF;
                                END LOOP;
                               END LOOP;
                             END LOOP;
                         END LOOP;
  ------------------------------------------------------------------------------
  --  END of matrix implementation for Commission rates
  ------------------------------------------------------------------------------
                    ELSE
                          cnc_write_log_prc('The rate dimension value is ' ||
                                            'greater than 4. Value is: ' ||
                                             l_rate_number_dim
                                           );
                    END CASE;
                ELSE
                    cnc_write_log_prc('Error: The rate table ' || l_rate_name ||
                                      'has been associated to existing rate ' ||
                                      'dimensions. Please update the commission'
                                      || ' rates to this rate table manually');
                END IF;--If rate dimension existed then no need for Commission recreation
  ------------------------------------------------------------------------------
  -- Get the rate table id for creating the formula
  ------------------------------------------------------------------------------
                BEGIN
                     SELECT CRSA.rate_schedule_id
                       INTO l_rate_schedule_id
                       FROM cn_rate_schedules_all CRSA
                      WHERE CRSA.name = l_rate_name;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     cnc_write_log_prc('Rate Table: ' || l_rate_name || ' not found');
                     RAISE g_create_formula_error;
                WHEN others THEN
                     cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                     RAISE;
                END;

                rec_formula_rt_assign.rate_schedule_id := l_rate_schedule_id;
               ELSE
                   rec_formula_rt_assign.rate_schedule_id := l_rate_schedule_id;
                   IF NOT cn_created_ele_fnc(l_rate_name,
                                             L_RATESCH_ELE) THEN
                           cnc_write_log_prc('Warning: The Rate Table: ' ||
                                             l_rate_name || ' exists.'
                                            );
                   END IF;
               END IF;
               l_formula_rt_assign_id                          := l_formula_rt_assign_id + 1;
 
            l_formula_rt_assign_tbl(l_formula_rt_assign_id) := rec_formula_rt_assign;
            END LOOP; --rtasgns

  ------------------------------------------------------------------------------
  -- Check if the formula does not exist. IF yes then create formula, else update
  ------------------------------------------------------------------------------
            BEGIN
                 l_calc_formula_id := 0;
                 SELECT  CCFA.calc_formula_id
                   INTO  l_calc_formula_id
                   FROM  cn_calc_formulas_all CCFA
                  WHERE  CCFA.NAME   = l_formula_name
                    AND  CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 l_calc_formula_id := 0;
            WHEN OTHERS THEN
                 cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                 RAISE;
            END;

            IF l_calc_formula_id = 0 THEN

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'create_formula API Call',
                         p_field          => 'cnc_create_formula_prc',
                         p_field_value    => 'l_formula_name : '||l_formula_name,
                         p_record_id      => NULL
                        );
                END IF;
            BEGIN
                 cn_calc_formulas_pvt.create_formula
                                        (p_api_version             => 1,
                                         p_commit                  => FND_API.G_FALSE,
                                         p_name                    => l_formula_name,
                                         p_description             => l_formula_description,
                                         p_formula_type            => l_formula_type,
                                         p_trx_group_code          => l_formula_trx_group_code,
                                         p_number_dim              => l_formula_number_dim,
                                         p_cumulative_flag         => l_formula_cumulative_flag,
                                         p_itd_flag                => l_formula_itd_flag,
                                         p_split_flag              => l_formula_split_flag,
                                         p_threshold_all_tier_flag => l_threshold_all_tier_flag,
                                         p_modeling_flag           => l_formula_modeling_flag,
                                         p_perf_measure_id         => l_formula_perf_measure_id,
                                         p_output_exp_id           => l_formula_output_exp_id,
                                         p_f_output_exp_id         => NULL,
                                         p_input_tbl               => l_formula_input_tbl,
                                         p_rt_assign_tbl           => l_formula_rt_assign_tbl,
                                         x_calc_formula_id         => l_formula_x_calc_formula_id,
                                         x_formula_status          => l_formula_x_formula_status,
                                         x_return_status           => l_x_return_status,
                                         x_msg_count               => l_x_msg_count,
                                         x_msg_data                => l_x_msg_data);
                 IF l_x_return_status <> 'S' THEN
                    IF (fnd_msg_pub.count_msg <> 0) THEN
                       FOR i IN 1 .. fnd_msg_pub.count_msg
                       LOOP
                           fnd_msg_pub.get
                                   (p_msg_index          => i,
                                    p_encoded            => fnd_api.g_false,
                                    p_data               => l_x_msg_data,
                                    p_msg_index_out      => l_msg_index_out
                                   );
                           l_x_error_mesg := SUBSTR (l_x_error_mesg || ' '
                                                     || l_msg_index_out
                                                     || l_x_msg_data,
                                                     1,
                                                     2000);
                       END LOOP;
                    END IF;

                    l_x_error_code := 'Error: Create Formula '|| l_formula_name;
                    l_x_error_mesg := SUBSTR (l_x_error_mesg,1,2000);
                    cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                      l_x_error_mesg
                                     );
                    RAISE g_create_formula_error;
                 ELSE
                    cnc_write_log_prc('Creation of Formula ' ||
                                       l_formula_name ||
                                      ' succeeded with status: ' ||
                                      l_formula_x_formula_status
                                     );
                 END IF;
                 EXCEPTION
                 WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                 END;
  ------------------------------------------------------------------------------
  -- If the formula exists then update the formula
  ------------------------------------------------------------------------------
                   ELSE
                   l_formula_x_calc_formula_id := l_calc_formula_id;
                   BEGIN
                      l_rt_formula_exists := 0;
                      FOR rec_formula_rates IN c_formula_rates(l_calc_formula_id)
                      LOOP
                        -- Write additional debug messages
                        IF g_debug_flag = 'Y' THEN
                           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                (p_error_message  => 'Formula exists and has associated rate tables',
                                 p_field          => 'cnc_create_formula_prc',
                                 p_field_value    => 'l_calc_formula_id : '||l_calc_formula_id,
                                 p_record_id      => NULL
                                );
                        END IF;

                        cnc_write_log_prc('Warning: The formula ' || l_formula_name
                                          || ' exists and has rate tables associated to it.'
                                          || ' Program will not override the associations');

                        l_rt_formula_exists := 1;
                        EXIT;
                      END LOOP;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                        NULL;
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                   END;
                IF l_rt_formula_exists = 0 THEN
 
 
                   BEGIN
rec_formula_rt_assign.rate_schedule_id      := l_rate_schedule_id;
rec_formula_rt_assign.start_date            := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'START_DATE'),'DD-MON-YYYY');
rec_formula_rt_assign.end_date              := TO_DATE(xslprocessor.valueof (l_rtasgns_node, 'END_DATE'),'DD-MON-YYYY');
rec_formula_rt_assign.rate_schedule_name    := l_rate_name;
rec_formula_rt_assign.rate_schedule_type    := l_commission_unit_code;

 l_formula_rt_assign_tbl(l_formula_rt_assign_id) := rec_formula_rt_assign;

              FOR i in l_formula_rt_assign_tbl.FIRST ..l_formula_rt_assign_tbl.LAST
                     LOOP
                          BEGIN
                          l_rt_formula_asgn_id := NULL;

                            -- Write additional debug messages
                            IF g_debug_flag = 'Y' THEN
                               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                                    (p_error_message  => 'insert_row api to create date asso',
                                     p_field          => 'cnc_create_formula_prc',
                                     p_field_value    => NULL,
                                     p_record_id      => NULL
                                    );
                            END IF;

                          cnc_write_log_prc('Associating rate table ' ||
                                            l_formula_rt_assign_tbl(i).rate_schedule_name
                                            ||  ' to formula: ' || l_formula_name
                                           );

                          cn_rt_formula_asgns_pkg.insert_row
                                  (
                                   X_RT_FORMULA_ASGN_ID    => l_rt_formula_asgn_id,
                                   X_CALC_FORMULA_ID       => l_calc_formula_id,
                                   X_RATE_SCHEDULE_ID      => l_formula_rt_assign_tbl(i).rate_schedule_id,
                                   X_START_DATE            => l_formula_rt_assign_tbl(i).start_date,
                                   X_END_DATE              => l_formula_rt_assign_tbl(i).end_date,
                                   X_CREATION_DATE         => l_creation_date,
                                   X_CREATED_BY            => l_created_by,
                                   X_LAST_UPDATE_DATE      => l_update_date,
                                   X_LAST_UPDATED_BY       => l_updated_by,
                                   X_LAST_UPDATE_LOGIN     => l_last_update_login
                                  );
                          EXCEPTION
                          WHEN others THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE;
                          END;
                      END LOOP;

                      cnc_write_log_prc
                                       ('Assignment of rate table to formula' ||
                                        l_formula_name ||
                                        ' completed successfully.'
                                       );
 
                   EXCEPTION
                   WHEN OTHERS THEN
                      cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                      RAISE g_create_formula_error;
                   END;
 
                   -- Formula did not have rate assignments, so associated rates
                   END IF;
 
                   -- Check for the formula existence
                   END IF;

                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'generate_formula API',
                             p_field          => 'cnc_create_formula_prc',
                             p_field_value    => 'l_formula_x_calc_formula_id : '||l_formula_x_calc_formula_id,
                             p_record_id      => NULL
                            );
                    END IF;

                    BEGIN
                          CN_CALC_FORMULAS_PVT.generate_formula
                            (p_api_version       => 1,
                             p_commit            => FND_API.G_FALSE,
                             p_calc_formula_id   => l_formula_x_calc_formula_id,
                             p_formula_type      => l_formula_type,
                             p_trx_group_code    => l_formula_trx_group_code,
                             p_number_dim        => l_formula_number_dim,
                             p_itd_flag          => l_formula_itd_flag,
                             p_perf_measure_id   => l_formula_perf_measure_id,
                             p_output_exp_id     => l_formula_output_exp_id,
                             p_f_output_exp_id   => NULL,
                             x_formula_status    => l_x_formula_status,
                             x_return_status     => l_x_return_status,
                             x_msg_count         => l_x_msg_count,
                             x_msg_data          => l_x_msg_data
                            );

                          IF l_x_return_status <> 'S' THEN
                             IF (fnd_msg_pub.count_msg <> 0) THEN
                                FOR i IN 1 .. fnd_msg_pub.count_msg
                                LOOP
                                    fnd_msg_pub.get
                                       (p_msg_index          => i,
                                        p_encoded            => fnd_api.g_false,
                                        p_data               => l_x_msg_data,
                                        p_msg_index_out      => l_msg_index_out
                                       );
                                    l_x_error_mesg := SUBSTR (l_x_error_mesg ||
                                                               ' ' ||
                                                              l_msg_index_out ||
                                                              l_x_msg_data,
                                                              1,
                                                              2000
                                                             );
                                END LOOP;
                             END IF;
                             l_x_error_code := 'Error: Generating Formula ' ||
                                                l_formula_name;
                             l_x_error_mesg := SUBSTR (l_x_error_mesg, 1, 2000);
                             cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                               l_x_error_mesg
                                              );
                             RAISE g_gen_formula_error;
                          ELSE
                              cnc_write_log_prc
                                       ('Generation of Formula ' ||
                                        l_formula_name ||
                                        ' succeeded with status: ' ||
                                          l_x_formula_status
                                       );
                              g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                              rec_created_ele.l_name := l_formula_name;
                              rec_created_ele.l_type := L_FORMULA_ELE;
                              g_tbl_created_ele(g_tbl_created_ele_id)
                                                          := rec_created_ele;
                          END IF;
                          EXCEPTION
                          WHEN OTHERS THEN
                               cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                               RAISE g_gen_formula_error;
                          END;
        END LOOP;
        xmldom.freedocument(l_formula_doc);
    EXCEPTION
         WHEN OTHERS THEN
              RAISE;
    END CNC_CREATE_FORMULA_PRC;

  ------------------------------------------------------------------------------
  --Procedure: CNC_CREATE_PLANELE_PRC
  --Procedure to create the plan element with the data in p_planele_xml
  ------------------------------------------------------------------------------
    PROCEDURE CNC_CREATE_PLANELE_PRC(p_planele_xml IN CLOB, p_tag_type IN VARCHAR2) IS
      CURSOR c_credit_types(p_credit_type_id NUMBER) IS
           SELECT DISTINCT CCT.name
             FROM cn_credit_types CCT
            WHERE CCT.credit_type_id = p_credit_type_id;

      CURSOR c_interval_types(p_interval_type_id NUMBER) IS
           SELECT DISTINCT CIT.NAME
             FROM cn_interval_types CIT
            WHERE CIT.interval_type_id = p_interval_type_id;

        l_planele_doc          XMLDOM.DOMDOCUMENT;
        l_revclass_doc         XMLDOM.DOMDOCUMENT;
        l_planele_nodelist     XMLDOM.DOMNODELIST;
        l_revclass_nodelist    XMLDOM.DOMNODELIST;
        l_formula_nodelist     XMLDOM.DOMNODELIST;
        l_planele_node         XMLDOM.DOMNODE;
        l_revclass_node        XMLDOM.DOMNODE;
        l_formula_node         XMLDOM.DOMNODE;

        l_planele_tag          VARCHAR2(100)  := NULL;
        l_revclass_tag         VARCHAR2(100)  := NULL;
        l_formula_tag          VARCHAR2(100)  := NULL;

        l_result               CLOB                                            := NULL;
        l_revenue_class_id     CN_REVENUE_CLASSES.REVENUE_CLASS_ID%TYPE        := NULL;
        l_formula_name         CN_CALC_FORMULAS.NAME%TYPE                      := NULL;
        l_calc_formula_id      CN_CALC_FORMULAS.CALC_FORMULA_ID%TYPE           := NULL;
        l_planele_id           CN_QUOTAS.QUOTA_ID%TYPE                         := NULL;
        rec_plan_element       cn_plan_element_pub.plan_element_rec_type;
        rec_revenue_class      cn_plan_element_pub.revenue_class_rec_type;
        l_tbl_revenue_class    cn_plan_element_pub.revenue_class_rec_tbl_type;
        l_tbl_revenue_class_id NUMBER         := 0;

        l_x_return_status      VARCHAR2(10)                        := 'F';
        l_x_loading_status     VARCHAR2(20)                        := NULL;
        l_x_msg_count          NUMBER                              := 0;
        l_x_msg_data           VARCHAR2(32767)                     := NULL;
        l_msg_index_out        VARCHAR2(2000)                      := NULL;
        l_x_error_mesg         VARCHAR2(2000)                      := NULL;
        l_x_error_code         VARCHAR2(200)                       := NULL;
    BEGIN
  ------------------------------------------------------------------------------
  --   Get the XML formula DOMDocument for the planelement
  ------------------------------------------------------------------------------
        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'In Create PE Prog',
                 p_field          => 'cnc_create_planele_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

        l_planele_doc := cnc_retdomdoc_fnc(p_planele_xml);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'Got PE Doc',
                 p_field          => 'cnc_create_planele_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;

  ------------------------------------------------------------------------------
  --  Check if the call for this procedure came in from the hierarchy
  --  node or other node and initialise the tag appropriately
  ------------------------------------------------------------------------------
        CASE p_tag_type
        WHEN L_DEPENDENT_TAGTYPE THEN
             l_planele_tag     := '/CN_QUOTAS_ALL';
        WHEN L_MAIN_TAGTYPE THEN
             l_planele_tag     := '/XX_OIC_QUOTA_ASSIGN_OBJ/CN_QUOTAS_ALL/XX_OIC_QUOTAS_OBJ';
        ELSE
             cnc_write_log_prc('The plan element tag type is invalid: ' ||
                               p_tag_type
                              );
        END CASE;

        l_revclass_tag         := l_planele_tag || '/CN_QUOTA_RULES_ALL/XX_OIC_QUOTA_RULES_OBJ';
        l_formula_tag          := l_planele_tag || '/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_OBJ';
  ------------------------------------------------------------------------------
  --  Create nodelist to traverse Formula
  ------------------------------------------------------------------------------
        l_planele_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_planele_doc), l_planele_tag);
        FOR l_planele_num IN 0 .. xmldom.getlength (l_planele_nodelist) -1
        LOOP
               l_planele_node      :=  xmldom.item (l_planele_nodelist, l_planele_num);
  ------------------------------------------------------------------------------
  -- Assign the plan element record with the data of Plan element
  ------------------------------------------------------------------------------
               rec_plan_element.name                      := xslprocessor.valueof (l_planele_node, 'NAME');
               rec_plan_element.description               := xslprocessor.valueof (l_planele_node, 'DESCRIPTION');
               rec_plan_element.period_type               := xslprocessor.valueof (l_planele_node, 'PERIOD_TYPE_CODE');
               rec_plan_element.element_type              := xslprocessor.valueof (l_planele_node, 'QUOTA_TYPE_CODE');
               rec_plan_element.target                    := xslprocessor.valueof (l_planele_node, 'TARGET');
               rec_plan_element.incentive_type            := xslprocessor.valueof (l_planele_node, 'INCENTIVE_TYPE_CODE');
               FOR rec_credit_type IN c_credit_types(xslprocessor.valueof (l_planele_node, 'CREDIT_TYPE_ID'))
               LOOP
                   rec_plan_element.credit_type           := rec_credit_type.name;
               END LOOP;
               rec_plan_element.calc_formula_name         := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_planele_doc, l_planele_tag || '/CN_CALC_FORMULAS_ALL/XX_OIC_CALC_FORMULAS_OBJ/NAME');
               rec_plan_element.rt_sched_custom_flag      := xslprocessor.valueof (l_planele_node, 'RT_SCHED_CUSTOM_FLAG');
               rec_plan_element.package_name              := xslprocessor.valueof (l_planele_node, 'PACKAGE_NAME');
               rec_plan_element.performance_goal          := xslprocessor.valueof (l_planele_node, 'PERFORMANCE_GOAL');
               rec_plan_element.payment_amount            := xslprocessor.valueof (l_planele_node, 'PAYMENT_AMOUNT');
               rec_plan_element.start_date                := xslprocessor.valueof (l_planele_node, 'START_DATE');
               rec_plan_element.end_date                  := xslprocessor.valueof (l_planele_node, 'END_DATE');
               rec_plan_element.status                    := xslprocessor.valueof (l_planele_node, 'QUOTA_STATUS');
               FOR rec_interval_type IN c_interval_types(xslprocessor.valueof (l_planele_node, 'INTERVAL_TYPE_ID'))
               LOOP
                   rec_plan_element.interval_name         := rec_interval_type.name;
               END LOOP;
               rec_plan_element.payee_assign_flag         := xslprocessor.valueof (l_planele_node, 'PAYEE_ASSIGN_FLAG');
               rec_plan_element.vesting_flag              := xslprocessor.valueof (l_planele_node, 'VESTING_FLAG');
               rec_plan_element.addup_from_rev_class_flag := xslprocessor.valueof (l_planele_node, 'ADDUP_FROM_REV_CLASS_FLAG');
               rec_plan_element.expense_account_id        := xslprocessor.valueof (l_planele_node, 'EXPENSE_ACCOUNT_ID');
               rec_plan_element.liability_account_id      := xslprocessor.valueof (l_planele_node, 'LIABILITY_ACCOUNT_ID');
               rec_plan_element.quota_group_code          := xslprocessor.valueof (l_planele_node, 'QUOTA_GROUP_CODE');
               rec_plan_element.payment_group_code        := xslprocessor.valueof (l_planele_node, 'PAYMENT_GROUP_CODE');

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Processing Revenue classes',
                         p_field          => 'cnc_create_planele_prc',
                         p_field_value    => NULL,
                         p_record_id      => NULL
                        );
                END IF;
  ------------------------------------------------------------------------------
  -- Get the revenue classes attached to the planelement
  ------------------------------------------------------------------------------
               l_revclass_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_planele_doc), l_revclass_tag);
               FOR l_revclass_num IN 0 .. xmldom.getlength (l_revclass_nodelist) -1
               LOOP
                   l_revclass_node      :=  xmldom.item (l_revclass_nodelist, l_revclass_num);
                   l_result             :=  'a';

                   xmlDOM.writetoclob(l_revclass_node,l_result);
                   l_revclass_doc       := cnc_retdomdoc_fnc(l_result);
  ------------------------------------------------------------------------------
  --  Assign the revenue class record with the data of Plan element
  --  record assignments
  ------------------------------------------------------------------------------
                   rec_revenue_class.rev_class_name  := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_revclass_doc, '/XX_OIC_QUOTA_RULES_OBJ/CN_REVENUE_CLASSES_ALL/XX_OIC_REVENUE_CLASSES_OBJ/NAME');
                   BEGIN
                        SELECT CRSA.revenue_class_id
                          INTO l_revenue_class_id
                          FROM cn_revenue_classes_all CRSA
                         WHERE CRSA.NAME = rec_revenue_class.rev_class_name;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                        l_revenue_class_id := 0;
                   WHEN others THEN
                        cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                        RAISE;
                   END;

                   IF l_revenue_class_id = 0 THEN
                       cnc_write_log_prc('The Revenue Class is Missing.' ||
                                         ' Please setup the revenue class: ' ||
                                         rec_revenue_class.rev_class_name);
                   ELSE
                       rec_revenue_class.rev_class_target             := xslprocessor.valueof (l_revclass_node,'TARGET');
                       rec_revenue_class.rev_class_payment_amount     := xslprocessor.valueof (l_revclass_node,'PAYMENT_AMOUNT');
                       rec_revenue_class.rev_class_performance_goal   := xslprocessor.valueof (l_revclass_node,'PERFORMANCE_GOAL');
                       rec_revenue_class.description                  := XX_OIC_XPATH_PKG.cnc_extract_fnc(l_revclass_doc, '/XX_OIC_QUOTA_RULES_OBJ/CN_REVENUE_CLASSES_ALL/XX_OIC_REVENUE_CLASSES_OBJ/DESCRIPTION');
                       l_tbl_revenue_class_id                         := l_tbl_revenue_class_id + 1;
                       l_tbl_revenue_class(l_tbl_revenue_class_id)    := rec_revenue_class;
                   END IF;
               END LOOP;

                -- Write additional debug messages
                IF g_debug_flag = 'Y' THEN
                   XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                        (p_error_message  => 'Processing formulas',
                         p_field          => 'cnc_create_planele_prc',
                         p_field_value    => NULL,
                         p_record_id      => NULL
                        );
                END IF;
  ------------------------------------------------------------------------------
  --  Find the formula associated with the Plan Element
  ------------------------------------------------------------------------------
              l_formula_nodelist := xslprocessor.selectnodes (xmldom.makenode(l_planele_doc), l_formula_tag);
              FOR l_formula_num IN 0 .. xmldom.getlength (l_formula_nodelist) -1
              LOOP
                  l_formula_node      :=  xmldom.item (l_formula_nodelist, l_formula_num);
                  l_result            :=  'a';

                  xmlDOM.writetoclob(l_formula_node,l_result);
  ------------------------------------------------------------------------------
  --  Check if the formula exists. If not then call the procedure
  --  CNC_CREATE_FORMULA_PRC to create the formula
  ------------------------------------------------------------------------------
                  l_formula_name      := xslprocessor.valueof (l_formula_node,'NAME');
                  l_calc_formula_id := 0;
                  BEGIN
                       SELECT  CCFA.calc_formula_id
                         INTO  l_calc_formula_id
                         FROM  cn_calc_formulas_all CCFA
                        WHERE  CCFA.NAME   = l_formula_name
                          AND  CCFA.org_id = FND_PROFILE.VALUE('ORG_ID');
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       l_calc_formula_id := 0;
                  WHEN others THEN
                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                       RAISE;
                  END;

                  IF l_calc_formula_id = 0 THEN
 
                     cnc_create_formula_prc(l_result,L_MAIN_TAGTYPE);
                  ELSE
                      IF NOT cn_created_ele_fnc(l_formula_name,
                                                L_FORMULA_ELE
                                               ) THEN
                           cnc_write_log_prc
                             ('Warning: The Formula: ' ||
                              l_formula_name || ' exists.'
                             );
                           cnc_create_formula_prc(l_result,L_MAIN_TAGTYPE);
                      END IF;
                  END IF;
              END LOOP; -- formula
  ------------------------------------------------------------------------------
  --  CALL CREATE PLAN ELEMENT API
  ------------------------------------------------------------------------------
              BEGIN
                   SELECT CQA.quota_id
                     INTO l_planele_id
                     FROM cn_quotas_all CQA
                    WHERE CQA.NAME        = rec_plan_element.NAME
                      AND CQA.delete_flag = 'N'
                      AND CQA.org_id      = FND_PROFILE.VALUE('ORG_ID');
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   l_planele_id := 0;
              WHEN OTHERS THEN
                   cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                   RAISE;
              END;

              IF l_planele_id = 0 THEN
                    -- Write additional debug messages
                    IF g_debug_flag = 'Y' THEN
                       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                            (p_error_message  => 'Call create_plan_element API',
                             p_field          => 'cnc_create_planele_prc',
                             p_field_value    => NULL,
                             p_record_id      => NULL
                            );
                    END IF;
                  BEGIN
                       cn_plan_element_pub.create_plan_element
                                   (p_api_version            => 1,
                                    p_commit                 => FND_API.G_FALSE,
                                    x_return_status          => l_x_return_status,
                                    x_msg_count              => l_x_msg_count,
                                    x_msg_data               => l_x_msg_data,
                                    p_plan_element_rec       => rec_plan_element,
                                    p_revenue_class_rec_tbl  => l_tbl_revenue_class,
                                    x_loading_status         => l_x_loading_status
                                   );

                       IF l_x_return_status <> 'S' THEN
                          IF (fnd_msg_pub.count_msg <> 0) THEN
                             FOR i IN 1 .. fnd_msg_pub.count_msg
                             LOOP
                                 fnd_msg_pub.get
                                         (p_msg_index          => i,
                                          p_encoded            => FND_API.G_FALSE,
                                          p_data               => l_x_msg_data,
                                          p_msg_index_out      => l_msg_index_out
                                         );
                                 l_x_error_mesg := SUBSTR (l_x_error_mesg || ' ' ||
                                                           l_msg_index_out || l_x_msg_data
                                                           , 1, 2000
                                                          );
                             END LOOP;
                          END IF;

                          l_x_error_code := 'Error: Create Plan Element ' ||
                                             rec_plan_element.name;
                          l_x_error_mesg :=  SUBSTR (l_x_error_mesg, 1,2000);
                          cnc_write_log_prc(l_x_error_code || CHR(10) ||
                                            l_x_error_mesg
                                           );
                          RAISE g_create_planele_error;
                       ELSE
                          cnc_write_log_prc('Creation of Plan Element ' ||
                                            rec_plan_element.NAME ||
                                            ' succeeded with loading status: '||
                                            l_x_loading_status
                                           );
                          g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                          rec_created_ele.l_name := rec_plan_element.NAME;
                          rec_created_ele.l_type := L_PLANELE_ELE;
                          g_tbl_created_ele(g_tbl_created_ele_id)
                                                      := rec_created_ele;
                       END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                       cnc_write_log_prc(SUBSTR(SQLERRM,1,2000));
                       RAISE g_create_planele_error;
                  END;
              ELSE
                  g_tbl_created_ele_id   := g_tbl_created_ele_id + 1;
                  rec_created_ele.l_name := rec_plan_element.NAME;
                  rec_created_ele.l_type := L_PLANELE_ELE;
                  g_tbl_created_ele(g_tbl_created_ele_id) := rec_created_ele;
              END IF;

            -- Write additional debug messages
            IF g_debug_flag = 'Y' THEN
               XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                    (p_error_message  => 'End create_plan_element API',
                     p_field          => 'cnc_create_planele_prc',
                     p_field_value    => NULL,
                     p_record_id      => NULL
                    );
            END IF;

        END LOOP;
        xmlDOM.freedocument(l_planele_doc);

        -- Write additional debug messages
        IF g_debug_flag = 'Y' THEN
           XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
                (p_error_message  => 'End PE Program',
                 p_field          => 'cnc_create_planele_prc',
                 p_field_value    => NULL,
                 p_record_id      => NULL
                );
        END IF;
    EXCEPTION
         WHEN OTHERS THEN
              RAISE;
    END CNC_CREATE_PLANELE_PRC;

   -----------------------------------------------------------------------------
   -- Procedure     : cnc_parse_sql_prc
   --
   -- Description   : This procedure parses the SQL_SELECT column for a given
   --                 expression. Any references to plan elements are stored in
   --                 the plsql table p_tbl_planele and references to formulas
   --                 are stored in plsql table p_tbl_formula
   -----------------------------------------------------------------------------
  PROCEDURE cnc_parse_sql_prc(p_sql_select  IN  VARCHAR2,
                              p_tbl_formula OUT g_tbl_type_formula,
                              p_tbl_planele OUT g_tbl_type_planele
                             ) IS

     l_sql                 VARCHAR2(1000) := NULL;
     l_indx1               NUMBER         := 0;
     l_indx2               NUMBER         := 0;
     l_indx3               NUMBER         := 0;
     l_len                 NUMBER         := 0;
     l_formula             VARCHAR2(100)  := NULL;
     l_planele             VARCHAR2(100)  := NULL;
     l_endsrch             BOOLEAN        := FALSE;
     l_formula_tbl_id      NUMBER         := 0;
     l_planele_tbl_id      NUMBER         := 0;
  BEGIN

    -- Write additional debug messages
    IF g_debug_flag = 'Y' THEN
       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
            (p_error_message  => 'Begin Parse',
             p_field          => 'cnc_parse_sql_prc',
             p_field_value    => NULL,
             p_record_id      => NULL
            );
    END IF;

     l_sql := p_sql_select;
     WHILE NOT l_endsrch
     LOOP
         l_formula := NULL;
         l_indx1 := INSTR(l_sql,'cn_formula_');
         IF l_indx1 IS NULL OR l_indx1 = 0 THEN
            l_endsrch := TRUE;
         ELSE
            l_indx2 := INSTR(l_sql,'get_result(p_commission_line_id)');
            l_indx2 := l_indx2 + 32;
            l_formula := SUBSTR(l_sql,l_indx1,l_indx2-l_indx1);
            l_sql := REPLACE(l_sql,l_formula,'');
            l_formula_tbl_id                := l_formula_tbl_id + 1;
            p_tbl_formula(l_formula_tbl_id) := l_formula;
         END IF;
     END LOOP;

     l_sql := p_sql_select;
     l_endsrch := FALSE;
     WHILE NOT l_endsrch
     LOOP
         l_planele := NULL;
         l_len     := LENGTH(l_sql);
         l_indx1   := INSTR(l_sql,'PE.');
         IF l_indx1 IS NULL OR l_indx1 = 0 THEN
            l_endsrch := TRUE;
         ELSE
            l_indx2   := INSTR(l_sql,'(',-(l_len-l_indx1));
            l_indx3   := INSTR(l_sql,')',l_indx1);
            l_indx3   := (l_indx3 + 1) - l_indx2;
            l_planele := SUBSTR(l_sql,l_indx2,l_indx3);
            l_planele := SUBSTR(l_planele,2,INSTR(l_planele,'PE.'));
            l_sql     := REPLACE(l_sql,l_planele,'');
            l_planele_tbl_id                  := l_planele_tbl_id + 1;
            p_tbl_planele(l_planele_tbl_id)   := l_planele;
         END IF;
     END LOOP;

    -- Write additional debug messages
    IF g_debug_flag = 'Y' THEN
       XX_OIC_ERRORS_PKG.cnc_insert_line_record_prc
            (p_error_message  => 'End Parse',
             p_field          => 'cnc_parse_sql_prc',
             p_field_value    => NULL,
             p_record_id      => NULL
            );
    END IF;

  EXCEPTION
  WHEN OTHERS THEN
      cnc_write_log_prc('Error Parsing Expression: '||SUBSTR(SQLERRM,1,2000));
      RAISE g_sql_parse_error;
  END cnc_parse_sql_prc;

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

END XX_OIC_PLANRATE_IMP_PKG;
/
