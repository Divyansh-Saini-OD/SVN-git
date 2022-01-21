CREATE OR REPLACE PACKAGE BODY APPS.xx_gl_ytd_bal_extract_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_GL_YTD_BAL_EXTRACT_PKG.pkb                                      |
-- | Description: Extension I2131_Oracle_GL_Feed_to_Hyperion_HFM for                 |
-- |              OD: GL Monthly YTD Balance Extract Program                         |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0      27-MAY-2011   Jagadeesh S        Creation                               |
-- |1.1      03-AUG-2011   Joe Klein          Added call to OD: Common Put Program   |
-- |                                          to FTP file to SFTP server.            |
-- |1.2      08-SEP-2011   Gaurav Agarwal     Modified code for rouding defect       |
-- |1.2      13-SEP-2011   Gaurav Agarwal     Modified code to remove rouding        |
-- |1.3      09-NOV-2011   Joe Klein          Defect 14971.  Modified so that native |
-- |                                          currency is used for each company as   |
-- |                                          defined in parameter p_currency_code.  |
-- |1.4      18-JUL-2013   Rishabh            R12 upgrade baseline version           |
-- |1.5      07-NOV-2013   Vivek S	      Modified the sql to get the account and|
-- |                                          cost center value set to fix duplicates|
-- |                                          records issues SIT02 defect#26312      | 	
-- |1.6      28-NOV-2013   Veronica Mairembam Modified for fix of defect# 26743:     |
-- |                                          Changed to write to the file, only if it is open|
-- |1.7  	 7-JUN-2017	  Amber Gupta				  Modified for fix of defect 41760 to check if
-- |										   file is open after close of second cursor|										
---+=================================================================================+

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  print_control_totals                                                           |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- |  Procedure to print the control totals                                          |
-- |                                                                                 |
-- |HISTORY                                                                          |
-- | 1.0          Creation                                                           |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |p_version                IN      Version                                         |
-- |p_scenario               IN      Scenario                                        |
-- |p_year                   IN      Year                                            |
-- |p_period                 IN      Period                                          |
-- |p_company                IN      Company                                         |
-- |p_value1                 IN      Value1                                          |
-- |p_value2                 IN      Value2                                          |
-- |p_value3                 IN      Value3                                          |
-- |                                                                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  gl_ytd_bal_monthly_extract                                                                          |
-- +=================================================================================+
   PROCEDURE print_control_totals (
      p_version    IN   VARCHAR2,
      p_scenario   IN   VARCHAR2,
      p_year       IN   VARCHAR2,
      p_period     IN   VARCHAR2,
      p_company    IN   VARCHAR2,
      p_value1     IN   VARCHAR2,
      p_value2     IN   VARCHAR2,
      p_value3     IN   NUMBER
   )
   IS
   BEGIN
      UTL_FILE.put_line (g_lt_file,
                            p_version
                         || '|'
                         || p_scenario
                         || '|'
                         || p_year
                         || '|'
                         || p_period
                         || '|'
                         || p_company
                         || '|'
                         || p_value1
                         || '|'
                         || p_value2
                         || '|'
                         || 'Top ICP'
                         || '|'
                         || 'Local Currency'
                         || '|'
                         || 'TOTCC'
                         || '|'
                         || 'TOTCHA'
                         || '|'
                         || 'TOTFLW'
                         || '|'
                         || 'TOTREP'
                         || '|'
                         || p_value3
                        );
   END print_control_totals;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  gl_ytd_bal_monthly_extract                                                     |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Main procedure to get GL Monthly YTD balance extract                            |
-- |                                                                                 |
-- |HISTORY                                                                          |
-- | 1.0          Creation                                                           |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_sob_name               IN      Set of Books Name                               |
-- |p_company                IN      Company Name                                    |
-- |p_year                   IN      Year                                            |
-- |p_period_name            IN      Period Name                                     |
-- |p_acc_rolup_grp          IN      Account Rollup Group Name                       |
-- |p_cc_rolup_grp           IN      Cost Center Rollup Group Name                   |
-- |                                                                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  None.                                                                          |
-- +=================================================================================+
   PROCEDURE gl_ytd_bal_monthly_extract (
      x_err_buff        OUT NOCOPY      VARCHAR2,
      x_ret_code        OUT NOCOPY      NUMBER,
      p_sob_name        IN              VARCHAR2,
      p_company         IN              VARCHAR2,
      p_year            IN              VARCHAR2,
      p_period_name     IN              VARCHAR2,
      p_acc_rolup_grp   IN              VARCHAR2,
      p_cc_rolup_grp    IN              VARCHAR2
   )
   AS
      lc_period_num            VARCHAR2 (2);
      lc_file_name             VARCHAR2 (100);
      ln_old_trans             NUMBER                                    := 0;
      ln_trans_balances        NUMBER                                    := 0;
      ln_cc_value_set_id       NUMBER;
      ln_acct_value_set_id     NUMBER;
      lb_req_status1           BOOLEAN;
      lb_req_status2           BOOLEAN;
      lc_file_path             VARCHAR2 (500)             := 'XXFIN_OUTBOUND_GLEXTRACT';
      lc_file_flag             VARCHAR2 (3)                            := 'N';
      lc_source_file_path      VARCHAR2 (500);
      lc_dest_file_path        VARCHAR2 (500)
                                            := '$XXFIN_DATA/ftp/out/hyperion';
      lc_archive_file_path     VARCHAR2 (500)    := '$XXFIN_ARCHIVE/outbound';
      lc_source_file_name      VARCHAR2 (1000);
      lc_dest_file_name        VARCHAR2 (1000);
      lc_dest_file_rename      VARCHAR2 (1000);
      lc_phase                 VARCHAR2 (50);
      lc_status                VARCHAR2 (50);
      lc_devphase              VARCHAR2 (50);
      lc_devstatus             VARCHAR2 (50);
      lc_message               VARCHAR2 (50);
      lc_error_msg             VARCHAR2 (4000);
      ln_req_id1               NUMBER (10);
      ln_req_id2               NUMBER (10);
      ln_msg_cnt               NUMBER                                    := 0;
      ln_buffer                BINARY_INTEGER                        := 32767;
      ln_appl_id               fnd_application.application_id%TYPE;
      ln_com_count             NUMBER                                    := 0;
      lc_previous_company      gl_code_combinations.segment1%TYPE     := NULL;
      ln_acc_rollup_grp        NUMBER;
      ln_cc_rollup_grp         NUMBER;
      ln_error_flag            NUMBER                                    := 0;
      lc_parent_acc   CONSTANT fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE
                                                                := 'P8000000';
      lc_period_status         VARCHAR2 (1);
      lc_period_name           VARCHAR2 (30);
      ln_tot_revenue           NUMBER                                    := 0;
      ln_tot_expenses          NUMBER                                    := 0;
      ln_net_income            NUMBER                                    := 0;
      ln_tot_assets            NUMBER                                    := 0;
      ln_tot_liability         NUMBER                                    := 0;
      ln_tot_owner_equity      NUMBER                                    := 0;
      ln_tot_liab_equity       NUMBER                                    := 0;
      ln_gl_appl_id            NUMBER                                  := 200;
      --
      lc_version               VARCHAR2 (10);
      lc_scenario              VARCHAR2 (50);
      lc_year                  VARCHAR2 (10);
      lc_period                VARCHAR2 (10);
      lc_company               VARCHAR2 (50);
      ln_rec_count             NUMBER;
      lc_source_file           VARCHAR2 (1000);


      -- Cursor Query to get the Set of Books --
      CURSOR lcu_set_of_books
      IS
         SELECT ---gsb.set_of_books_id,
            gsb.ledger_id,
            gsb.short_name, gsb.NAME,
                gsb.currency_code, gsb.chart_of_accounts_id
           FROM --gl_sets_of_books gsb
            gl_ledgers gsb
          WHERE gsb.attribute1 = 'Y'
            AND gsb.short_name =
                        DECODE (p_sob_name,
                                'ALL', gsb.short_name,
                                p_sob_name
                               );

      -- Cursor query to get the GL Balances
      CURSOR lcu_gl_balances (
         p_set_of_books_id     IN   NUMBER,
         p_currency_code       IN   VARCHAR2,
         p_period_name         IN   VARCHAR2,
         p_acct_value_set_id   IN   NUMBER,
         p_cc_value_set_id     IN   NUMBER,
         p_acc_rollup_grp      IN   VARCHAR2,
         p_cc_rollup_grp       IN   VARCHAR2,
         p_coa_id              IN   NUMBER
      )
      IS
         SELECT   VERSION, scenario, YEAR, period, company, ACCOUNT,
                  acct_description, intercompany, currency, cost_center, LOB,
               --   flow, reporting, round(SUM (ytd_bal)) ytd_bal    -- round added by Gaurav Agarwal
                  flow, reporting, SUM (ytd_bal) ytd_bal    -- round added by Gaurav Agarwal
             FROM (
                   -- Query to fetch the records where the parents exist for both account and cost center
                   SELECT /*+ leading(GLB) no_merge(AC) no_merge(AC1) no_merge(CC1) */
                          'Final' VERSION, 'Actual' scenario,
                          GLB.period_year YEAR,
                          SUBSTR (GLB.period_name, 1, 3) period,
                          gcc.segment1 company, gcc.segment3 ACCOUNT,
                          ac.description acct_description,
                          gcc.segment5 intercompany,
                          GLB.currency_code currency,
                          gcc.segment2 cost_center, gcc.segment6 LOB,
                          '[none]' flow, 'General_Ledger' reporting,
                          (  GLB.begin_balance_dr
                                  - GLB.begin_balance_cr
                                  + GLB.period_net_dr
                                  - GLB.period_net_cr
                                 ) ytd_bal
                     FROM gl_balances GLB,
                          gl_code_combinations gcc,
                          fnd_flex_values_vl ac,
                          fnd_flex_values_vl ac1,
                          fnd_flex_value_norm_hierarchy ac_par,
                          fnd_flex_values_vl cc1,
                          fnd_flex_value_norm_hierarchy cc_par
                    --WHERE GLB.set_of_books_id = p_set_of_books_id -- Commented by Rishabh on 18-Jul-2013 for R12 Retrofit
                    WHERE GLB.ledger_id = p_set_of_books_id  -- Commented by Rishabh on 18-Jul-2013 for R12 Retrofit
                      AND GLB.period_name = p_period_name
                      AND (   (    GLB.translated_flag IN ('Y', 'N')
                               AND GLB.currency_code = p_currency_code --Defect 14971
                              )
                           OR (   (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = 'STAT'
                                  )
                               OR (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = p_currency_code --Defect 14971
                                  )
                              )
                          )
                      AND GLB.actual_flag = 'A'
                      AND gcc.chart_of_accounts_id = p_coa_id
                      AND gcc.template_id IS NULL
                      AND gcc.code_combination_id = GLB.code_combination_id
                      AND cc_par.parent_flex_value = cc1.flex_value
                      AND cc1.flex_value_set_id = p_cc_value_set_id
                      AND cc1.structured_hierarchy_level = p_cc_rollup_grp
                      AND cc_par.flex_value_set_id = p_cc_value_set_id
                      AND gcc.segment2 BETWEEN cc_par.child_flex_value_low
                                           AND cc_par.child_flex_value_high
                      AND ac_par.parent_flex_value = ac1.flex_value
                      AND ac1.flex_value_set_id = p_acct_value_set_id
                      AND ac1.structured_hierarchy_level = p_acc_rollup_grp
                      AND ac.flex_value_set_id = p_acct_value_set_id
                      AND ac_par.flex_value_set_id = p_acct_value_set_id
                      AND ac.flex_value BETWEEN ac_par.child_flex_value_low
                                            AND ac_par.child_flex_value_high
                      AND ac.flex_value = gcc.segment3
                      AND ac1.enabled_flag = 'Y'
                      AND ac.enabled_flag = 'Y'
                      AND cc1.enabled_flag = 'Y'
                      AND gcc.segment1 = NVL (p_company, gcc.segment1)
                   UNION ALL
                   -- Query to fetch values where account parent does not exist and cost center parent exist
                   SELECT /*+ leading(GLB) no_merge(AC) no_merge(CC1) */
                          'Final' VERSION, 'Actual' scenario,
                          GLB.period_year YEAR,
                          SUBSTR (GLB.period_name, 1, 3) period,
                          gcc.segment1 company, gcc.segment3 ACCOUNT,
                          ac.description acct_description,
                          gcc.segment5 intercompany,
                          GLB.currency_code currency,
                          gcc.segment2 cost_center, gcc.segment6 LOB,
                          '[none]' flow, 'General_Ledger' reporting,
                         (  GLB.begin_balance_dr
                                  - GLB.begin_balance_cr
                                  + GLB.period_net_dr
                                  - GLB.period_net_cr

                                ) ytd_bal
                     FROM gl_balances GLB,
                          gl_code_combinations gcc,
                          fnd_flex_values_vl ac,
                          fnd_flex_values_vl cc1,
                          fnd_flex_value_norm_hierarchy cc_par
                    --WHERE GLB.set_of_books_id = p_set_of_books_id -- -- Commented by Rishabh on 18-Jul-2013 for R12 Retrofit
                     WHERE GLB.ledger_id = p_set_of_books_id -- -- Added by Rishabh on 18-Jul-2013 for R12 Retrofit
                      AND GLB.period_name = p_period_name
                      AND gcc.code_combination_id = GLB.code_combination_id
                      AND (   (    GLB.translated_flag IN ('Y', 'N')
                               AND GLB.currency_code = p_currency_code --Defect 14971
                              )
                           OR (   (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = 'STAT'
                                  )
                               OR (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = p_currency_code --Defect 14971
                                  )
                              )
                          )
                      AND GLB.actual_flag = 'A'
                      AND gcc.template_id IS NULL
                      AND gcc.chart_of_accounts_id = p_coa_id
                      AND ac.flex_value_set_id = p_acct_value_set_id
                      AND ac.flex_value = gcc.segment3
                      AND ac.enabled_flag = 'Y'
                      AND NOT EXISTS (
                             SELECT 1
                               FROM fnd_flex_value_norm_hierarchy ac_par,
                                    fnd_flex_values ac1
                              WHERE ac_par.flex_value_set_id =
                                                           p_acct_value_set_id
                                AND gcc.segment3
                                       BETWEEN ac_par.child_flex_value_low
                                           AND ac_par.child_flex_value_high
                                AND ac1.flex_value = ac_par.parent_flex_value
                                AND ac1.flex_value_set_id =
                                                           p_acct_value_set_id
                                AND ac1.structured_hierarchy_level =
                                                              p_acc_rollup_grp
                                AND ac1.enabled_flag = 'Y')
                      AND cc_par.parent_flex_value = cc1.flex_value
                      AND cc1.flex_value_set_id = p_cc_value_set_id
                      AND cc1.structured_hierarchy_level = p_cc_rollup_grp
                      AND cc_par.flex_value_set_id = p_cc_value_set_id
                      AND gcc.segment2 BETWEEN cc_par.child_flex_value_low
                                           AND cc_par.child_flex_value_high
                      AND gcc.segment1 = NVL (p_company, gcc.segment1)
                   UNION ALL
                   -- Query to fetch records where both cost center parent and account parent do not exist
                   SELECT /*+ leading(GLB) no_merge(AC) */
                          'Final' VERSION, 'Actual' scenario,
                          GLB.period_year YEAR,
                          SUBSTR (GLB.period_name, 1, 3) period,
                          gcc.segment1 company, gcc.segment3 ACCOUNT,
                          ac.description acct_description,
                          gcc.segment5 intercompany,
                          GLB.currency_code currency,
                          gcc.segment2 cost_center, gcc.segment6 LOB,
                          '[none]' flow, 'General_Ledger' reporting,
                          (  GLB.begin_balance_dr
                                  - GLB.begin_balance_cr
                                  + GLB.period_net_dr
                                  - GLB.period_net_cr
                                 ) ytd_bal
                     FROM gl_balances GLB,
                          gl_code_combinations gcc,
                          fnd_flex_values_vl ac
                    --WHERE GLB.set_of_books_id = p_set_of_books_id -- -- Commented by Rishabh on 18-Jul-2013 for R12 Retrofit
                     WHERE GLB.ledger_id = p_set_of_books_id -- -- Added by Rishabh on 18-Jul-2013 for R12 Retrofit
                      AND GLB.period_name = p_period_name
                      AND gcc.code_combination_id = GLB.code_combination_id
                      AND (   (    GLB.translated_flag IN ('Y', 'N')
                               AND GLB.currency_code = p_currency_code --Defect 14971
                              )
                           OR (   (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = 'STAT'
                                  )
                               OR (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = p_currency_code --Defect 14971
                                  )
                              )
                          )
                      AND GLB.actual_flag = 'A'
                      AND gcc.template_id IS NULL
                      AND gcc.chart_of_accounts_id = p_coa_id
                      AND ac.flex_value_set_id = p_acct_value_set_id
                      AND ac.flex_value = gcc.segment3
                      AND ac.enabled_flag = 'Y'
                      AND NOT EXISTS (
                             SELECT 1
                               FROM fnd_flex_value_norm_hierarchy ac_par,
                                    fnd_flex_values ac1
                              WHERE ac_par.flex_value_set_id =
                                                           p_acct_value_set_id
                                AND gcc.segment3
                                       BETWEEN ac_par.child_flex_value_low
                                           AND ac_par.child_flex_value_high
                                AND ac1.flex_value = ac_par.parent_flex_value
                                AND ac1.flex_value_set_id =
                                                           p_acct_value_set_id
                                AND ac1.structured_hierarchy_level =
                                                              p_acc_rollup_grp
                                AND ac1.enabled_flag = 'Y')
                      AND NOT EXISTS (
                             SELECT 1
                               FROM fnd_flex_value_norm_hierarchy cc_par,
                                    fnd_flex_values cc1
                              WHERE cc_par.flex_value_set_id =
                                                             p_cc_value_set_id
                                AND gcc.segment2
                                       BETWEEN cc_par.child_flex_value_low
                                           AND cc_par.child_flex_value_high
                                AND cc1.flex_value = cc_par.parent_flex_value
                                AND cc1.flex_value_set_id = p_cc_value_set_id
                                AND cc1.structured_hierarchy_level =
                                                               p_cc_rollup_grp
                                AND cc1.enabled_flag = 'Y')
                      AND gcc.segment1 = NVL (p_company, gcc.segment1)
                   UNION ALL
                   -- Query to fetch the records where parent account exists but parent cost center does not exist
                   SELECT 'Final' VERSION, 'Actual' scenario,
                          GLB.period_year YEAR,
                          SUBSTR (GLB.period_name, 1, 3) period,
                          gcc.segment1 company, gcc.segment3 ACCOUNT,
                          ac.description acct_description,
                          gcc.segment5 intercompany,
                          GLB.currency_code currency,
                          gcc.segment2 cost_center, gcc.segment6 LOB,
                          '[none]' flow, 'General_Ledger' reporting,
                         (  GLB.begin_balance_dr
                                  - GLB.begin_balance_cr
                                  + GLB.period_net_dr
                                  - GLB.period_net_cr

                                ) ytd_bal
                     FROM gl_balances GLB,
                          gl_code_combinations gcc,
                          fnd_flex_values_vl ac,
                          fnd_flex_values_vl ac1,
                          fnd_flex_value_norm_hierarchy ac_par
                    --WHERE GLB.set_of_books_id = p_set_of_books_id -- -- Commented by Rishabh on 18-Jul-2013 for R12 Retrofit
                     WHERE GLB.ledger_id = p_set_of_books_id -- -- Added by Rishabh on 18-Jul-2013 for R12 Retrofit
                      AND GLB.period_name = p_period_name
                      AND gcc.code_combination_id = GLB.code_combination_id
                      AND (   (    GLB.translated_flag IN ('Y', 'N')
                               AND GLB.currency_code = p_currency_code --Defect 14971
                              )
                           OR (   (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = 'STAT'
                                  )
                               OR (    GLB.translated_flag IS NULL
                                   AND GLB.currency_code = p_currency_code --Defect 14971
                                  )
                              )
                          )
                      AND GLB.actual_flag = 'A'
                      AND gcc.template_id IS NULL
                      AND gcc.chart_of_accounts_id = p_coa_id
                      AND ac_par.parent_flex_value = ac1.flex_value
                      AND ac1.flex_value_set_id = p_acct_value_set_id
                      AND ac1.structured_hierarchy_level = p_acc_rollup_grp
                      AND ac.flex_value_set_id = p_acct_value_set_id
                      AND ac_par.flex_value_set_id = p_acct_value_set_id
                      AND ac.flex_value BETWEEN ac_par.child_flex_value_low
                                            AND ac_par.child_flex_value_high
                      AND ac.flex_value = gcc.segment3
                      AND ac.enabled_flag = 'Y'
                      AND ac1.enabled_flag = 'Y'
                      AND NOT EXISTS (
                             SELECT 1
                               FROM fnd_flex_value_norm_hierarchy cc_par,
                                    fnd_flex_values cc1
                              WHERE cc_par.flex_value_set_id =
                                                             p_cc_value_set_id
                                AND gcc.segment2
                                       BETWEEN cc_par.child_flex_value_low
                                           AND cc_par.child_flex_value_high
                                AND cc1.flex_value = cc_par.parent_flex_value
                                AND cc1.flex_value_set_id = p_cc_value_set_id
                                AND cc1.structured_hierarchy_level =
                                                               p_cc_rollup_grp
                                AND cc1.enabled_flag = 'Y')
                      AND gcc.segment1 = NVL (p_company, gcc.segment1))
         GROUP BY VERSION,
                  scenario,
                  YEAR,
                  period,
                  company,
                  ACCOUNT,
                  acct_description,
                  intercompany,
                  currency,
                  cost_center,
                  LOB,
                  flow,
                  reporting
           HAVING round(SUM (ytd_bal)) <> 0
         ORDER BY company;
   BEGIN
      -- Get application_id
      BEGIN
         SELECT application_id
           INTO ln_appl_id
           FROM fnd_application
          WHERE application_short_name = 'SQLGL';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                   (fnd_file.LOG,
                       'Exception raised while fetching the application ID. '
                    || SQLERRM
                   );
      END;

      x_ret_code := 0;

      BEGIN
         SELECT directory_path
           INTO lc_source_file_path
           FROM dba_directories
          WHERE directory_name = lc_file_path;

         lc_source_file := lc_source_file_path;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
               (fnd_file.LOG,
                   'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                || SQLERRM
               );
      END;

      FOR lr_set_of_books IN lcu_set_of_books
      LOOP
         lc_previous_company := NULL;
         ln_com_count := 0;
         lc_period_name := NULL;
         lc_period_status := 'Y';

         -- Query for fetching period_num for the current period --
         BEGIN
            SELECT LPAD (gp.period_num, 2, 0)
              INTO lc_period_num
              FROM gl_period_statuses gp
             WHERE period_name = p_period_name
               ---AND gp.set_of_books_id = lr_set_of_books.set_of_books_id
           AND gp.ledger_id = lr_set_of_books.ledger_id
               AND gp.application_id = ln_appl_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line
                      (fnd_file.LOG,
                       'Exception raised while trying to find period number.'
                      );
         END;

         -- Query for fetching flex_value_set_ids for Accounts and Cost Centers --
         BEGIN
            SELECT ffv_cc.flex_value_set_id, ffv_ac.flex_value_set_id
              INTO ln_cc_value_set_id, ln_acct_value_set_id
              FROM fnd_flex_value_sets ffv_cc,
                   fnd_id_flex_segments fsg_cc,
                   fnd_flex_value_sets ffv_ac,
                   fnd_id_flex_segments fsg_ac
             WHERE fsg_cc.segment_name = 'Cost Center'
               AND fsg_cc.id_flex_code='GL#'            -- Added by Vivek on 7-NOV-2013 to fix duplicates records issues SIT02 defect#26312
               AND fsg_cc.flex_value_set_id = ffv_cc.flex_value_set_id
               AND fsg_cc.id_flex_num = lr_set_of_books.chart_of_accounts_id
               AND fsg_ac.segment_name = 'Account'
               AND fsg_ac.id_flex_code='GL#'            -- Added by Vivek on 7-NOV-2013 to fix duplicates records issues SIT02 defect#26312
               AND fsg_ac.flex_value_set_id = ffv_ac.flex_value_set_id
               AND fsg_ac.id_flex_num = lr_set_of_books.chart_of_accounts_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Value Set IDs not found for Account and Cost Center. '
                   || SQLERRM
                  );
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while fetching Value Set IDs for Account and Cost Center. '
                   || SQLERRM
                  );
         END;

         -- Query for fetching hierarchy_id for Report Line --
         BEGIN
            SELECT acc.hierarchy_id
              INTO ln_acc_rollup_grp
              FROM fnd_flex_hierarchies_vl acc
             WHERE acc.hierarchy_code = p_acc_rolup_grp
               AND acc.flex_value_set_id = ln_acct_value_set_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line
                              (fnd_file.LOG,
                                  'Hierarchy IDs not found for Report Line. '
                               || SQLERRM
                              );
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while fetching Hierarchy IDs not found for Report Line. '
                   || SQLERRM
                  );
         END;

         --  Query for fetching hierarchy_id for External --
         BEGIN
            SELECT cc.hierarchy_id
              INTO ln_cc_rollup_grp
              FROM fnd_flex_hierarchies_vl cc
             WHERE cc.hierarchy_code = p_cc_rolup_grp
               AND cc.flex_value_set_id = ln_cc_value_set_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Hierarchy IDs not found for External. '
                                  || SQLERRM
                                 );
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      'Exception raised while fetching Hierarchy IDs not found for External. '
                   || SQLERRM
                  );
         END;

         -- Initialize
         ln_com_count := 1;
         ln_tot_revenue := 0;
         ln_net_income := 0;
         ln_tot_expenses := 0;
         ln_tot_assets := 0;
         ln_tot_liability := 0;
         ln_tot_owner_equity := 0;
     ln_tot_liab_equity := 0;
         lc_previous_company := NULL;
         ln_rec_count := 0;

         -- Loop through the gl_balances cursor
         FOR lr_gl_balances IN
            lcu_gl_balances (---lr_set_of_books.set_of_books_id,
                             lr_set_of_books.ledger_id,
                             lr_set_of_books.currency_code,
                             p_period_name,
                             ln_acct_value_set_id,
                             ln_cc_value_set_id,
                             ln_acc_rollup_grp,
                             ln_cc_rollup_grp,
                             lr_set_of_books.chart_of_accounts_id
                            )
         LOOP
            IF (lc_previous_company <> lr_gl_balances.company)
            THEN
               UTL_FILE.put_line (g_lt_file, 'Control Totals:');
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'Revenue',
                                     p_value2        => 'Total Revenue',
                                     p_value3        => ln_tot_revenue
                                    );
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'Expenses',
                                     p_value2        => 'Total Expense',
                                     p_value3        => ln_tot_expenses
                                    );
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'NETINCOME',
                                     p_value2        => 'Net Income',
                                     p_value3        => ln_net_income
                                    );
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'Assets',
                                     p_value2        => 'Total Assets',
                                     p_value3        => ln_tot_assets
                                    );
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'Liabilities',
                                     p_value2        => 'Total Liabilities',
                                     p_value3        => ln_tot_liability
                                    );
               print_control_totals (p_version       => lr_gl_balances.VERSION,
                                     p_scenario      => lr_gl_balances.scenario,
                                     p_year          => lr_gl_balances.YEAR,
                                     p_period        => lr_gl_balances.period,
                                     p_company       => lc_previous_company,
                                     p_value1        => 'Owners Equity',
                                     p_value2        => 'Total Owners Equity',
                                     p_value3        => ln_tot_owner_equity
                                    );
               print_control_totals
                                   (p_version       => lr_gl_balances.VERSION,
                                    p_scenario      => lr_gl_balances.scenario,
                                    p_year          => lr_gl_balances.YEAR,
                                    p_period        => lr_gl_balances.period,
                                    p_company       => lc_previous_company,
                                    p_value1        => 'Shareholders Equity',
                                    p_value2        => 'Total Shareholders Equity',
                                    p_value3        => ln_tot_liab_equity
                                   );

               IF ln_error_flag = 0
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                      'The GL Balances have been written into the file successfully.'
                     );
               END IF;

               IF UTL_FILE.is_open (g_lt_file)
               THEN
                  UTL_FILE.fclose (g_lt_file);
               END IF;

               --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
               lc_source_file_name :=
                                    lc_source_file_path || '/' || lc_file_name;
               lc_dest_file_name := lc_dest_file_path || '/' || lc_file_name;
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG,
                                     'The Created File Name     : '
                                  || lc_source_file_name
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                     'The File Copied  Path     : '
                                  || lc_dest_file_name
                                 );
               ln_req_id1 :=
                  fnd_request.submit_request ('xxfin',
                                              'XXCOMFILCOPY',
                                              '',
                                              '',
                                              FALSE,
                                              lc_source_file_name,
                                              lc_dest_file_name,
                                              NULL,
                                              NULL
                                             );
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG,
                                     'The File was Copied into '
                                  || lc_dest_file_path
                                  || '. Request id : '
                                  || ln_req_id1
                                 );
               COMMIT;
               ----------- Wait for the Common file copy Program to Complete -----------
               lb_req_status1 :=
                  fnd_concurrent.wait_for_request (request_id      => ln_req_id1,
                                                   INTERVAL        => '2',
                                                   max_wait        => '',
                                                   phase           => lc_phase,
                                                   status          => lc_status,
                                                   dev_phase       => lc_devphase,
                                                   dev_status      => lc_devstatus,
                                                   MESSAGE         => lc_message
                                                  );
               fnd_file.put_line
                  (fnd_file.LOG,
                   '*************************************************************'
                  );
               ln_com_count := ln_com_count + 1;
               ln_rec_count := 0;
               ln_tot_revenue := 0;
               ln_net_income := 0;
               ln_tot_expenses := 0;
               ln_tot_assets := 0;
               ln_tot_liability := 0;
               ln_tot_owner_equity := 0;
           ln_tot_liab_equity := 0;
            END IF;

            IF ln_rec_count = 0
            THEN
               lc_file_name :=
                     TO_CHAR (ln_gl_appl_id)
                  || '@'
                  || lr_gl_balances.company
                  || '_HFM'
                  || '@Actual@'
                  || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')
                  || '-'
                  || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YYYY')
                  || '@RM.txt';
               fnd_file.put_line
                  (fnd_file.LOG,
                   '*************************************************************'
                  );
               fnd_file.put_line (fnd_file.LOG,
                                     'SOB Name     : '
                                  || lr_set_of_books.short_name
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                  'Company     : ' || lr_gl_balances.company
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                     'Currency     : '
                                  || lr_set_of_books.currency_code
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                  'Period Name  : ' || p_period_name
                                 );
               fnd_file.put_line
                  (fnd_file.LOG,
                   '-------------------------------------------------------------'
                  );
               fnd_file.put_line (fnd_file.LOG,
                                  'File Name : ' || lc_file_name);

               IF NOT UTL_FILE.is_open (g_lt_file)
               THEN
                  BEGIN
                     g_lt_file :=
                        UTL_FILE.fopen (lc_file_path,
                                        lc_file_name,
                                        'w',
                                        ln_buffer
                                       );
                     lc_file_flag := 'Y';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                              (fnd_file.LOG,
                                  'Exception raised while Opening the file. '
                               || SQLERRM
                              );
            lc_file_flag := 'N';
                  END;
               END IF;
            END IF;

            BEGIN
               UTL_FILE.put_line (g_lt_file,
                                     lr_gl_balances.VERSION
                                  || '|'
                                  || lr_gl_balances.scenario
                                  || '|'
                                  || lr_gl_balances.YEAR
                                  || '|'
                                  || lr_gl_balances.period
                                  || '|'
                                  || lr_gl_balances.company
                                  || '|'
                                  || lr_gl_balances.ACCOUNT
                                  || '|'
                                  || lr_gl_balances.acct_description
                                  || '|'
                                  || lr_gl_balances.intercompany
                                  || '|'
                                  || lr_gl_balances.currency
                                  || '|'
                                  || lr_gl_balances.cost_center
                                  || '|'
                                  || lr_gl_balances.LOB
                                  || '|'
                                  || lr_gl_balances.flow
                                  || '|'
                                  || lr_gl_balances.reporting
                                  || '|'
                                  || lr_gl_balances.ytd_bal
                                 );
               ln_rec_count := ln_rec_count + 1;
               lc_previous_company := lr_gl_balances.company;

               -- Calculating Totals
               IF SUBSTR (lr_gl_balances.ACCOUNT, 1, 1) = '4'
               THEN
                  ln_tot_revenue := ln_tot_revenue + lr_gl_balances.ytd_bal;
                  ln_net_income := ln_net_income + lr_gl_balances.ytd_bal;
               ELSIF SUBSTR (lr_gl_balances.ACCOUNT, 1, 1) IN ('5', '7', '9')
               THEN
                  ln_tot_expenses := ln_tot_expenses + lr_gl_balances.ytd_bal;
                  ln_net_income := ln_net_income + lr_gl_balances.ytd_bal;
               ELSIF SUBSTR (lr_gl_balances.ACCOUNT, 1, 1) = '1'
               THEN
                  ln_tot_assets := ln_tot_assets + lr_gl_balances.ytd_bal;
               ELSIF SUBSTR (lr_gl_balances.ACCOUNT, 1, 1) = '2'
               THEN
                  ln_tot_liability :=
                                    ln_tot_liability + lr_gl_balances.ytd_bal;
                  ln_tot_liab_equity :=
                                  ln_tot_liab_equity + lr_gl_balances.ytd_bal;
               ELSIF SUBSTR (lr_gl_balances.ACCOUNT, 1, 1) = '3'
               THEN
                  ln_tot_owner_equity :=
                                 ln_tot_owner_equity + lr_gl_balances.ytd_bal;
                  ln_tot_liab_equity :=
                                  ln_tot_liab_equity + lr_gl_balances.ytd_bal;
               END IF;


              lc_version := lr_gl_balances.VERSION;
              lc_scenario := lr_gl_balances.scenario;
              lc_year := lr_gl_balances.YEAR;
              lc_period := lr_gl_balances.period;
              lc_company := lr_gl_balances.company;

            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_error_flag := 1;
                  fnd_file.put_line
                        (fnd_file.LOG,
                            'Exception raised while writing into Text file. '
                         || SQLERRM
                        );
            END;
         END LOOP;

         --IF ln_com_count > 0
		 --IF ln_com_count > 0 AND lc_file_flag = 'Y'    -- Commented/Added by Veronica for fix of defect# 26743
		 IF ln_com_count > 0 AND UTL_FILE.is_open (g_lt_file)   --Commented the above and Added by Amber for fix of defect 41760 V 1.7
         THEN
            UTL_FILE.put_line (g_lt_file, 'Control Totals:');
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Revenue',
                                  p_value2        => 'Total Revenue',
                                  p_value3        => ln_tot_revenue
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Expenses',
                                  p_value2        => 'Total Expense',
                                  p_value3        => ln_tot_expenses
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'NETINCOME',
                                  p_value2        => 'Net Income',
                                  p_value3        => ln_net_income
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Assets',
                                  p_value2        => 'Total Assets',
                                  p_value3        => ln_tot_assets
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Liabilities',
                                  p_value2        => 'Total Liabilities',
                                  p_value3        => ln_tot_liability
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Owners Equity',
                                  p_value2        => 'Total Owners Equity',
                                  p_value3        => ln_tot_owner_equity
                                 );
            print_control_totals (p_version       => lc_version,
                                  p_scenario      => lc_scenario,
                                  p_year          => lc_year,
                                  p_period        => lc_period,
                                  p_company       => lc_company,
                                  p_value1        => 'Shareholders Equity',
                                  p_value2        => 'Total Shareholders Equity',
                                  p_value3        => ln_tot_liab_equity
                                 );

            IF ln_error_flag = 0
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'The GL Balances have been written into the file successfully.'
                  );
            END IF;

            IF UTL_FILE.is_open (g_lt_file)
            THEN
               UTL_FILE.fclose (g_lt_file);
            END IF;

            --------------- Call the Common file copy Program to Copy the file to $XXFIN_DATA/ftp/out/hyperion-------------
            lc_source_file_name := lc_source_file_path || '/' || lc_file_name;
            lc_dest_file_name := lc_dest_file_path || '/' || lc_file_name;
            fnd_file.put_line (fnd_file.LOG, '');
            fnd_file.put_line (fnd_file.LOG,
                                  'The Created File Name     : '
                               || lc_source_file_name
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'The File Copied  Path     : '
                               || lc_dest_file_name
                              );
            ln_req_id1 :=
               fnd_request.submit_request ('xxfin',
                                           'XXCOMFILCOPY',
                                           '',
                                           '',
                                           FALSE,
                                           lc_source_file_name,
                                           lc_dest_file_name,
                                           NULL,
                                           NULL
                                          );
            fnd_file.put_line (fnd_file.LOG, '');
            fnd_file.put_line (fnd_file.LOG,
                                  'The File was Copied into '
                               || lc_dest_file_path
                               || '. Request id : '
                               || ln_req_id1
                              );
            COMMIT;
            ----------- Wait for the Common file copy Program to Complete -----------
            lb_req_status1 :=
               fnd_concurrent.wait_for_request (request_id      => ln_req_id1,
                                                INTERVAL        => '2',
                                                max_wait        => '',
                                                phase           => lc_phase,
                                                status          => lc_status,
                                                dev_phase       => lc_devphase,
                                                dev_status      => lc_devstatus,
                                                MESSAGE         => lc_message
                                               );
            fnd_file.put_line
               (fnd_file.LOG,
                '*************************************************************'
               );
         END IF;

         fnd_file.put_line (fnd_file.LOG, '');
      END LOOP;

      --------- Call to OD: ZIP Directory Program to archive the files into $XXFIN_ARCHIVE/outbound -------
      fnd_file.put_line
               (fnd_file.LOG,
                '*************************************************************'
               );
      fnd_file.put_line
               (fnd_file.LOG,
                'Archiving the files into $XXFIN_ARCHIVE/outbound'
               );

      lc_source_file_name := lc_source_file;
      lc_file_name :=
                     TO_CHAR (ln_gl_appl_id)
                  || '@'
                  || 'COMP'
                  || '_HFM'
                  || '@Actual@'
                  || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'Mon')
                  || '-'
                  || TO_CHAR (TO_DATE (p_period_name, 'MON-YY'), 'YYYY')
                  || '@RM@';

      lc_dest_file_name :=
            lc_archive_file_path
         || '/'
         || lc_file_name
         || TO_CHAR (SYSDATE, 'DD-MON-YYYYHHMMSS');

      fnd_file.put_line (fnd_file.LOG, '');
      fnd_file.put_line (fnd_file.LOG,
                         'Input Folder    : ' || lc_source_file_name
                        );
      fnd_file.put_line (fnd_file.LOG,
                         'The Archived File Path   : ' || lc_dest_file_name
                        );
      ln_req_id2 :=
         fnd_request.submit_request ('xxfin',
                                     'XXODDIRZIP',
                                     '',
                                     '',
                                     FALSE,
                                     lc_source_file_name,
                                     lc_dest_file_name,
                                     NULL,
                                     NULL
                                    );
      COMMIT;
      fnd_file.put_line (fnd_file.LOG, '');
      fnd_file.put_line (fnd_file.LOG,
                            'The File was Archived into '
                         || lc_archive_file_path
                         || '. Request id : '
                         || ln_req_id2
                        );
      lb_req_status2 :=
         fnd_concurrent.wait_for_request (request_id      => ln_req_id2,
                                          INTERVAL        => '2',
                                          max_wait        => '',
                                          phase           => lc_phase,
                                          status          => lc_status,
                                          dev_phase       => lc_devphase,
                                          dev_status      => lc_devstatus,
                                          MESSAGE         => lc_message
                                         );
      fnd_file.put_line
               (fnd_file.LOG,
                '*************************************************************'
               );

         --------------- Call the Common file copy Program to copy .zip file to .dat file-------------
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG, '*************************************************************');
               fnd_file.put_line (fnd_file.LOG, 'Copying .zip file to .dat file');
               lc_source_file_name := lc_dest_file_name || '.zip';
               lc_dest_file_name   := 'GL_NAGL_'
                                      || TO_CHAR (SYSDATE, 'YYYYMMDDHH24miss')
                                      || '.dat';
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG,
                                     'Source Path and File Name     : '
                                  || lc_source_file_name
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                     'Copied Path and File Name     : '
                                  || lc_archive_file_path || '/' || lc_dest_file_name
                                 );
               ln_req_id1 :=
                  fnd_request.submit_request ('xxfin',
                                              'XXCOMFILCOPY',
                                              '',
                                              '',
                                              FALSE,
                                              lc_source_file_name,
                                              lc_archive_file_path || '/' || lc_dest_file_name,
                                              NULL,
                                              NULL
                                             );
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG,
                                     'OD: Common File Copy submitted to copy file.  Request id : '
                                  || ln_req_id1
                                 );
               COMMIT;
               ----------- Wait for the Common file copy Program to Complete -----------
               lb_req_status1 :=
                  fnd_concurrent.wait_for_request (request_id      => ln_req_id1,
                                                   INTERVAL        => '2',
                                                   max_wait        => '',
                                                   phase           => lc_phase,
                                                   status          => lc_status,
                                                   dev_phase       => lc_devphase,
                                                   dev_status      => lc_devstatus,
                                                   MESSAGE         => lc_message
                                                  );
               fnd_file.put_line
                  (fnd_file.LOG,
                   '*************************************************************'
                  );

         --------------- Call the OD: Common Put Program to FTP .dat file to HFM, then rename it back to .zip, then delete source .dat file
               fnd_file.put_line (fnd_file.LOG, '');
               fnd_file.put_line (fnd_file.LOG, '*************************************************************');
               fnd_file.put_line (fnd_file.LOG, 'FTPing zip file to SFTP server');
               lc_dest_file_rename := REPLACE(lc_dest_file_name,'.dat','.zip');
               fnd_file.put_line (fnd_file.LOG,
                                     'Dest file rename     : '
                                  || lc_dest_file_rename
                                 );
               ln_req_id1 := FND_REQUEST.SUBMIT_REQUEST(application => 'XXFIN'
                                                          ,program     => 'XXCOMFTP'
                                                          ,description => 'GL Balances File FTP PUT'
                                                          ,sub_request => FALSE
                                                          ,argument1   => 'OD_EPM_GL_BAL'            -- Row from OD_FTP_PROCESSES translation
                                                          ,argument2   => lc_dest_file_name          -- Source file name
                                                          ,argument3   => NULL                       -- Dest file name
                                                          ,argument4   => 'Y'                        -- Delete source file
                                                          ,argument5   => lc_dest_file_rename        -- New name after file is FTP'd
                                                          );
               COMMIT;
               IF ln_req_id1 = 0 THEN
                  fnd_file.put_line (fnd_file.LOG,'Error : Unable to submit FTP program to send GL Balances file');
               ELSE
                  fnd_file.put_line (fnd_file.LOG,
                                     'OD: Common Put Program submitted to FTP file to SFTP server.  Request id : '
                                  || ln_req_id1
                                 );
               END IF;
         --------------- END of FTP'ing .dat file

   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (g_lt_file)
         THEN
            UTL_FILE.fclose (g_lt_file);
         END IF;

         fnd_message.set_name ('XXFIN', 'XX_GL_0006_BAL_EXT_OTHERS');
         fnd_message.set_token ('COL', 'GL Balance');
         lc_error_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG, 'Exception section: ' || SQLERRM);
         x_ret_code := 2;
         xx_com_error_log_pub.log_error
                  (p_program_type                => 'CONCURRENT PROGRAM',
                   p_program_name                => 'OD: GL Monthly Balance Extract Program',
                   p_program_id                  => fnd_global.conc_program_id,
                   p_module_name                 => 'GL',
                   p_error_location              => 'Oracle Error ' || SQLERRM,
                   p_error_message_count         => ln_msg_cnt + 1,
                   p_error_message_code          => 'E',
                   p_error_message               => lc_error_msg,
                   p_error_message_severity      => 'Major',
                   p_notify_flag                 => 'N',
                   p_object_type                 => 'GL Balance Extract'
                  );
   END gl_ytd_bal_monthly_extract;
END xx_gl_ytd_bal_extract_pkg;
/
