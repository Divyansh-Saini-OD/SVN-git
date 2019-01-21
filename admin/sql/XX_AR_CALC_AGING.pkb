create or replace
PACKAGE BODY ar_calc_aging AS
/* $Header: ARRECONB.pls 115.26.15104.11 2009/03/10 06:52:19 rsamanta ship $ */
/*-------------------------------------------------------------
 PRIVATE variables
---------------------------------------------------------------*/
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name : XX_AR_CALC_AGING                                             |
-- | Description :Modified the standard package for performance issues   |
-- |              in AR Reconciliation Report for Defect 3947            |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  17-FEB-10     Hemalatha S          Performance change for  |
-- |                                             defect 3947             |
-- +=====================================================================+
company_segment_where    VARCHAR2(500) := NULL;
br_enabled_flag          VARCHAR2(1)   := NULL;
l_gl_dist_table          VARCHAR2(50)  := NULL;
l_ps_table               VARCHAR2(50)  := NULL;
l_trx_table              VARCHAR2(50)  := NULL;
l_line_table             VARCHAR2(50)  := NULL;
l_ra_table               VARCHAR2(50)  := NULL;
l_ard_table              VARCHAR2(50)  := NULL;
l_adj_table              VARCHAR2(50)  := NULL;
l_ps_org_where           VARCHAR2(200) := NULL;
l_gl_dist_org_where      VARCHAR2(200) := NULL;
l_trx_org_where          VARCHAR2(200) := NULL;
l_line_org_where         VARCHAR2(200) := NULL;
l_ra_org_where           VARCHAR2(200) := NULL;
l_ard_org_where          VARCHAR2(200) := NULL;
l_ard1_org_where         VARCHAR2(200) := NULL;
l_ath_org_where          VARCHAR2(200) := NULL;
l_adj_org_where          VARCHAR2(200) := NULL;

PROCEDURE build_parameters(p_reporting_level          IN  VARCHAR2,
                           p_reporting_entity_id      IN  NUMBER,
                           p_co_seg_low               IN VARCHAR2,
                           p_co_seg_high              IN VARCHAR2,
                           p_coa_id                   IN NUMBER)
IS
BEGIN

 ar_calc_aging.g_reporting_entity_id   := p_reporting_entity_id;

 IF NVL(ar_calc_aging.ca_sob_type,'P') = 'P' THEN
     l_ps_table      := 'ar_payment_schedules_all ';
     l_ra_table      := 'ar_receivable_applications_all ';
     l_adj_table     := 'ar_adjustments_all ';
     l_ard_table     := 'ar_distributions_all ';
     l_gl_dist_table := 'ra_cust_trx_line_gl_dist_all ';
     l_line_table    := 'ra_customer_trx_lines_all ';
     l_trx_table     := 'ra_customer_trx_all ';
  ELSE
     l_ps_table      := 'ar_payment_schedules_all_mrc_v ';
     l_ra_table      := 'ar_receivable_apps_all_mrc_v ';
     l_adj_table     := 'ar_adjustments_all_mrc_v ';
     l_ard_table     := 'ar_distributions_all_mrc_v ';
     l_gl_dist_table := 'ra_trx_line_gl_dist_all_mrc_v ';
     l_line_table    := 'ra_cust_trx_ln_all_mrc_v ';
     l_trx_table     := 'ra_customer_trx_all_mrc_v ';
  END IF;

  XLA_MO_REPORTING_API.Initialize(p_reporting_level, p_reporting_entity_id, 'AUTO');

  l_ps_org_where     := XLA_MO_REPORTING_API.Get_Predicate('ps',null);
  l_gl_dist_org_where:= XLA_MO_REPORTING_API.Get_Predicate('gl_dist', null);
  l_trx_org_where    := XLA_MO_REPORTING_API.Get_Predicate('trx', null);
  l_line_org_where   := XLA_MO_REPORTING_API.Get_Predicate('lines',null);
  l_ra_org_where     := XLA_MO_REPORTING_API.Get_Predicate('ra' , null);
  l_ard_org_where    := XLA_MO_REPORTING_API.Get_Predicate('ard',null);
  l_ard1_org_where   := XLA_MO_REPORTING_API.Get_Predicate('ard1',null);
  l_ath_org_where    := XLA_MO_REPORTING_API.Get_Predicate('ath' ,null);
  l_adj_org_where    := XLA_MO_REPORTING_API.Get_Predicate('adj' ,null);

  /* Replace the variables to bind with the function calls so that we don't have to bind those */
  l_ps_org_where     := replace(l_ps_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_gl_dist_org_where:= replace(l_gl_dist_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_trx_org_where    := replace(l_trx_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_line_org_where   := replace(l_line_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_ra_org_where     := replace(l_ra_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_ard_org_where    := replace(l_ard_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_ard1_org_where   := replace(l_ard1_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_ath_org_where    := replace(l_ath_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');
  l_adj_org_where    := replace(l_adj_org_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');

  IF company_segment_where IS NULL THEN
     IF p_co_seg_low IS NULL AND p_co_seg_high IS NULL THEN
        company_segment_where := NULL;
     ELSIF p_co_seg_low IS NULL THEN
        company_segment_where := ' AND ' ||
               ar_calc_aging.FLEX_SQL(p_application_id => 101,
                               p_id_flex_code => 'GL#',
                               p_id_flex_num =>p_coa_id,
                               p_table_alias => 'GC',
                               p_mode => 'WHERE',
                               p_qualifier => 'GL_BALANCING',
                               p_function => '<=',
                               p_operand1 => p_co_seg_high);
     ELSIF p_co_seg_high IS NULL THEN
        company_segment_where := ' AND ' ||
               ar_calc_aging.FLEX_SQL(p_application_id => 101,
                               p_id_flex_code => 'GL#',
                               p_id_flex_num => p_coa_id,
                               p_table_alias => 'GC',
                               p_mode => 'WHERE',
                               p_qualifier => 'GL_BALANCING',
                               p_function => '>=',
                               p_operand1 => p_co_seg_low);
    ELSE
        company_segment_where := ' AND ' ||
               ar_calc_aging.FLEX_SQL(p_application_id => 101,
                               p_id_flex_code => 'GL#',
                               p_id_flex_num =>p_coa_id,
                               p_table_alias => 'GC',
                               p_mode => 'WHERE',
                               p_qualifier => 'GL_BALANCING',
                               p_function => 'BETWEEN',
                               p_operand1 => p_co_seg_low,
                               p_operand2 => p_co_seg_high);
    END IF;

  END IF;

END build_parameters;

/*========================================================================+
 Function which returns the global variable g_reporting_entity_id
 ========================================================================*/

FUNCTION get_reporting_entity_id return NUMBER is
BEGIN
    return ar_calc_aging.g_reporting_entity_id;
END get_reporting_entity_id;


/*========================================================================+
   Wrapper procedures for the APIS available in FA_RX_FLEX_SQL package
   When patch 4128137 is released, we need to replace this call with the
   corresponding FND API calls
 ========================================================================*/
FUNCTION flex_sql(
        p_application_id in number,
        p_id_flex_code in varchar2,
        p_id_flex_num in number default null,
        p_table_alias in varchar2,
        p_mode in varchar2,
        p_qualifier in varchar2,
        p_function in varchar2 default null,
        p_operand1 in varchar2 default null,
        p_operand2 in varchar2 default null) return varchar2 IS

l_ret_param varchar2(8000);

BEGIN
         	FND_FILE.put_line(fnd_file.log,'ar_calc_aging.flex_sql+1');

        /* This is a wrapper function for the fa_rx_flex_pkg.flex_sql
           When patch 4128137 is released, we need to replace this call with the corresponding
           FND API calls */

         l_ret_param := fa_rx_flex_pkg.flex_sql(
                                                p_application_id   => p_application_id,
                                                p_id_flex_code     => p_id_flex_code,
                                                p_id_flex_num      => p_id_flex_num,
                                                p_table_alias      => p_table_alias,
                                                p_mode             => p_mode,
                                                p_qualifier        => p_qualifier,
                                                p_function         => p_function,
                                                p_operand1         => p_operand1,
                                                p_operand2         => p_operand2);
         	FND_FILE.put_line(fnd_file.log,'ar_calc_aging.flex_sql+2');


         return l_ret_param;

END flex_sql;


FUNCTION get_value(
        p_application_id in number,
        p_id_flex_code in varchar2,
        p_id_flex_num in number default NULL,
        p_qualifier in varchar2,
        p_ccid in number) return varchar2 IS

l_value  varchar2(2000);

BEGIN
         /* This is a wrapper function for the fa_rx_flex_pkg.get_value
           When patch 4128137 is released, we need to replace this call with the corresponding
           FND API calls */

         l_value := fa_rx_flex_pkg.get_value (
                                              p_application_id => p_application_id,
                                              p_id_flex_code   => p_id_flex_code,
                                              p_id_flex_num    => p_id_flex_num,
                                              p_qualifier      => p_qualifier,
                                              p_ccid           => p_ccid);

         return l_value;

END get_value;

FUNCTION get_description(
        p_application_id in number,
        p_id_flex_code in varchar2,
        p_id_flex_num in number default NULL,
        p_qualifier in varchar2,
        p_data in varchar2) return varchar2 IS

l_description varchar2(2000);
l_account     varchar2(30);

BEGIN
         /* This is a wrapper function for the fa_rx_flex_pkg.get_description
           When patch 4128137 is released, we need to replace this call with the corresponding
           FND API calls */

         l_account     :=  get_value(p_application_id => p_application_id,
                                              p_id_flex_code   => p_id_flex_code,
                                              p_id_flex_num    => p_id_flex_num,
                                              p_qualifier      => p_qualifier,
                                              p_ccid           => p_data);

         l_description := fa_rx_flex_pkg.get_description(
                                                         p_application_id => p_application_id,
                                                         p_id_flex_code   => p_id_flex_code,
                                                         p_id_flex_num    => p_id_flex_num,
                                                         p_qualifier      => p_qualifier,
                                                         p_data           => l_account);

         return l_description;

END get_description;


PROCEDURE initialize
IS
    l_profile_rsob_id NUMBER := NULL;
    l_client_info_rsob_id NUMBER := NULL;
BEGIN

    /*
     * When the report (AR Reconciliation report) is run for reporting book
     * client info will be set for the particular set of books ID.  We will
     * use that information to determine which sql statements to execute
     * The checking of profile is done to make sure that if the user submits
     * the report from reporting responsibility it would still work and in
     * this case even though report is run for reporting book we still need
     * to point to regular AR views
     * For more information please refer to bug 2498344
     */

     /*
      * Bug fix 2801076
      *  Using replace to change spaces to null when RSOB not set
      */
     SELECT TO_NUMBER(NVL( REPLACE(SUBSTRB(USERENV('CLIENT_INFO'),45,10),' '),-99))
     INTO l_client_info_rsob_id
     FROM dual;


    fnd_profile.get('MRC_REPORTING_SOB_ID', l_profile_rsob_id);

    IF (l_client_info_rsob_id = NVL(l_profile_rsob_id,-1)) OR
       (l_client_info_rsob_id = -99)
    THEN
      ar_calc_aging.ca_sob_type := 'P';
    ELSE
      ar_calc_aging.ca_sob_type := 'R';
    END IF;

 END;

/*-------------------------------------------------------------
PUBLIC PROCEDURE aging
---------------------------------------------------------------*/
/*Bug 7287425 added parameters for dividing data in workers added two
  paramters p_worker_number and p_total_workers in all procedures*/
PROCEDURE aging_as_of(
                      p_as_of_date_from          IN  DATE,
                      p_as_of_date_to            IN  DATE,
                      p_reporting_level          IN  VARCHAR2,
                      p_reporting_entity_id      IN  NUMBER,
                      p_co_seg_low               IN  VARCHAR2,
                      p_co_seg_high              IN  VARCHAR2,
                      p_coa_id                   IN  NUMBER,
                      p_begin_bal                OUT NOCOPY NUMBER,
                      p_end_bal                  OUT NOCOPY NUMBER,
                      p_acctd_begin_bal          OUT NOCOPY NUMBER,
                      p_acctd_end_bal            OUT NOCOPY NUMBER,
	              p_worker_number            IN NUMBER DEFAULT 1,
	              p_total_workers            IN NUMBER DEFAULT 1) IS
 l_ps_select                VARCHAR2(5000);
 l_ra_select                VARCHAR2(5000);
 l_cm_ra_select             VARCHAR2(5000);
 l_adj_select               VARCHAR2(5000);
 l_cancel_br_select         VARCHAR2(5000);
 l_trx_main_select          VARCHAR2(32000);
 l_br_select                VARCHAR2(5000);
 l_br_app_select            VARCHAR2(5000);
 l_br_adj_select            VARCHAR2(5000);
 l_br_main_select           VARCHAR2(32000);
 l_unapp_select             VARCHAR2(5000);
 l_main_select              VARCHAR2(32000);
 v_cursor                   NUMBER;
 l_ignore                   INTEGER;
 l_customer_trx_id          NUMBER;
 l_request                  NUMBER;
BEGIN

  COMMIT;
  SET TRANSACTION READ ONLY;

  build_parameters (p_reporting_level,
                    p_reporting_entity_id,
                    p_co_seg_low,
                    p_co_seg_high,
                    p_coa_id);

  l_ps_select := 'SELECT ps.customer_trx_id ,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            NULL,:p_as_of_date_from)
                             *  ps.amount_due_remaining) start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            NULL,:p_as_of_date_to)
                             *  ps.amount_due_remaining) end_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            NULL,:p_as_of_date_from)
                             *  ps.acctd_amount_due_remaining) acctd_start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            NULL,:p_as_of_date_to)
                             *  ps.acctd_amount_due_remaining) acctd_end_bal
                  FROM '||l_ps_table||'  ps
                  WHERE ps.payment_schedule_id+0 > 0
                  AND   ps.gl_date_closed  >= :p_as_of_date_from
                  AND   ps.class IN ( ''CB'', ''CM'',''DEP'',''DM'',''GUAR'',''INV'')
                  AND   ps.gl_date  <= :p_as_of_date_to
                  '|| l_ps_org_where ||'
                  GROUP BY ps.customer_trx_id ' ;

  l_ra_select := 'SELECT
                         ps.customer_trx_id ,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_from)
                             * ( ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                 + NVL(ra.unearned_discount_taken,0))) start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_to)
                             * ( ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                 + NVL(ra.unearned_discount_taken,0))) end_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_from)
                             * (ra.acctd_amount_applied_to +
                                 NVL(ra.acctd_earned_discount_taken,0)
                                 + NVL(ra.acctd_unearned_discount_taken,0)))  acctd_start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_to)
                             * (ra.acctd_amount_applied_to +
                                 NVL(ra.acctd_earned_discount_taken,0)
                                 + NVL(ra.acctd_unearned_discount_taken,0)))  acctd_end_bal
                 FROM '|| l_ps_table ||' ps,
                      '|| l_ra_table ||' ra
                WHERE  ra.applied_payment_schedule_id = ps.payment_schedule_id
                  AND  ps.payment_schedule_id+0 > 0
                  AND  ps.gl_date_closed  >= :p_as_of_date_from
                  AND  ps.class IN ( ''CB'', ''CM'',''DEP'',''DM'',''GUAR'',''INV'')
                  AND  ra.gl_date > :p_as_of_date_from
                  AND  ra.status = ''APP''
                  AND  ps.gl_date <= :p_as_of_date_to
                  AND  NVL(ra.confirmed_flag,''Y'') = ''Y''
                  '|| l_ps_org_where||'
                  '|| l_ra_org_where||'
               GROUP BY ps.customer_trx_id ';

  l_cm_ra_select := 'SELECT
                         ps.customer_trx_id ,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_from)
                             * -1
                             * ( ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                 + NVL(ra.unearned_discount_taken,0))) start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_to)
                             * -1
                             * ( ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                 + NVL(ra.unearned_discount_taken,0))) end_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_from)
                             * -1
                             * ra.acctd_amount_applied_from )  acctd_start_bal,
                         sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ra.gl_date,:p_as_of_date_to)
                             * -1
                             * ra.acctd_amount_applied_from ) acctd_end_bal
                 FROM '|| l_ps_table ||' ps,
                      '|| l_ra_table ||' ra
                  WHERE ra.payment_schedule_id = ps.payment_schedule_id
                  AND  ps.payment_schedule_id+0 > 0
                  AND  ps.gl_date_closed  >= :p_as_of_date_from
                  AND  ps.class  = ''CM''
                  AND  ra.gl_date > :p_as_of_date_from
                  AND  ra.status IN (''APP'',''ACTIVITY'')   --bug5185746
                  AND  ra.application_type = ''CM''
                  AND  ps.gl_date <= :p_as_of_date_to
                  AND  NVL(ra.confirmed_flag,''Y'') = ''Y''
                  '|| l_ps_org_where||'
                  '|| l_ra_org_where||'
               GROUP BY ps.customer_trx_id ';

  l_adj_select := 'SELECT ps.customer_trx_id,
                          -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                  adj.gl_date,:p_as_of_date_from)
                             *   adj.amount)  start_bal,
                          -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                  adj.gl_date,:p_as_of_date_to)
                             *   adj.amount)  end_bal  ,
                          -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                  adj.gl_date,:p_as_of_date_from)
                             *   adj.acctd_amount)  acctd_start_bal,
                          -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                  adj.gl_date,:p_as_of_date_to)
                             *   adj.acctd_amount) acctd_end_bal
                    FROM  '||l_adj_table||' adj ,'
                           ||l_ps_table ||' ps
                    WHERE ps.payment_schedule_id + 0 > 0
                    AND   ps.gl_date_closed  >= :p_as_of_date_from
                    AND   ps.class IN ( ''CB'', ''CM'',''DEP'',''DM'',''GUAR'',''INV'')
                    AND   ps.gl_date  <= :p_as_of_date_to
                    AND   adj.payment_schedule_id = ps.payment_schedule_id
                    AND   adj.gl_date > :p_as_of_date_from
                    AND   adj.status = ''A''
                    '|| l_adj_org_where||'
                    '|| l_ps_org_where|| '
                    GROUP BY ps.customer_trx_id ';

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
      l_cancel_br_select :=  'SELECT
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_from)
                               * decode(nvl(ard.amount_cr,0), 0, nvl(ard.amount_dr,0),
                                             (ard.amount_cr * -1))) start_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_to)
                               * decode(nvl(ard.amount_cr,0), 0, nvl(ard.amount_dr,0),
                                             (ard.amount_cr * -1))) end_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_from)
                               * decode(nvl(ard.acctd_amount_cr,0), 0, nvl(ard.acctd_amount_dr,0),
                                            (ard.acctd_amount_cr * -1))) acctd_start_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_to)
                               * decode(nvl(ard.acctd_amount_cr,0), 0, nvl(ard.acctd_amount_dr,0),
                                            (ard.acctd_amount_cr * -1))) acctd_end_bal
                       FROM '||l_ps_table||' ps,
                            '||l_ard_table || ' ard,
                            '||'ar_transaction_history_all ath,
                            '||l_line_table|| ' lines,
                             gl_code_combinations gc
                       WHERE ps.payment_schedule_id+0 > 0
                       AND  ps.gl_date_closed  >= :p_as_of_date_from
                       AND  ps.class IN ( ''BR'',''CB'', ''CM'',''DEP'',''DM'',''GUAR'',''INV'')
                       AND  ath.gl_date > :p_as_of_date_from
                       AND  ath.event = ''CANCELLED''
                       AND  ps.gl_date <= :p_as_of_date_to
                       AND  ps.customer_trx_id = ath.customer_trx_id
                       AND  ard.source_table = ''TH''
                       AND  ard.source_id = ath.transaction_history_id
                       AND  ps.customer_trx_id = lines.customer_trx_id
                       AND  ard.source_id_secondary = lines.customer_trx_line_id
                       AND  ard.code_combination_id = gc.code_combination_id
                       ' || l_ps_org_where ||'
                       ' || l_ard_org_where||'
                       ' || l_ath_org_where||'
                       ' || l_line_org_where ||'
                       ' || company_segment_where;
     ELSE
      l_cancel_br_select :=  'SELECT
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_from)
                               * decode(nvl(ard.amount_cr,0), 0, nvl(ard.amount_dr,0),
                                             (ard.amount_cr * -1))) start_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_to)
                               * decode(nvl(ard.amount_cr,0), 0, nvl(ard.amount_dr,0),
                                             (ard.amount_cr * -1))) end_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_from)
                               * decode(nvl(ard.acctd_amount_cr,0), 0, nvl(ard.acctd_amount_dr,0),
                                            (ard.acctd_amount_cr * -1))) acctd_start_bal,
                               sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                            ath.gl_date,:p_as_of_date_to)
                               * decode(nvl(ard.acctd_amount_cr,0), 0, nvl(ard.acctd_amount_dr,0),
                                            (ard.acctd_amount_cr * -1))) acctd_end_bal
                       FROM '||l_ps_table||' ps,
                            '||l_ard_table || ' ard,
                            '||'ar_transaction_history_all ath,
                            '||l_line_table|| ' lines
                       WHERE ps.payment_schedule_id+0 > 0
                       AND  ps.gl_date_closed  >= :p_as_of_date_from
                       AND  ps.class IN ( ''BR'',''CB'', ''CM'',''DEP'',''DM'',''GUAR'',''INV'')
                       AND  ath.gl_date > :p_as_of_date_from
                       AND  ath.event = ''CANCELLED''
                       AND  ps.gl_date <= :p_as_of_date_to
                       AND  ps.customer_trx_id = ath.customer_trx_id
                       AND  ard.source_table = ''TH''
                       AND  ard.source_id = ath.transaction_history_id
                       AND  ps.customer_trx_id = lines.customer_trx_id
                       AND  ard.source_id_secondary = lines.customer_trx_line_id
                       ' || l_ps_org_where ||'
                       ' || l_ard_org_where||'
                       ' || l_ath_org_where||'
                       ' || l_line_org_where;
  END IF;

  l_br_select :=    ' SELECT ps.customer_trx_id ,
                             sum(ar_calc_aging.begin_or_end_bal(gl_date,gl_date_closed,
                                                                NULL,:p_as_of_date_from)
                               *  ps.amount_due_remaining) start_bal,
                             sum(ar_calc_aging.begin_or_end_bal(gl_date,gl_date_closed,
                                                                NULL,:p_as_of_date_to)
                               *  ps.amount_due_remaining) end_bal,
                             sum(ar_calc_aging.begin_or_end_bal(gl_date,gl_date_closed,
                                                                NULL,:p_as_of_date_from)
                               *  ps.acctd_amount_due_remaining) acctd_start_bal,
                             sum(ar_calc_aging.begin_or_end_bal(gl_date,gl_date_closed,
                                                                NULL,:p_as_of_date_to)
                               *  ps.acctd_amount_due_remaining) acctd_end_bal
                       FROM  '||l_ps_table||' ps
                       WHERE ps.payment_schedule_id+0 > 0
                       AND   ps.class  = ''BR''
                       AND   ps.gl_date        <= :p_as_of_date_to
                       AND   ps.gl_date_closed  >= :p_as_of_date_from
                       '||   l_ps_org_where ||'
                       GROUP BY ps.customer_trx_id ';

  l_br_app_select :=  ' SELECT
                              ps.customer_trx_id ,
                              sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                  ra.gl_date,:p_as_of_date_from)
                                *(ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                       + NVL(ra.unearned_discount_taken,0))) start_bal,
                              sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   ra.gl_date,:p_as_of_date_to)
                                *(ra.amount_applied  + NVL(ra.earned_discount_taken,0)
                                       + NVL(ra.unearned_discount_taken,0))) end_bal,
                              sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   ra.gl_date,:p_as_of_date_from)
                                *(ra.acctd_amount_applied_to + NVL(ra.acctd_earned_discount_taken,0)
                                        + NVL(ra.acctd_unearned_discount_taken,0))) acctd_start_bal,
                              sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   ra.gl_date,:p_as_of_date_to)
                                *(ra.acctd_amount_applied_to + NVL(ra.acctd_earned_discount_taken,0)
                                        + NVL(ra.acctd_unearned_discount_taken,0))) acctd_end_bal
                         FROM '|| l_ps_table||' ps,
                            '|| l_ra_table||' ra
                         WHERE ra.applied_payment_schedule_id = ps.payment_schedule_id
                          AND  ps.payment_schedule_id+0 > 0
                          AND  ps.class  =''BR''
                          AND  ra.gl_date > :p_as_of_date_from
                          AND  ra.status = ''APP''
                          AND  ps.gl_date <= :p_as_of_date_to
                          AND  ps.gl_date_closed  >= :p_as_of_date_from
                          AND  NVL(ra.confirmed_flag,''Y'') = ''Y''
                          '||  l_ps_org_where ||'
                          '||  l_ra_org_where ||'
                        GROUP by ps.customer_trx_id ';

  l_br_adj_select:=  ' SELECT ps.customer_trx_id,
                         -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   adj.gl_date,:p_as_of_date_from)
                                * adj.amount) start_bal,
                         -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   adj.gl_date,:p_as_of_date_to)
                                * adj.amount) end_bal,
                         -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   adj.gl_date,:p_as_of_date_from)
                                * adj.acctd_amount) acctd_start_bal,
                         -sum(ar_calc_aging.begin_or_end_bal(ps.gl_date,ps.gl_date_closed,
                                                                   adj.gl_date,:p_as_of_date_to)
                                * adj.acctd_amount) acctd_end_bal
                       FROM  '|| l_adj_table ||' adj,
                             '|| l_ps_table  ||' ps
                       WHERE ps.payment_schedule_id + 0 > 0
                       AND   ps.class  = ''BR''
                       AND   adj.payment_schedule_id = ps.payment_schedule_id
                       AND   adj.gl_date > :p_as_of_date_from
                       AND   ps.gl_date        <= :p_as_of_date_to
                       AND   ps.gl_date_closed >= :p_as_of_date_from
                       AND   adj.status = ''A''
                       '||   l_adj_org_where||'
                       '||   l_ps_org_where ||'
                       GROUP BY ps.customer_trx_id ';

     IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
--         l_unapp_select := 'SELECT /*+ full(ps) full(ra) use_hash(ps ra) parallel(ps) */
-- Added the below line for performance issue - Defect 3947
         l_unapp_select := 'SELECT /*+ index(ps AR_PAYMENT_SCHEDULES_N9) */
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_from)
                              * ra.amount_applied) ,0 ) start_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_to)
                              * ra.amount_applied) ,0)  end_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_from)
                              * ra.acctd_amount_applied_from) ,0 ) acctd_start_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_to)
                              * ra.acctd_amount_applied_from) ,0) acctd_end_bal
                      FROM  '|| l_ps_table ||' ps,
                            '|| l_ra_table ||' ra,
                             gl_code_combinations gc
                     WHERE  ra.gl_date  <= :p_as_of_date_to
                       AND  ps.cash_receipt_id = ra.cash_receipt_id
                       AND  ra.status in ( ''ACC'', ''UNAPP'', ''UNID'', ''OTHER ACC'' )
                       AND  nvl(ra.confirmed_flag, ''Y'') = ''Y''
                       AND  ps.class = ''PMT''
                       AND  ps.gl_date_closed >= :p_as_of_date_from
                       AND  nvl( ps.receipt_confirmed_flag, ''Y'' ) = ''Y''
                       AND  gc.code_combination_id = ra.code_combination_id
                       ' || l_ps_org_where ||'
                       ' || l_ra_org_where || '
                       ' || company_segment_where;
     ELSE
--         l_unapp_select := 'SELECT /*+ full(ps) full(ra) use_hash(ps ra) parallel(ps) */
-- Added the below line for performance issue - Defect 3947
         l_unapp_select := 'SELECT /*+ index(ps AR_PAYMENT_SCHEDULES_N9) */
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_from)
                              * ra.amount_applied) ,0 ) start_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_to)
                              * ra.amount_applied) ,0)  end_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_from)
                              * ra.acctd_amount_applied_from) ,0 ) acctd_start_bal,
                            NVL(-sum(ar_calc_aging.begin_or_end_bal(ra.gl_date,gl_date_closed,
                                                           NULL,:p_as_of_date_to)
                              * ra.acctd_amount_applied_from) ,0) acctd_end_bal
                      FROM  '|| l_ps_table ||' ps,
                            '|| l_ra_table ||' ra
                     WHERE  ra.gl_date  <= :p_as_of_date_to
                       AND  ps.cash_receipt_id = ra.cash_receipt_id
                       AND  ra.status in ( ''ACC'', ''UNAPP'', ''UNID'', ''OTHER ACC'' )
                       AND  nvl(ra.confirmed_flag, ''Y'') = ''Y''
                       AND  ps.class = ''PMT''
                       AND  ps.gl_date_closed >= :p_as_of_date_from
                       AND  nvl( ps.receipt_confirmed_flag, ''Y'' ) = ''Y''
                       ' || l_ps_org_where ||'
                       ' || l_ra_org_where ;
    END IF;
/*bug 7287425 logic change to divide sql among different worker based on no of worker.
   Scaling of sqls in this rutine are upto 5 workers only as per sql*/
IF p_total_workers = 0 THEN
  l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                      '||l_ps_select ||'
                         UNION ALL
                         '||l_ra_select ||'
                         UNION ALL
                         '||l_cm_ra_select ||'
                         UNION ALL
                         '||l_adj_select ||'
                     ) ps ';
ELSE
IF p_worker_number = 1 THEN
 l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_ps_select ||'
                     ) ps ';
ELSIF p_worker_number = 2 THEN
 l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_ra_select ||'
                     ) ps ';
ELSIF p_worker_number = 3 THEN
 l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_cm_ra_select ||'
                     ) ps ';
ELSIF p_worker_number = 4 THEN
 l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_adj_select ||'
                     ) ps ';
ELSIF p_worker_number = 5 THEN
 l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_unapp_select ||'
                     ) ps ';
END IF;
END IF;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_trx_main_select := l_trx_main_select || ', '|| l_gl_dist_table ||' gl_dist,
                         gl_code_combinations gc
                  where gl_dist.customer_trx_id = ps.customer_trx_id
                  and   gl_dist.account_class  =''REC''
                  and   gl_dist.latest_rec_flag  =''Y''
                  and   gl_dist.code_combination_id = gc.code_combination_id
                  ' || l_gl_dist_org_where ||'
                  ' || company_segment_where ;
  END IF;
    l_br_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '||l_br_select ||'
                         UNION ALL
                         '||l_br_app_select ||'
                         UNION ALL
                         '||l_br_adj_select ||'
                              ) ps ';
    IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
       l_br_main_select := l_br_main_select || ' , ar_transaction_history_all ath,
                             '|| l_ard_table ||' ard,
                             gl_code_combinations gc
                      WHERE  ps.customer_trx_id = ath.customer_trx_id
                      AND    ath.status = ''PENDING_REMITTANCE''
                      AND    ath.event in (''COMPLETED'',''ACCEPTED'')
                      AND    ard.source_id = ath.transaction_history_id
                      AND    ard.source_table  = ''TH''
                      AND    ard.source_type = ''REC''
                      AND    ard.source_id_secondary IS NULL
                      AND    ard.source_table_secondary IS NULL
                      AND    ard.source_type_secondary IS NULL
                      AND    gc.code_combination_id = ard.code_combination_id
                      '||    l_ath_org_where ||'
                      '||    l_ard_org_where ||'
                      '||    company_segment_where ;
    END IF;

IF p_total_workers = 0 THEN
    IF nvl(br_enabled_flag,'N')  = 'Y' THEN
          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                           FROM ('|| l_trx_main_select ||' UNION ALL '||
                                     l_br_main_select  ||'
                                   UNION ALL
                                '|| l_unapp_select    ||' UNION ALL
                                '|| l_cancel_br_select|| ') ';
    ELSE


          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM ('|| l_trx_main_select ||' UNION ALL
                                  '|| l_unapp_select
                                   || ') ';

    END IF;
ELSE
IF ( p_worker_number <= 5) THEN
    IF p_worker_number <> 0 THEN
	l_main_select := l_trx_main_select;
    ELSE
        IF p_total_workers = 1 THEN
        l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                      '||l_ra_select ||'
                         UNION ALL
                         '||l_cm_ra_select ||'
                         UNION ALL
                         '||l_adj_select ||'
                     ) ps ';


        ELSIF p_total_workers = 2 THEN
        l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '|| l_cm_ra_select ||'
                         UNION ALL
                         '||l_adj_select ||'
                     ) ps ';


        ELSIF p_total_workers = 3 THEN
        l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '|| l_adj_select ||'
                     ) ps ';

        ELSIF p_total_workers = 4 THEN
        l_trx_main_select := NULL;
        /*l_trx_main_select := '
                      SELECT sum(start_bal) start_bal,
                             sum(end_bal) end_bal,
                             sum(acctd_start_bal)acctd_start_bal ,
                             sum(acctd_end_bal) acctd_end_bal
                      FROM (
                         '|| l_adj_select ||'
                     ) ps '; */

        ELSIF p_total_workers = 5 THEN
        l_trx_main_select := NULL;

        END IF;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_trx_main_select := l_trx_main_select || ', '|| l_gl_dist_table ||' gl_dist,
                         gl_code_combinations gc
                  where gl_dist.customer_trx_id = ps.customer_trx_id
                  and   gl_dist.account_class  =''REC''
                  and   gl_dist.latest_rec_flag  =''Y''
                  and   gl_dist.code_combination_id = gc.code_combination_id
                  ' || l_gl_dist_org_where ||'
                  ' || company_segment_where ;
  END IF;
--naneja
  IF p_total_workers < 4 THEN
    IF nvl(br_enabled_flag,'N')  = 'Y' THEN

          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM ('|| l_trx_main_select ||' UNION ALL '|| l_br_main_select  ||
				     ' UNION ALL '|| l_unapp_select||
				     ' UNION ALL '|| l_cancel_br_select||') ';

    ELSE
          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM ('|| l_trx_main_select ||' UNION ALL
                                  '|| l_unapp_select
                                   || ') ';

    END IF;
  ELSE
  IF p_total_workers = 4 THEN
    IF nvl(br_enabled_flag,'N')  = 'Y' THEN
          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM ( '||l_br_main_select  ||
                                     ' UNION ALL '|| l_unapp_select||
                                     ' UNION ALL '|| l_cancel_br_select||') ';

    ELSE

          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM (
                                  '|| l_unapp_select
                                   || ') ';
    END IF;
  END IF;
  IF p_total_workers >= 5 THEN  /*Handling case of BR enabled in case workers >=5 */
    IF nvl(br_enabled_flag,'N')  = 'Y' THEN
          l_main_select := 'SELECT sum(start_bal) start_bal,
                                   sum(end_bal) end_bal,
                                   sum(acctd_start_bal) acctd_start_bal ,
                                   sum(acctd_end_bal) acctd_end_bal
                            FROM ( '||l_br_main_select  ||
                                     ' UNION ALL '|| l_cancel_br_select || ')';
    END IF;
  END IF;
  END IF;

END IF;

END IF;
END IF;
IF ( p_worker_number <= 5) then
IF p_worker_number = 0 AND p_total_workers >= 5 AND nvl(br_enabled_flag,'N')  = 'N' THEN
p_begin_bal := 0;
p_end_bal := 0;
p_acctd_begin_bal := 0;
p_acctd_end_bal := 0;
ELSE
    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_main_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':p_as_of_date_from', p_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':p_as_of_date_to', p_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_begin_bal);
    dbms_sql.define_column(v_cursor, 2, p_end_bal);
    dbms_sql.define_column(v_cursor, 3, p_acctd_begin_bal);
    dbms_sql.define_column(v_cursor, 4, p_acctd_end_bal);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_begin_bal);
         dbms_sql.column_value(v_cursor, 2, p_end_bal);
         dbms_sql.column_value(v_cursor, 3, p_acctd_begin_bal);
         dbms_sql.column_value(v_cursor, 4, p_acctd_end_bal);
      ELSE
         EXIT;
      END IF;
   END LOOP;

  dbms_sql.close_cursor(v_cursor);
END IF;
END IF;
/*Insertion in temp table for summing up later bug 7287425*/
IF p_worker_number = 0 THEN
COMMIT;
l_request:=   fnd_global.conc_request_id;
		insert into AR_RECONCILIATION values(
		l_request,
		l_request,
		'AGING_AS_OF',
		p_begin_bal,
		p_end_bal,
            	p_acctd_begin_bal,
            	p_acctd_end_bal,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null);
	  COMMIT;
 END IF;

END aging_as_of;

/*-----------------------------------------------------------
 PUBLIC PROCEDURE adjustment_register
-------------------------------------------------------------*/
/*Added and changed parameter to divide among workers based on gl date bug 7287425*/
PROCEDURE adjustment_register(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                              p_reporting_level        IN  VARCHAR2,
                              p_reporting_entity_id    IN  NUMBER,
                              p_co_seg_low             IN  VARCHAR2,
                              p_co_seg_high            IN  VARCHAR2,
                              p_coa_id                 IN  NUMBER,
                              p_fin_chrg_amount        OUT NOCOPY NUMBER,
                              p_fin_chrg_acctd_amount  OUT NOCOPY NUMBER,
                              p_adj_amount             OUT NOCOPY NUMBER,
                              p_adj_acctd_amount       OUT NOCOPY NUMBER,
                              p_guar_amount            OUT NOCOPY NUMBER,
                              p_guar_acctd_amount      OUT NOCOPY NUMBER,
                              p_dep_amount             OUT NOCOPY NUMBER,
                              p_dep_acctd_amount       OUT NOCOPY NUMBER,
                              p_endorsmnt_amount       OUT NOCOPY NUMBER,
                              p_endorsmnt_acctd_amount OUT NOCOPY NUMBER,
			      p_worker_number            IN NUMBER DEFAULT 1,
		      	      p_total_workers            IN NUMBER DEFAULT 1) IS


 l_main_select              VARCHAR2(10000);
 l_endorsement_select       VARCHAR2(5000);
 v_cursor                   NUMBER;
 l_ignore                   INTEGER;
 l_as_of_date_from          DATE;
 l_as_of_date_to            DATE;

BEGIN

  /* AR Reconciliation Process Enhancements : Procedure is completely re-written */

    build_parameters (p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id);
    IF NVL(p_total_workers,1) <= 1 then
      l_as_of_date_from := p_as_of_date_from;
      l_as_of_date_to := p_as_of_date_to;
    ELSE
      IF p_total_workers = p_worker_number then
	  l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;

	  l_as_of_date_to:= p_as_of_date_to;
      ELSE
        IF p_worker_number = 1 then
	   l_as_of_date_from := p_as_of_date_from;
	   l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)));
        ELSE
	  l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;
	  l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)*(p_worker_number)));
        END IF;
      END IF;
    END IF;

    l_main_select := '
            SELECT sum(decode(rec.type,''FINCHRG'', adj.amount,0)) fin_amount,
                   sum(decode(rec.type,''FINCHRG'', adj.acctd_amount,0)) fin_acctd_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',0,
                                  decode(adj.receivables_trx_id,-15,0, adj.amount)))) Adj_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',0,
                                decode(adj.receivables_trx_id,-15,0, adj.acctd_amount)))) Adj_acctd_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',
                                  decode(type.type,''GUAR'',adj.amount,0)))) Guar_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',
                                  decode(type.type,''GUAR'',adj.acctd_amount,0)))) Guar_acctd_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',
                                  decode(type.type,''GUAR'',0,adj.amount)))) Dep_amount,
                   sum(decode(rec.type,''ADJUST'',
                                decode(adj.adjustment_type,''C'',
                                  decode(type.type,''GUAR'',0,adj.acctd_amount)))) Dep_acctd_amount
           FROM   '||l_adj_table||' adj,
                  ar_receivables_trx_all rec,
                  '||l_trx_table||' trx,
                  ra_cust_trx_types_all type ';
   IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
           l_main_select := l_main_select || ',
                  '||l_gl_dist_table||' gl_dist,
                  gl_code_combinations gc ';
   END IF;
    l_main_select := l_main_select ||'
           WHERE  nvl(adj.status, ''A'') = ''A''
           AND    adj.receivables_trx_id <> -15
           AND    adj.receivables_trx_id = rec.receivables_trx_id
           AND    nvl(rec.org_id,-99) = nvl(adj.org_id,-99)
           AND    adj.gl_date between :gl_date_low and :gl_date_high
           AND    trx.customer_trx_id = adj.customer_trx_id
           AND    trx.complete_flag = ''Y''
           AND    trx.cust_trx_type_id =  type.cust_trx_type_id
           AND    nvl(type.org_id,-99) = nvl(trx.org_id,-99)
           '||    l_adj_org_where ||'
           '||    l_trx_org_where ;

   IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
           l_main_select := l_main_select ||'
           AND    adj.customer_trx_id = gl_dist.customer_trx_id
           AND    gl_dist.account_class = ''REC''
           AND    gl_dist.latest_rec_flag = ''Y''
           AND    gc.code_combination_id = gl_dist.code_combination_id
           '||    l_gl_dist_org_where ||'
           '|| company_segment_where;
   END IF;
    l_endorsement_select := 'SELECT
                             sum(adj.amount) Endsmnt_amount,
                             sum(adj.acctd_amount) Endrsmnt_acctd_amount
                             FROM   '||l_adj_table||' adj,
                                    ar_receivables_trx_all rec';
   IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
      l_endorsement_select := l_endorsement_select || ' ,
                                    ar_transaction_history_all ath ';
   END IF;
    l_endorsement_select := l_endorsement_select ||'
                             WHERE  nvl(adj.status, ''A'') = ''A''
                             AND    adj.receivables_trx_id <> -15
                             AND    adj.receivables_trx_id = rec.receivables_trx_id
                             AND    nvl(adj.org_id,-99) = nvl(rec.org_id,-99)
                             AND    rec.type = ''ENDORSEMENT''
                             AND    adj.gl_date between :gl_date_low and :gl_date_high
                             '||    l_adj_org_where ;
  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
      l_endorsement_select := l_endorsement_select || '
                             AND    adj.customer_trx_id = ath.customer_trx_id
                             AND    ath.status = ''PENDING_REMITTANCE''
                             AND    ath.event in (''COMPLETED'',''ACCEPTED'')
                             '||    l_ath_org_where ||'
                             AND    exists (SELECT line_id
                                            FROM   '|| l_ard_table ||' ard,
                                                   gl_code_combinations gc
                                            WHERE  ard.source_id = ath.transaction_history_id
                                            AND    ard.source_table  = ''TH''
                                            AND    ard.source_type = ''REC''
                                            AND    ard.source_id_secondary IS NULL
                                            AND    ard.source_table_secondary IS NULL
                                            AND    ard.source_type_secondary IS NULL
                                            AND    gc.code_combination_id = ard.code_combination_id
                                            '|| l_ard_org_where ||'
                                            '||company_segment_where||')';
  END IF;

    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_main_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_fin_chrg_amount);
    dbms_sql.define_column(v_cursor, 2, p_fin_chrg_acctd_amount);
    dbms_sql.define_column(v_cursor, 3, p_adj_amount);
    dbms_sql.define_column(v_cursor, 4, p_adj_acctd_amount);
    dbms_sql.define_column(v_cursor, 5, p_guar_amount);
    dbms_sql.define_column(v_cursor, 6, p_guar_acctd_amount);
    dbms_sql.define_column(v_cursor, 7, p_dep_amount);
    dbms_sql.define_column(v_cursor, 8, p_dep_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_fin_chrg_amount);
         dbms_sql.column_value(v_cursor, 2, p_fin_chrg_acctd_amount);
         dbms_sql.column_value(v_cursor, 3, p_adj_amount);
         dbms_sql.column_value(v_cursor, 4, p_adj_acctd_amount);
         dbms_sql.column_value(v_cursor, 5, p_guar_amount);
         dbms_sql.column_value(v_cursor, 6, p_guar_acctd_amount);
         dbms_sql.column_value(v_cursor, 7, p_dep_amount);
         dbms_sql.column_value(v_cursor, 8, p_dep_acctd_amount);
      ELSE
         EXIT;
      END IF;
   END LOOP;

   IF nvl(br_enabled_flag,'N')  = 'Y' THEN
      dbms_sql.parse(v_cursor,l_endorsement_select,DBMS_SQL.NATIVE);

      dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
      dbms_sql.bind_variable(v_cursor, ':gl_date_high',l_as_of_date_to);

      dbms_sql.define_column(v_cursor, 1, p_endorsmnt_amount);
      dbms_sql.define_column(v_cursor, 2, p_endorsmnt_acctd_amount);

      l_ignore := dbms_sql.execute(v_cursor);

      LOOP
         IF dbms_sql.fetch_rows(v_cursor) > 0 then
            dbms_sql.column_value(v_cursor, 1, p_endorsmnt_amount);
            dbms_sql.column_value(v_cursor, 2, p_endorsmnt_acctd_amount);
         ELSE
            EXIT;
         END IF;
      END LOOP;
   END IF;

  dbms_sql.close_cursor(v_cursor);

END adjustment_register  ;

/*-----------------------------------------------------------
 PUBLIC PROCEDURE transaction_register
-------------------------------------------------------------*/
/*Added and changed parameter to divide among workers based on gl date bug 7287425*/
PROCEDURE transaction_register(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                               p_reporting_level          IN  VARCHAR2,
                               p_reporting_entity_id      IN  NUMBER,
                               p_co_seg_low               IN  VARCHAR2,
                               p_co_seg_high              IN  VARCHAR2,
                               p_coa_id                   IN  NUMBER,
                               p_non_post_amount          OUT NOCOPY NUMBER,
                               p_non_post_acctd_amount    OUT NOCOPY NUMBER,
                               p_post_amount              OUT NOCOPY NUMBER ,
                               p_post_acctd_amount        OUT NOCOPY NUMBER ,
	 		       p_worker_number            IN NUMBER DEFAULT 1,
			       p_total_workers            IN NUMBER DEFAULT 1) IS


 l_post_select              VARCHAR2(2000);
 l_non_post_select          VARCHAR2(2000);
 v_cursor                   NUMBER;
 l_ignore                   INTEGER;

 l_as_of_date_from          DATE;
 l_as_of_date_to            DATE;


BEGIN

    /* AR Reconciliation Process Enhancements:  The procedure is completely modified */
    build_parameters (p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id);
    IF NVL(p_total_workers,1) <= 1 then
      l_as_of_date_from := p_as_of_date_from;
      l_as_of_date_to := p_as_of_date_to;
    ELSE
      IF p_total_workers = p_worker_number then
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;

          l_as_of_date_to:= p_as_of_date_to;
      ELSE
        IF p_worker_number = 1 then
           l_as_of_date_from := p_as_of_date_from;
           l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)));
        ELSE
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;
          l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)*(p_worker_number)));
        END IF;
      END IF;
    END IF;
fnd_file.put_line(fnd_file.log,'from Date:'||l_as_of_date_from);
fnd_file.put_line(fnd_file.log,'To Date:'||l_as_of_date_to);

    IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
        l_post_select := '
                      SELECT
                         NVL(SUM(NVL(gl_dist.amount,0)),0)       Invoice_Currency,
                         NVL(SUM(NVL(gl_dist.acctd_amount,0)),0) Functional_Currency
                      FROM ra_cust_trx_types_all type,
                           '||l_trx_table||'         trx,
                           '||l_gl_dist_table||' gl_dist,
                           gl_code_combinations gc
                      WHERE   gl_dist.gl_date BETWEEN :gl_date_low AND :gl_date_high
                      AND     gl_dist.gl_date IS NOT NULL
                      AND     gl_dist.account_class   = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     type.cust_trx_type_id   = trx.cust_trx_type_id
                      AND     trx.complete_flag       = ''Y''
                      AND     type.type  in (''INV'',''DEP'',''GUAR'', ''CM'',''DM'', ''CB'' )
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     gc.code_combination_id = gl_dist.code_combination_id
                      '||l_gl_dist_org_where ||'
                      '||l_trx_org_where ||'
                      '||company_segment_where;
         l_non_post_select := '
                      SELECT
                         NVL(SUM(NVL(gl_dist.amount,0)),0)       Invoice_Currency,
                         NVL(SUM(NVL(gl_dist.acctd_amount,0)),0) Functional_Currency
                      FROM ra_cust_trx_types_all type,
                           '||l_trx_table||'         trx,
                           '||l_gl_dist_table||' gl_dist,
                           gl_code_combinations gc
                      WHERE   trx.trx_date  BETWEEN :gl_date_low AND :gl_date_high
                      AND     gl_dist.gl_date IS NULL
                      AND     gl_dist.account_class   = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     type.cust_trx_type_id   = trx.cust_trx_type_id
                      AND     trx.complete_flag       = ''Y''
                      AND     type.type  in (''INV'',''DEP'',''GUAR'', ''CM'',''DM'', ''CB'' )
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     gc.code_combination_id = gl_dist.code_combination_id
                      '||l_gl_dist_org_where ||'
                      '||l_trx_org_where ||'
                      '||company_segment_where;
    ELSE
        l_post_select := '
                      SELECT
                         NVL(SUM(NVL(gl_dist.amount,0)),0)       Invoice_Currency,
                         NVL(SUM(NVL(gl_dist.acctd_amount,0)),0) Functional_Currency
                      FROM ra_cust_trx_types_all type,
                           '||l_trx_table||'         trx,
                           '||l_gl_dist_table||' gl_dist
                      WHERE   gl_dist.gl_date BETWEEN :gl_date_low AND :gl_date_high
                      AND     gl_dist.gl_date IS NOT NULL
                      AND     gl_dist.account_class   = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     type.cust_trx_type_id   = trx.cust_trx_type_id
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     trx.complete_flag       = ''Y''
                      AND     type.type  in (''INV'',''DEP'',''GUAR'', ''CM'',''DM'', ''CB'' )
                      '||l_gl_dist_org_where ||'
                      '||l_trx_org_where;
         l_non_post_select := '
                      SELECT
                         NVL(SUM(NVL(gl_dist.amount,0)),0)       Invoice_Currency,
                         NVL(SUM(NVL(gl_dist.acctd_amount,0)),0) Functional_Currency
                      FROM ra_cust_trx_types_all type,
                           '||l_trx_table||'         trx,
                           '||l_gl_dist_table||' gl_dist
                      WHERE   trx.trx_date  BETWEEN :gl_date_low AND :gl_date_high
                      AND     gl_dist.gl_date IS NULL
                      AND     gl_dist.account_class   = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     type.cust_trx_type_id   = trx.cust_trx_type_id
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     trx.complete_flag       = ''Y''
                      AND     type.type  in (''INV'',''DEP'',''GUAR'', ''CM'',''DM'', ''CB'' )
                      '||l_gl_dist_org_where ||'
                      '||l_trx_org_where;
    END IF;

    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_post_select ,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_post_amount);
    dbms_sql.define_column(v_cursor, 2, p_post_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_post_amount);
         dbms_sql.column_value(v_cursor, 2, p_post_acctd_amount);
      ELSE
         EXIT;
      END IF;
   END LOOP;

    dbms_sql.parse(v_cursor,l_non_post_select ,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_non_post_amount);
    dbms_sql.define_column(v_cursor, 2, p_non_post_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_non_post_amount);
         dbms_sql.column_value(v_cursor, 2, p_non_post_acctd_amount);
      ELSE
         EXIT;
      END IF;
   END LOOP;

   dbms_sql.close_cursor(v_cursor);

END transaction_register ;

/*-------------------------------------------------
PUBLIC PROCEDURE rounding_diff
--------------------------------------------------*/

PROCEDURE rounding_diff(l_gl_date_low   IN DATE,
                        l_gl_date_high  IN DATE,
                        l_rounding_diff OUT NOCOPY NUMBER ) IS
BEGIN

    /*
     * Bug fix: 2498344
     *   MRC enhancements to select data from reporting book
     *   please refer to bug for more details.
     *   we need to execute different selects depending on the book
     *   for which report is run
     */


   -- For Zero Amount Transactions , sometimes the acctd_amount is
   -- derived as 0.01 or 0.02.

  IF NVL(ar_calc_aging.ca_sob_type,'P') = 'P'
  THEN
    SELECT NVL(SUM(NVL(acctd_amount,0)),0)
    INTO   l_rounding_diff
    FROM   ra_cust_trx_line_gl_dist
    WHERE  amount = 0
    AND    gl_date BETWEEN l_gl_date_low AND l_gl_date_high ;
  ELSE
    SELECT NVL(SUM(NVL(acctd_amount,0)),0)
    INTO   l_rounding_diff
    FROM   ra_trx_line_gl_dist_mrc_v
    WHERE  amount = 0
    AND    gl_date BETWEEN l_gl_date_low AND l_gl_date_high ;
  END IF;

END rounding_diff ;


/*------------------------------------------------
PUBLIC PROCEDURE cash_receipt_register
--------------------------------------------------*/
-- Calculate  Applied, Unapplied and CM gain/loss amounts
--
/*Added and changed parameter to divide among workers based on gl date bug 7287425*/
PROCEDURE cash_receipts_register(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                                 p_reporting_level       IN  VARCHAR2,
                                 p_reporting_entity_id   IN  NUMBER,
                                 p_co_seg_low            IN  VARCHAR2,
                                 p_co_seg_high           IN  VARCHAR2,
                                 p_coa_id                IN  NUMBER,
                                 p_unapp_amount          OUT NOCOPY NUMBER,
                                 p_unapp_acctd_amount    OUT NOCOPY NUMBER,
                                 p_acc_amount            OUT NOCOPY NUMBER,
                                 p_acc_acctd_amount      OUT NOCOPY NUMBER,
                                 p_claim_amount          OUT NOCOPY NUMBER,
                                 p_claim_acctd_amount    OUT NOCOPY NUMBER,
                                 p_prepay_amount         OUT NOCOPY NUMBER,
                                 p_prepay_acctd_amount   OUT NOCOPY NUMBER,
                                 p_app_amount            OUT NOCOPY NUMBER,
                                 p_app_acctd_amount      OUT NOCOPY NUMBER,
                                 p_edisc_amount          OUT NOCOPY NUMBER,
                                 p_edisc_acctd_amount    OUT NOCOPY NUMBER,
                                 p_unedisc_amount        OUT NOCOPY NUMBER,
                                 p_unedisc_acctd_amount  OUT NOCOPY NUMBER,
                                 p_cm_gain_loss          OUT NOCOPY NUMBER,
                                 p_on_acc_cm_ref_amount  OUT NOCOPY NUMBER,  /*bug 4173702*/
                                 p_on_acc_cm_ref_acctd_amount OUT NOCOPY NUMBER,
      		   	         p_worker_number            IN NUMBER DEFAULT 1,
		  		 p_total_workers            IN NUMBER DEFAULT 1
					    ) IS


 l_main_select                VARCHAR2(20000);
 v_cursor                     NUMBER;
 l_ignore                     INTEGER;
 l_as_of_date_from          DATE;
 l_as_of_date_to            DATE;


BEGIN

    /* AR Reconciliation Process Enhancements : Procedure is completely re-written */
    build_parameters (p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id);
    IF NVL(p_total_workers,1) <= 1 then
      l_as_of_date_from := p_as_of_date_from;
      l_as_of_date_to := p_as_of_date_to;
    ELSE
      IF p_total_workers = p_worker_number then
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;

          l_as_of_date_to:= p_as_of_date_to;
      ELSE
        IF p_worker_number = 1 then
           l_as_of_date_from := p_as_of_date_from;
           l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)));
        ELSE
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;
          l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)*(p_worker_number)));
        END IF;
      END IF;
    END IF;
fnd_file.put_line(fnd_file.log,'from Date:'||l_as_of_date_from);
fnd_file.put_line(fnd_file.log,'To Date:'||l_as_of_date_to);


    l_main_select := 'SELECT   NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''ACC'',  ra.amount_applied,0)
                                    ,0)),0)  Onacc_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''ACC'',  ra.acctd_amount_applied_from,0)
                                    ,0)),0)  Onacc_acctd_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''OTHER ACC'', DECODE(ra.applied_payment_schedule_id,
                                                   -4, ra.amount_applied,0),0)
                                    ,0)),0) claim_amount,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''OTHER ACC'', DECODE(ra.applied_payment_schedule_id,
                                                   -4, ra.acctd_amount_applied_from,0),0)
                                    ,0)),0) claim_acctd_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''OTHER ACC'', DECODE(ra.applied_payment_schedule_id,
                                                   -7, ra.amount_applied,0),0)
                                    ,0)),0) prepay_amount,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''OTHER ACC'', DECODE(ra.applied_payment_schedule_id,
                                                   -7, ra.acctd_amount_applied_from,0),0)
                                    ,0)),0) prepay_acctd_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''UNAPP'',  ra.amount_applied,
                                    ''UNID'', ra.amount_applied,0)
                                    ,0)),0) unapp_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                    ''UNAPP'',  ra.acctd_amount_applied_from,
                                    ''UNID'', ra.acctd_amount_applied_from,0)
                                    ,0)),0)  unapp_acctd_amt,

             NVL(SUM(DECODE(ra.application_type,
                                ''CM'', DECODE(ra.amount_applied,0,0,
                                            ra.acctd_amount_applied_from)
                                    , 0)
                         ),0)  -
             NVL(SUM(DECODE(ra.application_type,
                                ''CM'', DECODE(ra.amount_applied,0,0,
                                             NVL(ra.acctd_amount_applied_to,0))
                                    , 0)
                         ),0)   cm_gain_loss,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                                           ra.amount_applied,0),0)),0) app_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                                      NVL(ra.earned_discount_taken,0),0),0)),0) edisc_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                                      NVL(ra.unearned_discount_taken,0),0),0)),0) unedisc_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                                      NVL(ra.acctd_amount_applied_to,0),0),0)),0) acctd_app_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                              NVL(ra.acctd_earned_discount_taken,0),0),0)),0) acctd_edisc_amt,
             NVL(SUM(DECODE(ra.application_type,
                              ''CASH'',
                                    DECODE(ra.status,
                                                ''APP'',
                            NVL(ra.acctd_unearned_discount_taken,0),0),0)),0) acctd_unedisc_amt,
               NVL(SUM(DECODE(ra.application_type,     /*bug 4173702*/
                              ''CM'',
                                    DECODE(ra.status,
                                    ''ACTIVITY'', DECODE(ra.applied_payment_schedule_id,
                                                   -8, ra.amount_applied,0),0)
                                    ,0)),0) onacc_cm_ref_amount,
               NVL(SUM(DECODE(ra.application_type,
                              ''CM'',
                                    DECODE(ra.status,
                                    ''ACTIVITY'', DECODE(ra.applied_payment_schedule_id,
                                                   -8, ra.acctd_amount_applied_to,0),0)
                                    ,0)),0) onacc_cm_ref_acctd_amount


    FROM  '|| l_ra_table || ' ra ';

    IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
        l_main_select := l_main_select || ',
                         gl_code_combinations gc ';
    END IF;
    l_main_select  := l_main_select || '
          WHERE  NVL(ra.confirmed_flag,''Y'') = ''Y''
          AND   ra.gl_date BETWEEN :gl_date_low  AND :gl_date_high
          '||   l_ra_org_where;

    IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
       l_main_select := l_main_select || '
          AND gc.code_combination_id = ra.code_combination_id
         '|| company_segment_where;
    END IF;

    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_main_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_acc_amount);
    dbms_sql.define_column(v_cursor, 2, p_acc_acctd_amount);
    dbms_sql.define_column(v_cursor, 3, p_claim_amount);
    dbms_sql.define_column(v_cursor, 4, p_claim_acctd_amount);
    dbms_sql.define_column(v_cursor, 5, p_prepay_amount);
    dbms_sql.define_column(v_cursor, 6, p_prepay_acctd_amount);
    dbms_sql.define_column(v_cursor, 7, p_unapp_amount);
    dbms_sql.define_column(v_cursor, 8, p_unapp_acctd_amount);
    dbms_sql.define_column(v_cursor, 9, p_cm_gain_loss);
    dbms_sql.define_column(v_cursor, 10, p_app_amount);
    dbms_sql.define_column(v_cursor, 11, p_edisc_amount);
    dbms_sql.define_column(v_cursor, 12, p_unedisc_amount);
    dbms_sql.define_column(v_cursor, 13, p_app_acctd_amount);
    dbms_sql.define_column(v_cursor, 14, p_edisc_acctd_amount);
    dbms_sql.define_column(v_cursor, 15, p_unedisc_acctd_amount);
    dbms_sql.define_column(v_cursor, 16, p_on_acc_cm_ref_amount);  /*bug4173702*/
    dbms_sql.define_column(v_cursor, 17, p_on_acc_cm_ref_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
          dbms_sql.column_value(v_cursor, 1, p_acc_amount);
          dbms_sql.column_value(v_cursor, 2, p_acc_acctd_amount);
          dbms_sql.column_value(v_cursor, 3, p_claim_amount);
          dbms_sql.column_value(v_cursor, 4, p_claim_acctd_amount);
          dbms_sql.column_value(v_cursor, 5, p_prepay_amount);
          dbms_sql.column_value(v_cursor, 6, p_prepay_acctd_amount);
          dbms_sql.column_value(v_cursor, 7, p_unapp_amount);
          dbms_sql.column_value(v_cursor, 8, p_unapp_acctd_amount);
          dbms_sql.column_value(v_cursor, 9, p_cm_gain_loss);
          dbms_sql.column_value(v_cursor, 10, p_app_amount);
          dbms_sql.column_value(v_cursor, 11, p_edisc_amount);
          dbms_sql.column_value(v_cursor, 12, p_unedisc_amount);
          dbms_sql.column_value(v_cursor, 13, p_app_acctd_amount);
          dbms_sql.column_value(v_cursor, 14, p_edisc_acctd_amount);
          dbms_sql.column_value(v_cursor, 15, p_unedisc_acctd_amount);
          dbms_sql.column_value(v_cursor, 16, p_on_acc_cm_ref_amount);    /*bug4173702*/
          dbms_sql.column_value(v_cursor, 17, p_on_acc_cm_ref_acctd_amount);
      ELSE
         EXIT;
      END IF;
    END LOOP;

   dbms_sql.close_cursor(v_cursor);

END cash_receipts_register ;

/*------------------------------------------------
PUBLIC PROCEDURE invoice_exception
--------------------------------------------------*/
/*Added and changed parameter to divide among workers based on gl date bug 7287425*/
PROCEDURE invoice_exceptions(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                              p_reporting_level             IN  VARCHAR2,
                              p_reporting_entity_id         IN  NUMBER,
                              p_co_seg_low                  IN  VARCHAR2,
                              p_co_seg_high                 IN  VARCHAR2,
                              p_coa_id                      IN  NUMBER,
                              p_post_excp_amount            OUT NOCOPY NUMBER,
                              p_post_excp_acctd_amount      OUT NOCOPY NUMBER,
                              p_nonpost_excp_amount         OUT NOCOPY NUMBER,
                              p_nonpost_excp_acctd_amount   OUT NOCOPY NUMBER,
                              p_worker_number            IN NUMBER DEFAULT 1,
                              p_total_workers            IN NUMBER DEFAULT 1
                                            ) IS

 l_post_select              VARCHAR2(10000);
 l_non_post_select          VARCHAR2(10000);
 v_cursor                   NUMBER;
 l_ignore                   INTEGER;

 l_as_of_date_from          DATE;
 l_as_of_date_to            DATE;

BEGIN

    build_parameters (p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id);

    IF NVL(p_total_workers,1) <= 1 then
      l_as_of_date_from := p_as_of_date_from;
      l_as_of_date_to := p_as_of_date_to;
    ELSE
      IF p_total_workers = p_worker_number then
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;

          l_as_of_date_to:= p_as_of_date_to;
      ELSE
        IF p_worker_number = 1 then
           l_as_of_date_from := p_as_of_date_from;
           l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)));
        ELSE
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;
          l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)*(p_worker_number)));
        END IF;
      END IF;
    END IF;
fnd_file.put_line(fnd_file.log,'from Date:'||l_as_of_date_from);
fnd_file.put_line(fnd_file.log,'To Date:'||l_as_of_date_to);


    l_post_select := '
                      SELECT
                        NVL(SUM(NVL(gl_dist.amount,0)),0) ,
                        NVL(SUM(NVL(gl_dist.acctd_amount,0)),0)
                      FROM
                        ra_cust_trx_types_all   type,
                        '||l_trx_table||'   trx,
                        '||l_gl_dist_table||'  gl_dist ';
    l_non_post_select := '
                      SELECT
                        NVL(SUM(NVL(gl_dist.amount,0)),0) ,
                        NVL(SUM(NVL(gl_dist.acctd_amount,0)),0)
                      FROM
                        ra_cust_trx_types_all  type,
                        '||l_trx_table||'  trx,
                        '||l_gl_dist_table||'  gl_dist ';

    IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
       l_post_select := l_post_select ||',
                        gl_code_combinations gc ';
       l_non_post_select := l_non_post_select ||',
                        gl_code_combinations gc ';
    END IF;

    l_post_select := l_post_select || '
                      WHERE   trx.complete_flag = ''Y''
                      AND     NOT EXISTS ( SELECT ''x''
                                            FROM   '||l_ps_table||' ps
                                            WHERE  ps.customer_trx_id = trx.customer_trx_id
                                             '|| l_ps_org_where||')
                      AND     gl_dist.gl_date BETWEEN :gl_date_low AND :gl_date_high
                      AND     type.post_to_gl = ''Y''
                      AND     gl_dist.account_class = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     trx.cust_trx_type_id = type.cust_trx_type_id
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     type.type IN (''INV'', ''DEP'', ''GUAR'', ''CM'',''DM'')
                      '|| l_trx_org_where||'
                      '|| l_gl_dist_org_where ;
    l_non_post_select := l_non_post_select||'
                      WHERE   trx.complete_flag = ''Y''
                      AND     NOT EXISTS ( SELECT ''x''
                                           FROM   '||l_ps_table||' ps
                                           WHERE  ps.customer_trx_id = trx.customer_trx_id
                                           '|| l_ps_org_where||')
                      AND     trx.trx_date BETWEEN :gl_date_low AND :gl_date_high
                      AND     type.post_to_gl = ''N''
                      AND     gl_dist.account_class = ''REC''
                      AND     gl_dist.latest_rec_flag = ''Y''
                      AND     gl_dist.customer_trx_id = trx.customer_trx_id
                      AND     trx.cust_trx_type_id = type.cust_trx_type_id
                      AND     nvl(type.org_id,-99) = nvl(trx.org_id,-99)
                      AND     type.type IN (''INV'', ''DEP'', ''GUAR'', ''CM'',''DM'')
                      '|| l_trx_org_where ||'
                      '|| l_gl_dist_org_where;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_post_select := l_post_select||'
                     AND     gc.code_combination_id = gl_dist.code_combination_id
                      '||company_segment_where ;
    l_non_post_select := l_non_post_select ||'
                     AND     gc.code_combination_id = gl_dist.code_combination_id
                      '||company_segment_where ;
  END IF;

    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_post_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_post_excp_amount);
    dbms_sql.define_column(v_cursor, 2, p_post_excp_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_post_excp_amount);
         dbms_sql.column_value(v_cursor, 2, p_post_excp_acctd_amount);
      ELSE
         EXIT;
      END IF;
    END LOOP;

    dbms_sql.parse(v_cursor,l_non_post_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_nonpost_excp_amount);
    dbms_sql.define_column(v_cursor, 2, p_nonpost_excp_acctd_amount);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_nonpost_excp_amount);
         dbms_sql.column_value(v_cursor, 2, p_nonpost_excp_acctd_amount);
      ELSE
         EXIT;
      END IF;
    END LOOP;

   dbms_sql.close_cursor(v_cursor);

END invoice_exceptions ;

FUNCTION begin_or_end_bal( p_gl_date IN DATE,
                           p_gl_date_closed IN DATE,
                           p_activity_date IN DATE,
                           p_as_of_date IN DATE
                           )RETURN NUMBER IS

BEGIN
  --If the payment schedule gl date is less than p_as_of_date_start
  --and gl date closed is greater than p_as_of_date_start

 IF p_activity_date IS NULL THEN  --for Open Trx
   IF (  ( p_gl_date <= p_as_of_date)
   AND   ( p_gl_date_closed > p_as_of_date) ) THEN
        RETURN 1;
   ELSE
        RETURN 0;
   END IF;
 ELSIF p_activity_date IS NOT NULL THEN  -- applications and adjustments
   IF (  (p_gl_date <=  p_as_of_date)
     AND  (p_gl_date_closed > p_as_of_date)
     AND  (p_activity_date > p_as_of_date))  THEN
        RETURN 1;
   ELSE
        RETURN 0;
   END IF;
 END IF;

END begin_or_end_bal;

/*Added and changed parameter to divide among workers based on gl date bug 7287425*/
PROCEDURE journal_reports(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                            p_reporting_level             IN  VARCHAR2,
                            p_reporting_entity_id         IN  NUMBER,
                            p_co_seg_low                  IN  VARCHAR2,
                            p_co_seg_high                 IN  VARCHAR2,
                            p_coa_id                      IN  NUMBER,
                            p_sales_journal_amt           OUT NOCOPY NUMBER,
                            p_sales_journal_acctd_amt     OUT NOCOPY NUMBER,
                            p_adj_journal_amt             OUT NOCOPY NUMBER,
                            p_adj_journal_acctd_amt       OUT NOCOPY NUMBER,
                            p_app_journal_amt             OUT NOCOPY NUMBER,
                            p_app_journal_acctd_amt       OUT NOCOPY NUMBER,
                            p_unapp_journal_amt           OUT NOCOPY NUMBER,
                            p_unapp_journal_acctd_amt     OUT NOCOPY NUMBER,
                            p_cm_journal_acctd_amt        OUT NOCOPY NUMBER,
                            p_worker_number            IN NUMBER DEFAULT 1,
                            p_total_workers            IN NUMBER DEFAULT 1
                                            ) IS


 l_sales_journal_salect          VARCHAR2(2000);
 l_adj_journal_select            VARCHAR2(2000);
 l_app_journal_select            VARCHAR2(3000);
 l_unapp_journal_select          VARCHAR2(2000);
 l_cm_journal_select             VARCHAR2(2000);
 v_cursor                        NUMBER;
 l_ignore                        INTEGER;
 l_as_of_date_from          DATE;
 l_as_of_date_to            DATE;

BEGIN
    build_parameters (p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id);

    IF NVL(p_total_workers,1) <= 1 then
      l_as_of_date_from := p_as_of_date_from;
      l_as_of_date_to := p_as_of_date_to;
    ELSE
      IF p_total_workers = p_worker_number then
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;

          l_as_of_date_to:= p_as_of_date_to;
      ELSE
        IF p_worker_number = 1 then
           l_as_of_date_from := p_as_of_date_from;
           l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)));
        ELSE
          l_as_of_date_from := (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)) * (p_worker_number-1)) + 1;
          l_as_of_date_to:= (p_as_of_date_from + (round((p_as_of_date_to-p_as_of_date_from)/p_total_workers)*(p_worker_number)));
        END IF;
      END IF;
    END IF;
fnd_file.put_line(fnd_file.log,'from Date:'||l_as_of_date_from);
fnd_file.put_line(fnd_file.log,'To Date:'||l_as_of_date_to);


    l_sales_journal_salect   := ' SELECT sum(gl_dist.amount), sum(gl_dist.acctd_amount)
                         FROM   '||l_trx_table||' trx,
                                '||l_gl_dist_table||' gl_dist' ;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_sales_journal_salect := l_sales_journal_salect ||',
                                gl_code_combinations gc ';
  END IF;

    l_sales_journal_salect := l_sales_journal_salect ||'
                         WHERE  trx.complete_flag = ''Y''
                         AND    gl_dist.latest_rec_flag = ''Y''
                         AND    gl_dist.gl_date between :gl_date_low and :gl_date_high
                         AND    gl_dist.customer_trx_id = trx.customer_trx_id
                         AND    gl_dist.account_class = ''REC''
                        '|| l_gl_dist_org_where ||'
                        '|| l_trx_org_where;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_sales_journal_salect := l_sales_journal_salect ||'
                         AND    gc.code_combination_id = gl_dist.code_combination_id
                        '||company_segment_where;
  END IF;

    l_adj_journal_select := 'SELECT (sum(nvl(ard.amount_dr,0))- sum(nvl(ard.amount_cr,0))),
                                    (sum(nvl(ard.acctd_amount_dr,0)) -sum(nvl(ard.acctd_amount_cr,0)))
                             FROM  '||l_adj_table||' adj,
                                   '||l_ard_table||' ard';
  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_adj_journal_select := l_adj_journal_select||',
                                   gl_code_combinations gc';
  END IF;

    l_adj_journal_select := l_adj_journal_select||'
                             WHERE adj.gl_date between :gl_date_low and :gl_date_high
                             AND nvl(adj.postable,''Y'') = ''Y''
                             AND nvl(adj.status ,''A'')  = ''A''
                             AND adj.adjustment_id = ard.source_id
                             AND ard.source_table=''ADJ''
                             AND ard.source_type in (''REC'', ''UNPAIDREC'')
                            '|| l_adj_org_where ||'
                            '|| l_ard_org_where ;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_adj_journal_select := l_adj_journal_select||'
                             AND gc.code_combination_id = ard.code_combination_id
                            '||company_segment_where;
  END IF;

    l_app_journal_select := 'SELECT (sum(nvl(ard.amount_cr,0))- sum(nvl(ard.amount_dr,0))),
                                    (sum(nvl(acctd_amount_cr,0))- sum(nvl(acctd_amount_dr,0)))
                             FROM  '||l_ra_table ||' ra ,
                                   '||l_ard_table||' ard,
                                   '||l_ps_table ||' ps ';
  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_app_journal_select := l_app_journal_select ||',
                                   gl_code_combinations gc';
  END IF;
    l_app_journal_select := l_app_journal_select||'
                             WHERE ard.source_table=''RA''
                               AND ard.source_id=ra.receivable_application_id
                               AND ra.status = ''APP''
                               AND nvl(ra.postable,''Y'')=''Y''
                               AND nvl(ra.confirmed_flag,''Y'')=''Y''
                               AND ra.application_type =''CASH''
                               AND ra.applied_payment_schedule_id=ps.payment_schedule_id
                               AND ra.gl_date between :gl_date_low and :gl_date_high
                               AND ((ard.source_type = ''REC'')
                                 OR (ps.class =''BR''
                                     AND not exists (SELECT line_id
                                                     FROM   '||l_ard_table||' ard1
                                                     WHERE ard1.source_id = ra.receivable_application_id
                                                     AND   ard1.source_type = ''REC''
                                                     AND   ard1.source_table =''RA''
                                                     '|| l_ard1_org_where || ')
                                     AND ard.source_type in (''REMITTANCE'',''FACTOR'',''UNPAIDREC'')))
                              '|| l_ra_org_where ||'
                              '|| l_ard_org_where ||'
                              '|| l_ps_org_where ;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_app_journal_select := l_app_journal_select||'
                               AND gc.code_combination_id = ard.code_combination_id
                              '||company_segment_where;
  END IF;

    l_unapp_journal_select := 'SELECT (sum(nvl(amount_cr,0))- sum(nvl(amount_dr,0))) ,
                                      (sum(nvl(acctd_amount_cr,0))- sum(nvl(acctd_amount_dr,0)))
                               FROM '||l_ra_table||' ra,
                                    '||l_ard_table||' ard ';

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_unapp_journal_select := l_unapp_journal_select ||',
                                    gl_code_combinations gc ';
  END IF;

    l_unapp_journal_select := l_unapp_journal_select ||'
                               WHERE ard.source_table = ''RA''
                               AND   ard.source_id = ra.receivable_application_id
                               AND   ra.status in (''UNAPP'',''UNID'',''ACC'',''OTHER ACC'')
                               AND   nvl(ra.confirmed_flag, ''Y'') = ''Y''
                               AND   ra.application_type = ''CASH''
                               AND   ra.gl_date between :gl_date_low and :gl_date_high
                             '|| l_ra_org_where ||'
                             '|| l_ard_org_where ;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_unapp_journal_select := l_unapp_journal_select ||'
                               AND   gc.code_combination_id = ard.code_combination_id
                             '||company_segment_where;
  END IF;

    l_cm_journal_select  := 'SELECT sum(nvl(acctd_amount_cr,0))- sum(nvl(acctd_amount_dr,0)) --bug4173702
                             FROM '||l_ra_table||' ra ,
                                  '||l_ard_table||' ard ';
  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_cm_journal_select  := l_cm_journal_select ||',
                                  gl_code_combinations gc';
  END IF;

    l_cm_journal_select  := l_cm_journal_select ||'
                             WHERE ard.source_table = ''RA''
                             AND   ard.source_type in (''EXCH_GAIN'',''EXCH_LOSS'')   --bug 4173702
                             AND   ard.source_id = ra.receivable_application_id
                             AND   nvl(ra.confirmed_flag,''Y'') = ''Y''
                             AND   ra.application_type = ''CM''
                             AND   ra.gl_date between :gl_date_low and :gl_date_high
                             '|| l_ra_org_where ||'
                             '|| l_ard_org_where ;

  IF p_co_seg_low IS NOT NULL OR p_co_seg_high IS NOT NULL THEN
    l_cm_journal_select  := l_cm_journal_select ||'
                             AND   gc.code_combination_id = ard.code_combination_id
                             '||company_segment_where;
  END IF;

    v_cursor := dbms_sql.open_cursor;

    dbms_sql.parse(v_cursor,l_sales_journal_salect,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_sales_journal_amt);
    dbms_sql.define_column(v_cursor, 2, p_sales_journal_acctd_amt);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_sales_journal_amt);
         dbms_sql.column_value(v_cursor, 2, p_sales_journal_acctd_amt);
      ELSE
         EXIT;
      END IF;
    END LOOP;

    dbms_sql.parse(v_cursor,l_adj_journal_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_adj_journal_amt);
    dbms_sql.define_column(v_cursor, 2, p_adj_journal_acctd_amt);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_adj_journal_amt);
         dbms_sql.column_value(v_cursor, 2, p_adj_journal_acctd_amt);
      ELSE
         EXIT;
      END IF;
    END LOOP;

    dbms_sql.parse(v_cursor,l_app_journal_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_app_journal_amt);
    dbms_sql.define_column(v_cursor, 2, p_app_journal_acctd_amt);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_app_journal_amt);
         dbms_sql.column_value(v_cursor, 2, p_app_journal_acctd_amt);
      ELSE
         EXIT;
      END IF;
    END LOOP;

    dbms_sql.parse(v_cursor,l_unapp_journal_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1, p_unapp_journal_amt);
    dbms_sql.define_column(v_cursor, 2, p_unapp_journal_acctd_amt);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1, p_unapp_journal_amt);
         dbms_sql.column_value(v_cursor, 2, p_unapp_journal_acctd_amt);
      ELSE
         EXIT;
      END IF;
    END LOOP;

    dbms_sql.parse(v_cursor,l_cm_journal_select,DBMS_SQL.NATIVE);

    dbms_sql.bind_variable(v_cursor, ':gl_date_low', l_as_of_date_from);
    dbms_sql.bind_variable(v_cursor, ':gl_date_high', l_as_of_date_to);

    dbms_sql.define_column(v_cursor, 1,p_cm_journal_acctd_amt);

    l_ignore := dbms_sql.execute(v_cursor);

    LOOP
      IF dbms_sql.fetch_rows(v_cursor) > 0 then
         dbms_sql.column_value(v_cursor, 1,p_cm_journal_acctd_amt);
     ELSE
         EXIT;
      END IF;
    END LOOP;

   dbms_sql.close_cursor(v_cursor);

END journal_reports;


PROCEDURE get_report_heading ( p_reporting_level          IN  VARCHAR2,
                               p_reporting_entity_id      IN  NUMBER,
                               p_set_of_books_id          IN  NUMBER,
                               p_sob_name                 OUT NOCOPY VARCHAR2,
                               p_functional_currency      OUT NOCOPY VARCHAR2,
                               p_coa_id                   OUT NOCOPY NUMBER,
                               p_precision                OUT NOCOPY NUMBER,
                               p_sysdate                  OUT NOCOPY VARCHAR2,
                               p_organization             OUT NOCOPY VARCHAR2,
                               p_bills_receivable_flag    OUT NOCOPY VARCHAR2) IS
l_select_stmt      VARCHAR2(10000);
l_sysparam_table   VARCHAR2(50);
l_sysparam_where   VARCHAR2(200);
l_org_name         VARCHAR2(10000);
l_br_flag          VARCHAR2(1);
BEGIN

 ar_calc_aging.g_reporting_entity_id   := p_reporting_entity_id;

 IF NVL(ar_calc_aging.ca_sob_type,'P') = 'P' THEN
     l_sysparam_table := 'ar_system_parameters_all ';
  ELSE
     l_sysparam_table := 'ar_system_parameters_all_mrc_v ';
  END IF;

  XLA_MO_REPORTING_API.Initialize(p_reporting_level, p_reporting_entity_id, 'AUTO');

  l_sysparam_where     := XLA_MO_REPORTING_API.Get_Predicate('param',null);

  l_sysparam_where     := replace(l_sysparam_where,
                                  ':p_reporting_entity_id','ar_calc_aging.get_reporting_entity_id()');

  l_select_stmt := 'SELECT  sob.name sob_name,
                            sob.currency_code functional_currency,
                            sob.chart_of_accounts_id ,
                            cur.precision,
                            to_char(sysdate,''DD-MON-YYYY hh24:mi'') p_sysdate
                    FROM    gl_sets_of_books sob,
                            fnd_currencies cur
                    WHERE   sob.set_of_books_id = :p_set_of_books_id
                    AND     sob.currency_code = cur.currency_code';

  EXECUTE IMMEDIATE  l_select_stmt
     INTO p_sob_name,
          p_functional_currency,
          p_coa_id,
          p_precision,
          p_sysdate
   USING  p_set_of_books_id;

   IF p_reporting_level <> '3000' THEN
        select meaning
        into p_organization
        from ar_lookups
        where lookup_code = 'ALL'
        and lookup_type = 'ALL';
     BEGIN
       execute immediate
          'select ''Y''
          from dual
          where exists( select ''br_enabled''
                        from '||l_sysparam_table||' param
                        where bills_receivable_enabled_flag = ''Y''
                       '||l_sysparam_where||')'
       into br_enabled_flag;

     EXCEPTION WHEN OTHERS THEN
           br_enabled_flag := 'N';
     END;

   ELSE
    execute immediate 'select substr(hou.name,1,60) organization,
                             nvl(param.bills_receivable_enabled_flag,''N'')
                        from hr_organization_units hou,
                            '||l_sysparam_table||' param
                        where hou.organization_id = :org_id
                          and hou.organization_id = param.org_id'
    into p_organization,br_enabled_flag
    using p_reporting_entity_id;

   END IF;

    IF nvl(br_enabled_flag,'N') <> 'Y' THEN
       br_enabled_flag := 'N';
    END IF;

    p_bills_receivable_flag := br_enabled_flag;

END get_report_heading;

/*New procedure added to call by child program and to initate no of workers bug 7287425*/
PROCEDURE aging_as_of_child(
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                              p_reporting_level          IN VARCHAR2,
                              p_reporting_entity_id      IN NUMBER,
                              p_co_seg_low               IN VARCHAR2,
                              p_co_seg_high              IN VARCHAR2,
                              p_coa_id                   IN NUMBER,
			      p_conc_request_id		 IN NUMBER,
                              p_workers                  IN NUMBER,
			      p_req_status_tab           OUT req_status_tab_typ
                              ) IS
errbuf varchar2(2000);
retcode number;
l_worker_number		NUMBER ;
l_tot_workers           NUMBER;
l_parent_request_id     NUMBER;
l_request_id            NUMBER;

Begin

IF p_workers IS NULL OR p_workers <= 0 THEN
   l_tot_workers := 1;
ELSE
   l_tot_workers := p_workers;
END IF;

l_parent_request_id :=p_conc_request_id;

    FOR l_worker_number in 1..l_tot_workers LOOP

        l_request_id := FND_REQUEST.submit_request('AR','ARRECWRB',
                                 '',
                                 SYSDATE,
                                 FALSE,
                                 p_as_of_date_from ,
                                 p_as_of_date_to,
                                 p_reporting_level,
                                 p_reporting_entity_id,
                                 p_co_seg_low,
                                 p_co_seg_high,
                                 p_coa_id,
                                 l_parent_request_id,
			         l_worker_number,
                                 l_tot_workers
                                  );
        IF (l_request_id = 0) THEN
            errbuf := fnd_Message.get;
            retcode := 2;
            return;
        ELSE
--	    insert into ar_parent_request_id values (l_parent_request_id , l_request_id);
            p_req_status_tab(l_worker_number).request_id := l_request_id;
	    COMMIT;
        END IF;

     END LOOP;

     --COMMIT;

END aging_as_of_child;



PROCEDURE aging_as_of_worker(
                              errbuf                 OUT NOCOPY VARCHAR2,
                              retcode                OUT NOCOPY NUMBER,
                              p_as_of_date_from          IN DATE,
                              p_as_of_date_to            IN DATE,
                              p_reporting_level          IN VARCHAR2,
                              p_reporting_entity_id      IN NUMBER,
                              p_co_seg_low               IN VARCHAR2,
                              p_co_seg_high              IN VARCHAR2,
                              p_coa_id                   IN NUMBER,
                              p_parent_request_id        IN NUMBER,
                              p_worker_number            IN NUMBER,
                              p_total_workers            IN NUMBER
                              ) IS

l_begin_bal                  NUMBER;
l_end_bal                    NUMBER;
l_acctd_begin_bal            NUMBER;
l_acctd_end_bal              NUMBER;
l_request                    NUMBER;
l_sales_journal_amt          NUMBER;
l_sales_journal_acctd_amt    NUMBER;
l_adj_journal_amt            NUMBER;
l_adj_journal_acctd_amt      NUMBER;
l_app_journal_amt            NUMBER;
l_app_journal_acctd_amt      NUMBER;
l_unapp_journal_amt          NUMBER;
l_unapp_journal_acctd_amt    NUMBER;
l_cm_journal_acctd_amt       NUMBER;
l_non_post_amount		     NUMBER;
l_non_post_acctd_amount      NUMBER;
l_post_amount                NUMBER;
l_post_acctd_amount          NUMBER;
l_unapp_amount               NUMBER;
l_unapp_acctd_amount         NUMBER;
l_acc_amount		     NUMBER;
l_acc_acctd_amount 	     NUMBER;
l_claim_amount               NUMBER;
l_claim_acctd_amount         NUMBER;
l_prepay_amount              NUMBER;
l_prepay_acctd_amount        NUMBER;
l_app_amount 		     NUMBER;
l_app_acctd_amount           NUMBER;
l_edisc_amount               NUMBER;
l_edisc_acctd_amount         NUMBER;
l_unedisc_amount             NUMBER;
l_unedisc_acctd_amount       NUMBER;
l_cm_gain_loss               NUMBER;
l_on_acc_cm_ref_amount       NUMBER;
l_on_acc_cm_ref_acctd_amount NUMBER;
l_fin_chrg_amount            NUMBER;
l_fin_chrg_acctd_amount      NUMBER;
l_adj_amount                 NUMBER;
l_adj_acctd_amount           NUMBER;
l_guar_amount                NUMBER;
l_guar_acctd_amount          NUMBER;
l_dep_amount                 NUMBER;
l_dep_acctd_amount           NUMBER;
l_endorsmnt_amount           NUMBER;
l_endorsmnt_acctd_amount     NUMBER;
l_post_excp_amount           NUMBER;
l_post_excp_acctd_amount     NUMBER;
l_nonpost_excp_amount        NUMBER;
l_nonpost_excp_acctd_amount  NUMBER;
l_begin_as_of                 DATE;
l_end_as_of                  DATE;
Begin
/*Sub request procedure calls aging as of*/

COMMIT;
SET TRANSACTION READ ONLY;

initialize;
l_begin_as_of := nvl(p_as_of_date_from, TRUNC(sysdate) ) -1;
l_end_as_of:= nvl(p_as_of_date_to, TRUNC(sysdate)) ;

          aging_as_of(
                      l_begin_as_of,
                      l_end_as_of,
                      p_reporting_level,
                      p_reporting_entity_id,
                      p_co_seg_low,
                      p_co_seg_high,
                      p_coa_id,
                      l_begin_bal,
                      l_end_bal,
                      l_acctd_begin_bal,
                      l_acctd_end_bal,
		      p_worker_number,
   		      p_total_workers);


          journal_reports(  p_as_of_date_from,
                            p_as_of_date_to,
                            p_reporting_level,
                            p_reporting_entity_id,
                            p_co_seg_low,
                            p_co_seg_high,
                            p_coa_id,
                            l_sales_journal_amt,
                            l_sales_journal_acctd_amt,
                            l_adj_journal_amt,
                            l_adj_journal_acctd_amt,
                            l_app_journal_amt,
                            l_app_journal_acctd_amt,
                            l_unapp_journal_amt,
                            l_unapp_journal_acctd_amt,
                            l_cm_journal_acctd_amt,
			    p_worker_number,
			    p_total_workers);

	    transaction_register(p_as_of_date_from,
                               p_as_of_date_to,
                               p_reporting_level,
                               p_reporting_entity_id,
                               p_co_seg_low,
                               p_co_seg_high,
                               p_coa_id,
                               l_non_post_amount,
                               l_non_post_acctd_amount,
                               l_post_amount,
                               l_post_acctd_amount,
                 	       p_worker_number,
			       p_total_workers);


	    cash_receipts_register(p_as_of_date_from,
                                 p_as_of_date_to,
                                 p_reporting_level,
                                 p_reporting_entity_id,
                                 p_co_seg_low,
                                 p_co_seg_high,
                                 p_coa_id,
                                 l_unapp_amount,
                                 l_unapp_acctd_amount,
                                 l_acc_amount,
                                 l_acc_acctd_amount,
                                 l_claim_amount,
                                 l_claim_acctd_amount,
                                 l_prepay_amount,
                                 l_prepay_acctd_amount,
                                 l_app_amount,
                                 l_app_acctd_amount,
                                 l_edisc_amount,
                                 l_edisc_acctd_amount,
                                 l_unedisc_amount,
                                 l_unedisc_acctd_amount,
                                 l_cm_gain_loss,
                                 l_on_acc_cm_ref_amount,
                                 l_on_acc_cm_ref_acctd_amount,
      			   	 p_worker_number,
		       		 p_total_workers);


	    adjustment_register(p_as_of_date_from,
                              p_as_of_date_to,
                              p_reporting_level,
                              p_reporting_entity_id,
                              p_co_seg_low,
                              p_co_seg_high,
                              p_coa_id,
                              l_fin_chrg_amount,
                              l_fin_chrg_acctd_amount,
                              l_adj_amount,
                              l_adj_acctd_amount,
                              l_guar_amount,
                              l_guar_acctd_amount,
                              l_dep_amount,
                              l_dep_acctd_amount,
                              l_endorsmnt_amount,
                              l_endorsmnt_acctd_amount,
			      p_worker_number,
			      p_total_workers);

	    invoice_exceptions( p_as_of_date_from,
                              p_as_of_date_to,
                              p_reporting_level,
                              p_reporting_entity_id,
                              p_co_seg_low,
                              p_co_seg_high,
                              p_coa_id,
                              l_post_excp_amount,
                              l_post_excp_acctd_amount,
                              l_nonpost_excp_amount,
                              l_nonpost_excp_acctd_amount,
			      p_worker_number,
		      	      p_total_workers);

          COMMIT;

          l_request:=   fnd_global.conc_request_id;

		insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'AGING_AS_OF',
		l_begin_bal,
		l_end_bal,
            	l_acctd_begin_bal,
            	l_acctd_end_bal,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null);

          insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'JOURNAL_REPORTS',
		null,
		null,
		null,
		null,
            l_sales_journal_amt,
            l_sales_journal_acctd_amt ,
            l_adj_journal_amt,
            l_adj_journal_acctd_amt,
            l_app_journal_amt,
            l_app_journal_acctd_amt,
            l_unapp_journal_amt,
            l_unapp_journal_acctd_amt,
            l_cm_journal_acctd_amt,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null);

		insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'TRANSACTION_REGISTER',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
                l_non_post_amount,
                l_non_post_acctd_amount,
                l_post_amount,
                l_post_acctd_amount,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null);

		insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'CASH_RECEIPT_REGISTER',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
                l_unapp_amount,
                l_unapp_acctd_amount,
                l_acc_amount,
		l_acc_acctd_amount,
		l_claim_amount,
		l_claim_acctd_amount,
		l_prepay_amount,
		l_prepay_acctd_amount,
		l_app_amount,
		l_app_acctd_amount,
		l_edisc_amount,
		l_edisc_acctd_amount,
		l_unedisc_amount,
		l_unedisc_acctd_amount,
		l_cm_gain_loss,
		l_on_acc_cm_ref_amount,
		l_on_acc_cm_ref_acctd_amount,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null);

		insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'ADJUSTMENT_REGISTER',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
                l_fin_chrg_amount,
		l_fin_chrg_acctd_amount,
		l_adj_amount,
		l_adj_acctd_amount,
		l_guar_amount,
		l_guar_acctd_amount,
		l_dep_amount,
		l_dep_acctd_amount,
		l_endorsmnt_amount,
		l_endorsmnt_acctd_amount,
		null,
		null,
		null,
		null);

		insert into AR_RECONCILIATION values(
		p_parent_request_id,
		l_request,
		'INVOICE_EXCEPTION',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
            l_post_excp_amount,
            l_post_excp_acctd_amount,
            l_nonpost_excp_amount,
            l_nonpost_excp_acctd_amount);

          COMMIT;

END aging_as_of_worker;

FUNCTION get_child_request_id(p_worker in number) return NUMBER
IS
BEGIN

return l_req_status_tab(p_worker).request_id;
/*
IF p_worker = 2 THEN
   return g_req_id;
ELSE
   return g_journal_req_id;
END IF;
*/
END get_child_request_id;

END ar_calc_aging ;

/
