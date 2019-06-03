SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_HIS_PLAN_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_CONV_PKG.pkb    	 	               |
-- | Description :  OD QA Conversion Package Body                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       01-Jun-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE OD_PB_CA_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CA_REQUEST_HISTORY_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_CAR_ID			 ,
		OD_PB_CA_TYPE  			 ,                        
		OD_PB_SKU                        ,      
		OD_PB_ITEM_DESC                  ,      
		OD_PB_SUPPLIER                   ,      
		OD_PB_CONTACT                    ,      
		OD_PB_TECH_RPT_NUM               ,      
		OD_PB_DATE_REPORTED              ,      
		OD_PB_DEFECT_SUM                 ,      
		OD_PB_DATE_CAPA_SENT             ,      
		OD_PB_DATE_CAPA_RECEIVED         ,      
		OD_PB_ROOT_CAUSE                 ,      
		OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		OD_PB_CORR_ACTION                ,      
		OD_PB_QA_ENGR_EMAIL              ,      
		OD_PB_APPROVAL_STATUS            ,      
		OD_PB_DATE_CORR_IMPL             ,      
		OD_PB_DATE_VERIFIED              ,      
		OD_PB_COMMENTS_VERIFIED          ,      
		OD_PB_DATE_APPROVED              ,      
		OD_PB_CA_NEEDED                  ,      
		OD_PB_LINK                       ,      
		OD_PB_ITEM_ID                    ,      
		OD_PB_DATE_DUE                   ,      
		OD_PB_COMMENTS                   ,      
		OD_PB_CONTACT_EMAIL              ,      
		OD_PB_CLASS                      ,      
		OD_PB_RESULTS                    ,      
		OD_PB_VENDOR_VPC                 ,
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
                'OD_PB_CA_REQUEST_HISTORY',
                '1000', 
		OD_PB_CAR_ID			 ,
		OD_PB_CA_TYPE  			 ,                        
		OD_PB_SKU                        ,      
		OD_PB_ITEM_DESC                  ,      
		OD_PB_SUPPLIER                   ,      
		OD_PB_CONTACT                    ,      
		OD_PB_TECH_RPT_NUM               ,      
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')               ,      
		OD_PB_DEFECT_SUM                 ,      
		TO_CHAR(OD_PB_DATE_CAPA_SENT,'YYYY/MM/DD')              ,      
		TO_CHAR(OD_PB_DATE_CAPA_RECEIVED,'YYYY/MM/DD')          ,      
		OD_PB_ROOT_CAUSE                 ,      
		OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		OD_PB_CORR_ACTION                ,      
		OD_PB_QA_ENGR_EMAIL              ,      
		OD_PB_APPROVAL_STATUS            ,      
		TO_CHAR(OD_PB_DATE_CORR_IMPL,'YYYY/MM/DD')              ,      
		TO_CHAR(OD_PB_DATE_VERIFIED,'YYYY/MM/DD')               ,      
		OD_PB_COMMENTS_VERIFIED          ,      
		TO_CHAR(OD_PB_DATE_APPROVED,'YYYY/MM/DD')               ,      
		OD_PB_CA_NEEDED                  ,      
		OD_PB_LINK                       ,      
		OD_PB_ITEM_ID                    ,      
		TO_CHAR(OD_PB_DATE_DUE,'YYYY/MM/DD')                    ,      
		OD_PB_COMMENTS                   ,      
		OD_PB_CONTACT_EMAIL              ,      
		OD_PB_CLASS                      ,      
		OD_PB_RESULTS                    ,      
		OD_PB_VENDOR_VPC                 ,
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CAR_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CA_REQUEST_HISTORY_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CA_HIS_INS;

PROCEDURE OD_PB_CA_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,a.*
    FROM apps.Q_OD_PB_CA_REQUEST_HISTORY_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_CA_REQUEST_HISTORY'
     AND a.plan_name=c.name
     AND a.od_pb_car_id IS NULL;

 CURSOR C2 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_car_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_CA_REQUEST_V b,
         apps.Q_OD_PB_CA_REQUEST_HISTORY_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_CA_REQUEST_HISTORY'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_car_id
     AND a.od_pb_car_id iS NOT NULL;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		character1,			--OD_PB_CA_TYPE                        
		character2,			--OD_PB_SKU          
		character3,			--OD_PB_ITEM_DESC    
		character4,			--OD_PB_SUPPLIER     
		character5,			--OD_PB_CONTACT      
		character6,			--OD_PB_TECH_RPT_NUM 
		character7,			--OD_PB_DATE_REPORTED
		comment1,			--OD_PB_DEFECT_SUM                 ,      
		character8,			--TO_CHAR(OD_PB_DATE_CAPA_SENT,'YYYY/MM/DD')              ,      
		character9,			--TO_CHAR(OD_PB_DATE_CAPA_RECEIVED,'YYYY/MM/DD')          ,      
		comment2,			--OD_PB_ROOT_CAUSE                 ,      
		character10,			--OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		comment3,			--OD_PB_CORR_ACTION                ,      
		character11,			--OD_PB_QA_ENGR_EMAIL              ,      
		character12,			--OD_PB_APPROVAL_STATUS            ,      
		character13,			--TO_CHAR(OD_PB_DATE_CORR_IMPL,'YYYY/MM/DD')              ,      
		character14,			--TO_CHAR(OD_PB_DATE_VERIFIED,'YYYY/MM/DD')               ,      
		character15,			--OD_PB_COMMENTS_VERIFIED          ,      
		character16,			--TO_CHAR(OD_PB_DATE_APPROVED,'YYYY/MM/DD')               ,      
		character17,			--OD_PB_CA_NEEDED                  ,      
		comment4,			--OD_PB_LINK                       ,      
		character18,			--OD_PB_ITEM_ID                    ,      
		character19,			--TO_CHAR(OD_PB_DATE_DUE,'YYYY/MM/DD')                    ,      
		comment5,			--OD_PB_COMMENTS                   ,      
		character20,			--OD_PB_CONTACT_EMAIL              ,      
		character21,			--OD_PB_CLASS                      ,      
		character22,			--OD_PB_RESULTS                    ,   
		character23,			--OD_PB_VENDOR_VPC                 ,
		character24,			--OD_PB_LEGACY_COL_ID
		character25)			--OD_PB_LEGACY_OCR_ID
	VALUES
		(apps.QA_COLLECTION_ID_S.NEXTVAL,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.OD_PB_CA_TYPE  			 ,                        
		 cur.OD_PB_SKU                        ,      
		 cur.OD_PB_ITEM_DESC                  ,      
		 cur.OD_PB_SUPPLIER                   ,      
		 cur.OD_PB_CONTACT                    ,      
		 cur.OD_PB_TECH_RPT_NUM               ,      
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)               ,      
		 cur.OD_PB_DEFECT_SUM                 ,      
		 TO_CHAR(cur.OD_PB_DATE_CAPA_SENT)              ,      
		 TO_CHAR(cur.OD_PB_DATE_CAPA_RECEIVED)          ,      
		 cur.OD_PB_ROOT_CAUSE                 ,      
		 cur.OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		 cur.OD_PB_CORR_ACTION                ,      
		 cur.OD_PB_QA_ENGR_EMAIL              ,      
		 cur.OD_PB_APPROVAL_STATUS            ,      
		 TO_CHAR(cur.OD_PB_DATE_CORR_IMPL)              ,      
		 TO_CHAR(cur.OD_PB_DATE_VERIFIED)               ,      
		 cur.OD_PB_COMMENTS_VERIFIED          ,      
		 TO_CHAR(cur.OD_PB_DATE_APPROVED)               ,      
		 cur.OD_PB_CA_NEEDED                  ,      
		 cur.OD_PB_LINK                       ,      
		 cur.OD_PB_ITEM_ID                    ,      
		 TO_CHAR(cur.OD_PB_DATE_DUE)                    ,      
		 cur.OD_PB_COMMENTS                   ,      
		 cur.OD_PB_CONTACT_EMAIL              ,      
		 cur.OD_PB_CLASS                      ,      
		 cur.OD_PB_RESULTS                    ,    
		 cur.OD_PB_VENDOR_VPC,
		 cur.collection_id,
		 cur.source_line_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal CARID NULL:'||total_rec);
 dbms_output.put_line('Error CARID NULL:'||error_rec);

 total_rec:=0;
 error_rec:=0;
 FOR cur IN C2 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence1 ,			--OD_PB_CAR_ID
		character1,			--OD_PB_CA_TYPE                        
		character2,			--OD_PB_SKU          
		character3,			--OD_PB_ITEM_DESC    
		character4,			--OD_PB_SUPPLIER     
		character5,			--OD_PB_CONTACT      
		character6,			--OD_PB_TECH_RPT_NUM 
		character7,			--OD_PB_DATE_REPORTED
		comment1,			--OD_PB_DEFECT_SUM                 ,      
		character8,			--TO_CHAR(OD_PB_DATE_CAPA_SENT,'YYYY/MM/DD')              ,      
		character9,			--TO_CHAR(OD_PB_DATE_CAPA_RECEIVED,'YYYY/MM/DD')          ,      
		comment2,			--OD_PB_ROOT_CAUSE                 ,      
		character10,			--OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		comment3,			--OD_PB_CORR_ACTION                ,      
		character11,			--OD_PB_QA_ENGR_EMAIL              ,      
		character12,			--OD_PB_APPROVAL_STATUS            ,      
		character13,			--TO_CHAR(OD_PB_DATE_CORR_IMPL,'YYYY/MM/DD')              ,      
		character14,			--TO_CHAR(OD_PB_DATE_VERIFIED,'YYYY/MM/DD')               ,      
		character15,			--OD_PB_COMMENTS_VERIFIED          ,      
		character16,			--TO_CHAR(OD_PB_DATE_APPROVED,'YYYY/MM/DD')               ,      
		character17,			--OD_PB_CA_NEEDED                  ,      
		comment4,			--OD_PB_LINK                       ,      
		character18,			--OD_PB_ITEM_ID                    ,      
		character19,			--TO_CHAR(OD_PB_DATE_DUE,'YYYY/MM/DD')                    ,      
		comment5,			--OD_PB_COMMENTS                   ,      
		character20,			--OD_PB_CONTACT_EMAIL              ,      
		character21,			--OD_PB_CLASS                      ,      
		character22,			--OD_PB_RESULTS                    ,      
		character23,			--OD_PB_VENDOR_VPC                 ,
		character24,			--OD_PB_LEGACY_COL_ID
		character25,			--OD_PB_LEGACY_OCR_ID
		character26)			--OD_PB_LEGACY_REC_ID		
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_CA_TYPE  			 ,                        
		 cur.OD_PB_SKU                        ,      
		 cur.OD_PB_ITEM_DESC                  ,      
		 cur.OD_PB_SUPPLIER                   ,      
		 cur.OD_PB_CONTACT                    ,      
		 cur.OD_PB_TECH_RPT_NUM               ,      
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)               ,      
		 cur.OD_PB_DEFECT_SUM                 ,      
		 TO_CHAR(cur.OD_PB_DATE_CAPA_SENT)              ,      
		 TO_CHAR(cur.OD_PB_DATE_CAPA_RECEIVED)          ,      
		 cur.OD_PB_ROOT_CAUSE                 ,      
		 cur.OD_PB_CORRECTIVE_ACTION_TYPE     ,      
		 cur.OD_PB_CORR_ACTION                ,      
		 cur.OD_PB_QA_ENGR_EMAIL              ,      
		 cur.OD_PB_APPROVAL_STATUS            ,      
		 TO_CHAR(cur.OD_PB_DATE_CORR_IMPL)              ,      
		 TO_CHAR(cur.OD_PB_DATE_VERIFIED)               ,      
		 cur.OD_PB_COMMENTS_VERIFIED          ,      
		 TO_CHAR(cur.OD_PB_DATE_APPROVED)               ,      
		 cur.OD_PB_CA_NEEDED                  ,      
		 cur.OD_PB_LINK                       ,      
		 cur.OD_PB_ITEM_ID                    ,      
		 TO_CHAR(cur.OD_PB_DATE_DUE)                    ,      
		 cur.OD_PB_COMMENTS                   ,      
		 cur.OD_PB_CONTACT_EMAIL              ,      
		 cur.OD_PB_CLASS                      ,      
		 cur.OD_PB_RESULTS                    ,      
		 cur.OD_PB_VENDOR_VPC,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_car_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;

 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_CA_HIS;

PROCEDURE OD_PB_ECR_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_ECR_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_ECR_ID			,                           
		OD_PB_DATE_REQUESTED            ,       
		OD_PB_VENDOR_ID                 ,       
		OD_PB_SUPPLIER                  ,       
		OD_PB_CONTACT                   ,       
		OD_PB_VENDOR_EMAIL              ,       
		OD_PB_FACTORY_ID                ,       
		OD_PB_FACTORY_NAME              ,       
		OD_PB_FACTORY_CONTACT           ,       
		OD_PB_PRODUCT_AFFECTED          ,       
		OD_PB_SKU                       ,       
		OD_PB_DEPARTMENT                ,       
		OD_PB_CLASS                     ,       
		OD_PB_CHANGE_DESC               ,       
		OD_PB_DATE_PROPOSED_PRODUCTION  ,       
		OD_PB_CHG_CAT_AESTHETICS        ,       
		OD_PB_CHG_CAT_DESIGN            ,       
		OD_PB_CHG_CAT_LOCATION          ,       
		OD_PB_CHG_CAT_PACKAGING         ,       
		OD_PB_CHG_CAT_PERFORMANCE       ,       
		OD_PB_CHG_CAT_SAFETY            ,       
		OD_PB_CHG_CAT_SOFTWARE          ,       
		OD_PB_CHG_CAT_SUBSTITUTION      ,       
		OD_PB_QA_ENGINEER               ,       
		OD_PB_ATTACHMENT                ,       
		OD_PB_TECH_RPT_NUM              ,       
		OD_PB_COMMENTS                  ,       
		OD_PB_APPROVAL_STATUS           ,       
		OD_PB_DATE_QA_RESPONSE          ,       
		OD_PB_LINK                      ,       
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
                'OD_PB_ECR_HIST',
                '1000', 
		OD_PB_ECR_ID			,                           
		TO_CHAR(OD_PB_DATE_REQUESTED,'YYYY/MM/DD')             ,       
		OD_PB_VENDOR_ID                 ,       
		OD_PB_SUPPLIER                  ,       
		OD_PB_CONTACT                   ,       
		OD_PB_VENDOR_EMAIL              ,       
		OD_PB_FACTORY_ID                ,       
		OD_PB_FACTORY_NAME              ,       
		OD_PB_FACTORY_CONTACT           ,       
		OD_PB_PRODUCT_AFFECTED          ,       
		OD_PB_SKU                       ,       
		OD_PB_DEPARTMENT                ,       
		OD_PB_CLASS                     ,       
		OD_PB_CHANGE_DESC               ,       
		TO_CHAR(OD_PB_DATE_PROPOSED_PRODUCTION,'YYYY/MM/DD')   ,       
		OD_PB_CHG_CAT_AESTHETICS        ,       
		OD_PB_CHG_CAT_DESIGN            ,       
		OD_PB_CHG_CAT_LOCATION          ,       
		OD_PB_CHG_CAT_PACKAGING         ,       
		OD_PB_CHG_CAT_PERFORMANCE       ,       
		OD_PB_CHG_CAT_SAFETY            ,       
		OD_PB_CHG_CAT_SOFTWARE          ,       
		OD_PB_CHG_CAT_SUBSTITUTION      ,       
		OD_PB_QA_ENGINEER               ,       
		OD_PB_ATTACHMENT                ,       
		OD_PB_TECH_RPT_NUM              ,       
		OD_PB_COMMENTS                  ,       
		OD_PB_APPROVAL_STATUS           ,       
		TO_CHAR(OD_PB_DATE_QA_RESPONSE,'YYYY/MM/DD')           ,       
		OD_PB_LINK                      ,       
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_ECR_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
    apps.Q_OD_PB_ECR_HIST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_ECR_HIS_INS;

PROCEDURE OD_PB_ECR_HIS IS
 CURSOR C2 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_ecr_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_ECR_V b,
         apps.Q_OD_PB_ECR_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_ECR_HIST'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_ecr_id;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C2 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence2,			--OD_PB_ECR_ID                           
		character1,			--OD_PB_DATE_REQUESTED                   
		character2,			--OD_PB_VENDOR_ID                        
		character3,			--OD_PB_SUPPLIER                         
		character4,			--OD_PB_CONTACT                          
		character5,			--OD_PB_VENDOR_EMAIL                     
		character6,			--OD_PB_FACTORY_ID                       
		character7,			--OD_PB_FACTORY_NAME                     
		character8,			--OD_PB_FACTORY_CONTACT                  
		character9,			--OD_PB_PRODUCT_AFFECTED                 
		character10,			--OD_PB_SKU                              
		character26,			--OD_PB_DEPARTMENT                       
		character11,			--OD_PB_CLASS                            
		comment1,			--OD_PB_CHANGE_DESC                      
		character12,			--OD_PB_DATE_PROPOSED_PRODUCTION         
		character13,			--OD_PB_CHG_CAT_AESTHETICS               
		character14,			--OD_PB_CHG_CAT_DESIGN                   
		character15,			--OD_PB_CHG_CAT_LOCATION                 
		character16,			--OD_PB_CHG_CAT_PACKAGING                
		character17,			--OD_PB_CHG_CAT_PERFORMANCE              
		character18,			--OD_PB_CHG_CAT_SAFETY                   
		character19,			--OD_PB_CHG_CAT_SOFTWARE                 
		character20,			--OD_PB_CHG_CAT_SUBSTITUTION             
		character21,			--OD_PB_QA_ENGINEER                      
		character22,			--OD_PB_ATTACHMENT                       
		character23,			--OD_PB_TECH_RPT_NUM                     
		comment2,			--OD_PB_COMMENTS                         
		character24,			--OD_PB_APPROVAL_STATUS                  
		character25,			--OD_PB_DATE_QA_RESPONSE                 
		comment3,			--OD_PB_LINK                             
		character27,			--LEGACY_COL
		character28,			--LEGACY_OCR
		character29)			--LEGACY_REC
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
	  	 TO_CHAR(cur.OD_PB_DATE_REQUESTED)         ,          
		 cur.OD_PB_VENDOR_ID                        ,
		 cur.OD_PB_SUPPLIER                         , 
		 cur.OD_PB_CONTACT                          ,
		 cur.OD_PB_VENDOR_EMAIL                    , 
		 cur.OD_PB_FACTORY_ID                       ,
		 cur.OD_PB_FACTORY_NAME                    , 
		 cur.OD_PB_FACTORY_CONTACT                  ,
		 cur.OD_PB_PRODUCT_AFFECTED                 ,
		 cur.OD_PB_SKU                              ,
		 cur.OD_PB_DEPARTMENT                      , 
		 cur.OD_PB_CLASS                            ,
		 cur.OD_PB_CHANGE_DESC                      ,
		 TO_CHAR(cur.OD_PB_DATE_PROPOSED_PRODUCTION) ,        
		 cur.OD_PB_CHG_CAT_AESTHETICS               ,
		 cur.OD_PB_CHG_CAT_DESIGN                   ,
		 cur.OD_PB_CHG_CAT_LOCATION                 ,
		 cur.OD_PB_CHG_CAT_PACKAGING                ,
		 cur.OD_PB_CHG_CAT_PERFORMANCE              ,
		 cur.OD_PB_CHG_CAT_SAFETY                   ,
		 cur.OD_PB_CHG_CAT_SOFTWARE                 ,
		 cur.OD_PB_CHG_CAT_SUBSTITUTION             ,
		 cur.OD_PB_QA_ENGINEER                      ,
		 cur.OD_PB_ATTACHMENT                       ,
		 cur.OD_PB_TECH_RPT_NUM                     ,
		 cur.OD_PB_COMMENTS                         ,
		 cur.OD_PB_APPROVAL_STATUS                  ,
		 TO_CHAR(cur.OD_PB_DATE_QA_RESPONSE)        ,        
		 cur.OD_PB_LINK,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_ecr_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_ECR_HIS;


PROCEDURE OD_PB_FAI_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FIRST_ARTICLE_HISTO_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_RECORD_ID,
		OD_PB_SUPPLIER                ,         
		OD_PB_FACTORY_NAME             ,        
		OD_PB_SKU                      ,        
		OD_PB_DEPARTMENT               ,        
		OD_PB_PO_NUM                   ,        
		OD_PB_DATE_OF_INSPECTON        ,        
		OD_PB_RESULTS                  ,        
		OD_PB_APPROVAL_STATUS          ,   
		OD_PB_ODGSO_QA_ENGINEER	       ,
		OD_PB_QA_ENGR_EMAIL            ,        
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
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
                'OD_PB_FIRST_ARTICLE_HISTORY',
                '1000', 
		OD_PB_RECORD_ID,
		OD_PB_SUPPLIER                ,         
		OD_PB_FACTORY_NAME             ,        
		OD_PB_SKU                      ,        
		OD_PB_DEPARTMENT               ,        
		OD_PB_PO_NUM                   ,        
		OD_PB_DATE_OF_INSPECTON        ,        
		OD_PB_RESULTS                  ,        
		OD_PB_APPROVAL_STATUS          ,   
	        OD_PB_ODGSO_QA_ENGINEER     ,
		OD_PB_QA_ENGR_EMAIL            ,        
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,               
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
        apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FAI_HIS_INS;


PROCEDURE OD_PB_FAI_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_record_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V b,
	     apps.Q_OD_PB_FIRST_ARTICLE_HISTO_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_FIRST_ARTICLE_HISTORY'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_record_id;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence8,		--OD_PB_RECORD_ID
		character1,		--OD_PB_SUPPLIER          
		character2,		--OD_PB_FACTORY_NAME          
		character3,		--OD_PB_SKU          
		character4,		--OD_PB_DEPARTMENT                     
		character5,		--OD_PB_PO_NUM   
                character6,		--OD_PB_DATE_OF_INSPECTION
		character7,		--OD_PB_RESULTS          
		character8,		--OD_PB_APPROVAL_STATUS  
	        character15,		--OD_QA_ENGINEER              
		character10,		--OD_PB_QA_ENGR_EMAIL                
		character11,		--OD_PB_ATTACHMENT              
		comment1,		--OD_PB_COMMENTS
		character12,		--Legacy_collection
		character13,		--legacy_occurence
		character14)		--legacy_record_id
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_SUPPLIER 		       ,             
		 cur.OD_PB_FACTORY_NAME                ,             
		 cur.OD_PB_SKU		             ,    
		 cur.OD_PB_DEPARTMENT			,             
		 cur.OD_PB_PO_NUM			,
		 cur.OD_PB_DATE_OF_INSPECTON		,
		 cur.OD_PB_RESULTS			,
		 cur.OD_PB_APPROVAL_STATUS      	,
		 cur.OD_PB_ODGSO_QA_ENGINEER ,
		 cur.OD_PB_QA_ENGR_EMAIL		,             
		 cur.OD_PB_ATTACHMENT                  ,             
		 cur.OD_PB_COMMENTS,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_record_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_FAI_HIS;


PROCEDURE OD_PB_PPUR_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PRE_PURCHASE_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_PROJ_NUM                	   ,      
		OD_PB_PROJ_NAME                     ,   
		OD_PB_PROJ_DESC                     ,   
		OD_PB_PROJ_MGR                      ,   
		OD_PB_DOM_IMP                       ,   
		OD_PB_SOURCING_AGENT                ,   
		OD_PB_ITEM_ID                       ,   
		OD_PB_QA_PROJECT_DESC               ,   
		OD_PB_SKU                           ,   
		OD_PB_ITEM_DESC                     ,   
		OD_PB_VENDOR_VPC                    ,   
		OD_PB_SUPPLIER                      ,   
		OD_PB_CONTACT                       ,   
		OD_PB_CONTACT_PHONE                 ,   
		OD_PB_CONTACT_EMAIL                 ,   
		OD_PB_COUNTRY_OF_ORIGIN             ,   
		OD_PB_ITEM_ACTION_CODE              ,   
		OD_PB_TESTING_TYPE                  ,   
		OD_PB_TECH_RPT_NUM                  ,   
		OD_PB_ITEM_STATUS                   ,   
		OD_PB_CAP_STATUS                    ,   
		OD_PB_COMMENTS                      ,   
		OD_PB_STATUS_TIMESTAMP              ,   
		OD_PB_RESULTS                       ,   
		OD_PB_PROJ_STAT                     ,   
		OD_PB_QA_ENGINEER                   ,   
		OD_PB_QA_ENGR_EMAIL                 ,   
		OD_PB_CA_TYPE                       ,   
		OD_PB_CLASS                         ,   
		OD_PB_DEPARTMENT                    ,   
		OD_PB_SEND_EMAIL                    ,   
		OD_PB_PROTOCOL_NUMBER               ,   
		OD_PB_PROTOCOL_NAME                 ,   
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_PRE_PURCHASE_HIST',
                '1000', 
		OD_PB_PROJ_NUM                	   ,      
		OD_PB_PROJ_NAME                     ,   
		OD_PB_PROJ_DESC                     ,   
		OD_PB_PROJ_MGR                      ,   
		OD_PB_DOM_IMP                       ,   
		OD_PB_SOURCING_AGENT                ,   
		OD_PB_ITEM_ID                       ,   
		OD_PB_QA_PROJECT_DESC               ,   
		OD_PB_SKU                           ,   
		OD_PB_ITEM_DESC                     ,   
		OD_PB_VENDOR_VPC                    ,   
		OD_PB_SUPPLIER                      ,   
		OD_PB_CONTACT                       ,   
		OD_PB_CONTACT_PHONE                 ,   
		OD_PB_CONTACT_EMAIL                 ,   
		OD_PB_COUNTRY_OF_ORIGIN             ,   
		OD_PB_ITEM_ACTION_CODE              ,   
		OD_PB_TESTING_TYPE                  ,   
		OD_PB_TECH_RPT_NUM                  ,   
		OD_PB_ITEM_STATUS                   ,   
		OD_PB_CAP_STATUS                    ,   
		OD_PB_COMMENTS                      ,   
		TO_CHAR(OD_PB_STATUS_TIMESTAMP,'YYYY/MM/DD HH24:MI:SS'),   
		OD_PB_RESULTS                       ,   
		OD_PB_PROJ_STAT                     ,   
		OD_PB_QA_ENGINEER                   ,   
		OD_PB_QA_ENGR_EMAIL                 ,   
		OD_PB_CA_TYPE                       ,   
		OD_PB_CLASS                         ,   
		OD_PB_DEPARTMENT                    ,   
		OD_PB_SEND_EMAIL                    ,   
		OD_PB_PROTOCOL_NUMBER               ,   
		OD_PB_PROTOCOL_NAME                 ,   
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PRE_PURCHASE_HIST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PPUR_HIS_INS;


PROCEDURE OD_PB_PPUR_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,a.*
    FROM apps.Q_OD_PB_PRE_PURCHASE_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_PRE_PURCHASE_HIST'
     AND a.plan_name=c.name;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		character2,  			--OD_PB_PROJECT_NUM
		character3,			--OD_PB_PROJ_NAME
		character4,			--OD_PB_PROJ_DESC
		character5,			--OD_PB_PROJ_MGR
		character6,			--OD_PB_DOM_IMP
		character7,			--OD_PB_SOURCING_AGENT
		character8,			--OD_PB_ITEM_ID
		character9,			--OD_PB_QA_PROJECT_DESC
		character10,			--OD_PB_SKU
		character11,			--OD_PB_ITEM_DESC
		character12,			--OD_PB_VENDOR_UPC
		character13,			--OD_PB_SUPPLIER
		character14,			--OD_PB_CONTACT
		character15,			--OD_PB_CONTACT_PHONE
		character16,			--OD_PB_CONTACT_EMAIL
		character17,			--OD_PB_COUNTRY_OF_ORIGIN
		character18,			--OD_PB_ITEM_ACTION_CODE
		character19,			--OD_PB_TESTING_TYPE
		character20,			--OD_PB_TECH_RPT_NUM
		character21,			--OD_PB_ITEM_STATUS
		character22,			--OD_PB_CAP_STATUS
		comment1,			--OD_PB_COMMENTS
		character23,			--OD_PB_STAUTS_TIMESTAMP
		character24,			--OD_PB_RESULTS
		character25,			--OD_PB_PROJ_STAT
		character26,			--OD_PB_QA_ENGINEER
		character27,			--OD_PB_QA_ENGR_EMAIL
		character31,			--OD_PB_CA_TYPE
		character28,			--OD_PB_CLASS
		character29,			--OD_PB_DEPARTMENT
		character1,			--OD_PB_SEND_EMAIL
		character30,			--OD_PB_PROTOCOL_NUMBER
		character32,			--OD_PB_PROTOCAL_NAME
		character33,			--LEGACY_COL
		character34)			--LEGACY_OCR
	VALUES
		(apps.QA_COLLECTION_ID_S.NEXTVAL,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.OD_PB_PROJ_NUM                	   ,      
		 cur.OD_PB_PROJ_NAME                     ,   
		 cur.OD_PB_PROJ_DESC                     ,   
		 cur.OD_PB_PROJ_MGR                      ,   
		 cur.OD_PB_DOM_IMP                       ,   
		 cur.OD_PB_SOURCING_AGENT                ,   
		 cur.OD_PB_ITEM_ID                       ,   
		 cur.OD_PB_QA_PROJECT_DESC               ,   
		 cur.OD_PB_SKU                           ,   
		 cur.OD_PB_ITEM_DESC                     ,   
		 cur.OD_PB_VENDOR_VPC                    ,   
		 cur.OD_PB_SUPPLIER                      ,   
		 cur.OD_PB_CONTACT                       ,   
		 cur.OD_PB_CONTACT_PHONE                 ,   
		 cur.OD_PB_CONTACT_EMAIL                 ,   
		 cur.OD_PB_COUNTRY_OF_ORIGIN             ,   
		 cur.OD_PB_ITEM_ACTION_CODE              ,   
		 cur.OD_PB_TESTING_TYPE                  ,   
		 cur.OD_PB_TECH_RPT_NUM                  ,   
		 cur.OD_PB_ITEM_STATUS                   ,   
		 cur.OD_PB_CAP_STATUS                    ,   
		 cur.OD_PB_COMMENTS                      ,   
		 TO_CHAR(cur.OD_PB_STATUS_TIMESTAMP),   
		 cur.OD_PB_RESULTS                       ,   
		 cur.OD_PB_PROJ_STAT                     ,   
		 cur.OD_PB_QA_ENGINEER                   ,   
		 cur.OD_PB_QA_ENGR_EMAIL                 ,   
		 cur.OD_PB_CA_TYPE                       ,   
		 cur.OD_PB_CLASS                         ,   
		 cur.OD_PB_DEPARTMENT                    ,   
		 cur.OD_PB_SEND_EMAIL                    ,   
		 cur.OD_PB_PROTOCOL_NUMBER               ,   
		 cur.OD_PB_PROTOCOL_NAME,
		 cur.collection_id,
		 cur.source_line_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_PPUR_HIS;


PROCEDURE OD_PB_PLOG_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PROCEDURES_LOG_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_COLLECTION_PLANS,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER                  ,      
		ENTERED_BY_USER,
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id	
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_PROCEDURES_LOG_HISTORY',
                '1000', 
		OD_PB_COLLECTION_PLANS,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER                  ,      
		ENTERED_BY_USER,                          
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PROCEDURES_LOG_HISTO_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PLOG_HIS_INS;


PROCEDURE OD_PB_PLOG_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,a.*
    FROM apps.Q_OD_PB_PROCEDURES_LOG_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_PROCEDURES_LOG_HISTORY'
     AND a.plan_name=c.name;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		character1,		--OD_PB_COLLECTION_PLANS           
		character2,		--OD_PB_ATTACHMENT 
		character3,		--ENTERED_BY_USER              
		character4,		--OD_PB_QA_APPROVER             
		character5,		--LEGACY_COL_ID
		character6)		--LEGACY_OCR_ID

	VALUES
		(apps.QA_COLLECTION_ID_S.NEXTVAL,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.OD_PB_COLLECTION_PLANS		       ,             
		 cur.OD_PB_ATTACHMENT	                       ,             
		 cur.ENTERED_BY_USER             ,             
		 cur.OD_PB_QA_APPROVER,			             
		 cur.collection_id,
		 cur.source_line_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_PLOG_HIS;


PROCEDURE OD_PB_PSI_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PSI_IC_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_SERVICE_TYPE                     ,
		OD_PB_INSPECTION_TYPE                  ,
		OD_PB_SOURCING_AGENT                   ,
		OD_PB_REPORT_NUMBER                    ,
		OD_PB_ORIGINAL_REPORT_NUMBER           ,
		OD_PB_DATE_VERIFICATION_BY             ,
		OD_PB_BOOKING_NUMBER                   ,
		OD_PB_DIVISION                         ,
		OD_PB_VENDOR_NAME                      ,
		OD_PB_MANUF_NAME                       ,
		OD_PB_MANUF_ID                         ,
		OD_PB_MANUF_COUNTRY_CD                 ,
		OD_PB_DATE_REPORTED                    ,
		OD_PB_DATE_PROPOSAL_PROVIDED           ,
		OD_PB_DATE_SAMPLE_SENT                 ,
		OD_PB_SKU                              ,
		OD_PB_ITEM_DESC                        ,
		OD_PB_PO_NUM                           ,
		OD_PB_DECLARED_QUANTITY                ,
		OD_PB_INSP_CERTIFICATE_NUMBER          ,
		OD_PB_DESTINATION_COUNTRY              ,
		OD_PB_GENERAL_INSPECTION_LEVEL         ,
		OD_PB_AQL                              ,
		OD_PB_INSPECTION_PROTOCOL_NUM          ,
		OD_PB_DATE_PROPOSAL_APPROVED           ,
		OD_PB_SAMPLE_SIZE                      ,
		OD_PB_DEFECT_FOUND_CRITICAL            ,
		OD_PB_DEFECT_FOUND_MAJOR               ,
		OD_PB_DEFECT_FOUND_MINOR               ,
		OD_PB_RESULTS                          ,
		OD_PB_COMMENTS                         ,
		OD_PB_ATTACHMENT                       ,
		OD_PB_INSPECTION_SERVICE_OFFIC         ,
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_PSI_IC_HIST',
                '1000', 
		OD_PB_SERVICE_TYPE                     ,
		OD_PB_INSPECTION_TYPE                  ,
		OD_PB_SOURCING_AGENT                   ,
		OD_PB_REPORT_NUMBER                    ,
		OD_PB_ORIGINAL_REPORT_NUMBER           ,
		TO_CHAR(OD_PB_DATE_VERIFICATION_BY,'YYYY/MM/DD')             ,
		OD_PB_BOOKING_NUMBER                   ,
		OD_PB_DIVISION                         ,
		OD_PB_VENDOR_NAME                      ,
		OD_PB_MANUF_NAME                       ,
		OD_PB_MANUF_ID                         ,
		OD_PB_MANUF_COUNTRY_CD                 ,
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')                    ,
		TO_CHAR(OD_PB_DATE_PROPOSAL_PROVIDED,'YYYY/MM/DD')           ,
		TO_CHAR(OD_PB_DATE_SAMPLE_SENT,'YYYY/MM/DD')                 ,
		OD_PB_SKU                              ,
		OD_PB_ITEM_DESC                        ,
		OD_PB_PO_NUM                           ,
		OD_PB_DECLARED_QUANTITY                ,
		OD_PB_INSP_CERTIFICATE_NUMBER          ,
		OD_PB_DESTINATION_COUNTRY              ,
		OD_PB_GENERAL_INSPECTION_LEVEL         ,
		OD_PB_AQL                              ,
		OD_PB_INSPECTION_PROTOCOL_NUM          ,
		TO_CHAR(OD_PB_DATE_PROPOSAL_APPROVED,'YYYY/MM/DD')           ,
		OD_PB_SAMPLE_SIZE                      ,
		OD_PB_DEFECT_FOUND_CRITICAL            ,
		OD_PB_DEFECT_FOUND_MAJOR               ,
		OD_PB_DEFECT_FOUND_MINOR               ,
		OD_PB_RESULTS                          ,
		OD_PB_COMMENTS                         ,
		OD_PB_ATTACHMENT                       ,
		OD_PB_INSPECTION_SERVICE_OFFIC         ,
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PSI_IC_HIST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PSI_HIS_INS;


PROCEDURE OD_PB_PSI_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,a.*
    FROM apps.Q_OD_PB_PSI_IC_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_PSI_IC_HIST'
     AND a.plan_name=c.name;
 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		character1,  			--OD_PB_SERVICE_TYPE
		character2,			--OD_PB_INSPECTION_TYPE                  ,
		character3,			--OD_PB_SOURCING_AGENT                   ,
		character4,			--OD_PB_REPORT_NUMBER                    ,
		character32,			--OD_PB_ORIGINAL_REPORT_NUMBER           ,
		character25,			--OD_PB_DATE_VERIFICATION_BY             ,
		character7,			--OD_PB_BOOKING_NUMBER                   ,
		character8,			--OD_PB_DIVISION                         ,
		character9,			--OD_PB_VENDOR_NAME                      ,
		character10,			--OD_PB_MANUF_NAME                       ,
		character11,			--OD_PB_MANUF_ID                         ,
		character12,			--OD_PB_MANUF_COUNTRY_CD                 ,
		character6,			--OD_PB_DATE_REPORTED                    ,
		character13,			--OD_PB_DATE_PROPOSAL_PROVIDED           ,
		character15,			--OD_PB_DATE_SAMPLE_SENT                 ,
		character16,			--OD_PB_SKU                              ,
		character17,			--OD_PB_ITEM_DESC                        ,
		character18,			--OD_PB_PO_NUM                           ,
		character19,			--OD_PB_DECLARED_QUANTITY                ,
		character20,			--OD_PB_INSP_CERTIFICATE_NUMBER          ,
		character21,			--OD_PB_DESTINATION_COUNTRY              ,
		character22,			--OD_PB_GENERAL_INSPECTION_LEVEL         ,
		character23,			--OD_PB_AQL                              ,
		character24,			--OD_PB_INSPECTION_PROTOCOL_NUM          ,
		character14,			--OD_PB_DATE_PROPOSAL_APPROVED           ,
		character26,			--OD_PB_SAMPLE_SIZE                      ,
		character27,			--OD_PB_DEFECT_FOUND_CRITICAL            ,
		character28,			--OD_PB_DEFECT_FOUND_MAJOR               ,
		character29,			--OD_PB_DEFECT_FOUND_MINOR               ,
		character31,			--OD_PB_RESULTS                          ,
		comment1,			--OD_PB_COMMENTS                         ,
		character30,			--OD_PB_ATTACHMENT                       ,
		character5,			--OD_PB_INSPECTION_SERVICE_OFFIC         ,
		character33,			--LEGACY_COL
		character34)			--LEGACY_OCR
	VALUES
		(apps.QA_COLLECTION_ID_S.NEXTVAL,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		cur.OD_PB_SERVICE_TYPE                     ,
		cur.OD_PB_INSPECTION_TYPE                  ,
		cur.OD_PB_SOURCING_AGENT                   ,
		cur.OD_PB_REPORT_NUMBER                    ,
		cur.OD_PB_ORIGINAL_REPORT_NUMBER           ,
		TO_CHAR(cur.OD_PB_DATE_VERIFICATION_BY)             ,
		cur.OD_PB_BOOKING_NUMBER                   ,
		cur.OD_PB_DIVISION                         ,
		cur.OD_PB_VENDOR_NAME                      ,
		cur.OD_PB_MANUF_NAME                       ,
		cur.OD_PB_MANUF_ID                         ,
		cur.OD_PB_MANUF_COUNTRY_CD                 ,
		TO_CHAR(cur.OD_PB_DATE_REPORTED)                    ,
		TO_CHAR(cur.OD_PB_DATE_PROPOSAL_PROVIDED)           ,
		TO_CHAR(cur.OD_PB_DATE_SAMPLE_SENT)                 ,
		cur.OD_PB_SKU                              ,
		cur.OD_PB_ITEM_DESC                        ,
		cur.OD_PB_PO_NUM                           ,
		cur.OD_PB_DECLARED_QUANTITY                ,
		cur.OD_PB_INSP_CERTIFICATE_NUMBER          ,
		cur.OD_PB_DESTINATION_COUNTRY              ,
		cur.OD_PB_GENERAL_INSPECTION_LEVEL         ,
		cur.OD_PB_AQL                              ,
		cur.OD_PB_INSPECTION_PROTOCOL_NUM          ,
		TO_CHAR(cur.OD_PB_DATE_PROPOSAL_APPROVED)           ,
		cur.OD_PB_SAMPLE_SIZE                      ,
		cur.OD_PB_DEFECT_FOUND_CRITICAL            ,
		cur.OD_PB_DEFECT_FOUND_MAJOR               ,
		cur.OD_PB_DEFECT_FOUND_MINOR               ,
		cur.OD_PB_RESULTS                          ,
		cur.OD_PB_COMMENTS                         ,
		cur.OD_PB_ATTACHMENT                       ,
		cur.OD_PB_INSPECTION_SERVICE_OFFIC,
		cur.collection_id,
		cur.source_line_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_PSI_HIS;


PROCEDURE OD_PB_SAPR_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_SPEC_APPROVAL_HISTO_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_VENDOR_NAME       ,       
		OD_PB_SKU                      ,
		OD_PB_SKU_DESCRIPTION          ,
		OD_PB_DEPARTMENT              , 
		OD_PB_QA_APPROVER              ,
		OD_PB_APPROVAL_STATUS          ,
		OD_PB_ATTACHMENT               ,
		OD_PB_COMMENTS                  ,      
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id	
        )
SELECT          collection_id,
		occurrence,  
		'1000',
                'PRJ',
                'OD_PB_SPEC_APPROVAL_HISTORY',
                '1000', 
		OD_PB_VENDOR_NAME          ,    
		OD_PB_SKU                      ,
		OD_PB_SKU_DESCRIPTION          ,
		OD_PB_DEPARTMENT              , 
		OD_PB_QA_APPROVER              ,
		OD_PB_APPROVAL_STATUS          ,
		OD_PB_ATTACHMENT               ,
		OD_PB_COMMENTS                  ,              
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_SAPR_HIS_INS;


PROCEDURE OD_PB_SAPR_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,a.*
    FROM apps.Q_OD_PB_SPEC_APPROVAL_HISTO_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_SPEC_APPROVAL_HISTORY'
     AND a.plan_name=c.name;

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		character1,		--OD_PB_VENDOR_NAME           
		character2,		--OD_PB_SKU          
		character3,		--OD_PB_SKU_DESCRIPTION          
		character4,		--OD_PB_DEPARTMENT                     
		character6,		--OD_PB_QA_APPROVER             
		character7,		--OD_PB_APPROVAL_STATUS              
		character8,		--OD_PB_ATTACHMENT                
		comment1,		--OD_PB_COMMENTS              
		character5,		--LEGACY_COL_ID
		character9)		--LEGACY_OCR_ID

	VALUES
		(apps.QA_COLLECTION_ID_S.NEXTVAL,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.OD_PB_VENDOR_NAME		       ,             
		 cur.OD_PB_SKU	                       ,             
		 cur.OD_PB_SKU_DESCRIPTION             ,             
		 cur.OD_PB_DEPARTMENT		       ,
		 cur.OD_PB_QA_APPROVER,			             
		 cur.OD_PB_APPROVAL_STATUS      	,             
		 cur.OD_PB_ATTACHMENT                  ,             
		 cur.OD_PB_COMMENTS,
		 cur.collection_id,
		 cur.source_line_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_SAPR_HIS;


PROCEDURE OD_PB_ATS_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_ATS_HISTORY_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_ATS_ID       ,             
		OD_PB_CA_TYPE            ,              
		OD_PB_REPORT_NUMBER       ,             
		OD_PB_DATE_REPORTED       ,             
		OD_PB_QA_ACTIVITY_NUMBER   ,            
		OD_PB_MANUF_NAME           ,            
		OD_PB_SKU                  ,            
		OD_PB_SKU_DESCRIPTION      ,            
		OD_PB_DEPARTMENT           ,            
		OD_PB_REASON_FOR_WAIVING   ,            
		OD_PB_FAILURE              ,            
		OD_PB_PENDING_SUPPLIER_ACTION,          
		OD_PB_FOLLOW_UP_DATE         ,          
		OD_PB_AUTHORIZED             ,          
		OD_PB_ATS_ISSUE_DATE         ,          
		OD_PB_LINK                   ,          
		OD_PB_COMMENTS               ,          
		OD_PB_ATTACHMENT             ,          
		OD_PB_APPROVAL_STATUS        , 
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
                'OD_PB_ATS_HISTORY',
                '1000', 
		OD_PB_ATS_ID       ,             
		OD_PB_CA_TYPE            ,              
		OD_PB_REPORT_NUMBER       ,             
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')       ,             
		OD_PB_QA_ACTIVITY_NUMBER   ,            
		OD_PB_MANUF_NAME           ,            
		OD_PB_SKU                  ,            
		OD_PB_SKU_DESCRIPTION      ,            
		OD_PB_DEPARTMENT           ,            
		OD_PB_REASON_FOR_WAIVING   ,            
		OD_PB_FAILURE              ,            
		OD_PB_PENDING_SUPPLIER_ACTION,          
		OD_PB_FOLLOW_UP_DATE         ,          
		OD_PB_AUTHORIZED             ,          
		OD_PB_ATS_ISSUE_DATE         ,          
		OD_PB_LINK                   ,          
		OD_PB_COMMENTS               ,          
		OD_PB_ATTACHMENT             ,          
		OD_PB_APPROVAL_STATUS      ,
		d.user_id,
     	        e.user_id,
		a.collection_id,
		a.occurrence,
		a.OD_PB_ATS_ID		
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_ATS_HISTORY_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name
   AND  a.OD_PB_ATS_ID NOT LIKE '%EU%';
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_ATS_HIS_INS;


PROCEDURE OD_PB_ATS_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_ats_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V b,
         apps.Q_OD_PB_ATS_HISTORY_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_ATS_HISTORY'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_ats_id
     AND b.OD_PB_ATS_ID NOT LIKE '%EU%';

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence11,		--OD_PB_ATS_ID                           
		character1,		--OD_PB_CA_TYPE                          
		character2,		--OD_PB_REPORT_NUMBER                    
		character3,		--OD_PB_DATE_REPORTED                    
		character4,		--OD_PB_QA_ACTIVITY_NUMBER               
		character5,		--OD_PB_MANUF_NAME	                       
		character6,		--OD_PB_SKU                              
		character7,		--OD_PB_SKU_DESCRIPTION                  
		character8,		--OD_PB_DEPARTMENT                       
		comment3,		--OD_PB_REASON_FOR_WAIVING               
		comment4,		--OD_PB_FAILURE                          
		character10,		--OD_PB_PENDING_SUPPLIER_ACTION          
		character11,		--OD_PB_FOLLOW_UP_DATE                   
		character12,		--OD_PB_AUTHORIZED                       
		character13,		--OD_PB_ATS_ISSUE_DATE                   
		comment1,		--OD_PB_LINK                             
		comment2,		--OD_PB_COMMENTS                         
		character14,		--OD_PB_ATTACHMENT                       
		character15,		--OD_PB_APPROVAL_STATUS                  
		character9,		--OB_PB_LEGACY_COL_ID
		character16,		--OB_PB_LEGACY_OCR_ID
		character17)		--OB_PB_LEGACY_REC_ID
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
  	 	 cur.OD_PB_CA_TYPE            ,              
		 cur.OD_PB_REPORT_NUMBER       ,             
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)       ,             
		 cur.OD_PB_QA_ACTIVITY_NUMBER   ,            
		 cur.OD_PB_MANUF_NAME           ,            
		 cur.OD_PB_SKU                  ,            
		 cur.OD_PB_SKU_DESCRIPTION      ,            
		 cur.OD_PB_DEPARTMENT           ,            
		 cur.OD_PB_REASON_FOR_WAIVING   ,            
		 cur.OD_PB_FAILURE              ,            
		 cur.OD_PB_PENDING_SUPPLIER_ACTION,          
		 cur.OD_PB_FOLLOW_UP_DATE         ,          
		 cur.OD_PB_AUTHORIZED             ,          
		 cur.OD_PB_ATS_ISSUE_DATE         ,          
		 cur.OD_PB_LINK                   ,          
		 cur.OD_PB_COMMENTS               ,          
		 cur.OD_PB_ATTACHMENT             ,          
		 cur.OD_PB_APPROVAL_STATUS,
	         cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_ats_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_ATS_HIS;


PROCEDURE OD_PB_CUSCOMP_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		OD_PB_DATE_REPORTED               ,             
		OD_PB_DATE_OPENED                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		OD_PB_DATE_SAMPLE_RECEIVED        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
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
                'OD_PB_CUSTOMER_COMPLAINTS_HIST',
                '1000', 
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')               ,             
		TO_CHAR(OD_PB_DATE_OPENED,'YYYY/MM/DD')                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		TO_CHAR(OD_PB_DATE_SAMPLE_RECEIVED,'YYYY/MM/DD')        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CUSTOMER_COMPLAINT_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name
   AND  a.OD_PB_CUSTOMER_COMPLAINT_ID NOT LIKE '%EU%';
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CUSCOMP_HIS_INS;


PROCEDURE OD_PB_CUSCOMP_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_customer_complaint_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V b,
	     apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_CUSTOMER_COMPLAINTS_HIST'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_customer_complaint_id
     AND b.OD_PB_CUSTOMER_COMPLAINT_ID NOT LIKE '%EU%';

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence12,		--OD_PB_CUSTOMER_COMPLAINT_ID    
		character1,		--OD_PB_CA_TYPE                  
		character2,		--OD_PB_QA_ENGR_EMAIL            
		character3,		--OD_PB_DATE_REPORTED            
		character4,		--OD_PB_DATE_OPENED              
		character5,		--OD_PB_SKU                      
		character16,		--OD_PB_DEPARTMENT               
		character6,		--OD_PB_ITEM_DESC                
		character7,		--OD_PB_SUPPLIER                 
		comment1,		--OD_PB_DEFECT_SUM               
		character8,		--OD_PB_PRODUCT_ALERT            
		character9,		--OD_PB_SAMPLE_AVAILABLE         
		character10,		--OD_PB_DATE_SAMPLE_RECEIVED     
		character11,		--OD_PB_CA_NEEDED                
		character12,		--OD_PB_CORRECTIVE_ACTION_ID     
		character13,		--OD_PB_ROOT_CAUSE_TYPE          
		comment2,		--OD_PB_COMMENTS                 
		character14,		--OD_PB_DATE_CLOSED              
		character15,		--OD_PB_POPT_CANDIDATE
		character17,		--legacy_col
		character18,		--legacy_ocr
		character19)		--legacy_rec
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_CA_TYPE                     ,             
		 cur.OD_PB_QA_ENGR_EMAIL               ,             
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)               ,             
		 TO_CHAR(cur.OD_PB_DATE_OPENED)                 ,             
		 cur.OD_PB_SKU                         ,             
		 cur.OD_PB_DEPARTMENT                  ,             
		 cur.OD_PB_ITEM_DESC                   ,             
		 cur.OD_PB_SUPPLIER                    ,             
		 cur.OD_PB_DEFECT_SUM                  ,             
		 cur.OD_PB_PRODUCT_ALERT               ,             
		 cur.OD_PB_SAMPLE_AVAILABLE            ,             
		 TO_CHAR(cur.OD_PB_DATE_SAMPLE_RECEIVED)        ,             
		 cur.OD_PB_CA_NEEDED                   ,             
		 cur.OD_PB_CORRECTIVE_ACTION_ID        ,             
		 cur.OD_PB_ROOT_CAUSE_TYPE             ,             
		 cur.OD_PB_COMMENTS  	          ,                     
		 cur.OD_PB_DATE_CLOSED                 ,             
		 cur.OD_PB_POPT_CANDIDATE,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_customer_complaint_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_CUSCOMP_HIS;


PROCEDURE OD_PB_CUSCOMPEU_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		OD_PB_DATE_REPORTED               ,             
		OD_PB_DATE_OPENED                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		OD_PB_DATE_SAMPLE_RECEIVED        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
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
                'OD_PB_CUSTOMER_COMPLAINTS_HIST',
                '1000', 
		OD_PB_CUSTOMER_COMPLAINT_ID       ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_QA_ENGR_EMAIL               ,             
		TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')               ,             
		TO_CHAR(OD_PB_DATE_OPENED,'YYYY/MM/DD')                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_ITEM_DESC                   ,             
		OD_PB_SUPPLIER                    ,             
		OD_PB_DEFECT_SUM                  ,             
		OD_PB_PRODUCT_ALERT               ,             
		OD_PB_SAMPLE_AVAILABLE            ,             
		TO_CHAR(OD_PB_DATE_SAMPLE_RECEIVED,'YYYY/MM/DD')        ,             
		OD_PB_CA_NEEDED                   ,             
		OD_PB_CORRECTIVE_ACTION_ID        ,             
		OD_PB_ROOT_CAUSE_TYPE             ,             
		OD_PB_COMMENTS  	          ,                     
		OD_PB_DATE_CLOSED                 ,             
		OD_PB_POPT_CANDIDATE              ,             
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CUSTOMER_COMPLAINT_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name
   AND  a.OD_PB_CUSTOMER_COMPLAINT_ID LIKE '%EU%';
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CUSCOMPEU_HIS_INS;


PROCEDURE OD_PB_CUSCOMPEU_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_customer_complaint_id_eu Mrecord_id,a.*
    FROM apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V b,
	     apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_CUSTOMER_COMPLAINTS_HIST'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_customer_complaint_id 
     AND b.OD_PB_CUSTOMER_COMPLAINT_ID_EU LIKE '%EU%';

 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence12,		--OD_PB_CUSTOMER_COMPLAINT_ID    
		character1,		--OD_PB_CA_TYPE                  
		character2,		--OD_PB_QA_ENGR_EMAIL            
		character3,		--OD_PB_DATE_REPORTED            
		character4,		--OD_PB_DATE_OPENED              
		character5,		--OD_PB_SKU                      
		character16,		--OD_PB_DEPARTMENT               
		character6,		--OD_PB_ITEM_DESC                
		character7,		--OD_PB_SUPPLIER                 
		comment1,		--OD_PB_DEFECT_SUM               
		character8,		--OD_PB_PRODUCT_ALERT            
		character9,		--OD_PB_SAMPLE_AVAILABLE         
		character10,		--OD_PB_DATE_SAMPLE_RECEIVED     
		character11,		--OD_PB_CA_NEEDED                
		character12,		--OD_PB_CORRECTIVE_ACTION_ID     
		character13,		--OD_PB_ROOT_CAUSE_TYPE          
		comment2,		--OD_PB_COMMENTS                 
		character14,		--OD_PB_DATE_CLOSED              
		character15,		--OD_PB_POPT_CANDIDATE
		character17,		--legacy_col
		character18,		--legacy_ocr
		character19)		--legacy_rec
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_CA_TYPE                     ,             
		 cur.OD_PB_QA_ENGR_EMAIL               ,             
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)               ,             
		 TO_CHAR(cur.OD_PB_DATE_OPENED)                 ,             
		 cur.OD_PB_SKU                         ,             
		 cur.OD_PB_DEPARTMENT                  ,             
		 cur.OD_PB_ITEM_DESC                   ,             
		 cur.OD_PB_SUPPLIER                    ,             
		 cur.OD_PB_DEFECT_SUM                  ,             
		 cur.OD_PB_PRODUCT_ALERT               ,             
		 cur.OD_PB_SAMPLE_AVAILABLE            ,             
		 TO_CHAR(cur.OD_PB_DATE_SAMPLE_RECEIVED)        ,             
		 cur.OD_PB_CA_NEEDED                   ,             
		 cur.OD_PB_CORRECTIVE_ACTION_ID        ,             
		 cur.OD_PB_ROOT_CAUSE_TYPE             ,             
		 cur.OD_PB_COMMENTS  	          ,                     
		 cur.OD_PB_DATE_CLOSED                 ,             
		 cur.OD_PB_POPT_CANDIDATE,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_customer_complaint_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_CUSCOMPEU_HIS;


PROCEDURE OD_PB_FQA_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FQA_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_FQA_ID_ODC                ,               
	 	 OD_PB_SUPPLIER                 ,                
		 OD_PB_FACTORY_NAME             ,                
		 OD_PB_CATEGORY                 ,                
		 OD_PB_FACTORY_ADDRESS          ,                
		 OD_PB_FACTORY_CONTACT          ,                
		 OD_PB_FQA_ASSIGNED_DATE        ,                
		 OD_PB_AUDIT_DATE               ,                
		 OD_PB_DATE_REPORTED            ,                
		 OD_PB_AUDITOR_NAME             ,                
		 OD_PB_AUDIT_TYPE               ,                
		 OD_PB_VENDOR_ID                ,                
		 OD_PB_SKU                      ,                
		 OD_PB_DEPARTMENT               ,                
		 OD_PB_DESIGN_CONTROL_SCORE     ,                
		 OD_PB_PURCHASE_CONTROL_SCORE   ,                
		 OD_PB_STORAGE_MANAGEMENT_SCORE ,                
		 OD_PB_INCOMING_INSPECT_SCORE   ,                
		 OD_PB_PRODUCTION_CONTROL_SCORE ,                
		 OD_PB_CONTINUOUS_IMPROVE_SCORE ,                
		 OD_PB_FQA_GENERAL              ,                
		 OD_PB_AUDIT_GRADE              ,                
		 OD_PB_APPROVAL_STATUS          ,                
		 OD_PB_COMMENTS                 ,                
		 OD_PB_FQA_ID                   ,                
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
                'OD_PB_FQA',
                '1000', 
		OD_PB_FQA_ID_ODC                ,               
	 	 OD_PB_SUPPLIER                 ,                
		 OD_PB_FACTORY_NAME             ,                
		 OD_PB_CATEGORY                 ,                
		 OD_PB_FACTORY_ADDRESS          ,                
		 OD_PB_FACTORY_CONTACT          ,                
		 TO_CHAR(OD_PB_FQA_ASSIGNED_DATE,'YYYY/MM/DD')        ,                
		 TO_CHAR(OD_PB_AUDIT_DATE,'YYYY/MM/DD')               ,                
		 TO_CHAR(OD_PB_DATE_REPORTED,'YYYY/MM/DD')            ,                
		 OD_PB_AUDITOR_NAME             ,                
		 OD_PB_AUDIT_TYPE               ,                
		 OD_PB_VENDOR_ID                ,                
		 OD_PB_SKU                      ,                
		 OD_PB_DEPARTMENT               ,                
		 OD_PB_DESIGN_CONTROL_SCORE     ,                
		 OD_PB_PURCHASE_CONTROL_SCORE   ,                
		 OD_PB_STORAGE_MANAGEMENT_SCORE ,                
		 OD_PB_INCOMING_INSPECT_SCORE   ,                
		 OD_PB_PRODUCTION_CONTROL_SCORE ,                
		 OD_PB_CONTINUOUS_IMPROVE_SCORE ,                
		 OD_PB_FQA_GENERAL              ,                
		 OD_PB_AUDIT_GRADE              ,                
		 OD_PB_APPROVAL_STATUS          ,                
		 OD_PB_COMMENTS                 ,                
		 OD_PB_FQA_ID                   ,                
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_FQA_ID_ODC
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FQA_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FQA_HIS_INS;


PROCEDURE OD_PB_FQA_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_fqa_id_odc Mrecord_id,a.*
    FROM apps.Q_OD_PB_FQA_ODC_V b,
	     apps.Q_OD_PB_FQA_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_FQA'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.OD_PB_FQA_ID_ODC;
 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence6,			--OD_PB_FQA_ID_ODC 
		character1,			--OD_PB_SUPPLIER                                 
		character2,			--OD_PB_FACTORY_NAME                             
		character3,			--OD_PB_CATEGORY                                 
		character4,			--OD_PB_FACTORY_ADDRESS                          
		character5,			--OD_PB_FACTORY_CONTACT                          
		character20,			--OD_PB_FQA_ASSIGNED_DATE                        
		character21,			--OD_PB_AUDIT_DATE                               
		character6,			--OD_PB_DATE_REPORTED                            
		character7,			--OD_PB_AUDITOR_NAME                             
		character8,			--OD_PB_AUDIT_TYPE                               
		character9,			--OD_PB_VENDOR_ID                                
		character10,			--OD_PB_SKU                                      
		character22,			--OD_PB_DEPARTMENT                               
		character11,			--OD_PB_DESIGN_CONTROL_SCORE                     
		character12,			--OD_PB_PURCHASE_CONTROL_SCORE                   
		character13,			--OD_PB_STORAGE_MANAGEMENT_SCORE                 
		character14,			--OD_PB_INCOMING_INSPECT_SCORE                   
		character15,			--OD_PB_PRODUCTION_CONTROL_SCORE                 
		character16,			--OD_PB_CONTINUOUS_IMPROVE_SCORE                 
		character23,			--OD_PB_FQA_GENERAL                              
		character17,			--OD_PB_AUDIT_GRADE                              
		character18,			--OD_PB_APPROVAL_STATUS                          
		comment1,			--OD_PB_COMMENTS                                 
		character19,			--OD_PB_FQA_ID)
		character24,			--OD_PB_LEGACY_COL_ID
		character25,			--OD_PB_LEGACY_OCR_ID
		character26)			--OD_PB_LEGACY_REC_ID
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_SUPPLIER                         	,
		 cur.OD_PB_FACTORY_NAME                    , 
		 cur.OD_PB_CATEGORY                        , 
		 cur.OD_PB_FACTORY_ADDRESS                 , 
		 cur.OD_PB_FACTORY_CONTACT                 , 
		 TO_CHAR(cur.OD_PB_FQA_ASSIGNED_DATE)      ,          
		 TO_CHAR(cur.OD_PB_AUDIT_DATE)             ,          
		 TO_CHAR(cur.OD_PB_DATE_REPORTED)          ,          
		 cur.OD_PB_AUDITOR_NAME                    , 
		 cur.OD_PB_AUDIT_TYPE                      , 
		 cur.OD_PB_VENDOR_ID                       , 
		 cur.OD_PB_SKU                             , 
		 cur.OD_PB_DEPARTMENT                      , 
		 cur.OD_PB_DESIGN_CONTROL_SCORE            , 
		 cur.OD_PB_PURCHASE_CONTROL_SCORE          , 
		 cur.OD_PB_STORAGE_MANAGEMENT_SCORE        , 
		 cur.OD_PB_INCOMING_INSPECT_SCORE          , 
		 cur.OD_PB_PRODUCTION_CONTROL_SCORE        , 
		 cur.OD_PB_CONTINUOUS_IMPROVE_SCORE        , 
		 cur.OD_PB_FQA_GENERAL                     , 
		 cur.OD_PB_AUDIT_GRADE                     , 
		 cur.OD_PB_APPROVAL_STATUS                 , 
		 cur.OD_PB_COMMENTS                        , 
		 cur.OD_PB_FQA_ID,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.OD_PB_FQA_ID_ODC);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_FQA_HIS;


PROCEDURE OD_PB_REGCERT_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
--employee number : 801159 (Tony Tong) does not exists
INSERT INTO apps.Q_OD_PB_REG_FEES_HIST_IV
    (      	collection_id,
		source_line_id,
		process_status, 
                organization_code ,
                plan_name,
                insert_type,
		OD_PB_REGISTRATION_ID                          ,
		OD_PB_REGISTRATION_ORG                         ,
		OD_PB_DATE_OPENED                              ,
		OD_PB_FACTORY_NAME                             ,
		OD_PB_VENDOR_ID                                ,
		OD_PB_SKU                                      ,
		OD_PB_COMMENTS                                 ,
		OD_PB_CASE_NUMBER                              ,
		OD_PB_AMOUNT                                   ,
		OD_PB_DATE_DUE                                 ,
		OD_PB_DATE_CLOSED                              ,
		OD_PB_RENEW_REGISTRATION                       ,
		OD_PB_FREQUENCY                                ,
		OD_PB_DATE_RENEW                               ,
		OD_PB_ATTACHMENT                               ,
		OD_PB_REGISTRATION_NUMBER                      ,
		OD_PB_QA_ENGINEER                              ,
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
                'OD_PB_REG_FEES_HIST',
                '1000', 
		OD_PB_REGISTRATION_ID                          ,
		OD_PB_REGISTRATION_ORG                         ,
		TO_CHAR(OD_PB_DATE_OPENED,'YYYY/MM/DD')        ,
		OD_PB_FACTORY_NAME                             ,
		OD_PB_VENDOR_ID                                ,
		OD_PB_SKU                                      ,
		OD_PB_COMMENTS                                 ,
		OD_PB_CASE_NUMBER                              ,
		OD_PB_AMOUNT                                   ,
		TO_CHAR(OD_PB_DATE_DUE,'YYYY/MM/DD')           ,
		TO_CHAR(OD_PB_DATE_CLOSED,'YYYY/MM/DD')        ,
		OD_PB_RENEW_REGISTRATION                       ,
		OD_PB_FREQUENCY                                ,
		TO_CHAR(OD_PB_DATE_RENEW,'YYYY/MM/DD')         ,
		OD_PB_ATTACHMENT                               ,
		OD_PB_REGISTRATION_NUMBER                      ,
		OD_PB_QA_ENGINEER                              ,
		d.user_id,
     	        e.user_id ,
		a.collection_id,
		a.occurrence,
		a.OD_PB_registration_id
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_REG_FEES_HIST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_REGCERT_HIS_INS;


PROCEDURE OD_PB_REGCERT_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_registration_id Mrecord_id,a.*
    FROM apps.Q_OD_PB_REGULATORY_CERT_V b,
	     apps.Q_OD_PB_REG_FEES_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_REG_FEES_HIST'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_registration_id;
 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
 
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence4,	--OD_PB_REGISTRATION_ID
		character7,     --OD_PB_AMOUNT
         	character13,    --OD_PB_ATTACHMENT
		comment1,	--OD_PB_COMMENTS
		character6,     --OD_PB_CASE_NUMBER
		character8,     --OD_PB_DATE_DUE
		character9,	--OD_PB_DATE_CLOSED  
		character2,	--OD_PB_DATE_OPENED    
		character12,	--OD_PB_DATE_RENEW  
		character3,	--OD_PB_FACTORY_NAME
		character11,	--OD_PB_FREQUENCY
		character1,	--OD_PB_REGISTRATION_ORG  
		character14,	--OD_PB_REGISTRATION_NUMBER         
		character15,	--OD_PB_QA_ENGINEER
		character10,	--OD_PB_RENEW_REGISTRATION
		character4,	--OD_PB_VENDOR_ID
		character5, 	--OD_PB_SKU 
		character16,	--LEGACY_COL
		character17,	--LEGACY_OCR
		character18)	--LEGACY_REC
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_AMOUNT,
         	 cur.OD_PB_ATTACHMENT,
		 cur.OD_PB_COMMENTS,
		 cur.OD_PB_CASE_NUMBER,
		 TO_CHAR(cur.OD_PB_DATE_DUE),
		 TO_CHAR(cur.OD_PB_DATE_CLOSED)  ,
		 TO_CHAR(cur.OD_PB_DATE_OPENED)  , 
		 TO_CHAR(cur.OD_PB_DATE_RENEW) , 
		 cur.OD_PB_FACTORY_NAME,
		 cur.OD_PB_FREQUENCY,
		 cur.OD_PB_REGISTRATION_ORG  ,
		 cur.OD_PB_REGISTRATION_NUMBER,         
		 cur.OD_PB_QA_ENGINEER,
		 cur.OD_PB_RENEW_REGISTRATION,
		 cur.OD_PB_VENDOR_ID,
		 cur.OD_PB_SKU,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_registration_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_REGCERT_HIS;


PROCEDURE OD_PB_TESTING_HIS_INS IS
 v_cnt NUMBER:=0;
BEGIN
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
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_TESTING_HIS_INS;


PROCEDURE OD_PB_TESTING_HIS IS
  CURSOR C1 IS
  SELECT c.organization_id,c.plan_id,b.collection_id Mcollection_id,
	 b.od_pb_record_id Mrecord_id,a.*
    FROM apps.q_od_pb_testing_v b,
	     apps.Q_OD_PB_TESTING_HIST_IV a,
         apps.qa_plans c
   WHERE c.name='OD_PB_TESTING_HIST'
     AND a.plan_name=c.name
     AND b.od_pb_legacy_col_id=a.collection_id
     AND b.od_pb_legacy_rec_id=a.od_pb_record_id;
 Total_rec NUMBER:=0;
 Error_rec NUMBER:=0;
BEGIN
 FOR cur IN C1 LOOP
    Total_rec:=Total_rec+1;
  BEGIN
    INSERT INTO apps.qa_results
	( 	collection_id,
		occurrence,
		last_update_date,
		qa_last_update_date,
		last_updated_by,
		qa_last_updated_by,
		creation_date,
		qa_creation_date,
		created_by,
		qa_created_by,
		txn_header_id,
		organization_id,
		plan_id,
		sequence8,
		character12,  --OD_PB_1ST_ARTICLE_DEFECT_RATE  
		character32,  --OD_PB_APPROVAL_STATUS
		character31,  --OD_PB_ATTACHMENT       
		character20,  --OD_PB_AUDITOR_NAME     
		character29,	--OD_PB_CA_TYPE  
		character33,	--OD_PB_CLASS    
		comment4,	--OD_PB_COMMENTS 
		character34,	--OD_PB_COMPARISON_NAME  
		character18,	--OD_PB_CONTACT
		character1,	--OD_PB_CRITICAL
		comment1,	--OD_PB_CTQ_LIST         
		comment5,	--OD_PB_CTQ_RESULTS
		character2,	-- OD_PB_DATE_APPROVED    
		character3,	-- OD_PB_DATE_DUE         
		character4,	--OD_PB_DATE_KICKOFF
		character5,	-- OD_PB_DATE_OPENED
		character6,	--OD_PB_DATE_PROPOSAL_APPROVED
		character7,	--OD_PB_DATE_PROPOSAL_PROVIDED
		character8,	--OD_PB_DATE_REPORT_DUE
		character9,	--OD_PB_DATE_TESTING_BEGINS
		character24,	--OD_PB_DATE_REPORTED
		comment3,	--OD_PB_DEFECT_SUM
		character10,	--OD_PB_DPPM
		character11,	--OD_PB_FACTORY_ID
		character22,	--OD_PB_FQA_SCORE 
		character25,	--OD_PB_LOT_SIZE
		character36,	--OD_PB_MINOR 
		character37,	--OD_PB_MAJOR                    
		character13,	--OD_PB_MERCHANDISING_APPROVER
		character26,	--OD_PB_OBJECTIVE
		character21,	--OD_PB_ORG_AUDITED
		character14,	--OD_PB_PO_NUM
		character27,	--OD_PB_PROGRAM_TEST_TYPE
		character15,	--OD_PB_QA_APPROVER
		character30,	--OD_PB_RESULTS
		character16,	--OD_PB_SAMPLE_SIZE		
		character17,	--OD_PB_SKU
		character23,	--OD_PB_SPECIFICATION_NAME 
		character35,	--OD_PB_SUPPLIER 		
		character28,	--OD_PB_TECH_RPT_NUM
		character19,	--OD_PB_VENDORS_AWARDED
		comment2,	--OD_PB_VENDOR_COMMENTS
		character38,	--LEGACY_COL
		character39,	--LEGACY_OCR
		character40)	--LEGACY_REC
	VALUES
		(cur.mcollection_id,
		 apps.QA_OCCURRENCE_S.NEXTVAL,		
		 sysdate,
		 sysdate,
		 cur.qa_last_updated_by_name,
		 cur.qa_last_updated_by_name,
		 sysdate,
		 sysdate,
		 cur.qa_created_by_name,
		 cur.qa_created_by_name,		 		 		 
		 apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL,  -- txn_header_id
                 cur.organization_id,
		 cur.plan_id,
		 cur.mrecord_id,
		 cur.OD_PB_1ST_ARTICLE_DEFECT_RATE,  
		 cur.OD_PB_APPROVAL_STATUS,
		 cur.OD_PB_ATTACHMENT   ,    
		 cur.OD_PB_AUDITOR_NAME ,    
		 cur.OD_PB_CA_TYPE      , 
		 cur.OD_PB_CLASS        ,
		 cur.OD_PB_COMMENTS     ,
		 cur.OD_PB_COMPARISON_NAME , 
		 cur.OD_PB_CONTACT         ,
		 cur.OD_PB_CRITICAL        ,
		 cur.OD_PB_CTQ_LIST        ,
		 cur.OD_PB_CTQ_RESULTS     ,
		 TO_CHAR(cur.OD_PB_DATE_APPROVED)   , 
		 TO_CHAR(cur.OD_PB_DATE_DUE)        , 
		 TO_CHAR(cur.OD_PB_DATE_KICKOFF)    ,
		 TO_CHAR(cur.OD_PB_DATE_OPENED)			,
		 TO_CHAR(cur.OD_PB_DATE_PROPOSAL_APPROVED),
		 TO_CHAR(cur.OD_PB_DATE_PROPOSAL_PROVIDED),
		 TO_CHAR(cur.OD_PB_DATE_REPORT_DUE),
		 TO_CHAR(cur.OD_PB_DATE_TESTING_BEGINS),
		 TO_CHAR(cur.OD_PB_DATE_REPORTED),
		 cur.OD_PB_DEFECT_SUM,
		 cur.OD_PB_DPPM,
		 cur.OD_PB_FACTORY_ID,
		 cur.OD_PB_FQA_SCORE ,
		 cur.OD_PB_LOT_SIZE,
		 cur.OD_PB_MINOR ,
		 cur.OD_PB_MAJOR  ,                  
		 cur.OD_PB_MERCHANDISING_APPROVER,
		 cur.OD_PB_OBJECTIVE,
		 cur.OD_PB_ORG_AUDITED,
		 cur.OD_PB_PO_NUM,
		 cur.OD_PB_PROGRAM_TEST_TYPE,
		 cur.OD_PB_QA_APPROVER,
		 cur.OD_PB_RESULTS,
		 cur.OD_PB_SAMPLE_SIZE		,
		 cur.OD_PB_SKU,
		 cur.OD_PB_SPECIFICATION_NAME ,
		 cur.OD_PB_SUPPLIER 		,
		 cur.OD_PB_TECH_RPT_NUM,
		 cur.OD_PB_VENDORS_AWARDED,
		 cur.OD_PB_VENDOR_COMMENTS,
		 cur.collection_id,
		 cur.source_line_id,
		 cur.od_pb_record_id);
  EXCEPTION
    WHEN others THEN
      error_rec:=error_rec+1;
      dbms_output.put_line(sqlerrm);
  END;     
 END LOOP;
 dbms_output.put_line('TOtal :'||total_rec);
 dbms_output.put_line('Error :'||error_rec);
END OD_PB_TESTING_HIS;

END XX_QA_HIS_PLAN_PKG;
/
