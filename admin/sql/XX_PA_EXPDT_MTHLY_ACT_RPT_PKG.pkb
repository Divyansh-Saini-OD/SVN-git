create or replace
PACKAGE BODY XX_PA_EXPDT_MTHLY_ACT_RPT_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_EXPDT_MTHLY_ACT_RPT_PKG                                                      |
-- |  Description:  OD: PA Expenditures Monthly Activity Report                                 |
-- |                CR631/731 - R1170                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         22-Jan-2010  Joe Klein        Initial version                                  |
-- | 1.1         06-May-2010  Joe Klein        Defect 5649 - Changed where clause for CIP       |
-- |                                           General task type.                               |
-- | 1.1         06-May-2010  Joe Klein        Defect 5681 - Added raw_cost column to query     |
-- | 1.2         30-jan-2013  Divya            Defect#14693                                     |
-- | 1.3         10-May-2013  Shruthi          Modified for R12 Upgrade retrofit                |
-- | 1.4         10-May-2013  Shruthi          Modified for R12 Upgrade retrofit                |
-- | 1.5         29-Nov-2013  Sravanthi        Modifies Query for Defevt#26589 as part of R12   |
-- |                                           Upgrade                                          |
-- | 1.6         24-Jun-2014  Kirna            Removed raw_cost column and amount column as part|
-- |                                           defect 30419                                     |
-- | 1.7         17-Nov-2015  Harvinder Rakhra Retrofit R12.2                                   |
-- +============================================================================================+

   -- +============================================================================================+
-- |  Name: XX_PA_EXPDT_MTHLY_ACT_RPT_PKG.XX_MAIN_RPT                                           |
-- |  Description: This pkg.procedure will extract project data that originated in AP for a     |
-- |  particular PA period range and write it to the concurrent program's output.               |
-- =============================================================================================|
   PROCEDURE xx_main_rpt
   (
      errbuff                    OUT NOCOPY VARCHAR2
     ,retcode                    OUT NOCOPY NUMBER
     ,p_period_from              IN       VARCHAR2 DEFAULT NULL
     ,p_period_to                IN       VARCHAR2 DEFAULT NULL
     ,p_capital_task             IN       VARCHAR2 DEFAULT 'Y'
     ,p_service_type             IN       VARCHAR2 DEFAULT NULL     --Added as per Defect# 14693
     ,p_vendor                   IN       VARCHAR2 DEFAULT NULL     --Added as per Defect# 14693
     ,p_project_num_from         IN       VARCHAR2 DEFAULT NULL     --Added as per Defect# 14693
     --p_task_type IN VARCHAR2 DEFAULT NULL,                        --Commented as per Defect# 14693
     ,p_project_num_to           IN       VARCHAR2 DEFAULT NULL
     ,p_company                  IN       VARCHAR2 DEFAULT NULL
   )
   IS
      v_out_header                  VARCHAR2 (1000);
      v_log_msg                     VARCHAR2 (100);
      v_profile_value               VARCHAR2 (100);
      v_period_num_from             gl_period_statuses.effective_period_num%TYPE;
      v_period_num_to               gl_period_statuses.effective_period_num%TYPE;
      i                             NUMBER;

      CURSOR c_out
      IS
         SELECT a.project_number
               ,a.expenditure_item_id
                /*Start modification by Adithya for Defect#14693*/
                 --a.latest_gl_period_name,
               ,SUBSTR (a.latest_gl_period_name ,0,4) || glp.period_year latest_gl_period_name
               ,glp.period_num
               ,glp.period_year
               ,glp.quarter_num
               /*End modification by Adithya for Defect#14693*/
               ,a.capitalizable_flag
               ,a.expenditure_organization_name
               ,a.expenditure_type
               ,a.task_number
               ,b.vendor_name
               ,a.employee_name
               ,a.quantity
               /* Added as amount part of defect 30419*/
               ,c.amount 
               ,a.expenditure_item_date
               ,d.segment1
               ,d.segment2
               ,d.segment3
               ,d.segment4
               ,d.segment5
               ,d.segment6
               ,d.segment7
               ,xx_pa_month_end_bals_rpt_pkg.xx_prj_tsk_minor (c.project_id,c.task_id) minor
           FROM gl_periods glp,
	         pa_expend_items_adjust2_v a
                JOIN pa_cost_distribution_lines_all c
                  ON c.expenditure_item_id = a.expenditure_item_id
		 -- Added By Sravanthi on 11/29/2013 for defect# 26589
                JOIN pa_expenditures_all EI
                  ON a.expenditure_id = ei.expenditure_id
		--- Comment ends
                JOIN gl_code_combinations d
                  ON d.code_combination_id = c.dr_code_combination_id
                /*Start modification by Adithya for Defect#14693*/
                JOIN pa_tasks t
                  ON t.task_id = c.task_id
                /*End modification by Adithya for Defect#14693*/
                /*Start modification by Shruthi for R12 Upgrade retrofit */
              --  LEFT JOIN po_vendors b ON b.vendor_id = a.vendor_id
             ---   LEFT JOIN ap_suppliers b ON b.vendor_id = a.vendor_id   ---- commented By Sravanthi on 11/29/2013 for defect# 26589
	          LEFT JOIN ap_suppliers b ON b.vendor_id = ei.vendor_id   ---- added By Sravanthi on 11/29/2013 for defect# 26589
                /*End modification by Shruthi */
          WHERE a.latest_gl_period_name IN ( SELECT DISTINCT period_name
                                                        FROM gl_period_statuses
                                                       WHERE effective_period_num
                                                     BETWEEN v_period_num_from
                                                         AND v_period_num_to)
            AND a.latest_gl_period_name = glp.period_name
            AND a.capitalizable_flag = 'Y'
            /*commented below code as per Defect#14693*/
            /*AND (  (p_task_type = 'Marketing'          AND (a.task_number LIKE '80.%' OR a.task_number LIKE '%.MKT.%'))
                   OR
                   (p_task_type = 'Tenant Allowance'   AND (a.task_number LIKE '81.%.ST%' OR a.task_number LIKE '81.%.LT%'))
                   OR
                   (p_task_type = 'Lease Acquisitions' AND (a.task_number = '02.LEG'))
                   OR
                   (p_task_type = 'CIP General'        AND (  (a.task_number LIKE '02.%' AND a.task_number <> '02.LEG')
                                                              OR
                                                              (a.task_number LIKE '81.%' AND a.task_number NOT LIKE '81.%.ST%' AND a.task_number NOT LIKE '81.%.LT%' AND a.task_number NOT LIKE '%.MKT.%')
                                                           ))
                   OR
                   (p_task_type IS NULL)
                )*/
                /*Added below code as per Defect#14693*/
            AND (   (    p_service_type IS NOT NULL
                     AND p_service_type = t.service_type_code
                    )
                 OR (p_service_type IS NULL)
                 OR (p_service_type = 'ALL')
                )
            AND (   (    p_vendor IS NOT NULL
                     AND p_vendor = 'Y'
                     AND b.vendor_name IS NULL
                    )
                 OR (    p_vendor IS NOT NULL
                     AND p_vendor = 'N'
                     AND b.vendor_name IS NOT NULL
                    )
                 OR (p_vendor IS NULL)
                )
            /*Added above code as per Defect#14693*/
            AND (   (    p_project_num_from IS NOT NULL
                     AND p_project_num_to IS NOT NULL
                     AND a.project_number BETWEEN p_project_num_from
                                              AND p_project_num_to
                    )
                 OR (    p_project_num_from IS NOT NULL
                     AND p_project_num_to IS NULL
                     AND a.project_number >= p_project_num_from
                    )
                 OR (    p_project_num_from IS NULL
                     AND p_project_num_to IS NOT NULL
                     AND a.project_number <= p_project_num_to
                    )
                 OR (    p_project_num_from IS NULL
                     AND p_project_num_to IS NULL
                    )
                )
            AND (   (    p_company IS NOT NULL
                     AND d.segment1 = p_company)
                 OR (p_company IS NULL)
                )
            AND a.org_id = v_profile_value
            /*Added below code as per Defect#14693*/
            AND (   (    p_capital_task = 'Y'
                     AND NVL (t.billable_flag, 'N') = p_capital_task
                    )
                 OR (    p_capital_task = 'N'
                     AND NVL (t.billable_flag, 'N') = p_capital_task
                    )
                )
--Start modification by Adithya for defect#14693
         UNION ALL
         SELECT a.project_number
               ,a.expenditure_item_id
               /*Start modification by Adithya for Defect#14693*/
                    --a.latest_gl_period_name,
                ,SUBSTR (a.latest_gl_period_name ,0,4)|| glp.period_year latest_gl_period_name
               ,glp.period_num
               ,glp.period_year
               ,glp.quarter_num
               /*End modification by Adithya for Defect#14693*/
               ,a.capitalizable_flag
               ,a.expenditure_organization_name
               ,a.expenditure_type
               ,a.task_number
               ,b.vendor_name
               ,a.employee_name
               ,a.quantity
               /* Added amount as part of defect 30419*/
               ,c.amount
               ,a.expenditure_item_date
               ,d.segment1
               ,d.segment2
               ,d.segment3
               ,d.segment4
               ,d.segment5
               ,d.segment6
               ,d.segment7
               ,xx_pa_month_end_bals_rpt_pkg.xx_prj_tsk_minor (c.project_id,c.task_id) minor
           FROM gl_periods glp,
                pa_expend_items_adjust2_v a
                JOIN pa_cost_distribution_lines_all c
                  ON c.expenditure_item_id = a.expenditure_item_id
		------ Added By Sravanthi on 11/29/2013 for defect# 2658
                JOIN pa_expenditures_all EI
		 ON a.expenditure_id = ei.expenditure_id
		--- Comment Ends
                JOIN gl_code_combinations d
                  ON d.code_combination_id = c.dr_code_combination_id
                /*Start modification by Adithya for Defect#14693*/
                JOIN pa_tasks t ON t.task_id = c.task_id
                /*End modification by Adithya for Defect#14693*/
				/*Start modification by Shruthi for R12 Upgrade Retrofit */
              --  LEFT JOIN po_vendors b ON b.vendor_id = a.vendor_id
               ---   LEFT JOIN ap_suppliers b ON b.vendor_id = a.vendor_id   ---- commented By Sravanthi on 11/29/2013 for defect# 26589
	          LEFT JOIN ap_suppliers b ON b.vendor_id = ei.vendor_id   ---- added By Sravanthi on 11/29/2013 for defect# 26589
                /*End modification by Shruthi */
          WHERE a.latest_gl_period_name IN ( SELECT DISTINCT period_name
                                                        FROM gl_period_statuses
                                                       WHERE effective_period_num
                                                     BETWEEN v_period_num_from
                                                         AND v_period_num_to)
            AND a.latest_gl_period_name = glp.period_name
            AND a.capitalizable_flag = 'Y'
            /*commented below code as per Defect#14693*/
            /*AND (  (p_task_type = 'Marketing'          AND (a.task_number LIKE '80.%' OR a.task_number LIKE '%.MKT.%'))
                   OR
                   (p_task_type = 'Tenant Allowance'   AND (a.task_number LIKE '81.%.ST%' OR a.task_number LIKE '81.%.LT%'))
                   OR
                   (p_task_type = 'Lease Acquisitions' AND (a.task_number = '02.LEG'))
                   OR
                   (p_task_type = 'CIP General'        AND (  (a.task_number LIKE '02.%' AND a.task_number <> '02.LEG')
                                                              OR
                                                              (a.task_number LIKE '81.%' AND a.task_number NOT LIKE '81.%.ST%' AND a.task_number NOT LIKE '81.%.LT%' AND a.task_number NOT LIKE '%.MKT.%')
                                                           ))
                   OR
                   (p_task_type IS NULL)
                )*/
                /*Added below code as per Defect#14693*/
            AND EXISTS (
                   SELECT 1                                  -- ,SEGMENT_VALUE
                     FROM pa_segment_value_lookups pas
                         ,pa_segment_value_lookup_sets s
                    WHERE pas.segment_value_lookup_set_id =
                                                 s.segment_value_lookup_set_id
                      AND UPPER (s.segment_value_lookup_set_name) =
                                         UPPER ('SERVICE TYPE TO CIP ACCOUNT')
                      AND segment_value_lookup = t.service_type_code
                      AND p_service_type = pas.segment_value)
            AND (   (    p_vendor IS NOT NULL
                     AND p_vendor = 'Y'
                     AND b.vendor_name IS NULL
                    )
                 OR (    p_vendor IS NOT NULL
                     AND p_vendor = 'N'
                     AND b.vendor_name IS NOT NULL
                    )
                 OR (p_vendor IS NULL)
                )
            /*Added above code as per Defect#14693*/
            AND (   (    p_project_num_from IS NOT NULL
                     AND p_project_num_to IS NOT NULL
                     AND a.project_number BETWEEN p_project_num_from
                                              AND p_project_num_to
                    )
                 OR (    p_project_num_from IS NOT NULL
                     AND p_project_num_to IS NULL
                     AND a.project_number >= p_project_num_from
                    )
                 OR (    p_project_num_from IS NULL
                     AND p_project_num_to IS NOT NULL
                     AND a.project_number <= p_project_num_to
                    )
                 OR (    p_project_num_from IS NULL
                     AND p_project_num_to IS NULL
                    )
                )
            AND (   (    p_company IS NOT NULL
                     AND d.segment1 = p_company)
                 OR (p_company IS NULL)
                )
            AND a.org_id = v_profile_value
            /*Added below code as per Defect#14693*/
            AND (   (    p_capital_task = 'Y'
                     AND NVL (t.billable_flag, 'N') = p_capital_task
                    )
                 OR (    p_capital_task = 'N'
                     AND NVL (t.billable_flag, 'N') = p_capital_task
                    )
                );
--End modification by Adithya for defect#14693
   BEGIN
      --v_log_msg := 'Starting BEGIN block';
      --FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
      v_profile_value            := fnd_profile.VALUE ('ORG_ID');
      fnd_file.put_line (fnd_file.LOG, 'org_id ='|| v_profile_value);

      SELECT DISTINCT effective_period_num
                 INTO v_period_num_from
                 FROM gl_period_statuses
                WHERE period_name = p_period_from;

      --FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_period_num_from = ' || v_period_num_from);
      SELECT DISTINCT effective_period_num
                 INTO v_period_num_to
                 FROM gl_period_statuses
                WHERE period_name = p_period_to;

      --FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_period_num_to = ' || v_period_num_to);
      v_out_header               :=
            'PROJECT NUMBER'
         || CHR (9)
         || 'TRANSACTION ID'
         || CHR (9)
         || 'GL PERIOD'
         || CHR (9)
         || 'PERIOD'
         || CHR (9)
         || 'YEAR'
         || CHR (9)
         || 'QUARTER'
         || CHR (9)
         || 'CAPITALIZABLE'
         || CHR (9)
         || 'EXPENDITURE ORGANIZATION NAME'
         || CHR (9)
         || 'EXPENDITURE TYPE'
         || CHR (9)
         || 'TASK NUMBER'
         || CHR (9)
         || 'VENDOR'
         || CHR (9)
         || 'EMPLOYEE'
         || CHR (9)
         || 'QUANTITY'
         || CHR (9)
         || 'RAW COST'
         || CHR (9)
         || 'ITEM DATE'
         || CHR (9)
         || 'COMPANY'
         || CHR (9)
         || 'COST CENTER'
         || CHR (9)
         || 'ACCOUNT'
         || CHR (9)
         || 'LOCATION'
         || CHR (9)
         || 'INTERCOMPANY'
         || CHR (9)
         || 'LOB'
         || CHR (9)
         || 'FUTURE'
         || CHR (9)
         || 'MINOR';
      fnd_file.put_line (fnd_file.LOG,'p_period_from = ' || p_period_from);
      fnd_file.put_line (fnd_file.LOG,'p_period_to = '|| p_period_to);
      --FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_task_type = ' || p_task_type);
      fnd_file.put_line (fnd_file.LOG,'p_capital_task = ' || p_capital_task);
      fnd_file.put_line (fnd_file.LOG,'p_service_type = ' || p_service_type);
      fnd_file.put_line (fnd_file.LOG,'p_project_num_from = ' || p_project_num_from);
      fnd_file.put_line (fnd_file.LOG,'p_project_num_to = '|| p_project_num_to);
      fnd_file.put_line (fnd_file.LOG,'p_company = '|| p_company);

	  i:= 0;

      FOR c_out_rec IN c_out
      LOOP
         i:=   i + 1;

         IF i = 1
         THEN
            fnd_file.put_line (fnd_file.output, v_out_header);
         END IF;

         fnd_file.put_line (fnd_file.output
                           ,    c_out_rec.project_number
                             || CHR (9)
                             || c_out_rec.expenditure_item_id
                             || CHR (9)
                             || c_out_rec.latest_gl_period_name
                             || CHR (9)
                             || c_out_rec.period_num
                             || CHR (9)
                             || c_out_rec.period_year
                             || CHR (9)
                             || c_out_rec.quarter_num
                             || CHR (9)
                             || c_out_rec.capitalizable_flag
                             || CHR (9)
                             || c_out_rec.expenditure_organization_name
                             || CHR (9)
                             || c_out_rec.expenditure_type
                             || CHR (9)
                             || c_out_rec.task_number
                             || CHR (9)
                             || c_out_rec.vendor_name
                             || CHR (9)
                             || c_out_rec.employee_name
                             || CHR (9)
                             || c_out_rec.quantity
                             || CHR (9)
                             || c_out_rec.amount
                             || CHR (9)
                             || c_out_rec.expenditure_item_date
                             || CHR (9)
                             || c_out_rec.segment1
                             || CHR (9)
                             || c_out_rec.segment2
                             || CHR (9)
                             || c_out_rec.segment3
                             || CHR (9)
                             || c_out_rec.segment4
                             || CHR (9)
                             || c_out_rec.segment5
                             || CHR (9)
                             || c_out_rec.segment6
                             || CHR (9)
                             || c_out_rec.segment7
                             || CHR (9)
                             || c_out_rec.minor);
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, 'output record count = '|| i);
   END xx_main_rpt;

   --Start modification by Adithya for defect#14693
   FUNCTION xx_prj_tsk_minor (
                                xx_project_id NUMBER
                               ,xx_task_id   NUMBER
                              ) RETURN VARCHAR2
   IS
      lc_minor                      VARCHAR2 (50);
   BEGIN
      SELECT fa_cat.segment2
        INTO lc_minor
        FROM pa_project_asset_assignments pal
            ,pa_project_assets_all pa_pal
            ,fa_categories_b fa_cat
       WHERE pa_pal.project_asset_id = pal.project_asset_id
         AND pal.project_id = pa_pal.project_id
         AND fa_cat.category_id = pa_pal.asset_category_id
         AND pal.project_id = xx_project_id
         AND pal.task_id = xx_task_id
         AND ROWNUM < 2;

      RETURN lc_minor;
   EXCEPTION
      WHEN TOO_MANY_ROWS
      THEN
         RETURN NULL;
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
         RETURN NULL;
            --If the assets are project level rerun NULL as per the requiment
   END;
--End modification by Adithya for defect#14693
END xx_pa_expdt_mthly_act_rpt_pkg;
/