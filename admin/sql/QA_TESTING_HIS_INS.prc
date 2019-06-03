INSERT INTO apps.Q_OD_PB_TESTING_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_RECORD_ID ,                               
		OD_PB_PROGRAM_TEST_TYPE                        ,
		OD_PB_TECH_RPT_NUM                             ,
		OD_PB_CA_TYPE                                  ,
		OD_PB_RESULTS                                  ,
		OD_PB_ATTACHMENT                               ,
		OD_PB_APPROVAL_STATUS                          ,
		OD_PB_CLASS                                    ,
		OD_PB_COMMENTS                                 ,
		OD_PB_COMPARISON_NAME                          ,
		OD_PB_CTQ_LIST                                 ,
		OD_PB_CTQ_RESULTS                              ,
		OD_PB_DATE_APPROVED                            ,
		OD_PB_DATE_DUE                                 ,
		OD_PB_DATE_KICKOFF                             ,
		OD_PB_DATE_OPENED                              ,
		OD_PB_DATE_PROPOSAL_APPROVED                   ,
		OD_PB_DATE_PROPOSAL_PROVIDED                   ,
		OD_PB_DATE_REPORT_DUE                          ,
		OD_PB_DATE_TESTING_BEGINS                      ,
		OD_PB_DPPM                                     ,
		OD_PB_FACTORY_ID                               ,
		OD_PB_1ST_ARTICLE_DEFECT_RATE                  ,
		OD_PB_MINOR                                    ,
		OD_PB_MAJOR                                    ,
		OD_PB_CRITICAL                                 ,
		OD_PB_MERCHANDISING_APPROVER                   ,
		OD_PB_PO_NUM                                   ,
		OD_PB_QA_APPROVER                              ,
		OD_PB_SAMPLE_SIZE                              ,
		OD_PB_SKU                                      ,
		OD_PB_CONTACT                                  ,
		OD_PB_VENDORS_AWARDED                          ,
		OD_PB_VENDOR_COMMENTS                          ,
		OD_PB_AUDITOR_NAME                             ,
		OD_PB_ORG_AUDITED                              ,
		OD_PB_FQA_SCORE                                ,
		OD_PB_SPECIFICATION_NAME                       ,
		OD_PB_DATE_REPORTED				,
		OD_PB_LOT_SIZE                                 ,
		OD_PB_DEFECT_SUM                               ,
		OD_PB_OBJECTIVE                                ,
		OD_PB_SUPPLIER                                 ,
		OD_PB_TESTINGPLAN_ID                           ,
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_TESTING_HIST',
                '1000', 
                OD_PB_RECORD_ID				       ,
		OD_PB_PROGRAM_TEST_TYPE                        ,
		OD_PB_TECH_RPT_NUM                             ,
		OD_PB_CA_TYPE                                  ,
		OD_PB_RESULTS                                  ,
		OD_PB_ATTACHMENT                               ,
		OD_PB_APPROVAL_STATUS                          ,
		OD_PB_CLASS                                    ,
		OD_PB_COMMENTS                                 ,
		OD_PB_COMPARISON_NAME                          ,
		OD_PB_CTQ_LIST                                 ,
		OD_PB_CTQ_RESULTS                              ,
		TO_CHAR(OD_PB_DATE_APPROVED,'YYYY/MM/DD')                            ,
		TO_CHAR(OD_PB_DATE_DUE,'YYYY/MM/DD')                                 ,
		TO_CHAR(OD_PB_DATE_KICKOFF,'YYYY/MM/DD')                             ,
		TO_CHAR(OD_PB_DATE_OPENED,'YYYY/MM/DD')                              ,
		TO_CHAR(OD_PB_DATE_PROPOSAL_APPROVED,'YYYY/MM/DD')                   ,
		TO_CHAR(OD_PB_DATE_PROPOSAL_PROVIDED,'YYYY/MM/DD')                   ,
		TO_CHAR(OD_PB_DATE_REPORT_DUE,'YYYY/MM/DD')                          ,
		TO_CHAR(OD_PB_DATE_TESTING_BEGINS,'YYYY/MM/DD')                      ,
		OD_PB_DPPM                                     ,
		OD_PB_FACTORY_ID                               ,
		OD_PB_1ST_ARTICLE_DEFECT_RATE                  ,
		OD_PB_MINOR                                    ,
		OD_PB_MAJOR                                    ,
		OD_PB_CRITICAL                                 ,
		OD_PB_MERCHANDISING_APPROVER                   ,
		OD_PB_PO_NUM                                   ,
		OD_PB_QA_APPROVER                              ,
		OD_PB_SAMPLE_SIZE                              ,
		OD_PB_SKU                                      ,
		OD_PB_CONTACT                                  ,
		OD_PB_VENDORS_AWARDED                          ,
		OD_PB_VENDOR_COMMENTS                          ,
		OD_PB_AUDITOR_NAME                             ,
		OD_PB_ORG_AUDITED                              ,
		OD_PB_FQA_SCORE                                ,
		OD_PB_SPECIFICATION_NAME                       ,
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')                            ,
		OD_PB_LOT_SIZE                                 ,
		OD_PB_DEFECT_SUM                               ,
		OD_PB_OBJECTIVE                                ,
		OD_PB_SUPPLIER                                 ,
		OD_PB_TESTINGPLAN_ID                           ,
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.od_pb_record_id
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_TESTING_HIST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;
