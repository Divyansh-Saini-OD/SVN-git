-- $Id$
-- $Rev$
-- $HeadURL$
-- $Date$
-- $Author$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XXSCS_SIT_TO_PRF_DATA_CPY
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXSCS_SIT_TO_PRF_DATA_CPY.pkb                      |
-- | Description :  Package to Copy Data From SIT To PRF               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Apr-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+

AS
  
   PROCEDURE copy_data
  (
    x_errbuf                 OUT VARCHAR2,
    x_retcode                OUT VARCHAR2,
    p_db_link                IN  VARCHAR2
  ) AS
  l_sql                   VARCHAR2(2000);
  TYPE l_data_cur_type    IS REF CURSOR;
  l_data_cur              l_data_cur_type;
  l_fdbk_hdr_rec          XXSCS_FDBK_HDR_STG%ROWTYPE;
  l_fdbk_lin_rec          XXSCS_FDBK_LINE_DTL_STG%ROWTYPE;
  l_fdbk_qstn_rec         XXSCS_FDBK_QSTN_STG%ROWTYPE;
  l_fdbk_resp_rec         XXSCS_FDBK_RESP_STG%ROWTYPE;
  l_commit_counter        NUMBER  :=  0;
  BEGIN
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_FDBK_HDR_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_FDBK_HDR_STG';
    
    fnd_file.put_line(fnd_file.log, 'TRUNCATE on Table XXSCS_FDBK_HDR_STG COMPLETE');
    fnd_file.put_line(fnd_file.log, 'Inserting Data Into Table XXSCS_FDBK_HDR_STG ......... ');
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_fdbk_hdr_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_FDBK_HDR_STG
      (
          FDBK_ID,
          CUSTOMER_ACCOUNT_ID,
          ADDRESS_ID,
          PARTY_SITE_ID,
          PARTY_ID,
          MASS_APPLY_FLAG,
          CONTACT_ID,
          LAST_UPDATED_EMP,
          SALES_TERRITORY_ID,
          RESOURCE_ID,
          ROLE_ID,
          GROUP_ID,
          LANGUAGE,
          SOURCE_LANG,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN,
          REQUEST_ID,
          PROGRAM_APPLICATION_ID,
          PROGRAM_ID,
          PROGRAM_UPDATE_DATE,
          ATTRIBUTE_CATEGORY,
          ATTRIBUTE1,
          ATTRIBUTE2,
          ATTRIBUTE3,
          ATTRIBUTE4,
          ATTRIBUTE5,
          ATTRIBUTE6,
          ATTRIBUTE7,
          ATTRIBUTE8,
          ATTRIBUTE9,
          ATTRIBUTE10,
          ATTRIBUTE11,
          ATTRIBUTE12,
          ATTRIBUTE13,
          ATTRIBUTE14,
          ATTRIBUTE15,
          ATTRIBUTE16,
          ATTRIBUTE17,
          ATTRIBUTE18,
          ATTRIBUTE19,
          ATTRIBUTE20,
          ENTITY_ID,
          ENTITY_TYPE
        )
        VALUES
        (
          l_fdbk_hdr_rec.FDBK_ID,
          l_fdbk_hdr_rec.CUSTOMER_ACCOUNT_ID,
          l_fdbk_hdr_rec.ADDRESS_ID,
          l_fdbk_hdr_rec.PARTY_SITE_ID,
          l_fdbk_hdr_rec.PARTY_ID,
          l_fdbk_hdr_rec.MASS_APPLY_FLAG,
          l_fdbk_hdr_rec.CONTACT_ID,
          l_fdbk_hdr_rec.LAST_UPDATED_EMP,
          l_fdbk_hdr_rec.SALES_TERRITORY_ID,
          l_fdbk_hdr_rec.RESOURCE_ID,
          l_fdbk_hdr_rec.ROLE_ID,
          l_fdbk_hdr_rec.GROUP_ID,
          l_fdbk_hdr_rec.LANGUAGE,
          l_fdbk_hdr_rec.SOURCE_LANG,
          l_fdbk_hdr_rec.CREATED_BY,
          l_fdbk_hdr_rec.CREATION_DATE,
          l_fdbk_hdr_rec.LAST_UPDATED_BY,
          l_fdbk_hdr_rec.LAST_UPDATE_DATE,
          l_fdbk_hdr_rec.LAST_UPDATE_LOGIN,
          l_fdbk_hdr_rec.REQUEST_ID,
          l_fdbk_hdr_rec.PROGRAM_APPLICATION_ID,
          l_fdbk_hdr_rec.PROGRAM_ID,
          l_fdbk_hdr_rec.PROGRAM_UPDATE_DATE,
          l_fdbk_hdr_rec.ATTRIBUTE_CATEGORY,
          l_fdbk_hdr_rec.ATTRIBUTE1,
          l_fdbk_hdr_rec.ATTRIBUTE2,
          l_fdbk_hdr_rec.ATTRIBUTE3,
          l_fdbk_hdr_rec.ATTRIBUTE4,
          l_fdbk_hdr_rec.ATTRIBUTE5,
          l_fdbk_hdr_rec.ATTRIBUTE6,
          l_fdbk_hdr_rec.ATTRIBUTE7,
          l_fdbk_hdr_rec.ATTRIBUTE8,
          l_fdbk_hdr_rec.ATTRIBUTE9,
          l_fdbk_hdr_rec.ATTRIBUTE10,
          l_fdbk_hdr_rec.ATTRIBUTE11,
          l_fdbk_hdr_rec.ATTRIBUTE12,
          l_fdbk_hdr_rec.ATTRIBUTE13,
          l_fdbk_hdr_rec.ATTRIBUTE14,
          l_fdbk_hdr_rec.ATTRIBUTE15,
          l_fdbk_hdr_rec.ATTRIBUTE16,
          l_fdbk_hdr_rec.ATTRIBUTE17,
          l_fdbk_hdr_rec.ATTRIBUTE18,
          l_fdbk_hdr_rec.ATTRIBUTE19,
          l_fdbk_hdr_rec.ATTRIBUTE20,
          l_fdbk_hdr_rec.ENTITY_ID,
          l_fdbk_hdr_rec.ENTITY_TYPE
        );
        
        l_commit_counter    := l_commit_counter + 1;
        
        IF mod(l_commit_counter, 500) = 0 THEN
           COMMIT;
        END IF;
    
    END LOOP;    
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_FDBK_HDR_STG COMPLETE >> Total Rows Inserted : ' || l_commit_counter);
    
    l_commit_counter := 0;
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_FDBK_LINE_DTL_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_FDBK_LINE_DTL_STG';
    
    fnd_file.put_line(fnd_file.log, 'TRUNCATE on Table XXSCS_FDBK_LINE_DTL_STG COMPLETE');
    fnd_file.put_line(fnd_file.log, 'Inserting Data Into Table XXSCS_FDBK_LINE_DTL_STG ......... ');
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_fdbk_lin_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_FDBK_LINE_DTL_STG
      (
        FDBK_LINE_ID,
        FDBK_ID,
        FDK_CODE,
        FDK_VALUE,
        FDK_TXT,
        FDK_DATE,
        FDK_PICK_VALUE,
        LAST_UPDATED_EMP,
        LANGUAGE,
        SOURCE_LANG,
        CREATED_BY,
        CREATION_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATE_LOGIN,
        REQUEST_ID,
        PROGRAM_APPLICATION_ID,
        PROGRAM_ID,
        PROGRAM_UPDATE_DATE,
        ATTRIBUTE_CATEGORY,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        ATTRIBUTE16,
        ATTRIBUTE17,
        ATTRIBUTE18,
        ATTRIBUTE19,
        ATTRIBUTE20
      )
      VALUES
      (
        l_fdbk_lin_rec.FDBK_LINE_ID,
        l_fdbk_lin_rec.FDBK_ID,
        l_fdbk_lin_rec.FDK_CODE,
        l_fdbk_lin_rec.FDK_VALUE,
        l_fdbk_lin_rec.FDK_TXT,
        l_fdbk_lin_rec.FDK_DATE,
        l_fdbk_lin_rec.FDK_PICK_VALUE,
        l_fdbk_lin_rec.LAST_UPDATED_EMP,
        l_fdbk_lin_rec.LANGUAGE,
        l_fdbk_lin_rec.SOURCE_LANG,
        l_fdbk_lin_rec.CREATED_BY,
        l_fdbk_lin_rec.CREATION_DATE,
        l_fdbk_lin_rec.LAST_UPDATED_BY,
        l_fdbk_lin_rec.LAST_UPDATE_DATE,
        l_fdbk_lin_rec.LAST_UPDATE_LOGIN,
        l_fdbk_lin_rec.REQUEST_ID,
        l_fdbk_lin_rec.PROGRAM_APPLICATION_ID,
        l_fdbk_lin_rec.PROGRAM_ID,
        l_fdbk_lin_rec.PROGRAM_UPDATE_DATE,
        l_fdbk_lin_rec.ATTRIBUTE_CATEGORY,
        l_fdbk_lin_rec.ATTRIBUTE1,
        l_fdbk_lin_rec.ATTRIBUTE2,
        l_fdbk_lin_rec.ATTRIBUTE3,
        l_fdbk_lin_rec.ATTRIBUTE4,
        l_fdbk_lin_rec.ATTRIBUTE5,
        l_fdbk_lin_rec.ATTRIBUTE6,
        l_fdbk_lin_rec.ATTRIBUTE7,
        l_fdbk_lin_rec.ATTRIBUTE8,
        l_fdbk_lin_rec.ATTRIBUTE9,
        l_fdbk_lin_rec.ATTRIBUTE10,
        l_fdbk_lin_rec.ATTRIBUTE11,
        l_fdbk_lin_rec.ATTRIBUTE12,
        l_fdbk_lin_rec.ATTRIBUTE13,
        l_fdbk_lin_rec.ATTRIBUTE14,
        l_fdbk_lin_rec.ATTRIBUTE15,
        l_fdbk_lin_rec.ATTRIBUTE16,
        l_fdbk_lin_rec.ATTRIBUTE17,
        l_fdbk_lin_rec.ATTRIBUTE18,
        l_fdbk_lin_rec.ATTRIBUTE19,
        l_fdbk_lin_rec.ATTRIBUTE20
      );

    
    END LOOP;
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_FDBK_LINE_DTL_STG COMPLETE >> Total Rows Inserted : ' || l_commit_counter);
    
    l_commit_counter := 0;
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_FDBK_QSTN_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_FDBK_QSTN_STG';
    
    fnd_file.put_line(fnd_file.log, 'TRUNCATE on Table XXSCS_FDBK_QSTN_STG COMPLETE');
    fnd_file.put_line(fnd_file.log, 'Inserting Data Into Table XXSCS_FDBK_QSTN_STG ......... ');
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_fdbk_qstn_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_FDBK_QSTN_STG
      (
        FDBK_QSTN_ID,
        FDK_CODE,
        FDK_CODE_DESC,
        FDK_GDW_CODE,
        FDK_GDW_CODE_DESC,
        EFFECTIVE_START_DT,
        EFFECTIVE_END_DT,
        FDK_TYPE,
        SORT_SEQ,
        LANGUAGE,
        SOURCE_LANG,
        CREATED_BY,
        CREATION_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATE_LOGIN,
        REQUEST_ID,
        PROGRAM_APPLICATION_ID,
        PROGRAM_ID,
        PROGRAM_UPDATE_DATE,
        ATTRIBUTE_CATEGORY,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        ATTRIBUTE16,
        ATTRIBUTE17,
        ATTRIBUTE18,
        ATTRIBUTE19,
        ATTRIBUTE20,
        FRM_CODE,
        GDW_PICK_FLAG,
        ORA_SEQ,
        FDK_PICK_VALUE,
        FDK_HDR_FLAG,
        ORA_PICK_FLAG,
        ACTION_CODE,
        REQUIRED,
        OPPORTUNITY,
        LEAD,
        ACTION_STATUS,
        ACTION_TYPE,
        MIN_RANGE,
        MAX_RANGE,
        NUMBER_ONLY,
        ENTITY_STATUS,
        ENTITY_REASON,
        MULTI_RESULT
      )
      VALUES
      (
        l_fdbk_qstn_rec.FDBK_QSTN_ID,
        l_fdbk_qstn_rec.FDK_CODE,
        l_fdbk_qstn_rec.FDK_CODE_DESC,
        l_fdbk_qstn_rec.FDK_GDW_CODE,
        l_fdbk_qstn_rec.FDK_GDW_CODE_DESC,
        l_fdbk_qstn_rec.EFFECTIVE_START_DT,
        l_fdbk_qstn_rec.EFFECTIVE_END_DT,
        l_fdbk_qstn_rec.FDK_TYPE,
        l_fdbk_qstn_rec.SORT_SEQ,
        l_fdbk_qstn_rec.LANGUAGE,
        l_fdbk_qstn_rec.SOURCE_LANG,
        l_fdbk_qstn_rec.CREATED_BY,
        l_fdbk_qstn_rec.CREATION_DATE,
        l_fdbk_qstn_rec.LAST_UPDATED_BY,
        l_fdbk_qstn_rec.LAST_UPDATE_DATE,
        l_fdbk_qstn_rec.LAST_UPDATE_LOGIN,
        l_fdbk_qstn_rec.REQUEST_ID,
        l_fdbk_qstn_rec.PROGRAM_APPLICATION_ID,
        l_fdbk_qstn_rec.PROGRAM_ID,
        l_fdbk_qstn_rec.PROGRAM_UPDATE_DATE,
        l_fdbk_qstn_rec.ATTRIBUTE_CATEGORY,
        l_fdbk_qstn_rec.ATTRIBUTE1,
        l_fdbk_qstn_rec.ATTRIBUTE2,
        l_fdbk_qstn_rec.ATTRIBUTE3,
        l_fdbk_qstn_rec.ATTRIBUTE4,
        l_fdbk_qstn_rec.ATTRIBUTE5,
        l_fdbk_qstn_rec.ATTRIBUTE6,
        l_fdbk_qstn_rec.ATTRIBUTE7,
        l_fdbk_qstn_rec.ATTRIBUTE8,
        l_fdbk_qstn_rec.ATTRIBUTE9,
        l_fdbk_qstn_rec.ATTRIBUTE10,
        l_fdbk_qstn_rec.ATTRIBUTE11,
        l_fdbk_qstn_rec.ATTRIBUTE12,
        l_fdbk_qstn_rec.ATTRIBUTE13,
        l_fdbk_qstn_rec.ATTRIBUTE14,
        l_fdbk_qstn_rec.ATTRIBUTE15,
        l_fdbk_qstn_rec.ATTRIBUTE16,
        l_fdbk_qstn_rec.ATTRIBUTE17,
        l_fdbk_qstn_rec.ATTRIBUTE18,
        l_fdbk_qstn_rec.ATTRIBUTE19,
        l_fdbk_qstn_rec.ATTRIBUTE20,
        l_fdbk_qstn_rec.FRM_CODE,
        l_fdbk_qstn_rec.GDW_PICK_FLAG,
        l_fdbk_qstn_rec.ORA_SEQ,
        l_fdbk_qstn_rec.FDK_PICK_VALUE,
        l_fdbk_qstn_rec.FDK_HDR_FLAG,
        l_fdbk_qstn_rec.ORA_PICK_FLAG,
        l_fdbk_qstn_rec.ACTION_CODE,
        l_fdbk_qstn_rec.REQUIRED,
        l_fdbk_qstn_rec.OPPORTUNITY,
        l_fdbk_qstn_rec.LEAD,
        l_fdbk_qstn_rec.ACTION_STATUS,
        l_fdbk_qstn_rec.ACTION_TYPE,
        l_fdbk_qstn_rec.MIN_RANGE,
        l_fdbk_qstn_rec.MAX_RANGE,
        l_fdbk_qstn_rec.NUMBER_ONLY,
        l_fdbk_qstn_rec.ENTITY_STATUS,
        l_fdbk_qstn_rec.ENTITY_REASON,
        l_fdbk_qstn_rec.MULTI_RESULT
      );

    
    END LOOP;
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_FDBK_QSTN_STG COMPLETE  >> Total Rows Inserted : ' || l_commit_counter);
    
    l_commit_counter := 0;
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_FDBK_RESP_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_FDBK_RESP_STG';
    
    fnd_file.put_line(fnd_file.log, 'TRUNCATE on Table XXSCS_FDBK_RESP_STG COMPLETE');
    fnd_file.put_line(fnd_file.log, 'Inserting Data Into Table XXSCS_FDBK_RESP_STG ......... ');
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_fdbk_resp_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_FDBK_RESP_STG
      (
        FDBK_RESP_ID,
        FDBK_QSTN_ID,
        FDK_CODE,
        FDK_VALUE,
        FDK_VALUE_DESC,
        FDK_GDW_CODE,
        FDK_GDW_VALUE,
        FDK_GDW_VALUE_DESC,
        EFFECTIVE_START_DT,
        EFFECTIVE_END_DT,
        LANGUAGE,
        SOURCE_LANG,
        CREATED_BY,
        CREATION_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATE_LOGIN,
        REQUEST_ID,
        PROGRAM_APPLICATION_ID,
        PROGRAM_ID,
        PROGRAM_UPDATE_DATE,
        ATTRIBUTE_CATEGORY,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        ATTRIBUTE16,
        ATTRIBUTE17,
        ATTRIBUTE18,
        ATTRIBUTE19,
        ATTRIBUTE20,
        ORA_PICK_FLAG,
        GDW_PICK_FLAG,
        ACTION_CODE,
        OPPORTUNITY,
        LEAD,
        ACTION_STATUS,
        ACTION_TYPE,
        ORA_SEQ,
        ENTITY_STATUS,
        ENTITY_REASON
      )
      VALUES
      (
        l_fdbk_resp_rec.FDBK_RESP_ID,
        l_fdbk_resp_rec.FDBK_QSTN_ID,
        l_fdbk_resp_rec.FDK_CODE,
        l_fdbk_resp_rec.FDK_VALUE,
        l_fdbk_resp_rec.FDK_VALUE_DESC,
        l_fdbk_resp_rec.FDK_GDW_CODE,
        l_fdbk_resp_rec.FDK_GDW_VALUE,
        l_fdbk_resp_rec.FDK_GDW_VALUE_DESC,
        l_fdbk_resp_rec.EFFECTIVE_START_DT,
        l_fdbk_resp_rec.EFFECTIVE_END_DT,
        l_fdbk_resp_rec.LANGUAGE,
        l_fdbk_resp_rec.SOURCE_LANG,
        l_fdbk_resp_rec.CREATED_BY,
        l_fdbk_resp_rec.CREATION_DATE,
        l_fdbk_resp_rec.LAST_UPDATED_BY,
        l_fdbk_resp_rec.LAST_UPDATE_DATE,
        l_fdbk_resp_rec.LAST_UPDATE_LOGIN,
        l_fdbk_resp_rec.REQUEST_ID,
        l_fdbk_resp_rec.PROGRAM_APPLICATION_ID,
        l_fdbk_resp_rec.PROGRAM_ID,
        l_fdbk_resp_rec.PROGRAM_UPDATE_DATE,
        l_fdbk_resp_rec.ATTRIBUTE_CATEGORY,
        l_fdbk_resp_rec.ATTRIBUTE1,
        l_fdbk_resp_rec.ATTRIBUTE2,
        l_fdbk_resp_rec.ATTRIBUTE3,
        l_fdbk_resp_rec.ATTRIBUTE4,
        l_fdbk_resp_rec.ATTRIBUTE5,
        l_fdbk_resp_rec.ATTRIBUTE6,
        l_fdbk_resp_rec.ATTRIBUTE7,
        l_fdbk_resp_rec.ATTRIBUTE8,
        l_fdbk_resp_rec.ATTRIBUTE9,
        l_fdbk_resp_rec.ATTRIBUTE10,
        l_fdbk_resp_rec.ATTRIBUTE11,
        l_fdbk_resp_rec.ATTRIBUTE12,
        l_fdbk_resp_rec.ATTRIBUTE13,
        l_fdbk_resp_rec.ATTRIBUTE14,
        l_fdbk_resp_rec.ATTRIBUTE15,
        l_fdbk_resp_rec.ATTRIBUTE16,
        l_fdbk_resp_rec.ATTRIBUTE17,
        l_fdbk_resp_rec.ATTRIBUTE18,
        l_fdbk_resp_rec.ATTRIBUTE19,
        l_fdbk_resp_rec.ATTRIBUTE20,
        l_fdbk_resp_rec.ORA_PICK_FLAG,
        l_fdbk_resp_rec.GDW_PICK_FLAG,
        l_fdbk_resp_rec.ACTION_CODE,
        l_fdbk_resp_rec.OPPORTUNITY,
        l_fdbk_resp_rec.LEAD,
        l_fdbk_resp_rec.ACTION_STATUS,
        l_fdbk_resp_rec.ACTION_TYPE,
        l_fdbk_resp_rec.ORA_SEQ,
        l_fdbk_resp_rec.ENTITY_STATUS,
        l_fdbk_resp_rec.ENTITY_REASON
      );

    
    END LOOP;
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_FDBK_RESP_STG COMPLETE >> Total Rows Inserted : ' || l_commit_counter);
   
  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure Copy Data - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure Copy Data - Error - '||SQLERRM;
      x_retcode := 2;              
  END copy_data;

END XXSCS_SIT_TO_PRF_DATA_CPY;
/
SHOW ERRORS;
EXIT;
