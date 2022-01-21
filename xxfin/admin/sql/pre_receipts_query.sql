alter session set current_schema=apps
;


select /*+ parallel(10) */ DISTINCT CONCATENATED_sEGMENTS from 
(
SELECT ROWID, code_combination_id, chart_of_accounts_id,
       (DECODE (chart_of_accounts_id,
                50310, segment1
                 || '.'
                 || segment2
                 || '.'
                 || segment3
                 || '.'
                 || segment4
                 || '.'
                 || segment5
                 || '.'
                 || segment6
                 || '.'
                 || segment7,
                NULL
               )
       ) concatenated_segments,
       (DECODE (chart_of_accounts_id,
                50310, RPAD (NVL (segment1, ' '), 5)
                 || '.'
                 || RPAD (NVL (segment2, ' '), 5)
                 || '.'
                 || RPAD (NVL (segment3, ' '), 8)
                 || '.'
                 || RPAD (NVL (segment4, ' '), 6)
                 || '.'
                 || RPAD (NVL (segment5, ' '), 5)
                 || '.'
                 || RPAD (NVL (segment6, ' '), 2)
                 || '.'
                 || RPAD (NVL (segment7, ' '), 6),
                NULL
               )
       ),
       account_type, reference3, jgzz_recon_flag,
       detail_budgeting_allowed_flag, detail_posting_allowed_flag, attribute3,
       segment_attribute4, segment_attribute37, segment_attribute14, segment5,
       segment19, segment_attribute3, segment8, last_update_date,
       segment_attribute20, segment_attribute16, segment2,
       segment_attribute32, segment17, segment26, segment_attribute7,
       refresh_flag, alternate_code_combination_id, segment_attribute8,
       reference2, company_cost_center_org_id, segment16, attribute5,
       segment_attribute23, segment6, attribute7, segment9,
       igi_balanced_budget_flag, segment29, segment23, segment_attribute2,
       segment18, segment25, segment_attribute27, segment28, segment11,
       segment_attribute36, attribute4, segment_attribute1, ledger_segment,
       template_id, attribute1, segment_attribute10, segment3,
       start_date_active, segment_attribute26, segment22, jgzz_recon_context,
       segment_attribute40, segment_attribute13, segment15, segment24,
       summary_flag, segment20, segment_attribute31, segment27,
       segment_attribute29, allocation_create_flag, segment_attribute21,
       preserve_flag, segment_attribute18, segment_attribute35,
       segment_attribute19, enabled_flag, end_date_active, segment_attribute6,
       reference5, segment12, attribute9, segment21, segment_attribute28,
       segment_attribute41, segment7, segment14, last_updated_by,
       segment_attribute34, segment_attribute33, segment30,
       segment_attribute9, segment_attribute5, segment_attribute15,
       segment_attribute24, segment_attribute25, attribute2,
       segment_attribute39, segment_attribute11, segment10,
       segment_attribute42, attribute8, segment_attribute22,
       segment_attribute17, segment_attribute30, reference4,
       segment_attribute38, segment4, description, segment1,
       segment_attribute12, attribute10, CONTEXT, attribute6, reference1,
       revaluation_id, segment13
  FROM gl_code_combinations
)
 where code_Combination_id in (
select /*+ parallel(10) */ distinct accrual_account_id from po_headers_All a , po_distributions_All c
 where exists (select 1 
                 from xx_po_hdrs_conv_stg b
                where b.document_num = a.segment1)
and accrual_account_id not in (select accrual_account_id from cst_accrual_accounts)
and a.po_header_id = c.po_header_id
)
;
