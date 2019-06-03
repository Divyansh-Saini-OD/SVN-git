SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PSI_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PPT_PKG.pkb      	   	               |
-- | Description :  OD QA PPT Processing Pkg                           |
-- | Rice id     :  E2098                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       12-Apr-2012 Paddy Sanjeevi     Initial version           |
-- |1.1       28-Mar-2013 Saritha Mumamneni  Modified to CLOSE the file| 
-- |                                         in the exception block as |
-- |                                         per defect # 22836        |
-- |1.2       07-Jul-2013 Paddy Sanjeevi     Modified for R12          |
-- +===================================================================+
AS


PROCEDURE load_doc_stg (p_file_name IN VARCHAR2,p_report_no IN varchar2,p_psi_id varchar2)
IS

  v_bfile       BFILE;
  v_blob        BLOB;
  v_directory_name 	VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_cnt 	NUMBER:=0;

BEGIN

  -- Checks if the document is already received, if not inserts in the xx_qa_psi_docs

  SELECT COUNT(1) 
    INTO v_cnt
    FROM xx_qa_psi_docs
   WHERE psi_id=p_psi_id
     AND test_doc_name=p_file_name;
  IF v_cnt=0 THEN
     BEGIN
       INSERT 
         INTO xx_qa_psi_docs
       VALUES (p_psi_id,
  	       p_file_name,
	       p_report_no,
	      'N'
  	      );
       COMMIT;
     EXCEPTION
       WHEN others THEN
         NULL;
     END;
  END IF;

  -- Check if the document is in file system, if exists, load it in the xx_qa_psi_doc_stg table
  -- Update the process_flag='Y' for the document in xx_qa_psi_docs

  v_bfile := BFILENAME (v_directory_name, p_file_name);
  DBMS_LOB.fileopen (v_bfile, DBMS_LOB.file_readonly);

  SELECT COUNT(1)
    INTO v_cnt
    FROM xx_qa_psi_doc_stg
   WHERE psi_id=p_psi_id
     AND test_doc_name=p_file_name;

  IF v_cnt=0 THEN

     INSERT 
       INTO apps.xx_qa_psi_doc_stg
          ( test_doc_name,
	    test_document,
 	    report_no,
	    psi_id,
	    process_flag,
	    creation_date,
	    created_by
          )
     VALUES 
	 ( p_file_name,
	   EMPTY_BLOB (),
	   p_report_no,	
	   p_psi_id,	
	   'N',sysdate,-1
 	 )
     RETURN test_document
     INTO v_blob;
 
     DBMS_LOB.loadfromfile (v_blob, v_bfile, DBMS_LOB.getlength (v_bfile));
     DBMS_LOB.fileclose (v_bfile);

     UPDATE xx_qa_psi_docs
        SET process_flag='Y'
      WHERE psi_id=p_psi_id
        AND test_doc_name=p_file_name;

     COMMIT;
  END IF;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in load_doc_stg for the file :'||p_file_name||','||SQLERRM);
    DBMS_LOB.fileclose (v_bfile);  -- As per Ver 1.1
END load_doc_stg;


PROCEDURE xx_psi_load_doc
IS

  -- Cursor to get documents which are not processed from xx_qa_psi_stg table

  CURSOR C1 IS
  SELECT DISTINCT 
	 fail_notice_file,
	 report_no_file,
	 psi_id
    FROM xx_qa_psi_stg a
   WHERE process_flag=1
     AND (   fail_notice_file is not null
	  or report_no_file is not null
	 );

  -- Cursor to get documents which are not processed from xx_qa_psi_docs table
 

  CURSOR C2 IS
  SELECT test_doc_name, psi_id, report_no
    FROM xx_qa_psi_docs
   WHERE process_Flag='N';



  v_file 		VARCHAR2(50);
  v_failnotice_no	VARCHAR2(150);
  v_report_no	 	VARCHAR2(150);

  
  v_loc  	NUMBER;
  v_length 	NUMBER;
  j 		NUMBER:=1;
 
BEGIN

  -- Delete the processed documents which are older than 30 days in xx_qa_psi_doc_stg table

  DELETE
    FROM xx_qa_psi_doc_stg stg
   WHERE creation_date<sysdate-30
     AND process_Flag='Y';
  COMMIT;

  -- Delete the processed documents in xx_qa_psi_docs table

  DELETE
    FROM xx_qa_psi_docs
   WHERE process_Flag='Y';
  COMMIT;

 -- For each cursor record, check if any multiple document exists. For each document call loc_doc_stg
 -- to insert into xx_qa_psi_docs and xx_qa_psi_docs_Stg table

  FOR cur IN  c1 loop

   IF cur.report_no_file IS NOT NULL THEN

    v_loc       :=INSTR(cur.report_no_file,'^',1);
    v_report_no :=cur.report_no_file;
 
    IF v_loc>0 THEN
 
       v_length:=LENGTH(v_report_no);
 
       WHILE j <= v_length LOOP
  
         v_loc:=INSTR(v_report_no,'^',1);
      
	 IF v_loc> 0 THEN
         
            v_file:=substr(v_report_no,1,v_loc-1);
            v_report_no:=substr(v_report_no,v_loc+1);
	    load_doc_stg(v_file,cur.report_no_file,cur.psi_id);
	 ELSE
	    v_file:=v_report_no;
	    load_doc_stg(v_file,cur.report_no_file,cur.psi_id);
            EXIT;
         END IF;
	 j:=j+v_loc;
       END LOOP;
    ELSE
       load_doc_stg(cur.report_no_file,cur.report_no_file,cur.psi_id);
    END IF;

   END IF;
  END LOOP;
  COMMIT;

  j:=1;

 -- For each cursor record, check if any multiple document exists. For each document call loc_doc_stg
 -- to insert into xx_qa_psi_docs and xx_qa_psi_docs_Stg table

  FOR cur IN  c1 loop
    
   IF cur.fail_notice_file IS NOT NULL THEN

    v_loc           :=INSTR(cur.fail_notice_file,'^',1);
    v_failnotice_no :=cur.fail_notice_file;
 
    IF v_loc>0 THEN
 
       v_length:=LENGTH(v_failnotice_no);
 
       WHILE j <= v_length LOOP
  
         v_loc:=INSTR(v_failnotice_no,'^',1);
      
	 IF v_loc> 0 THEN
         
            v_file:=substr(v_failnotice_no,1,v_loc-1);
            v_failnotice_no:=substr(v_failnotice_no,v_loc+1);
	    load_doc_stg(v_file,cur.fail_notice_file,cur.psi_id);
	 ELSE
	    v_file:=v_failnotice_no;
	    load_doc_stg(v_file,cur.fail_notice_file,cur.psi_id);
            EXIT;
         END IF;
	 j:=j+v_loc;
       END LOOP;
    ELSE
       load_doc_stg(cur.fail_notice_file,cur.fail_notice_file,cur.psi_id);
    END IF;
   END IF;
  END LOOP;
  COMMIT;

 -- For each cursor record  call loc_doc_stg
 -- to insert into xx_qa_psi_docs and xx_qa_psi_docs_Stg table

 FOR cur IN  c2 loop

   load_doc_stg(cur.test_doc_name,cur.report_no,cur.psi_id);

 END LOOP;
  COMMIT;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_psi_load_doc :'||SQLERRM);
END xx_psi_load_doc;

PROCEDURE xx_psi_docs
IS

-- Cursor to get the PSI documents which are not yet processed

CURSOR C1 IS
select stg.rowid arowid,
       stg.test_doc_name,
       stg.test_document,
       stg.psi_id
  from xx_qa_psi_doc_stg stg
 where stg.process_flag='N';

-- Cursor to get the PSI documents which are not yet attached to PSI records 

 CURSOR C_attach_docs IS
 select stg.rowid arowid,
        stg.test_doc_name,
        stg.test_document,
        stg.psi_id,
	stg.doc_id,
        a.plan_id,
        b.occurrence,
        b.collection_id
  from  apps.Q_OD_OB_PSI_V b,
        apps.qa_plans a,
        xx_qa_psi_doc_stg stg
  where stg.process_flag='P'
    and a.name='OD_OB_PSI'
    and b.plan_id=a.plan_id
    and b.OD_OB_psi_ID=stg.psi_id
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

-- Cursor to get the PSI documents which are attached to PSI records 

CURSOR C_exist_docs IS
 select stg.rowid arowid,
        stg.test_doc_name,
        stg.test_document,
        stg.psi_id,
	stg.doc_id,
        a.plan_id,
        b.occurrence,
        b.collection_id
  from  apps.Q_OD_OB_PSI_V b,
        apps.qa_plans a,
        xx_qa_psi_doc_stg stg
  where stg.process_flag='P'
    and a.name='OD_OB_PSI'
    and b.plan_id=a.plan_id
    and b.OD_OB_psi_ID=stg.psi_id
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
                       and fd.file_name=stg.test_doc_name);   -- Modified for R12


  v_media_id	NUMBER;
  v_file_type   VARCHAR2(50);
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  l_rowid rowid;
  l_seq_num	NUMBER;
  v_error       VARCHAR2(2000);

BEGIN

  -- Update the documents staging table with process_flag=Y for already processed records

  FOR cur IN C_exist_docs LOOP

      UPDATE xx_qa_psi_doc_stg
         SET process_flag='Y'
       WHERE rowid=cur.arowid;

  END LOOP;
  COMMIT;

  -- For unprocessed documents, derive the file type and creates as blob in fnd_lobs

  FOR cur IN C1 LOOP

    -- For each cursor record, derive the file type
    
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

    -- For each cursor record, insert into fnd_lobs as blob

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
         UPDATE xx_qa_psi_doc_stg
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


  -- For each cursor record, creates a record in fnd_documents and attach the documents to PSI record
  
  
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
	, X_DESCRIPTION                  => cur.psi_id||','||cur.test_doc_name
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
	, X_DESCRIPTION                  => cur.psi_id||','||cur.test_doc_name
	, X_FILE_NAME                    => cur.test_doc_name
	, X_MEDIA_ID                     => cur.doc_id
   );

      UPDATE xx_qa_psi_doc_stg
         SET process_flag='Y'
       WHERE rowid=cur.arowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_psi_docs '||SQLERRM);
END xx_psi_docs;

PROCEDURE xx_psi_cap_defects
IS

-- Cursor to get all the PSI defects which are assigned to CAP Defects

CURSOR c_psi_to_capds
IS
SELECT psi.plan_id,
       psi.organization_id,
       psi.occurrence,
       psi.od_ob_psi_id psi_id,
       psd.od_pb_defect_code,
       psd.od_ob_sku,
       psd.od_pb_defect_sum,
       psi.od_ob_ref_capid cap_id,
       b.OD_SC_FACTORY_NAME,
       b.OD_PB_AUDITOR_NAME,
       b.OD_PB_QA_ENGR_EMAIL,
       b.OD_OB_VENDOR_NAME,
       b.OCCURRENCE cap_occurrence,
       b.COLLECTION_ID,
       psi.od_ob_reason    
  FROM apps.q_od_ob_cap_v b,
       apps.q_od_ob_psi_defects_v psd,
       apps.q_od_ob_psi_v psi
 WHERE psi.od_ob_ref_capid IS NOT NULL
   AND psd.od_ob_ref_psid=psi.od_ob_psi_id
   AND psd.od_ob_dsid_ref IS NULL
   AND b.OD_OB_QA_ACT='PSI'
   AND b.od_ob_qa_id=psi.od_ob_psi_id
   AND b.od_pb_car_id=psi.od_ob_ref_capid
   AND NOT EXISTS (SELECT 'x'
                     FROM apps.q_od_ob_cap_defects_v
                    WHERE OD_OB_REF_CAPID=psi.OD_OB_REF_CAPID
                      AND od_ob_qa_id=psd.od_ob_ref_psid
		      AND od_pb_defect_sum=psd.od_pb_defect_sum);

-- Cursor to get all the DS ID for the CAP Defects and update DSID in PSI Defects

CURSOR c_capds_upd
IS
SELECT psd.plan_id,
       psd.organization_id,
       psd.occurrence,
       cpd.od_ob_ds_id
  FROM apps.q_od_ob_cap_defects_v cpd,
       apps.q_od_ob_psi_defects_v psd,
       apps.q_od_ob_psi_v psi
 WHERE psi.OD_OB_REF_CAPID IS NOT NULL
   AND psd.od_ob_ref_psid=psi.od_ob_psi_id
   AND psd.od_ob_dsid_ref IS NULL
   AND cpd.od_ob_ref_capid=psi.od_ob_ref_capid
   AND cpd.od_pb_defect_sum=psd.od_pb_defect_sum
   AND cpd.od_ob_qa_id=psd.od_ob_ref_psid||'/'||TO_CHAR(psd.od_ob_sku);

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

  -- Inserting the PSI defects interface table to import CAP Defects

  FOR cur IN c_psi_to_capds LOOP
	
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
	        cur.psi_id||'/'||TO_CHAR(cur.od_ob_sku),
		cur.od_pb_defect_sum,
		cur.od_ob_reason,
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

  -- Calling the collection import to import CAP Defects

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

  -- Updating the PSI Defects with CAP DS ID

  FOR cur IN c_capds_upd LOOP

    UPDATE qa_results
       SET character6=cur.od_ob_ds_id
     WHERE plan_id=cur.plan_id
       AND organization_id=cur.organization_id
       AND occurrence=cur.occurrence;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_cap_defect '||SQLERRM);
END xx_psi_cap_defects;


PROCEDURE xx_psi_cap 
IS

-- Cursor to get all the PSI if any defects exists but CAP is not yet created

CURSOR c_psi_to_cap 
IS
SELECT DISTINCT 
       psi.plan_id,
       psi.organization_id,
       psi.od_ob_psi_id psi_id,
       psi.od_sc_region,
       psi.od_pb_vendor_name,
       psi.od_pb_factory_name,
       psi.od_pb_contact_email factory_email,
       psi.od_sc_audit_agent,
       psi.OD_PB_ODGSO_QA_ENGINEER,
       psi.OD_PB_ODC_QA_ENGINEER,
       psi.OD_PB_ART_TEST_REPORT_NUMBER
  FROM apps.q_od_ob_psi_v psi
 WHERE psi.od_ob_ref_capid IS NULL
   AND UPPER(psi.od_pb_inspection_result) like 'FAIL%'
   AND EXISTS (SELECT 'x'
		 FROM apps.q_od_ob_psi_defects_v
		WHERE od_ob_ref_psid=psi.od_ob_psi_id)
   AND NOT EXISTS (SELECT 'x'
              FROM apps.q_od_ob_cap_v
             WHERE OD_OB_QA_ACT='PSI'
                   AND od_ob_qa_id=psi.od_ob_psi_id);


-- Cursor to get all the SKU's for the PSI 

CURSOR c_psi_sku(p_psi_id VARCHAR2)
IS
SELECT distinct
       psk.od_ob_sku,
       psk.od_ob_dept_name
  FROM q_od_ob_psi_sku_v psk
 WHERE OD_OB_REF_PSID=p_psi_id
   AND EXISTS ( SELECT 'x'
	          FROM q_od_ob_psi_defects_v
		 WHERE od_ob_ref_psid=p_psi_id
	           AND od_ob_sku=psk.od_ob_sku);


-- To update PSI with CAP information, Cursor to get all the CAP Id for the PSI 

CURSOR c_cap_upd
IS
SELECT  DISTINCT 
	a.plan_id,
	a.organization_id,
	a.od_ob_psi_id psi_id,
	b.od_pb_car_id,
	b.OD_PB_QA_ENGR_EMAIL,
	b.OD_PB_AUDITOR_NAME
  FROM  apps.q_od_ob_cap_v b,
	apps.q_od_ob_psi_v a
 WHERE  a.od_ob_ref_capid IS NULL
   AND  UPPER(a.od_pb_inspection_result) like 'FAIL%'
   AND  b.od_ob_qa_act='PSI'
   AND  b.od_ob_qa_id=a.od_ob_psi_id;


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

  v_sku_list		VARCHAR2(150);
  v_dept_name		VARCHAR2(150);
BEGIN

  SELECT name INTO v_instance from v$database;

  -- Inserting the PSI information for CAP creation

  FOR cur IN c_psi_to_cap LOOP

    FOR c IN c_psi_sku(cur.psi_id) LOOP

	v_sku_list:=v_sku_list||TO_CHAR(c.od_ob_sku)||'/';
	v_dept_name:=c.od_ob_dept_name;

    END LOOP;
	
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
		cur.psi_id,
		'PSI',
		cur.od_sc_region,
		v_sku_list,
		v_dept_name,
		cur.od_pb_vendor_name,
		cur.od_pb_factory_name,
		cur.od_pb_factory_name,
		cur.factory_email,
		cur.od_sc_audit_agent,
		cur.od_pb_odgso_qa_engineer,
		cur.od_pb_odc_qa_engineer,				
		cur.od_pb_art_test_report_number,
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

  -- Calling the Collection import to import CAP information for the PSI

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

  -- Updating the PSI with CAP ID as well as sending CAP creation notification

  FOR cur IN c_cap_upd LOOP

    UPDATE qa_results
       SET character29=cur.od_pb_car_id
     WHERE plan_id=cur.plan_id
       AND organization_id=cur.organization_id
       AND character1=cur.psi_id;

    IF SQL%FOUND THEN
       v_subject :='CAP Creation Notification for '||cur.psi_id;
       v_text:='A CAP is created for the PSI. Please see the details below'||chr(10);
       v_text:=v_text||chr(10);
       v_text:=v_text||'PSI ID  :'||cur.psi_id ||chr(10);
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
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_ppt_cap '||SQLERRM);
END xx_psi_cap;


PROCEDURE XX_PSI_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
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
  v_psi_error		VARCHAR2(2000)  ;
  v_psi_sku_error	VARCHAR2(2000)  ;
  v_psi_Def_error	VARCHAR2(2000)  ;
  v_text		VARCHAR2(6000);
  v_email_list    	VARCHAR2(3000);
  v_cc_email_list	VARCHAR2(3000);
  v_subject		VARCHAR2(3000);
  v_instance		VARCHAR2(10);
  v_error_Flag		VARCHAR2(1):='N';
  v_dept_name		VARCHAR2(150);


 -- Cursor to get the PSI information from the staging table

 CURSOR C1 IS
 SELECT DISTINCT
	a.psi_id			,
        a.region			,
        a.service_provider        ,          
        a.agent                   ,           
        a.vendor_name             ,           
        a.vendor_id               ,         
	a.vendor_email  	        ,  
        a.factory_name            ,           
        a.factory_id              ,           
        a.odgso_engineer          ,           
        a.regional_engineer       ,           
        a.po_num            	,           
        a.re_inspection 		,
	a.total_units		,
	a.booking_date		,
	a.req_insp_date		,
	a.act_insp_date		,
	a.mandays			,
	a.inspector_name		,
	a.total_sample_size	,
	a.ship_date		,
	a.insp_fail_notice	,
	a.fail_notice_file	,
  	a.report_no		,
	a.report_no_file		,
	a.inspection_result	,
	a.failure_reason		,
	a.paid_by			,
	a.amount			
   FROM xx_qa_psi_stg a
  WHERE process_flag IN (1,4)
    AND NOT EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_v
		     WHERE od_ob_psi_id=a.psi_id);

 -- Cursor to get the PSI SKU information from the staging table

 CURSOR C_sku IS
 SELECT DISTINCT
	a.psi_id			,
	a.sku,
	a.vpn,
	a.sku_description,
	a.division_name,
	a.dept_no,
	a.units_ordered,
	a.sample_size,
	a.total_crt_defects,
	a.total_maj_defects,
	a.total_mnr_defects
   FROM xx_qa_psi_stg a
  WHERE process_flag IN (1,4)
    AND NOT EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_sku_v
		     WHERE od_ob_ref_psid=a.psi_id
		       AND od_ob_sku=a.sku);

 -- Cursor to get the PSI Defect information from the staging table

 CURSOR C_defect IS
 SELECT DISTINCT
	a.psi_id			,
	a.sku,
	a.failure_type,
	a.defects_count,
	a.defect_code,
	a.defect_details
   FROM xx_qa_psi_stg a
  WHERE process_flag IN (1,4)
    AND a.defect_details IS NOT NULL
    AND NOT EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_defects_v
		     WHERE od_ob_ref_psid=a.psi_id
		       AND od_ob_sku=a.sku
		       AND LTRIM(RTRIM(od_pb_defect_sum))=LTRIM(RTRIM(a.defect_details)));   -- Modified for R12
BEGIN

 -- Delete the processed records from the staging table which are more than 30 days

  DELETE 
    FROM xx_qa_psi_stg 
   WHERE process_flag=7
     AND TRUNC(creation_date)<SYSDATE-30;
  COMMIT;

  -- Processing the PSI Header Record

  FOR cur IN C1 LOOP
	
	i:=i+1;
	v_psi_error :=NULL;

        BEGIN
          INSERT INTO apps.Q_OD_OB_PSI_IV
          (     process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_PSI_ID,
		OD_SC_REGION,
		OD_PB_COMPANY,
		OD_SC_AUDIT_AGENT,
		OD_PB_VENDOR_NAME,
		OD_OB_VENDOR_NUMBER,
		OD_PB_CONTACT_EMAIL,
		OD_PB_FACTORY_NAME,
		OD_PB_FACTORY_ID,
		OD_PB_ODGSO_QA_ENGINEER,
		OD_PB_ODC_QA_ENGINEER,
		OD_PB_PO_NUM,
		OD_PB_ATTACHMENT,
		OD_OB_SALE_UNITS,
		OD_SC_SCHEDULED_DATE,
		OD_SC_INIT_INSPECTION_DATE,
		OD_SC_INSPECT_DATE,
		OD_PB_MAN_DAYS,
		OD_OB_INSPECTOR,
		OD_PB_SAMPLE_SIZE,
		OD_PB_SHIP_BOOKING_ENTRY_DATE,
		OD_PB_REPORT_NAME,
		OD_PB_REPORT_NUMBER,
		OD_PB_ART_TEST_REPORT_NUMBER,
		OD_PB_ORIGINAL_REPORT_NUMBER,
		OD_PB_INSPECTION_RESULT,
		OD_OB_REASON,
		OD_PB_PAID_BY,
		OD_SC_PAY_AMOUNT,
	        qa_created_by_name,
                qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_PSI',
               '1', --1 for INSERT
               'OD_OB_PSI_ID',
		cur.psi_id,
		cur.region,
		cur.service_provider,
		cur.agent,
		cur.vendor_name,
		cur.vendor_id,
		cur.vendor_email,
		cur.factory_name,
		cur.factory_id,
		cur.odgso_engineer,
		cur.regional_engineer,
		cur.po_num,
		cur.re_inspection,
		cur.total_units,
		TO_CHAR(cur.booking_date,'DD-MON-YYYY'),
		TO_CHAR(cur.req_insp_date,'DD-MON-YYYY'),
		TO_CHAR(cur.act_insp_date,'DD-MON-YYYY'),
		cur.mandays,
		cur.inspector_name,
		cur.total_sample_size,
		TO_CHAR(cur.ship_date,'DD-MON-YYYY'),	
		cur.insp_fail_notice	,
		cur.fail_notice_file	,
  		cur.report_no		,
		cur.report_no_file		,
		cur.inspection_result,
		cur.failure_reason,
		cur.paid_by,
		cur.amount,			
     	        fnd_global.user_name,
		fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
           v_psi_error:=sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_PPT_TEST_STATUS_IV'||v_psi_error);
       END;
  END LOOP;
 

  -- Processing PSI SKU Information


  FOR cur IN c_sku LOOP

	i:=i+1;
	v_psi_sku_error :=NULL;

	BEGIN
	  SELECT SUBSTR(b.description,1,150)
	    INTO v_dept_name
	    FROM fnd_flex_values_vl b,
	         fnd_flex_value_sets a
	   WHERE a.flex_value_set_name='XX_GI_DEPARTMENT_VS'
	     AND b.flex_value_set_id=a.flex_value_set_id
	     AND b.flex_value=cur.dept_no;
        EXCEPTION
	  WHEN others THEN
	    v_dept_name:=NULL;
	END;

        BEGIN
          INSERT INTO apps.Q_OD_OB_PSI_SKU_IV
          (     process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_REF_PSID,
		OD_OB_SKU,
		OD_PB_ITEM_DESC,
		OD_PB_VENDOR_VPC,
		OD_PB_DIVISION,
		OD_PB_DEPARTMENT,
		OD_OB_DEPT_NAME,
		OD_PB_SAMPLE_SIZE,
		OD_OB_SALE_UNITS,
		OD_OB_QC_DEFECTS,
		OD_OB_FQC_DEFECTS,
		OD_OB_IQC_DEFECTS,
	        qa_created_by_name,
                qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_PSI_SKU',
               '1', --1 for INSERT
               'OD_OB_PSI_ID,OD_OB_SKU',
		cur.psi_id,
		cur.sku,
		cur.sku_description,
		cur.vpn,
		cur.division_name,
		cur.dept_no,
		v_dept_name,
		cur.sample_size,
		cur.units_ordered,
		cur.total_crt_defects,
		cur.total_maj_defects,
		cur.total_mnr_defects,
     	        fnd_global.user_name,
		fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
           v_psi_sku_error:=sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_PPT_TEST_STATUS_IV'||v_psi_sku_error);
       END;
  END LOOP;


  -- Processing the PSI SKU Defects Records

  FOR cur IN C_defect LOOP
	
	i:=i+1;
	v_psi_def_error :=NULL;

        BEGIN
          INSERT INTO apps.Q_OD_OB_PSI_DEFECTS_IV
          (     process_status, 
                organization_code ,
                plan_name,
                insert_type,
	        matching_elements,
		OD_OB_REF_PSID,
	        OD_OB_SKU,
		OD_PB_FAILURE_CODES,
		OD_OB_QC_DEFECTS,
		OD_PB_DEFECT_CODE,
		OD_PB_DEFECT_SUM,
	        qa_created_by_name,
                qa_last_updated_by_name
          )
         VALUES
	  (
 	       '1',
               'PRJ',
               'OD_OB_PSI_DEFECTS',
               '1', --1 for INSERT
               'OD_OB_PSI_ID,OD_OB_SKU,OD_PB_DEFECT_SUM',
		cur.psi_id,
		cur.sku,
		cur.failure_type,
		cur.defects_count,
		cur.defect_code,
		cur.defect_details,
     	        fnd_global.user_name,
		fnd_global.user_name
	  );
       EXCEPTION
         WHEN others THEN
           v_psi_def_error:=sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in inserting Q_OD_OB_PPT_TEST_STATUS_IV'||v_psi_def_error);
       END;
  END LOOP;

 
  -- Wait for the completion of collection import

  IF i>0 THEN
                
     v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
		'500','1',TO_CHAR(V_user_id),'No');
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

  --  Update the staging table with defects_cr_Flag='Y' if the defects are created

  UPDATE xx_qa_psi_stg a
     SET defects_cr_flag='Y'
   WHERE PROCESS_FLAG IN (1,4)
     AND EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_defects_v
		     WHERE od_ob_ref_psid=a.psi_id
		       AND od_ob_sku=a.sku
		       AND od_pb_defect_sum=a.defect_details);

  --  Update the staging table with sku_cr_Flag='Y' if the SKU's are created

  UPDATE xx_qa_psi_stg a
     SET sku_cr_flag='Y'
   WHERE PROCESS_FLAG IN (1,4)
     AND EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_sku_v
		     WHERE od_ob_ref_psid=a.psi_id
		       AND od_ob_sku=a.sku);

  --  Update the staging table with psi_cr_Flag='Y' if the PSI's are created

  UPDATE xx_qa_psi_stg a
     SET psi_cr_flag='Y'
   WHERE PROCESS_FLAG IN (1,4)
     AND EXISTS (SELECT 'X'
		      FROM q_od_ob_psi_v
		     WHERE od_ob_psi_id=a.psi_id);

   COMMIT;

  -- Call to create CAP if any defects for PSI
 
   xx_psi_cap;

  -- Call to create CAP Defects if any defects for PSI, once the CAP is created

   xx_psi_cap_defects;

  -- Call to load the PSI Documents received from vendor

   xx_psi_load_doc;

  -- Call to attach documents at PSI level 

   xx_psi_docs;

  -- Update staging table with process_Flag=7,if all the sku,defect and PSI's are created


  UPDATE xx_qa_psi_stg a
     SET process_flag=7
   WHERE PROCESS_FLAG IN (1,4)
     AND psi_cr_flag='Y'
     AND sku_cr_Flag='Y'
     AND defects_cr_flag='Y';

  -- Update staging table with process_Flag=4,if either  the sku,defect/ PSI's are not created


  UPDATE xx_qa_psi_stg a
     SET process_flag=4
   WHERE PROCESS_FLAG=1
     AND (    psi_cr_flag='N'
          OR  sku_cr_Flag='N'
          OR defects_cr_flag='N'
	 );

   COMMIT;

EXCEPTION
  WHEN others THEN
    COMMIT;
    v_errbuf:='Error in When others :'||SQLERRM;
    v_retcode:=SQLCODE;
END XX_PSI_PROCESS;

END XX_QA_PSI_PKG;
/
