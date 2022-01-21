CREATE OR REPLACE PACKAGE BODY xx_cdh_ebl_conv_paper_epdf
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CDH_EBL_CONV_PAPER_EPDF                               |
-- | Description : 1) To import account details and into BSD table          |
-- |                                                                        |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      22-NOV-2010  Devi Viswanathan      Initial version             |
-- |2.0      14-AUG-2013  Jagadeesh S           Modified procedure          |
--                                              create_ebill_contact for    | 
--                                              retrofit to R12             |
-- |3.0      22-Oct-2015  Vasu Raparla          Removed Schema References   |
--                                              for  R12.2                  |
-- +========================================================================+
-- +========================================================================+
-- | Name        : LOAD_ACCOUNT_DTLS                                        |
-- | Description : 1) To import account details and into BSD table          |
-- |                                                                        |
-- | Returns     : VARCHAR2                                                 |
-- +========================================================================+
  FUNCTION load_account_dtls( p_cust_account_id     VARCHAR2
                            , p_account_number      VARCHAR2
                            , p_customer_name       VARCHAR2
                            , p_aops_number         VARCHAR2
                            , p_zip_code            VARCHAR2
                            )
  RETURN VARCHAR2
  IS

    ln_request_id NUMBER;

  BEGIN

    SAVEPOINT upload_acct_dtls;

    fnd_file.put_line(fnd_file.LOG, '***********Begin Function load_account_dtls');

    ln_request_id := fnd_global.conc_request_id();

    --DELETE FROM xx_cdh_ebl_conv_account_dtl WHERE request_id != ln_request_id;

    /* Inserting Account details eligible for conversion into the conversion table xx_cdh_ebl_conv_account_dtl.
     */

    INSERT INTO xx_cdh_ebl_conv_account_dtl( cust_account_id
                                           , account_number
                                           , customer_name
                                           , aops_number
                                           , zip_code
                                           , request_id
                                           , program_application_id
                                           , program_id
                                           , program_update_date
                                           , last_update_date
                                           , last_updated_by
                                           , creation_date
                                           , created_by
                                           , last_update_login)
    VALUES( p_cust_account_id
          , p_account_number
          , p_customer_name
          , LPAD(p_aops_number,8,'0')
          , p_zip_code
          , ln_request_id
          , fnd_global.prog_appl_id()
          , fnd_global.conc_program_id()
          , sysdate
          , sysdate
          , fnd_global.user_id
          , sysdate
          , fnd_global.user_id
          , fnd_global.login_id);

    fnd_file.PUT_LINE(fnd_file.LOG, '***********Inserted account number: ' || p_account_number);

    COMMIT;

      RETURN 'TRUE' || 'Success';

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 'FALSE_Failed","Unexpected exception in load_account_dtls. ' || SQLERRM;

  END load_account_dtls;


-- +========================================================================+
-- | Name        : LOG_MSG                                                  |
-- | Description : 1) Procedure to print log messages based on flag value.  |
-- |                                                                        |
-- | Returns     :                                                          |
-- +========================================================================+

  PROCEDURE log_msg( p_enable_flag VARCHAR2
                   , p_log_msg     VARCHAR2)
  IS
  BEGIN

    IF p_enable_flag = 'Y' THEN

      fnd_file.put_line (fnd_file.log, p_log_msg);

    END IF;

  END;


-- +========================================================================+
-- | Name        : validate_account_login                                   |
-- | Description : 1) To validate login details and to return validation    |
-- |                  results. If account is valid then submit a concurrent |
-- |                  program to covert all the print documents to ePDF     |
-- |                                                                        |
-- | Returns     :                                                          |
-- +========================================================================+
  PROCEDURE validate_account_login( p_aops_account_number   IN VARCHAR2
                                  , p_account_name          IN VARCHAR2
                                  , p_zip_code              IN NUMBER
                                  , p_contact_first_name    IN VARCHAR2
                                  , p_contact_last_name     IN VARCHAR2
                                  , p_contact_phone_area    IN VARCHAR2
                                  , p_contact_phone         IN VARCHAR2
                                  , p_contact_phone_ext     IN VARCHAR2
                                  , p_contact_email         IN VARCHAR2
                                  , p_validate              IN VARCHAR2
                                  , x_status               OUT VARCHAR2
                                  , x_message              OUT VARCHAR2
                                  )
  IS

    ln_print_count       NUMBER;
    ln_return_code       NUMBER;
    ln_cust_account_id   NUMBER;
    ln_login_attempts    NUMBER;
    ln_user_id           NUMBER;
    ln_responsibility_id NUMBER;
    ln_application_id    NUMBER;
    lc_account_locked    VARCHAR2(200);
    lc_account_status    VARCHAR2(200);
    lc_aops_number       VARCHAR2(2000);
    lc_zip_code          VARCHAR2(2000);
    lc_account_name      VARCHAR2(4000);
    lc_proc_log          VARCHAR2(4000);

    validation_failed_exception EXCEPTION;
    request_failed_exception EXCEPTION;

    /* Cursor to get account details to validate the user
     */
    CURSOR validate_login_cur (c_aops_number VARCHAR2)
        IS
    SELECT cust_account_id
         , aops_number
         , account_locked
         , account_status
         , login_attempts
      FROM xx_cdh_ebl_conv_account_dtl
     WHERE aops_number = c_aops_number;

    /* Cursor to validate the Account in hz_cust_accounts table
     */
    CURSOR validate_login_hz_cur (c_cust_account_id NUMBER)
        IS
    SELECT cust_account_id
      FROM hz_cust_accounts HCA
     WHERE HCA.cust_account_id = c_cust_account_id
       AND HCA.status = 'A';

    /* Cursor to validate account nme/zip code
     */
    CURSOR get_acc_name_zip_cur (c_cust_account_id NUMBER)
        IS
    SELECT SUBSTR(HL.postal_code,1,5) zip_code
         , NVL(HL.address_lines_phonetic, HP.party_name) account_name
      FROM hz_cust_acct_sites_all HCAS
         , hz_cust_site_uses_all  HCSU
         , hz_cust_accounts       HCA
         , hz_parties             HP
         , hz_party_sites         HPS
         , hz_locations           HL
     WHERE HPS.party_site_id      = HCAS.party_site_id
       AND HPS.location_id        = HL.location_id
       AND HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
       AND HCAS.status            = 'A'
       AND HCSU.site_use_code     = 'BILL_TO'
       AND HCSU.status            = 'A'
       AND HCSU.primary_flag      = 'Y'
       AND HPS.status             = 'A'
       AND HCA.party_id           = HP.party_id
       AND HCA.cust_account_id    = HCAS.cust_account_id
       AND HCA.cust_account_id    = c_cust_account_id;


    /* Cursor to check if the account has any valid print documents
     */
    CURSOR get_print_doc_cur(c_cust_account_id NUMBER)
        IS
    SELECT 1
      FROM xx_cdh_cust_acct_ext_b XCEB
        ,  ego_attr_groups_v EAG
    WHERE  XCEB.cust_account_id = c_cust_account_id
      AND  XCEB.attr_group_id   = EAG.attr_group_id
      AND  XCEB.c_ext_attr3     = 'PRINT'
      AND  XCEB.c_ext_attr7     = 'Y'                      -- Direct customer
      AND  XCEB.c_ext_attr16    = 'COMPLETE'               -- Status
      AND  XCEB.c_ext_attr13    IS NULL                    -- Combo type
      AND  XCEB.d_ext_attr2     IS NULL                    -- Effective end date
      AND  XCEB.n_ext_attr17    = 0
      AND  XCEB.n_ext_attr15    IS NULL
      AND  EAG.attr_group_type  = 'XX_CDH_CUST_ACCOUNT'
      AND  EAG.attr_group_name  = 'BILLDOCS'
      AND  rownum = 1;

    CURSOR get_user_id_cur
        IS
     SELECT user_id
       FROM fnd_user
      WHERE user_name = 'ODCDH';

    CURSOR get_resp_id_cur
        IS
     SELECT responsibility_id
       FROM fnd_responsibility
      WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION';

    CURSOR get_app_id_cur
        IS
    SELECT application_id
      FROM fnd_application
     WHERE application_short_name = 'XXCNV';

  BEGIN

    /* Inserting login details into xx_cdh_ebl_conv_login_dtl table */
    lc_proc_log := 'Inserting login details into xx_cdh_ebl_conv_login_dtl table';

    IF p_aops_account_number IS NULL THEN

      x_status  := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_001'); -- Please enter your Account Number.
      RETURN;

    END IF;


    /* Save the login details entered by the user in xx_cdh_ebl_conv_login_dtl for tracking purpose
     */

    lc_proc_log := 'Inserting login details into xx_cdh_ebl_conv_login_dtl table';

    BEGIN

      INSERT INTO xx_cdh_ebl_conv_login_dtl ( aops_number
                                                  , customer_name
                                                  , zip_code
                                                  , contact_first_name
                                                  , contact_last_name
                                                  , email_address
                                                  , phone_area_code
                                                  , phone_number
                                                  , phone_extension
                                                  , last_update_date
                                                  , last_updated_by
                                                  , creation_date
                                                  , created_by
                                                  , last_update_login)
                                           VALUES ( p_aops_account_number
                                                  , p_account_name
                                                  , p_zip_code
                                                  , p_contact_first_name
                                                  , p_contact_last_name
                                                  , p_contact_email
                                                  , p_contact_phone_area
                                                  , p_contact_phone
                                                  , p_contact_phone_ext
                                                  , sysdate
                                                  , fnd_global.user_id
                                                  , sysdate
                                                  , fnd_global.user_id
                                                  , fnd_global.login_id);

  EXCEPTION

    WHEN OTHERS THEN

      x_status  := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_000') || ' at ' || lc_proc_log;
      RETURN;

  END;

  /* Open curosr to check if account_number is eligible for conversion, status is not COMPLETE/IN_PROCESS
   * and account is not locked.
   */

  lc_proc_log := ' Open curosr to checking fetch account details from AOPS Number entered by user.';

  OPEN validate_login_cur(p_aops_account_number);

  FETCH validate_login_cur INTO ln_cust_account_id
                              , lc_aops_number
                              , lc_account_locked
                              , lc_account_status
                              , ln_login_attempts;

  /* Check if the login details are entered
   */
  lc_proc_log := 'Check if the login details are entered when validation parameter is passed as (Y)';

  IF p_validate = 'Y' THEN


    /* Check if account name/zip code is entered.
     */
    lc_proc_log := 'Check if account name/zip code is entered.';

    IF (p_account_name IS NULL AND p_zip_code IS NULL) THEN

      x_status  := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_006'); -- Please enter your Account name/Zip Code.
      RETURN;

    END IF;

    /* Check if account is eligible for conversion.
     */
    lc_proc_log := 'Check if account is eligible for conversion. ';

    IF validate_login_cur%ROWCOUNT = 0 THEN

      CLOSE validate_login_cur;
      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_002'); -- Sorry, we did not recognize the account number or validation you entered.  Please try again or send an email to electronincbilling@officedepot.com with your account and phone number and we will assist you with this process.
      RETURN;

    END IF;

    CLOSE validate_login_cur;

    /* Check if account status is not COMPLETE/IN_PROCESS
     */

    lc_proc_log := 'Check if account status is not COMPLETE/IN_PROCESS. ';

    IF lc_account_status IS NOT NULL THEN    -- ('COMPLETE', 'IN_PROCESS') THEN

      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_003'); -- Conversion already completed for this account
      RETURN;

    END IF;

    /* Check if account is locked
     */

    lc_proc_log := 'Check if account is locked. ';

    IF lc_account_locked = 'Y' THEN

      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_004'); -- Account Locked.
      RETURN;

    END IF;


    /*Open cursor to check if the customer is valid in eBilling tables
     */

    lc_proc_log := 'Open cursor to check if the customer is valid in eBilling tables';

    OPEN validate_login_hz_cur(ln_cust_account_id);
    FETCH validate_login_hz_cur
     INTO ln_cust_account_id;

    IF validate_login_hz_cur%ROWCOUNT = 0 THEN

      CLOSE validate_login_hz_cur;
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_005'); -- Sorry, we did not recognize the account number you have entered.  Please try again or send an email to electronincbilling@officedepot.com with your account and phone number and we will assist you with this process.
      RAISE validation_failed_exception;

    END IF; -- IF validate_login_hz_cur%ROWCOUNT = 0 THEN
    CLOSE validate_login_hz_cur;

    /* Open cusor to check if the customer name/zip code is valid
     */

    lc_proc_log := 'Open cusor to check if the customer name/zip code is valid';

    OPEN get_acc_name_zip_cur(ln_cust_account_id);
    FETCH get_acc_name_zip_cur INTO lc_zip_code, lc_account_name;
    CLOSE get_acc_name_zip_cur;

    lc_proc_log := 'If account name is entered check if it is valid';

    IF (p_account_name IS NOT NULL AND p_account_name != lc_account_name) THEN
      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_007'); -- Account name entered is not valid.
      RAISE validation_failed_exception;
    END IF; -- IF (c_account_name IS NOT NULL AND p_account_name != c_account_name) THEN

    lc_proc_log := 'If zip code is entered check if it is valid';

    IF (p_zip_code IS NOT NULL AND p_zip_code != lc_zip_code ) THEN
      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_008'); -- Zip code entered is not valid.
      RAISE validation_failed_exception;
    END IF; -- IF (c_account_name IS NOT NULL AND p_account_name != c_account_name) THEN

  END IF; -- IF p_validate = 'Y' THEN

  IF validate_login_cur%ISOPEN THEN

   CLOSE validate_login_cur;

  END IF;

  /* Fetch the PRINT documents eligibile for conversion.
   */

  lc_proc_log := 'Fetch the PRINT documents eligibile for conversion.';

  OPEN get_print_doc_cur(ln_cust_account_id);
  FETCH get_print_doc_cur INTO ln_print_count;

  /* If there is no active print document for this account.
   */

  IF get_print_doc_cur%ROWCOUNT = 0 THEN
    x_status := 'E';
    x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_009'); -- This account does not have any eligible paper documents to convert.
    CLOSE get_print_doc_cur;
    RETURN;
  END IF;   --  IF get_print_doc_cur%ROWCOUNT = 0 THEN

  CLOSE get_print_doc_cur;

  /*Updating XX_CDH_EBL_CONV_ACCOUNT_DTL table with status */

  lc_proc_log := 'Updating XX_CDH_EBL_CONV_ACCOUNT_DTL table with status';

  UPDATE xx_cdh_ebl_conv_account_dtl
     SET account_status = 'IN_PROCESS'
   WHERE aops_number = p_aops_account_number;

  /* Returning Success Message if the entered login credentials are valid */

  x_status := 'S';

  x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_011'); -- Request Processed Successfully!  Your electronic billing will begin with the start of your next billing cycle.
                                                                -- Thank you for working with us as we continue to improve your billing experience.

  /* Submitting concurrent request to record and end date old PRINT documents and create new ePDF documents.
   */
  lc_proc_log := 'Submitting concurrent request to record and end date old PRINT documents and create new ePDF documents.';

  --fnd_global.apps_initialize(1121351, 50658, 20049);

  OPEN get_user_id_cur;
  FETCH get_user_id_cur INTO ln_user_id;
  CLOSE get_user_id_cur;

  OPEN get_resp_id_cur;
  FETCH get_resp_id_cur INTO ln_responsibility_id;
  CLOSE get_resp_id_cur;

  OPEN get_app_id_cur;
  FETCH get_app_id_cur INTO ln_application_id;
  CLOSE get_app_id_cur;

  fnd_global.apps_initialize(ln_user_id, ln_responsibility_id, ln_application_id);

  ln_return_code := fnd_request.submit_request( application => 'XXCNV'
                                              , program     => 'XX_CDH_EBL_CNV_PRINT_EPDF'
                                              , start_time  => sysdate
                                              , sub_request => FALSE
                                              , argument1   => to_char(ln_cust_account_id)
                                              , argument2   => p_contact_first_name
                                              , argument3   => p_contact_last_name
                                              , argument4   => p_contact_phone_area
                                              , argument5   => p_contact_phone
                                              , argument6   => p_contact_phone_ext
                                              , argument7   => p_contact_email
                                              , argument8   => p_validate);

  /* Check if the concurrent program has got submitted successfully, if not change the account_status to
   * NULL and raise an Unhandled exception.
   */

  IF ln_return_code IS NULL THEN

    UPDATE xx_cdh_ebl_conv_account_dtl
       SET account_status = NULL
     WHERE aops_number = p_aops_account_number;

     COMMIT;

     RAISE request_failed_exception;

  END IF;

  COMMIT;

  EXCEPTION

    WHEN validation_failed_exception THEN

       /* If the login validation fails, increment the login_attempts by 1
        * and set account_locked to 'Y' if the login_attempts reached the permissable
        * number of attempts.
        */

        UPDATE xx_cdh_ebl_conv_account_dtl
           SET login_attempts = nvl(login_attempts,0) + 1
         WHERE aops_number    = p_aops_account_number;

        UPDATE xx_cdh_ebl_conv_account_dtl
           SET account_locked = 'Y'
         WHERE aops_number    = p_aops_account_number
           AND login_attempts >= NVL(FND_PROFILE.VALUE('XX_CDH_EBL_LOGIN_ATTEMPT'),5);

        COMMIT;

        IF (nvl(ln_login_attempts, 0) + 1 >= FND_PROFILE.VALUE('XX_CDH_EBL_LOGIN_ATTEMPT')) THEN

          x_message := x_message || ' ' || fnd_message.get_string('XXCNV', 'EBL_CONV_004');

        END IF;

        x_status := 'E';

        COMMIT;

        RETURN;

    WHEN OTHERS THEN

      x_status := 'E';
      x_message := FND_MESSAGE.GET_STRING('XXCNV', 'EBL_CONV_000') || ' at ' || lc_proc_log; -- Unhandled Exception.

  END validate_account_login;



-- +===========================================================================+
-- | Name        : CREATE_EBILL_CONTACT                                        |
-- | Description :                                                             |
-- | This program will create contact for the coverted ePDF document with      |
-- | contact points for eMail and phone.                                       |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ============= ========================================|
-- |DRAFT 1  24-DEC-2010 Naga kalyan          Initial draft version            |
-- |                                                                           |
-- |===========================================================================|

  PROCEDURE create_ebill_contact( p_cust_account_id       IN  HZ_CUST_ACCOUNTS.cust_account_id%TYPE
                                , p_contact_first_name    IN  VARCHAR2
                                , p_contact_last_name     IN  VARCHAR2
                                , p_contact_phone_area    IN  VARCHAR2
                                , p_contact_phone         IN  VARCHAR2
                                , p_contact_phone_ext     IN  VARCHAR2
                                , p_contact_email         IN  VARCHAR2
                                , x_org_contact_id        OUT NUMBER)

    IS

    lc_init_msg_list VARCHAR2(200);
    lc_return_status VARCHAR2(200);
    ln_msg_count     NUMBER;
    lc_msg_data      VARCHAR2(200);

    -- ORGANIZATION
    ln_org_party_id  HZ_PARTIES.party_id%TYPE;

    -- PERSON
    lr_person_rec        HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    ln_contact_party_id  NUMBER;
    lc_party_number      VARCHAR2(200);
    ln_profile_id        NUMBER;

    -- Org contact
    lr_org_contact_rec             HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
    ln_org_contact_id_APcontact    NUMBER;
    ln_party_rel_id                NUMBER;
    ln_party_id_create_org_contact NUMBER;
    lc_party_number_org_contact    VARCHAR2(2000);

    -- contact points
    lr_contact_point_rec  hz_contact_point_v2pub.contact_point_rec_type;
    lr_edi_rec            hz_contact_point_v2pub.edi_rec_type;
    lr_email_rec          hz_contact_point_v2pub.email_rec_type;
    lr_phone_rec          hz_contact_point_v2pub.phone_rec_type;
    lr_telex_rec          hz_contact_point_v2pub.telex_rec_type;
    lr_web_rec            hz_contact_point_v2pub.web_rec_type;
    ln_contact_point_id  NUMBER;

    -- Account roles
    lr_cust_account_role_rec hz_cust_account_role_v2pub.cust_account_role_rec_type;
    ln_cust_account_role_id  NUMBER;

    -- Role responsibility
    lr_role_responsibility_rec hz_cust_account_role_v2pub.role_responsibility_rec_type;
    ln_responsibility_id NUMBER;

    lc_proc_log        VARCHAR2(4000);
    lc_log_enable      VARCHAR2(10);

    ebill_contact_exp EXCEPTION;

  BEGIN

    lc_log_enable := fnd_profile.value('XX_CDH_EBL_LOG_ENABLE');

    lc_init_msg_list := NULL;
    -- modify the code to initialize the variable
    lr_person_rec.person_first_name := p_contact_first_name;
    lr_person_rec.person_last_name  := p_contact_last_name;
    lr_person_rec.created_by_module := 'BO_API';

    lc_proc_log := 'Calling hz_party_v2pub.create_person API';
    log_msg(lc_log_enable, lc_proc_log);

    hz_party_v2pub.create_person( p_init_msg_list => lc_init_msg_list
                                , p_person_rec => lr_person_rec
                                , x_party_id => ln_contact_party_id
                                , x_party_number => lc_party_number
                                , x_profile_id => ln_profile_id
                                , x_return_status => lc_return_status
                                , x_msg_count => ln_msg_count
                                , x_msg_data => lc_msg_data);

    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE ebill_contact_exp;
    END IF;

    log_msg(lc_log_enable, 'x_party_id = ' || ln_contact_party_id);
    log_msg(lc_log_enable, 'x_party_number = ' || lc_party_number);
    log_msg(lc_log_enable, 'x_profile_id = ' || ln_profile_id);
    log_msg(lc_log_enable, 'x_return_status = ' || lc_return_status);
    log_msg(lc_log_enable, 'x_msg_count = ' || ln_msg_count);
    log_msg(lc_log_enable, 'x_msg_data = ' || lc_msg_data);

    lc_proc_log := 'Get organization party_id';
    log_msg(lc_log_enable, lc_proc_log);

    -- get organization party_id
    SELECT  party_id into ln_org_party_id
      FROM  hz_cust_accounts
    WHERE   cust_account_id = p_cust_account_id;

    -- create relationship
    lc_init_msg_list := NULL;

    /* Create the person as contact in HZ_ORG_CONTACTS AND HZ_RELATIONSHIPS tables
     */

    lr_org_contact_rec.created_by_module := 'BO_API'; --'XXCRM';  -- v2.0 - modified for R12 retrofit - XXCRM - is not in HZ_CREATED_BY_MODULES
    lr_org_contact_rec.party_rel_rec.subject_id := ln_contact_party_id;
    lr_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
    lr_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
    lr_org_contact_rec.party_rel_rec.object_id := ln_org_party_id;
    lr_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
    lr_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
    lr_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
    lr_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
    lr_org_contact_rec.party_rel_rec.start_date := SYSDATE;
    lr_org_contact_rec.job_title := NULL;

    lc_proc_log := 'Calling hz_party_contact_v2pub.create_org_contact API';
    log_msg(lc_log_enable, lc_proc_log);

    hz_party_contact_v2pub.create_org_contact( p_init_msg_list   => 'T'
               , p_org_contact_rec => lr_org_contact_rec
               , x_org_contact_id  => x_org_contact_id
               , x_party_rel_id    => ln_party_rel_id
               , x_party_id        => ln_party_id_create_org_contact
               , x_party_number    => lc_party_number_org_contact
               , x_return_status   => lc_return_status
               , x_msg_count       => ln_msg_count
               , x_msg_data        => lc_msg_data);

    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      -- v2.0 - Added FOR loop to log error messages - R12 retrofit 
      FOR i IN 1 .. ln_msg_count
      LOOP
        lc_msg_data := FND_msg_pub.get( p_msg_index => i, p_encoded => 'F');
        log_msg(lc_log_enable,i||' - '||lc_msg_data);       
      END LOOP;
     RAISE ebill_contact_exp;
    END IF;

    /* API calls to create contact points
     */

    IF p_contact_phone IS NOT NULL THEN

      -- PHONE
      lc_init_msg_list := NULL;
      -- modify the code to initialize the variable
      lr_contact_point_rec.contact_point_type := 'PHONE';
      lr_contact_point_rec.owner_table_name   := 'HZ_PARTIES';
      lr_contact_point_rec.owner_table_id     := ln_party_id_create_org_contact;
      lr_contact_point_rec.contact_point_purpose := 'BILLING';
      lr_contact_point_rec.created_by_module     := 'BO_API';
      lr_phone_rec.phone_area_code      := p_contact_phone_area;

      --  lr_phone_rec.phone_country_code := 1 ;
      lr_phone_rec.phone_number         := p_contact_phone;
      lr_phone_rec.phone_extension      := p_contact_phone_ext;
      lr_phone_rec.phone_line_type      := 'GEN';

      lc_proc_log := 'Calling hz_contact_point_v2pub.create_contact_point API for creating phone as contact point';
      log_msg(lc_log_enable, lc_proc_log);

      hz_contact_point_v2pub.create_contact_point( p_init_msg_list => lc_init_msg_list
                                                 , p_contact_point_rec => lr_contact_point_rec
                                                 , p_edi_rec => lr_edi_rec
                                                 , p_email_rec => lr_email_rec
                                                 , p_phone_rec => lr_phone_rec
                                                 , p_telex_rec => lr_telex_rec
                                                 , p_web_rec => lr_web_rec
                                                 , x_contact_point_id => ln_contact_point_id
                                                 , x_return_status => lc_return_status
                                                 , x_msg_count => ln_msg_count
                                                 , x_msg_data => lc_msg_data );

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        -- v2.0 - Added FOR loop to log error messages - R12 retrofit
        FOR i IN 1 .. ln_msg_count
        LOOP
          lc_msg_data := FND_msg_pub.get( p_msg_index => i, p_encoded => 'F');
          log_msg(lc_log_enable,i||' - '||lc_msg_data);       
        END LOOP;
        RAISE ebill_contact_exp;
      END IF;

      log_msg(lc_log_enable, 'x_contact_point_id = ' || ln_contact_point_id);
      log_msg(lc_log_enable, 'x_return_status = ' || lc_return_status);
      log_msg(lc_log_enable, 'x_msg_count = ' || ln_msg_count);
      log_msg(lc_log_enable, 'x_msg_data = ' || lc_msg_data);

    END IF; -- IF p_contact_phone IS NOT NULL THEN

    IF p_contact_email IS NOT NULL THEN

      -- EMAIL
      lc_init_msg_list := NULL;
      -- modify the code to initialize the variable
      lr_contact_point_rec.contact_point_type := 'EMAIL';
      lr_contact_point_rec.owner_table_name   := 'HZ_PARTIES';
      lr_contact_point_rec.owner_table_id     := ln_party_id_create_org_contact;
      lr_contact_point_rec.contact_point_purpose := 'BILLING';
      lr_contact_point_rec.created_by_module := 'BO_API';
      lr_email_rec.email_address := p_contact_email;
      lr_email_rec.email_format  := NULL;


      lc_proc_log := 'Calling hz_contact_point_v2pub.create_contact_point API for creating email as contact point';
      log_msg(lc_log_enable, lc_proc_log);

      hz_contact_point_v2pub.create_contact_point(
        p_init_msg_list => lc_init_msg_list,
        p_contact_point_rec => lr_contact_point_rec,
        p_edi_rec => lr_edi_rec,
        p_email_rec => lr_email_rec,
        p_phone_rec => lr_phone_rec,
        p_telex_rec => lr_telex_rec,
        p_web_rec => lr_web_rec,
        x_contact_point_id => ln_contact_point_id,
        x_return_status => lc_return_status,
        x_msg_count => ln_msg_count,
        x_msg_data => lc_msg_data
      );

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        -- v2.0 - Added FOR loop to log error messages - R12 retrofit
        FOR i IN 1 .. ln_msg_count
        LOOP
          lc_msg_data := FND_msg_pub.get( p_msg_index => i, p_encoded => 'F');
          log_msg(lc_log_enable,i||' - '||lc_msg_data);       
        END LOOP;

        RAISE ebill_contact_exp;
      END IF;

      log_msg(lc_log_enable, 'x_contact_point_id = ' || ln_contact_point_id);
      log_msg(lc_log_enable, 'x_return_status = ' || lc_return_status);
      log_msg(lc_log_enable, 'x_msg_count = ' || ln_msg_count);
      log_msg(lc_log_enable, 'x_msg_data = ' || lc_msg_data);


    END IF; -- IF p_contact_email IS NOT NULL THEN

    /* API calles to Create account roles.
     */

    lc_init_msg_list := null;
    -- Modify the code to initialize the variable
    lr_cust_account_role_rec.party_id    := ln_party_id_create_org_contact ;
    lr_cust_account_role_rec.cust_account_id   := p_cust_account_id   ;
    lr_cust_account_role_rec.role_type     := 'CONTACT';
    --lr_cust_account_role_rec.primary_flag    := 'Y';
    lr_cust_account_role_rec.created_by_module := 'BO_API';


    lc_proc_log := 'Calling hz_cust_account_role_v2pub.create_cust_account_role API';
    log_msg(lc_log_enable, lc_proc_log);


    hz_cust_account_role_v2pub.create_cust_account_role(
      p_init_msg_list => lc_init_msg_list,
      p_cust_account_role_rec => lr_cust_account_role_rec,
      x_cust_account_role_id => ln_cust_account_role_id,
      x_return_status => lc_return_status,
      x_msg_count => ln_msg_count,
      x_msg_data => lc_msg_data
    );

    IF lc_return_status <> fnd_api.g_ret_sts_success THEN
      RAISE ebill_contact_exp;
    END IF;

    log_msg(lc_log_enable, 'x_cust_account_role_id = ' || ln_cust_account_role_id);
    log_msg(lc_log_enable, 'x_return_status = ' || lc_return_status);
    log_msg(lc_log_enable, 'x_msg_count = ' || ln_msg_count);
    log_msg(lc_log_enable, 'x_msg_data = ' || lc_msg_data);

    /* API Calls to create role_responsibility
     */

    lc_init_msg_list := null;

  -- modify the code to initialize the variable
    lr_role_responsibility_rec.responsibility_type := 'BILLING';
    lr_role_responsibility_rec.primary_flag := 'Y' ;
    lr_role_responsibility_rec.cust_account_role_id := ln_cust_account_role_id;
    lr_role_responsibility_rec.created_by_module := 'BO_API';


    lc_proc_log := 'Calling hz_cust_account_role_v2pub.create_role_responsibility API';
    log_msg(lc_log_enable, lc_proc_log);

    hz_cust_account_role_v2pub.create_role_responsibility( p_init_msg_list => lc_init_msg_list
                                                         , p_role_responsibility_rec => lr_role_responsibility_rec
                                                         , x_responsibility_id => ln_responsibility_id
                                                         , x_return_status => lc_return_status
                                                         , x_msg_count => ln_msg_count
                                                         , x_msg_data => lc_msg_data );

    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE ebill_contact_exp;
    END IF;

    log_msg(lc_log_enable, 'x_responsibility_id = ' || ln_responsibility_id);
    log_msg(lc_log_enable, 'x_return_status = ' || lc_return_status);
    log_msg(lc_log_enable, 'x_msg_count = ' || ln_msg_count);
    log_msg(lc_log_enable, 'x_msg_data = ' || lc_msg_data);

  EXCEPTION

    WHEN OTHERS THEN

      fnd_file.put_line(fnd_file.log,' Unexpected Exception in create_ebill_contact API at ' || lc_proc_log );

  END create_ebill_contact;

-- +========================================================================+
-- | Name        : INSERT_CONV_DOC_DETAILS                                   |
-- | Description : To to insert document and contact details into the       |
-- |               conversion details table.                                |
-- |                                                                        |
-- +========================================================================+
  PROCEDURE insert_conv_doc_details ( x_errbuff            OUT NOCOPY  VARCHAR2
                                    , x_retcode            OUT NOCOPY  VARCHAR2
                                    , p_cust_account_id    IN  NUMBER
                                    , p_contact_first_name IN  VARCHAR2
                                    , p_contact_last_name  IN  VARCHAR2
                                    , p_contact_phone_area IN  VARCHAR2
                                    , p_contact_phone      IN  VARCHAR2
                                    , p_contact_phone_ext  IN  VARCHAR2
                                    , p_contact_email      IN  VARCHAR2
                                    , p_validate           IN  VARCHAR2)
  IS
    ln_conv_doc_id       NUMBER;
    ln_conv_batch_id     NUMBER;
    ln_conv_contact_id   NUMBER;
    ln_org_contact_id    NUMBER;
    ln_cust_acct_site_id NUMBER;
    ln_new_cust_doc_id   NUMBER;
    ln_doc_cnt           NUMBER := 0;
    lc_status            VARCHAR2(10);
    lc_log_enable        VARCHAR2(10);
    lc_proc_log          VARCHAR2(4000);
    lc_message           VARCHAR2(10000);
    lc_email_subject     VARCHAR2(20000);
    lc_orig_sys_ref      VARCHAR2(20000);
    ld_req_start_date    DATE;


    /* Cusor to fetch the old PRINT document details for the account
     */

    CURSOR get_conv_doc_dtl_cur(c_cust_account_id NUMBER)
        IS
    SELECT XCECA.aops_number    aops_number
         , XCECA.account_number account_number
         , XCEB.n_ext_attr2     cust_doc_id
         , XCEB.n_ext_attr1     mbs_doc_id
         , XCEB.c_ext_attr1     doc_type
         , XCEB.c_ext_attr2     pay_doc_ind
         , XCEB.c_ext_attr3     delivery_method
         , XCEB.c_ext_attr7     direct_flag
         , XCEB.c_ext_attr13    combo_type
         , XCEB.c_ext_attr14    payment_term
         , XCEB.n_ext_attr18    term_id
         , XCEB.n_ext_attr17    is_parent
         , XCEB.n_ext_attr16    send_to_parent
         , XCEB.n_ext_attr15    parent_doc_id
         , XCEB.c_ext_attr15    mail_to_attention
         , XCEB.c_ext_attr16    status
         , XCEB.d_ext_attr1     effective_start_date
         , RT.attribute1        frequency
         , RT.attribute2        report_day
      FROM xx_cdh_cust_acct_ext_b XCEB
         , xx_cdh_ebl_conv_account_dtl XCECA
         , ego_attr_groups_v EAG
         , ra_terms RT
    WHERE  XCEB.cust_account_id  = c_cust_account_id
      AND  XCECA.cust_account_id = XCEB.cust_account_id
      AND  XCEB.attr_group_id    = EAG.attr_group_id
      AND  XCEB.c_ext_attr3      = 'PRINT'
      AND  XCEB.c_ext_attr7      = 'Y'                      -- Direct customer
      AND  XCEB.c_ext_attr16     = 'COMPLETE'               -- Status
      AND  XCEB.c_ext_attr13     IS NULL                    -- Combo type
      AND  XCEB.d_ext_attr2      IS NULL                    -- Effective end date
      AND  XCEB.n_ext_attr17     = 0
      AND  XCEB.n_ext_attr15     IS NULL
      AND  EAG.attr_group_type   = 'XX_CDH_CUST_ACCOUNT'
      AND  EAG.attr_group_name   = 'BILLDOCS'
      AND  RT.name               = XCEB.c_ext_attr14
      AND  RT.end_date_active    IS NULL;

 /* Cursor to fetch default values from fin trans tables for eBilling main table
  */

  CURSOR get_conv_ebl_main_dtl_cur
      IS
  SELECT XFTV.source_value1  delivery_method
       , XFTV.source_value2  associate
       , XFTV.source_value3  file_proc_method
       , XFTV.source_value4  max_file_size
       , XFTV.source_value5  max_trans_size
       , XFTV.source_value6  zip_required
       , XFTV.source_value7  compression_utility
       , XFTV.source_value8  compression_ext
       , XFTV.source_value9  file_extension
       , XFTV.source_value10 logo_required
       , XFTV.target_value1  logo_type
       , XFTV.target_value2  sales_contact_name
       , XFTV.target_value3  sales_contact_email
       , XFTV.target_value4  sales_contact_phone
       , XFTV.target_value5  field_selection
       , XFTV.target_value6  comments
    FROM xx_fin_translatedefinition XFTD
       , xx_fin_translatevalues     XFTV
   WHERE XFTD.translate_id     = XFTV.translate_id
    AND  XFTD.translation_name ='XX_CDH_EBL_CONV_VALUES'
    AND  XFTV.enabled_flag     ='Y'
    AND  SYSDATE BETWEEN XFTV.start_date_active and nvl(XFTV.end_date_active, sysdate +1);

  /* Cursor to fet the contact system referece
   */

  CURSOR get_contact_sys_ref_cur(c_org_contact_id NUMBER)
      IS
  SELECT HCAR.orig_system_reference
    FROM hz_cust_account_roles HCAR
       , hz_relationships HR
       , hz_org_contacts HOC
  WHERE HCAR.party_id              = HR.party_id
    AND HOC.party_relationship_id  = HR.relationship_id
    AND HOC.org_contact_id         = c_org_contact_id;

  BEGIN

    SAVEPOINT proc_begin;

    lc_log_enable := fnd_profile.value('XX_CDH_EBL_LOG_ENABLE');

    lc_proc_log := 'Inside insert_conv_doc_details procedure';
    log_msg(lc_log_enable, lc_proc_log);

    fnd_file.put_line (fnd_file.OUTPUT,'AOPS Account Number | Old Cust Doc Id | Doucment Type | Payment Term | New Cust Doc Id | Status | Error');

    /* Calling create_ebill_contact API to create the contact and
     * contact points with the information provided by the user.
     */

    lc_proc_log := 'Calling create_ebill_contact API to create the contact and contact points with the information provided by the user. ';
    log_msg(lc_log_enable, lc_proc_log);

    create_ebill_contact( p_cust_account_id      => p_cust_account_id
                        , p_contact_first_name   => p_contact_first_name
                        , p_contact_last_name    => p_contact_last_name
                        , p_contact_phone_area   => p_contact_phone_area
                        , p_contact_phone        => p_contact_phone
                        , p_contact_phone_ext    => p_contact_phone_ext
                        , p_contact_email        => p_contact_email
                        , x_org_contact_id       => ln_org_contact_id);

    lc_proc_log := 'Contact created: org_contact_id:' || ln_org_contact_id;
    log_msg(lc_log_enable, lc_proc_log);

    OPEN get_contact_sys_ref_cur(ln_org_contact_id);
    FETCH get_contact_sys_ref_cur INTO lc_orig_sys_ref;
    CLOSE get_contact_sys_ref_cur;

    /* Deleting failed records in XX_CDH_EBL_CONV_DOC_DTL and XX_CDH_EBL_CONV_CONTACT_DTL tables.
     */

    /*

    lc_proc_log := 'Deleting failed records in XX_CDH_EBL_CONV_CONTACT_DTL table';
    log_msg(lc_log_enable, lc_proc_log);

    DELETE FROM xx_cdh_ebl_conv_contact_dtl
     WHERE ebl_conv_doc_id IN (SELECT ebl_conv_doc_id
                                 FROM xx_cdh_ebl_conv_doc_dtl
                                WHERE cust_account_id = p_cust_account_id
                                  AND new_doc_status  = 'IN_PROCESS');

    lc_proc_log := 'Deleting failed records in XX_CDH_EBL_CONV_DOC_DTL table';
    log_msg(lc_log_enable, lc_proc_log);

    DELETE FROM xx_cdh_ebl_conv_doc_dtl
     WHERE cust_account_id = p_cust_account_id
       AND new_doc_status  = 'IN_PROCESS';       */


    /* Inserting PRINT documents into XX_CDH_EBL_CONV_DOC_DTL table.
     */

    lc_proc_log := 'Inserting PRINT documents into XX_CDH_EBL_CONV_DOC_DTL table';
    log_msg(lc_log_enable, lc_proc_log);

    SELECT xx_cdh_ebl_conv_batch_id_s.NEXTVAL
      INTO ln_conv_batch_id
      FROM DUAL;


    FOR conv_ebl_main_rec IN get_conv_ebl_main_dtl_cur LOOP

      ln_doc_cnt := 0;

      FOR conv_doc_rec IN get_conv_doc_dtl_cur(p_cust_account_id) LOOP

      BEGIN

          ln_doc_cnt := ln_doc_cnt + 1;

          SELECT xx_cdh_ebl_conv_doc_s.NEXTVAL
               , xx_cdh_ebl_conv_contact_s.NEXTVAL
               , xx_cdh_cust_doc_id_s.NEXTVAL
               , decode(conv_doc_rec.doc_type,'Invoice', fnd_profile.value('XXOD_EBL_EMAIL_STD_SUB_STAND'),fnd_profile.value('XXOD_EBL_EMAIL_STD_SUB_STAND'))
           INTO ln_conv_doc_id
              , ln_conv_contact_id
              , ln_new_cust_doc_id
              , lc_email_subject
           FROM DUAL;

           lc_proc_log := 'Inserting PRINT document into XX_CDH_EBL_CONV_DOC_DTL table for old cust doc id: ' || conv_doc_rec.cust_doc_id || ' and new cust doc id: ' || ln_new_cust_doc_id;
           log_msg(lc_log_enable, lc_proc_log);

           IF conv_doc_rec.effective_start_date > TRUNC(SYSDATE) THEN

             ld_req_start_date := conv_doc_rec.effective_start_date;

           ELSE

             ld_req_start_date := SYSDATE;

           END IF;

           xx_cdh_ebl_conv_doc_dtl_pkg.insert_row( x_status                         => lc_status
                                                 , x_error_message                  => lc_message
                                                 , p_ebl_conv_doc_id                => ln_conv_doc_id
                                                 , p_new_cust_doc_id                => ln_new_cust_doc_id
                                                 , p_new_doc_status                 => 'IN_PROCESS'
                                                 , p_batch_id                       => ln_conv_batch_id
                                                 , p_cust_account_id                => p_cust_account_id
                                                 , p_account_number                 => conv_doc_rec.account_number
                                                 , p_aops_number                    => conv_doc_rec.aops_number
                                                 , p_old_cust_doc_id                => conv_doc_rec.cust_doc_id
                                                 , p_old_frequency                  => conv_doc_rec.frequency
                                                 , p_old_report_day                 => conv_doc_rec.report_day
                                                 , p_billdocs_mbs_doc_id            => conv_doc_rec.mbs_doc_id
                                                 , p_billdocs_pay_doc_ind           => conv_doc_rec.pay_doc_ind
                                                 , p_billdocs_delivery_method       => conv_doc_rec.delivery_method
                                                 , p_billdocs_direct_flag           => conv_doc_rec.direct_flag
                                                 , p_billdocs_doc_type              => conv_doc_rec.doc_type
                                                 , p_billdocs_combo_type            => conv_doc_rec.combo_type
                                                 , p_billdocs_payment_term          => conv_doc_rec.payment_term
                                                 , p_billdocs_term_id               => conv_doc_rec.term_id
                                                 , p_billdocs_is_parent             => conv_doc_rec.is_parent
                                                 , p_billdocs_send_to_parent        => conv_doc_rec.send_to_parent
                                                 , p_billdocs_parent_doc_id         => conv_doc_rec.parent_doc_id
                                                 , p_billdocs_mail_to_attention     => conv_doc_rec.mail_to_attention
                                                 , p_billdoc_status                 => 'IN_PROCESS' -- conv_doc_rec.status --> (initially it will be INPROCESS)
                                                 , p_billdocs_record_status         => 0 --> (should be status)
                                                 , p_billdocs_req_start_date        => ld_req_start_date -- setting current date for request start date
                                                 , p_ebill_transmission_type        => 'EMAIL' -- transmission_type
                                                 , p_ebill_associate                => conv_ebl_main_rec.associate
                                                 , p_file_processing_method         => conv_ebl_main_rec.file_proc_method
                                                 , p_file_name_ext                  => conv_ebl_main_rec.file_extension
                                                 , p_max_file_size                  => conv_ebl_main_rec.max_file_size
                                                 , p_max_transmission_size          => conv_ebl_main_rec.max_trans_size
                                                 , p_zip_required                   => conv_ebl_main_rec.zip_required
                                                 , p_zipping_utility                => conv_ebl_main_rec.compression_utility
                                                 , p_zip_file_name_ext              => conv_ebl_main_rec.compression_ext
                                                 , p_od_field_contact               => conv_ebl_main_rec.sales_contact_name
                                                 , p_od_field_contact_phone         => conv_ebl_main_rec.sales_contact_phone
                                                 , p_od_field_contact_email         => conv_ebl_main_rec.sales_contact_email
                                                 , p_client_tech_contact            => NULL
                                                 , p_client_tech_contact_phone      => NULL
                                                 , p_client_tech_contact_email      => NULL
                                                 , p_field_selection                => conv_ebl_main_rec.field_selection
                                                 , p_file_name_seq_reset            => NULL
                                                 , p_file_next_seq_number           => NULL
                                                 , p_file_seq_reset_date            => NULL
                                                 , p_file_name_max_seq_number       => NULL
                                                 , p_email_subject                  => lc_email_subject
                                                 , p_email_std_message              => FND_PROFILE.VALUE('XXOD_EBL_EMAIL_STD_MSG')
                                                 , p_email_custom_message           => NULL
                                                 , p_email_std_disclaimer           => FND_PROFILE.VALUE('XXOD_EBL_EMAIL_STD_DISCLAIM') || FND_PROFILE.VALUE('XXOD_EBL_EMAIL_STD_DISCLAIM1')
                                                 , p_email_signature                => FND_PROFILE.VALUE('XXOD_EBL_EMAIL_STD_SIGN')
                                                 , p_email_logo_required            => conv_ebl_main_rec.logo_required
                                                 , p_email_logo_file_name           => conv_ebl_main_rec.logo_type
                                                 , p_ftp_direction                  => NULL
                                                 , p_ftp_transfer_type              => NULL
                                                 , p_ftp_destination_site           => NULL
                                                 , p_ftp_destination_folder         => NULL
                                                 , p_ftp_user_name                  => NULL
                                                 , p_ftp_password                   => NULL
                                                 , p_ftp_pickup_server              => NULL
                                                 , p_ftp_pickup_folder              => NULL
                                                 , p_ftp_cust_contact_name          => NULL
                                                 , p_ftp_cust_contact_email         => NULL
                                                 , p_ftp_cust_contact_phone         => NULL
                                                 , p_ftp_notify_customer            => NULL
                                                 , p_ftp_cc_emails                  => NULL
                                                 , p_ftp_email_sub                  => NULL
                                                 , p_ftp_email_content              => NULL
                                                 , p_ftp_send_zero_byte_file        => NULL
                                                 , p_ftp_zero_byte_file_text        => NULL
                                                 , p_ftp_zero_byte_notification     => NULL
                                                 , p_cd_file_location               => NULL
                                                 , p_cd_send_to_address             => NULL
                                                 , p_comments                       => conv_ebl_main_rec.comments
                                                 , p_request_id                     => fnd_global.conc_request_id()
                                                 , p_program_application_id         => fnd_global.prog_appl_id()
                                                 , p_program_id                     => fnd_global.conc_program_id()
                                                 , p_program_update_date            => SYSDATE
                                                 );

          IF lc_status = 'E' THEN

            ROLLBACK TO proc_begin;

            fnd_file.put_line (fnd_file.log,lc_message);
            x_retcode := '1';
            x_errbuff :=  x_errbuff || lc_message || ' For the PRINT document: ' || conv_doc_rec.cust_doc_id;

            fnd_file.put_line (fnd_file.output, conv_doc_rec.aops_number || ' | ' || conv_doc_rec.cust_doc_id || ' | ' || conv_doc_rec.doc_type || ' | ' || conv_doc_rec.payment_term || ' | ' || ln_new_cust_doc_id || ' | ' || 'Failed' || '| ' || ' Insert into xx_cdh_ebl_conv_doc_dtl table failed: ' || lc_message);

            RETURN;

          END IF; -- IF lc_status = 'E' THEN

          lc_proc_log := 'Inserting contact details into XX_CDH_EBL_CONV_CONTACT_DTL table for ln_conv_doc_id: ' || ln_conv_doc_id || ' and ln_cust_acct_site_id: ' || ln_cust_acct_site_id;
          log_msg(lc_log_enable, lc_proc_log);

          xx_cdh_ebl_conv_contacts_pkg.insert_row(x_status              => lc_status
                                                , x_error_message       => lc_message
                                                , p_ebl_conv_contact_id => ln_conv_contact_id
                                                , p_ebl_conv_doc_id     => ln_conv_doc_id
                                                , p_org_contact_id      => ln_org_contact_id
                                                , p_org_ref_number      => lc_orig_sys_ref
                                                , p_cust_acct_site_id   => NULL
                                                , p_first_name          => p_contact_first_name
                                                , p_last_name           => p_contact_last_name
                                                , p_email_address       => p_contact_email
                                                , p_phone_area_code     => p_contact_phone_area
                                                , p_phone_number        => p_contact_phone
                                                , p_phone_extension     => p_contact_phone_ext);

          IF lc_status = 'E' THEN

            ROLLBACK TO proc_begin;

            fnd_file.put_line (fnd_file.log,lc_message);
            x_retcode := '1';
            x_errbuff :=  x_errbuff || lc_message || ' For the PRINT document: ' || conv_doc_rec.cust_doc_id;

            fnd_file.put_line (fnd_file.output, conv_doc_rec.aops_number || ' | ' || conv_doc_rec.cust_doc_id || ' | ' || conv_doc_rec.doc_type || ' | ' || conv_doc_rec.payment_term || ' | ' || ln_new_cust_doc_id || ' | ' || 'Failed' || '| ' || ' Insert into xx_cdh_ebl_conv_contacts table failed: ' || lc_message);

            RETURN;

          END IF; -- IF lc_status = 'E' THEN

        END;

      END LOOP;

      IF ln_doc_cnt = 0 THEN

            fnd_file.put_line (fnd_file.output, ' No Print documents exists for the Customer ');

      END IF;

    END LOOP;

    /* Calling convert_paper_to_epdf procedure to convert all the PRINT documents into ePDF documents.
     * PRINT documents will be end dated after this and the new ePDF documents will be active from the
     * next billing cycle.
     */

    lc_proc_log := 'Calling convert_paper_to_epdf procedure for batch id: ' || ln_conv_batch_id;
    log_msg(lc_log_enable, lc_proc_log);

    convert_paper_to_epdf( p_batch_id  => ln_conv_batch_id
                         , p_validate  => p_validate
                         , x_status    => lc_status
                         , x_message   => lc_message);

    IF lc_status = 'E' THEN

      fnd_file.put_line (fnd_file.log,lc_message);
      x_retcode := '1';
      x_errbuff :=  x_errbuff || lc_message;

    END IF;

    IF x_retcode NOT IN ('1', '2') THEN
      x_retcode := '0';
      x_errbuff := x_errbuff || lc_message;
    END IF;

    COMMIT;

  EXCEPTION

    WHEN OTHERS THEN

      x_retcode := '2';
      x_errbuff :=  x_errbuff || 'Unexpected exception insert_conv_doc_details while ' || lc_proc_log || '. Exception : ' || SQLERRM ;
      fnd_file.put_line (fnd_file.log,x_errbuff);

  END insert_conv_doc_details;

-- +===========================================================================+
-- | Name        : CONVERT_PAPER_TO_EPDF                                       |
-- | Description :                                                             |
-- | This program will convert all the PAPER document into ePDF documents and  |
-- | will validate the data to change the status to COMPLETE                   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author               Remarks                          |
-- |======== =========== ================     =================================|
-- |DRAFT 1  08-DEC-2010 Parameswaran S N     Initial draft version            |
-- |                                                                           |
-- |===========================================================================|

 PROCEDURE convert_paper_to_epdf   ( p_batch_id  IN  NUMBER
                                   , p_validate  IN  VARCHAR2
                                   , x_status    OUT VARCHAR2
                                   , x_message   OUT VARCHAR2)
IS
  -- Declaration of local variables to be used within the procedure.
  ln_attr_group_id      NUMBER;
  ln_success_count      NUMBER;
  ln_msg_count          NUMBER;
  ln_ext_id_aeb         NUMBER;
  ln_ext_id_seb         NUMBER;
  ln_cust_account_id    NUMBER;
  ln_ebl_doc_contact_id NUMBER;
  ln_error_flag         NUMBER := 0;
  lri_x_row_id_seb      ROWID;
  lc_epdf_del_method    VARCHAR2(10)   := 'ePDF';
  lc_change_status      VARCHAR2(10)   := 'COMPLETE';
  lc_log_enable         VARCHAR2(10);
  lc_validate           VARCHAR2(20);
  lc_error_status       VARCHAR2(100);
  lc_status             VARCHAR2(200);
  lc_return_status      VARCHAR2(200);
  lc_msg_data           VARCHAR2(2000);
  lc_x_row_id_aeb       VARCHAR2(2000);
  lc_proc_log           VARCHAR2(4000);
  lc_validate_error_msg VARCHAR2(32000) := '';

  ld_effective_end_date    DATE;
  ld_effective_start_date  DATE;

  /* Cursor to get the document detail for batch id passed.
   */
  CURSOR lc_cdh_ebl_conv_doc_dtl (c_batch_id IN NUMBER)
  IS
  SELECT XCECD.cust_account_id cust_account_id
       , XCECD.old_cust_doc_id old_cust_doc_id
       , XCECD.new_cust_doc_id new_cust_doc_id
       , XCECD.aops_number aops_number
       , XCECD.billdocs_pay_doc_ind billdocs_pay_doc_ind
       , XCECD.billdocs_mbs_doc_id billdocs_mbs_doc_id
       , XCECD.billdocs_direct_flag billdocs_direct_flag
       , XCECD.billdocs_combo_type billdocs_combo_type
       , XCECD.billdocs_term_id billdocs_term_id
       , XCECD.billdocs_is_parent billdocs_is_parent
       , XCECD.billdocs_send_to_parent billdocs_send_to_parent
       , XCECD.billdocs_parent_doc_id billdocs_parent_doc_id
       , XCECD.billdocs_mail_to_attention billdocs_mail_to_attention
       , XCECD.billdoc_status billdoc_status
       , XCECD.billdocs_req_start_date billdocs_req_start_date
       , XCECD.ebl_conv_doc_id ebl_conv_doc_id
       , XCECD.billdocs_delivery_method billdocs_delivery_method
       , XCECD.billdocs_doc_type billdocs_doc_type
       , XCECD.old_frequency old_frequency
       , XCECD.old_report_day old_report_day
       , XCECD.billdocs_payment_term billdocs_payment_term
       , XCECD.ebill_transmission_type ebill_transmission_type
       , XCECD.ebill_associate ebill_associate
       , XCECD.file_processing_method file_processing_method
       , XCECD.file_name_ext file_name_ext
       , XCECD.max_file_size max_file_size
       , XCECD.max_transmission_size max_transmission_size
       , XCECD.zip_required zip_required
       , XCECD.zipping_utility zipping_utility
       , XCECD.zip_file_name_ext zip_file_name_ext
       , XCECD.od_field_contact od_field_contact
       , XCECD.od_field_contact_phone od_field_contact_phone
       , XCECD.od_field_contact_email od_field_contact_email
       , XCECD.client_tech_contact client_tech_contact
       , XCECD.client_tech_contact_phone client_tech_contact_phone
       , XCECD.client_tech_contact_email client_tech_contact_email
       , XCECD.file_name_seq_reset file_name_seq_reset
       , XCECD.file_next_seq_number file_next_seq_number
       , XCECD.file_seq_reset_date file_seq_reset_date
       , XCECD.file_name_max_seq_number file_name_max_seq_number
       , XCECD.email_subject email_subject
       , XCECD.email_std_message email_std_message
       , XCECD.email_custom_message email_custom_message
       , XCECD.email_std_disclaimer email_std_disclaimer
       , XCECD.email_signature email_signature
       , XCECD.email_logo_required email_logo_required
       , XCECD.email_logo_file_name email_logo_file_name
       , XCECD.ftp_direction ftp_direction
       , XCECD.ftp_transfer_type ftp_transfer_type
       , XCECD.ftp_destination_site ftp_destination_site
       , XCECD.ftp_destination_folder ftp_destination_folder
       , XCECD.ftp_user_name ftp_user_name
       , XCECD.ftp_password ftp_password
       , XCECD.ftp_pickup_server ftp_pickup_server
       , XCECD.ftp_pickup_folder ftp_pickup_folder
       , XCECD.ftp_cust_contact_name ftp_cust_contact_name
       , XCECD.ftp_cust_contact_email ftp_cust_contact_email
       , XCECD.ftp_cust_contact_phone ftp_cust_contact_phone
       , XCECD.ftp_notify_customer ftp_notify_customer
       , XCECD.ftp_cc_emails ftp_cc_emails
       , XCECD.ftp_email_sub ftp_email_sub
       , XCECD.ftp_email_content ftp_email_content
       , XCECD.ftp_send_zero_byte_file ftp_send_zero_byte_file
       , XCECD.ftp_zero_byte_file_text ftp_zero_byte_file_text
       , XCECD.ftp_zero_byte_notification_txt ftp_zero_byte_notification_txt
       , XCECD.cd_file_location cd_file_location
       , XCECD.cd_send_to_address cd_send_to_address
       , XCECD.comments comments
       , XCECD.batch_id batch_id
    FROM xx_cdh_ebl_conv_doc_dtl XCECD
    WHERE batch_id = c_batch_id; -- Passing the batch ID for getting the values for document details of each batch ID

  /* Cursor to get the contact detail for batch id passed.
   */
  CURSOR lc_cdh_ebl_conv_cont_dtl ( c_batch_id IN NUMBER
                                  , c_new_cust_doc_id IN NUMBER)
  IS
  SELECT XCECC.org_contact_id org_contact_id
    FROM xx_cdh_ebl_conv_doc_dtl XCECD
       , xx_cdh_ebl_conv_contact_dtl XCECC
    WHERE XCECD.ebl_conv_doc_id = XCECC.ebl_conv_doc_id
      AND XCECD.batch_id        = c_batch_id
      AND XCECD.new_cust_doc_id = c_new_cust_doc_id;

  /* Cursor for getting the default file name parameter values
   */
  CURSOR lc_ebl_file_name_dtl
  IS
  SELECT xx_cdh_ebl_file_name_id_s.nextval ebl_file_name_id
        , XFTV.source_value3 file_name_order_seq
        , XFTV.source_value4 field_id
        , XFTV.source_value5 constant_value
        , XFTV.source_value6 default_if_null
    FROM xx_fin_translatedefinition XFTD
       , xx_fin_translatevalues XFTV
   WHERE XFTD.translate_id     = XFTV.translate_id
     AND XFTD.translation_name = 'XX_CDH_EBL_CONV_FILENAME'
     AND XFTV.enabled_flag     = 'Y'
     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active, SYSDATE +1);

  /* Cursor to fetch the exceptions of the existing PRINT documents
   */
  CURSOR get_cust_doc_ext_cur(c_old_cust_doc_id NUMBER)
      IS
  SELECT XCAS.cust_acct_site_id
       , XCAS.c_ext_attr3
       , XCAS.c_ext_attr5
       , XCAS.c_ext_attr19
       , XCAS.c_ext_attr20
       , XCAS.attr_group_id
    FROM xx_cdh_acct_site_ext_b XCAS
       , ego_attr_groups_v EAG
   WHERE XCAS.attr_group_id  =  EAG.attr_group_id
     AND EAG.attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
     AND EAG.attr_group_name = 'BILLDOCS'
     AND XCAS.n_ext_attr1    = c_old_cust_doc_id;

  /* Cursor to fetch if the old PRINT document is still active
   */
  CURSOR check_print_active_cur(c_old_cust_doc_id NUMBER)
      IS
  SELECT XCAE.d_ext_attr2 effective_end_date
       , XCAE.attr_group_id
    FROM xx_cdh_cust_acct_ext_b XCAE
       , ego_attr_groups_v EAG
   WHERE XCAE.attr_group_id  = EAG.attr_group_id
     AND EAG.attr_group_type = 'XX_CDH_CUST_ACCOUNT'
     AND EAG.attr_group_name = 'BILLDOCS'
     AND XCAE.n_ext_attr2    = c_old_cust_doc_id;


  /* Cursro to fetch all the error messages if the validate_final procedure fails
   */
  CURSOR get_validate_error_cur (c_new_cust_doc_id NUMBER)
      IS
  SELECT error_code
       , error_desc
       , doc_process_date
    FROM xx_cdh_ebl_error
   WHERE cust_doc_id = c_new_cust_doc_id;



  BEGIN

     /* Converts all the PRINT document in to ePDF by looping through the conversion table
      * 1. Create new ePDF document to replace the PRINT document
      * 2. Validates the ePDF document and changes the status to Complete
      * 3. Corresponding PRINT document is end dated
      * 4. Statuses are updated in the conversion tables.
      */

     lc_log_enable := fnd_profile.value('XX_CDH_EBL_LOG_ENABLE');

     lc_proc_log := 'Inside convert_paper_to_epdf procedure.';
     log_msg(lc_log_enable, lc_proc_log);

     log_msg(lc_log_enable, '------------------------------------------------------------');

     FOR lcr_cdh_ebl_conv_doc_dtl IN lc_cdh_ebl_conv_doc_dtl(p_batch_id) -- Opening the main cursor
     LOOP

       BEGIN

         lc_proc_log := 'Converting PRINT Document: ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' to ePDF Doccumnet: ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;
         log_msg(lc_log_enable, lc_proc_log);

         SELECT ego_extfwk_s.NEXTVAL -- Getting the extension ID sequence for xx_cdh_cust_acct_ext_b table -- Need to verify
           INTO ln_ext_id_aeb
           FROM DUAL;

         ld_effective_end_date := NULL;

         OPEN check_print_active_cur(lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id);

         FETCH check_print_active_cur INTO ld_effective_end_date, ln_attr_group_id;

         CLOSE check_print_active_cur;

         lc_proc_log := 'Effective End Date of old PRINT Doc: ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' is: ' || ld_effective_end_date;
         log_msg(lc_log_enable, lc_proc_log);

         /* Below API calls will insert data into eBilling tables to create the new ePDF document
          * which will replace the PRINT document.
          *
          * Calling API to insert the data into the xx_cdh_cust_acct_ext_b table based on the batch ID.
          */

         ln_cust_account_id := lcr_cdh_ebl_conv_doc_dtl.cust_account_id;

         lc_proc_log := 'Calling xx_cdh_cust_acct_ext_w_pkg.insert_row and xx_cdh_cust_acct_site_extw_pkg.insert_row for new cust doc id: ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;
         log_msg(lc_log_enable, lc_proc_log);

         xx_cdh_cust_acct_ext_w_pkg.insert_row ( x_rowid            => lc_x_row_id_aeb
                                               , p_extension_id     => ln_ext_id_aeb
                                               , p_cust_account_id  => lcr_cdh_ebl_conv_doc_dtl.cust_account_id
                                               , p_attr_group_id    => ln_attr_group_id
                                               , p_c_ext_attr1      => lcr_cdh_ebl_conv_doc_dtl.billdocs_doc_type
                                               , p_c_ext_attr2      => lcr_cdh_ebl_conv_doc_dtl.billdocs_pay_doc_ind
                                               , p_c_ext_attr3      => lc_epdf_del_method                             -- passing ePDF value
                                               , p_c_ext_attr7      => lcr_cdh_ebl_conv_doc_dtl.billdocs_direct_flag
                                               , p_c_ext_attr13     => lcr_cdh_ebl_conv_doc_dtl.billdocs_combo_type
                                               , p_c_ext_attr14     => lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term
                                               , p_c_ext_attr15     => lcr_cdh_ebl_conv_doc_dtl.billdocs_mail_to_attention
                                               , p_c_ext_attr16     => 'IN_PROCESS'
                                               , p_d_ext_attr9      => lcr_cdh_ebl_conv_doc_dtl.billdocs_req_start_date
                                               , p_n_ext_attr1      => lcr_cdh_ebl_conv_doc_dtl.billdocs_mbs_doc_id
                                               , p_n_ext_attr2      => lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                               , p_n_ext_attr15     => lcr_cdh_ebl_conv_doc_dtl.billdocs_parent_doc_id
                                               , p_n_ext_attr16     => lcr_cdh_ebl_conv_doc_dtl.billdocs_send_to_parent
                                               , p_n_ext_attr17     => lcr_cdh_ebl_conv_doc_dtl.billdocs_is_parent
                                               , p_n_ext_attr18     => lcr_cdh_ebl_conv_doc_dtl.billdocs_term_id);


         /* Calling API to insert the data into the xx_cdh_acct_site_ext_b table based on the batch ID.
          */

         lc_proc_log := 'Calling xx_cdh_cust_acct_site_extw_pkg.insert_row.';
         log_msg(lc_log_enable, lc_proc_log);

         FOR lr_cust_doc_ext IN get_cust_doc_ext_cur(lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id) LOOP

           SELECT ego_extfwk_s.NEXTVAL -- Getting the extension ID sequence for xx_cdh_acct_site_ext_b table
             INTO ln_ext_id_seb
             FROM DUAL;

           xx_cdh_cust_acct_site_extw_pkg.insert_row ( x_rowid               => lri_x_row_id_seb
                                                     , p_extension_id        => ln_ext_id_seb
                                                     , p_attr_group_id       => lr_cust_doc_ext.attr_group_id
                                                     , p_n_ext_attr1         => lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                                     , p_cust_acct_site_id   => lr_cust_doc_ext.cust_acct_site_id
                                                     , p_c_ext_attr3         => lr_cust_doc_ext.c_ext_attr3
                                                     , p_c_ext_attr5         => lr_cust_doc_ext.c_ext_attr5
                                                     , p_c_ext_attr20        => lr_cust_doc_ext.c_ext_attr20
                                                     , p_c_ext_attr19        => lr_cust_doc_ext.c_ext_attr19
                                                     , x_return_status       => lc_error_status);

           --Printing the error status in the log
           IF (lc_return_status != 'S') THEN

              FOR k IN 1 .. ln_msg_count
              LOOP
                 lc_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
              END LOOP;
              fnd_file.put_line (fnd_file.log,'xx_cdh_cust_acct_site_extw_pkg.insert_row Failed :'||lc_msg_data );

           END IF;

         END LOOP;

         /* Calling API to insert the data into the xx_cdh_ebl_main table based on the batch ID.
          */

         lc_proc_log := 'Calling xx_cdh_ebl_main_pkg.insert_row';
         log_msg(lc_log_enable, lc_proc_log);

         xx_cdh_ebl_main_pkg.insert_row ( p_cust_doc_id                  =>    lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                        , p_cust_account_id              =>    lcr_cdh_ebl_conv_doc_dtl.cust_account_id
                                        , p_ebill_transmission_type      =>    lcr_cdh_ebl_conv_doc_dtl.ebill_transmission_type
                                        , p_ebill_associate              =>    lcr_cdh_ebl_conv_doc_dtl.ebill_associate
                                        , p_file_processing_method       =>    lcr_cdh_ebl_conv_doc_dtl.file_processing_method
                                        , p_file_name_ext                =>    lcr_cdh_ebl_conv_doc_dtl.file_name_ext
                                        , p_max_file_size                =>    lcr_cdh_ebl_conv_doc_dtl.max_file_size
                                        , p_max_transmission_size        =>    lcr_cdh_ebl_conv_doc_dtl.max_transmission_size
                                        , p_zip_required                 =>    lcr_cdh_ebl_conv_doc_dtl.zip_required
                                        , p_zipping_utility              =>    lcr_cdh_ebl_conv_doc_dtl.zipping_utility
                                        , p_zip_file_name_ext            =>    lcr_cdh_ebl_conv_doc_dtl.zip_file_name_ext
                                        , p_od_field_contact             =>    lcr_cdh_ebl_conv_doc_dtl.od_field_contact
                                        , p_od_field_contact_email       =>    lcr_cdh_ebl_conv_doc_dtl.od_field_contact_email
                                        , p_od_field_contact_phone       =>    lcr_cdh_ebl_conv_doc_dtl.od_field_contact_phone
                                        , p_client_tech_contact          =>    lcr_cdh_ebl_conv_doc_dtl.client_tech_contact
                                        , p_client_tech_contact_email    =>    lcr_cdh_ebl_conv_doc_dtl.client_tech_contact_email
                                        , p_client_tech_contact_phone    =>    lcr_cdh_ebl_conv_doc_dtl.client_tech_contact_phone
                                        , p_file_name_seq_reset          =>    lcr_cdh_ebl_conv_doc_dtl.file_name_seq_reset
                                        , p_file_next_seq_number         =>    lcr_cdh_ebl_conv_doc_dtl.file_next_seq_number
                                        , p_file_seq_reset_date          =>    lcr_cdh_ebl_conv_doc_dtl.file_seq_reset_date
                                        , p_file_name_max_seq_number     =>    lcr_cdh_ebl_conv_doc_dtl.file_name_max_seq_number);

         /* Calling API to insert the data into the xx_cdh_ebl_transmission_dtl table based on the batch ID.
          */

         lc_proc_log := 'Calling xx_cdh_ebl_trans_dtl_pkg.insert_row';
         log_msg(lc_log_enable, lc_proc_log);

         xx_cdh_ebl_trans_dtl_pkg.insert_row ( p_cust_doc_id                 =>     lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                             , p_email_subject               =>     lcr_cdh_ebl_conv_doc_dtl.email_subject
                                             , p_email_std_message           =>     lcr_cdh_ebl_conv_doc_dtl.email_std_message
                                             , p_email_custom_message        =>     lcr_cdh_ebl_conv_doc_dtl.email_custom_message
                                             , p_email_std_disclaimer        =>     lcr_cdh_ebl_conv_doc_dtl.email_std_disclaimer
                                             , p_email_signature             =>     lcr_cdh_ebl_conv_doc_dtl.email_signature
                                             , p_email_logo_required         =>     lcr_cdh_ebl_conv_doc_dtl.email_logo_required
                                             , p_email_logo_file_name        =>     lcr_cdh_ebl_conv_doc_dtl.email_logo_file_name
                                             , p_ftp_direction               =>     lcr_cdh_ebl_conv_doc_dtl.ftp_direction
                                             , p_ftp_transfer_type           =>     lcr_cdh_ebl_conv_doc_dtl.ftp_transfer_type
                                             , p_ftp_destination_site        =>     lcr_cdh_ebl_conv_doc_dtl.ftp_destination_site
                                             , p_ftp_destination_folder      =>     lcr_cdh_ebl_conv_doc_dtl.ftp_destination_folder
                                             , p_ftp_user_name               =>     lcr_cdh_ebl_conv_doc_dtl.ftp_user_name
                                             , p_ftp_password                =>     lcr_cdh_ebl_conv_doc_dtl.ftp_password
                                             , p_ftp_pickup_server           =>     lcr_cdh_ebl_conv_doc_dtl.ftp_pickup_server
                                             , p_ftp_pickup_folder           =>     lcr_cdh_ebl_conv_doc_dtl.ftp_pickup_folder
                                             , p_ftp_cust_contact_name       =>     lcr_cdh_ebl_conv_doc_dtl.ftp_cust_contact_name
                                             , p_ftp_cust_contact_email      =>     lcr_cdh_ebl_conv_doc_dtl.ftp_cust_contact_phone
                                             , p_ftp_cust_contact_phone      =>     lcr_cdh_ebl_conv_doc_dtl.ftp_notify_customer
                                             , p_ftp_notify_customer         =>     lcr_cdh_ebl_conv_doc_dtl.ftp_cust_contact_email
                                             , p_ftp_cc_emails               =>     lcr_cdh_ebl_conv_doc_dtl.ftp_cc_emails
                                             , p_ftp_email_sub               =>     lcr_cdh_ebl_conv_doc_dtl.ftp_email_sub
                                             , p_ftp_email_content           =>     lcr_cdh_ebl_conv_doc_dtl.ftp_email_content
                                             , p_ftp_send_zero_byte_file     =>     lcr_cdh_ebl_conv_doc_dtl.ftp_send_zero_byte_file
                                             , p_ftp_zero_byte_file_text     =>     lcr_cdh_ebl_conv_doc_dtl.ftp_zero_byte_file_text
                                             , p_ftp_zero_byte_notifi_txt    =>     lcr_cdh_ebl_conv_doc_dtl.ftp_zero_byte_notification_txt
                                             , p_cd_file_location            =>     lcr_cdh_ebl_conv_doc_dtl.cd_file_location
                                             , p_cd_send_to_address          =>     lcr_cdh_ebl_conv_doc_dtl.cd_send_to_address
                                             , p_comments                    =>     SUBSTR('(Old Document Id: ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' ), ' || lcr_cdh_ebl_conv_doc_dtl.comments, 1, 4000) );

         /* Inserting the data into the xx_cdh_ebl_file_name_dtl table.
          */

         lc_proc_log := 'Inserting the data into the xx_cdh_ebl_file_name_dtl table.';
         log_msg(lc_log_enable, lc_proc_log);

         FOR lcr_ebl_file_name_dtl IN lc_ebl_file_name_dtl -- Opening the file naming dtl cursor
         LOOP

           xx_cdh_ebl_file_name_dtl_pkg.insert_row ( p_ebl_file_name_id    => lcr_ebl_file_name_dtl.ebl_file_name_id
                                                   , p_cust_doc_id         => lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                                   , p_file_name_order_seq => lcr_ebl_file_name_dtl.file_name_order_seq
                                                   , p_field_id            => lcr_ebl_file_name_dtl.field_id
                                                   , p_constant_value      => lcr_ebl_file_name_dtl.constant_value
                                                   , p_default_if_null     => lcr_ebl_file_name_dtl.default_if_null
                                                   , p_comments            => lcr_cdh_ebl_conv_doc_dtl.comments);

         END LOOP; -- Closing the file naming dtl cursor


         lc_proc_log := 'Calling  xx_cdh_ebl_contacts_pkg.insert_row.';
         log_msg(lc_log_enable, lc_proc_log);

         FOR lcr_cdh_ebl_conv_cont_dtl IN lc_cdh_ebl_conv_cont_dtl(p_batch_id, lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id)
         LOOP

           /* Calling API to insert the data into the xx_cdh_ebl_contacts table based on the batch ID.
            */

           SELECT xx_cdh_ebl_doc_contact_id_s.NEXTVAL
             INTO ln_ebl_doc_contact_id
             FROM dual;

           xx_cdh_ebl_contacts_pkg.insert_row( p_ebl_doc_contact_id   => ln_ebl_doc_contact_id
                                             , p_cust_doc_id          => lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id
                                             , p_org_contact_id       => lcr_cdh_ebl_conv_cont_dtl.org_contact_id
                                             , p_cust_acct_site_id    => NULL -- lcr_cdh_ebl_conv_doc_dtl.cust_acct_site_id (Locaion can be null)
                                             , p_attribute1           => lcr_cdh_ebl_conv_doc_dtl.cust_account_id);

         END LOOP;

        /* Check if the old PRINT document is already endated, if yes return error message
         * Else validate the new document and complete it. End date the old doucment.
         */

         IF ld_effective_end_date IS NOT NULL THEN

           lc_proc_log := 'PRINT document is already end dated for old document id: ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id;
           fnd_file.put_line (fnd_file.log,lc_proc_log);

           UPDATE xx_cdh_ebl_conv_doc_dtl -- updating the xx_cdh_ebl_conv_doc_dtl for docs that are in process
              SET new_doc_status  = 'ERROR' -- verify for the column to be updated
                , attribute1      = TRIM(SUBSTR(lc_proc_log,1,145))
            WHERE batch_id = p_batch_id
              AND new_cust_doc_id = lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;

           fnd_file.put_line (fnd_file.output,lcr_cdh_ebl_conv_doc_dtl.aops_number || ' | ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_doc_type || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term || ' | ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id || ' | ' || 'Failed' || '| ' || ' PRINT document is end dated already.');

         ELSE -- IF ld_effective_end_date IS NOT NULL THEN

           /* Validating the new document and changing the status to complete if thd document details are valid
            */

           lc_proc_log := 'Calling Vaildate Final';
           log_msg(lc_log_enable, lc_proc_log);

           lc_validate := xx_cdh_ebl_validate_pkg.validate_final(lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id,lcr_cdh_ebl_conv_doc_dtl.cust_account_id,lc_change_status); -- Validates the data in the table

           FOR lr_validate_error_rec IN get_validate_error_cur(lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id) LOOP

            lc_validate := 'FALSE';
            fnd_file.put_line (fnd_file.log,lr_validate_error_rec.error_desc);
            IF LENGTH(lc_validate_error_msg || lr_validate_error_rec.error_desc) >= 150 THEN
              lc_validate_error_msg := lc_validate_error_msg || lr_validate_error_rec.error_desc;
            END IF;

           END LOOP;

           IF (lc_validate = 'TRUE') THEN   -- gets the cust doc ID for the deilvery method passed whose status is in 'COMPLETE'

             lc_proc_log := 'Validation Successful for the new Customer Document: ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;
             log_msg(lc_log_enable, lc_proc_log);

             /* Check if the old PRINT document is a info doc
              * If yes, end date the old PRINT document by udating the record in  xx_cdh_cust_acct_ext_b table.
              * Calculate the end date calling the xx_ar_inv_freq_pkg.compute_effective_date procedure.
              */

             IF (lcr_cdh_ebl_conv_doc_dtl.billdocs_pay_doc_ind != 'Y') THEN -- info doc

               lc_proc_log := 'End dating the old info print cust doc ID using the end date logic for info doc: ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id;
               log_msg(lc_log_enable, lc_proc_log);

               UPDATE xx_cdh_cust_acct_ext_b -- End Dating the old cust doc ID using the end date logic.
                  SET d_ext_attr2     = xx_ar_inv_freq_pkg.compute_effective_date(lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term, lcr_cdh_ebl_conv_doc_dtl.billdocs_req_start_date)
                WHERE cust_account_id = lcr_cdh_ebl_conv_doc_dtl.cust_account_id
                  AND n_ext_attr2     = lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id;

             END IF;  -- (lc_billdocs_pay_doc_ind != 'Y')

             /* Document validation is successful, Updating the document status to COMPLETE in xx_cdh_ebl_conv_doc_dtl table.
              */

             lc_proc_log := 'Updating xx_cdh_ebl_conv_doc_dtl table.';
             log_msg(lc_log_enable, lc_proc_log);

             UPDATE xx_cdh_ebl_conv_doc_dtl -- updating the xx_cdh_ebl_conv_doc_dtl for successfully inserted docs
                SET new_doc_status  = 'COMPLETE' -- verify for the column to be updated
              WHERE batch_id = p_batch_id
                AND new_cust_doc_id = lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;

             fnd_file.put_line (fnd_file.output,lcr_cdh_ebl_conv_doc_dtl.aops_number || ' | ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_doc_type || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term || ' | ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id || ' | ' || 'Complete' || '| ');

           ELSE --(lc_validate = 'TRUE')

             /* Document validation is failed, Updating the document status to ERROR
              * and attribute1 with error message in xx_cdh_ebl_conv_doc_dtl table.
              */

             lc_proc_log := 'Validation Failed for the new Customer Document: ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;
             fnd_file.put_line (fnd_file.log,lc_proc_log);

             UPDATE xx_cdh_ebl_conv_doc_dtl -- updating the xx_cdh_ebl_conv_doc_dtl for docs that are in process
                SET new_doc_status  = 'ERROR' -- verify for the column to be updated
                  , attribute1      = TRIM(SUBSTR ((lc_proc_log || ' : ' || lc_validate_error_msg), 1, 145))
              WHERE batch_id = p_batch_id
                AND new_cust_doc_id = lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;

             fnd_file.put_line (fnd_file.output,lcr_cdh_ebl_conv_doc_dtl.aops_number || ' | ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_doc_type || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term || ' | ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id || ' | ' || 'Failed' || '| ' || ' Validation Failed');

           END IF; --(lc_validate = 'TRUE') THEN

         END IF; -- IF ld_effective_end_date IS NOT NULL THEN

       EXCEPTION

         WHEN OTHERS THEN

           lc_proc_log := 'Unexpected exception for the new Customer Document: ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id || ' SQLCODE - '||SQLCODE||' SQLERRM - '||Initcap(SQLERRM);
           fnd_file.put_line (fnd_file.log,lc_proc_log);

           UPDATE xx_cdh_ebl_conv_doc_dtl -- updating the xx_cdh_ebl_conv_doc_dtl for docs that are in process
              SET new_doc_status  = 'ERROR' -- verify for the column to be updated
                , attribute1      = TRIM(SUBSTR(lc_proc_log,1,145))
            WHERE batch_id = p_batch_id
              AND new_cust_doc_id = lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id;

           fnd_file.put_line (fnd_file.output,lcr_cdh_ebl_conv_doc_dtl.aops_number || ' | ' || lcr_cdh_ebl_conv_doc_dtl.old_cust_doc_id || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_doc_type || ' | ' || lcr_cdh_ebl_conv_doc_dtl.billdocs_payment_term || ' | ' || lcr_cdh_ebl_conv_doc_dtl.new_cust_doc_id || ' | ' || 'Failed' || '| ' || lc_proc_log || ', SQLCODE - '|| SQLCODE ||' SQLERRM - '|| Initcap(SQLERRM) );

       END;

       log_msg(lc_log_enable, '------------------------------------------------------------');

     END LOOP; -- Closing the main cursor

     /* Get the number of documents which have failed during conversion.
      * If the one or more documents have failed then update the xx_cdh_ebl_conv_account_dtl with IN_PROCESS status
      * Else update the status has COMPLETE.
      */

     SELECT count(1)
       INTO ln_success_count
       FROM xx_cdh_ebl_conv_doc_dtl
      WHERE batch_id = p_batch_id
        AND new_doc_status  = 'ERROR';

     lc_proc_log := 'Updating xx_cdh_ebl_conv_account_dtl table.';
     log_msg(lc_log_enable, lc_proc_log);

     IF (ln_success_count >= 1) THEN -- Checking for the errored docuemnts in xx_cdh_ebl_conv_doc_dtl table.

       UPDATE xx_cdh_ebl_conv_account_dtl -- updating xx_cdh_ebl_conv_account_dtl table for the accounts which have atleast one error record
          SET account_status = 'IN_PROCESS'
        WHERE cust_account_id = ln_cust_account_id;

       x_message := 'One or more documents have failed validation for the batch id:' || p_batch_id;
       x_status  := 'E';

     ELSE -- (ln_success_count >= 1)

       UPDATE xx_cdh_ebl_conv_account_dtl -- updating xx_cdh_ebl_conv_account_dtl table for the accounts which have zero error records.
          SET account_status = 'COMPLETE'
        WHERE cust_account_id = ln_cust_account_id;

       x_message := 'All New Document completed successfully for the batch id:' || p_batch_id;
       x_status  := 'S';

     END IF;  -- (ln_success_count >= 1)

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       x_message :=  'No data found exception in the procedure convert_paper_to_epdf at' || lc_proc_log;
       x_status  := 'E';

       fnd_file.put_line(fnd_file.log,x_message);

     WHEN OTHERS THEN

       x_message := 'Unhandled exception in the procedure convert_paper_to_epdf at.' || lc_proc_log ||' SQLCODE - '||SQLCODE||' SQLERRM - '||Initcap(SQLERRM);
       x_status  := 'E';

       fnd_file.put_line(fnd_file.log,x_message);

  END convert_paper_to_epdf;


-- +===========================================================================+
-- | Name        : CONVERT_PAPER_TO_EPDF                                       |
-- | Description :                                                             |
-- | This program is for generating a report to list all the documents which   |
-- | have failed during conversion from PRINT to ePDF.                         |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |DRAFT 1A 15-FEB-2011 Devi Viswanathan Initial draft version                |
-- |                                                                           |
-- |===========================================================================|
  PROCEDURE convert_error_report( x_errbuff     OUT NOCOPY  VARCHAR2
                                , x_retcode     OUT NOCOPY  VARCHAR2
                                , p_start_date  IN  VARCHAR2
                                )

  IS

  CURSOR cur_get_failed_docs( c_strart_date DATE
                            , c_end_date    DATE)
      IS
  SELECT XCDD.ebl_conv_doc_id            ebl_conv_doc_id
      ,  XCDD.new_cust_doc_id            new_cust_doc_id
      ,  XCDD.old_cust_doc_id            old_cust_doc_id
      ,  XCDD.new_doc_status             new_doc_status
      ,  XCDD.aops_number                aops_number
      ,  XCDD.account_number             account_number
      ,  HCA.account_name                customer_name
      ,  XCDD.billdocs_mbs_doc_id        billdocs_mbs_doc_id
      ,  XCDD.billdocs_pay_doc_ind       billdocs_pay_doc_ind
      ,  XCDD.billdocs_delivery_method   billdocs_delivery_method
      ,  XCDD.billdocs_direct_flag       billdocs_direct_flag
      ,  XCDD.billdocs_doc_type          billdocs_doc_type
      ,  XCDD.billdocs_payment_term      billdocs_payment_term
      ,  XCDD.billdocs_mail_to_attention billdocs_mail_to_attention
      ,  XCDD.billdocs_req_start_date    billdocs_req_start_date
      ,  XCDD.creation_date              creation_date
      ,  XCDD.request_id                 request_id
      ,  XCDD.cust_account_id            cust_account_id
      ,  XCDD.attribute1                 error_message
    FROM xx_cdh_ebl_conv_doc_dtl XCDD
       , hz_cust_accounts HCA
   WHERE XCDD.new_doc_status  = 'ERROR'
     AND XCDD.cust_account_id = HCA.cust_account_id
     AND XCDD.creation_date BETWEEN c_strart_date AND c_end_date
   ORDER BY XCDD.aops_number, XCDD.old_cust_doc_id, XCDD.ebl_conv_doc_id;


 CURSOR cur_get_doc_cont(c_ebl_conv_doc_id NUMBER)

     IS
 SELECT (XCCD.first_name || ' ' || XCCD.last_name) contact_name
      , XCCD.email_address                         contact_email
   FROM xx_cdh_ebl_conv_contact_dtl XCCD
  WHERE XCCD.ebl_conv_doc_id = c_ebl_conv_doc_id
    AND rownum = 1;

  lc_contact_name  VARCHAR2(32000);
  lc_contact_email VARCHAR2(32000);
  lb_return        BOOLEAN;
  ld_start_date    DATE;
  ld_end_date      DATE;
  ln_request_id    NUMBER;

  BEGIN

    ld_start_date := NVL(TO_DATE(p_start_date,'RRRR/MM/DD HH24:MI:SS'),TO_DATE(FND_PROFILE.VALUE('XX_CDH_EBL_REPORT_DATE'),'DD-MON-RRRR HH24:MI:SS'));
    ld_end_date   := sysdate;
    ln_request_id := fnd_global.conc_request_id();

    fnd_file.put_line (fnd_file.log,   'Request Id: '        || ln_request_id);
    fnd_file.put_line (fnd_file.log,   'Report Start Date: ' || TO_CHAR(ld_start_date,'DD-MON-RRRR HH24:MI:SS'));
    fnd_file.put_line (fnd_file.log,   'Report End Date: '   || TO_CHAR(ld_end_date,'DD-MON-RRRR HH24:MI:SS'));
    fnd_file.put_line (fnd_file.output,'Request Id: '        || ln_request_id);
    fnd_file.put_line (fnd_file.output,'Report Start Date: ' || TO_CHAR(ld_start_date,'DD-MON-RRRR HH24:MI:SS'));
    fnd_file.put_line (fnd_file.output,'Report End Date: '   || TO_CHAR(ld_end_date,'DD-MON-RRRR HH24:MI:SS'));

    /* print the header in the output file.
     */

    fnd_file.put_line (fnd_file.output,'NEW_CUST_DOC_ID|OLD_CUST_DOC_ID|NEW_DOC_STATUS|AOPS_NUMBER|ACCOUNT_NUMBER|CUSTOMER_NAME|BILLDOCS_MBS_DOC_ID|BILLDOCS_PAY_DOC_IND|BILLDOCS_DELIVERY_METHOD|BILLDOCS_DIRECT_FLAG|BILLDOCS_DOC_TYPE|BILLDOCS_PAYMENT_TERM|BILLDOCS_MAIL_TO_ATTENTION|CONTACT_NAME|CONTACT_EMAIL|BILLDOCS_REQ_START_DATE|CREATION_DATE|REQUEST_ID|EBL_CONV_DOC_ID|CUST_ACCOUNT_ID|ERROR_MESSAGE ');

    /* Fetch all the error records and print in the output file in pipe delimited format matching the header.
       All the record processed on are after the give report start date are fetched.
       If the user doesn't enter the start date, the end date of the last run report is taken as the start date
       from the system profile option XX_CDH_EBL_REPORT_DATE.
     */
    FOR lr_docs IN cur_get_failed_docs(ld_start_date, ld_end_date)
    LOOP

      BEGIN

        OPEN cur_get_doc_cont(lr_docs.ebl_conv_doc_id);
        FETCH cur_get_doc_cont INTO lc_contact_name
                                  , lc_contact_email;
        CLOSE cur_get_doc_cont;

        fnd_file.put_line (fnd_file.output, lr_docs.new_cust_doc_id || '|' || lr_docs.old_cust_doc_id || '|' || lr_docs.new_doc_status || '|' || lr_docs.aops_number || '|' || lr_docs.account_number || '|' || lr_docs.customer_name || '|' || lr_docs.billdocs_mbs_doc_id || '|' || lr_docs.billdocs_pay_doc_ind || '|' || lr_docs.billdocs_delivery_method || '|' || lr_docs.billdocs_direct_flag || '|' || lr_docs.billdocs_doc_type || '|' || lr_docs.billdocs_payment_term || '|' || lr_docs.billdocs_mail_to_attention || '|' || lc_contact_name || '|' || lc_contact_email || '|' || TO_CHAR(lr_docs.billdocs_req_start_date,'DD-MON-RRRR HH24:MI:SS') || '|' || TO_CHAR(lr_docs.creation_date,'DD-MON-RRRR HH24:MI:SS') || '|' || lr_docs.request_id || '|' || lr_docs.ebl_conv_doc_id || '|' || lr_docs.cust_account_id || '|' || lr_docs.error_message);

      EXCEPTION

        WHEN OTHERS THEN

          fnd_file.put_line (fnd_file.log, 'Unexpected Exception in the procedure convert_error_report - Inner Loop. ' || SQLCODE || ':' || SQLERRM);
          x_retcode := '2';
          x_errbuff := 'Unexpected Exception in the procedure convert_error_report - Inner Loop. ' || SQLCODE || ':' || SQLERRM;
      END;

    END LOOP;

    /* Set the Start date to the end date of the current report.
       The date in the profile value will be used as the start date of the next report run
       in case user runs the report without giving a start date
     */

    lb_return  := fnd_profile.save('XX_CDH_EBL_REPORT_DATE',TO_CHAR(ld_end_date, 'DD-MON-RRRR HH24:MI:SS'),'SITE',null,null,null);

    x_retcode := '0';

  EXCEPTION

    WHEN OTHERS THEN

      fnd_file.put_line (fnd_file.log, 'Unexpected Exception in the procedure convert_error_report. ' || SQLCODE || ':' || SQLERRM);
      x_retcode := '2';
      x_errbuff := 'Unexpected Exception in the procedure convert_error_report. ' || SQLCODE || ':' || SQLERRM;

  END convert_error_report;


END xx_cdh_ebl_conv_paper_epdf;
/
