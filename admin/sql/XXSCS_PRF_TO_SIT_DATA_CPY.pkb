-- $Id$
-- $Rev$
-- $HeadURL$
-- $Date$
-- $Author$


SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XXSCS_PRF_TO_SIT_DATA_CPY 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXSCS_PRF_TO_SIT_DATA_CPY.pkb                      |
-- | Description :  Package to Copy Data From PRF To SIT               |
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
  )
  AS
  
  l_sql                   VARCHAR2(2000);
  TYPE l_data_cur_type    IS REF CURSOR;
  l_data_cur              l_data_cur_type;
  l_pot_rep_rec           XXSCS_POTENTIAL_REP_STG%ROWTYPE;
  l_pot_rec               XXSCS_POTENTIAL_STG%ROWTYPE;
  l_commit_counter        NUMBER  :=  0;
  BEGIN
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_POTENTIAL_REP_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_POTENTIAL_REP_STG';
    
    fnd_file.put_line(fnd_file.log, 'TRUNCATE on Table XXSCS_POTENTIAL_REP_STG COMPLETE');
    fnd_file.put_line(fnd_file.log, 'Inserting Data Into Table XXSCS_POTENTIAL_REP_STG ......... ');
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_pot_rep_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_POTENTIAL_REP_STG
      (
          POTENTIAL_REP_ID,
          COMPARABLE_POTENTIAL_AMT,
          COMPARABLE_POTENTIAL_PCT,
          SALES_TRTRY_DESC,
          SALES_TRTRY_MANAGER_ID,
          SALES_TRTRY_EFCT_START_DT,
          SALES_TRTRY_EFCT_END_DT,
          ORG_ID,
          COST_CENTER,
          CHARGE_TO_COST_CENTER,
          CURRENCY_CODE,
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
          SALES_TRTRY_ID
        )
        VALUES
        (
          l_pot_rep_rec.POTENTIAL_REP_ID,
          l_pot_rep_rec.COMPARABLE_POTENTIAL_AMT,
          l_pot_rep_rec.COMPARABLE_POTENTIAL_PCT,
          l_pot_rep_rec.SALES_TRTRY_DESC,
          l_pot_rep_rec.SALES_TRTRY_MANAGER_ID,
          l_pot_rep_rec.SALES_TRTRY_EFCT_START_DT,
          l_pot_rep_rec.SALES_TRTRY_EFCT_END_DT,
          l_pot_rep_rec.ORG_ID,
          l_pot_rep_rec.COST_CENTER,
          l_pot_rep_rec.CHARGE_TO_COST_CENTER,
          l_pot_rep_rec.CURRENCY_CODE,
          l_pot_rep_rec.LANGUAGE,
          l_pot_rep_rec.SOURCE_LANG,
          l_pot_rep_rec.CREATED_BY,
          l_pot_rep_rec.CREATION_DATE,
          l_pot_rep_rec.LAST_UPDATED_BY,
          l_pot_rep_rec.LAST_UPDATE_DATE,
          l_pot_rep_rec.LAST_UPDATE_LOGIN,
          l_pot_rep_rec.REQUEST_ID,
          l_pot_rep_rec.PROGRAM_APPLICATION_ID,
          l_pot_rep_rec.PROGRAM_ID,
          l_pot_rep_rec.PROGRAM_UPDATE_DATE,
          l_pot_rep_rec.ATTRIBUTE_CATEGORY,
          l_pot_rep_rec.ATTRIBUTE1,
          l_pot_rep_rec.ATTRIBUTE2,
          l_pot_rep_rec.ATTRIBUTE3,
          l_pot_rep_rec.ATTRIBUTE4,
          l_pot_rep_rec.ATTRIBUTE5,
          l_pot_rep_rec.ATTRIBUTE6,
          l_pot_rep_rec.ATTRIBUTE7,
          l_pot_rep_rec.ATTRIBUTE8,
          l_pot_rep_rec.ATTRIBUTE9,
          l_pot_rep_rec.ATTRIBUTE10,
          l_pot_rep_rec.ATTRIBUTE11,
          l_pot_rep_rec.ATTRIBUTE12,
          l_pot_rep_rec.ATTRIBUTE13,
          l_pot_rep_rec.ATTRIBUTE14,
          l_pot_rep_rec.ATTRIBUTE15,
          l_pot_rep_rec.ATTRIBUTE16,
          l_pot_rep_rec.ATTRIBUTE17,
          l_pot_rep_rec.ATTRIBUTE18,
          l_pot_rep_rec.ATTRIBUTE19,
          l_pot_rep_rec.ATTRIBUTE20,
          l_pot_rep_rec.SALES_TRTRY_ID
        );
        
        l_commit_counter    := l_commit_counter + 1;
        
        IF mod(l_commit_counter, 500) = 0 THEN
           COMMIT;
        END IF;
    
    END LOOP;    
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_POTENTIAL_REP_STG COMPLETE >> Total Rows Inserted : ' || l_commit_counter);
    
    
    l_commit_counter    := 0;
    
    l_sql          :=  'SELECT * FROM XXCRM.XXSCS_POTENTIAL_STG@' || p_db_link;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCRM.XXSCS_POTENTIAL_STG';
    
    OPEN l_data_cur FOR l_sql;
    LOOP
      FETCH l_data_cur INTO l_pot_rec;
      EXIT WHEN l_data_cur%NOTFOUND;
      
      INSERT INTO XXCRM.XXSCS_POTENTIAL_STG
      (
        POTENTIAL_ID,
        CUSTOMER_ACCOUNT_ID,
        ADDRESS_ID,
        PARTY_SITE_ID,
        POTENTIAL_TYPE_CD,
        POTENTIAL_TYPE_NM,
        EFFECTIVE_FISCAL_WEEK_ID,
        WEEKLY_SALES_TO_STD_IND,
        MONTH_SALES_TO_STD_IND,
        WKLY_ORDR_CNT_TO_STD_IND,
        LIKELY_TO_PURCHASE_IND,
        FIRST_ORDER_DT,
        LAST_ORDER_DT,
        SALE_ORDER_52WEEK_CNT,
        ACCT_BUSINESS_NM,
        SITE_BUSINESS_NM,
        COMPARABLE_POTENTIAL_AMT,
        ACCOUNT_SITE_RNK,
        STREET_ADDRESS1,
        STREET_ADDRESS2,
        CITY_NM,
        STATE_CD,
        STATE_NM,
        ZIP_CD,
        COUNTRY,
        CALC_WHITE_COLLAR_WORKER_CNT,
        SIC_GROUP_CD,
        OD_WHITE_COLLAR_WORKER_CNT,
        OD_SIC_GROUP_CD,
        SALES_TRTRY_DESC,
        SALES_TRTRY_MANAGER_ID,
        SALES_TRTRY_EFCT_START_DT,
        SALES_TRTRY_EFCT_END_DT,
        ORG_ID,
        COST_CENTER,
        CHARGE_TO_COST_CENTER,
        CURRENCY_CODE,
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
        SIC_GROUP_NM,
        SALES_TRTRY_ID
      )
      VALUES
      (
        l_pot_rec.POTENTIAL_ID,
        l_pot_rec.CUSTOMER_ACCOUNT_ID,
        l_pot_rec.ADDRESS_ID,
        l_pot_rec.PARTY_SITE_ID,
        l_pot_rec.POTENTIAL_TYPE_CD,
        l_pot_rec.POTENTIAL_TYPE_NM,
        l_pot_rec.EFFECTIVE_FISCAL_WEEK_ID,
        l_pot_rec.WEEKLY_SALES_TO_STD_IND,
        l_pot_rec.MONTH_SALES_TO_STD_IND,
        l_pot_rec.WKLY_ORDR_CNT_TO_STD_IND,
        l_pot_rec.LIKELY_TO_PURCHASE_IND,
        l_pot_rec.FIRST_ORDER_DT,
        l_pot_rec.LAST_ORDER_DT,
        l_pot_rec.SALE_ORDER_52WEEK_CNT,
        l_pot_rec.ACCT_BUSINESS_NM,
        l_pot_rec.SITE_BUSINESS_NM,
        l_pot_rec.COMPARABLE_POTENTIAL_AMT,
        l_pot_rec.ACCOUNT_SITE_RNK,
        l_pot_rec.STREET_ADDRESS1,
        l_pot_rec.STREET_ADDRESS2,
        l_pot_rec.CITY_NM,
        l_pot_rec.STATE_CD,
        l_pot_rec.STATE_NM,
        l_pot_rec.ZIP_CD,
        l_pot_rec.COUNTRY,
        l_pot_rec.CALC_WHITE_COLLAR_WORKER_CNT,
        l_pot_rec.SIC_GROUP_CD,
        l_pot_rec.OD_WHITE_COLLAR_WORKER_CNT,
        l_pot_rec.OD_SIC_GROUP_CD,
        l_pot_rec.SALES_TRTRY_DESC,
        l_pot_rec.SALES_TRTRY_MANAGER_ID,
        l_pot_rec.SALES_TRTRY_EFCT_START_DT,
        l_pot_rec.SALES_TRTRY_EFCT_END_DT,
        l_pot_rec.ORG_ID,
        l_pot_rec.COST_CENTER,
        l_pot_rec.CHARGE_TO_COST_CENTER,
        l_pot_rec.CURRENCY_CODE,
        l_pot_rec.LANGUAGE,
        l_pot_rec.SOURCE_LANG,
        l_pot_rec.CREATED_BY,
        l_pot_rec.CREATION_DATE,
        l_pot_rec.LAST_UPDATED_BY,
        l_pot_rec.LAST_UPDATE_DATE,
        l_pot_rec.LAST_UPDATE_LOGIN,
        l_pot_rec.REQUEST_ID,
        l_pot_rec.PROGRAM_APPLICATION_ID,
        l_pot_rec.PROGRAM_ID,
        l_pot_rec.PROGRAM_UPDATE_DATE,
        l_pot_rec.ATTRIBUTE_CATEGORY,
        l_pot_rec.ATTRIBUTE1,
        l_pot_rec.ATTRIBUTE2,
        l_pot_rec.ATTRIBUTE3,
        l_pot_rec.ATTRIBUTE4,
        l_pot_rec.ATTRIBUTE5,
        l_pot_rec.ATTRIBUTE6,
        l_pot_rec.ATTRIBUTE7,
        l_pot_rec.ATTRIBUTE8,
        l_pot_rec.ATTRIBUTE9,
        l_pot_rec.ATTRIBUTE10,
        l_pot_rec.ATTRIBUTE11,
        l_pot_rec.ATTRIBUTE12,
        l_pot_rec.ATTRIBUTE13,
        l_pot_rec.ATTRIBUTE14,
        l_pot_rec.ATTRIBUTE15,
        l_pot_rec.ATTRIBUTE16,
        l_pot_rec.ATTRIBUTE17,
        l_pot_rec.ATTRIBUTE18,
        l_pot_rec.ATTRIBUTE19,
        l_pot_rec.ATTRIBUTE20,
        l_pot_rec.SIC_GROUP_NM,
        l_pot_rec.SALES_TRTRY_ID
      );

    
    END LOOP;
    
    CLOSE l_data_cur;
    
    COMMIT;
    
    fnd_file.put_line(fnd_file.log, 'Data Insert Into Table XXSCS_POTENTIAL_STG COMPLETE >> Total Rows Inserted : ' || l_commit_counter);
        
  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure Copy Data - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure Copy Data - Error - '||SQLERRM;
      x_retcode := 2; 
  END copy_data;

END XXSCS_PRF_TO_SIT_DATA_CPY;
/
SHOW ERRORS;
EXIT;
