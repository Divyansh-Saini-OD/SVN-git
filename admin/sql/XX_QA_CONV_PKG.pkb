SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_CONV_PKG
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
PROCEDURE OD_PB_CUSTCOM_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMER_COMPLAINTS_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS__V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMER_COMPLAINTS_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
  v_ltx NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));

EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CUSTCOM_HIS_DOC;

PROCEDURE OD_PB_FAI_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FIRST_ARTICLE_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FIRST_ARTICLE_HISTOR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FIRST_ARTICLE_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_FAI_HIS_DOC;

PROCEDURE OD_PB_REGFEE_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_REG_FEES_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_REG_FEES_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_REG_FEES_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_REG_FEES_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_REG_FEES_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_REG_FEES_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_REGFEE_HIS_DOC;

PROCEDURE OD_PB_SPECAPR_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_SPEC_APPROVAL_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_SPEC_APPROVAL_HISTOR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_SPEC_APPROVAL_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_SPECAPR_HIS_DOC;

PROCEDURE OD_PB_FQA_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_FQA_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_FQA_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_FQA_HIS_DOC;

PROCEDURE OD_PB_PREPUR_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PRE_PURCHASE_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PRE_PURCHASE_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PRE_PURCHASE_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PRE_PURCHASE_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PRE_PURCHASE_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PRE_PURCHASE_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PREPUR_HIS_DOC;

PROCEDURE OD_PB_ECR_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_ECR_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ECR_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ECR_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_ECR_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ECR_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ECR_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
  v_ltx NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));

EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_ECR_HIS_DOC;

PROCEDURE OD_PB_PSI_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PSI_IC_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PSI_IC_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PSI_IC_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PSI_IC_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PSI_IC_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PSI_IC_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PSI_HIS_DOC;

PROCEDURE OD_PB_TESTING_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_TESTING_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_TESTING_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_TESTING_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_TESTING_HIST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_TESTING_HIST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_TESTING_HIST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_TESTING_HIS_DOC;

PROCEDURE OD_PB_PROLOG_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PROCEDURES_LOG_HISTO_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PROCEDURES_LOG_HISTO_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PROCEDURES_LOG_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

 

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PROLOG_HIS_DOC;

PROCEDURE OD_PB_CA_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.od_pb_car_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_CA_REQUEST_HISTORY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CA_REQUEST_HISTORY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CA_REQUEST_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

 CURSOR C2 IS
  select a.name,b.collection_id,b.od_pb_car_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_CA_REQUEST_HISTORY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CA_REQUEST_HISTORY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CA_REQUEST_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;


   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

 

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CA_HIS_DOC;

PROCEDURE OD_PB_ATS_HIS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.od_pb_ats_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_ATS_HISTORY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ATS_HISTORY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ATS_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

 CURSOR C2 IS
  select a.name,b.collection_id,b.od_pb_ats_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_ATS_HISTORY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ATS_HISTORY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ATS_HISTORY'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;


   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

 

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_ATS_HIS_DOC;

PROCEDURE OD_PB_SPEC_APR_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_SPEC_APPROVAL_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_SPEC_APPROVAL_V b,
         apps.qa_plans a
  where  a.name='OD_PB_SPEC_APPROVAL'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_SPEC_APPROVAL_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_SPEC_APPROVAL_V b,
         apps.qa_plans a
  where  a.name='OD_PB_SPEC_APPROVAL'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_SPEC_APR_DOC;

PROCEDURE OD_PB_FAI_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FIRST_ARTICLE_INSPECTION'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FIRST_ARTICLE_INSPEC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FIRST_ARTICLE_INSPECTION'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_FAI_DOC;

PROCEDURE OD_PB_FQA_US_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_FQA_US_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_US_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA_US'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_FQA_US_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_US_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA_US'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_FQA_US_DOC;


PROCEDURE OD_PB_PROC_LOG_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PROCEDURES_LOG_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PROCEDURES_LOG_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PROCEDURES_LOG'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PROCEDURES_LOG_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PROCEDURES_LOG_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PROCEDURES_LOG'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PROC_LOG_DOC;

PROCEDURE OD_PB_RET_GOODS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_RETURNED_GOODS_ANALY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_RETURNED_GOODS_ANALY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_RETURNED_GOODS_ANALYSIS'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_RETURNED_GOODS_ANALY_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_RETURNED_GOODS_ANALY_V b,
         apps.qa_plans a
  where  a.name='OD_PB_RETURNED_GOODS_ANALYSIS'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_RET_GOODS_DOC;


PROCEDURE OD_PB_QA_REPORT_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_QA_REPORTING_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_QA_REPORTING_V b,
         apps.qa_plans a
  where  a.name='OD_PB_QA_REPORTING'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_QA_REPORTING_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_QA_REPORTING_V b,
         apps.qa_plans a
  where  a.name='OD_PB_QA_REPORTING'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_QA_REPORT_DOC;

PROCEDURE OD_PB_PROT_REV_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PROTOCOL_REVIEW_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PROTOCOL_REVIEW_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PROTOCOL_REVIEW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PROTOCOL_REVIEW_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PROTOCOL_REVIEW_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PROTOCOL_REVIEW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PROT_REV_DOC;

PROCEDURE OD_PB_CAP_APPRV_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PPT_CAP_APPROVAL_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PPT_CAP_APPROVAL_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PPT_CAP_APPROVAL'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PPT_CAP_APPROVAL_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PPT_CAP_APPROVAL_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PPT_CAP_APPROVAL'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CAP_APPRV_DOC;



PROCEDURE OD_PB_HOUSE_ART_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_IHR_NUMBER,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V b,
         apps.qa_plans a
  where  a.name='OD_PB_IN_HOUSE_ARTWORK_REVIEW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_IHR_NUMBER,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_IN_HOUSE_ARTWORK_REV_V b,
         apps.qa_plans a
  where  a.name='OD_PB_IN_HOUSE_ARTWORK_REVIEW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_HOUSE_ART_DOC;


PROCEDURE OD_PB_FQA_ODC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_FQA_ID_ODC,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_FQA_ODC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_ODC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA_ODC'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_FQA_ID_ODC,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_FQA_ODC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_FQA_ODC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_FQA_ODC'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_FQA_ODC;

PROCEDURE OD_PB_WITHDRAW_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_WITHDRAW_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_WITHDRAW_V b,
         apps.qa_plans a
  where  a.name='OD_PB_WITHDRAW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_WITHDRAW_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_WITHDRAW_V b,
         apps.qa_plans a
  where  a.name='OD_PB_WITHDRAW'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_WITHDRAW_DOC;


PROCEDURE OD_PB_TESTING_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_RECORD_ID,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_TESTING_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_TESTING_V b,
         apps.qa_plans a
  where  a.name='OD_PB_TESTING'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_RECORD_ID,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_TESTING_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_TESTING_V b,
         apps.qa_plans a
  where  a.name='OD_PB_TESTING'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
  v_ltx NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));

EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_TESTING_DOC;

PROCEDURE OD_PB_REG_CERT_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_REGISTRATION_ID,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_REGULATORY_CERT_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_REGULATORY_CERT_V b,
         apps.qa_plans a
  where  a.name='OD_PB_REGULATORY_CERT'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_REGISTRATION_ID,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_REGULATORY_CERT_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_REGULATORY_CERT_V b,
         apps.qa_plans a
  where  a.name='OD_PB_REGULATORY_CERT'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_REG_CERT_DOC;

PROCEDURE OD_PB_PSI_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_PSI_ID,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PSI_IC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PSI_IC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PSI_IC'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_PSI_ID,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PSI_IC_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PSI_IC_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PSI_IC'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PSI_DOC;

PROCEDURE OD_PB_PRE_PUR_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_PRE_PURCHASE_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PRE_PURCHASE_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PRE_PURCHASE'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_PRE_PURCHASE_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_PRE_PURCHASE_V b,
         apps.qa_plans a
  where  a.name='OD_PB_PRE_PURCHASE'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_PRE_PUR_DOC;

PROCEDURE OD_PB_ECR_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_ECR_ID,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_ECR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ECR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ECR'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_ECR_ID,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_ECR_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_ECR_V b,
         apps.qa_plans a
  where  a.name='OD_PB_ECR'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_ECR_DOC;

PROCEDURE OD_PB_CUST_COMP_EU_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_CUSTOMER_COMPLAINT_ID_EU,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMERCOMPLAINTS_EU'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_CUSTOMER_COMPLAINT_ID_EU,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMERCOMPLAINTS_E_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMERCOMPLAINTS_EU'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CUST_COMP_EU_DOC;

PROCEDURE OD_PB_CUST_COMP_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.OD_PB_CUSTOMER_COMPLAINT_ID,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMER_COMPLAINTS'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.OD_PB_CUSTOMER_COMPLAINT_ID,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CUSTOMER_COMPLAINTS_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CUSTOMER_COMPLAINTS'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CUST_COMP_DOC;


PROCEDURE OD_PB_CA_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.od_pb_car_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_CA_REQUEST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CA_REQUEST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CA_REQUEST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;

  CURSOR C2 IS
  select a.name,b.collection_id,b.od_pb_car_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_CA_REQUEST_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_CA_REQUEST_V b,
         apps.qa_plans a
  where  a.name='OD_PB_CA_REQUEST'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_CA_DOC;

PROCEDURE OD_PB_ATS_EU_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.od_pb_ats_id_eu,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V b,
         apps.qa_plans a
  where  a.name='OD_PB_AUTHORIZATIONTO_SHIP_EU'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;


   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  CURSOR C2 IS
  select a.name,b.collection_id,b.od_pb_ats_id_eu,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_AUTHORIZATIONTO_SHIP_V b,
         apps.qa_plans a
  where  a.name='OD_PB_AUTHORIZATIONTO_SHIP_EU'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_ATS_EU_DOC;

PROCEDURE OD_PB_ATS_DOC IS
  CURSOR C1 IS
  select a.name,b.collection_id,b.od_pb_ats_id,b.occurrence,b.plan_id,
         fdd.datatype_id,fd.category_id,fd.creation_date fdcdate,fd.last_update_date fdldate,
         fad.seq_num,fdt.media_id,fdd.user_name,
         fdt.description,fdt.short_text,fdt.file_name,
         fad.entity_name
   from  apps.fnd_documents@gsiprd01.na.odcorp.net fd,
         apps.fnd_documents_tl@gsiprd01.na.odcorp.net fdt,
         apps.fnd_document_datatypes@gsiprd01.na.odcorp.net fdd,
         apps.FND_ATTACHED_DOCUMENTS@gsiprd01.na.odcorp.net fad,
         apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V b,
         apps.qa_plans a
  where  a.name='OD_PB_AUTHORIZATION_TO_SHIP'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and  fd.document_id = fdt.document_id
    and  fd.datatype_id = fdd.datatype_id
    and  fdd.user_name='File'  
    and  fd.document_id = fad.document_id
    and  fdd.language = 'US'
    and  fad.entity_name = 'QA_RESULTS'
    and  fad.pk3_value = pqr.plan_id
    and  fad.pk2_value = pqr.collection_id
    and  fad.pk1_value = pqr.occurrence
  order by od_pb_legacy_rec_id, fad.seq_num;


   CURSOR fnd_lobs_cur (mid NUMBER) IS
   SELECT file_id,
          file_name,
          file_content_type,
          upload_date,
          expiration_date,
          program_name,
          program_tag,
          file_data,
          language,
          oracle_charset,
          file_format
     FROM xxmer.xx_qa_fnd_lobs
    WHERE file_id =mid;

  CURSOR C2 IS
  select a.name,b.collection_id,b.od_pb_ats_id,b.occurrence,b.plan_id,
      fvl.seq_num,fvl.creation_date fdcdate,fvl.last_update_date fdldate,
     fvl.datatype_id,fvl.document_description,fvl.media_id,fst.short_text
   from  apps.FND_DOCUMENTS_SHORT_TEXT@gsiprd01.na.odcorp.net fst,
     apps.fnd_attached_docs_form_vl@gsiprd01.na.odcorp.net fvl,
         apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V@gsiprd01.na.odcorp.net pqr,
         apps.qa_plans@gsiprd01.na.odcorp.net ppl,
         apps.Q_OD_PB_AUTHORIZATION_TO_SHI_V b,
         apps.qa_plans a
  where  a.name='OD_PB_AUTHORIZATION_TO_SHIP'
    and  b.plan_id=a.plan_id
    and  ppl.name=a.name
    and  pqr.plan_id=ppl.plan_id
    and  b.od_pb_legacy_col_id=pqr.collection_id
    and  b.od_pb_legacy_ocr_id=pqr.occurrence
    and fvl.pk1_value=pqr.occurrence
    and fvl.pk2_value=pqr.collection_id
    and fvl.pk3_value=pqr.plan_id
    and fvl.datatype_id in (1)
    and fvl.entity_name='QA_RESULTS'
    and fvl.function_name='QAPLMDF'
    and fst.media_id=fvl.media_id
  order by od_pb_legacy_rec_id, fvl.seq_num;

  fnd_lobs_rec fnd_lobs_cur%ROWTYPE;
  v_media_id	NUMBER;
  l_rowid rowid;
  l_attached_document_id number;
  l_document_id number;
  l_category_id number := 1;
  v_ctr NUMBER:=0;
  v_shr NUMBER:=0;
BEGIN
  FOR CUR IN C1 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    OPEN  fnd_lobs_cur(cur.media_id);
    FETCH fnd_lobs_cur
    INTO  fnd_lobs_rec.file_id,
          fnd_lobs_rec.file_name,
          fnd_lobs_rec.file_content_type,
          fnd_lobs_rec.upload_date,
          fnd_lobs_rec.expiration_date,
          fnd_lobs_rec.program_name,
          fnd_lobs_rec.program_tag,
          fnd_lobs_rec.file_data,
          fnd_lobs_rec.language,
          fnd_lobs_rec.oracle_charset,
          fnd_lobs_rec.file_format;
    CLOSE fnd_lobs_cur;

    SELECT fnd_lobs_s.nextval INTO v_media_id FROM dual;
    BEGIN
      INSERT INTO fnd_lobs (
                        file_id,
                        file_name,
                        file_content_type,
                        upload_date,
                        expiration_date,
                        program_name,
                        program_tag,
                        file_data,
                        language,
                        oracle_charset,
                        file_format)
      VALUES  (
                       v_media_id,
                       fnd_lobs_rec.file_name,
                       fnd_lobs_rec.file_content_type,
                       fnd_lobs_rec.upload_date,
                       fnd_lobs_rec.expiration_date,
                       fnd_lobs_rec.program_name,
                       fnd_lobs_rec.program_tag,
                       fnd_lobs_rec.file_data,
                       fnd_lobs_rec.language,
                       fnd_lobs_rec.oracle_charset,
                       fnd_lobs_rec.file_format);
    EXCEPTION
      WHEN others THEN
        dbms_output.put_line(sqlerrm);
    END;

    fnd_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdldate
	, X_LAST_UPDATED_BY              => 33963
	, X_DATATYPE_ID                  => 6 -- File
	, X_CATEGORY_ID                  => l_category_id
	, X_SECURITY_TYPE                => 2
	, X_PUBLISH_FLAG                 => 'Y'
	, X_USAGE_TYPE                   => 'O'
	, X_LANGUAGE                     => 'US'
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
       );

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    fnd_attached_documents_pkg.insert_row
	( X_ROWID                        => l_rowid
	, X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
	, X_DOCUMENT_ID                  => l_document_id
	, X_CREATION_DATE                => cur.fdcdate
	, X_CREATED_BY                   => 33963
	, X_LAST_UPDATE_DATE             => cur.fdcdate
	, X_LAST_UPDATED_BY              => 33963
	, X_LAST_UPDATE_LOGIN            => 33963
	, X_SEQ_NUM                      => cur.seq_num
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
	, X_DESCRIPTION                  => cur.description
	, X_FILE_NAME                    => cur.file_name
	, X_MEDIA_ID                     => v_media_id
   );
    v_ctr:=v_ctr+1;
  END LOOP;
  dbms_output.put_line('Total Documents:'||to_char(v_Ctr));

-- Migrating Short text

  FOR CUR IN C2 LOOP

    l_document_id:=NULL;
    l_attached_document_id:=NULL;
    v_media_id:=NULL;

    select apps.fnd_documents_short_text_s.NEXTVAL 
      INTO v_media_id
      from dual;

    SELECT fnd_documents_s.nextval
      INTO l_document_id
      FROM dual;

    BEGIN
      INSERT INTO apps.fnd_documents_short_text 
	(media_id, short_text ) 
      VALUES 
	(v_media_id,cur.short_text); 
    EXCEPTION
      WHEN others THEN
	dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents 
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	datatype_id, 
	category_id, 
	security_type, 
	publish_flag, 
	usage_type 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	cur.datatype_id, 
	l_category_id,  
	1, 
	'Y', -- Publish_flag 
	'O' -- Usage_type of 'One Time' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

    BEGIN
      INSERT INTO apps.fnd_documents_tl
	(document_id, 
	creation_date, 
	created_by, 
	last_update_date, 
	last_updated_by, 
	language, 
	description, 
	media_id,
	source_lang 
	) 
	VALUES 
	(l_document_id, 
	cur.fdcdate, 
	33963, 
	cur.fdldate, 
	33963, 
	'US', -- language 
	cur.document_description, -- description 
	v_media_id, -- media_id
	'US' 
	); 
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;

   select FND_ATTACHED_DOCUMENTS_S.nextval 
     into l_attached_document_id
     from dual;

    BEGIN
      INSERT INTO apps.fnd_attached_documents
	(attached_document_id, 
	 document_id, 
	 creation_date, 
	 created_by, 
	 last_update_date, 
	 last_updated_by, 
	 category_id,
	 seq_num, 
	 entity_name, 
	 pk1_value, 
	 pk2_value, 
	 pk3_value, 
	 automatically_added_flag 
	) 
      VALUES
	(l_attached_document_id,
	 l_document_id,
  	 cur.fdcdate, 
 	 33963, 
	 cur.fdldate, 
	 33963, 	 
	 1,
	 cur.seq_num,
	 'QA_RESULTS',
	 cur.occurrence,
	 cur.collection_id,
	 cur.plan_id,
	 'N');
    EXCEPTION
      WHEN otherS THEN
        dbms_output.put_line(sqlerrm);
    END;
    v_shr:=v_shr+1;
  END LOOP;
  dbms_output.put_line('Total Short Text:'||to_char(v_shr));
EXCEPTION
  WHEN others THEN 
    dbms_output.put_line(sqlerrm); 
END OD_PB_ATS_DOC;

END XX_QA_CONV_PKG;
/
