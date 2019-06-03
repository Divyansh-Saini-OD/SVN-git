SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_MAIN_PLAN_PKG
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

PROCEDURE OD_PB_INSPECTION IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_INSPECTION_ACTIVITY_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_STYL                            , 
		OD_PB_BV_OPERATING_OFFICE            ,  
		OD_PB_INSPECTION_BOOKING_NO          ,  
		OD_PB_INSPECTION_CERT                ,  
		OD_PB_PO_NUM                         ,  
		OD_PB_SELLING_OFFICE                 ,  
		OD_PB_VENDOR_NAME                    ,  
		OD_PB_FACTORY_NAME                   ,  
		OD_PB_FACTORY_CITY                   ,  
		OD_PB_FACTORY_COUNTRY                ,  
		OD_PB_INSP_BEGIN_DATE                ,  
		OD_PB_INSP_END_DATE                  ,  
		OD_PB_REPORT_DATE                    ,  
		OD_PB_SERVICE_TYPE                   ,  
		OD_PB_SKU                            ,  
		OD_PB_BV_PRODUCT_TYPE                ,  
		OD_PB_ITEM_DESC                      ,  
		OD_PB_INSPECTION_RESULT              ,  
		OD_PB_ORDER_QTY                      ,  
		OD_PB_ACTUAL_QTY                     ,  
		OD_PB_SAMPLE_SIZE                    ,  
		OD_PB_NUMBER_OF_MAN_DAYS             ,  
		OD_PB_INSP_FEE                       ,  
		OD_PB_ACCOMODATION_EXP               ,  
		OD_PB_TRAVELLING_EXP                 ,  
		OD_PB_FLIGHT_CHARGE                  ,  
		OD_PB_EXTRA_TRAVELLING_TIME          ,  
		OD_PB_TOTAL_CHARGE                   ,  
		OD_PB_INVOICE_NUM                    ,  
		OD_PB_APPROVAL_STATUS                ,  
		OD_PB_COMMENTS                       ,  
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_INSPECTION_ACTIVITY',
                   '1', --1 for INSERT
               'OD_PB_INSPECTION_BOOKING_NO,OD_PB_SKU',	
		OD_PB_STYL                            , 
		OD_PB_BV_OPERATING_OFFICE            ,  
		OD_PB_INSPECTION_BOOKING_NO          ,  
		OD_PB_INSPECTION_CERT                ,  
		OD_PB_PO_NUM                         ,  
		OD_PB_SELLING_OFFICE                 ,  
		OD_PB_VENDOR_NAME                    ,  
		OD_PB_FACTORY_NAME                   ,  
		OD_PB_FACTORY_CITY                   ,  
		OD_PB_FACTORY_COUNTRY                ,  
		OD_PB_INSP_BEGIN_DATE                ,  
		OD_PB_INSP_END_DATE                  ,  
		OD_PB_REPORT_DATE                    ,  
		OD_PB_SERVICE_TYPE                   ,  
		OD_PB_SKU                            ,  
		OD_PB_BV_PRODUCT_TYPE                ,  
		OD_PB_ITEM_DESC                      ,  
		OD_PB_INSPECTION_RESULT              ,  
		OD_PB_ORDER_QTY                      ,  
		OD_PB_ACTUAL_QTY                     ,  
		OD_PB_SAMPLE_SIZE                    ,  
		OD_PB_NUMBER_OF_MAN_DAYS             ,  
		OD_PB_INSP_FEE                       ,  
		OD_PB_ACCOMODATION_EXP               ,  
		OD_PB_TRAVELLING_EXP                 ,  
		OD_PB_FLIGHT_CHARGE                  ,  
		OD_PB_EXTRA_TRAVELLING_TIME          ,  
		OD_PB_TOTAL_CHARGE                   ,  
		OD_PB_INVOICE_NUM                    ,  
		OD_PB_APPROVAL_STATUS                ,  
		OD_PB_COMMENTS                       ,  
		d.user_name,
     	        e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_INSPECTION_ACTIVITY_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_INSPECTION;

PROCEDURE OD_PB_INVOICE IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_QUALITY_INVOICES_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		 OD_PB_PROGRAM_TEST_TYPE    ,    
		 OD_PB_TECH_RPT_NUM          ,   
		 OD_PB_DATE_INVOICED         ,   
		 OD_PB_AMOUNT                ,   
		 OD_PB_PAID_BY               ,   
		 OD_PB_COUNTRY_DESTINATION   ,   
		 OD_PB_INVOICE_NUM           ,   
		 OD_PB_PAYEE                 ,   
		 OD_PB_LAB_LOCATION          ,   
		 OD_PB_SUPPLIER              ,   
		 OD_PB_VENDOR_ID             ,   
		 OD_PB_PO_NUM                ,   
		 OD_PB_MAN_DAYS              ,   
		 OD_PB_INSP_FEE              ,   
		 OD_PB_ACCOM_EXPENSE         ,   
		 OD_PB_TRAVEL_EXPENSE        ,   
		 OD_PB_FLIGHT_EXPENSE        ,   
		 OD_PB_EXTRA_EXPENSE         ,   
		 OD_PB_COMMENTS              ,   
		 OD_PB_ATTACHMENT            ,   
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id	
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_QUALITY_INVOICES',
                   '1', --1 for INSERT
               'OD_PB_PROGRAM_TEST_TYPE,OD_PB_TECH_RPT_NUM',
		 OD_PB_PROGRAM_TEST_TYPE    ,    
		 OD_PB_TECH_RPT_NUM          ,   
		 OD_PB_DATE_INVOICED         ,   
		 OD_PB_AMOUNT                ,   
		 OD_PB_PAID_BY               ,   
		 OD_PB_COUNTRY_DESTINATION   ,   
		 OD_PB_INVOICE_NUM           ,   
		 OD_PB_PAYEE                 ,   
		 OD_PB_LAB_LOCATION          ,   
		 OD_PB_SUPPLIER              ,   
		 OD_PB_VENDOR_ID             ,   
		 OD_PB_PO_NUM                ,   
		 OD_PB_MAN_DAYS              ,   
		 OD_PB_INSP_FEE              ,   
		 OD_PB_ACCOM_EXPENSE         ,   
		 OD_PB_TRAVEL_EXPENSE        ,   
		 OD_PB_FLIGHT_EXPENSE        ,   
		 OD_PB_EXTRA_EXPENSE         ,   
		 OD_PB_COMMENTS              ,   
		 OD_PB_ATTACHMENT            ,   
		d.user_name,
     	        e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_QUALITY_INVOICES_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_INVOICE;



PROCEDURE OD_PB_ATS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_AUTHORIZATION_TO_SH_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
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
SELECT            '1',
                  'PRJ',
                  'OD_PB_AUTHORIZATION_TO_SHIP',
                   '1', --1 for INSERT
               'OD_PB_ATS_ID,OD_PB_REPORT_NUMBER,OD_PB_SKU',
		OD_PB_CA_TYPE            ,              
		OD_PB_REPORT_NUMBER       ,             
		TO_CHAR(OD_PB_DATE_REPORTED,'DD-MON-YYYY')       ,             
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
		d.user_name,
     	        e.user_name,
		a.collection_id,
		a.occurrence,
		OD_PB_ATS_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_ATS;


PROCEDURE OD_PB_ATS_EU IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_AUTHORIZATIONTO_SHI_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_CA_TYPE       ,                   
		OD_PB_REPORT_NUMBER  ,                  
		OD_PB_DATE_REPORTED   ,                 
		OD_PB_QA_ACTIVITY_NUMBER,               
		OD_PB_MANUF_NAME         ,              
		OD_PB_SKU                ,              
		OD_PB_SKU_DESCRIPTION    ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_REASON_FOR_WAIVING ,              
		OD_PB_FAILURE            ,              
		OD_PB_PENDING_SUPPLIER_ACTION ,         
		OD_PB_FOLLOW_UP_DATE     ,              
		OD_PB_AUTHORIZED         ,              
		OD_PB_ATS_ISSUE_DATE     ,              
		OD_PB_LINK               ,              
		OD_PB_COMMENTS           ,              
		OD_PB_ATTACHMENT         ,              
		OD_PB_APPROVAL_STATUS    ,              
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id		
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_AUTHORIZATIONTO_SHIP_EU',
                  '1', --1 for INSERT
              'OD_PB_ATS_ID_EU,OD_PB_SKU',
		OD_PB_CA_TYPE       ,                   
		OD_PB_REPORT_NUMBER  ,                  
		OD_PB_DATE_REPORTED   ,                 
		OD_PB_QA_ACTIVITY_NUMBER,               
		OD_PB_MANUF_NAME         ,              
		OD_PB_SKU                ,              
		OD_PB_SKU_DESCRIPTION    ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_REASON_FOR_WAIVING ,              
		OD_PB_FAILURE            ,              
		OD_PB_PENDING_SUPPLIER_ACTION ,         
		OD_PB_FOLLOW_UP_DATE     ,              
		OD_PB_AUTHORIZED         ,              
		OD_PB_ATS_ISSUE_DATE     ,              
		OD_PB_LINK               ,              
		OD_PB_COMMENTS           ,              
		OD_PB_ATTACHMENT         ,              
		OD_PB_APPROVAL_STATUS    ,              
	          d.user_name,
                 e.user_name,
		a.collection_id,
		a.occurrence,
		OD_PB_ATS_ID_EU
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_ATS_EU;

PROCEDURE OD_PB_CA IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CA_REQUEST_IV
	(	  process_status, 
         	  organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
                  od_pb_ca_type,
                  od_pb_sku,
                  od_pb_item_desc,
                  od_pb_department,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_tech_rpt_num,
                  od_pb_defect_sum,
                  od_pb_date_capa_sent,
                  od_pb_date_capa_received,
                  od_pb_root_cause,
                  od_pb_corrective_action_type,
                  od_pb_corr_action,
                  od_pb_qa_engr_email,
                  od_pb_approval_status,
                  od_pb_date_approved,
                  od_pb_date_corr_impl,
                  od_pb_date_verified,
                  od_pb_comments_verified,
                  od_pb_ca_needed,
                  od_pb_link,
                  od_pb_item_id,
                  od_pb_date_due,
                  od_pb_comments,
                  od_pb_contact_email,
                  od_pb_class,
                  od_pb_results,
                  od_pb_vendor_vpc,
                  od_pb_customer_complaint_num,
                  od_pb_date_reported,
                  od_pb_qa_engineer,
        	  qa_created_by_name,
	          qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id		
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_CA_REQUEST',
                  '1', --1 for INSERT
	          'OD_PB_ITEM_ID,OD_PB_TECH_RPT_NUM',
                  od_pb_ca_type,
                  od_pb_sku,
                  od_pb_item_desc,
                  od_pb_department,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_tech_rpt_num,
                  od_pb_defect_sum,
                  od_pb_date_capa_sent,
                  od_pb_date_capa_received,
                  od_pb_root_cause,
                  od_pb_corrective_action_type,
                  od_pb_corr_action,
                  od_pb_qa_engr_email,
                  od_pb_approval_status,
                  od_pb_date_approved,
                  od_pb_date_corr_impl,
                  od_pb_date_verified,
                  od_pb_comments_verified,
                  od_pb_ca_needed,
                  od_pb_link,
                  od_pb_item_id,
                  od_pb_date_due,
                  od_pb_comments,
                  od_pb_contact_email,
                  od_pb_class,
                  od_pb_results,
                  od_pb_vendor_vpc,
                  od_pb_customer_complaint_num,
                  od_pb_date_reported,
                  od_pb_qa_engineer,
	          d.user_name,
        	  e.user_name,
		a.collection_id,
		a.occurrence,
		OD_PB_CAR_ID
 FROM  apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CA_REQUEST_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CA;

PROCEDURE OD_PB_CAP_APPRV IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PPT_CAP_APPROVAL_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_PROJECT_ID    ,                   
		OD_PB_PROJECT_NAME   ,                  
		OD_PB_DIVISION        ,                 
		OD_PB_VENDOR_NAME      ,                
		OD_PB_DEPARTMENT       ,                
		OD_PB_ITEM_DESC        ,                
		OD_PB_TESTING_TYPE     ,                
		OD_PB_REPORT_NUMBER    ,                
		OD_PB_RESULTS          ,                
		OD_PB_CA_NEEDED        ,                
		OD_PB_ATTACHMENT       ,                
		OD_PB_CAP_APPROVAL     ,                
		OD_PB_ODGSO_QA_ENGINEER  ,                
		OD_PB_QA_ENGR_EMAIL    ,                
		OD_PB_VENDOR_EMAIL     ,                
		OD_PB_FACTORY_NAME     ,                
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_VENDOR_VPC       ,                
		OD_PB_PRODUCT_REQUIREMENTS,             
		OD_PB_PRODUCT_PHOTOS       ,            
		OD_PB_PROJECT_ASSIGNED_DATE ,           
		OD_PB_DATE_DUE              ,           
		OD_PB_ITEM_STATUS           ,           
		OD_PB_SOURCING_MERCHANT     ,           
		OD_PB_LINK                  ,           
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_PPT_CAP_APPROVAL',
                  '1', --1 for INSERT
              'OD_PB_PROJECT_ID,OD_PB_TESTING_TYPE,OD_PB_REPORT_NUMBER',
		OD_PB_PROJECT_ID    ,                   
		OD_PB_PROJECT_NAME   ,                  
		OD_PB_DIVISION        ,                 
		OD_PB_VENDOR_NAME      ,                
		OD_PB_DEPARTMENT       ,                
		OD_PB_ITEM_DESC        ,                
		OD_PB_TESTING_TYPE     ,                
		OD_PB_REPORT_NUMBER    ,                
		OD_PB_RESULTS          ,                
		OD_PB_CA_NEEDED        ,                
		OD_PB_ATTACHMENT       ,                
		OD_PB_CAP_APPROVAL     ,                
		OD_PB_ODGSO_QA_ENGINEER  ,                
		OD_PB_QA_ENGR_EMAIL    ,                
		OD_PB_VENDOR_EMAIL     ,                
		OD_PB_FACTORY_NAME     ,                
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_VENDOR_VPC       ,                
		OD_PB_PRODUCT_REQUIREMENTS,             
		OD_PB_PRODUCT_PHOTOS       ,            
		OD_PB_PROJECT_ASSIGNED_DATE ,           
		OD_PB_DATE_DUE              ,           
		OD_PB_ITEM_STATUS           ,           
		OD_PB_SOURCING_MERCHANT     ,           
		OD_PB_LINK                  ,
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PPT_CAP_APPROVAL_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CAP_APPRV;

PROCEDURE OD_PB_CUST_COMP IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CUSTOMER_COMPLAINTS_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_CA_TYPE       ,           
		OD_PB_QA_ENGR_EMAIL  ,          
		OD_PB_DATE_REPORTED  ,          
		OD_PB_DATE_OPENED    ,          
		OD_PB_SKU            ,          
		OD_PB_DEPARTMENT     ,          
		OD_PB_ITEM_DESC      ,          
		OD_PB_SUPPLIER       ,          
		OD_PB_DEFECT_SUM     , 
		OD_PB_EXECUTIVE_REPORT_SUMMARY          ,
		OD_PB_PRODUCT_ALERT  ,          
		OD_PB_SAMPLE_AVAILABLE,         
		OD_PB_DATE_SAMPLE_RECEIVED,     
		OD_PB_CA_NEEDED            ,    
		OD_PB_CORRECTIVE_ACTION_ID ,    
		OD_PB_ROOT_CAUSE_TYPE      ,    
		OD_PB_COMMENTS             ,    
		OD_PB_DATE_CLOSED          ,    
		OD_PB_POPT_CANDIDATE       ,    
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id		
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_CUSTOMER_COMPLAINTS',
                  '1', --1 for INSERT
              'OD_PB_CUSTOMER_COMPLAINT_ID,OD_PB_SKU',
		OD_PB_CA_TYPE       ,           
		OD_PB_QA_ENGR_EMAIL  ,          
		OD_PB_DATE_REPORTED  ,          
		OD_PB_DATE_OPENED    ,          
		OD_PB_SKU            ,          
		OD_PB_DEPARTMENT     ,          
		OD_PB_ITEM_DESC      ,          
		OD_PB_SUPPLIER       ,          
		OD_PB_DEFECT_SUM     ,      
		OD_PB_EXECUTIVE_REPORT_SUMMARY    ,
		OD_PB_PRODUCT_ALERT  ,          
		OD_PB_SAMPLE_AVAILABLE,         
		OD_PB_DATE_SAMPLE_RECEIVED,     
		OD_PB_CA_NEEDED            ,    
		OD_PB_CORRECTIVE_ACTION_ID ,    
		OD_PB_ROOT_CAUSE_TYPE      ,    
		OD_PB_COMMENTS             ,    
		OD_PB_DATE_CLOSED          ,    
		OD_PB_POPT_CANDIDATE       ,    
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CUSTOMER_COMPLAINT_ID    
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CUST_COMP;

PROCEDURE OD_PB_CUST_COMP_EU IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_CUSTOMERCOMPLAINTS__IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_CA_TYPE       ,           
		OD_PB_QA_ENGR_EMAIL  ,          
		OD_PB_DATE_REPORTED  ,          
		OD_PB_DATE_OPENED    ,          
		OD_PB_SKU            ,          
		OD_PB_DEPARTMENT     ,          
		OD_PB_ITEM_DESC      ,          
		OD_PB_SUPPLIER       ,          
		OD_PB_DEFECT_SUM     ,          
		OD_PB_PRODUCT_ALERT  ,          
		OD_PB_SAMPLE_AVAILABLE,         
		OD_PB_DATE_SAMPLE_RECEIVED,     
		OD_PB_CA_NEEDED            ,    
		OD_PB_CORRECTIVE_ACTION_ID ,    
		OD_PB_ROOT_CAUSE_TYPE      ,    
		OD_PB_COMMENTS             ,    
		OD_PB_DATE_CLOSED          ,    
		OD_PB_POPT_CANDIDATE       ,    
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_CUSTOMERCOMPLAINTS_EU',
                  '1', --1 for INSERT
              'OD_PB_CUSTOMER_COMPLAINT_ID_EU,OD_PB_SKU',
		OD_PB_CA_TYPE       ,           
		OD_PB_QA_ENGR_EMAIL  ,          
		OD_PB_DATE_REPORTED  ,          
		OD_PB_DATE_OPENED    ,          
		OD_PB_SKU            ,          
		OD_PB_DEPARTMENT     ,          
		OD_PB_ITEM_DESC      ,          
		OD_PB_SUPPLIER       ,          
		OD_PB_DEFECT_SUM     ,          
		OD_PB_PRODUCT_ALERT  ,          
		OD_PB_SAMPLE_AVAILABLE,         
		OD_PB_DATE_SAMPLE_RECEIVED,     
		OD_PB_CA_NEEDED            ,    
		OD_PB_CORRECTIVE_ACTION_ID ,    
		OD_PB_ROOT_CAUSE_TYPE      ,    
		OD_PB_COMMENTS             ,    
		OD_PB_DATE_CLOSED          ,    
		OD_PB_POPT_CANDIDATE       ,    
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_CUSTOMER_COMPLAINT_ID_EU   
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_CUST_COMP_EU;

PROCEDURE OD_PB_ECR IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.q_od_pb_ecr_iv
	(	  process_status, 
         	  organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
                  source_reference_id,
                  od_pb_date_requested,
                  od_pb_vendor_id,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_vendor_email,
                  od_pb_factory_id,
                  od_pb_factory_name,
                  od_pb_factory_contact,
                  od_pb_product_affected,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_class,
                  od_pb_change_desc,
                  od_pb_date_proposed_production,
                  od_pb_chg_cat_aesthetics,
                  od_pb_chg_cat_design,
                  od_pb_chg_cat_location,
                  od_pb_chg_cat_packaging,
                  od_pb_chg_cat_performance,
                  od_pb_chg_cat_safety,
                  od_pb_chg_cat_software,
                  od_pb_chg_cat_substitution,
                  od_pb_qa_engineer,
                  od_pb_qa_approver,
                  od_pb_attachment,
                  od_pb_tech_rpt_num,
                  od_pb_comments,
                  od_pb_approval_status,
                  od_pb_date_qa_response,
                  od_pb_link,
		  qa_created_by_name,
		  qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_ECR',
                  '1', --1 for INSERT
	          'OD_PB_ECR_ID,OD_PB_SKU',
                  source_reference_id,
                  od_pb_date_requested,
                  od_pb_vendor_id,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_vendor_email,
                  od_pb_factory_id,
                  od_pb_factory_name,
                  od_pb_factory_contact,
                  od_pb_product_affected,
                  od_pb_sku,
                  od_pb_department,
                  od_pb_class,
                  od_pb_change_desc,
                  od_pb_date_proposed_production,
                  od_pb_chg_cat_aesthetics,
                  od_pb_chg_cat_design,
                  od_pb_chg_cat_location,
                  od_pb_chg_cat_packaging,
                  od_pb_chg_cat_performance,
                  od_pb_chg_cat_safety,
                  od_pb_chg_cat_software,
                  od_pb_chg_cat_substitution,
                  od_pb_qa_engineer,
                  od_pb_qa_approver,
                  od_pb_attachment,
                  od_pb_tech_rpt_num,
                  od_pb_comments,
                  od_pb_approval_status,
                  od_pb_date_qa_response,
                  od_pb_link,
		  d.user_name,
		  e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_ECR_ID
 FROM 	
	apps.fnd_user e,
	apps.fnd_user d,
	apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
	apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_ECR_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_ECR;

PROCEDURE OD_PB_FA_CODES IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FAILURE_CODES_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_TECH_RPT_NUM,     
		OD_PB_PROJ_NUM     ,    
		OD_PB_ITEM_ID       ,   
		OD_PB_FAILURE_CODES  ,  
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FAILURE_CODES',
                  '1', --1 for INSERT
              'OD_PB_TECH_RPT_NUM,OD_PB_ITEM_ID',
		OD_PB_TECH_RPT_NUM,     
		OD_PB_PROJ_NUM     ,    
		OD_PB_ITEM_ID       ,   
		OD_PB_FAILURE_CODES  ,  
          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FAILURE_CODES_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FA_CODES;

PROCEDURE OD_PB_FAI IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FIRST_ARTICLE_INSPE_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_SUPPLIER              ,   
		OD_PB_FACTORY_NAME          ,   
		OD_PB_SKU                   ,   
		OD_PB_DEPARTMENT            ,   
		OD_PB_PO_NUM                ,   
		OD_PB_DATE_OF_INSPECTON     ,   
		OD_PB_RESULTS               ,   
		OD_PB_APPROVAL_STATUS       ,   
		OD_PB_QA_ENGR_EMAIL         ,   
		OD_PB_ATTACHMENT            ,   
		OD_PB_COMMENTS              ,   
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FIRST_ARTICLE_INSPECTION',
                  '1', --1 for INSERT
               'OD_PB_RECORD_ID,OD_PB_SKU',
		OD_PB_SUPPLIER              ,   
		OD_PB_FACTORY_NAME          ,   
		OD_PB_SKU                   ,   
		OD_PB_DEPARTMENT            ,   
		OD_PB_PO_NUM                ,   
		OD_PB_DATE_OF_INSPECTON     ,   
		OD_PB_RESULTS               ,   
		OD_PB_APPROVAL_STATUS       ,   
		OD_PB_QA_ENGR_EMAIL         ,   
		OD_PB_ATTACHMENT            ,   
		OD_PB_COMMENTS              ,   
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_RECORD_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FAI;

PROCEDURE OD_PB_FQA_ODC IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FQA_ODC_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_DOM_IMP       ,                   
		OD_PB_QA_APPROVER    ,                  
		OD_PB_SUPPLIER        ,                 
		OD_PB_FACTORY_NAME     ,                
		OD_PB_CATEGORY          ,               
		OD_PB_FACTORY_ADDRESS    ,              
		OD_PB_FACTORY_CONTACT    ,              
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_FQA_GENERAL              ,        
		OD_PB_AUDIT_GRADE              ,        
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,        
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FQA_ODC',
                  '1', --1 for INSERT
              'OD_PB_FQA_ID_ODC,OD_PB_SKU',
		OD_PB_DOM_IMP       ,                   
		OD_PB_QA_APPROVER    ,                  
		OD_PB_SUPPLIER        ,                 
		OD_PB_FACTORY_NAME     ,                
		OD_PB_CATEGORY          ,               
		OD_PB_FACTORY_ADDRESS    ,              
		OD_PB_FACTORY_CONTACT    ,              
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_FQA_GENERAL              ,        
		OD_PB_AUDIT_GRADE              ,        
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,        
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_FQA_ID_ODC
FROM         apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FQA_ODC_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FQA_ODC;

PROCEDURE OD_PB_FQA_RTLF IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FQA_RTLF_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_SUPPLIER      ,                   
		OD_PB_FACTORY_NAME   ,                  
		OD_PB_CATEGORY        ,                 
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_FACTORY_CONTACT   ,               
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_AUDIT_GRADE              ,       
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,       
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FQA_RTLF',
                  '1', --1 for INSERT
              'OD_PB_FQA_ID_RTLF,OD_PB_SKU',
		OD_PB_SUPPLIER      ,                   
		OD_PB_FACTORY_NAME   ,                  
		OD_PB_CATEGORY        ,                 
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_FACTORY_CONTACT   ,               
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_AUDIT_GRADE              ,       
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,       
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
	  a.OD_PB_FQA_ID_RTLF
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FQA_RTLF_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FQA_RTLF;

PROCEDURE OD_PB_FQA_US IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_FQA_US_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_SUPPLIER      ,                   
		OD_PB_FACTORY_NAME   ,                  
		OD_PB_CATEGORY        ,                 
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_FACTORY_CONTACT   ,               
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_AUDIT_GRADE              ,       
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,       
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_FQA_US',
                  '1', --1 for INSERT
              'OD_PB_FQA_US_ID,OD_PB_SKU',
		OD_PB_SUPPLIER      ,                   
		OD_PB_FACTORY_NAME   ,                  
		OD_PB_CATEGORY        ,                 
		OD_PB_FACTORY_ADDRESS  ,                
		OD_PB_FACTORY_CONTACT   ,               
		OD_PB_FQA_ASSIGNED_DATE  ,              
		OD_PB_AUDIT_DATE         ,              
		OD_PB_DATE_REPORTED      ,              
		OD_PB_AUDITOR_NAME       ,              
		OD_PB_AUDIT_TYPE         ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_SKU                ,              
		OD_PB_DEPARTMENT         ,              
		OD_PB_DESIGN_CONTROL_SCORE,             
		OD_PB_PURCHASE_CONTROL_SCORE,           
		OD_PB_STORAGE_MANAGEMENT_SCORE,         
		OD_PB_INCOMING_INSPECT_SCORE   ,        
		OD_PB_PRODUCTION_CONTROL_SCORE ,        
		OD_PB_CONTINUOUS_IMPROVE_SCORE ,        
		OD_PB_AUDIT_GRADE              ,       
		OD_PB_APPROVAL_STATUS          ,        
		OD_PB_QA_ENGR_EMAIL            ,       
		OD_PB_ATTACHMENT               ,        
		OD_PB_COMMENTS                 ,        
          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_FQA_US_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_FQA_US_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_FQA_US;

PROCEDURE OD_PB_HOUSE_ART IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_IN_HOUSE_ARTWORK_RE_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		 OD_PB_SKU               ,       
		 OD_PB_SKU_DESCRIPTION   ,       
		 OD_PB_DEPARTMENT        ,       
		 OD_PB_DATE_APPROVED     ,       
		 OD_PB_QA_ENGR_EMAIL     ,       
		 OD_PB_PROGRAM_MANAGER   ,       
		 OD_PB_ATTACHMENT        ,       
		 OD_PB_COMMENTS          ,       
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_IN_HOUSE_ARTWORK_REVIEW',
                  '1', --1 for INSERT
              'OD_PB_IHR_NUMBER,OD_PB_SKU',
		 OD_PB_SKU               ,       
		 OD_PB_SKU_DESCRIPTION   ,       
		 OD_PB_DEPARTMENT        ,       
		 OD_PB_DATE_APPROVED     ,       
		 OD_PB_QA_ENGR_EMAIL     ,       
		 OD_PB_PROGRAM_MANAGER   ,       
		 OD_PB_ATTACHMENT        ,       
		 OD_PB_COMMENTS          ,       
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_IHR_NUMBER
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_HOUSE_ART;

PROCEDURE OD_PB_LAB_INV IS
 v_cnt NUMBER:=0;
BEGIN
/*
INSERT INTO apps.Q_OD_PB_LAB_INVOICING_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_PROGRAM_TEST_TYPE,
		OD_PB_TECH_RPT_NUM   ,                  
		OD_PB_DATE_INVOICED   ,                 
		OD_PB_AMOUNT           ,                
		OD_PB_PAID_BY           ,               
		OD_PB_COUNTRY_DESTINATION,              
		OD_PB_INVOICE_NUM        ,              
		OD_PB_PAYEE              ,              
		OD_PB_LAB_LOCATION       ,              
		OD_PB_SUPPLIER           ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_PO_NUM             ,              
		OD_PB_MAN_DAYS           ,              
		OD_PB_INSP_FEE           ,              
		OD_PB_ACCOM_EXPENSE      ,              
		OD_PB_TRAVEL_EXPENSE     ,              
		OD_PB_FLIGHT_EXPENSE     ,              
		OD_PB_EXTRA_EXPENSE      ,              
		OD_PB_COMMENTS           ,              
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_LAB_INVOICING',
                  '1', --1 for INSERT
              'OD_PB_PROGRAM_TEST_TYPE,OD_PB_TECH_RPT_NUM',
		OD_PB_PROGRAM_TEST_TYPE,
		OD_PB_TECH_RPT_NUM   ,                  
		OD_PB_DATE_INVOICED   ,                 
		OD_PB_AMOUNT           ,                
		OD_PB_PAID_BY           ,               
		OD_PB_COUNTRY_DESTINATION,              
		OD_PB_INVOICE_NUM        ,              
		OD_PB_PAYEE              ,              
		OD_PB_LAB_LOCATION       ,              
		OD_PB_SUPPLIER           ,              
		OD_PB_VENDOR_ID          ,              
		OD_PB_PO_NUM             ,              
		OD_PB_MAN_DAYS           ,              
		OD_PB_INSP_FEE           ,              
		OD_PB_ACCOM_EXPENSE      ,              
		OD_PB_TRAVEL_EXPENSE     ,              
		OD_PB_FLIGHT_EXPENSE     ,              
		OD_PB_EXTRA_EXPENSE      ,              
		OD_PB_COMMENTS           ,              
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_LAB_INVOICING_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
*/
  NULL;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_LAB_INV;

PROCEDURE OD_PB_MONTH_DEF IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_MONTHLY_DEFECT_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_TECH_RPT_NUM         ,    
		OD_PB_SKU                  ,    
		OD_PB_DATE_OF_INSPECTION   ,    
		OD_PB_FACTORY_NAME         ,    
		OD_PB_FAILURE              ,    
		SEVERITY_CODE              ,    
		OD_PB_SAMPLE_SIZE          ,    
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_MONTHLY_DEFECT',
                  '1', --1 for INSERT
              'OD_PB_TECH_RPT_NUM,OD_PB_SKU',
		OD_PB_TECH_RPT_NUM         ,    
		OD_PB_SKU                  ,    
		OD_PB_DATE_OF_INSPECTION   ,    
		OD_PB_FACTORY_NAME         ,    
		OD_PB_FAILURE              ,    
		SEVERITY_CODE              ,    
		OD_PB_SAMPLE_SIZE          ,    
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_MONTHLY_DEFECT_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_MONTH_DEF;

PROCEDURE OD_PB_PRE_PUR IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PRE_PURCHASE_IV
	(	  process_status, 
         	  organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
                  od_pb_proj_num,
                  od_pb_proj_name,
                  od_pb_proj_desc,
                  od_pb_proj_mgr,
                  od_pb_dom_imp,
                  od_pb_sourcing_agent,
                  od_pb_item_id,
                  od_pb_qa_project_desc,
                  od_pb_sku,
                  od_pb_item_desc,
                  od_pb_vendor_vpc,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_contact_phone,
                  od_pb_contact_email,
                  od_pb_country_of_origin,
                  od_pb_item_action_code,
                  od_pb_testing_type,
                  od_pb_tech_rpt_num,
                  od_pb_item_status,
                  od_pb_cap_status,
                  od_pb_comments,
                  od_pb_status_timestamp,
                  od_pb_results,
                  od_pb_proj_stat,
                  od_pb_qa_engineer,
                  od_pb_qa_engr_email,
                  od_pb_ca_type,
                  od_pb_class,
                  od_pb_department,
                  od_pb_send_email,
                  od_pb_protocol_name,
                  od_pb_protocol_number,
        	  qa_created_by_name,
	          qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_PRE_PURCHASE',
                  '1', --1 for INSERT
	          'OD_PB_ITEM_ID,OD_PB_TESTING_TYPE',
                  od_pb_proj_num,
                  od_pb_proj_name,
                  od_pb_proj_desc,
                  od_pb_proj_mgr,
                  od_pb_dom_imp,
                  od_pb_sourcing_agent,
                  od_pb_item_id,
                  od_pb_qa_project_desc,
                  od_pb_sku,
                  od_pb_item_desc,
                  od_pb_vendor_vpc,
                  od_pb_supplier,
                  od_pb_contact,
                  od_pb_contact_phone,
                  od_pb_contact_email,
                  od_pb_country_of_origin,
                  od_pb_item_action_code,
                  od_pb_testing_type,
                  od_pb_tech_rpt_num,
                  od_pb_item_status,
                  od_pb_cap_status,
                  od_pb_comments,
                  od_pb_status_timestamp,
                  od_pb_results,
                  od_pb_proj_stat,
                  od_pb_qa_engineer,
                  od_pb_qa_engr_email,
                  od_pb_ca_type,
                  od_pb_class,
                  od_pb_department,
                  od_pb_send_email,
                  od_pb_protocol_name,
                  od_pb_protocol_number,
	          d.user_name,
        	  e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PRE_PURCHASE_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PRE_PUR;

PROCEDURE OD_PB_PROC_LOG IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PROCEDURES_LOG_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
                  matching_elements,
		OD_PB_COLLECTION_PLANS         ,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER              ,
		ENTERED_BY_USER                ,
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_PROCEDURES_LOG',
                  '1', --1 for INSERT
              'OD_PB_COLLECTION_PLANS',
		OD_PB_COLLECTION_PLANS         ,
		OD_PB_ATTACHMENT               ,
		OD_PB_QA_APPROVER              ,
		ENTERED_BY_USER                ,
	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PROCEDURES_LOG_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PROC_LOG;

PROCEDURE OD_PB_PROT_REV IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PROTOCOL_REVIEW_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_PROTOCOL_NUMBER          ,
		OD_PB_PROTOCOL_ACTIVITY_TYPE   ,
		OD_PB_DATE_DUE                 ,
		OD_PB_COMMENTS                 ,
		OD_PB_ATTACHMENT               ,
		OD_PB_DATE_CLOSED              ,
		OD_PB_PROTOCOL_NAME            ,
		OD_PB_QA_ENGR_EMAIL            ,
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_PROTOCOL_REVIEW',
                  '1', --1 for INSERT
              'OD_PB_PROTOCOL_NUMBER,OD_PB_PROTOCOL_ACTIVITY_TYPE',
		OD_PB_PROTOCOL_NUMBER          ,
		OD_PB_PROTOCOL_ACTIVITY_TYPE   ,
		OD_PB_DATE_DUE                 ,
		OD_PB_COMMENTS                 ,
		OD_PB_ATTACHMENT               ,
		OD_PB_DATE_CLOSED              ,
		OD_PB_PROTOCOL_NAME            ,
		OD_PB_QA_ENGR_EMAIL            ,	          d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PROTOCOL_REVIEW_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PROT_REV;

PROCEDURE OD_PB_PSI_IC IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_PSI_IC_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_SERVICE_TYPE              ,               
		OD_PB_INSPECTION_TYPE           ,               
		OD_PB_SOURCING_AGENT            ,               
		OD_PB_REPORT_NUMBER             ,               
		OD_PB_ORIGINAL_REPORT_NUMBER    ,               
		OD_PB_DATE_VERIFICATION_BY      ,               
		OD_PB_BOOKING_NUMBER            ,               
		OD_PB_DIVISION                  ,               
		OD_PB_VENDOR_NAME               ,               
		OD_PB_MANUF_NAME                ,               
		OD_PB_MANUF_ID                  ,               
		OD_PB_MANUF_COUNTRY_CD          ,               
		OD_PB_DATE_REPORTED             ,               
		OD_PB_DATE_PROPOSAL_PROVIDED    ,               
		OD_PB_DATE_SAMPLE_SENT          ,               
		OD_PB_PO_NUM                    ,               
		OD_PB_SKU                       ,               
		OD_PB_ITEM_DESC                 ,               
		OD_PB_DEPARTMENT                ,               
		OD_PB_DECLARED_QUANTITY         ,               
		OD_PB_INSP_CERTIFICATE_NUMBER   ,               
		OD_PB_DESTINATION_COUNTRY       ,               
		OD_PB_GENERAL_INSPECTION_LEVEL  ,               
		OD_PB_AQL                       ,               
		OD_PB_INSPECTION_PROTOCOL_NUM   ,               
		OD_PB_DATE_PROPOSAL_APPROVED    ,               
		OD_PB_SAMPLE_SIZE               ,               
		OD_PB_DEFECT_FOUND_CRITICAL     ,               
		OD_PB_DEFECT_FOUND_MAJOR        ,               
		OD_PB_FAILURE_REASONS           ,               
		OD_PB_RESULTS                   ,               
		OD_PB_ATTACHMENT                ,               
		OD_PB_QA_ENGR_EMAIL             ,               
		OD_PB_APPROVAL_STATUS           ,               
		OD_PB_COMMENTS                  ,               
		OD_PB_INSPECTION_SERVICE_OFFIC  ,               
		OD_PB_DEFECT_FOUND_MINOR        ,               
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id	
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_PSI_IC',
                  '1', --1 for INSERT
              'OD_PB_PSI_ID,OD_PB_SKU',
		OD_PB_SERVICE_TYPE              ,               
		OD_PB_INSPECTION_TYPE           ,               
		OD_PB_SOURCING_AGENT            ,               
		OD_PB_REPORT_NUMBER             ,               
		OD_PB_ORIGINAL_REPORT_NUMBER    ,               
		OD_PB_DATE_VERIFICATION_BY      ,               
		OD_PB_BOOKING_NUMBER            ,               
		OD_PB_DIVISION                  ,               
		OD_PB_VENDOR_NAME               ,               
		OD_PB_MANUF_NAME                ,               
		OD_PB_MANUF_ID                  ,               
		OD_PB_MANUF_COUNTRY_CD          ,               
		OD_PB_DATE_REPORTED             ,               
		OD_PB_DATE_PROPOSAL_PROVIDED    ,               
		OD_PB_DATE_SAMPLE_SENT          ,               
		OD_PB_PO_NUM                    ,               
		OD_PB_SKU                       ,               
		OD_PB_ITEM_DESC                 ,               
		OD_PB_DEPARTMENT                ,               
		OD_PB_DECLARED_QUANTITY         ,               
		OD_PB_INSP_CERTIFICATE_NUMBER   ,               
		OD_PB_DESTINATION_COUNTRY       ,               
		OD_PB_GENERAL_INSPECTION_LEVEL  ,               
		OD_PB_AQL                       ,               
		OD_PB_INSPECTION_PROTOCOL_NUM   ,               
		OD_PB_DATE_PROPOSAL_APPROVED    ,               
		OD_PB_SAMPLE_SIZE               ,               
		OD_PB_DEFECT_FOUND_CRITICAL     ,               
		OD_PB_DEFECT_FOUND_MAJOR        ,               
		OD_PB_FAILURE_REASONS           ,               
		OD_PB_RESULTS                   ,               
		OD_PB_ATTACHMENT                ,               
		OD_PB_QA_ENGR_EMAIL             ,               
		OD_PB_APPROVAL_STATUS           ,               
		OD_PB_COMMENTS                  ,               
		OD_PB_INSPECTION_SERVICE_OFFIC  ,               
		OD_PB_DEFECT_FOUND_MINOR        ,               		
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_PSI_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_PSI_IC_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_PSI_IC;

PROCEDURE OD_PB_QA_REPORT IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_QA_REPORTING_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_DATE_APPROVED       ,     
		OD_PB_QA_ENGINEER         ,     
		OD_PB_DEPARTMENT          ,     
		OD_PB_ITEM_SUB_CLASS_ID   ,     
		OD_PB_REPORT_NAME         ,     
		OD_PB_SOURCING_MERCHANT   ,     
		OD_PB_ATTACHMENT          ,     
		OD_PB_COMMENTS            ,     
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_QA_REPORTING',
                  '1', --1 for INSERT
              'OD_PB_QA_ENGINEER,OD_PB_REPORT_NAME',
		OD_PB_DATE_APPROVED       ,     
		OD_PB_QA_ENGINEER         ,     
		OD_PB_DEPARTMENT          ,     
		OD_PB_ITEM_SUB_CLASS_ID   ,     
		OD_PB_REPORT_NAME         ,     
		OD_PB_SOURCING_MERCHANT   ,     
		OD_PB_ATTACHMENT          ,     
		OD_PB_COMMENTS            ,     
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_QA_REPORTING_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_QA_REPORT;

PROCEDURE OD_PB_REG_CERT IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_REGULATORY_CERT_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		 OD_PB_REGISTRATION_ORG                 ,
		 OD_PB_REGISTRATION_NUMBER              ,
		 OD_PB_SOURCING_AGENT                   ,
		 OD_PB_ITEM_DESC                        ,
		 OD_PB_SKU                              ,
		 OD_PB_DATE_OPENED                      ,
		 OD_PB_FACTORY_NAME                     ,
		 OD_PB_VENDOR_ID                        ,
		 OD_PB_COMMENTS                         ,
		 OD_PB_CASE_NUMBER                      ,
		 OD_PB_AMOUNT                           ,
		 OD_PB_DATE_DUE                         ,
		 OD_PB_DATE_CLOSED                      ,
		 OD_PB_RENEW_REGISTRATION               ,
		 OD_PB_FREQUENCY                        ,
		 OD_PB_DATE_RENEW                       ,
		 OD_PB_ATTACHMENT                       ,
		 OD_PB_QA_ENGINEER                      ,
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_REGULATORY_CERT',
                  '1', --1 for INSERT
              'OD_PB_REGISTRATION_ID,OD_PB_SKU',
		 OD_PB_REGISTRATION_ORG                 ,
		 OD_PB_REGISTRATION_NUMBER              ,
		 OD_PB_SOURCING_AGENT                   ,
		 OD_PB_ITEM_DESC                        ,
		 OD_PB_SKU                              ,
		 OD_PB_DATE_OPENED                      ,
		 OD_PB_FACTORY_NAME                     ,
		 OD_PB_VENDOR_ID                        ,
		 OD_PB_COMMENTS                         ,
		 OD_PB_CASE_NUMBER                      ,
		 OD_PB_AMOUNT                           ,
		 OD_PB_DATE_DUE                         ,
		 OD_PB_DATE_CLOSED                      ,
		 OD_PB_RENEW_REGISTRATION               ,
		 OD_PB_FREQUENCY                        ,
		 OD_PB_DATE_RENEW                       ,
		 OD_PB_ATTACHMENT                       ,
		 OD_PB_QA_ENGINEER                      ,
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_REGISTRATION_ID	
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_REGULATORY_CERT_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_REG_CERT;

PROCEDURE OD_PB_RET_GOODS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_RETURNED_GOODS_ANAL_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_DATE_REPORTED     ,               
		OD_PB_STORE_NUMBER       ,              
		OD_PB_SKU                 ,             
		OD_PB_DEPARTMENT          ,             
		OD_PB_QA_ENGINEER         ,             
		OD_PB_COMMENTS            ,             
		OD_PB_ENGINEER_FINDINGS   ,             
		OD_PB_SAMPLE_DISPOSITION  ,             
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_RETURNED_GOODS_ANALYSIS',
                  '1', --1 for INSERT
              'OD_PB_SAMPLE_NUMBER,OD_PB_SKU',
		OD_PB_DATE_REPORTED     ,               
		OD_PB_STORE_NUMBER       ,              
		OD_PB_SKU                 ,             
		OD_PB_DEPARTMENT          ,             
		OD_PB_QA_ENGINEER         ,             
		OD_PB_COMMENTS            ,             
		OD_PB_ENGINEER_FINDINGS   ,             
		OD_PB_SAMPLE_DISPOSITION  ,             
		d.user_name,
	          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_SAMPLE_NUMBER    
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_RETURNED_GOODS_ANALY_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_RET_GOODS;

PROCEDURE OD_PB_SRVC_SCORECARD IS
 v_cnt NUMBER:=0;
BEGIN
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
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_SRVC_SCORECARD;

PROCEDURE OD_PB_SPEC_APR IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_SPEC_APPROVAL_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_VENDOR_NAME                ,      		
		OD_PB_SKU                        ,      
		OD_PB_SKU_DESCRIPTION            ,      
		OD_PB_DEPARTMENT                 ,      
		OD_PB_QA_APPROVER                ,      
		OD_PB_APPROVAL_STATUS            ,      
		OD_PB_ATTACHMENT                 ,      
		OD_PB_COMMENTS                   ,      
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_SPEC_APPROVAL',
                  '1', --1 for INSERT
               'OD_PB_VENDOR_NAME,OD_PB_SKU',
		OD_PB_VENDOR_NAME                ,      		
		OD_PB_SKU                        ,      
		OD_PB_SKU_DESCRIPTION            ,      
		OD_PB_DEPARTMENT                 ,      
		OD_PB_QA_APPROVER                ,      
		OD_PB_APPROVAL_STATUS            ,      
		OD_PB_ATTACHMENT                 ,      
		OD_PB_COMMENTS                   ,      
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_SPEC_APPROVAL_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_SPEC_APR;

PROCEDURE OD_PB_TEST_DETAILS IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_TEST_DETAILS_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_TECH_RPT_NUM  ,   
		OD_PB_PROJ_NUM       ,  
		OD_PB_ITEM_ID        ,  
		OD_PB_TEST_NAME      ,  
		OD_PB_RESULTS        ,  
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_TEST_DETAILS',
                  '1', --1 for INSERT
              'OD_PB_TECH_RPT_NUM,OD_PB_ITEM_ID',
		OD_PB_TECH_RPT_NUM  ,   
		OD_PB_PROJ_NUM       ,  
		OD_PB_ITEM_ID        ,  
		OD_PB_TEST_NAME      ,  
		OD_PB_RESULTS        ,
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_TEST_DETAILS_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_TEST_DETAILS;

PROCEDURE OD_PB_TESTING IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_TESTING_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_PROGRAM_TEST_TYPE           ,             
		OD_PB_DATE_REPORTED               ,             
		OD_PB_TECH_RPT_NUM                ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_RESULTS                     ,             
		OD_PB_APPROVAL_STATUS             ,             
		OD_PB_CLASS                       ,             
		OD_PB_COMMENTS                    ,             
		OD_PB_COMPARISON_NAME             ,             
		OD_PB_CTQ_LIST                    ,             
		OD_PB_CTQ_RESULTS                 ,             
		OD_PB_DATE_APPROVED               ,             
		OD_PB_DATE_DUE                    ,             
		OD_PB_DATE_KICKOFF                ,             
		OD_PB_DATE_OPENED                 ,             
		OD_PB_DATE_PROPOSAL_APPROVED      ,             
		OD_PB_DATE_PROPOSAL_PROVIDED      ,             
		OD_PB_DATE_REPORT_DUE             ,             
		OD_PB_DATE_TESTING_BEGINS         ,             
		OD_PB_DPPM                        ,             
		OD_PB_FACTORY_ID                  ,             
		OD_PB_1ST_ARTICLE_DEFECT_RATE     ,             
		OD_PB_MINOR                       ,             
		OD_PB_MAJOR                       ,             
		OD_PB_CRITICAL                    ,             
		OD_PB_MERCHANDISING_APPROVER      ,             
		OD_PB_PO_NUM                      ,             
		OD_PB_QA_APPROVER                 ,             
		OD_PB_SAMPLE_SIZE                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_CONTACT                     ,             
		OD_PB_VENDORS_AWARDED             ,             
		OD_PB_VENDOR_COMMENTS             ,             
		OD_PB_AUDITOR_NAME                ,             
		OD_PB_ORG_AUDITED                 ,             
		OD_PB_FQA_SCORE                   ,             
		OD_PB_SPECIFICATION_NAME          ,             
		OD_PB_LOT_SIZE                   ,              
		OD_PB_DEFECT_SUM                 ,              
		OD_PB_OBJECTIVE                  ,              
		OD_PB_SUPPLIER                   ,              
		OD_PB_ATTACHMENT                 ,              
		OD_PB_FACTORY_NAME               ,              
		OD_PB_TESTINGPLAN_ID             ,              
		OD_PB_PROD_TEST_REPT_NUM         ,              
		OD_PB_PROD_TEST_RESULT           ,              
		OD_PB_TRANSIT_TEST_REPT_NUMBER   ,              
		OD_PB_TRANSIT_TEST_RESULT        ,              
		OD_PB_ART_TEST_REPORT_NUMBER     ,              
		OD_PB_ARTWORK_TEST_RESULT        ,              
		OD_PB_QA_ENGR_EMAIL              ,              
		OD_PB_ODGSO_QA_ENGINEER          ,              
	        qa_created_by_name	,
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id,
		od_pb_legacy_rec_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_TESTING',
                  '1', --1 for INSERT
              'OD_PB_RECORD_ID,OD_PB_PROGRAM_TEST_TYPE,OD_PB_SKU',
		OD_PB_PROGRAM_TEST_TYPE           ,             
		OD_PB_DATE_REPORTED               ,             
		OD_PB_TECH_RPT_NUM                ,             
		OD_PB_CA_TYPE                     ,             
		OD_PB_RESULTS                     ,             
		OD_PB_APPROVAL_STATUS             ,             
		OD_PB_CLASS                       ,             
		OD_PB_COMMENTS                    ,             
		OD_PB_COMPARISON_NAME             ,             
		OD_PB_CTQ_LIST                    ,             
		OD_PB_CTQ_RESULTS                 ,             
		OD_PB_DATE_APPROVED               ,             
		OD_PB_DATE_DUE                    ,             
		OD_PB_DATE_KICKOFF                ,             
		OD_PB_DATE_OPENED                 ,             
		OD_PB_DATE_PROPOSAL_APPROVED      ,             
		OD_PB_DATE_PROPOSAL_PROVIDED      ,             
		OD_PB_DATE_REPORT_DUE             ,             
		OD_PB_DATE_TESTING_BEGINS         ,             
		OD_PB_DPPM                        ,             
		OD_PB_FACTORY_ID                  ,             
		OD_PB_1ST_ARTICLE_DEFECT_RATE     ,             
		OD_PB_MINOR                       ,             
		OD_PB_MAJOR                       ,             
		OD_PB_CRITICAL                    ,             
		OD_PB_MERCHANDISING_APPROVER      ,             
		OD_PB_PO_NUM                      ,             
		OD_PB_QA_APPROVER                 ,             
		OD_PB_SAMPLE_SIZE                 ,             
		OD_PB_SKU                         ,             
		OD_PB_DEPARTMENT                  ,             
		OD_PB_CONTACT                     ,             
		OD_PB_VENDORS_AWARDED             ,             
		OD_PB_VENDOR_COMMENTS             ,             
		OD_PB_AUDITOR_NAME                ,             
		OD_PB_ORG_AUDITED                 ,             
		OD_PB_FQA_SCORE                   ,             
		OD_PB_SPECIFICATION_NAME          ,             
		OD_PB_LOT_SIZE                   ,              
		OD_PB_DEFECT_SUM                 ,              
		OD_PB_OBJECTIVE                  ,              
		OD_PB_SUPPLIER                   ,              
		OD_PB_ATTACHMENT                 ,              
		OD_PB_FACTORY_NAME               ,              
		OD_PB_TESTINGPLAN_ID             ,              
		OD_PB_PROD_TEST_REPT_NUM         ,              
		OD_PB_PROD_TEST_RESULT           ,              
		OD_PB_TRANSIT_TEST_REPT_NUMBER   ,              
		OD_PB_TRANSIT_TEST_RESULT        ,              
		OD_PB_ART_TEST_REPORT_NUMBER     ,              
		OD_PB_ARTWORK_TEST_RESULT        ,              
		OD_PB_QA_ENGR_EMAIL              ,              
		OD_PB_ODGSO_QA_ENGINEER          ,              
		d.user_name,
          e.user_name,
		a.collection_id,
		a.occurrence,
		a.OD_PB_RECORD_ID
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_TESTING_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END OD_PB_TESTING;

PROCEDURE OD_PB_WITHDRAW IS
 v_cnt NUMBER:=0;
BEGIN
INSERT INTO apps.Q_OD_PB_WITHDRAW_IV
    (      process_status, 
               organization_code ,
                  plan_name,
                  insert_type,
		  matching_elements,
		OD_PB_SKU                    ,  
		OD_PB_ITEM_DESC              ,  
		OD_PB_SUPPLIER               ,  
		OD_PB_FACTORY_NAME           ,  
		OD_PB_DEFECT_SUM             ,  
		OD_PB_INVESTIGATION_ID       ,  
		OD_PB_WITHDRAWAL_DATE        ,  
		OD_PB_STORE_NOTICE           ,  
		OD_PB_COST_ASSOCIATED        ,  
		OD_PB_ATTACHMENT             ,  
	        qa_created_by_name	,	
                qa_last_updated_by_name,
		od_pb_legacy_col_id,
		od_pb_legacy_ocr_id
        )
SELECT            '1',
                  'PRJ',
                  'OD_PB_WITHDRAW',
                  '1', --1 for INSERT
              'OD_PB_SKU,OD_PB_SUPPLIER,OD_PB_FACTORY_NAME',
		OD_PB_SKU                    ,  
		OD_PB_ITEM_DESC              ,  
		OD_PB_SUPPLIER               ,  
		OD_PB_FACTORY_NAME           ,  
		OD_PB_DEFECT_SUM             ,  
		OD_PB_INVESTIGATION_ID       ,  
		OD_PB_WITHDRAWAL_DATE        ,  
		OD_PB_STORE_NOTICE           ,  
		OD_PB_COST_ASSOCIATED        ,  
		OD_PB_ATTACHMENT             ,  
		d.user_name,
	          e.user_name,
		a.collection_id,
		a.occurrence
 FROM     
    apps.fnd_user e,
    apps.fnd_user d,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET b,
    apps.fnd_user@GSIPRD01.NA.ODCORP.NET c,
        apps.Q_OD_PB_WITHDRAW_V@GSIPRD01.NA.ODCORP.NET a
 WHERE  c.user_name=a.created_by
   AND  b.user_name=a.last_updated_by
   AND  d.user_name=c.user_name
   AND  e.user_name=b.user_name;
  DBMS_OUTPUT.PUT_LINE('Total :'||TO_CHAR(SQL%ROWCOUNT));
END  OD_PB_WITHDRAW;

END XX_QA_MAIN_PLAN_PKG;
/
