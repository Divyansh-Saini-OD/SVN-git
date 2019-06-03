INSERT INTO apps.Q_OD_PB_SERVICE_PROV_SCOREC_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_CA_TYPE       		,           
		OD_PB_SUPPLIER                 ,
		OD_PB_DEFECT_SUM              , 
		OD_PB_DATE_CAPA_SENT          , 
		OD_PB_ROOT_CAUSE               ,
		OD_PB_CORRECTIVE_ACTION_TYPE   ,
		OD_PB_DATE_CAPA_RECEIVED      , 
		OD_PB_QA_ENGR_EMAIL           , 
		OD_PB_APPROVAL_STATUS         , 
		OD_PB_DATE_APPROVED           , 
		OD_PB_DATE_CORR_IMPL          , 
		OD_PB_DATE_VERIFIED           , 
		OD_PB_COMMENTS_VERIFIED       , 
		OD_PB_COMMENTS                , 
		OD_PB_ATTACHMENT              , 
		OD_PB_LINK                    , 
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_SERVICE_PROV_SCORECARD',
                  '1', --1 for INSERT
               'OD_PB_CAR_ID,OD_PB_SUPPLIER',
		OD_PB_CA_TYPE       		,           
		OD_PB_SUPPLIER                 ,
		OD_PB_DEFECT_SUM              , 
		OD_PB_DATE_CAPA_SENT          , 
		OD_PB_ROOT_CAUSE               ,
		OD_PB_CORRECTIVE_ACTION_TYPE   ,
		OD_PB_DATE_CAPA_RECEIVED      , 
		OD_PB_QA_ENGR_EMAIL           , 
		OD_PB_APPROVAL_STATUS         , 
		OD_PB_DATE_APPROVED           , 
		OD_PB_DATE_CORR_IMPL          , 
		OD_PB_DATE_VERIFIED           , 
		OD_PB_COMMENTS_VERIFIED       , 
		OD_PB_COMMENTS                , 
		OD_PB_ATTACHMENT              , 
		OD_PB_LINK                    , 
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CAR_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_SERVICE_PROV_SCORECA_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
commit;

   
   
