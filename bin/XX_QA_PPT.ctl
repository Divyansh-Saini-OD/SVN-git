OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE xx_qa_ppt_stg
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
trailing nullcols
 (ppt_id,
  sku_id,
  test_id,
  sp_contacted_vendor 	"to_date(:sp_contacted_vendor,'MM/DD/YYYY')",
  sample_est_lab 		"to_date(:sample_est_lab,'MM/DD/YYYY')",
  sample_recd_sp 		"to_date(:sample_recd_sp,'MM/DD/YYYY')",
  protocol,
  report_no,
  report_doc,
  expect_compl 		"to_date(:expect_compl,'MM/DD/YYYY')",
  test_status,
  test_status_comment,
  status_timestamp 	"to_date(:status_timestamp,'MM/DD/YYYY')",
  results,  
  compl_date            "to_date(:compl_date,'MM/DD/YYYY')",
  defect_code,
  defect_comments,
  prev_report_no,
  inv_amount,
  paid_by                "TRIM(:paid_by)",
  tests_upd_flag      CONSTANT 'D',
  load_batch_id        "apps.XX_QA_PPT_SEQ_S.nextval",
  creation_date "SYSDATE",
  process_flag "-1"
)
