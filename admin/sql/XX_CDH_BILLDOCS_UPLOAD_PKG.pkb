CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_BILLDOCS_UPLOAD_PKG
AS
-- +=========================================================================+
-- |                           Oracle - GSD                                  |
-- |                             Bangalore                                   |
-- +=========================================================================+
-- | Name  : XX_CDH_BILLDOCS_UPLOAD_PKG                                      |
-- | Rice ID: E3116                                                          |
-- | Description      : This Program will create the bill docs               |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     21-MAY-2015 Arun G          Initial draft version                |
-- |1.2     29-OCT-2015 Arun G          Made changes as per defect 1845      |
-- |1.3     09-NOV-2018 Thilak E        Added for Defect#NAIT-56624          |
-- |1.4     03-JAN-2019	Sridhar P       Added for Defect#NAIT 50792
-- +=========================================================================+

  g_debug_flag      BOOLEAN;
  gc_success        VARCHAR2(100)   := 'SUCCESS';
  gc_failure        VARCHAR2(100)   := 'FAILURE';

  PROCEDURE log_exception ( p_error_location     IN  VARCHAR2
                           ,p_error_msg          IN  VARCHAR2 )
  IS
  -- +===================================================================+
  -- | Name  : log_exception                                             |
  -- | Description     : The log_exception procedure logs all exceptions |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_error_location     IN -> Error location       |
  -- |                   p_error_msg          IN -> Error message        |
  -- +===================================================================+

   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
  ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;
  ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;

  BEGIN

    XX_COM_ERROR_LOG_PUB.log_error(  p_return_code             => FND_API.G_RET_STS_ERROR
                                    ,p_msg_count               => 1
                                    ,p_application_name        => 'XXFIN'
                                    ,p_program_type            => 'Custom Messages'
                                    ,p_program_name            => 'XX_CDH_BILLDOCS_UPLOAD_PKG'
                                    ,p_attribute15             => 'XX_CDH_BILLDOCS_UPLOAD_PKG'
                                    ,p_program_id              => null
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => p_error_location
                                    ,p_error_message_code      => null
                                    ,p_error_message           => p_error_msg
                                    ,p_error_message_severity  => 'MAJOR'
                                    ,p_error_status            => 'ACTIVE'
                                    ,p_created_by              => ln_user_id
                                    ,p_last_updated_by         => ln_user_id
                                    ,p_last_update_login       => ln_login
                                    );

  EXCEPTION
    WHEN OTHERS
    THEN
      fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
  END log_exception;


  PROCEDURE log_msg(
                    p_string IN VARCHAR2
                   )
  IS
  -- +===================================================================+
  -- | Name  : log_msg                                                   |
  -- | Description     : The log_msg procedure displays the log messages |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_string             IN -> Log Message          |
  -- +===================================================================+

  BEGIN

    IF (g_debug_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG,p_string);
      dbms_output.put_line(p_String);
    END IF;
  END log_msg;

  -- +===================================================================+
  -- | Name  : log_msg                                                   |
  -- | Description     : The log_msg procedure displays the log messages |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_string             IN -> Log Message          |
  -- +===================================================================+

  PROCEDURE set_context
  AS 
   l_user_id                       NUMBER;
   l_responsibility_id             NUMBER;
   l_responsibility_appl_id        NUMBER;  
  
   -- set the user to ODCDH for bypassing VPD
   BEGIN
     SELECT user_id,
            responsibility_id,
            responsibility_application_id
     INTO   l_user_id,                      
            l_responsibility_id,            
            l_responsibility_appl_id
     FROM   fnd_user_resp_groups 
     WHERE user_id=(SELECT user_id 
                    FROM  fnd_user 
                    WHERE user_name='ODCDH')
     AND responsibility_id=(SELECT responsibility_id 
                            FROM   FND_RESPONSIBILITY 
                            WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
						   
     FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
					   
     log_msg (' User Id:' || l_user_id);
     log_msg (' Responsibility Id:' || l_responsibility_id);
     log_msg (' Responsibility Application Id:' || l_responsibility_appl_id);

  EXCEPTION
    WHEN OTHERS
    THEN
      log_msg ('Exception in initializing : ' || SQLERRM);   
  END set_context;

-- +===================================================================+
-- | Name  : get_data
-- | Description     : The get_data procedure reads the data from      |
-- |                   webadi excel template file and loads the data   |
-- |                   into stg table for further processing           |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+

  PROCEDURE get_data(p_aops_number             IN  xx_cdh_billdocs_upload_stg.aops_customer_number%TYPE,
                     p_mbs_doc_id              IN  xx_cdh_billdocs_upload_stg.mbs_doc_id%TYPE,
                     p_paydoc                  IN  xx_cdh_billdocs_upload_stg.paydoc%TYPE,
                     p_delivery_method         IN  xx_cdh_billdocs_upload_stg.delivery_method%TYPE,
                     p_direct_document         IN  xx_cdh_billdocs_upload_stg.is_parent%TYPE,
                     p_is_parent               IN  xx_cdh_billdocs_upload_stg.direct_document%TYPE,
                     p_request_start_date      IN  xx_cdh_billdocs_upload_stg.request_start_date%TYPE,
                     p_payment_term            IN  xx_cdh_billdocs_upload_stg.payment_term%TYPE,
                     p_send_to_parent          IN  xx_cdh_billdocs_upload_stg.send_to_parent%TYPE,
                     p_parent_doc_id           IN  xx_cdh_billdocs_upload_stg.parent_doc_id%TYPE,
                     p_mail_to_Attention       IN  xx_cdh_billdocs_upload_stg.mail_to_attention%TYPE,
                     p_doc_status              IN  xx_cdh_billdocs_upload_stg.doc_status%TYPE,
                     p_transmission_type       IN  xx_cdh_billdocs_upload_stg.transmission_type%TYPE,
                     p_file_extension          IN  xx_cdh_billdocs_upload_stg.file_extension%TYPE,
                     p_ebill_associate         IN  xx_cdh_billdocs_upload_stg.ebill_associate%TYPE,
                     p_file_processing_method  IN  xx_cdh_billdocs_upload_stg.file_processing_method%TYPE,
                     p_max_file_size           IN  xx_cdh_billdocs_upload_stg.max_file_size%TYPE,
                     p_max_trans_size          IN  xx_cdh_billdocs_upload_stg.max_trans_size%TYPE,
                     p_zip_required            IN  xx_cdh_billdocs_upload_stg.zip_required%TYPE,
                     p_compress_utility        IN  xx_cdh_billdocs_upload_stg.compress_utility%TYPE,
                     p_compress_extension      IN  xx_cdh_billdocs_upload_stg.compress_extension%TYPE,
                     p_email_subject           IN  xx_cdh_billdocs_upload_stg.email_subject%TYPE,
                     p_standard_message        IN  xx_cdh_billdocs_upload_stg.standard_message%TYPE,
                     p_notify_customer         IN  xx_cdh_billdocs_upload_stg.notify_customer%TYPE,
                     p_ftp_direction           IN  xx_cdh_billdocs_upload_stg.ftp_direction%TYPE,
                     p_contact_name            IN  xx_cdh_billdocs_upload_stg.contact_name%TYPE,
                     p_destination_folder      IN  xx_cdh_billdocs_upload_stg.destination_folder%TYPE,
                     p_contact_email           IN  xx_cdh_billdocs_upload_stg.contact_email%TYPE,
                     p_FTP_if_zero_byte        IN  xx_cdh_billdocs_upload_stg.ftp_if_zero_byte%TYPE,
                     p_cc_list                 IN  xx_cdh_billdocs_upload_stg.cc_list%TYPE,
                     p_zero_byte_noty_list     IN  xx_cdh_billdocs_upload_stg.zero_byte_noty_list%TYPE,
                     p_ftp_email_subject       IN  xx_cdh_billdocs_upload_stg.ftp_email_subject%TYPE,
                     p_zero_byte_file_text     IN  xx_cdh_billdocs_upload_stg.zero_byte_file_text%TYPE,
                     p_email_content           IN  xx_cdh_billdocs_upload_stg.email_content%TYPE,
                     p_comments                IN  xx_cdh_billdocs_upload_stg.comments%TYPE,
                     p_contact_phone           IN  xx_cdh_billdocs_upload_stg.contact_phone%TYPE,
                     p_created_by              IN  xx_cdh_billdocs_upload_stg.created_by%TYPE)
  AS 

  lc_error_message varchar2(4000);

  BEGIN 

    INSERT INTO XX_CDH_BILLDOCS_UPLOAD_STG
    (batch_id                 ,
     record_id                ,
     aops_customer_number     ,   
     mbs_doc_id               ,
     paydoc                   ,
     delivery_method          ,
     direct_document          ,
     is_parent                ,
     request_start_date       ,
     payment_term             ,
     send_to_parent           ,
     parent_doc_id            ,
     mail_to_Attention        ,
     doc_status               ,
     transmission_type         ,
     file_extension           ,
     ebill_associate                ,
     file_processing_method   ,
     max_file_size            ,
     max_trans_size           ,
     zip_required             ,
     compress_utility         ,
     compress_extension       ,
     email_subject            ,
     standard_message         ,
     notify_customer          ,
     ftp_direction            ,
     contact_name             ,
     destination_folder       ,
     contact_email            ,
     FTP_if_zero_byte         ,
     cc_list                  ,
     zero_byte_noty_list      ,
     ftp_email_subject        ,
     zero_byte_file_text      ,
     email_content            ,
     comments                 ,
     contact_phone            ,
     record_status            ,
     creation_date            ,
     created_by               ,
     last_update_date         ,
     last_updated_by)
   VALUES
     (fnd_global.session_id        ,
      xx_cdh_billdocs_record_s.nextval, 
      p_aops_number              ,
      p_mbs_doc_id               ,
      UPPER(p_paydoc)            ,
      p_delivery_method          ,
      p_direct_document          ,
      UPPER(p_is_parent)         ,
      p_request_start_date       ,
      p_payment_term             ,
      p_send_to_parent           ,
      p_parent_doc_id            ,
      p_mail_to_Attention        ,
      UPPER(p_doc_status)        ,
      p_transmission_type        ,
      p_file_extension           ,
      p_ebill_associate          ,
      p_file_processing_method   ,
      p_max_file_size            ,
      p_max_trans_size           ,
      p_zip_required             ,
      p_compress_utility         ,
      p_compress_extension       ,
      p_email_subject           ,
      p_standard_message        ,
      p_notify_customer          ,
      p_ftp_direction            ,
      p_contact_name             ,
      p_destination_folder       ,
      p_contact_email            ,
      p_FTP_if_zero_byte         ,
      p_cc_list                  ,
      p_zero_byte_noty_list      ,
      p_ftp_email_subject        ,
      p_zero_byte_file_text      , 
      p_email_content            ,
      p_comments                 ,
      p_contact_phone            , 
      'N'                        ,
      SYSDATE                    ,
      p_created_by               ,
      SYSDATE                    ,
      p_created_by
       );

    COMMIT;
          
  EXCEPTION 
    WHEN OTHERS 
    THEN
      fnd_message.set_name('BNE', 'Error while inserting the data ..'||SQLERRM);

      lc_error_message := SQLERRM;
  END get_data;

 -- +===================================================================+
  -- | Name  : get_customer_detais                                        |
  -- | Description     : This function returns the customer details       |
  -- |                   ret_orig_order_num for return orders             |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_customer_details(p_aops_cust_NUMBER IN  xx_cdh_omx_bill_docs_stg.aops_customer_NUMBER%TYPE,
                                p_customer_info    OUT hz_cust_accounts%ROWTYPE,
                                p_error_msg        OUT VARCHAR2)
  RETURN VARCHAR2
  IS
   BEGIN
     log_msg('Getting the customer details ..');
  
     p_error_msg := NULL;

     SELECT *
     INTO   p_customer_info
     FROM   hz_cust_accounts_all 
     WHERE  orig_system_reference = lpad(to_char(p_aops_cust_NUMBER),8,0)||'-'||'00001-A0';


     log_msg('cust acct id: ...:' ||p_customer_info.cust_account_id);

     RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       p_error_msg :=  'Customer not exists';
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       p_error_msg := 'Unable to fetch Customer details :'||' '||SQLERRM;
       RETURN gc_failure;
  END get_customer_details;

 -- +===================================================================+
  -- | Name  : get_document_type                                          |
  -- | Description     : This function returns the document type          |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_document_type(p_document_id      IN  xx_cdh_mbs_document_master.document_id%TYPE,
                             p_doc_type         OUT xx_cdh_mbs_document_master.doc_type%TYPE,
                             p_error_msg        OUT VARCHAR2)
  RETURN VARCHAR2
  IS
   BEGIN
     log_msg('Getting the document type for document id..' || p_document_id);
  
     p_error_msg := NULL;

     SELECT doc_type
     INTO   p_doc_type
     FROM   xx_cdh_mbs_document_master
     WHERE  document_id  = p_document_id;


     log_msg('doc type: ...:' ||p_doc_type);

     RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       p_error_msg :=  'Invalid Doc type .. Unable to find the document type';
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       p_error_msg := 'Unable to fetch document type :'||' '||SQLERRM;
       RETURN gc_failure;
  END get_document_type;

  -- +===================================================================+
  -- | Name  : end_DATE_existing_doc                                     |
  -- | Description     : The function check if there are any active      |
  -- |                   docs exists for the given customer , if exists  |
  -- |                   it will end DATE all of them                    |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- +===================================================================+
    
  FUNCTION end_date_existing_doc(p_aops_customer_NUMBER IN  xx_cdh_omx_bill_docs_stg.aops_customer_number%TYPE,
                                 p_cust_acct_id         IN  hz_cust_accounts_all.cust_account_id%TYPE,
                                 p_end_date             IN  DATE,
                                 p_error_msg            OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  CURSOR cur_doc
  IS 
  SELECT *
  FROM xx_cdh_cust_acct_ext_b 
  WHERE cust_account_id = p_cust_acct_id 
  AND d_ext_attr2 IS NULL -- not end dated -- 
  AND p_end_date IS NOT NULL  
  AND ATTR_GROUP_ID = 166
  AND c_ext_attr2 = 'Y' -- only paydocs.
  UNION
  SELECT *
  FROM xx_cdh_cust_acct_ext_b 
  WHERE cust_account_id = p_cust_acct_id 
  AND d_ext_attr2 IS NOT NULL -- not end dated -- 
  AND p_end_date IS NULL 
  AND ATTR_GROUP_ID = 166;

  ln_cnt NUMBER := 0;

  BEGIN
    p_error_msg := NULL;

    FOR cur_doc_rec IN cur_doc
    LOOP 
      BEGIN
        log_msg('End dating the document id .'|| cur_doc_rec.n_ext_Attr2);

        UPDATE XX_CDH_CUST_ACCT_EXT_B
        SET D_EXT_ATTR2 = p_end_Date -- SYSDATE-1 -- to_DATE('09/30/2014', 'MM/DD/YYYY'),  --end DATE
        WHERE  ATTR_GROUP_ID = 166
        AND N_EXT_ATTR2 = cur_doc_rec.n_ext_attr2;

        ln_cnt := ln_cnt + SQL%ROWCOUNT;
      END;
    END LOOP;  
    
    log_msg(ln_cnt ||' Rows End dated: ');

    RETURN gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      p_error_msg := 'Error while end dating the docs'||SQLERRM;
      RETURN gc_failure;
  END end_date_existing_doc;


  -- +===================================================================+
  -- | Name  : get_payment_term_info                                      |
  -- | Description     : This function returns the payment terminfo       |
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      :                                                  |
  -- +===================================================================+

  FUNCTION get_payment_term_info(p_payment_term        IN  ra_terms.name%TYPE,
                                 p_payment_term_info   OUT ra_terms%ROWTYPE,
                                 p_error_msg           OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  e_process_exception  EXCEPTION;

  BEGIN
    p_error_msg          := NULL;
    p_payment_term_info  := NULL;
    log_msg('Getting Payment term info  ..'|| p_payment_term);

    -- Get Oracle payment term ..

    SELECT *
    INTO p_payment_term_info
    FROM ra_terms 
    WHERE name = p_payment_term
    AND NVL(end_date_active, SYSDATE) >= SYSDATE;

    log_msg( 'Payment term id :' || p_payment_term_info.term_id);    
    log_msg( 'payment term name :' || p_payment_term_info.name); 
 
    RETURN gc_success;
  EXCEPTION 
    WHEN NO_DATA_FOUND 
    THEN 
      p_error_msg := 'Payterm not found';
      RETURN gc_failure;
    WHEN OTHERS 
    THEN 
      p_error_msg := 'Unable to fetch payment term details :'||' '||SQLERRM;
      RETURN gc_failure;

  END get_payment_term_info;

-- +===================================================================+
-- | Name  : update stg table 
-- | Description     : The update stg table sets the record status     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE update_stg_table(p_record_id       IN      xx_cdh_billdocs_upload_stg.record_id%TYPE,
                             p_customer_number IN      xx_cdh_billdocs_upload_stg.aops_customer_number%TYPE,
                             p_status          IN      xx_cdh_billdocs_upload_stg.record_status%TYPE,
                             p_batch_id        IN      xx_cdh_billdocs_upload_stg.batch_id%TYPE,
                             p_error_msg       IN OUT  xx_cdh_billdocs_upload_stg.error_message%TYPE,
                             x_return_status   OUT     VARCHAR2)

  AS 
  BEGIN 

    x_return_status := NULL;

    UPDATE xx_cdh_billdocs_upload_stg
    SET record_status = p_status,
        error_message = p_error_msg
    WHERE record_id      =  p_record_id 
    AND   batch_id       =  p_batch_id;

    log_msg( SQL%ROWCOUNT ||' Row updated for record id :'|| p_record_id);

    x_return_status := gc_success;

   
  EXCEPTION 
    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      p_error_msg     := 'Error while updating the staging table '||SQLERRM;
  END update_stg_table;

  -- +========================================================================================+
  -- | Name  : Insert_eBill_trans_dtls                                                        |
  -- | Description   : This Procedure inserts the records into ebill trans dtls table         |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE insert_ebill_trans_dtls(p_cust_doc_id         IN xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                    p_billdocs_rec        IN  xx_cdh_billdocs_upload_stg%ROWTYPE,
                                    p_error_msg           OUT VARCHAR2)
  IS

  lc_email_subject             xx_cdh_ebl_transmission_dtl.email_subject%TYPE;
  lc_email_std_msg             xx_cdh_ebl_transmission_dtl.email_std_message%TYPE;
  lc_email_std_disclaim1       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_std_disclaim2       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_std_disclaime       xx_cdh_ebl_transmission_dtl.email_std_disclaimer%TYPE;
  lc_email_signature           xx_cdh_ebl_transmission_dtl.email_signature%TYPE;
  lc_email_logo_file_name      xx_cdh_ebl_transmission_dtl.email_logo_file_name%TYPE;

  BEGIN
    lc_email_subject            := NULL;
    lc_email_std_msg            := NULL;
    lc_email_std_disclaim1      := NULL;
    lc_email_std_disclaim2      := NULL;
    lc_email_std_disclaime      := NULL;
    lc_email_signature          := NULL;
    lc_email_logo_file_name     := NULL;


    log_msg('Getting Profile values ..');

    IF p_billdocs_rec.email_subject IS NULL
    THEN 
      SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_SUB_STAND')
      INTO lc_email_subject
      FROM DUAL;
    ELSE
      lc_email_subject := p_billdocs_rec.email_subject;
    END IF;

    log_msg('Email Subject :'|| lc_email_subject);

    IF p_billdocs_rec.standard_message IS NULL
    THEN 
      SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_MSG')
      INTO lc_email_std_msg
      FROM DUAL;
    ELSE
      lc_email_std_msg := p_billdocs_rec.standard_message;
    END IF;

    log_msg('Email Std msg :'|| lc_email_std_msg);

    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_DISCLAIM')
    INTO lc_email_std_disclaim1
    FROM DUAL;

    log_msg('Email std disclaim1 :'|| lc_email_std_disclaim1);

    SELECT fnd_profile.value('XXOD_EBL_EMAIL_STD_DISCLAIM1')
    INTO lc_email_std_disclaim2
    FROM DUAL;

    log_msg('Email std disclaim2 :'|| lc_email_std_disclaim2);


    lc_email_std_disclaime := lc_email_std_disclaim1||lc_email_std_disclaim2;

    log_msg('Email std disclaime :'|| lc_email_std_disclaime);

    select fnd_profile.value('XXOD_EBL_EMAIL_STD_SIGN')
    into lc_email_signature
    from dual;

    log_msg('Email Signature :'|| lc_email_signature);

    select fnd_profile.value('XXOD_EBL_LOGO_FILE')
    into lc_email_logo_file_name
    from dual;

    log_msg('Email logo file name :'|| lc_email_logo_file_name);

    log_msg('Calling XX_CDH_EBL_TRANS_DTL_PKG.insert_row pkg to insert row ..');

    XX_CDH_EBL_TRANS_DTL_PKG.insert_row(p_cust_doc_id               => p_cust_doc_id,
                                        p_email_subject             => lc_email_Subject,
                                        p_email_std_message         => lc_email_std_msg,
                                        p_email_custom_message      => NULL,
                                        p_email_std_disclaimer      => lc_email_std_disclaime,
                                        p_email_signature           => lc_email_signature,
                                        p_Email_logo_required       => NULL,
                                        p_email_logo_file_name      => lc_email_logo_file_name,
                                        p_ftp_direction             => NVL(p_billdocs_rec.ftp_direction,'N'), 
                                        p_ftp_transfer_type         => NULL ,
                                        p_ftp_destination_site      => NULL ,
                                        p_ftp_destination_folder    => NVL(p_billdocs_rec.destination_folder,'N'), 
                                        p_ftp_user_name             => NULL ,
                                        p_ftp_password              => NULL ,
                                        p_ftp_pickup_server         => NULL ,
                                        p_ftp_pickup_folder         => NULL ,
                                        p_ftp_cust_contact_name     => NVL(p_billdocs_rec.contact_name,'N'), 
                                        p_ftp_cust_contact_email    => NVL(p_billdocs_rec.contact_email,'N'), 
                                        p_ftp_cust_contact_phone    => NVL(p_billdocs_rec.contact_phone,'N'), 
                                        p_ftp_notify_customer       => NVL(p_billdocs_rec.notify_customer,'N'),
                                        p_ftp_cc_emails             => NVL(p_billdocs_rec.cc_list,'N'),
                                        p_ftp_email_sub             => NVL(p_billdocs_rec.email_subject,'N'), 
                                        p_ftp_email_content         => NVL(p_billdocs_rec.email_content,'N'), 
                                        p_ftp_send_zero_byte_file   => NVL(p_billdocs_rec.ftp_if_zero_byte,'N'), 
                                        p_ftp_zero_byte_file_text   => NVL(p_billdocs_rec.zero_byte_file_text,'N'),
                                        p_ftp_zero_byte_notifi_txt  => NVL(p_billdocs_rec.zero_byte_noty_list,'N' ),
                                        p_cd_file_location          => NULL ,
                                        p_cd_send_to_address        => NULL ,
                                        p_comments                  => NVL(p_billdocs_rec.comments,'N'));

  EXCEPTION
    WHEN OTHERS
    THEN
      p_error_msg     := 'Error inserting rec into ebill trans dtls '|| SQLERRM ;
  END insert_ebill_trans_dtls;

  -- +========================================================================================+
  -- | Name  :Insert_ebill_file_name_dtls                                                         |
  -- | Description   : This Procedure inserts the records into ebill file name dtls table         |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Insert_ebill_file_name_dtls (p_cust_doc_id         IN   xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                         p_document_type       IN   VARCHAR2,
                                         p_error_msg           OUT  VARCHAR2)
  IS

  ln_order_seq        NUMBER;
  ln_file_name_id     NUMBER;
  lc_field_value      xx_fin_translatevalues.source_value2%TYPE;
  lc_file_name_id     NUMBER;
  ln_file_id          NUMBER;
  lc_doc_field_value  VARCHAR2(100);

  e_process_exception  exception;

  BEGIN

    ln_order_seq     := 10;
    ln_file_name_id  := NULL;
    p_error_msg  := NULL;
    lc_field_value   := NULL;

    log_msg('P_document_type :'|| p_document_type);

    For i IN 1..4
    LOOP
      BEGIN

        SELECT xx_cdh_ebl_file_name_id_s.nextval
        INTO lc_file_name_id
        FROM DUAL;

        lc_field_value := NULL;

        IF p_document_type = 'Consolidated Bill'
        THEN
          lc_doc_field_value := 'Consolidated Bill Number';
        ELSE
          lc_doc_field_value := 'Invoice Number';
        END IF ;

        IF ln_order_seq = 10
        THEN
          lc_field_value := 'Account Number';
        ELSIF ln_order_seq = 20
        THEN
          lc_field_value := 'Customer_DocID';
        ELSIF ln_order_seq = 30
        THEN
          lc_field_value := 'Bill To Date';
        ELSIF ln_order_seq = 40
        THEN
          lc_field_value := lc_doc_field_value;
        END IF;

        log_msg('lc_field_value :'|| lc_field_value);

        SELECT xftv.source_value1
        INTO ln_file_id
        FROM xx_fin_translatedefinition xft,
             xx_fin_translatevalues xftv
        WHERE xft.translate_id   = xftv.translate_id
        AND xft.enabled_flag     = 'Y'
        AND xftv.enabled_flag    = 'Y'
        AND translation_name     = 'XX_CDH_EBILLING_FIELDS'
        AND source_value2        = lc_field_value;

        log_msg('inserting into file dtl pkg..');
        log_msg('Cust doc id: '|| p_cust_doc_id);

        xx_cdh_ebl_file_name_dtl_pkg.insert_row(p_ebl_file_name_id     => lc_file_name_id ,
                                                p_cust_doc_id          => p_cust_doc_id,
                                                p_file_name_order_seq  => ln_order_seq,
                                                p_field_id             => ln_file_id,
                                                p_constant_value       => null,
                                                p_default_if_null      => null,
                                                p_comments             => null);

       ln_order_seq := ln_order_seq + 10;
      EXCEPTION
        WHEN OTHERS
        THEN
          p_error_msg := 'Error inserting rec into Insert_ebill_file_name_dtls  '|| SQLERRM ;
          RAISE e_process_exception;
      END;
   END LOOP;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF p_error_msg IS NULL
      THEN
        p_error_msg := 'Error inserting rec into Insert_ebill_file_name_dtls  '|| SQLERRM ;
      END IF;
  END Insert_ebill_file_name_dtls ;

  -- +========================================================================================+
  -- | Name  :Insert_ebill_Main_dtls                                                          |
  -- | Description   : This Procedure inserts the records into Insert_ebill_Main_dtls table   |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+


PROCEDURE Insert_ebill_main_dtls(p_cust_doc_id         IN xx_cdh_ebl_transmission_dtl.cust_doc_id%TYPE,
                                 p_cust_account_id     IN hz_cust_accounts.cust_account_id%TYPE,
                                 p_billdocs_rec        IN  xx_cdh_billdocs_upload_stg%ROWTYPE,
                                 p_error_msg           OUT VARCHAR2)
  IS

  ln_order_seq             NUMBER;
  ln_file_name_id          NUMBER;
  lc_associate             fnd_lookups.lookup_code%TYPE;
  lc_file_processing_code  fnd_lookups.lookup_code%TYPE;

  BEGIN

    p_error_msg := NULL;

    log_msg('inserting into Ebil Main pkg..');

    BEGIN 
      -- get associate id
      SELECT lookup_code
      INTO lc_associate
      FROM fnd_lookups
      WHERE lookup_type = 'XXOD_EBL_ASSOCIATE'
      AND  meaning      = p_billdocs_rec.ebill_associate --'OMX'
      AND enabled_flag  = 'Y';
    EXCEPTION 
      WHEN OTHERS
      THEN 
        SELECT FND_PROFILE.value('XXOD_EBL_ASSOCIATE_NAME')
        INTO lc_associate
        FROM DUAL;
        fnd_file.put_line(fnd_file.log, 'No data found for Associate so using the default');
    END ;

    log_msg('lc associate :'|| lc_associate);

    -- get file processing method id

    IF p_billdocs_rec.file_processing_method IS NOT NULL
    THEN
      SELECT lookup_code
      INTO lc_file_processing_code
      FROM fnd_lookups
      WHERE lookup_type = 'XXOD_EBL_FILE_PROC_MTD'
      AND meaning = p_billdocs_rec.file_processing_method;
    END IF;

    log_msg('lc file Processing code :' || lc_file_processing_code);


    xx_cdh_ebl_main_pkg.insert_row(p_cust_doc_id               => p_cust_doc_id,
                                   p_cust_account_id           => p_cust_account_id ,
                                   p_ebill_transmission_type   => p_billdocs_rec.transmission_type,
                                   p_ebill_associate           => lc_associate, --160,
                                   p_file_processing_method    => lc_file_processing_code, --'03',
                                   p_file_name_ext             => p_billdocs_rec.file_extension, --'PDF',
                                   p_max_file_size             => NVL(p_billdocs_rec.max_file_size,10),
                                   p_max_transmission_size     => NVL(p_billdocs_rec.max_trans_size,10),
                                   p_zip_required              => NVL(p_billdocs_rec.zip_required,'N'),
                                   p_zipping_utility           => NVL(p_billdocs_rec.compress_utility,'N'),
                                   p_zip_file_name_ext         => NVL(p_billdocs_rec.compress_extension,'N'),
                                   p_od_field_contact          => NULL,
                                   p_od_field_contact_email    => NULL,
                                   p_od_field_contact_phone    => NULL,
                                   p_client_tech_contact       => NULL,
                                   p_client_tech_contact_email => NULL,
                                   p_client_tech_contact_phone => NULL,
                                   p_file_name_seq_reset       => NULL,
                                   p_file_next_seq_NUMBER      => NULL,
                                   p_file_seq_reset_DATE       => NULL,
                                   p_file_name_max_seq_NUMBER  => NULL
                                   );
  EXCEPTION
    WHEN OTHERS
    THEN
      p_error_msg := 'Error inserting rec into Insert_ebill_main_dtls  '|| SQLERRM ;
  END Insert_ebill_Main_dtls;

-- +========================================================================================+
  -- | Name  :Create_Document                                                                 |
  -- | Description   : This Procedure creates the billing document                            |
  -- |                                                                                        |
  -- |                                                                                        |
  -- | Parameters    :                                                                        |
  -- +========================================================================================+

  PROCEDURE Create_Document(p_billdocs_rec        IN  xx_cdh_billdocs_upload_stg%ROWTYPE,
                            p_payment_term_info   IN  ra_terms%ROWTYPE,
                            p_customer_info       IN  hz_cust_accounts%ROWTYPE,
                            p_document_type       IN  VARCHAR2,
                            p_return_Status       OUT VARCHAR2,
                            p_error_msg           OUT VARCHAR2)
  IS

  ln_order_seq       NUMBER;
  ln_file_name_id    NUMBER;
  lc_user_table      EGO_USER_ATTR_ROW_TABLE  := EGO_USER_ATTR_ROW_TABLE();
  lc_data_table      EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
  lr_od_ext_attr_rec XX_CDH_OMX_BILL_DOCUMENTS_PKG.xx_od_ext_attr_rec;
  ln_cust_doc_id     NUMBER;
  lc_billing_type    VARCHAR2(1);
  lc_summary_billing VARCHAR2(1);
  lc_status          VARCHAR2(50);
  lc_doc_type        VARCHAR2(10);
  l_return_status    VARCHAR2(1000);
  l_errorcode        NUMBER;
  l_msg_count        NUMBER;
  l_msg_data         VARCHAR2(1000);
  l_errors_tbl       ERROR_HANDLER.Error_Tbl_Type;
  l_failed_row_id_list   VARCHAR2(1000);
  ln_msg_text            VARCHAR2(32000);
  lc_start_date      DATE;
  lc_paydoc          VARCHAR2(10);
  ln_is_parent       NUMBER;
  ln_send_parent     NUMBER;


  e_process_exception  EXCEPTION;
  BEGIN

    lr_od_ext_attr_rec  := NULL;
    lc_doc_type         := NULL;
    lc_billing_type     := NULL;
    lc_summary_billing  := NULL;
    lc_status           := NULL;
    lc_paydoc           := NULL;
 
    p_error_msg         := NULL;
    p_return_status     := NULL;

    log_msg('Create document .....');

    log_msg('Get next cust doc id seq value ..');

    SELECT xx_Cdh_cust_doc_id_s.nextval
    INTo ln_cust_doc_id 
    FROM DUAL;

    log_msg('ln_cust_doc_id :'|| ln_cust_doc_id);
 
    SELECT DECODE(p_billdocs_rec.paydoc ,'Y', 1, 0)  --infodoc and 1 --paydoc
    INTO lc_paydoc
    FROM DUAL;

    SELECT DECODE(p_document_type, 'Invoice' ,'N', 'Y')
    INTO lc_summary_billing
    FROM DUAL;

    SELECT DECODE(p_billdocs_rec.send_to_parent, 'Y', 1,0)
    INTO ln_send_parent
    FROM DUAL;

    SELECT DECODE(p_billdocs_rec.is_parent,'Y', 1, 0)
    INTO ln_is_parent
    FROM DUAL;

	--Added OPSTECH for Ebill Central Defect#NAIT-56624 by Thilak E 
	--Added EDI for Ebill  Defect#NAIT-50792 by Sridhar P
    IF p_billdocs_rec.doc_status IS NULL AND p_billdocs_rec.delivery_method IN ('PRINT','OPSTECH','EDI') 
    THEN 
      lc_status := 'COMPLETE';
    ELSIF p_billdocs_rec.delivery_method = 'ePDF'
    THEN 
      lc_status := 'IN_PROCESS';
    ELSE
      lc_status :=  p_billdocs_rec.doc_status;
    END IF;

    log_msg('Record id          :'|| p_billdocs_rec.record_id);
    log_msg('Cust account Id    :'|| p_customer_info.cust_account_id);
    log_msg('Document Type      :'|| p_document_type);
    log_msg('paydoc             :'|| p_billdocs_rec.paydoc);
    log_msg('delivery Method    :'|| p_billdocs_rec.delivery_method);
    log_msg('Direct Document    :'|| p_billdocs_rec.direct_document);
    log_msg('Payment term id    :'|| p_payment_term_info.term_id);
    log_msg('Payment term       :'|| p_payment_term_info.name); 
    log_msg('Mbs dod id         :'|| p_billdocs_rec.mbs_doc_id);
    log_msg('paydoc indicator   :'|| lc_paydoc);
    log_msg('lc_doc_status      :'|| lc_status);
          
    lr_od_ext_attr_rec.Attribute_group_code   :=   'BILLDOCS'; 
    lr_od_ext_attr_rec.record_id              :=   p_billdocs_rec.record_id;                   --101; 
    lr_od_ext_attr_rec.Interface_entity_name  :=   'ACCOUNT' ;
    lr_od_ext_attr_rec.cust_acct_id           :=   p_customer_info.cust_account_id;          --21929541; 
    lr_od_ext_attr_rec.c_ext_attr1            :=   p_document_type;                          --'Invoice'; -- Document_type -- consolidated or invoiced
    lr_od_ext_attr_rec.c_ext_attr2            :=   p_billdocs_rec.paydoc ;                   -- Paydoc or Infodoc
    lr_od_ext_attr_rec.c_ext_attr3            :=   p_billdocs_rec.delivery_method;           -- 'ePDF';      -- Delivery Method 
    lr_od_ext_attr_rec.c_ext_attr4            :=   NULL;                                     -- special handling
    lr_od_ext_attr_rec.c_ext_attr5            :=   'N' ;                                     --,Signature Required
    lr_od_ext_attr_rec.c_ext_attr6            :=   NULL;                                     --'WEEKLY';      -- Cycle  ?? HOW TO DERIVE THIS
    lr_od_ext_attr_rec.c_ext_attr7            :=   p_billdocs_rec.direct_document;           -- Direct_document -- Direct or Indirect
    lr_od_ext_attr_rec.c_ext_attr8            :=   NULL; 
    lr_od_ext_attr_rec.c_ext_attr9            :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr10           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr11           :=   lc_summary_billing;           -- Populate if consolidated is Y else N
    lr_od_ext_attr_rec.c_ext_attr12           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr13           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr14           :=   p_payment_term_info.name;                 --'WKON060000N030'; -- Payment term
    lr_od_ext_attr_rec.c_ext_attr15           :=   p_billdocs_rec.mail_to_attention;
    lr_od_ext_attr_rec.c_ext_attr16           :=   lc_status;                                --- Status 'COMPLETE'
    lr_od_ext_attr_rec.c_ext_attr17           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr18           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr19           :=   NULL;
    lr_od_ext_attr_rec.c_ext_attr20           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr1            :=   p_billdocs_rec.mbs_doc_id;                --10000;         -- MBS DOC ID 
    lr_od_ext_attr_rec.N_Ext_attr2            :=   ln_cust_doc_id;                           -- CUST DOC ID 
    lr_od_ext_attr_rec.N_Ext_attr3            :=   1 ;                                       --NO OF COPIES --1
    lr_od_ext_attr_rec.N_Ext_attr4            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr5            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr6            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr7            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr8            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr9            :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr10           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr11           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr12           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr13           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr14           :=   NULL;
    lr_od_ext_attr_rec.N_Ext_attr15           :=   p_billdocs_rec.parent_doc_id;
    lr_od_ext_attr_rec.N_Ext_attr16           :=   ln_send_parent;    -- send to parent
    lr_od_ext_attr_rec.N_Ext_attr17           :=   ln_is_parent;         -- is_parent
    lr_od_ext_attr_rec.N_Ext_attr18           :=   p_payment_term_info.term_id;                                --1330; -- Payment term id
    lr_od_ext_attr_rec.N_Ext_attr19           :=   lc_paydoc; --p_billdocs_rec.paydoc   ;                   --1;     -- 0 --infodoc and 1 --paydoc
    lr_od_ext_attr_rec.N_Ext_attr20           :=   p_billdocs_rec.batch_id;                                    -- batch id
    lr_od_ext_attr_rec.D_Ext_attr1            :=   NVL(p_billdocs_rec.request_start_date, TRUNC(SYSDATE));      -- start date
    lr_od_ext_attr_rec.d_Ext_attr2            :=   NULL;                                                       -- End date 
    lr_od_ext_attr_rec.d_Ext_attr3            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr4            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr5            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr6            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr7            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr8            :=   NULL;
    lr_od_ext_attr_rec.d_Ext_attr9            :=   SYSDATE;                                                   -- request start date
    lr_od_ext_attr_rec.d_Ext_attr10           :=   NULL;


    log_msg( ' Calling Bulid Extension table ...');

    XX_CDH_OMX_BILL_DOCUMENTS_PKG.Build_extension_table
         (p_user_row_table        => lc_user_table,
          p_user_data_table       => lc_data_table,
          p_ext_attribs_row       => lr_od_ext_attr_rec,
          p_return_Status         => p_return_status,
          p_error_msg             => p_error_msg);
                    
    IF lc_user_table.count >0 
    THEN
      log_msg('User Table count..'|| lc_user_table.count); 
    END IF;

    IF lc_data_table.count >0 
    THEN
      log_msg('Data Table count..'|| lc_data_table.count); 
    END IF;                     
                     
    log_msg('calling process acct..');
         
    XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Account_Record(p_api_version           => XX_CDH_CUST_EXTEN_ATTRI_PKG.G_API_VERSION,
                                                       p_cust_account_id       => p_customer_info.cust_account_id,
                                                       p_attributes_row_table  => lc_user_table,
                                                       p_attributes_data_table => lc_data_table,
                                                       p_log_errors            => FND_API.G_FALSE,
                                                       x_failed_row_id_list    => l_failed_row_id_list,
                                                       x_return_status         => l_return_status,
                                                       x_errorcode             => l_errorcode,
                                                       x_msg_count             => l_msg_count,
                                                       x_msg_data              => l_msg_data);

    log_msg('Process_Account_Record : l_return_status '|| l_return_status);
    
    IF l_return_status != FND_API.G_RET_STS_SUCCESS
    THEN
      IF l_msg_count > 0
      THEN
        ERROR_HANDLER.Get_Message_List(l_errors_tbl);
        FOR i IN 1..l_errors_tbl.COUNT
        LOOP
          ln_msg_text := ln_msg_text||' '||l_errors_tbl(i).message_text;
        END LOOP;
      ELSE 
        ln_msg_text := l_msg_data;
      END IF;

      p_error_msg := ln_msg_text;

      log_msg('XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API returned Error.');
      RAISE e_process_exception;
    END IF;

    log_msg( 'XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API successful.');

    IF p_billdocs_rec.delivery_method = 'ePDF'
    THEN
      log_msg('Calling insert ebill Trans DTLS ..');

      Insert_ebill_trans_dtls(p_cust_doc_id  => ln_cust_doc_id,
                              p_billdocs_rec => p_billdocs_rec,
                              p_error_msg    => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;
 
      log_msg('Calling insert ebill file name dtls ..');

      Insert_ebill_file_name_dtls (p_cust_doc_id     => ln_cust_doc_id,
                                   p_document_type   => NULL, --p_document_type,
                                   p_error_msg       => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;

      log_msg('Calling insert ebill main dtls ..');

      Insert_ebill_main_dtls(p_cust_doc_id         => ln_cust_doc_id,
                             p_cust_account_id     => p_customer_info.cust_account_id,
                             p_billdocs_rec        => p_billdocs_rec,
                             p_error_msg           => p_error_msg);

      IF p_error_msg IS NOT NULL
      THEN 
        RAISE e_process_exception;
      END IF;
    END IF;
   
    p_return_status := gc_Success;

  EXCEPTION 
    WHEN OTHERS
    THEN 
      IF p_error_msg IS NULL
      THEN 
        p_error_msg := 'Error while creating the document  '|| SQLERRM ; 
      END IF;
      log_msg('error'||p_error_msg);
      p_return_status := gc_failure;
  END create_document;
-- +===================================================================+
-- | Name  : generate_report 
-- | Description     : This process generates the report output        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : 
-- +===================================================================+

  PROCEDURE generate_report(p_batch_id       IN     xx_cdh_billdocs_upload_stg.batch_id%TYPE,
                            p_error_msg      OUT    xx_cdh_billdocs_upload_stg.error_message%TYPE,
                            x_return_status  OUT    VARCHAR2)

  AS 

  CURSOR cur_rep(p_batch_id xx_cdh_billdocs_upload_stg.batch_id%TYPE, p_status In xx_cdh_billdocs_upload_stg.record_status%TYPE)
  IS 
  SELECT *
  FROM xx_cdh_billdocs_upload_stg xamp
  WHERE batch_id           = p_batch_id
  AND xamp.record_status   = p_status
  ;

  ln_header_rec          NUMBER := 1;
  lc_line                VARCHAR2(4000) := NULL;
  lc_header              VARCHAR2(4000) := NULL;
  lc_head_line           VARCHAR2(4000) := NULL;
  lc_customer_name       hz_cust_accounts.account_name%TYPE := NULL;
   
  BEGIN 

    x_return_status := NULL;

    log_msg('Batch id : '|| p_batch_id);

    FOR cur_rep_rec IN cur_rep(p_batch_id => p_batch_id , p_status => 'C')
    LOOP
      BEGIN

      lc_line := NULL;
      lc_customer_name := NULL;

      BEGIN 
        SELECT account_name
        INTO lc_customer_name
        FROM hz_cust_accounts
        WHERE orig_system_reference = lpad(to_char(cur_rep_rec.aops_customer_number),8,0)||'-'||'00001-A0';
      EXCEPTION 
        WHEN OTHERS 
        THEN 
          log_msg('Customet name not found ..');
          lc_customer_name := NULL;
      END;

      IF ln_header_rec = 1
      THEN 
        log_msg('Processing successful records ..');
        fnd_file.put_line(fnd_file.output, '*****************************************************REPORT FOR SUCCESSFUL RECORDS ********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        ln_header_rec := 2;

        lc_header := LPAD('AOPS Customer Number',  22, ' ')||chr(9)||
                     LPAD('Customer Name',  25, ' ')||chr(9)||
                     LPAD('MBS DOC ID', 10, ' ')||chr(9)||
                     LPAD('Paydoc',  8, ' ')||chr(9)||
                     LPAD('Delivery Method',  16, ' ')||chr(9)||
                     LPAD('Payment Term',  14, ' ')||chr(9);

        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := LPAD('--------------------',  22, ' ')||chr(9)||
                        LPAD('---------------',  25, ' ')||chr(9)||
                        LPAD('-----------',  10, '-')||chr(9)||
                        LPAD('-----------',  10, '-')||chr(9)||
                        LPAD('--------------',18, '-')||chr(9)||
                        LPAD('-----------',  14, '-')||chr(9);
        fnd_file.put_line(fnd_file.output , lc_head_line);
      END IF;

      lc_line := LPAD(cur_rep_rec.aops_customer_number,20, ' ')||chr(9)||
                 LPAD(lc_customer_name,25, ' ')||chr(9)||
                 LPAD(cur_rep_rec.mbs_doc_id,8, ' ')||chr(9)||
                 LPAD(cur_rep_rec.paydoc,6, ' ')||chr(9)||
                 LPAD(cur_rep_rec.delivery_method,20, ' ')||chr(9)||
                 LPAD(cur_rep_rec.payment_term,23, ' ')||chr(9)
                 ;
      fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN 
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_rep_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    ln_header_rec := 1;

    FOR cur_err_rec IN cur_rep(p_batch_id => p_batch_id , p_status => 'E')
    LOOP
      BEGIN

      lc_line := NULL;

      lc_customer_name := NULL;

      BEGIN 
        SELECT account_name
        INTO lc_customer_name
        FROM hz_cust_accounts
        WHERE orig_system_reference = lpad(to_char(cur_err_rec.aops_customer_number),8,0)||'-'||'00001-A0';
      EXCEPTION 
        WHEN OTHERS 
        THEN 
          log_msg('Customet name not found ..');
          lc_customer_name := NULL;
      END;

      IF ln_header_rec = 1
      THEN 
        log_msg('Processing Failed records ..');
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, '*****************************************************REPORT FOR FAILED RECORDS ********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        lc_header := LPAD('AOPS Customer Number',  22, ' ')||chr(9)||
                     LPAD('Customer Name',  25, ' ')||chr(9)||
                     LPAD('MBS DOC ID', 10, ' ')||chr(9)||
                     LPAD('Paydoc',  8, ' ')||chr(9)||
                     LPAD('Delivery Method',  16, ' ')||chr(9)||
                     LPAD('Payment Term',  14, ' ')||chr(9)||chr(9)||
                     RPAD('Error Message','16',' ')||CHR(9);

        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := LPAD('---------------------',  22, ' ')||chr(9)||
                        LPAD('---------------',  25, ' ')||chr(9)||
                        LPAD('-----------',  10, '-')||chr(9)||
                        LPAD('-----------',  10, '-')||chr(9)||
                        LPAD('--------------',18, '-')||chr(9)||
                        LPAD('-----------',  14, '-')||chr(9)||chr(9)||
                        RPAD('----------',18, '-')||CHR(9);

        fnd_file.put_line(fnd_file.output , lc_head_line);
        ln_header_rec := 2;
        fnd_file.put_line(fnd_file.output , chr(10));
      END IF;
 
      lc_line := LPAD(cur_err_rec.aops_customer_number,20, ' ')||chr(9)||
                 LPAD(NVL(lc_customer_name,' '),25, ' ')||chr(9)||
                 LPAD(cur_err_rec.mbs_doc_id,8, ' ')||chr(9)||
                 LPAD(cur_err_rec.paydoc,6, ' ')||chr(9)||
                 LPAD(cur_err_rec.delivery_method,20, ' ')||chr(9)||
                 LPAD(cur_err_rec.payment_term,23, ' ')||chr(9)||chr(9)||
                 cur_err_rec.error_message||CHR(9)
                 ;
       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN 
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_err_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    x_return_status := gc_success;
   
  EXCEPTION 
    WHEN OTHERS
    THEN 
      x_return_status := gc_failure;
      p_error_msg     := 'Error while updating the staging table '||SQLERRM;
      log_msg(p_error_msg);
  END generate_report;

  PROCEDURE extract(x_retcode         OUT NOCOPY     NUMBER,
                    x_errbuf          OUT NOCOPY     VARCHAR2)
  IS
  -- +===================================================================+
  -- | Name  : extract
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records and process them via Oracle API         |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+

 
  CURSOR lcu_billdocs(p_batch_id       IN xx_cdh_billdocs_upload_stg.batch_id%TYPE, 
                      p_status         IN xx_cdh_billdocs_upload_stg.record_status%TYPE)                    
  IS 
  SELECT *
  FROM xx_cdh_billdocs_upload_stg
  WHERE batch_id     = p_batch_id
  AND record_status  = NVL(p_status, record_status)
  Order BY aops_customer_number;

  TYPE t_pay_tab IS TABLE OF lcu_billdocs%ROWTYPE INDEX BY PLS_INTEGER;
  l_billdocs_tab               t_pay_tab;
  ln_batch_id             Number;
  ln_user_id              fnd_user.user_id%TYPE;
  lc_user_name            fnd_user.user_name%TYPE;
  lc_debug_flag           VARCHAR2(1) := NULL;
  lc_return_status        VARCHAR2(10);
  ln_org_id               NUMBER := NULL;
  lc_update_comments      VARCHAR2(1) := NULL;

  lc_cust_acct_info       hz_cust_accounts%ROWTYPE := NULL;
  lc_payment_term_info    ra_terms%ROWTYPE := NULL;

  ln_successful_records   NUMBER := 0;
  ln_failed_records       NUMBER := 0;
  lc_error_message        VARCHAR2(4000) := NULL;
  lc_doc_type             VARCHAR2(200);

  e_process_exception     EXCEPTION;
  
  BEGIN
    -- Get the Debug flag
    BEGIN
     SELECT xftv.target_value1
     INTO lc_debug_flag
     FROM xx_fin_translatedefinition xft,
          xx_fin_translatevalues xftv
     WHERE xft.translate_id    = xftv.translate_id
     AND xft.enabled_flag      = 'Y'
     AND xftv.enabled_flag     = 'Y'
     AND xft.translation_name  = 'XXOD_CDH_MASS_UPLOAD'
     AND xftv.source_value1    = 'Bill Docs';

    EXCEPTION 
      WHEN OTHERS
      THEN 
        lc_debug_flag := 'N';
    END;

    IF(lc_debug_flag = 'Y')
    THEN
      g_debug_flag := TRUE;
    ELSE
      g_debug_flag := FALSE;
    END IF; 

    ln_user_id := fnd_global.user_id;
    ln_org_id  := fnd_global.org_id;

    log_msg('Getting the user name ..');

    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log ,'Purge all the successfull records from staging table for USER :'||lc_user_name);

    DELETE FROM xx_cdh_billdocs_upload_stg
    WHERE record_status = 'C'
    AND created_by = ln_user_id;

    fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Records deleted from staging table');

    COMMIT;

    fnd_file.put_line(fnd_file.log, 'Remove duplicate records if AOPS Number and Paydoc flag is set to Y  ..');

    DELETE FROM xx_cdh_billdocs_upload_stg a
    WHERE EXISTS ( SELECT 1
                   FROM xx_cdh_billdocs_upload_stg b
                   WHERE aops_customer_number = a.aops_customer_number
                   AND a.paydoc = b.paydoc
                   AND b.paydoc = 'Y'
                   AND record_status = a.record_status
                   AND ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0 
    THEN 
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Paydoc Duplicate Records deleted from staging table');
    END IF;

    fnd_file.put_line(fnd_file.log, 'Remove duplicate records if any ....');

    DELETE FROM xx_cdh_billdocs_upload_stg a
    WHERE EXISTS ( SELECT 1
                   FROM xx_cdh_billdocs_upload_stg b
                   WHERE aops_customer_number = a.aops_customer_number
                   AND a.paydoc = b.paydoc
                   and a.mbs_doc_id = b.mbs_doc_id
                   and a.delivery_method = b.delivery_method
                   AND record_status = a.record_status
                   AND ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0 
    THEN 
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Duplicate Records deleted from staging table');
    END IF;

    log_msg('Gettting the next batch id .............');

    SELECT xx_cdh_billdocs_batch_s.NEXTVAL
    INTO ln_batch_id
    FROM DUAL;

    fnd_file.put_line(fnd_file.log, 'Batch id      :'|| ln_batch_id);
    fnd_file.put_line(fnd_file.log, 'session_id    :'||  fnd_global.session_id);
    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);
    fnd_file.put_line(fnd_file.log, 'org id        :'||  ln_org_id);

    fnd_file.put_line(fnd_file.log, 'Update the batch id in stg table for Used id :'|| ln_user_id);

    UPDATE xx_cdh_billdocs_upload_stg
    SET batch_id = ln_batch_id
    WHERE created_by = ln_user_id
    AND   record_status = 'N';

    fnd_file.put_line(fnd_file.log ,'Number of records Updated for user : '|| ln_user_id || ' with batch id :'|| ln_batch_id ||' :'||SQL%ROWCOUNT);

    COMMIT;

    set_context;

    OPEN lcu_billdocs(p_batch_id => ln_batch_id,
                      p_status   => 'N');
    LOOP
     FETCH lcu_billdocs 
     BULK COLLECT INTO l_billdocs_tab Limit 1000;

     fnd_file.put_line(fnd_file.log, 'Total number of payment records :'||l_billdocs_tab.COUNT);
     log_msg('Total number of payment records :'||l_billdocs_tab.COUNT);
     
     IF (l_billdocs_tab.COUNT > 0)
     THEN
       FOR i_index IN l_billdocs_tab.FIRST .. l_billdocs_tab.LAST
       LOOP
         BEGIN
           lc_return_status      := NULL;
           lc_error_message      := NULL;
           lc_doc_type           := NULL;
           lc_cust_acct_info     := NULL;
           lc_payment_term_info  := NULL;

           log_msg(' Processing document for AOPS customer number ..'|| l_billdocs_tab(i_index).aops_customer_number);

           lc_return_status := get_customer_details(p_aops_cust_number   => l_billdocs_tab(i_index).aops_customer_number,
                                                    p_customer_info      => lc_cust_acct_info,
                                                    p_error_msg          => lc_error_message);
           IF (lc_return_status != gc_success)
           THEN
            RAISE e_process_exception;
           END IF;
 
           IF l_billdocs_tab(i_index).paydoc = 'Y'
           THEN
             log_msg(' Check if the active pay document exists ..if so , end DATE them ..');
             lc_return_status := end_date_existing_doc(p_aops_customer_number => l_billdocs_tab(i_index).aops_customer_number,
                                                       p_cust_acct_id         => lc_cust_acct_info.cust_account_id,
                                                       p_end_date             => (l_billdocs_tab(i_index).request_start_date)-1,
                                                       p_error_msg            => lc_error_message);
           END IF;

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          log_msg('calling the payment term info ..');

          lc_return_status := get_payment_term_info(p_payment_term     =>  l_billdocs_tab(i_index).payment_term,
                                                    p_payment_term_info => lc_payment_term_info,
                                                    p_error_msg         => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          log_msg('calling the get document type info ..');

          lc_return_status := get_document_type(p_document_id  =>  l_billdocs_tab(i_index).mbs_doc_id,
                                                p_doc_type     =>  lc_doc_type,
                                                p_error_msg    =>  lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;
    
          log_msg('Calling create document to create the paydoc  ..');

          Create_document( p_billdocs_rec        => l_billdocs_tab(i_index),
                           p_payment_term_info   => lc_payment_term_info,
                           p_customer_info       => lc_cust_acct_info,
                           p_document_type       => lc_doc_type,
                           p_return_status       => lc_return_status,
                           p_error_msg           => lc_error_message);

          IF lc_return_status != gc_success
          THEN 
            RAISE e_process_exception;
          END IF;

          update_stg_table(p_record_id      => l_billdocs_tab(i_index).record_id,
                           p_customer_number => l_billdocs_tab(i_index).aops_customer_number,
                           p_status         => 'C',
                           p_batch_id       => ln_batch_id,
                           p_error_msg      => lc_error_message,
                           x_return_status  => lc_return_status);
 
          ln_successful_records :=  ln_successful_records +1 ;

          log_msg('lc_update_comments '|| lc_update_comments);

          log_msg('Commiting the record ...');
          COMMIT;

          EXCEPTION 
            WHEN others 
            THEN 
              IF lc_error_message IS NULL
              THEN
                lc_error_message := 'Unable to process ..'||SQLERRM;
              END IF;
              fnd_file.put_line(fnd_file.log,lc_error_message);

              ln_failed_records := ln_failed_records + 1;

              log_exception( p_error_location     =>  'XX_AR_MASS_APPLY_PKG.EXTRACT'
                            ,p_error_msg         =>  lc_error_message);
              x_retcode := 2;
              ROLLBACK; 

              update_stg_table(p_record_id      => l_billdocs_tab(i_index).record_id,
                               p_customer_number => l_billdocs_tab(i_index).aops_customer_number,
                               p_batch_id       => ln_batch_id,
                               p_status         => 'E',
                               p_error_msg      => lc_error_message,
                               x_return_status  => lc_return_status);

          END;
          COMMIT ;
        END LOOP;
      END IF;
    EXIT WHEN l_billdocs_tab.COUNT = 0;
   END LOOP;

   CLOSE lcu_billdocs;
  
   COMMIT;

   fnd_file.put_line(fnd_file.log , 'Total Successfull records ..'|| ln_successful_records );
   fnd_file.put_line(fnd_file.log , 'Total failed records ..'|| ln_failed_records );

   log_msg('Calling generate report for batch id :'|| ln_batch_id );

   generate_report(p_batch_id       => ln_batch_id,
                   p_error_msg      => lc_error_message,
                   x_return_status  => lc_return_status);

  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      IF lc_error_message IS NULL
      THEN
        lc_error_message := 'Unable to process the records'||SQLERRM;
      END IF;
    
      fnd_file.put_line(fnd_file.log,lc_error_message);
      log_exception ( p_error_location     =>  'XX_AR_MASS_APPLY_PKG.EXTRACT'
                     ,p_error_msg         =>  lc_error_message);
      x_retcode := 2;  
      COMMIT;
  END extract;
END XX_CDH_BILLDOCS_UPLOAD_PKG;

/

Sho err


