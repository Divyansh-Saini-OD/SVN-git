SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

   -- +===================================================================+
   -- |               Office Depot - Project Simplify                     |
   -- |             Oracle NAIO Consulting Organization                   |
   -- +===================================================================+
   -- | Name        : XX_OIC_PLANCOPY_V                                   |
   -- | Description : View to copy Compensation plan details data         |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date       Version     Description                                 |
   -- |=======    ==========  =============                               |
   -- |01-Aug-07   1.0        This view is used by OIC_PLAN_COPY object   |
   -- +===================================================================+

  CREATE OR REPLACE VIEW APPS.XX_OIC_PLANCOPY_V OF XX_OIC_COMP_PLANS_OBJ
  WITH OBJECT IDENTIFIER (COMP_PLAN_ID,ORG_ID) AS 
  SELECT CCPA.comp_plan_id,
          CCPA.name,
          CCPA.version,
          CCPA.description,
          CCPA.start_period_id,
          CCPA.end_period_id,
          CCPA.status_code,
          CCPA.complete_flag,
          CCPA.on_quota_date,
          CCPA.allow_rev_class_overlap,
          CCPA.org_id,
          CCPA.start_date,
          CCPA.end_date,
          CCPA.object_version_number,
          CCPA.security_group_id,
          CAST (MULTISET(
          SELECT CQAA.quota_assign_id,
                 CQAA.quota_id,
                 CQAA.comp_plan_id,
             CQAA.org_id,
                 CQAA.weight,
                 CQAA.object_version_number,
                 CQAA.quota_sequence,
                 CQAA.security_group_id,
                 CAST(MULTISET(
                 SELECT   CQA.quota_id,
                          CQA.name,
                          CQA.rate_schedule_id,
                          CQA.quota_type_code,
                          CQA.target,
                          CQA.description,
                          CQA.period_type_code,
                          CQA.usage_code,
                          CQA.payment_type_code,
                          CQA.payment_amount,
                          CQA.trx_group_code,
                          CQA.cumulative_flag,
                          CQA.quota_unspecified,
                          CQA.start_period_id,
                          CQA.end_period_id,
                          CQA.start_num,
                          CQA.end_num,
                          CQA.org_id,
                          CQA.disc_rate_schedule_id,
                          CQA.discount_option_code,
                          CQA.itd_flag,
                          CQA.split_flag,
                          CQA.incremental_type,
                          CQA.start_date,
                          CQA.end_date,
                          CQA.incentive_type_code,
                          CQA.credit_type_id,
                          CQA.bonus_credit_type_id,
                          CQA.interval_type_id,
                          CQA.calc_formula_id,
                          CQA.rt_sched_custom_flag,
                          CQA.payee_assign_flag,
                          CQA.vesting_flag,
                          CQA.performance_goal,
                          CQA.quota_status,
                          CQA.package_name,
                          CQA.addup_from_rev_class_flag,
                          CQA.liability_account_id,
                          CQA.expense_account_id,
                          CQA.quota_group_code,
                          CQA.object_version_number,
                          CQA.security_group_id,
                          CQA.delete_flag,
                          CQA.payment_group_code,
                          CAST (MULTISET (
                                SELECT   CCFA.org_id,
                                         CCFA.calc_formula_id,
                                         CCFA.name,
                                         CCFA.description,
                                         CCFA.comment_long,
                                         CCFA.formula_status,
                                         CCFA.output_disp,
                                         CCFA.output_sql_select,
                                         CCFA.output_sql_from,
                                         CCFA.output_status,
                                         CCFA.split_flag,
                                         CCFA.cumulative_flag,
                                         CCFA.itd_flag,
                                         CCFA.trx_group_code,
                                         CCFA.perf_measure_id,
                                         CCFA.threshold_all_tier_flag,
                                         CCFA.threshold_first_tier_flag,
                                         CCFA.number_dim,
                                         CCFA.formula_type,
                                         CCFA.thresholds,
                                         CCFA.input_disp,
                                         CCFA.input_sql_select,
                                         CCFA.input_sql_from,
                                         CCFA.input_status,
                                         CCFA.piped_output_select,
                                         CCFA.piped_output_from,
                                         CCFA.piped_output_disp,
                                         CCFA.piped_output_sql,
                                         CCFA.output_exp_id,
                                         CCFA.f_output_exp_id,
                                         CCFA.object_version_number,
                                         CCFA.modeling_flag,
                                         CCFA.security_group_id,
                                         CAST(MULTISET(
                               SELECT  CCSEA.org_id,
                                     CCSEA.calc_sql_exp_id,
                                     CCSEA.name,
                                     CCSEA.description,
                                     CCSEA.status,
                                     CCSEA.exp_type_code,
                                     CCSEA.expression_disp,
                                     CCSEA.sql_select,
                                     CCSEA.sql_from,
                                     CCSEA.piped_sql_select,
                                     CCSEA.piped_sql_from,
                                     CCSEA.piped_expression_disp,
                                     CCSEA.object_version_number,
                                     CCSEA.security_group_id
                                 FROM   cn_calc_sql_exps_all CCSEA
                                WHERE CCSEA.calc_sql_exp_id  (+)=  CCFA.output_exp_id
                                  AND CCSEA.org_id           (+)=  CCFA.org_id
                                   ) AS XX_OIC_CALC_EXPRESSIONS_LIST
                                   ) AS CN_OUT_SQL_EXPS_ALL,
                               CAST(MULTISET(
                               SELECT   CFIA.org_id,
                                     CFIA.formula_input_id,
                                     CFIA.calc_formula_id,
                                     CFIA.rate_dim_sequence,
                                     CFIA.input_disp,
                                     CFIA.input_sql_select,
                                     CFIA.input_sql_from,
                                     CFIA.input_status,
                                     CFIA.input_sequence,
                                     CFIA.name,
                                     CFIA.description,
                                     CFIA.piped_input_select,
                                     CFIA.piped_input_from,
                                     CFIA.piped_input_disp,
                                     CFIA.calc_sql_exp_id,
                                     CFIA.f_calc_sql_exp_id,
                                     CFIA.object_version_number,
                                     CFIA.security_group_id,
                                     CFIA.cumulative_flag,
                                     CFIA.split_flag,
                                     CAST(MULTISET(
                                     SELECT  CCSEA.org_id,
                                           CCSEA.calc_sql_exp_id,
                                           CCSEA.name,
                                           CCSEA.description,
                                           CCSEA.status,
                                           CCSEA.exp_type_code,
                                           CCSEA.expression_disp,
                                           CCSEA.sql_select,
                                           CCSEA.sql_from,
                                           CCSEA.piped_sql_select,
                                           CCSEA.PIPED_SQL_FROM,
                                           CCSEA.piped_expression_disp,
                                           CCSEA.object_version_number,
                                           CCSEA.security_group_id
                                       FROM  cn_calc_sql_exps_all  CCSEA
                                      WHERE  CCSEA.calc_sql_exp_id (+)= CFIA.calc_sql_exp_id
                                        AND  CCSEA.org_id          (+)= CFIA.org_id
                                                  ) AS XX_OIC_CALC_EXPRESSIONS_LIST
                                         ) AS CN_INPUT_SQL_EXPS_ALL,
                                     CAST(MULTISET(
                                     SELECT  CCSEA.org_id,
                                           CCSEA.calc_sql_exp_id,
                                           CCSEA.name,
                                           CCSEA.description,
                                           CCSEA.status,
                                           CCSEA.exp_type_code,
                                           CCSEA.expression_disp,
                                           CCSEA.sql_select,
                                           CCSEA.sql_from,
                                           CCSEA.piped_sql_select,
                                           CCSEA.piped_sql_from,
                                           CCSEA.piped_expression_disp,
                                           CCSEA.object_version_number,
                                           CCSEA.security_group_id
                                       FROM  cn_calc_sql_exps_all  CCSEA
                                      WHERE  CCSEA.calc_sql_exp_id (+)= CFIA.f_calc_sql_exp_id
                                        AND  CCSEA.org_id          (+)= CFIA.org_id
                                                  ) AS XX_OIC_CALC_EXPRESSIONS_LIST
                                         ) AS CN_FORECAST_INPUT_EXPS_ALL
                                 FROM  cn_formula_inputs_all CFIA
                                         WHERE  CFIA.calc_formula_id (+)= CCFA.calc_formula_id
                                 AND  CFIA.org_id          (+)= CCFA.org_id) AS XX_OIC_FORMULA_INPUTS_LIST
                                          ) AS CN_FORMULA_INPUTS_ALL,
                                         CAST(MULTISET(
                               SELECT  CCSEA.org_id,
                                     CCSEA.calc_sql_exp_id,
                                     CCSEA.name,
                                     CCSEA.description,
                                     CCSEA.status,
                                     CCSEA.exp_type_code,
                                     CCSEA.expression_disp,
                                     CCSEA.sql_select,
                                     CCSEA.sql_from,
                                     CCSEA.piped_sql_select,
                                     CCSEA.piped_sql_from,
                                     CCSEA.piped_expression_disp,
                                     CCSEA.object_version_number,
                                     CCSEA.security_group_id
                                 FROM   cn_calc_sql_exps_all CCSEA
                                WHERE CCSEA.calc_sql_exp_id  (+)=  CCFA.perf_measure_id
                                  AND CCSEA.org_id           (+)=  CCFA.org_id
                                   ) AS XX_OIC_CALC_EXPRESSIONS_LIST
                                   ) AS CN_PERF_MEASURES_ALL,
                                         CAST(MULTISET(
                                         SELECT  CRFAA.org_id,
                                     CRFAA.rt_formula_asgn_id,
                                     CRFAA.calc_formula_id,
                                     CRFAA.start_date,
                                     CRFAA.end_date,
                                     CRFAA.rate_schedule_id,
                                     CRFAA.object_version_number,
                                     CRFAA.security_group_id,
                                     CAST(MULTISET(
                                     SELECT  CRSA.rate_schedule_id,
                                           CRSA.name,
                                           CRSA.tier_unit_code,
                                           CRSA.commission_unit_code,
                                           CRSA.status_code,
                                           CRSA.org_id,
                                           CRSA.number_dim,
                                           CRSA.object_version_number,
                                           CRSA.security_group_id,
                                           CAST(MULTISET(
                                           SELECT  CRSDA.org_id,
                                                 CRSDA.rate_sch_dim_id,
                                                 CRSDA.rate_dimension_id,
                                                 CRSDA.rate_schedule_id,
                                                 CRSDA.rate_dim_sequence,
                                                 CRSDA.object_version_number,
                                                 CRSDA.security_group_id,
                                                 CAST(MULTISET(
                                                 SELECT  CRDA.org_id,
                                                       CRDA.rate_dimension_id,
                                                       CRDA.name,
                                                       CRDA.description,
                                                       CRDA.dim_unit_code,
                                                       CRDA.number_tier,
                                                       CRDA.object_version_number,
                                                       CRDA.security_group_id,
                                                       CAST(MULTISET(
                                                        SELECT CRDTA.org_id,
                                                             CRDTA.rate_dim_tier_id,
                                                             CRDTA.rate_dimension_id,
                                                             CRDTA.dim_unit_code,
                                                             CRDTA.minimum_amount,
                                                             CRDTA.maximum_amount,
                                                             CRDTA.tier_sequence,
                                                             CRDTA.string_value,
                                                             CRDTA.min_exp_id,
                                                             CRDTA.max_exp_id,
                                                             CRDTA.object_version_number,
                                                             CRDTA.security_group_id
                                                          FROM cn_rate_dim_tiers_all CRDTA
                                                                           WHERE CRDTA.rate_dimension_id (+)= CRDA.rate_dimension_id
                                                                             AND CRDTA.org_id            (+)= CRDA.org_id
                                                                  ) AS XX_OIC_RATE_DIM_TIERS_LIST
                                                          ) AS CN_RATE_DIM_TIERS_ALL
                                                   FROM cn_rate_dimensions_all CRDA
                                                  WHERE CRDA.rate_dimension_id (+)= CRSDA.rate_dimension_id
                                                    AND CRDA.org_id            (+)= CRSDA.org_id
                                                              ) AS XX_OIC_RATE_DIMENSIONS_LIST
                                                     ) AS CN_RATE_DIMENSIONS_ALL
                                             FROM CN_RATE_SCH_DIMS_ALL CRSDA
                                            WHERE CRSDA.rate_schedule_id (+)= CRSA.rate_schedule_id
                                              AND CRSDA.org_id           (+)= CRSA.org_id
                                                        ) AS XX_OIC_RATE_SCH_DIMS_LIST
                                              ) AS CN_RATE_SCH_DIMS_ALL,
                                           CAST(MULTISET(
                                                        SELECT  CRTA.rate_tier_id,
                                                  CRTA.rate_schedule_id,
                                                 CRTA.minimum_percent,
                                                 CRTA.maximum_percent,
                                                 CRTA.commission_rate,
                                                 CRTA.commission_amount,
                                                 CRTA.minimum_amount,
                                                 CRTA.maximum_amount,
                                                 CRTA.sequence_number,
                                                 CRTA.org_id,
                                                 CRTA.rate_sequence,
                                                 CRTA.object_version_number,
                                                 CRTA.security_group_id
                                            FROM  cn_rate_tiers_all CRTA
                                            WHERE  CRTA.rate_schedule_id (+)= CRSA.rate_schedule_id
                                             AND  CRTA.org_id           (+)= CRSA.org_id
                                                       ) AS XX_OIC_RATE_TIERS_LIST
                                              ) AS CN_RATE_TIERS_ALL
                                       FROM  cn_rate_schedules_all CRSA
                                                  WHERE CRSA.rate_schedule_id (+)= CRFAA.rate_schedule_id
                                                    AND CRSA.org_id           (+)= CRFAA.org_id
                                                               ) AS XX_OIC_RATE_SCHEDULES_LIST
                                                      ) AS CN_RATE_SCHEDULES_ALL
                                           FROM cn_rt_formula_asgns_all CRFAA
                                          WHERE CRFAA.calc_formula_id (+)= CCFA.calc_formula_id
                                            AND CRFAA.org_id          (+)= CCFA.org_id
                                                      ) AS XX_OIC_RT_FORMULA_ASGN_LIST
                                             )AS CN_RT_FORMULA_ASGNS_ALL
                                  FROM  cn_calc_formulas_all CCFA
                                 WHERE  CCFA.calc_formula_id (+)= CQA.calc_formula_id
                                   AND  CCFA.org_id          (+)= CQA.org_id) AS XX_OIC_CALC_FORMULAS_LIST
                                          ) AS CN_CALC_FORMULAS_ALL,
                         CAST(MULTISET(
                         SELECT  CQRA.quota_rule_id,
                         CQRA.name,
                         CQRA.revenue_class_id,
                         CQRA.quota_id,
                         CQRA.target,
                         CQRA.description,
                         CQRA.payment_factor,
                         CQRA.quota_factor,
                         CQRA.org_id,
                         CQRA.payment_amount,
                         CQRA.performance_goal,
                         CQRA.object_version_number,
                         CQRA.security_group_id,
                         CAST(MULTISET(
                         SELECT CRCA.revenue_class_id,
                               CRCA.NAME,
                               CRCA.repository_id,
                               CRCA.description,
                               CRCA.org_id,
                               CRCA.liability_account_id,
                               CRCA.expense_account_id,
                               CRCA.object_version_number,
                               CRCA.security_group_id
                           FROM  cn_revenue_classes_all CRCA
                          WHERE CRCA.revenue_class_id (+)= CQRA.revenue_class_id
                            AND CRCA.org_id           (+)= CQRA.org_id
                                      ) AS XX_OIC_REVENUE_CLASSES_LIST
                             ) AS CN_REVENUE_CLASSES_ALL,
                          CAST(MULTISET(
                          SELECT CQRUA.org_id,
                              CQRUA.quota_rule_uplift_id,
                              CQRUA.quota_rule_id,
                              CQRUA.start_date,
                              CQRUA.end_date,
                              CQRUA.payment_factor,
                              CQRUA.quota_factor,
                              CQRUA.object_version_number,
                              CQRUA.security_group_id
                            FROM cn_quota_rule_uplifts_all CQRUA
                           WHERE CQRUA.quota_rule_id (+)= CQRA.quota_rule_id
                             AND CQRUA.org_id        (+)= CQRA.org_id
                                       ) AS XX_OIC_RULE_UPLIFTS_LIST
                               ) AS CN_QUOTA_RULE_UPLIFTS_ALL
                           FROM  cn_quota_rules_all CQRA
                          WHERE CQRA.quota_id (+)= CQA.quota_id
                            AND CQRA.org_id   (+)= CQA.org_id
                                      ) AS XX_OIC_QUOTA_RULES_LIST
                             ) AS CN_QUOTA_RULES_ALL
                   FROM  CN_QUOTAS_ALL CQA
                  WHERE  CQA.quota_id  (+)= CQAA.quota_id
                AND  CQA.org_id    (+)= CQAA.org_id) AS XX_OIC_QUOTAS_LIST
                 ) AS CN_QUOTAS_ALL
           FROM CN_QUOTA_ASSIGNS_ALL CQAA
          WHERE CQAA.comp_plan_id (+)= CCPA.comp_plan_id
          AND CQAA.org_id       (+)= CCPA.org_id
          ORDER BY CQAA.quota_sequence ASC) AS XX_OIC_QUOTA_ASSIGN_LIST
                       ) AS CN_QUOTA_ASSIGNS_ALL
     FROM cn_comp_plans_all CCPA
/