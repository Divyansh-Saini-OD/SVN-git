create or replace
PACKAGE BODY XX_PA_FA_MTHLY_ACT_RPT_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_PA_FA_MTHLY_ACT_RPT_PKG                                                         |
-- |  Description:  OD: PA Fixed Asset Monthly Activity Report                                  |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07-Apr-2010  Joe Klein        Initial version                                  |
-- | 1.1         06-May-2010  Joe Klein        Defect 5649 - Changed where clause for CIP       |
-- |                                           General task type.                               |
-- | 1.2         06-May-2010  Joe Klein        Defect 5686 - Changed LEFT JOIN to JOIN to       |
-- |                                           eliminate null value lines on follwoing tables:  |
-- |                                           pa_project_asset_lines                           |
-- |                                           pa_tasks                                         |
-- |                                           gl_code_combinations                             |
-- |                                           fa_transaction_headers                           |
-- | 1.3         11-May-2010  Joe Klein        Defect 5689 - Changed join logic for tables      |
-- |                                           fa_transaction_headers                           |
-- |                                           fa_deprn_periods                                 |
-- |                                           fa_asset_invoices                                |
-- | 1.4         28-NOV-2012  Rohit Ranjan/Adithya     Defect# 14694                            |
-- | 1.5         18-MAR-2013  Divya                    Defect# 22467                            |
-- | 1.6         19-NOV-2015  Harvinder Rakhra Harvinder Rakhra                                 |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XX_PA_FA_MTHLY_ACT_RPT_PKG.XX_MAIN_RPT                                              |
-- |  Description: This pkg.procedure will extract project data that was sent from PA to FA     |
-- |  for a particular PA period range.                                                         |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_period_from IN VARCHAR2 DEFAULT NULL,
   p_period_to IN VARCHAR2 DEFAULT NULL,
   p_capital_task     IN VARCHAR2 DEFAULT 'Y',  --Added as per Defect# 14694
   P_SERVICE_TYPE     in varchar2 default null, --Added as per Defect# 14694
   --p_task_type IN VARCHAR2 DEFAULT NULL,--Commented as per Defect# 14694
   p_project_num_from IN VARCHAR2 DEFAULT NULL,
   p_project_num_to IN VARCHAR2 DEFAULT NULL,
   p_company IN VARCHAR2 DEFAULT NULL)
  IS
    v_out_header   VARCHAR2(1000);
    v_log_msg      VARCHAR2(100);
    v_profile_value VARCHAR2(100);
    v_lang VARCHAR2(100);
    v_period_num_from gl_period_statuses.effective_period_num%TYPE;
    v_period_num_to gl_period_statuses.effective_period_num%TYPE;
    i NUMBER;

    CURSOR c_out IS
    SELECT
       p.segment1 p_segment1,
       paa.asset_name,
       paa.project_asset_id,
       paa.project_asset_type,
       paa.asset_number,
       ppal.description,
       t.task_number,
       ppal.current_asset_cost,
       ppal.fa_period_name,
       gcc.segment1 gcc_segment1,
       gcc.segment2 gcc_segment2,
       gcc.segment3 gcc_segment3,
       gcc.segment4,
       gcc.segment5,
       gcc.segment6,
       gcc.segment7,
	   fth.transaction_header_id,
       fth.transaction_type_code,
       c.segment1 c_segment1,
       c.segment2 c_segment2,
       c.segment3 c_segment3
       FROM  pa_projects p
         JOIN pa_project_assets_all paa
           ON paa.project_id = p.project_id
         JOIN fa_categories_tl ct
           ON ct.category_id = paa.asset_category_id
         JOIN fa_categories c
           ON c.category_id = ct.category_id
         JOIN pa_project_asset_lines ppal
           ON ppal.project_asset_id = paa.project_asset_id
          AND ppal.fa_period_name IN
                                 (SELECT DISTINCT period_name
                                  FROM gl_period_statuses
                                  WHERE effective_period_num BETWEEN  v_period_num_from AND v_period_num_to
                                 )
         JOIN pa_tasks t
           on T.TASK_ID = PPAL.TASK_ID
           /*commented below code as per Defect#14694*/
     /*   AND (  (p_task_type = 'Marketing'          AND (t.task_number LIKE '80.%' OR t.task_number LIKE '%.MKT.%'))
               OR
               (p_task_type = 'Tenant Allowance'   AND (t.task_number LIKE '81.%.ST%' OR t.task_number LIKE '81.%.LT%'))
               OR
               (p_task_type = 'Lease Acquisitions' AND (t.task_number = '02.LEG'))
               OR
               (p_task_type = 'CIP General'        AND (  (t.task_number LIKE '02.%' AND t.task_number <> '02.LEG')
                                                          OR
                                                          (t.task_number LIKE '81.%' AND t.task_number NOT LIKE '81.%.ST%' AND t.task_number NOT LIKE '81.%.LT%' AND t.task_number NOT LIKE '%.MKT.%')
                                                       ))
               OR
               (p_task_type IS NULL)
            )*/

 /*Added below code as per Defect#14694*/
 AND ((p_service_type IS NOT NULL AND p_service_type= t.service_type_code)
    or
    (p_service_type IS NULL) OR (p_service_type= 'ALL'))
 /*Added above code as per Defect#14694*/
       JOIN gl_code_combinations gcc
           ON gcc.code_combination_id = ppal.cip_ccid
          AND (  (p_company IS NOT NULL AND gcc.segment1 = p_company)
                 OR
                 (p_company IS NULL)
              )
         JOIN fa_asset_invoices fai
           ON fai.project_asset_line_id = ppal.project_asset_line_id
          AND fai.fixed_assets_cost = ppal.current_asset_cost
          AND fai.asset_id = paa.fa_asset_id
         JOIN fa_transaction_headers fth
           ON fth.asset_id = paa.fa_asset_id
          AND fth.book_type_code = paa.book_type_code
          AND fth.invoice_transaction_id = fai.invoice_transaction_id_in
          AND fth.transaction_type_code IN ('ADDITION', 'ADDITION/VOID', 'ADJUSTMENT')
         JOIN fa_deprn_periods fdp
           ON --trunc(fai.date_effective) BETWEEN (trunc(fdp.period_open_date) + 1) AND trunc(fdp.period_close_date)/*Commented by Divya for Defect# 22467*/
          fdp.book_type_code = paa.book_type_code
          AND fdp.period_name = ppal.fa_period_name
       WHERE ct.language = v_lang
         AND (  (p_project_num_from IS NOT NULL AND p_project_num_to IS NOT NULL AND p.segment1 BETWEEN p_project_num_from AND p_project_num_to)
                OR
                (p_project_num_from IS NOT NULL AND p_project_num_to IS     NULL AND p.segment1 >= p_project_num_from)
                OR
                (p_project_num_from IS     NULL AND p_project_num_to IS NOT NULL AND p.segment1 <= p_project_num_to)
                OR
                (p_project_num_from IS     NULL AND p_project_num_to IS     NULL)
             )
              /*Added below code as per Defect#14694*/
AND ((p_capital_task= 'Y' AND NVL(t.BILLABLE_FLAG,'N') = p_capital_task AND c.segment2 IS NOT NULL)
or
(P_CAPITAL_TASK= 'N' and NVL(T.BILLABLE_FLAG,'N') = P_CAPITAL_TASK))
 --Start modification by Adithya for defect#14694
UNION ALL
	   SELECT
       p.segment1 p_segment1,
       paa.asset_name,
       paa.project_asset_id,
       paa.project_asset_type,
       paa.asset_number,
       ppal.description,
       t.task_number,
       ppal.current_asset_cost,
       ppal.fa_period_name,
       gcc.segment1 gcc_segment1,
       gcc.segment2 gcc_segment2,
       gcc.segment3 gcc_segment3,
       gcc.segment4,
       gcc.segment5,
       gcc.segment6,
       gcc.segment7,
	   fth.transaction_header_id,
       fth.transaction_type_code,
       c.segment1 c_segment1,
       c.segment2 c_segment2,
       c.segment3 c_segment3
       FROM  pa_projects p
         JOIN pa_project_assets_all paa
           ON paa.project_id = p.project_id
         JOIN fa_categories_tl ct
           ON ct.category_id = paa.asset_category_id
         JOIN fa_categories c
           ON c.category_id = ct.category_id
         JOIN pa_project_asset_lines ppal
           ON ppal.project_asset_id = paa.project_asset_id
          AND ppal.fa_period_name IN
                                 (SELECT DISTINCT period_name
                                  FROM gl_period_statuses
                                  WHERE effective_period_num BETWEEN  v_period_num_from AND v_period_num_to
                                 )
         JOIN pa_tasks t
           on T.TASK_ID = PPAL.TASK_ID
 AND EXISTS
  (SELECT 1 -- ,SEGMENT_VALUE
  FROM PA_SEGMENT_VALUE_LOOKUPS PAS,
       PA_SEGMENT_VALUE_LOOKUP_SETS S
  WHERE PAS.SEGMENT_VALUE_LOOKUP_SET_ID      = S.SEGMENT_VALUE_LOOKUP_SET_ID
  AND upper(S.segment_value_lookup_set_name) = upper('SERVICE TYPE TO CIP ACCOUNT')
  AND SEGMENT_VALUE_LOOKUP                   =t.service_type_code
  AND p_service_type               = PAS.SEGMENT_VALUE
  )
       JOIN gl_code_combinations gcc
           ON gcc.code_combination_id = ppal.cip_ccid
          AND (  (p_company IS NOT NULL AND gcc.segment1 = p_company)
                 OR
                 (p_company IS NULL)
              )
         JOIN fa_asset_invoices fai
           ON fai.project_asset_line_id = ppal.project_asset_line_id
          AND fai.fixed_assets_cost = ppal.current_asset_cost
          AND fai.asset_id = paa.fa_asset_id
         JOIN fa_transaction_headers fth
           ON fth.asset_id = paa.fa_asset_id
          AND fth.book_type_code = paa.book_type_code
          AND fth.invoice_transaction_id = fai.invoice_transaction_id_in
          AND fth.transaction_type_code IN ('ADDITION', 'ADDITION/VOID', 'ADJUSTMENT')
         JOIN fa_deprn_periods fdp
           ON --trunc(fai.date_effective) BETWEEN (trunc(fdp.period_open_date) + 1) AND trunc(fdp.period_close_date)/*COMMENTED BY DIVYA FOR Defect# 22467*/
          fdp.book_type_code = paa.book_type_code
          AND fdp.period_name = ppal.fa_period_name
       WHERE ct.language = v_lang
         AND (  (p_project_num_from IS NOT NULL AND p_project_num_to IS NOT NULL AND p.segment1 BETWEEN p_project_num_from AND p_project_num_to)
                OR
                (p_project_num_from IS NOT NULL AND p_project_num_to IS     NULL AND p.segment1 >= p_project_num_from)
                OR
                (p_project_num_from IS     NULL AND p_project_num_to IS NOT NULL AND p.segment1 <= p_project_num_to)
                OR
                (p_project_num_from IS     NULL AND p_project_num_to IS     NULL)
             )
 /*Added below code as per Defect#14694*/
AND ((p_capital_task= 'Y' AND NVL(t.BILLABLE_FLAG,'N') = p_capital_task AND c.segment2 IS NOT NULL)
or
(P_CAPITAL_TASK= 'N' and NVL(T.BILLABLE_FLAG,'N') = P_CAPITAL_TASK))
ORDER BY 1,3,17,18;
 /*Added above code as per Defect#14694*/
	   --End modification by Adithya for defect#14694

  BEGIN
    --v_log_msg := 'Starting BEGIN block';
    --FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    v_profile_value := FND_PROFILE.value('ORG_ID');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || v_profile_value);
    v_lang := USERENV('LANG');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'LANG = ' || v_lang);

    select distinct effective_period_num into v_period_num_from from gl_period_statuses where period_name = p_period_from;
    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_period_num_from = ' || v_period_num_from);

    select distinct effective_period_num into v_period_num_to from gl_period_statuses where period_name = p_period_to;
    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'v_period_num_to = ' || v_period_num_to);

    v_out_header  := 'PROJECT NUMBER'||chr(9)||'ASSET NAME'||chr(9)||'ASSET ID'||chr(9)||'ASSET TYPE'||chr(9)||'ASSET NUMBER'||chr(9)||'DESCRIPTION'||chr(9)||
                     'TASK NUMBER'||chr(9)||'CURRENT ASSET COST'||chr(9)||'FA PERIOD NAME'||chr(9)||'COMPANY'||chr(9)||'COST CENTER'||chr(9)||'ACCOUNT'||chr(9)||
                     'LOCATION'||chr(9)||'INTERCOMPANY'||chr(9)||'LOB'||chr(9)||'FUTURE'||chr(9)||'ASSET TRANSACTION TYPE'||chr(9)||'MAJOR'||chr(9)||'MINOR'||chr(9)||'SUBMINOR';

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_period_from = ' || p_period_from);
    FND_FILE.PUT_LINE(FND_FILE.log, 'p_period_to = ' || P_PERIOD_TO);
   -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_task_type = ' || p_task_type);
    FND_FILE.PUT_LINE(FND_FILE.log, 'p_capital_task = ' || P_CAPITAL_TASK);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_service_type = ' || p_service_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_project_num_from = ' || p_project_num_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_project_num_to = ' || p_project_num_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_company = ' || p_company);

    i := 0;
    FOR c_out_rec IN c_out LOOP
      i := i + 1;
      IF i = 1 THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, c_out_rec.p_segment1||chr(9)||
       c_out_rec.asset_name||chr(9)||
       c_out_rec.project_asset_id||chr(9)||
       c_out_rec.project_asset_type||chr(9)||
       c_out_rec.asset_number||chr(9)||
       c_out_rec.description||chr(9)||
       c_out_rec.task_number||chr(9)||
       c_out_rec.current_asset_cost||chr(9)||
       c_out_rec.fa_period_name||chr(9)||
       c_out_rec.gcc_segment1||chr(9)||
       c_out_rec.gcc_segment2||chr(9)||
       c_out_rec.gcc_segment3||chr(9)||
       c_out_rec.segment4||chr(9)||
       c_out_rec.segment5||chr(9)||
       c_out_rec.segment6||chr(9)||
       c_out_rec.segment7||chr(9)||
       c_out_rec.transaction_type_code||chr(9)||
       c_out_rec.c_segment1||chr(9)||
       c_out_rec.c_segment2||chr(9)||
       c_out_rec.c_segment3 );
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'output record count = ' || i);

  END XX_MAIN_RPT;

END XX_PA_FA_MTHLY_ACT_RPT_PKG;
/