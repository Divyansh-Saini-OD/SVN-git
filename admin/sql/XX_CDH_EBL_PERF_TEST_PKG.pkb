CREATE OR REPLACE PACKAGE BODY XX_CDH_EBL_PERF_TEST_PKG
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_PERF_TEST_PKG                                    |
-- | Description :                                                             |
-- | This package will validate entire data before changing the document       |
-- |          status, to make sure that the data is Valid. It will insert      |
-- |          data into the template header, template detail, aggregate table  |
-- |          for the 'eXLS' delivery method and file naming parameters        |
-- |          if the file naming parameters are are not present                |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 09-JUL-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|
AS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_VALID_PROG                                       |
-- | Description :                                                             |
-- |          status, to make sure that the data is Valid. It will insert      |
-- |          data into the template header, template detail, aggregate table  |
-- |          for the 'eXLS' delivery method and file naming parameters        |
-- |          if the file naming parameters are are not present                |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 09-JUL-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|
    PROCEDURE XX_CDH_EBL_VALID_PROG  (x_error_buff        OUT VARCHAR2
                                     ,x_ret_code          OUT NUMBER
                                     ,p_summary_id        IN  NUMBER
                                     ,p_delivery_mthd     IN  VARCHAR2
                                     ,p_no_of_documents   IN  NUMBER
                                     )
    IS

    lc_error_message            VARCHAR2(4000);
    lc_validate                 VARCHAR2(4000);
    lc_direct_flag              VARCHAR2(10);
    lc_change_status            VARCHAR2(10)   := 'COMPLETE';
    lc_status                   VARCHAR2(10);
    ld_creation_date            DATE           := SYSDATE;
    ld_wh_update_date           DATE           := SYSDATE;
    ld_last_update_date         DATE           := SYSDATE;
    ln_last_updated_by          NUMBER         := FND_GLOBAL.USER_ID;
    ln_created_by               NUMBER         := FND_GLOBAL.USER_ID;
    ln_last_update_login        NUMBER         := FND_GLOBAL.LOGIN_ID;
    ln_count_field_id           NUMBER;
    ln_count_success_rcd        NUMBER;
    ln_completed_documents      NUMBER;
    ln_setup_doc                NUMBER;
    ln_document_id              NUMBER;
    ln_cust_acc_id              xxod_hz_summary.eft_printing_program_id%TYPE;
    ln_cust_doc_id              xxod_hz_summary.eft_transmission_program_id%TYPE;
    ln_acc_number               hz_cust_accounts.account_number%TYPE;
    ln_cust_document_id         xxod_hz_summary.eft_transmission_program_id%TYPE;
    ln_file_name_order_seq      xx_cdh_ebl_file_name_dtl.file_name_order_seq%TYPE;
    ln_field_id                 xx_cdh_ebl_file_name_dtl.field_id%TYPE;
    ln_customer_doc_id          xx_cdh_cust_acct_ext_b.n_ext_attr2%TYPE;
    ln_attr_grp_id              ego_attr_groups_v.attr_group_id%TYPE;

    CURSOR lcu_get_data
    IS
    SELECT XOHS.eft_printing_program_id      -- CUST ACCT ID
          ,XOHS.eft_transmission_program_id  -- CUST DOC ID
          ,HZCA.account_number               -- ACC Number
    FROM   xxod_hz_summary  XOHS
          ,hz_cust_accounts HZCA
          ,xx_cdh_cust_acct_ext_b XCAEB
    WHERE  XOHS.summary_id                  = p_summary_id
    AND    HZCA.cust_account_id             = XOHS.eft_printing_program_id                -- CUST ACCT ID relation between hz cust account and hz summary table
    AND    XOHS.eft_transmission_program_id = XCAEB.n_ext_attr2                           -- CUST DOC ID relation between hz summary table and cust acct ext b table
    AND    XOHS.edi_remittance_method       = nvl(p_delivery_mthd, edi_remittance_method) -- Gets the data for the delivery method that is passed.
    AND    XOHS.insert_update_flag          = 2                                           -- picks the cust acc ID and cust doc ID whose records are processed.
    AND    XCAEB.c_ext_attr16               = 'IN_PROCESS'                                -- picks only the data that are in 'IN PROCESS' state.
    AND    XCAEB.attr_group_id              = ln_attr_grp_id;

    BEGIN
       SELECT attr_group_id
       INTO   ln_attr_grp_id
       FROM   ego_attr_groups_v
       WHERE  attr_group_type   = 'XX_CDH_CUST_ACCOUNT'
       AND    attr_group_name   = 'BILLDOCS';
       xx_cdh_ebl_util_pkg.log_error('getting aggregate ID for the cust doc  id'||ln_attr_grp_id);

       ln_count_success_rcd    := 0;
       lc_error_message := '*****************************************************Header*********************************************************'||CHR(13)
                         ||'Delimiter seperation details : '||'Account Number'||'|'||'Customer Account ID'||'|'||'Customer Doc ID'||'|'||'Status'||CHR(13)
                         ||'********************************************************************************************************************';
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_message);

       OPEN lcu_get_data;
       LOOP
          FETCH lcu_get_data
          INTO  ln_cust_acc_id
               ,ln_cust_doc_id
               ,ln_acc_number;
          EXIT WHEN lcu_get_data%NOTFOUND;
          xx_cdh_ebl_util_pkg.log_error('Processing Record '||ln_cust_doc_id);
            IF (p_delivery_mthd ='eXLS') THEN  -- used for selecting the document template based on the number of documents required to be processed.
               ln_setup_doc := mod(ln_count_success_rcd,8);
            IF ln_setup_Doc = 0 THEN
               ln_document_id := 2045892;
            ELSIF ln_setup_Doc = 1 THEN
               ln_document_id := 20902220;
            ELSIF ln_setup_Doc = 2 THEN
               ln_document_id := 28515413;
            ELSIF ln_setup_Doc = 3 THEN
               ln_document_id := 20902222;
            ELSIF ln_setup_Doc = 4 THEN
               ln_document_id := 20902223;
            ELSIF ln_setup_Doc = 5 THEN
               ln_document_id := 20902224;
            ELSIF ln_setup_Doc = 6 THEN
               ln_document_id := 20902225;
            ELSIF ln_setup_Doc = 7 THEN
               ln_document_id := 20902226;
            END IF;
            xx_cdh_ebl_util_pkg.log_error('Processing from Document '||ln_document_id);

            DELETE xx_cdh_ebl_templ_header
            where cust_doc_id = ln_cust_doc_id;
         -- inserting the data into the templ header table for the delivery method passed.
            INSERT INTO xx_cdh_ebl_templ_header(
               cust_doc_id
              ,ebill_file_creation_type
              ,delimiter_char
              ,line_feed_style
              ,include_header
              ,logo_file_name
              ,file_split_criteria
              ,file_split_value
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,last_update_date
              ,last_updated_by
              ,creation_date
              ,created_by
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,wh_update_date
              )
            SELECT
               ln_cust_doc_id
              ,ebill_file_creation_type
              ,delimiter_char
              ,line_feed_style
              ,include_header
              ,logo_file_name
              ,file_split_criteria
              ,file_split_value
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,ld_last_update_date
              ,ln_last_updated_by
              ,ld_creation_date
              ,ln_created_by
              ,ln_last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,ld_creation_date
            FROM  xx_cdh_ebl_templ_header
            WHERE cust_doc_id = ln_document_id;

            DELETE xx_cdh_ebl_templ_dtl
            where cust_doc_id = ln_cust_doc_id;
         -- inserting the data into the templ detail for the delivery method passed.
            INSERT INTO xx_cdh_ebl_templ_dtl (
               ebl_templ_id
              ,cust_doc_id
              ,record_type
              ,seq
              ,field_id
              ,label
              ,start_pos
              ,field_len
              ,data_format
              ,string_fun
              ,sort_order
              ,sort_type
              ,mandatory
              ,seq_start_val
              ,seq_inc_val
              ,seq_reset_field
              ,constant_value
              ,alignment
              ,padding_char
              ,default_if_null
              ,comments
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,last_update_date
              ,last_updated_by
              ,creation_date
              ,created_by
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,wh_update_date
              )
            SELECT
               xx_cdh_ebl_templ_id_s.NEXTVAL
              ,ln_cust_doc_id
              ,record_type
              ,seq
              ,field_id
              ,label
              ,start_pos
              ,field_len
              ,data_format
              ,string_fun
              ,sort_order
              ,sort_type
              ,mandatory
              ,seq_start_val
              ,seq_inc_val
              ,seq_reset_field
              ,constant_value
              ,alignment
              ,padding_char
              ,default_if_null
              ,comments
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,ld_last_update_date
              ,ln_last_updated_by
              ,ld_creation_date
              ,ln_created_by
              ,ln_last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,ld_creation_date
            FROM  xx_cdh_ebl_templ_dtl
            WHERE cust_doc_id = ln_document_id;

            DELETE xx_cdh_ebl_std_aggr_dtl
            where cust_doc_id = ln_cust_doc_id;
         -- inserting the data into the aggregate detail for the delivery method passed.
            INSERT INTO xx_cdh_ebl_std_aggr_dtl(
               ebl_aggr_id
              ,cust_doc_id
              ,aggr_fun
              ,aggr_field_id
              ,change_field_id
              ,label_on_file
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,last_update_date
              ,last_updated_by
              ,creation_date
              ,created_by
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,wh_update_date
              )
            SELECT
               xx_cdh_ebl_aggr_id_s.NEXTVAL
              ,ln_cust_doc_id
              ,aggr_fun
              ,aggr_field_id
              ,change_field_id
              ,label_on_file
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,attribute16
              ,attribute17
              ,attribute18
              ,attribute19
              ,attribute20
              ,ld_last_update_date
              ,ln_last_updated_by
              ,ld_creation_date
              ,ln_created_by
              ,ln_last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
              ,ld_creation_date
            FROM xx_cdh_ebl_std_aggr_dtl
            WHERE cust_doc_id = ln_document_id;
              lc_error_message := 'The documents were successfully inserted for the cust doc id '|| ln_cust_doc_id;
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
            END IF;  --(p_delivery_mthd ='eXLS')

            SELECT COUNT(field_id)   -- to check if the field id is present for the customer document ID
            INTO   ln_count_field_id
            FROM   xx_cdh_ebl_file_name_dtl
            WHERE  cust_doc_id = ln_cust_doc_id;
            xx_cdh_ebl_util_pkg.log_error('getting count of field id for the cust doc id');

            IF (ln_count_field_id = 0) THEN
               SELECT c_ext_attr7 direct_flag   -- checks the flag for the cust doc id passed.
               INTO   lc_direct_flag
               FROM   xx_cdh_cust_acct_ext_b XCEB
               WHERE  n_ext_attr2   = ln_cust_doc_id
               AND    attr_group_id = ln_attr_grp_id;
               xx_cdh_ebl_util_pkg.log_error('fetching flag for the cust doc  id');
                 IF (lc_direct_flag = 'Y') THEN    -- inserts the file naming parameters for the direct doc
                    INSERT INTO XX_CDH_EBL_FILE_NAME_DTL(
                            ebl_file_name_id
                           ,cust_doc_id
                           ,file_name_order_seq
                           ,last_update_date
                           ,last_updated_by
                           ,creation_date
                           ,created_by
                           ,last_update_login
                           ,field_id
                           )
                    SELECT XX_CDH_EBL_FILE_NAME_ID_S.NEXTVAL
                          ,ln_cust_doc_id
                          ,(ROWNUM * 10)
                          ,ld_last_update_date
                          ,ln_last_updated_by
                          ,ld_creation_date
                          ,ln_created_by
                          ,ln_last_update_login
                          ,xftv.source_value1
                    FROM   xx_fin_translatedefinition xftd
                          ,xx_fin_translatevalues xftv
                    WHERE  xftd.translate_id = xftv.translate_id
                    AND    xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
                    AND    xftv.source_value2 IN ('Account Number','Customer_DocID','Bill To Date')
                    AND    xftv.enabled_flag ='Y';
                    xx_cdh_ebl_util_pkg.log_error('inserting values file naming parameters for the direct doc');
                 ELSE   -- (lc_direct_flag = 'Y') inserts the file naming parameters for the indirect doc
                    INSERT INTO XX_CDH_EBL_FILE_NAME_DTL(
                            ebl_file_name_id
                           ,cust_doc_id
                           ,file_name_order_seq
                           ,last_update_date
                           ,last_updated_by
                           ,creation_date
                           ,created_by
                           ,last_update_login
                           ,field_id
                           )
                    SELECT XX_CDH_EBL_FILE_NAME_ID_S.NEXTVAL
                          ,ln_cust_doc_id   -- ln_cust_document_id
                          ,(ROWNUM * 10)
                          ,ld_last_update_date
                          ,ln_last_updated_by
                          ,ld_creation_date
                          ,ln_created_by
                          ,ln_last_update_login
                          ,xftv.source_value1
                    FROM   xx_fin_translatedefinition xftd
                          ,xx_fin_translatevalues xftv
                    WHERE  xftd.translate_id = xftv.translate_id
                    AND    xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
                    AND    xftv.source_value2 IN ('Account Number','Customer_DocID','Bill To Date','Ship To Location')
                    AND    xftv.enabled_flag ='Y';
                    xx_cdh_ebl_util_pkg.log_error('inserting values file naming parameters for the indirect doc');
                 END IF; --(lc_direct_flag = 'Y')
            END IF; --(ln_count_field_id = 0)

            xx_cdh_ebl_util_pkg.log_error('valiating the values into the table');
            lc_validate := XX_CDH_EBL_VALIDATE_PKG.VALIDATE_FINAL(ln_cust_doc_id,ln_cust_acc_id,lc_change_status); -- validates the data in the respective tables

            IF (lc_validate = 'TRUE') THEN   -- gets the cust doc ID for the deilvery method passed whose status is in 'COMPLETE'
               lc_status := 'COMPLETE';
               lc_error_message := ln_acc_number||'|'||ln_cust_acc_id||'|'||ln_cust_doc_id||'|'||lc_status;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_message);
            ELSE --(lc_validate = 'TRUE') THEN
               lc_status := 'IN PROCESS';
               lc_error_message := ln_acc_number||'|'||ln_cust_acc_id||'|'||ln_cust_doc_id||'|'||lc_status;
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_message);
            END IF; --(lc_validate = 'TRUE') THEN
               ln_count_success_rcd := ln_count_success_rcd +1;
            COMMIT;
           EXIT WHEN ln_count_success_rcd = p_no_of_documents;
       END LOOP;
       CLOSE lcu_get_data;

          EXCEPTION

             WHEN NO_DATA_FOUND THEN
             lc_error_message :=  'SQLCODE - '||SQLCODE||' SQLERRM - '||Initcap(SQLERRM)||' for the Summary ID '||p_summary_id;
             FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
             x_ret_code := 1;

             WHEN OTHERS THEN
             lc_error_message := 'Error - Unhandled exception : package XX_CDH_EBL_PERF_TEST_PKG.XX_CDH_EBL_VALD_PROG. '
                               ||' SQLCODE - '||SQLCODE||' SQLERRM - '||SQLERRM;
             FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
             x_ret_code := 2;

      END XX_CDH_EBL_VALID_PROG;
 END XX_CDH_EBL_PERF_TEST_PKG;
/
