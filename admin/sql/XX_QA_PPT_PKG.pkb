SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PPT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PPT_PKG.pkb      	   	               |
-- | Description :  OD QA PPT Processing Pkg                           |
-- | Rice id     :  E2096                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-Oct-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       07-Mar-2012 Paddy Sanjeevi     Defect 17441              |
-- |1.2       17-May-2012 Paddy Sanjeevi     Defect 18622              |
-- |1.1       27-Sep-2012 Paddy Sanjeevi     Defect 20454              |
-- |1.4       18-Dec-2012 OD AMS Offshore    Defect 21498              |
-- |1.5       02-Jul-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS


PROCEDURE load_docs(p_file_name IN VARCHAR2,p_report_no IN varchar2,p_test_id varchar2)
IS
  v_cnt 	NUMBER:=0;
BEGIN
 SELECT COUNT(1) 
    INTO v_cnt
    FROM xx_qa_ppt_docs
   WHERE test_id=p_test_id
     AND test_doc_name=p_file_name;
  IF v_cnt=0 THEN
     BEGIN
       INSERT 
         INTO xx_qa_ppt_docs
       VALUES (p_test_id,
  	       p_file_name,
	       p_report_no,
	      'N'
  	      );
     EXCEPTION
       WHEN others THEN
         NULL;
     END;
  END IF;
  COMMIT;
END load_docs;

--- Added function as Per Ver 1.4
FUNCTION load_dept_number( p_dept IN VARCHAR2
			) 
RETURN VARCHAR2
IS
v_dept_number VARCHAR2(150);

BEGIN
   SELECT flex_value
     INTO  v_dept_number
     FROM apps.fnd_flex_values_vl
    WHERE flex_value_set_id in (select flex_value_set_id
     FROM apps.fnd_flex_value_sets where flex_value_set_name='XX_GI_DEPARTMENT_VS')
     AND SYSDATE BETWEEN nvl(start_date_active,SYSDATE) and nvl(end_date_active,SYSDATE)
     AND description=p_dept;
 
 RETURN(v_dept_number);
EXCEPTION
 WHEN others THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in load_dept_number :'||SQLERRM);
  RETURN NULL;
END load_dept_number;

PROCEDURE load_doc_stg (p_file_name IN VARCHAR2,p_report_no IN varchar2,p_test_id varchar2)
IS

  v_bfile       BFILE;
  v_blob        BLOB;
  v_directory_name 	VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_cnt 	NUMBER:=0;

BEGIN

  v_bfile := BFILENAME (v_directory_name, p_file_name);
  DBMS_LOB.fileopen (v_bfile, DBMS_LOB.file_readonly);

  SELECT COUNT(1)
    INTO v_cnt
    FROM xx_qa_ppt_doc_stg
   WHERE test_id=p_test_id
     AND test_doc_name=p_file_name;

  IF v_cnt=0 THEN

     INSERT 
       INTO apps.xx_qa_ppt_doc_stg
          ( test_doc_name,
	    test_document,
 	    report_no,
	    test_id,
	    process_flag,
	    creation_date,
	    created_by
          )
     VALUES 
	 ( p_file_name,
	   EMPTY_BLOB (),
	   p_report_no,	
	   p_test_id,	
	   'N',sysdate,-1
 	 )
     RETURN test_document
     INTO v_blob;
 
     DBMS_LOB.loadfromfile (v_blob, v_bfile, DBMS_LOB.getlength (v_bfile));
     DBMS_LOB.fileclose (v_bfile);

     UPDATE xx_qa_ppt_docs
        SET process_flag='Y'
      WHERE test_id=p_test_id
        AND test_doc_name=p_file_name;

     COMMIT;
  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in file opening in load_doc_stg for the file :'||p_file_name||','||SQLERRM);
END load_doc_stg;


PROCEDURE xx_ppt_load_doc
IS
  CURSOR C1 IS
  SELECT DISTINCT report_doc report_no,test_id
    FROM xx_qa_ppt_stg a
   WHERE process_flag=1
     AND report_doc is not null
     AND tests_upd_flag='T';
 

  CURSOR C2 IS
  SELECT test_doc_name, test_id, report_no
    FROM xx_qa_ppt_docs
   WHERE process_Flag='N';



  v_file 	VARCHAR2(50);
  v_report_no 	VARCHAR2(100);
  v_loc  	NUMBER;
  v_length 	NUMBER;
  i 		NUMBER:=1;
  j 		NUMBER:=1;
 
BEGIN

  DELETE
    FROM xx_qa_ppt_doc_stg stg
   WHERE creation_date<sysdate-30
     AND process_Flag='Y';

  DELETE
    FROM xx_qa_ppt_docs
   WHERE process_Flag='Y';
  COMMIT;

  FOR cur IN  c1 loop

    v_loc       :=INSTR(cur.report_no,'^',1);
    v_report_no :=cur.report_no;
 
    IF v_loc>0 THEN
 
       v_length:=LENGTH(v_report_no);
 
       WHILE j <= v_length LOOP
  
         v_loc:=INSTR(v_report_no,'^',1);
      
	 IF v_loc> 0 THEN
         
            v_file:=substr(v_report_no,1,v_loc-1);
            v_report_no:=substr(v_report_no,v_loc+1);
	    load_docs(v_file,cur.report_no,cur.test_id);
	 ELSE
	    v_file:=v_report_no;
	    load_docs(v_file,cur.report_no,cur.test_id);
            EXIT;
         END IF;
	 j:=j+v_loc;
       END LOOP;
    ELSE
       load_docs(cur.report_no,cur.report_no,cur.test_id);
    END IF;
  END LOOP;
  COMMIT;

 FOR cur IN  c2 loop

   load_doc_stg(cur.test_doc_name,cur.report_no,cur.test_id);

 END LOOP;

 UPDATE apps.xx_qa_ppt_docs a
    SET process_flag='Y'
  WHERE process_flag='N'
    AND EXISTS (SELECT 'x'
		  FROM apps.xx_qa_ppt_doc_stg
		 WHERE test_id=a.test_id
		   AND test_doc_name=a.test_doc_name);
 COMMIT;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_load_doc :'||SQLERRM);
END xx_ppt_load_doc;

PROCEDURE xx_ppt_docs
IS

CURSOR C1 IS
select stg.rowid arowid,
       stg.test_doc_name,
       stg.test_document,
       stg.test_id
  from xx_qa_ppt_doc_stg stg
 where stg.process_flag='N';

 CURSOR C_attach_docs IS
 select stg.rowid arowid,
        stg.test_doc_name,
        stg.test_document,
        stg.test_id,
	stg.doc_id,
        a.plan_id,
        b.occurrence,
        b.collection_id
  from  apps.Q_OD_OB_PPT_TEST_STATUS_V b,
        apps.qa_plans a,
        xx_qa_ppt_doc_stg stg
  where stg.process_flag='P'
    and a.name='OD_OB_PPT_TEST_STATUS'
    and b.plan_id=a.plan_id
    and b.OD_OB_TEST_ID=stg.test_id
    and not exists (select 'x'
                      from apps.fnd_documents_tl fdt,
                           apps.fnd_document_datatypes fdd,
                           apps.fnd_documents fd,
                           apps.FND_ATTACHED_DOCUMENTS fad
                     where fad.pk3_value = b.plan_id
                       and fad.pk2_value = b.collection_id
                       and fad.pk1_value = b.occurrence
                       and fad.entity_name = 'QA_RESULTS'
                       and fd.document_id = fad.document_id
                       and fdd.datatype_id = fd.datatype_id
                       and fdd.user_name='File'  
                       and fdd.language = 'US'
                       and fdt.document_id = fd.document_id 
                       and fd.file_name=stg.test_doc_name);  -- Modified for R12

CURSOR C_exist_docs IS
 select stg.rowid arowid,
        stg.test_doc_name,
        stg.test_document,
        stg.test_id,
	stg.doc_id,
        a.plan_id,
        b.occurrence,
        b.collection_id
  from  apps.Q_OD_OB_PPT_TEST_STATUS_V b,
        apps.qa_plans a,
        xx_qa_ppt_doc_stg stg
  where stg.process_flag='P'
    and a.name='OD_OB_PPT_TEST_STATUS'
    and b.plan_id=a.plan_id
    and b.OD_OB_TEST_ID=stg.test_id
    and exists (select 'x'
                      from apps.fnd_documents_tl fdt,
                           apps.fnd_document_datatypes fdd,
                           apps.fnd_documents fd,
                           apps.FND_ATTACHED_DOCUMENTS fad
                     where fad.pk3_value = b.plan_id
                       and fad.pk2_value = b.collection_id
                       and fad.pk1_value = b.occurrence
                       and fad.entity_name = 'QA_RESULTS'
                       and fd.document_id = fad.document_id
                       and fdd.datatype_id = fd.datatype_id
                       and fdd.user_name='File'  
                       and fdd.language = 'US'
                       and fdt.document_id = fd.document_id 
                       and fd.file_name=stg.test_doc_name);  -- Modified for R12


  v_media_id	NUMBER;
  v_file_type   VARCHAR2(50);
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  l_rowid rowid;
  l_seq_num	NUMBER;
  v_error       VARCHAR2(2000);

BEGIN

  FOR cur IN C_exist_docs LOOP

      UPDATE xx_qa_ppt_doc_stg
         SET process_flag='Y'
       WHERE rowid=cur.arowid;

  END LOOP;
  COMMIT;

  FOR cur IN C1 LOOP

    v_error:=NULL;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;

    IF UPPER(SUBSTR(cur.test_doc_name,length(cur.test_doc_name)-2)) LIKE 'PDF%' THEN
 
       v_file_type:='application/pdf';

    ELSIF UPPER(SUBSTR(cur.test_doc_name,length(cur.test_doc_name)-2)) LIKE 'XLS%' THEN
 
       v_file_type:='application/vnd.ms-excel';

    ELSIF UPPER(SUBSTR(cur.test_doc_name,length(cur.test_doc_name)-2)) LIKE 'PPT%' THEN
 
       v_file_type:='application/vnd.ms-powerpoint';

    ELSIF UPPER(SUBSTR(cur.test_doc_name,length(cur.test_doc_name)-2)) LIKE 'DOC%' THEN
 
       v_file_type:='application/msword';

    END IF;


       BEGIN
         INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        program_name,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
         VALUES  (
                       v_media_id,
                       cur.test_doc_name,
                       v_file_type,
                       sysdate,
                       'FNDATTCH',
                       cur.test_document,
                       'US',
                       'UTF8',
                       'BINARY'
	       );
         UPDATE xx_qa_ppt_doc_stg
            SET doc_id=v_media_id,
	        process_flag='P'
          WHERE rowid=cur.arowid;
      EXCEPTION
         WHEN others THEN
	   v_error:=sqlerrm;
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting fnd_lobs :'||cur.test_doc_name||','||v_error);
      END;

  END LOOP;
  COMMIT;

  
  FOR cur IN C_attach_docs LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => sysdate
	, X_CREATED_BY                   => fnd_global.user_id
	, X_LAST_UPDATE_DATE             => sysdate
	, X_LAST_UPDATED_BY              => fnd_global.user_id
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.test_id||','||cur.test_doc_name
	, X_FILE_NAME                    => cur.test_doc_name
	, X_MEDIA_ID                     => cur.doc_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      SELECT NVL(MAX(seq_num),0)+10
        INTO l_seq_num
        FROM fnd_attached_documents
       WHERE entity_name='QA_RESULTS'
         AND pk1_value=cur.occurrence
         AND pk2_value=cur.collection_id
         AND pk3_value=cur.plan_id;
    EXCEPTION
      WHEN others THEN
	l_seq_num:=10;
    END;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => sysdate
	, X_CREATED_BY                   => fnd_global.user_id
	, X_LAST_UPDATE_DATE             => sysdate
	, X_LAST_UPDATED_BY              => fnd_global.user_id
	, X_LAST_UPDATE_LOGIN            => fnd_global.user_id
	, X_SEQ_NUM                      => l_seq_num
	, X_ENTITY_NAME                  => 'QA_RESULTS'
	, X_COLUMN1                      => null
	, X_PK1_VALUE                    => cur.occurrence
	, X_PK2_VALUE                    => cur.collection_id
	, X_PK3_VALUE                    => cur.plan_id
	, X_PK4_VALUE                    => null
	, X_PK5_VALUE                    => null
	, X_AUTOMATICALLY_ADDED_FLAG     => 'N'
	, X_DATATYPE_ID                  => 6
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.test_id||','||cur.test_doc_name
	, X_FILE_NAME                    => cur.test_doc_name
	, X_MEDIA_ID                     => cur.doc_id
   );

      UPDATE qa_results
         SET character20='Y'
       WHERE plan_id=cur.plan_id
         AND occurrence=cur.occurrence
         AND collection_id=cur.collection_id;

      -- Added for Defect 20454

      UPDATE xx_qa_ppt_doc_stg
         SET process_flag='Y'
       WHERE rowid=cur.arowid;
	
      -- End of Defect 20454

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_docs '||SQLERRM);
END xx_ppt_docs;

PROCEDURE xx_ppt_cap_defects
IS

CURSOR c_ppt_to_capds
IS
SELECT a.plan_id,
       a.organization_id,
       a.occurrence,
       a.od_ob_test_refid test_id,
       a.od_ob_pptsku_refid sku_id,
       a.od_ob_ref_pptid ppt_id,
       a.od_pb_defect_code,
       a.od_pb_defect_sum,
       a.od_ob_ref_capid cap_id,
       b.OD_SC_FACTORY_NAME,
       b.OD_PB_AUDITOR_NAME,
       b.OD_PB_QA_ENGR_EMAIL,
       b.OD_OB_VENDOR_NAME,
       b.OCCURRENCE cap_occurrence,
       b.COLLECTION_ID    
  FROM apps.q_od_ob_cap_v b,
       apps.q_od_ob_ppt_test_defects_v a 
 WHERE a.od_ob_ref_capid IS NOT NULL
   AND a.od_ob_dsid_ref IS NULL
   AND b.od_pb_car_id=a.od_ob_ref_capid
   AND NOT EXISTS (SELECT 'x'
                     FROM apps.q_od_ob_cap_defects_v
                    WHERE OD_OB_REF_CAPID=a.OD_OB_REF_CAPID
                      AND od_ob_qa_id=a.od_ob_ref_pptid||a.od_ob_test_refid
		      AND od_pb_defect_sum=a.od_pb_defect_code);

CURSOR c_capds_upd
IS
SELECT  a.plan_id,
	a.organization_id,
	a.occurrence,
	b.od_ob_ds_id
  FROM  apps.q_od_ob_cap_defects_v b,
	apps.q_od_ob_ppt_test_defects_v a
 WHERE  a.od_ob_dsid_ref IS NULL
   AND  b.od_ob_ref_capid=a.od_ob_ref_capid
   AND  b.od_pb_defect_sum=a.od_pb_defect_code;

  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
  v_error		VARCHAR2(2000); 
  
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  v_text		VARCHAR2(6000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);


BEGIN

  SELECT name INTO v_instance from v$database;

  FOR cur IN c_ppt_to_capds LOOP
	
    i:=i+1;
    v_error:=NULL;
    BEGIN
      INSERT INTO apps.Q_OD_OB_CAP_DEFECTS_IV
        (       process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		od_ob_ref_capid,
		od_ob_qa_id,
		od_pb_defect_sum,
		od_pb_comments,
		OD_PB_LEGACY_OCR_ID,
		OD_PB_LEGACY_COL_ID,
		OD_SC_FACTORY_NAME,
		OD_PB_AUDITOR_NAME,
		OD_PB_QA_ENGR_EMAIL,
		OD_OB_VENDOR_NAME,
 	        qa_created_by_name,
                qa_last_updated_by_name
        )
      VALUES
	(
 	       '1',
               'PRJ',
               'OD_OB_CAP_DEFECTS',
               '1', --1 for INSERT
               'OD_OB_REF_CAPID,OD_OB_QA_ID,OD_OB_DS_ID',
		cur.cap_id,
	        cur.ppt_id||cur.test_id,
		cur.od_pb_defect_code,
		cur.test_id||' / '||cur.od_pb_defect_sum,
		cur.cap_occurrence,
		cur.collection_id,
		cur.od_sc_factory_name,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,
		cur.od_ob_vendor_name,
		fnd_global.user_name,
     	        fnd_global.user_name
	);
    EXCEPTION
      WHEN others THEN
	v_error:=sqlerrm;
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Q_OD_OB_CAP_DEFECTS_IV '||v_error);
    END;
  END LOOP;

  COMMIT;
  IF i>0 THEN
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'No');
       IF v_request_id>0 THEN
          COMMIT;
       END IF;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
       END IF;

       BEGIN
         SELECT request_id
           INTO v_crequest_id
	   FROM apps.fnd_concurrent_requests
  	  WHERE parent_request_id=v_request_id;
       EXCEPTION
         WHEN others THEN
	   v_crequest_id:=NULL;
       END;

       IF v_crequest_ID IS NOT NULL THEN
	
          IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_crequest_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

             IF v_dphase = 'COMPLETE' THEN
  
  	        dbms_output.put_line('success');

             END IF;
          END IF;

       END IF;

  END IF;

  FOR cur IN c_capds_upd LOOP

    UPDATE qa_results
       SET character7=cur.od_ob_ds_id
     WHERE plan_id=cur.plan_id
       AND organization_id=cur.organization_id
       AND occurrence=cur.occurrence;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_cap_defect '||SQLERRM);
END xx_ppt_cap_defects;


PROCEDURE xx_ppt_cap 
IS

CURSOR c_ppt_to_cap 
IS
SELECT  DISTINCT a.plan_id,
       a.organization_id,
       a.od_ob_test_refid test_id,
       a.od_ob_pptsku_refid sku_id,
       a.od_ob_ref_pptid ppt_id,
       ppt.od_sc_region,
       ppt.od_ob_vendor_name,
       ppt.od_ob_factory_name,
       --ppt.od_pb_contact factory_email,      -- Commented as per ver 1.4
       ppt.od_pb_contact_email factory_email,  -- Added as Per Ver 1.4
       ppt.od_sc_audit_agent,
       ppt.od_pb_auditor_name,
       ppt.od_pb_qa_engr_email,
       sku.od_ob_pptsku_id,
       sku.od_pb_vendor_vpc,
       sku.od_ob_sku,
       sku.od_pb_item_desc,
       sku.od_pb_sc_dept_name,
       sts.od_pb_report_number
  FROM apps.q_od_ob_ppt_test_status_v sts,
       apps.q_od_ob_ppt_sku_v sku,
       apps.q_od_ob_ppt_v ppt,
       apps.q_od_ob_ppt_test_defects_v a 
 WHERE a.od_ob_ref_capid IS NULL
   AND ppt.od_ob_ppt_id=a.od_ob_ref_pptid
   AND sku.od_ob_ref_pptid=a.od_ob_ref_pptid
   AND sku.od_ob_pptsku_id=a.od_ob_pptsku_refid
   AND sts.od_ob_test_id=a.od_ob_test_refid
   AND sts.OD_OB_PPTSKU_REFID=a.OD_OB_PPTSKU_REFID
   AND sts.OD_OB_REF_PPTID=a.OD_OB_REF_PPTID
   AND NOT EXISTS (SELECT 'x'
              FROM apps.q_od_ob_cap_v
             WHERE OD_OB_QA_ACT='PPT'
                   AND od_ob_qa_id=a.od_ob_ref_pptid||a.od_ob_test_refid);
CURSOR c_cap_upd
IS
SELECT  DISTINCT 
	a.plan_id,
	a.organization_id,
	b.od_pb_car_id,
	a.od_ob_test_refid test_id,
	a.od_ob_ref_pptid ppt_id,
	b.OD_PB_QA_ENGR_EMAIL,
	b.OD_PB_AUDITOR_NAME
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_ppt_test_defects_v a
 WHERE  a.od_ob_ref_capid IS NULL
   AND  b.od_ob_qa_act='PPT'
   AND  b.od_ob_qa_id=a.od_ob_ref_pptid||a.od_ob_test_refid;

CURSOR c_ppt_test(p_test_id VARCHAR2)
IS
SELECT *
  FROM apps.q_od_ob_ppt_test_status_v
 WHERE od_ob_test_id=p_test_id;


  v_request_id 		NUMBER;
  v_crequest_id 	NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  i			NUMBER:=0;
  
  v_error		VARCHAR2(2000);
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  v_text		VARCHAR2(6000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);
BEGIN

  SELECT name INTO v_instance from v$database;

  FOR cur IN c_ppt_to_cap LOOP
	
    i:=i+1;
    v_error:=NULL;
    BEGIN
      INSERT INTO apps.Q_OD_OB_CAP_IV
        (       process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_QA_ID,
		OD_OB_QA_ACT,
		od_sc_region,
		od_ob_sku,
		od_pb_vendor_vpc,
		od_pb_item_desc,
		od_pb_sc_dept_name,
		OD_OB_VENDOR_NAME,
		OD_SC_FACTORY_NAME,
		OD_OB_FACTORY_NAME,
		OD_SC_FACTORY_EMAIL,
		OD_SC_AUDIT_AGENT,
		OD_PB_AUDITOR_NAME,
		OD_PB_QA_ENGR_EMAIL,
		OD_PB_TECH_RPT_NUM,
 	        qa_created_by_name,
                qa_last_updated_by_name
        )
      VALUES
	(
 	       '1',
               'PRJ',
               'OD_OB_CAP',
               '1', --1 for INSERT
               'OD_PB_CAR_ID,OD_OB_QA_ID,OD_OB_QA_ACT',
		cur.ppt_id||cur.test_id,
		'PPT',
		cur.od_sc_region,
		cur.od_ob_sku,
		cur.od_pb_vendor_vpc,
		cur.od_pb_item_desc,
		cur.od_pb_sc_dept_name,
		cur.od_ob_vendor_name,
		cur.od_ob_factory_name,
		cur.od_ob_factory_name,
		cur.factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_auditor_name,
		cur.od_pb_qa_engr_email,				
		cur.od_pb_report_number,
		fnd_global.user_name,
     	        fnd_global.user_name
	);
    EXCEPTION
      WHEN others THEN
	v_error:=sqlerrm;
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_CAP_IV '||v_error);
    END;
  END LOOP;

  COMMIT;
  IF i>0 THEN
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'No');
       IF v_request_id>0 THEN
          COMMIT;
       END IF;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
       END IF;

       BEGIN
         SELECT request_id
           INTO v_crequest_id
	   FROM apps.fnd_concurrent_requests
  	  WHERE parent_request_id=v_request_id;
       EXCEPTION
         WHEN others THEN
	   v_crequest_id:=NULL;
       END;

       IF v_crequest_ID IS NOT NULL THEN
	
          IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_crequest_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

             IF v_dphase = 'COMPLETE' THEN
  
  	        dbms_output.put_line('success');

             END IF;
          END IF;

       END IF;

  END IF;

  FOR cur IN c_cap_upd LOOP

    UPDATE qa_results
       SET character9=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND organization_id=cur.organization_id
       AND character1=cur.test_id;

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for '||cur.test_id;
       v_text:='A CAP is created for the PPT. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'PPT ID  :'||cur.ppt_id ||chr(10);
       v_text:=v_text||'Test ID :'||cur.test_id ||chr(10);	
       v_text:=v_text||'CAP ID  :'||cur.od_pb_car_id||chr(10);
       IF lc_send_mail='Y' THEN
          v_email_list:=cur.OD_PB_QA_ENGR_EMAIL||':'||cur.OD_PB_AUDITOR_NAME;
       ELSE
          v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.lutzy@officedepot.com';
       END IF;

       IF v_instance<>'GSIPRDGB' THEN

	  v_subject:='Please Ignore this mail :'||v_subject;

       END IF;
       xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);
    END IF;

 
    FOR c IN c_ppt_test(cur.test_id) LOOP

        UPDATE qa_results
	   SET character26=cur.od_pb_car_id
         WHERE plan_id=c.plan_id
           AND organization_id=c.organization_id
           AND sequence3=cur.test_id;

    END LOOP;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_cap '||SQLERRM);
END xx_ppt_cap;

PROCEDURE xx_ppt_defect_upd
IS

  i			NUMBER:=0;
  v_request_id 		NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  v_error		VARCHAR2(2000)	;

   CURSOR c2(p_test_id VARCHAR2,p_defect VARCHAR2) IS
   SELECT plan_id,
	  occurrence,
	  organization_id
     FROM apps.q_od_ob_ppt_test_defects_v
    WHERE od_ob_test_refid=p_test_id
      AND od_pb_defect_code=p_defect;


 CURSOR C_defupd IS
 SELECT test_id,
	load_batch_id,
	defect_code,
	defect_comments,
	prev_report_no,
	report_no,
	status_timestamp
   FROM xx_qa_ppt_stg a
  WHERE process_flag=1
    AND tests_upd_flag='D'
    AND defect_code IS NOT NULL
    AND EXISTS (SELECT 'X'
		      FROM q_od_ob_ppt_test_defects_v
		     WHERE od_ob_test_refid=a.test_id
		       AND od_pb_defect_code=a.defect_code)
  ORDER BY test_id,status_timestamp;

-- Added distinct in the select clause for the Defect 17441 


 CURSOR C_defins IS
 SELECT distinct test_id,
	b.od_ob_pptsku_refid skuid,
	b.od_ob_ref_pptid pptid,
	b.od_pb_proj_num,
	b.od_pb_project_name,
	a.defect_code,
	a.defect_comments,
	a.report_no,
	a.prev_report_no,a.status_timestamp                   	
   FROM q_od_ob_ppt_test_status_v b,
	xx_qa_ppt_stg a
  WHERE a.process_flag=1
    AND defect_code IS NOT NULL
    AND tests_upd_flag='D'
    AND NVL(a.defects_cr_flag,'N')='N'
    AND b.od_ob_test_id=a.test_id
    AND NOT EXISTS (SELECT 'X'
		      FROM q_od_ob_ppt_test_defects_v
		     WHERE od_ob_test_refid=a.test_id
		       AND od_pb_defect_code=a.defect_code)
   ORDER BY a.test_id,a.status_timestamp;

BEGIN

  FOR cur IN c_defupd LOOP

    FOR c IN c2(cur.test_id,cur.defect_code) LOOP

      UPDATE qa_results
         SET  COMMENT1=NVL(cur.defect_comments,comment1)
	     ,CHARACTER6=NVL(UPPEr(cur.report_no),character6)
	     ,CHARACTER10=NVL(cur.prev_report_no,character10)
	     ,CHARACTER11=TO_CHAR(cur.load_batch_id)
	     ,last_update_date=sysdate
	     ,qa_last_update_date=sysdate
	     ,last_updated_by=fnd_global.user_id
	     ,qa_last_updated_by=fnd_global.user_id
       WHERE plan_id=c.plan_id
	 AND organization_id=c.organization_id
         AND occurrence=c.occurrence;

    END LOOP;

  END LOOP;
  COMMIT;


/*
  FOR cur IN c_defupd LOOP
	
	i:=i+1;
        v_error :=NULL;

        BEGIN
          INSERT INTO apps.Q_OD_OB_PPT_TEST_DEFECTS_IV
          (     process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_TEST_REFID,
		od_pb_defect_code,		
		od_pb_defect_sum,
		OD_PB_REPORT_NUMBER,
		od_pb_report_name,
	        OD_SC_NUM_WORKERS,
                qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_PPT_TEST_DEFECTS',
               '2', --1 for INSERT
               'OD_OB_TEST_REFID,OD_PB_DEFECT_CODE',
		cur.test_id, 
		cur.defect_code,
		cur.defect_comments,
	 	cur.report_no,
		cur.prev_report_no,
		cur.load_batch_id,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
	   v_error:=sqlerrm;
   	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_PPT_TEST_DEFECTS_IV '||v_error);
       END;
  END LOOP;

  IF i>0 THEN
                
     v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','2',TO_CHAR(V_user_id),'No');
     IF v_request_id>0 THEN
        COMMIT;
     END IF;

     IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
     END IF;
     COMMIT;
  END IF;
*/
  i:=0;
  FOR cur IN c_defins LOOP

      i:=i+1;
      v_error:=NULL;

    BEGIN
      INSERT INTO apps.Q_OD_OB_PPT_TEST_DEFECTS_IV
          (     process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_TEST_REFID      , 
		OD_OB_PPTSKU_REFID    , 
		OD_OB_REF_PPTID       , 
		OD_PB_PROJ_NUM        , 
		OD_PB_PROJECT_NAME    , 
		OD_PB_REPORT_NUMBER   , 
		OD_PB_DEFECT_CODE     , 
		OD_PB_DEFECT_SUM      , 
		OD_PB_REPORT_NAME     ,    
                qa_last_updated_by_name
       )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_PPT_TEST_DEFECTS',
               '1', --1 for INSERT
               'OD_OB_TEST_REFID,OD_PB_DEFECT_CODE',
		cur.test_id, 
		cur.skuid,
		cur.pptid,
		cur.od_pb_proj_num,
		cur.od_pb_project_name,
		cur.report_no,
		cur.defect_code,
		cur.defect_comments,
		cur.prev_report_no,
     	        fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
	   v_error:=sqlerrm;
   	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_PPT_TEST_DEFECTS_IV '||v_error);
       END;
  END LOOP;

  IF i>0 THEN

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'200','1',TO_CHAR(V_user_id),'No');
  IF v_request_id>0 THEN
     COMMIT;
  END IF;

  IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN

         IF v_dphase = 'COMPLETE' THEN
  
	    dbms_output.put_line('success');

         END IF;
  END IF;
  COMMIT;
  END IF;

  UPDATE xx_qa_ppt_stg a
     SET defects_cr_flag='Y',
	 process_flag=7
   WHERE PROCESS_FLAG=1
     AND tests_upd_flag='D'
     AND EXISTS (SELECT 'X'
		   FROM q_od_ob_ppt_test_defects_v
		  WHERE od_ob_test_refid=a.test_id
		    AND od_pb_defect_code=a.defect_code);
   COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_pp_defect_upd '||SQLERRM);
END xx_ppt_defect_upd;

PROCEDURE XX_PPT_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       )
IS


  v_errbuf     		VARCHAR2(2000);
  v_retcode    		VARCHAR2(50);
  i			NUMBER:=0;
  v_request_id 		NUMBER;
  v_user_id		NUMBER:=fnd_global.user_id;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;
  x_dummy		varchar2(2000) 	;
  v_batch_id		NUMBER;
  v_error		VARCHAR2(2000)  ;
  v_text		VARCHAR2(32000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);
  v_error_Flag		VARCHAR2(1):='N';

 CURSOR C1 IS
 SELECT test_id,rowid crowid,
        SP_CONTACTED_VENDOR ,           
        SAMPLE_EST_LAB      ,          
        SAMPLE_RECD_SP      ,           
        PROTOCOL            ,           
        REPORT_NO           ,         
	REPORT_DOC	    ,  
        EXPECT_COMPL        ,           
        TEST_STATUS         ,           
        TEST_STATUS_COMMENT ,           
        STATUS_TIMESTAMP    ,           
        RESULTS             ,           
        COMPL_DATE,
	paid_by,
	inv_amount,
	load_batch_id                    	
   FROM xx_qa_ppt_stg a
  WHERE process_flag=1
    AND tests_upd_flag='T'
    AND NOT EXISTS (SELECT 'X'
		      FROM q_od_ob_ppt_test_status_v
		     WHERE od_ob_test_id=a.test_id
		       AND od_sc_num_workers=a.load_batch_id)
  ORDER BY test_id,status_timestamp;

   CURSOR c2(p_test_id VARCHAR2) IS
   SELECT plan_id,
	  occurrence,
	  organization_id
     FROM apps.q_od_ob_ppt_test_status_v
    WHERE od_ob_test_id=p_test_id;


   CURSOR c_ins IS
   SELECT DISTINCT		
	ppt_id,
	sku_id,
	test_id,
	sp_contacted_vendor,
	sample_est_lab,
	sample_recd_sp,
	protocol,
	report_no,
        report_doc,
	expect_compl,
	test_status,
	test_status_comment,
	status_timestamp,
	results,
	compl_date,
	paid_by,
	inv_amount
     FROM xx_qa_ppt_stg
    WHERE process_flag=-1
    ORDER by test_id,status_timestamp;

   CURSOR c_error IS
   select b.transaction_interface_id txn_id,b.plan_name,a.error_message,a.error_column 
     from apps.qa_interface_errors a,
          apps.qa_results_interface b
    where b.plan_name in ('OD_OB_CAP_DEFECTS','OD_OB_CAP','OD_OB_PPT_TEST_STATUS',
			  'OD_OB_PPT_TEST_DEFECTS')
      and b.transaction_interface_id=a.transaction_interface_id 
      and NVL(b.character50,'N')='N';

BEGIN

  DELETE 
    FROM xx_qa_ppt_stg 
   WHERE process_flag=7
     AND TRUNC(creation_date)<SYSDATE-30;
  COMMIT;

  UPDATE xx_qa_ppt_stg
     SET process_flag=1,
	 tests_upd_flag='T'
   WHERE process_flag=-1
     AND tests_upd_flag='D'
     AND defect_code IS NULL;
  COMMIT;

  FOR cur IN c_ins LOOP

    v_batch_id:=NULL;
    v_error   :=NULL;

    SELECT apps.XX_QA_PPT_SEQ_S.nextval
      INTO v_batch_id
      FROM dual;

    BEGIN
      INSERT INTO xx_qa_ppt_stg
      ( ppt_id,
	sku_id,
	test_id,
	sp_contacted_vendor,
	sample_est_lab,
	sample_recd_sp,
	protocol,
	report_no,
	report_doc,
	expect_compl,
	test_status,
	test_status_comment,
	status_timestamp,
	results,
	compl_date,
        paid_by,
	inv_amount,
	tests_upd_flag,
	process_flag,
	creation_date,
	load_batch_id)
      VALUES
      (	cur.ppt_id,
	cur.sku_id,
	cur.test_id,
	cur.sp_contacted_vendor,
	cur.sample_est_lab,
	cur.sample_recd_sp,
	cur.protocol,
	cur.report_no,
	cur.report_doc,
	cur.expect_compl,
	cur.test_status,
	cur.test_status_comment,
	cur.status_timestamp,
	UPPER(cur.results),
	cur.compl_date,
	cur.paid_by,
	cur.inv_amount,
	'T',
	1,
	sysdate,
	v_batch_id
       );
    EXCEPTION
      WHEN others THEN
        v_error:=sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting c_ins xx_qa_ppt_stg'||v_error);
    END;
  END LOOP;  

  UPDATE xx_qa_ppt_stg
     SET process_flag=1
   WHERE process_flag=-1;
  COMMIT;

  xx_ppt_load_doc;

  FOR cur IN C1 LOOP

    FOR c IN C2(cur.test_id) LOOP

      UPDATE qa_results
         SET  CHARACTER10=NVL(TO_CHAR(cur.sp_contacted_vendor,'YYYY/MM/DD'),character10)
	     ,CHARACTER11=NVL(TO_CHAR(cur.sample_est_lab,'YYYY/MM/DD'),character11)
	     ,CHARACTER12=NVL(TO_CHAR(cur.sample_recd_sp,'YYYY/MM/DD'),character12)
	     ,CHARACTER13=NVL(cur.protocol,character13)
	     ,CHARACTER14=NVL(cur.report_no,character14)
	     ,CHARACTER21=NVL(cur.report_doc,character21)
	     ,CHARACTER15=NVL(TO_CHAR(cur.expect_compl,'YYYY/MM/DD'),character15)
	     ,CHARACTER16=NVL(cur.test_status,character16)
	     ,COMMENT1=NVL(cur.test_status_comment,comment1)
	     ,CHARACTER17=NVL(TO_CHAR(cur.status_timestamp,'YYYY/MM/DD'),character17)
	     ,CHARACTER18=NVL(UPPEr(cur.results),character18)
	     ,CHARACTER19=NVL(TO_CHAR(cur.compl_date,'YYYY/MM/DD'),character19)
	     ,CHARACTER22=TO_CHAR(cur.load_batch_id)
	     ,CHARACTER23=NVL(cur.paid_by,character23)
	     ,CHARACTER24=NVL(TO_CHAR(cur.inv_amount),character24)
	     ,last_update_date=sysdate
	     ,qa_last_update_date=sysdate
	     ,last_updated_by=fnd_global.user_id
	     ,qa_last_updated_by=fnd_global.user_id
       WHERE plan_id=c.plan_id
	 AND organization_id=c.organization_id
         AND occurrence=c.occurrence;

	UPDATE xx_qa_ppt_stg
           set process_Flag=7
         where rowid=cur.crowid;

    END LOOP;

  END LOOP;
  COMMIT;

  UPDATE xx_qa_ppt_stg a
     SET process_flag=7
   WHERE PROCESS_FLAG=1
     AND tests_upd_flag='T'
     AND EXISTS (SELECT 'X'
		      FROM q_od_ob_ppt_test_status_v
		     WHERE od_ob_test_id=a.test_id
		       AND od_sc_num_workers=a.load_batch_id);
   COMMIT;


    xx_ppt_defect_upd;

    xx_ppt_cap;

    xx_ppt_cap_defects;

    xx_ppt_docs;

   FOR cur IN c_error LOOP

       v_error_flag:='Y';

       v_text:=v_text||chr(10);
       v_text:=v_text||'Plan Name :'||cur.plan_name ||chr(10);
       v_text:=v_text||'Element   :'||cur.error_column||chr(10);	
       v_text:=v_text||'Error     :'||cur.error_message||chr(10);	

   END LOOP;

   IF v_error='Y' THEN

      SELECT name INTO v_instance from v$database;

      v_subject :='Collection Import Errors';

      v_email_list:='padmanaban.sanjeevi@officedepot.com:Fritz.lutzy@officedepot.com';
 
      IF v_instance<>'GSIPRDGB' THEN
 
         v_subject:='Please Ignore this mail :'||v_subject;

      END IF;
      xx_qa_fqa_pkg.SEND_NOTIFICATION(v_subject,v_email_list,v_cc_email_list,v_text);

      UPDATE apps.qa_results_interface a
         SET character50='Y'
       WHERE plan_name in ('OD_OB_CAP_DEFECTS','OD_OB_CAP','OD_OB_PPT_TEST_STATUS',
			  'OD_OB_PPT_TEST_DEFECTS')
         AND EXISTS (SELECT 'X'
		    FROM apps.qa_interface_errors
		   WHERE transaction_interface_id=a.transaction_interface_id);
      COMMIT;

   END IF;
EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_PPT_PROCESS;



PROCEDURE XX_PPT_EXTRACT
IS

  CURSOR c_bv IS
  SELECT 
	a.OD_OB_PPT_ID			,
	a.OD_PB_PROJECT_NAME		,
	a.OD_OB_TESTING			,
	a.OD_OB_VENDOR_NAME		,
	a.OD_OB_FACTORY_NAME		,
	a.OD_OB_FACTORY_LOCATION	,
	a.OD_SC_VENDOR_CONTACTS		,
	a.OD_PB_CONTACT_EMAIL		,
	a.OD_PB_COMPANY			,
	a.OD_OB_LAB_LOCATION		,
	a.OD_PB_AUDITOR_NAME		,
	a.OD_PB_QA_ENGR_EMAIL		,
	b.OD_OB_PPTSKU_ID		,
	b.OD_PB_VENDOR_VPC		,
	b.OD_OB_SKU			,
	b.OD_PB_ITEM_DESC		,
	b.OD_PB_SC_DEPT_NAME		,
	b.OD_PB_COUNTRY_OF_ORIGIN	,
	c.OD_OB_TEST_ID			,
	c.OD_OB_TEST_TYPE		,
	a.plan_id			,
	a.organization_id		,
	a.occurrence			,
        C.PLAN_ID TEST_PLAN_ID		,      
        B.OD_OB_SKU_GRP			,
        c.OD_PB_COMMENTS     --Adding two columns as per Ver 1.4
   FROM apps.Q_OD_OB_PPT_TEST_STATUS_V c,
        apps.Q_OD_OB_PPT_SKU_V b,
        apps.Q_OD_OB_PPT_V a
  WHERE b.OD_OB_REF_PPTID=a.OD_OB_PPT_ID	
    AND c.OD_OB_PPTSKU_REFID(+)=b.OD_OB_PPTSKU_ID	-- Included Outer join as per Ver 1.4
    AND NVL(a.OD_PB_AQL,'N')='Y'
    AND NVL(a.OD_OB_ENGR_NTFY,'N')='N'
    AND NVL(c.OD_SC_YES_NO,'N')='N'
  ORDER BY a.OD_OB_PPT_ID,b.OD_OB_PPTSKU_ID;	

 CURSOR c_ppt_rec IS
  SELECT DISTINCT
	a.OD_OB_PPT_ID			
   FROM apps.Q_OD_OB_PPT_TEST_STATUS_V c,
        apps.Q_OD_OB_PPT_SKU_V b,
        apps.Q_OD_OB_PPT_V a
  WHERE b.OD_OB_REF_PPTID=a.OD_OB_PPT_ID	
    AND c.OD_OB_PPTSKU_REFID=b.OD_OB_PPTSKU_ID	
    AND NVL(a.OD_PB_AQL,'N')='Y'
    AND NVL(a.OD_OB_ENGR_NTFY,'N')='N'
    AND NVL(c.OD_SC_YES_NO,'N')='N'
  ORDER BY a.OD_OB_PPT_ID;


 -- Variable Declaration
  TYPE c_ppt IS TABLE OF c_bv%rowtype;

  data_rec                c_ppt;

  lc_outdata              VARCHAR2(4000);
  v_file                  UTL_FILE.FILE_TYPE;
  lc_file_path            VARCHAR2(100) := 'XXMER_OUTBOUND';
  lc_file_name            VARCHAR2(100);
  lc_sysdate              VARCHAR2(20);
  lc_header               VARCHAR2(4000);
  v_text		  VARCHAR2(4000);
  v_default		  VARCHAR2(300);

  lc_ppt_out		   VARCHAR2(6000);

  lc_dept_number           VARCHAR(150);     -- As Per Ver 1.4
  TYPE plan_id_tbl_type IS TABLE OF qa_results.plan_id%TYPE INDEX BY BINARY_INTEGER;
  lt_plan_id  plan_id_tbl_type;

  lt_test_plan_id plan_id_tbl_type;
 

  TYPE org_id_tbl_type IS TABLE OF qa_results.organization_id%TYPE INDEX BY BINARY_INTEGER;
  lt_org_id  org_id_tbl_type;

  TYPE ocr_id_tbl_type IS TABLE OF qa_results.occurrence%TYPE INDEX BY BINARY_INTEGER;
  lt_ocr_id  ocr_id_tbl_type;

  TYPE test_id_tbl_type IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
  lt_test_id  test_id_tbl_type;

BEGIN

    v_default:='Please send notification to Fritz.Lutzy@OfficeDepot.com,Padmanaban.Sanjeevi@OfficeDepot.com '||
		   'and Quality@OfficeDepot.com, if the PPTID file was not received';
    FOR cur IN c_ppt_rec LOOP

	lc_ppt_out:=lc_ppt_out||chr(10);
	lc_ppt_out:=lc_ppt_out||cur.od_ob_ppt_id;
	
    END LOOP;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Begin of Program');
    
    SELECT TO_CHAR(SYSDATE,'MMDDYYHH24MI') INTO lc_sysdate FROM DUAL;
    
    /* File Name Defined */

    lc_file_name := 'ODPPT'||lc_sysdate||'.txt';

    -- Defect 18622 changed the file format    

    /* Header Record defined */

    lc_header := 'PPT_ID'||'|'||'Project Name'||'|'||'Testing'||'|'||'Vendor Name'||'|'||'Factory Name'||'|'||
		 'Factory Location'||'|'||'Vendor Contact Name'||'|'||'Vendor Email'||'|'||'Test Lab Name'||'|'||
		 'Test Lab Location'||'|'||
		 'Submitter'||'|'||'Approver'||'|'||'SKUID'||'|'||'SKU'||'|'||'Item Description'||'|'||'VPN'||'|'||
		 'Department'||'|'||'COO'||'|'||'TSID'||'|'||'Test Type'||'|'||'Grouping'||'|'||'Test Status Comment'||'|'||  --Adding two columns according to defect# 21498
		 'SP Contacted Vendor'||'|'||'Sample Est at Lab'||'|'||'Sample Received at SP'||'|'||'Protocol'||'|'||
		 'Report #'||'|'||'Expected Completion'||'|'||'Test Status'||'|'||
		 'Status Timestamp'||'|'||'Results'||'|'||'Completion Date'||'|'||'Defect Code'||'|'||
		 'Defect Comments'||'|'||'Previous Report #';		 


      /* Open UTL file to write the content */
 
      v_file := UTL_FILE.FOPEN( location      => lc_file_path
                               , filename     => lc_file_name
                               , open_mode    => 'w'
                               , max_linesize => 32767
                              );
                            
     /* write Header record */

     UTL_FILE.PUT_LINE( v_file , lc_header);
     
     /* open cursor for bulk collect */

     OPEN c_bv;
     FETCH c_bv BULK COLLECT INTO data_rec LIMIT 2000;
     CLOSE c_bv;

     IF data_rec.COUNT <> 0 THEN

        v_file := UTL_FILE.FOPEN( location      => lc_file_path
                                 , filename     => lc_file_name
                                 , open_mode    => 'w'
                                 , max_linesize => 32767
                                );
                            
        /* write Header record */

        UTL_FILE.PUT_LINE( v_file , lc_header);
     
        FOR i IN 1..data_rec.count
        LOOP
        
              lc_dept_number := load_dept_number(data_rec(i).od_pb_sc_dept_name); -- As Per Ver 1.4

	    lt_plan_id(i)  :=data_rec(i).plan_id;
	    lt_org_id(i)   :=data_rec(i).organization_id;
	    lt_ocr_id(i)   :=data_rec(i).occurrence;
 	    lt_test_id(i)  :=data_rec(i).od_ob_test_id;
	    lt_test_plan_id(i):=data_rec(i).test_plan_id;

            UTL_FILE.PUT_LINE( v_file ,
                            data_rec(i).od_ob_ppt_id            ||'|'||
                            data_rec(i).od_pb_project_name      ||'|'||
                            data_rec(i).od_ob_testing           ||'|'||
                            data_rec(i).od_ob_vendor_name       ||'|'||
                            data_rec(i).od_ob_factory_name      ||'|'||
                            data_rec(i).od_ob_factory_location  ||'|'||
                            data_rec(i).od_sc_vendor_contacts   ||'|'||
                            data_rec(i).od_pb_contact_email     ||'|'||
                            data_rec(i).od_pb_company           ||'|'||
                            data_rec(i).od_ob_lab_location      ||'|'||
                            data_rec(i).od_pb_auditor_name      ||'|'||
                            data_rec(i).od_pb_qa_engr_email     ||'|'||
                            data_rec(i).od_ob_pptsku_id         ||'|'||
                            DATA_REC(I).OD_OB_SKU               ||'|'||                            
                            data_rec(i).od_pb_item_desc         ||'|'||
                            data_rec(i).od_pb_vendor_vpc        ||'|'||
                            lc_dept_number                      ||'|'||   -- As Per Ver 1.4
                            data_rec(i).od_pb_country_of_origin ||'|'||
                            DATA_REC(I).OD_OB_TEST_ID           ||'|'||
                            DATA_REC(I).OD_OB_TEST_TYPE         ||'|'||
                            DATA_REC(I).OD_OB_SKU_GRP           ||'|'||   -- As Per Ver 1.4
                            DATA_REC(I).OD_PB_COMMENTS
			   );
        END LOOP;

	FORALL i IN 1 .. data_rec.LAST
	   UPDATE apps.qa_results
              SET character19='Y'
            WHERE plan_id=lt_plan_id(i)
	      AND organization_id=lt_org_id(i)
	      AND occurrence=lt_ocr_id(i);
	COMMIT;	


	FORALL i IN 1 .. data_rec.LAST
	   UPDATE apps.qa_results
              SET character9=TO_CHAR(SYSDATE,'YYYY/MM/DD')
            WHERE plan_id=lt_test_plan_id(i)
	      AND sequence3=lt_test_id(i);
	COMMIT;	

     END IF; -- IF data_rec.COUNT <> 0 THEN
    
    /*close UTL file */

     UTL_FILE.FCLOSE(v_file); 
	
    
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'End of Program');
     If lc_ppt_out IS NOT NULL THEN
	
        v_text:='List of PPTs Sent By Office Depot. Please see the details below'||chr(10);
        v_text:=v_text||lc_ppt_out||chr(10);
        v_text:=v_text||chr(10);
        v_text:=v_text||chr(10);
        v_text:=v_text||v_default;


      IF lc_send_mail='Y' THEN
	xx_qa_fqa_pkg.SEND_NOTIFICATION('List of PPTs to be Tested','cpsitclientsolution@hk.bureauveritas.com',
			'Fritz.lutzy@officedepot.com:Padmanaban.sanjeevi@officedepot.com',v_text);
      ELSE
	xx_qa_fqa_pkg.SEND_NOTIFICATION('List of PPTs to be Tested','Fritz.lutzy@officedepot.com',
			'Padmanaban.sanjeevi@officedepot.com',v_text);
      END IF;

     END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN 
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'NO DATA FOUND');
    WHEN UTL_FILE.INVALID_PATH THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File location is invalid.');
    WHEN UTL_FILE.INVALID_MODE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The open_mode parameter in FOPEN is invalid.');
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File handle is invalid.');
    WHEN UTL_FILE.INVALID_OPERATION THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'File could not be opened or operated on as requested.');
    WHEN UTL_FILE.READ_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Operating system error occurred during the read operation.');
    WHEN UTL_FILE.WRITE_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Operating system error occurred during the write operation.');
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unspecified PL/SQL error.');
    WHEN UTL_FILE.CHARSETMISMATCH THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'A file is opened using FOPEN_NCHAR, but later I/O ' ||
                                          'operations use nonchar functions such as PUTF or GET_LINE.');
    WHEN UTL_FILE.FILE_OPEN THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested operation failed because the file is open.');
    WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The MAX_LINESIZE value for FOPEN() is invalid; it should ' || 
                                          'be within the range 1 to 32767.');
    WHEN UTL_FILE.INVALID_FILENAME THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The filename parameter is invalid.');
    WHEN UTL_FILE.ACCESS_DENIED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Permission to access to the file location is denied.');
    WHEN UTL_FILE.INVALID_OFFSET THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The ABSOLUTE_OFFSET parameter for FSEEK() is invalid; ' ||
                                          'it should be greater than 0 and less than the total ' ||
                                           'number of bytes in the file.');
    WHEN UTL_FILE.DELETE_FAILED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested file delete operation failed.');
    WHEN UTL_FILE.RENAME_FAILED THEN
        UTL_FILE.FCLOSE(v_file);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The requested file rename operation failed.');
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'WHEN OTHERS RAISED :'||SQLERRM);

END XX_PPT_EXTRACT;

END XX_QA_PPT_PKG;
/
