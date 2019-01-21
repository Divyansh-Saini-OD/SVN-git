CREATE OR REPLACE PACKAGE BODY xx_od_irec_receipts_attach_pkg
AS
-- +=============================================================================================+
-- |                            Office Depot                                                     |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XX_OD_IREC_RECEIPTS_ATTACH_PKG.pkb                                           |
-- | Description  : This package is used to add the attachment to the receipt, call the BPEL     |
-- |                service and get the confirmation number                                      |
-- |                                                                                             |
-- |Type        Name                       Description                                           |
-- |=========   ===========                ===================================================   |
-- |PROCEDURE   attach_file                This procedure will add the attachment to the receipt |
-- |                                                                                             |
-- |PROCEDURE   call_ach_epay_webservice   This Procedure will call the BPEL service and get back|
-- |                                       the confirmation number                               |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author             Remarks                                        |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  20-JUN-2012     Suraj Charan        Initial draft version                          |
-- |1.1       24-Oct-2012     Jay Gupta            Changes for SOA Error                         |
-- |1.12      18-Jan-2013  Gaurav Agarwal       For SIT02 pointing SOA to Dev01                  |
-- |1.13      23-Jan-2013  Gaurav Agarwal       Changed for p_status var initialize              |
-- |1.2       17-Apr-2013  Jay Gupta            Change if email_address is null                  |
-- |1.14      03-Apr-2013  Suraj Charan         Attachment sent as BLOB                          |
-- |2.0       30-Oct-2013  Sridevi K            R12 upgrade - host pointed to soasit01           |
-- |2.1       12-Nov-2013  Sridevi K            R12 upgrade - Added IF for DEV02 hosturl         |
-- |2.2       16-Oct-2014  Sridevi K            Modifications for SOA request and host URL       |
-- |3.0       4-MAR-2015   Sridevi K            Modifications for CR1120                         |
-- |3.1       29-JUN-2016  Madhan Sanjeevi	    Modified for Defect# 37794                       |                                                                                             |
-- +=============================================================================================+

   -- +==================================================================================================+
-- | FUNCTION       : get_msg                                                                         |
-- |                                                                                                  |
-- | DESCRIPTION    : This Function to get the error message                |
-- |                                                                                                  |
-- |                                                                                                  |
-- | PARAMETERS     :                                                                                 |
-- |    NAME                   Mode       TYPE                  DESCRIPTION                           |
-- |-------------              ----       ------------     -------------------------------            |
-- | p_app_short_name           IN        fnd_application.application_short_name%TYPE,                |
-- | p_message_name             IN        fnd_new_messages.message_name%TYPE,                         |
-- | p_token_tbl                IN        error_handler.token_tbl_type            |
-- |                DEFAULT error_handler.g_miss_token_tbl                  |
-- +==================================================================================================+
   FUNCTION get_msg (
      p_app_short_name   IN   fnd_application.application_short_name%TYPE,
      p_message_name     IN   fnd_new_messages.message_name%TYPE,
      p_token_tbl        IN   error_handler.token_tbl_type
            DEFAULT error_handler.g_miss_token_tbl
   )
      RETURN fnd_new_messages.MESSAGE_TEXT%TYPE
   IS
   BEGIN
      -- Setting message name for the message
      fnd_message.set_name (application      => p_app_short_name,
                            NAME             => p_message_name
                           );

      IF p_token_tbl.COUNT > 0
      THEN
         FOR l_loopindex IN 1 .. p_token_tbl.COUNT
         LOOP
            IF (p_token_tbl (l_loopindex).token_name IS NOT NULL)
            THEN
               -- Setting token values for the message
               fnd_message.set_token
                               (token      => p_token_tbl (l_loopindex).token_name,
                                VALUE      => p_token_tbl (l_loopindex).token_value
                               );
            END IF;
         END LOOP;
      END IF;

      --Returning the message text fetched for the FND message code passed
      RETURN (fnd_message.get);
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END get_msg;

   PROCEDURE log_msg (p_msg IN VARCHAR2)
   IS
   BEGIN
      --fnd_log.STRING (log_level => fnd_log.level_statement, module => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG', MESSAGE => p_msg );
      --Put a condition based on profile option when can the debug is on
      xx_com_error_log_pub.log_error
                          (p_return_code                 => fnd_api.g_ret_sts_success,
                           p_msg_count                   => 1,
                           p_application_name            => 'XXFIN',
                           p_program_type                => 'DEBUG'
                                                                   --------index exists on program_type
      ,
                           p_attribute15                 => p_msg
                                                                 --------index exists on attribute15
      ,
                           p_program_id                  => 0,
                           p_module_name                 => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG'
                                                                                            --------index exists on module_name
      ,
                           p_error_message               => p_msg,
                           p_error_message_severity      => 'LOG',
                           p_error_status                => 'ACTIVE',
                           p_created_by                  => fnd_global.user_id,
                           p_last_updated_by             => fnd_global.user_id,
                           p_last_update_login           => fnd_global.login_id
                          );
   END;

   PROCEDURE attach_file (
      p_confirmemail      IN       VARCHAR2,
      p_file_name         IN       VARCHAR2,
      p_cash_receipt_id   IN       NUMBER,
      p_blob_file         IN       BLOB,
      p_return_status     OUT      VARCHAR2
   )
   IS
      lv_entity_name        VARCHAR2 (30)               := 'AR_CASH_RECEIPTS';
      ln_media_id           NUMBER;
      ln_category_id        NUMBER;
      ln_seq_num            NUMBER;
      ln_datatype_id        NUMBER;
      ln_entity_id          NUMBER                       := p_cash_receipt_id;
                                                                  --45678320;
      lv_document_desc      VARCHAR2 (120)               := 'eCheck Receipt';
      lb_file               BFILE;
      lb_lob                BLOB;
      lv_procedure          VARCHAR2 (30)                := 'attach_file';
      lv_emailsubject       VARCHAR2 (200);
      lv_emailbody          VARCHAR2 (2000);
      lv_emailsubject_msg   VARCHAR2 (50)       := 'XX_AR_IREC_EMAIL_SUBJECT';
      lv_emailbody_msg      VARCHAR2 (50)          := 'XX_AR_IREC_EMAIL_BODY';
      lv_emailfrom          VARCHAR2 (200)
                               := fnd_profile.VALUE ('XX_AR_IREC_EMAIL_FROM');
      lv_emailsmtp          VARCHAR2 (200)
                         := fnd_profile.VALUE ('XX_AR_IREC_EMAIL_SMTPSERVER');
      lv_file_name          VARCHAR2 (200)
                     := fnd_profile.VALUE ('XX_AR_IREC_EMAIL_ATTACHFILENAME');
      lv_application        VARCHAR2 (30)                := 'XXFIN';
      t_msg_token_tbl       error_handler.token_tbl_type;
   BEGIN
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                      MESSAGE        => 'Start Procedure' || lv_procedure
                     );

      BEGIN
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Fetching media id'
                        );

         SELECT fnd_lobs_s.NEXTVAL
           INTO ln_media_id
           FROM DUAL;

         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'ln_media_id' || ln_media_id
                        );
         /* Global variable used in function generate_url */
         gv_fileid := ln_media_id;
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Fetching category id'
                        );

         SELECT category_id
           INTO ln_category_id
           FROM fnd_document_categories_tl
          WHERE user_name = 'Miscellaneous';

         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'ln_category_id' || ln_category_id
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Fetching datatype id'
                        );

         SELECT datatype_id
           INTO ln_datatype_id
           FROM fnd_document_datatypes
          WHERE NAME = 'FILE' AND LANGUAGE = 'US';

         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => ' ln_datatype_id' || ln_datatype_id
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Fetching sequence num '
                        );

         SELECT (NVL (MAX (seq_num), 0) + 10)
           INTO ln_seq_num
           FROM fnd_attached_documents
          WHERE entity_name = lv_entity_name
            AND pk1_value = TO_CHAR (ln_entity_id);

         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'ln_seq_num ' || ln_seq_num
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Inserting into FND_LOBS'
                        );

         INSERT INTO fnd_lobs
                     (file_id, file_name, file_content_type,
                      file_data, upload_date, expiration_date, program_name,
                      program_tag, LANGUAGE, oracle_charset, file_format
                     )
              VALUES (ln_media_id, p_file_name, 'application/pdf',
                      p_blob_file, SYSDATE, NULL, 'FNDATTCH',
                      '', 'US', 'UTF8', 'BINARY'
                     );

         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        =>    ln_category_id
                                           || ' '
                                           || ln_datatype_id
                                           || ' '
                                           || ln_media_id
                                           || ' '
                                           || lv_entity_name
                                           || ' '
                                           || p_file_name
                                           || ln_seq_num
                        );
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        => 'Calling Attachment API'
                        );
         fnd_webattch.add_attachment
                                    (seq_num                   => ln_seq_num,
                                     category_id               => ln_category_id,
                                     document_description      => lv_document_desc,
                                     datatype_id               => ln_datatype_id,
                                     text                      => NULL,
                                     file_name                 => p_file_name,
                                     url                       => NULL,
                                     function_name             => NULL,
                                     entity_name               => lv_entity_name,
                                     pk1_value                 => TO_CHAR
                                                                     (ln_entity_id
                                                                     ),
                                     pk2_value                 => NULL,
                                     pk3_value                 => NULL,
                                     pk4_value                 => NULL,
                                     pk5_value                 => NULL,
                                     media_id                  => ln_media_id,
                                     user_id                   => fnd_global.user_id
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_log.STRING (log_level      => fnd_log.level_statement,
                            module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                            MESSAGE        =>    'Error while attaching '
                                              || SQLERRM
                           );
            p_return_status := 'ERROR';
      END;

      IF p_return_status != 'ERROR'
      THEN
         p_return_status := 'SUCCESS';
         COMMIT;
      END IF;

      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                      MESSAGE        =>    'After Attachment API'
                                        || p_return_status
                     );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                      MESSAGE        =>    'Sending mail'
                                        || 'p_to               => '
                                        || p_confirmemail
                                        || 'p_from             => '
                                        || lv_emailfrom
                                        || 'p_attach_name      => '
                                        || lv_file_name
                                        || 'p_smtp_host        => '
                                        || lv_emailsmtp
                     );
      lv_emailsubject :=
                get_msg (lv_application, lv_emailsubject_msg, t_msg_token_tbl);
      lv_emailbody :=
                   get_msg (lv_application, lv_emailbody_msg, t_msg_token_tbl);
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                      MESSAGE        =>    'p_subject          => '
                                        || lv_emailsubject
                                        || 'p_text_msg         => '
                                        || lv_emailbody
                     );
      xx_od_irec_receipts_attach_pkg.send_mail
                                          (p_to               => p_confirmemail,
                                           p_from             => lv_emailfrom,
                                           p_subject          => lv_emailsubject,
                                           p_text_msg         => lv_emailbody,
                                           p_attach_name      => lv_file_name,
                                           p_attach_mime      => 'application/pdf',
                                           p_attach_blob      => p_blob_file,
                                           p_smtp_host        => lv_emailsmtp
                                          );
      fnd_log.STRING (log_level      => fnd_log.level_statement,
                      module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                      MESSAGE        => 'End Procedure' || lv_procedure
                     );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status := 'ERROR';
         fnd_log.STRING (log_level      => fnd_log.level_statement,
                         module         => 'XX_OD_IREC_RECEIPTS_ATTACH_PKG',
                         MESSAGE        =>    'End Procedure'
                                           || lv_procedure
                                           || 'Error'
                                           || SQLCODE
                                           || '-'
                                           || SQLERRM
                        );
   END;

   FUNCTION generate_url
      RETURN VARCHAR2
   IS
   BEGIN
      lv_url :=
         fnd_gfm.construct_download_url (fnd_web_config.gfm_agent, gv_fileid);
      RETURN lv_url;
   END;

   PROCEDURE call_ach_epay_webservice (
      p_businessid                IN       NUMBER,
      p_login                     IN       VARCHAR2,
      p_password                  IN       VARCHAR2,
      p_product                   IN       VARCHAR2,
      p_bankaccounttype           IN       VARCHAR2,
      p_routingnumber             IN       VARCHAR2,
      p_bankaccountnumber         IN       VARCHAR2,
      p_accountholdername         IN       VARCHAR2,
      p_accountaddress1           IN       VARCHAR2,
      p_accountaddress2           IN       VARCHAR2,
      p_accountcity               IN       VARCHAR2,
      p_accountstate              IN       VARCHAR2,
      p_accountpostalcode         IN       VARCHAR2,
      p_accountcountrycode        IN       VARCHAR2,
      p_nachastandardentryclass   IN       VARCHAR2,
      p_individualidentifier      IN       VARCHAR2,
      p_companyname               IN       VARCHAR2,
      p_creditdebitindicator      IN       VARCHAR2,
      p_requestedpaymentdate      IN       VARCHAR2,
      p_billingaccountnumber      IN       VARCHAR2,
      p_remitamount               IN       VARCHAR2,
      p_remitfee                  IN       VARCHAR2,
      p_feewaiverreason           IN       VARCHAR2,
      p_transactioncode           IN       VARCHAR2,
      p_emailaddress              IN       VARCHAR2,
      p_remitfieldvalue           IN       VARCHAR2,
      p_messagecode               OUT      NUMBER,
      p_messagetext               OUT      VARCHAR2,
      p_confirmation_number       OUT      VARCHAR2,
      p_status                    OUT      VARCHAR2
   )
   IS
      lv_soap_request              VARCHAR2 (32500);
      lv_soap_respond              VARCHAR2 (32500);
      lv_response_temp             VARCHAR2 (128);
      lv_response_text             VARCHAR2 (128);
      lv_result_xml_node           VARCHAR2 (128);
      lv_resultstatus              VARCHAR2 (100);
      http_req                     UTL_HTTP.req;
      http_resp                    UTL_HTTP.resp;
      resp                         XMLTYPE;
      i                            INTEGER;
      ln_message_text1             NUMBER;
      ln_message_text2             NUMBER;
      ln_message_code1             NUMBER;
      ln_message_code2             NUMBER;
      lv_hosturl                   VARCHAR2 (200)
                                      := fnd_profile.VALUE ('XX_OD_IREC_URL');
      lv_businessid                xx_fin_translatevalues.target_value1%TYPE;
      lv_login                     xx_fin_translatevalues.target_value1%TYPE;
      lv_password                  xx_fin_translatevalues.target_value1%TYPE;
      lv_nachastandardentryclass   xx_fin_translatevalues.target_value1%TYPE;
      lv_product                   xx_fin_translatevalues.target_value1%TYPE;
      lv_emailaddress              fnd_user.email_address%TYPE;
      lv_ns_map                    VARCHAR2 (200)
         := 'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/", xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"';
      lv_xpath                     VARCHAR2 (200)
                := '/env:Envelope/env:Body/ns1:bank-payment-response/message';
      lv_ticket_no                 VARCHAR2 (30);
      lv_summary                   VARCHAR2 (30);
      lv_customer_number           hz_cust_accounts.account_number%TYPE;
      lv_country_code              hz_parties.country%TYPE;
      lv_address1                  hz_parties.address1%TYPE;
      lv_address2                  hz_parties.address2%TYPE;
      lv_city                      hz_parties.city%TYPE;
      lv_postal_code               hz_parties.postal_code%TYPE;
      lv_state                     hz_parties.state%TYPE;
      lv_soa_username              VARCHAR2 (100);
      lv_soa_passowrd              VARCHAR2 (1000);
      lv_soa_dec_password          VARCHAR2 (1000);
      p_messagetext1               VARCHAR2 (2000);
      p_messagecode1               NUMBER;                ---VARCHAR2(2000) ;
	  lv_acct_hold_name_length     NUMBER;                -- Added for Defect# 37794
   BEGIN
      p_status := fnd_api.g_ret_sts_success;                     --deep v1.13
      log_msg (' inside SOA Call');
      log_msg (' inside SOA Call 1');
      BEGIN
         SELECT xftv.target_value1
           INTO lv_nachastandardentryclass
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND UPPER (xftv.source_value1) = 'NACHASTANDARDENTRYCLASS'
            AND UPPER (xftv.source_value2) = UPPER (p_bankaccounttype)
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
                     'Error in getting nacha standard entry class' || SQLERRM;
      END;
	  --Defect# 37794 code change starts here
	  BEGIN
	  SELECT xftv.target_value1 
	    INTO lv_acct_hold_name_length
        FROM XX_FIN_TRANSLATEDEFINITION  xftd,
             XX_FIN_TRANSLATEVALUES xftv
      WHERE xftd.translation_name='XX_IREC_ACT_HOL_NAME_LENG'
	    AND UPPER (xftv.source_value1) = 'ACH'
        AND xftd.translate_id=xftv.translate_id
		AND SYSDATE BETWEEN xftv.start_date_active
                        AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
                     'Error in getting translation setup value XX_IREC_ACT_HOL_NAME_LENG ' || SQLERRM;
      END;
	  --Defect# 37794 code change ends here

      BEGIN
         log_msg (' inside SOA Call 2');

         SELECT xftv.target_value1
           INTO lv_product
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND UPPER (xftv.source_value1) = 'PRODUCT'
            AND UPPER (xftv.source_value2) = UPPER (p_product)
            --'OD (US) iReceivables External' --Need to pass dynamic to do
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
                  p_status
               || ' - '
               || 'Error in getting Product from translation Table'
               || SQLERRM;
      END;

      log_msg (' inside SOA Call 3');

      BEGIN
         SELECT DECODE
                   (INSTR (NVL (email_address, 'XXX'), '@'),
                    0, 'no_customer_email@officedepot.com',
                    email_address
                   )                                -- Jay Gupta email_address
           INTO lv_emailaddress
           FROM fnd_user
          WHERE user_id = p_emailaddress;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
               p_status || ' - ' || 'Error in fetching email address'
               || SQLERRM;
      END;

      log_msg (' inside SOA Call 4');

      BEGIN
         SELECT hzca.account_number, hzp.country, hzp.address1,
                hzp.address2, hzp.city, hzp.postal_code, hzp.state
           INTO lv_customer_number, lv_country_code, lv_address1,
                lv_address2, lv_city, lv_postal_code, lv_state
           FROM hz_cust_accounts hzca, hz_parties hzp
          WHERE hzca.cust_account_id = p_billingaccountnumber
            AND hzp.party_id = hzca.party_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
                  p_status
               || ' - '
               || 'Error in getting account number/address details'
               || SQLERRM;
      END;

      -- To get the SOA username and password
      BEGIN
         SELECT xftv.target_value1
           INTO lv_soa_username
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND UPPER (xftv.source_value1) = UPPER ('soa_username')
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
               p_status || ' - ' || 'Error in getting SOA Username'
               || SQLERRM;
      END;

      -- to get SOA encrypted password
      BEGIN
         SELECT xftv.target_value1
           INTO lv_soa_passowrd
           FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'ACH_ECHECK_DETAILS'
            AND UPPER (xftv.source_value1) = UPPER ('soa_password')
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active
                            AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
                  p_status
               || ' - '
               || 'Error in getting SOA encrypted password'
               || SQLERRM;
      END;

      BEGIN
         SELECT xx_encrypt_decryption_toolkit.decrypt (lv_soa_passowrd)
           INTO lv_soa_dec_password
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status :=
               p_status || ' - ' || 'Error indecrypting the password'
               || SQLERRM;
      END;

      log_msg (' inside SOA Call 5');
      lv_soap_request :=
            ' 

<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"  xmlns:ns1="http://www.princetonecom.com/connect/bankpaymentrequest1">



<soap:Header>

<wsse:Security  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">

<wsse:UsernameToken>

<wsse:Username>'
         || lv_soa_username
         || '</wsse:Username>

<wsse:Password>'
         || lv_soa_dec_password
         || '</wsse:Password>

<!--   <wsse:Username>development</wsse:Username>

<wsse:Password>development123</wsse:Password>   -->



</wsse:UsernameToken>

</wsse:Security>

</soap:Header>



<soap:Body>

<ns1:bank-payment-request>

<ns1:identity>

<ns1:business-id>'
         || 0                                                  --lv_businessid
         || '</ns1:business-id>

<ns1:login>'
         || '_'                                                     --lv_login
         || '</ns1:login>

<ns1:password>'
         || '_'                                                  --lv_password
         || '</ns1:password>

</ns1:identity>



<ns1:bank-account>

<ns1:bank-account-type>'
         || p_bankaccounttype
         || '</ns1:bank-account-type>

<ns1:routing-number>'
         || p_routingnumber
         || '</ns1:routing-number>

<ns1:bank-account-number>'
         || p_bankaccountnumber
         || '</ns1:bank-account-number>

<ns1:account-holder-name>'
    --     || p_accountholdername -- Commented based on the defect# 37794
         || substr(p_accountholdername,1,lv_acct_hold_name_length) -- Added based on the defect# 37794
         || '</ns1:account-holder-name>

<ns1:account-address-1>'
         || lv_address1
         || '</ns1:account-address-1>

<ns1:account-city>'
         || lv_city
         || '</ns1:account-city>

<ns1:account-state>'
         || lv_state
         || '</ns1:account-state>

<ns1:account-postal-code>'
         || lv_postal_code
         || '</ns1:account-postal-code>

<ns1:account-country-code>'
         || lv_country_code
         || '</ns1:account-country-code>

</ns1:bank-account>

<ns1:nacha-standard-entry-class>'
         || lv_nachastandardentryclass
         || '</ns1:nacha-standard-entry-class>

<ns1:individual-identifier>'
         || p_individualidentifier
         || '</ns1:individual-identifier>

<ns1:credit-debit-indicator>'
         || p_creditdebitindicator
         || '</ns1:credit-debit-indicator>

<ns1:requested-payment-date>'
         || p_requestedpaymentdate
         || '</ns1:requested-payment-date>

<ns1:remittance>

<ns1:billing-account>

<ns1:billing-account-number>'
         || lv_customer_number
         || '</ns1:billing-account-number>

<!-- <ns1:billing-division-id>null</ns1:billing-division-id> -->

</ns1:billing-account>

<ns1:remit-amount>'
         || p_remitamount
         || '</ns1:remit-amount>

<ns1:remit-fee>'
         || p_remitfee
         || '</ns1:remit-fee>

<!--

<ns1:payment-remit-field>

<ns1:value>'
         || p_remitfieldvalue
         || '</ns1:value>

</ns1:payment-remit-field>

<ns1:payment-remit-field>

<ns1:value>12341</ns1:value>

</ns1:payment-remit-field>

-->

</ns1:remittance>

<ns1:product>'
         || lv_product
         || '</ns1:product>

<ns1:transaction-code>'
         || p_transactioncode
         || '</ns1:transaction-code>

<ns1:email-address>'
         || lv_emailaddress
         || '</ns1:email-address>

</ns1:bank-payment-request>

</soap:Body>

</soap:Envelope> ';
      log_msg (' inside SOA Call 6');
      /*
      SELECT NAME INTO lv_hostname FROM v$database;
      IF (lv_hostname = 'GSIDEV01') THEN
      lv_hosturl   := 'soadev01';
      END IF;
      IF (lv_hostname = 'GSIDEV02') THEN
      lv_hosturl   := 'soauat01';
      END IF;
      IF (lv_hostname = 'GSISIT01') THEN
      lv_hosturl   := 'soasit01';
      END IF;
      IF (lv_hostname = 'GSIUATGB') THEN
      lv_hosturl   := 'soauat01';
      END IF;
      IF (lv_hostname = 'GSISIT02') THEN
      lv_hosturl := 'soasit01';
      END IF;
      IF (lv_hostname = 'GSIPRFGB') THEN
      lv_hosturl   := 'soaprf01';
      END IF;
      IF (lv_hostname = 'GSIPRDGB') THEN
      lv_hosturl   := 'soaprd01';
      END IF;
      */
      log_msg (' inside SOA Call 7' || lv_hosturl);

      BEGIN
         http_req := UTL_HTTP.begin_request (lv_hosturl, 'POST', 'HTTP/1.1');
         /*
         http_req := UTL_HTTP.begin_request (
         --'http://172.20.4.118:80/orabpel/default/BEWorkDayOracleErrorReportUtility'
         --'http://soadev01.na.odcorp.net/soa-infra/services/finance_rt/CreateBankACHPaymentReqABCImpl/CreateBankACHPayment' , 'POST' , 'HTTP/1.1' );
         'http://' || lv_hosturl
         -- || '.na.odcorp.net/soa-infra/services/finance_rt/CreateBankACHPaymentsReqABCImpl/createbankachpaymentsreqabcimplprocess_client_ep',
         --new url
         || '.na.odcorp.net:80/soa-infra/services/finance_rt/CreateBankACHPaymentsReqABCS/createbankachpaymentsreqabcsprocess_client_ep?WSDL', 'POST', 'HTTP/1.1' );
         */
         UTL_HTTP.set_header (http_req, 'Content-Type', 'text/xml');
         -- since we are dealing with plain text in XML documents
         UTL_HTTP.set_header (http_req,
                              'Content-Length',
                              LENGTH (lv_soap_request)
                             );
         UTL_HTTP.set_header (http_req, 'SOAPAction', '');
         -- required to specify this is a SOAP communication
         UTL_HTTP.write_text (http_req, lv_soap_request);
         http_resp := UTL_HTTP.get_response (http_req);
         UTL_HTTP.read_text (http_resp, lv_soap_respond);
         UTL_HTTP.end_response (http_resp);
         resp := XMLTYPE.createxml (lv_soap_respond);
         --  DBMS_OUTPUT.put_line(soap_respond);
         DBMS_OUTPUT.put_line (   'Response> status_code: "'
                               || http_resp.status_code
                               || '"'
                              );
         log_msg (' inside SOA Call 8');
         log_msg (   ' inside SOA Call 8.A http_resp.status_code='
                  || http_resp.status_code
                 );

         IF (http_resp.status_code = 200)
         THEN
            -- Create XML type from response text         l_resp_xml := XMLType.createXML(l_clob_response);
            -- Clean SOAP header         SELECT EXTRACT(l_resp_xml, 'Envelope/Body/node()', l_NAMESPACE_SOAP) INTO l_resp_xml FROM dual;
            -- Extract City         l_result_XML_node := 'GetCityForecastByZIPResponse/GetCityForecastByZIPResult/';
            --         SELECT EXTRACTVALUE(l_resp_xml, l_result_XML_node || 'City[1]', 'xmlns="http://ws.cdyne.com/WeatherWS/"') INTO l_response_city FROM dual;
            --         SELECT EXTRACTVALUE(l_resp_xml, l_result_XML_node || 'ForecastResult[1]/Forecast[1]/Date[1]', 'xmlns="http://ws.cdyne.com/WeatherWS/"') INTO l_response_date FROM dual;
            FOR lcntr IN 1 .. 100
            LOOP
               BEGIN
                  -- BEGIN
                  SELECT NVL
                            (EXTRACTVALUE
                                (resp,
                                    lv_result_xml_node
                                 || '//message['
                                 || lcntr
                                 || ']/message-code',
                                 'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'
                                ),
                             -99
                            )
                    --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')
                  INTO   p_messagecode
                    FROM DUAL;

                  IF p_messagecode = -99
                  THEN
                     EXIT;
                  END IF;

                  SELECT SUBSTR
                            (EXTRACTVALUE
                                (resp,
                                    lv_result_xml_node
                                 || '//message['
                                 || lcntr
                                 || ']/message-text',
                                 'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'
                                ),
                             1,
                             2000
                            )
                    --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')
                  INTO   p_messagetext
                    FROM DUAL;

                  -- To concatenate the message text
                  p_messagetext1 := p_messagetext1 || ' ' || p_messagetext;
                  p_messagecode1 := p_messagecode;
                  log_msg (   ' inside SOA Call 8.B p_messagecode1='
                           || p_messagecode1
                           || '  p_messagetext1='
                           || p_messagetext1
                          );                                          -- Suraj
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     log_msg (' inside SOA Call 9');                 -- Suraj
                     p_status := p_status || ' - ' || fnd_api.g_ret_sts_error;
                                                                       --deep
               --DBMS_OUTPUT.put_line ('### MSG ERROR=' || SQLERRM);
               END;
            END LOOP;

            log_msg (' inside SOA Call 9.A');                         -- Suraj

            BEGIN
               SELECT EXTRACTVALUE
                         (resp,
                          lv_result_xml_node || '//confirmation-number',
                          'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'
                         )
                 --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')
               INTO   p_confirmation_number
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_status := fnd_api.g_ret_sts_error;                 --deep
                  log_msg (   ' inside SOA Call 9.B p_confirmation_number='
                           || p_confirmation_number
                          );                                          -- Suraj
            END;

            p_messagetext := SUBSTR (p_messagetext1, 1, 1000);
            p_messagecode := p_messagecode1;
            -- Suraj deep
            --p_status := 'SUCCESS';
            log_msg (' inside SOA Call 10 p_status=' || p_status);    -- Suraj
         -- V1.1 , aded else art for SOA Error
         ELSE
            --if http_resp.status_code = 500 then
            --p_status := 'FAILURE';
            p_status := p_status || ' - ' || fnd_api.g_ret_sts_error;  --deep
            p_messagecode := 100;
            p_messagetext :=
               'We apologize but the system is temporarily unavailable. Please try again later.';
            log_msg (   ' inside SOA Call 11 p_status='
                     || p_status
                     || ' p_messagecode='
                     || p_messagecode
                    );                                                -- Suraj
         -- END IF;
         END IF;

         log_msg (   ' inside SOA Call 11.A p_status='
                  || p_status
                  || ' p_messagecode='
                  || p_messagecode
                 );                                                   -- Suraj
         DBMS_OUTPUT.put_line (   'p_messageCode='
                               || p_messagecode
                               || '   p_messageText='
                               -- || p_messagetext
                               || '   p_confirmation_number='
                               || p_confirmation_number
                              );
      END;

      log_msg (' inside SOA Call 11.B Before SOA Call Exception');    -- Suraj
   --soap-env host url
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := p_status || ' - ' || fnd_api.g_ret_sts_error;     --deep
         log_msg (' inside SOA Call exception' || SQLERRM);
   END;

   PROCEDURE send_mail (
      p_to            IN   VARCHAR2,
      p_from          IN   VARCHAR2,
      p_subject       IN   VARCHAR2,
      p_text_msg      IN   VARCHAR2 DEFAULT NULL,
      p_attach_name   IN   VARCHAR2 DEFAULT NULL,
      p_attach_mime   IN   VARCHAR2 DEFAULT NULL,
      p_attach_blob   IN   BLOB DEFAULT NULL,
      p_smtp_host     IN   VARCHAR2,
      p_smtp_port     IN   NUMBER DEFAULT 25
   )
   AS
      l_mail_conn   UTL_SMTP.connection;
      l_boundary    VARCHAR2 (50)       := '----=*#abc1234321cba#*=';
      l_step        PLS_INTEGER         := 12000;
   -- make sure you set a multiple of 3 not higher than 24573
   BEGIN
      l_mail_conn := UTL_SMTP.open_connection (p_smtp_host, p_smtp_port);
      UTL_SMTP.helo (l_mail_conn, p_smtp_host);
      UTL_SMTP.mail (l_mail_conn, p_from);
      UTL_SMTP.rcpt (l_mail_conn, p_to);
      UTL_SMTP.open_data (l_mail_conn);
      UTL_SMTP.write_data (l_mail_conn,
                              'Date: '
                           || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                           || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
      UTL_SMTP.write_data (l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
      UTL_SMTP.write_data (l_mail_conn,
                           'Subject: ' || p_subject || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (l_mail_conn,
                           'Reply-To: ' || p_from || UTL_TCP.crlf);
      UTL_SMTP.write_data (l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
      UTL_SMTP.write_data (l_mail_conn,
                              'Content-Type: multipart/mixed; boundary="'
                           || l_boundary
                           || '"'
                           || UTL_TCP.crlf
                           || UTL_TCP.crlf
                          );

      IF p_text_msg IS NOT NULL
      THEN
         UTL_SMTP.write_data (l_mail_conn,
                              '--' || l_boundary || UTL_TCP.crlf);
         UTL_SMTP.write_data
                         (l_mail_conn,
                             'Content-Type: text/plain; charset="iso-8859-1"'
                          || UTL_TCP.crlf
                          || UTL_TCP.crlf
                         );
         UTL_SMTP.write_data (l_mail_conn, p_text_msg);
         UTL_SMTP.write_data (l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      END IF;

      IF p_attach_name IS NOT NULL
      THEN
         UTL_SMTP.write_data (l_mail_conn,
                              '--' || l_boundary || UTL_TCP.crlf);
         UTL_SMTP.write_data (l_mail_conn,
                                 'Content-Type: '
                              || p_attach_mime
                              || '; name="'
                              || p_attach_name
                              || '"'
                              || UTL_TCP.crlf
                             );
         UTL_SMTP.write_data (l_mail_conn,
                                 'Content-Transfer-Encoding: base64'
                              || UTL_TCP.crlf
                             );
         UTL_SMTP.write_data (l_mail_conn,
                                 'Content-Disposition: attachment; filename="'
                              || p_attach_name
                              || '"'
                              || UTL_TCP.crlf
                              || UTL_TCP.crlf
                             );

         FOR i IN 0 .. TRUNC ((DBMS_LOB.getlength (p_attach_blob) - 1)
                              / l_step)
         LOOP
            UTL_SMTP.write_data
               (l_mail_conn,
                UTL_RAW.cast_to_varchar2
                    (UTL_ENCODE.base64_encode (DBMS_LOB.SUBSTR (p_attach_blob,
                                                                l_step,
                                                                i * l_step + 1
                                                               )
                                              )
                    )
               );
         END LOOP;

         UTL_SMTP.write_data (l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      END IF;

      UTL_SMTP.write_data (l_mail_conn,
                           '--' || l_boundary || '--' || UTL_TCP.crlf
                          );
      UTL_SMTP.close_data (l_mail_conn);
      UTL_SMTP.quit (l_mail_conn);
   END;
END xx_od_irec_receipts_attach_pkg;
/

