CREATE OR REPLACE PACKAGE XX_CDH_EBILL_ENT_PKG
AS
  PROCEDURE insert_epdf_entities(
    p_orig_system_reference  IN         VARCHAR2,
    p_cust_account_id        IN         NUMBER,
    x_errbuf                 OUT NOCOPY VARCHAR2,
    x_retcode                OUT NOCOPY VARCHAR2
  );
END XX_CDH_EBILL_ENT_PKG;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY XX_CDH_EBILL_ENT_PKG
AS
  PROCEDURE insert_epdf_entities(
    p_orig_system_reference  IN         VARCHAR2,
    p_cust_account_id        IN         NUMBER,
    x_errbuf                 OUT NOCOPY VARCHAR2,
    x_retcode                OUT NOCOPY VARCHAR2
  )
  AS

    v_errbuf               VARCHAR2(4000);
    l_error_message        VARCHAR2(4000);
    l_return_status        VARCHAR2(100);
    v_message          VARCHAR2(4000);
    l_individual_consolidate VARCHAR2(1000);
    l_subject VARCHAR2(1000);
    l_subject_invoice VARCHAR2(1000);
    l_subject_cons VARCHAR2(1000);
    ln_count               NUMBER:=0;
    ln_success             NUMBER:=0;
    l_field_cons_inv  VARCHAR2(20);
    l_field_account   VARCHAR2(20);
    l_field_docid     VARCHAR2(20);
    l_field_billdate  VARCHAR2(20);
    l_field_invoice   VARCHAR2(20);
    l_field_cons      VARCHAR2(20);

    CURSOR missing_epdf
    IS
    select cust_account_id cust_acc_id, n_ext_attr2 cust_doc_id
    from   xx_cdh_cust_acct_ext_b
    where  attr_group_id=166
    and    c_ext_attr16='COMPLETE'
    and    sysdate between d_ext_attr1 and nvl(d_ext_attr2,sysdate+1)
    and    c_ext_attr3 = 'ePDF'
    and    cust_account_id = p_cust_account_id
    MINUS
    select cust_account_id cust_acc_id, 
           cust_doc_id 
    from   xx_cdh_ebl_main
    where  cust_account_id = p_cust_account_id;
    
    ln_ebl_file_name_id     NUMBER;
    l_standard_message     VARCHAR2(4000);
    l_standard_sign        VARCHAR2(400);
    l_standard_disclaim    VARCHAR2(4000);
    lc_individual_consolidate  VARCHAR2(400);

 BEGIN

    x_retcode := 0;


    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_SUB_CONSOLI'),'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.')
        INTO l_subject_cons
    FROM DUAL;

    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_SUB_STAND'),'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.')
        INTO l_subject_invoice
    FROM DUAL;


    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_SUB_STAND'),'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.')
        INTO l_subject_invoice
    FROM DUAL;


    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_MSG'),'Dear Customer,<br><br>Attached is your electronic billing for &DATEFROM to &DATETO.<br>For questions regarding billing format, please contact electronicbilling@officedepot.com.<br>For account related questions, please call 1-800-721-6592.')
        INTO l_standard_message
    FROM DUAL;


    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_SIGN'),'Thank You,<br>Office Depot')
        INTO l_standard_sign
    FROM DUAL;

    SELECT NVL(FND_PROFILE.VALUE ('XXOD_EBL_EMAIL_STD_DISCLAIM'),'Disclaimer:  The attached file is construed as a legally binding document between Office DEPOT and  its customer, and is not intended for anyone other than the intended recipient.  If you are not the intended recipient, please forward this')
        INTO l_standard_disclaim
    FROM DUAL;



    SELECT field_id INTO l_field_account FROM xx_cdh_ebilling_fields_v WHERE field_name='Account Number' ;

    SELECT field_id INTO l_field_docid FROM xx_cdh_ebilling_fields_v WHERE field_name like 'Customer_DocID' ;

    SELECT field_id INTO l_field_billdate FROM xx_cdh_ebilling_fields_v WHERE field_name like 'Bill To Date' ;

    SELECT field_id INTO l_field_invoice FROM xx_cdh_ebilling_fields_v WHERE field_name like 'Invoice Number' ;

    SELECT field_id INTO l_field_cons FROM xx_cdh_ebilling_fields_v WHERE field_name like 'Consolidated Bill Number' ;

 FOR l in missing_epdf LOOP

    ln_count := ln_count+1;
   -- Insert Data into EBIL Main
    BEGIN
    SAVEPOINT cust_start;
    XX_CDH_EBL_MAIN_PKG.insert_row(
                       p_cust_doc_id               => l.cust_doc_id          -- Cust_Doc_Id (Using Sequence)
                      ,p_cust_account_id           => l.cust_acc_id         -- Cust_Account_Id
                      ,p_ebill_transmission_type   => 'EMAIL'                -- Transmission Method
                      ,p_ebill_associate           => '10'                   -- eBill Associate
                      ,p_file_processing_method    => '03'                   -- File Processing Method
                      ,p_file_name_ext             => 'PDF'                  -- File Name Extension
                      ,p_max_file_size             => 10
                      ,p_max_transmission_size     => 10
                      ,p_zip_required              => 'N'
                      ,p_zipping_utility           => NULL
                      ,p_zip_file_name_ext         => NULL
                      ,p_od_field_contact          => NULL
                      ,p_od_field_contact_email    => NULL
                      ,p_od_field_contact_phone    => NULL
                      ,p_client_tech_contact       => NULL
                      ,p_client_tech_contact_email => NULL
                      ,p_client_tech_contact_phone => NULL
                      ,p_file_name_seq_reset       => NULL
                      ,p_file_next_seq_number      => NULL
                      ,p_file_seq_reset_date       => SYSDATE
                      ,p_file_name_max_seq_number  => NULL
                      ,p_attribute1                => 'CORE'
                      ,p_last_update_date          => SYSDATE
                      ,p_last_updated_by           => FND_GLOBAL.USER_ID
                      ,p_creation_date             => SYSDATE
                      ,p_created_by                => FND_GLOBAL.USER_ID
                      ,p_last_update_login         => FND_GLOBAL.LOGIN_ID
                  );

      -- Insert Data into Transaction Details

    lc_individual_consolidate := null;
    l_field_cons_inv      := null;

    BEGIN
    SELECT c_ext_attr1 INTO l_individual_consolidate FROM xx_cdh_cust_acct_ext_b WHERE n_ext_attr2 = l.cust_doc_id;

    EXCEPTION
    WHEN OTHERS THEN
    lc_individual_consolidate := null;
    END;

        IF l_individual_consolidate = 'Invoice' THEN

            l_subject := l_subject_invoice;
            l_field_cons_inv  := l_field_invoice;

        ELSIF l_individual_consolidate = 'Consolidated Bill' THEN

            l_subject := l_subject_cons;
            l_field_cons_inv := l_field_cons;

        ELSE

            l_subject := 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.';
            l_field_cons_inv  := l_field_invoice;

        END IF;

      -- Missing check.. Already present or not...
      XX_CDH_EBL_TRANS_DTL_PKG.insert_row(
                         p_cust_doc_id              => l.cust_doc_id
                        ,p_email_subject            => l_subject
                        ,p_email_std_message        => l_standard_message
                        ,p_email_custom_message     => NULL
                        ,p_email_signature          => l_standard_sign
                        ,p_email_std_disclaimer     => l_standard_disclaim
                        ,p_email_logo_required      => 'Y'
                        ,p_email_logo_file_name     => 'OFFICEDEPOT'
                        ,p_ftp_cust_contact_name    => NULL
                        ,p_ftp_cust_contact_email   => NULL
                        ,p_ftp_cust_contact_phone   => NULL
                        ,p_ftp_direction            => NULL
                        ,p_ftp_transfer_type        => NULL
                        ,p_ftp_destination_site     => NULL
                        ,p_ftp_destination_folder   => NULL
                        ,p_ftp_user_name            => NULL
                        ,p_ftp_password             => NULL
                        ,p_ftp_pickup_server        => NULL
                        ,p_ftp_pickup_folder        => NULL
                        ,p_ftp_notify_customer      => NULL
                        ,p_ftp_cc_emails            => NULL
                        ,p_ftp_email_sub            => NULL
                        ,p_ftp_email_content        => NULL
                        ,p_ftp_send_zero_byte_file  => NULL
                        ,p_ftp_zero_byte_file_text  => NULL
                        ,p_ftp_zero_byte_notifi_txt => NULL
                        ,p_cd_file_location         => NULL
                        ,p_cd_send_to_address       => NULL
                        ,p_comments                 => NULL
                        ,p_last_update_date         => SYSDATE
                        ,p_last_updated_by          => FND_GLOBAL.USER_ID
                        ,p_creation_date            => SYSDATE
                        ,p_created_by               => FND_GLOBAL.USER_ID
                        ,p_last_update_login        => FND_GLOBAL.LOGIN_ID
                  );

        -- Insert Data into File

         SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
                INTO ln_ebl_file_name_id
         FROM DUAL;

        -- Missing check.. Already present or not...
        -- Missing sequence number 20, 30, 40...

        XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row(
                          p_ebl_file_name_id     => ln_ebl_file_name_id               -- Using Sequence
                         ,p_cust_doc_id          => l.cust_doc_id
                         ,p_file_name_order_seq  => 10                                -- 10 or 20 or 30 -- Sequence_Number
                         ,p_field_id             => l_field_account                              -- 10003(account_number), 10118, 10007
                         ,p_constant_value       => NULL
                         ,p_default_if_null      => NULL
                         ,p_comments             => NULL
                         ,p_last_update_date     => SYSDATE
                         ,p_last_updated_by      => FND_GLOBAL.USER_ID
                         ,p_creation_date        => SYSDATE
                         ,p_created_by           => FND_GLOBAL.USER_ID
                         ,p_last_update_login    => FND_GLOBAL.LOGIN_ID
                  );

         SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
                INTO ln_ebl_file_name_id
         FROM DUAL;

        XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row(
                          p_ebl_file_name_id     => ln_ebl_file_name_id               -- Using Sequence
                         ,p_cust_doc_id          => l.cust_doc_id
                         ,p_file_name_order_seq  => 20                                -- 10 or 20 or 30 -- Sequence_Number
                         ,p_field_id             => l_field_docid                              -- 10003(account_number), 10118, 10007
                         ,p_constant_value       => NULL
                         ,p_default_if_null      => NULL
                         ,p_comments             => NULL
                         ,p_last_update_date     => SYSDATE
                         ,p_last_updated_by      => FND_GLOBAL.USER_ID
                         ,p_creation_date        => SYSDATE
                         ,p_created_by           => FND_GLOBAL.USER_ID
                         ,p_last_update_login    => FND_GLOBAL.LOGIN_ID
                  );


         SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
                INTO ln_ebl_file_name_id
         FROM DUAL;

        XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row(
                          p_ebl_file_name_id     => ln_ebl_file_name_id               -- Using Sequence
                         ,p_cust_doc_id          => l.cust_doc_id
                         ,p_file_name_order_seq  => 30                                -- 10 or 20 or 30 -- Sequence_Number
                         ,p_field_id             => l_field_billdate                              -- 10003(account_number), 10118, 10007
                         ,p_constant_value       => NULL
                         ,p_default_if_null      => NULL
                         ,p_comments             => NULL
                         ,p_last_update_date     => SYSDATE
                         ,p_last_updated_by      => FND_GLOBAL.USER_ID
                         ,p_creation_date        => SYSDATE
                         ,p_created_by           => FND_GLOBAL.USER_ID
                         ,p_last_update_login    => FND_GLOBAL.LOGIN_ID
                  );

         SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
                INTO ln_ebl_file_name_id
         FROM DUAL;

        XX_CDH_EBL_FILE_NAME_DTL_PKG.insert_row(
                          p_ebl_file_name_id     => ln_ebl_file_name_id               -- Using Sequence
                         ,p_cust_doc_id          => l.cust_doc_id
                         ,p_file_name_order_seq  => 40                                -- 10 or 20 or 30 -- Sequence_Number
                         ,p_field_id             => l_field_cons_inv                              -- 10003(account_number), 10118, 10007
                         ,p_constant_value       => NULL
                         ,p_default_if_null      => NULL
                         ,p_comments             => NULL
                         ,p_last_update_date     => SYSDATE
                         ,p_last_updated_by      => FND_GLOBAL.USER_ID
                         ,p_creation_date        => SYSDATE
                         ,p_created_by           => FND_GLOBAL.USER_ID
                         ,p_last_update_login    => FND_GLOBAL.LOGIN_ID
                  );

    ln_success := ln_success+1;
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'Success, cust_account_id:,'|| l.cust_acc_id);

    EXCEPTION WHEN OTHERS THEN
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'Error occurred for cust_account_id:,'|| l.cust_acc_id||','||SQLERRM);
      ROLLBACK to cust_start;
      x_retcode:=1;

    END;

 END LOOP;

    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, CHR(13)||'Summary: '||CHR(13));
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'Total number of accounts corrected :'||ln_count);
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, 'Total number of accounts errored :'||(ln_count-ln_success));


 EXCEPTION WHEN OTHERS THEN
   x_retcode := 2;
   x_errbuf  := 'Unexpected Error during Bill Docs Update:' || SQLERRM;
   XX_CDH_CUST_UTIL_BO_PVT.log_msg(0,x_errbuf);
 END insert_epdf_entities;
END XX_CDH_EBILL_ENT_PKG;
/
SHOW ERRORS;
